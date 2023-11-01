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
 * \file tan.h
 ***********************************************/
#if !defined(TAN_H)
  #define TAN_H

  #include "defines.h"
  #include "realType.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  void fnTan                    (uint16_t unusedButMandatoryParameter);
  void longIntegerAngleReduction(calcRegister_t regist, angularMode_t angularMode, real_t *reducedAngle);
  angularMode_t determineAngleMode(angularMode_t mode);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void tanError                 (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define tanError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void tanLonI                  (void);
  void tanRema                  (void);
  void tanCxma                  (void);
  void tanReal                  (void);
  void tanCplx                  (void);

  uint8_t TanComplex(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);
#endif // !TAN_H
