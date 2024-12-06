// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file imaginaryPart.h
 ***********************************************/
#if !defined(IMAGINARYPART_H)
  #define IMAGINARYPART_H

  void fnImaginaryPart(uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void imagPartError  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define imagPartError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void imagPartCxma   (void);
  void imagPartCplx   (void);
  void imagPartReal   (void);
#endif // !IMAGINARYPART_H
