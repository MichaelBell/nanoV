/*
 * Copyright (c) 2024 Michael Bell
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module nanoV_top (
        input clk,
        input rst_n,

    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display

        output reg spi_select,
        output reg spi_mosi,
        output spi_clk,
        input  spi_miso,

        input  uart_rxd,
        output uart_txd,
        output uart_rts
);
    localparam CLOCK_FREQ = 12_000_000;

    wire spi_clk_enable;
    assign spi_clk = !clk && spi_clk_enable;

    reg buffered_spi_in;
    always @(negedge clk)
        buffered_spi_in <= spi_miso;

    wire spi_data_nano, spi_select_nano;
    always @(posedge clk)
        if (!rst_n)
            spi_select <= 1;
        else
            spi_select <= spi_select_nano;

    always @(posedge clk)
        spi_mosi <= spi_data_nano;
    
    wire [31:0] data_in;
    wire [31:0] addr_out;
    wire [31:0] data_out;
    wire is_data, is_data_in;
    wire is_addr;
    reg [7:0] output_data;
    assign uo_out = output_data;

    nanoV_cpu #(.NUM_REGS(16)) nano(
        .clk(clk), 
        .rstn(rst_n),
        .spi_data_in(buffered_spi_in), 
        .spi_select(spi_select_nano), 
        .spi_out(spi_data_nano),
        .spi_clk_enable(spi_clk_enable),
        .ext_data_in(data_in),
        .addr_out(addr_out),
        .data_out(data_out),
        .store_data_out(is_data),
        .store_addr_out(is_addr),
        .data_in_read(is_data_in));

    localparam PERI_NONE = 0;
    localparam PERI_GPIO_OUT = 2;
    localparam PERI_GPIO_IN = 3;
    localparam PERI_UART = 4;
    localparam PERI_UART_STATUS = 5;

    reg [2:0] connect_peripheral;
    
    always @(posedge clk) begin
        if (!rst_n) begin 
            connect_peripheral <= PERI_NONE;
        end
        else if (is_addr) begin
            if (addr_out == 32'h10000000) connect_peripheral <= PERI_GPIO_OUT;
            else if (addr_out == 32'h10000004) connect_peripheral <= PERI_GPIO_IN;
            else if (addr_out == 32'h10000010) connect_peripheral <= PERI_UART;
            else if (addr_out == 32'h10000014) connect_peripheral <= PERI_UART_STATUS;
            else connect_peripheral <= PERI_NONE;
        end

        if (is_data && connect_peripheral == PERI_GPIO_OUT) output_data <= data_out[7:0];
    end

    wire uart_tx_busy;
    wire uart_rx_valid;
    wire [7:0] uart_rx_data;
    assign data_in[31:8] = 0;
    assign data_in[7:0] = connect_peripheral == PERI_GPIO_OUT ? output_data :
                          connect_peripheral == PERI_GPIO_IN ? ui_in : 
                          connect_peripheral == PERI_UART ? uart_rx_data :
                          connect_peripheral == PERI_UART_STATUS ? {6'b0, uart_rx_valid, uart_tx_busy} : 0;

    wire uart_tx_start = is_data && connect_peripheral == PERI_UART;
    wire [7:0] uart_tx_data = data_out[7:0];

    uart_tx #(.CLK_HZ(12_000_000), .BIT_RATE(93_750)) i_uart_tx(
        .clk(clk),
        .resetn(rst_n),
        .uart_txd(uart_txd),
        .uart_tx_en(uart_tx_start),
        .uart_tx_data(uart_tx_data),
        .uart_tx_busy(uart_tx_busy) 
    );

    uart_rx #(.CLK_HZ(12_000_000), .BIT_RATE(93_750)) i_uart_rx(
        .clk(clk),
        .resetn(rst_n),
        .uart_rxd(uart_rxd),
        .uart_rts(uart_rts),
        .uart_rx_read(connect_peripheral == PERI_UART && is_data_in),
        .uart_rx_valid(uart_rx_valid),
        .uart_rx_data(uart_rx_data) 
    );

endmodule
