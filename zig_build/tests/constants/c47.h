// SPDX-License-Identifier: GPL-3.0-only

#if !defined(C47_H)
#define C47_H

#include <stdbool.h>
#include <inttypes.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;

typedef struct {
  uint16_t id;
} real_t;

typedef real_t real34_t;

typedef enum {
  dtLongInteger = 0,
  dtReal34 = 1,
} dataType_t;

typedef enum {
  amRadian = 0,
  amGrad = 1,
  amDegree = 2,
  amDMS = 3,
  amMultPi = 4,
  amNone = 5,
} angularMode_t;

#define REGISTER_X ((calcRegister_t)100)
#define NOUC 84
#define SOLVER_STATUS_READY_TO_EXECUTE 0x0001
#define EXTRA_INFO_ON_CALC_ERROR 1

extern uint16_t currentSolverStatus;
extern char errorMessage[256];
extern const real_t *realtConstants[NOUC];
extern const real_t *const39_pi;

real34_t *z47_constants_test_register_real34_data(calcRegister_t reg);

#define REGISTER_REAL34_DATA(reg) z47_constants_test_register_real34_data(reg)

void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4);
void liftStack(void);
void reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag);
void realToReal34(const real_t *source, real34_t *destination);
void convertRealToResultRegister(const real_t *source, calcRegister_t dest, angularMode_t angle);
void adjustResult(calcRegister_t res,
                  bool_t dropY,
                  bool_t setCpxRes,
                  calcRegister_t op1,
                  calcRegister_t op2,
                  calcRegister_t op3);
void setLastintegerBasetoZero(void);

#endif