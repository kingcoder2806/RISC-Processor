module adder_pc(A, B, Sub, Sum);

	input [15:0] A;
	input [15:0] B;
	input Sub;
	input [15:0] Sum;
	
	// Instantiate 4-bit adders
	// sub signal set to 0 as we never subtract
	addsub_4bit iadd0(.A(A[3:0]), .B(B[3:0]), .sub(1'b0), .Sum(Sum[3:0]), .Ovfl());
	addsub_4bit iadd1(.A(A[7:4]), .B(B[7:4]), .sub(1'b0), .Sum(Sum[7:4]), .Ovfl());
	addsub_4bit iadd2(.A(A[11:8]), .B(B[11:8]), .sub(1'b0), .Sum(Sum[11:8]), .Ovfl());
	addsub_4bit iadd3(.A(A[15:12]), .B(B[15:12]), .sub(1'b0), .Sum(Sum[15:12]), .Ovfl());

endmodule