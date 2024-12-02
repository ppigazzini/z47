// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file 10pow.h
 ***********************************************/
#if !defined(FILE_10POW_H)
  #define FILE_10POW_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fn10Pow    (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void tenPowError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define tenPowError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void tenPowLonI (void);
  void tenPowRema (void);
  void tenPowCxma (void);
  void tenPowShoI (void);
  void tenPowReal (void);
  void tenPowCplx (void);

  void realPower10(const real_t *x, real_t *res, realContext_t *realContext);
#endif // !FILE_10POW_H
