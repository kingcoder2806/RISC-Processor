`timescale 1ns/100ps
module cpu_ptb_chance();
  
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
   wire [15:0] MemDataOut_M, MemDataIn_M;
   wire [3:0]  WriteRegister_M;
   // Memory Stage - Control signals
   wire        HaltMux_M;
   wire        RegWrite_M;
   wire        MemtoRegMux_M;
   wire        MemRead_M;
   wire        MemWrite_M;

   
   // Writeback Stage - Data signals
   wire [15:0] WriteData_W;
   wire [3:0]  WriteRegister_W;
   // Writeback Stage - Control signals
   wire        HaltMux_W;
   wire        RegWrite_W;
   
   // Add missing wire declarations
   wire [15:0] MemAddress_M;
   wire [15:0] MemData_M;
   
   // ------------------------------
   // Counters and File Handles for Logging
   // ------------------------------
   integer inst_count, cycle_count;
   integer trace_file, sim_log_file;
   
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
      trace_file = $fopen("/Users/Patron/Documents/ECE552/ECE552_Project/Phase2/debug/verilogsim.trace");
      sim_log_file = $fopen("/Users/Patron/Documents/ECE552/ECE552_Project/Phase2/debug/verilogsim.log");
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
        $stop();
     end
   end

   /* Stats and File Outputs */
   always @(posedge clk) begin
      if (rst_n) begin
         // Increment inst_count when there is a writeback or memory write (or a halt)
         if (Halt || RegWrite_D || MemWrite_D)
            inst_count = inst_count + 1;

         // Standard simulation log output including PC and instruction details
         $fdisplay(sim_log_file, "SIMLOG:: Cycle %d PC: 0x%04x I: 0x%04x R: %d %3d %8x M: %d %d %8x %8x",
                  cycle_count,
                  PC,
                  Inst,
                  RegWrite_W,
                  WriteRegister_W,
                  WriteData_W,
                  MemRead_M,
                  MemWrite_M,
                  MemAddress_M,
                  MemDataIn_M,
                  MemDataOut_M);
                  
         // Trace file output now uses a chain of conditions to always show PC
         if (RegWrite_W) begin
            // For a register write, check if it is a load (MemRead_M) to include the memory address
            if (MemRead_M) begin
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x REG: %d VALUE: 0x%04x ADDR: 0x%04x",
                         (inst_count-1),
                         PC,
                         WriteRegister_W,
                         WriteData_W,
                         MemAddress_M);
            end else begin
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x REG: %d VALUE: 0x%04x",
                         (inst_count-1),
                         PC,
                         WriteRegister_W,
                         WriteData_W);
            end
         end else if (Halt) begin
            // If halted, output halt info and close files
            $fdisplay(sim_log_file, "SIMLOG:: Processor halted");
            $fdisplay(sim_log_file, "SIMLOG:: sim_cycles %d", cycle_count);
            $fdisplay(sim_log_file, "SIMLOG:: inst_count %d", inst_count);
            $fdisplay(trace_file, "INUM: %8d PC: 0x%04x", (inst_count-1), PC);
            $fclose(trace_file);
            $fclose(sim_log_file);
            #5;
            $stop();
         end else begin
            // For non-writeback and non-halt cases, check for a memory store or a branch/NOP
            if (MemWrite_M) begin
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x ADDR: 0x%04x VALUE: 0x%04x",
                         (inst_count-1),
                         PC,
                         MemAddress_M,
                         MemDataIn_M);
            end else begin
               // For conditional branches or NOPs, increment inst_count and log PC
               inst_count = inst_count + 1;
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x",
                         (inst_count-1),
                         PC);
            end
         end
      end
   end

   // Debug signals and outfile declaration
   
   // Fetch Stage
   assign Inst      = DUT.fetch.instruction;  // in outfile
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
   assign MemAddress_M     = DUT.memory.alu_result;      // in outfile
   assign WriteRegister_M  = DUT.memory.wr_reg_M;
   assign MemDataIn_M      = DUT.memory.rr2_data_M;        // in outfile
   assign MemDataOut_M     = MemRead_M ? DUT.memory.mem_data_out : 16'h0000;   // in outfile
   
   // Memory Stage - Control signals
   assign HaltMux_M        = DUT.memory.HaltMux_M;
   assign RegWrite_M       = DUT.memory.RegWrite_M;
   assign MemtoRegMux_M    = DUT.memory.MemtoRegMux_M;
   assign MemRead_M        = DUT.memory.MemRead_M;       // in outfile 
   assign MemWrite_M       = DUT.memory.MemWrite_M;      // in outfile

   // Writeback Stage - Data signals
   assign WriteData_W      = DUT.writeback.write_data_W; // in outfile
   assign WriteRegister_W  = DUT.writeback.wr_reg_W;     // in outfile
   
   // Writeback Stage - Control signals
   assign HaltMux_W        = DUT.writeback.HaltMux_W;
   assign RegWrite_W       = DUT.writeback.RegWrite_W;   // in outfile 
   
endmodule
