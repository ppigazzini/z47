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
 * \file random.c
 ***********************************************/

#include "mathematics/random.h"

#include "config.h"
#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "memory.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"
#include "timer.h"

#include "c47.h"

//////////////////////////////////////////////////////////
// Fast Random Integer Generation in an Interval
// DANIEL LEMIRE, Université du Québec (TELUQ), Canada
// https://arxiv.org/abs/1805.10941
uint32_t boundedRand(uint32_t s) { // random integer in [0 , s)
  uint32_t x = pcg32_random_r(&pcg32_global);
  uint64_t m = (uint64_t)x * (uint64_t)s;
  uint32_t l = (uint32_t) m;

  if(l < s) {
    uint32_t t = (-s) % s;
    while(l < t) {
      x = pcg32_random_r(&pcg32_global);
      m = (uint64_t) x *(uint64_t)s;
      l = (uint32_t)m;
    }
  }
  return m >> 32;
}



void fnRandomI(uint16_t unusedButMandatoryParameter) {
  longInteger_t regX, regY, mini, maxi;
  uint32_t maxRand;
  int32_t cmp;

  if(getRegisterDataType(REGISTER_X) != dtLongInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RANI# with %s in X", getRegisterDataTypeName(REGISTER_X, true, false));
      moreInfoOnError("In function fnRandomI:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(getRegisterDataType(REGISTER_Y) != dtLongInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot RANI# with %s in Y", getRegisterDataTypeName(REGISTER_Y, true, false));
      moreInfoOnError("In function fnRandomI:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  convertLongIntegerRegisterToLongInteger(REGISTER_X, regX);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, regY);

  cmp = longIntegerCompare(regX, regY);
  if(cmp == 0) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnRandomI:", "cannot RANI# with X = Y", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  longIntegerInit(mini);
  longIntegerInit(maxi);
  if(cmp < 0) {
    longIntegerCopy(regX, mini);
    longIntegerCopy(regY, maxi);
  }
  else {
    longIntegerCopy(regX, maxi);
    longIntegerCopy(regY, mini);
  }

  longIntegerSubtract(maxi, mini, regX);
  longIntegerAddUInt(regX, 1, regX);
  if(longIntegerCompareUInt(regX, 0xFFFFFFFF) >= 0) { // 2^32 - 1
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnRandomI:", "cannot RANI# with |X - Y| >= 2^32", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  longIntegerToUInt(regX, maxRand);
  longIntegerAddUInt(mini, boundedRand(maxRand), maxi);

  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  convertLongIntegerToLongIntegerRegister(maxi, REGISTER_X);

  longIntegerFree(regX);
  longIntegerFree(regY);
  longIntegerFree(maxi);
  longIntegerFree(mini);
}



/////////////////////////////////////////////////////////////////////////////
// Method for pseudo random number generation: http://www.pcg-random.org/

void fnRandom(uint16_t unusedButMandatoryParameter) {
  real_t x1, x2;

  uInt32ToReal(boundedRand(100000000),  &x1);
  uInt32ToReal(boundedRand(100000000),  &x2);
  realFMA(const_1e8, &x1, &x2, &x1, &ctxtReal39);
  uInt32ToReal(boundedRand(1000000000), &x2);
  realFMA(const_1e9, &x1, &x2, &x1, &ctxtReal39);
  uInt32ToReal(boundedRand(1000000000), &x2);
  realFMA(const_1e9, &x1, &x2, &x1, &ctxtReal39);
  x1.exponent -= 34;

  liftStack();
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  convertRealToReal34ResultRegister(&x1, REGISTER_X);

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



void fnSeed(uint16_t unusedButMandatoryParameter) {
  uint64_t seed=0, sequ=0;

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    if(!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
      seed = *(uint64_t *)getRegisterDataPointer(REGISTER_X);          // First 64 bits of the real34_t
      sequ = *(((uint64_t *)getRegisterDataPointer(REGISTER_X)) + 1);  // Last  64 bits of the real34_t
    }
  }
  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    if(getRegisterLongIntegerSign(REGISTER_X) != LI_ZERO) {
      seed = *(uint64_t *)getRegisterDataPointer(REGISTER_X);          // First 64 bits of the long integer
      sequ = *(((uint64_t *)getRegisterDataPointer(REGISTER_X)) + 1);  // Second 64 bits of the long integer
    }
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "cannot use %s as a seed for the RNG!\n it must be a SP or DP real or a long integer", getDataTypeName(getRegisterDataType(REGISTER_X), true, false));
      moreInfoOnError("In function fnSeed:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(seed == 0 && sequ == 0) {
    #if defined(TESTSUITE_BUILD)
      seed = 0xDeadBeef;
      sequ = 0xBadCafeFace;
    #else // !TESTSUITE_BUILD
      seed = (((uint64_t)getUptimeMs()) << 32) + (uint64_t)getFreeRamMemory();
      sequ = (((uint64_t)getUptimeMs()) << 32) + (uint64_t)getFreeFlash();
    #endif // TESTSUITE_BUILD
  }

  pcg32_srandom(seed, sequ);
}
