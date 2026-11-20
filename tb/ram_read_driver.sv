
`ifndef RAM_READ_DRIVER_SV
`define RAM_READ_DRIVER_SV

`include "ram_transaction.sv"

class ram_read_driver;

    virtual ram_if.READ_DRV vif;

    mailbox #(ram_transaction) rd_mbx;
    mailbox #(ram_transaction) rd_done_mbx;

    int unsigned txn_count;

    function new(virtual ram_if.READ_DRV vif,
                 mailbox #(ram_transaction) rd_mbx,
                 mailbox #(ram_transaction) rd_done_mbx);
        this.vif         = vif;
        this.rd_mbx      = rd_mbx;
        this.rd_done_mbx = rd_done_mbx;
        this.txn_count   = 0;
    endfunction

    task run();
        ram_transaction txn;
        $display("[RD-DRV] Started");
        forever begin
            rd_mbx.get(txn);
            drive(txn);
            txn_count++;
        end
    endtask

    //drive task
    task drive(ram_transaction txn);
        //Step 1: assert re + addr (output #1 -> wire at T+1)
        @(vif.rd_cb);
        vif.rd_cb.re   <= 1'b1;
        vif.rd_cb.addr <= txn.addr;

        //Step 2: wait for the posedge where DUT latches re=1
        @(posedge vif.clk);
        //wait past the NBA region so rdata/valid are committed
        #2;
        txn.rdata = vif.rdata;
        txn.valid = vif.valid;

        //deassert re - wire goes low well before next posedge
        vif.rd_cb.re   <= 1'b0;
        vif.rd_cb.addr <= 7'h00;

        //Step 3: idle cycle - DUT clears valid, bus clean
        @(vif.rd_cb);

        $display("[RD-DRV] addr=0x%02h rdata=0x%02h valid=%0b",
                 txn.addr, txn.rdata, txn.valid);

        rd_done_mbx.put(txn);
    endtask

endclass : ram_read_driver

`endif // RAM_READ_DRIVER_SV
