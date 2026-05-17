// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "constants_test_runtime.h"

void fnConstant(uint16_t constant);
void fnPi(uint16_t unusedButMandatoryParameter);

void oracle_fnConstant(uint16_t constant);
void oracle_fnPi(uint16_t unusedButMandatoryParameter);

typedef void (*constants_fn)(uint16_t);

static int reportMismatch(const char *name,
                          uint16_t arg,
                          const constants_snapshot_t *expected,
                          const constants_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: lift=%u solver=%#x realloc=%u/%d/%u/%u/%u real=%u/%u/%d convert=%u/%u/%d/%d adjust=%u/%d/%u/%u/%d/%d/%d zero=%u x=%u info=%u/%s/%s\n"
          "  actual:   lift=%u solver=%#x realloc=%u/%d/%u/%u/%u real=%u/%u/%d convert=%u/%u/%d/%d adjust=%u/%d/%u/%u/%d/%d/%d zero=%u x=%u info=%u/%s/%s\n",
          name,
          arg,
          expected->lift_stack_calls,
          expected->current_solver_status,
          expected->reallocate_register_calls,
          expected->reallocate_register_reg,
          expected->reallocate_register_data_type,
          expected->reallocate_register_data_size_without_data_len_blocks,
          expected->reallocate_register_tag,
          expected->real_to_real34_calls,
          expected->real_to_real34_source_id,
          expected->real_to_real34_destination_reg,
          expected->convert_real_to_result_register_calls,
          expected->convert_real_to_result_source_id,
          expected->convert_real_to_result_dest,
          expected->convert_real_to_result_angle,
          expected->adjust_result_calls,
          expected->adjust_result_res,
          expected->adjust_result_drop_y,
          expected->adjust_result_set_cpx_res,
          expected->adjust_result_op1,
          expected->adjust_result_op2,
          expected->adjust_result_op3,
          expected->set_lastinteger_base_to_zero_calls,
          expected->register_x_real34_id,
          expected->more_info_calls,
          expected->more_info_line1,
          expected->more_info_line2,
          actual->lift_stack_calls,
          actual->current_solver_status,
          actual->reallocate_register_calls,
          actual->reallocate_register_reg,
          actual->reallocate_register_data_type,
          actual->reallocate_register_data_size_without_data_len_blocks,
          actual->reallocate_register_tag,
          actual->real_to_real34_calls,
          actual->real_to_real34_source_id,
          actual->real_to_real34_destination_reg,
          actual->convert_real_to_result_register_calls,
          actual->convert_real_to_result_source_id,
          actual->convert_real_to_result_dest,
          actual->convert_real_to_result_angle,
          actual->adjust_result_calls,
          actual->adjust_result_res,
          actual->adjust_result_drop_y,
          actual->adjust_result_set_cpx_res,
          actual->adjust_result_op1,
          actual->adjust_result_op2,
          actual->adjust_result_op3,
          actual->set_lastinteger_base_to_zero_calls,
          actual->register_x_real34_id,
          actual->more_info_calls,
          actual->more_info_line1,
          actual->more_info_line2);
  return 1;
}

static int runCase(const char *name,
                   constants_fn oracle_fn,
                   constants_fn zig_fn,
                   uint16_t arg) {
  constants_snapshot_t expected;
  constants_snapshot_t actual;

  constantsRuntimeReset();
  oracle_fn(arg);
  constantsRuntimeCapture(&expected);

  constantsRuntimeReset();
  zig_fn(arg);
  constantsRuntimeCapture(&actual);

  return reportMismatch(name, arg, &expected, &actual);
}

int main(void) {
  int failures = 0;

  failures += runCase("fnConstant", oracle_fnConstant, fnConstant, 0);
  failures += runCase("fnConstant", oracle_fnConstant, fnConstant, 7);
  failures += runCase("fnConstant", oracle_fnConstant, fnConstant, NOUC - 1);
  failures += runCase("fnConstant", oracle_fnConstant, fnConstant, NOUC);
  failures += runCase("fnPi", oracle_fnPi, fnPi, 0);
  failures += runCase("fnPi", oracle_fnPi, fnPi, 99);

  if(failures != 0) {
    fprintf(stderr, "%d constants parity checks failed\n", failures);
    return 1;
  }

  return 0;
}