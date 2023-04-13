/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_core (
    input clk,
    input rstn,

    input [31:0] instr,
    input [2:0] cycle,

    output [31:0] data_out,
    output branch
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_core);
  #1;
end
`endif

    reg [4:0] counter;
    always @(posedge clk)
        if (!rstn) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end

    wire branch;
    wire shift_data_out = 1'b0;
    wire pc = 1'b0;
    wire shift_pc;
    nanoV_core core (
        clk,
        rstn,
        instr,
        cycle,
        counter,
        pc,
        shift_data_out,
        shift_pc,
        data_out,
        branch
    );

endmodule