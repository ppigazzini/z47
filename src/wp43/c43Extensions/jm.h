// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


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


// Confirmation Y or N changed from original WP43 because the alpha keys order changed
#define ITEM_CONF_Y ITM_2
#define ITEM_CONF_N ITM_CHS




// Additional routines needed in jm.c
void fnSigmaAssign(uint16_t sigmaAssign);
void fnGetSigmaAssignToX(uint16_t unusedButMandatoryParameter);

//void fnInfo(bool_t Info);

void fnJM(uint16_t JM_OPCODE);


void fnJM_GetXToNORMmode(uint16_t Rubbish);
void fnStrInputReal34 (char inp1[]);
void fnStrInputLongint(char inp1[]);
void fnRCL          (int16_t inp);


#define JC_ERPN                 1    // eRPN
#define JC_HOME_TRIPLE          2    // HOME.3
#define JC_SHFT_4s              3    // SH_4s
#define JC_BASE_HOME            4    // HOME
#define JC_MYM_TRIPLE           5    // HOME.3
#define JC_BCR                  9    // CB ComplexResult
#define JC_BLZ                 10    // CB LeadingZeros
#define JC_PROPER              11    // CB FractionType
#define JC_IMPROPER            12    // CB FractionType
#define JC_BSR                 13    // CB SpecialResult
#define DM_ANY                 16    // DENANY
#define DM_FIX                 17    // DENFIX
#define JC_FRC                 18    // CB FRACTION MODE
#define PR_HPRP                19    // POLAR RECT CLASSIC MODE
#define PRTACT                 20    // PRTACT checkbox
#define PRTACT0                21    // PRTACT checkbox
#define PRTACT1                22    // PRTACT checkbox
#define DM_PROPFR              23
#define JC_BASE_MYM            24    // screen setup
#define JC_G_DOUBLETAP         25    // screen setup
#define JC_LARGELI             26

#define JC_ITM_TST             27    //dr

#define JC_VECT                39    // graph setup
#define JC_NVECT               40    // graph setup
#define JC_SCALE               41    // graph setup
#define JC_EXTENTX             42    // graph setup
#define JC_EXTENTY             43    // graph setup
#define JC_PLINE               44    // graph setup
#define JC_PCROS               45    // graph setup
#define JC_PBOX                46    // graph setup
#define JC_INTG                47    // graph setup
#define JC_DIFF                48    // graph setup
#define JC_RMS                 49    // graph setup
#define JC_SHADE               50    // graph setup
#define JC_PZOOMX              51
#define JC_PZOOMY              52

#define JC_NL                  53
#define JC_UC                  54

#define JC_LINEAR_FITTING      55
#define JC_EXPONENTIAL_FITTING 56
#define JC_LOGARITHMIC_FITTING 57
#define JC_POWER_FITTING       58
#define JC_ROOT_FITTING        59
#define JC_HYPERBOLIC_FITTING  60
#define JC_PARABOLIC_FITTING   61
#define JC_CAUCHY_FITTING      62
#define JC_GAUSS_FITTING       63
#define JC_ORTHOGONAL_FITTING  64

#define JC_IRFRAC              65
#define JC_UU                  66
#define JC_BCD                 67
#define JC_TOPHEX              68

#define JC_SI_All              69
#define JC_CPXMULT             70

#define JC_SS                  71
#define PR_HPBASE              72    // BASE CLASSIC MODE
#define PR_2TO10               73    // 2^10 flag for UNIT

#if defined(PC_BUILD)
//keyboard.c
void JM_DOT(int16_t xx, int16_t yy);
#endif // PC_BUILD

void fnShowJM  (uint16_t jmConfig);

#endif // !JM_H
