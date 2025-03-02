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
	wire [15:0] level3_mux1, level3_mux2;
	wire [15:0] llb_result, lhb_result, lb_result;
	wire [15:0] addr_result;
	wire V;
	
	// Assign subtraction bit
	assign sub = op[0];
	
	// Adder used for addition, subtraction, load word, and store word
	adder iadd_sub(.A(a), .B(b), .Sub(sub), .Sum(sum), .Ovfl(V));
	
	// Instantiate adder for LW and SW address calculation (address = (a & 0xFFFE) + b)
	// Sign-extension of immediate (b) and shifting taken care at top-level
	adder iLWSW(.A({a[15:1], 1'b0}), .B(b), .Sub(1'b0), .Sum(addr_result), .Ovfl());
	
	// Bitwise xor operation
	assign xor_result = a ^ b;
	
	// reduction module
	// TODO:
	// red iRed();
	
	// Shift mode (0 = SLL, 1 = SRA)
	assign shift_mode = op[0];
	
	// Instantiate shifter module
	Shifter iShift(.Shift_In(a), .Shift_Val(b[3:0]), .Shift_Out(shift_result), .Mode(shift_mode));
	
	// Instantiate rotate right module
	rotate_right iROR(.ROR_In(a), .ROR_Val(b[3:0]), .ROR_Out(ror_result));
	
	// Instantiate paralle sub-word add module
	PADDSB ipaddsb(.A(a), .B(b), .Sum(paddsb_result));
	
	// Assign V flag if overflow occurs only during add and sub operation
	assign flags[0] = V & (op[3:1] == 3'b000);
	
	// Assign Z flag if result is 0
	assign flags[1] = (result == 16'h0000) ? 1 : 0; 
	
	// Assign N flag if result from adder is negative
	assign flags[2] = (sum[15] == 1'b1) & (op[3:1] == 3'b000) ? 1 : 0;
	
	// Logic for LLB and LHB result
	assign llb_result = {a[15:8], b[7:0]};
	assign lhb_result = {b[7:0], a[7:0]};
	
	// Assign which load byte operation is being done
	assign lb_result = op[0] ? lhb_result : llb_result;
	
	// Selct ALU output using 2:1 muxes and opcode
	assign add_sub = sum;
	assign xor_red = op[0] ? xor_result : red_result;
	assign ror_paddsb = op[0] ? paddsb_result : ror_result;
	
	// 2nd level muxes
	assign adder_xorred = op[1] ? xor_red : add_sub;
	assign shift_rorpaddsb = op[1] ? shift_result : ror_paddsb;
	
	// 3rd level mux
	assign level3_mux1 = op[2] ? shift_rorpaddsb : adder_xorred;
	assign level3_mux2 = op[1] ? lb_result : addr_result;
	
	// 4th level mux
	assign result = op[3] ? level3_mux2 : level3_mux1;

	// NEED Case statement to assign the internal rsults to the outpu result 
	/* Example of what thuis might look like possibly


	always @* begin
		casez (opcode)
			4'bz00z		: out_reg = addsub_o;	//add,sub,lw,sw
			`PADDSB		: out_reg = paddsb_o;
			4'bz1zz		: out_reg = shift_o;	 	// all shift ops
			`RED			: out_reg = red_o;
			`XOR			: out_reg = xor_o;
			`LHB			: out_reg = LHB;
			default 		: out_reg = LLB;			// LLB. and everything else.
		endcase
	end
	assign out = out_reg; 
	*/


endmodule
