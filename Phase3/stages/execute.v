module execute(
    input clk,
    input rst_n,
    
    // Input from ID/EX pipeline register
    input [70:0] X_in,

    // Input from forwarding and hazard unit
    input [1:0] fwdMuxSel_A,
    input [1:0] fwdMuxSel_B,
    input [15:0] fwd_dataMux_A,
    input [15:0] fwd_dataMux_B,
    
    // Output to EX/MEM pipeline register
    output [48:0] X_out      // Signals to be passed to MEM stage
);
    // Data signals (76 bits)
    wire [3:0] wr_reg_X;        // Write register number (4 bits)
    wire [3:0] rr2_reg_X;       // Read register 2 number (4 bits)
    wire [3:0] rr1_reg_X;       // Read register 1 number (4 bits)
    wire [15:0] imm_value_X;    // Immediate value from instruction (16 bits)
    wire [15:0] rr2_data_X;     // Data from rr2 register (16 bits)
    wire [15:0] rr1_data_X;     // Data from rr1 register (16 bits)

    // Control signals (12 bits)
    wire HaltMux_X;             // Halt signal (1 bit)
    wire Flag_Enable_X;         // Flag update enable for EX stage (1 bit)
    wire MemRead_X;             // Memory read enable for MEM stage (1 bit)
    wire MemWrite_X;            // Memory write enable for MEM stage (1 bit)
    wire RegWrite_X;            // Register write enable for WB (1 bit)
    wire MemtoRegMux_X;         // Selects memory vs. ALU result in WB (1 bit)
    wire ALUSrcMux_X;           // ALU source selection for EX stage (1 bit)
    wire [3:0] ALUop_X;         // Opcode from instruction (4 bits)

    // Extract signals from D_out
    assign {
        // Data signals (60 bits)
        rr1_data_X,      // Source data 1
        rr2_data_X,      // Source data 2
        imm_value_X,     // Immediate value
        rr1_reg_X,       // Source register 1
        rr2_reg_X,       // Source register 2
        wr_reg_X,        // Destination register

        // Control signals (11 bits)
        ALUop_X,         // Opcode
        ALUSrcMux_X,     // ALU source select
        MemtoRegMux_X,   // Memory to register select
        RegWrite_X,      // Register write enable
        MemWrite_X,      // Memory write enable
        MemRead_X,       // Memory read enable
        Flag_Enable_X,   // Flag update enable
        HaltMux_X        // Halt signal
    } = X_in;

    // ALU source B selection
    wire [15:0] alu_input_a;
    wire [15:0] alu_input_b;

    // to decide if using passed data from decode of data from forwarding
    wire internal_a, internal_b;

    assign internal_a = (fwdMuxSel_A == 2'b00) || (fwdMuxSel_A == 2'b11);
    assign internal_b = (fwdMuxSel_B == 2'b00) || (fwdMuxSel_B == 2'b11);

    assign alu_input_a = internal_a ? rr1_data_X : fwd_dataMux_A;
    assign alu_input_b = ALUSrcMux_X ? imm_value_X : (internal_b ? rr2_data_X : fwd_dataMux_B);

    
    // ALU signals
    wire [15:0] alu_result_X;
    wire [2:0] flags;
    
    // ALU instantiation
    alu ALU(
        .a(alu_input_a),
        .b(alu_input_b),
        .op(ALUop_X),            // Using opcode as ALU operation
        .result(alu_result_X),
        .flags(flags)            // Z, V, N flags (not used, calculated in the Decode stage)
    );
    
    // Prepare output for EX/MEM pipeline register
    assign X_out = {
    // Data signals
    rr1_reg_X,           //[48:45]
    rr2_reg_X,           //[44:41]
    alu_result_X,      // [40:25] ALU result (16 bits)
    rr2_data_X,      // [24:9] Data to write to memory (16 bits)
    wr_reg_X,        // [8:5] Destination register (4 bits)
    
    // Control signals
    MemWrite_X,      // [4] Memory write enable (1 bit)
    MemtoRegMux_X,   // [3] Memory to register (1 bit)
    RegWrite_X,      // [2] Register write enable (1 bit)
    HaltMux_X,       // [1] Halt signal (1 bit)
    MemRead_X        // [0] Memory read enable (1 bit)
};

endmodule