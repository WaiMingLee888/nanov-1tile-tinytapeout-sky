/*
 * Tiny Tapeout wrapper for Michael Bell's nanoV RV32E core.
 *
 * Derived from https://github.com/MichaelBell/tt04-nanoV at
 * f6fcbbfe693fec80418b6dccc6447019cca8435e.
 * Updated for the current Tiny Tapeout SKY130 flow in 2026.
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_WaiMingLee888_nanov_1tile (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire spi_select;
    wire spi_mosi;
    wire spi_clk_enable;
    // Mode-0 SPI: the memory captures MOSI and presents MISO relative to the
    // same rising edge used by the controller.  Keeping SCK non-inverted also
    // avoids treating a package-output inverter as part of the internal clock
    // tree during physical design.
    assign uio_out = {
        spi_clk_enable,
        4'b0000,
        (clk && spi_clk_enable),
        spi_select,
        spi_mosi
    };

    // Switch SPI bidis to inputs when in reset (allows external programming of SPI RAM
    // while in reset).
    assign uio_oe = rst_n ? 8'b10000111 : 8'b00000000;

    wire unused_retire;
    nanoV_cpu_external nano (
        .clk(clk),
        .rstn(rst_n),
        .spi_data_in(uio_in[3]),
        .spi_select(spi_select),
        .spi_out(spi_mosi),
        .spi_clk_enable(spi_clk_enable),
        .retire(unused_retire),
        .gpio_in(ui_in),
        .gpio_out(uo_out)
    );

    wire unused = &{ena, 1'b0, unused_retire};

endmodule

`default_nettype wire
