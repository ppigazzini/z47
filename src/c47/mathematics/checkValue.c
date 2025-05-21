// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/****************************************************//**
 * \file checkValue.c
 *******************************************************/

#include "c47.h"

static bool_t checkXisType(uint16_t type) {
  return getRegisterDataType(REGISTER_X) == type;
}

void fnCheckType(uint16_t type) {
  SET_TI_TRUE_FALSE(checkXisType(type));
}

void fnCheckReal(uint16_t unusedButMandatoryParameter) {
  const uint32_t t = getRegisterDataType(REGISTER_X);

  SET_TI_TRUE_FALSE(t <= dtDate || t == dtShortInteger);
}

void fnCheckNumber(uint16_t unusedButMandatoryParameter) {
  uint32_t t = getRegisterDataType(REGISTER_X);
  int res = 1;

  switch (t) {
    default:
      res = 0;
      break;

    case dtLongInteger:
    case dtShortInteger:
      break;

    case dtComplex34:
      res = !real34IsSpecial(REGISTER_IMAG34_DATA(REGISTER_X));
      /* FALL THROUGH */
    case dtTime:
    case dtDate:
    case dtReal34:
      res &= !real34IsSpecial(REGISTER_REAL34_DATA(REGISTER_X));
      break;
  }
  SET_TI_TRUE_FALSE(res);
}

void fnCheckAngle(uint16_t unusedButMandatoryParameter) {
  SET_TI_TRUE_FALSE(checkXisType(dtReal34) && getRegisterAngularMode(REGISTER_X) != amNone);
}

void fnCheckMatrix(uint16_t unusedButMandatoryParameter) {
  const uint32_t t = getRegisterDataType(REGISTER_X);

  SET_TI_TRUE_FALSE(t == dtReal34Matrix || t == dtComplex34Matrix);
}

void fnCheckMatrixSquare(uint16_t unusedButMandatoryParameter) {
  const uint32_t t = getRegisterDataType(REGISTER_X);

  SET_TI_TRUE_FALSE((t == dtReal34Matrix || t == dtComplex34Matrix)
                    && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns);
}

void fnCheckIsNotReal (uint16_t unusedButMandatoryParameter) {
  const uint32_t t = getRegisterDataType(REGISTER_X);

  /* Should a matrix be checked? */
  if (t == dtComplex34) {
    SET_TI_TRUE_FALSE(!real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)));
  } else {
    SET_TI_TRUE_FALSE(t > dtDate && t != dtShortInteger);
  }
}

void fnCheckIsNotImag (uint16_t unusedButMandatoryParameter) {
  const uint32_t t = getRegisterDataType(REGISTER_X);

  /* Should a complex matrix be checked? */
  if (t == dtComplex34) {
    SET_TI_TRUE_FALSE(real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)));
  } else {
    SET_TI_TRUE_FALSE(t <= dtDate || t == dtShortInteger);
  }
}

void fnCheckIsVect2d (uint16_t unusedButMandatoryParameter) {
  SET_TI_TRUE_FALSE(isRegisterMatrix2dVector(REGISTER_X));
}

void fnCheckIsVect3d (uint16_t unusedButMandatoryParameter) {
  SET_TI_TRUE_FALSE(isRegisterMatrix3dVector(REGISTER_X));
}


static uint32_t matrixXNumElem(void) {
  return REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows * (uint32_t)REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
}

static void realCheck(int (*checkFn)(const real34_t *)) {

  int check = 0;
  uint32_t elements, i;

  switch (getRegisterDataType(REGISTER_X)) {
    default:
      break;
    case dtComplex34:
      check = checkFn(REGISTER_IMAG34_DATA(REGISTER_X));
      /* FALL THROUGH */
    case dtTime:
    case dtDate:
    case dtReal34:
      check |= checkFn(REGISTER_REAL34_DATA(REGISTER_X));
      break;

    case dtReal34Matrix:
      elements = matrixXNumElem();
      for(i = 0; i < elements; ++i)
        if (!checkFn(REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + i))
          break;
      check = 1;
      break;

    case dtComplex34Matrix:
      elements = matrixXNumElem();
      for(i = 0; i < elements; ++i) {
        const complex34_t *cpx = REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i;

        if (!checkFn(&cpx->real)
            || !checkFn(&cpx->imag))
          break;
      }
      check = 1;
      break;
  }
  SET_TI_TRUE_FALSE(check);
}

static int wrapperDecQuadIsNaN(const real34_t *r) {
    return (int)decQuadIsNaN(r);
}

static int wrapperDecQuadIsInfinite(const real34_t *r) {
    return (int)decQuadIsInfinite(r);
}

static int wrapperCheckRealSpecial(const real34_t *r) {
    return wrapperDecQuadIsNaN(r) || wrapperDecQuadIsInfinite(r);
}

void fnCheckNaN(uint16_t unusedButMandatoryParameter) {
    realCheck(wrapperDecQuadIsNaN);
}

void fnCheckInfinite(uint16_t unusedButMandatoryParameter) {
    realCheck(wrapperDecQuadIsInfinite);
}

void fnCheckSpecial(uint16_t unusedButMandatoryParameter) {
    realCheck(wrapperCheckRealSpecial);
}

static void zeroCheck(int neg) {
  int check = 0;
  uint32_t elements, i;

  switch (getRegisterDataType(REGISTER_X)) {
    default:
      break;
    case dtLongInteger:
      if (!neg) {
        longInteger_t val;

        convertLongIntegerRegisterToLongInteger(REGISTER_X, val);
        check = longIntegerIsZero(val);
        longIntegerFree(val);
      }
      break;

    case dtShortInteger: {
      uint64_t u64;
      int16_t sign16;

      convertShortIntegerRegisterToUInt64(REGISTER_X, &sign16, &u64);
      check = u64 == 0 && sign16 == neg;
      break;
    }

    case dtComplex34: {
      const complex34_t *cpx = REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X);

      check = real34IsZero(&cpx->real) && real34IsZero(&cpx->imag) &&
              (real34IsNegative(&cpx->real) == neg || real34IsNegative(&cpx->imag) == neg);
      break;
    }

    case dtTime:
    case dtDate:
    case dtReal34:
      check = real34IsNegative(REGISTER_REAL34_DATA(REGISTER_X)) == neg && real34IsZero(REGISTER_REAL34_DATA(REGISTER_X));
      break;

    case dtReal34Matrix:
      elements = matrixXNumElem();
      for(i = 0; i < elements; ++i) {
        const real34_t *r = REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X) + i;

        if (!real34IsZero(r) || real34IsNegative(r) != neg)
          break;
      }
      check = 1;
      break;

    case dtComplex34Matrix:
      elements = matrixXNumElem();
      for(i = 0; i < elements; ++i) {
        const complex34_t *cpx = REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X) + i;

        if (!real34IsZero(&cpx->real) || !real34IsZero(&cpx->imag))
          break;
        if (real34IsNegative(&cpx->real) != neg && real34IsNegative(&cpx->imag) != neg)
          break;
      }
      check = 1;
      break;
  }
  SET_TI_TRUE_FALSE(check);
}

void fnCheckPlusZero(uint16_t unusedButMandatoryParameter) {
  zeroCheck(0);
}

void fnCheckMinusZero(uint16_t unusedButMandatoryParameter) {
  zeroCheck(1);
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

void fnGetType(uint16_t unusedButMandatoryParameter) {
  const int dtp = getRegisterDataType(REGISTER_X);
  int dam = getRegisterAngularMode(REGISTER_X);

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
    case dtComplex34Matrix:
      if(!(dam & 0x10))
        dam = amNone; //pre-set dam, to cause no angle display if RECT
      /* FALL THROUGH */
    case dtShortInteger   :
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
  temporaryInformation = TI_REGTYPE;
}
