module ReadDecoder_4_16(
    input [3:0] RegId,
    output [15:0] Wordline
);
    // assigning the correct bit of the wordline (one-hot) based on RegId
    assign Wordline[0] = (RegId == 4'b0000);
    assign Wordline[1] = (RegId == 4'b0001);
    assign Wordline[2] = (RegId == 4'b0010);
    assign Wordline[3] = (RegId == 4'b0011);
    assign Wordline[4] = (RegId == 4'b0100);
    assign Wordline[5] = (RegId == 4'b0101);
    assign Wordline[6] = (RegId == 4'b0110);
    assign Wordline[7] = (RegId == 4'b0111);
    assign Wordline[8] = (RegId == 4'b1000);
    assign Wordline[9] = (RegId == 4'b1001);
    assign Wordline[10] = (RegId == 4'b1010);
    assign Wordline[11] = (RegId == 4'b1011);
    assign Wordline[12] = (RegId == 4'b1100);
    assign Wordline[13] = (RegId == 4'b1101);
    assign Wordline[14] = (RegId == 4'b1110);
    assign Wordline[15] = (RegId == 4'b1111);
    
endmodule