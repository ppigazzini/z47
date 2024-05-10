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
 * \file remainder.c
 ***********************************************/

#include "mathematics/remainder.h"

#include "debug.h"
#include "error.h"
#include "mathematics/wp34s.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

/******************************************************************************************************************************************************************************************/
/* long integer rmd ...                                                                                                                                                                     */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(long integer) rmd X(long integer) ==> X(long integer)
 *
 * \param void
 * \return void
 ***********************************************/
static void rmdLonI(void) {
  longInteger_t x, y, remainder;

  if(!getRegisterAsLongInt(REGISTER_X, x)
    || !getRegisterAsLongInt(REGISTER_Y, y))
  return;

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function rmdLonI:", "cannot IDIVR a long integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    longIntegerInit(remainder);
    longIntegerDivideRemainder(y, x, remainder);

    convertLongIntegerToLongIntegerRegister(remainder, REGISTER_X);

    longIntegerFree(y);
    longIntegerFree(remainder);
  }

  longIntegerFree(x);
}

/******************************************************************************************************************************************************************************************/
/* short integer rmd ...                                                                                                                                                                    */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(short integer) rmd X(short integer) ==> X(short integer)
 *
 * \param void
 * \return void
 ***********************************************/
static void rmdShoI(void) {
  longInteger_t x, y, remainder;
    uint32_t baseY;

  if(!getRegisterAsLongInt(REGISTER_X, x)
    || !getRegisterAsLongInt(REGISTER_Y, y))
  return;

  if(longIntegerIsZero(x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function rmdLonILonI:", "cannot IDIVR a short integer by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
  }
  else {
    baseY = getRegisterShortIntegerBase(REGISTER_Y);

    longIntegerInit(remainder);
    longIntegerDivideRemainder(y, x, remainder);

    convertLongIntegerToShortIntegerRegister(remainder, baseY, REGISTER_X);

    longIntegerFree(y);
    longIntegerFree(remainder);
  }

  longIntegerFree(x);

}

/******************************************************************************************************************************************************************************************/
/* real34 rmd ...                                                                                                                                                                           */
/******************************************************************************************************************************************************************************************/

/********************************************//**
 * \brief Y(real34) rmd X(real34) ==> X(real34)
 *
 * \param void
 * \return void
 ***********************************************/
static void rmdReal(void) {
  real_t x, y;

  if(!getRegisterAsReal(REGISTER_X, &x) || !getRegisterAsReal(REGISTER_Y, &y))
    return;

  if(realIsZero(&x)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function rmdReal:", "cannot IDIVR a real34 by 0", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  WP34S_Mod(&y, &x, &x, &ctxtReal39);
  convertRealToResultRegister(&x, REGISTER_X, amNone);
}

/********************************************//**
 * \brief regX ==> regL and regY rmd regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter
 * \return void
 ***********************************************/
void fnRmd(uint16_t unusedButMandatoryParameter) {
  processIntRealComplexDyadicFunction(&rmdReal, NULL, &rmdShoI, &rmdLonI);
}
