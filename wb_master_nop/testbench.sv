module wb_master_nop_tb ();
    reg rst_i;
    reg clk_i;
    reg ack_o;
    reg stb_i;
    reg cyc_i;
    int i;

    wb_master_nop master_tb (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .cyc_o(cyc_i),
        .ack_i(ack_o),
        .stb_o(stb_i)
    );

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, master_tb);

        rst_i = 0;
        clk_i = 0;
        ack_o = 0;

        for (i = 0; i < 16; i++) begin
            $display("Waiting for phase start");
            @(posedge stb_i);

            $display("Responding with ACK");

            ack_o = 1;

            $display("Waiting for phase end");
            @(negedge stb_i);

            ack_o = 0;
        end

        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
