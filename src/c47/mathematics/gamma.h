// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

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

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
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
