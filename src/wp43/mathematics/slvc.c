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
#include "mathematics/addition.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/cubeRoot.h"
#include "mathematics/division.h"
#include "mathematics/magnitude.h"
#include "mathematics/multiplication.h"
#include "mathematics/squareRoot.h"
#include "mathematics/slvq.h"
#include "mathematics/subtraction.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "stack.h"
#include "typeDefinitions.h"

#include "wp43.h"

#undef DISCRIMINANT //Note the testSuite tests were revised to remove the discriminant

struct cmplxPair {
  real_t r, i;
};

static int cmplxSortCompare(const void *v1, const void *v2) {
  const struct cmplxPair *p1 = (const struct cmplxPair *)v1;
  const struct cmplxPair *p2 = (const struct cmplxPair *)v2;
  real_t v1a, v2a, c;

  complexMagnitude2(&p1->r, &p1->i, &v1a, &ctxtReal39);
  complexMagnitude2(&p2->r, &p2->i, &v2a, &ctxtReal39);

  if (realIsNaN(&v1a)) {
    if (realIsNaN(&v2a))
      return 0;
    return 1;
  }
  if (realIsNaN(&v2a))
    return -1;
  realCompare(&v1a, &v2a, &c, &ctxtReal75);
  if (realIsZero(&c))
    return 0;
  return realIsNegative(&c) ? -1 : 1;
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
  bool_t complexCoefs=false;
  real_t aReal, bReal, cReal, dReal, rReal;
  real_t aImag, bImag, cImag, dImag, rImag;
  struct cmplxPair x[3];

  if(!(getRegisterAsComplexOrReal(REGISTER_X, &dReal, &dImag, &complexCoefs) &&
       getRegisterAsComplexOrReal(REGISTER_Y, &cReal, &cImag, &complexCoefs) &&
       getRegisterAsComplexOrReal(REGISTER_Z, &bReal, &bImag, &complexCoefs) &&
       getRegisterAsComplexOrReal(REGISTER_T, &aReal, &aImag, &complexCoefs))) {
    return;
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


  if(realIsZero(&aReal) && realIsZero(&aImag)) {
    solveQuadraticEquation(&bReal, &bImag, &cReal, &cImag, &dReal, &dImag, &rReal, &rImag, &x[0].r, &x[0].i, &x[1].r, &x[1].i, &ctxtReal75);
    realCopy(const_NaN, &x[2].r);
    realCopy(const_NaN, &x[2].i);
  } else {
    divComplexComplex(&bReal, &bImag, &aReal, &aImag, &bReal, &bImag, &ctxtReal75);
    divComplexComplex(&cReal, &cImag, &aReal, &aImag, &cReal, &cImag, &ctxtReal75);
    divComplexComplex(&dReal, &dImag, &aReal, &aImag, &dReal, &dImag, &ctxtReal75);
    solveCubicEquation(&bReal, &bImag, &cReal, &cImag, &dReal, &dImag, &rReal, &rImag, &x[0].r, &x[0].i, &x[1].r, &x[1].i, &x[2].r, &x[2].i, &ctxtReal75);
  }

  qsort(x, 3, sizeof(x[0]), &cmplxSortCompare);
  for (int i = 0; i < 3; i++) {
    if (realIsZero(&x[i].i) || (realIsNaN(&x[i].r) && realIsNaN(&x[i].i))) {
      reallocateRegister(REGISTER_X + i, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x[i].r, REGISTER_X + i);
    } else {
      reallocateRegister(REGISTER_X + i, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
      convertRealToReal34ResultRegister(&x[i].r, REGISTER_X + i);
      convertRealToImag34ResultRegister(&x[i].i, REGISTER_X + i);
    }
    adjustResult(REGISTER_X + i, false, true, REGISTER_X + i, -1, -1);
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
  const bool_t realIn = realIsZero(c2Imag) && realIsZero(c1Imag) && realIsZero(c0Imag);

  // q = (c - b^2 / 3) / 3
  mulComplexComplex(c2Real, c2Imag, c2Real, c2Imag, &qr, &qi, realContext);
  divComplexReal(&qr, &qi, const_3, &qr, &qi, realContext);
  complexSubtract(c1Real, c1Imag, &qr, &qi, &qr, &qi, realContext);
  divComplexReal(&qr, &qi, const_3, &qr, &qi, realContext);

  // r = (b c - 3 d) / 6 - b^3 / 27
  mulComplexComplex(c2Real, c2Imag, c1Real, c1Imag, &rr, &ri, realContext);
  mulComplexReal(c0Real, c0Imag, const_3, &ar, &ai, realContext);
  complexSubtract(&rr, &ri, &ar, &ai, &rr, &ri, realContext);
  divComplexReal(&rr, &ri, const_6, &rr, &ri, realContext);
  mulComplexComplex(c2Real, c2Imag, c2Real, c2Imag, &ar, &ai, realContext);
  mulComplexComplex(&ar, &ai, c2Real, c2Imag, &ar, &ai, realContext);
  divComplexReal(&ar, &ai, const_27, &ar, &ai, realContext);
  complexSubtract(&rr, &ri, &ar, &ai, &rr, &ri, realContext);

  // q^3 + r^2
  mulComplexComplex(&qr, &qi, &qr, &qi, rReal, rImag, realContext);
  mulComplexComplex(rReal, rImag, &qr, &qi, rReal, rImag, realContext);
  mulComplexComplex(&rr, &ri, &rr, &ri, &ar, &ai, realContext);
  complexAdd(rReal, rImag, &ar, &ai, rReal, rImag, realContext);

  // s1, s2 = cbrt(r ± sqrt(q^3 + r^2))
  sqrtComplex(rReal, rImag, &s1r, &s1i, realContext);
  complexSubtract(&rr, &ri, &s1r, &s1i, &s2r, &s2i, realContext);
  complexAdd(&rr, &ri, &s1r, &s1i, &s1r, &s1i, realContext);
  curtComplex(&s1r, &s1i, &s1r, &s1i, realContext);
  curtComplex(&s2r, &s2i, &s2r, &s2i, realContext);

  // reusing q, r for (s1 ± s2)
  complexAdd(&s1r, &s1i, &s2r, &s2i, &qr, &qi, realContext);
  complexSubtract(&s1r, &s1i, &s2r, &s2i, &rr, &ri, realContext);
  mulComplexComplex(&rr, &ri, const_0, const_root3on2, &rr, &ri, realContext);

  // roots
  divComplexReal(c2Real, c2Imag, const_3, x2Real, x2Imag, realContext);
  _realCheckedSubtract(&qr, x2Real, x1Real, realContext); _realCheckedSubtract(&qi, x2Imag, x1Imag, realContext);
  mulComplexReal(&qr, &qi, const_1on2, x3Real, x3Imag, realContext);
  _realCheckedAdd(x3Real, x2Real, x3Real, realContext);   _realCheckedAdd(x3Imag, x2Imag, x3Imag, realContext);
  realChangeSign(x3Real);                                  realChangeSign(x3Imag);
  _realCheckedAdd(x3Real, &rr, x2Real, realContext);      _realCheckedAdd(x3Imag, &ri, x2Imag, realContext);
  _realCheckedSubtract(x3Real, &rr, x3Real, realContext); _realCheckedSubtract(x3Imag, &ri, x3Imag, realContext);

  // Force real outputs when the roots are known to be real
  if (realIn) {
    if (realIsZero(rReal) || realIsNegative(rImag)) {
      /* Three real roots */
      realCopy(const_0, x1Imag);
      realCopy(const_0, x2Imag);
      realCopy(const_0, x3Imag);
    } else {
      /* One real, two complex roots */
      if (realCompareAbsLessThan(x1Imag, x2Imag)) {
        if (realCompareAbsLessThan(x1Imag, x3Imag))
          realCopy(const_0, x1Imag);
        else
          realCopy(const_0, x3Imag);
      } else {
        if (realCompareAbsLessThan(x2Imag, x3Imag))
          realCopy(const_0, x2Imag);
        else
          realCopy(const_0, x3Imag);
      }
    }
  }

#ifdef DISCRIMINANT
  // discriminant
  mulComplexReal(rReal, rImag, const__108, rReal, rImag, realContext);
#endif
}
