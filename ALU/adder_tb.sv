`timescale 1ns/100ps
module adder_tb();

	logic [15:0] A, B, Sum;
	logic Sub, Ovfl;
	
	// instantiate DUT
	adder idut(.A(A), .B(B), .Sum(Sum), .Sub(Sub), .Ovfl(Ovfl));
	
	initial begin
		// Simple addition
		A = 16'h1234;
		B = 16'h4321;
		Sub = 0;
		
		#5
		// Simple subtraction
		A = 16'h1234;
		B = 16'h0212;
		Sub = 1;
		
		#5
		// Cause Overflow (saturate it to most positive)
		A = 16'h7FFF;
		B = 16'h0001;
		Sub = 0;
		
		#5
		// Cause Overflow (saturate to most negative)
		A = 16'h8000;
		B = 16'h8001;
		Sub = 0;
		
		#5
		$stop;
	
	end

endmodule