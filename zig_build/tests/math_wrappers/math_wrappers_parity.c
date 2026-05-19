// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void fnMin(uint16_t unusedButMandatoryParameter);
void fnMax(uint16_t unusedButMandatoryParameter);
void fnCeil(uint16_t unusedButMandatoryParameter);
void fnFloor(uint16_t unusedButMandatoryParameter);
void fnIp(uint16_t unusedButMandatoryParameter);
void fnLint(uint16_t unusedButMandatoryParameter);
void fnSint(uint16_t unusedButMandatoryParameter);
void fnFp(uint16_t unusedButMandatoryParameter);
void fnSinc(uint16_t unusedButMandatoryParameter);
void fnSincpi(uint16_t unusedButMandatoryParameter);
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
void fnExpM1(uint16_t unusedButMandatoryParameter);
void fnExpt(uint16_t unusedButMandatoryParameter);
void fnBn(uint16_t unusedButMandatoryParameter);
void fnBnStar(uint16_t unusedButMandatoryParameter);
void fnLn(uint16_t unusedButMandatoryParameter);
void fnLnP1(uint16_t unusedButMandatoryParameter);
void fnSqrt1Px2(uint16_t unusedButMandatoryParameter);
void fnGetType(uint16_t unusedButMandatoryParameter);
void fnErf(uint16_t unusedButMandatoryParameter);
void fnErfc(uint16_t unusedButMandatoryParameter);
void fn2Pow(uint16_t unusedButMandatoryParameter);
void fn10Pow(uint16_t unusedButMandatoryParameter);
void fnLog10(uint16_t unusedButMandatoryParameter);
void fnLog2(uint16_t unusedButMandatoryParameter);
void fnM1Pow(uint16_t unusedButMandatoryParameter);
void fnEulersFormula(uint16_t unusedButMandatoryParameter);
void fnWinverse(uint16_t unusedButMandatoryParameter);
void fnWnegative(uint16_t unusedButMandatoryParameter);
void fnWpositive(uint16_t unusedButMandatoryParameter);
void fnGcd(uint16_t unusedButMandatoryParameter);
void fnLcm(uint16_t unusedButMandatoryParameter);
void fnMod(uint16_t unusedButMandatoryParameter);
void fnRmd(uint16_t unusedButMandatoryParameter);
void fnDblMultiply(uint16_t unusedButMandatoryParameter);
void fnDblDivide(uint16_t unusedButMandatoryParameter);
void fnDblDivideRemainder(uint16_t unusedButMandatoryParameter);
void fnUlp(uint16_t unusedButMandatoryParameter);
void fnMant(uint16_t unusedButMandatoryParameter);
void fnRoundi(uint16_t unusedButMandatoryParameter);
void fnDecomp(uint16_t unusedButMandatoryParameter);
void fnNeighb(uint16_t unusedButMandatoryParameter);
void fnIxyz(uint16_t unusedButMandatoryParameter);
void fnFactorial(uint16_t unusedButMandatoryParameter);
void fnRandomI(uint16_t unusedButMandatoryParameter);
void oracle_fnGetType(uint16_t unusedButMandatoryParameter);

static void setMatrixReal34(real34_t *value, int32_t signedValue, uint8_t bits);
void fnCheckInteger(uint16_t unusedButMandatoryParameter);
void fnCheckForZero(uint16_t unusedButMandatoryParameter);
void fnCheckType(uint16_t unusedButMandatoryParameter);
void fnCheckReal(uint16_t unusedButMandatoryParameter);
void fnCheckAngle(uint16_t unusedButMandatoryParameter);
void fnCheckMatrix(uint16_t unusedButMandatoryParameter);
void fnCheckNumber(uint16_t unusedButMandatoryParameter);
void fnCheckNaN(uint16_t unusedButMandatoryParameter);
void fnCheckInfinite(uint16_t unusedButMandatoryParameter);
void fnCheckSpecial(uint16_t unusedButMandatoryParameter);
void fnCheckPlusZero(uint16_t unusedButMandatoryParameter);
void fnCheckMinusZero(uint16_t unusedButMandatoryParameter);
void fnCheckMatrixSquare(uint16_t unusedButMandatoryParameter);
void fnCheckIsVect2d(uint16_t unusedButMandatoryParameter);
void fnCheckIsVect3d(uint16_t unusedButMandatoryParameter);
void fnRealPart(uint16_t unusedButMandatoryParameter);
void fnImaginaryPart(uint16_t unusedButMandatoryParameter);
void fnArg(uint16_t unusedButMandatoryParameter);
void fnMagnitude(uint16_t unusedButMandatoryParameter);
void fnConjugate(uint16_t unusedButMandatoryParameter);
void fnSwapRealImaginary(uint16_t unusedButMandatoryParameter);
void fnAtan2(uint16_t unusedButMandatoryParameter);
void fnSquare(uint16_t unusedButMandatoryParameter);
void fnCube(uint16_t unusedButMandatoryParameter);
void fnPercent(uint16_t unusedButMandatoryParameter);
void fnToPolar2(uint16_t unusedButMandatoryParameter);
void fnToRect2(uint16_t unusedButMandatoryParameter);
void fnToRect(uint16_t unusedButMandatoryParameter);
void fnParallel(uint16_t unusedButMandatoryParameter);
void fnCross(uint16_t unusedButMandatoryParameter);
void fnDot(uint16_t unusedButMandatoryParameter);
void fnPercentMRR(uint16_t unusedButMandatoryParameter);
void fnPercentPlusMG(uint16_t unusedButMandatoryParameter);
void fnPercentT(uint16_t unusedButMandatoryParameter);
void fnDeltaPercent(uint16_t unusedButMandatoryParameter);
void fnLogXY(uint16_t unusedButMandatoryParameter);
void fnUnitVector(uint16_t unusedButMandatoryParameter);
void fnSdl(uint16_t unusedButMandatoryParameter);
void fnSdr(uint16_t unusedButMandatoryParameter);

void oracle_fnMin(uint16_t unusedButMandatoryParameter);
void oracle_fnMax(uint16_t unusedButMandatoryParameter);
void oracle_fnCeil(uint16_t unusedButMandatoryParameter);
void oracle_fnFloor(uint16_t unusedButMandatoryParameter);
void oracle_fnIp(uint16_t unusedButMandatoryParameter);
void oracle_fnLint(uint16_t unusedButMandatoryParameter);
void oracle_fnSint(uint16_t unusedButMandatoryParameter);
void oracle_fnFp(uint16_t unusedButMandatoryParameter);
void oracle_fnSinc(uint16_t unusedButMandatoryParameter);
void oracle_fnSincpi(uint16_t unusedButMandatoryParameter);
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
void oracle_fnExpM1(uint16_t unusedButMandatoryParameter);
void oracle_fnExpt(uint16_t unusedButMandatoryParameter);
void oracle_fnBn(uint16_t unusedButMandatoryParameter);
void oracle_fnBnStar(uint16_t unusedButMandatoryParameter);
void oracle_fnLn(uint16_t unusedButMandatoryParameter);
void oracle_fnLnP1(uint16_t unusedButMandatoryParameter);
void oracle_fnSqrt1Px2(uint16_t unusedButMandatoryParameter);
void oracle_fnErf(uint16_t unusedButMandatoryParameter);
void oracle_fnErfc(uint16_t unusedButMandatoryParameter);
void oracle_fn2Pow(uint16_t unusedButMandatoryParameter);
void oracle_fn10Pow(uint16_t unusedButMandatoryParameter);
void oracle_fnLog10(uint16_t unusedButMandatoryParameter);
void oracle_fnLog2(uint16_t unusedButMandatoryParameter);
void oracle_fnM1Pow(uint16_t unusedButMandatoryParameter);
void oracle_fnEulersFormula(uint16_t unusedButMandatoryParameter);
void oracle_fnWinverse(uint16_t unusedButMandatoryParameter);
void oracle_fnWnegative(uint16_t unusedButMandatoryParameter);
void oracle_fnWpositive(uint16_t unusedButMandatoryParameter);
void oracle_fnGcd(uint16_t unusedButMandatoryParameter);
void oracle_fnLcm(uint16_t unusedButMandatoryParameter);
void oracle_fnMod(uint16_t unusedButMandatoryParameter);
void oracle_fnRmd(uint16_t unusedButMandatoryParameter);
void oracle_fnDblMultiply(uint16_t unusedButMandatoryParameter);
void oracle_fnDblDivide(uint16_t unusedButMandatoryParameter);
void oracle_fnDblDivideRemainder(uint16_t unusedButMandatoryParameter);
void oracle_fnUlp(uint16_t unusedButMandatoryParameter);
void oracle_fnMant(uint16_t unusedButMandatoryParameter);
void oracle_fnRoundi(uint16_t unusedButMandatoryParameter);
void oracle_fnDecomp(uint16_t unusedButMandatoryParameter);
void oracle_fnNeighb(uint16_t unusedButMandatoryParameter);
void oracle_fnIxyz(uint16_t unusedButMandatoryParameter);
void oracle_fnFactorial(uint16_t unusedButMandatoryParameter);
void oracle_fnRandomI(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckInteger(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckForZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckType(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckReal(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckAngle(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckMatrix(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckNumber(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckNaN(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckInfinite(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckSpecial(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckPlusZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckMinusZero(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckMatrixSquare(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckIsVect2d(uint16_t unusedButMandatoryParameter);
void oracle_fnCheckIsVect3d(uint16_t unusedButMandatoryParameter);
void oracle_fnRealPart(uint16_t unusedButMandatoryParameter);
void oracle_fnImaginaryPart(uint16_t unusedButMandatoryParameter);
void oracle_fnArg(uint16_t unusedButMandatoryParameter);
void oracle_fnMagnitude(uint16_t unusedButMandatoryParameter);
void oracle_fnConjugate(uint16_t unusedButMandatoryParameter);
void oracle_fnSwapRealImaginary(uint16_t unusedButMandatoryParameter);
void oracle_fnAtan2(uint16_t unusedButMandatoryParameter);
void oracle_fnSquare(uint16_t unusedButMandatoryParameter);
void oracle_fnCube(uint16_t unusedButMandatoryParameter);
void oracle_fnPercent(uint16_t unusedButMandatoryParameter);
void oracle_fnToPolar2(uint16_t unusedButMandatoryParameter);
void oracle_fnToRect2(uint16_t unusedButMandatoryParameter);
void oracle_fnToRect(uint16_t unusedButMandatoryParameter);
void oracle_fnParallel(uint16_t unusedButMandatoryParameter);
void oracle_fnCross(uint16_t unusedButMandatoryParameter);
void oracle_fnDot(uint16_t unusedButMandatoryParameter);
void oracle_fnPercentMRR(uint16_t unusedButMandatoryParameter);
void oracle_fnPercentPlusMG(uint16_t unusedButMandatoryParameter);
void oracle_fnPercentT(uint16_t unusedButMandatoryParameter);
void oracle_fnDeltaPercent(uint16_t unusedButMandatoryParameter);
void oracle_fnLogXY(uint16_t unusedButMandatoryParameter);
void oracle_fnUnitVector(uint16_t unusedButMandatoryParameter);
void oracle_fnSdl(uint16_t unusedButMandatoryParameter);
void oracle_fnSdr(uint16_t unusedButMandatoryParameter);

typedef void (*math_wrapper_fn)(uint16_t);
typedef void (*math_wrapper_config_fn)(void);

enum {
  parity_CHECK_INTEGER = 0,
  parity_CHECK_INTEGER_EVEN = 1,
  parity_CHECK_INTEGER_ODD = 2,
  parity_CHECK_INTEGER_FP = 3,
  parity_ITM_ISREZQ = 2527,
  parity_ITM_ISIMZQ = 2528,
  parity_ITM_ISRENZQ = 2529,
  parity_ITM_ISIMNZQ = 2530,
};

static void printMatrixSummary(const char *label, const math_wrappers_snapshot_t *snapshot) {
  fprintf(stderr,
          "  %s matrix: real=%ux%u [%d/%u,%d/%u,%d/%u,%d/%u] complex=%ux%u [(%d/%u,%d/%u),(%d/%u,%d/%u),(%d/%u,%d/%u),(%d/%u,%d/%u)]\n",
          label,
          snapshot->final_real_matrix_rows,
          snapshot->final_real_matrix_columns,
          snapshot->final_real_matrix_values[0],
          snapshot->final_real_matrix_bits[0],
          snapshot->final_real_matrix_values[1],
          snapshot->final_real_matrix_bits[1],
          snapshot->final_real_matrix_values[2],
          snapshot->final_real_matrix_bits[2],
          snapshot->final_real_matrix_values[3],
          snapshot->final_real_matrix_bits[3],
          snapshot->final_complex_matrix_rows,
          snapshot->final_complex_matrix_columns,
          snapshot->final_complex_matrix_real_values[0],
          snapshot->final_complex_matrix_real_bits[0],
          snapshot->final_complex_matrix_imag_values[0],
          snapshot->final_complex_matrix_imag_bits[0],
          snapshot->final_complex_matrix_real_values[1],
          snapshot->final_complex_matrix_real_bits[1],
          snapshot->final_complex_matrix_imag_values[1],
          snapshot->final_complex_matrix_imag_bits[1],
          snapshot->final_complex_matrix_real_values[2],
          snapshot->final_complex_matrix_real_bits[2],
          snapshot->final_complex_matrix_imag_values[2],
          snapshot->final_complex_matrix_imag_bits[2],
          snapshot->final_complex_matrix_real_values[3],
          snapshot->final_complex_matrix_real_bits[3],
          snapshot->final_complex_matrix_imag_values[3],
          snapshot->final_complex_matrix_imag_bits[3]);
}

static int reportMismatch(const char *name,
                          uint16_t arg,
                          const math_wrappers_snapshot_t *expected,
                          const math_wrappers_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: dtype=%u tag=%u save=%u/%d mono=%u imono=%u dyad=%u longIn=%u/%d longInQ=%u/%u/%d/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u rdiv=%u(%d/%d) cmp=%u(%d,%d) divr=%u(%d;%d,%d) invm=%u cplxi=%u(%d,%d) cplxmul=%u ang=%u(%d;%d->%d) set=%u(%d) refresh=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu yshort=%llu long=%d ylong=%d ovf=%d carry=%d\n"
          "  actual:   dtype=%u tag=%u save=%u/%d mono=%u imono=%u dyad=%u longIn=%u/%d longInQ=%u/%u/%d/%d longOut=%u/%d cvt=%u trig=%u sinh=%u mul=%u rdiv=%u(%d/%d) cmp=%u(%d,%d) divr=%u(%d;%d,%d) invm=%u cplxi=%u(%d,%d) cplxmul=%u ang=%u(%d;%d->%d) set=%u(%d) refresh=%u unit=%u chs=%u intmul=%u realOut=%u complexOut=%u err=%u more=%u final=%d/%u short=%llu yshort=%llu long=%d ylong=%d ovf=%d carry=%d\n",
          name,
          arg,
      expected->final_register_data_type,
      expected->final_register_tag,
          expected->save_last_x_calls,
          expected->save_last_x_result,
          expected->process_real_complex_monadic_calls,
          expected->process_int_real_complex_monadic_calls,
            expected->process_int_real_complex_dyadic_calls,
      expected->get_register_as_longint_calls,
      expected->get_register_as_longint_value,
      expected->get_register_as_longint_quiet_calls,
      expected->get_register_as_longint_quiet_error,
      expected->get_register_as_longint_quiet_fractional,
      expected->get_register_as_longint_quiet_value,
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
          (unsigned long long)expected->final_register_y_shortint_raw,
          expected->final_register_longint_value,
          expected->final_register_y_longint_value,
            expected->final_overflow_flag,
            expected->final_carry_flag,
      actual->final_register_data_type,
      actual->final_register_tag,
          actual->save_last_x_calls,
          actual->save_last_x_result,
          actual->process_real_complex_monadic_calls,
          actual->process_int_real_complex_monadic_calls,
          actual->process_int_real_complex_dyadic_calls,
      actual->get_register_as_longint_calls,
          actual->get_register_as_longint_value,
        actual->get_register_as_longint_quiet_calls,
        actual->get_register_as_longint_quiet_error,
        actual->get_register_as_longint_quiet_fractional,
        actual->get_register_as_longint_quiet_value,
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
          (unsigned long long)actual->final_register_y_shortint_raw,
          actual->final_register_longint_value,
          actual->final_register_y_longint_value,
          actual->final_overflow_flag,
          actual->final_carry_flag);

  if(expected->final_register_data_type == dtReal34Matrix ||
     expected->final_register_data_type == dtComplex34Matrix ||
     actual->final_register_data_type == dtReal34Matrix ||
     actual->final_register_data_type == dtComplex34Matrix) {
    printMatrixSummary("expected", expected);
    printMatrixSummary("actual", actual);
  }

  return 1;
}

static void normalizeRegisterMetadataGetterCounts(math_wrappers_snapshot_t *snapshot) {
  snapshot->get_register_data_type_calls = 0;
  snapshot->get_register_tag_calls = 0;
  snapshot->get_register_data_pointer_calls = 0;
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

static int runCaseIgnoringRegisterMetadataGetters(const char *name,
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

  normalizeRegisterMetadataGetterCounts(&expected);
  normalizeRegisterMetadataGetterCounts(&actual);
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

static void configureSincReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 5, 0);
}

static void configureSincRealInfinity(void) {
  configureSincReal();
  mathWrappersSetRealInput(true, 9, 0x40);
  mathWrappersSetFlagSpcRes(true);
}

static void configureSincRealInfinityDanger(void) {
  configureSincReal();
  mathWrappersSetRealInput(true, 9, 0x40);
  mathWrappersSetFlagSpcRes(false);
}

static void configureSincComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureSincpiReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 4, 0);
}

static void configureSincpiShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetShortIntegerInput(4);
}

static void configureSincpiComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
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

static void configureExptReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 456, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureExptRealNaN(void) {
  configureExptReal();
  mathWrappersSetRealInput(true, 0, 0x20);
}

static void configureExptRealInfinity(void) {
  configureExptReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureExptLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 1234);
  mathWrappersSetRealInput(true, 1234, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureBnPositive(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureBnZero(void) {
  configureBnPositive();
  mathWrappersSetRealInput(true, 0, 0);
}

static void configureWpositiveReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 2, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(false);
}

static void configureWpositiveRealComplexFallback(void) {
  configureWpositiveReal();
  mathWrappersSetRealInput(true, -2, 0);
  mathWrappersSetFlagCpxRes(true);
}

static void configureWpositiveRealDomainError(void) {
  configureWpositiveRealComplexFallback();
  mathWrappersSetFlagCpxRes(false);
}

static void configureWpositiveComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureWnegativeReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, -1, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureWnegativeRealDomainError(void) {
  configureWnegativeReal();
  mathWrappersSetRealInput(true, 2, 0);
}

static void configureWnegativeComplexZeroImag(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, -1, 0, 0, 0);
}

static void configureWnegativeComplexImagError(void) {
  configureWnegativeComplexZeroImag();
  mathWrappersSetComplexInput(true, -1, 0, 1, 0);
}

static void configureWinverseReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 3, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureWinverseComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 3, 0, 4, 0);
}

static void configureDyadicLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -6);
  mathWrappersSetLongIntegerYInput(true, 9);
}

static void configureDyadicShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(-6);
  mathWrappersSetShortIntegerYInput(9);
}

static void configureModuloReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetRealYInput(true, 9, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureModuloLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 4);
  mathWrappersSetLongIntegerYInput(true, 9);
}

static void configureModuloShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(4);
  mathWrappersSetShortIntegerYInput(9);
  mathWrappersSetLongIntegerInput(true, 4);
  mathWrappersSetLongIntegerYInput(true, 9);
}

static void configureDblMultiplyLowWord(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(7);
  mathWrappersSetShortIntegerYInput(9);
  mathWrappersSetFlagOverflow(true);
}

static void configureDblMultiplyHighWord(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(((int64_t)1) << 32);
  mathWrappersSetShortIntegerYInput(((int64_t)1) << 32);
  mathWrappersSetFlagOverflow(true);
}

static void configureDblMultiplyTypeError(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
}

static void configureDblDivideQuotient(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(3);
  mathWrappersSetShortIntegerYInput(0);
  mathWrappersSetShortIntegerZInput(10);
  mathWrappersSetFlagCarry(false);
  mathWrappersSetFlagOverflow(true);
}

static void configureDblDivideExact(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(3);
  mathWrappersSetShortIntegerYInput(0);
  mathWrappersSetShortIntegerZInput(12);
  mathWrappersSetFlagCarry(true);
  mathWrappersSetFlagOverflow(true);
}

static void configureDblDivideRemainderMode(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(3);
  mathWrappersSetShortIntegerYInput(0);
  mathWrappersSetShortIntegerZInput(10);
  mathWrappersSetFlagCarry(true);
  mathWrappersSetFlagOverflow(true);
}

static void configureDblDivideByZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(0);
  mathWrappersSetShortIntegerYInput(0);
  mathWrappersSetShortIntegerZInput(10);
}

static void configureDblDivideOverflow(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(2);
  mathWrappersSetShortIntegerYInput(1);
  mathWrappersSetShortIntegerZInput(0);
  mathWrappersSetFlagCarry(true);
  mathWrappersSetFlagOverflow(false);
}

static void configureDblDivideTypeError(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
}

static void configureRmdReal(void) {
  configureModuloReal();
}

static void configureRmdLongInteger(void) {
  configureModuloLongInteger();
}

static void configureUlpReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 12, 0);
}

static void configureUlpLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 12);
}

static void configureUlpShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(12);
}

static void configureUlpInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureMantReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 456, 0);
}

static void configureMantInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureMantRealNaN(void) {
  configureMantReal();
  mathWrappersSetRealInput(true, 0, 0x20);
}

static void configureMantLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 456);
}

static void configureRoundiReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 12, 0);
}

static void configureRoundiRealNaN(void) {
  configureRoundiReal();
  mathWrappersSetRealInput(true, 0, 0x20);
}

static void configureRoundiRealInfinity(void) {
  configureRoundiReal();
  mathWrappersSetRealInput(true, 9, 0x40);
}

static void configureRoundiLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -456);
}

static void configureRoundiShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(0x2345);
}

static void configureRoundiMatrix(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], -2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureRoundiInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureSdlReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 12, 0);
}

static void configureSdlLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 345);
}

static void configureSdlInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureSdrReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 1200, 0);
}

static void configureSdrLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 34567);
}

static void configureSdrInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureParallelReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetRealYInput(true, 9, 0);
}

static void configureParallelComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetRealYInput(true, 5, 0);
}

static void configureCrossReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 6, 0);
  mathWrappersSetRealYInput(true, 7, 0);
}

static void configureCrossComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetRealYInput(true, 5, 0);
}

static void configureDotReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 6, 0);
  mathWrappersSetRealYInput(true, 7, 0);
}

static void configureDotComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetRealYInput(true, 5, 0);
}

static void configurePercentMRRReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 8, 0);
  mathWrappersSetRealYInput(true, 2, 0);
  mathWrappersSetRealZInput(true, 100, 0);
}

static void configurePercentMRRSpcResZeroZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetRealYInput(true, 0, 0);
  mathWrappersSetRealZInput(true, 100, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configurePercentPlusMGReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 20, 0);
  mathWrappersSetRealYInput(true, 50, 0);
}

static void configurePercentPlusMGSpcRes(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 100, 0);
  mathWrappersSetRealYInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configurePercentTReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
  mathWrappersSetRealYInput(true, 20, 0);
}

static void configurePercentTSpcRes(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
  mathWrappersSetRealYInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureDeltaPercentReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 15, 0);
  mathWrappersSetRealYInput(true, 10, 0);
}

static void configureDeltaPercentSpcRes(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
  mathWrappersSetRealYInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureLogXYReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 8, 0);
  mathWrappersSetRealYInput(true, 2, 0);
}

static void configureLogXYComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetRealYInput(true, 5, 0);
}

static void configureLogXYShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(8);
  mathWrappersSetShortIntegerYInput(2);
}

static void configureLogXYLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 8);
  mathWrappersSetLongIntegerYInput(true, 2);
}

static void configureLogXYSpcResZeroZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetRealYInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureUnitVectorComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 0, 0, 5, 0);
}

static void configureUnitVectorRealMatrix(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0], 0, 0);
  setMatrixReal34(&matrix.matrixElements[1], 0, 0);
  setMatrixReal34(&matrix.matrixElements[2], 0, 0);
  setMatrixReal34(&matrix.matrixElements[3], 5, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureUnitVectorComplexMatrix(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0].real, 0, 0);
  setMatrixReal34(&matrix.matrixElements[0].imag, 0, 0);
  setMatrixReal34(&matrix.matrixElements[1].real, 0, 0);
  setMatrixReal34(&matrix.matrixElements[1].imag, 0, 0);
  setMatrixReal34(&matrix.matrixElements[2].real, 0, 0);
  setMatrixReal34(&matrix.matrixElements[2].imag, 0, 0);
  setMatrixReal34(&matrix.matrixElements[3].real, 0, 0);
  setMatrixReal34(&matrix.matrixElements[3].imag, 5, 0);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
}

static void configureUnitVectorInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureDecompLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -6);
}

static void configureDecompRealFraction(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, -7, 0);
  mathWrappersSetFractionResult(true, -1, 1, 3, 4, 0);
}

static void configureDecompRealNaN(void) {
  configureDecompRealFraction();
  mathWrappersSetRealInput(true, 0, 0x20);
}

static void configureDecompRealInfinity(void) {
  configureDecompRealFraction();
  mathWrappersSetRealInput(true, 0, 0xc0);
}

static void configureDecompTypeError(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureNeighbReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetRealYInput(true, 9, 0);
}

static void configureNeighbLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 4);
  mathWrappersSetLongIntegerYInput(true, 9);
}

static void configureIxyzValid(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 1, 0);
  mathWrappersSetRealYInput(true, 2, 0);
  mathWrappersSetRealZInput(true, 3, 0);
}

static void configureIxyzDomainError(void) {
  configureIxyzValid();
  mathWrappersSetRealInput(true, 2, 0);
}

static void configureFactorialReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureFactorialComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureFactorialLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 5);
}

static void configureRandomILongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 2);
  mathWrappersSetLongIntegerYInput(true, 5);
  mathWrappersSetPcgState(123456789ULL, 987654321ULL);
}

static void configureCheckIntegerLongIntegerOdd(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 7);
}

static void configureCheckIntegerLongIntegerEven(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 6);
}

static void configureCheckIntegerShortIntegerOdd(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(7);
}

static void configureCheckIntegerShortIntegerEven(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(6);
}

static void configureCheckIntegerRealInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 6, 0);
  mathWrappersSetLongIntegerQuietResult(false, ERROR_NONE, false, 0);
}

static void configureCheckIntegerRealFractional(void) {
  configureCheckIntegerRealInteger();
  mathWrappersSetLongIntegerQuietResult(true, ERROR_NONE, true, 6);
}

static void configureCheckIntegerRealNaN(void) {
  configureCheckIntegerRealInteger();
  mathWrappersSetRealInput(true, 0, 0x20);
}

static void configureCheckIntegerTypeError(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
}

static void configureCheckForZeroRealNonzero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
}

static void configureCheckForZeroComplexNonzero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
}

static void configureCheckTypeLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 7);
}

static void configureCheckRealMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
}

static void configureCheckAngleTrue(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 7, 0);
}

static void configureCheckAngleFalse(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 7, 0);
}

static void configureCheckMatrixTrue(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
}

static void configureGetTypeLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 7);
}

static void configureGetTypeRealDegree(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 7, 0);
}

static void configureGetTypeShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(0x1234);
}

static void configureGetTypeRealMatrixVector2D(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 2);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amDegree | amPolar);
}

static void configureGetTypeRealMatrixCylinder(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 3, 1);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amDegree);
}

static void configureGetTypeRealMatrixSquare(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
}

static void configureGetTypeComplexMatrixPolarRow(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 1, 2);
  setMatrixReal34(&matrix.matrixElements[0].real, 1, 0);
  setMatrixReal34(&matrix.matrixElements[0].imag, 5, 0);
  setMatrixReal34(&matrix.matrixElements[1].real, 2, 0);
  setMatrixReal34(&matrix.matrixElements[1].imag, 6, 0);
  setMatrixReal34(&matrix.matrixElements[2].real, 3, 0);
  setMatrixReal34(&matrix.matrixElements[2].imag, 7, 0);
  setMatrixReal34(&matrix.matrixElements[3].real, 4, 0);
  setMatrixReal34(&matrix.matrixElements[3].imag, 8, 0);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtComplex34Matrix, amDegree | amPolar);
}

static void configureGetTypeConfig(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtConfig, amNone);
}

static void configureCheckNaNComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 0, 0x20);
}

static void configureCheckLongIntegerZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_ZERO);
  mathWrappersSetLongIntegerInput(true, 0);
}

static void configureCheckShortIntegerZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(0);
}

static void configureCheckRealPositiveZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0);
}

static void configureCheckRealNegativeZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 0, 0x80);
}

static void configureCheckComplexPositiveZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 0, 0, 0, 0);
}

static void configureCheckComplexNegativeZero(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 0, 0x80, 0, 0x80);
}

static void configureCheckMatrixSquareRealSquare(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckMatrixSquareRealNonsquare(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 1);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckMatrixSquareComplexSquare(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 2);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
}

static void configureCheckMatrixSquareComplexNonsquare(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 1);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
}

static void configureCheckVect2dTrue(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 1);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckVect2dFalse(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 3, 1);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckVect3dTrue(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 3, 1);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckNaNRealMatrixFalse(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckNaNRealMatrixTrue(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  matrix.matrixElements[2].bytes[15] = 0x20;
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckNaNComplexMatrixFalse(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 2);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
}

static void configureCheckNaNComplexMatrixTrue(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 2);
  matrix.matrixElements[1].imag.bytes[15] = 0x20;
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
}

static void configureCheckInfiniteRealMatrixTrue(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  matrix.matrixElements[3].bytes[15] = 0x40;
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
}

static void configureCheckInfiniteComplexMatrixTrue(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 2);
  matrix.matrixElements[2].real.bytes[15] = 0x40;
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
}

static void configureFactorialShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(5);
}

static void configureRealPartReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, 12, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureRealPartComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 4, 0, 7, 0);
}

static void configureRealPartRealMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureRealPartComplexMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureImaginaryPartReal(void) {
  configureRealPartReal();
}

static void configureImaginaryPartComplex(void) {
  configureRealPartComplex();
}

static void configureImaginaryPartRealMatrix(void) {
  configureRealPartRealMatrix();
}

static void configureImaginaryPartComplexMatrix(void) {
  configureRealPartComplexMatrix();
}

static void setMatrixReal34(real34_t *value, int32_t signedValue, uint8_t bits) {
  uint32_t magnitude = (uint32_t)(signedValue < 0 ? -signedValue : signedValue);

  memset(value, 0, sizeof(*value));
  memcpy(value->bytes, &magnitude, sizeof(magnitude));
  value->bytes[15] = bits;
  if(signedValue < 0) {
    value->bytes[15] |= 0x80;
  }
}

static void configureArgRealPositive(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 5, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureArgRealNegative(void) {
  configureArgRealPositive();
  mathWrappersSetRealInput(true, -5, 0);
}

static void configureArgComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 3, 0, 4, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureArgRealMatrix(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0], 5, 0);
  setMatrixReal34(&matrix.matrixElements[1], -5, 0);
  setMatrixReal34(&matrix.matrixElements[2], 0, 0);
  setMatrixReal34(&matrix.matrixElements[3], 0, 0x20);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetCurrentAngularMode(amRadian);
  mathWrappersSetFlagSpcRes(false);
}

static void configureArgComplexMatrix(void) {
  complex34Matrix_t matrix;

  configureDefaultSurface();
  complexMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0].real, 1, 0);
  setMatrixReal34(&matrix.matrixElements[0].imag, 5, 0);
  setMatrixReal34(&matrix.matrixElements[1].real, 2, 0);
  setMatrixReal34(&matrix.matrixElements[1].imag, 1, 0);
  setMatrixReal34(&matrix.matrixElements[2].real, -3, 0);
  setMatrixReal34(&matrix.matrixElements[2].imag, 4, 0);
  setMatrixReal34(&matrix.matrixElements[3].real, 0, 0);
  setMatrixReal34(&matrix.matrixElements[3].imag, -2, 0);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
  complexMatrixFree(&matrix);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureMagnitudeReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amDegree);
  mathWrappersSetRealInput(true, -5, 0);
}

static void configureMagnitudeRealMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureMagnitudeComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 3, 0, 4, 0);
}

static void configureMagnitudeComplexMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureMagnitudeLongInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -8);
}

static void configureMagnitudeShortInteger(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtShortInteger, 16);
  mathWrappersSetShortIntegerInput(-6);
}

static void configureConjugateComplex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 3, 0, 4, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureConjugateRealMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(true);
}

static void configureConjugateComplexMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureSwapRealImaginaryComplex(void) {
  configureConjugateComplex();
}

static void configureSwapRealImaginaryRealMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureSwapRealImaginaryComplexMatrix(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34Matrix, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureAtan2Real(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetRealYInput(true, 9, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureAtan2ZeroDomain(void) {
  configureAtan2Real();
  mathWrappersSetRealInput(true, 0, 0);
  mathWrappersSetRealYInput(true, 0, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureAtan2XMatrixYReal(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], -3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRealYInput(true, 9, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureAtan2XMatrixYLongInteger(void) {
  configureAtan2XMatrixYReal();
  mathWrappersSetLongIntegerYInput(true, -8);
}

static void configureAtan2XMatrixYMatrix(void) {
  real34Matrix_t matrix_x;
  real34Matrix_t matrix_y;

  configureDefaultSurface();
  realMatrixInit(&matrix_x, 2, 2);
  realMatrixInit(&matrix_y, 2, 2);
  setMatrixReal34(&matrix_x.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix_x.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix_x.matrixElements[2], -3, 0);
  setMatrixReal34(&matrix_x.matrixElements[3], 4, 0);
  setMatrixReal34(&matrix_y.matrixElements[0], 5, 0);
  setMatrixReal34(&matrix_y.matrixElements[1], -6, 0);
  setMatrixReal34(&matrix_y.matrixElements[2], 7, 0);
  setMatrixReal34(&matrix_y.matrixElements[3], 8, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix_x, REGISTER_X);
  convertReal34MatrixToReal34MatrixRegister(&matrix_y, REGISTER_Y);
  realMatrixFree(&matrix_x);
  realMatrixFree(&matrix_y);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureAtan2XRealYMatrix(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 2, 2);
  setMatrixReal34(&matrix.matrixElements[0], 5, 0);
  setMatrixReal34(&matrix.matrixElements[1], -6, 0);
  setMatrixReal34(&matrix.matrixElements[2], 7, 0);
  setMatrixReal34(&matrix.matrixElements[3], 8, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_Y);
  realMatrixFree(&matrix);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureAtan2XLongIntegerYMatrix(void) {
  configureAtan2XRealYMatrix();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_NEGATIVE);
  mathWrappersSetLongIntegerInput(true, -4);
}

static void configureAtan2XMatrixYMatrixMismatch(void) {
  real34Matrix_t matrix_x;
  real34Matrix_t matrix_y;

  configureDefaultSurface();
  realMatrixInit(&matrix_x, 2, 2);
  realMatrixInit(&matrix_y, 2, 1);
  convertReal34MatrixToReal34MatrixRegister(&matrix_x, REGISTER_X);
  convertReal34MatrixToReal34MatrixRegister(&matrix_y, REGISTER_Y);
  realMatrixFree(&matrix_x);
  realMatrixFree(&matrix_y);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureLnP1Real(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(false);
}

static void configureLnP1RealMinusOne(void) {
  configureLnP1Real();
  mathWrappersSetRealInput(true, -1, 0);
}

static void configureLnP1RealMinusOneDanger(void) {
  configureLnP1RealMinusOne();
  mathWrappersSetFlagSpcRes(true);
}

static void configureLnP1RealNegativeComplex(void) {
  configureLnP1Real();
  mathWrappersSetRealInput(true, -8, 0);
  mathWrappersSetFlagCpxRes(true);
}

static void configureLnP1RealNegativeDanger(void) {
  configureLnP1RealNegativeComplex();
  mathWrappersSetFlagCpxRes(false);
  mathWrappersSetFlagSpcRes(true);
}

static void configureLnP1Complex(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetRealInput(false, 0, 0);
  mathWrappersSetComplexInput(true, 2, 0, 3, 0);
  mathWrappersSetFlagSpcRes(false);
}

static void configureLnP1ComplexMinusOneDanger(void) {
  configureLnP1Complex();
  mathWrappersSetComplexInput(true, -1, 0, 0, 0);
  mathWrappersSetFlagSpcRes(true);
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

static void configurePercentReal(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 4, 0);
  mathWrappersSetRealYInput(true, 25, 0);
  mathWrappersSetComplexInput(false, 0, 0, 0, 0);
}

static void configureToPolar2Real34Pair(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 2, 0);
  mathWrappersSetRealYInput(true, 3, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToPolar2LongIntegerPair(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 2);
  mathWrappersSetLongIntegerYInput(true, 3);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToPolar2InvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureToPolar2ComplexNoAngle(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amNone);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToPolar2Vector2D(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 2);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToPolar23DRect(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 3);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amNone);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToPolar23DSpherical(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 3);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amDegree | amPolar);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToRect2Real34Pair(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 2, 0);
  mathWrappersSetRealYInput(true, 3, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToRect2LongIntegerPair(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 2);
  mathWrappersSetLongIntegerYInput(true, 3);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureToRect2InvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
}

static void configureToRect2ComplexPolar(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtComplex34, amDegree | amPolar);
}

static void configureToRect2Vector2D(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 2);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amDegree | amPolar);
}

static void configureToRect23DSpherical(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 3);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amDegree | amPolar);
}

static void configureToRect23DCylindrical(void) {
  real34Matrix_t matrix;

  configureDefaultSurface();
  realMatrixInit(&matrix, 1, 3);
  setMatrixReal34(&matrix.matrixElements[0], 1, 0);
  setMatrixReal34(&matrix.matrixElements[1], 2, 0);
  setMatrixReal34(&matrix.matrixElements[2], 3, 0);
  setMatrixReal34(&matrix.matrixElements[3], 4, 0);
  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
  realMatrixFree(&matrix);
  mathWrappersSetRegisterSurface(dtReal34Matrix, amDegree);
}

static void configureFnToRectReal34Pair(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 3, 0);
  mathWrappersSetRealYInput(true, 2, 0);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureFnToRectLongIntegerPair(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, LI_POSITIVE);
  mathWrappersSetLongIntegerInput(true, 3);
  mathWrappersSetLongIntegerYInput(true, 2);
  mathWrappersSetCurrentAngularMode(amDegree);
}

static void configureFnToRectInvalidType(void) {
  configureDefaultSurface();
  mathWrappersSetRegisterSurface(dtTime, amNone);
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
  failures += runCase("fnLint/shortint", oracle_fnLint, fnLint, 0, true, configure2PowShortInteger);
  failures += runCase("fnLint/longint", oracle_fnLint, fnLint, 0, true, configure2PowLongInteger);
  failures += runCase("fnSint/shortint", oracle_fnSint, fnSint, 0, true, configure2PowShortInteger);
  failures += runCase("fnSint/longint", oracle_fnSint, fnSint, 0, true, configure2PowLongInteger);
  failures += runCase("fnFp/real", oracle_fnFp, fnFp, 0, true, configure2PowReal);
  failures += runCase("fnFp/shortint", oracle_fnFp, fnFp, 0, true, configure2PowShortInteger);
  failures += runCase("fnFp/longint", oracle_fnFp, fnFp, 0, true, configure2PowLongInteger);
  failures += runCase("fnSinc/real", oracle_fnSinc, fnSinc, 0, true, configureSincReal);
  failures += runCase("fnSinc/real_inf", oracle_fnSinc, fnSinc, 0, true, configureSincRealInfinity);
  failures += runCase("fnSinc/real_inf_danger", oracle_fnSinc, fnSinc, 0, true, configureSincRealInfinityDanger);
  failures += runCase("fnSinc/complex", oracle_fnSinc, fnSinc, 0, true, configureSincComplex);
  failures += runCase("fnSincpi/real", oracle_fnSincpi, fnSincpi, 0, true, configureSincpiReal);
  failures += runCase("fnSincpi/shortint", oracle_fnSincpi, fnSincpi, 0, true, configureSincpiShortInteger);
  failures += runCase("fnSincpi/complex", oracle_fnSincpi, fnSincpi, 0, true, configureSincpiComplex);
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
  failures += runCase("fnExpt/real", oracle_fnExpt, fnExpt, 0, true, configureExptReal);
  failures += runCase("fnExpt/real_nan", oracle_fnExpt, fnExpt, 0, true, configureExptRealNaN);
  failures += runCase("fnExpt/real_inf", oracle_fnExpt, fnExpt, 0, true, configureExptRealInfinity);
  failures += runCase("fnExpt/longint", oracle_fnExpt, fnExpt, 0, true, configureExptLongInteger);
  failures += runCase("fnBn", oracle_fnBn, fnBn, 0, true, configureBnPositive);
  failures += runCase("fnBn/zero", oracle_fnBn, fnBn, 0, true, configureBnZero);
  failures += runCase("fnBnStar", oracle_fnBnStar, fnBnStar, 0, true, configureBnZero);
  failures += runCase("fnExpM1/real", oracle_fnExpM1, fnExpM1, 0, true, configureExpReal);
  failures += runCase("fnExpM1/real_inf_danger", oracle_fnExpM1, fnExpM1, 0, true, configureExpRealInfinityDanger);
  failures += runCase("fnExpM1/real_neg_inf_danger", oracle_fnExpM1, fnExpM1, 0, true, configureExpRealNegativeInfinityDanger);
  failures += runCase("fnExpM1/complex", oracle_fnExpM1, fnExpM1, 0, true, configureExpComplex);
  failures += runCase("fnExpM1/complex_imag_zero", oracle_fnExpM1, fnExpM1, 0, true, configureExpComplexImagZero);
  failures += runCase("fnExpM1/complex_special", oracle_fnExpM1, fnExpM1, 0, true, configureExpComplexSpecial);
  failures += runCase("fnLn/real", oracle_fnLn, fnLn, 0, true, configureLog2Real);
  failures += runCase("fnLn/real_zero_danger", oracle_fnLn, fnLn, 0, true, configureLnRealZeroDanger);
  failures += runCase("fnLn/real_negative_complex", oracle_fnLn, fnLn, 0, true, configureLnRealNegativeComplex);
  failures += runCase("fnLn/real_negative_danger", oracle_fnLn, fnLn, 0, true, configureLnRealNegativeDanger);
  failures += runCase("fnLn/complex", oracle_fnLn, fnLn, 0, true, configureLog2Complex);
  failures += runCase("fnLn/complex_zero_danger", oracle_fnLn, fnLn, 0, true, configureLnComplexZeroDanger);
  failures += runCase("fnLnP1/real", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1Real);
  failures += runCase("fnLnP1/real_minus_one", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1RealMinusOne);
  failures += runCase("fnLnP1/real_minus_one_danger", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1RealMinusOneDanger);
  failures += runCase("fnLnP1/real_negative_complex", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1RealNegativeComplex);
  failures += runCase("fnLnP1/real_negative_danger", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1RealNegativeDanger);
  failures += runCase("fnLnP1/complex", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1Complex);
  failures += runCase("fnLnP1/complex_minus_one_danger", oracle_fnLnP1, fnLnP1, 0, true, configureLnP1ComplexMinusOneDanger);
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
  failures += runCase("fnWinverse/real", oracle_fnWinverse, fnWinverse, 0, true, configureWinverseReal);
  failures += runCase("fnWinverse/complex", oracle_fnWinverse, fnWinverse, 0, true, configureWinverseComplex);
  failures += runCase("fnWnegative/real", oracle_fnWnegative, fnWnegative, 0, true, configureWnegativeReal);
  failures += runCase("fnWnegative/real_domain", oracle_fnWnegative, fnWnegative, 0, true, configureWnegativeRealDomainError);
  failures += runCase("fnWnegative/complex_zero_imag", oracle_fnWnegative, fnWnegative, 0, true, configureWnegativeComplexZeroImag);
  failures += runCase("fnWnegative/complex_imag_error", oracle_fnWnegative, fnWnegative, 0, true, configureWnegativeComplexImagError);
  failures += runCase("fnWpositive/real", oracle_fnWpositive, fnWpositive, 0, true, configureWpositiveReal);
  failures += runCase("fnWpositive/real_complex_fallback", oracle_fnWpositive, fnWpositive, 0, true, configureWpositiveRealComplexFallback);
  failures += runCase("fnWpositive/real_domain", oracle_fnWpositive, fnWpositive, 0, true, configureWpositiveRealDomainError);
  failures += runCase("fnWpositive/complex", oracle_fnWpositive, fnWpositive, 0, true, configureWpositiveComplex);
  failures += runCase("fnGcd/longint", oracle_fnGcd, fnGcd, 0, true, configureDyadicLongInteger);
  failures += runCase("fnGcd/shortint", oracle_fnGcd, fnGcd, 0, true, configureDyadicShortInteger);
  failures += runCase("fnLcm/longint", oracle_fnLcm, fnLcm, 0, true, configureDyadicLongInteger);
  failures += runCase("fnLcm/shortint", oracle_fnLcm, fnLcm, 0, true, configureDyadicShortInteger);
  failures += runCase("fnMod/real", oracle_fnMod, fnMod, 0, true, configureModuloReal);
  failures += runCase("fnMod/shortint", oracle_fnMod, fnMod, 0, true, configureModuloShortInteger);
  failures += runCase("fnMod/longint", oracle_fnMod, fnMod, 0, true, configureModuloLongInteger);
  failures += runCase("fnRmd/real", oracle_fnRmd, fnRmd, 0, true, configureRmdReal);
  failures += runCase("fnRmd/shortint", oracle_fnRmd, fnRmd, 0, true, configureModuloShortInteger);
  failures += runCase("fnRmd/longint", oracle_fnRmd, fnRmd, 0, true, configureRmdLongInteger);
  failures += runCase("fnDblMultiply/low_word", oracle_fnDblMultiply, fnDblMultiply, 0, true, configureDblMultiplyLowWord);
  failures += runCase("fnDblMultiply/high_word", oracle_fnDblMultiply, fnDblMultiply, 0, true, configureDblMultiplyHighWord);
  failures += runCase("fnDblMultiply/save_last_x_false", oracle_fnDblMultiply, fnDblMultiply, 0, false, configureDblMultiplyLowWord);
  failures += runCase("fnDblMultiply/type_error", oracle_fnDblMultiply, fnDblMultiply, 0, true, configureDblMultiplyTypeError);
  failures += runCase("fnDblDivide/quotient", oracle_fnDblDivide, fnDblDivide, 0, true, configureDblDivideQuotient);
  failures += runCase("fnDblDivide/exact", oracle_fnDblDivide, fnDblDivide, 0, true, configureDblDivideExact);
  failures += runCase("fnDblDivide/save_last_x_false", oracle_fnDblDivide, fnDblDivide, 0, false, configureDblDivideQuotient);
  failures += runCase("fnDblDivide/divide_by_zero", oracle_fnDblDivide, fnDblDivide, 0, true, configureDblDivideByZero);
  failures += runCase("fnDblDivide/overflow", oracle_fnDblDivide, fnDblDivide, 0, true, configureDblDivideOverflow);
  failures += runCase("fnDblDivide/type_error", oracle_fnDblDivide, fnDblDivide, 0, true, configureDblDivideTypeError);
  failures += runCase("fnDblDivideRemainder/remainder", oracle_fnDblDivideRemainder, fnDblDivideRemainder, 0, true, configureDblDivideRemainderMode);
  failures += runCase("fnDblDivideRemainder/save_last_x_false", oracle_fnDblDivideRemainder, fnDblDivideRemainder, 0, false, configureDblDivideRemainderMode);
  failures += runCase("fnUlp/real", oracle_fnUlp, fnUlp, 0, true, configureUlpReal);
  failures += runCase("fnUlp/longint", oracle_fnUlp, fnUlp, 0, true, configureUlpLongInteger);
  failures += runCase("fnUlp/shortint", oracle_fnUlp, fnUlp, 0, true, configureUlpShortInteger);
  failures += runCase("fnUlp/invalid_type", oracle_fnUlp, fnUlp, 0, true, configureUlpInvalidType);
  failures += runCase("fnMant/real", oracle_fnMant, fnMant, 0, true, configureMantReal);
  failures += runCase("fnMant/real_nan", oracle_fnMant, fnMant, 0, true, configureMantRealNaN);
  failures += runCase("fnMant/longint", oracle_fnMant, fnMant, 0, true, configureMantLongInteger);
  failures += runCase("fnMant/invalid_type", oracle_fnMant, fnMant, 0, true, configureMantInvalidType);
  failures += runCase("fnRoundi/real", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiReal);
  failures += runCase("fnRoundi/real_nan", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiRealNaN);
  failures += runCase("fnRoundi/real_inf", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiRealInfinity);
  failures += runCase("fnRoundi/longint", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiLongInteger);
  failures += runCase("fnRoundi/shortint", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiShortInteger);
  failures += runCase("fnRoundi/matrix", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiMatrix);
  failures += runCase("fnRoundi/invalid_type", oracle_fnRoundi, fnRoundi, 0, true, configureRoundiInvalidType);
  failures += runCase("fnParallel/real", oracle_fnParallel, fnParallel, 0, true, configureParallelReal);
  failures += runCase("fnParallel/complex", oracle_fnParallel, fnParallel, 0, true, configureParallelComplex);
  failures += runCase("fnCross/real", oracle_fnCross, fnCross, 0, true, configureCrossReal);
  failures += runCase("fnCross/complex", oracle_fnCross, fnCross, 0, true, configureCrossComplex);
  failures += runCase("fnDot/real", oracle_fnDot, fnDot, 0, true, configureDotReal);
  failures += runCase("fnDot/complex", oracle_fnDot, fnDot, 0, true, configureDotComplex);
  failures += runCase("fnPercentMRR/real", oracle_fnPercentMRR, fnPercentMRR, 0, true, configurePercentMRRReal);
  failures += runCase("fnPercentMRR/spcres_zero_zero", oracle_fnPercentMRR, fnPercentMRR, 0, true, configurePercentMRRSpcResZeroZero);
  failures += runCase("fnPercentPlusMG/real", oracle_fnPercentPlusMG, fnPercentPlusMG, 0, true, configurePercentPlusMGReal);
  failures += runCase("fnPercentPlusMG/spcres", oracle_fnPercentPlusMG, fnPercentPlusMG, 0, true, configurePercentPlusMGSpcRes);
  failures += runCase("fnPercentT/real", oracle_fnPercentT, fnPercentT, 0, true, configurePercentTReal);
  failures += runCase("fnPercentT/spcres", oracle_fnPercentT, fnPercentT, 0, true, configurePercentTSpcRes);
  failures += runCase("fnDeltaPercent/real", oracle_fnDeltaPercent, fnDeltaPercent, 0, true, configureDeltaPercentReal);
  failures += runCase("fnDeltaPercent/spcres", oracle_fnDeltaPercent, fnDeltaPercent, 0, true, configureDeltaPercentSpcRes);
  failures += runCase("fnLogXY/real", oracle_fnLogXY, fnLogXY, 0, true, configureLogXYReal);
  failures += runCase("fnLogXY/complex", oracle_fnLogXY, fnLogXY, 0, true, configureLogXYComplex);
  failures += runCase("fnLogXY/shortint", oracle_fnLogXY, fnLogXY, 0, true, configureLogXYShortInteger);
  failures += runCase("fnLogXY/longint", oracle_fnLogXY, fnLogXY, 0, true, configureLogXYLongInteger);
  failures += runCase("fnLogXY/spcres_zero_zero", oracle_fnLogXY, fnLogXY, 0, true, configureLogXYSpcResZeroZero);
  failures += runCase("fnSdl/real", oracle_fnSdl, fnSdl, 2, true, configureSdlReal);
  failures += runCase("fnSdl/longint", oracle_fnSdl, fnSdl, 2, true, configureSdlLongInteger);
  failures += runCase("fnSdl/invalid_type", oracle_fnSdl, fnSdl, 2, true, configureSdlInvalidType);
  failures += runCase("fnSdr/real", oracle_fnSdr, fnSdr, 2, true, configureSdrReal);
  failures += runCase("fnSdr/longint", oracle_fnSdr, fnSdr, 2, true, configureSdrLongInteger);
  failures += runCase("fnSdr/invalid_type", oracle_fnSdr, fnSdr, 2, true, configureSdrInvalidType);
  failures += runCase("fnUnitVector/complex", oracle_fnUnitVector, fnUnitVector, 0, true, configureUnitVectorComplex);
  failures += runCase("fnUnitVector/real_matrix", oracle_fnUnitVector, fnUnitVector, 0, true, configureUnitVectorRealMatrix);
  failures += runCase("fnUnitVector/complex_matrix", oracle_fnUnitVector, fnUnitVector, 0, true, configureUnitVectorComplexMatrix);
  failures += runCase("fnUnitVector/invalid_type", oracle_fnUnitVector, fnUnitVector, 0, true, configureUnitVectorInvalidType);
  failures += runCase("fnDecomp/longint", oracle_fnDecomp, fnDecomp, 0, true, configureDecompLongInteger);
  failures += runCase("fnDecomp/real_fraction", oracle_fnDecomp, fnDecomp, 0, true, configureDecompRealFraction);
  failures += runCase("fnDecomp/real_nan", oracle_fnDecomp, fnDecomp, 0, true, configureDecompRealNaN);
  failures += runCase("fnDecomp/real_infinity", oracle_fnDecomp, fnDecomp, 0, true, configureDecompRealInfinity);
  failures += runCase("fnDecomp/type_error", oracle_fnDecomp, fnDecomp, 0, true, configureDecompTypeError);
  failures += runCase("fnDecomp/save_last_x_false", oracle_fnDecomp, fnDecomp, 0, false, configureDecompRealFraction);
  failures += runCase("fnNeighb/real", oracle_fnNeighb, fnNeighb, 0, true, configureNeighbReal);
  failures += runCase("fnNeighb/shortint", oracle_fnNeighb, fnNeighb, 0, true, configureDyadicShortInteger);
  failures += runCase("fnNeighb/longint", oracle_fnNeighb, fnNeighb, 0, true, configureNeighbLongInteger);
  failures += runCase("fnIxyz/valid", oracle_fnIxyz, fnIxyz, 0, true, configureIxyzValid);
  failures += runCase("fnIxyz/domain", oracle_fnIxyz, fnIxyz, 0, true, configureIxyzDomainError);
  failures += runCase("fnFactorial/real", oracle_fnFactorial, fnFactorial, 0, true, configureFactorialReal);
  failures += runCase("fnFactorial/complex", oracle_fnFactorial, fnFactorial, 0, true, configureFactorialComplex);
  failures += runCase("fnFactorial/longint", oracle_fnFactorial, fnFactorial, 0, true, configureFactorialLongInteger);
  failures += runCase("fnFactorial/shortint", oracle_fnFactorial, fnFactorial, 0, true, configureFactorialShortInteger);
  failures += runCase("fnRandomI/longint", oracle_fnRandomI, fnRandomI, 0, true, configureRandomILongInteger);
  failures += runCase("fnCheckInteger/longint_int", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER, true, configureCheckIntegerLongIntegerOdd);
  failures += runCase("fnCheckInteger/longint_even", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_EVEN, true, configureCheckIntegerLongIntegerEven);
  failures += runCase("fnCheckInteger/longint_odd", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_ODD, true, configureCheckIntegerLongIntegerOdd);
  failures += runCase("fnCheckInteger/longint_fp", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_FP, true, configureCheckIntegerLongIntegerOdd);
  failures += runCase("fnCheckInteger/shortint_int", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER, true, configureCheckIntegerShortIntegerOdd);
  failures += runCase("fnCheckInteger/shortint_even", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_EVEN, true, configureCheckIntegerShortIntegerEven);
  failures += runCase("fnCheckInteger/shortint_odd", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_ODD, true, configureCheckIntegerShortIntegerOdd);
  failures += runCase("fnCheckInteger/shortint_fp", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_FP, true, configureCheckIntegerShortIntegerOdd);
  failures += runCase("fnCheckInteger/real_int", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER, true, configureCheckIntegerRealInteger);
  failures += runCase("fnCheckInteger/real_even", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_EVEN, true, configureCheckIntegerRealInteger);
  failures += runCase("fnCheckInteger/real_fraction", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER, true, configureCheckIntegerRealFractional);
  failures += runCase("fnCheckInteger/real_fraction_fp", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER_FP, true, configureCheckIntegerRealFractional);
  failures += runCase("fnCheckInteger/real_nan", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER, true, configureCheckIntegerRealNaN);
  failures += runCase("fnCheckInteger/type_error", oracle_fnCheckInteger, fnCheckInteger, parity_CHECK_INTEGER, true, configureCheckIntegerTypeError);
  failures += runCase("fnCheckForZero/longint_re_zero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISREZQ, true, configureCheckLongIntegerZero);
  failures += runCase("fnCheckForZero/longint_re_nonzero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISRENZQ, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckForZero/shortint_re_zero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISREZQ, true, configureCheckShortIntegerZero);
  failures += runCase("fnCheckForZero/shortint_im_nonzero_false", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISIMNZQ, true, configureFactorialShortInteger);
  failures += runCase("fnCheckForZero/real_re_zero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISREZQ, true, configureCheckRealPositiveZero);
  failures += runCase("fnCheckForZero/real_im_zero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISIMZQ, true, configureCheckForZeroRealNonzero);
  failures += runCase("fnCheckForZero/complex_im_zero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISIMZQ, true, configureCheckComplexPositiveZero);
  failures += runCase("fnCheckForZero/complex_im_nonzero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISIMNZQ, true, configureCheckForZeroComplexNonzero);
  failures += runCase("fnCheckForZero/complex_re_nonzero", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISRENZQ, true, configureCheckForZeroComplexNonzero);
  failures += runCase("fnCheckForZero/type_error", oracle_fnCheckForZero, fnCheckForZero, parity_ITM_ISREZQ, true, configureCheckRealMatrix);
  failures += runCase("fnCheckType/true", oracle_fnCheckType, fnCheckType, dtLongInteger, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckType/false", oracle_fnCheckType, fnCheckType, dtReal34, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckReal/true", oracle_fnCheckReal, fnCheckReal, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckReal/false", oracle_fnCheckReal, fnCheckReal, 0, true, configureCheckRealMatrix);
  failures += runCase("fnCheckAngle/true", oracle_fnCheckAngle, fnCheckAngle, 0, true, configureCheckAngleTrue);
  failures += runCase("fnCheckAngle/false", oracle_fnCheckAngle, fnCheckAngle, 0, true, configureCheckAngleFalse);
  failures += runCase("fnCheckMatrix/true", oracle_fnCheckMatrix, fnCheckMatrix, 0, true, configureCheckMatrixTrue);
  failures += runCase("fnCheckMatrix/false", oracle_fnCheckMatrix, fnCheckMatrix, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnGetType/longint", oracle_fnGetType, fnGetType, 0, true, configureGetTypeLongInteger);
  failures += runCase("fnGetType/real_degree", oracle_fnGetType, fnGetType, 0, true, configureGetTypeRealDegree);
  failures += runCase("fnGetType/shortint", oracle_fnGetType, fnGetType, 0, true, configureGetTypeShortInteger);
  failures += runCaseIgnoringRegisterMetadataGetters("fnGetType/real_matrix_vector_2d", oracle_fnGetType, fnGetType, 0, true, configureGetTypeRealMatrixVector2D);
  failures += runCaseIgnoringRegisterMetadataGetters("fnGetType/real_matrix_cyl", oracle_fnGetType, fnGetType, 0, true, configureGetTypeRealMatrixCylinder);
  failures += runCaseIgnoringRegisterMetadataGetters("fnGetType/real_matrix_square", oracle_fnGetType, fnGetType, 0, true, configureGetTypeRealMatrixSquare);
  failures += runCaseIgnoringRegisterMetadataGetters("fnGetType/complex_matrix_polar_row", oracle_fnGetType, fnGetType, 0, true, configureGetTypeComplexMatrixPolarRow);
  failures += runCase("fnGetType/config", oracle_fnGetType, fnGetType, 0, true, configureGetTypeConfig);
  failures += runCase("fnCheckNumber/longint_true", oracle_fnCheckNumber, fnCheckNumber, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckNumber/real_true", oracle_fnCheckNumber, fnCheckNumber, 0, true, configureFactorialReal);
  failures += runCase("fnCheckNumber/real_nan_false", oracle_fnCheckNumber, fnCheckNumber, 0, true, configureSignRealNaN);
  failures += runCase("fnCheckNumber/complex_true", oracle_fnCheckNumber, fnCheckNumber, 0, true, configureFactorialComplex);
  failures += runCase("fnCheckNumber/complex_special_false", oracle_fnCheckNumber, fnCheckNumber, 0, true, configureExpComplexSpecial);
  failures += runCase("fnCheckNumber/matrix_false", oracle_fnCheckNumber, fnCheckNumber, 0, true, configureCheckRealMatrix);
  failures += runCase("fnCheckNaN/real_false", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureFactorialReal);
  failures += runCase("fnCheckNaN/real_true", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureSignRealNaN);
  failures += runCase("fnCheckNaN/complex_false", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureFactorialComplex);
  failures += runCase("fnCheckNaN/complex_true", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureCheckNaNComplex);
  failures += runCase("fnCheckNaN/real_matrix_false", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureCheckNaNRealMatrixFalse);
  failures += runCase("fnCheckNaN/real_matrix_true", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureCheckNaNRealMatrixTrue);
  failures += runCase("fnCheckNaN/complex_matrix_false", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureCheckNaNComplexMatrixFalse);
  failures += runCase("fnCheckNaN/complex_matrix_true", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureCheckNaNComplexMatrixTrue);
  failures += runCase("fnCheckNaN/type_error", oracle_fnCheckNaN, fnCheckNaN, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckInfinite/real_false", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureFactorialReal);
  failures += runCase("fnCheckInfinite/real_true", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureSincRealInfinity);
  failures += runCase("fnCheckInfinite/complex_false", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureFactorialComplex);
  failures += runCase("fnCheckInfinite/complex_true", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureExpComplexSpecial);
  failures += runCase("fnCheckInfinite/real_matrix_false", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureCheckNaNRealMatrixFalse);
  failures += runCase("fnCheckInfinite/real_matrix_true", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureCheckInfiniteRealMatrixTrue);
  failures += runCase("fnCheckInfinite/complex_matrix_false", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureCheckNaNComplexMatrixFalse);
  failures += runCase("fnCheckInfinite/complex_matrix_true", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureCheckInfiniteComplexMatrixTrue);
  failures += runCase("fnCheckInfinite/type_error", oracle_fnCheckInfinite, fnCheckInfinite, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckSpecial/real_false", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureFactorialReal);
  failures += runCase("fnCheckSpecial/real_nan_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureSignRealNaN);
  failures += runCase("fnCheckSpecial/real_inf_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureSincRealInfinity);
  failures += runCase("fnCheckSpecial/complex_false", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureFactorialComplex);
  failures += runCase("fnCheckSpecial/complex_inf_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureExpComplexSpecial);
  failures += runCase("fnCheckSpecial/complex_nan_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckNaNComplex);
  failures += runCase("fnCheckSpecial/real_matrix_false", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckNaNRealMatrixFalse);
  failures += runCase("fnCheckSpecial/real_matrix_nan_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckNaNRealMatrixTrue);
  failures += runCase("fnCheckSpecial/real_matrix_inf_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckInfiniteRealMatrixTrue);
  failures += runCase("fnCheckSpecial/complex_matrix_false", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckNaNComplexMatrixFalse);
  failures += runCase("fnCheckSpecial/complex_matrix_nan_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckNaNComplexMatrixTrue);
  failures += runCase("fnCheckSpecial/complex_matrix_inf_true", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckInfiniteComplexMatrixTrue);
  failures += runCase("fnCheckSpecial/type_error", oracle_fnCheckSpecial, fnCheckSpecial, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckPlusZero/longint_true", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckLongIntegerZero);
  failures += runCase("fnCheckPlusZero/longint_false", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckPlusZero/shortint_true", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckShortIntegerZero);
  failures += runCase("fnCheckPlusZero/real_true", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckRealPositiveZero);
  failures += runCase("fnCheckPlusZero/real_false", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckRealNegativeZero);
  failures += runCase("fnCheckPlusZero/complex_true", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckComplexPositiveZero);
  failures += runCase("fnCheckPlusZero/complex_false", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckComplexNegativeZero);
  failures += runCase("fnCheckPlusZero/type_error", oracle_fnCheckPlusZero, fnCheckPlusZero, 0, true, configureCheckRealMatrix);
  failures += runCase("fnCheckMinusZero/longint_false", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckLongIntegerZero);
  failures += runCase("fnCheckMinusZero/shortint_false", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckShortIntegerZero);
  failures += runCase("fnCheckMinusZero/real_false", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckRealPositiveZero);
  failures += runCase("fnCheckMinusZero/real_true", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckRealNegativeZero);
  failures += runCase("fnCheckMinusZero/complex_false", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckComplexPositiveZero);
  failures += runCase("fnCheckMinusZero/complex_true", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckComplexNegativeZero);
  failures += runCase("fnCheckMinusZero/type_error", oracle_fnCheckMinusZero, fnCheckMinusZero, 0, true, configureCheckRealMatrix);
  failures += runCase("fnCheckMatrixSquare/real_true", oracle_fnCheckMatrixSquare, fnCheckMatrixSquare, 0, true, configureCheckMatrixSquareRealSquare);
  failures += runCase("fnCheckMatrixSquare/real_false", oracle_fnCheckMatrixSquare, fnCheckMatrixSquare, 0, true, configureCheckMatrixSquareRealNonsquare);
  failures += runCase("fnCheckMatrixSquare/complex_true", oracle_fnCheckMatrixSquare, fnCheckMatrixSquare, 0, true, configureCheckMatrixSquareComplexSquare);
  failures += runCase("fnCheckMatrixSquare/complex_false", oracle_fnCheckMatrixSquare, fnCheckMatrixSquare, 0, true, configureCheckMatrixSquareComplexNonsquare);
  failures += runCase("fnCheckMatrixSquare/type_error", oracle_fnCheckMatrixSquare, fnCheckMatrixSquare, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckIsVect2d/true", oracle_fnCheckIsVect2d, fnCheckIsVect2d, 0, true, configureCheckVect2dTrue);
  failures += runCase("fnCheckIsVect2d/false", oracle_fnCheckIsVect2d, fnCheckIsVect2d, 0, true, configureCheckVect2dFalse);
  failures += runCase("fnCheckIsVect2d/type_error", oracle_fnCheckIsVect2d, fnCheckIsVect2d, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnCheckIsVect3d/true", oracle_fnCheckIsVect3d, fnCheckIsVect3d, 0, true, configureCheckVect3dTrue);
  failures += runCase("fnCheckIsVect3d/false", oracle_fnCheckIsVect3d, fnCheckIsVect3d, 0, true, configureCheckVect2dTrue);
  failures += runCase("fnCheckIsVect3d/type_error", oracle_fnCheckIsVect3d, fnCheckIsVect3d, 0, true, configureCheckTypeLongInteger);
  failures += runCase("fnRealPart/real", oracle_fnRealPart, fnRealPart, 0, true, configureRealPartReal);
  failures += runCase("fnRealPart/complex", oracle_fnRealPart, fnRealPart, 0, true, configureRealPartComplex);
  failures += runCase("fnRealPart/real_matrix", oracle_fnRealPart, fnRealPart, 0, true, configureRealPartRealMatrix);
  failures += runCase("fnRealPart/complex_matrix", oracle_fnRealPart, fnRealPart, 0, true, configureRealPartComplexMatrix);
  failures += runCase("fnImaginaryPart/real", oracle_fnImaginaryPart, fnImaginaryPart, 0, true, configureImaginaryPartReal);
  failures += runCase("fnImaginaryPart/complex", oracle_fnImaginaryPart, fnImaginaryPart, 0, true, configureImaginaryPartComplex);
  failures += runCase("fnImaginaryPart/real_matrix", oracle_fnImaginaryPart, fnImaginaryPart, 0, true, configureImaginaryPartRealMatrix);
  failures += runCase("fnImaginaryPart/complex_matrix", oracle_fnImaginaryPart, fnImaginaryPart, 0, true, configureImaginaryPartComplexMatrix);
  failures += runCase("fnArg/real_positive", oracle_fnArg, fnArg, 0, true, configureArgRealPositive);
  failures += runCase("fnArg/real_negative", oracle_fnArg, fnArg, 0, true, configureArgRealNegative);
  failures += runCase("fnArg/complex", oracle_fnArg, fnArg, 0, true, configureArgComplex);
  failures += runCase("fnArg/real_matrix", oracle_fnArg, fnArg, 0, true, configureArgRealMatrix);
  failures += runCase("fnArg/complex_matrix", oracle_fnArg, fnArg, 0, true, configureArgComplexMatrix);
  failures += runCase("fnMagnitude/real", oracle_fnMagnitude, fnMagnitude, 0, true, configureMagnitudeReal);
  failures += runCase("fnMagnitude/real_matrix", oracle_fnMagnitude, fnMagnitude, 0, true, configureMagnitudeRealMatrix);
  failures += runCase("fnMagnitude/complex", oracle_fnMagnitude, fnMagnitude, 0, true, configureMagnitudeComplex);
  failures += runCase("fnMagnitude/complex_matrix", oracle_fnMagnitude, fnMagnitude, 0, true, configureMagnitudeComplexMatrix);
  failures += runCase("fnMagnitude/longint", oracle_fnMagnitude, fnMagnitude, 0, true, configureMagnitudeLongInteger);
  failures += runCase("fnMagnitude/shortint", oracle_fnMagnitude, fnMagnitude, 0, true, configureMagnitudeShortInteger);
  failures += runCase("fnConjugate/complex", oracle_fnConjugate, fnConjugate, 0, true, configureConjugateComplex);
  failures += runCase("fnConjugate/real_matrix", oracle_fnConjugate, fnConjugate, 0, true, configureConjugateRealMatrix);
  failures += runCase("fnConjugate/complex_matrix", oracle_fnConjugate, fnConjugate, 0, true, configureConjugateComplexMatrix);
  failures += runCase("fnSwapRealImaginary/complex", oracle_fnSwapRealImaginary, fnSwapRealImaginary, 0, true, configureSwapRealImaginaryComplex);
  failures += runCase("fnSwapRealImaginary/real_matrix", oracle_fnSwapRealImaginary, fnSwapRealImaginary, 0, true, configureSwapRealImaginaryRealMatrix);
  failures += runCase("fnSwapRealImaginary/complex_matrix", oracle_fnSwapRealImaginary, fnSwapRealImaginary, 0, true, configureSwapRealImaginaryComplexMatrix);
  failures += runCase("fnAtan2/real", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2Real);
  failures += runCase("fnAtan2/zero_domain", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2ZeroDomain);
  failures += runCase("fnAtan2/x_matrix_y_real", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2XMatrixYReal);
  failures += runCase("fnAtan2/x_matrix_y_longint", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2XMatrixYLongInteger);
  failures += runCase("fnAtan2/x_matrix_y_matrix", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2XMatrixYMatrix);
  failures += runCase("fnAtan2/x_real_y_matrix", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2XRealYMatrix);
  failures += runCase("fnAtan2/x_longint_y_matrix", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2XLongIntegerYMatrix);
  failures += runCase("fnAtan2/x_matrix_y_matrix_mismatch", oracle_fnAtan2, fnAtan2, 0, true, configureAtan2XMatrixYMatrixMismatch);
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
  failures += runCase("fnPercent/real", oracle_fnPercent, fnPercent, 0, true, configurePercentReal);
  failures += runCase("fnToPolar2/real34_pair", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar2Real34Pair);
  failures += runCase("fnToPolar2/longint_pair", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar2LongIntegerPair);
  failures += runCase("fnToPolar2/invalid_type", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar2InvalidType);
  failures += runCase("fnToPolar2/complex_no_angle", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar2ComplexNoAngle);
  failures += runCaseIgnoringRegisterMetadataGetters("fnToPolar2/vector_2d", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar2Vector2D);
  failures += runCaseIgnoringRegisterMetadataGetters("fnToPolar2/vector_3d_rect", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar23DRect);
  failures += runCaseIgnoringRegisterMetadataGetters("fnToPolar2/vector_3d_spherical", oracle_fnToPolar2, fnToPolar2, 0, true, configureToPolar23DSpherical);
  failures += runCase("fnToRect2/real34_pair", oracle_fnToRect2, fnToRect2, 0, true, configureToRect2Real34Pair);
  failures += runCase("fnToRect2/longint_pair", oracle_fnToRect2, fnToRect2, 0, true, configureToRect2LongIntegerPair);
  failures += runCase("fnToRect2/invalid_type", oracle_fnToRect2, fnToRect2, 0, true, configureToRect2InvalidType);
  failures += runCase("fnToRect2/complex_polar", oracle_fnToRect2, fnToRect2, 0, true, configureToRect2ComplexPolar);
  failures += runCaseIgnoringRegisterMetadataGetters("fnToRect2/vector_2d", oracle_fnToRect2, fnToRect2, 0, true, configureToRect2Vector2D);
  failures += runCaseIgnoringRegisterMetadataGetters("fnToRect2/vector_3d_spherical", oracle_fnToRect2, fnToRect2, 0, true, configureToRect23DSpherical);
  failures += runCaseIgnoringRegisterMetadataGetters("fnToRect2/vector_3d_cylindrical", oracle_fnToRect2, fnToRect2, 0, true, configureToRect23DCylindrical);
  failures += runCase("fnToRect/real34_pair", oracle_fnToRect, fnToRect, 1, true, configureFnToRectReal34Pair);
  failures += runCase("fnToRect/longint_pair", oracle_fnToRect, fnToRect, 1, true, configureFnToRectLongIntegerPair);
  failures += runCase("fnToRect/invalid_type", oracle_fnToRect, fnToRect, 1, true, configureFnToRectInvalidType);

  if(failures != 0) {
    fprintf(stderr, "%d math-command-wrapper parity checks failed\n", failures);
    return 1;
  }

  return 0;
}