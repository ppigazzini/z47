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
 * \file iteration.h
 ***********************************************/
#if !defined(ITERATION_H)
  #define ITERATION_H

  #include <stdint.h>

  void fnIse(uint16_t regist);
  void fnIsg(uint16_t regist);
  void fnIsz(uint16_t regist);
  void fnDse(uint16_t regist);
  void fnDsl(uint16_t regist);
  void fnDsz(uint16_t regist);
#endif // !ITERATION_H
