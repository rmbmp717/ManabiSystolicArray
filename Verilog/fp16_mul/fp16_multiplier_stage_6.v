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
  wire [9:0] p1_frac_a_raw_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire p1_eq_869_comb;
  wire p1_eq_870_comb;
  wire p1_eq_887_comb;
  wire p1_eq_888_comb;
  wire p1_eq_889_comb;
  wire p1_eq_890_comb;
  wire p1_leading_a_comb;
  wire p1_leading_b_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire [21:0] p1_frac_mult_comb;
  wire [5:0] p1_add_882_comb;
  wire p1_not_896_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_eq_869_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_870_comb = p1_exp_b_comb == 5'h00;
  assign p1_eq_887_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_888_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_889_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_890_comb = p1_exp_b_comb == 5'h1f;
  assign p1_leading_a_comb = ~p1_eq_869_comb;
  assign p1_leading_b_comb = ~p1_eq_870_comb;
  assign p1_is_zero_a_comb = p1_eq_869_comb & p1_eq_887_comb;
  assign p1_is_zero_b_comb = p1_eq_870_comb & p1_eq_888_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_889_comb & p1_eq_887_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_890_comb & p1_eq_888_comb;
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_889_comb | p1_eq_887_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_890_comb | p1_eq_888_comb);
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_add_882_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_not_896_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_870_comb & p1_eq_888_comb | p1_eq_869_comb & p1_eq_887_comb & p1_is_inf_b_chk_comb;

  // Registers for pipe stage 1:
  reg [21:0] p1_frac_mult;
  reg [5:0] p1_add_882;
  reg p1_is_inf_a_chk;
  reg p1_is_inf_b_chk;
  reg p1_not_896;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_frac_mult <= p1_frac_mult_comb;
    p1_add_882 <= p1_add_882_comb;
    p1_is_inf_a_chk <= p1_is_inf_a_chk_comb;
    p1_is_inf_b_chk <= p1_is_inf_b_chk_comb;
    p1_not_896 <= p1_not_896_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_leading_bit_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_guard_bit_comb;
  wire p2_round_condition_comb;
  assign p2_leading_bit_comb = p1_frac_mult[21];
  assign p2_round_bit_comb = p2_leading_bit_comb ? p1_frac_mult[9] : p1_frac_mult[8];
  assign p2_sticky_bit_comb = p1_frac_mult[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p1_frac_mult[21:11] : p1_frac_mult[20:10];
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p1_frac_mult[10] : p1_frac_mult[9];
  assign p2_round_condition_comb = p2_guard_bit_comb & (p2_round_bit_comb | p2_sticky_bit_comb) | p2_guard_bit_comb & ~p2_round_bit_comb & ~p2_sticky_bit_comb & p2_frac_adjusted_comb[0];

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg [10:0] p2_frac_adjusted;
  reg p2_round_condition;
  reg [5:0] p2_add_882;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_896;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_round_condition <= p2_round_condition_comb;
    p2_add_882 <= p1_add_882;
    p2_is_inf_a_chk <= p1_is_inf_a_chk;
    p2_is_inf_b_chk <= p1_is_inf_b_chk;
    p2_not_896 <= p1_not_896;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire [11:0] p3_frac_adjusted_12_comb;
  wire [11:0] p3_one_12__1_comb;
  wire [11:0] p3_frac_no_of_12_comb;
  wire p3_cond_of_comb;
  wire [10:0] p3_frac_no_of_11_comb;
  wire [10:0] p3_frac_of_shifted_11_comb;
  wire [10:0] p3_frac_final_11_comb;
  assign p3_frac_adjusted_12_comb = {1'h0, p2_frac_adjusted};
  assign p3_one_12__1_comb = {11'h000, p2_round_condition};
  assign p3_frac_no_of_12_comb = p3_frac_adjusted_12_comb + p3_one_12__1_comb;
  assign p3_cond_of_comb = p3_frac_no_of_12_comb[11];
  assign p3_frac_no_of_11_comb = p3_frac_no_of_12_comb[10:0];
  assign p3_frac_of_shifted_11_comb = p3_frac_no_of_12_comb[11:1];
  assign p3_frac_final_11_comb = p3_cond_of_comb ? p3_frac_of_shifted_11_comb : p3_frac_no_of_11_comb;

  // Registers for pipe stage 3:
  reg p3_leading_bit;
  reg p3_cond_of;
  reg [5:0] p3_add_882;
  reg [10:0] p3_frac_final_11;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_896;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_leading_bit <= p2_leading_bit;
    p3_cond_of <= p3_cond_of_comb;
    p3_add_882 <= p2_add_882;
    p3_frac_final_11 <= p3_frac_final_11_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_896 <= p2_not_896;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [6:0] p4_concat_992_comb;
  wire [1:0] p4_add_997_comb;
  wire [6:0] p4_add_999_comb;
  wire [5:0] p4_add_1000_comb;
  wire [6:0] p4_add_1005_comb;
  wire [7:0] p4_add_1006_comb;
  wire [8:0] p4_concat_1007_comb;
  assign p4_concat_992_comb = {1'h0, p3_add_882};
  assign p4_add_997_comb = {1'h0, p3_leading_bit} + {1'h0, p3_cond_of};
  assign p4_add_999_comb = p4_concat_992_comb + {6'h00, p3_leading_bit};
  assign p4_add_1000_comb = {5'h00, p3_cond_of} + 6'h31;
  assign p4_add_1005_comb = p4_concat_992_comb + {5'h00, p4_add_997_comb};
  assign p4_add_1006_comb = {1'h0, p4_add_999_comb} + {{2{p4_add_1000_comb[5]}}, p4_add_1000_comb};
  assign p4_concat_1007_comb = {2'h0, p4_add_1005_comb};

  // Registers for pipe stage 4:
  reg [7:0] p4_add_1006;
  reg [10:0] p4_frac_final_11;
  reg [8:0] p4_concat_1007;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg p4_not_896;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_add_1006 <= p4_add_1006_comb;
    p4_frac_final_11 <= p3_frac_final_11;
    p4_concat_1007 <= p4_concat_1007_comb;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_not_896 <= p3_not_896;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [4:0] p5_exp_out_5_comb;
  wire [31:0] p5_frac_final_32_comb;
  wire [8:0] p5_shift_9_comb;
  wire [31:0] p5_frac_subnormal_32_comb;
  wire p5_sign_comb;
  wire [9:0] p5_frac_out_10_comb;
  wire [9:0] p5_frac_subnormal_comb;
  wire p5_is_subnormal_comb;
  wire p5_is_inf_result_comb;
  wire [14:0] p5_sel_1047_comb;
  assign p5_exp_out_5_comb = p4_add_1006[4:0];
  assign p5_frac_final_32_comb = {21'h00_0000, p4_frac_final_11};
  assign p5_shift_9_comb = 9'h010 - p4_concat_1007;
  assign p5_frac_subnormal_32_comb = p5_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p5_frac_final_32_comb >> p5_shift_9_comb;
  assign p5_sign_comb = p4_add_1006[7];
  assign p5_frac_out_10_comb = p4_frac_final_11[9:0];
  assign p5_frac_subnormal_comb = p5_frac_subnormal_32_comb[9:0];
  assign p5_is_subnormal_comb = p5_sign_comb | ~((|p4_add_1006[7:1]) | p4_add_1006[0]);
  assign p5_is_inf_result_comb = p4_is_inf_a_chk | p4_is_inf_b_chk | ~(p5_sign_comb | ~((|p4_add_1006[7:5]) | (&p5_exp_out_5_comb)));
  assign p5_sel_1047_comb = p5_is_subnormal_comb ? {5'h00, p5_frac_subnormal_comb} : {p5_exp_out_5_comb, p5_frac_out_10_comb};

  // Registers for pipe stage 5:
  reg p5_is_inf_result;
  reg [14:0] p5_sel_1047;
  reg p5_not_896;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_is_inf_result <= p5_is_inf_result_comb;
    p5_sel_1047 <= p5_sel_1047_comb;
    p5_not_896 <= p4_not_896;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [15:0] p6_result_comb;
  assign p6_result_comb = p5_is_nan_result ? 16'h7e00 : {p5_sign_result, (p5_is_inf_result ? 15'h7c00 : p5_sel_1047) & {15{p5_not_896}}};

  // Registers for pipe stage 6:
  reg [15:0] p6_result;
  always @ (posedge clk) begin
    p6_result <= p6_result_comb;
  end
  assign out = p6_result;
endmodule
