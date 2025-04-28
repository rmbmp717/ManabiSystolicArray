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
  wire [9:0] p1_frac_a_raw_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_leading_a_comb;
  wire p1_leading_b_comb;
  wire [5:0] p1_add_879_comb;
  wire p1_eq_884_comb;
  wire p1_eq_885_comb;
  wire p1_eq_886_comb;
  wire p1_eq_887_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_869_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_870_comb = p1_exp_b_comb == 5'h00;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_leading_a_comb = ~p1_eq_869_comb;
  assign p1_leading_b_comb = ~p1_eq_870_comb;
  assign p1_add_879_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_884_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_885_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_886_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_887_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_869;
  reg p1_eq_870;
  reg p1_leading_a;
  reg [9:0] p1_frac_a_raw;
  reg p1_leading_b;
  reg [9:0] p1_frac_b_raw;
  reg [5:0] p1_add_879;
  reg p1_eq_884;
  reg p1_eq_885;
  reg p1_eq_886;
  reg p1_eq_887;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_869 <= p1_eq_869_comb;
    p1_eq_870 <= p1_eq_870_comb;
    p1_leading_a <= p1_leading_a_comb;
    p1_frac_a_raw <= p1_frac_a_raw_comb;
    p1_leading_b <= p1_leading_b_comb;
    p1_frac_b_raw <= p1_frac_b_raw_comb;
    p1_add_879 <= p1_add_879_comb;
    p1_eq_884 <= p1_eq_884_comb;
    p1_eq_885 <= p1_eq_885_comb;
    p1_eq_886 <= p1_eq_886_comb;
    p1_eq_887 <= p1_eq_887_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire [21:0] p2_frac_mult_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire p2_leading_bit_comb;
  wire p2_bit_slice_919_comb;
  wire p2_bit_slice_920_comb;
  wire [7:0] p2_bit_slice_921_comb;
  wire [10:0] p2_bit_slice_922_comb;
  wire [10:0] p2_bit_slice_923_comb;
  wire p2_bit_slice_924_comb;
  wire p2_not_930_comb;
  wire p2_is_nan_result_comb;
  assign p2_is_zero_a_comb = p1_eq_869 & p1_eq_884;
  assign p2_is_zero_b_comb = p1_eq_870 & p1_eq_885;
  assign p2_is_inf_a_chk_comb = p1_eq_886 & p1_eq_884;
  assign p2_is_inf_b_chk_comb = p1_eq_887 & p1_eq_885;
  assign p2_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a, p1_frac_a_raw}, {p1_leading_b, p1_frac_b_raw});
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_886 | p1_eq_884);
  assign p2_is_nan__1_comb = ~(~p1_eq_887 | p1_eq_885);
  assign p2_leading_bit_comb = p2_frac_mult_comb[21];
  assign p2_bit_slice_919_comb = p2_frac_mult_comb[8];
  assign p2_bit_slice_920_comb = p2_frac_mult_comb[9];
  assign p2_bit_slice_921_comb = p2_frac_mult_comb[7:0];
  assign p2_bit_slice_922_comb = p2_frac_mult_comb[20:10];
  assign p2_bit_slice_923_comb = p2_frac_mult_comb[21:11];
  assign p2_bit_slice_924_comb = p2_frac_mult_comb[10];
  assign p2_not_930_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_a_chk_comb & p1_eq_870 & p1_eq_885 | p1_eq_869 & p1_eq_884 & p2_is_inf_b_chk_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg p2_bit_slice_919;
  reg p2_bit_slice_920;
  reg [7:0] p2_bit_slice_921;
  reg [10:0] p2_bit_slice_922;
  reg [10:0] p2_bit_slice_923;
  reg p2_bit_slice_924;
  reg [5:0] p2_add_879;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_930;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_bit_slice_919 <= p2_bit_slice_919_comb;
    p2_bit_slice_920 <= p2_bit_slice_920_comb;
    p2_bit_slice_921 <= p2_bit_slice_921_comb;
    p2_bit_slice_922 <= p2_bit_slice_922_comb;
    p2_bit_slice_923 <= p2_bit_slice_923_comb;
    p2_bit_slice_924 <= p2_bit_slice_924_comb;
    p2_add_879 <= p1_add_879;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_930 <= p2_not_930_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire p3_round_bit_comb;
  wire p3_sticky_bit_comb;
  wire [10:0] p3_frac_adjusted_comb;
  wire p3_guard_bit_comb;
  wire p3_and_973_comb;
  wire p3_and_974_comb;
  assign p3_round_bit_comb = p2_leading_bit ? p2_bit_slice_920 : p2_bit_slice_919;
  assign p3_sticky_bit_comb = p2_bit_slice_921 != 8'h00;
  assign p3_frac_adjusted_comb = p2_leading_bit ? p2_bit_slice_923 : p2_bit_slice_922;
  assign p3_guard_bit_comb = p2_leading_bit ? p2_bit_slice_924 : p2_bit_slice_920;
  assign p3_and_973_comb = p3_guard_bit_comb & (p3_round_bit_comb | p3_sticky_bit_comb);
  assign p3_and_974_comb = p3_guard_bit_comb & ~p3_round_bit_comb & ~p3_sticky_bit_comb & p3_frac_adjusted_comb[0];

  // Registers for pipe stage 3:
  reg p3_leading_bit;
  reg [10:0] p3_frac_adjusted;
  reg p3_and_973;
  reg p3_and_974;
  reg [5:0] p3_add_879;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_930;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_leading_bit <= p2_leading_bit;
    p3_frac_adjusted <= p3_frac_adjusted_comb;
    p3_and_973 <= p3_and_973_comb;
    p3_and_974 <= p3_and_974_comb;
    p3_add_879 <= p2_add_879;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_930 <= p2_not_930;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire p4_round_condition_comb;
  wire [11:0] p4_frac_adjusted_12_comb;
  wire [11:0] p4_one_12__1_comb;
  wire [11:0] p4_frac_no_of_12_comb;
  assign p4_round_condition_comb = p3_and_973 | p3_and_974;
  assign p4_frac_adjusted_12_comb = {1'h0, p3_frac_adjusted};
  assign p4_one_12__1_comb = {11'h000, p4_round_condition_comb};
  assign p4_frac_no_of_12_comb = p4_frac_adjusted_12_comb + p4_one_12__1_comb;

  // Registers for pipe stage 4:
  reg p4_leading_bit;
  reg [11:0] p4_frac_no_of_12;
  reg [5:0] p4_add_879;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg p4_not_930;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_leading_bit <= p3_leading_bit;
    p4_frac_no_of_12 <= p4_frac_no_of_12_comb;
    p4_add_879 <= p3_add_879;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_not_930 <= p3_not_930;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire p5_cond_of_comb;
  wire [10:0] p5_frac_no_of_11_comb;
  wire [10:0] p5_frac_of_shifted_11_comb;
  wire [1:0] p5_add_1022_comb;
  wire [10:0] p5_frac_final_11_comb;
  assign p5_cond_of_comb = p4_frac_no_of_12[11];
  assign p5_frac_no_of_11_comb = p4_frac_no_of_12[10:0];
  assign p5_frac_of_shifted_11_comb = p4_frac_no_of_12[11:1];
  assign p5_add_1022_comb = {1'h0, p4_leading_bit} + {1'h0, p5_cond_of_comb};
  assign p5_frac_final_11_comb = p5_cond_of_comb ? p5_frac_of_shifted_11_comb : p5_frac_no_of_11_comb;

  // Registers for pipe stage 5:
  reg p5_leading_bit;
  reg p5_cond_of;
  reg [5:0] p5_add_879;
  reg [1:0] p5_add_1022;
  reg [10:0] p5_frac_final_11;
  reg p5_is_inf_a_chk;
  reg p5_is_inf_b_chk;
  reg p5_not_930;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_leading_bit <= p4_leading_bit;
    p5_cond_of <= p5_cond_of_comb;
    p5_add_879 <= p4_add_879;
    p5_add_1022 <= p5_add_1022_comb;
    p5_frac_final_11 <= p5_frac_final_11_comb;
    p5_is_inf_a_chk <= p4_is_inf_a_chk;
    p5_is_inf_b_chk <= p4_is_inf_b_chk;
    p5_not_930 <= p4_not_930;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [6:0] p6_concat_1049_comb;
  wire [6:0] p6_add_1055_comb;
  wire [5:0] p6_add_1056_comb;
  wire [6:0] p6_add_1061_comb;
  wire [7:0] p6_concat_1058_comb;
  wire [7:0] p6_sign_ext_1059_comb;
  wire [8:0] p6_concat_1062_comb;
  assign p6_concat_1049_comb = {1'h0, p5_add_879};
  assign p6_add_1055_comb = p6_concat_1049_comb + {6'h00, p5_leading_bit};
  assign p6_add_1056_comb = {5'h00, p5_cond_of} + 6'h31;
  assign p6_add_1061_comb = p6_concat_1049_comb + {5'h00, p5_add_1022};
  assign p6_concat_1058_comb = {1'h0, p6_add_1055_comb};
  assign p6_sign_ext_1059_comb = {{2{p6_add_1056_comb[5]}}, p6_add_1056_comb};
  assign p6_concat_1062_comb = {2'h0, p6_add_1061_comb};

  // Registers for pipe stage 6:
  reg [7:0] p6_concat_1058;
  reg [7:0] p6_sign_ext_1059;
  reg [10:0] p6_frac_final_11;
  reg [8:0] p6_concat_1062;
  reg p6_is_inf_a_chk;
  reg p6_is_inf_b_chk;
  reg p6_not_930;
  reg p6_sign_result;
  reg p6_is_nan_result;
  always @ (posedge clk) begin
    p6_concat_1058 <= p6_concat_1058_comb;
    p6_sign_ext_1059 <= p6_sign_ext_1059_comb;
    p6_frac_final_11 <= p5_frac_final_11;
    p6_concat_1062 <= p6_concat_1062_comb;
    p6_is_inf_a_chk <= p5_is_inf_a_chk;
    p6_is_inf_b_chk <= p5_is_inf_b_chk;
    p6_not_930 <= p5_not_930;
    p6_sign_result <= p5_sign_result;
    p6_is_nan_result <= p5_is_nan_result;
  end

  // ===== Pipe stage 7:
  wire [7:0] p7_add_1081_comb;
  wire [31:0] p7_frac_final_32_comb;
  wire [8:0] p7_shift_9_comb;
  wire [4:0] p7_exp_out_5_comb;
  wire [31:0] p7_frac_subnormal_32_comb;
  wire [9:0] p7_frac_out_10_comb;
  wire p7_or_reduce_1089_comb;
  wire p7_and_reduce_1090_comb;
  wire p7_or_reduce_1091_comb;
  wire p7_bit_slice_1092_comb;
  wire p7_sign_comb;
  wire [9:0] p7_frac_subnormal_comb;
  wire [14:0] p7_concat_1097_comb;
  assign p7_add_1081_comb = p6_concat_1058 + p6_sign_ext_1059;
  assign p7_frac_final_32_comb = {21'h00_0000, p6_frac_final_11};
  assign p7_shift_9_comb = 9'h010 - p6_concat_1062;
  assign p7_exp_out_5_comb = p7_add_1081_comb[4:0];
  assign p7_frac_subnormal_32_comb = p7_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p7_frac_final_32_comb >> p7_shift_9_comb;
  assign p7_frac_out_10_comb = p6_frac_final_11[9:0];
  assign p7_or_reduce_1089_comb = |p7_add_1081_comb[7:5];
  assign p7_and_reduce_1090_comb = &p7_exp_out_5_comb;
  assign p7_or_reduce_1091_comb = |p7_add_1081_comb[7:1];
  assign p7_bit_slice_1092_comb = p7_add_1081_comb[0];
  assign p7_sign_comb = p7_add_1081_comb[7];
  assign p7_frac_subnormal_comb = p7_frac_subnormal_32_comb[9:0];
  assign p7_concat_1097_comb = {p7_exp_out_5_comb, p7_frac_out_10_comb};

  // Registers for pipe stage 7:
  reg p7_or_reduce_1089;
  reg p7_and_reduce_1090;
  reg p7_or_reduce_1091;
  reg p7_bit_slice_1092;
  reg p7_sign;
  reg [9:0] p7_frac_subnormal;
  reg p7_is_inf_a_chk;
  reg p7_is_inf_b_chk;
  reg [14:0] p7_concat_1097;
  reg p7_not_930;
  reg p7_sign_result;
  reg p7_is_nan_result;
  always @ (posedge clk) begin
    p7_or_reduce_1089 <= p7_or_reduce_1089_comb;
    p7_and_reduce_1090 <= p7_and_reduce_1090_comb;
    p7_or_reduce_1091 <= p7_or_reduce_1091_comb;
    p7_bit_slice_1092 <= p7_bit_slice_1092_comb;
    p7_sign <= p7_sign_comb;
    p7_frac_subnormal <= p7_frac_subnormal_comb;
    p7_is_inf_a_chk <= p6_is_inf_a_chk;
    p7_is_inf_b_chk <= p6_is_inf_b_chk;
    p7_concat_1097 <= p7_concat_1097_comb;
    p7_not_930 <= p6_not_930;
    p7_sign_result <= p6_sign_result;
    p7_is_nan_result <= p6_is_nan_result;
  end

  // ===== Pipe stage 8:
  wire p8_is_subnormal_comb;
  wire p8_is_inf_result_comb;
  wire [14:0] p8_sel_1129_comb;
  assign p8_is_subnormal_comb = p7_sign | ~(p7_or_reduce_1091 | p7_bit_slice_1092);
  assign p8_is_inf_result_comb = p7_is_inf_a_chk | p7_is_inf_b_chk | ~(p7_sign | ~(p7_or_reduce_1089 | p7_and_reduce_1090));
  assign p8_sel_1129_comb = p8_is_subnormal_comb ? {5'h00, p7_frac_subnormal} : p7_concat_1097;

  // Registers for pipe stage 8:
  reg p8_is_inf_result;
  reg [14:0] p8_sel_1129;
  reg p8_not_930;
  reg p8_sign_result;
  reg p8_is_nan_result;
  always @ (posedge clk) begin
    p8_is_inf_result <= p8_is_inf_result_comb;
    p8_sel_1129 <= p8_sel_1129_comb;
    p8_not_930 <= p7_not_930;
    p8_sign_result <= p7_sign_result;
    p8_is_nan_result <= p7_is_nan_result;
  end

  // ===== Pipe stage 9:
  wire [15:0] p9_concat_1144_comb;
  assign p9_concat_1144_comb = {p8_sign_result, (p8_is_inf_result ? 15'h7c00 : p8_sel_1129) & {15{p8_not_930}}};

  // Registers for pipe stage 9:
  reg p9_is_nan_result;
  reg [15:0] p9_concat_1144;
  always @ (posedge clk) begin
    p9_is_nan_result <= p8_is_nan_result;
    p9_concat_1144 <= p9_concat_1144_comb;
  end

  // ===== Pipe stage 10:
  wire [15:0] p10_result_comb;
  assign p10_result_comb = p9_is_nan_result ? 16'h7e00 : p9_concat_1144;

  // Registers for pipe stage 10:
  reg [15:0] p10_result;
  always @ (posedge clk) begin
    p10_result <= p10_result_comb;
  end
  assign out = p10_result;
endmodule
