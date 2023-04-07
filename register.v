/* Register file for nanoV.

    Targetting RV32E, so 15 registers + x0 is always zero.

    1-bit access and the registers are normally shifted every clock.

    Normally read bit address is one ahead of write bit address, and both increment every clock.

    On pause, the write bit address increments one more time, catching up with the read bit address.
    On unpause, the write bit address is not incremented on the first clock.
 */

module nanoV_registers (
    input clk,
    input rstn,

    input pause,  // Pause the register cycling.  If wr_en is 
    input wr_en,  // Whether to write to rd.

    input [3:0] rs1,
    input [3:0] rs2,
    input [3:0] rd,

    output data_rs1,
    output data_rs2,
    input data_rd
);

    reg [4:0] read_addr;
    reg [4:0] write_addr;
    reg write_pause;

    always @(posedge clk) begin
        if (!rstn) begin
            read_addr <= 0;
            write_addr <= 0;
            write_pause <= 1;
        end else begin
            if (!pause)
                read_addr <= read_addr + 1;
            if (!write_pause)
                write_addr <= write_addr + 1;
            write_pause <= pause;
        end
    end

`ifdef ICE40
    wire [15:0] reg_read_data;
    SB_RAM40_4K registers (
        .RDATA(reg_read_data),
        .RADDR({6'b0,read_addr}),
        .WADDR({6'b0,write_addr}),
        .MASK(~(16'b1 << rd)),
        .WDATA({15'b0,data_rd} << rd),
        .RCLKE(1'b1),
        .RCLK(clk),
        .RE(1'b1),
        .WCLKE(1'b1),
        .WCLK(clk),
        .WE(wr_en && rd != 0)
    );

    defparam registers.READ_MODE=0;
    defparam registers.WRITE_MODE=0;
    defparam registers.INIT_0=256'b0;

    reg [3:0] last_rs1;
    reg [3:0] last_rs2;
    always @(posedge clk) begin
        last_rs1 <= rs1;
        last_rs2 <= rs2;
    end

    assign data_rs1 = reg_read_data[last_rs1];
    assign data_rs2 = reg_read_data[last_rs2];

`else
    reg [15:1] registers [0:31];  // Each entry is the bit value for each register at a particular index.
    reg read_data_rs1, read_data_rs2;

    always @(posedge clk) begin
        if (wr_en && rd != 0)
            registers[write_addr][rd] <= data_rd;

        read_data_rs1 <= (rs1 == 0) ? 1'b0 : registers[read_addr][rs1];
        read_data_rs2 <= (rs2 == 0) ? 1'b0 : registers[read_addr][rs2];
    end

    assign data_rs1 = read_data_rs1;
    assign data_rs2 = read_data_rs2;
`endif

endmodule