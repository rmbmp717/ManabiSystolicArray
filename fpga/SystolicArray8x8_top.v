`timescale 1ns / 1ps

module SystolicArrayNxN_top (
    input  wire         Clock,
    input  wire         rst_n,
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    //------------------------------------------------
    //  セレクタ等、外部アクセス用の追加ポート
    //------------------------------------------------
    input  wire  [5:0]  b_sel,         // b_reg_array 0〜63 のどの要素をアクセスするか (64要素なので6bit)
    input  wire  [2:0]  a_sel,         // a_left_in   0〜7  のどの要素をアクセスするか (8要素なので3bit)
    input  wire         external_we,   // 外部書き込みイネーブル
    input  wire         sel_a_or_b,    // 0なら b_reg_array に書き込み, 1なら a_left_in に書き込み
    input  wire [15:0]  external_wdata,// 外部書き込みデータ
    output wire [15:0]  external_rdata,// 外部読み出しデータ

    //------------------------------------------------
    //  従来の top_in / bottom_out などの入出力 (8要素)
    //------------------------------------------------
    input  wire  [2:0]  ps_sel,        // 出力データ選択用のセレクタ (3bit)
    output wire [15:0]  ps_bottom_out, // 選択された1つのデータを出力

    //------------------------------------------------
    //  b_we_array_flat 信号
    //------------------------------------------------
    input  wire         b_we_array_flat_sig
);

    //------------------------------------------------
    //  内部信号とレジスタの宣言
    //------------------------------------------------
    wire                b_we_array_flat[0:63]; // 64個の書き込みイネーブル
    reg  [15:0]         b_reg_array [0:63];    // 64個のBレジスタ
    reg  [15:0]         a_left_in   [0:7];     // 8個のA入力レジスタ
    wire [15:0]         ps_bottom_out_flat [0:7]; // 8個の部分和出力

    //------------------------------------------------
    //  書き込みイネーブル信号の展開
    //------------------------------------------------
    generate
        genvar i;
        for (i = 0; i < 64; i = i + 1) begin : WE_ARRAY_GEN
            assign b_we_array_flat[i] = b_we_array_flat_sig;
        end
    endgenerate

    //------------------------------------------------
    //  外部からの書き込み処理
    //------------------------------------------------
    always @(posedge Clock or negedge rst_n) begin
        integer i;
        if (!rst_n) begin
            // リセット時: 全レジスタをクリア
            for (i = 0; i < 64; i = i + 1) begin
                b_reg_array[i] <= 16'd0;
            end
            for (i = 0; i < 8; i = i + 1) begin
                a_left_in[i] <= 16'd0;
            end
        end else begin
            // 外部からの書き込み要求がある場合
            if (external_we) begin
                if (!sel_a_or_b) begin
                    // Bレジスタに書き込み
                    b_reg_array[b_sel] <= external_wdata;
                end else begin
                    // Aレジスタに書き込み
                    a_left_in[a_sel] <= external_wdata;
                end
            end
        end
    end

    //------------------------------------------------
    //  外部への読み出しデータ処理
    //------------------------------------------------
    reg [15:0] rdata_mux;
    always @(*) begin
        rdata_mux = b_reg_array[b_sel]; // デフォルトはBレジスタを選択
    end
    assign external_rdata = rdata_mux;

    //------------------------------------------------
    //  サブモジュールに渡すための配列
    //------------------------------------------------
    wire [15:0] w_b_reg_array_flat [0:63];
    wire [15:0] w_a_left_in_flat   [0:7];

    generate
        // Bレジスタ配列の割り当て
        genvar idx_b;
        for (idx_b = 0; idx_b < 64; idx_b = idx_b + 1) begin : B_REG_GEN
            assign w_b_reg_array_flat[idx_b] = b_reg_array[idx_b];
        end

        // Aレジスタ配列の割り当て
        genvar idx_a;
        for (idx_a = 0; idx_a < 8; idx_a = idx_a + 1) begin : A_LEFT_GEN
            assign w_a_left_in_flat[idx_a] = a_left_in[idx_a];
        end
    endgenerate

    //------------------------------------------------
    //  出力セレクタに基づく部分和出力選択
    //------------------------------------------------
    reg [15:0] ps_selected_out;
    always @(*) begin
        case (ps_sel)
            3'd0: ps_selected_out = ps_bottom_out_flat[0];
            3'd1: ps_selected_out = ps_bottom_out_flat[1];
            3'd2: ps_selected_out = ps_bottom_out_flat[2];
            3'd3: ps_selected_out = ps_bottom_out_flat[3];
            3'd4: ps_selected_out = ps_bottom_out_flat[4];
            3'd5: ps_selected_out = ps_bottom_out_flat[5];
            3'd6: ps_selected_out = ps_bottom_out_flat[6];
            3'd7: ps_selected_out = ps_bottom_out_flat[7];
            default: ps_selected_out = 16'd0;
        endcase
    end
    assign ps_bottom_out = ps_selected_out;

    //------------------------------------------------
    //  サブモジュールのインスタンス化
    //------------------------------------------------
    SystolicArrayNxN u_systolic (
        .Clock               (Clock),
        .rst_n               (rst_n),
        .data_clear          (data_clear),
        .en_shift_right      (en_shift_right),
        .en_shift_bottom     (en_shift_bottom),

        // 64個のBレジスタ配列
        .b_reg_array_flat    (w_b_reg_array_flat),
        .b_we_array_flat     (b_we_array_flat),

        // 8個のA入力配列
        .a_left_in_flat      (w_a_left_in_flat),

        // 出力配列
        .ps_bottom_out_flat  (ps_bottom_out_flat)
    );

    //------------------------------------------------
    //  VCDダンプ設定 (Icarus Verilog 用)
    //------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");       
        $dumpvars(1, SystolicArrayNxN_top);     
        $dumpvars(0, SystolicArrayNxN_top.u_systolic);     
    end

endmodule
