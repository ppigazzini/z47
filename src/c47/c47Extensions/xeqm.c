// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//**
 * \file xeqm.c
 ***********************************************/

#include "c47Extensions/xeqm.h"

#include "bufferize.h"
#include "calcMode.h"
#include "charString.h"
#include "flags.h"
#include "hal/gui.h"
#include "c47Extensions/addons.h"
#include "c47Extensions/graphText.h"
#include "items.h"
#include "c47Extensions/jm.h"
#include "keyboard.h"
#include "c47Extensions/keyboardTweak.h"
#include "registers.h"
#include "screen.h"
#include "softmenus.h"
#include "stack.h"
#include "statusBar.h"
#include "timer.h"
#include "c47Extensions/textfiles.h"
#include <string.h>

#include "c47.h"

#define XEQ_STR_LENGTH_LONG  TMP_STR_LENGTH // 3000 // note the limit is the tmpString limit

bool_t strcompare(const char *in1, const char *in2) {
  if(stringByteLength(in1) == stringByteLength(in2)) {
    int16_t i = 0;
    bool_t areEqual = true;
    while(areEqual && in1[i] != 0) {
      if(in1[i] != in2[i]) {
        areEqual = false;
        return false;
      }
      i++;
    }
    return areEqual;
  }
  else {
    return false;
  }
}




typedef struct {
  uint16_t itemNr;            ///<
  char     itemName[16];         ///<
} function_t;


TO_QSPI const function_t indexOfFunctions[] = {
    //        function              functionName
//XEQM CODE 2023-10-31
              {ITM_PRIME,                     "@"},
              {ITM_ENTER,                     "ENTER"},
              {ITM_XexY,                      "X<>Y"},
              {ITM_DROP,                      "DROPX"},
              {ITM_CLX,                       "@"},
              {ITM_FILL,                      "@"},
              {ITM_STO,                       "@"},
              {ITM_COMB,                      "@"},
              {ITM_PERM,                      "@"},
              {ITM_RCL,                       "@"},
              {ITM_SQUARE,                    "X^2"},
              {ITM_CUBE,                      "X^3"},
              {ITM_YX,                        "Y^X"},
              {ITM_SQUAREROOTX,               "SQRT"},
              {ITM_CUBEROOT,                  "CUBRT"},
              {ITM_XTHROOT,                   "XRTY"},
              {ITM_2X,                        "2^X"},
              {ITM_EXP,                       "e^X"},
              {ITM_10x,                       "10^X"},
              {ITM_LOG2,                      "LOG2"},
              {ITM_LN,                        "@"},
              {ITM_LOG10,                     "LOG10"},
              {ITM_LOGXY,                     "LOGXY"},
              {ITM_1ONX,                      "1/X"},
              {ITM_cos,                       "@"},
              {ITM_cosh,                      "COSH"},
              {ITM_sin,                       "@"},
              {ITM_sinh,                      "SINH"},
              {ITM_tan,                       "@"},
              {ITM_tanh,                      "TANH"},
              {ITM_arccos,                    "ACOS"},
              {ITM_arcosh,                    "ARCOSH"},
              {ITM_arcsin,                    "ASIN"},
              {ITM_arsinh,                    "ARSINH"},
              {ITM_arctan,                    "ATAN"},
              {ITM_artanh,                    "ARTANH"},
              {ITM_GCD,                       "@"},
              {ITM_LCM,                       "@"},
              {ITM_DEC,                       "@"},
              {ITM_INC,                       "@"},
              {ITM_IP,                        "@"},
              {ITM_FP,                        "@"},
              {ITM_ADD,                       "@"},
              {ITM_SUB,                       "@"},
              {ITM_CHS,                       "@"},
              {ITM_MULT,                      "*"},
              {ITM_DIV,                       "/"},
              {ITM_IDIV,                      "@"},
              {ITM_VIEW,                      "@"},
              {ITM_AVIEW,                     "@"},
              {ITM_MOD,                       "@"},
              {ITM_MAX,                       "MAX"},
              {ITM_MIN,                       "MIN"},
              {ITM_MAGNITUDE,                 "MAGN"},
              {ITM_NEXTP,                     "@"},
              {ITM_CONSTpi,                   "PI"},
              {ITM_DEG2,                      ">>DEG"},
              {ITM_RAD2,                      ">>RAD"},
              {ITM_GRAD2,                     ">>GRAD"},
              {CST_05,                        "@"},
              {CST_74,                        "PHI"},
              {ITM_SIGMAPLUS,                 "SUM+"},
              {ITM_NSIGMA,                    "NSUM"},
              {ITM_SIGMAx,                    "SUMX"},
              {ITM_SIGMAy,                    "SUMY"},
              {ITM_REG_X,                     "@"},
              {ITM_REG_Y,                     "@"},
              {ITM_INDIRECTION,               "IND>"},
              {ITM_Max,                       "MAX"},
              {ITM_Min,                       "MIN"},
              {ITM_EXPONENT,                  "EEX"},
              {ITM_SNAP,                      "@"},
              {ITM_ABS,                       "@"},
              {ITM_ALL,                       "ALL"},
              {ITM_BATT,                      "@"},
              {ITM_CASE,                      "@"},
              {ITM_CLSTK,                     "@"},
              {ITM_CLSIGMA,                   "CLSUM"},
              {ITM_DEG,                       "@"},
              {ITM_ENG,                       "@"},
              {ITM_EXPT,                      "@"},
              {ITM_FIB,                       "@"},
              {ITM_FIX,                       "@"},
              {ITM_GD,                        "GD"},
              {ITM_GDM1,                      "GD^-1"},
              {ITM_IM,                        "IM"},
              {ITM_INDEX,                     "@"},
              {ITM_IPLUS,                     "@"},
              {ITM_IMINUS,                    "@"},
              {ITM_JPLUS,                     "@"},
              {ITM_JMINUS,                    "@"},
              {ITM_sinc,                      "SINC"},
              {ITM_MULPI,                     "MULPI"},
              {ITM_SUM,                       "SUM"},
              {ITM_sincpi,                    "SINCPI"},
              {ITM_PLOT_SCATR,                "@"},
              {ITM_RAD,                       "@"},
              {ITM_RAN,                       "@"},
              {ITM_RCLEL,                     "@"},
              {ITM_RE,                        "RE"},
              {ITM_REexIM,                    "RE<>IM"},
              {ITM_EX1,                       "e^X-1"},
              {ITM_SCI,                       "@"},
              {ITM_STOEL,                     "@"},
              {ITM_STOIJ,                     "@"},
              {ITM_LN1X,                      "LN(1+X)"},
              {ITM_TICKS,                     "@"},
              {ITM_M1X,                       "(-1)^X"},
              {ITM_toREAL,                    ">REAL"},
              {ITM_EXIT1,                     "@"},
              {ITM_AIM,                       "ALPHA"},
              {ITM_dotD,                      "DOTD"},
              {ITM_MINUTE,                    "MINUTE"},
              {KEY_COMPLEX,                   "@"},
              {ITM_toPOL2,                    ">POLAR"},
              {ITM_toREC2,                    ">RECT"},
              {ITM_eRPN_ON,                   "ERPN"},
              {ITM_eRPN_OFF,                  "@"},
              {ITM_SIGFIG,                    "@"},
              {ITM_ROUND2,                    "@"},
              {ITM_ROUNDI2,                   "@"},
              {CHR_caseUP,                    "CASEUP"},
              {CHR_caseDN,                    "CASEDN"},
              {ITM_LISTXY,                    "@"},
              {ITM_STKTO3x1,                  "ZYX>M"},
              {ITM_POLAR,                     "@"},
              {ITM_RECT,                      "@"},
              {ITM_INTG,                      "P_INT"},
              {ITM_DIFF,                      "P_DIFF"},
              {ITM_RMS,                       "P_RMS"},
              {ITM_SHADE,                     "P_SHADE"},
              {ITM_CLGRF,                     "@"},
              {ITM_PLOT_STAT,                 "@"},
              {ITM_3x1TOSTK,                  "M>ZYX"},
              {ITM_PLOTRST,                   "@"},
              {ITM_CEIL,                      "CEIL"},
              {ITM_FLOOR,                     "FLOOR"},
              {ITM_XFACT,                     "X!"},
              {ITM_RMD,                       "@"},
              {ITM_SDL,                       "@"},
              {ITM_SDR,                       "@"},
              {ITM_Lm,                        "LM"},
              {ITM_LNBETA,                    "LNBETA"},
              {ITM_LNGAMMA,                   "LNGAMMA"},
              {ITM_SEED,                      "@"},
              {ITM_SIGN,                      "SIGN"},
              {ITM_IDIVR,                     "@"},
              {ITM_GAMMAX,                    "GAMMA"},
              {ITM_DELTAPC,                   "DELTA%"},
              {ITM_RANI,                      "@"},
              {ITM_STDDEV,                    "STDDEV"},
              {ITM_sn,                        "SN"},
              {ITM_cn,                        "CN"},
              {ITM_dn,                        "DN"},
              {ITM_PARALLEL,                  "||"},
              {ITM_PRINTERSTK,                "PRSTK"},
              {ITM_UNIT,                      "@"},
              {ITM_M_NEW,                     "MNEW"},







              {ITM_MULTCR,                    "MULTCR"},
              {ITM_MULTDOT,                   "MULTDOT"},
              {ITM_DMY,                       "@"},
              {ITM_YMD,                       "@"},
              {ITM_MDY,                       "@"},


              {ITM_SSIZE4,                    "@"},
              {ITM_SSIZE8,                    "@"},
              {ITM_CPXI,                      "CPXI"},
              {ITM_CPXJ,                      "CPXJ"},
              {ITM_CLK12,                     "@"},
              {ITM_CLK24,                     "@"},
              {ITM_SCIOVR,                    "@"},
              {ITM_ENGOVR,                    "@"},
              {ITM_F1234,                     "F1234"},
              {ITM_M1234,                     "M1234"},
              {ITM_F14,                       "F14"},
              {ITM_M14,                       "M14"},
              {ITM_F124,                      "F124"},
              {ITM_M124,                      "M124"},
              {ITM_CF,                        "@"},
              {ITM_SF,                        "@"},
              {ITM_G_DOUBLETAP,               "G2TP"},
              {ITM_HOMEx3,                    "HOME3"},
              {ITM_MYMx3,                     "MYM3"},
              {ITM_SHTIM,                     "SH4S"},
              {ITM_IRFRAC,                    "@"},
              {ITM_BASE_HOME,                 "HOMEB"},
              {ITM_BASE_MYM,                  "MYMB"},
              {ITM_LARGELI,                   "LARGELI"},
              {ITM_CPXRES1,                   "@"},
              {ITM_SPCRES1,                   "@"},
              {ITM_CPXRES0,                   "@"},
              {ITM_SPCRES0,                   "@"},
              {ITM_FGLNOFF,                   "FGOFF"},
              {ITM_FGLNLIM,                   "FGLIM"},
              {ITM_FGLNFUL,                   "FGFUL"},
              {ITM_GAPPER_L,                  "IPER"},
              {ITM_GAPCOM_L,                  "ICOM"},
              {ITM_GAPAPO_L,                  "IWTICK"},
              {ITM_GAPSPC_L,                  "ISPC"},
              {ITM_GAPDBLSPC_L,               "IWSPC"},
              {ITM_GAPDOT_L,                  "IDOT"},
              {ITM_GAPUND_L,                  "IUNDR"},
              {ITM_GAPNIL_L,                  "@"},
              {ITM_GAPNARSPC_L,               "INSPC"},
              {ITM_GAPPER_R,                  "FPER"},
              {ITM_GAPCOM_R,                  "FCOM"},
              {ITM_GAPAPO_R,                  "FWTICK"},
              {ITM_GAPSPC_R,                  "FSPC"},
              {ITM_GAPDBLSPC_R,               "FWSPC"},
              {ITM_GAPDOT_R,                  "FDOT"},
              {ITM_GAPUND_R,                  "FUNDR"},
              {ITM_GAPNIL_R,                  "@"},
              {ITM_GAPNARSPC_R,               "FNSPC"},
              {ITM_JUL_GREG_1582,             "JG1582"},
              {ITM_JUL_GREG_1752,             "JG1752"},
              {ITM_JUL_GREG_1873,             "JG1873"},
              {ITM_JUL_GREG_1949,             "JG1949"},


              {ITM_GRP_L,                     "@"},
              {ITM_GRP1_L_OF,                 "IPGRP1X"},
              {ITM_GRP1_L,                    "@"},
              {ITM_GRP_R,                     "@"},


              {ITM_BEEP,                      "@"},
              {ITM_TONE,                      "@"},
              {ITM_SQRT1PX2,                  "SQRT1+XSQR"},
              {ITM_PRTACT1,                   "@"},
              {ITM_PRTACT0,                   "@"},
              {ITM_HR_DEG,                    "@"},
              {ITM_SECOND,                    "@"},
              {ITM_EE_EXP_TH,                 "e^iX"},

              {ITM_SIGMAn,                    "SUMn"},
              {ITM_iSIGMAn,                   "iSUMn"},
              {ITM_PIn,                       "PRODn"},
              {ITM_iPIn,                      "iPRODn"},

              {ITM_LASTT,                     "LASTT"},
              {ITM_LASTX,                     "LASTX"}

};


  bool_t getXeqmText(int16_t com, char *str) {
    str[0] = 0;
    uint_fast16_t n = nbrOfElements(indexOfFunctions);
    for(uint_fast16_t i=0; i<n; i++) {
      if(com == indexOfFunctions[i].itemNr) {
        if(indexOfFunctions[i].itemName[0] == '@') {       //if new indicator "@" is found, XEQM uses standard indexOfItems[].itemCatalogName
          strcpy(str, indexOfItems[com].itemCatalogName);
        }
        else {
          strcpy(str, indexOfFunctions[i].itemName);
        }
        break;
      }
    }
    return str[0] != 0;
  }





void fnXSWAP (uint16_t mode) {
  #define isEdit (mode > 0)
  #define isSwap (!isEdit)

    if(calcMode == CM_EIM || calcMode == CM_AIM) {
      if(calcMode==CM_AIM) fnSwapXY(0);
      //convert X to string if needed
      int type_x = getRegisterDataType(REGISTER_X);
      if(type_x == dtString && stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) >= AIM_BUFFER_LENGTH) {
        if(calcMode==CM_AIM) fnSwapXY(0);                                           //swap back before returning with nothing done
        return;
      }
      if(type_x == dtReal34 || type_x == dtComplex34 || type_x == dtLongInteger || type_x == dtShortInteger || type_x == dtTime || type_x == dtDate) {
        //Backup Y; Use Y as temp to add to X; Convert number in X to string; Restore Y; Leave X as string
        copySourceRegisterToDestRegister(REGISTER_Y, TEMP_REGISTER_1);              //Save Y to temp register
        char tmp[2];
        tmp[0] = 0;
        int16_t len = stringByteLength(tmp) + 1;
        reallocateRegister(REGISTER_Y, dtString, TO_BLOCKS(len), amNone);           //Make blank string in Y
        xcopy(REGISTER_STRING_DATA(REGISTER_Y), tmp, len);
        addition[type_x][getRegisterDataType(REGISTER_Y)]();                        //Convert X (number) to string in X
        adjustResult(REGISTER_X, false, false, -1, -1, -1);

        copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_Y);              //restore Y
        clearRegister(TEMP_REGISTER_1);                                             //Clear in case it was a really long longinteger
        //resulting in a converted string in X, with Y unchanged
      }
      if(getRegisterDataType(REGISTER_X) != dtString) {                             //somehow failed to convert then return with whatever was done in X
        if(calcMode==CM_AIM) fnSwapXY(0);                                           //  This could be optimized to still restore the original X register if it had failed to convert
        return;
      }

      if(isSwap) {
        //Save aimbuffer to TEMP1 as a string register
        int16_t len = stringByteLength(aimBuffer) + 1;
        reallocateRegister(TEMP_REGISTER_1, dtString, TO_BLOCKS(len), amNone);
        xcopy(REGISTER_STRING_DATA(TEMP_REGISTER_1), aimBuffer, len);
      }
      //In essence, after conversions,
      //If X is string shorter than buffer max, copy X to aimbuffer
      //If X is no string, ignore, then aimbuffer remains unchanged.
      if(getRegisterDataType(REGISTER_X) == dtString) {
        if(stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) < AIM_BUFFER_LENGTH) {
          strcpy(aimBuffer, REGISTER_STRING_DATA(REGISTER_X));

          if(isSwap) {
            //copy aimbuffer to X
            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
          }
          //Set cursors
          if(calcMode==CM_AIM) {
            fnSwapXY(0);
            T_cursorPos = stringByteLength(aimBuffer);
            if(isEdit) {
              fnDrop(NOPARAM);
            }
          }
          else { //EIM
            xCursor = stringGlyphLength(aimBuffer);
          }
          refreshRegisterLine(REGISTER_X);        //make sure that the mulit line editor check is done
          last_CM = 253;
          refreshScreen(64);
        }
      }
      clearRegister(TEMP_REGISTER_1);
    }

    else if(calcMode == CM_NORMAL && getRegisterDataType(REGISTER_X) == dtString) {
      if(stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) < AIM_BUFFER_LENGTH) {
        if(getSystemFlag(FLAG_ERPN)) {      //JM NEWERPN
          setSystemFlag(FLAG_ASLIFT);            //JM NEWERPN OVERRIDE SLS, AS ERPN ENTER ALWAYS HAS SLS SET
        }                                        //JM NEWERPN
        strcpy(aimBuffer, REGISTER_STRING_DATA(REGISTER_X));
        T_cursorPos = stringByteLength(aimBuffer);
        fnDrop(NOPARAM);
        #if !defined(TESTSUITE_BUILD)
          resetShiftState();
          calcModeAim(NOPARAM); // Alpha Input Mode
          showSoftmenu(-MNU_ALPHA);
        #endif // !TESTSUITE_BUILD
      }
    }
    else if(calcMode == CM_NORMAL && getRegisterDataType(REGISTER_X) != dtString) {
      char line1[XEQ_STR_LENGTH_LONG];
      line1[0] = 0;
      strcpy(line1, " ");
      int16_t len = stringByteLength(line1);
      if(getSystemFlag(FLAG_ERPN)) {      //JM NEWERPN
        setSystemFlag(FLAG_ASLIFT);            //JM NEWERPN OVERRIDE SLS, AS ERPN ENTER ALWAYS HAS SLS SET
      }                                        //JM NEWERPN
      liftStack();
      reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(len), amNone);
      strcpy(REGISTER_STRING_DATA(REGISTER_X), line1);
      fnXSWAP(0);
    }

  last_CM = 252;
  refreshScreen(63);
  last_CM = 251;
  refreshScreen(0);
}



