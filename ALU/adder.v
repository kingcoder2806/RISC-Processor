`timescale 1ns/100ps
module adder(
	input [15:0] A,
	input [15:0] B,
	input Sub,
	output [15:0] Sum,
	output Ovfl);
	
	// Internal signals
	wire [15:0] B_in;		// Intermediate B operand
	wire [4:0] C;			// Carry-in signal for each CLA
	wire [15:0] Unsat_Sum;	// Adder result before saturation
	wire [3:0] Pg;			// Group propagate signal
	wire [3:0] Gg;			// Group generate signal
	
	// Invert B operand if sub is 1
	assign B_in = Sub ? (~B) : B;
	
	// Assign carry in for each CLA (Look Ahead Block)
	assign C[0] = Sub;
	assign C[1] = Gg[0] | (Pg[0] & C[0]);
	assign C[2] = Gg[1] | (Pg[1] & C[1]);
	assign C[3] = Gg[2] | (Pg[2] & C[2]);
	assign C[4] = Gg[3] | (Pg[3] & C[3]);
	
	// Instantiate 4-bit carry look ahead adders
	CLA iCLA0(.A(A[3:0]), .B(B_in[3:0]), .Cin(C[0]), .Cout(), .Sum(Unsat_Sum[3:0]), .Gg(Gg[0]), .Pg(Pg[0]));
	CLA iCLA1(.A(A[7:4]), .B(B_in[7:4]), .Cin(C[1]), .Cout(), .Sum(Unsat_Sum[7:4]), .Gg(Gg[1]), .Pg(Pg[1]));
	CLA iCLA2(.A(A[11:8]), .B(B_in[11:8]), .Cin(C[2]), .Cout(), .Sum(Unsat_Sum[11:8]), .Gg(Gg[2]), .Pg(Pg[2]));
	CLA iCLA3(.A(A[15:12]), .B(B_in[15:12]), .Cin(C[3]), .Cout(), .Sum(Unsat_Sum[15:12]), .Gg(Gg[3]), .Pg(Pg[3]));
	
	// Assign Overflow
	assign Ovfl = (~A[15] & ~B_in[15] & Unsat_Sum[15]) | (A[15] & B_in[15] & ~Unsat_Sum[15]);
	
	// Saturate Sum to most positive or most negative
	assign Sum = Ovfl ? 
             ((~A[15] & ~B_in[15]) ? 16'h7FFF : 
             ((A[15] & B_in[15]) ? 16'h8000 : Unsat_Sum)) 
             : Unsat_Sum;
	
endmodule