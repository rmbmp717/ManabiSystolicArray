module fp16_multiplier(
  input wire clk,
  input wire [15:0] a,
  input wire [15:0] b,
  output wire [15:0] out
);
  // lint_off MULTIPLY
  function automatic [21:0] umul22b_11b_x_11b (input reg [10:0] lhs, input reg [10:0] rhs);
    begin
      umul22b_11b_x_11b = lhs * rhs;
    end
  endfunction
  // lint_on MULTIPLY

  // ===== Pipe stage 0:

  // Registers for pipe stage 0:
  reg [15:0] p0_a;
  reg [15:0] p0_b;
  always @ (posedge clk) begin
    p0_a <= a;
    p0_b <= b;
  end

  // ===== Pipe stage 1:
  wire [4:0] p1_exp_a_comb;
  wire [4:0] p1_exp_b_comb;
  wire p1_eq_869_comb;
  wire p1_eq_870_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_leading_a_comb;
  wire [9:0] p1_frac_a_raw_comb;
  wire p1_leading_b_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire [5:0] p1_add_879_comb;
  wire p1_eq_882_comb;
  wire p1_eq_883_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_869_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_870_comb = p1_exp_b_comb == 5'h00;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_leading_a_comb = ~p1_eq_869_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_870_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_add_879_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_882_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_883_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_869;
  reg p1_eq_870;
  reg p1_leading_a;
  reg [9:0] p1_frac_a_raw;
  reg p1_leading_b;
  reg [9:0] p1_frac_b_raw;
  reg [5:0] p1_add_879;
  reg p1_eq_882;
  reg p1_eq_883;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_869 <= p1_eq_869_comb;
    p1_eq_870 <= p1_eq_870_comb;
    p1_leading_a <= p1_leading_a_comb;
    p1_frac_a_raw <= p1_frac_a_raw_comb;
    p1_leading_b <= p1_leading_b_comb;
    p1_frac_b_raw <= p1_frac_b_raw_comb;
    p1_add_879 <= p1_add_879_comb;
    p1_eq_882 <= p1_eq_882_comb;
    p1_eq_883 <= p1_eq_883_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_eq_924_comb;
  wire p2_eq_925_comb;
  wire [21:0] p2_frac_mult_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire p2_leading_bit_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_guard_bit_comb;
  wire p2_not_931_comb;
  wire p2_is_nan_result_comb;
  assign p2_eq_924_comb = p1_frac_a_raw == 10'h000;
  assign p2_eq_925_comb = p1_frac_b_raw == 10'h000;
  assign p2_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a, p1_frac_a_raw}, {p1_leading_b, p1_frac_b_raw});
  assign p2_is_zero_a_comb = p1_eq_869 & p2_eq_924_comb;
  assign p2_is_zero_b_comb = p1_eq_870 & p2_eq_925_comb;
  assign p2_is_inf_a_chk_comb = p1_eq_882 & p2_eq_924_comb;
  assign p2_is_inf_b_chk_comb = p1_eq_883 & p2_eq_925_comb;
  assign p2_leading_bit_comb = p2_frac_mult_comb[21];
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_882 | p2_eq_924_comb);
  assign p2_is_nan__1_comb = ~(~p1_eq_883 | p2_eq_925_comb);
  assign p2_round_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[9] : p2_frac_mult_comb[8];
  assign p2_sticky_bit_comb = p2_frac_mult_comb[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p2_frac_mult_comb[21:11] : p2_frac_mult_comb[20:10];
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[10] : p2_frac_mult_comb[9];
  assign p2_not_931_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_a_chk_comb & p1_eq_870 & p2_eq_925_comb | p1_eq_869 & p2_eq_924_comb & p2_is_inf_b_chk_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg p2_round_bit;
  reg p2_sticky_bit;
  reg [10:0] p2_frac_adjusted;
  reg p2_guard_bit;
  reg [5:0] p2_add_879;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_931;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_round_bit <= p2_round_bit_comb;
    p2_sticky_bit <= p2_sticky_bit_comb;
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_guard_bit <= p2_guard_bit_comb;
    p2_add_879 <= p1_add_879;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_931 <= p2_not_931_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire p3_round_condition_comb;
  assign p3_round_condition_comb = p2_guard_bit & (p2_round_bit | p2_sticky_bit) | p2_guard_bit & ~p2_round_bit & ~p2_sticky_bit & p2_frac_adjusted[0];

  // Registers for pipe stage 3:
  reg p3_leading_bit;
  reg [10:0] p3_frac_adjusted;
  reg p3_round_condition;
  reg [5:0] p3_add_879;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_931;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_leading_bit <= p2_leading_bit;
    p3_frac_adjusted <= p2_frac_adjusted;
    p3_round_condition <= p3_round_condition_comb;
    p3_add_879 <= p2_add_879;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_931 <= p2_not_931;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [11:0] p4_frac_adjusted_12_comb;
  wire [11:0] p4_one_12__1_comb;
  wire [11:0] p4_frac_no_of_12_comb;
  wire p4_cond_of_comb;
  wire [10:0] p4_frac_no_of_11_comb;
  wire [10:0] p4_frac_of_shifted_11_comb;
  wire [10:0] p4_frac_final_11_comb;
  assign p4_frac_adjusted_12_comb = {1'h0, p3_frac_adjusted};
  assign p4_one_12__1_comb = {11'h000, p3_round_condition};
  assign p4_frac_no_of_12_comb = p4_frac_adjusted_12_comb + p4_one_12__1_comb;
  assign p4_cond_of_comb = p4_frac_no_of_12_comb[11];
  assign p4_frac_no_of_11_comb = p4_frac_no_of_12_comb[10:0];
  assign p4_frac_of_shifted_11_comb = p4_frac_no_of_12_comb[11:1];
  assign p4_frac_final_11_comb = p4_cond_of_comb ? p4_frac_of_shifted_11_comb : p4_frac_no_of_11_comb;

  // Registers for pipe stage 4:
  reg p4_leading_bit;
  reg p4_cond_of;
  reg [5:0] p4_add_879;
  reg [10:0] p4_frac_final_11;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg p4_not_931;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_leading_bit <= p3_leading_bit;
    p4_cond_of <= p4_cond_of_comb;
    p4_add_879 <= p3_add_879;
    p4_frac_final_11 <= p4_frac_final_11_comb;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_not_931 <= p3_not_931;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [6:0] p5_concat_1020_comb;
  wire [1:0] p5_add_1025_comb;
  wire [6:0] p5_add_1027_comb;
  wire [5:0] p5_add_1028_comb;
  wire [6:0] p5_add_1032_comb;
  wire [7:0] p5_add_1033_comb;
  assign p5_concat_1020_comb = {1'h0, p4_add_879};
  assign p5_add_1025_comb = {1'h0, p4_leading_bit} + {1'h0, p4_cond_of};
  assign p5_add_1027_comb = p5_concat_1020_comb + {6'h00, p4_leading_bit};
  assign p5_add_1028_comb = {5'h00, p4_cond_of} + 6'h31;
  assign p5_add_1032_comb = p5_concat_1020_comb + {5'h00, p5_add_1025_comb};
  assign p5_add_1033_comb = {1'h0, p5_add_1027_comb} + {{2{p5_add_1028_comb[5]}}, p5_add_1028_comb};

  // Registers for pipe stage 5:
  reg [6:0] p5_add_1032;
  reg [7:0] p5_add_1033;
  reg [10:0] p5_frac_final_11;
  reg p5_is_inf_a_chk;
  reg p5_is_inf_b_chk;
  reg p5_not_931;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_add_1032 <= p5_add_1032_comb;
    p5_add_1033 <= p5_add_1033_comb;
    p5_frac_final_11 <= p4_frac_final_11;
    p5_is_inf_a_chk <= p4_is_inf_a_chk;
    p5_is_inf_b_chk <= p4_is_inf_b_chk;
    p5_not_931 <= p4_not_931;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [4:0] p6_exp_out_5_comb;
  wire [31:0] p6_frac_final_32_comb;
  wire [8:0] p6_shift_9_comb;
  wire [31:0] p6_frac_subnormal_32_comb;
  wire p6_sign_comb;
  wire [9:0] p6_frac_out_10_comb;
  wire [9:0] p6_frac_subnormal_comb;
  wire p6_nor_1069_comb;
  wire p6_is_subnormal_comb;
  wire [14:0] p6_concat_1071_comb;
  assign p6_exp_out_5_comb = p5_add_1033[4:0];
  assign p6_frac_final_32_comb = {21'h00_0000, p5_frac_final_11};
  assign p6_shift_9_comb = 9'h010 - {2'h0, p5_add_1032};
  assign p6_frac_subnormal_32_comb = p6_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p6_frac_final_32_comb >> p6_shift_9_comb;
  assign p6_sign_comb = p5_add_1033[7];
  assign p6_frac_out_10_comb = p5_frac_final_11[9:0];
  assign p6_frac_subnormal_comb = p6_frac_subnormal_32_comb[9:0];
  assign p6_nor_1069_comb = ~(p6_sign_comb | ~((|p5_add_1033[7:5]) | (&p6_exp_out_5_comb)));
  assign p6_is_subnormal_comb = p6_sign_comb | ~((|p5_add_1033[7:1]) | p5_add_1033[0]);
  assign p6_concat_1071_comb = {p6_exp_out_5_comb, p6_frac_out_10_comb};

  // Registers for pipe stage 6:
  reg [9:0] p6_frac_subnormal;
  reg p6_is_inf_a_chk;
  reg p6_is_inf_b_chk;
  reg p6_nor_1069;
  reg p6_is_subnormal;
  reg [14:0] p6_concat_1071;
  reg p6_not_931;
  reg p6_sign_result;
  reg p6_is_nan_result;
  always @ (posedge clk) begin
    p6_frac_subnormal <= p6_frac_subnormal_comb;
    p6_is_inf_a_chk <= p5_is_inf_a_chk;
    p6_is_inf_b_chk <= p5_is_inf_b_chk;
    p6_nor_1069 <= p6_nor_1069_comb;
    p6_is_subnormal <= p6_is_subnormal_comb;
    p6_concat_1071 <= p6_concat_1071_comb;
    p6_not_931 <= p5_not_931;
    p6_sign_result <= p5_sign_result;
    p6_is_nan_result <= p5_is_nan_result;
  end

  // ===== Pipe stage 7:
  wire p7_is_inf_result_comb;
  wire [14:0] p7_and_1097_comb;
  assign p7_is_inf_result_comb = p6_is_inf_a_chk | p6_is_inf_b_chk | p6_nor_1069;
  assign p7_and_1097_comb = (p7_is_inf_result_comb ? 15'h7c00 : (p6_is_subnormal ? {5'h00, p6_frac_subnormal} : p6_concat_1071)) & {15{p6_not_931}};

  // Registers for pipe stage 7:
  reg p7_sign_result;
  reg [14:0] p7_and_1097;
  reg p7_is_nan_result;
  always @ (posedge clk) begin
    p7_sign_result <= p6_sign_result;
    p7_and_1097 <= p7_and_1097_comb;
    p7_is_nan_result <= p6_is_nan_result;
  end

  // ===== Pipe stage 8:
  wire [15:0] p8_result_comb;
  assign p8_result_comb = p7_is_nan_result ? 16'h7e00 : {p7_sign_result, p7_and_1097};

  // Registers for pipe stage 8:
  reg [15:0] p8_result;
  always @ (posedge clk) begin
    p8_result <= p8_result_comb;
  end
  assign out = p8_result;
endmodule
