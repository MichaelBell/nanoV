module nanoV_top (
    input clk12MHz,
    input rstn,
    input i,
    output o31,
    output o0
);

    reg [3:0] op;
    reg [31:0] a;
    reg [31:0] b;
    wire [31:0] d;

    nanoV nano(clk12MHz, rstn, op, a, b, d);

    always @(posedge clk12MHz) begin
        op <= {op[2:0],i};
        a <= {a[30:0],op[3]};
        b <= {b[30:0],a[31]};
    end

    assign o31 = d[31];
    assign o0 = d[0];

endmodule
