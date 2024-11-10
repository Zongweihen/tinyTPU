`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:54:00 PM
// Design Name: 
// Module Name: ACTIVATION_CONTROL
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

module ACTIVATION_CONTROL #(
    parameter MATRIX_WIDTH = 14,
    parameter COUNTER_WIDTH = 32
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [COUNTER_WIDTH-1:0] INSTRUCTION_CALC_LENGTH,
    input wire [COUNTER_WIDTH-1:0] INSTRUCTION_ACC_ADDRESS,
    input wire [COUNTER_WIDTH-1:0] INSTRUCTION_BUFFER_ADDRESS,
    input wire [4:0] INSTRUCTION_OP_CODE,
    input wire INSTRUCTION_EN,
    
    output reg [COUNTER_WIDTH-1:0] ACC_TO_ACT_ADDR,
    output reg [3:0] ACTIVATION_FUNCTION,
    output reg SIGNED_NOT_UNSIGNED,
    
    output reg [COUNTER_WIDTH-1:0] ACT_TO_BUF_ADDR,
    output reg BUF_WRITE_EN,
    
    output reg BUSY,
    output reg RESOURCE_BUSY
);

    // Internal signals
    wire [COUNTER_WIDTH-1:0] ACC_TO_ACT_ADDR_cs, ACT_TO_BUF_ADDR_cs;
    reg [3:0] ACTIVATION_FUNCTION_cs;
    reg SIGNED_NOT_UNSIGNED_cs;
    reg BUF_WRITE_EN_cs;
    reg RUNNING_cs;
    reg [3+MATRIX_WIDTH+2+7+3-1:0] RUNNING_PIPE_cs;

    // Delays for pipelining
    reg [COUNTER_WIDTH-1:0] ACC_ADDRESS_DELAY [0:3+MATRIX_WIDTH+2-1];
    reg [3:0] ACTIVATION_DELAY [0:3+MATRIX_WIDTH+2+7-1];
    reg [0:3+MATRIX_WIDTH+2+7-1] S_NOT_U_DELAY;
    reg [COUNTER_WIDTH-1:0] ACT_TO_BUF_DELAY [0:3+MATRIX_WIDTH+2+7+3-1];
    reg [0:3+MATRIX_WIDTH+2+7+3-1] WRITE_EN_DELAY;

    wire LENGTH_EVENT;
    reg LENGTH_RESET, LENGTH_LOAD, ADDRESS_LOAD, ACT_RESET, ACT_LOAD;

    // Control signals for delayed pipelines
    always @* begin
        ACC_TO_ACT_ADDR = ACC_ADDRESS_DELAY[3+MATRIX_WIDTH+2-1];
        ACTIVATION_FUNCTION = ACTIVATION_DELAY[3+MATRIX_WIDTH+2+7-1];
        SIGNED_NOT_UNSIGNED = S_NOT_U_DELAY[3+MATRIX_WIDTH+2+7-1];
        ACT_TO_BUF_ADDR = ACT_TO_BUF_DELAY[3+MATRIX_WIDTH+2+7+3-1];
        BUF_WRITE_EN = WRITE_EN_DELAY[3+MATRIX_WIDTH+2+7+3-1];
        BUSY = RUNNING_cs;
    end

    // LENGTH_COUNTER instance for managing timing
    DSP_COUNTER #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) LENGTH_COUNTER_i (
        .CLK(CLK),
        .RESET(LENGTH_RESET),
        .ENABLE(ENABLE),
        .END_VAL(INSTRUCTION_CALC_LENGTH),
        .LOAD(LENGTH_LOAD),
        .COUNT_EVENT(LENGTH_EVENT)
    );

    // Address Counter for accumulator
    DSP_LOAD_COUNTER #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) ADDRESS_COUNTER0_i (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .START_VAL(INSTRUCTION_ACC_ADDRESS),
        .LOAD(ADDRESS_LOAD),
        .COUNT_VAL(ACC_TO_ACT_ADDR_cs)
    );

    // Address Counter for buffer
    DSP_LOAD_COUNTER #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) ADDRESS_COUNTER1_i (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .START_VAL(INSTRUCTION_BUFFER_ADDRESS),
        .LOAD(ADDRESS_LOAD),
        .COUNT_VAL(ACT_TO_BUF_ADDR_cs)
    );

    // Delayed pipeline control for buffer write enable, signed flag, and activation function
    always @(posedge CLK) begin
        if (RESET) begin
            BUF_WRITE_EN_cs <= 0;
            RUNNING_cs <= 0;
            RUNNING_PIPE_cs <= 0;
            ACTIVATION_FUNCTION_cs <= 0;
            SIGNED_NOT_UNSIGNED_cs <= 0;
        end else if (ENABLE) begin
            if (ACT_RESET) begin
                ACTIVATION_FUNCTION_cs <= 0;
                SIGNED_NOT_UNSIGNED_cs <= 0;
            end else if (ACT_LOAD) begin
                ACTIVATION_FUNCTION_cs <= INSTRUCTION_OP_CODE[3:0];
                SIGNED_NOT_UNSIGNED_cs <= INSTRUCTION_OP_CODE[4];
            end
            RUNNING_PIPE_cs <= {RUNNING_PIPE_cs[3+MATRIX_WIDTH+2+7+3-2:0], RUNNING_cs};
            RUNNING_cs <= RUNNING_PIPE_cs[3+MATRIX_WIDTH+2+7+3-1];
            BUF_WRITE_EN_cs <= BUF_WRITE_EN;
        end
    end

    // Control logic for executing the activation instruction
    always @* begin
        // Initialize control signals
        LENGTH_RESET = 0;
        LENGTH_LOAD = 0;
        ADDRESS_LOAD = 0;
        BUF_WRITE_EN = 0;
        RUNNING_cs = 0;
        ACT_LOAD = 0;
        ACT_RESET = 0;
        
        if (!RUNNING_cs) begin
            if (INSTRUCTION_EN) begin
                RUNNING_cs = 1;
                ADDRESS_LOAD = 1;
                BUF_WRITE_EN = 1;
                LENGTH_LOAD = 1;
                LENGTH_RESET = 1;
                ACT_LOAD = 1;
            end
        end else begin
            if (LENGTH_EVENT) begin
                RUNNING_cs = 0;
                ACT_RESET = 1;
            end else begin
                BUF_WRITE_EN = 1;
            end
        end
    end
    
    integer i;

    // Generate RESOURCE_BUSY by checking if any bit in RUNNING_PIPE_cs is high
    always @* begin
        RESOURCE_BUSY = RUNNING_cs;
        for (i = 0; i < 3+MATRIX_WIDTH+2+7+3; i = i + 1) begin
            RESOURCE_BUSY = RESOURCE_BUSY | RUNNING_PIPE_cs[i];
        end
    end
    
    // Delay pipelines
    always @(posedge CLK) begin
        if (ENABLE) begin
            for (i = 1; i < 3+MATRIX_WIDTH+2; i = i + 1) begin
                ACC_ADDRESS_DELAY[i] <= ACC_ADDRESS_DELAY[i-1];
            end
            for (i = 1; i < 3+MATRIX_WIDTH+2+7; i = i + 1) begin
                ACTIVATION_DELAY[i] <= ACTIVATION_DELAY[i-1];
                S_NOT_U_DELAY[i] <= S_NOT_U_DELAY[i-1];
            end
            for (i = 1; i < 3+MATRIX_WIDTH+2+7+3; i = i + 1) begin
                ACT_TO_BUF_DELAY[i] <= ACT_TO_BUF_DELAY[i-1];
                WRITE_EN_DELAY[i] <= WRITE_EN_DELAY[i-1];
            end
            
            ACC_ADDRESS_DELAY[0] <= ACC_TO_ACT_ADDR_cs;
            ACT_TO_BUF_DELAY[0] <= ACT_TO_BUF_ADDR_cs;
            ACTIVATION_DELAY[0] <= ACTIVATION_FUNCTION_cs;
            S_NOT_U_DELAY[0] <= SIGNED_NOT_UNSIGNED_cs;
            WRITE_EN_DELAY[0] <= BUF_WRITE_EN_cs;
        end
    end

endmodule
