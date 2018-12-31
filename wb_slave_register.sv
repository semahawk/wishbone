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
    input wire [7:0] sel_i,
    input wire we_i,
    input wire stb_i,
    output wire ack_o,
    input wire cyc_i
);

    parameter GRANULE = 8;

    reg [`DATA_WIDTH-1:0] register_value = {`DATA_WIDTH{1'h0}};
    reg [`DATA_WIDTH-1:0] input_data = {`DATA_WIDTH{1'h0}};
    reg [`DATA_WIDTH-1:0] output_data = {`DATA_WIDTH{1'h0}};
    reg [`ADDR_WIDTH-1:0] addr;
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

                    if (we_i) begin
                        input_data <= dat_i;
                    end
                end
            end
            STATE_PROCESS: begin
                for (i = 0; i < `DATA_WIDTH / GRANULE; i++) begin
                    if (selection[i]) begin
                        if (we_i)
                            register_value[i*GRANULE+:GRANULE] <= input_data[i*GRANULE+:GRANULE];
                        else
                            output_data[i*GRANULE+:GRANULE] <= register_value[i*GRANULE+:GRANULE];
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
    assign dat_o = output_data;
  
endmodule
