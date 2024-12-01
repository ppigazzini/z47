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
 * \file checkValue.h
 ***********************************************/
#if !defined(CHECKVALUE_H)
  #define CHECKVALUE_H

  #include <stdint.h>

  void fnCheckValue   (uint16_t mode);
  void checkValueError(uint16_t unusedButMandatoryParameter);
  void checkValueLonI (uint16_t mode);
  void checkValueRema (uint16_t mode);
  void checkValueCxma (uint16_t mode);
  void checkValueShoI (uint16_t mode);
  void checkValueReal (uint16_t mode);
  void checkValueCplx (uint16_t mode);
#endif // !CHECKVALUE_H
