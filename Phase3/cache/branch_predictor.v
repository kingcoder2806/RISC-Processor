// 2-bit saturating BHT + simple BTB
module branch_predictor #(
    parameter N   = 128,  // number of entries
    parameter IDX = 7     // log2(N)
)(
    input               clk,
    input               rst_n,

    // ==> lookup port
    input  [15:0]       pc_fetch,
    output              predict_taken,
    output reg [15:0]   predict_target,

    // ==> update port (on branch resolution)
    input               update_en,
    input  [15:0]       pc_resolve,
    input               taken,
    input  [15:0]       target
);

    // two-bit counters
    reg [1:0]    bht [0:N-1];
    // branch target buffer
    reg [15:0]   btb [0:N-1];

    // index into tables (drop two low bits, then low IDX bits)
    wire [IDX-1:0] idx_fetch   = pc_fetch[IDX+1:2];
    wire [IDX-1:0] idx_resolve = pc_resolve[IDX+1:2];

    // predict “taken” if MSB of the 2-bit counter is 1
    assign predict_taken = bht[idx_fetch][1];

    // supply the cached target
    always @(*) begin
        predict_target = btb[idx_fetch];
    end

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // initialize to weakly-not-taken, empty BTB
            for (i = 0; i < N; i = i+1) begin
                bht[i] <= 2'b01;
                btb[i] <= 16'h0000;
            end
        end else if (update_en) begin
            // update saturating counter
            if (taken && bht[idx_resolve] != 2'b11)
                bht[idx_resolve] <= bht[idx_resolve] + 1;
            else if (!taken && bht[idx_resolve] != 2'b00)
                bht[idx_resolve] <= bht[idx_resolve] - 1;

            // on taken, update BTB
            if (taken)
                btb[idx_resolve] <= target;
        end
    end

endmodule
