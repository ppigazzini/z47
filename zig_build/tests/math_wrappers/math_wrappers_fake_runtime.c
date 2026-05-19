// SPDX-License-Identifier: GPL-3.0-only

#include <gmp.h>
#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

typedef unsigned __int128 uint128_t;
typedef __int128 int128_t;

static math_wrappers_snapshot_t snapshot;
static bool_t save_last_x_result = true;
static uint32_t current_register_data_type = dtReal34;
static uint32_t current_register_tag = amNone;

static uint8_t register_slot[32];
static uint32_t register_scalar_magnitude;
static bool_t register_scalar_available = true;
static real34Matrix_t fake_real_matrix;
static complex34Matrix_t fake_complex_matrix;

static struct {
  bool_t available;
  real_t value;
} real_input;

static struct {
  bool_t available;
  real_t value;
} real_y_input;

static struct {
  bool_t available;
  real_t value;
} real_z_input;

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
  bool_t available;
  int32_t value;
} longint_y_input;

static struct {
  bool_t enabled;
  real_t sin_value;
  real_t cos_value;
  real_t tan_value;
} trig_outputs;

static bool_t spcres_flag = false;
static bool_t cpxres_flag = false;
static bool_t overflow_flag = false;
static uint32_t fake_uptime_ms = 0;
static uint32_t fake_free_ram_memory = 0;
static uint32_t fake_free_flash = 0;

realContext_t ctxtReal34;
realContext_t ctxtReal39;
realContext_t ctxtReal51;
realContext_t ctxtReal75;
uint8_t shortIntegerMode = SIM_UNSIGN;
uint64_t shortIntegerMask = UINT64_MAX;
uint64_t shortIntegerSignBit = UINT64_C(1) << 63;
angularMode_t currentAngularMode = amNone;
bool_t thereIsSomethingToUndo = false;
pcg32_random_t pcg32_global = PCG32_INITIALIZER;
int32_t significantDigits = 34;
int32_t temporaryInformation = 0;
static real_t fake_const_nan_value;
static real_t fake_const_one_value;
static real_t fake_const_100_value;
static real_t fake_const_180_value;
static real_t fake_const_plus_infinity_value;
static real_t fake_const_minus_infinity_value;
static real_t fake_const_1e_6_value;
static real34_t fake_const34_zero_value;
const real_t *const_NaN = &fake_const_nan_value;
uint8_t lastErrorCode = 0;
char errorMessage[ERROR_MESSAGE_LENGTH];
char tmpString[ERROR_MESSAGE_LENGTH];
const char *commonBugScreenMessages[] = {
  "%s %u %s",
};

static uint128_t pow10u(uint32_t exponent) {
  uint128_t result = 1;

  while(exponent-- != 0) {
    result *= 10;
  }
  return result;
}

static uint128_t loadFakeCoeff(const real_t *value) {
  uint128_t coeff = 0;

  memcpy(&coeff, value->lsu, sizeof(coeff));
  return coeff;
}

static void storeFakeCoeff(real_t *value, uint128_t coeff) {
  memset(value->lsu, 0, sizeof(value->lsu));
  memcpy(value->lsu, &coeff, sizeof(coeff));
}

static void setFakeRealWithCoeff(real_t *value, int128_t coeff, uint8_t bits, int32_t exponent) {
  uint128_t magnitude;

  memset(value, 0, sizeof(*value));
  value->digits = 1;
  value->exponent = exponent;
  value->bits = bits & 0x70;

  if(coeff < 0) {
    magnitude = (uint128_t)(-coeff);
    value->bits |= 0x80;
  }
  else {
    magnitude = (uint128_t)coeff;
  }

  storeFakeCoeff(value, magnitude);
}

static int128_t signedFakeCoeff(const real_t *value) {
  const int128_t magnitude = (int128_t)loadFakeCoeff(value);

  if((value->bits & 0x80) != 0 && magnitude != 0) {
    return -magnitude;
  }
  return magnitude;
}

static void setRegisterReal34(uint8_t *slot, int32_t signed_value, uint8_t bits) {
  uint32_t magnitude = (uint32_t)(signed_value < 0 ? -signed_value : signed_value);

  memset(slot, 0, sizeof(real34_t));
  memcpy(slot, &magnitude, sizeof(magnitude));
  slot[15] = bits;
  if(signed_value < 0) {
    slot[15] |= 0x80;
  }
}

static int32_t fakeReal34Value(const real34_t *value) {
  uint32_t magnitude = 0;

  memcpy(&magnitude, value->bytes, sizeof(magnitude));
  return (value->bytes[15] & 0x80) ? -(int32_t)magnitude : (int32_t)magnitude;
}

static void setRegisterScalar(int32_t signed_value, uint8_t bits) {
  register_scalar_magnitude = (uint32_t)(signed_value < 0 ? -signed_value : signed_value);
  register_slot[15] = bits;
  if(signed_value < 0) {
    register_slot[15] |= 0x80;
  }
  setRegisterReal34(register_slot, signed_value, bits);
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
  setFakeRealWithCoeff(value, signed_value, bits, exponent);
}

static void setFakeReal(real_t *value, int32_t signed_value, uint8_t bits) {
  setFakeRealWithExponent(value, signed_value, bits, 0);
}

static int32_t fakeRealValue(const real_t *value) {
  int128_t scaled_value = signedFakeCoeff(value);

  if(value->exponent > 0) {
    for(int32_t i = 0; i < value->exponent; ++i) {
      scaled_value *= 10;
    }
  }
  else if(value->exponent < 0) {
    for(int32_t i = 0; i < -value->exponent; ++i) {
      scaled_value /= 10;
    }
  }

  if(scaled_value > INT32_MAX) {
    return INT32_MAX;
  }
  if(scaled_value < INT32_MIN) {
    return INT32_MIN;
  }
  return (int32_t)scaled_value;
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

  real_y_input.available = true;
  setFakeReal(&real_y_input.value, 2, 0);

  real_z_input.available = true;
  setFakeReal(&real_z_input.value, 3, 0);

  real_angle_input.available = true;
  setFakeReal(&real_angle_input.value, 5, 0);
  real_angle_input.angle_mode = amRadian;

  complex_input.available = true;
  setFakeReal(&complex_input.real, 2, 0);
  setFakeReal(&complex_input.imag, 3, 0);

  longint_input.available = true;
  longint_input.value = -4;

  longint_y_input.available = true;
  longint_y_input.value = 9;

  trig_outputs.enabled = false;
  spcres_flag = false;
  cpxres_flag = false;
  overflow_flag = false;
  fake_uptime_ms = 0x12345678u;
  fake_free_ram_memory = 0x11223344u;
  fake_free_flash = 0x55667788u;
  shortIntegerMode = SIM_UNSIGN;
  currentAngularMode = amNone;
  thereIsSomethingToUndo = false;
  lastErrorCode = 0;
  pcg32_global = (pcg32_random_t)PCG32_INITIALIZER;

  ctxtReal34.digits = 34;
  ctxtReal39.digits = 39;
  ctxtReal51.digits = 51;
  ctxtReal75.digits = 75;
  setFakeReal(&fake_const_nan_value, 0, 0x20);
  setFakeReal(&fake_const_one_value, 1, 0);
  setFakeReal(&fake_const_100_value, 100, 0);
  setFakeReal(&fake_const_180_value, 180, 0);
  setFakeReal(&fake_const_plus_infinity_value, 0, 0x40);
  setFakeReal(&fake_const_minus_infinity_value, 0, 0xc0);
  setFakeRealWithExponent(&fake_const_1e_6_value, 1, 0, -6);
  setRegisterReal34((uint8_t *)&fake_const34_zero_value, 0, 0);
  setRegisterReal34(register_slot, 2, 0);
  setRegisterReal34(register_slot + sizeof(real34_t), 3, 0);

  fake_real_matrix.header.matrixRows = 2;
  fake_real_matrix.header.matrixColumns = 2;
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[0], 1, 0);
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[1], 2, 0);
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[2], 3, 0);
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[3], 4, 0);

  fake_complex_matrix.header.matrixRows = 2;
  fake_complex_matrix.header.matrixColumns = 2;
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[0].real, 1, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[0].imag, 5, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[1].real, 2, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[1].imag, 6, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[2].real, 3, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[2].imag, 7, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[3].real, 4, 0);
  setRegisterReal34((uint8_t *)&fake_complex_matrix.matrixElements[3].imag, 8, 0);
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

void mathWrappersSetRealYInput(bool_t available, int32_t value, uint8_t bits) {
  real_y_input.available = available;
  setFakeReal(&real_y_input.value, value, bits);
}

void mathWrappersSetRealZInput(bool_t available, int32_t value, uint8_t bits) {
  real_z_input.available = available;
  setFakeReal(&real_z_input.value, value, bits);
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
  setRegisterReal34(register_slot, real_value, real_bits);
  setRegisterReal34(register_slot + sizeof(real34_t), imag_value, imag_bits);
}

void mathWrappersSetShortIntegerInput(int64_t value) {
  *(uint64_t *)register_slot = encodeShortInteger(value);
}

void mathWrappersSetShortIntegerMode(uint8_t mode) {
  shortIntegerMode = mode;
}

void mathWrappersSetLongIntegerInput(bool_t available, int32_t value) {
  longint_input.available = available;
  longint_input.value = value;
}

void mathWrappersSetLongIntegerYInput(bool_t available, int32_t value) {
  longint_y_input.available = available;
  longint_y_input.value = value;
}

void mathWrappersSetFlagCpxRes(bool_t enabled) {
  cpxres_flag = enabled;
}

void mathWrappersSetFlagOverflow(bool_t enabled) {
  overflow_flag = enabled;
}

void mathWrappersSetFlagSpcRes(bool_t enabled) {
  spcres_flag = enabled;
}

void mathWrappersSetCurrentAngularMode(angularMode_t mode) {
  currentAngularMode = mode;
}

void mathWrappersSetTrigOutputs(bool_t enabled, int32_t sin_value, int32_t cos_value, int32_t tan_value) {
  trig_outputs.enabled = enabled;
  setFakeReal(&trig_outputs.sin_value, sin_value, 0);
  setFakeReal(&trig_outputs.cos_value, cos_value, 0);
  setFakeReal(&trig_outputs.tan_value, tan_value, 0);
}

void mathWrappersSetSeedInput(uint64_t seed, uint64_t seq) {
  memset(&real_input.value, 0, sizeof(real_input.value));
  real_input.available = true;
  memcpy(real_input.value.lsu, &seed, sizeof(seed));
  memcpy((unsigned char *)real_input.value.lsu + sizeof(seed), &seq, sizeof(seq));
}

void mathWrappersSetPcgState(uint64_t state, uint64_t inc) {
  pcg32_global.state = state;
  pcg32_global.inc = inc;
}

void mathWrappersSetUptimeMs(uint32_t value) {
  fake_uptime_ms = value;
}

void mathWrappersSetFreeRamMemory(uint32_t value) {
  fake_free_ram_memory = value;
}

void mathWrappersSetFreeFlash(uint32_t value) {
  fake_free_flash = value;
}

void mathWrappersCapture(math_wrappers_snapshot_t *out) {
  snapshot.final_register_data_type = current_register_data_type;
  snapshot.final_register_tag = current_register_tag;
  snapshot.final_register_real34_value = fakeRegisterScalarValue();
  snapshot.final_register_real34_bits = register_slot[15];
  snapshot.final_register_shortint_raw = *(uint64_t *)register_slot;
  snapshot.final_register_longint_value = longint_input.value;
  snapshot.final_overflow_flag = overflow_flag;
  snapshot.final_pcg_state = pcg32_global.state;
  snapshot.final_pcg_inc = pcg32_global.inc;
  snapshot.final_there_is_something_to_undo = thereIsSomethingToUndo;
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

void elementwiseRema(void (*func)(void)) {
  if(func != NULL) {
    func();
  }
}

void elementwiseRemaReal(void (*func)(void)) {
  elementwiseRema(func);
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

void processIntRealComplexDyadicFunction(void (*realf)(void),
                                        void (*complexf)(void),
                                        void (*shortintf)(void),
                                        void (*longintf)(void)) {
  snapshot.process_int_real_complex_dyadic_calls++;
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

bool_t getRegisterAsReal(calcRegister_t reg, real_t *value) {
  snapshot.get_register_as_real_calls++;
  if(current_register_data_type == dtTime) {
    if(!register_scalar_available) {
      return false;
    }
    setFakeReal(value, fakeRegisterScalarValue(), register_slot[15] & 0x70);
    return true;
  }
  if(reg == REGISTER_Y) {
    if(!real_y_input.available) {
      return false;
    }
    *value = real_y_input.value;
    return true;
  }
  if(reg == REGISTER_Z) {
    if(!real_z_input.available) {
      return false;
    }
    *value = real_z_input.value;
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

bool_t getRegisterAsShortInt(calcRegister_t reg, bool_t *sign, uint64_t *val, bool_t *overflow, bool_t *fractional) {
  (void)reg;

  if(current_register_data_type == dtShortInteger) {
    const uint64_t raw = *(uint64_t *)register_slot;
    if(sign != NULL) {
      *sign = (raw >> 63) != 0;
    }
    if(val != NULL) {
      *val = raw & ~(UINT64_C(1) << 63);
    }
    if(overflow != NULL) {
      *overflow = overflow_flag;
    }
    if(fractional != NULL) {
      *fractional = false;
    }
    return true;
  }

  if(current_register_data_type == dtLongInteger) {
    const int32_t input_value = longint_input.value;
    if(sign != NULL) {
      *sign = input_value < 0;
    }
    if(val != NULL) {
      *val = (uint64_t)(input_value < 0 ? -input_value : input_value);
    }
    if(overflow != NULL) {
      *overflow = false;
    }
    if(fractional != NULL) {
      *fractional = false;
    }
    return true;
  }

  return false;
}

bool_t getFlag(uint16_t flag) {
  if(flag == FLAG_CPXRES) {
    return cpxres_flag;
  }

  return getSystemFlag(flag);
}

bool_t getRegisterAsLongInt(calcRegister_t reg, longInteger_t val, bool_t *fractional) {
  const bool_t available = reg == REGISTER_Y ? longint_y_input.available : longint_input.available;
  const int32_t input_value = reg == REGISTER_Y ? longint_y_input.value : longint_input.value;

  snapshot.get_register_as_longint_calls++;
  snapshot.get_register_as_longint_result = available;
  snapshot.get_register_as_longint_value = input_value;
  mpz_init(val);
  if(fractional != NULL) {
    *fractional = false;
  }
  if(!available) {
    return false;
  }
  mpz_set_si(val, input_value);
  return true;
}

void convertLongIntegerRegisterToLongInteger(calcRegister_t reg, longInteger_t lgInt) {
  mpz_init(lgInt);
  mpz_set_si(lgInt, reg == REGISTER_Y ? longint_y_input.value : longint_input.value);
}

void convertLongIntegerRegisterToReal(calcRegister_t reg, real_t *real, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(real, reg == REGISTER_Y ? longint_y_input.value : longint_input.value, 0);
}

void convertLongIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  const int32_t value = source == REGISTER_Y ? longint_y_input.value : longint_input.value;

  (void)destination;
  current_register_data_type = dtReal34;
  current_register_tag = amNone;
  setRegisterScalar(value, 0);
}

void convertLongIntegerToLongIntegerRegister(const longInteger_t lgInt, calcRegister_t reg) {
  snapshot.convert_long_integer_to_register_calls++;
  snapshot.convert_long_integer_to_register_value = (int32_t)mpz_get_si(lgInt);
  snapshot.convert_long_integer_to_register_dest = reg;
  longint_input.value = (int32_t)mpz_get_si(lgInt);
  current_register_data_type = dtLongInteger;
  current_register_tag = longint_input.value < 0 ? LI_NEGATIVE : longint_input.value > 0 ? LI_POSITIVE : LI_ZERO;
}

void convertUInt64ToShortIntegerRegister(int16_t sign, uint64_t value, uint32_t base, calcRegister_t reg) {
  (void)reg;
  *(uint64_t *)register_slot = value | ((uint64_t)(sign != 0) << 63);
  current_register_data_type = dtShortInteger;
  current_register_tag = base;
}

void convertShortIntegerRegisterToUInt64(calcRegister_t reg, int16_t *sign, uint64_t *value) {
  const uint64_t raw = *(uint64_t *)getRegisterDataPointer(reg);

  if(sign != NULL) {
    *sign = (raw >> 63) != 0;
  }
  if(value != NULL) {
    *value = raw & ~(UINT64_C(1) << 63);
  }
}

void convertLongIntegerToShortIntegerRegister(const longInteger_t longInteger, uint32_t base, calcRegister_t reg) {
  const int64_t value = mpz_get_si(longInteger);

  (void)reg;
  *(uint64_t *)register_slot = encodeShortInteger(value);
  current_register_data_type = dtShortInteger;
  current_register_tag = base;
}

void real34ToIntegralValue(const real34_t *source, real34_t *destination, enum rounding mode) {
  (void)mode;
  setRegisterReal34((uint8_t *)destination, fakeReal34Value(source), source->bytes[15] & 0x70);
}

void real34Subtract(const real34_t *operand1, const real34_t *operand2, real34_t *res) {
  setRegisterReal34((uint8_t *)res, fakeReal34Value(operand1) - fakeReal34Value(operand2), operand1->bytes[15] & 0x70);
}

bool_t real34CompareLessThan(const real34_t *lhs, const real34_t *rhs) {
  return fakeReal34Value(lhs) < fakeReal34Value(rhs);
}

bool_t real34IsInfinite(const real34_t *value) {
  return (value->bytes[15] & DECINF) != 0;
}

int32_t real34GetExponent(const real34_t *value) {
  const int32_t magnitude = fakeReal34Value(value);

  if(magnitude == 0) {
    return 0;
  }
  return magnitude < 0 ? -magnitude : magnitude;
}

void real34NextPlus(const real34_t *source, real34_t *destination) {
  setRegisterReal34((uint8_t *)destination, fakeReal34Value(source) + 1, source->bytes[15] & 0x70);
}

void real34NextMinus(const real34_t *source, real34_t *destination) {
  setRegisterReal34((uint8_t *)destination, fakeReal34Value(source) - 1, source->bytes[15] & 0x70);
}

void realToReal34(const real_t *source, real34_t *destination) {
  setRegisterReal34((uint8_t *)destination, fakeRealValue(source), source->bits & 0x70);
}

void convertAngle34FromTo(real34_t *angle, angularMode_t fromMode, angularMode_t toMode) {
  setRegisterReal34((uint8_t *)angle, fakeReal34Value(angle) + fromMode - toMode, angle->bytes[15] & 0x70);
}

void real34RectangularToPolar(const real34_t *real, const real34_t *imag, real34_t *magnitude, real34_t *theta) {
  setRegisterReal34((uint8_t *)magnitude, fakeReal34Value(real) + fakeReal34Value(imag) + 5, 0);
  setRegisterReal34((uint8_t *)theta, fakeReal34Value(real) - fakeReal34Value(imag) + 7, 0);
}

void convertRealToLongIntegerRegister(const real_t *real, calcRegister_t dest, enum rounding roundingMode) {
  const int32_t value = fakeRealValue(real);

  (void)roundingMode;
  snapshot.convert_long_integer_to_register_calls++;
  snapshot.convert_long_integer_to_register_value = value;
  snapshot.convert_long_integer_to_register_dest = dest;
  longint_input.value = value;
  current_register_data_type = dtLongInteger;
  current_register_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void convertReal34ToLongIntegerRegister(const real34_t *real, calcRegister_t dest, enum rounding roundingMode) {
  const int32_t value = fakeReal34Value(real);

  (void)roundingMode;
  snapshot.convert_long_integer_to_register_calls++;
  snapshot.convert_long_integer_to_register_value = value;
  snapshot.convert_long_integer_to_register_dest = dest;
  longint_input.value = value;
  current_register_data_type = dtLongInteger;
  current_register_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void convertRealToResultRegister(const real_t *real, calcRegister_t reg, angularMode_t angleMode) {
  snapshot.convert_real_to_result_calls++;
  snapshot.convert_real_to_result_value = fakeRealValue(real);
  snapshot.convert_real_to_result_bits = real->bits;
  snapshot.convert_real_to_result_angle = angleMode;
  snapshot.convert_real_to_result_raw = *real;
  (void)reg;
  current_register_data_type = dtReal34;
  current_register_tag = (uint32_t)angleMode;
  setRegisterScalar(fakeRealValue(real), real->bits & 0x70);
}

void convertRealToReal34ResultRegister(const real_t *real, calcRegister_t dest) {
  snapshot.convert_real_to_real34_result_calls++;
  snapshot.convert_real_to_real34_result_dest = dest;
  snapshot.convert_real_to_real34_result_raw = *real;
  current_register_data_type = dtReal34;
  current_register_tag = amNone;
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

void linkToComplexMatrixRegister(calcRegister_t reg, complex34Matrix_t *matrix) {
  (void)reg;
  *matrix = fake_complex_matrix;
}

void linkToRealMatrixRegister(calcRegister_t reg, real34Matrix_t *matrix) {
  (void)reg;
  *matrix = fake_real_matrix;
}

bool_t realMatrixInit(real34Matrix_t *matrix, uint16_t rows, uint16_t columns) {
  matrix->header.matrixRows = rows;
  matrix->header.matrixColumns = columns;
  for(uint16_t i = 0; i < rows * columns && i < 4; ++i) {
    setRegisterReal34((uint8_t *)&matrix->matrixElements[i], 0, 0);
  }
  return true;
}

bool_t complexMatrixInit(complex34Matrix_t *matrix, uint16_t rows, uint16_t columns) {
  matrix->header.matrixRows = rows;
  matrix->header.matrixColumns = columns;
  for(uint16_t i = 0; i < rows * columns && i < 4; ++i) {
    setRegisterReal34((uint8_t *)&matrix->matrixElements[i].real, 0, 0);
    setRegisterReal34((uint8_t *)&matrix->matrixElements[i].imag, 0, 0);
  }
  return true;
}

void realMatrixFree(real34Matrix_t *matrix) {
  (void)matrix;
}

void complexMatrixFree(complex34Matrix_t *matrix) {
  (void)matrix;
}

void convertReal34MatrixToReal34MatrixRegister(const real34Matrix_t *matrix, calcRegister_t reg) {
  (void)reg;
  fake_real_matrix = *matrix;
  current_register_data_type = dtReal34Matrix;
  current_register_tag = amNone;
}

void convertComplex34MatrixToComplex34MatrixRegister(const complex34Matrix_t *matrix, calcRegister_t reg) {
  (void)reg;
  fake_complex_matrix = *matrix;
  current_register_data_type = dtComplex34Matrix;
  current_register_tag = amNone;
}

void convertReal34MatrixRegisterToReal34Matrix(calcRegister_t reg, real34Matrix_t *matrix) {
  (void)reg;
  *matrix = fake_real_matrix;
}

void convertReal34MatrixRegisterToComplex34Matrix(calcRegister_t reg, complex34Matrix_t *matrix) {
  (void)reg;
  matrix->header = fake_real_matrix.header;
  for(uint16_t i = 0; i < matrix->header.matrixRows * matrix->header.matrixColumns && i < 4; ++i) {
    matrix->matrixElements[i].real = fake_real_matrix.matrixElements[i];
    setRegisterReal34((uint8_t *)&matrix->matrixElements[i].imag, 0, 0);
  }
}

void convertReal34MatrixToComplex34Matrix(const real34Matrix_t *realMatrix, complex34Matrix_t *complexMatrix) {
  complexMatrix->header = realMatrix->header;
  for(uint16_t i = 0; i < complexMatrix->header.matrixRows * complexMatrix->header.matrixColumns && i < 4; ++i) {
    complexMatrix->matrixElements[i].real = realMatrix->matrixElements[i];
    setRegisterReal34((uint8_t *)&complexMatrix->matrixElements[i].imag, 0, 0);
  }
}

void setRegisterTag(calcRegister_t reg, uint32_t tag) {
  (void)reg;
  current_register_tag = tag;
}

void setRegisterAngularMode(calcRegister_t reg, angularMode_t mode) {
  setRegisterTag(reg, (current_register_tag & ~amAngleMask) | (uint32_t)mode);
}

void WP34S_Mod(const real_t *x, const real_t *y, real_t *res, realContext_t *realContext) {
  const int32_t x_value = fakeRealValue(x);
  const int32_t y_value = fakeRealValue(y);
  int32_t remainder = 0;

  (void)realContext;

  if(y_value != 0) {
    remainder = x_value % y_value;
    if(remainder < 0) {
      remainder += y_value < 0 ? -y_value : y_value;
    }
  }

  setFakeReal(res, remainder, 0);
}

decNumber *decimal128ToNumber(const real34_t *source, decNumber *destination) {
  setFakeReal(destination, fakeReal34Value(source), source->bytes[15] & 0x70);
  return destination;
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

void C47_WP34S_Asin(const real_t *x, real_t *angle, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(angle, fakeRealValue(x) + 61, 0);
}

void C47_WP34S_Acos(const real_t *x, real_t *angle, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(angle, fakeRealValue(x) + 62, 0);
}

void C47_WP34S_Atan(const real_t *x, real_t *angle, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(angle, fakeRealValue(x) + 63, 0);
}

void C47_WP34S_Atan2(const real_t *y, const real_t *x, real_t *angle, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(angle, fakeRealValue(y) - fakeRealValue(x) + 94, 0);
}

void WP34S_ArcSinh(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 64, 0);
}

void WP34S_ArcTanh(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 65, 0);
}

void WP34S_Ln(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 66, 0);
}

void WP34S_Ln1P(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 67, 0);
}

void WP34S_ExpM1(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 68, 0);
}

void WP34S_Bernoulli(const real_t *x, real_t *res, bool_t bnstar, realContext_t *realContext) {
  const int32_t input_value = fakeRealValue(x);

  (void)realContext;
  if(input_value < 0 || (!bnstar && input_value == 0)) {
    setFakeReal(res, 0, 0x20);
    return;
  }

  setFakeReal(res, input_value + (bnstar ? 83 : 82), 0);
}

void WP34S_Factorial(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 91, 0);
}

void WP34S_InverseW(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 84, 0);
}

void WP34S_InverseComplexW(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(resReal, fakeRealValue(real) + 85, 0);
  setFakeReal(resImag, fakeRealValue(imag) + 86, 0);
}

void WP34S_LambertW(const real_t *x, real_t *res, bool_t negativeBranch, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + (negativeBranch ? 87 : 88), 0);
}

void WP34S_ComplexLambertW(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(resReal, fakeRealValue(real) + 89, 0);
  setFakeReal(resImag, fakeRealValue(imag) + 90, 0);
}

void WP34S_ComplexGamma(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(resReal, fakeRealValue(real) + 92, 0);
  setFakeReal(resImag, fakeRealValue(imag) + 93, 0);
}

void WP34S_betai(const real_t *b, const real_t *a, const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(b) + fakeRealValue(a) + fakeRealValue(x), 0);
}

void complexMagnitude(const real_t *real, const real_t *imag, real_t *magnitude, realContext_t *realContext) {
  real_t theta;

  realRectangularToPolar(real, imag, magnitude, &theta, realContext);
}

void int32ToReal(int32_t source, real_t *destination) {
  setFakeReal(destination, source, 0);
}

void WP34S_Erf(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 80, 0);
}

void WP34S_Erfc(const real_t *x, real_t *res, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(res, fakeRealValue(x) + 81, 0);
}

void sqrtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  const int32_t real_value = fakeRealValue(real);
  const int32_t imag_value = fakeRealValue(imag);
  real_t magnitude;
  real_t theta;

  if(imag_value == 0) {
    if(real_value < 0) {
      setFakeReal(resReal, 0, 0);
      setFakeReal(resImag, -real_value + 71, 0);
    }
    else {
      setFakeReal(resReal, real_value + 70, 0);
      setFakeReal(resImag, 0, 0);
    }
    return;
  }

  realRectangularToPolar(real, imag, &magnitude, &theta, realContext);
  realSquareRoot(&magnitude, &magnitude, realContext);
  realMultiply(&theta, const_1on2, &theta, realContext);
  realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, realContext);
  setFakeReal(resReal, real_value + imag_value + 72, 0);
  setFakeReal(resImag, real_value - imag_value + 73, 0);
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

void realRectangularToPolar(const real_t *real,
                            const real_t *imag,
                            real_t *magnitude,
                            real_t *theta,
                            realContext_t *realContext) {
  const int32_t real_value = fakeRealValue(real);
  const int32_t imag_value = fakeRealValue(imag);
  const int32_t magnitude_value = (real_value < 0 ? -real_value : real_value) + (imag_value < 0 ? -imag_value : imag_value) + 5;

  snapshot.real_polar_to_rectangular_calls++;
  snapshot.real_polar_to_rectangular_magnitude_value = real_value;
  snapshot.real_polar_to_rectangular_angle_value = imag_value;
  (void)realContext;
  setFakeReal(magnitude, magnitude_value, 0);
  setFakeReal(theta, real_value - imag_value + 7, 0);
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

decNumber *decNumberSquareRoot(decNumber *result, const decNumber *rhs, decContext *realContext) {
  (void)realContext;
  setFakeReal(result, fakeRealValue(rhs) + 69, rhs->bits & 0x70);
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

decNumber *decNumberAdd(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *realContext) {
  const int32_t result_exponent = lhs->exponent < rhs->exponent ? lhs->exponent : rhs->exponent;
  int128_t lhs_coeff = signedFakeCoeff(lhs);
  int128_t rhs_coeff = signedFakeCoeff(rhs);

  snapshot.dec_number_add_calls++;
  (void)realContext;

  lhs_coeff *= (int128_t)pow10u((uint32_t)(lhs->exponent - result_exponent));
  rhs_coeff *= (int128_t)pow10u((uint32_t)(rhs->exponent - result_exponent));
  setFakeRealWithCoeff(result, lhs_coeff + rhs_coeff, 0, result_exponent);
  return result;
}

decNumber *decNumberSubtract(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *realContext) {
  const int32_t result_exponent = lhs->exponent < rhs->exponent ? lhs->exponent : rhs->exponent;
  int128_t lhs_coeff = signedFakeCoeff(lhs);
  int128_t rhs_coeff = signedFakeCoeff(rhs);

  snapshot.dec_number_subtract_calls++;
  (void)realContext;

  lhs_coeff *= (int128_t)pow10u((uint32_t)(lhs->exponent - result_exponent));
  rhs_coeff *= (int128_t)pow10u((uint32_t)(rhs->exponent - result_exponent));
  setFakeRealWithCoeff(result, lhs_coeff - rhs_coeff, 0, result_exponent);
  return result;
}

decNumber *decNumberFMA(decNumber *result, const decNumber *lhs, const decNumber *rhs, const decNumber *term, decContext *realContext) {
  real_t product;

  snapshot.dec_number_fma_calls++;
  (void)realContext;

  setFakeRealWithCoeff(&product, signedFakeCoeff(lhs) * signedFakeCoeff(rhs), 0, lhs->exponent + rhs->exponent);
  return decNumberAdd(result, &product, term, realContext);
}

decNumber *decNumberFromUInt32(decNumber *result, uint32_t source) {
  snapshot.dec_number_from_uint32_calls++;
  snapshot.dec_number_from_uint32_last_source = source;
  setFakeRealWithCoeff(result, source, 0, 0);
  return result;
}

void realToIntegralValue(const real_t *source, real_t *destination, enum rounding mode, realContext_t *realContext) {
  (void)mode;
  (void)realContext;
  *destination = *source;
}

bool_t realCompareAbsEqual(const real_t *number1, const real_t *number2) {
  const int32_t lhs_value = fakeRealValue(number1);
  const int32_t rhs_value = fakeRealValue(number2);

  snapshot.real_compare_abs_equal_calls++;
  snapshot.real_compare_abs_equal_lhs_value = lhs_value;
  snapshot.real_compare_abs_equal_rhs_value = rhs_value;
  return (lhs_value < 0 ? -lhs_value : lhs_value) == (rhs_value < 0 ? -rhs_value : rhs_value);
}

bool_t realCompareEqual(const real_t *number1, const real_t *number2) {
  return fakeRealValue(number1) == fakeRealValue(number2) && ((number1->bits & 0x70) == (number2->bits & 0x70));
}

bool_t realCompareLessThan(const real_t *number1, const real_t *number2) {
  return fakeRealValue(number1) < fakeRealValue(number2);
}

bool_t realIsAnInteger(const real_t *x) {
  return !realIsSpecial(x);
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

void mulComplexReal(const real_t *factor1Real,
                    const real_t *factor1Imag,
                    const real_t *factor2,
                    real_t *productReal,
                    real_t *productImag,
                    realContext_t *realContext) {
  (void)realContext;
  setFakeReal(productReal, fakeRealValue(factor1Real) * fakeRealValue(factor2), 0);
  setFakeReal(productImag, fakeRealValue(factor1Imag) * fakeRealValue(factor2), 0);
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

int64_t WP34S_build_value(uint64_t x, int32_t sign) {
  return (int64_t)(x | ((uint64_t)(sign != 0) << 63));
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

uint64_t WP34S_intLog10(uint64_t x) {
  uint64_t value = WP34S_extract_value(x, NULL);
  uint64_t result = 0;

  while(value >= 10) {
    value /= 10;
    result++;
  }

  return result;
}

uint64_t WP34S_int2pow(uint64_t x) {
  uint64_t exponent = WP34S_extract_value(x, NULL);
  uint64_t result = 1;

  snapshot.wp34s_int2pow_calls++;
  snapshot.wp34s_int2pow_input = x;
  while(exponent-- != 0) {
    result *= 2;
  }
  return result;
}

uint64_t WP34S_intAbs(uint64_t x) {
  return WP34S_extract_value(x, NULL);
}

uint64_t WP34S_intLog2(uint64_t x) {
  uint64_t value = WP34S_extract_value(x, NULL);
  uint64_t result = 0;

  while(value > 1) {
    value >>= 1;
    result++;
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

static uint64_t gcdUnsigned(uint64_t lhs, uint64_t rhs) {
  while(rhs != 0) {
    const uint64_t remainder = lhs % rhs;
    lhs = rhs;
    rhs = remainder;
  }
  return lhs;
}

uint64_t WP34S_intGCD(uint64_t y, uint64_t x) {
  return gcdUnsigned(WP34S_extract_value(y, NULL), WP34S_extract_value(x, NULL));
}

uint64_t WP34S_intLCM(uint64_t y, uint64_t x) {
  const uint64_t lhs = WP34S_extract_value(y, NULL);
  const uint64_t rhs = WP34S_extract_value(x, NULL);
  const uint64_t gcd = gcdUnsigned(lhs, rhs);

  if(lhs == 0 || rhs == 0) {
    return 0;
  }
  return (lhs / gcd) * rhs;
}

uint64_t WP34S_intAdd(uint64_t x, uint64_t y) {
  return WP34S_extract_value(x, NULL) + WP34S_extract_value(y, NULL);
}

uint64_t WP34S_intSubtract(uint64_t x, uint64_t y) {
  return WP34S_extract_value(x, NULL) - WP34S_extract_value(y, NULL);
}

void convertAngleFromTo(real_t *angle, angularMode_t fromAngularMode, angularMode_t toAngularMode, realContext_t *realContext) {
  snapshot.convert_angle_from_to_calls++;
  snapshot.convert_angle_from_to_input_value = fakeRealValue(angle);
  snapshot.convert_angle_from_to_from_mode = fromAngularMode;
  snapshot.convert_angle_from_to_to_mode = toAngularMode;
  (void)realContext;
  setFakeReal(angle, fakeRealValue(angle) + fromAngularMode - toAngularMode, angle->bits & 0x70);
}

void roundToSignificantDigits(const real_t *source, real_t *destination, int32_t digits, realContext_t *realContext) {
  (void)digits;
  (void)realContext;
  *destination = *source;
}

void fnSetFlag(int32_t flag) {
  snapshot.fn_set_flag_calls++;
  snapshot.fn_set_flag_last_flag = flag;
}

void fnRefreshState(void) {
  snapshot.fn_refresh_state_calls++;
}

void forceSystemFlag(unsigned int sf, int set) {
  if(sf == FLAG_OVERFLOW) {
    overflow_flag = set != 0;
  }
}

void setLastintegerBasetoZero(void) {
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
  if(flag == FLAG_SPCRES) {
    return spcres_flag;
  }
  if(flag == FLAG_OVERFLOW) {
    return overflow_flag;
  }
  return false;
}

void setSystemFlag(int32_t flag) {
  if(flag == FLAG_SPCRES) {
    spcres_flag = true;
  }
  if(flag == FLAG_OVERFLOW) {
    overflow_flag = true;
  }
}

void clearSystemFlag(int32_t flag) {
  if(flag == FLAG_SPCRES) {
    spcres_flag = false;
  }
  if(flag == FLAG_OVERFLOW) {
    overflow_flag = false;
  }
}

void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line) {
  snapshot.display_calc_error_calls++;
  snapshot.display_calc_error_last_code = error_code;
  snapshot.display_calc_error_last_message_reg_line = err_message_register_line;
  snapshot.display_calc_error_last_register_line = err_register_line;
}

void displayBugScreen(const char *message) {
  (void)message;
}

void saveForUndo(void) {
  snapshot.save_for_undo_calls++;
}

void liftStack(void) {
  snapshot.lift_stack_calls++;
}

const real_t *z47_math_wrappers_const_1e_6(void) {
  return &fake_const_1e_6_value;
}

const real_t *z47_math_wrappers_const_100(void) {
  return &fake_const_100_value;
}

const real_t *z47_math_wrappers_const_180(void) {
  return &fake_const_180_value;
}

void reallocateRegister(calcRegister_t regist, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag) {
  snapshot.reallocate_register_calls++;
  snapshot.reallocate_register_reg = regist;
  snapshot.reallocate_register_data_type = data_type;
  snapshot.reallocate_register_data_size_without_data_len_blocks = data_size_without_data_len_blocks;
  snapshot.reallocate_register_tag = tag;
  current_register_data_type = data_type;
  current_register_tag = tag;
}

void fnDrop(uint16_t unusedButMandatoryParameter) {
  snapshot.fn_drop_calls++;
  snapshot.fn_drop_last_param = unusedButMandatoryParameter;
}

void fnDropY(uint16_t unusedButMandatoryParameter) {
  fnDrop(unusedButMandatoryParameter);
}

void refreshLcd(void *unused) {
  (void)unused;
  snapshot.fn_refresh_state_calls++;
}

void lcd_refresh(void) {
  snapshot.fn_refresh_state_calls++;
}

void fnChangeBase(uint16_t base) {
  (void)base;
}

void fnUndo(uint16_t unusedButMandatoryParameter) {
  snapshot.fn_undo_calls++;
  snapshot.fn_undo_last_param = unusedButMandatoryParameter;
  thereIsSomethingToUndo = false;
}

uint32_t getUptimeMs(void) {
  snapshot.get_uptime_ms_calls++;
  return fake_uptime_ms;
}

uint32_t getFreeRamMemory(void) {
  snapshot.get_free_ram_memory_calls++;
  return fake_free_ram_memory;
}

uint32_t getFreeFlash(void) {
  snapshot.get_free_flash_calls++;
  return fake_free_flash;
}

uint32_t decQuadIsNaN(const decQuad *dq) {
  return (dq->bytes[15] & 0x30) != 0;
}

uint32_t decQuadIsZero(const decQuad *dq) {
  uint32_t magnitude = 0;

  memcpy(&magnitude, dq->bytes, sizeof(magnitude));
  return magnitude == 0 && (dq->bytes[15] & 0x70) == 0;
}

uint32_t decQuadIsNegative(const decQuad *dq) {
  return (dq->bytes[15] & 0x80) != 0;
}

void moreInfoOnError(const char *msg1, const char *msg2, const char *msg3, const char *msg4) {
  snapshot.more_info_calls++;
  (void)msg1;
  (void)msg2;
  (void)msg3;
  (void)msg4;
}

void doNothing(void) {
}

void realNextToward(const real_t *x, const real_t *y, real_t *result, realContext_t *realContext) {
  const int32_t lhs = fakeRealValue(x);
  const int32_t rhs = fakeRealValue(y);

  (void)realContext;
  if(lhs == rhs) {
    *result = *x;
    return;
  }
  setFakeReal(result, lhs + (rhs > lhs ? 1 : -1), x->bits & 0x70);
}

const char *getRegisterDataTypeName(calcRegister_t reg, bool_t article, bool_t abbreviated) {
  (void)reg;
  (void)article;
  (void)abbreviated;
  return "test";
}

const char *getDataTypeName(uint32_t data_type, bool_t article, bool_t abbreviated) {
  (void)article;
  (void)abbreviated;

  switch(data_type) {
    case dtShortInteger: return "short integer";
    case dtLongInteger: return "long integer";
    case dtReal34: return "real";
    case dtComplex34: return "complex";
    case dtTime: return "time";
    case dtReal34Matrix: return "real matrix";
    case dtComplex34Matrix: return "complex matrix";
    default: return "test";
  }
}

void longIntegerRegisterToDisplayString(calcRegister_t reg, char *buffer, int bufferLength, int screenWidth, int limit, bool_t allowLarge) {
  (void)reg;
  (void)screenWidth;
  (void)limit;
  (void)allowLarge;
  if(bufferLength > 0) {
    snprintf(buffer, (size_t)bufferLength, "%d", longint_input.value);
  }
}

const real34_t *z47_math_wrappers_const34_0(void) {
  return &fake_const34_zero_value;
}

bool_t real34CompareEqual(const real34_t *lhs, const real34_t *rhs) {
  return memcmp(lhs, rhs, sizeof(*lhs)) == 0;
}

bool_t real34IsAnInteger(const real34_t *value) {
  return real34GetExponent(value) >= 0;
}

void WP34S_Logxy(const real_t *numer, const real_t *denom, real_t *res, realContext_t *realContext) {
  decNumberDivide(res, numer, denom, realContext);
}

void convertShortIntegerRegisterToLongInteger(calcRegister_t reg, longInteger_t long_integer) {
  int16_t sign;
  uint64_t value;

  convertShortIntegerRegisterToUInt64(reg, &sign, &value);
  mpz_set_ui(long_integer, value);
  if(sign < 0) {
    mpz_neg(long_integer, long_integer);
  }
}

void longInteger2Pow(int32_t exponent, longInteger_t result) {
  mpz_ui_pow_ui(result, 2, (unsigned long)exponent);
}

void longIntegerDivideQuotientRemainder(const longInteger_t dividend, const longInteger_t divisor, longInteger_t quotient, longInteger_t remainder) {
  mpz_tdiv_qr(quotient, remainder, dividend, divisor);
}
