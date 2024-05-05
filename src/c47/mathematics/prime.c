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
 * \file prime.c
 ***********************************************/

#include "mathematics/prime.h"

#include "c43Extensions/addons.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "integers.h"
#include "matrix.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "display.h"
#include "screen.h"
#include "statusBar.h"
#include <string.h>

#include "c47.h"


/*
// primes less than 212
TO_QSPI const uint8_t smallPrimes[] = {   2,   3,   5,   7,  11,  13,  17,  19,  23,  29,  31,  37,
                                         41,  43,  47,  53,  59,  61,  67,  71,  73,  79,  83,  89,
                                         97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
                                        157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211      };

// pre-calced sieve of Eratosthenes for n = 2, 3, 5, 7
TO_QSPI const uint8_t indices[] = {   1,  11,  13,  17,  19,  23,  29,  31,  37,  41,  43,  47,
                                     53,  59,  61,  67,  71,  73,  79,  83,  89,  97, 101, 103,
                                    107, 109, 113, 121, 127, 131, 137, 139, 143, 149, 151, 157,
                                    163, 167, 169, 173, 179, 181, 187, 191, 193, 197, 199, 209 };

// distances between sieve values
TO_QSPI const uint8_t offsets[] = {  10,   2,   4,   2,   4,   6,   2,   6,   4,   2,   4,   6,
                                      6,   2,   6,   4,   2,   6,   4,   6,   8,   4,   2,   4,
                                      2,   4,   8,   6,   4,   6,   2,   4,   6,   2,   6,   6,
                                      4,   2,   4,   6,   2,   6,   4,   2,   4,   2,  10,   2 };


// Test if a number is prime or not using a Miller-Rabin test
#define QUICK_CHECK (101*101-1)
#define NUMBER_OF_SMALL_PRIMES 25

static bool_t longIntegerIsPrime1(longInteger_t primeCandidate) {
  uint32_t i;
  longInteger_t primeCandidateMinus1, s, temp, smallPrime, mod;

  if(longIntegerCompareUInt(primeCandidate, 2) < 0) {
    return false;
  }

  // Quick check for divisibility by small primes
  for(i=0; i<NUMBER_OF_SMALL_PRIMES; i++) {
    if(longIntegerCompareUInt(primeCandidate, smallPrimes[i]) == 0) {
      return true;
    }
    else if(longIntegerModuloUInt(primeCandidate, smallPrimes[i]) == 0) {
      return false;
    }
  }

  if(longIntegerCompareUInt(primeCandidate, QUICK_CHECK) < 0) {
    return true;
  }

  longIntegerInit(primeCandidateMinus1);
  longIntegerInit(s);
  longIntegerInit(temp);
  longIntegerInit(smallPrime);
  longIntegerInit(mod);
  longIntegerSubtractUInt(primeCandidate, 1, primeCandidateMinus1);
  longIntegerCopy(primeCandidateMinus1, s);

  // Calculate s such as   primeCandidate - 1 = s×2^d and s odd
  while(longIntegerIsEven(s)) {
    longIntegerDivide2Exact(s, s);
  }

  // The loop below should only go from 0 to 12 (primes from 2 to 41) ensuring correct result for candidatePrime < 3 317 044 064 679 887 385 961 981
  // There is a conjecture that when going from 0 to 19 (primes from 2 to 71) the result is correct up to 10^36
  for(i=0; i<NUMBER_OF_SMALL_PRIMES; i++) {
    longIntegerCopy(s, temp);

    uIntToLongInteger(smallPrimes[i], smallPrime);
    longIntegerPowerModulo(smallPrime, temp, primeCandidate, mod);
    while(longIntegerCompare(temp, primeCandidateMinus1) != 0 && longIntegerCompareUInt(mod, 1) != 0 && longIntegerCompare(mod, primeCandidateMinus1) != 0) {
      longIntegerPowerUIntModulo(mod, 2, primeCandidate, mod);
      longIntegerMultiply2(temp, temp);
    }

    if(longIntegerCompare(mod, primeCandidateMinus1) != 0 && longIntegerIsEven(temp)) {
      longIntegerFree(primeCandidateMinus1);
      longIntegerFree(s);
      longIntegerFree(temp);
      longIntegerFree(smallPrime);
      longIntegerFree(mod);
      return false;
    }
  }

  longIntegerFree(primeCandidateMinus1);
  longIntegerFree(s);
  longIntegerFree(temp);
  longIntegerFree(smallPrime);
  longIntegerFree(mod);
  return true;
} */


void fnIsPrime(uint16_t unusedButMandatoryParameter) {
#if !defined(SAVE_SPACE_DM42_12)
  hourGlassIconEnabled = true;
  showHideHourGlass();
  longInteger_t primeCandidate;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    convertShortIntegerRegisterToLongInteger(REGISTER_X, primeCandidate);
  }

  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToLongInteger(REGISTER_X, primeCandidate);
  }

  else if(getRegisterDataType(REGISTER_X) == dtReal34) {
    convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), primeCandidate, DEC_ROUND_DOWN);
  }

  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for PRIME?!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnIsPrime:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto return2;
  }

  longIntegerSetPositiveSign(primeCandidate);
  //temporaryInformation = (longIntegerIsPrime1(primeCandidate) ? TI_TRUE : TI_FALSE);
  //temporaryInformation = (longIntegerIsPrime2(primeCandidate) ? TI_TRUE : TI_FALSE);
  temporaryInformation = (longIntegerIsPrime(primeCandidate) ? TI_TRUE : TI_FALSE);
  longIntegerFree(primeCandidate);
return2:
  hourGlassIconEnabled = false;
  showHideHourGlass();
#endif // !SAVE_SPACE_DM42_12
}


void fnNextPrime(uint16_t unusedButMandatoryParameter) {
#if !defined(SAVE_SPACE_DM42_12)
  hourGlassIconEnabled = true;
  showHideHourGlass();
  longInteger_t currentNumber, nextPrime;

  longIntegerInit(currentNumber);
  longIntegerInit(nextPrime);

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    convertShortIntegerRegisterToLongInteger(REGISTER_X, currentNumber);
  }

  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToLongInteger(REGISTER_X, currentNumber);
  }

  else if(getRegisterDataType(REGISTER_X) == dtReal34) {
    convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), currentNumber, DEC_ROUND_DOWN);
  }

  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for PRIME?!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnIsPrime:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }

  if(!saveLastX()) {
    goto return1;
  }

  longIntegerSetPositiveSign(currentNumber);

  longIntegerNextPrime(currentNumber, nextPrime);

  if(getRegisterDataType(REGISTER_L) == dtShortInteger) {
    convertLongIntegerToShortIntegerRegister(nextPrime, getRegisterShortIntegerBase(REGISTER_L), REGISTER_X);
  }
  else {
    convertLongIntegerToLongIntegerRegister(nextPrime, REGISTER_X);
  }

  longIntegerFree(nextPrime);
  longIntegerFree(currentNumber);
return1:
  hourGlassIconEnabled = false;
  showHideHourGlass();
#endif // !SAVE_SPACE_DM42_12
}


/*
// Baillie-PSW primality test in python found here:
// https://codegolf.stackexchange.com/questions/10701/fastest-code-to-find-the-next-prime
bool_t isStrongProbablePrime(longInteger_t primeCandidate) {
  longInteger_t two, d, x, primeCandidateMinus1;
  int32_t r, s;

  longIntegerInit(d);
  longIntegerSubtractUInt(primeCandidate, 1, d);       // d = primeCandidate - 1;
  longIntegerInit(primeCandidateMinus1);
  longIntegerCopy(d, primeCandidateMinus1);            // primeCandidateMinus1 = primeCandidate - 1
  s = 0;
  while(longIntegerIsEven(d)) {
    s++;
    longIntegerDivide2(d, d);                          // d >>= 1;
  }

  longIntegerInit(two);
  uIntToLongInteger(2, two);                           // two = 2
  longIntegerInit(x);
  longIntegerPowerModulo(two, d, primeCandidate, x);   // x = pow(2, d, primeCandidate);
  longIntegerFree(two);
  longIntegerFree(d);

  if(longIntegerCompareUInt(x, 1) == 0 || longIntegerCompare(x, primeCandidateMinus1) == 0) {
    longIntegerFree(x);
    longIntegerFree(primeCandidateMinus1);
    return true;
  }

  for(r=1; r<s; r++) {
    longIntegerPowerUIntModulo(x, 2, primeCandidate, x); // x = (x * x) % primeCandidate;
    if(longIntegerCompareUInt(x, 1) == 0) {
      longIntegerFree(x);
      longIntegerFree(primeCandidateMinus1);
      return false;
    }
    else if(longIntegerCompare(x, primeCandidateMinus1) == 0) {
      longIntegerFree(x);
      longIntegerFree(primeCandidateMinus1);
      return true;
    }
  }

  longIntegerFree(x);
  longIntegerFree(primeCandidateMinus1);
  return false;
}

// Lucas probable prime
// assumes D = 1 (mod 4), (D|primeCandidate) = -1
bool_t isLucasProbablePrime(longInteger_t primeCandidate, longInteger_t D) {
  longInteger_t Q, s, t, primeCandidatePlus1, inv2, oldU, U, V, q;
  uint32_t r = 0;

  longIntegerInit(Q);                             // Q = 0;
  uIntToLongInteger(1, Q);                        // Q = 1;
  longIntegerSubtract(Q, D, Q);                   // Q = 1 - D;
  longIntegerDivideUInt(Q, 4, Q);                 // Q = (1 - D) >> 2

  // primeCandidate + 1 = 2**r*s where s is odd
  longIntegerInit(s);                             // s = 0;
  longIntegerAddUInt(primeCandidate, 1, s);       // s = primeCandidate + 1
  longIntegerCopy(s, primeCandidatePlus1);        // primeCandidatePlus1 = primeCandidate + 1
  while(longIntegerIsEven(s)) {
    r++;
    longIntegerDivide2(s, s);
  }

  // calculate the bit reversal of (odd) s
  // e.g. 19 (10011) <=> 25 (11001)
  longIntegerInit(t);                             // t = 0;
  while(longIntegerIsPositive(s)) {
    if(longIntegerIsOdd(s)) {
      longIntegerAddUInt(t, 1, t);                // t++;
      longIntegerSubtractUInt(s, 1, s);           // s--;
    }
    else {
      longIntegerMultiply2(t, t);                 // t <<= 1;
      longIntegerDivide2(s, s);                   // s >>= 1;
    }
  }

  // use the same bit reversal process to calculate the sth Lucas number
  // keep track of q = Q**primeCandidate as we go
  longIntegerInit(U);                             // U = 0;
  longIntegerInit(V);                             // V = 0;
  uIntToLongInteger(2, V);                        // V = 2;
  longIntegerInit(q);                             // q = 0;
  uIntToLongInteger(1, q);                        // q = 1;
  // mod_inv(2, primeCandidate)
  longIntegerDivide2(primeCandidatePlus1, inv2);  //inv2 = primeCandidatePlus1 >> 1;
  while(longIntegerIsPositive(t)) {
    if(longIntegerIsOdd(t)) {
      // U, V of primeCandidate+1
      longIntegerCopy(U, oldU);                   // oldU = U;
      longIntegerAdd(oldU, V, U);                 // U =  (oldU + V);
      longIntegerMultiply(U, inv2, U);            // U =  (oldU + V) * inv2;
      longIntegerModulo(U, primeCandidate, U);    // U = ((oldU + V) * inv2) % primeCandidate;

      longIntegerMultiply(D, oldU, oldU);         // oldU = D * oldU;
      longIntegerAdd(oldU, V, V);                 // V =   D * oldU + V;
      longIntegerMultiply(V, inv2, V);            // V =  (D * oldU + V) * inv2;
      longIntegerModulo(V, primeCandidate, V);    // V = ((D * oldU + V) * inv2) % primeCandidate;

      longIntegerMultiply(q, Q, q);               // q = q * Q;
      longIntegerModulo(q, primeCandidate, q);    // q = (q * Q) % primeCandidate;
      longIntegerSubtractUInt(t, 1, t);           // t--;
    }
    else {
      // U, V of primeCandidate * 2
      longIntegerMultiply(U, V, U);               // U =  U * V;
      longIntegerModulo(U, primeCandidate, U);    // U = (U * V) % primeCandidate;

      longIntegerMultiply(V, V, V);               // V = V * V;
      longIntegerMultiply2(q, oldU);              // oldU = 2 * q;
      longIntegerSubtract(V, oldU, V);            // V =  V * V - 2 * q;
      longIntegerModulo(V, primeCandidate, V);    // V = (V * V - 2 * q) % primeCandidate;

      longIntegerMultiply(q, q, q);               // q = q * q;
      longIntegerModulo(q, primeCandidate, q);    // q = (q * q) % primeCandidate;

      longIntegerDivide2(t, t);                   // t >>= 1;
    }
  }

  // double s until we have the 2**r*sth Lucas number
  while(r > 0) {
    longIntegerMultiply(U, V, U);                 // U =  U * V;
    longIntegerModulo(U, primeCandidate, U);      // U = (U * V) % primeCandidate;

    longIntegerMultiply(V, V, V);                 // V = V * V;
    longIntegerMultiply2(q, oldU);                // oldU = 2 * q;
    longIntegerSubtract(V, oldU, V);              // V =  V * V - 2 * q;
    longIntegerModulo(V, primeCandidate, V);      // V = (V * V - 2 * q) % primeCandidate;

    longIntegerMultiply(q, q, q);                 // q = q * q;
    longIntegerModulo(q, primeCandidate, q);      // q = (q * q) % primeCandidate;

    r--;
  }

  // primality check
  // if primeCandidate is prime, primeCandidate divides the primeCandidate+1st Lucas number, given the assumptions
  return (longIntegerIsZero(U));
}


// an 'almost certain' primality check
bool_t longIntegerIsPrime2(longInteger_t primeCandidate) {
  longInteger_t primeCandidateMinus1, primeCandidateMinus1on2, a, s, temp;
  uint32_t i, j, pc;

  if(longIntegerCompareUInt(primeCandidate, 212) <= 0) {
    longIntegerToUInt(primeCandidate, pc);
    for(i=0; i<sizeof(smallPrimes)/sizeof(smallPrimes[0]); i++) {
      if(smallPrimes[i] == pc) {
        return true;
      }
    }
    return false;
  }

  for(i=0; i<sizeof(smallPrimes)/sizeof(smallPrimes[0]); i++) {
    if(longIntegerModuloUInt(primeCandidate, smallPrimes[i]) == 0) {
      return false;
    }
  }

  // if primeCandidate is a 32-bit integer, perform full trial division
  if(longIntegerCompareUInt(primeCandidate, 0xffffffff) <= 0) {
    i = 211;
    longIntegerToUInt(primeCandidate, pc);
    while(i*i < pc) {
      for(j=0; j<sizeof(offsets)/sizeof(offsets[0]); j++) {
        i += offsets[j];
        if(pc % i == 0) {
          return false;
        }
      }
    }

    return true;
  }

  // Baillie-PSW: this is technically a probabalistic test, but there are no known pseudoprimes
  if(!isStrongProbablePrime(primeCandidate)) {
    return false;
  }

  longIntegerSubtractUInt(primeCandidate, 1, primeCandidateMinus1); // primeCandidateMinus1 = primeCandidate - 1;
  longIntegerDivide2(primeCandidate, primeCandidateMinus1on2);      // primeCandidateMinus1on2 = (primeCandidate - 1) >> 1
  uIntToLongInteger(2, s);
  uIntToLongInteger(5, a);
  longIntegerPowerModulo(a, primeCandidateMinus1on2, primeCandidate, temp); // temp = Legendre symbol resulting in primeCandidate-1 if a is a non-residue, instead of -1
  while(longIntegerCompare(temp, primeCandidateMinus1) != 0) {
    longIntegerChangeSign(s);     // s = -s;
    longIntegerSubtract(s, a, a); // a = s - a;
    longIntegerPowerModulo(a, primeCandidateMinus1on2, primeCandidate, temp);
  }

  return isLucasProbablePrime(primeCandidate, a);
}

// Next prime strictly larger than currentNumber
void nextPrime(longInteger_t currentNumber, longInteger_t nextPrime) {
  uint32_t cn, i, x, s, e, m, o;

  if(longIntegerCompareUInt(currentNumber, 2) < 0) {
    uIntToLongInteger(2, nextPrime);
    return;
  }

  // first odd larger than currentNumber
  longIntegerAddUInt(currentNumber, 1, currentNumber);
  if(longIntegerIsEven(currentNumber)) {
    longIntegerAddUInt(currentNumber, 1, currentNumber);
  }

  if(longIntegerCompareUInt(currentNumber, 212) < 0) {
    longIntegerToUInt(currentNumber, cn);
    while(true) {
      for(i=0; i<sizeof(smallPrimes)/sizeof(smallPrimes[0]); i++) {
        if(smallPrimes[i] == cn) {
          uIntToLongInteger(cn, nextPrime);
          return;
        }
      }
      longIntegerAddUInt(currentNumber, 2, currentNumber);
    }
  }

  // find our position in the sieve rotation via binary search
  x = longIntegerModuloUInt(currentNumber, 210);
  s = 0;
  e = 47;
  m = 24;
  while(m != e) {
    if(indices[m] < x) {
      s = m;
      m = (s + e + 1) >> 1;
    }
    else {
      e = m;
      m = (s + e) >> 1;
    }
  }

  nextPrime = currentNumber + indices[m] - x;
  while(true) {
    for(o=m; o<m+48; o++) {
      if(longIntegerIsPrime2(nextPrime)) {
        return;
      }
      longIntegerAddUInt(nextPrime, offsets[o % 48], nextPrime);
    }
  }
} */


#if !defined (TESTSUITE_BUILD)
  static void _showProgress(const real34_t *ss, longInteger_t nextp) {
    real34_t rr;
    clearRegisterLine(REGISTER_Z, true, true);
    clearRegisterLine(REGISTER_Y, true, true);
    clearRegisterLine(REGISTER_X, true, true);
    uint8_t savedDisplayFormatDigits = displayFormatDigits;
    displayFormatDigits = 0;
    strcpy(tmpString,"Last =  ");
    real34ToDisplayString(ss, amNone, tmpString+6, &standardFont, 400, 34, false, true);
    showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, true, true);

    longIntegerToAllocatedString(nextp, tmpString, TMP_STR_LENGTH);
    stringToReal34(tmpString, &rr);
    strcpy(tmpString,"p =  ");
    real34ToDisplayString(&rr, amNone, tmpString+3, &standardFont, 400, 34, false, true);
    showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE + 6, vmNormal, true, true);

    refreshRegisterLine(REGISTER_X);

    displayFormatDigits = savedDisplayFormatDigits;
  }
#endif //TESTSUITE_BUILD



#define WGR              //verbose
#undef WGR
#define MAX_FACTORS 100//87

typedef struct FactorAdder
{
  uint16_t nExpons;
  uint16_t expons[MAX_FACTORS];
  longInteger_t lastFactor;
} FactorAdder_t;


static void initFactorAdder(FactorAdder_t *faddr) {
  faddr->nExpons = 0;
  longIntegerInit(faddr->lastFactor);
};

void clearFactorAdder(FactorAdder_t *faddr) {
  longIntegerFree(faddr->lastFactor);
}

void dumpExponents(real34Matrix_t *matrix, FactorAdder_t *faddr, uint16_t dumpForFewerThan) {
  uint16_t n2 = faddr->nExpons;
  #ifdef WGR
    printf("wgr:  fill expons:  *nExpons==%u, n2==%u dump=%u\n", faddr->nExpons, n2, dumpForFewerThan);
    uint16_t cols = REGISTER_DATA(REGISTER_X)->matrixColumns;
    uint16_t rows = REGISTER_DATA(REGISTER_X)->matrixRows;
    printf("wgr:  rows==%u, cols==%u\n", (uint16_t)rows, (uint16_t)cols);
  #endif
  linkToRealMatrixRegister(REGISTER_X,  matrix);
  for( uint16_t i = 0;  i < min(n2,dumpForFewerThan);  ++i ) {
    char expon_str[21];
    sprintf(expon_str, "%u", faddr->expons[i]);
    #ifdef WGR
      printf("wgr:  adding expon at n2==%u, i==%u, val %u, sval %s, ind %u\n", n2, i, faddr->expons[i], expon_str, n2+i);
    #endif //WGR
    stringToReal34(expon_str, &matrix->matrixElements[n2+i]);
  }
}


static bool_t addFactor(longInteger_t lastFactor, longInteger_t factor, real34Matrix_t *matrix, const real34_t *lastAdded,FactorAdder_t *faddr) {
  //printLongIntegerToConsole(factor,"-->","\n");
  #ifdef WGR
    printf("wgr:  addFactor()\n");
  #endif //WGR
  if(getRegisterDataType(REGISTER_X) != dtReal34Matrix) {
    //Initialize Memory for Matrix
    if(initMatrixRegister(REGISTER_X, 2, 0, false)) {
      setSystemFlag(FLAG_ASLIFT);
    }
    else {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
        moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }

  uint16_t rows = REGISTER_DATA(REGISTER_X)->matrixRows;
  uint16_t cols = REGISTER_DATA(REGISTER_X)->matrixColumns;
  if ( faddr->nExpons == 0 ) {
    faddr->nExpons = 1;  // has to be 1 now, as we have this factor
    faddr->expons[(faddr->nExpons)-1] = 1;
  }
  uint16_t wkgCols = faddr->nExpons;
  #ifdef WGR
    gmp_printf("wgr:  factor==%Zd, rows==%u, cols==%u, nExpons==%u, wkgCols==%u\n",factor, (uint16_t)rows, (uint16_t)cols, faddr->nExpons, wkgCols);
  #endif //WGR

  #if !defined(TESTSUITE_BUILD)
    if(!redimMatrixRegister(REGISTER_X, rows, wkgCols)) {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
        moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return false;
    }
  #endif // !TESTSUITE_BUILD

  if ( cols == 0 ) {
    #ifdef WGR
      printf("wgr:  zeroing lastFactor\n");
    #endif //WGR
    uIntToLongInteger(0,lastFactor);
  }
  linkToRealMatrixRegister(REGISTER_X,  matrix);
  #ifdef WGR
    gmp_printf("wgr:  lastFactor==%Zd\n", lastFactor);
  #endif //WGR
  uint16_t n = rows*(faddr->nExpons);
  uint16_t c = n/2;
  if ( longIntegerSign(lastFactor) != 0 && longIntegerCompare(lastFactor, factor) == 0 ) {
    ++faddr->expons[(faddr->nExpons)-1];
    #ifdef WGR
      printf("wgr:  lastFactor use existing:  created expons %u at %u\n",faddr->expons[(faddr->nExpons)-1], (faddr->nExpons)-1);
    #endif
  }
  else {
    bool_t incNExpons = longIntegerSign(lastFactor) ==0 ? false : true;
    if ( !incNExpons ) {
      c = 0;
    }
    #ifdef WGR
      printf("wgr:  lastFactor restart:  n==%u, c==%u, incNExpons==%d\n", n, c, incNExpons);
    #endif
    longIntegerToAllocatedString(factor, tmpString, TMP_STR_LENGTH);
    stringToReal34(tmpString, &matrix->matrixElements[c]);
    #ifdef WGR
      printf("wgr:  tmpString from lastAdded:  %s\n", tmpString);
    #endif
    real34Copy(&matrix->matrixElements[c], lastAdded);
    if ( incNExpons ) {
      if ( faddr->nExpons < MAX_FACTORS ) {
          ++faddr->nExpons;
      } else {
        #if !defined(TESTSUITE_BUILD)
          displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "Maximum number of factors exceeded %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
            moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return false;
        #endif // !TESTSUITE_BUILD
      }
      ++wkgCols;
      faddr->expons[faddr->nExpons-1] = 1;
      #if !defined(TESTSUITE_BUILD)
        if(!redimMatrixRegister(REGISTER_X, rows, wkgCols)) {
          displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
            moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return false;
        }
      #endif // !TESTSUITE_BUILD
    }
    n = rows*(faddr->nExpons);
    c = n/2;
    longIntegerCopy(factor, lastFactor);
  }
  return true;
}



void fnPrimeFactors (uint16_t unusedButMandatoryParameter) {
  hourGlassIconEnabled = true;
  showHideHourGlass();
  currentKeyCode = 255;
  #if !defined(TESTSUITE_BUILD)
    uint32_t loop = 0;
  #endif //TESTSUITE_BUILD
  real34_t m34, lastAdded;

  longInteger_t lastFactor, currentNumber, nextPrime, remainder, quotient, eval, temp;

  longIntegerInit(currentNumber);
  longIntegerInit(nextPrime);
  longIntegerInit(remainder);
  longIntegerInit(quotient);
  longIntegerInit(eval);
  longIntegerInit(temp);
  longIntegerInit(lastFactor);
  real34Matrix_t matrix;

  if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
    convertShortIntegerRegisterToLongInteger(REGISTER_X, currentNumber);
  }
  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {
    convertLongIntegerRegisterToLongInteger(REGISTER_X, currentNumber);
  }
  else if(getRegisterDataType(REGISTER_X) == dtReal34) {
    real34ToIntegralValue(REGISTER_REAL34_DATA(REGISTER_X), &m34, DEC_ROUND_UP);
    real34Subtract(REGISTER_REAL34_DATA(REGISTER_X), &m34, &m34); // Fractional part
    if(!real34IsZero(&m34)) {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      #if defined(PC_BUILD)
        sprintf(errorMessage, "DataType %" PRIu32, getRegisterDataType(REGISTER_X));
        moreInfoOnError("In function fnPrimeFactors:", errorMessage, "has decimals and cannot have prime factors.", "");
      #endif
      goto abort;
    }
    convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), currentNumber, DEC_ROUND_DOWN);
  }

  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "the input type %s is not allowed for FACTORS!", getDataTypeName(getRegisterDataType(REGISTER_X), false, false));
      moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto abort;
  }

  if(longIntegerIsZero(currentNumber) || longIntegerSign(currentNumber) == -1) {             // <=0 end
    goto abort;
  } else {
    longIntegerSubtractUInt(currentNumber,1,temp);                                           // ==1 end
    if(longIntegerIsZero(temp)) {
      goto abort;
    }
  }

  if(!saveLastX()) {
    goto abort;
  }

  longIntegerSetPositiveSign(currentNumber);
  uIntToLongInteger(2,nextPrime);
  uIntToLongInteger(1,remainder);
  uIntToLongInteger(1,eval);
  int32ToReal34(0,&lastAdded);

  FactorAdder_t faddr;
  initFactorAdder(&faddr);

  while(longIntegerIsPositive(eval)) {

    #if !defined(TESTSUITE_BUILD)
      if (printHalfSecUpdate_Integer(timed, "Tested n =",loop++, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
        _showProgress(&lastAdded, nextPrime);
        dumpExponents(&matrix, &faddr, 13);
        #if defined DMCP_BUILD
          lcd_refresh();
        #endif //DMCP_BUILD
      }

    if(keyWaiting()) {
        showString("key Waiting ...", &standardFont, 20, 40, vmNormal, false, false);
        printHalfSecUpdate_Integer(force+1, "Interrupted Test:",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp);
        programRunStop = PGM_WAITING;
      break;
    }

    #endif //!TESTSUITE_BUILD


    longIntegerDivideQuotientRemainder(currentNumber, nextPrime, quotient, remainder);
    longIntegerSubtract(quotient, nextPrime, eval);
    if(longIntegerIsZero(remainder)) {
      if(!addFactor(lastFactor, nextPrime, &matrix, &lastAdded, &faddr)) {
        goto endandclose;
      }
      longIntegerCopy(quotient,currentNumber);
      if(longIntegerIsPrime(quotient)) {
        if(!addFactor(lastFactor, quotient, &matrix, &lastAdded, &faddr)) {
          goto endandclose;
        }
        goto endandclose;
      }
    } else {
      longIntegerNextPrime(nextPrime, nextPrime);
    }
    if(!longIntegerIsPositive(eval)) {
      longIntegerSubtractUInt(currentNumber,1,temp);
      if(!longIntegerIsZero(temp)) {
        if(!addFactor(lastFactor, currentNumber, &matrix, &lastAdded, &faddr)) {
          goto endandclose;
        }
      }
    }
  }

endandclose:
  dumpExponents(&matrix, &faddr, 65535);
  clearFactorAdder(&faddr);
abort:
  longIntegerFree(lastFactor);
  longIntegerFree(temp);
  longIntegerFree(eval);
  longIntegerFree(quotient);
  longIntegerFree(remainder);
  longIntegerFree(nextPrime);
  longIntegerFree(currentNumber);
  hourGlassIconEnabled = false;
  showHideHourGlass();
}
