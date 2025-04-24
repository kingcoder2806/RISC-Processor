module cache_fill_FSM(
    input clk,
    input rst_n,
    input miss,
    input [15:0] miss_addr,
    input [15:0] mem_data,
    input mem_data_valid,
    output fsm_busy,
    output wrt_data_array,
    output wrt_tag_array,
    output [15:0] mem_addr,
    output read_request
  );

  // State encoding
  localparam STATE_IDLE = 1'b0;
  localparam STATE_BUSY = 1'b1;

  // FSM state registers
  reg state, next_state;

  //////////////////////////////////////////////////////////////////////////////
  // CHUNK COUNTER
  //////////////////////////////////////////////////////////////////////////////
  reg  [2:0] counter, next_chunk;
  reg        chunk_done, req_data;
  wire       update_counter;

  // Clocked chunk counter via provided DFFs
  dff chunk_ff[2:0] (
    .q   (counter),
    .d   (next_chunk),
    .wen (update_counter),
    .clk (clk),
    .rst (~rst_n)
  );

  // Combinational logic to step through chunks 0–7
  always @(*) begin
    chunk_done = 1'b0;
    req_data   = 1'b0;
    case (counter)
      3'd0:  begin next_chunk = 3'd1; req_data = 1'b1; end
      3'd1:  begin next_chunk = 3'd2; req_data = 1'b1; end
      3'd2:  begin next_chunk = 3'd3; req_data = 1'b1; end
      3'd3:  begin next_chunk = 3'd4; req_data = 1'b1; end
      3'd4:  begin next_chunk = 3'd5; req_data = 1'b1; end
      3'd5:  begin next_chunk = 3'd6; req_data = 1'b1; end
      3'd6:  begin next_chunk = 3'd7; req_data = 1'b1; end
      3'd7:  begin
               next_chunk = 3'd0;
               chunk_done  = 1'b1;
               req_data    = 1'b0;
             end
      default: next_chunk = 3'bxxx;
    endcase
  end

  //////////////////////////////////////////////////////////////////////////////
  // FSM
  //////////////////////////////////////////////////////////////////////////////
  // State register
  dff state_fsm (
    .q   (state),
    .d   (next_state),
    .wen (1'b1),
    .clk (clk),
    .rst (~rst_n)
  );

  // Outputs and internal control regs
  reg        busy_signal;
  reg        write_data_enable;
  reg        write_tag_enable;
  reg        read_memory_request;
  reg        counter_enable;
  reg [15:0] next_mem_addr;

  // Connect internal regs to module outputs
  assign fsm_busy        = busy_signal;
  assign wrt_data_array  = write_data_enable;
  assign wrt_tag_array   = write_tag_enable;
  assign mem_addr        = next_mem_addr;
  assign read_request    = read_memory_request;
  assign update_counter  = counter_enable;

  // Combinational next-state & output logic
  always @(*) begin
    case (state)
      STATE_IDLE: begin
        write_data_enable   = 1'b0;
        write_tag_enable    = 1'b0;
        next_mem_addr       = { miss_addr[15:3], counter, 1'b0 };
        busy_signal         = miss     ? 1'b1 : 1'b0;
        counter_enable      = 1'b0;
        read_memory_request = miss     ? 1'b1 : 1'b0;
        next_state          = miss     ? STATE_BUSY : STATE_IDLE;
      end

      STATE_BUSY: begin
        write_data_enable   = mem_data_valid;
        write_tag_enable    = chunk_done & mem_data_valid;
        next_mem_addr       = { miss_addr[15:3], counter, 1'b0 };
        busy_signal         = 1'b1;
        counter_enable      = mem_data_valid;
        read_memory_request = req_data;
        next_state          = (chunk_done & mem_data_valid)
                              ? STATE_IDLE
                              : STATE_BUSY;
      end

      default: begin
        write_data_enable   = 1'bx;
        write_tag_enable    = 1'bx;
        next_mem_addr       = 16'hxxxx;
        busy_signal         = 1'bx;
        counter_enable      = 1'bx;
        read_memory_request = 1'bx;
        next_state          = 1'bx;
      end
    endcase
  end

endmodule
