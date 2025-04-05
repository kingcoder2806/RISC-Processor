module cpu(
    input clk,
    input rst_n,
    output hlt,
    output [15:0] pc
);

    //declare internal control / data signals
    wire flush;
    wire [15:0] branch_target;
    wire [15:0] write_data_W;
    wire [3:0] wr_reg_W;
    wire RegWrite_W;

    // declare all internal pipeline connections
    // FD Pipeline: 32 bits 
    wire [31:0] FD_pipe_in, FD_pipe_out;

    // DX Pipeline: 71 bits
    wire [70:0] DX_pipe_in, DX_pipe_out;

    // XM Pipeline: 49 bits
    wire [48:0] XM_pipe_in, XM_pipe_out;

    // MW Pipeline: 39 bits
    wire [38:0] MW_pipe_in, MW_pipe_out;



    // hazard_forward unit will take care of pc_next logic for stalls and data forwarding for ALU and branch
    // inputs and data intilization for forwarding 

    wire [1:0] fwdMuxSel_A, fwdMuxSel_B;
    wire [1:0] forwardD;
    
     hazard_forward hazard (
         .reg_wr_enX(XM_pipe_in[4]),       // RegWrite enable in Execute
         .reg_wr_enM(MW_pipe_in[1]),       // Regwrite enable in Memory
         .reg_wr_enW(RegWrite_W),     // From WB output

         .write_regX(XM_pipe_in[8:5]),     // Destination reg for write data in X 
         .write_regM(MW_pipe_in[6:3]),     // Destination reg for write data in M
         .write_regW(wr_reg_W),       // from WB output for reg value

         .rr1_reg_D(DX_pipe_in[22:19]),       // First source register in decode stage
         .rr2_reg_D(DX_pipe_in[18:15]),       // Second source register in decode stage

         .rr1_reg_X(XM_pipe_in[48:45]),       // First source register in execute stage
         .rr2_reg_X(XM_pipe_in[44:41]),       // Second source register in execute stage

         .mem_to_regX(XM_pipe_in[3]),
         .mem_to_regM(MW_pipe_in[0]),

         .stallFD(stallFD),             // output to stall pc
         .forwardD(forwardD),           // Encodes whether the branch source (rr1_reg_D) should be forwarded from EX, MEM, or WB (or not at all)
         .forward_A_selX(fwdMuxSel_A),  // These signals determine which stage’s result should be used for the ALU’s operands in the Execute stage.
         .forward_B_selX(fwdMuxSel_B)   // ''
    );
    
                            ///////////
                            // FETCH //
                            ///////////
    
    // instantiate fetch stage
    fetch fetch(
        .clk(clk),
        .rst_n(rst_n),
        .stall(stallFD),               // comes from hazard detection unit, PC = PC
        .flush(flush),                  // comes from branch_taken in decode
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
        .clr(flush),        // clear reg if branch taken, signal from decode
        .wren(~stallFD),    // stall if load in EX or MEM stage feeds a value needed by the decode stage
        .q(FD_pipe_out)
    );


                            ////////////
                            // DECODE //
                            ////////////

    // forwarding logic for branch in decode
    // need to instantialte alu results here
    wire [15:0] branch_fwrd, alu_result_X, alu_result_M;
    assign alu_result_X = XM_pipe_in[40:25];
    assign alu_result_M = MW_pipe_in[38:23];
    assign branch_fwrd =
                     forwardD == 2'b11 ? write_data_W : // will use write_data_W outputfrom Writeback stage
                     forwardD == 2'b01 ? alu_result_X : // will use alu_result from Execute stage
                     forwardD == 2'b10 ? alu_result_M : // will use alu_result from Memory stage
                     16'hXXXX;                          // will use src_data_1 internaly from reg file in Decode 


    decode decode(
    .clk(clk),
    .rst_n(rst_n),
    .D_in(FD_pipe_out),
    .flush(flush),          // high if branch taken, flushes IF_ID reg and sets PC to branch_target 
    .branch_target(branch_target),
    .D_out(DX_pipe_in),
    .write_data_W(write_data_W),
    .wr_reg_W(wr_reg_W),
    .RegWrite_W(RegWrite_W),
    .forwardD(forwardD),     // selection signal to decode if forward branch target or internal branch target in decode
    .branch_fwrd(branch_fwrd)   // forwarded branch target data
    );  


    // D/X Pipeline Register one register for all values
    pipeline_reg #(.WIDTH(71)) DX_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .d(DX_pipe_in),
        .clr(1'b0),       // no need to clear
        .wren(1'b1),      // no need to stall here
        .q(DX_pipe_out)
    );


                            /////////////
                            // EXECUTE //
                            /////////////

    // forwarding for ALU's inputs in Execute
    wire [15:0] fwd_dataMux_A, fwd_dataMux_B;
    assign fwd_dataMux_A = 
                fwdMuxSel_A == 2'b10 ? write_data_W : // will use write_data_W outputfrom Writeback stage
                fwdMuxSel_A == 2'b01 ? alu_result_M :  // will use alu_result from Memory stage
                16'hXXXX;

    assign fwd_dataMux_B = 
                fwdMuxSel_B == 2'b10 ? write_data_W : // will use write_data_W outputfrom Writeback stage
                fwdMuxSel_B == 2'b01 ? alu_result_M :  // will use alu_result from Memory stage
                16'hXXXX;


    execute execute(
        .clk(clk),
        .rst_n(rst_n),
        .X_in(DX_pipe_out),
        .X_out(XM_pipe_in),
        .fwdMuxSel_A(fwdMuxSel_A),
        .fwdMuxSel_B(fwdMuxSel_B),
        .fwd_dataMux_A(fwd_dataMux_A),
        .fwd_dataMux_B(fwd_dataMux_B)
    );

    // X/M Pipeline Register one register for all values
    pipeline_reg #(.WIDTH(49)) XM_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .d(XM_pipe_in),
        .clr(1'b0),    // no need to clear
        .wren(1'b1),   // always enabled, no need to stall  
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
        .clr(1'b0),      // no need to clear 
        .wren(1'b1),    // always enabled, no need to stall  
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