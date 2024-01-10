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
 * \file weibull.h
 ***********************************************/
#if !defined(WEIBULL_H)
  #define WEIBULL_H

  #include "realType.h"
  #include <stdint.h>

  void fnWeibullP     (uint16_t unusedButMandatoryParameter);
  void fnWeibullL     (uint16_t unusedButMandatoryParameter);
  void fnWeibullR     (uint16_t unusedButMandatoryParameter);
  void fnWeibullI     (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Weib (const real_t *x, const real_t *b, const real_t *t, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Weib(const real_t *x, const real_t *b, const real_t *t, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Weib (const real_t *x, const real_t *b, const real_t *t, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Weib  (const real_t *x, const real_t *b, const real_t *t, real_t *res, realContext_t *realContext);
#endif // !WEIBULL_H
