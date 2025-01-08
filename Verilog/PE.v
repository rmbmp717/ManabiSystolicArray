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
    reg [15:0] b_reg_internal;         // B を保持するレジスタ
    reg [15:0] a_reg;                  // A を保持するレジスタ
    reg [15:0] ps_reg;                 // partial_sum を保持

    // 5段パイプライン用レジスタ (1つの乗算器を5サイクルかけて実行する想定)
    reg [15:0] mul_pipe [0:4];         // mul_pipe[0] が最初に入力を受け取る
    wire [15:0] mul_input;             // 乗算入力 (A * B)
    reg [15:0] mul_result;             // 乗算結果（5段の最後）

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
    // A Register & Shift (右方向シフト)
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 16'd0;
        end else if (data_clear) begin
            a_reg <= 16'd0;
        end else if (en_shift_right) begin
            // 左から a_in が入ってきて自分のレジスタにロード
            a_reg <= a_in;
        end
    end

    // 出力: 自分の a_reg を右隣へ渡す
    assign a_shift_to_right = a_reg;

    //========================================================
    // 5-stage Multiply Pipeline
    //========================================================
    assign mul_input = a_reg * b_reg_internal; // 実際は合成上マルチサイクル等の考慮が必要

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
            // シフトレジスタ形式
            mul_pipe[0] <= mul_input;       // Stage 1
            mul_pipe[1] <= mul_pipe[0];    // Stage 2
            mul_pipe[2] <= mul_pipe[1];    // Stage 3
            mul_pipe[3] <= mul_pipe[2];    // Stage 4
            mul_pipe[4] <= mul_pipe[3];    // Stage 5
        end
    end

    // 最終段の乗算結果
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
    // partial_sum Register & Shift (下方向シフト)
    //========================================================
    always @(posedge Clock or negedge rst_n) begin
        if (!rst_n) begin
            ps_reg <= 16'd0;
        end else if (data_clear) begin
            ps_reg <= 16'd0;
        end else if (en_shift_bottom) begin
            // ここで上からの ps_in と 自分の mul_result を足し込む、とする場合
            // ps_reg は現サイクルの古い値 + ps_in + mul_result など、要件に応じて決定
            ps_reg <= ps_in + mul_result;
        end
    end

    // 出力: 自分の partial_sum を下へ渡す
    assign partial_sum_to_bottom = ps_reg;

endmodule
