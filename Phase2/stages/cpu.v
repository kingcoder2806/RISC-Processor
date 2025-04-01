module cpu(
    input clk,
    input rst_n,
    output hlt,
    output [15:0] pc
);


    // ADD hazard_forwarding unit here!
    // ADD Flag registers here for branch resolution!
    // ADD Control Unit instantiation here!
    
                            ///////////
                            // FETCH //
                            ///////////

    // declare all wire connections for I inputs and outputs 

    // internal signals used for branch resultion in Decode that need to be sent to Fetch
    wire flush;                    // Flush signal for pipeline
    wire hlt;
    
    // instantiate fetch stage
    fetch F_stage(
        .clk(clk),
        .rst_n(rst_n),
        .stall(stall),                  // comes from hazard detection in decode
        .flush(flush),                  // comes from branch resolution in decode
        .halt(hlt),                     // comes from Writeback stage
        .branch_target(branch_target),  // input from decode of branch addr
        .pc(pc),                        // output to pc of cpu
        .F_out(FD_pipe_in)            //output of inst and pc+2
    );
    
    // F/D Pipeline Register (single register for all signals)
    // FD_out : {[31:16]FD_pc_plus_2 , [15:0]FD_instruction}
    pipeline_reg #(.WIDTH(32)) ID_data(
        .clk(clk),
        .rst_n(rst_n),s
        .d(FD_pipe_in),
        .clr(flush),      
        .wren(~stall),    
        .q(FD_pipe_out)
    );


                            ////////////
                            // DECODE //
                            ////////////


    decode decode_stage(
    .clk(clk),
    .rst_n(rst_n),
    .D_in(FD_pipe_out),
    .flush(flush),
    .stall(stall),
    .branch_target(branch_target),
    .D_out(DX_pipe_in)
    );


    // D/X Pipeline Register one register for all data
    pipeline_reg #(.WIDTH(?)) DX_data(
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

    execute execute_stage(
        .X_in(DX_pipe_out),
    );

    // X/M Pipeline Register one register for all control
    pipeline_reg #(.WIDTH(?)) XM(
        .clk(clk),
        .rst_n(rst_n),
        .d(),
        .clr(flush),      
        .wren(~stall),    
        .q()
    );

   
endmodule