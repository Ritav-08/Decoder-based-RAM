
`ifndef RAM_WRITE_MONITOR_SV
`define RAM_WRITE_MONITOR_SV
`include "ram_transaction.sv"

class ram_write_monitor;

    //interface
    virtual ram_if.WR_MON vif;

    //mailbox
    mailbox #(ram_transaction) sb_wr_mbx;
    mailbox #(ram_transaction) rm_wr_mbx;

    //statistics variable
    int unsigned observed_count;
     
    //coverage sampling variables (updated each write)
    logic [6:0] cov_addr;
    logic [7:0] cov_wdata;

    //functional coverage group
    covergroup wr_monitor_cg;

        // -- Address Coverage --
        //are all 128 addresses exercised?
        cp_addr: coverpoint cov_addr {
            bins addr_zero        = {7'h00};
            bins addr_low         = {[7'h01 : 7'h1F]};   // 1?31
            bins addr_mid         = {[7'h20 : 7'h5F]};   // 32?95
            bins addr_high        = {[7'h60 : 7'h7E]};   // 96?126
            bins addr_max         = {7'h7F};
        }

        // -- Write Data Coverage --
        //full byte range bucketed
        cp_wdata: coverpoint cov_wdata {
            bins data_zero        = {8'h00};
            bins data_all_ones    = {8'hFF};
            bins data_low         = {[8'h01 : 8'h3F]};
            bins data_mid         = {[8'h40 : 8'hBF]};
            bins data_high        = {[8'hC0 : 8'hFE]};
        }

        // -- Write Data Bit-Pattern Coverage --
        //checks walking-one, walking-zero, alternating patterns
        cp_wdata_pattern: coverpoint cov_wdata {
            bins walking_ones[]   = {8'h01, 8'h02, 8'h04, 8'h08,
                                     8'h10, 8'h20, 8'h40, 8'h80};
            bins walking_zeros[]  = {8'hFE, 8'hFD, 8'hFB, 8'hF7,
                                     8'hEF, 8'hDF, 8'hBF, 8'h7F};
            bins alternating      = {8'hAA, 8'h55};
            bins others           = default;
        }

        // -- Address Boundary Coverage --
        //explicit bins for boundary addresses only
        cp_addr_boundary: coverpoint cov_addr {
            bins boundary[] = {7'h00, 7'h7F};
            bins non_boundary = default;
        }

        // -- Cross: Address Range × Data Range --
        //ensures writes to every address region carry varied data
        cx_addr_x_data: cross cp_addr, cp_wdata;

        // -- Cross: Address Boundary × Data Pattern --
        //corner-case: boundary address + special data patterns
        cx_boundary_x_pattern: cross cp_addr_boundary, cp_wdata_pattern;

    endgroup : wr_monitor_cg

    //constructor
    function new(virtual ram_if.WR_MON vif,
                 mailbox #(ram_transaction) sb_wr_mbx,
                 mailbox #(ram_transaction) rm_wr_mbx);
        this.vif            = vif;
        this.sb_wr_mbx      = sb_wr_mbx;
        this.rm_wr_mbx      = rm_wr_mbx;
        this.observed_count = 0;
        wr_monitor_cg       = new();   // instantiate covergroup
    endfunction

    //run() ? watch the bus every clock
    task run();
        ram_transaction txn;
        $display("[WR-MON] Started");
        forever begin
            @(vif.mon_cb);

            if (vif.mon_cb.we === 1'b1) begin
                txn       = new();
                txn.op    = WRITE;
                txn.addr  = vif.mon_cb.addr;
                txn.wdata = vif.mon_cb.wdata;
                txn.rdata = 8'h00;
                txn.valid = 1'b0;

                observed_count++;
                txn.print("[WR-MON]");

                // -- Update coverage variables and sample --
                cov_addr  = txn.addr;
                cov_wdata = txn.wdata;
                wr_monitor_cg.sample();

                //broadcast to scoreboard and reference model
                sb_wr_mbx.put(txn.copy());
                rm_wr_mbx.put(txn.copy());
            end
        end
    endtask

    //report coverage at end of simulation
    function void report();
        $display("[WR-MON] Observed writes : %0d", observed_count);
        $display("[WR-MON] Functional coverage: %.2f%%",
                 wr_monitor_cg.get_coverage());
    endfunction

endclass : ram_write_monitor
`endif // RAM_WRITE_MONITOR_SV
