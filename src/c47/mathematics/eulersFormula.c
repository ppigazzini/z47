/* This file is part of C43.
 *
 * C43 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * C43 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with C43.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file eulersFormula.c
 ***********************************************/

#include "mathematics/eulersFormula.h"

#include "constantPointers.h"
#include "conversionAngles.h"
#include "debug.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "items.h"
#include "matrix.h"
#include "registers.h"
#include "realType.h"
#include "registerValueConversions.h"
#include "mathematics/multiplication.h"
#include "mathematics/exp.h"
#include "c43Extensions/radioButtonCatalog.h"

#include "c47.h"

void eulersFormula(const real_t *inReal, const real_t *inImag, real_t *outReal, real_t *outImag, realContext_t *ctxt) {
  real_t zReal, zImag;

  mulComplexi(inReal, inImag, &zReal, &zImag);
  expComplex(&zReal, &zImag, outReal, outImag, ctxt);
}

static void eulersFormulaCplx(void) {
  real_t zReal, zImag;

  if (!getRegisterAsComplex(REGISTER_X, &zReal, &zImag))
    return;

  if( (realIsInfinite(&zReal) || (real34IsInfinite(&zImag))) ) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function eulersFormulaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as real or imag X input when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    convertComplexToResultRegister(const_NaN, const_NaN, REGISTER_X);
    goto end;
  }

  eulersFormula(&zReal, &zImag, &zReal, &zImag, &ctxtReal39);
  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);

end:
  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
}

static void eulersFormulaReal(void) {
  real_t c, i;
  angularMode_t xAngularMode;
  const uint32_t type = getRegisterDataType(REGISTER_X);

  if (!getRegisterAsReal(REGISTER_X, &c))
    return;

  if(realIsInfinite(&c) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function eulersFormulaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  if (type == dtReal34) {
    xAngularMode = getRegisterAngularMode(REGISTER_X);
    if (xAngularMode != amNone)
      convertAngleFromTo(&c, xAngularMode, amRadian, &ctxtReal39);
  }

  eulersFormula(&c, const_0, &c, &i, &ctxtReal39);

  convertComplexToResultRegister(&c, &i, REGISTER_X);
  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
}

void fnEulersFormula(uint16_t unusedButMandatoryParameter) {
  processRealComplexMonadicFunction(&eulersFormulaReal, &eulersFormulaCplx);
}
