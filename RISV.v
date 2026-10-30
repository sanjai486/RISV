module pc_plus4(from_pc, next_pc);
  input  [31:0] from_pc;
  output [31:0] next_pc;
  assign next_pc = from_pc + 32'd4;
endmodule

module program_counter(clk, rst, pc_in, pc_out);
  input clk, rst;
  input  [31:0] pc_in;
  output reg [31:0] pc_out;
  always @(posedge clk or posedge rst) begin
    if (rst) pc_out <= 32'b0;
    else     pc_out <= pc_in;
  end
endmodule

module instruction_mem(read_address, instruct_out);
  input  [31:0] read_address;         
  output [31:0] instruct_out;
  reg [31:0] I_mem [0:63];
  assign instruct_out = I_mem[read_address];
endmodule

module register_file(clk, rst, rs1, rs2, rd, write_data, reg_write, read_data1, read_data2);
  input clk, rst, reg_write;
  input  [4:0]  rs1, rs2, rd;
  input  [31:0] write_data;
  output [31:0] read_data1, read_data2;
  reg [31:0] regs [0:31];
  integer k;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (k = 0; k < 32; k = k + 1)
        regs[k] <= 32'b0;
    end
    else if (reg_write && rd != 5'd0)
      regs[rd] <= write_data;
  end
  assign read_data1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
  assign read_data2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];
endmodule

module Imm_gen(opcode, instruct, ImmExt);
  input  [6:0]  opcode;
  input  [31:0] instruct;
  output reg [31:0] ImmExt;
  always @(*) begin
    case (opcode)
      7'b0000011: ImmExt = {{20{instruct[31]}}, instruct[31:20]};                                         // lw
      7'b0100011: ImmExt = {{20{instruct[31]}}, instruct[31:25], instruct[11:7]};                         // sw
      7'b1100011: ImmExt = {{20{instruct[31]}}, instruct[7], instruct[30:25], instruct[11:8], 1'b0};      // beq
      default:    ImmExt = 32'b0;
    endcase
  end
endmodule

module control_unit(instruction, branch, memread, memtoreg, ALUop, memwrite, ALUsrc, regwrite);
  input  [6:0] instruction;
  output reg branch, memread, memtoreg, memwrite, ALUsrc, regwrite;
  output reg [1:0] ALUop;
  always @(*) begin
    case (instruction)
      7'b0110011: {ALUsrc,memtoreg,regwrite,memread,memwrite,branch,ALUop} = 8'b001000_10; // R-type
      7'b0000011: {ALUsrc,memtoreg,regwrite,memread,memwrite,branch,ALUop} = 8'b111100_00; // lw
      7'b0100011: {ALUsrc,memtoreg,regwrite,memread,memwrite,branch,ALUop} = 8'b100010_00; // sw
      7'b1100011: {ALUsrc,memtoreg,regwrite,memread,memwrite,branch,ALUop} = 8'b000001_01; // beq
      default:    {ALUsrc,memtoreg,regwrite,memread,memwrite,branch,ALUop} = 8'b000000_00;
    endcase
  end
endmodule

module ALU_unit(a, b, control_in, ALU_result, zero);
  input  [31:0] a, b;
  input  [3:0]  control_in;
  output reg [31:0] ALU_result;
  output zero;
  always @(*) begin
    case (control_in)
      4'b0000: ALU_result = a & b;
      4'b0001: ALU_result = a | b;
      4'b0010: ALU_result = a + b;
      4'b0110: ALU_result = a - b;
      default: ALU_result = 32'b0;
    endcase
  end
  assign zero = (ALU_result == 32'b0);
endmodule

module ALU_control(ALUop, fun7, fun3, control_out);
  input fun7;
  input [2:0] fun3;
  input [1:0] ALUop;
  output reg [3:0] control_out;
  always @(*) begin
    case (ALUop)
      2'b00:   control_out = 4'b0010;            // lw/sw: add
      2'b01:   control_out = 4'b0110;            // beq: subtract
      default: begin                              // R-type
        case ({fun7, fun3})
          4'b0_000: control_out = 4'b0010;       // add
          4'b1_000: control_out = 4'b0110;       // sub
          4'b0_111: control_out = 4'b0000;       // and
          4'b0_110: control_out = 4'b0001;       // or
          default:  control_out = 4'b0010;
        endcase
      end
    endcase
  end
endmodule

module data_mem(clk, rst, memwrite, memread, read_address, write_data, memdata_out);
  input clk, rst, memwrite, memread;
  input  [31:0] read_address, write_data;   // word address
  output [31:0] memdata_out;
  reg [31:0] D_mem [0:63];
  integer k;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      for (k = 0; k < 64; k = k + 1)
        D_mem[k] <= 32'b0;
    end
    else if (memwrite)
      D_mem[read_address] <= write_data;
  end
  assign memdata_out = memread ? D_mem[read_address] : 32'b0;
endmodule

module mux1(sel1, a1, b1, mux1_out);
  input sel1;
  input  [31:0] a1, b1;
  output [31:0] mux1_out;
  assign mux1_out = (sel1 == 1'b0) ? a1 : b1;
endmodule

module mux2(sel2, a2, b2, mux2_out);
  input sel2;
  input  [31:0] a2, b2;
  output [31:0] mux2_out;
  assign mux2_out = (sel2 == 1'b0) ? a2 : b2;
endmodule

module mux3(sel3, a3, b3, mux3_out);
  input sel3;
  input  [31:0] a3, b3;
  output [31:0] mux3_out;
  assign mux3_out = (sel3 == 1'b0) ? a3 : b3;
endmodule

module and_logic(branch, zero, and_out);
  input branch, zero;
  output and_out;
  assign and_out = branch & zero;
endmodule

module adder(in_1, in_2, sum_out);
  input  [31:0] in_1, in_2;
  output [31:0] sum_out;
  assign sum_out = in_1 + in_2;
endmodule

// ------------------------------------------------------------------
// Top level
// ------------------------------------------------------------------
module riscv_single_cycle_top(clk, rst);
  input clk, rst;

  wire [31:0] pc_out, pc_next, pc_plus4_w, branch_target;
  wire [31:0] instr;
  wire [31:0] rd1, rd2, imm, alu_b, alu_result, mem_rdata, wb_data;
  wire [3:0]  alu_ctrl;
  wire [1:0]  aluop;
  wire        branch, memread, memtoreg, memwrite, alusrc, regwrite;
  wire        zero, pcsrc;

  // Fetch
  program_counter PC (.clk(clk), .rst(rst), .pc_in(pc_next), .pc_out(pc_out));

  pc_plus4 PC_PLUS4 (.from_pc(pc_out), .next_pc(pc_plus4_w));

  instruction_mem IMEM (.read_address({2'b00, pc_out[31:2]}), .instruct_out(instr));

  // Decode
  control_unit CTRL (
    .instruction(instr[6:0]),
    .branch(branch), .memread(memread), .memtoreg(memtoreg),
    .ALUop(aluop), .memwrite(memwrite), .ALUsrc(alusrc), .regwrite(regwrite)
  );

  register_file REGS (
    .clk(clk), .rst(rst),
    .rs1(instr[19:15]), .rs2(instr[24:20]), .rd(instr[11:7]),
    .write_data(wb_data), .reg_write(regwrite),
    .read_data1(rd1), .read_data2(rd2)
  );

  Imm_gen IMMGEN (.opcode(instr[6:0]), .instruct(instr), .ImmExt(imm));

  // Execute
  mux2 ALUSRC_MUX (.sel2(alusrc), .a2(rd2), .b2(imm), .mux2_out(alu_b));

  ALU_control ALUCTRL (
    .ALUop(aluop), .fun7(instr[30]), .fun3(instr[14:12]), .control_out(alu_ctrl)
  );

  ALU_unit ALU (
    .a(rd1), .b(alu_b), .control_in(alu_ctrl),
    .ALU_result(alu_result), .zero(zero)
  );

  adder BRANCH_ADDER (.in_1(pc_out), .in_2(imm), .sum_out(branch_target));

  and_logic BRANCH_AND (.branch(branch), .zero(zero), .and_out(pcsrc));

  mux1 PC_MUX (.sel1(pcsrc), .a1(pc_plus4_w), .b1(branch_target), .mux1_out(pc_next));

  // Memory / Writeback
  data_mem DMEM (
    .clk(clk), .rst(rst), .memwrite(memwrite), .memread(memread),
    .read_address({2'b00, alu_result[31:2]}),
    .write_data(rd2), .memdata_out(mem_rdata)
  );

  mux3 WB_MUX (.sel3(memtoreg), .a3(alu_result), .b3(mem_rdata), .mux3_out(wb_data));

endmodule
