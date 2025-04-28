`timescale 1ns / 1ps
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
  wire p1_leading_a_comb;
  wire p1_leading_b_comb;
  wire p1_eq_894_comb;
  wire p1_eq_895_comb;
  wire p1_eq_896_comb;
  wire p1_eq_897_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire [21:0] p1_frac_mult_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire p1_leading_bit_comb;
  wire p1_bit_slice_879_comb;
  wire p1_bit_slice_880_comb;
  wire [7:0] p1_bit_slice_881_comb;
  wire [10:0] p1_bit_slice_882_comb;
  wire [10:0] p1_bit_slice_883_comb;
  wire p1_bit_slice_884_comb;
  wire [5:0] p1_add_889_comb;
  wire p1_not_903_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_869_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_870_comb = p1_exp_b_comb == 5'h00;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_leading_a_comb = ~p1_eq_869_comb;
  assign p1_leading_b_comb = ~p1_eq_870_comb;
  assign p1_eq_894_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_895_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_896_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_897_comb = p1_exp_b_comb == 5'h1f;
  assign p1_is_zero_a_comb = p1_eq_869_comb & p1_eq_894_comb;
  assign p1_is_zero_b_comb = p1_eq_870_comb & p1_eq_895_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_896_comb & p1_eq_894_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_897_comb & p1_eq_895_comb;
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_896_comb | p1_eq_894_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_897_comb | p1_eq_895_comb);
  assign p1_leading_bit_comb = p1_frac_mult_comb[21];
  assign p1_bit_slice_879_comb = p1_frac_mult_comb[8];
  assign p1_bit_slice_880_comb = p1_frac_mult_comb[9];
  assign p1_bit_slice_881_comb = p1_frac_mult_comb[7:0];
  assign p1_bit_slice_882_comb = p1_frac_mult_comb[20:10];
  assign p1_bit_slice_883_comb = p1_frac_mult_comb[21:11];
  assign p1_bit_slice_884_comb = p1_frac_mult_comb[10];
  assign p1_add_889_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_not_903_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_870_comb & p1_eq_895_comb | p1_eq_869_comb & p1_eq_894_comb & p1_is_inf_b_chk_comb;

  // Registers for pipe stage 1:
  reg p1_leading_bit;
  reg p1_bit_slice_879;
  reg p1_bit_slice_880;
  reg [7:0] p1_bit_slice_881;
  reg [10:0] p1_bit_slice_882;
  reg [10:0] p1_bit_slice_883;
  reg p1_bit_slice_884;
  reg [5:0] p1_add_889;
  reg p1_is_inf_a_chk;
  reg p1_is_inf_b_chk;
  reg p1_not_903;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_leading_bit <= p1_leading_bit_comb;
    p1_bit_slice_879 <= p1_bit_slice_879_comb;
    p1_bit_slice_880 <= p1_bit_slice_880_comb;
    p1_bit_slice_881 <= p1_bit_slice_881_comb;
    p1_bit_slice_882 <= p1_bit_slice_882_comb;
    p1_bit_slice_883 <= p1_bit_slice_883_comb;
    p1_bit_slice_884 <= p1_bit_slice_884_comb;
    p1_add_889 <= p1_add_889_comb;
    p1_is_inf_a_chk <= p1_is_inf_a_chk_comb;
    p1_is_inf_b_chk <= p1_is_inf_b_chk_comb;
    p1_not_903 <= p1_not_903_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_guard_bit_comb;
  wire p2_round_condition_comb;
  wire [11:0] p2_frac_adjusted_12_comb;
  wire [11:0] p2_one_12__1_comb;
  wire [11:0] p2_frac_no_of_12_comb;
  assign p2_round_bit_comb = p1_leading_bit ? p1_bit_slice_880 : p1_bit_slice_879;
  assign p2_sticky_bit_comb = p1_bit_slice_881 != 8'h00;
  assign p2_frac_adjusted_comb = p1_leading_bit ? p1_bit_slice_883 : p1_bit_slice_882;
  assign p2_guard_bit_comb = p1_leading_bit ? p1_bit_slice_884 : p1_bit_slice_880;
  assign p2_round_condition_comb = p2_guard_bit_comb & (p2_round_bit_comb | p2_sticky_bit_comb) | p2_guard_bit_comb & ~p2_round_bit_comb & ~p2_sticky_bit_comb & p2_frac_adjusted_comb[0];
  assign p2_frac_adjusted_12_comb = {1'h0, p2_frac_adjusted_comb};
  assign p2_one_12__1_comb = {11'h000, p2_round_condition_comb};
  assign p2_frac_no_of_12_comb = p2_frac_adjusted_12_comb + p2_one_12__1_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg [11:0] p2_frac_no_of_12;
  reg [5:0] p2_add_889;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_903;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p1_leading_bit;
    p2_frac_no_of_12 <= p2_frac_no_of_12_comb;
    p2_add_889 <= p1_add_889;
    p2_is_inf_a_chk <= p1_is_inf_a_chk;
    p2_is_inf_b_chk <= p1_is_inf_b_chk;
    p2_not_903 <= p1_not_903;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire p3_cond_of_comb;
  wire [6:0] p3_concat_981_comb;
  wire [1:0] p3_add_986_comb;
  wire [6:0] p3_add_988_comb;
  wire [5:0] p3_add_989_comb;
  wire [10:0] p3_frac_no_of_11_comb;
  wire [10:0] p3_frac_of_shifted_11_comb;
  wire [6:0] p3_add_995_comb;
  wire [7:0] p3_add_996_comb;
  wire [10:0] p3_frac_final_11_comb;
  assign p3_cond_of_comb = p2_frac_no_of_12[11];
  assign p3_concat_981_comb = {1'h0, p2_add_889};
  assign p3_add_986_comb = {1'h0, p2_leading_bit} + {1'h0, p3_cond_of_comb};
  assign p3_add_988_comb = p3_concat_981_comb + {6'h00, p2_leading_bit};
  assign p3_add_989_comb = {5'h00, p3_cond_of_comb} + 6'h31;
  assign p3_frac_no_of_11_comb = p2_frac_no_of_12[10:0];
  assign p3_frac_of_shifted_11_comb = p2_frac_no_of_12[11:1];
  assign p3_add_995_comb = p3_concat_981_comb + {5'h00, p3_add_986_comb};
  assign p3_add_996_comb = {1'h0, p3_add_988_comb} + {{2{p3_add_989_comb[5]}}, p3_add_989_comb};
  assign p3_frac_final_11_comb = p3_cond_of_comb ? p3_frac_of_shifted_11_comb : p3_frac_no_of_11_comb;

  // Registers for pipe stage 3:
  reg [6:0] p3_add_995;
  reg [7:0] p3_add_996;
  reg [10:0] p3_frac_final_11;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_903;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_add_995 <= p3_add_995_comb;
    p3_add_996 <= p3_add_996_comb;
    p3_frac_final_11 <= p3_frac_final_11_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_903 <= p2_not_903;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [4:0] p4_exp_out_5_comb;
  wire [31:0] p4_frac_final_32_comb;
  wire [8:0] p4_shift_9_comb;
  wire [31:0] p4_frac_subnormal_32_comb;
  wire p4_sign_comb;
  wire [9:0] p4_frac_out_10_comb;
  wire [9:0] p4_frac_subnormal_comb;
  wire p4_is_subnormal_comb;
  wire p4_is_inf_result_comb;
  wire [14:0] p4_sel_1039_comb;
  assign p4_exp_out_5_comb = p3_add_996[4:0];
  assign p4_frac_final_32_comb = {21'h00_0000, p3_frac_final_11};
  assign p4_shift_9_comb = 9'h010 - {2'h0, p3_add_995};
  assign p4_frac_subnormal_32_comb = p4_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p4_frac_final_32_comb >> p4_shift_9_comb;
  assign p4_sign_comb = p3_add_996[7];
  assign p4_frac_out_10_comb = p3_frac_final_11[9:0];
  assign p4_frac_subnormal_comb = p4_frac_subnormal_32_comb[9:0];
  assign p4_is_subnormal_comb = p4_sign_comb | ~((|p3_add_996[7:1]) | p3_add_996[0]);
  assign p4_is_inf_result_comb = p3_is_inf_a_chk | p3_is_inf_b_chk | ~(p4_sign_comb | ~((|p3_add_996[7:5]) | (&p4_exp_out_5_comb)));
  assign p4_sel_1039_comb = p4_is_subnormal_comb ? {5'h00, p4_frac_subnormal_comb} : {p4_exp_out_5_comb, p4_frac_out_10_comb};

  // Registers for pipe stage 4:
  reg p4_is_inf_result;
  reg [14:0] p4_sel_1039;
  reg p4_not_903;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_is_inf_result <= p4_is_inf_result_comb;
    p4_sel_1039 <= p4_sel_1039_comb;
    p4_not_903 <= p3_not_903;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [15:0] p5_result_comb;
  assign p5_result_comb = p4_is_nan_result ? 16'h7e00 : {p4_sign_result, (p4_is_inf_result ? 15'h7c00 : p4_sel_1039) & {15{p4_not_903}}};

  // Registers for pipe stage 5:
  reg [15:0] p5_result;
  always @ (posedge clk) begin
    p5_result <= p5_result_comb;
  end
  assign out = p5_result;
endmodule
