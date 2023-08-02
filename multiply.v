/* Multiplier for nanoV
 *
 * 32x32 -> 32 multiply (mullo)
 *
 * Multiply runs over bits(b) cycles.
 * The user provides the 32-bit value a and the low bit of b.
 * Each cycle:
 * a is added to the result if b is true.
 * a is shifted left (by the user).
 * b is shifted right (by the user).
 *
 * The low bit of the result is presented as d.
 * The full result can be read over 32 cycles by holding read_out high,
 * which causes the result to be shifted right.
 */

module nanoV_mul #(parameter A_BITS=32) (
    input clk,

    input [A_BITS-1:0] a,
    input b,

    output d
);

    reg [A_BITS-1:0] accum;
    wire [A_BITS:0] next_accum = {1'b0, accum} + {1'b0, a};

    always @(posedge clk) begin
        accum <= b ? next_accum[A_BITS:1] : {1'b0, accum[A_BITS-1:1]};
    end

    assign d = b ? next_accum[0] : accum[0];

endmodule
