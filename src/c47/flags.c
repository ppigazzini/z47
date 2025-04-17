// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file flags.c
 ***********************************************/

#include "c47.h"

typedef enum { FLAG_CLEAR=0, FLAG_SET=1, FLAG_FLIP=2 } flagAction_t;

uint64_t systemFlags0Changed = 0xFFFFFFFFFFFFFFFF;
uint64_t systemFlags1Changed = 0xFFFFFFFFFFFFFFFF;
uint64_t systemFlags2Changed = 0xFFFFFFFFFFFFFFFF;


static void _setSystemFlag(unsigned int sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0Changed |= (~systemFlags0 & ((uint64_t)1 << flag));
    systemFlags0 |= ((uint64_t)1 << flag);
  }
  else {
    systemFlags1Changed |= (~systemFlags1 & ((uint64_t)1 << (flag - 64)));
    systemFlags1 |= ((uint64_t)1 << (flag - 64));
  }
}

static void _clearSystemFlag(unsigned int sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0Changed |= (systemFlags0 & ((uint64_t)1 << flag));
    systemFlags0 &= ~((uint64_t)1 << flag);
  }
  else {
    systemFlags1Changed |= (systemFlags1 & ((uint64_t)1 << (flag - 64)));
    systemFlags1 &= ~((uint64_t)1 << (flag - 64));
  }
}

static void _flipSystemFlag(unsigned int sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0Changed |= ((uint64_t)1 << flag);
    systemFlags0 ^=  ((uint64_t)1 << flag);
  }
  else {
    systemFlags1Changed |= ((uint64_t)1 << (flag - 64));
    systemFlags1 ^=  ((uint64_t)1 << (flag - 64));
  }
}

bool_t getSystemFlag(int32_t sf);

static void systemFlagAction(uint16_t systemFlag, flagAction_t action) {
  switch(systemFlag) {
    case FLAG_YMD:       //these flags need to update the corresponding softkey status
    case FLAG_DMY:
    case FLAG_MDY:
    case FLAG_TDM24:
    case FLAG_CPXRES:
    case FLAG_SPCRES:
    case FLAG_CPXj:
    case FLAG_POLAR:
    case FLAG_LEAD0:
    case FLAG_DENANY:
    case FLAG_DENFIX:
    case FLAG_SSIZE8:
    case FLAG_MULTx:
    case FLAG_ENGOVR:
    case FLAG_ENDPMT:
    case FLAG_HPRP:
    case FLAG_MNUp1:
    case FLAG_HPBASE:
    case FLAG_NUMLOCK:
    case FLAG_CPXMULT:
    case FLAG_ERPN:
    case FLAG_FRCYC:
    case FLAG_LARGELI:
    case FLAG_alphaCAP:
    case FLAG_2TO10:
    case FLAG_CPXPLOT:
    case FLAG_SHOWX   :
    case FLAG_SHOWY   :
    case FLAG_PBOX   :
    case FLAG_PCROS  :
    case FLAG_PPLUS  :
    case FLAG_PLINE  :
    case FLAG_SCALE  :
    case FLAG_VECT   :
    case FLAG_NVECT  :
              fnRefreshState();
              break;

    case FLAG_SBdate:       //these flags need to clear the statusbar and start SB again
    case FLAG_SBcr  :
    case FLAG_SBcpx :
    case FLAG_SBang :
    case FLAG_SBint :
    case FLAG_SBmx  :
    case FLAG_SBtvm :
    case FLAG_SBoc  :
    case FLAG_SBss  :
    case FLAG_SBstpw:
    case FLAG_SBser :
    case FLAG_SBprn :
    case FLAG_SBbatV:
    case FLAG_SBshfR:
    case FLAG_SBfrac:
    case FLAG_SBwoy :
    case FLAG_SBtime:
    case FLAG_FRACT:
    case FLAG_IRFRAC:
    case FLAG_IRFRQ:
            #if !defined(TESTSUITE_BUILD)
              reallyClearStatusBar(201);
              fnRefreshState();
              screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
              break;
            #endif

    default: break;
  }


  switch(systemFlag) {
    case FLAG_SBfrac:
              lastIntegerBase = 0; //needed to reset the annunciator
              break;

    case FLAG_SBwoy :
    case FLAG_SBtime:
              if(systemFlag == FLAG_SBtime && getSystemFlag(FLAG_SBtime)) {
                _clearSystemFlag(FLAG_SBwoy);
              }
              else if(systemFlag == FLAG_SBwoy && getSystemFlag(FLAG_SBwoy)) {
                _clearSystemFlag(FLAG_SBtime);
              }
              break; 
          
    case FLAG_FRACT:
              if(getSystemFlag(FLAG_FRACT)) {
                _clearSystemFlag(FLAG_IRFRAC);
                _clearSystemFlag(FLAG_IRFRQ);
              }
              break;

    case FLAG_IRFRAC:
              if(getSystemFlag(FLAG_IRFRAC)) {
                _clearSystemFlag(FLAG_FRACT);
                _setSystemFlag(FLAG_IRFRQ);
              }
              break;

     case FLAG_IRFRQ:
              if(getSystemFlag(FLAG_FRACT)) {
                _clearSystemFlag(FLAG_FRACT);
                _setSystemFlag(FLAG_IRFRAC);
              }
              break;

    default: break;
  }
}

void setSystemFlag(unsigned int sf) {
  _setSystemFlag(sf);
  systemFlagAction(sf, FLAG_SET);
}

void clearSystemFlag(unsigned int sf) {
  _clearSystemFlag(sf);
  systemFlagAction(sf, FLAG_CLEAR);
}

void flipSystemFlag(unsigned int sf) {
  _flipSystemFlag(sf);
  systemFlagAction(sf, FLAG_FLIP);
}

bool_t getSystemFlag(int32_t sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    return (systemFlags0 & ((uint64_t)1 << flag)) != 0;
  }
  else {
    return (systemFlags1 & ((uint64_t)1 << (flag - 64))) != 0;
  }
}

bool_t didSystemFlagChange(int32_t sf) {
  int32_t flag = sf & 0x3fff;
  bool_t returnvalue;
  if(flag < 64) {
    returnvalue = (systemFlags0Changed & ((uint64_t)1 << flag)) != 0;
    systemFlags0Changed &= ~((uint64_t)1 << flag);
  }
  else if (flag < 128) {
    returnvalue = (systemFlags1Changed & ((uint64_t)1 << (flag - 64))) != 0;
    systemFlags1Changed &= ~((uint64_t)1 << (flag - 64));
  }
  else {
    returnvalue = (systemFlags2Changed & ((uint64_t)1 << (flag - 128))) != 0;
    systemFlags2Changed &= ~((uint64_t)1 << (flag - 128));
  }
  return returnvalue;
}

void setSystemFlagChanged(int32_t sf) {  // only valid for labels from SETTING_...
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0Changed |= ((uint64_t)1 << (flag-0));
  }
  else if (flag < 128) {
    systemFlags1Changed |= ((uint64_t)1 << (flag-64));
  }
  else {
    systemFlags2Changed |= ((uint64_t)1 << (flag-128));
  }
}

void setAllSystemFlagChanged(void) {
  systemFlags0Changed = 0xFFFFFFFFFFFFFFFF;
  systemFlags1Changed = 0xFFFFFFFFFFFFFFFF;
  systemFlags2Changed = 0xFFFFFFFFFFFFFFFF;
}



void forceSystemFlag(unsigned int sf, int set) {
  if(set) {
    setSystemFlag(sf);
  }
  else {
    clearSystemFlag(sf);
  }
}



#if !defined(TESTSUITE_BUILD)
static void _setAlpha(void) {
  if(calcMode != CM_EIM) {
    calcModeAim(NOPARAM);
  }
}

static void _clearAlpha(void) {
  if(calcMode == CM_EIM) {
    if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQ_EDIT) {
      calcModeNormal();
      if(allFormulae[currentFormula].pointerToFormulaData == C47_NULL) {
        deleteEquation(currentFormula);
      }
    }
    popSoftmenu();
  }
  else {
    calcModeNormal();
  }
}
#endif // TESTSUITE_BUILD



/********************************************//**
 * \brief Returns the status of a flag
 *
 * \param[in] flag uint16_t
 * \return bool_t
 ***********************************************/
bool_t getFlag(uint16_t flag) {
  if(flag & 0x8000) { // System flag
    return getSystemFlag(flag);
  }

  else if(flag <= FLAG_K) { // Global flag
    return (globalFlags[flag/16] & (1u << (flag%16))) != 0;
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        return (*currentLocalFlags & (1u << (uint32_t)flag)) != 0;
      }
      else {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgNotDefinedMustBe], "getFlag", "local flag", flag, NUMBER_OF_LOCAL_FLAGS - 1);
        displayBugScreen(errorMessage);
      }
    }
    #if defined(PC_BUILD)
    else {
      moreInfoOnError("In function getFlag:", "no local flags defined!", "", "");
    }
    #endif // PC_BUILD
  }

  else if(FLAG_M <= flag && flag <= FLAG_W) { // Extra global flag
    flag -= 99;
    return (globalFlags[flag/16] & (1u << (flag%16))) != 0;
  }

  #if defined(PC_BUILD)
  else {
    if(flag < FLAG_M) {
      sprintf(tmpString, "there is no local flag above .31 (%" PRIu16 ")", flag);
    }
    else {
      sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
    }
  }
  #endif // PC_BUILD

  return false;
 }



/********************************************//**
 * \brief Returns the status of a system flag
 *
 * \param[in] systemFlag uint16_t
 * \return void
 ***********************************************/
void fnGetSystemFlag(uint16_t systemFlag) {
  if(getSystemFlag(systemFlag)) {
    temporaryInformation = TI_TRUE;
  }
  else {
    temporaryInformation = TI_FALSE;
  }
 }



/********************************************//**
 * \brief Sets a flag
 *
 * \param[in] flag uint16_t
 * \return void
 ***********************************************/
void fnSetFlag(uint16_t flag) {
  if(flag & 0x8000) { // System flag
    if(isSystemFlagWriteProtected(flag)) {
      temporaryInformation = TI_NO_INFO;
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      displayCalcErrorMessage(ERROR_WRITE_PROTECTED_SYSTEM_FLAG, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "protected system flag (%" PRIu16 ")!", (uint16_t)(flag & 0x3fff));
        moreInfoOnError("In function fnSetFlag:", "Tying to set a write", errorMessage, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    #if !defined(TESTSUITE_BUILD)
      else if(flag == FLAG_ALPHA) {
        tamLeaveMode();
        _setAlpha();
      }
    #endif // !TESTSUITE_BUILD
    else {
      setSystemFlag(flag);
    }
  }

  else if(flag <= FLAG_K) { // Global flag
    globalFlags[flag/16] |= 1u << (flag%16);
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        *currentLocalFlags |=  (1u << (uint32_t)flag);
      }
      else {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgNotDefinedMustBe], "fnSetFlag", "local flag", flag, NUMBER_OF_LOCAL_FLAGS - 1);
        displayBugScreen(errorMessage);
      }
    }
    #if defined(PC_BUILD)
    else {
      moreInfoOnError("In function fnSetFlag:", "no local flags defined!", "", "");
    }
    #endif // PC_BUILD
  }

  else if(FLAG_M <= flag && flag <= FLAG_W) { // Extra global flag
    flag -= 99;
    globalFlags[flag/16] |= 1u << (flag%16);
  }

  #if defined(PC_BUILD)
  else {
    if(flag < FLAG_M) {
      sprintf(tmpString, "there is no local flag above .31 (%" PRIu16 ")", flag);
    }
    else {
      sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
    }
    moreInfoOnError("In function fnSetFlag:", tmpString, "", "");
  }
  #endif // PC_BUILD
}



/********************************************//**
 * \brief Clears a flag
 *
 * \param[in] flags uint16_t
 * \return void
 ***********************************************/
void fnClearFlag(uint16_t flag) {
  if(flag & 0x8000) { // System flag
    if(isSystemFlagWriteProtected(flag)) {
      temporaryInformation = TI_NO_INFO;
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      displayCalcErrorMessage(ERROR_WRITE_PROTECTED_SYSTEM_FLAG, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "protected system flag (%" PRIu16 ")!", (uint16_t)(flag & 0x3fff));
        moreInfoOnError("In function fnClearFlag:", "Tying to clear a write", errorMessage, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    #if !defined(TESTSUITE_BUILD)
      else if(flag == FLAG_ALPHA) {
        tamLeaveMode();
        _clearAlpha();
      }
    #endif // !TESTSUITE_BUILD
    else {
      clearSystemFlag(flag);
    }
  }

  else if(flag <= FLAG_K) { // Global flag
    globalFlags[flag/16] &= ~(1u << (flag%16));
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        *currentLocalFlags &= ~(1u << (uint32_t)flag);
      }
      else {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgNotDefinedMustBe], "fnClearFlag", "local flag", flag, NUMBER_OF_LOCAL_FLAGS - 1);
        displayBugScreen(errorMessage);
      }
    }

    #if defined(PC_BUILD)
      else {
       moreInfoOnError("In function fnClearFlag:", "no local flags defined!", "", "");
      }
    #endif // PC_BUILD
  }

  else if(FLAG_M <= flag && flag <= FLAG_W) { // Extra global flag
    flag -= 99;
    globalFlags[flag/16] &= ~(1u << (flag%16));
  }

  #if defined(PC_BUILD)
  else {
    if(flag < FLAG_M) {
      sprintf(tmpString, "there is no local flag above .31 (%" PRIu16 ")", flag);
    }
    else {
      sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
    }
    moreInfoOnError("In function fnClearFlag:", tmpString, "", "");
  }
  #endif // PC_BUILD
}



/********************************************//**
 * \brief Flips a flag
 *
 * \param[in] flags uint16_t
 * \return void
 ***********************************************/
void fnFlipFlag(uint16_t flag) {
  if(flag & 0x8000) { // System flag
    if(isSystemFlagWriteProtected(flag)) {
      temporaryInformation = TI_NO_INFO;
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      displayCalcErrorMessage(ERROR_WRITE_PROTECTED_SYSTEM_FLAG, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "protected system flag (%" PRIu16 ")!", (uint16_t)(flag & 0x3fff));
        moreInfoOnError("In function fnFlipFlag:", "Tying to flip a write", errorMessage, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    #if !defined(TESTSUITE_BUILD)
      else if(flag == FLAG_ALPHA) {
        tamLeaveMode();
        if(getSystemFlag(FLAG_ALPHA)) {
          _clearAlpha();
        }
        else {
          _setAlpha();
        }
      }
    #endif // !TESTSUITE_BUILD
    else {
      flipSystemFlag(flag);
    }
  }

  else if(flag <= FLAG_K) { // Global flag
    globalFlags[flag/16] ^=  1u << (flag%16);
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        *currentLocalFlags ^=  (1u << (uint32_t)flag);
      }
      else {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgNotDefinedMustBe], "fnFlipFlag", "local flag", flag, NUMBER_OF_LOCAL_FLAGS - 1);
        displayBugScreen(errorMessage);
      }
    }
    #if defined(PC_BUILD)
      else {
        moreInfoOnError("In function fnFlipFlag:", "no local flags defined!", "", "");
      }
    #endif // PC_BUILD
  }

  else if(FLAG_M <= flag && flag <= FLAG_W) { // Extra global flag
    flag -= 99;
    globalFlags[flag/16] ^=  1u << (flag%16);
  }

  #if defined(PC_BUILD)
  else {
    if(flag < FLAG_M) {
      sprintf(tmpString, "there is no local flag above .31 (%" PRIu16 ")", flag);
    }
    else {
      sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
    }
    moreInfoOnError("In function fnFlipFlag:", tmpString, "", "");
  }
  #endif // PC_BUILD
}



/********************************************//**
 * \brief Clear all global flags and the local flags
 *
 * \param[in] flags uint16_t
 * \return void
 ***********************************************/
void fnClFAll(uint16_t confirmation) {
  if((confirmation == NOT_CONFIRMED) && (programRunStop != PGM_RUNNING)) {
    setConfirmationMode(fnClFAll);
  }
  else {
    memset(globalFlags, 0, sizeof(globalFlags)); // Clear global flags from 00 to 99 and X to W

    if(currentLocalFlags != NULL) {
      *currentLocalFlags = 0; // Clear local flags
    }
  }
}


void fnIsFlagClear(uint16_t flag) {
  SET_TI_TRUE_FALSE(!getFlag(flag));
}


void fnIsFlagClearClear(uint16_t flag) {
  SET_TI_TRUE_FALSE(!getFlag(flag));
  fnClearFlag(flag);
}


void fnIsFlagClearSet(uint16_t flag) {
  SET_TI_TRUE_FALSE(!getFlag(flag));
  fnSetFlag(flag);
}


void fnIsFlagClearFlip(uint16_t flag) {
  SET_TI_TRUE_FALSE(!getFlag(flag));
  fnFlipFlag(flag);
}


void fnIsFlagSet(uint16_t flag) {
  SET_TI_TRUE_FALSE(getFlag(flag));
}


void fnIsFlagSetClear(uint16_t flag) {
  SET_TI_TRUE_FALSE(getFlag(flag));
  fnClearFlag(flag);
}


void fnIsFlagSetSet(uint16_t flag) {
  SET_TI_TRUE_FALSE(getFlag(flag));
  fnSetFlag(flag);
}


void fnIsFlagSetFlip(uint16_t flag) {
  SET_TI_TRUE_FALSE(getFlag(flag));
  fnFlipFlag(flag);
}



/********************************************//**
 * \brief Sets/resets flag
 *
 * \param[in] jmConfig uint16_t
 * \return void
 ***********************************************/
void SetSetting(uint16_t jmConfig) {
  switch(jmConfig) {
    case JC_G_DOUBLETAP: jm_G_DOUBLETAP = !jm_G_DOUBLETAP;                           fnRefreshState(); break;
    case JC_HOME_TRIPLE: HOME3 = !HOME3;           if(HOME3) {MYM3 = false;}         fnRefreshState(); break;
    case JC_MYM_TRIPLE:  MYM3 = !MYM3;             if(MYM3) {HOME3 = false;}         fnRefreshState(); break;
    case JC_SHFT_4s:     ShiftTimoutMode = !ShiftTimoutMode;                         fnRefreshState(); break;
    case JC_BASE_MYM:    BASE_MYM = !BASE_MYM;     if(BASE_MYM) {BASE_HOME = false;} fnRefreshState(); break;
    case JC_BASE_HOME:   BASE_HOME = !BASE_HOME;   if(BASE_HOME) {BASE_MYM = false;} fnRefreshState(); break;


    case TF_H12:         fnClearFlag(FLAG_TDM24);                               break;
    case TF_H24:         fnSetFlag(FLAG_TDM24);                                 break;
    case CU_I:           fnClearFlag(FLAG_CPXj);                                break;
    case CU_J:           fnSetFlag(FLAG_CPXj);                                  break;
    case PS_DOT:         fnClearFlag(FLAG_MULTx);                               break;
    case PS_CROSS:       fnSetFlag(FLAG_MULTx);                                 break;
    case SS_4:           fnClearFlag(FLAG_SSIZE8);                              break;
    case SS_8:           fnSetFlag(FLAG_SSIZE8);                                break;
    case CM_RECTANGULAR: fnClearFlag(FLAG_POLAR);                               break;
    case CM_POLAR:       fnSetFlag(FLAG_POLAR);                                 break;
    case DO_SCI:         fnClearFlag(FLAG_ENGOVR);                              break;
    case DO_ENG:         fnSetFlag(FLAG_ENGOVR);                                break;

    case JC_NL:          fnFlipFlag(FLAG_NUMLOCK); showAlphaModeonGui();        break; //

    case FLAG_HPRP:      //this list is for flags that have HP42 compatible menu set buttons operating the underlying flags
    case FLAG_MNUp1:
    case FLAG_HPBASE:
    case FLAG_2TO10:
    case FLAG_PROPFR:
    case FLAG_PRTACT:
    case FLAG_LEAD0:
    case FLAG_CPXRES:
    case FLAG_SPCRES:
    case FLAG_ERPN:
    case FLAG_FRCYC:
    case FLAG_CPXMULT:
    case FLAG_CPXPLOT:
    case FLAG_SHOWX   :
    case FLAG_SHOWY   :
    case FLAG_PBOX   :
    case FLAG_PCROS  :
    case FLAG_PPLUS  :
    case FLAG_PLINE  :
    case FLAG_SCALE  :
    case FLAG_VECT   :
    case FLAG_NVECT  :
    case FLAG_TOPHEX :
              fnFlipFlag(jmConfig);                                  break; //
    case FLAG_DENANY:    fnFlipFlag(FLAG_DENANY); clearSystemFlag(FLAG_DENFIX); break;
    case FLAG_DENFIX:    fnFlipFlag(FLAG_DENFIX); clearSystemFlag(FLAG_DENANY); break;

    case FLAG_FRACT:
      fnFlipFlag(FLAG_FRACT);
      break;

    case ITM_DREAL:
      fnFlipFlag(FLAG_DREAL);
      if(getSystemFlag(FLAG_DREAL)) {
        clearSystemFlag(FLAG_LARGELI);
      }
      break;
    case FLAG_LARGELI:
      fnFlipFlag(FLAG_LARGELI);
      if(getSystemFlag(FLAG_LARGELI)) {
        clearSystemFlag(FLAG_DREAL);
      }
      break;
    case FLAG_IRFRAC:
      fnFlipFlag(FLAG_IRFRAC);
      fnRefreshState();
      break;



    case JC_UC:
      if(alphaCase == AC_LOWER) {
        alphaCase = AC_UPPER;
      }
      else {
        alphaCase = AC_LOWER;
      }
      break;
    case JC_SS:     //call sub/sup script
      if(scrLock == NC_NORMAL) {
        scrLock = NC_SUBSCRIPT;
      }
      else if(scrLock == NC_SUBSCRIPT) {
        scrLock = NC_SUPERSCRIPT;
      }
      else if(scrLock == NC_SUPERSCRIPT) {
        scrLock = NC_NORMAL;
      }
      else {
        scrLock = NC_NORMAL;
      }
      nextChar = scrLock;
      showAlphaModeonGui();
      break;

    default: break;
  }
  fnRefreshState();
}
