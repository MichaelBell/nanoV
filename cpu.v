/* A RISC-V core designed to use minimal area.
  
   This core module takes instructions and produces output data
 */

module nanoV_cpu (
    input clk,
    input rstn,

    input spi_data_in,
    output reg spi_select,
    output spi_out
);

    reg [4:0] counter;
    wire [5:0] next_counter = {1'b0,counter} + 1;
    always @(posedge clk)
        if (!rstn) begin
            counter <= 0;
        end else begin
            counter <= next_counter[4:0];
        end

    reg [2:0] cycle;
    wire [2:0] instr_cycles = 1;  // TODO
    wire [2:0] next_cycle = cycle + next_counter[5];
    reg [31:0] next_instr;
    reg [31:0] instr;
    always @(posedge clk)
        if (!rstn) begin
            cycle <= 0;
            instr <= 32'b000000000000_00000_000_00000_0010011;
        end else begin
            if (next_cycle == instr_cycles) begin
                cycle <= 0;
                instr <= next_instr;
            end else
                cycle <= next_cycle;
        end

    wire [31:0] data_out;
    wire shift_data_out;
    wire take_branch;

    nanoV_core core (
        clk,
        rstn,
        instr,
        cycle,
        counter,
        shift_data_out,
        data_out,
        take_branch
    );

    reg start_instr_stream;
    reg starting_instr_stream;
    reg read_instr;
    reg [23:0] pc;
    reg [7:0] read_cmd;
    
    wire [23:0] next_pc = (read_instr && counter == 5'b11111 && next_cycle == instr_cycles) ? pc + 2 : 
                          (take_branch && counter == 0 && cycle == 1) ? data_out[23:0] : pc;

    always @(posedge clk) begin
        if (!rstn) begin
            start_instr_stream <= 1;
            starting_instr_stream <= 0;
            read_instr <= 0;
            spi_select <= 1;
            pc <= 0;
            read_cmd <= 8'b00000011;
        end else begin
            read_cmd <= {read_cmd[6:0], next_pc[23]};
            pc       <= {next_pc[22:0], read_cmd[7]};
            if (take_branch && counter == 0 && cycle == 1) begin
                read_instr <= 0;
                start_instr_stream <= 1;                
                starting_instr_stream <= 0;
                spi_select <= 1;
            end else begin
                if (counter == 5'b11101) begin
                    if (start_instr_stream) begin
                        start_instr_stream <= 0;
                        starting_instr_stream <= 1;
                        spi_select <= 0;
                    end else if (starting_instr_stream) begin
                        start_instr_stream <= 0;
                        starting_instr_stream <= 0;
                        read_instr <= 1;
                    end
                end
            end
        end
    end

    assign shift_data_out = starting_instr_stream;
    // TODO Probably need to read from earlier in the read cmd bitfield to account for 
    // io delays, and fix the reset value of read_cmd appropriately.
    assign spi_out = starting_instr_stream ? read_cmd[5] : data_out[0];

    always @(posedge clk) begin
        if (!rstn) begin
            next_instr <= 32'b000000000000_00000_000_00000_0010011;
        end else begin
            if (read_instr) begin
                next_instr[31] <= spi_data_in;
                next_instr[30:0] <= next_instr[31:1];
            end
        end
    end

endmodule