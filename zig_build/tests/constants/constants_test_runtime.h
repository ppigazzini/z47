// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_CONSTANTS_TEST_RUNTIME_H
#define Z47_CONSTANTS_TEST_RUNTIME_H

#include "c47.h"

typedef struct {
  uint32_t lift_stack_calls;
  uint16_t current_solver_status;

  uint32_t reallocate_register_calls;
  calcRegister_t reallocate_register_reg;
  uint32_t reallocate_register_data_type;
  uint16_t reallocate_register_data_size_without_data_len_blocks;
  uint32_t reallocate_register_tag;

  uint32_t real_to_real34_calls;
  uint16_t real_to_real34_source_id;
  calcRegister_t real_to_real34_destination_reg;

  uint32_t convert_real_to_result_register_calls;
  uint16_t convert_real_to_result_source_id;
  calcRegister_t convert_real_to_result_dest;
  int32_t convert_real_to_result_angle;

  uint32_t adjust_result_calls;
  calcRegister_t adjust_result_res;
  bool_t adjust_result_drop_y;
  bool_t adjust_result_set_cpx_res;
  calcRegister_t adjust_result_op1;
  calcRegister_t adjust_result_op2;
  calcRegister_t adjust_result_op3;

  uint32_t set_lastinteger_base_to_zero_calls;
  uint16_t register_x_real34_id;

  uint32_t more_info_calls;
  char more_info_line1[64];
  char more_info_line2[256];
} constants_snapshot_t;

void constantsRuntimeReset(void);
void constantsRuntimeCapture(constants_snapshot_t *snapshot);

#endif