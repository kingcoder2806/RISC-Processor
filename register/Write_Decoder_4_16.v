module WriteDecoder_4_16(
    input [3:0] RegId,
    input WriteReg,
    output [15:0] Wordline
);

    // get 16-bit wordline from ReadDecoder
    wire [15:0] decoded;
    ReadDecoder_4_16 Decoder(.RegId(RegId), .Wordline(decoded));
    
    // set wordline output by & with decoding signal to get onehot write reg output
    assign Wordline = decoded & {16{WriteReg}};
endmodule