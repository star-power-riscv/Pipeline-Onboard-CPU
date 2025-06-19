module wb_stage (
    // Inputs from MEM stage
    input  logic [31:0] mem_result,
    input  logic [4:0]  rd_address,
    input  logic        reg_we,

    // Outputs to the register file
    output logic [31:0] mem_result_out,
    output logic [4:0]  rd_address_out,
    output logic        reg_we_out,

    input  logic [31:0] pc_address_in, // 输入的PC地址
    output logic [31:0] pc_address_out // 输出的PC地址
);
    assign mem_result_out = mem_result;
    assign rd_address_out = rd_address;
    assign reg_we_out = reg_we;
    assign pc_address_out = pc_address_in;
endmodule
