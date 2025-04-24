`timescale 1ns/100ps
module full_adder_1bit(A, B, Cin, Sum, Cout);
	
	input A, B;			// Input values
	input Cin;			// Carry In value
	output Sum, Cout;		// Sum and Carry out bits
	
	// Internal signals
	wire A_xor_B;
	wire Cout_in0, Cout_in1;
	
	// Full adder logic for 1-bit
	xor iXOR0(A_xor_B, A, B);
	xor iXOR1(Sum, A_xor_B, Cin);
	
	and iAND0(Cout_in0, A_xor_B, Cin);
	and iAND1(Cout_in1, A, B);
	
	or iOR0(Cout, Cout_in0, Cout_in1);

endmodule