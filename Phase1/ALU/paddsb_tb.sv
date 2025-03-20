`timescale 1ns/100ps
module paddsb_tb();

	logic [15:0] A, B, Sum;
	
	// instantiate DUT
	PADDSB iDUT(.A(A), .B(B), .Sum(Sum));
	
	initial begin
		A = 16'h1234;
		B = 16'h4321;
		
		#5
		// Saturation at every 4-bit adders
		A = 16'h7777;
		B = 16'h3333;
		
		#5
		// Saturation
		A = 16'h8921;
		B = 16'h9257;
		
		#5
		$stop;
		
	end

endmodule