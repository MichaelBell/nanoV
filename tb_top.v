/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_top (
    input clk,
    input rstn,

    input spi_data_in,

    output spi_select,
    output spi_out,
    output spi_clk
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_top);
  #1;
end
`endif

    nanoV_top top (
        .clk12MHz(clk),
        .rstn(rstn),
        .spi_miso(spi_data_in),
        .spi_select(spi_select),
        .spi_clk_out(spi_clk),
        .spi_mosi(spi_out)
    );

    wire is_buffered = 1;

endmodule