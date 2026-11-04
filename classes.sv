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
   
   //run task
   task run(); 
      transaction txn;
      
      logic [6:0] written_addr[];
      written_addr = new[num_writes];
      
      //Write
      for(int i = 0; i < num_writes; i++) begin : Write_Logic
         txn = new();
         txn.op = WRITE;
         if(!txn.randomize() with {txn.op == WRITE;}) begin
            $display("Randomization failed : Write");
         end
         
         written_addr[i] = txn.addr;
         wr_mbox.put(txn);
      end : Write_Logic
      
      begin : Write_Ack
         bit token;
         for(int i = 0; i < num_writes; i++) begin
            write_done_mbox.get(token);
         end
      end : Write_Ack
      
      //Read : Write Address Array
      for(int i = 0; i < num_writes; i++) begin : Read_arr
         txn = new();
         txn.op = READ;
         txn.addr = written_addr[i];
         rd_mbox.put(txn);
      end : Read_arr
      
      //Read : Random Address
      for(int i = 0; i < num_reads; i++) begin : Read_rand
         txn = new();
         txn.op = READ;
         if(!txn.randomize() with {txn.op == READ;}) begin
            $display("Randomization failed : Read");
         end
         rd_mbox.put(txn);
      end : Read_rand
       
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
         
         
      end
   endtask
   
   
   
endclass