module branch(
    input [2:0] branch_condition,  // The 3-bit condition code (ccc)
    input [2:0] flag_reg,          // The flag register [N, V, Z]
    output branch_taken            // 1 if branch should be taken, 0 otherwise
);

    // Declare logic signals
    logic n_flag;  // Negative flag
    logic v_flag;  // Overflow flag
    logic z_flag;  // Zero flag
    
    // Declare condition logic signals
    logic cond_neq;     // Not Equal (Z = 0)
    logic cond_eq;      // Equal (Z = 1)
    logic cond_gt;      // Greater Than (Z = N = 0)
    logic cond_lt;      // Less Than (N = 1)
    logic cond_gte;     // Greater Than or Equal (Z = 1 or Z = N = 0)
    logic cond_lte;     // Less Than or Equal (N = 1 or Z = 1)
    logic cond_ovfl;    // Overflow (V = 1)
    logic cond_uncond;  // Unconditional
    
    // Extract individual flags
    assign n_flag = flag_reg[2];
    assign v_flag = flag_reg[1];
    assign z_flag = flag_reg[0];
    
    // Condition evaluation using assign statements
    assign cond_neq = ~z_flag;
    assign cond_eq = z_flag;
    assign cond_gt = (~z_flag) & (~n_flag);
    assign cond_lt = n_flag;
    assign cond_gte = z_flag | (~n_flag);
    assign cond_lte = n_flag | z_flag;
    assign cond_ovfl = v_flag;
    assign cond_uncond = 1'b1;
    
    // Determine if branch should be taken based on condition and flags
    assign branch_taken = 
        (branch_condition == 3'b000) ? cond_neq :
        (branch_condition == 3'b001) ? cond_eq :
        (branch_condition == 3'b010) ? cond_gt :
        (branch_condition == 3'b011) ? cond_lt :
        (branch_condition == 3'b100) ? cond_gte :
        (branch_condition == 3'b101) ? cond_lte :
        (branch_condition == 3'b110) ? cond_ovfl :
        (branch_condition == 3'b111) ? cond_uncond : 1'b0;

endmodule