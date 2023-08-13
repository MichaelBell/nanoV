/*
 *
 *  Copyright(C) 2018 Gerald Coe, Devantech Ltd <gerry@devantech.co.uk>
 *  Modifications Copyright (C) 2023 Michael Bell
 *
 *  Permission to use, copy, modify, and/or distribute this software for any purpose with or
 *  without fee is hereby granted, provided that the above copyright notice and
 *  this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO
 *  THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS.
 *  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 *  DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
 *  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 *  CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

 module Music (
    input clk12MHz,
    input rstn,
    input [7:0] midi_note,
    output reg spk_out
    );

    reg [14:0] notetime;        // = 22933;

// Timer register */
    reg [14:0] timer;

// increment the note timer
    always @ (posedge clk12MHz) begin
        if (!rstn) begin
            timer <= 0;
            spk_out <= 0;
        end else if (timer == 0) begin
            timer <= notetime;
            if (midi_note[7:0] != 0) spk_out <= !spk_out;
        end else 
            timer <= timer - 1;
    end

    always @ (posedge clk12MHz) begin
        if (!rstn) begin
            notetime <= 22933;
        end else begin
            case (midi_note[7:0])
                8'd60: notetime <= 22933;   // C  C4
                8'd67: notetime <= 15306;   // G  G4
                8'd72: notetime <= 11467;   // c  C5
                8'd74: notetime <= 10216;   // d  D5
                8'd76: notetime <= 9101;    // e  E5
                default: notetime <= notetime;
            endcase
        end
    end

endmodule        