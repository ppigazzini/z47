// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/****************************************************//**
 * \file checkValue.c
 *******************************************************/

#include "c47.h"

TO_QSPI void (* const CheckValue[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(uint16_t) = {
// regX ==> 1               2               3               4                   5                  6                7               8               9               10
//          Long integer    Real34          Complex34       Time                Date               String           Real34 matrix   Complex34 mat   Short integer   Config data
            checkValueLonI, checkValueReal, checkValueCplx, checkValueDT,       checkValueDT,      checkValueError, checkValueRema, checkValueCxma, checkValueDT,  checkValueError
};


void checkValueError(uint16_t unusedButMandatoryParameter) {
  //displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  //#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  //  sprintf(errorMessage, "cannot do this for %s", getRegisterDataTypeName(REGISTER_X, true, false));
  //  moreInfoOnError("In function fnCheckValue:", errorMessage, NULL, NULL);
  //#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  temporaryInformation = TI_FALSE;
}

static void checkReal(uint16_t mode) {
  switch(mode) {
    case CHECK_VALUE_COMPLEX:
    case CHECK_VALUE_MATRIX: {
      temporaryInformation = TI_FALSE;
      return;
    }
    case CHECK_VALUE_REAL: {
      temporaryInformation = TI_TRUE;
      return;
    }
    default: {
      checkValueError(mode);
    }
  }
}



void fnCheckValue(uint16_t mode) {
  CheckValue[getRegisterDataType(REGISTER_X)](mode);
}




// LongInteger       0
// Real              1.0 (1.0 for no angle; 1.1-1.5 for angle)
// Complex           2.0 (2.0 for RECT, 2.1-2.5 for POLAR)
// Time              3
// Date              4
// String            5
// RealMatrix        6
// ComplexMatrix     7.0 (7.0 for RECT, 7.1-7.5 for POLAR)
// ShortInteger      8.bb (8.02 for binary, 8.16 for Hex)
// Config            9
//   
//   
// For Real, Complex and ComplexMatrix, if it is an angle, add the following:
// No angle or RECT   0
// MultPi      0.1
// DMS         0.2
// Degree      0.3
// Grad        0.4
// Radian      0.5

void fnCheckType(uint16_t unusedButMandatoryParameter) {
  int dtp = getRegisterDataType(REGISTER_X);
  int dam = getRegisterAngularMode(REGISTER_X);
  if(dtp == dtComplex34Matrix && !(dam & 0x10)) {
    dam = amNone; //pre-set dam, to cause no angle display if RECT
  }
  switch(getRegisterDataType(REGISTER_X)) {
    case dtLongInteger    :
    case dtTime           :
    case dtDate           :
    case dtString         :
    case dtReal34Matrix   :
    case dtConfig         : {
      longInteger_t lgInt;
      longIntegerInit(lgInt);
      uInt32ToLongInteger(dtp, lgInt);
      setSystemFlag(FLAG_ASLIFT); // 5
      liftStack();
      convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
      longIntegerFree(lgInt);
      setSystemFlag(FLAG_ASLIFT);
      break;
    }
    case dtShortInteger   :
    case dtComplex34Matrix:
    case dtReal34         :
    case dtComplex34      : {
      real34_t rr;
      int exportValue = (dtp == dtShortInteger) ? dtp*100 + (dam & 0x1F) : dtp*10 + 5 - (dam & 0x07); // BASE 8.16 for HEX; Angle: 1.3 for Degrees
      uInt32ToReal34(exportValue,&rr);
      setSystemFlag(FLAG_ASLIFT); // 5
      liftStack();
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      if(dtp == dtShortInteger) {
        real34Multiply(&rr,const34_1on10,&rr);
      }
      real34Multiply(&rr,const34_1on10,REGISTER_REAL34_DATA(REGISTER_X));
      setSystemFlag(FLAG_ASLIFT);
      break;
    }
    default:; //impossible to not be one of the defines
  }
}


void checkValueDT(uint16_t mode) {
  if(   (mode == CHECK_VALUE_DATE && getRegisterDataType(REGISTER_X) == dtDate)
     || (mode == CHECK_VALUE_TIME && getRegisterDataType(REGISTER_X) == dtTime)
     || ((mode == CHECK_VALUE_SINT || mode == CHECK_VALUE_NUMBER) && getRegisterDataType(REGISTER_X) == dtShortInteger)) {
    temporaryInformation = TI_TRUE;
    return;
  }
  temporaryInformation = TI_FALSE;
}


void checkValueLonI(uint16_t mode) {
  longInteger_t val;

  if(mode == CHECK_VALUE_POSITIVE_ZERO || mode == CHECK_VALUE_NEGATIVE_ZERO) { // unlikely true
    convertLongIntegerRegisterToLongInteger(REGISTER_X, val);
    if(mode == CHECK_VALUE_POSITIVE_ZERO) {
      SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && longIntegerIsZero(val) && longIntegerIsPositive(val));
    }
    else { // mode == CHECK_VALUE_NEGATIVE_ZERO
      SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && longIntegerIsZero(val) && longIntegerIsNegative(val));
    }
    longIntegerFree(val);
    return;
  }
  if(mode == CHECK_VALUE_LINT || mode == CHECK_VALUE_NUMBER) {
    temporaryInformation = TI_TRUE;
    return;
  }
  checkReal(mode);
}



void checkValueRema(uint16_t mode) {
  const int32_t elements = (int32_t)REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows * (int32_t)REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
  switch(mode) {
    case CHECK_VALUE_MATRIX: {
      temporaryInformation = TI_TRUE;
      return;
    }
    case CHECK_VALUE_MATRIX_SQUARE: {
      SET_TI_TRUE_FALSE(REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns);
      return;
    }
    case CHECK_VALUE_COMPLEX: {
      temporaryInformation = TI_FALSE;
      return;
    }
    case CHECK_VALUE_REAL: {
      temporaryInformation = TI_TRUE;
      return;
    }
    case CHECK_VALUE_SPECIAL:  { // true if any elements is special
      temporaryInformation = TI_FALSE;
      if(getSystemFlag(FLAG_SPCRES)) {
        for(int i = 0; i < elements; ++i) {
          if(real34IsSpecial(REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + i)) {
            temporaryInformation = TI_TRUE;
          }
        }
      }
      return;
    }
    case CHECK_VALUE_NAN: {
      temporaryInformation = TI_FALSE;
      if(getSystemFlag(FLAG_SPCRES)) {
        for(int i = 0; i < elements; ++i) {
          if(real34IsNaN(REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + i)) {
            temporaryInformation = TI_TRUE;
          }
        }
      }
      return;
    }
    default: {
      checkValueError(mode);
    }
  }
}



void checkValueCxma(uint16_t mode) {
  const int32_t elements = (int32_t)REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows * (int32_t)REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
  switch(mode) {
    case CHECK_VALUE_MATRIX: {
      temporaryInformation = TI_TRUE;
      return;
    }
    case CHECK_VALUE_MATRIX_SQUARE: {
      SET_TI_TRUE_FALSE(REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns);
      return;
    }
    case CHECK_VALUE_COMPLEX: {
      temporaryInformation = TI_FALSE;
      if(getSystemFlag(FLAG_SPCRES)) {
        for(int i = 0; i < elements; ++i) {
          if(!real34IsZero(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i))) {
            temporaryInformation = TI_TRUE;
          }
        }
      }
      return;
    }
    case CHECK_VALUE_REAL: { // true if all elements are real
      temporaryInformation = TI_TRUE;
      if(getSystemFlag(FLAG_SPCRES)) {
        for(int i = 0; i < elements; ++i) {
          if(!real34IsZero(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i))) {
            temporaryInformation = TI_FALSE;
          }
        }
      }
      return;
    }
    case CHECK_VALUE_SPECIAL: { // true if any elements is special
      temporaryInformation = TI_FALSE;
      if(getSystemFlag(FLAG_SPCRES)) {
        for(int i = 0; i < elements; ++i) {
          if(real34IsSpecial(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i)) || real34IsSpecial(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i))) {
            temporaryInformation = TI_TRUE;
          }
        }
      }
      return;
    }
    case CHECK_VALUE_NAN: {
      temporaryInformation = TI_FALSE;
      if(getSystemFlag(FLAG_SPCRES)) {
        for(int i = 0; i < elements; ++i) {
          if(real34IsNaN(VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i)) || real34IsNaN(VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i))) {
            temporaryInformation = TI_TRUE;
          }
        }
      }
      return;
    }
    default: {
      checkValueError(mode);
    }
  }
}



void checkValueShoI(uint16_t mode) {
  if(mode == CHECK_VALUE_POSITIVE_ZERO || mode == CHECK_VALUE_NEGATIVE_ZERO) {
    if(shortIntegerMode == SIM_1COMPL || shortIntegerMode == SIM_SIGNMT) {
      if(mode == CHECK_VALUE_POSITIVE_ZERO && (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerMask) == 0) {
          temporaryInformation = TI_TRUE;
          return;
      }
      if(mode == CHECK_VALUE_NEGATIVE_ZERO && (*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) & shortIntegerMask) == (shortIntegerMode == SIM_1COMPL ? shortIntegerMask : shortIntegerSignBit)) {
          temporaryInformation = TI_TRUE;
          return;
      }
    }
    temporaryInformation = TI_FALSE;
    return;
  }
  checkReal(mode);
}



void checkValueReal(uint16_t mode) {
  longInteger_t val;

  switch(mode) {
    case CHECK_VALUE_SPECIAL: {
      SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && real34IsSpecial(REGISTER_REAL34_DATA(REGISTER_X)));
      return;
    }
    case CHECK_VALUE_NAN: {
      SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)));
      return;
    }
    case CHECK_VALUE_ANGLE: {
      if(getRegisterAngularMode(REGISTER_X) != amNone) {
        temporaryInformation = TI_TRUE;
      }
      return;
    }
    case CHECK_VALUE_NUMBER: {
      temporaryInformation = TI_TRUE;
      return;
    }
  }
  if(getRegisterAngularMode(REGISTER_X) == amNone) {
    switch(mode) {
      case CHECK_VALUE_POSITIVE_ZERO: {
        SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)));
        return;
      }
      case CHECK_VALUE_NEGATIVE_ZERO: {
        SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)) && real34IsNegative(REGISTER_REAL34_DATA(REGISTER_X)));
        return;
      }
      case CHECK_VALUE_INFINITY: {
        if(getSystemFlag(FLAG_SPCRES) && real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) {
          temporaryInformation = TI_TRUE;
          longIntegerInit(val);
          int32ToLongInteger(real34IsPositive(REGISTER_REAL34_DATA(REGISTER_X)) ? 1 : -1, val);
          convertLongIntegerToLongIntegerRegister(val, REGISTER_X);
          longIntegerFree(val);
        }
        else {
          temporaryInformation = TI_FALSE;
          longIntegerInit(val);
          uInt32ToLongInteger(0u, val);
          convertLongIntegerToLongIntegerRegister(val, REGISTER_X);
          longIntegerFree(val);
        }
        return;
      }
    }
  }
  checkReal(mode);
}



void checkValueCplx(uint16_t mode) {
  switch(mode) {
    case CHECK_VALUE_COMPLEX: {
      SET_TI_TRUE_FALSE(!real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)));
      return;
    }
    case CHECK_VALUE_REAL: {
      SET_TI_TRUE_FALSE(real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)));
      return;
    }
    case CHECK_VALUE_SPECIAL: {
      SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && (real34IsSpecial(REGISTER_REAL34_DATA(REGISTER_X)) || real34IsSpecial(REGISTER_IMAG34_DATA(REGISTER_X))));
      return;
    }
    case CHECK_VALUE_NAN: {
      SET_TI_TRUE_FALSE(getSystemFlag(FLAG_SPCRES) && (real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)) || real34IsNaN(REGISTER_IMAG34_DATA(REGISTER_X))));
      return;
    }
    case CHECK_VALUE_MATRIX: {
      temporaryInformation = TI_FALSE;
      return;
    }
    case CHECK_VALUE_NUMBER: {
      temporaryInformation = TI_TRUE;
      return;
    }
    default: {
      checkValueError(mode);
    }
  }
}
