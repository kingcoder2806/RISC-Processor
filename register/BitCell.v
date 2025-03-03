module BitCell( input clk, input rst, input D, input WriteEnable, input ReadEnable1, input
	ReadEnable2, inout Bitline1, inout Bitline2);
	
	// Internal signal for read lines
	wire Q_Out;
	
	dff iDFF0 (.clk(clk), .rst(rst), .d(D), .wen(WriteEnable), .q(Q_Out));
	
	assign Bitline1 = (ReadEnable1) ? Q_Out : 1'bZ;
	assign Bitline2 = (ReadEnable2) ? Q_Out : 1'bZ;
	
endmodule