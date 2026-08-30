/*
 * Execution harness joining the original NanoV core to external SPI
 * registers. It currently sequences one-cycle RV32E ALU instructions and is
 * the integration precursor to the full instruction-fetch/load-store CPU FSM.
 */

module nanoV_external_core_harness (
    input clk,
    input rstn,
    input start,
    input [31:0] instruction,
    output reg busy,
    output reg done,

    input spi_data_in,
    output spi_select,
    output spi_out,
    output spi_clk_enable
);

    localparam STATE_IDLE = 3'd0;
    localparam STATE_LOAD_START = 3'd1;
    localparam STATE_LOAD_WAIT = 3'd2;
    localparam STATE_EXECUTE = 3'd3;
    localparam STATE_COMMIT_START = 3'd4;
    localparam STATE_COMMIT_WAIT = 3'd5;

    reg [2:0] state;
    reg [31:0] instruction_latched;
    reg [4:0] counter;

    wire execute = state == STATE_EXECUTE;
    wire load_start = state == STATE_LOAD_START;
    wire commit_start = state == STATE_COMMIT_START;
    wire load_done;
    wire commit_done;
    wire register_busy;

    wire data_rs1;
    wire data_rs2;
    wire wr_en;
    wire wr_next_en;
    wire read_through;
    wire [3:0] next_rs1;
    wire [3:0] next_rs2;
    wire [3:0] rs1;
    wire [3:0] rs2;
    wire [3:0] rd;
    wire data_rd;
    wire data_rd_next;
    wire [31:0] core_data_out;
    wire core_rs2_out;
    wire core_branch;
    wire core_shift_pc;

    nanoV_core #(
        .NUM_REGS(16),
        .REG_ADDR_BITS(4),
        .EXTERNAL_REGISTERS(1)
    ) core (
        .clk(clk),
        .rstn(rstn),
        .next_instr(instruction_latched[30:2]),
        .instr(instruction_latched[31:2]),
        .cycle(3'd0),
        .counter(counter),
        .pc(1'b0),
        .data_in(1'b0),
        .ext_data_in(1'b0),
        .use_ext_data_in(1'b0),
        .shift_data_out(1'b0),
        .shift_pc(core_shift_pc),
        .data_out(core_data_out),
        .rs2_out(core_rs2_out),
        .branch(core_branch),
        .ext_data_rs1(data_rs1),
        .ext_data_rs2(data_rs2),
        .ext_wr_en(wr_en),
        .ext_wr_next_en(wr_next_en),
        .ext_read_through(read_through),
        .ext_next_rs1(next_rs1),
        .ext_next_rs2(next_rs2),
        .ext_rs1(rs1),
        .ext_rs2(rs2),
        .ext_rd(rd),
        .ext_data_rd(data_rd),
        .ext_data_rd_next(data_rd_next)
    );

    nanoV_external_register_subsystem registers (
        .clk(clk),
        .rstn(rstn),
        .load_start(load_start),
        .commit_start(commit_start),
        .execute(execute),
        .load_done(load_done),
        .commit_done(commit_done),
        .transaction_busy(register_busy),
        .next_rs1(next_rs1),
        .next_rs2(next_rs2),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .counter(counter),
        .wr_en(wr_en),
        .wr_next_en(wr_next_en),
        .read_through(read_through),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2),
        .data_rd(data_rd),
        .data_rd_next(data_rd_next),
        .spi_data_in(spi_data_in),
        .spi_select(spi_select),
        .spi_out(spi_out),
        .spi_clk_enable(spi_clk_enable)
    );

    wire unused_core_outputs = ^{core_data_out, core_rs2_out, core_branch,
                                 core_shift_pc, register_busy};

    always @(posedge clk) begin
        if (!rstn) begin
            state <= STATE_IDLE;
            instruction_latched <= 32'h00000013;
            counter <= 0;
            busy <= 0;
            done <= 0;
        end else begin
            done <= 0;
            case (state)
                STATE_IDLE: if (start) begin
                    instruction_latched <= instruction;
                    counter <= 0;
                    busy <= 1;
                    state <= STATE_LOAD_START;
                end
                STATE_LOAD_START: state <= STATE_LOAD_WAIT;
                STATE_LOAD_WAIT: if (load_done) begin
                    counter <= 0;
                    state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    if (counter == 31) begin
                        counter <= 0;
                        state <= STATE_COMMIT_START;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
                STATE_COMMIT_START: state <= STATE_COMMIT_WAIT;
                STATE_COMMIT_WAIT: if (commit_done) begin
                    state <= STATE_IDLE;
                    busy <= 0;
                    done <= 1;
                end
                default: state <= STATE_IDLE;
            endcase
        end
    end

    wire unused_sink = unused_core_outputs;

endmodule
