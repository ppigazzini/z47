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
 * \file idivr.h
 ***********************************************/
#if !defined(IDIVR_H)
  #define IDIVR_H

  #include "defines.h"
  #include <stdint.h>

  void fnIDivR(uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void idivrError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define idivrError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  //      RegYRegX
  void idivrLonILonI(void);
  void idivrLonIShoI(void);
  void idivrLonIReal(void);

  //      RegYRegX
  void idivrShoILonI(void);
  void idivrShoIShoI(void);
  void idivrShoIReal(void);

  //      RegYRegX
  void idivrRealLonI(void);
  void idivrRealShoI(void);
  void idivrRealReal(void);
#endif // !IDIVR_H
