module cpu(
    input logic clk,
    input logic rst_n,
    output logic hlt,
    output logic [15:0] pc
);

    // declare all logic connections between modules
    logic [15:0] instruction;          // Instruction from memory
    logic [15:0] pc_plus2;             // PC + 2
    logic [15:0] branch_target;        // PC + SE(imm << 1)
    logic [15:0] pc_next;              // Next PC value
    logic [3:0] rr1_reg;               // Read register 1 selector
    logic [3:0] rr2_reg;               // Read register 2 selector
    logic [3:0] wr_reg;                // Write register selector
    logic [15:0] rr1_data;             // Data from rs register
    logic [15:0] rr2_data;             // Data from rt register
    logic [15:0] write_data;           // Data to write to rd register
    logic [15:0] alu_result;           // ALU result
    logic [15:0] imm_value;            // Immediate value for ALU
    logic [15:0] alu_input_b;          // Second input to ALU
    logic [15:0] mem_data_out;         // Data from memory
    logic take_branch;                 // Branch condition is satisfied

    // control signals from control_assign module
    logic RR1Mux;                      // Read register 1 mux control
    logic RR2Mux;                      // Read register 2 mux control
    logic [1:0] ImmMux;                // Immediate value mux control
    logic ALUSrcMux;                   // ALU source mux control
    logic MemtoRegMux;                 // Memory to register mux control
    logic PCSMux;                 // PC save mux control
    logic HaltMux;                     // Halt mux control
    logic BranchRegMux;                // Branch register mux control
    logic BranchMux;                   // Branch immediate mux control
    logic RegWrite;                    // Register write control
    logic MemWrite;                    // Memory write control
    logic MemRead;               // Enable using data memory
    

    ///////////////
    // PC Select //
    ///////////////

    // instantiate program counter register
    pc_reg PC(
        .clk(clk),
        .rst_n(rst_n),
        .pc_next(pc_next),
        .pc(pc)
    );

    // instantiate branch module to determine if branch is taken on B or BR operation
    branch branch_ctrl (
    .branch_condition(instruction[11:9]), 
    .flag_reg(flags), // from ALU
    .branch_taken(branch_taken)
    );

    // PC incrementer and branch target
    assign pc_plus2 = pc + 16'h0002;
    assign branch_target = pc_plus2 + {{6{instruction[8]}}, instruction[8:0], 1'b0};

    
    // PC selection logic
    assign pc_next = HaltMux ? pc :
                     BranchRegMux & ? rr1_data :
                     BranchMux ? branch_target :
                     pc_plus2;
    
    ////////////////////////
    // Instruction memory //
    ////////////////////////

    // INSTRUCTION MEMORY (instance of memory1c)
    memory1c IMEM(
        .data_out(instruction),   // Output: instruction fetched
        .data_in(16'h0000),       // Input: not used (we don't write to instruction memory)
        .addr(pc),                // Address: current PC
        .enable(1'b1),            // Always enabled
        .wr(1'b0),                // Never write
        .clk(clk),
        .rst(~rst_n)              // Convert active-low to active-high
    );

    // DATA MEMORY (instance of memory1c)
    memory1c DMEM(
        .data_out(mem_data_out),  // Output: data read from memory
        .data_in(rr2_data),       // Input: data to write to memory (from rt register)
        .addr(alu_result),        // Address: calculated by ALU
        .enable(MemRead),   // Enable for LW/SW
        .wr(MemWrite),            // Write enable signal from control
        .clk(clk),
        .rst(~rst_n)              // Convert active-low to active-high
    );

    
    //////////////////
    // Control unit //
    //////////////////

    control CTRL(
        .instruction(instruction),
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
        .DataMemEnable(DataMemEnable)
    );
    
    // Register selection logic
    assign rr1_reg = RR1Mux ? instruction[11:8] : instruction[7:4];    // 1 : LLB / LHB , 0 : else
    assign rr2_reg = RR2Mux ? instruction[11:8] : instruction[3:0];    // 1 : SW , 0 : else
    assign wr_reg = instruction[11:8];                                // always [11:8] 
    
    
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

    // Write data selection for register file using assign statement with conditional operators
    assign write_data = PCSMux ? pc_plus2 :                                  // PCS instruction - save PC+2
                       MemtoRegMux ? mem_data_out :                               // Load from memory
                       alu_result;                                                // ALU result


    /////////
    // ALU //
    /////////

    // Immediate value selection using assign statements and conditional operators
    assign imm_value = (ImmMux == 2'b00) ? {{12{1'b0}}, instruction[3:0]} :             // 4-bit immediate (SLL, SRA, ROR)
                       (ImmMux == 2'b01) ? {{11{instruction[3]}}, instruction[3:0], 1'b0} : // 4-bit offset shifted (LW, SW)
                       {{8{1'b0}}, instruction[7:0]};                                     // 8-bit immediate (LLB, LHB) - 2'b10

    assign alu_input_b = ALUSrcMux ? imm_value : rr2_data;

    logic [2:0] flags;                 // Z, V, N flags from ALU
    
    alu ALU(
        .a(rr1_data),
        .b(alu_input_b),
        .op(instruction[15:12]),  // Using opcode as ALU operation
        .result(alu_result),
        .flags(flags)             // Z, V, N flags
    );

    
endmodule