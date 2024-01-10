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
 * \file compare.h
 ***********************************************/
#if !defined(COMPARE_H)
  #define COMPARE_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  bool_t registerCmp       (calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpError   (calcRegister_t regist1, calcRegister_t regist2);
  void  registerCmpLonILonI(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpLonIShoI(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpLonIReal(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpTimeTime(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpDateDate(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpStriStri(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpShoILonI(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpShoIShoI(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpShoIReal(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpRealLonI(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpRealShoI(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerCmpRealReal(calcRegister_t regist1, calcRegister_t regist2, int8_t *result);
  void  registerMax        (calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest);
  void  registerMin        (calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest);

  void  fnXLessThan        (uint16_t regist);
  void  fnXLessEqual       (uint16_t regist);
  void  fnXGreaterThan     (uint16_t regist);
  void  fnXGreaterEqual    (uint16_t regist);
  void  fnXEqualsTo        (uint16_t regist);
  void  fnXNotEqual        (uint16_t regist);
  void  fnXAlmostEqual     (uint16_t regist);

  void  fnIsConverged      (uint16_t mode);
#endif // !COMPARE_H
