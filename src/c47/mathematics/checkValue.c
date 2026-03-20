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
  int res = 1;

  switch (getRegisterDataType(REGISTER_X)) {
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

  if (t == dtReal34Matrix || t == dtComplex34Matrix)
    SET_TI_TRUE_FALSE(REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns);
  else
    compareTypeErrorX();
}

void fnCheckReIsZero (uint16_t unusedButMandatoryParameter) {
  if (checkXisType(dtComplex34)) {
    SET_TI_TRUE_FALSE(real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)));
  } else {
    compareTypeErrorX();
  }
}

void fnCheckImIsZero (uint16_t unusedButMandatoryParameter) {
  if (checkXisType(dtComplex34)) {
    SET_TI_TRUE_FALSE(real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)));
  } else {
    compareTypeErrorX();
  }
}

void fnCheckReNotZero (uint16_t unusedButMandatoryParameter) {
  if (checkXisType(dtComplex34)) {
    SET_TI_TRUE_FALSE(!real34IsZero(REGISTER_REAL34_DATA(REGISTER_X)));
  } else {
    compareTypeErrorX();
  }
}

void fnCheckImNotZero (uint16_t unusedButMandatoryParameter) {
  if (checkXisType(dtComplex34)) {
    SET_TI_TRUE_FALSE(!real34IsZero(REGISTER_IMAG34_DATA(REGISTER_X)));
  } else {
    compareTypeErrorX();
  }
}

void fnCheckIsVect2d (uint16_t unusedButMandatoryParameter) {
  if (checkXisType(dtReal34Matrix)) {
    const matrixHeader_t *h = REGISTER_MATRIX_HEADER(REGISTER_X);

    SET_TI_TRUE_FALSE(isMatrix2dVector(h->matrixRows, h->matrixColumns));
  } else
    compareTypeErrorX();
}

void fnCheckIsVect3d (uint16_t unusedButMandatoryParameter) {
  if (checkXisType(dtReal34Matrix)) {
    const matrixHeader_t *h = REGISTER_MATRIX_HEADER(REGISTER_X);

    SET_TI_TRUE_FALSE(isMatrix3dVector(h->matrixRows, h->matrixColumns));
  } else
    compareTypeErrorX();
}


static uint32_t matrixXNumElem(void) {
  return REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows * (uint32_t)REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns;
}

static void specialRealCheck(int (*checkFn)(const real34_t *)) {

  int check = 0;
  uint32_t elements, i;

  switch (getRegisterDataType(REGISTER_X)) {
    default:
      compareTypeErrorX();
      return;
    case dtComplex34:
      check = checkFn(REGISTER_IMAG34_DATA(REGISTER_X));
      /* FALL THROUGH */
    case dtTime:
    case dtDate:
    case dtReal34:
      check |= checkFn(REGISTER_REAL34_DATA(REGISTER_X));
      break;

    case dtReal34Matrix: {
      const real34_t *r = REGISTER_REAL34_MATRIX_ELEMENTS(REGISTER_X);

      elements = matrixXNumElem();
      for(i = 0; i < elements; ++i)
        if (checkFn(r + i)) {
          check = 1;
          break;
        }
      break;
    }

    case dtComplex34Matrix: {
      const complex34_t *cpx = REGISTER_COMPLEX34_MATRIX_ELEMENTS(REGISTER_X);

      elements = matrixXNumElem();
      for(i = 0; i < elements; ++i) {
        if (checkFn(&cpx[i].real) || checkFn(&cpx[i].imag)) {
          check = 1;
          break;
        }
      }
      break;
    }
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
    specialRealCheck(wrapperDecQuadIsNaN);
}

void fnCheckInfinite(uint16_t unusedButMandatoryParameter) {
    specialRealCheck(wrapperDecQuadIsInfinite);
}

void fnCheckSpecial(uint16_t unusedButMandatoryParameter) {
    specialRealCheck(wrapperCheckRealSpecial);
}

static void zeroCheck(int neg) {
  int check = 0;

  switch (getRegisterDataType(REGISTER_X)) {
    default:
      compareTypeErrorX();
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
  }
  SET_TI_TRUE_FALSE(check);
}

void fnCheckPlusZero(uint16_t unusedButMandatoryParameter) {
  zeroCheck(0);
}

void fnCheckMinusZero(uint16_t unusedButMandatoryParameter) {
  zeroCheck(1);
}




// GETTYPE return values
//
// Type              Value    Notes
// ─────────────────────────────────────────────────────────────────────
// Long Integer      0        (integer)
// Real              1.0–1.5  RECT=1.0; +angle suffix/10 (see below)
// Complex           2.0–2.5  RECT=2.0; +angle suffix/10 (see below)
// Time              3        (integer)
// Date              4        (integer)
// String            5        (integer)
// Config            9        (integer)
// ─────────────────────────────────────────────────────────────────────
// Real Matrix       6        (integer)
// 2D Vector RECT    6.1      + 0.001 if column
// 2D Vector POLAR   6.2x     x = angle suffix (see below)  + 0.001 if column
// 3D Vector RECT    6.3      + 0.001 if column
// 3D Vector SPH     6.4x     x = angle suffix (see below)  + 0.001 if column
// 3D Vector CYL     6.5x     x = angle suffix (see below)  + 0.001 if column
// 1D or >3D row     6.6
// 1D or >3D column  6.601
// Complex Matrix    7.0–7.5  RECT=7.0; +angle suffix/10 (see below)
// Short Integer     8.bb     bb = base (e.g. 02=binary, 16=hex)
// ─────────────────────────────────────────────────────────────────────
// Angle suffix (tenths for Real/Complex/ComplexMatrix; hundredths for vectors):
//   RECT / no angle   +0
//   Multi-Pi          +1
//   DMS               +2
//   Degrees           +3
//   Grad              +4
//   Radians           +5


static void _pushIntOut(int dtp) {
  longInteger_t lgInt;
  longIntegerInit(lgInt);
  uInt32ToLongInteger(dtp, lgInt);
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
  setSystemFlag(FLAG_ASLIFT);
}

static void _pushRealOut(real34_t* rr) {
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  real34Copy(rr,REGISTER_REAL34_DATA(REGISTER_X));
  setSystemFlag(FLAG_ASLIFT);
}


void fnGetType(uint16_t unusedButMandatoryParameter) {
  real34_t realOut;
  const int dtp = getRegisterDataType(REGISTER_X);
  int dam = getRegisterAngularMode(REGISTER_X);

  switch(dtp) {
    case dtLongInteger:
    case dtTime:
    case dtDate:
    case dtString:
    case dtReal34Matrix:
    case dtConfig: {
      if(isRegisterMatrixVector(REGISTER_X)) {
        int pol   = getVectorRegisterPolarMode(REGISTER_X);
        int pOff  = (pol == amPolarCYL) ? 2 : (pol == amPolar || pol == amPolarSPH) ? 1 : 0;
        pOff     += isRegisterMatrix2dVector(REGISTER_X) ? 1 : isRegisterMatrix3dVector(REGISTER_X) ? 3 : 0;
        int isCol = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows > 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns == 1;
        uInt32ToReal34(dtp*1000 + 100*pOff + 10*(5-(dam&0x07)) + isCol, &realOut);
      } else if(dtp == dtReal34Matrix) {
        int isCol = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows > 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns == 1;
        int isRow = REGISTER_MATRIX_HEADER(REGISTER_X)->matrixRows == 1 && REGISTER_MATRIX_HEADER(REGISTER_X)->matrixColumns > 1;
        if(isCol || isRow) {
          uInt32ToReal34(dtp*1000 + 600 + isCol, &realOut);
        } else {
          _pushIntOut(dtp); break;
        }
      } else {
        _pushIntOut(dtp); break;
      }
      real34Divide(&realOut, const34_1000, &realOut);
      _pushRealOut(&realOut);
      break;
    }
    case dtComplex34Matrix:
      if(!(dam & 0x10)) dam = amNone;
      /* FALL THROUGH */
    case dtShortInteger:
    case dtReal34:
    case dtComplex34: {
      uint32_t v = (dtp == dtShortInteger) ? 10*(dtp*100 + (dam & 0x1F)) : 100*(dtp*10 + 5 - (dam & 0x07));
      uInt32ToReal34(v, &realOut);
      real34Divide(&realOut, const34_1000, &realOut);
      _pushRealOut(&realOut);
      break;
    }
    default:;
  }
  temporaryInformation = TI_REGTYPE;
}
