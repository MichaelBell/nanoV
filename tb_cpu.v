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
        data_out,
        store_data_out,
        store_addr_out,
        data_in_read
    );

    wire [31:0] reversed_data_out;
    genvar i;
    generate 
      for (i=0; i<32; i=i+1) assign reversed_data_out[i] = data_out[31-i]; 
    endgenerate

    always @(posedge clk)
      if (store_data_out)
        data <= reversed_data_out;
      else if (store_addr_out)
        addr <= data_out;

    wire is_buffered = 0;

endmodule