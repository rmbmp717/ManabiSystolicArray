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
  wire [21:0] p1_frac_mult_comb;
  wire p1_leading_bit_comb;
  wire p1_eq_905_comb;
  wire p1_eq_906_comb;
  wire p1_eq_907_comb;
  wire p1_eq_908_comb;
  wire p1_round_bit_comb;
  wire p1_sticky_bit_comb;
  wire [10:0] p1_frac_adjusted_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire p1_guard_bit_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire p1_and_894_comb;
  wire p1_and_895_comb;
  wire [5:0] p1_add_900_comb;
  wire p1_not_914_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_869_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_870_comb = p1_exp_b_comb == 5'h00;
  assign p1_leading_a_comb = ~p1_eq_869_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_870_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_leading_bit_comb = p1_frac_mult_comb[21];
  assign p1_eq_905_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_906_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_907_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_908_comb = p1_exp_b_comb == 5'h1f;
  assign p1_round_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[9] : p1_frac_mult_comb[8];
  assign p1_sticky_bit_comb = p1_frac_mult_comb[7:0] != 8'h00;
  assign p1_frac_adjusted_comb = p1_leading_bit_comb ? p1_frac_mult_comb[21:11] : p1_frac_mult_comb[20:10];
  assign p1_is_zero_a_comb = p1_eq_869_comb & p1_eq_905_comb;
  assign p1_is_zero_b_comb = p1_eq_870_comb & p1_eq_906_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_907_comb & p1_eq_905_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_908_comb & p1_eq_906_comb;
  assign p1_guard_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[10] : p1_frac_mult_comb[9];
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_907_comb | p1_eq_905_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_908_comb | p1_eq_906_comb);
  assign p1_and_894_comb = p1_guard_bit_comb & (p1_round_bit_comb | p1_sticky_bit_comb);
  assign p1_and_895_comb = p1_guard_bit_comb & ~p1_round_bit_comb & ~p1_sticky_bit_comb & p1_frac_adjusted_comb[0];
  assign p1_add_900_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_not_914_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_870_comb & p1_eq_906_comb | p1_eq_869_comb & p1_eq_905_comb & p1_is_inf_b_chk_comb;

  // Registers for pipe stage 1:
  reg p1_leading_bit;
  reg [10:0] p1_frac_adjusted;
  reg p1_and_894;
  reg p1_and_895;
  reg [5:0] p1_add_900;
  reg p1_is_inf_a_chk;
  reg p1_is_inf_b_chk;
  reg p1_not_914;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_leading_bit <= p1_leading_bit_comb;
    p1_frac_adjusted <= p1_frac_adjusted_comb;
    p1_and_894 <= p1_and_894_comb;
    p1_and_895 <= p1_and_895_comb;
    p1_add_900 <= p1_add_900_comb;
    p1_is_inf_a_chk <= p1_is_inf_a_chk_comb;
    p1_is_inf_b_chk <= p1_is_inf_b_chk_comb;
    p1_not_914 <= p1_not_914_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_round_condition_comb;
  wire [11:0] p2_frac_adjusted_12_comb;
  wire [11:0] p2_one_12__1_comb;
  wire [11:0] p2_frac_no_of_12_comb;
  wire p2_cond_of_comb;
  wire [6:0] p2_concat_959_comb;
  wire [1:0] p2_add_964_comb;
  wire [6:0] p2_add_966_comb;
  wire [5:0] p2_add_967_comb;
  wire [10:0] p2_frac_no_of_11_comb;
  wire [10:0] p2_frac_of_shifted_11_comb;
  wire [6:0] p2_add_974_comb;
  wire [7:0] p2_add_975_comb;
  wire [10:0] p2_frac_final_11_comb;
  wire [8:0] p2_concat_977_comb;
  assign p2_round_condition_comb = p1_and_894 | p1_and_895;
  assign p2_frac_adjusted_12_comb = {1'h0, p1_frac_adjusted};
  assign p2_one_12__1_comb = {11'h000, p2_round_condition_comb};
  assign p2_frac_no_of_12_comb = p2_frac_adjusted_12_comb + p2_one_12__1_comb;
  assign p2_cond_of_comb = p2_frac_no_of_12_comb[11];
  assign p2_concat_959_comb = {1'h0, p1_add_900};
  assign p2_add_964_comb = {1'h0, p1_leading_bit} + {1'h0, p2_cond_of_comb};
  assign p2_add_966_comb = p2_concat_959_comb + {6'h00, p1_leading_bit};
  assign p2_add_967_comb = {5'h00, p2_cond_of_comb} + 6'h31;
  assign p2_frac_no_of_11_comb = p2_frac_no_of_12_comb[10:0];
  assign p2_frac_of_shifted_11_comb = p2_frac_no_of_12_comb[11:1];
  assign p2_add_974_comb = p2_concat_959_comb + {5'h00, p2_add_964_comb};
  assign p2_add_975_comb = {1'h0, p2_add_966_comb} + {{2{p2_add_967_comb[5]}}, p2_add_967_comb};
  assign p2_frac_final_11_comb = p2_cond_of_comb ? p2_frac_of_shifted_11_comb : p2_frac_no_of_11_comb;
  assign p2_concat_977_comb = {2'h0, p2_add_974_comb};

  // Registers for pipe stage 2:
  reg [7:0] p2_add_975;
  reg [10:0] p2_frac_final_11;
  reg [8:0] p2_concat_977;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_914;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_add_975 <= p2_add_975_comb;
    p2_frac_final_11 <= p2_frac_final_11_comb;
    p2_concat_977 <= p2_concat_977_comb;
    p2_is_inf_a_chk <= p1_is_inf_a_chk;
    p2_is_inf_b_chk <= p1_is_inf_b_chk;
    p2_not_914 <= p1_not_914;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire [4:0] p3_exp_out_5_comb;
  wire [31:0] p3_frac_final_32_comb;
  wire [8:0] p3_shift_9_comb;
  wire [31:0] p3_frac_subnormal_32_comb;
  wire p3_sign_comb;
  wire [9:0] p3_frac_out_10_comb;
  wire [9:0] p3_frac_subnormal_comb;
  wire p3_is_subnormal_comb;
  wire p3_is_inf_result_comb;
  wire [15:0] p3_concat_1022_comb;
  wire [15:0] p3_result_comb;
  assign p3_exp_out_5_comb = p2_add_975[4:0];
  assign p3_frac_final_32_comb = {21'h00_0000, p2_frac_final_11};
  assign p3_shift_9_comb = 9'h010 - p2_concat_977;
  assign p3_frac_subnormal_32_comb = p3_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p3_frac_final_32_comb >> p3_shift_9_comb;
  assign p3_sign_comb = p2_add_975[7];
  assign p3_frac_out_10_comb = p2_frac_final_11[9:0];
  assign p3_frac_subnormal_comb = p3_frac_subnormal_32_comb[9:0];
  assign p3_is_subnormal_comb = p3_sign_comb | ~((|p2_add_975[7:1]) | p2_add_975[0]);
  assign p3_is_inf_result_comb = p2_is_inf_a_chk | p2_is_inf_b_chk | ~(p3_sign_comb | ~((|p2_add_975[7:5]) | (&p3_exp_out_5_comb)));
  assign p3_concat_1022_comb = {p2_sign_result, (p3_is_inf_result_comb ? 15'h7c00 : (p3_is_subnormal_comb ? {5'h00, p3_frac_subnormal_comb} : {p3_exp_out_5_comb, p3_frac_out_10_comb})) & {15{p2_not_914}}};
  assign p3_result_comb = p2_is_nan_result ? 16'h7e00 : p3_concat_1022_comb;

  // Registers for pipe stage 3:
  reg [15:0] p3_result;
  always @ (posedge clk) begin
    p3_result <= p3_result_comb;
  end
  assign out = p3_result;
endmodule
