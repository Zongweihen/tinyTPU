`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 05:42:57 PM
// Design Name: 
// Module Name: MATRIX_MULTIPLY_UNIT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module MATRIX_MULTIPLY_UNIT #(
    parameter MATRIX_WIDTH = 14,
    parameter BYTE_WIDTH = 8,
    parameter EXTENDED_BYTE_WIDTH = BYTE_WIDTH
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] WEIGHT_DATA,
    input wire WEIGHT_SIGNED,
    input wire [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] SYSTOLIC_DATA,
    input wire SYSTOLIC_SIGNED,
    
    input wire ACTIVATE_WEIGHT,
    input wire LOAD_WEIGHT,
    input wire [BYTE_WIDTH-1:0] WEIGHT_ADDRESS,
    
    output reg [(MATRIX_WIDTH*16)-1:0] RESULT_DATA
);

    // Internal signals
    reg [EXTENDED_BYTE_WIDTH-1:0] EXTENDED_WEIGHT_DATA [0:MATRIX_WIDTH-1];
    reg [EXTENDED_BYTE_WIDTH-1:0] EXTENDED_SYSTOLIC_DATA [0:MATRIX_WIDTH-1];
    reg [MATRIX_WIDTH-1:0] LOAD_WEIGHT_MAP;
    reg [MATRIX_WIDTH-1:0] ACTIVATE_MAP;
    reg [MATRIX_WIDTH-1:0] ACTIVATE_CONTROL_cs, ACTIVATE_CONTROL_ns;
    reg [2 + MATRIX_WIDTH - 1:0] SIGN_CONTROL_cs, SIGN_CONTROL_ns;

    // ??????
    wire [2*EXTENDED_BYTE_WIDTH+MATRIX_WIDTH-1:0] INTERIM_RESULT [0:MATRIX_WIDTH-1][0:MATRIX_WIDTH-1];

    integer i, j;

    // ???????
    always @* begin
        ACTIVATE_CONTROL_ns = {ACTIVATE_CONTROL_cs[MATRIX_WIDTH-2:0], ACTIVATE_WEIGHT};
        SIGN_CONTROL_ns = {SIGN_CONTROL_cs[2 + MATRIX_WIDTH - 2:0], SYSTOLIC_SIGNED};
        ACTIVATE_MAP = {ACTIVATE_CONTROL_ns[0], ACTIVATE_CONTROL_cs};
    end

    // ??????
    always @* begin
        LOAD_WEIGHT_MAP = {MATRIX_WIDTH{1'b0}};
        if (LOAD_WEIGHT)
            LOAD_WEIGHT_MAP[WEIGHT_ADDRESS] = 1'b1;
    end

    // ????
    always @* begin
        for (i = 0; i < MATRIX_WIDTH; i = i + 1) begin
            EXTENDED_WEIGHT_DATA[i] = WEIGHT_SIGNED ? 
                                      {WEIGHT_DATA[i*BYTE_WIDTH + BYTE_WIDTH-1], WEIGHT_DATA[i*BYTE_WIDTH +: BYTE_WIDTH]} : 
                                      {1'b0, WEIGHT_DATA[i*BYTE_WIDTH +: BYTE_WIDTH]};
            EXTENDED_SYSTOLIC_DATA[i] = SIGN_CONTROL_ns[i] ? 
                                        {SYSTOLIC_DATA[i*BYTE_WIDTH + BYTE_WIDTH-1], SYSTOLIC_DATA[i*BYTE_WIDTH +: BYTE_WIDTH]} : 
                                        {1'b0, SYSTOLIC_DATA[i*BYTE_WIDTH +: BYTE_WIDTH]};
        end
    end

    // ?? MACC ??
    generate
        // ??? MACC_ROW
        for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_0
            MACC #(
                .LAST_SUM_WIDTH(0),
                .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH)
            ) MACC_inst_0 (
                .CLK(CLK),
                .RESET(RESET),
                .ENABLE(ENABLE),
                .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[0]),
                .LOAD_WEIGHT(ACTIVATE_MAP[0]),
                .INPUT(EXTENDED_SYSTOLIC_DATA[0]),
                .LAST_SUM({2 * EXTENDED_BYTE_WIDTH{1'b0}}),
                .PARTIAL_SUM(INTERIM_RESULT[0][j][2 * EXTENDED_BYTE_WIDTH-1:0])
            );
        end
    
        // Row 1
        for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_1
            MACC #(
                .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH),
                .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 1)
            ) MACC_inst_1 (
                .CLK(CLK),
                .RESET(RESET),
                .ENABLE(ENABLE),
                .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[1]),
                .LOAD_WEIGHT(ACTIVATE_MAP[1]),
                .INPUT(EXTENDED_SYSTOLIC_DATA[1]),
                .LAST_SUM(INTERIM_RESULT[0][j][2 * EXTENDED_BYTE_WIDTH-1:0]),
                .PARTIAL_SUM(INTERIM_RESULT[1][j][2 * EXTENDED_BYTE_WIDTH:0])
            );
        end
    
        // Row 2
        for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_2
            MACC #(
                .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 1),
                .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 2)
            ) MACC_inst_2 (
                .CLK(CLK),
                .RESET(RESET),
                .ENABLE(ENABLE),
                .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[2]),
                .LOAD_WEIGHT(ACTIVATE_MAP[2]),
                .INPUT(EXTENDED_SYSTOLIC_DATA[2]),
                .LAST_SUM(INTERIM_RESULT[1][j][2 * EXTENDED_BYTE_WIDTH:0]),
                .PARTIAL_SUM(INTERIM_RESULT[2][j][2 * EXTENDED_BYTE_WIDTH+1:0])
            );
        end
    
        // Row 3
        for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_3
            MACC #(
                .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 2),
                .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 3)
            ) MACC_inst_3 (
                .CLK(CLK),
                .RESET(RESET),
                .ENABLE(ENABLE),
                .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[3]),
                .LOAD_WEIGHT(ACTIVATE_MAP[3]),
                .INPUT(EXTENDED_SYSTOLIC_DATA[3]),
                .LAST_SUM(INTERIM_RESULT[2][j][2 * EXTENDED_BYTE_WIDTH+1:0]),
                .PARTIAL_SUM(INTERIM_RESULT[3][j][2 * EXTENDED_BYTE_WIDTH+2:0])
            );
        end
    
        // Row 4 - Row 13
        for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_4
            MACC #(
                .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 3),
                .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 4)
            ) MACC_inst_4 (
                .CLK(CLK),
                .RESET(RESET),
                .ENABLE(ENABLE),
                .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[4]),
                .LOAD_WEIGHT(ACTIVATE_MAP[4]),
                .INPUT(EXTENDED_SYSTOLIC_DATA[4]),
                .LAST_SUM(INTERIM_RESULT[3][j][2 * EXTENDED_BYTE_WIDTH+2:0]),
                .PARTIAL_SUM(INTERIM_RESULT[4][j][2 * EXTENDED_BYTE_WIDTH+3:0])
            );
        end
         // Row 5
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_5
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 4),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 5)
               ) MACC_inst_5 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[5]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[5]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[5]),
                   .LAST_SUM(INTERIM_RESULT[4][j][2 * EXTENDED_BYTE_WIDTH+3:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[5][j][2 * EXTENDED_BYTE_WIDTH+4:0])
               );
           end
       
           // Row 6
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_6
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 5),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 6)
               ) MACC_inst_6 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[6]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[6]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[6]),
                   .LAST_SUM(INTERIM_RESULT[5][j][2 * EXTENDED_BYTE_WIDTH+4:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[6][j][2 * EXTENDED_BYTE_WIDTH+5:0])
               );
           end
       
           // Row 7
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_7
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 6),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 7)
               ) MACC_inst_7 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[7]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[7]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[7]),
                   .LAST_SUM(INTERIM_RESULT[6][j][2 * EXTENDED_BYTE_WIDTH+5:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[7][j][2 * EXTENDED_BYTE_WIDTH+6:0])
               );
           end
       
           // Row 8
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_8
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 7),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 8)
               ) MACC_inst_8 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[8]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[8]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[8]),
                   .LAST_SUM(INTERIM_RESULT[7][j][2 * EXTENDED_BYTE_WIDTH+6:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[8][j][2 * EXTENDED_BYTE_WIDTH+7:0])
               );
           end
       
           // Row 9
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_9
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 8),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 9)
               ) MACC_inst_9 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[9]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[9]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[9]),
                   .LAST_SUM(INTERIM_RESULT[8][j][2 * EXTENDED_BYTE_WIDTH+7:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[9][j][2 * EXTENDED_BYTE_WIDTH+8:0])
               );
           end
       
           // Row 10
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_10
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 9),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 10)
               ) MACC_inst_10 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[10]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[10]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[10]),
                   .LAST_SUM(INTERIM_RESULT[9][j][2 * EXTENDED_BYTE_WIDTH+8:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[10][j][2 * EXTENDED_BYTE_WIDTH+9:0])
               );
           end
       
           // Row 11
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_11
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 10),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 11)
               ) MACC_inst_11 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[11]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[11]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[11]),
                   .LAST_SUM(INTERIM_RESULT[10][j][2 * EXTENDED_BYTE_WIDTH+9:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[11][j][2 * EXTENDED_BYTE_WIDTH+10:0])
               );
           end
       
           // Row 12
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_12
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 11),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 12)
               ) MACC_inst_12 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[12]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[12]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[12]),
                   .LAST_SUM(INTERIM_RESULT[11][j][2 * EXTENDED_BYTE_WIDTH+10:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[12][j][2 * EXTENDED_BYTE_WIDTH+11:0])
               );
           end
       
           // Row 13
           for (genvar j = 0; j < MATRIX_WIDTH; j = j + 1) begin : MACC_COL_13
               MACC #(
                   .LAST_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 12),
                   .PARTIAL_SUM_WIDTH(2 * EXTENDED_BYTE_WIDTH + 13)
               ) MACC_inst_13 (
                   .CLK(CLK),
                   .RESET(RESET),
                   .ENABLE(ENABLE),
                   .WEIGHT_INPUT(EXTENDED_WEIGHT_DATA[j]),
                   .PRELOAD_WEIGHT(LOAD_WEIGHT_MAP[13]),
                   .LOAD_WEIGHT(ACTIVATE_MAP[13]),
                   .INPUT(EXTENDED_SYSTOLIC_DATA[13]),
                   .LAST_SUM(INTERIM_RESULT[12][j][2 * EXTENDED_BYTE_WIDTH+11:0]),
                   .PARTIAL_SUM(INTERIM_RESULT[13][j][2 * EXTENDED_BYTE_WIDTH+12:0])
               );
           end
    endgenerate

    // ??????
    always @* begin
        for (i = 0; i < MATRIX_WIDTH; i = i + 1) begin
            if (SIGN_CONTROL_cs[2 + MATRIX_WIDTH - 1])
                RESULT_DATA[i*EXTENDED_BYTE_WIDTH +: EXTENDED_BYTE_WIDTH] = 
                    {INTERIM_RESULT[MATRIX_WIDTH-1][i][2*EXTENDED_BYTE_WIDTH-1], INTERIM_RESULT[MATRIX_WIDTH-1][i]};
            else
                RESULT_DATA[i*EXTENDED_BYTE_WIDTH +: EXTENDED_BYTE_WIDTH] = INTERIM_RESULT[MATRIX_WIDTH-1][i];
        end
    end

    // ????
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            ACTIVATE_CONTROL_cs <= {MATRIX_WIDTH{1'b0}};
            SIGN_CONTROL_cs <= {2 + MATRIX_WIDTH{1'b0}};
        end else begin
            ACTIVATE_CONTROL_cs <= ACTIVATE_CONTROL_ns;
            SIGN_CONTROL_cs <= SIGN_CONTROL_ns;
        end
    end

endmodule
