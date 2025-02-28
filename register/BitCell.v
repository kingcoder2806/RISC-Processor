module BitCell(
    input clk,
    input rst,
    input D,
    input WriteEnable,
    input ReadEnable1,
    input ReadEnable2,
    inout Bitline1,
    inout Bitline2
);
    wire q_out;
    
    // d flip-flop instance 
    dff dff_inst(
        .q(q_out),
        .d(D),
        .wen(WriteEnable),
        .clk(clk),
        .rst(rst)
    );
    
    // tri-state buffers for read ports
    assign Bitline1 = ReadEnable1 ? q_out : 1'bz;
    assign Bitline2 = ReadEnable2 ? q_out : 1'bz;
endmodule