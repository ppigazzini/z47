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
 * \file logxy.h
 ***********************************************/
#if !defined(LOGXY_H)
  #define LOGXY_H

  #include "defines.h"
  #include <stdint.h>

  void fnLogXY   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void logxyError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define logxyError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void logxyLonILonI(void);
  void logxyRealLonI(void);
  void logxyCplxLonI(void);
  void logxyRemaLonI(void);
  void logxyCxmaLonI(void);
  void logxyShoILonI(void);

  void logxyLonIReal(void);
  void logxyRealReal(void);
  void logxyCplxReal(void);
  void logxyRemaReal(void);
  void logxyCxmaReal(void);
  void logxyShoIReal(void);

  void logxyLonICplx(void);
  void logxyRealCplx(void);
  void logxyCplxCplx(void);
  void logxyRemaCplx(void);
  void logxyCxmaCplx(void);
  void logxyShoICplx(void);

  void logxyLonIShoI(void);
  void logxyRealShoI(void);
  void logxyCplxShoI(void);
  void logxyRemaShoI(void);
  void logxyCxmaShoI(void);
  void logxyShoIShoI(void);
#endif // !LOGXY_H
