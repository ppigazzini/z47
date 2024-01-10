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
 * \file isumprod.c
 ***********************************************/

#include "solver/isumprod.h"

#include "c43Extensions/addons.h"
#include "constantPointers.h"
#include "defines.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "items.h"
#include "mathematics/integerPart.h"
#include "mathematics/iteration.h"
#include "programming/lblGtoXeq.h"
#include "programming/manage.h"
#include "programming/nextStep.h"
#include "realType.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "solver/solve.h"
#include "statusBar.h"
#include "stack.h"
#include "timer.h"
#include "c47.h"


#if !defined(TESTSUITE_BUILD)
  static void _programmableiSumProd(uint16_t label, bool_t prod) {
    uint32_t      loop = 0;
    int16_t       finished = 0;
    longInteger_t resultLi, xLi;
    longInteger_t loopStep, loopTo, iCounter, iLoop;
    longIntegerInit(loopStep);
    longIntegerInit(loopTo);
    longIntegerInit(iCounter);
    longIntegerInit(iLoop);
    longIntegerInit(xLi);
    longIntegerInit(resultLi);
    convertLongIntegerRegisterToLongInteger(REGISTER_Y, loopTo);
    convertLongIntegerRegisterToLongInteger(REGISTER_X, loopStep);
    convertLongIntegerRegisterToLongInteger(REGISTER_Z, iCounter); //Loopfrom counter initial value = From
    uIntToLongInteger(prod ? 1 : 0, resultLi);                     //Initialize long integer accumulator

    longIntegerSubtract(loopTo, iCounter, iLoop);                  //calculate the remaining iteration counter
    if(!longIntegerIsZero(loopStep)) {
      longIntegerDivide(iLoop, loopStep, iLoop);
    }
    loop = longIntegerModuloUInt(iLoop, 100000);

    if(longIntegerCompare(loopTo, iCounter) != 0 &&
        (longIntegerIsZero(loopStep) ||
          (longIntegerCompare(loopTo, iCounter) > 0 && longIntegerCompareUInt(loopStep, 0) <=0) ||
          (longIntegerCompare(loopTo, iCounter) < 0 && longIntegerCompareUInt(loopStep, 0) >=0) )
    ) {
      displayCalcErrorMessage(ERROR_BAD_INPUT, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Counter will not count to destination");
        moreInfoOnError("In function _programmableiSumProd:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      ++currentSolverNestingDepth;
      setSystemFlag(FLAG_SOLVING);


      while(lastErrorCode == ERROR_NONE) {
        hourGlassIconEnabled = true;
        showHideHourGlass();

        finished = longIntegerCompare(iCounter, loopTo);            // 0 mean equal
        finished = finished * longIntegerCompareUInt(loopStep, 0);
        if(finished > 0) {
          break;
        }

        convertLongIntegerToLongIntegerRegister(iCounter, REGISTER_X);
        fnFillStack(NOPARAM);

        #if defined(VERBOSE_COUNTER)
          printRegisterToConsole(REGISTER_X,"[f(",") ");
        #endif //VERBOSE_COUNTER


        dynamicMenuItem = -1;
        execProgram(label);
        if(lastErrorCode != ERROR_NONE) {
          break;
        }

        #if defined(VERBOSE_COUNTER)
          printRegisterToConsole(REGISTER_X," = ","] ");
          printLongIntegerToConsole(resultLi," + "," ");
        #endif //VERBOSE_COUNTER

        if(getRegisterDataType(REGISTER_X) != dtLongInteger) {
          lastErrorCode = ERROR_INVALID_DATA_TYPE_FOR_OP;
          break;
        }


        convertLongIntegerRegisterToLongInteger(REGISTER_X, xLi); //Result accumulated
        if(prod) {
          longIntegerMultiply(resultLi, xLi, resultLi);
        }
        else {
          longIntegerAdd(resultLi, xLi, resultLi);
        }

        #if defined(VERBOSE_COUNTER)
          printLongIntegerToConsole(resultLi,"= "," \n");
        #endif //VERBOSE_COUNTER

        longIntegerAdd(iCounter, loopStep, iCounter);
        printHalfSecUpdate_Integer(timed, "Loop: ",loop--); //timed

        #if defined(DMCP_BUILD)
          if(keyWaiting()) {
              showString("key Waiting ...", &standardFont, 20, 40, vmNormal, false, false);
              printHalfSecUpdate_Integer(force+1, "Interrupted: ",loop);
            break;
          }
        #endif //DMCP_BUILD

        if(finished == 0) {
          break;
        }
      } //WHILE


      if(lastErrorCode == ERROR_NONE) {
        convertLongIntegerToLongIntegerRegister(resultLi, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Error while calculating");
          moreInfoOnError("In function _programmableiSumProd:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        fnUndo(0);
      }

      longIntegerFree(resultLi);
      longIntegerFree(xLi);
      longIntegerFree(iLoop);
      longIntegerFree(iCounter);
      longIntegerFree(loopTo);
      longIntegerFree(loopStep);

      temporaryInformation = TI_NO_INFO;
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }

    } //MAIN IF
    if((--currentSolverNestingDepth) == 0) {
      clearSystemFlag(FLAG_SOLVING);
    }
    hourGlassIconEnabled = false;
    showHideHourGlass();

    printHalfSecUpdate_Integer(force+0, "Loop complete: ",loop);

  }


static bool_t _checkRegisters(void) {
  if(getRegisterDataType(REGISTER_X) != dtLongInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Long integer expected");
      moreInfoOnError("In function _checkiArgument:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return true;
  } else if(getRegisterDataType(REGISTER_Y) != dtLongInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Long integer expected");
      moreInfoOnError("In function _checkiArgument:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return true;
  } else if(getRegisterDataType(REGISTER_Z) != dtLongInteger) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Z);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Long integer expected");
      moreInfoOnError("In function _checkiArgument:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return true;
  }
  return false;
}


static  void _checkiArgument(uint16_t label, bool_t prod) {
    if(label >= FIRST_LABEL && label <= LAST_LABEL) {
      if(!_checkRegisters()) {
        _programmableiSumProd(label, prod);
      }
    }
    else if(label >= REGISTER_X && label <= REGISTER_T) {
      // Interactive mode
      char buf[4];
      switch(label) {
        case REGISTER_X: buf[0] = 'X'; break;
        case REGISTER_Y: buf[0] = 'Y'; break;
        case REGISTER_Z: buf[0] = 'Z'; break;
        case REGISTER_T: buf[0] = 'T'; break;
        default:         buf[0] = 0; /* unlikely */
      }
      buf[1] = 0;
      label = findNamedLabel(buf);
      if(label == INVALID_VARIABLE) {
        displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        #if(EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "string '%s' is not a named label", buf);
          moreInfoOnError("In function _checkiArgument:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      else {
        if(!_checkRegisters()) {
          _programmableiSumProd(label, prod);
        }
      }

    }
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "unexpected parameter %u", label);
        moreInfoOnError("In function _checkiArgument:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
#endif // !TESTSUITE_BUILD

void fnProgrammableiSum(uint16_t label) {
  #if !defined(TESTSUITE_BUILD)
    _checkiArgument(label, false);
  #endif // !TESTSUITE_BUILD
}

void fnProgrammableiProduct(uint16_t label) {
  #if !defined(TESTSUITE_BUILD)
    _checkiArgument(label, true);
  #endif // !TESTSUITE_BUILD
}
