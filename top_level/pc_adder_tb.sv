`timescale 1ns/100ps
module pc_adder_tb();

	logic [15:0] A, B, Sum;
	logic sub;
	
	adder_pc idut(.A(A), .B(B), .Sum(Sum), .Sub(sub));
	
	initial begin
		A = 16'h0000;
		B = 16'h0002;
		sub = 0;
		
		#5
		A = 16'h1234;
		
		#5
		A = 16'h5260;
		
		#5
		$stop;
	
	end

endmodule