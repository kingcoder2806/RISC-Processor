module cache_fill_FSM(
    input clk,
    input rst_n,
    input miss_detected,
    input [15:0] miss_address,
    input [15:0] memory_data,
    input memory_data_valid,
    output fsm_busy,
    output write_data_array,
    output write_tag_array,
    output [15:0] memory_address,
    output read_request
);

  // Define state encoding using localparams instead of typedef
  localparam STATE_IDLE = 1'b0;
  localparam STATE_BUSY = 1'b1;
  
  // Replace 'state_t' with reg types
  reg state, next_state;
  
  //////////////////////////////////////////////////////////////////////////////
  // CHUNK COUNTER
  //////////////////////////////////////////////////////////////////////////////
  
  reg [2:0] counter;       // Current chunk counter
  reg [2:0] next_chunk;    // Next counter value
  reg chunk_done;          // When all chunks are received
  reg req_data;            // Active when requesting memory data
  wire update_counter;      // Signal to increment counter
  
  // Counter register logic
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      counter <= 3'b000;
    else if (update_counter)
      counter <= next_chunk;
  end
  
  // Counter combinational logic using always @(*)
  always @(*) begin
    chunk_done = 1'b0;
    req_data = 1'b0;
    case(counter)
      3'd0: begin next_chunk = 3'd1; req_data = 1'b1; end
      3'd1: begin next_chunk = 3'd2; req_data = 1'b1; end
      3'd2: begin next_chunk = 3'd3; req_data = 1'b1; end
      3'd3: begin next_chunk = 3'd4; req_data = 1'b1; end
      3'd4: begin next_chunk = 3'd5; req_data = 1'b1; end
      3'd5: begin next_chunk = 3'd6; req_data = 1'b1; end
      3'd6: begin next_chunk = 3'd7; req_data = 1'b1; end
      3'd7: begin
              next_chunk = 3'd0;
              chunk_done = 1'b1;
              req_data = 1'b0;
           end
      default: next_chunk = 3'bxxx;
    endcase
  end
  
  //////////////////////////////////////////////////////////////////////////////
  // FSM
  //////////////////////////////////////////////////////////////////////////////
  
  // FSM state register
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      state <= STATE_IDLE;
    else
      state <= next_state;
  end
  
  // Output registers
  reg busy_signal;
  reg write_data_enable;
  reg write_tag_enable;
  reg read_memory_request;
  reg counter_enable;
  reg [15:0] mem_addr;
  
  // Assign internal registers to outputs
  assign fsm_busy        = busy_signal;
  assign write_data_array = write_data_enable;
  assign write_tag_array  = write_tag_enable;
  assign memory_address   = mem_addr;
  assign read_request     = read_memory_request;
  assign update_counter   = counter_enable;
  
  // FSM state and output logic with always @(*)
  always @(*) begin
    case (state)
      STATE_IDLE: begin
        write_data_enable   = 1'b0;
        write_tag_enable    = 1'b0;
        mem_addr            = {miss_address[15:3], counter, 1'b0};
        busy_signal         = miss_detected ? 1'b1 : 1'b0;
        counter_enable      = 1'b0;
        read_memory_request = miss_detected ? 1'b1 : 1'b0;
        next_state          = miss_detected ? STATE_BUSY : STATE_IDLE;
      end
      
      STATE_BUSY: begin
        write_data_enable   = memory_data_valid;
        write_tag_enable    = chunk_done & memory_data_valid;
        mem_addr            = {miss_address[15:3], counter, 1'b0};
        busy_signal         = 1'b1;
        counter_enable      = memory_data_valid;
        read_memory_request = req_data;
        next_state          = (chunk_done & memory_data_valid) ? STATE_IDLE : STATE_BUSY;
      end
      
      default: begin
        write_data_enable   = 1'bx;
        write_tag_enable    = 1'bx;
        mem_addr            = 16'hxxxx;
        busy_signal         = 1'bx;
        counter_enable      = 1'bx;
        read_memory_request = 1'bx;
        next_state          = 1'bx;
      end
    endcase
  end
  
endmodule
