`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/02/2026 03:23:09 PM
// Design Name: 
// Module Name: decoder_ram
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


module decoder_ram(
   input wire clk,
   input wire rst_n, 
   input wire we, 
   input wire re, 
   input wire [6:0] addr, 
   input wire [7:0] wdata, 
   output reg [7:0] rdata, 
   output reg valid
);
   
//loop variable
integer i = 0;
   
//Intermediate wirings
   wire [3:0] cs;  //chip select
   wire [4:0] word_address;
   
//Wiring Assignments
   assign cs[0] = addr[6:5] == 2'b00;
   assign cs[1] = addr[6:5] == 2'b01;
   assign cs[2] = addr[6:5] == 2'b10;
   assign cs[3] = addr[6:5] == 2'b11;
   assign word_address = addr[4:0];
   
//Memory
   reg [7:0] mem_block0[0:31];
   reg [7:0] mem_block1[0:31];
   reg [7:0] mem_block2[0:31];
   reg [7:0] mem_block3[0:31];
   
//Write
   always@(posedge clk, negedge rst_n) begin //write_logic
      if(!rst_n) begin //reset
         for(i = 0; i < 32; i = i + 1) begin
            mem_block0[i] = 8'h00;
            mem_block1[i] = 8'h00;
            mem_block2[i] = 8'h00;
            mem_block3[i] = 8'h00;
         end
      end //reset_end
      
      else begin //active_write
         if(we) begin
            case(cs)
               4'b0001: mem_block0[word_address] <= wdata; //cs0
               4'b0010: mem_block1[word_address] <= wdata; //cs1
               4'b0100: mem_block2[word_address] <= wdata; //cs2
               4'b1000: mem_block3[word_address] <= wdata; //cs3
               default: ; //default
            endcase
         end
      end //active_write_end
   end //write_logic_end
   
//Read
   always@(posedge clk, negedge rst_n) begin //read_logic
      if(!rst_n) begin //reset
         rdata <= 8'h00;
         valid <= 1'b0;
      end
      
      else begin //active_read
         case(cs) 
            4'b0001: rdata <= mem_block0[word_address];
            4'b0010: rdata <= mem_block1[word_address];
            4'b0100: rdata <= mem_block2[word_address];
            4'b1000: rdata <= mem_block3[word_address];
            default: rdata <= 8'h00;
         endcase
      end //active_read_end
   end //read_logic_end
   
endmodule
