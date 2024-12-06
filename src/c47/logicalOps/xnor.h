// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file xnor.h
 ***********************************************/
#if !defined(XNOR_H)
  #define XNOR_H

  void fnLogicalXnor(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void xnorError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define xnorError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void xnorError31  (void);
  void xnorLonILonI (void);
  void xnorLonIReal (void);
  void xnorRealLonI (void);
  void xnorRealReal (void);
  void xnorShoIShoI (void);
#endif // !XNOR_H
