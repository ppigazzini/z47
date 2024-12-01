// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file mathematics/log10.h
 */
#if !defined(LOG10_H)
  #define LOG10_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void   fnLog10   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void   log10Error(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define log10Error typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void   log10LonI (void);
  void   log10Rema (void);
  void   log10Cxma (void);
  void   log10ShoI (void);
  void   log10Real (void);
  void   log10Cplx (void);

  void   realLog10 (const real_t *x, real_t *res, realContext_t *realContext);

#endif // !LOG10_H
