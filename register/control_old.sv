module control (

    input wire [15:0] instruction,      // 16-bit instruction
    output logic RegWrite,              // Register write enable
    output logic [1:0] RegDst,          // Register destination selector (00: rd, 01: rt, 10: r7 for PCS)
    output logic MemRead,               // Memory read enable
    output logic MemWrite,              // Memory write enable
    output logic MemToReg,              // Memory to register (load)
    output logic [3:0] ALUOp,           // ALU operation
    output logic ALUSrc1,               // ALU source 1 (0: register, 1: zero/special)
    output logic [1:0] ALUSrc2,         // ALU source 2 (00: register, 01: immediate, 10: PC, 11: special)
    output logic [2:0] BranchOp,        // Branch operation (condition codes)
    output logic Branch,                // Branch instruction
    output logic BranchReg,             // Branch to register
    output logic [1:0] ImmSrc,          // Immediate source (00: sign ext, 01: zero ext, 10: LLB/LHB)
    output logic LLB,                   // Load Lower Byte
    output logic LHB,                   // Load Higher Byte
    output logic PCWrite,               // PC write enable for HLT
    output logic PCSource,              // PC source (0: PC+2, 1: branch/jump target)
    output logic Halt                   // Halt the processor
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

    // internal signals
    logic [3:0] opcode;
    logic [2:0] branchCode;

    // extract opcode and function fields
    assign opcode = instruction[15:12];
    assign branchCode = instruction[11:9];
    
    // Define instruction types
    logic isALUInstr, isMemInstr, isBranchInstr, isPCSInstr, isHLTInstr, isLIInstr;
    
    // Instruction decode
    always_comb begin
        // Default values
        RegWrite = 1'b0;
        RegDst = 2'b00;      // Default rd is destination
        MemRead = 1'b0;
        MemWrite = 1'b0;
        MemToReg = 1'b0;
        ALUOp = 4'b0000;     // Default ADD
        ALUSrc1 = 1'b0;      // Default use register
        ALUSrc2 = 2'b00;     // Default use register
        BranchOp = 3'b000;
        Branch = 1'b0;
        BranchReg = 1'b0;
        ImmSrc = 2'b00;      // Default sign-extend
        LLB = 1'b0;
        LHB = 1'b0;
        PCWrite = 1'b1;      // Default enable PC increment
        PCSource = 1'b0;     // Default PC+2
        Halt = 1'b0;
        
        // Identify instruction type
        isALUInstr = (opcode <= 4'b0111);                 // ADD, SUB, XOR, RED, SLL, SRA, ROR, PADDSB 
        isMemInstr = (opcode >= 4'b1000 && opcode <= 4'b1011); // LW, SW, LLB, LHB
        isBranchInstr = (opcode == 4'b1100 || opcode == 4'b1101); // B, BR
        isPCSInstr = (opcode == 4'b1110);                // PCS
        isHLTInstr = (opcode == 4'b1111);                // HLT
        isLIInstr = (opcode == 4'b1010 || opcode == 4'b1011); // LLB, LHB
        
        // Decode individual instructions
        case (opcode)

            //////////////////////////
            // Compute instructions //
            //////////////////////////

            4'b0000: begin // ADD
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0000;    // ADD operation
            end
            
            4'b0001: begin // SUB
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0001;    // SUB operation
            end
            
            4'b0010: begin // XOR
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0010;    // XOR operation
            end
            
            4'b0011: begin // RED
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0011;    // RED operation
            end
            
            4'b0100: begin // SLL
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0100;    // Shift Left operation
                ALUSrc2 = 2'b01;    // Use immediate
                ImmSrc = 2'b01;     // Zero extend (4-bit imm)
            end
            
            4'b0101: begin // SRA
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0101;    // Shift Right Arithmetic operation
                ALUSrc2 = 2'b01;    // Use immediate
                ImmSrc = 2'b01;     // Zero extend (4-bit imm)
            end
            
            4'b0110: begin // ROR
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0110;    // Rotate Right operation
                ALUSrc2 = 2'b01;    // Use immediate
                ImmSrc = 2'b01;     // Zero extend (4-bit imm)
            end
            
            4'b0111: begin // PADDSB
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                ALUOp = 4'b0111;    // Parallel Add Saturated Byte operation
            end

            /////////////////////////
            // Memory instructions //
            /////////////////////////

            4'b1000: begin // LW
                RegWrite = 1'b1;
                RegDst = 2'b01;     // rt
                MemRead = 1'b1;
                MemToReg = 1'b1;
                ALUOp = 4'b0000;    // ADD for address calculation
                ALUSrc2 = 2'b01;    // Use immediate
                ImmSrc = 2'b00;     // Sign extend (offset)
            end
            
            4'b1001: begin // SW
                MemWrite = 1'b1;
                ALUOp = 4'b0000;    // ADD for address calculation
                ALUSrc2 = 2'b01;    // Use immediate
                ImmSrc = 2'b00;     // Sign extend (offset)
            end
            
            4'b1010: begin // LLB
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                LLB = 1'b1;
                ImmSrc = 2'b10;     // 8-bit immediate
            end
            
            4'b1011: begin // LHB
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd
                LHB = 1'b1;
                ImmSrc = 2'b10;     // 8-bit immediate
            end

            //////////////////////////
            // Control instructions //
            //////////////////////////

            4'b1100: begin // B
                Branch = 1'b1;
                BranchOp = branchCode;
                PCSource = 1'b1;
                ImmSrc = 2'b00;     // Sign extend (offset)
            end
            
            4'b1101: begin // BR
                Branch = 1'b1;
                BranchReg = 1'b1;
                BranchOp = branchCode;
                PCSource = 1'b1;
            end
            
            4'b1110: begin // PCS
                RegWrite = 1'b1;
                RegDst = 2'b00;     // rd 
                ALUOp = 4'b0000;    // ADD
                ALUSrc1 = 1'b0;     // Use PC
                ALUSrc2 = 2'b10;    // Use constant 2
            end
            
            4'b1111: begin // HLT
                PCWrite = 1'b0;     // Disable PC increment
                Halt = 1'b1;
            end
            
            default: begin
                // Invalid opcode, explicitly set to default values (NOP)
                RegWrite = 1'b0;
                RegDst = 2'b00;
                MemRead = 1'b0;
                MemWrite = 1'b0;
                MemToReg = 1'b0;
                ALUOp = 4'b0000;
                ALUSrc1 = 1'b0;
                ALUSrc2 = 2'b00;
                BranchOp = 3'b000;
                Branch = 1'b0;
                BranchReg = 1'b0;
                ImmSrc = 2'b00;
                LLB = 1'b0;
                LHB = 1'b0;
                PCWrite = 1'b1;
                PCSource = 1'b0;
                Halt = 1'b0;
            end
        endcase
    end
    
endmodule