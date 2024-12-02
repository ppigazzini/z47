// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file 2pow.h
 ***********************************************/
#if !defined(FILE_2POW_H)
  #define FILE_2POW_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fn2Pow     (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void twoPowError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define twoPowError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void twoPowLonI (void);
  void twoPowRema (void);
  void twoPowCxma (void);
  void twoPowShoI (void);
  void twoPowReal (void);
  void twoPowCplx (void);

  void realPower2 (const real_t *x, real_t *res, realContext_t *realContext);
#endif // !FILE_2POW_H
