/*
 * Sequential external-register NanoV CPU controller.
 *
 * This controller uses one shared SPI engine for instruction fetch and the
 * private x1/x2/x5-x15 register slots. It preserves the original NanoV
 * core's serial ALU while sequencing instruction fetch, branches/jumps, and
 * explicit word load/store transactions through the same SPI engine.
 */

module nanoV_cpu_external (
    input clk,
    input rstn,

    input spi_data_in,
    output spi_select,
    output spi_out,
    output spi_clk_enable,
    output retire,
    input [7:0] gpio_in,
    output reg [7:0] gpio_out
);

    localparam STATE_FETCH_START = 4'd0;
    localparam STATE_FETCH_WAIT = 4'd1;
    localparam STATE_RS1_START = 4'd2;
    localparam STATE_RS1_WAIT = 4'd3;
    localparam STATE_RS2_START = 4'd4;
    localparam STATE_RS2_WAIT = 4'd5;
    localparam STATE_NORMALIZE = 4'd6;
    localparam STATE_EXECUTE = 4'd7;
    localparam STATE_WRITE_START = 4'd8;
    localparam STATE_WRITE_WAIT = 4'd9;
    localparam STATE_DATA_START = 4'd10;
    localparam STATE_DATA_WAIT = 4'd11;
    localparam STATE_LOAD_CAPTURE = 4'd12;
    localparam STATE_FETCH_CAPTURE = 4'd13;

    reg [3:0] state;
    reg [21:0] pc;
    reg [31:0] instruction;
    reg [4:0] counter;
    reg [2:0] cycle;
    reg branch_taken;

    function [2:0] cycles_for_instr(input [31:2] decoded_instr);
        if (decoded_instr[6:2] == 5'b11000) cycles_for_instr = 4;
        else if (decoded_instr[6:5] == 2'b11) cycles_for_instr = 3;
        else if (decoded_instr[6] == 0 && decoded_instr[4:2] == 0 && decoded_instr[19:15] != 5'b00100) cycles_for_instr = 5;
        else if (decoded_instr[6] == 0 && decoded_instr[4] == 1 && decoded_instr[2] == 0 && decoded_instr[13:12] == 2'b01) cycles_for_instr = 2;
        else cycles_for_instr = 1;
    endfunction

    wire is_mmio;
    wire execute = state == STATE_EXECUTE;
    wire engine_start = state == STATE_FETCH_START ||
                        state == STATE_RS1_START ||
                        state == STATE_RS2_START ||
                        state == STATE_WRITE_START ||
                        (state == STATE_DATA_START && !is_mmio);
    wire data_transaction = state == STATE_DATA_START || state == STATE_DATA_WAIT;
    wire is_mem = instruction[6] == 0 && instruction[4:2] == 0;
    wire is_store = is_mem && instruction[5];
    wire is_branch = instruction[6:2] == 5'b11000;
    wire is_jump = instruction[6:4] == 3'b110 && instruction[2];
    wire instruction_writes_rd = !is_branch && !is_store &&
                                 instruction[6:2] != 5'b00011 &&
                                 instruction[6:2] != 5'b11100;
    wire engine_write = state == STATE_WRITE_START || state == STATE_WRITE_WAIT ||
                        (data_transaction && is_store);
    wire fetch_transaction = state == STATE_FETCH_START || state == STATE_FETCH_WAIT;

    wire [31:0] unused_engine_read_word;
    wire engine_read_bit;
    wire engine_read_valid;
    wire engine_busy;
    wire engine_done;

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
    wire [31:0] rs1_value;
    wire [31:0] rs2_raw_value;
    wire [31:0] rs2_value;
    wire [31:0] core_data_out;
    wire core_rs2_out;
    wire core_branch;
    wire core_shift_pc;
    wire is_fast_mem = is_mem && instruction[19:15] == 5'b00100;
    wire [11:0] fast_addr_imm = {
        instruction[31:25],
        instruction[5] ? instruction[11:9] : instruction[24:22],
        2'b00
    };
    wire write_required = rd != 0 && rd != 3 && rd != 4;
    wire general_mmio = !is_fast_mem && core_data_out[31:28] == 4'h1;
    wire mmio_input_select = is_fast_mem ? fast_addr_imm[2] : core_data_out[2];
    assign is_mmio = is_fast_mem || general_mmio;
    wire [31:0] load_value = instruction[14:12] == 3'b000 ?
                             {{24{rs1_value[7]}}, rs1_value[7:0]} :
                             instruction[14:12] == 3'b001 ?
                             {{16{rs1_value[15]}}, rs1_value[15:0]} :
                             instruction[14:12] == 3'b100 ?
                             {24'b0, rs1_value[7:0]} :
                             instruction[14:12] == 3'b101 ?
                             {16'b0, rs1_value[15:0]} : rs1_value;
    wire [31:0] decoded_instruction = {
        instruction[24], instruction[25], instruction[26], instruction[27],
        instruction[28], instruction[29], instruction[30], instruction[31],
        instruction[16], instruction[17], instruction[18], instruction[19],
        instruction[20], instruction[21], instruction[22], instruction[23],
        instruction[8],  instruction[9],  instruction[10], instruction[11],
        instruction[12], instruction[13], instruction[14], instruction[15],
        instruction[0],  instruction[1],  instruction[2],  instruction[3],
        instruction[4],  instruction[5],  instruction[6],  instruction[7]
    };

    wire [3:0] engine_reg_index =
        (state == STATE_RS1_START || state == STATE_RS1_WAIT) ? rs1 :
        (state == STATE_RS2_START || state == STATE_RS2_WAIT) ? rs2 : rd;

    nanoV_register_spi spi_engine (
        .clk(clk),
        .rstn(rstn),
        .start(engine_start),
        .write(engine_write),
        .reg_index(engine_reg_index),
        .write_word(is_jump ? rs2_raw_value :
                    data_transaction && is_store ? rs2_value :
                    is_mem ? load_value : rs1_value),
        .read_word(unused_engine_read_word),
        .read_bit(engine_read_bit),
        .read_bit_valid(engine_read_valid),
        .busy(engine_busy),
        .done(engine_done),
        .spi_data_in(spi_data_in),
        .spi_select(spi_select),
        .spi_out(spi_out),
        .spi_clk_enable(spi_clk_enable),
        .direct_address_enable(fetch_transaction || data_transaction),
        .direct_address(fetch_transaction ? {2'b00, pc} : core_data_out[23:0]),
        .transfer_size(data_transaction && is_store ? instruction[13:12] : 2'd2)
    );

    nanoV_external_sources staging (
        .clk(clk),
        .capture_rs1(engine_read_valid && state == STATE_RS1_WAIT),
        .capture_rs2(engine_read_valid && state == STATE_RS2_WAIT),
        .normalize_sources(state == STATE_NORMALIZE),
        .serial_bit(engine_read_bit),
        .rotate(execute),
        .capture_result(execute && instruction_writes_rd && !is_jump && !is_mem &&
                        cycle + 1'b1 >= cycles_for_instr(instruction[31:2])),
        .result_bit(data_rd),
        .capture_result_next(wr_next_en),
        .result_next_bit(data_rd_next),
        .capture_load(engine_read_valid && state == STATE_DATA_WAIT && !is_store),
        .normalize_result(state == STATE_LOAD_CAPTURE),
        .load_rs1_word(state == STATE_DATA_START && is_mmio && !is_store),
        .rs1_load_word(mmio_input_select ? {24'b0, gpio_in} : 32'b0),
        .load_rs2_word(state == STATE_NORMALIZE && is_jump),
        .rs2_load_word({10'b0, pc} + 32'd4),
        .counter(counter),
        .rs1(rs1),
        .rs2(rs2),
        .data_rs1(data_rs1),
        .data_rs2(data_rs2),
        .rs1_value(rs1_value),
        .rs2_raw_value(rs2_raw_value),
        .rs2_value(rs2_value)
    );

    wire core_shift_data_out = (is_branch && cycle[1]) ||
                               (is_jump && cycle != 0);

    nanoV_core #(
        .NUM_REGS(16),
        .REG_ADDR_BITS(4),
        .EXTERNAL_REGISTERS(1)
    ) core (
        .clk(clk),
        .rstn(rstn),
        .execute_enable(execute),
        .next_instr(instruction[30:2]),
        .instr(instruction[31:2]),
        .cycle(cycle),
        .counter(counter),
        .pc(pc[0]),
        .data_in(1'b0),
        .ext_data_in(1'b0),
        .use_ext_data_in(1'b0),
        .shift_data_out(core_shift_data_out),
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

    wire final_execute_bit = state == STATE_EXECUTE && counter == 31 &&
                             cycle + 1'b1 >= cycles_for_instr(instruction[31:2]);
    wire commit_after_execute = instruction_writes_rd && write_required;
    wire branch_taken_at_completion = branch_taken || core_branch;
    wire [21:0] completed_pc = (is_branch && branch_taken_at_completion) ?
                               {core_data_out[20:0], 1'b0} :
                               is_jump ? {pc[20:0], core_data_out[31]} : pc + 4;
    assign retire = (state == STATE_WRITE_WAIT && engine_done) ||
                    (state == STATE_DATA_WAIT && engine_done && is_store) ||
                    (state == STATE_DATA_START && is_mmio && is_store) ||
                    (final_execute_bit && !commit_after_execute && !is_mem);

    always @(posedge clk) begin
        if (!rstn) begin
            state <= STATE_FETCH_START;
            pc <= 0;
            instruction <= 32'h00000013;
            counter <= 0;
            cycle <= 0;
            branch_taken <= 0;
            gpio_out <= 0;
        end else begin
            // Feed the serial PC bits expected by NanoV's branch/jump target
            // adder. A complete 22-bit rotation restores the fetch PC before
            // the instruction retires.
            if (execute && core_shift_pc)
                pc <= {pc[0], pc[21:1]};
            else if (execute && is_jump && cycle == 2 && counter > 9)
                pc <= {pc[20:0], core_data_out[31]};

            case (state)
                STATE_FETCH_START: state <= STATE_FETCH_WAIT;
                STATE_FETCH_WAIT: begin
                    if (engine_read_valid)
                        instruction <= {engine_read_bit, instruction[31:1]};
                    if (engine_done)
                        state <= STATE_FETCH_CAPTURE;
                end
                STATE_FETCH_CAPTURE: begin
                    instruction <= decoded_instruction;
                    state <= STATE_RS1_START;
                end
                STATE_RS1_START: state <= STATE_RS1_WAIT;
                STATE_RS1_WAIT: if (engine_done) state <= STATE_RS2_START;
                STATE_RS2_START: state <= STATE_RS2_WAIT;
                STATE_RS2_WAIT: if (engine_done) state <= STATE_NORMALIZE;
                STATE_NORMALIZE: begin
                    counter <= 0;
                    cycle <= 0;
                    branch_taken <= 0;
                    state <= STATE_EXECUTE;
                end
                STATE_EXECUTE: begin
                    if (core_branch)
                        branch_taken <= 1;

                    if (counter == 31) begin
                        counter <= 0;
                        if (is_mem && cycle == 0) begin
                            cycle <= 0;
                            state <= STATE_DATA_START;
                        end else if (cycle + 1'b1 < cycles_for_instr(instruction[31:2])) begin
                            cycle <= cycle + 1'b1;
                        end else begin
                            cycle <= 0;
                            pc <= completed_pc;
                            if (commit_after_execute)
                                state <= STATE_WRITE_START;
                            else begin
                                state <= STATE_FETCH_START;
                            end
                        end
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
                STATE_WRITE_START: state <= STATE_WRITE_WAIT;
                STATE_WRITE_WAIT: if (engine_done) begin
                    state <= STATE_FETCH_START;
                end
                STATE_DATA_START: begin
                    if (is_mmio) begin
                        pc <= pc + 4;
                        if (is_store) begin
                            gpio_out <= rs2_value[7:0];
                            state <= STATE_FETCH_START;
                        end else begin
                            state <= STATE_WRITE_START;
                        end
                    end else begin
                        state <= STATE_DATA_WAIT;
                    end
                end
                STATE_DATA_WAIT: if (engine_done) begin
                    if (is_store) begin
                        pc <= pc + 4;
                        state <= STATE_FETCH_START;
                    end else begin
                        pc <= pc + 4;
                        state <= STATE_LOAD_CAPTURE;
                    end
                end
                STATE_LOAD_CAPTURE: state <= STATE_WRITE_START;
                default: state <= STATE_FETCH_START;
            endcase
        end
    end

    wire unused_outputs = ^{engine_busy, unused_engine_read_word,
                            core_data_out, core_rs2_out,
                            core_branch, core_shift_pc};
    wire unused_sink = unused_outputs;

endmodule
