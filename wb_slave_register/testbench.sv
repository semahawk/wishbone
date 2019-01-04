typedef enum {
    OP_CLASSIC_SINGLE_READ,
    OP_CLASSIC_SINGLE_WRITE,
    OP_READ_MODIFY_WRITE,
    OP_PIPELINED_SINGLE_READ,
    OP_PIPELINED_SINGLE_WRITE
} op_t;

typedef enum {
    RETURN_ACK,
    RETURN_ERR
} ret_t;

module wb_slave_register_tb ();
    localparam ADDR_WIDTH = 16;
    localparam DATA_WIDTH = 32;
    localparam GRANULE = 8;
    localparam SEL_WIDTH = DATA_WIDTH / GRANULE;

    reg rst_o;
    reg clk_i;
    reg ack_i;
    reg err_i;
    reg stb_o;
    reg [ADDR_WIDTH-1:0] adr_o;
    reg [DATA_WIDTH-1:0] dat_i;
    reg [DATA_WIDTH-1:0] dat_o;
    reg [SEL_WIDTH-1:0] sel_o;
    reg we_o;
    reg cyc_o;

    reg [DATA_WIDTH-1:0] read_data;
    reg [3:0] return_type;

    reg [4+SEL_WIDTH+ADDR_WIDTH+DATA_WIDTH*2+4-1:0] testvector [31:0];
    reg [3:0] tv_op;
    reg [SEL_WIDTH-1:0] tv_sel;
    reg [ADDR_WIDTH-1:0] tv_addr;
    reg [DATA_WIDTH-1:0] tv_write_data;
    reg [DATA_WIDTH-1:0] tv_expected_data;
    reg [3:0] tv_return_type;
    int current_test_num = 0;
    int errors = 0;
    int i = 0;

    wb_slave_register #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .GRANULE(GRANULE)
    ) slave_tb (
        .rst_i(rst_o),
        .clk_i(clk_i),
        .adr_i(adr_o),
        .dat_o(dat_i),
        .dat_i(dat_o),
        .we_i(we_o),
        .cyc_i(cyc_o),
        .ack_o(ack_i),
        .err_o(err_i),
        .stb_i(stb_o),
        .sel_i(sel_o)
    );

    task single_read;
        input  [ADDR_WIDTH-1:0] addr;
        input  [7:0] selection;
        output [DATA_WIDTH-1:0] data;
        output [3:0] return_type;

        @(posedge clk_i);

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection);

        adr_o = addr;
        sel_o = selection;
        we_o = 1'h0;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        while (ack_i != 1'h1 && err_i != 1'h1) begin
            $display(".. %03g: Waiting for ACK or ERR...", $time);
            @(posedge clk_i);
        end

        if (err_i == 1'h1) begin
            $display(".. %03g: Got ERR", $time);
            return_type = RETURN_ERR;
        end else if (ack_i == 1'h1) begin
            $display(".. %03g: Got ACK", $time);
            data = dat_i;
            $display(".. %03g: Received data: 0x%x", $time, data);
            return_type = RETURN_ACK;
        end

        $display(".. %03g: Ending cycle (cyc_o -> 0, stb_o -> 0)", $time);

        stb_o = 1'h0;
        cyc_o = 1'h0;

        #1;
    endtask

    task single_write;
        input [ADDR_WIDTH-1:0] addr;
        input [7:0] selection;
        input [DATA_WIDTH-1:0] data;
        output [3:0] return_type;

        @(posedge clk_i);

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, dat_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection, data);

        adr_o = addr;
        sel_o = selection;
        dat_o = data;
        we_o = 1'h1;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        while (ack_i != 1'h1 && err_i != 1'h1) begin
            $display(".. %03g: Waiting for ACK or ERR...", $time);
            @(posedge clk_i);
        end

        if (err_i == 1'h1) begin
            $display(".. %03g: Got ERR", $time);
            return_type = RETURN_ERR;
        end else if (ack_i == 1'h1) begin
            $display(".. %03g: Got ACK", $time);
            return_type = RETURN_ACK;
        end

        $display(".. %03g: Ending cycle (cyc_o -> 0, stb_o -> 0, we_o -> 0)", $time);

        stb_o = 1'h0;
        cyc_o = 1'h0;
        we_o = 1'h0;

        #1;
    endtask

    task read_modify_write;
        input  [ADDR_WIDTH-1:0] addr;
        input  [7:0] selection;
        input  [DATA_WIDTH-1:0] write_data;
        output [DATA_WIDTH-1:0] read_data;
        output [3:0] return_type;

        @(posedge clk_i);

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection);
        $display(".. %03g: Read phase (stb_o -> 1)", $time);

        adr_o = addr;
        sel_o = selection;
        we_o = 1'h0;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        @(posedge clk_i);

        stb_o = 1'h0;

        while (ack_i != 1'h1 && err_i != 1'h1) begin
            $display(".. %03g: Waiting for ACK or ERR...", $time);
            @(posedge clk_i);
        end

        if (err_i == 1'h1) begin
            $display(".. %03g: Got ERR", $time);
            return_type = RETURN_ERR;
        end else if (ack_i == 1'h1) begin
            $display(".. %03g: Got ACK", $time);
            return_type = RETURN_ACK;
        end

        read_data = dat_i;

        $display(".. %03g: Received data: 0x%x", $time, read_data);
        $display(".. %03g: Ending phase (stb_o -> 0)", $time);

        // set the data up before the next posedge
        @(negedge clk_i);

        $display(".. %03g: Write phase (dat_o -> 0x%x, stb_o -> 1)", $time, write_data);

        dat_o = write_data;
        we_o = 1'h1;
        stb_o = 1'h1;

        // wait two posedges so the slave has time to latch the data in
        @(posedge clk_i);
        @(posedge clk_i);

        stb_o = 1'h0;
        we_o = 1'h0;

        i = 0;
        while (ack_i != 1'h1 && err_i != 1'h1 && i < 10) begin
            $display(".. %03g: Waiting for ACK or ERR...", $time);
            @(posedge clk_i);
            i = i+1;
        end

        if (err_i == 1'h1) begin
            $display(".. %03g: Got ERR", $time);
            return_type = RETURN_ERR;
        end else if (ack_i == 1'h1) begin
            $display(".. %03g: Got ACK", $time);
            return_type = RETURN_ACK;
        end

        $display(".. %03g: Ending cycle (cyc_o -> 0, stb_o -> 0, we_o -> 0)", $time);

        stb_o = 1'h0;
        cyc_o = 1'h0;
        we_o = 1'h0;

        #1;
    endtask

    task pipelined_single_read;
        input  [ADDR_WIDTH-1:0] addr;
        input  [7:0] selection;
        output [DATA_WIDTH-1:0] data;
        output [3:0] return_type;

        @(posedge clk_i);

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection);

        adr_o = addr;
        sel_o = selection;
        we_o = 1'h0;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        @(posedge clk_i);

        adr_o = {ADDR_WIDTH{1'bx}};
        sel_o = {SEL_WIDTH{1'bx}};
        stb_o = 1'h0;
        i = 0;

        while (ack_i != 1'h1 && err_i != 1'h1 && i < 10) begin
            $display(".. %03g: Waiting for ACK or ERR...", $time);
            @(posedge clk_i);
            i = i+1;
        end

        if (err_i == 1'h1) begin
            $display(".. %03g: Got ERR", $time);
            return_type = RETURN_ERR;
        end else if (ack_i == 1'h1) begin
            $display(".. %03g: Got ACK", $time);
            data = dat_i;
            $display(".. %03g: Received data: 0x%x", $time, data);
            return_type = RETURN_ACK;
        end

        $display(".. %03g: Ending cycle (cyc_o -> 0, stb_o -> 0)", $time);

        cyc_o = 1'h0;

        #1;
    endtask

    task pipelined_single_write;
        input [ADDR_WIDTH-1:0] addr;
        input [7:0] selection;
        input [DATA_WIDTH-1:0] data;
        output [3:0] return_type;

        @(posedge clk_i);

        $display(".. %03g: Starting a cycle (adr_o -> 0x%x, sel_o -> 0x%x, dat_o -> 0x%x, we_o -> 0, cyc_o -> 1, stb_o -> 1)",
            $time, addr, selection, data);

        adr_o = addr;
        sel_o = selection;
        dat_o = data;
        we_o = 1'h1;
        cyc_o = 1'h1;
        stb_o = 1'h1;

        @(posedge clk_i);

        adr_o = {ADDR_WIDTH{1'bx}};
        dat_o = {DATA_WIDTH{1'bx}};
        sel_o = {SEL_WIDTH{1'bx}};
        we_o = 1'h0;
        stb_o = 1'h0;

        while (ack_i != 1'h1 && err_i != 1'h1) begin
            $display(".. %03g: Waiting for ACK or ERR...", $time);
            @(posedge clk_i);
        end

        if (err_i == 1'h1) begin
            $display(".. %03g: Got ERR", $time);
            return_type = RETURN_ERR;
        end else if (ack_i == 1'h1) begin
            $display(".. %03g: Got ACK", $time);
            return_type = RETURN_ACK;
        end

        $display(".. %03g: Ending cycle (cyc_o -> 0)", $time);

        cyc_o = 1'h0;

        #1;
    endtask

    initial begin
        $dumpfile(`WAVE_FILE);
        $dumpvars(0, slave_tb);

        $readmemh("testvector.tv", testvector);

        clk_i = 0;
        cyc_o = 0;
        stb_o = 0;
        we_o = 0;
        adr_o = 0;
        dat_o = 0;

        // reset the slave
        #1;
        rst_o = 1;
        #1;
        rst_o = 0;

        #10;

        for (int i = 0; i < 32; i++) begin
            { tv_op, tv_sel, tv_addr, tv_write_data, tv_expected_data, tv_return_type } = testvector[i];

            if (tv_op === 4'hx) begin
                $display("");
                $display("Completed %1d tests, %1d failed, %.2f%% success ratio",
                    current_test_num, errors, (current_test_num - errors) * 100 / current_test_num);
                $finish;
            end

            current_test_num = current_test_num + 1;

            case (tv_op)
                OP_CLASSIC_SINGLE_READ: begin
                    $display("## Test %1d: Classic Single Read", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Selection: 0x%x", tv_sel);
                    $display("-- Expected output data: 0x%x", tv_expected_data);

                    single_read(tv_addr, tv_sel, read_data, return_type);

                    if (tv_expected_data != read_data) begin
                        $display("!! Mismatch!");
                        $display("!! Expected 0x%x, got 0x%x (xor: 0x%x)",
                            tv_expected_data, read_data, tv_expected_data ^ read_data);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else if (tv_return_type != return_type) begin
                        $display("!! Mismatch!");
                        $display("!! Expected return with %1d, got %1d", tv_return_type, return_type);
                        $display("!! (ACK is %1d, ERR is %1d)", RETURN_ACK, RETURN_ERR);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else begin
                        $display("## Test %1d: OK", current_test_num);
                    end
                end
                OP_CLASSIC_SINGLE_WRITE: begin
                    $display("## Test %1d: Classic Single Write", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Input data: 0x%x", tv_write_data);
                    $display("-- Selection: 0x%x", tv_sel);

                    single_write(tv_addr, tv_sel, tv_write_data, return_type);

                    if (tv_return_type != return_type) begin
                        $display("!! Mismatch!");
                        $display("!! Expected return with %1d, got %1d", tv_return_type, return_type);
                        $display("!! (ACK is %1d, ERR is %1d)", RETURN_ACK, RETURN_ERR);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else begin
                        $display("## Test %1d: OK", current_test_num);
                    end
                end
                OP_READ_MODIFY_WRITE: begin
                    $display("## Test %1d: Read Modify Write", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Selection: 0x%x", tv_sel);
                    $display("-- Input data: 0x%x", tv_write_data);
                    $display("-- Expected read: 0x%x", tv_expected_data);

                    read_modify_write(tv_addr, tv_sel, tv_write_data, read_data, return_type);

                    if (tv_expected_data != read_data) begin
                        $display("!! Mismatch!");
                        $display("!! Expected 0x%x, got 0x%x (xor: 0x%x)",
                            tv_expected_data, read_data, tv_expected_data ^ read_data);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else if (tv_return_type != return_type) begin
                        $display("!! Mismatch!");
                        $display("!! Expected return with %1d, got %1d", tv_return_type, return_type);
                        $display("!! (ACK is %1d, ERR is %1d)", RETURN_ACK, RETURN_ERR);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else begin
                        $display("## Test %1d: OK", current_test_num);
                    end
                end
                OP_PIPELINED_SINGLE_READ: begin
                    $display("## Test %1d: Pipelined Single Read", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Selection: 0x%x", tv_sel);
                    $display("-- Expected output data: 0x%x", tv_expected_data);

                    pipelined_single_read(tv_addr, tv_sel, read_data, return_type);

                    if (tv_expected_data != read_data) begin
                        $display("!! Mismatch!");
                        $display("!! Expected 0x%x, got 0x%x (xor: 0x%x)",
                            tv_expected_data, read_data, tv_expected_data ^ read_data);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else if (tv_return_type != return_type) begin
                        $display("!! Mismatch!");
                        $display("!! Expected return with %1d, got %1d", tv_return_type, return_type);
                        $display("!! (ACK is %1d, ERR is %1d)", RETURN_ACK, RETURN_ERR);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else begin
                        $display("## Test %1d: OK", current_test_num);
                    end
                end
                OP_PIPELINED_SINGLE_WRITE: begin
                    $display("## Test %1d: Pipelined Single Write", current_test_num);
                    $display("-- Address: 0x%x", tv_addr);
                    $display("-- Input data: 0x%x", tv_write_data);
                    $display("-- Selection: 0x%x", tv_sel);

                    pipelined_single_write(tv_addr, tv_sel, tv_write_data, return_type);

                    if (tv_return_type != return_type) begin
                        $display("!! Mismatch!");
                        $display("!! Expected return with %1d, got %1d", tv_return_type, return_type);
                        $display("!! (ACK is %1d, ERR is %1d)", RETURN_ACK, RETURN_ERR);
                        $display("!! NOK!");
                        errors = errors + 1;
                    end else begin
                        $display("## Test %1d: OK", current_test_num);
                    end
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
