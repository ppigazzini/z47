// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void fnMin(uint16_t unusedButMandatoryParameter);
void fnMax(uint16_t unusedButMandatoryParameter);
void fnCeil(uint16_t unusedButMandatoryParameter);
void fnFloor(uint16_t unusedButMandatoryParameter);
void fnCosh(uint16_t unusedButMandatoryParameter);

void oracle_fnMin(uint16_t unusedButMandatoryParameter);
void oracle_fnMax(uint16_t unusedButMandatoryParameter);
void oracle_fnCeil(uint16_t unusedButMandatoryParameter);
void oracle_fnFloor(uint16_t unusedButMandatoryParameter);
void oracle_fnCosh(uint16_t unusedButMandatoryParameter);

typedef void (*math_wrapper_fn)(uint16_t);

static int reportMismatch(const char *name,
                          uint16_t arg,
                          const math_wrappers_snapshot_t *expected,
                          const math_wrappers_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: save=%u/%d min=%u max=%u adjust=%u mono=%u imono=%u ip=%u/%d ipcx=%u/%d noop=%u cosh=%u/%d coshcx=%u/%d\n"
          "  actual:   save=%u/%d min=%u max=%u adjust=%u mono=%u imono=%u ip=%u/%d ipcx=%u/%d noop=%u cosh=%u/%d coshcx=%u/%d\n",
          name,
          arg,
          expected->save_last_x_calls,
          expected->save_last_x_result,
          expected->register_min_calls,
          expected->register_max_calls,
          expected->adjust_result_calls,
          expected->process_real_complex_monadic_calls,
          expected->process_int_real_complex_monadic_calls,
          expected->integer_part_real_calls,
          expected->integer_part_real_mode,
          expected->integer_part_cplx_calls,
          expected->integer_part_cplx_mode,
          expected->integer_part_noop_calls,
          expected->sinh_cosh_real_calls,
          expected->sinh_cosh_real_trig_type,
          expected->sinh_cosh_cplx_calls,
          expected->sinh_cosh_cplx_trig_type,
          actual->save_last_x_calls,
          actual->save_last_x_result,
          actual->register_min_calls,
          actual->register_max_calls,
          actual->adjust_result_calls,
          actual->process_real_complex_monadic_calls,
          actual->process_int_real_complex_monadic_calls,
          actual->integer_part_real_calls,
          actual->integer_part_real_mode,
          actual->integer_part_cplx_calls,
          actual->integer_part_cplx_mode,
          actual->integer_part_noop_calls,
          actual->sinh_cosh_real_calls,
          actual->sinh_cosh_real_trig_type,
          actual->sinh_cosh_cplx_calls,
          actual->sinh_cosh_cplx_trig_type);
  return 1;
}

static int runCase(const char *name,
                   math_wrapper_fn oracle_fn,
                   math_wrapper_fn zig_fn,
                   uint16_t arg,
                   bool_t save_last_x_result) {
  math_wrappers_snapshot_t expected;
  math_wrappers_snapshot_t actual;

  mathWrappersReset();
  mathWrappersSetSaveLastXResult(save_last_x_result);
  oracle_fn(arg);
  mathWrappersCapture(&expected);

  mathWrappersReset();
  mathWrappersSetSaveLastXResult(save_last_x_result);
  zig_fn(arg);
  mathWrappersCapture(&actual);

  return reportMismatch(name, arg, &expected, &actual);
}

int main(void) {
  int failures = 0;

  failures += runCase("fnMin", oracle_fnMin, fnMin, 0, false);
  failures += runCase("fnMin", oracle_fnMin, fnMin, 0, true);
  failures += runCase("fnMax", oracle_fnMax, fnMax, 0, false);
  failures += runCase("fnMax", oracle_fnMax, fnMax, 0, true);
  failures += runCase("fnCeil", oracle_fnCeil, fnCeil, 0, true);
  failures += runCase("fnFloor", oracle_fnFloor, fnFloor, 0, true);
  failures += runCase("fnCosh", oracle_fnCosh, fnCosh, 0, true);

  if(failures != 0) {
    fprintf(stderr, "%d math-command-wrapper parity checks failed\n", failures);
    return 1;
  }

  return 0;
}