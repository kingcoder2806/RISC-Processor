module RegisterFile_tb();

	logic [3:0] SrcReg1, SrcReg2, DstReg;
	logic [15:0] DstData;
	wire [15:0] SrcData1, SrcData2;
	logic WriteReg, clk, rst;
	
	// Instantiate DUT
	RegisterFile iDUT(.clk(clk), 
					  .rst(rst), 
					  .SrcReg1(SrcReg1), 
					  .SrcReg2(SrcReg2), 
					  .DstReg(DstReg), 
					  .DstData(DstData), 
					  .SrcData1(SrcData1), 
					  .SrcData2(SrcData2), 
					  .WriteReg(WriteReg));
	
	always
		#5 clk = ~clk;
	
	initial begin
		clk = 0;
		rst = 1;
		SrcReg1 = 4'b0000;
		SrcReg2 = 4'b0001;
		DstReg = 4'b0000;
		DstData = 16'h2A59;
		WriteReg = 0;
		
		@(posedge clk);
		rst = 0;
		
		@(posedge clk);
		#1
		if (SrcData1 != 16'h0000 && SrcData2 != 16'h0000) begin
			$display("Test 1: Error");
		end else
			$display("Test 1 passed as all registers should be set to 0 at reset");
		
		@(posedge clk);
		// Attempt to write to register 0
		WriteReg = 1;
		
		@(posedge clk);
		#1
		if (SrcData1 != 16'h0000) begin
			$display("Test 2: Error");
		end else
			$display("Test 2 passed as register 0 is hardwired and not written to");
		
		@(posedge clk);
		
		DstReg = 4'b0001;
		SrcReg1 = 4'b0001;
		@(posedge clk);
		#1
		if (SrcData1 != 16'h2A59) begin
			$display("Test 3: Error");
		end else
			$display("Test 3 passed");
			
		@(posedge clk);
		$stop;
	
	end

endmodule