module branch(
    input [2:0] branch_condition,  // the 3-bit condition code (ccc)
    input [2:0] flag_reg,          // the flag register [N, Z, V]
    output branch_taken            // 1 if branch should be taken, 0 otherwise
);

    // declare wire signals
    wire n_flag;  // N
    wire z_flag;  // Z
    wire v_flag;  // V
    
    // declare condition wire signals
    wire cond_neq;     // not Equal (Z = 0)
    wire cond_eq;      // equal (Z = 1)
    wire cond_gt;      // greater Than (Z = N = 0)
    wire cond_lt;      // less Than (N = 1)
    wire cond_gte;     // greater Than or Equal (Z = 1 or Z = N = 0)
    wire cond_lte;     // less Than or Equal (N = 1 or Z = 1)
    wire cond_ovfl;    // overflow (V = 1)
    wire cond_uncond;  // unconditional
    
    // extract individual flags 
    assign n_flag = flag_reg[2];    // N
    assign z_flag = flag_reg[1];    // Z
    assign v_flag = flag_reg[0];    // V 
    
    // condition evaluation using assign statements
    assign cond_neq = ~z_flag;
    assign cond_eq = z_flag;
    assign cond_gt = (~z_flag) & (~n_flag);
    assign cond_lt = n_flag;
    assign cond_gte = z_flag | ((~z_flag) & (~n_flag));  
    assign cond_lte = n_flag | z_flag;
    assign cond_ovfl = v_flag;
    assign cond_uncond = 1'b1;
    
    // determine if branch should be taken based on condition and flags
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