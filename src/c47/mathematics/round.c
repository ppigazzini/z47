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
 * \file round.c
 ***********************************************/

#include "mathematics/round.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "mathematics/toRect.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "saveRestoreCalcState.h"
#include "screen.h"

#include "c47.h"

static void roundNoOp (void);


TO_QSPI void (* const Round[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1            2          3          4          5          6           7          8           9             10
//          Long integer Real34     Complex34  Time       Date       String      Real34 mat Complex34 m Short integer Config data
            roundNoOp,   roundReal, roundCplx, roundTime, roundDate, roundError, roundRema, roundCxma,  roundNoOp,    roundError
};



/********************************************//**
 * \brief Data type error in round
 *
 * \param void
 * \return void
 ***********************************************/
#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void roundError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate ROUND for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function roundError:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



/********************************************//**
 * \brief regX ==> regL and round(regX) ==> regX
 * enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnRound(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  Round[getRegisterDataType(REGISTER_X)]();

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}


static void roundNoOp(void) {
}

void roundTime(void) {
  real34_t real34, value34;
  uint32_t digits;

  real34Copy(REGISTER_REAL34_DATA(REGISTER_X), &real34);

  switch(timeDisplayFormatDigits) {
    case 0: { // no rounding
      break;
    }
    case 1:
    case 2: { // round to minutes
      int32ToReal34(60, &value34);
      real34Divide(&real34, &value34, &real34);
      real34ToIntegralValue(&real34, &real34, DEC_ROUND_DOWN);
      real34Multiply(&real34, &value34, &real34);
      break;
    }
    default: { // round to seconds, milliseconds, microseconds, ...
      int32ToReal34(10, &value34);
      for(digits = 4; digits <= timeDisplayFormatDigits; ++digits) {
        real34Multiply(&real34, &value34, &real34);
      }
      real34ToIntegralValue(&real34, &real34, roundingMode);
      for(digits = 4; digits <= timeDisplayFormatDigits; ++digits) {
        real34Divide(&real34, &value34, &real34);
      }
    }
  }

  real34Copy(&real34, REGISTER_REAL34_DATA(REGISTER_X));
}



void roundDate(void) {
  // For the case accidentally added fractions of a day. It should not occur.
  real34_t real34, value34;

  real34Copy(REGISTER_REAL34_DATA(REGISTER_X), &real34);

  int32ToReal34(43200, &value34);
  real34Subtract(&real34, &value34, &real34);
  int32ToReal34(86400, &value34);
  real34Divide(&real34, &value34, &real34);

  real34ToIntegralValue(&real34, &real34, roundingMode);

  real34Multiply(&real34, &value34, &real34);
  int32ToReal34(43200, &value34);
  real34Add(&real34, &value34, &real34);

  real34Copy(&real34, REGISTER_REAL34_DATA(REGISTER_X));
}



void roundRema(void) {
  elementwiseRema(roundReal);
}



void roundCxma(void) {
  elementwiseCxma(roundCplx);
}



void roundReal(void) {
  updateDisplayValueX = true;
  displayValueX[0] = 0;
  refreshRegisterLine(REGISTER_X);
  updateDisplayValueX = false;

  if(getSystemFlag(FLAG_FRACT)) {
    int16_t endOfIntegerPart, slashPos;
    real34_t numerator, denominator;

    endOfIntegerPart = -1;
    if(getSystemFlag(FLAG_PROPFR)) { // a b/c
      while(displayValueX[++endOfIntegerPart] != ' ') {
      }
      displayValueX[endOfIntegerPart] = 0;
      stringToReal34(displayValueX, REGISTER_REAL34_DATA(REGISTER_X));
    }
    else { // FT_IMPROPER d/c
      real34Zero(REGISTER_REAL34_DATA(REGISTER_X));
    }

    slashPos = endOfIntegerPart++;
    while(displayValueX[++slashPos] != '/') {
    }
    displayValueX[slashPos++] = 0;
    int32ToReal34(stringToInt32(displayValueX + endOfIntegerPart), &numerator);
    int32ToReal34(stringToInt32(displayValueX + slashPos), &denominator);
    real34Divide(&numerator, &denominator, &numerator);
    if(displayValueX[0] == '-') {
      real34Subtract(REGISTER_REAL34_DATA(REGISTER_X), &numerator, REGISTER_REAL34_DATA(REGISTER_X));
    }
    else {
      real34Add(REGISTER_REAL34_DATA(REGISTER_X), &numerator, REGISTER_REAL34_DATA(REGISTER_X));
    }
  }
  else {
    stringToReal34(displayValueX, REGISTER_REAL34_DATA(REGISTER_X));
  }
}



void roundCplx(void) {
  int32_t pos, posI;
  bool_t polar = false;

  updateDisplayValueX = true;
  displayValueX[0] = 0;
  refreshRegisterLine(REGISTER_X);
  updateDisplayValueX = false;

  posI = DISPLAY_VALUE_LEN - 1;
  pos = 0;
  while(displayValueX[pos] != 0) {
    if(displayValueX[pos] == 'i') {
      posI = pos;
      break;
    }
    pos++;
  }

  if(posI == DISPLAY_VALUE_LEN - 1) {
    pos = 0;
    while(displayValueX[pos] != 0) {
      if(displayValueX[pos] == 'j') {
        posI = pos;
        polar = true;
        break;
      }
      pos++;
    }
  }

  displayValueX[posI++] = 0;
  if(polar) {
    real_t magnitude, theta;

    stringToReal(displayValueX,        &magnitude, &ctxtReal39);
    stringToReal(displayValueX + posI, &theta,     &ctxtReal39);
    realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &ctxtReal39);
    realToReal34(&magnitude, REGISTER_REAL34_DATA(REGISTER_X));
    realToReal34(&theta,     REGISTER_IMAG34_DATA(REGISTER_X));
  }
  else {
    stringToReal34(displayValueX,        REGISTER_REAL34_DATA(REGISTER_X));
    stringToReal34(displayValueX + posI, REGISTER_IMAG34_DATA(REGISTER_X));
  }
}
