module instruction_memory(
    input clk,
    input [31:0] pc,
    input reset,
    output [31:0] instruction_code
);
    
    reg [7:0] memory [255:0];  // 256 bytes
    
    assign instruction_code = {memory[pc+3],memory[pc+2],memory[pc+1],memory[pc]};
    
    integer i;
    
    always@(posedge clk) begin
        if(reset == 1) begin
            // Initialize all memory to 0
            for(i = 0; i < 256; i = i + 1)
                memory[i] = 8'h00;
            
            // =================================================================
            // BRANCH/JUMP/JALR TEST PROGRAM
            // =================================================================
            
            // Setup values for testing
            // PC=0x00: ADDI r1, r0, 10   (0x00A00093) - r1 = 10
            memory[3] = 8'h00; memory[2] = 8'hA0; memory[1] = 8'h00; memory[0] = 8'h93;
            
            // PC=0x04: ADDI r2, r0, 10   (0x00A00113) - r2 = 10 (same as r1)
            memory[7] = 8'h00; memory[6] = 8'hA0; memory[5] = 8'h01; memory[4] = 8'h13;
            
            // PC=0x08: ADDI r3, r0, 5    (0x00500193) - r3 = 5 (different from r1)
            memory[11] = 8'h00; memory[10] = 8'h50; memory[9] = 8'h01; memory[8] = 8'h93;
            
            // =================================================================
            // TEST 1: BEQ (Branch if Equal) - SHOULD BE TAKEN
            // =================================================================
            
            // PC=0x0C: BEQ r1, r2, 8     (0x00208463) - Branch if r1 == r2 (both are 10)
            // Should jump to PC=0x0C+8=0x14
            memory[15] = 8'h00; memory[14] = 8'h20; memory[13] = 8'h84; memory[12] = 8'h63;
            
            // PC=0x10: ADDI r9, r0, 99   (0x06300493) - Should be SKIPPED (flushed)
            memory[19] = 8'h06; memory[18] = 8'h30; memory[17] = 8'h04; memory[16] = 8'h93;
            
            // PC=0x14: ADDI r9, r0, 1    (0x00100493) - Target of BEQ, r9 = 1
            memory[23] = 8'h00; memory[22] = 8'h10; memory[21] = 8'h04; memory[20] = 8'h93;
            
            // =================================================================
            // TEST 2: BNE (Branch if Not Equal) - SHOULD BE TAKEN  
            // =================================================================
            
            // PC=0x18: BNE r1, r3, 8     (0x00309463) - Branch if r1 != r3 (10 != 5)
            // Should jump to PC=0x18+8=0x20
            memory[27] = 8'h00; memory[26] = 8'h30; memory[25] = 8'h94; memory[24] = 8'h63;
            
            // PC=0x1C: ADDI r9, r0, 99   (0x06300493) - Should be SKIPPED (flushed)
            memory[31] = 8'h06; memory[30] = 8'h30; memory[29] = 8'h04; memory[28] = 8'h93;
            
            // PC=0x20: ADDI r9, r0, 2    (0x00200493) - Target of BNE, r9 = 2
            memory[35] = 8'h00; memory[34] = 8'h20; memory[33] = 8'h04; memory[32] = 8'h93;
            
            // =================================================================
            // TEST 3: BEQ (Branch if Equal) - SHOULD NOT BE TAKEN
            // =================================================================
            
            // PC=0x24: BEQ r1, r3, 8     (0x00308463) - Branch if r1 == r3 (10 != 5)
            // Should NOT jump, continue to next instruction
            memory[39] = 8'h00; memory[38] = 8'h30; memory[37] = 8'h84; memory[36] = 8'h63;
            
            // PC=0x28: ADDI r9, r0, 3    (0x00300493) - Should execute, r9 = 3
            memory[43] = 8'h00; memory[42] = 8'h30; memory[41] = 8'h04; memory[40] = 8'h93;
            
            // =================================================================
            // TEST 4: JAL (Jump and Link) - ALWAYS TAKEN
            // =================================================================
            
            // PC=0x2C: JAL r10, 12       (0x00C005EF) - Jump to PC+12=0x38, save PC+4 to r10
           // JAL r10, 12 should be: 0x00C00AEF (rd=10, not rd=11)
            memory[47] = 8'h00; memory[46] = 8'hC0; memory[45] = 8'h05; memory[44] = 8'h6F;
            
            // PC=0x30: ADDI r9, r0, 99   (0x06300493) - Should be SKIPPED (flushed)
            memory[51] = 8'h06; memory[50] = 8'h30; memory[49] = 8'h04; memory[48] = 8'h93;
            
            // PC=0x34: ADDI r9, r0, 99   (0x06300493) - Should be SKIPPED (flushed)
            memory[55] = 8'h06; memory[54] = 8'h30; memory[53] = 8'h04; memory[52] = 8'h93;
            
            // PC=0x38: ADDI r9, r0, 4    (0x00400493) - Target of JAL, r9 = 4
            memory[59] = 8'h00; memory[58] = 8'h40; memory[57] = 8'h04; memory[56] = 8'h93;
            
            // =================================================================
            // TEST 5: JALR (Jump and Link Register) - ALWAYS TAKEN
            // =================================================================
            
            // PC=0x3C: ADDI r1, r0, 72   (0x04800093) - r1 = 72 (0x48) 
            memory[63] = 8'h04; memory[62] = 8'h80; memory[61] = 8'h00; memory[60] = 8'h93;
            
            // PC=0x40: JALR r2, r1, 0    (0x00008167) - Jump to r1+0=72, save PC+4 to r2
            memory[67] = 8'h00; memory[66] = 8'h00; memory[65] = 8'h81; memory[64] = 8'h67;
            
            // PC=0x44: ADDI r9, r0, 99   (0x06300493) - Should be SKIPPED (flushed)
            memory[71] = 8'h06; memory[70] = 8'h30; memory[69] = 8'h04; memory[68] = 8'h93;
            
            // PC=0x48: ADDI r9, r0, 5    (0x00500493) - Target of JALR, r9 = 5
            memory[75] = 8'h00; memory[74] = 8'h50; memory[73] = 8'h04; memory[72] = 8'h93;
            
            // =================================================================
            // END MARKER
            // =================================================================
            
            // PC=0x4C: ADDI r9, r0, 100  (0x06400493) - End marker, r9 = 100
            memory[79] = 8'h06; memory[78] = 8'h40; memory[77] = 8'h04; memory[76] = 8'h93;
            
            // Fill remaining memory with NOPs (ADDI r0, r0, 0 = 0x00000013)
            for(i = 80; i < 256; i = i + 4) begin
                if (i+3 < 256) begin
                    memory[i+3] = 8'h00;
                    memory[i+2] = 8'h00;
                    memory[i+1] = 8'h00;
                    memory[i+0] = 8'h13;
                end
            end
        end
    end
endmodule