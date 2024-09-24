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

#include "c43Extensions/addons.h"
#include "constantPointers.h"
#include "defines.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/power.h"
#include "realType.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
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
        tvmIKnown = false;

        /* Calculate */
        if(currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE || programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED) {
          real34_t y, x, resZ, resY, resX;
          saveForUndo();
          thereIsSomethingToUndo = true;
          liftStack();

          tvmIKnown = false;

          switch(variable) {
            case RESERVED_VARIABLE_IPONA:
            case RESERVED_VARIABLE_PPERONA:
            case RESERVED_VARIABLE_CPERONA: {
              tvmIChanges = true;
              break;
            }
            default: {
              tvmIChanges = false;
            }
          }

          real34Multiply(REGISTER_REAL34_DATA(variable), const34_2, &y);
          real34Multiply(REGISTER_REAL34_DATA(variable), const34_1on2, &x);

          switch(variable) {
            case RESERVED_VARIABLE_PV: {
              if(real34CompareAbsLessThan(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV),const34_1e_4)) {
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV), const34_2, &y);
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV), const34_1on2, &x);
              }
              break;
            }
            case RESERVED_VARIABLE_FV: {
              if(real34CompareAbsLessThan(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV),const34_1e_4)) {
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV), const34_2, &y);
                real34Multiply(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV), const34_1on2, &x);
              }
              break;
            }
            case RESERVED_VARIABLE_IPONA: {
              if(real34CompareAbsLessThan(REGISTER_REAL34_DATA(variable), const34_1on10)) {       //if interest rate p.a. < 0.1% then default to a reasonable 3% to 7% strarting condition
                real34Copy(const34_3, &y); //3
                real34Copy(const34_7, &x); //7
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

            case RESERVED_VARIABLE_PMT: {
              //no special x y cases
              break;
            }
            default:break;
          }

          if((variable == RESERVED_VARIABLE_PV || variable == RESERVED_VARIABLE_FV) &&
            !real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)) &&
            !real34IsZero(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV)) &&
            real34IsNegative(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV)) == real34IsNegative(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV))) {
              real34ChangeSign(&y);
              real34ChangeSign(&x);
          }

          if(real34CompareAbsLessThan(&x,const34_1e_4) && real34CompareAbsLessThan(&y,const34_1e_4)) { //still after all the tries, if x & y are still both below 0.0001, then change x to 1 (keeping y = 0)
            real34Copy(const34_1, &x);
          }

          uint16_t iter = 0;
          real34_t xx, yy;

          #define nIter 6
          while(iter++ < nIter || !real34CompareEqual(&resX, &resY)) {
            real34Copy(&x, &xx);
            real34Copy(&y, &yy);
            #if defined(PC_BUILD)
              printReal34ToConsole(&x,"iter x:","\n");
              printReal34ToConsole(&y,"iter y:","\n");            
            #endif //PC_BUILD
            uint16_t solveResult = solver(variable, &y, &x, &resZ, &resY, &resX);
            #if defined(PC_BUILD)
              printf("Solve iteration: iter=%u solveResult=%u\n",iter,solveResult);
            #endif //PC_BUILD
            if(solveResult == SOLVER_RESULT_NORMAL) {
              #if defined(PC_BUILD)
                printReal34ToConsole(&resZ,"solver results: resZ:","\n");
                printReal34ToConsole(&resY,"solver results: resY:","\n");
                printReal34ToConsole(&resX,"solver results: resX:","\n");
              #endif //PC_BUILD
              reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
              real34Copy(&resX, REGISTER_REAL34_DATA(REGISTER_X));
              temporaryInformation = TI_SOLVER_VARIABLE;
              thereIsSomethingToUndo = false;
              break;
            }
            else if(solveResult == SOLVER_RESULT_CONSTANT) { // in cases with prevented infinite loop
              iter = nIter;
              break;
            }
            else if(solveResult == SOLVER_RESULT_ABORTED) { // solver aborted
              iter = nIter;
              if(exitKeyWaiting()) {
                showString("key Waiting ...", &standardFont, 20, 40, vmNormal, false, false);
                #if defined(DMCP_BUILD)
                  while(popKey() == 32) {}
                #endif // DMCP_BUILD
                break;
              }
            }
            else {
              if(real34IsNegative(&xx)) {
                real34Subtract(&xx, const34_2, &x);
              } else {
                real34Add(&xx, const34_1, &x);
              }
              if(real34IsNegative(&yy)) {
                real34Subtract(&yy, const34_1on2, &y);
              }
              else {
                real34Add(&yy, const34_2, &y);
              }
              real34Multiply(&x, const34_3, &x);
              if((iter+1)%3 == 0) {
                real34ChangeSign(&x);
              }
              real34Multiply(&y, const34_2, &y);
            }
          }
          
          if(iter == nIter) {
            if(lastErrorCode != ERROR_SOLVER_ABORT) {
              displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
            }
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
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
            if(variable == RESERVED_VARIABLE_PPERONA) {
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


void fnEff(uint16_t unusedButMandatoryParameter) {
  real_t iA, cperA, tmp;
  //no need to use tvmIKnown or tvmIChanges, as this is a simplistic output only, which takes the current cperA & iA and produces the effective rate. There is no situation where there is no values in these
    //   EFF = 100({[iA / 100cperA] + 1} ^ cperA - 1) 

  if(getRegisterAsRealQuiet(RESERVED_VARIABLE_IPONA, &iA) &&
     getRegisterAsRealQuiet(RESERVED_VARIABLE_CPERONA, &cperA) &&
     !realIsZero(&cperA)) {

    saveForUndo();
    thereIsSomethingToUndo = true;
    liftStack();

    realDivide(&iA, const_100, &tmp, &ctxtReal39);
    realDivide(&tmp, &cperA, &tmp, &ctxtReal39);
    realAdd(&tmp, const_1, &tmp, &ctxtReal39);
    realPower(&tmp, &cperA, &tmp, &ctxtReal39);
    realSubtract(&tmp, const_1, &tmp, &ctxtReal39);
    realMultiply(&tmp, const_100, &tmp, &ctxtReal39);
    
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&tmp, REGISTER_X);
    temporaryInformation = TI_TVM_EFF;
  } else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnEff:", "cannot compute EFF%/a ", "with parameter cp/a = 0", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}


void fnEffToI(uint16_t unusedButMandatoryParameter) {
  real_t iEFF, tmp, cperA, cperAInv;
  //no need to use tvmIKnown or tvmIChanges, as this is a simplistic output only, which takes the current cperA & iA and produces the effective rate. There is no situation where there is no values in these
    // iA = {[(EFF / 100 + 1) ^ (1/cperA) ] - 1 } 100 * cperA

  if(getRegisterAsRealQuiet(REGISTER_X, &iEFF) && 
     getRegisterAsRealQuiet(RESERVED_VARIABLE_CPERONA, &cperA) && 
     !realIsZero(&cperA) &&
     realIsPositive(&iEFF)) {

    saveForUndo();
    thereIsSomethingToUndo = true;

    realDivide(&iEFF, const_100, &tmp, &ctxtReal39);
    realAdd(&tmp, const_1, &tmp, &ctxtReal39);

    realDivide(const_1, &cperA, &cperAInv, &ctxtReal39);
    PowerReal(&tmp, &cperAInv, &tmp, &ctxtReal39);
    realSubtract(&tmp, const_1, &tmp, &ctxtReal39);
    realMultiply(&tmp, const_100, &tmp, &ctxtReal39);
    realMultiply(&tmp, &cperA, &tmp, &ctxtReal39);

    realToReal34(&tmp, REGISTER_REAL34_DATA(RESERVED_VARIABLE_IPONA));
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    convertRealToReal34ResultRegister(&tmp, REGISTER_X);

    temporaryInformation = TI_TVM_IA;
  } else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function fnEffToI:", "cannot compute I%/a ", "with parameters n = 0 & EFF/a < 0 ", NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}





void tvmEquation(void) {
  real_t fv, iA, nPer, pperA, cperA, pmt, pv;
  real_t i1nPer, val, tmp, r;
  static real_t i;

  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_FV),      &fv);     //future value
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_IPONA),   &iA);     //interest percentage per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_NPPER),   &nPer);   //number of periods
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PPERONA), &pperA);  //payment periods per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_CPERONA), &cperA);  //compounding periods per annum
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PMT),     &pmt);    //payment
  real34ToReal(REGISTER_REAL34_DATA(RESERVED_VARIABLE_PV),      &pv);     //present value
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

  if((!tvmIKnown) || (tvmIChanges)) { // if i hasn't been found yet or i changes each time
    realDivide(&iA, const_100, &i, &ctxtReal39);
    realDivide(&i, &pperA, &i, &ctxtReal39);
    // i is now (iA / 100) / pperA.
    // This is the "normal" value of i when cperA = pperA.

    realDivide(&cperA, &pperA, &r, &ctxtReal39); // r = cperA / pperA

    if(!(realIsZero(&r) || realCompareEqual(const_1, &r)) ) { // not normal case
      realDivide(&i, &r, &i, &ctxtReal39);
      realAdd(&i, const_1, &i, &ctxtReal39);
      realPower(&i, &r, &i, &ctxtReal39);
      realSubtract(&i, const_1, &i, &ctxtReal39); // i = (1 + (i/pperA)/r)^r - 1
    }
    tvmIKnown = true;
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
  if(realCompareAbsLessThan(&i,const_1e_37)) {    //prevent infinity when i = 0, to continue work
    realCopy(const_1e_37,&i);
  }
  realDivide(&val, &i, &val, &ctxtReal39);

  realSubtract(const_1, &i1nPer, &tmp, &ctxtReal39);
  realMultiply(&val, &tmp, &val, &ctxtReal39);

  realFMA(&pv, &i1nPer, &val, &val, &ctxtReal39);
  realSubtract(&val, &fv, &val, &ctxtReal39);

  reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
  convertRealToReal34ResultRegister(&val, REGISTER_X);
}
