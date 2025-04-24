module WriteDecoder_4_16(input [3:0] RegId, input WriteReg, output [15:0] Wordline);

	// Register 0 is harcoded at value zero, therefore we cannot write anything to it
	assign Wordline[0] = 1'b0;
	
	// Decoder sets output line to 1 if WriteReg and RegId selects it
	assign Wordline[1] = ((RegId == 4'b0001) & WriteReg) ? 1 : 0;
	assign Wordline[2] = ((RegId == 4'b0010) & WriteReg) ? 1 : 0;
	assign Wordline[3] = ((RegId == 4'b0011) & WriteReg) ? 1 : 0;
	assign Wordline[4] = ((RegId == 4'b0100) & WriteReg) ? 1 : 0;
	assign Wordline[5] = ((RegId == 4'b0101) & WriteReg) ? 1 : 0;
	assign Wordline[6] = ((RegId == 4'b0110) & WriteReg) ? 1 : 0;
	assign Wordline[7] = ((RegId == 4'b0111) & WriteReg) ? 1 : 0;
	assign Wordline[8] = ((RegId == 4'b1000) & WriteReg) ? 1 : 0;
	assign Wordline[9] = ((RegId == 4'b1001) & WriteReg) ? 1 : 0;
	assign Wordline[10] = ((RegId == 4'b1010) & WriteReg) ? 1 : 0;
	assign Wordline[11] = ((RegId == 4'b1011) & WriteReg) ? 1 : 0;
	assign Wordline[12] = ((RegId == 4'b1100) & WriteReg) ? 1 : 0;
	assign Wordline[13] = ((RegId == 4'b1101) & WriteReg) ? 1 : 0;
	assign Wordline[14] = ((RegId == 4'b1110) & WriteReg) ? 1 : 0;
	assign Wordline[15] = ((RegId == 4'b1111) & WriteReg) ? 1 : 0;

endmodule