// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file and.h
 ***********************************************/
#if !defined(AND_H)
  #define AND_H

  #include "defines.h"
  #include <stdint.h>

  void fnLogicalAnd(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void andError24  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define andError24 typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void andError31  (void);
  void andLonILonI (void);
  void andLonIReal (void);
  void andRealLonI (void);
  void andRealReal (void);
  void andShoIShoI (void);
#endif // !AND_H
