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
            write_pause <= 0;
        end

    wire [31:0] i_imm = {{20{instr[31]}}, instr[31:20]};

    wire [3:0] rs1 = instr[18:15];
    wire [3:0] rs2 = instr[23:20];
    reg [3:0] rd;
    wire data_rs1, data_rs2, data_rd;
    wire wr_en = alu_write;
    wire pause = 1'b0;
    nanoV_registers registers(clk, rstn, pause, wr_en, rs1, rs2, rd, data_rs1, data_rs2, data_rd);
    always @(posedge clk) begin
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
    wire cy_out, lts;
    nanoV_alu alu(alu_op, data_rs1, alu_b_in, cy_in, data_rd, cy_out, lts);

    always @(posedge clk) begin
        cy <= cy_out;

        alu_op <= next_alu_op;
        alu_select_rs2 <= instr[5];
        alu_write <= (instr[4:0] == 5'b10011);
        alu_imm <= i_imm[counter];

        // TODO: SLT support using pause
        /*if (counter == 5'b11111)
            if (op[2:0] == 3'b011)
                d[0] <= ~cy_out;
            else if (op[2:0] == 3'b010)
                d[0] <= lts; */
    end

    // Basic support for Store
    always @(posedge clk)
        if (instr[6:0] == 7'b0100011)
            data_out[last_counter] <= data_rs2;

endmodule