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
 * \file fib.h
 ***********************************************/
#if !defined(FIB_H)
  #define FIB_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnFib   (uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void fibError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define fibError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void fibLonI (void);
  void fibReal (void);
  void fibCplx (void);

  uint8_t FibonacciReal(const real_t *n, real_t *res, realContext_t *realContext);
  uint8_t FibonacciComplex(const real_t *nReal, const real_t *nImag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#endif // !FIB_H
