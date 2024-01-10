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
 * \file toPolar.h
 ***********************************************/
#if !defined(TOPOLAR_H)
  #define TOPOLAR_H

  #include "realType.h"
  #include <stdint.h>

  void fnToPolar2              (uint16_t unusedButMandatoryParameter);
  void fnToPolar               (uint16_t unusedButMandatoryParameter);
  void real34RectangularToPolar(const real34_t *real34, const real34_t *imag34, real34_t *magnitude34, real34_t *theta34);
  void realRectangularToPolar  (const real_t   *real,   const real_t   *imag,   real_t   *magnitude,   real_t   *theta,  realContext_t *realContext);
#endif // !TOPOLAR_H
