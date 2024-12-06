// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file fractionalPart.h
 ***********************************************/
#if !defined(FRACTIONALPART_H)
  #define FRACTIONALPART_H

  void fnFp   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void fpError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define fpError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void fpLonI (void);
  void fpRema (void);
  void fpShoI (void);
  void fpReal (void);
#endif // !FRACTIONALPART_H
