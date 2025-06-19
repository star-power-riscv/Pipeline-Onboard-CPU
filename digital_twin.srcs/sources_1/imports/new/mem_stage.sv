module mem_stage (
    input logic [31:0] alu_result, // 地址或计算结果
    input logic [31:0] rs2_data, // store 写数据
    input logic [4:0] rd_address, // 目的寄存器
    
    input logic reg_write_en, // 这条指令是否要写回某个寄存器
    input logic load_en, // 是否要load
    input logic store_en, // 是否要store
    
    input logic [6:0] opcode, // 用于生成掩码
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    // 与data memory通信
    input logic [31:0] perip_rdata, // 从dmem读回的数据
    output logic [31:0] perip_addr, // 发给dmem的地址
    output logic [31:0] perip_wdata, // 写给dmem的数据
    output logic perip_wen, // 写使能
    output logic [2:0] perip_mask, // 字节使能，有些指令只需要对dmem写入目标字节, 2->3

    // 输出给WB stage
    output logic [31:0] mem_result, // 输出到WB的数据（可能是来自ALU或DMEM）
    output logic [4:0] rd_address_out,
    output logic reg_write_en_out,

    input [31:0] pc_address_in, // 输入的PC地址
    output logic [31:0] pc_address_out // 输出的PC地址
);

    assign perip_wen = store_en;
    
    assign rd_address_out = rd_address;
    assign reg_write_en_out = reg_write_en;

    assign pc_address_out = pc_address_in;

    // 删去了本文件中的掩码数据处理逻辑，在dram_driver中已有
    // 本文件只需提供掩码即可，如下
    always_comb begin
        case(opcode)
            7'b0000011: begin // Load 指令
                case(funct3)
                    3'b000: begin // LB
                        perip_mask = 3'b000;
                        perip_addr = alu_result;
                        mem_result = perip_rdata;
                    end
                    3'b001: begin // LH
                        perip_mask = 3'b001;
                        perip_addr = alu_result;
                        mem_result = perip_rdata;
                    end
                    3'b010: begin // LW
                        perip_mask = 3'b010;
                        perip_addr = alu_result;
                        mem_result = perip_rdata;
                    end
                    3'b100: begin // LBU
                        perip_mask = 3'b100;
                        perip_addr = alu_result;
                        mem_result = perip_rdata;
                    end
                    3'b101: begin // LHU
                        perip_mask = 3'b101;
                        perip_addr = alu_result;
                        mem_result = perip_rdata;
                    end
                    default: begin
                        perip_mask = 3'b000;
                        mem_result = 32'd0;
                    end
                endcase
            end
            7'b0100011: begin // Store 指令
                case(funct3)
                    3'b000: begin // SB
                        perip_mask = 3'b000;
                        perip_addr = alu_result;
                        perip_wdata = rs2_data;
                    end
                    3'b001: begin // SH
                        perip_mask = 3'b001;
                        perip_addr = alu_result;
                        perip_wdata = rs2_data;
                    end
                    3'b010: begin // SW
                        perip_mask = 3'b010;
                        perip_addr = alu_result;
                        perip_wdata = rs2_data;
                    end
                    default: begin
                        perip_mask = 3'b000;
                        perip_wdata = 32'd0;
                    end
                endcase
            end
            default: begin // 其他指令
                mem_result = alu_result;
                perip_mask = 3'b000; // 默认不与DMEM交互
                perip_addr = 32'd0;
                perip_wdata = 32'd0;
            end
        endcase
    end

endmodule