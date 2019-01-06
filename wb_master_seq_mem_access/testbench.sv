/* dupa */

module wb_master_seq_mem_access_tb ();
    localparam ADDR_WIDTH = 16;
    localparam DATA_WIDTH = 32;

    reg rst_i;
    reg clk_i;
    reg stb_i;
    reg cyc_i;
    reg [ADDR_WIDTH-1:0] adr_i;
    reg [DATA_WIDTH-1:0] dat_i;
    reg [DATA_WIDTH-1:0] dat_o;
    reg we_i;
    reg ack_o;
    reg err_o;
    int i;

    reg [DATA_WIDTH-1:0] input_data;
    reg [DATA_WIDTH-1:0] output_data;

    wb_master_seq_mem_access #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .START_ADDR(0),
        .END_ADDR(7),
        .STEP(1)
    ) master_tb (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .stb_o(stb_i),
        .cyc_o(cyc_i),
        .we_o(we_i),
        .adr_o(adr_i),
        .dat_o(dat_i),
        .dat_i(dat_o),
        .ack_i(ack_o),
        .err_i(err_o)
    );

    task cycle;
        $display("Waiting for STB to be asserted");
        @(posedge stb_i);

        if (we_i != 1) begin
            $display("Not a write cycle!");
            $finish;
        end

        input_data = dat_i;

        $display("Write cycle started");
        $display("Responding with ACK");

        ack_o = 1;

        $display("Waiting for phase end");
        @(negedge stb_i);

        ack_o = 0;

        $display("Waiting for the read cycle...");

        @(posedge stb_i);

        if (we_i != 0) begin
            $display("Not a read cycle!");
            $finish;
        end

        $display("Responding with ACK");
        dat_o = input_data;
        ack_o = 1;

        $display("Waiting for phase end");
        @(negedge stb_i);

        ack_o = 0;

    endtask

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, master_tb);

        rst_i = 0;
        clk_i = 0;
        ack_o = 0;
        err_o = 0;
        dat_o = 0;

        for (i = 0; i < 16; i++) begin
            #2 cycle();
        end

        #2;

        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
