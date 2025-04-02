module fetch(
    input clk,                    // Clock signal
    input rst_n,                  // Reset signal (active low)
    input stall,                  // Stall signal from hazard detection
    input flush,                  // Flush signal when branch is taken
    input halt_PC,
    input [15:0] branch_target,   // Branch target from ID stage
    
    // Outputs - just the basic values
    output [15:0] pc,             // Current PC value (for CPU output)
    output [32:0] F_out;   // data to be passed to the FD pipe reg
);

    // Internal wires
    wire [15:0] pc_next;          // Next PC value

    // PC selection logic for predict-not-taken
    // Note: Stall comes from hazard in X , flush comes from branch resolution in D, halt coms from writeback
    assign pc_next = (halt_PC && !flush) ? pc :     // Halt: freeze PC unless in branch shadow
                 stall ? pc :                   // Stall: keep current PC 
                 flush ? branch_target :        // Branch taken: jump to target
                 pc_plus_2;                      // Normal: increment PC

    // PC register
    pc_reg PC(
        .clk(clk),
        .rst_n(rst_n),
        .pc_next(pc_next),
        .pc(pc)
    );

    // PC + 2 adder (for normal sequential execution)
    adder_16bit pc_incrementer(
        .A(pc),
        .B(16'h0002),
        .Sub(1'b0),
        .Sum(pc_plus_2)
    );

    // Instruction memory
    memory1c IMEM(
        .data_out(instruction),   // Output: instruction fetched
        .data_in(16'h0000),       // Not used (we don't write to instruction memory)
        .addr(pc),                // Address: current PC
        .enable(1'b1),            // Always enabled
        .wr(1'b0),                // Never write
        .clk(clk),
        .rst(~rst_n)              // Convert active-low to active-high
    );

    // assign data that will go into pipeline to decode
    // FD_in : {[31:16]pc_plus_2, [15:0]instruction}
    assign F_out = {pc_plus_2, instruction};

endmodule