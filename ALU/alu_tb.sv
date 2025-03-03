`timescale 1ns/100ps
module alu_tb();

        logic [15:0] a, b, result, expected;
        logic [3:0] op;
        logic [2:0] flags;
        integer error;

        // instantiate alu
        alu iDUT(.a(a), .b(b), .result(result), .op(op), .flags(flags));

        initial begin
            // addition
            error = 0;
            a = 16'h1234;
			b = 16'h4321;
            op = 4'b0000;
            expected = a + b;
            #1
            if (result != expected) begin
                $display("Test 1 failed");
				error = error + 1;
            end else
                $display("Test 1 passed");

            #5
            // addition positive saturation
            a = 16'h7fff;
            b = 16'h0123;
            op = 4'b0000;
            expected = 16'h7fff;
            #1
            if (result != expected) begin
                $display("Test 2 failed");
				error = error + 1;
            end else
                $display("Test 2 passed");

            #5
            // addition negative saturation
            a = 16'h8000;
            b = 16'h0010;
            op = 4'b0001;
            expected = 16'h8000;
            #1
            if (result != expected) begin
                $display("Test 3 failed");
				error = error + 1;
            end else
                $display("Test 3 passed");

            #5
            // subtraction
            a = 16'h1234;
            b = 16'h0123;
            op = 4'b0001;
            expected = a - b;
            #1
            if (result != expected) begin
                $display("Test 4 failed");
				error = error + 1;
            end else
                $display("Test 4 passed");
				
			#5
            // xor
            a = 16'hFAB3;
            b = 16'h2897;
            op = 4'b0010;
            expected = a ^ b;
            #1
            if (result != expected) begin
                $display("Test 5 failed");
				error = error + 1;
            end else
                $display("Test 5 passed");
			
			#5
            // shift left by 5
            a = 16'hFFFF;
            b = 16'hABC5;
            op = 4'b0100;
            expected = a << 4'h5;
            #1
            if (result != expected) begin
                $display("Test 6 failed");
				error = error + 1;
            end else
                $display("Test 6 passed");
			
			#5
            // shift arithmetic right by 8
            a = 16'h8210;
            b = 16'h0028;
            op = 4'b0101;
            expected = 16'hFF82;
            #1
            if (result != expected) begin
                $display("Test 7 failed");
				error = error + 1;
            end else
                $display("Test 7 passed");
				
			#5
            // right rotate by 10
            a = 16'h82AB;
            b = 16'h2F2A;
            op = 4'b0110;
            expected = 16'hAAE0;
            #1
            if (result != expected) begin
                $display("Test 8 failed");
				error = error + 1;
            end else
                $display("Test 8 passed");
				
			#5
            // test paddsb
            a = 16'hAB70;
            b = 16'h572F;
            op = 4'b0111;
            expected = 16'hF27F;
            #1
            if (result != expected) begin
                $display("Test 9 failed");
				error = error + 1;
            end else
                $display("Test 9 passed");
				
			#5
            // test lw
            a = 16'hAB77;
            b = 16'h0050;
            op = 4'b1000;
            expected = (a & 16'hFFFE) + b;
            #1
            if (result != expected) begin
                $display("Test 10 failed");
				error = error + 1;
            end else
                $display("Test 10 passed");
				
			#5
            // test sw
            a = 16'hCDEF;
            b = 16'h0052;
            op = 4'b1001;
            expected = (a & 16'hFFFE) + b;
            #1
            if (result != expected) begin
                $display("Test 11 failed");
				error = error + 1;
            end else
                $display("Test 11 passed");
			
			#5
            // test llb
            a = 16'hAB77;
            b = 16'h0059;
            op = 4'b1010;
            expected = 16'hAB59;
            #1
            if (result != expected) begin
                $display("Test 12 failed");
				error = error + 1;
            end else
                $display("Test 12 passed");
				
			#5
            // test lhb
            a = 16'hABF9;
            b = 16'h0056;
            op = 4'b1011;
            expected = 16'h56F9;
            #1
            if (result != expected) begin
                $display("Test 12 failed");
				error = error + 1;
            end else
                $display("Test 12 passed");
			
			// end of tests
			if (error > 0)
				$display("Some tests failed");
			else
				$display("Yahoo! All tests passed");

            #5
            $stop;
		end
endmodule