/* verilator lint_off UNOPTFLAT */
module myCPU (
    input  logic         cpu_rst,
    input  logic         cpu_clk,

    // Interface to IROM
    input  logic [31:0] irom_rdata,          // IROM读数据
    output logic [31:0] irom_addr,           // IROM读地址, 16->12
    
    // Interface to DRAM
    input  logic [31:0] dram_rdata,          // DRAM读数据
    output logic [31:0] dram_addr,           // DRAM地址, 16->32
    output logic [31:0] dram_wdata,          // DRAM写数据
    output logic        dram_we,             // DRAM写使能
    output logic [2:0]  dram_mask            // DRAM写掩码
);
    logic stall;    
    logic flush;
    logic load_use_hazard;

    always_comb begin
        stall = load_use_hazard;
        flush = ex_stage_pc_branch_valid;
    end

    logic [31:0] if_stage_inst_out;
    logic [31:0] if_stage_pc_address_out;
    logic [31:0] if_stage_pc_address_in;
    logic if_stage_pc_branch_valid;

    always_ff @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            if_stage_pc_address_in <= 32'h80000000;
            if_stage_pc_branch_valid <= 1'b0;
        end else begin
            if_stage_pc_address_in <= ex_stage_pc_branch_target;
            if_stage_pc_branch_valid <= ex_stage_pc_branch_valid;
        end
    end

    if_stage if_stage (
        .clk(cpu_clk),
        .reset(cpu_rst),
        .stall(stall),
        .pc_address_in(if_stage_pc_address_in),
        .pc_branch_valid(if_stage_pc_branch_valid),
        .pc_address_out(if_stage_pc_address_out),
        .imem_data(irom_rdata),
        .inst_out(if_stage_inst_out)
    );
    
    assign irom_addr = if_stage_pc_address_out;

    logic [31:0] id_stage_inst_in;
    logic [31:0] id_stage_pc_address_in;
    logic [4:0] id_stage_rs1_address;
    logic [4:0] id_stage_rs2_address;
    logic signed [31:0] id_stage_rs1_data_in;
    logic signed [31:0] id_stage_rs2_data_in;
    logic signed [31:0] id_stage_rs1_data;
    logic signed [31:0] id_stage_rs2_data;
    logic [31:0] id_stage_imm;
    logic [4:0] id_stage_rd_address;
    logic id_stage_reg_write_en;
    logic id_stage_load_en;
    logic id_stage_store_en;
    logic [6:0] id_stage_opcode;
    logic [2:0] id_stage_funct3;
    logic [6:0] id_stage_funct7;
    logic [31:0] id_stage_pc_address_out;

    always_ff @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            id_stage_inst_in <= 32'b0;
            id_stage_pc_address_in <= 32'b0;
        end else if (ex_stage_pc_branch_valid) begin
            id_stage_inst_in <= 32'b0;
            id_stage_pc_address_in <= 32'b0;
        end else if (!stall) begin
            id_stage_inst_in <= if_stage_inst_out;
            id_stage_pc_address_in <= if_stage_pc_address_out;
        end
    end

    id_stage id_stage (
        .clk(cpu_clk),
        .reset(cpu_rst),
        .stall(stall),
        .inst_in(id_stage_inst_in),
        .pc_address_in(id_stage_pc_address_in),
        .rs1_address(id_stage_rs1_address),
        .rs2_address(id_stage_rs2_address),
        .rs1_data_in(regfile_rs1_data),
        .rs2_data_in(regfile_rs2_data),
        .rs1_data(id_stage_rs1_data),
        .rs2_data(id_stage_rs2_data),
        .imm(id_stage_imm),
        .rd_address(id_stage_rd_address),
        .reg_write_en(id_stage_reg_write_en),
        .load_en(id_stage_load_en),
        .store_en(id_stage_store_en),
        .opcode(id_stage_opcode),
        .funct3(id_stage_funct3),
        .funct7(id_stage_funct7),
        .pc_address_out(id_stage_pc_address_out),
        .ex_stage_rd_address(ex_stage_rd_address_out),
        .ex_stage_alu_result(ex_stage_alu_result),
        .ex_stage_load_en(ex_stage_load_en),
        .mem_stage_rd_address(mem_stage_rd_address_out),
        .mem_stage_mem_result(mem_stage_mem_result),
        .wb_stage_rd_address(wb_stage_rd_address),
        .wb_stage_mem_result(wb_stage_mem_result),
        .load_use_hazard(load_use_hazard)
    );

    logic [31:0] ex_stage_pc_address_in;
    logic [31:0] ex_stage_rs1_data;
    logic [31:0] ex_stage_rs2_data;
    logic [31:0] ex_stage_imm;
    logic [4:0] ex_stage_rd_address;
    logic ex_stage_reg_write_en;
    logic ex_stage_load_en;
    logic ex_stage_store_en;
    logic [6:0] ex_stage_opcode;
    logic [2:0] ex_stage_funct3;
    logic [6:0] ex_stage_funct7;
    logic [31:0] ex_stage_alu_result;
    logic [31:0] ex_stage_rs2_data_out;
    logic [4:0] ex_stage_rd_address_out;
    logic ex_stage_reg_write_en_out;
    logic ex_stage_load_en_out;
    logic ex_stage_store_en_out;
    logic [6:0] ex_stage_opcode_out;
    logic [2:0] ex_stage_funct3_out;
    logic [6:0] ex_stage_funct7_out;
    logic ex_stage_pc_branch_valid;
    logic [31:0] ex_stage_pc_branch_target;
    logic [31:0] ex_stage_pc_address_out;

    always_ff @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            ex_stage_pc_address_in <= 32'b0;
            ex_stage_rs1_data <= 32'b0;
            ex_stage_rs2_data <= 32'b0;
            ex_stage_imm <= 32'b0;
            ex_stage_rd_address <= 5'b0;
            ex_stage_reg_write_en <= 1'b0;
            ex_stage_load_en <= 1'b0;
            ex_stage_store_en <= 1'b0;
            ex_stage_opcode <= 7'b0;
            ex_stage_funct3 <= 3'b0;
            ex_stage_funct7 <= 7'b0;
        end else if (flush || stall) begin
            ex_stage_pc_address_in <= 32'b0;
            ex_stage_rs1_data <= 32'b0;
            ex_stage_rs2_data <= 32'b0;
            ex_stage_imm <= 32'b0;
            ex_stage_rd_address <= 5'b0;
            ex_stage_reg_write_en <= 1'b0;
            ex_stage_load_en <= 1'b0;
            ex_stage_store_en <= 1'b0;
            ex_stage_opcode <= 7'b0;
            ex_stage_funct3 <= 3'b0;
            ex_stage_funct7 <= 7'b0;
        end else begin
            ex_stage_pc_address_in <= id_stage_pc_address_out;
            ex_stage_rs1_data <= id_stage_rs1_data;
            ex_stage_rs2_data <= id_stage_rs2_data;
            ex_stage_imm <= id_stage_imm;
            ex_stage_rd_address <= id_stage_rd_address;
            ex_stage_reg_write_en <= id_stage_reg_write_en;
            ex_stage_load_en <= id_stage_load_en;
            ex_stage_store_en <= id_stage_store_en;
            ex_stage_opcode <= id_stage_opcode;
            ex_stage_funct3 <= id_stage_funct3;
            ex_stage_funct7 <= id_stage_funct7;
        end
    end

    ex_stage ex_stage (
        .pc_address_in(ex_stage_pc_address_in),
        .rs1_data(ex_stage_rs1_data),
        .rs2_data(ex_stage_rs2_data),
        .imm(ex_stage_imm),
        .rd_address(ex_stage_rd_address),
        .reg_write_en(ex_stage_reg_write_en),
        .load_en(ex_stage_load_en),
        .store_en(ex_stage_store_en),
        .opcode(ex_stage_opcode),
        .funct3(ex_stage_funct3),
        .funct7(ex_stage_funct7),
        .alu_result(ex_stage_alu_result),
        .rs2_data_out(ex_stage_rs2_data_out),
        .rd_address_out(ex_stage_rd_address_out),
        .reg_write_en_out(ex_stage_reg_write_en_out),
        .load_en_out(ex_stage_load_en_out),
        .store_en_out(ex_stage_store_en_out),
        .funct3_out(ex_stage_funct3_out),
        .funct7_out(ex_stage_funct7_out),
        .opcode_out(ex_stage_opcode_out),
        .pc_branch_valid(ex_stage_pc_branch_valid),
        .pc_branch_target(ex_stage_pc_branch_target),
        .pc_address_out(ex_stage_pc_address_out)
    );

    logic [31:0] mem_stage_alu_result;
    logic [31:0] mem_stage_rs2_data;
    logic [4:0] mem_stage_rd_address;
    logic mem_stage_reg_write_en;
    logic mem_stage_load_en;
    logic mem_stage_store_en;
    logic [6:0] mem_stage_opcode;
    logic [2:0] mem_stage_funct3;
    logic [6:0] mem_stage_funct7;
    logic [31:0] mem_stage_dmem_rdata;
    logic [31:0] mem_stage_dmem_addr;
    logic [31:0] mem_stage_dmem_wdata;
    logic mem_stage_dmem_we;
    logic [31:0] mem_stage_mem_result;
    logic [4:0] mem_stage_rd_address_out;
    logic mem_stage_reg_write_en_out;
    logic [31:0] mem_stage_pc_address_in;
    logic [31:0] mem_stage_pc_address_out;

    always_ff @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            mem_stage_alu_result <= 32'b0;
            mem_stage_rs2_data <= 32'b0;
            mem_stage_rd_address <= 5'b0;
            mem_stage_reg_write_en <= 1'b0;
            mem_stage_load_en <= 1'b0;
            mem_stage_store_en <= 1'b0;
            mem_stage_funct3 <= 3'b0;
            mem_stage_funct7 <= 7'b0;
            mem_stage_pc_address_in <= 32'b0;
        end else begin
            mem_stage_alu_result <= ex_stage_alu_result;
            mem_stage_rs2_data <= ex_stage_rs2_data_out;
            mem_stage_rd_address <= ex_stage_rd_address_out;
            mem_stage_reg_write_en <= ex_stage_reg_write_en_out;
            mem_stage_load_en <= ex_stage_load_en_out;
            mem_stage_store_en <= ex_stage_store_en_out;
            mem_stage_opcode <= ex_stage_opcode_out;
            mem_stage_funct3 <= ex_stage_funct3_out;
            mem_stage_funct7 <= ex_stage_funct7_out;
            mem_stage_pc_address_in <= ex_stage_pc_address_out;
        end
    end

    mem_stage mem_stage (
        .alu_result(mem_stage_alu_result),
        .rs2_data(mem_stage_rs2_data),
        .rd_address(mem_stage_rd_address),
        .reg_write_en(mem_stage_reg_write_en),
        .load_en(mem_stage_load_en),
        .store_en(mem_stage_store_en),
        .opcode(mem_stage_opcode),
        .funct3(mem_stage_funct3),
        .funct7(mem_stage_funct7),
        .dmem_rdata(dram_rdata),
        .dmem_addr(dram_addr),
        .dmem_wdata(dram_wdata),
        .dmem_we(dram_we),
        .dmem_mask(dram_mask),
        .mem_result(mem_stage_mem_result),
        .rd_address_out(mem_stage_rd_address_out),
        .reg_write_en_out(mem_stage_reg_write_en_out),
        .pc_address_in(mem_stage_pc_address_in),
        .pc_address_out(mem_stage_pc_address_out)
    );

    logic [31:0] wb_stage_mem_result;
    logic [4:0] wb_stage_rd_address;
    logic wb_stage_reg_write_en;
    logic [31:0] wb_stage_mem_result_out;
    logic [4:0] wb_stage_rd_address_out;
    logic wb_stage_reg_write_en_out;
    logic [31:0] wb_stage_pc_address_in;
    logic [31:0] wb_stage_pc_address_out;

    always_ff @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            wb_stage_mem_result <= 32'b0;
            wb_stage_rd_address <= 5'b0;
            wb_stage_reg_write_en <= 1'b0;
            wb_stage_pc_address_in <= 32'b0;
        end else begin
            wb_stage_mem_result <= mem_stage_mem_result;
            wb_stage_rd_address <= mem_stage_rd_address_out;
            wb_stage_reg_write_en <= mem_stage_reg_write_en_out;
            wb_stage_pc_address_in <= mem_stage_pc_address_out;
        end
    end

    wb_stage wb_stage (
        .mem_result(wb_stage_mem_result),
        .rd_address(wb_stage_rd_address),
        .reg_we(wb_stage_reg_write_en),
        .mem_result_out(wb_stage_mem_result_out),
        .rd_address_out(wb_stage_rd_address_out),
        .reg_we_out(wb_stage_reg_write_en_out),
        .pc_address_in(wb_stage_pc_address_in),
        .pc_address_out(wb_stage_pc_address_out)
    );

    logic [4:0] regfile_rd_address;
    logic [4:0] regfile_rs1_address;
    logic [4:0] regfile_rs2_address;
    logic [31:0] regfile_rd_data;
    logic [31:0] regfile_rs1_data;
    logic [31:0] regfile_rs2_data;
    logic regfile_we;

    assign regfile_rs1_address = id_stage_rs1_address;
    assign regfile_rs2_address = id_stage_rs2_address;
    assign regfile_rd_address = wb_stage_rd_address_out;
    assign regfile_rd_data = wb_stage_mem_result_out;
    assign regfile_we = wb_stage_reg_write_en_out;

    reg_file reg_file (
        .clk(cpu_clk),
        .rst(cpu_rst),
        .rs1_address(regfile_rs1_address),
        .rs2_address(regfile_rs2_address),
        .rs1_data(regfile_rs1_data),
        .rs2_data(regfile_rs2_data),
        .rd_address(regfile_rd_address),
        .rd_data(regfile_rd_data),
        .we(regfile_we)
    );
    
endmodule
