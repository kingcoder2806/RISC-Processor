`timescale 1ns/100ps
module CLA_5bit(
    input  [4:0] A,
    input  [4:0] B,
    input        Cin,
    output [4:0] Sum,
    output       Cout
);
    wire [3:0] sum_lower;
    wire       carry_lower;

    // Use your 4-bit CLA for the lower 4 bits
    CLA cla4_inst(
        .A(A[3:0]),
        .B(B[3:0]),
        .Cin(Cin),
        .Cout(carry_lower),
        .Sum(sum_lower),
        .Gg(), // not used
        .Pg()  // not used
    );

    // Add the 5th bit with the carry out from the CLA
    wire carry_upper;
    full_adder_1bit fa_upper(
        .A(A[4]),
        .B(B[4]),
        .Cin(carry_lower),
        .Sum(Sum[4]),
        .Cout(carry_upper)
    );

    // Combine results
    assign Sum[3:0] = sum_lower;
    assign Cout     = carry_upper;
endmodule
