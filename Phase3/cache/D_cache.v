module dCache(
    input         clk,            // Clock
    input         rst_n,          // Active-low reset
    input         wrt_en,         // High when processor issues a store
    input         mem_en,         // Enable cache (stall if low)
    input         ifsm_busy,      // Stall signal from I-cache FSM
    input         mem_data_vld,   // Memory data valid
    input  [15:0] mem_data,       // Half-word returned from memory
    input  [15:0] addr,           // Requested half-word address
    input  [15:0] reg_in,         // Store data from register file

    output        read_req,       // Memory read request to arbiter
    output        fsm_busy,       // Stall pipeline on a miss
    output        wrt_mem,        // Memory write (write-through)
    output [15:0] cache_addr,     // Address sent to memory arbiter
    output [15:0] data_out        // Data returned to CPU
);

    // Address instantiation //
    wire [4:0]  tag;
    wire [6:0]  index;
    wire [2:0]  offset;

    // Assign tag, index, offset from cache_addr (driven by FSM or addr) //
    assign tag    = cache_addr[15:11];
    assign index  = cache_addr[10:4];
    assign offset = cache_addr[3:1];

    // Decode for BlockEnable //
    wire [127:0] block_en;
    decoder_7to128b dec_idx(.in(index), .out(block_en));

    // Decode for WordEnable //
    wire [7:0] word_en;
    decoder_3to8b dec_off(.in(offset), .out(word_en));

    // Refill FSM interface //
    wire        wrt_data_array;  // Pulse each returning half-word
    wire        wrt_tag_array;   // Pulse once to write new tag/valid

    // Two-way metadata instantiation //
    wire [7:0] metaDataIn0, metaDataIn1;   // New {Valid, spare, LRU, Tag[4:0]}
    wire [7:0] metaDataOut0, metaDataOut1; // Current metadata read-back

    // Two-way data outputs //
    wire [15:0] data0_out, data1_out;

    // Hit logic (Valid && Tag match) //
    wire hit0 = metaDataOut0[7] && (metaDataOut0[4:0] == tag);
    wire hit1 = metaDataOut1[7] && (metaDataOut1[4:0] == tag);
    wire hit  = hit0 || hit1;

    // D-cache miss condition (not hit, cache enabled, I-cache not busy) //
    wire miss = (~hit) && mem_en && ~ifsm_busy;

    // Replacement (1-bit LRU) & way selection //
    // On hit, refill same way; on miss pick way by LRU bit
    wire wayToFill = hit0 ? 1'b0
                      : hit1 ? 1'b1
                             : metaDataOut0[5];

    // Build new metadata entries //
    // {Valid=1, spare=0, LRU=(i==wayToFill?0:1), Tag}
    assign metaDataIn0 = {1'b1, 1'b0, wayToFill,    tag};
    assign metaDataIn1 = {1'b1, 1'b0, ~wayToFill,   tag};

    // Select data input: store-hit uses reg_in, refill uses mem_data //
    wire [15:0] data_in = (hit && wrt_en && mem_en)
                          ? reg_in
                          : mem_data;

    // Gate writes to data arrays //
    wire writeWay0 = (hit0 && wrt_en && mem_en) || (wrt_data_array && wayToFill==0);
    wire writeWay1 = (hit1 && wrt_en && mem_en) || (wrt_data_array && wayToFill==1);

    // Gate writes to metadata arrays //
    wire writeMeta0 = wrt_tag_array && (wayToFill==0);
    wire writeMeta1 = wrt_tag_array && (wayToFill==1);

    // Memory write-through signal //
    assign wrt_mem = hit && wrt_en && mem_en;

    // Instantiate metadata arrays (2 ways) //
    MetaDataArray META0(
      .clk        (clk),
      .rst        (rst_n),
      .DataIn     (metaDataIn0),
      .Write      (writeMeta0),
      .BlockEnable(block_en),
      .DataOut    (metaDataOut0)
    );
    MetaDataArray META1(
      .clk        (clk),
      .rst        (rst_n),
      .DataIn     (metaDataIn1),
      .Write      (writeMeta1),
      .BlockEnable(block_en),
      .DataOut    (metaDataOut1)
    );

    // Instantiate data arrays (2 ways) //
    DataArray DATA0(
      .clk         (clk),
      .rst         (rst_n),
      .DataIn      (data_in),
      .Write       (writeWay0),
      .BlockEnable (block_en),
      .WordEnable  (word_en),
      .DataOut     (data0_out)
    );
    DataArray DATA1(
      .clk         (clk),
      .rst         (rst_n),
      .DataIn      (data_in),
      .Write       (writeWay1),
      .BlockEnable (block_en),
      .WordEnable  (word_en),
      .DataOut     (data1_out)
    );

    // Output mux for reads //
    assign data_out = hit0 ? data0_out
                    : hit1 ? data1_out
                    : 16'hxxxx;  // unused on miss (we stall)

    // Instantiate refill FSM //
    cache_fill_FSM cache_fill_D(
        .clk            (clk),
        .rst_n          (rst_n),
        .miss           (miss),
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
