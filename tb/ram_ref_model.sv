
`ifndef RAM_REF_MODEL_SV
`define RAM_REF_MODEL_SV
`include "ram_transaction.sv"

class ram_ref_model;

    //internal memory mirror (128 x 8)
    //initialized to 0x00 matching DUT reset state
    logic [7:0] mem [0:127];

    //mailbox
    mailbox #(ram_transaction) rm_wr_mbx;
    mailbox #(ram_transaction) rm_rd_mbx;
    mailbox #(ram_transaction) sb_exp_mbx;

    //statistics variables
    int unsigned wr_processed;
    int unsigned rd_processed;

    //constructor
    function new(mailbox #(ram_transaction) rm_wr_mbx,
                 mailbox #(ram_transaction) rm_rd_mbx,
                 mailbox #(ram_transaction) sb_exp_mbx);
        this.rm_wr_mbx  = rm_wr_mbx;
        this.rm_rd_mbx  = rm_rd_mbx;
        this.sb_exp_mbx = sb_exp_mbx;
        wr_processed    = 0;
        rd_processed    = 0;
        //mirror matches DUT reset state exactly
        for (int i = 0; i < 128; i++)
            mem[i] = 8'h00;
    endfunction

    //run_writes() ? update mirror on every write
    task run_writes();
        ram_transaction txn;
        $display("[RM] Write task started");
        forever begin
            rm_wr_mbx.get(txn);
            mem[txn.addr] = txn.wdata;
            wr_processed++;
            $display("[RM] WR addr=0x%02h data=0x%02h | block=%0d",
                     txn.addr, txn.wdata, txn.addr[6:5]);
        end
    endtask

    //run_reads() ? every read is now checkable because
    // both DUT and RM start from the same 0x00 state.
    //no seen[] flag, no skip needed.
    task run_reads();
        ram_transaction txn, exp_txn;
        $display("[RM] Read task started");
        forever begin
            rm_rd_mbx.get(txn);
            exp_txn       = txn.copy();
            exp_txn.rdata = mem[txn.addr];
            exp_txn.valid = 1'b1;
            rd_processed++;
            $display("[RM] RD addr=0x%02h expected_rdata=0x%02h | block=%0d",
                     txn.addr, exp_txn.rdata, txn.addr[6:5]);
            sb_exp_mbx.put(exp_txn);
        end
    endtask

    function int get_block(logic [6:0] addr);
        return addr[6:5];
    endfunction

endclass : ram_ref_model

`endif // RAM_REF_MODEL_SV
