module write_back(
    
    
    // Control signals
    input reg_write_in,
    input mem_to_reg_in,
    input lui_control_in,
    input jump_in,
    input jalr_in,                  

    // Data inputs
    input [31:0] alu_result_in,
    input [31:0] mem_data_in,
    input [31:0] pc_plus_4_in,
    input [31:0] lui_imm_in,
    
    // ✅ FIXED: Added missing rd input for debug
    input [4:0] rd_register,

    // Outputs
    output wire [31:0] write_data
);

    assign write_data = reg_write_in ?
                            (mem_to_reg_in ? mem_data_in :          // Load data
                             (jump_in || jalr_in) ? pc_plus_4_in :  // Return address
                             lui_control_in ? lui_imm_in :          // LUI immediate
                             alu_result_in) :                       // Default: ALU result
                        32'h0;  // Don't care value when not writing

    
        
endmodule