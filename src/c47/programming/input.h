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
 * \file input.h
 ***********************************************/
#if !defined(INPUT_H)
  #define INPUT_H

  #include <stdint.h>

  void fnInput  (uint16_t regist);
  void fnVarMnu (uint16_t label);
  void fnPause  (uint16_t duration);
  void fnKey    (uint16_t regist);
  void fnKeyType(uint16_t regist);
  void fnPutKey (uint16_t regist);
  void fnEntryQ (uint16_t unusedButMandatoryParameter);
#endif // !INPUT_H
