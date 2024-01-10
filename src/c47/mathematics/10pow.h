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
 * \file 10pow.h
 ***********************************************/
#if !defined(FILE_10POW_H)
  #define FILE_10POW_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fn10Pow    (uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void tenPowError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define tenPowError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void tenPowLonI (void);
  void tenPowRema (void);
  void tenPowCxma (void);
  void tenPowShoI (void);
  void tenPowReal (void);
  void tenPowCplx (void);

  void realPower10(const real_t *x, real_t *res, realContext_t *realContext);
#endif // !FILE_10POW_H
