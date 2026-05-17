// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MATH_WRAPPERS_TEST_RUNTIME_H
#define Z47_MATH_WRAPPERS_TEST_RUNTIME_H

#include "c47.h"

typedef struct {
  uint32_t save_last_x_calls;
  bool_t save_last_x_result;

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
} math_wrappers_snapshot_t;

void mathWrappersReset(void);
void mathWrappersSetSaveLastXResult(bool_t result);
void mathWrappersCapture(math_wrappers_snapshot_t *snapshot);

#endif