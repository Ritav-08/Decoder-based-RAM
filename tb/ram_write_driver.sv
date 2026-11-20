
`ifndef RAM_WRITE_DRIVER_SV
`define RAM_WRITE_DRIVER_SV

`include "ram_transaction.sv"

class ram_write_driver;

    //interface
    virtual ram_if.WRITE_DRV vif;

    //mailbox
    mailbox #(ram_transaction) wr_mbx;      // from generator
    mailbox #(bit)             wr_done_mbx; // ack to generator per write

    //statistics variable
    int unsigned txn_count;

    //new construct
    function new(virtual ram_if.WRITE_DRV vif,
                 mailbox #(ram_transaction) wr_mbx,
                 mailbox #(bit)             wr_done_mbx);
        this.vif          = vif;
        this.wr_mbx       = wr_mbx;
        this.wr_done_mbx  = wr_done_mbx;
        this.txn_count    = 0;
    endfunction

    //reset() - assert reset for N cycles then release
    task reset(int cycles = 4);
        $display("[WR-DRV] Asserting reset for %0d cycles", cycles);
        vif.wr_cb.rst_n <= 1'b0;
        vif.wr_cb.we    <= 1'b0;
        vif.wr_cb.addr  <= 7'h00;
        vif.wr_cb.wdata <= 8'h00;
        repeat (cycles) @(vif.wr_cb);
        vif.wr_cb.rst_n <= 1'b1;
        $display("[WR-DRV] Reset de-asserted");
    endtask

    //run() - pull transactions and drive them
    task run();
        ram_transaction txn;
        $display("[WR-DRV] Started");

        forever begin
            wr_mbx.get(txn);                  // blocking get
            drive(txn);
            txn_count++;
            wr_done_mbx.put(1'b1);            // signal write complete
        end
    endtask

    //drive() - apply one WRITE transaction
    task drive(ram_transaction txn);
        //apply signals on clocking-block edge
        @(vif.wr_cb);
        vif.wr_cb.we    <= 1'b1;
        vif.wr_cb.addr  <= txn.addr;
        vif.wr_cb.wdata <= txn.wdata;

        @(vif.wr_cb);                          // hold for 1 cycle (DUT latches)
        vif.wr_cb.we    <= 1'b0;
        vif.wr_cb.addr  <= 7'h00;
        vif.wr_cb.wdata <= 8'h00;

        $display("[WR-DRV] addr=0x%02h data=0x%02h", txn.addr, txn.wdata);
    endtask

endclass : ram_write_driver

`endif // RAM_WRITE_DRIVER_SV
