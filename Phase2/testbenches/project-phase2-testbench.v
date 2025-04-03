`timescale 1ns/100ps
module cpu_ptb();
  
   // Top-level signals
   wire [15:0] PC;
   wire        Halt;
   
   // Additional internal signals from the DUT
   // Fetch Stage
   wire [15:0] Inst;
   wire [15:0] pc_plus_2;
   
   // Decode Stage - Data signals
   wire [15:0] ReadData1_D;
   wire [15:0] ReadData2_D;
   wire [15:0] ImmValue_D;
   wire [3:0]  ReadReg1_D;
   wire [3:0]  ReadReg2_D;
   wire [15:0] BranchTarget;
   // Decode Stage - Control signals
   wire        RR1Mux_D;
   wire        RR2Mux_D;
   wire [1:0]  ImmMux_D;
   wire        ALUSrcMux_D;
   wire        MemtoRegMux_D;
   wire        PCSMux_D;
   wire        HaltMux_D;
   wire        BranchRegMux_D;
   wire        BranchMux_D;
   wire        RegWrite_D;
   wire        MemRead_D;
   wire        MemWrite_D;
   wire        Flag_Enable_D;
   wire [3:0]  ALUop_D;
   wire [3:0]  WriteRegister_D;
   wire        BranchTaken;
   wire [2:0]  Flags;
   
   // Execute Stage - Data signals
   wire [15:0] rr1_data_X;
   wire [15:0] rr2_data_X;
   wire [15:0] imm_value_X;
   wire [3:0]  rr1_reg_X;
   wire [3:0]  rr2_reg_X;
   wire [3:0]  wr_reg_X;
   // Execute Stage - Control signals
   wire [3:0]  ALUop_X;
   wire        ALUSrcMux_X;
   wire        MemtoRegMux_X;
   wire        RegWrite_X;
   wire        MemWrite_X;
   wire        MemRead_X;
   wire        Flag_Enable_X;
   wire        HaltMux_X;
   
   // Memory Stage - Data signals
   wire [15:0] ALUResult_M;
   wire [15:0] MemoryOut_M;
   wire [3:0]  WriteRegister_M;
   // Memory Stage - Control signals
   wire        HaltMux_M;
   wire        RegWrite_M;
   wire        MemtoRegMux_M;
   
   // Writeback Stage - Data signals
   wire [15:0] WriteData_W;
   wire [3:0]  WriteRegister_W;
   // Writeback Stage - Control signals
   wire        HaltMux_W;
   wire        RegWrite_W;
   
   // Add missing wire declarations
   wire [15:0] MemAddress_D;
   wire [15:0] MemData_D;
   wire [15:0] WriteData_D;
   
   // ------------------------------
   // Counters and File Handles for Logging
   // ------------------------------
   integer inst_count, cycle_count;
   integer trace_file, sim_log_file, debug_file;
   
   reg clk;    // Clock input
   reg rst_n;  // Active low reset

   // Instantiate your processor DUT
   cpu DUT(
       .clk(clk),
       .rst_n(rst_n),
       .pc(PC),
       .hlt(Halt)
   );

   // Setup
   initial begin
      $display("Hello world...simulation starting");
      $display("See verilogsim.log, verilogsim.trace, and verilogsim.debug for output");
      inst_count = 0;
      trace_file = $fopen("verilogsim.trace");
      sim_log_file = $fopen("verilogsim.log");
      debug_file = $fopen("verilogsim.debug");
   end

   // Clock and Reset
   initial begin
      $dumpvars;
      cycle_count = 0;
      rst_n = 0;  // Initial reset state
      clk = 1;
      #201 rst_n = 1;  // Release reset after two clock periods
   end

   always #50 clk = ~clk; // Clock period is 100 time units

   always @(posedge clk) begin
     cycle_count = cycle_count + 1;
     if (cycle_count > 100000) begin
        $display("hmm....more than 100000 cycles of simulation...error?\n");
        $finish;
     end
   end

   // ------------------------------
   // Logging (Tracking Output File) Using _D Signals
   // ------------------------------
   always @(posedge clk) begin
      if (rst_n) begin
         if (Halt || RegWrite_D || MemWrite_D)
            inst_count = inst_count + 1;

         $fdisplay(sim_log_file, "SIMLOG:: Cycle %d PC: %8x I: %8x R: %d %3d %8x M: %d %d %8x %8x",
                  cycle_count,
                  PC,
                  Inst,         // decode-stage instruction alias
                  RegWrite_D,     // decode-stage RegWrite
                  WriteRegister_D,// decode-stage write register
                  WriteData_D,    // decode-stage write data alias
                  MemRead_D,      // decode-stage memory read
                  MemWrite_D,     // decode-stage memory write
                  MemAddress_D,   // dummy decode-stage memory address
                  MemData_D);     // dummy decode-stage memory data
                  
         $fdisplay(debug_file, "DEBUG:: Cycle %d\n  PC: %8x Instr: %8x",
                  cycle_count, PC, Inst);
         $fdisplay(debug_file, "  RegSel: RR1=%d RR2=%d WR=%d  RegData: RD1=%8x RD2=%8x WD=%8x RegWrite=%d",
                  ReadReg1_D, ReadReg2_D, WriteRegister_D, ReadData1_D, ReadData2_D, WriteData_D, RegWrite_D);
         $fdisplay(debug_file, "  ALU: Result=%8x Flags=%b  Imm=%8x",
                  ImmValue_D, Flags, ImmValue_D);
         $fdisplay(debug_file, "  Mem: Read=%d Write=%d Addr: %8x Data: %8x",
                  MemRead_D, MemWrite_D, MemAddress_D, MemData_D);
         $fdisplay(debug_file, "  Ctrl: RR1Mux=%d RR2Mux=%d ImmMux=%d ALUSrcMux=%d MemtoRegMux=%d",
                  RR1Mux_D, RR2Mux_D, ImmMux_D, ALUSrcMux_D, MemtoRegMux_D);
         $fdisplay(debug_file, "        PCSMux=%d HaltMux=%d BranchRegMux=%d BranchMux=%d BranchTaken=%d\n",
                  PCSMux_D, HaltMux_D, BranchRegMux_D, BranchMux_D, BranchTaken);
                  
         if (RegWrite_D) begin
            if (MemRead_D) begin
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x REG: %d VALUE: 0x%04x ADDR: 0x%04x",
                         (inst_count-1),
                         PC,
                         WriteRegister_D,
                         WriteData_D,
                         MemAddress_D);
            end else begin
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x REG: %d VALUE: 0x%04x",
                         (inst_count-1),
                         PC,
                         WriteRegister_D,
                         WriteData_D);
            end
         end else if (Halt) begin
            $fdisplay(sim_log_file, "SIMLOG:: Processor halted\n");
            $fdisplay(sim_log_file, "SIMLOG:: sim_cycles %d\n", cycle_count);
            $fdisplay(sim_log_file, "SIMLOG:: inst_count %d\n", inst_count);
            $fclose(trace_file);
            $fclose(sim_log_file);
            $fclose(debug_file);
            #5;
            $finish;
         end else if (MemWrite_D) begin
            $fdisplay(trace_file, "INUM: %8d PC: 0x%04x ADDR: 0x%04x VALUE: 0x%04x",
                         (inst_count-1),
                         PC,
                         MemAddress_D,
                         MemData_D);
         end else begin
            inst_count = inst_count + 1;
            $fdisplay(trace_file, "INUM: %8d PC: 0x%04x",
                         (inst_count-1),
                         PC);
         end 
      end
   end

   // ------------------------------
   // Hierarchical Signal Assignments from DUT
   // ------------------------------
   
   // Fetch Stage
   assign Inst      = DUT.fetch.instruction;  
   assign pc_plus_2 = DUT.fetch.pc_plus_2;

   // Decode Stage - Data signals
   assign ReadData1_D   = DUT.decode.rr1_data_D;
   assign ReadData2_D   = DUT.decode.rr2_data_D;
   assign ImmValue_D    = DUT.decode.imm_value_D;
   assign ReadReg1_D    = DUT.decode.rr1_reg_D;
   assign ReadReg2_D    = DUT.decode.rr2_reg_D;
   assign BranchTarget  = DUT.decode.branch_target;
   
   // Decode Stage - Control signals
   assign RR1Mux_D      = DUT.decode.RR1Mux_D;
   assign RR2Mux_D      = DUT.decode.RR2Mux_D;
   assign ImmMux_D      = DUT.decode.ImmMux_D;
   assign ALUSrcMux_D   = DUT.decode.ALUSrcMux_D;
   assign MemtoRegMux_D = DUT.decode.MemtoRegMux_D;
   assign PCSMux_D      = DUT.decode.PCSMux_D;
   assign HaltMux_D     = DUT.decode.HaltMux_D;
   assign BranchRegMux_D= DUT.decode.BranchRegMux_D;
   assign BranchMux_D   = DUT.decode.BranchMux_D;
   assign RegWrite_D    = DUT.decode.RegWrite_D;
   assign MemRead_D     = DUT.decode.MemRead_D;
   assign MemWrite_D    = DUT.decode.MemWrite_D;
   assign Flag_Enable_D = DUT.decode.Flag_Enable_D;
   assign ALUop_D       = DUT.decode.ALUop_D;
   assign WriteRegister_D = DUT.decode.wr_reg_D;
   assign BranchTaken   = DUT.decode.branch_taken;


   // Execute Stage - Data signals
   assign rr1_data_X    = DUT.execute.rr1_data_X;
   assign MemData_D    = DUT.execute.rr2_data_X;
   assign imm_value_X   = DUT.execute.imm_value_X;
   assign rr1_reg_X     = DUT.execute.rr1_reg_X;
   assign rr2_reg_X     = DUT.execute.rr2_reg_X;
   assign wr_reg_X      = DUT.execute.wr_reg_X;
   
   // Execute Stage - Control signals
   assign ALUop_X       = DUT.execute.ALUop_X;
   assign ALUSrcMux_X   = DUT.execute.ALUSrcMux_X;
   assign MemtoRegMux_X = DUT.execute.MemtoRegMux_X;
   assign RegWrite_X    = DUT.execute.RegWrite_X;
   assign MemWrite_X    = DUT.execute.MemWrite_X;
   assign MemRead_X     = DUT.execute.MemRead_X;
   assign Flag_Enable_X = DUT.execute.Flag_Enable_X;
   assign HaltMux_X     = DUT.execute.HaltMux_X;

   // Memory Stage - Data signals
   assign MemAddress_D    = DUT.memory.alu_result;
   assign MemoryOut_M      = DUT.memory.mem_data_out;
   assign WriteRegister_M  = DUT.memory.wr_reg_M;
   
   // Memory Stage - Control signals
   assign HaltMux_M        = DUT.memory.HaltMux_M;
   assign RegWrite_M       = DUT.memory.RegWrite_M;
   assign MemtoRegMux_M    = DUT.memory.MemtoRegMux_M;

   // Writeback Stage - Data signals
   assign WriteData_D      = DUT.writeback.write_data_W;
   assign WriteRegister_W  = DUT.writeback.wr_reg_W;
   
   // Writeback Stage - Control signals
   assign HaltMux_W        = DUT.writeback.HaltMux_W;
   assign RegWrite_W       = DUT.writeback.RegWrite_W;
   

endmodule