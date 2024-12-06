// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gammaQ.h
 ***********************************************/
#if !defined(GAMMAQ_H)
  #define GAMMAQ_H

  void fnGammaQ      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void gammaQError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define gammaQError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void gammaQLonILonI(void);
  void gammaQLonIReal(void);
  void gammaQRealLonI(void);
  void gammaQRealReal(void);
#endif // !GAMMAQ_H
