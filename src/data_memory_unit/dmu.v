module data_memory(
    input clk,
    input rst,
    input [31:0] read_addr,
    input [31:0] write_data,
    input write_enable,
    input is_unsigned,
    input [31:0] write_addr,
    input [1:0] mem_size,
    output [31:0] read_data,
    output [31:0] debug_mem_addr_16
);
    
    reg [7:0] memory [1023:0];
    integer i;
    
    // Write logic
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 1024; i = i + 1)
                memory[i] = 8'h00;
        end
        else if (write_enable) begin
            case (mem_size)
                2'b00: begin // Store Byte
                    memory[write_addr[9:0]] <= write_data[7:0];
                end
                2'b01: begin // Store Halfword
                    if (write_addr[0] == 1'b0) begin  // Check alignment
                        memory[write_addr[9:0]] <= write_data[7:0];
                        memory[write_addr[9:0] + 1] <= write_data[15:8];
                    end
                end
                2'b10: begin // Store Word
                    if (write_addr[1:0] == 2'b00) begin  // Check alignment
                        memory[write_addr[9:0]]     <= write_data[7:0];
                        memory[write_addr[9:0] + 1] <= write_data[15:8];
                        memory[write_addr[9:0] + 2] <= write_data[23:16];
                        memory[write_addr[9:0] + 3] <= write_data[31:24];
                    end
                end
            endcase
        end
    end
    
    //  prevent latch inference 
    assign read_data = 
        (mem_size == 2'b00) ? (is_unsigned ? {24'b0,memory[read_addr[9:0]]}:{{24{memory[read_addr[9:0]][7]}}, memory[read_addr[9:0]]}) :  // Load Byte
        (mem_size == 2'b01 && read_addr[0] == 1'b0) ? (is_unsigned? {16'b0,memory[read_addr[9:0]]} : {{16{memory[read_addr[9:0] + 1][7]}}, 
                                                      memory[read_addr[9:0] + 1], memory[read_addr[9:0]]}) :  // Load Halfword
        (mem_size == 2'b10 && read_addr[1:0] == 2'b00) ? {memory[read_addr[9:0] + 3], memory[read_addr[9:0] + 2],
                                                          memory[read_addr[9:0] + 1], memory[read_addr[9:0]]} :  // Load Word
        32'h00000000;  // Default/unaligned access

    assign debug_mem_addr_16 =  {memory[19], memory[18], memory[17], memory[16]};
    
endmodule