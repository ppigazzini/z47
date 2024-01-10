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
 * \file rotateBits.h
 ***********************************************/
#if !defined(ROTATEBITS_H)
#define ROTATEBITS_H

#include <stdint.h>

void fnAsr   (uint16_t numberOfShifts);
void fnSl    (uint16_t numberOfShifts);
void fnSr    (uint16_t numberOfShifts);
void fnRl    (uint16_t numberOfShifts);
void fnRlc   (uint16_t numberOfShifts);
void fnRr    (uint16_t numberOfShifts);
void fnRrc   (uint16_t numberOfShifts);
void fnLj    (uint16_t numberOfShifts);
void fnRj    (uint16_t numberOfShifts);
void fnMirror(uint16_t unusedButMandatoryParameter);
void fnSwapEndian(uint8_t bitWidth);                  //JM
#endif // !ROTATEBITS_H
