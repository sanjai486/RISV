`timescale 1ns/1ps
module tb;
  reg clk, rst;
  integer i;
  riscv_single_cycle_top uut (.clk(clk), .rst(rst));
  initial clk = 0;
  always #5 clk = ~clk;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb);
    rst = 1;
    // Program
    for (i = 0; i < 64; i = i + 1) uut.IMEM.I_mem[i] = 32'b0;
    uut.IMEM.I_mem[0] = 32'h002081B3;  // add x3,x1,x2
    uut.IMEM.I_mem[1] = 32'h40208233;  // sub x4,x1,x2
    uut.IMEM.I_mem[2] = 32'h00302023;  // sw  x3,0(x0)
    uut.IMEM.I_mem[3] = 32'h00002283;  // lw  x5,0(x0)
    uut.IMEM.I_mem[4] = 32'h00518463;  // beq x3,x5,+8  (taken)
    uut.IMEM.I_mem[5] = 32'h40208333;  // sub x6,x1,x2  (skipped)
    uut.IMEM.I_mem[6] = 32'h002083B3;  // add x7,x1,x2
    #16;
    uut.REGS.regs[1] = 32'd5;
    uut.REGS.regs[2] = 32'd3;
    #2 rst = 0;
    #120;
    $display("x3=%0d (exp 8)  x4=%0d (exp 2)  x5=%0d (exp 8)  x6=%0d (exp 0)  x7=%0d (exp 8)  mem[0]=%0d (exp 8)",
             uut.REGS.regs[3], uut.REGS.regs[4], uut.REGS.regs[5],
             uut.REGS.regs[6], uut.REGS.regs[7], uut.DMEM.D_mem[0]);
    $finish;
  end
endmodule
