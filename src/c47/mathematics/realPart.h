// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file realPart.h
 ***********************************************/
#if !defined(REALPART_H)
  #define REALPART_H

  #include "defines.h"
  #include <stdint.h>

  void fnRealPart   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void realPartError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define realPartError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void realPartCxma (void);
  void realPartCplx (void);
  void realPartReal (void);
#endif // !REALPART_H
