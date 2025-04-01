// ADD FORWARDING UNIT HERE!!!!

module execute();

    // todo need to pipe ALUSRCMux here
    wire [15:0] alu_input_b;
    assign alu_input_b = ALUSrcMux ? imm_value : rr2_data;
   

    wire [2:0] alu_flags;
    alu ALU(
        .a(rr1_data),
        .b(alu_input_b),
        .op(instruction[15:12]),  // Using opcode as ALU operation
        .result(alu_result),
        .flags(flags)             // N, Z, V [N,Z,V]
    );

    dff idff0(.d(flags[2]), .q(flags_out[2]), .wen(flag_enable), .clk(clk), .rst(~rst_n)); // N flop
    dff idff1(.d(flags[1]), .q(flags_out[1]), .wen(flag_enable), .clk(clk), .rst(~rst_n)); // Z flop
    dff idff2(.d(flags[0]), .q(flags_out[0]), .wen(flag_enable), .clk(clk), .rst(~rst_n)); // V flop







endmodule
