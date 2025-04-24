module RegisterFile_tb();

    reg clk;
    reg rst;
    reg [3:0] SrcReg1, SrcReg2, DstReg;
    reg WriteReg;
    reg [15:0] DstData;
    wire [15:0] SrcData1, SrcData2;
    
    // instantiate RegisterFile
    RegisterFile iDUT(
        .clk(clk),
        .rst(rst),
        .SrcReg1(SrcReg1),
        .SrcReg2(SrcReg2),
        .DstReg(DstReg),
        .WriteReg(WriteReg),
        .DstData(DstData),
        .SrcData1(SrcData1),
        .SrcData2(SrcData2)
    );
    
    // clock generation (20ns)
    always begin
        #10 clk = ~clk;
    end
    
    // test stimulus
    initial begin

        // initialize signals
        clk = 0;
        rst = 1;
        SrcReg1 = 0;
        SrcReg2 = 0;
        DstReg = 0;
        WriteReg = 0;
        DstData = 0;
        
        // deassert rst and wait for propagaton
        @(posedge clk);
        rst = 0;
        @(posedge clk);
        
        // test 1: write to register 2
        DstReg = 4'b0010;
        DstData = 16'hABCD;
        WriteReg = 1;
        @(posedge clk);


        // test 2: read from register 2
        WriteReg = 0;
        SrcReg1 = 4'b0010;

        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 !== 16'hABCD) begin
            $display("Test 1 Failed \n Test 2 Failed: Expected %h, Got %h", 16'hABCD, SrcData1);
            $stop();
        end else begin
            $display("Test 1 Passed \n Test 2 Passed: Write and Read correct data from register 2");
        end
        
        // test 3: write-before-read bypass
        @(posedge clk);
        DstReg = 4'b0101;
        SrcReg1 = 4'b0101;
        DstData = 16'h1234;
        WriteReg = 1;

        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 !== 16'h1234) begin
            $display("Test 3 Failed: Bypass not working. Expected %h, Got %h", 16'h1234, SrcData1);
            $stop();
        end else begin
            $display("Test 3 Passed: Bypass working correctly");
        end

        // test 4: make sure that bypass still writes to DstReg
        @(posedge clk);
        SrcReg1 = 4'b0101;
        WriteReg = 0;

        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 !== 16'h1234) begin
            $display("Test 4 Failed: Bypass didnt write to DstReg. Expected %h, Got %h", 16'h1234, SrcData1);
            $stop();
        end else begin
            $display("Test 4 Passed: Bypass wrote to DstReg");
        end


        // test 5: write to register 1 (should be zero)
        @(posedge clk);
        DstReg = 4'b0001;
        SrcReg1 = 4'b0111;
        DstData = 16'h1000;
        WriteReg = 1;

        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 != 16'h0000) begin
            $display("Test 5 Failed: Resgister 1 is not hardcoded to 0. Expected %h, Got %h", 16'h0000, SrcData1);
            $stop();
        end else begin
            $display("Test 5 Passed: Regsiter 1 is set to zero");
        end


        // test 6: Dual read ports
        @(posedge clk);
        WriteReg = 0;
        SrcReg1 = 4'b0010;  // Read ABCD from reg 2
        SrcReg2 = 4'b0101;  // Read 1234 from reg 5

        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 !== 16'hABCD || SrcData2 !== 16'h1234) begin
            $display("Test 6 Failed: Dual read incorrect");
            $display("SrcData1 = %h (Expected ABCD)", SrcData1);
            $display("SrcData2 = %h (Expected 1234)", SrcData2);
            $stop();
        end else begin
            $display("Test 6 Passed: Dual read working correctly");
        end
        
        // test 7: reset functionality
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        SrcReg1 = 4'b0010;
        SrcReg2 = 4'b0101;
        
        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 !== 16'h0000 || SrcData2 !== 16'h0000) begin
            $display("Test 6 Failed: Reset not working");
            $display("SrcData1 = %h (Expected 0)", SrcData1);
            $display("SrcData2 = %h (Expected 0)", SrcData2);
            $stop();
        end else begin
            $display("Test 7 Passed: Reset working correctly");
        end
        
        // test 8: write to register 0
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        DstReg = 4'b0000;
        DstData = 16'hFFFF;
        WriteReg = 1;
        @(posedge clk);
        SrcReg1 = 4'b0000;

        // wait for signals to propagate
        @(posedge clk);
        if(SrcData1 !== 16'h0000) begin
            $display("Test 8 Failed: Write Disable to reg0 failed");
            $stop();
        end else begin
            $display("Test 8 Passed: Write Disable to reg0 working");
        end
        
        // test 9: sequential writes and reads
        @(posedge clk);
        for(int i = 1; i < 16; i++) begin
            // write value to register i
            DstReg = i[3:0];
            DstData = 16'h1000 + i;
            WriteReg = 1;
            @(posedge clk);
        end
        
        WriteReg = 0;
        for(int i = 1; i < 16; i++) begin
            // Read and verify value from register i
            SrcReg1 = i[3:0];
            @(posedge clk);
            if(SrcData1 !== (16'h1000 + i)) begin
                $display("Test 9 Failed: Register %d = %h (Expected %h)", 
                    i, SrcData1, 16'h1000 + i);
            $stop();
            end
        end
        $display("Test 9 Complete: Sequential access test");
        
        // End simulation
        @(posedge clk);
        $display("YAHOO! All tests passed!");
        $stop();
    end
endmodule