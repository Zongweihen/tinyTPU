`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:45:16 PM
// Design Name: 
// Module Name: DSP_COUNTER
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

module DSP_COUNTER #(
    parameter COUNTER_WIDTH = 32 // The width of the counter
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [COUNTER_WIDTH-1:0] END_VAL, // The end value of the counter
    input wire LOAD, // Load signal for the end value
    
    output reg [COUNTER_WIDTH-1:0] COUNT_VAL, // The current value of the counter
    output reg COUNT_EVENT // The event, asserted when the end value is reached
);

    // Internal signals
    reg [COUNTER_WIDTH-1:0] COUNTER = 0;
    reg [COUNTER_WIDTH-1:0] END_REG = 0;
    
    reg EVENT_cs = 0;
    reg EVENT_PIPE = 0;


    always @(posedge CLK) begin
        if (RESET) begin
            COUNTER <= 0;
            EVENT_cs <= 0;
            EVENT_PIPE <= 0;
            END_REG <= 0;
        end else begin
            if (ENABLE) begin
                COUNTER <= COUNTER + 1;
                EVENT_cs <= (COUNTER == END_REG) ? 1 : 0; // ?????? EVENT_cs
                EVENT_PIPE <= EVENT_cs;
            end
            
            if (LOAD) begin
                END_REG <= END_VAL;
            end
        end
    end
    // Output assignments
    always @(posedge CLK) begin
        COUNT_VAL <= COUNTER;
        COUNT_EVENT <= EVENT_PIPE;
    end

endmodule