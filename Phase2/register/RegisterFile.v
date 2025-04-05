module RegisterFile(input clk, input rst, input [3:0] SrcReg1, input [3:0] SrcReg2, input [3:0]
	DstReg, input WriteReg, input [15:0] DstData, inout [15:0] SrcData1, inout [15:0] SrcData2);
	
	// Internal signals for read decoder outputs
	wire [15:0] SrcReg1_Sel, SrcReg2_Sel;
	
	// Internal signals for write decoder outputs
	wire [15:0] WriteEn;
	
	// Bypassing support wires
	wire [15:0] Data_Out1, Data_Out2;
	
	// Instantiate Read Decoders
	ReadDecoder_4_16 iRD0 (.RegId(SrcReg1), .Wordline(SrcReg1_Sel));
	ReadDecoder_4_16 iRD1 (.RegId(SrcReg2), .Wordline(SrcReg2_Sel));
	
	// Instantiate Write decoder
	WriteDecoder_4_16 iWD0 (.RegId(DstReg), .WriteReg(WriteReg), .Wordline(WriteEn));
	
	// Instantiate Registers
	Register iReg0(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[0]), .ReadEnable1(SrcReg1_Sel[0]), .ReadEnable2(SrcReg2_Sel[0]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg1(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[1]), .ReadEnable1(SrcReg1_Sel[1]), .ReadEnable2(SrcReg2_Sel[1]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg2(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[2]), .ReadEnable1(SrcReg1_Sel[2]), .ReadEnable2(SrcReg2_Sel[2]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg3(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[3]), .ReadEnable1(SrcReg1_Sel[3]), .ReadEnable2(SrcReg2_Sel[3]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg4(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[4]), .ReadEnable1(SrcReg1_Sel[4]), .ReadEnable2(SrcReg2_Sel[4]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg5(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[5]), .ReadEnable1(SrcReg1_Sel[5]), .ReadEnable2(SrcReg2_Sel[5]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg6(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[6]), .ReadEnable1(SrcReg1_Sel[6]), .ReadEnable2(SrcReg2_Sel[6]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg7(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[7]), .ReadEnable1(SrcReg1_Sel[7]), .ReadEnable2(SrcReg2_Sel[7]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg8(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[8]), .ReadEnable1(SrcReg1_Sel[8]), .ReadEnable2(SrcReg2_Sel[8]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg9(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[9]), .ReadEnable1(SrcReg1_Sel[9]), .ReadEnable2(SrcReg2_Sel[9]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg10(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[10]), .ReadEnable1(SrcReg1_Sel[10]), .ReadEnable2(SrcReg2_Sel[10]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg11(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[11]), .ReadEnable1(SrcReg1_Sel[11]), .ReadEnable2(SrcReg2_Sel[11]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg12(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[12]), .ReadEnable1(SrcReg1_Sel[12]), .ReadEnable2(SrcReg2_Sel[12]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg13(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[13]), .ReadEnable1(SrcReg1_Sel[13]), .ReadEnable2(SrcReg2_Sel[13]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg14(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[14]), .ReadEnable1(SrcReg1_Sel[14]), .ReadEnable2(SrcReg2_Sel[14]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	Register iReg15(.clk(clk), .rst(rst), .D(DstData), .WriteReg(WriteEn[15]), .ReadEnable1(SrcReg1_Sel[15]), .ReadEnable2(SrcReg2_Sel[15]), .Bitline1(Data_Out1), .Bitline2(Data_Out2));
	
	// Register bypassing logic
	assign SrcData1 = ((SrcReg1 == DstReg) & (DstReg != 4'b0000)) ? DstData : Data_Out1;
	assign SrcData2 = ((SrcReg2 == DstReg) & (DstReg != 4'b0000)) ? DstData : Data_Out2;
	
endmodule
