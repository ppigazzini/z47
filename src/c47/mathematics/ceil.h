// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file ceil.h
 ***********************************************/
#if !defined(CEIL_H)
  #define CEIL_H

  void fnCeil   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void ceilError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define ceilError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void ceilRema (void);
  void ceilReal (void);
#endif // !CEIL_H
