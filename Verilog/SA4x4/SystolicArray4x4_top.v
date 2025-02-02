`timescale 1ns / 1ps

module SystolicArray4x4_top (
    // 上位から与えられるポート
    input  wire         Clock,
    input  wire         rst_n,
    input  wire         data_clear,
    input  wire         en_b_shift_bottom,
    input  wire         en_shift_right,
    input  wire         en_shift_bottom,

    input  wire [15:0]  a_left_in_flat   [0:3],
    input  wire [15:0]  b_top_in_flat    [0:3],
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
        .en_b_shift_bottom  (en_b_shift_bottom),
        .en_shift_right     (en_shift_right),
        .en_shift_bottom    (en_shift_bottom),

        .a_left_in_flat     (a_left_in_flat),
        .b_top_in_flat      (b_top_in_flat),
        .ps_top_in_flat     (ps_top_in_flat),

        .ps_bottom_out_flat (ps_bottom_out_flat)
    );

    RV32IM uRV32IM(
        .clock              (Clock),
        .reset_n            (rst_n),
        .uart_out           (),
        .gpio_in            ()
    );

    // =================================================================
    // 2. VCDダンプ設定 (Icarus Verilog 用)
    // =================================================================
    // Debug
    wire [15:0] a_left_in_flat_0;
    wire [15:0] a_left_in_flat_1;
    wire [15:0] a_left_in_flat_2;
    wire [15:0] a_left_in_flat_3;
    assign a_left_in_flat_0 = a_left_in_flat[0];
    assign a_left_in_flat_1 = a_left_in_flat[1];
    assign a_left_in_flat_2 = a_left_in_flat[2];
    assign a_left_in_flat_3 = a_left_in_flat[3];

    wire [15:0] ps_bottom_out_flat_0;
    wire [15:0] ps_bottom_out_flat_1;
    wire [15:0] ps_bottom_out_flat_2;
    wire [15:0] ps_bottom_out_flat_3;
    assign ps_bottom_out_flat_0 = ps_bottom_out_flat[0];
    assign ps_bottom_out_flat_1 = ps_bottom_out_flat[1];
    assign ps_bottom_out_flat_2 = ps_bottom_out_flat[2];
    assign ps_bottom_out_flat_3 = ps_bottom_out_flat[3];

    initial begin
        $dumpfile("sa4x4.vcd");       // ダンプするファイル名
        $dumpvars(0, SystolicArray4x4_top);     
        $dumpvars(0, SystolicArray4x4_top.u_systolic);     
    end

endmodule
