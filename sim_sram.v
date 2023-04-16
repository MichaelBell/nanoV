// Simulation of a SPI RAM that accepts reads and writes using
// commands 03h and 02h.

module sim_spi_ram (
    input spi_clk,
    input spi_mosi,
    input spi_select,
    output reg spi_miso,

    input debug_clk,
    input [23:0] debug_addr,
    output reg [31:0] debug_data
);

    reg [31:0] cmd;
    reg [26:0] addr;
    reg [5:0] start_count;
    reg reading;
    reg writing;
    reg error;

    reg [31:0] data [0:16384];

    parameter INIT_FILE = "";
    initial begin
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, data);
        else
            data = 0;
    end

    wire [5:0] next_start_count = start_count + 1;

    always @(posedge spi_clk) begin
        if (spi_select) begin
            cmd <= 0;
            addr <= 0;
            start_count <= 0;
        end else begin
            start_count <= next_start_count;

            if (writing) begin
                data[addr[18:5]][addr[4:0]] <= spi_mosi;
            end else if (!reading && !writing && !error) begin
                cmd <= {cmd[30:0],spi_mosi};
            end
        end
    end

    always @(negedge spi_clk) begin
        if (spi_select) begin
            reading <= 0;
            writing <= 0;
            error <= 0;
        end else begin
            if (reading || writing) begin
                addr <= addr + 1;
            end else if (!reading && !writing && !error && start_count == 32) begin
                addr[26:3] <= cmd[23:0];
                addr[2:0] <= 0;
                if (cmd[31:24] == 3)
                    reading <= 1;
                else if (cmd[31:24] == 2)
                    writing <= 1;
                else
                    error <= 1;
            end
        end
    end

    always @(posedge debug_clk) begin
        debug_data <= data[debug_addr];
    end

    assign spi_miso = reading ? data[addr[18:5]][addr[4:0]] : 0;
endmodule