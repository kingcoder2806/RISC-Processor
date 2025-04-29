module mem_interface(
    input         clk,
    input         rst,
    input         d_wrt_en,         // data mem write enable
    input  [15:0] data_in,          // data from data memory in
    input  [15:0] i_addr,           // instruction address (PC)
    input  [15:0] d_addr,           // data address
    input         d_mem_en,         // enables data memory for reads
    output        i_fsm_busy,       // instruction cache busy
    output        d_fsm_busy,       // data cache busy
    output [15:0] instr_out,        // instruction from icache
    output [15:0] data_out          // data from data cache
);
    // Memory system wires
    wire        mem_en;             // memory enable
    wire        mem_wr;             // memory write enable
    wire        data_vld;           // memory data valid signal
    wire [15:0] mem_data_out;       // data from memory
    wire [15:0] mem_data_in;        // data to memory
    wire [15:0] mem_addr;           // address to memory

    // I-cache interface wires
    wire        i_data_vld;         // data valid to i-cache
    wire        i_read_req;         // read request from i-cache
    wire [15:0] i_cache_addr;       // address from i-cache

    // D-cache interface wires
    wire        d_data_vld;         // data valid to d-cache
    wire        d_read_req;         // read request from d-cache
    wire        d_wrt_mem;          // write request from d-cache
    wire [15:0] d_cache_addr;       // address from d-cache

    // Instantiate instruction cache
    iCache iCache(
        .clk(clk),
        .rst(rst),
        .mem_data_vld(i_data_vld),
        .mem_data(mem_data_out),
        .addr(i_addr),
        .read_req(i_read_req),
        .fsm_busy(i_fsm_busy),
        .wrt_mem(),                 // Not connected (I-cache never writes)
        .cache_addr(i_cache_addr),
        .data_out(instr_out)
    );

    // Instantiate data cache
    dCache dCache(
        .clk(clk),
        .rst(rst),
        .wrt_en(d_wrt_en),
        .mem_en(d_mem_en),
        .ifsm_busy(i_fsm_busy),
        .mem_data_vld(d_data_vld),
        .mem_data(mem_data_out),
        .addr(d_addr),
        .reg_in(data_in),
        .read_req(d_read_req),
        .fsm_busy(d_fsm_busy),
        .wrt_mem(d_wrt_mem),
        .cache_addr(d_cache_addr),
        .data_out(data_out)
    );

    // Instantiate memory
    memory4c mem(
        .data_out(mem_data_out),
        .data_in(mem_data_in),
        .addr(mem_addr),
        .enable(mem_en),
        .wr(mem_wr),
        .clk(clk),
        .rst(rst),
        .data_valid(data_vld)
    );

    // Arbitration logic - prioritize I-cache when busy
    wire sel;
    assign sel = i_fsm_busy;             // Select I-cache when it's busy
    
    // Memory interfacing based on selected cache
    assign mem_addr      = sel ? i_cache_addr                 : d_cache_addr;
    assign mem_en        = sel ? i_read_req                   : (d_read_req | d_wrt_mem);
    assign mem_wr        = sel ? 1'b0                         : d_wrt_mem;  // I-cache never writes
    assign i_data_vld    = sel ? data_vld                     : 1'b0;
    assign d_data_vld    = sel ? 1'b0                         : data_vld;
    assign mem_data_in   = data_in;  // Only D-cache writes to memory
    
endmodule
