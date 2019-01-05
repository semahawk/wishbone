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

        i = 0;
        while (stb_i != 1 && i < 10) begin
            $display("Waiting for STB to be asserted");
            @(posedge clk_i);
            i = i + 1;
        end

        if (i == 10) begin
            $display("Failed to receive an ACK after 10 clocks!");
            $finish;
        end

        trigger_o = 0;

        $display("Phase started - STB asserted");
        $display("Responding with ACK");

        ack_o = 1;

        while (stb_i != 0) begin
            $display("Waiting for phase end");
            @(posedge clk_i);
        end

        ack_o = 0;

        #4;

        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
