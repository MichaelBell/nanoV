/* A RISC-V core designed to use minimal area.
  
   Aim is to support RV32E 
 */

module tb_alu_register (
    input clk,
    input rstn,

    input [31:0] instr,

    output reg [31:0] data_out
);

`ifdef COCOTB_SIM
initial begin
  $dumpfile ("nanoV.vcd");
  $dumpvars (0, tb_alu_register);
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

    wire [31:0] i_imm = {{20{instr[31]}}, instr[31:20]};

    wire [3:0] rs1 = instr[18:15];
    wire [3:0] rs2 = instr[23:20];
    wire [3:0] rd = instr[10:7];
    wire data_rs1, data_rs2, data_rd;
    wire data_rd_next = slt;
    wire wr_en = alu_write;
    wire wr_next_en = slt_req;
    wire read_through = slt_req;
    nanoV_registers registers(clk, rstn, wr_en, wr_next_en, read_through, rs1, rs2, rd, data_rs1, data_rs2, data_rd, data_rd_next);

    reg cy;
    wire [3:0] alu_op = {instr[30] && instr[5],instr[14:12]};
    wire alu_select_rs2 = instr[5];
    wire alu_write = (instr[4:0] == 5'b10011);
    wire alu_imm = i_imm[counter];
    wire alu_b_in = alu_select_rs2 ? data_rs2 : alu_imm;
    wire cy_in = (counter == 0) ? (alu_op[1] || alu_op[3]) : cy;
    wire alu_out, cy_out, lts;
    wire slt = alu_op[0] == 1 ? ~cy_out : lts;
    wire slt_req = (counter == 5'b11111) && (alu_op[2:1] == 2'b01) && instr[4];
    assign data_rd = alu_out;
    nanoV_alu alu(alu_op, data_rs1, alu_b_in, cy_in, alu_out, cy_out, lts);

    always @(posedge clk) begin
        cy <= cy_out;
    end

    // Basic support for Store
    always @(posedge clk)
        if (instr[6:0] == 7'b0100011)
            data_out[counter] <= data_rs2;

endmodule