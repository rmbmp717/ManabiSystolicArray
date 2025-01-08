`timescale 1ns / 1ps

module SystolicArray8x8 (
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals (shared across all PEs)
    input  wire         data_clear,
    input  wire         en_b_shift_bottom,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    // External connections for A and partial_sum (1D arrays)
    input  wire [15:0]  a_left_in_flat   [0:7],  // Input A from the left (8 elements)
    input  wire [15:0]  b_top_in_flat    [0:7], 
    input  wire [15:0]  ps_top_in_flat   [0:7],  // Input partial_sum from the top (8 elements)
    
    // Outputs for the final results (1D array)
    output wire [15:0]  ps_bottom_out_flat [0:7] // Bottom partial_sum outputs (8 elements)
);

    //========================================================
    // Internal 2D arrays (B, WE, A, partial_sum)
    //========================================================
    wire [15:0] a_left_in   [0:7];
    wire [15:0] b_top_in    [0:7];
    wire [15:0] ps_top_in   [0:7];
    wire [15:0] ps_bottom_out [0:7];

    //========================================================
    // Systolic internal wiring (A shifts right, partial_sum shifts down)
    //========================================================
    wire [15:0] a_wire [0:7][0:8];  // Horizontal wiring (8 rows x 9 columns)
    wire [15:0] b_wire [0:8][0:7];  // Vertical wiring (9 rows x 8 columns)
    wire [15:0] ps_wire [0:8][0:7]; // Vertical wiring (9 rows x 8 columns)

    //========================================================
    // Intermediate wiring: a_in and ps_in to pass to each PE (8x8 dimensions)
    //========================================================
    wire [15:0] a_in_val [0:7][0:7];
    wire [15:0] b_in_val [0:7][0:7];
    wire [15:0] ps_in_val[0:7][0:7];

    //========================================================
    // Mapping 1D arrays to 2D arrays (B, A, partial_sum inputs)
    //========================================================
    genvar i, j;

    // Mapping A inputs from the left
    generate
        for (i = 0; i < 8; i = i + 1) begin : MAP_A_LEFT
            assign a_left_in[i] = a_left_in_flat[i];
        end
    endgenerate

    // Mapping B inputs from the top
    generate
        for (i = 0; i < 8; i = i + 1) begin : MAP_B_TOP
            assign b_top_in[i] = b_top_in_flat[i];
        end
    endgenerate

    // Mapping partial_sum inputs from the top
    generate
        for (j = 0; j < 8; j = j + 1) begin : MAP_PS_TOP
            assign ps_top_in[j] = ps_top_in_flat[j];
        end
    endgenerate

    // Mapping bottom partial_sum outputs
    generate
        for (j = 0; j < 8; j = j + 1) begin : MAP_PS_BOTTOM
            assign ps_bottom_out_flat[j] = ps_bottom_out[j];
        end
    endgenerate

    //========================================================
    // Conditional wiring for a_in_val and ps_in_val
    // Passing connections to each PE without negative indices
    //========================================================
    generate
        for (i = 0; i < 8; i = i + 1) begin : AIN_GEN
            for (j = 0; j < 8; j = j + 1) begin : AIN_GEN_COL
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
        for (i = 0; i < 8; i = i + 1) begin : BIN_GEN
            for (j = 0; j < 8; j = j + 1) begin : BIN_GEN_COL
                // b_in_val[i][j]
                if (i == 0) begin
                    // First row → b_top_in[j]
                    assign b_in_val[i][j] = b_top_in[j];
                end else begin
                    // Others → b_wire[i-1][j]
                    assign b_in_val[i][j] = b_wire[i-1][j];
                end
            end
        end
    endgenerate

    generate
        for (i = 0; i < 8; i = i + 1) begin : PSIN_GEN
            for (j = 0; j < 8; j = j + 1) begin : PSIN_GEN_COL
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
    // PE array instances (8x8)
    //========================================================
    genvar r, c;
    generate
        for (r = 0; r < 8; r = r + 1) begin: ROW_BLOCK
            for (c = 0; c < 8; c = c + 1) begin: COL_BLOCK

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
        for (c = 0; c < 8; c = c + 1) begin : FINAL_PS
            assign ps_bottom_out[c] = ps_wire[7][c];
        end
    endgenerate

endmodule
