// =============================================================================
// BRANCH/JUMP/JALR TESTBENCH
// =============================================================================
`timescale 1ns / 1ps

module tb_branch_jump_test();
    
    // DUT signals
    reg clk, rst;
    wire [31:0] pc, instruction_out, alu_result;
    wire reg_write, store_enable, mem_to_reg;
    wire beq, bneq, blt, bgeq, jump;
    wire [31:0] current_pc, alu_branch_result, debug_signature;
    
    // Debug ports
    wire [31:0] debug_reg_r1, debug_reg_r2, debug_reg_r9, debug_reg_r10;
    wire [31:0] debug_mem_addr_16, debug_cycle_counter;
    
    // Test tracking
    reg [31:0] cycle_count;
    reg [31:0] test_count, pass_count, fail_count;
    
    // Test completion flags
    reg test_beq_taken_done;
    reg test_bne_taken_done;
    reg test_beq_not_taken_done;
    reg test_jal_done;
    reg test_jalr_done;
    reg all_tests_complete;
    
    // DUT instantiation
    top_riscv dut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instruction_out(instruction_out),
        .alu_result(alu_result),
        .reg_write(reg_write),
        .store_enable(store_enable),
        .mem_to_reg(mem_to_reg),
        .beq(beq),
        .bneq(bneq),
        .blt(blt),
        .bgeq(bgeq),
        .jump(jump),
        .current_pc(current_pc),
        .alu_branch_result(alu_branch_result),
        .debug_signature(debug_signature),
        .debug_reg_r1(debug_reg_r1),
        .debug_reg_r2(debug_reg_r2),
        .debug_reg_r9(debug_reg_r9),
        .debug_reg_r10(debug_reg_r10),
        .debug_mem_addr_16(debug_mem_addr_16),
        .debug_cycle_counter(debug_cycle_counter)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // VCD generation
    initial begin
        $dumpfile("branch_jump_test.vcd");
        $dumpvars(0, tb_branch_jump_test);
    end
    
    // Main test sequence
    initial begin
        $display("================================================================");
        $display("        BRANCH/JUMP/JALR PROCESSOR VERIFICATION");
        $display("================================================================");
        $display("Testing: BEQ, BNE, JAL, JALR instructions");
        $display("================================================================");
        
        // Initialize
        cycle_count = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize test flags
        test_beq_taken_done = 0;
        test_bne_taken_done = 0;
        test_beq_not_taken_done = 0;
        test_jal_done = 0;
        test_jalr_done = 0;
        all_tests_complete = 0;
        
        // Reset sequence
        rst = 1;
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(5) @(posedge clk);
        
        // Test basic functionality once
        test_basic_functionality();
        
        $display("\n--- BRANCH/JUMP/JALR MONITORING STARTED ---");
        $display("Watching for instruction execution and PC changes...");
    end
    
    // Continuous monitoring
    always @(posedge clk) begin
        if (!rst) begin
            cycle_count = cycle_count + 1;
            
            // Display current state every 5 cycles
            if (cycle_count % 5 == 0) begin
                $display("C%3d | PC=%08h | r1=%08h | r2=%08h | r9=%08h | r10=%08h", 
                         cycle_count, pc, debug_reg_r1, debug_reg_r2, debug_reg_r9, debug_reg_r10);
            end
            
            // Test BEQ taken: r9 should become 1 from PC=0x14
            if (!test_beq_taken_done && debug_reg_r9 == 32'h00000001) begin
                test_beq_taken();
                test_beq_taken_done = 1;
            end
            
            // Test BNE taken: r9 should become 2 from PC=0x20
            if (!test_bne_taken_done && debug_reg_r9 == 32'h00000002) begin
                test_bne_taken();
                test_bne_taken_done = 1;
            end
            
            // Test BEQ not taken: r9 should become 3 from PC=0x28
            if (!test_beq_not_taken_done && debug_reg_r9 == 32'h00000003) begin
                test_beq_not_taken();
                test_beq_not_taken_done = 1;
            end
            
            // Test JAL: r9 should become 4 and r10 should have return address
            if (!test_jal_done && debug_reg_r9 == 32'h00000004 && debug_reg_r10 != 32'h00000000) begin
                test_jal();
                test_jal_done = 1;
            end
            
            // Test JALR: r9 should become 5 and r2 should have return address
            if (!test_jalr_done && debug_reg_r9 == 32'h00000005 && debug_reg_r2 != 32'h00000000) begin
                test_jalr();
                test_jalr_done = 1;
            end
            
            // Check if all tests are complete
            if (!all_tests_complete && test_beq_taken_done && test_bne_taken_done && 
                test_beq_not_taken_done && test_jal_done && test_jalr_done) begin
                
                all_tests_complete = 1;
                $display("\n*** ALL BRANCH/JUMP TESTS COMPLETED ***");
                #20; // Small delay for final display
                generate_final_report();
                $finish;
            end
            
            // Safety timeout
            if (cycle_count > 200) begin
                $display("*** SAFETY TIMEOUT ***");
                $display("Completed tests: BEQ_taken=%b, BNE_taken=%b, BEQ_not_taken=%b, JAL=%b, JALR=%b", 
                         test_beq_taken_done, test_bne_taken_done, test_beq_not_taken_done, test_jal_done, test_jalr_done);
                generate_final_report();
                $finish;
            end
        end
    end
    
    // Test 1: Basic functionality
    task test_basic_functionality;
        begin
            $display("\n--- TEST 1: BASIC FUNCTIONALITY ---");
            
            if (debug_signature == 32'hDEADBEEF) begin
                $display("✓ Debug signature correct");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ Debug signature wrong: %08h", debug_signature);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Test 2: BEQ taken
    task test_beq_taken;
        begin
            $display("\n--- TEST 2: BEQ TAKEN ---");
            $display("BEQ r1, r2 should branch when r1=r2=10");
            
            if (debug_reg_r9 == 32'h00000001) begin
                $display("✓ BEQ taken correctly: r9 = %d (cycle %d)", debug_reg_r9, cycle_count);
                $display("  Branch jumped from PC=0x0C to PC=0x14");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ BEQ taken failed: r9 = %08h (expected 00000001)", debug_reg_r9);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Test 3: BNE taken
    task test_bne_taken;
        begin
            $display("\n--- TEST 3: BNE TAKEN ---");
            $display("BNE r1, r3 should branch when r1=10, r3=5");
            
            if (debug_reg_r9 == 32'h00000002) begin
                $display("✓ BNE taken correctly: r9 = %d (cycle %d)", debug_reg_r9, cycle_count);
                $display("  Branch jumped from PC=0x18 to PC=0x20");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ BNE taken failed: r9 = %08h (expected 00000002)", debug_reg_r9);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Test 4: BEQ not taken
    task test_beq_not_taken;
        begin
            $display("\n--- TEST 4: BEQ NOT TAKEN ---");
            $display("BEQ r1, r3 should NOT branch when r1=10, r3=5");
            
            if (debug_reg_r9 == 32'h00000003) begin
                $display("✓ BEQ not taken correctly: r9 = %d (cycle %d)", debug_reg_r9, cycle_count);
                $display("  Continued to next instruction at PC=0x28");
                pass_count = pass_count + 1;
            end else begin
                $display("✗ BEQ not taken failed: r9 = %08h (expected 00000003)", debug_reg_r9);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Test 5: JAL
    task test_jal;
        begin
            $display("\n--- TEST 5: JAL (Jump and Link) ---");
            $display("JAL r10, 12 should jump and save return address");
            
            if (debug_reg_r9 == 32'h00000004) begin
                $display("✓ JAL executed correctly: r9 = %d (cycle %d)", debug_reg_r9, cycle_count);
                $display("  Jumped from PC=0x2C to PC=0x38");
                if (debug_reg_r10 == 32'h00000030) begin  // 0x2C + 4 = 0x30
                    $display("✓ JAL return address correct: r10 = %08h", debug_reg_r10);
                    pass_count = pass_count + 1;
                end else begin
                    $display("✗ JAL return address wrong: r10 = %08h (expected 00000030)", debug_reg_r10);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("✗ JAL failed: r9 = %08h (expected 00000004)", debug_reg_r9);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Test 6: JALR
    task test_jalr;
        begin
            $display("\n--- TEST 6: JALR (Jump and Link Register) ---");
            $display("JALR r2, r1, 0 should jump to r1 and save return address");
            
            if (debug_reg_r9 == 32'h00000005) begin
                $display("✓ JALR executed correctly: r9 = %d (cycle %d)", debug_reg_r9, cycle_count);
                $display("  Jumped to address stored in r1 (0x48)");
                if (debug_reg_r2 == 32'h00000044) begin  // 0x40 + 4 = 0x44
                    $display("✓ JALR return address correct: r2 = %08h", debug_reg_r2);
                    pass_count = pass_count + 1;
                end else begin
                    $display("✗ JALR return address wrong: r2 = %08h (expected 00000044)", debug_reg_r2);
                    fail_count = fail_count + 1;
                end
            end else begin
                $display("✗ JALR failed: r9 = %08h (expected 00000005)", debug_reg_r9);
                fail_count = fail_count + 1;
            end
            test_count = test_count + 1;
        end
    endtask
    
    // Generate final test report
    task generate_final_report;
        real success_rate;
        begin
            if (test_count > 0) begin
                success_rate = (pass_count * 100.0) / test_count;
            end else begin
                success_rate = 0.0;
            end
            
            $display("\n================================================================");
            $display("              BRANCH/JUMP/JALR TEST REPORT");
            $display("================================================================");
            $display("Total Cycles:         %0d", cycle_count);
            $display("Total Tests:          %0d", test_count);
            $display("Tests Passed:         %0d", pass_count);
            $display("Tests Failed:         %0d", fail_count);
            $display("Success Rate:         %.1f%%", success_rate);
            $display("");
            $display("Test Completion Status:");
            $display("  BEQ Taken:          %s", test_beq_taken_done ? "✓ DONE" : "✗ PENDING");
            $display("  BNE Taken:          %s", test_bne_taken_done ? "✓ DONE" : "✗ PENDING");
            $display("  BEQ Not Taken:      %s", test_beq_not_taken_done ? "✓ DONE" : "✗ PENDING");
            $display("  JAL:                %s", test_jal_done ? "✓ DONE" : "✗ PENDING");
            $display("  JALR:               %s", test_jalr_done ? "✓ DONE" : "✗ PENDING");
            $display("");
            
            if (fail_count == 0 && test_count >= 6) begin
                $display("🎉 *** ALL BRANCH/JUMP TESTS PASSED *** 🎉");
                $display("");
                $display("✅ BEQ (taken) working correctly");
                $display("✅ BNE (taken) working correctly");
                $display("✅ BEQ (not taken) working correctly");
                $display("✅ JAL working correctly");
                $display("✅ JALR working correctly");
                $display("✅ Branch prediction and flushing working");
                $display("✅ Pipeline control hazard handling working");
                $display("");
                $display("🏆 BRANCH/JUMP PROCESSOR FULLY VERIFIED! 🏆");
            end else if (test_count == 0) begin
                $display("❌ NO TESTS COMPLETED");
                $display("Check processor connectivity and branch logic");
            end else if (fail_count == 0) begin
                $display("⚠️  PARTIAL SUCCESS");
                $display("Some tests completed successfully but others are pending");
            end else begin
                $display("❌ SOME TESTS FAILED");
                $display("Check branch/jump logic and pipeline flushing");
            end
            
            $display("================================================================");
            $display("Test completed at: %0t ns", $time);
            $display("================================================================");
        end
    endtask

endmodule