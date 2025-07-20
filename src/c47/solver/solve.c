// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//**
 * \file solve.c
 ***********************************************/

#include "c47.h"

void fnPgmSlv(uint16_t label) {
  if(FIRST_LABEL <= label && label <= LAST_LABEL) {
    currentSolverProgram = label - FIRST_LABEL;
  }
  else if(REGISTER_X <= label && label <= REGISTER_T) {
    // Interactive mode
    char buf[2];
    buf[0] = letteredRegisterName((calcRegister_t)label);
    buf[1] = 0;
    label = findNamedLabel(buf);
    if(label == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "string '%s' is not a named label", buf);
        moreInfoOnError("In function fnPgmSlv:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      currentSolverProgram = label - FIRST_LABEL;
    }
  }
  else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "unexpected parameter %u", label);
      moreInfoOnError("In function fnPgmSlv:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}

void fnSolve(uint16_t labelOrVariable) {
  if((FIRST_LABEL <= labelOrVariable && labelOrVariable <= LAST_LABEL) || (REGISTER_X <= labelOrVariable && labelOrVariable <= REGISTER_T)) {
    // Interactive mode
    fnPgmSlv(labelOrVariable);
    if(lastErrorCode == ERROR_NONE) {
      currentSolverStatus = SOLVER_STATUS_INTERACTIVE;
    }
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
  else if(!(currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (FIRST_NAMED_VARIABLE <= labelOrVariable && labelOrVariable <= LAST_NAMED_VARIABLE) && currentSolverProgram >= numberOfLabels) {
    displayCalcErrorMessage(ERROR_NO_PROGRAM_SPECIFIED, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "label %u not found", labelOrVariable);
      moreInfoOnError("In function fnSolve:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
  else if(FIRST_NAMED_VARIABLE <= labelOrVariable && labelOrVariable <= LAST_NAMED_VARIABLE) {
    // Execute
    real34_t z, y, x;
    real_t tmp;
    int resultCode = 0;

    if(getRegisterAsReal34Quiet(REGISTER_Y, &y) && getRegisterAsReal34Quiet(REGISTER_X, &x)) {
      fnDrop(NOPARAM);
      fnDrop(NOPARAM);
      saveForUndo(); //repeat after dropping the input parameters
      currentSolverVariable = labelOrVariable;
      screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
      refreshScreen(0);
      resultCode = solver(labelOrVariable, &y, &x, &z, &y, &x);

      fnUndo(0);
      liftStack();
      liftStack();
      liftStack();
      liftStack();
      real34ToReal(&z, &tmp), convertRealToReal34ResultRegister(&tmp, REGISTER_Z);
      real34ToReal(&y, &tmp), convertRealToReal34ResultRegister(&tmp, REGISTER_Y);
      real34ToReal(&x, &tmp), convertRealToReal34ResultRegister(&tmp, REGISTER_X);
      int32ToReal34(resultCode, REGISTER_REAL34_DATA(REGISTER_T));
      switch(resultCode) {
        case SOLVER_RESULT_NORMAL: {
          copySourceRegisterToDestRegister(REGISTER_X, labelOrVariable);
          temporaryInformation = TI_SOLVER_VARIABLE_RESULT;
          lastErrorCode = ERROR_NONE;
          break;
        }
        case SOLVER_RESULT_SIGN_REVERSAL: {
          temporaryInformation = TI_SOLVER_FAILED;
          displayCalcErrorMessage(ERROR_LARGE_DELTA_AND_OPPOSITE_SIGN, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          break;
        }
        case SOLVER_RESULT_EXTREMUM: {
          temporaryInformation = TI_SOLVER_FAILED;
          displayCalcErrorMessage(ERROR_SOLVER_REACHED_LOCAL_EXTREMUM, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          break;
        }
        case SOLVER_RESULT_BAD_GUESS: {
          temporaryInformation = TI_SOLVER_FAILED;
          displayCalcErrorMessage(ERROR_INITIAL_GUESS_OUT_OF_DOMAIN, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          break;
        }
        case SOLVER_RESULT_CONSTANT: {
          temporaryInformation = TI_SOLVER_FAILED;
          displayCalcErrorMessage(ERROR_FUNCTION_VALUES_LOOK_CONSTANT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          break;
        }
        case SOLVER_RESULT_OTHER_FAILURE: {
          temporaryInformation = TI_SOLVER_FAILED;
          displayCalcErrorMessage(ERROR_NO_ROOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          break;
        }
        case SOLVER_RESULT_ABORTED: {
          temporaryInformation = TI_SOLVER_FAILED;
          displayCalcErrorMessage(ERROR_SOLVER_ABORT, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          break;
        }
      }
      adjustResult(REGISTER_X, false, false, REGISTER_X, REGISTER_Y, -1);


    }
    else {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      #if defined(PC_BUILD)
        sprintf(errorMessage, "DataType %" PRIu32, getRegisterDataType(REGISTER_X));
        moreInfoOnError("In function fnSolve:", errorMessage, "is not a real number.", "");
      #endif // PC_BUILD
      adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    }
  }
  else {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "unexpected parameter %u", labelOrVariable);
      moreInfoOnError("In function fnSolve:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }
}

void fnSolveVar(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    printStatus(1, errorMessages[REAL_SOLVER],force);
    const char *var = (char *)getNthString(dynamicSoftmenu[softmenuStack[0].softmenuId].menuContent, dynamicMenuItem);
    const uint16_t regist = findOrAllocateNamedVariable(var);
    const uint16_t nameLength = stringByteLength(var) + 1;
    if(currentMvarLabel != INVALID_VARIABLE) {
      if(currentSolverStatus & SOLVER_STATUS_INTERACTIVE) { // MNU_MVAR was displayed by the Solver
        reallyRunFunction(ITM_STO, regist);
      }
      else {  // MNU_MVAR was displayed by VARMNU
        if(entryStatus & 0x01) { // MVAR menu key pressed after a user entry: save the value in the variable
          entryStatus &= 0xfe;
          currentSolverVariable = regist;
          reallyRunFunction(ITM_STO, regist);
          temporaryInformation = TI_SOLVER_VARIABLE;
        }
        else { // MVAR menu key pressed without a a user entry: store the variable name in K and continue program execution
          reallocateRegister(REGISTER_K, dtString, TO_BLOCKS(nameLength) , amNone);
          xcopy(REGISTER_STRING_DATA(REGISTER_K), var, nameLength);
          dynamicMenuItem = -1;
          runProgram(false, INVALID_VARIABLE);
        }
      }
    }
    else if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE || (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) {
      currentSolverVariable = regist;
      reallyRunFunction(ITM_STO, regist);
      temporaryInformation = TI_SOLVER_VARIABLE;
    }
    else if(currentSolverStatus & SOLVER_STATUS_READY_TO_EXECUTE) {
      reallyRunFunction(ITM_SOLVE, regist);
    }
    else {
      currentSolverVariable = regist;
      reallyRunFunction(ITM_STO, regist);
      currentSolverStatus |= SOLVER_STATUS_READY_TO_EXECUTE;
      temporaryInformation = TI_SOLVER_VARIABLE;
    }
  #endif // !TESTSUITE_BUILD
}

#if !defined(TESTSUITE_BUILD)
  static void _solverIteration(real34_t *res) {
    if(lastErrorCode == ERROR_SOLVER_ABORT) {
      realToReal34(const_NaN, res);
      return;
    }
    if(currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) {
      tvmEquation();
    }
    else if(currentSolverStatus & SOLVER_STATUS_USES_FORMULA) {
      parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    }
    else {
      uint16_t savedCurrentSolverProgram = currentSolverProgram;
      dynamicMenuItem = -1;
      execProgram(currentSolverProgram + FIRST_LABEL);
      currentSolverProgram = savedCurrentSolverProgram;
    }
    if(lastErrorCode == ERROR_OVERFLOW_PLUS_INF) {
      realToReal34(const_plusInfinity, res);
      lastErrorCode = ERROR_NONE;
    }
    else if(lastErrorCode == ERROR_OVERFLOW_MINUS_INF) {
      realToReal34(const_minusInfinity, res);
      lastErrorCode = ERROR_NONE;
    }
    else if(lastErrorCode != ERROR_NONE) {
      realToReal34(const_NaN, res);
    }
    else if(getRegisterAsReal34Quiet(REGISTER_X, res)) {
    else if(getRegisterAsReal34Quiet(REGISTER_X, res)) {
      ;
    } 
    else if(getRegisterDataType(REGISTER_X) == dtComplex34 && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X))) {
      real34Copy(REGISTER_IMAG34_DATA(REGISTER_X), res);
      real34ChangeSign(res);
    }
    else {
      realToReal34(const_NaN, res);
    }
  }

static void _executeSolver(calcRegister_t variable, const real34_t *val, real34_t *res) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  real34Copy(val, REGISTER_REAL34_DATA(REGISTER_X));
  if(currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) {
    copySourceRegisterToDestRegister(REGISTER_X, variable);
  }
  else {
    reallyRunFunction(ITM_STO, variable);
    fnFillStack(NOPARAM);
  }
  _solverIteration(res);
}

  static void _linearInterpolation(const real_t *a, const real_t *b, const real_t *fa, const real_t *fb, real_t *res, real_t *slope, realContext_t *realContext) {
    real_t amb, famfb;
    realSubtract(a, b, &amb, realContext);
    realSubtract(fa, fb, &famfb, realContext);
    if(slope) {
      realDivide(&famfb, &amb, slope, realContext);
    }
    if(res) {
      realDivide(&amb, &famfb, &amb, realContext);
      realMultiply(&amb, fb, &amb, realContext);
      realSubtract(b, &amb, res, realContext);
    }
  }

  static void _inverseQuadraticInterpolation(const real_t *a, const real_t *b, const real_t *c, const real_t *fa, const real_t *fb, const real_t *fc, real_t *res, realContext_t *realContext) {
    real_t val, num, den, tmp;

    realMultiply(fb, fc, &num, realContext);
    realMultiply(&num, a, &num, realContext);
    realSubtract(fa, fb, &den, realContext);
    realSubtract(fa, fc, &tmp, realContext);
    realMultiply(&den, &tmp, &den, realContext);
    realDivide(&num, &den, &val, realContext);

    realMultiply(fa, fc, &num, realContext);
    realMultiply(&num, b, &num, realContext);
    realSubtract(fb, fa, &den, realContext);
    realSubtract(fb, fc, &tmp, realContext);
    realMultiply(&den, &tmp, &den, realContext);
    realDivide(const_1, &den, &den, realContext);
    realFMA(&num, &den, &val, &val, realContext);

    realMultiply(fa, fb, &num, realContext);
    realMultiply(&num, c, &num, realContext);
    realSubtract(fc, fa, &den, realContext);
    realSubtract(fc, fb, &tmp, realContext);
    realMultiply(&den, &tmp, &den, realContext);
    realDivide(const_1, &den, &den, realContext);
    realFMA(&num, &den, &val, res, realContext);
  }



  static void _showProgress(const real34_t *a, const real34_t *b, const real34_t *fa, const real34_t *fb) {
    #if ENABLE_SOLVER_PROGRESS == 1
        const real34_t *c;
        if((currentSolverStatus & (SOLVER_STATUS_TVM_APPLICATION & SOLVER_STATUS_USES_FORMULA)) == 0 && currentSolverNestingDepth == 1 ) { //} programRunStop != PGM_RUNNING) { //proposed omission to make progress monitoring while in program running, it can be switched off with MONIT. Not final.
          uint8_t savedDisplayFormatDigits = displayFormatDigits;

          if(real34CompareGreaterThan(a, b)) {
            c = a;  a  = b;  b  = c;
            c = fa; fa = fb; fb = c;
          }

          clearRegisterLine(REGISTER_Z, true, true);
          clearRegisterLine(REGISTER_Y, true, true);
          clearRegisterLine(REGISTER_X, true, true);

          displayFormatDigits = displayFormat == DF_ALL ? 0 : 33;
          real34ToDisplayString(a, amNone, tmpString, &standardFont, 9999, 34, !LIMITEXP, FRONTSPACE, NOIRFRAC);
          showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, true, true);
          showString(real34IsSpecial(fa) ? "?" : real34IsZero(fa) ? "" : real34IsPositive(fa) ? "+" : "-", &standardFont, SCREEN_WIDTH - 10 /* width of '+' */, Y_POSITION_OF_REGISTER_Y_LINE + 6, vmNormal, true, true);
          real34ToDisplayString(b, amNone, tmpString, &standardFont, 9999, 34, !LIMITEXP, FRONTSPACE, NOIRFRAC);
          showString(tmpString, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
          showString(real34IsSpecial(fb) ? "?" : real34IsZero(fb) ? "" : real34IsPositive(fb) ? "+" : "-", &standardFont, SCREEN_WIDTH - 10 /* width of '+' */, Y_POSITION_OF_REGISTER_X_LINE + 6, vmNormal, true, true);
          displayFormatDigits = savedDisplayFormatDigits;

        #if defined DMCP_BUILD
          lcd_refresh();
        #endif //DMCP_BUILD
      }
    #endif // ENABLE_SOLVER_PROGRESS == 1
  }
#endif //TESTSUITE_BUILD



int solver(calcRegister_t variable, const real34_t *y, const real34_t *x, real34_t *resZ, real34_t *resY, real34_t *resX) {
  currentKeyCode = 255;
  #if !defined(TESTSUITE_BUILD)
    real34_t a, b, b1, b2, fa, fb, fb1, m, s, *bp1, fbp1, tmp, antiLevel34, tol34AlmostZero;
    real_t aa, bb, bb1, bb2, faa, fbb, fbb1, mm, ss, secantSlopeA, secantSlopeB, delta, deltaB, smb, tol;
    bool_t extendRange = false;
    bool_t originallyLevel = false;
    bool_t extremum = false;
    int result = SOLVER_RESULT_NORMAL;
    bool_t was_inting = getSystemFlag(FLAG_INTING);
    int loop = 0;
    int16_t getOutOfLevel = 17;
    bool_t fbIsAlmostZero = false;

    convergenceTolerence(&tol);
    stringToReal34("1e-34", &tol34AlmostZero);
    //printReal34ToConsole(&tol34AlmostZero,"tol=","\n");

    ++currentSolverNestingDepth;
    setSystemFlag(FLAG_SOLVING);
    clearSystemFlag(FLAG_INTING);

    realCopy(const_0, &delta);

    real34Copy(y, &a);
    real34Copy(y, &b1);
    real34Copy(x, &b);
    realToReal34(const_NaN, &b2);


    //determine the tolerance (ULP) with which levelness will be detected
    real34NextPlus(x, &antiLevel34);
    if(real34IsInfinite(&antiLevel34)) {
      real34NextMinus(x, &antiLevel34);
      real34Subtract(x, &antiLevel34, &antiLevel34);
    }
    else {
      real34Subtract(x, &antiLevel34, &antiLevel34);
    }


    if(real34CompareEqual(x, y)) {                              //try solve the originallyLevel problem by forcing the inputs marginally not equal, causing the originallyLevel flag not to be set.
retryLevel:
      if(--getOutOfLevel >= 0) {
        #ifdef PC_BUILD
          printf("Retry Level:%i ",getOutOfLevel);
          printReal34ToConsole(&antiLevel34," antiLevel34:","\n");
        #endif //PC_BUILD
        real34Multiply(&antiLevel34,const34_153,&antiLevel34);   //increase it for the next round so long
        real34Minus(&antiLevel34,&antiLevel34);                  //let the increment be 2 orders of magnitude larger, and flip sign so we can cover negatives equally well.
        if(real34IsPositive(&antiLevel34)) {
          real34Add(&b, &antiLevel34, &b);                       //Add this value to the right hand starting value
        } else {
          real34Add(&a, &antiLevel34, &a);                       //Add this value to the left hand starting value
          real34Add(&b1, &antiLevel34, &b1);                     //Add this value to the left hand starting value
        }
      }
    }

    real34Subtract(&b, &a, &s);
    if(real34CompareAbsLessThan(&s, const34_1e_32)) {
      real34Copy(const34_1e_32, &s);
      if(real34CompareLessThan(&b, &a)) {
        real34SetNegativeSign(&s);
      }
      real34Subtract(&a, &s, &a);
      real34Add(&b, &s, &b);
    }

    _executeSolver(variable, &b1, &fb1);
    if(lastErrorCode != ERROR_NONE) {
      result = SOLVER_RESULT_BAD_GUESS;
    }
    real34Copy(&fb1, &fa);

    // calculation
    _executeSolver(variable, &b, &fb);
    //printReal34ToConsole(&b1,"JJ2: f(&b1=",")  "); printReal34ToConsole(&fb1,"","\n");
    //printReal34ToConsole(&b, "JJ2: f(&b=", ")  "); printReal34ToConsole(&fb,"","\n");

    if(lastErrorCode != ERROR_NONE) {
      result = SOLVER_RESULT_BAD_GUESS;
    }

    if(real34IsSpecial(&fb) || real34IsSpecial(&fb1)) {
      result = SOLVER_RESULT_BAD_GUESS;
    }
    else if(real34IsNegative(&fb) == real34IsNegative(&fb1)) {
      extendRange = true;
    }

    if(real34CompareEqual(&fb, &fb1)) {
      if(getOutOfLevel >= 0) {             //try solve the originallyLevel problem by forcing the inputs marginally not equal, causing the originallyLevel flag not to be set.
        goto retryLevel;
      }
      else {
        originallyLevel = true;
      }
    }

    if(real34CompareAbsLessThan(&fa, &fb)) {
      real34Copy(&b, &tmp); real34Copy(&a, &b); real34Copy(&tmp, &a); real34Copy(&tmp, &b1);
      real34Copy(&fb, &tmp); real34Copy(&fa, &fb); real34Copy(&tmp, &fa); real34Copy(&tmp, &fb1);
    }

    if(real34IsZero(&fa) || real34IsZero(&fb)) { // already is a root?
      if((--currentSolverNestingDepth) == 0) {
        clearSystemFlag(FLAG_SOLVING);
      }
      else if(was_inting) {
        clearSystemFlag(FLAG_SOLVING);
        setSystemFlag(FLAG_INTING);
      }
      real34Zero(resZ);
      real34Zero(resY);
      real34Copy(real34IsZero(&fa) ? &a : &b, resX);
      return SOLVER_RESULT_NORMAL;
    }

    do {
      // convert real34 to real
      real34ToReal(&a, &aa);
      real34ToReal(&b, &bb);
      real34ToReal(&b1, &bb1);
      real34ToReal(&b2, &bb2);
      real34ToReal(&fa, &faa);
      real34ToReal(&fb, &fbb);
      real34ToReal(&fb1, &fbb1);



      loop++;
      if(checkHalfSec()) {
        if(progressHalfSecUpdate_Integer(timed, "Iter: ",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp)) { //timed
          _showProgress(&a, &b, &fa, &fb);
        }
      }

      if(exitKeyWaiting()) {
          progressHalfSecUpdate_Integer(force+1, "Interrupted Iter:",loop, halfSec_clearZ, halfSec_clearT, halfSec_disp);
          programRunStop = PGM_WAITING;
          displayCalcErrorMessage(ERROR_SOLVER_ABORT, REGISTER_T, NIM_REGISTER_LINE);
        break;
      }

      // pre-calculation
      if(realIsSpecial(&bb2)) {
        realSubtract(&bb, &bb1, &deltaB, &ctxtReal39);
      }
      else {
        realSubtract(&bb1, &bb2, &deltaB, &ctxtReal39);
      }
      realSetPositiveSign(&deltaB);

      _linearInterpolation(&aa, &bb, &faa, &fbb, NULL, &secantSlopeA, &ctxtReal39);

      // interpolation
      if(!(realCompareEqual(&faa, &fbb) || realCompareEqual(&faa, &fbb1) || realCompareEqual(&fbb, &fbb1))) { // inverse quadratic interpolation
        _linearInterpolation(&bb, &bb1, &fbb, &fbb1, NULL, &secantSlopeB, &ctxtReal39);
        _inverseQuadraticInterpolation(&aa, &bb, &bb1, &faa, &fbb, &fbb1, &ss, &ctxtReal39);
      }
      else { // linear interpolation
        _linearInterpolation(&bb, &bb1, &fbb, &fbb1, &ss, &secantSlopeB, &ctxtReal39);
      }
      realToReal34(&ss, &s);

      realSubtract(&ss, &bb, &smb, &ctxtReal39);
      realMultiply(&smb, const_2, &smb, &ctxtReal39);
      realSetPositiveSign(&smb);

      // bisection
      realAdd(&aa, &bb, &mm, &ctxtReal39);
      realMultiply(&mm, const_1on2, &mm, &ctxtReal39);
      realToReal34(&mm, &m);

      // next point
      if(extendRange) {
        if(real34CompareEqual(&fb, &fa)) {
          real34Subtract(&b, &a, &s);
          if(real34CompareAbsLessThan(&s, const34_1e_32)) {
            real34Copy(const34_1e_32, &s);
            if(real34CompareLessThan(&b, &a)) {
              real34SetNegativeSign(&s);
            }
          }
          if(real34CompareAbsLessThan(const34_1e6, &s)) {
            real34Multiply(&s, const34_1e6, &s);
          }
          real34Subtract(&a, &s, &a);
          _executeSolver(variable, &a, &fa);
          //printReal34ToConsole(&b1,"JJ3: f(&a=",")  "); printReal34ToConsole(&fa,"","\n");
          //printReal34ToConsole(&b,"JJ3: f(&b=",")  "); printReal34ToConsole(&fb,"","\n");

          real34Add(&b, &s, &s);
        }
        else if(!real34CompareEqual(&b, &a)) {
          real34Subtract(&b, &a, &s);
          real34Add(&s, &b, &s);
        }
        else if(real34IsNegative(&fb)) {
          real34Multiply(&b, const34_1e_32, &s);
          real34Subtract(&b, &s, &s);
        }
        else {
          real34Multiply(&b, const34_1e_32, &s);
          if(real34CompareAbsLessThan(&s, const34_1e_32)) {
            real34Copy(const34_1e_32, &s);
            if(real34CompareLessThan(&b, &a)) {
              real34SetNegativeSign(&s);
            }
          }
          if(real34IsNegative(&fb)) {
            real34Subtract(&b, &s, &s);
          }
          else {
            real34Add(&b, &s, &s);
          }
        }
        bp1 = &s;
      }
      else if(real34CompareEqual(&b, &s)) {
        bp1 = &m;
      }
      else if(!real34IsSpecial(&s) && ((real34CompareLessThan(&b, &s) && real34CompareLessThan(&s, &m)) || (real34CompareLessThan(&m, &s) && real34CompareLessThan(&s, &m)))) {
        if(realCompareLessThan(&delta, &deltaB) && realCompareLessThan(&smb, &deltaB)) {
          bp1 = &s;
        }
        else {
          bp1 = &m;
        }
      }
      else {
        bp1 = &m;
      }
      //printReal34ToConsole(bp1,"New point:","\n");

      // calculation
      _executeSolver(variable, bp1, &fbp1);
      if(extendRange && (realIsNegative(&secantSlopeA) != realIsNegative(&secantSlopeB)) && !realIsZero(&secantSlopeA) && !realIsZero(&secantSlopeB)) {
        extendRange = false;
        extremum = (real34IsNegative(&fb) == real34IsNegative(&fbp1));
      }

      if(!real34IsSpecial(bp1) && !real34IsSpecial(&fbp1)) {
        if(extendRange) {
          if((real34IsNegative(&fb) != real34IsNegative(&fbp1)) || (real34IsNegative(&fb) != real34IsNegative(&fa))) {
            extendRange = false;
            originallyLevel = false;
          }
          if((real34IsNegative(&fa) == real34IsNegative(&fbp1)) && real34CompareAbsLessThan(&fb, &fbp1)) {
            extendRange = false;
            originallyLevel = false;
            extremum = true;
          }
        }
        else if(real34IsNegative(&fa) == real34IsNegative(&fbp1)) {
          real34Copy(&b, &a);
          real34Copy(&fb, &fa);
        }
        else {
          extendRange = false;
          extremum = false;
          if(!real34CompareEqual(&fb, &fa)) {
            originallyLevel = false;
          }
        }

        if(real34CompareAbsLessThan(&fa, &fbp1)) {
          real34Copy(bp1, &tmp); real34Copy(&a, bp1); real34Copy(&tmp, &a);
          real34Copy(&fbp1, &tmp); real34Copy(&fa, &fbp1); real34Copy(&tmp, &fa);
          real34Copy(&a, &b); real34Copy(&fa, &fb);
        }

        if(bp1 == &s) {
          realToReal34(const_NaN, &b2);
        }
        else {
          real34Copy(&b1, &b2);
        }
        real34Copy(&b, &b1);
        real34Copy(&fb, &fb1);
        real34Copy(bp1, &b);
        real34Copy(&fbp1, &fb);
        //printReal34ToConsole(&b1,"PP: &b1=","  "); printReal34ToConsole(&b,"&b=","\n");
      }

      else if(originallyLevel && (real34IsInfinite(&b) || real34IsInfinite(&a))) {
        result = SOLVER_RESULT_CONSTANT;
      }
      else if(extendRange) {
        extendRange = false;
        originallyLevel = false;
        extremum = true;
      }
      else if(real34IsNegative(&fa) != real34IsNegative(&fb)) {
        result = SOLVER_RESULT_SIGN_REVERSAL;
      }
      else {
        result = SOLVER_RESULT_EXTREMUM;
      }

      real34ToReal(&b, &bb);
      real34ToReal(&b1, &bb1);


      bool_t bb_bb1_converged   = WP34S_RelativeError(&bb, &bb1, &tol, &ctxtReal39);
      bool_t b1_b2_Equal = real34CompareEqual(&b1, &b2);
      bool_t b_b1_Equal  = real34CompareEqual(&b,  &b1);
      fbIsAlmostZero = real34CompareAbsLessThan(&fb,&tol34AlmostZero);

      //printf("SOLVER_RESULT_NORMAL:%i\n",result == SOLVER_RESULT_NORMAL);
      //printf("bb_bb1_converged:%i b1_b2_Equal:%i b_b1_Equal:%i originallyLevel:%i, extremum=%d\n",bb_bb1_converged, b1_b2_Equal, b_b1_Equal, originallyLevel, extremum);
      //   } while(result == SOLVER_RESULT_NORMAL &&
      //           (real34IsSpecial(&b2) || !real34CompareEqual(&b1, &b2) || !(extendRange || extremum || WP34S_RelativeError(&bb, &bb1, &tol, &ctxtReal39))) &&
      //           (originallyLevel || !((!extendRange && WP34S_RelativeError(&bb, &bb1, &tol, &ctxtReal39)) || real34CompareEqual(&b, &b1) || real34CompareEqual(&fb, const34_0)))
      //          );
      //Rewrote the above while condition as more understandable discrete logic:

      if(result != SOLVER_RESULT_NORMAL) {
        break;
      }
      if( (!real34IsSpecial(&b2) && b1_b2_Equal ) &&
        ( (extendRange || bb_bb1_converged) || extremum )  ) {
        break;
      }
      if( !originallyLevel &&
        ((!extendRange && bb_bb1_converged) || b_b1_Equal || fbIsAlmostZero) ) {
        break;
      }
    } while(true);

    _executeSolver(variable, &b, resZ);
    real34Copy(&b1, resY);
    real34Copy(&b, resX);

    if((extendRange && !originallyLevel) || extremum) {
      result = SOLVER_RESULT_EXTREMUM;
    }

    if((--currentSolverNestingDepth) == 0) {
      clearSystemFlag(FLAG_SOLVING);
    }
    else if(was_inting) {
      clearSystemFlag(FLAG_SOLVING);
      setSystemFlag(FLAG_INTING);
    }

    if(fbIsAlmostZero) {  //    if(real34IsZero(&fb)) {
      result = SOLVER_RESULT_NORMAL;
    }

    if(result == SOLVER_RESULT_EXTREMUM) { // Check if the result is really an extremum
      bool_t retainSolvingFlag = getSystemFlag(FLAG_SOLVING);
      setSystemFlag(FLAG_SOLVING);
      real34Copy(const34_1e_32, &tmp);
      while(true) {
        real34Add(resX, &tmp, &a);
        real34Subtract(resX, &tmp, &b);
        _executeSolver(variable, &a, &fa);
        _executeSolver(variable, &b, &fb);
        real34Subtract(&fa, resZ, &fa);
        real34Subtract(&fb, resZ, &fb);
        if(real34IsSpecial(&fa) || real34IsSpecial(&fb)) {
          result = SOLVER_RESULT_OTHER_FAILURE;
          break;
        }
        else if((currentSolverStatus & SOLVER_STATUS_TVM_APPLICATION) && (real34IsSpecial(&a) || real34IsSpecial(&b))) { // terminate the TVM solver to avoid possible infinite loop
          result = SOLVER_RESULT_CONSTANT;
          break;
        }
        else if(real34IsZero(&fa) || real34IsZero(&fb)) {
          real34Multiply(&tmp, const34_100, &tmp);
        }
        else if(real34IsNegative(&fa) == real34IsNegative(&fb)) { // true extremum
          break;
        }
        else { // not an extremum
          result = SOLVER_RESULT_OTHER_FAILURE;
          break;
        }
      }
      if(!retainSolvingFlag) {
        clearSystemFlag(FLAG_SOLVING);
      }
    }

    if(result == SOLVER_RESULT_NORMAL && real34IsInfinite(REGISTER_REAL34_DATA(variable)) && extendRange && real34IsZero(resZ)) {
      result = SOLVER_RESULT_CONSTANT;
    }

    if(lastErrorCode == ERROR_SOLVER_ABORT) {
      result = SOLVER_RESULT_ABORTED;
    }

    return result;
  #else // !TESTSUITE_BUILD
    return SOLVER_RESULT_NORMAL;
  #endif // TESTSUITE_BUILD
}
