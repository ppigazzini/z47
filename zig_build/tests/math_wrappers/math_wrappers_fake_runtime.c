// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "math_wrappers_test_runtime.h"

static math_wrappers_snapshot_t snapshot;
static bool_t save_last_x_result = true;

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
const real_t *const_NaN = &fake_const_nan_value;

static void setFakeReal(real_t *value, int32_t signed_value, uint8_t bits) {
  memset(value, 0, sizeof(*value));
  value->digits = 1;
  value->exponent = 0;
  value->bits = bits;
  if(signed_value < 0) {
    value->bits |= 0x80;
    value->lsu[0] = (uint16_t)(-signed_value);
  }
  else {
    value->lsu[0] = (uint16_t)signed_value;
  }
}

static int32_t fakeRealValue(const real_t *value) {
  const int32_t magnitude = value->lsu[0];
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

  real_input.available = true;
  setFakeReal(&real_input.value, 7, 0);

  real_angle_input.available = true;
  setFakeReal(&real_angle_input.value, 5, 0);
  real_angle_input.angle_mode = amRadian;

  complex_input.available = true;
  setFakeReal(&complex_input.real, 2, 0);
  setFakeReal(&complex_input.imag, 3, 0);

  trig_outputs.enabled = false;
  spcres_flag = false;

  ctxtReal39.digits = 39;
  ctxtReal51.digits = 51;
  ctxtReal75.digits = 75;
  setFakeReal(&fake_const_nan_value, 0, 0x20);
}

void mathWrappersSetSaveLastXResult(bool_t result) {
  save_last_x_result = result;
  snapshot.save_last_x_result = result;
}

void mathWrappersSetRealInput(bool_t available, int32_t value, uint8_t bits) {
  real_input.available = available;
  setFakeReal(&real_input.value, value, bits);
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
  *out = snapshot;
}

bool_t saveLastX(void) {
  snapshot.save_last_x_calls++;
  return save_last_x_result;
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
  if(realf != NULL) {
    realf();
  }
  if(complexf != NULL) {
    complexf();
  }
  if(shortintf != NULL) {
    shortintf();
  }
  if(longintf != NULL) {
    longintf();
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

void convertRealToResultRegister(const real_t *real, calcRegister_t reg, angularMode_t angleMode) {
  snapshot.convert_real_to_result_calls++;
  snapshot.convert_real_to_result_value = fakeRealValue(real);
  snapshot.convert_real_to_result_bits = real->bits;
  snapshot.convert_real_to_result_angle = angleMode;
  (void)reg;
}

void convertComplexToResultRegister(const real_t *real, const real_t *imag, calcRegister_t reg) {
  snapshot.convert_complex_to_result_calls++;
  snapshot.convert_complex_to_result_real_value = fakeRealValue(real);
  snapshot.convert_complex_to_result_real_bits = real->bits;
  snapshot.convert_complex_to_result_imag_value = fakeRealValue(imag);
  snapshot.convert_complex_to_result_imag_bits = imag->bits;
  (void)reg;
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

void moreInfoOnError(const char *msg1, const char *msg2, const char *msg3, const char *msg4) {
  snapshot.more_info_calls++;
  (void)msg1;
  (void)msg2;
  (void)msg3;
  (void)msg4;
}
