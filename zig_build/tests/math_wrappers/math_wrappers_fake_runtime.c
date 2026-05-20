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
static uint32_t current_register_y_data_type = dtReal34;
static uint32_t current_register_y_tag = amNone;
static uint32_t current_register_z_data_type = dtReal34;
static uint32_t current_register_z_tag = amNone;
static uint32_t current_register_t_data_type = dtReal34;
static uint32_t current_register_t_tag = amNone;

static uint8_t register_slot[32];
static uint8_t register_y_slot[32];
static uint8_t register_z_slot[32];
static uint8_t register_t_slot[32];
static uint64_t shortint_y_slot;
static uint64_t shortint_z_slot;
static uint64_t shortint_t_slot;
static uint32_t register_scalar_magnitude;
static bool_t register_scalar_available = true;
static real34Matrix_t fake_real_matrix;
static complex34Matrix_t fake_complex_matrix;
static real34Matrix_t fake_real_y_matrix;
static complex34Matrix_t fake_complex_y_matrix;

typedef struct {
  bool_t available;
  real_t value;
} real_register_input_t;

typedef struct {
  bool_t available;
  real_t value;
  angularMode_t angle_mode;
} real_angle_input_t;

typedef struct {
  bool_t available;
  real_t real;
  real_t imag;
} complex_register_input_t;

typedef struct {
  bool_t available;
  int32_t value;
} longint_register_input_t;

static real_register_input_t real_input;
static real_register_input_t real_y_input;
static real_register_input_t real_z_input;
static real_register_input_t real_t_input;
static real_angle_input_t real_angle_input;
static complex_register_input_t complex_input;
static complex_register_input_t complex_y_input;
static complex_register_input_t complex_z_input;
static complex_register_input_t complex_t_input;
static longint_register_input_t longint_input;
static longint_register_input_t longint_y_input;
static longint_register_input_t longint_z_input;
static longint_register_input_t longint_t_input;

static struct {
  bool_t result;
  int16_t sign;
  uint64_t int_part;
  uint64_t numer;
  uint64_t denom;
  int16_t less_equal_greater;
} fraction_result;

static struct {
  bool_t enabled;
  int32_t error_code;
  bool_t fractional;
  int32_t value;
} longint_quiet_result;

static struct {
  bool_t enabled;
  real_t sin_value;
  real_t cos_value;
  real_t tan_value;
} trig_outputs;

static bool_t spcres_flag = false;
static bool_t cpxres_flag = false;
static bool_t overflow_flag = false;
static bool_t carry_flag = false;
static uint32_t fake_uptime_ms = 0;
static uint32_t fake_free_ram_memory = 0;
static uint32_t fake_free_flash = 0;

realContext_t ctxtReal34;
realContext_t ctxtReal39;
realContext_t ctxtReal51;
realContext_t ctxtReal75;
uint8_t shortIntegerMode = SIM_UNSIGN;
uint8_t shortIntegerWordSize = 64;
uint64_t shortIntegerMask = UINT64_MAX;
uint64_t shortIntegerSignBit = UINT64_C(1) << 63;
angularMode_t currentAngularMode = amNone;
bool_t thereIsSomethingToUndo = false;
pcg32_random_t pcg32_global = PCG32_INITIALIZER;
int32_t significantDigits = 34;
int32_t temporaryInformation = 0;
uint64_t systemFlags0 = 0;
uint64_t systemFlags1 = 0;
static real_t fake_const_nan_value;
static real_t fake_const_one_value;
static real_t fake_const_100_value;
static real_t fake_const_180_value;
static real_t fake_const_plus_infinity_value;
static real_t fake_const_minus_infinity_value;
static real_t fake_const_1e_6_value;
static real34_t fake_const34_zero_value;
static real34_t fake_const34_86400_value;
const real_t *const_NaN = &fake_const_nan_value;
uint8_t lastErrorCode = 0;
char errorMessage[ERROR_MESSAGE_LENGTH];
char tmpString[ERROR_MESSAGE_LENGTH];
const char *commonBugScreenMessages[] = {
  "%s %u %s",
};
const font_t standardFont = {0};
const font_t numericFont = {0};
uint8_t roundingMode = 0;
const enum rounding roundingModeTable[7] = {
  DEC_ROUND_HALF_EVEN,
  DEC_ROUND_HALF_UP,
  DEC_ROUND_HALF_DOWN,
  DEC_ROUND_UP,
  DEC_ROUND_DOWN,
  DEC_ROUND_CEILING,
  DEC_ROUND_FLOOR,
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

static int32_t fakeRealValue(const real_t *value);

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

static uint64_t *shortIntegerSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return &shortint_y_slot;
  }
  if(reg == REGISTER_Z) {
    return &shortint_z_slot;
  }
  if(reg == REGISTER_T) {
    return &shortint_t_slot;
  }
  return (uint64_t *)register_slot;
}

static uint32_t *registerDataTypeSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return &current_register_y_data_type;
  }
  if(reg == REGISTER_Z) {
    return &current_register_z_data_type;
  }
  if(reg == REGISTER_T) {
    return &current_register_t_data_type;
  }
  return &current_register_data_type;
}

static uint32_t *registerTagSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return &current_register_y_tag;
  }
  if(reg == REGISTER_Z) {
    return &current_register_z_tag;
  }
  if(reg == REGISTER_T) {
    return &current_register_t_tag;
  }
  return &current_register_tag;
}

static uint8_t *registerDataSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return register_y_slot;
  }
  if(reg == REGISTER_Z) {
    return register_z_slot;
  }
  if(reg == REGISTER_T) {
    return register_t_slot;
  }
  return register_slot;
}

typedef struct {
  uint32_t data_type;
  uint32_t tag;
  uint8_t data_slot[32];
  uint64_t shortint_raw;
  real_register_input_t real_value;
  complex_register_input_t complex_value;
  longint_register_input_t longint_value;
  real34Matrix_t real_matrix;
  complex34Matrix_t complex_matrix;
} fakeRegisterSurface_t;

static real_register_input_t *realInputSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return &real_y_input;
  }
  if(reg == REGISTER_Z) {
    return &real_z_input;
  }
  if(reg == REGISTER_T) {
    return &real_t_input;
  }
  return &real_input;
}

static complex_register_input_t *complexInputSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return &complex_y_input;
  }
  if(reg == REGISTER_Z) {
    return &complex_z_input;
  }
  if(reg == REGISTER_T) {
    return &complex_t_input;
  }
  return &complex_input;
}

static longint_register_input_t *longIntInputSlot(calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    return &longint_y_input;
  }
  if(reg == REGISTER_Z) {
    return &longint_z_input;
  }
  if(reg == REGISTER_T) {
    return &longint_t_input;
  }
  return &longint_input;
}

static real34Matrix_t *realMatrixSlot(calcRegister_t reg) {
  return reg == REGISTER_Y ? &fake_real_y_matrix : &fake_real_matrix;
}

static complex34Matrix_t *complexMatrixSlot(calcRegister_t reg) {
  return reg == REGISTER_Y ? &fake_complex_y_matrix : &fake_complex_matrix;
}

static uint16_t cappedMatrixElementCount(uint16_t rows, uint16_t columns) {
  const uint32_t count = (uint32_t)rows * (uint32_t)columns;
  return (uint16_t)(count < 4 ? count : 4);
}

static void refreshXScalarMirror(void) {
  const int32_t value = fakeRealValue(&real_input.value);

  register_scalar_available = real_input.available;
  register_scalar_magnitude = register_scalar_available ? (uint32_t)(value < 0 ? -value : value) : 0;
}

static void captureRegisterSurface(calcRegister_t reg, fakeRegisterSurface_t *surface) {
  memset(surface, 0, sizeof(*surface));
  surface->data_type = *registerDataTypeSlot(reg);
  surface->tag = *registerTagSlot(reg);
  memcpy(surface->data_slot, registerDataSlot(reg), sizeof(surface->data_slot));
  surface->shortint_raw = *shortIntegerSlot(reg);
  surface->real_value = *realInputSlot(reg);
  surface->complex_value = *complexInputSlot(reg);
  surface->longint_value = *longIntInputSlot(reg);
  if(reg == REGISTER_X || reg == REGISTER_Y) {
    surface->real_matrix = *realMatrixSlot(reg);
    surface->complex_matrix = *complexMatrixSlot(reg);
  }
}

static void restoreRegisterSurface(calcRegister_t reg, const fakeRegisterSurface_t *surface) {
  *registerDataTypeSlot(reg) = surface->data_type;
  *registerTagSlot(reg) = surface->tag;
  memcpy(registerDataSlot(reg), surface->data_slot, sizeof(surface->data_slot));
  *shortIntegerSlot(reg) = surface->shortint_raw;
  *realInputSlot(reg) = surface->real_value;
  *complexInputSlot(reg) = surface->complex_value;
  *longIntInputSlot(reg) = surface->longint_value;
  if(reg == REGISTER_X || reg == REGISTER_Y) {
    *realMatrixSlot(reg) = surface->real_matrix;
    *complexMatrixSlot(reg) = surface->complex_matrix;
  }
  if(reg == REGISTER_X) {
    refreshXScalarMirror();
  }
}

static void matrixMismatch(void) {
  displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

static uint16_t matrixIndex(uint16_t row, uint16_t column, uint16_t columns) {
  return (uint16_t)(row * columns + column);
}

static bool_t realMatrixShapesMatch(const real34Matrix_t *lhs, const real34Matrix_t *rhs) {
  return lhs->header.matrixRows == rhs->header.matrixRows && lhs->header.matrixColumns == rhs->header.matrixColumns;
}

static bool_t complexMatrixShapesMatch(const complex34Matrix_t *lhs, const complex34Matrix_t *rhs) {
  return lhs->header.matrixRows == rhs->header.matrixRows && lhs->header.matrixColumns == rhs->header.matrixColumns;
}

static void real34ToRealPair(const real34_t *source, real_t *destination) {
  real34ToReal(source, destination);
}

static void complex34ToRealPair(const complex34_t *source, real_t *real, real_t *imag) {
  real34ToReal(&source->real, real);
  real34ToReal(&source->imag, imag);
}

static void realPairToComplex34(const real_t *real, const real_t *imag, complex34_t *destination) {
  realToReal34(real, &destination->real);
  realToReal34(imag, &destination->imag);
}

static void addComplexValues(const real_t *lhs_real,
                             const real_t *lhs_imag,
                             const real_t *rhs_real,
                             const real_t *rhs_imag,
                             real_t *sum_real,
                             real_t *sum_imag,
                             realContext_t *realContext) {
  realAdd(lhs_real, rhs_real, sum_real, realContext);
  realAdd(lhs_imag, rhs_imag, sum_imag, realContext);
}

static void subtractComplexValues(const real_t *lhs_real,
                                  const real_t *lhs_imag,
                                  const real_t *rhs_real,
                                  const real_t *rhs_imag,
                                  real_t *diff_real,
                                  real_t *diff_imag,
                                  realContext_t *realContext) {
  realSubtract(lhs_real, rhs_real, diff_real, realContext);
  realSubtract(lhs_imag, rhs_imag, diff_imag, realContext);
}

static bool_t realIsZeroLike(const real_t *value) {
  return realCompareEqual(value, const_0);
}

static bool_t complexIsZeroLike(const real_t *real, const real_t *imag) {
  return realIsZeroLike(real) && realIsZeroLike(imag);
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
  current_register_y_data_type = dtReal34;
  current_register_y_tag = amNone;
  current_register_z_data_type = dtReal34;
  current_register_z_tag = amNone;
  current_register_t_data_type = dtReal34;
  current_register_t_tag = amNone;
  memset(register_slot, 0, sizeof(register_slot));
  memset(register_y_slot, 0, sizeof(register_y_slot));
  memset(register_z_slot, 0, sizeof(register_z_slot));
  memset(register_t_slot, 0, sizeof(register_t_slot));
  shortint_y_slot = encodeShortInteger(2);
  shortint_z_slot = encodeShortInteger(3);
  shortint_t_slot = encodeShortInteger(4);
  register_scalar_available = true;
  setRegisterScalar(7, 0);
  *(uint64_t *)register_slot = encodeShortInteger(-3);

  real_input.available = true;
  setFakeReal(&real_input.value, 7, 0);

  real_y_input.available = true;
  setFakeReal(&real_y_input.value, 2, 0);

  real_z_input.available = true;
  setFakeReal(&real_z_input.value, 3, 0);

  real_t_input.available = true;
  setFakeReal(&real_t_input.value, 4, 0);

  real_angle_input.available = true;
  setFakeReal(&real_angle_input.value, 5, 0);
  real_angle_input.angle_mode = amRadian;

  complex_input.available = true;
  setFakeReal(&complex_input.real, 2, 0);
  setFakeReal(&complex_input.imag, 3, 0);

  complex_y_input.available = true;
  setFakeReal(&complex_y_input.real, 4, 0);
  setFakeReal(&complex_y_input.imag, 5, 0);

  complex_z_input.available = true;
  setFakeReal(&complex_z_input.real, 6, 0);
  setFakeReal(&complex_z_input.imag, 7, 0);

  complex_t_input.available = true;
  setFakeReal(&complex_t_input.real, 8, 0);
  setFakeReal(&complex_t_input.imag, 9, 0);

  longint_input.available = true;
  longint_input.value = -4;

  longint_y_input.available = true;
  longint_y_input.value = 9;

  longint_z_input.available = true;
  longint_z_input.value = 11;

  longint_t_input.available = true;
  longint_t_input.value = 13;

  fraction_result.result = true;
  fraction_result.sign = 1;
  fraction_result.int_part = 0;
  fraction_result.numer = 3;
  fraction_result.denom = 4;
  fraction_result.less_equal_greater = 0;

  longint_quiet_result.enabled = false;
  longint_quiet_result.error_code = ERROR_NONE;
  longint_quiet_result.fractional = false;
  longint_quiet_result.value = 0;

  trig_outputs.enabled = false;
  spcres_flag = false;
  cpxres_flag = false;
  overflow_flag = false;
  carry_flag = false;
  fake_uptime_ms = 0x12345678u;
  fake_free_ram_memory = 0x11223344u;
  fake_free_flash = 0x55667788u;
  shortIntegerMode = SIM_UNSIGN;
  shortIntegerWordSize = 64;
  currentAngularMode = amNone;
  roundingMode = 0;
  thereIsSomethingToUndo = false;
  lastErrorCode = 0;
  systemFlags0 = 0;
  systemFlags1 = 0;
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
  setRegisterReal34((uint8_t *)&fake_const34_86400_value, 86400, 0);
  setRegisterReal34(register_slot, 2, 0);
  setRegisterReal34(register_slot + sizeof(real34_t), 3, 0);

  fake_real_matrix.header.matrixRows = 2;
  fake_real_matrix.header.matrixColumns = 2;
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[0], 1, 0);
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[1], 2, 0);
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[2], 3, 0);
  setRegisterReal34((uint8_t *)&fake_real_matrix.matrixElements[3], 4, 0);

  fake_real_y_matrix = fake_real_matrix;

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

  fake_complex_y_matrix = fake_complex_matrix;
}

void mathWrappersSetSaveLastXResult(bool_t result) {
  save_last_x_result = result;
  snapshot.save_last_x_result = result;
}

void copySourceRegisterToDestRegister(calcRegister_t source_register, calcRegister_t dest_register) {
  fakeRegisterSurface_t surface;

  captureRegisterSurface(source_register, &surface);
  restoreRegisterSurface(dest_register, &surface);
}

void fnSwapXY(uint16_t unusedButMandatoryParameter) {
  fakeRegisterSurface_t x_surface;
  fakeRegisterSurface_t y_surface;

  (void)unusedButMandatoryParameter;
  captureRegisterSurface(REGISTER_X, &x_surface);
  captureRegisterSurface(REGISTER_Y, &y_surface);
  restoreRegisterSurface(REGISTER_X, &y_surface);
  restoreRegisterSurface(REGISTER_Y, &x_surface);
}

int16_t stringByteLength(const char *value) {
  return value == NULL ? 0 : (int16_t)strlen(value);
}

int16_t stringGlyphLength(const char *value) {
  return stringByteLength(value);
}

void xcopy(void *destination, const void *source, size_t length) {
  memcpy(destination, source, length);
}

void fractionToDisplayString(calcRegister_t regist, char *displayString) {
  (void)regist;
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "fraction");
}

void shortIntegerToDisplayString(calcRegister_t regist, char *displayString, bool_t determineFont, uint8_t baseOverride) {
  int16_t sign = 0;
  uint64_t value = 0;

  (void)determineFont;
  (void)baseOverride;
  convertShortIntegerRegisterToUInt64(regist, &sign, &value);
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "%s%llu", sign ? "-" : "", (unsigned long long)value);
}

void real34ToDisplayString(const real34_t *real34, uint32_t tag, char *displayString, const font_t *font, int16_t maxWidth, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace, irfracOption_t limitIrfrac) {
  (void)tag;
  (void)font;
  (void)maxWidth;
  (void)displayHasNDigits;
  (void)limitExponent;
  (void)frontSpace;
  (void)limitIrfrac;
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "%d", fakeReal34Value(real34));
}

void complex34ToDisplayString(const complex34_t *complex34, char *displayString, const font_t *font, int16_t maxWidth, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace, irfracOption_t limitIrfrac, uint16_t tagAngle, bool_t tagPolar) {
  (void)font;
  (void)maxWidth;
  (void)displayHasNDigits;
  (void)limitExponent;
  (void)frontSpace;
  (void)limitIrfrac;
  (void)tagAngle;
  (void)tagPolar;
  snprintf(displayString,
           ERROR_MESSAGE_LENGTH,
           "%d%+di",
           fakeReal34Value(&complex34->real),
           fakeReal34Value(&complex34->imag));
}

void dateToDisplayString(calcRegister_t regist, char *displayString) {
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "date:%d", fakeRealValue(&realInputSlot(regist)->value));
}

void timeToDisplayString(calcRegister_t regist, char *displayString, bool_t ignoreTDisp) {
  (void)ignoreTDisp;
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "time:%d", fakeRealValue(&realInputSlot(regist)->value));
}

void real34MatrixToDisplayString(calcRegister_t regist, char *displayString) {
  const real34Matrix_t *matrix = regist == REGISTER_Y ? &fake_real_y_matrix : &fake_real_matrix;
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "[%ux%u real matrix]", matrix->header.matrixRows, matrix->header.matrixColumns);
}

void complex34MatrixToDisplayString(calcRegister_t regist, char *displayString) {
  const complex34Matrix_t *matrix = regist == REGISTER_Y ? &fake_complex_y_matrix : &fake_complex_matrix;
  snprintf(displayString, ERROR_MESSAGE_LENGTH, "[%ux%u complex matrix]", matrix->header.matrixRows, matrix->header.matrixColumns);
}

real34_t *decQuadDivide(real34_t *res, const real34_t *operand1, const real34_t *operand2, realContext_t *context) {
  real_t lhs;
  real_t rhs;
  real_t quotient;

  real34ToReal(operand1, &lhs);
  real34ToReal(operand2, &rhs);
  realDivide(&lhs, &rhs, &quotient, context);
  realToReal34(&quotient, res);
  return res;
}

real34_t *decQuadAdd(real34_t *res, const real34_t *operand1, const real34_t *operand2, realContext_t *context) {
  real_t lhs;
  real_t rhs;
  real_t sum;

  real34ToReal(operand1, &lhs);
  real34ToReal(operand2, &rhs);
  realAdd(&lhs, &rhs, &sum, context);
  realToReal34(&sum, res);
  return res;
}

real34_t *decQuadMultiply(real34_t *res, const real34_t *operand1, const real34_t *operand2, realContext_t *context) {
  real_t lhs;
  real_t rhs;
  real_t product;

  real34ToReal(operand1, &lhs);
  real34ToReal(operand2, &rhs);
  realMultiply(&lhs, &rhs, &product, context);
  realToReal34(&product, res);
  return res;
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
  setRegisterReal34(register_y_slot, value, bits);
  current_register_y_data_type = dtReal34;
  current_register_y_tag = amNone;
}

void mathWrappersSetRealZInput(bool_t available, int32_t value, uint8_t bits) {
  real_z_input.available = available;
  setFakeReal(&real_z_input.value, value, bits);
  setRegisterReal34(register_z_slot, value, bits);
  current_register_z_data_type = dtReal34;
  current_register_z_tag = amNone;
}

void mathWrappersSetRealTInput(bool_t available, int32_t value, uint8_t bits) {
  real_t_input.available = available;
  setFakeReal(&real_t_input.value, value, bits);
  setRegisterReal34(register_t_slot, value, bits);
  current_register_t_data_type = dtReal34;
  current_register_t_tag = amNone;
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

void mathWrappersSetComplexYInput(bool_t available, int32_t real_value, uint8_t real_bits, int32_t imag_value, uint8_t imag_bits) {
  complex_y_input.available = available;
  setFakeReal(&complex_y_input.real, real_value, real_bits);
  setFakeReal(&complex_y_input.imag, imag_value, imag_bits);
  setRegisterReal34(register_y_slot, real_value, real_bits);
  setRegisterReal34(register_y_slot + sizeof(real34_t), imag_value, imag_bits);
  current_register_y_data_type = dtComplex34;
  current_register_y_tag = amNone;
}

void mathWrappersSetComplexZInput(bool_t available, int32_t real_value, uint8_t real_bits, int32_t imag_value, uint8_t imag_bits) {
  complex_z_input.available = available;
  setFakeReal(&complex_z_input.real, real_value, real_bits);
  setFakeReal(&complex_z_input.imag, imag_value, imag_bits);
  setRegisterReal34(register_z_slot, real_value, real_bits);
  setRegisterReal34(register_z_slot + sizeof(real34_t), imag_value, imag_bits);
  current_register_z_data_type = dtComplex34;
  current_register_z_tag = amNone;
}

void mathWrappersSetComplexTInput(bool_t available, int32_t real_value, uint8_t real_bits, int32_t imag_value, uint8_t imag_bits) {
  complex_t_input.available = available;
  setFakeReal(&complex_t_input.real, real_value, real_bits);
  setFakeReal(&complex_t_input.imag, imag_value, imag_bits);
  setRegisterReal34(register_t_slot, real_value, real_bits);
  setRegisterReal34(register_t_slot + sizeof(real34_t), imag_value, imag_bits);
  current_register_t_data_type = dtComplex34;
  current_register_t_tag = amNone;
}

void mathWrappersSetShortIntegerInput(int64_t value) {
  *shortIntegerSlot(REGISTER_X) = encodeShortInteger(value);
}

void mathWrappersSetShortIntegerYInput(int64_t value) {
  *shortIntegerSlot(REGISTER_Y) = encodeShortInteger(value);
  current_register_y_data_type = dtShortInteger;
  current_register_y_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void mathWrappersSetShortIntegerZInput(int64_t value) {
  *shortIntegerSlot(REGISTER_Z) = encodeShortInteger(value);
  current_register_z_data_type = dtShortInteger;
  current_register_z_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void mathWrappersSetShortIntegerTInput(int64_t value) {
  *shortIntegerSlot(REGISTER_T) = encodeShortInteger(value);
  current_register_t_data_type = dtShortInteger;
  current_register_t_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
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
  current_register_y_data_type = dtLongInteger;
  current_register_y_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void mathWrappersSetLongIntegerZInput(bool_t available, int32_t value) {
  longint_z_input.available = available;
  longint_z_input.value = value;
  current_register_z_data_type = dtLongInteger;
  current_register_z_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void mathWrappersSetLongIntegerTInput(bool_t available, int32_t value) {
  longint_t_input.available = available;
  longint_t_input.value = value;
  current_register_t_data_type = dtLongInteger;
  current_register_t_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void mathWrappersSetLongIntegerQuietResult(bool_t enabled,
                                           int32_t error_code,
                                           bool_t fractional,
                                           int32_t value) {
  longint_quiet_result.enabled = enabled;
  longint_quiet_result.error_code = error_code;
  longint_quiet_result.fractional = fractional;
  longint_quiet_result.value = value;
}

void mathWrappersSetFractionResult(bool_t result,
                                   int16_t sign,
                                   uint64_t int_part,
                                   uint64_t numer,
                                   uint64_t denom,
                                   int16_t less_equal_greater) {
  fraction_result.result = result;
  fraction_result.sign = sign;
  fraction_result.int_part = int_part;
  fraction_result.numer = numer;
  fraction_result.denom = denom;
  fraction_result.less_equal_greater = less_equal_greater;
}

void mathWrappersSetFlagCpxRes(bool_t enabled) {
  cpxres_flag = enabled;
}

void mathWrappersSetFlagCarry(bool_t enabled) {
  carry_flag = enabled;
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
  for(uint16_t i = 0; i < 4; ++i) {
    snapshot.final_real_matrix_values[i] = fakeReal34Value(&fake_real_matrix.matrixElements[i]);
    snapshot.final_real_matrix_bits[i] = fake_real_matrix.matrixElements[i].bytes[15];
    snapshot.final_complex_matrix_real_values[i] = fakeReal34Value(&fake_complex_matrix.matrixElements[i].real);
    snapshot.final_complex_matrix_real_bits[i] = fake_complex_matrix.matrixElements[i].real.bytes[15];
    snapshot.final_complex_matrix_imag_values[i] = fakeReal34Value(&fake_complex_matrix.matrixElements[i].imag);
    snapshot.final_complex_matrix_imag_bits[i] = fake_complex_matrix.matrixElements[i].imag.bytes[15];
  }

  snapshot.final_register_data_type = current_register_data_type;
  snapshot.final_register_tag = current_register_tag;
  snapshot.final_register_real34_value = fakeRegisterScalarValue();
  snapshot.final_register_real34_bits = register_slot[15];
  snapshot.final_register_complex_real_value = fakeReal34Value((const real34_t *)register_slot);
  snapshot.final_register_complex_real_bits = register_slot[15];
  snapshot.final_register_complex_imag_value = fakeReal34Value((const real34_t *)(register_slot + sizeof(real34_t)));
  snapshot.final_register_complex_imag_bits = register_slot[sizeof(real34_t) + 15];
  snapshot.final_register_y_data_type = current_register_y_data_type;
  snapshot.final_register_y_tag = current_register_y_tag;
  snapshot.final_register_y_real34_value = fakeReal34Value((const real34_t *)register_y_slot);
  snapshot.final_register_y_real34_bits = register_y_slot[15];
  snapshot.final_register_y_complex_real_value = fakeReal34Value((const real34_t *)register_y_slot);
  snapshot.final_register_y_complex_real_bits = register_y_slot[15];
  snapshot.final_register_y_complex_imag_value = fakeReal34Value((const real34_t *)(register_y_slot + sizeof(real34_t)));
  snapshot.final_register_y_complex_imag_bits = register_y_slot[sizeof(real34_t) + 15];
  snapshot.final_register_z_data_type = current_register_z_data_type;
  snapshot.final_register_z_tag = current_register_z_tag;
  snapshot.final_register_z_real34_value = fakeReal34Value((const real34_t *)register_z_slot);
  snapshot.final_register_z_real34_bits = register_z_slot[15];
  snapshot.final_register_z_complex_real_value = fakeReal34Value((const real34_t *)register_z_slot);
  snapshot.final_register_z_complex_real_bits = register_z_slot[15];
  snapshot.final_register_z_complex_imag_value = fakeReal34Value((const real34_t *)(register_z_slot + sizeof(real34_t)));
  snapshot.final_register_z_complex_imag_bits = register_z_slot[sizeof(real34_t) + 15];
  snapshot.final_register_t_data_type = current_register_t_data_type;
  snapshot.final_register_t_tag = current_register_t_tag;
  snapshot.final_register_t_real34_value = fakeReal34Value((const real34_t *)register_t_slot);
  snapshot.final_register_t_real34_bits = register_t_slot[15];
  snapshot.final_register_t_complex_real_value = fakeReal34Value((const real34_t *)register_t_slot);
  snapshot.final_register_t_complex_real_bits = register_t_slot[15];
  snapshot.final_register_t_complex_imag_value = fakeReal34Value((const real34_t *)(register_t_slot + sizeof(real34_t)));
  snapshot.final_register_t_complex_imag_bits = register_t_slot[sizeof(real34_t) + 15];
  snapshot.final_register_shortint_raw = *(uint64_t *)register_slot;
  snapshot.final_register_y_shortint_raw = shortint_y_slot;
  snapshot.final_register_z_shortint_raw = shortint_z_slot;
  snapshot.final_register_t_shortint_raw = shortint_t_slot;
  snapshot.final_register_longint_value = longint_input.value;
  snapshot.final_register_y_longint_value = longint_y_input.value;
  snapshot.final_register_z_longint_value = longint_z_input.value;
  snapshot.final_register_t_longint_value = longint_t_input.value;
  snapshot.final_real_matrix_rows = fake_real_matrix.header.matrixRows;
  snapshot.final_real_matrix_columns = fake_real_matrix.header.matrixColumns;
  snapshot.final_complex_matrix_rows = fake_complex_matrix.header.matrixRows;
  snapshot.final_complex_matrix_columns = fake_complex_matrix.header.matrixColumns;
  snapshot.final_overflow_flag = overflow_flag;
  snapshot.final_carry_flag = carry_flag;
  snapshot.final_pcg_state = pcg32_global.state;
  snapshot.final_pcg_inc = pcg32_global.inc;
  snapshot.final_there_is_something_to_undo = thereIsSomethingToUndo;
  snapshot.final_temporary_information = temporaryInformation;
  *out = snapshot;
}

bool_t saveLastX(void) {
  snapshot.save_last_x_calls++;
  return save_last_x_result;
}

uint32_t getRegisterDataType(calcRegister_t reg) {
  snapshot.get_register_data_type_calls++;
  if(reg == REGISTER_Y) {
    return current_register_y_data_type;
  }
  if(reg == REGISTER_Z) {
    return current_register_z_data_type;
  }
  if(reg == REGISTER_T) {
    return current_register_t_data_type;
  }
  return current_register_data_type;
}

uint32_t getRegisterTag(calcRegister_t reg) {
  snapshot.get_register_tag_calls++;
  if(reg == REGISTER_Y) {
    return current_register_y_tag;
  }
  if(reg == REGISTER_Z) {
    return current_register_z_tag;
  }
  if(reg == REGISTER_T) {
    return current_register_t_tag;
  }
  return current_register_tag;
}

void *getRegisterDataPointer(calcRegister_t reg) {
  snapshot.get_register_data_pointer_calls++;
  const uint32_t data_type = *registerDataTypeSlot(reg);

  if(data_type == dtShortInteger) {
    return shortIntegerSlot(reg);
  }
  if(data_type == dtReal34Matrix) {
    return reg == REGISTER_Y ? (void *)&fake_real_y_matrix : (void *)&fake_real_matrix;
  }
  if(data_type == dtComplex34Matrix) {
    return reg == REGISTER_Y ? (void *)&fake_complex_y_matrix : (void *)&fake_complex_matrix;
  }
  if(reg == REGISTER_Y) {
    return register_y_slot;
  }
  if(reg == REGISTER_Z) {
    return register_z_slot;
  }
  if(reg == REGISTER_T) {
    return register_t_slot;
  }
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
  if(func == NULL) {
    return;
  }

  if(current_register_data_type != dtReal34Matrix) {
    func();
    return;
  }

  real34Matrix_t matrix = fake_real_matrix;

  for(uint16_t i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns && i < 4; ++i) {
    const int32_t value = fakeReal34Value(&matrix.matrixElements[i]);
    const uint8_t bits = matrix.matrixElements[i].bytes[15] & 0x70;

    current_register_data_type = dtReal34;
    current_register_tag = amNone;
    setRegisterScalar(value, bits);
    setFakeReal(&real_input.value, value, bits);
    real_input.available = true;
    func();
    matrix.matrixElements[i] = *(real34_t *)register_slot;
  }

  fake_real_matrix = matrix;
  current_register_data_type = dtReal34Matrix;
  current_register_tag = amNone;
}

void elementwiseRemaReal(void (*func)(void)) {
  if(func == NULL) {
    return;
  }

  real34Matrix_t matrix = fake_real_y_matrix;
  real_t x_input;

  if(!getRegisterAsReal(REGISTER_X, &x_input)) {
    return;
  }

  for(uint16_t i = 0; i < matrix.header.matrixRows * matrix.header.matrixColumns && i < 4; ++i) {
    const int32_t x_value = fakeRealValue(&x_input);
    const uint8_t x_bits = x_input.bits & 0x70;
    const int32_t y_value = fakeReal34Value(&matrix.matrixElements[i]);
    const uint8_t y_bits = matrix.matrixElements[i].bytes[15] & 0x70;

    reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    setRegisterReal34(register_y_slot, y_value, y_bits);
    setFakeReal(&real_y_input.value, y_value, y_bits);
    real_y_input.available = true;
    setRegisterScalar(x_value, x_bits);
    setFakeReal(&real_input.value, x_value, x_bits);
    real_input.available = true;
    func();
    matrix.matrixElements[i] = *(real34_t *)register_slot;
  }

  fake_real_matrix = matrix;
  current_register_data_type = dtReal34Matrix;
  current_register_tag = amNone;
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
  if(current_register_data_type == dtReal34Matrix) {
    elementwiseRema(realf);
    return;
  }
  if(realf != NULL) {
    realf();
  }
  if(complexf != NULL) {
    complexf();
  }
}

void processRealComplexDyadicFunction(void (*realf)(void), void (*complexf)(void)) {
  snapshot.process_real_complex_dyadic_calls++;

  if(!saveLastX()) {
    return;
  }

  if(current_register_data_type == dtComplex34 || current_register_y_data_type == dtComplex34) {
    if(complexf != NULL) {
      complexf();
    }
  }
  else if(realf != NULL) {
    realf();
  }

  adjustResult(REGISTER_X, true, true, REGISTER_X, REGISTER_Y, -1);
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
  const uint32_t data_type = *registerDataTypeSlot(reg);

  if(data_type == dtTime) {
    if(!register_scalar_available) {
      return false;
    }
    setFakeReal(value, fakeRegisterScalarValue(), register_slot[15] & 0x70);
    return true;
  }
  if(data_type == dtShortInteger) {
    setFakeReal(value, (int32_t)decodeShortInteger(*shortIntegerSlot(reg), NULL), 0);
    return true;
  }
  if(data_type == dtLongInteger) {
    setFakeReal(value, reg == REGISTER_Y ? longint_y_input.value : reg == REGISTER_Z ? longint_z_input.value : reg == REGISTER_T ? longint_t_input.value : longint_input.value, 0);
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
  if(reg == REGISTER_T) {
    if(!real_t_input.available) {
      return false;
    }
    *value = real_t_input.value;
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
  if(*registerDataTypeSlot(reg) == dtComplex34) {
  const void *inputPtr = reg == REGISTER_Y ? (const void *)&complex_y_input : reg == REGISTER_Z ? (const void *)&complex_z_input : reg == REGISTER_T ? (const void *)&complex_t_input : (const void *)&complex_input;
  const typeof(complex_input) *input = inputPtr;

    snapshot.get_register_as_complex_real_value = fakeRealValue(&input->real);
    snapshot.get_register_as_complex_real_bits = input->real.bits;
    snapshot.get_register_as_complex_imag_value = fakeRealValue(&input->imag);
    snapshot.get_register_as_complex_imag_bits = input->imag.bits;

    if(!input->available) {
      return false;
    }

    *real = input->real;
    *imag = input->imag;
    return true;
  }

  if(!getRegisterAsReal(reg, real)) {
    return false;
  }

  setFakeReal(imag, 0, 0);
  snapshot.get_register_as_complex_real_value = fakeRealValue(real);
  snapshot.get_register_as_complex_real_bits = real->bits;
  snapshot.get_register_as_complex_imag_value = 0;
  snapshot.get_register_as_complex_imag_bits = 0;
  return true;
}

bool_t getRegisterAsShortInt(calcRegister_t reg, bool_t *sign, uint64_t *val, bool_t *overflow, bool_t *fractional) {
  if(*registerDataTypeSlot(reg) == dtShortInteger) {
    const uint64_t raw = *shortIntegerSlot(reg);
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
  const bool_t available = reg == REGISTER_Y ? longint_y_input.available : reg == REGISTER_Z ? longint_z_input.available : longint_input.available;
  const int32_t input_value = reg == REGISTER_Y ? longint_y_input.value : reg == REGISTER_Z ? longint_z_input.value : longint_input.value;

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

int getRegisterAsLongIntQuiet(calcRegister_t reg, longInteger_t val, bool_t *fractional) {
  int32_t value = 0;
  uint8_t error_code = ERROR_NONE;
  bool_t has_fractional = false;

  snapshot.get_register_as_longint_quiet_calls++;
  mpz_init(val);

  if(longint_quiet_result.enabled) {
    error_code = (uint8_t)longint_quiet_result.error_code;
    has_fractional = longint_quiet_result.fractional;
    value = longint_quiet_result.value;
    if(error_code == ERROR_NONE) {
      mpz_set_si(val, value);
    }
  }
  else {
    switch(current_register_data_type) {
      case dtLongInteger:
        value = reg == REGISTER_Y ? longint_y_input.value : reg == REGISTER_Z ? longint_z_input.value : longint_input.value;
        mpz_set_si(val, value);
        break;

      case dtShortInteger: {
        longInteger_t tmp;

        convertShortIntegerRegisterToLongInteger(reg, tmp);
        value = (int32_t)mpz_get_si(tmp);
        mpz_set(val, tmp);
        mpz_clear(tmp);
        break;
      }

      case dtComplex34:
      case dtReal34:
        if(realIsSpecial(&real_input.value)) {
          error_code = ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
        }
        else {
          value = fakeRealValue(&real_input.value);
          mpz_set_si(val, value);
        }
        break;

      default:
        error_code = ERROR_INVALID_DATA_TYPE_FOR_OP;
        break;
    }
  }

  snapshot.get_register_as_longint_quiet_error = error_code;
  snapshot.get_register_as_longint_quiet_fractional = has_fractional;
  snapshot.get_register_as_longint_quiet_value = value;

  if(fractional != NULL) {
    *fractional = has_fractional;
  }

  return error_code;
}

void convertLongIntegerRegisterToLongInteger(calcRegister_t reg, longInteger_t lgInt) {
  mpz_init(lgInt);
  mpz_set_si(lgInt, reg == REGISTER_Y ? longint_y_input.value : reg == REGISTER_Z ? longint_z_input.value : reg == REGISTER_T ? longint_t_input.value : longint_input.value);
}

void convertLongIntegerRegisterToReal(calcRegister_t reg, real_t *real, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(real, reg == REGISTER_Y ? longint_y_input.value : reg == REGISTER_Z ? longint_z_input.value : longint_input.value, 0);
}

void convertLongIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  const int32_t value = source == REGISTER_Y ? longint_y_input.value : source == REGISTER_Z ? longint_z_input.value : longint_input.value;

  if(destination == REGISTER_Y) {
    current_register_y_data_type = dtReal34;
    current_register_y_tag = amNone;
    real_y_input.available = true;
    setFakeReal(&real_y_input.value, value, 0);
    setRegisterReal34(register_y_slot, value, 0);
    return;
  }

  if(destination == REGISTER_Z) {
    current_register_z_data_type = dtReal34;
    current_register_z_tag = amNone;
    real_z_input.available = true;
    setFakeReal(&real_z_input.value, value, 0);
    setRegisterReal34(register_z_slot, value, 0);
    return;
  }

  current_register_data_type = dtReal34;
  current_register_tag = amNone;
  setRegisterScalar(value, 0);
}

void convertLongIntegerRegisterToTimeRegister(calcRegister_t source, calcRegister_t destination) {
  convertLongIntegerRegisterToReal34Register(source, destination);
  *registerDataTypeSlot(destination) = dtTime;
}

void convertLongIntegerToReal34(longInteger_t source, real34_t *destination) {
  setRegisterReal34((uint8_t *)destination, (int32_t)mpz_get_si(source), 0);
}

void convertLongIntegerToLongIntegerRegister(const longInteger_t lgInt, calcRegister_t reg) {
  const int32_t value = (int32_t)mpz_get_si(lgInt);

  snapshot.convert_long_integer_to_register_calls++;
  snapshot.convert_long_integer_to_register_value = value;
  snapshot.convert_long_integer_to_register_dest = reg;
  if(reg == REGISTER_Y) {
    longint_y_input.available = true;
    longint_y_input.value = value;
    current_register_y_data_type = dtLongInteger;
    current_register_y_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
    return;
  }
  if(reg == REGISTER_Z) {
    longint_z_input.available = true;
    longint_z_input.value = value;
    current_register_z_data_type = dtLongInteger;
    current_register_z_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
    return;
  }
  if(reg == REGISTER_T) {
    longint_t_input.available = true;
    longint_t_input.value = value;
    current_register_t_data_type = dtLongInteger;
    current_register_t_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
    return;
  }
  longint_input.available = true;
  longint_input.value = value;
  current_register_data_type = dtLongInteger;
  current_register_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

void convertUInt64ToShortIntegerRegister(int16_t sign, uint64_t value, uint32_t base, calcRegister_t reg) {
  *shortIntegerSlot(reg) = value | ((uint64_t)(sign != 0) << 63);
  *registerDataTypeSlot(reg) = dtShortInteger;
  *registerTagSlot(reg) = base;
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

void convertShortIntegerRegisterToReal(calcRegister_t source, real_t *destination, realContext_t *realContext) {
  (void)realContext;
  setFakeReal(destination, (int32_t)decodeShortInteger(*shortIntegerSlot(source), NULL), 0);
}

void convertShortIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  const int32_t value = (int32_t)decodeShortInteger(*shortIntegerSlot(source), NULL);

  *registerDataTypeSlot(destination) = dtReal34;
  *registerTagSlot(destination) = amNone;
  if(destination == REGISTER_Y) {
    real_y_input.available = true;
    setFakeReal(&real_y_input.value, value, 0);
    setRegisterReal34(register_y_slot, value, 0);
    return;
  }
  if(destination == REGISTER_Z) {
    real_z_input.available = true;
    setFakeReal(&real_z_input.value, value, 0);
    setRegisterReal34(register_z_slot, value, 0);
    return;
  }
  if(destination == REGISTER_T) {
    real_t_input.available = true;
    setFakeReal(&real_t_input.value, value, 0);
    setRegisterReal34(register_t_slot, value, 0);
    return;
  }
  real_input.available = true;
  setFakeReal(&real_input.value, value, 0);
  setRegisterScalar(value, 0);
  refreshXScalarMirror();
}

void convertShortIntegerRegisterToLongIntegerRegister(calcRegister_t source, calcRegister_t destination) {
  longInteger_t value;

  convertShortIntegerRegisterToLongInteger(source, value);
  convertLongIntegerToLongIntegerRegister(value, destination);
  longIntegerFree(value);
}

void convertLongIntegerToShortIntegerRegister(const longInteger_t longInteger, uint32_t base, calcRegister_t reg) {
  const int64_t value = mpz_get_si(longInteger);

  *shortIntegerSlot(reg) = encodeShortInteger(value);
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
  if(dest == REGISTER_Y) {
    longint_y_input.available = true;
    longint_y_input.value = value;
    return;
  }
  longint_input.available = true;
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
  if(dest == REGISTER_Y) {
    longint_y_input.available = true;
    longint_y_input.value = value;
    return;
  }
  longint_input.available = true;
  longint_input.value = value;
  current_register_data_type = dtLongInteger;
  current_register_tag = value < 0 ? LI_NEGATIVE : value > 0 ? LI_POSITIVE : LI_ZERO;
}

bool_t fraction(calcRegister_t regist, int16_t *sign, uint64_t *intPart, uint64_t *numer, uint64_t *denom, int16_t *lessEqualGreater) {
  (void)regist;
  if(sign != NULL) {
    *sign = fraction_result.sign;
  }
  if(intPart != NULL) {
    *intPart = fraction_result.int_part;
  }
  if(numer != NULL) {
    *numer = fraction_result.numer;
  }
  if(denom != NULL) {
    *denom = fraction_result.denom;
  }
  if(lessEqualGreater != NULL) {
    *lessEqualGreater = fraction_result.less_equal_greater;
  }
  return fraction_result.result;
}

void convertRealToResultRegister(const real_t *real, calcRegister_t reg, angularMode_t angleMode) {
  snapshot.convert_real_to_result_calls++;
  snapshot.convert_real_to_result_value = fakeRealValue(real);
  snapshot.convert_real_to_result_bits = real->bits;
  snapshot.convert_real_to_result_angle = angleMode;
  snapshot.convert_real_to_result_raw = *real;
  if(reg == REGISTER_Y) {
    current_register_y_data_type = dtReal34;
    current_register_y_tag = (uint32_t)angleMode;
    real_y_input.available = true;
    real_y_input.value = *real;
    setRegisterReal34(register_y_slot, fakeRealValue(real), real->bits & 0x70);
    return;
  }
  if(reg == REGISTER_Z) {
    current_register_z_data_type = dtReal34;
    current_register_z_tag = (uint32_t)angleMode;
    real_z_input.available = true;
    real_z_input.value = *real;
    setRegisterReal34(register_z_slot, fakeRealValue(real), real->bits & 0x70);
    return;
  }
  current_register_data_type = dtReal34;
  current_register_tag = (uint32_t)angleMode;
  setRegisterScalar(fakeRealValue(real), real->bits & 0x70);
}

void convertRealToReal34ResultRegister(const real_t *real, calcRegister_t dest) {
  snapshot.convert_real_to_real34_result_calls++;
  snapshot.convert_real_to_real34_result_dest = dest;
  snapshot.convert_real_to_real34_result_raw = *real;
  if(dest == REGISTER_Y) {
    current_register_y_data_type = dtReal34;
    current_register_y_tag = amNone;
    real_y_input.available = true;
    real_y_input.value = *real;
    setRegisterReal34(register_y_slot, fakeRealValue(real), real->bits & 0x70);
    return;
  }
  if(dest == REGISTER_Z) {
    current_register_z_data_type = dtReal34;
    current_register_z_tag = amNone;
    real_z_input.available = true;
    real_z_input.value = *real;
    setRegisterReal34(register_z_slot, fakeRealValue(real), real->bits & 0x70);
    return;
  }
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
  if(reg == REGISTER_Y) {
    current_register_y_data_type = dtComplex34;
    current_register_y_tag = amNone;
    complex_y_input.available = true;
    complex_y_input.real = *real;
    complex_y_input.imag = *imag;
    setRegisterReal34(register_y_slot, fakeRealValue(real), real->bits & 0x70);
    setRegisterReal34(register_y_slot + sizeof(real34_t), fakeRealValue(imag), imag->bits & 0x70);
    return;
  }
  if(reg == REGISTER_Z) {
    current_register_z_data_type = dtComplex34;
    current_register_z_tag = amNone;
    complex_z_input.available = true;
    complex_z_input.real = *real;
    complex_z_input.imag = *imag;
    setRegisterReal34(register_z_slot, fakeRealValue(real), real->bits & 0x70);
    setRegisterReal34(register_z_slot + sizeof(real34_t), fakeRealValue(imag), imag->bits & 0x70);
    return;
  }
  complex_input.available = true;
  complex_input.real = *real;
  complex_input.imag = *imag;
  current_register_data_type = dtComplex34;
  current_register_tag = amNone;
  setRegisterReal34(register_slot, fakeRealValue(real), real->bits & 0x70);
  setRegisterReal34(register_slot + sizeof(real34_t), fakeRealValue(imag), imag->bits & 0x70);
}

void linkToComplexMatrixRegister(calcRegister_t reg, complex34Matrix_t *matrix) {
  *matrix = reg == REGISTER_Y ? fake_complex_y_matrix : fake_complex_matrix;
}

void linkToRealMatrixRegister(calcRegister_t reg, real34Matrix_t *matrix) {
  *matrix = reg == REGISTER_Y ? fake_real_y_matrix : fake_real_matrix;
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
  if(reg == REGISTER_Y) {
    fake_real_y_matrix = *matrix;
    current_register_y_data_type = dtReal34Matrix;
    current_register_y_tag = amNone;
    return;
  }

  fake_real_matrix = *matrix;
  current_register_data_type = dtReal34Matrix;
  current_register_tag = amNone;
}

void convertComplex34MatrixToComplex34MatrixRegister(const complex34Matrix_t *matrix, calcRegister_t reg) {
  if(reg == REGISTER_Y) {
    fake_complex_y_matrix = *matrix;
    current_register_y_data_type = dtComplex34Matrix;
    current_register_y_tag = amNone;
    return;
  }

  fake_complex_matrix = *matrix;
  current_register_data_type = dtComplex34Matrix;
  current_register_tag = amNone;
}

void convertReal34MatrixRegisterToReal34Matrix(calcRegister_t reg, real34Matrix_t *matrix) {
  *matrix = reg == REGISTER_Y ? fake_real_y_matrix : fake_real_matrix;
}

void convertComplex34MatrixRegisterToComplex34Matrix(calcRegister_t reg, complex34Matrix_t *matrix) {
  *matrix = reg == REGISTER_Y ? fake_complex_y_matrix : fake_complex_matrix;
}

void convertReal34MatrixRegisterToComplex34Matrix(calcRegister_t reg, complex34Matrix_t *matrix) {
  const real34Matrix_t *source = reg == REGISTER_Y ? &fake_real_y_matrix : &fake_real_matrix;

  matrix->header = source->header;
  for(uint16_t i = 0; i < matrix->header.matrixRows * matrix->header.matrixColumns && i < 4; ++i) {
    matrix->matrixElements[i].real = source->matrixElements[i];
    setRegisterReal34((uint8_t *)&matrix->matrixElements[i].imag, 0, 0);
  }
}

void convertReal34MatrixRegisterToComplex34MatrixRegister(calcRegister_t source, calcRegister_t destination) {
  complex34Matrix_t matrix;

  convertReal34MatrixRegisterToComplex34Matrix(source, &matrix);
  convertComplex34MatrixToComplex34MatrixRegister(&matrix, destination);
}

void convertReal34MatrixToComplex34Matrix(const real34Matrix_t *realMatrix, complex34Matrix_t *complexMatrix) {
  complexMatrix->header = realMatrix->header;
  for(uint16_t i = 0; i < complexMatrix->header.matrixRows * complexMatrix->header.matrixColumns && i < 4; ++i) {
    complexMatrix->matrixElements[i].real = realMatrix->matrixElements[i];
    setRegisterReal34((uint8_t *)&complexMatrix->matrixElements[i].imag, 0, 0);
  }
}

void elementwiseRealRema(void (*func)(void)) {
  real34Matrix_t matrix;
  real_t y_input_value;
  real34_t y_value;

  if(func == NULL || !getRegisterAsReal(REGISTER_Y, &y_input_value)) {
    return;
  }

  realToReal34(&y_input_value, &y_value);
  convertReal34MatrixRegisterToReal34Matrix(REGISTER_X, &matrix);

  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix.header.matrixRows, matrix.header.matrixColumns); ++i) {
    reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    real34Copy(&y_value, REGISTER_REAL34_DATA(REGISTER_Y));
    real34Copy(&matrix.matrixElements[i], REGISTER_REAL34_DATA(REGISTER_X));
    real_y_input.available = true;
    setFakeReal(&real_y_input.value, fakeReal34Value(&y_value), y_value.bytes[15] & 0x70);
    real_input.available = true;
    setFakeReal(&real_input.value, fakeReal34Value(&matrix.matrixElements[i]), matrix.matrixElements[i].bytes[15] & 0x70);
    func();
    matrix.matrixElements[i] = *REGISTER_REAL34_DATA(REGISTER_X);
  }

  convertReal34MatrixToReal34MatrixRegister(&matrix, REGISTER_X);
}

void elementwiseCxmaReal(void (*func)(void)) {
  complex34Matrix_t matrix;
  real_t x_input_value;
  real34_t x_value;

  if(func == NULL || !getRegisterAsReal(REGISTER_X, &x_input_value)) {
    return;
  }

  realToReal34(&x_input_value, &x_value);
  convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_Y, &matrix);

  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix.header.matrixRows, matrix.header.matrixColumns); ++i) {
    reallocateRegister(REGISTER_Y, dtComplex34, 0, amNone);
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    complex34Copy(&matrix.matrixElements[i], REGISTER_COMPLEX34_DATA(REGISTER_Y));
    real34Copy(&x_value, REGISTER_REAL34_DATA(REGISTER_X));
    complex_y_input.available = true;
    complex34ToRealPair(&matrix.matrixElements[i], &complex_y_input.real, &complex_y_input.imag);
    real_input.available = true;
    setFakeReal(&real_input.value, fakeReal34Value(&x_value), x_value.bytes[15] & 0x70);
    func();
    matrix.matrixElements[i] = *REGISTER_COMPLEX34_DATA(REGISTER_X);
  }

  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
}

void elementwiseRealCxma(void (*func)(void)) {
  complex34Matrix_t matrix;
  real_t y_input_value;
  real34_t y_value;

  if(func == NULL || !getRegisterAsReal(REGISTER_Y, &y_input_value)) {
    return;
  }

  realToReal34(&y_input_value, &y_value);
  convertComplex34MatrixRegisterToComplex34Matrix(REGISTER_X, &matrix);

  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix.header.matrixRows, matrix.header.matrixColumns); ++i) {
    reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
    real34Copy(&y_value, REGISTER_REAL34_DATA(REGISTER_Y));
    complex34Copy(&matrix.matrixElements[i], REGISTER_COMPLEX34_DATA(REGISTER_X));
    real_y_input.available = true;
    setFakeReal(&real_y_input.value, fakeReal34Value(&y_value), y_value.bytes[15] & 0x70);
    complex_input.available = true;
    complex34ToRealPair(&matrix.matrixElements[i], &complex_input.real, &complex_input.imag);
    func();
    matrix.matrixElements[i] = *REGISTER_COMPLEX34_DATA(REGISTER_X);
  }

  convertComplex34MatrixToComplex34MatrixRegister(&matrix, REGISTER_X);
}

static void multiplyComplexScalars(const complex34_t *lhs, const complex34_t *rhs, complex34_t *res, realContext_t *realContext) {
  real_t lhs_real;
  real_t lhs_imag;
  real_t rhs_real;
  real_t rhs_imag;
  real_t prod_real;
  real_t prod_imag;

  complex34ToRealPair(lhs, &lhs_real, &lhs_imag);
  complex34ToRealPair(rhs, &rhs_real, &rhs_imag);
  mulComplexComplex(&lhs_real, &lhs_imag, &rhs_real, &rhs_imag, &prod_real, &prod_imag, realContext);
  realPairToComplex34(&prod_real, &prod_imag, res);
}

static void divideComplexScalars(const complex34_t *lhs, const complex34_t *rhs, complex34_t *res, realContext_t *realContext) {
  real_t lhs_real;
  real_t lhs_imag;
  real_t rhs_real;
  real_t rhs_imag;
  real_t quot_real;
  real_t quot_imag;

  complex34ToRealPair(lhs, &lhs_real, &lhs_imag);
  complex34ToRealPair(rhs, &rhs_real, &rhs_imag);
  divComplexComplex(&lhs_real, &lhs_imag, &rhs_real, &rhs_imag, &quot_real, &quot_imag, realContext);
  realPairToComplex34(&quot_real, &quot_imag, res);
}

static void negateComplex34(const complex34_t *value, complex34_t *res) {
  *res = *value;
  real34ChangeSign(&res->real);
  real34ChangeSign(&res->imag);
}

uint32_t getInfiniteComplexAngle(real_t *x, real_t *y) {
  if(!realIsInfinite(x)) {
    return 2 + 4 * realIsNegative(y);
  }
  if(!realIsInfinite(y)) {
    return 4 * realIsNegative(x);
  }
  if(realIsPositive(x)) {
    return 1 + 6 * realIsNegative(y);
  }
  return 3 + 2 * realIsNegative(y);
}

void setInfiniteComplexAngle(uint32_t angle, real_t *x, real_t *y) {
  switch(angle) {
    case 3:
    case 4:
    case 5:
      realSetMinusInfinity(x);
      break;
    case 2:
    case 6:
      realSetZero(x);
      break;
    default:
      realSetPlusInfinity(x);
      break;
  }

  switch(angle) {
    case 5:
    case 6:
    case 7:
      realSetMinusInfinity(y);
      break;
    case 0:
    case 4:
      realSetZero(y);
      break;
    default:
      realSetPlusInfinity(y);
      break;
  }
}

void addRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res) {
  real34Matrix_t out;

  if(!realMatrixShapesMatch(y, x)) {
    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  realMatrixInit(&out, y->header.matrixRows, y->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(y->header.matrixRows, y->header.matrixColumns); ++i) {
    real34Add(&y->matrixElements[i], &x->matrixElements[i], &out.matrixElements[i]);
  }
  *res = out;
}

void subtractRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res) {
  real34Matrix_t out;

  if(!realMatrixShapesMatch(y, x)) {
    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  realMatrixInit(&out, y->header.matrixRows, y->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(y->header.matrixRows, y->header.matrixColumns); ++i) {
    real34Subtract(&y->matrixElements[i], &x->matrixElements[i], &out.matrixElements[i]);
  }
  *res = out;
}

void addComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res) {
  complex34Matrix_t out;

  if(!complexMatrixShapesMatch(y, x)) {
    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  complexMatrixInit(&out, y->header.matrixRows, y->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(y->header.matrixRows, y->header.matrixColumns); ++i) {
    real34Add(&y->matrixElements[i].real, &x->matrixElements[i].real, &out.matrixElements[i].real);
    real34Add(&y->matrixElements[i].imag, &x->matrixElements[i].imag, &out.matrixElements[i].imag);
  }
  *res = out;
}

void subtractComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res) {
  complex34Matrix_t out;

  if(!complexMatrixShapesMatch(y, x)) {
    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  complexMatrixInit(&out, y->header.matrixRows, y->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(y->header.matrixRows, y->header.matrixColumns); ++i) {
    real34Subtract(&y->matrixElements[i].real, &x->matrixElements[i].real, &out.matrixElements[i].real);
    real34Subtract(&y->matrixElements[i].imag, &x->matrixElements[i].imag, &out.matrixElements[i].imag);
  }
  *res = out;
}

void multiplyRealMatrix(const real34Matrix_t *matrix, const real34_t *x, real34Matrix_t *res) {
  real34Matrix_t out;

  realMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    real34Multiply(&matrix->matrixElements[i], x, &out.matrixElements[i]);
  }
  *res = out;
}

void _multiplyRealMatrix(const real34Matrix_t *matrix, const real_t *x, real34Matrix_t *res, realContext_t *realContext) {
  real34Matrix_t out;

  realMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    real_t value;

    real34ToRealPair(&matrix->matrixElements[i], &value);
    realMultiply(&value, x, &value, realContext);
    realToReal34(&value, &out.matrixElements[i]);
  }
  *res = out;
}

void multiplyRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res) {
  real34Matrix_t out;

  if(y->header.matrixColumns != x->header.matrixRows) {
    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  realMatrixInit(&out, y->header.matrixRows, x->header.matrixColumns);
  for(uint16_t row = 0; row < y->header.matrixRows; ++row) {
    for(uint16_t col = 0; col < x->header.matrixColumns; ++col) {
      real_t sum;

      realSetZero(&sum);
      for(uint16_t iter = 0; iter < y->header.matrixColumns; ++iter) {
        real_t lhs;
        real_t rhs;
        real_t prod;

        real34ToRealPair(&y->matrixElements[matrixIndex(row, iter, y->header.matrixColumns)], &lhs);
        real34ToRealPair(&x->matrixElements[matrixIndex(iter, col, x->header.matrixColumns)], &rhs);
        realMultiply(&lhs, &rhs, &prod, &ctxtReal39);
        realAdd(&sum, &prod, &sum, &ctxtReal39);
      }
      realToReal34(&sum, &out.matrixElements[matrixIndex(row, col, x->header.matrixColumns)]);
    }
  }
  *res = out;
}

void multiplyComplexMatrix(const complex34Matrix_t *matrix, const real34_t *xr, const real34_t *xi, complex34Matrix_t *res) {
  real_t xr_real;
  real_t xi_real;

  real34ToRealPair(xr, &xr_real);
  real34ToRealPair(xi, &xi_real);
  _multiplyComplexMatrix(matrix, &xr_real, &xi_real, res, &ctxtReal39);
}

void _multiplyComplexMatrix(const complex34Matrix_t *matrix, const real_t *xr, const real_t *xi, complex34Matrix_t *res, realContext_t *realContext) {
  complex34Matrix_t out;
  complex34_t rhs;

  realToReal34(xr, &rhs.real);
  realToReal34(xi, &rhs.imag);
  complexMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    multiplyComplexScalars(&matrix->matrixElements[i], &rhs, &out.matrixElements[i], realContext);
  }
  *res = out;
}

void multiplyComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res) {
  complex34Matrix_t out;

  if(y->header.matrixColumns != x->header.matrixRows) {
    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  complexMatrixInit(&out, y->header.matrixRows, x->header.matrixColumns);
  for(uint16_t row = 0; row < y->header.matrixRows; ++row) {
    for(uint16_t col = 0; col < x->header.matrixColumns; ++col) {
      real_t sum_real;
      real_t sum_imag;

      realSetZero(&sum_real);
      realSetZero(&sum_imag);
      for(uint16_t iter = 0; iter < y->header.matrixColumns; ++iter) {
        real_t lhs_real;
        real_t lhs_imag;
        real_t rhs_real;
        real_t rhs_imag;
        real_t prod_real;
        real_t prod_imag;

        complex34ToRealPair(&y->matrixElements[matrixIndex(row, iter, y->header.matrixColumns)], &lhs_real, &lhs_imag);
        complex34ToRealPair(&x->matrixElements[matrixIndex(iter, col, x->header.matrixColumns)], &rhs_real, &rhs_imag);
        mulComplexComplex(&lhs_real, &lhs_imag, &rhs_real, &rhs_imag, &prod_real, &prod_imag, &ctxtReal39);
        realAdd(&sum_real, &prod_real, &sum_real, &ctxtReal39);
        realAdd(&sum_imag, &prod_imag, &sum_imag, &ctxtReal39);
      }
      realPairToComplex34(&sum_real, &sum_imag, &out.matrixElements[matrixIndex(row, col, x->header.matrixColumns)]);
    }
  }
  *res = out;
}

void divideRealMatrix(const real34Matrix_t *matrix, const real34_t *x, real34Matrix_t *res) {
  real34Matrix_t out;

  realMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    real34Divide(&matrix->matrixElements[i], x, &out.matrixElements[i]);
  }
  *res = out;
}

void divideByRealMatrix(const real34_t *y, const real34Matrix_t *matrix, real34Matrix_t *res) {
  real34Matrix_t out;

  realMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    real34Divide(y, &matrix->matrixElements[i], &out.matrixElements[i]);
  }
  *res = out;
}

void _divideRealMatrix(const real34Matrix_t *matrix, const real_t *x, real34Matrix_t *res, realContext_t *realContext) {
  real34Matrix_t out;

  realMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    real_t value;

    real34ToRealPair(&matrix->matrixElements[i], &value);
    realDivide(&value, x, &value, realContext);
    realToReal34(&value, &out.matrixElements[i]);
  }
  *res = out;
}

void _divideByRealMatrix(const real_t *y, const real34Matrix_t *matrix, real34Matrix_t *res, realContext_t *realContext) {
  real34Matrix_t out;

  realMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    real_t x;

    real34ToRealPair(&matrix->matrixElements[i], &x);
    realDivide(y, &x, &x, realContext);
    realToReal34(&x, &out.matrixElements[i]);
  }
  *res = out;
}

static bool_t invertRealMatrix(const real34Matrix_t *matrix, real34Matrix_t *inverse) {
  if(matrix->header.matrixRows != matrix->header.matrixColumns) {
    return false;
  }

  if(matrix->header.matrixRows == 1) {
    real34_t one;

    realMatrixInit(inverse, 1, 1);
    setRegisterReal34((uint8_t *)&one, 1, 0);
    real34Divide(&one, &matrix->matrixElements[0], &inverse->matrixElements[0]);
    return true;
  }

  if(matrix->header.matrixRows != 2) {
    return false;
  }

  {
    real_t a;
    real_t b;
    real_t c;
    real_t d;
    real_t ad;
    real_t bc;
    real_t det;
    real_t inv_real;

    real34ToRealPair(&matrix->matrixElements[0], &a);
    real34ToRealPair(&matrix->matrixElements[1], &b);
    real34ToRealPair(&matrix->matrixElements[2], &c);
    real34ToRealPair(&matrix->matrixElements[3], &d);
    realMultiply(&a, &d, &ad, &ctxtReal39);
    realMultiply(&b, &c, &bc, &ctxtReal39);
    realSubtract(&ad, &bc, &det, &ctxtReal39);
    if(realIsZeroLike(&det)) {
      return false;
    }

    realMatrixInit(inverse, 2, 2);
    realDivide(&d, &det, &inv_real, &ctxtReal39);
    realToReal34(&inv_real, &inverse->matrixElements[0]);
    realChangeSign(&b);
    realDivide(&b, &det, &inv_real, &ctxtReal39);
    realToReal34(&inv_real, &inverse->matrixElements[1]);
    realChangeSign(&c);
    realDivide(&c, &det, &inv_real, &ctxtReal39);
    realToReal34(&inv_real, &inverse->matrixElements[2]);
    real34ToRealPair(&matrix->matrixElements[0], &a);
    realDivide(&a, &det, &inv_real, &ctxtReal39);
    realToReal34(&inv_real, &inverse->matrixElements[3]);
  }

  return true;
}

void divideRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res) {
  real34Matrix_t inverse;

  if(y->header.matrixColumns != x->header.matrixRows || !invertRealMatrix(x, &inverse)) {
    real34Matrix_t out;

    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  multiplyRealMatrices(y, &inverse, res);
}

void divideComplexMatrix(const complex34Matrix_t *matrix, const real34_t *xr, const real34_t *xi, complex34Matrix_t *res) {
  real_t xr_real;
  real_t xi_real;

  real34ToRealPair(xr, &xr_real);
  real34ToRealPair(xi, &xi_real);
  _divideComplexMatrix(matrix, &xr_real, &xi_real, res, &ctxtReal39);
}

void divideByComplexMatrix(const real34_t *yr, const real34_t *yi, const complex34Matrix_t *matrix, complex34Matrix_t *res) {
  real_t yr_real;
  real_t yi_real;

  real34ToRealPair(yr, &yr_real);
  real34ToRealPair(yi, &yi_real);
  _divideByComplexMatrix(&yr_real, &yi_real, matrix, res, &ctxtReal39);
}

void _divideComplexMatrix(const complex34Matrix_t *matrix, const real_t *xr, const real_t *xi, complex34Matrix_t *res, realContext_t *realContext) {
  complex34Matrix_t out;
  complex34_t rhs;

  realToReal34(xr, &rhs.real);
  realToReal34(xi, &rhs.imag);
  complexMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    divideComplexScalars(&matrix->matrixElements[i], &rhs, &out.matrixElements[i], realContext);
  }
  *res = out;
}

void _divideByComplexMatrix(const real_t *yr, const real_t *yi, const complex34Matrix_t *matrix, complex34Matrix_t *res, realContext_t *realContext) {
  complex34Matrix_t out;
  complex34_t lhs;

  realToReal34(yr, &lhs.real);
  realToReal34(yi, &lhs.imag);
  complexMatrixInit(&out, matrix->header.matrixRows, matrix->header.matrixColumns);
  for(uint16_t i = 0; i < cappedMatrixElementCount(matrix->header.matrixRows, matrix->header.matrixColumns); ++i) {
    divideComplexScalars(&lhs, &matrix->matrixElements[i], &out.matrixElements[i], realContext);
  }
  *res = out;
}

static bool_t invertComplexMatrix(const complex34Matrix_t *matrix, complex34Matrix_t *inverse) {
  if(matrix->header.matrixRows != matrix->header.matrixColumns) {
    return false;
  }

  if(matrix->header.matrixRows == 1) {
    complex34_t one;

    complexMatrixInit(inverse, 1, 1);
    setRegisterReal34((uint8_t *)&one.real, 1, 0);
    setRegisterReal34((uint8_t *)&one.imag, 0, 0);
    divideComplexScalars(&one, &matrix->matrixElements[0], &inverse->matrixElements[0], &ctxtReal39);
    return true;
  }

  if(matrix->header.matrixRows != 2) {
    return false;
  }

  {
    real_t a_real;
    real_t a_imag;
    real_t b_real;
    real_t b_imag;
    real_t c_real;
    real_t c_imag;
    real_t d_real;
    real_t d_imag;
    real_t ad_real;
    real_t ad_imag;
    real_t bc_real;
    real_t bc_imag;
    real_t det_real;
    real_t det_imag;
    real_t inv_real;
    real_t inv_imag;
    complex34_t term;

    complex34ToRealPair(&matrix->matrixElements[0], &a_real, &a_imag);
    complex34ToRealPair(&matrix->matrixElements[1], &b_real, &b_imag);
    complex34ToRealPair(&matrix->matrixElements[2], &c_real, &c_imag);
    complex34ToRealPair(&matrix->matrixElements[3], &d_real, &d_imag);
    mulComplexComplex(&a_real, &a_imag, &d_real, &d_imag, &ad_real, &ad_imag, &ctxtReal39);
    mulComplexComplex(&b_real, &b_imag, &c_real, &c_imag, &bc_real, &bc_imag, &ctxtReal39);
    subtractComplexValues(&ad_real, &ad_imag, &bc_real, &bc_imag, &det_real, &det_imag, &ctxtReal39);
    if(complexIsZeroLike(&det_real, &det_imag)) {
      return false;
    }

    complexMatrixInit(inverse, 2, 2);

    realToReal34(&det_real, &term.real);
    realToReal34(&det_imag, &term.imag);

    divComplexComplex(&d_real, &d_imag, &det_real, &det_imag, &inv_real, &inv_imag, &ctxtReal39);
    realPairToComplex34(&inv_real, &inv_imag, &inverse->matrixElements[0]);

    {
      complex34_t neg_b;

      negateComplex34(&matrix->matrixElements[1], &neg_b);
      divideComplexScalars(&neg_b, &term, &inverse->matrixElements[1], &ctxtReal39);
    }
    {
      complex34_t neg_c;

      negateComplex34(&matrix->matrixElements[2], &neg_c);
      divideComplexScalars(&neg_c, &term, &inverse->matrixElements[2], &ctxtReal39);
    }
    divideComplexScalars(&matrix->matrixElements[0], &term, &inverse->matrixElements[3], &ctxtReal39);
  }

  return true;
}

void divideComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res) {
  complex34Matrix_t inverse;

  if(y->header.matrixColumns != x->header.matrixRows || !invertComplexMatrix(x, &inverse)) {
    complex34Matrix_t out;

    out.header.matrixRows = 0;
    out.header.matrixColumns = 0;
    *res = out;
    matrixMismatch();
    return;
  }

  multiplyComplexMatrices(y, &inverse, res);
}

uint16_t realVectorSize(const real34Matrix_t *matrix) {
  if(matrix->header.matrixRows == 1) {
    return matrix->header.matrixColumns;
  }
  if(matrix->header.matrixColumns == 1) {
    return matrix->header.matrixRows;
  }
  return 0;
}

static int32_t fakeReal34VectorValue(const real34Matrix_t *matrix, uint16_t index) {
  if(index >= 4) {
    return 0;
  }
  return fakeReal34Value(&matrix->matrixElements[index]);
}

static void setFakeReal34VectorValue(real34Matrix_t *matrix, uint16_t index, int32_t value) {
  if(index < 4) {
    setRegisterReal34((uint8_t *)&matrix->matrixElements[index], value, 0);
  }
}

void dotRealVectors(const real34Matrix_t *y, const real34Matrix_t *x, real34_t *res) {
  const uint16_t count = realVectorSize(y);
  int32_t sum = 0;

  for(uint16_t i = 0; i < count && i < 4; ++i) {
    sum += fakeReal34VectorValue(y, i) * fakeReal34VectorValue(x, i);
  }

  setRegisterReal34((uint8_t *)res, sum, 0);
}

void crossRealVectors(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res) {
  const uint16_t count = realVectorSize(y);
  const int32_t y0 = fakeReal34VectorValue(y, 0);
  const int32_t y1 = fakeReal34VectorValue(y, 1);
  const int32_t y2 = count > 2 ? fakeReal34VectorValue(y, 2) : 0;
  const int32_t x0 = fakeReal34VectorValue(x, 0);
  const int32_t x1 = fakeReal34VectorValue(x, 1);
  const int32_t x2 = count > 2 ? fakeReal34VectorValue(x, 2) : 0;

  res->header = x->header;
  setFakeReal34VectorValue(res, 0, y1 * x2 - y2 * x1);
  setFakeReal34VectorValue(res, 1, y2 * x0 - y0 * x2);
  setFakeReal34VectorValue(res, 2, y0 * x1 - y1 * x0);
}

uint16_t complexVectorSize(const complex34Matrix_t *matrix) {
  return realVectorSize((const real34Matrix_t *)matrix);
}

static int32_t fakeComplexRealValue(const complex34Matrix_t *matrix, uint16_t index) {
  if(index >= 4) {
    return 0;
  }
  return fakeReal34Value(&matrix->matrixElements[index].real);
}

static int32_t fakeComplexImagValue(const complex34Matrix_t *matrix, uint16_t index) {
  if(index >= 4) {
    return 0;
  }
  return fakeReal34Value(&matrix->matrixElements[index].imag);
}

void dotComplexVectors(const complex34Matrix_t *y, const complex34Matrix_t *x, real34_t *res_r, real34_t *res_i) {
  const uint16_t count = complexVectorSize(y);
  int32_t sum_real = 0;
  int32_t sum_imag = 0;

  for(uint16_t i = 0; i < count && i < 4; ++i) {
    const int32_t y_real = fakeComplexRealValue(y, i);
    const int32_t y_imag = fakeComplexImagValue(y, i);
    const int32_t x_real = fakeComplexRealValue(x, i);
    const int32_t x_imag = fakeComplexImagValue(x, i);

    sum_real += y_real * x_real - y_imag * x_imag;
    sum_imag += y_real * x_imag + y_imag * x_real;
  }

  setRegisterReal34((uint8_t *)res_r, sum_real, 0);
  setRegisterReal34((uint8_t *)res_i, sum_imag, 0);
}

void crossComplexVectors(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res) {
  const uint16_t count = complexVectorSize(y);
  const int32_t y0r = fakeComplexRealValue(y, 0);
  const int32_t y0i = fakeComplexImagValue(y, 0);
  const int32_t y1r = fakeComplexRealValue(y, 1);
  const int32_t y1i = fakeComplexImagValue(y, 1);
  const int32_t y2r = count > 2 ? fakeComplexRealValue(y, 2) : 0;
  const int32_t y2i = count > 2 ? fakeComplexImagValue(y, 2) : 0;
  const int32_t x0r = fakeComplexRealValue(x, 0);
  const int32_t x0i = fakeComplexImagValue(x, 0);
  const int32_t x1r = fakeComplexRealValue(x, 1);
  const int32_t x1i = fakeComplexImagValue(x, 1);
  const int32_t x2r = count > 2 ? fakeComplexRealValue(x, 2) : 0;
  const int32_t x2i = count > 2 ? fakeComplexImagValue(x, 2) : 0;

  res->header = x->header;
  setRegisterReal34((uint8_t *)&res->matrixElements[0].real, y1r * x2r - y2r * x1r, 0);
  setRegisterReal34((uint8_t *)&res->matrixElements[0].imag, y1i * x2i - y2i * x1i, 0);
  setRegisterReal34((uint8_t *)&res->matrixElements[1].real, y2r * x0r - y0r * x2r, 0);
  setRegisterReal34((uint8_t *)&res->matrixElements[1].imag, y2i * x0i - y0i * x2i, 0);
  setRegisterReal34((uint8_t *)&res->matrixElements[2].real, y0r * x1r - y1r * x0r, 0);
  setRegisterReal34((uint8_t *)&res->matrixElements[2].imag, y0i * x1i - y1i * x0i, 0);
}

void setRegisterTag(calcRegister_t reg, uint32_t tag) {
  if(reg == REGISTER_Y) {
    current_register_y_tag = tag;
    return;
  }

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

void realPower(const real_t *base, const real_t *exponent, real_t *result, realContext_t *realContext) {
  const int32_t base_value = fakeRealValue(base);
  const int32_t exponent_value = fakeRealValue(exponent);
  int32_t power = 1;

  (void)realContext;

  if(exponent_value == 0) {
    setFakeReal(result, 1, 0);
    return;
  }

  if(exponent_value == 1) {
    *result = *base;
    return;
  }

  if(exponent_value > 1 && exponent_value <= 8) {
    for(int32_t i = 0; i < exponent_value; ++i) {
      power *= base_value;
    }
    setFakeReal(result, power, 0);
    return;
  }

  setFakeReal(result, base_value + exponent_value, 0);
}

void PowerReal(const real_t *base, const real_t *exponent, real_t *result, realContext_t *realContext) {
  if(exponent == z47_math_wrappers_const_1on3()) {
    int32_t magnitude = fakeRealValue(base);
    int32_t root = 0;

    (void)realContext;
    if(magnitude < 0) {
      magnitude = -magnitude;
    }
    while((root + 1) * (root + 1) * (root + 1) <= magnitude) {
      root++;
    }
    setFakeReal(result, root, 0);
    return;
  }

  realPower(base, exponent, result, realContext);
}

uint8_t PowerComplex(const real_t *base_real,
                     const real_t *base_imag,
                     const real_t *exponent_real,
                     const real_t *exponent_imag,
                     real_t *result_real,
                     real_t *result_imag,
                     realContext_t *realContext) {
  (void)realContext;
  setFakeReal(result_real, fakeRealValue(base_real) + fakeRealValue(exponent_real) + 84, 0);
  setFakeReal(result_imag, fakeRealValue(base_imag) + fakeRealValue(exponent_imag) + 85, 0);
  return ERROR_NONE;
}

int32_t realToInt32C47(const real_t *source, bool_t *error) {
  if(error != NULL) {
    *error = false;
  }
  return fakeRealValue(source);
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

static int32_t fakeAbsInt32(int32_t value) {
  return value < 0 ? -value : value;
}

void convergenceTolerence(real_t *tol) {
  setFakeReal(tol, 1, 0);
}

bool_t WP34S_AbsoluteError(const real_t *x, const real_t *y, const real_t *tol, realContext_t *realContext) {
  (void)realContext;
  return fakeAbsInt32(fakeRealValue(x) - fakeRealValue(y)) <= fakeAbsInt32(fakeRealValue(tol));
}

bool_t WP34S_RelativeError(const real_t *x, const real_t *y, const real_t *tol, realContext_t *realContext) {
  const int32_t scale = fakeAbsInt32(fakeRealValue(y)) > 0 ? fakeAbsInt32(fakeRealValue(y)) : 1;

  (void)realContext;
  return fakeAbsInt32(fakeRealValue(x) - fakeRealValue(y)) * 10 <= scale * fakeAbsInt32(fakeRealValue(tol));
}

bool_t WP34S_ComplexAbsError(const real_t *xReal,
                             const real_t *xImag,
                             const real_t *yReal,
                             const real_t *yImag,
                             const real_t *tol,
                             realContext_t *realContext) {
  return WP34S_AbsoluteError(xReal, yReal, tol, realContext) &&
         WP34S_AbsoluteError(xImag, yImag, tol, realContext);
}

bool_t WP34S_ComplexRelativeError(const real_t *xReal,
                                  const real_t *xImag,
                                  const real_t *yReal,
                                  const real_t *yImag,
                                  const real_t *tol,
                                  realContext_t *realContext) {
  return WP34S_RelativeError(xReal, yReal, tol, realContext) &&
         WP34S_RelativeError(xImag, yImag, tol, realContext);
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

uint64_t WP34S_intDivide(uint64_t y, uint64_t x) {
  int32_t sign_y;
  int32_t sign_x;
  const uint64_t dividend = WP34S_extract_value(y, &sign_y);
  const uint64_t divisor = WP34S_extract_value(x, &sign_x);
  const uint64_t quotient = divisor == 0 ? 0 : dividend / divisor;

  if(divisor == 0) {
	 displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    return 0;
  }

  clearSystemFlag(FLAG_OVERFLOW);
  if(quotient * divisor != dividend) {
    setSystemFlag(FLAG_CARRY);
  }
  else {
    clearSystemFlag(FLAG_CARRY);
  }

  if(shortIntegerMode == SIM_UNSIGN) {
    return quotient & shortIntegerMask;
  }

  return (uint64_t)WP34S_build_value(quotient & ~shortIntegerSignBit, sign_y ^ sign_x);
}

uint64_t WP34S_intSqrt(uint64_t x) {
  int32_t signValue;
  const uint64_t value = WP34S_extract_value(x, &signValue);
  uint64_t nn0;
  uint64_t nn1;

  if(signValue) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    moreInfoOnError("In function WP34S_intSqrt:", "Cannot extract the square root of a negative short integer!", NULL, NULL);
    return 0;
  }

  if(value == 0) {
    clearSystemFlag(FLAG_CARRY);
    return WP34S_build_value(0, signValue);
  }

  nn0 = value / 2 + 1;
  nn1 = value / nn0 + nn0 / 2;
  while(nn1 < nn0) {
    nn0 = nn1;
    nn1 = (nn0 + value / nn0) / 2;
  }

  nn0 = nn1 * nn1;
  if(nn0 > value) {
    nn1--;
    nn0 = nn1 * nn1;
  }

  if(nn0 != value) {
    setSystemFlag(FLAG_CARRY);
  }
  else {
    clearSystemFlag(FLAG_CARRY);
  }

  return WP34S_build_value(nn1, signValue);
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
  if(flag == FLAG_CARRY) {
    return carry_flag;
  }
  if(flag == FLAG_SPCRES) {
    return spcres_flag;
  }
  if(flag == FLAG_OVERFLOW) {
    return overflow_flag;
  }
  return false;
}

void setSystemFlag(int32_t flag) {
  if(flag == FLAG_CARRY) {
    carry_flag = true;
  }
  if(flag == FLAG_SPCRES) {
    spcres_flag = true;
  }
  if(flag == FLAG_OVERFLOW) {
    overflow_flag = true;
  }
}

void clearSystemFlag(int32_t flag) {
  if(flag == FLAG_CARRY) {
    carry_flag = false;
  }
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

void longIntegerFibonacci(uint32_t n, longInteger_t result) {
  __gmpz_set_ui(result, n + 100);
}

void convertTimeRegisterToReal34Register(calcRegister_t source, calcRegister_t destination) {
  (void)source;
  (void)destination;
}

void convertReal34RegisterToTimeRegister(calcRegister_t source, calcRegister_t destination) {
  (void)source;
  (void)destination;
}

void internalDateToJulianDay(real34_t *source, real34_t *destination) {
  if(destination != source) {
    *destination = *source;
  }
}

void julianDayToInternalDate(real34_t *source, real34_t *destination) {
  if(destination != source) {
    *destination = *source;
  }
}

void liftStack(void) {
  snapshot.lift_stack_calls++;
  switch(current_register_data_type) {
    case dtLongInteger:
      longint_y_input.available = longint_input.available;
      longint_y_input.value = longint_input.value;
      break;
    case dtShortInteger:
      shortint_y_slot = *(uint64_t *)register_slot;
      break;
    case dtTime:
    case dtReal34:
      real_y_input.available = real_input.available;
      real_y_input.value = real_input.value;
      break;
    default:
      break;
  }
}

const real_t *z47_math_wrappers_const_1e_6(void) {
  return &fake_const_1e_6_value;
}

const real34_t *z47_math_wrappers_const34_86400(void) {
  return &fake_const34_86400_value;
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
  *registerDataTypeSlot(regist) = data_type;
  *registerTagSlot(regist) = tag;
  if(regist == REGISTER_X && data_type != dtReal34 && data_type != dtTime && data_type != dtDate) {
    register_scalar_available = false;
  }
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

void fnMatrixSquareRoot(uint16_t unusedButMandatoryParameter) {
  (void)unusedButMandatoryParameter;
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
  mpz_init(long_integer);
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
