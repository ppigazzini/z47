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
 * \file f.h
 ***********************************************/
#if !defined(F_H)
  #define F_H

  #include "realType.h"
  #include <stdint.h>

  void fnF_P          (uint16_t unusedButMandatoryParameter);
  void fnF_L          (uint16_t unusedButMandatoryParameter);
  void fnF_R          (uint16_t unusedButMandatoryParameter);
  void fnF_I          (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_F    (const real_t *x, const real_t *d1, const real_t *d2, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_F   (const real_t *x, const real_t *d1, const real_t *d2, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_F    (const real_t *x, const real_t *d1, const real_t *d2, real_t *res, realContext_t *realContext);
  void WP34S_Qf_F     (const real_t *x, const real_t *d1, const real_t *d2, real_t *res, realContext_t *realContext);

  void WP34S_Qf_Newton(uint32_t r_dist, const real_t *target, const real_t *estimate, const real_t *p1, const real_t *p2, const real_t *p3, real_t *res, realContext_t *realContext);
#endif // !F_H
