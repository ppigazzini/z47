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
 * \file changeSign.c
 ***********************************************/

#include "mathematics/changeSign.h"

#include "debug.h"
#include "error.h"
#include "flags.h"
#include "integers.h"
#include "items.h"
#include "mathematics/matrix.h"
#include "registers.h"
#include "registerValueConversions.h"

#include "c47.h"

static void chsLonI(void) {
  longInteger_t x;

  if(!getRegisterAsLongInt(REGISTER_X, x, NULL))
    return;

  longIntegerChangeSign(x);
  convertLongIntegerToLongIntegerRegister(x, REGISTER_X);
  longIntegerFree(x);
}

static void chsShoI(void) {
  *(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)) = WP34S_intChs(*(REGISTER_SHORT_INTEGER_DATA(REGISTER_X)));
}

static void chsZeroCheck(real_t *a) {
  realChangeSign(a);
  if(realIsZero(a) && !getSystemFlag(FLAG_SPCRES))
    realSetPositiveSign(a);
}

void chsReal(void) {
  real_t x;
  angularMode_t mode = amNone;

  if(!getRegisterAsReal(REGISTER_X, &x))
    return;

  if(getRegisterDataType(REGISTER_X) == dtReal34)
    mode = getRegisterAngularMode(REGISTER_X);

  chsZeroCheck(&x);
  convertRealToResultRegister(&x, REGISTER_X, mode);
}

void chsCplx(void) {
  real_t a, b;

  if(getRegisterAsComplex(REGISTER_X, &a, &b)) {
    chsZeroCheck(&a);
    chsZeroCheck(&b);
    convertComplexToResultRegister(&a, &b, REGISTER_X);
  }
}

/********************************************//**
 * \brief rexX ==> regL and -regX ==> regX
 * Drops Y, enables stack lift and refreshes the stack
 *
 * \param[in] unusedButMandatoryParameter uint16_t
 * \return void
 ***********************************************/
void fnChangeSign(uint16_t unusedButMandatoryParameter) {
  processIntRealComplexMonadicFunction(&chsReal, &chsCplx, &chsShoI, &chsLonI);
}
