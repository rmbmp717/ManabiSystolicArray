module SystolicArray4x4 (
    input  wire         Clock,
    input  wire         rst_n,

    // 制御信号 (全PE共通)
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    // Bレジスタ書き込み用（外部または上位から制御）
    input  wire [15:0]  b_reg_array [0:3][0:3],
    input  wire         b_we_array  [0:3][0:3],

    // Aおよびpartial_sumの外部接続例（必要に応じて追加・変更）
    // 今回は簡単のため、左端と上端を外部から与える場合を想定
    input  wire [15:0]  a_left_in   [0:3],  // 各行の左端から入れるA
    input  wire [15:0]  ps_top_in   [0:3],  // 各列の上端から入れるpartial_sum
    
    // 計算結果の取り出し (最下段の partial_sum を外部に出す場合)
    output wire [15:0]  ps_bottom_out [0:3]  // 各列の最下段PEのpartial_sum
);

    //========================================================
    // 配線 (Aのシフト、partial_sum のシフト)
    //========================================================
    //  - a_wire[r][c] は「PE[r][c] へ入力する A」
    //  - a_wire[r][c+1] は「PE[r][c] の出力を右隣に接続」する
    //    つまり、PE[r][c].a_shift_to_right → a_wire[r][c+1]
    //
    //  - ps_wire[r][c] は「PE[r][c] へ入力する partial_sum」
    //  - ps_wire[r+1][c] は「PE[r][c] の出力を下隣に接続」する
    //    つまり、PE[r][c].partial_sum_to_bottom → ps_wire[r+1][c]
    //
    // ※Verilog 2001 以前だと多次元配列のポートに制限があるため、
    //   SystemVerilog で書くか、あるいは1次元に展開して使う方法などもあります。
    //   ここでは説明のため多次元配列で記述しています。

    // A: 横方向に 4+1=5 本(列数+1)
    wire [15:0] a_wire [0:3][0:4];
    // partial_sum: 縦方向に 4+1=5 本(行数+1)
    wire [15:0] ps_wire [0:4][0:3];

    genvar r, c;

    //========================================================
    // 境界 (左端・上端) の入力設定
    //========================================================
    // 左端 (col=0) の a_wire[r][0] <= a_left_in[r]
    generate
    for (r = 0; r < 4; r = r + 1) begin
        assign a_wire[r][0] = a_left_in[r];
    end
    endgenerate

    // 上端 (row=0) の ps_wire[0][c] <= ps_top_in[c]
    generate
    for (c = 0; c < 4; c = c + 1) begin
        assign ps_wire[0][c] = ps_top_in[c];
    end
    endgenerate

    //========================================================
    // 4x4 の PE インスタンス生成
    //========================================================
    generate
    for (r = 0; r < 4; r = r + 1) begin : ROW_BLOCK
        for (c = 0; c < 4; c = c + 1) begin : COL_BLOCK

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

                // A / partial sum の入力
                .a_in           (a_wire[r][c]),
                .ps_in          (ps_wire[r][c]),

                // 出力
                .a_shift_to_right      (a_wire[r][c+1]),    // → 右隣へ
                .partial_sum_to_bottom (ps_wire[r+1][c])    // → 下隣へ
            );

        end
    end
    endgenerate

    //========================================================
    // 境界 (最下段) の partial_sum を外部へ
    //========================================================
    // ps_wire[4][c] が、row=4(最下段のさらに1つ下)に相当。
    // 実際の最下段PE は row=3 なので、その出力が ps_wire[4][c] に繋がっている。
    // これを上位へ返す。
    generate
    for (c = 0; c < 4; c = c + 1) begin
        assign ps_bottom_out[c] = ps_wire[4][c];
    end
    endgenerate

endmodule
