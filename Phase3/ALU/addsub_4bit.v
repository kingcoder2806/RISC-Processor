`timescale 1ns/100ps
module addsub_4bit (Sum, Ovfl, A, B, sub);
	
	input [3:0] A, B; //Input values
	input sub; // add-sub indicator
	output [3:0] Sum; //sum output
	output Ovfl; //To indicate overflow
	
	// Internal signals
	wire Cin_bit0;
	wire Cout_bit0, Cout_bit1, Cout_bit2, Cout_bit3;
	wire [3:0] B_operand;
	
	// If doing subtraction operation, Carry In of bit 0 needs to be 1
	assign Cin_bit0 = sub ? 1 : 0;
	
	// Invert the B operand if subtraction operation
	assign B_operand = sub ? ~B : B;
	
	// Instantiate full adders and interconnect signals
	full_adder_1bit FA0(.A(A[0]), .B(B_operand[0]), .Cin(Cin_bit0), .Sum(Sum[0]), .Cout(Cout_bit0));
	full_adder_1bit FA1(.A(A[1]), .B(B_operand[1]), .Cin(Cout_bit0), .Sum(Sum[1]), .Cout(Cout_bit1));
	full_adder_1bit FA2(.A(A[2]), .B(B_operand[2]), .Cin(Cout_bit1), .Sum(Sum[2]), .Cout(Cout_bit2));
	full_adder_1bit FA3(.A(A[3]), .B(B_operand[3]), .Cin(Cout_bit2), .Sum(Sum[3]), .Cout(Cout_bit3));
	
	// Check for overflow
	// Overflow cases: 1) If positve + positve = negative
	//				   2) If negative + negative = positve
	
	assign Ovfl = (~A[3] & ~B_operand[3] & Sum[3]) | (A[3] & B_operand[3] & ~Sum[3]);

endmodule