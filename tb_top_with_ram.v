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

    wire debug_clk;
    wire [23:0] debug_addr;
    wire [31:0] debug_data;
    sim_spi_ram spi_ram(
        spi_clk,
        spi_mosi,
        spi_select,
        spi_miso,

        debug_clk,
        debug_addr,
        debug_data
    );

    defparam spi_ram.INIT_FILE = `PROG_FILE;
    wire [23:0] start_sig = 24'h`START_SIG;
    wire [23:0] end_sig = 24'h`END_SIG;

    wire is_buffered = 1;

endmodule