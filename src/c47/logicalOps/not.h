// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file not.h
 ***********************************************/
#if !defined(NOT_H)
  #define NOT_H

  void fnLogicalNot(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void notError    (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define notError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void notLonI     (void);
  void notShoI     (void);
  void notReal     (void);
#endif // !NOT_H
