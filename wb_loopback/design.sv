/*
 *
 * General description:
 *
 *      A basic device which implements both a master and a slave Wishbone interface
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

package wb_loopback_pkg;

typedef enum int {
    MASTER_STATE_WAIT,
    MASTER_STATE_START,
    MASTER_STATE_WAIT_FOR_ACK
} master_state_t;

typedef enum int {
    SLAVE_STATE_WAIT,
    SLAVE_STATE_RESPOND
} slave_state_t;

endpackage

module wb_loopback (
    input wire rst_i,
    input wire clk_i,
    // master interface
    input wire ack_i,
    output reg stb_o,
    output reg cyc_o,
    // slave interface
    output reg ack_o,
    input wire stb_i,
    input wire cyc_i
);

    parameter INITIAL_DELAY = 2;
    parameter WAIT_CYCLES = 4;

    import wb_loopback_pkg::*;

    master_state_t master_state = MASTER_STATE_WAIT;
    slave_state_t slave_state = SLAVE_STATE_WAIT;
    int wait_cycles = INITIAL_DELAY;

    // slave interface
    assign ack_o = stb_i;

    // master interface
    always @(posedge clk_i) begin
        if (rst_i) begin
            master_state <= MASTER_STATE_WAIT;
            slave_state <= SLAVE_STATE_WAIT;
            stb_o <= 0;
            cyc_o <= 0;
            wait_cycles <= WAIT_CYCLES;
        end else begin
            case (master_state)
                MASTER_STATE_WAIT: begin
                    if (wait_cycles == 0) begin
                        master_state <= MASTER_STATE_START;
                        wait_cycles <= WAIT_CYCLES;
                    end else begin
                        wait_cycles <= wait_cycles - 1;
                    end
                end
                MASTER_STATE_START: begin
                    master_state <= MASTER_STATE_WAIT_FOR_ACK;
                    stb_o <= 1;
                    cyc_o <= 1;
                end
                MASTER_STATE_WAIT_FOR_ACK: begin
                    if (ack_i) begin
                        master_state <= MASTER_STATE_WAIT;
                        stb_o <= 0;
                        cyc_o <= 0;
                    end
                end
            endcase
        end
    end

endmodule
