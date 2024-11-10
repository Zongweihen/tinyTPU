`timescale 1ns / 1ps

module TPU_CORE #(
    parameter MATRIX_WIDTH = 14,
    parameter WEIGHT_BUFFER_DEPTH = 32768,
    parameter UNIFIED_BUFFER_DEPTH = 4096
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,

    // Weight Buffer
    input wire [MATRIX_WIDTH*8-1:0] WEIGHT_WRITE_PORT,
    input wire [15:0] WEIGHT_ADDRESS,
    input wire WEIGHT_ENABLE,
    input wire [MATRIX_WIDTH-1:0] WEIGHT_WRITE_ENABLE,

    // Unified Buffer
    input wire [MATRIX_WIDTH*8-1:0] BUFFER_WRITE_PORT,
    output wire [MATRIX_WIDTH*8-1:0] BUFFER_READ_PORT,
    input wire [15:0] BUFFER_ADDRESS,
    input wire BUFFER_ENABLE,
    input wire [MATRIX_WIDTH-1:0] BUFFER_WRITE_ENABLE,

    // Instructions
    input wire [95:0] INSTRUCTION_PORT,
    input wire INSTRUCTION_ENABLE,
    
    output wire BUSY,
    output wire SYNCHRONIZE
);

    // Internal signals
    wire [MATRIX_WIDTH*8-1:0] weight_read_port;
    wire [MATRIX_WIDTH*8-1:0] buffer_read_port_internal;
    wire [MATRIX_WIDTH*8-1:0] systolic_output;
    wire [MATRIX_WIDTH*16-1:0] mmu_result_data;
    wire [MATRIX_WIDTH*16-1:0] activation_output;
    wire [95:0] instruction_output;
    wire instruction_ready;
    wire instruction_busy;
    wire synchronize_internal;

    wire weight_busy, matrix_busy, activation_busy;
    wire weight_resource_busy, matrix_resource_busy, activation_resource_busy;

    // Control signals
    wire [1:0] activation_function;
    wire activation_signed;
    wire [7:0] mmu_weight_address;
    wire mmu_weight_signed;
    wire mmu_systolic_signed;
    wire mmu_activate_weight;
    wire mmu_load_weight;
    wire reg_accumulate;
    wire [31:0] reg_write_address, reg_read_address;
    wire reg_write_en;

    // Weight Buffer instantiation
// ????
    reg [15:0] WEIGHT_ADDRESS0;
    reg WEIGHT_EN0;
    reg WEIGHT_WRITE_EN0;
    reg [MATRIX_WIDTH*8-1:0] WEIGHT_WRITE_PORT0;
    wire [MATRIX_WIDTH*8-1:0] WEIGHT_READ_PORT0;
    
    reg [15:0] WEIGHT_ADDRESS1;
    reg WEIGHT_EN1;
    reg [MATRIX_WIDTH-1:0] WEIGHT_WRITE_EN1;
    reg [MATRIX_WIDTH*8-1:0] WEIGHT_WRITE_PORT1;
    wire [MATRIX_WIDTH*8-1:0] WEIGHT_READ_PORT1;
    
    // WEIGHT_BUFFER ???
    WEIGHT_BUFFER #(
        .MATRIX_WIDTH(14),
        .TILE_WIDTH(32768),
        .BYTE_WIDTH(8)
    ) weight_buffer_inst (
        .CLK(CLK),                    // ????
        .RESET(RESET),              // ???????????
        .ENABLE(WEIGHT_ENABLE),              // ?????
    
        // Port 0
        .ADDRESS0(WEIGHT_ADDRESS0),          // ??0??
        .EN0(WEIGHT_EN0),                    // ??0??
        .WRITE_EN0(WEIGHT_WRITE_EN0),        // ??0???
        .WRITE_PORT0(WEIGHT_WRITE_PORT0),    // ??0???
        .READ_PORT0(WEIGHT_READ_PORT0),      // ??0???
    
        // Port 1
        .ADDRESS1(WEIGHT_ADDRESS1),          // ??1??
        .EN1(WEIGHT_EN1),                    // ??1??
        .WRITE_EN1(WEIGHT_WRITE_EN1),        // ??1??????
        .WRITE_PORT1(WEIGHT_WRITE_PORT1),    // ??1???
        .READ_PORT1(WEIGHT_READ_PORT1)       // ??1???
    );


    // Unified Buffer instantiation
   // ????
    reg [31:0] BUFFER_ADDRESS0;
    reg BUFFER_EN0;
    wire [MATRIX_WIDTH*8-1:0] BUFFER_READ_PORT0;
    
    reg [31:0] BUFFER_ADDRESS1;
    reg [MATRIX_WIDTH*8-1:0] BUFFER_WRITE_PORT1;
    reg BUFFER_WRITE_EN1;
    
    // Master Port ??
    reg [31:0] MASTER_BUFFER_ADDRESS;
    reg MASTER_BUFFER_EN;
    reg [MATRIX_WIDTH-1:0] MASTER_WRITE_EN;
    reg [MATRIX_WIDTH*8-1:0] MASTER_WRITE_PORT;
    wire [MATRIX_WIDTH*8-1:0] MASTER_READ_PORT;
    
    // UNIFIED_BUFFER ?????
    UNIFIED_BUFFER #(
        .MATRIX_WIDTH(14),
        .TILE_WIDTH(4096)
    ) unified_buffer_inst (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
    
        // Master port
        .MASTER_ADDRESS(MASTER_BUFFER_ADDRESS),
        .MASTER_EN(MASTER_BUFFER_EN),
        .MASTER_WRITE_EN(MASTER_WRITE_EN),
        .MASTER_WRITE_PORT(MASTER_WRITE_PORT),
        .MASTER_READ_PORT(MASTER_READ_PORT),
    
        // Port 0
        .ADDRESS0(BUFFER_ADDRESS0),
        .EN0(BUFFER_EN0),
        .READ_PORT0(BUFFER_READ_PORT0),
    
        // Port 1
        .ADDRESS1(BUFFER_ADDRESS1),
        .EN1(BUFFER_WRITE_EN1),
        .WRITE_EN1(BUFFER_WRITE_EN1),
        .WRITE_PORT1(BUFFER_WRITE_PORT1)
    );

    assign BUFFER_READ_PORT = buffer_read_port_internal;

    // Systolic Data Setup instantiation
// ????
    reg [MATRIX_WIDTH*8-1:0] DATA_INPUT;
    wire [MATRIX_WIDTH*8-1:0] SDS_SYSTOLIC_OUTPUT;
    
    // SYSTOLIC_DATA_SETUP ?????
    SYSTOLIC_DATA_SETUP #(
        .MATRIX_WIDTH(14)
    ) systolic_data_setup_inst (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .DATA_INPUT(DATA_INPUT),
        .SYSTOLIC_OUTPUT(SDS_SYSTOLIC_OUTPUT)
    );


    // Matrix Multiply Unit instantiation
    MATRIX_MULTIPLY_UNIT #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) matrix_multiply_unit (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .WEIGHT_DATA(weight_read_port),
        .WEIGHT_SIGNED(mmu_weight_signed),
        .SYSTOLIC_DATA(systolic_output),
        .SYSTOLIC_SIGNED(mmu_systolic_signed),
        .ACTIVATE_WEIGHT(mmu_activate_weight),
        .LOAD_WEIGHT(mmu_load_weight),
        .WEIGHT_ADDRESS(mmu_weight_address),
        .RESULT_DATA(mmu_result_data)
    );

    // Register File instantiation
    REGISTER_FILE #(
        .MATRIX_WIDTH(MATRIX_WIDTH),
        .REGISTER_DEPTH(512)
    ) register_file (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .WRITE_ADDRESS(reg_write_address),
        .WRITE_PORT(mmu_result_data),
        .WRITE_ENABLE(reg_write_en),
        .ACCUMULATE(reg_accumulate),
        .READ_ADDRESS(reg_read_address),
        .READ_PORT(activation_output)
    );

    // Activation instantiation
    ACTIVATION #(
        .MATRIX_WIDTH(MATRIX_WIDTH)
    ) activation (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .ACTIVATION_FUNCTION(activation_function),
        .SIGNED_NOT_UNSIGNED(activation_signed),
        .ACTIVATION_INPUT(activation_output),
        .ACTIVATION_OUTPUT(BUFFER_WRITE_PORT)
    );

    // Weight Control instantiation
    WEIGHT_CONTROL weight_control (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .INSTRUCTION_OP_CODE(instruction_output),
        .INSTRUCTION_EN(instruction_ready),
        .WEIGHT_READ_EN(weight_busy),
        .WEIGHT_BUFFER_ADDRESS(WEIGHT_ADDRESS),
        .LOAD_WEIGHT(mmu_load_weight),
        .WEIGHT_ADDRESS(mmu_weight_address),
        .WEIGHT_SIGNED(mmu_weight_signed),
        .BUSY(weight_busy),
        .RESOURCE_BUSY(weight_resource_busy)
    );

    // Matrix Multiply Control instantiation
    MATRIX_MULTIPLY_CONTROL matrix_control (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .INSTRUCTION_OP_CODE(instruction_output),
        .INSTRUCTION_EN(instruction_ready),
        .BUF_READ_EN(matrix_busy),
        .MMU_SDS_EN(mmu_systolic_signed),
        .ACTIVATE_WEIGHT(mmu_activate_weight),
        .ACC_ADDR(reg_write_address),
        .ACCUMULATE(reg_accumulate),
        .ACC_ENABLE(reg_write_en),
        .BUSY(matrix_busy),
        .RESOURCE_BUSY(matrix_resource_busy)
    );

    // Activation Control instantiation
    ACTIVATION_CONTROL activation_control (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .INSTRUCTION_OP_CODE(instruction_output),
        .INSTRUCTION_EN(instruction_ready),
        .ACC_TO_ACT_ADDR(reg_read_address),
        .ACTIVATION_FUNCTION(activation_function),
        .SIGNED_NOT_UNSIGNED(activation_signed),
        .BUSY(activation_busy),
        .RESOURCE_BUSY(activation_resource_busy)
    );

    // Look Ahead Buffer instantiation
    LOOK_AHEAD_BUFFER look_ahead_buffer (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .INSTRUCTION_INPUT(INSTRUCTION_PORT),
        .INSTRUCTION_WRITE(INSTRUCTION_ENABLE),
        .INSTRUCTION_OUTPUT(instruction_output),
        .INSTRUCTION_READ(instruction_ready),
        .INSTRUCTION_BUSY(instruction_busy)
    );

    // Control Coordinator instantiation
    CONTROL_COORDINATOR control_coordinator (
        .CLK(CLK),
        .RESET(RESET),
        .ENABLE(ENABLE),
        .INSTRUCTION(instruction_output),
        .INSTRUCTION_EN(instruction_ready),
        .WEIGHT_BUSY(weight_busy),
        .WEIGHT_RESOURCE_BUSY(weight_resource_busy),
        .MATRIX_BUSY(matrix_busy),
        .MATRIX_RESOURCE_BUSY(matrix_resource_busy),
        .ACTIVATION_BUSY(activation_busy),
        .ACTIVATION_RESOURCE_BUSY(activation_resource_busy),
        .BUSY(BUSY),
        .SYNCHRONIZE(SYNCHRONIZE)
    );

endmodule
