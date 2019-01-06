/*
 *
 * General description:
 *
 *      A NOP master device, which does basically nothing. It only starts a cycle/phase
 *      waits for ACK and that's about it.
 *
 * Wishbone specification used: B4 (https://cdn.opencores.org/downloads/wbspec_b4.pdf)
 *
 * Copyright (c) Szymon Urbaś <szymon.urbas@aol.com> All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     1. Redistributions of source code must retain the above copyright
 *        notice, this list of conditions and the following disclaimer.
 *     2. Redistributions in binary form must reproduce the above copyright
 *        notice, this list of conditions and the following disclaimer in the
 *        documentation and/or other materials provided with the distribution.
 *     3. Neither the name of the copyright holder nor the names of its
 *        contributors may be used to endorse or promote products derived from
 *        this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 */

`default_nettype none

package wb_master_nop_pkg;

typedef enum int {
    STATE_WAIT,
    STATE_START,
    STATE_WAIT_FOR_ACK
} state_t;

endpackage

module wb_master_nop (
    input wire rst_i,
    input wire clk_i,
    input wire ack_i,
    output wire stb_o,
    output wire cyc_o
);

    parameter INITIAL_DELAY = 2;
    parameter WAIT_CYCLES = 4;

    import wb_master_nop_pkg::*;

    state_t state = STATE_WAIT;
    int wait_cycles = INITIAL_DELAY;
    reg stb = 1'h0;
    reg cyc = 1'h0;

    assign stb_o = stb;
    assign cyc_o = cyc;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_WAIT;
            stb <= 0;
            cyc <= 0;
            wait_cycles <= WAIT_CYCLES;
        end else begin
            case (state)
                STATE_WAIT: begin
                    if (wait_cycles == 0) begin
                        state <= STATE_START;
                        wait_cycles <= WAIT_CYCLES;
                    end else begin
                        wait_cycles <= wait_cycles - 1;
                    end
                end
                STATE_START: begin
                    state <= STATE_WAIT_FOR_ACK;
                    stb <= 1;
                    cyc <= 1;
                end
                STATE_WAIT_FOR_ACK: begin
                    if (ack_i) begin
                        state <= STATE_WAIT;
                        stb <= 0;
                        cyc <= 0;
                    end
                end
            endcase
        end
    end

endmodule
