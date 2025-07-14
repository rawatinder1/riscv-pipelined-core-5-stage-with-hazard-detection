 module mem_stage(
    input clk,
    input rst,
    
    // Control signals from EX/MEM register
    input reg_write_in,
    input mem_to_reg_in,
    input store_enable_in,
   
    input lui_control_in,
    input jump_in,
    input jalr_in,
    input is_unsigned_in,
    input [1:0] mem_size_in,
    
    // Data signals from EX/MEM register
    input [31:0] alu_result_in,
    input [31:0] write_data_in,
    input [31:0] pc_plus_4_in,
    input [31:0] lui_imm_in,
    input [4:0] rd_in,
    input branch_taken_in,
    input [31:0] branch_target_in,
    
    // Control outputs to MEM/WB register
    output reg_write_out,
    output mem_to_reg_out,
    output lui_control_out,
    output jump_out,
    output jalr_out,
    
    // Data outputs to MEM/WB register
    output [31:0] alu_result_out,
    output [31:0] mem_data_out,
    output [31:0] pc_plus_4_out,
    output [31:0] lui_imm_out,
    output [4:0] rd_out,
    
    // Branch outputs (back to IF stage)
    output branch_taken_out,
    output [31:0] branch_target_out,
    output [31:0] debug_mem_addr_16
);

    // =================================================================
    // DATA MEMORY INSTANTIATION
    // =================================================================
    
    data_memory dmu(
        .clk(clk),
        .rst(rst),
        .read_addr(alu_result_in),
        .write_data(write_data_in),
        .write_enable(store_enable_in),
        .is_unsigned(is_unsigned_in),
        .write_addr(alu_result_in),
        .mem_size(mem_size_in),
        .read_data(mem_data_out),
        .debug_mem_addr_16(debug_mem_addr_16)
    );
    
    // =================================================================
    // CONTROL SIGNAL PASS-THROUGH
    // =================================================================
    
    assign reg_write_out = reg_write_in;
    assign mem_to_reg_out = mem_to_reg_in;
    assign lui_control_out = lui_control_in;
    assign jump_out = jump_in;
    assign jalr_out = jalr_in;
    
    // =================================================================
    // DATA SIGNAL PASS-THROUGH
    // =================================================================
    
    assign alu_result_out = alu_result_in;
    assign pc_plus_4_out = pc_plus_4_in;
    assign lui_imm_out = lui_imm_in;
    assign rd_out = rd_in;
    
    // =================================================================
    // BRANCH SIGNAL PASS-THROUGH (back to IF stage)
    // =================================================================
    
    assign branch_taken_out = branch_taken_in;
    assign branch_target_out = branch_target_in;

endmodule