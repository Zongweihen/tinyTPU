`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:46:51 PM
// Design Name: 
// Module Name: DSP_LOAD_COUNTER
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


module DSP_LOAD_COUNTER #(
    parameter COUNTER_WIDTH = 32,
    parameter MATRIX_WIDTH = 14
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [COUNTER_WIDTH-1:0] START_VAL, // The given start value of the counter
    input wire LOAD, // Load flag for the start value
    
    output reg [COUNTER_WIDTH-1:0] COUNT_VAL // The current value of the counter
);

    // Internal signals
    reg [COUNTER_WIDTH-1:0] COUNTER_INPUT_cs = 0;
    reg [COUNTER_WIDTH-1:0] INPUT_PIPE_cs = 0;
    reg [COUNTER_WIDTH-1:0] COUNTER_cs = 0;
    reg LOAD_cs = 0;

    // Combinational logic for next state values
    wire [COUNTER_WIDTH-1:0] COUNTER_ns = COUNTER_cs + COUNTER_INPUT_cs;
    wire [COUNTER_WIDTH-1:0] INPUT_PIPE_ns = (LOAD) ? START_VAL : {{(COUNTER_WIDTH-1){1'b0}}, 1'b1};
    wire LOAD_ns = LOAD;

    // Sequential logic for counter operation
    always @(posedge CLK) begin
        if (RESET) begin
            COUNTER_INPUT_cs <= 0;
            INPUT_PIPE_cs <= 0;
            LOAD_cs <= 0;
            COUNTER_cs <= 0;
        end else if (ENABLE) begin
            COUNTER_INPUT_cs <= INPUT_PIPE_cs;
            INPUT_PIPE_cs <= INPUT_PIPE_ns;
            LOAD_cs <= LOAD_ns;
            if (LOAD_cs) begin
                COUNTER_cs <= 0;
            end else begin
                COUNTER_cs <= COUNTER_ns;
            end
        end
    end

    // Output assignment
    always @(posedge CLK) begin
        if (ENABLE) begin
            COUNT_VAL <= COUNTER_cs;
        end
    end

endmodule