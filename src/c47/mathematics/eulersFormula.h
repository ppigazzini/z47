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

#if !defined(EULERSFORMULA_H)
#define EULERSFORMULA_H

#include "defines.h"
#include "realType.h"
#include <stdint.h>

void fnEulersFormula(uint16_t unusedButMandatoryParameter);

#if(EXTRA_INFO_ON_CALC_ERROR == 1)
void eulersFormulaError  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
#define eulersFormulaError typeError
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

void eulersFormulaCplx       (void);
void eulersFormulaReal       (void);
void eulersFormulaLongint    (void);
void eulersFormulaRema       (void);
void eulersFormulaCxma       (void);

void eulersFormula(const real_t *inReal, const real_t *inImag, real_t *outReal, real_t *outImag, realContext_t *ctxt);

#endif // !EULERSFORMULA_H
