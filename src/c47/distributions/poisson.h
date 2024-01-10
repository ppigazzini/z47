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
 * \file poisson.h
 ***********************************************/
#if !defined(POISSON_H)
  #define POISSON_H

  #include "realType.h"
  #include <stdint.h>

  void fnPoissonP                (uint16_t unusedButMandatoryParameter);
  void fnPoissonL                (uint16_t unusedButMandatoryParameter);
  void fnPoissonR                (uint16_t unusedButMandatoryParameter);
  void fnPoissonI                (uint16_t unusedButMandatoryParameter);

  void WP34S_normal_moment_approx(const real_t *prob, const real_t *var, const real_t *mean, real_t *res, realContext_t *realContext);

  void WP34S_Pdf_Poisson         (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Poisson        (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Poisson         (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Poisson2        (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Poisson          (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
#endif // !POISSON_H
