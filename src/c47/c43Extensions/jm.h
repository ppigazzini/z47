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

// Time format 1 bit
#define TF_H24                  105
#define TF_H12                  106
// Complex unit 1 bit
#define CU_I                    107
#define CU_J                    108
// Product sign 1 bit
#define PS_DOT                  109
#define PS_CROSS                110
// Stack size 1 bit
#define SS_4                    111
#define SS_8                    112
// Complex mode 1 bit
#define CM_RECTANGULAR          113
#define CM_POLAR                114
// Display override 1 bit
#define DO_SCI                  115
#define DO_ENG                  116

#define FN_BEG                  117
#define FN_END                  118

//BCD options
#define BCDu                    0
#define BCD9c                   1
#define BCD10c                  2
//Longpress Options
#define RB_F14                  0
#define RB_F124                 1
#define RB_F1234                2
#define RB_M14                  10
#define RB_M124                 11
#define RB_M1234                12
//fgLine options
#define RB_FGLNOFF              0
#define RB_FGLNFUL              1
#define RB_FGLNLIM              2


void jm_show_calc_state(char comment[]);
void jm_show_comment   (char comment[]);


//keyboard.c  screen.c


// Additional routines needed in jm.c
void fnSigmaAssign(uint16_t sigmaAssign);
void fnGetSigmaAssignToX(uint16_t unusedButMandatoryParameter);

//void fnInfo(bool_t Info);

void fnJM(uint16_t JM_OPCODE);


void fnJM_GetXToNORMmode(uint16_t Rubbish);
void fnStrInputReal34 (char inp1[]);
void fnStrInputLongint(char inp1[]);
void fnRCL          (int16_t inp);


#define JC_ERPN                10001    // eRPN
#define JC_HOME_TRIPLE         10002    // HOME.3
#define JC_SHFT_4s             10003    // SH_4s
#define JC_BASE_HOME           10004    // HOME
#define JC_MYM_TRIPLE          10005    // HOME.3
#define JC_BCR                 10006    // CB ComplexResult
#define JC_BLZ                 10007    // CB LeadingZeros
#define JC_PROPER              10008    // CB FractionType
#define JC_IMPROPER            10009    // CB FractionType
#define JC_BSR                 10010    // CB SpecialResult
#define DM_FRACT               10011    // FRACT ON OFF
#define DM_ANY                 10012    // DENANY
#define DM_FIX                 10013    // DENFIX
#define JC_FRC                 10014    // CB FRACTION MODE
#define PR_HPRP                10015    // POLAR RECT CLASSIC MODE
#define PRTACT                 10016    // PRTACT checkbox
#define PRTACT0                10017    // PRTACT checkbox
#define PRTACT1                10018    // PRTACT checkbox
#define DM_PROPFR              10019
#define JC_BASE_MYM            10020    // screen setup
#define JC_G_DOUBLETAP         10021    // screen setup
#define JC_LARGELI             10022
#define JC_ITM_TST             10023    //dr
#define JC_CPXPLOT             10024
#define JC_VECT                10025    // graph setup
#define JC_NVECT               10026    // graph setup
#define JC_SCALE               10027    // graph setup
#define JC_EXTENTX             10028    // graph setup
#define JC_EXTENTY             10029    // graph setup
#define JC_PLINE               10030    // graph setup
#define JC_PCROS               10031    // graph setup
#define JC_PBOX                10032    // graph setup
#define JC_INTG                10033    // graph setup
#define JC_DIFF                10034    // graph setup
#define JC_RMS                 10035    // graph setup
#define JC_SHADE               10036    // graph setup
#define JC_PZOOMX              10037
#define JC_PZOOMY              10038
#define JC_NL                  10039
#define JC_UC                  10040
#define JC_LINEAR_FITTING      10041
#define JC_EXPONENTIAL_FITTING 10042
#define JC_LOGARITHMIC_FITTING 10043
#define JC_POWER_FITTING       10044
#define JC_ROOT_FITTING        10045
#define JC_HYPERBOLIC_FITTING  10046
#define JC_PARABOLIC_FITTING   10047
#define JC_CAUCHY_FITTING      10048
#define JC_GAUSS_FITTING       10049
#define JC_ORTHOGONAL_FITTING  10050
#define JC_IRFRAC              10051
#define JC_UU                  10052
#define JC_BCD                 10053
#define JC_TOPHEX              10054
#define JC_SI_All              10055
#define JC_CPXMULT             10056
#define JC_SS                  10057
#define PR_HPBASE              10058    // BASE CLASSIC MODE
#define PR_2TO10               10059    // 2^10 flag for UNIT
#define JC_LPfg                10060


void fnShowJM  (uint16_t jmConfig);

#endif // !JM_H
