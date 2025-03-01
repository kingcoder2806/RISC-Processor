module alu(
	input [15:0] a,
	input [15:0] b,
	input [3:0] op,
	output [15:0] result,
	output [2:0] flags
	);
	
	wire sub;
	wire shift_mode;
	wire [15:0] sum;
	wire [15:0] xor_result;
	wire [15:0] red_result;
	wire [15:0] shift_result;
	wire [15:0] ror_result;
	wire [15:0] paddsb_result;
	wire [15:0] add_sub, xor_red, adder_xorred, shift_rorpaddsb;
	wire V;
	
	assign sub = (op = 4'b0001) ? 1 : 0;
	
	adder iadd_sub(.A(a), .B(b), .Sub(sub), .Sum(sum), .Ovfl(V));
	
	assign xor_result = a ^ b;
	
	// reduction module
	// TODO:
	//
	
	assign shift_mode = op[0];
	
	Shifer iShift(.Shift_In(a), .Shift_Val(b[3:0]), .Shift_Out(shift_result), Mode(shift_mode));
	
	right_rotate(.ROR_In(a), .ROR_Val(b[3:0]), .ROR_Out(ror_result));
	
	PADDSB(.A(a), .B(b), .Sum(paddsb_result));
	
	// Assign V flag if overflow occurs only during add and sub operation
	assign flags[0] = V & (op[3:1] == 3'b000);
	
	// Assign Z flag if result is 0
	assign flags[1] = (result == 16'h0000) ? 1 : 0; 
	
	// Assign N flag if result from adder is negative
	assign flags[2] = (sum[15] == 1'b1) & (op[3:1] == 3'b000) ? 1 : 0;
	
	// Seelct ALU output using 2:1 muxes and opcode
	assign add_sub = sum;
	assign xor_red = op[0] ? xor_result : red_result;
	assign ror_paddsb = op[0] ? paddsb : ror;
	
	// 2nd level muxes
	assign adder_xorred = op[1] ? xor_red : add_sub;
	assign shift_rorpaddsb = op[1] ? shift_result : ror_paddsb;
	
	// 3rd level mux
	assign result = op[2] ? shift_rorpaddsb : adder_xorred;

endmodule
