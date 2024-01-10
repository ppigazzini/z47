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
 * \file t.h
 ***********************************************/
#if !defined(T_H)
  #define T_H

  #include "realType.h"
  #include <stdint.h>

  void fnT_P       (uint16_t unusedButMandatoryParameter);
  void fnT_L       (uint16_t unusedButMandatoryParameter);
  void fnT_R       (uint16_t unusedButMandatoryParameter);
  void fnT_I       (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_T (const real_t *x, const real_t *nu, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_T(const real_t *x, const real_t *nu, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_T (const real_t *x, const real_t *nu, real_t *res, realContext_t *realContext);
  void WP34S_Qf_T  (const real_t *x, const real_t *nu, real_t *res, realContext_t *realContext);
#endif // !T_H
