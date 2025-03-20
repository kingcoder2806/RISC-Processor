`timescale 1ns/100ps
module PADDSB (Sum, A, B);

	input [15:0] A, B; // Input data values
	output [15:0] Sum; // Sum output

	// Internal overflow signals for each 4-bit adders
	wire Ovfl0, Ovfl1, Ovfl2, Ovfl3;
	
	// Wire to connect to subtract pins of 4-bit adders
	wire sub;
	
	// We never subtract so set subtract signal to 0
	assign sub = 0;
	
	// 16-bit wire to drive result of each sub-adders
	wire [15:0] result;
	
	// Instantiate 4-bit adder blocks
	addsub_4bit iAS0(.A(A[3:0]), .B(B[3:0]), .Sum(result[3:0]), .Ovfl(Ovfl0), .sub(sub));
	addsub_4bit iAS1(.A(A[7:4]), .B(B[7:4]), .Sum(result[7:4]), .Ovfl(Ovfl1), .sub(sub));
	addsub_4bit iAS2(.A(A[11:8]), .B(B[11:8]), .Sum(result[11:8]), .Ovfl(Ovfl2), .sub(sub));
	addsub_4bit iAS3(.A(A[15:12]), .B(B[15:12]), .Sum(result[15:12]), .Ovfl(Ovfl3), .sub(sub));
	
	// Check for overflow in each half byte and saturate accordingly
	// When overflow occurs, check the MSB of the result to determine saturation direction
	// When overflow occurs, use sign bits of inputs to determine saturation direction
	assign Sum[3:0] = Ovfl0 ? ((A[3] == B[3]) ? (A[3] ? 4'b1000 : 4'b0111) : result[3:0]) : result[3:0];
	assign Sum[7:4] = Ovfl1 ? ((A[7] == B[7]) ? (A[7] ? 4'b1000 : 4'b0111) : result[7:4]) : result[7:4];
	assign Sum[11:8] = Ovfl2 ? ((A[11] == B[11]) ? (A[11] ? 4'b1000 : 4'b0111) : result[11:8]) : result[11:8];
	assign Sum[15:12] = Ovfl3 ? ((A[15] == B[15]) ? (A[15] ? 4'b1000 : 4'b0111) : result[15:12]) : result[15:12];

endmodule
