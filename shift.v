/* Shifter for nanoV.

    RISC-V Shift instructions:
      0001 SLL:  D = A << B
      0101 SRL:  D = A >> B (logical)
      1101 SRA:  D = A >> B (signed)
*/

module nanoV_shift (
    input [3:0] op,
    input [4:0] counter,
    input [31:0] a,
    input [4:0] b,
    output d,
    output shift_a,
    output top_bit
);

    assign top_bit = op[3] ? a[31] : 1'b0;

    wire negate = op[2] ? 1'b0 : 1'b1;
    wire [5:0] counter_shifted = {1'b0,counter} + {negate,b} + negate;
    wire a_left = counter_shifted[5] ? 1'b0 : a[0];
    wire a_right = counter_shifted[5] ? top_bit : a[b];

    assign d = op[2] ? a_right : a_left;
    assign shift_a = counter_shifted[5] == 0;

endmodule
