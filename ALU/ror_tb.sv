`timescale 1ns/100ps
module ror_tb();

	logic [15:0] ROR_In, ROR_Out;
	logic [3:0] ROR_Val;
	
	// instantiate DUT
	rotate_right iDUT(.ROR_In(ROR_In), .ROR_Out(ROR_Out), .ROR_Val(ROR_Val));
	
	initial begin
		ROR_In = 16'hAB75;
		ROR_Val = 4'h2;
		
		#5
		ROR_Val = 4'h7;
		
		#5
		ROR_Val = 4'hF;
		
		#5
		$stop;
		
	end
	
endmodule