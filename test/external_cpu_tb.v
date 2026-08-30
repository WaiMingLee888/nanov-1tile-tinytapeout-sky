`timescale 1ns/1ps

module external_cpu_tb;
    reg clk = 0;
    reg rstn = 0;
    wire spi_select;
    wire spi_out;
    wire spi_clk_enable;
    wire spi_miso;
    reg buffered_spi_in;
    wire [21:0] debug_pc = dut.pc;
    wire [31:0] debug_instruction = dut.instruction;
    wire retire;
    wire [7:0] gpio_out;
    reg [15:0] retired_instructions = 0;
    reg [23:0] debug_addr = 0;
    wire [31:0] debug_data;
    integer timeout;

    wire spi_clk = !clk && spi_clk_enable;
    always #5 clk = ~clk;
    always @(negedge clk)
        buffered_spi_in <= spi_miso;

    nanoV_cpu_external dut (
        clk, rstn, buffered_spi_in,
        spi_select, spi_out, spi_clk_enable, retire, 8'ha5, gpio_out
    );

    always @(posedge clk)
        if (!rstn)
            retired_instructions <= 0;
        else if (retire)
            retired_instructions <= retired_instructions + 1'b1;

    sim_spi_ram ram (
        spi_clk, spi_out, spi_select, spi_miso,
        clk, debug_addr, debug_data
    );
    defparam ram.INIT_FILE = "test/external_cpu.mem";
    defparam ram.INIT_WORDS = 36;

    task check_register;
        input [3:0] index;
        input [31:0] expected;
        begin
            debug_addr = (((24'hffffc0 + {18'b0, index, 2'b00}) >> 2) & 24'h003fff);
            repeat (2) @(posedge clk);
            #1;
            if (debug_data !== expected)
                $fatal(1, "x%0d mismatch: got %h expected %h", index, debug_data, expected);
        end
    endtask

    task check_memory;
        input [23:0] byte_address;
        input [31:0] expected;
        begin
            debug_addr = (byte_address >> 2) & 24'h003fff;
            repeat (2) @(posedge clk);
            #1;
            if (debug_data !== expected) begin
                $display("nearby memory: %h %h %h %h",
                         ram.data[14'h0400], ram.data[14'h0401],
                         ram.data[14'h0402], ram.data[14'h0403]);
                $fatal(1, "memory[%h] mismatch: got %h expected %h",
                       byte_address, debug_data, expected);
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rstn <= 1;

        timeout = 0;
        while (retired_instructions < 18 && timeout < 18000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (retired_instructions < 18)
            $fatal(1, "external CPU timed out at pc=%h instr=%h", debug_pc, debug_instruction);

        check_register(4'd5, 32'h00000123);
        check_register(4'd6, 32'h00000246);
        check_register(4'd7, 32'h00000123);
        // Taken BEQ skipped x8=0x111; not-taken BNE allowed x9=0x333.
        check_register(4'd8, 32'h00000222);
        check_register(4'd9, 32'h00000333);
        // JAL at 0x20 skips 0x24 and links 0x24 in x10.
        check_register(4'd10, 32'h00000024);
        check_register(4'd11, 32'h00000444);
        // JALR at 0x30 targets 0x38 and links 0x34 in x13.
        check_register(4'd13, 32'h00000034);
        check_register(4'd14, 32'h00000666);
        // Two-cycle SLLI/SRLI/SRAI exercise ring orientation across cycles.
        check_register(4'd15, 32'h00000010);
        check_register(4'd1, 32'h00000008);
        check_register(4'd2, 32'h00000004);
        // A conventional little-endian word store/load through shared SPI.
        check_memory(24'h001000, 32'h00000123);
        check_register(4'd5, 32'h00000123);

        while (retired_instructions < 27 && timeout < 28000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (retired_instructions < 27)
            $fatal(1, "byte/halfword test timed out at pc=%h instr=%h",
                   debug_pc, debug_instruction);

        // Signed and unsigned byte/halfword loads after short SPI writes.
        check_memory(24'h001004, 32'h000000ff);
        check_memory(24'h001008, 32'h0000ffff);
        check_register(4'd6, 32'hffffffff);
        check_register(4'd7, 32'hffffffff);
        check_register(4'd8, 32'h000000ff);
        check_register(4'd9, 32'hffffffff);
        check_register(4'd10, 32'h0000ffff);

        while (retired_instructions < 30 && timeout < 32000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (retired_instructions < 30)
            $fatal(1, "SLT test timed out at pc=%h instr=%h",
                   debug_pc, debug_instruction);
        check_register(4'd11, 32'h00000001);
        check_register(4'd12, 32'h00000000);
        check_register(4'd13, 32'h00000001);

        while (retired_instructions < 32 && timeout < 35000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (retired_instructions < 32)
            $fatal(1, "GPIO test timed out at pc=%h instr=%h",
                   debug_pc, debug_instruction);
        if (gpio_out !== 8'hff)
            $fatal(1, "GPIO output mismatch: got %h expected ff (pc=%h addr=%h)",
                   gpio_out, debug_pc, dut.fast_addr_imm);
        check_register(4'd14, 32'h000000a5);

        $display("external-register NanoV instruction fetch and execution passed");
        $finish;
    end
endmodule
