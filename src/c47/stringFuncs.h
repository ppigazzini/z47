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

/**
 * \file stringFuncs.h
 */
#if !defined(STRINGFUNCS_H)
  #define STRINGFUNCS_H

  #include <stdint.h>

  void fnAlphaLeng(uint16_t regist);
  void fnAlphaToX (uint16_t regist);
  void fnAlphaRR  (uint16_t regist);
  void fnAlphaRL  (uint16_t regist);
  void fnAlphaSR  (uint16_t regist);
  void fnAlphaSL  (uint16_t regist);
  void fnAlphaPos (uint16_t regist);
  void fnXToAlpha (uint16_t unusedButMandatoryParameter);
  void fnIsString (uint16_t unusedButMandatoryParameter);
#endif // !STRINGFUNCS_H
