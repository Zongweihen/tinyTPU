`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: WEIGHT_BUFFER
// Description: Dual-port RAM module for storing weights with selective byte writes
//////////////////////////////////////////////////////////////////////////////////

module WEIGHT_BUFFER #(
    parameter MATRIX_WIDTH = 14,
    parameter TILE_WIDTH = 32768,    // Depth of the buffer
    parameter BYTE_WIDTH = 8         // Byte width
)(
    input wire CLK, 
    input wire RESET,
    input wire ENABLE,

    // Port 0
    input wire [15:0] ADDRESS0,          // Address for port 0
    input wire EN0,                      // Enable signal for port 0
    input wire WRITE_EN0,                // Write enable for port 0
    input wire [MATRIX_WIDTH*BYTE_WIDTH-1:0] WRITE_PORT0, // Write data for port 0
    output reg [MATRIX_WIDTH*BYTE_WIDTH-1:0] READ_PORT0,  // Read data for port 0

    // Port 1
    input wire [15:0] ADDRESS1,          // Address for port 1
    input wire EN1,                      // Enable signal for port 1
    input wire [MATRIX_WIDTH-1:0] WRITE_EN1, // Byte-level write enable for port 1
    input wire [MATRIX_WIDTH*BYTE_WIDTH-1:0] WRITE_PORT1, // Write data for port 1
    output reg [MATRIX_WIDTH*BYTE_WIDTH-1:0] READ_PORT1   // Read data for port 1
);

    // Define the RAM for the weight buffer
    reg [MATRIX_WIDTH*BYTE_WIDTH-1:0] RAM [0:TILE_WIDTH-1];

    // Temporary registers for read ports
    reg [MATRIX_WIDTH*BYTE_WIDTH-1:0] READ_PORT0_REG0, READ_PORT0_REG1;
    reg [MATRIX_WIDTH*BYTE_WIDTH-1:0] READ_PORT1_REG0, READ_PORT1_REG1;

    // Port 0 operation: Read and write
    always @(posedge CLK) begin
        if (RESET) begin
            READ_PORT0 <= 0;
        end else if (EN0) begin
            if (WRITE_EN0 && (ADDRESS0 < TILE_WIDTH)) begin
                // Write operation for port 0
                RAM[ADDRESS0] <= WRITE_PORT0;
            end
            READ_PORT0 <= READ_PORT0_REG1; // Output the second-stage register
        end
    end

    // Port 1 operation: Selective byte writes and read
    integer i;
    always @(posedge CLK) begin
        if (RESET) begin
            READ_PORT1 <= 0;
        end else if (EN1) begin
            if (ADDRESS1 < TILE_WIDTH) begin
                // Byte-wise write operation for port 1
                for (i = 0; i < MATRIX_WIDTH; i = i + 1) begin
                    if (WRITE_EN1[i]) begin
                        RAM[ADDRESS1][(i+1)*BYTE_WIDTH-1 -: BYTE_WIDTH] <= WRITE_PORT1[(i+1)*BYTE_WIDTH-1 -: BYTE_WIDTH];
                    end
                end
            end
            READ_PORT1 <= READ_PORT1_REG1; // Output the second-stage register
        end
    end

    // Sequential logic for pipeline registers
    always @(posedge CLK) begin
        if (RESET) begin
            READ_PORT0_REG0 <= 0;
            READ_PORT0_REG1 <= 0;
            READ_PORT1_REG0 <= 0;
            READ_PORT1_REG1 <= 0;
        end else if (ENABLE) begin
            // Pipeline registers for Port 0
            READ_PORT0_REG0 <= RAM[ADDRESS0];
            READ_PORT0_REG1 <= READ_PORT0_REG0;

            // Pipeline registers for Port 1
            READ_PORT1_REG0 <= RAM[ADDRESS1];
            READ_PORT1_REG1 <= READ_PORT1_REG0;
        end
    end

endmodule
