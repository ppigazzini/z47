/* This file is part of C47.
 *
 * C47 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * C47 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with C47.  If not, see <http://www.gnu.org/licenses/>.
 */

//wp43.h


/* ADDITIONAL C43 functions and routines */

/*
Modes available in the mode menu:

1. HOME.3    This switches on/off whether the HOME menu pops on/off within SH.3T timeout. This is a testing option, makes no sense in real life.
2. SH.4s     ShiftTimoutMode:  This switches off the 4 second shift time-out
3. HOME.3    This switches off the 600 ms triple shift timer
4. ERPN      This disables the stack duplication and lift after entry

5. MYMENU
6. MYALPHA
7. HOME
8. ALPHAHOME
*/

#if !defined(JM_H)
#define JM_H

#include "longIntegerType.h"
#include "typeDefinitions.h"
#include <stdint.h>

void jm_show_calc_state(char comment[]);
void jm_show_comment   (char comment[]);


// Additional routines needed in jm.c
void fnSigmaAssign(uint16_t sigmaAssign);
void fnGetSigmaAssignToX(uint16_t unusedButMandatoryParameter);

//void fnInfo(bool_t Info);

void fnJM(uint16_t JM_OPCODE);


void fnStrInputReal34 (char inp1[]);
void fnStrInputLongint(char inp1[]);
void fnRCL          (int16_t inp);




void fnShowErpn  (uint16_t jmConfig);

#endif // !JM_H
