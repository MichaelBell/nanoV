/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_top_with_ram (
    input clk,
    input rstn
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_top_with_ram);
  #1;
end
`endif

    wire spi_miso, spi_select, spi_clk, spi_mosi;
    nanoV_top top (
        .clk12MHz(clk),
        .rstn(rstn),
        .spi_miso(spi_miso),
        .spi_select(spi_select),
        .spi_clk_out(spi_clk),
        .spi_mosi(spi_mosi)
    );

    sim_spi_ram spi_ram(
        spi_clk,
        spi_mosi,
        spi_select,
        spi_miso
    );

    defparam spi_ram.INIT_FILE = `PROG_FILE;

    wire is_buffered = 1;

endmodule