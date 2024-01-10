/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file slvq.h
 ***********************************************/
#if !defined(SLVQ_H)
  #define SLVQ_H

  #include "realType.h"
  #include <stdint.h>

  void fnSlvq                (uint16_t unusedButMandatoryParameter);

  /**
   * Solve quadratic equation a x^2 + b x + c = 0.
   *
   * \param[in] aReal the real part of the quadratic coefficient
   * \param[in] aImag the imaginary part of the quadratic coefficient
   * \param[in] bReal the real part of the linear coefficient
   * \param[in] bImag the imaginary part of the linear coefficient
   * \param[in] cReal the real part of the constant term
   * \param[in] cImag the imaginary part of the constant term
   * \param[out] rReal the real part of the discriminant b^2 - 4 a c
   * \param[out] rImag the imaginary part of the discriminant
   * \param[out] x1Real the real part of the 1st root
   * \param[out] x1Imag the imaginary part of the 1st root
   * \param[out] x2Real the real part of the 2nd root
   * \param[out] x2Imag the imaginary part of the 2nd root
   * \param[in] realContext
   */
  void solveQuadraticEquation(const real_t *aReal, const real_t *aImag,
                              const real_t *bReal, const real_t *bImag,
                              const real_t *cReal, const real_t *cImag,
                                    real_t *rReal,       real_t *rImag,
                                    real_t *x1Real,      real_t *x1Imag,
                                    real_t *x2Real,      real_t *x2Imag, realContext_t *realContext);

#endif // !SLVQ_H
