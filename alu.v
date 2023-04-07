/* ALU for nanoV.

    RISC-V ALU instructions:
      0000 ADD:  D = A + B
      1000 SUB:  D = A - B
      0010 SLT:  D = (A < B) ? 1 : 0, comparison is signed
      0011 SLTU: D = (A < B) ? 1 : 0, comparison is unsigned
      0111 AND:  D = A & B
      0110 OR:   D = A | B
      0100 XOR:  D = A ^ B
*/

module nanoV_alu (
    input [3:0] op,
    input a,
    input b,
    input cy_in,
    output d,
    output cy_out,   // On final cycle, 1 for SLTU
    output lts       // On final cycle, 1 for SLT
);

    wire [1:0] a_for_add = {1'b0, a};
    wire [1:0] b_for_add = {1'b0, (op[1] || op[3]) ? ~b : b};
    wire [1:0] sum = a_for_add + b_for_add + cy_in;

    function operate(
        input [2:0] op,
        input a,
        input b,
        input s
    );
        case (op)
            3'b000: operate = s;
            3'b010, 3'b011: operate = 1'b0;
            3'b111: operate = a & b;
            3'b110: operate = a | b;
            3'b100: operate = a ^ b;
        endcase
    endfunction

    assign cy_out = sum[1];
    assign d = operate(op[2:0], a, b, sum[0]);
    assign lts = a ^ b_for_add[0] ^ sum[1];

endmodule
