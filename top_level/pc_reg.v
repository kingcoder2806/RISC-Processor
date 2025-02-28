module pc_reg (
    input clk,               // Clock input
    input rst_n,             // Active low reset
    input [15:0] pc_next,    // Next PC value
    output reg [15:0] pc     // Current PC value (reg instead of wire for sequential output)
);

    // Program counter register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset PC to 0 when reset is active
            pc <= 16'h0000;
        end else begin
            // Update PC with next value on clock edge
            pc <= pc_next;
        end
    end

endmodule