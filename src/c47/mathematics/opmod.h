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
 * \file opmod.h
 ***********************************************/
#if !defined(OPMOD_H)
  #define OPMOD_H

  #include "longIntegerType.h"
  #include <stdint.h>

  void fnMulMod          (uint16_t unusedButMandatoryParameter);
  void fnExpMod          (uint16_t unusedButMandatoryParameter);
  void fnOpMod           (uint16_t mode);
  void opModError        (uint16_t mode);

  void longInteger_mulmod(const longInteger_t a, int32_t exp_a, const longInteger_t b, int32_t exp_b, const longInteger_t c, int32_t exp_c, longInteger_t res, int32_t *exp_res);
  void longInteger_expmod(const longInteger_t a, const longInteger_t b, const longInteger_t c, longInteger_t res);

  //      RegZRegYRegX
  void opModLonILonILonI (uint16_t mode);
  void opModLonILonIShoI (uint16_t mode);
  void opModLonILonIReal (uint16_t mode);
  void opModLonIShoILonI (uint16_t mode);
  void opModLonIShoIShoI (uint16_t mode);
  void opModLonIShoIReal (uint16_t mode);
  void opModLonIRealLonI (uint16_t mode);
  void opModLonIRealShoI (uint16_t mode);
  void opModLonIRealReal (uint16_t mode);

  void opModShoILonILonI (uint16_t mode);
  void opModShoILonIShoI (uint16_t mode);
  void opModShoILonIReal (uint16_t mode);
  void opModShoIShoILonI (uint16_t mode);
  void opModShoIShoIShoI (uint16_t mode);
  void opModShoIShoIReal (uint16_t mode);
  void opModShoIRealLonI (uint16_t mode);
  void opModShoIRealShoI (uint16_t mode);
  void opModShoIRealReal (uint16_t mode);

  void opModRealLonILonI (uint16_t mode);
  void opModRealLonIShoI (uint16_t mode);
  void opModRealLonIReal (uint16_t mode);
  void opModRealShoILonI (uint16_t mode);
  void opModRealShoIShoI (uint16_t mode);
  void opModRealShoIReal (uint16_t mode);
  void opModRealRealLonI (uint16_t mode);
  void opModRealRealShoI (uint16_t mode);
  void opModRealRealReal (uint16_t mode);
#endif // !OPMOD_H
