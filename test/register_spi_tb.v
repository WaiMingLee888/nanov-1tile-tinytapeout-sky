`timescale 1ns/1ps

module register_spi_tb;
    reg clk = 0;
    reg rstn = 0;
    reg start = 0;
    reg write = 0;
    reg [3:0] reg_index = 0;
    reg [31:0] write_word = 0;
    wire [31:0] read_word;
    wire read_bit;
    wire read_bit_valid;
    wire busy;
    wire done;
    wire spi_select;
    wire spi_out;
    wire spi_clk_enable;
    wire spi_miso;
    wire [31:0] debug_data;
    reg [23:0] debug_addr = 0;
    reg buffered_spi_in;

    wire spi_clk = !clk && spi_clk_enable;

    always #5 clk = ~clk;
    always @(negedge clk)
        buffered_spi_in <= spi_miso;

    nanoV_register_spi dut (
        clk, rstn, start, write, reg_index, write_word,
        read_word, read_bit, read_bit_valid, busy, done,
        buffered_spi_in, spi_select, spi_out, spi_clk_enable,
        1'b0, 24'b0, 2'd2
    );

    sim_spi_ram ram (
        spi_clk,
        spi_out,
        spi_select,
        spi_miso,
        clk,
        debug_addr,
        debug_data
    );
    defparam ram.INIT_FILE = "test/test.mem";
    defparam ram.INIT_WORDS = 97;

    task transact_write;
        input [3:0] index;
        input [31:0] value;
        begin
            @(posedge clk);
            reg_index <= index;
            write_word <= value;
            write <= 1;
            start <= 1;
            @(posedge clk);
            start <= 0;
            while (!done) @(posedge clk);
            if (busy) $fatal(1, "write completed while busy remained high");
            // The compact simulation RAM models 64 KiB and intentionally
            // aliases the high address bits used by the real 24-bit device.
            debug_addr = ((24'hffffc0 + {18'b0, index, 2'b00}) >> 2) & 24'h003fff;
            @(posedge clk);
            #1;
            if (debug_data !== value) begin
                $display("RAM cmd=%h addr=%h reading=%b writing=%b error=%b start_count=%0d",
                         ram.cmd, ram.addr, ram.reading, ram.writing, ram.error, ram.start_count);
                $display("RAM direct[%0d]=%h neighbor=%h", debug_addr, ram.data[debug_addr], ram.data[debug_addr-1]);
                $fatal(1, "x%0d SPI write mismatch: memory has %h expected %h", index, debug_data, value);
            end
        end
    endtask

    task transact_read;
        input [3:0] index;
        input [31:0] expected;
        begin
            @(posedge clk);
            reg_index <= index;
            write <= 0;
            start <= 1;
            @(posedge clk);
            start <= 0;
            while (!done) @(posedge clk);
            #1;
            if (read_word !== expected) begin
                $display("READ cmd=%h addr=%h reading=%b error=%b shift=%h buffered=%b miso=%b",
                         ram.cmd, ram.addr, ram.reading, ram.error, dut.read_shift,
                         buffered_spi_in, spi_miso);
                $fatal(1, "x%0d read mismatch: got %h expected %h", index, read_word, expected);
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rstn <= 1;

        transact_write(4'd5, 32'hdeadbeef);
        transact_read(4'd5, 32'hdeadbeef);
        transact_write(4'd15, 32'h01234567);
        transact_read(4'd15, 32'h01234567);
        transact_read(4'd5, 32'hdeadbeef);

        $display("external register SPI transactions passed");
        $finish;
    end
endmodule
