module alu(
	input [15:0] a,
	input [15:0] b,
	input [3:0] op,
	output [15:0] result,
	output [2:0] flags
	);
	
	// Internal signals
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
	wire V, Z_flag_op;
	
	// Assign subtraction bit
	assign sub = op[0];
	
	// Adder used for addition, subtraction, load word, and store word
	adder iadd_sub(.A(a), .B(b), .Sub(sub), .Sum(sum), .Ovfl(V));
	
	// Instantiate adder for LW and SW address calculation (address = (a & 0xFFFE) + b)
	// Sign-extension of immediate (b) and shifting taken care at top-level
	adder iLWSW(.A({a & 16'hFFFE}), .B(b), .Sub(1'b0), .Sum(addr_result), .Ovfl());
	
	// Bitwise xor operation
	assign xor_result = a ^ b;
	
	// Instantiate reduction module
	RED iRED(.A(a), .B(b), .R(red_result));
	
	// Shift mode (0 = SLL, 1 = SRA)
	assign shift_mode = op[0];
	
	// Instantiate shifter module
	Shifter iShift(.Shift_In(a), .Shift_Val(b[3:0]), .Shift_Out(shift_result), .Mode(shift_mode));
	
	// Instantiate rotate right module
	rotate_right iROR(.ROR_In(a), .ROR_Val(b[3:0]), .ROR_Out(ror_result));
	
	// Instantiate paralle sub-word add module
	PADDSB ipaddsb(.A(a), .B(b), .Sum(paddsb_result));
	
	// Assign V flag if overflow occurs only during add and sub operation
	assign flags[0] = V & (op == 4'b0000 | op == 4'b0001);
	
	// Assign Z flag if result is 0 only during add, sub, xor, sll, sra, and ror operations
	assign Z_flag_op = ((op == 4'b0000) | (op == 4'b0001) | (op == 4'b0010) | (op == 4'b0100) | (op == 4'b0101) | (op == 4'b0110));
	assign flags[1] = (result == 16'h0000) & (Z_flag_op);
	
	// Assign N flag if result from add and sub is negative
	assign flags[2] = (sum[15] == 1'b1) & (op == 4'b0000 | op == 4'b0001);
	
	// Logic for LLB and LHB result
	assign llb_result = {a[15:8], b[7:0]};
	assign lhb_result = {b[7:0], a[7:0]};
	
	// Assign which load byte operation is being done
	assign lb_result = op[0] ? lhb_result : llb_result;
	
	// Case statement to select the operation result
	reg [15:0] final_result;
	
	always @* begin
		case(op)
			4'b0000: final_result = sum;               // ADD
			4'b0001: final_result = sum;               // SUB
			4'b0010: final_result = xor_result;        // XOR
			4'b0011: final_result = red_result;        // RED
			4'b0100: final_result = shift_result;      // SLL
			4'b0101: final_result = shift_result;      // SRA
			4'b0110: final_result = ror_result;        // ROR
			4'b0111: final_result = paddsb_result;     // PADDSB
			4'b1000: final_result = addr_result;       // LW
			4'b1001: final_result = addr_result;       // SW
			4'b1010: final_result = llb_result;        // LLB
			4'b1011: final_result = lhb_result;        // LHB
			default: final_result = 16'h0000;          // Default case
		endcase
	end
	
	assign result = final_result;
	
endmodule