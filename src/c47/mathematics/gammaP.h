// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file gammaP.h
 ***********************************************/
#if !defined(GAMMAP_H)
  #define GAMMAP_H

  void fnGammaP      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void gammaPError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define gammaPError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void gammaPLonILonI(void);
  void gammaPLonIReal(void);
  void gammaPRealLonI(void);
  void gammaPRealReal(void);
#endif // !GAMMAP_H
