module instruction_fetch(
    input clk,
    input rst,
    
    // Hazard control signals
    input stall_pc,              // From hazard detection unit
    
    // Branch/Jump control from EX/MEM stage
    input branch_taken,          // Branch was taken
    input jump_taken,            // Jump was taken (JAL)
    input jalr_taken,            // JALR was taken
    input [31:0] branch_target,  // Target address for branch/jump
    
    // Outputs to IF/ID pipeline register
    output [31:0] pc_out,
    output [31:0] instruction_out,
    output [31:0] pc_plus_4_out
);

    // PC register
    reg [31:0] pc;
    
    // PC + 4 calculation
    wire [31:0] pc_plus_4 = pc + 4;
    
    // Next PC calculation
    wire [31:0] next_pc;
    
    // PC update logic
    assign next_pc = (branch_taken || jump_taken || jalr_taken) ? branch_target :
                     pc_plus_4;
    always @(posedge clk) begin
    if (!rst) begin
        $display("PC_DEBUG: old_pc=%h, pc_plus_4=%h, next_pc=%h, branch_taken=%b, jump_taken=%b, jalr_taken=%b, branch_target=%h, stall_pc=%b", 
                 pc, pc_plus_4, next_pc, branch_taken, jump_taken, jalr_taken, branch_target, stall_pc);
    end
end
    // PC register update
    always @(posedge clk) begin
        if (rst) begin
            pc <= 32'h0;  // Start at address 0
        end
        else if (!stall_pc) begin  // Only update if not stalled
            pc <= next_pc;
        end
        // If stalled, PC stays the same
    end
    
    // Instantiate instruction memory (your existing module)
    instruction_memory imem(
        .clk(clk),
        .pc(pc),
        .reset(rst),
        .instruction_code(instruction_out)
    );
    
    // Output assignments
    assign pc_out = pc;
    assign pc_plus_4_out = pc_plus_4;


// In instruction_fetch.v
always @(posedge clk) begin
    if (pc_out >= 32'h00000028 && pc_out <= 32'h00000030) begin
        $display("FETCH DEBUG: PC=%h, instruction=%h, branch_taken=%b", 
                 pc_out, instruction_out, branch_taken);
    end
end
    
endmodule
