// Testbench for WISC-S25 Control Unit
module control_tb();
    // Inputs
    logic [15:0] instruction;
    
    // For checking results
    int errors = 0;
    
    // Outputs
    logic RR1Mux;
    logic RR2Mux;
    logic [1:0] ImmMux;
    logic ALUSrcMux;
    logic MemtoRegMux;
    logic PCSMux;
    logic HaltMux;
    logic BranchRegMux;
    logic BranchMux;
    logic RegWrite;
    logic MemWrite;
    logic DataMemEnable;
    
    // Instantiate the module under test
    control dut(
        .instruction(instruction),
        .RR1Mux(RR1Mux),
        .RR2Mux(RR2Mux),
        .ImmMux(ImmMux),
        .ALUSrcMux(ALUSrcMux),
        .MemtoRegMux(MemtoRegMux),
        .PCSMux(PCSMux),
        .HaltMux(HaltMux),
        .BranchRegMux(BranchRegMux),
        .BranchMux(BranchMux),
        .RegWrite(RegWrite),
        .MemWrite(MemWrite),
        .DataMemEnable(DataMemEnable)
    );
    
    // Helper function to check and report errors
    function void check_signals(
        string op_name,
        logic exp_RR1Mux, 
        logic exp_RR2Mux, 
        logic [1:0] exp_ImmMux, 
        logic exp_ALUSrcMux,
        logic exp_MemtoRegMux, 
        logic exp_PCSMux, 
        logic exp_HaltMux,
        logic exp_BranchRegMux, 
        logic exp_BranchMux, 
        logic exp_RegWrite, 
        logic exp_MemWrite,
        logic exp_DataMemEnable
    );
        
        // Check each signal against expected value
        if (RR1Mux !== exp_RR1Mux && exp_RR1Mux !== 1'bx) begin
            $display("Error: %s - RR1Mux is %b, expected %b", op_name, RR1Mux, exp_RR1Mux);
            errors++;
        end
        
        if (RR2Mux !== exp_RR2Mux) begin
            $display("Error: %s - RR2Mux is %b, expected %b", op_name, RR2Mux, exp_RR2Mux);
            errors++;
        end
        
        if (ImmMux !== exp_ImmMux && exp_ImmMux !== 2'bxx) begin
            $display("Error: %s - ImmMux is %b, expected %b", op_name, ImmMux, exp_ImmMux);
            errors++;
        end
        
        if (ALUSrcMux !== exp_ALUSrcMux && exp_ALUSrcMux !== 1'bx) begin
            $display("Error: %s - ALUSrcMux is %b, expected %b", op_name, ALUSrcMux, exp_ALUSrcMux);
            errors++;
        end
        
        if (MemtoRegMux !== exp_MemtoRegMux) begin
            $display("Error: %s - MemtoRegMux is %b, expected %b", op_name, MemtoRegMux, exp_MemtoRegMux);
            errors++;
        end
        
        if (PCSMux !== exp_PCSMux) begin
            $display("Error: %s - PCSMux is %b, expected %b", op_name, PCSMux, exp_PCSMux);
            errors++;
        end
        
        if (HaltMux !== exp_HaltMux) begin
            $display("Error: %s - HaltMux is %b, expected %b", op_name, HaltMux, exp_HaltMux);
            errors++;
        end
        
        if (BranchRegMux !== exp_BranchRegMux) begin
            $display("Error: %s - BranchRegMux is %b, expected %b", op_name, BranchRegMux, exp_BranchRegMux);
            errors++;
        end
        
        if (BranchMux !== exp_BranchMux) begin
            $display("Error: %s - BranchMux is %b, expected %b", op_name, BranchMux, exp_BranchMux);
            errors++;
        end
        
        if (RegWrite !== exp_RegWrite) begin
            $display("Error: %s - RegWrite is %b, expected %b", op_name, RegWrite, exp_RegWrite);
            errors++;
        end
        
        if (MemWrite !== exp_MemWrite) begin
            $display("Error: %s - MemWrite is %b, expected %b", op_name, MemWrite, exp_MemWrite);
            errors++;
        end
        
        if (DataMemEnable !== exp_DataMemEnable) begin
            $display("Error: %s - DataMemEnable is %b, expected %b", op_name, DataMemEnable, exp_DataMemEnable);
            errors++;
        end
        
        // If all checks pass, print success message
        if (errors == 0) begin
            $display("%s - All control signals correct", op_name);
        end
    endfunction

    // Main test process
    initial begin
        $display("Starting WISC-S25 Control Unit Tests");
        
        // Test each opcode with appropriate instruction format
        // ADD (0000)
        instruction = 16'b0000_0000_0000_0000;
        #10;
        check_signals("ADD", 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // SUB (0001)
        instruction = 16'b0001_0000_0000_0000;
        #10;
        check_signals("SUB", 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // XOR (0010)
        instruction = 16'b0010_0000_0000_0000;
        #10;
        check_signals("XOR", 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // RED (0011)
        instruction = 16'b0011_0000_0000_0000;
        #10;
        check_signals("RED", 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // PADDSB (0111)
        instruction = 16'b0111_0000_0000_0000;
        #10;
        check_signals("PADDSB", 1'b0, 1'b0, 2'bxx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // SLL (0100)
        instruction = 16'b0100_0000_0000_0000;
        #10;
        check_signals("SLL", 1'b0, 1'b0, 2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // SRA (0101)
        instruction = 16'b0101_0000_0000_0000;
        #10;
        check_signals("SRA", 1'b0, 1'b0, 2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // ROR (0110)
        instruction = 16'b0110_0000_0000_0000;
        #10;
        check_signals("ROR", 1'b0, 1'b0, 2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // LW (1000)
        instruction = 16'b1000_0000_0000_0000;
        #10;
        check_signals("LW", 1'b0, 1'b0, 2'b01, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1);
        
        // SW (1001)
        instruction = 16'b1001_0000_0000_0000;
        #10;
        check_signals("SW", 1'b0, 1'b1, 2'b01, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1);
        
        // LLB (1010)
        instruction = 16'b1010_0000_0000_0000;
        #10;
        check_signals("LLB", 1'b1, 1'b0, 2'b10, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // LHB (1011)
        instruction = 16'b1011_0000_0000_0000;
        #10;
        check_signals("LHB", 1'b1, 1'b0, 2'b10, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // B (1100)
        instruction = 16'b1100_0000_0000_0000;
        #10;
        check_signals("B", 1'bx, 1'b0, 2'bxx, 1'bx, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0);
        
        // BR (1101)
        instruction = 16'b1101_0000_0000_0000;
        #10;
        check_signals("BR", 1'b0, 1'b0, 2'bxx, 1'bx, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0);
        
        // PCS (1110)
        instruction = 16'b1110_0000_0000_0000;
        #10;
        check_signals("PCS", 1'bx, 1'b0, 2'bxx, 1'bx, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);
        
        // HLT (1111)
        instruction = 16'b1111_0000_0000_0000;
        #10;
        check_signals("HLT", 1'bx, 1'b0, 2'bxx, 1'bx, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0);
        
        // Summary
        if (errors == 0) begin
            $display("All tests passed! No errors found.");
        end else begin
            $display("%d errors found during testing.", errors);
        end
        
        $stop();
    end
endmodule