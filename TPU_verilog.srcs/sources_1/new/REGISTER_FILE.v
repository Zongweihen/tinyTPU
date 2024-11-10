module REGISTER_FILE #(
    parameter MATRIX_WIDTH = 14,
    parameter REGISTER_DEPTH = 512,
    parameter BYTE_WIDTH = 8  // Define BYTE_WIDTH as per requirement
)(
    input wire CLK,
    input wire RESET,
    input wire ENABLE,
    
    input wire [31:0] WRITE_ADDRESS,  
    input wire [(MATRIX_WIDTH*2*BYTE_WIDTH)-1:0] WRITE_PORT,
    input wire WRITE_ENABLE,
    input wire ACCUMULATE,
    
    input wire [31:0] READ_ADDRESS,  
    output reg [(MATRIX_WIDTH*2*BYTE_WIDTH)-1:0] READ_PORT
);

    // Define accumulators
    reg [(MATRIX_WIDTH*4*BYTE_WIDTH)-1:0] ACCUMULATORS [0:REGISTER_DEPTH-1];
    reg [(MATRIX_WIDTH*4*BYTE_WIDTH)-1:0] ACCUMULATORS_COPY [0:REGISTER_DEPTH-1];

    // Define DSP ports
    reg [(MATRIX_WIDTH*4*BYTE_WIDTH)-1:0] DSP_ADD_PORT0, DSP_ADD_PORT1, DSP_RESULT_PORT;
    reg [(MATRIX_WIDTH*4*BYTE_WIDTH)-1:0] ACCUMULATE_PORT_PIPE0, ACCUMULATE_PORT_PIPE1;

    // Define shift registers for pipeline control
    reg [2:0] ACCUMULATE_PIPE;
    reg [(MATRIX_WIDTH*4*BYTE_WIDTH)-1:0] WRITE_PORT_PIPE [0:2];
    reg [5:0] WRITE_ENABLE_PIPE;
    reg [31:0] WRITE_ADDRESS_PIPE [0:5];
    reg [31:0] READ_ADDRESS_PIPE [0:5];

    wire [(MATRIX_WIDTH*4*BYTE_WIDTH)-1:0] ACC_WRITE_PORT = DSP_RESULT_PORT;

    // Sequential logic for processing
    always @(posedge CLK) begin
        if (RESET) begin
            DSP_ADD_PORT0 <= 0;
            DSP_ADD_PORT1 <= 0;
            DSP_RESULT_PORT <= 0;
            ACCUMULATE_PORT_PIPE0 <= 0;
            ACCUMULATE_PORT_PIPE1 <= 0;
            ACCUMULATE_PIPE <= 0;
            WRITE_ENABLE_PIPE <= 0;
        end else if (ENABLE) begin
            // DSP operations
            DSP_ADD_PORT0 <= WRITE_PORT_PIPE[2];
            DSP_ADD_PORT1 <= (ACCUMULATE_PIPE[2]) ? ACCUMULATE_PORT_PIPE1 : 0;
            DSP_RESULT_PORT <= DSP_ADD_PORT0 + DSP_ADD_PORT1;

            // Accumulate pipeline
            ACCUMULATE_PORT_PIPE0 <= ACCUMULATORS_COPY[WRITE_ADDRESS];
            ACCUMULATE_PORT_PIPE1 <= ACCUMULATE_PORT_PIPE0;

            // Update pipes
            ACCUMULATE_PIPE <= {ACCUMULATE_PIPE[1:0], ACCUMULATE};
            
            WRITE_PORT_PIPE[0] <= WRITE_PORT;
            WRITE_PORT_PIPE[1] <= WRITE_PORT_PIPE[0];
            WRITE_PORT_PIPE[2] <= WRITE_PORT_PIPE[1];
            
            WRITE_ENABLE_PIPE <= {WRITE_ENABLE_PIPE[4:0], WRITE_ENABLE};
            WRITE_ADDRESS_PIPE[0] <= WRITE_ADDRESS;
            WRITE_ADDRESS_PIPE[1] <= WRITE_ADDRESS_PIPE[0];
            WRITE_ADDRESS_PIPE[2] <= WRITE_ADDRESS_PIPE[1];
            WRITE_ADDRESS_PIPE[3] <= WRITE_ADDRESS_PIPE[2];
            WRITE_ADDRESS_PIPE[4] <= WRITE_ADDRESS_PIPE[3];
            WRITE_ADDRESS_PIPE[5] <= WRITE_ADDRESS_PIPE[4];
            
            READ_ADDRESS_PIPE[0] <= READ_ADDRESS;
            READ_ADDRESS_PIPE[1] <= READ_ADDRESS_PIPE[0];
            READ_ADDRESS_PIPE[2] <= READ_ADDRESS_PIPE[1];
            READ_ADDRESS_PIPE[3] <= READ_ADDRESS_PIPE[2];
            READ_ADDRESS_PIPE[4] <= READ_ADDRESS_PIPE[3];
            READ_ADDRESS_PIPE[5] <= READ_ADDRESS_PIPE[4];

            // Write operation
            if (WRITE_ENABLE_PIPE[5]) begin
                ACCUMULATORS[WRITE_ADDRESS_PIPE[5]] <= ACC_WRITE_PORT;
                ACCUMULATORS_COPY[WRITE_ADDRESS_PIPE[5]] <= ACC_WRITE_PORT;
            end

            // Read operation
            READ_PORT <= ACCUMULATORS[READ_ADDRESS_PIPE[5]];
        end
    end
endmodule