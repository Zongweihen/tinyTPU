module tinyTPU_V_v1_0_S00_AXI #(
    parameter integer MATRIX_WIDTH = 14,
    parameter integer WEIGHT_BUFFER_DEPTH = 32768,
    parameter integer UNIFIED_BUFFER_DEPTH = 4096,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 20
)(
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,

    // AXI Slave Interface
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire S_AXI_AWVALID,
    output reg S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output reg S_AXI_WREADY,
    output reg [1:0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output reg [1:0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY,
    output wire SYNCHRONIZE
);

// FSM States
localparam IDLE = 3'b000;
localparam WRITE_DATA = 3'b001;
localparam WRITE_RESPONSE = 3'b010;
localparam READ_DATA = 3'b011;
localparam READ_RESPONSE = 3'b100;

// Internal registers and wires
reg [2:0] state_cs, state_ns;
reg [19:0] write_address, read_address;
reg [31:0] write_data;
reg [31:0] read_data;
reg [31:0] lower_instruction_word, middle_instruction_word;
reg [15:0] upper_instruction_word;
reg [2:0] instruction_write_en;
wire synchronize_internal;


// Flattened buffers for TPU
wire [8*MATRIX_WIDTH-1:0] tpu_weight_data;
reg [8*MATRIX_WIDTH-1:0] tpu_weight_data_reg;
wire [8*MATRIX_WIDTH-1:0] tpu_buffer_data;
reg [8*MATRIX_WIDTH-1:0] tpu_buffer_data_reg;
wire [8*MATRIX_WIDTH-1:0] buffer_read_port;
reg [MATRIX_WIDTH-1:0] weight_write_enable;
reg [MATRIX_WIDTH-1:0] buffer_write_enable;
reg tpu_weight_enable, tpu_buffer_enable;
reg [15:0] tpu_weight_addr, tpu_buffer_addr;

//assign SYNCHRONIZE = synchronize_internal;
assign tpu_weight_data = tpu_weight_data_reg;
assign tpu_buffer_data = tpu_buffer_data_reg;

wire [31:0] runtime_count;
// TPU Instance
TPU #(
    .MATRIX_WIDTH(MATRIX_WIDTH),
    .WEIGHT_BUFFER_DEPTH(WEIGHT_BUFFER_DEPTH),
    .UNIFIED_BUFFER_DEPTH(UNIFIED_BUFFER_DEPTH)
) tpu_inst (
    .CLK(S_AXI_ACLK),
    .RESET(~S_AXI_ARESETN),
    .ENABLE(1'b1),
    .RUNTIME_COUNT(runtime_count),
    .LOWER_INSTRUCTION_WORD(lower_instruction_word),
    .MIDDLE_INSTRUCTION_WORD(middle_instruction_word),
    .UPPER_INSTRUCTION_WORD(upper_instruction_word),
    .INSTRUCTION_WRITE_EN(instruction_write_en),
    .WEIGHT_WRITE_PORT(tpu_weight_data),
    .WEIGHT_ADDRESS(tpu_weight_addr),
    .WEIGHT_ENABLE(tpu_weight_enable),
    .WEIGHT_WRITE_ENABLE(weight_write_enable),
    .BUFFER_WRITE_PORT(tpu_buffer_data),
    .BUFFER_READ_PORT(buffer_read_port),
    .BUFFER_ADDRESS(tpu_buffer_addr),
    .BUFFER_ENABLE(tpu_buffer_enable),
    .BUFFER_WRITE_ENABLE(buffer_write_enable),
    .SYNCHRONIZE(SYNCHRONIZE)
);

// AXI Write Logic
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        state_cs <= IDLE;
    end else begin
        state_cs <= state_ns;
    end
end

always @(*) begin
    // Default assignments
    S_AXI_AWREADY = 0;
    S_AXI_ARREADY = 0;
    S_AXI_WREADY = 0;
    S_AXI_BVALID = 0;
    S_AXI_RVALID = 0;
    S_AXI_BRESP = 2'b00;
    S_AXI_RRESP = 2'b00;
    state_ns = state_cs;
    
    case (state_cs)
        IDLE: begin
            if (S_AXI_AWVALID) begin
                S_AXI_AWREADY = 1;
                state_ns = WRITE_DATA;
            end else if (S_AXI_ARVALID) begin
                S_AXI_ARREADY = 1;
                state_ns = READ_DATA;
            end
        end

        WRITE_DATA: begin
            if (S_AXI_WVALID) begin
                S_AXI_WREADY = 1;
                write_data = S_AXI_WDATA;
                write_address = S_AXI_AWADDR;

                // ??????
                if (write_address[19] == 0) begin
                    tpu_weight_enable = 1;
                    tpu_weight_addr = write_address[15:0];
                    tpu_weight_data_reg = {8{write_data[7:0]}};
                end else begin
                    tpu_buffer_enable = 1;
                    tpu_buffer_addr = write_address[15:0];
                    tpu_buffer_data_reg = {8{write_data[7:0]}};
                end

                state_ns = WRITE_RESPONSE;
            end
        end

        WRITE_RESPONSE: begin
            S_AXI_BVALID = 1;
            if (S_AXI_BREADY) begin
                state_ns = IDLE;
            end
        end

        READ_DATA: begin
            if (read_address[19] == 1) begin
                S_AXI_RDATA = buffer_read_port[31:0];
            end else begin
                S_AXI_RDATA = 32'hDEADBEEF;
            end
            S_AXI_RVALID = 1;
            state_ns = READ_RESPONSE;
        end

        READ_RESPONSE: begin
            if (S_AXI_RREADY) begin
                state_ns = IDLE;
            end
        end

        default: state_ns = IDLE;
    endcase
end
endmodule
