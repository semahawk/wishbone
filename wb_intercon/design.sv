/*
 *
 * General description:
 *
 *      A simple general Wishbone multiplexed interconnect.
 *      It's using a simple round robin way of selecting which master gets to go.
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

package wb_intercon_pkg;

    typedef enum {
        STATE_WAIT_FOR_BUS_CLAIM,
        STATE_WAIT_FOR_CYCLE_END
    } state_t;

endpackage

module wb_intercon (
    input wire rst_i,
    input wire clk_i,

    // master -> intercon
    input wire [MASTERS_NUM-1:0] m2i_cyc_i,
    input wire [MASTERS_NUM-1:0] m2i_stb_i,
    input wire [MASTERS_NUM*ADDR_WIDTH-1:0] m2i_adr_i,
    // intercon -> master
    output wire [MASTERS_NUM-1:0] i2m_ack_o,
    // slave -> intercon
    input wire [SLAVES_NUM-1:0] s2i_ack_i,
    // intercon -> slave
    output wire [SLAVES_NUM-1:0] i2s_cyc_o,
    output wire [SLAVES_NUM-1:0] i2s_stb_o,

    // so we don't have to care about the ','
    output wire nc

`ifdef DUPA
    // master -> intercon
    input wire cyc_i [0:MASTERS_NUM-1],
    input wire stb_i [0:MASTERS_NUM-1],
    // intercon -> slave
    output wire cyc_o, // every slave get's the same cyc signal
    output wire stb_o [0:SLAVES_NUM-1],
    // master -> intercon
    input wire                  we_i  [0:MASTERS_NUM-1],
    input wire [ADDR_WIDTH-1:0] adr_i [0:MASTERS_NUM-1],
    input wire [DATA_WIDTH-1:0] dat_i [0:MASTERS_NUM-1],
    input wire [SEL_WIDTH-1:0]  sel_i [0:MASTERS_NUM-1],
    // intercon -> slave
    // these four signal groups are all shared between all slaves
    output wire                  we_o,
    output wire [ADDR_WIDTH-1:0] adr_o,
    output wire [DATA_WIDTH-1:0] dat_m2s_o,
    output wire [SEL_WIDTH-1:0]  sel_o,
    // slave -> intercon
    input wire ack_i [0:SLAVES_NUM-1],
    input wire err_i [0:SLAVES_NUM-1],
    // intercon -> master
    // each master get's it's own ack_i and err_i inputs
    output wire ack_o [0:MASTERS_NUM-1],
    output wire err_o [0:MASTERS_NUM-1],
    // intercon -> master
    // slave's data output, shared between all masters
    output wire [DATA_WIDTH-1:0] dat_s2m_o
`endif
);

    parameter MASTERS_NUM = 2;
    parameter SLAVES_NUM = 2;
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    localparam SEL_WIDTH = 8;

    import wb_intercon_pkg::*;

    state_t state = STATE_WAIT_FOR_BUS_CLAIM;
    reg [$clog2(MASTERS_NUM)-1:0] grant = 0;

    wire [$clog2(SLAVES_NUM)-1:0] selected_slave;

    // upper 4 bits of granted master's adr_o select the slave
    assign selected_slave = m2i_adr_i[ADDR_WIDTH*grant+ADDR_WIDTH-4+:4];

    // distribute the cyc_o signal (coming from the blessed master) to all slaves
    assign i2s_cyc_o = {SLAVES_NUM{m2i_cyc_i[grant]}};
    // distribute the stb_o signal only to the one slave
    assign i2s_stb_o = m2i_stb_i[grant] << selected_slave;

    assign i2m_ack_o = s2i_ack_i[selected_slave] << grant;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_WAIT_FOR_BUS_CLAIM;
            grant <= 0;
        end else begin
            case (state)
                STATE_WAIT_FOR_BUS_CLAIM: begin
                    // reduction OR - check if at least one bit is set
                    if (|m2i_cyc_i) begin
                        state <= STATE_WAIT_FOR_CYCLE_END;
                    end
                end
                STATE_WAIT_FOR_CYCLE_END: begin
                    if (~m2i_cyc_i[grant]) begin
                        state <= STATE_WAIT_FOR_BUS_CLAIM;
                        grant <= grant + 1;
                    end
                end
            endcase
        end
    end

endmodule