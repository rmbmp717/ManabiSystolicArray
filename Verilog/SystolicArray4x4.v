`timescale 1ns / 1ps

module SystolicArray4x4 (
    input  wire         Clock,
    input  wire         rst_n,

    // 制御信号 (全PE共通)
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    // Bレジスタ書き込み用（1次元配列で外部から入力）
    input  wire [15:0]  b_reg_array_flat [0:15], // 16要素（4×4をフラット化）
    input  wire         b_we_array_flat  [0:15], // 16要素（4×4をフラット化）

    // Aおよびpartial_sumの外部接続例（1次元配列で入力）
    input  wire [15:0]  a_left_in_flat   [0:3],  // 左端から入れるA（4要素）
    input  wire [15:0]  ps_top_in_flat   [0:3],  // 上端から入れるpartial_sum（4要素）
    
    // 計算結果の取り出し (1次元配列で出力)
    output wire [15:0]  ps_bottom_out_flat [0:3] // 最下段のpartial_sum（4要素）
);

    //========================================================
    // 内部2次元配列 (B, WE, A, partial_sum)
    //========================================================
    wire [15:0] b_reg_array [0:3][0:3];
    wire        b_we_array  [0:3][0:3];
    wire [15:0] a_left_in   [0:3];
    wire [15:0] ps_top_in   [0:3];
    wire [15:0] ps_bottom_out [0:3];

    //========================================================
    // Systolic 内部配線 (A の右方向シフト, partial_sum の下方向シフト)
    //========================================================
    wire [15:0] a_wire [0:3][0:4];  // 横方向 (4行 × (4+1列))
    wire [15:0] ps_wire [0:4][0:3]; // 縦方向 ((4+1行) × 4列)

    //========================================================
    // 中間配線: PE に渡す直前の a_in, ps_in (次元: 4×4)
    //========================================================
    wire [15:0] a_in_val [0:3][0:3];
    wire [15:0] ps_in_val[0:3][0:3];

    //========================================================
    // 1次元配列を2次元配列にマッピング (B と A, partial_sum の外部入力)
    //========================================================
    genvar i, j;

    // Bレジスタと WE
    generate
        for (i = 0; i < 4; i = i + 1) begin : MAP_B_REG
            for (j = 0; j < 4; j = j + 1) begin : MAP_B_REG_COL
                assign b_reg_array[i][j] = b_reg_array_flat[i * 4 + j];
                assign b_we_array[i][j]  = b_we_array_flat[i * 4 + j];
            end
        end
    endgenerate

    // A左端
    generate
        for (i = 0; i < 4; i = i + 1) begin : MAP_A_LEFT
            assign a_left_in[i] = a_left_in_flat[i];
        end
    endgenerate

    // partial_sum上端
    generate
        for (j = 0; j < 4; j = j + 1) begin : MAP_PS_TOP
            assign ps_top_in[j] = ps_top_in_flat[j];
        end
    endgenerate

    // partial_sum最下端 (結果を外部へ)
    generate
        for (j = 0; j < 4; j = j + 1) begin : MAP_PS_BOTTOM
            assign ps_bottom_out_flat[j] = ps_bottom_out[j];
        end
    endgenerate

    //========================================================
    // a_in_val, ps_in_val に条件分岐で代入し
    // PEへ負のインデックスを含まない配線を渡す
    //========================================================
    generate
        for (i = 0; i < 4; i = i + 1) begin : AIN_GEN
            for (j = 0; j < 4; j = j + 1) begin : AIN_GEN_COL
                // a_in_val[i][j]
                if (j == 0) begin
                    // 最左列 → a_left_in[i]
                    assign a_in_val[i][j] = a_left_in[i];
                end else begin
                    // それ以外 → a_wire[i][j-1]
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
                    // 最上行 → ps_top_in[j]
                    assign ps_in_val[i][j] = ps_top_in[j];
                end else begin
                    // それ以外 → ps_wire[i-1][j]
                    assign ps_in_val[i][j] = ps_wire[i-1][j];
                end
            end
        end
    endgenerate

    //========================================================
    // PE 配列インスタンス (4×4)
    //========================================================
    genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin: ROW_BLOCK
            for (c = 0; c < 4; c = c + 1) begin: COL_BLOCK

                PE u_pe (
                    // クロック & リセット
                    .Clock          (Clock),
                    .rst_n          (rst_n),

                    // 制御信号
                    .data_clear     (data_clear),
                    .en_shift_right (en_shift_right),
                    .en_shift_bottom(en_shift_bottom),

                    // B 入力
                    .b_reg          (b_reg_array[r][c]),
                    .b_we           (b_we_array[r][c]),

                    // A / partial_sum の接続
                    .a_in           (a_in_val[r][c]),   // ← 三項演算子不要！
                    .ps_in          (ps_in_val[r][c]),  // ← 三項演算子不要！

                    // 出力
                    .a_shift_to_right      (a_wire[r][c]),
                    .partial_sum_to_bottom (ps_wire[r][c])
                );

            end
        end
    endgenerate

    //========================================================
    // 最下段部分和 (row=4) → ps_bottom_out
    //========================================================
    generate
        for (c = 0; c < 4; c = c + 1) begin : FINAL_PS
            assign ps_bottom_out[c] = ps_wire[3][c];
        end
    endgenerate

endmodule
