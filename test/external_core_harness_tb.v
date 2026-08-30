`timescale 1ns/1ps

module external_core_harness_tb;
    reg clk = 0;
    reg rstn = 0;
    reg start = 0;
    reg [31:0] instruction = 32'h00000013;
    wire busy;
    wire done;
    wire spi_select;
    wire spi_out;
    wire spi_clk_enable;
    wire spi_miso;
    reg buffered_spi_in;
    reg [23:0] debug_addr = 0;
    wire [31:0] debug_data;

    wire spi_clk = !clk && spi_clk_enable;
    always #5 clk = ~clk;
    always @(negedge clk)
        buffered_spi_in <= spi_miso;

    nanoV_external_core_harness dut (
        clk, rstn, start, instruction, busy, done,
        buffered_spi_in, spi_select, spi_out, spi_clk_enable
    );

    sim_spi_ram ram (
        spi_clk, spi_out, spi_select, spi_miso,
        clk, debug_addr, debug_data
    );
    defparam ram.INIT_FILE = "test/test.mem";
    defparam ram.INIT_WORDS = 97;

    task execute_instruction;
        input [31:0] encoded;
        begin
            @(negedge clk);
            instruction = encoded;
            start = 1;
            @(negedge clk);
            start = 0;
            while (!done) @(posedge clk);
            if (busy) $fatal(1, "instruction completed while busy remained high");
        end
    endtask

    task check_register;
        input [3:0] index;
        input [31:0] expected;
        begin
            debug_addr = (((24'hffffc0 + {18'b0, index, 2'b00}) >> 2) & 24'h003fff);
            repeat (2) @(posedge clk);
            #1;
            if (debug_data !== expected) begin
                $display("core rs1=%0d rs2=%0d rd=%0d write_word=%h regstate=%0d cmd=%h error=%b",
                         dut.rs1, dut.rs2, dut.rd, dut.registers.write_word,
                         dut.registers.state, ram.cmd, ram.error);
                $fatal(1, "x%0d mismatch: got %h expected %h", index, debug_data, expected);
            end
        end
    endtask

    initial begin
        repeat (3) @(posedge clk);
        rstn <= 1;

        // addi x5, x0, 0x123
        execute_instruction(32'h12300293);
        check_register(4'd5, 32'h00000123);

        // add x6, x5, x5
        execute_instruction(32'h00528333);
        check_register(4'd6, 32'h00000246);

        // sub x7, x6, x5
        execute_instruction(32'h405303b3);
        check_register(4'd7, 32'h00000123);

        $display("external-register NanoV core execution passed");
        $finish;
    end
endmodule
