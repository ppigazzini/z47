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
 * \file geometric.h
 ***********************************************/
#if !defined(GEOMETRIC_H)
  #define GEOMETRIC_H

  #include "realType.h"
  #include <stdint.h>

  void fnGeometricP           (uint16_t unusedButMandatoryParameter);
  void fnGeometricL           (uint16_t unusedButMandatoryParameter);
  void fnGeometricR           (uint16_t unusedButMandatoryParameter);
  void fnGeometricI           (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Geom         (const real_t *x, const real_t *p0, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Geom        (const real_t *x, const real_t *p0, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Geom         (const real_t *x, const real_t *p0, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Geom          (const real_t *x, const real_t *p0, real_t *res, realContext_t *realContext);

  void WP34S_qf_discrete_final(uint16_t dist, const real_t *r, const real_t *p, const real_t *i, const real_t *j, const real_t *k, real_t *res, realContext_t *realContext);
#endif // !GEOMETRIC_H
