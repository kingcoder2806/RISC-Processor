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
                end else begin
                        $display("Test 1 passed");
                        error = error + 1;
                end
                #5
                // addition positive saturation
                a = 16'h7fff;
                b = 16'h0123;
                op = 4'b0001;
                expected = 16'h7fff;
                #1
                if (result != expected) begin
                        $display("Test 2 failed");
                end else begin
                        $display("Test 2 passed");
                        error = error + 1;
                end

                #5
                // addition negative saturation
                a = 16'h8000;
                b = 16'h0010;
                op = 4'b0001;
                expected = 16'h8000;
                #1
                if (result != expected) begin
                        $display("Test 3 failed");
                end else begin
                        $display("Test 3 passed");
                        error = error + 1;
                end

                #5
                // subtraction
                a = 16'h1234;
                b = 16'h0123;
                op = 4'b0001;
                expected = a - b;
                #1
                if (result != expected) begin
                        $display("Test 4 failed");
                end else begin
                        $display("Test 4 passed");
                        error = error + 1;
                end

                #5
                $stop;

        end
