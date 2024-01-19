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
 * \file exponential.c
 ***********************************************/

#include "distributions/exponential.h"

#include "constantPointers.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


#if defined(SAVE_SPACE_DM42_15)
  void fnExponentialP  (uint16_t unusedButMandatoryParameter){}
  void fnExponentialL  (uint16_t unusedButMandatoryParameter){}
  void fnExponentialR  (uint16_t unusedButMandatoryParameter){}
  void fnExponentialI  (uint16_t unusedButMandatoryParameter){}
  void WP34S_Pdf_Expon (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext){}
  void WP34S_Cdfu_Expon(const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext){}
  void WP34S_Cdf_Expon (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext){}
  void WP34S_Qf_Expon  (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext){}

#else
  static bool_t checkParamExponential(real_t *x, real_t *i) {
    if (!getRegisterAsReal(REGISTER_X, x)
        || !getRegisterAsReal(REGISTER_R, i))
      goto err;

    if(realIsNegative(x)) {
      displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamExponential:", "cannot calculate for x < 0", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      goto err;
    }
    else if(realIsZero(i) || realIsNegative(i)) {
      displayDomainErrorMessage(ERROR_INVALID_DISTRIBUTION_PARAM, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function checkParamExponential:", "cannot calculate for " STD_lambda " " STD_LESS_EQUAL " 0", NULL, NULL);
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


  void fnExponentialP(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, dof;

    if(!saveLastX()) {
      return;
    }

    if(checkParamExponential(&val, &dof)) {
      WP34S_Pdf_Expon(&val, &dof, &ans, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&ans, REGISTER_X);
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
  }


  void fnExponentialL(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, dof;

    if(!saveLastX()) {
      return;
    }

    if(checkParamExponential(&val, &dof)) {
      WP34S_Cdf_Expon(&val, &dof, &ans, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&ans, REGISTER_X);
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
  }


  void fnExponentialR(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, dof;

    if(!saveLastX()) {
      return;
    }

    if(checkParamExponential(&val, &dof)) {
      WP34S_Cdfu_Expon(&val, &dof, &ans, &ctxtReal39);
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&ans, REGISTER_X);
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
  }


  void fnExponentialI(uint16_t unusedButMandatoryParameter) {
    real_t val, ans, dof;

    if(!saveLastX()) {
      return;
    }

    if(checkParamExponential(&val, &dof)) {
      if(realCompareLessEqual(&val, const_0) || realCompareGreaterEqual(&val, const_1)) {
        displayDomainErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnExponentialI:", "the argument must be 0 < x < 1", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        }
        return;
      }
      WP34S_Qf_Expon(&val, &dof, &ans, &ctxtReal39);
      if(realIsNaN(&ans)) {
        displayDomainErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function fnExponentialI:", "WP34S_Qf_Expon did not converge", NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        if(getSystemFlag(FLAG_SPCRES)) {
          convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
        }
        return;
      }
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&ans, REGISTER_X);
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
  }



  /******************************************************
   * This functions are borrowed from the WP34S project
   ******************************************************/

  void WP34S_Pdf_Expon(const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext) {
    if(realCompareLessEqual(x, const_0)) {
      realCopy(const_0, res);
      return;
    }
    if(realIsSpecial(lambda)) {
      realZero(res); /* Can only be infinite which has zero probability */
      return;
    }
    realMultiply(x, lambda, res, realContext);
    realChangeSign(res);
    realExp(res, res, realContext);
    realMultiply(res, lambda, res, realContext);
  }

  void WP34S_Cdfu_Expon(const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext) {
    if(realCompareLessEqual(x, const_0)) {
      realCopy(const_1, res);
      return;
    }
    if(realIsSpecial(lambda)) {
      realCopy(const_plusInfinity, res);
      return;
    }
    realMultiply(x, lambda, res, realContext);
    if(realCompareLessThan(res, const_0)) {
      realCopy(const_1, res);
      return;
    }
    realChangeSign(res);
    realExp(res, res, realContext);
  }

  void WP34S_Cdf_Expon(const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext) {
    if(realCompareLessEqual(x, const_0)) {
      realCopy(const_0, res);
      return;
    }
    if(realIsSpecial(lambda)) {
      realCopy(const_plusInfinity, res);
      return;
    }
    realMultiply(x, lambda, res, realContext);
    if(realCompareLessThan(res, const_0)) {
      realCopy(const_1, res);
      return;
    }
    realChangeSign(res);
    WP34S_ExpM1(res, res, realContext);
    realChangeSign(res);
  }

  void WP34S_Qf_Expon(const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext) {
    real_t p;

    realSubtract(const_0, x, &p, realContext), WP34S_Ln1P(&p, res, realContext);
    realDivide(res, lambda, res, realContext);
    realChangeSign(res);
  }

#endif //SAVE_SPACE_DM42_15
