# 128×8 Decoder-Based RAM & SystemVerilog Verification Environment

A 128×8 synchronous RAM (`decoder_ram`) built from four 32×8 memory blocks with a 2-to-4 address decoder, paired with a layered, class-based SystemVerilog verification testbench.

## Architecture Overview

### Design Under Test (`decoder_ram`)

The DUT implements a 128-byte (128×8) synchronous memory organized as four independent 32×8 banks (`mem_block0` through `mem_block3`).

- **Block Selection (`addr[6:5]`)**: A 2-to-4 decoder generates one-hot chip-select signals (`cs[3:0]`) to select one of the four 32×8 blocks:
  - `2'b00` (`0x00–0x1F`) → `mem_block0` (`cs[0]`)
  - `2'b01` (`0x20–0x3F`) → `mem_block1` (`cs[1]`)
  - `2'b10` (`0x40–0x5F`) → `mem_block2` (`cs[2]`)
  - `2'b11` (`0x60–0x7F`) → `mem_block3` (`cs[3]`)
- **Word Addressing (`addr[4:0]`)**: Selects one of 32 byte locations within the active block.
- **Reset Behavior (`rst_n`)**: Active-low asynchronous reset clears all 128 memory locations to `0x00`, sets `rdata` to `0x00`, and deasserts `valid` (`1'b0`), ensuring a known initial state shared with the reference model.

#### Port Specification

| Signal | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 | System clock (10 ns period in `ram_tb_top`) |
| `rst_n` | Input | 1 | Active-low asynchronous reset |
| `we` | Input | 1 | Write enable (active high) |
| `re` | Input | 1 | Read enable (active high) |
| `addr` | Input | 7 | 7-bit byte address (`0x00`–`0x7F`) |
| `wdata` | Input | 8 | 8-bit write data |
| `rdata` | Output | 8 | 8-bit read data (valid when `valid == 1`) |
| `valid` | Output | 1 | Read data valid indicator |

### Testbench Architecture

The verification environment uses a modular, mailbox-connected SystemVerilog class hierarchy:

1. **Interface (`ram_if`)**: Defines `wr_cb`, `rd_cb`, and `mon_cb` clocking blocks (`@(posedge clk)`) along with `WRITE_DRV`, `READ_DRV`, `WR_MON`, and `RD_MON` modports. `READ_DRV` exposes raw `rdata` and `valid` signals to sample committed non-blocking assignments cleanly after the NBA region.
2. **Transaction (`ram_transaction`)**: Encapsulates `op` (`WRITE` / `READ`), randomized `addr` (`0x00`–`0x7F`), randomized `wdata` (`0x00`–`0xFF`), and captured `rdata`/`valid` fields.
3. **Generator (`ram_generator`)**: Owns the driver mailboxes and injects directed or randomized write and read sequences from the active test.
4. **Drivers (`ram_write_driver`, `ram_read_driver`)**: Translate transactions into pin-level stimulus on `ram_if`. `ram_write_driver` also handles DUT reset assertion/release and acknowledges completed writes.
5. **Monitors (`ram_write_monitor`, `ram_read_monitor`)**: Passively observe bus activity and broadcast transactions to both the reference model and scoreboard. `ram_write_monitor` includes the `wr_monitor_cg` covergroup.
6. **Reference Model (`ram_ref_model`)**: Maintains a 128×8 software mirror (`mem[0:127]`) initialized to `0x00` on reset, predicting expected `rdata` and `valid` for every read.
7. **Scoreboard (`ram_scoreboard`)**: Compares actual read transactions against reference model predictions (`addr`, `rdata`, and `valid`), reporting pass/fail counts and a final summary.
8. **Environment & Tests (`ram_env`, `ram_test`, `ram_tb_top`)**: `ram_env` wires and forks all components; `ram_tb_top` instantiates the DUT and selects tests via `+TESTNAME`.

## Repository Files

| File | Role | Description |
| :--- | :--- | :--- |
| `decoder_ram.sv` | RTL DUT | 128×8 RAM with 2-to-4 block decoder and synchronous R/W logic |
| `ram_if.sv` | Interface | Clocking blocks and modports for drivers and monitors |
| `ram_transaction.sv` | Transaction | Sequence item with address/data constraints, `copy()`, and `print()` |
| `ram_generator.sv` | Generator | Generates directed and randomized write/read stimulus |
| `ram_write_driver.sv` | Write Driver | Drives reset and write transactions onto `wr_cb` |
| `ram_read_driver.sv` | Read Driver | Drives read transactions onto `rd_cb` and captures `rdata`/`valid` |
| `ram_write_monitor.sv` | Write Monitor | Observes writes, samples `wr_monitor_cg` coverage, forwards to RM/SB |
| `ram_read_monitor.sv` | Read Monitor | Relays captured reads, checks `valid`, forwards to RM/SB |
| `ram_ref_model.sv` | Reference Model | 128×8 software memory mirror for expected read prediction |
| `ram_scoreboard.sv` | Scoreboard | Checks actual vs. expected read data and prints pass/fail summary |
| `ram_env.sv` | Environment | Builds, connects, and starts all testbench components |
| `ram_test.sv` | Test Suite | `ram_base_test` and 15 directed/randomized test classes |
| `ram_tb_top.sv` | Top Module | Clock generation, DUT/interface instantiation, `+TESTNAME` dispatch |
| `decoder_ram_test_cases.docx` | Documentation | Verification plan detailing 39 test cases across 10 categories |

## Running Simulations

Compile the RTL and testbench top file with your SystemVerilog simulator (such as Questa/ModelSim, VCS, or Xcelium) and pass the desired test via `+TESTNAME`.

### Example (Questa / ModelSim)

```bash
vlog decoder_ram.sv ram_if.sv ram_tb_top.sv
vsim -c work.ram_tb_top +TESTNAME=ram_random_test -do "run -all; quit"
```

## Available Tests

`ram_tb_top.sv` supports the following 15 test cases via `+TESTNAME=<test_name>`:

| Test Name | Focus |
| :--- | :--- |
| `ram_random_test` | Randomized writes followed by reads |
| `ram_block_boundary_test` | First and last addresses of all 4 blocks (`0x00`, `0x1F`, `0x20`, `0x3F`, `0x40`, `0x5F`, `0x60`, `0x7F`) |
| `ram_full_sweep_test` | Full 128-location write and read sweep (`0x00`–`0x7F`) |
| `ram_walking1_data_test` | Walking-1s pattern across the 8-bit data bus |
| `ram_walking0_data_test` | Walking-0s pattern across the 8-bit data bus |
| `ram_walking1_addr_test` | Walking-1s pattern across the 7-bit address bus |
| `ram_walking0_addr_test` | Walking-0s pattern across the 7-bit address bus |
| `ram_same_addr_overwrite_test` | Multiple writes to the same address verifying latest-value retention |
| `ram_toggle_addr_test` | Alternating address bit-toggle stress |
| `ram_checkerboard_test` | Alternating `0xAA` and `0x55` data pattern |
| `ram_block_isolation_test` | Cross-block integrity verifying writes to one block do not corrupt others |
| `ram_allzero_test` | All-zeros (`0x00`) data pattern |
| `ram_allone_test` | All-ones (`0xFF`) data pattern |
| `ram_read_before_write_test` | Reads immediately after reset before any write (verifies `0x00` reset state) |
| `ram_constrained_weighted_test` | Constrained-random weighted stimulus |

## Functional Coverage

The `wr_monitor_cg` covergroup inside `ram_write_monitor.sv` tracks:

- **Address Coverage (`cp_addr`)**: Zero (`0x00`), low (`0x01–0x1F`), mid (`0x20–0x5F`), high (`0x60–0x7E`), and max (`0x7F`).
- **Write Data Coverage (`cp_wdata`)**: Zero (`0x00`), all-ones (`0xFF`), low (`0x01–0x3F`), mid (`0x40–0xBF`), and high (`0xC0–0xFE`).
- **Bit Patterns (`cp_wdata_pattern`)**: Walking 1s, walking 0s, and alternating (`0xAA`, `0x55`).
- **Boundary & Cross Coverage**: Boundary addresses (`0x00`, `0x7F`) crossed with data ranges and bit patterns (`cx_addr_x_data`, `cx_boundary_x_pattern`).
