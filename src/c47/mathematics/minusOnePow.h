// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file minusOnePow.h
 ***********************************************/
#if !defined(MINUSONEPOW_H)
  #define MINUSONEPOW_H

  void fnM1Pow   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void m1PowError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define m1PowError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void m1PowLonI (void);
  void m1PowRema (void);
  void m1PowCxma (void);
  void m1PowShoI (void);
  void m1PowReal (void);
  void m1PowCplx (void);
#endif // !MINUSONEPOW_H
