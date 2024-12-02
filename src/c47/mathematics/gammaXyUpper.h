// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gammaXyUpper.h
 ***********************************************/
#if !defined(GAMMAXYUPPER_H)
  #define GAMMAXYUPPER_H

  #include "defines.h"
  #include <stdint.h>

  void fnGammaXyUpper      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void gammaXyUpperError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define gammaXyUpperError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void gammaXyUpperLonILonI(void);
  void gammaXyUpperLonIReal(void);
  void gammaXyUpperRealLonI(void);
  void gammaXyUpperRealReal(void);
#endif // !GAMMAXYUPPER_H
