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
 * \file arctanh.c
 ***********************************************/

#include "mathematics/arctanh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/ln.h"
#include "mathematics/matrix.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


static void arctanhCplx(void) {
  //                    1       1 + (a + ib)
  // arctanh(a + i b) = - * ln( ------------ )
  //                    2       1 - (a + ib)

  real_t numerReal, denomReal;
  real_t numerImag, denomImag;

  if(!getRegisterAsComplex(REGISTER_X, &denomImag, &numerImag))
    return;

  // numer = 1 + (a + ib)
  realAdd(&denomImag, const_1, &numerReal, &ctxtReal39);

  // denom = 1 - (a + ib)
  realSubtract(const_1, &denomImag, &denomReal, &ctxtReal39);
  realMinus(&numerImag, &denomImag, &ctxtReal39);

  // numer = (1 + (a + ib)) / (1 - (a + ib)
  divComplexComplex(&numerReal, &numerImag, &denomReal, &denomImag, &numerReal, &numerImag, &ctxtReal39);

  // numer = ln((1 + (a + ib)) / (1 - (a + ib))
  lnComplex(&numerReal, &numerImag, &numerReal, &numerImag, &ctxtReal39);

  // 1/2 * ln((1 + (a + ib)) / (1 - (a + ib))
  realMultiply(&numerReal, const_1on2, &numerReal, &ctxtReal39);
  realMultiply(&numerImag, const_1on2, &numerImag, &ctxtReal39);

  convertComplexToResultRegister(&numerReal, &numerImag, REGISTER_X);
}


static void arctanhReal(void) {
  real_t x;
  const real_t *r = &x;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if(realIsZero(&x)) {
    r = const_0;
  }
  else {
    if(realCompareEqual(&x, const_1)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        r = const_plusInfinity;
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhReal:", "X = 1", "and DANGER flag is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
       }
    }
    else if(realCompareEqual(&x, const__1)) {
      if(getSystemFlag(FLAG_SPCRES)) {
        r = const_minusInfinity;
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          moreInfoOnError("In function arctanhReal:", "X = -1", "and DANGER flag is not set!", NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
       }
    }
    else {
      if(realCompareAbsGreaterThan(&x, const_1)) {
        if(getFlag(FLAG_CPXRES)) {
          arctanhCplx();
          return;
        }
        else if(getSystemFlag(FLAG_SPCRES)) {
          r = const_NaN;
        }
        else {
          displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
          #if (EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function arctanhReal:", "|X| > 1", "and CPXRES is not set!", NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return;
        }
      }
      else {
        WP34S_ArcTanh(&x, &x, &ctxtReal39);
      }
    }
  }
  convertRealToResultRegister(r, REGISTER_X, amNone);
}


/********************************************//**
 * \brief regX ==> regL and arctanh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArctanh(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&arctanhReal, &arctanhCplx);
}
