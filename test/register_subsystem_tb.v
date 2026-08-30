`timescale 1ns/1ps

module register_subsystem_tb;
    reg clk = 0;
    reg rstn = 0;
    reg load_start = 0;
    reg commit_start = 0;
    reg execute = 0;
    wire load_done;
    wire commit_done;
    wire transaction_busy;
    reg [3:0] next_rs1 = 0;
    reg [3:0] next_rs2 = 0;
    reg [3:0] rs1 = 0;
    reg [3:0] rs2 = 0;
    reg [3:0] rd = 0;
    reg [4:0] counter = 0;
    reg wr_en = 0;
    reg wr_next_en = 0;
    reg read_through = 0;
    wire data_rs1;
    wire data_rs2;
    reg data_rd = 0;
    reg data_rd_next = 0;
    wire spi_select;
    wire spi_out;
    wire spi_clk_enable;
    wire spi_miso;
    reg buffered_spi_in;
    wire [31:0] debug_data;
    reg [31:0] expected_rs1 = 32'h89abcdef;
    reg [31:0] expected_rs2 = 32'h13579bdf;
    integer bit_index;

    wire spi_clk = !clk && spi_clk_enable;
    always #5 clk = ~clk;
    always @(negedge clk)
        buffered_spi_in <= spi_miso;

    nanoV_external_register_subsystem dut (
        clk, rstn, load_start, commit_start, execute,
        load_done, commit_done, transaction_busy,
        next_rs1, next_rs2, rs1, rs2, rd, counter,
        wr_en, wr_next_en, read_through, data_rs1, data_rs2,
        data_rd, data_rd_next,
        buffered_spi_in, spi_select, spi_out, spi_clk_enable
    );

    sim_spi_ram ram (
        spi_clk, spi_out, spi_select, spi_miso,
        clk, 24'h000000, debug_data
    );
    defparam ram.INIT_FILE = "test/test.mem";
    defparam ram.INIT_WORDS = 97;

    task load_operands;
        input [3:0] source1;
        input [3:0] source2;
        input [3:0] destination;
        begin
            @(posedge clk);
            rs1 <= source1;
            rs2 <= source2;
            rd <= destination;
            load_start <= 1;
            @(posedge clk);
            load_start <= 0;
            while (!load_done) @(posedge clk);
            if (transaction_busy) $fatal(1, "load_done asserted while subsystem remained busy");
        end
    endtask

    task commit_result;
        begin
            @(posedge clk);
            commit_start <= 1;
            @(posedge clk);
            commit_start <= 0;
            while (!commit_done) @(posedge clk);
            if (transaction_busy) $fatal(1, "commit_done asserted while subsystem remained busy");
        end
    endtask

    task store_register;
        input [3:0] destination;
        input [31:0] value;
        begin
            load_operands(4'd0, 4'd0, destination);
            execute = 1;
            wr_en = 1;
            for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
                @(negedge clk);
                counter = bit_index;
                data_rd = value[bit_index];
                @(posedge clk);
            end
            #1 execute = 0;
            wr_en = 0;
            if (dut.write_word !== value)
                $fatal(1, "staging write mismatch before commit");
            commit_result();
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rstn <= 1;

        store_register(4'd5, 32'h89abcdef);
        store_register(4'd15, 32'h13579bdf);

        load_operands(4'd5, 4'd15, 4'd0);
        execute = 1;
        for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
            @(negedge clk);
            counter = bit_index;
            #1;
            if (data_rs1 !== expected_rs1[bit_index])
                $fatal(1, "subsystem rs1 mismatch at bit %0d", bit_index);
            if (data_rs2 !== expected_rs2[bit_index])
                $fatal(1, "subsystem rs2 mismatch at bit %0d", bit_index);
            @(posedge clk);
        end
        execute = 0;

        $display("external register subsystem passed");
        $finish;
    end
endmodule
