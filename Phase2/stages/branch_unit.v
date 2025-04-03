module branch_unit(
    input         clk,              // Clock for the flag register
    input         rst_n,            // Active-low reset
    input         Flag_Enable_D,    // Enable signal: when high, update the flag register
    input  [2:0]  branch_condition, // Condition code (e.g., bits [11:9] of instruction)
    input  [15:0] a,                // First operand (e.g., register value)
    input  [15:0] b,                // Second operand (e.g., value to compare)
    input  [3:0]  op,               // Operation code (determines which math is performed)
    output        branch_taken      // Branch decision signal
);

    // Internal signals for computed flags and arithmetic result.
    wire sub;
    wire [15:0] sum;
    wire overflow;
    wire computed_V, computed_Z, computed_N;
    wire Z_flag_op;
    wire N, Z, V;

    // Use op[0] as the subtract control for ADD/SUB operations.
    assign sub = op[0];

    // Instantiate the adder for addition/subtraction.
    adder iadd_sub(
        .A(a),
        .B(b),
        .Sub(sub),
        .Sum(sum),
        .Ovfl(overflow)
    );

    // Compute the overflow flag (V) only for ADD (0000) and SUB (0001).
    assign computed_V = overflow & ((op == 4'b0000) | (op == 4'b0001));

    // Determine if the Zero flag should be computed for the given op.
    assign Z_flag_op = (op == 4'b0000) | (op == 4'b0001) |
                       (op == 4'b0010) | (op == 4'b0100) |
                       (op == 4'b0101) | (op == 4'b0110);
    // Compute Zero flag (Z) when the result is zero.
    assign computed_Z = (sum == 16'h0000) & Z_flag_op;

    // Compute the Negative flag (N) only for ADD and SUB.
    assign computed_N = (sum[15] == 1'b1) & ((op == 4'b0000) | (op == 4'b0001));

    // Latch the computed flags into registers when Flag_Enable_D is asserted.
    // The order is: N (bit 2), Z (bit 1), V (bit 0).
    dff idff0(.d(computed_N), .q(N), .wen(Flag_Enable_D), .clk(clk), .rst(~rst_n)); // N flop
    dff idff1(.d(computed_Z), .q(Z), .wen(Flag_Enable_D), .clk(clk), .rst(~rst_n)); // Z flop
    dff idff2(.d(computed_V), .q(V), .wen(Flag_Enable_D), .clk(clk), .rst(~rst_n)); // V flop

    // Branch decision logic using the stored flag values.
    // N, Z, and V are now available as individual wires.
    reg Branch;
    always @(*) begin
        case (branch_condition)
            3'b000: Branch = ~Z;          // Not Equal (branch if Z == 0)
            3'b001: Branch = Z;           // Equal (branch if Z == 1)
            3'b010: Branch = ~Z & ~N;     // Greater Than (branch if Z==0 and N==0)
            3'b011: Branch = N;           // Less Than (branch if N == 1)
            3'b100: Branch = Z | (~Z & ~N); // Greater Than or Equal (branch if Z==1 or (Z==0 and N==0))
            3'b101: Branch = N | Z;       // Less Than or Equal (branch if N==1 or Z==1)
            3'b110: Branch = V;           // Overflow (branch if V == 1)
            3'b111: Branch = 1'b1;        // Unconditional branch
            default: Branch = 1'b0;
        endcase
    end

    assign branch_taken = Branch;

endmodule
