// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file or.h
 ***********************************************/
#if !defined(OR_H)
  #define OR_H

  void fnLogicalOr(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void orError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define orError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void orError31  (void);
  void orLonILonI (void);
  void orLonIReal (void);
  void orRealLonI (void);
  void orRealReal (void);
  void orShoIShoI (void);
#endif // !OR_H
