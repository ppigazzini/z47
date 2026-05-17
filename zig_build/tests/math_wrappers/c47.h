// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MATH_WRAPPERS_C47_H
#define Z47_MATH_WRAPPERS_C47_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;
typedef int32_t angularMode_t;

typedef struct {
  int32_t digits;
  int32_t exponent;
  uint8_t bits;
  uint16_t lsu[25];
} real_t;

typedef real_t decNumber;

typedef enum {
  trigSin,
  trigCos,
} trigType_t;

enum rounding {
  DEC_ROUND_CEILING,
  DEC_ROUND_UP,
  DEC_ROUND_HALF_UP,
  DEC_ROUND_HALF_EVEN,
  DEC_ROUND_HALF_DOWN,
  DEC_ROUND_DOWN,
  DEC_ROUND_FLOOR,
  DEC_ROUND_05UP,
  DEC_ROUND_MAX,
};

typedef struct {
  int32_t digits;
  int32_t emax;
  int32_t emin;
  enum rounding round;
  uint32_t traps;
  uint32_t status;
  uint8_t clamp;
} realContext_t;

typedef realContext_t decContext;

enum {
  amRadian = 0,
  amNone = 5,
};

#define DECINF 0x40
#define DECSPECIAL 0x70

#define EXTRA_INFO_ON_CALC_ERROR 1

#define STD_PLUS_MINUS "+/-"
#define STD_INFINITY "inf"
#define STD_DEGREE "deg"

#define REGISTER_X ((calcRegister_t)100)
#define REGISTER_Y ((calcRegister_t)101)
#define REGISTER_Z ((calcRegister_t)102)

#define ERR_REGISTER_LINE REGISTER_Z
#define ERROR_NONE 0
#define ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN 1
#define FLAG_SPCRES 0x8017

#define ifLongIntegerDoAngleReduction true

#define realChangeSign(operand) ((operand)->bits ^= 0x80)
#define realSetPositiveSign(operand) ((operand)->bits &= 0x7f)
#define realIsSpecial(source) (((source)->bits & DECSPECIAL) != 0)
#define realIsInfinite(source) (((source)->bits & DECINF) != 0)
#define realIsZero(source) ((source)->lsu[0] == 0 && !realIsSpecial(source))
#define realMultiply(operand1, operand2, res, ctxt) decNumberMultiply((res), (operand1), (operand2), (ctxt))

extern realContext_t ctxtReal39;
extern realContext_t ctxtReal51;
extern realContext_t ctxtReal75;
extern const real_t *const_NaN;

bool_t saveLastX(void);
void registerMin(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest);
void registerMax(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest);
void adjustResult(calcRegister_t res,
                  bool_t dropY,
                  bool_t setCpxRes,
                  calcRegister_t op1,
                  calcRegister_t op2,
                  calcRegister_t op3);
void processRealComplexMonadicFunction(void (*realf)(void), void (*complexf)(void));
void processIntRealComplexMonadicFunction(void (*realf)(void),
                                         void (*complexf)(void),
                                         void (*shortintf)(void),
                                         void (*longintf)(void));

void integerPartNoOp(void);
void integerPartReal(enum rounding mode);
void integerPartCplx(enum rounding mode);

bool_t getRegisterAsReal(calcRegister_t reg, real_t *value);
bool_t getRegisterAsRealAngle(calcRegister_t reg, real_t *value, angularMode_t *angle_mode, bool_t reduce_longinteger_angle);
bool_t getRegisterAsComplex(calcRegister_t reg, real_t *real, real_t *imag);
void convertRealToResultRegister(const real_t *real, calcRegister_t dest, angularMode_t angle_mode);
void convertComplexToResultRegister(const real_t *real, const real_t *imag, calcRegister_t dest);
void C47_WP34S_Cvt2RadSinCosTan(const real_t *angle,
                                angularMode_t mode,
                                real_t *sin,
                                real_t *cos,
                                real_t *tan,
                                realContext_t *real_context);
void WP34S_SinhCosh(const real_t *x, real_t *sin_out, real_t *cos_out, realContext_t *real_context);
decNumber *decNumberMultiply(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
void realSetNaN(real_t *value);
void divComplexComplex(const real_t *numer_real,
                       const real_t *numer_imag,
                       const real_t *denom_real,
                       const real_t *denom_imag,
                       real_t *quotient_real,
                       real_t *quotient_imag,
                       realContext_t *real_context);
bool_t getSystemFlag(int32_t flag);
void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line);
void moreInfoOnError(const char *msg1, const char *msg2, const char *msg3, const char *msg4);

void sinCosReal(trigType_t trigType);
void sinCosCplx(trigType_t trigType);
void sinComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void cosComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
uint8_t TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
void sinhCoshReal(trigType_t trigType);
void sinhCoshCplx(trigType_t trigType);

#endif