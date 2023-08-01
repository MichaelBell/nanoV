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

module nanoV_mul (
    input clk,
    input rstn,

    input [31:0] a,
    input b,

    input read_out,
    output d
);

    reg [31:0] accum;

    always @(posedge clk) begin
        if (!rstn) begin
            accum <= 0;
        end else begin
            if (read_out) accum <= {1'b0, accum[31:1]};
            else if (b) accum <= accum + a;
            else accum <= accum;
        end
    end

    assign d = accum[0];

endmodule
