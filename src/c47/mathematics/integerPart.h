// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file integerPart.h
 ***********************************************/
#if !defined(INTEGERPART_H)
  #define INTEGERPART_H

  #include "defines.h"
  #include <stdint.h>

  void fnIp   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void ipError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define ipError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void ipRema (void);
  void ipReal (void);
#endif // !INTEGERPART_H
