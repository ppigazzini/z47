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
 * \file tvm.c
 ***********************************************/

#include "solver/tvm.h"

#include "constantPointers.h"
#include "defines.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "realType.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "solver/solve.h"
#include "stack.h"
#include "c47.h"

#if !defined(TESTSUITE_BUILD)
  TO_QSPI static const char bugScreenNotForTvm[] = "In function fnTvmVar: this variable is not intended for TVM application!";
#endif //TESTSUITE_BUILD

void fnTvmVar(uint16_t variable) {
  #if !defined(TESTSUITE_BUILD)
    switch(variable) {
      case RESERVED_VARIABLE_FV:
      case RESERVED_VARIABLE_IPONA:
      case RESERVED_VARIABLE_NPPER:
      case RESERVED_VARIABLE_PPERONA:
      case RESERVED_VARIABLE_CPERONA:
      case RESERVED_VARIABLE_PMT:
      case RESERVED_VARIABLE_PV: {
        currentSolverStatus |= SOLVER_STATUS_TVM_APPLICATION;
        currentSolverVariable = variable;
        clearSystemFlag(FLAG_TVM_I_KNOWN);
	
        /* Calculate */
        if(currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE) {
          real34_t y, x, resZ, resY, resX;
          saveForUndo();
          thereIsSomethingToUndo = true;
          liftStack();

      	  clearSystemFlag(FLAG_TVM_I_KNOWN);

      	  switch(variable) {
            case RESERVED_VARIABLE_IPONA:
            case RESERVED_VARIABLE_PPERONA:
            case RESERVED_VARIABLE_CPERONA: {
              setSystemFlag(FLAG_TVM_I_CHANGES);
              break;
            }
            default: {
              clearSystemFlag(FLAG_TVM_I_CHANGES);	  
            }
      	  }
      	  real34Multiply(REGISTER_REAL34_DATA(variable), const34_2, &y);
          real34Multiply(REGISTER_REAL34_DATA(variable), const34_1on2, &x);

          switch(variable) {
            case RESERVED_VARIABLE_PV: {
              if(real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV))) {
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV), const34_2, &y);
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV), const34_1on2, &x);
              }
              break;
            }
            case RESERVED_VARIABLE_FV: {
              if(real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV))) {
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV), const34_2, &y);
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV), const34_1on2, &x);
              }
              break;
            }
            case RESERVED_VARIABLE_IPONA: {
              if(real34CompareLessThan(REGISTER_REAL34_DATA(variable), const34_1)) {
                real34Copy(const34_100, &y);
                real34Copy(const34_1, &x);
              }
              break;
            }

            case RESERVED_VARIABLE_NPPER:
            case RESERVED_VARIABLE_CPERONA:
            case RESERVED_VARIABLE_PPERONA: {
              if(real34CompareLessThan(REGISTER_REAL34_DATA(variable), const34_1)) {
                real34Copy(const34_2, &y);
                real34Copy(const34_1, &x);
              }
              break;
            }
          }
          if((variable == RESERVED_VARIABLE_PV || variable == RESERVED_VARIABLE_FV) &&
            !real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)) &&
            !real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV)) &&
            real34IsNegative(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)) == real34IsNegative(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV))) {
              real34ChangeSign(&y);
              real34ChangeSign(&x);
          }
          if(solver(variable, &y, &x, &resZ, &resY, &resX) == SOLVER_RESULT_NORMAL) {
            reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
            real34Copy(&resX, REGISTER_REAL34_DATA(REGISTER_X));
            temporaryInformation = TI_SOLVER_VARIABLE;
            thereIsSomethingToUndo = false;
          }
          else {
            displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            #if(EXTRA_INFO_ON_CALC_ERROR == 1)
              moreInfoOnError("In function fnTvmVar:", "cannot compute TVM equation", "with current parameters", NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }
          adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
        }

        /* Store parameters */
        else {
          fnToReal(NOPARAM);
          if(lastErrorCode == ERROR_NONE) {
            reallyRunFunction(ITM_STO, variable);
      	    if (variable == RESERVED_VARIABLE_PPERONA) {
      	      reallyRunFunction(ITM_STO, RESERVED_VARIABLE_CPERONA);
      	    }
            currentSolverStatus |= SOLVER_STATUS_READY_TO_EXECUTE;
            temporaryInformation = TI_SOLVER_VARIABLE;
          }
          adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
        }
        break;
      }

      default: {
        displayBugScreen(bugScreenNotForTvm);
      }
    }
  #endif // !TESTSUITE_BUILD
}



void fnTvmBeginMode(uint16_t unusedButMandatoryParameter) {
  clearSystemFlag(FLAG_ENDPMT);
}

void fnTvmEndMode(uint16_t unusedButMandatoryParameter) {
  setSystemFlag(FLAG_ENDPMT);
}




void tvmEquation(void) {
  real_t fv, iA, nPer, pperA, cperA, pmt, pv;
  real_t i1nPer, val, tmp, r;
  static real_t i;

  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV),     &fv);
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_IPONA),  &iA);
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_NPPER),   &nPer);
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PPERONA), &pperA);
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_CPERONA), &cperA);
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PMT),    &pmt);
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV),     &pv);
  /*
    The plan is to find an interest rate iM which, 
    when compounded pperA times in a year, gives iAER.
    (AER stands for annual effective rate.)
    iAER can be found like this:
    1 + iAER = (1 + (iA/100)/cperA)^cperA
    Also,
    1 + iAER = (1 + iM) ^ pperA.
    So
    iM = (1 + (iA/100)/cperA)^(cperA/pperA) - 1.
    If cperA = pperA this is just iM = (iA/100)/pperA.

    Define r = cperA / pperA. r = 1 corresponds to the "normal" case.
    In terms of r,
    iM = (1 + iA/100/pperA/r)^r - 1.
    This reduces to iM = (iA/100)/pperA when r=1.
    When pperA is set cperA is also set to the same value. So if no value
    is entered for cperA, r will be 1. We can test for this and short-circuit
    the calculation.
    If no value is entered for pperA - perhaps it's being solved for so it's zero
    Can I avoid repeating this calculation each time the TVM equation is called?
    The calculation of i depends on: iA; pperA; cperA. iA could change if i is being solved for;
    similarly, the other two could change as well if being solved for.
    This function doesn't know what is being solved for.
    It takes a lot of iterations to converge but without the calculation of i each time
    these iterations pass much more quickly. So I do need to do something here.
   */

  if ( (!getSystemFlag(FLAG_TVM_I_KNOWN)) || (getSystemFlag(FLAG_TVM_I_CHANGES)) ) { // if i hasn't been found yet or i changes each time
    realDivide(&iA, const_100, &i, &ctxtReal39);
    realDivide(&i, &pperA, &i, &ctxtReal39);
    // i is now (iA / 100) / pperA.
    // This is the "normal" value of i when cperA = pperA.

    realDivide(&cperA, &pperA, &r, &ctxtReal39); // r = cperA / pperA
			   
    if ( !(realIsZero (&r) || realCompareEqual(const_1, &r)) ) { // not normal case
      realDivide(&i, &r, &i, &ctxtReal39);
      realAdd (&i, const_1, &i, &ctxtReal39);
      realPower (&i, &r, &i, &ctxtReal39);
      realSubtract (&i, const_1, &i, &ctxtReal39); // i = (1 + (i/pperA)/r)^r - 1
    }
    setSystemFlag(FLAG_TVM_I_KNOWN);
  }
  
  realChangeSign(&pv);

  realAdd(&i, const_1, &i1nPer, &ctxtReal39);
  realPower(&i1nPer, &nPer, &i1nPer, &ctxtReal39);

  if(getSystemFlag(FLAG_ENDPMT)) {
    realCopy(const_1, &val); // END mode
  }
  else {
    realAdd(const_1, &i, &val, &ctxtReal39); // BEGIN mode
  }

  realMultiply(&val, &pmt, &val, &ctxtReal39);
  realDivide(&val, &i, &val, &ctxtReal39);

  realSubtract(const_1, &i1nPer, &tmp, &ctxtReal39);
  realMultiply(&val, &tmp, &val, &ctxtReal39);

  realFMA(&pv, &i1nPer, &val, &val, &ctxtReal39);
  realSubtract(&val, &fv, &val, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&val, REGISTER_X);
}
