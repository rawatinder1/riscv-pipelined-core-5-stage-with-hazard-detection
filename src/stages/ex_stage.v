module ex_stage(
    input clk,
    input rst,
    
    // Data inputs from ID/EX pipeline register
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] immediate_in,
    input [31:0] pc_in,
    input [31:0] pc_plus_4_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [4:0] shamt_in,
    
    // Control signals from ID/EX pipeline register
    input [5:0] alu_control_in,
    input alu_src_in,
    input beq_control_in,
    input bneq_control_in,
    input bgeq_control_in,
    input blt_control_in,
    input jump_in,
    input jalr_in,
    
    // Forwarding inputs (from later pipeline stages)
    input [31:0] ex_mem_alu_result,     // From EX/MEM register
    input [31:0] mem_wb_result,         // From MEM/WB register
    input [4:0] ex_mem_rd,              // From EX/MEM register
    input [4:0] mem_wb_rd,              // From MEM/WB register
    input ex_mem_reg_write,             // From EX/MEM register
    input mem_wb_reg_write,             // From MEM/WB register
    
    // Outputs
    output [31:0] alu_result_out,
    output [31:0] write_data_out,       // rs2 data for stores (forwarded)
    output [31:0] pc_plus_4_out,
    output [4:0] rd_out,

    output  branch_resolved,      // Set to 1 when processing branch/jump
    output branch_taken_out,
    output [31:0] branch_target_out
);

    // Internal wires
    wire [1:0] forward_a, forward_b;
    
    // Pass-through outputs
    assign pc_plus_4_out = pc_plus_4_in;
    assign rd_out = rd_in;
    
    // =================================================================
    // FORWARDING UNIT
    // =================================================================
    
    forwarding_unit fu(
        .id_ex_rs1(rs1_in),
        .id_ex_rs2(rs2_in),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forwardA(forward_a),
        .forwardB(forward_b)
    );
    
    // =================================================================
    // ALU WITH FORWARDING
    // =================================================================
    
    pipelined_alu alu(
        .read_data1_in(read_data1_in),
        .read_data2_in(read_data2_in),
        .ex_mem_alu_result_in(ex_mem_alu_result),
        .mem_wb_result_in(mem_wb_result),
        .forwardA(forward_a),
        .forwardB(forward_b),
        .alu_control(alu_control_in),
        .imm_val_r(immediate_in),
        .shamt(shamt_in),
        .alu_src(alu_src_in),
        .result(alu_result_out)
    );
    
    // =================================================================
    // FORWARDED DATA FOR STORE INSTRUCTIONS
    // =================================================================
    always @(posedge clk) begin
    if (is_branch || jump_in || jalr_in) begin
        $display("BRANCH DEBUG: PC=%h, imm=%h, target=%h, condition=%b", 
                 pc_in, immediate_in, branch_target_out, branch_condition_met);
    end
end
    // For store instructions, we need to forward rs2 data to memory stage
    assign write_data_out = (forward_b == 2'b00) ? read_data2_in :      // No forwarding
                           (forward_b == 2'b01) ? mem_wb_result :       // Forward from WB
                           (forward_b == 2'b10) ? ex_mem_alu_result :   // Forward from MEM
                           read_data2_in;                               // Default

    // =================================================================
    // BRANCH LOGIC (SIMPLIFIED - ALU DOES THE COMPARISON)
    // =================================================================
  
    // Branch taken decision - let ALU handle comparisons
    
    assign branch_resolved = beq_control_in || bneq_control_in || blt_control_in || bgeq_control_in|| jump_in || jalr_in;
    wire is_branch  = beq_control_in || bneq_control_in || blt_control_in || bgeq_control_in;
    
    wire branch_condition_met = (alu_result_out != 32'h0);
    
    assign branch_taken_out = (is_branch && branch_condition_met) ||  // Branch condition met
                         jump_in ||                               // JAL always taken
                         jalr_in;

    // Branch target calculation
    assign branch_target_out = jalr_in ? alu_result_out :                           // JALR: ALU result
                        jump_in ? (pc_in + immediate_in) :                   // JAL: PC + offset
                        (is_branch && branch_condition_met) ? (pc_in + immediate_in) : // Branch taken: PC + offset
                        pc_plus_4_in; 
endmodule

/*branch_resolved = "We processed a branch/jump instruction"
branch_taken_out = "The branch/jump actually changed the PC"*/