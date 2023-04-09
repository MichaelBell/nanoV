/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_alu_register (
    input clk,
    input rstn,

    input [31:0] instr,
    input [1:0] cycle,

    output [31:0] data_out,
    output branch
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_alu_register);
  #1;
end
`endif

    wire branch;
    nanoV_core core (
        clk,
        rstn,
        instr,
        cycle,
        data_out,
        branch
    );

endmodule