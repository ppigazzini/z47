// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file fib.h
 ***********************************************/
#if !defined(GD_H)
  #define GD_H

  #include "realType.h"
  #include <stdint.h>

  void fnGd   (uint16_t unusedButMandatoryParameter);
  void fnInvGd(uint16_t unusedButMandatoryParameter);

  void gdTypeError(uint16_t gdOrInvGd);
  void gdLonI (uint16_t gdOrInvGd);
  void gdReal (uint16_t gdOrInvGd);
  void gdCplx (uint16_t gdOrInvGd);

  uint8_t GudermannianReal(const real_t *x, real_t *res, realContext_t *realContext);
  uint8_t GudermannianComplex(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext);

  uint8_t InverseGudermannianReal(const real_t *x, real_t *res, realContext_t *realContext);
  uint8_t InverseGudermannianComplex(const real_t *xReal, const real_t *xImag, real_t *resReal, real_t *resImag, realContext_t *realContext);
#endif // !GD_H
