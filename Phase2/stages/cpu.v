module cpu(
    input clk,
    input rst_n,
    output hlt,
    output [15:0] pc
);


    // ADD hazard and forwarding unit here this will take care of pc_next logic
    // ADD Control Unit instantiation here!
    
                            ///////////
                            // FETCH //
                            ///////////

    // declare all wire connections for I inputs and outputs 
    
    // instantiate fetch stage
    fetch fetch_stage(
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



    // DX_pipe_out Signal Guide
    // 
    // [87:12] D_data (76 bits) - Data path signals
    //   [87:72] rr1_data     - Data from first source register (16 bits)
    //   [71:56] rr2_data     - Data from second source register (16 bits)
    //   [55:40] write_data   - Data to write to destination register (16 bits)
    //   [39:24] imm_value    - Immediate value from instruction (16 bits)
    //   [23:20] rr1_reg      - First source register number (4 bits)
    //   [19:16] rr2_reg      - Second source register number (4 bits)
    //   [15:12] wr_reg       - Destination register number (4 bits)
    //
    // [11:0] D_control (12 bits) - Control signals
    //   [11:8] ALUop        - ALU operation code (4 bits)
    //   [7]    ALUSrcMux    - Selects register (0) or immediate (1) for ALU B input
    //   [6]    MemtoRegMux  - Selects ALU result (0) or memory data (1) for register write
    //   [5]    PCSMux       - Selects PC+2 as write data for PCS instruction
    //   [4]    RegWrite     - Enable signal for register file writing
    //   [3]    MemWrite     - Enable signal for memory writing (SW)
    //   [2]    MemRead      - Enable signal for memory reading (LW)
    //   [1]    Flag_Enable  - Enable signal for updating ALU flags
    //   [0]    HaltMux      - Signal to halt processor execution


    decode decode_stage(
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
    pipeline_reg #(.WIDTH(72)) DX_pipeline(
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


    memory memory_stage(
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


    writeback writeback_stage(
        .clk(clk),
        .rst_n(rst_n),
        .M_in(MW_pipe_out),
        .HaltMux_W(hlt),   // triggers cpu hlt to go high
        .write_data_W(write_data_W),
        .wr_reg_W(wr_reg_W),
        .RegWrite_W(RegWrite_W)
    );
   
endmodule