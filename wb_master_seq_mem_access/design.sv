/*
 *
 * General description:
 *
 *      A master device, which continuously issues SINGLE WRITE and SINGLE READ
 *      bus cycles, over a range of memory addresses.
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

package wb_master_seq_mem_access_pkg;

typedef enum int {
    STATE_INIT,
    STATE_START,
    STATE_WAIT_FOR_ACK_AFTER_WRITE,
    STATE_WAIT_BEFORE_READ,
    STATE_WAIT_FOR_ACK_AFTER_READ
} state_t;

endpackage

module wb_master_seq_mem_access (
    input  wire rst_i,
    input  wire clk_i,
    output wire stb_o,
    output wire cyc_o,
    output reg  we_o,
    output reg  [ADDR_WIDTH-1:0] adr_o,
    output reg  [DATA_WIDTH-1:0] dat_o,
    input  wire [DATA_WIDTH-1:0] dat_i,
    input  wire ack_i,
    input  wire err_i
);

    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter START_ADDR = 0;
    parameter END_ADDR = 15; // inclusive
    parameter STEP = 1;

    import wb_master_seq_mem_access_pkg::*;

    state_t state = STATE_INIT;

    reg stb = 0;
    reg cyc = 0;

    reg [ADDR_WIDTH-1:0] curr_addr = START_ADDR;
    reg [DATA_WIDTH-1:0] curr_data;
    reg [2:0] init_cycles = 0;

    assign stb_o = stb;
    assign cyc_o = cyc;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_IDLE;
        end else begin
            case (state)
                STATE_INIT: begin
                    if (init_cycles[2] == 1'b1)
                        state <= STATE_START;

                    init_cycles <= init_cycles + 1;
                end
                STATE_START: begin
                    state <= STATE_WAIT_FOR_ACK_AFTER_WRITE;
                    stb <= 1;
                    cyc <= 1;
                    we_o <= 1'b1;
                    adr_o <= curr_addr;
                    dat_o <= $urandom_range(16);
                    curr_data <= dat_o;
                end
                STATE_WAIT_FOR_ACK_AFTER_WRITE: begin
                    $display("Writing data: %x", dat_o);

                    if (ack_i) begin
                        state <= STATE_WAIT_BEFORE_READ;
                        stb <= 0;
                        we_o <= 1'b0;
                    end
                end
                STATE_WAIT_BEFORE_READ: begin
                    state <= STATE_WAIT_FOR_ACK_AFTER_READ;
                    stb <= 1;
                end
                STATE_WAIT_FOR_ACK_AFTER_READ: begin
                    if (ack_i) begin
                        $display("Data read: %x", dat_i);

                        state <= STATE_START;
                        stb <= 0;
                        cyc <= 0;

                        if (curr_addr + STEP > END_ADDR)
                            curr_addr <= START_ADDR;
                        else
                            curr_addr <= curr_addr + STEP;
                    end
                end
            endcase
        end
    end

endmodule
