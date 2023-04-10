/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_cpu (
    input clk,
    input rstn,

    input spi_data_in,

    output spi_select,
    output spi_out
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_cpu);
  #1;
end
`endif

    wire branch;
    nanoV_cpu cpu (
        clk,
        rstn,
        spi_data_in,
        spi_select,
        spi_out
    );

endmodule