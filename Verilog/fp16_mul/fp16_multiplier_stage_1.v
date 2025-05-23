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
  wire p1_round_bit_comb;
  wire p1_sticky_bit_comb;
  wire [10:0] p1_frac_adjusted_comb;
  wire p1_guard_bit_comb;
  wire p1_round_condition_comb;
  wire [11:0] p1_frac_adjusted_12_comb;
  wire [11:0] p1_one_12__1_comb;
  wire [11:0] p1_frac_no_of_12_comb;
  wire p1_cond_of_comb;
  wire [5:0] p1_add_910_comb;
  wire [6:0] p1_concat_915_comb;
  wire [1:0] p1_add_920_comb;
  wire [6:0] p1_add_922_comb;
  wire [5:0] p1_add_923_comb;
  wire [10:0] p1_frac_no_of_11_comb;
  wire [10:0] p1_frac_of_shifted_11_comb;
  wire [6:0] p1_add_930_comb;
  wire [7:0] p1_add_931_comb;
  wire [10:0] p1_frac_final_11_comb;
  wire [4:0] p1_exp_out_5_comb;
  wire [31:0] p1_frac_final_32_comb;
  wire [8:0] p1_shift_9_comb;
  wire [31:0] p1_frac_subnormal_32_comb;
  wire p1_eq_950_comb;
  wire p1_eq_951_comb;
  wire p1_eq_952_comb;
  wire p1_eq_953_comb;
  wire p1_sign_comb;
  wire [9:0] p1_frac_out_10_comb;
  wire [9:0] p1_frac_subnormal_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire p1_is_subnormal_comb;
  wire p1_is_zero_result_comb;
  wire p1_is_inf_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  wire [15:0] p1_concat_986_comb;
  wire [15:0] p1_result_comb;
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
  assign p1_round_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[9] : p1_frac_mult_comb[8];
  assign p1_sticky_bit_comb = p1_frac_mult_comb[7:0] != 8'h00;
  assign p1_frac_adjusted_comb = p1_leading_bit_comb ? p1_frac_mult_comb[21:11] : p1_frac_mult_comb[20:10];
  assign p1_guard_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[10] : p1_frac_mult_comb[9];
  assign p1_round_condition_comb = p1_guard_bit_comb & (p1_round_bit_comb | p1_sticky_bit_comb) | p1_guard_bit_comb & ~p1_round_bit_comb & ~p1_sticky_bit_comb & p1_frac_adjusted_comb[0];
  assign p1_frac_adjusted_12_comb = {1'h0, p1_frac_adjusted_comb};
  assign p1_one_12__1_comb = {11'h000, p1_round_condition_comb};
  assign p1_frac_no_of_12_comb = p1_frac_adjusted_12_comb + p1_one_12__1_comb;
  assign p1_cond_of_comb = p1_frac_no_of_12_comb[11];
  assign p1_add_910_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_concat_915_comb = {1'h0, p1_add_910_comb};
  assign p1_add_920_comb = {1'h0, p1_leading_bit_comb} + {1'h0, p1_cond_of_comb};
  assign p1_add_922_comb = p1_concat_915_comb + {6'h00, p1_leading_bit_comb};
  assign p1_add_923_comb = {5'h00, p1_cond_of_comb} + 6'h31;
  assign p1_frac_no_of_11_comb = p1_frac_no_of_12_comb[10:0];
  assign p1_frac_of_shifted_11_comb = p1_frac_no_of_12_comb[11:1];
  assign p1_add_930_comb = p1_concat_915_comb + {5'h00, p1_add_920_comb};
  assign p1_add_931_comb = {1'h0, p1_add_922_comb} + {{2{p1_add_923_comb[5]}}, p1_add_923_comb};
  assign p1_frac_final_11_comb = p1_cond_of_comb ? p1_frac_of_shifted_11_comb : p1_frac_no_of_11_comb;
  assign p1_exp_out_5_comb = p1_add_931_comb[4:0];
  assign p1_frac_final_32_comb = {21'h00_0000, p1_frac_final_11_comb};
  assign p1_shift_9_comb = 9'h010 - {2'h0, p1_add_930_comb};
  assign p1_frac_subnormal_32_comb = p1_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p1_frac_final_32_comb >> p1_shift_9_comb;
  assign p1_eq_950_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_951_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_952_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_953_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_comb = p1_add_931_comb[7];
  assign p1_frac_out_10_comb = p1_frac_final_11_comb[9:0];
  assign p1_frac_subnormal_comb = p1_frac_subnormal_32_comb[9:0];
  assign p1_is_zero_a_comb = p1_eq_869_comb & p1_eq_950_comb;
  assign p1_is_zero_b_comb = p1_eq_870_comb & p1_eq_951_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_952_comb & p1_eq_950_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_953_comb & p1_eq_951_comb;
  assign p1_is_subnormal_comb = p1_sign_comb | ~((|p1_add_931_comb[7:1]) | p1_add_931_comb[0]);
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_is_inf_result_comb = p1_is_inf_a_chk_comb | p1_is_inf_b_chk_comb | ~(p1_sign_comb | ~((|p1_add_931_comb[7:5]) | (&p1_exp_out_5_comb)));
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_952_comb | p1_eq_950_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_953_comb | p1_eq_951_comb);
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_870_comb & p1_eq_951_comb | p1_eq_869_comb & p1_eq_950_comb & p1_is_inf_b_chk_comb;
  assign p1_concat_986_comb = {p1_sign_result_comb, (p1_is_inf_result_comb ? 15'h7c00 : (p1_is_subnormal_comb ? {5'h00, p1_frac_subnormal_comb} : {p1_exp_out_5_comb, p1_frac_out_10_comb})) & {15{~p1_is_zero_result_comb}}};
  assign p1_result_comb = p1_is_nan_result_comb ? 16'h7e00 : p1_concat_986_comb;

  // Registers for pipe stage 1:
  reg [15:0] p1_result;
  always @ (posedge clk) begin
    p1_result <= p1_result_comb;
  end
  assign out = p1_result;
endmodule
