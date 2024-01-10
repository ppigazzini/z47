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
 * \file rsd.h
 ***********************************************/
#if !defined(RSD_H)
  #define RSD_H

  #include "realType.h"
  #include "typeDefinitions.h"
  #include <stdint.h>

  void roundToSignificantDigits(const real_t *source, real_t *destination, uint16_t digits, realContext_t *realContext);
  void senaryDigitToDecimal    (bool_t pre_grouped, real_t *val, realContext_t *realContext);
  void decimalDigitToSenary    (bool_t pre_grouped, real_t *val, realContext_t *realContext);
  void fnRsd                   (uint16_t digits);
  void rsdError                (uint16_t unusedButMandatoryParameter);
  void rsdTime                 (uint16_t digits);
  void rsdRema                 (uint16_t digits);
  void rsdCxma                 (uint16_t digits);
  void rsdReal                 (uint16_t digits);
  void rsdCplx                 (uint16_t digits);
#endif // !RSD_H
