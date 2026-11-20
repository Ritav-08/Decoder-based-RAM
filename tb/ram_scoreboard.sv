
`ifndef RAM_SCOREBOARD_SV
`define RAM_SCOREBOARD_SV
`include "ram_transaction.sv"

class ram_scoreboard;

    mailbox #(ram_transaction) sb_rd_mbx;
    mailbox #(ram_transaction) sb_exp_mbx;
    mailbox #(ram_transaction) sb_wr_mbx;

    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned wr_count;

    function new(mailbox #(ram_transaction) sb_rd_mbx,
                 mailbox #(ram_transaction) sb_exp_mbx,
                 mailbox #(ram_transaction) sb_wr_mbx);
        this.sb_rd_mbx  = sb_rd_mbx;
        this.sb_exp_mbx = sb_exp_mbx;
        this.sb_wr_mbx  = sb_wr_mbx;
        pass_count = 0;
        fail_count = 0;
        wr_count   = 0;
    endfunction

    //run_check() ? every read is now a valid comparison
    // because DUT and RM share the same initial state
    task run_check();
        ram_transaction actual, expected;
        $display("[SB] Checker task started");
        forever begin
            sb_rd_mbx.get(actual);
            sb_exp_mbx.get(expected);
            check(actual, expected);
        end
    endtask

    task run_wr_sink();
        ram_transaction txn;
        forever begin
            sb_wr_mbx.get(txn);
            wr_count++;
        end
    endtask

    function void check(ram_transaction actual, ram_transaction expected);
        bit addr_match  = (actual.addr  === expected.addr);
        bit data_match  = (actual.rdata === expected.rdata);
        bit valid_match = (actual.valid === expected.valid);

        if (addr_match && data_match && valid_match) begin
            pass_count++;
            $display("[SB] PASS | addr=0x%02h actual=0x%02h expected=0x%02h valid=%0b",
                     actual.addr, actual.rdata, expected.rdata, actual.valid);
        end else begin
            fail_count++;
            $error("[SB] FAIL | addr=0x%02h actual=0x%02h expected=0x%02h valid_act=%0b valid_exp=%0b",
                   actual.addr, actual.rdata, expected.rdata,
                   actual.valid, expected.valid);
            if (!addr_match)
                $error("[SB]   --> Address mismatch: actual=0x%02h expected=0x%02h",
                       actual.addr, expected.addr);
        end
    endfunction

    function void report();
        $display("");
        $display("======================================================");
        $display("  SCOREBOARD SUMMARY");
        $display("======================================================");
        $display("  Write transactions observed : %0d", wr_count);
        $display("  Read  transactions checked  : %0d", pass_count + fail_count);
        $display("  PASS                        : %0d", pass_count);
        $display("  FAIL                        : %0d", fail_count);
        if (fail_count == 0)
            $display("  RESULT: *** ALL TESTS PASSED ***");
        else
            $display("  RESULT: *** %0d TEST(S) FAILED ***", fail_count);
        $display("======================================================");
        $display("");
    endfunction

endclass : ram_scoreboard

`endif // RAM_SCOREBOARD_SV
