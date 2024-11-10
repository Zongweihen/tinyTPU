`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 05:23:51 PM
// Design Name: 
// Module Name: LOOK_AHEAD_BUFFER
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

module LOOK_AHEAD_BUFFER #(
    parameter INSTRUCTION_WIDTH = 32,                      // Adjust the instruction width as needed
    parameter [INSTRUCTION_WIDTH-1:0] INIT_INSTRUCTION = {INSTRUCTION_WIDTH{1'b0}}  // Default to all zeros
)(
    input wire CLK, RESET,
    input wire ENABLE,
    input wire INSTRUCTION_BUSY,

    input wire [INSTRUCTION_WIDTH-1:0] INSTRUCTION_INPUT,
    input wire INSTRUCTION_WRITE,
    output reg [INSTRUCTION_WIDTH-1:0] INSTRUCTION_OUTPUT,
    output reg INSTRUCTION_READ
);

    // Define internal registers
    reg [INSTRUCTION_WIDTH-1:0] INPUT_REG_cs, INPUT_REG_ns;
    reg [INSTRUCTION_WIDTH-1:0] PIPE_REG_cs, PIPE_REG_ns;
    reg [INSTRUCTION_WIDTH-1:0] OUTPUT_REG_cs, OUTPUT_REG_ns;

    reg INPUT_WRITE_cs, INPUT_WRITE_ns;
    reg PIPE_WRITE_cs, PIPE_WRITE_ns;
    reg OUTPUT_WRITE_cs, OUTPUT_WRITE_ns;

    // Sequential logic for registers
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            INPUT_REG_cs <= INIT_INSTRUCTION;
            PIPE_REG_cs <= INIT_INSTRUCTION;
            OUTPUT_REG_cs <= INIT_INSTRUCTION;

            INPUT_WRITE_cs <= 1'b0;
            PIPE_WRITE_cs <= 1'b0;
            OUTPUT_WRITE_cs <= 1'b0;
        end else if (ENABLE && !INSTRUCTION_BUSY) begin
            INPUT_REG_cs <= INPUT_REG_ns;
            PIPE_REG_cs <= PIPE_REG_ns;
            OUTPUT_REG_cs <= OUTPUT_REG_ns;

            INPUT_WRITE_cs <= INPUT_WRITE_ns;
            PIPE_WRITE_cs <= PIPE_WRITE_ns;
            OUTPUT_WRITE_cs <= OUTPUT_WRITE_ns;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        INPUT_REG_ns = INSTRUCTION_INPUT;
        INPUT_WRITE_ns = INSTRUCTION_WRITE;
        INSTRUCTION_OUTPUT = (INSTRUCTION_BUSY) ? INIT_INSTRUCTION : OUTPUT_REG_cs;
        INSTRUCTION_READ = (!INSTRUCTION_BUSY) ? OUTPUT_WRITE_cs : 1'b0;

        // Pipeline logic
        if (PIPE_WRITE_cs) begin
            if (PIPE_REG_cs[INSTRUCTION_WIDTH-1:3] == 5'b00001) begin
                // Weight in pipeline
                if (INPUT_WRITE_cs) begin
                    PIPE_REG_ns = INPUT_REG_cs;
                    OUTPUT_REG_ns = PIPE_REG_cs;
                    PIPE_WRITE_ns = INPUT_WRITE_cs;
                    OUTPUT_WRITE_ns = PIPE_WRITE_cs;
                end else begin
                    PIPE_REG_ns = PIPE_REG_cs;
                    OUTPUT_REG_ns = INIT_INSTRUCTION;
                    PIPE_WRITE_ns = PIPE_WRITE_cs;
                    OUTPUT_WRITE_ns = 1'b0;
                end
            end else begin
                PIPE_REG_ns = INPUT_REG_cs;
                OUTPUT_REG_ns = PIPE_REG_cs;
                PIPE_WRITE_ns = INPUT_WRITE_cs;
                OUTPUT_WRITE_ns = PIPE_WRITE_cs;
            end
        end
        else begin
            PIPE_REG_ns = INPUT_REG_cs;
            OUTPUT_REG_ns = PIPE_REG_cs;
            PIPE_WRITE_ns = INPUT_WRITE_cs;
            OUTPUT_WRITE_ns = PIPE_WRITE_cs;
        end
    end

endmodule

