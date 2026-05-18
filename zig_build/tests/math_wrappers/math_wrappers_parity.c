// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void fnMin(uint16_t unusedButMandatoryParameter);
void fnMax(uint16_t unusedButMandatoryParameter);
void fnCeil(uint16_t unusedButMandatoryParameter);
void fnFloor(uint16_t unusedButMandatoryParameter);
void fnIp(uint16_t unusedButMandatoryParameter);
void fnArcsin(uint16_t unusedButMandatoryParameter);
void fnArccos(uint16_t unusedButMandatoryParameter);
void fnArctan(uint16_t unusedButMandatoryParameter);
void fnArcsinh(uint16_t unusedButMandatoryParameter);
void fnArccosh(uint16_t unusedButMandatoryParameter);
void fnArctanh(uint16_t unusedButMandatoryParameter);
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
void fnLn(uint16_t unusedButMandatoryParameter);
void fnSqrt1Px2(uint16_t unusedButMandatoryParameter);
void fnErf(uint16_t unusedButMandatoryParameter);
void fnErfc(uint16_t unusedButMandatoryParameter);
void fn2Pow(uint16_t unusedButMandatoryParameter);
void fn10Pow(uint16_t unusedButMandatoryParameter);
void fnLog10(uint16_t unusedButMandatoryParameter);
void fnLog2(uint16_t unusedButMandatoryParameter);
void fnM1Pow(uint16_t unusedButMandatoryParameter);
void fnEulersFormula(uint16_t unusedButMandatoryParameter);
void fnSquare(uint16_t unusedButMandatoryParameter);
void fnCube(uint16_t unusedButMandatoryParameter);

void oracle_fnMin(uint16_t unusedButMandatoryParameter);
void oracle_fnMax(uint16_t unusedButMandatoryParameter);
void oracle_fnCeil(uint16_t unusedButMandatoryParameter);
void oracle_fnFloor(uint16_t unusedButMandatoryParameter);
void oracle_fnIp(uint16_t unusedButMandatoryParameter);
void oracle_fnArcsin(uint16_t unusedButMandatoryParameter);
void oracle_fnArccos(uint16_t unusedButMandatoryParameter);
void oracle_fnArctan(uint16_t unusedButMandatoryParameter);
void oracle_fnArcsinh(uint16_t unusedButMandatoryParameter);
void oracle_fnArccosh(uint16_t unusedButMandatoryParameter);
void oracle_fnArctanh(uint16_t unusedButMandatoryParameter);
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
void oracle_fnLn(uint16_t unusedButMandatoryParameter);
void oracle_fnSqrt1Px2(uint16_t unusedButMandatoryParameter);
void oracle_fnErf(uint16_t unusedButMandatoryParameter);
void oracle_fnErfc(uint16_t unusedButMandatoryParameter);
void oracle_fn2Pow(uint16_t unusedButMandatoryParameter);
void oracle_fn10Pow(uint16_t unusedButMandatoryParameter);
void oracle_fnLog10(uint16_t unusedButMandatoryParameter);
void oracle_fnLog2(uint16_t unusedButMandatoryParameter);
void oracle_fnM1Pow(uint16_t unusedButMandatoryParameter);
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
      "  expected: dtype=%u tag=%u save=%u/%d mono=%u imono=%u longIn=%u/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u rdiv=%u(%d/%d) cmp=%u(%d,%d) divr=%u(%d;%d,%d) invm=%u cplxi=%u(%d,%d) cplxmul=%u ang=%u(%d;%d->%d) set=%u(%d) refresh=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu long=%d ovf=%d\n"
      "  actual:   dtype=%u tag=%u save=%u/%d mono=%u imono=%u longIn=%u/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u rdiv=%u(%d/%d) cmp=%u(%d,%d) divr=%u(%d;%d,%d) invm=%u cplxi=%u(%d,%d) cplxmul=%u ang=%u(%d;%d->%d) set=%u(%d) refresh=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu long=%d ovf=%d\n",
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
            expected->final_overflow_flag,
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
          actual->final_register_longint_value,
          actual->final_overflow_flag);
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
  mathWrappersSetShortIntegerMode(SIM_UNSIGN);
  mathWrappersSetLongIntegerInput(true, -4);
  mathWrappersSetFlagOverflow(false);
}

static void configureTrigNominal(void) {
  configureDefaultSurface();
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealAngleInput(true, 5, 0, amRadian);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetTrigOutputs(false, 0, 0, 0);
}

static void configureInverseTrigReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 1, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureInverseTrigComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 2, 0);
  mathWrappersSetComplexInput(true, 4, 0, 5, 0);
  mathWrappersSetFlagCpxRes(true);
  mathWrappersSetFlagSpcRes(false);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureInverseTrigDomainDanger(void) {
  configureInverseTrigComplex();
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(true);
}

static void configureArctanInfinity(void) {
  configureInverseTrigReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureArctanInfinityDanger(void) {
  configureArctanInfinity();
  mathWrappersSetFlagSpcRes(true);
}

static void configureArcsinhReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureArcsinhRealInfinity(void) {
  configureArcsinhReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureArcsinhComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureArccoshReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(false);
}

static void configureArccoshComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagCpxRes(true);
  mathWrappersSetFlagSpcRes(false);
}

static void configureArccoshDanger(void) {
  configureArccoshComplex();
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(true);
}

static void configureArctanhReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(false);
}

static void configureArctanhRealPositiveOne(void) {
  configureArctanhReal();
  mathWrappersSetRealInput(true, 1, 0);
}

static void configureArctanhRealPositiveOneDanger(void) {
  configureArctanhRealPositiveOne();
  mathWrappersSetFlagSpcRes(true);
}

static void configureArctanhRealNegativeOneDanger(void) {
  configureArctanhReal();
  mathWrappersSetRealInput(true, -1, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureArctanhComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 2, 0);
  mathWrappersSetComplexInput(true, 3, 0, 4, 0);
  mathWrappersSetFlagCpxRes(true);
  mathWrappersSetFlagSpcRes(false);
}

static void configureArctanhDanger(void) {
  configureArctanhComplex();
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(true);
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

static void configure10PowReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configure10PowRealInfinity(void) {
  configure10PowReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configure10PowRealInfinityDanger(void) {
  configure10PowRealInfinity();
  mathWrappersSetFlagSpcRes(true);
}

static void configure10PowComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configure10PowShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(3);
}

static void configure10PowLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 3);
}

static void configure10PowLongIntegerNegative(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -2);
}

static void configureLog2Real(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 8, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureLog2Complex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 8, 0, 3, 0);
}

static void configureLog2ShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(8);
}

static void configureLog2LongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 8);
}

static void configureLnRealZeroDanger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(true);
}

static void configureLnRealNegativeComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, -8, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(true);
  mathWrappersSetFlagSpcRes(false);
}

static void configureLnRealNegativeDanger(void) {
  configureLnRealNegativeComplex();
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(true);
}

static void configureLnComplexZeroDanger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureLog10ShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(100);
}

static void configureLog10LongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 1000);
}

static void configureErfReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureErfcReal(void) {
  configureErfReal();
  mathWrappersSetRealInput(true, -3, 0);
}

static void configure2PowReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configure2PowRealInfinity(void) {
  configure2PowReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configure2PowRealInfinityDanger(void) {
  configure2PowRealInfinity();
  mathWrappersSetFlagSpcRes(true);
}

static void configure2PowComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configure2PowShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(3);
}

static void configure2PowLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 3);
}

static void configure2PowLongIntegerNegative(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -2);
}

static void configureM1PowRealZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureM1PowRealOne(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 1, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureM1PowRealInfinity(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 9, 0x40);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureM1PowComplexZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amDegree);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 0, 0, 0, 0);
}

static void configureM1PowComplexOne(void) {
  configureM1PowComplexZero();
  mathWrappersSetComplexInput(true, 1, 0, 0, 0);
}

static void configureM1PowComplexGeneral(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amDegree);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 1, 0, 2, 0);
}

static void configureM1PowShortIntegerUnsignedOdd(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerMode(SIM_UNSIGN);
  mathWrappersSetFlagOverflow(false);
  mathWrappersSetShortIntegerInput(3);
}

static void configureM1PowShortIntegerSignedEven(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerMode(SIM_2COMPL);
  mathWrappersSetFlagOverflow(true);
  mathWrappersSetShortIntegerInput(2);
}

static void configureM1PowLongIntegerOdd(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 3);
}

static void configureM1PowLongIntegerEven(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 4);
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
  failures += runCase("fnIp/real", oracle_fnIp, fnIp, 0, true, configure2PowReal);
  failures += runCase("fnIp/complex", oracle_fnIp, fnIp, 0, true, configure2PowComplex);
  failures += runCase("fnIp/shortint", oracle_fnIp, fnIp, 0, true, configure2PowShortInteger);
  failures += runCase("fnIp/longint", oracle_fnIp, fnIp, 0, true, configure2PowLongInteger);
  failures += runCase("fnIp/real_nan", oracle_fnIp, fnIp, 0, true, configureSignRealNaN);
  failures += runCase("fnArcsin/real", oracle_fnArcsin, fnArcsin, 0, true, configureInverseTrigReal);
  failures += runCase("fnArcsin/complex", oracle_fnArcsin, fnArcsin, 0, true, configureInverseTrigComplex);
  failures += runCase("fnArcsin/danger", oracle_fnArcsin, fnArcsin, 0, true, configureInverseTrigDomainDanger);
  failures += runCase("fnArccos/real", oracle_fnArccos, fnArccos, 0, true, configureInverseTrigReal);
  failures += runCase("fnArccos/complex", oracle_fnArccos, fnArccos, 0, true, configureInverseTrigComplex);
  failures += runCase("fnArccos/danger", oracle_fnArccos, fnArccos, 0, true, configureInverseTrigDomainDanger);
  failures += runCase("fnArctan/real", oracle_fnArctan, fnArctan, 0, true, configureInverseTrigReal);
  failures += runCase("fnArctan/real_inf", oracle_fnArctan, fnArctan, 0, true, configureArctanInfinity);
  failures += runCase("fnArctan/real_inf_danger", oracle_fnArctan, fnArctan, 0, true, configureArctanInfinityDanger);
  failures += runCase("fnArctan/complex", oracle_fnArctan, fnArctan, 0, true, configureInverseTrigComplex);
  failures += runCase("fnArcsinh/real", oracle_fnArcsinh, fnArcsinh, 0, true, configureArcsinhReal);
  failures += runCase("fnArcsinh/real_inf", oracle_fnArcsinh, fnArcsinh, 0, true, configureArcsinhRealInfinity);
  failures += runCase("fnArcsinh/complex", oracle_fnArcsinh, fnArcsinh, 0, true, configureArcsinhComplex);
  failures += runCase("fnArccosh/real", oracle_fnArccosh, fnArccosh, 0, true, configureArccoshReal);
  failures += runCase("fnArccosh/complex", oracle_fnArccosh, fnArccosh, 0, true, configureArccoshComplex);
  failures += runCase("fnArccosh/danger", oracle_fnArccosh, fnArccosh, 0, true, configureArccoshDanger);
  failures += runCase("fnArctanh/real_zero", oracle_fnArctanh, fnArctanh, 0, true, configureArctanhReal);
  failures += runCase("fnArctanh/real_pos_one", oracle_fnArctanh, fnArctanh, 0, true, configureArctanhRealPositiveOne);
  failures += runCase("fnArctanh/real_pos_one_danger", oracle_fnArctanh, fnArctanh, 0, true, configureArctanhRealPositiveOneDanger);
  failures += runCase("fnArctanh/real_neg_one_danger", oracle_fnArctanh, fnArctanh, 0, true, configureArctanhRealNegativeOneDanger);
  failures += runCase("fnArctanh/complex", oracle_fnArctanh, fnArctanh, 0, true, configureArctanhComplex);
  failures += runCase("fnArctanh/danger", oracle_fnArctanh, fnArctanh, 0, true, configureArctanhDanger);
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
  failures += runCase("fnLn/real", oracle_fnLn, fnLn, 0, true, configureLog2Real);
  failures += runCase("fnLn/real_zero_danger", oracle_fnLn, fnLn, 0, true, configureLnRealZeroDanger);
  failures += runCase("fnLn/real_negative_complex", oracle_fnLn, fnLn, 0, true, configureLnRealNegativeComplex);
  failures += runCase("fnLn/real_negative_danger", oracle_fnLn, fnLn, 0, true, configureLnRealNegativeDanger);
  failures += runCase("fnLn/complex", oracle_fnLn, fnLn, 0, true, configureLog2Complex);
  failures += runCase("fnLn/complex_zero_danger", oracle_fnLn, fnLn, 0, true, configureLnComplexZeroDanger);
  failures += runCase("fnSqrt1Px2/real", oracle_fnSqrt1Px2, fnSqrt1Px2, 0, true, configure2PowReal);
  failures += runCase("fnSqrt1Px2/real_inf_danger", oracle_fnSqrt1Px2, fnSqrt1Px2, 0, true, configure2PowRealInfinityDanger);
  failures += runCase("fnErf/real", oracle_fnErf, fnErf, 0, true, configureErfReal);
  failures += runCase("fnErfc/real", oracle_fnErfc, fnErfc, 0, true, configureErfcReal);
  failures += runCase("fn2Pow/real", oracle_fn2Pow, fn2Pow, 0, true, configure2PowReal);
  failures += runCase("fn2Pow/real_inf", oracle_fn2Pow, fn2Pow, 0, true, configure2PowRealInfinity);
  failures += runCase("fn2Pow/real_inf_danger", oracle_fn2Pow, fn2Pow, 0, true, configure2PowRealInfinityDanger);
  failures += runCase("fn2Pow/complex", oracle_fn2Pow, fn2Pow, 0, true, configure2PowComplex);
  failures += runCase("fn2Pow/shortint", oracle_fn2Pow, fn2Pow, 0, true, configure2PowShortInteger);
  failures += runCase("fn2Pow/longint", oracle_fn2Pow, fn2Pow, 0, true, configure2PowLongInteger);
  failures += runCase("fn2Pow/longint_negative", oracle_fn2Pow, fn2Pow, 0, true, configure2PowLongIntegerNegative);
  failures += runCase("fn10Pow/real", oracle_fn10Pow, fn10Pow, 0, true, configure10PowReal);
  failures += runCase("fn10Pow/real_inf", oracle_fn10Pow, fn10Pow, 0, true, configure10PowRealInfinity);
  failures += runCase("fn10Pow/real_inf_danger", oracle_fn10Pow, fn10Pow, 0, true, configure10PowRealInfinityDanger);
  failures += runCase("fn10Pow/complex", oracle_fn10Pow, fn10Pow, 0, true, configure10PowComplex);
  failures += runCase("fn10Pow/shortint", oracle_fn10Pow, fn10Pow, 0, true, configure10PowShortInteger);
  failures += runCase("fn10Pow/longint", oracle_fn10Pow, fn10Pow, 0, true, configure10PowLongInteger);
  failures += runCase("fn10Pow/longint_negative", oracle_fn10Pow, fn10Pow, 0, true, configure10PowLongIntegerNegative);
  failures += runCase("fnLog10/real", oracle_fnLog10, fnLog10, 0, true, configureLog2Real);
  failures += runCase("fnLog10/complex", oracle_fnLog10, fnLog10, 0, true, configureLog2Complex);
  failures += runCase("fnLog10/real_zero_danger", oracle_fnLog10, fnLog10, 0, true, configureLnRealZeroDanger);
  failures += runCase("fnLog10/real_negative_complex", oracle_fnLog10, fnLog10, 0, true, configureLnRealNegativeComplex);
  failures += runCase("fnLog10/shortint", oracle_fnLog10, fnLog10, 0, true, configureLog10ShortInteger);
  failures += runCase("fnLog10/longint", oracle_fnLog10, fnLog10, 0, true, configureLog10LongInteger);
  failures += runCase("fnLog2/real", oracle_fnLog2, fnLog2, 0, true, configureLog2Real);
  failures += runCase("fnLog2/complex", oracle_fnLog2, fnLog2, 0, true, configureLog2Complex);
  failures += runCase("fnLog2/shortint", oracle_fnLog2, fnLog2, 0, true, configureLog2ShortInteger);
  failures += runCase("fnLog2/longint", oracle_fnLog2, fnLog2, 0, true, configureLog2LongInteger);
  failures += runCase("fnM1Pow/real_zero", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowRealZero);
  failures += runCase("fnM1Pow/real_one", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowRealOne);
  failures += runCase("fnM1Pow/real_inf", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowRealInfinity);
  failures += runCase("fnM1Pow/complex_zero", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowComplexZero);
  failures += runCase("fnM1Pow/complex_one", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowComplexOne);
  failures += runCase("fnM1Pow/complex_general", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowComplexGeneral);
  failures += runCase("fnM1Pow/shortint_unsigned_odd", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowShortIntegerUnsignedOdd);
  failures += runCase("fnM1Pow/shortint_signed_even", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowShortIntegerSignedEven);
  failures += runCase("fnM1Pow/longint_odd", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowLongIntegerOdd);
  failures += runCase("fnM1Pow/longint_even", oracle_fnM1Pow, fnM1Pow, 0, true, configureM1PowLongIntegerEven);
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