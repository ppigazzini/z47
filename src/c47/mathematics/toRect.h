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
 * \file toRect.h
 ***********************************************/
#if !defined(TORECT_H)
  #define TORECT_H

  #include "realType.h"
  #include <stdint.h>

  void fnToRect2               (uint16_t unusedButMandatoryParameter);
  void realPolarToRectangular  (const real_t *magnitude, const real_t *theta, real_t *real, real_t *imag, realContext_t *realContext);
  //void real34PolarToRectangular(const real34_t *magnitude34, const real34_t *theta34, real34_t *real34, real34_t *imag34); never used
#endif // !TORECT_H
