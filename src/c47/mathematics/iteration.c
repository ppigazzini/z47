/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file iteration.c
 ***********************************************/

#include "mathematics/iteration.h"

#include "constantPointers.h"
#include "error.h"
#include "mathematics/compare.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/incDec.h"
#include "registers.h"

#include "c47.h"



#define ITER_ISE ((INC_FLAG << 2) | 0)
#define ITER_ISG ((INC_FLAG << 2) | 1)
#define ITER_ISZ ((INC_FLAG << 2) | 2)
#define ITER_DSE ((DEC_FLAG << 2) | 0)
#define ITER_DSL ((DEC_FLAG << 2) | 1)
#define ITER_DSZ ((DEC_FLAG << 2) | 2)

static void getIterParam(uint16_t regist, real34_t *fp, real34_t *target, real34_t *step) {
  real34_t tmpval;

  if(getRegisterDataType(regist) == dtReal34) {
    real34ToIntegralValue(REGISTER_REAL34_DATA(regist), fp, DEC_ROUND_DOWN);
    real34Subtract(REGISTER_REAL34_DATA(regist), fp, fp);
    real34SetPositiveSign(fp);
    int32ToReal34(1000, &tmpval);
    real34Multiply(fp, &tmpval, target);
    real34Copy(target, step);
    real34ToIntegralValue(target, target, DEC_ROUND_DOWN);
    real34Subtract(step, target, step);
    int32ToReal34(100, &tmpval);
    real34Multiply(step, &tmpval, step);
    real34ToIntegralValue(step, step, DEC_ROUND_DOWN);
    if(real34IsZero(step)) {
      real34Copy(const34_1, step);
    }
  }
  else {
    real34Copy(const34_0, fp);
    real34Copy(const34_0, target);
    real34Copy(const34_1, step);
  }
}



static void incDecAndCompare(uint16_t regist, uint16_t mode) {
  real34_t fp, step;
  int8_t compared;

  reallocateRegister(TEMP_REGISTER_1, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  getIterParam(regist, &fp, REGISTER_REAL34_DATA(TEMP_REGISTER_1), &step);
  switch(getRegisterDataType(regist)) {
    case dtLongInteger: {
      incDecLonI(regist, mode >> 2);
      registerCmpLonIReal(regist, TEMP_REGISTER_1, &compared);
      break;
    }
    case dtShortInteger: {
      incDecShoI(regist, mode >> 2);
      registerCmpShoIReal(regist, TEMP_REGISTER_1, &compared);
      break;
    }
    case dtReal34: {
      if((mode & 2) == 2) {
        real34Copy(const34_1, &step);
        incDecReal(regist, mode >> 2);
        compared = real34CompareAbsLessThan(REGISTER_REAL34_DATA(regist), const34_1) ? 0 : 1;
        break;
      }
      else if(getRegisterAngularMode(regist) == amNone) {
        real34ToIntegralValue(REGISTER_REAL34_DATA(regist), REGISTER_REAL34_DATA(regist), DEC_ROUND_DOWN);
        if((mode >> 2) == DEC_FLAG) {
          real34SetNegativeSign(&step);
        }
        real34Add(REGISTER_REAL34_DATA(regist), &step, REGISTER_REAL34_DATA(regist));
        registerCmpRealReal(regist, TEMP_REGISTER_1, &compared);
        if(real34IsNegative(REGISTER_REAL34_DATA(regist))) {
          real34SetNegativeSign(&fp);
        }
        real34Add(REGISTER_REAL34_DATA(regist), &fp, REGISTER_REAL34_DATA(regist));
        break;
      }
    /* fallthrough */
    }
    default: {
      goto invalidType;
    }
  }
  if(compared > 0) {
    SET_TI_TRUE_FALSE(!((mode & 6) == (INC_FLAG << 2)));
  }
  else if(compared < 0) {
    SET_TI_TRUE_FALSE(!((mode & 6) == (DEC_FLAG << 2)));
  }
  else { // compared==0
    SET_TI_TRUE_FALSE( ((mode & 1) !=              0 ));
  }
  return;

invalidType:
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "incompatible type for iterator.");
    moreInfoOnError("In function incDecAndCompare:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  return;
}



void fnIse(uint16_t regist) {
  incDecAndCompare(regist, ITER_ISE);
}

void fnIsg(uint16_t regist) {
  incDecAndCompare(regist, ITER_ISG);
}

void fnIsz(uint16_t regist) {
  incDecAndCompare(regist, ITER_ISZ);
}

void fnDse(uint16_t regist) {
  incDecAndCompare(regist, ITER_DSE);
}

void fnDsl(uint16_t regist) {
  incDecAndCompare(regist, ITER_DSL);
}

void fnDsz(uint16_t regist) {
  incDecAndCompare(regist, ITER_DSZ);
}


#undef ITER_ISE
#undef ITER_ISG
#undef ITER_ISZ
#undef ITER_DSE
#undef ITER_DSL
#undef ITER_DSZ
