// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPartShortinteger.h
 ***********************************************/
#if !defined(INTEGERPARTSHORT_H)
  #define INTEGERPARTSHORT_H

  #include "defines.h"
  #include <stdint.h>

  void fnSint   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void sintError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define sintError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void sintLonI (void);
  void sintShoI (void);
  void sintReal (void);
#endif // !INTEGERPARTLONG_H
