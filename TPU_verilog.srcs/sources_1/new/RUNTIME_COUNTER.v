`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 06:55:40 PM
// Design Name: 
// Module Name: RUNTIME_COUNTER
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

module RUNTIME_COUNTER (
    input wire CLK,
    input wire RESET,
    input wire INSTRUCTION_EN,   // Signals that a new instruction was fed and starts the counter
    input wire SYNCHRONIZE,      // Signals that the calculations are done, stops the counter
    output reg [31:0] COUNTER_VAL // Current value of the counter
);

    // Internal signals
    reg [31:0] COUNTER_cs, COUNTER_ns;
    reg [31:0] PIPELINE_cs, PIPELINE_ns;
    reg STATE_cs, STATE_ns;
    reg RESET_COUNTER;

    // Counter increment logic
    always @* begin
        COUNTER_ns = COUNTER_cs + 1;
    end

    // Pipeline for DSP performance
    always @* begin
        PIPELINE_ns = COUNTER_cs;
    end

    // Assign the pipeline output to COUNTER_VAL
    always @(posedge CLK) begin
        if (RESET)
            COUNTER_VAL <= 32'd0;
        else
            COUNTER_VAL <= PIPELINE_cs;
    end

    // FSM logic to control counter behavior
    always @* begin
        // FSM state transition
        case (STATE_cs)
            1'b0: begin
                if (INSTRUCTION_EN && !SYNCHRONIZE) begin
                    STATE_ns = 1'b1;
                    RESET_COUNTER = 1'b1;
                end else begin
                    STATE_ns = 1'b0;
                    RESET_COUNTER = 1'b0;
                end
            end
            1'b1: begin
                if (SYNCHRONIZE) begin
                    STATE_ns = 1'b0;
                    RESET_COUNTER = 1'b0;
                end else begin
                    STATE_ns = 1'b1;
                    RESET_COUNTER = 1'b0;
                end
            end
            default: begin
                STATE_ns = 1'b0;
                RESET_COUNTER = 1'b0;
            end
        endcase
    end

    // Sequential logic to update state and counter
    always @(posedge CLK) begin
        if (RESET) begin
            STATE_cs <= 1'b0;
            PIPELINE_cs <= 32'd0;
        end else begin
            STATE_cs <= STATE_ns;
            PIPELINE_cs <= PIPELINE_ns;
        end

        if (RESET_COUNTER) begin
            COUNTER_cs <= 32'd0;
        end else if (STATE_cs == 1'b1) begin
            COUNTER_cs <= COUNTER_ns;
        end
    end

endmodule
