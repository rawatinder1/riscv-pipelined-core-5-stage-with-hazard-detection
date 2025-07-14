// Pipeline Register: ID/EX
module id_ex_register(
    input clk,
    input rst,
    input flush,
    
    // Control signals
    input reg_write_in,
    input mem_to_reg_in,
    input [5:0] alu_control_in,
    input store_enable_in,
    input beq_control_in,
    input bneq_control_in,
    input bgeq_control_in,
    input blt_control_in,
    input jump_in,
    input jalr_in,
    input lui_control_in,
    input lb_in,
    input is_unsigned_in,
    input [1:0] mem_size_in,
    input alu_src_in,
    
    // Data signals
    input [31:0] pc_in,
    input [31:0] pc_plus_4_in,
    input [31:0] read_data1_in,
    input [31:0] read_data2_in,
    input [31:0] immediate_in,
    input [4:0] rs1_in,
    input [4:0] rs2_in,
    input [4:0] rd_in,
    input [4:0] shamt_in,
    
    // Control outputs
    output reg reg_write_out,
    output reg mem_to_reg_out,
    output reg [5:0] alu_control_out,
    output reg store_enable_out,
    output reg beq_control_out,
    output reg bneq_control_out,
    output reg bgeq_control_out,
    output reg blt_control_out,
    output reg jump_out,
    output reg jalr_out,
    output reg lui_control_out,
    output reg lb_out,
    output reg is_unsigned_out,
    output reg [1:0] mem_size_out,
    output reg alu_src_out,
    
    // Data outputs
    output reg [31:0] pc_out,
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] immediate_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [4:0] shamt_out
);
    always @(posedge clk) begin
        if (rst || flush) begin
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            alu_control_out <= 6'b0;
            store_enable_out <= 1'b0;
            beq_control_out <= 1'b0;
            bneq_control_out <= 1'b0;
            bgeq_control_out <= 1'b0;
            blt_control_out <= 1'b0;
            jump_out <= 1'b0;
            jalr_out <= 1'b0;
            lui_control_out <= 1'b0;
            lb_out <= 1'b0;
            is_unsigned_out <= 1'b0;
            mem_size_out <= 2'b0;
            pc_out <= 32'h0;
            pc_plus_4_out <= 32'h0;
            read_data1_out <= 32'h0;
            read_data2_out <= 32'h0;
            immediate_out <= 32'h0;
            rs1_out <= 5'b0;
            rs2_out <= 5'b0;
            rd_out <= 5'b0;
            shamt_out <= 5'b0;
            alu_src_out <= 1'b0;
        end
        else begin
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_control_out <= alu_control_in;
            store_enable_out <= store_enable_in;
            beq_control_out <= beq_control_in;
            bneq_control_out <= bneq_control_in;
            bgeq_control_out <= bgeq_control_in;
            blt_control_out <= blt_control_in;
            jump_out <= jump_in;
            jalr_out <= jalr_in;
            lui_control_out <= lui_control_in;
            lb_out <= lb_in;
            is_unsigned_out <= is_unsigned_in;
            mem_size_out <= mem_size_in;
            pc_out <= pc_in;
            pc_plus_4_out <= pc_plus_4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            immediate_out <= immediate_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
            shamt_out <= shamt_in;
           alu_src_out <= alu_src_in;
        end
    end
endmodule
