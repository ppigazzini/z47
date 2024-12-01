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
 * \file logistic.h
 ***********************************************/
#if !defined(LOGISTIC_H)
  #define LOGISTIC_H

  #include "realType.h"
  #include <stdint.h>

  void fnLogisticP     (uint16_t unusedButMandatoryParameter);
  void fnLogisticL     (uint16_t unusedButMandatoryParameter);
  void fnLogisticR     (uint16_t unusedButMandatoryParameter);
  void fnLogisticI     (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Logit (const real_t *x, const real_t *mu, const real_t *s, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Logit(const real_t *x, const real_t *mu, const real_t *s, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Logit (const real_t *x, const real_t *mu, const real_t *s, real_t *res, realContext_t *realContext);
  void WP34S_Qf_Logit  (const real_t *x, const real_t *mu, const real_t *s, real_t *res, realContext_t *realContext);
#endif // !LOGISTIC_H
