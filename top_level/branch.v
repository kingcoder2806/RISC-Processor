module branch(
    input [2:0] branch_condition,       // Condition code
    input [2:0] flag_reg,    // Flag register [N, Z, V]
    output branch_taken   // Condition pass signal
);
    wire N, V, Z;
    assign {N, Z, V} = flag_reg;  // Extract flags: flag[2] = N, flag[1] = Z, flag[0] = V

    reg Branch;
    always @(*) begin
        case (branch_condition)
            3'b000: Branch = ~Z;          // Not Equal (Z = 0)
            3'b001: Branch = Z;           // Equal (Z = 1)
            3'b010: Branch = ~Z & ~N;     // Greater Than (Z = N = 0)
            3'b011: Branch = N;           // Less Than (N = 1)
            3'b100: Branch = Z | (~Z & ~N); // Greater Than or Equal (Z = 1 or Z = N = 0)
            3'b101: Branch = N | Z;       // Less Than or Equal (N = 1 or Z = 1)
            3'b110: Branch = V;           // Overflow (V = 1)
            3'b111: Branch = 1'b1;        // Unconditional
        endcase
    end

    assign branch_taken = Branch;
endmodule