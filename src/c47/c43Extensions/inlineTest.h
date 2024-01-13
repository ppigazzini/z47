/* This file is part of C43.
 *
 * C43 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * C43 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with C43.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file inlineTest.h
 ***********************************************/

#if !defined(INLINETEST_H)
#define INLINETEST_H

#include "longIntegerType.h"
#include "typeDefinitions.h"
#include <stdint.h>

//#if defined(INLINE_TEST)
extern bool_t   testEnabled;
extern uint16_t testBitset;



void     fnSwStart            (uint8_t nr);       // Start StopWatch, 0..3
void     fnSwStop             (uint8_t nr);       // Stop StopWatch, 0..3

void fnSetInlineTest          (uint16_t drConfig);
void fnGetInlineTestBsToX     (uint16_t unusedButMandatoryParameter);
void fnSetInlineTestXToBs     (uint16_t unusedButMandatoryParameter);
void fnSysFreeMem             (uint16_t unusedButMandatoryParameter);
bool_t fnTestBitIsSet         (uint8_t bit);
//#endif // INLINE_TEST

#endif // !INLINETEST_H
