// SPDX-License-Identifier: GPL-3.0-only

#ifndef Z47_MATH_WRAPPERS_C47_H
#define Z47_MATH_WRAPPERS_C47_H

#include <stdbool.h>
#include <stdint.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;

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

#define REGISTER_X ((calcRegister_t)100)
#define REGISTER_Y ((calcRegister_t)101)

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

void sinhCoshReal(trigType_t trigType);
void sinhCoshCplx(trigType_t trigType);

#endif