/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_cpu (
    input clk,
    input rstn,

    input spi_data_in,

    output spi_select,
    output spi_out,
    output spi_clk_enable,

    output reg [31:0] data,
    output store_data_out
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_cpu);
  #1;
end
`endif

    wire [31:0] data_out;
    nanoV_cpu cpu (
        clk,
        rstn,
        spi_data_in,
        spi_select,
        spi_out,
        spi_clk_enable,
        data_out,
        store_data_out
    );

    always @(posedge clk)
      if (store_data_out)
        data <= data_out;

    wire is_buffered = 0;

endmodule