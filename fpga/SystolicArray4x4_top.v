`timescale 1ns / 1ps

module SystolicArray4x4_top (
    input  wire         Clock,
    input  wire         rst_n,
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    //------------------------------------------------
    //  セレクタ等、外部アクセス用の追加ポート
    //------------------------------------------------
    input  wire  [3:0]  b_sel,         // b_reg_array 0〜15 のどの要素をアクセスするか
    input  wire  [1:0]  a_sel,         // a_left_in   0〜3  のどの要素をアクセスするか
    input  wire         external_we,   // 外部書き込みイネーブル
    input  wire         sel_a_or_b,    // 0なら b_reg_array に書き込み, 1なら a_left_in に書き込み
    input  wire [15:0]  external_wdata,// 外部書き込みデータ
    output wire [15:0]  external_rdata,// 外部読み出しデータ

    //------------------------------------------------
    //  従来の top_in / bottom_out などの入出力
    //------------------------------------------------
    input  wire [15:0]  ps_top_in_flat      [0:3],
    output wire [15:0]  ps_bottom_out_flat  [0:3],

    //------------------------------------------------
    //  b_we_array_flat も上位から与えたい場合に利用
    //------------------------------------------------
    input  wire         b_we_array_flat  [0:15]
);

    //------------------------------------------------
    //  (1) b_reg_array, a_left_in をモジュール内部で保持するレジスタを用意
    //------------------------------------------------
    reg [15:0] b_reg_array [0:15];
    reg [15:0] a_left_in   [0:3];

    //------------------------------------------------
    //  (2) 外部からの書き込み処理
    //------------------------------------------------
    integer i;
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            // リセット時: 必要に応じて 0クリア等を行う
            for (i = 0; i < 16; i = i + 1) begin
                b_reg_array[i] <= 16'd0;
            end
            for (i = 0; i < 4; i = i + 1) begin
                a_left_in[i] <= 16'd0;
            end
        end else begin
            // 外部からの書き込み要求(external_we)があるとき
            if (external_we) begin
                // sel_a_or_b が 0なら b_reg_array に書き込み
                // sel_a_or_b が 1なら a_left_in    に書き込み
                if (!sel_a_or_b) begin
                    b_reg_array[b_sel] <= external_wdata;
                end else begin
                    a_left_in[a_sel] <= external_wdata;
                end
            end
        end
    end

    //------------------------------------------------
    //  (3) 外部への読み出しデータ
    //------------------------------------------------
    // sel_a_or_b に基づいて読み出しソースを選択
    reg [15:0] rdata_mux;
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            rdata_mux <= 16'd0;
        end else begin
            if (!sel_a_or_b) begin
                rdata_mux <= b_reg_array[b_sel];
            end else begin
                rdata_mux <= a_left_in[a_sel];
            end
        end
    end
    assign external_rdata = rdata_mux;

    // =================================================================
    //  (4) サブモジュールに渡すために wire を経由して配列をアサイン
    // =================================================================
    wire [15:0] w_b_reg_array_flat [0:3];
    wire [15:0] w_a_left_in_flat   [0:3];

    genvar idx_b, idx_a;
    generate
        for (idx_b = 0; idx_b < 4; idx_b = idx_b + 1) begin : GEN_B_REG_ASSIGN
            assign w_b_reg_array_flat[idx_b] = b_reg_array[idx_b];
        end
        for (idx_a = 0; idx_a < 4; idx_a = idx_a + 1) begin : GEN_A_LEFT_ASSIGN
            assign w_a_left_in_flat[idx_a] = a_left_in[idx_a];
        end
    endgenerate

    // =================================================================
    //  (5) サブモジュール（SystolicArray4x4）をインスタンス化
    // =================================================================
    SystolicArray4x4 u_systolic (
        .Clock               (Clock),
        .rst_n               (rst_n),
        .data_clear          (data_clear),
        .en_shift_right      (en_shift_right),
        .en_shift_bottom     (en_shift_bottom),

        .a_left_in_flat      (w_a_left_in_flat),
        .b_top_in_flat       (w_b_reg_array_flat),
        .ps_top_in_flat      (ps_top_in_flat),

        .ps_bottom_out_flat  (ps_bottom_out_flat)
    );

    // =================================================================
    //  (6) VCDダンプ設定 (Icarus Verilog 用)
    // =================================================================
    initial begin
        $dumpfile("wave.vcd");       
        $dumpvars(1, SystolicArray4x4_top);     
        $dumpvars(0, SystolicArray4x4_top.u_systolic);     
    end

endmodule
