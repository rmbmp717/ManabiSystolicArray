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
    //     ここでは例として「b_reg_array[b_sel]」を返す
    //     A側を返したい場合は、sel_a_or_b で切り替えるなど
    //------------------------------------------------
    reg [15:0] rdata_mux;
    always @(*) begin
        // b_sel による読み出し例
        case (b_sel)
            4'd0 :  rdata_mux = b_reg_array[0];
            4'd1 :  rdata_mux = b_reg_array[1];
            4'd2 :  rdata_mux = b_reg_array[2];
            4'd3 :  rdata_mux = b_reg_array[3];
            4'd4 :  rdata_mux = b_reg_array[4];
            4'd5 :  rdata_mux = b_reg_array[5];
            4'd6 :  rdata_mux = b_reg_array[6];
            4'd7 :  rdata_mux = b_reg_array[7];
            4'd8 :  rdata_mux = b_reg_array[8];
            4'd9 :  rdata_mux = b_reg_array[9];
            4'd10:  rdata_mux = b_reg_array[10];
            4'd11:  rdata_mux = b_reg_array[11];
            4'd12:  rdata_mux = b_reg_array[12];
            4'd13:  rdata_mux = b_reg_array[13];
            4'd14:  rdata_mux = b_reg_array[14];
            4'd15:  rdata_mux = b_reg_array[15];
            default: rdata_mux = 16'hxxxx;
        endcase
    end
    assign external_rdata = rdata_mux;

    // =================================================================
    //  (4) サブモジュールに渡すために wire を経由して配列をアサイン
    // =================================================================
    wire [15:0] w_b_reg_array_flat [0:15];
    wire [15:0] w_a_left_in_flat   [0:3];

    genvar idx_b, idx_a;
    generate
        for (idx_b = 0; idx_b < 16; idx_b = idx_b + 1) begin : GEN_B_REG_ASSIGN
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

        .b_reg_array_flat    (w_b_reg_array_flat),
        .b_we_array_flat     (b_we_array_flat),

        .a_left_in_flat      (w_a_left_in_flat),
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
