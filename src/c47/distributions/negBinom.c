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
 * \file negBinom.c
 ***********************************************/

#include "distributions/negBinom.h"

#include "constantPointers.h"
#include "distributions/chi2.h"
#include "distributions/f.h"
#include "distributions/poisson.h"
#include "error.h"
#include "flags.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/cpyx.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


#if defined(SAVE_SPACE_DM42_15)
  void fnNegBinomialP  (uint16_t unusedButMandatoryParameter){}
  void fnNegBinomialL  (uint16_t unusedButMandatoryParameter){}
  void fnNegBinomialR  (uint16_t unusedButMandatoryParameter){}
  void fnNegBinomialI  (uint16_t unusedButMandatoryParameter){}
  void pdf_NegBinomial (const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext){}
  void cdfu_NegBinomial(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext){}
  void cdf_NegBinomial (const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext){}
  void cdf_NegBinomial2(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext){}
  void qf_NegBinomial  (const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext){}

#else
  static bool_t checkParamNegBinom(real_t *x, real_t *i, real_t *j) {
    if (!getRegisterAsReal(REGISTER_X, x)
        || !getRegisterAsReal(REGISTER_P, i)
        || !getRegisterAsReal(REGISTER_N, j))
      goto err;

    if(!checkRegisterNoFP(j)) {
      displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamNegBinom:", "r is not an integer", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto err;
    }
    else if(realIsNegative(x)) {
      displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamNegBinom:", "cannot calculate for x < 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto err;
    }
    else if(realIsZero(i) || realIsNegative(i) || realCompareGreaterEqual(i, const_1) || realIsZero(j) || realIsNegative(j)) {
      displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamNegBinom:", "the parameters must be 0 < p < 1 and r > 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto err;
    }
    return true;

  err:
    if(getSystemFlag(FLAG_SPCRES)) {
      convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
    }
    return false;
  }


  void fnNegBinomialP(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, prob, num;

    if(!saveLastX()) {
      return;
    }

    if(checkParamNegBinom(&val, &prob, &num)) {
      if(realIsAnInteger(&val)) {
        pdf_NegBinomial(&val, &prob, &num, &ans, &ctxtReal39);
      }
      else {
        realZero(&ans);
      }
      if(realIsNaN(&ans)) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnNegBinomialP:", "a parameter is invalid", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      else {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&ans, REGISTER_X);
      }
    }

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }


  void fnNegBinomialL(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, prob, num;

    if(!saveLastX()) {
      return;
    }

    if(checkParamNegBinom(&val, &prob, &num)) {
      cdf_NegBinomial(&val, &prob, &num, &ans, &ctxtReal39);
      if(realIsNaN(&ans)) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnNegBinomialL:", "a parameter is invalid", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      else {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&ans, REGISTER_X);
      }
    }

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }


  void fnNegBinomialR(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, prob, num;

    if(!saveLastX()) {
      return;
    }

    if(checkParamNegBinom(&val, &prob, &num)) {
      cdfu_NegBinomial(&val, &prob, &num, &ans, &ctxtReal39);
      if(realIsNaN(&ans)) {
        displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnNegBinomialR:", "a parameter is invalid", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      else {
        reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&ans, REGISTER_X);
      }
    }

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }


  void fnNegBinomialI(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, prob, num;

    if(!saveLastX()) {
      return;
    }

    if(checkParamNegBinom(&val, &prob, &num)) {
      if(realCompareLessEqual(&val, const_0) || realCompareGreaterEqual(&val, const_1)) {
        displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnNegBinomialI:", "the argument must be 0 < x < 1", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        }
        return;
      }
      qf_NegBinomial(&val, &prob, &num, &ans, &ctxtReal39);
      if(realIsNaN(&ans)) {
        displayDomainErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnNegBinomialI:", "WP34S_Qf_Binomial did not converge", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        }
        return;
      }
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&ans, REGISTER_X);
    }

    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }


  bool_t negBinom_param(const real_t *r, real_t *res) {
    if(realIsSpecial(r)) {
      realCopy(const_NaN, res);
      return false;
    }
    if((!realIsPositive(r)) || (!realIsAnInteger(r))) {
      realCopy(const_0, res);
      return false;
    }
    return true;
  }

  // PDF[NB(r, p)](k) = [(k + r - 1) C k] p^k (1 - p)^r
  void pdf_NegBinomial(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext) {
    real_t p, q, xx, c;

    if(!negBinom_param(r, res)) {
      return;
    }
    if(realIsNegative(x)) {
      realZero(res);
      return;
    }

    realMultiply(p0, const__1, &p, realContext);
    WP34S_Ln1P(&p, &p, realContext);       // ln(1 - p0)
    realMultiply(&p, r, &p, realContext);  // ln((1 - p0) ^ r)

    WP34S_Ln(p0, &q, realContext);
    realMultiply(&q, x, &q, realContext);  // ln(p0 ^ x)
    realAdd(&p, &q, &p, realContext);

    realAdd(x, r, &q, realContext);
    realSubtract(&q, const_1, &q, realContext);
    realCopy(x, &xx);
    logCyxReal(&q, &xx, &c, realContext);

    realAdd(&p, &c, &p, realContext);
    realExp(&p, res, realContext);
  }

  // I[p](k, r)
  void cdfu_NegBinomial(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext) {
    real_t p;

    if(!negBinom_param(r, res)) {
      return;
    }
    realToIntegralValue(x, &p, DEC_ROUND_CEILING, realContext);
    if(realCompareLessThan(&p, const_1)) {
      realCopy(const_1, res);
      return;
    }

    WP34S_betai(r, &p, p0, res, realContext);
  }

  // 1 - I[p](k + 1, r)
  void cdf_NegBinomial(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext) {
    real_t p;

    if(!negBinom_param(r, res)) {
      return;
    }
    realToIntegralValue(x, &p, DEC_ROUND_FLOOR, realContext);
    cdf_NegBinomial2(&p, p0, r, res, realContext);
  }

  void cdf_NegBinomial2(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext) {
    real_t p, q;

    if(realCompareLessThan(x, const_0)) {
      realZero(res);
      return;
    }

    realSubtract(const_1, p0, &p, realContext);

    realAdd(x, const_1, &q, realContext);
    WP34S_betai(&q, r, &p, res, realContext);
  }

  void qf_NegBinomial(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext) {
    real_t p0c, pr, mean, var, s;

    if(!negBinom_param(r, res)) {
      return;
    }
    if(realCompareLessEqual(x, const_0)) {
      realZero(res);
      return;
    }

    realSubtract(const_1, p0, &p0c, realContext); // 1 - p
    realMultiply(p0, r, &pr, realContext);
    realDivide(&pr, &p0c, &mean, realContext);    // mean = pr/(1-p)

    realDivide(&mean, &p0c, &var, realContext);   // variance = pr/((1-p)^2)
    realSquareRoot(&var, &var, realContext);

    WP34S_normal_moment_approx(x, &var, &mean, &s, realContext);
    WP34S_Qf_Newton(QF_NEWTON_NEGBINOM, x, &s, p0, r, NULL, res, realContext);
  }

#endif //SAVE_SPACE_DM42_15

