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

// A placeholder for c43's decNumber. The lane links c43's own constant blob, so
// a real_t inside it is a view onto bytes this mock cannot decode -- and does
// not need to. What a case has to know is WHICH constant a call reached, so the
// placeholder carries that constant's byte offset in the blob and nothing else.
typedef struct {
  uint16_t constant_offset;
} real_t;

typedef real_t real34_t;

// c43 puts the generated tables in QSPI on the DMCP builds; a PC build leaves
// the attribute empty. The generated sources this lane compiles carry it.
#define TO_QSPI

// c43's generated blob header. It declares `constants` and every const*_ macro
// over it, const39_pi among them: pi is a macro at a fixed offset, not a link
// symbol, and fnPi names it instead of indexing realtConstants. Including the
// generated header means the offset is the generator's own and moves when the
// blob is regenerated, which a `#define` written out here could not do.
//
// realtConstants is deliberately absent: c43's constants.c declares it and the
// generated constantPointers2.c defines it.
#include "constantPointers.h"

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
// NOUC also sizes the generated constantPointers2.c table this lane compiles.
// That source is built with -Werror=excess-initializers, so a NOUC that has
// fallen behind c43's fails the build instead of truncating the table.
#define NOUC 84
#define SOLVER_STATUS_READY_TO_EXECUTE 0x0001
#define EXTRA_INFO_ON_CALC_ERROR 1

extern uint16_t currentSolverStatus;
extern char *errorMessage;

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
