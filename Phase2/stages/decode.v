// ADD HAZARD DETECTION HERE!!!!

module decode (
    input clk,
    input rst_n,
    
    // Inputs from Fetch/Decode pipeline register
    input [15:0] FD_pc_plus_2,
    input [15:0] FD_instruction,
    
    // branch resolution signals to go back to F stage
    output flush,
    output halt,
    output [15:0] branch_target

    // outputs to go into Decode / Execute pipeline
    // pipeline data
    output [15:0] D_rr1_data;             // Data from rs register
    output [15:0] D_rr2_data;             // Data from rt register
    output [15:0] D_write_data;           // Data to write to rd register
    output [15:0] D_imm_value;            // imm value from inst
    output [3:0] D_rr1_reg;               // Read register 1 selector
    output [3:0] D_rr2_reg;               // Read register 2 selector
    output [3:0] D_wr_reg;                // Write register selector
    output [3:0] D_ALUop;                 // opcode from inst

    // pipeline control
    output D_ALUSrcMux,       // ALU source selection for EX stage
    output D_MemtoRegMux,     // selects memory vs. ALU result in WB
    output D_PCSMux,          // selects PC+2 for PCS instructions in WB
    output D_RegWrite,        // register write enable for WB
    output D_MemWrite,        // memory write enable for MEM stage
    output D_MemRead,         // memory read enable for MEM stage
    output D_Flag_Enable,     // flag update enable for EX stage

);
    
    // declare all wire connections for decode stage
    wire [3:0] rr1_reg;               // Read register 1 selector
    wire [3:0] rr2_reg;               // Read register 2 selector
    wire [3:0] wr_reg;                // Write register selector
    wire [15:0] rr1_data;             // Data from rs register
    wire [15:0] rr2_data;             // Data from rt register
    wire [15:0] imm_value;            // Immediate value for ALU
    wire [15:0] write_data;           // Data to write to rd register

    // control signals from control module
    wire RR1Mux;                      // Read register 1 mux control
    wire RR2Mux;                      // Read register 2 mux control
    wire [1:0] ImmMux;                // Immediate value mux control
    wire ALUSrcMux;                   // ALU source mux control
    wire MemtoRegMux;                 // Memory to register mux control
    wire PCSMux;                      // PC save mux control
    wire HaltMux;                     // Halt mux control
    wire BranchRegMux;                // Branch register mux control
    wire BranchMux;                   // Branch immediate mux control
    wire RegWrite;                    // Register write control
    wire MemWrite;                    // Memory write control
    wire MemRead;                     // Enable using data memory
    wire Flag_Enable;
    wire ALUop;

    // Control unit instantiation
    control ctrl_unit(
        .instruction(FD_instruction),
        .RR1Mux(RR1Mux),
        .RR2Mux(RR2Mux),
        .ImmMux(ImmMux),
        .ALUSrcMux(ALUSrcMux),
        .MemtoRegMux(MemtoRegMux),
        .PCSMux(PCSMux),
        .HaltMux(HaltMux),
        .BranchRegMux(BranchRegMux),
        .BranchMux(BranchMux),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Flag_Enable(Flag_Enable),
        .ALUop(ALUop)
    );

    // Register selection logic
    assign rr1_reg = RR1Mux ? FD_instruction[11:8] : FD_instruction[7:4];    // 1 : LLB / LHB , 0 : else
    assign rr2_reg = (MemWrite | MemRead) ? FD_instruction[11:8] : FD_instruction[3:0]; // LW and SW
    assign wr_reg = FD_instruction[11:8];  
    
    // RegisterFile instantiation
    RegisterFile RF(
        .clk(clk),
        .rst(~rst_n),                  // Convert active-low to active-high
        .SrcReg1(rr1_reg),
        .SrcReg2(rr2_reg),
        .DstReg(wr_reg),
        .WriteReg(RegWrite),
        .DstData(write_data),
        .SrcData1(rr1_data),
        .SrcData2(rr2_data)
    );
    
    // Immediate value selection - based on your control logic
    assign imm_value = (ImmMux == 2'b00) ? {{12{1'b0}}, FD_instruction[3:0]} :             // 4-bit immediate (SLL, SRA, ROR)
                       (ImmMux == 2'b01) ? {{11{FD_instruction[3]}}, FD_instruction[3:0], 1'b0} : // 4-bit offset shifted (LW, SW)
                       {{8{1'b0}}, FD_instruction[7:0]};                                     // 8-bit immediate (LLB, LHB) - 2'b10
    
    // Branch resolution - using the same logic from your single-cycle implementation
    branch branch_unit(
        .branch_condition(FD_instruction[11:9]),
        .flag_reg(flags),
        .branch_taken(branch_taken)
    );
    
    // Calculate branch target
    wire [15:0] branch_value
    wire [15:0] extended_imm;
    assign extended_imm = {{6{FD_instruction[8]}}, FD_instruction[8:0], 1'b0}; // Sign-extend and shift left
    adder_16bit branch_adder(
        .A(FD_pc_plus_2),
        .B(extended_imm),
        .Sub(1'b0),
        .Sum(branch_value)
    );

    // assign halt to go and stop write to pipe registers
    assign halt = HaltMux;

    // assign flush so PC can load in the new branch addr
    assign flush = (BranchRegMux & branch_taken) | (BranchMux & branch_taken);

    // assign branch tagret, if branchMux high take output of branch_addr else take rr1 data
    assign branch_target = BranchMux ? branch_value : rr1_data;

    // assiging internal signals to outputs of Decode:
    assign D_ALUop       = ALUop;
    assign D_ALUSrcMux   = ALUSrcMux;
    assign D_MemtoRegMux = MemtoRegMux;
    assign D_PCSMux      = PCSMux;
    assign D_RegWrite    = RegWrite;
    assign D_MemWrite    = MemWrite;
    assign D_MemRead     = MemRead;
    assign D_Flag_Enable = Flag_Enable;
    assign D_imm_value   = imm_value;
    assign D_rr1_reg     = rr1_reg;
    assign D_rr2_reg     = rr2_reg;
    assign D_wr_reg      = wr_reg;
    assign D_rr1_data    = rr1_data;
    assign D_rr2_data    = rr2_data;
    assign D_write_data  = write_data;


endmodule