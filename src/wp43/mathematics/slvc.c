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
#include "mathematics/magnitude.h"
#include "mathematics/multiplication.h"
#include "mathematics/squareRoot.h"
#include "mathematics/slvq.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"
#include "typeDefinitions.h"

#include "wp43.h"

#undef DISCRIMINANT //Note the testSuite tests were revised to remove the discriminant


bool_t _sortReal(register_t r1, register_t r2, register_t r3, real_t *v1, real_t *v2, real_t *v3) {
  if(realIsNaN(v1) || (!realCompareAbsGreaterThan(v1, v2) && !realCompareAbsGreaterThan(v1, v3))) {
      reallocateRegister(r1, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      reallocateRegister(r2, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      reallocateRegister(r3, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(v1, r1);
      if(!realCompareAbsGreaterThan(v2, v3)) {
        convertRealToReal34ResultRegister(v2, r2);
        convertRealToReal34ResultRegister(v3, r3);
      } else {
        convertRealToReal34ResultRegister(v3, r2);
        convertRealToReal34ResultRegister(v2, r3);
      }
      return true;
    } else {
      return false;
    }
  }


bool_t _sortComplex(register_t r1, register_t r2, register_t r3, real_t *v1r, real_t *v1i, real_t *v2r, real_t *v2i, real_t *v3r, real_t *v3i) {
  real_t v1a, v2a, v3a;
  complexMagnitude(v1r, v1i, &v1a, &ctxtReal39);
  complexMagnitude(v2r, v2i, &v2a, &ctxtReal39);
  complexMagnitude(v3r, v3i, &v3a, &ctxtReal39);
  if(realIsNaN(&v1a)) {
    realCopy(const_plusInfinity, &v1a);
  }
  if(realIsNaN(&v2a)) {
    realCopy(const_plusInfinity, &v2a);
  }
  if(realIsNaN(&v3a)) {
    realCopy(const_plusInfinity, &v3a);
  }

  if(!realCompareAbsGreaterThan(&v1a, &v2a) && !realCompareAbsGreaterThan(&v1a, &v3a)) {
    if(realIsZero(v1i) || (realIsNaN(v1r) && (realIsNaN(v1i)))) {
      reallocateRegister(r1, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(v1r, r1);
    } else {
      reallocateRegister(r1, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(v1r, r1);
      convertRealToImag34ResultRegister(v1i, r1);
    }
    if(!realCompareAbsGreaterThan(&v2a, &v3a)) {
      if(realIsZero(v2i) || (realIsNaN(v2r) && (realIsNaN(v2i)))) {
        reallocateRegister(r2, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v2r, r2);
      } else {
        reallocateRegister(r2, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v2r, r2);
        convertRealToImag34ResultRegister(v2i, r2);
      }
      if(realIsZero(v3i) || (realIsNaN(v3r) && (realIsNaN(v3i)))) {
        reallocateRegister(r3, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v3r, r3);
      } else {
        reallocateRegister(r3, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v3r, r3);
        convertRealToImag34ResultRegister(v3i, r3);
      }
    } else {
      if(realIsZero(v3i) || (realIsNaN(v3r) && (realIsNaN(v3i)))) {
        reallocateRegister(r2, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v3r, r2);
      } else {
        reallocateRegister(r2, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v3r, r2);
        convertRealToImag34ResultRegister(v3i, r2);
      }
      if(realIsZero(v2i) || (realIsNaN(v2r) && (realIsNaN(v2i)))) {
        reallocateRegister(r3, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v2r, r3);
      } else {
        reallocateRegister(r3, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
        convertRealToReal34ResultRegister(v2r, r3);
        convertRealToImag34ResultRegister(v2i, r3);
      }
    }
    return true;
  } else {
    return false;
  }
}


/********************************************//**
 * \brief (d, c, b, a) ==> (x1, x2, r) c ==> regL
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnSlvc(uint16_t unusedButMandatoryParameter) {
#if !defined(SAVE_SPACE_DM42_12)
  bool_t realCoefs=false, realRoots=true, complexCoefs=false;
  real_t aReal, bReal, cReal, dReal, rReal, x1Real, x2Real, x3Real;
  real_t aImag, bImag, cImag, dImag, rImag, x1Imag, x2Imag, x3Imag;

  if(!(getRegisterAsComplexOrReal(REGISTER_X, &dReal, &dImag, &complexCoefs) &&
       getRegisterAsComplexOrReal(REGISTER_Y, &cReal, &cImag, &complexCoefs) &&
       getRegisterAsComplexOrReal(REGISTER_Z, &bReal, &bImag, &complexCoefs) &&
       getRegisterAsComplexOrReal(REGISTER_T, &aReal, &aImag, &complexCoefs))) {
    return;
  }
  realCoefs = !complexCoefs;

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


  if(false && realRoots) {
    #ifdef DISCRIMINANT
      reallocateRegister(REGISTER_T, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    #endif //DISCRIMINANT

    //printf("REAL:\n");
    //printRealToConsole(&x1Real,"x1:"," ");
    //printRealToConsole(&x1Imag,"+i ","\n");
    //printRealToConsole(&x2Real,"x2:"," ");
    //printRealToConsole(&x2Imag,"+i ","\n");
    //printRealToConsole(&x3Real,"x3:"," ");
    //printRealToConsole(&x3Imag,"+i ","\n");


    if(!_sortReal(REGISTER_X, REGISTER_Y, REGISTER_Z, &x1Real, &x2Real, &x3Real)) {
      if(!_sortReal(REGISTER_X, REGISTER_Y, REGISTER_Z, &x2Real, &x1Real, &x3Real)) { 
        if(!_sortReal(REGISTER_X, REGISTER_Y, REGISTER_Z, &x3Real, &x2Real, &x1Real)) {
          #if defined (PC_BUILD)
            printf("In function fnSlvc real root selection failed.\n");
          #endif
        }
      }
    }
    #ifdef DISCRIMINANT
      realToReal34(&rReal,  REGISTER_REAL34_DATA(REGISTER_T));
    #endif //DISCRIMINANT
  }
  else { // !realRoots

    //printf("NON REAL:\n");
    //printRealToConsole(&x1Real,"x1:"," ");
    //printRealToConsole(&x1Imag,"+i ","\n");
    //printRealToConsole(&x2Real,"x2:"," ");
    //printRealToConsole(&x2Imag,"+i ","\n");
    //printRealToConsole(&x3Real,"x3:"," ");
    //printRealToConsole(&x3Imag,"+i ","\n");

    if(!_sortComplex(REGISTER_X, REGISTER_Y, REGISTER_Z, &x1Real, &x1Imag, &x2Real, &x2Imag, &x3Real, &x3Imag)) {
      if(!_sortComplex(REGISTER_X, REGISTER_Y, REGISTER_Z, &x2Real, &x2Imag, &x1Real, &x1Imag, &x3Real, &x3Imag)) { 
        if(!_sortComplex(REGISTER_X, REGISTER_Y, REGISTER_Z, &x3Real, &x3Imag, &x2Real, &x2Imag, &x1Real, &x1Imag)) {
          #if defined (PC_BUILD)
            printf("In function fnSlvc complex root selection failed.\n");
          #endif
        }
      }
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
  realDivide(&qr, const_3, &qr, realContext), realDivide(&qi, const_3, &qi, realContext);
  realSubtract(c1Real, &qr, &qr, realContext), realSubtract(c1Imag, &qi, &qi, realContext);
  realDivide(&qr, const_3, &qr, realContext), realDivide(&qi, const_3, &qi, realContext);

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
  realDivide(c2Real, const_3, x2Real, realContext),   realDivide(c2Imag, const_3, x2Imag, realContext);
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
