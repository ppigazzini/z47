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
 * \file realType.c
 ***********************************************/


#include "wp43.h"

/*#define realToInt32(source, destination) do {                  \
            enum rounding savedRoundingMode;                     \
            real_t tmp;                                          \
            savedRoundingMode = ctxtReal39.round;                \
            ctxtReal39.round = DEC_ROUND_DOWN;                   \
            ctxtReal39.status = 0;                               \
            decNumberToIntegralValue(&tmp, source, &ctxtReal39); \
            destination = decGetInt(&tmp);                       \
            ctxtReal39.round = savedRoundingMode;                \
          } while(0) */

int32_t realToInt32C47(const real_t *r) {
  #if DECDPUN != 3
    #error DECDPUN must be 3
  #endif

  if(realIsSpecial(r) || (*r->lsu == 0 && r->digits == 1)) { // Special or zero
    return 0;
  }

  int32_t nbrDigitsInt = r->digits + r->exponent;
  if(nbrDigitsInt <= 0) { // number is less than 1
    return 0;
  }

  int32_t numberOfUnits = (r->digits + (DECDPUN - 1)) / DECDPUN;
  int32_t int32 = r->lsu[numberOfUnits-1];
  int32_t processedDigits = ((r->digits - 1) % DECDPUN) + 1;
  for(int unit=numberOfUnits-2; processedDigits<min(nbrDigitsInt, r->digits); unit--) {
    int32 = int32*1000 + r->lsu[unit]; // 1000 = 10^DECDPUN
    processedDigits += DECDPUN;
  }

  while(processedDigits > nbrDigitsInt) {
    int32 /= 10;
    processedDigits--;
  }

  while(processedDigits < nbrDigitsInt) {
    int32 *= 10;
    processedDigits++;
  }

  return (-2 * realIsNegative(r) + 1) * int32;
}

uint32_t realToUint32C47(const real_t *r) {
  #if DECDPUN != 3
    #error DECDPUN must be 3
  #endif

  if(realIsSpecial(r) || (*r->lsu == 0 && r->digits == 1)) { // Special or zero
    return 0;
  }

  int32_t nbrDigitsInt = r->digits + r->exponent;
  if(nbrDigitsInt <= 0) { // number is less than 1
    return 0;
  }

  int32_t numberOfUnits = (r->digits + (DECDPUN - 1)) / DECDPUN;
  uint32_t uint32 = r->lsu[numberOfUnits-1];
  int32_t processedDigits = ((r->digits - 1) % DECDPUN) + 1;
  for(int unit=numberOfUnits-2; processedDigits<min(nbrDigitsInt, r->digits); unit--) {
    uint32 = uint32*1000 + r->lsu[unit]; // 1000 = 10^DECDPUN
    processedDigits += DECDPUN;
  }

  while(processedDigits > nbrDigitsInt) {
    uint32 /= 10;
    processedDigits--;
  }

  while(processedDigits < nbrDigitsInt) {
    uint32 *= 10;
    processedDigits++;
  }

  return uint32;
}

int64_t realToInt64C47(const real_t *r) {
  #if DECDPUN != 3
    #error DECDPUN must be 3
  #endif

  if(realIsSpecial(r) || (*r->lsu == 0 && r->digits == 1)) { // Special or zero
    return 0;
  }

  int32_t nbrDigitsInt = r->digits + r->exponent;
  if(nbrDigitsInt <= 0) { // number is less than 1
    return 0;
  }

  int32_t numberOfUnits = (r->digits + (DECDPUN - 1)) / DECDPUN;
  int64_t int64 = r->lsu[numberOfUnits-1];
  int32_t processedDigits = ((r->digits - 1) % DECDPUN) + 1;
  for(int unit=numberOfUnits-2; processedDigits<min(nbrDigitsInt, r->digits); unit--) {
    int64 = int64*1000 + r->lsu[unit]; // 1000 = 10^DECDPUN
    processedDigits += DECDPUN;
  }

  while(processedDigits > nbrDigitsInt) {
    int64 /= 10;
    processedDigits--;
  }

  while(processedDigits < nbrDigitsInt) {
    int64 *= 10;
    processedDigits++;
  }

  return (-2 * realIsNegative(r) + 1) * int64;
}

uint64_t realToUint64C47(const real_t *r) {
  #if DECDPUN != 3
    #error DECDPUN must be 3
  #endif

  if(realIsSpecial(r) || (*r->lsu == 0 && r->digits == 1)) { // Special or zero
    return 0;
  }

  int32_t nbrDigitsInt = r->digits + r->exponent;
  if(nbrDigitsInt <= 0) { // number is less than 1
    return 0;
  }

  int32_t numberOfUnits = (r->digits + (DECDPUN - 1)) / DECDPUN;
  uint64_t uint64 = r->lsu[numberOfUnits-1];
  int32_t processedDigits = ((r->digits - 1) % DECDPUN) + 1;
  for(int unit=numberOfUnits-2; processedDigits<min(nbrDigitsInt, r->digits); unit--) {
    uint64 = uint64*1000 + r->lsu[unit]; // 1000 = 10^DECDPUN
    processedDigits += DECDPUN;
  }

  while(processedDigits > nbrDigitsInt) {
    uint64 /= 10;
    processedDigits--;
  }

  while(processedDigits < nbrDigitsInt) {
    uint64 *= 10;
    processedDigits++;
  }

  return uint64;
}
