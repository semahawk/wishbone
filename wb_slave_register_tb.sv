`define OP_CLASSIC_SINGLE_READ  0
`define OP_CLASSIC_SINGLE_WRITE 1

module wb_slave_register_tb ();
    localparam ADDR_WIDTH = 16;
    localparam DATA_WIDTH = 32;
    localparam GRANULE = 8;
    localparam SEL_WIDTH = DATA_WIDTH / GRANULE;

    reg rst_i;
    reg clk_i;
    reg ack_i;
    reg stb_o;
    reg [ADDR_WIDTH-1:0] adr_o;
    reg [DATA_WIDTH-1:0] dat_i;
    reg [DATA_WIDTH-1:0] dat_o;
    reg [SEL_WIDTH-1:0] sel_o;
    reg we_o;
    reg cyc_o;

    reg [DATA_WIDTH-1:0] read_data;

    reg [4+SEL_WIDTH+ADDR_WIDTH+DATA_WIDTH*2-1:0] testvector [31:0];
    reg [3:0] tv_op;
    reg [SEL_WIDTH-1:0] tv_sel;
    reg [ADDR_WIDTH-1:0] tv_addr;
    reg [DATA_WIDTH-1:0] tv_write_data;
    reg [DATA_WIDTH-1:0] tv_expected_data;
    int current_test_num = 0;
    int errors = 0;

    wb_slave_register #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .GRANULE(GRANULE)
    ) slave_tb (
        .rst_i(rst_i),
        .clk_i(clk_i),
        .adr_i(adr_o),
        .dat_o(dat_i),
        .dat_i(dat_o),
        .we_i(we_o),
        .cyc_i(cyc_o),
        .ack_o(ack_i),
        .stb_i(stb_o),
        .sel_i(sel_o)
    );

    task single_read;
        input  [ADDR_WIDTH-1:0] addr;
        input  [7:0] selection;
        output [DATA_WIDTH-1:0] data;

        #1;

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection);

        adr_o = addr;
        sel_o = selection;
        we_o = 1'h0;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        while (ack_i != 1'h1) begin
            $display(".. %03g: Waiting for ACK...", $time);
            #1;
        end

        data = dat_i;

        $display(".. %03g: Received data: 0x%x", $time, data);
        $display(".. %03g: Ending cycle (cyc_o -> 0, stb_o -> 0)", $time);

        stb_o = 1'h0;
        cyc_o = 1'h0;

        #2;
    endtask

    task single_write;
        input [ADDR_WIDTH-1:0] addr;
        input [7:0] selection;
        input [DATA_WIDTH-1:0] data;

        #1;

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, dat_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection, data);

        adr_o = addr;
        sel_o = selection;
        dat_o = data;
        we_o = 1'h1;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        while (ack_i != 1'h1) begin
            $display(".. %03g: Waiting for ACK...", $time);
            #1;
        end

        $display(".. %03g: Ending cycle (cyc_o -> 0, stb_o -> 0, we_o -> 0)", $time);

        stb_o = 1'h0;
        cyc_o = 1'h0;
        we_o = 1'h0;

        #2;
    endtask

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, slave_tb);

        $readmemh("wb_slave_register_testvector.tv", testvector);

        clk_i = 0;
        cyc_o = 0;
        stb_o = 0;
        we_o = 0;
        adr_o = 0;
        dat_o = 0;

        for (int i = 0; i < 32; i++) begin
            { tv_op, tv_sel, tv_addr, tv_write_data, tv_expected_data } = testvector[i];

            if (tv_op === 4'hx) begin
                $display("");
                $display("Completed %1d tests, %1d failed, %.2f%% success ratio",
                    current_test_num, errors, (current_test_num - errors) * 100 / current_test_num);
                $finish;
            end

            current_test_num = current_test_num + 1;

            case (tv_op)
                `OP_CLASSIC_SINGLE_READ: begin
                    $display("## Test %1d: Classic Single Read", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Selection: 0x%x", tv_sel);
                    $display("-- Expected output data: 0x%x", tv_expected_data);

                    single_read(tv_addr, tv_sel, read_data);

                    if (tv_expected_data == read_data) begin
                        $display("## Test %1d: OK", current_test_num);
                    end else begin
                        if (tv_expected_data != read_data)
                            $display("!! Mismatch!");
                            $display("!! Expected 0x%x, got 0x%x (xor: 0x%x)",
                                tv_expected_data, read_data, tv_expected_data ^ read_data);
                            $display("!! NOK!");
                            errors = errors + 1;
                    end
                end
                `OP_CLASSIC_SINGLE_WRITE: begin
                    $display("## Test %1d: Classic Single Write", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Selection: 0x%x", tv_sel);

                    single_write(tv_addr, tv_sel, tv_write_data);

                    $display("## Test %1d: OK", current_test_num);
                end
                default: begin
                    $error("# test %2d: Unknown op: %x",
                        current_test_num, tv_op);

                    errors = errors + 1;
                end
            endcase
        end
    end

    always begin
        #1 clk_i = ~clk_i;
    end
endmodule
