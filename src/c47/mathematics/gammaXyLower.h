// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gammaXyLower.h
 ***********************************************/
#if !defined(GAMMAXYLOWER_H)
  #define GAMMAXYLOWER_H

  void fnGammaXyLower      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void gammaXyLowerError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define gammaXyLowerError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void gammaXyLowerLonILonI(void);
  void gammaXyLowerLonIReal(void);
  void gammaXyLowerRealLonI(void);
  void gammaXyLowerRealReal(void);
#endif // !GAMMAXYLOWER_H
