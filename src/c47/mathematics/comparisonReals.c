// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file comparisonReals.c
 ***********************************************/

#include "c47.h"

void convergenceTolerence(real_t *tol)
{
  realCopy(const_1, tol);
  tol->exponent -= (significantDigits == 0 || significantDigits >= 32) ? 32 : significantDigits;
}

void irfractionTolerence(int32_t ii, real_t *tol)
{
  int32ToReal((int32_t)ii,tol);
  tol->exponent -= ((fractionDigits == 0 || fractionDigits >= 34) ? 34 : fractionDigits);
}

void fractionTolerence(real_t *tol)
{
  irfractionTolerence(2, tol);
}


bool_t real34CompareAbsGreaterThan(const real34_t *number1, const real34_t *number2) {
  real34_t num1, num2;

  real34CopyAbs(number1, &num1);
  real34CopyAbs(number2, &num2);
  real34Compare(&num1, &num2, &num2);
  return real34IsPositive(&num2) && !real34IsZero(&num2);
}



bool_t real34CompareAbsLessThan(const real34_t *number1, const real34_t *number2) {
  real34_t num1, num2;

  real34CopyAbs(number1, &num1);
  real34CopyAbs(number2, &num2);
  real34Compare(&num1, &num2, &num2);
  return real34IsNegative(&num2) && !real34IsZero(&num2);
}



bool_t real34CompareEqual(const real34_t *number1, const real34_t *number2) {
  real34_t compare;

  real34Compare(number1, number2, &compare);
  return real34IsZero(&compare);
}



bool_t real34CompareGreaterEqual(const real34_t *number1, const real34_t *number2) {
  real34_t compare;

  real34Compare(number1, number2, &compare);
  return real34IsPositive(&compare) || real34IsZero(&compare);
}


/* never used*/ //: put back JM
bool_t real34CompareGreaterThan(const real34_t *number1, const real34_t *number2) {
  real34_t compare;

  real34Compare(number1, number2, &compare);
  return real34IsPositive(&compare) && !real34IsZero(&compare);
}
/**/


bool_t real34CompareLessEqual(const real34_t *number1, const real34_t *number2) {
  real34_t compare;

  real34Compare(number1, number2, &compare);
  return real34IsNegative(&compare) || real34IsZero(&compare);
}



bool_t real34CompareLessThan(const real34_t *number1, const real34_t *number2) {
  real34_t compare;

  real34Compare(number1, number2, &compare);
  return real34IsNegative(&compare) && !real34IsZero(&compare);
}



bool_t realCompareAbsGreaterThan(const real_t *number1, const real_t *number2) {
  real_t num1, num2;

  realCopyAbs(number1, &num1);
  realCopyAbs(number2, &num2);
  realCompare(&num1, &num2, &num2, &ctxtReal75);
  return realIsPositive(&num2) && !realIsZero(&num2);
}


/*
bool_t realCompareAbsGreaterEqual(const real_t *number1, const real_t *number2) {
  real_t num1, num2;

  realCopyAbs(number1, &num1);
  realCopyAbs(number2, &num2);
  realCompare(&num1, &num2, &num2, &ctxtReal75);
  return realIsPositive(&num2) || realIsZero(&num2);
}
*/


bool_t realCompareAbsLessThan(const real_t *number1, const real_t *number2) {
  real_t num1, num2;

  realCopyAbs(number1, &num1);
  realCopyAbs(number2, &num2);
  realCompare(&num1, &num2, &num2, &ctxtReal75);
  return realIsNegative(&num2) && !realIsZero(&num2);
}



bool_t realCompareEqual(const real_t *number1, const real_t *number2) {
  real_t compare;

  realCompare(number1, number2, &compare, &ctxtReal75);
  return realIsZero(&compare);
}



bool_t realCompareAbsEqual(const real_t *number1, const real_t *number2) {
  real_t num1, num2;

  realCopyAbs(number1, &num1);
  realCopyAbs(number2, &num2);
  realCompare(&num1, &num2, &num2, &ctxtReal75);
  return realIsZero(&num2);
}



bool_t realCompareGreaterEqual(const real_t *number1, const real_t *number2) {
  real_t compare;

  realCompare(number1, number2, &compare, &ctxtReal75);
  return realIsPositive(&compare) || realIsZero(&compare);
}



bool_t realCompareGreaterThan(const real_t *number1, const real_t *number2) {
  real_t compare;

  realCompare(number1, number2, &compare, &ctxtReal75);
  return realIsPositive(&compare) && !realIsZero(&compare);
}



bool_t realCompareLessEqual(const real_t *number1, const real_t *number2) {
  real_t compare;

  realCompare(number1, number2, &compare, &ctxtReal75);
  return realIsNegative(&compare) || realIsZero(&compare);
}



bool_t realCompareLessThan(const real_t *number1, const real_t *number2) {
  real_t compare;

  realCompare(number1, number2, &compare, &ctxtReal75);
  return realIsNegative(&compare) && !realIsZero(&compare);
}



bool_t real34IsAnInteger(const real34_t *x) {
  real34_t y;

  if(real34IsNaN(x) || real34IsInfinite(x)) {
    return false;
  }

  real34ToIntegralValue(x, &y, DEC_ROUND_DOWN);
  real34Subtract(x, &y, &y);

  return real34CompareEqual(&y, const34_0);
}



bool_t realIsAnInteger(const real_t *x) {
  real_t y;

  if(realIsNaN(x)) {
    return false;
  }

  if(realIsInfinite(x)) {
    return true;
  }

  realToIntegralValue(x, &y, DEC_ROUND_DOWN, &ctxtReal75);
  realSubtract(x, &y, &y, &ctxtReal75);

  return realCompareEqual(&y, const_0);
}



/*
int16_t realIdenticalDigits(real_t *a, real_t *b) {
  int16_t counter, smallest;

  if(realGetExponent(a) != realGetExponent(b)) {
    return 0;
  }

  realGetCoefficient(a, tmpString);
  realGetCoefficient(b, tmpString + TMP_STR_LENGTH/2);
  smallest = min(a->digits, b->digits);
  counter = 0;

  while(counter < smallest && tmpString[counter] == tmpString[TMP_STR_LENGTH/2 + counter]) {
    counter++;
  }

  return counter;
}
*/
