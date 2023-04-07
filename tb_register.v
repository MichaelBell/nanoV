/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_register (
    input clk,
    input rstn,

    input pause,
    input wr_en,

    input [3:0] rs1,
    input [3:0] rs2,
    input [3:0] rd,

    output reg [31:0] rs1_out,
    output reg [31:0] rs2_out,
    input [31:0] rd_in
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("register.vcd");
  $dumpvars (0, tb_register);
  #1;
end
`endif

    reg [4:0] last_counter;
    wire [4:0] counter = last_counter + (write_pause ? 0 : 1);
    reg write_pause;
    always @(posedge clk)
        if (!rstn) begin
            last_counter <= 0;
            write_pause <= 1;
        end else begin
            last_counter <= counter;
            write_pause <= pause;
        end

    wire data_rs1, data_rs2;
    nanoV_registers registers(clk, rstn, pause, wr_en, rs1, rs2, rd, data_rs1, data_rs2, rd_in[last_counter]);

    always @(posedge clk) begin
        rs1_out[last_counter] <= data_rs1;
        rs2_out[last_counter] <= data_rs2;
    end

endmodule