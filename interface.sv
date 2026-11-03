`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2026 11:49:11 AM
// Design Name: 
// Module Name: ram_if
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


interface ram_if;
   bit clk;
   logic rst_n;
   logic we;
   logic re;
   logic [6:0] addr;
   logic [7:0] wdata;
   logic [7:0] rdata;
   logic valid;
   
   modport dut_m(
      input clk, input rst_n, input we, input re, input addr, 
      output wdata, output rdata, output valid
   );
   
   modport tb_m(
      input wdata, input rdata, input valid, 
      output clk, output rst_n, output we, output re, output addr
   );
   
endinterface
