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
 * \file hyper.h
 ***********************************************/
#if !defined(HYPER_H)
  #define HYPER_H

  #include "realType.h"
  #include <stdint.h>

  void fnHypergeometricP  (uint16_t unusedButMandatoryParameter);
  void fnHypergeometricL  (uint16_t unusedButMandatoryParameter);
  void fnHypergeometricR  (uint16_t unusedButMandatoryParameter);
  void fnHypergeometricI  (uint16_t unusedButMandatoryParameter);

  void pdf_Hypergeometric (const real_t *x, const real_t *p0, const real_t *n, const real_t *n0, real_t *res, realContext_t *realContext);
  void cdfu_Hypergeometric(const real_t *x, const real_t *p0, const real_t *n, const real_t *n0, real_t *res, realContext_t *realContext);
  void cdf_Hypergeometric (const real_t *x, const real_t *p0, const real_t *n, const real_t *n0, real_t *res, realContext_t *realContext);
  void cdf_Hypergeometric2(const real_t *x, const real_t *p0, const real_t *n, const real_t *n0, real_t *res, realContext_t *realContext);
  void qf_Hypergeometric  (const real_t *x, const real_t *p0, const real_t *n, const real_t *n0, real_t *res, realContext_t *realContext);
#endif // !HYPER_H
