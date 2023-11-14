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

#include "wp43.h"

void systemFlagAction(uint16_t systemFlag, uint16_t action) {
  switch(systemFlag) {
    case FLAG_ALLENG: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_A/16] &= ~(1u << (FLAG_A%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_A/16] |=   1u << (FLAG_A%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_A/16] ^=   1u << (FLAG_A%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_OVERFLOW: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_B/16] &= ~(1u << (FLAG_B%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_B/16] |=   1u << (FLAG_B%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_B/16] ^=   1u << (FLAG_B%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_CARRY: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_C/16] &= ~(1u << (FLAG_C%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_C/16] |=   1u << (FLAG_C%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_C/16] ^=   1u << (FLAG_C%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_SPCRES: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_D/16] &= ~(1u << (FLAG_D%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_D/16] |=   1u << (FLAG_D%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_D/16] ^=   1u << (FLAG_D%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_CPXRES: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_I/16] &= ~(1u << (FLAG_I%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_I/16] |=   1u << (FLAG_I%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_I/16] ^=   1u << (FLAG_I%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_LEAD0: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_L/16] &= ~(1u << (FLAG_L%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_L/16] |=   1u << (FLAG_L%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_L/16] ^=   1u << (FLAG_L%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_TRACE: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_T/16] &= ~(1u << (FLAG_T%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_T/16] |=   1u << (FLAG_T%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_T/16] ^=   1u << (FLAG_T%16);
          break;
        }
        default: ;
      }
      break;
    }

    case FLAG_POLAR: {
      switch(action) {
        case 0: {
          globalFlags[FLAG_X/16] &= ~(1u << (FLAG_X%16));
          break;
        }
        case 1: {
          globalFlags[FLAG_X/16] |=   1u << (FLAG_X%16);
          break;
        }
        case 2: {
          globalFlags[FLAG_X/16] ^=   1u << (FLAG_X%16);
          break;
        }
        default: ;
      }
      break;
    }

    default: ;
  }

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
    case FLAG_2TO10:
                     fnRefreshState(); break;



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


    default: ;
  }
}



void synchronizeLetteredFlags(void) {
  if(getSystemFlag(FLAG_ALLENG)) {
    setSystemFlag(FLAG_ALLENG)
  }
  else {
    clearSystemFlag(FLAG_ALLENG)
  }

  if(getSystemFlag(FLAG_OVERFLOW)) {
    setSystemFlag(FLAG_OVERFLOW)
  }
  else {
    clearSystemFlag(FLAG_OVERFLOW)
  }

  if(getSystemFlag(FLAG_CARRY)) {
    setSystemFlag(FLAG_CARRY)
  }
  else {
    clearSystemFlag(FLAG_CARRY)
  }

  if(getSystemFlag(FLAG_SPCRES)) {
    setSystemFlag(FLAG_SPCRES)
  }
  else {
    clearSystemFlag(FLAG_SPCRES)
  }

  if(getSystemFlag(FLAG_CPXRES)) {
    setSystemFlag(FLAG_CPXRES)
  }
  else {
    clearSystemFlag(FLAG_CPXRES)
  }

  if(getSystemFlag(FLAG_LEAD0)) {
    setSystemFlag(FLAG_LEAD0)
  }
  else {
    clearSystemFlag(FLAG_LEAD0)
  }

  if(getSystemFlag(FLAG_TRACE)) {
    setSystemFlag(FLAG_TRACE)
  }
  else {
    clearSystemFlag(FLAG_TRACE)
  }

  if(getSystemFlag(FLAG_POLAR)) {
    setSystemFlag(FLAG_POLAR)
  }
  else {
    clearSystemFlag(FLAG_POLAR)
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
  else if(flag < NUMBER_OF_GLOBAL_FLAGS) { // Global flag
    return (globalFlags[flag/16] & (1u << (flag%16))) != 0;
  }
  else { // Local flag
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
        moreInfoOnError("In function getFlag:", "no local flags defined!", "To do so, you can find LocR here:", "[g] [P.FN] [g] [F5]");
      }
    #endif // PC_BUILD
  }
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
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
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
  else if(flag < NUMBER_OF_GLOBAL_FLAGS) { // Global flag
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
  else { // Local flag
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
        moreInfoOnError("In function fnSetFlag:", "no local flags defined!", "To do so, you can find LocR here:", "[g] [P.FN] [g] [F5]");
      }
    #endif // PC_BUILD
  }
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
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
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
  else if(flag < NUMBER_OF_GLOBAL_FLAGS) { // Global flag
    switch(flag) {
      case FLAG_A: {
        clearSystemFlag(FLAG_ALLENG);
        break;
      }
      case FLAG_B: {
        clearSystemFlag(FLAG_OVERFLOW);
        break;
      }
      case FLAG_C: {
        clearSystemFlag(FLAG_CARRY);
        break;
      }
      case FLAG_D: {
        clearSystemFlag(FLAG_SPCRES);
        break;
      }
      case FLAG_I: {
        clearSystemFlag(FLAG_CPXRES);
        break;
      }
      case FLAG_L: {
        clearSystemFlag(FLAG_LEAD0);
        break;
      }
      case FLAG_T: {
        clearSystemFlag(FLAG_TRACE);
        break;
      }
      case FLAG_X: {
        clearSystemFlag(FLAG_POLAR);
        break;
      }
      default: {
        globalFlags[flag/16] &= ~(1u << (flag%16));
      }
    }
  }
  else { // Local flag
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
       moreInfoOnError("In function fnClearFlag:", "no local flags defined!", "To do so, you can find LocR here:", "[g] [P.FN] [g] [F5]");
      }
    #endif // PC_BUILD
  }
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
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
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
  else if(flag < NUMBER_OF_GLOBAL_FLAGS) { // Global flag
    switch(flag) {
      case FLAG_A: {
        flipSystemFlag(FLAG_ALLENG);
        break;
      }
      case FLAG_B: {
        flipSystemFlag(FLAG_OVERFLOW);
        break;
      }
      case FLAG_C: {
        flipSystemFlag(FLAG_CARRY);
        break;
      }
      case FLAG_D: {
        flipSystemFlag(FLAG_SPCRES);
        break;
      }
      case FLAG_I: {
        flipSystemFlag(FLAG_CPXRES);
        break;
      }
      case FLAG_L: {
        flipSystemFlag(FLAG_LEAD0);
        break;
      }
      case FLAG_T: {
        flipSystemFlag(FLAG_TRACE);
        break;
      }
      case FLAG_X: {
        flipSystemFlag(FLAG_POLAR);
        break;
      }
      default: {
        globalFlags[flag/16] ^=  1u << (flag%16);
      }
    }
  }
  else { // Local flag
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
        moreInfoOnError("In function fnFlipFlag:", "no local flags defined!", "To do so, you can find LocR here:", "[g] [P.FN] [g] [F5]");
      }
    #endif // PC_BUILD
  }
}



/********************************************//**
 * \brief Clear all global from 00 to 99 and the local flags
 *
 * \param[in] flags uint16_t
 * \return void
 ***********************************************/
void fnClFAll(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED) {
    setConfirmationMode(fnClAll);
  }
  else {
    // Leave lettered flags as they are
    memset(globalFlags, 0, sizeof(globalFlags) - sizeof(uint16_t)); // Clear flags from 00 to 95
    globalFlags[6] &= 0xfff0; // Clear flags from 96 to 99

    if(currentLocalFlags != NULL) {
      currentLocalFlags->localFlags = 0;
    }
  }
}



void fnIsFlagClear(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_FALSE : TI_TRUE);
}



void fnIsFlagClearClear(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_FALSE : TI_TRUE);
  fnClearFlag(flag);
}



void fnIsFlagClearSet(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_FALSE : TI_TRUE);
  fnSetFlag(flag);
}



void fnIsFlagClearFlip(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_FALSE : TI_TRUE);
  fnFlipFlag(flag);
}



void fnIsFlagSet(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_TRUE : TI_FALSE);
}




void fnIsFlagSetClear(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_TRUE : TI_FALSE);
  fnClearFlag(flag);
}




void fnIsFlagSetSet(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_TRUE : TI_FALSE);
  fnSetFlag(flag);
}




void fnIsFlagSetFlip(uint16_t flag) {
  temporaryInformation = (getFlag(flag) ? TI_TRUE : TI_FALSE);
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

    case JC_ERPN:
      eRPN = !eRPN;
      fnRefreshState();
      break;

    case JC_G_DOUBLETAP: {
      jm_G_DOUBLETAP = !jm_G_DOUBLETAP;
      fnRefreshState();
      break;
    }

    case JC_HOME_TRIPLE: {
      HOME3 = !HOME3;
      if(HOME3) {
        MYM3 = false;
      }
      fnRefreshState();
      break;
    }

    case JC_MYM_TRIPLE: {
      MYM3 = !MYM3;
      if(MYM3) {
        HOME3 = false;
      }
      fnRefreshState();
      break;
    }

    case JC_SHFT_4s: {
      ShiftTimoutMode = !ShiftTimoutMode;
      fnRefreshState();
      break;
    }

    case JC_BASE_MYM: {
      BASE_MYM = !BASE_MYM;
      if(BASE_MYM) {
        BASE_HOME = false;
      }
      fnRefreshState();
      break;
    }

    case JC_BASE_HOME: {
      BASE_HOME = !BASE_HOME;
      if(BASE_HOME) {
        BASE_MYM = false;
      }
      fnRefreshState();
      break;
    }

    case JC_LARGELI: {
      jm_LARGELI = !jm_LARGELI;
      fnRefreshState();
      break;
    }

    case JC_CPXMULT: {
      CPXMULT = !CPXMULT;
      fnRefreshState();
      break;
    }

    case JC_IRFRAC: {
      constantFractions = !constantFractions;
      if(constantFractions) {
        if(getSystemFlag(FLAG_FRACT)) {
          clearSystemFlag(FLAG_FRACT);
          constantFractionsOn = true;
        }
      }
      else {
        if(constantFractionsOn) {              //when switching off IRFRAC, if it was currently displaying, revert back to fractions, not decimal
          setSystemFlag(FLAG_FRACT);
          constantFractionsOn = false;
        }
      }
      fnRefreshState();
      break;
    }

    case TF_H12: {
      fnClearFlag(FLAG_TDM24);
      break;
    }

    case TF_H24: {
      fnSetFlag(FLAG_TDM24);
      break;
    }

    case CU_I: {
      fnClearFlag(FLAG_CPXj);
      break;
    }

    case CU_J: {
      fnSetFlag(FLAG_CPXj);
      break;
    }

    case PS_DOT: {
      fnClearFlag(FLAG_MULTx);
      break;
    }

    case PS_CROSS: {
      fnSetFlag(FLAG_MULTx);
      break;
    }

    case SS_4: {
      fnClearFlag(FLAG_SSIZE8);
      break;
    }

    case SS_8: {
      fnSetFlag(FLAG_SSIZE8);
      break;
    }

    case CM_RECTANGULAR: {
      fnClearFlag(FLAG_POLAR);
      if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
        setComplexRegisterPolarMode(REGISTER_X, ~amPolar);
        setComplexRegisterAngularMode(REGISTER_X, amNone);
      }
      break;
    }

    case CM_POLAR: {
      fnSetFlag(FLAG_POLAR);
      if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
        setComplexRegisterPolarMode(REGISTER_X, amPolar);
        if(getComplexRegisterAngularMode(REGISTER_X) == amNone) {
          setComplexRegisterAngularMode(REGISTER_X, currentAngularMode);
        }
      }
      break;
    }

    case DO_SCI: {
      fnClearFlag(FLAG_ALLENG);
      break;
    }

    case DO_ENG: {
      fnSetFlag(FLAG_ALLENG);
      break;
    }

    case PR_HPRP: {
      fnFlipFlag(FLAG_HPRP);
      break;
    }

    case PR_HPBASE: {
      fnFlipFlag(FLAG_HPBASE);
      break;
    }

    case PR_2TO10: {
      fnFlipFlag(FLAG_2TO10);
      break;
    }

    case DM_ANY: {
      fnFlipFlag(FLAG_DENANY);
      break;
    }

    case DM_PROPFR: {
      fnFlipFlag(FLAG_PROPFR);
      break;
    }

    case DM_FIX: {
      fnFlipFlag(FLAG_DENFIX);
      break;
    }

    case PRTACT: {
      fnFlipFlag(FLAG_PRTACT);
      break;
    }

    case JC_BLZ: {    //bit LeadingZeros
      fnFlipFlag(FLAG_LEAD0);
      break;
    }

    case JC_BCR: {    //bit ComplexResult
      fnFlipFlag(FLAG_CPXRES);
      break;
    }

    case ITM_CPXRES1: {    //bit ComplexResult
      fnSetFlag(FLAG_CPXRES);
      break;
    }

    case ITM_CPXRES0: {    //bit ComplexResult
      fnClearFlag(FLAG_CPXRES);
      break;
    }

    case JC_BSR: {    //bit SpecialResult
      fnFlipFlag(FLAG_SPCRES);
      break;
    }

    case ITM_SPCRES1: {    //bit SpecialResult
      fnSetFlag(FLAG_SPCRES);
      break;
    }

    case ITM_SPCRES0: {    //bit SpecialResult
      fnClearFlag(FLAG_SPCRES);
      break;
    }

    case ITM_PRTACT1: {
      fnSetFlag(FLAG_PRTACT);
      break;
    }

    case ITM_PRTACT0: {
      fnClearFlag(FLAG_PRTACT);
      break;
    }

    case JC_FRC: {    //bit
      fnFlipFlag(FLAG_FRCSRN);
      break;
    }

    case JC_NL: {    //call numlock
      numLock = !numLock;
      showAlphaModeonGui();
      break;
    }

    case JC_UC: {    //call flip case
      numLock = false;
      if(alphaCase == AC_LOWER)
        alphaCase = AC_UPPER;
      else
        alphaCase = AC_LOWER;
       showAlphaModeonGui();
       break;
     }

    case JC_SS: {    //call sub/sup script
      if(scrLock == NC_NORMAL) {
        scrLock = NC_SUPERSCRIPT;
      } else if(scrLock == NC_SUPERSCRIPT) {
        scrLock = NC_SUBSCRIPT;
      } else
      if(scrLock == NC_SUBSCRIPT) {
        scrLock = NC_NORMAL;
      } else {
        scrLock = NC_NORMAL;
      }
      nextChar = scrLock;
      showAlphaModeonGui();
      break;
    }


    default:
    break;
  }
fnRefreshState();
}


