module branch_prediction_unit(
    input clk, rst,
    input [31:0] pc, instruction,
    input [31:0] branch_pc,
    input branch_resolved, branch_taken_actual,
    input [31:0] branch_target_actual,
    
    output reg prediction,
    output reg [31:0] predicted_target,
    output reg is_branch_instruction,
    output reg is_jump_instruction,
    output reg misprediction
);
    // Simple always-not-taken predictor
    always @(*) begin
        prediction = 1'b0;
        predicted_target = pc + 4;
        is_branch_instruction = 1'b0;
        is_jump_instruction = 1'b0;
        misprediction = 1'b0;
    end
endmodule