`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:04:13 PM
// Design Name: 
// Module Name: ACC_LOAD_COUNTER
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


module ACC_LOAD_COUNTER #(
    parameter COUNTER_WIDTH = 32,
    parameter MATRIX_WIDTH = 16
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    input wire LOAD,
    input wire [COUNTER_WIDTH-1:0] START_VAL,
    output reg [COUNTER_WIDTH-1:0] COUNT_VAL
);

    reg [COUNTER_WIDTH-1:0] COUNTER_INPUT_cs = 0;
    reg [COUNTER_WIDTH-1:0] START_VAL_cs = 0;
    reg [COUNTER_WIDTH-1:0] INPUT_PIPE_cs = 0;
    reg [COUNTER_WIDTH-1:0] COUNTER_cs = 0;
    reg LOAD_cs = 0;

    always @(posedge CLK) begin
        if (RESET) begin
            COUNTER_INPUT_cs <= 0;
            INPUT_PIPE_cs <= 0;
            LOAD_cs <= 0;
        end else if (ENABLE) begin
            if (LOAD) begin
                LOAD_cs <= LOAD;
                START_VAL_cs <= START_VAL;
                COUNTER_INPUT_cs <= START_VAL;
                COUNTER_cs <= 0;
            end else begin
                LOAD_cs <= LOAD;
                INPUT_PIPE_cs <= START_VAL;
                COUNTER_INPUT_cs <= INPUT_PIPE_cs;
                COUNTER_cs <= (COUNTER_cs == MATRIX_WIDTH - 1 + START_VAL) ? START_VAL :
                              (COUNTER_cs + COUNTER_INPUT_cs);
            end
        end
        COUNT_VAL <= COUNTER_cs;
    end

endmodule

