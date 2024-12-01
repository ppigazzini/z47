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
 * \file slvc.h
 ***********************************************/
#if !defined(SLVC_H)
  #define SLVC_H

  #include "realType.h"

  void fnSlvc(uint16_t unusedButMandatoryParameter);

  /**
   * Solve monic cubic equation x^3 + b x^2 + c x + d = 0.
   *
   * \param[in] c2Real the real part of the quadratic coefficient
   * \param[in] c2Imag the imaginary part of the quadratic coefficient
   * \param[in] c1Real the real part of the linear coefficient
   * \param[in] c1Imag the imaginary part of the linear coefficient
   * \param[in] c0Real the real part of the constant term
   * \param[in] c0Imag the imaginary part of the constant term
   * \param[out] rReal the real part of the discriminant b^2 c^2 - 4 c^3 - 4 b^3 d - 27 d^2 + 18 b c d
   * \param[out] rImag the imaginary part of the discriminant
   * \param[out] x1Real the real part of the 1st root
   * \param[out] x1Imag the imaginary part of the 1st root
   * \param[out] x2Real the real part of the 2nd root
   * \param[out] x2Imag the imaginary part of the 2nd root
   * \param[out] x3Real the real part of the 3rd root
   * \param[out] x3Imag the imaginary part of the 3rd root
   * \param[in] realContext
   */
  void solveCubicEquation(const real_t *c2Real, const real_t *c2Imag,
                          const real_t *c1Real, const real_t *c1Imag,
                          const real_t *c0Real, const real_t *c0Imag,
                                real_t *rReal,        real_t *rImag,
                                real_t *x1Real,       real_t *x1Imag,
                                real_t *x2Real,       real_t *x2Imag,
                                real_t *x3Real,       real_t *x3Imag, realContext_t *realContext);
#endif // !SLVC_H
