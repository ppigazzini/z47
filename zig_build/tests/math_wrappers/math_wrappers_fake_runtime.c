// SPDX-License-Identifier: GPL-3.0-only

#include <gmp.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

static math_wrappers_snapshot_t snapshot;
static bool_t save_last_x_result = true;
static uint32_t current_register_data_type = dtReal34;
static uint32_t current_register_tag = amNone;

static uint8_t register_slot[16];
static uint32_t register_scalar_magnitude;
static bool_t register_scalar_available = true;

static struct {
  bool_t available;
  real_t value;
} real_input;

static struct {
  bool_t available;
  real_t value;
  angularMode_t angle_mode;
} real_angle_input;

static struct {
  bool_t available;
  real_t real;
  real_t imag;
} complex_input;

static struct {
  bool_t available;
  int32_t value;
} longint_input;

static struct {
  bool_t enabled;
  real_t sin_value;
  real_t cos_value;
  real_t tan_value;
} trig_outputs;

static bool_t spcres_flag = false;

realContext_t ctxtReal39;
realContext_t ctxtReal51;
realContext_t ctxtReal75;
static real_t fake_const_nan_value;
static real_t fake_const_one_value;
static real_t fake_const_plus_infinity_value;
static real_t fake_const_minus_infinity_value;
const real_t *const_NaN = &fake_const_nan_value;
uint8_t lastErrorCode = 0;

static void setRegisterScalar(int32_t signed_value, uint8_t bits) {
  register_scalar_magnitude = (uint32_t)(signed_value < 0 ? -signed_value : signed_value);
  register_slot[15] = bits;
  if(signed_value < 0) {
    register_slot[15] |= 0x80;
  }
}

static int32_t fakeRegisterScalarValue(void) {
  return (register_slot[15] & 0x80) ? -(int32_t)register_scalar_magnitude : (int32_t)register_scalar_magnitude;
}

static uint64_t encodeShortInteger(int64_t signed_value) {
  const uint64_t magnitude = (uint64_t)(signed_value < 0 ? -signed_value : signed_value);
  return magnitude | (signed_value < 0 ? (UINT64_C(1) << 63) : 0);
}

static int64_t decodeShortInteger(uint64_t raw, int32_t *sign_value) {
  const bool_t negative = (raw >> 63) != 0;
  if(sign_value != NULL) {
    *sign_value = negative ? 1 : 0;
  }
  return negative ? -(int64_t)(raw & ~(UINT64_C(1) << 63)) : (int64_t)(raw & ~(UINT64_C(1) << 63));
}

static void setFakeRealWithExponent(real_t *value, int32_t signed_value, uint8_t bits, int32_t exponent) {
  memset(value, 0, sizeof(*value));
  value->digits = 1;
  value->exponent = exponent;
  value->bits = bits;
  if(signed_value < 0) {
    value->bits |= 0x80;
    value->lsu[0] = (uint16_t)(-signed_value);
  }
  else {
    value->lsu[0] = (uint16_t)signed_value;
  }
}

static void setFakeReal(real_t *value, int32_t signed_value, uint8_t bits) {
  setFakeRealWithExponent(value, signed_value, bits, 0);
}

static int32_t fakeRealValue(const real_t *value) {
  int64_t magnitude = value->lsu[0];

  if(value->exponent > 0) {
    for(int32_t i = 0; i < value->exponent; ++i) {
      magnitude *= 10;
    }
  }
  else if(value->exponent < 0) {
    for(int32_t i = 0; i < -value->exponent; ++i) {
      magnitude /= 10;
    }
  }

  return (value->bits & 0x80) ? -magnitude : magnitude;
}

void mathWrappersReset(void) {
  memset(&snapshot, 0, sizeof(snapshot));
  save_last_x_result = true;
  snapshot.save_last_x_result = true;
  snapshot.integer_part_real_mode = -1;
  snapshot.integer_part_cplx_mode = -1;
  snapshot.sinh_cosh_real_trig_type = -1;
  snapshot.sinh_cosh_cplx_trig_type = -1;
  current_register_data_type = dtReal34;
  current_register_tag = amNone;
  memset(register_slot, 0, sizeof(register_slot));
  register_scalar_available = true;
  setRegisterScalar(7, 0);
  *(uint64_t *)register_slot = encodeShortInteger(-3);

  real_input.available = true;
  setFakeReal(&real_input.value, 7, 0);

  real_angle_input.available = true;
  setFakeReal(&real_angle_input.value, 5, 0);
  real_angle_input.angle_mode = amRadian;

  complex_input.available = true;
  setFakeReal(&complex_input.real, 2, 0);
  setFakeReal(&complex_input.imag, 3, 0);

  longint_input.available = true;
  longint_input.value = -4;

  trig_outputs.enabled = false;
  spcres_flag = false;
  lastErrorCode = 0;

  ctxtReal39.digits = 39;
  ctxtReal51.digits = 51;
  ctxtReal75.digits = 75;
  setFakeReal(&fake_const_nan_value, 0, 0x20);
  setFakeReal(&fake_const_one_value, 1, 0);
  setFakeReal(&fake_const_plus_infinity_value, 0, 0x40);
  setFakeReal(&fake_const_minus_infinity_value, 0, 0xc0);
}

void mathWrappersSetSaveLastXResult(bool_t result) {
  save_last_x_result = result;
  snapshot.save_last_x_result = result;
}

void mathWrappersSetRegisterSurface(uint32_t data_type, uint32_t tag) {
  current_register_data_type = data_type;
  current_register_tag = tag;
}

void mathWrappersSetRealInput(bool_t available, int32_t value, uint8_t bits) {
  real_input.available = available;
  setFakeReal(&real_input.value, value, bits);
  register_scalar_available = available;
  setRegisterScalar(value, bits);
}

void mathWrappersSetTimeInput(bool_t available, int32_t value, uint8_t bits) {
  register_scalar_available = available;
  setRegisterScalar(value, bits);
}

void mathWrappersSetRealAngleInput(bool_t available, int32_t value, uint8_t bits, angularMode_t angle_mode) {
  real_angle_input.available = available;
  setFakeReal(&real_angle_input.value, value, bits);
  real_angle_input.angle_mode = angle_mode;
}

void mathWrappersSetComplexInput(bool_t available, int32_t real_value, uint8_t real_bits, int32_t imag_value, uint8_t imag_bits) {
  complex_input.available = available;
  setFakeReal(&complex_input.real, real_value, real_bits);
  setFakeReal(&complex_input.imag, imag_value, imag_bits);
}

void mathWrappersSetShortIntegerInput(int64_t value) {
  *(uint64_t *)register_slot = encodeShortInteger(value);
}

void mathWrappersSetLongIntegerInput(bool_t available, int32_t value) {
  longint_input.available = available;
  longint_input.value = value;
}

void mathWrappersSetFlagSpcRes(bool_t enabled) {
  spcres_flag = enabled;
}

void mathWrappersSetTrigOutputs(bool_t enabled, int32_t sin_value, int32_t cos_value, int32_t tan_value) {
  trig_outputs.enabled = enabled;
  setFakeReal(&trig_outputs.sin_value, sin_value, 0);
  setFakeReal(&trig_outputs.cos_value, cos_value, 0);
  setFakeReal(&trig_outputs.tan_value, tan_value, 0);
}

void mathWrappersCapture(math_wrappers_snapshot_t *out) {
  snapshot.final_register_data_type = current_register_data_type;
  snapshot.final_register_tag = current_register_tag;
  snapshot.final_register_real34_value = fakeRegisterScalarValue();
  snapshot.final_register_real34_bits = register_slot[15];
  snapshot.final_register_shortint_raw = *(uint64_t *)register_slot;
  snapshot.final_register_longint_value = longint_input.value;
  *out = snapshot;
}

bool_t saveLastX(void) {
  snapshot.save_last_x_calls++;
  return save_last_x_result;
}

uint32_t getRegisterDataType(calcRegister_t reg) {
  snapshot.get_register_data_type_calls++;
  (void)reg;
  return current_register_data_type;
}

uint32_t getRegisterTag(calcRegister_t reg) {
  snapshot.get_register_tag_calls++;
  (void)reg;
  return current_register_tag;
}

void *getRegisterDataPointer(calcRegister_t reg) {
  snapshot.get_register_data_pointer_calls++;
  (void)reg;
  return register_slot;
}

void registerMin(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest) {
  snapshot.register_min_calls++;
  snapshot.register_min_reg1 = regist1;
  snapshot.register_min_reg2 = regist2;
  snapshot.register_min_dest = dest;
}

void registerMax(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest) {
  snapshot.register_max_calls++;
  snapshot.register_max_reg1 = regist1;
  snapshot.register_max_reg2 = regist2;
  snapshot.register_max_dest = dest;
}

void adjustResult(calcRegister_t res,
                  bool_t dropY,
                  bool_t setCpxRes,
                  calcRegister_t op1,
                  calcRegister_t op2,
                  calcRegister_t op3) {
  snapshot.adjust_result_calls++;
  snapshot.adjust_result_res = res;
  snapshot.adjust_result_drop_y = dropY;
  snapshot.adjust_result_set_cpx_res = setCpxRes;
  snapshot.adjust_result_op1 = op1;
  snapshot.adjust_result_op2 = op2;
  snapshot.adjust_result_op3 = op3;
}

void processRealComplexMonadicFunction(void (*realf)(void), void (*complexf)(void)) {
  snapshot.process_real_complex_monadic_calls++;
  if(realf != NULL) {
    realf();
  }
  if(complexf != NULL) {
    complexf();
  }
}

void processIntRealComplexMonadicFunction(void (*realf)(void),
                                         void (*complexf)(void),
                                         void (*shortintf)(void),
                                         void (*longintf)(void)) {
  snapshot.process_int_real_complex_monadic_calls++;
  switch(current_register_data_type) {
    case dtComplex34:
      if(complexf != NULL) {
        complexf();
      }
      break;
    case dtShortInteger:
      if(shortintf != NULL) {
        shortintf();
      }
      break;
    case dtLongInteger:
      if(longintf != NULL) {
        longintf();
      }
      break;
    default:
      if(realf != NULL) {
        realf();
      }
      break;
  }
}

void integerPartNoOp(void) {
  snapshot.integer_part_noop_calls++;
}

void integerPartReal(enum rounding mode) {
  snapshot.integer_part_real_calls++;
  snapshot.integer_part_real_mode = mode;
}

void integerPartCplx(enum rounding mode) {
  snapshot.integer_part_cplx_calls++;
  snapshot.integer_part_cplx_mode = mode;
}

bool_t getRegisterAsReal(calcRegister_t reg, real_t *value) {
  snapshot.get_register_as_real_calls++;
  (void)reg;
  if(current_register_data_type == dtTime) {
    if(!register_scalar_available) {
      return false;
    }
    setFakeReal(value, fakeRegisterScalarValue(), register_slot[15] & 0x70);
    return true;
  }
  if(!real_input.available) {
    return false;
  }
  *value = real_input.value;
  return true;
}

bool_t getRegisterAsRealAngle(calcRegister_t reg, real_t *value, angularMode_t *angleMode, bool_t reduceLongintegerAngle) {
  snapshot.get_register_as_real_angle_calls++;
  snapshot.get_register_as_real_angle_reg = reg;
  snapshot.get_register_as_real_angle_reduce_longinteger = reduceLongintegerAngle;
  snapshot.get_register_as_real_angle_value = fakeRealValue(&real_angle_input.value);
  snapshot.get_register_as_real_angle_bits = real_angle_input.value.bits;
  snapshot.get_register_as_real_angle_mode = real_angle_input.angle_mode;
  if(!real_angle_input.available) {
    return false;
  }
  *value = real_angle_input.value;
  *angleMode = real_angle_input.angle_mode;
  return true;
}

bool_t getRegisterAsComplex(calcRegister_t reg, real_t *real, real_t *imag) {
  snapshot.get_register_as_complex_calls++;
  snapshot.get_register_as_complex_real_value = fakeRealValue(&complex_input.real);
  snapshot.get_register_as_complex_real_bits = complex_input.real.bits;
  snapshot.get_register_as_complex_imag_value = fakeRealValue(&complex_input.imag);
  snapshot.get_register_as_complex_imag_bits = complex_input.imag.bits;
  (void)reg;
  if(!complex_input.available) {
    return false;
  }
  *real = complex_input.real;
  *imag = complex_input.imag;
  return true;
}

bool_t getRegisterAsLongInt(calcRegister_t reg, longInteger_t val, bool_t *fractional) {
  snapshot.get_register_as_longint_calls++;
  snapshot.get_register_as_longint_result = longint_input.available;
  snapshot.get_register_as_longint_value = longint_input.value;
  (void)reg;
  mpz_init(val);
  if(fractional != NULL) {
    *fractional = false;
  }
  if(!longint_input.available) {
    return false;
  }
  mpz_set_si(val, longint_input.value);
  return true;
}

void convertLongIntegerRegisterToLongInteger(calcRegister_t reg, longInteger_t lgInt) {
  (void)reg;
  mpz_init(lgInt);
  mpz_set_si(lgInt, longint_input.value);
}

void convertLongIntegerToLongIntegerRegister(const longInteger_t lgInt, calcRegister_t reg) {
  snapshot.convert_long_integer_to_register_calls++;
  snapshot.convert_long_integer_to_register_value = (int32_t)mpz_get_si(lgInt);
  snapshot.convert_long_integer_to_register_dest = reg;
  longint_input.value = (int32_t)mpz_get_si(lgInt);
  current_register_data_type = dtLongInteger;
  current_register_tag = longint_input.value < 0 ? LI_NEGATIVE : longint_input.value > 0 ? LI_POSITIVE : LI_ZERO;
}

void convertRealToResultRegister(const real_t *real, calcRegister_t reg, angularMode_t angleMode) {
  snapshot.convert_real_to_result_calls++;
  snapshot.convert_real_to_result_value = fakeRealValue(real);
  snapshot.convert_real_to_result_bits = real->bits;
  snapshot.convert_real_to_result_angle = angleMode;
  (void)reg;
  current_register_data_type = dtReal34;
  current_register_tag = (uint32_t)angleMode;
  setRegisterScalar(fakeRealValue(real), real->bits & 0x70);
}

void convertComplexToResultRegister(const real_t *real, const real_t *imag, calcRegister_t reg) {
  snapshot.convert_complex_to_result_calls++;
  snapshot.convert_complex_to_result_real_value = fakeRealValue(real);
  snapshot.convert_complex_to_result_real_bits = real->bits;
  snapshot.convert_complex_to_result_imag_value = fakeRealValue(imag);
  snapshot.convert_complex_to_result_imag_bits = imag->bits;
  (void)reg;
  current_register_data_type = dtComplex34;
}

void C47_WP34S_Cvt2RadSinCosTan(const real_t *angle,
                                angularMode_t mode,
                                real_t *sin,
                                real_t *cos,
                                real_t *tan,
                                realContext_t *realContext) {
  const int32_t input_value = fakeRealValue(angle);
  snapshot.cvt2rad_calls++;
  snapshot.cvt2rad_input_value = input_value;
  snapshot.cvt2rad_input_bits = angle->bits;
  snapshot.cvt2rad_mode = mode;
  snapshot.cvt2rad_requested_mask = (sin != NULL ? 1 : 0) | (cos != NULL ? 2 : 0) | (tan != NULL ? 4 : 0);
  (void)realContext;

  if(trig_outputs.enabled) {
    if(sin != NULL) {
      *sin = trig_outputs.sin_value;
    }
    if(cos != NULL) {
      *cos = trig_outputs.cos_value;
    }
    if(tan != NULL) {
      *tan = trig_outputs.tan_value;
    }
    return;
  }

  if(sin != NULL) {
    setFakeReal(sin, input_value + 10 + mode, 0);
  }
  if(cos != NULL) {
    setFakeReal(cos, input_value + 20 + mode, 0);
  }
  if(tan != NULL) {
    setFakeReal(tan, input_value + 30 + mode, 0);
  }
}

void WP34S_SinhCosh(const real_t *x, real_t *sinOut, real_t *cosOut, realContext_t *realContext) {
  const int32_t input_value = fakeRealValue(x);
  snapshot.wp34s_sinh_cosh_calls++;
  snapshot.wp34s_sinh_cosh_input_value = input_value;
  snapshot.wp34s_sinh_cosh_input_bits = x->bits;
  snapshot.wp34s_sinh_cosh_requested_mask = (sinOut != NULL ? 1 : 0) | (cosOut != NULL ? 2 : 0);
  (void)realContext;

  if(sinOut != NULL) {
    setFakeReal(sinOut, input_value + 40, 0);
  }
  if(cosOut != NULL) {
    setFakeReal(cosOut, input_value + 50, 0);
  }
}

void WP34S_Tanh(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 60, 0);
}

void realPolarToRectangular(const real_t *magnitude,
                            const real_t *angle,
                            real_t *real,
                            real_t *imag,
                            realContext_t *realContext) {
  snapshot.real_polar_to_rectangular_calls++;
  snapshot.real_polar_to_rectangular_magnitude_value = fakeRealValue(magnitude);
  snapshot.real_polar_to_rectangular_angle_value = fakeRealValue(angle);
  (void)realContext;
  setFakeReal(real, fakeRealValue(magnitude) + fakeRealValue(angle), 0);
  setFakeReal(imag, fakeRealValue(magnitude) - fakeRealValue(angle), 0);
}

decNumber *decNumberMultiply(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *realContext) {
  snapshot.dec_number_multiply_calls++;
  snapshot.dec_number_multiply_lhs_value = fakeRealValue(lhs);
  snapshot.dec_number_multiply_lhs_bits = lhs->bits;
  snapshot.dec_number_multiply_rhs_value = fakeRealValue(rhs);
  snapshot.dec_number_multiply_rhs_bits = rhs->bits;
  (void)realContext;
  setFakeReal(result, fakeRealValue(lhs) * fakeRealValue(rhs), 0);
  return result;
}

decNumber *decNumberDivide(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *realContext) {
  const int32_t rhs_value = fakeRealValue(rhs);

  snapshot.dec_number_divide_calls++;
  snapshot.dec_number_divide_lhs_value = fakeRealValue(lhs);
  snapshot.dec_number_divide_rhs_value = rhs_value;
  (void)realContext;
  setFakeReal(result, rhs_value == 0 ? 0 : (fakeRealValue(lhs) * 100) / rhs_value, 0);
  return result;
}

decNumber *decNumberExp(decNumber *result, const decNumber *rhs, decContext *realContext) {
  snapshot.dec_number_exp_calls++;
  snapshot.dec_number_exp_input_value = fakeRealValue(rhs);
  snapshot.dec_number_exp_input_bits = rhs->bits;
  (void)realContext;
  setFakeReal(result, fakeRealValue(rhs) + 70, 0);
  return result;
}

bool_t realCompareAbsEqual(const real_t *number1, const real_t *number2) {
  const int32_t lhs_value = fakeRealValue(number1);
  const int32_t rhs_value = fakeRealValue(number2);

  snapshot.real_compare_abs_equal_calls++;
  snapshot.real_compare_abs_equal_lhs_value = lhs_value;
  snapshot.real_compare_abs_equal_rhs_value = rhs_value;
  return (lhs_value < 0 ? -lhs_value : lhs_value) == (rhs_value < 0 ? -rhs_value : rhs_value);
}

bool_t realCompareAbsGreaterThan(const real_t *number1, const real_t *number2) {
  const int32_t lhs_value = fakeRealValue(number1);
  const int32_t rhs_value = fakeRealValue(number2);

  snapshot.real_compare_abs_greater_than_calls++;
  snapshot.real_compare_abs_greater_than_lhs_value = lhs_value;
  snapshot.real_compare_abs_greater_than_rhs_value = rhs_value;
  return (lhs_value < 0 ? -lhs_value : lhs_value) > (rhs_value < 0 ? -rhs_value : rhs_value);
}

void divRealComplex(const real_t *numer,
                    const real_t *denomReal,
                    const real_t *denomImag,
                    real_t *quotientReal,
                    real_t *quotientImag,
                    realContext_t *realContext) {
  snapshot.div_real_complex_calls++;
  snapshot.div_real_complex_numer_value = fakeRealValue(numer);
  snapshot.div_real_complex_denom_real_value = fakeRealValue(denomReal);
  snapshot.div_real_complex_denom_imag_value = fakeRealValue(denomImag);
  (void)realContext;
  setFakeReal(quotientReal, fakeRealValue(numer) + fakeRealValue(denomReal), 0);
  setFakeReal(quotientImag, fakeRealValue(numer) - fakeRealValue(denomImag), 0);
}

void fnInvertMatrix(uint16_t unusedButMandatoryParameter) {
  snapshot.invert_matrix_calls++;
  (void)unusedButMandatoryParameter;
}

void mulComplexi(const real_t *inReal, const real_t *inImag, real_t *productReal, real_t *productImag) {
  snapshot.mul_complex_i_calls++;
  snapshot.mul_complex_i_input_real_value = fakeRealValue(inReal);
  snapshot.mul_complex_i_input_imag_value = fakeRealValue(inImag);
  setFakeReal(productReal, -fakeRealValue(inImag), 0);
  setFakeReal(productImag, fakeRealValue(inReal), 0);
}

void mulComplexComplex(const real_t *factor1Real,
                       const real_t *factor1Imag,
                       const real_t *factor2Real,
                       const real_t *factor2Imag,
                       real_t *productReal,
                       real_t *productImag,
                       realContext_t *realContext) {
  snapshot.mul_complex_complex_calls++;
  snapshot.mul_complex_complex_factor1_real_value = fakeRealValue(factor1Real);
  snapshot.mul_complex_complex_factor1_imag_value = fakeRealValue(factor1Imag);
  snapshot.mul_complex_complex_factor2_real_value = fakeRealValue(factor2Real);
  snapshot.mul_complex_complex_factor2_imag_value = fakeRealValue(factor2Imag);
  (void)realContext;
  setFakeReal(productReal, fakeRealValue(factor1Real) * fakeRealValue(factor2Real) - fakeRealValue(factor1Imag) * fakeRealValue(factor2Imag), 0);
  setFakeReal(productImag, fakeRealValue(factor1Real) * fakeRealValue(factor2Imag) + fakeRealValue(factor1Imag) * fakeRealValue(factor2Real), 0);
}

void unitVectorCplx(void) {
  snapshot.unit_vector_cplx_calls++;
}

uint64_t WP34S_extract_value(const uint64_t val, int32_t *const sign) {
  snapshot.wp34s_extract_value_calls++;
  snapshot.wp34s_extract_value_input = val;
  snapshot.wp34s_extract_value_sign = ((val >> 63) != 0) ? 1 : 0;
  if(sign != NULL) {
    *sign = snapshot.wp34s_extract_value_sign;
  }
  return val & ~(UINT64_C(1) << 63);
}

uint64_t WP34S_intChs(uint64_t x) {
  const uint64_t magnitude = x & ~(UINT64_C(1) << 63);

  snapshot.wp34s_int_chs_calls++;
  snapshot.wp34s_int_chs_input = x;
  if(magnitude == 0) {
    return 0;
  }
  return x ^ (UINT64_C(1) << 63);
}

uint64_t WP34S_int10pow(uint64_t x) {
  uint64_t exponent = WP34S_extract_value(x, NULL);
  uint64_t result = 1;

  snapshot.wp34s_int10pow_calls++;
  snapshot.wp34s_int10pow_input = x;
  while(exponent-- != 0) {
    result *= 10;
  }
  return result;
}

uint64_t WP34S_intMultiply(uint64_t y, uint64_t x) {
  int32_t sign_y;
  int32_t sign_x;
  const uint64_t magnitude_y = WP34S_extract_value(y, &sign_y);
  const uint64_t magnitude_x = WP34S_extract_value(x, &sign_x);
  const uint64_t product = magnitude_y * magnitude_x;

  snapshot.wp34s_int_multiply_calls++;
  snapshot.wp34s_int_multiply_lhs = y;
  snapshot.wp34s_int_multiply_rhs = x;
  return product | ((uint64_t)(sign_y ^ sign_x) << 63);
}

void convertAngleFromTo(real_t *angle, angularMode_t fromAngularMode, angularMode_t toAngularMode, realContext_t *realContext) {
  snapshot.convert_angle_from_to_calls++;
  snapshot.convert_angle_from_to_input_value = fakeRealValue(angle);
  snapshot.convert_angle_from_to_from_mode = fromAngularMode;
  snapshot.convert_angle_from_to_to_mode = toAngularMode;
  (void)realContext;
  setFakeReal(angle, fakeRealValue(angle) + fromAngularMode - toAngularMode, angle->bits & 0x70);
}

void fnSetFlag(int32_t flag) {
  snapshot.fn_set_flag_calls++;
  snapshot.fn_set_flag_last_flag = flag;
}

void fnRefreshState(void) {
  snapshot.fn_refresh_state_calls++;
}

void divComplexComplex(const real_t *numerReal,
                       const real_t *numerImag,
                       const real_t *denomReal,
                       const real_t *denomImag,
                       real_t *quotientReal,
                       real_t *quotientImag,
                       realContext_t *realContext) {
  snapshot.div_complex_complex_calls++;
  snapshot.div_complex_complex_numer_real_value = fakeRealValue(numerReal);
  snapshot.div_complex_complex_numer_imag_value = fakeRealValue(numerImag);
  snapshot.div_complex_complex_denom_real_value = fakeRealValue(denomReal);
  snapshot.div_complex_complex_denom_imag_value = fakeRealValue(denomImag);
  (void)realContext;
  setFakeReal(quotientReal, fakeRealValue(numerReal) + fakeRealValue(denomReal), 0);
  setFakeReal(quotientImag, fakeRealValue(numerImag) - fakeRealValue(denomImag), 0);
}

void realSetNaN(real_t *value) {
  setFakeReal(value, 0, 0x20);
}

void realSetZero(real_t *value) {
  setFakeReal(value, 0, 0);
}

void realSetOne(real_t *value) {
  setFakeReal(value, 1, 0);
}

bool_t getSystemFlag(int32_t flag) {
  snapshot.get_system_flag_calls++;
  snapshot.get_system_flag_last_flag = flag;
  return flag == FLAG_SPCRES ? spcres_flag : false;
}

void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line) {
  snapshot.display_calc_error_calls++;
  snapshot.display_calc_error_last_code = error_code;
  snapshot.display_calc_error_last_message_reg_line = err_message_register_line;
  snapshot.display_calc_error_last_register_line = err_register_line;
}

uint32_t decQuadIsNaN(const decQuad *dq) {
  (void)dq;
  return (register_slot[15] & 0x30) != 0;
}

uint32_t decQuadIsZero(const decQuad *dq) {
  (void)dq;
  return register_scalar_magnitude == 0 && (register_slot[15] & 0x70) == 0;
}

uint32_t decQuadIsNegative(const decQuad *dq) {
  (void)dq;
  return (register_slot[15] & 0x80) != 0;
}

void moreInfoOnError(const char *msg1, const char *msg2, const char *msg3, const char *msg4) {
  snapshot.more_info_calls++;
  (void)msg1;
  (void)msg2;
  (void)msg3;
  (void)msg4;
}
