`timescale 1ns / 1ps

module SystolicArray4x4_top (
    // Ports from the upper module
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

    wire       uart_rw;
    wire [7:0] uart_data;

    // =================================================================
    // 1. Instantiate the submodule (SystolicArray4x4)
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

    wire [15:0] bm_data0;
    wire [15:0] bm_data1;
    wire [15:0] bm_data2;
    wire [15:0] bm_data3;
    assign  bm_data0 = ps_bottom_out_flat[0];
    assign  bm_data1 = ps_bottom_out_flat[1];
    assign  bm_data2 = ps_bottom_out_flat[2];
    assign  bm_data3 = ps_bottom_out_flat[3];

    wire [31:0] dma_in_data;
    assign  dma_in_data = {{bm_data3[7:0]}, {bm_data2[7:0]}, {bm_data1[7:0]}, {bm_data0[7:0]}};
    //assign  dma_in_data = 32'h01020304;

    // RISC-V processor instance
    RV32IM uRV32IM(
        // Clock & Reset
        .clock              (Clock),
        .reset_n            (rst_n),
        .uart_out           ({{uart_rw}, {uart_data}}),
        .DMA_in             (dma_in_data)
    );

    // Shift enable for right shift
    shift_module #(
        .EN_SHIFT_ADDR      (8'hFF)
        ) right_shift_module(
        // Clock & Reset
        .Clock              (Clock),
        .rst_n              (rst_n),
        // UART interface
        .uart_rw            (uart_rw),
        .uart_in            (uart_data),
        .shift              (en_shift_right)
    );

    // Shift enable for b data shift
    shift_module #(
        .EN_SHIFT_ADDR      (8'hFE)
        ) b_shift_module(
        // Clock & Reset
        .Clock              (Clock),
        .rst_n              (rst_n),
        // UART interface
        .uart_rw            (uart_rw),
        .uart_in            (uart_data),
        .shift              (en_b_shift_bottom)
    );

    // Shift enable for bottom shift
    shift_module #(
        .EN_SHIFT_ADDR      (8'hFD)
        ) bottom_shift_module(
        // Clock & Reset
        .Clock              (Clock),
        .rst_n              (rst_n),
        // UART interface
        .uart_rw            (uart_rw),
        .uart_in            (uart_data),
        .shift              (en_shift_bottom)
    );

    // Data input module for matrix A
    data_16x4_module #(
        .DATA_WRITE_ADDR    (8'hFC)
    ) a_data_16x4_module(
        // Clock & Reset
        .Clock              (Clock),
        .rst_n              (rst_n),
        // UART interface
        .uart_rw            (uart_rw),
        .uart_in            (uart_data),
        .saved_data0        (a_left_in_flat[0]),
        .saved_data1        (a_left_in_flat[1]),
        .saved_data2        (a_left_in_flat[2]),
        .saved_data3        (a_left_in_flat[3])
    );

    // Data input module for matrix B
    data_16x4_module #(
        .DATA_WRITE_ADDR    (8'hFB)
    ) b_data_16x4_module(
        // Clock & Reset
        .Clock              (Clock),
        .rst_n              (rst_n),
        // UART interface
        .uart_rw            (uart_rw),
        .uart_in            (uart_data),
        .saved_data0        (b_top_in_flat[0]),
        .saved_data1        (b_top_in_flat[1]),
        .saved_data2        (b_top_in_flat[2]),
        .saved_data3        (b_top_in_flat[3])
    );

    // Data input module for PS in
    data_16x4_module #(
        .DATA_WRITE_ADDR    (8'hFA)
    ) ps_in_module(
        // Clock & Reset
        .Clock              (Clock),
        .rst_n              (rst_n),
        // UART interface
        .uart_rw            (uart_rw),
        .uart_in            (uart_data),
        .saved_data0        (ps_top_in_flat[0]),
        .saved_data1        (ps_top_in_flat[1]),
        .saved_data2        (ps_top_in_flat[2]),
        .saved_data3        (ps_top_in_flat[3])
    );


    // =================================================================
    // 2. VCD dump settings (for Icarus Verilog simulation)
    // =================================================================
    // Debugging signals
    wire [15:0] a_left_in_flat_0;
    wire [15:0] a_left_in_flat_1;
    wire [15:0] a_left_in_flat_2;
    wire [15:0] a_left_in_flat_3;
    assign a_left_in_flat_0 = a_left_in_flat[0];
    assign a_left_in_flat_1 = a_left_in_flat[1];
    assign a_left_in_flat_2 = a_left_in_flat[2];
    assign a_left_in_flat_3 = a_left_in_flat[3];

    wire [15:0] b_top_in_flat_0;
    wire [15:0] b_top_in_flat_1;
    wire [15:0] b_top_in_flat_2;
    wire [15:0] b_top_in_flat_3;
    assign b_top_in_flat_0 = b_top_in_flat[0];
    assign b_top_in_flat_1 = b_top_in_flat[1];
    assign b_top_in_flat_2 = b_top_in_flat[2];
    assign b_top_in_flat_3 = b_top_in_flat[3];

    wire [15:0] ps_bottom_out_flat_0;
    wire [15:0] ps_bottom_out_flat_1;
    wire [15:0] ps_bottom_out_flat_2;
    wire [15:0] ps_bottom_out_flat_3;
    assign ps_bottom_out_flat_0 = ps_bottom_out_flat[0];
    assign ps_bottom_out_flat_1 = ps_bottom_out_flat[1];
    assign ps_bottom_out_flat_2 = ps_bottom_out_flat[2];
    assign ps_bottom_out_flat_3 = ps_bottom_out_flat[3];

    wire [15:0] ps_top_in_flat_0;
    wire [15:0] ps_top_in_flat_1;
    wire [15:0] ps_top_in_flat_2;
    wire [15:0] ps_top_in_flat_3;
    assign ps_top_in_flat_0 = ps_top_in_flat[0];
    assign ps_top_in_flat_1 = ps_top_in_flat[1];
    assign ps_top_in_flat_2 = ps_top_in_flat[2];
    assign ps_top_in_flat_3 = ps_top_in_flat[3];

    initial begin
        $dumpfile("sa4x4.vcd");       // Output file name for VCD dump
        $dumpvars(1, SystolicArray4x4_top);     
        $dumpvars(0, SystolicArray4x4_top.u_systolic);     
        $dumpvars(1, SystolicArray4x4_top.uRV32IM);     
        $dumpvars(1, SystolicArray4x4_top.right_shift_module);    
        $dumpvars(1, SystolicArray4x4_top.b_shift_module);    
        $dumpvars(1, SystolicArray4x4_top.bottom_shift_module);    
        $dumpvars(1, SystolicArray4x4_top.a_data_16x4_module);     
        $dumpvars(1, SystolicArray4x4_top.b_data_16x4_module);   
    end

endmodule