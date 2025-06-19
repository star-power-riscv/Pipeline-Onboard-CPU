module reg_file (
  input logic clk,
  input logic rst,
  input logic [4:0] rs1_address,
  input logic [4:0] rs2_address,
  output logic [31:0] rs1_data,
  output logic [31:0] rs2_data,
  
  input logic [4:0] rd_address,
  input logic [31:0] rd_data,
  
  input logic we
);
  logic [31:0] regs[31:0];
  
  assign rs1_data = regs[rs1_address];
  assign rs2_data = regs[rs2_address];
  
  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 32; i++) begin
        regs[i] <= 32'b0;
      end
    end else if (we && rd_address != 5'b0) begin
      regs[rd_address] <= rd_data;
    end
  end
endmodule