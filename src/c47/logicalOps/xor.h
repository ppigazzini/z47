// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file xor.h
 ***********************************************/
#if !defined(XOR_H)
  #define XOR_H

  void fnLogicalXor(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void xorError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define xorError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void xorError31  (void);
  void xorLonILonI (void);
  void xorLonIReal (void);
  void xorRealLonI (void);
  void xorRealReal (void);
  void xorShoIShoI (void);
#endif // !XOR_H
