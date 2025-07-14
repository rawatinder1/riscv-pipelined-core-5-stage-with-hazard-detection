// =============================================================================
// HAZARD DETECTION UNIT 
// =============================================================================
/*
module hazard_detection_unit(
    // Current instruction in ID stage (decoded combinationally)
    input [4:0] id_rs1,              // rs1 from current instruction
    input [4:0] id_rs2,              // rs2 from current instruction
   
    
    // From ID/EX pipeline register
    input [4:0] id_ex_rd,
    input id_ex_mem_read,            // Load instruction in EX stage (lb signal)
    
    
    // Control hazard inputs (from branch prediction or execution)
    input control_hazard,            // Branch misprediction or other control hazard
    
    // Outputs
    output reg stall_pc,             // Stall PC update
    output reg stall_if_id,          // Stall IF/ID register
    output reg if_id_flush,          // Flush IF/ID register
    output reg id_ex_flush           // Flush ID/EX register (insert bubble)
);


    // =================================================================
    // HAZARD DETECTION LOGIC
    // =================================================================

    always @(*) begin
        // Default values
        stall_pc = 1'b0;
        stall_if_id = 1'b0;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;
        
        // DATA HAZARD DETECTION
        // Load-use hazard: when a load instruction in EX stage 
        // has destination register that matches source register in ID stage
        // Note: If id_ex_mem_read is true, the instruction writes to a register
        if (id_ex_mem_read && id_ex_rd != 5'b0) begin
            if (( id_ex_rd == id_rs1) || 
                (id_ex_rd == id_rs2)) begin
                stall_pc = 1'b1;        // Don't update PC
                stall_if_id = 1'b1;     // Don't update IF/ID register
                id_ex_flush = 1'b1;     // Insert bubble in ID/EX (convert to NOP)
            end
        end
        
        // CONTROL HAZARD DETECTION
        // Flush pipeline on control hazard (branch misprediction, etc.)
        if (misprediction) begin
            if_id_flush = 1'b1;     // Flush IF/ID register
            id_ex_flush = 1'b1;     // Flush ID/EX register
            // Note: PC update handled by branch/jump logic
        end
    end

endmodule*/


module hazard_detection_unit(
    // Current instruction in ID stage (decoded combinationally)
    input [4:0] id_rs1,              // rs1 from current instruction
    input [4:0] id_rs2,              // rs2 from current instruction
    
    // From ID/EX pipeline register
    input [4:0] id_ex_rd,
    input id_ex_mem_read,            // Load instruction in EX stage
    
    // FIXED: Branch misprediction detection inputs (from EX/MEM stage)
    input branch_resolved,           // Branch instruction completed in EX
    input branch_taken_actual,       // Actual branch outcome
    input [31:0] branch_target_actual, // Actual branch target
    input [31:0] pc_plus_4,          // What we predicted (PC+4)
    
    // Outputs
    output reg stall_pc,             // Stall PC update
    output reg stall_if_id,          // Stall IF/ID register
    output reg if_id_flush,          // Flush IF/ID register
    output reg id_ex_flush           // Flush ID/EX register (insert bubble)
);

    // =================================================================
    // MISPREDICTION DETECTION LOGIC
    // =================================================================
    
    // For "always not-taken" predictor:
    // - We always predict "not-taken" (fetch PC+4)  
    // - Misprediction occurs when branch is actually taken
    wire misprediction;
    assign misprediction = branch_resolved && branch_taken_actual;
    
    // =================================================================
    // HAZARD DETECTION LOGIC
    // =================================================================
    
    always @(*) begin
        // Default values
        stall_pc = 1'b0;
        stall_if_id = 1'b0;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;
        
        // DATA HAZARD DETECTION
        // Load-use hazard: when a load instruction in EX stage 
        // has destination register that matches source register in ID stage
        if (id_ex_mem_read && id_ex_rd != 5'b0) begin
            if ((id_ex_rd == id_rs1) || (id_ex_rd == id_rs2)) begin
                stall_pc = 1'b1;        // Don't update PC
                stall_if_id = 1'b1;     // Don't update IF/ID register
                id_ex_flush = 1'b1;     // Insert bubble in ID/EX (convert to NOP)
            end
        end
        
        // CONTROL HAZARD DETECTION
        // Flush pipeline on branch misprediction
        if (misprediction) begin
            if_id_flush = 1'b1;         // Flush wrong instruction in IF/ID
            id_ex_flush = 1'b1;         // Flush wrong instruction in ID/EX
            // Note: PC redirect handled by branch/jump logic in EX stage
        end
    end

endmodule