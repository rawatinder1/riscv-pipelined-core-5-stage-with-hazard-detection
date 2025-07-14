
module pipelined_alu_tb();
    reg [31:0] read_data1_in, read_data2_in;
    reg [31:0] ex_mem_alu_result_in, mem_wb_result_in;
    reg [1:0] forwardA, forwardB;
    reg [5:0] alu_control;
    reg [31:0] imm_val_r;
    reg [4:0] shamt;
    reg alu_src;
    
    wire [31:0] result;
    
    pipelined_alu uut(
        .read_data1_in(read_data1_in),
        .read_data2_in(read_data2_in),
        .ex_mem_alu_result_in(ex_mem_alu_result_in),
        .mem_wb_result_in(mem_wb_result_in),
        .forwardA(forwardA),
        .forwardB(forwardB),
        .alu_control(alu_control),
        .imm_val_r(imm_val_r),
        .shamt(shamt),
        .alu_src(alu_src),
        .result(result)
    );
    
    initial begin
        // Initialize
        read_data1_in = 32'h10;
        read_data2_in = 32'h20;
        ex_mem_alu_result_in = 32'h100;
        mem_wb_result_in = 32'h200;
        forwardA = 2'b00;
        forwardB = 2'b00;
        alu_control = 6'b000001;  // ADD
        imm_val_r = 32'h5;
        shamt = 5'h2;
        alu_src = 1'b0;
        
        #10;
        
        // Test Case 1: No forwarding - simple ADD
        $display("=== Test Case 1: No forwarding ADD ===");
        $display("Result: %h (Expected: 30)", result);
        
        // Test Case 2: Forward from EX/MEM to src1
        $display("\n=== Test Case 2: Forward EX/MEM to src1 ===");
        forwardA = 2'b10;  // Forward from EX/MEM
        #1;
        $display("Result: %h (Expected: 120)", result);
        
        // Test Case 3: Forward from MEM/WB to src2
        $display("\n=== Test Case 3: Forward MEM/WB to src2 ===");
        forwardA = 2'b00;  // Reset src1 forwarding
        forwardB = 2'b01;  // Forward from MEM/WB
        #1;
        $display("Result: %h (Expected: 210)", result);
        
        // Test Case 4: Use immediate instead of rs2
        $display("\n=== Test Case 4: ADDI with immediate ===");
        forwardB = 2'b00;  // Reset src2 forwarding
        alu_src = 1'b1;    // Use immediate
        alu_control = 6'b001011;  // ADDI
        #1;
        $display("Result: %h (Expected: 15)", result);
        
        // Test Case 5: Branch comparison with forwarding
        $display("\n=== Test Case 5: BEQ with forwarding ===");
        alu_src = 1'b0;    // Use register
        alu_control = 6'b011100;  // BEQ
        forwardA = 2'b10;  // Forward 100 to src1
        forwardB = 2'b10;  // Forward 100 to src2
        #1;
        $display("Result: %h (Expected: 1 - equal)", result);
        
        $finish;
    end
    
endmodule
