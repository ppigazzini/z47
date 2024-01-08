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
 * \file arcsinh.c
 ***********************************************/

#include "mathematics/arcsinh.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/toRect.h"
#include "mathematics/toPolar.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const arcsinh[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1             2            3            4             5             6             7            8            9             10
//          Long integer  Real34       Complex34    Time          Date          String        Real34 mat   Complex34 m  Short integer Config data
            arcsinhLonI,  arcsinhReal, arcsinhCplx, arcsinhError, arcsinhError, arcsinhError, arcsinhRema, arcsinhCxma, arcsinhError, arcsinhError
};



/********************************************//**
 * \brief Data type error in arcsinh
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void arcsinhError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate arcsinh for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnArcsinh:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and arcsinh(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnArcsinh(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  arcsinh[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void arcsinhLonI(void) {
  real_t x, xSquared;

  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);

  // arcsinh(x) = ln(x + sqrt(x� + 1))
  realMultiply(&x, &x, &xSquared, &ctxtReal39);
  realAdd(&xSquared, const_1, &xSquared, &ctxtReal39);
  realSquareRoot(&xSquared, &xSquared, &ctxtReal39);
  realAdd(&xSquared, &x, &x, &ctxtReal39);
  WP34S_Ln(&x, &x, &ctxtReal39);

  convertRealToReal34ResultRegister(&x, REGISTER_X);
}



void arcsinhRema(void) {
  elementwiseRema(arcsinhReal);
}



void arcsinhCxma(void) {
  elementwiseCxma(arcsinhCplx);
}



void arcsinhReal(void) {
  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);
  ArcsinhReal(&x, &x, &ctxtReal51);
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void arcsinhCplx(void) {
  real_t xReal, xImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  ArcsinhComplex(&xReal, &xImag, &rReal, &rImag, &ctxtReal39);

  convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
}


uint8_t ArcsinhReal(const real_t *x, real_t *res, realContext_t *realContext) {
  if(realIsInfinite(x)) {
    realCopy(realIsNegative(x) ? const_minusInfinity : const_plusInfinity, res);
  }
  else {
    WP34S_ArcSinh(x, res, realContext);
  }

  return ERROR_NONE;
}


uint8_t ArcsinhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  real_t a, b;

  realCopy(xReal, &a);
  realCopy(xImag, &b);

  // arcsinh(z) = ln(z + sqrt(z� + 1))
  // calculate z�   real part
  realMultiply(&b, &b, rReal, realContext);
  realChangeSign(rReal);
  realFMA(&a, &a, rReal, rReal, realContext);

  // calculate z�   imaginary part
  realMultiply(&a, &b, rImag, realContext);
  realMultiply(rImag, const_2, rImag, realContext);

  // calculate z� + 1
  realAdd(rReal, const_1, rReal, realContext);

  // calculate sqrt(z� + 1)
  realRectangularToPolar(rReal, rImag, rReal, rImag, realContext);
  realSquareRoot(rReal, rReal, realContext);
  realMultiply(rImag, const_1on2, rImag, realContext);
  realPolarToRectangular(rReal, rImag, rReal, rImag, realContext);

  // calculate z + sqrt(z� + 1)
  realAdd(&a, rReal, rReal, realContext);
  realAdd(&b, rImag, rImag, realContext);

  // calculate ln(z + sqtr(z� + 1))
  realRectangularToPolar(rReal, rImag, &a, &b, realContext);
  WP34S_Ln(&a, &a, realContext);

  realCopy(&a, rReal);
  realCopy(&b, rImag);

  return ERROR_NONE;
}
