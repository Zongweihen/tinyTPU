`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: UNIFIED_BUFFER
// Description: Dual-port RAM with an additional master port for prioritized access
//////////////////////////////////////////////////////////////////////////////////

module UNIFIED_BUFFER #(
    parameter MATRIX_WIDTH = 14,
    parameter TILE_WIDTH = 4096,
    parameter BYTE_WIDTH = 8 // Define BYTE_WIDTH
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,

    // Master Port
    input wire [31:0] MASTER_ADDRESS,
    input wire MASTER_EN,
    input wire [MATRIX_WIDTH-1:0] MASTER_WRITE_EN,
    input wire [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] MASTER_WRITE_PORT,
    output reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] MASTER_READ_PORT,
    
    // Port 0
    input wire [31:0] ADDRESS0,
    input wire EN0,
    output reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] READ_PORT0,
    
    // Port 1
    input wire [31:0] ADDRESS1,
    input wire EN1,
    input wire WRITE_EN1,
    input wire [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] WRITE_PORT1
);

    // Define the RAM for the unified buffer
    reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] RAM [0:TILE_WIDTH-1];

    // Temporary registers for read ports
    reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] READ_PORT0_REG0, READ_PORT0_REG1;
    reg [(MATRIX_WIDTH*BYTE_WIDTH)-1:0] MASTER_READ_PORT_REG0, MASTER_READ_PORT_REG1;

    // Address and enable override logic for Master port priority
    wire [31:0] ADDRESS0_OVERRIDE = (MASTER_EN) ? MASTER_ADDRESS : ADDRESS0;
    wire [31:0] ADDRESS1_OVERRIDE = (MASTER_EN) ? MASTER_ADDRESS : ADDRESS1;
    wire EN0_OVERRIDE = (MASTER_EN) ? MASTER_EN : EN0;
    wire EN1_OVERRIDE = (MASTER_EN) ? MASTER_EN : EN1;
    
    
    integer i;

    // Master port write operation (with byte-wise enable)
    always @(posedge CLK) begin
        if (EN0_OVERRIDE) begin
            if (ADDRESS0_OVERRIDE < TILE_WIDTH) begin
                for (i = 0; i < MATRIX_WIDTH; i = i + 1) begin
                    if (MASTER_WRITE_EN[i]) begin
                        RAM[ADDRESS0_OVERRIDE][((i + 1) * BYTE_WIDTH - 1) -: BYTE_WIDTH] <= MASTER_WRITE_PORT[((i + 1) * BYTE_WIDTH - 1) -: BYTE_WIDTH];
                    end
                end
                READ_PORT0_REG0 <= RAM[ADDRESS0_OVERRIDE];
            end
        end
    end

    // Port 0 read process
    always @(posedge CLK) begin
        if (RESET) begin
            READ_PORT0_REG0 <= 0;
            READ_PORT0_REG1 <= 0;
        end else if (ENABLE && EN0) begin
            READ_PORT0_REG1 <= READ_PORT0_REG0;
            READ_PORT0 <= READ_PORT0_REG1;
        end
    end

    // Port 1 write and read process
    always @(posedge CLK) begin
        if (EN1_OVERRIDE) begin
            if (ADDRESS1_OVERRIDE < TILE_WIDTH) begin
                // Write operation for port 1
                if (WRITE_EN1) begin
                    RAM[ADDRESS1_OVERRIDE] <= WRITE_PORT1;
                end
                MASTER_READ_PORT_REG0 <= RAM[ADDRESS1_OVERRIDE];
            end
        end
    end

    // Sequential logic for Master Read Port
    always @(posedge CLK) begin
        if (RESET) begin
            MASTER_READ_PORT_REG0 <= 0;
            MASTER_READ_PORT_REG1 <= 0;
        end else if (ENABLE && MASTER_EN) begin
            MASTER_READ_PORT_REG1 <= MASTER_READ_PORT_REG0;
            MASTER_READ_PORT <= MASTER_READ_PORT_REG1;
        end
    end

endmodule
