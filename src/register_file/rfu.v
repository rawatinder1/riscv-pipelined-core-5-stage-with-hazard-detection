
module register_file(
    input clk,
    input rst,
    input [4:0] read_reg_num1,      // rs1
    input [4:0] read_reg_num2,      // rs2
    input [4:0] write_reg_num1,     // rd
    input [31:0] write_data,        // Write-back data
    input reg_write,                // Write enable
    
    output [31:0] read_data1,       // rs1 data
    output [31:0] read_data2,        // rs2 data

    output [31:0] debug_r1,
    output [31:0] debug_r2,
    output [31:0] debug_r9,
    output [31:0] debug_r10

);
    
    // Register file - 32 registers
    reg [31:0] reg_mem [31:0];      
    integer i;
    
    // Register initialization and write logic
    always @(posedge clk) begin
        if (rst) begin
            // Initialize all registers to 0
            for (i = 0; i < 32; i = i + 1)
                reg_mem[i] <= 32'h00000000;
        end
        else begin
            // Register write logic 
            if (reg_write && write_reg_num1 != 5'b00000) begin  
                reg_mem[write_reg_num1] <= write_data;
            end
            
            // Register 0 is always 0 (RISC-V requirement)
            reg_mem[0] <= 32'h00000000;
        end
    end

    always @(posedge clk) begin
    if (reg_write && write_reg_num1 == 10) begin
        $display("REG DEBUG: Writing to r10: data=%h", write_data);
    end
end
    
    // Continuous assignment for read operations
    assign read_data1 = (read_reg_num1 == 5'b00000) ? 32'h00000000 : reg_mem[read_reg_num1];
    assign read_data2 = (read_reg_num2 == 5'b00000) ? 32'h00000000 : reg_mem[read_reg_num2];

    assign debug_r1=reg_mem[1];
    assign debug_r2=reg_mem[2];
    assign debug_r9=reg_mem[9];
    assign debug_r10=reg_mem[10];
    
endmodule