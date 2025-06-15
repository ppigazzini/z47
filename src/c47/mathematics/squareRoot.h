// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file mathematics/sqrt.h
 */
#if !defined(SQUAREROOT_H)
  #define SQUAREROOT_H

  void fnSquareRoot(uint16_t unusedButMandatoryParameter);
  void sqrtComplex (const real_t *real, const real_t *imag, real_t *resReal, real_t *resImag, realContext_t *realContext);
  void rootLonI    (int32_t n);

#endif // !SQUAREROOT_H
