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
 * \file rdp.h
 ***********************************************/
#if !defined(RDP_H)
  #define RDP_H

  #include "realType.h"
  #include <stdint.h>

  void roundToDecimalPlace(const real_t *source, real_t *destination, uint16_t digits, realContext_t *realContext);
  void fnRdp              (uint16_t digits);
  void rdpError           (uint16_t unusedButMandatoryParameter);
  void rdpTime            (uint16_t digits);
  void rdpRema            (uint16_t digits);
  void rdpCxma            (uint16_t digits);
  void rdpReal            (uint16_t digits);
  void rdpCplx            (uint16_t digits);
#endif // !RDP_H
