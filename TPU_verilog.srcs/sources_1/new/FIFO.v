`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 06:51:21 PM
// Design Name: 
// Module Name: FIFO
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

module FIFO #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 32,
    parameter ADDRESS_WIDTH = 5 // Calculated as log2(FIFO_DEPTH)
)(
    input wire CLK,
    input wire RESET,
    input wire [DATA_WIDTH-1:0] INPUT,  // Data input for writing
    input wire WRITE_EN,                // Write enable signal
    output reg [DATA_WIDTH-1:0] OUTPUT, // Data output for reading
    input wire NEXT_EN,                 // Read or 'next' enable of the FIFO
    output wire EMPTY,                  // FIFO is empty
    output wire FULL                    // FIFO is full
);

    // Internal signals
    reg [ADDRESS_WIDTH-1:0] write_ptr, read_ptr;
    reg looped;
    wire [DATA_WIDTH-1:0] ram_output;

    // Instantiating the DIST_RAM module
    DIST_RAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .DATA_DEPTH(FIFO_DEPTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) ram_inst (
        .CLK(CLK),
        .IN_ADDR(write_ptr),
        .INPUT(INPUT),
        .WRITE_EN(WRITE_EN),
        .OUT_ADDR(read_ptr),
        .OUTPUT(ram_output)
    );

    // Assign the output from the RAM to the OUTPUT port
    always @(posedge CLK) begin
        if (RESET) begin
            OUTPUT <= 0;
        end else begin
            OUTPUT <= ram_output;
        end
    end

    // FIFO control signals
    assign EMPTY = (write_ptr == read_ptr) && !looped;
    assign FULL = (write_ptr == read_ptr) && looped;

    // Write pointer logic
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            write_ptr <= 0;
            looped <= 0;
        end else if (WRITE_EN && !FULL) begin
            if (write_ptr == FIFO_DEPTH - 1) begin
                write_ptr <= 0;
                looped <= 1;
            end else begin
                write_ptr <= write_ptr + 1;
            end
        end
    end

    // Read pointer logic
    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            read_ptr <= 0;
        end else if (NEXT_EN && !EMPTY) begin
            if (read_ptr == FIFO_DEPTH - 1) begin
                read_ptr <= 0;
                looped <= 0;
            end else begin
                read_ptr <= read_ptr + 1;
            end
        end
    end

endmodule
