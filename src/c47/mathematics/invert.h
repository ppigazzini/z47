// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file invert.h
 ***********************************************/
#if !defined(INVERT_H)
  #define INVERT_H

  void fnInvert   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void invertError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define invertError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void invertLonI (void);
  void invertRema (void);
  void invertCxma (void);
  void invertReal (void);
  void invertCplx (void);
#endif // !INVERT_H
