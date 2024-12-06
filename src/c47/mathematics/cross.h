// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file cross.h
 ***********************************************/
#if !defined(CROSS_H)
  #define CROSS_H

  void fnCross(uint16_t unusedButMandatoryParameter);

  void crossRealCplx(void);
  void crossLonICplx(void);
  void crossShoICplx(void);
  void crossCplxCplx(void);
  void crossCplxReal(void);
  void crossCplxLonI(void);
  void crossCplxShoI(void);

  void crossRemaRema(void);
  void crossCpmaRema(void);
  void crossRemaCpma(void);
  void crossCpmaCpma(void);
#endif // !CROSS_H
