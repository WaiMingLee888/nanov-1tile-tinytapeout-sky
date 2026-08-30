/*
 * External RV32E register subsystem for the one-tile NanoV derivative.
 *
 * A load operation reads rs1 and rs2 from reserved SPI-RAM slots, captures
 * their serial bits directly into the two operand rings, and normalizes their
 * byte bit order. A commit operation writes the completed destination ring.
 * The CPU asserts execute only for actual 32-clock core cycles, keeping all
 * ring orientation fixed during SPI transactions and controller overhead.
 */

module nanoV_external_register_subsystem (
    input clk,
    input rstn,

    input load_start,
    input commit_start,
    input execute,
    output reg load_done,
    output reg commit_done,
    output transaction_busy,

    input [3:0] next_rs1,
    input [3:0] next_rs2,
    input [3:0] rs1,
    input [3:0] rs2,
    input [3:0] rd,
    input [4:0] counter,
    input wr_en,
    input wr_next_en,
    input read_through,
    output data_rs1,
    output data_rs2,
    input data_rd,
    input data_rd_next,

    input spi_data_in,
    output spi_select,
    output spi_out,
    output spi_clk_enable
);

    localparam STATE_IDLE = 3'd0;
    localparam STATE_RS1_START = 3'd1;
    localparam STATE_RS1_WAIT = 3'd2;
    localparam STATE_RS2_START = 3'd3;
    localparam STATE_RS2_WAIT = 3'd4;
    localparam STATE_NORMALIZE = 3'd5;
    localparam STATE_WRITE_START = 3'd6;
    localparam STATE_WRITE_WAIT = 3'd7;

    reg [2:0] state;
    reg [3:0] rs1_latched;
    reg [3:0] rs2_latched;
    reg [3:0] rd_latched;

    wire engine_start = state == STATE_RS1_START ||
                        state == STATE_RS2_START ||
                        state == STATE_WRITE_START;
    wire engine_write = state == STATE_WRITE_START || state == STATE_WRITE_WAIT;
    wire [3:0] engine_reg_index =
        (state == STATE_RS1_START || state == STATE_RS1_WAIT) ? rs1_latched :
        (state == STATE_RS2_START || state == STATE_RS2_WAIT) ? rs2_latched :
        rd_latched;

    wire [31:0] write_word;
    wire write_required;
    wire [31:0] unused_read_word;
    wire engine_read_bit;
    wire engine_read_valid;
    wire engine_busy;
    wire engine_done;

    nanoV_register_spi spi_engine (
        .clk(clk),
        .rstn(rstn),
        .start(engine_start),
        .write(engine_write),
        .reg_index(engine_reg_index),
        .write_word(write_word),
        .read_word(unused_read_word),
        .read_bit(engine_read_bit),
        .read_bit_valid(engine_read_valid),
        .busy(engine_busy),
        .done(engine_done),
        .spi_data_in(spi_data_in),
        .spi_select(spi_select),
        .spi_out(spi_out),
        .spi_clk_enable(spi_clk_enable)
    );

    nanoV_external_registers staging (
        .clk(clk),
        .rstn(rstn),
        .load_sources(1'b0),
        .rs1_word(32'b0),
        .rs2_word(32'b0),
        .capture_rs1(engine_read_valid && state == STATE_RS1_WAIT),
        .capture_rs2(engine_read_valid && state == STATE_RS2_WAIT),
        .normalize_sources(state == STATE_NORMALIZE),
        .serial_bit(engine_read_bit),
        .rotate(execute),
        .wr_en(wr_en),
        .wr_next_en(wr_next_en),
        .read_through(read_through),
        .counter(counter),
        .next_rs1(next_rs1),
        .next_rs2(next_rs2),
        .rs1(rs1_latched),
        .rs2(rs2_latched),
        .rd(rd_latched),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2),
        .data_rd(data_rd),
        .data_rd_next(data_rd_next),
        .write_word(write_word),
        .write_required(write_required)
    );

    assign transaction_busy = state != STATE_IDLE || engine_busy;

    always @(posedge clk) begin
        if (!rstn) begin
            state <= STATE_IDLE;
            rs1_latched <= 0;
            rs2_latched <= 0;
            rd_latched <= 0;
            load_done <= 0;
            commit_done <= 0;
        end else begin
            load_done <= 0;
            commit_done <= 0;

            case (state)
                STATE_IDLE: begin
                    if (load_start) begin
                        rs1_latched <= rs1;
                        rs2_latched <= rs2;
                        rd_latched <= rd;
                        state <= STATE_RS1_START;
                    end else if (commit_start) begin
                        if (write_required)
                            state <= STATE_WRITE_START;
                        else
                            commit_done <= 1;
                    end
                end
                STATE_RS1_START: state <= STATE_RS1_WAIT;
                STATE_RS1_WAIT: if (engine_done) state <= STATE_RS2_START;
                STATE_RS2_START: state <= STATE_RS2_WAIT;
                STATE_RS2_WAIT: if (engine_done) state <= STATE_NORMALIZE;
                STATE_NORMALIZE: begin
                    state <= STATE_IDLE;
                    load_done <= 1;
                end
                STATE_WRITE_START: state <= STATE_WRITE_WAIT;
                STATE_WRITE_WAIT: if (engine_done) begin
                    state <= STATE_IDLE;
                    commit_done <= 1;
                end
                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule
