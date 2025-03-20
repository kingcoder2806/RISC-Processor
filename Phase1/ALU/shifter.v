`timescale 1ns/100ps
module Shifter (Shift_Out, Shift_In, Shift_Val, Mode);
	
	input [15:0] Shift_In; // This is the input data to perform shift operation on
	input [3:0] Shift_Val; // Shift amount (used to shift the input data)
	input Mode; // To indicate 0=SLL or 1=SRA
	output [15:0] Shift_Out; // Shifted output data
	
	// Internal signals
	wire [15:0] SRA_Stage1, SRA_Stage2, SRA_Stage3, SRA_Stage4;
	wire [15:0] SLL_Stage1, SLL_Stage2, SLL_Stage3, SLL_Stage4;
	wire [15:0] Stage1_Result, Stage2_Result, Stage3_Result; 
	
	// Stage 1 Shifter (Shifts by 1-bit)
	assign SRA_Stage1 = Shift_Val[0] ? {Shift_In[15], Shift_In[15:1]} : Shift_In;
	assign SLL_Stage1 = Shift_Val[0] ? {Shift_In[14:0], 1'b0} : Shift_In;
	assign Stage1_Result = Mode ? SRA_Stage1 : SLL_Stage1;
	
	// Stage 2 Shifter (Shifts by 2-bits)
	assign SRA_Stage2 = Shift_Val[1] ? {{2{Stage1_Result[15]}}, Stage1_Result[15:2]} : Stage1_Result;
	assign SLL_Stage2 = Shift_Val[1] ? {Stage1_Result[13:0], 2'b00} : Stage1_Result;
	assign Stage2_Result = Mode ? SRA_Stage2 : SLL_Stage2;
	
	// Stage 3 Shifter (Shifts by 4-bits)
	assign SRA_Stage3 = Shift_Val[2] ? {{4{Stage2_Result[15]}}, Stage2_Result[15:4]} : Stage2_Result;
	assign SLL_Stage3 = Shift_Val[2] ? {Stage2_Result[11:0], 4'b0000} : Stage2_Result;
	assign Stage3_Result = Mode ? SRA_Stage3 : SLL_Stage3;
	
	// Stage 4 Shifter (Shifts by 8-bits)
	assign SRA_Stage4 = Shift_Val[3] ? {{8{Stage3_Result[15]}}, Stage3_Result[15:8]} : Stage3_Result;
	assign SLL_Stage4 = Shift_Val[3] ? {Stage3_Result[7:0], 8'b00000000} : Stage3_Result;
	assign Shift_Out = Mode ? SRA_Stage4 : SLL_Stage4;
	
endmodule
