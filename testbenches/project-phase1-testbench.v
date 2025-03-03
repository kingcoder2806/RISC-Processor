`timescale 1ns/100ps
module cpu_tb();
  
   wire [15:0] PC;
   wire [15:0] Inst;           // Instruction fetched from memory
   wire        RegWrite;       // Whether register file is being written to
   wire [3:0]  WriteRegister;  // What register is written
   wire [15:0] WriteData;      // Data
   wire        MemWrite;       // Memory write control
   wire        MemRead;
   wire [15:0] MemAddress;
   wire [15:0] MemData;

   // Additional signals to monitor
   wire [3:0]  ReadReg1;       // First read register selector
   wire [3:0]  ReadReg2;       // Second read register selector
   wire [15:0] ReadData1;      // Data from first read register
   wire [15:0] ReadData2;      // Data from second read register
   wire [15:0] ImmValue;       // Immediate value
   wire [15:0] ALUResult;      // Result from ALU
   wire [2:0]  Flags;          // CPU flags (Z, V, N)
   wire        BranchTaken;    // Whether branch was taken

   // Control signals
   wire        RR1Mux;
   wire        RR2Mux;
   wire [1:0]  ImmMux;
   wire        ALUSrcMux;
   wire        MemtoRegMux;
   wire        PCSMux;
   wire        HaltMux;
   wire        BranchRegMux;
   wire        BranchMux;

   wire        Halt;           // Halt signal
        
   integer     inst_count;
   integer     cycle_count;

   integer     trace_file;
   integer     sim_log_file;
   integer     debug_file;     // Additional file for detailed debug info

   reg clk;    // Clock input
   reg rst_n;  // (Active low) Reset input

   // Instantiate your processor
   cpu DUT(.clk(clk), .rst_n(rst_n), .pc(PC), .hlt(Halt));

   // Setup
   initial begin
      $display("Hello world...simulation starting");
      $display("See verilogsim.log and verilogsim.trace for output");
      $display("See verilogsim.debug for detailed signal information");
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
      #201 rst_n = 1; // delay until slightly after two clock periods
    end

    always #50 begin   // delay 1/2 clock period each time
      clk = ~clk;
    end
	
    always @(posedge clk) begin
    	cycle_count = cycle_count + 1;
	if (cycle_count > 100000) begin
		$display("hmm....more than 100000 cycles of simulation...error?\n");
		$stop();
	end
    end

   // Stats
   always @ (posedge clk) begin
      if (rst_n) begin
         if (Halt || RegWrite || MemWrite) begin
            inst_count = inst_count + 1;
         end
         
         // Standard log output
         $fdisplay(sim_log_file, "SIMLOG:: Cycle %d PC: %8x I: %8x R: %d %3d %8x M: %d %d %8x %8x",
                  cycle_count,
                  PC,
                  Inst,
                  RegWrite,
                  WriteRegister,
                  WriteData,
                  MemRead,
                  MemWrite,
                  MemAddress,
                  MemData);
                  
         // Additional detailed debug information
         $fdisplay(debug_file, "DEBUG:: Cycle %d\n  PC: %8x Instr: %8x",
                  cycle_count, PC, Inst);
         $fdisplay(debug_file, "  RegSel: RR1=%d RR2=%d WR=%d  RegData: RD1=%8x RD2=%8x WD=%8x RegWrite=%d",
                  ReadReg1, ReadReg2, WriteRegister, ReadData1, ReadData2, WriteData, RegWrite);
         $fdisplay(debug_file, "  ALU: Result=%8x Flags=%b  Imm=%8x",
                  ALUResult, Flags, ImmValue);
         $fdisplay(debug_file, "  Mem: Read=%d Write=%d Addr=%8x Data=%8x",
                  MemRead, MemWrite, MemAddress, MemData);
         $fdisplay(debug_file, "  Ctrl: RR1Mux=%d RR2Mux=%d ImmMux=%d ALUSrcMux=%d MemtoRegMux=%d",
                  RR1Mux, RR2Mux, ImmMux, ALUSrcMux, MemtoRegMux);
         $fdisplay(debug_file, "        PCSMux=%d HaltMux=%d BranchRegMux=%d BranchMux=%d BranchTaken=%d\n",
                  PCSMux, HaltMux, BranchRegMux, BranchMux, BranchTaken);
         
         // Standard trace information
         if (RegWrite) begin
            if (MemRead) begin
               // ld
               $fdisplay(trace_file,"INUM: %8d PC: 0x%04x REG: %d VALUE: 0x%04x ADDR: 0x%04x",
                         (inst_count-1),
                        PC,
                        WriteRegister,
                        WriteData,
                        MemAddress);
            end else begin
               $fdisplay(trace_file,"INUM: %8d PC: 0x%04x REG: %d VALUE: 0x%04x",
                         (inst_count-1),
                        PC,
                        WriteRegister,
                        WriteData );
            end
         end else if (Halt) begin
            $fdisplay(sim_log_file, "SIMLOG:: Processor halted\n");
            $fdisplay(sim_log_file, "SIMLOG:: sim_cycles %d\n", cycle_count);
            $fdisplay(sim_log_file, "SIMLOG:: inst_count %d\n", inst_count);
            $fdisplay(trace_file, "INUM: %8d PC: 0x%04x",
                      (inst_count-1),
                      PC );

            $fclose(trace_file);
            $fclose(sim_log_file);
            $fclose(debug_file);
            
            $stop();
         end else begin
            if (MemWrite) begin
               // st
               $fdisplay(trace_file,"INUM: %8d PC: 0x%04x ADDR: 0x%04x VALUE: 0x%04x",
                         (inst_count-1),
                        PC,
                        MemAddress,
                        MemData);
            end else begin
               // conditional branch or NOP
               inst_count = inst_count + 1;
               $fdisplay(trace_file, "INUM: %8d PC: 0x%04x",
                         (inst_count-1),
                         PC );
            end
         end 
      end
   end

   // Assign internal signals to top level wires
   // Basic CPU execution signals
   assign Inst = DUT.instruction;
   assign RegWrite = DUT.RegWrite;
   assign WriteRegister = DUT.wr_reg;
   assign WriteData = DUT.write_data;
   assign MemRead = DUT.MemRead;
   assign MemWrite = DUT.MemWrite;
   assign MemAddress = DUT.alu_result;
   assign MemData = DUT.rr2_data;
   
   // Additional internal signals
   assign ReadReg1 = DUT.rr1_reg;
   assign ReadReg2 = DUT.rr2_reg;
   assign ReadData1 = DUT.rr1_data;
   assign ReadData2 = DUT.rr2_data;
   assign ImmValue = DUT.imm_value;
   assign ALUResult = DUT.alu_result;
   assign Flags = DUT.flags;
   assign BranchTaken = DUT.branch_taken;
   
   // Control signals
   assign RR1Mux = DUT.RR1Mux;
   assign RR2Mux = DUT.RR2Mux;
   assign ImmMux = DUT.ImmMux;
   assign ALUSrcMux = DUT.ALUSrcMux;
   assign MemtoRegMux = DUT.MemtoRegMux;
   assign PCSMux = DUT.PCSMux;
   assign HaltMux = DUT.HaltMux;
   assign BranchRegMux = DUT.BranchRegMux;
   assign BranchMux = DUT.BranchMux;
   
endmodule