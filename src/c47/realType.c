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


#include "c47.h"
#include "registerValueConversions.h"
#include "constantPointers.h"

static void roundToIntAndNormalise(const real_t *r, real_t *i) {
  realToIntegralValue(r, i, DEC_ROUND_DOWN, &ctxtReal39);
  /* Adding zero forces the normalisation of the resulting real which is
   * required for the conversions to integers to work properly
   */
  realAdd(const_0, i, i, &ctxtReal39);
}

int32_t realToInt32C47(const real_t *r) {
  real_t i;

  roundToIntAndNormalise(r, &i);
  return decNumberToInt32(&i, &ctxtReal39);
}

uint32_t realToUint32C47(const real_t *r) {
  real_t i;

  roundToIntAndNormalise(r, &i);
  return decNumberToUInt32(&i, &ctxtReal39);
}

//int64_t realToInt64C47(const real_t *r) {
//  real_t i;
//
//  roundToIntAndNormalise(r, &i);
//  return decNumberToInt64(&i, &ctxtReal39);
//}

uint64_t realToUint64C47(const real_t *r) {
  real_t i;

  roundToIntAndNormalise(r, &i);
  return decNumberToUInt64(&i, &ctxtReal39);
}
