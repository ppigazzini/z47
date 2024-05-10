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
 * \file lnPOne.h
 ***********************************************/
#if !defined(LNPONE_H)
  #define LNPONE_H
  // Coded by JM, based on ln.h

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnLnP1   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void lnP1Error(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define lnP1Error typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void lnP1LonI (void);
  void lnP1Rema (void);
  void lnP1Cxma (void);
  void lnP1ShoI (void);
  void lnP1Real (void);
  void lnP1Cplx (void);
  void lnP1Complex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext);
#endif // !LNPONE_H
