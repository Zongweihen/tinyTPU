`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:57:00 PM
// Design Name: 
// Module Name: WEIGHT_CONTROL
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


module WEIGHT_CONTROL #(
    parameter MATRIX_WIDTH = 14,
    parameter COUNTER_WIDTH = 32,
    parameter WEIGHT_COUNTER_WIDTH = 4, // adjust based on MATRIX_WIDTH and log2
    parameter WEIGHT_ADDRESS_WIDTH = 32,
    parameter BYTE_WIDTH = 8
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [WEIGHT_ADDRESS_WIDTH-1:0] INSTRUCTION_WEIGHT_ADDRESS,
    input wire [4:0] INSTRUCTION_OP_CODE, // The weight instruction to be executed
    input wire INSTRUCTION_EN,
    
    output reg WEIGHT_READ_EN,
    output reg [WEIGHT_ADDRESS_WIDTH-1:0] WEIGHT_BUFFER_ADDRESS,
    output reg LOAD_WEIGHT,
    output reg [BYTE_WIDTH-1:0] WEIGHT_ADDRESS,
    output reg WEIGHT_SIGNED,
    output reg BUSY,
    output reg RESOURCE_BUSY
);

    // Internal signals
    reg [2:0] LOAD_WEIGHT_cs, LOAD_WEIGHT_ns;
    reg WEIGHT_READ_EN_cs, WEIGHT_READ_EN_ns;
    reg WEIGHT_SIGNED_cs, WEIGHT_SIGNED_ns;
    reg [WEIGHT_COUNTER_WIDTH-1:0] WEIGHT_ADDRESS_cs, WEIGHT_ADDRESS_ns;
    reg [2:0] SIGNED_PIPE_cs, SIGNED_PIPE_ns;
    reg [WEIGHT_ADDRESS_WIDTH-1:0] BUFFER_PIPE_cs;
    wire [WEIGHT_ADDRESS_WIDTH-1:0] BUFFER_PIPE_ns;
    reg [WEIGHT_COUNTER_WIDTH-1:0] WEIGHT_PIPE [0:5];
    reg [2:0] READ_PIPE_cs, READ_PIPE_ns;
    reg RUNNING_cs, RUNNING_ns;
    reg [2:0] RUNNING_PIPE_cs, RUNNING_PIPE_ns;
    
    wire LENGTH_EVENT;
    reg LENGTH_RESET, LENGTH_LOAD, ADDRESS_LOAD;

    // LENGTH_COUNTER instance
    DSP_COUNTER #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) LENGTH_COUNTER_i (
        .CLK(CLK),
        .RESET(LENGTH_RESET),
        .ENABLE(ENABLE),
        .END_VAL(INSTRUCTION_WEIGHT_ADDRESS),
        .LOAD(LENGTH_LOAD),
        .COUNT_EVENT(LENGTH_EVENT)
    );

    // ADDRESS_COUNTER instance
    DSP_LOAD_COUNTER #(
        .COUNTER_WIDTH(WEIGHT_ADDRESS_WIDTH)
    ) ADDRESS_COUNTER_i (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .START_VAL(INSTRUCTION_WEIGHT_ADDRESS),
        .LOAD(ADDRESS_LOAD),
        .COUNT_VAL(BUFFER_PIPE_ns)
    );

    // Control Logic
    always @* begin
        LENGTH_RESET = 0;
        LENGTH_LOAD = 0;
        ADDRESS_LOAD = 0;
        WEIGHT_READ_EN_ns = 0;
        RUNNING_ns = 0;
        WEIGHT_SIGNED_ns = 0;
        LOAD_WEIGHT_ns = 0;
        SIGNED_PIPE_ns = 0;

        if (!RUNNING_cs && INSTRUCTION_EN) begin
            RUNNING_ns = 1;
            ADDRESS_LOAD = 1;
            WEIGHT_READ_EN_ns = 1;
            LENGTH_LOAD = 1;
            LENGTH_RESET = 1;
            WEIGHT_SIGNED_ns = INSTRUCTION_OP_CODE[0];
        end else if (RUNNING_cs && LENGTH_EVENT) begin
            RUNNING_ns = 0;
            WEIGHT_READ_EN_ns = 0;
        end else if (RUNNING_cs) begin
            WEIGHT_READ_EN_ns = 1;
            LOAD_WEIGHT_ns = 1;
        end
    end

    // Resource Busy calculation
    always @* begin
        RESOURCE_BUSY = RUNNING_cs | |RUNNING_PIPE_cs;
    end

    // Sequential Logic
    always @(posedge CLK) begin
        if (RESET) begin
            RUNNING_cs <= 0;
            RUNNING_PIPE_cs <= 0;
            WEIGHT_READ_EN_cs <= 0;
            WEIGHT_SIGNED_cs <= 0;
            LOAD_WEIGHT_cs <= 0;
            WEIGHT_ADDRESS_cs <= 0;
            BUFFER_PIPE_cs <= 0;
            WEIGHT_PIPE[0] <= 0;
            WEIGHT_PIPE[1] <= 0;
            WEIGHT_PIPE[2] <= 0;
            WEIGHT_PIPE[3] <= 0;
            WEIGHT_PIPE[4] <= 0;
            WEIGHT_PIPE[5] <= 0;
            READ_PIPE_cs <= 0;
        end else if (ENABLE) begin
            RUNNING_cs <= RUNNING_ns;
            RUNNING_PIPE_cs <= {RUNNING_PIPE_cs[1:0], RUNNING_cs};
            WEIGHT_READ_EN_cs <= WEIGHT_READ_EN_ns;
            WEIGHT_SIGNED_cs <= WEIGHT_SIGNED_ns;
            LOAD_WEIGHT_cs <= LOAD_WEIGHT_ns;
            BUFFER_PIPE_cs <= BUFFER_PIPE_ns;
            WEIGHT_PIPE[0] <= WEIGHT_ADDRESS_cs;
            WEIGHT_PIPE[1] <= WEIGHT_PIPE[0];
            WEIGHT_PIPE[2] <= WEIGHT_PIPE[1];
            WEIGHT_PIPE[3] <= WEIGHT_PIPE[2];
            WEIGHT_PIPE[4] <= WEIGHT_PIPE[3];
            WEIGHT_PIPE[5] <= WEIGHT_PIPE[4];
            READ_PIPE_cs <= READ_PIPE_ns;

            if (LENGTH_RESET) begin
                WEIGHT_ADDRESS_cs <= 0;
            end else begin
                WEIGHT_ADDRESS_cs <= WEIGHT_ADDRESS_ns;
            end
        end
    end

    // WEIGHT_ADDRESS Increment Logic
    always @* begin
        if (WEIGHT_ADDRESS_cs == (MATRIX_WIDTH - 1)) begin
            WEIGHT_ADDRESS_ns = 0;
        end else begin
            WEIGHT_ADDRESS_ns = WEIGHT_ADDRESS_cs + 1;
        end
    end

    // Output assignments
    always @* begin
        WEIGHT_BUFFER_ADDRESS = BUFFER_PIPE_cs;
        WEIGHT_ADDRESS = {4'b0, WEIGHT_PIPE[5]};
        WEIGHT_SIGNED = WEIGHT_SIGNED_cs;
        LOAD_WEIGHT = LOAD_WEIGHT_cs[2];
        WEIGHT_READ_EN = WEIGHT_READ_EN_cs & READ_PIPE_cs[2];
        BUSY = RUNNING_cs;
    end

endmodule
