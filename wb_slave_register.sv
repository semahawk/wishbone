/*
 *
 * General description:
 *
 *     A simple register device, which retains it's data. Reading will return
 *     the register's data, and writing to it will modify it.
 *
 * Supported cycles:
 *
 *      SLAVE, READ / WRITE
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
    input wire [7:0] sel_i,
    input wire we_i,
    input wire stb_i,
    output wire ack_o,
    input wire cyc_i
);

    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 32;
    parameter GRANULE = 8;

    reg [DATA_WIDTH-1:0] register_value = {DATA_WIDTH{1'h0}};
    reg [ADDR_WIDTH-1:0] addr;
    reg [7:0] selection; // maximum number of selection bits (max port size / lowest granule)
    reg ack = 1'h0;
    state_t state = STATE_IDLE;
    int i;

    always @(posedge clk_i) begin
        case (state)
            STATE_IDLE: begin
                if ((cyc_i) && (stb_i)) begin
                    state <= STATE_PROCESS;
                    addr <= adr_i;
                    selection <= sel_i;
                end
            end
            STATE_PROCESS: begin
                for (i = 0; i < DATA_WIDTH / GRANULE; i++) begin
                    if (selection[i]) begin
                        if (we_i)
                            register_value[i*GRANULE+:GRANULE] <= dat_i[i*GRANULE+:GRANULE];
                        else
                            dat_o[i*GRANULE+:GRANULE] <= register_value[i*GRANULE+:GRANULE];
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

    assign ack_o = stb_i ? ack : 1'h0;

endmodule
