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
 * \file exp.h
 ***********************************************/
#if !defined(EXP_H)
  #define EXP_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnExp   (uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void expError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define expError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void expLonI (void);
  void expRema (void);
  void expCxma (void);
  void expShoI (void);
  void expReal (void);
  void expCplx (void);
  void expComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#endif // !EXP_H
