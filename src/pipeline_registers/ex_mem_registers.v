module ex_mem_register(
    input clk,
    input rst,
    
    // Control signals
    input reg_write_in,
    input mem_to_reg_in,
    input store_enable_in,
    input lb_in,
    input lui_control_in,
    input jump_in,
    input jalr_in,
    input is_unsigned_in,
    input [1:0] mem_size_in,
    
    // Data signals
    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input [31:0] pc_plus_4_in,
    input [31:0] lui_imm_in,
    input [4:0] rd_in,
    input branch_resolved_in,        // Whether this was a branch/jump instruction
    input branch_taken_in,
    input [31:0] branch_target_in,
    
    // Control outputs
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg store_enable_out,
    output reg lb_out,
    output reg lui_control_out,
    output reg jump_out,
    output reg jalr_out,
    output reg is_unsigned_out,
    output reg [1:0] mem_size_out,
    
    // Data outputs
    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] lui_imm_out,
    output reg [4:0] rd_out,



    output reg branch_resolved_out,  // Pass through resolved signal
    output reg branch_taken_out,
    output reg [31:0] branch_target_out
);
    always @(posedge clk) begin
        if (rst) begin
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            store_enable_out <= 1'b0;
            lb_out <= 1'b0;
            lui_control_out <= 1'b0;
            jump_out <= 1'b0;
            jalr_out <= 1'b0;
            is_unsigned_out <= 1'b0;
            mem_size_out <= 2'b0;
            alu_result_out <= 32'h0;
            write_data_out <= 32'h0;
            pc_plus_4_out <= 32'h0;
            lui_imm_out <= 32'h0;
            rd_out <= 5'b0;

            branch_resolved_out <= 1'b0;
            branch_taken_out <= 1'b0;
            branch_target_out <= 32'h0;
        end
        else begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            store_enable_out <= store_enable_in;
            lb_out <= lb_in;
            lui_control_out <= lui_control_in;
            jump_out <= jump_in;
            jalr_out <= jalr_in;
            is_unsigned_out <= is_unsigned_in;
            mem_size_out <= mem_size_in;
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            pc_plus_4_out <= pc_plus_4_in;
            lui_imm_out <= lui_imm_in;
            rd_out <= rd_in;

            branch_resolved_out <= branch_resolved_in;
            branch_taken_out <= branch_taken_in;
            branch_target_out <= branch_target_in;
        end
    end
endmodule