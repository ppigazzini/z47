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

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fractions.h"
#include "mathematics/comparisonReals.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

#include <time.h>

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
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnDenMax:", getRegisterDataTypeName(REGISTER_X, true, false), "cannot be converted!", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(realIsNaN(&reX)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnDenMax:", "cannot use NaN as X input of fnDenMax", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if(realIsSpecial(&reX) || realCompareLessThan(&reX, const_1) || realCompareGreaterEqual(&reX, const_9999)) {
    denMax = MAX_DENMAX;
  }
  else {
    int32_t den;

    den = realToInt32C47(&reX);

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



bool_t fraction(calcRegister_t regist, int16_t *sign, uint64_t *intPart, uint64_t *numer, uint64_t *denom, int16_t *lessEqualGreater) {
  // temp0 = fractional_part(absolute_value(real number))
  // temp1 = continued fraction calculation --> fractional_part(1 / temp1)  initialized with temp0
  // delta = difference between the best fraction and the real number

  uint32_t dd = denMax;
  uint32_t denMax;
  if(dd == MAX_DENMAX) {
    denMax = MAX_INTERNAL_DENMAX;
  }
  else {
    denMax = dd;
  }

  real_t temp0;

  if(getRegisterDataType(regist) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(regist), &temp0);
  }
  else {
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "%s cannot be shown as a fraction!", getRegisterDataTypeName(regist, true, false));
      moreInfoOnError("In function fraction:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    *sign             = 0;
    *intPart          = 0;
    *numer            = 0;
    *denom            = 0;
    *lessEqualGreater = 0;

    return false;
  }

  if(realIsZero(&temp0)) {
    *sign             = 0;
    *intPart          = 0;
    *numer            = 0;
    *denom            = 1;
    *lessEqualGreater = 0;

    return false;
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
  ip = realToUint32C47(&temp0);
  *intPart = ip;
  uInt32ToReal(*intPart, &temp3);
  realSubtract(&temp0, &temp3, &temp0, &ctxtReal34);

  //*******************
  //* Any denominator *
  //*******************
  if(getSystemFlag(FLAG_DENANY)) { // denominator up to denMax
    #define OPTIMAL_FRACTION_METHOD 1 // 0=continuous fraction   1=Farey fractions   2=Nigel's method

    #if (OPTIMAL_FRACTION_METHOD != 0) && (OPTIMAL_FRACTION_METHOD != 1) && (OPTIMAL_FRACTION_METHOD != 2)
      #error OPTIMAL_FRACTION_METHOD must be 0, 1 or 2
    #endif // (OPTIMAL_FRACTION_METHOD != 0) && (OPTIMAL_FRACTION_METHOD != 1) && (OPTIMAL_FRACTION_METHOD != 2)

    #if (OPTIMAL_FRACTION_METHOD == 2) // NIGEL'S METHOD
    // see: https://forum.swissmicros.com/viewtopic.php?p=30506#p30506
    // and https://www.hpmuseum.org/forum/thread-20705-post-180180.html#pid180180
    // and https://en.wikipedia.org/wiki/Continued_fraction#Semiconvergents

    // This method should be faster than Farey's fractions method, but it isn't!
    // here the timings:
    //
    // Farey processor time (R103) =    0,077550  π      110 loops
    // Farey processor time (R102) =    0,081307  e³      29 loops
    // Farey processor time (R101) =    0,087934  ln13    25 loops
    // Farey processor time (R100) =    0,024816  1/3      2 loops
    //
    // Nigel processor time (R103) =    0,686072  π        3 loops
    // Nigel processor time (R102) =    2,105902  e³       8 loops
    // Nigel processor time (R101) =    1,933471  ln13     9 loops
    // Nigel processor time (R100) =    0,156097  1/3      1 loop
    //
    // The culprit seems to be realToInt32() that uses decNumberToIntegralValue()…
    // Even with the improved (faster) version of realToInt32C47(), it's still much slower...

    int32_t m, h, h_1, h_2, k, k_1, k_2, a;
    real_t y, this_error, last_error, twoDenMax, temp1, yma;

    realCopy(&temp0, &y);
    int32ToReal(denMax, &twoDenMax);
    realMultiply(&twoDenMax, const_2, &twoDenMax, &ctxtReal39);

    realDivide(const_1, &twoDenMax, &temp1, &ctxtReal39);
    if(realCompareLessThan(&y, &temp1)) {
      *numer = 0;
      *denom = 1; // ...because the number is closer to 0 than to 1/denMax
    }
    else {
      // Start the continued fraction:
      realDivide(const_1, &y, &y, &ctxtReal39); // guaranteed safe; y >= 1/(2*denMax)
      a = realToInt32C47(&y); // this is a1 in the continued fraction

      if(a > (int32_t)denMax) { // return 1/denMax
        *numer = 1;
        *denom = denMax;
      }
      else {
        // h, k are num and den of continued fraction up to this point
        // h_1,k_1 and h_2,k_2 are h,k for the two previous steps.
        // Initialise:
        h_1 = 0;
        k_1 = 1;
        h = 1;
        k = a;

        do {
          // update h, k variables
          h_2 = h_1;
          k_2 = k_1;
          h_1 = h;
          k_1 = k;

          // work out next y, a
          int32ToReal(k_1, &temp1);
          realDivide(&temp1, &twoDenMax, &temp1, &ctxtReal39);
          int32ToReal(a, &yma);
          realSubtract(&y, &yma, &yma, &ctxtReal39);
          if(realCompareLessThan(&yma, &temp1)) {
            // We're about to do new_y = 1/(y-a); new_a = floor(new_y).
            // new_a is used to calculate new values of h and k.
            // If y-a is too small, the new value of k will be too much
            // greater than denMax to be useful. In this algorithm we need
            // to stop if the new value of k is greater than 2*denMax.
            // new_k = new_a * k_1 + k_2;
            // this is true if(y-a) < k_1/(2*denMax)
            // (and it may be true for slightly larger values of (y-a), but
            // this is caught later).
            // In this case, the current convergent is the best rational approximation
            // with denominator < denMax.
            h = h_1;
            k = k_1;
            goto fracEnd;
          }
          realDivide(const_1, &yma, &y, &ctxtReal39);
          a = realToInt32C47(&y); // first time in, this is a2 in the continued fraction.
          // work out new h, k;
          h = a*h_1 + h_2;
          k = a*k_1 + k_2;
        } while(k <= (int32_t)denMax); // when k > denMax, no point in going further.

        // Now k>denMax. h/k is still a convergent, but we can't use it directly.
        // Instead we look for semiconvergents between h_1/k_1 and h/k.
        // A semiconvergent is (m*h_1+h_2)/(m*k_1+k_2), where m is an integer
        // between 1 and a-1.
        // If a/2<m<a, the semiconvergent is a better RA than the previous convergent.
        // If m = a/2, the semiconvergent might be better - need to check.
        // If m<a/2, the previous convergent is the best RA possible.
        // We want a value of m that makes m*k_1+k_2 as big as possible but <= denMax.

        m = (denMax - k_2) / k_1; // integer division ok

        if(m < a / 2) { // use previous convergent
          *numer = h_1;
          *denom = k_1;
        }
        else {
          // This is the semiconvergent
          h = h_2 + m*h_1;
          k = k_2 + m*k_1;

          if(m == a / 2) { // only admissible if better than last time
            int32ToReal(h_1, &last_error);
            int32ToReal(k_1, &temp1);
            realDivide(&last_error, &temp1, &last_error, &ctxtReal39);
            realSubtract(&temp0, &last_error, &last_error, &ctxtReal39);
            realSetPositiveSign(&last_error);

            int32ToReal(h, &this_error);
            int32ToReal(k, &temp1);
            realDivide(&this_error, &temp1, &this_error, &ctxtReal39);
            realSubtract(&temp0, &this_error, &this_error, &ctxtReal39);
            realSetPositiveSign(&this_error);

            if(realCompareLessEqual(&last_error, &this_error)) {
              h = h_1;
              k = k_1;
            }
          }

          // Here, m>a/2, or m=a/2 and better than last time. Use the semiconvergent.
          fracEnd:
          *numer = h;
          *denom = k;
        }
      }
    }
    #endif // OPTIMAL_FRACTION_METHOD == 2

    #if (OPTIMAL_FRACTION_METHOD == 1) // FAREY FRACTIONS
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
    #endif // OPTIMAL_FRACTION_METHOD == 1

    #if (OPTIMAL_FRACTION_METHOD == 0) // OLD CONTINUOUS FACTION CODE RESULTING IN SUB-OPTIMAL FRACTIONS
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
      ip = realToUint32C47(&temp1);
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
    #endif // OPTIMAL_FRACTION_METHOD == 0
  }

  //*******************
  //* Fix denominator *
  //*******************
  else if(getSystemFlag(FLAG_DENFIX)) { // denominator is D.MAX
    *denom = denMax;

    uInt32ToReal(denMax, &delta);
    realFMA(&delta, &temp0, const_1on2, &temp3, &ctxtReal34);
    ip = realToUint32C47(&temp3);
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
        ip = realToUint32C47(&temp3);
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
  real_t f, d, n;
  uInt32ToReal(*intPart, &f);
  uInt32ToReal(*denom, &d);
  realMultiply(&f, &d, &f, &ctxtReal39);
  uInt32ToReal(*numer, &n);
  realAdd(&f, &n, &f, &ctxtReal39);
  realDivide(&f, &d, &f, &ctxtReal39);
  if(*sign == -1) {
    realChangeSign(&f);
  }

  realSubtract(&f, &r, &f, &ctxtReal39);
  real_t roundingTolerance;
  fractionTolerence(&roundingTolerance);                              //Arrive here if a tolerance for lying is set

  
  if( ((fractionDigits == 0 || fractionDigits == 34) && realIsZero(&f)) ||
      ((fractionDigits >= 1 && fractionDigits <= 33) && realCompareAbsLessThan(&f,&roundingTolerance)) ) { //broaden the range for it to be deemed zero

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

  if(fractionDigits == 0 || fractionDigits == 34) {                  //Returns true to prepend the tags, if FDIGS=34 is normal, i.e. no lying
    return true;
  }
  else {                                                             //Checks if within tolerance for FDIGS<=32
    return realCompareAbsGreaterThan(&f,&roundingTolerance);           //return true to prepend tags, if actual fraction is outside of tolerance
  }                                                                    //return false to not prepend tags, if actual fraction is within the tolerance
}
