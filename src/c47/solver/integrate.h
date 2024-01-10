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
 * \file integrate.h
 ***********************************************/
#if !defined(INTEGRATE_H)
  #define INTEGRATE_H

  #include "typeDefinitions.h"
  #include <stdint.h>

  void fnPgmInt   (uint16_t label);
  void fnIntegrate(uint16_t labelOrVariable);
  void fnIntVar   (uint16_t unusedButMandatoryParameter);

  void integrate  (calcRegister_t regist, const real_t *a, const real_t *b, real_t *acc, real_t *res, realContext_t *realContext);
#endif // !INTEGRATE_H
