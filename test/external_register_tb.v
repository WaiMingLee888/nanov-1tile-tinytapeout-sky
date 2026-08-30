`timescale 1ns/1ps

module external_register_tb;
    reg clk = 0;
    reg rstn = 0;
    reg load_sources = 0;
    reg [31:0] rs1_word = 0;
    reg [31:0] rs2_word = 0;
    reg wr_en = 0;
    reg wr_next_en = 0;
    reg read_through = 0;
    reg [4:0] counter = 0;
    reg [3:0] next_rs1 = 0;
    reg [3:0] next_rs2 = 0;
    reg [3:0] rs1 = 5;
    reg [3:0] rs2 = 6;
    reg [3:0] rd = 7;
    reg data_rd = 0;
    reg data_rd_next = 0;
    wire data_rs1;
    wire data_rs2;
    wire [31:0] write_word;
    wire write_required;

    reg [31:0] expected_rs1 = 32'h89abcdef;
    reg [31:0] expected_rs2 = 32'h13579bdf;
    reg [31:0] expected_write = 32'h5aa5c33c;
    integer bit_index;

    always #5 clk = ~clk;

    nanoV_external_registers dut (
        clk, rstn, load_sources, rs1_word, rs2_word,
        wr_en, wr_next_en, read_through, counter,
        next_rs1, next_rs2, rs1, rs2, rd,
        data_rs1, data_rs2, data_rd, data_rd_next,
        write_word, write_required
    );

    initial begin
        repeat (2) @(posedge clk);
        rstn <= 1;
        rs1_word <= expected_rs1;
        rs2_word <= expected_rs2;
        load_sources <= 1;
        @(posedge clk);
        #1 load_sources <= 0;

        for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
            counter = bit_index;
            #1;
            if (data_rs1 !== expected_rs1[bit_index]) $fatal(1, "rs1 bit mismatch at %0d", bit_index);
            if (data_rs2 !== expected_rs2[bit_index]) $fatal(1, "rs2 bit mismatch at %0d", bit_index);
            data_rd = expected_write[bit_index];
            wr_en = 1;
            @(posedge clk);
        end
        #1 wr_en = 0;

        if (write_word !== expected_write) $fatal(1, "write word mismatch: %h", write_word);
        if (!write_required) $fatal(1, "x7 write was not requested");

        // SLT writes its final bit through wr_next_en at the instruction
        // boundary. Verify that the external word retains this behavior.
        rd = 8;
        data_rd = 0;
        for (bit_index = 0; bit_index < 32; bit_index = bit_index + 1) begin
            counter = bit_index;
            wr_en = 1;
            wr_next_en = bit_index == 31;
            data_rd_next = bit_index == 31;
            @(posedge clk);
        end
        #1 wr_en = 0;
        wr_next_en = 0;
        data_rd_next = 0;
        if (write_word !== 32'h00000001) $fatal(1, "SLT write word mismatch: %h", write_word);

        rs1 = 0;
        rs2 = 3;
        counter = 12;
        #1;
        if (data_rs1 !== 0 || data_rs2 !== 1) $fatal(1, "x0/x3 constants failed");
        rs2 = 4;
        counter = 28;
        #1;
        if (data_rs2 !== 1) $fatal(1, "x4 constant failed");

        rd = 0;
        #1;
        if (write_required) $fatal(1, "x0 must not be written externally");

        $display("external register staging passed");
        $finish;
    end
endmodule
