
module pipelined_alu(
    // Original register file data
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    
    // Forwarded data from pipeline stages
    input [31:0] ex_mem_alu_result_in,
    input [31:0] mem_wb_result_in,        // This could be ALU result or memory data
    
    // Forwarding control signals
    input [1:0] forwardA,
    input [1:0] forwardB,
    
    // ALU control and immediate values
    input [5:0] alu_control,
    input [31:0] imm_val_r,
    input [4:0] shamt,
    input alu_src,                        // Select between rs2 and immediate
    
    output reg [31:0] result
);

    // Internal forwarded sources
    wire [31:0] forwarded_src1;
    wire [31:0] forwarded_src2_reg;       // Forwarded rs2 from register
    wire [31:0] final_src2;               // Final src2 after alu_src mux
    
    // =================================================================
    // FORWARDING MULTIPLEXERS
    // =================================================================
    
    // Forwarding MUX for src1 (rs1)
    assign forwarded_src1 = (forwardA == 2'b00) ? read_data1_in :
                           (forwardA == 2'b01) ? mem_wb_result_in :
                           (forwardA == 2'b10) ? ex_mem_alu_result_in :
                           read_data1_in;  // Default case
    
    // Forwarding MUX for src2 (rs2) 
    assign forwarded_src2_reg = (forwardB == 2'b00) ? read_data2_in :
                               (forwardB == 2'b01) ? mem_wb_result_in :
                               (forwardB == 2'b10) ? ex_mem_alu_result_in :
                               read_data2_in;  // Default case
    
    // ALU source MUX: choose between forwarded rs2 and immediate
    assign final_src2 = alu_src ? imm_val_r : forwarded_src2_reg;
    
    // =================================================================
    // ALU OPERATIONS
    // =================================================================
    
    always @(*) begin
        case(alu_control)
            // R-TYPE OPERATIONS
             // R-TYPE OPERATIONS
        6'b000001: begin                                                    // ADD
            result = forwarded_src1 + final_src2;
            $display("ALU ADD: %h + %h = %h", forwarded_src1, final_src2, result);
        end
        6'b000010: begin                                                    // SUB
            result = forwarded_src1 - final_src2;
            $display("ALU SUB: %h - %h = %h", forwarded_src1, final_src2, result);
        end
            6'b000011: result = forwarded_src1 << final_src2[4:0];                              // SLL
            6'b000100: result = ($signed(forwarded_src1) < $signed(final_src2)) ? 1 : 0;       // SLT
            6'b000101: result = (forwarded_src1 < final_src2) ? 1 : 0;                          // SLTU
            6'b000110: result = forwarded_src1 ^ final_src2;                                    // XOR
            6'b000111: result = forwarded_src1 >> final_src2[4:0];                              // SRL
            6'b001000: result = $signed(forwarded_src1) >>> final_src2[4:0];                    // SRA
            6'b001001: result = forwarded_src1 | final_src2;                                    // OR
            6'b001010: result = forwarded_src1 & final_src2;                                    // AND
            
            // I-TYPE IMMEDIATE OPERATIONS
            6'b001011: result = forwarded_src1 + imm_val_r;                               // ADDI
            6'b001100: result = forwarded_src1 << shamt;                                  // SLLI
            6'b001101: result = ($signed(forwarded_src1) < $signed(imm_val_r)) ? 1 : 0;   // SLTI
            6'b001110: result = (forwarded_src1 < imm_val_r) ? 1 : 0;                     // SLTIU
            6'b001111: result = forwarded_src1 ^ imm_val_r;                               // XORI
            6'b010000: result = forwarded_src1 >> shamt;                                  // SRLI
            6'b010001: result = $signed(forwarded_src1) >>> shamt;                        // SRAI
            6'b010010: result = forwarded_src1 | imm_val_r;                               // ORI
            6'b010011: result = forwarded_src1 & imm_val_r;                               // ANDI
            
            // LOAD OPERATIONS (Calculate address)
            6'b010100: result = forwarded_src1 + imm_val_r;                               // LB address
            6'b010101: result = forwarded_src1 + imm_val_r;                               // LH address
            6'b010110: result = forwarded_src1 + imm_val_r;                               // LW address
            6'b010111: result = forwarded_src1 + imm_val_r;                               // LBU address
            6'b011000: result = forwarded_src1 + imm_val_r;                               // LHU address
            
            // STORE OPERATIONS (Calculate address)
            6'b011001: result = forwarded_src1 + imm_val_r;                               // SB address
            6'b011010: result = forwarded_src1 + imm_val_r;                               // SH address
            6'b011011: result = forwarded_src1 + imm_val_r;                               // SW address
            
            // BRANCH OPERATIONS (Comparison) - Use forwarded values
            6'b011100: result = (forwarded_src1 == forwarded_src2_reg) ? 1 : 0;           // BEQ
            6'b011101: result = (forwarded_src1 != forwarded_src2_reg) ? 1 : 0;           // BNE
            6'b011110: result = ($signed(forwarded_src1) < $signed(forwarded_src2_reg)) ? 1 : 0;  // BLT
            6'b011111: result = ($signed(forwarded_src1) >= $signed(forwarded_src2_reg)) ? 1 : 0; // BGE
            6'b100000: result = (forwarded_src1 < forwarded_src2_reg) ? 1 : 0;            // BLTU
            6'b100001: result = (forwarded_src1 >= forwarded_src2_reg) ? 1 : 0;           // BGEU
            
            // U-TYPE AND J-TYPE OPERATIONS
            6'b100010: result = imm_val_r;                                      // LUI
            6'b100011: result = imm_val_r;
            6'b100100: result = (forwarded_src1 + imm_val_r) & ~1;             // JALR
            
            default: result = 32'h00000000;
        endcase
    end

endmodule