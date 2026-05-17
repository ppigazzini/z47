// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void fnMin(uint16_t unusedButMandatoryParameter);
void fnMax(uint16_t unusedButMandatoryParameter);
void fnCeil(uint16_t unusedButMandatoryParameter);
void fnFloor(uint16_t unusedButMandatoryParameter);
void fnSign(uint16_t unusedButMandatoryParameter);
void fnChangeSign(uint16_t unusedButMandatoryParameter);
void fnSin(uint16_t unusedButMandatoryParameter);
void fnCos(uint16_t unusedButMandatoryParameter);
void fnTan(uint16_t unusedButMandatoryParameter);
void fnSinh(uint16_t unusedButMandatoryParameter);
void fnCosh(uint16_t unusedButMandatoryParameter);
void fnTanh(uint16_t unusedButMandatoryParameter);
void fnSquare(uint16_t unusedButMandatoryParameter);
void fnCube(uint16_t unusedButMandatoryParameter);

void oracle_fnMin(uint16_t unusedButMandatoryParameter);
void oracle_fnMax(uint16_t unusedButMandatoryParameter);
void oracle_fnCeil(uint16_t unusedButMandatoryParameter);
void oracle_fnFloor(uint16_t unusedButMandatoryParameter);
void oracle_fnSign(uint16_t unusedButMandatoryParameter);
void oracle_fnChangeSign(uint16_t unusedButMandatoryParameter);
void oracle_fnSin(uint16_t unusedButMandatoryParameter);
void oracle_fnCos(uint16_t unusedButMandatoryParameter);
void oracle_fnTan(uint16_t unusedButMandatoryParameter);
void oracle_fnSinh(uint16_t unusedButMandatoryParameter);
void oracle_fnCosh(uint16_t unusedButMandatoryParameter);
void oracle_fnTanh(uint16_t unusedButMandatoryParameter);
void oracle_fnSquare(uint16_t unusedButMandatoryParameter);
void oracle_fnCube(uint16_t unusedButMandatoryParameter);

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
      "  expected: dtype=%u tag=%u save=%u/%d mono=%u imono=%u longIn=%u/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u cplxmul=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu long=%d\n"
      "  actual:   dtype=%u tag=%u save=%u/%d mono=%u imono=%u longIn=%u/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u cplxmul=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu long=%d\n",
          name,
          arg,
      expected->final_register_data_type,
      expected->final_register_tag,
          expected->save_last_x_calls,
          expected->save_last_x_result,
          expected->process_real_complex_monadic_calls,
          expected->process_int_real_complex_monadic_calls,
      expected->get_register_as_longint_calls,
      expected->get_register_as_longint_value,
      expected->convert_long_integer_to_register_calls,
      expected->convert_long_integer_to_register_value,
          expected->cvt2rad_calls,
          expected->wp34s_sinh_cosh_calls,
          expected->dec_number_multiply_calls,
      expected->mul_complex_complex_calls,
      expected->unit_vector_cplx_calls,
      expected->wp34s_int_chs_calls,
      expected->wp34s_int_multiply_calls,
          expected->div_complex_complex_calls,
          expected->convert_real_to_result_calls,
          expected->convert_complex_to_result_calls,
          expected->display_calc_error_calls,
          expected->more_info_calls,
          expected->final_register_real34_value,
          expected->final_register_real34_bits,
          (unsigned long long)expected->final_register_shortint_raw,
          expected->final_register_longint_value,
      actual->final_register_data_type,
      actual->final_register_tag,
          actual->save_last_x_calls,
          actual->save_last_x_result,
          actual->process_real_complex_monadic_calls,
          actual->process_int_real_complex_monadic_calls,
      actual->get_register_as_longint_calls,
          actual->get_register_as_longint_value,
      actual->convert_long_integer_to_register_calls,
          actual->convert_long_integer_to_register_value,
          actual->cvt2rad_calls,
          actual->wp34s_sinh_cosh_calls,
          actual->dec_number_multiply_calls,
      actual->mul_complex_complex_calls,
      actual->unit_vector_cplx_calls,
      actual->wp34s_int_chs_calls,
      actual->wp34s_int_multiply_calls,
          actual->div_complex_complex_calls,
          actual->convert_real_to_result_calls,
          actual->convert_complex_to_result_calls,
          actual->display_calc_error_calls,
          actual->more_info_calls,
          actual->final_register_real34_value,
          actual->final_register_real34_bits,
          (unsigned long long)actual->final_register_shortint_raw,
          actual->final_register_longint_value);
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

static void configureDefaultSurface(void) {
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetTimeInput(true, 7, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetShortIntegerInput(-3);
  mathWrappersSetLongIntegerInput(true, -4);
}

static void configureTrigNominal(void) {
  configureDefaultSurface();
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 5, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(false, 0, 0, 0);
}

static void configureSinhInfinity(void) {
  configureDefaultSurface();
  mathWrappersSetRealInput(true, 9, 0x40);
  mathWrappersSetRealAngleInput(true, 5, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(false, 0, 0, 0);
}

static void configureTanhNominal(void) {
  configureDefaultSurface();
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureTanhInfinity(void) {
  configureTanhNominal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureTanhInfinityDanger(void) {
  configureTanhInfinity();
  mathWrappersSetFlagSpcRes(true);
}

static void configureTanhComplexImagZero(void) {
  configureTanhNominal();
  mathWrappersSetComplexInput(true, 2, 0, 0, 0);
}

static void configureTanPoleNoDanger(void) {
  configureDefaultSurface();
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 90, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(true, 1, 0, 99);
}

static void configureTanPoleDanger(void) {
  configureDefaultSurface();
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 90, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(true);
  mathWrappersSetTrigOutputs(true, 1, 0, 99);
}

static void configureSignReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
}

static void configureSignRealNaN(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0x20);
}

static void configureSignComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
}

static void configureSignShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(-3);
}

static void configureSignLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -4);
}

static void configureChangeSignReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 5, 0);
}

static void configureChangeSignComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
}

static void configureChangeSignShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(5);
}

static void configureChangeSignLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 9);
}

static void configureChangeSignTimeZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
  mathWrappersSetTimeInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureChangeSignTimeDanger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
  mathWrappersSetTimeInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureSquareReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
}

static void configureSquareRealInfinity(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0x40);
  mathWrappersSetFlagSpcRes(false);
}

static void configureSquareRealInfinityDanger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0x40);
  mathWrappersSetFlagSpcRes(true);
}

static void configureSquareComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
}

static void configureSquareShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(-3);
}

static void configureSquareLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -4);
}

static void configureCubeReal(void) {
  configureSquareReal();
}

static void configureCubeRealInfinity(void) {
  configureSquareRealInfinity();
}

static void configureCubeRealInfinityDanger(void) {
  configureSquareRealInfinityDanger();
}

static void configureCubeComplex(void) {
  configureSquareComplex();
}

static void configureCubeShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(2);
}

static void configureCubeLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 3);
}

int main(void) {
  int failures = 0;

  failures += runCase("fnMin", oracle_fnMin, fnMin, 0, false, NULL);
  failures += runCase("fnMin", oracle_fnMin, fnMin, 0, true, NULL);
  failures += runCase("fnMax", oracle_fnMax, fnMax, 0, false, NULL);
  failures += runCase("fnMax", oracle_fnMax, fnMax, 0, true, NULL);
  failures += runCase("fnCeil", oracle_fnCeil, fnCeil, 0, true, NULL);
  failures += runCase("fnFloor", oracle_fnFloor, fnFloor, 0, true, NULL);
  failures += runCase("fnSign/real", oracle_fnSign, fnSign, 0, true, configureSignReal);
  failures += runCase("fnSign/real_nan", oracle_fnSign, fnSign, 0, true, configureSignRealNaN);
  failures += runCase("fnSign/complex", oracle_fnSign, fnSign, 0, true, configureSignComplex);
  failures += runCase("fnSign/shortint", oracle_fnSign, fnSign, 0, true, configureSignShortInteger);
  failures += runCase("fnSign/longint", oracle_fnSign, fnSign, 0, true, configureSignLongInteger);
  failures += runCase("fnChangeSign/real", oracle_fnChangeSign, fnChangeSign, 0, true, configureChangeSignReal);
  failures += runCase("fnChangeSign/complex", oracle_fnChangeSign, fnChangeSign, 0, true, configureChangeSignComplex);
  failures += runCase("fnChangeSign/shortint", oracle_fnChangeSign, fnChangeSign, 0, true, configureChangeSignShortInteger);
  failures += runCase("fnChangeSign/longint", oracle_fnChangeSign, fnChangeSign, 0, true, configureChangeSignLongInteger);
  failures += runCase("fnChangeSign/time_zero", oracle_fnChangeSign, fnChangeSign, 0, true, configureChangeSignTimeZero);
  failures += runCase("fnChangeSign/time_danger", oracle_fnChangeSign, fnChangeSign, 0, true, configureChangeSignTimeDanger);
  failures += runCase("fnSin", oracle_fnSin, fnSin, 0, true, configureTrigNominal);
  failures += runCase("fnCos", oracle_fnCos, fnCos, 0, true, configureTrigNominal);
  failures += runCase("fnTan", oracle_fnTan, fnTan, 0, true, configureTrigNominal);
  failures += runCase("fnTan", oracle_fnTan, fnTan, 0, true, configureTanPoleNoDanger);
  failures += runCase("fnTan", oracle_fnTan, fnTan, 0, true, configureTanPoleDanger);
  failures += runCase("fnSinh", oracle_fnSinh, fnSinh, 0, true, configureTrigNominal);
  failures += runCase("fnSinh", oracle_fnSinh, fnSinh, 0, true, configureSinhInfinity);
  failures += runCase("fnCosh", oracle_fnCosh, fnCosh, 0, true, configureTrigNominal);
  failures += runCase("fnTanh", oracle_fnTanh, fnTanh, 0, true, configureTanhNominal);
  failures += runCase("fnTanh/real_inf", oracle_fnTanh, fnTanh, 0, true, configureTanhInfinity);
  failures += runCase("fnTanh/real_inf_danger", oracle_fnTanh, fnTanh, 0, true, configureTanhInfinityDanger);
  failures += runCase("fnTanh/imag_zero", oracle_fnTanh, fnTanh, 0, true, configureTanhComplexImagZero);
  failures += runCase("fnSquare/real", oracle_fnSquare, fnSquare, 0, true, configureSquareReal);
  failures += runCase("fnSquare/real_inf", oracle_fnSquare, fnSquare, 0, true, configureSquareRealInfinity);
  failures += runCase("fnSquare/real_inf_danger", oracle_fnSquare, fnSquare, 0, true, configureSquareRealInfinityDanger);
  failures += runCase("fnSquare/complex", oracle_fnSquare, fnSquare, 0, true, configureSquareComplex);
  failures += runCase("fnSquare/shortint", oracle_fnSquare, fnSquare, 0, true, configureSquareShortInteger);
  failures += runCase("fnSquare/longint", oracle_fnSquare, fnSquare, 0, true, configureSquareLongInteger);
  failures += runCase("fnCube/real", oracle_fnCube, fnCube, 0, true, configureCubeReal);
  failures += runCase("fnCube/real_inf", oracle_fnCube, fnCube, 0, true, configureCubeRealInfinity);
  failures += runCase("fnCube/real_inf_danger", oracle_fnCube, fnCube, 0, true, configureCubeRealInfinityDanger);
  failures += runCase("fnCube/complex", oracle_fnCube, fnCube, 0, true, configureCubeComplex);
  failures += runCase("fnCube/shortint", oracle_fnCube, fnCube, 0, true, configureCubeShortInteger);
  failures += runCase("fnCube/longint", oracle_fnCube, fnCube, 0, true, configureCubeLongInteger);

  if(failures != 0) {
    fprintf(stderr, "%d math-command-wrapper parity checks failed\n", failures);
    return 1;
  }

  return 0;
}