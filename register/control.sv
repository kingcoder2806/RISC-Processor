module control (
    input [15:0] instruction,
    output RR1Mux,
    output RR2Mux,
    output [1:0] ImmMux,
    output ALUSrcMux,
    output MemtoRegMux,
    output PCSWriteMux,
    output PSCInstrMUX,
    output HaltMux,
    output BranchRegMux,
    output BranchMux,
    output RegWrite,
    output MemWrite
    output DataMemEnable
);

    // WISC-S25 Instruction Opcodes:

    ///////////////////////////////////
    // Opcode(4) rd(4), rs(4), rt(4) //
    ///////////////////////////////////
    // 0000 - ADD     : Addition with saturation 
    // 0001 - SUB     : Subtraction with saturation 
    // 0010 - XOR     : Bitwise XOR 
    // 0011 - RED     : Reduction (add 8 half-byte operands) (R-type)
    // 0111 - PADDSB  : Parallel Add Saturated Byte (4 half-byte additions) 


    ////////////////////////////////////
    // Opcode(4) rd(4), rs(4), imm(4) //
    ////////////////////////////////////
    // 0100 - SLL     : Shift Left Logical (by immediate) 
    // 0101 - SRA     : Shift Right Arithmetic (by immediate) 
    // 0110 - ROR     : Rotate Right (by immediate) 

    ////////////////////////////////////////////////
    // Opcode(4) rt(4), rs(4), twos(offset<<1)(4) //
    ////////////////////////////////////////////////
    // 1000 - LW      : Load Word
    // 1001 - SW      : Store Word

    ///////////////////////////////////////
    // Opcode(4) rd(4), imm(8) //
    ///////////////////////////////////////
    // 1010 - LLB     : Load Lower Byte (immediate)
    // 1011 - LHB     : Load Higher Byte (immediate)

    ////////////
    // Unique //
    ////////////
    // 1100 - B       : Branch with offset   (Opcode ccci iiii iiii) , ccc = condition  as  in Table  1 , iiiiiiiii = 9-bit signed  offset  in  two’s  complement 
    // 1101 - BR      : Branch to Register   (Opcode cccx ssss xxxx) , ccc = condition as in Table 1 , ssss  = encodes the source register rs
    // 1110 - PCS     : Program Counter Save (Opcode dddd xxxx xxxx) , dddd = encodes register rd
    // 1111 - HLT     : Halt execution       (Opcode xxxx xxxx xxxx) , this is a no-op


    // internal signal declaration
    logic [3:0] op;
    
    // assigning opcode to the PC opcode
    assign op = instruction[15:12];

    ////////////////////////////////
    // control signal assignments //
    ////////////////////////////////

    // logic for read register 1 mux control 
    // select alternate register field for LLB and LHB instructions
    assign RR1Mux = (op[15] & ~op[14] & op[13]);

    // logic for read register 2 mux control
    // select instruction[7:4] for most instructions, but use instruction[11:8] for SW
    assign RR2Mux = (op == 4'b1001);

    // logic for immediate value mux control, 2-bit
    // 00: imm4 (SLL, SRA, ROR) : 4-bits = immediate
    // 01: offset4 (LW, SW) : 4-bits = SE(signed <<1)
    // 10: imm8 (LLB, LHB) : 8-bits = ZE(immediate)
    // 11: offset9 (B) : 9-bits = signed << 1
    assign ImmMux[1] = op[3] & (op[2] | (op[1] & op[0])); // 1 for LLB/LHB (101x) or B (1100)
    assign ImmMux[0] = (op[3] & ~op[2] & ~op[1]) |      // 1 for LW/SW (100x)
                      (op[3] & op[2] & op[1] & ~op[0]);  // 1 for B (1100)

    // Logic for ALU select between imm and register 2 data
    // 0: Use reg2 data for ADD, SUB, XOR, RED, PADDSB
    // 1: Use immediate for SLL, SRA, ROR, LW, SW, LLB, LHB, B
    assign ALUSrcMux = (op[2] & ~op[3]) |  // SLL, SRA, ROR
                      (op[3] & ~op[2]) |   // LW, SW
                      (op[3] & op[2] & ~op[1]) | // LLB, LHB
                      (op == 4'b1100);      // B instruction

    // logic for choosing to store data from memory or from ALU
    // 1: memory data (LW)
    assign MemtoRegMux = (op = 4'b1000);

    // logic for putting current PC in write data in reg file and logic for putting current PC or PC + 2 into instruction memory
    assign PCSMux = (op = 4'b1110);

    // logic to stop PC from incrementing
    assign HaltMux = (op == 4'b1111); 

    // logic to determine if we branch to data in register data 1 (using flags)
    assign BranchRegMux = (op == 4'b1101) & take_branch;

    // logic to determine if we branch based on immediate value (using flags)
    assign BranchMux = (op == 4'b1100) & take_branch;

    // logic to enable write to register file
    // enable for arithmetic/logical instructions, LW, LLB, LHB, PCS
    assign RegWrite = ~op[3] |                // All arithmetic/logical (op[3]=0)
                     (op == 4'b1000) |        // LW
                     (op == 4'b1010) |        // LLB
                     (op == 4'b1011) |        // LHB
                     (op == 4'b1110);         // PCS

    // logic to enable write data to memory
    assign MemWrite = (op == 4'b1001); // SW instruction

    // logic to enable using data memory (LW/SW)
    assign DataMemEnable = (op[3] & ~op[2] & ~op[1])


endmodule