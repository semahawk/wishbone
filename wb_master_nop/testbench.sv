module wb_master_nop_tb ();
    reg rst_i;
    reg clk_i;
    reg ack_o;
    reg stb_i;
    reg cyc_i;
    reg trigger_o;
    int i;

    wb_master_nop master_tb (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .cyc_o(cyc_i),
        .ack_i(ack_o),
        .stb_o(stb_i),
        // non-Wishbone signals
        .trigger_i(trigger_o)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, master_tb);

        rst_i = 0;
        clk_i = 0;
        ack_o = 0;
        trigger_o = 0;

        #4;

        trigger_o = 1;

        $display("Waiting for STB to be asserted");
        @(posedge stb_i);

        trigger_o = 0;

        $display("Phase started - STB asserted");
        $display("Responding with ACK");

        ack_o = 1;

        $display("Waiting for phase end");
        @(negedge stb_i);

        ack_o = 0;

        #4;

        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
