`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 06:50:35 PM
// Design Name: 
// Module Name: INSTRUCTION_FIFO
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

module INSTRUCTION_FIFO #(
    parameter FIFO_DEPTH = 32,
    parameter BYTE_WIDTH = 8
)(
    input wire CLK, 
    input wire RESET,
    
    // Inputs
    input wire [(4*BYTE_WIDTH)-1:0] LOWER_WORD,
    input wire [(4*BYTE_WIDTH)-1:0] MIDDLE_WORD,
    input wire [(2*BYTE_WIDTH)-1:0] UPPER_WORD,
    input wire [2:0] WRITE_EN,

    // Outputs
    output reg [(10*BYTE_WIDTH)-1:0] OUTPUT,
    input wire NEXT_EN,
    output wire EMPTY,
    output wire FULL
);

    // Internal signals
    wire EMPTY_VECTOR[0:2];
    wire FULL_VECTOR[0:2];
    
    wire [(4*BYTE_WIDTH)-1:0] LOWER_OUTPUT;
    wire [(4*BYTE_WIDTH)-1:0] MIDDLE_OUTPUT;
    wire [(2*BYTE_WIDTH)-1:0] UPPER_OUTPUT;

    // Output assignment combining the three parts into one instruction
    always @(*) begin
        OUTPUT = {UPPER_OUTPUT, MIDDLE_OUTPUT, LOWER_OUTPUT};
    end

    // Empty and Full signals
    assign EMPTY = EMPTY_VECTOR[0] | EMPTY_VECTOR[1] | EMPTY_VECTOR[2];
    assign FULL = FULL_VECTOR[0] | FULL_VECTOR[1] | FULL_VECTOR[2];

    // FIFO for LOWER_WORD
    FIFO #(
        .DATA_WIDTH(4*BYTE_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_lower (
        .CLK(CLK),
        .RESET(RESET),
        .INPUT(LOWER_WORD),
        .WRITE_EN(WRITE_EN[0]),
        .OUTPUT(LOWER_OUTPUT),
        .NEXT_EN(NEXT_EN),
        .EMPTY(EMPTY_VECTOR[0]),
        .FULL(FULL_VECTOR[0])
    );

    // FIFO for MIDDLE_WORD
    FIFO #(
        .DATA_WIDTH(4*BYTE_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_middle (
        .CLK(CLK),
        .RESET(RESET),
        .INPUT(MIDDLE_WORD),
        .WRITE_EN(WRITE_EN[1]),
        .OUTPUT(MIDDLE_OUTPUT),
        .NEXT_EN(NEXT_EN),
        .EMPTY(EMPTY_VECTOR[1]),
        .FULL(FULL_VECTOR[1])
    );

    // FIFO for UPPER_WORD (halfword)
    FIFO #(
        .DATA_WIDTH(2*BYTE_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) fifo_upper (
        .CLK(CLK),
        .RESET(RESET),
        .INPUT(UPPER_WORD),
        .WRITE_EN(WRITE_EN[2]),
        .OUTPUT(UPPER_OUTPUT),
        .NEXT_EN(NEXT_EN),
        .EMPTY(EMPTY_VECTOR[2]),
        .FULL(FULL_VECTOR[2])
    );

endmodule

