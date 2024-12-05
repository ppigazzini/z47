// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file lcm.h
 ***********************************************/
#if !defined(LCM_H)
  #define LCM_H

  #include "defines.h"
  #include <stdint.h>

  void fnLcm      (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void lcmError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define lcmError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  //      RegYRegX
  void lcmLonILonI(void);
  void lcmLonIShoI(void);
  void lcmShoILonI(void);
  void lcmShoIShoI(void);
#endif // !LCM_H
