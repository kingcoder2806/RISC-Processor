module writeback();




 // Write data selection for register file using assign statement with conditional operators
    assign write_data = PCSMux ? pc_plus2 :                                  // PCS instruction - save PC+2
                       MemtoRegMux ? mem_data_out :                          // Load from memory
                       alu_result;

endmodule