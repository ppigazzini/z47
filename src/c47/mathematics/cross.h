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
 * \file cross.h
 ***********************************************/
#if !defined(CROSS_H)
  #define CROSS_H

  #include <stdint.h>

  void fnCross(uint16_t unusedButMandatoryParameter);

  void crossRealCplx(void);
  void crossLonICplx(void);
  void crossShoICplx(void);
  void crossCplxCplx(void);
  void crossCplxReal(void);
  void crossCplxLonI(void);
  void crossCplxShoI(void);

  void crossRemaRema(void);
  void crossCpmaRema(void);
  void crossRemaCpma(void);
  void crossCpmaCpma(void);
#endif // !CROSS_H
