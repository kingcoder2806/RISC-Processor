module iCache(
    input         clk,
    input         rst_n,
    input         mem_data_vld,
    input  [15:0] mem_data,
    input  [15:0] addr,
    output        read_req,
    output        fsm_busy,
    output        wrt_mem,
    output [15:0] cache_addr,
    output [15:0] data_out
);
    // Address instantiation //
    wire [4:0] tag;
    wire [6:0] index;
    wire [2:0] offset;

    // Assiging the tag, index and, offset bits //
    // used cache_addr since driven by FSM during refill, and else == addr // 
    assign tag = cache_addr[15:11];
    assign index = cache_addr[10:4];
    assign offset = cache_addr[3:1];

    // Decode signals //
    wire [127:0] block_en;
    decoder_7to128b dec_indx(.in(index), .out(block_en));

    wire [7:0] word_en;
    decoder_3to8b   dec_offs(.in(offset), .out(word_en));

    // Refill FSM interface //
    wire wrt_data_array;  // pulses on each returning half-word
    wire wrt_tag_array;   // pulses once at end to write tag+LRU+valid

    // Two-way metadata instatiation //
    wire [7:0] metaDataIn0, metaDataIn1;   // new {valid, spare bit (1'b0), LRU bit,tag bits}
    wire [7:0] metaDataOut0, metaDataOut1; // current read-back

    // Two-way data //
    wire [15:0] data0_out, data1_out;

    // Hit logic , valid bit = q and metaDataOut = tag //
    wire hit0 = metaDataOut0[7] && (metaDataOut0[4:0] == tag);
    wire hit1 = metaDataOut1[7] && (metaDataOut1[4:0] == tag);
    wire hit  = hit0 || hit1;

    // Replacement (LRU) and way selection //
    // On hit, refill the same way; on miss, use LRU bit from way0
    wire wayToFill = hit0 ? 1'b0 : hit1 ? 1'b1 : metaDataOut0[5];

    // Build new metadata entries //
    // valid=1, spare bit = 0, LRU = now MRU(0) or LRU(1), tag=addr[15:11]
    // For the chosen way, set LRU=0 (just used → MRU).
    // For the other way, set LRU=1 (now LRU).

    assign metaDataIn0 = {1'b1, 1'b0, wayToFill, tag};
    assign metaDataIn1 = {1'b1, 1'b0, ~wayToFill, tag};

    // Gate writes to the chosen way we want to write to //
    wire writeWay0 = wrt_data_array && (wayToFill == 1'b0);
    wire writeWay1 = wrt_data_array && (wayToFill == 1'b1);
    wire writeMeta0 = wrt_tag_array  && (wayToFill == 1'b0);
    wire writeMeta1 = wrt_tag_array  && (wayToFill == 1'b1);

    // Instantiate metadata arrays for each way (2) //
    MetaDataArray META0 (
      .clk        (clk),
      .rst        (rst_n),
      .DataIn     (metaDataIn0),
      .Write      (writeMeta0),
      .BlockEnable(block_en),
      .DataOut    (metaDataOut0)
    );
    MetaDataArray META1 (
      .clk        (clk),
      .rst        (rst_n),
      .DataIn     (metaDataIn1),
      .Write      (writeMeta1),
      .BlockEnable(block_en),
      .DataOut    (metaDataOut1)
    );

    // Instantiate data arrays for each way (2) //
    DataArray DATA0 (
      .clk         (clk),
      .rst         (rst_n),
      .DataIn      (mem_data),
      .Write       (writeWay0),
      .BlockEnable (block_en),
      .WordEnable  (word_en),
      .DataOut     (data0_out)
    );
    DataArray DATA1 (
      .clk         (clk),
      .rst         (rst_n),
      .DataIn      (mem_data),
      .Write       (writeWay1),
      .BlockEnable (block_en),
      .WordEnable  (word_en),
      .DataOut     (data1_out)
    );

    // Output mux for reads //
    assign data_out = hit0 ? data0_out
                    : hit1 ? data1_out
                    : 16'hxxxx;  // unused on miss (we stall)

    // Instruction cache never writes to memory so hardcode //
    assign wrt_mem = 1'b0;

    // Instantiate the refill FSM //
    cache_fill_FSM cache_fill_I (
        .clk            (clk),
        .rst_n          (rst_n),
        .miss           (~hit),
        .miss_addr      (addr),
        .mem_data       (mem_data),
        .mem_data_valid (mem_data_vld),
        .fsm_busy       (fsm_busy),
        .wrt_data_array (wrt_data_array),
        .wrt_tag_array  (wrt_tag_array),
        .mem_addr       (cache_addr), 
        .read_request   (read_req)
    );

endmodule
