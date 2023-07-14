/* Register file for nanoV.

    Targetting RV32E, so 15 registers + x0 is always zero.

    1-bit access and the registers are normally shifted every clock.

    Normally read bit address is one ahead of write bit address, and both increment every clock.

    On pause, the write bit address increments one more time, catching up with the read bit address.
    On unpause, the write bit address is not incremented on the first clock.
 */

module nanoV_registers #(parameter NUM_REGS=16, parameter REG_ADDR_BITS=4) (
    input clk,
    input rstn,

    input wr_en,  // Whether to write to rd.
    input wr_next_en,
    input read_through,

    input [REG_ADDR_BITS-1:0] next_rs1,
    input [REG_ADDR_BITS-1:0] next_rs2,

    input [REG_ADDR_BITS-1:0] rs1,
    input [REG_ADDR_BITS-1:0] rs2,
    input [REG_ADDR_BITS-1:0] rd,

    output data_rs1,
    output data_rs2,
    input data_rd,
    input data_rd_next
);

    reg last_data_rd_next;
    reg read_through_rs1, read_through_rs2;
    wire may_read_through = read_through && rd != 0;
    wire read_through_rs1_next = may_read_through && (next_rs1 == rd);
    wire read_through_rs2_next = may_read_through && (next_rs2 == rd);
    always @(posedge clk) begin
        last_data_rd_next <= data_rd_next;
        read_through_rs1 <= read_through_rs1_next;
        read_through_rs2 <= read_through_rs2_next;
    end

`ifdef ICE40
    reg [4:0] read_addr;
    reg [4:0] write_addr;

    always @(posedge clk) begin
        if (!rstn) begin
            read_addr <= 1;
            write_addr <= 0;
        end else begin
            read_addr <= (read_addr == 5'b11110) ? 0 : read_addr + 1;
            write_addr <= (write_addr == 5'b11110) ? 0 : write_addr + 1;
        end
    end

    wire [15:0] read_data;
    reg [15:1] reg_write_data;
    wire [15:0] reg_read_data = {reg_write_data, 1'b0};
    wire [15:0] write_data;
    SB_RAM40_4K registers (
        .RDATA(read_data),
        .RADDR({6'b0,read_addr}),
        .WADDR({6'b0,write_addr}),
        .MASK(16'h0001),
        .WDATA(write_data),
        .RCLKE(1'b1),
        .RCLK(clk),
        .RE(1'b1),
        .WCLKE(1'b1),
        .WCLK(clk),
        .WE(1'b1)
    );

    defparam registers.READ_MODE=0;
    defparam registers.WRITE_MODE=0;
    defparam registers.INIT_0=256'b0;

    reg data_rs1_reg, data_rs2_reg;
    always @(posedge clk) begin
        data_rs1_reg <= read_data[next_rs1];
        data_rs2_reg <= read_data[next_rs2];
    end
    assign data_rs1 = read_through_rs1 ? last_data_rd_next : data_rs1_reg;
    assign data_rs2 = read_through_rs2 ? last_data_rd_next : data_rs2_reg;

    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin
            always @(posedge clk) begin
                if (wr_next_en && rd == i)
                    reg_write_data[i] <= data_rd_next;
                else
                    reg_write_data[i] <= read_data[i];
            end

            assign write_data[i] = (wr_en && rd == i) ? data_rd : reg_write_data[i];
        end
    endgenerate

    assign write_data[0] = 1'b0;
`else

    reg [31:0] registers [1:NUM_REGS-1];
    wire [31:0] reg_access [0:2**REG_ADDR_BITS-1];

    genvar i;
    generate
        for (i = 0; i < 2**REG_ADDR_BITS; i = i + 1) begin
            if (i == 0 || i >= NUM_REGS) begin
                assign reg_access[i] = 0;
            end else begin
                always @(posedge clk) begin
                    if (wr_en && rd == i)
                        registers[i][0] <= data_rd;
                    else
                        registers[i][0] <= registers[i][1];
                    
                    if (wr_next_en && rd == i)
                        registers[i][1] <= data_rd_next;
                    else
                        registers[i][1] <= registers[i][2];
                    
                    registers[i][31:2] <= {registers[i][0], registers[i][31:3]};
                end

                assign reg_access[i] = registers[i];
            end
        end
    endgenerate 

    assign data_rs1 = read_through_rs1 ? last_data_rd_next : reg_access[rs1][1];
    assign data_rs2 = read_through_rs2 ? last_data_rd_next : reg_access[rs2][1];
`endif

endmodule
