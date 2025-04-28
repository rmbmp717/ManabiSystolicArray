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
  wire p1_eq_899_comb;
  wire p1_eq_900_comb;
  wire p1_eq_901_comb;
  wire p1_eq_902_comb;
  wire [21:0] p1_frac_mult_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire p1_leading_bit_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire p1_round_bit_comb;
  wire p1_sticky_bit_comb;
  wire [10:0] p1_frac_adjusted_comb;
  wire p1_guard_bit_comb;
  wire [5:0] p1_add_894_comb;
  wire p1_not_908_comb;
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
  assign p1_eq_899_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_900_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_901_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_902_comb = p1_exp_b_comb == 5'h1f;
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_is_zero_a_comb = p1_eq_869_comb & p1_eq_899_comb;
  assign p1_is_zero_b_comb = p1_eq_870_comb & p1_eq_900_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_901_comb & p1_eq_899_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_902_comb & p1_eq_900_comb;
  assign p1_leading_bit_comb = p1_frac_mult_comb[21];
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_901_comb | p1_eq_899_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_902_comb | p1_eq_900_comb);
  assign p1_round_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[9] : p1_frac_mult_comb[8];
  assign p1_sticky_bit_comb = p1_frac_mult_comb[7:0] != 8'h00;
  assign p1_frac_adjusted_comb = p1_leading_bit_comb ? p1_frac_mult_comb[21:11] : p1_frac_mult_comb[20:10];
  assign p1_guard_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[10] : p1_frac_mult_comb[9];
  assign p1_add_894_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_not_908_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_870_comb & p1_eq_900_comb | p1_eq_869_comb & p1_eq_899_comb & p1_is_inf_b_chk_comb;

  // Registers for pipe stage 1:
  reg p1_leading_bit;
  reg p1_round_bit;
  reg p1_sticky_bit;
  reg [10:0] p1_frac_adjusted;
  reg p1_guard_bit;
  reg [5:0] p1_add_894;
  reg p1_is_inf_a_chk;
  reg p1_is_inf_b_chk;
  reg p1_not_908;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_leading_bit <= p1_leading_bit_comb;
    p1_round_bit <= p1_round_bit_comb;
    p1_sticky_bit <= p1_sticky_bit_comb;
    p1_frac_adjusted <= p1_frac_adjusted_comb;
    p1_guard_bit <= p1_guard_bit_comb;
    p1_add_894 <= p1_add_894_comb;
    p1_is_inf_a_chk <= p1_is_inf_a_chk_comb;
    p1_is_inf_b_chk <= p1_is_inf_b_chk_comb;
    p1_not_908 <= p1_not_908_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_round_condition_comb;
  wire [11:0] p2_frac_adjusted_12_comb;
  wire [11:0] p2_one_12__1_comb;
  wire [11:0] p2_frac_no_of_12_comb;
  wire p2_cond_of_comb;
  wire [10:0] p2_frac_no_of_11_comb;
  wire [10:0] p2_frac_of_shifted_11_comb;
  wire [1:0] p2_concat_956_comb;
  wire [1:0] p2_concat_957_comb;
  wire [10:0] p2_frac_final_11_comb;
  assign p2_round_condition_comb = p1_guard_bit & (p1_round_bit | p1_sticky_bit) | p1_guard_bit & ~p1_round_bit & ~p1_sticky_bit & p1_frac_adjusted[0];
  assign p2_frac_adjusted_12_comb = {1'h0, p1_frac_adjusted};
  assign p2_one_12__1_comb = {11'h000, p2_round_condition_comb};
  assign p2_frac_no_of_12_comb = p2_frac_adjusted_12_comb + p2_one_12__1_comb;
  assign p2_cond_of_comb = p2_frac_no_of_12_comb[11];
  assign p2_frac_no_of_11_comb = p2_frac_no_of_12_comb[10:0];
  assign p2_frac_of_shifted_11_comb = p2_frac_no_of_12_comb[11:1];
  assign p2_concat_956_comb = {1'h0, p1_leading_bit};
  assign p2_concat_957_comb = {1'h0, p2_cond_of_comb};
  assign p2_frac_final_11_comb = p2_cond_of_comb ? p2_frac_of_shifted_11_comb : p2_frac_no_of_11_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg p2_cond_of;
  reg [5:0] p2_add_894;
  reg [1:0] p2_concat_956;
  reg [1:0] p2_concat_957;
  reg [10:0] p2_frac_final_11;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_908;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p1_leading_bit;
    p2_cond_of <= p2_cond_of_comb;
    p2_add_894 <= p1_add_894;
    p2_concat_956 <= p2_concat_956_comb;
    p2_concat_957 <= p2_concat_957_comb;
    p2_frac_final_11 <= p2_frac_final_11_comb;
    p2_is_inf_a_chk <= p1_is_inf_a_chk;
    p2_is_inf_b_chk <= p1_is_inf_b_chk;
    p2_not_908 <= p1_not_908;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire [6:0] p3_concat_986_comb;
  wire [1:0] p3_add_991_comb;
  wire [6:0] p3_add_993_comb;
  wire [5:0] p3_add_994_comb;
  wire [6:0] p3_add_999_comb;
  wire [7:0] p3_add_1000_comb;
  wire [4:0] p3_exp_out_5_comb;
  wire [31:0] p3_frac_final_32_comb;
  wire [8:0] p3_shift_9_comb;
  wire [31:0] p3_frac_subnormal_32_comb;
  wire [9:0] p3_frac_out_10_comb;
  wire p3_sign_comb;
  wire p3_nor_1015_comb;
  wire p3_nor_1016_comb;
  wire [9:0] p3_frac_subnormal_comb;
  wire [14:0] p3_concat_1019_comb;
  assign p3_concat_986_comb = {1'h0, p2_add_894};
  assign p3_add_991_comb = p2_concat_956 + p2_concat_957;
  assign p3_add_993_comb = p3_concat_986_comb + {6'h00, p2_leading_bit};
  assign p3_add_994_comb = {5'h00, p2_cond_of} + 6'h31;
  assign p3_add_999_comb = p3_concat_986_comb + {5'h00, p3_add_991_comb};
  assign p3_add_1000_comb = {1'h0, p3_add_993_comb} + {{2{p3_add_994_comb[5]}}, p3_add_994_comb};
  assign p3_exp_out_5_comb = p3_add_1000_comb[4:0];
  assign p3_frac_final_32_comb = {21'h00_0000, p2_frac_final_11};
  assign p3_shift_9_comb = 9'h010 - {2'h0, p3_add_999_comb};
  assign p3_frac_subnormal_32_comb = p3_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p3_frac_final_32_comb >> p3_shift_9_comb;
  assign p3_frac_out_10_comb = p2_frac_final_11[9:0];
  assign p3_sign_comb = p3_add_1000_comb[7];
  assign p3_nor_1015_comb = ~((|p3_add_1000_comb[7:5]) | (&p3_exp_out_5_comb));
  assign p3_nor_1016_comb = ~((|p3_add_1000_comb[7:1]) | p3_add_1000_comb[0]);
  assign p3_frac_subnormal_comb = p3_frac_subnormal_32_comb[9:0];
  assign p3_concat_1019_comb = {p3_exp_out_5_comb, p3_frac_out_10_comb};

  // Registers for pipe stage 3:
  reg p3_sign;
  reg p3_nor_1015;
  reg p3_nor_1016;
  reg [9:0] p3_frac_subnormal;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg [14:0] p3_concat_1019;
  reg p3_not_908;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_sign <= p3_sign_comb;
    p3_nor_1015 <= p3_nor_1015_comb;
    p3_nor_1016 <= p3_nor_1016_comb;
    p3_frac_subnormal <= p3_frac_subnormal_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_concat_1019 <= p3_concat_1019_comb;
    p3_not_908 <= p2_not_908;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire p4_is_subnormal_comb;
  wire p4_is_inf_result_comb;
  wire [15:0] p4_concat_1050_comb;
  wire [15:0] p4_result_comb;
  assign p4_is_subnormal_comb = p3_sign | p3_nor_1016;
  assign p4_is_inf_result_comb = p3_is_inf_a_chk | p3_is_inf_b_chk | ~(p3_sign | p3_nor_1015);
  assign p4_concat_1050_comb = {p3_sign_result, (p4_is_inf_result_comb ? 15'h7c00 : (p4_is_subnormal_comb ? {5'h00, p3_frac_subnormal} : p3_concat_1019)) & {15{p3_not_908}}};
  assign p4_result_comb = p3_is_nan_result ? 16'h7e00 : p4_concat_1050_comb;

  // Registers for pipe stage 4:
  reg [15:0] p4_result;
  always @ (posedge clk) begin
    p4_result <= p4_result_comb;
  end
  assign out = p4_result;
endmodule
