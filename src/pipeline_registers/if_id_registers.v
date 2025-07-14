// Pipeline Register: IF/ID (Start with this one)
module if_id_register(
    input clk,
    input rst,
    input stall,
    input flush,
    input [31:0] pc_in,
    input [31:0] instruction_in,
    input [31:0] pc_plus_4_in,
    
    output reg [31:0] pc_out,
    output reg [31:0] instruction_out,
    output reg [31:0] pc_plus_4_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            pc_out <= 32'h0;
            instruction_out <= 32'h0;
            pc_plus_4_out <= 32'h0;
        end
        else if (!stall) begin
            pc_out <= pc_in;
            instruction_out <= instruction_in;
            pc_plus_4_out <= pc_plus_4_in;
        end
    end
endmodule
