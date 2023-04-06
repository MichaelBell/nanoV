/* ALU for nanoV.

    RISC-V ALU instructions:
      000 ADD:  D = A + B
      010 SLT:  D = (A < B) ? 1 : 0, comparison is signed
      011 SLTU: D = (A < B) ? 1 : 0, comparison is unsigned
      111 AND:  D = A & B
      110 OR:   D = A | B
      100 XOR:  D = A ^ B
*/

module nanoV_alu (
    input [2:0] op,
    input [31:0] a,
    input [31:0] b,
    output [31:0] d
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("alu.vcd");
  $dumpvars (0, nanoV_alu);
  #1;
end
`endif

    wire a_sgn = op[0] ? 0 : a[31];
    wire b_sgn = op[0] ? 0 : b[31];
    wire [32:0] a_for_sub = {a_sgn, a};
    wire [32:0] b_for_sub = {b_sgn, b};
    wire [32:0] subtract = a_for_sub - b_for_sub;

    function [31:0] operate(
        input [2:0] op,
        input [31:0] a,
        input [31:0] b,
        input s
    );
        case (op)
            3'b000: operate = a + b;
            3'b010, 3'b011: operate = {31'b0,s};
            3'b111: operate = a & b;
            3'b110: operate = a | b;
            3'b100: operate = a ^ b;
        endcase
    endfunction

    assign d = operate(op, a, b, subtract[32]);

endmodule
