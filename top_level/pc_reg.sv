module pc_reg (
    input logic clk,               // Clock input
    input logic rst_n,             // Active low reset
    input logic [15:0] pc_next,    // Next PC value
    output logic [15:0] pc         // Current PC value
);

    // Program counter register
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            // Reset PC to 0 when reset is active
            pc <= 16'h0000;
        end else begin
            // Update PC with next value on clock edge
            pc <= pc_next;
        end
    end

endmodule