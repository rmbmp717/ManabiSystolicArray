`timescale 1ns / 1ps

module SystolicArrayNxN (
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals (shared across all PEs)
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    // B register input (1D array from external sources)
    // → 8x8 = 64要素
    input  wire [15:0]  b_reg_array_flat [0:63],
    input  wire         b_we_array_flat  [0:63],

    // External connections for A and partial_sum (1D arrays)
    // → A: 8要素, partial_sum: 8要素
    input  wire [15:0]  a_left_in_flat   [0:7],  
    //input  wire [15:0]  ps_top_in_flat   [0:7],  
    
    // Outputs for the final results (1D array)
    // → 8要素
    output wire [15:0]  ps_bottom_out_flat [0:7] 
);

    //========================================================
    // Internal 2D arrays (B, WE, A, partial_sum)
    //========================================================
    // 8x8 の B・WE 配列
    wire [15:0] b_reg_array [0:7][0:7];
    wire        b_we_array  [0:7][0:7];

    // A入力・PS入力/出力 (8要素)
    wire [15:0] a_left_in    [0:7];
    wire [15:0] ps_top_in    [0:7];
    wire [15:0] ps_bottom_out[0:7];

    //========================================================
    // Systolic internal wiring (A shifts right, partial_sum shifts down)
    //========================================================
    // A は「横方向」へシフト → 8行 × (8+1=9列)
    wire [15:0] a_wire [0:7][0:8];  

    // PS は「縦方向」へシフト → (8+1=9行) × 8列
    wire [15:0] ps_wire [0:8][0:7]; 

    //========================================================
    // Intermediate wiring: a_in and ps_in to pass to each PE (8x8 dimensions)
    //========================================================
    wire [15:0] a_in_val [0:7][0:7];
    wire [15:0] ps_in_val[0:7][0:7];

    //========================================================
    // Mapping 1D arrays to 2D arrays (B, A, partial_sum inputs)
    //========================================================
    genvar i, j;

    //-----------------------------
    // Mapping B registers and WE signals
    // b_reg_array_flat[i*8 + j] → b_reg_array[i][j]
    //-----------------------------
    generate
        for (i = 0; i < 8; i = i + 1) begin : MAP_B_REG
            for (j = 0; j < 8; j = j + 1) begin : MAP_B_REG_COL
                assign b_reg_array[i][j] = b_reg_array_flat[i * 8 + j];
                assign b_we_array[i][j]  = b_we_array_flat [i * 8 + j];
            end
        end
    endgenerate

    //-----------------------------
    // Mapping A inputs from the left (8要素)
    //-----------------------------
    generate
        for (i = 0; i < 8; i = i + 1) begin : MAP_A_LEFT
            assign a_left_in[i] = a_left_in_flat[i];
        end
    endgenerate

    //-----------------------------
    // Mapping partial_sum inputs from the top (8要素)
    //-----------------------------
    generate
        for (j = 0; j < 8; j = j + 1) begin : MAP_PS_TOP
            //assign ps_top_in[j] = ps_top_in_flat[j];
            assign ps_top_in[j] = 16'd0;
        end
    endgenerate

    //-----------------------------
    // Mapping bottom partial_sum outputs (8要素)
    //-----------------------------
    generate
        for (j = 0; j < 8; j = j + 1) begin : MAP_PS_BOTTOM
            assign ps_bottom_out_flat[j] = ps_bottom_out[j];
        end
    endgenerate

    //========================================================
    // Conditional wiring for a_in_val and ps_in_val
    // Passing connections to each PE without negative indices
    //========================================================
    // a_in_val[i][j]:  j=0 → 左端の a_left_in[i],  それ以外 → a_wire[i][j-1]
    //--------------------------------------------------------
    generate
        for (i = 0; i < 8; i = i + 1) begin : AIN_GEN
            for (j = 0; j < 8; j = j + 1) begin : AIN_GEN_COL
                if (j == 0) begin
                    assign a_in_val[i][j] = a_left_in[i];
                end else begin
                    assign a_in_val[i][j] = a_wire[i][j-1];
                end
            end
        end
    endgenerate

    // ps_in_val[i][j]: i=0 → 上端の ps_top_in[j],  それ以外 → ps_wire[i-1][j]
    //--------------------------------------------------------
    generate
        for (i = 0; i < 8; i = i + 1) begin : PSIN_GEN
            for (j = 0; j < 8; j = j + 1) begin : PSIN_GEN_COL
                if (i == 0) begin
                    assign ps_in_val[i][j] = ps_top_in[j];
                end else begin
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
                    .a_in           (a_in_val[r][c]),
                    .ps_in          (ps_in_val[r][c]),

                    // Outputs
                    .a_shift_to_right      (a_wire[r][c]),
                    .partial_sum_to_bottom (ps_wire[r][c])
                );

            end
        end
    endgenerate

    //========================================================
    // Bottom row partial_sum → ps_bottom_out (row=7)
    //========================================================
    generate
        for (c = 0; c < 8; c = c + 1) begin : FINAL_PS
            assign ps_bottom_out[c] = ps_wire[7][c];
        end
    endgenerate

endmodule


//========================================================
// Sub PE (処理要素)
//========================================================
module PE (
    // Clock & Reset
    input  wire         Clock,
    input  wire         rst_n,

    // Control signals
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,
    
    // B input
    input  wire [15:0]  b_reg,
    input  wire         b_we,

    // A / partial sum from left / top
    input  wire [15:0]  a_in,
    input  wire [15:0]  ps_in,

    // Output
    output wire [15:0]  a_shift_to_right,
    output wire [15:0]  partial_sum_to_bottom
);

    //========================================================
    // Internal Registers
    //========================================================
    reg [15:0] b_reg_internal;         // Register to hold B value
    reg [15:0] a_reg;                  // Register to hold A value
    reg [15:0] ps_reg;                 // Register to hold partial_sum

    // 5-stage multiply pipeline (例示)
    reg [15:0] mul_pipe [0:4];
    wire [15:0] mul_input;
    reg [15:0] mul_result;

    //========================================================
    // B Register Write
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            b_reg_internal <= 16'd0;
        end else if (b_we) begin
            b_reg_internal <= b_reg;
        end
    end

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
    assign mul_input = a_reg * b_reg_internal;

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
            mul_pipe[0] <= mul_input;    
            mul_pipe[1] <= mul_pipe[0]; 
            mul_pipe[2] <= mul_pipe[1]; 
            mul_pipe[3] <= mul_pipe[2]; 
            mul_pipe[4] <= mul_pipe[3]; 
        end
    end

    // 最終ステージを保持
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
            // 上からの入力ps_in + 自PEの結果mul_result を加算
            ps_reg <= ps_in + mul_result;
        end
    end

    // 下方向へ渡す
    assign partial_sum_to_bottom = ps_reg;

endmodule
