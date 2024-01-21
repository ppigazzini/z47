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
 * \file gev.c
 ***********************************************/

#include "distributions/gev.h"

#include "constantPointers.h"
#include "error.h"
#include "flags.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/expMOne.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "c47.h"

static bool_t checkParamGEV(real_t *x, real_t *mu, real_t *sigma, real_t *xi, bool_t qf) {
  real_t t;

  if (!getRegisterAsReal(REGISTER_X, x)
      || !getRegisterAsReal(REGISTER_M, mu)
      || !getRegisterAsReal(REGISTER_S, sigma)
      || !getRegisterAsReal(REGISTER_Q, xi))
    goto err;

  if(realIsNegative(x)) {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamGeometric:", "cannot calculate for x < 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }
  else if(realIsZero(sigma) || realIsNegative(sigma)) {
    displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function checkParamGEV:", "the parameter sigma must be positive", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    goto err;
  }

  // Check support range
  if (qf || realIsZero(xi))
    return true;                                // xi = 0, full line
  realSubtract(mu, sigma, &t, &ctxtReal39);
  realDivide(&t, xi, &t, &ctxtReal39);
  if (realIsNegative(xi))
    return realCompareLessEqual(x, &t);         // xi < 0, (-inf, (mu-sigma)/xi]
  return realCompareGreaterEqual(x, &t);        // xi > 0, [(mu-sigma)/xi, +inf)

  err:
  if(getSystemFlag(FLAG_SPCRES)) {
    convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
  }
  return false;
}

static void tGEV(const real_t *x, const real_t *mu, const real_t *sigma, const real_t *xi, real_t *t) {
  real_t z;

  realSubtract(x, mu, &z, &ctxtReal39);
  realDivide(&z, sigma, &z, &ctxtReal39);   // z = (x - mu) / sigma

  if (!realIsZero(xi)) {
    realMultiply(&z, xi, &z, &ctxtReal39);    // z = xi (x - mu) / sigma
    WP34S_Ln1P(&z, &z, &ctxtReal39);
    realDivide(&z, xi, &z, &ctxtReal39);
  }
  realChangeSign(&z);
  realExp(&z, t, &ctxtReal39);
}

void fnGEVP(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi, t, u, v;

  if (!checkParamGEV(&x, &mu, &sigma, &xi, false))
    return;
  tGEV(&x, &mu, &sigma, &xi, &t);
  realAdd(&t, const_1, &u, &ctxtReal39);
  realPower(&t, &u, &v, &ctxtReal39);       // v= t^(xi+1)
  realDivide(&v, &sigma, &u, &ctxtReal39);   // u = t^(xi+1) / sigma
  realChangeSign(&t);
  realExp(&t, &v, &ctxtReal39);             // v = e^-t
  realMultiply(&v, &u, &x, &ctxtReal39);
  convertRealToResultRegister(&x, REGISTER_X, amNone);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

static void lowerLnGEV(const real_t *x, const real_t *mu, const real_t *sigma, const real_t *xi, real_t *z) {
  tGEV(x, mu, sigma, xi, z);
  realChangeSign(z);
}

void fnGEVL(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi;

  if (!checkParamGEV(&x, &mu, &sigma, &xi, false))
    return;
  lowerLnGEV(&x, &mu, &sigma, &xi, &x);
  realExp(&x, &x, &ctxtReal39);
  convertRealToResultRegister(&x, REGISTER_X, amNone);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

void fnGEVR(uint16_t unusedButMandatoryParameter) {
  real_t x, mu, sigma, xi;

  if (!checkParamGEV(&x, &mu, &sigma, &xi, false))
    return;
  lowerLnGEV(&x, &mu, &sigma, &xi, &x);
  realExpM1(&x, &x, &ctxtReal39);
  realChangeSign(&x);
  convertRealToResultRegister(&x, REGISTER_X, amNone);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

void fnGEVI(uint16_t unusedButMandatoryParameter) {
  real_t p, mu, sigma, xi, t, x;

  if (!checkParamGEV(&p, &mu, &sigma, &xi, true))
    return;

  if(realCompareLessEqual(&p, const_0) || realCompareGreaterEqual(&p, const_1)) {
    displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnExponentialI:", "the argument must be 0 < x < 1", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    return;
  }
  tGEV(&p, &mu, &sigma, &xi, &t);

  convertRealToResultRegister(&x, REGISTER_X, amNone);
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}

