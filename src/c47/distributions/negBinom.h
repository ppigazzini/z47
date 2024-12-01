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
 * \file negBinom.h
 ***********************************************/
#if !defined(NEGBINOM_H)
  #define NEGBINOM_H

  #include "realType.h"
  #include <stdint.h>

  void fnNegBinomialP  (uint16_t unusedButMandatoryParameter);
  void fnNegBinomialL  (uint16_t unusedButMandatoryParameter);
  void fnNegBinomialR  (uint16_t unusedButMandatoryParameter);
  void fnNegBinomialI  (uint16_t unusedButMandatoryParameter);

  void pdf_NegBinomial (const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext);
  void cdfu_NegBinomial(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext);
  void cdf_NegBinomial (const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext);
  void cdf_NegBinomial2(const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext);
  void qf_NegBinomial  (const real_t *x, const real_t *p0, const real_t *r, real_t *res, realContext_t *realContext);
#endif // !NEGBINOM_H
