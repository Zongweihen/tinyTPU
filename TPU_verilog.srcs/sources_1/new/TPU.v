`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 06:56:29 PM
// Design Name: 
// Module Name: TPU
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

module TPU #(
    parameter MATRIX_WIDTH = 14,
    parameter WEIGHT_BUFFER_DEPTH = 32768,
    parameter UNIFIED_BUFFER_DEPTH = 4096
) (
        input wire CLK,
        input wire RESET,
        input wire ENABLE,
        output wire [31:0] RUNTIME_COUNT,
        input wire [31:0] LOWER_INSTRUCTION_WORD,
        input wire [31:0] MIDDLE_INSTRUCTION_WORD,
        input wire [15:0] UPPER_INSTRUCTION_WORD,
        input wire [2:0] INSTRUCTION_WRITE_EN,
        output reg [8*MATRIX_WIDTH-1:0] WEIGHT_WRITE_PORT,
        input wire [15:0] WEIGHT_ADDRESS,
        input wire WEIGHT_ENABLE,
        input wire [MATRIX_WIDTH-1:0] WEIGHT_WRITE_ENABLE,
        output reg [8*MATRIX_WIDTH-1:0] BUFFER_WRITE_PORT,
        output reg [8*MATRIX_WIDTH-1:0] BUFFER_READ_PORT,
        input wire [15:0] BUFFER_ADDRESS,
        input wire BUFFER_ENABLE,
        input wire [MATRIX_WIDTH-1:0] BUFFER_WRITE_ENABLE,
        output wire SYNCHRONIZE
    );

    // Internal signals
    wire [79:0] INSTRUCTION;
    reg INSTRUCTION_ENABLE;
    wire EMPTY;
    wire BUSY;
    wire FULL;
    wire SYNCHRONIZE_IN;
    reg [8*MATRIX_WIDTH-1:0] weight_write_port_internal;
    reg [8*MATRIX_WIDTH-1:0] buffer_write_port_internal;
    wire [8*MATRIX_WIDTH-1:0] buffer_read_port_internal;
    wire [8*MATRIX_WIDTH-1:0] WEIGHT_WRITE_PORT_FLAT;
    wire [8*MATRIX_WIDTH-1:0] BUFFER_WRITE_PORT_FLAT;
    reg  [8*MATRIX_WIDTH-1:0] buffer_read_port_flat;
    // Internal flattened-to-2D signals conversion
//    reg [7:0] weight_write_port_internal [0:MATRIX_WIDTH-1];
//    reg [7:0] buffer_write_port_internal [0:MATRIX_WIDTH-1];
//    wire [7:0] buffer_read_port_internal [0:MATRIX_WIDTH-1];

    // Flattened output conversion
//    reg [MATRIX_WIDTH*8-1:0] buffer_read_port_flat;

    // Unflatten the incoming flattened data
    integer i;
    always @(*) begin
        for (i = 0; i < MATRIX_WIDTH; i = i + 1) begin
            weight_write_port_internal[i] = WEIGHT_WRITE_PORT_FLAT[i*8 +: 8];
            buffer_write_port_internal[i] = BUFFER_WRITE_PORT_FLAT[i*8 +: 8];
        end
    end

    // Flatten the outgoing data
    always @(*) begin
        for (i = 0; i < MATRIX_WIDTH; i = i + 1) begin
            buffer_read_port_flat[i*8 +: 8] = buffer_read_port_internal[i];
        end
    end

//    assign BUFFER_READ_PORT_FLAT = buffer_read_port_flat;
    
//    reg [31:0] runtime_count;
    reg instruction_enable; // ?? reg ??? wire?????? always ????
    
    // ??? RUNTIME_COUNTER ??
    RUNTIME_COUNTER RUNTIME_COUNTER_i (
        .CLK(CLK),
        .RESET(RESET),
        .INSTRUCTION_EN(instruction_enable),
        .SYNCHRONIZE(SYNCHRONIZE_IN),
        .COUNTER_VAL(RUNTIME_COUNT)
    );
    // Instruction FIFO instance
    INSTRUCTION_FIFO #(
        .FIFO_DEPTH(32)
    ) INSTRUCTION_FIFO_i (
        .CLK(CLK),
        .RESET(RESET),
        .LOWER_WORD(LOWER_INSTRUCTION_WORD),
        .MIDDLE_WORD(MIDDLE_INSTRUCTION_WORD),
        .UPPER_WORD(UPPER_INSTRUCTION_WORD),
        .WRITE_EN(INSTRUCTION_WRITE_EN),
        .OUTPUT(INSTRUCTION),
        .NEXT_EN(INSTRUCTION_ENABLE),
        .EMPTY(EMPTY),
        .FULL(FULL)
    );

    // TPU Core instance
    TPU_CORE #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
        .UNIFIED_BUFFER_DEPTH(UNIFIED_BUFFER_DEPTH)
    ) TPU_CORE_i (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),

        // Weight buffer ports
        .WEIGHT_WRITE_PORT(weight_write_port_internal),
        .WEIGHT_ADDRESS(WEIGHT_ADDRESS),
        .WEIGHT_ENABLE(WEIGHT_ENABLE),
        .WEIGHT_WRITE_ENABLE(WEIGHT_WRITE_ENABLE),

        // Unified buffer ports
        .BUFFER_WRITE_PORT(buffer_write_port_internal),
        .BUFFER_READ_PORT(buffer_read_port_internal),
        .BUFFER_ADDRESS(BUFFER_ADDRESS),
        .BUFFER_ENABLE(BUFFER_ENABLE),
        .BUFFER_WRITE_ENABLE(BUFFER_WRITE_ENABLE),

        // Instruction handling
        .INSTRUCTION_PORT(INSTRUCTION),
        .INSTRUCTION_ENABLE(INSTRUCTION_ENABLE),

        // Control signals
        .BUSY(BUSY),
        .SYNCHRONIZE(SYNCHRONIZE_IN)
    );

    assign SYNCHRONIZE = SYNCHRONIZE_IN;

    // Instruction feed logic
    always @(posedge CLK) begin
        if (BUSY == 1'b0 && EMPTY == 1'b0) begin
            INSTRUCTION_ENABLE <= 3'b100;
        end else begin
            INSTRUCTION_ENABLE <= 3'b000;
        end
    end

endmodule

