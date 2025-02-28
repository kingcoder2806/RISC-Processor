module RegisterFile(
    input clk, rst,                     
    input [3:0] SrcReg1, SrcReg2,      
    input [3:0] DstReg,                
    input WriteReg,                     
    input [15:0] DstData,              
    inout [15:0] SrcData1, SrcData2    
);

    wire [15:0] read_wordline1, read_wordline2, write_wordline;
    wire [15:0] read_enable1, read_enable2;  // Intermediate signals
    wire write_read_1, write_read_2;

    // convert 4-bit register numbers to 16-bit one-hot signals (read 1)
    ReadDecoder_4_16 read_decoder1(
        .RegId(SrcReg1),
        .Wordline(read_wordline1)   // Connect directly to decoder output
    );

    // convert 4-bit register numbers to 16-bit one-hot signals (read 2) 
    ReadDecoder_4_16 read_decoder2(
        .RegId(SrcReg2),
        .Wordline(read_wordline2)   // Connect directly to decoder output
    );

    // Create the gated read enables
    assign read_enable1 = read_wordline1 & {16{~write_read_1}};
    assign read_enable2 = read_wordline2 & {16{~write_read_2}};

    // Write decoder remains the same
    WriteDecoder_4_16 write_decoder(
        .RegId(DstReg),
        .WriteReg(WriteReg),
        .Wordline(write_wordline)
    );

    // Register array now uses the gated read enables
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : registers
            Register register_inst(
                .clk(clk),
                .rst(rst),
                .D(DstData),
                .WriteReg(write_wordline[i]),
                .ReadEnable1(read_enable1[i]),  // Use gated signal
                .ReadEnable2(read_enable2[i]),  // Use gated signal
                .Bitline1(SrcData1),
                .Bitline2(SrcData2)
            );
        end
    endgenerate

    assign write_read_1 = WriteReg && (DstReg == SrcReg1);
    assign write_read_2 = WriteReg && (DstReg == SrcReg2);

    // bypass logic
    assign SrcData1 = write_read_1 ? DstData : 16'bzzzz_zzzz_zzzz_zzzz;
    assign SrcData2 = write_read_2 ? DstData : 16'bzzzz_zzzz_zzzz_zzzz;

endmodule