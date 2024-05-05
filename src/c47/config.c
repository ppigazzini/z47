// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file config.c
 ***********************************************/

#include "config.h"

#include "assign.h"
#include "browsers/fontBrowser.h"
#include "bufferize.h"
#include "calcMode.h"
#include "charString.h"
#include "constantPointers.h"
#include "constants.h"
#include "dateTime.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "fonts.h"
#include "flags.h"
#include "fractions.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/addons.h"
#include "c43Extensions/graphText.h"
#include "c43Extensions/keyboardTweak.h"
#include "keyboard.h"
#include "mathematics/matrix.h"
#include "mathematics/square.h"
#include "memory.h"
#include "plotstat.h"
#include "programming/manage.h"
#include "programming/programmableMenu.h"
#include "c43Extensions/graphs.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "c43Extensions/xeqm.h"
#include "recall.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "saveRestoreCalcState.h"
#include "screen.h"
#include "softmenus.h"
#include "solver/equation.h"
#include "stack.h"
#include "stats.h"
#include "statusBar.h"
#include "store.h"
#include "recall.h"
#include <stdlib.h>
#include <string.h>

#include "c47.h"

#include <hal/io.h>



//C47 defaults (used in both settings arrays)
#define _gapl   ITM_SPACE_PUNCTUATION
#define _gprl   3
#define _gpr1x  0
#define _gpr1   0
#define _gprr   3
#define _gapr   ITM_SPACE_PUNCTUATION
#define _gaprx  ITM_PERIOD

TO_QSPI static const struct {
    unsigned tdm24 : 1;
    unsigned dmy : 1;
    unsigned mdy : 1;
    unsigned ymd : 1;
    unsigned gregorianDay : 22;
    unsigned gapl : 16;
    unsigned gprl : 4;
    unsigned gpr1x: 4;
    unsigned gpr1 : 4;
    unsigned gprr : 4;
    unsigned gapr : 16;
    unsigned gaprx : 16;


} configSettings[] = {
                /*                         gapl                     gprl  gpr1x  gpr1  gprr     gapr                                   */
                /*   24  D M Y  Gregorian  GAP char                 GRP   GRPx   GRP1  FP.GRP   FP.GAP char               New Radix    */
    [CFG_DFLT  ] = {  1, 0,0,1, 2361222,   _gapl                , _gprl, _gpr1x, _gpr1, _gprr, _gapr                 ,   _gaprx    },    /* 14 Sep 1752 */
    [CFG_CHINA ] = {  1, 0,0,1, 2433191,   ITM_COMMA            ,    4,    0,    0,    4,      ITM_COMMA             ,   ITM_PERIOD},    /*  1 Oct 1949 */
    [CFG_EUROPE] = {  1, 1,0,0, 2299161,   ITM_SPACE_PUNCTUATION,    3,    0,    0,    3,      ITM_SPACE_PUNCTUATION ,   ITM_COMMA },    /* 15 Oct 1582 */
    [CFG_INDIA ] = {  1, 1,0,0, 2361222,   ITM_COMMA            ,    2,    0,    3,    2,      ITM_COMMA             ,   ITM_PERIOD},    /* 14 Sep 1752 */
    [CFG_JAPAN ] = {  1, 0,0,1, 2405160,   ITM_SPACE_PUNCTUATION,    3,    0,    0,    3,      ITM_SPACE_PUNCTUATION ,   ITM_PERIOD},    /*  1 Jan 1873 */
    [CFG_UK    ] = {  0, 1,0,0, 2361222,   ITM_SPACE_PUNCTUATION,    3,    0,    0,    3,      ITM_SPACE_PUNCTUATION ,   ITM_PERIOD},    /* 14 Sep 1752 */
    [CFG_USA   ] = {  0, 0,1,0, 2361222,   ITM_COMMA            ,    3,    9,    0,    3,      ITM_NULL              ,   ITM_PERIOD},    /* 14 Sep 1752 */
};

void configCommon(uint16_t idx) {
  #if !defined(TESTSUITE_BUILD)
    if(checkHP) {
      fnSetC47(0);
    }
  #endif // !TESTSUITE_BUILD

  forceSystemFlag(FLAG_TDM24, configSettings[idx].tdm24);
  forceSystemFlag(FLAG_DMY, configSettings[idx].dmy);
  forceSystemFlag(FLAG_MDY, configSettings[idx].mdy);
  forceSystemFlag(FLAG_YMD, configSettings[idx].ymd);
  firstGregorianDay = configSettings[idx].gregorianDay;
  temporaryInformation = TI_DISP_JULIAN;

  fnSetGapChar (0 + configSettings[idx].gapl);
  grpGroupingLeft            = configSettings[idx].gprl ;
  grpGroupingGr1LeftOverflow = configSettings[idx].gpr1x;
  grpGroupingGr1Left         = configSettings[idx].gpr1 ;
  grpGroupingRight           = configSettings[idx].gprr ;
  fnSetGapChar (32768+configSettings[idx].gapr);
  fnSetGapChar (49152+configSettings[idx].gaprx);
}





#define xxx -10001
#define _Reset 1
#define _HP35  2
#define _JM    3
#define _RJ    4
#define _C47   5
#define _DefltSB 6
#define _TVM     7
#define _numberOfGrps 7

TO_QSPI const int32_t Settings[] = { 
//variable     n/a       Reset                        HP35            JM             RJ                         C47           DefltSB       TVM
       101,    xxx,      xxx,                         ID_DP,          xxx,           xxx,                       ID_43S,       xxx,          xxx,    //fnInDefault
       102,    xxx,      xxx,                         9,              3,             xxx,                       xxx,          xxx,          xxx,    //fnDisplayFormatSigFig
       103,    xxx,      xxx,                         xxx,            xxx,           xxx,                       3,            xxx,          xxx,    //fnDisplayFormatAll
       104,    xxx,      xxx,                         xxx,            xxx,           3,                         xxx,          xxx,          xxx,    //fnDisplayFormatFix
       105,    xxx,      1,                           0,              xxx,           xxx,                       1,            xxx,          xxx,    //BASE_MYM
       106,    xxx,      0,                           0,              xxx,           xxx,                       0,            xxx,          xxx,    //BASE_HOME
       107,    xxx,      6145,                        99,             xxx,           xxx,                       6145,         xxx,          xxx,    //exponentLimit
       108,    xxx,      0,                           16,             xxx,           xxx,                       34,           xxx,          xxx,    //significantDigits
       109,    xxx,      4,                           1,              xxx,           xxx,                       4,            xxx,          xxx,    //displayStack
       110,    xxx,      4,                           1,              xxx,           xxx,                       4,            xxx,          xxx,    //cachedDisplayStack
       111,    xxx,      amDegree,                    amRadian,       amDegree,      amRadian,                  amDegree,     xxx,          xxx,    //currentAngularMode
       112,    xxx,      3,                           3,              xxx,           xxx,                       _gprl,        xxx,          xxx,    //grpGroupingLeft
       113,    xxx,      3,                           3,              xxx,           xxx,                       _gprr,        xxx,          xxx,    //grpGroupingRight
       114,    xxx,      0,                           0,              xxx,           xxx,                       _gpr1,        xxx,          xxx,    //grpGroupingGr1Left
       115,    xxx,      0,                           0,              xxx,           1,                         _gpr1x,       xxx,          xxx,    //grpGroupingGr1LeftOverflow
       116,    xxx,      1,                           0,              xxx,           xxx,                       1,            xxx,          xxx,    //fneRPN
       117,    xxx,      xxx,                         RB_FGLNOFF,     xxx,           xxx,                       RB_FGLNFUL,   xxx,          xxx,    //setFGLSettings
       118,    xxx,      0,                           xxx,            xxx,           0,                         xxx,          xxx,          xxx,    //constantFractions    
       119,    xxx,      CF_NORMAL,                   xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,    //constantFractionsMode
       120,    xxx,      0,                           xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,    //constantFractionsOn
       121,    xxx,      64,                          xxx,            xxx,           9999,                      64,           xxx,          xxx,    //denmax

//TVM
 RESERVED_VARIABLE_FV     , xxx,   0,                 xxx,            xxx,           xxx,                       xxx,          xxx,          0,
 RESERVED_VARIABLE_IPONA  , xxx,   0,                 xxx,            xxx,           xxx,                       xxx,          xxx,          0,
 RESERVED_VARIABLE_NPPER  , xxx,   0,                 xxx,            xxx,           xxx,                       xxx,          xxx,          0,
 RESERVED_VARIABLE_PMT    , xxx,   0,                 xxx,            xxx,           xxx,                       xxx,          xxx,          0,
 RESERVED_VARIABLE_PV     , xxx,   0,                 xxx,            xxx,           xxx,                       xxx,          xxx,          0,
 RESERVED_VARIABLE_PPERONA, xxx,  12,                 xxx,            xxx,           xxx,                       xxx,          xxx,          12,
 RESERVED_VARIABLE_CPERONA, xxx,  12,                 xxx,            xxx,           xxx,                       xxx,          xxx,          12,
       3,      0,        FLAG_TVM_I_KNOWN,            xxx,            xxx,           xxx,                       xxx,          xxx,          FLAG_TVM_I_KNOWN,
       3,      0,        FLAG_TVM_I_CHANGES,          xxx,            xxx,           xxx,                       xxx,          xxx,          FLAG_TVM_I_CHANGES,
       3,      1,        FLAG_ENDPMT       ,          xxx,            xxx,           xxx,                       xxx,          xxx,          FLAG_ENDPMT,



//Setsetting   n/a       Reset                        HP35            JM             RJ                         C47           DefltSB       TVM
       2,      xxx,      xxx,                         SS_4       ,    SS_8,          xxx,                       SS_8,         xxx,          xxx,   //SetSetting
       2,      xxx,      xxx,                         ITM_CPXRES0,    ITM_CPXRES1,   xxx,                       ITM_CPXRES1,  xxx,          xxx,   //SetSetting
       2,      xxx,      xxx,                         ITM_SPCRES0,    ITM_SPCRES1,   xxx,                       ITM_SPCRES1,  xxx,          xxx,   //SetSetting
       2,      xxx,      xxx,                         xxx,            xxx,           JC_IRFRAC,                 xxx,          xxx,          xxx,   //SetSetting

//FLAG,       set/clear, Reset                        HP35            JM             RJ                         C47           DefltSB    
       3,      0,        FLAG_FRCYC        ,          xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag(FLAG_FRCYC);
       3,      1,        FLAG_MONIT        ,          xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag(FLAG_MONIT);
       3,      1,        FLAG_SH_LONGPRESS ,          xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag(FLAG_SH_LONGPRESS);

       3,      0,        xxx,                         xxx,            FLAG_USER,     FLAG_USER,                 xxx,          xxx        ,  xxx,  //clearSystemFlag
       3,      1,        FLAG_SBdate,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBdate,  xxx,  //setSystemFlag
       3,      0,        FLAG_SBtime,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBtime,  xxx,  //clearSystemFlag
       3,      0,        FLAG_SBcr,                   xxx,            xxx,           xxx,                       xxx,          FLAG_SBcr  ,  xxx,  //clearSystemFlag
       3,      1,        xxx,                         xxx,            xxx,           FLAG_SBcr,                 xxx,          xxx        ,  xxx,  //setSystemFlag
       3,      1,        FLAG_SBcpx,                  xxx,            xxx,           xxx,                       xxx,          FLAG_SBcpx ,  xxx,  //setSystemFlag
       3,      0,        FLAG_SBang,                  xxx,            xxx,           xxx,                       xxx,          FLAG_SBang ,  xxx,  //clearSystemFlag
       3,      1,        FLAG_SBfrac,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBfrac,  xxx,  //setSystemFlag
       3,      1,        FLAG_SBint ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBint ,  xxx,  //setSystemFlag
       3,      0,        xxx        ,                 xxx,            xxx,           FLAG_SBint,                xxx,          xxx        ,  xxx,  //clearSystemFlag
       3,      0,        FLAG_SBmx  ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBmx  ,  xxx,  //clearSystemFlag
       3,      1,        xxx        ,                 xxx,            xxx,           FLAG_SBmx,                 xxx,          xxx        ,  xxx,  //setSystemFlag
       3,      1,        FLAG_SBtvm ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBtvm ,  xxx,  //setSystemFlag
       3,      1,        FLAG_SBoc  ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBoc  ,  xxx,  //setSystemFlag
       3,      0,        FLAG_SBss  ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBss  ,  xxx,  //clearSystemFlag
       3,      1,        FLAG_SBclk ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBclk ,  xxx,  //setSystemFlag
       3,      0,        xxx        ,                 xxx,            xxx,           FLAG_SBclk,                xxx,          xxx        ,  xxx,  //clearSystemFlag
       3,      1,        FLAG_SBser ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBser ,  xxx,  //setSystemFlag
       3,      1,        FLAG_SBprn ,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBprn ,  xxx,  //setSystemFlag
       3,      0,        FLAG_SBbatV,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBbatV,  xxx,  //clearSystemFlag
       3,      1,        xxx,                         xxx,            FLAG_SBbatV,   FLAG_SBbatV,               xxx,          xxx        ,  xxx,  //setSystemFlag
       3,      0,        FLAG_SBshfR,                 xxx,            xxx,           xxx,                       xxx,          FLAG_SBshfR,  xxx,  //clearSystemFlag
       3,      0,        FLAG_FRACT ,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag
       3,      1,        FLAG_DENANY,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag        //overwritten
       3,      1,        FLAG_MULTx ,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      1,        FLAG_AUTOFF,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      1,        FLAG_ASLIFT,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag        //overwritten
       3,      1,        FLAG_PROPFR,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      1,        FLAG_ENDPMT,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      1,        FLAG_HPRP  ,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      0,        xxx        ,                 xxx,            FLAG_HPRP,     FLAG_HPRP,                 xxx,          xxx,          xxx,  //clearSystemFlag
       3,      1,        FLAG_HPBASE,                 xxx,            FLAG_HPBASE,   xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      0,        xxx        ,                 xxx,            xxx,           FLAG_HPBASE,               xxx,          xxx,          xxx,  //clearSystemFlag
       3,      0,        FLAG_2TO10 ,                 xxx,            FLAG_2TO10,    FLAG_2TO10,                xxx,          xxx,          xxx,  //clearSystemFlag
       3,      0,        xxx        ,                 xxx,            FLAG_POLAR,    xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag
       3,      0,        xxx ,                        xxx,            xxx,           xxx,                       FLAG_CPXj,    xxx,          xxx,  //clearSystemFlag
       3,      1,        xxx,                         xxx,            FLAG_CPXj,     xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      0,        FLAG_FRCSRN ,                xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag
       3,      1,        xxx,                         xxx,            FLAG_FRCSRN,   xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      1,        FLAG_CPXRES,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      1,        FLAG_SSIZE8,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag
       3,      0,        FLAG_DENANY,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag
       3,      1,        xxx,                         xxx,            xxx,           FLAG_DENANY,               xxx,          xxx,          xxx,  //setSystemFlag
       3,      0,        FLAG_ASLIFT,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag
       3,      0,        FLAG_DENFIX,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //clearSystemFlag
       3,      1,        FLAG_SPCRES,                 xxx,            xxx,           xxx,                       xxx,          xxx,          xxx,  //setSystemFlag

//fnSetGapChar n/a       Reset                        HP35            JM             RJ                         C47           DefltSB    
       4,      xxx,      0+    ITM_SPACE_PUNCTUATION, ITM_NULL,       xxx,           0+    ITM_SPACE_4_PER_EM,  0 +   _gapl,  xxx,          xxx,  //fnSetGapChar
       4,      xxx,      32768+ITM_SPACE_PUNCTUATION, ITM_NULL+32768, xxx,           32768+ITM_NULL          ,  32768+_gapr,  xxx,          xxx,  //fnSetGapChar
       4,      xxx,      49152+ITM_PERIOD           , ITM_WDOT+49152, xxx,           49152+ITM_WCOMMA        ,  49152+_gaprx, xxx,          xxx,  //fnSetGapChar

       0,      0,        0,                           0,              0,             0,                         0,            0,            0
    };


void Sett(int16_t grp) {
  int16_t ptr = -1;
  real_t realt;

  while(Settings[++ptr*(_numberOfGrps+2) + 0] != 0) {
    if(Settings[  ptr*(_numberOfGrps+2) + 1 + grp] != xxx) {

      #if defined(PC_BUILD)
        if(Settings[ptr*(_numberOfGrps+2) + 0] >= 101 && Settings[ptr*(_numberOfGrps+2) + 0] <= 121) {
          printf("\nSett1:%5d,  +0=%5d, +1=%5d, +1+grp=%5d ",ptr, Settings[ptr*(_numberOfGrps+2) + 0], Settings[ptr*(_numberOfGrps+2) + 1], Settings[ptr*(_numberOfGrps+2) + 1 + grp]);
        }
      #endif //PC_BUILD
      switch (Settings[ptr*(_numberOfGrps+2) + 0]) {
        case 101: {fnInDefault                  (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 102: {fnDisplayFormatSigFig        (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 103: {fnDisplayFormatAll           (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 104: {fnDisplayFormatFix           (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 105: {BASE_MYM  =                  (Settings[ptr*(_numberOfGrps+2) + 1 + grp]) == 1 ? true : false;break;}
        case 106: {BASE_HOME =                  (Settings[ptr*(_numberOfGrps+2) + 1 + grp]) == 1 ? true : false;break;}
        case 107: {exponentLimit      =         (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 108: {significantDigits  =         (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 109: {displayStack       =         (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 110: {cachedDisplayStack =         (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 111: {currentAngularMode =         (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 112: {grpGroupingLeft            = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 113: {grpGroupingRight           = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 114: {grpGroupingGr1Left         = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 115: {grpGroupingGr1LeftOverflow = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 116: {fneRPN                       (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 117: {setFGLSettings               (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 118: {constantFractions          = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]) == 1 ? true : false;break;}
        case 119: {constantFractionsMode      = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}
        case 120: {constantFractionsOn        = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]) == 1 ? true : false;break;}
        case 121: {denMax                     = (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);break;}

        case RESERVED_VARIABLE_FV     :
        case RESERVED_VARIABLE_IPONA  : 
        case RESERVED_VARIABLE_NPPER  : 
        case RESERVED_VARIABLE_PMT    : 
        case RESERVED_VARIABLE_PV     :  
        case RESERVED_VARIABLE_PPERONA:
        case RESERVED_VARIABLE_CPERONA: {
            int32ToReal(Settings[ptr*(_numberOfGrps+2) + 1 + grp],&realt);
            reallocateRegister(Settings[ptr*(_numberOfGrps+2) + 0], dtReal34, REAL34_SIZE_IN_BLOCKS, amNone);
            realToReal34(&realt, REGISTER_REAL34_DATA(Settings[ptr*(_numberOfGrps+2) + 0]));
            #if defined(PC_BUILD)
              printf("Sett1A Register %d = ",Settings[ptr*(_numberOfGrps+2) + 0]);
              printRegisterToConsole(Settings[ptr*(_numberOfGrps+2) + 0]," : ","\n");
            #endif //PC_BUILD
            break;
          }
    
        case 2 : {
            #if defined(PC_BUILD)
              printf("\nSett2:%5d:%5d\n",ptr,Settings[ptr*(_numberOfGrps+2) + 1 + grp]);
            #endif //PC_BUILD
            SetSetting (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);
            break;
          } 

        case 3: {
          #if defined(PC_BUILD)
            printf("\nSett3:%5d:%5d",ptr,Settings[ptr*(_numberOfGrps+2) + 1 + grp]);
          #endif //PC_BUILD
          forceSystemFlag (Settings[ptr*(_numberOfGrps+2) + 1 + grp], Settings[  ptr*(_numberOfGrps+2) + 1 ]); 
          break;
          } 

        case 4: {
          #if defined(PC_BUILD)
            printf("\nSett4:%5d:%5d",ptr,Settings[ptr*(_numberOfGrps+2) + 1 + grp]); 
          #endif //PC_BUILD
          fnSetGapChar (Settings[ptr*(_numberOfGrps+2) + 1 + grp]);
          }
        default:break;
      }
    }
  }
  #if defined(PC_BUILD)
    printf("\n");
  #endif //PC_BUILD
}



#if !defined(TESTSUITE_BUILD)
  void fnSetHP35(uint16_t unusedButMandatoryParameter) {
    getDateString(lastStateFileOpened);
    strcat(lastStateFileOpened,": HP35 defaults");
    fnKeyExit(0);                            //Clear pending key input
    fnClrMod(0);                             //Get out of NIM or BASE
    fnStoreConfig(35);                       //Store current config into R35

    fnClearStack(0);                         //Clear stack
    fnPi(0);                                 //Put pi on X

    Sett(_HP35);
    //---    fnInDefault(ID_DP);                      //Change to Real input only :                                     ID, if changed, also set the conditions for checkHP in defines.h (DP)
    //---    fnDisplayFormatSigFig(9);                //SIG 9                                                           There is special treatment for the Sig mode in the display driver, to restrict to 9+1 digits while SDIGS > 10
    //---    BASE_MYM = false;                        //Switch off base = MyMenu
    //---    BASE_HOME = false;                       //Ensure base = HOME is off
    //---    exponentLimit     = 99;                  //Set the exponent limit the same as HP35, i.e. 99                ID, if changed, also set the conditions for checkHP in defines.h (99)
    //---    significantDigits = 16;                  //SETSIG2 = 16                                                    ID, if changed, also set the conditions for checkHP in defines.h (10-16)
    //---    displayStack = cachedDisplayStack = 1;   //Change to single stack register display                         ID, if changed, also set the conditions for checkHP in defines.h (1)
    //---    currentAngularMode = amRadian;           //Set to RAD
    //---    SetSetting(SS_4);                        //SSTACK4
    //---    SetSetting(ITM_CPXRES0);                 //Clear CPXRES
    //---    SetSetting(ITM_SPCRES0);                 //Clear SPCRES
    //---    fneRPN(0);                               //RPN
    //---    setFGLSettings(RB_FGLNOFF);              //fgLine OFF
    //---    grpGroupingLeft    =  3;                 //IPGRP 3
    //---    grpGroupingRight   =  3;                 //FPGRP 3
    //---    grpGroupingGr1Left =  0;                 //IPGRP1 0
    //---    grpGroupingGr1LeftOverflow = 0;          //IPGRP1x 0
    //---    fnSetGapChar(ITM_NULL);                  //IPART nil
    //---    fnSetGapChar(ITM_NULL+32768);            //FPART nil
    //---    fnSetGapChar(ITM_WDOT+49152);            //RADIX WDOT
    //---    fnSetFlag(FLAG_USER);                    //Set USER mode

    temporaryInformation = TI_NO_INFO;       //Clear any pending TI
    fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(160);
  }


  void fnSetJM(uint16_t unusedButMandatoryParameter){
    fnDrop(0);
    fnSquare(0);
    resetOtherConfigurationStuff();
    getDateString(lastStateFileOpened);
    strcat(lastStateFileOpened,": Jaco defaults");


    //---    defaultStatusBar();
    Sett(_JM);
    //---    fnClearFlag    (FLAG_USER);              // Clear USER mode
    //---    clearSystemFlag(FLAG_HPRP  );            // Clear HP Rect/Polar
    //---    setSystemFlag  (FLAG_HPBASE);            // Set HP Base
    //---    clearSystemFlag(FLAG_2TO10 );
    //---    clearSystemFlag(FLAG_POLAR );            // Set rectangular default
    //---    SetSetting     (SS_8);                   // SSTACK 8
    //---    SetSetting     (ITM_CPXRES1);            // Set CPXRES
    //---    SetSetting     (ITM_SPCRES1);            // Set SPCRES
    //---    setSystemFlag  (FLAG_CPXj);              // Set j
    //---    setSystemFlag  (FLAG_SBbatV);            // Set battery voltage indicator
    //---    fnDisplayFormatSigFig(3);                // SIG 3
    //---    setSystemFlag(FLAG_FRCSRN);              // Display

    roundingMode = RM_HALF_UP;
    fnKeysManagement(USER_MC47);

    itemToBeAssigned = -MNU_EE;
    assignToMyMenu(6);
    itemToBeAssigned = ITM_op_j_pol;
    assignToMyMenu(11);


    cachedDynamicMenu = 0;

    setSystemFlag(FLAG_SH_LONGPRESS);
    temporaryInformation = TI_NO_INFO;
    fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(161);
    }


  void fnSetRJ(uint16_t unusedButMandatoryParameter){
    resetOtherConfigurationStuff();
    getDateString(lastStateFileOpened);
    strcat(lastStateFileOpened,": RJvM defaults");

    //---    defaultStatusBar();
    Sett(_RJ);
    //---    currentAngularMode = amRadian;                 // RAD
    //---    clearSystemFlag(FLAG_HPRP);                    // HP.RP off
    //---    clearSystemFlag(FLAG_HPBASE);                  // Clear HP Base
    //---    clearSystemFlag(FLAG_2TO10);
    //---    denMax = 9999;                                 // DMX 9999
    //---    constantFractions = false;
    //---    SetSetting(JC_IRFRAC); // IRFRAC ON (also setting the fractions modes appropriately)
    //---    setSystemFlag(FLAG_DENANY);                    // DENANY ON
    //---       setSystemFlag(FLAG_SBbatV );                // SBbatV ON
    //---     clearSystemFlag(FLAG_SBclk  );                // SBclk OFF
    //---       setSystemFlag(FLAG_SBcr   );                // SBcr ON
    //---     clearSystemFlag(FLAG_SBint  );                // SBint OFF
    //---       setSystemFlag(FLAG_SBmx   );                // SBmx ON
    //---    fnDisplayFormatFix(3);                        // FIX 3
    //---     fnSetGapChar(0+    ITM_SPACE_4_PER_EM);       // IPART NSPC
    //---     fnSetGapChar(32768+ITM_NULL);                 // FPART NONE
    //---     fnSetGapChar(49152+ITM_WCOMMA);               // RADIX WCOM
    //---     grpGroupingGr1LeftOverflow = 1;               //IPGRP1x = 1

     setSystemFlag(FLAG_SH_LONGPRESS);
     fnKeyExit(0);
     fnDrop(0);
     fnSquare(0);
     fnRefreshState();
     screenUpdatingMode = SCRUPD_AUTO;
     refreshScreen(165);
    }


  void _fnSetC47(uint16_t unusedButMandatoryParameter) {         //Reversing the HP35 settings to C47 defaults
    fnKeyExit(0);
    addItemToBuffer(ITM_EXIT1);
    getDateString(lastStateFileOpened);
    strcat(lastStateFileOpened,": C47 defaults");

    Sett(_C47);
    //---    fnInDefault(ID_43S);                     //!ID
    //---    fnDisplayFormatAll(3);
    //---    BASE_MYM = true;
    //---    BASE_HOME = false;
    //---    exponentLimit     = 6145;                //!ID
    //---    significantDigits = 34;                  //!ID
    //---    displayStack = cachedDisplayStack = 4;   //!ID
    //---    currentAngularMode = amDegree;
    //---    SetSetting(SS_8);
    //---    SetSetting(ITM_CPXRES1);
    //---    SetSetting(ITM_SPCRES1);
    //---    clearSystemFlag(FLAG_CPXj);
    //---    fneRPN(1); //eRPN
    //---    setFGLSettings(RB_FGLNFUL); //fgLine ON
    //---    grpGroupingLeft            = configSettings[CFG_DFLT].gprl ;
    //---    grpGroupingGr1LeftOverflow = configSettings[CFG_DFLT].gpr1x;
    //---    grpGroupingGr1Left         = configSettings[CFG_DFLT].gpr1 ;
    //---    grpGroupingRight           = configSettings[CFG_DFLT].gprr ;
    //---    fnSetGapChar (0 + configSettings[CFG_DFLT].gapl);
    //---    fnSetGapChar (32768+configSettings[CFG_DFLT].gapr);
    //---    fnSetGapChar (49152+configSettings[CFG_DFLT].gaprx);
    //---    fnClearFlag(FLAG_USER);                    //Set USER mode

    temporaryInformation = TI_NO_INFO;
    fnRefreshState();

    fnDrop(0);
    fnDrop(0);
    runFunction(ITM_SQUARE);
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(162);
  }


void fnSetC47(uint16_t unusedButMandatoryParameter) {
    fnKeyExit(0);
    addItemToBuffer(ITM_EXIT1);
    fnClrMod(0);
    _fnSetC47(0);               //Needs a reset in case for some reason RCLCFG R35 fails, then it resets to defaults
    fnRecallConfig(35);         //restores previously stored C47 config
    lastErrorCode = 0;
    fnRefreshState();
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(167);
  }
#endif // !TESTSUITE_BUILD



void fnClrMod(uint16_t unusedButMandatoryParameter) {        //clear input buffe
  #if defined(PC_BUILD)
    jm_show_comment("^^^^fnClrModa");
  #endif // PC_BUILD
  #if !defined(TESTSUITE_BUILD)
    resetKeytimers();  //JM
    clearSystemFlag(FLAG_FRACT);

    if(calcMode == CM_NIM) {
      strcpy(aimBuffer, "+");
      fnKeyBackspace(0);
      //printf("|%s|\n", aimBuffer);
    }
    if(calcMode == CM_ASSIGN) {
      fnKeyExit(0);
    }
    fnKeyExit(0);           //Call fnkeyExit to ensure the correct home screen is brought up, if HOME is selected.
    fnKeyExit(0);           //Second time to ensure not only keys exited, but also modes
    popSoftmenu();
    lastIntegerBase = 0;
    temporaryInformation = TI_NO_INFO;
    lastErrorCode = 0;
    currentInputVariable = INVALID_VARIABLE;
    fnExitAllMenus(0);
    if(!checkHP) {
      fnDisplayStack(4);    //Restore to default DSTACK 4
    } else {                //Snap out of HP35 mode, and reset all setting needed for that
      _fnSetC47(0);
      fnRecallConfig(35);
      lastErrorCode = 0;
    }
    calcModeNormal();
    screenUpdatingMode = SCRUPD_AUTO;
    shiftF = false;
    shiftG = false;
    showShiftState();
    refreshModeGui();
    refreshScreen(166);
    #if defined(PC_BUILD_TELLTALE)
      jm_show_calc_state("fnClrMod end: \n");
    #endif //PC_BUILD_TELLTALE
  #endif // !TESTSUITE_BUILD
}



void fnSetGapChar (uint16_t charParam) {
  //printf(">>>> charParam=%u %u \n", charParam, charParam & 16383);
  if((charParam & 49152) == 0) {                        //+0 for the left hand separator
    gapItemLeft = charParam & 16383;
  } else
  if((charParam & 49152) == 32768) {                        //+32768 for the right hand separator
    gapItemRight = charParam & 16383;
  } else
  if((charParam & 49152) == 49152) {                        //+49152 for the radix separator
    gapItemRadix = charParam & 16383;
  }
//printf("LT=%s RT=%s RX=%s\n",Lt, Rt, Rx);
//printf("Post: gapCharL0=%u gapCharL1=%u gapCharR0=%u gapCharR1=%u gapCharRx0=%u gapCharRx1%u  \n", (uint8_t)gapChar1Left[0], (uint8_t)gapChar1Left[1], (uint8_t)gapChar1Right[0], (uint8_t)gapChar1Right[1],  (uint8_t)gapChar1Radix[0], (uint8_t)gapChar1Radix[1]);
}


void fnSettingsDispFormatGrpL   (uint16_t param) {
  grpGroupingLeft = param;
}
void fnSettingsDispFormatGrp1Lo  (uint16_t param) {
  grpGroupingGr1LeftOverflow = param;
}
void fnSettingsDispFormatGrp1L  (uint16_t param) {
  grpGroupingGr1Left = param;
}
void fnSettingsDispFormatGrpR   (uint16_t param) {
  grpGroupingRight = param;
}

void fnMenuGapL (uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    showSoftmenu(-MNU_GAP_L);
  #endif // ! TESTSUITE_BUILD
}

void fnMenuGapRX (uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    showSoftmenu(-MNU_GAP_RX);
  #endif // ! TESTSUITE_BUILD
}

void fnMenuGapR (uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    showSoftmenu(-MNU_GAP_R);
  #endif // ! TESTSUITE_BUILD
}






void fnIntegerMode(uint16_t mode) {
  shortIntegerMode = mode;
  fnRefreshState();
}



void fnWho(uint16_t unusedButMandatoryParameter) {
  temporaryInformation = TI_WHO;
 }



void fnVersion(uint16_t unusedButMandatoryParameter) {
  temporaryInformation = TI_VERSION;
}



void fnFreeMemory(uint16_t unusedButMandatoryParameter) {
  longInteger_t mem;

  liftStack();

  longIntegerInit(mem);
  uIntToLongInteger(getFreeRamMemory(), mem);
  convertLongIntegerToLongIntegerRegister(mem, REGISTER_X);
  longIntegerFree(mem);
  temporaryInformation = TI_BYTES;
}


void fnGetDmx(uint16_t unusedButMandatoryParameter) {
  longInteger_t dmx;

  liftStack();

  longIntegerInit(dmx);
  uIntToLongInteger(denMax, dmx);
  convertLongIntegerToLongIntegerRegister(dmx, REGISTER_X);
  longIntegerFree(dmx);
}


void fnGetRoundingMode(uint16_t unusedButMandatoryParameter) {
  longInteger_t rounding;

  liftStack();

  longIntegerInit(rounding);
  uIntToLongInteger(roundingMode, rounding);
  convertLongIntegerToLongIntegerRegister(rounding, REGISTER_X);
  longIntegerFree(rounding);
}



void fnSetRoundingMode(uint16_t RM) {
  roundingMode = RM;
}

// "enum rounding" does not match with the specification of WP 43s rounding mode.
// So you need roundingModeTable[roundingMode] rather than roundingMode
// to specify rounding mode in the real number functions.
TO_QSPI const enum rounding roundingModeTable[7] = {
  DEC_ROUND_HALF_EVEN, DEC_ROUND_HALF_UP, DEC_ROUND_HALF_DOWN,
  DEC_ROUND_UP, DEC_ROUND_DOWN, DEC_ROUND_CEILING, DEC_ROUND_FLOOR
};



void fnGetIntegerSignMode(uint16_t unusedButMandatoryParameter) {
  fnRecall(RESERVED_VARIABLE_ISM);
}



void fnGetWordSize(uint16_t unusedButMandatoryParameter) {
  longInteger_t wordSize;

  liftStack();

  longIntegerInit(wordSize);
  uIntToLongInteger(shortIntegerWordSize, wordSize);
  convertLongIntegerToLongIntegerRegister(wordSize, REGISTER_X);
  longIntegerFree(wordSize);
  temporaryInformation = TI_BITS;
}



void fnSetWordSize(uint16_t WS) {
  bool_t reduceWordSize;
  if(WS == 0) {
    WS = 64;
  }

  reduceWordSize = (WS < shortIntegerWordSize);

  shortIntegerWordSize = WS;

  if(shortIntegerWordSize == 64) {
    shortIntegerMask    = -1;
  }
  else {
    shortIntegerMask    = ((uint64_t)1 << shortIntegerWordSize) - 1;
  }

  shortIntegerSignBit = (uint64_t)1 << (shortIntegerWordSize - 1);
  //printf("shortIntegerMask  =   %08x-%08x\n", (unsigned int)(shortIntegerMask>>32), (unsigned int)(shortIntegerMask&0xffffffff));
  //printf("shortIntegerSignBit = %08x-%08x\n", (unsigned int)(shortIntegerSignBit>>32), (unsigned int)(shortIntegerSignBit&0xffffffff));

  if(reduceWordSize) {
    // reduce the word size of integers on the stack
    for(calcRegister_t regist=REGISTER_X; regist<=getStackTop(); regist++) {
      if(getRegisterDataType(regist) == dtShortInteger) {
        *(REGISTER_SHORT_INTEGER_DATA(regist)) &= shortIntegerMask;
      }
    }

    // reduce the word size of integers in the L register
    if(getRegisterDataType(REGISTER_L) == dtShortInteger) {
      *(REGISTER_SHORT_INTEGER_DATA(REGISTER_L)) &= shortIntegerMask;
    }
  }

  fnRefreshState();                              //dr

}



void fnFreeFlashMemory(uint16_t unusedButMandatoryParameter) {
  longInteger_t flashMem;

  liftStack();

  longIntegerInit(flashMem);
  uIntToLongInteger(getFreeFlash(), flashMem);
  convertLongIntegerToLongIntegerRegister(flashMem, REGISTER_X);
  longIntegerFree(flashMem);
}



void fnBatteryVoltage(uint16_t unusedButMandatoryParameter) {
  real_t value;

  liftStack();

  #if defined(PC_BUILD)
    int32ToReal(3100, &value);
  #endif // PC_BUILD

  #if defined(DMCP_BUILD)
//    int32ToReal(get_vbat(), &value);
    int tmpVbat = get_vbat();
    int32ToReal(tmpVbat < vbatVIntegrated ? tmpVbat : vbatVIntegrated, &value);
  #endif // DMCP_BUILD

  temporaryInformation = TI_BATTV;
  realDivide(&value, const_1000, &value, &ctxtReal39);
  convertRealToResultRegister(&value, REGISTER_X, amNone);
}



uint32_t getFreeFlash(void) {
  return 0;
}



void fnGetSignificantDigits(uint16_t unusedButMandatoryParameter) {
  longInteger_t sigDigits;

  liftStack();

  longIntegerInit(sigDigits);
  uIntToLongInteger(significantDigits == 0 ? 34 : significantDigits, sigDigits);
  convertLongIntegerToLongIntegerRegister(sigDigits, REGISTER_X);
  longIntegerFree(sigDigits);
}



void fnSetSignificantDigits(uint16_t S) {
   significantDigits = S;
   if(significantDigits == 0) {
     significantDigits = 34;
   }
 }



void fnRoundingMode(uint16_t RM) {
  if(RM < sizeof(roundingModeTable) / sizeof(*roundingModeTable)) {
    roundingMode = RM;
    ctxtReal34.round = roundingModeTable[RM];
  }
  else {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgValueFor], "fnRoundingMode", RM, "RM");
    sprintf(errorMessage + strlen(errorMessage), "Must be from 0 to 6");
    displayBugScreen(errorMessage);
  }
}



void fnAngularMode(uint16_t am) {
  currentAngularMode = am;
  fnRefreshState();
}



void fnFractionType(uint16_t unusedButMandatoryParameter) {
  #define STATE_offbc    0b0000  // B
  #define STATE_bc       0b0001  //1
  #define STATE_offabc   0b0010  // B
  #define STATE_abc      0b0011  //3
//                         0100  B
//                         0101    C if b8==0 the b4=0
//                         0110  B
//                         0111    C if b8==0 the b4=0
//                         1000  A
//                         1001 
//                         1010  A
//                         1011
  #define STATE_exfr_bc  0b1100  //12
//                         1101
  #define STATE_exfr_abc 0b1110  //14
//                         1111
  #define STATE          ((constantFractions         ? 8:0) +  \
                         (constantFractionsOn        ? 4:0) +  \
                         (getSystemFlag(FLAG_PROPFR) ? 2:0) +  \
                         (getSystemFlag(FLAG_FRACT)  ? 1:0))
  uint8_t state = STATE;
  //printf("%u ",state);

  if(getSystemFlag(FLAG_FRCYC)) {
    if(!getSystemFlag(FLAG_FRACT) && constantFractions && !constantFractionsOn) { // 10x0 --> 11x0 A
      constantFractionsOn = true;
      return;
    } else {
      if(!constantFractions && !getSystemFlag(FLAG_FRACT)) {                      // 0xx0 --> 0xx1 B
        flipSystemFlag(FLAG_FRACT);
        return;
      }
    }
    switch(state) {
      case STATE_bc          : state = STATE_exfr_abc;  break;                    // 0b0001 --> 
      case STATE_abc         : state = STATE_bc;        break;                    // 0b0011 --> 
      case STATE_exfr_bc     : state = STATE_abc;       break;                    // 0b1100 --> 
      case STATE_exfr_abc    : state = STATE_exfr_bc;   break;                    // 0b1110 --> 
      default                : state = STATE_abc;       break;                    // 
    }
  } else { 
    switch(state) {
      case STATE_bc          : state = STATE_exfr_bc;   break;                    // 0b0001 --> 
      case STATE_abc         : state = STATE_exfr_abc;  break;                    // 0b0011 --> 
      case STATE_exfr_bc     : state = STATE_offbc;     break;                    // 0b1100 --> 
      case STATE_exfr_abc    : state = STATE_offabc;    break;                    // 0b1110 --> 
      case STATE_offbc       : state = STATE_bc;        break;                    // 0b0000 -->
      case STATE_offabc      : state = STATE_abc;       break;                    // 0b0010 -->
      default                : state = STATE_abc;       break;                    //
    }  
  }
  constantFractions   = (state & 8) ? true : false;
  constantFractionsOn = (state & 4) ? true : false;
  if (((state & 2) == 2) == !getSystemFlag(FLAG_PROPFR)) flipSystemFlag(FLAG_PROPFR);
  if (((state & 1) == 1) == !getSystemFlag(FLAG_FRACT)) flipSystemFlag(FLAG_FRACT);
  //printf("--> %u --> %u\n",state, STATE);
}


/* Confirmation messages */
TO_QSPI const confirmationTI_t confirmationTI[] = {
    {.item = ITM_DELALL,      .string = "Delete all?"                  },
    {.item = ITM_CLFALL,      .string = "Clear all flags?"             },
    {.item = ITM_DELPALL,     .string = "Delete all programs?"         },
    {.item = ITM_CLREGS,      .string = "Clear registers?"             },
    {.item = ITM_RESET,       .string = "Reset?"                       },
    {.item = ITM_SYSTEM,      .string = "Exit to system?"              },
    {.item = ITM_DELBKUP,     .string = "Delete backup file?"          },
    {.item = ITM_CLMALL,      .string = "Clear all user menus?"        },
    {.item = ITM_CLVALL,      .string = "Clear all user variables?"    },
    {.item = ITM_DELMALL,     .string = "Delete all user menus?"       },
    {.item = ITM_DELVALL,     .string = "Delete all user variables?"   },
    {.item = 0,               .string = "Are you sure?"                }          // Default TI for items requiring confirmation but not listed in this table
};

uint16_t getConfirmationTiId(void) {
  uint16_t id;
  uint16_t item = 0;
  for(id=0; id<LAST_ITEM; id++) {
    if(indexOfItems[id].func == confirmedFunction) {
      item = id;
      break;
    }
  }
  id = 0;
  while(confirmationTI[id].item != 0) {
    if(confirmationTI[id].item == item) {
      break;
    }
    id++;
  }
  return id;
}

void setConfirmationMode(void (*func)(uint16_t)) {
#if !defined(TESTSUITE_BUILD)
  previousCalcMode = calcMode;
  cursorEnabled = false;
  calcMode = CM_CONFIRMATION;
  clearSystemFlag(FLAG_ALPHA);
  confirmedFunction = func;
  temporaryInformation = TI_ARE_YOU_SURE;
  showSoftmenu(-MNU_YESNO);
#endif // !TESTSUITE_BUILD
}


void fnConfirmationYes(uint16_t unusedButMandatoryParameter) {
#if !defined(TESTSUITE_BUILD)
  if(calcMode == CM_CONFIRMATION) {
      calcMode = previousCalcMode;
      popSoftmenu();                // Pop MNU_YESNO
      confirmedFunction(CONFIRMED);
  }
#endif // !TESTSUITE_BUILD
}


 void fnConfirmationNo(uint16_t unusedButMandatoryParameter) {
#if !defined(TESTSUITE_BUILD)
  if(calcMode == CM_CONFIRMATION) {
      calcMode = previousCalcMode;
      popSoftmenu();                // Pop MNU_YESNO
  }
#endif // !TESTSUITE_BUILD
}


void fnRange(uint16_t R) {
  exponentLimit = R;
  if(exponentLimit < 99) exponentLimit = 99;
}



void fnGetRange(uint16_t unusedButMandatoryParameter) {
  longInteger_t range;

  liftStack();

  longIntegerInit(range);
  uIntToLongInteger(exponentLimit, range);
  convertLongIntegerToLongIntegerRegister(range, REGISTER_X);
  longIntegerFree(range);
}



void fnHide(uint16_t H) {
  exponentHideLimit = H;
  if(exponentHideLimit > 0 && exponentHideLimit < 12) {
    exponentHideLimit = 12;
  }
}



void fnGetHide(uint16_t unusedButMandatoryParameter) {
  longInteger_t range;

  liftStack();

  longIntegerInit(range);
  uIntToLongInteger(exponentHideLimit, range);
  convertLongIntegerToLongIntegerRegister(range, REGISTER_X);
  longIntegerFree(range);
}


void initSimEqMatABX(void) {
  void *memPtr;

  allocateNamedVariable("Mat_A", dtReal34Matrix, REAL34_SIZE_IN_BLOCKS + 1);
  memPtr = getRegisterDataPointer(FIRST_NAMED_VARIABLE);
  ((dataBlock_t *)memPtr)->matrixRows = 1;
  ((dataBlock_t *)memPtr)->matrixColumns = 1;
  real34Zero(memPtr + 4);

  allocateNamedVariable("Mat_B", dtReal34Matrix, REAL34_SIZE_IN_BLOCKS + 1);
  memPtr = getRegisterDataPointer(FIRST_NAMED_VARIABLE + 1);
  ((dataBlock_t *)memPtr)->matrixRows = 1;
  ((dataBlock_t *)memPtr)->matrixColumns = 1;
  real34Zero(memPtr + 4);

  allocateNamedVariable("Mat_X", dtReal34Matrix, REAL34_SIZE_IN_BLOCKS + 1);
  memPtr = getRegisterDataPointer(FIRST_NAMED_VARIABLE + 2);
  ((dataBlock_t *)memPtr)->matrixRows = 1;
  ((dataBlock_t *)memPtr)->matrixColumns = 1;
  real34Zero(memPtr + 4);
}


void fnClAll(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(fnClAll);
  }
  else {
    calcRegister_t regist;

    fnClPAll(CONFIRMED);  // Clears all the programs
    fnClSigma(CONFIRMED); // Clears and releases the memory of all statistical sums
    if(savedStatisticalSumsPointer != NULL) {
      freeC47Blocks(savedStatisticalSumsPointer, NUMBER_OF_STATISTICAL_SUMS * REAL_SIZE_IN_BLOCKS);
    }

    // Clear local registers
    allocateLocalRegisters(0);

    // Clear registers including stack, I, J, K, L, MNP QRS, EFHH OUVW, saved stack and temp
    for(regist=FIRST_GLOBAL_REGISTER; regist<=LAST_GLOBAL_REGISTER; regist++) {
      clearRegister(regist);
    }
    thereIsSomethingToUndo = false;

    // Clear user menus
    fnExitAllMenus(NOPARAM);
    fnDeleteUserMenus(CONFIRMED);             // Delete all user menus and user menus assignments

    if(MODEL == USER_R47) {
      fnRESET_MyM(USER_MR47);                  // Reset Menu MyMenu
    } else {
      fnRESET_MyM(USER_MC47);                  // Reset Menu MyMenu
    }

    fnRESET_Mya();                            // Reset Menu MyAlpha
    #if !defined(TESTSUITE_BUILD)
      createHOME();                             // Reset Menu HOME
      createPFN();                              // Reset Menu P.FN
    #endif // !TESTSUITE_BUILD

    // Clear All Key assignments
    fnKeysManagement(USER_KRESET);
    initUserKeyArgument();

    // Delete named variables
    fnDeleteAllVariables(CONFIRMED);

    // Clear global flags
    fnClFAll(CONFIRMED);

    temporaryInformation = TI_NO_INFO;
    if(programRunStop == PGM_WAITING) {
      programRunStop = PGM_STOPPED;
    }
  }
}



void addTestPrograms(void) {
  uint32_t numberOfBytesUsed, numberOfBytesForTheTestPrograms = TO_BYTES(TO_BLOCKS(16000));

  resizeProgramMemory(TO_BLOCKS(numberOfBytesForTheTestPrograms));
  firstDisplayedStep            = beginOfProgramMemory;
  currentStep                   = beginOfProgramMemory;
  currentLocalStepNumber        = 1;
  firstDisplayedLocalStepNumber = 0;

  #if defined(DMCP_BUILD)
    if(f_open(ppgm_fp, "testPgms.bin", FA_READ) != FR_OK) {
      *(beginOfProgramMemory)     = 255; // .END.
      *(beginOfProgramMemory + 1) = 255; // .END.
      firstFreeProgramByte = beginOfProgramMemory;
      freeProgramBytes = numberOfBytesForTheTestPrograms - 2;
    }
    else {
      UINT bytesRead;
      f_read(ppgm_fp, &numberOfBytesUsed,   sizeof(numberOfBytesUsed), &bytesRead);
      f_read(ppgm_fp, beginOfProgramMemory, numberOfBytesUsed,         &bytesRead);
      f_close(ppgm_fp);

      firstFreeProgramByte = beginOfProgramMemory + (numberOfBytesUsed - 2);
      freeProgramBytes = numberOfBytesForTheTestPrograms - numberOfBytesUsed;
    }

    scanLabelsAndPrograms();
  #else // !DMCP_BUILD
    FILE *testPgms;

    testPgms = fopen("res/dmcp/testPgms.bin", "rb");
    if(testPgms == NULL) {
      printf("Cannot open file res/dmcp/testPgms.bin\n");
      *(beginOfProgramMemory)     = 255; // .END.
      *(beginOfProgramMemory + 1) = 255; // .END.
      firstFreeProgramByte = beginOfProgramMemory;
      freeProgramBytes = numberOfBytesForTheTestPrograms - 2;
    }
    else {
      ignoreReturnedValue(fread(&numberOfBytesUsed, 1, sizeof(numberOfBytesUsed), testPgms));
      printf("%u bytes\n", numberOfBytesUsed);
      if(numberOfBytesUsed > numberOfBytesForTheTestPrograms) {
        printf("Increase allocated memory for programs! File config.c 1st line of function addTestPrograms\n");
        fclose(testPgms);
        exit(0);
      }
      ignoreReturnedValue(fread(beginOfProgramMemory, 1, numberOfBytesUsed, testPgms));
      fclose(testPgms);

      firstFreeProgramByte = beginOfProgramMemory + (numberOfBytesUsed - 2);
      freeProgramBytes = numberOfBytesForTheTestPrograms - numberOfBytesUsed;
    }

    printf("freeProgramBytes = %u\n", freeProgramBytes);

    scanLabelsAndPrograms();
    #if !defined(TESTSUITE_BUILD)
      leavePem();
    #endif // !TESTSUITE_BUILD
    printf("freeProgramBytes = %u\n", freeProgramBytes);
    //listPrograms();
    //listLabelsAndPrograms();
  #endif // DMCP_BUILD
}



void restoreStats(void){
  if(lrChosen !=65535) {
    lrChosen = lrChosenHistobackup;
  }
  if(lrSelection !=65535) {
    lrSelection = lrSelectionHistobackup;
  }
  strcpy(statMx,"STATS");
  lrSelectionHistobackup = 65535;
  lrChosenHistobackup = 65535;
  calcSigma(0);
}


    typedef struct {              //JM VALUES DEMO
      uint8_t  itemType;
      uint8_t  count;
      char     *itemName;
    } numberstr;

    TO_QSPI const numberstr indexOfStrings[] = {
      {0,10, "Reg 11,12 & 13 have: The 3 cubes = 3."},
      {1,11, "569936821221962380720"},
      {1,12, "-569936821113563493509"},
      {1,13, "-472715493453327032"},

      {0,14, "Reg 15, 16 & 17 have: The 3 cubes = 42."},
      {1,15, "-80538738812075974"},
      {1,16, "80435758145817515"},
      {1,17, "12602123297335631"},

      {0,18, "37 digits of pi, Reg19 / Reg20."},
      {1,19, "2646693125139304345"},
      {1,20, "842468587426513207"},

      {0,21, "Primes: Carol"},
      {1,22, "18014398241046527"},

      {0,23, "Primes: Kynea"},
      {1,24, "18446744082299486207"},

      {0,25, "Primes: repunit"},
      {1,26, "7369130657357778596659"},

      {0,27, "Primes: Woodal"},
      {1,28, "195845982777569926302400511"},

      {0,29, "Primes: Woodal"},
      {1,30, "4776913109852041418248056622882488319"},

      {0,31, "Primes: Woodal"},
      {1,32, "225251798594466661409915431774713195745814267044878909733007331390393510002687"},

      {0,33, "pi.(10^100) (101 digits) longinteger"},
      {1,34, "31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170680"},

      {0,35, "100 primes' product 2x3x...x541"},
      {1,36, "4711930799906184953162487834760260422020574773409675520188634839616415335845034221205289256705544681972439104097777157991804380284218315038719444943990492579030720635990538452312528339864352999310398481791730017201031090"},

    };





    TO_QSPI const numberstr indexOfMsgs[] = {
      {0,USER_C47,     "C47: Classic single shift (DM42)"  },
      {0,USER_R47,     "R47: 2 shifts R (43S mould) /x-+ R"          },
      {0,USER_R47bkfg, "R47bkfg: 1 shift R (43Ssp mould) /x-+ R"     },
      {0,USER_R47fgbk, "R47fgbk: 1 shift L (43Ssp mould) /x-+ R"     },
      {0,USER_R47fg_g, "R47fg_g: 2 shifts f/g g (43Ssp mould) /x-+ R"    },
      {0,USER_D47,     "D47: Exp 2 shifts R (43S mould) /x-+ R"          },
      {0,USER_E47,     "E47: Exp 2 shifts L /x-+ R"                      },
      {0,USER_N47,     "N47: Exp 2 shft L (32 mould) /x-+ R " STD_UP_ARROW STD_DOWN_ARROW " top"  },
      {0,USER_V47,     "V47: Exp Vintage 2 shifts TopR -+x/ L"           },
      {0,USER_DM42,    "DM42: Final Compatibility layout"                },
      {0,USER_HRESET,  "HOME Menu reset to default"                      },
      {0,USER_PRESET,  "P.FN Menu reset to default"                      },
      {0,USER_KRESET,  "USER keys cleaned"                               },
      {0,USER_MRESET,  "MyMenu menu cleaned"                             },
      {0,USER_ARESET,  "My" STD_alpha " menu cleaned"                    },
      {0,USER_MFIN,    "MyMenu primary F-key financial ribbon"           },
      {0,USER_MCPX,    "MyMenu primary F-key complex ribbon"             },
      {0,USER_MSAV,    "MyMenu primary F-key save/load ribbon"           },
      {0,USER_MC47,    "MyMenu primary C47 F-key ribbon"                 },
      {0,USER_MR47,    "MyMenu primary R47 F-key ribbon"                 },
      {0,100,"Error List"}
    };



uint16_t searchMsg(uint16_t idStr) {
  uint_fast16_t n = nbrOfElements(indexOfMsgs);
  uint_fast16_t i;
  for(i=0; i<n; i++) {
    if(indexOfMsgs[i].count == idStr) {
       break;
    }
  }
  return i;
}


void fnShowVersion(uint8_t option) {  //KEYS VERSION LOADED
  strcpy(errorMessage, indexOfMsgs[searchMsg(option)].itemName);
  temporaryInformation = TI_KEYS;
}


void fnResetTVM (uint16_t unusedButMandatoryParameter) {
  Sett(_TVM);
}



void defaultStatusBar(void) {
  Sett(_DefltSB);
  //---     setSystemFlag(FLAG_SBdate );  // FLAG_SBdate  0x802C
  //---   clearSystemFlag(FLAG_SBtime );  // FLAG_SBtime  0x802D
  //---   clearSystemFlag(FLAG_SBcr   );  // FLAG_SBcr    0x802E
  //---     setSystemFlag(FLAG_SBcpx  );  // FLAG_SBcpx   0x802F
  //---   clearSystemFlag(FLAG_SBang  );  // FLAG_SBang   0x8030
  //---     setSystemFlag(FLAG_SBfrac );  // FLAG_SBfrac  0x8031
  //---     setSystemFlag(FLAG_SBint  );  // FLAG_SBint   0x8032
  //---   clearSystemFlag(FLAG_SBmx   );  // FLAG_SBmx    0x8033
  //---     setSystemFlag(FLAG_SBtvm  );  // FLAG_SBtvm   0x8034
  //---     setSystemFlag(FLAG_SBoc   );  // FLAG_SBoc    0x8035
  //---   clearSystemFlag(FLAG_SBss   );  // FLAG_SBss    0x8036
  //---     setSystemFlag(FLAG_SBclk  );  // FLAG_SBclk   0x8037
  //---     setSystemFlag(FLAG_SBser  );  // FLAG_SBser   0x8038
  //---     setSystemFlag(FLAG_SBprn  );  // FLAG_SBprn   0x8039
  //---   clearSystemFlag(FLAG_SBbatV );  // FLAG_SBbatV  0x803A
  //---   clearSystemFlag(FLAG_SBshfR );  // FLAG_SBshfR  0x803B
}

void resetOtherConfigurationStuff(void) {
  cancelFilename = true;
  lastStateFileOpened[0]=0;

  firstGregorianDay = 2361222 /* 14 Sept 1752 */;
//---  denMax = 64;                                               //JM changed default from MAX_DENMAX default
  displayFormat = DF_ALL;
  displayFormatDigits = 3;
  timeDisplayFormatDigits = 0;

  shortIntegerMode = SIM_2COMPL;                              //64:2
  fnSetWordSize(64);

//---  grpGroupingLeft   = 3;
//---  grpGroupingGr1Left= 0;
//---  grpGroupingGr1Left= 0;
//---  grpGroupingRight  = 3;
//---  fnSetGapChar(0+    ITM_SPACE_PUNCTUATION);
//---  fnSetGapChar(32768+ITM_SPACE_PUNCTUATION);
//---  fnSetGapChar(49152+ITM_PERIOD);

//---  significantDigits = 0;
//---  currentAngularMode = amDegree;
  roundingMode = RM_HALF_EVEN;
//---  displayStack = cachedDisplayStack = 4;
  pcg32_srandom(0x1963073019931121ULL, 0x1995062319981019ULL); // RNG initialisation
//---  exponentLimit = 6145;
  exponentHideLimit = 0;
  lrSelection = CF_LINEAR_FITTING;
  lrSelectionUndo = lrSelection;                               //Not saved in file, but reset

//---  eRPN = true;
  HOME3 = true;
  MYM3 = false;
  ShiftTimoutMode = false;
//---  BASE_HOME   = false;
  Norm_Key_00_VAR  = Norm_Key_00_item_in_layout;               //JM NORM MODE SIGMA REPLACEMENT KEY
  Input_Default =  ID_43S;
  jm_G_DOUBLETAP = true;
//---  BASE_MYM = true;                                             //"MyM" setting, set as part of USER_MRESET
  jm_LARGELI = true;                                           //Large font for long integers on stack
//---  constantFractions = false;                                   //Extended fractions
//---  constantFractionsMode = CF_NORMAL;                           //Extended fractions
//---  constantFractionsOn = false;                                 //Extended fractions
  displayStackSHOIDISP = 2;            //See if the refresh is needed. fnShoiXRepeats(2); //displayStackSHOIDISP
  bcdDisplay = false;
  topHex = true;                                               //Hex keys enabled
  bcdDisplaySign = BCDu;
  DRG_Cycling = 0;
  DM_Cycling = 0;
  SI_All = false;                                              //UNIT display full SI prefix display range
  CPXMULT = false;                                             //defaults to the new complex notation with space
  LongPressM = RB_M1234;
  LongPressF = RB_F124;
  fgLN = RB_FGLNFUL;
  lastIntegerBase = 0;
  timeLastOp = 0;
  timeLastOp0 = 0;
  timeLastOp1 = 0;
}



typedef struct {
  char str2[180];
} nstr2;
TO_QSPI const nstr2 msg2[] = { 
      { "\xff\xf8\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\xff\xf8" }
   };


void fnReset(uint16_t confirmation) {
  doFnReset(confirmation, doNotLoadAutoSav);
}

void doFnReset(uint16_t confirmation, bool_t autoSav) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(fnReset);
  }
  else {
    void *memPtr;

    if(ram == NULL) {
      ram = (dataBlock_t *)malloc(TO_BYTES(RAM_SIZE_IN_BLOCKS));
    }
    memset(ram, 0, TO_BYTES(RAM_SIZE_IN_BLOCKS));
    numberOfFreeMemoryRegions = 1;

    // for reserved variables (for Martin: you moron, think twice when you change something around here!)
    freeMemoryRegions[0].blockAddress = allReservedVariables[LAST_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE].header.pointerToRegisterData + REAL34_SIZE_IN_BLOCKS; // + REAL34_SIZE_IN_BLOCKS is wrong because GRAMOD is a dtLongInteger, but it works
    freeMemoryRegions[0].sizeInBlocks = RAM_SIZE_IN_BLOCKS - freeMemoryRegions[0].blockAddress - 1; // - 1: one block for an empty program

    #if !defined(DMCP_BUILD)
      numberOfAllocatedMemoryRegions = 0;
    #endif // !DMCP_BUILD

    if(tmpString == NULL) {
      #if defined(DMCP_BUILD)
         tmpString        = aux_buf_ptr();   // 2560 byte buffer provided by DMCP
         errorMessage     = write_buf_ptr(); // 4096 byte buffer provided by DMCP
       #else // !DMCP_BUILD
         tmpString        = (char *)malloc(TMP_STR_LENGTH);
         errorMessage     = (char *)malloc(WRITE_BUFFER_LEN);
       #endif // DMCP_BUILD

       aimBuffer        = errorMessage + ERROR_MESSAGE_LENGTH;    // + 512
       nimBufferDisplay = aimBuffer + AIM_BUFFER_LENGTH;          // + 400
       tamBuffer        = nimBufferDisplay + NIM_BUFFER_LENGTH;   // + 200 + 32

       tmpStringLabelOrVariableName = tmpString + 1000;
    }
    memset(tmpString,        0, TMP_STR_LENGTH);
    memset(errorMessage,     0, ERROR_MESSAGE_LENGTH);
    memset(aimBuffer,        0, AIM_BUFFER_LENGTH);
    memset(nimBufferDisplay, 0, NIM_BUFFER_LENGTH);
    memset(tamBuffer,        0, TAM_BUFFER_LENGTH);

    // Empty program initialization
    beginOfProgramMemory          = (uint8_t *)(ram + (RAM_SIZE_IN_BLOCKS - 1)); // Last block of RAM
    currentStep                   = beginOfProgramMemory;
    firstFreeProgramByte          = beginOfProgramMemory + 2;
    firstDisplayedStep            = beginOfProgramMemory;
    firstDisplayedLocalStepNumber = 0;
    labelList                     = NULL;
    programList                   = NULL;
    *(beginOfProgramMemory + 0) = (ITM_END >> 8) | 0x80;
    *(beginOfProgramMemory + 1) =  ITM_END       & 0xff;
    *(beginOfProgramMemory + 2) = 255; // .END.
    *(beginOfProgramMemory + 3) = 255; // .END.
    freeProgramBytes            = 0;

    scanLabelsAndPrograms();

    // "Not found glyph" initialization
    if(glyphNotFound.data == NULL) {
      glyphNotFound.data = malloc(38);
    }
    //xcopy(glyphNotFound.data, "\xff\xf8\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\x80\x08\xff\xf8", 38);
    xcopy(glyphNotFound.data, msg2[0].str2, 38);


    // Initialization of user key assignments
    xcopy(kbd_usr, kbd_std, sizeof(kbd_std));
    //kbd_usr[ 0].keyLblAim   = CHR_A_GRAVE;
    //kbd_usr[ 0].fShiftedAim = CHR_A_GRAVE;
    //kbd_usr[ 4].keyLblAim   = CHR_E_ACUTE;
    //kbd_usr[ 4].fShiftedAim = CHR_E_ACUTE;
    //kbd_usr[18].fShifted    = -MNU_VARS;
    //kbd_usr[18].gShifted    = CST_54;
    //kbd_usr[19].fShifted    = ITM_SW;
    //kbd_usr[19].gShifted    = ITM_SXY;
    //kbd_usr[20].gShifted    = ITM_LYtoM;

    // initialize 9 real34 reserved variables: ACC, ↑Lim, ↓Lim, FV, i%/a, NPPER, PPER/a, PMT, and PV
    for(int i=0; i<9; i++) {
      real34Zero(allocC47Blocks(REAL34_SIZE_IN_BLOCKS));
    }

    // initialize 1 long integer reserved variables: GRAMOD
    #if defined(OS64BIT)
      memPtr = allocC47Blocks(3);
      ((dataBlock_t *)memPtr)->dataMaxLength = 2;
    #else // !OS64BIT
      memPtr = allocC47Blocks(2);
      ((dataBlock_t *)memPtr)->dataMaxLength = 1;
    #endif // OS64BIT

    // initialize the global registers
    memset(globalRegister, 0, sizeof(globalRegister));
    for(calcRegister_t regist=FIRST_GLOBAL_REGISTER; regist<=LAST_GLOBAL_REGISTER; regist++) {
      setRegisterDataType(regist, dtReal34, amNone);
      memPtr = allocC47Blocks(REAL34_SIZE_IN_BLOCKS);
      setRegisterDataPointer(regist, memPtr);
      real34Zero(memPtr);
    }

    // Clear global flags
    memset(globalFlags, 0, sizeof(globalFlags));

    // allocate space for the local register list
    allSubroutineLevels.numberOfSubroutineLevels = 1;
    currentSubroutineLevelData = allocC47Blocks(3);
    allSubroutineLevels.ptrToSubroutineLevel0Data = TO_C47MEMPTR(currentSubroutineLevelData);
    currentReturnProgramNumber = 0;
    currentReturnLocalStep = 0;
    currentNumberOfLocalRegisters = 0; // No local register
    currentNumberOfLocalFlags = 0; // No local flags
    currentSubroutineLevel = 0;
    currentPtrToNextLevel = C47_NULL;
    currentPtrToPreviousLevel = C47_NULL;
    currentLocalFlags = NULL;
    currentLocalRegisters = NULL;

    // allocate space for the named variable list
    numberOfNamedVariables = 0;
    allNamedVariables = NULL;

    initSimEqMatABX();

    #if !defined(TESTSUITE_BUILD)
      matrixIndex = INVALID_VARIABLE; // Unset matrix index
    #endif // !TESTSUITE_BUILD


    #if defined(PC_BUILD)
      debugWindow = DBG_REGISTERS;
    #endif // PC_BUILD

    decContextDefault(&ctxtReal34, DEC_INIT_DECQUAD);

    decContextDefault(&ctxtReal4, DEC_INIT_DECSINGLE);
    ctxtReal4.digits = 6;
    ctxtReal4.traps  = 0;

    decContextDefault(&ctxtReal39, DEC_INIT_DECQUAD);
    ctxtReal39.digits = 39;
    ctxtReal39.emax   = 999999;
    ctxtReal39.emin   = -999999;
    ctxtReal39.traps  = 0;

    decContextDefault(&ctxtReal51, DEC_INIT_DECQUAD);
    ctxtReal51.digits = 51;
    ctxtReal51.emax   = 999999;
    ctxtReal51.emin   = -999999;
    ctxtReal51.traps  = 0;

    decContextDefault(&ctxtReal75, DEC_INIT_DECQUAD);
    ctxtReal75.digits = 75;
    ctxtReal75.emax   = 999999;
    ctxtReal75.emin   = -999999;
    ctxtReal75.traps  = 0;

    decContextDefault(&ctxtReal1071,  DEC_INIT_DECQUAD);
    ctxtReal1071.digits = 1071;
    ctxtReal1071.emax   = 999999;
    ctxtReal1071.emin   = -999999;
    ctxtReal1071.traps  = 0;

    decContextDefault(&ctxtReal2139,  DEC_INIT_DECQUAD);
    ctxtReal2139.digits = 2139;
    ctxtReal2139.emax   = 999999;
    ctxtReal2139.emin   = -999999;
    ctxtReal2139.traps  = 0;

    resetOtherConfigurationStuff();

    statisticalSumsPointer = NULL;
    savedStatisticalSumsPointer = NULL;
    statisticalSumsUpdate = true;
    lrChosen    = 0;
    lrChosenUndo = 0;
    lastPlotMode = PLOT_NOTHING;
    plotSelection = 0;
    drawHistogram = 0;
    realZero(&SAVED_SIGMA_LASTX);
    realZero(&SAVED_SIGMA_LASTY);
    SAVED_SIGMA_LAc1 = 0;

    plotStatMx[0] = 0;
    regStatsXY = INVALID_VARIABLE;
    real34Zero(&loBinR);
    real34Zero(&nBins );
    real34Zero(&hiBinR);
    histElementXorY = -1;


    x_min = -10;
    x_max = 10;
    y_min = 0;
    y_max = 1;



    systemFlags0 = 0;
    systemFlags1 = 0;

Sett(_Reset);
    //Statusbar default setup   DATE noTIME noCR noANGLE [ADM] FRAC INT MATX TVM CARRY noSS WATCH SERIAL PRN BATVOLT noSHIFTR
//---    defaultStatusBar();

    configCommon(CFG_DFLT);

//---    clearSystemFlag(FLAG_FRACT );                                //Not saved in file, but restored here:  fnDisplayFormatAll(3);
//---    setSystemFlag  (FLAG_DENANY); //overridden later
//---    setSystemFlag  (FLAG_MULTx );
//---    setSystemFlag  (FLAG_AUTOFF);
//---    setSystemFlag  (FLAG_ASLIFT); //overridden later
//---    setSystemFlag  (FLAG_PROPFR);
//---    setSystemFlag  (FLAG_ENDPMT);// TVM application = END mode
//---    setSystemFlag  (FLAG_HPRP  );
//---    setSystemFlag  (FLAG_HPBASE);
//---    clearSystemFlag(FLAG_2TO10 );
//---    clearSystemFlag(FLAG_FRCYC );
//---    setSystemFlag(FLAG_MONIT   );
//---    setSystemFlag(FLAG_SH_LONGPRESS);


    hourGlassIconEnabled = false;
    watchIconEnabled = false;
    serialIOIconEnabled = false;
    printerIconEnabled = false;
    thereIsSomethingToUndo = false;
    pemCursorIsZerothStep = true;
    tam.alpha = false;
    fnKeyInCatalog = false;
    shiftF = false;
    shiftG = false;
    halfSecTick = false;


    ctxtReal34.round = DEC_ROUND_HALF_EVEN;

    initFontBrowser();
    currentAsnScr = 1;
    currentFlgScr = 0;
    lastFlgScr = 0;
    currentRegisterBrowserScreen = 9999;

    memset(softmenuStack, 0, sizeof(softmenuStack)); // This works because the ID of MyMenu is 0

    aimBuffer[0] = 0;
    lastErrorCode = 0;

    #if !defined(TESTSUITE_BUILD)
      resetAlphaSelectionBuffer();
    #endif // !TESTSUITE_BUILD

    #if defined(TESTSUITE_BUILD)
      calcMode = CM_NORMAL;
    #else // TESTSUITE_BUILD
      if(calcMode == CM_MIM) {
        mimFinalize();
      }
      calcModeNormal();
    #endif // !TESTSUITE_BUILD

    #if defined(PC_BUILD) || defined(TESTSUITE_BUILD)
      debugMemAllocation = true;
    #endif // PC_BUILD || TESTSUITE_BUILD


    tam.mode = 0;
    catalog = CATALOG_NONE;
    memset(lastCatalogPosition, 0, NUMBER_OF_CATALOGS * sizeof(lastCatalogPosition[0]));
    lastDenominator = 4;
    temporaryInformation = TI_RESET;

    currentInputVariable = INVALID_VARIABLE;
    currentMvarLabel = INVALID_VARIABLE;
    lastKeyCode = 0;
    entryStatus = 0;

    memset(userMenuItems,  0, sizeof(userMenuItem_t) * 18);
    memset(userAlphaItems, 0, sizeof(userMenuItem_t) * 18);
    userMenus = NULL;
    numberOfUserMenus = 0;
    currentUserMenu = 0;

    initUserKeyArgument();

    fnClearMenu(NOPARAM);
//---    clearSystemFlag(FLAG_DENANY);                              //JM Default
//---    clearSystemFlag(FLAG_ASLIFT);  //JM??
//---    setSystemFlag(FLAG_SSIZE8);                                //JM Default
//---    setSystemFlag(FLAG_CPXRES);                                //JM Default
//---    clearSystemFlag(FLAG_FRCSRN);  //JM??                      //JM Default

    #if !defined(TESTSUITE_BUILD)
      calcModeNormal();
      if(BASE_HOME) showSoftmenu(-MNU_HOME); //JM Reset to BASE MENU HOME;
    #endif // !TESTSUITE_BUILD

    showRegis = 9999;                                          //JMSHOW

    //JM defaults vv: CONFIG STO/RCL

    graph_xmin = -3*3.14159265;                                //JM GRAPH
    graph_xmax = -graph_xmin;                                  //JM GRAPH
    graph_ymin = -2;                                           //JM GRAPH
    graph_ymax = +2;                                           //JM GRAPH

    graph_reset();

    running_program_jm=false;                                  //JM program is running flag

//---    setSystemFlag(FLAG_SPCRES);                                //JM default infinity etc.
//---    clearSystemFlag(FLAG_DENFIX);                              //JM default

    ListXYposition = 0;

     //JM defaults ^^

                                                               //Find fnXEQMENU in the indexOfItems array
    fnXEQMENUpos = 0;
    while(indexOfItems[fnXEQMENUpos].func != fnXEQMENU) {
       fnXEQMENUpos++;
    }

                                                               //Reset XEQM
    uint16_t ix;
    ix = 0;
    while(ix<18) {
      indexOfItemsXEQM[+8*ix]=0;
      strcpy(indexOfItemsXEQM +8*ix, indexOfItems[fnXEQMENUpos+ix].itemSoftmenuName);
      ix++;
    }

    fnClrMod(0);
    XEQMENU_loadAllfromdisk();

    displayAIMbufferoffset = 0;
    T_cursorPos = 0;

//********** JM CHECKQQ
    //JM Default USER
    #if defined(PC_BUILD)
      printf("Doing A.RESET, M.RESET & K.RESET\n");
    #endif
    //    calcMode = CM_BUG_ON_SCREEN; this also removes the false start on MyMenu error

    fnKeysManagement(USER_PRESET);                                      //JM USER
    fnKeysManagement(USER_HRESET);                                      //JM USER
    fnKeysManagement(USER_ARESET);                                      //JM USER
    fnKeysManagement(USER_MRESET);                                      //JM USER

    if(MODEL == USER_R47) {
      fnKeysManagement(USER_MR47);                  // Reset Menu MyMenu Ribbon
    } else {
      fnKeysManagement(USER_MC47);                  // Reset Menu MyMenu Ribbon
    }

    #if !defined(TESTSUITE_BUILD)
      showSoftmenu(-MNU_MyMenu);                                   //this removes the false start on MyMenu error
    #endif // !TESTSUITE_BUILD
    fnKeysManagement(USER_KRESET);                                      //JM USER
    temporaryInformation = TI_NO_INFO;
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(163);

    //kbd_usr[0].primary     = ITM_CC;                         //JM CPX TEMP DEFAULT        //JM note. over-writing the content of setupdefaults
    //kbd_usr[0].gShifted    = KEY_TYPCON_UP;                  //JM TEMP DEFAULT            //JM note. over-writing the content of setupdefaults
    //kbd_usr[0].fShifted    = KEY_TYPCON_DN;                  //JM TEMP DEFAULT            //JM note. over-writing the content of setupdefaults

    // The following lines are test data
    #if !defined(SAVE_SPACE_DM42_14)
      addTestPrograms();
    #endif // !SAVE_SPACE_DM42_14
    //fnSetFlag(  3);
    //fnSetFlag( 11);
    //fnSetFlag( 33);
    //fnSetFlag( 34);
    //fnSetFlag( 52);
    //fnSetFlag( 62);
    //fnSetFlag( 77);
    //fnSetFlag( 85);
    //setSystemFlag(FLAG_CARRY);
    //setSystemFlag(FLAG_SPCRES);

    //allocateLocalRegisters(3);
    //fnSetFlag(FIRST_LOCAL_REGISTER+0);
    //fnSetFlag(NUMBER_OF_GLOBAL_FLAGS+2);
    //reallocateRegister(FIRST_LOCAL_REGISTER+0, dtReal34, REAL34_SIZE_IN_BLOCKS, RT_REAL);
    //stringToReal34("5.555", REGISTER_REAL34_DATA(FIRST_LOCAL_REGISTER));

    //strcpy(tmpString, "Pure ASCII string requiring 38 bytes!");
    //reallocateRegister(FIRST_LOCAL_REGISTER+1, dtString, TO_BLOCKS(strlen(tmpString) + 1), amNone);
    //strcpy(REGISTER_STRING_DATA(FIRST_LOCAL_REGISTER + 1), tmpString);

    //allocateNamedVariable("Z" STD_a_DIARESIS "hler");
    //allocateNamedVariable(STD_omega STD_SUB_1);
    //allocateNamedVariable(STD_omega STD_SUB_2);

    // Equation formulae
    allFormulae = NULL;
    numberOfFormulae = 0;
    currentFormula = 0;

    currentSolverStatus = 0;
    currentSolverProgram = 0xffffu;
    currentSolverVariable = INVALID_VARIABLE;
    currentSolverNestingDepth = 0;

    graphVariabl1 = 0;

    // Timer application
    timerCraAndDeciseconds = 0x80u;
    timerValue             = 0u;
    timerStartTime         = TIMER_APP_STOPPED;
    timerTotalTime         = 0u;

    #if(DEBUG_PANEL == 1)
      debugWindow = DBG_REGISTERS;
      gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(chkHexaString), false);
      refreshDebugPanel();
    #endif // (DEBUG_PANEL == 1)

    #if defined(DMCP_BUILD)
      //Check and update current power status (USB / LOWBAT)
      checkBattery();
    #endif // DMCP_BUILD

    //JM TEMPORARY TEST DATA IN REGISTERS
    uint_fast16_t n = nbrOfElements(indexOfStrings);
    for(uint_fast16_t i=0; i<n; i++) {
      if( indexOfStrings[i].itemType== 0) {
        fnStrtoX(indexOfStrings[i].itemName);
      } else
      if( indexOfStrings[i].itemType== 1) {
        fnStrInputLongint(indexOfStrings[i].itemName);
      }
      fnStore(indexOfStrings[i].count);
      fnDrop(0);
    }


    #if !defined(TESTSUITE_BUILD)
      runFunction(ITM_VERS);
    #endif // !TESTSUITE_BUILD


    //Autoloading of C47Auto.sav
    #if defined(DMCP_BUILD)
      if(autoSav == loadAutoSav) {
        fnLoadAuto();
      }
    #endif // DMCP_BUILD

    #if !defined(TESTSUITE_BUILD)
      showSoftmenuCurrentPart();
    #endif // !TESTSUITE_BUILD
    doRefreshSoftMenu = true;     //jm dr
    screenUpdatingMode = SCRUPD_AUTO;
    refreshScreen(164);

    fnClearFlag(FLAG_USER);
    fnRefreshState();
  }
}



#ifdef DMCP_BUILD

  void dmcpResetAutoOff(void) {
    // Key is ready -> clear auto off timer
    if(!key_empty() || !getSystemFlag(FLAG_AUTOFF) || getSystemFlag(FLAG_RUNTIM) || programRunStop == PGM_RUNNING || (nextTimerRefresh != 0)) {
      reset_auto_off();
    }
  }


  int16_t loop=0;
  int16_t loop2=0;
  int updateVbatIntegrated(bool_t minutePulse) {
    if(getSystemFlag(FLAG_USB)) {
        return 3100;
    }
    int tmpVbat = get_vbat();
    if(tmpVbat > 1500 && tmpVbat < 3100) {
      if(tmpVbat < vbatVIntegrated) {
        vbatVIntegrated = tmpVbat;                                                        //immediately assume the lowest possibe value measured
        loop = 0;
      } else
      if(tmpVbat > vbatVIntegrated) {
        #ifndef MONITOR_VOLTAGE_INTEGRATOR
          //During monitoring do not force a reset to normal and high voltage
          if(tmpVbat > 2900) {                                                           //if high enough, reset
            vbatVIntegrated = tmpVbat;
          loop = 0;
          } else
        #endif
        if(vbatVIntegrated < tmpVbat && minutePulse) {                                    // Every min if vbatTIntegrated is lower than actual V, then creep closer
          vbatVIntegrated = vbatVIntegrated + max(1,((tmpVbat - vbatVIntegrated) >> 4));  //   (2500 - 2350) >> 4 = 9 increase every minute
        }
      }
    } else {
      vbatVIntegrated = tmpVbat;
      loop = 0;
    }

    #ifdef MONITOR_VOLTAGE_INTEGRATOR
      //Monitoring for voltage integrator
      if(minutePulse) {
        char aaa[120];
        sprintf(aaa,"         V=%i VI=%i loop=%i cnt=%i   ",tmpVbat, vbatVIntegrated, loop++, loop2++);
        print_numberstr(aaa,true);
        convertDoubleToReal34RegisterPush((double)vbatVIntegrated, REGISTER_X);
        uint8_t min = rtc_read_min();
        convertDoubleToReal34RegisterPush((double)min, REGISTER_X);
        fnSigma(1);
        fnDrop(0);
        fnDrop(0);
      }
    #endif

    return tmpVbat; //returning the direct battery voltage; to enable the selective usage of the integrator
  }


  void checkBattery(void) {
    if(usb_powered() == 1) {
      if(!getSystemFlag(FLAG_USB)) {
        setSystemFlag(FLAG_USB);
        clearSystemFlag(FLAG_LOWBAT);
        showHideUsbLowBattery();
      }
    }
    else {
      if(getSystemFlag(FLAG_USB)) {
        clearSystemFlag(FLAG_USB);
        showHideUsbLowBattery();
      }

      int tmpVbat = updateVbatIntegrated(false);

      if(tmpVbat < 2100 || vbatVIntegrated < 2100) { //shutdown from the new integrator system. The indicator uses the integrator.
        if(!getSystemFlag(FLAG_LOWBAT)) {
          setSystemFlag(FLAG_LOWBAT);
          showHideUsbLowBattery();
        }
        SET_ST(STAT_PGM_END);
      }
      else if(tmpVbat < 2500 || vbatVIntegrated < 2500) {
        if(!getSystemFlag(FLAG_LOWBAT)) {
          setSystemFlag(FLAG_LOWBAT);
          showHideUsbLowBattery();
        }
      }
      else {
        if(getSystemFlag(FLAG_LOWBAT)) {
          clearSystemFlag(FLAG_LOWBAT);
          showHideUsbLowBattery();
        }
      }
    }
  }
#endif //DMCP_BUILD

void backToSystem(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(backToSystem);
  }
  else {
    cancelFilename = true;
    #if defined(PC_BUILD)
      fnOff(NOPARAM);
    #endif // PC_BUILD

    #if defined(DMCP_BUILD)
      backToDMCP = true;
    #endif // DMCP_BUILD
  }
}

void runDMCPmenu(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(runDMCPmenu);
  }
  else {
    cancelFilename = true;
    #if defined(PC_BUILD)  //for consistency with backToSystem
      fnOff(NOPARAM);
    #endif // PC_BUILD

    #if defined(DMCP_BUILD)
      run_menu_item_sys(MI_DMCP_MENU);
    #endif // DMCP_BUILD
  }
}

void activateUSBdisk(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(activateUSBdisk);
  }
  else {
    cancelFilename = true;
    #if defined(DMCP_BUILD)
      run_menu_item_sys(MI_MSC);
    #endif // DMCP_BUILD
  }
}



/********************************************//**
 * \brief Sets/resets KEYS MANAGEMENT
 *
 * \param[in] jmConfig uint16_t
 * \return void
 ***********************************************/
void fnKeysManagement(uint16_t choice) {
  switch(choice) {
    //---KEYS SIGMA+ ALLOCATIONS: COPY SIGMA+ USER MODE primary to -> ALLMODE
    //-----------------------------------------------------------------------
    case USER_COPY:
      if(Norm_Key_00_VAR != ITM_SHIFTf && Norm_Key_00_VAR != ITM_SHIFTg && Norm_Key_00_VAR != KEY_fg) {
        kbd_usr[Norm_Key_00_key].primary = Norm_Key_00_VAR;
        fnRefreshState();
        fnSetFlag(FLAG_USER);
      }
      break;

      case USER_R47:
      case USER_R47bkfg:
      case USER_R47fgbk:
      case USER_R47fg_g:
      case USER_C47:
      case USER_DM42:
        calcModel = choice;
        fnClearFlag(FLAG_USER);
        fnKeysManagement(USER_KRESET);                   // Reset all user keys when a permanent layout is changed
        Norm_Key_00_VAR = Norm_Key_00_item_in_layout;    // Rest +NRM when a permanent layout is changed
        fnShowVersion(choice);
      break;

    #if defined(PC_BUILD)
      case USER_E47:
        fnKeysManagement(USER_KRESET);
        fnShowVersion(USER_E47);
        xcopy(kbd_usr, kbd_std_E47, sizeof(kbd_std_E47));
        fnSetFlag(FLAG_USER);
      break;

      case USER_V47:
        fnKeysManagement(USER_KRESET);
        fnShowVersion(USER_V47);
        xcopy(kbd_usr, kbd_std_V47, sizeof(kbd_std_V47));
        fnSetFlag(FLAG_USER);
      break;

      case USER_N47:
        fnKeysManagement(USER_KRESET);
        fnShowVersion(USER_N47);
        xcopy(kbd_usr, kbd_std_N47, sizeof(kbd_std_N47));
        fnSetFlag(FLAG_USER);
        break;

      case USER_D47:
        fnKeysManagement(USER_KRESET);
        fnShowVersion(USER_D47);
        xcopy(kbd_usr, kbd_std_D47, sizeof(kbd_std_D47));
        fnSetFlag(FLAG_USER);
      break;
    #endif //PC_BUILD

    case USER_KRESET:
      fnShowVersion(choice);
      xcopy(kbd_usr, kbd_std, sizeof(kbd_std_C47));         //sizeof does not work when using the define for kbd_std
      Norm_Key_00_VAR = Norm_Key_00_item_in_layout;
      fnRefreshState();
      fnClearFlag(FLAG_USER);
      break;

    case USER_HRESET:
      #if !defined(TESTSUITE_BUILD)
        createHOME();
        showSoftmenu(-MNU_HOME);
        fnShowVersion(choice);
      #endif // !TESTSUITE_BUILD
      break;

    case USER_PRESET:
      #if !defined(TESTSUITE_BUILD)
        createPFN();
        showSoftmenu(-MNU_PFN);
        fnShowVersion(choice);
      #endif // !TESTSUITE_BUILD
      break;

    case USER_MRESET:
      fnRESET_MyM(0);
      fnShowVersion(choice);
      break;

    case USER_ARESET:
      fnRESET_Mya();
      fnShowVersion(choice);
      break;

    case USER_MFIN:
    case USER_MCPX:
    case USER_MSAV:
    case USER_MC47:
    case USER_MR47:
      fnRESET_MyM(choice);
      fnShowVersion(choice);
      #if !defined(TESTSUITE_BUILD)
        showSoftmenu(-MNU_MyMenu);
      #endif // !TESTSUITE_BUILD
      break;


    default:
      break;
  }
}
