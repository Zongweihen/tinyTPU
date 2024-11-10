`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 05:33:52 PM
// Design Name: 
// Module Name: CONTROL_COORDINATOR
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


module CONTROL_COORDINATOR #(
    parameter INSTRUCTION_WIDTH = 32,
    parameter OP_CODE_WIDTH = 8
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    input wire [INSTRUCTION_WIDTH-1:0] INSTRUCTION,
    input wire INSTRUCTION_EN,
    output wire BUSY,
    
    input wire WEIGHT_BUSY,
    input wire WEIGHT_RESOURCE_BUSY,
    output reg [INSTRUCTION_WIDTH-1:0] WEIGHT_INSTRUCTION,
    output reg WEIGHT_INSTRUCTION_EN,
    
    input wire MATRIX_BUSY,
    input wire MATRIX_RESOURCE_BUSY,
    output reg [INSTRUCTION_WIDTH-1:0] MATRIX_INSTRUCTION,
    output reg MATRIX_INSTRUCTION_EN,
    
    input wire ACTIVATION_BUSY,
    input wire ACTIVATION_RESOURCE_BUSY,
    output reg [INSTRUCTION_WIDTH-1:0] ACTIVATION_INSTRUCTION,
    output reg ACTIVATION_INSTRUCTION_EN,
    
    output reg SYNCHRONIZE
);

    reg [3:0] EN_FLAGS_cs = 4'b0000;
    reg [3:0] EN_FLAGS_ns;
    reg [INSTRUCTION_WIDTH-1:0] INSTRUCTION_cs;
    reg [INSTRUCTION_WIDTH-1:0] INSTRUCTION_ns;
    reg INSTRUCTION_EN_cs;
    reg INSTRUCTION_EN_ns;
    reg INSTRUCTION_RUNNING;

    assign BUSY = INSTRUCTION_RUNNING;

    // Decode process
    always @(*) begin
        EN_FLAGS_ns = 4'b0000;
        case (INSTRUCTION[OP_CODE_WIDTH-1:0])
            8'hFF: EN_FLAGS_ns = 4'b0001;                // Synchronize
            default:
                if (INSTRUCTION[OP_CODE_WIDTH-1] == 1'b1)      EN_FLAGS_ns = 4'b0010;  // Activate
                else if (INSTRUCTION[OP_CODE_WIDTH-3] == 1'b1) EN_FLAGS_ns = 4'b0100;  // Matrix Multiply
                else if (INSTRUCTION[OP_CODE_WIDTH-5] == 1'b1) EN_FLAGS_ns = 4'b1000;  // Load Weight
        endcase
    end

    // Running detect process
    always @(*) begin
        WEIGHT_INSTRUCTION_EN = 0;
        MATRIX_INSTRUCTION_EN = 0;
        ACTIVATION_INSTRUCTION_EN = 0;
        SYNCHRONIZE = 0;

        if (INSTRUCTION_EN_cs) begin
            if (EN_FLAGS_cs[3]) begin  // Synchronize instruction
                if (WEIGHT_RESOURCE_BUSY || MATRIX_RESOURCE_BUSY || ACTIVATION_RESOURCE_BUSY) begin
                    INSTRUCTION_RUNNING = 1;
                end else begin
                    INSTRUCTION_RUNNING = 0;
                    SYNCHRONIZE = 1;
                end
            end else begin
                if ((WEIGHT_BUSY && EN_FLAGS_cs[0]) ||
                    (MATRIX_BUSY && (EN_FLAGS_cs[1] || EN_FLAGS_cs[2])) ||  // Activation waits for matrix multiply
                    (ACTIVATION_BUSY && EN_FLAGS_cs[2])) begin
                    INSTRUCTION_RUNNING = 1;
                end else begin
                    INSTRUCTION_RUNNING = 0;
                    WEIGHT_INSTRUCTION_EN = EN_FLAGS_cs[0];
                    MATRIX_INSTRUCTION_EN = EN_FLAGS_cs[1];
                    ACTIVATION_INSTRUCTION_EN = EN_FLAGS_cs[2];
                end
            end
        end else begin
            INSTRUCTION_RUNNING = 0;
        end
    end

    // Sequential logic
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            EN_FLAGS_cs <= 4'b0000;
            INSTRUCTION_cs <= 0;
            INSTRUCTION_EN_cs <= 0;
        end else if (!INSTRUCTION_RUNNING && ENABLE) begin
            EN_FLAGS_cs <= EN_FLAGS_ns;
            INSTRUCTION_cs <= INSTRUCTION;
            INSTRUCTION_EN_cs <= INSTRUCTION_EN;
        end
    end

    // Assign output instructions
    always @(*) begin
        WEIGHT_INSTRUCTION = INSTRUCTION_cs;
        MATRIX_INSTRUCTION = INSTRUCTION_cs;
        ACTIVATION_INSTRUCTION = INSTRUCTION_cs;
    end

endmodule
