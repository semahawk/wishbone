`timescale 1us / 1ns

module wb_intercon_tb ();
    localparam MASTERS_NUM = 2;
    localparam SLAVES_NUM = 2;

    reg rst_o;
    reg clk_o;

    wire m0_nop_ack_i;
    wire m0_nop_cyc_o;
    wire m0_nop_stb_o;

    wire m1_nop_ack_i;
    wire m1_nop_cyc_o;
    wire m1_nop_stb_o;

    wire s0_nop_stb_i;
    wire s0_nop_cyc_i;
    wire s0_nop_ack_o;

    wire s1_nop_stb_i;
    wire s1_nop_cyc_i;
    wire s1_nop_ack_o;

    wb_intercon #(
        .MASTERS_NUM(MASTERS_NUM),
        .SLAVES_NUM(SLAVES_NUM)
    ) wb_intercon_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .m2i_cyc_i({ m1_nop_cyc_o, m0_nop_cyc_o }),
        .m2i_stb_i({ m1_nop_stb_o, m0_nop_stb_o }),
        .m2i_adr_i({ 16'h1000, 16'h0000 }),
        .i2m_ack_o({ m1_nop_ack_i, m0_nop_ack_i }),
        .s2i_ack_i({ s1_nop_ack_o, s0_nop_ack_o }),
        .i2s_cyc_o({ s1_nop_cyc_i, s0_nop_cyc_i }),
        .i2s_stb_o({ s1_nop_stb_i, s0_nop_stb_i })
    );

    wb_master_nop #(
        .INITIAL_DELAY(4),
        .WAIT_CYCLES(0)
    ) wb_master0_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_o(m0_nop_cyc_o),
        .stb_o(m0_nop_stb_o),
        .ack_i(m0_nop_ack_i)
    );

    wb_master_nop #(
        .INITIAL_DELAY(2),
        .WAIT_CYCLES(0)
    ) wb_master1_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_o(m1_nop_cyc_o),
        .stb_o(m1_nop_stb_o),
        .ack_i(m1_nop_ack_i)
    );

    wb_slave_nop wb_slave0_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_i(s0_nop_cyc_i),
        .stb_i(s0_nop_stb_i),
        .ack_o(s0_nop_ack_o)
    );

    wb_slave_nop wb_slave1_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_i(s1_nop_cyc_i),
        .stb_i(s1_nop_stb_i),
        .ack_o(s1_nop_ack_o)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0);

        rst_o = 0;
        clk_o = 0;

        $display("hello, world");

        #1000;

        $finish;
    end

    always begin
        #10 clk_o = ~clk_o;
    end

endmodule