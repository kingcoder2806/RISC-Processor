module pc_reg (
    input clk,               // Clock input
    input rst_n,             // Active low reset
    input [15:0] pc_next,    // Next PC value
    output [15:0] pc     // Current PC value (reg instead of wire for sequential output)
);

	/*
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
	*/
	
	dff iDFF0(.d(pc_next[0]), .q(pc[0]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF1(.d(pc_next[1]), .q(pc[1]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF2(.d(pc_next[2]), .q(pc[2]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF3(.d(pc_next[3]), .q(pc[3]), .wen(1'b1), .clk(clk), .rst(rst_n));
	
	dff iDFF4(.d(pc_next[4]), .q(pc[4]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF5(.d(pc_next[5]), .q(pc[5]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF6(.d(pc_next[6]), .q(pc[6]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF7(.d(pc_next[7]), .q(pc[7]), .wen(1'b1), .clk(clk), .rst(rst_n));
	
	dff iDFF8(.d(pc_next[8]), .q(pc[8]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF9(.d(pc_next[9]), .q(pc[9]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF10(.d(pc_next[10]), .q(pc[10]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF11(.d(pc_next[11]), .q(pc[11]), .wen(1'b1), .clk(clk), .rst(rst_n));
	
	dff iDFF12(.d(pc_next[12]), .q(pc[12]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF13(.d(pc_next[13]), .q(pc[13]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF14(.d(pc_next[14]), .q(pc[14]), .wen(1'b1), .clk(clk), .rst(rst_n));
	dff iDFF15(.d(pc_next[15]), .q(pc[15]), .wen(1'b1), .clk(clk), .rst(rst_n));

endmodule