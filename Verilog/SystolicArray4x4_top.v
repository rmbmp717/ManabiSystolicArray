`timescale 1ns / 1ps

module SystolicArray4x4_top (
    // 上位から与えられるポート
    input  wire         Clock,
    input  wire         rst_n,
    input  wire         data_clear,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    input  wire [15:0]  b_reg_array_flat [0:15],
    input  wire         b_we_array_flat  [0:15],

    input  wire [15:0]  a_left_in_flat   [0:3],
    input  wire [15:0]  ps_top_in_flat   [0:3],

    output wire [15:0]  ps_bottom_out_flat [0:3]
);

    // =================================================================
    // 1. サブモジュール（SystolicArray4x4）をインスタンス化
    // =================================================================
    SystolicArray4x4 u_systolic (
        .Clock              (Clock),
        .rst_n              (rst_n),
        .data_clear         (data_clear),
        .en_shift_right     (en_shift_right),
        .en_shift_bottom    (en_shift_bottom),

        .b_reg_array_flat   (b_reg_array_flat),
        .b_we_array_flat    (b_we_array_flat),

        .a_left_in_flat     (a_left_in_flat),
        .ps_top_in_flat     (ps_top_in_flat),

        .ps_bottom_out_flat (ps_bottom_out_flat)
    );

    // =================================================================
    // 2. VCDダンプ設定 (Icarus Verilog 用)
    // =================================================================
    initial begin
        $dumpfile("wave.vcd");       // ダンプするファイル名
        $dumpvars(1, SystolicArray4x4_top);     
        $dumpvars(0, SystolicArray4x4_top.u_systolic);     
    end

endmodule
