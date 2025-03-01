module cpu(
    input clk,
    input rst_n,
    output hlt,
    output [15:0] pc
);

    // declare all wire connections between modules
    wire [15:0] instruction;          // Instruction from memory
    wire [15:0] pc_plus2;             // PC + 2
    wire [15:0] branch_target;        // PC + SE(imm << 1)
    wire [15:0] pc_next;              // Next PC value
    wire [15:0] pc2_raw;              // Raw increment pc value from adder
    wire [15:0] branch_raw;           // Raw branch pc value from adder
    wire [3:0] rr1_reg;               // Read register 1 selector
    wire [3:0] rr2_reg;               // Read register 2 selector
    wire [3:0] wr_reg;                // Write register selector
    wire [15:0] rr1_data;             // Data from rs register
    wire [15:0] rr2_data;             // Data from rt register
    wire [15:0] write_data;           // Data to write to rd register
    wire [15:0] alu_result;           // ALU result
    wire [15:0] imm_value;            // Immediate value for ALU
    wire [15:0] alu_input_b;          // Second input to ALU
    wire [15:0] mem_data_out;         // Data from memory
    wire take_branch;                 // Branch condition is satisfied
    wire [2:0] flags;                 // Z, V, N flags
    wire branch_taken;                // Branch condition is satisfied

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

    // PC incrementer and branch target using the adder module
    
    // PC + 2 adder
    adder pc_incrementer(
        .A(pc),
        .B(16'h0002),
        .Sub(1'b0),
        .Sum(pc2_raw),
        .Ovfl(pc_increment_ovfl)
    );

    assign pc_plus2 = pc_increment_ovfl ? 16'h0000 : pc2_raw;

    
    // branch target calculation adder (pc_plus2 + sign-extended immediate)
    wire [15:0] extended_imm = {{6{instruction[8]}}, instruction[8:0], 1'b0};
    adder branch_target_adder(
        .A(pc_plus2),
        .B(extended_imm),
        .Sub(1'b0),
        .Sum(branch_target),
        .Ovfl(branch_target_ovfl)
    );

    // for wrap-around, we need to calculate what the wrapped result would be
    wire [16:0] branch_full = {1'b0, pc_plus2} + {1'b0, extended_imm};
    assign branch_target = branch_target_ovfl ? branch_full[15:0] : branch_target_sat;

    // PC selection logic
    assign pc_next = HaltMux ? pc :
                     (BranchRegMux & branch_taken) ? rr1_data :
                     (BranchMux & branch_taken) ? branch_target :
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
        .enable(MemRead),         // Enable for LW/SW
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
        .MemRead(MemRead)
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
                       MemtoRegMux ? mem_data_out :                          // Load from memory
                       alu_result;                                           // ALU result


    /////////
    // ALU //
    /////////

    // Immediate value selection using assign statements and conditional operators
    assign imm_value = (ImmMux == 2'b00) ? {{12{1'b0}}, instruction[3:0]} :             // 4-bit immediate (SLL, SRA, ROR)
                       (ImmMux == 2'b01) ? {{11{instruction[3]}}, instruction[3:0], 1'b0} : // 4-bit offset shifted (LW, SW)
                       {{8{1'b0}}, instruction[7:0]};                                     // 8-bit immediate (LLB, LHB) - 2'b10

    assign alu_input_b = ALUSrcMux ? imm_value : rr2_data;
    
    alu ALU(
        .a(rr1_data),
        .b(alu_input_b),
        .op(instruction[15:12]),  // Using opcode as ALU operation
        .result(alu_result),
        .flags(flags)             // N,  Z, V [N,Z,V]
    );

    // Connect hlt output to HaltMux
    assign hlt = HaltMux;
    
endmodule