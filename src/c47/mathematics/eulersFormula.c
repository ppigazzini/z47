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



TO_QSPI void (* const dispatch_eulersFormula[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void) = {
// regX ==> 1                     2                  3                  4                   5                   6                   7                   8                   9                   10
//          Long integer          Real34             complex34          Time                Date                String              Real34 mat          Complex34 m         Short integer       Config data
            eulersFormulaLongint, eulersFormulaReal, eulersFormulaCplx, eulersFormulaError, eulersFormulaError, eulersFormulaError, eulersFormulaRema,  eulersFormulaCxma,  eulersFormulaError, eulersFormulaError
};


#if(EXTRA_INFO_ON_CALC_ERROR == 1)
  void eulersFormulaError(void) {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
    sprintf(errorMessage, "cannot calculate e^ix for %s", getRegisterDataTypeName(REGISTER_X, true, false));
    moreInfoOnError("In function fnEulersFormula:", errorMessage, NULL, NULL);
  }
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)



void fnEulersFormula(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  dispatch_eulersFormula[getRegisterDataType(REGISTER_X)]();
}



void eulersFormulaRema(void) {
  elementwiseRema(eulersFormulaReal);
}



void eulersFormulaCxma(void) {
  elementwiseCxma(eulersFormulaCplx);
}



void eulersFormula(const real_t *inReal, const real_t *inImag, real_t *outReal, real_t *outImag, realContext_t *ctxt) {
  real_t zReal, zImag;

  mulComplexi(inReal, inImag, &zReal, &zImag);
  expComplex(&zReal, &zImag, outReal, outImag, ctxt);
}

void eulersFormulaCplx(void) {

  if( (real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X)) || (real34IsInfinite(REGISTER_IMAG34_DATA(REGISTER_X)))) ) {
    if(!getSystemFlag(FLAG_SPCRES)) {
      displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        moreInfoOnError("In function eulersFormulaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as real or imag X input when flag D is not set", NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    else {
      convertComplexToResultRegister(const_NaN, const_NaN, REGISTER_X);
      fnSetFlag(FLAG_CPXRES);
      fnRefreshState();
    }
  }

  real_t zReal, zImag;

  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &zReal);
  real34ToReal(REGISTER_IMAG34_DATA(REGISTER_X), &zImag);

  eulersFormula(&zReal, &zImag, &zReal, &zImag, &ctxtReal39);

  convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);

}


void eulersFormulaReal(void) {
  if((real34IsInfinite(REGISTER_REAL34_DATA(REGISTER_X))) && !getSystemFlag(FLAG_SPCRES)) {
    displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
    #if(EXTRA_INFO_ON_CALC_ERROR == 1)
      moreInfoOnError("In function eulersFormulaReal:", "cannot use " STD_PLUS_MINUS STD_INFINITY " as X input when flag D is not set", NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }

  real_t c, i;

  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
  if(getRegisterAngularMode(REGISTER_X) != amNone) {
    fnCvtFromCurrentAngularMode(amRadian);
    setRegisterAngularMode(REGISTER_X, amNone);
  }
  real34ToReal(REGISTER_REAL34_DATA(REGISTER_X), &c);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);

  eulersFormula(&c, const_0, &c, &i, &ctxtReal39);

  convertComplexToResultRegister(&c, &i, REGISTER_X);
}


void eulersFormulaLongint(void) {
  real_t c, i;

  fnSetFlag(FLAG_CPXRES);
  fnRefreshState();
  convertLongIntegerRegisterToReal(REGISTER_X, &c, &ctxtReal39);
  reallocateRegister(REGISTER_X, dtComplex34, COMPLEX34_SIZE_IN_BLOCKS, amNone);

  eulersFormula(&c, const_0, &c, &i, &ctxtReal39);

  convertComplexToResultRegister(&c, &i, REGISTER_X);
}
