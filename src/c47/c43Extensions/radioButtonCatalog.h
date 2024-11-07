// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file radioButtonCatalog.h
 ***********************************************/

#if !defined(RADIOBUTTONCATALOG_H)
#define RADIOBUTTONCATALOG_H

#include <stdint.h>

#define RB_FALSE    0
#define RB_TRUE     1
#define CB_FALSE    2
#define CB_TRUE     3

#define NOVAL              -126
#define ITEM_NOT_CODED     -127
#define NOTEXT             ""


int8_t   fnCbIsSet             (int16_t item);
void     fnRefreshState        (void);
int16_t  fnItemShowValue       (int16_t item);
char*    figlabel              (const char* label, const char* showText, int16_t showValue);


/********************************************//**
 * \typedef radiocb_t
 * \brief Structure keeping the information for one item
 ***********************************************/


#define RB_AM                  128 // AngularMode
#define RB_CM                  129 // ComplexMode
#define RB_CU                  130 // ComplexUnit
#define RB_CF                  131 // CurveFitting
#define RB_DF                  132 // DateFormat
#define RB_DI                  133 // DisplayFormat
#define RB_DO                  134 // DisplayModeOverride
#define RB_IM                  135 // IntegerMode
#define RB_PS                  136 // ProductSign
#define RB_SS                  137 // StackSize
#define RB_TF                  138 // TimeFormat
#define RB_WS                  139 // WordSize
#define RB_SA                  140 // SigmaAssign
#define RB_ID                  141 // InputDefault
#define CB_JC                  142 // CheckBox
#define RB_HX                  143 // BASE
#define RB_NM                  144 // NORMALMODE
#define RB_BCD                 145 // NORMALMODE
#define RB_M                   146 // NORMALMODE
#define RB_F                   147 // NORMALMODE
#define RB_TV                  148 // NORMALMODE
#define RB_FG                  149 // NORMALMODE
#define RB_IP                  150 // SEPS
#define RB_FP                  151 // SEPS
#define RB_RX                  152 // SEPS
#define RB_PRN                 153 // PRON PROFF
#define RB_x3                  154 // HOME/MYM x3
#define RB_BA                  155 // BASE SCREEN/MENU
#define RB_GW                  156 // GROW/WRAP
#define RB_KY                  157 // KEYS LAYOUT

//Not strictly needed to follow on numerically from RB/CB types above, but why not
#define JC_ERPN                158    // eRPN
#define JC_HOME_TRIPLE         159    // HOME.3
#define JC_SHFT_4s             160    // SH_4s
#define JC_BASE_HOME           161    // HOME
#define JC_MYM_TRIPLE          162    // HOME.3
#define JC_BCR                 163    // CB ComplexResult
#define JC_BLZ                 164    // CB LeadingZeros
#define JC_PROPER              165    // CB FractionType
#define JC_IMPROPER            166    // CB FractionType
#define JC_BSR                 167    // CB SpecialResult
#define DM_FRACT               168    // FRACT ON OFF
#define DM_ANY                 169    // DENANY
#define DM_FIX                 170    // DENFIX
#define JC_FRC                 171    // CB FRACTION MODE
#define PR_HPRP                172    // POLAR RECT CLASSIC MODE
#define PRTACT                 173    // PRTACT checkbox
#define PRTACT0                174    // PRTACT checkbox
#define PRTACT1                175    // PRTACT checkbox
#define DM_PROPFR              176
#define JC_BASE_MYM            177    // screen setup
#define JC_G_DOUBLETAP         178    // screen setup
#define JC_LARGELI             179
#define JC_ITM_TST             180    //dr
#define JC_CPXPLOT             181
#define JC_VECT                182    // graph setup
#define JC_NVECT               183    // graph setup
#define JC_SCALE               184    // graph setup
#define JC_EXTENTX             185    // graph setup
#define JC_EXTENTY             186    // graph setup
#define JC_PLINE               187    // graph setup
#define JC_PCROS               188    // graph setup
#define JC_PPLUS               189    // graph setup
#define JC_PBOX                190    // graph setup
#define JC_INTG                191    // graph setup
#define JC_DIFF                192    // graph setup
#define JC_RMS                 193    // graph setup
#define JC_SHADE               194    // graph setup
#define JC_PZOOMX              195
#define JC_PZOOMY              196
#define JC_NL                  197
#define JC_UC                  198
#define JC_LINEAR_FITTING      199
#define JC_EXPONENTIAL_FITTING 200
#define JC_LOGARITHMIC_FITTING 201
#define JC_POWER_FITTING       202
#define JC_ROOT_FITTING        203
#define JC_HYPERBOLIC_FITTING  204
#define JC_PARABOLIC_FITTING   205
#define JC_CAUCHY_FITTING      206
#define JC_GAUSS_FITTING       207
#define JC_ORTHOGONAL_FITTING  208
#define JC_IRFRAC              209
#define JC_UU                  210
#define JC_BCD                 211
#define JC_TOPHEX              212
#define JC_CPXMULT             213
#define JC_SS                  214
#define PR_HPBASE              215  // BASE CLASSIC MODE
#define PR_2TO10               216  // 2^10 flag for UNIT
#define JC_LPfg                217
#define BCDu                   218  //BCD options
#define BCD9c                  219
#define BCD10c                 220
#define RBX_F14                221  //Longpress Options
#define RBX_F124               222
#define RBX_F1234              223
#define RBX_M14                224
#define RBX_M124               225
#define RBX_M1234              226
#define RBX_FGLNOFF            227  //fgLine options
#define RBX_FGLNFUL            228
#define RBX_FGLNLIM            229
#define TF_H24                 230 // Time format 1 bit
#define TF_H12                 231
#define CU_I                   232 // Complex unit 1 bit
#define CU_J                   233
#define PS_DOT                 234 // Product sign 1 bit
#define PS_CROSS               235
#define SS_4                   236 // Stack size 1 bit
#define SS_8                   237
#define CM_RECTANGULAR         238 // Complex mode 1 bit
#define CM_POLAR               239
#define DO_SCI                 240 // Display override 1 bit
#define DO_ENG                 241
#define FN_BEG                 242 // FIN BEGIN END
#define FN_END                 243


typedef struct {
  int16_t itemNr;              //<
  int16_t param;               //< 1st parameter to the above function
  uint8_t  radioButton;        //< Menu of RADIO in which the item is located: see #define RB_*
} radiocb_t;

#endif // !RADIOBUTTONCATALOG_H
