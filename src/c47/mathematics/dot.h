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
 * \file dot.h
 ***********************************************/
#if !defined(DOT_H)
  #define DOT_H

  #include "realType.h"
  #include <stdint.h>

  void fnDot(uint16_t unusedButMandatoryParameter);

  void dotRealCplx(void);
  void dotLonICplx(void);
  void dotShoICplx(void);
  void dotCplxCplx(void);
  void dotCplxReal(void);
  void dotCplxLonI(void);
  void dotCplxShoI(void);

  void dotRemaRema(void);
  void dotCpmaRema(void);
  void dotRemaCpma(void);
  void dotCpmaCpma(void);

  void dotCplx    (const real_t *xReal, const real_t *xImag, const real_t *yReal, const real_t *yImag, real_t *rReal, realContext_t *realContext);
#endif // !DOT_H
