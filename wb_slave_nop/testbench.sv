module wb_slave_nop_tb ();
    reg rst_o;
    reg clk_i;
    reg ack_i;
    reg stb_o;
    reg cyc_o;

    wb_slave_nop slave_tb (
        .rst_i(rst_o),
        .clk_i(clk_i),
        .cyc_i(cyc_o),
        .ack_o(ack_i),
        .stb_i(stb_o)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, slave_tb);

        clk_i = 0;
        cyc_o = 0;
        stb_o = 0;

        $display("Resetting the slave");

        #1;
        rst_o = 1;
        #1;
        rst_o = 0;

        #10;

        $display("Waiting for positive edge of the clock");

        @(posedge clk_i);

        $display("Starting the cycle");

        stb_o = 1;
        cyc_o = 1;

        $display("Waiting for positive edge of the clock");
        #1;

        while (ack_i != 1) begin
          $display("Waiting for an ACK...");
          @(posedge clk_i);
        end

        $display("Got an ACK");
        $display("Ending the cycle");

        stb_o = 0;
        cyc_o = 0;

        #4;

        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
