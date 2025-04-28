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
  wire p1_leading_a_comb;
  wire [9:0] p1_frac_a_raw_comb;
  wire p1_leading_b_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire [10:0] p1_concat_875_comb;
  wire [10:0] p1_concat_876_comb;
  wire [5:0] p1_add_881_comb;
  wire p1_eq_886_comb;
  wire p1_eq_887_comb;
  wire p1_eq_888_comb;
  wire p1_eq_889_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_869_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_870_comb = p1_exp_b_comb == 5'h00;
  assign p1_leading_a_comb = ~p1_eq_869_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_870_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_concat_875_comb = {p1_leading_a_comb, p1_frac_a_raw_comb};
  assign p1_concat_876_comb = {p1_leading_b_comb, p1_frac_b_raw_comb};
  assign p1_add_881_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_886_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_887_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_888_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_889_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_869;
  reg p1_eq_870;
  reg [10:0] p1_concat_875;
  reg [10:0] p1_concat_876;
  reg [5:0] p1_add_881;
  reg p1_eq_886;
  reg p1_eq_887;
  reg p1_eq_888;
  reg p1_eq_889;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_869 <= p1_eq_869_comb;
    p1_eq_870 <= p1_eq_870_comb;
    p1_concat_875 <= p1_concat_875_comb;
    p1_concat_876 <= p1_concat_876_comb;
    p1_add_881 <= p1_add_881_comb;
    p1_eq_886 <= p1_eq_886_comb;
    p1_eq_887 <= p1_eq_887_comb;
    p1_eq_888 <= p1_eq_888_comb;
    p1_eq_889 <= p1_eq_889_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire [21:0] p2_frac_mult_comb;
  wire p2_leading_bit_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire p2_guard_bit_comb;
  wire p2_or_926_comb;
  wire p2_not_927_comb;
  wire p2_not_928_comb;
  wire p2_bit_slice_929_comb;
  wire p2_not_935_comb;
  wire p2_is_nan_result_comb;
  assign p2_frac_mult_comb = umul22b_11b_x_11b(p1_concat_875, p1_concat_876);
  assign p2_leading_bit_comb = p2_frac_mult_comb[21];
  assign p2_is_zero_a_comb = p1_eq_869 & p1_eq_886;
  assign p2_is_zero_b_comb = p1_eq_870 & p1_eq_887;
  assign p2_is_inf_a_chk_comb = p1_eq_888 & p1_eq_886;
  assign p2_is_inf_b_chk_comb = p1_eq_889 & p1_eq_887;
  assign p2_round_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[9] : p2_frac_mult_comb[8];
  assign p2_sticky_bit_comb = p2_frac_mult_comb[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p2_frac_mult_comb[21:11] : p2_frac_mult_comb[20:10];
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_888 | p1_eq_886);
  assign p2_is_nan__1_comb = ~(~p1_eq_889 | p1_eq_887);
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[10] : p2_frac_mult_comb[9];
  assign p2_or_926_comb = p2_round_bit_comb | p2_sticky_bit_comb;
  assign p2_not_927_comb = ~p2_round_bit_comb;
  assign p2_not_928_comb = ~p2_sticky_bit_comb;
  assign p2_bit_slice_929_comb = p2_frac_adjusted_comb[0];
  assign p2_not_935_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_a_chk_comb & p1_eq_870 & p1_eq_887 | p1_eq_869 & p1_eq_886 & p2_is_inf_b_chk_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg [10:0] p2_frac_adjusted;
  reg p2_guard_bit;
  reg p2_or_926;
  reg p2_not_927;
  reg p2_not_928;
  reg p2_bit_slice_929;
  reg [5:0] p2_add_881;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_935;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_guard_bit <= p2_guard_bit_comb;
    p2_or_926 <= p2_or_926_comb;
    p2_not_927 <= p2_not_927_comb;
    p2_not_928 <= p2_not_928_comb;
    p2_bit_slice_929 <= p2_bit_slice_929_comb;
    p2_add_881 <= p1_add_881;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_935 <= p2_not_935_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire p3_round_condition_comb;
  wire [11:0] p3_frac_adjusted_12_comb;
  wire [11:0] p3_one_12__1_comb;
  wire [11:0] p3_frac_no_of_12_comb;
  assign p3_round_condition_comb = p2_guard_bit & p2_or_926 | p2_guard_bit & p2_not_927 & p2_not_928 & p2_bit_slice_929;
  assign p3_frac_adjusted_12_comb = {1'h0, p2_frac_adjusted};
  assign p3_one_12__1_comb = {11'h000, p3_round_condition_comb};
  assign p3_frac_no_of_12_comb = p3_frac_adjusted_12_comb + p3_one_12__1_comb;

  // Registers for pipe stage 3:
  reg p3_leading_bit;
  reg [11:0] p3_frac_no_of_12;
  reg [5:0] p3_add_881;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_935;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_leading_bit <= p2_leading_bit;
    p3_frac_no_of_12 <= p3_frac_no_of_12_comb;
    p3_add_881 <= p2_add_881;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_935 <= p2_not_935;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire p4_cond_of_comb;
  wire [6:0] p4_concat_1001_comb;
  wire [1:0] p4_add_1006_comb;
  wire [10:0] p4_frac_no_of_11_comb;
  wire [10:0] p4_frac_of_shifted_11_comb;
  wire [6:0] p4_add_1007_comb;
  wire [5:0] p4_add_1008_comb;
  wire [6:0] p4_concat_1009_comb;
  wire [10:0] p4_frac_final_11_comb;
  assign p4_cond_of_comb = p3_frac_no_of_12[11];
  assign p4_concat_1001_comb = {1'h0, p3_add_881};
  assign p4_add_1006_comb = {1'h0, p3_leading_bit} + {1'h0, p4_cond_of_comb};
  assign p4_frac_no_of_11_comb = p3_frac_no_of_12[10:0];
  assign p4_frac_of_shifted_11_comb = p3_frac_no_of_12[11:1];
  assign p4_add_1007_comb = p4_concat_1001_comb + {6'h00, p3_leading_bit};
  assign p4_add_1008_comb = {5'h00, p4_cond_of_comb} + 6'h31;
  assign p4_concat_1009_comb = {5'h00, p4_add_1006_comb};
  assign p4_frac_final_11_comb = p4_cond_of_comb ? p4_frac_of_shifted_11_comb : p4_frac_no_of_11_comb;

  // Registers for pipe stage 4:
  reg [6:0] p4_concat_1001;
  reg [6:0] p4_add_1007;
  reg [5:0] p4_add_1008;
  reg [6:0] p4_concat_1009;
  reg [10:0] p4_frac_final_11;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg p4_not_935;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_concat_1001 <= p4_concat_1001_comb;
    p4_add_1007 <= p4_add_1007_comb;
    p4_add_1008 <= p4_add_1008_comb;
    p4_concat_1009 <= p4_concat_1009_comb;
    p4_frac_final_11 <= p4_frac_final_11_comb;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_not_935 <= p3_not_935;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [6:0] p5_add_1037_comb;
  wire [7:0] p5_add_1038_comb;
  wire [4:0] p5_exp_out_5_comb;
  wire [31:0] p5_frac_final_32_comb;
  wire [8:0] p5_shift_9_comb;
  wire [9:0] p5_frac_out_10_comb;
  wire p5_or_reduce_1047_comb;
  wire p5_and_reduce_1048_comb;
  wire p5_or_reduce_1049_comb;
  wire p5_bit_slice_1050_comb;
  wire [31:0] p5_frac_subnormal_32_comb;
  wire p5_sign_comb;
  wire [14:0] p5_concat_1054_comb;
  assign p5_add_1037_comb = p4_concat_1001 + p4_concat_1009;
  assign p5_add_1038_comb = {1'h0, p4_add_1007} + {{2{p4_add_1008[5]}}, p4_add_1008};
  assign p5_exp_out_5_comb = p5_add_1038_comb[4:0];
  assign p5_frac_final_32_comb = {21'h00_0000, p4_frac_final_11};
  assign p5_shift_9_comb = 9'h010 - {2'h0, p5_add_1037_comb};
  assign p5_frac_out_10_comb = p4_frac_final_11[9:0];
  assign p5_or_reduce_1047_comb = |p5_add_1038_comb[7:5];
  assign p5_and_reduce_1048_comb = &p5_exp_out_5_comb;
  assign p5_or_reduce_1049_comb = |p5_add_1038_comb[7:1];
  assign p5_bit_slice_1050_comb = p5_add_1038_comb[0];
  assign p5_frac_subnormal_32_comb = p5_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p5_frac_final_32_comb >> p5_shift_9_comb;
  assign p5_sign_comb = p5_add_1038_comb[7];
  assign p5_concat_1054_comb = {p5_exp_out_5_comb, p5_frac_out_10_comb};

  // Registers for pipe stage 5:
  reg p5_or_reduce_1047;
  reg p5_and_reduce_1048;
  reg p5_or_reduce_1049;
  reg p5_bit_slice_1050;
  reg [31:0] p5_frac_subnormal_32;
  reg p5_sign;
  reg p5_is_inf_a_chk;
  reg p5_is_inf_b_chk;
  reg [14:0] p5_concat_1054;
  reg p5_not_935;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_or_reduce_1047 <= p5_or_reduce_1047_comb;
    p5_and_reduce_1048 <= p5_and_reduce_1048_comb;
    p5_or_reduce_1049 <= p5_or_reduce_1049_comb;
    p5_bit_slice_1050 <= p5_bit_slice_1050_comb;
    p5_frac_subnormal_32 <= p5_frac_subnormal_32_comb;
    p5_sign <= p5_sign_comb;
    p5_is_inf_a_chk <= p4_is_inf_a_chk;
    p5_is_inf_b_chk <= p4_is_inf_b_chk;
    p5_concat_1054 <= p5_concat_1054_comb;
    p5_not_935 <= p4_not_935;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [9:0] p6_frac_subnormal_comb;
  wire p6_is_subnormal_comb;
  wire p6_is_inf_result_comb;
  wire [14:0] p6_sel_1089_comb;
  assign p6_frac_subnormal_comb = p5_frac_subnormal_32[9:0];
  assign p6_is_subnormal_comb = p5_sign | ~(p5_or_reduce_1049 | p5_bit_slice_1050);
  assign p6_is_inf_result_comb = p5_is_inf_a_chk | p5_is_inf_b_chk | ~(p5_sign | ~(p5_or_reduce_1047 | p5_and_reduce_1048));
  assign p6_sel_1089_comb = p6_is_inf_result_comb ? 15'h7c00 : (p6_is_subnormal_comb ? {5'h00, p6_frac_subnormal_comb} : p5_concat_1054);

  // Registers for pipe stage 6:
  reg p6_not_935;
  reg [14:0] p6_sel_1089;
  reg p6_sign_result;
  reg p6_is_nan_result;
  always @ (posedge clk) begin
    p6_not_935 <= p5_not_935;
    p6_sel_1089 <= p6_sel_1089_comb;
    p6_sign_result <= p5_sign_result;
    p6_is_nan_result <= p5_is_nan_result;
  end

  // ===== Pipe stage 7:
  wire [15:0] p7_result_comb;
  assign p7_result_comb = p6_is_nan_result ? 16'h7e00 : {p6_sign_result, p6_sel_1089 & {15{p6_not_935}}};

  // Registers for pipe stage 7:
  reg [15:0] p7_result;
  always @ (posedge clk) begin
    p7_result <= p7_result_comb;
  end
  assign out = p7_result;
endmodule
