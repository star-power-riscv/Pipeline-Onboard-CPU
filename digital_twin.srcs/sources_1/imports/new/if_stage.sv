module if_stage (
    input logic clk,
    input logic reset,
    input logic stall, // stall时所有寄存器保持旧值

    input logic [31:0] pc_address_in, // 如果要跳转，这个值告诉PC下一条指令的地址
    input logic pc_branch_valid, // 跳转使能
    
    // 输出给Instruction Momery
    output logic [31:0] pc_address_out, // 这个信号也要输出给Decode阶段，jump时要用
    
    // 来自Instruction Memory的输入，也就是fetch到的指令
    input logic [31:0] imem_data,

    // 输出给Decode阶段
    output logic [31:0] inst_out // Fetch到的指令
);

    logic [31:0] pc_reg;

    always_ff @( posedge clk ) begin
        if (reset) begin
            pc_reg <= 32'h0000_0000;
        end else if (!stall) begin
            if (pc_branch_valid) begin
                pc_reg <= pc_address_in + 4;
            end else begin
                pc_reg <= pc_reg + 4;
            end
        end
    end

    // PC
    always_comb begin
        pc_address_out = (pc_branch_valid == 1'b1) ? pc_address_in : pc_reg;
    end

    always_comb begin
        inst_out = imem_data;
    end

endmodule