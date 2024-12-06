// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file floor.h
 ***********************************************/
#if !defined(FLOOR_H)
  #define FLOOR_H

  void fnFloor   (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void floorError(void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define floorError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void floorRema (void);
  void floorReal (void);
#endif // !FLOOR_H
