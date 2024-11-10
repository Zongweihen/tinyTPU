`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 04:43:35 PM
// Design Name: 
// Module Name: MATRIX_MULTIPLY_CONTROL
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

module MATRIX_MULTIPLY_CONTROL #(
    parameter MATRIX_WIDTH = 14,
    parameter COUNTER_WIDTH = 32
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [COUNTER_WIDTH-1:0] INSTRUCTION_CALC_LENGTH,
    input wire [COUNTER_WIDTH-1:0] INSTRUCTION_ACC_ADDRESS,
    input wire [COUNTER_WIDTH-1:0] INSTRUCTION_BUFFER_ADDRESS,
    input wire [1:0] INSTRUCTION_OP_CODE,
    input wire INSTRUCTION_EN,
    
    output wire [COUNTER_WIDTH-1:0] BUF_TO_SDS_ADDR,
    output reg BUF_READ_EN,
    output reg MMU_SDS_EN,
    output reg MMU_SIGNED,
    output reg ACTIVATE_WEIGHT,
    
    output wire [COUNTER_WIDTH-1:0] ACC_ADDR,
    output reg ACCUMULATE,
    output reg ACC_ENABLE,
    
    output reg BUSY,
    output reg RESOURCE_BUSY
);

    // Internal signals
    reg [COUNTER_WIDTH-1:0] WEIGHT_COUNTER;
    reg [COUNTER_WIDTH-1:0] ACCUMULATE_DELAY, ACC_EN_DELAY, MMU_SDS_DELAY;
    reg RUNNING;
    reg [MATRIX_WIDTH+2+3-1:0] RUNNING_PIPE;

    // Define additional internal control signals
    wire LENGTH_EVENT;
    reg LENGTH_RESET, LENGTH_LOAD, ADDRESS_LOAD, WEIGHT_RESET, ACC_RESET, ACC_LOAD;
    
    // Length Counter instantiation
    DSP_COUNTER #(COUNTER_WIDTH) LENGTH_COUNTER_i (
        .CLK(CLK),
        .RESET(LENGTH_RESET),
        .ENABLE(ENABLE),
        .END_VAL(INSTRUCTION_CALC_LENGTH),
        .LOAD(LENGTH_LOAD),
        .COUNT_EVENT(LENGTH_EVENT)
    );

    // Address Counter instantiations
    ACC_LOAD_COUNTER #(COUNTER_WIDTH, MATRIX_WIDTH) ADDRESS_COUNTER0_i (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .START_VAL(INSTRUCTION_ACC_ADDRESS),
        .LOAD(ADDRESS_LOAD),
        .COUNT_VAL(ACC_ADDR)
    );

    DSP_LOAD_COUNTER #(COUNTER_WIDTH, MATRIX_WIDTH) ADDRESS_COUNTER1_i (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .START_VAL(INSTRUCTION_BUFFER_ADDRESS),
        .LOAD(ADDRESS_LOAD),
        .COUNT_VAL(BUF_TO_SDS_ADDR)
    );

  // ?????
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            RUNNING <= 0;
            BUF_READ_EN <= 0;
            MMU_SDS_EN <= 0;
            ACC_ENABLE <= 0;
            ACCUMULATE <= 0;
            MMU_SIGNED <= 0;
            RESOURCE_BUSY <= 0;  // ????????
            RUNNING_PIPE <= 0;
        end else if (ENABLE) begin
            RUNNING_PIPE <= {RUNNING_PIPE[MATRIX_WIDTH+2+3-2:0], RUNNING};
            ACCUMULATE_DELAY <= {ACCUMULATE_DELAY[COUNTER_WIDTH-2:0], ACCUMULATE};
            ACC_EN_DELAY <= {ACC_EN_DELAY[COUNTER_WIDTH-2:0], ACC_ENABLE};
            MMU_SDS_DELAY <= {MMU_SDS_DELAY[COUNTER_WIDTH-2:0], MMU_SDS_EN};
            if (INSTRUCTION_EN) begin
                RUNNING <= 1;
                ADDRESS_LOAD <= 1;
                BUF_READ_EN <= 1;
                MMU_SDS_EN <= 1;
                ACC_ENABLE <= 1;
                LENGTH_LOAD <= 1;
                ACC_LOAD <= 1;
                WEIGHT_RESET <= 1;
            end else if (LENGTH_EVENT) begin
                RUNNING <= 0;
                BUF_READ_EN <= 0;
                MMU_SDS_EN <= 0;
                ACC_ENABLE <= 0;
                ACC_LOAD <= 0;
                ACC_RESET <= 1;
            end else begin
                // Maintain the run state
                RUNNING <= 1;
                BUF_READ_EN <= 1;
                MMU_SDS_EN <= 1;
                ACC_ENABLE <= 1;
            end
            
            // ?? RESOURCE_BUSY ??
            RESOURCE_BUSY <= RUNNING | |RUNNING_PIPE;
        end
    end


    // Weight Counter Logic
    always @(posedge CLK or posedge WEIGHT_RESET) begin
        if (WEIGHT_RESET | RESET) begin
            WEIGHT_COUNTER <= 0;
        end else if (ENABLE) begin
            if (WEIGHT_COUNTER == MATRIX_WIDTH-1) begin
                WEIGHT_COUNTER <= 0;
            end else begin
                WEIGHT_COUNTER <= WEIGHT_COUNTER + 1;
            end
        end
    end

    // Accumulator and address delay pipelines
//    always @(posedge CLK) begin
//        if (ENABLE) begin
//            RUNNING_PIPE <= {RUNNING_PIPE[MATRIX_WIDTH+2+3-2:0], RUNNING};
//            ACCUMULATE_DELAY <= {ACCUMULATE_DELAY[COUNTER_WIDTH-2:0], ACCUMULATE};
//            ACC_EN_DELAY <= {ACC_EN_DELAY[COUNTER_WIDTH-2:0], ACC_ENABLE};
//            MMU_SDS_DELAY <= {MMU_SDS_DELAY[COUNTER_WIDTH-2:0], MMU_SDS_EN};
//        end
//    end
endmodule
