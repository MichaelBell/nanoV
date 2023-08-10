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
    output reg [31:0] addr,
    output store_data_out
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_cpu);
  #1;
end
`endif

    wire [31:0] ext_data_in;
    wire [31:0] addr_out;
    wire [31:0] data_out;
    wire store_addr_out;
    wire data_in_read;
    nanoV_cpu cpu (
        clk,
        rstn,
        spi_data_in,
        spi_select,
        spi_out,
        spi_clk_enable,
        ext_data_in,
        addr_out,
        data_out,
        store_data_out,
        store_addr_out,
        data_in_read
    );

    always @(posedge clk)
      if (store_data_out)
        data <= data_out;
      else if (store_addr_out)
        addr <= addr_out;

    wire is_buffered = 0;

endmodule