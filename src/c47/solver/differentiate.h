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
 * \file differentiate.h
 ***********************************************/
#if !defined(DIFFERENTIATE_H)
  #define DIFFERENTIATE_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  void fn1stDeriv      (uint16_t label);
  void fn2ndDeriv      (uint16_t label);
  void fn1stDerivEq    (uint16_t unusedButMandatoryParameter);
  void fn2ndDerivEq    (uint16_t unusedButMandatoryParameter);

  void firstDerivative (calcRegister_t label);
  void secondDerivative(calcRegister_t label);
#endif // !DIFFERENTIATE_H
