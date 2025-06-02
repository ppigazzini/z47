// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file prime.c
 ***********************************************/

#include "c47.h"

#define maximumPrime 308   //10^308

// primes less than 212
TO_QSPI const uint8_t smallPrimes[] = {   2,   3,   5,   7,  11,  13,  17,  19,  23,  29,  31,  37,
                                         41,  43,  47,  53,  59,  61,  67,  71,  73,  79,  83,  89,
                                         97, 101, 103, 107, 109, 113, 127, 131, 137, 139, 149, 151,
                                        157, 163, 167, 173, 179, 181, 191, 193, 197, 199, 211,      
                                        223, 227, 229, 233, 239, 241, 251 };

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


// distances between primes, starting at 251+6 ==> 257 .... 1009
TO_QSPI const uint8_t smallPrimes2[] = { 6, 6, 6, 2, 6, 4, 2, 10, 14, 4, 2, 4, 14, 6, 10, 2, 4, 6, 8, 
                                         6, 6, 4, 6, 8, 4, 8, 10, 2, 10, 2, 6, 4, 6, 8, 4, 2, 4, 12, 
                                         8, 4, 8, 4, 6, 12, 2, 18, 6, 10, 6, 6, 2, 6, 10, 6, 6, 2, 6, 
                                         6, 4, 2, 12, 10, 2, 4, 6, 6, 2, 12, 4, 6, 8, 10, 8, 10, 8, 6, 
                                         6, 4, 8, 6, 4, 8, 4, 14, 10, 12, 2, 10, 2, 4, 2, 10, 14, 4, 2, 
                                         4, 14, 4, 2, 4, 20, 4, 8, 10, 8, 4, 6, 6, 14, 4, 6, 6, 8, 6, 12 };


#define smallPrimeListNumber (nbrOfElements(smallPrimes) + nbrOfElements(smallPrimes2))
uint16_t smallPrimeList(uint16_t index) {
  uint16_t tt = 251;
  if(index < nbrOfElements(smallPrimes)) {
    return smallPrimes[index];
  } else
  if(index < smallPrimeListNumber) {
    uint16_t subIndex = index - nbrOfElements(smallPrimes);
    for(uint16_t ii = 0; ii <= subIndex && ii < nbrOfElements(smallPrimes2); ii++) {
      tt += smallPrimes2[ii];
    }
    return tt;
  } else {
    return 0;
  }
}

//void listAllPrimesInList(void) {
//  for (uint i = 0; i < smallPrimeListNumber; i++) {
//    printf("prime: %u : %u\n",i,smallPrimeList(i));
//  }
//}



void calculateNextPrime(longInteger_t currentNumber, longInteger_t nextPrime);

/*
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

    uInt32ToLongInteger(smallPrimes[i], smallPrime);
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

static bool_t getIntArg(longInteger_t x) {
  bool_t fractional;

  if(!getRegisterAsLongInt(REGISTER_X, x, &fractional))
    return false;

  if (fractional) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    return false;
  }
  return true;
}


void fnIsPrime(uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_12PRIME)
    longInteger_t tmp, primeCandidate;

    longIntegerInit(primeCandidate);
    longIntegerInit(tmp);
    if (!getIntArg(primeCandidate))
      goto abort;
    longIntegerPowerUIntUInt(10,maximumPrime,tmp);
    longIntegerSubtract(primeCandidate, tmp, tmp);   // (primeCandidate - 10^300) positive is too large
    if(longIntegerIsPositive(tmp)) {
      badDomainError(REGISTER_X);
      goto abort;
    }

    SET_TI_TRUE_FALSE(longIntegerIsPositive(primeCandidate) && longIntegerIsPrime(primeCandidate) != 0);

  abort:
    longIntegerFree(tmp);
    longIntegerFree(primeCandidate);
  #endif // !SAVE_SPACE_DM42_12PRIME
}

void SQUFOF(mpz_t result, const mpz_t N);
void complete_factorization1(const mpz_t N);
void complete_factorization2(const mpz_t N);


void fnNextPrime(uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_12PRIME)
    real_t x;
    longInteger_t tmp, currentNumber, nextPrime;

    longIntegerInit(currentNumber);
    longIntegerInit(nextPrime);
    longIntegerInit(tmp);

    if(getRegisterDataType(REGISTER_X) == dtReal34) {    //Allow decimals to be rounded down, to be able to get the next prime despite being decimal input;
      if(!getRegisterAsReal(REGISTER_X, &x)) {
        goto abort;
      }
      convertRealToLongInteger(&x, currentNumber, DEC_ROUND_DOWN);
    }
    else {
      if(!getIntArg(currentNumber)) {
        goto abort;
      }
    }

    longIntegerPowerUIntUInt(10,maximumPrime,tmp);
    longIntegerSubtract(currentNumber, tmp, tmp);   // (primeCandidate - 10^300) positive is too large
    if(longIntegerIsPositive(tmp)) {
      badDomainError(REGISTER_X);
      goto abort;
    }


    if(!saveLastX()) {
      goto abort;
    }

    if(!longIntegerIsPositive(currentNumber)) {
      uInt32ToLongInteger(1u, currentNumber);
    }


    //longIntegerNextPrime(currentNumber, nextPrime);
    calculateNextPrime(currentNumber, nextPrime);

    if(getRegisterDataType(REGISTER_L) == dtShortInteger) {
      convertLongIntegerToShortIntegerRegister(nextPrime, getRegisterShortIntegerBase(REGISTER_L), REGISTER_X);
    }
    else {
      convertLongIntegerToLongIntegerRegister(nextPrime, REGISTER_X);
    }
  abort:
    longIntegerFree(tmp);
    longIntegerFree(nextPrime);
    longIntegerFree(currentNumber);
  #endif // !SAVE_SPACE_DM42_12PRIME
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
  uInt32ToLongInteger(2u, two);                           // two = 2
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
  uInt32ToLongInteger(1u, Q);                     // Q = 1;
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
  uInt32ToLongInteger(2u, V);                     // V = 2;
  longIntegerInit(q);                             // q = 0;
  uInt32ToLongInteger(1u, q);                     // q = 1;
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

  if(longIntegerCompareUInt(primeCandidate, smallPrimes[46]+1) <= 0) {  //smallPrimes[46]+1 = 212
    longIntegerToUInt32(primeCandidate, pc);
    for(i=0; i<nbrOfElements(smallPrimes); i++) {
      if(smallPrimes[i] == pc) {
        return true;
      }
    }
    return false;
  }

  for(i=0; i<nbrOfElements(smallPrimes); i++) {
    if(longIntegerModuloUInt(primeCandidate, smallPrimes[i]) == 0) {
      return false;
    }
  }

  // if primeCandidate is a 32-bit integer, perform full trial division
  if(longIntegerCompareUInt(primeCandidate, 0xffffffff) <= 0) {
    i = smallPrimes[46]; //smallPrimes[46] = 211
    longIntegerToUInt32(primeCandidate, pc);
    while(i*i < pc) {
      for(j=0; j<nbrOfElements(offsets); j++) {
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
  uInt32ToLongInteger(2u, s);
  uInt32ToLongInteger(5u, a);
  longIntegerPowerModulo(a, primeCandidateMinus1on2, primeCandidate, temp); // temp = Legendre symbol resulting in primeCandidate-1 if a is a non-residue, instead of -1
  while(longIntegerCompare(temp, primeCandidateMinus1) != 0) {
    longIntegerChangeSign(s);     // s = -s;
    longIntegerSubtract(s, a, a); // a = s - a;
    longIntegerPowerModulo(a, primeCandidateMinus1on2, primeCandidate, temp);
  }

  return isLucasProbablePrime(primeCandidate, a);
} */

// Next prime strictly larger than currentNumber
//void nextPrime(longInteger_t currentNumber, longInteger_t nextPrime) {
void calculateNextPrime(longInteger_t currentNumber, longInteger_t nextPrime) {
  uint32_t cn, i, x, s, e, m, o;
  #if !defined(TESTSUITE_BUILD)
    int32_t loop = 0;
  #endif //TESTSUITE_BUILD


  if(longIntegerCompareUInt(currentNumber, 2) < 0) {
    uInt32ToLongInteger(2u, nextPrime);
    return;
  }

  // first odd larger than currentNumber
  longIntegerAddUInt(currentNumber, 1, currentNumber);
  if(longIntegerIsEven(currentNumber)) {
    longIntegerAddUInt(currentNumber, 1, currentNumber);
  }


  //replaced the above with a faster integer only sequential prime elimination
  //check if the next odd number is a small prime
  if (longIntegerCompareUInt(currentNumber, smallPrimeList(smallPrimeListNumber - 1) + 1) < 0) {
    if (mpz_fits_ulong_p(currentNumber)) {
      longIntegerToUInt32(currentNumber, cn);
      while (true) {
        for (i = 0; i < smallPrimeListNumber; i++) {
          if (smallPrimeList(i) == cn) {
            uInt32ToLongInteger(cn, nextPrime);
            return;
          }
        }
        cn += 2;
      }
    }
    //note: not coming out of here except by returning out of the loop
  }


  // find our position in the sieve rotation via binary search
  // The sieve algorithm uses a wheel of size 210 (the product of the first four primes:
  // 2×3×5×7 = 210). The rotation pattern (or reduced residue system) under mod 210 
  // consists of numbers < 210 that are coprime to 210, and these are indexed in indices[]. 
  // There are 48 such numbers, 47 when starting from 2 as we do.

  // below:
  // startpoint inclusive
  // endpoint exclusive
  // midpoint: will be incremented until endpoint is reached

  // uses the first 47 entries of the smallPrimes list, not needing the actual list, using the indices
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

  //nextPrime = currentNumber + indices[m] - x;
  longIntegerAddUInt(currentNumber, indices[m] - x, nextPrime);
  while(true) {
    for(o=m; o<m+48; o++) {
      //if(longIntegerIsPrime2(nextPrime)) {
      if(longIntegerIsPrime(nextPrime)) {
        return;
      }
      longIntegerAddUInt(nextPrime, offsets[o % 48], nextPrime);

      #if !defined(TESTSUITE_BUILD)
        if(monitorExit(&loop, "Iter: ")) {
          displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          return;
        }
      #endif //!TESTSUITE_BUILD
    }
  }
}


#if !defined (TESTSUITE_BUILD)
  #if !defined(SAVE_SPACE_DM42_12PRIME)
    static void _showProgress(const real34_t *ss, longInteger_t nextp) {
      real34_t rr;
      clearRegisterLine(REGISTER_Z, true, true);
      clearRegisterLine(REGISTER_Y, true, true);
      clearRegisterLine(REGISTER_X, true, true);
      uint8_t savedDisplayFormatDigits = displayFormatDigits;
      displayFormatDigits = 0;
      strcpy(tmpString,"Last =  ");
      real34ToDisplayString(ss, amNone, tmpString+6, &standardFont, 400, 28, !LIMITEXP, FRONTSPACE, NOIRFRAC);
      showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, true, true);
      convertLongIntegerToReal34(nextp, &rr);

      strcpy(tmpString,"Test:   ");
      real34ToDisplayString(&rr, amNone, tmpString+7, &standardFont, 400, 28, !LIMITEXP, FRONTSPACE, NOIRFRAC);
      showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_Z_LINE + 6, vmNormal, true, true);

      refreshRegisterLine(REGISTER_X);

      displayFormatDigits = savedDisplayFormatDigits;
    }
  #endif //SAVE_SPACE_DM42_12PRIME
#endif //TESTSUITE_BUILD




#undef old_PrimeFactorProgram

#ifdef old_PrimeFactorProgram
#define MAX_FACTORS 100//87
#define WGR              //verbose
#undef WGR

typedef struct FactorAdder
{
  uint16_t nExpons;
  uint16_t expons[MAX_FACTORS];
  longInteger_t lastFactor;
} FactorAdder_t;


#if !defined(SAVE_SPACE_DM42_12PRIME)
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
      uint16_t cols = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
      uint16_t rows = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows;
      printf("wgr:  rows==%" PRIu16 ", cols==%" PRIu16 "\n", rows, cols);
    #endif
    linkToRealMatrixRegister(REGISTER_X,  matrix);
    for( uint16_t i = 0;  i < min(n2,dumpForFewerThan);  ++i ) {
      #ifdef WGR
        printf("wgr:  adding expon at n2==%u, i==%u, val %u, sval %u, ind %u\n", n2, i, faddr->expons[i], faddr->expons[i], n2+i);
      #endif //WGR
      uInt32ToReal34(faddr->expons[i], &matrix->matrixElements[n2+i]);
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
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
          moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return false;
      }
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }

    uint16_t rows = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows;
    uint16_t cols = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
    if( faddr->nExpons == 0 ) {
      faddr->nExpons = 1;  // has to be 1 now, as we have this factor
      faddr->expons[(faddr->nExpons)-1] = 1;
    }
    uint16_t wkgCols = faddr->nExpons;
    #ifdef WGR
      gmp_printf("wgr:  factor==%Zd, rows==%u, cols==%u, nExpons==%u, wkgCols==%u\n",factor, (uint16_t)rows, (uint16_t)cols, faddr->nExpons, wkgCols);
    #endif //WGR

    if(!redimMatrixRegister(REGISTER_X, rows, wkgCols)) {
      #if !defined(TESTSUITE_BUILD)
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
          moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      #endif // !TESTSUITE_BUILD
      return false;
      }

    if( cols == 0 ) {
      #ifdef WGR
        printf("wgr:  zeroing lastFactor\n");
      #endif //WGR
      uInt32ToLongInteger(0u, lastFactor);
    }
    linkToRealMatrixRegister(REGISTER_X,  matrix);
    #ifdef WGR
      gmp_printf("wgr:  lastFactor==%Zd\n", lastFactor);
    #endif //WGR
    uint16_t n = rows*(faddr->nExpons);
    uint16_t c = n/2;
    if( longIntegerSign(lastFactor) != 0 && longIntegerCompare(lastFactor, factor) == 0 ) {
      ++faddr->expons[(faddr->nExpons)-1];
      #ifdef WGR
        printf("wgr:  lastFactor use existing:  created expons %u at %u\n",faddr->expons[(faddr->nExpons)-1], (faddr->nExpons)-1);
      #endif
    }
    else {
      bool_t incNExpons = longIntegerSign(lastFactor) ==0 ? false : true;
      if( !incNExpons ) {
        c = 0;
      }
      #ifdef WGR
        printf("wgr:  lastFactor restart:  n==%u, c==%u, incNExpons==%d\n", n, c, incNExpons);
      #endif
      convertLongIntegerToReal34(factor, &matrix->matrixElements[c]);
      #ifdef WGR
        printReal34ToConsole(&matrix->matrixElements[c],"wgr:  from lastAdded:  ","\n");
      #endif
      real34Copy(&matrix->matrixElements[c], lastAdded);
      if( incNExpons ) {
        if( faddr->nExpons < MAX_FACTORS ) {
            ++faddr->nExpons;
        }
        else {
          #if !defined(TESTSUITE_BUILD)
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "Maximum number of factors exceeded %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
              moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          #endif // !TESTSUITE_BUILD
          return false;
        }
        ++wkgCols;
        faddr->expons[faddr->nExpons-1] = 1;
        if(!redimMatrixRegister(REGISTER_X, rows, wkgCols)) {
          #if !defined(TESTSUITE_BUILD)
            displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
              moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            #endif // !TESTSUITE_BUILD
          return false;
        }
      }
      n = rows*(faddr->nExpons);
      c = n/2;
      longIntegerCopy(factor, lastFactor);
    }
    return true;
  }
#endif //SAVE_SPACE_DM42_12PRIME


/*
 * This function takes a long integer in the X register, and determines its
 * prime factorisation.  The result is a matrix with two rows.  The first
 * row contains all the distinct prime factors.
 * The second row contains the exponents for each prime factor, that is in
 * the same column in the first row.
 * Example:
 *   Input X register:  1500
 *   Output X register:  2.  3.  5.
 *                       2.  1.  3.
 *
 *   Input X register:  -1500
 *   Output X register:  -1. 2.  3.  5.
 *                        1. 2.  1.  3.
 */
void fnPrimeFactors (uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_12PRIME)
    #define NOFACTOR 127
    #define INITIALISPRIME  126
    int8_t initialFactorAdded = NOFACTOR;
    currentKeyCode = 255;
    #if !defined(TESTSUITE_BUILD)
      int32_t loop = 0;
    #endif //TESTSUITE_BUILD
    real34_t lastAdded;

    longInteger_t lastFactor, currentNumber, nextPrime, remainder, quotient, eval, temp, tmp;

    longIntegerInit(currentNumber);
    longIntegerInit(nextPrime);
    longIntegerInit(remainder);
    longIntegerInit(quotient);
    longIntegerInit(eval);
    longIntegerInit(temp);
    longIntegerInit(lastFactor);
    longIntegerInit(tmp);
    real34Matrix_t matrix;

    if(!getIntArg(currentNumber)) {
      goto abort;
    }

    longIntegerPowerUIntUInt(10,maximumPrime,tmp);
    longIntegerSubtract(currentNumber, tmp, tmp);   // (primeCandidate - 10^300) positive is too large
    if(longIntegerIsPositive(tmp)) {
      badDomainError(REGISTER_X);
      goto abort;
    }

    if(longIntegerIsPrime(currentNumber)) {
      initialFactorAdded = INITIALISPRIME;
    }
    if(longIntegerIsZero(currentNumber)) {                       // currentNumber = 0 --> end
      initialFactorAdded = 0;
    }
    else if(!longIntegerIsPositive(currentNumber)) {             // currentNumber <=0 --> end
      initialFactorAdded = -1;
    }
    else {
      longIntegerSubtractUInt(currentNumber,1,temp);             // currentNumber = 1 --> end
      if(longIntegerIsZero(temp)) {
        initialFactorAdded = 1;
      }
    }

    if(!saveLastX()) {
      goto abort;
    }

    longIntegerSetPositiveSign(currentNumber);
    uInt32ToLongInteger(2u, nextPrime);
    uInt32ToLongInteger(1u, remainder);
    uInt32ToLongInteger(1u, eval);
    int32ToReal34(0,&lastAdded);

    FactorAdder_t faddr;
    initFactorAdder(&faddr);

     if(initialFactorAdded != NOFACTOR) {
       if(initialFactorAdded == INITIALISPRIME) {
         longIntegerCopy(currentNumber, nextPrime);
       }
       else {
         int32ToLongInteger(initialFactorAdded, nextPrime);
       }
       if(!addFactor(lastFactor, nextPrime, &matrix, &lastAdded, &faddr)) {
         goto abort;
       }
       if(initialFactorAdded == 0 || initialFactorAdded == 1 || initialFactorAdded == INITIALISPRIME) {
        goto endandclose;
       }
       uInt32ToLongInteger(2u, nextPrime);
     }


    while(longIntegerIsPositive(eval)) {

      #if !defined(TESTSUITE_BUILD)
        loop++;
        if(checkHalfSec()) {
          if(progressHalfSecUpdate_Integer(timed, "Tested n =",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
            _showProgress(&lastAdded, nextPrime);
            dumpExponents(&matrix, &faddr, 13);
            force_refresh(force);
          }
        }
        if(exitKeyWaiting()) {
          progressHalfSecUpdate_Integer(force+1, "Interrupted: ",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp);
          programRunStop = PGM_WAITING;
          break;
        }
      #endif //!TESTSUITE_BUILD


      longIntegerDivideQuotientRemainder(currentNumber, nextPrime, quotient, remainder);
      longIntegerSubtract(quotient, nextPrime, eval);

      //printLongIntegerToConsole(currentNumber,"doing currentNumber: ","\n");
      //printLongIntegerToConsole(nextPrime,"   nextPrime: ","\n");
      //printLongIntegerToConsole(quotient,"   quotient: ","\n");
      //printLongIntegerToConsole(remainder,"   remainder: ","\n");


      if(longIntegerIsZero(remainder)) {
        if(!addFactor(lastFactor, nextPrime, &matrix, &lastAdded, &faddr)) {
        //printf("    -- remainder zero, added factor");
          goto endandclose;
        }
        longIntegerCopy(quotient,currentNumber);
        if(longIntegerIsPrime(quotient)) {
          //printf("    -- quotient prime, added factor");
          if(!addFactor(lastFactor, quotient, &matrix, &lastAdded, &faddr)) {
            goto endandclose;
          }
          goto endandclose;
        }
      }
      else {
        longIntegerNextPrime(nextPrime, nextPrime);
      }
      if(!longIntegerIsPositive(eval)) {
        longIntegerSubtractUInt(currentNumber,1,temp);
        if(!longIntegerIsZero(temp) ){
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
    longIntegerFree(tmp);
    longIntegerFree(lastFactor);
    longIntegerFree(temp);
    longIntegerFree(eval);
    longIntegerFree(quotient);
    longIntegerFree(remainder);
    longIntegerFree(nextPrime);
    longIntegerFree(currentNumber);
  #endif //SAVE_SPACE_DM42_12PRIME
}
#endif //old_PrimeFactorProgram




// *** This is used with the Euler sigma function
void longIntegerSumPowers(longInteger_t base, longInteger_t exponent, uint32_t k, longInteger_t result) {
  longInteger_t count, sum, pwr, tmp, tmpbase;
  longIntegerInit(count);
  longIntegerInit(sum);
  longIntegerInit(pwr);
  longIntegerInit(tmp);
  longIntegerInit(tmpbase);
  uInt32ToLongInteger(0u, sum);
  longIntegerCopy(exponent, count);

  while(!longIntegerIsNegative(count)) {
    //printLongIntegerToConsole(count,"  count:"," \n");
    if(k == 0) {                                    // Divisor Count is the generalized sigma function, with k = 0
      uInt32ToLongInteger(0u, tmp);
    }
    else {                                          // Euler's sigma function is the generalized sigma function, with k = 1
      longIntegerCopy(count, tmp);
    }
    if(k >= 2) {                                    // Generalized sigma function, with k > 1
      longIntegerMultiplyUInt(tmp, k, tmp);
    }
    longIntegerCopy(base, tmpbase);
    longIntegerPower(tmpbase, tmp, pwr);
    longIntegerCopy(pwr, tmp);
    longIntegerAdd(sum, tmp, sum);
    //printLongIntegerToConsole(pwr,"  pwr:"," ");
    //printLongIntegerToConsole(sum,"  sum:","\n");
    longIntegerSubtractUInt(count, 1, count);
  }

  longIntegerCopy(sum, result);
  longIntegerFree(tmpbase);
  longIntegerFree(tmp);
  longIntegerFree(pwr);
  longIntegerFree(sum);
  longIntegerFree(count);
}



/*
 * This is the inverse function of fnPrimeFactors.
 * Given a matrix as produced by fnPrimeFactors, this function expands out
 * all the prime factors with their exponents, and returns in the X register
 * the result as a long integer.
 */
void _fnEvPFacts     (uint16_t param) {
  #if !defined(SAVE_SPACE_DM42_12PRIME)
    real_t factorR, factorI, baseR, expR, prodR, prodI;

    //parameter X required for k
    int32_t pwr = param;
    real_t x;
    longInteger_t currentNumber;
    longIntegerInit(currentNumber);
    if(param == M_EULER_SIGMA_k) {
      if(getRegisterDataType(REGISTER_X) == dtReal34) {    //Allow decimals to be rounded down, to be able to get the next prime despite being decimal input;
        if(!getRegisterAsReal(REGISTER_X, &x)) {
          goto abort;
        }
        pwr = realToInt32C47(&x);
        fnDrop(NOPARAM);
      }
      else {
        if(!getIntArg(currentNumber)) {
          goto abort;
        }
        longIntegerToInt32(currentNumber, pwr);
        if(pwr > 3321 || pwr < 0) {
          goto abort;
        }
        fnDrop(NOPARAM);
      }
    }
    longIntegerFree(currentNumber);



    if(getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
      real34Matrix_t matrix;

      linkToRealMatrixRegister(REGISTER_X, &matrix);
      uint16_t rows = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows;
      uint16_t cols = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
      if ( rows == 2 && cols >= 1 ) {
        // Only operate if factorisation matrix has two rows and at least one column
        longInteger_t prod, factor, tmp_prod, p_li, k_li;
        longIntegerInit(prod);
        longIntegerInit(factor);
        longIntegerInit(tmp_prod);
        uInt32ToLongInteger(1u, prod);
        realCopy(const_1,&prodR);
        #define sumTypeInteger 0
        #define sumTypeReal    1
        #define sumTypeComplex 2
        uint8_t sumType = sumTypeInteger;
        for ( uint16_t j = 0;  j < cols;  ++j ) {
          if(real34IsAnInteger(&matrix.matrixElements[j]) && real34IsAnInteger(&matrix.matrixElements[cols+j]) && sumType == sumTypeInteger) {
            convertReal34ToLongInteger(&matrix.matrixElements[j], p_li, RM_HALF_UP);
            convertReal34ToLongInteger(&matrix.matrixElements[cols+j], k_li, RM_HALF_UP);
            //printLongIntegerToConsole(p_li,"base:","  ");
            //printLongIntegerToConsole(k_li,"exp:","\n");
            switch(param){
              case M_FACTORS:        longIntegerPower(p_li, k_li, factor); break;
              case M_EULER_SIGMA_0:
              case M_EULER_SIGMA_1:
              case M_EULER_SIGMA_k:  longIntegerSumPowers(p_li, k_li, pwr, factor); break;
              default:;
            }
            longIntegerFree(p_li);
            longIntegerFree(k_li);
            //printLongIntegerToConsole(factor,"factor:","\n");
            longIntegerCopy(prod, tmp_prod);
            longIntegerMultiply(tmp_prod, factor, prod);
          }
          else {
            if(sumType == sumTypeInteger) {
              convertLongIntegerToReal(prod, &prodR, &ctxtReal39);
              sumType = sumTypeReal;
            }
            real34ToReal(&matrix.matrixElements[j], &baseR);
            real34ToReal(&matrix.matrixElements[cols+j], &expR);
            if(!(realIsNegative(&baseR) && !realIsAnInteger(&expR)) && sumType == sumTypeReal) {
              PowerReal(&baseR, &expR, &factorR, &ctxtReal39);
              realMultiply(&prodR, &factorR, &prodR, &ctxtReal39);
            }
            else if(getFlag(FLAG_CPXRES)) {
              if(sumType == sumTypeReal) {
                realCopy(const_0,&prodI);
                sumType = sumTypeComplex;
              }
              if(sumType == sumTypeComplex) {
                PowerComplex(&baseR, const_0, &expR, const_0, &factorR, &factorI, &ctxtReal39);
                mulComplexComplex(&prodR, &prodI, &factorR, &factorI, &prodR, &prodI, &ctxtReal39);
              }
            }
            else {
              displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
              #if (EXTRA_INFO_ON_CALC_ERROR == 1)
                moreInfoOnError("In function fnEvPFacts:", "cannot do complex results if CPXRES is not set", NULL, NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
              longIntegerFree(prod);
              longIntegerFree(factor);
              longIntegerFree(tmp_prod);
              return;
            }
          }
        }

        switch(sumType) {
          case sumTypeInteger: {
            convertLongIntegerToLongIntegerRegister(prod, REGISTER_X);
            break;
          }
          case sumTypeReal: {
            convertRealToResultRegister(&prodR, REGISTER_X, amNone);
            break;
          }
          case sumTypeComplex: {
            convertComplexToResultRegister(&prodR, &prodI, REGISTER_X);
            break;
          }
          default: break;
        }
        adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
        longIntegerFree(prod);
        longIntegerFree(factor);
        longIntegerFree(tmp_prod);
      }
      else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Only 2" STD_CROSS "n matrix supported: %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
          moreInfoOnError("In function fnEvPFacts:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        goto return10;
      }
    }
    else {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "2" STD_CROSS "n matrix required.");
        moreInfoOnError("In function fnEvPFacts:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto return10;
    }
    return10:
    refreshScreen(253);
    return;

    abort:
    longIntegerFree(currentNumber);
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnEvPFacts:", "cannot do Euler sigma function due to parameter issue", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto return10;

  #endif //SAVE_SPACE_DM42_12PRIME
}



void fnEvPFacts (uint16_t param) {
  longInteger_t xx;
  int32_t k = 1;

  if(!saveLastX()) {
    goto return10;
  }
  saveForUndo();
  if(param == M_EULER_SIGMA_pk) {
    longIntegerInit(xx);
    if(!getIntArg(xx)) {
      longIntegerFree(xx);
      return;
    }
    longIntegerToInt32(xx, k);
    longIntegerFree(xx);
    fnSwapXY(NOPARAM);
  }

  if(param == M_EULER_SIGMA_p1 || param == M_EULER_SIGMA_pk) {
    longInteger_t y, x, z, tmp;
    _fnEvPFacts(M_FACTORS);                                      //longinteger register output
    convertLongIntegerRegisterToLongInteger(REGISTER_X, y);
    //printLongIntegerToConsole(y,"Y:","\n");
    longIntegerInit(z);
    longIntegerInit(tmp);
    int32ToLongInteger(k, z);
    longIntegerPower(y, z, tmp);
    longIntegerCopy(tmp,y);                                      //y is the number to be subtracted
    //printLongIntegerToConsole(y,"Y:","\n");
    copySourceRegisterToDestRegister(SAVED_REGISTER_X, REGISTER_X);
    copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);
    switch(param) {
      case M_EULER_SIGMA_p1: _fnEvPFacts(M_EULER_SIGMA_1); break;      //longintger register output
      case M_EULER_SIGMA_pk: _fnEvPFacts(M_EULER_SIGMA_k); break;      //longintger register output
      default:;
    }
    convertLongIntegerRegisterToLongInteger(REGISTER_X, x);
    //printLongIntegerToConsole(x,"x:","  ");
    //printLongIntegerToConsole(y,"y:","\n");
    longIntegerSubtract(x, y, x);
    //printLongIntegerToConsole(x,"x:","\n");
    convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
    longIntegerFree(tmp);
    longIntegerFree(z);
    longIntegerFree(y);
    longIntegerFree(x);
  } else {
    _fnEvPFacts(param);
  }



  return10:

  refreshScreen(254);
}



/*
 * This function accepts a long integer in the X register and computes
 * the Euler phi function on it.  The result is a new long integer.
 *
 * Example:
 *
 *   Input X register:  1500
 *   Output X register:  400
 *
 * Formula for euler phi function phi(n):
 * determine prime factorisation of n:  p[0]**k[0], p[1]**k[1], p[2]**k[2], ... p[r]**k[r] where the p[i] are distinct
 * phi(n) = n * prod[i=0...r]((p[i]-1)/p[i])
 *
 * This is done by grabbing the value n as long integer from the X register.
 * Then fnPrimeFactors is computed, producing a factorisation matrix.
 * The prime factors are extracted from this matrix and used to complete
 * the calculation.
 */
void fnEulPhi     (uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_12PRIME)
    longInteger_t x;
    longIntegerInit(x);

    if(!getIntArg(x)) {
      goto return1;
    }

    if(!saveLastX()) {
      goto return1;
    }

    longInteger_t phi_x, p_li, p_li_less_1, phi_x_tmp, phi_x_tmp_b;
    longIntegerInit(phi_x);
    longIntegerInit(phi_x_tmp);
    longIntegerInit(phi_x_tmp_b);
    real34Matrix_t matrix;
    // Check for the trivial case x = 0        (*)
    if(longIntegerIsZero(x)) {
      longIntegerCopy(x, phi_x);
      goto returnValue;
    }
    longIntegerSubtractUInt(x, 1, phi_x_tmp);
    // Check for the trivial case x = 1        (**)
    if(longIntegerIsZero(phi_x_tmp)) {
      longIntegerCopy(x, phi_x);
      goto returnValue;
    }
    if(longIntegerIsPositive(phi_x_tmp)) {
      // Only operate if input long integer to fnPrimeFactors in register x is greater than 1 (***)
      fnPrimeFactors(unusedButMandatoryParameter);
      if(getRegisterDataType(REGISTER_X) == dtReal34Matrix) {
        // Only operate if we got back a Real 34 Matrix from fnPrimeFactors
        linkToRealMatrixRegister(REGISTER_X, &matrix);
        uint16_t rows = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows;
        uint16_t cols = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
        if (rows == 2 && cols >= 1) {
          // Only operate if factorisation matrix has two rows and at least one column
          longIntegerCopy(x, phi_x);
          for (uint16_t j = 0;  j < cols; ++j) {
            real34_t p = matrix.matrixElements[j];
            convertReal34ToLongInteger(&p, p_li, RM_HALF_UP);
            longIntegerInit(p_li_less_1);
            longIntegerSubtractUInt(p_li, 1, p_li_less_1);
            if(j == 0 && !longIntegerIsPositive(p_li_less_1)) {   //ensure 0 is returned is the first factor <= 1. This is achieved above, see (*), (**), (***)
              uInt32ToLongInteger(0u, phi_x);
              longIntegerFree(p_li);
              longIntegerFree(p_li_less_1);
              break;
            }
            longIntegerCopy(phi_x, phi_x_tmp);
            longIntegerDivide(phi_x_tmp, p_li, phi_x_tmp_b);
            longIntegerMultiply(phi_x_tmp_b, p_li_less_1, phi_x);
            longIntegerFree(p_li);
            longIntegerFree(p_li_less_1);
          }
        }
        else {
          goto return2; //matrix dimensions wrong. An error would have been issued by fnPrimeFactors
        }
      }
      else {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "The intermediate prime factor matrix could not be found.");
        moreInfoOnError("In function fnEulPhi:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto return2;
      }
    }
    else {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "The input value is negative and therefore out of the domain for Euler's Phi function!");
        moreInfoOnError("In function fnEulPhi:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto return2;
    }
    returnValue:
    convertLongIntegerToLongIntegerRegister(phi_x, REGISTER_X);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

    return2:
    longIntegerFree(phi_x);
    longIntegerFree(phi_x_tmp);
    longIntegerFree(phi_x_tmp_b);

    return1:
    longIntegerFree(x);

  #endif //SAVE_SPACE_DM42_12PRIME
}





#ifndef old_PrimeFactorProgram
//** factorization **********************************************************************************************************
// Shanks algorithm, based on the demo on the wikipedia page
// https://en.wikipedia.org/wiki/Shanks%27s_square_forms_factorization

#define MONITOR_FACTORS
#undef MONITOR_FACTORS

// Check if a number is a perfect square using GMP
static int longIntegerIsPerfectSquareCheckAndDo(const longInteger_t n, longInteger_t r)
{
  if (longIntegerPerfectSquare(n)) {
    longIntegerSquareRoot(n, r);
    return 1;
  }
  return 0;
}


// Fast perfect square check using 32-bit integer sqrt
static int is_perfect_square_uint32(uint32_t n, uint32_t* sqrt_out) {
    uint32_t r = (uint32_t)(sqrt((double)n));
    if (r * r == n) {
        if (sqrt_out) *sqrt_out = r;
        return 1;
    }
    if ((r + 1) * (r + 1) == n) {
        if (sqrt_out) *sqrt_out = r + 1;
        return 1;
    }
    return 0;
}



    #if !defined(TESTSUITE_BUILD)
      int32_t loopp = 0;
    #endif //TESTSUITE_BUILD

void SQUFOF(mpz_t result, const mpz_t N) {
    mpz_t D, Po, P, Pprev, Q, Qprev, q, b, r, s;
    mpz_t temp1, temp2, temp3, gcd_result;
    uint32_t L, B, i, k;
    // Initialize all GMP variables
    mpz_init(D); mpz_init(Po); mpz_init(P); mpz_init(Pprev);
    mpz_init(Q); mpz_init(Qprev); mpz_init(q); mpz_init(b);
    mpz_init(r); mpz_init(s); mpz_init(temp1); mpz_init(temp2);
    mpz_init(temp3); mpz_init(gcd_result);
    
    // Check if N is a perfect square
    if (longIntegerIsPerfectSquareCheckAndDo(N, s)) {
      goto cleanup;
    }
    
    // Calculate s = sqrt(N)
    longIntegerSquareRoot(N, s);
    
    // Removed multiplier loop, replaced with multiplier=1 single run
    k = 1;
    
    // D = multiplier[k] * N  (just N here)
    mpz_mul_ui(D, N, k);
    
    // Po = Pprev = P = sqrt(D)
    longIntegerSquareRoot(D, Po);
    mpz_set(Pprev, Po);
    mpz_set(P, Po);
    
    // Qprev = 1
    mpz_set_ui(Qprev, 1);
    
    // Q = D - Po*Po
    mpz_mul(temp1, Po, Po);
    mpz_sub(Q, D, temp1);
    if (mpz_sgn(Q) == 0) {
        goto cleanup;  // Q is zero; no factor found
    }
    
    // L = 2 * sqrt(2*s)
    mpz_mul_ui(temp1, s, 2);
    longIntegerSquareRoot(temp1, temp2);
    L = 2 * mpz_get_ui(temp2);
    
    // B = 3 * L
    B = 3 * L;
   
    for (i = 2; i < B; i++) {
        #if !defined(TESTSUITE_BUILD)
          loopp++;
          if(checkHalfSec()) {
            if(progressHalfSecUpdate_Integer(timed, "Shanks SQFO(up): n =",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
              force_refresh(force);
            }
          }
          if(exitKeyWaiting()) {
            progressHalfSecUpdate_Integer(force+1, "Interrupted: ",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            programRunStop = PGM_WAITING;
            break;
          }
        #endif //!TESTSUITE_BUILD
        // b = (Po + P) / Q
        mpz_add(temp1, Po, P);
        mpz_fdiv_q(b, temp1, Q);
        
        // P = b*Q - P
        mpz_mul(temp1, b, Q);
        mpz_sub(temp2, temp1, P);
        mpz_set(P, temp2);

        // q = Q
        mpz_set(q, Q);

        // Q = Qprev + b*(Pprev - P)
        mpz_sub(temp1, Pprev, P);
        mpz_mul(temp2, b, temp1);
        mpz_add(Q, Qprev, temp2);

        // r = sqrt(Q)
        longIntegerSquareRoot(Q, r);

        // Check if i is even and r*r == Q
        if (!(i & 1) && longIntegerIsPerfectSquareCheckAndDo(Q, temp1)) {
            break;
        }
        
        // Qprev = q; Pprev = P
        mpz_set(Qprev, q);
        mpz_set(Pprev, P);
    }
    
    if (i >= B) goto cleanup;
    
    // b = (Po - P) / r
    mpz_sub(temp1, Po, P);
    mpz_fdiv_q(b, temp1, r);
    
    // Pprev = P = b*r + P
    mpz_mul(temp1, b, r);
    mpz_add(temp2, temp1, P);
    mpz_set(Pprev, temp2);
    mpz_set(P, temp2);
    
    // Qprev = r
    mpz_set(Qprev, r);
    
    // Q = (D - Pprev*Pprev) / Qprev
    mpz_mul(temp1, Pprev, Pprev);
    mpz_sub(temp2, D, temp1);
    mpz_fdiv_q(Q, temp2, Qprev);
    
    i = 0;
    do {
        #if !defined(TESTSUITE_BUILD)
          loopp++;
          if(checkHalfSec()) {
            if(progressHalfSecUpdate_Integer(timed, "Shanks SQFO(dn): n =",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
              force_refresh(force);
            }
          }
          if(exitKeyWaiting()) {
            progressHalfSecUpdate_Integer(force+1, "Interrupted: ",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            programRunStop = PGM_WAITING;
            break;
          }
        #endif //!TESTSUITE_BUILD
        // b = (Po + P) / Q
        mpz_add(temp1, Po, P);
        mpz_fdiv_q(b, temp1, Q);
        
        // Pprev = P
        mpz_set(Pprev, P);
        
        // P = b*Q - P
        mpz_mul(temp1, b, Q);
        mpz_sub(P, temp1, P);
        
        // q = Q
        mpz_set(q, Q);
        
        // Q = Qprev + b*(Pprev - P)
        mpz_sub(temp1, Pprev, P);
        mpz_mul(temp2, b, temp1);
        mpz_add(Q, Qprev, temp2);
        
        // Qprev = q
        mpz_set(Qprev, q);
        
        i++;
    } while (mpz_cmp(P, Pprev) != 0);
    
    // r = gcd(N, Qprev)
    longIntegerGcd(N, Qprev, r);
    
    // Check if r != 1 and r != N
    if (mpz_cmp_ui(r, 1) != 0 && mpz_cmp(r, N) != 0) {
        mpz_set(result, r);
        goto cleanup;
    }
    
    // No factor found
    mpz_set_ui(result, 0);
    
cleanup:
    // Clear all GMP variables
    mpz_clear(D); mpz_clear(Po); mpz_clear(P); mpz_clear(Pprev);
    mpz_clear(Q); mpz_clear(Qprev); mpz_clear(q); mpz_clear(b);
    mpz_clear(r); mpz_clear(s); mpz_clear(temp1); mpz_clear(temp2);
    mpz_clear(temp3); mpz_clear(gcd_result);
}



bool delCol1RealMatrixX(void) {
    real34Matrix_t mat;
    linkToRealMatrixRegister(REGISTER_X, &mat);
    uint16_t rows = mat.header.matrixRows;
    uint16_t cols = mat.header.matrixColumns;
    if (!mat.matrixElements || cols <= 1) return false;

    // every element in column 0 is exactly 1.0
    bool allOnes = true;
    for (uint16_t i = 0; i < rows; ++i) {
        if (!real34CompareEqual(&mat.matrixElements[i * cols + 0], const34_1)) {
            allOnes = false;
            break;
        }
    }
    if (!allOnes) {
        // nothing to delete, first column is all 1.0
        return true;
    }


    // Build a temp matrix with one fewer column:
    real34Matrix_t tmp;
    if (!realMatrixInit(&tmp, rows, cols - 1)) {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return false;
    }
    for (uint16_t i = 0; i < rows; i++) {
        for (uint16_t j = 1; j < cols; j++) {
            real34Copy(
                &mat.matrixElements[i*cols + j],
                &tmp.matrixElements[i*(cols-1) + (j-1)]
            );
        }
    }
    // Re-init the register and free old buffer
    initMatrixRegister(REGISTER_X, rows, cols - 1, false);

    // Copy the temp data back into the freshly-allocated register
    real34_t *dest = REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X);
    size_t total = (size_t)rows * (cols - 1);
    for (size_t k = 0; k < total; k++) {
        real34Copy(&tmp.matrixElements[k], &dest[k]);
    }
    realMatrixFree(&tmp);
    return true;
}




#define MAX_FACTORS 110
#define MAXIMUM_QUEUE_SIZE 1000
typedef struct FactorAdder
{
  uint16_t nExpons;
  uint16_t expons[MAX_FACTORS];
} FactorAdder_t;


#if !defined(SAVE_SPACE_DM42_12PRIME)
  static void initFactorAdder(FactorAdder_t *faddr) {
    faddr->nExpons = 0;
  };

  void dumpExponents(real34Matrix_t *matrix, FactorAdder_t *faddr, uint16_t dumpForFewerThan) {
    uint16_t n2 = faddr->nExpons;
                                            #ifdef MONITOR_FACTORS
                                              printf("dumpExponents:  fill expons:  *nExpons==%u, n2==%u dump=%u\n", faddr->nExpons, n2, dumpForFewerThan);
                                              uint16_t cols = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
                                              uint16_t rows = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows;
                                              printf("--a:  rows==%" PRIu16 ", cols==%" PRIu16 "\n", rows, cols);
                                            #endif //MONITOR_FACTORS
    linkToRealMatrixRegister(REGISTER_X,  matrix);
    for( uint16_t i = 0;  i < min(n2,dumpForFewerThan);  ++i ) {
                                            #ifdef MONITOR_FACTORS
                                              printf("--b:  adding expon at n2==%u, i==%u, val %u, sval %u, ind %u\n", n2, i, faddr->expons[i], faddr->expons[i], n2+i);
                                            #endif //MONITOR_FACTORS
      uInt32ToReal34(faddr->expons[i], &matrix->matrixElements[n2+i]);
    }
  }


  static bool_t addFactor(longInteger_t factor, real34Matrix_t *matrix, const real34_t *lastAdded,FactorAdder_t *faddr) {
    //printLongIntegerToConsole(factor,"-->","\n");
                                            #ifdef MONITOR_FACTORS
                                              printf("--c:  addFactor()\n");
                                            #endif //MONITOR_FACTORS
    if(getRegisterDataType(REGISTER_X) != dtReal34Matrix) {
      //Initialize Memory for Matrix
      if(initMatrixRegister(REGISTER_X, 2, 0, false)) {
        setSystemFlag(FLAG_ASLIFT);
      }
      else {
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
          moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return false;
      }
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }



    uint16_t rows = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows;
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      uint16_t cols = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
    #endif //(EXTRA_INFO_ON_CALC_ERROR == 1)
    if(rows > 2) {
       #if !defined(TESTSUITE_BUILD)
         displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
         #if (EXTRA_INFO_ON_CALC_ERROR == 1)
           sprintf(errorMessage, "Incorrect matrix dimensions %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
           moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
         #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
       #endif // !TESTSUITE_BUILD
       return false;
    }

    if( faddr->nExpons == 0 ) {
      faddr->nExpons = 1;  // has to be 1 now, as we have this factor
      faddr->expons[(faddr->nExpons)-1] = 1;
    }
    uint16_t wkgCols = faddr->nExpons;
                                            #ifdef MONITOR_FACTORS
                                              gmp_printf("--d:  factor==%Zd, rows==%u, cols==%u, nExpons==%u, wkgCols==%u\n",factor, (uint16_t)rows, (uint16_t)cols, faddr->nExpons, wkgCols);
                                            #endif //MONITOR_FACTORS
    if(!redimMatrixRegister(REGISTER_X, rows, wkgCols)) {
      #if !defined(TESTSUITE_BUILD)
        displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
          moreInfoOnError("In function fnPrimeFactors:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      #endif // !TESTSUITE_BUILD
      return false;
    }

    linkToRealMatrixRegister(REGISTER_X, matrix);
    int counter = faddr->nExpons;
    uint16_t n = rows*counter;
    uint16_t c = n/2;

    //printf("faddr->nExpons=%d n=%d c=%d",cntr, n, c);

    real34_t factorR;
    convertLongIntegerToReal34(factor, &factorR);
    //search for existing factors
    while(counter >= 0 && !real34CompareEqual(&factorR, &matrix->matrixElements[counter])) {
      counter--;
    }

    //increment exponent if found
    if( longIntegerSign(factor) != 0 && counter >= 0 && !real34CompareAbsEqual(&matrix->matrixElements[counter],const34_1) ) {
      ++(faddr->expons[counter]);
                                              #ifdef MONITOR_FACTORS
                                                printf("--e:   use existing:  created expons %u at %u\n",faddr->expons[(faddr->nExpons)-1], (faddr->nExpons)-1);
                                              #endif //MONITOR_FACTORS
    }
    else {
      bool_t incNExpons = real34CompareAbsEqual(&factorR,const34_1) ? false : true;
      if( !incNExpons ) {
        c = 0;
      }
                                              #ifdef MONITOR_FACTORS
                                                printf("--f:   restart:  n==%u, c==%u, incNExpons==%d\n", n, c, incNExpons);
                                              #endif //MONITOR_FACTORS
      real34Copy(&factorR, &matrix->matrixElements[c]);
      real34Copy(&matrix->matrixElements[c], lastAdded);
      if( incNExpons ) {
        if( faddr->nExpons < MAX_FACTORS ) {
            (faddr->nExpons)++;
        }
        else {
          #if !defined(TESTSUITE_BUILD)
            displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "Maximum number of factors exceeded %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
              moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          #endif // !TESTSUITE_BUILD
          return false;
        }

        ++wkgCols;
        faddr->expons[faddr->nExpons-1] = 1;
        if(!redimMatrixRegister(REGISTER_X, rows, wkgCols)) {
          #if !defined(TESTSUITE_BUILD)
            displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", rows, cols);
              moreInfoOnError("In function addFactor:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            #endif // !TESTSUITE_BUILD
          return false;
        }
      }
      n = rows*(faddr->nExpons);
      c = n/2;
    }
    return true;
  }
#endif //SAVE_SPACE_DM42_12PRIME



void fnPrimeFactors (uint16_t unusedButMandatoryParameter) {
//void complete_factorization2(uint16_t unusedButMandatoryParameter) {
    currentKeyCode = 255;
    real34_t lastAdded;

    longInteger_t currentNumber, tmp, temp1;

    longIntegerInit(currentNumber);
    longIntegerInit(tmp);
    longIntegerInit(temp1);
    real34Matrix_t matrix;

    if(!getIntArg(currentNumber)) {
      goto abort;
    }

    longIntegerPowerUIntUInt(10,maximumPrime,tmp);
    longIntegerSubtract(currentNumber, tmp, tmp);   // (primeCandidate - 10^300) positive is too large
    if(longIntegerIsPositive(tmp)) {
      badDomainError(REGISTER_X);
      goto abort;
    }

    if(!saveLastX()) {
      goto abort;
    }

    int32ToReal34(0,&lastAdded);
    FactorAdder_t faddr;
    initFactorAdder(&faddr);

    int32ToLongInteger(longIntegerIsNegative(currentNumber) ? -1 : 1, tmp);    
    if(!addFactor(tmp, &matrix, &lastAdded, &faddr)) {
      goto abort;
    }
    longIntegerSetPositiveSign(currentNumber);

    mpz_t queue[MAXIMUM_QUEUE_SIZE];
    int queue_start = 0, queue_end = 0;

// initialize and prep second part
    mpz_t temp, factor, quotient, tempPrePrimeRun;
    mpz_init(temp);
    mpz_init(factor);
    mpz_init(quotient);
    mpz_init(tempPrePrimeRun);
    // Initialize queue with the input number
    for (int i = 0; i < MAXIMUM_QUEUE_SIZE; i++) {
        mpz_init(queue[i]);
    }

    // original command, prior to pre-run of primes. Retain here to test without the pre-run block
    //   mpz_set(queue[queue_end++], currentNumber);

    // first do a pre-run, to do small prime checking
    for (uint16_t i = 0; i < smallPrimeListNumber; i++) {
      uint16_t smallP = smallPrimeList(i);
      while (mpz_divisible_ui_p(currentNumber, smallP)) {
        #if !defined(TESTSUITE_BUILD)
          loopp++;
          if(checkHalfSec()) {
            if(progressHalfSecUpdate_Integer(timed, "Pre-run small primes < 1000: n =",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
              _showProgress(&lastAdded, currentNumber);
              dumpExponents(&matrix, &faddr, 13);
              force_refresh(force);
            }
          }
          if(exitKeyWaiting()) {
            progressHalfSecUpdate_Integer(force+1, "Interrupted: ",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            programRunStop = PGM_WAITING;
            break;
          }
        #endif //!TESTSUITE_BUILD
                            #if defined(MONITOR_FACTORS)
                              printf("Prime factor: %u -> tempPrePrimeRun; Remaining currentNumber -> queue: ", smallP);
                            #endif //MONITOR_FACTORS
        mpz_divexact_ui(currentNumber, currentNumber, smallP);
                            #if defined(MONITOR_FACTORS)
                              mpz_out_str(stdout, 10, currentNumber);
                            #endif //MONITOR_FACTORS
        mpz_set_ui(tempPrePrimeRun, (unsigned long)(smallP));
        if(!addFactor(tempPrePrimeRun, &matrix, &lastAdded, &faddr)) {
          goto cleanup;
        }
                            #if defined(MONITOR_FACTORS)
                              printf("\n");
                            #endif //MONITOR_FACTORS
      }
    } // end of small prime loop

    // Early multiplier check using 32-bit perfect square test
    static const uint32_t multipliers[] = { 257, 263, 269, 271, 281, 283, 293, 307, 311, 313 };
    for (uint16_t i = 0; i < sizeof(multipliers)/sizeof(multipliers[0]); i++) {
        uint32_t k = multipliers[i];
        if (mpz_fits_uint_p(currentNumber)) {
            uint32_t n32 = mpz_get_ui(currentNumber);
            uint64_t kn = (uint64_t)k * (uint64_t)n32;
            uint32_t root;
            if (is_perfect_square_uint32(kn, &root)) {
                // Skip trivial perfect square 1 * 1 = 1
                if (!(k == 1 && root == 1)) {
                    #if defined(MONITOR_FACTORS)
                      printf("Perfect square detected early: %u * %u = %" PRIu64 "\n", k, n32, kn);
                    #endif
                    // Inject a trivial factor
                    mpz_set_ui(tempPrePrimeRun, root);
                    if (!addFactor(tempPrePrimeRun, &matrix, &lastAdded, &faddr)) {
                        goto cleanup;
                    }
                    mpz_divexact_ui(currentNumber, currentNumber, root);
                    break;
                }
            }
        }
    }




    mpz_set(queue[queue_end++], currentNumber);
                            #if defined(MONITOR_FACTORS)
                              printf("Factorizing: ");
                              mpz_out_str(stdout, 10, currentNumber);
                              printf("\nFactors found: ");
                            #endif //MONITOR_FACTORS

    mpz_t current;
    mpz_init(current);
    while (queue_start < queue_end) {
        mpz_set(current, queue[queue_start++]);
                            #if defined(MONITOR_FACTORS)
                              printf("loopp=%d queue_start=%d queue_end=%d\n",loopp, queue_start, queue_end);
                            #endif //MONITOR_FACTORS
           #if defined(MONITOR_FACTORS)
             mpz_out_str(stdout, 10, current);
             printf(" ");
            #endif //MONITOR_FACTORS

        #if !defined(TESTSUITE_BUILD)
          loopp++;
          if(checkHalfSec()) {
            if(progressHalfSecUpdate_Integer(timed, "Shanks iteratative: n =",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
              _showProgress(&lastAdded, current);
              dumpExponents(&matrix, &faddr, 13);
              force_refresh(force);
            }
          }
          if(exitKeyWaiting()) {
            progressHalfSecUpdate_Integer(force+1, "Interrupted: ",loopp, halfSec_clearZ, halfSec_clearT, halfSec_disp);
            programRunStop = PGM_WAITING;
            break;
          }
        #endif //!TESTSUITE_BUILD


        // Skip if current is 1
        if (mpz_cmp_ui(current, 1) == 0) {
                            #if defined(MONITOR_FACTORS)
                              printf("Skip, current is 1\n");
                            #endif //MONITOR_FACTORS
            continue;
        }

        // Check if current is prime
        if (longIntegerProbabPrime(current)) {
           #if defined(MONITOR_FACTORS)
             mpz_out_str(stdout, 10, current);
             printf(" ");
            #endif //MONITOR_FACTORS
            convertLongIntegerToLongIntegerRegister(current, TEMP_REGISTER_1);
            fnP_All_Regs(PRN_TMP);
            if(!addFactor(current, &matrix, &lastAdded, &faddr)) {
              goto endandclose;
            }
                            #if defined(MONITOR_FACTORS)
                              printf("Skip, current is prime\n");
                            #endif //MONITOR_FACTORS
            continue;
        }

        // Attempt to find a factor using SQUFOF
        SQUFOF(factor, current);
        if (mpz_cmp_ui(factor, 0) == 0 || mpz_cmp(factor, current) == 0) {
            // SQUFOF failed; treat current as prime
                            #if defined(MONITOR_FACTORS)
                              printf("SQUFOF failed; treat current as prime: ");
                              mpz_out_str(stdout, 10, current);
                              printf(" ");
                            #endif //MONITOR_FACTORS
            convertLongIntegerToLongIntegerRegister(current, TEMP_REGISTER_1);
            fnP_All_Regs(PRN_TMP);
            if(!addFactor(current, &matrix, &lastAdded, &faddr)) {
              goto endandclose;
            }
                            #if defined(MONITOR_FACTORS)
                              printf("current considered prime, next\n");
                            #endif //MONITOR_FACTORS
            continue;
        }

        // Divide current by the found factor
        mpz_divexact(quotient, current, factor);

        // Enqueue the factor and quotient for further factorization
        if (queue_end + 2 <= MAXIMUM_QUEUE_SIZE) {
                            #if defined(MONITOR_FACTORS)
                              printf("Enqeueing: ");
                              mpz_out_str(stdout, 10, factor);
                              printf(" ");
                              mpz_out_str(stdout, 10, quotient);
                              printf("\n");
                            #endif //MONITOR_FACTORS
            mpz_set(queue[queue_end++], factor);
            mpz_set(queue[queue_end++], quotient);
        } else {
            displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
              moreInfoOnError("In function fnPrimeFactors:  Queue overflow:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            break;
        }

    }
    mpz_clear(current);

cleanup:
    mpz_clear(temp);
    mpz_clear(factor);
    mpz_clear(quotient);
    mpz_clear(tempPrePrimeRun);
    for (int i = 0; i < MAXIMUM_QUEUE_SIZE; i++) {
        mpz_clear(queue[i]);
    }

endandclose:
    dumpExponents(&matrix, &faddr, 65535);
    delCol1RealMatrixX();

abort:
    uInt32ToLongInteger(1u, tmp);
    convertLongIntegerToLongIntegerRegister(tmp, TEMP_REGISTER_1);
    longIntegerFree(tmp);
    longIntegerFree(temp1);
    longIntegerFree(currentNumber);

}
#endif //!old_PrimeFactorProgram

