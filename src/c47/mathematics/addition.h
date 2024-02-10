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
 * \file addition.h
 ***********************************************/
#if !defined(ADDITION_H)
#define ADDITION_H

#include "defines.h"
#include "realType.h"
#include <stdint.h>

void fnAdd      (uint16_t unusedButMandatoryParameter);
void addComplex(const real_t *aReal, const real_t *aImag, const real_t *bReal, const real_t *bImag, real_t *resReal, real_t *resImag, realContext_t *realContext);

#if(EXTRA_INFO_ON_CALC_ERROR == 1)
void addError   (void);
#else // (EXTRA_INFO_ON_CALC_ERROR == 1)
#define addError typeError
#endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

//      RegYRegX
void addLonILonI(void);
  void addLonIRema(void);
  void addLonICxma(void);
void addLonITime(void);
void addLonIDate(void);
void addLonIShoI(void);
void addLonIReal(void);
void addLonICplx(void);

//      RegYRegX
void addTimeLonI(void);
void addTimeTime(void);
void addTimeReal(void);

//      RegYRegX
void addDateLonI(void);
void addDateReal(void);

//      RegYRegX
void addStriLonI(void);
void addStriTime(void);
void addStriStri(void);
void addStriRema(void);
void addStriCxma(void);
void addStriDate(void);
void addStriShoI(void);
void addStriReal(void);
void addStriCplx(void);
void addRegYStri(void);   //JM

//      RegYRegX
  void addRemaLonI(void);
void addRemaRema(void);
void addRemaCxma(void);
  void addRemaShoI(void);
  void addRemaReal(void);
  void addRemaCplx(void);

//      RegYRegX
  void addCxmaLonI(void);
void addCxmaRema(void);
void addCxmaCxma(void);
  void addCxmaShoI(void);
  void addCxmaReal(void);
  void addCxmaCplx(void);

//      RegYRegX
void addShoILonI(void);
  void addShoIRema(void);
  void addShoICxma(void);
void addShoIShoI(void);
void addShoIReal(void);
void addShoICplx(void);

//      RegYRegX
void addRealLonI(void);
  void addRealRema(void);
  void addRealCxma(void);
void addRealTime(void);
void addRealDate(void);
void addRealShoI(void);
void addRealReal(void);
void addRealCplx(void);

//      RegYRegX
void addCplxLonI(void);
  void addCplxRema(void);
  void addCplxCxma(void);
void addCplxShoI(void);
void addCplxReal(void);
void addCplxCplx(void);
#endif // !ADDITION_H
