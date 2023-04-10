/* A RISC-V core designed to use minimal area.
  
   This core module takes instructions and produces output data
 */

module nanoV_core (
    input clk,
    input rstn,

    input [31:0] instr,
    input [2:0] cycle,
    input [4:0] counter,

    input shift_data_out,
    output [31:0] data_out,
    output branch
);

    wire is_jal = (instr[6:4] == 3'b110 && instr[2] == 1'b1);
    wire [31:0] i_imm = {{20{instr[31]}}, instr[31:20]};
    reg [31:0] stored_data;

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
    nanoV_alu alu(alu_op, data_rs1, alu_b_in, cy_in, alu_out, cy_out, lts);

    always @(posedge clk) begin
        cy <= cy_out;
    end

    reg [4:0] shift_amt_reg;
    always @(posedge clk) begin
        if (counter < 5 && cycle == 0) begin
            shift_amt_reg[4] <= alu_op[2] ? data_rs2 : ~data_rs2;
            shift_amt_reg[3:0] <= shift_amt_reg[4:1];
        end
    end

    wire [4:0] shift_amt = alu_select_rs2 ? shift_amt_reg : alu_op[2] ? i_imm[4:0] : ~i_imm[4:0];
    wire shifter_out, shift_stored, shift_in;
    nanoV_shift shifter({instr[30],alu_op[2:0]}, counter, stored_data, shift_amt, shifter_out, shift_stored, shift_in);

    assign data_rd = is_jal ? 1'b0 :  // TODO
                     (alu_op[1:0] == 2'b01) ? shifter_out : alu_out;
    assign branch = is_jal;

    // Various instructions require us to buffer a register
    wire store_data_in = (alu_op[1:0] == 2'b01) ? data_rs1 : data_rs2;
    wire do_store = ((alu_op[1:0] == 2'b01) && (cycle == 0 || shift_stored)) || (instr[6:2] == 5'b01000) || shift_data_out;
    always @(posedge clk) begin
        if (do_store) begin
            stored_data[31] <= ((alu_op[1:0] == 2'b01) && (cycle == 1 && shift_stored)) ? shift_in : store_data_in;
            stored_data[30:0] <= stored_data[31:1];
        end
    end

    assign data_out = stored_data;

endmodule