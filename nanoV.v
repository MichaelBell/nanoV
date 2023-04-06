/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module nanoV (
    input clk,

    input [2:0] op,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] d
);

    wire [31:0] op_res;
    nanoV_alu alu(op, a, b, op_res);

    always @(posedge clk)
        d <= op_res;

endmodule