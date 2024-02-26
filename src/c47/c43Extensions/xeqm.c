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
 * \file xeqm.c
 ***********************************************/

#include "c43Extensions/xeqm.h"

#include "bufferize.h"
#include "calcMode.h"
#include "charString.h"
#include "flags.h"
#include "hal/gui.h"
#include "c43Extensions/addons.h"
#include "c43Extensions/graphText.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "keyboard.h"
#include "c43Extensions/keyboardTweak.h"
#include "registers.h"
#include "screen.h"
#include "softmenus.h"
#include "stack.h"
#include "statusBar.h"
#include "timer.h"
#include "c43Extensions/textfiles.h"
#include <string.h>

#include "c47.h"

#define commandnumberl NIM_BUFFER_LENGTH

#define SCAN true
#define EXEC true

typedef struct {
  char itemName[30];
} nstr0;
TO_QSPI const nstr0 XeqmMsgs[] = { 
/*0*/  { "Loading XEQM program file:" },
/*1*/  { "Loading XEQM:" },
/*2*/  { "XEQC47 XEQLBL 01 XXXXXX " },
/*3*/  { "Press a key" },
/*4*/  { "XEQMINDEX.TXT" },
/*5*/  { "XEQM01:HELP;" }
};


typedef struct {
  char itemName[180];
} nstr1;
TO_QSPI const nstr1 helpMsg[] = { 
   //Std F1 Helpmessage
      { "XEQLBL 01 HELP ALPHA \"I\" CASE \"n directory \" CASE \"PROGRAMS\" CASEDN \" create \" CASEUP \"XEQM\" CASEDN \"NN\" CASEUP \".TXT\" EXIT "} };



//Inline XEQC code used in ELEC, in jm.c
typedef struct {
  char itemName[130];
} nstr2;

TO_QSPI const nstr2 xeqTexts[] = { 
   //Create a 3x3 A-matrix
      { "XEQC47 ERPN RECT 3 ENTER 3 MNEW STO 99 DROPX INDEX 99 1 ENTER 1 STOIJ DROPX DROPX" },
      { " 1 STOEL J+ STOEL J+ STOEL" },
      { " J+ STOEL DROPX 0.5 ENTER CHS 3 ENTER SQRT 2 / CHS COMPLEX J+ STOEL COMPLEX CHS COMPLEX J+ STOEL" },
      { " 1 J+ STOEL DROPX J+ STOEL X^2 J+ STOEL DROPX" },
      { " RCL 99 " },
   //Create a 3x1 matrix from Z Y X
      { "XEQC47 ERPN 3 ENTER 1 MNEW STO 99 DROPX INDEX 99 3 ENTER 1 STOIJ DROPX DROPX STOEL DROPX  I- STOEL DROPX  I-  STOEL DROPX RCL 99 " },
   //Create a ZYX form a 3x1 matrix
      { "XEQC47 ERPN STO 99 INDEX 99 DROPX 1 ENTER 1 STOIJ DROPX DROPX RCLEL I+ RCLEL I+ RCLEL " }
    };


void fnXeqmExecuteText(uint16_t command){
    char line1[700];
    if(command == 45) {
      //Create a 3x3 A-matrix
      strcpy(line1, xeqTexts[0].itemName);
      strcat(line1, xeqTexts[1].itemName);
      strcat(line1, xeqTexts[2].itemName);
      strcat(line1, xeqTexts[3].itemName);
      strcat(line1, xeqTexts[4].itemName);
      fnXEQMexecute(line1);
      }

    else if(command == 46) {
      //Create a 3x1 matrix from Z Y X
      strcpy(line1, xeqTexts[5].itemName);
      fnXEQMexecute(line1);
    }

    else if(command == 47) {
      //Create a ZYX form a 3x1 matrix
      strcpy(line1, xeqTexts[6].itemName);
      fnXEQMexecute(line1);
    }
}



void press_key(void) {
  #if defined(DMCP_BUILD)
    print_inlinestr(XeqmMsgs[3].itemName, true);  //Press a key
    wait_for_key_press();
  #endif // DMCP_BUILD
}

#define XEQ_STR_LENGTH_LONG  TMP_STR_LENGTH // 3000 // note the limit is the tmpString limit

void capture_sequence(char *origin, uint16_t item) {
  #if defined(PC_BUILD)
    //printf("Captured: %4d   //%10s//  (%s)\n", item, indexOfItems[item].itemSoftmenuName, origin);
    char line1[XEQ_STR_LENGTH_LONG];
    char ll[commandnumberl];

    line1[0]=0;
    ll[0]=0;
    ll[1]=0;
    switch(item) {
      case  ITM_XexY:     strcpy(ll, "X<>Y"); break;
      case  ITM_YX:       strcpy(ll, "Y^X" ); break;
      case  ITM_DIV:      strcpy(ll, "/"   ); break;

      case  ITM_0:
      case  ITM_1:
      case  ITM_2:
      case  ITM_3:
      case  ITM_4:
      case  ITM_5:
      case  ITM_6:
      case  ITM_7:
      case  ITM_8:
      case  ITM_9:        ll[0]=item - ITM_0 + 48;
                          strcpy(line1, "   \"");
                          strcat(line1, ll);
                          strcat(line1, "\" ");
                          break;

      case  ITM_PERIOD:   ll[0]=46;
                          strcpy(line1, "   \"");
                          strcat(line1, ll);
                          strcat(line1, "\" ");
                          break;

      case  ITM_EXPONENT: ll[0]=69;
                          strcpy(line1, "   \"");
                          strcat(line1, ll);
                          strcat(line1, "\" ");
                          break;

      default:            strcpy(ll, indexOfItems[item].itemSoftmenuName);
    }

    if(line1[0]==0) {
      sprintf(line1, " %4d //%10s", item, ll);
    }

    stringToUtf8(line1, (uint8_t *)tmpString);
    export_string_to_file(tmpString);
  #endif // PC_BUILD
}


//############################ SEND KEY TO 43S ENGINE ####################
void runkey(int16_t item){
  #if !defined(TESTSUITE_BUILD)
    //char tmp[2];
    //tmp[0]=0;
    //executeFunction(tmp, item);


    if(item < 0) {
      showSoftmenu(item);
    }
    else {
      //printf("§%d§ ", item);
      hideFunctionName();           //Clear in case active
      processKeyAction(item);
      if(!keyActionProcessed) {
        hideFunctionName();         //Clear in case activated during process
        runFunction(item);
        //#if defined(DMCP_BUILD)
        //  lcd_forced_refresh(); // Just redraw from LCD buffer
        //#endif // DMCP_BUILD
      }
    }
  #endif // !TESTSUITE_BUILD
}


//############################ DECODE NUMBERS AND THEN SEND KEY TO 43S ENGINE ####################
void sendkeys(const char aa[]) {
  int16_t ix = 0;
  while(aa[ix] != 0) {
         if(aa[ix] >= 65 && aa[ix] <=  90) runkey(ITM_A + aa[ix] - 65     ); //A..Z
    else if(aa[ix] >= 97 && aa[ix] <= 122) runkey(ITM_A + aa[ix] - 65 - 32); //a..z converted to A..Z
    else if(aa[ix] >= 48 && aa[ix] <=  57) runkey(ITM_0 + aa[ix] - 48     ); //0..9
    else {
      switch(aa[ix]) {
        case '.':  runkey(ITM_PERIOD       ); break; //.
        case 'E':  runkey(ITM_EXPONENT     ); break; //E
        case 'e':  runkey(ITM_EXPONENT     ); break; //e
        case '-':  runkey(ITM_SUB          ); break; //-
        case '+':  runkey(ITM_ADD          ); break; //+
        case ' ':  runkey(ITM_SPACE        ); break; //space
        case '#':  runkey(ITM_toINT        ); break; //#
        case ':':  runkey(ITM_COLON        ); break; //#
        case ';':  runkey(ITM_SEMICOLON    ); break; //#
        case '\'': runkey(ITM_QUOTE        ); break; //#
        case '?':  runkey(ITM_QUESTION_MARK); break; //#
        default:;
      }
    }
    ix++;
  }
}


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

// COMMAND name or number: command to be located in between any of CR, LF, comma, space, tab, i.e. X<>Y, PRIME?, ...
// COMMENT: comment to be located in between / and /, i.e. /Comment/
// NUMBER to be located in between quotes: "123.123" or STO "00"
// Example: "200" EXIT PRIME?
// Ignores all other ASCII control and white space.


bool_t running_program_jm = false;


typedef struct {
  uint16_t itemNr;            ///<
  char     itemName[16];         ///<
} function_t;


TO_QSPI const function_t indexOfFunctions[] = {
  #if !defined(SAVE_SPACE_DM42_2)
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
              {ITM_PLOT,                      "@"},
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
              {ITM_iPIn,                      "iPRODn"}



  #endif // !SAVE_SPACE_DM42_2
};


//SPECIAL CODE TODO FOR XEQMnn
//                           if(strcompare(str,"XEQM01") && exec) *com = ITM_X_P1;
//                      else if(strcompare(str,"XEQM02") && exec) *com = ITM_X_P2;
//                      else if(strcompare(str,"XEQM03") && exec) *com = ITM_X_P3;
//                      else if(strcompare(str,"XEQM04") && exec) *com = ITM_X_P4;
//                      else if(strcompare(str,"XEQM05") && exec) *com = ITM_X_P5;
//                      else if(strcompare(str,"XEQM06") && exec) *com = ITM_X_P6;
//                      else if(strcompare(str,"XEQM07") && exec) *com = ITM_X_f1;
//                      else if(strcompare(str,"XEQM08") && exec) *com = ITM_X_f2;
//                      else if(strcompare(str,"XEQM09") && exec) *com = ITM_X_f3;
//                      else if(strcompare(str,"XEQM10") && exec) *com = ITM_X_f4;
//                      else if(strcompare(str,"XEQM11") && exec) *com = ITM_X_f5;
//                      else if(strcompare(str,"XEQM12") && exec) *com = ITM_X_f6;
//                      else if(strcompare(str,"XEQM13") && exec) *com = ITM_X_g1;
//                      else if(strcompare(str,"XEQM14") && exec) *com = ITM_X_g2;
//                      else if(strcompare(str,"XEQM15") && exec) *com = ITM_X_g3;
//                      else if(strcompare(str,"XEQM16") && exec) *com = ITM_X_g4;
//                      else if(strcompare(str,"XEQM17") && exec) *com = ITM_X_g5;
//                      else if(strcompare(str,"XEQM18") && exec) *com = ITM_X_g6;

#if !defined(SAVE_SPACE_DM42_2)
  bool_t checkindexes(int16_t *com, char *str, bool_t exec) {
    *com = 0;
    uint_fast16_t n = nbrOfElements(indexOfFunctions);
    for(uint_fast16_t i=0; i<n; i++) {
      if(indexOfFunctions[i].itemName[0] == '@' && strcompare(str, (char*)indexOfItems[indexOfFunctions[i].itemNr].itemCatalogName)) {        //if new indicator "@" is found, XEQM uses standard indexOfItems[].itemCatalogName
        *com = indexOfFunctions[i].itemNr;
        break;
      }
      else if(strcompare(str, indexOfFunctions[i].itemName)) {
        *com = indexOfFunctions[i].itemNr;
        break;
      }
    }
    return *com != 0;
  }
#endif // !SAVE_SPACE_DM42_2


  bool_t getXeqmText(int16_t com, char *str) {
    str[0] = 0;
    uint_fast16_t n = nbrOfElements(indexOfFunctions);
    for(uint_fast16_t i=0; i<n; i++) {
      if(com == indexOfFunctions[i].itemNr) {
        if(indexOfFunctions[i].itemName[0] == '@') {       //if new indicator "@" is found, XEQM uses standard indexOfItems[].itemCatalogName
          strcpy(str, indexOfItems[com].itemCatalogName);
        } else {
          strcpy(str, indexOfFunctions[i].itemName);
        }
        break;
      }
    }
    return str[0] != 0;
  }



void execute_string(const char *inputstring, bool_t exec1, bool_t namescan) {
  currentKeyCode = 255;
  #if !defined(SAVE_SPACE_DM42_2)
    #if !defined(TESTSUITE_BUILD)
      #if(VERBOSE_LEVEL > 0)
        uint32_t ttt = getUptimeMs();
        while(ttt + 300 != getUptimeMs()); // This is bad for battery
        print_linestr(inputstring, true);
        print_linestr("", false);
      #endif // VERBOSE_LEVEL > 0

      if(exec1) {
        namescan = false;     //no scanning option if tasked to execute
      }
      int16_t commno;
      uint16_t ix, ix_m;
      uint16_t ix_m1 = 0;
      uint16_t ix_m2 = 0;
      uint16_t ix_m3 = 0;
      uint16_t ix_m4 = 0;
      int16_t  no, ii;
      char     commandnumber[commandnumberl];
      char     aa[2], bb[2];
      bool_t   state_comments, state_commands, state_quotes;
      uint16_t xeqlblinprogress;
      uint16_t gotoinprogress;
      bool_t   gotlabels = false;
      bool_t   exec = false;
      bool_t   go;
      running_program_jm = true;
      indic_x = 0;
      indic_y = SCREEN_HEIGHT-1;
      uint8_t starttoken = 0;
      #if defined(PC_BUILD)
        uint16_t loopnumber = 0;
      #endif // PC_BUILD

      hourGlassIconEnabled = true;
      cancelFilename = true;
      showHideHourGlass();
      #if defined(DMCP_BUILD)
        lcd_refresh();
      #else // !DMCP_BUILD
        refreshLcd(NULL);
      #endif // DMCP_BUILD

                                                 // If !gotlabels, means it is a scouting pass/parse to find and mark the goto labels M1-M4
      while(!gotlabels || (gotlabels && exec)) { // scheme to use for label scouting and name processing in "false", and to do a two parse exec
        #if defined(PC_BUILD_VERBOSE1)
          #if defined(PC_BUILD)
            printf("\n------Starting parse ------- Indexes: M1:%d M2:%d M3:%d M4:%d   EXEC:%d\n", ix_m1, ix_m2, ix_m3, ix_m4, exec);
            printf("|%s|\n", inputstring);
          #endif // PC_BUILD
        #endif // PC_BUILD_VERBOSE1
        xeqlblinprogress = 0;
        gotoinprogress   = 0;
        go = false;
        ix = 0;
        ix_m = 0;
        no = 0;
        state_comments = false;
        state_commands = false;
        state_quotes = false;
        commandnumber[0] = 0;
        aa[0] = 0;

        while(inputstring[ix] != 0 && ix < XEQ_STR_LENGTH_LONG) {
          //if( (inputstring[ix] == 13 || inputstring[ix] == 10) && (aa[0] == 13 || aa[0] == 10) ) {
          //  ix++;
          //}
          // else {
          strcpy(bb, aa);
          aa[0] = inputstring[ix];
          aa[1] = 0;
          #if defined(PC_BUILD_VERBOSE0)
            #if defined(PC_BUILD)
              printf("##--$ |%s|%s| --gotlabels=%i exec=%i \n",bb,aa,gotlabels,exec);
            #endif // PC_BUILD
          #endif // PC_BUILD_VERBOSE0
          //print_linestr(aa, false);
          switch(bb[0]) { // COMMAND can start after any of these: space, tab, cr, lf, comma, beginning of file
            case 32:
            case  8:
            case 13:
            case 10:
            case 44:
            case  0: if( // COMMAND WORD START DETECTION +-*/ 0-9; A-Z; %; >; (; a-z; .
                        (       aa[0] == '*' //  42 // *
                            ||  aa[0] == '+' //  43 // +
                            ||  aa[0] == '-' //  45 // -
                            ||  aa[0] == '/' //  47 // /
                            ||  aa[0] == '~' // 126 // ~
                            || (aa[0] >= 48 && aa[0] <= 57) // 0-9
                            || (aa[0] >= 65 && aa[0] <= 90) // A-Z
                            || (aa[0] >= 65 + 32 && aa[0] <= 90 + 32) // a-z
                            ||  aa[0] == '%'
                            ||  aa[0] == '>'
                            ||  aa[0] == '('
                            ||  aa[0] == '.'
                        )
                        && !state_comments            // If not inside comments
                        && !state_quotes              // if not inside quotes
                        && !state_commands            // Don't re-check until done
                      ) {
                      state_commands = true;         // Waiting to open command number or name: nnn
                    }
              default:;
          }

          if(state_comments && (aa[0] == 13 || aa[0] == 10)) {
            #if defined(PC_BUILD_VERBOSE0)
              #if defined(PC_BUILD)
                printf("##++ Cancel Comments\n");
              #endif // PC_BUILD
            #endif // PC_BUILD_VERBOSE0
            state_comments=false;
          }
          else {
            switch(aa[0]) {
              case '/': if(bb[0] == '/' && state_comments == false) { // ADDED  STATE, SO //always switches on the comment, but not off. CR/LF cancels it
                          state_comments = true;           // Switch comment state on
                          state_commands = false;
                          state_quotes   = false;
                          commandnumber[0]=0;
                          #if defined(PC_BUILD_VERBOSE0)
                            #if defined(PC_BUILD)
                              printf("##++ Start Comments\n");
                            #endif // PC_BUILD
                          #endif // PC_BUILD_VERBOSE0
                        }
                        break;

              case  34: if(!state_comments && !state_commands) { // " Toggle quote state
                          state_quotes = !state_quotes;
                        }
                        break;

              case  13: //cr
              case  10: //lf
              case   8: //tab
              case ',': //,
              case ' ': //print_linestr(commandnumber, false);
                        #if defined(PC_BUILD_VERBOSE0)
                          #if defined(PC_BUILD)
                            printf("@@@ %s\n", commandnumber);
                          #endif // PC_BUILD
                        #endif // PC_BUILD_VERBOSE0
                        if(state_commands) {
                          state_commands = false;                // Waiting for delimiter to close off and send command number: nnn<
                          #if defined(PC_BUILD_VERBOSE0)
                            #if defined(PC_BUILD)
                              printf("\nCommand/number detected:(tempjm=%d)(gotoinprogress=%d) %45s ", temporaryInformation, gotoinprogress, commandnumber);
                            #endif // PC_BUILD
                          #endif // PC_BUILD_VERBOSE0
                          //print_linestr(commandnumber, false);

                          //DSZ:
                          if(!(gotoinprogress != 11 || (gotoinprogress == 11 && (temporaryInformation == TI_FALSE)))) {     // If DEC results in 0, then 'true'.    It is now the command that may or may not be skipped
                            //......IS NOT DSZ.... OR               DSZ    with REG NOT ZERO
                            go = (temporaryInformation == TI_FALSE); //As per GTO_SZ ---- REGISTER<>0, then go
                            //printf("   DSZ/ISZ temporaryInformation = %5d\n", temporaryInformation);
                            gotoinprogress = 1;                      //As per GTO_SZ
                            commandnumber[0] = 0;                    //As per GTO_SZ
                          }
                          else {
                            // Unlimited GTO                                      GTO M1
                            // 4 Labels M1, M2, M3 & M4                           XEQLBL M1
                            // Unlimited DSZ and ISZ                              DSZ 00
                            // Non-nested subroutine GSB M1..M4; RTN              GSB M01     RTN
                            // END reacts to labelling parse and execution parse  END
                            // RETURN reacts to execution parse only              RETURN

                            if(checkindexes(&commno, commandnumber, exec)) {
                              sprintf(commandnumber, "%d", commno);
                              #if defined(PC_BUILD_VERBOSE0)
                                #if defined(PC_BUILD)
                                  printf("## no:%i",commno);
                                #endif // PC_BUILD
                              #endif // PC_BUILD_VERBOSE0
                            }
                            else if(strcompare(commandnumber, "DSZ"    )) {
                                sprintf(commandnumber,"%d", ITM_DEC);
                                gotoinprogress = 9;
                            }
                            else if(strcompare(commandnumber, "ISZ"   )) { //EXPECTING FOLLOWING OPERAND "nn"
                              sprintf(commandnumber,"%d", ITM_INC);
                              gotoinprogress = 9;
                            }
                            else if(strcompare(commandnumber, "LBL")) { //EXPECTING FOLLOWING OPERAND "nn"
                              xeqlblinprogress = 10;
                            }
                            else if(strcompare(commandnumber, "XEQC43")) { //EXPECTING FOLLOWING OPERAND Mn
                              starttoken = 1;
                            }
                            else if(strcompare(commandnumber, "XEQC47")) { //EXPECTING FOLLOWING OPERAND Mn
                              starttoken = 1;
                            }
                            else if(strcompare(commandnumber, "XEQLBL")) { //EXPECTING FOLLOWING OPERAND Mn
                              #if(VERBOSE_LEVEL > 0)
                                print_linestr("->XEQLBL", false);
                              #endif // (VERBOSE_LEVEL > 0)
                              xeqlblinprogress =  1;
                              starttoken = 1;
                            }
                            else if(strcompare(commandnumber, "GTO")) { //EXPECTING 2 OPERANDS nn XXXXXX
                              #if defined(PC_BUILD)
                                printf("   >>> Loop GTO Jump %d:go\n", loopnumber++);
                              #endif // PC_BUILD
                              if(exec) {
                                go = true;
                                gotoinprogress = 1;
                                force_refresh(timed);
                              }
                            }
                            else if(strcompare(commandnumber, "GSB")) {
                              #if defined(PC_BUILD)
                                printf("   >>> Sub  GSB Jump %d\n", loopnumber++);
                              #endif // PC_BUILD
                              if(exec) {
                                go = true;
                                gotoinprogress = 1;
                                ix_m = ix;
                                force_refresh(timed);
                                #if defined(PC_BUILD)
                                  printf("   >>> Sub  GSB Jump %d:go storing return address %d\n", loopnumber++, ix_m);
                                #endif // PC_BUILD
                              }
                            }
                            else if(strcompare(commandnumber, "RTN")) {
                              if(exec) {
                                ix = ix_m + 2;
                                ix_m = 0;
                                force_refresh(timed);
                                #if defined(PC_BUILD)
                                  printf("   >>> Sub  RTN to return address %d\n", ix);
                                #endif // PC_BUILD
                              }
                            }
                            else if(strcompare(commandnumber, "GTO_SZ")) {
                              if(exec) {
                                go = (temporaryInformation == TI_FALSE);
                                gotoinprogress = 1;
                              }
                            }
                            else if(strcompare(commandnumber, "END")) {
                              ix = stringByteLength(inputstring) - 2;
                            }
                            else if(strcompare(commandnumber, "RETURN")) {
                              if(exec) {
                                ix = stringByteLength(inputstring)-2;
                              }
                            }
                            else {
                              ii = 0;
                              while(commandnumber[ii]!=0 && ((commandnumber[ii]<='9' && commandnumber[ii]>='0') || commandnumber[ii]>='.' || commandnumber[ii]>='E' ) ) {
                                ii++;
                              }
                              if(commandnumber[ii]==0 && (gotoinprogress == 0 || gotoinprogress == 10) && xeqlblinprogress == 0 ) {
                                //printf("   Fell thru, i.e. number %s, gotoinprogress %d\n",commandnumber,gotoinprogress);   // at this stage there SHOULD be a number (not checked) coming out at this point, from the ELSE, it is a number from the text file, therefore literal mnumbers
                                                          // prepare to break out of this state
                                                          // and set flags as if in direct character (quotes) state
                                if(exec) {
                                  sendkeys(commandnumber);
                                  //printf("   sent-->a|%s|\n", commandnumber);
                                }
                                commandnumber[0]=0;
                                if(gotoinprogress == 10) { //if the digits of STO or DSZ
                                  gotoinprogress = 11;
                                }
                                break;
                              }
                            }
                          }

                          //v
                          if(starttoken == 0) {                  //if not started with XEQLBL or XEQC43, immediately abandon program mode
                            goto exec_exit;
                          }

                          //printf("   gotoinprogress = %5d; xeqlblinprogress = %5d; commandnumber = %10s\n",gotoinprogress,xeqlblinprogress,commandnumber);

                          temporaryInformation  = TI_NO_INFO;   //Cancel after go was determined.
                          switch(gotoinprogress) {
                            case 1:                  //GOTO IN PROGRESS: got command GOTO. If arriving from DSZ with no label, just pass around and skip to 2
                              gotoinprogress = 2;
                              commandnumber[0] = 0;
                              break;

                            case 2:                  //GOTO IN PROGRESS: if arriving from DSZ / 1, witho9ut M1-M4, waste the commandd, zero, and pass around
                                    if(strcompare(commandnumber,"M1") && exec && go && (ix_m1 !=0)) ix = ix_m1;
                              else if(strcompare(commandnumber,"M2") && exec && go && (ix_m2 !=0)) ix = ix_m2;
                              else if(strcompare(commandnumber,"M3") && exec && go && (ix_m3 !=0)) ix = ix_m3;
                              else if(strcompare(commandnumber,"M4") && exec && go && (ix_m4 !=0)) ix = ix_m4;
                              gotoinprogress = 0;
                              commandnumber[0] = 0;   //Processed
                              go = false;
                            break;

                            case 13:                  //GOTO IN PROGRESS: eat one word
                              gotoinprogress = 0;
                              commandnumber[0] = 0;
                            break;

                            default:;
                          }


                          switch(xeqlblinprogress) {
                            case 1:                  //XEQMLABEL IN PROGRESS: got command XEQLBL
                              xeqlblinprogress = 2;
                              commandnumber[0] = 0;
                              break;

                            case 2:                  //XEQMLABEL IN PROGRESS: get softkeynumber 01 - 18
                              no = atoi(commandnumber);
                              if(no >= 1 && no <= 18) {
                                xeqlblinprogress = 3;
                                commandnumber[0] = 0;   //Processed
                              }
                              else {
                                xeqlblinprogress = 0;
                                commandnumber[0] = 0;   //Processed
                              }
                              break;

                            case 3:                  //XEQMLABEL IN PROGRESS: get label
                              if(no >= 1 && no <= 18) {
                                char tmpp[commandnumberl];
                                strcpy(tmpp,commandnumber);
                                tmpp[8-1] = 0;         //Limit to length of indexOfItemsXEQM
                                //printf(">>> Exec:%d no:%d ComndNo:%s tmpp:%s>>XEQM:%s\n",exec, no,commandnumber, tmpp,indexOfItemsXEQM + (no-1)*8);
                                if(!exec) {
                                  strcpy(indexOfItemsXEQM + (no-1)*8, tmpp);        // At Exec time, the XEQM label is changed to the command number. So the re-allocation of the name can only happen in the !exec state
                                  if(namescan) {
                                    //printf("\n### Namescan end %s\n",tmpp);
                                    goto exec_exit; //If in name scan mode, only need to process string up to here
                                  }
                                }
                                xeqlblinprogress = 0;
                                commandnumber[0]=0;  //Processed

                                #if !defined(TESTSUITE_BUILD)
                                  //showSoftmenuCurrentPart(); //JMXX Redisplay because softkey content changed
                                #endif // !TESTSUITE_BUILD
                              }
                              break;

                            case 10:                  //LABEL IN PROGRESS: got command XEQLBL
                              xeqlblinprogress = 11;
                              commandnumber[0] = 0;
                            break;

                            case 11:                  //LABEL IN PROGRESS: get label M1-M4
                              //printf("LABEL %s\n",commandnumber);
                                    if(strcompare(commandnumber,"M1")) ix_m1 = ix;
                              else if(strcompare(commandnumber,"M2")) ix_m2 = ix;
                              else if(strcompare(commandnumber,"M3")) ix_m3 = ix;
                              else if(strcompare(commandnumber,"M4")) ix_m4 = ix;
                              xeqlblinprogress = 0;
                              commandnumber[0] = 0;   //Processed
                              flipPixel(indic_x, indic_y-1);
                              break;

                            //HERE DEFAULT !!
                            //NOT IN PROGRESS
                            default:                 //NOT IN PROGRESS
                              no = atoi(commandnumber);       //Will force all unknown commands to have no number, and invalid command and RETURN MARK etc. to 0
                              //printf("   Command send %s EXEC=%d no=%d ",commandnumber,exec,no);
                              if(no > LAST_ITEM-1) {
                                no = 0;
                              }
                              if(no!=0 && exec) {
                                flipPixel(indic_x++, indic_y);
                                if(indic_x==SCREEN_WIDTH) {
                                  indic_x = 0;
                                  indic_y--;
                                  indic_y--;
                                }

                                if(exec) {
                                  runkey(no);
                                  //printf("   -->%d sent ",no);
                                }
                                else {
                                  //printf("   -->%d not sent ",no);
                                }
                                //printf(">>> %d\n",temporaryInformation);
                                if(gotoinprogress == 9 ) {
                                  gotoinprogress = 10;
                                }
                              }
                              else {
                                //printf("Skip execution |%s|",commandnumber);
                              }
                              //printf("#\n");
                              commandnumber[0] = 0;   //Processed
                              break;
                          }
                        }
                        break;
              default:;           //ignore all other characters
            }
          }
          if(state_quotes) {
            if(exec) {
              //printf("   sent-->b|%s|\n",aa);
              sendkeys(aa);} //else printf("Skip sending |%s|",aa);
          }
          else {
            if(state_commands && stringByteLength(commandnumber) < commandnumberl-1) {
              strcat(commandnumber,aa);
              //printf("#%s",aa);
            }   // accumulate string
          }
          ix++;
          //}
          if(keyWaiting()) {
            break;
          }
        } //while

        gotlabels = true;  //allow to run only once, unless
                          //exec must run, and ensure it runs only once.
        if(!exec) {
          exec = exec1;
        }
        else {
          exec = false;
        }

        if(keyWaiting()) {
          goto exec_exit;
        }
      }
      #if defined(PC_BUILD_VERBOSE0)
        #if defined(PC_BUILD)
          printf(">>>end gotlabels=%i exec=%i \n", gotlabels, exec);
        #endif // PC_BUILD
      #endif // PC_BUILD_VERBOSE0

      exec_exit:
      exec = false;     //exec must run, and ensure it runs only once.
    #endif // !TESTSUITE_BUILD
    running_program_jm = false;
    #if defined(PC_BUILD_VERBOSE0)
      #if defined(PC_BUILD)
        printf("##++ END Exiting\n");
      #endif // PC_BUILD
    #endif // PC_BUILD_VERBOSE0
    return;
  #endif // !SAVE_SPACE_DM42_2
}


void replaceFF(char* FF, char* line2) {
  int16_t ix =0;
  if(FF[0]>='0' && FF[0]<='9' && FF[1]>='0' && FF[1]<='9' && FF[2]==0) {
    while(line2[ix] != 0 && ix + 10 < stringByteLength(line2)) {
      if(line2[ix]==88 /*X*/ && line2[ix+1]==69 /*E*/ && line2[ix+2]==81 /*Q*/ && line2[ix+3]==76 /*L*/ && line2[ix+4]==66 /*B*/ && line2[ix+5]==76 /*L*/ && line2[ix+6]==32 && line2[ix+7]==70 /*F*/ && line2[ix+8]==70 /*F*/) {
        line2[ix+7] = FF[0];
        line2[ix+8] = FF[1];
      }
      ix++;
    }
  }
}


void XEQMENU_Selection(uint16_t selection, char *line1, bool_t exec, bool_t scanning) {
  #if !defined(SAVE_SPACE_DM42_2)
    #if !defined(TESTSUITE_BUILD)
                                            // Read in XEQMINDEX.TXT file, with default XEQMnn file name replacements
      line1[0] = 0;                         // Clear incoming/outgoing string data
      char nn[6];
      nn[0] = 0;
      char fallback[130];     // Fallback text
      char fn_long[200];      // Long file name
      char fn_short[16];      // standard file name

      #if(VERBOSE_LEVEL >= 1)
        char tmp[400];          // Messages
      #endif // (VERBOSE_LEVEL >= 1)


      #if defined(DMCP_BUILD)
        #define pgmpath "PROGRAMS"
      #else // !DMCP_BUILD
        #define pgmpath "res/PROGRAMS"
      #endif // DMCP_BUILD
      strcpy(fn_short, XeqmMsgs[4].itemName);    //"XEQMINDEX.TXT"
      strcpy(fn_long,  "");
      strcpy(fallback, XeqmMsgs[5].itemName);    //"XEQM01:HELP;" 

      #if(VERBOSE_LEVEL >= 1)
        strcpy(tmp, fn_short);
        strcat(tmp, " A: Loading XEQMENU mapping");
        print_linestr(tmp, false);
      #endif // (VERBOSE_LEVEL >= 1)

      import_string_from_filename(line1, pgmpath, fn_short, fn_long, fallback, !SCAN);

      #if(VERBOSE_LEVEL >= 1)
        sprintf(tmp, " B: XEQMENU mapping Loaded: %u bytes.\n", (uint16_t)stringByteLength(line1));
        print_linestr(tmp, false);
      #endif // (VERBOSE_LEVEL >= 1)

      #if(VERBOSE_LEVEL >= 2)
        #if defined(DMCP_BUILD)
          press_key();
        #endif // DMCP_BUILD
      #endif // (VERBOSE_LEVEL >= 2)

      int16_t ix = 0;
      int16_t iy = 0;
      sprintf(nn, "%2d", selection);        // Create string value for 00
      if(nn[0] == ' ') {
        nn[0] = '0';
      }
      if(nn[1] == ' ') {
        nn[1] = '0';
      }
      strcpy(fn_short, "XEQM");             // Build default short file name XEQMnn
      strcat(fn_short, nn);
      strcpy(fn_long, fn_short);

                                            // Find XEQMnn in the replacement token file
      while(line1[ix] != 0 && ix+6 < stringByteLength(line1)) {
        if(line1[ix]=='X' && line1[ix+1]=='E' && line1[ix+2]=='Q' && line1[ix+3]=='M' && line1[ix+4]==nn[0] && line1[ix+5]==nn[1] && line1[ix+6]==':') {
          ix = ix + 7;
          iy = ix;                             // If found, find the replacement text after the colon until before the semi-colon
          while(line1[ix] != 0 && ix < stringByteLength(line1)) {
            if(line1[ix] == ';' ) {
              line1[ix] = 0;
              strcpy(fn_long, line1 + iy);
              break;
            } // Replace file name with content from replacement string
            ix++;
          }
        }
        ix++;
      }
      strcat(fn_short, ".TXT");
      strcat(fn_long, ".TXT");

      #if(VERBOSE_LEVEL >= 1)
        sprintf(tmp," C: Trying %s then %s.", fn_short, fn_long);
        print_linestr(tmp, false);
      #endif // (VERBOSE_LEVEL >= 1)

      line1[0] = 0;                                     //Clear incoming/outgoing string data

      //printf(">>> original name:|%s|, replacement file name:|%s|\n", fn_short, fn_long);
      if(selection == 1) {
        sprintf(fallback, "%s", helpMsg[0].itemName);
      }
      else {
        sprintf(fallback, "XEQLBL %s X%s ", nn, nn);
      }

      #if(VERBOSE_LEVEL >= 2)
        sprintf(tmp, "  Fallback:%s", fallback);
        print_linestr(tmp, false);
      #endif // (VERBOSE_LEVEL >= 2)

      import_string_from_filename(line1,pgmpath,fn_short,fn_long,fallback,scanning);

      #if(VERBOSE_LEVEL >= 1)
        sprintf(tmp, " D: PGM Loaded: %u bytes.\n", (uint16_t)stringByteLength(line1) );
        print_linestr(tmp, false);
      #endif // (VERBOSE_LEVEL >= 1)

      replaceFF(nn,line1);

      #if(VERBOSE_LEVEL >= 1)
        sprintf(tmp, " E: FF: %u bytes.\n", (uint16_t)stringByteLength(line1) );
        print_linestr(tmp, false);
        print_linestr(line1, false);
      #endif // (VERBOSE_LEVEL >= 1)

      #if(VERBOSE_LEVEL >= 2)
        #if defined(DMCP_BUILD)
          press_key();
        #endif // DMCP_BUILD
      #endif // (VERBOSE_LEVEL >= 2)

      #if(VERBOSE_LEVEL >= 1)
        clearScreenOld(false, true, true);
      #endif // (VERBOSE_LEVEL >= 1)

      displaywords(line1);       //output  is  in  tmpString

      strcpy(line1,tmpString);
      #if(VERBOSE_LEVEL >= 2)
        #if defined(DMCP_BUILD)
          press_key();
        #endif // DMCP_BUILD
      #endif // (VERBOSE_LEVEL >= 2)

      #if(VERBOSE_LEVEL >= 1)
        clearScreenOld(false, true, true);
      #endif // (VERBOSE_LEVEL >= 1)

      execute_string(line1,exec, scanning);

      #if(VERBOSE_LEVEL >= 2)
        #if defined(DMCP_BUILD)
          press_key();
          clearScreenOld(false, true, true);
        #endif // DMCP_BUILD
      #endif // (VERBOSE_LEVEL >= 2)

    #endif // !TESTSUITE_BUILD
  #endif // !SAVE_SPACE_DM42_2
}



void fnXEQMENU(uint16_t XEQM_no) {
  #if !defined(TESTSUITE_BUILD)
//    clearScreenOld(false, true, true);
//    print_linestr("Loading XEQM program file:", true);

    printStatus(0, XeqmMsgs[0].itemName,force);

    char line[XEQ_STR_LENGTH_LONG];
    XEQMENU_Selection( XEQM_no, line, EXEC, !SCAN);

    refreshScreen(0);

    //calcMode = CM_BUG_ON_SCREEN;
    //temporaryInformation = TI_NO_INFO;
  #endif // !TESTSUITE_BUILD
}                                               // DOES NOT RETURN TO ##C in items.


void XEQMENU_loadAllfromdisk(void) {
  #if !defined(SAVE_SPACE_DM42_2)
    #if !defined(TESTSUITE_BUILD)
      //uint16_t Delay;
      clearScreenOld(false, true, true);
      print_inlinestr("", true);
      print_inlinestr(XeqmMsgs[1].itemName, false); //Loading XEQM:

      char line[XEQ_STR_LENGTH_LONG];

      char tmp[2];
      tmp[1] = 0;
      uint8_t ix = 1;
      while(ix <= 18) {
        tmp[0] = 48+ix + (ix > 9 ? 65-48-10 : 0);
        print_inlinestr(tmp, false);
        XEQMENU_Selection(ix, line, !EXEC, SCAN);
        ix++;
      }
    #endif // !TESTSUITE_BUILD
  #endif // !SAVE_SPACE_DM42_2
}


/*
//Fixed test program, dispatching commands
void testprogram_12(uint16_t unusedButMandatoryParameter) {
  runkey(ITM_TICKS); //622
  runkey(684);       //X<>Y
  sendkeys("2"); runkey(ITM_EXIT1); //EXIT
  runkey(684);   //X<>Y
  runkey(698);   //Y^X
  sendkeys("1"); runkey(ITM_EXIT1); //EXIT
  runkey(780);   //-
  runkey(589);   sendkeys("00"); //STO 00
  runkey(469);   //PRIME?
  runkey(684);   //X<>Y
  runkey(ITM_TICKS);
  runkey(684);   //X<>Y
  runkey(ITM_SUB);
}


//Fixed test program, dispatching commands from text string
void testprogram_1(uint16_t unusedButMandatoryParameter) {
char line1[TMP_STR_LENGTH];
  strcpy(line1,
    "TICKS //RPN Program to demostrate PRIME// "
    "\"2\" EXIT "
    "\"2203\" "
    "Y^X "
    "\"1\" - "
    "PRIME?  "
    "X<>Y "
    "TICKS "
    "X<>Y - "
    "\"10.0\" / "
    "RETURN "
    "ABCDEFGHIJKLMNOPQ!@#$%^&*()\n"
  );
  displaywords(line1);
  execute_string(line1,true);
}
*/


void fnXEQMSAVE (uint16_t XEQM_no) {                                  //X-REGISTER TO DISK
  #if !defined(SAVE_SPACE_DM42_2)
    char tt[40];
    if(getRegisterDataType(REGISTER_X) == dtString) {
      xcopy(tmpString + TMP_STR_LENGTH/2, REGISTER_STRING_DATA(REGISTER_X), stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) + 1);
      tt[0] = 0;

      sprintf(tt, "XEQM%02u.TXT", XEQM_no);

      #if defined(PC_BUILD)
        printf(">>> string ready  ## %s:%s\n", tt, tmpString + TMP_STR_LENGTH/2);
        //uint16_t ix = 0;
        //while(ix!=20) {
        //  printf("%d:%d=\n", ix, tmpString[ix]);
        //  ix++;
        //}
        stringToUtf8(tmpString + TMP_STR_LENGTH/2, (uint8_t *)tmpString);
        printf(">>> string in utf ## %s:%s\n", tt, tmpString);
        //ix = 0;
        //while(ix!=20) {
        //  printf("%d:%d=\n", ix, ll[ix]);
        //  ix++;
        //}
      #endif // PC_BUILD

      #if !defined(TESTSUITE_BUILD)
        stringToUtf8(tmpString + TMP_STR_LENGTH/2, (uint8_t *)tmpString);
        if(tt[0] != 0) {
          export_string_to_filename(tmpString, OVERWRITE, pgmpath, tt);  //"res/PROGRAMS"
        }
      #endif // !TESTSUITE_BUILD
    }
  #endif // !SAVE_SPACE_DM42_2
}


void fnXEQMLOAD (uint16_t XEQM_no) {                                  //DISK to X-REGISTER
  #if !defined(SAVE_SPACE_DM42_2)
    #if defined(PC_BUILD)
      printf("LOAD %d\n", XEQM_no);
    #endif // PC_BUILD

    char line1[XEQ_STR_LENGTH_LONG];
    line1[0] = 0;
    XEQMENU_Selection(XEQM_no, line1, !EXEC, !SCAN);
    uint16_t ix = 0;
    while(ix!=20) {
      #if defined(PC_BUILD)
        printf("%d ", line1[ix]);
      #endif // PC_BUILD
      ix++;
    }
    //printf(">>> loaded: utf:%s\n", line1);
    utf8ToString((uint8_t *)line1, line1 + TMP_STR_LENGTH/2);
    //ix = 0;
    //while(ix!=20) {
    //  printf("%d ", line1[ix]);
    //  ix++;
    //}
    //printf(">>> loaded: str:%s\n", line1 + TMP_STR_LENGTH/2);
    int16_t len = stringByteLength(line1 + TMP_STR_LENGTH/2);
    liftStack();
    reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(len), amNone);
    strcpy(REGISTER_STRING_DATA(REGISTER_X), line1 + TMP_STR_LENGTH/2);
  #endif // !SAVE_SPACE_DM42_2
}


#define DISALLOW_ZERO_STRING

void fnXSWAP (uint16_t unusedButMandatoryParameter) {
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

        #if defined (DISALLOW_ZERO_STRING)
          if(!(getRegisterDataType(REGISTER_X) == dtString && REGISTER_STRING_DATA(REGISTER_X)[0]!=0)) { //never allow a zero string in a register
            clearRegister(REGISTER_X);                                                //create 0. instead of zero string
          }
        #endif //DISALLOW_ZERO_STRING

        adjustResult(REGISTER_X, false, false, -1, -1, -1);
        copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_Y);              //restore Y
        clearRegister(TEMP_REGISTER_1);                                             //Clear in case it was a really long longinteger
        //resulting in a converted string in X, with Y unchanged
      }
      if(getRegisterDataType(REGISTER_X) != dtString) {                             //somehow failed to convert then return with whatever was done in X
        if(calcMode==CM_AIM) fnSwapXY(0);                                           //  This could be optimized to still restore the original X register if it had failed to convert
        return;
      }
      //Save aimbuffer to TEMP1 as a string register
      int16_t len = stringByteLength(aimBuffer) + 1;
      reallocateRegister(TEMP_REGISTER_1, dtString, TO_BLOCKS(len), amNone);
      xcopy(REGISTER_STRING_DATA(TEMP_REGISTER_1), aimBuffer, len);

      //In essence, after conversions,
      //If X is string shorter than buffer max, copy X to aimbuffer
      //If X is no string, ignore, then aimbuffer remains unchanged.
      if(getRegisterDataType(REGISTER_X) == dtString) {
        if(stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) < AIM_BUFFER_LENGTH) {
          strcpy(aimBuffer, REGISTER_STRING_DATA(REGISTER_X));

          #if defined(DISALLOW_ZERO_STRING)
            if(!(getRegisterDataType(TEMP_REGISTER_1) == dtString && REGISTER_STRING_DATA(TEMP_REGISTER_1)[0]!=0)) { //never allow a zero string in a register
              clearRegister(TEMP_REGISTER_1);
              goto returnZeroAim;
            } else
          #endif //DISALLOW_ZERO_STRING
          {
            //copy aimbuffer to X
            copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_X);
          }


          //Set cursors
          if(calcMode==CM_AIM) {
            fnSwapXY(0);
            T_cursorPos = stringByteLength(aimBuffer);
          } else { //EIM
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
        if(eRPN) {      //JM NEWERPN
          setSystemFlag(FLAG_ASLIFT);            //JM NEWERPN OVERRIDE SLS, AS ERPN ENTER ALWAYS HAS SLS SET
        }                                        //JM NEWERPN
        strcpy(aimBuffer, REGISTER_STRING_DATA(REGISTER_X));
        T_cursorPos = stringByteLength(aimBuffer);
        fnDrop(0);
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
      if(eRPN) {      //JM NEWERPN
        setSystemFlag(FLAG_ASLIFT);            //JM NEWERPN OVERRIDE SLS, AS ERPN ENTER ALWAYS HAS SLS SET
      }                                        //JM NEWERPN
      liftStack();
      reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(len), amNone);
      strcpy(REGISTER_STRING_DATA(REGISTER_X), line1);
      fnXSWAP(0);
    }
  #if defined(DISALLOW_ZERO_STRING)
    returnZeroAim:
  #endif //DISALLOW_ZERO_STRING

  last_CM = 252;
  refreshScreen(63);
  last_CM = 251;
  refreshScreen(0);
}


void fnXEQMexecute(char *line1) {
  #if defined(PC_BUILD)
    printf("Execute: %s\n",line1);
  #endif
  displaywords(line1);
  execute_string(line1, !EXEC, !SCAN); //Run to catch all label names
  execute_string(line1,  EXEC, !SCAN); //Run to execute
}


void fnXEQMXXEQ (uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_2)
    char line1[XEQ_STR_LENGTH_LONG];
    if(getRegisterDataType(REGISTER_X) == dtString) {
      xcopy(line1, REGISTER_STRING_DATA(REGISTER_X), stringByteLength(REGISTER_STRING_DATA(REGISTER_X)) + 1);
      fnDrop(0);
      fnXEQMexecute(line1);
    }
  #endif // !SAVE_SPACE_DM42_2
}


void fnXEQNEW (uint16_t unusedButMandatoryParameter) {
  #if !defined(SAVE_SPACE_DM42_2)
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    fnStrtoX(XeqmMsgs[2].itemName);  // "XEQC47 XEQLBL 01 XXXXXX "
    fnXSWAP(0);
    fnDrop(0);
  #endif // !SAVE_SPACE_DM42_2
}
