`timescale 1ns/100ps
module CLA_tb();

	logic [3:0] A, B, Sum;
	logic Cin, Cout, Gg, Pg;
	
	// Instantiate DUT
	CLA iDUT(.A(A), .B(B), .Sum(Sum), .Cin(Cin), .Cout(Cout), .Gg(Gg), .Pg(Pg));
	
	initial begin
		// Simple addition
		A = 4'b0001;
		B = 4'b0001;
		Cin = 0;
		
		#5
		// Gg and Ovfl should be 1
		A = 4'b1000;
		B = 4'b1000;
		Cin = 0;
		
		#5
		// Pg should be 1
		A = 4'b1010;
		B = 4'b0101;
		Cin = 0;
		
		#5
		// Pg and Ovfl should be 1
		A = 4'b1111;
		B = 4'b0000;
		Cin = 1;
		
		#5
		// Gg should be 1
		A = 4'b1010;
		B = 4'b0110;
		Cin = 0;
		
		#5
		$stop;
	
	end

endmodule
