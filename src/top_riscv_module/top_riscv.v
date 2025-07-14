module top_riscv(
    input clk,
    input rst,
    
    // ===== DEBUG PORTS FOR TESTBENCH =====
    output [31:0] pc,                    // Current PC
    output [31:0] instruction_out,       // Current instruction
    output [31:0] alu_result,           // ALU result
    output reg_write,                   // Register write enable
    output store_enable,                // Store enable
    output mem_to_reg,                  // Memory to register
    output beq,                         // BEQ control signal
    output bneq,                        // BNE control signal
    output [31:0] current_pc,           // Current PC (alias)
    output blt,                         // BLT control signal
    output bgeq,                        // BGE control signal
    output jump,                        // Jump control signal
    output [31:0] alu_branch_result,     // Branch comparison result
    output [31:0] debug_signature,
    
    output [31:0] debug_reg_r1,
    output [31:0] debug_reg_r2,
    output [31:0] debug_reg_r9,
    output [31:0] debug_reg_r10,
    output [31:0] debug_mem_addr_16,
    output [31:0] debug_cycle_counter
);

    // =================================================================
    // CYCLE COUNTER FOR DEBUG
    // =================================================================
    reg [31:0] cycle_counter;
    
    always @(posedge clk) begin
       if (rst) begin
        cycle_counter <= 0;
       end else begin
        cycle_counter <= cycle_counter + 1;
       end
    end

   assign debug_cycle_counter = cycle_counter;

   always @(posedge clk) begin
        $display("TOP DUT >>> internal cycle = %0d", cycle_counter);
   end

    // =================================================================
    // PIPELINE STAGE INTERCONNECT WIRES
    // =================================================================
   
    assign debug_signature = 32'hDEADBEEF;
    
    // IF Stage outputs
    wire [31:0] if_pc;
    wire [31:0] if_instruction;
    wire [31:0] if_pc_plus_4;
    
    // IF/ID Pipeline Register outputs
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instruction;
    wire [31:0] if_id_pc_plus_4;
    
    // ID Stage outputs
    wire [31:0] id_read_data1;
    wire [31:0] id_read_data2;
    wire [5:0] id_alu_control;
    wire id_alu_src;
    wire id_reg_write;
    wire id_mem_to_reg;
    wire id_bneq_control;
    wire id_beq_control;
    wire id_bgeq_control;
    wire id_blt_control;
    wire id_jump;
    wire id_store_enable;
    wire id_lui_control;
    wire id_is_unsigned;
    wire id_jalr;
    wire [1:0] id_mem_size;
    wire [31:0] id_selected_immediate;
    
    // Hazard Detection outputs
    wire stall_pc;
    wire stall_if_id;
    wire if_id_flush;
    wire id_ex_flush;
    
    // ID/EX Pipeline Register outputs
    wire id_ex_reg_write;
    wire id_ex_mem_to_reg;
    wire [5:0] id_ex_alu_control;
    wire id_ex_alu_src;
    wire id_ex_store_enable;
    wire id_ex_beq_control;
    wire id_ex_bneq_control;
    wire id_ex_bgeq_control;
    wire id_ex_blt_control;
    wire id_ex_jump;
    wire id_ex_jalr;
    wire id_ex_lui_control;
    wire id_ex_lb;
    wire id_ex_is_unsigned;
    wire [1:0] id_ex_mem_size;
    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_pc_plus_4;
    wire [31:0] id_ex_read_data1;
    wire [31:0] id_ex_read_data2;
    wire [31:0] id_ex_immediate;
    wire [4:0] id_ex_rs1;
    wire [4:0] id_ex_rs2;
    wire [4:0] id_ex_rd;
    wire [4:0] id_ex_shamt;
    
    // EX Stage outputs
    wire [31:0] ex_alu_result;
    wire [31:0] ex_write_data;
    wire [31:0] ex_pc_plus_4;
    wire [4:0] ex_rd;
    wire ex_branch_resolved;          
    wire ex_branch_taken;
    wire [31:0] ex_branch_target;
    
    // EX/MEM Pipeline Register outputs
    wire ex_mem_reg_write;
    wire ex_mem_mem_to_reg;
    wire ex_mem_store_enable;
    wire ex_mem_lb;
    wire ex_mem_lui_control;
    wire ex_mem_jump;
    wire ex_mem_jalr;
    wire ex_mem_is_unsigned;
    wire [1:0] ex_mem_mem_size;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_write_data;
    wire [31:0] ex_mem_pc_plus_4;
    wire [31:0] ex_mem_lui_imm;
    wire [4:0] ex_mem_rd;
    wire ex_mem_branch_resolved;     
    wire ex_mem_branch_taken;
    wire [31:0] ex_mem_branch_target;
    
    // MEM Stage outputs
    wire mem_reg_write;
    wire mem_mem_to_reg;
    wire mem_lui_control;
    wire mem_jump;
    wire mem_jalr;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_data;
    wire [31:0] mem_pc_plus_4;
    wire [31:0] mem_lui_imm;
    wire [4:0] mem_rd;
    wire mem_branch_taken;
    wire [31:0] mem_branch_target;
    
    // MEM/WB Pipeline Register outputs
    wire mem_wb_reg_write;
    wire mem_wb_mem_to_reg;
    wire mem_wb_lui_control;
    wire mem_wb_jump;
    wire mem_wb_jalr;
    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_data;
    wire [31:0] mem_wb_pc_plus_4;
    wire [31:0] mem_wb_lui_imm;
    wire [4:0] mem_wb_rd;
    
    // Debug signal wires
    wire [31:0] debug_r1_internal;
    wire [31:0] debug_r2_internal; 
    wire [31:0] debug_r9_internal;
    wire [31:0] debug_r10_internal;
    wire [31:0] debug_mem_internal;
    
    // WB Stage outputs
    wire [31:0] wb_write_data;
    
    
    wire control_transfer = ex_mem_branch_taken || ex_mem_jump || ex_mem_jalr;
    
    // =================================================================
    // DEBUG PORT ASSIGNMENTS
    // =================================================================
    
    // Map internal signals to debug outputs
    assign pc = if_pc;                              // Current PC from IF stage
    assign instruction_out = if_instruction;        // Current instruction from IF stage
    assign alu_result = ex_alu_result;             // ALU result from EX stage
    assign reg_write = mem_wb_reg_write;           // Register write from WB stage
    assign store_enable = ex_mem_store_enable;     // Store enable from MEM stage

    assign current_pc = if_pc;                     // Alias for PC
    assign mem_to_reg = ex_mem_mem_to_reg;         
    assign alu_branch_result = ex_alu_result;     
    assign beq = (ex_branch_taken && id_ex_beq_control);   
    assign bneq = (ex_branch_taken && id_ex_bneq_control);  
    assign blt = (ex_branch_taken && id_ex_blt_control);   
    assign bgeq = (ex_branch_taken && id_ex_bgeq_control); 
    assign jump = (ex_branch_taken && id_ex_jump);     

    assign debug_reg_r1 = debug_r1_internal;
    assign debug_reg_r2 = debug_r2_internal;
    assign debug_reg_r9 = debug_r9_internal;
    assign debug_reg_r10 = debug_r10_internal;
    assign debug_mem_addr_16 = debug_mem_internal;    
    
    // =================================================================
    // PIPELINE STAGE INSTANTIATIONS
    // =================================================================
     
    // IF Stage
    instruction_fetch IF_stage(
        .clk(clk),
        .rst(rst),
        .stall_pc(stall_pc),
        .branch_taken(control_transfer),
        .jump_taken(1'b0),
        .jalr_taken(1'b0),
        .branch_target(ex_mem_branch_target),
        .pc_out(if_pc),
        .instruction_out(if_instruction),
        .pc_plus_4_out(if_pc_plus_4)
    );
    
    // IF/ID Pipeline Register
    if_id_register IF_ID_reg(
        .clk(clk),
        .rst(rst),
        .stall(stall_if_id),
        .flush(if_id_flush),
        .pc_in(if_pc),
        .instruction_in(if_instruction),
        .pc_plus_4_in(if_pc_plus_4),
        .pc_out(if_id_pc),
        .instruction_out(if_id_instruction),
        .pc_plus_4_out(if_id_pc_plus_4)
    );
    
    // ID Stage
    instruction_decode ID_stage(
        .clk(clk),
        .rst(rst),
        .pc_in(if_id_pc),
        .instruction_in(if_id_instruction),
        .pc_plus_4_in(if_id_pc_plus_4),
        .write_data(wb_write_data),
        .reg_write(mem_wb_reg_write),
        .write_reg_num(mem_wb_rd),
        
        // Hazard detection inputs
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_lb),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_mem_read(ex_mem_mem_to_reg),
        
      
        .ex_mem_branch_taken_actual(ex_mem_branch_taken),   
        .ex_mem_branch_target_actual(ex_mem_branch_target),  
        
        // Outputs
        .read_data1(id_read_data1),
        .read_data2(id_read_data2),
        .alu_control(id_alu_control),
        .alu_src(id_alu_src),
        .reg_write_out(id_reg_write),
        .mem_to_reg(id_mem_to_reg),
        .bneq_control(id_bneq_control),
        .beq_control(id_beq_control),
        .bgeq_control(id_bgeq_control),
        .blt_control(id_blt_control),
        .jump(id_jump),
        .store_enable(id_store_enable),
        .lui_control(id_lui_control),
        .is_unsigned(id_is_unsigned),
        .jalr(id_jalr),
        .mem_size(id_mem_size),
        .selected_immediate(id_selected_immediate),
        
        // Branch prediction outputs (not fully connected)
        .branch_prediction(),
        .predicted_target(),
        .is_branch_instruction(),
        .is_jump_instruction(),
        
        // Hazard detection outputs
        .stall_pc(stall_pc),
        .stall_if_id(stall_if_id),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush),

        .debug_r1(debug_r1_internal),
        .debug_r2(debug_r2_internal),
        .debug_r9(debug_r9_internal),
        .debug_r10(debug_r10_internal)
    );
    
    // ID/EX Pipeline Register
    id_ex_register ID_EX_reg(
        .clk(clk),
        .rst(rst),
        .flush(id_ex_flush),
        
        // Control signals
        .reg_write_in(id_reg_write),
        .mem_to_reg_in(id_mem_to_reg),
        .alu_control_in(id_alu_control),
        .alu_src_in(id_alu_src),
        .store_enable_in(id_store_enable),
        .beq_control_in(id_beq_control),
        .bneq_control_in(id_bneq_control),
        .bgeq_control_in(id_bgeq_control),
        .blt_control_in(id_blt_control),
        .jump_in(id_jump),
        .jalr_in(id_jalr),
        .lui_control_in(id_lui_control),
        .lb_in(id_mem_to_reg),
        .is_unsigned_in(id_is_unsigned),
        .mem_size_in(id_mem_size),
        
        // Data signals
        .pc_in(if_id_pc),
        .pc_plus_4_in(if_id_pc_plus_4),
        .read_data1_in(id_read_data1),
        .read_data2_in(id_read_data2),
        .immediate_in(id_selected_immediate),
        .rs1_in(if_id_instruction[19:15]),
        .rs2_in(if_id_instruction[24:20]),
        .rd_in(if_id_instruction[11:7]),
        .shamt_in(if_id_instruction[24:20]),
        
        // Control outputs
        .reg_write_out(id_ex_reg_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .alu_control_out(id_ex_alu_control),
        .alu_src_out(id_ex_alu_src),
        .store_enable_out(id_ex_store_enable),
        .beq_control_out(id_ex_beq_control),
        .bneq_control_out(id_ex_bneq_control),
        .bgeq_control_out(id_ex_bgeq_control),
        .blt_control_out(id_ex_blt_control),
        .jump_out(id_ex_jump),
        .jalr_out(id_ex_jalr),
        .lui_control_out(id_ex_lui_control),
        .lb_out(id_ex_lb),
        .is_unsigned_out(id_ex_is_unsigned),
        .mem_size_out(id_ex_mem_size),
        
        // Data outputs
        .pc_out(id_ex_pc),
        .pc_plus_4_out(id_ex_pc_plus_4),
        .read_data1_out(id_ex_read_data1),
        .read_data2_out(id_ex_read_data2),
        .immediate_out(id_ex_immediate),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),
        .shamt_out(id_ex_shamt)
    );
    
    // EX Stage
    ex_stage EX_stage(
        .clk(clk),
        .rst(rst),
        
        // Data inputs from ID/EX pipeline register
        .read_data1_in(id_ex_read_data1),
        .read_data2_in(id_ex_read_data2),
        .immediate_in(id_ex_immediate),
        .pc_in(id_ex_pc),
        .pc_plus_4_in(id_ex_pc_plus_4),
        .rs1_in(id_ex_rs1),
        .rs2_in(id_ex_rs2),
        .rd_in(id_ex_rd),
        .shamt_in(id_ex_shamt),
        
        // Control signals from ID/EX pipeline register
        .alu_control_in(id_ex_alu_control),
        .alu_src_in(id_ex_alu_src),
        .beq_control_in(id_ex_beq_control),
        .bneq_control_in(id_ex_bneq_control),
        .bgeq_control_in(id_ex_bgeq_control),
        .blt_control_in(id_ex_blt_control),
        .jump_in(id_ex_jump),
        .jalr_in(id_ex_jalr),
        
        // Forwarding inputs
        .ex_mem_alu_result(ex_mem_alu_result),
        .mem_wb_result(wb_write_data),
        .ex_mem_rd(ex_mem_rd),
        .mem_wb_rd(mem_wb_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),
        
        // Outputs
        .alu_result_out(ex_alu_result),
        .write_data_out(ex_write_data),
        .pc_plus_4_out(ex_pc_plus_4),
        .rd_out(ex_rd),
        
       
        .branch_resolved(ex_branch_resolved),    
        .branch_taken_out(ex_branch_taken),
        .branch_target_out(ex_branch_target)
    );
    
    // EX/MEM Pipeline Register
    ex_mem_register EX_MEM_reg(
        .clk(clk),
        .rst(rst),
        
        // Control signals
        .reg_write_in(id_ex_reg_write),
        .mem_to_reg_in(id_ex_mem_to_reg),
        .store_enable_in(id_ex_store_enable),
        .lb_in(id_ex_lb),
        .lui_control_in(id_ex_lui_control),
        .jump_in(id_ex_jump),
        .jalr_in(id_ex_jalr),
        .is_unsigned_in(id_ex_is_unsigned),
        .mem_size_in(id_ex_mem_size),
        
        // Data signals
        .alu_result_in(ex_alu_result),
        .write_data_in(ex_write_data),
        .pc_plus_4_in(ex_pc_plus_4),
        .lui_imm_in(id_ex_immediate),
        .rd_in(ex_rd),
        
      
        .branch_resolved_in(ex_branch_resolved),   
        .branch_taken_in(ex_branch_taken),
        .branch_target_in(ex_branch_target),
        
        // Control outputs
        .reg_write_out(ex_mem_reg_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),
        .store_enable_out(ex_mem_store_enable),
        .lb_out(ex_mem_lb),
        .lui_control_out(ex_mem_lui_control),
        .jump_out(ex_mem_jump),
        .jalr_out(ex_mem_jalr),
        .is_unsigned_out(ex_mem_is_unsigned),
        .mem_size_out(ex_mem_mem_size),
        
        // Data outputs
        .alu_result_out(ex_mem_alu_result),
        .write_data_out(ex_mem_write_data),
        .pc_plus_4_out(ex_mem_pc_plus_4),
        .lui_imm_out(ex_mem_lui_imm),
        .rd_out(ex_mem_rd),
        
       
        .branch_resolved_out(ex_mem_branch_resolved), 
        .branch_taken_out(ex_mem_branch_taken),
        .branch_target_out(ex_mem_branch_target)
    );
    
    // MEM Stage
    mem_stage MEM_stage(
        .clk(clk),
        .rst(rst),
        
        // Control signals from EX/MEM register
        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),
        .store_enable_in(ex_mem_store_enable),
        .lui_control_in(ex_mem_lui_control),
        .jump_in(ex_mem_jump),
        .jalr_in(ex_mem_jalr),
        .is_unsigned_in(ex_mem_is_unsigned),
        .mem_size_in(ex_mem_mem_size),
        
        // Data signals from EX/MEM register
        .alu_result_in(ex_mem_alu_result),
        .write_data_in(ex_mem_write_data),
        .pc_plus_4_in(ex_mem_pc_plus_4),
        .lui_imm_in(ex_mem_lui_imm),
        .rd_in(ex_mem_rd),
        .branch_taken_in(ex_mem_branch_taken),
        .branch_target_in(ex_mem_branch_target),
        
        // Control outputs to MEM/WB register
        .reg_write_out(mem_reg_write),
        .mem_to_reg_out(mem_mem_to_reg),
        .lui_control_out(mem_lui_control),
        .jump_out(mem_jump),
        .jalr_out(mem_jalr),
        
        // Data outputs to MEM/WB register
        .alu_result_out(mem_alu_result),
        .mem_data_out(mem_data),
        .pc_plus_4_out(mem_pc_plus_4),
        .lui_imm_out(mem_lui_imm),
        .rd_out(mem_rd),
        
        // Branch outputs (back to IF stage)
        .branch_taken_out(mem_branch_taken),
        .branch_target_out(mem_branch_target),
        .debug_mem_addr_16(debug_mem_internal)
    );
    
    // MEM/WB Pipeline Register
    mem_wb_register MEM_WB_reg(
        .clk(clk),
        .rst(rst),
        
        // Control signals
        .reg_write_in(mem_reg_write),
        .mem_to_reg_in(mem_mem_to_reg),
        .lui_control_in(mem_lui_control),
        .jump_in(mem_jump),
        .jalr_in(mem_jalr),
        
        // Data signals
        .alu_result_in(mem_alu_result),
        .mem_data_in(mem_data),
        .pc_plus_4_in(mem_pc_plus_4),
        .lui_imm_in(mem_lui_imm),
        .rd_in(mem_rd),
        
        // Control outputs
        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg),
        .lui_control_out(mem_wb_lui_control),
        .jump_out(mem_wb_jump),
        .jalr_out(mem_wb_jalr),
        
        // Data outputs
        .alu_result_out(mem_wb_alu_result),
        .mem_data_out(mem_wb_mem_data),
        .pc_plus_4_out(mem_wb_pc_plus_4),
        .lui_imm_out(mem_wb_lui_imm),
        .rd_out(mem_wb_rd)
    );
    
    // WB Stage
    write_back WB_stage(
   
    .reg_write_in(mem_wb_reg_write),
    .mem_to_reg_in(mem_wb_mem_to_reg),
    .lui_control_in(mem_wb_lui_control),
    .jump_in(mem_wb_jump),
    .jalr_in(mem_wb_jalr),
    .alu_result_in(mem_wb_alu_result),
    .mem_data_in(mem_wb_mem_data),      
    .pc_plus_4_in(mem_wb_pc_plus_4),
    .lui_imm_in(mem_wb_lui_imm),
    .write_data(wb_write_data)         
    );

endmodule