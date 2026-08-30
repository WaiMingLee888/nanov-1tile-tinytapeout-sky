/* Two source rings for the external-register NanoV implementation. */
module nanoV_external_sources (
    input clk,
    input capture_rs1,
    input capture_rs2,
    input normalize_sources,
    input serial_bit,
    input rotate,
    input capture_result,
    input result_bit,
    input capture_result_next,
    input result_next_bit,
    input capture_load,
    input normalize_result,
    input load_rs1_word,
    input [31:0] rs1_load_word,
    input load_rs2_word,
    input [31:0] rs2_load_word,
    input [4:0] counter,
    input [3:0] rs1,
    input [3:0] rs2,
    output data_rs1,
    output data_rs2,
    output [31:0] rs1_value,
    output [31:0] rs2_raw_value,
    output [31:0] rs2_value
);
    reg [31:0] rs1_ring;
    reg [31:0] rs2_ring;

    wire [31:0] decoded_rs1_ring = {
        rs1_ring[24], rs1_ring[25], rs1_ring[26], rs1_ring[27],
        rs1_ring[28], rs1_ring[29], rs1_ring[30], rs1_ring[31],
        rs1_ring[16], rs1_ring[17], rs1_ring[18], rs1_ring[19],
        rs1_ring[20], rs1_ring[21], rs1_ring[22], rs1_ring[23],
        rs1_ring[8],  rs1_ring[9],  rs1_ring[10], rs1_ring[11],
        rs1_ring[12], rs1_ring[13], rs1_ring[14], rs1_ring[15],
        rs1_ring[0],  rs1_ring[1],  rs1_ring[2],  rs1_ring[3],
        rs1_ring[4],  rs1_ring[5],  rs1_ring[6],  rs1_ring[7]
    };
    wire [31:0] decoded_rs2_ring = {
        rs2_ring[24], rs2_ring[25], rs2_ring[26], rs2_ring[27],
        rs2_ring[28], rs2_ring[29], rs2_ring[30], rs2_ring[31],
        rs2_ring[16], rs2_ring[17], rs2_ring[18], rs2_ring[19],
        rs2_ring[20], rs2_ring[21], rs2_ring[22], rs2_ring[23],
        rs2_ring[8],  rs2_ring[9],  rs2_ring[10], rs2_ring[11],
        rs2_ring[12], rs2_ring[13], rs2_ring[14], rs2_ring[15],
        rs2_ring[0],  rs2_ring[1],  rs2_ring[2],  rs2_ring[3],
        rs2_ring[4],  rs2_ring[5],  rs2_ring[6],  rs2_ring[7]
    };

    always @(posedge clk) begin
        if (load_rs1_word)
            rs1_ring <= {rs1_load_word[30:0], rs1_load_word[31]};
        else if (normalize_result)
            rs1_ring <= {decoded_rs1_ring[30:0], decoded_rs1_ring[31]};
        else if (normalize_sources)
            rs1_ring <= {decoded_rs1_ring[30:0], decoded_rs1_ring[31]};
        else if (capture_load)
            rs1_ring <= {serial_bit, rs1_ring[31:1]};
        else if (capture_rs1)
            rs1_ring <= {serial_bit, rs1_ring[31:1]};
        else if (capture_result) begin
            rs1_ring[0] <= result_bit;
            rs1_ring[1] <= capture_result_next ? result_next_bit : rs1_ring[2];
            rs1_ring[31:2] <= {rs1_ring[0], rs1_ring[31:3]};
        end
        else if (rotate)
            rs1_ring <= {rs1_ring[0], rs1_ring[31:1]};

        if (load_rs2_word)
            rs2_ring <= {rs2_load_word[30:0], rs2_load_word[31]};
        else if (normalize_sources)
            rs2_ring <= {decoded_rs2_ring[30:0], decoded_rs2_ring[31]};
        else if (capture_rs2)
            rs2_ring <= {serial_bit, rs2_ring[31:1]};
        else if (rotate)
            rs2_ring <= {rs2_ring[0], rs2_ring[31:1]};
    end

    wire source_rs1 = (rs1 == 0) ? 1'b0 :
                      (rs1 == 3) ? (counter == 12) :
                      (rs1 == 4) ? (counter == 28) : rs1_ring[1];
    wire source_rs2 = (rs2 == 0) ? 1'b0 :
                      (rs2 == 3) ? (counter == 12) :
                      (rs2 == 4) ? (counter == 28) : rs2_ring[1];

    assign data_rs1 = source_rs1;
    assign data_rs2 = source_rs2;
    assign rs1_value = {rs1_ring[0], rs1_ring[31:1]};
    assign rs2_raw_value = {rs2_ring[0], rs2_ring[31:1]};
    assign rs2_value = (rs2 == 0) ? 32'b0 :
                       (rs2 == 3) ? 32'h00001000 :
                       (rs2 == 4) ? 32'h10000000 :
                       rs2_raw_value;
endmodule
