// Pipeline Register: MEM/WB
module mem_wb_register(
    input clk,
    input rst,
    
    // Control signals
    input reg_write_in,
    input mem_to_reg_in,
    input lui_control_in,
    input jump_in,
    input jalr_in,
    
    // Data signals
    input [31:0] alu_result_in,
    input [31:0] mem_data_in,
    input [31:0] pc_plus_4_in,
    input [31:0] lui_imm_in,
    input [4:0] rd_in,
    
    // Control outputs
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg lui_control_out,
    output reg jump_out,
    output reg jalr_out,
    
    // Data outputs
    output reg [31:0] alu_result_out,
    output reg [31:0] mem_data_out,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] lui_imm_out,
    output reg [4:0] rd_out
);
    always @(posedge clk) begin
        if (rst) begin
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            lui_control_out <= 1'b0;
            jump_out <= 1'b0;
            jalr_out <= 1'b0;
            alu_result_out <= 32'h0;
            mem_data_out <= 32'h0;
            pc_plus_4_out <= 32'h0;
            lui_imm_out <= 32'h0;
            rd_out <= 5'b0;
        end
        else begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            lui_control_out <= lui_control_in;
            jump_out <= jump_in;
            jalr_out <= jalr_in;
            alu_result_out <= alu_result_in;
            mem_data_out <= mem_data_in;
            pc_plus_4_out <= pc_plus_4_in;
            lui_imm_out <= lui_imm_in;
            rd_out <= rd_in;
        end
    end
endmodule