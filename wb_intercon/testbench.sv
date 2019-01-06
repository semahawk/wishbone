`timescale 1us / 1ns

module wb_intercon_tb ();
    localparam MASTERS_NUM = 3;
    localparam SLAVES_NUM = 3;
    localparam ADDR_WIDTH = 16;
    localparam DATA_WIDTH = 32;
    localparam GRANULE = 8;

    reg rst_o;
    reg clk_o;

    wire m0_nop_cyc_o;
    wire m0_nop_stb_o;
    wire m0_nop_ack_i;

    wire m1_nop_cyc_o;
    wire m1_nop_stb_o;
    wire m1_nop_ack_i;

    wire m2_mem_cyc_o;
    wire m2_mem_stb_o;
    wire m2_mem_we_o;
    wire [ADDR_WIDTH-1:0] m2_mem_adr_o;
    wire [DATA_WIDTH-1:0] m2_mem_dat_o;
    wire [7:0] m2_mem_sel_o;
    wire m2_mem_ack_i;
    wire m2_mem_err_i;

    wire s0_nop_stb_i;
    wire s0_nop_ack_o;

    wire s1_nop_stb_i;
    wire s1_nop_ack_o;

    wire s2_reg_stb_i;
    wire s2_reg_ack_o;
    wire s2_reg_err_o;
    wire [DATA_WIDTH-1:0] s2_reg_dat_o;

    // wires shared across all masters
    wire [DATA_WIDTH-1:0] master_dat_i;

    // wires shared across all slaves
    wire slave_cyc_i;
    wire slave_we_i;
    wire [ADDR_WIDTH-1:0] slave_adr_i;
    wire [DATA_WIDTH-1:0] slave_dat_i;
    wire [7:0] slave_sel_i;

    wire nc;

    wb_intercon #(
        .MASTERS_NUM(MASTERS_NUM),
        .SLAVES_NUM(SLAVES_NUM)
    ) wb_intercon_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .m2i_cyc_i({ m2_mem_cyc_o, m1_nop_cyc_o, m0_nop_cyc_o }),
        .m2i_stb_i({ m2_mem_stb_o, m1_nop_stb_o, m0_nop_stb_o }),
        .m2i_we_i({ m2_mem_we_o, 1'b0, 1'b0 }),
        .m2i_adr_i({ m2_mem_adr_o, 16'h1000, 16'h0000 }),
        .m2i_dat_i({ m2_mem_dat_o, 32'h0000, 32'h0000 }),
        .m2i_sel_i({ 8'hff, 8'h00, 8'h00 }),
        .i2m_ack_o({ m2_mem_ack_i, m1_nop_ack_i, m0_nop_ack_i }),
        .i2m_err_o({ m2_mem_err_i, nc, nc }),
        .i2m_dat_o(master_dat_i),
        .s2i_ack_i({ s2_reg_ack_o, s1_nop_ack_o, s0_nop_ack_o }),
        .s2i_err_i({ s2_reg_err_o, 1'b0, 1'b0 }),
        .s2i_dat_i({ s2_reg_dat_o, 32'b0, 32'b0 }),
        .i2s_stb_o({ s2_reg_stb_i, s1_nop_stb_i, s0_nop_stb_i }),
        .i2s_cyc_o(slave_cyc_i),
        .i2s_adr_o(slave_adr_i),
        .i2s_dat_o(slave_dat_i),
        .i2s_sel_o(slave_sel_i),
        .i2s_we_o(slave_we_i)
    );

    wb_master_nop #(
        .INITIAL_DELAY(1),
        .WAIT_CYCLES(0)
    ) wb_master0_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_o(m0_nop_cyc_o),
        .stb_o(m0_nop_stb_o),
        .ack_i(m0_nop_ack_i)
    );

    wb_master_nop #(
        .INITIAL_DELAY(1),
        .WAIT_CYCLES(0)
    ) wb_master1_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_o(m1_nop_cyc_o),
        .stb_o(m1_nop_stb_o),
        .ack_i(m1_nop_ack_i)
    );

    wb_master_seq_mem_access #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .START_ADDR(16'h2000),
        .END_ADDR(16'h200f)
    ) wb_master2_mem_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .stb_o(m2_mem_stb_o),
        .cyc_o(m2_mem_cyc_o),
        .we_o(m2_mem_we_o),
        .adr_o(m2_mem_adr_o),
        .dat_o(m2_mem_dat_o),
        .dat_i(master_dat_i),
        .ack_i(m2_mem_ack_i),
        .err_i(m2_mem_err_i)
    );

    wb_slave_nop wb_slave0_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_i(slave_cyc_i),
        .stb_i(s0_nop_stb_i),
        .ack_o(s0_nop_ack_o)
    );

    wb_slave_nop wb_slave1_nop_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_i(slave_cyc_i),
        .stb_i(s1_nop_stb_i),
        .ack_o(s1_nop_ack_o)
    );

    wb_slave_register #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .GRANULE(GRANULE)
    ) wb_slave2_reg_dut (
        .rst_i(rst_o),
        .clk_i(clk_o),
        .cyc_i(slave_cyc_i),
        .stb_i(s2_reg_stb_i),
        .ack_o(s2_reg_ack_o),
        .adr_i(slave_adr_i),
        .dat_i(slave_dat_i),
        .dat_o(s2_reg_dat_o),
        .sel_i(slave_sel_i),
        .we_i(slave_we_i),
        .err_o(s2_reg_err_o)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0);

        rst_o = 0;
        clk_o = 0;

        #2000;

        $finish;
    end

    always begin
        #10 clk_o = ~clk_o;
    end

endmodule