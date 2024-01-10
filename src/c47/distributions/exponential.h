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
 * \file exponential.h
 ***********************************************/
#if !defined(EXPONENTIAL_H)
  #define EXPONENTIAL_H

  #include "realType.h"
  #include <stdint.h>

  void fnExponentialP  (uint16_t unusedButMandatoryParameter);
  void fnExponentialL  (uint16_t unusedButMandatoryParameter);
  void fnExponentialR  (uint16_t unusedButMandatoryParameter);
  void fnExponentialI  (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Expon (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Expon(const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Expon (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Expon  (const real_t *x, const real_t *lambda, real_t *res, realContext_t *realContext);
#endif // !EXPONENTIAL_H
