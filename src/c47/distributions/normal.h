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
 * \file normal.h
 ***********************************************/
#if !defined(NORMAL_H)
  #define NORMAL_H

  #include "realType.h"
  #include <stdint.h>

  void fnStdNormalP  (uint16_t unusedButMandatoryParameter);
  void fnStdNormalL  (uint16_t unusedButMandatoryParameter);
  void fnStdNormalR  (uint16_t unusedButMandatoryParameter);
  void fnStdNormalI  (uint16_t unusedButMandatoryParameter);

  void fnNormalP     (uint16_t unusedButMandatoryParameter);
  void fnNormalL     (uint16_t unusedButMandatoryParameter);
  void fnNormalR     (uint16_t unusedButMandatoryParameter);
  void fnNormalI     (uint16_t unusedButMandatoryParameter);

  void fnLogNormalP  (uint16_t unusedButMandatoryParameter);
  void fnLogNormalL  (uint16_t unusedButMandatoryParameter);
  void fnLogNormalR  (uint16_t unusedButMandatoryParameter);
  void fnLogNormalI  (uint16_t unusedButMandatoryParameter);

  void WP34S_Pdf_Q   (const real_t *x, real_t *res, realContext_t *realContext);
  void WP34S_Cdfu_Q  (const real_t *x, real_t *res, realContext_t *realContext);
  void WP34S_Cdf_Q   (const real_t *x, real_t *res, realContext_t *realContext);
  void WP34S_qf_q_est(const real_t *x, real_t *res, real_t* resY, realContext_t *realContext);
  void WP34S_Qf_Q    (const real_t *x, real_t *res, realContext_t *realContext);
#endif // !NORMAL_H
