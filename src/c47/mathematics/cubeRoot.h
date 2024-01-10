// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/**
 * \file mathematics/cubeRoot.h
 */
#if !defined(CUBEROOT_H)
  #define CUBEROOT_H

  #include "defines.h"
  #include "realType.h"
  #include <stdint.h>

  void fnCubeRoot(uint16_t unusedButMandatoryParameter);

  #if(EXTRA_INFO_ON_CALC_ERROR == 1)
    void curtError  (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR == 1)
    #define curtError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void curtLonI   (void);
  void curtRema   (void);
  void curtCxma   (void);
  void curtShoI   (void);
  void curtReal   (void);
  void curtCplx   (void);

  void curtComplex(const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);

#endif // !CUBEROOT_H
