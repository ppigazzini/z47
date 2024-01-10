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
#if !defined(GD_H)
  #define GD_H

  #include "realType.h"
  #include <stdint.h>

  void fnGd   (uint16_t unusedButMandatoryParameter);
  void fnInvGd(uint16_t unusedButMandatoryParameter);

  void gdTypeError(uint16_t gdOrInvGd);
  void gdLonI (uint16_t gdOrInvGd);
  void gdReal (uint16_t gdOrInvGd);
  void gdCplx (uint16_t gdOrInvGd);

  uint8_t GudermannianReal(const real_t *x, real_t *res, realContext_t *realContext);
  uint8_t GudermannianComplex(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext);

  uint8_t InverseGudermannianReal(const real_t *x, real_t *res, realContext_t *realContext);
  uint8_t InverseGudermannianComplex(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#endif // !GD_H
