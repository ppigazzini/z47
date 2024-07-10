/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file flags.c
 ***********************************************/

#include "flags.h"

#include "calcMode.h"
#include "config.h"
#include "error.h"
#include "items.h"
#include "registers.h"
#include "softmenus.h"
#include "solver/equation.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/keyboardTweak.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "ui/tam.h"
#include <string.h>

#include "c47.h"

typedef enum { FLAG_CLEAR=0, FLAG_SET=1, FLAG_FLIP=2 } flagAction_t;

static void systemFlagProcess(unsigned int idx, flagAction_t action) {
  const unsigned int n = idx / 16;
  const unsigned int b = idx % 16;

  switch(action) {
    case FLAG_CLEAR: {
      globalFlags[n] &= ~(1u << b);
      break;
    }
    case FLAG_SET: {
      globalFlags[n] |=   1u << b;
      break;
    }
    case FLAG_FLIP: {
      globalFlags[n] ^=   1u << b;
      break;
    }
  }
}

static void systemFlagAction(uint16_t systemFlag, flagAction_t action) {
  switch(systemFlag) {
    case FLAG_ALLENG:   systemFlagProcess(FLAG_A, action); break;
    case FLAG_OVERFLOW: systemFlagProcess(FLAG_B, action); break;
    case FLAG_CARRY:    systemFlagProcess(FLAG_C, action); break;
    case FLAG_SPCRES:   systemFlagProcess(FLAG_D, action); break;
    case FLAG_CPXRES:   systemFlagProcess(FLAG_I, action); break;
    case FLAG_LEAD0:    systemFlagProcess(FLAG_L, action); break;
    case FLAG_TRACE:    systemFlagProcess(FLAG_T, action); break;
    case FLAG_POLAR:    systemFlagProcess(FLAG_X, action); break;
    default:                                               break;
  }

// this will clash with the button! maybe have straight flags only  if(systemFlag == FLAG_IRFRAC && (action == FLAG_SET || (action == FLAG_FLIP && !getSystemFlag(FLAG_IRFRAC)))) {
// this will clash with the button! maybe have straight flags only    setSystemFlag(FLAG_IRF_ON);
// this will clash with the button! maybe have straight flags only  } 
// this will clash with the button! maybe have straight flags only  else if(systemFlag == FLAG_IRFRAC && (action == FLAG_CLEAR || (action == FLAG_FLIP && getSystemFlag(FLAG_IRFRAC)))) {
// this will clash with the button! maybe have straight flags only    clearSystemFlag(FLAG_IRF_ON);
// this will clash with the button! maybe have straight flags only  } 

  switch(systemFlag) {
    case FLAG_YMD:
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
    case FLAG_ALLENG:
    case FLAG_ENDPMT:
    case FLAG_HPRP:
    case FLAG_HPBASE:
    case FLAG_NUMLOCK:
    case FLAG_CPXMULT:
    case FLAG_ERPN:
    case FLAG_LARGELI:
    case FLAG_IRFRAC:
    case FLAG_IRF_ON:
    case FLAG_2TO10:  fnRefreshState(); break;

    case FLAG_SBdate:
    case FLAG_SBtime:
    case FLAG_SBcr  :
    case FLAG_SBcpx :
    case FLAG_SBang :
    case FLAG_SBfrac:
    case FLAG_SBint :
    case FLAG_SBmx  :
    case FLAG_SBtvm :
    case FLAG_SBoc  :
    case FLAG_SBss  :
    case FLAG_SBclk :
    case FLAG_SBser :
    case FLAG_SBprn :
    case FLAG_SBbatV:
    case FLAG_SBshfR: fnRefreshState(); screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR; break;

    default: break;
  }
}

void setSystemFlag(unsigned int sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0 |= ((uint64_t)1 << flag);
    systemFlagAction(sf, FLAG_SET);
  }
  else {
    systemFlags1 |= ((uint64_t)1 << (flag - 64));
    systemFlagAction(sf, FLAG_SET);
  }
}

void clearSystemFlag(unsigned int sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0 &= ~((uint64_t)1 << flag);
    systemFlagAction(sf, FLAG_CLEAR);
  }
  else {
    systemFlags1 &= ~((uint64_t)1 << (flag - 64));
    systemFlagAction(sf, FLAG_CLEAR);
  }
}

void flipSystemFlag(unsigned int sf) {
  int32_t flag = sf & 0x3fff;

  if(flag < 64) {
    systemFlags0 ^=  ((uint64_t)1 << flag);
    systemFlagAction(sf, FLAG_FLIP);
  }
  else {
    systemFlags1 ^=  ((uint64_t)1 << (flag - 64));
    systemFlagAction(sf, FLAG_FLIP);
  }
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
        return (currentLocalFlags->localFlags & (1u << (uint32_t)flag)) != 0;
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
    moreInfoOnError("In function getFlag:", "there is no flag beyond FLAG_W", "", "");
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

  else if(flag < FLAG_K) { // Global flag
    switch(flag) {
      case FLAG_A: setSystemFlag(FLAG_ALLENG);   break;
      case FLAG_B: setSystemFlag(FLAG_OVERFLOW); break;
      case FLAG_C: setSystemFlag(FLAG_CARRY);    break;
      case FLAG_D: setSystemFlag(FLAG_SPCRES);   break;
      case FLAG_I: setSystemFlag(FLAG_CPXRES);   break;
      case FLAG_L: setSystemFlag(FLAG_LEAD0);    break;
      case FLAG_T: setSystemFlag(FLAG_TRACE);    break;
      case FLAG_X: setSystemFlag(FLAG_POLAR);    break;
      default: globalFlags[flag/16] |= 1u << (flag%16);
    }
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        currentLocalFlags->localFlags |=  (1u << (uint32_t)flag);
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
    sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
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

  else if(flag < FLAG_K) { // Global flag
    switch(flag) {
      case FLAG_A: clearSystemFlag(FLAG_ALLENG);   break;
      case FLAG_B: clearSystemFlag(FLAG_OVERFLOW); break;
      case FLAG_C: clearSystemFlag(FLAG_CARRY);    break;
      case FLAG_D: clearSystemFlag(FLAG_SPCRES);   break;
      case FLAG_I: clearSystemFlag(FLAG_CPXRES);   break;
      case FLAG_L: clearSystemFlag(FLAG_LEAD0);    break;
      case FLAG_T: clearSystemFlag(FLAG_TRACE);    break;
      case FLAG_X: clearSystemFlag(FLAG_POLAR);    break;
      default:     globalFlags[flag/16] &= ~(1u << (flag%16));
    }
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        currentLocalFlags->localFlags &= ~(1u << (uint32_t)flag);
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
    sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
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
    switch(flag) {
      case FLAG_A: flipSystemFlag(FLAG_ALLENG);   break;
      case FLAG_B: flipSystemFlag(FLAG_OVERFLOW); break;
      case FLAG_C: flipSystemFlag(FLAG_CARRY);    break;
      case FLAG_D: flipSystemFlag(FLAG_SPCRES);   break;
      case FLAG_I: flipSystemFlag(FLAG_CPXRES);   break;
      case FLAG_L: flipSystemFlag(FLAG_LEAD0);    break;
      case FLAG_T: flipSystemFlag(FLAG_TRACE);    break;
      case FLAG_X: flipSystemFlag(FLAG_POLAR);    break;
      default:     globalFlags[flag/16] ^=  1u << (flag%16);
    }
  }

  else if(flag <= LAST_LOCAL_FLAG) { // Local flag
    if(currentLocalFlags != NULL) {
      flag -= NUMBER_OF_GLOBAL_FLAGS;
      if(flag < NUMBER_OF_LOCAL_FLAGS) {
        currentLocalFlags->localFlags ^=  (1u << (uint32_t)flag);
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
    sprintf(tmpString, "there is no flag beyond FLAG_W (%" PRIu16 ")", flag);
    moreInfoOnError("In function fnFlipFlag:", tmpString, "", "");
  }
  #endif // PC_BUILD
}



/********************************************//**
 * \brief Clear all global from 00 to 99 and the local flags
 *
 * \param[in] flags uint16_t
 * \return void
 ***********************************************/
void fnClFAll(uint16_t confirmation) {
  if((confirmation == NOT_CONFIRMED) && (programRunStop != PGM_RUNNING)) {
    setConfirmationMode(fnClFAll);
  }
  else {
    // Leave lettered flags as they are
    memset(globalFlags, 0, sizeof(globalFlags) - 2*sizeof(uint16_t)); // Clear flags from 00 to 95
    globalFlags[6] &= 0xfff0; // Clear flags from 96 to 99
    globalFlags[7] = 0;       // Clear flags from M to W

    if(currentLocalFlags != NULL) {
      currentLocalFlags->localFlags = 0;
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


    case TF_H12:         fnClearFlag(FLAG_TDM24);                  break;
    case TF_H24:         fnSetFlag(FLAG_TDM24);                    break;
    case CU_I:           fnClearFlag(FLAG_CPXj);                   break;
    case CU_J:           fnSetFlag(FLAG_CPXj);                     break;
    case PS_DOT:         fnClearFlag(FLAG_MULTx);                  break;
    case PS_CROSS:       fnSetFlag(FLAG_MULTx);                    break;
    case SS_4:           fnClearFlag(FLAG_SSIZE8);                 break;
    case SS_8:           fnSetFlag(FLAG_SSIZE8);                   break;
    case CM_RECTANGULAR:
      fnClearFlag(FLAG_POLAR);
      //if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {   //RECT/POLAR radiobuttons to also change the complex number in X
      //  setComplexRegisterPolarMode(REGISTER_X, ~amPolar);
      //  setComplexRegisterAngularMode(REGISTER_X, amNone);
      //}
      break;

    case CM_POLAR:
      fnSetFlag(FLAG_POLAR);
      //if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {   //RECT/POLAR radiobuttons to also change the complex number in X
      //  setComplexRegisterPolarMode(REGISTER_X, amPolar);
      //  if(getComplexRegisterAngularMode(REGISTER_X) == amNone) {
      //    setComplexRegisterAngularMode(REGISTER_X, currentAngularMode);
      //  }
      //}
      break;

    case DO_SCI:      fnClearFlag(FLAG_ALLENG);                              break;
    case DO_ENG:      fnSetFlag(FLAG_ALLENG);                                break;
    case PR_HPRP:     fnFlipFlag(FLAG_HPRP);                                 break;
    case PR_HPBASE:   fnFlipFlag(FLAG_HPBASE);                               break;
    case PR_2TO10:    fnFlipFlag(FLAG_2TO10);                                break;
    case DM_ANY:      fnFlipFlag(FLAG_DENANY); clearSystemFlag(FLAG_DENFIX); break;
    case DM_PROPFR:   fnFlipFlag(FLAG_PROPFR);                               break;
    case DM_FRACT:    fnFlipFlag(FLAG_FRACT);                                break;
    case DM_FIX:      fnFlipFlag(FLAG_DENFIX); clearSystemFlag(FLAG_DENANY); break;
    case PRTACT:      fnFlipFlag(FLAG_PRTACT);                               break;
    case JC_BLZ:      fnFlipFlag(FLAG_LEAD0);                                break; //bit LeadingZeros
    case JC_BCR:      fnFlipFlag(FLAG_CPXRES);                               break; //bit ComplexResult
    case ITM_CPXRES1: fnSetFlag(FLAG_CPXRES);                                break; //bit ComplexResult
    case ITM_CPXRES0: fnClearFlag(FLAG_CPXRES);                              break; //bit ComplexResult
    case JC_BSR:      fnFlipFlag(FLAG_SPCRES);                               break; //bit SpecialResult
    case ITM_SPCRES1: fnSetFlag(FLAG_SPCRES);                                break; //bit SpecialResult
    case ITM_SPCRES0: fnClearFlag(FLAG_SPCRES);                              break; //bit SpecialResult
    case ITM_PRTACT1: fnSetFlag(FLAG_PRTACT);                                break;
    case ITM_PRTACT0: fnClearFlag(FLAG_PRTACT);                              break;
    case JC_FRC:      fnFlipFlag(FLAG_FRCSRN);                               break; //bit
    case JC_ERPN:     fnFlipFlag(FLAG_ERPN);                                 break; //   eRPN = !eRPN;              fnRefreshState(); break;
    case JC_LARGELI:  fnFlipFlag(FLAG_LARGELI);                              break; //   jm_LARGELI = !jm_LARGELI;  fnRefreshState(); break;
    case JC_CPXMULT:  fnFlipFlag(FLAG_CPXMULT);                              break; //   CPXMULT = !CPXMULT;        fnRefreshState(); break;
    case JC_NL:       fnFlipFlag(FLAG_NUMLOCK); showAlphaModeonGui();        break; //   numLock = !numLock;        showAlphaModeonGui(); break; //call numlock
    case JC_IRFRAC:  
      fnFlipFlag(FLAG_IRFRAC);
      if(getSystemFlag(FLAG_IRFRAC)) {
        setSystemFlag(FLAG_IRF_ON);
        if(getSystemFlag(FLAG_FRACT)) {
          clearSystemFlag(FLAG_FRACT);
        }
      }
      else {
        if(getSystemFlag(FLAG_IRF_ON)) {
          clearSystemFlag(FLAG_IRF_ON);
        }
      }
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
