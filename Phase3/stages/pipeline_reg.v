module pipeline_reg #(parameter WIDTH = 16)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] d,
    input clr,
    input wren,
    output [WIDTH-1:0] q
);

   // Array of D flip-flops for each bit
   dff ff [WIDTH-1:0](
      .q(q),
      .d(clr ? {WIDTH{1'b0}} : d),  // Clear to zeros when clr=1, otherwise pass d
      .wen(wren),                   
      .clk(clk),                    
      .rst(~rst_n)                  // Convert active-low to active-high
   );

endmodule
