`include "parameters.sv"

module wb_slave_tb ();
    reg rst_i;
    reg clk_i;
    reg ack_i;
    reg stb_o;
    reg [`ADDR_WIDTH-1:0] adr_o;
    reg [`DATA_WIDTH-1:0] dat_i;
    reg [`DATA_WIDTH-1:0] dat_o;
    reg we_o;
    reg cyc_o;

    wb_slave slave (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .adr_i(adr_o),
        .dat_o(dat_i),
        .dat_i(dat_o),
        .we_i(we_o),
        .cyc_i(cyc_o),
        .ack_o(ack_i),
        .stb_i(stb_o)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, slave);

        clk_i = 0;
        #100;
        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
