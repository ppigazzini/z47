// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPartLonginteger.h
 ***********************************************/
#if !defined(INTEGERPARTLONG_H)
  #define INTEGERPARTLONG_H

  #include "defines.h"
  #include <stdint.h>

  void fnLint   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void lintError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define lintError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void lintLonI (void);
  void lintShoI (void);
  void lintReal (void);
#endif // !INTEGERPARTLONG_H
