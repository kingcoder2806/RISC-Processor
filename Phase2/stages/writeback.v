module writeback(
    
    // Inputs from Memory/Writeback pipeline register
    input [38:0] W_in,
    
    // Outputs for CPU and Register File
    output HaltMux_W,   // out to cpu to halt 
    output RegWrite_W, // to register file in decode
    output [15:0] write_data_W,
    output [3:0] wr_reg_W
);
    // Extract individual signals from W_in
    wire [15:0] alu_result;
    wire [15:0] mem_data_out;
    wire MemtoRegMux_W;

    // Extract all signals from the pipeline register
    assign {
        alu_result,       // ALU result [16:0]
        mem_data_out,     // Memory data [16:0]
        wr_reg_W,         // Destination register [3:0], straight to output
        HaltMux_W,        // Halt signal, straight to output
        RegWrite_W,       // Register write enable, straight to output
        MemtoRegMux_W     // Memory to register select
    } = W_in;

    
    // Determine the data to write to register file
    assign write_data_W = MemtoRegMux_W ? mem_data_out : alu_result;

    
endmodule