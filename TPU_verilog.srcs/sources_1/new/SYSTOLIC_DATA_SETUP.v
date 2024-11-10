`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 05:41:02 PM
// Design Name: 
// Module Name: SYSTOLIC_DATA_SETUP
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

module SYSTOLIC_DATA_SETUP #(
    parameter MATRIX_WIDTH = 14,
    parameter BYTE_WIDTH = 8  // Define BYTE_WIDTH as per requirement
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    input wire [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] DATA_INPUT, // Flattened input array
    output reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] SYSTOLIC_OUTPUT // Flattened output array
);

    reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] BUFFER_REG [1:MATRIX_WIDTH-1];

    integer i, j;

    // Shift Register Process - Diagonalizes the input array
    always @* begin
        // Initialize the BUFFER_REG with shifted DATA_INPUT values
        for (i = 1; i < MATRIX_WIDTH; i = i + 1) begin
            for (j = 1; j < MATRIX_WIDTH; j = j + 1) begin
                if (i == 1) begin
                    BUFFER_REG[i][j*BYTE_WIDTH +: BYTE_WIDTH] = DATA_INPUT[j*BYTE_WIDTH +: BYTE_WIDTH];
                end else begin
                    BUFFER_REG[i][j*BYTE_WIDTH +: BYTE_WIDTH] = BUFFER_REG[i-1][j*BYTE_WIDTH +: BYTE_WIDTH];
                end
            end
        end
    end

    // Systolic Output Assignment
    always @* begin
        SYSTOLIC_OUTPUT[0 +: BYTE_WIDTH] = DATA_INPUT[0 +: BYTE_WIDTH];
        for (i = 1; i < MATRIX_WIDTH; i = i + 1) begin
            SYSTOLIC_OUTPUT[i*BYTE_WIDTH +: BYTE_WIDTH] = BUFFER_REG[i][i*BYTE_WIDTH +: BYTE_WIDTH];
        end
    end

    // Sequential Logic for BUFFER_REG update
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            for (i = 1; i < MATRIX_WIDTH; i = i + 1) begin
                BUFFER_REG[i] <= {MATRIX_WIDTH*BYTE_WIDTH{1'b0}};
            end
        end else if (ENABLE) begin
            for (i = 1; i < MATRIX_WIDTH; i = i + 1) begin
                BUFFER_REG[i] <= BUFFER_REG[i];
            end
        end
    end

endmodule
