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
 * \file percentT.h
 ***********************************************/
#if !defined(PERCENTT_H)
  #define PERCENTT_H

  #include <stdint.h>

  void fnPercentT(uint16_t unusedButMandatoryParameter);

  void percentTLonILonI(void);
  void percentTLonIReal(void);
  void percentTRealLonI(void);
  void percentTRealReal(void);
#endif // !PERCENTT_H
