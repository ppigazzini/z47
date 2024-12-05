// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file mathematics/log2.h
 */
#if !defined(LOG2_H)
  #define LOG2_H

  #include "defines.h"
  #include <stdint.h>

  void  fnLog2   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void  log2Error(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define log2Error typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void  log2LonI (void);
  void  log2Rema (void);
  void  log2Cxma (void);
  void  log2ShoI (void);
  void  log2Real (void);
  void  log2Cplx (void);

#endif // !LOG2_H
