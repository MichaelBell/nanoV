/* Copyright (C) 2023 Michael Bell

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

module big7_seg (
    input [7:0] seg_in,
    output [7:0] leds1,
    output [7:0] leds2,
    output [7:0] leds3,
    output [7:0] leds4
);

    assign leds1[0] = 0;
    assign leds2[0] = seg_in[0];
    assign leds3[0] = seg_in[0];
    assign leds4[0] = 0;

    assign leds1[1:2] = {(2){seg_in[5]}};
    assign leds2[1:2] = 0;
    assign leds3[1:2] = 0;
    assign leds4[1:2] = {(2){seg_in[1]}};

    assign leds1[3] = seg_in[5] && seg_in[4];
    assign leds2[3] = seg_in[6];
    assign leds3[3] = seg_in[6];
    assign leds4[3] = seg_in[1] && seg_in[2];

    assign leds1[4:5] = {(2){seg_in[4]}};
    assign leds2[4:5] = 0;
    assign leds3[4:5] = 0;
    assign leds4[4:5] = {(2){seg_in[2]}};

    assign leds1[6] = 0;
    assign leds2[6] = seg_in[3];
    assign leds3[6] = seg_in[3];
    assign leds4[6] = 0;

    assign leds1[7] = 0;
    assign leds2[7] = 0;
    assign leds3[7] = 0;
    assign leds4[7] = seg_in[7];

endmodule