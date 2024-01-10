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
 * \file comparisonReals.h
 ***********************************************/
#if !defined(COMPARISONREALS_H)
#define COMPARISONREALS_H

#include "realType.h"
#include "typeDefinitions.h"
#include <stdint.h>

// Return a convergence tolerance based on the current display setting
void convergenceTolerence(real_t *tol);

bool_t  real34CompareAbsGreaterThan (const real34_t *number1, const real34_t *number2);
bool_t  real34CompareAbsGreaterEqual(const real34_t *number1, const real34_t *number2);
bool_t  real34CompareAbsLessThan    (const real34_t *number1, const real34_t *number2);
bool_t  real34CompareEqual          (const real34_t *number1, const real34_t *number2);
bool_t  real34CompareGreaterEqual   (const real34_t *number1, const real34_t *number2);
bool_t  real34CompareGreaterThan    (const real34_t *number1, const real34_t *number2); //never used: JM returned
bool_t  real34CompareLessEqual      (const real34_t *number1, const real34_t *number2);
bool_t  real34CompareLessThan       (const real34_t *number1, const real34_t *number2);

bool_t  realCompareAbsGreaterThan   (const real_t *number1, const real_t *number2);
//bool_t  realCompareAbsGreaterEqual  (const real_t *number1, const real_t *number2); never used
bool_t  realCompareAbsLessThan      (const real_t *number1, const real_t *number2);
bool_t  realCompareEqual            (const real_t *number1, const real_t *number2);
bool_t  realCompareGreaterEqual     (const real_t *number1, const real_t *number2);
bool_t  realCompareGreaterThan      (const real_t *number1, const real_t *number2);
bool_t  realCompareLessEqual        (const real_t *number1, const real_t *number2);
bool_t  realCompareLessThan         (const real_t *number1, const real_t *number2);

bool_t  real34IsAnInteger           (const real34_t *x);
bool_t  realIsAnInteger             (const real_t *x);
//int16_t realIdenticalDigits         (real_t *a, real_t *b);
#endif // !COMPARISONREALS_H
