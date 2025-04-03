module memory(
    input clk,
    input rst_n,

    // Input from X/M pipeline register
    input [40:0] M_in,
    output [38:0] M_out

);

    // Data signals 
    wire [3:0] wr_reg_M;        // Write register number (4 bits)
    wire [15:0] alu_result;
    wire [15:0] rr2_data_M;     // Data from rr2 register (16 bits)

    // Control signals
    wire MemRead_M;             // Memory read enable for MEM stage (1 bit)
    wire MemWrite_M;            // Memory write enable for MEM stage (1 bit)
    wire RegWrite_M;            // Register write enable for WB (1 bit)
    wire MemtoRegMux_M;         // Selects memory vs. ALU result in WB (1 bit)
    wire HaltMux_M;             // Halt signal (1 bit)



assign {
    // Data signals
    alu_result,      // [40:25] ALU result (16 bits)
    rr2_data_M,      // [24:9] Data to write to memory (16 bits)
    wr_reg_M,        // [8:5] Destination register (4 bits)
    
    // Control signals
    MemWrite_M,      // [4] Memory write enable (1 bit)
    MemtoRegMux_M,   // [3] Memory to register (1 bit)
    RegWrite_M,      // [2] Register write enable (1 bit)
    HaltMux_M,       // [1] Halt signal (1 bit)
    MemRead_M        // [0] Memory read enable (1 bit)
} = M_in;

    // DATA MEMORY (instance of memory1c)
    wire [15:0] mem_data_out;
    memory1c DMEM(
        .data_out(mem_data_out),  // Output: data read from memory
        .data_in(rr2_data_M),       // Input: data to write to memory (from rt register)
        .addr(alu_result),        // Address: calculated by ALU
        .enable(MemWrite_M | MemRead_M),         // Enable for LW/SW
        .wr(MemWrite_M),            // Write enable signal from control
        .clk(clk),
        .rst(~rst_n)              // Convert active-low to active-high
    );


    assign M_out = {

        // data signals
        alu_result,       // ALU result [16:0]
        mem_data_out,     // Memory data [16:0]
        wr_reg_M,         // Destination register [3:0]

        // control signals
        HaltMux_M,        // Halt signal
        RegWrite_M,       // Register write enable
        MemtoRegMux_M     // Memory to register select
    };
    

endmodule