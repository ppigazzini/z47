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
 * \file multiplication.h
 ***********************************************/
#if !defined(MULTIPLICATION_H)
  #define MULTIPLICATION_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnMultiply (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void mulError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define mulError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void mulComplexi(const real_t *inReal, const real_t *inImag, real_t *productReal, real_t *productImag);
  void mulComplexComplex(const real_t *factor1Real, const real_t *factor1Imag, const real_t *factor2Real, const real_t *factor2Imag, real_t *productReal, real_t *productImag, realContext_t *realContext);
  void mulComplexReal(const real_t *factor1Real, const real_t *factor1Imag, const real_t *factor2, real_t *productReal, real_t *productImag, realContext_t *realContext);

  //      RegYRegX
  void mulLonILonI(void);
  void mulLonITime(void);
  void mulLonIRema(void);
  void mulLonICxma(void);
  void mulLonIShoI(void);
  void mulLonIReal(void);
  void mulLonICplx(void);

  //      RegYRegX
  void mulTimeLonI(void);
  void mulTimeShoI(void);
  void mulTimeReal(void);

  //      RegYRegX
  void mulRemaLonI(void);
  void mulRemaRema(void);
  void mulRemaCxma(void);
  void mulRemaShoI(void);
  void mulRemaReal(void);
  void mulRemaCplx(void);

  //      RegYRegX
  void mulCxmaLonI(void);
  void mulCxmaRema(void);
  void mulCxmaCxma(void);
  void mulCxmaShoI(void);
  void mulCxmaReal(void);
  void mulCxmaCplx(void);

  //      RegYRegX
  void mulShoILonI(void);
  void mulShoITime(void);
  void mulShoIRema(void);
  void mulShoICxma(void);
  void mulShoIShoI(void);
  void mulShoIReal(void);
  void mulShoICplx(void);

  //      RegYRegX
  void mulRealLonI(void);
  void mulRealTime(void);
  void mulRealRema(void);
  void mulRealCxma(void);
  void mulRealShoI(void);
  void mulRealReal(void);
  void mulRealCplx(void);

  //      RegYRegX
  void mulCplxLonI(void);
  void mulCplxRema(void);
  void mulCplxCxma(void);
  void mulCplxShoI(void);
  void mulCplxReal(void);
  void mulCplxCplx(void);
#endif // !MULTIPLICATION_H
