module cache_fill_FSM(
    input clk,
    input rst,
    input wrt,                    // Added: Write enable signal on hit
    input miss,                   // miss_detected
    input [15:0] miss_addr,
    input [15:0] mem_data,        // memory_data
    input mem_data_valid,         // memory_data_vld
    input pause,                  // Added: Signal to pause counter
    output fsm_busy,
    output wrt_data_array,        // write_data_array
    output wrt_tag_array,         // write_tag_array
    output wrt_mem,               // Added: Write signal to memory
    output [15:0] mem_addr,       // memory_address
    output [15:0] cache_addr,     // Added: Separate address for cache
    output read_request           // read_req
);

  // State encoding
  localparam STATE_IDLE = 1'b0;
  localparam STATE_BUSY = 1'b1;

  ////////////////////////////////////////////////////////////////////////////
  // MAIN COUNTER FOR MEMORY ADDRESSING
  ////////////////////////////////////////////////////////////////////////////
  wire [3:0] cnt;                // Extended to 4 bits to match online version
  reg [3:0] nxt_cnt_reg;
  wire incr_cnt;
  wire done, reading;
  reg done_reg, reading_reg;

  // Counter flip-flops - expanded to 4 bits
  dff cnt_ff0(.q(cnt[0]), .d(nxt_cnt_reg[0]), .wen(incr_cnt),
              .clk(clk), .rst(rst));
  dff cnt_ff1(.q(cnt[1]), .d(nxt_cnt_reg[1]), .wen(incr_cnt),
              .clk(clk), .rst(rst));
  dff cnt_ff2(.q(cnt[2]), .d(nxt_cnt_reg[2]), .wen(incr_cnt),
              .clk(clk), .rst(rst));
  dff cnt_ff3(.q(cnt[3]), .d(nxt_cnt_reg[3]), .wen(incr_cnt),
              .clk(clk), .rst(rst));

  assign done    = done_reg;
  assign reading = incr_cnt ? reading_reg : 1'b0;

  // Counter logic expanded to match online version
  always @(*) begin
    done_reg = 1'b0;
    case(cnt)
      4'd0  : begin nxt_cnt_reg = 4'd1;  reading_reg = 1'b1; end
      4'd1  : begin nxt_cnt_reg = 4'd2;  reading_reg = 1'b1; end
      4'd2  : begin nxt_cnt_reg = 4'd3;  reading_reg = 1'b1; end
      4'd3  : begin nxt_cnt_reg = 4'd4;  reading_reg = 1'b1; end
      4'd4  : begin nxt_cnt_reg = 4'd5;  reading_reg = 1'b1; end
      4'd5  : begin nxt_cnt_reg = 4'd6;  reading_reg = 1'b1; end
      4'd6  : begin nxt_cnt_reg = 4'd7;  reading_reg = 1'b1; end
      4'd7  : begin nxt_cnt_reg = 4'd8;  reading_reg = 1'b1; end
      4'd8  : begin nxt_cnt_reg = 4'd9;  reading_reg = 1'b0; end
      4'd9  : begin nxt_cnt_reg = 4'd10; reading_reg = 1'b0; end
      4'd10 : begin nxt_cnt_reg = 4'd11; reading_reg = 1'b0; end
      4'd11 : begin
                nxt_cnt_reg = 4'd0;
                done_reg    = incr_cnt ? 1'b1 : 1'b0;
                reading_reg = 1'b0;
              end
      default : nxt_cnt_reg = 4'hx;
    endcase
  end

  ////////////////////////////////////////////////////////////////////////////
  // BLOCK OFFSET COUNTER FOR CACHE ADDRESSING
  ////////////////////////////////////////////////////////////////////////////
  wire [3:0] blck_off;
  reg  [3:0] nxt_blck_off_reg;

  // Block offset flip-flops
  dff blk_ff0(.q(blck_off[0]), .d(nxt_blck_off_reg[0]),
              .wen(mem_data_valid), .clk(clk), .rst(rst));
  dff blk_ff1(.q(blck_off[1]), .d(nxt_blck_off_reg[1]),
              .wen(mem_data_valid), .clk(clk), .rst(rst));
  dff blk_ff2(.q(blck_off[2]), .d(nxt_blck_off_reg[2]),
              .wen(mem_data_valid), .clk(clk), .rst(rst));
  dff blk_ff3(.q(blck_off[3]), .d(nxt_blck_off_reg[3]),
              .wen(mem_data_valid), .clk(clk), .rst(rst));

  // Block offset logic
  always @(*) begin
    case(blck_off)
      4'b0000 : nxt_blck_off_reg = 4'b0010;
      4'b0010 : nxt_blck_off_reg = 4'b0100;
      4'b0100 : nxt_blck_off_reg = 4'b0110;
      4'b0110 : nxt_blck_off_reg = 4'b1000;
      4'b1000 : nxt_blck_off_reg = 4'b1010;
      4'b1010 : nxt_blck_off_reg = 4'b1100;
      4'b1100 : nxt_blck_off_reg = 4'b1110;
      4'b1110 : nxt_blck_off_reg = 4'b0000;
      default : nxt_blck_off_reg = 4'hx;
    endcase
  end

  ////////////////////////////////////////////////////////////////////////////
  // FSM
  ////////////////////////////////////////////////////////////////////////////
  wire state_wire;
  reg  next_state;
  dff state_fsm(.q(state_wire), .d(next_state), .wen(1'b1),
                .clk(clk), .rst(rst));
  wire state = state_wire;

  // Output registers
  reg busy_signal, write_data_enable, write_tag_enable;
  reg read_memory_request, write_memory, counter_enable;
  reg [15:0] memory_address_reg, cache_address_reg;

  assign fsm_busy       = busy_signal;
  assign wrt_data_array = write_data_enable;
  assign wrt_tag_array  = write_tag_enable;
  assign mem_addr       = memory_address_reg;
  assign cache_addr     = cache_address_reg;
  assign read_request   = read_memory_request;
  assign wrt_mem        = write_memory;
  assign incr_cnt       = counter_enable;

  // FSM next-state & output logic
  always @(*) begin
    case (state)
      STATE_IDLE: begin
        write_data_enable   = miss ? 1'b0 : wrt;
        write_tag_enable    = 1'b0;
        cache_address_reg   = miss ? {miss_addr[15:4], blck_off} : miss_addr;
        memory_address_reg  = miss ? {miss_addr[15:4], cnt} : miss_addr;
        busy_signal         = miss;
        counter_enable      = 1'b0;
        read_memory_request = 1'b0;
        write_memory        = miss ? 1'b0 : wrt;
        next_state          = miss ? STATE_BUSY : STATE_IDLE;
      end

      STATE_BUSY: begin
        write_data_enable   = mem_data_valid;
        write_tag_enable    = done;
        cache_address_reg   = {miss_addr[15:4], blck_off};
        memory_address_reg  = {miss_addr[15:4], cnt[2:0], 1'b0};
        busy_signal         = 1'b1;
        counter_enable      = pause ? 1'b0 : 1'b1;
        read_memory_request = reading;
        write_memory        = 1'b0;
        next_state          = done ? STATE_IDLE : STATE_BUSY;
      end

      default: begin
        write_data_enable   = 1'bx;
        write_tag_enable    = 1'bx;
        cache_address_reg   = 16'hxxxx;
        memory_address_reg  = 16'hxxxx;
        busy_signal         = 1'bx;
        counter_enable      = 1'bx;
        read_memory_request = 1'bx;
        write_memory        = 1'bx;
        next_state          = 1'bx;
      end
    endcase
  end
endmodule
