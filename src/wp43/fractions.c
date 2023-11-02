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

#include <math.h>
#include "fractions.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "mathematics/comparisonReals.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



void fnDenMax(uint16_t D) {
  denMax = D;
  if(denMax < 2) {
    denMax = 2;
  }
}

/* Replaces in favour of TAM selection
  real_t reX;

  if(!saveLastX()) {
    return;
  }

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &reX);
  }
  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToReal(REGISTER_X, &reX, &ctxtReal39);
  }
  else if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    convertShortIntegerRegisterToReal(REGISTER_X, &reX, &ctxtReal39);
  }
  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnDenMax:", getRegisterDataTypeName(REGISTER_X, true, false), "cannot be converted!", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(realIsNaN(&reX)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnDenMax:", "cannot use NaN as X input of fnDenMax", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(realIsSpecial(&reX) || realCompareLessThan(&reX, const_1) || realCompareGreaterEqual(&reX, const_9999)) {
    denMax = MAX_DENMAX;
  }
  else {
    int32_t den;

    realToInt32(&reX, den);

    if(den == 1) {
      longInteger_t lgInt;

      longIntegerInit(lgInt);
      uIntToLongInteger(denMax, lgInt);
      convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
      longIntegerFree(lgInt);
    }
    else {
      denMax = den;
    }
  }
}
*/



void fraction(calcRegister_t regist, int16_t *sign, uint64_t *intPart, uint64_t *numer, uint64_t *denom, int16_t *lessEqualGreater) {
  // temp0 = fractional_part(absolute_value(real number))
  // temp1 = continued fraction calculation --> fractional_part(1 / temp1)  initialized with temp0
  // delta = difference between the best fraction and the real number

  real_t temp0;

  if(getRegisterDataType(regist) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(regist), &temp0);
  }
  else {
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "%s cannot be shown as a fraction!", getRegisterDataTypeName(regist, true, false));
      moreInfoOnError("In function fraction:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    *sign             = 0;
    *intPart          = 0;
    *numer            = 0;
    *denom            = 0;
    *lessEqualGreater = 0;

    return;
  }

  if(realIsZero(&temp0)) {
    *sign             = 0;
    *intPart          = 0;
    *numer            = 0;
    *denom            = 1;
    *lessEqualGreater = 0;

    return;
  }

  if(realIsNegative(&temp0)) {
    *sign = -1;
    realSetPositiveSign(&temp0);
  }
  else {
    *sign = 1;
  }

  real_t delta, temp3;
  realPlus(const_9999, &delta, &ctxtReal34);

  uint32_t ip;
  bool_t of;
  realToUInt32(&temp0, DEC_ROUND_DOWN, &ip, &of);
  *intPart = ip;
  uInt32ToReal(*intPart, &temp3);
  realSubtract(&temp0, &temp3, &temp0, &ctxtReal34);

  //*******************
  //* Any denominator *
  //*******************
  if(getSystemFlag(FLAG_DENANY)) { // denominator up to D.MAX
    #define OPTIMAL_FRACTIONS 1
    #if OPTIMAL_FRACTIONS == 1
    // see: https://math.stackexchange.com/questions/2438510/can-i-find-the-closest-rational-to-any-given-real-if-i-assume-that-the-denomina
    // and https://www.johndcook.com/blog/2010/10/20/best-rational-approximation/#comment-1077474

    uint32_t a=0, b=1, c=1, d=1, oldA=0, oldB=0, oldC=0, oldD=0;
    bool_t exactValue = false;
    real_t mediant, temp1;

    //printf("\n\n\n====================================================================================================\n");
    //printf("denMax = %u   sign = %d   intPart = %" PRIu64, denMax, *sign, *intPart);
    //printRealToConsole(&temp0, "   fracPart", "\n");
    while(b <= denMax && d <= denMax) {
      oldA = a;
      oldB = b;
      oldC = c;
      oldD = d;


      // mediant = (a+c) / (b+d)
      int32ToReal(a + c, &mediant);
      int32ToReal(b + d, &temp1);
      realDivide(&mediant, &temp1, &mediant, &ctxtReal34);

      realSubtract(&mediant, &temp0, &delta, &ctxtReal34);
      if(realIsZero(&delta)) {
        exactValue = true;
        if(b + d <= denMax) {
          *numer = a + c;
          *denom = b + d;
        }
        else if(d > b) {
          *numer = c;
          *denom = d;
        }
        else {
          *numer = a;
          *denom = b;
        }
        break;
      }
      else if(realIsNegative(&delta)) {
        a += c;
        b += d;
      }
      else {
        c += a;
        d += b;
      }
      //printf("   %u/%u   %u/%u\n", a, b, c, d);
    }

    if(!exactValue) {
      // mediant = |fracPart - oldC/oldD|
      int32ToReal(oldC, &mediant);
      int32ToReal(oldD, &temp1);
      realDivide(&mediant, &temp1, &mediant, &ctxtReal34);
      realSubtract(&temp0, &mediant, &mediant, &ctxtReal34);
      realSetPositiveSign(&mediant);

      // delta = |fracPart - oldA/oldB|
      int32ToReal(oldA, &delta);
      int32ToReal(oldB, &temp1);
      realDivide(&delta, &temp1, &delta, &ctxtReal34);
      realSubtract(&temp0, &delta, &delta, &ctxtReal34);
      realSetPositiveSign(&delta);

      if(realCompareLessThan(&mediant, &delta)) {
        *numer = oldC;
        *denom = oldD;
      }
      else {
        *numer = oldA;
        *denom = oldB;
      }
    }

    #else // OPTIMAL_FRACTIONS != 1  OLD CODE RESULTING IN SUB-OPTIMAL FRACTIONS
    uint64_t iPart[20], ex, bestNumer=0, bestDenom=1;
    uint32_t invalidOperation;
    int16_t i, j;

    real_t temp1, temp4;

    // Calculate the continued fraction
    *denom = 1;
    i = 0;
    iPart[0] = *intPart;

    realCopy(&temp0, &temp1);

    if(realCompareAbsLessThan(&temp1, const_1e_6)) {
      realZero(&temp1);
    }

    decContextClearStatus(&ctxtReal34, DEC_Invalid_operation);
    invalidOperation = 0;
    while(*denom < denMax && !realIsZero(&temp1) && !invalidOperation) {
      realDivide(const_1, &temp1, &temp1, &ctxtReal34);
      realToUInt32(&temp1, DEC_ROUND_DOWN, &ip, &of);
      iPart[++i] = ip;
      uInt32ToReal(iPart[i], &temp3);
      invalidOperation = decContextGetStatus(&ctxtReal34) & DEC_Invalid_operation;
      decContextClearStatus(&ctxtReal34, DEC_Invalid_operation);
      realSubtract(&temp1, &temp3, &temp1, &ctxtReal34);
      if(realCompareAbsLessThan(&temp1, const_1e_6)) {
        realZero(&temp1);
      }

      *numer = 1;
      *denom = iPart[i];
      for(j=i; j>1; j--) {
        *numer += *denom * iPart[j-1];
        ex = *numer; *numer = *denom; *denom = ex;
      }

      if(*denom <= denMax) {
        uInt32ToReal(*numer, &temp3);
        uInt32ToReal(*denom, &temp4);
        realDivide(&temp3, &temp4, &temp3, &ctxtReal34);
        realSubtract(&temp3, &temp0, &temp3, &ctxtReal34);
        realSetPositiveSign(&temp3);
        realSubtract(&temp3, &delta, &temp3, &ctxtReal34);
        if(realIsNegative(&temp3)) {
          realAdd(&temp3, &delta, &delta, &ctxtReal34);
          bestNumer = *numer;
          bestDenom = *denom;
        }
      }

      *numer = 1;
      *denom = iPart[i] + 1;
      for(j=i; j>1; j--) {
        *numer += *denom * iPart[j-1];
        ex = *numer; *numer = *denom; *denom = ex;
      }

      if(*denom <= denMax) {
        uInt32ToReal(*numer, &temp3);
        uInt32ToReal(*denom, &temp4);
        realDivide(&temp3, &temp4, &temp3, &ctxtReal34);
        realSubtract(&temp3, &temp0, &temp3, &ctxtReal34);
        realSetPositiveSign(&temp3);
        realSubtract(&temp3, &delta, &temp3, &ctxtReal34);
        if(realIsNegative(&temp3)) {
          realAdd(&temp3, &delta, &delta, &ctxtReal34);
          bestNumer = *numer;
          bestDenom = *denom;
        }
      }
    }

    *numer = bestNumer;
    *denom = bestDenom;

    if(*numer == 1 && *denom == 1) {
      *numer = 0;
      *intPart += 1;
    }
    #endif // OPTIMAL_FRACTIONS == 1
  }

  //*******************
  //* Fix denominator *
  //*******************
  else if(getSystemFlag(FLAG_DENFIX)) { // denominator is D.MAX
    *denom = denMax;

    uInt32ToReal(denMax, &delta);
    realFMA(&delta, &temp0, const_1on2, &temp3, &ctxtReal34);
    realToUInt32(&temp3, DEC_ROUND_DOWN, &ip, &of);
    *numer = ip;
  }

  //******************************
  //* Factors of max denominator *
  //******************************
  else { // denominator is a factor of D.MAX
    uint64_t bestNumer=0, bestDenom=1;

    real_t temp4;

    // TODO: we can certainly do better here
    for(uint32_t i=1; i<=denMax; i++) {
      if(denMax % i == 0) {
        uInt32ToReal(i, &temp4);
        realFMA(&temp4, &temp0, const_1on2, &temp3, &ctxtReal34);
        realToUInt32(&temp3, DEC_ROUND_DOWN, &ip, &of);
        *numer = ip;

        uInt32ToReal(*numer, &temp3);
        uInt32ToReal(i, &temp4);
        realDivide(&temp3, &temp4, &temp3, &ctxtReal34);
        realSubtract(&temp3, &temp0, &temp3, &ctxtReal34);
        realSetPositiveSign(&temp3);
        realSubtract(&temp3, &delta, &temp3, &ctxtReal34);
        if(realIsNegative(&temp3)) {
          realAdd(&temp3, &delta, &delta, &ctxtReal34);
          bestNumer = *numer;
          bestDenom = i;
        }
      }
    }

    *numer = bestNumer;
    *denom = bestDenom;
  }

  // The register value
  real_t r;
  real34ToReal(REGISTER_REAL34_DATA(regist), &r);

  // The fraction value
  real_t f, d;
  uInt32ToReal(*intPart, &f);
  uInt32ToReal(*denom, &d);
  realMultiply(&f, &d, &f, &ctxtReal39);
  uInt32ToReal(*numer, &d);
  realAdd(&f, &d, &f, &ctxtReal39);
  uInt32ToReal(*denom, &d);
  realDivide(&f, &d, &f, &ctxtReal39);
  if(*sign == -1) {
    realChangeSign(&f);
  }

  realSubtract(&f, &r, &f, &ctxtReal39);

  if(realIsZero(&f)) {
    *lessEqualGreater = 0;
  }
  else if(realIsNegative(&f)) {
    *lessEqualGreater = -1;
  }
  else {
    *lessEqualGreater = 1;
  }

  if(!getSystemFlag(FLAG_PROPFR)) { // d/c
    *numer += *denom * *intPart;
    *intPart = 0;
  }
}
