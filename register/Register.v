module Register(
    input clk,
    input rst,
    input [15:0] D,
    input WriteReg,
    input ReadEnable1,
    input ReadEnable2,
    inout [15:0] Bitline1,
    inout [15:0] Bitline2
);
    // create 16 BitCells so we have 16 bits per reg
    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : bit_cells
            BitCell bit_cell_inst(
                .clk(clk),
                .rst(rst),
                .D(D[i]),
                .WriteEnable(WriteReg),
                .ReadEnable1(ReadEnable1),
                .ReadEnable2(ReadEnable2),
                .Bitline1(Bitline1[i]),
                .Bitline2(Bitline2[i])
            );
        end
    endgenerate
endmodule