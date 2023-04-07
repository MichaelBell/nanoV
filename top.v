module nanoV_top (
    input clk12MHz,
    input rstn,
    input i,
    output o31,
    output o0
);

    reg [31:0] instr;
    wire [31:0] data;

    nanoV nano(clk12MHz, rstn, instr, data);

    always @(posedge clk12MHz) begin
        instr <= {instr[30:0],i};
    end

    assign o31 = data[31];
    assign o0 = data[0];

endmodule
