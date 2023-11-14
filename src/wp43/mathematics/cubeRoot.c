// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 Authors

#include "mathematics/cubeRoot.h"

#include "constantPointers.h"
#include "debug.h"
#include "error.h"
#include "fonts.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/power.h"
#include "mathematics/toPolar.h"
#include "mathematics/toRect.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "wp43.h"



TO_QSPI void (* const Curt[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2         3         4          5          6          7          8           9             10
//          Long integer Real34    Complex34 Time       Date       String     Real34 mat Complex34 m Short integer Config data
            curtLonI,    curtReal, curtCplx, curtError, curtError, curtError, curtRema,  curtCxma,   curtShoI,     curtError
};



/********************************************//**
 * \brief Data type error in curt
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void curtError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate curt for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnCubeRoot:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and curt(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnCubeRoot(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Curt[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



void curtLonI(void) {
  longInteger_t value;

  convertLongIntegerRegisterToLongInteger(REGISTER_X, value);

  if(longIntegerRoot(value, 3, value)) {
    convertLongIntegerToLongIntegerRegister(value, REGISTER_X);
  }
  else {
    real_t x;

    convertLongIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);
    reallocateRegister(REGISTER_X, dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
    if(realIsPositive(&x)) {
      PowerReal(&x, const_1on3, &x, &ctxtReal39);
    }
    else {
      realSetPositiveSign(&x);
      PowerReal(&x, const_1on3, &x, &ctxtReal39);
      realSetNegativeSign(&x);
    }
    convertRealToReal34ResultRegister(&x, REGISTER_X);
  }

  longIntegerFree(value);
}



void curtRema(void) {
  elementwiseRema(curtReal);
}



void curtCxma(void) {
  elementwiseCxma(curtCplx);
}



void curtShoI(void) {
  real_t x;
  int32_t cubeRoot;

  convertShortIntegerRegisterToReal(REGISTER_X, &x, &ctxtReal39);

  if(realIsPositive(&x)) {
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
  }
  else {
    realSetPositiveSign(&x);
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
    realSetNegativeSign(&x);
  }

  realToInt32(&x, cubeRoot);

  if(cubeRoot >= 0) {
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_build_value((int64_t)cubeRoot, 0);
  }
  else {
    *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_build_value(-(int64_t)cubeRoot, 1);
  }
}



void curtReal(void) {
  if(real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function curtReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input of curt when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t x;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &x);

  if(realIsPositive(&x)) {
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
  }
  else {
    realSetPositiveSign(&x);
    PowerReal(&x, const_1on3, &x, &ctxtReal39);
    realSetNegativeSign(&x);
  }
  convertRealToReal34ResultRegister(&x, REGISTER_X);
  setRegisterAngularMode(REGISTER_X, amNone);
}



void curtCplx(void) {
  real_t a, b;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &a);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &b);

  curtComplex(&a, &b, &a, &b, &ctxtReal39);

  convertRealToReal34ResultRegister(&a, REGISTER_X);
  convertRealToImag34ResultRegister(&b, REGISTER_X);
}



void curtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext) {
  real_t a, b;

  realCopy(real, &a);
  realCopy(imag, &b);

  if(realIsZero(&b)) {
    if(realIsPositive(&a)) {
      PowerReal(&a, const_1on3, resReal, realContext);
    }
    else {
      realSetPositiveSign(&a);
      PowerReal(&a, const_1on3, resReal, realContext);
      realSetNegativeSign(resReal);
    }
    realZero(resImag);
  }
  else {
    realRectangularToPolar(&a, &b, &a, &b, realContext);
    PowerReal(&a, const_1on3, &a, realContext);
    realMultiply(&b, const_1on3, &b, realContext);
    realPolarToRectangular(&a, &b, resReal, resImag, realContext);
  }
}
