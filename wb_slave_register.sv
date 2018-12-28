`include "parameters.sv"

typedef enum {
    STATE_IDLE,
    STATE_PROCESS,
    STATE_WAIT_FOR_PHASE_END
} state_t;

module wb_slave_register (
    input wire rst_i,
    input wire clk_i,
    input wire [`ADDR_WIDTH-1:0] adr_i,
    input wire [`DATA_WIDTH-1:0] dat_i,
    output wire [`DATA_WIDTH-1:0] dat_o,
    input wire we_i,
    input wire stb_i,
    output wire ack_o,
    input wire cyc_i
);

    reg [`DATA_WIDTH-1:0] register_value = 8'h0;
    reg [`DATA_WIDTH-1:0] output_data = 8'h0;
    reg [`ADDR_WIDTH-1:0] addr;
    reg ack = 1'h0;
    state_t state = STATE_IDLE;

    always @(posedge clk_i) begin
        case (state)
            STATE_IDLE: begin
                if ((cyc_i) && (stb_i)) begin
                    state <= STATE_PROCESS;
                    addr <= adr_i;
                end
            end
            STATE_PROCESS: begin
                state <= STATE_WAIT_FOR_PHASE_END;
                output_data <= register_value;
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
    assign dat_o = output_data;
  
endmodule
