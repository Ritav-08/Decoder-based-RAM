
`ifndef RAM_TRANSACTION_SV
`define RAM_TRANSACTION_SV

typedef enum logic { WRITE = 1'b0, READ = 1'b1 } op_t;

class ram_transaction;

//transaction fields
    rand op_t       op;          // WRITE or READ
    rand logic [6:0] addr;       // 7-bit address (0..127)
    rand logic [7:0] wdata;      // data to write (unused for reads)
         logic [7:0] rdata;      // data captured on read
         logic       valid;      // read valid flag captured
	bit skip;
//constraints
    //full address range
    constraint addr_range_c {
        addr inside {[7'h00 : 7'h7F]};
    }

    //data byte can be anything
    constraint data_range_c {
        wdata inside {[8'h00 : 8'hFF]};
    }

//new construct
    function new();
        op    = WRITE;
        addr  = 7'h00;
        wdata = 8'h00;
        rdata = 8'h00;
        valid = 1'b0;
    endfunction

//deep copy
    function ram_transaction copy();
        copy       = new();
        copy.op    = this.op;
        copy.addr  = this.addr;
        copy.wdata = this.wdata;
        copy.rdata = this.rdata;
        copy.valid = this.valid;
    endfunction
  
//display header
    function void print(string tag = "");
        $display("[%0t] %s | op=%s addr=0x%02h wdata=0x%02h rdata=0x%02h valid=%0b",
                 $time, tag,
                 (op == WRITE) ? "WRITE" : "READ ",
                 addr, wdata, rdata, valid);
    endfunction

endclass : ram_transaction

`endif // RAM_TRANSACTION_SV
