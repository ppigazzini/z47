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
 * \file rdp.c
 ***********************************************/

#include "mathematics/rdp.h"

#include "config.h"
#include "constantPointers.h"
#include "conversionAngles.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "items.h"
#include "mathematics/comparisonReals.h"
#include "mathematics/matrix.h"
#include "mathematics/rsd.h"
#include "mathematics/toPolar.h"
#include "mathematics/toRect.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"

#include "c47.h"



TO_QSPI void (* const Rdp[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(uint16_t) = {
// regX ==> 1            2        3         4        5         6         7          8           9             10
//          Long integer Real34   Complex34 Time     Date      String    Real34 mat Complex34 m Short integer Config data
            rdpError,    rdpReal, rdpCplx,  rdpTime, rdpError, rdpError, rdpRema,   rdpCxma,    rdpError,     rdpError
};



/********************************************//**
 * \brief calculate RDP
 *
 * \param[in] source real_t*
 * \param[out] destination real_t*
 * \param[in] realContext realContext_t*
 * \param[in] digits uint16_t
 * \return void
 ***********************************************/
void roundToDecimalPlace(const real_t *source, real_t *destination, uint16_t digits, realContext_t *realContext) {
  real_t val, tmp;
  int32_t exponent;

  if(realIsZero(source) || realIsSpecial(source)) {
    realCopy(source, destination);
    return;
  }

  realCopy(source, &val);
  exponent = val.digits + val.exponent - 1;
  val.exponent -= exponent;
  while(1) { // in case of subnormal
    realCopy(&val, &tmp);
    if(realCompareAbsLessThan(&tmp, const_1)) {
      ++val.exponent;
      --exponent;
    }
    else {
      break;
    }
  }
  val.exponent += exponent;

  val.exponent += digits;
  realToIntegralValue(&val, &val, roundingModeTable[roundingMode], realContext);
  val.exponent -= digits;

  realCopy(&val, destination);
  return;
}



/********************************************//**
 * \brief Data type error in rdp
 *
 * \param unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void rdpError(uint16_t unusedButMandatoryParameter) {
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "cannot calculate RDP for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function rdpError:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}



/********************************************//**
 * \brief round to given significant digits
 *
 * \param[in] digits uint16_t
 * \return void
 ***********************************************/
void fnRdp(uint16_t digits) {
  if(!saveLastX()) {
    return;
  }

  Rdp[getRegisterDataType(REGISTER_X)](digits);

  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
}



void rdpTime(uint16_t digits) {
  real_t val;
  int32_t i;

  updateDisplayValueX = true;
  displayValueX[0] = 0;
  refreshRegisterLine(REGISTER_X);
  updateDisplayValueX = false;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &val);

  for(i = 0; i < 2; ++i){
    val.exponent -= 1;
    senaryDigitToDecimal(false, &val, &ctxtReal39);
    val.exponent -= 1;
  }
  roundToDecimalPlace(&val, &val, digits, &ctxtReal39);
  for(i = 0; i < 2; ++i){
    val.exponent += 1;
    decimalDigitToSenary(false, &val, &ctxtReal39);
    val.exponent += 1;
  }

  realToReal34(&val, REGISTER_REAL34_DATA(REGISTER_X));
}



void rdpRema(uint16_t digits) {
  elementwiseRema_UInt16(rdpReal, digits);
}



void rdpCxma(uint16_t digits) {
  elementwiseCxma_UInt16(rdpCplx, digits);
}



void rdpReal(uint16_t digits) {
  real_t val;

  if(getRegisterAngularMode(REGISTER_X) == amDMS) {
    real34FromDegToDms(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
    checkDms34(REGISTER_REAL34_DATA(REGISTER_X));
  }

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &val);
  roundToDecimalPlace(&val, &val, digits, &ctxtReal39);
  convertRealToReal34ResultRegister(&val, REGISTER_X);

  if(getRegisterAngularMode(REGISTER_X) == amDMS) {
    real34FromDmsToDeg(REGISTER_REAL34_DATA(REGISTER_X), REGISTER_REAL34_DATA(REGISTER_X));
  }
}
/*void rdpReal(uint16_t digits) {
  real_t val;
  int32_t i;

  updateDisplayValueX = true;
  displayValueX[0] = 0;
  refreshRegisterLine(REGISTER_X);
  updateDisplayValueX = false;

  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &val);

  if(getRegisterAngularMode(REGISTER_X) == amDMS) {
    for(i = 0; i < 2; ++i){
      val.exponent += 1;
      senaryDigitToDecimal(true, &val, &ctxtReal39);
      val.exponent += 1;
    }
    val.exponent -= 4;
  }
  roundToDecimalPlace(&val, &val, digits, &ctxtReal39);
  if(getRegisterAngularMode(REGISTER_X) == amDMS) {
    for(i = 0; i < 2; ++i){
      val.exponent += 1;
      decimalDigitToSenary(true, &val, &ctxtReal39);
      val.exponent += 1;
    }
    val.exponent -= 4;
    convertAngleFromTo(&val, amDMS, amDMS, &ctxtReal39);
  }

  convertRealToReal34ResultRegister(&val, REGISTER_X);
}*/



void rdpCplx(uint16_t digits) {
  if(getSystemFlag(FLAG_POLAR)) {
    real_t magnitude, theta;
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &magnitude);
    real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &theta);
    realRectangularToPolar(&magnitude, &theta, &magnitude, &theta, &ctxtReal39);
    roundToDecimalPlace(&magnitude, &magnitude, digits, &ctxtReal39);
    roundToDecimalPlace(&theta,     &theta,     digits, &ctxtReal39);
    realPolarToRectangular(&magnitude, &theta, &magnitude, &theta, &ctxtReal39);
    convertComplexToResultRegister(&magnitude, &theta, REGISTER_X);
  }
  else {
    real_t real, imaginary;
    real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &real);
    real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &imaginary);
    roundToDecimalPlace(&real,      &real,      digits, &ctxtReal39);
    roundToDecimalPlace(&imaginary, &imaginary, digits, &ctxtReal39);
    convertComplexToResultRegister(&real, &imaginary, REGISTER_X);
  }
}
