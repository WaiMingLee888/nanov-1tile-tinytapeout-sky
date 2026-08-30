/*
 * External-memory register staging for the one-tile NanoV derivative.
 *
 * Architectural registers x1, x2, x5-x15 live as conventional 32-bit words
 * in the existing SPI RAM. x0 remains zero and the ABI-reserved x3/x4 retain
 * NanoV's hardwired values. The CPU controller loads the two source words
 * before execution and writes write_word back after an instruction that has
 * a destination register.
 *
 * The three local words are rotating rings so this block presents the same
 * one-bit-per-clock interface as nanoV_registers without a variable bit-index
 * decoder. A later integration step connects load_sources/write_word to the
 * shared SPI transaction sequencer.
 */

module nanoV_external_registers (
    input clk,
    input rstn,

    input load_sources,
    input [31:0] rs1_word,
    input [31:0] rs2_word,

    input wr_en,
    input wr_next_en,
    input read_through,
    input [4:0] counter,

    input [3:0] next_rs1,
    input [3:0] next_rs2,
    input [3:0] rs1,
    input [3:0] rs2,
    input [3:0] rd,

    output data_rs1,
    output data_rs2,
    input data_rd,
    input data_rd_next,

    output [31:0] write_word,
    output write_required
);

    reg [31:0] rs1_ring;
    reg [31:0] rs2_ring;
    reg [31:0] write_ring;

    reg last_data_rd_next;
    reg read_through_rs1;
    reg read_through_rs2;

    wire rd_writable = rd != 0 && rd != 3 && rd != 4;
    wire may_read_through = read_through && rd_writable;

    always @(posedge clk) begin
        if (load_sources) begin
            // Place logical bit zero at ring position one, matching the
            // original NanoV register-file interface.
            rs1_ring <= {rs1_word[30:0], rs1_word[31]};
            rs2_ring <= {rs2_word[30:0], rs2_word[31]};
        end else begin
            rs1_ring <= {rs1_ring[0], rs1_ring[31:1]};
            rs2_ring <= {rs2_ring[0], rs2_ring[31:1]};
        end

        if (wr_en && rd_writable)
            write_ring[0] <= data_rd;
        else
            write_ring[0] <= write_ring[1];

        if (wr_next_en && rd_writable)
            write_ring[1] <= data_rd_next;
        else
            write_ring[1] <= write_ring[2];

        write_ring[31:2] <= {write_ring[0], write_ring[31:3]};

        last_data_rd_next <= data_rd_next;
        read_through_rs1 <= may_read_through && next_rs1 == rd;
        read_through_rs2 <= may_read_through && next_rs2 == rd;
    end

    // Source and write rings are initialized by SPI reads or complete
    // writeback cycles before use; resetting 96 data bits would add larger
    // resettable cells without changing architectural reset behavior.
    wire unused_rstn = rstn;

    wire source_rs1 = (rs1 == 0) ? 1'b0 :
                      (rs1 == 3) ? (counter == 12) :
                      (rs1 == 4) ? (counter == 28) : rs1_ring[1];
    wire source_rs2 = (rs2 == 0) ? 1'b0 :
                      (rs2 == 3) ? (counter == 12) :
                      (rs2 == 4) ? (counter == 28) : rs2_ring[1];

    assign data_rs1 = read_through_rs1 ? last_data_rd_next : source_rs1;
    assign data_rs2 = read_through_rs2 ? last_data_rd_next : source_rs2;

    // Convert the physical ring orientation back to a normal 32-bit word.
    assign write_word = {write_ring[0], write_ring[31:1]};
    assign write_required = rd_writable;
    wire unused_rstn_sink = unused_rstn;

endmodule
