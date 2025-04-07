module hazard_forward(

    input         ALUSrcMux,
    input         reg_wr_enX,      // EX stage: register write enable.
    input         reg_wr_enM,      // MEM stage: register write enable.
    input         reg_wr_enW,      // WB stage: register write enable.

    input  [3:0]  write_regX,      // EX stage: destination register.
    input  [3:0]  write_regM,      // MEM stage: destination register.
    input  [3:0]  write_regW,      // WB stage: destination register.

    input  [3:0]  rr1_reg_D,       // D stage: first source register.
    input  [3:0]  rr2_reg_D,       // D stage: second source register.

    input  [3:0]  rr1_reg_X,       // EX stage: first source register.
    input  [3:0]  rr2_reg_X,       // EX stage: second source register.

    input  [3:0]  rr1_reg_M,       // MEM stage: second source register (for store instructions)
    input         mem_writeM,       // MEM stage: indicates a store instruction
    
    // Inputs for load hazard detection.
    input         mem_to_regX,     // EX stage: indicates a load instruction.
    input         mem_to_regM,     // MEM stage: indicates a load instruction.

    output        stallFD,         // Stall fetch stage.

    output [1:0]  forwardD,        // Forwarding for branch calculation.
    output [1:0]  forward_A_selX,  // Forwarding selector for ALU input A.
    output [1:0]  forward_B_selX,   // Forwarding selector for ALU input B.
    output forward_M_selM
);

    //----------------------------------------------------------------------
    // Branch Forwarding:
    // Choose the most recent value for rr1_reg_D from the EX, MEM, or WB stage.
    //----------------------------------------------------------------------
    assign forwardD =
          (reg_wr_enX & (rr1_reg_D == write_regX)) ? 2'b01 :
          (reg_wr_enM & (rr1_reg_D == write_regM)) ? 2'b10 :
          (reg_wr_enW & (rr1_reg_D == write_regW)) ? 2'b11 : 2'b00;

    //----------------------------------------------------------------------
    // ALU Operand Forwarding for Execute Stage:
    // Forward from MEM or WB stage to avoid data hazards.
    //----------------------------------------------------------------------
    // Detect forwarding need from MEM stage.
    wire fwdA_ex_mem, fwdB_ex_mem;
    assign fwdA_ex_mem = reg_wr_enM & (write_regM != 4'b0000) & (write_regM == rr1_reg_X);
    assign fwdB_ex_mem = reg_wr_enM & (write_regM != 4'b0000) & (write_regM == rr2_reg_X); // last arg gives priority to the imm value

    // Detect forwarding need from WB stage.
    wire fwdA_mem_wb, fwdB_mem_wb;
    assign fwdA_mem_wb = reg_wr_enW & (write_regW != 4'b0000) & (write_regW == rr1_reg_X);
    assign fwdB_mem_wb = reg_wr_enW & (write_regW != 4'b0000) & (write_regW == rr2_reg_X); // last arg gives priority to the imm value

    // Choose the forwarding source:
    // 01 => forward from MEM stage,
    // 10 => forward from WB stage,
    // 00 => no forwarding needed.
    assign forward_A_selX = fwdA_ex_mem ? 2'b01 : (fwdA_mem_wb ? 2'b10 : 2'b00);
    assign forward_B_selX = fwdB_ex_mem ? 2'b01 : (fwdB_mem_wb ? 2'b10 : 2'b00);

    // Mem - Mem forwarding
    wire fwd_mem_to_mem;
    assign fwd_mem_to_mem = mem_writeM & reg_wr_enW & (write_regW != 4'b0000) & (write_regW == rr1_reg_M);

    // Forward selector for MEM stage store data
    assign forward_M_selM = fwd_mem_to_mem;


    //----------------------------------------------------------------------
    // Load-Hazard Stall Detection:
    // Detect a load-use hazard when a load in EX or MEM stage feeds a value needed
    // by the decode stage.
    //----------------------------------------------------------------------
    wire stall_frm_X = mem_to_regX & ((write_regX == rr1_reg_D) | (write_regX == rr2_reg_D));
    wire stall_frm_M = mem_to_regM & (write_regM == rr1_reg_D);

    // With single-cycle memory, the stalls depend solely on data hazards.
    assign stallFD = stall_frm_X | stall_frm_M;

endmodule