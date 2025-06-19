module id_stage (
    input logic clk,
    input logic reset,
    input logic stall,
    
    input logic [31:0] inst_in, // 指令
    input logic [31:0] pc_address_in, // PC地址

    input logic [4:0] ex_stage_rd_address, // 来自EX阶段的rd地址，用于数据冒险检测
    input logic [31:0] ex_stage_alu_result,

    input logic [4:0] mem_stage_rd_address, // 来自MEM阶段的rd地址，用于数据冒险检测
    input logic [31:0] mem_stage_mem_result,

    input logic [4:0] wb_stage_rd_address, // 来自WB阶段的rd地址，用于数据冒险检测
    input logic [31:0] wb_stage_mem_result,

    input logic ex_stage_load_en, // 来自EX阶段的load_en，用于load-use冲突检测

    // 与寄存器堆交互
    output logic [4:0] rs1_address,
    output logic [4:0] rs2_address,
    input logic [31:0] rs1_data_in,
    input logic [31:0] rs2_data_in,
    
    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] imm,
    output logic [4:0] rd_address,
    
    output logic reg_write_en, // 这条指令是否要写回某个寄存器
    output logic load_en, // 是否要load
    output logic store_en, // 是否要store
    
    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    
    output logic [31:0]  pc_address_out,

    output logic load_use_hazard
);

    assign rs1_address = inst_in[19:15];
    assign rs2_address = inst_in[24:20];
    assign rd_address = inst_in[11:7];

    assign opcode = inst_in[6:0];
    assign funct3 = inst_in[14:12];
    assign funct7 = inst_in[31:25];

    assign load_use_hazard = ex_stage_load_en &&
                             (ex_stage_rd_address != 5'b0) &&
                             ((ex_stage_rd_address == rs1_address) || (ex_stage_rd_address == rs2_address));

    assign rs1_data = (inst_in[19:15] == 5'b00000) ? 32'b0 : // x0 always zero
                      (ex_stage_rd_address == inst_in[19:15]) ? ex_stage_alu_result : 
                      (mem_stage_rd_address == inst_in[19:15] && ex_stage_rd_address != inst_in[19:15]) ? mem_stage_mem_result : 
                      (wb_stage_rd_address == inst_in[19:15]) ? wb_stage_mem_result : rs1_data_in;
    assign rs2_data = (inst_in[24:20] == 5'b00000) ? 32'b0 : // x0 always zero
                      (ex_stage_rd_address == inst_in[24:20]) ? ex_stage_alu_result : 
                      (mem_stage_rd_address == inst_in[24:20] && ex_stage_rd_address != inst_in[24:20]) ? mem_stage_mem_result : 
                      (wb_stage_rd_address == inst_in[24:20]) ? wb_stage_mem_result : rs2_data_in;

    assign pc_address_out = pc_address_in;

    assign reg_write_en = (opcode == 7'b0110111) || // LUI
                          (opcode == 7'b0010111) || // AUIPC
                          (opcode == 7'b1101111) || // JAL
                          (opcode == 7'b1100111) || // JALR
                          (opcode == 7'b0010011) || // I-type ALU
                          (opcode == 7'b0000011) || // Load
                          (opcode == 7'b0110011);   // R-type ALU


    assign load_en = (opcode == 7'b0000011); // Load
    assign store_en = (opcode == 7'b0100011); // Store

    assign imm = (opcode == 7'b0110111) ? {inst_in[31:12], 12'b0} : // LUI
                 (opcode == 7'b0010111) ? {inst_in[31:12], 12'b0} : // AUIPC
                 (opcode == 7'b1101111) ? {{12{inst_in[31]}}, inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0} : // JAL
                 (opcode == 7'b1100111) ? {{20{inst_in[31]}}, inst_in[31:20]} : // JALR
                 (opcode == 7'b1100011) ? {{20{inst_in[31]}}, inst_in[7], inst_in[30:25], inst_in[11:8], 1'b0} : // Branch
                 (opcode == 7'b0000011) ? {{20{inst_in[31]}}, inst_in[31:20]} : // Load
                 (opcode == 7'b0100011) ? {{20{inst_in[31]}}, inst_in[31:25], inst_in[11:7]} : // Store
                 (opcode == 7'b0010011) ? {{20{inst_in[31]}}, inst_in[31:20]} : // I-type ALU
                 32'b0; // Default case

endmodule