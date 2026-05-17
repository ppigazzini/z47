// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MATH_WRAPPERS_TEST_RUNTIME_H
#define Z47_MATH_WRAPPERS_TEST_RUNTIME_H

#include "c47.h"

typedef struct {
  uint32_t save_last_x_calls;
  bool_t save_last_x_result;

  uint32_t get_register_data_type_calls;
  uint32_t get_register_tag_calls;
  uint32_t get_register_data_pointer_calls;

  uint32_t register_min_calls;
  calcRegister_t register_min_reg1;
  calcRegister_t register_min_reg2;
  calcRegister_t register_min_dest;

  uint32_t register_max_calls;
  calcRegister_t register_max_reg1;
  calcRegister_t register_max_reg2;
  calcRegister_t register_max_dest;

  uint32_t adjust_result_calls;
  calcRegister_t adjust_result_res;
  bool_t adjust_result_drop_y;
  bool_t adjust_result_set_cpx_res;
  calcRegister_t adjust_result_op1;
  calcRegister_t adjust_result_op2;
  calcRegister_t adjust_result_op3;

  uint32_t process_real_complex_monadic_calls;
  uint32_t process_int_real_complex_monadic_calls;

  uint32_t integer_part_noop_calls;
  uint32_t integer_part_real_calls;
  int32_t integer_part_real_mode;
  uint32_t integer_part_cplx_calls;
  int32_t integer_part_cplx_mode;

  uint32_t sinh_cosh_real_calls;
  int32_t sinh_cosh_real_trig_type;
  uint32_t sinh_cosh_cplx_calls;
  int32_t sinh_cosh_cplx_trig_type;

  uint32_t get_register_as_real_calls;
  uint32_t get_register_as_real_angle_calls;
  calcRegister_t get_register_as_real_angle_reg;
  bool_t get_register_as_real_angle_reduce_longinteger;
  int32_t get_register_as_real_angle_value;
  uint8_t get_register_as_real_angle_bits;
  angularMode_t get_register_as_real_angle_mode;

  uint32_t get_register_as_complex_calls;
  int32_t get_register_as_complex_real_value;
  uint8_t get_register_as_complex_real_bits;
  int32_t get_register_as_complex_imag_value;
  uint8_t get_register_as_complex_imag_bits;

  uint32_t get_register_as_longint_calls;
  bool_t get_register_as_longint_result;
  int32_t get_register_as_longint_value;

  uint32_t convert_long_integer_to_register_calls;
  int32_t convert_long_integer_to_register_value;
  calcRegister_t convert_long_integer_to_register_dest;

  uint32_t convert_real_to_result_calls;
  int32_t convert_real_to_result_value;
  uint8_t convert_real_to_result_bits;
  angularMode_t convert_real_to_result_angle;

  uint32_t convert_complex_to_result_calls;
  int32_t convert_complex_to_result_real_value;
  uint8_t convert_complex_to_result_real_bits;
  int32_t convert_complex_to_result_imag_value;
  uint8_t convert_complex_to_result_imag_bits;

  uint32_t cvt2rad_calls;
  int32_t cvt2rad_input_value;
  uint8_t cvt2rad_input_bits;
  angularMode_t cvt2rad_mode;
  uint8_t cvt2rad_requested_mask;

  uint32_t wp34s_sinh_cosh_calls;
  int32_t wp34s_sinh_cosh_input_value;
  uint8_t wp34s_sinh_cosh_input_bits;
  uint8_t wp34s_sinh_cosh_requested_mask;

  uint32_t dec_number_multiply_calls;
  int32_t dec_number_multiply_lhs_value;
  uint8_t dec_number_multiply_lhs_bits;
  int32_t dec_number_multiply_rhs_value;
  uint8_t dec_number_multiply_rhs_bits;

  uint32_t dec_number_divide_calls;
  int32_t dec_number_divide_lhs_value;
  int32_t dec_number_divide_rhs_value;

  uint32_t real_compare_abs_equal_calls;
  int32_t real_compare_abs_equal_lhs_value;
  int32_t real_compare_abs_equal_rhs_value;

  uint32_t div_real_complex_calls;
  int32_t div_real_complex_numer_value;
  int32_t div_real_complex_denom_real_value;
  int32_t div_real_complex_denom_imag_value;

  uint32_t invert_matrix_calls;

  uint32_t mul_complex_complex_calls;
  int32_t mul_complex_complex_factor1_real_value;
  int32_t mul_complex_complex_factor1_imag_value;
  int32_t mul_complex_complex_factor2_real_value;
  int32_t mul_complex_complex_factor2_imag_value;

  uint32_t unit_vector_cplx_calls;

  uint32_t wp34s_extract_value_calls;
  uint64_t wp34s_extract_value_input;
  int32_t wp34s_extract_value_sign;

  uint32_t wp34s_int_chs_calls;
  uint64_t wp34s_int_chs_input;

  uint32_t wp34s_int_multiply_calls;
  uint64_t wp34s_int_multiply_lhs;
  uint64_t wp34s_int_multiply_rhs;

  uint32_t div_complex_complex_calls;
  int32_t div_complex_complex_numer_real_value;
  int32_t div_complex_complex_numer_imag_value;
  int32_t div_complex_complex_denom_real_value;
  int32_t div_complex_complex_denom_imag_value;

  uint32_t get_system_flag_calls;
  int32_t get_system_flag_last_flag;

  uint32_t display_calc_error_calls;
  uint8_t display_calc_error_last_code;
  calcRegister_t display_calc_error_last_message_reg_line;
  calcRegister_t display_calc_error_last_register_line;

  uint32_t more_info_calls;

  uint32_t final_register_data_type;
  uint32_t final_register_tag;
  int32_t final_register_real34_value;
  uint8_t final_register_real34_bits;
  uint64_t final_register_shortint_raw;
  int32_t final_register_longint_value;
} math_wrappers_snapshot_t;

void mathWrappersReset(void);
void mathWrappersSetSaveLastXResult(bool_t result);
void mathWrappersSetRegisterSurface(uint32_t data_type, uint32_t tag);
void mathWrappersSetRealInput(bool_t available, int32_t value, uint8_t bits);
void mathWrappersSetTimeInput(bool_t available, int32_t value, uint8_t bits);
void mathWrappersSetRealAngleInput(bool_t available, int32_t value, uint8_t bits, angularMode_t angle_mode);
void mathWrappersSetComplexInput(bool_t available, int32_t real_value, uint8_t real_bits, int32_t imag_value, uint8_t imag_bits);
void mathWrappersSetShortIntegerInput(int64_t value);
void mathWrappersSetLongIntegerInput(bool_t available, int32_t value);
void mathWrappersSetFlagSpcRes(bool_t enabled);
void mathWrappersSetTrigOutputs(bool_t enabled, int32_t sin_value, int32_t cos_value, int32_t tan_value);
void mathWrappersCapture(math_wrappers_snapshot_t *snapshot);

#endif