`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 06:52:23 PM
// Design Name: 
// Module Name: DIST_RAM
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

module DIST_RAM #(
    parameter DATA_WIDTH = 8,    // Width of a data word
    parameter DATA_DEPTH = 32,   // Depth of the memory
    parameter ADDRESS_WIDTH = 5  // Width of the addresses
)(
    input wire CLK,
    input wire [ADDRESS_WIDTH-1:0] IN_ADDR,   // Input address for writing
    input wire [DATA_WIDTH-1:0] INPUT,        // Data input for writing
    input wire WRITE_EN,                      // Write enable signal
    input wire [ADDRESS_WIDTH-1:0] OUT_ADDR,  // Address for reading
    output reg [DATA_WIDTH-1:0] OUTPUT        // Data output for reading
);

    // Memory array definition
    reg [DATA_WIDTH-1:0] RAM [0:DATA_DEPTH-1];

    // Write process
    always @(posedge CLK) begin
        if (WRITE_EN) begin
            RAM[IN_ADDR] <= INPUT;  // Write data on rising edge of CLK if WRITE_EN is high
        end
    end

    // Read process (asynchronous read)
    always @(*) begin
        OUTPUT = RAM[OUT_ADDR];     // Output data based on OUT_ADDR
    end

endmodule

