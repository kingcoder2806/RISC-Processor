module memory(
    input clk,
    input rst_n,

    // Input from X/M pipeline register
    input [48:0] M_in,

    // Inputs from forwarding
    input fwdMuxSel_M,
    input [15:0] fwdDataWB,
    output [38:0] M_out

);

    // Data signals 
    wire [3:0] wr_reg_M;        // Write register number (4 bits)
    wire [15:0] alu_result_M;
    wire [15:0] rr2_data_M, MemDataIn;     // Data from rr2 register (16 bits)
    wire [3:0] rr1_reg_M, rr2_reg_M; // rr1 and rr2 reg values 

    // Control signals
    wire MemRead_M;             // Memory read enable for MEM stage (1 bit)
    wire MemWrite_M;            // Memory write enable for MEM stage (1 bit)
    wire RegWrite_M;            // Register write enable for WB (1 bit)
    wire MemtoRegMux_M;         // Selects memory vs. ALU result in WB (1 bit)
    wire HaltMux_M;             // Halt signal (1 bit)



assign {
    // Data signals
    rr1_reg_M,           //[48:45]
    rr2_reg_M,           //[44:41]
    alu_result_M,      // [40:25] ALU result (16 bits)
    rr2_data_M,      // [24:9] Data to write to memory (16 bits)
    wr_reg_M,        // [8:5] Destination register (4 bits)
    
    // Control signals
    MemWrite_M,      // [4] Memory write enable (1 bit)
    MemtoRegMux_M,   // [3] Memory to register (1 bit)
    RegWrite_M,      // [2] Register write enable (1 bit)
    HaltMux_M,       // [1] Halt signal (1 bit)
    MemRead_M        // [0] Memory read enable (1 bit)
} = M_in;

    // Choose what mem_data_in is in case of mem - mem forwarding
    assign MemDataIn = fwdMuxSel_M ? fwdDataWB : rr2_data_M;

    // DATA MEMORY (instance of memory1c)
    wire [15:0] mem_data_out;
    memory1c DMEM(
        .data_out(mem_data_out),  // Output: data read from memory
        .data_in(MemDataIn),       // Input: data to write to memory (from rt register)
        .addr(alu_result_M),        // Address: calculated by ALU
        .enable(MemWrite_M | MemRead_M),         // Enable for LW/SW
        .wr(MemWrite_M),            // Write enable signal from control
        .clk(clk),
        .rst(~rst_n)              // Convert active-low to active-high
    );


    assign M_out = {

        // data signals
        
        alu_result_M,       // ALU result [39:23]
        mem_data_out,     // Memory data [22:7]
        wr_reg_M,         // Destination register [6:3]

        // control signals
        HaltMux_M,        // Halt signal 2
        RegWrite_M,       // Register write enable 1
        MemtoRegMux_M     // Memory to register select 0
    };
    

endmodule