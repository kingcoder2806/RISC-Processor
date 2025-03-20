module branch_tb();
    // Inputs
    logic [2:0] branch_condition;
    logic [2:0] flag_reg;
    
    // For checking results
    int errors = 0;
    
    // Outputs
    logic branch_taken;
    
    // Instantiate the module under test
    branch UUT (
        .branch_condition(branch_condition),
        .flag_reg(flag_reg),
        .branch_taken(branch_taken)
    );
    
    // Helper function to check and report errors
    function void check_branch(
        logic expected
    );
        if (branch_taken !== expected) begin
            $display("Error: branch_condition=%b, flag_reg=%b - branch_taken is %b, expected %b", 
                      branch_condition, flag_reg, branch_taken, expected);
            errors++;
        end else begin
            $display("PASS: branch_condition=%b, flag_reg=%b", branch_condition, flag_reg);
        end
    endfunction

    // Main test process
    initial begin
        $display("Starting Branch Module Tests");
        
        // Test Not Equal (000): Z = 0
        branch_condition = 3'b000;
        
        flag_reg = 3'b000; // Z=0
        #10;
        check_branch(1);
        
        flag_reg = 3'b010; // Z=1
        #10;
        check_branch(0);
        
        // Test Equal (001): Z = 1
        branch_condition = 3'b001;
        
        flag_reg = 3'b000; // Z=0
        #10;
        check_branch(0);
        
        flag_reg = 3'b010; // Z=1
        #10;
        check_branch(1);
        
        // Test Greater Than (010): Z=0, N=0
        branch_condition = 3'b010;
        
        flag_reg = 3'b000; // Z=0, N=0
        #10;
        check_branch(1);
        
        flag_reg = 3'b010; // Z=1, N=0
        #10;
        check_branch(0);
        
        flag_reg = 3'b100; // Z=0, N=1
        #10;
        check_branch(0);
        
        flag_reg = 3'b110; // Z=1, N=1
        #10;
        check_branch(0);
        
        // Test Less Than (011): N=1
        branch_condition = 3'b011;
        
        flag_reg = 3'b000; // N=0
        #10;
        check_branch(0);
        
        flag_reg = 3'b100; // N=1
        #10;
        check_branch(1);
        
        // Test Greater Than or Equal (100): Z=1 OR (Z=0 AND N=0)
        branch_condition = 3'b100;
        
        flag_reg = 3'b000; // Z=0, N=0
        #10;
        check_branch(1);
        
        flag_reg = 3'b010; // Z=1, N=0
        #10;
        check_branch(1);
        
        flag_reg = 3'b100; // Z=0, N=1
        #10;
        check_branch(0);
        
        flag_reg = 3'b110; // Z=1, N=1
        #10;
        check_branch(1);
        
        // Test Less Than or Equal (101): N=1 OR Z=1
        branch_condition = 3'b101;
        
        flag_reg = 3'b000; // Z=0, N=0
        #10;
        check_branch(0);
        
        flag_reg = 3'b010; // Z=1, N=0
        #10;
        check_branch(1);
        
        flag_reg = 3'b100; // Z=0, N=1
        #10;
        check_branch(1);
        
        flag_reg = 3'b110; // Z=1, N=1
        #10;
        check_branch(1);
        
        // Test Overflow (110): V=1
        branch_condition = 3'b110;
        
        flag_reg = 3'b000; // V=0
        #10;
        check_branch(0);
        
        flag_reg = 3'b001; // V=1
        #10;
        check_branch(1);
        
        // Test Unconditional (111): Always branch
        branch_condition = 3'b111;
        
        flag_reg = 3'b000;
        #10;
        check_branch(1);
        
        flag_reg = 3'b111;
        #10;
        check_branch(1);
        
        // Summary
        if (errors == 0) begin
            $display("All tests passed! No errors found.");
        end else begin
            $display("%d errors found during testing.", errors);
        end
        
        $stop();
    end
endmodule