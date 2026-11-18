
module decoder_ram (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,
    input  wire        re,
    input  wire [6:0]  addr,
    input  wire [7:0]  wdata,
    output reg  [7:0]  rdata,
    output reg         valid
);
    //Decoder
    wire [3:0] cs;
    wire [4:0] word_addr;
    assign word_addr = addr[4:0];
    assign cs[0] = (addr[6:5] == 2'b00);
    assign cs[1] = (addr[6:5] == 2'b01);
    assign cs[2] = (addr[6:5] == 2'b10);
    assign cs[3] = (addr[6:5] == 2'b11);

    //Memory
    reg [7:0] mem_block0 [0:31];
    reg [7:0] mem_block1 [0:31];
    reg [7:0] mem_block2 [0:31];
    reg [7:0] mem_block3 [0:31];
  
    //Write logic + Reset clear
    //DUT and RM now share the same known initial state
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < 32; k = k + 1) begin
                mem_block0[k] <= 8'h00;
                mem_block1[k] <= 8'h00;
                mem_block2[k] <= 8'h00;
                mem_block3[k] <= 8'h00;
            end
        end else if (we) begin
            case (cs)
                4'b0001: mem_block0[word_addr] <= wdata;
                4'b0010: mem_block1[word_addr] <= wdata;
                4'b0100: mem_block2[word_addr] <= wdata;
                4'b1000: mem_block3[word_addr] <= wdata;
                default: ;
            endcase
        end
    end

    //Read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 8'h00;
            valid <= 1'b0;
        end else if (re) begin
            valid <= 1'b1;
            case (cs)
                4'b0001: rdata <= mem_block0[word_addr];
                4'b0010: rdata <= mem_block1[word_addr];
                4'b0100: rdata <= mem_block2[word_addr];
                4'b1000: rdata <= mem_block3[word_addr];
                default: rdata <= 8'hxx;
            endcase
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
