`timescale 1ns/100ps
module CLA_7bit(
    input  [6:0] A,
    input  [6:0] B,
    input        Cin,
    output [6:0] Sum,
    output       Cout
);
    wire [3:0] sum_lower;
    wire       carry_lower;

    // Lower 4 bits
    CLA cla4_inst(
        .A(A[3:0]),
        .B(B[3:0]),
        .Cin(Cin),
        .Cout(carry_lower),
        .Sum(sum_lower),
        .Gg(),
        .Pg()
    );

    // Bit 4
    wire sum_bit4, carry_bit4;
    full_adder_1bit fa4(
        .A(A[4]),
        .B(B[4]),
        .Cin(carry_lower),
        .Sum(sum_bit4),
        .Cout(carry_bit4)
    );

    // Bit 5
    wire sum_bit5, carry_bit5;
    full_adder_1bit fa5(
        .A(A[5]),
        .B(B[5]),
        .Cin(carry_bit4),
        .Sum(sum_bit5),
        .Cout(carry_bit5)
    );

    // Bit 6
    wire sum_bit6, carry_bit6;
    full_adder_1bit fa6(
        .A(A[6]),
        .B(B[6]),
        .Cin(carry_bit5),
        .Sum(sum_bit6),
        .Cout(carry_bit6)
    );

    // Combine
    assign Sum = {sum_bit6, sum_bit5, sum_bit4, sum_lower};
    assign Cout = carry_bit6;
endmodule
