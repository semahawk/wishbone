/*
 *
 * General description:
 *
 *     A simple register array device, which contains a number of identical registers.
 *     Number of registers is controlled by a module parameter. They are then
 *     addressed using the ADR_I lines (where, ADR_I = 0x0, is first register,
 *     ADR_I = 0x1 is second register, etc. regardless of their sizes)
 *
 * Supported cycles:
 *
 *      SLAVE, READ / WRITE
 *      SLAVE, READ MODIFY WRITE
 *
 * Data organization:
 *
 *      Port size: 8, 16, 32 or 64 bit (module parameter: DATA_WIDTH)
 *      Port granularity: 8, 16, 32 or 64 bit (module parameter: GRANULE)
 *      Port maximum operand size: depends on port size
 *      Transfer ordering: Big endian
 *      Transfer sequencing: Undefined
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

typedef enum {
    STATE_IDLE,
    STATE_PROCESS,
    STATE_WAIT_FOR_PHASE_END
} state_t;

module wb_slave_register (
    input wire rst_i,
    input wire clk_i,
    input wire [ADDR_WIDTH-1:0] adr_i,
    input wire [DATA_WIDTH-1:0] dat_i,
    output reg [DATA_WIDTH-1:0] dat_o,
    input wire [SEL_WIDTH-1:0] sel_i,
    input wire we_i,
    input wire stb_i,
    output wire ack_o,
    input wire cyc_i
);

    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter GRANULE = 8;
    parameter REGISTER_NUM = 16;
    localparam SEL_WIDTH = DATA_WIDTH / GRANULE;

    reg [DATA_WIDTH-1:0] register_value [0:REGISTER_NUM-1];
    reg ack = 1'h0;
    state_t state = STATE_IDLE;
    int i;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= STATE_IDLE;
            ack <= 1'h0;

            for (i = 0; i < REGISTER_NUM; i++) begin
                register_value[i] <= {DATA_WIDTH{1'h0}};
            end
        end else begin
            case (state)
                STATE_IDLE: begin
                    if (stb_i) begin
                        state <= STATE_PROCESS;
                    end
                end
                STATE_PROCESS: begin
                    for (i = 0; i < SEL_WIDTH; i++) begin
                        if (sel_i[i]) begin
                            if (we_i)
                                register_value[adr_i][i*GRANULE+:GRANULE] <= dat_i[i*GRANULE+:GRANULE];
                            else
                                dat_o[i*GRANULE+:GRANULE] <= register_value[adr_i][i*GRANULE+:GRANULE];
                        end
                    end

                    state <= STATE_WAIT_FOR_PHASE_END;
                    ack <= 1'h1;
                end
                STATE_WAIT_FOR_PHASE_END: begin
                    if (~stb_i) begin
                        state <= STATE_IDLE;
                        ack <= 1'h0;
                    end
                end
            endcase
        end
    end

    assign ack_o = stb_i ? ack : 1'h0;

endmodule
