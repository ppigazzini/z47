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
 * \file differentiate.c
 ***********************************************/

#include "solver/differentiate.h"
#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "programming/lblGtoXeq.h"
#include "programming/manage.h"
#include "realType.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "solver/equation.h"
#include "stack.h"
#include "c47.h"

void fn1stDeriv(uint16_t label) {
  currentSolverStatus &= !SOLVER_STATUS_USES_FORMULA;
  bool_t solving = getSystemFlag(FLAG_SOLVING);
  setSystemFlag(FLAG_SOLVING);
  if(label >= FIRST_LABEL && label <= LAST_LABEL) {
    firstDerivative(label);
  }
  else if(label >= REGISTER_X && label <= REGISTER_T) {
    // Interactive mode
    char buf[4];
    switch(label) {
      case REGISTER_X: {
        buf[0] = 'X';
        break;
      }
      case REGISTER_Y: {
        buf[0] = 'Y';
        break;
      }
      case REGISTER_Z: {
        buf[0] = 'Z';
        break;
      }
      case REGISTER_T: {
        buf[0] = 'T';
        break;
      }
      default: { /* unlikely */
        buf[0] = 0;
      }
    }
    buf[1] = 0;
    label = findNamedLabel(buf);
    if(label == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "string '%s' is not a named label", buf);
        moreInfoOnError("In function fn1stDeriv:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      firstDerivative(label);
    }
  }
  else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "unexpected parameter %u", label);
      moreInfoOnError("In function fn1stDeriv:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  if(!solving) {
    clearSystemFlag(FLAG_SOLVING);
  }
}

void fn2ndDeriv(uint16_t label) {
  currentSolverStatus &= !SOLVER_STATUS_USES_FORMULA;
  bool_t solving = getSystemFlag(FLAG_SOLVING);
  setSystemFlag(FLAG_SOLVING);
  if(label >= FIRST_LABEL && label <= LAST_LABEL) {
    secondDerivative(label);
  }
  else if(label >= REGISTER_X && label <= REGISTER_T) {
    // Interactive mode
    char buf[4];
    switch(label) {
      case REGISTER_X: {
        buf[0] = 'X';
        break;}
      case REGISTER_Y: {
        buf[0] = 'Y';
        break;}
      case REGISTER_Z: {
        buf[0] = 'Z';
        break;}
      case REGISTER_T: {
        buf[0] = 'T';
        break;}
      default: { /* unlikely */
        buf[0] = 0;
      }
    }
    buf[1] = 0;
    label = findNamedLabel(buf);
    if(label == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "string '%s' is not a named label", buf);
        moreInfoOnError("In function fn2ndDeriv:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      secondDerivative(label);
    }
  }
  else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "unexpected parameter %u", label);
      moreInfoOnError("In function fn2ndDeriv:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  if(!solving) {
    clearSystemFlag(FLAG_SOLVING);
  }
}

void fn1stDerivEq(uint16_t unusedButMandatoryParameter) {
    //new method to maintain solver variable
    #if !defined(TESTSUITE_BUILD)
      reallyRunFunction(ITM_RCL, currentSolverVariable);
      copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    #endif // TESTSUITE_BUILD
  currentSolverStatus |= SOLVER_STATUS_USES_FORMULA;
  firstDerivative(INVALID_VARIABLE);
    #if !defined(TESTSUITE_BUILD)
      reallyRunFunction(ITM_RCL, TEMP_REGISTER_1);
      reallyRunFunction(ITM_STO, currentSolverVariable);
      fnDrop(0);
    #endif // TESTSUITE_BUILD
  temporaryInformation = TI_1ST_DERIVATIVE;
}


void fn2ndDerivEq(uint16_t unusedButMandatoryParameter) {
printf("fn2stDerivEq: currentSolverStatus=%u \n",currentSolverStatus);

    #if !defined(TESTSUITE_BUILD)
    //new method to maintain solver variable
      reallyRunFunction(ITM_RCL, currentSolverVariable);
      copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    #endif // TESTSUITE_BUILD
  currentSolverStatus |= SOLVER_STATUS_USES_FORMULA;
  secondDerivative(INVALID_VARIABLE);
    #if !defined(TESTSUITE_BUILD)
      reallyRunFunction(ITM_RCL, TEMP_REGISTER_1);
      reallyRunFunction(ITM_STO, currentSolverVariable);
      fnDrop(0);
    #endif // TESTSUITE_BUILD
  temporaryInformation = TI_2ND_DERIVATIVE;
}



/* The following routines are ported from WP34s. */

static void deriv_found_lbl(calcRegister_t deltaX, real_t *h) {
  execProgram(deltaX);
  fnToReal(NOPARAM);
  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), h);
  }
  else {
    lastErrorCode = ERROR_NONE;
    realCopy(const_1on10, h);
  }
}

static void deriv_default_h(real_t *h) {
  calcRegister_t deltaX;

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  realToReal34(h, REGISTER_REAL34_DATA(REGISTER_X));
  fnFillStack(NOPARAM);

  dynamicMenuItem = -1;
  if((deltaX = findNamedLabel(STD_delta "x")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else if((deltaX = findNamedLabel(STD_delta "X")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else if((deltaX = findNamedLabel(STD_DELTA "x")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else if((deltaX = findNamedLabel(STD_DELTA "X")) != INVALID_VARIABLE) {
    deriv_found_lbl(deltaX, h);
  }
  else {
    realCopy(const_1on10, h); /* default h = 0.1 */
  }
}


static void _differentiatorIteration(calcRegister_t label, real_t *r0) {
  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  realToReal34(r0, REGISTER_REAL34_DATA(REGISTER_X));
  fnFillStack(NOPARAM);

  if(currentSolverStatus & SOLVER_STATUS_USES_FORMULA) {
    #if !defined(TESTSUITE_BUILD)
      //printf("parseEquation\n");
      reallyRunFunction(ITM_STO, currentSolverVariable);
      parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    #endif // TESTSUITE_BUILD
  }
  else {
    dynamicMenuItem = -1;
    //printf("Running RPN execProgram\n");
    execProgram(label);
    fnToReal(NOPARAM);
  }

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), r0);
  }
  else {
    lastErrorCode = ERROR_NONE;
    realCopy(const_NaN, r0);
  }
}


/* Eval f(X + k h) k on stack */
static bool_t deriv_eval_func(calcRegister_t label, real_t *r0, const real_t *r3, const real_t *r4, bool_t secondDeriv, realContext_t *realContext) {
  real_t tmpX, tmpY;
  realMultiply(r0, r4, &tmpX, realContext);
  realAdd(&tmpX, r3, &tmpX, realContext);
  _differentiatorIteration(label, &tmpX); /* f(x + k h)*/
  if(realIsSpecial(&tmpX)) {
    return true;
  }
  if(!realIsZero(r0)) {
    realCopy(&tmpX, &tmpY);
    realMinus(r0, &tmpX, realContext);
    realMultiply(&tmpX, r4, &tmpX, realContext);
    realAdd(&tmpX, r3, &tmpX, realContext);
    _differentiatorIteration(label, &tmpX); /* f(x - k h)*/
    if(realIsSpecial(&tmpX)) {
      return true;
    }
    if(secondDeriv) {
      realChangeSign(&tmpX);
    }
    realSubtract(&tmpY, &tmpX, &tmpX, realContext);
  } // deriv_skip_midpoint
  realCopy(&tmpX, r0);
  return false;
}


static void deriv2_4point(real_t *r1, const real_t *r4, realContext_t *realContext) {
  real_t tmpX;
  realMultiply(const_12, r4, &tmpX, realContext);
  realMultiply(&tmpX, r4, &tmpX, realContext);
  realDivide(const_1, &tmpX, &tmpX, realContext);
  realMultiply(r1, &tmpX, r1, realContext);
}


static void _1stDerivative(calcRegister_t label, const real_t *x, real_t *res, realContext_t *realContext) {
  real_t r0, r1, r2, r3, r4;  /* Registers .00 to .04 */
  real_t tmpX, tmpY, tmpZ;

  if(realIsSpecial(x)) {
    realCopy(const_NaN, res);
    return;
  }
  realCopy(x, &r3);
  realCopy(x, &r4);
  deriv_default_h(&r4);
  realCopy(const_1, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, false, realContext)) { /* f(x+h) - f(x-h)*/
    realCopy(const_NaN, res);
    return;
  }
  realCopy(&r0, &r1);

  realCopy(const_2, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, false, realContext)) { /* f(x+2h) - f(x-2h)*/
    realCopy(const_NaN, res);
    return;
  }
  realCopy(&r0, &r2);

  /* At this point we can do a four point estimate if something goes awry */
  realCopy(const_3, &r0);
  if(!deriv_eval_func(label, &r0, &r3, &r4, false, realContext)) { /* f(x+3h)-f(x-3h)*/
    /* At this point we can do the six point estimate - calculate it now */
    realMultiply(const_45, &r1, &tmpY, realContext);
    realMultiply(const_9, &r2, &tmpX, realContext);
    realSubtract(&tmpY, &tmpX, &tmpX, realContext);
    realAdd(&r0, &tmpX, &tmpY, realContext);
    realMultiply(const_60, &r4, &tmpX, realContext);
    realDivide(&tmpY, &tmpX, &tmpZ, realContext);
    realCopy(&r1, &tmpX); realCopy(&tmpZ, &r1); /* Six point stimate in E2 & start ten point estimate*/
    realMultiply(&tmpX, const_2100, &tmpY, realContext);
    realMultiply(const_600, &r2, &tmpX, realContext);
    realSubtract(&tmpY, &tmpX, &tmpY, realContext);
    realMultiply(const_150, &r0, &tmpX, realContext);
    realAdd(&tmpY, &tmpX, &tmpX, realContext); /* Ten point estimate to end up in E1*/

    realCopy(&tmpX, &r2);
    realCopy(const_4, &r0);
    if(deriv_eval_func(label, &r0, &r3, &r4, false, realContext)) { /* f(x+4h) - f(x-4h)*/
      realCopy(&r1, res); // deriv_6point
    }
    else {
      realMultiply(&r0, const_25, &tmpX, realContext);
      realSubtract(&r2, &tmpX, &r2, realContext);

      realCopy(const_5, &r0);
      if(deriv_eval_func(label, &r0, &r3, &r4, false, realContext)) { /* f(x+5h) - f(x-5h)*/
        realCopy(&r1, res); // deriv_6point
      }
      else {
        realAdd(&r0, &r0, &tmpX, realContext);
        realAdd(&tmpX, &r2, &tmpY, realContext);
        realMultiply(const_2520, &r4, &tmpX, realContext);
        realDivide(&tmpY, &tmpX, res, realContext);
      }
    }
  }
  else { //deriv_4point::
    realMultiply(const_8, &r1, &tmpX, realContext);
    realSubtract(&tmpX, &r2, &tmpY, realContext);
    realMultiply(const_12, &r4, &tmpX, realContext);
    realDivide(&tmpY, &tmpX, res, realContext);
  }
}



static void _2ndDerivative(calcRegister_t label, const real_t *x, real_t *res, realContext_t *realContext) {
  real_t r0, r1, r2, r3, r4;  /* Registers .00 to .04 */
  real_t tmpX, tmpY;
  if(realIsSpecial(x)) {
    realCopy(const_NaN, res);
    return;
  }
  realCopy(x, &r3);
  realCopy(x, &r4);
  deriv_default_h(&r4);
  realCopy(const_1, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, true, realContext)) { /* f(x+h) - f(x-h)*/
    realCopy(const_NaN, res);
    return;
  }
  realMultiply(const_16, &r0, &r1, realContext); /* order four estimate*/
  realMultiply(const_42000, &r0, &r2, realContext); /* order ten estimate*/
  realCopy(const_0, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, true, realContext)) { /* f(x)*/
    realCopy(const_NaN, res);
    return;
  }
  realMultiply(const_30, &r0, &tmpX, realContext);
  realSubtract(&r1, &tmpX, &r1, realContext);
  realMultiply(const_73766, &r0, &tmpX, realContext);
  realSubtract(&r2, &tmpX, &r2, realContext);

  realCopy(const_2, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, true, realContext)) { /* f(x+2h) + f(x-2h)*/
    realCopy(const_NaN, res);
    return;
  }
  realSubtract(&r1, &r0, &r1, realContext);
  realMultiply(const_6000, &r0, &tmpX, realContext);
  realSubtract(&r2, &tmpX, &r2, realContext);

  realCopy(const_3, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, true, realContext)) { /* f(x+3h) + f(x-3h)*/
    deriv2_4point(&r1, &r4, realContext);
    realCopy(&r1, res);
    return;
  }
  realMultiply(&r0, const_1000, &tmpX, realContext);
  realAdd(&r2, &tmpX, &r2, realContext);

  realCopy(const_4, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, true, realContext)) { /* f(x+4h) + f(x-4h)*/
    deriv2_4point(&r1, &r4, realContext);
    realCopy(&r1, res);
    return;
  }
  realMultiply(&r0, const_125, &tmpX, realContext);
  realSubtract(&r2, &tmpX, &r2, realContext);

  realCopy(const_5, &r0);
  if(deriv_eval_func(label, &r0, &r3, &r4, true, realContext)) { /* f(x+5h) + f(x-5h)*/
    deriv2_4point(&r1, &r4, realContext);
    realCopy(&r1, res);
    return;
  }
  realMultiply(&r0, const_8, &tmpX, realContext);
  realAdd(&tmpX, &r2, &tmpY, realContext);
  realMultiply(const_25200, &r4, &tmpX, realContext);
  realMultiply(&tmpX, &r4, &tmpX, realContext);
  realDivide(&tmpY, &tmpX, res, realContext);
}



void firstDerivative(calcRegister_t label) {
  real_t x;

  if (!getRegisterAsReal(REGISTER_X, &x))
    return;

  _1stDerivative(label, &x, &x, &ctxtReal39);
  fillStackWithReal0();
  convertRealToResultRegister(&x, REGISTER_X, amNone);
}

void secondDerivative(calcRegister_t label) {
  real_t x;

  if (!getRegisterAsReal(REGISTER_X, &x))
    return;

  _2ndDerivative(label, &x, &x, &ctxtReal39);
  fillStackWithReal0();
  convertRealToResultRegister(&x, REGISTER_X, amNone);
}
