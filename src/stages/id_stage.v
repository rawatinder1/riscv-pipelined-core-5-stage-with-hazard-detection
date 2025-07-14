
module instruction_decode(
    input clk,
    input rst,
    input [31:0] pc_in,
    input [31:0] instruction_in,
    input [31:0] pc_plus_4_in,
    input [31:0] write_data,
    input reg_write,
    input [4:0] write_reg_num,

    // Hazard detection inputs (from top module)
    input [4:0] id_ex_rd,
    input id_ex_mem_read,
    input [4:0] ex_mem_rd,
    input ex_mem_mem_read,

    // Branch feedback for misprediction detection
    input ex_mem_branch_resolved,
    input ex_mem_branch_taken_actual,
    input [31:0] ex_mem_branch_target_actual,

    output [31:0] read_data1,
    output [31:0] read_data2,

    // Control signals
    output [5:0] alu_control,   
    output alu_src,
    output reg_write_out,
    output mem_to_reg,        
    output bneq_control,        
    output beq_control,         
    output bgeq_control,       
    output blt_control,         
    output jump,                
    output store_enable,       
    output lui_control,         
    output is_unsigned,
    output jalr,
    output [1:0] mem_size,
    output [31:0] selected_immediate,
    
    // Branch prediction outputs 
    output branch_prediction,
    output [31:0] predicted_target,
    output is_branch_instruction,
    output is_jump_instruction,
    
    // Hazard detection outputs
    output stall_pc,
    output stall_if_id,
    output if_id_flush,
    output id_ex_flush,

    output [31:0] debug_r1,
    output [31:0] debug_r2,
    output [31:0] debug_r9,
    output [31:0] debug_r10
);
  
    // Internal wires
    wire [31:0] imm_val_branch, imm_val_i, imm_val_jump, imm_val_lui, imm_val_store;
    wire [6:0] opcode = instruction_in[6:0];
    
    
    wire [4:0] rd = instruction_in[11:7];  // Extract rd field

    // Register file
    register_file rfu(
        .clk(clk),
        .rst(rst),
        .read_reg_num1(instruction_in[19:15]),
        .read_reg_num2(instruction_in[24:20]),
        .write_reg_num1(write_reg_num),
        .write_data(write_data),
        .reg_write(reg_write),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .debug_r1(debug_r1),
        .debug_r2(debug_r2),
        .debug_r9(debug_r9),
        .debug_r10(debug_r10)
    );

    // Control unit
    control_unit cu(
        .funct7(instruction_in[31:25]),
        .funct3(instruction_in[14:12]),
        .opcode(instruction_in[6:0]),
        .alu_control(alu_control),
        .alu_src(alu_src),
        .reg_write(reg_write_out),
        .mem_to_reg(mem_to_reg),
        .bneq_control(bneq_control),
        .beq_control(beq_control),
        .bgeq_control(bgeq_control),
        .blt_control(blt_control),
        .jump(jump),
        .store_enable(store_enable),
        .lui_control(lui_control),
        .is_unsigned(is_unsigned),
        .jalr(jalr),
        .mem_size(mem_size) 
    );

    // Simple branch predictor (always not-taken)
    assign branch_prediction = 1'b0;           // Always predict not-taken
    assign predicted_target = pc_plus_4_in;    // Always predict PC+4
    assign is_branch_instruction = 1'b0;       // Simplified for now
    assign is_jump_instruction = 1'b0;         // Simplified for now

    // Hazard detection unit 
    hazard_detection_unit hdu(
        .id_rs1(instruction_in[19:15]),
        .id_rs2(instruction_in[24:20]),
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),
        
        //  branch resolution signals
        .branch_resolved(ex_mem_branch_resolved),
        .branch_taken_actual(ex_mem_branch_taken_actual),
        .branch_target_actual(ex_mem_branch_target_actual),
        .pc_plus_4(pc_plus_4_in),
        
        .stall_pc(stall_pc),
        .stall_if_id(stall_if_id),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );

    // Immediate generation
    assign imm_val_i = {{20{instruction_in[31]}}, instruction_in[31:20]};          
    assign imm_val_branch = {{19{instruction_in[31]}}, instruction_in[31], instruction_in[7], instruction_in[30:25], instruction_in[11:8], 1'b0};
    assign imm_val_lui = {instruction_in[31:12], 12'b0};
    assign imm_val_jump = {{11{instruction_in[31]}}, instruction_in[31], instruction_in[19:12], instruction_in[20], instruction_in[30:21], 1'b0};
    assign imm_val_store = {{20{instruction_in[31]}}, instruction_in[31:25], instruction_in[11:7]};

    assign selected_immediate = 
        (opcode == 7'b0010011) ? imm_val_i :
        (opcode == 7'b0000011) ? imm_val_i :
        (opcode == 7'b0100011) ? imm_val_store :
        (opcode == 7'b1100011) ? imm_val_branch :
        (opcode == 7'b0110111) ? imm_val_lui :
        (opcode == 7'b1101111) ? imm_val_jump :
        (opcode == 7'b1100111) ? imm_val_i :
        32'h0;

    always @(posedge clk) begin
        if (pc_in == 32'h0000002C) begin
            $display("DECODE DEBUG: PC=0x2C, opcode=%b, rd=%d, jump=%b, instruction=%h", 
                     opcode, rd, jump, instruction_in);
        end
    end

endmodule