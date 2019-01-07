`timescale 1ns / 1ps

module wb_loopback_tb ();
    reg rst_i;
    reg clk_i;

    wire ack;
    wire stb;
    wire cyc;

    wb_loopback loopback_tb (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .cyc_o(cyc),
        .ack_i(ack),
        .stb_o(stb),
        .cyc_i(cyc),
        .ack_o(ack),
        .stb_i(stb)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, loopback_tb);

        rst_i = 0;
        clk_i = 0;

        #1;
        rst_i = 1;
        #10;
        rst_i = 0;

        #1000;

        $finish;
    end

    always begin
        #10 clk_i = ~clk_i;
    end
endmodule
