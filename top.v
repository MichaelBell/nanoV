module nanoV_top (
    input clk12MHz,
    input rstn,

    input spi_miso,
    output reg spi_select,
    output spi_clk_out,
    output reg spi_mosi,

    input button1,
    input button2,
    input button3,

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
    output lcol4);

    wire cpu_clk;
    assign cpu_clk = clk12MHz;

    reg buffered_spi_in;
    wire spi_data_out, spi_select_out, spi_clk_enable;
    wire [31:0] data_in;
    wire [31:0] raw_data_out;
    wire latch_data_out, latch_addr_out;
    nanoV_cpu nano(
        cpu_clk, 
        rstn, 
        buffered_spi_in, 
        spi_select_out, 
        spi_data_out, 
        spi_clk_enable, 
        data_in,
        raw_data_out, 
        latch_data_out, 
        latch_addr_out);

    reg [7:0] addr;
    always @(posedge cpu_clk) begin
        if (!rstn)
            addr <= 8'hff;
        else if (latch_addr_out)
            if (raw_data_out[31:24] == 8'h10)
                addr <= raw_data_out[7:0];
            else
                addr <= 8'hff;
    end

    assign data_in = (addr == 0) ? {29'h0, button3, button2, button1} : 32'h0;

    wire [31:0] reversed_data_out;
    genvar i;
    generate 
      for (i=0; i<32; i=i+1) assign reversed_data_out[i] = raw_data_out[31-i]; 
    endgenerate

    reg [31:0] data;
    always @(posedge cpu_clk) begin
        if (!rstn)
            data <= 0;
        else if (latch_data_out && addr == 0)
            data <= reversed_data_out;
    end

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
                .leds1(data[31:24]),
                .leds2(data[23:16]),
                .leds3(data[15:8]),
                .leds4(data[7:0]),
                .leds(leds_out),
                .lcol(lcol)
        );

endmodule
