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
 * \file gamma.h
 ***********************************************/
#if !defined(GAMMA_H)
  #define GAMMA_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnGamma     (uint16_t unusedButMandatoryParameter);
  void fnLnGamma   (uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void gammaError  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define gammaError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void lnGammaError(void);

  void gammaLonI   (void);
  void gammaReal   (void);
  void gammaCplx   (void);

  void lnGammaLonI (void);
  void lnGammaReal (void);
  void lnGammaCplx (void);

  void complexLnGamma(const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);

#endif // !GAMMA_H
