// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MATH_WRAPPERS_C47_H
#define Z47_MATH_WRAPPERS_C47_H

#include <gmp.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <inttypes.h>
#include <stdint.h>
#include <string.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;
typedef int32_t angularMode_t;

typedef mpz_t longInteger_t;

typedef struct {
  uint8_t bytes[16];
} decQuad;

typedef decQuad real34_t;

typedef struct {
  real34_t real;
  real34_t imag;
} complex34_t;

typedef struct {
  uint16_t matrixRows;
  uint16_t matrixColumns;
} matrixHeader_t;

typedef struct {
  matrixHeader_t header;
  real34_t matrixElements[4];
} real34Matrix_t;

typedef struct {
  matrixHeader_t header;
  complex34_t matrixElements[4];
} complex34Matrix_t;

typedef struct {
  uint8_t unused;
} font_t;

typedef int irfracOption_t;

typedef struct {
  uint64_t state;
  uint64_t inc;
} pcg32_random_t;

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
  amPolar = 16,
  amAngleMask = 15,
};

enum {
  dtLongInteger = 0,
  dtReal34 = 1,
  dtComplex34 = 2,
  dtTime = 3,
  dtDate = 4,
  dtString = 5,
  dtReal34Matrix = 6,
  dtComplex34Matrix = 7,
  dtShortInteger = 8,
  dtConfig = 9,
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

#define PCG32_INITIALIZER { 0x853c49e6748fea9bULL, 0xda3e39cb94b95bdbULL }

#define STD_PLUS_MINUS "+/-"
#define STD_INFINITY "inf"
#define STD_DEGREE "deg"
#define STD_LESS_EQUAL "<="
#define STD_CROSS "x"
#define STD_DIVIDE "/"
#define STD_SUP_BOLD_x "^x"

#define REGISTER_X ((calcRegister_t)100)
#define REGISTER_Y ((calcRegister_t)101)
#define REGISTER_Z ((calcRegister_t)102)
#define REGISTER_T ((calcRegister_t)103)

#define REGISTER_L ((calcRegister_t)108)
#define ERR_REGISTER_LINE REGISTER_Z
#define ERROR_NONE 0
void copySourceRegisterToDestRegister(calcRegister_t source_register, calcRegister_t dest_register);
real34_t *decQuadAdd(real34_t *res, const real34_t *operand1, const real34_t *operand2, realContext_t *context);
real34_t *decQuadDivide(real34_t *res, const real34_t *operand1, const real34_t *operand2, realContext_t *context);
real34_t *decQuadMultiply(real34_t *res, const real34_t *operand1, const real34_t *operand2, realContext_t *context);
#define ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN 1
#define ERROR_INVALID_DATA_TYPE_FOR_OP 2
#define ERROR_OUT_OF_RANGE 3
#define ERROR_OVERFLOW_PLUS_INF 4
#define ERROR_OVERFLOW_MINUS_INF 5
#define ERROR_RAM_FULL 6
#define ERROR_MATRIX_MISMATCH 7
#define ERROR_SINGULAR_MATRIX 22
#define ERROR_STRING_WOULD_BE_TOO_LONG 33
#define FLAG_CARRY 0x800b
#define FLAG_CPXRES 0x8004
#define FLAG_FRACT 0x8007
#define FLAG_PROPFR 0x8008
#define FLAG_OVERFLOW 0x800c
#define FLAG_POLAR 0x8018
#define FLAG_SPCRES 0x8017
#define FLAG_ASLIFT 0x8019
#define FLAG_HPRP 0x802b
#define NOPARAM 0
#define NIM_REGISTER_LINE REGISTER_X
#define TEMP_REGISTER_1 REGISTER_Z
#define TO_QSPI
#define TO_BLOCKS(length) (length)
#define NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS 10
#define MAX_LONG_INTEGER_SIZE_IN_BITS 3328
#define MAX_FACTORIAL 450
#define ERROR_MESSAGE_LENGTH 256
#define TMP_STR_LENGTH 2560
#define MAX_NUMBER_OF_GLYPHS_IN_STRING 255
#define NUMBER_OF_DISPLAY_DIGITS 34
#define LIMITEXP 0
#define FRONTSPACE false
#define FULLIRFRAC 0
#define noBaseOverride 0
#define SCREEN_WIDTH 32
#define LINUX 1

#define SIM_UNSIGN 0
#define SIM_1COMPL 1
#define SIM_2COMPL 2
#define SIM_SIGNMT 3

#define ifLongIntegerDoAngleReduction true

#define longIntegerInit(op) mpz_init(op)
#define uInt32ToLongInteger(source, destination) mpz_set_ui((destination), (source))
#define int32ToLongInteger(source, destination) mpz_set_si((destination), (source))
#define longIntegerSetPositiveSign(op) do { if(mpz_sgn((op)) < 0) mpz_neg((op), (op)); } while(0)
#define longIntegerSetNegativeSign(op) do { if(mpz_sgn((op)) > 0) mpz_neg((op), (op)); } while(0)
#define longIntegerSign(op) mpz_sgn(op)
#define longIntegerIsNegative(op) (mpz_sgn(op) < 0)
#define longIntegerIsZero(op) (mpz_sgn(op) == 0)
#define longIntegerIsEven(op) mpz_even_p(op)
#define longIntegerIsOdd(op) mpz_odd_p(op)
#define longIntegerChangeSign(op) ((op)->_mp_size = -((op)->_mp_size))
#define longIntegerFree(op) mpz_clear(op)
#define longIntegerSetZero(op) mpz_set_ui((op), 0)
#define longIntegerInitSizeInBits(op, bits) mpz_init2((op), (bits))
#define longIntegerDivideUInt(op, divisor, result) mpz_fdiv_q_ui((result), (op), (divisor))
#define longIntegerMultiply(op_y, op_x, result) mpz_mul((result), (op_y), (op_x))
#define longIntegerMultiplyUInt(lhs, rhs, result) mpz_mul_ui((result), (lhs), (rhs))
#define longIntegerSquare(op, result) mpz_mul((result), (op), (op))
#define longIntegerCompare(lhs, rhs) mpz_cmp((lhs), (rhs))
#define longIntegerCopy(source, destination) mpz_set((destination), (source))
#define longIntegerSubtract(lhs, rhs, result) mpz_sub((result), (lhs), (rhs))
#define longIntegerSubtractUInt(lhs, rhs, result) mpz_sub_ui((result), (lhs), (rhs))
#define longIntegerCompareUInt(lhs, rhs) mpz_cmp_ui((lhs), (rhs))
#define longIntegerToUInt32(source, destination) ((destination) = (uint32_t)mpz_get_ui((source)))
#define longIntegerAddUInt(lhs, rhs, result) mpz_add_ui((result), (lhs), (rhs))
#define longIntegerAdd(lhs, rhs, result) mpz_add((result), (lhs), (rhs))
#define longIntegerGcd(lhs, rhs, result) mpz_gcd((result), (lhs), (rhs))
#define longIntegerLcm(lhs, rhs, result) mpz_lcm((result), (lhs), (rhs))
#define longIntegerDivide(lhs, rhs, result) mpz_tdiv_q((result), (lhs), (rhs))
#define longIntegerDivideRemainder(dividend, divisor, remainder) mpz_tdiv_r((remainder), (dividend), (divisor))
#define longIntegerModulo(lhs, rhs, result) mpz_mod((result), (lhs), (rhs))
#define DECNEG 0x80

#define TI_FALSE 0
#define TI_TRUE 1
#define TI_RADIUS_THETA 1
#define TI_RADIUS_THETA_SWAPPED 2
#define TI_PERC 2
#define TI_PERCD 3
#define TI_X_Y 4
#define TI_X_Y_SWAPPED 5
#define SET_TI_TRUE_FALSE(condition) do { temporaryInformation = ((condition) ? TI_TRUE : TI_FALSE); } while(0)

enum {
  bugMsgUnexpectedSValue = 0,
};

#define realChangeSign(operand) ((operand)->bits ^= 0x80)
#define realSetNegativeSign(operand) ((operand)->bits |= 0x80)
#define realSetPositiveSign(operand) ((operand)->bits &= 0x7f)
#define realIsSpecial(source) (((source)->bits & DECSPECIAL) != 0)
#define realIsInfinite(source) (((source)->bits & DECINF) != 0)
#define realIsNaN(source) (((source)->bits & (DECNAN | DECSNAN)) != 0)
#define realIsNegative(source) (((source)->bits & 0x80) != 0)
#define realIsPositive(source) (!realIsNegative(source))
#define realGetSign(source) (realIsNegative(source) ? -1 : 1)
#define realIsZero(source) ((source)->lsu[0] == 0 && !realIsSpecial(source))
#define realCopy(source, destination) (*(destination) = *(source))
#define realMinus(operand, res, ctxt) do { (void)(ctxt); realCopy((operand), (res)); realChangeSign((res)); } while(0)
#define realMultiply(operand1, operand2, res, ctxt) decNumberMultiply((res), (operand1), (operand2), (ctxt))
#define realDivide(operand1, operand2, res, ctxt) decNumberDivide((res), (operand1), (operand2), (ctxt))
#define realAdd(operand1, operand2, res, ctxt) decNumberAdd((res), (operand1), (operand2), (ctxt))
#define realSubtract(operand1, operand2, res, ctxt) decNumberSubtract((res), (operand1), (operand2), (ctxt))
#define realFMA(factor1, factor2, term, res, ctxt) decNumberFMA((res), (factor1), (factor2), (term), (ctxt))
#define realSquareRoot(operand, res, ctxt) decNumberSquareRoot((res), (operand), (ctxt))
#define uInt32ToReal(source, destination) decNumberFromUInt32((destination), (source))

#define real34ChangeSign(operand) ((operand)->bytes[15] ^= 0x80)
#define real34SetPositiveSign(operand) ((operand)->bytes[15] &= 0x7f)
#define real34IsNaN(source) decQuadIsNaN((const decQuad *)(source))
#define real34IsZero(source) decQuadIsZero((const decQuad *)(source))
#define real34IsNegative(source) decQuadIsNegative((const decQuad *)(source))
#define real34IsPositive(source) (!real34IsNegative((source)))
#define real34Add(operand1, operand2, res) decQuadAdd((res), (operand1), (operand2), &ctxtReal34)
#define real34Divide(operand1, operand2, res) decQuadDivide((res), (operand1), (operand2), &ctxtReal34)
#define real34Multiply(operand1, operand2, res) decQuadMultiply((res), (operand1), (operand2), &ctxtReal34)

extern realContext_t ctxtReal34;
extern realContext_t ctxtReal39;
extern realContext_t ctxtReal51;
extern realContext_t ctxtReal75;
extern const real_t *const_NaN;
extern uint8_t lastErrorCode;
extern uint8_t shortIntegerMode;
extern uint8_t shortIntegerWordSize;
extern uint64_t shortIntegerMask;
extern uint64_t shortIntegerSignBit;
extern angularMode_t currentAngularMode;
extern bool_t thereIsSomethingToUndo;
extern pcg32_random_t pcg32_global;
extern int32_t significantDigits;
extern int32_t temporaryInformation;
extern uint64_t systemFlags0;
extern uint64_t systemFlags1;

#define const_0 ((real_t *)z47_math_wrappers_const_0())
#define const_1 ((real_t *)z47_math_wrappers_const_1())
#define const__1 ((real_t *)z47_math_wrappers_const_minus_1())
#define const_2 ((real_t *)z47_math_wrappers_const_2())
#define const_5 ((real_t *)z47_math_wrappers_const_5())
#define const_100 ((real_t *)z47_math_wrappers_const_100())
#define const_180 ((real_t *)z47_math_wrappers_const_180())
#define const_1on2 ((real_t *)z47_math_wrappers_const_1on2())
#define const39_1on3 ((real_t *)z47_math_wrappers_const_1on3())
#define const_2e6 ((real_t *)z47_math_wrappers_const_2e6())
#define const_1e_6 ((real_t *)z47_math_wrappers_const_1e_6())
#define const34_0 ((real34_t *)z47_math_wrappers_const34_0())
#define const39_1oneE ((real_t *)z47_math_wrappers_const_1oneE())
#define const_90 ((real_t *)z47_math_wrappers_const_90())
#define const39_ln2 ((real_t *)z47_math_wrappers_const_ln2())
#define const39_ln10 ((real_t *)z47_math_wrappers_const_ln10())
#define const39_PHI ((real_t *)z47_math_wrappers_const_phi())
#define const39_pi ((real_t *)z47_math_wrappers_const_pi())
#define const_plusInfinity ((real_t *)z47_math_wrappers_const_plus_infinity())
#define const_minusInfinity ((real_t *)z47_math_wrappers_const_minus_infinity())

#define realSetPlusInfinity(value) realCopy(const_plusInfinity, (value))
#define realSetMinusInfinity(value) realCopy(const_minusInfinity, (value))
#define real34ToReal(source, destination) decimal128ToNumber((const real34_t *)(source), (destination))
#define realDivideRemainder(dividend, divisor, remainder, ctxt) WP34S_Mod((dividend), (divisor), (remainder), (ctxt))
#define realCompareAbsLessThan(number1, number2) (!realCompareAbsEqual((number1), (number2)) && !realCompareAbsGreaterThan((number1), (number2)))
#define realCompareGreaterEqual(number1, number2) (!realCompareLessThan((number1), (number2)))
#define realCompareLessEqual(number1, number2) (!realCompareLessThan((number2), (number1)))
#define realCompareGreaterThan(number1, number2) realCompareLessThan((number2), (number1))
#define WP34S_BigMod(x, y, res, real_context) WP34S_Mod((x), (y), (res), (real_context))
#define EXTRA_INFO_MESSAGE(function, msg) do { moreInfoOnError((function), (msg), NULL, NULL); } while(0)
#define real34Copy(source, destination) (*(destination) = *(source))
#define complex34Copy(source, destination) (*(destination) = *(source))
#define real34SetZero(destination) memset((destination), 0, sizeof(real34_t))
#define setRegisterLongIntegerSign(reg, sign) setRegisterTag((reg), (sign))
#define VARIABLE_REAL34_DATA(variable) (&((variable)->real))
#define VARIABLE_IMAG34_DATA(variable) (&((variable)->imag))

bool_t saveLastX(void);
void saveForUndo(void);
void registerMin(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest);
void registerMax(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest);
void elementwiseRema(void (*func)(void));
void elementwiseRemaReal(void (*func)(void));
void adjustResult(calcRegister_t res,
                  bool_t dropY,
                  bool_t setCpxRes,
                  calcRegister_t op1,
                  calcRegister_t op2,
                  calcRegister_t op3);
void processRealComplexMonadicFunction(void (*realf)(void), void (*complexf)(void));
void processRealComplexDyadicFunction(void (*realf)(void), void (*complexf)(void));
void processIntRealComplexMonadicFunction(void (*realf)(void),
                                         void (*complexf)(void),
                                         void (*shortintf)(void),
                                         void (*longintf)(void));
void processIntRealComplexDyadicFunction(void (*realf)(void),
                                        void (*complexf)(void),
                                        void (*shortintf)(void),
                                        void (*longintf)(void));

void liftStack(void);
void reallocateRegister(calcRegister_t regist, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag);
void fnDrop(uint16_t unusedButMandatoryParameter);
void fnUndo(uint16_t unusedButMandatoryParameter);
uint32_t getUptimeMs(void);
uint32_t getFreeRamMemory(void);
uint32_t getFreeFlash(void);

void integerPartNoOp(void);
void integerPartReal(enum rounding mode);
void integerPartCplx(enum rounding mode);

bool_t getRegisterAsReal(calcRegister_t reg, real_t *value);
bool_t getRegisterAsRealAngle(calcRegister_t reg, real_t *value, angularMode_t *angle_mode, bool_t reduce_longinteger_angle);
bool_t getRegisterAsComplex(calcRegister_t reg, real_t *real, real_t *imag);
bool_t getRegisterAsShortInt(calcRegister_t reg, bool_t *sign, uint64_t *val, bool_t *overflow, bool_t *fractional);
bool_t getFlag(uint16_t flag);
bool_t getRegisterAsLongInt(calcRegister_t reg, longInteger_t val, bool_t *fractional);
int getRegisterAsLongIntQuiet(calcRegister_t reg, longInteger_t val, bool_t *fractional);
bool_t fraction(calcRegister_t regist, int16_t *sign, uint64_t *intPart, uint64_t *numer, uint64_t *denom, int16_t *lessEqualGreater);
void convertLongIntegerRegisterToLongInteger(calcRegister_t reg, longInteger_t long_integer);
void convertShortIntegerRegisterToLongInteger(calcRegister_t reg, longInteger_t long_integer);
void convertShortIntegerRegisterToLongIntegerRegister(calcRegister_t source, calcRegister_t destination);
void convertLongIntegerRegisterToReal(calcRegister_t reg, real_t *real, realContext_t *real_context);
void convertLongIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination);
void convertLongIntegerRegisterToTimeRegister(calcRegister_t source, calcRegister_t destination);
void convertLongIntegerToReal34(longInteger_t source, real34_t *destination);
void *getRegisterDataPointer(calcRegister_t reg);
uint32_t getRegisterDataType(calcRegister_t reg);
uint32_t getRegisterTag(calcRegister_t reg);
void setRegisterTag(calcRegister_t reg, uint32_t tag);
void convertLongIntegerToLongIntegerRegister(const longInteger_t long_integer, calcRegister_t regist);
void convertLongIntegerToShortIntegerRegister(const longInteger_t long_integer, uint32_t base, calcRegister_t regist);
void convertUInt64ToShortIntegerRegister(int16_t sign, uint64_t value, uint32_t base, calcRegister_t regist);
void convertShortIntegerRegisterToUInt64(calcRegister_t reg, int16_t *sign, uint64_t *value);
void convertShortIntegerRegisterToReal(calcRegister_t source, real_t *destination, realContext_t *real_context);
void convertShortIntegerRegisterToReal34Register(calcRegister_t source, calcRegister_t destination);
void convergenceTolerence(real_t *tol);
bool_t WP34S_RelativeError(const real_t *x, const real_t *y, const real_t *tol, realContext_t *realContext);
bool_t WP34S_AbsoluteError(const real_t *x, const real_t *y, const real_t *tol, realContext_t *realContext);
bool_t WP34S_ComplexRelativeError(const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag, const real_t *tol, realContext_t *realContext);
bool_t WP34S_ComplexAbsError(const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag, const real_t *tol, realContext_t *realContext);
void convertRealToResultRegister(const real_t *real, calcRegister_t dest, angularMode_t angle_mode);
void convertRealToLongIntegerRegister(const real_t *real, calcRegister_t dest, enum rounding roundingMode);
void convertReal34ToLongIntegerRegister(const real34_t *real, calcRegister_t dest, enum rounding roundingMode);
void real34ToIntegralValue(const real34_t *source, real34_t *destination, enum rounding mode);
void real34Subtract(const real34_t *operand1, const real34_t *operand2, real34_t *res);
bool_t real34CompareLessThan(const real34_t *lhs, const real34_t *rhs);
bool_t real34CompareEqual(const real34_t *lhs, const real34_t *rhs);
bool_t real34IsInfinite(const real34_t *value);
int32_t real34GetExponent(const real34_t *value);
bool_t real34IsAnInteger(const real34_t *value);
void real34NextPlus(const real34_t *source, real34_t *destination);
void real34NextMinus(const real34_t *source, real34_t *destination);
void realToReal34(const real_t *source, real34_t *destination);
void convertAngle34FromTo(real34_t *angle, angularMode_t from_mode, angularMode_t to_mode);
void real34RectangularToPolar(const real34_t *real, const real34_t *imag, real34_t *magnitude, real34_t *theta);
void convertComplexToResultRegister(const real_t *real, const real_t *imag, calcRegister_t dest);
void setRegisterAngularMode(calcRegister_t reg, angularMode_t mode);
void convertAngleFromTo(real_t *angle, angularMode_t fromAngularMode, angularMode_t toAngularMode, realContext_t *realContext);
uint32_t getInfiniteComplexAngle(real_t *x, real_t *y);
void setInfiniteComplexAngle(uint32_t angle, real_t *x, real_t *y);
void realPolarToRectangular(const real_t *magnitude,
                            const real_t *angle,
                            real_t *real,
                            real_t *imag,
                            realContext_t *real_context);
void realRectangularToPolar(const real_t *real,
                            const real_t *imag,
                            real_t *magnitude,
                            real_t *theta,
                            realContext_t *real_context);
void WP34S_Mod(const real_t *x, const real_t *y, real_t *res, realContext_t *real_context);
void WP34S_Logxy(const real_t *numer, const real_t *denom, real_t *res, realContext_t *real_context);
void C47_WP34S_Cvt2RadSinCosTan(const real_t *angle,
                                angularMode_t mode,
                                real_t *sin,
                                real_t *cos,
                                real_t *tan,
                                realContext_t *real_context);
void C47_WP34S_Asin(const real_t *x, real_t *angle, realContext_t *real_context);
void C47_WP34S_Acos(const real_t *x, real_t *angle, realContext_t *real_context);
void C47_WP34S_Atan(const real_t *x, real_t *angle, realContext_t *real_context);
void C47_WP34S_Atan2(const real_t *y, const real_t *x, real_t *angle, realContext_t *real_context);
void WP34S_SinhCosh(const real_t *x, real_t *sin_out, real_t *cos_out, realContext_t *real_context);
void WP34S_ArcSinh(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_ArcTanh(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_Tanh(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_Erf(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_Erfc(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_Ln(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_Ln1P(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_ExpM1(const real_t *x, real_t *res, realContext_t *real_context);
void realPower(const real_t *base, const real_t *exponent, real_t *result, realContext_t *real_context);
void PowerReal(const real_t *base, const real_t *exponent, real_t *result, realContext_t *real_context);
uint8_t PowerComplex(const real_t *base_real, const real_t *base_imag, const real_t *exponent_real, const real_t *exponent_imag, real_t *result_real, real_t *result_imag, realContext_t *real_context);
void WP34S_Bernoulli(const real_t *x, real_t *res, bool_t bnstar, realContext_t *real_context);
void WP34S_Factorial(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_InverseW(const real_t *x, real_t *res, realContext_t *real_context);
void WP34S_InverseComplexW(const real_t *real, const real_t *imag, real_t *res_real, real_t *res_imag, realContext_t *real_context);
void WP34S_LambertW(const real_t *x, real_t *res, bool_t negative_branch, realContext_t *real_context);
void WP34S_ComplexLambertW(const real_t *real, const real_t *imag, real_t *res_real, real_t *res_imag, realContext_t *real_context);
void WP34S_ComplexGamma(const real_t *real, const real_t *imag, real_t *res_real, real_t *res_imag, realContext_t *real_context);
void WP34S_betai(const real_t *b, const real_t *a, const real_t *x, real_t *res, realContext_t *real_context);
void realExpM1(const real_t *x, real_t *res, realContext_t *realContext);
void logxyLonI(const real_t *denom);
void logxyReal(const real_t *denom);
void logxyCplx(const real_t *denom);
void lnComplex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext);
void sqrt1Px2Complex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void sqrtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void complexMagnitude(const real_t *real, const real_t *imag, real_t *magnitude, realContext_t *realContext);
void int32ToReal(int32_t source, real_t *destination);
int32_t realToInt32C47(const real_t *source, bool_t *error);
decNumber *decimal128ToNumber(const real34_t *source, decNumber *destination);
decNumber *decNumberMultiply(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
decNumber *decNumberDivide(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
decNumber *decNumberSquareRoot(decNumber *result, const decNumber *rhs, decContext *real_context);
decNumber *decNumberExp(decNumber *result, const decNumber *rhs, decContext *real_context);
decNumber *decNumberAdd(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
decNumber *decNumberSubtract(decNumber *result, const decNumber *lhs, const decNumber *rhs, decContext *real_context);
decNumber *decNumberFMA(decNumber *result, const decNumber *lhs, const decNumber *rhs, const decNumber *term, decContext *real_context);
decNumber *decNumberFromUInt32(decNumber *result, uint32_t source);
void realToIntegralValue(const real_t *source, real_t *destination, enum rounding mode, realContext_t *realContext);
bool_t realCompareEqual(const real_t *number1, const real_t *number2);
bool_t realCompareLessThan(const real_t *number1, const real_t *number2);
bool_t realCompareAbsEqual(const real_t *number1, const real_t *number2);
bool_t realCompareAbsGreaterThan(const real_t *number1, const real_t *number2);
bool_t realIsAnInteger(const real_t *x);
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
void mulComplexReal(const real_t *factor1_real,
                    const real_t *factor1_imag,
                    const real_t *factor2,
                    real_t *product_real,
                    real_t *product_imag,
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
int64_t WP34S_build_value(uint64_t x, int32_t sign);
uint64_t WP34S_int2pow(uint64_t x);
uint64_t WP34S_int10pow(uint64_t x);
uint64_t WP34S_intLog10(uint64_t x);
uint64_t WP34S_intLog2(uint64_t x);
uint64_t WP34S_intAbs(uint64_t x);
uint64_t WP34S_intSqrt(uint64_t x);
uint64_t WP34S_intAdd(uint64_t x, uint64_t y);
uint64_t WP34S_intSubtract(uint64_t x, uint64_t y);
uint64_t WP34S_intDivide(uint64_t y, uint64_t x);
uint64_t WP34S_intGCD(uint64_t y, uint64_t x);
uint64_t WP34S_intLCM(uint64_t y, uint64_t x);
uint64_t WP34S_intMultiply(uint64_t y, uint64_t x);
uint64_t WP34S_intChs(uint64_t x);
bool_t getSystemFlag(int32_t flag);
void setSystemFlag(int32_t flag);
void clearSystemFlag(int32_t flag);
void fnSetFlag(int32_t flag);
void fnRefreshState(void);
void refreshLcd(void *unused);
void lcd_refresh(void);
void fnChangeBase(uint16_t base);
void fnSwapXY(uint16_t unusedButMandatoryParameter);
void forceSystemFlag(unsigned int sf, int set);
void displayCalcErrorMessage(uint8_t error_code, calcRegister_t err_message_register_line, calcRegister_t err_register_line);
void displayBugScreen(const char *message);
void moreInfoOnError(const char *msg1, const char *msg2, const char *msg3, const char *msg4);
void doNothing(void);
void fnMatrixSquareRoot(uint16_t unusedButMandatoryParameter);
void fnDropY(uint16_t unusedButMandatoryParameter);
const char *getDataTypeName(uint32_t data_type, bool_t article, bool_t abbreviated);
void realNextToward(const real_t *x, const real_t *y, real_t *result, realContext_t *real_context);
const char *getRegisterDataTypeName(calcRegister_t reg, bool_t article, bool_t abbreviated);
void longIntegerRegisterToDisplayString(calcRegister_t reg, char *buffer, int buffer_length, int screen_width, int limit, bool_t allow_large);
int16_t stringByteLength(const char *value);
int16_t stringGlyphLength(const char *value);
void xcopy(void *destination, const void *source, size_t length);
void fractionToDisplayString(calcRegister_t regist, char *displayString);
void shortIntegerToDisplayString(calcRegister_t regist, char *displayString, bool_t determineFont, uint8_t baseOverride);
void real34ToDisplayString(const real34_t *real34, uint32_t tag, char *displayString, const font_t *font, int16_t maxWidth, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace, irfracOption_t limitIrfrac);
void complex34ToDisplayString(const complex34_t *complex34, char *displayString, const font_t *font, int16_t maxWidth, int16_t displayHasNDigits, bool_t limitExponent, bool_t frontSpace, irfracOption_t limitIrfrac, uint16_t tagAngle, bool_t tagPolar);
void dateToDisplayString(calcRegister_t regist, char *displayString);
void timeToDisplayString(calcRegister_t regist, char *displayString, bool_t ignoreTDisp);
void real34MatrixToDisplayString(calcRegister_t regist, char *displayString);
void complex34MatrixToDisplayString(calcRegister_t regist, char *displayString);
void roundToSignificantDigits(const real_t *source, real_t *destination, int32_t digits, realContext_t *real_context);
void linkToComplexMatrixRegister(calcRegister_t reg, complex34Matrix_t *matrix);
void linkToRealMatrixRegister(calcRegister_t reg, real34Matrix_t *matrix);
bool_t realMatrixInit(real34Matrix_t *matrix, uint16_t rows, uint16_t columns);
bool_t complexMatrixInit(complex34Matrix_t *matrix, uint16_t rows, uint16_t columns);
void realMatrixFree(real34Matrix_t *matrix);
void complexMatrixFree(complex34Matrix_t *matrix);
void convertReal34MatrixToReal34MatrixRegister(const real34Matrix_t *matrix, calcRegister_t reg);
void convertComplex34MatrixToComplex34MatrixRegister(const complex34Matrix_t *matrix, calcRegister_t reg);
void convertReal34MatrixRegisterToReal34Matrix(calcRegister_t reg, real34Matrix_t *matrix);
void convertComplex34MatrixRegisterToComplex34Matrix(calcRegister_t reg, complex34Matrix_t *matrix);
void convertReal34MatrixRegisterToComplex34MatrixRegister(calcRegister_t source, calcRegister_t destination);
void convertReal34MatrixRegisterToComplex34Matrix(calcRegister_t reg, complex34Matrix_t *matrix);
void convertReal34MatrixToComplex34Matrix(const real34Matrix_t *real_matrix, complex34Matrix_t *complex_matrix);
void elementwiseRealRema(void (*func)(void));
void elementwiseCxmaReal(void (*func)(void));
void elementwiseRealCxma(void (*func)(void));
void addRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res);
void subtractRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res);
void addComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res);
void subtractComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res);
void multiplyRealMatrix(const real34Matrix_t *matrix, const real34_t *x, real34Matrix_t *res);
void _multiplyRealMatrix(const real34Matrix_t *matrix, const real_t *x, real34Matrix_t *res, realContext_t *realContext);
void multiplyRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res);
void multiplyComplexMatrix(const complex34Matrix_t *matrix, const real34_t *xr, const real34_t *xi, complex34Matrix_t *res);
void _multiplyComplexMatrix(const complex34Matrix_t *matrix, const real_t *xr, const real_t *xi, complex34Matrix_t *res, realContext_t *realContext);
void multiplyComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res);
void divideRealMatrix(const real34Matrix_t *matrix, const real34_t *x, real34Matrix_t *res);
void _divideRealMatrix(const real34Matrix_t *matrix, const real_t *x, real34Matrix_t *res, realContext_t *realContext);
void _divideByRealMatrix(const real_t *y, const real34Matrix_t *matrix, real34Matrix_t *res, realContext_t *realContext);
void divideByRealMatrix(const real34_t *y, const real34Matrix_t *matrix, real34Matrix_t *res);
void divideRealMatrices(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res);
void divideComplexMatrix(const complex34Matrix_t *matrix, const real34_t *xr, const real34_t *xi, complex34Matrix_t *res);
void _divideComplexMatrix(const complex34Matrix_t *matrix, const real_t *xr, const real_t *xi, complex34Matrix_t *res, realContext_t *realContext);
void _divideByComplexMatrix(const real_t *yr, const real_t *yi, const complex34Matrix_t *matrix, complex34Matrix_t *res, realContext_t *realContext);
void divideByComplexMatrix(const real34_t *yr, const real34_t *yi, const complex34Matrix_t *matrix, complex34Matrix_t *res);
void divideComplexMatrices(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res);
uint16_t realVectorSize(const real34Matrix_t *matrix);
void dotRealVectors(const real34Matrix_t *y, const real34Matrix_t *x, real34_t *res);
void crossRealVectors(const real34Matrix_t *y, const real34Matrix_t *x, real34Matrix_t *res);
uint16_t complexVectorSize(const complex34Matrix_t *matrix);
void dotComplexVectors(const complex34Matrix_t *y, const complex34Matrix_t *x, real34_t *res_r, real34_t *res_i);
void crossComplexVectors(const complex34Matrix_t *y, const complex34Matrix_t *x, complex34Matrix_t *res);
void setLastintegerBasetoZero(void);
void fnInvertMatrix(uint16_t unusedButMandatoryParameter);
void convertRealToReal34ResultRegister(const real_t *real, calcRegister_t dest);
double z47_math_wrappers_log(double value);

extern char errorMessage[ERROR_MESSAGE_LENGTH];
extern char tmpString[ERROR_MESSAGE_LENGTH];
extern const char *commonBugScreenMessages[];

const real_t *z47_math_wrappers_const_0(void);
const real_t *z47_math_wrappers_const_1(void);
const real_t *z47_math_wrappers_const_minus_1(void);
const real_t *z47_math_wrappers_const_2(void);
const real_t *z47_math_wrappers_const_5(void);
const real_t *z47_math_wrappers_const_100(void);
const real_t *z47_math_wrappers_const_180(void);
const real_t *z47_math_wrappers_const_1on2(void);
const real_t *z47_math_wrappers_const_1on3(void);
const real_t *z47_math_wrappers_const_2e6(void);
const real_t *z47_math_wrappers_const_1e_6(void);
const real34_t *z47_math_wrappers_const34_0(void);
const real34_t *z47_math_wrappers_const34_86400(void);
const real_t *z47_math_wrappers_const_1oneE(void);
const real_t *z47_math_wrappers_const_90(void);
const real_t *z47_math_wrappers_const_ln2(void);
const real_t *z47_math_wrappers_const_ln10(void);
const real_t *z47_math_wrappers_const_phi(void);
const real_t *z47_math_wrappers_const_pi(void);
const real_t *z47_math_wrappers_const_plus_infinity(void);
const real_t *z47_math_wrappers_const_minus_infinity(void);
void z47_math_wrappers_minus_one_power_long_integer(void);
void z47_math_wrappers_integer_part_long_integer(void);
void z47_math_wrappers_integer_part_short_integer(void);
void z47_math_wrappers_fractional_part_long_integer(void);
void z47_math_wrappers_fractional_part_short_integer(void);
void z47_math_wrappers_fractional_part_real(void);
int32_t z47_math_wrappers_small_base_power_long_integer(uint32_t baseValue);
void longInteger2Pow(int32_t exponent, longInteger_t result);
void longIntegerDivideQuotientRemainder(const longInteger_t dividend, const longInteger_t divisor, longInteger_t quotient, longInteger_t remainder);
void z47_math_wrappers_report_int_pow_real_domain_error(void);
void z47_math_wrappers_report_exp_real_domain_error(void);
void z47_math_wrappers_report_eulers_formula_complex_domain_error(void);
void z47_math_wrappers_report_eulers_formula_real_domain_error(void);

uint32_t decQuadIsNaN(const decQuad *dq);
uint32_t decQuadIsZero(const decQuad *dq);
uint32_t decQuadIsNegative(const decQuad *dq);

extern const font_t standardFont;
extern const font_t numericFont;
extern uint8_t roundingMode;
extern const enum rounding roundingModeTable[7];

#define REGISTER_SHORT_INTEGER_DATA(a) ((uint64_t *)(getRegisterDataPointer(a)))
#define REGISTER_REAL34_DATA(a) ((real34_t *)(getRegisterDataPointer(a)))
#define REGISTER_IMAG34_DATA(a) ((real34_t *)((uint8_t *)(getRegisterDataPointer(a)) + sizeof(real34_t)))
#define REGISTER_COMPLEX34_DATA(a) ((complex34_t *)(getRegisterDataPointer(a)))
#define REGISTER_STRING_DATA(a) ((char *)(getRegisterDataPointer(a)))
#define REGISTER_MATRIX_HEADER(reg) ((matrixHeader_t *)(getRegisterDataPointer(reg)))
#define const34_86400 ((real34_t *)z47_math_wrappers_const34_86400())
#define amPolarCYL 64
#define amPolarSPH 128
#define TI_REGTYPE 123
#define TI_VECTOR 127
#define getRegisterAngularMode(reg) (getRegisterTag(reg) & amAngleMask)
#define getComplexRegisterAngularMode(reg) (getRegisterTag(reg) & amAngleMask)
#define getComplexRegisterPolarMode(reg) (getRegisterTag(reg) & amPolar)
#define setComplexRegisterAngularMode(reg, am) setRegisterTag((reg), ((am) & amAngleMask) | (getRegisterTag(reg) & amPolar))
#define setComplexRegisterPolarMode(reg, pm) setRegisterTag((reg), ((((pm) & amPolar) != 0) ? (getRegisterTag(reg) & amAngleMask) : amNone) | ((pm) & amPolar))
#define isRegisterMatrix3dVector(reg) ((getRegisterDataType(reg) == dtReal34Matrix) && (((REGISTER_MATRIX_HEADER(reg)->matrixRows == 1) && (REGISTER_MATRIX_HEADER(reg)->matrixColumns == 3)) || ((REGISTER_MATRIX_HEADER(reg)->matrixRows == 3) && (REGISTER_MATRIX_HEADER(reg)->matrixColumns == 1))))
#define isRegisterMatrix2dVector(reg) ((getRegisterDataType(reg) == dtReal34Matrix) && (((REGISTER_MATRIX_HEADER(reg)->matrixRows == 1) && (REGISTER_MATRIX_HEADER(reg)->matrixColumns == 2)) || ((REGISTER_MATRIX_HEADER(reg)->matrixRows == 2) && (REGISTER_MATRIX_HEADER(reg)->matrixColumns == 1))))
#define isRegisterMatrixVector(reg) (isRegisterMatrix3dVector(reg) || isRegisterMatrix2dVector(reg))
#define getVectorRegisterAngularMode(reg) ((getRegisterDataType(reg) == dtReal34Matrix) ? (getRegisterTag(reg) & amAngleMask) : amNone)
#define setVectorRegisterAngularMode(reg, am) setRegisterTag((reg), ((am) & amAngleMask) | (getRegisterTag(reg) & amPolar))
#define getVectorRegisterPolarMode(reg) (((getRegisterDataType(reg) == dtReal34Matrix) && ((getRegisterTag(reg) & amAngleMask) != amNone)) ? (isRegisterMatrix3dVector(reg) ? ((((getRegisterTag(reg) & amPolar) == amPolar)) ? amPolarSPH : amPolarCYL) : (isRegisterMatrix2dVector(reg) ? (getRegisterTag(reg) & amPolar) : 0)) : 0)
static inline void z47_test_setVectorRegisterPolarMode(calcRegister_t reg, uint32_t pm) {
  uint32_t next_tag;

  if(pm == 0) {
    next_tag = (getRegisterTag(reg) & ~(amAngleMask | amPolar)) + amNone;
  }
  else {
    next_tag = (getRegisterTag(reg) & (amAngleMask | amPolar)) | ((pm == amPolarSPH || pm == amPolar) ? amPolar : 0);
    if(pm == amPolarCYL) {
      next_tag &= ((~amPolar) & (amAngleMask | amPolar));
    }
  }

  setRegisterTag(reg, next_tag);
}

#define setVectorRegisterPolarMode(reg, pm) z47_test_setVectorRegisterPolarMode((reg), (pm))
#define getRegisterLongIntegerSign(reg) getRegisterTag(reg)
#define getRegisterShortIntegerBase(reg) getRegisterTag(reg)
#define setRegisterShortIntegerBase(reg, base) setRegisterTag((reg), (base))

void sinCosReal(trigType_t trigType);
void sinCosCplx(trigType_t trigType);
void sinComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
void cosComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
uint8_t TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
uint8_t TanhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
void sinhCoshReal(trigType_t trigType);
void sinhCoshCplx(trigType_t trigType);

void pcg32_srandom(uint64_t initstate, uint64_t initseq);
void pcg32_srandom_r(pcg32_random_t *rng, uint64_t initstate, uint64_t initseq);
uint32_t pcg32_random_r(pcg32_random_t *rng);
void realRandomU01(real_t *res);

void z47_math_wrappers_seed_defaults(uint64_t *seed, uint64_t *seq);
void z47_math_wrappers_do_int_random_i(void);
void longIntegerFibonacci(uint32_t n, longInteger_t result);
void convertTimeRegisterToReal34Register(calcRegister_t source, calcRegister_t destination);
void convertReal34RegisterToTimeRegister(calcRegister_t source, calcRegister_t destination);
void internalDateToJulianDay(real34_t *source, real34_t *destination);
void julianDayToInternalDate(real34_t *source, real34_t *destination);

#endif