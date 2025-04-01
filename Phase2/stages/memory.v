module memory();


     // DATA MEMORY (instance of memory1c)
    memory1c DMEM(
        .data_out(mem_data_out),  // Output: data read from memory
        .data_in(rr2_data),       // Input: data to write to memory (from rt register)
        .addr(alu_result),        // Address: calculated by ALU
        .enable(MemWrite | MemRead),         // Enable for LW/SW
        .wr(MemWrite),            // Write enable signal from control
        .clk(clk),
        .rst(~rst_n)              // Convert active-low to active-high
    );



endmodule