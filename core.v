/* A RISC-V core designed to use minimal area.
  
   This core module takes instructions and produces output data
 */

module nanoV_core #(parameter NUM_REGS=16, parameter REG_ADDR_BITS=4) (
    input clk,
    input rstn,

    input [30:2] next_instr,
    input [31:2] instr,
    input [2:0] cycle,
    input [4:0] counter,
    input pc,
    input data_in,
    input ext_data_in,
    input use_ext_data_in,

    input shift_data_out,
    output shift_pc,
    output [31:0] data_out,
    output branch
);

    wire is_jmp = (instr[6:4] == 3'b110 && instr[2] == 1'b1);
    wire is_jal = is_jmp && instr[3];
    wire is_branch = (instr[6:2] == 5'b11000);
    wire is_mem = (instr[6] == 0 && instr[4:2] == 0);
    wire is_store = instr[5];
    wire is_load_upper = (instr[6] == 0 && instr[4:2] == 3'b101);
    wire is_mul = (instr[25] && instr[5:4] == 2'b11 && instr[2] == 1'b0);

    wire [31:0] i_imm = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] s_imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] b_imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] u_imm = {instr[31:12], 12'h000};
    wire [31:0] j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    reg [31:0] stored_data;

    wire [REG_ADDR_BITS-1:0] rs1 = instr[REG_ADDR_BITS+14:15];
    wire [REG_ADDR_BITS-1:0] rs2 = instr[REG_ADDR_BITS+19:20];
    wire [REG_ADDR_BITS-1:0] rd = instr[REG_ADDR_BITS+6:7];
    wire data_rs1, data_rs2, data_rd;
    wire data_rd_next = slt;

    wire last_count = (counter == 31);
    wire [REG_ADDR_BITS-1:0] next_rs1 = last_count ? next_instr[REG_ADDR_BITS+14:15] : instr[REG_ADDR_BITS+14:15];
    wire [REG_ADDR_BITS-1:0] next_rs2 = last_count ? next_instr[REG_ADDR_BITS+19:20] : instr[REG_ADDR_BITS+19:20];

    wire wr_en = alu_write || ((is_jmp || is_mul) && cycle == 1) || is_load_upper || (is_mem && !is_store && (cycle == 2));
    wire wr_next_en = slt_req;
    wire read_through = wr_next_en;
    nanoV_registers #(.REG_ADDR_BITS(REG_ADDR_BITS), .NUM_REGS(NUM_REGS)) 
        i_registers(clk, rstn, wr_en, wr_next_en, read_through, counter, next_rs1, next_rs2, rs1, rs2, rd, data_rs1, data_rs2, data_rd, data_rd_next);

    reg cy;
    wire is_branch_cycle1 = is_branch && cycle[0];
    wire [3:0] alu_op = (is_jmp || is_branch_cycle1 || is_load_upper || is_mem) ? 4'b0000 : 
                        is_branch ? {2'b00,instr[14:13]} :
                        {instr[30] && instr[5],instr[14:12]};
    wire alu_select_rs2 = instr[5] && !is_jmp && !is_branch_cycle1 && !is_load_upper && !is_mem;
    wire alu_write = (instr[4:2] == 3'b100) && !is_mul;
    wire alu_imm = is_jmp ? ((cycle == 0) ? (is_jal ? j_imm[counter] : i_imm[counter]) : (counter == 2)) : 
                   is_branch ? b_imm[counter] :
                   is_load_upper ? u_imm[counter] :
                   (is_mem && is_store) ? s_imm[counter] :
                   i_imm[counter];
    wire alu_a_in = ((is_jmp && (is_jal || cycle[0])) || is_branch_cycle1 || is_load_upper) ? pc : data_rs1;
    wire alu_b_in = alu_select_rs2 ? data_rs2 : alu_imm;
    wire cy_in = (counter == 0) ? (alu_op[1] || alu_op[3]) : cy;
    wire alu_out, cy_out, lts;
    wire slt = alu_op[0] == 1 ? ~cy_out : lts;
    wire slt_req = last_count && (alu_op[2:1] == 2'b01) && instr[4];
    nanoV_alu alu(alu_op, alu_a_in, alu_b_in, cy_in, alu_out, cy_out, lts);

    reg is_equal_reg;
    wire is_equal = is_equal_reg && (data_rs1 == data_rs2);

    always @(posedge clk) begin
        if (last_count) is_equal_reg <= 1;
        else is_equal_reg <= is_equal;
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

    wire mul_out;
    nanoV_mul #(.A_BITS(16)) multiplier(clk, stored_data[15:0], data_rs1 && is_mul && cycle[0], mul_out);

    assign data_rd = (is_mem && !is_store)  ? (use_ext_data_in ? ext_data_in : stored_data[6]) :
                     (is_mul) ? mul_out :
                     (alu_op[1:0] == 2'b01) ? shifter_out : alu_out;
    assign branch = cycle == 0 && ((is_jmp && counter == 0) || 
                                   (is_branch && last_count && ((instr[14] ? slt : is_equal) ^ instr[12])));

    // Various instructions require us to buffer a register
    wire store_data_in = (is_jmp || is_branch_cycle1 || (is_mem && cycle == 0)) ? alu_out :
                         (alu_op[1:0] == 2'b01) ? ((cycle == 1 && shift_stored) ? shift_in : data_rs1) : data_rs2;
    wire do_store = ((alu_op[1:0] == 2'b01) && (cycle == 0 || shift_stored)) || is_mem || is_jmp || is_branch_cycle1 || (is_mul && !cycle[0]);
    always @(posedge clk) begin
        if (shift_data_out) begin
            stored_data[31:1] <= stored_data[30:0];
            stored_data[0] <= is_mem ? (is_store ? data_rs2 : data_in) : 
                              stored_data[31];
        end else if (do_store) begin
            stored_data[31] <= store_data_in;
            stored_data[30:0] <= stored_data[31:1];
        end
    end

    assign data_out = stored_data;

    assign shift_pc = (is_jmp || is_branch_cycle1 || (is_load_upper && !instr[5])) && counter < 22 && cycle < 2;

endmodule

// Idea for 3 cycle MUL:
// - First cycle: populate stored_data with one argument
// - Second cycle: shift stored_data and add to an accumulator when corresponding bit in second argument is non-zero
// - Third cycle: shift accumulator out to dest reg