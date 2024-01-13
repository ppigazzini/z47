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
 * \file arcsinh.h
 ***********************************************/
#if !defined(ARCSINH_H)
  #define ARCSINH_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnArcsinh   (uint16_t unusedButMandatoryParameter);

  uint8_t ArcsinhReal(const real_t *x, real_t *res, realContext_t *realContext);
  uint8_t ArcsinhComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#endif // !ARCSINH_H
