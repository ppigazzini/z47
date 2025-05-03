// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//**
 * \file radioButtonCatalog.c
 ***********************************************/

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

  {ITM_1COMPL,           SIM_1COMPL,             RB_IM},  //fnIntegerMode
  {ITM_2COMPL,           SIM_2COMPL,             RB_IM},  //fnIntegerMode
  {ITM_SIGNMT,           SIM_SIGNMT,             RB_IM},  //fnIntegerMode
  {ITM_UNSIGN,           SIM_UNSIGN,             RB_IM},  //fnIntegerMode
  {ITM_WS8,              8,                      RB_WS},  //fnSetWordSize
  {ITM_WS16,             16,                     RB_WS},  //fnSetWordSize
  {ITM_WS32,             32,                     RB_WS},  //fnSetWordSize
  {ITM_WS64,             64,                     RB_WS},  //fnSetWordSize

  {ITM_N_KEY_ALPHA,      16384+ITM_AIM,          RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_FSH,        16384+ITM_SHIFTf,       RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_GSH,        16384+ITM_SHIFTg,       RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_FGSH,       16384+KEY_fg,           RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_USER,       16384+ITM_USERMODE,     RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_SIGMA,      16384+ITM_SIGMAPLUS,    RB_SA},  //fnSigmaAssign
  {ITM_N_KEY_NIL,        16384+ITM_NULL,         RB_SA},  //fnSigmaAssign


  {ITM_F1234,            RBX_F1234,              RB_F },   //
  {ITM_M1234,            RBX_M1234,              RB_M },   //
  {ITM_F14,              RBX_F14,                RB_F },   //
  {ITM_M14,              RBX_M14,                RB_M },   //
  {ITM_F124,             RBX_F124,               RB_F },   //
  {ITM_M124,             RBX_M124,               RB_M },   //
  {ITM_FGLNOFF,          RBX_FGLNOFF,            RB_FG},  //
  {ITM_FGLNLIM,          RBX_FGLNLIM,            RB_FG},  //
  {ITM_FGLNFUL,          RBX_FGLNFUL,            RB_FG},  //

  {ITM_BCDU,             BCDu,                   RB_BCD}, //
  {ITM_BCD9,             BCD9c,                  RB_BCD}, //
  {ITM_BCD10,            BCD10c,                 RB_BCD}, //

  {ITM_M_GROW,           ITM_M_GROW,             RB_GW},  // SFL_PRTACT
  {ITM_M_WRAP,           ITM_M_WRAP,             RB_GW},  // SFL_PRTACT

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

  {ITM_USER_C47,         USER_C47,               RB_KY},  //SetSetting
  {ITM_USER_DM42,        USER_DM42,              RB_KY},  //SetSetting
  {ITM_USER_R47,         USER_R47,               RB_KY},  //SetSetting
  {ITM_USER_EXPR,        USER_EXPR,              RB_KY},  //SetSetting

  {ITM_USER_V47,         USER_V47,               CB_JC},  //SetSetting
  {ITM_USER_D47,         USER_D47,               CB_JC},  //SetSetting
  {ITM_USER_N47,         USER_N47,               CB_JC},  //SetSetting
  {ITM_USER_E47,         USER_E47,               CB_JC},  //SetSetting
  {ITM_USER_R47f_g,      USER_R47f_g,            CB_JC},  //SetSetting
  {ITM_USER_R47bk_fg,    USER_R47bk_fg,          CB_JC},  //SetSetting
  {ITM_USER_R47fg_bk,    USER_R47fg_bk,          CB_JC},  //SetSetting
  {ITM_USER_R47fg_g,     USER_R47fg_g,           CB_JC},  //SetSetting

  {ITM_G_DOUBLETAP,      JC_G_DOUBLETAP,         CB_JC},  //SetSetting
  {ITM_SHTIM,            JC_SHFT_4s,             CB_JC},  //SetSetting

  {ITM_TEST,             JC_ITM_TST,             CB_JC},  //fnSetInlineTest
  {ITM_INTG,             JC_INTG,                CB_JC},  //
  {ITM_DIFF,             JC_DIFF,                CB_JC},  //
  {ITM_RMS,              JC_RMS,                 CB_JC},  //
  {ITM_SHADE,            JC_SHADE,               CB_JC},  //

  {ITM_CB_CPXRES,        FLAG_CPXRES ,           CB_JC},  //SetSetting
  {ITM_CB_SPCRES,        FLAG_SPCRES ,           CB_JC},  //SetSetting
  {ITM_CB_LEADING_ZERO,  FLAG_LEAD0  ,           CB_JC},  //SetSetting
  {ITM_HPRP,             FLAG_HPRP   ,           CB_JC},
  {ITM_MNUp1 ,           FLAG_MNUp1  ,           CB_JC},
  {ITM_HPBASE,           FLAG_HPBASE ,           CB_JC},
  {ITM_2TO10,            FLAG_2TO10  ,           CB_JC},
  {ITM_DENANY,           FLAG_DENANY ,           CB_JC},
  {ITM_DENFIX,           FLAG_DENFIX ,           CB_JC},
  {ITM_PROPFR,           FLAG_PROPFR ,           CB_JC},
  {ITM_FRACT,            FLAG_FRACT  ,           CB_JC},
  {ITM_PRTACT,           FLAG_PRTACT ,           CB_JC},  // SFL_PRTACT
  {ITM_ERPN,             FLAG_ERPN   ,           CB_JC},  //SetSetting
  {ITM_FRCYC,            FLAG_FRCYC  ,           CB_JC},
  {ITM_LARGELI,          FLAG_LARGELI,           CB_JC},  //SetSetting
  {ITM_IRFRAC,           FLAG_IRFRAC ,           CB_JC},  //SetSetting
  {ITM_CPXPLOT,          FLAG_CPXPLOT,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_SHOWX,            FLAG_SHOWX  ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_SHOWY,            FLAG_SHOWY  ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_PBOX,             FLAG_PBOX   ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_PCROS,            FLAG_PCROS  ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_PPLUS,            FLAG_PPLUS  ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_PLINE,            FLAG_PLINE  ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_SCALE,            FLAG_SCALE  ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_VECT,             FLAG_VECT   ,           CB_JC},  // graph EQN & PLSTAT options
  {ITM_NVECT,            FLAG_NVECT  ,           CB_JC},  // graph EQN & PLSTAT options
  {CHR_num,              FLAG_NUMLOCK     ,      CB_JC},  //
  {ITM_USERMODE,         FLAG_USER        ,      CB_JC},  //
  {ITM_SH_LONGPRESS,     FLAG_SH_LONGPRESS,      CB_JC},  //
  {ITM_DREAL,            FLAG_DREAL       ,      CB_JC},  //
  {ITM_CPXMULT,          FLAG_CPXMULT,           CB_JC},  //


  {CHR_case,             JC_UC,                  CB_JC},  //
  {ITM_SCR,              JC_SS,                  CB_JC},  //
  {ITM_BCD,              JC_BCD,                 CB_JC},  //
  {ITM_TOPHEX,           FLAG_TOPHEX,            CB_JC},  //

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

  if(itemNotAvail(item)) {
    return result;
  }

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

        case RB_DO:  if(getSystemFlag(FLAG_ENGOVR)) rb_param = DO_ENG;
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

        case RB_SA:  rb_param = 16384 + Norm_Key_00.func;
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

        case RB_KY:  rb_param = calcModel;
                     if(itemNr == ITM_USER_EXPR) {
                       switch(calcModel) {
                         case USER_D47 :
                         case USER_E47 :
                         case USER_N47 :
                         case USER_V47 : rb_param = USER_EXPR; break;
                         default:;
                       }
                     }
                     if(itemNr == ITM_USER_R47) {
                       switch(calcModel) {
                         case USER_R47f_g   :
                         case USER_R47bk_fg :
                         case USER_R47fg_bk :
                         case USER_R47fg_g  : rb_param = USER_R47; break;
                         default:;
                       }
                     }
                     break;

        case CB_JC:  is_cb = true;
          switch(indexOfRadioCbEepromItems[i].param) {

            case USER_D47:
            case USER_E47:
            case USER_N47:
            case USER_V47:
            case USER_R47f_g:
            case USER_R47bk_fg:
            case USER_R47fg_bk:
            case USER_R47fg_g:           cb_param = calcModel == indexOfRadioCbEepromItems[i].param; break;

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

            case JC_G_DOUBLETAP:         cb_param = jm_G_DOUBLETAP;                                                   break;
            case JC_SHFT_4s:             cb_param = ShiftTimoutMode;                                                  break;
            case JC_DIFF:                cb_param = PLOT_DIFF;                                                        break;
            case JC_INTG:                cb_param = PLOT_INTG;                                                        break;
            case JC_RMS:                 cb_param = PLOT_RMS;                                                         break;
            case JC_SHADE:               cb_param = PLOT_SHADE;                                                       break;

            case FLAG_CPXRES :
            case FLAG_SPCRES :
            case FLAG_LEAD0  :
            case FLAG_HPRP   :
            case FLAG_MNUp1  :
            case FLAG_HPBASE :
            case FLAG_2TO10  :
            case FLAG_DENANY :
            case FLAG_DENFIX :
            case FLAG_PROPFR :
            case FLAG_FRACT  :
            case FLAG_PRTACT :
            case FLAG_ERPN   :
            case FLAG_FRCYC  :
            case FLAG_LARGELI:
            case FLAG_IRFRAC :
            case FLAG_CPXPLOT:
            case FLAG_SHOWX  :
            case FLAG_SHOWY  :
            case FLAG_PBOX   :
            case FLAG_PCROS  :
            case FLAG_PPLUS  :
            case FLAG_PLINE  :
            case FLAG_SCALE  :
            case FLAG_VECT   :
            case FLAG_NVECT  :
            case FLAG_NUMLOCK     :
            case FLAG_USER        :
            case FLAG_SH_LONGPRESS:
            case FLAG_DREAL       :
            case FLAG_CPXMULT     :
            case FLAG_TOPHEX      :
                       cb_param = getSystemFlag(indexOfRadioCbEepromItems[i].param);                break;

            case JC_UC:                  cb_param = !alphaCase;                                                       break;
            case JC_SS:                  cb_param = scrLock != NC_NORMAL;                                             break;
            case JC_BCD:                 cb_param = bcdDisplay;                                                       break;
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
    case ITM_MZOOMY:
    case ITM_PZOOMY:    result = calcMode == CM_PLOT_STAT ? PLOT_ZOOM : PLOT_ZMY;   break;
    case ITM_WSIZE:     result = shortIntegerWordSize;                              break; //  664
    case ITM_RNG:       result = exponentLimit;                                     break;
    case ITM_BASENR:    result = dispBase;                                          break;
    case ITM_SETSIG2:   result = (significantDigits == 0 ? 34 : significantDigits); break;
    case ITM_SETFDIGS:  result = (fractionDigits == 0 ? 34 : fractionDigits);       break;
    case ITM_DSPCYCLE:  result = 32700 + displayFormat;                             break;
    case ITM_SCR:       result = (scrLock & 0x03) | (nextChar & 0x03);              break;
    case ITM_DSP:       result = displayFormatDigits;                               break;
    case ITM_HIDE:      result = exponentHideLimit;                                 break;
    case ITM_BESTF:     result = (lrSelection) & 0x1FF;                             break;
    case ITM_RMODE:     result = roundingMode;                                      break;
    case ITM_HASH_JM:   if(lastIntegerBase != 0) result = (int16_t)lastIntegerBase; break;
    case ITM_TIMER_SIGMA_L:
    case ITM_TIMER_SIGMA_T: result = statisticalSumsPointer == NULL ? 0 : realToUint32C47(SIGMA_N); break;
    case ITM_TIMER_R_L:
    case ITM_TIMER_R_T:     result = timerCraAndDeciseconds &0x7F; break;
    case ITM_VOL:
    case ITM_VOLPLUS:
    case ITM_VOLMINUS:  result = getBeepVolume();                                   break; // DL
    case ITM_YY_DFLT:   result = lastCenturyHighUsed & 0x3FFF;                        break;
    default:            if(indexOfItems[itemNr].func == itemToBeCoded) {
                         result = ITEM_NOT_CODED;
                        }
  }
  return result;
}


char tmp[16];
void add_digitglyph_to_tmp2(char* tmp2, int16_t xx) {
  tmp2[0] = 0;

  stringCopy(tmp2, STD_BASE_0);     //can also be STD_SUB_0 for a slightly raised look
  if(1 <= xx && xx <= 16) {
    stringCopy(tmp2, STD_BASE_1);   //can also be STD_SUB_1 for a slightly raised look
    tmp2[1] += (xx-1);
  }
}


void use_base_glyphs(char* tmp1, int16_t xx) {              // Needs non-local variable tmp2
  char tmp2[16];
  tmp1[0] = 0;

  if(xx <= 16) {
    add_digitglyph_to_tmp2(tmp2, xx); stringCopy(tmp1, tmp2);
  }
  else if(xx <= 99) {
    add_digitglyph_to_tmp2(tmp2, xx / 10); stringCopy(tmp1,                          tmp2);
    add_digitglyph_to_tmp2(tmp2, xx % 10); stringCopy(tmp1 + stringByteLength(tmp1), tmp2);
  }
  else if(xx <= 999) {
    add_digitglyph_to_tmp2(tmp2,  xx / 100);         stringCopy(tmp1,                          tmp2);
    add_digitglyph_to_tmp2(tmp2, (xx % 100) / 10);   stringCopy(tmp1 + stringByteLength(tmp1), tmp2);
    add_digitglyph_to_tmp2(tmp2, (xx % 100) % 10);   stringCopy(tmp1 + stringByteLength(tmp1), tmp2);
  }
  else if(xx <= 9999) {
    add_digitglyph_to_tmp2(tmp2,   xx / 1000);                stringCopy(tmp1,                          tmp2);     //9876 > 9
    add_digitglyph_to_tmp2(tmp2,  (xx % 1000) / 100);         stringCopy(tmp1 + stringByteLength(tmp1), tmp2);     //876  > 8
    add_digitglyph_to_tmp2(tmp2, ((xx % 1000) % 100) / 10);   stringCopy(tmp1 + stringByteLength(tmp1), tmp2);     //76   > 7
    add_digitglyph_to_tmp2(tmp2, ((xx % 1000) % 100) % 10);   stringCopy(tmp1 + stringByteLength(tmp1), tmp2);     //6
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
    stringCopy(tmp, label);
  }

  if(showValue != NOVAL && showValue != ITEM_NOT_CODED && showValue < 0) {
    stringCopy(tmp + stringByteLength(tmp), STD_SUB_MINUS);
  }

  if(showValue != NOVAL && showValue != ITEM_NOT_CODED && stringByteLength(label) <= 8) {
    showValue = max(showValue, -showValue);
    use_base_glyphs(tmp1, showValue);
    stringCopy(tmp + stringByteLength(tmp), tmp1);
  }

  if(showText[0] != 0 && stringByteLength(tmp)+stringByteLength(showText) + 1 <= 15) {
    //stringCopy(tmp + stringByteLength(tmp), showText);
    uint16_t ii = 0;
    while(showText[ii] != 0) {
      if(showText[ii]>='A' && showText[ii]<='Z') {
        stringCopy(tmp + stringByteLength(tmp), STD_SUB_A);
        tmp[stringByteLength(tmp)-1] += showText[ii]-'A';
      }
      else if(showText[ii]>='0' && showText[ii]<='9') {
        stringCopy(tmp + stringByteLength(tmp), STD_SUB_0);
        tmp[stringByteLength(tmp)-1] += showText[ii]-'0';
      }
      else {
        switch(showText[ii]) {
          case '+':  stringCopy(tmp + stringByteLength(tmp), STD_SUB_PLUS);   break;
          case ',':  stringCopy(tmp + stringByteLength(tmp), STD_COMMA);      break;
          case '-':  stringCopy(tmp + stringByteLength(tmp), STD_SUB_MINUS);  break;
          case '.':  stringCopy(tmp + stringByteLength(tmp), STD_PERIOD);     break;
          case '_':  stringCopy(tmp + stringByteLength(tmp), STD_UNDERSCORE); break;
          case ' ':  stringCopy(tmp + stringByteLength(tmp), STD_OPEN_BOX);   break;
          case '\'': stringCopy(tmp + stringByteLength(tmp), STD_QUOTE);      break;
          default: {
            uint16_t tmpi = (uint16_t)((((uint8_t)(showText[ii]) & 0x00FF)) << 8) + (uint16_t)((uint8_t)(showText[ii+1]));
            if(0x0101 == tmpi) {
              stringCopy(tmp + stringByteLength(tmp), STD_o_STROKE);
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
                stringCopy(tmp + stringByteLength(tmp), STD_OPEN_BOX);
                ii++;
              }

              else if(((uint16_t)(STD_SPACE_4_PER_EM[0] & 0x00FF) << 8) + (STD_SPACE_4_PER_EM[1] & 0x00FF) == tmpi) {
                stringCopy(tmp + stringByteLength(tmp), STD_INV_BRIDGE);
                ii++;
              }

              else if(((uint16_t)(STD_SPACE_EM[0] & 0x00FF) << 8) + (STD_SPACE_EM[1] & 0x00FF) == tmpi) {
                stringCopy(tmp + stringByteLength(tmp), STD_OPEN_BOX STD_OPEN_BOX);
                ii++;
              }

              else { //double byte
                //printf(">>>> Double byte in RB\n");
                tt[0] = showText[ii++];
                tt[1] = showText[ii];
                stringCopy(tmp + stringByteLength(tmp), tt);
              }
            }

            else { //single byte
              //printf(">>>> Single byte in RB\n");
              char tt[2];
              tt[0] = showText[ii];
              tt[1] = 0;
              stringCopy(tmp + stringByteLength(tmp), tt);
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
