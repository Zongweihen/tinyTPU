`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 05:53:15 PM
// Design Name: 
// Module Name: MACC
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


module MACC #(
    parameter LAST_SUM_WIDTH = 0,
    parameter PARTIAL_SUM_WIDTH = 16  // Assume 2 * EXTENDED_BYTE_WIDTH for default
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    // Weights - current and preload
    input wire [7:0] WEIGHT_INPUT,  // EXTENDED_BYTE_TYPE assumed to be 8 bits here
    input wire PRELOAD_WEIGHT,
    input wire LOAD_WEIGHT,
    
    // Input
    input wire [7:0] INPUT,         // EXTENDED_BYTE_TYPE assumed to be 8 bits here
    input wire [LAST_SUM_WIDTH-1:0] LAST_SUM,
    
    // Output
    output reg [PARTIAL_SUM_WIDTH-1:0] PARTIAL_SUM
);

    // Internal registers
    reg [7:0] PREWEIGHT_cs, PREWEIGHT_ns;
    reg [7:0] WEIGHT_cs, WEIGHT_ns;
    reg [7:0] INPUT_cs, INPUT_ns;
    reg [15:0] PIPELINE_cs, PIPELINE_ns; // Result of multiplication (assuming EXTENDED_BYTE_WIDTH is 8)
    reg [PARTIAL_SUM_WIDTH-1:0] PARTIAL_SUM_cs, PARTIAL_SUM_ns;

    // Multiply-Add process
    always @* begin
        INPUT_ns = INPUT;
        PREWEIGHT_ns = WEIGHT_INPUT;
        WEIGHT_ns = PREWEIGHT_cs;

        // Perform multiplication
        PIPELINE_ns = $signed(INPUT_cs) * $signed(WEIGHT_cs);

        // Accumulate result based on LAST_SUM_WIDTH
        if (LAST_SUM_WIDTH > 0 && LAST_SUM_WIDTH < PARTIAL_SUM_WIDTH) begin
            PARTIAL_SUM_ns = $signed({PIPELINE_cs[15], PIPELINE_cs}) + $signed({LAST_SUM[LAST_SUM_WIDTH-1], LAST_SUM});
        end else if (LAST_SUM_WIDTH > 0 && LAST_SUM_WIDTH == PARTIAL_SUM_WIDTH) begin
            PARTIAL_SUM_ns = $signed(PIPELINE_cs) + $signed(LAST_SUM);
        end else begin
            PARTIAL_SUM_ns = PIPELINE_cs;
        end
    end

    // Sequential process
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            PREWEIGHT_cs <= 0;
            WEIGHT_cs <= 0;
            INPUT_cs <= 0;
            PIPELINE_cs <= 0;
            PARTIAL_SUM_cs <= 0;
        end else if (CLK) begin
            if (PRELOAD_WEIGHT) begin
                PREWEIGHT_cs <= PREWEIGHT_ns;
            end
            if (LOAD_WEIGHT) begin
                WEIGHT_cs <= WEIGHT_ns;
            end
            if (ENABLE) begin
                INPUT_cs <= INPUT_ns;
                PIPELINE_cs <= PIPELINE_ns;
                PARTIAL_SUM_cs <= PARTIAL_SUM_ns;
            end
        end
    end

    // Output assignment
    always @(posedge CLK) begin
        PARTIAL_SUM <= PARTIAL_SUM_cs;
    end

endmodule
