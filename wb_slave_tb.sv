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

    reg [`DATA_WIDTH-1:0] read_data;

    wb_slave slave_tb (
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

    task single_read;
        input  [`ADDR_WIDTH-1:0] addr;
        output [`DATA_WIDTH-1:0] data;

        $display("%g: Single Read (addr: %x)", $time, addr);

        #1;

        adr_o = addr;
        we_o = 1'h0;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        while (ack_i != 1'h1) begin
            #1;
        end

        data = dat_i;

        $display("%g: -> Received data: %x", $time, dat_i);

        stb_o = 1'h0;
        cyc_o = 1'h0;

        #1;
    endtask

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, slave_tb);

        clk_i = 0;

        single_read(8'h00, read_data);

        $finish;
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
