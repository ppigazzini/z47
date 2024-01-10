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
 * \file cpyx.h
 ***********************************************/
#if !defined(CPYX_H)
  #define CPYX_H

  #include "realType.h"
  #include <stdint.h>

  void fnCyx(uint16_t unusedButMandatoryParameter);
  void fnPyx(uint16_t unusedButMandatoryParameter);

  void logCyxReal(real_t *y, real_t *x, real_t *result, realContext_t *realContext);

  /*
   * When combOrPerm == CP_COMBINATION => Cyx
   *      combOrPerm == CP_PERMUTATION => Pyx
   */
  void cpyxLonILonI(uint16_t combOrPerm);
  void cpyxLonIReal(uint16_t combOrPerm);
  void cpyxLonICplx(uint16_t combOrPerm);
  void cpyxLonIShoI(uint16_t combOrPerm);

  void cpyxRealLonI(uint16_t combOrPerm);
  void cpyxRealReal(uint16_t combOrPerm);
  void cpyxRealCplx(uint16_t combOrPerm);
  void cpyxRealShoI(uint16_t combOrPerm);

  void cpyxCplxLonI(uint16_t combOrPerm);
  void cpyxCplxReal(uint16_t combOrPerm);
  void cpyxCplxCplx(uint16_t combOrPerm);
  void cpyxCplxShoI(uint16_t combOrPerm);

  void cpyxShoILonI(uint16_t combOrPerm);
  void cpyxShoIReal(uint16_t combOrPerm);
  void cpyxShoICplx(uint16_t combOrPerm);
  void cpyxShoIShoI(uint16_t combOrPerm);
#endif // !CPYX_H
