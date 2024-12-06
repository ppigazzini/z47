// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file nand.h
 ***********************************************/
#if !defined(NAND_H)
  #define NAND_H

  void fnLogicalNand(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void nandError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define nandError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void nandError31  (void);
  void nandLonILonI (void);
  void nandLonIReal (void);
  void nandRealLonI (void);
  void nandRealReal (void);
  void nandShoIShoI (void);
#endif // !NAND_H
