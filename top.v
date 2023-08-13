module nanoV_top (
    input clk12MHz,
    input rstn,

    input spi_miso,
    output reg spi_select,
    output spi_clk_out,
    output reg spi_mosi,

    input uart_rxd,
    output uart_txd,
    output uart_rts,

    input button1,
    input button2,
    input button3,

    output out0,
    output out1,
    output out2,
    output out3,
    output out4,
    output out5,
    output out6,
    output out7,

    output led1,
    output led2,
    output led3,
    output led4,
    output led5,
    output led6,
    output led7,
    output led8,
    output lcol1,
    output lcol2,
    output lcol3,
    output lcol4,
    
    output spkp,
    output spkm);

    wire cpu_clk;
    assign cpu_clk = clk12MHz;

    reg buffered_spi_in;
    wire spi_data_out, spi_select_out, spi_clk_enable;
    wire [31:0] data_in;
    wire [31:0] addr_out;
    wire [31:0] data_out;
    wire is_data, is_addr, is_data_in;
    nanoV_cpu nano(
        cpu_clk, 
        rstn, 
        buffered_spi_in, 
        spi_select_out, 
        spi_data_out, 
        spi_clk_enable, 
        data_in,
        addr_out, 
        data_out, 
        is_data, 
        is_addr,
        is_data_in);

    localparam PERI_NONE = 0;
    localparam PERI_LEDS = 1;
    localparam PERI_GPIO_OUT = 2;
    localparam PERI_GPIO_IN = 3;
    localparam PERI_UART = 4;
    localparam PERI_UART_STATUS = 5;
    localparam PERI_MUSIC = 6;

    reg [2:0] connect_peripheral;
    
    always @(posedge cpu_clk) begin
        if (!rstn) begin 
            connect_peripheral <= PERI_NONE;
        end
        else if (is_addr) begin
            if (addr_out == 32'h10000000) connect_peripheral <= PERI_GPIO_OUT;
            else if (addr_out == 32'h10000004) connect_peripheral <= PERI_GPIO_IN;
            else if (addr_out == 32'h10000008) connect_peripheral <= PERI_LEDS;
            else if (addr_out == 32'h10000010) connect_peripheral <= PERI_UART;
            else if (addr_out == 32'h10000014) connect_peripheral <= PERI_UART_STATUS;
            else if (addr_out == 32'h10000020) connect_peripheral <= PERI_MUSIC;
            else connect_peripheral <= PERI_NONE;
        end
    end

    reg [7:0] output_data;
    reg [31:0] led_data;
    reg [7:0] midi_note;
    always @(posedge cpu_clk) begin
        if (!rstn) begin
            led_data <= 0;
            output_data <= 0;
        end else if (is_data) begin
            if (connect_peripheral == PERI_LEDS) led_data <= data_out;
            else if (connect_peripheral == PERI_GPIO_OUT) output_data <= data_out[7:0];
            else if (connect_peripheral == PERI_MUSIC) midi_note <= data_out[7:0];
        end
    end

    assign { out7, out6, out5, out4, out3, out2, out1, out0 } = output_data;

    wire uart_tx_busy;
    wire uart_rx_valid;
    wire [7:0] uart_rx_data;
    assign data_in[31:8] = 0;
    assign data_in[7:0] = connect_peripheral == PERI_GPIO_OUT ? output_data :
                          connect_peripheral == PERI_GPIO_IN ? {5'b0, button3, button2, button1} : 
                          connect_peripheral == PERI_UART ? uart_rx_data :
                          connect_peripheral == PERI_UART_STATUS ? {6'b0, uart_rx_valid, uart_tx_busy} :
                          connect_peripheral == PERI_MUSIC ? midi_note : 0;

    wire uart_tx_start = is_data && connect_peripheral == PERI_UART;
    wire [7:0] uart_tx_data = data_out[7:0];

    uart_tx #(.CLK_HZ(12_000_000), .BIT_RATE(93_750)) i_uart_tx(
        .clk(cpu_clk),
        .resetn(rstn),
        .uart_txd(uart_txd),
        .uart_tx_en(uart_tx_start),
        .uart_tx_data(uart_tx_data),
        .uart_tx_busy(uart_tx_busy) 
    );

    uart_rx #(.CLK_HZ(12_000_000), .BIT_RATE(93_750)) i_uart_rx(
        .clk(cpu_clk),
        .resetn(rstn),
        .uart_rxd(uart_rxd),
        .uart_rts(uart_rts),
        .uart_rx_read(connect_peripheral == PERI_UART && is_data_in),
        .uart_rx_valid(uart_rx_valid),
        .uart_rx_data(uart_rx_data) 
    );

    // TODO: Probably need to use SB_IO directly for reading/writing with good timing
    always @(negedge cpu_clk) begin
        buffered_spi_in <= spi_miso;
    end

    always @(posedge cpu_clk) begin
        if (!rstn)
            spi_select <= 1;
        else
            spi_select <= spi_select_out;

        spi_mosi <= spi_data_out;
    end

    assign spi_clk_out = !cpu_clk && spi_clk_enable;

    // map the output of ledscan to the port pins
    wire [7:0] leds_out;
    wire [3:0] lcol;
    assign { led8, led7, led6, led5, led4, led3, led2, led1 } = leds_out[7:0];
    assign { lcol4, lcol3, lcol2, lcol1 } = lcol[3:0];

    LedScan scan (
                .clk12MHz(clk12MHz),
                .leds1(led_data[31:24]),
                .leds2(led_data[23:16]),
                .leds3(led_data[15:8]),
                .leds4(led_data[7:0]),
                .leds(leds_out),
                .lcol(lcol)
        );

    wire spk_out;
    Music music (
        .clk12MHz(clk12MHz),
        .rstn(rstn),
        .midi_note(midi_note),
        .spk_out(spk_out)
    );
    assign spkp = spk_out;
    assign spkm = !spk_out;

endmodule
