module cpu(
    input clk,
    input rst_n,
    output hlt,
    output [15:0] pc
);

    
                            ///////////
                            // FETCH //
                            ///////////

    // declare all wire connections for I inputs and outputs 

    wire stall;                    // Stall signal for pipeline
    wire flush;                    // Flush signal for pipeline
    wire branch_taken;             // Branch condition satisfied
    wire [15:0] pc;                // Current PC from fetch stage
    wire [15:0] pc_plus_2;         // PC + 2 from fetch stage
    wire [15:0] instruction;       // Instruction from fetch stage
    wire [15:0] FD_pc_plus_2       // PC + 2 forwarded to D stage
    wire [15:0] FD_instruction     // Instruction forwarded to D stage
    wire [15:0] branch_target;     // Branch target address
    wire [31:0] FD_in, FD_out;          // Combined input and output to F/D register
    
    // concatanate signals for F/D register input
    // FD_in : {[31:16]FD_pc_plus_2, [15:0]FD_instruction}
    assign FD_in = {pc_plus_2, instruction};
    
    // instantiate fetch stage
    fetch F_stage(
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),
        .flush(flush),
        .halt(hlt),
        .branch_target(branch_target),
        .pc(pc),
        .pc_plus2(pc_plus_2),
        .instruction(instruction)
    );
    
    // F/D Pipeline Register (single register for all signals)
    // FD_out : {[31:16]FD_pc_plus_2 , [15:0]FD_instruction}
    pipeline_reg #(.WIDTH(32)) ID_data(
        .clk(clk),
        .rst_n(rst_n),
        .d(FD_in),
        .clr(flush),      
        .wren(~stall),    
        .q(FD_out)
    );


                            ////////////
                            // DECODE //
                            ////////////



    // assign the register outputs to inputs for decode stage
    assign FD_pc_plus_2 = FD_out[31:16];    // PC + 2 forwarded to D stage
    assign FD_instruction = FD_out[15:0];   // Instruction forwarded to D stage

    decode decode_stage(
    .clk(clk),
    .rst_n(rst_n),
    .FD_pc_plus_2(FD_pc_plus_2),
    .FD_instruction(FD_instruction),
    .flush(flush),
    .halt(hlt),
    .branch_target(branch_target),
    .D_rr1_data(D_rr1_data),
    .D_rr2_data(D_rr2_data),
    .D_write_data(D_write_data),
    .D_imm_value(D_imm_value),
    .D_rr1_reg(D_rr1_reg),
    .D_rr2_reg(D_rr2_reg),
    .D_wr_reg(D_wr_reg),
    .D_ALUop(D_ALUop),
    .D_ALUSrcMux(D_ALUSrcMux),
    .D_MemtoRegMux(D_MemtoRegMux),
    .D_PCSMux(D_PCSMux),
    .D_RegWrite(D_RegWrite),
    .D_MemWrite(D_MemWrite),
    .D_MemRead(D_MemRead),
    .D_Flag_Enable(D_Flag_Enable)
    );


    // D/X Pipeline Register one register for all data
    pipeline_reg #(.WIDTH(?)) DX_data(
        .clk(clk),
        .rst_n(rst_n),
        .d(FD_in),
        .clr(flush),      
        .wren(~stall),    
        .q(FD_out)
    );

    // D/X Pipeline Register one register for all control
    pipeline_reg #(.WIDTH(?)) DX_control(
        .clk(clk),
        .rst_n(rst_n),
        .d(FD_in),
        .clr(flush),      
        .wren(~stall),    
        .q(FD_out)
    );


                            /////////////
                            // EXECUTE //
                            /////////////

    execute execute_stage();

    // X/M Pipeline Register one register for all control
    pipeline_reg #(.WIDTH(?)) XM(
        .clk(clk),
        .rst_n(rst_n),
        .d(FD_in),
        .clr(flush),      
        .wren(~stall),    
        .q(FD_out)
    );

   
endmodule