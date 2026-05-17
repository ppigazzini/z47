// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void fnMin(uint16_t unusedButMandatoryParameter);
void fnMax(uint16_t unusedButMandatoryParameter);
void fnCeil(uint16_t unusedButMandatoryParameter);
void fnFloor(uint16_t unusedButMandatoryParameter);
void fnInvert(uint16_t unusedButMandatoryParameter);
void fnSign(uint16_t unusedButMandatoryParameter);
void fnChangeSign(uint16_t unusedButMandatoryParameter);
void fnSin(uint16_t unusedButMandatoryParameter);
void fnCos(uint16_t unusedButMandatoryParameter);
void fnTan(uint16_t unusedButMandatoryParameter);
void fnSinh(uint16_t unusedButMandatoryParameter);
void fnCosh(uint16_t unusedButMandatoryParameter);
void fnTanh(uint16_t unusedButMandatoryParameter);
void fnExp(uint16_t unusedButMandatoryParameter);
void fnEulersFormula(uint16_t unusedButMandatoryParameter);
void fnSquare(uint16_t unusedButMandatoryParameter);
void fnCube(uint16_t unusedButMandatoryParameter);

void oracle_fnMin(uint16_t unusedButMandatoryParameter);
void oracle_fnMax(uint16_t unusedButMandatoryParameter);
void oracle_fnCeil(uint16_t unusedButMandatoryParameter);
void oracle_fnFloor(uint16_t unusedButMandatoryParameter);
void oracle_fnInvert(uint16_t unusedButMandatoryParameter);
void oracle_fnSign(uint16_t unusedButMandatoryParameter);
void oracle_fnChangeSign(uint16_t unusedButMandatoryParameter);
void oracle_fnSin(uint16_t unusedButMandatoryParameter);
void oracle_fnCos(uint16_t unusedButMandatoryParameter);
void oracle_fnTan(uint16_t unusedButMandatoryParameter);
void oracle_fnSinh(uint16_t unusedButMandatoryParameter);
void oracle_fnCosh(uint16_t unusedButMandatoryParameter);
void oracle_fnTanh(uint16_t unusedButMandatoryParameter);
void oracle_fnExp(uint16_t unusedButMandatoryParameter);
void oracle_fnEulersFormula(uint16_t unusedButMandatoryParameter);
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
      "  expected: dtype=%u tag=%u save=%u/%d mono=%u imono=%u longIn=%u/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u rdiv=%u(%d/%d) cmp=%u(%d,%d) divr=%u(%d;%d,%d) invm=%u cplxi=%u(%d,%d) cplxmul=%u ang=%u(%d;%d->%d) set=%u(%d) refresh=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu long=%d\n"
      "  actual:   dtype=%u tag=%u save=%u/%d mono=%u imono=%u longIn=%u/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u rdiv=%u(%d/%d) cmp=%u(%d,%d) divr=%u(%d;%d,%d) invm=%u cplxi=%u(%d,%d) cplxmul=%u ang=%u(%d;%d->%d) set=%u(%d) refresh=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu long=%d\n",
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
            expected->dec_number_divide_calls,
            expected->dec_number_divide_lhs_value,
            expected->dec_number_divide_rhs_value,
            expected->real_compare_abs_equal_calls,
            expected->real_compare_abs_equal_lhs_value,
            expected->real_compare_abs_equal_rhs_value,
            expected->div_real_complex_calls,
            expected->div_real_complex_numer_value,
            expected->div_real_complex_denom_real_value,
            expected->div_real_complex_denom_imag_value,
            expected->invert_matrix_calls,
          expected->mul_complex_i_calls,
          expected->mul_complex_i_input_real_value,
          expected->mul_complex_i_input_imag_value,
      expected->mul_complex_complex_calls,
          expected->convert_angle_from_to_calls,
          expected->convert_angle_from_to_input_value,
          expected->convert_angle_from_to_from_mode,
          expected->convert_angle_from_to_to_mode,
          expected->fn_set_flag_calls,
          expected->fn_set_flag_last_flag,
          expected->fn_refresh_state_calls,
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
            actual->dec_number_divide_calls,
            actual->dec_number_divide_lhs_value,
            actual->dec_number_divide_rhs_value,
            actual->real_compare_abs_equal_calls,
            actual->real_compare_abs_equal_lhs_value,
            actual->real_compare_abs_equal_rhs_value,
            actual->div_real_complex_calls,
            actual->div_real_complex_numer_value,
            actual->div_real_complex_denom_real_value,
            actual->div_real_complex_denom_imag_value,
            actual->invert_matrix_calls,
          actual->mul_complex_i_calls,
          actual->mul_complex_i_input_real_value,
          actual->mul_complex_i_input_imag_value,
      actual->mul_complex_complex_calls,
          actual->convert_angle_from_to_calls,
          actual->convert_angle_from_to_input_value,
          actual->convert_angle_from_to_from_mode,
          actual->convert_angle_from_to_to_mode,
          actual->fn_set_flag_calls,
          actual->fn_set_flag_last_flag,
          actual->fn_refresh_state_calls,
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

static void configureExpReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureExpRealInfinity(void) {
  configureExpReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureExpRealInfinityDanger(void) {
  configureExpRealInfinity();
  mathWrappersSetFlagSpcRes(true);
}

static void configureExpRealNegativeInfinityDanger(void) {
  configureExpReal();
  mathWrappersSetRealInput(true, -9, 0x40);
  mathWrappersSetFlagSpcRes(true);
}

static void configureExpComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureExpComplexImagZero(void) {
  configureExpComplex();
  mathWrappersSetComplexInput(true, 2, 0, 0, 0);
}

static void configureExpComplexSpecial(void) {
  configureExpComplex();
  mathWrappersSetComplexInput(true, 2, 0, 0, 0x40);
}

static void configureEulersFormulaReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 3, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureEulersFormulaRealAngle(void) {
  configureEulersFormulaReal();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
}

static void configureEulersFormulaRealInfinity(void) {
  configureEulersFormulaReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureEulersFormulaRealInfinityDanger(void) {
  configureEulersFormulaRealInfinity();
  mathWrappersSetFlagSpcRes(true);
}

static void configureEulersFormulaComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureEulersFormulaComplexInfinity(void) {
  configureEulersFormulaComplex();
  mathWrappersSetComplexInput(true, 2, 0x40, 3, 0);
}

static void configureEulersFormulaComplexInfinityDanger(void) {
  configureEulersFormulaComplexInfinity();
  mathWrappersSetFlagSpcRes(true);
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

static void configureInvertReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureInvertRealZero(void) {
  configureInvertReal();
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureInvertRealZeroDanger(void) {
  configureInvertReal();
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureInvertRealNegativeZeroDanger(void) {
  configureInvertReal();
  mathWrappersSetRealInput(true, 0, 0x80);
  mathWrappersSetFlagSpcRes(true);
}

static void configureInvertRealInfinityDanger(void) {
  configureInvertReal();
  mathWrappersSetRealInput(true, -9, 0x40);
  mathWrappersSetFlagSpcRes(true);
}

static void configureInvertRealAbsOne(void) {
  configureInvertReal();
  mathWrappersSetRealInput(true, -1, 0);
}

static void configureInvertComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
}

static void configureInvertRealMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
}

static void configureInvertComplexMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34Matrix, amNone);
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
  failures += runCase("fnInvert/real", oracle_fnInvert, fnInvert, 0, true, configureInvertReal);
  failures += runCase("fnInvert/real_zero", oracle_fnInvert, fnInvert, 0, true, configureInvertRealZero);
  failures += runCase("fnInvert/real_zero_danger", oracle_fnInvert, fnInvert, 0, true, configureInvertRealZeroDanger);
  failures += runCase("fnInvert/real_neg_zero_danger", oracle_fnInvert, fnInvert, 0, true, configureInvertRealNegativeZeroDanger);
  failures += runCase("fnInvert/real_inf_danger", oracle_fnInvert, fnInvert, 0, true, configureInvertRealInfinityDanger);
  failures += runCase("fnInvert/real_abs_one", oracle_fnInvert, fnInvert, 0, true, configureInvertRealAbsOne);
  failures += runCase("fnInvert/complex", oracle_fnInvert, fnInvert, 0, true, configureInvertComplex);
  failures += runCase("fnInvert/real_matrix", oracle_fnInvert, fnInvert, 0, true, configureInvertRealMatrix);
  failures += runCase("fnInvert/complex_matrix", oracle_fnInvert, fnInvert, 0, true, configureInvertComplexMatrix);
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
  failures += runCase("fnExp/real", oracle_fnExp, fnExp, 0, true, configureExpReal);
  failures += runCase("fnExp/real_inf", oracle_fnExp, fnExp, 0, true, configureExpRealInfinity);
  failures += runCase("fnExp/real_inf_danger", oracle_fnExp, fnExp, 0, true, configureExpRealInfinityDanger);
  failures += runCase("fnExp/real_neg_inf_danger", oracle_fnExp, fnExp, 0, true, configureExpRealNegativeInfinityDanger);
  failures += runCase("fnExp/complex", oracle_fnExp, fnExp, 0, true, configureExpComplex);
  failures += runCase("fnExp/complex_imag_zero", oracle_fnExp, fnExp, 0, true, configureExpComplexImagZero);
  failures += runCase("fnExp/complex_special", oracle_fnExp, fnExp, 0, true, configureExpComplexSpecial);
  failures += runCase("fnEulersFormula/real", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaReal);
  failures += runCase("fnEulersFormula/real_angle", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaRealAngle);
  failures += runCase("fnEulersFormula/real_inf", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaRealInfinity);
  failures += runCase("fnEulersFormula/real_inf_danger", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaRealInfinityDanger);
  failures += runCase("fnEulersFormula/complex", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaComplex);
  failures += runCase("fnEulersFormula/complex_inf", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaComplexInfinity);
  failures += runCase("fnEulersFormula/complex_inf_danger", oracle_fnEulersFormula, fnEulersFormula, 0, true, configureEulersFormulaComplexInfinityDanger);
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