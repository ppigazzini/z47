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

#include "recall.h"

#include "charString.h"
#include "debug.h"
#include "defines.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "mathematics/compare.h"
#include "mathematics/matrix.h"
#include "memory.h"
#include "plotstat.h"
#include "registerValueConversions.h"
#include "registers.h"
#include "stack.h"
#include "store.h"
#include "typeDefinitions.h"
#include "ui/matrixEditor.h"

#include "c47.h"



#if !defined(TESTSUITE_BUILD)
  static bool_t recallElementReal(real34Matrix_t *matrix) {
    const int16_t i = getIRegisterAsInt(true);
    const int16_t j = getJRegisterAsInt(true);

    liftStack();
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    real34Copy(&matrix->matrixElements[i * matrix->header.matrixColumns + j], REGISTER_REAL34_DATA(REGISTER_X));
    return false;
  }

  static bool_t recallElementComplex(complex34Matrix_t *matrix) {
    const int16_t i = getIRegisterAsInt(true);
    const int16_t j = getJRegisterAsInt(true);

    liftStack();
    reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);
    complex34Copy(&matrix->matrixElements[i * matrix->header.matrixColumns + j], REGISTER_COMPLEX34_DATA(REGISTER_X));
    return false;
  }
#endif // !TESTSUITE_BUILD



void fnRecall(uint16_t regist) {
  if(regInRange(regist)) {
    if(REGISTER_X <= regist && regist <= getStackTop()) {
      copySourceRegisterToDestRegister(regist, TEMP_REGISTER_1);
      liftStack();
      copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
    }
    else {
      if(getSystemFlag(FLAG_ASLIFT)) {
        fnRollUp(NOPARAM);
      }
      copySourceRegisterToDestRegister(regist, REGISTER_X);
      if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
        *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
      }
    }
  }
}



void fnLastX(uint16_t unusedButMandatoryParameter) {
  fnRecall(REGISTER_L);
}



void fnRecallAdd(uint16_t regist) {
  if(regInRange(regist)) {
    if(programRunStop == PGM_RUNNING && regist == REGISTER_L) {
      copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
    if(!saveLastX()) {
      return;
    }
    if(programRunStop == PGM_RUNNING) {
      copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
    }
    copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
    copySourceRegisterToDestRegister(regist == REGISTER_Y ? SAVED_REGISTER_Y : regist == REGISTER_L ? SAVED_REGISTER_L : regist, REGISTER_X);
    if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
    }

    addition[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

    copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

    adjustResult(REGISTER_X, false, true, REGISTER_X, regist, -1);
  }
}



void fnRecallSub(uint16_t regist) {
  if(regInRange(regist)) {
    if(programRunStop == PGM_RUNNING && regist == REGISTER_L) {
      copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
    if(!saveLastX()) {
      return;
    }
    if(programRunStop == PGM_RUNNING) {
      copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
    }
    copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
    copySourceRegisterToDestRegister(regist == REGISTER_Y ? SAVED_REGISTER_Y : regist == REGISTER_L ? SAVED_REGISTER_L : regist, REGISTER_X);
    if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
    }

    subtraction[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

    copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

    adjustResult(REGISTER_X, false, true, REGISTER_X, regist, -1);
  }
}



void fnRecallMult(uint16_t regist) {
  if(regInRange(regist)) {
    if(programRunStop == PGM_RUNNING && regist == REGISTER_L) {
      copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
    if(!saveLastX()) {
      return;
    }
    if(programRunStop == PGM_RUNNING) {
      copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
    }
    copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
    copySourceRegisterToDestRegister(regist == REGISTER_Y ? SAVED_REGISTER_Y : regist == REGISTER_L ? SAVED_REGISTER_L : regist, REGISTER_X);
    if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
    }

    multiplication[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

    copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

    adjustResult(REGISTER_X, false, true, REGISTER_X, regist, -1);
  }
}



void fnRecallDiv(uint16_t regist) {
  if(regInRange(regist)) {
    if(programRunStop == PGM_RUNNING && regist == REGISTER_L) {
      copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
    if(!saveLastX()) {
      return;
    }
    if(programRunStop == PGM_RUNNING) {
      copySourceRegisterToDestRegister(REGISTER_Y, SAVED_REGISTER_Y);
    }
    copySourceRegisterToDestRegister(REGISTER_X, REGISTER_Y);
    copySourceRegisterToDestRegister(regist == REGISTER_Y ? SAVED_REGISTER_Y : regist == REGISTER_L ? SAVED_REGISTER_L : regist, REGISTER_X);
    if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) &= shortIntegerMask;
    }

    division[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

    copySourceRegisterToDestRegister(SAVED_REGISTER_Y, REGISTER_Y);

    adjustResult(REGISTER_X, false, true, REGISTER_X, regist, -1);
  }
}



void fnRecallMin(uint16_t regist) {
  if(regInRange(regist)) {
    if(programRunStop == PGM_RUNNING && regist == REGISTER_L) {
      copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
    if(!saveLastX()) {
      return;
    }
    if(regist >= FIRST_RESERVED_VARIABLE && regist < LAST_RESERVED_VARIABLE && allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.pointerToRegisterData == C47_NULL) {
      copySourceRegisterToDestRegister(regist == REGISTER_L ? SAVED_REGISTER_L : regist, TEMP_REGISTER_1);
      regist = TEMP_REGISTER_1;
    }
    registerMin(REGISTER_X, regist, REGISTER_X);
  }
}



void fnRecallMax(uint16_t regist) {
  if(regInRange(regist)) {
    if(programRunStop == PGM_RUNNING && regist == REGISTER_L) {
      copySourceRegisterToDestRegister(REGISTER_L, SAVED_REGISTER_L);
      if(lastErrorCode != ERROR_NONE) {
        return;
      }
    }
    if(!saveLastX()) {
      return;
    }
    if(regist >= FIRST_RESERVED_VARIABLE && regist < LAST_RESERVED_VARIABLE && allReservedVariables[regist - FIRST_RESERVED_VARIABLE].header.pointerToRegisterData == C47_NULL) {
      copySourceRegisterToDestRegister(regist == REGISTER_L ? SAVED_REGISTER_L : regist, TEMP_REGISTER_1);
      regist = TEMP_REGISTER_1;
    }
    registerMax(REGISTER_X, regist, REGISTER_X);
  }
}



void fnRecallConfig(uint16_t regist) {
    __attribute__((unused)) bool_t compatibility_bool00;    //for use in spare slots below
    __attribute__((unused)) bool_t compatibility_bool0 ;    //for use in spare slots below
    __attribute__((unused)) bool_t compatibility_bool1 ;    //for use in spare slots below
    __attribute__((unused)) bool_t compatibility_bool2 ;    //for use in spare slots below
    __attribute__((unused)) bool_t compatibility_bool3 ;    //for use in spare slots below
    __attribute__((unused)) bool_t compatibility_bool4 ;    //for use in spare slots below
    __attribute__((unused)) bool_t compatibility_bool5 ;    //for use in spare slots below
    __attribute__((unused)) float  compatibility_float1;    //for use in spare slots below
    __attribute__((unused)) float  compatibility_float2;    //for use in spare slots below
    __attribute__((unused)) float  compatibility_float3;    //for use in spare slots below
    __attribute__((unused)) float  compatibility_float4;    //for use in spare slots below
    __attribute__((unused)) float  compatibility_float5;    //for use in spare slots below
    __attribute__((unused)) float  compatibility_float6;    //for use in spare slots below
  if(getRegisterDataType(regist) == dtConfig) {
    dtConfigDescriptor_t *configToRecall = REGISTER_CONFIG_DATA(regist);

    recallFromDtConfigDescriptor(shortIntegerMode);
    recallFromDtConfigDescriptor(shortIntegerWordSize);
    recallFromDtConfigDescriptor(displayFormat);
    recallFromDtConfigDescriptor(displayFormatDigits);
    recallFromDtConfigDescriptor(gapItemLeft);
    recallFromDtConfigDescriptor(gapItemRight);
    recallFromDtConfigDescriptor(gapItemRadix);
    recallFromDtConfigDescriptor(grpGroupingLeft);
    recallFromDtConfigDescriptor(grpGroupingGr1LeftOverflow);
    recallFromDtConfigDescriptor(grpGroupingGr1Left);
    recallFromDtConfigDescriptor(grpGroupingRight);
    recallFromDtConfigDescriptor(currentAngularMode);
    recallFromDtConfigDescriptor(lrSelection);
    recallFromDtConfigDescriptor(lrChosen);
    recallFromDtConfigDescriptor(denMax);
    recallFromDtConfigDescriptor(displayStack);
    recallFromDtConfigDescriptor(firstGregorianDay);
    recallFromDtConfigDescriptor(roundingMode);
    recallFromDtConfigDescriptor(systemFlags);
    synchronizeLetteredFlags();
    xcopy(kbd_usr, configToRecall->kbd_usr, sizeof(kbd_usr));
    recallFromDtConfigDescriptor(fgLN);
    recallFromDtConfigDescriptor(eRPN);
    recallFromDtConfigDescriptor(HOME3);
    recallFromDtConfigDescriptor(ShiftTimoutMode);
    recallFromDtConfigDescriptor(CPXMULT);
    recallFromDtConfigDescriptor(BASE_HOME);
    recallFromDtConfigDescriptor(compatibility_bool00);   //spare
    recallFromDtConfigDescriptor(Norm_Key_00_VAR);
    recallFromDtConfigDescriptor(Input_Default);
    recallFromDtConfigDescriptor(compatibility_bool0);    //spare
    recallFromDtConfigDescriptor(BASE_MYM);
    recallFromDtConfigDescriptor(jm_G_DOUBLETAP);
    recallFromDtConfigDescriptor(compatibility_float1);   //spare
    recallFromDtConfigDescriptor(compatibility_float2);   //spare
    recallFromDtConfigDescriptor(compatibility_float3);   //spare
    recallFromDtConfigDescriptor(compatibility_float4);   //spare
    recallFromDtConfigDescriptor(compatibility_float5);   //spare
    recallFromDtConfigDescriptor(compatibility_float6);   //spare
    recallFromDtConfigDescriptor(compatibility_bool1);    //spare
    recallFromDtConfigDescriptor(compatibility_bool2);    //spare
    recallFromDtConfigDescriptor(compatibility_bool3);    //spare
    recallFromDtConfigDescriptor(PLOT_VECT);
    recallFromDtConfigDescriptor(PLOT_NVECT);
    recallFromDtConfigDescriptor(PLOT_SCALE);
    recallFromDtConfigDescriptor(compatibility_bool4);    //spare
    recallFromDtConfigDescriptor(PLOT_LINE);
    recallFromDtConfigDescriptor(PLOT_CROSS);
    recallFromDtConfigDescriptor(PLOT_BOX);
    recallFromDtConfigDescriptor(PLOT_INTG);
    recallFromDtConfigDescriptor(PLOT_DIFF);
    recallFromDtConfigDescriptor(PLOT_RMS);
    recallFromDtConfigDescriptor(PLOT_SHADE);
    recallFromDtConfigDescriptor(PLOT_AXIS);
    recallFromDtConfigDescriptor(PLOT_ZMX);
    recallFromDtConfigDescriptor(PLOT_ZMY);
    recallFromDtConfigDescriptor(compatibility_bool5);    //spare
    recallFromDtConfigDescriptor(jm_LARGELI);
    recallFromDtConfigDescriptor(constantFractions);
    recallFromDtConfigDescriptor(constantFractionsMode);
    recallFromDtConfigDescriptor(constantFractionsOn);
    recallFromDtConfigDescriptor(displayStackSHOIDISP);
    recallFromDtConfigDescriptor(bcdDisplay);
    recallFromDtConfigDescriptor(topHex);
    recallFromDtConfigDescriptor(bcdDisplaySign);
    recallFromDtConfigDescriptor(DRG_Cycling);
    recallFromDtConfigDescriptor(DM_Cycling);
    recallFromDtConfigDescriptor(SI_All);
    recallFromDtConfigDescriptor(LongPressM);
    recallFromDtConfigDescriptor(LongPressF);
    recallFromDtConfigDescriptor(lastDenominator);
    recallFromDtConfigDescriptor(significantDigits);
    recallFromDtConfigDescriptor(pcg32_global);
    recallFromDtConfigDescriptor(exponentLimit);
    recallFromDtConfigDescriptor(exponentHideLimit);
    recallFromDtConfigDescriptor(lastIntegerBase);
    recallFromDtConfigDescriptor(HOME3);
  }

  else {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "data type %s cannot be used to recall a configuration!", getRegisterDataTypeName(regist, false, false));
      moreInfoOnError("In function fnRecallConfig:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
}



void fnRecallStack(uint16_t regist) {
  uint16_t size = getSystemFlag(FLAG_SSIZE8) ? 8 : 4;

  if(regist + size >= REGISTER_X && regist < REGISTER_X) {
    displayCalcErrorMessage(ERROR_STACK_CLASH, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Cannot execute RCLS, destination register would overlap the stack: %d", regist);
      moreInfoOnError("In function fnRecallStack:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else if((regist >= REGISTER_X && regist < FIRST_LOCAL_REGISTER) || regist + size > FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters) {
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Cannot execute RCLS, destination register is out of range: %d", regist);
      moreInfoOnError("In function fnRecallStack:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    int i;

    if(!saveLastX()) {
      return;
    }

    for(i=0; i<size; i++) {
      copySourceRegisterToDestRegister(regist + i, REGISTER_X + i);
    }

    for(i=0; i<4; i++) {
      adjustResult(REGISTER_X + i, false, true, REGISTER_X + i, -1, -1);
    }
  }
}



void fnRecallVElement(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(matrixIndex == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Cannot execute RCLEL without a matrix indexed");
        moreInfoOnError("In function fnRecallElement:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      callByIndexedMatrix(recallElementReal, recallElementComplex);
    }
  #endif // !TESTSUITE_BUILD
}


void fnRecallElement(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(matrixIndex == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Cannot execute RCLEL without a matrix indexed");
        moreInfoOnError("In function fnRecallElement:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      callByIndexedMatrix(recallElementReal, recallElementComplex);
    }
  #endif // !TESTSUITE_BUILD
}


void fnRecallIJ(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(matrixIndex == INVALID_VARIABLE) {
      displayCalcErrorMessage(ERROR_NO_MATRIX_INDEXED, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Cannot execute RCLIJ without a matrix indexed");
        moreInfoOnError("In function fnRecallIJ:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
    else {
      longInteger_t zero;
      longIntegerInit(zero);

      if(!saveLastX()) {
        return;
      }

      liftStack();
      liftStack();

      if(matrixIndex == INVALID_VARIABLE || !regInRange(matrixIndex) || !((getRegisterDataType(matrixIndex) == dtReal34Matrix) || (getRegisterDataType(matrixIndex) == dtComplex34Matrix))) {
        convertLongIntegerToLongIntegerRegister(zero, REGISTER_Y);
        convertLongIntegerToLongIntegerRegister(zero, REGISTER_X);
      }
      else {
        if(getRegisterDataType(REGISTER_I) == dtLongInteger) {
          copySourceRegisterToDestRegister(REGISTER_I, REGISTER_Y);
        }
        else if(getRegisterDataType(REGISTER_I) == dtReal34) {
          convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_I), REGISTER_Y, DEC_ROUND_DOWN);
        }
        else {
          convertLongIntegerToLongIntegerRegister(zero, REGISTER_Y);
        }
        if(getRegisterDataType(REGISTER_J) == dtLongInteger) {
          copySourceRegisterToDestRegister(REGISTER_J, REGISTER_X);
        }
        else if(getRegisterDataType(REGISTER_J) == dtReal34) {
          convertReal34ToLongIntegerRegister(REGISTER_REAL34_DATA(REGISTER_J), REGISTER_X, DEC_ROUND_DOWN);
        }
        else {
          convertLongIntegerToLongIntegerRegister(zero, REGISTER_X);
        }
      }

      adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
      adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);

      longIntegerFree(zero);
    }
  #endif // !TESTSUITE_BUILD
}
