/*
  Execute Stage for RV32I (37 instructions, excluding fence/ecall/ebreak)
  - Computes ALU results for arithmetic, logical, load/store address calc, branches, and jumps.
  - Passes through rs2_data for store operations.
  - Propagates control signals and rd address.
  - No signal omitted to ensure proper connection with other pipeline stages.
*/

module ex_stage (
  input  logic [31:0] pc_address_in,       // PC address of this instruction
  input  logic [31:0] rs1_data,            // Register source 1 value
  input  logic [31:0] rs2_data,            // Register source 2 value
  input  logic [31:0] imm,                 // Immediate value (signed extended)
  input  logic [4:0]  rd_address,          // Destination register address

  input  logic        reg_write_en,        // Will write back to register
  input  logic        load_en,             // Load instruction
  input  logic        store_en,            // Store instruction

  input  logic [6:0]  opcode,              // Main opcode field
  input  logic [2:0]  funct3,              // Function3 field
  input  logic [6:0]  funct7,              // Function7 field

  output logic [31:0] alu_result,          // ALU computation result
  output logic [31:0] rs2_data_out,        // Forwarded rs2 for store data
  output logic [4:0]  rd_address_out,      // Forwarded rd address
  output logic        reg_write_en_out,    // Forwarded reg write enable
  output logic        load_en_out,         // Forwarded load enable
  output logic        store_en_out,        // Forwarded store enable
  output logic [6:0]  opcode_out,          // Forwarded opcode
  output logic [2:0]  funct3_out,          // Forwarded funct3
  output logic [6:0]  funct7_out,          // Forwarded funct7
  output logic        pc_branch_valid,     // Branch valid signal
  output logic [31:0] pc_branch_target,    // Branch target address
  output logic [31:0] pc_address_out       // Forwarded PC address
);

  // Default pass-through of control signals and data
  assign rs2_data_out     = rs2_data;
  assign rd_address_out   = (opcode != 7'b1100011 && opcode != 7'b0100011) ? rd_address : 5'b0; // rd_address is not used in branch/store
  assign reg_write_en_out = reg_write_en;
  assign load_en_out      = load_en;
  assign store_en_out     = store_en;
  assign funct3_out       = funct3;
  assign funct7_out       = funct7;
  assign opcode_out       = opcode;
  assign pc_address_out   = pc_address_in;

  // ALU operation: combinational
  always_comb begin
    unique case (opcode)
      // *** R-type instructions ***
      7'b0110011: begin
        unique casez ({funct7, funct3})
          10'b0000000_000: alu_result = rs1_data + rs2_data;     // ADD
          10'b0100000_000: alu_result = rs1_data - rs2_data;     // SUB
          10'b0000000_001: alu_result = rs1_data << rs2_data[4:0]; // SLL
          10'b0000000_010: alu_result = ($signed(rs1_data) < $signed(rs2_data)) ? 32'd1 : 32'd0; // SLT
          10'b0000000_011: alu_result = (rs1_data < rs2_data) ? 32'd1 : 32'd0; // SLTU
          10'b0000000_100: alu_result = rs1_data ^ rs2_data;     // XOR
          10'b0000000_101: alu_result = rs1_data >> rs2_data[4:0]; // SRL
          10'b0100000_101: alu_result = $signed(rs1_data) >>> rs2_data[4:0]; // SRA
          10'b0000000_110: alu_result = rs1_data | rs2_data;     // OR
          10'b0000000_111: alu_result = rs1_data & rs2_data;     // AND
          default:         alu_result = 32'd0;
        endcase
      end

      // *** I-type ALU instructions ***
      7'b0010011: begin
        unique case (funct3)
          3'b000: alu_result = rs1_data + imm;                   // ADDI
          3'b010: alu_result = ($signed(rs1_data) < $signed(imm)) ? 32'd1 : 32'd0; // SLTI
          3'b011: alu_result = (rs1_data < imm) ? 32'd1 : 32'd0;  // SLTIU
          3'b100: alu_result = rs1_data ^ imm;                   // XORI
          3'b110: alu_result = rs1_data | imm;                   // ORI
          3'b111: alu_result = rs1_data & imm;                   // ANDI
          3'b001: alu_result = rs1_data << imm[4:0];             // SLLI
          3'b101: begin
            if (funct7 == 7'b0000000)
              alu_result = rs1_data >> imm[4:0];                 // SRLI
            else
              alu_result = $signed(rs1_data) >>> imm[4:0];       // SRAI
          end
          default: alu_result = 32'd0;
        endcase
      end

      // *** Load upper immediate (LUI) ***
      7'b0110111: alu_result = imm;                              // LUI

      // *** Add upper immediate to PC (AUIPC) ***
      7'b0010111: alu_result = pc_address_in + imm;             // AUIPC

      // *** JAL: jump and link ***
      7'b1101111: alu_result = pc_address_in + 32'd4;           // Write PC+4 into rd

      // *** JALR: jump and link register ***
      7'b1100111: alu_result = pc_address_in + 32'd4;           // Write PC+4 into rd (target externally: (rs1+imm)&~1)

      // *** Branch instructions: target calc here, decision in MEM/WB ***
      7'b1100011: alu_result = 32'd0;                           // NO need here

      // *** Load: address calc ***
      7'b0000011: alu_result = rs1_data + imm;                  // Load address

      // *** Store: address calc ***
      7'b0100011: alu_result = rs1_data + imm;                  // Store address

      default: alu_result = 32'd0;
    endcase
  end

  // Branch/jump flag
  always_comb begin
    unique case (opcode)
      7'b1101111: begin // JAL
        pc_branch_valid = 1'b1;
        pc_branch_target = pc_address_in + imm; // JAL target
      end
      7'b1100111: begin// JALR
        pc_branch_valid = 1'b1;
        pc_branch_target = (rs1_data + imm) & 32'hFFFFFFFE; // JALR target
      end
      7'b1100011: begin// Branch
        unique case (funct3)
          3'b000: pc_branch_valid = (rs1_data == rs2_data);     // BEQ
          3'b001: pc_branch_valid = (rs1_data != rs2_data);     // BNE
          3'b100: pc_branch_valid = ($signed(rs1_data) < $signed(rs2_data)); // BLT
          3'b101: pc_branch_valid = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
          3'b110: pc_branch_valid = (rs1_data < rs2_data);       // BLTU
          3'b111: pc_branch_valid = (rs1_data >= rs2_data);      // BGEU
          default: pc_branch_valid = 1'b0;
        endcase
        pc_branch_target = pc_address_in + imm; // Branch target
      end
      default:begin
        pc_branch_valid = 1'b0;
        pc_branch_target = 32'd0; // No branch target for non-branch instructions
      end
    endcase
  end

endmodule
