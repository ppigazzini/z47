// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file sign.h
 ***********************************************/
#if !defined(SIGN_H)
  #define SIGN_H

  #include "defines.h"
  #include <stdint.h>

  void fnSign   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void signError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define signError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void signLonI (void);
  void signRema (void);
  void signShoI (void);
  void signReal (void);
#endif // !SIGN_H
