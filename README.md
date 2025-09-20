# RISC Processor (ECE 552 Project)

A 32-bit, 5-stage pipelined RISC processor with **instruction and data cache support**, designed in **Verilog**.  
The design includes hazard detection, forwarding logic, cache integration, and testbench verification using ModelSim/GTKWave.

---

## Features
- **32-bit Instruction Set**: Arithmetic, logic, load/store, and branch ops.
- **5-Stage Pipeline**: IF → ID → EX → MEM → WB.
- **Hazard Handling**:
  - Data forwarding (reduces stalls).
  - Hazard detection for load-use dependencies.
  - Basic branch handling.
- **Cache System**:
  - Instruction Cache (I-Cache) and Data Cache (D-Cache).
  - Configurable cache size, block size, and associativity.
  - Write-back / write-allocate policies.
  - Miss handling and memory interface integration.
- **Simulation & Testing**:
  - Self-checking testbenches.
  - Waveform analysis with GTKWave.
  - Verified functional correctness and cache hit/miss behavior.

---

## Project Structure
