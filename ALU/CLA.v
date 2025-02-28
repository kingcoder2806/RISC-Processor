`timescale 1ns/100ps
module CLA(
	input [3:0] A,
	input [3:0] B,
	input Cin,
	output Cout,
	output [3:0] Sum,
	output Ovfl,
	output Gg,
	output Pg);
	
	// Intermediate carry, generate, and propagate signals
	wire [3:0] carry;
	wire [3:0] g;
	wire [3:0] p;
	
	// Generate logic
	assign g[0] = A[0] & B[0];
	assign g[1] = A[1] & B[1];
	assign g[2] = A[2] & B[2];
	assign g[3] = A[3] & B[3];
	
	// Propagate logic
	assign p[0] = A[0] | B[0];
	assign p[1] = A[1] | B[1];
	assign p[2] = A[2] | B[2];
	assign p[3] = A[3] | B[3];
	
	// Assign group generate and group propagate logic
	assign Pg = p[3] & p[2] & p[1] & p[0];
	assign Gg = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
	
	// Assign carry generates
	assign carry[0] = Cin;
	assign carry[1] = g[0] | (p[0] & carry[0]);
	assign carry[2] = g[1] | (p[1] & carry[1]);
	assign carry[3] = g[2] | (p[2] & carry[2]);
	assign Cout = g[3] | (p[3] & carry[3]);
	
	// Instiantiate full adders
	full_adder_1bit iFA0(.A(A[0]), .B(B[0]), .Cin(carry[0]), .Sum(Sum[0]), .Cout());
	full_adder_1bit iFA1(.A(A[1]), .B(B[1]), .Cin(carry[1]), .Sum(Sum[1]), .Cout());
	full_adder_1bit iFA2(.A(A[2]), .B(B[2]), .Cin(carry[2]), .Sum(Sum[2]), .Cout());
	full_adder_1bit iFA3(.A(A[3]), .B(B[3]), .Cin(carry[3]), .Sum(Sum[3]), .Cout());
	
	// Assign overflow logic
	assign Ovfl = (~A[3] & ~B[3] & Sum[3]) | (A[3] & B[3] & ~Sum[3]);

endmodule
