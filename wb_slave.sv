`include "parameters.sv"

module wb_slave (
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

    // TODO
  
endmodule
