/*
 * Compact 32-bit SPI transaction engine for external NanoV registers.
 *
 * Registers occupy the final 64 bytes of the 24-bit SPI address space:
 *   xN -> 0xffffc0 + 4*N
 *
 * The engine emits standard SPI commands 03h (read) and 02h (write), with
 * command/address and data both transferred most-significant bit first within
 * each byte. Program/data images elsewhere in memory remain ordinary little
 * endian bytes.
 */

module nanoV_register_spi (
    input clk,
    input rstn,

    input start,
    input write,
    input [3:0] reg_index,
    // Hold write_word stable until done when starting a write transaction.
    input [31:0] write_word,
    output [31:0] read_word,
    output read_bit,
    output read_bit_valid,
    output reg busy,
    output reg done,

    input spi_data_in,
    output reg spi_select,
    output spi_out,
    output spi_clk_enable
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_COMMAND = 2'd1;
    localparam STATE_DATA = 2'd2;

    reg [1:0] state;
    reg [4:0] bit_count;
    reg write_latched;
    reg [3:0] reg_index_latched;
    reg [31:0] read_shift;

    wire [23:0] register_address = 24'hffffc0 + {18'b0, reg_index_latched, 2'b00};
    wire [31:0] command_word = {
        write_latched ? 8'h02 : 8'h03,
        register_address
    };
    wire [4:0] write_bit_index = {bit_count[4:3], ~bit_count[2:0]};

    assign spi_out = (state == STATE_COMMAND) ? command_word[31-bit_count] :
                     (state == STATE_DATA && write_latched) ? write_word[write_bit_index] :
                     1'b0;
    assign read_bit = spi_data_in;
    assign read_bit_valid = state == STATE_DATA && !write_latched;
    // Keep SCK running while CS is high. This is harmless for a real SPI RAM
    // and gives the NanoV simulation model a deselected edge between adjacent
    // transactions, matching the behavior of the existing CPU controller.
    assign spi_clk_enable = 1'b1;

    wire [31:0] decoded_read_shift = {
        read_shift[24], read_shift[25], read_shift[26], read_shift[27],
        read_shift[28], read_shift[29], read_shift[30], read_shift[31],
        read_shift[16], read_shift[17], read_shift[18], read_shift[19],
        read_shift[20], read_shift[21], read_shift[22], read_shift[23],
        read_shift[8],  read_shift[9],  read_shift[10], read_shift[11],
        read_shift[12], read_shift[13], read_shift[14], read_shift[15],
        read_shift[0],  read_shift[1],  read_shift[2],  read_shift[3],
        read_shift[4],  read_shift[5],  read_shift[6],  read_shift[7]
    };
    assign read_word = decoded_read_shift;

    always @(posedge clk) begin
        if (!rstn) begin
            state <= STATE_IDLE;
            bit_count <= 0;
            write_latched <= 0;
            reg_index_latched <= 0;
            read_shift <= 0;
            busy <= 0;
            done <= 0;
            spi_select <= 1;
        end else begin
            done <= 0;

            if (state == STATE_IDLE) begin
                if (start) begin
                    state <= STATE_COMMAND;
                    bit_count <= 0;
                    write_latched <= write;
                    reg_index_latched <= reg_index;
                    read_shift <= 0;
                    busy <= 1;
                    spi_select <= 0;
                end
            end else if (state == STATE_COMMAND) begin
                if (bit_count == 31) begin
                    state <= STATE_DATA;
                    bit_count <= 0;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end else begin
                if (!write_latched)
                    read_shift <= {spi_data_in, read_shift[31:1]};

                if (bit_count == 31) begin
                    state <= STATE_IDLE;
                    bit_count <= 0;
                    busy <= 0;
                    done <= 1;
                    spi_select <= 1;
                end else begin
                    bit_count <= bit_count + 1'b1;
                end
            end
        end
    end

endmodule
