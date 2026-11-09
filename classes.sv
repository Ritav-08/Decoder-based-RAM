`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/04/2026 01:37:04 PM
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//GLOBAL PARAMETERS
typedef enum {WRITE, READ} op_t; //remember to make it global, or access to generator.run task


// ----------- TRANSACTION -----------

class transaction;
   
   
   rand op_t op;
   
   rand logic [6:0] addr;
   rand logic [7:0] wdata;
   logic [7:0] rdata;
   logic valid;
   
   function new();
      op    = WRITE;
      addr  = 7'b000_0000;
      wdata = 8'h00;
      rdata = 8'h00;
      valid = 1'b0;
   endfunction
   
   function void print(string text = " ");
      $display("@%0t: %0s | OP: %0s, Addr: %0h, Wdata: %0h, Rdata: %0h", 
               $time, text, op, addr, wdata, rdata, valid);
   endfunction
    
endclass


// ----------- GENERATOR -----------

class generator;
   
   //mailbox
   mailbox #(transaction) wr_mbox; //write
   mailbox #(transaction) rd_mbox; //read
   mailbox #(bit) write_done_mbox; //ack from the driver
   
   //intermediate variables
   int unsigned num_writes;
   int unsigned num_reads;
   
   //new constructor
   function new(
      mailbox #(transaction) wr_mbox, 
      mailbox #(transaction) rd_mbox, 
      mailbox #(bit) write_done_mbox, 
      int unsigned num_writes = 32, 
      int unsigned num_reads  = 32
   );
      this.wr_mbox         = wr_mbox;
      this.rd_mbox         = rd_mbox;
      this.write_done_mbox = write_done_mbox;
      this.num_writes      = num_writes;
      this.num_reads       = num_reads;
   endfunction
   
   //send write task
   local task send_write(
      input logic [6:0] addr, 
      input logic [7:0] data
   );
      transaction txn = new();
      txn.op = WRITE;
      txn.addr = addr;
      txn.wdata = data;
      txn.print("[GEN-WR]");
      
      wr_mbox.put(txn);
   endtask
   
   //wait for write task
   local task wait_writes_done(
      input int unsigned n
   );
      bit tok;
      repeat(n) wr_done_mbox.get(tok);
   endtask
   
   //send read task
   local task send_read(
      input logic [6:0] addr
   );
      transaction txn = new();
      txn.op = READ;
      txn.addr = addr;
      txn.print("[GEN-RD]");
      
      rd_mbox.put(txn);
   endtask
   
   //run task
   task run(
      input logic [6:0] wr_addrs[],
      input logic [7:0] wr_datas[], 
      input int unsigned n_writes, 
      input logic [6:0] rd_addrs[], 
      input int unsigned n_reads, 
      input bit randomize_txns = 0 
   ); 
      //Write
      $display("[GEN] Sending %0d writes", n_writes);
      if(randomize_txns) begin
         for(int i = 0; i < n_writes; i++) begin
            transaction txn = new();
            if(!txn.randomize() with {op == WRITE;}) begin
               $fatal(1, "[GEN] randomize() failed for WRITE %0d", i);
            end
            send_write(txn.addr, txn.wdata);
         end
      end
      else begin
         for(int i = 0; i < n_writes; i++) begin
            send_write(wr_addrs[i], wr_datas[i]);
         end
      end
      
      //Drain all writes before issuing reads
      wait_writes_done(n_writes);
      $display("[GEN] All writes done");
      
      //Reads
      $display("[GEN] Sending %0d reads", n_reads);
      if(randomize_txns) begin
         for(int i = 0; i < n_reads; i++) begin
            transaction txn = new();
            if(!txn.randomize() with {op == READ;}) begin
               $fatal(1, "[GEN] randomize() failed for READ %0d", i);
            end
            send_read(txn.addr);
         end
      end
      else begin
         for(int i = 0; i < n_reads; i++) begin
            send_read(rd_addrs[i]);
         end
      end
      
      $display("[GEN] Done...");
      
      
//      transaction txn;
      
//      logic [6:0] written_addr[];
//      written_addr = new[num_writes];
      
//      //Write
//      for(int i = 0; i < num_writes; i++) begin : Write_Logic
//         txn = new();
//         txn.op = WRITE;
//         if(!txn.randomize() with {txn.op == WRITE;}) begin
//            $display("Randomization failed : Write");
//         end
         
//         written_addr[i] = txn.addr;
//         wr_mbox.put(txn);
//      end : Write_Logic
      
//      begin : Write_Ack
//         bit token;
//         for(int i = 0; i < num_writes; i++) begin
//            write_done_mbox.get(token);
//         end
//      end : Write_Ack
      
//      //Read : Write Address Array
//      for(int i = 0; i < num_writes; i++) begin : Read_arr
//         txn = new();
//         txn.op = READ;
//         txn.addr = written_addr[i];
//         rd_mbox.put(txn);
//      end : Read_arr
      
//      //Read : Random Address
//      for(int i = 0; i < num_reads; i++) begin : Read_rand
//         txn = new();
//         txn.op = READ;
//         if(!txn.randomize() with {txn.op == READ;}) begin
//            $display("Randomization failed : Read");
//         end
//         rd_mbox.put(txn);
//      end : Read_rand
       
   endtask : run
   
endclass


// ----------- WRITE DRIVER -----------

class ram_wr_driver;

   //virtual interface
   virtual ram_if.WRITE_DRV vif;
   
   //mailbox
   mailbox #(transaction) wr_mbox;
   mailbox #(transaction) write_done_mbox;
   
   //intermediate variables
   int unsigned txn_count;
   
   //new construct
   function new(
      virtual ram_if vif, 
      mailbox #(transaction) wr_mbox, 
      mailbox #(transaction) write_done_mbox, 
      int unsigned txn_count = 0
   );
      this.vif = vif;
      this.wr_mbox = wr_mbox;
      this.write_done_mbox = write_done_mbox;
      this.txn_count = txn_count;
   endfunction
   
   //reset task
   task reset(
      int cycles = 3
   );
      $display("Applying reset...");
      
      vif.rst_n <= 1'b0;
      vif.we    <= 1'b0;
      vif.re    <= 1'b0;
      vif.addr  <= 7'h00;
      vif.wdata <= 8'h00;
      
      repeat(cycles) @(vif.wr_cb)
         vif.rst_n <= 1'b1;
      
      $display("Reset deasserted");
   endtask
   
   //drive task
   task drive(
      transaction txn
   ); 
      @(vif.wr_cb);
   
      vif.wr_cb.we    <= 1'b1;
      vif.wr_cb.addr  <= txn.addr;
      vif.wr_cb.wdata <= txn.wdata;
      
      @(vif.wr_cb)
      
      vif.wr_cb.we    <= 1'b0;
      vif.wr_cb.addr  <= 7'h00;
      vif.wr_cb.wdata <= 8'h00;
      
      $monitor("@%0t: We: %0b | Addr: %0h, Wdata: %0h", 
         $time, vif.we, vif.addr, vif.wdata);
      $display("Values driven...");
   endtask
   
   //run task
   task run();
      transaction txn;
      forever begin
         wr_mbox.get(txn);
         drive(txn);
         txn_count++;
         write_done_mbox.put(1'b1);
      end
   endtask

endclass


// ----------- READ DRIVER -----------
class ram_rd_driver;
   //virtual interface
   virtual ram_if.READ_DRV vif;
   
   //mailbox
   mailbox #(transaction) rd_mbox;
//   mailbox #(read_transaction) rd_done_mbox;   //***********
   
   //intermediate variables
   int unsigned txn_count;
   
   //new construct
   function new(
      virtual ram_if.READ_DRV vif, 
      mailbox #(transaction) rd_mbox, 
//      mailbox #(read_transaction) rd_done_mbox,   //**********
      int unsigned txn_count
   );
      this.vif = vif;
      this.re_mbox = rd_mbox;
//      this.re_done_mbox = rd_done_mbox;   //************
      this.txn_count = txn_count;
   endfunction
   
   //reset task
   task drive(
transaction txn//      ram_transaction txn   //***********

   );
      @(vif.rd_cb);
      
      vif.rd_cb.re <= 1'b1;
      vif.rd_cb.addr <= txn.addr;
      
      @(vif.rd_cb)
      
      vif.rd_cb.re <= 1'b0;
      vif.rd_cb.addr <= 7'h00;
   endtask
   
   //run task
   task run();
      transaction txn;
      forever begin
         rd_mbox.get(txn);
         drive(txn);
         txn_count++;
      end
   endtask
   
endclass


// ----------- WRITE MONITOR -----------
class write_monitor;
   //virtual interface
   virtual ram_if.WR_MON vif;
   
   //mailbox
   mailbox #(transaction) sb_wr_mbox;
   mailbox #(transaction) rm_wr_mbox;
   
   //intermediate variables
   int unsigned observed_count;
   
   //new construct
   function new(
      virtual ram_if.WR_MON vif, 
      mailbox #(transaction) sb_wr_mbox, 
      mailbox #(transaction) rm_wr_mbox, 
      int unsigned observed_count = 0
   );
      this.vif = vif;
      this.sb_wr_mbox = sb_wr_mbox;
      this.rm_wr_mbox = rm_wr_mbox;
      this.observed_count = observed_count;
   endfunction
   
   //run task
   task run();
      transaction txn;
      $display("WR_MON started...");
      forever begin
         @(vif.mon_cb)
         
         if(vif.mon_cb.we == 1'b1) begin
            txn = new();
            txn.op = WRITE;
            
            txn.addr = vif.mon_cb.addr;
            txn.wdata = vif.mon_cb.wdata;
            txn.valid = 1'b0;
            
            observed_count++;
            
            txn.print("Wr_Mon");
            
            sb_wr_mbox.put(txn);
            rm_wr_mbox.put(txn);
         end
      end
   endtask
endclass


// ----------- READ MONITOR -----------
class read_monitor;
   //virtual interface
   virtual ram_if.RD_MON vif;
   
   //mailbox
   mailbox #(transaction) sb_rd_mbox;
   mailbox #(transaction) rm_rd_mbox;
   
   //intermediate variables
   int unsigned observed_count;
   
   //new construct
   function new(
      virtual ram_if.RD_MON vif, 
      mailbox #(transaction) sb_rd_mbox, 
      mailbox #(transaction) rm_rd_mbox, 
      int unsigned observed_count = 0
   );
      this.vif = vif;
      this.sb_rd_mbox = sb_rd_mbox;
      this.rm_rd_mbox = rm_rd_mbox;
      this.observed_count = observed_count;
   endfunction
   
   //run task
   task run();
      transaction txn;
      $display("RD_MON started...");
      forever begin
         @(vif.clk)
         #2;
         txn.rdata = vif.rdata;
         txn.valid = vif.valid;
         txn.re = vif.re;
         
         if(txn.valid == 0) begin
            $display("valid isn't generated, waiting for valid");
         end
         
         observed_count++;
         
         txn.print("rd_Mon");
         
         sb_rd_mbox.put(txn);
         rm_rd_mbox.put(txn);
      end
   endtask
   
endclass


// ----------- REFERENCE MODEL -----------
class ram_ref_model;
   //memory
   logic [7:0] mem[0:127];
   
   //mailboxe
   mailbox #(transaction) rm_wr_mbox;
   mailbox #(transaction) rm_rd_mbox;
   mailbox #(transaction) sb_ex_mbox;
   
   //intermediate variables
   int unsigned wr_processed;
   int unsigned rd_processed;
   
   //new construct
   function new(
      mailbox #(transaction) rm_wr_mbox,
      mailbox #(transaction) rm_rd_mbox,
      mailbox #(transaction) sb_ex_mbox
//      int unsigned wr_processed = 0,
//      int unsigned rd_processed = 0
   );
      this.rm_wr_mbox = rm_wr_mbox;
      this.rm_rd_mbox = rm_rd_mbox;
      this.sb_ex_mbox = sb_ex_mbox;
//      this.wr_processed = wr_processed;
//      this.rd_processed = rd_processed;
   endfunction
   
   //run task for write
   task run_writes();
      transaction txn;
      $display("RM : Write Task started...");
      
      forever begin
         rm_wr_mbox.get(txn);
         mem[txn.addr] = txn.wdata;
         
         wr_processed++;
         
         $display("RM | Wr addr: %0h, data: %0h, block: %0d", 
            txn.addr, txn.wdata, txn.addr[6:5]);
      end
   endtask
   
   //run task for read
   task run_reads();
      transaction txn, exp_txn; //**********
      $display("RM : Read Task started...");
      
      forever begin
         rm_rd_mbox.get(txn);
         txn.rdata = mem[txn.addr];
         txn.valid = 1'b1;
         
         rd_processed++;
      end
   endtask
   
endclass


// ----------- SCOREBOARD -----------
class ram_scoreboard;
   //mailbox
   mailbox #(transaction) sb_rd_mbox;
   mailbox #(transaction) sb_wr_mbox;
   mailbox #(transaction) sb_exp_mbox;
   
   //intermediate variables
   int unsigned pass_count;
   int unsigned fail_count;
   int unsigned wr_count;
   
   //new construct
   function new(
      mailbox #(transaction) sb_rd_mbox, 
      mailbox #(transaction) sb_wr_mbox, 
      mailbox #(transaction) sb_exp_mbox
   );
      this.sb_rd_mbox = sb_rd_mbox;
      this.sb_wr_mbox = sb_wr_mbox;
      this.sb_exp_mbox = sb_exp_mbox;
   endfunction
   
   //run task for checker
   task run_check();
      transaction txn, exp_txn;
      $display("Scoreboard started...");
      
      forever begin
//         sb_rd_mbox.get(actual);     //**********
//         sb_exp_mbox.get(expected);  //**********
         
//         check(actual, expected);    //**********
      end
   endtask
   
   //checker function
   function void check(
      transaction actual,
      transaction expected
   );
      bit addr_match;
      bit data_match;
      bit valid_match;
      
      addr_match = (actual.addr == expected.addr);
      data_match = (actual.data == expected.data);
      valid_match = (actual.valid == expected.valid);
      
      if(addr_match && data_match && valid_match) begin
         pass_count++;
         $display("SB passed | Addr: %0d, Data: %0d", 
            actual.addr, actual.data);
      end
      else begin
         fail_count++;
         if(!addr_match) begin
            $display("Addr Mismatch | A_Addr: %0d, E_Addr: %0d", 
               actual.addr, expected.addr);
         end
         if(!data_match) begin
            $display("Data Mismatch | A_Data: %0d, E_Data: %0d", 
               actual.data, expected.data);
         end
      end
      
   endfunction
   
   //report function
   function report();
      //PENDING 
      //no of write, no of transactions happened, no of read amd read txns happened
      //total no of pass, fail, count
      //if fail == 0, All test pass display
      //if any fail, x test failed
   endfunction
   
endclass


//----------- ENVIRONMENT -----------
class ram_env;
   //external files
   `include "interface.sv";
   
   //instantiations
   generator gen;
   ram_wr_driver wr_drv;
   ram_rd_driver rd_drv;
   write_monitor wr_mon;
   read_monitor rd_mon;
   ram_ref_model rm;
   ram_sccoreboard sb;
   
   //mailboxes
   local mailbox #(transaction) wr_mbox;
   local mailbox #(transaction) rd_mbox;
   local mailbox #(bit) wr_done_mbox;
   local mailbox #(transaction) rd_done_mbox;
   local mailbox #(transaction) rm_wr_mbox;
   local mailbox #(transaction) rm_rd_mbox;
   local mailbox #(transaction) sb_wr_mbox;
   mailbox #(transaction) sb_rd_mbox;
   mailbox #(transaction) sb_exp_mbox;
   
   //virtual interface
   virtual ram_if.WRITE_DRV wr_vif;
   virtual ram_if.READ_DRV rd_vif;
   virtual ram_if.WR_MON wr_mon_vif;
   virtual ram_if.RD_MON rd_mon_vif;
   
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif,
      virtual ram_if.READ_DRV rd_vif,
      virtual ram_if.WR_MON wr_mon_vif,
      virtual ram_if.RD_MON rd_mon_vif
   );
      this.wr_vif = wr_vif;
      this.rd_vif = rd_vif;
      this.wr_mon_vif = wr_mon_vif;
      this.rd_mon_vif = rd_mon_vif;
      
      wr_mbox = new();
      rd_mbox = new();
      wr_done_mbox = new();
      rd_done_mbox = new();
      rm_wr_mbox = new();
      rm_rd_mbox = new();
      sb_wr_mbox = new();
      sb_rd_mbox = new();
      sb_exp_mbox = new();
      
   endfunction
   
   //build function
   function build();
      gen    = new(
                  wr_mbox, 
                  rd_mbox, 
                  wr_done_mbox
               );
      wr_drv = new(
                  wr_vif, 
                  wr_mbox, 
                  wr_done_mbox
               );
      rd_drv = new(
                  rd_vif, 
                  rd_mbox, 
                  rd_done_mbox
               );
      wr_mon = new(
                  wr_mon_vif, 
                  sb_wr_mbox, 
                  rm_wr_mbox
               );
      rd_mon = new(
                  rd_mon_vif, 
                  rd_done_mbox, 
                  sb_rd_mbox, 
                  rm_rd_mbox
               );
      rm     = new(
                  rm_wr_mbox, 
                  rm_rd_mbox, 
                  sb_exp_mbox
               );
      sb     = new(
                  sb_rd_mbox, 
                  sb_exp_mbox, 
                  sb_wr_mbox
               );
      $display("[ENV] All components built");
   endfunction
   
   //start task
   task start();
      fork 
         wr_drv.run();
         rd_drv.run();
         wr_mon.run();
         rd_mon.run();
         rm.run_writes();
         rm.run_reads();
         sb.run_check();
//         sb.run_wr_sink();
      join_none
      wr_drv.reset(4);
      $display("[ENV] All threads started, DUT reset done");
   endtask
   
   //run task
   task run(
      input logic [6:0] wr_addrs[], 
      input logic [7:0] wr_datas[], 
      input int unsigned n_writes, 
      input logic [6:0] rd_addrs[], 
      input int unsigned n_reads, 
      input bit randomize_txns = 0
   );
      gen.run(
         wr_addrs, 
         wr_datas, 
         n_writes, 
         rd_addrs, 
         n_reads, 
         randomize_txns
      );
   endtask
   
   //report function
//   function void report();
//      sb.report();
//   endfunction

endclass