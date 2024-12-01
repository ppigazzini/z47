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
 * \file binomial.h
 ***********************************************/
#if !defined(BINOMIAL_H)
  #define BINOMIAL_H

  #include "realType.h"
  #include <stdint.h>

  void fnBinomialP        (uint16_t unusedButMandatoryParameter);
  void fnBinomialL        (uint16_t unusedButMandatoryParameter);
  void fnBinomialR        (uint16_t unusedButMandatoryParameter);
  void fnBinomialI        (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Binomial (const real_t *x, const real_t *p0, const real_t *n, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Binomial(const real_t *x, const real_t *p0, const real_t *n, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Binomial (const real_t *x, const real_t *p0, const real_t *n, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Binomial2(const real_t *x, const real_t *p0, const real_t *n, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Binomial  (const real_t *x, const real_t *p0, const real_t *n, real_t *res, realContext_t *realContext);
#endif // !BINOMIAL_H
