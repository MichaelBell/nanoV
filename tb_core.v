/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_core (
    input clk,
    input rstn,

    input [31:0] next_instr,
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

    wire shift_data_out = 1'b0;
    wire pc = 1'b0;
    wire shift_pc;
    wire data_in = 1'b0;
    nanoV_core core (
        clk,
        rstn,
        next_instr[30:2],
        instr[31:2],
        cycle,
        counter,
        pc,
        data_in,
        shift_data_out,
        shift_pc,
        data_out,
        branch
    );

endmodule