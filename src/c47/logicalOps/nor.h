// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file nor.h
 ***********************************************/
#if !defined(NOR_H)
  #define NOR_H

  void fnLogicalNor(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void norError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define norError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void norError31  (void);
  void norLonILonI (void);
  void norLonIReal (void);
  void norRealLonI (void);
  void norRealReal (void);
  void norShoIShoI (void);
#endif // !NOR_H
