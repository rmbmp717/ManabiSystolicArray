
`timescale 1ns / 1ps

module SystolicArray4x4 (
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals (shared across all PEs)
    input  wire         data_clear,
    input  wire         en_b_shift_bottom,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    // External connections for A and partial_sum (1D arrays)
    input  wire [15:0]  a_left_in_flat   [0:3],  // Input A from the left (4 elements)
    input  wire [15:0]  b_top_in_flat    [0:3], 
    input  wire [15:0]  ps_top_in_flat   [0:3],  // Input partial_sum from the top (4 elements)
    
    // Outputs for the final results (1D array)
    output wire [15:0]  ps_bottom_out_flat [0:3] // Bottom partial_sum outputs (4 elements)
);

    //========================================================
    // Internal 2D arrays (B, WE, A, partial_sum)
    //========================================================
    wire [15:0] a_left_in   [0:3];
    wire [15:0] b_top_in    [0:3];
    wire [15:0] ps_top_in   [0:3];
    wire [15:0] ps_bottom_out [0:3];

    //========================================================
    // Systolic internal wiring (A shifts right, partial_sum shifts down)
    //========================================================
    wire [15:0] a_wire [0:3][0:4];  // Horizontal wiring (4 rows x 5 columns)
    wire [15:0] b_wire [0:4][0:3];  // Horizontal wiring (4 rows x 5 columns)
    wire [15:0] ps_wire [0:4][0:3]; // Vertical wiring (5 rows x 4 columns)

    //========================================================
    // Intermediate wiring: a_in and ps_in to pass to each PE (4x4 dimensions)
    //========================================================
    wire [15:0] a_in_val [0:3][0:3];
    wire [15:0] b_in_val [0:3][0:3];
    wire [15:0] ps_in_val[0:3][0:3];

    //========================================================
    // Mapping 1D arrays to 2D arrays (B, A, partial_sum inputs)
    //========================================================
    genvar i, j;

    // Mapping A inputs from the left
    generate
        for (i = 0; i < 4; i = i + 1) begin : MAP_A_LEFT
            assign a_left_in[i] = a_left_in_flat[i];
        end
    endgenerate

    // Mapping B inputs from the top
    generate
        for (i = 0; i < 4; i = i + 1) begin : MAP_B_TOP
            assign b_top_in[i] = b_top_in_flat[i];
        end
    endgenerate

    // Mapping partial_sum inputs from the top
    generate
        for (j = 0; j < 4; j = j + 1) begin : MAP_PS_TOP
            assign ps_top_in[j] = ps_top_in_flat[j];
        end
    endgenerate

    // Mapping bottom partial_sum outputs
    generate
        for (j = 0; j < 4; j = j + 1) begin : MAP_PS_BOTTOM
            assign ps_bottom_out_flat[j] = ps_bottom_out[j];
        end
    endgenerate

    //========================================================
    // Conditional wiring for a_in_val and ps_in_val
    // Passing connections to each PE without negative indices
    //========================================================
    generate
        for (i = 0; i < 4; i = i + 1) begin : AIN_GEN
            for (j = 0; j < 4; j = j + 1) begin : AIN_GEN_COL
                // a_in_val[i][j]
                if (j == 0) begin
                    // First column → a_left_in[i]
                    assign a_in_val[i][j] = a_left_in[i];
                end else begin
                    // Others → a_wire[i][j-1]
                    assign a_in_val[i][j] = a_wire[i][j-1];
                end
            end
        end
    endgenerate

    generate
        for (i = 0; i < 4; i = i + 1) begin : BIN_GEN
            for (j = 0; j < 4; j = j + 1) begin : BIN_GEN_COL
                // b_in_val[i][j]
                if (i == 0) begin
                    // First column → a_left_in[i]
                    assign b_in_val[i][j] = b_top_in[j];
                end else begin
                    // Others → a_wire[i][j-1]
                    assign b_in_val[i][j] = b_wire[i-1][j];
                end
            end
        end
    endgenerate

    generate
        for (i = 0; i < 4; i = i + 1) begin : PSIN_GEN
            for (j = 0; j < 4; j = j + 1) begin : PSIN_GEN_COL
                // ps_in_val[i][j]
                if (i == 0) begin
                    // First row → ps_top_in[j]
                    assign ps_in_val[i][j] = ps_top_in[j];
                end else begin
                    // Others → ps_wire[i-1][j]
                    assign ps_in_val[i][j] = ps_wire[i-1][j];
                end
            end
        end
    endgenerate

    //========================================================
    // PE array instances (4x4)
    //========================================================
    genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin: ROW_BLOCK
            for (c = 0; c < 4; c = c + 1) begin: COL_BLOCK

                PE u_pe (
                    // Clock & Reset
                    .Clock                  (Clock),
                    .rst_n                  (rst_n),

                    // Control signals
                    .data_clear             (data_clear),
                    .en_shift_right         (en_shift_right),
                    .en_b_shift_bottom      (en_b_shift_bottom),
                    .en_shift_bottom        (en_shift_bottom),

                    // B inputs
                    .b_in                   (b_in_val[r][c]),

                    // A / partial_sum inputs
                    .a_in                   (a_in_val[r][c]),   // No ternary operator!
                    .ps_in                  (ps_in_val[r][c]),  // No ternary operator!

                    // Outputs
                    .a_shift_to_right       (a_wire[r][c]),
                    .b_shift_to_bottom      (b_wire[r][c]),
                    .partial_sum_to_bottom  (ps_wire[r][c])
                );

            end
        end
    endgenerate

    //========================================================
    // Bottom row partial_sum → ps_bottom_out
    //========================================================
    generate
        for (c = 0; c < 4; c = c + 1) begin : FINAL_PS
            assign ps_bottom_out[c] = ps_wire[3][c];
        end
    endgenerate

endmodule

//========================================================
// Sub PE
//========================================================
module PE (
    // Clock & Reset
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals
    input  wire         data_clear,
    input  wire         en_b_shift_bottom,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,
    
    // B input
    input  wire [15:0]  b_in,

    // A / partial sum from left / top
    input  wire [15:0]  a_in,
    input  wire [15:0]  ps_in,

    // Output
    output wire [15:0]  a_shift_to_right,
    output wire [15:0]  b_shift_to_bottom,
    output wire [15:0]  partial_sum_to_bottom
);

    //========================================================
    // Internal Registers
    //========================================================
    reg [15:0] b_reg;                  // Register to hold B value
    reg [15:0] a_reg;                  // Register to hold A value
    reg [15:0] ps_reg;                 // Register to hold partial_sum

    // Registers for 5-stage pipeline (Assumes 1 multiplier takes 5 cycles to execute)
    reg [15:0] mul_pipe [0:4];         // mul_pipe[0] receives the initial input
    wire [15:0] mul_input;             // Multiplier input (A * B)
    reg [15:0] mul_result;             // Multiplier output (final result from 5th stage)

    //========================================================
    // B Register Write
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            b_reg <= 16'd0;
        end else if (en_b_shift_bottom) begin
            b_reg <= b_in;
        end 
    end

    // Output: Pass b_reg to the right neighbor
    assign b_shift_to_bottom = b_reg;

    //========================================================
    // A Register & Shift (Right Shift)
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'd0;
        end else if (data_clear) begin
            a_reg <= 16'd0;
        end else if (en_shift_right) begin
            // Load a_in from the left into the current register
            a_reg <= a_in;
        end
    end

    // Output: Pass a_reg to the right neighbor
    assign a_shift_to_right = a_reg;

    //========================================================
    // 5-stage Multiply Pipeline
    //========================================================
    assign mul_input = a_reg * b_reg; // In practice, consider synthesis constraints such as multi-cycle

    integer i;
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 5; i=i+1) begin
                mul_pipe[i] <= 16'd0;
            end
        end else if (data_clear) begin
            for (i = 0; i < 5; i=i+1) begin
                mul_pipe[i] <= 16'd0;
            end
        end else begin
            // Shift register structure
            mul_pipe[0] <= mul_input;       // Stage 1
            mul_pipe[1] <= mul_pipe[0];    // Stage 2
            mul_pipe[2] <= mul_pipe[1];    // Stage 3
            mul_pipe[3] <= mul_pipe[2];    // Stage 4
            mul_pipe[4] <= mul_pipe[3];    // Stage 5
        end
    end

    // Final stage of the multiplier result
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            mul_result <= 16'd0;
        end else if (data_clear) begin
            mul_result <= 16'd0;
        end else begin
            mul_result <= mul_pipe[4];
        end
    end

    //========================================================
    // partial_sum Register & Shift (Downward Shift)
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            ps_reg <= 16'd0;
        end else if (data_clear) begin
            ps_reg <= 16'd0;
        end else if (en_shift_bottom) begin
            // Add ps_in from above and the current mul_result
            // ps_reg = current ps_reg + ps_in + mul_result, depending on requirements
            ps_reg <= ps_in + mul_result;
        end
    end

    // Output: Pass partial_sum to the lower neighbor
    assign partial_sum_to_bottom = ps_reg;

endmodule