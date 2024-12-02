// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gcd.h
 ***********************************************/
#if !defined(GCD_H)
  #define GCD_H

  #include "defines.h"
  #include <stdint.h>

  void fnGcd      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void gcdError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define gcdError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  //      RegYRegX
  void gcdLonILonI(void);
  void gcdLonIShoI(void);
  void gcdShoILonI(void);
  void gcdShoIShoI(void);
#endif // !GCD_H
