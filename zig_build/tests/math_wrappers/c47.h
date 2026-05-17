// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MATH_WRAPPERS_C47_H
#define Z47_MATH_WRAPPERS_C47_H

#include <gmp.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;
typedef int32_t angularMode_t;

typedef mpz_t longInteger_t;

typedef struct {
  uint8_t bytes[16];
} decQuad;

typedef decQuad real34_t;

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
  amDegree = 2,
  amNone = 5,
  amAngleMask = 15,
};

enum {
  dtLongInteger = 0,
  dtReal34 = 1,
  dtComplex34 = 2,
  dtTime = 3,
  dtReal34Matrix = 6,
  dtComplex34Matrix = 7,
  dtShortInteger = 8,
};

enum {
  LI_ZERO = 0,
  LI_NEGATIVE = 1,
  LI_POSITIVE = 2,
};

#define DECINF 0x40
#define DECNAN 0x20
#define DECSNAN 0x10
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
#define FLAG_CPXRES 0x8004
#define FLAG_SPCRES 0x8017
#define NOPARAM 0

#define ifLongIntegerDoAngleReduction true

#define longIntegerInit(op) mpz_init(op)
#define int32ToLongInteger(source, destination) mpz_set_si((destination), (source))
#define longIntegerChangeSign(op) ((op)->_mp_size = -((op)->_mp_size))
#define longIntegerFree(op) mpz_clear(op)
#define longIntegerMultiply(op_y, op_x, result) mpz_mul((result), (op_y), (op_x))

#define realChangeSign(operand) ((operand)->bits ^= 0x80)
#define realSetPositiveSign(operand) ((operand)->bits &= 0x7f)
#define realIsSpecial(source) (((source)->bits & DECSPECIAL) != 0)
#define realIsInfinite(source) (((source)->bits & DECINF) != 0)
#define realIsNegative(source) (((source)->bits & 0x80) != 0)
#define realIsPositive(source) (!realIsNegative(source))
#define realIsZero(source) ((source)->lsu[0] == 0 && !realIsSpecial(source))
#define realCopy(source, destination) (*(destination) = *(source))
#define realMultiply(operand1, operand2, res, ctxt) decNumberMultiply((res), (operand1), (operand2), (ctxt))
#define realDivide(operand1, operand2, res, ctxt) decNumberDivide((res), (operand1), (operand2), (ctxt))

#define real34ChangeSign(operand) ((operand)->bytes[15] ^= 0x80)
#define real34SetPositiveSign(operand) ((operand)->bytes[15] &= 0x7f)
#define real34IsNaN(source) decQuadIsNaN((const decQuad *)(source))
#define real34IsZero(source) decQuadIsZero((const decQuad *)(source))
#define real34IsNegative(source) decQuadIsNegative((const decQuad *)(source))

extern realContext_t ctxtReal39;
extern realContext_t ctxtReal51;
extern realContext_t ctxtReal75;
extern const real_t *const_NaN;

#define const_0 z47_math_wrappers_const_0()
#define const_1 z47_math_wrappers_const_1()
#define const_2e6 z47_math_wrappers_const_2e6()
#define const_plusInfinity z47_math_wrappers_const_plus_infinity()
#define const_minusInfinity z47_math_wrappers_const_minus_infinity()

#define realSetPlusInfinity(value) realCopy(const_plusInfinity, (value))

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
bool_t getRegisterAsLongInt(calcRegister_t reg, longInteger_t val, bool_t *fractional);
void *getRegisterDataPointer(calcRegister_t reg);
uint32_t getRegisterDataType(calcRegister_t reg);
uint32_t getRegisterTag(calcRegister_t reg);
void convertLongIntegerToLongIntegerRegister(const longInteger_t long_integer, calcRegister_t regist);
void convertRealToResultRegister(const real_t *real, calcRegister_t dest, angularMode_t angle_mode);
void convertComplexToResultRegister(const real_t *real, const real_t *imag, calcRegister_t dest);
void convertAngleFromTo(real_t *angle, angularMode_t fromAngularMode, angularMode_t toAngularMode, realContext_t *realContext);
void C47_WP34S_Cvt2RadSinCosTan(const real_t *angle,
                                angularMode_t mode,
                                real_t *sin,
                                real_t *cos,
                                real_t *tan,
                                realContext_t *real_context);
void WP34S_SinhCosh(const real_t *x, real_t *sin_out, real_t *cos_out, realContext_t *real_context);
void WP34S_Tanh(const real_t *x, real_t *res, realContext_t *real_context);
decNumber *decNumberMultiply(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
decNumber *decNumberDivide(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
decNumber *decNumberExp(decNumber *result, const decNumber *rhs, decContext *real_context);
bool_t realCompareAbsEqual(const real_t *number1, const real_t *number2);
bool_t realCompareAbsGreaterThan(const real_t *number1, const real_t *number2);
void realSetNaN(real_t *value);
void realSetZero(real_t *value);
void realSetOne(real_t *value);
void divRealComplex(const real_t *numer,
                    const real_t *denom_real,
                    const real_t *denom_imag,
                    real_t *quotient_real,
                    real_t *quotient_imag,
                    realContext_t *real_context);
void divComplexComplex(const real_t *numer_real,
                       const real_t *numer_imag,
                       const real_t *denom_real,
                       const real_t *denom_imag,
                       real_t *quotient_real,
                       real_t *quotient_imag,
                       realContext_t *real_context);
void mulComplexi(const real_t *inReal, const real_t *inImag, real_t *productReal, real_t *productImag);
void mulComplexComplex(const real_t *factor1_real,
                       const real_t *factor1_imag,
                       const real_t *factor2_real,
                       const real_t *factor2_imag,
                       real_t *product_real,
                       real_t *product_imag,
                       realContext_t *real_context);
void unitVectorCplx(void);
uint64_t WP34S_extract_value(uint64_t val, int32_t *sign);
uint64_t WP34S_intMultiply(uint64_t y, uint64_t x);
uint64_t WP34S_intChs(uint64_t x);
bool_t getSystemFlag(int32_t flag);
void fnSetFlag(int32_t flag);
void fnRefreshState(void);
void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line);
void moreInfoOnError(const char *msg1, const char *msg2, const char *msg3, const char *msg4);
void fnInvertMatrix(uint16_t unusedButMandatoryParameter);

const real_t *z47_math_wrappers_const_0(void);
const real_t *z47_math_wrappers_const_1(void);
const real_t *z47_math_wrappers_const_2e6(void);
const real_t *z47_math_wrappers_const_plus_infinity(void);
const real_t *z47_math_wrappers_const_minus_infinity(void);
void z47_math_wrappers_report_exp_real_domain_error(void);
void z47_math_wrappers_report_eulers_formula_complex_domain_error(void);
void z47_math_wrappers_report_eulers_formula_real_domain_error(void);

uint32_t decQuadIsNaN(const decQuad *dq);
uint32_t decQuadIsZero(const decQuad *dq);
uint32_t decQuadIsNegative(const decQuad *dq);

#define REGISTER_SHORT_INTEGER_DATA(a) ((uint64_t *)(getRegisterDataPointer(a)))
#define REGISTER_REAL34_DATA(a) ((real34_t *)(getRegisterDataPointer(a)))
#define getRegisterAngularMode(reg) (getRegisterTag(reg) & amAngleMask)
#define getRegisterLongIntegerSign(reg) getRegisterTag(reg)

void sinCosReal(trigType_t trigType);
void sinCosCplx(trigType_t trigType);
void sinComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void cosComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
uint8_t TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
uint8_t TanhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
void sinhCoshReal(trigType_t trigType);
void sinhCoshCplx(trigType_t trigType);

#endif