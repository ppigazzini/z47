// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file logxy.c
 ***********************************************/

#include "mathematics/logxy.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "items.h"
#include "longIntegerType.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/division.h"
#include "mathematics/integerPartLonginteger.h"
#include "mathematics/ln.h"
#include "mathematics/matrix.h"
#include "mathematics/power.h"
#include "mathematics/wp34s.h"
#include "realType.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"


TO_QSPI void (* const logBaseX[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])() = {
// regX |    regY ==>    1              2              3              4           5           6           7              8              9              10
//      V                Long integer   Real34         Complex34      Time        Date        String      Real34 mat     Complex34 mat  Short integer  Config data
/*  1 Long integer  */ { logxyLonILonI, logxyRealLonI, logxyCplxLonI, logxyError, logxyError, logxyError, logxyRemaLonI, logxyCxmaLonI, logxyShoILonI, logxyError },
/*  2 Real34        */ { logxyLonIReal, logxyRealReal, logxyCplxReal, logxyError, logxyError, logxyError, logxyRemaReal, logxyCxmaReal, logxyShoIReal, logxyError },
/*  3 Complex34     */ { logxyLonICplx, logxyRealCplx, logxyCplxCplx, logxyError, logxyError, logxyError, logxyRemaCplx, logxyCxmaCplx, logxyShoICplx, logxyError },
/*  4 Time          */ { logxyError,    logxyError,    logxyError,    logxyError, logxyError, logxyError, logxyError,    logxyError,    logxyError,    logxyError },
/*  5 Date          */ { logxyError,    logxyError,    logxyError,    logxyError, logxyError, logxyError, logxyError,    logxyError,    logxyError,    logxyError },
/*  6 String        */ { logxyError,    logxyError,    logxyError,    logxyError, logxyError, logxyError, logxyError,    logxyError,    logxyError,    logxyError },
/*  7 Real34 mat    */ { logxyError,    logxyError,    logxyError,    logxyError, logxyError, logxyError, logxyError,    logxyError,    logxyError,    logxyError },
/*  8 Complex34 mat */ { logxyError,    logxyError,    logxyError,    logxyError, logxyError, logxyError, logxyError,    logxyError,    logxyError,    logxyError },
/*  9 Short integer */ { logxyLonIShoI, logxyRealShoI, logxyCplxShoI, logxyError, logxyError, logxyError, logxyRemaShoI, logxyCxmaShoI, logxyShoIShoI, logxyError },
/* 10 Config data   */ { logxyError,    logxyError,    logxyError,    logxyError, logxyError, logxyError, logxyError,    logxyError,    logxyError,    logxyError }
};

/********************************************//**
 * \brief Data type error in logxy
 *
 * \param void
 * \return void
 ***********************************************/
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  void logxyError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate Log of %s with base %s", getRegisterDataTypeName(REGISTER_Y, true, false), getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnLogXY:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

/********************************************//**
 * \brief regX ==> regL and log(regX)(RegY) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnLogXY(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  logBaseX[getRegisterDataType(REGISTER_X)][getRegisterDataType(REGISTER_Y)]();

  adjustResult(REGISTER_X, true, true, REGISTER_X, -1, -1);
}

static void logXYComplex(const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag, real_t *rReal, real_t *rImag, realContext_t *realContext) {
  real_t lnxReal, lnxImag;

  // lnComplex handle the case where y = 0+i0.
  lnComplex(yReal, yImag, rReal, rImag, realContext);                             //   r = Ln(y)
  lnComplex(xReal, xImag, &lnxReal, &lnxImag, realContext);                       // lnx = Ln(x)
  divComplexComplex(rReal, rImag, &lnxReal, &lnxImag, rReal, rImag, realContext); // r = Ln(y) / Ln(x)
}

#define COMPLEX_IS_ZERO(real, imag) (realIsZero(real) && (imag==NULL || realIsZero(imag)))

static bool_t checkArgs(const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag) {
  /*
   * Log(0, 0) = +Inf
   * Log(x, 0) = -Inf x!=0
   * Log(0, y) = NaN  y!=0
   */
  if(COMPLEX_IS_ZERO(xReal, xImag) && COMPLEX_IS_ZERO(yReal, yImag)) {
    displayCalcErrorMessage(ERROR_OVERFLOW_PLUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("checkArgs", "cannot calculate LogXY with x=0 and y=0");
  }
  else if(!COMPLEX_IS_ZERO(xReal, xImag) && COMPLEX_IS_ZERO(yReal, yImag)) {
    displayCalcErrorMessage(ERROR_OVERFLOW_MINUS_INF, ERR_REGISTER_LINE, REGISTER_X);
    EXTRA_INFO_MESSAGE("checkArgs", "cannot calculate LogXY with x=0 and y!=0");
  }
  else if(COMPLEX_IS_ZERO(xReal, xImag) && !COMPLEX_IS_ZERO(yReal, yImag)) {
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
  }
  else {
    return true;
  }

  return false;
}

static void logxy(const real_t *xReal, const real_t *yReal, realContext_t *realContext) {
  real_t rReal, rImag;

  /*
   * Log(0, 0) = +Inf
   * Log(x, 0) = -Inf x!=0
   * Log(0, y) = NaN  y!=0
   */
  if(checkArgs(xReal, NULL, yReal, NULL)) {
    if(realIsNegative(xReal) || realIsNegative(yReal)) {
      logXYComplex(xReal, const_0, yReal, const_0, &rReal, &rImag, realContext);

      if(realIsZero(&rImag)) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(&rReal, REGISTER_X);
      }
      else if(getFlag(FLAG_CPXRES)) {
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
      }
      else if(getFlag(FLAG_SPCRES)) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        convertRealToReal34ResultRegister(const_NaN, REGISTER_X);
      }
      else {
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        EXTRA_INFO_MESSAGE("logxy", "cannot calculate LogXY with x<0 or y<0 when flag I is not set");
      }
    }
    else {
      WP34S_Logxy(yReal, xReal, &rReal, realContext);

      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      convertRealToReal34ResultRegister(&rReal, REGISTER_X);
    }
  }
}


void logxyLonILonI(void) {
  real_t x, y;
  longInteger_t antilog, yy, xx, rr;

  convertLongIntegerRegisterToLongInteger(REGISTER_Y, antilog);
  convertLongIntegerRegisterToLongInteger(REGISTER_Y, yy);
  convertLongIntegerRegisterToLongInteger(REGISTER_X, xx);

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  logxy(&x, &y, &ctxtReal39);

  if(getRegisterDataType(REGISTER_X) == dtReal34 && real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
    longIntegerInit(rr);
    convertReal34ToLongInteger(REGISTER_REAL34_DATA(REGISTER_X), rr, DEC_ROUND_DOWN);
    longIntegerPower(xx, rr, yy);
    fflush(stdout);
    if(longIntegerCompare(antilog, yy) == 0) {
      lintReal();
    }
    longIntegerFree(rr);
  }

  longIntegerFree(xx);
  longIntegerFree(yy);
  longIntegerFree(antilog);
}



void logxyRealLonI(void) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  logxy(&x, &y, &ctxtReal39);
}



void logxyCplxLonI(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  convertLongIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyShoILonI(void) {
  real_t x, y;
  int32_t base = getRegisterShortIntegerBase(REGISTER_Y);

  convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  logxy(&x, &y, &ctxtReal39);

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      EXTRA_INFO_MESSAGE("logxy", "cannot calculate LogXY with x=0");
      return;
    }
    else if(real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
      clearSystemFlag(FLAG_CARRY);
    }
    else {
      setSystemFlag(FLAG_CARRY);
    }
    fnChangeBase((uint16_t)base);
  }
}



void logxyLonIReal(void) {
  real_t x, y;

  convertLongIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  logxy(&x, &y, &ctxtReal39);
}



void logxyRealReal(void) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  logxy(&x, &y, &ctxtReal39);
}



void logxyCplxReal(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  realZero(&xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyShoIReal(void) {
  real_t x, y;
  int32_t base = getRegisterShortIntegerBase(REGISTER_Y);

  convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  logxy(&x, &y, &ctxtReal39);

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      EXTRA_INFO_MESSAGE("logxy", "cannot calculate LogXY with x=0");
      return;
    }
    else if(real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
      clearSystemFlag(FLAG_CARRY);
    }
    else {
      setSystemFlag(FLAG_CARRY);
    }
    fnChangeBase((uint16_t)base);
  }
}



void logxyLonICplx(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  convertLongIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyRealCplx(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyCplxCplx(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyShoICplx(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  convertShortIntegerRegisterToReal(REGISTER_Y, &yReal, &ctxtReal39);
  realZero(&yImag);

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &xReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyLonIShoI(void) {
  convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X);
  logxyLonILonI();
}



void logxyRealShoI(void) {
  real_t x, y;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &y);
  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  logxy(&x, &y, &ctxtReal39);
}



void logxyCplxShoI(void) {
  real_t xReal, xImag, yReal, yImag, rReal, rImag;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_Y), &yReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_Y), &yImag);

  convertShortIntegerRegisterToReal(REGISTER_X, &xReal, &ctxtReal39);
  realZero(&xImag);

  if(checkArgs(&xReal, &xImag, &yReal, &yImag)) {
    logXYComplex(&xReal, &xImag, &yReal, &yImag, &rReal, &rImag, &ctxtReal39);

    reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
    convertComplexToResultRegister(&rReal, &rImag, REGISTER_X);
  }
}



void logxyShoIShoI(void) {
  real_t x, y;
  int32_t base = getRegisterShortIntegerBase(REGISTER_Y);

  convertShortIntegerRegisterToReal(REGISTER_Y, &y, &ctxtReal39);
  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  logxy(&x, &y, &ctxtReal39);

  if(getRegisterDataType(REGISTER_X) == dtReal34) {
    if(real34IsNaN(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      EXTRA_INFO_MESSAGE("logxy", "cannot calculate LogXY with x=0");
      return;
    }
    else if(real34IsAnInteger(REGISTER_REAL34_DATA(REGISTER_X))) {
      clearSystemFlag(FLAG_CARRY);
    }
    else {
      setSystemFlag(FLAG_CARRY);
    }
    fnChangeBase((uint16_t)base);
  }
}



void logxyRemaLonI(void) {
  elementwiseRemaLonI(logxyRealLonI);
}



void logxyCxmaLonI(void) {
  elementwiseCxmaLonI(logxyCplxLonI);
}



void logxyRemaReal(void) {
  elementwiseRemaReal(logxyRealReal);
}



void logxyCxmaReal(void) {
  elementwiseCxmaReal(logxyCplxReal);
}



void logxyRemaCplx(void) {
  convertReal34MatrixRegisterToComplex34MatrixRegister(REGISTER_Y, REGISTER_Y);
  logxyCxmaCplx();
}



void logxyCxmaCplx(void) {
  elementwiseCxmaCplx(logxyCplxCplx);
}



void logxyRemaShoI(void) {
  elementwiseRemaShoI(logxyRealShoI);
}



void logxyCxmaShoI(void) {
  elementwiseCxmaShoI(logxyCplxShoI);
}
