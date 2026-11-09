`timescale 1ns / 1ps
`include "classes.sv/ram_env";

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 11:17:04 AM
// Design Name: 
// Module Name: ram_base_test
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


class ram_base_test;
   //interface
   virtual ram_if.WRITE_DRV wr_vif;
   virtual ram_if.READ_DRV rd_vif;
   virtual ram_if.WR_MON wr_mon_vif;
   virtual ram_if.RD_MON rd_mon_vif;
   
   //instantiation
   ram_env env;
   
   //intermediate variables
   logic [6:0] empty_addrs[];
   logic [7:0] empty_datas[];
   
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
      empty_addrs = new[0]; 
      empty_datas = new[0];
   endfunction
   
   //build function
   virtual function void built_env();
      env = new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
      env.build();
   endfunction
   
   //body task: base test body
   virtual task body();
      $fatal(1, "[TEST] base body() called directly: Override in child");
   endtask
   
   //drain task
   task drain(
      int unsigned cycles = 30
   );
      repeat(cycles) @(env.wr_vif.we_cb);
      env.report();
   endtask
   
   //run task
   task run();
      build_env();
      env.start();
      body();
      drain();
   endtask
   
   //write then read task
   task do_writes_then_reads(
      input logic [6:0] addrs[], 
      input logic [7:0] datas[], 
      input int unsigned n 
   );
      env.run(
         addrs, 
         datas,
         n, 
         addrs, 
         n, 
         0
      );
   endtask
   
   //writes only task
   task do_writes_only(
      input logic [6:0] addrs[], 
      input logic [7:0] datas[], 
      input int unsigned n
   );
      env.run(
         addrs, 
         datas, 
         n, 
         empty_addrs, 
         0, 
         0
      );
   endtask
   
   //reads only task
   task do_reads_only(
      input logic [6:0] addrs[], 
      input int unsigned n
   );
      env.run(
         empty_addrs, 
         empty_datas, 
         0, 
         addrs, 
         n, 
         0
      );
   endtask
   
   //write then read with different address task
   task do_writes_then_reads_diff_addr(
      input logic [6:0] wr_addrs[], 
      input logic [7:0] wr_datas[], 
      input int unsigned n_writes, 
      input logic [6:0] rd_addrs[], 
      input int unsigned n_reads
   );
      env.run(
         wr_addrs, 
         wr_datas, 
         n_writes, 
         rd_addrs, 
         n_reads, 
         0
      );
   endtask
   
endclass


// ----------- TEST 1 :: Random R/W ----------- 
class ram_random_test extends ram_base_test;
   //intermediate variables
   int unsigned num_writes;
   int unsigned reads;
   
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif, 
      int unsigned num_writes = 32, 
      int unsigned num_reads = 16
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
      this.num_writes = num_writes;
      this.num_reads = num_reads;
   endfunction
   
   //body task
   virtual task body();
      $display("\n[TEST] ----- ram_random_test -----");
      env.run(
         empty_addrs, 
         empty_datas, 
         num_writes, 
         empty_addrs, 
         1
      );
   endtask
   
endclass : ram_random_test


// ----------- TEST 2 :: Block Boundary ----------- 
class ram_block_boundary_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      addrs = new[8];
      datas = new[8];
      rd_addrs = new[8];
      $display("\n[TEST] ----- ram_block_boundary_test -----");
      addrs[0] = 7'h00; addrs[1] = 7'h1F;
      addrs[2] = 7'h20; addrs[3] = 7'h3F;
      addrs[4] = 7'h40; addrs[5] = 7'h5F;
      addrs[6] = 7'h60; addrs[7] = 7'h7F;
      datas[0] = 8'hAA; datas[1] = 8'hBB;
      datas[2] = 8'hCC; datas[3] = 8'hDD;
      datas[4] = 8'hEE; datas[5] = 8'hFF;
      datas[6] = 8'h11; datas[7] = 8'h22;
      rd_addrs[0] = 7'h00; rd_addrs[1] = 7'h1F;
      rd_addrs[2] = 7'h20; rd_addrs[3] = 7'h3F;
      rd_addrs[4] = 7'h40; rd_addrs[5] = 7'h5F;
      rd_addrs[6] = 7'h60; rd_addrs[7] = 7'h7F;
      do_writes_then_reads_diff_addr(
         addrs, 
         datas, 
         8, 
         rd_addrs, 
         8
      );
   endtask 
   
endclass : ram_block_boundary_test
   
// ----------- TEST 3 :: Full Address Sweep -----------
class ram_full_sweep_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[128];
      datas = new[128];
      rd_addrs = new[128];
      $display("\n[TEST] ----- ram_full_sweep_test -----");
      for(i = 0; i < 128; i++) begin
         addrs[i] = i[6:0];
         datas[i] = ~i[7:0];
         rd_addrs[i] = i[6:0];
      end
      do_writes_then_reads_diff_addr(
         addrs, 
         datas, 
         128, 
         rd_addrs, 
         128
      );
   endtask 
   
endclass : ram_full_sweep_test

   
// ----------- TEST 4 :: Walking 1s on Data Bus -----------
class ram_walking1_data_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[8];
      datas = new[8];
      rd_addrs = new[8];
      $display("\n[TEST] ----- ram_walking_data_test -----");
      for(i = 0; i < 8; i++) begin
         addrs[i] = i[6:0];
         datas[i] = 8'h01 << i;
         rd_addrs[i] = i[6:0];
      end
      do_writes_then_reads_diff_addr(
         addrs, 
         datas, 
         8, 
         rd_addrs, 
         8
      );
   endtask 
endclass : ram_walking1_data_test


// ----------- TEST 5 :: Walking 0s on Data Bus -----------
class ram_walking0_data_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[8];
      datas = new[8];
      rd_addrs = new[8];
      $display("\n[TEST] ----- ram_walking_data_test -----");
      for(i = 0; i < 8; i++) begin
         addrs[i] = i[6:0];
         datas[i] = ~(8'h01 << i);
         rd_addrs[i] = i[6:0];
      end
      do_writes_then_reads_diff_addr(
         addrs, 
         datas, 
         8, 
         rd_addrs, 
         8
      );
   endtask 
endclass : ram_walking0_data_test


// ----------- TEST 6 :: Walking 1s on Address Bus -----------
class ram_walking1_addr_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[7];
      datas = new[7];
      rd_addrs = new[7];
      $display("\n[TEST] ----- ram_walking_data_test -----");
      for(i = 0; i < 7; i++) begin
         addrs[i] = 7'h01 << i;
         datas[i] = 8'hA0 | i[7:0];
         rd_addrs[i] = 7'h01 << i;
      end
      do_writes_then_reads_diff_addr(
         addrs, 
         datas, 
         7, 
         rd_addrs, 
         7
      );
   endtask 
endclass : ram_walking1_addr_test


// ----------- TEST 6 :: Walking 0s on Address Bus -----------
class ram_walking0_addr_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[7];
      datas = new[7];
      rd_addrs = new[7];
      $display("\n[TEST] ----- ram_walking_data_test -----");
      for(i = 0; i < 7; i++) begin
         addrs[i] = ~(7'h01 << i);
         datas[i] = 8'hB0 | i[7:0];
         rd_addrs[i] = ~(7'h01 << i);
      end
      do_writes_then_reads_diff_addr(
         addrs, 
         datas, 
         7, 
         rd_addrs, 
         7
      );
   endtask 
endclass : ram_walking0_addr_test


// ----------- TEST 8 :: Same Address Back-to-Back Overwrite -----------
class ram_same_addr_overwrite_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //body task
   virtual task body();
      logic [6:0] victims[];
      logic [7:0] first_data[];
      logic [7:0] second_data[];
      logic [6:0] a[];
      logic [6:0] ra[];
      logic [7:0] d1[];
      logic [7:0] d2[];
      int i;
      victims = new[8];
      first_data = new[8];
      second_data = new[8];
      a = new[1];
      ra = new[1];
      d1 = new[1];
      d2 = new[1];
      $display("\n[TEST] ----- ram_same_addr_overwrite_test -----");
      victims[0] = 7'h00; //first address
      victims[1] = 7'h10; //aligned/block boundary
      victims[2] = 7'h1F; //end of block
      victims[3] = 7'h20; //next block start
      victims[4] = 7'h3F; //anther boundary
      victims[5] = 7'h55; //alternating bit pattern
      victims[6] = 7'h70; //upper region
      victims[7] = 7'h7F; //last address
      
      first_data[0] = 8'hAA; //alternating 1010
      first_data[1] = 8'h55; //alternating 0101
      first_data[2] = 8'hFF; //all 1s
      first_data[3] = 8'h00; //all 0s
      first_data[4] = 8'h0F; //lower nibble
      first_data[5] = 8'hF0; //upper nibble
      first_data[6] = 8'hA5; //mixed
      first_data[7] = 8'h5A; //mixed inverse
      
      second_data[0] = 8'h55;
      second_data[1] = 8'hAA;
      second_data[2] = 8'h00;
      second_data[3] = 8'hFF;
      second_data[4] = 8'hF0;
      second_data[5] = 8'h0F;
      second_data[6] = 8'h5A;
      second_data[7] = 8'hA5;
      for(i = 0; i < 8; i++) begin
         a[0] = victims[i];
         ra[0] = victims[i];
         d1[0] = first_data[i];
         d2[0] = second_data[i];
         do_writes_only(
            a, 
            d1, 
            1
         );
         do_writes_only(
            a, 
            d2, 
            1
         );
         do_reads_only(
            ra, 
            1
         );
      end
   endtask
   
endclass : ram_same_addr_overwrite_test


// ----------- TEST 9 :: Toggle (Write-Read-Write-Read) Same Address -----------
class ram_toggle_addr_test extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [6:0] a[];
      logic [6:0] ra[];
      logic [7:0] d1[];
      logic [7:0] d2[];
      int i;
      addrs = new[4];
      a = new[1];
      ra = new[1];
      d1 = new[1];
      d2 = new[1];
      $display("\n[TEST] ----- ram_toggle_adddr_test -----");
      addrs[0] = 7'h00; addrs[1] = 7'h2A;
      addrs[2] = 7'h55; addrs[3] = 7'h7F;
      d1[0] = 8'hC3;
      d2[0] = 8'h3C;
      for(i = 0; i < 4; i++) begin
         a[0] = addrs[i];
         ra[0] = addrs[i];
         do_writes_only(
            a, 
            d1, 
            1
         );
         do_reads_only(
            ra, 
            1
         );
         do_writes_only(
            a,
            d2, 
            1
         );
         do_reads_only(
            ra, 
            1
         );
      end
   endtask 
endclass : ram_toggle_addr_test


// ----------- TEST 10 :: Checkboard pattern -----------
class ram_checkboard_pattern extends ram_base_test;
   //new construct
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[128];
      datas = new[128];
      rd_addrs = new[128];
      
      $display("\n[TEST] ----- ram_checkboard_test -----");
      for(i = 0; i < 128; i++) begin
         addrs[i] = i[6:0];
         rd_addrs[i] = i[6:0];
      end
      //pass 1: 0xAA/0x55
      for(i = 0; i < 128; i++) begin
         datas[i] = (i % 2 == 0) ? 8'hAA : 8'h55;
         do_writes_then_reads_diff_addr(
            addrs, 
            datas, 
            128, 
            rd_addrs, 
            128
         );
      end
      //pass 2: inverted
      for(i = 0; i < 128; i++) begin
         datas[i] = (i % 2 == 0) ? 8'h55 : 8'hAA;
         do_writes_then_reads_diff_addr(
            addrs, 
            datas, 
            128, 
            rd_addrs, 
            128
         );
      end
   endtask 
endclass : ram_checkboard_pattern


// ----------- TEST 11 :: Block Isolation -----------
class ram_block_isolation_test extends ram_base_test;
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] blk0_addrs[];
      logic [7:0] blk0_datas[];
      logic [6:0] blk123_addrs[];
      logic [7:0] blk123_datas[];
      logic [6:0] rd_addrs[];
      int i;
      int tmp;
      blk0_addrs = new[32];
      blk0_datas = new[32];
      blk123_addrs = new[96];
      blk123_datas = new[96];
      rd_addrs = new[32];
      $display("\n[TEST] ----- ram_block_isolation_test -----");
      for(i = 0; i < 32; i++) begin
         blk0_addrs[i] = i[6:0];
         blk0_datas[i] = 8'hDE;
         rd_addrs[i] = i[6:0];
      end
      for(i = 0; i < 96; i++) begin
         tmp = i + 32; //compute first
         blk123_addrs[i] = tmp[6:0]; //thrn bit select on variable
         blk123_datas[i] = i[0] ? 8'hFF : 8'h00;
      end
      do_writes_only(
         blk0_addrs, 
         blk0_datas, 
         32
      );
      do_writes_only(
         blk0_addrs, 
         blk0_datas, 
         32
      );
      do_writes_only(
         blk123_addrs, 
         blk123_datas, 
         96
      );
      do_reads_only(
         rd_addrs, 
         32
      );
   endtask
   
endclass : ram_block_isolation_test


// ----------- TEST 12 :: All Zeroes Data -----------
class ram_allzero_test extends ram_base_test;
   function new(
      virtual ram_if.WRITE_DRV wr_vif, 
      virtual ram_if.READ_DRV rd_vif, 
      virtual ram_if.WR.MON wr_mon_vif, 
      virtual ram_if.RD_MON rd_mon_vif
   );
      super.new(
         wr_vif, 
         rd_vif, 
         wr_mon_vif, 
         rd_mon_vif
      );
   endfunction 
   
   //drain task
   task drain(
      int unsigned cycles = 400
   );
      repeat (cycles) @(env.wr_vif.wr_cb);
      env.report();
   endtask
   
   //body task
   virtual task body();
      logic [6:0] addrs[];
      logic [7:0] datas[];
      logic [6:0] rd_addrs[];
      int i;
      addrs = new[128];
      //pending 8888888888888**************888888888888
   endtask
   
endclass