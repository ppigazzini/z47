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
 * \file magnitude.h
 ***********************************************/
#if !defined(MAGNITUDE_H)
  #define MAGNITUDE_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnMagnitude   (uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void magnitudeError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define magnitudeError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void magnitudeLonI (void);
  void magnitudeRema (void);
  void magnitudeCxma (void);
  void magnitudeShoI (void);
  void magnitudeReal (void);
  void magnitudeCplx (void);

  void complexMagnitude(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext);
  void complexMagnitude2(const real_t *a, const real_t *b, real_t *c, realContext_t *realContext);
#endif // !MAGNITUDE_H
