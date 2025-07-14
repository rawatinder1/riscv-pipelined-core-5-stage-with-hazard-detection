
module control_unit(
    input [6:0] funct7,             //function 7 field 
    input [2:0] funct3,             //function 3 field
    input [6:0] opcode,             //opcode field         
    output reg [5:0] alu_control,   //alu_control for controlling the alu module
    output reg alu_src,
  
    output reg reg_write,
    output reg mem_to_reg,          //control signal for enabling data flow from memory to register
    output reg bneq_control,        //control signal for enabling bneq operation
    output reg beq_control,         //control signal for enabling beq operation
    output reg bgeq_control,        //control signal for enabling bgeq operation
    output reg blt_control,         //control signal for enabling blt operation
    output reg jump,                //control signal for enabling jump operation
    output reg store_enable,        //control signal for enabling store enable operation
    output reg lui_control,         //control signal for enabling lui operation
    output reg is_unsigned,
    output reg jalr,
    output reg [1:0] mem_size       // control signal for memory operation size
);

// Logic for analyzing the type of the instruction
always@(funct7 or funct3 or opcode) begin
    // Default values
    alu_control    = 6'b000000;
    alu_src        = 0;
    reg_write      = 0;
    mem_to_reg     = 0;
    beq_control    = 0;
    bneq_control   = 0;
    bgeq_control   = 0;
    blt_control    = 0;
    jump           = 0;
    store_enable   = 0;
    lui_control    = 0;
  
    is_unsigned    = 0;
    jalr           = 0;
    mem_size       = 2'b00;

    case(opcode)
        // R-TYPE INSTRUCTIONS
        7'b0110011: begin
            reg_write = 1;
            case(funct3)
                3'b000: begin // ADD/SUB
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b000001; // ADD
                    else if(funct7 == 7'b0100000)  // CORRECT funct7 for SUB
                        alu_control = 6'b000010; // SUB
                end
                3'b001: begin // SLL
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b000011; // SLL (Shift Left Logical)
                end
                3'b010: begin // SLT
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b000100; // SLT (Set Less Than)
                end
                3'b011: begin // SLTU
                    if(funct7 == 7'b0000000) begin
                        alu_control = 6'b000101; // SLTU (Set Less Than Unsigned)
                        is_unsigned = 1;
                    end
                end
                3'b100: begin // XOR
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b000110; // XOR
                end
                3'b101: begin // SRL/SRA
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b000111; // SRL (Shift Right Logical)
                    else if(funct7 == 7'b0100000)  
                        alu_control = 6'b001000; // SRA (Shift Right Arithmetic)
                end
                3'b110: begin // OR
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b001001; // OR
                end
                3'b111: begin // AND
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b001010; // AND
                end
            endcase
        end

        // I-TYPE INSTRUCTIONS (Immediate) 
        7'b0010011: begin
            reg_write = 1;
            alu_src   = 1;
            case(funct3)
                3'b000: alu_control = 6'b001011; // ADDI
                3'b001: begin // SLLI
                    if(funct7 == 7'b0000000)
                        alu_control = 6'b001100; // SLLI
                end
                3'b010: alu_control = 6'b001101; // SLTI
                3'b011: begin // SLTIU
                    alu_control = 6'b001110; // SLTIU
                    is_unsigned = 1;
                end
                3'b100: alu_control = 6'b001111; // XORI

                3'b101: begin // SRLI/SRAI

                    if(funct7 == 7'b0000000)
                        alu_control = 6'b010000; // SRLI

                    else if(funct7 == 7'b0100000)  
                        alu_control = 6'b010001; // SRAI
                end
                3'b110: alu_control = 6'b010010; // ORI 
                3'b111: alu_control = 6'b010011; // ANDI 
            endcase
        end

        // LOAD INSTRUCTIONS
        7'b0000011: begin
            reg_write = 1;
            mem_to_reg = 1;
            alu_src   = 1;
            case(funct3)
                3'b000: begin // LB (Load Byte)
                    alu_control = 6'b010100;
                    mem_size = 2'b00;      // 8-bit
                    is_unsigned = 0;
                end
                3'b001: begin // LH (Load Halfword)
                    alu_control = 6'b010101;
                    mem_size = 2'b01;      // 16-bit
                    is_unsigned = 0;
                end
                3'b010: begin // LW (Load Word)
                    alu_control = 6'b010110;
                    mem_size = 2'b10;      // 32-bit
                    is_unsigned = 0;
                end
                3'b100: begin // LBU (Load Byte Unsigned)
                    alu_control = 6'b010111;
                    mem_size = 2'b00;      // 8-bit
                    is_unsigned = 1;
                end
                3'b101: begin // LHU (Load Halfword Unsigned)
                    alu_control = 6'b011000;
                    mem_size = 2'b01;      // 16-bit
                    is_unsigned = 1;
                end
            endcase
        end

        // STORE INSTRUCTIONS
        7'b0100011: begin
            store_enable = 1;
            alu_src   = 1;
            case(funct3)
                3'b000: begin // SB (Store Byte)
                    alu_control = 6'b011001;
                    mem_size = 2'b00;      // 8-bit
                end
                3'b001: begin // SH (Store Halfword)
                    alu_control = 6'b011010;
                    mem_size = 2'b01;      // 16-bit
                end
                3'b010: begin // SW (Store Word)
                    alu_control = 6'b011011;
                    mem_size = 2'b10;      // 32-bit
                end
            endcase
        end

        // BRANCH INSTRUCTIONS
        7'b1100011: begin
            case(funct3)
                3'b000: begin // BEQ (Branch if Equal)
                    beq_control = 1;
                    alu_control = 6'b011100;
                end
                3'b001: begin // BNE (Branch if Not Equal)
                    bneq_control = 1;
                    alu_control = 6'b011101;
                end
                3'b100: begin // BLT (Branch if Less Than)
                    blt_control = 1;
                    alu_control = 6'b011110;
                    is_unsigned = 0;
                end
                3'b101: begin // BGE (Branch if Greater or Equal)
                    bgeq_control = 1;
                    alu_control = 6'b011111;
                    is_unsigned = 0;
                end
                3'b110: begin // BLTU (Branch if Less Than Unsigned)
                    blt_control = 1;
                    alu_control = 6'b100000;
                    is_unsigned = 1;
                end
                3'b111: begin // BGEU (Branch if Greater or Equal Unsigned)
                    bgeq_control = 1;
                    alu_control = 6'b100001;
                    is_unsigned = 1;
                end
            endcase
        end

        // LUI INSTRUCTION (Load Upper Immediate) - FIXED: unique code
        7'b0110111: begin
            reg_write = 1;
            alu_src   = 1;
            lui_control = 1;
            alu_control = 6'b100010; // LUI - FIXED: unique code
        end
        // JALR
        7'b1100111: begin
            if(funct3 == 3'b000) begin // JALR
                reg_write = 1;
                jalr = 1;
                alu_control = 6'b100100; // JALR operation
                alu_src   = 1;
            end
        end

        // JAL INSTRUCTION (Jump and Link)
        7'b1101111: begin
            reg_write = 1;
            jump = 1;
            alu_control = 6'b100011; 
            alu_src   = 1;
        end

        // Default case
        default: begin
            // All signals already set to default values above
        end
    endcase
end

endmodule