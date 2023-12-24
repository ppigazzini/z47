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
 * \file slvc.c
 ***********************************************/

#include "mathematics/slvc.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/cubeRoot.h"
#include "mathematics/division.h"
#include "mathematics/multiplication.h"
#include "mathematics/squareRoot.h"
#include "mathematics/slvq.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"
#include "typeDefinitions.h"

#include "wp43.h"

#undef DISCRIMINANT

/********************************************//**
 * \brief (d, c, b, a) ==> (x1, x2, r) c ==> regL
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSlvc(uint16_t unusedButMandatoryParameter) {
#if !defined(SAVE_SPACE_DM42_12)
  bool_t realCoefs=true, realRoots=true;
  real_t aReal, bReal, cReal, dReal, rReal, x1Real, x2Real, x3Real;
  real_t aImag, bImag, cImag, dImag, rImag, x1Imag, x2Imag, x3Imag;

  switch(getRegisterDataType(REGISTER_X)) {
    case dtLongInteger: {
      convertLongIntegerRegisterToReal(REGISTER_X, &dReal, &ctxtReal75);
      realZero(&dImag);
      break;
    }

    case dtReal34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &dReal);
      realZero(&dImag);
      break;
    }

    case dtComplex34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &dReal);
      real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &dImag);
      realCoefs = false;
      break;
    }

    default: {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot SLVC with %s in X", getRegisterDataTypeName(REGISTER_X, true, false));
        moreInfoOnError("In function fnSlvc:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  switch(getRegisterDataType(REGISTER_Y)) {
    case dtLongInteger: {
      convertLongIntegerRegisterToReal(REGISTER_Y, &cReal, &ctxtReal75);
      realZero(&cImag);
      break;
    }

    case dtReal34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &cReal);
      realZero(&cImag);
      break;
    }

    case dtComplex34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &cReal);
      real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &cImag);
      realCoefs = false;
      break;
    }

    default: {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot SLVC with %s in Y", getRegisterDataTypeName(REGISTER_Y, true, false));
        moreInfoOnError("In function fnSlvc:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }

  switch(getRegisterDataType(REGISTER_Z)) {
    case dtLongInteger: {
      convertLongIntegerRegisterToReal(REGISTER_Z, &bReal, &ctxtReal75);
      realZero(&bImag);
      break;
    }

    case dtReal34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_Z), &bReal);
      realZero(&bImag);
      break;
    }

    case dtComplex34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_Z), &bReal);
      real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Z), &bImag);
      realCoefs = false;
      break;
    }

    default: {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Z);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot SLVC with %s in Z", getRegisterDataTypeName(REGISTER_Z, true, false));
        moreInfoOnError("In function fnSlvc:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }


  switch(getRegisterDataType(REGISTER_T)) {
    case dtLongInteger: {
      convertLongIntegerRegisterToReal(REGISTER_T, &aReal, &ctxtReal75);
      realZero(&aImag);
      break;
    }

    case dtReal34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_T), &aReal);
      realZero(&aImag);
      break;
    }

    case dtComplex34: {
      real34ToReal(REGISTER_REAL34_DATA(REGISTER_T), &aReal);
      real34ToReal(REGISTER_IMAG34_DATA(REGISTER_T), &aImag);
      realCoefs = false;
      break;
    }

    default: {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_T);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot SLVC with %s in T", getRegisterDataTypeName(REGISTER_T, true, false));
        moreInfoOnError("In function fnSlvc:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
  }



  if(   realIsZero(&aReal) && realIsZero(&aImag)
     && realIsZero(&bReal) && realIsZero(&bImag)
     && realIsZero(&cReal) && realIsZero(&cImag)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnSlvc:", "cannot use 0 for Y, Z and T as input of SLVC", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }


  if(!saveLastX()) {
    return;
  }

  if(realCoefs == false) {
    realRoots = false;
  }


  if(realIsZero(&aReal) && realIsZero(&aImag)) {
    solveQuadraticEquation(&bReal, &bImag, &cReal, &cImag, &dReal, &dImag, &rReal, &rImag, &x1Real, &x1Imag, &x2Real, &x2Imag, &ctxtReal75);
    realCopy(const_NaN, &x3Real);
    realCopy(const_NaN, &x3Imag);
    realRoots &= realIsZero(&x1Imag) && realIsZero(&x2Imag);
  } else {
    divComplexComplex(&bReal, &bImag, &aReal, &aImag, &bReal, &bImag, &ctxtReal39);
    divComplexComplex(&cReal, &cImag, &aReal, &aImag, &cReal, &cImag, &ctxtReal39);
    divComplexComplex(&dReal, &dImag, &aReal, &aImag, &dReal, &dImag, &ctxtReal39);
    solveCubicEquation(&bReal, &bImag, &cReal, &cImag, &dReal, &dImag, &rReal, &rImag, &x1Real, &x1Imag, &x2Real, &x2Imag, &x3Real, &x3Imag, &ctxtReal75);
    realRoots &= realIsZero(&x1Imag) && realIsZero(&x2Imag) && realIsZero(&x3Imag);
  }


  if(realRoots) {
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    reallocateRegister(REGISTER_Z, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    #ifdef DISCRIMINANT
      reallocateRegister(REGISTER_T, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    #endif //DISCRIMINANT
    convertRealToReal34ResultRegister(&x1Real, REGISTER_X);
    convertRealToReal34ResultRegister(&x2Real, REGISTER_Y);
    convertRealToReal34ResultRegister(&x3Real, REGISTER_Z);
    #ifdef DISCRIMINANT
      realToReal34(&rReal,  REGISTER_REAL34_DATA(REGISTER_T));
    #endif //DISCRIMINANT
  }
  else { // !realRoots
    if(realIsZero(&x1Imag)) { // x1 is real
      reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x1Real, REGISTER_X);
    }
    else {
      reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x1Real, REGISTER_X);
      convertRealToImag34ResultRegister(&x1Imag, REGISTER_X);
    }

    if(realIsZero(&x2Imag)) { // x2 is real
      reallocateRegister(REGISTER_Y, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x2Real, REGISTER_Y);
    }
    else {
      reallocateRegister(REGISTER_Y, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x2Real, REGISTER_Y);
      convertRealToImag34ResultRegister(&x2Imag, REGISTER_Y);
    }

    if(realIsZero(&x3Imag)) { // x2 is real
      reallocateRegister(REGISTER_Z, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x3Real, REGISTER_Y);
    }
    else {
      reallocateRegister(REGISTER_Z, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x3Real, REGISTER_Z);
      convertRealToImag34ResultRegister(&x3Imag, REGISTER_Z);
    }


    #ifdef DISCRIMINANT
      if(realIsZero(&rImag)) { // q3r2 is real
        reallocateRegister(REGISTER_T, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&rReal, REGISTER_T);
      }
      else {
        reallocateRegister(REGISTER_T, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(&rReal, REGISTER_T);
        convertRealToImag34ResultRegister(&rImag, REGISTER_T);
      }
    #endif //DISCRIMINANT

  }

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
  adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
  adjustResult(REGISTER_Z, false, true, REGISTER_Z, -1, -1);
  #ifdef DISCRIMINANT
    adjustResult(REGISTER_T, false, true, REGISTER_T, -1, -1);
  #else
    fnDropT(0);
  #endif //DISCRIMINANT
#endif // !SAVE_SPACE_DM42_12
}




static bool_t _checkConditionNumberOfAddSub(const real_t *operand1, const real_t *operand2, const real_t *res, realContext_t *realContext) {
  real_t conditionNumber1, conditionNumber2;
  real_t *conditionNumber = &conditionNumber1;

  if(realIsZero(res)) {
    return false;
  }
  else {
    realDivide(res, operand1, &conditionNumber1, realContext); realSetPositiveSign(&conditionNumber1);
    realDivide(res, operand2, &conditionNumber2, realContext); realSetPositiveSign(&conditionNumber2);
    if(realIsZero(operand1)) {
      conditionNumber = &conditionNumber2;
    }
    else if(realIsZero(operand2)) {
      conditionNumber = &conditionNumber1;
    }
    else if(realCompareGreaterThan(&conditionNumber1, &conditionNumber2)) {
      conditionNumber = &conditionNumber2;
    }
    else {
      conditionNumber = &conditionNumber1;
    }
    return realCompareLessThan(conditionNumber, const_1e_37);
  }
}
static void _realCheckedAdd(const real_t *operand1, const real_t *operand2, real_t *res, realContext_t *realContext) {
  real_t r;
  realAdd(operand1, operand2, &r, realContext);
  if(_checkConditionNumberOfAddSub(operand1, operand2, &r, realContext)) {
    realZero(res);
  }
  else {
    realCopy(&r, res);
  }
}
static void _realCheckedSubtract(const real_t *operand1, const real_t *operand2, real_t *res, realContext_t *realContext) {
  real_t r;
  realSubtract(operand1, operand2, &r, realContext);
  if(_checkConditionNumberOfAddSub(operand1, operand2, &r, realContext)) {
    realZero(res);
  }
  else {
    realCopy(&r, res);
  }
}

void solveCubicEquation(const real_t *c2Real, const real_t *c2Imag, const real_t *c1Real, const real_t *c1Imag, const real_t *c0Real, const real_t *c0Imag, real_t *rReal, real_t *rImag, real_t *x1Real, real_t *x1Imag, real_t *x2Real, real_t *x2Imag, real_t *x3Real, real_t *x3Imag, realContext_t *realContext) {
  // x^3 + b x^2 + c x + d = 0
  // Abramowitz & Stegun §3.8.2
  real_t qr, qi, rr, ri, s1r, s1i, s2r, s2i, ar, ai;

  // q = (c - b^2 / 3) / 3
  mulComplexComplex(c2Real, c2Imag, c2Real, c2Imag, &qr, &qi, realContext);
  realMultiply(&qr, const_1on3, &qr, realContext), realMultiply(&qi, const_1on3, &qi, realContext);
  realSubtract(c1Real, &qr, &qr, realContext), realSubtract(c1Imag, &qi, &qi, realContext);
  realMultiply(&qr, const_1on3, &qr, realContext), realMultiply(&qi, const_1on3, &qi, realContext);

  // r = (b c - 3 d) / 6 - b^3 / 27
  mulComplexComplex(c2Real, c2Imag, c1Real, c1Imag, &rr, &ri, realContext);
  realMultiply(c0Real, const_3, &ar, realContext), realMultiply(c0Imag, const_3, &ai, realContext);
  realSubtract(&rr, &ar, &rr, realContext), realSubtract(&ri, &ai, &ri, realContext);
  realDivide(&rr, const_6, &rr, realContext), realDivide(&ri, const_6, &ri, realContext);
  mulComplexComplex(c2Real, c2Imag, c2Real, c2Imag, &ar, &ai, realContext);
  mulComplexComplex(&ar, &ai, c2Real, c2Imag, &ar, &ai, realContext);
  realDivide(&ar, const_27, &ar, realContext), realDivide(&ai, const_27, &ai, realContext);
  realSubtract(&rr, &ar, &rr, realContext), realSubtract(&ri, &ai, &ri, realContext);

  // q^3 + r^2
  mulComplexComplex(&qr, &qi, &qr, &qi, rReal, rImag, realContext);
  mulComplexComplex(rReal, rImag, &qr, &qi, rReal, rImag, realContext);
  mulComplexComplex(&rr, &ri, &rr, &ri, &ar, &ai, realContext);
  realAdd(rReal, &ar, rReal, realContext), realAdd(rImag, &ai, rImag, realContext);

  // s1, s2 = cbrt(r ± sqrt(q^3 + r^2))
  sqrtComplex(rReal, rImag, &s1r, &s1i, realContext);
  realSubtract(&rr, &s1r, &s2r, realContext), realSubtract(&ri, &s1i, &s2i, realContext);
  realAdd(&rr, &s1r, &s1r, realContext), realAdd(&ri, &s1i, &s1i, realContext);
  curtComplex(&s1r, &s1i, &s1r, &s1i, realContext);
  curtComplex(&s2r, &s2i, &s2r, &s2i, realContext);

  // reusing q, r for (s1 ± s2)
  realAdd(&s1r, &s2r, &qr, realContext), realAdd(&s1i, &s2i, &qi, realContext);
  realSubtract(&s1r, &s2r, &rr, realContext), realSubtract(&s1i, &s2i, &ri, realContext);
  mulComplexComplex(&rr, &ri, const_0, const_root3on2, &rr, &ri, realContext);

  // roots
  realMultiply(c2Real, const_1on3, x2Real, realContext),   realMultiply(c2Imag, const_1on3, x2Imag, realContext);
  _realCheckedSubtract(&qr, x2Real, x1Real, realContext), _realCheckedSubtract(&qi, x2Imag, x1Imag, realContext);
  realMultiply(&qr, const_1on2, x3Real, realContext),      realMultiply(&qi, const_1on2, x3Imag, realContext);
  _realCheckedAdd(x3Real, x2Real, x3Real, realContext),   _realCheckedAdd(x3Imag, x2Imag, x3Imag, realContext);
  realChangeSign(x3Real);                                  realChangeSign(x3Imag);
  _realCheckedAdd(x3Real, &rr, x2Real, realContext),      _realCheckedAdd(x3Imag, &ri, x2Imag, realContext);
  _realCheckedSubtract(x3Real, &rr, x3Real, realContext), _realCheckedSubtract(x3Imag, &ri, x3Imag, realContext);

  // discriminant
  realMultiply(rReal, const__108, rReal, realContext);
  realMultiply(rImag, const__108, rImag, realContext);
}
