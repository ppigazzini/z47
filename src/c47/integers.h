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

/**
 * \file integers.h
 */
#if !defined(INTEGERS_H)
  #define INTEGERS_H

  #include "longIntegerType.h"
  #include <stdint.h>

  void     fnChangeBase                (uint16_t base);
  void     longIntegerMultiply         (longInteger_t opY, longInteger_t opX, longInteger_t result);
  void     longIntegerSquare           (longInteger_t op,  longInteger_t result);
  void     longIntegerAdd              (longInteger_t opY, longInteger_t opX, longInteger_t result);
  void     longIntegerSubtract         (longInteger_t opY, longInteger_t opX, longInteger_t result);

  /*
   * The functions below are borrowed
   * from the WP34S project and sligtly
   * modified and adapted
   */
  int64_t  WP34S_build_value          (const uint64_t x, const int32_t sign);
  uint64_t WP34S_intAdd               (uint64_t y, uint64_t x);
  uint64_t WP34S_intSubtract          (uint64_t y, uint64_t x);
  uint64_t WP34S_intMultiply          (uint64_t y, uint64_t x);
  uint64_t WP34S_intDivide            (uint64_t y, uint64_t x);
  uint64_t WP34S_intPower             (uint64_t b, uint64_t e);
  //uint64_t WP34S_intSqr               (uint64_t x); Never used
  //uint64_t WP34S_intCube              (uint64_t x); Never used
  uint64_t WP34S_intLCM               (uint64_t y, uint64_t x);
  uint64_t WP34S_intGCD               (uint64_t y, uint64_t x);
  uint64_t WP34S_intChs               (uint64_t x);
  uint64_t WP34S_intSqrt              (uint64_t x);
  uint64_t WP34S_intAbs               (uint64_t x);
  //uint64_t WP34S_intNot               (uint64_t x);
  //uint64_t WP34S_intFP                (uint64_t x);
  //uint64_t WP34S_intIP                (uint64_t x);
  uint64_t WP34S_intSign              (uint64_t x);
  uint64_t WP34S_int2pow              (uint64_t x);
  uint64_t WP34S_int10pow             (uint64_t x);
  uint64_t WP34S_intLog2              (uint64_t x);
  uint64_t WP34S_intLog10             (uint64_t x);
  uint64_t WP34S_extract_value        (const uint64_t val, int32_t *const sign);
  int64_t  WP34S_intFib               (int64_t x);
  uint64_t WP34S_mulmod               (const uint64_t a, uint64_t b, const uint64_t c);
  uint64_t WP34S_expmod               (const uint64_t a, uint64_t b, const uint64_t c);
#endif // !INTEGERS_H
