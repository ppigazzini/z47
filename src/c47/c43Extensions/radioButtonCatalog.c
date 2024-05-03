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



/********************************************//**
 * \file radioButtonCatalog.c
 ***********************************************/

#include "c43Extensions/radioButtonCatalog.h"

#include "charString.h"
#include "curveFitting.h"
#include "flags.h"
#include "fonts.h"
#include "hal/audio.h"
#include "c43Extensions/inlineTest.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "plotstat.h"
#include "screen.h"
#include <string.h>

#include "c47.h"


TO_QSPI const radiocb_t indexOfRadioCbEepromItems[] = {
  //item                 parameter               function
  {ITM_DEG,              amDegree,               RB_AM},  //fnAngularMode
  {ITM_DMS,              amDMS,                  RB_AM},  //fnAngularMode
  {ITM_GRAD,             amGrad,                 RB_AM},  //fnAngularMode
  {ITM_MULPI,            amMultPi,               RB_AM},  //fnAngularMode
  {ITM_RAD,              amRadian,               RB_AM},  //fnAngularMode

  {ITM_DMY,              DF_DMY,                 RB_DF},  //fnSetDateFormat
  {ITM_MDY,              DF_MDY,                 RB_DF},  //fnSetDateFormat
  {ITM_YMD,              DF_YMD,                 RB_DF},  //fnSetDateFormat
  {ITM_ALL,              DF_ALL,                 RB_DI},  //fnDisplayFormatAll
  {ITM_ENG,              DF_ENG,                 RB_DI},  //fnDisplayFormatEng
  {ITM_FIX,              DF_FIX,                 RB_DI},  //fnDisplayFormatFix
  {ITM_SCI,              DF_SCI,                 RB_DI},  //fnDisplayFormatSci
  {ITM_SIGFIG,           DF_SF,                  RB_DI},  //fnDisplayFormatSigFig
  {ITM_UNIT,             DF_UN,                  RB_DI},  //fnDisplayFormatUnit
  {ITM_INP_DEF_43S,      ID_43S,                 RB_ID},  //fnInDefault
  {ITM_INP_DEF_CPXDP,    ID_CPXDP,               RB_ID},  //fnInDefault
  {ITM_INP_DEF_DP,       ID_DP,                  RB_ID},  //fnInDefault
  {ITM_INP_DEF_LI,       ID_LI,                  RB_ID},  //fnInDefault
  {ITM_INP_DEF_SI,       ID_SI,                  RB_ID},  //fnInDefault
  {ITM_1COMPL,           SIM_1COMPL,             RB_IM},  //fnIntegerMode
  {ITM_2COMPL,           SIM_2COMPL,             RB_IM},  //fnIntegerMode
  {ITM_SIGNMT,           SIM_SIGNMT,             RB_IM},  //fnIntegerMode
  {ITM_UNSIGN,           SIM_UNSIGN,             RB_IM},  //fnIntegerMode
  {ITM_WS8,              8,                      RB_WS},  //fnSetWordSize
  {ITM_WS16,             16,                     RB_WS},  //fnSetWordSize
  {ITM_WS32,             32,                     RB_WS},  //fnSetWordSize
  {ITM_WS64,             64,                     RB_WS},  //fnSetWordSize

  {ITM_N_KEY_op_j,       16384+ITM_op_j,         RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_TGLFRT,     16384+ITM_TGLFRT,       RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_ALPHA,      16384+ITM_AIM,          RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_CC,         16384+ITM_CC,           RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_FSH,        16384+ITM_SHIFTf,       RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_GSH,        16384+ITM_SHIFTg,       RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_FGSH,       16384+KEY_fg,           RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_MM,         16384+-MNU_MyMenu,      RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_DRG,        16384+ITM_DRG,          RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_PRGM,       16384+ITM_PR,           RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_USER,       16384+ITM_USERMODE,     RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_HOME,       16384+-MNU_HOME,        RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_SIGMA,      16384+ITM_SIGMAPLUS,    RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_SNAP,       16384+ITM_SNAP,         RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_NIL,        16384+ITM_NULL,         RB_SA},  //fnSigmaAssign


  {ITM_F1234,            RB_F1234,               RB_F},   //
  {ITM_M1234,            RB_M1234,               RB_M},   //
  {ITM_F14,              RB_F14,                 RB_F},   //
  {ITM_M14,              RB_M14,                 RB_M},   //
  {ITM_F124,             RB_F124,                RB_F},   //
  {ITM_M124,             RB_M124,                RB_M},   //

  {ITM_FGLNOFF,          RB_FGLNOFF,             RB_FG},  //
  {ITM_FGLNLIM,          RB_FGLNLIM,             RB_FG},  //
  {ITM_FGLNFUL,          RB_FGLNFUL,             RB_FG},  //

  {ITM_BCDU,             BCDu,                   RB_BCD}, //
  {ITM_BCD9,             BCD9c,                  RB_BCD}, //
  {ITM_BCD10,            BCD10c,                 RB_BCD}, //

  {ITM_HPRP,             PR_HPRP,                CB_JC},
  {ITM_HPBASE,           PR_HPBASE,              CB_JC},
  {ITM_2TO10,            PR_2TO10,               CB_JC},
  {ITM_DENANY,           DM_ANY,                 CB_JC},
  {ITM_DENFIX,           DM_FIX,                 CB_JC},
  {ITM_PROPFR,           DM_PROPFR,              CB_JC},
  {ITM_FRACT,            DM_FRACT,               CB_JC},

  {ITM_M_GROW,           ITM_M_GROW,             RB_GW},  // SFL_PRTACT
  {ITM_M_WRAP,           ITM_M_WRAP,             RB_GW},  // SFL_PRTACT

  {ITM_PRTACT,           PRTACT,                 CB_JC},  // SFL_PRTACT
  {ITM_PRTACT0,          PRTACT0,                RB_PRN},  // SFL_PRTACT
  {ITM_PRTACT1,          PRTACT1,                RB_PRN},  // SFL_PRTACT

  {ITM_T_LINF,           JC_LINEAR_FITTING,      CB_JC},  //fnCurveFitting
  {ITM_T_EXPF,           JC_EXPONENTIAL_FITTING, CB_JC},  //fnCurveFitting
  {ITM_T_LOGF,           JC_LOGARITHMIC_FITTING, CB_JC},  //fnCurveFitting
  {ITM_T_POWERF,         JC_POWER_FITTING,       CB_JC},  //fnCurveFitting
  {ITM_T_ROOTF,          JC_ROOT_FITTING,        CB_JC},  //fnCurveFitting
  {ITM_T_HYPF,           JC_HYPERBOLIC_FITTING,  CB_JC},  //fnCurveFitting
  {ITM_T_PARABF,         JC_PARABOLIC_FITTING,   CB_JC},  //fnCurveFitting
  {ITM_T_CAUCHF,         JC_CAUCHY_FITTING,      CB_JC},  //fnCurveFitting
  {ITM_T_GAUSSF,         JC_GAUSS_FITTING,       CB_JC},  //fnCurveFitting
  {ITM_T_ORTHOF,         JC_ORTHOGONAL_FITTING,  CB_JC},  //fnCurveFitting

  {ITM_POLAR,            CM_POLAR,               RB_CM},  //SetSetting          /*  464 */ //fnComplexMode
  {ITM_RECT,             CM_RECTANGULAR,         RB_CM},  //SetSetting          /*  507 */ //fnComplexMode
  {ITM_CPXI,             CU_I,                   RB_CU},  //SetSetting          /*   96 */ //fnComplexUnit
  {ITM_CPXJ,             CU_J,                   RB_CU},  //SetSetting          /*   97 */ //fnComplexUnit
  {ITM_ENGOVR,           DO_ENG,                 RB_DO},  //SetSetting          /*  146 */ //fnDisplayOvr
  {ITM_SCIOVR,           DO_SCI,                 RB_DO},  //SetSetting          /*  547 */ //fnDisplayOvr
  {ITM_MULTCR,           PS_CROSS,               RB_PS},  //SetSetting          /*  373 */ //fnProductSign
  {ITM_MULTDOT,          PS_DOT,                 RB_PS},  //SetSetting          /*  374 */ //fnProductSign
  {ITM_SSIZE4,           SS_4,                   RB_SS},  //SetSetting          /*  583 */ //fnStackSize
  {ITM_SSIZE8,           SS_8,                   RB_SS},  //SetSetting          /*  584 */ //fnStackSize
  {ITM_CLK12,            TF_H12,                 RB_TF},  //SetSetting          /*   75 */ //fnTimeFormat
  {ITM_CLK24,            TF_H24,                 RB_TF},  //SetSetting          /*   76 */ //fnTimeFormat
  {ITM_BEGINP,           FN_BEG,                 RB_TV},  //SetSetting
  {ITM_ENDP,             FN_END,                 RB_TV},  //SetSetting


  {ITM_CB_CPXRES,        JC_BCR,                 CB_JC},  //SetSetting
  {ITM_CB_SPCRES,        JC_BSR,                 CB_JC},  //SetSetting
  {ITM_CB_LEADING_ZERO,  JC_BLZ,                 CB_JC},  //SetSetting
  {ITM_CB_FRCSRN,        JC_FRC,                 CB_JC},  //SetSetting
  {ITM_ERPN,             JC_ERPN,                CB_JC},  //SetSetting
  {ITM_G_DOUBLETAP,      JC_G_DOUBLETAP,         CB_JC},  //SetSetting
  {ITM_SHTIM,            JC_SHFT_4s,             CB_JC},  //SetSetting
  {ITM_VECT,             JC_VECT,                CB_JC},  //SetSetting
  {ITM_NVECT,            JC_NVECT,               CB_JC},  //SetSetting
  {ITM_SCALE,            JC_SCALE,               CB_JC},  //SetSetting
  {ITM_LARGELI,          JC_LARGELI,             CB_JC},  //SetSetting
  {ITM_IRFRAC,           JC_IRFRAC,              CB_JC},  //SetSetting
  {ITM_EXTX,             JC_EXTENTX,             CB_JC},  //SetSetting
  {ITM_EXTY,             JC_EXTENTY,             CB_JC},  //SetSetting

  {ITM_TEST,             JC_ITM_TST,             CB_JC},  //fnSetInlineTest
  {ITM_PLINE,            JC_PLINE,               CB_JC},  //
  {ITM_PCROS,            JC_PCROS,               CB_JC},  //
  {ITM_PBOX,             JC_PBOX,                CB_JC},  //
  {ITM_INTG,             JC_INTG,                CB_JC},  //
  {ITM_DIFF,             JC_DIFF,                CB_JC},  //
  {ITM_RMS,              JC_RMS,                 CB_JC},  //
  {ITM_SHADE,            JC_SHADE,               CB_JC},  //
  {ITM_CPXPLT,           JC_CPXPLT,              CB_JC},

  {CHR_num,              JC_NL,                  CB_JC},  //
  {CHR_case,             JC_UC,                  CB_JC},  //
  {ITM_USERMODE,         JC_UU,                  CB_JC},  //
  {ITM_SCR,              JC_SS,                  CB_JC},  //
  {ITM_SH_LONGPRESS,     JC_LPfg,                CB_JC},  //

  {ITM_BCD,              JC_BCD,                 CB_JC},  //
  {ITM_TOPHEX,           JC_TOPHEX,              CB_JC},  //

  {ITM_SI_All,           JC_SI_All,              CB_JC},  //
  {ITM_CPXMULT,          JC_CPXMULT,             CB_JC},  //

  {ITM_2BIN,             2,                      RB_HX},  //fnChangeBaseJM
  {ITM_2OCT,             8,                      RB_HX},  //fnChangeBaseJM
  {ITM_2DEC,             10,                     RB_HX},  //fnChangeBaseJM
  {ITM_2HEX,             16,                     RB_HX},  //fnChangeBaseJM

  {ITM_HOMEx3,           JC_HOME_TRIPLE,         CB_JC},  //SetSetting
  {ITM_MYMx3,            JC_MYM_TRIPLE,          CB_JC},  //SetSetting

  {ITM_BASE_HOME,        JC_BASE_HOME,           CB_JC},  //SetSetting
  {ITM_BASE_MYM,         JC_BASE_MYM,            CB_JC},  //SetSetting


  {ITM_GAPDOT_L,         ITM_DOT,                RB_IP},
  {ITM_GAPWIDDOT_L,      ITM_WDOT,               RB_IP},
  {ITM_GAPPER_L,         ITM_PERIOD,             RB_IP},
  {ITM_GAPWIDPER_L,      ITM_WPERIOD,            RB_IP},
  {ITM_GAPCOM_L,         ITM_COMMA,              RB_IP},
  {ITM_GAPWIDCOM_L,      ITM_WCOMMA,             RB_IP},
  {ITM_GAPAPO_L,         ITM_QUOTE,              RB_IP},
  {ITM_GAPNARAPO_L,      ITM_NQUOTE,             RB_IP},
  {ITM_GAPSPC_L,         ITM_SPACE_PUNCTUATION,  RB_IP},
  {ITM_GAPNARSPC_L,      ITM_SPACE_4_PER_EM,     RB_IP},
  {ITM_GAPDBLSPC_L,      ITM_SPACE_EM,           RB_IP},
  {ITM_GAPUND_L,         ITM_UNDERSCORE,         RB_IP},
  {ITM_GAPNIL_L,         ITM_NULL,               RB_IP},
  {ITM_GAPDOT_R,         ITM_DOT,                RB_FP},
  {ITM_GAPWIDDOT_R,      ITM_WDOT,               RB_FP},
  {ITM_GAPPER_R,         ITM_PERIOD,             RB_FP},
  {ITM_GAPWIDPER_R,      ITM_WPERIOD,            RB_FP},
  {ITM_GAPCOM_R,         ITM_COMMA,              RB_FP},
  {ITM_GAPWIDCOM_R,      ITM_WCOMMA,             RB_FP},
  {ITM_GAPAPO_R,         ITM_QUOTE,              RB_FP},
  {ITM_GAPNARAPO_R,      ITM_NQUOTE,             RB_FP},
  {ITM_GAPSPC_R,         ITM_SPACE_PUNCTUATION,  RB_FP},
  {ITM_GAPNARSPC_R,      ITM_SPACE_4_PER_EM,     RB_FP},
  {ITM_GAPDBLSPC_R,      ITM_SPACE_EM,           RB_FP},
  {ITM_GAPUND_R,         ITM_UNDERSCORE,         RB_FP},
  {ITM_GAPNIL_R,         ITM_NULL,               RB_FP},
  {ITM_GAPDOT_RX,        ITM_DOT,                RB_RX},
  {ITM_GAPWIDDOT_RX,     ITM_WDOT,               RB_RX},
  {ITM_GAPPER_RX,        ITM_PERIOD,             RB_RX},
  {ITM_GAPWIDPER_RX,     ITM_WPERIOD,            RB_RX},
  {ITM_GAPCOM_RX,        ITM_COMMA,              RB_RX},
  {ITM_GAPWIDCOM_RX,     ITM_WCOMMA,             RB_RX}
};


int8_t fnCbIsSet(int16_t item) {
  int8_t result = NOVAL;
  int16_t itemNr = max(item, -item);
  size_t n = nbrOfElements(indexOfRadioCbEepromItems);
  for(uint_fast8_t i = 0; i < n; i++) {
    if(indexOfRadioCbEepromItems[i].itemNr == itemNr) {
      //printf("^^^^**** item found %d\n", itemNr);
      bool_t is_cb = false;
      int32_t rb_param = 0;
      bool_t cb_param = false;

      switch(indexOfRadioCbEepromItems[i].radioButton) {
        case RB_AM:  rb_param = currentAngularMode;
                     break;

        case RB_CM:  if(getSystemFlag(FLAG_POLAR)) rb_param = CM_POLAR;
                     else                          rb_param = CM_RECTANGULAR;
                     break;

        case RB_CU:  if(getSystemFlag(FLAG_CPXj)) rb_param = CU_J;
                     else                         rb_param = CU_I;
                     break;

        case RB_DF:  if(getSystemFlag(FLAG_YMD))      rb_param = DF_YMD;
                     else if(getSystemFlag(FLAG_DMY)) rb_param = DF_DMY;
                     else                             rb_param = DF_MDY;
                     break;

        case RB_DI:  rb_param = displayFormat;
                     break;

        case RB_DO:  if(getSystemFlag(FLAG_ALLENG)) rb_param = DO_ENG;
                     else                           rb_param = DO_SCI;
                     break;

        case RB_ID:  rb_param = Input_Default;
                     break;

        case RB_IM:  rb_param = shortIntegerMode;
                     break;

        case RB_PS:  if(getSystemFlag(FLAG_MULTx)) rb_param = PS_CROSS;
                     else                          rb_param = PS_DOT;
                     break;

        case RB_WS:  rb_param = shortIntegerWordSize;
                     break;

        case RB_SS:  if(getSystemFlag(FLAG_SSIZE8)) rb_param = SS_8;
                     else                           rb_param = SS_4;
                     break;

        case RB_TF:  if(getSystemFlag(FLAG_TDM24)) rb_param = TF_H24;
                     else                          rb_param = TF_H12;
                     break;

        case RB_TV:  if(getSystemFlag(FLAG_ENDPMT)) rb_param = FN_END;
                     else                           rb_param = FN_BEG;
                     break;

        case RB_GW:  if(getSystemFlag(FLAG_GROW))   rb_param = ITM_M_GROW;
                     else                           rb_param = ITM_M_WRAP;
                     break;

        case RB_F:   rb_param = LongPressF;
                     break;

        case RB_M:   rb_param = LongPressM;
                     break;

        case RB_FG:  rb_param = fgLN;
                     break;

        case RB_BCD: rb_param = bcdDisplaySign;
                     break;

        case RB_SA:  rb_param = 16384 + Norm_Key_00_VAR;
                     //printf("^^^^*** activated %d\n", rb_param);
                     break;

        case RB_HX:  if(lastIntegerBase != 0) rb_param = lastIntegerBase;
                     else                     return result;
                     break;

        case RB_FP:  rb_param = gapItemRight;
                     break;

        case RB_IP:  rb_param = gapItemLeft;
                     break;

        case RB_RX:  rb_param = gapItemRadix;
                     break;

        case RB_PRN: if(getSystemFlag(FLAG_PRTACT)) rb_param = PRTACT1;
                     else                           rb_param = PRTACT0;
                     break;

        case CB_JC:  is_cb = true;
          switch(indexOfRadioCbEepromItems[i].param) {
            case JC_LINEAR_FITTING:      cb_param = ((lrSelection & CF_LINEAR_FITTING)      == CF_LINEAR_FITTING     ); break;
            case JC_EXPONENTIAL_FITTING: cb_param = ((lrSelection & CF_EXPONENTIAL_FITTING) == CF_EXPONENTIAL_FITTING); break;
            case JC_LOGARITHMIC_FITTING: cb_param = ((lrSelection & CF_LOGARITHMIC_FITTING) == CF_LOGARITHMIC_FITTING); break;
            case JC_POWER_FITTING:       cb_param = ((lrSelection & CF_POWER_FITTING)       == CF_POWER_FITTING      ); break;
            case JC_ROOT_FITTING:        cb_param = ((lrSelection & CF_ROOT_FITTING)        == CF_ROOT_FITTING       ); break;
            case JC_HYPERBOLIC_FITTING:  cb_param = ((lrSelection & CF_HYPERBOLIC_FITTING)  == CF_HYPERBOLIC_FITTING ); break;
            case JC_PARABOLIC_FITTING:   cb_param = ((lrSelection & CF_PARABOLIC_FITTING)   == CF_PARABOLIC_FITTING  ); break;
            case JC_CAUCHY_FITTING:      cb_param = ((lrSelection & CF_CAUCHY_FITTING)      == CF_CAUCHY_FITTING     ); break;
            case JC_GAUSS_FITTING:       cb_param = ((lrSelection & CF_GAUSS_FITTING)       == CF_GAUSS_FITTING      ); break;
            case JC_ORTHOGONAL_FITTING:  cb_param = (orOrtho(lrSelection)                   == CF_ORTHOGONAL_FITTING ); break;
            case JC_BCR:                 cb_param = getSystemFlag(FLAG_CPXRES);                                       break;
            case JC_FRC:                 cb_param = getSystemFlag(FLAG_FRCSRN);                                       break;
            case JC_BSR:                 cb_param = getSystemFlag(FLAG_SPCRES);                                       break;
            case JC_BLZ:                 cb_param = getSystemFlag(FLAG_LEAD0);                                        break;
            case PR_HPRP:                cb_param = getSystemFlag(FLAG_HPRP);                                         break;
            case PR_HPBASE:              cb_param = getSystemFlag(FLAG_HPBASE);                                       break;
            case PR_2TO10:               cb_param = getSystemFlag(FLAG_2TO10);                                        break;
            case DM_ANY:                 cb_param = getSystemFlag(FLAG_DENANY);                                       break;
            case DM_FIX:                 cb_param = getSystemFlag(FLAG_DENFIX);                                       break;
            case DM_PROPFR:              cb_param = getSystemFlag(FLAG_PROPFR);                                       break;
            case DM_FRACT:               cb_param = getSystemFlag(FLAG_FRACT);                                        break;
            case PRTACT:                 cb_param = getSystemFlag(FLAG_PRTACT);                                       break;
            case JC_ERPN:                cb_param = eRPN;                                                             break;
            case JC_G_DOUBLETAP:         cb_param = jm_G_DOUBLETAP;                                                   break;
            case JC_SHFT_4s:             cb_param = ShiftTimoutMode;                                                  break;
            case JC_VECT:                cb_param = PLOT_VECT;                                                        break;
            case JC_NVECT:               cb_param = PLOT_NVECT;                                                       break;
            case JC_SCALE:               cb_param = PLOT_SCALE;                                                       break;
            case JC_LARGELI:             cb_param = jm_LARGELI;                                                       break;
            case JC_IRFRAC:              cb_param = constantFractions;                                                break;
            case JC_EXTENTX:             cb_param = !extentx;                                                         break;
            case JC_EXTENTY:             cb_param = !extenty;                                                         break;
            case JC_PLINE:               cb_param = PLOT_LINE;                                                        break;
            case JC_PCROS:               cb_param = PLOT_CROSS;                                                       break;
            case JC_PBOX:                cb_param = PLOT_BOX;                                                         break;
            case JC_DIFF:                cb_param = PLOT_DIFF;                                                        break;
            case JC_INTG:                cb_param = PLOT_INTG;                                                        break;
            case JC_RMS:                 cb_param = PLOT_RMS;                                                         break;
            case JC_SHADE:               cb_param = PLOT_SHADE;                                                       break;
            case JC_CPXPLT:              cb_param = PLOT_CPXPLT;                                                      break;
            case JC_NL:                  cb_param = numLock;                                                          break;
            case JC_UC:                  cb_param = !alphaCase;                                                       break;
            case JC_UU:                  cb_param = getSystemFlag(FLAG_USER);                                         break;
            case JC_LPfg:                cb_param = getSystemFlag(FLAG_SH_LONGPRESS);                                         break;
            case JC_SS:                  cb_param = scrLock != NC_NORMAL;                                             break;
            case JC_BCD:                 cb_param = bcdDisplay;                                                       break;
            case JC_TOPHEX:              cb_param = topHex;                                                           break;
            case JC_SI_All:              cb_param = SI_All;                                                           break;
            case JC_CPXMULT:             cb_param = CPXMULT;                                                          break;
            case JC_MYM_TRIPLE:          cb_param = MYM3;
                                         if(MYM3 && HOME3) MYM3 = false;
                                         break;
            case JC_HOME_TRIPLE:         cb_param = HOME3;
                                         if(MYM3 && HOME3) MYM3 = false;
                                         break;
            case JC_BASE_HOME:           cb_param = BASE_HOME;
                                         if(BASE_HOME && BASE_MYM) BASE_HOME = false;
                                         break;
            case JC_BASE_MYM:            cb_param = BASE_MYM;
                                         if(BASE_HOME && BASE_MYM) BASE_HOME = false;
                                         break;
            #if defined(INLINE_TEST)
              case JC_ITM_TST:           cb_param = testEnabled;                                                      break;
            #endif // INLINE_TEST

            default: ;
          }

          default: ;
      }

      if(is_cb) {
        //printf("^^^^*** %d %d\n", indexOfRadioCbEepromItems[i].param, cb_param);
        result = cb_param ? CB_TRUE : CB_FALSE;
      }
      else {
        //printf("^^^^*** %d %d\n", indexOfRadioCbEepromItems[i].param, rb_param);
        result = (indexOfRadioCbEepromItems[i].param == rb_param ? RB_TRUE : RB_FALSE);
      }
    }
  }

  return result;
}


void fnRefreshState(void) {                      // 2023-07-18 This seems antiquated. If it has no effect, all calls to fnRefreshState can be removed. Leaving commented for a while.
  #if !defined(TESTSUITE_BUILD)
    doRefreshSoftMenu = true;
  #endif //!TESTSUITE_BUILD
}


int16_t fnItemShowValue(int16_t item) {
  int16_t result = NOVAL;
  uint16_t itemNr = max(item, -item);
  switch(itemNr) {
    case ITM_DSTACK:    result = displayStack;                                      break; //  132
    case ITM_TDISP:     result = timeDisplayFormatDigits;                           break;
    case ITM_SHOIREP:   result = displayStackSHOIDISP;                              break;
    case ITM_FIX:       if(displayFormat == DF_FIX) result = displayFormatDigits;   break; //  185
    case ITM_SIGFIG:    if(displayFormat == DF_SF)  result = displayFormatDigits;   break; // 1682
    case ITM_ENG:       if(displayFormat == DF_ENG) result = displayFormatDigits;   break; //  145
    case ITM_UNIT:      if(displayFormat == DF_UN)  result = displayFormatDigits;   break; // 1693
    case ITM_SCI:       if(displayFormat == DF_SCI) result = displayFormatDigits;   break; //  545
    case ITM_ALL:       if(displayFormat == DF_ALL) result = displayFormatDigits;   break; //   20
    case ITM_PZOOMX:    result = PLOT_ZMX;                                          break;
    case ITM_PZOOMY:    result = PLOT_ZMY;                                          break;
    case ITM_PLOTZOOM:  result = -PLOT_ZOOM;                                        break;
    case ITM_WSIZE:     result = shortIntegerWordSize;                              break; //  664
    case ITM_RNG:       result = exponentLimit;                                     break;
    case ITM_DENMAX2:   result = denMax;                                            break;
    case ITM_SETSIG2:   result = (significantDigits == 0 ? 34 : significantDigits); break;
    case ITM_DSPCYCLE:  result = 32700 + displayFormat;                             break;
    case ITM_SCR:       result = (scrLock & 0x03) | (nextChar & 0x03);              break;
    case ITM_DSP:       result = displayFormatDigits;                               break;
    case ITM_HIDE:      result = exponentHideLimit;                                 break;
    case ITM_BESTF:     result = (lrSelection) & 0x1FF;                             break;
    case ITM_RMODE:     result = roundingMode;                                      break;
    case ITM_HASH_JM:   if(lastIntegerBase != 0) result = (int16_t)lastIntegerBase; break;
    case ITM_VOL:
    case ITM_VOLPLUS:
    case ITM_VOLMINUS:
                        result = getBeepVolume();                                   break; // DL
    default:            if(indexOfItems[itemNr].func == itemToBeCoded) {
                         result = ITEM_NOT_CODED;
                        }
  }
  return result;
}


char tmp[16];
void add_digitglyph_to_tmp2(char* tmp2, int16_t xx) {
  tmp2[0] = 0;

  stringAppend(tmp2, STD_SUB_0);
  if(xx >= 1 && xx <= 16) {
    stringAppend(tmp2, STD_BASE_1);
    tmp2[1] += (xx-1);
  }

//  switch(xx) {
//    case  0: stringAppend(tmp2 + stringByteLength(tmp2), STD_SUB_0);   break;
//    case  1: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_1);  break;
//    case  2: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_2);  break;
//    case  3: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_3);  break;
//    case  4: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_4);  break;
//    case  5: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_5);  break;
//    case  6: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_6);  break;
//    case  7: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_7);  break;
//    case  8: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_8);  break;
//    case  9: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_9);  break;
//    case 10: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_10); break;
//    case 11: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_11); break;
//    case 12: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_12); break;
//    case 13: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_13); break;
//    case 14: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_14); break;
//    case 15: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_15); break;
//    case 16: stringAppend(tmp2 + stringByteLength(tmp2), STD_BASE_16); break;
//    default: ;
//  }
}


void use_base_glyphs(char* tmp1, int16_t xx) {              // Needs non-local variable tmp2
  char tmp2[16];
  tmp1[0] = 0;

  if(xx <= 16) {
    add_digitglyph_to_tmp2(tmp2, xx); stringAppend(tmp1 + stringByteLength(tmp1), tmp2);
  }
  else if(xx <= 99) {
    add_digitglyph_to_tmp2(tmp2, xx / 10); stringAppend(tmp1 + stringByteLength(tmp1), tmp2);
    add_digitglyph_to_tmp2(tmp2, xx % 10); stringAppend(tmp1 + stringByteLength(tmp1), tmp2);
  }
  else if(xx <= 999) {
    add_digitglyph_to_tmp2(tmp2,  xx / 100);         stringAppend(tmp1 + stringByteLength(tmp1), tmp2);
    add_digitglyph_to_tmp2(tmp2, (xx % 100) / 10);   stringAppend(tmp1 + stringByteLength(tmp1), tmp2);
    add_digitglyph_to_tmp2(tmp2, (xx % 100) % 10);   stringAppend(tmp1 + stringByteLength(tmp1), tmp2);
  }
  else if(xx <= 9999) {
    add_digitglyph_to_tmp2(tmp2,   xx / 1000);                stringAppend(tmp1 + stringByteLength(tmp1), tmp2);     //9876 > 9
    add_digitglyph_to_tmp2(tmp2,  (xx % 1000) / 100);         stringAppend(tmp1 + stringByteLength(tmp1), tmp2);     //876  > 8
    add_digitglyph_to_tmp2(tmp2, ((xx % 1000) % 100) / 10);   stringAppend(tmp1 + stringByteLength(tmp1), tmp2);     //76   > 7
    add_digitglyph_to_tmp2(tmp2, ((xx % 1000) % 100) % 10);   stringAppend(tmp1 + stringByteLength(tmp1), tmp2);     //6
  }
  else {
    snprintf(tmp1, 12, "%d", xx);
  }
}


char *figlabel(const char *label, const char* showText, int16_t showValue) {      //JM
  //uint16_t ii=0;
  //while(label[ii] != 0) {
  //  printf("(%u)=%c=%u ", ii, label[ii], label[ii]);
  //  ii++;
  //}
  //printf(">>>>> %1u %1u\n", (uint8_t)showText[strlen(showText)-2], (uint8_t)showText[strlen(showText)-1]);
  //printf("\n");

  char tmp1[16];
  tmp[0] = 0;

  if(stringByteLength(label) <= 15) {
    stringAppend(tmp, label);
  }

  if(showValue != NOVAL && showValue != ITEM_NOT_CODED && showValue < 0) {
    stringAppend(tmp + stringByteLength(tmp), STD_SUB_MINUS);
  }

  if(showValue != NOVAL && showValue != ITEM_NOT_CODED && stringByteLength(label) <= 8) {
    showValue = max(showValue, -showValue);
    use_base_glyphs(tmp1, showValue);
    stringAppend(tmp + stringByteLength(tmp), tmp1);
  }

  if(showText[0] != 0 && stringByteLength(tmp)+stringByteLength(showText) + 1 <= 15) {
    //stringAppend(tmp + stringByteLength(tmp), showText);
    uint16_t ii = 0;
    while(showText[ii] != 0) {
      if(showText[ii]>='A' && showText[ii]<='Z') {
        stringAppend(tmp + stringByteLength(tmp), STD_SUB_A);
        tmp[stringByteLength(tmp)-1] += showText[ii]-'A';
      }
      else if(showText[ii]>='0' && showText[ii]<='9') {
        stringAppend(tmp + stringByteLength(tmp), STD_SUB_0);
        tmp[stringByteLength(tmp)-1] += showText[ii]-'0';
      }
      else {
        switch(showText[ii]) {
          case '+':  stringAppend(tmp + stringByteLength(tmp), STD_SUB_PLUS);   break;
          case ',':  stringAppend(tmp + stringByteLength(tmp), STD_COMMA);      break;
          case '-':  stringAppend(tmp + stringByteLength(tmp), STD_SUB_MINUS);  break;
          case '.':  stringAppend(tmp + stringByteLength(tmp), STD_PERIOD);     break;
          case '_':  stringAppend(tmp + stringByteLength(tmp), STD_UNDERSCORE); break;
          case ' ':  stringAppend(tmp + stringByteLength(tmp), STD_OPEN_BOX);   break;
          case '\'': stringAppend(tmp + stringByteLength(tmp), STD_QUOTE);      break;
          default: {
            uint16_t tmpi = (uint16_t)((((uint8_t)(showText[ii]) & 0x00FF)) << 8) + (uint16_t)((uint8_t)(showText[ii+1]));
            if(0x0101 == tmpi) {
              stringAppend(tmp + stringByteLength(tmp), STD_o_STROKE);
              ii++;
            }

            //any other characters won't have actual subscript conversions and are returned translated, or as is
            //printf(">>>> %u %u\n", (uint8_t)showText[ii], (uint8_t)showText[ii+1]);
            else if((showText[ii] & 0x80) && (showText[ii+1] != 0)) {
              char tt[3];
              tt[0] = 0;
              tt[1] = 0;
              tt[2] = 0;

              if(((uint16_t)(STD_SPACE_PUNCTUATION[0] & 0x00FF) << 8) + (STD_SPACE_PUNCTUATION[1] & 0x00FF) == tmpi) {
                stringAppend(tmp + stringByteLength(tmp), STD_OPEN_BOX);
                ii++;
              }

              else if(((uint16_t)(STD_SPACE_4_PER_EM[0] & 0x00FF) << 8) + (STD_SPACE_4_PER_EM[1] & 0x00FF) == tmpi) {
                stringAppend(tmp + stringByteLength(tmp), STD_INV_BRIDGE);
                ii++;
              }

              else if(((uint16_t)(STD_SPACE_EM[0] & 0x00FF) << 8) + (STD_SPACE_EM[1] & 0x00FF) == tmpi) {
                stringAppend(tmp + stringByteLength(tmp), STD_OPEN_BOX STD_OPEN_BOX);
                ii++;
              }

              else { //double byte
                //printf(">>>> Double byte in RB\n");
                tt[0] = showText[ii++];
                tt[1] = showText[ii];
                stringAppend(tmp + stringByteLength(tmp), tt);
              }
            }

            else { //single byte
              //printf(">>>> Single byte in RB\n");
              char tt[2];
              tt[0] = showText[ii];
              tt[1] = 0;
              stringAppend(tmp + stringByteLength(tmp), tt);
            }
          }
        }
      }
      ii++;
    }
  }
  compressConversionName(tmp);
  return tmp;
}                                                           //JM ^^
