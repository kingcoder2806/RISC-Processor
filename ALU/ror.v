`timescale 1ns/100ps
module rotate_right(ROR_In, ROR_Val, ROR_Out);
	
	input [15:0] ROR_In;
	input [3:0] ROR_Val;
	output [15:0] ROR_Out;
	
	// Internal signals for result of each stage
	wire [15:0] ror_stage1, ror_stage2, ror_stage3;
	
	// Stage 1: Rotates Right by 1-bit
	assign ror_stage1 = ROR_Val[0] ? {ROR_In[0], ROR_In[15:1]} : ROR_In;
	
	// Stage 2: Rotates Right by 2-bits
	assign ror_stage2 = ROR_Val[1] ? {ror_stage1[1:0], ror_stage1[15:2]} : ror_stage1;
	
	// Stage 3: Rotates Right by 4-bits
	assign ror_stage3 = ROR_Val[2] ? {ror_stage2[3:0], ror_stage2[15:4]} : ror_stage2;
	
	// Stage 4: Rotates Right by 8-bits and drives result to output
	assign ROR_Out = ROR_Val[3] ? {ror_stage3[7:0], ror_stage3[15:8]} : ror_stage3;

endmodule