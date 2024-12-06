// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file factorial.h
 ***********************************************/
#if !defined(FACTORIAL_H)
  #define FACTORIAL_H

  void fnFactorial(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void factError  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define factError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void factLonI   (void);
  void factShoI   (void);
  void factReal   (void);
  void factCplx   (void);

  uint64_t fact_uint64(uint64_t value);
#endif // !FACTORIAL_H
