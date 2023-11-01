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
 * \file wp34s.c
 ***********************************************/

#include "mathematics/wp34s.h"

#include "constantPointers.h"
#include "conversionAngles.h"
#include "distributions/normal.h"
#include "mathematics/10pow.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/exp.h"
#include "mathematics/ln.h"
#include "mathematics/lnbeta.h"
#include "mathematics/magnitude.h"
#include "mathematics/multiplication.h"
#include "mathematics/sin.h"
#include "mathematics/toPolar.h"
#include "realType.h"
#include "screen.h"
#include "statusBar.h"
#include "registers.h"

#include "wp43.h"


/******************************************************
 * This functions are borrowed from the WP34S project
 ******************************************************/

// Have to be careful here to ensure that every function we call can handle
// the increased size of the numbers we're using.
void WP34S_Cvt2RadSinCosTan(const real_t *an, angularMode_t angularMode, real_t *sinOut, real_t *cosOut, real_t *tanOut, realContext_t *realContext) {
  bool_t sinNeg = false, cosNeg = false, swap = false;
  real_t angle;
  const real_t *angle45, *angle90, *angle180;
  angle45  = const_0;
  angle90  = const_0;
  angle180 = const_0;


  if(realIsNaN(an)) {
    if(sinOut != NULL) {
     realCopy(const_NaN, sinOut);
    }
    if(cosOut != NULL) {
      realCopy(const_NaN, cosOut);
    }
    if(tanOut != NULL) {
      realCopy(const_NaN, tanOut);
    }
   return;
  }

  realCopy(an, &angle);

  // sin(-x) = -sin(x), cos(-x) = cos(x)
  if(realIsNegative(&angle)) {
    sinNeg = true;
    realSetPositiveSign(&angle);
  }

  int32_t savedContextDigits = realContext->digits;
  if(realContext->digits > 51) {
    realContext->digits = 75;
  }
  else {
    realContext->digits = 51;
  }

  switch(angularMode) {
    case amRadian: {
      angle45 = const_piOn4_75;
      angle90 = const_piOn2_75;
      angle180 = const_pi_75;
      WP34S_Mod(&angle, const1071_2pi, &angle, realContext); // mod(angle, 2pi) --> angle
      break;
    }

    case amMultPi: {
      angle45 = const_1on4;
      angle90 = const_1on2;
      angle180 = const_1;
      WP34S_Mod(&angle, const_2, &angle, realContext); // mod(angle, 2) --> angle
      break;
    }

    case amGrad: {
      angle45 = const_50;
      angle90 = const_100;
      angle180 = const_200;
      WP34S_Mod(&angle, const_400,     &angle, realContext); // mod(angle, 400g) --> angle
      break;
    }

    case amDegree:
    case amDMS: {
      angle45 = const_45;
      angle90 = const_90;
      angle180 = const_180;
      WP34S_Mod(&angle, const_360,     &angle, realContext); // mod(angle, 360°) --> angle
      angularMode = amDegree;
      break;
    }

    default: {
    }
  }

  // sin(180+x) = -sin(x), cos(180+x) = -cos(x)
  if(realCompareGreaterEqual(&angle, angle180)) {        // angle >= 180°
    realSubtract(&angle, angle180, &angle, realContext); // angle - 180° --> angle
    sinNeg = !sinNeg;
    cosNeg = !cosNeg;
  }

  // sin(90+x) = cos(x), cos(90+x) = -sin(x)
  if(realCompareGreaterEqual(&angle, angle90)) {        // angle >= 90°
    realSubtract(&angle, angle90, &angle, realContext); // angle - 90° --> angle
    swap = true;
    cosNeg = !cosNeg;
  }

  // sin(90-x) = cos(x), cos(90-x) = sin(x)
  if(realCompareEqual(&angle, angle45)) { // angle == 45°
    if(sinOut != NULL) {
     realCopy(const_root2on2, sinOut);
    }
    if(cosOut != NULL) {
      realCopy(const_root2on2, cosOut);
    }
    if(tanOut != NULL) {
      realCopy(const_1, tanOut);
    }
  }
  else { // angle < 90
    if(realCompareGreaterThan(&angle, angle45)) {         // angle > 45°
      realSubtract(angle90, &angle, &angle, realContext); // 90° - angle  --> angle
      swap = !swap;
    }

    convertAngleFromTo(&angle, angularMode, amRadian, realContext);
    WP34S_SinCosTanTaylor(&angle, swap, swap?cosOut:sinOut, swap?sinOut:cosOut, tanOut, realContext); // angle in radian
  }

  realContext->digits = savedContextDigits;

  if(sinOut != NULL) {
    if(sinNeg) {
      realSetNegativeSign(sinOut);
      if(tanOut != NULL) {
        realSetNegativeSign(tanOut);
      }
    }
    if(realIsZero(sinOut)) {
      realSetPositiveSign(sinOut);
      if(tanOut != NULL) {
        realSetPositiveSign(tanOut);
      }
    }
    realPlus(sinOut, sinOut, realContext);
  }

  if(cosOut != NULL) {
    if(cosNeg) {
      realSetNegativeSign(cosOut);
      if(tanOut != NULL) {
        realChangeSign(tanOut);
      }
    }
    if(realIsZero(cosOut)) {
      realSetPositiveSign(cosOut);
    }
    realPlus(cosOut, cosOut, realContext);
  }

  if(tanOut != NULL && realIsZero(cosOut)) {
    realSetPositiveSign(tanOut);
    realPlus(tanOut, tanOut, realContext);
  }
}


// Calculate sin, cos by Taylor series and tan by division
void WP34S_SinCosTanTaylor(const real_t *a, bool_t swap, real_t *sinOut, real_t *cosOut, real_t *tanOut, realContext_t *realContext) { // a in radian
  real_t angle, a2, t, j, z, sin, cos, compare;
  int i;
  bool_t endSin = (sinOut == NULL), endCos = (cosOut == NULL);
  int32_t savedContextDigits = realContext->digits;

  if(realContext->digits > 51) {
    realContext->digits = 75;
  }
  else {
    realContext->digits = 51;
  }

  realCopy(a, &angle);
  realMultiply(&angle, &angle, &a2, realContext);
  uInt32ToReal(1, &j);
  uInt32ToReal(1, &t);
  uInt32ToReal(1, &sin);
  uInt32ToReal(1, &cos);

  for(i=1; !(endSin && endCos) && i<1000; i++) { // i goes up to 31 max in the test suite
    realAdd(&j, const_1, &j, realContext);
    realDivide(&a2, &j, &z, realContext);
    realMultiply(&t, &z, &t, realContext);
    realChangeSign(&t);

    if(!endCos) {
      realCopy(&cos, &z);
      realAdd(&cos, &t, &cos, realContext);
      realCompare(&cos, &z, &compare, realContext);
      endCos = realIsZero(&compare);
    }

    realAdd(&j, const_1, &j, realContext);
    realDivide(&t, &j, &t, realContext);

    if(!endSin) {
      realCopy(&sin, &z);
      realAdd(&sin, &t, &sin, realContext);
      realCompare(&sin, &z, &compare, realContext);
      endSin = realIsZero(&compare);
    }
  }

  if(realIsZero(&cos)) {
    realSetPositiveSign(&cos);
  }

  if(realIsZero(&sin)) {
    realSetPositiveSign(&sin);
  }

  realMultiply(&sin, &angle, &sin, realContext);

  realContext->digits = savedContextDigits;

  if(sinOut != NULL) {
    realPlus(&sin, sinOut, realContext);
  }

  if(cosOut != NULL) {
    realPlus(&cos, cosOut, realContext);
  }

  if(tanOut != NULL) {
    if(sinOut == NULL || cosOut == NULL) {
      realCopy(const_NaN, tanOut);
    }
    else {
      if(swap) {
        realDivide(&cos, &sin, tanOut, realContext);
      }
      else {
        realDivide(&sin, &cos, tanOut, realContext);
      }
    }
  }
}


void WP34S_Atan(const real_t *x, real_t *angle, realContext_t *realContext) {
  real_t a, b, a2, t, j, z, last;
  int doubles = 0;
  int invert;
  int n;
  int neg = realIsNegative(x);

  realCopy(x, &a);

  // arrange for a >= 0
  if(neg) {
    realChangeSign(&a);
  }

  // reduce range to 0 <= a < 1, using atan(x) = pi/2 - atan(1/x)
  invert = realCompareGreaterThan(&a, const_1);
  if(invert) {
    realDivide(const_1, &a, &a, realContext);
  }

  // Range reduce to small enough limit to use taylor series using:
  //  tan(x/2) = tan(x)/(1+sqrt(1+tan(x)²))
  for(n=0; n<1000; n++) {
    if(realCompareLessEqual(&a, const_1on10)) {
      break;
    }
    doubles++;
    // a = a/(1+sqrt(1+a²)) -- at most 3 iterations.
    realMultiply(&a, &a, &b, realContext);
    realAdd(&b, const_1, &b, realContext);
    realSquareRoot(&b, &b, realContext);
    realAdd(&b, const_1, &b, realContext);
    realDivide(&a, &b, &a, realContext);
  }

  // Now Taylor series
  // atan(x) = x(1-x²/3+x⁴/5-x⁶/7...)
  // We calculate pairs of terms and stop when the estimate doesn't change
  realCopy(const_3, angle);
  realCopy(const_5, &j);
  realMultiply(&a, &a, &a2, realContext); // a²
  realCopy(&a2, &t);
  realDivide(&t, angle, angle, realContext); // s = 1-t/3 -- first two terms
  realSubtract(const_1, angle, angle, realContext);

  do { // Loop until there is no digits changed
    realCopy(angle, &last);

    realMultiply(&t, &a2, &t, realContext);
    realDivide(&t, &j, &z, realContext);
    realAdd(angle, &z, angle, realContext);

    realAdd(&j, const_2, &j, realContext);

    realMultiply(&t, &a2, &t, realContext);
    realDivide(&t, &j, &z, realContext);
    realSubtract(angle, &z, angle, realContext);

    realAdd(&j, const_2, &j, realContext);

  } while(!realCompareEqual(angle, &last));

  realMultiply(angle, &a, angle, realContext);

  while(doubles) {
    realAdd(angle, angle, angle, realContext);
    doubles--;
  }

  if(invert) {
    realSubtract(const_piOn2, angle, angle, realContext);
  }

  if(neg) {
    realChangeSign(angle);
  }
}


void WP34S_Atan2(const real_t *y, const real_t *x, real_t *atan, realContext_t *realContext) {
  real_t r, t;
  const bool_t xNeg = realIsNegative(x);
  const bool_t yNeg = realIsNegative(y);

  if(realIsNaN(x) || realIsNaN(y)) {
    realCopy(const_NaN, atan);
    return;
  }

  if(realCompareEqual(y, const_0)) {
    if(yNeg) {
      if(realCompareEqual(x, const_0)) {
        if(xNeg) {
          realMinus(const_pi, atan, realContext);
        }
        else {
          realCopy(y, atan);
        }
      }
      else if(xNeg) {
        realMinus(const_pi, atan, realContext);
      }
      else {
        realCopy(y, atan);
      }
    }
    else {
      if(realCompareEqual(x, const_0)) {
        if(xNeg) {
          realCopy(const_pi, atan);
        }
        else {
          realZero(atan);
        }
      }
      else if(xNeg) {
        realCopy(const_pi, atan);
      }
      else {
        realZero(atan);
      }
    }
    return;
  }

  if(realCompareEqual(x, const_0)) {
    realCopy(const_piOn2, atan);
    if(yNeg) {
      realSetNegativeSign(atan);
    }
    return;
  }

  if(realIsInfinite(x)) {
    if(xNeg) {
      if(realIsInfinite(y)) {
        realCopy(const_3piOn4, atan);
        if(yNeg) {
          realSetNegativeSign(atan);
        }
      }
      else {
        realCopy(const_pi, atan);
        if(yNeg) {
          realSetNegativeSign(atan);
        }
      }
    }
    else {
      if(realIsInfinite(y)) {
        realCopy(const_piOn4, atan);
        if(yNeg) {
          realSetNegativeSign(atan);
        }
      }
      else {
        realZero(atan);
        if(yNeg) {
          realSetNegativeSign(atan);
        }
      }
    }
    return;
  }

  if(realIsInfinite(y)) {
    realCopy(const_piOn2, atan);
    if(yNeg) {
      realSetNegativeSign(atan);
    }
    return;
  }

  realDivide(y, x, &t, realContext);
  WP34S_Atan(&t, &r, realContext);
  if(xNeg) {
    realCopy(const_pi, &t);
    if(yNeg) {
     realSetNegativeSign(&t);
    }
  }
  else {
    realZero(&t);
  }

  realAdd(&r, &t, atan, realContext);
  if(realCompareEqual(atan, const_0) && yNeg) {
    realSetNegativeSign(atan);
  }
}


void WP34S_Asin(const real_t *x, real_t *angle, realContext_t *realContext) {
  real_t abx, z;

  if(realIsNaN(x)) {
    realCopy(const_NaN, angle);
    return;
  }

  realCopyAbs(x, &abx);
  if(realCompareGreaterThan(&abx, const_1)) {
    realCopy(const_NaN, angle);
    return;
  }

  // angle = 2*atan(x/(1+sqrt(1-x*x)))
  realMultiply(x, x, &z, realContext);
  realSubtract(const_1, &z, &z, realContext);
  realSquareRoot(&z, &z, realContext);
  realAdd(&z, const_1, &z, realContext);
  realDivide(x, &z, &z, realContext);
  WP34S_Atan(&z, &abx, realContext);
  realAdd(&abx, &abx, angle, realContext);
}


void WP34S_Acos(const real_t *x, real_t *angle, realContext_t *realContext) {
  real_t abx, z;

  if(realIsNaN(x)) {
    realCopy(const_NaN, angle);
    return;
  }

  realCopyAbs(x, &abx);
  if(realCompareGreaterThan(&abx, const_1)) {
    realCopy(const_NaN, angle);
    return;
  }

  // angle = 2*atan((1-x)/sqrt(1-x*x))
  if(realCompareEqual(x, const_1)) {
    realZero(angle);
  }
  else {
    realMultiply(x, x, &z, realContext);
    realSubtract(const_1, &z, &z, realContext);
    realSquareRoot(&z, &z, realContext);
    realSubtract(const_1, x, &abx, realContext);
    realDivide(&abx, &z, &z, realContext);
    WP34S_Atan(&z, &abx, realContext);
    realAdd(&abx, &abx, angle, realContext);
  }
}


static void WP34S_Calc_Gamma_LnGamma_Lanczos(const real_t *xin, real_t *res, bool_t calculateLnGamma, realContext_t *realContext) {
  real_t r, s, t, u, v, x;
  int32_t k, savedContextDigits;

  savedContextDigits = realContext->digits;
  if(realContext->digits < 51) {
    realContext->digits = 51;
  }

  realSubtract(xin, const_1, &x, realContext);
  realZero(&s);
  realAdd(&x, const_29, &t, realContext);
  for(k=28; k>=0; k--) {
    realDivide((real_t *)(gammaLanczosCoefficients + k), &t, &u, realContext);
    realSubtract(&t, const_1, &t, realContext);
    realAdd(&s, &u, &s, realContext);
  }

  realAdd(&s, const_gammaC00, &t, realContext);
  WP34S_Ln(&t, &s, realContext);

  //  r = z + g + 0.5;
  realAdd(&x, const_gammaR, &r, realContext); // const_gammaR is g + 0.5

  //  r = log(R[0][0]) + (z+0.5) * log(r) - r;
  WP34S_Ln(&r, &u, realContext);
  realAdd(&x, const_1on2, &t, realContext);
  realMultiply(&u, &t, &v, realContext);

  realSubtract(&v, &r, &u, realContext);

  if(calculateLnGamma) {
    realAdd(&u, &s, &x, realContext);
  }
  else {
    realAdd(&u, &s, &x, realContext);
    realExp(&x, &x, realContext);
  }

  realContext->digits = savedContextDigits;

  realPlus(&x, res, realContext);
}


// common code for the [GAMMA] and LN[GAMMA]
static void WP34S_Gamma_LnGamma(const real_t *xin, const bool_t calculateLnGamma, real_t *res, realContext_t *realContext) {
  real_t x, t;
  bool_t reflect = false;

  // Check for special cases
  if(realIsSpecial(xin)) {
    if(realIsInfinite(xin) && realIsPositive(xin)) {
      realCopy(const_plusInfinity, res);
      return;
    }

    realCopy(const_NaN, res);
    return;
  }

  // Handle x approximately zero case
  if(realCompareAbsLessThan(xin, const_1e_24)) {
    if(realIsZero(xin)) {
      realCopy(const_NaN, res);
      return;
    }
    realDivide(const_1, xin, &x, realContext);
    realSubtract(&x, const_egamma, res, realContext);
    if(calculateLnGamma) {
      WP34S_Ln(res, res, realContext);
    }
    return;
  }

  // Correct our argument and begin the inversion if it is negative
  if(realCompareLessEqual(xin, const_0)) {
    reflect = true;
    realSubtract(const_1, xin, &t, realContext); // t = 1 - xin
    if(realIsAnInteger(&t)) {
      realCopy(const_NaN, res);
      return;
    }
  }
  else {
    // Provide a fast path evaluation for positive integer arguments that aren't too large
    // The threshold for overflow is 205! (i.e. 204! is within range and 205! isn't).
    if(realIsAnInteger(xin) && realCompareLessEqual(xin, const_205)) {
      realSubtract(xin, const_1, &x, realContext); // x = xin - 1
      realCopy(const_1, res);
      while(realCompareGreaterEqual(&x, const_2)) {
        realMultiply(res, &x, res, realContext);
        realSubtract(&x, const_1, &x, realContext);
      }
      if(calculateLnGamma) {
        WP34S_Ln(res, res, realContext);
      }
      return;
    }
    realCopy(xin, &t); // t = xin
  }

  WP34S_Calc_Gamma_LnGamma_Lanczos(&t, res, calculateLnGamma, realContext); // t=1-xin or t=xin and res=gamma(xin) or res=lngamma(xin) or res=gamma(1-xin) or res=lngamma(1-xin)

  if(reflect) {
    // figure out xin * PI mod 2PI
    WP34S_Mod(xin, const_2, &t, realContext);
    realMultiply(&t, const_pi, &t, realContext);                   // t = xin·pi
    WP34S_SinCosTanTaylor(&t, false, &x, NULL, NULL, realContext); // x = sin(xin·pi)

    if(calculateLnGamma) {
      realDivide(const_pi, &x, &t, realContext);                   // t = pi / sin(pi·xin)
      WP34S_Ln(&t, &t, realContext);                               // t = ln(pi / sin(pi·xin))
      realSubtract(&t, res, res, realContext);                     // res = ln(pi / sin(pi·xin)) - lngamma(1-xin)
    }
    else {
      realMultiply(&x, res, &t, realContext);                      // t = sin(pi·xin) × gamma(1-xin)
      realDivide(const_pi, &t, res, realContext);                  // res = pi / (sin(pi·xin)·gamma(1-xin))
    }
  }
}


void WP34S_Factorial(const real_t *xin, real_t *res, realContext_t *realContext) {
  real_t x;

  realAdd(xin, const_1, &x, realContext);
  WP34S_Gamma_LnGamma(&x, false, res, realContext);
}


void WP34S_Gamma(const real_t *xin, real_t *res, realContext_t *realContext) {
  real_t x;

  realCopy(xin, &x);
  WP34S_Gamma_LnGamma(&x, false, res, realContext);
}


void WP34S_LnGamma(const real_t *xin, real_t *res, realContext_t *realContext) {
  real_t x;

  realCopy(xin, &x);
  WP34S_Gamma_LnGamma(&x, true, res, realContext);
}


/* Natural logarithm.
 *
 * Take advantage of the fact that we store our numbers in the form: m * 10^e
 * so log(m * 10^e) = log(m) + e * log(10)
 * do this so that m is always in the range 0.1 <= m < 2.  However if the number
 * is already in the range 0.5 .. 1.5, this step is skipped.
 *
 * Then use the fact that ln(x²) = 2 * ln(x) to range reduce the mantissa
 * into 1/sqrt(2) <= m < 2.
 *
 * Finally, apply the series expansion:
 *   ln(x) = 2(a+a³/3+a⁵/5+...) where a=(x-1)/(x+1)
 * which converges quickly for an argument near unity.
 */
void WP34S_Ln(const real_t *xin, real_t *res, realContext_t *realContext) {
  real_t z, t, f, n, m, i, v, w, e;
  int32_t expon;

  if(realIsSpecial(xin)) {
    if(realIsNaN(xin) || realIsNegative(xin)) {
      realCopy(const_NaN, res);
      return;
    }

    realCopy(const_plusInfinity, res);
    return;
  }

  if(realCompareLessEqual(xin, const_0)) {
    if(realIsNegative(xin)) {
      realCopy(const_NaN, res);
      return;
    }

    realCopy(const_minusInfinity, res);
    return;
  }

  realCopy(xin, &z);
  realCopy(const_2, &f);
  realSubtract(xin, const_1, &t, realContext);
  realCopy(&t, &v);
  realSetPositiveSign(&v);
  if(realCompareGreaterThan(&v, const_1on2)) {
    expon = z.exponent + z.digits;
    z.exponent = -z.digits;
  }
  else {
    expon = 0;
  }

  /* The too high case never happens
  while(dn_le(const_2, &z)) {
    realMultiply(&f, const_2, &f, realContext);
    realSquareRoot(&z, &z, realContext);
  } */

  // Range reduce the value by repeated square roots.
  // Making the constant here larger will reduce the number of later
  // iterations at the expense of more square root operations.
  while(realCompareLessEqual(&z, const_root2on2)) {
    realMultiply(&f, const_2, &f, realContext);
    realSquareRoot(&z, &z, realContext);
  }

  realAdd(&z, const_1, &t, realContext);
  realSubtract(&z, const_1, &v, realContext);
  realDivide(&v, &t, &n, realContext);
  realCopy(&n, &v);
  realMultiply(&v, &v, &m, realContext);
  realCopy(const_3, &i);

  int32ToReal(1 - realContext->digits, &t); // t is the exponent
  realPower10(&t, &z, realContext); // z is the max error

  for(;;) {
    realMultiply(&m, &n, &n, realContext);
    realDivide(&n, &i, &e, realContext);
    realAdd(&v, &e, &w, realContext);
    if(WP34S_RelativeError(&w, &v, &z, realContext)) {
      break;
    }
    realCopy(&w, &v);
    realAdd(&i, const_2, &i, realContext);
  }

  realMultiply(&f, &w, res, realContext);
  if(expon == 0) {
    return;
  }

  int32ToReal(expon, &e);
  realMultiply(&e, const_ln10, &w, realContext);
  realAdd(res, &w, res, realContext);
}


void WP34S_Log(const real_t *xin, const real_t *base, real_t *res, realContext_t *realContext) {
  real_t y;

  if(realIsSpecial(xin)) {
    if(realIsNaN(xin) || realIsNegative(xin)) {
      realCopy(const_NaN, res);
      return;
    }

    realCopy(const_plusInfinity, res);
    return;
  }

  WP34S_Ln(xin, &y, realContext);

  realDivide(&y, base, res, realContext);
}


/* never used
void WP34S_Log2(const real_t *xin, real_t *res, realContext_t *realContext) {
  WP34S_Log(xin, const_ln2, res, realContext);
}
*/


void WP34S_Log10(const real_t *xin, real_t *res, realContext_t *realContext) {
  WP34S_Log(xin, const_ln10, res, realContext);
}


void WP34S_Logxy(const real_t *yin, const real_t *xin, real_t *res, realContext_t *realContext) {
  real_t lx;

  WP34S_Ln(xin, &lx, realContext);
  WP34S_Log(yin, &lx, res, realContext);
}


bool_t WP34S_RelativeError(const real_t *x, const real_t *y, const real_t *tol, realContext_t *realContext) {
  real_t a;

  if(realIsZero(x)) {
    realCopyAbs(y, &a);
    return realCompareLessThan(&a, tol);
  }

  realSubtract(x, y, &a, realContext);
  realDivide(&a, x, &a, realContext);
  realSetPositiveSign(&a);
  return realCompareLessThan(&a, tol);
}


bool_t WP34S_AbsoluteError(const real_t *x, const real_t *y, const real_t *tol, realContext_t *realContext) {
  real_t a;
  realSubtract(x, y, &a, realContext);
  return realCompareAbsLessThan(&a, tol);
}


bool_t WP34S_ComplexRelativeError(const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag, const real_t *tol, realContext_t *realContext) {
  real_t a, b;

  if(realIsZero(xReal) && realIsZero(xImag)) {
    complexMagnitude(yReal, yImag, &a, realContext);
  }
  else {
    realSubtract(xReal, yReal, &a, realContext);
    realSubtract(xImag, yImag, &b, realContext);
    divComplexComplex(&a, &b, xReal, xImag, &a, &b, realContext);
    complexMagnitude(&a, &b, &a, realContext);
  }
  return realCompareLessThan(&a, tol);
}


bool_t WP34S_ComplexAbsError(const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag, const real_t *tol, realContext_t *realContext) {
  real_t a, b, r;

  realSubtract(xReal, yReal, &a, realContext), realSubtract(xImag, yImag, &b, realContext);
  complexMagnitude(&a, &b, &r, realContext);
  return realCompareLessThan(&r, tol);
}


/* Hyperbolic functions.
 * We start with a utility routine that calculates sinh and cosh.
 * We do the sihn as (e^x - 1) (e^x + 1) / (2 e^x) for numerical stability
 * reasons if the value of x is smallish.
 */
void WP34S_SinhCosh(const real_t *x, real_t *sinhOut, real_t *coshOut, realContext_t *realContext) {
  real_t t, u, v;

  if(realIsNaN(x)) {
    if(sinhOut != NULL) {
      realCopy(const_NaN, sinhOut);
    }
    if(coshOut != NULL) {
      realCopy(const_NaN, coshOut);
    }
    return;
  }

  if(sinhOut != NULL) {
    if(realCompareAbsLessThan(x, const_1on2)) {
      WP34S_ExpM1(x, &u, realContext);                         // u = e^x - 1
      realMultiply(&u, const_1on2, &t, realContext);           // t = (e^x - 1) / 2

      realAdd(&u, const_1, &u, realContext);                   // u = e^x
      realDivide(&t, &u, &v, realContext);                     // v = (e^x - 1) / 2e^x

      realAdd(&u, const_1, &u, realContext);                   // u = e^x + 1
      realMultiply(&u, &v, sinhOut, realContext);              // sinhOut = (e^x - 1)(e^x + 1) / 2e^x
    }
    else {
      realExp(x, &u, realContext);                             // u = e^x
      realDivide(const_1, &u, &v, realContext);                // v = e^-x
      realSubtract(&u, &v, sinhOut, realContext);              // sinhOut = (e^x + e^-x)
      realMultiply(sinhOut, const_1on2, sinhOut, realContext); // sinhOut = (e^x + e^-x)/2
    }
  }
  if(coshOut != NULL) {
   realExp(x, &u, realContext);                                // u = e^x
   realDivide(const_1, &u, &v, realContext);                   // v = e^-x
   realAdd(&u, &v, coshOut, realContext);                      // coshOut = (e^x + e^-x)
   realMultiply(coshOut, const_1on2, coshOut, realContext);    // coshOut = (e^x + e^-x)/2
  }
}


void WP34S_Tanh(const real_t *x, real_t *res, realContext_t *realContext) {
  if(realIsNaN(x)) {
    realCopy(const_NaN, res);
  }
  else if(realCompareAbsGreaterThan(x, const_47)) { // equals 1 to 39 digits
    realCopy((realIsPositive(x) ? const_1 : const__1), res);
  }
  else {
    real_t a, b;

    realAdd(x, x, &a, realContext);        // a = 2x
    WP34S_ExpM1(&a, &b, realContext);      // b = exp(2x) - 1
    realAdd(&b, const_2, &a, realContext); // a = exp(2x) - 1 + 2 = exp(2x) + 1
    realDivide(&b, &a, res, realContext);  // res = (exp(2x) - 1) / (exp(2x) + 1)
  }
}


void WP34S_ArcSinh(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t a;

  realMultiply(x, x, &a, realContext);   // a = x²
  realAdd(&a, const_1, &a, realContext); // a = x² + 1
  realSquareRoot(&a, &a, realContext);   // a = sqrt(x²+1)
  realAdd(&a, const_1, &a, realContext); // a = sqrt(x²+1)+1
  realDivide(x, &a, &a, realContext);    // a = x / (sqrt(x²+1)+1)
  realAdd(&a, const_1, &a, realContext); // a = x / (sqrt(x²+1)+1) + 1
  realMultiply(x, &a, &a, realContext);  // y = x * (x / (sqrt(x²+1)+1) + 1)
  WP34S_Ln1P(&a, res, realContext);      // res = ln(1 + (x * (x / (sqrt(x²+1)+1) + 1)))
}



/* never used
void WP34S_ArcCosh(const real_t *xin, real_t *res, realContext_t *realContext) {
  real_t x, z;

  realCopy(xin, &x);
  realMultiply(&x, &x, res, realContext);      // res = x²
  realSubtract(res, const_1, &z, realContext); // z = x² - 1
  realSquareRoot(&z, res, realContext);        // res = sqrt(x²-1)
  realAdd(res, &x, &z, realContext);           // z = x + sqrt(x²-1)
  WP34S_Ln(&z, res, realContext);              // res = ln(x + sqrt(x²-1))
}
*/


void WP34S_ArcTanh(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t y, z;

  if(realIsNaN(x)) {
    realCopy(const_NaN, res);
  }

  // Not the obvious formula but more stable...
  realSubtract(const_1, x, &z, realContext);      // z = 1-x
  realDivide(x, &z, &y, realContext);             // y = x / (1-x)
  realMultiply(&y, const_2, &z, realContext);     // z = 2x / (1-x)
  WP34S_Ln1P(&z, &y, realContext);                // y = ln(1 + 2x / (1-x))
  realMultiply(&y, const_1on2, res, realContext); // res = ln(1 + 2x / (1-x)) / 2
}


/* ln(1+x) */
void WP34S_Ln1P(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t u, v, w;

  if(realIsSpecial(x) || realIsZero(x)) {
    realCopy(x, res);
  }
  else {
    realAdd(x, const_1, &u, realContext);       // u = x+1
    realSubtract(&u, const_1, &v, realContext); // v = x
    if(realIsZero(&v)) {
      realCopy(x, res);
    }
    else {
      realDivide(x, &v, &w, realContext);
      WP34S_Ln(&u, &v, realContext);
      realMultiply(&v, &w, res, realContext);
    }
  }
}


/* exp(x)-1 */
void WP34S_ExpM1(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t u, v, w;

  if(realIsInfinite(x)) {
    if(realIsPositive(x)) {
      realCopy(const_plusInfinity, res);
    }
    else {
      realCopy(const__1, res);
    }
  }

  realExp(x, &u, realContext);
  realSubtract(&u, const_1, &v, realContext);
  if(realIsZero(&v)) { // |x| is very little
    realCopy(x, res);
  }
  else {
    if(realCompareEqual(&v, const__1)) {
      realCopy(const__1, res);
    }
    else {
      realMultiply(&v, x, &w, realContext);
      WP34S_Ln(&u, &v, realContext);
      realDivide(&w, &v, res, realContext);
    }
  }
}


static void WP34S_CalcComplexLnGamma_Lanczos(const real_t *zReal, const real_t *zImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t rReal, sReal, tReal, uReal, vReal;
  real_t rImag, sImag, tImag, uImag, vImag;
  int k;
  int32_t savedContextDigits;

  savedContextDigits = realContext->digits;
  if(realContext->digits < 51) {
    realContext->digits = 51;
  }

  realZero(&uReal);
  realZero(&uImag);
  realAdd(zReal, const_29, &tReal, realContext);
  realCopy(zImag, &tImag);
  for(k=28; k>=0; k--) {
    divRealComplex((real_t *)(gammaLanczosCoefficients + k), &tReal, &tImag, &sReal, &sImag, realContext);
    realSubtract(&tReal, const_1, &tReal, realContext);
    realAdd(&uReal, &sReal, &uReal, realContext);
    realAdd(&uImag, &sImag, &uImag, realContext);
  }
  realAdd(&uReal, const_gammaC00, &tReal, realContext);
  realCopy(&uImag, &tImag);
  lnComplex(&tReal, &tImag, &sReal, &sImag, realContext);  // (s1, s2)

  realAdd(zReal, const_gammaR, &rReal, realContext);
  realCopy(zImag, &rImag);
  lnComplex(&rReal, &rImag, &uReal, &uImag, realContext);

  realAdd(zReal, const_1on2, &tReal, realContext);
  realCopy(zImag, &tImag);
  mulComplexComplex(&tReal, &tImag, &uReal, &uImag, &vReal, &vImag, realContext);

  realSubtract(&vReal, &rReal, &uReal, realContext);
  realSubtract(&vImag, zImag, &uImag, realContext);

  realContext->digits = savedContextDigits;

  realAdd(&uReal, &sReal, resReal, realContext);
  realAdd(&uImag, &sImag, resImag, realContext);
}


static void WP34S_ComplexGammaLnGamma(const real_t *zReal, const real_t *zImag, const bool_t calculateLnGamma, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t sinPiZReal, tReal, uReal, xReal;
  real_t sinPiZImag, tImag, uImag, xImag;
  bool_t reflect = false;

  // Check for special cases
  if(realIsSpecial(zReal) || realIsSpecial(zImag)) {
    if(realIsNaN(zReal) || realIsNaN(zImag)) {
      realCopy(const_NaN, resReal);
      realCopy(const_NaN, resImag);
    }
    else {
      if(realIsInfinite(zReal)) {
        if(realIsInfinite(zImag) || realIsNegative(zReal)) {
          realCopy(const_NaN, resReal);
          realCopy(const_NaN, resImag);
        }
        else {
          realCopy(const_plusInfinity, resReal);
          realZero(resImag);
        }
      }
      else {
        realZero(resReal);
        realZero(resImag);
      }
    }
    return;
  }

  // Correct our argument and begin the inversion if it is negative
  if(realIsNegative(zReal)) {
    reflect = true;
    realSubtract(const_1, zReal, &tReal, realContext);
    if(realIsZero(zImag) && realIsAnInteger(&tReal)) {
      realCopy(const_NaN, resReal);
      realCopy(const_NaN, resImag);
      return;
    }
    realSubtract(&tReal, const_1, &xReal, realContext);
    realMinus(zImag, &xImag, realContext);
  }
  else {
    realSubtract(zReal, const_1, &xReal, realContext);
    realCopy(zImag, &xImag);
  }

  // Sum the series
  WP34S_CalcComplexLnGamma_Lanczos(&xReal, &xImag, resReal, resImag, realContext);
  if(!calculateLnGamma) {
    expComplex(resReal, resImag, resReal, resImag, realContext);
  }

  // Finally invert if we started with a negative argument
  if(reflect) {
    realMultiply(zReal, const_pi, &tReal, realContext);
    realMultiply(zImag, const_pi, &tImag, realContext);
    sinComplex(&tReal, &tImag, &sinPiZReal, &sinPiZImag, realContext);
    if(!calculateLnGamma) {
      mulComplexComplex(&sinPiZReal, &sinPiZImag, resReal, resImag, &uReal, &uImag, realContext);
      divRealComplex(const_pi, &uReal, &uImag, resReal, resImag, realContext);
    }
    else {
      divRealComplex(const_pi, &sinPiZReal, &sinPiZImag, &uReal, &uImag, realContext);
      lnComplex(&uReal, &uImag, &tReal, &tImag, realContext);
      realSubtract(&tReal, resReal, resReal, realContext);
      realSubtract(&tImag, resImag, resImag, realContext);
    }
  }
}


void WP34S_ComplexGamma(const real_t *zinReal, const real_t *zinImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t zReal, zImag;

  realCopy(zinReal, &zReal);
  realCopy(zinImag, &zImag);
  WP34S_ComplexGammaLnGamma(&zReal, &zImag, false, resReal, resImag, realContext);
}


void WP34S_ComplexLnGamma(const real_t *zinReal, const real_t *zinImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t zReal, zImag;

  realCopy(zinReal, &zReal);
  realCopy(zinImag, &zImag);
  WP34S_ComplexGammaLnGamma(&zReal, &zImag, true, resReal, resImag, realContext);
}


void WP34S_Mod(const real_t *x, const real_t *y, real_t *res, realContext_t *realContext) {
  /* Declare a structure large enough to hold a really long number.
   * This structure is likely to be larger than is required.
   */
  real1071_t out;

  realDivideRemainder(x, y, (real_t *)&out, &ctxtReal1071);
  realPlus((real_t *)&out, res, realContext);
}


void WP34S_BigMod(const real_t *x, const real_t *y, real_t *res, realContext_t *realContext) {
  /* Declare a structure large enough to hold a really long number.
   * This structure is likely to be larger than is required.
   */
  real2139_t out;

  realDivideRemainder(x, y, (real_t *)&out, &ctxtReal2139);
  realPlus((real_t *)&out, res, realContext);
}


static void gser(const real_t *a, const real_t *x, const real_t *gln, real_t *res, realContext_t *realContext) {
  real_t ap, del, sum, t, u;
  int32_t i;

  if(realCompareLessEqual(x, const_0)) {
    realZero(res);
    return;
  }
  realCopy(a, &ap);
  realDivide(const_1, a, &sum, realContext);
  realCopy(&sum, &del);
  for(i=0; i<1000; i++) {
    realAdd(&ap, const_1, &ap, realContext);
    realDivide(x, &ap, &t, realContext);
    realMultiply(&del, &t, &del, realContext);
    realAdd(&sum, &del, &t, realContext);
    if(realCompareEqual(&sum, &t)) {
      break;
    }
    realCopy(&t, &sum);
  }
  WP34S_Ln(x, &t, realContext);
  realMultiply(&t, a, &u, realContext);
  realSubtract(&u, x, &t, realContext);
  realSubtract(&t, gln, &u, realContext);
  realExp(&u, &t, realContext);
  realMultiply(&sum, &t, res, realContext);
  return;
}


static void gcheckSmall(real_t *v, realContext_t *realContext) {
  if(realCompareAbsLessThan(v, const_1e_10000)) {
    realCopy(const_1e_10000, v);
  }
}


static void gcf(const real_t *a, const real_t *x, const real_t *gln, real_t *res, realContext_t *realContext) {
  real_t an, b, c, d, h, t, u, v, i;
  int32_t n;

  realAdd(x, const_1, &t, realContext);
  realSubtract(&t, a, &b, realContext);    // b = (x+1) - a
  gcheckSmall(&b, realContext);
  realCopy(const_plusInfinity, &c);
  realDivide(const_1, &b, &d, realContext);
  realCopy(&d, &h);
  realZero(&i);
  for(n=0; n<1000; n++) {
    realAdd(&i, const_1, &i, realContext);
    realSubtract(a, &i, &t, realContext);   // t = a-i
    realMultiply(&i, &t, &an, realContext); // an = -i (i-a)
    realAdd(&b, const_2, &b, realContext);
    realMultiply(&an, &d, &t, realContext);
    realAdd(&t, &b, &v, realContext);
    gcheckSmall(&v, realContext);
    realDivide(const_1, &v, &d, realContext);
    realDivide(&an, &c, &t, realContext);
    realAdd(&b, &t, &c, realContext);
    gcheckSmall(&c, realContext);
    realMultiply(&d, &c, &t, realContext);
    realMultiply(&h, &t, &u, realContext);
    if(realCompareEqual(&u, &h)) {
      break;
    }
    realCopy(&u, &h);
  }
  WP34S_Ln(x, &t, realContext);
  realMultiply(&t, a, &u, realContext);
  realSubtract(&u, x, &t, realContext);
  realSubtract(&t, gln, &u, realContext);
  realExp(&u, &t, realContext);
  realMultiply(&t, &h, res, realContext);
  return;
}


void WP34S_GammaP(const real_t *x, const real_t *a, real_t *res, realContext_t *realContext, bool_t upper, bool_t regularised) {
  real_t z, lga;

  if(realIsNegative(x) || realCompareLessEqual(a, const_0) || realIsNaN(x) || realIsNaN(a) || realIsInfinite(a)) {
    realCopy(const_NaN, res);
    return;
  }

  if(realIsInfinite(x)) {
    if(upper) {
      if(regularised) {
        realCopy(const_1, res);
        return;
      }

      WP34S_Gamma(a, res, realContext);
      return;
    }

    realZero(res);
    return;
  }

  realAdd(a, const_1, &lga, realContext);
  realCompare(x, &lga, &z, realContext);
  if(regularised) {
    WP34S_LnGamma(a, &lga, realContext);
  }
  else {
    realZero(&lga);
  }
  if(realIsNegative(&z)) {
    /* Deal with a difficult case by using the other expansion */
    int32ToReal(9000, &z);
    if(realCompareGreaterThan(a, &z)) {
      realCopy(const_995on1000, &z);
      realMultiply(a, &z, &z, realContext);
      if(realCompareGreaterThan(x, &z)) {
        goto use_cf;
      }
    }

    gser(a, x, &lga, res, realContext);
    if(upper) {
      goto invert;
    }
  }
  else {
    use_cf:
    gcf(a, x, &lga, res, realContext);
    if(!upper) {
      goto invert;
    }
  }
  return;

  invert:
  if(regularised) {
    realSubtract(const_1, res, res, realContext);
    return;
  }
  WP34S_Gamma(a, &z, realContext);
  realSubtract(&z, res, res, realContext);
  return;
}


// erf and erfc were embedded library functions on WP 34S
void WP34S_Erf(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t p, q;

  if(realIsInfinite(x)) {
    int32ToReal(realIsNegative(x) ? -1 : 1, res);
    return;
  }

  realMultiply(x, x, &p, realContext);
  WP34S_GammaP(&p, const_1on2, &p, realContext, false, false);
  realSquareRoot(const_pi, &q, realContext);
  realDivide(&p, &q, &p, realContext);
  if(realIsNegative(x)) {
    realChangeSign(&p);
  }
  realCopy(&p, res);
  return;
}


void WP34S_Erfc(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t p;

  realSquareRoot(const_2, &p, realContext);
  realMultiply(x, &p, &p, realContext);
  realChangeSign(&p);
  WP34S_Cdf_Q(&p, &p, realContext);
  realMultiply(&p, const_2, res, realContext);
}


static void check_low(real_t *d) {
  real_t real_1e_32;

  realCopy(const_1, &real_1e_32); real_1e_32.exponent -= 32;
  if(realCompareAbsLessThan(d, &real_1e_32)) {
    realCopy(d, &real_1e_32);
  }
}


static void ib_step(const real_t *aa, real_t *d, real_t *c, realContext_t *realContext) {
  real_t t, u;

  realMultiply(aa, d, &t, realContext);
  realAdd(&t, const_1, &u, realContext);   // d = 1+aa*d
  check_low(&u);
  realDivide(const_1, &u, d, realContext);
  realDivide(aa, c, &t, realContext);
  realAdd(&t, const_1, c, realContext);    // c = 1+aa/c
  check_low(c);
}


static void betacf(const real_t *a, const real_t *b, const real_t *x, real_t *r, realContext_t *realContext) {
  real_t aa, c, d, apb, am1, ap1, m, m2, oldr;
  int i;
  real_t t, u, v, w;

  realAdd(a, const_1, &ap1, realContext);        // ap1 = 1+a
  realSubtract(a, const_1, &am1, realContext);   // am1 = a-1
  realAdd(a, b, &apb, realContext);              // apb = a+b
  realCopy(const_1, &c);                         // c = 1
  realDivide(x, &ap1, &t, realContext);
  realMultiply(&t, &apb, &u, realContext);
  realSubtract(const_1, &u, &t, realContext);    // t = 1-apb*x/ap1
  check_low(&t);
  realDivide(const_1, &t, &d, realContext);      // d = 1/t
  realCopy(&d, r);    // res = d
  realZero(&m);
  for(i=0; i<500; i++) {
    realCopy(r, &oldr);
    realAdd(&m, const_1, &m, realContext);       // m = i+1
    realMultiply(&m, const_2, &m2, realContext);
    realSubtract(b, &m, &t, realContext);
    realMultiply(&t, &m, &u, realContext);
    realMultiply(&u, x, &t, realContext);        // t = m*(b-m)*x
    realAdd(&am1, &m2, &u, realContext);
    realAdd(a, &m2, &v, realContext);
    realMultiply(&u, &v, &w, realContext);       // w = (am1+m2)*(a+m2)
    realDivide(&t, &w, &aa, realContext);        // aa = t/w
    ib_step(&aa, &d, &c, realContext);
    realMultiply(r, &d, &t, realContext);
    realMultiply(&t, &c, r, realContext);        // r = r*d*c
    realAdd(a, &m, &t, realContext);
    realAdd(&apb, &m, &u, realContext);
    realMultiply(&t, &u, &w, realContext);
    realMultiply(&w, x, &t, realContext);
    realMultiply(&t, const__1, &w, realContext); // w = -(a+m)*(apb+m)*x
    realAdd(a, &m2, &t, realContext);
    realAdd(&ap1, &m2, &u, realContext);
    realMultiply(&t, &u, &v, realContext);       // v = (a+m2)*(ap1+m2)
    realDivide(&w, &v, &aa, realContext);        // aa = w/v
    ib_step(&aa, &d, &c, realContext);
    realMultiply(&d, &c, &v, realContext);
    realMultiply(r, &v, r, realContext);         // r *= d*c
    if(realCompareEqual(&oldr, r)) {
      break;
    }
  }
}


// Regularised incomplete beta function Ix(a, b)
void WP34S_betai(const real_t *b, const real_t *a, const real_t *x, real_t *res, realContext_t *realContext) {
  real_t t, u, v, w, y;
  int32_t limit = 0;

  realCompare(const_1, x, &t, realContext);
  if(realIsNegative(x) || realIsNegative(&t)) {
    realCopy(const_NaN, res);
   return;
  }

  if(realIsZero(x) || realIsZero(&t)) {
    limit = 1;
  }
  else {
    LnBeta(a, b, &u, realContext);
    WP34S_Ln(x, &v, realContext);              // v = ln(x)
    realMultiply(a, &v, &t, realContext);
    realSubtract(&t, &u, &v, realContext);     // v = lng(...)+a.ln(x)
    realSubtract(const_1, x, &y, realContext); // y = 1-x
    WP34S_Ln(&y, &u, realContext);             // u = ln(1-x)
    realMultiply(&u, b, &t, realContext);
    realAdd(&t, &v, &u, realContext);          // u = lng(...)+a.ln(x)+b.ln(1-x)
    realExp(&u, &w, realContext);
  }

  realAdd(a, b, &v, realContext);
  realAdd(&v, const_2, &u, realContext);       // u = a+b+2
  realAdd(a, const_1, &t, realContext);        // t = a+1
  realDivide(&t, &u, &v, realContext);         // u = (a+1)/(a+b+2)
  if(realCompareLessThan(x, &v)) {
    if(limit) {
      realCopy(const_0, res);
    }
    else {
      betacf(a, b, x, &t, realContext);
      realDivide(&t, a, &u, realContext);
      realMultiply(&w, &u, res, realContext);
    }
  }
  else {
    if(limit) {
      realCopy(const_1, res);
    }
    else {
      betacf(b, a, &y, &t, realContext);
      realDivide(&t, b, &u, realContext);
      realMultiply(&w, &u, &t, realContext);
      realSubtract(const_1, &t, res, realContext);
    }
  }
}


void WP34S_Bernoulli(const real_t *x, real_t *res, bool_t bn_star, realContext_t *realContext) {
  real_t p;

  if((!realIsAnInteger(x)) || realCompareLessThan(x, const_0)) {
    realCopy(const_NaN, res);
    return;
  }
  if(realIsZero(x)) {// Bn_0
    realCopy(bn_star ? const_NaN : const_1, res);
    return;
  }
  if(!bn_star) {
    if(realCompareEqual(x, const_1)) { // zeta_0
      realCopy(const_1on2, res);
      realChangeSign(res);
      return;
    }
    else if(realMultiply(x, const_1on2, &p, realContext), (!realIsAnInteger(&p))) { // Bn_odd
      realZero(res);
      return;
    }
    realCopy(x, &p);
  }
  else {
    realMultiply(x, const_2, &p, realContext);
  }

  // bernoulli
  realSubtract(&p, const_1, &p, realContext);
  realChangeSign(&p);
  WP34S_Zeta(&p, &p, realContext);
  realMultiply(&p, x, &p, realContext);
  realChangeSign(&p);

  if(bn_star) {
    realMultiply(&p, const_2, &p, realContext);
    realSetPositiveSign(&p);
  }
  realCopy(&p, res);
}


/**************************************************************************/
/* Zeta function implementation based on Jean-Marc Baillard's from:
 * http://hp41programs.yolasite.com/zeta.php
 * This is the same algorithm as the C version uses, just with fewer terms and
 * with the constants computed on the fly.
 */

static void zeta_calc(const real_t *x, real_t *reg1, real_t *reg7, real_t *res, realContext_t *realContext) {
  real_t p, q, r, s, reg0, reg3, reg4, reg5, reg6;

  int32ToReal(60/*44*/, &reg0);
  int32ToReal(60/*44*/, &reg3);
  int32ToReal(1, &reg4);
  int32ToReal(1, &reg5);
  int32ToReal(-1, &reg6);
  realZero(&p);
  do { // zeta_loop
    realMultiply(reg1, const__1, &q, realContext);
    realPower(&reg0, &q, &q, realContext);
    realMultiply(&reg5, &q, &q, realContext);
    realChangeSign(&reg6);
    realMultiply(&q, &reg6, &q, realContext);
    realAdd(&p, &q, &p, realContext);
    realMultiply(&reg0, const_2, &q, realContext);
    realMultiply(&q, &reg0, &q, realContext);
    realSubtract(&q, &reg0, &q, realContext);
    realMultiply(&q, &reg4, &q, realContext);
    realMultiply(&reg3, &reg3, &r, realContext);
    realSubtract(&reg0, const_1, &s, realContext);
    realMultiply(&s, &s, &s, realContext);
    realSubtract(&r, &s, &r, realContext);
    realMultiply(&r, const_2, &r, realContext);
    realDivide(&q, &r, &q, realContext);
    realCopy(&q, &reg4);
    realAdd(&q, &reg5, &reg5, realContext);
    realSubtract(&reg0, const_1, &reg0, realContext);
  } while(realCompareGreaterThan(&reg0, const_0));
  realDivide(&p, &reg5, &p, realContext);
  realSubtract(const_1, reg1, &r, realContext);
  realMultiply(const_ln2, &r, &r, realContext);
  WP34S_ExpM1(&r, &q, realContext);
  realDivide(&p, &q, res, realContext);
}


void WP34S_Zeta(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t p, q, r, reg1, reg7;

  if(realIsZero(x)) {
    realCopy(const_1on2, res);
    realChangeSign(res);
    return;
  }

  // zeta_int
  realCopy(x, &reg1);
  realCopy(x, &reg7);
  if(realCompareGreaterThan(x, const_1on2)) {
    zeta_calc(x, &reg1, &reg7, res, realContext);
  }
  else { // zeta_neg
    realSubtract(const_1, x, &q, realContext);
    realCopy(&q, &reg1);
    zeta_calc(&q, &reg1, &reg7, &p, realContext);
    WP34S_Asin(const_1, &q, realContext);
    realMultiply(&q, &reg7, &q, realContext);
    WP34S_Cvt2RadSinCosTan(&q, amRadian, &r, NULL, NULL, realContext);
    realMultiply(&p, &r, &p, realContext);
    realDivide(&p, const_pi, &p, realContext);
    realPower(const_2pi, &reg7, &q, realContext);
    realMultiply(&p, &q, &p, realContext);
    realCopy(&reg1, &q);
    WP34S_Gamma(&q, &r, realContext);
    realMultiply(&r, &p, res, realContext);
  }
}


/**************************************************************************/
/* A rough guess is made and then Newton's method is used to attain
 * convergence.  The C version (in ../trunk/unused/lambertW.c) works
 * similarily but uses Halley's method which converges a cubically
 * instead of quadratically.
 *
 * This code is based on a discussion on the MoHPC.  Search the archives
 * for "Lambert W (HP-41)" starting on the 2 Sept 2012.  The actual code
 * is Dieter's from a message posted on the 23rd of Sept 2012.
 */
void WP34S_LambertW(const real_t *x, real_t *res, bool_t negativeBranch, realContext_t *realContext) {
  real_t p, q, r, reg0, reg1, reg2;
  bool_t converged = false;

  if(realIsSpecial(x)) {
   realCopy(const_NaN, res);
   return;
  }
  if(realIsZero(x)) {
   realCopy(negativeBranch ? const_minusInfinity : const_0, res);
   return;
  }
  if(negativeBranch && realIsPositive(x)) {
   realCopy(const_NaN, res);
   return;
  }

  // LamW0_common
  realCopy(x, &reg0);
  int32ToReal(7, &reg1);
  int32ToReal(negativeBranch ? 25 : 35, &p), p.exponent -= 2, realChangeSign(&p);
  if(realCompareLessEqual(&reg0, &p)) {
    realDivide(const_1, const_eE, &q, realContext);
    realAdd(&reg0, &q, &q, realContext);
    realMultiply(&q, const_eE, &q, realContext);
    realCopy(&q, &reg2);
    realMultiply(&q, const_2, &q, realContext);
    realSquareRoot(&q, &r, realContext);
    if(negativeBranch) {
      realChangeSign(&r);
    }
    realMultiply(&q, const_1on3, &q, realContext);
    realSubtract(&r, &q, &q, realContext);

    // Newton iteration for W+1
    do { //LamW0_wp1_newton
      // FILL and x close to -1/e
      realMultiply(&q, const__1, &p, realContext);
      WP34S_ExpM1(&p, &p, realContext);
      realMultiply(&p, &reg0, &p, realContext);
      realMultiply(&p, const_eE, &p, realContext);
      realSubtract(&p, &q, &p, realContext);
      realAdd(&p, &reg2, &p, realContext);
      realDivide(&p, &q, &p, realContext);
      realAdd(&p, &q, &p, realContext);
      if(converged) {
        break;
      }
      if(WP34S_AbsoluteError(&p, &q, (realContext == &ctxtReal39) ? const_1e_37 : const_1e_49, realContext)) { // test if absolute error
        converged = true;
      }
      realSubtract(&reg1, const_1, &reg1, realContext);
      realCopy(&p, &q);
    } while(realCompareGreaterThan(&reg1, const_0));
    // LamW0_converged
    realSubtract(&p, const_1, res, realContext);
  }
  else {// LamW0_normal
    if(negativeBranch) {// LamW0_smallx
      realMultiply(&reg0, const__1, &q, realContext);
      WP34S_Ln(&q, &q, realContext);
      realMultiply(&q, const__1, &r, realContext);
      WP34S_Ln(&r, &r, realContext);
      realSubtract(&q, &r, &q, realContext);
    }
    else {
      WP34S_Ln1P(&reg0, &q, realContext);
      if(realCompareGreaterThan(&q, const_1)) {
        WP34S_Ln(&q, &r, realContext);
        realSubtract(&q, &r, &q, realContext);
      }
    }
    // Newton-Halley iteration for W
    // x not close to -1/e
    do { // LamW0_halley
      realExp(&q, &r, realContext);
      realDivide(&reg0, &r, &r, realContext);
      realSubtract(&q, &r, &r, realContext);
      realAdd(&q, const_1, &p, realContext);
      realDivide(&r, &p, &r, realContext);
      realDivide(const_1, &p, &p, realContext);
      realAdd(&p, const_1, &p, realContext);
      realMultiply(&p, &r, &p, realContext);
      realMultiply(&p, const_1on2, &p, realContext);
      realChangeSign(&p);
      realAdd(&p, const_1, &p, realContext);
      realDivide(&r, &p, &r, realContext);
      realSubtract(&q, &r, &r, realContext);
      // R Q Q
      if(converged) {
        break;
      }
      if(WP34S_RelativeError(&r, &q, (realContext == &ctxtReal39) ? const_1e_37 : const_1e_49, realContext)) { // test if relative error
        converged = true;
      }
      realSubtract(&reg1, const_1, &reg1, realContext);
      realCopy(&r, &q);
    } while(realCompareGreaterThan(&reg1, const_0));
    // LamW0_finish
    realCopy(&r, res);
  }
}


/**************************************************************************/
/* The positive branch of the complex W function.
 *
 * This code is based on Jean-Marc Baillard's HP-41 version from:
 * http://hp41programs.yolasite.com/lambertw.php
 *
 * Register use:
 * .00/.01 z
 * .02/.03 w
 * .04/.05 temporary
 */
void WP34S_ComplexLambertW(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t pr, pi, qr, qi, zr, zi, wr, wi, tr, ti;

  realCopy(xReal, &zr), realCopy(xImag, &zi);
  realCopy(const_1, &wr), realCopy(const_1, &wi);
  realAdd(xReal, const_1, &pr, realContext), realCopy(xImag, &pi);
  if (realIsZero(&zi) && realIsNegative(&zr) && realCompareGreaterEqual(&zr, const__1)) {
    // Close to -1/e, the series is very slow to converge
    realCopy(const_1, &pr);
    realCopy(realIsNegative(&pi) ? const__1 : const_1, &pi);
  } else if (!realIsZero(&pr) || !realIsZero(&pi)) {
    lnComplex(&pr, &pi, &pr, &pi, realContext);
    realCopy(&pr, &wr), realCopy(&pi, &wi);
  }
  while(1) { // LamW_cloop
    expComplex(&pr, &pi, &qr, &qi, realContext);
    realCopy(&qr, &tr), realCopy(&qi, &ti);
    mulComplexComplex(&qr, &qi, &wr, &wi, &qr, &qi, realContext);
    realAdd(&tr, &qr, &tr, realContext), realAdd(&ti, &qi, &ti, realContext);
    realSubtract(&qr, &zr, &qr, realContext), realSubtract(&qi, &zi, &qi, realContext);
    divComplexComplex(&qr, &qi, &tr, &ti, &qr, &qi, realContext);
    realSubtract(&wr, &qr, &wr, realContext), realSubtract(&wi, &qi, &wi, realContext);
    if(WP34S_ComplexAbsError(&wr, &wi, &pr, &pi, const_1e_37, realContext)) {
      break;
    }
    realCopy(&wr, &pr), realCopy(&wi, &pi);
  }
  realCopy(&wr, resReal), realCopy(&wi, resImag);
}


/**************************************************************************/
/* The inverse W function in both real and complex domains.
 */


void WP34S_InverseW(const real_t *x, real_t *res, realContext_t *realContext) {
  real_t p;

  realExp(x, &p, realContext);
  realMultiply(&p, x, res, realContext);
}


void WP34S_InverseComplexW(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t p, q;

  expComplex(xReal, xImag, &p, &q, realContext);
  mulComplexComplex(&p, &q, xReal, xImag, resReal, resImag, realContext);
}


// Orthogonal Polynomials, common function
void WP34S_OrthoPoly(uint16_t kind, const real_t *rX, const real_t *rN, const real_t *rParam, real_t *res, realContext_t *realContext) {
  real_t a, b, c, d, i;
  real_t rT0, rT1, incB;
  real_t p, q;
  bool_t incA = false, incC = false;

  // ortho_default
  if(realIsSpecial(rX) || (!realIsAnInteger(rN)) || realIsNegative(rN)) {
    realCopy(const_NaN, res);
    return;
  }
  if(realIsZero(rN)) {
    realCopy(const_1, res);
    return;
  }
  // Here we are free from the limitation of ISG since the code is ported to C.
  //if(realCompareGreaterEqual(rN, const_1000)) {
  //  realCopy(const_NaN, res);
  //  return;
  //}
  realCopy(const_1, &rT0);
  // Now initialise everything else
  realCopy(const_2, &i);
  realCopy(const_2, &d);
  realCopy(const_1, &c);
  realCopy(const_1, &b);
  realCopy(rX, &rT1);
  realMultiply(rX, const_2, &a, realContext);

  // We must initialise this too
  realCopy(const_0, &incB);

  switch(kind) {
  /**************************************************************************/
  /* Legendre's Pn                                                          */
    case ORTHOPOLY_LEGENDRE_P: {
      realAdd(&a, rX, &a, realContext);
      realMultiply(rX, const_2, &d, realContext);
      goto ortho_allinc;
    }

  /**************************************************************************/
  /* Chebychev's Tn                                                         */
    case ORTHOPOLY_CHEBYSHEV_T: {
      break;
    }

  /**************************************************************************/
  /* Chebychev's Un                                                         */
    case ORTHOPOLY_CHEBYSHEV_U: {
      realAdd(&rT1, rX, &rT1, realContext);
      break;
    }

  /**************************************************************************/
  /* Laguerre's Ln and Ln with parameter alpha                              */
    case ORTHOPOLY_LAGUERRE_L:
    case ORTHOPOLY_LAGUERRE_L_ALPHA: {
      // laguerre_common
      if(realIsSpecial(rParam) || realCompareLessEqual(rParam, const__1)) {
        realCopy(const_NaN, res);
        return;
      }
      realAdd(&b, rParam, &b, realContext);
      realAdd(rParam, const_3, &a, realContext);
      realSubtract(&a, rX, &a, realContext);
      realAdd(rParam, const_1, &rT1, realContext);
      realSubtract(&rT1, rX, &rT1, realContext);
      ortho_allinc:
      incA = true;
      realCopy(const_1, &incB);
      incC = true;
      break;
    }

  /**************************************************************************/
  /* Hermite's He (Hn)                                                      */
    case ORTHOPOLY_HERMITE_HE: {
      realCopy(rX, &a);
      realCopy(const_1, &incB);
      break;
    }

  /**************************************************************************/
  /* Hermite's H  (Hnp)                                                     */
    case ORTHOPOLY_HERMITE_H: {
      realAdd(&rT1, rX, &rT1, realContext);
      realCopy(const_2, &b);
      realCopy(const_2, &incB);
      break;
    }
  }

  /**************************************************************************/
  /* Common evaluation code                                                 */
  /* Everything is assumed properly set up at this point.                   */
  /* ortho_common                                                           */
  while(realCompareLessEqual(&i, rN)) { // ortho_loop
    realMultiply(&rT1, &a, &p, realContext);
    realMultiply(&rT0, &b, &q, realContext);
    realCopy(&rT1, &rT0);
    realSubtract(&p, &q, &rT1, realContext);

    if(incC) {
      realAdd(&c, const_1, &c, realContext);
      realDivide(&rT1, &c, &rT1, realContext);
    } // ortho_noC
    if(incA) {
      realAdd(&a, &d, &a, realContext);
    } // ortho_noA
    realAdd(&b, &incB, &b, realContext);
    realAdd(&i, const_1, &i, realContext);
  }
  realCopy(&rT1, res);
}
