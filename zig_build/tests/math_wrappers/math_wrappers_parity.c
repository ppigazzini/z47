// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void fnMin(uint16_t unusedButMandatoryParameter);
void fnMax(uint16_t unusedButMandatoryParameter);
void fnCeil(uint16_t unusedButMandatoryParameter);
void fnFloor(uint16_t unusedButMandatoryParameter);
void fnSin(uint16_t unusedButMandatoryParameter);
void fnCos(uint16_t unusedButMandatoryParameter);
void fnTan(uint16_t unusedButMandatoryParameter);
void fnSinh(uint16_t unusedButMandatoryParameter);
void fnCosh(uint16_t unusedButMandatoryParameter);

void oracle_fnMin(uint16_t unusedButMandatoryParameter);
void oracle_fnMax(uint16_t unusedButMandatoryParameter);
void oracle_fnCeil(uint16_t unusedButMandatoryParameter);
void oracle_fnFloor(uint16_t unusedButMandatoryParameter);
void oracle_fnSin(uint16_t unusedButMandatoryParameter);
void oracle_fnCos(uint16_t unusedButMandatoryParameter);
void oracle_fnTan(uint16_t unusedButMandatoryParameter);
void oracle_fnSinh(uint16_t unusedButMandatoryParameter);
void oracle_fnCosh(uint16_t unusedButMandatoryParameter);

typedef void (*math_wrapper_fn)(uint16_t);
typedef void (*math_wrapper_config_fn)(void);

static int reportMismatch(const char *name,
                          uint16_t arg,
                          const math_wrappers_snapshot_t *expected,
                          const math_wrappers_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: save=%u/%d min=%u max=%u adjust=%u mono=%u imono=%u cvt=%u trig=%u sinh=%u mul=%u div=%u realOut=%u complexOut=%u err=%u more=%u\n"
          "  actual:   save=%u/%d min=%u max=%u adjust=%u mono=%u imono=%u cvt=%u trig=%u sinh=%u mul=%u div=%u realOut=%u complexOut=%u err=%u more=%u\n",
          name,
          arg,
          expected->save_last_x_calls,
          expected->save_last_x_result,
          expected->register_min_calls,
          expected->register_max_calls,
          expected->adjust_result_calls,
          expected->process_real_complex_monadic_calls,
          expected->process_int_real_complex_monadic_calls,
          expected->cvt2rad_calls,
          expected->wp34s_sinh_cosh_calls,
          expected->dec_number_multiply_calls,
          expected->div_complex_complex_calls,
          expected->convert_real_to_result_calls,
          expected->convert_complex_to_result_calls,
          expected->display_calc_error_calls,
          expected->more_info_calls,
          actual->save_last_x_calls,
          actual->save_last_x_result,
          actual->register_min_calls,
          actual->register_max_calls,
          actual->adjust_result_calls,
          actual->process_real_complex_monadic_calls,
          actual->process_int_real_complex_monadic_calls,
          actual->cvt2rad_calls,
          actual->wp34s_sinh_cosh_calls,
          actual->dec_number_multiply_calls,
          actual->div_complex_complex_calls,
          actual->convert_real_to_result_calls,
          actual->convert_complex_to_result_calls,
          actual->display_calc_error_calls,
          actual->more_info_calls);
  return 1;
}

static int runCase(const char *name,
                   math_wrapper_fn oracle_fn,
                   math_wrapper_fn zig_fn,
                   uint16_t arg,
                   bool_t save_last_x_result,
                   math_wrapper_config_fn configure) {
  math_wrappers_snapshot_t expected;
  math_wrappers_snapshot_t actual;

  mathWrappersReset();
  mathWrappersSetSaveLastXResult(save_last_x_result);
  if(configure != NULL) {
    configure();
  }
  oracle_fn(arg);
  mathWrappersCapture(&expected);

  mathWrappersReset();
  mathWrappersSetSaveLastXResult(save_last_x_result);
  if(configure != NULL) {
    configure();
  }
  zig_fn(arg);
  mathWrappersCapture(&actual);

  return reportMismatch(name, arg, &expected, &actual);
}

static void configureTrigNominal(void) {
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 5, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(false, 0, 0, 0);
}

static void configureSinhInfinity(void) {
  mathWrappersSetRealInput(true, 9, 0x40);
  mathWrappersSetRealAngleInput(true, 5, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(false, 0, 0, 0);
}

static void configureTanPoleNoDanger(void) {
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 90, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(true, 1, 0, 99);
}

static void configureTanPoleDanger(void) {
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 90, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(true);
  mathWrappersSetTrigOutputs(true, 1, 0, 99);
}

int main(void) {
  int failures = 0;

  failures += runCase("fnMin", oracle_fnMin, fnMin, 0, false, NULL);
  failures += runCase("fnMin", oracle_fnMin, fnMin, 0, true, NULL);
  failures += runCase("fnMax", oracle_fnMax, fnMax, 0, false, NULL);
  failures += runCase("fnMax", oracle_fnMax, fnMax, 0, true, NULL);
  failures += runCase("fnCeil", oracle_fnCeil, fnCeil, 0, true, NULL);
  failures += runCase("fnFloor", oracle_fnFloor, fnFloor, 0, true, NULL);
  failures += runCase("fnSin", oracle_fnSin, fnSin, 0, true, configureTrigNominal);
  failures += runCase("fnCos", oracle_fnCos, fnCos, 0, true, configureTrigNominal);
  failures += runCase("fnTan", oracle_fnTan, fnTan, 0, true, configureTrigNominal);
  failures += runCase("fnTan", oracle_fnTan, fnTan, 0, true, configureTanPoleNoDanger);
  failures += runCase("fnTan", oracle_fnTan, fnTan, 0, true, configureTanPoleDanger);
  failures += runCase("fnSinh", oracle_fnSinh, fnSinh, 0, true, configureTrigNominal);
  failures += runCase("fnSinh", oracle_fnSinh, fnSinh, 0, true, configureSinhInfinity);
  failures += runCase("fnCosh", oracle_fnCosh, fnCosh, 0, true, configureTrigNominal);

  if(failures != 0) {
    fprintf(stderr, "%d math-command-wrapper parity checks failed\n", failures);
    return 1;
  }

  return 0;
}