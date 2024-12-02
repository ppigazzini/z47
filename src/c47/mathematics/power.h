// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file power.h
 ***********************************************/
#if !defined(POWER_H)
  #define POWER_H

  #include "defines.h"
  #include "longIntegerType.h"
  #include "realType.h"
  #include <stdint.h>

  void fnPower    (uint16_t unusedButMandatoryParameter);

  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    void powError   (void);
  #else // (EXTRA_INFO_ON_CALC_ERROR != 1)
    #define powError typeError
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)

  void PowerReal(const real_t *y, const real_t *x, real_t *res, realContext_t *realContext);

  uint8_t PowerComplex(const real_t *yReal, const real_t *yImag, const real_t *xReal, const real_t *xImag, real_t *rReal, real_t *rImag, realContext_t *realContext);

  void longIntegerPower(longInteger_t base, longInteger_t exponent, longInteger_t result);

  //      RegYRegX
  void powLonILonI(void);
  void powLonIShoI(void);
  void powLonIReal(void);
  void powLonICplx(void);

  //      RegYRegX
  void powRemaLonI(void);
  void powRemaShoI(void);
  void powRemaReal(void);
  void powRemaCplx(void);

  //      RegYRegX
  void powCxmaLonI(void);
  void powCxmaShoI(void);
  void powCxmaReal(void);
  void powCxmaCplx(void);

  //      RegYRegX
  void powShoILonI(void);
  void powShoIShoI(void);
  void powShoIReal(void);
  void powShoICplx(void);

  //      RegYRegX
  void powRealLonI(void);
  void powRealShoI(void);
  void powRealReal(void);
  void powRealCplx(void);

  //      RegYRegX
  void powCplxLonI(void);
  void powCplxShoI(void);
  void powCplxReal(void);
  void powCplxCplx(void);
#endif // !POWER_H
