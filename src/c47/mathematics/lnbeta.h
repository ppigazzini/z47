// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file lnbeta.h
 ***********************************************/
#if !defined(LNBETA_H)
  #define LNBETA_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnLnBeta      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void lnbetaError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define lnbetaError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void lnbetaLonILonI(void);
  void lnbetaRealLonI(void);
  void lnbetaCplxLonI(void);

  void lnbetaLonIReal(void);
  void lnbetaRealReal(void);
  void lnbetaCplxReal(void);

  void lnbetaLonICplx(void);
  void lnbetaRealCplx(void);
  void lnbetaCplxCplx(void);

  void LnBeta(const real_t *x, const real_t *y, real_t *res, realContext_t *realContext);
#endif // !LNBETA_H
