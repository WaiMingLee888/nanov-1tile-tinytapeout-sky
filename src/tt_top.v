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

    reg spi_select, spi_mosi;
    wire spi_clk_enable;
    wire buffered_spi_clk_enable;
    assign uio_out = {
        spi_clk_enable,
        4'b0000,
        (!clk && buffered_spi_clk_enable),
        spi_select,
        spi_mosi
    };
    reg buffered_spi_in;

    // The TT04 implementation used a hand-instantiated Sky130 buffer here.
    // Generic RTL lets the current synthesis flow choose the appropriate cell.
    assign buffered_spi_clk_enable = spi_clk_enable;

    // Switch SPI bidis to inputs when in reset (allows external programming of SPI RAM
    // while in reset).
    assign uio_oe = rst_n ? 8'b10000111 : 8'b00000000;

    always @(negedge clk)
        buffered_spi_in <= uio_in[3];

    wire spi_data_nano, spi_select_nano;
    always @(posedge clk)
        if (!rst_n)
            spi_select <= 1;
        else
            spi_select <= spi_select_nano;

    always @(posedge clk)
        spi_mosi <= spi_data_nano;
    
    wire [31:0] data_in;
    wire [31:0] addr_out;
    wire [31:0] data_out;
    wire is_data, is_data_in;
    wire is_addr;
    reg [7:0] output_data;
    assign uo_out = output_data;

    nanoV_cpu #(.NUM_REGS(16)) nano(
        .clk(clk), 
        .rstn(rst_n),
        .spi_data_in(buffered_spi_in), 
        .spi_select(spi_select_nano), 
        .spi_out(spi_data_nano),
        .spi_clk_enable(spi_clk_enable),
        .ext_data_in(data_in),
        .addr_out(addr_out),
        .data_out(data_out),
        .store_data_out(is_data),
        .store_addr_out(is_addr),
        .data_in_read(is_data_in));

    localparam PERI_NONE = 0;
    localparam PERI_GPIO_OUT = 1;
    localparam PERI_GPIO_IN = 2;

    reg [1:0] connect_peripheral;
    
    always @(posedge clk) begin
        if (!rst_n) begin 
            connect_peripheral <= PERI_NONE;
        end
        else if (is_addr) begin
            if (addr_out == 32'h10000000) connect_peripheral <= PERI_GPIO_OUT;
            else if (addr_out == 32'h10000004) connect_peripheral <= PERI_GPIO_IN;
            else connect_peripheral <= PERI_NONE;
        end

        if (!rst_n)
            output_data <= 8'h00;
        else if (is_data && connect_peripheral == PERI_GPIO_OUT)
            output_data <= data_out[7:0];
    end

    assign data_in[31:8] = 0;
    assign data_in[7:0] = connect_peripheral == PERI_GPIO_OUT ? output_data :
                          connect_peripheral == PERI_GPIO_IN ? ui_in : 8'h00;

endmodule

`default_nettype wire
