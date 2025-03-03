`timescale 1ns/100ps
module RED_tb;
    reg  [15:0] A, B;
    wire [15:0] R;
    integer errors;

    // Instantiate the RED module
    RED dut (
        .A(A),
        .B(B),
        .R(R)
    );

    initial begin
        errors = 0;

        // Test 1: Zero + Zero
        A = 16'h0000; B = 16'h0000;
        #10;
        if (R !== 16'h0000) begin
            $display("Test 1 FAILED: expected %h, got %h", 16'h0000, R);
            errors = errors + 1;
        end else begin
            $display("Test 1 PASSED: expected %h, got %h", 16'h0000, R);
        end

        // Test 2: Simple positive nibble values
        // A = 0x1234, B = 0x1111
        // Nibble sums: 4+1 = 5, 3+1 = 4, 2+1 = 3, 1+1 = 2, total = 14 (0x000E)
        A = 16'h1234; B = 16'h1111;
        #10;
        if (R !== 16'h000E) begin
            $display("Test 2 FAILED: expected %h, got %h", 16'h000E, R);
            errors = errors + 1;
        end else begin
            $display("Test 2 PASSED: expected %h, got %h", 16'h000E, R);
        end

        // Test 3: Negative nibble in high bits
        // A = 0xF000, B = 0x0F00.
        // Nibble0: 0+0=0, nibble1: 0+F (-1)= -1, nibble2: 0+0=0, nibble3: F (-1)+0 = -1
        // Total = 0 + (-1) + 0 + (-1) = -2, which is 16'hFFFE in 16-bit two's complement.
        A = 16'hF000; B = 16'h0F00;
        #10;
        if (R !== 16'hFFFE) begin
            $display("Test 3 FAILED: expected %h, got %h", 16'hFFFE, R);
            errors = errors + 1;
        end else begin
            $display("Test 3 PASSED: expected %h, got %h", 16'hFFFE, R);
        end

        // Test 4: Random example
        // A = 0xABCD, B = 0x1234.
        // Calculate nibble sums as signed 4-bit values:
        // nibble0: D (1101 = -3) + 4 (0100 = 4) =  1
        // nibble1: C (1100 = -4) + 3 (0011 = 3) = -1
        // nibble2: B (1011 = -5) + 2 (0010 = 2) = -3
        // nibble3: A (1010 = -6) + 1 (0001 = 1) = -5
        // Total = 1 + (-1) + (-3) + (-5) = -8, which is 16'hFFF8.
        A = 16'hABCD; B = 16'h1234;
        #10;
        if (R !== 16'hFFF8) begin
            $display("Test 4 FAILED: expected %h, got %h", 16'hFFF8, R);
            errors = errors + 1;
        end else begin
            $display("Test 4 PASSED: expected %h, got %h", 16'hFFF8, R);
        end

        // Test 5: Both near extremes
        // A = 0xFFFF, B = 0xFFFF.
        // Each nibble: F (1111) represents -1.
        // Sum per nibble = -1 + (-1) = -2.
        // Total sum = -2 * 4 = -8 = 16'hFFF8.
        A = 16'hFFFF; B = 16'hFFFF;
        #10;
        if (R !== 16'hFFF8) begin
            $display("Test 5 FAILED: expected %h, got %h", 16'hFFF8, R);
            errors = errors + 1;
        end else begin
            $display("Test 5 PASSED: expected %h, got %h", 16'hFFF8, R);
        end

        if (errors == 0)
            $display("All tests PASSED.");
        else
            $display("%0d test(s) FAILED.", errors);

        $stop;
    end
endmodule
