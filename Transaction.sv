`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 12:00:47 PM
// Design Name: 
// Module Name: transaction
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


class transaction;
   
   typedef enum {WRITE, READ} op_t; //remember to make it global, or access to generator.run task
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
