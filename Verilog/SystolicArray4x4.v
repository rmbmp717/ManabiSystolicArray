`timescale 1ns / 1ps

module SystolicArray4x4 (
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals (shared across all PEs)
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    // B register input (1D array from external sources)
    input  wire [15:0]  b_reg_array_flat [0:15], // Flattened 1D array (4x4 = 16 elements)
    input  wire         b_we_array_flat  [0:15], // Flattened 1D array (4x4 = 16 elements)

    // External connections for A and partial_sum (1D arrays)
    input  wire [15:0]  a_left_in_flat   [0:3],  // Input A from the left (4 elements)
    input  wire [15:0]  ps_top_in_flat   [0:3],  // Input partial_sum from the top (4 elements)
    
    // Outputs for the final results (1D array)
    output wire [15:0]  ps_bottom_out_flat [0:3] // Bottom partial_sum outputs (4 elements)
);

    //========================================================
    // Internal 2D arrays (B, WE, A, partial_sum)
    //========================================================
    wire [15:0] b_reg_array [0:3][0:3];
    wire        b_we_array  [0:3][0:3];
    wire [15:0] a_left_in   [0:3];
    wire [15:0] ps_top_in   [0:3];
    wire [15:0] ps_bottom_out [0:3];

    //========================================================
    // Systolic internal wiring (A shifts right, partial_sum shifts down)
    //========================================================
    wire [15:0] a_wire [0:3][0:4];  // Horizontal wiring (4 rows x 5 columns)
    wire [15:0] ps_wire [0:4][0:3]; // Vertical wiring (5 rows x 4 columns)

    //========================================================
    // Intermediate wiring: a_in and ps_in to pass to each PE (4x4 dimensions)
    //========================================================
    wire [15:0] a_in_val [0:3][0:3];
    wire [15:0] ps_in_val[0:3][0:3];

    //========================================================
    // Mapping 1D arrays to 2D arrays (B, A, partial_sum inputs)
    //========================================================
    genvar i, j;

    // Mapping B registers and WE signals
    generate
        for (i = 0; i < 4; i = i + 1) begin : MAP_B_REG
            for (j = 0; j < 4; j = j + 1) begin : MAP_B_REG_COL
                assign b_reg_array[i][j] = b_reg_array_flat[i * 4 + j];
                assign b_we_array[i][j]  = b_we_array_flat[i * 4 + j];
            end
        end
    endgenerate

    // Mapping A inputs from the left
    generate
        for (i = 0; i < 4; i = i + 1) begin : MAP_A_LEFT
            assign a_left_in[i] = a_left_in_flat[i];
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
                    .Clock          (Clock),
                    .rst_n          (rst_n),

                    // Control signals
                    .data_clear     (data_clear),
                    .en_shift_right (en_shift_right),
                    .en_shift_bottom(en_shift_bottom),

                    // B inputs
                    .b_reg          (b_reg_array[r][c]),
                    .b_we           (b_we_array[r][c]),

                    // A / partial_sum inputs
                    .a_in           (a_in_val[r][c]),   // No ternary operator!
                    .ps_in          (ps_in_val[r][c]),  // No ternary operator!

                    // Outputs
                    .a_shift_to_right      (a_wire[r][c]),
                    .partial_sum_to_bottom (ps_wire[r][c])
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
