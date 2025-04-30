module iCache (
    input         clk,
    input         rst,

    /* memory port */
    input         mem_data_vld,
    input  [15:0] mem_data,

    /* CPU fetch interface */
    input  [15:0] addr,          // PC
    output        read_req,
    output        fsm_busy,
    output        wrt_mem,       // always 0
    output [15:0] miss_addr,     // to memory arbiter
    output [15:0] data_out       // instruction
);

    /* effective address */
    wire [15:0] cache_addr;
    wire [4:0]  tag    = cache_addr[15:11];
    wire [6:0]  index  = cache_addr[10:4];
    wire [2:0]  offset = cache_addr[3:1];

    /* decoders */
    wire [127:0] block_en;
    decoder_7to128b dec_idx(.in(index), .out(block_en));
    wire [7:0] word_en;
    decoder_3to8b  dec_off(.in(offset), .out(word_en));

    /* arrays */
    wire [7:0] meta0_in, meta1_in, meta0_out, meta1_out;
    wire [15:0] data0_out, data1_out;

    /* hit logic */
    wire hit0 = meta0_out[7] & (meta0_out[4:0] == tag);
    wire hit1 = meta1_out[7] & (meta1_out[4:0] == tag);
    wire hit  = hit0 | hit1;

    /* victim way (deterministic on reset) */
    wire bothInvalid = (meta0_out[7] !== 1'b1) & (meta1_out[7] !== 1'b1);
    wire wayFill = hit0        ? 1'b0 :
                   hit1        ? 1'b1 :
                   bothInvalid ? 1'b0 : meta0_out[5];   // LRU

    assign meta0_in = {1'b1,1'b0,(wayFill==1'b0),tag};
    assign meta1_in = {1'b1,1'b0,(wayFill==1'b1),tag};

    /* write enables – simplified */
    wire wr_data, wr_tag;
    wire writeWay0  = wr_data & (wayFill == 1'b0);
    wire writeWay1  = wr_data & (wayFill == 1'b1);
    wire writeMeta0 = wr_tag  & (wayFill == 1'b0);
    wire writeMeta1 = wr_tag  & (wayFill == 1'b1);

    MetaDataArray META0(.clk(clk),.rst(rst),.DataIn(meta0_in),.Write(writeMeta0),
                        .BlockEnable(block_en),.DataOut(meta0_out));
    MetaDataArray META1(.clk(clk),.rst(rst),.DataIn(meta1_in),.Write(writeMeta1),
                        .BlockEnable(block_en),.DataOut(meta1_out));

    DataArray DATA0(.clk(clk),.rst(rst),.DataIn(mem_data),.Write(writeWay0),
                    .BlockEnable(block_en),.WordEnable(word_en),.DataOut(data0_out));
    DataArray DATA1(.clk(clk),.rst(rst),.DataIn(mem_data),.Write(writeWay1),
                    .BlockEnable(block_en),.WordEnable(word_en),.DataOut(data1_out));

    assign data_out = hit0 ? data0_out :
                      hit1 ? data1_out : 16'hZZZZ;

    assign wrt_mem = 1'b0;  // I-cache never writes memory

    /* refill FSM */
    cache_fill_FSM FSM_I (
        .clk            (clk),
        .rst            (rst),
        .wrt            (1'b0),
        .miss           (~hit),
        .miss_addr      (addr),
        .mem_data       (mem_data),
        .mem_data_valid (mem_data_vld),
        .pause          (1'b0),
        .fsm_busy       (fsm_busy),
        .wrt_data_array (wr_data),
        .wrt_tag_array  (wr_tag),
        .wrt_mem        (),
        .mem_addr       (miss_addr),
        .cache_addr     (cache_addr),
        .read_request   (read_req)
    );
endmodule
