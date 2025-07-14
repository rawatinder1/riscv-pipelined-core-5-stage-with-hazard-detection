
module forwarding_unit(
    input ex_mem_reg_write,
    input mem_wb_reg_write,         
    input [4:0] id_ex_rs1,
    input [4:0] id_ex_rs2,
    input [4:0] ex_mem_rd,
    input [4:0] mem_wb_rd,          
    
    output reg [1:0] forwardA,      
    output reg [1:0] forwardB       
);
   always @(*) begin
    // Default values
    forwardA = 2'b00;
    forwardB = 2'b00;
    
    // Debug prints
    $display("FORWARD DEBUG: rs1=%d rs2=%d ex_mem_rd=%d mem_wb_rd=%d ex_mem_wr=%b mem_wb_wr=%b", 
             id_ex_rs1, id_ex_rs2, ex_mem_rd, mem_wb_rd, ex_mem_reg_write, mem_wb_reg_write);
    
    // Your existing forwarding logic...
    if (ex_mem_reg_write && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs1) begin
        forwardA = 2'b10;
        $display("FORWARD A: EX->EX forwarding for rs1=%d", id_ex_rs1);
    end
    else if (mem_wb_reg_write && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs1) begin
        forwardA = 2'b01;
        $display("FORWARD A: MEM->EX forwarding for rs1=%d", id_ex_rs1);
    end
    
    // ... rest of logic
end

    always @(*) begin
        // Default values
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        // =================================================================
        // FORWARD A (rs1) LOGIC
        // =================================================================
        
        // EX hazard has priority over MEM hazard
        if (ex_mem_reg_write && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs1) begin
            forwardA = 2'b10;  // Forward from EX/MEM stage
        end
        // MEM hazard (only if no EX hazard)
        else if (mem_wb_reg_write && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs1) begin
            forwardA = 2'b01;  // Forward from MEM/WB stage
        end
        
        // =================================================================
        // FORWARD B (rs2) LOGIC
        // =================================================================
        
        // EX hazard has priority over MEM hazard
        if (ex_mem_reg_write && ex_mem_rd != 5'b0 && ex_mem_rd == id_ex_rs2) begin
            forwardB = 2'b10;  // Forward from EX/MEM stage
        end
        // MEM hazard (only if no EX hazard)
        else if (mem_wb_reg_write && mem_wb_rd != 5'b0 && mem_wb_rd == id_ex_rs2) begin
            forwardB = 2'b01;  // Forward from MEM/WB stage
        end
    end

endmodule