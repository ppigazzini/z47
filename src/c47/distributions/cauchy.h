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
 * \file cauchy.h
 ***********************************************/
#if !defined(CAUCHY_H)
  #define CAUCHY_H

  #include "realType.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  void fnCauchyP              (uint16_t unusedButMandatoryParameter);
  void fnCauchyL              (uint16_t unusedButMandatoryParameter);
  void fnCauchyR              (uint16_t unusedButMandatoryParameter);
  void fnCauchyI              (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Cauchy       (const real_t *x, const real_t *x0, const real_t *gamma, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Cauchy      (const real_t *x, const real_t *x0, const real_t *gamma, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Cauchy       (const real_t *x, const real_t *x0, const real_t *gamma, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Cauchy        (const real_t *x, const real_t *x0, const real_t *gamma, real_t *res, realContext_t *realContext);

  void WP34S_cdf_cauchy_common(const real_t *x, const real_t *x0, const real_t *gamma, bool_t complementary, real_t *res, realContext_t *realContext);
  void WP34S_cdf_cauchy_xform (const real_t *x, const real_t *x0, const real_t *gamma, real_t *res, realContext_t *realContext);
#endif // !CAUCHY_H
