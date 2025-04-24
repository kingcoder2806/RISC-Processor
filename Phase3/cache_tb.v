module cache_fill_FSM_tb();

 

  // Testbench signals

  reg clk;

  reg rst_n;

  reg miss_detected;

  reg [15:0] miss_address;

  reg [15:0] memory_data;

  reg memory_data_valid;

 

  wire fsm_busy;

  wire write_data_array;

  wire write_tag_array;

  wire [15:0] memory_address;

  wire read_request;

 

  // Instantiate the cache controller

  cache_fill_FSM DUT (

    .clk(clk),

    .rst_n(rst_n),

    .miss_detected(miss_detected),

    .miss_address(miss_address),

    .memory_data(memory_data),

    .memory_data_valid(memory_data_valid),

    .fsm_busy(fsm_busy),

    .write_data_array(write_data_array),

    .write_tag_array(write_tag_array),

    .memory_address(memory_address),

    .read_request(read_request)

  );

 

  // Clock generation

  initial begin

    clk = 0;

    forever #5 clk = ~clk; // 10ns clock period (100MHz)

  end

 

  // Test scenarios

  initial begin

    // Initialize signals

    rst_n = 0;

    miss_detected = 0;

    miss_address = 16'h0000;

    memory_data = 16'h0000;

    memory_data_valid = 0;

   

    // Apply reset

    #20;

    rst_n = 1;

    #10;

   

    // Display header

    $display("Time | State | Miss | Mem Valid | Busy | Write Data | Write Tag | Read Req | Mem Addr");

    $display("-----|-------|------|-----------|------|------------|-----------|----------|----------");

   

    // Test Case 1: Single cache miss followed by memory reads

    miss_address = 16'h1234;

   

    // Trigger a miss

    @(posedge clk) miss_detected = 1;

   

    // Print initial state after miss detection

    @(posedge clk) print_state();

   

    // Turn off miss signal and simulate memory returning data

    miss_detected = 0;

   

    // Simulate receiving 8 chunks of data from memory with 4-cycle latency each

    repeat (8) begin

      // 4-cycle latency for each memory read

      repeat (3) begin

        @(posedge clk) print_state();

      end

     

      // Memory returns valid data on 4th cycle

      @(posedge clk)

      memory_data_valid = 1;

      memory_data = memory_data + 16'h0001; // Some changing data pattern

      print_state();

     

      // Turn off valid signal

      @(posedge clk)

      memory_data_valid = 0;

    end

   

    // Run a few more cycles to observe return to idle

    repeat (5) begin

      @(posedge clk) print_state();

    end

   

    // Test Case 2: Back-to-back misses

    #20;

    $display("\n--- Test Case 2: Back-to-back misses ---\n");

    $display("Time | State | Miss | Mem Valid | Busy | Write Data | Write Tag | Read Req | Mem Addr");

    $display("-----|-------|------|-----------|------|------------|-----------|----------|----------");

   

    // First miss

    miss_address = 16'h5678;

    @(posedge clk) miss_detected = 1;

    @(posedge clk) print_state();

    miss_detected = 0;

   

    // Process only 4 chunks

    repeat (4) begin

      repeat (3) @(posedge clk) print_state();

      @(posedge clk) memory_data_valid = 1; memory_data = memory_data + 16'h0001; print_state();

      @(posedge clk) memory_data_valid = 0;

    end

   

    // Trigger another miss before completing the first one

    miss_address = 16'h9ABC;

    @(posedge clk) miss_detected = 1;

    @(posedge clk) print_state();

    miss_detected = 0;

   

    // Complete remaining chunks

    repeat (4) begin

      repeat (3) @(posedge clk) print_state();

      @(posedge clk) memory_data_valid = 1; memory_data = memory_data + 16'h0001; print_state();

      @(posedge clk) memory_data_valid = 0;

    end

   

    // Run a few more cycles to observe return to idle

    repeat (5) begin

      @(posedge clk) print_state();

    end

   

    // End simulation

    #20;

    $display("\nSimulation complete!");

    $finish;

  end

 

  // Helper task to print current state

  task print_state;

    begin

      $display("%4t | %5s | %4b | %9b | %4b | %10b | %9b | %8b | %8h",

               $time,

               (DUT.state == DUT.STATE_IDLE) ? "IDLE" : "BUSY",

               miss_detected,

               memory_data_valid,

               fsm_busy,

               write_data_array,

               write_tag_array,

               read_request,

               memory_address);

    end

  endtask

 

endmodule