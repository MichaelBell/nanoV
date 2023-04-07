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

    reg [4:0] last_counter;
    wire [4:0] counter = last_counter + (write_pause ? 0 : 1);
    reg write_pause;
    always @(posedge clk)
        if (!rstn) begin
            last_counter <= 0;
            write_pause <= 1;
        end else begin
            last_counter <= counter;
            write_pause <= slt_pause[2];
        end

    wire [31:0] i_imm = {{20{instr[31]}}, instr[31:20]};

    wire [3:0] rs1 = instr[18:15];
    wire [3:0] rs2 = instr[23:20];
    reg [3:0] rd;
    wire data_rs1, data_rs2, data_rd;
    wire wr_en = alu_write;
    //wire pause = 1'b0;
    nanoV_registers registers(clk, rstn, write_pause, wr_en, rs1, rs2, rd, data_rs1, data_rs2, data_rd);
    always @(posedge clk) begin
        if (!write_pause)
            rd <= instr[10:7];
    end

    reg cy;
    wire [3:0] next_alu_op = {instr[30] && instr[5],instr[14:12]};
    reg [3:0] alu_op;
    reg alu_select_rs2;
    reg alu_write;
    reg alu_imm;
    wire alu_b_in = alu_select_rs2 ? data_rs2 : alu_imm;
    wire cy_in = (last_counter == 0) ? (alu_op[1] || alu_op[3]) : cy;
    wire alu_out, cy_out, lts;
    reg [2:0] slt_pause;
    reg [1:0] slt;
    wire slt_pause_req = (counter == 5'b11111) && (alu_op[2:1] == 2'b01) && instr[4] && !slt_pause[1];
    assign data_rd = slt_pause[0] ? slt[0] : alu_out;
    nanoV_alu alu(alu_op, data_rs1, alu_b_in, cy_in, alu_out, cy_out, lts);

    always @(posedge clk) begin
        if (!rstn) begin
            slt_pause <= 3'b001;  // Must set slt_pause[0] to 1 to avoid possible loop assigning data_rd.
            alu_op <= 0;
        end else begin
            slt_pause <= {slt_pause_req, slt_pause[2:1]};
            alu_op <= next_alu_op;
        end

        cy <= cy_out;

        alu_select_rs2 <= instr[5];
        if (!write_pause)
            alu_write <= (instr[4:0] == 5'b10011);
        alu_imm <= i_imm[counter];

        slt[1] <= alu_op[0] == 1 ? ~cy_out : lts;
        slt[0] <= slt[1];
    end

    // Basic support for Store
    always @(posedge clk)
        if (instr[6:0] == 7'b0100011)
            data_out[last_counter] <= data_rs2;

endmodule