module cpu(
    input clk,
    input rst_n,
    output hlt,
    output [15:0] pc
);

    //declare internal control / data signals
    wire stall, flush, halt_PC;
    wire [15:0] branch_target;
    wire [15:0] write_data_W;
    wire [3:0] wr_reg_W;
    wire RegWrite_W;

    // declare all internal pipeline connections
    // FD Pipeline: 32 bits 
    wire [31:0] FD_pipe_in, FD_pipe_out;

    // DX Pipeline: 71 bits
    wire [70:0] DX_pipe_in, DX_pipe_out;

    // XM Pipeline: 41 bits
    wire [40:0] XM_pipe_in, XM_pipe_out;

    // MW Pipeline: 39 bits
    wire [38:0] MW_pipe_in, MW_pipe_out;


    // ADD hazard and forwarding unit here this will take care of pc_next logic for stalls and data forwarding

    // FOR TESTING //
    assign stall = 0;
    // FOR TESTING //
    
                            ///////////
                            // FETCH //
                            ///////////
    
    // instantiate fetch stage
    fetch fetch(
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),                  // comes from hazard detection in decode
        .flush(flush),                  // comes from branch resolution in decode
        .halt_PC(halt_PC),                     // comes from halt detection in decode to stop PC increment
        .branch_target(branch_target),  // input from decode of branch addr
        .pc(pc),                        // output to pc of cpu
        .F_out(FD_pipe_in)            //output of inst and pc+2
    );
    
    // F/D Pipeline Register (single register for all signals)
    // FD_out : {[31:16]FD_pc_plus_2 , [15:0]FD_instruction}
    pipeline_reg #(.WIDTH(32)) ID_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .d(FD_pipe_in),
        .clr(flush),      
        .wren(~stall),    
        .q(FD_pipe_out)
    );


                            ////////////
                            // DECODE //
                            ////////////


    decode decode(
    .clk(clk),
    .rst_n(rst_n),
    .D_in(FD_pipe_out),
    .flush(flush),
    .halt_PC(halt_PC),              // halt to stop PC increment but not cpu in simulation
    .branch_target(branch_target),
    .D_out(DX_pipe_in),
    .write_data_W(write_data_W),
    .wr_reg_W(wr_reg_W),
    .RegWrite_W(RegWrite_W)
    );


    // D/X Pipeline Register one register for all values
    pipeline_reg #(.WIDTH(71)) DX_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .d(DX_pipe_in),
        .clr(flush),      
        .wren(~stall),    
        .q(DX_pipe_out)
    );


                            /////////////
                            // EXECUTE //
                            /////////////

    execute execute(
        .clk(clk),
        .rst_n(rst_n),
        .X_in(DX_pipe_out),
        .X_out(XM_pipe_in)
    );

    // X/M Pipeline Register one register for all values
    pipeline_reg #(.WIDTH(41)) XM_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .d(XM_pipe_in),
        .clr(flush),      
        .wren(~stall),    
        .q(XM_pipe_out)
    );

                            ////////////
                            // MEMORY //
                            ////////////


    memory memory(
        .clk(clk),
        .rst_n(rst_n),
        .M_in(XM_pipe_out),
        .M_out(MW_pipe_in)
    );

    // M/W Pipeline Register one register for all values
    pipeline_reg #(.WIDTH(39)) MW_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .d(MW_pipe_in),
        .clr(flush),      
        .wren(~stall),    
        .q(MW_pipe_out)
    );


                            ///////////////
                            // WRITEBACK //
                            ///////////////


    writeback writeback(
        .W_in(MW_pipe_out),
        .HaltMux_W(hlt),   // triggers cpu hlt to go high
        .write_data_W(write_data_W),
        .wr_reg_W(wr_reg_W),
        .RegWrite_W(RegWrite_W)
    );
   
endmodule