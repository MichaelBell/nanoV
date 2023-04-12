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

    wire is_jmp = (instr[6:5] == 2'b11);
    reg [2:0] cycle;
    reg [2:0] instr_cycles_reg;
    wire [2:0] instr_cycles = instr_cycles_reg;
    wire [2:0] next_cycle = cycle + next_counter[5];
    reg [31:0] next_instr;
    reg [31:0] instr;
    always @(posedge clk)
        if (!rstn) begin
            cycle <= 0;
            instr <= 32'b000000000000_00000_000_00000_0010011;
            instr_cycles_reg <= 3;
        end else begin
            if (next_cycle == instr_cycles) begin
                cycle <= 0;
                instr <= next_instr;
                instr_cycles_reg <= (next_instr[6:5] == 2'b11) ? 3 : 1;  // TODO
            end else
                cycle <= next_cycle;
        end

    wire [31:0] data_out;
    wire shift_data_out;
    wire take_branch;
    wire read_pc;

    nanoV_core core (
        clk,
        rstn,
        instr,
        cycle,
        counter,
        pc[0],
        shift_data_out,
        read_pc,
        data_out,
        take_branch
    );

    reg start_instr_stream;
    reg starting_instr_stream;
    reg read_instr;
    reg [1:0] first_instr;
    reg [21:0] pc;
    wire starting_send_pc = counter[4:3] != 0 && counter < 30;
    wire starting_read_cmd = counter[2] && !counter[1];
    wire starting_data_out = starting_send_pc ? (is_jmp ? data_out[29] : pc[21]) : starting_read_cmd;
    
    wire [21:0] next_pc = (counter == 31 && next_cycle == instr_cycles && read_instr && !first_instr[0]) ? pc + 4 : pc;

    always @(posedge clk) begin
        if (!rstn) begin
            start_instr_stream <= 1;
            starting_instr_stream <= 0;
            read_instr <= 0;
            first_instr <= 0;
            spi_select <= 1;
            pc <= 0;
        end else begin
            if (take_branch && counter == 0) begin
                read_instr <= 0;
                start_instr_stream <= 1;                
                starting_instr_stream <= 0;
                spi_select <= 1;
            end else begin
                if (counter == 29) begin
                    if (start_instr_stream) begin
                        start_instr_stream <= 0;
                        starting_instr_stream <= 1;
                        spi_select <= 0;
                        read_instr <= 0;
                        first_instr <= 0;
                    end else if (starting_instr_stream) begin
                        start_instr_stream <= 0;
                        starting_instr_stream <= 0;
                        read_instr <= 1;
                        first_instr <= 2'b11;
                    end else begin
                        first_instr <= {1'b0,first_instr[1]};
                    end
                end
            end

            if (starting_instr_stream && starting_send_pc && !is_jmp)
                pc <= {pc[20:0],pc[21]};
            else if (read_pc)
                pc <= {pc[0],pc[21:1]};
            else if (is_jmp && cycle == 2 && counter > 9)
                pc <= {pc[20:0],data_out[31]};
            else
                pc <= next_pc;
        end
    end

    assign shift_data_out = is_jmp && (cycle != 0);
    assign spi_out = starting_instr_stream ? starting_data_out : data_out[0];

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