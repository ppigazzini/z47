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

/**
 * \file mathematics/sqrt1Px2.h
 */
#if !defined(SQRT1PX2_H)
  #define SQRT1PX2_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnSqrt1Px2   (uint16_t unusedButMandatoryParameter);

  void sqrt1Px2Complex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#endif // !SQRT1PX2_H
