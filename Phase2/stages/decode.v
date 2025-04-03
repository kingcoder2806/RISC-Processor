module decode (
    input clk,
    input rst_n,
    
    // Inputs from Fetch/Decode pipeline register
    input [31:0] D_in,
    input [15:0] write_data_W,
    input [3:0] wr_reg_W,
    input RegWrite_W,
    
    // branch resolution signals to go back to F stage
    output flush,
    output [15:0] branch_target,

    // pipeline data and control signals
    output [70:0] D_out
);
    
    // internal signals from Fetch
    wire [15:0] pc_plus_2_F;
    wire [15:0] instruction_F;

    // declare all wire connections for decode stage
    wire [3:0] rr1_reg_D;               // Read register 1 selector
    wire [3:0] rr2_reg_D;               // Read register 2 selector
    wire [3:0] wr_reg_D;                // Write register selector
    wire [15:0] rr1_data_D;             // Data from rs register
    wire [15:0] rr2_data_D;             // Data from rt register
    wire [15:0] imm_value_D;            // Immediate value for ALU

    // control signals from control module
    wire RR1Mux_D;                      // Read register 1 mux control
    wire RR2Mux_D;                      // Read register 2 mux control
    wire [1:0] ImmMux_D;                // Immediate value mux control
    wire ALUSrcMux_D;                   // ALU source mux control
    wire MemtoRegMux_D;                 // Memory to register mux control
    wire PCSMux_D;                      // PC save mux control
    wire HaltMux_D;                     // Halt mux control
    wire BranchRegMux_D;                // Branch register mux control
    wire BranchMux_D;                   // Branch immediate mux control
    wire RegWrite_D;                    // Register write control
    wire MemWrite_D;                    // Memory write control
    wire MemRead_D;                     // Enable using data memory
    wire Flag_Enable_D;                 // enables FF for flags
    wire [3:0] ALUop_D;                 // bits [15:12] of inst for alu operation

    // break up the FD pipeline data
    assign pc_plus_2_F = D_in[31:16];    // PC + 2 forwarded to D stage
    assign instruction_F = D_in[15:0];   // Instruction forwarded to D stage
 
    // Control unit instantiation
    control ctrl_unit(
        .instruction(instruction_F),
        .RR1Mux(RR1Mux_D),
        .RR2Mux(RR2Mux_D),
        .ImmMux(ImmMux_D),
        .ALUSrcMux(ALUSrcMux_D),
        .MemtoRegMux(MemtoRegMux_D),
        .PCSMux(PCSMux_D),
        .HaltMux(HaltMux_D), // used and proporagted to WB stage
        .BranchRegMux(BranchRegMux_D),
        .BranchMux(BranchMux_D),
        .RegWrite(RegWrite_D),
        .MemWrite(MemWrite_D),
        .MemRead(MemRead_D),
        .Flag_Enable(Flag_Enable_D),
        .ALUop(ALUop_D)
    );

    // Register selection logic
    assign rr1_reg_D = RR1Mux_D ? instruction_F[11:8] : instruction_F[7:4];    // 1 : LLB / LHB , 0 : else
    assign rr2_reg_D = (MemWrite_D | MemRead_D) ? instruction_F[11:8] : instruction_F[3:0]; // LW and SW
    assign wr_reg_D = instruction_F[11:8];     
    
    // RegisterFile instantiation
    RegisterFile RF(
        .clk(clk),
        .rst(~rst_n),                  // Convert active-low to active-high
        .SrcReg1(rr1_reg_D),
        .SrcReg2(rr2_reg_D),
        .DstReg(wr_reg_W),          // from WB
        .WriteReg(RegWrite_W),      // from WB
        .DstData(write_data_W),     // from WB
        .SrcData1(rr1_data_D), 
        .SrcData2(rr2_data_D)
    );

    
    // Immediate value selection - based on your control logic
    assign imm_value_D = (ImmMux_D == 2'b00) ? {{12{1'b0}}, instruction_F[3:0]} :             // 4-bit immediate (SLL, SRA, ROR)
                       (ImmMux_D == 2'b01) ? {{11{instruction_F[3]}}, instruction_F[3:0], 1'b0} : // 4-bit offset shifted (LW, SW)
                       {{8{1'b0}}, instruction_F[7:0]};                                     // 8-bit immediate (LLB, LHB) - 2'b10
    
    
    // Calculating if branch is taken by calculating flags, resolving the Branch in this stage
    wire branch_taken;
    branch_unit branch_inst(
        .clk(clk),
        .rst_n(rst_n),
        .Flag_Enable_D(Flag_Enable_D),
        .branch_condition(instruction_F[11:9]),
        .a(rr1_data_D),        // First operand from register file
        .b(rr2_data_D),        // Second operand from register file
        .op(ALUop_D),
        .branch_taken(branch_taken)
    );


    // Calculate branch target with extended imm
    wire [15:0] extended_imm;
    wire [15:0] branch_imm;
    assign extended_imm = {{6{instruction_F[8]}}, instruction_F[8:0], 1'b0}; // Sign-extend and shift left
    adder_16bit branch_adder(
        .A(pc_plus_2_F),
        .B(extended_imm),
        .Sub(1'b0),
        .Sum(branch_imm)
    );

    // Data signals and control signals concatenation
    assign D_out = {
        // Data signals (60 bits)
        PCSMux_D ? pc_plus_2_F : rr1_data_D,     // [70:55] Data from rr1 register or pc_plus_2_F if PSC instrction (16 bits)
        rr2_data_D,     // [54:39] Data from rr2 register (16 bits)
        imm_value_D,    // [38:23] Immediate value from instruction (16 bits)
        rr1_reg_D,      // [22:19] Read register 1 number (4 bits)
        rr2_reg_D,      // [18:15] Read register 2 number (4 bits)
        wr_reg_D,       // [14:11] Write register number (4 bits)
        
        // Control signals (11 bits)
        ALUop_D,        // [10:7] Opcode from instruction (4 bits)
        ALUSrcMux_D,    // [6] ALU source selection for EX stage (1 bit)
        MemtoRegMux_D,  // [5] Selects memory vs. ALU result in WB (1 bit)
        RegWrite_D,     // [4] Register write enable for WB (1 bit)
        MemWrite_D,     // [3] Memory write enable for MEM stage (1 bit)
        MemRead_D,      // [2] Memory read enable for MEM stage (1 bit)
        Flag_Enable_D,  // [1] Flag update enable for EX stage (1 bit)
        HaltMux_D       // [0] Halt signal (1 bit)
    };

    // assign halt signal to stop PC increment but not stop processor (stoped by writeback HLT)
    assign halt_PC = HaltMux_D;

    // assign flush based off of branch taken
    assign flush = (branch_taken && (BranchMux_D || BranchRegMux_D));

    // assign branch target based off of B or BR inst
    // if branch_taken is true and either BranchMux_D or BranchRegMux_D is high:
    // when BranchMux_D is high, use the computed branch target (branch_target_temp).
    // when BranchRegMux_D is high, use the register value (e.g. rr1_data_D).
    // otherwise, branch_target is 0.
    assign branch_target = (flush) ? 
                         (BranchMux_D ? branch_imm : rr1_data_D) :
                         16'h0000;

endmodule