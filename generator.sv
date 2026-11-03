`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 12:46:32 PM
// Design Name: 
// Module Name: generator
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

class generator;
   
   mailbox #(transaction) wr_mbox; //write
   mailbox #(transaction) rd_mbox; //read
   mailbox #(bit) write_done_mbox; //ack from the driver
   
   int unsigned num_writes;
   int unsigned num_reads;
   
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
   
   task run();
      transaction txn;
      
      logic [6:0] written_addr[];
      written_addr = new[num_writes];
      
   //Write
      for(int i = 0; i < num_writes; i++) begin
         txn = new();
         txn.op = WRITE;
         if(!txn.randomize() with {txn.op == WRITE;}) begin
            $display("Randomization failed");
         end
         
         written_addr = txn.addr;
         wr_mbox.put(txn);
      end
      
      bit token;
      for(int i = 0; i < num_writes; i++) begin
         write_done_mbox.get(token);
      end
      
      
   endtask
   
endclass
