module RED(
    input  [15:0] A,
    input  [15:0] B,
    output [15:0] R
);
    // 1) Sign-extend each 4-bit nibble from A and B to 5-bit signed numbers.
    wire signed [4:0] a0, a1, a2, a3;
    wire signed [4:0] b0, b1, b2, b3;
    assign a0 = {A[3],   A[3:0]};
    assign a1 = {A[7],   A[7:4]};
    assign a2 = {A[11],  A[11:8]};
    assign a3 = {A[15],  A[15:12]};
    assign b0 = {B[3],   B[3:0]};
    assign b1 = {B[7],   B[7:4]};
    assign b2 = {B[11],  B[11:8]};
    assign b3 = {B[15],  B[15:12]};
    
    // 2) Add corresponding nibble pairs using CLA_5bit
    wire [4:0] sum0, sum1, sum2, sum3;
    CLA_5bit cla5_0(.A(a0), .B(b0), .Cin(1'b0), .Sum(sum0), .Cout());
    CLA_5bit cla5_1(.A(a1), .B(b1), .Cin(1'b0), .Sum(sum1), .Cout());
    CLA_5bit cla5_2(.A(a2), .B(b2), .Cin(1'b0), .Sum(sum2), .Cout());
    CLA_5bit cla5_3(.A(a3), .B(b3), .Cin(1'b0), .Sum(sum3), .Cout());
    
    // 3) Sign-extend each 5-bit sum to 6 bits
    wire signed [5:0] s0, s1, s2, s3;
    assign s0 = {sum0[4], sum0};
    assign s1 = {sum1[4], sum1};
    assign s2 = {sum2[4], sum2};
    assign s3 = {sum3[4], sum3};
    
    // 4) Add pairs of 6-bit results using CLA_6bit
    wire [5:0] partial0, partial1;
    CLA_6bit cla6_0(.A(s0), .B(s1), .Cin(1'b0), .Sum(partial0), .Cout());
    CLA_6bit cla6_1(.A(s2), .B(s3), .Cin(1'b0), .Sum(partial1), .Cout());
    
    // 5) Sign-extend partial sums to 7 bits
    wire signed [6:0] p0, p1;
    assign p0 = {partial0[5], partial0};
    assign p1 = {partial1[5], partial1};
    
    // 6) Final addition using CLA_7bit to get a 7-bit result
    wire [6:0] final_sum;
    CLA_7bit cla7_0(.A(p0), .B(p1), .Cin(1'b0), .Sum(final_sum), .Cout());
    
    // 7) Sign-extend the 7-bit final sum to 16 bits
    assign R = {{9{final_sum[6]}}, final_sum};
endmodule