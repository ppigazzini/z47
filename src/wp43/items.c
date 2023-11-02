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

#include "items.h"

#include "c43Extensions/addons.h"
#include "assign.h"
#include "browsers/browsers.h"
#include "bufferize.h"
#include "calcMode.h"
#include "charString.h"
#include "config.h"
#include "constants.h"
#include "conversionAngles.h"
#include "conversionUnits.h"
#include "curveFitting.h"
#include "dateTime.h"
#include "display.h"
#include "distributions/distributions.h"
#include "error.h"
#include "flags.h"
#include "fonts.h"
#include "fractions.h"
#include "hal/audio.h"
#include "hal/io.h"
#include "c43Extensions/graphs.h"
#include "c43Extensions/inlineTest.h"
#include "integers.h"
#include "c43Extensions/jm.h"
#include "keyboard.h"
#include "c43Extensions/keyboardTweak.h"
#include "logicalOps/logicalOps.h"
#include "mathematics/linpol.h"
#include "mathematics/mathematics.h"
#include "mathematics/median.h"
#include "mathematics/matrix.h"
#include "plotstat.h"
#include "programming/decode.h"
#include "programming/programming.h"
#include "recall.h"
#include "registers.h"
#include "saveRestoreCalcState.h"
#include "saveRestorePrograms.h"
#include "screen.h"
#include "softmenus.h"
#include "solver/graph.h"
#include "solver/solver.h"
#include "stack.h"
#include "stats.h"
#include "statusBar.h"
#include "store.h"
#include "stringFuncs.h"
#include "timer.h"
#include "ui/matrixEditor.h"
#include "ui/tam.h"
#include "ui/tone.h"
#include "c43Extensions/xeqm.h"

#include <string.h>

#include "wp43.h"

void itemToBeCoded(uint16_t unusedButMandatoryParameter) {
  funcOK = false;
}

  void fnOldItemError(uint16_t unusedButMandatoryParameter) {
    #if !defined(TESTSUITE_BUILD) && !defined(GENERATE_CATALOGS)
      displayCalcErrorMessage(ERROR_OLD_ITEM_TO_REPLACE, ERR_REGISTER_LINE, REGISTER_X);
    #endif // !TESTSUITE_BUILD
  }


//#if !defined(GENERATE_CATALOGS)
//void fnToBeCoded(void) {
//  displayCalcErrorMessage(ERROR_FUNCTION_TO_BE_CODED, ERR_REGISTER_LINE, REGISTER_X);
//  #if defined(PC_BUILD)
//    moreInfoOnError("Function to be coded", "for that data type(s)!", NULL, NULL);
//  #endif // PC_BUILD
//}
//#endif // !GENERATE_CATALOGS



void fnNop(uint16_t unusedButMandatoryParameter) {
}


#if !defined(TESTSUITE_BUILD) && !defined(GENERATE_CATALOGS)
  int16_t lastFunc = 0;
  int16_t lastParam = 0;
  char    lastTemp[16];
  char *lastFuncCatalogName(void) {
    if(lastFunc == ITM_VERS || lastFunc == NOPARAM) return "";
    if(lastFunc == ITM_CNST) {
      if(lastParam < 79) {
        strcpy(lastTemp, indexOfItems[lastParam + 128].itemCatalogName);
      }
      else {
        lastTemp[0] = 0;
      }
    }
    else {
      strcpy(lastTemp, indexOfItems[lastFunc].itemCatalogName);
    }
    return lastTemp;
  }

  char *lastFuncSoftmenuName(void) {
    if(lastFunc == ITM_VERS || lastFunc == NOPARAM) return "";
    if(lastFunc == ITM_CNST) {
      if(lastParam < 79) {
        strcpy(lastTemp, indexOfItems[lastParam + 128].itemSoftmenuName);
      }
      else {
        lastTemp[0] = 0;
      }
    }
    else {
      strcpy(lastTemp, indexOfItems[lastFunc].itemSoftmenuName);
    }
    return lastTemp;
  }


  void reallyRunFunction(int16_t func, uint16_t param) {
    lastFunc = func;
    lastParam = param;
    if(func != ITM_SOLVE_VAR && (calcMode == CM_NORMAL || calcMode == CM_NIM) && 
        (softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_MVAR) && 
        (currentSolverStatus == 258 || currentSolverStatus == 259)) {  //allow interactive functions to clear the SolverReady flag
      currentSolverStatus &= ~SOLVER_STATUS_READY_TO_EXECUTE;
    }
    if(temporaryInformation == TI_LAST_CONST_CATNAME && (currentSolverStatus & 0x000F) != 0) {
      temporaryInformation = TI_NO_INFO;
    } else
    if(func >= CST_01 && func <= CST_79) {
      temporaryInformation = TI_LAST_CONST_CATNAME;
    }
    //else {                                                 //Removed code for TI of any last command
    //  temporaryInformation = TI_LAST_FUNC_CATNAME;
    //}



    if(func != ITM_CLX) { //JM Do not reset for backspace, because the timers need to run after the first action, CLX
      resetKeytimers();  //JM
    }
    if(func != ITM_DRG) { //JM Reset DRG cycling flag for any command except DRG
      DRG_Cycling = 0;  //JM
    }

    if((indexOfItems[func].status & US_STATUS) == US_ENABLED || (indexOfItems[func].status & US_STATUS) == US_ENABL_XEQ) {
      if((programRunStop != PGM_RUNNING || getSystemFlag(FLAG_IGN1ER)) && calcMode != CM_GRAPH && calcMode != CM_NO_UNDO && !getSystemFlag(FLAG_SOLVING)) {
        #if defined(DEBUGUNDO)
          printf(">>> saveForUndo from reallyRunFunction: %s, calcMode = %i ",indexOfItems[func].itemCatalogName, calcMode);
        #endif // DEBUGUNDO
        saveForUndo();
      }
      if(lastErrorCode == ERROR_RAM_FULL) {
        if((indexOfItems[func].status & US_STATUS) == US_ENABLED || calcMode == CM_CONFIRMATION) {
          displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function reallyRunFunction:", "there is not enough memory to save for undo!", NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          return;
        }
        else {
          lastErrorCode = ERROR_NONE;
          temporaryInformation = TI_UNDO_DISABLED;
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            moreInfoOnError("In function reallyRunFunction:", "there is not enough memory to save for undo!", NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
      }
    }
    else if(((indexOfItems[func].status & US_STATUS) == US_CANCEL) && calcMode != CM_NO_UNDO && calcMode !=CM_GRAPH){
      thereIsSomethingToUndo = false;
    }

    if(programRunStop != PGM_RUNNING) {
      #if defined(PC_BUILD)
        char tmp[200]; sprintf(tmp,"^^^^reallyRunFunction func=%d param=%d\n",func, param); jm_show_comment(tmp);
        //printf("---#### Before function %s\n",tmp);
      #endif // PC_BUILD

      if(func != ITM_SNAP) {
        hourGlassIconEnabled = true;
      }
      showHideHourGlass();

      if(func == ITM_GTO || func == ITM_XEQ || func == ITM_GTOP) {
        while(currentSubroutineLevel > 0) {
          fnReturn(0);
        }
        fnReturn(0); // 1 more time to clean local registers
      }

/* Full refresh included in showHideHourGlass above, so removinf it here to save time
      #if defined(DMCP_BUILD)
        lcd_refresh();
      #else // !DMCP_BUILD
        refreshLcd(NULL);
      #endif // DMCP_BUILD
*/

    screenUpdatingMode = SCRUPD_AUTO;
    }
    else {
      force_refresh(timed); //Added this to enable 0.5 second refresh during running
      #if defined(PC_BUILD) && VERBOSE_LEVEL > -1
        printf("   >>>   reallyRunFunction: §%s§%s§\n",indexOfItems[abs(func)].itemCatalogName, indexOfItems[abs(func)].itemSoftmenuName);
      #endif // PC_BUILD
    }


    indexOfItems[func].func(param);

    #if defined(DMCP_BUILD)
      updateVbatIntegrated();              //Check the battery directly after a task so that the worst case voltage is recorded
    #endif


    //TI for conversion menus
    if(lastErrorCode == ERROR_NONE && temporaryInformation == TI_NO_INFO) {
      switch(softmenu[softmenuStack[0].softmenuId].menuItem) {
        case -MNU_CONVE :
        case -MNU_CONVP :
        case -MNU_CONVFP:
        case -MNU_CONVM :
        case -MNU_CONVX :
        case -MNU_CONVV :
        case -MNU_CONVA :
        case -MNU_CONVS :
        case -MNU_CONVANG :
        case -MNU_MISC :
        case -MNU_CONVHUM :
        case -MNU_CONVYMMV : {
          errorMessage[0]=0;
          strcat(errorMessage,indexOfItems[func].itemCatalogName);
          temporaryInformation = TI_NO_INFO;
          int16_t i = 0;
          while(errorMessage[i+1] != 0) {
            if(STD_RIGHT_ARROW[0] == errorMessage[i] && (STD_RIGHT_ARROW[1] == errorMessage[i+1] || STD_RIGHT_SHORT_ARROW[1] == errorMessage[i+1])) {
              temporaryInformation = TI_CONV_MENU_STR;
              errorMessage[i++] = 0;
              errorMessage[i++] = 0;
              break;
            }
            i++;
          }
          int16_t j = 0;
          errorMessage[j] = 0;
          while(errorMessage[i] != 0) {
            errorMessage[j++] =  errorMessage[i++];
          }
          errorMessage[j] = 0;
          expandConversionName(errorMessage);
          break;
        }
        default:break;
      }
    }


    if(lastErrorCode != 0) {
      if(getSystemFlag(FLAG_IGN1ER)) {
        if(thereIsSomethingToUndo) {
          undo();
        }
        lastErrorCode = ERROR_NONE;
      }
      else {
        if(thereIsSomethingToUndo) {
          undo();
        }
      }
      clearSystemFlag(FLAG_IGN1ER);
    }
    else {
      if((indexOfItems[func].status & SLS_STATUS) == SLS_DISABLED) {
        clearSystemFlag(FLAG_ASLIFT);
      }
      else if((indexOfItems[func].status & SLS_STATUS) == SLS_ENABLED) {
        setSystemFlag(FLAG_ASLIFT);
      }
    }

    if(programRunStop != PGM_RUNNING) {
      updateMatrixHeightCache();
      cachedDynamicMenu = 0;
      #if defined(PC_BUILD)
        refreshLcd(NULL);
      #endif // PC_BUILD
    }
  }



  void runFunction(int16_t func) {
    funcOK = true;
    #if defined(RECORDLOG)                              //JMEXEC
      #if defined(PC_BUILD)
        capture_sequence("runFunction:", func);        //JMEXEC
      #endif // PC_BUILD
    #endif // RECORDLOG                                        //JMEXEC

    #if defined(PC_BUILD)
      if(func >= LAST_ITEM) {
        sprintf(errorMessage, "item (%" PRId16 ") must be below LAST_ITEM", func);
        moreInfoOnError("In function runFunction:", errorMessage, NULL, NULL);
      }
    #endif // PC_BUILD

    if(programRunStop != PGM_RUNNING) {
      if(func == ITM_RCL && dynamicMenuItem > -1) {
        char *varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
        calcRegister_t regist = findNamedVariable(varCatalogItem);
        if(regist != INVALID_VARIABLE) {
          reallyRunFunction(func, regist);
        }
        else {
          displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "string '%s' is not a named variable", varCatalogItem);
            moreInfoOnError("In function runFunction:", errorMessage, NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
        return;
      }
      else if(func == ITM_XEQ && dynamicMenuItem > -1) {
        char *varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
        calcRegister_t regist = findNamedLabel(varCatalogItem);
        if(regist != INVALID_VARIABLE) {
          reallyRunFunction(func, regist);
        }
        else {
          displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
          #if(EXTRA_INFO_ON_CALC_ERROR == 1)
            sprintf(errorMessage, "string '%s' is not a named label", varCatalogItem);
            moreInfoOnError("In function runFunction:", errorMessage, NULL, NULL);
          #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        }
        return;
      }
      else if(tam.mode == 0 && TM_VALUE <= indexOfItems[func].param && indexOfItems[func].param <= TM_CMP && (calcMode != CM_PEM || aimBuffer[0] == 0 || nimNumberPart != NP_INT_BASE)) {
        #if defined(VERBOSEKEYS)
          printf("itmes.c: runfunction (before tamEnterMode): %i, %s\n", softmenu[softmenuStack[0].softmenuId].menuItem, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName);
        #endif // VERBOSEKEYS
        tamEnterMode(func);
        #if defined(VERBOSEKEYS)
          printf("itmes.c: runfunction (after tamEnterMode): %i, %s\n", softmenu[softmenuStack[0].softmenuId].menuItem, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName);
        #endif // VERBOSEKEYS
        return;
      }

      // if(calcMode == CM_PEM && !tam.mode && !isFunctionItemAMenu(func)) {
      if(calcMode == CM_PEM && !tam.mode && !isFunctionItemAMenu(func) && (!(catalog && catalog != CATALOG_MVAR && !fnKeyInCatalog) || func == ITM_EXIT1)) {
        addStepInProgram(func);
        return;
      }
    }

    #if defined(PC_BUILD)
      char tmp[200]; sprintf(tmp,"^^^^RunFunction func=%d\n",func); jm_show_comment(tmp);
    #endif // PC_BUILD

    reallyRunFunction(func, indexOfItems[func].param);

    if(!funcOK) {
      displayCalcErrorMessage(ERROR_ITEM_TO_BE_CODED, ERR_REGISTER_LINE, REGISTER_X);
      #if defined(PC_BUILD)
        sprintf(errorMessage, "%" PRId16 " = %s", func, indexOfItems[func].itemCatalogName);
        moreInfoOnError("In function runFunction:", "Item not implemented", errorMessage, "to be coded");
      #endif // PC_BUILD
    }
  }
#endif // !TESTSUITE_BUILD && !GENERATE_CATALOGS

#if defined(GENERATE_CATALOGS)
  void fnAsnViewer                 (uint16_t unusedButMandatoryParameter) {}
  void registerBrowser             (uint16_t unusedButMandatoryParameter) {}
  void flagBrowser                 (uint16_t unusedButMandatoryParameter) {}
  void fontBrowser                 (uint16_t unusedButMandatoryParameter) {}
  void fnPow10                     (uint16_t unusedButMandatoryParameter) {}
  void fnIntegerMode               (uint16_t unusedButMandatoryParameter) {}
  void fnConstant                  (uint16_t unusedButMandatoryParameter) {}
  void fnInvert                    (uint16_t unusedButMandatoryParameter) {}
  void fn2Pow                      (uint16_t unusedButMandatoryParameter) {}
  void fn10Pow                     (uint16_t unusedButMandatoryParameter) {}
  void fnCubeRoot                  (uint16_t unusedButMandatoryParameter) {}
  void fnMagnitude                 (uint16_t unusedButMandatoryParameter) {}
  void fnAgm                       (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatAll          (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatFix          (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatSci          (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatEng          (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatDsp          (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatTime         (uint16_t unusedButMandatoryParameter) {}
  void fnArccos                    (uint16_t unusedButMandatoryParameter) {}
  void fnArccosh                   (uint16_t unusedButMandatoryParameter) {}
  void fnArcsin                    (uint16_t unusedButMandatoryParameter) {}
  void fnArcsinh                   (uint16_t unusedButMandatoryParameter) {}
  void fnArctan                    (uint16_t unusedButMandatoryParameter) {}
  void fnArctanh                   (uint16_t unusedButMandatoryParameter) {}
  void fnAtan2                     (uint16_t unusedButMandatoryParameter) {}
  void fnCos                       (uint16_t unusedButMandatoryParameter) {}
  void fnCosh                      (uint16_t unusedButMandatoryParameter) {}
  void fnSin                       (uint16_t unusedButMandatoryParameter) {}
  void fnSinc                      (uint16_t unusedButMandatoryParameter) {}
  void fnSincpi                    (uint16_t unusedButMandatoryParameter) {}
  void fnSinh                      (uint16_t unusedButMandatoryParameter) {}
  void fnTan                       (uint16_t unusedButMandatoryParameter) {}
  void fnTanh                      (uint16_t unusedButMandatoryParameter) {}
  void fnDrop                      (uint16_t unusedButMandatoryParameter) {}
  void fnDropY                     (uint16_t unusedButMandatoryParameter) {}
  void fnBatteryVoltage            (uint16_t unusedButMandatoryParameter) {}
  void fnCurveFitting              (uint16_t unusedButMandatoryParameter) {}
  void fnCeil                      (uint16_t unusedButMandatoryParameter) {}
  void fnFloor                     (uint16_t unusedButMandatoryParameter) {}
  void fnClearFlag                 (uint16_t unusedButMandatoryParameter) {}
  void fnFlipFlag                  (uint16_t unusedButMandatoryParameter) {}
  void fnSetFlag                   (uint16_t unusedButMandatoryParameter) {}
  void fnClAll                     (uint16_t unusedButMandatoryParameter) {}
  void fnClX                       (uint16_t unusedButMandatoryParameter) {}
  void fnClFAll                    (uint16_t unusedButMandatoryParameter) {}
  void fnClPAll                    (uint16_t unusedButMandatoryParameter) {}
  void fnClSigma                   (uint16_t unusedButMandatoryParameter) {}
  void fnClearStack                (uint16_t unusedButMandatoryParameter) {}
  void fnClearRegisters            (uint16_t unusedButMandatoryParameter) {}
  void fnTimeFormat                (uint16_t unusedButMandatoryParameter) {}
  void fnSetDateFormat             (uint16_t unusedButMandatoryParameter) {}
  void fnComplexUnit               (uint16_t unusedButMandatoryParameter) {}
  void fnComplexMode               (uint16_t unusedButMandatoryParameter) {}
  void fnComplexResult             (uint16_t unusedButMandatoryParameter) {}
  void fnConjugate                 (uint16_t unusedButMandatoryParameter) {}
  void fnAngularMode               (uint16_t unusedButMandatoryParameter) {}
  void fnDenMode                   (uint16_t unusedButMandatoryParameter) {}
  void fnDenMax                    (uint16_t unusedButMandatoryParameter) {}
  void fnErf                       (uint16_t unusedButMandatoryParameter) {}
  void fnErfc                      (uint16_t unusedButMandatoryParameter) {}
  void fnExp                       (uint16_t unusedButMandatoryParameter) {}
  void fnExpM1                     (uint16_t unusedButMandatoryParameter) {}
  void fnExpt                      (uint16_t unusedButMandatoryParameter) {}
  void fnMant                      (uint16_t unusedButMandatoryParameter) {}
  void fnCxToRe                    (uint16_t unusedButMandatoryParameter) {}
  void fnReToCx                    (uint16_t unusedButMandatoryParameter) {}
  void fnFillStack                 (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagClear               (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagClearClear          (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagClearFlip           (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagClearSet            (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagSet                 (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagSetClear            (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagSetFlip             (uint16_t unusedButMandatoryParameter) {}
  void fnIsFlagSetSet              (uint16_t unusedButMandatoryParameter) {}
  void fnKeyEnter                  (uint16_t unusedButMandatoryParameter) {}
  void fnKeyExit                   (uint16_t unusedButMandatoryParameter) {}
  void fnKeyUp                     (uint16_t unusedButMandatoryParameter) {}
  void fnKeyDown                   (uint16_t unusedButMandatoryParameter) {}
  void fnKeyDotD                   (uint16_t unusedButMandatoryParameter) {}
  void fnKeyCC                     (uint16_t unusedButMandatoryParameter) {}
  void fnKeyBackspace              (uint16_t unusedButMandatoryParameter) {}
  void fnKeyAngle                  (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayStack              (uint16_t unusedButMandatoryParameter) {}
  void fnFreeFlashMemory           (uint16_t unusedButMandatoryParameter) {}
  void fnFreeMemory                (uint16_t unusedButMandatoryParameter) {}
  void fnFp                        (uint16_t unusedButMandatoryParameter) {}
  void fnIp                        (uint16_t unusedButMandatoryParameter) {}
  void allocateLocalRegisters      (uint16_t unusedButMandatoryParameter) {}
  void fnLeadingZeros              (uint16_t unusedButMandatoryParameter) {}
  void fnNeighb                    (uint16_t unusedButMandatoryParameter) {}
  void fnGcd                       (uint16_t unusedButMandatoryParameter) {}
  void fnMin                       (uint16_t unusedButMandatoryParameter) {}
  void fnMax                       (uint16_t unusedButMandatoryParameter) {}
  void fnStatSum                   (uint16_t unusedButMandatoryParameter) {}
  void fnIsPrime                   (uint16_t unusedButMandatoryParameter) {}
  void fnIsLeap                    (uint16_t unusedButMandatoryParameter) {}
  void fnIsString                  (uint16_t unusedButMandatoryParameter) {}
  void fnCheckValue                (uint16_t unusedButMandatoryParameter) {}
  void fnRandom                    (uint16_t unusedButMandatoryParameter) {}
  void fnRandomI                   (uint16_t unusedButMandatoryParameter) {}
  void fnImaginaryPart             (uint16_t unusedButMandatoryParameter) {}
  void fnRecall                    (uint16_t unusedButMandatoryParameter) {}
  void fnRecallConfig              (uint16_t unusedButMandatoryParameter) {}
  void fnRecallElement             (uint16_t unusedButMandatoryParameter) {}
  void fnRecallIJ                  (uint16_t unusedButMandatoryParameter) {}
  void fnRecallStack               (uint16_t unusedButMandatoryParameter) {}
  void fnRecallAdd                 (uint16_t unusedButMandatoryParameter) {}
  void fnRecallSub                 (uint16_t unusedButMandatoryParameter) {}
  void fnRecallMult                (uint16_t unusedButMandatoryParameter) {}
  void fnRecallDiv                 (uint16_t unusedButMandatoryParameter) {}
  void fnRecallMin                 (uint16_t unusedButMandatoryParameter) {}
  void fnRecallMax                 (uint16_t unusedButMandatoryParameter) {}
  void fnRadixMark                 (uint16_t unusedButMandatoryParameter) {}
  void fnReset                     (uint16_t unusedButMandatoryParameter) {}
  void fnRealPart                  (uint16_t unusedButMandatoryParameter) {}
  void fnRmd                       (uint16_t unusedButMandatoryParameter) {}
  void fnRound                     (uint16_t unusedButMandatoryParameter) {}
  void fnRoundi                    (uint16_t unusedButMandatoryParameter) {}
  void fnRsd                       (uint16_t unusedButMandatoryParameter) {}
  void fnRdp                       (uint16_t unusedButMandatoryParameter) {}
  void fnRollDown                  (uint16_t unusedButMandatoryParameter) {}
  void fnRollUp                    (uint16_t unusedButMandatoryParameter) {}
  void fnSeed                      (uint16_t unusedButMandatoryParameter) {}
  void fnSetDate                   (uint16_t unusedButMandatoryParameter) {}
  void fnSetTime                   (uint16_t unusedButMandatoryParameter) {}
  void configCommon                (uint16_t unusedButMandatoryParameter) {}
  void fnLcm                       (uint16_t unusedButMandatoryParameter) {}
  void fnSign                      (uint16_t unusedButMandatoryParameter) {}
  void fnSlvq                      (uint16_t unusedButMandatoryParameter) {}
  void fnGetIntegerSignMode        (uint16_t unusedButMandatoryParameter) {}
  void fnLog2                      (uint16_t unusedButMandatoryParameter) {}
  void fnLog10                     (uint16_t unusedButMandatoryParameter) {}
  void fnLn                        (uint16_t unusedButMandatoryParameter) {}
  void fnLogXY                     (uint16_t unusedButMandatoryParameter) {}
  void fnLnP1                      (uint16_t unusedButMandatoryParameter) {}
  void fnLnGamma                   (uint16_t unusedButMandatoryParameter) {}
  void fnLnBeta                    (uint16_t unusedButMandatoryParameter) {}
  void fnBeta                      (uint16_t unusedButMandatoryParameter) {}
  void fnIxyz                      (uint16_t unusedButMandatoryParameter) {}
  void fnGamma                     (uint16_t unusedButMandatoryParameter) {}
  void fnGammaP                    (uint16_t unusedButMandatoryParameter) {}
  void fnGammaQ                    (uint16_t unusedButMandatoryParameter) {}
  void fnGammaXyLower              (uint16_t unusedButMandatoryParameter) {}
  void fnGammaXyUpper              (uint16_t unusedButMandatoryParameter) {}
  void fnBesselJ                   (uint16_t unusedButMandatoryParameter) {}
  void fnBesselY                   (uint16_t unusedButMandatoryParameter) {}
  void fnZeta                      (uint16_t unusedButMandatoryParameter) {}
  void fnBn                        (uint16_t unusedButMandatoryParameter) {}
  void fnBnStar                    (uint16_t unusedButMandatoryParameter) {}
  void fnWnegative                 (uint16_t unusedButMandatoryParameter) {}
  void fnWpositive                 (uint16_t unusedButMandatoryParameter) {}
  void fnWinverse                  (uint16_t unusedButMandatoryParameter) {}
  void fnHermite                   (uint16_t unusedButMandatoryParameter) {}
  void fnHermiteP                  (uint16_t unusedButMandatoryParameter) {}
  void fnLaguerre                  (uint16_t unusedButMandatoryParameter) {}
  void fnLaguerreAlpha             (uint16_t unusedButMandatoryParameter) {}
  void fnLegendre                  (uint16_t unusedButMandatoryParameter) {}
  void fnChebyshevT                (uint16_t unusedButMandatoryParameter) {}
  void fnChebyshevU                (uint16_t unusedButMandatoryParameter) {}
  void fnIDiv                      (uint16_t unusedButMandatoryParameter) {}
  void fnIDivR                     (uint16_t unusedButMandatoryParameter) {}
  void fnMirror                    (uint16_t unusedButMandatoryParameter) {}
  void fnMod                       (uint16_t unusedButMandatoryParameter) {}
  void fnMulMod                    (uint16_t unusedButMandatoryParameter) {}
  void fnExpMod                    (uint16_t unusedButMandatoryParameter) {}
  void fnPower                     (uint16_t unusedButMandatoryParameter) {}
  void fnPi                        (uint16_t unusedButMandatoryParameter) {}
  void fnUserMode                  (uint16_t unusedButMandatoryParameter) {}
  void fnParallel                  (uint16_t unusedButMandatoryParameter) {}
  void fnSquareRoot                (uint16_t unusedButMandatoryParameter) {}
  void fnSubtract                  (uint16_t unusedButMandatoryParameter) {}
  void fnChangeSign                (uint16_t unusedButMandatoryParameter) {}
  void fnM1Pow                     (uint16_t unusedButMandatoryParameter) {}
  void backToSystem                (uint16_t unusedButMandatoryParameter) {}
  void runDMCPmenu                 (uint16_t unusedButMandatoryParameter) {}
  void fnMultiply                  (uint16_t unusedButMandatoryParameter) {}
  void fnDblDivide                 (uint16_t unusedButMandatoryParameter) {}
  void fnDblDivideRemainder        (uint16_t unusedButMandatoryParameter) {}
  void fnDblMultiply               (uint16_t unusedButMandatoryParameter) {}
  void fnChangeBase                (uint16_t unusedButMandatoryParameter) {}
  void fnToPolar                   (uint16_t unusedButMandatoryParameter) {}
  void fnToRect                    (uint16_t unusedButMandatoryParameter) {}
  void fnDivide                    (uint16_t unusedButMandatoryParameter) {}
  void fnAdd                       (uint16_t unusedButMandatoryParameter) {}
  void fnSigma                     (uint16_t unusedButMandatoryParameter) {}
  void fnXEqualsTo                 (uint16_t unusedButMandatoryParameter) {}
  void fnXNotEqual                 (uint16_t unusedButMandatoryParameter) {}
  void fnXAlmostEqual              (uint16_t unusedButMandatoryParameter) {}
  void fnXLessThan                 (uint16_t unusedButMandatoryParameter) {}
  void fnXLessEqual                (uint16_t unusedButMandatoryParameter) {}
  void fnXGreaterThan              (uint16_t unusedButMandatoryParameter) {}
  void fnXGreaterEqual             (uint16_t unusedButMandatoryParameter) {}
  void fnIsConverged               (uint16_t unusedButMandatoryParameter) {}
  void fnGetLocR                   (uint16_t unusedButMandatoryParameter) {}
  void fnSwapRealImaginary         (uint16_t unusedButMandatoryParameter) {}
  void fnSetRoundingMode           (uint16_t unusedButMandatoryParameter) {}
  void fnGetRoundingMode           (uint16_t unusedButMandatoryParameter) {}
  void fnSetWordSize               (uint16_t unusedButMandatoryParameter) {}
  void fnGetWordSize               (uint16_t unusedButMandatoryParameter) {}
  void fnGetStackSize              (uint16_t unusedButMandatoryParameter) {}
  void fnStackSize                 (uint16_t unusedButMandatoryParameter) {}
  void fnStore                     (uint16_t unusedButMandatoryParameter) {}
  void fnStoreConfig               (uint16_t unusedButMandatoryParameter) {}
  void fnStoreElement              (uint16_t unusedButMandatoryParameter) {}
  void fnStoreIJ                   (uint16_t unusedButMandatoryParameter) {}
  void fnStoreStack                (uint16_t unusedButMandatoryParameter) {}
  void fnStoreAdd                  (uint16_t unusedButMandatoryParameter) {}
  void fnStoreSub                  (uint16_t unusedButMandatoryParameter) {}
  void fnStoreMult                 (uint16_t unusedButMandatoryParameter) {}
  void fnStoreDiv                  (uint16_t unusedButMandatoryParameter) {}
  void fnStoreMax                  (uint16_t unusedButMandatoryParameter) {}
  void fnStoreMin                  (uint16_t unusedButMandatoryParameter) {}
  void fnUlp                       (uint16_t unusedButMandatoryParameter) {}
  void fnUnitVector                (uint16_t unusedButMandatoryParameter) {}
  void fnVersion                   (uint16_t unusedButMandatoryParameter) {}
  void fnSquare                    (uint16_t unusedButMandatoryParameter) {}
  void fnCube                      (uint16_t unusedButMandatoryParameter) {}
  void fnFactorial                 (uint16_t unusedButMandatoryParameter) {}
  void fnSwapX                     (uint16_t unusedButMandatoryParameter) {}
  void fnSwapY                     (uint16_t unusedButMandatoryParameter) {}
  void fnSwapZ                     (uint16_t unusedButMandatoryParameter) {}
  void fnSwapT                     (uint16_t unusedButMandatoryParameter) {}
  void fnSwapXY                    (uint16_t unusedButMandatoryParameter) {}
  void fnShuffle                   (uint16_t unusedButMandatoryParameter) {}
  void fnWho                       (uint16_t unusedButMandatoryParameter) {}
  void fnGetSignificantDigits      (uint16_t unusedButMandatoryParameter) {}
  void fnSetSignificantDigits      (uint16_t unusedButMandatoryParameter) {}
  void fnSdl                       (uint16_t unusedButMandatoryParameter) {}
  void fnSdr                       (uint16_t unusedButMandatoryParameter) {}
  void fnCvtToCurrentAngularMode   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtAcreHa                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtAcreusHa               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtAtmPa                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtAuM                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtBarPa                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtBtuJ                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtCalJ                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtCwtKg                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFtM                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtSfeetM                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFlozukMl               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFlozusMl               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtGalukL                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtGalusL                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtDbRatio                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtRatioDb                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtHpeW                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtHpmW                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtHpukW                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtInhgPa                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtMmhgPa                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtInchMm                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtWhJ                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtLbKg                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtOzG                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtStoneKg                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtShorttonKg             (uint16_t unusedButMandatoryParameter) {}
  void fnCvtTrozG                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtLbfN                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtMiKm                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtLyM                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtTonKg                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtTorrPa                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtYardM                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtPcM                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtPointMm                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtCToF                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFToC                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtNmiKm                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtNmiMi                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtPsiPa                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtShortcwtKg             (uint16_t unusedButMandatoryParameter) {}
  void fnCvtLbfftNm                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFromCurrentAngularMode (uint16_t unusedButMandatoryParameter) {}
  void fnCvtYearS                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtCaratG                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtJinKg                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtLiangKg                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtQuartL                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtDmsToCurrentAngularMode(uint16_t unusedButMandatoryParameter) {}
  void fnCvtFathomM                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtBarrelM3               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtHectareM2              (uint16_t unusedButMandatoryParameter) {}
  void fnCvtMuM2                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtLiM                    (uint16_t unusedButMandatoryParameter) {}
  void fnCvtChiM                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtYinM                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtCunM                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtZhangM                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFenM                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtMileM                  (uint16_t unusedButMandatoryParameter) {}
  void fnCvtNMiM                   (uint16_t unusedButMandatoryParameter) {}
  void fnCvtMi2Km2                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtNmi2Km2                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtKmphmps                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtRpmDegps               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtMphmps                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtRpmRadps               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtDegRad                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtDegGrad                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtGradRad                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFurtom                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFtntos                 (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFpftomps               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtBrdstom                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFirtokg                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFpftokph               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtBrdstoin               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFirtolb                (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFpftomph               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFpstokph               (uint16_t unusedButMandatoryParameter) {}
  void fnCvtFpstomps               (uint16_t unusedButMandatoryParameter) {}
  void addItemToBuffer             (uint16_t unusedButMandatoryParameter) {}
  void fnOff                       (uint16_t unusedButMandatoryParameter) {}
  void fnAim                       (uint16_t unusedButMandatoryParameter) {}
  void fnShow                      (uint16_t unusedButMandatoryParameter) {}
  void fnView                      (uint16_t unusedButMandatoryParameter) {}
  void fnLastX                     (uint16_t unusedButMandatoryParameter) {}
  void fnCyx                       (uint16_t unusedButMandatoryParameter) {}
  void fnPyx                       (uint16_t unusedButMandatoryParameter) {}
  void fnDateToJulian              (uint16_t unusedButMandatoryParameter) {}
  void fnToDate                    (uint16_t unusedButMandatoryParameter) {}
  void fnDateTo                    (uint16_t unusedButMandatoryParameter) {}
  void fnXToDate                   (uint16_t unusedButMandatoryParameter) {}
  void fnYear                      (uint16_t unusedButMandatoryParameter) {}
  void fnMonth                     (uint16_t unusedButMandatoryParameter) {}
  void fnDay                       (uint16_t unusedButMandatoryParameter) {}
  void fnWday                      (uint16_t unusedButMandatoryParameter) {}
  void fnToHr                      (uint16_t unusedButMandatoryParameter) {}
  void fnToHms                     (uint16_t unusedButMandatoryParameter) {}
  void fnToReal                    (uint16_t unusedButMandatoryParameter) {}
  void fnDec                       (uint16_t unusedButMandatoryParameter) {}
  void fnInc                       (uint16_t unusedButMandatoryParameter) {}
  void fnIse                       (uint16_t unusedButMandatoryParameter) {}
  void fnIsg                       (uint16_t unusedButMandatoryParameter) {}
  void fnIsz                       (uint16_t unusedButMandatoryParameter) {}
  void fnDse                       (uint16_t unusedButMandatoryParameter) {}
  void fnDsl                       (uint16_t unusedButMandatoryParameter) {}
  void fnDsz                       (uint16_t unusedButMandatoryParameter) {}
  void fncountBits                 (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalNot                (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalAnd                (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalNand               (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalOr                 (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalNor                (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalXor                (uint16_t unusedButMandatoryParameter) {}
  void fnLogicalXnor               (uint16_t unusedButMandatoryParameter) {}
  void fnDecomp                    (uint16_t unusedButMandatoryParameter) {}
  void fnPlotStat                  (uint16_t unusedButMandatoryParameter) {}
  void fnSumXY                     (uint16_t unusedButMandatoryParameter) {}
  void fnMeanXY                    (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricMeanXY           (uint16_t unusedButMandatoryParameter) {}
  void fnWeightedMeanX             (uint16_t unusedButMandatoryParameter) {}
  void fnHarmonicMeanXY            (uint16_t unusedButMandatoryParameter) {}
  void fnRMSMeanXY                 (uint16_t unusedButMandatoryParameter) {}
  void fnWeightedSampleStdDev      (uint16_t unusedButMandatoryParameter) {}
  void fnWeightedPopulationStdDev  (uint16_t unusedButMandatoryParameter) {}
  void fnWeightedStandardError     (uint16_t unusedButMandatoryParameter) {}
  void fnSampleStdDev              (uint16_t unusedButMandatoryParameter) {}
  void fnPopulationStdDev          (uint16_t unusedButMandatoryParameter) {}
  void fnStandardError             (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricSampleStdDev     (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricPopulationStdDev (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricStandardError    (uint16_t unusedButMandatoryParameter) {}
  void fnPopulationCovariance      (uint16_t unusedButMandatoryParameter) {}
  void fnSampleCovariance          (uint16_t unusedButMandatoryParameter) {}
  void fnCoefficientDetermination  (uint16_t unusedButMandatoryParameter) {}
  void fnMinExpStdDev              (uint16_t unusedButMandatoryParameter) {}
  void fnMedianXY                  (uint16_t unusedButMandatoryParameter) {}
  void fnLowerQuartileXY           (uint16_t unusedButMandatoryParameter) {}
  void fnUpperQuartileXY           (uint16_t unusedButMandatoryParameter) {}
  void fnMADXY                     (uint16_t unusedButMandatoryParameter) {}
  void fnIQRXY                     (uint16_t unusedButMandatoryParameter) {}
  void fnLINPOL                    (uint16_t unusedButMandatoryParameter) {}
  void fnPercentileXY              (uint16_t unusedButMandatoryParameter) {}
  void fnPlotCloseSmi              (uint16_t unusedButMandatoryParameter) {}
  void fnMaskl                     (uint16_t unusedButMandatoryParameter) {}
  void fnMaskr                     (uint16_t unusedButMandatoryParameter) {}
  void fnAsr                       (uint16_t unusedButMandatoryParameter) {}
  void fnCb                        (uint16_t unusedButMandatoryParameter) {}
  void fnSb                        (uint16_t unusedButMandatoryParameter) {}
  void fnFb                        (uint16_t unusedButMandatoryParameter) {}
  void fnBs                        (uint16_t unusedButMandatoryParameter) {}
  void fnBc                        (uint16_t unusedButMandatoryParameter) {}
  void fnSl                        (uint16_t unusedButMandatoryParameter) {}
  void fnRl                        (uint16_t unusedButMandatoryParameter) {}
  void fnRlc                       (uint16_t unusedButMandatoryParameter) {}
  void fnSr                        (uint16_t unusedButMandatoryParameter) {}
  void fnRr                        (uint16_t unusedButMandatoryParameter) {}
  void fnRrc                       (uint16_t unusedButMandatoryParameter) {}
  void fnLj                        (uint16_t unusedButMandatoryParameter) {}
  void fnRj                        (uint16_t unusedButMandatoryParameter) {}
  void fnCountBits                 (uint16_t unusedButMandatoryParameter) {}
  void fnNextPrime                 (uint16_t unusedButMandatoryParameter) {}
  void fnScreenDump                (uint16_t unusedButMandatoryParameter) {}
  void fnArg                       (uint16_t unusedButMandatoryParameter) {}
  void fnRange                     (uint16_t unusedButMandatoryParameter) {}
  void fnGetRange                  (uint16_t unusedButMandatoryParameter) {}
  void fnHide                      (uint16_t unusedButMandatoryParameter) {}
  void fnGetHide                   (uint16_t unusedButMandatoryParameter) {}
  void fnDot                       (uint16_t unusedButMandatoryParameter) {}
  void fnCross                     (uint16_t unusedButMandatoryParameter) {}
  void fnPercent                   (uint16_t unusedButMandatoryParameter) {}
  void fnPercentMRR                (uint16_t unusedButMandatoryParameter) {}
  void fnPercentT                  (uint16_t unusedButMandatoryParameter) {}
  void fnPercentSigma              (uint16_t unusedButMandatoryParameter) {}
  void fnPercentPlusMG             (uint16_t unusedButMandatoryParameter) {}
  void fnDeltaPercent              (uint16_t unusedButMandatoryParameter) {}
  void fnXthRoot                   (uint16_t unusedButMandatoryParameter) {}
  void fnGetSystemFlag             (uint16_t unusedButMandatoryParameter) {}
  void fnFractionType              (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaLeng                 (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaSR                   (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaSL                   (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaRR                   (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaRL                   (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaPos                  (uint16_t unusedButMandatoryParameter) {}
  void fnXToAlpha                  (uint16_t unusedButMandatoryParameter) {}
  void fnAlphaToX                  (uint16_t unusedButMandatoryParameter) {}
  void fnTicks                     (uint16_t unusedButMandatoryParameter) {}
  void fnSetFirstGregorianDay      (uint16_t unusedButMandatoryParameter) {}
  void fnGetFirstGregorianDay      (uint16_t unusedButMandatoryParameter) {}
  void fnDate                      (uint16_t unusedButMandatoryParameter) {}
  void fnTime                      (uint16_t unusedButMandatoryParameter) {}
  void fnTone                      (uint16_t unusedButMandatoryParameter) {}
  void fnBeep                      (uint16_t unusedButMandatoryParameter) {}
  void fnSave                      (uint16_t unusedButMandatoryParameter) {}
  void fnLoad                      (uint16_t unusedButMandatoryParameter) {}
  void fnSaveProgram               (uint16_t unusedButMandatoryParameter) {}
  void fnExportProgram             (uint16_t unusedButMandatoryParameter) {}
  void fnLoadProgram               (uint16_t unusedButMandatoryParameter) {}
  void fnDeleteBackup              (uint16_t unusedButMandatoryParameter) {}
  void fnUndo                      (uint16_t unusedButMandatoryParameter) {}
  void fnXmax                      (uint16_t unusedButMandatoryParameter) {}
  void fnXmin                      (uint16_t unusedButMandatoryParameter) {}
  void fnRangeXY                   (uint16_t unusedButMandatoryParameter) {}
  void fnFib                       (uint16_t unusedButMandatoryParameter) {}
  void fnGd                        (uint16_t unusedButMandatoryParameter) {}
  void fnInvGd                     (uint16_t unusedButMandatoryParameter) {}
  void fnClP                       (uint16_t unusedButMandatoryParameter) {}
  void fnPem                       (uint16_t unusedButMandatoryParameter) {}
  void fnGoto                      (uint16_t unusedButMandatoryParameter) {}
  void fnGotoDot                   (uint16_t unusedButMandatoryParameter) {}
  void fnExecute                   (uint16_t unusedButMandatoryParameter) {}
  void fnReturn                    (uint16_t unusedButMandatoryParameter) {}
  void fnRunProgram                (uint16_t unusedButMandatoryParameter) {}
  void fnStopProgram               (uint16_t unusedButMandatoryParameter) {}
  void fnBst                       (uint16_t unusedButMandatoryParameter) {}
  void fnSst                       (uint16_t unusedButMandatoryParameter) {}
  void fnBack                      (uint16_t unusedButMandatoryParameter) {}
  void fnSkip                      (uint16_t unusedButMandatoryParameter) {}
  void fnCase                      (uint16_t unusedButMandatoryParameter) {}
  void fnCheckLabel                (uint16_t unusedButMandatoryParameter) {}
  void fnIsTopRoutine              (uint16_t unusedButMandatoryParameter) {}
  void fnRaiseError                (uint16_t unusedButMandatoryParameter) {}
  void fnErrorMessage              (uint16_t unusedButMandatoryParameter) {}
  void fnRegClr                    (uint16_t unusedButMandatoryParameter) {}
  void fnRegCopy                   (uint16_t unusedButMandatoryParameter) {}
  void fnRegSort                   (uint16_t unusedButMandatoryParameter) {}
  void fnRegSwap                   (uint16_t unusedButMandatoryParameter) {}
  void fnInput                     (uint16_t unusedButMandatoryParameter) {}
  void fnClCVar                    (uint16_t unusedButMandatoryParameter) {}
  void fnVarMnu                    (uint16_t unusedButMandatoryParameter) {}
  void fnDynamicMenu               (uint16_t unusedButMandatoryParameter) {}
  void fnPause                     (uint16_t unusedButMandatoryParameter) {}
  void fnKey                       (uint16_t unusedButMandatoryParameter) {}
  void fnKeyType                   (uint16_t unusedButMandatoryParameter) {}
  void fnPutKey                    (uint16_t unusedButMandatoryParameter) {}
  void fnKeyGtoXeq                 (uint16_t unusedButMandatoryParameter) {}
  void fnKeyGto                    (uint16_t unusedButMandatoryParameter) {}
  void fnKeyXeq                    (uint16_t unusedButMandatoryParameter) {}
  void fnProgrammableMenu          (uint16_t unusedButMandatoryParameter) {}
  void fnClearMenu                 (uint16_t unusedButMandatoryParameter) {}
  void fnExitAllMenus              (uint16_t unusedButMandatoryParameter) {}
  void fnEntryQ                    (uint16_t unusedButMandatoryParameter) {}
  void fnCheckInteger              (uint16_t unusedButMandatoryParameter) {}
  void fnNormalP                   (uint16_t unusedButMandatoryParameter) {}
  void fnNormalL                   (uint16_t unusedButMandatoryParameter) {}
  void fnNormalR                   (uint16_t unusedButMandatoryParameter) {}
  void fnNormalI                   (uint16_t unusedButMandatoryParameter) {}
  void fnT_P                       (uint16_t unusedButMandatoryParameter) {}
  void fnT_L                       (uint16_t unusedButMandatoryParameter) {}
  void fnT_R                       (uint16_t unusedButMandatoryParameter) {}
  void fnT_I                       (uint16_t unusedButMandatoryParameter) {}
  void fnChi2P                     (uint16_t unusedButMandatoryParameter) {}
  void fnChi2L                     (uint16_t unusedButMandatoryParameter) {}
  void fnChi2R                     (uint16_t unusedButMandatoryParameter) {}
  void fnChi2I                     (uint16_t unusedButMandatoryParameter) {}
  void fnStdNormalP                (uint16_t unusedButMandatoryParameter) {}
  void fnStdNormalL                (uint16_t unusedButMandatoryParameter) {}
  void fnStdNormalR                (uint16_t unusedButMandatoryParameter) {}
  void fnStdNormalI                (uint16_t unusedButMandatoryParameter) {}
  void fnF_P                       (uint16_t unusedButMandatoryParameter) {}
  void fnF_L                       (uint16_t unusedButMandatoryParameter) {}
  void fnF_R                       (uint16_t unusedButMandatoryParameter) {}
  void fnF_I                       (uint16_t unusedButMandatoryParameter) {}
  void fnProcessLR                 (uint16_t unusedButMandatoryParameter) {}
  void fnPlotZoom                  (uint16_t unusedButMandatoryParameter) {}
  void fnYIsFnx                    (uint16_t unusedButMandatoryParameter) {}
  void fnXIsFny                    (uint16_t unusedButMandatoryParameter) {}
  void fnStatSa                    (uint16_t unusedButMandatoryParameter) {}
  void fnCurveFittingLR            (uint16_t unusedButMandatoryParameter) {}
  void fnLogNormalP                (uint16_t unusedButMandatoryParameter) {}
  void fnLogNormalL                (uint16_t unusedButMandatoryParameter) {}
  void fnLogNormalR                (uint16_t unusedButMandatoryParameter) {}
  void fnLogNormalI                (uint16_t unusedButMandatoryParameter) {}
  void fnCauchyP                   (uint16_t unusedButMandatoryParameter) {}
  void fnCauchyL                   (uint16_t unusedButMandatoryParameter) {}
  void fnCauchyR                   (uint16_t unusedButMandatoryParameter) {}
  void fnCauchyI                   (uint16_t unusedButMandatoryParameter) {}
  void fnExponentialP              (uint16_t unusedButMandatoryParameter) {}
  void fnExponentialL              (uint16_t unusedButMandatoryParameter) {}
  void fnExponentialR              (uint16_t unusedButMandatoryParameter) {}
  void fnExponentialI              (uint16_t unusedButMandatoryParameter) {}
  void fnLogisticP                 (uint16_t unusedButMandatoryParameter) {}
  void fnLogisticL                 (uint16_t unusedButMandatoryParameter) {}
  void fnLogisticR                 (uint16_t unusedButMandatoryParameter) {}
  void fnLogisticI                 (uint16_t unusedButMandatoryParameter) {}
  void fnWeibullP                  (uint16_t unusedButMandatoryParameter) {}
  void fnWeibullL                  (uint16_t unusedButMandatoryParameter) {}
  void fnWeibullR                  (uint16_t unusedButMandatoryParameter) {}
  void fnWeibullI                  (uint16_t unusedButMandatoryParameter) {}
  void fnNegBinomialP              (uint16_t unusedButMandatoryParameter) {}
  void fnNegBinomialL              (uint16_t unusedButMandatoryParameter) {}
  void fnNegBinomialR              (uint16_t unusedButMandatoryParameter) {}
  void fnNegBinomialI              (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricP                (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricL                (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricR                (uint16_t unusedButMandatoryParameter) {}
  void fnGeometricI                (uint16_t unusedButMandatoryParameter) {}
  void fnHypergeometricP           (uint16_t unusedButMandatoryParameter) {}
  void fnHypergeometricL           (uint16_t unusedButMandatoryParameter) {}
  void fnHypergeometricR           (uint16_t unusedButMandatoryParameter) {}
  void fnHypergeometricI           (uint16_t unusedButMandatoryParameter) {}
  void fnBinomialP                 (uint16_t unusedButMandatoryParameter) {}
  void fnBinomialL                 (uint16_t unusedButMandatoryParameter) {}
  void fnBinomialR                 (uint16_t unusedButMandatoryParameter) {}
  void fnBinomialI                 (uint16_t unusedButMandatoryParameter) {}
  void fnPoissonP                  (uint16_t unusedButMandatoryParameter) {}
  void fnPoissonL                  (uint16_t unusedButMandatoryParameter) {}
  void fnPoissonR                  (uint16_t unusedButMandatoryParameter) {}
  void fnPoissonI                  (uint16_t unusedButMandatoryParameter) {}
  void fnNewMatrix                 (uint16_t unusedButMandatoryParameter) {}
  void fnEditMatrix                (uint16_t unusedButMandatoryParameter) {}
  void fnOldMatrix                 (uint16_t unusedButMandatoryParameter) {}
  void fnGoToElement               (uint16_t unusedButMandatoryParameter) {}
  void fnGoToRow                   (uint16_t unusedButMandatoryParameter) {}
  void fnGoToColumn                (uint16_t unusedButMandatoryParameter) {}
  void fnSetGrowMode               (uint16_t unusedButMandatoryParameter) {}
  void fnIncDecI                   (uint16_t unusedButMandatoryParameter) {}
  void fnIncDecJ                   (uint16_t unusedButMandatoryParameter) {}
  void fnInsRow                    (uint16_t unusedButMandatoryParameter) {}
  void fnDelRow                    (uint16_t unusedButMandatoryParameter) {}
  void fnSetMatrixDimensions       (uint16_t unusedButMandatoryParameter) {}
  void fnGetMatrixDimensions       (uint16_t unusedButMandatoryParameter) {}
  void fnTranspose                 (uint16_t unusedButMandatoryParameter) {}
  void fnLuDecomposition           (uint16_t unusedButMandatoryParameter) {}
  void fnDeterminant               (uint16_t unusedButMandatoryParameter) {}
  void fnInvertMatrix              (uint16_t unusedButMandatoryParameter) {}
  void fnEuclideanNorm             (uint16_t unusedButMandatoryParameter) {}
  void fnRowSum                    (uint16_t unusedButMandatoryParameter) {}
  void fnRowNorm                   (uint16_t unusedButMandatoryParameter) {}
  void fnVectorAngle               (uint16_t unusedButMandatoryParameter) {}
  void fnIndexMatrix               (uint16_t unusedButMandatoryParameter) {}
  void fnGetMatrix                 (uint16_t unusedButMandatoryParameter) {}
  void fnPutMatrix                 (uint16_t unusedButMandatoryParameter) {}
  void fnSwapRows                  (uint16_t unusedButMandatoryParameter) {}
  void fnSimultaneousLinearEquation(uint16_t unusedButMandatoryParameter) {}
  void fnEditLinearEquationMatrixA (uint16_t unusedButMandatoryParameter) {}
  void fnEditLinearEquationMatrixB (uint16_t unusedButMandatoryParameter) {}
  void fnEditLinearEquationMatrixX (uint16_t unusedButMandatoryParameter) {}
  void fnQrDecomposition           (uint16_t unusedButMandatoryParameter) {}
  void fnEigenvalues               (uint16_t unusedButMandatoryParameter) {}
  void fnEigenvectors              (uint16_t unusedButMandatoryParameter) {}
  void fnJacobiSn                  (uint16_t unusedButMandatoryParameter) {}
  void fnJacobiCn                  (uint16_t unusedButMandatoryParameter) {}
  void fnJacobiDn                  (uint16_t unusedButMandatoryParameter) {}
  void fnJacobiAmplitude           (uint16_t unusedButMandatoryParameter) {}
  void fnEllipticK                 (uint16_t unusedButMandatoryParameter) {}
  void fnEllipticE                 (uint16_t unusedButMandatoryParameter) {}
  void fnEllipticPi                (uint16_t unusedButMandatoryParameter) {}
  void fnEllipticFphi              (uint16_t unusedButMandatoryParameter) {}
  void fnEllipticEphi              (uint16_t unusedButMandatoryParameter) {}
  void fnJacobiZeta                (uint16_t unusedButMandatoryParameter) {}
  void fnPgmSlv                    (uint16_t unusedButMandatoryParameter) {}
  void fnSolve                     (uint16_t unusedButMandatoryParameter) {}
  void fnSolveVar                  (uint16_t unusedButMandatoryParameter) {}
  void fnPgmInt                    (uint16_t unusedButMandatoryParameter) {}
  void fnIntegrate                 (uint16_t unusedButMandatoryParameter) {}
  void fnIntVar                    (uint16_t unusedButMandatoryParameter) {}
  void fn1stDeriv                  (uint16_t unusedButMandatoryParameter) {}
  void fn2ndDeriv                  (uint16_t unusedButMandatoryParameter) {}
  void fn1stDerivEq                (uint16_t unusedButMandatoryParameter) {}
  void fn2ndDerivEq                (uint16_t unusedButMandatoryParameter) {}
  void fnEqDelete                  (uint16_t unusedButMandatoryParameter) {}
  void fnEqEdit                    (uint16_t unusedButMandatoryParameter) {}
  void fnEqNew                     (uint16_t unusedButMandatoryParameter) {}
  void fnEqCursorLeft              (uint16_t unusedButMandatoryParameter) {}
  void fnEqCursorRight             (uint16_t unusedButMandatoryParameter) {}
  void fnEqCalc                    (uint16_t unusedButMandatoryParameter) {}
  void fnProgrammableSum           (uint16_t unusedButMandatoryParameter) {}
  void fnProgrammableProduct       (uint16_t unusedButMandatoryParameter) {}
  void fnProgrammableiSum          (uint16_t unusedButMandatoryParameter) {}
  void fnProgrammableiProduct      (uint16_t unusedButMandatoryParameter) {}
  void fnTvmVar                    (uint16_t unusedButMandatoryParameter) {}
  void fnTvmBeginMode              (uint16_t unusedButMandatoryParameter) {}
  void fnTvmEndMode                (uint16_t unusedButMandatoryParameter) {}
  void fnAssign                    (uint16_t unusedButMandatoryParameter) {}
  void fnItemTimerApp              (uint16_t unusedButMandatoryParameter) {}
  void fnAddTimerApp               (uint16_t unusedButMandatoryParameter) {}
  void fnDecisecondTimerApp        (uint16_t unusedButMandatoryParameter) {}
  void fnResetTimerApp             (uint16_t unusedButMandatoryParameter) {}
  void fnRecallTimerApp            (uint16_t unusedButMandatoryParameter) {}
  void fnEqSolvGraph               (uint16_t unusedButMandatoryParameter) {}
  void graph_eqn                   (uint16_t unusedButMandatoryParameter) {}
  void fnClLcd                     (uint16_t unusedButMandatoryParameter) {}
  void fnPixel                     (uint16_t unusedButMandatoryParameter) {}
  void fnPoint                     (uint16_t unusedButMandatoryParameter) {}
  void fnAGraph                    (uint16_t unusedButMandatoryParameter) {}
  void fnSetLoBin                  (uint16_t unusedButMandatoryParameter) {}
  void fnSetHiBin                  (uint16_t unusedButMandatoryParameter) {}
  void fnSetNBins                  (uint16_t unusedButMandatoryParameter) {}
  void fnConvertStatsToHisto       (uint16_t unusedButMandatoryParameter) {}
  void fnSqrt1Px2                  (uint16_t unusedButMandatoryParameter) {}
  void fnDeleteVariable            (uint16_t unusedButMandatoryParameter) {}
  void fnDeleteMenu                (uint16_t unusedButMandatoryParameter) {}
  void activateUSBdisk             (uint16_t unusedButMandatoryParameter) {}

  void fnJM                       (uint16_t unusedButMandatoryParameter) {}           //vv JM
  void SetSetting                 (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatSigFig      (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatUnit        (uint16_t unusedButMandatoryParameter) {}
  void fnDisplayFormatCycle       (uint16_t unusedButMandatoryParameter) {}
  void fnShowJM                   (uint16_t unusedButMandatoryParameter) {}
  void fnKeysManagement           (uint16_t unusedButMandatoryParameter) {}
  void fnSigmaAssign              (uint16_t unusedButMandatoryParameter) {}
  void fnGetSigmaAssignToX        (uint16_t unusedButMandatoryParameter) {}
  void fnJM_GetXToNORMmode        (uint16_t unusedButMandatoryParameter) {}
  void fnInDefault                (uint16_t unusedButMandatoryParameter) {}
  void fnJM_2SI                   (uint16_t unusedButMandatoryParameter) {}
  void fnTo_ms                    (uint16_t unusedButMandatoryParameter) {}
  void fnFrom_ms                  (uint16_t unusedButMandatoryParameter) {}
  void fnShow_SCROLL              (uint16_t unusedButMandatoryParameter) {}
  void fnP_All_Regs               (uint16_t unusedButMandatoryParameter) {}
  void fnP_Regs                   (uint16_t unusedButMandatoryParameter) {}
  void fnToPolar2                 (uint16_t unusedButMandatoryParameter) {}
  void fnToRect2                  (uint16_t unusedButMandatoryParameter) {}
  void fnArg_all                  (uint16_t unusedButMandatoryParameter) {}
  void fnMultiplySI               (uint16_t unusedButMandatoryParameter) {}
  void fn_cnst_op_j               (uint16_t unusedButMandatoryParameter) {}
  void fn_cnst_op_j_pol           (uint16_t unusedButMandatoryParameter) {}
  void fn_cnst_op_aa              (uint16_t unusedButMandatoryParameter) {}
  void fn_cnst_op_a               (uint16_t unusedButMandatoryParameter) {}
  void fn_cnst_0_cpx              (uint16_t unusedButMandatoryParameter) {}
  void fn_cnst_1_cpx              (uint16_t unusedButMandatoryParameter) {}
  void fnListXY                   (uint16_t unusedButMandatoryParameter) {}
  void fnXEQMENU                  (uint16_t unusedButMandatoryParameter) {}
  void flagBrowser_old            (uint16_t unusedButMandatoryParameter) {}
  void fnRound2                   (uint16_t unusedButMandatoryParameter) {}
  void fnRoundi2                  (uint16_t unusedButMandatoryParameter) {}
  void fnSetInlineTest            (uint16_t unusedButMandatoryParameter) {}           //vv dr
  void fnSetInlineTestXToBs       (uint16_t unusedButMandatoryParameter) {}
  void fnGetInlineTestBsToX       (uint16_t unusedButMandatoryParameter) {}
  void fnSysFreeMem               (uint16_t unusedButMandatoryParameter) {}           //^^
  void fneRPN                     (uint16_t unusedButMandatoryParameter) {}
  void fnT_ARROW                  (uint16_t unusedButMandatoryParameter) {}
  void fnXEQNEW                   (uint16_t unusedButMandatoryParameter) {}
  void fnXEQMSAVE                 (uint16_t unusedButMandatoryParameter) {}
  void fnXEQMLOAD                 (uint16_t unusedButMandatoryParameter) {}
  void fnXSWAP                    (uint16_t unusedButMandatoryParameter) {}
  void fnXEQMXXEQ                 (uint16_t unusedButMandatoryParameter) {}
  void fnAngularModeJM            (uint16_t unusedButMandatoryParameter) {}
  void fnChangeBaseJM             (uint16_t unusedButMandatoryParameter) {}
  void fnChangeBaseMNU            (uint16_t unusedButMandatoryParameter) {}
  void fnByteShortcutsS           (uint16_t unusedButMandatoryParameter) {}  //JM POC BASE2
  void fnByteShortcutsU           (uint16_t unusedButMandatoryParameter) {}  //JM POC BASE2
  void fnByte                     (uint16_t unusedButMandatoryParameter) {}  //JM POC BASE2
  void fnClrMod                   (uint16_t unusedButMandatoryParameter) {}  //JM POC BASE2
  void fnShoiXRepeats             (uint16_t unusedButMandatoryParameter) {}  //JM SHOIDISP
  void fnDumpMenus                (uint16_t unusedButMandatoryParameter) {}  //JM
  void fnCFGsettings              (uint16_t unusedButMandatoryParameter) {}
  void fnPlotSQ                   (uint16_t unusedButMandatoryParameter) {}
  void fnPline                    (uint16_t unusedButMandatoryParameter) {}
  void fnPcros                    (uint16_t unusedButMandatoryParameter) {}
  void fnPbox                     (uint16_t unusedButMandatoryParameter) {}
  void fnPintg                    (uint16_t unusedButMandatoryParameter) {}
  void fnPdiff                    (uint16_t unusedButMandatoryParameter) {}
  void fnPrms                     (uint16_t unusedButMandatoryParameter) {}
  void fnPvect                    (uint16_t unusedButMandatoryParameter) {}
  void fnPNvect                   (uint16_t unusedButMandatoryParameter) {}
  void fnScale                    (uint16_t unusedButMandatoryParameter) {}
  void fnPx                       (uint16_t unusedButMandatoryParameter) {}
  void fnPy                       (uint16_t unusedButMandatoryParameter) {}
  void fnPshade                   (uint16_t unusedButMandatoryParameter) {}
  void fnPzoom                    (uint16_t unusedButMandatoryParameter) {}
  void fnCla                      (uint16_t unusedButMandatoryParameter) {}
  void fnCln                      (uint16_t unusedButMandatoryParameter) {}
  void fnClGrf                    (uint16_t unusedButMandatoryParameter) {}
  void fnMinute                   (uint16_t unusedButMandatoryParameter) {}
  void fnSecond                   (uint16_t unusedButMandatoryParameter) {}
  void fnHrDeg                    (uint16_t unusedButMandatoryParameter) {}
  void fnToTime                   (uint16_t unusedButMandatoryParameter) {}
  void fnTimeTo                   (uint16_t unusedButMandatoryParameter) {}
  void fnDRG                      (uint16_t unusedButMandatoryParameter) {}
  void fnPlotReset                (uint16_t unusedButMandatoryParameter) {}
  void fnCurveFittingReset        (uint16_t unusedButMandatoryParameter) {}
  void fnCurveFitting_T           (uint16_t unusedButMandatoryParameter) {}
  void fnSHIFTf                   (uint16_t unusedButMandatoryParameter) {}
  void fnSHIFTg                   (uint16_t unusedButMandatoryParameter) {}
  void graph_stat                 (uint16_t unusedButMandatoryParameter) {}
  void fnSafeReset                (uint16_t unusedButMandatoryParameter) {}
  void fnSetBCD                   (uint16_t unusedButMandatoryParameter) {}
  void fnLongPressSwitches        (uint16_t unusedButMandatoryParameter) {}
  void fnSetSI_All                (uint16_t unusedButMandatoryParameter) {}
  void fnJulianToDateTime         (uint16_t unusedButMandatoryParameter) {}
  void fnDateTimeToJulian         (uint16_t unusedButMandatoryParameter) {}
  void fnEulersFormula            (uint16_t unusedButMandatoryParameter) {}
  void fnSNAP                     (uint16_t unusedButMandatoryParameter) {}
  void fnPcSigmaDeltaPcXmean      (uint16_t unusedButMandatoryParameter) {}
  void fnDeltaPercentXmean        (uint16_t unusedButMandatoryParameter) {}
  void fnSetCPXmult               (uint16_t unusedButMandatoryParameter) {}
  void setFGLSettings             (uint16_t unusedButMandatoryParameter) {}
  void fnSettingsToXEQ            (uint16_t unusedButMandatoryParameter) {}
  void fnSettingsDispFormatGrpL   (uint16_t unusedButMandatoryParameter) {}
  void fnSettingsDispFormatGrp1L  (uint16_t unusedButMandatoryParameter) {}
  void fnSettingsDispFormatGrp1Lo (uint16_t unusedButMandatoryParameter) {}
  void fnSettingsDispFormatGrpR   (uint16_t unusedButMandatoryParameter) {}
  void fnSetGapChar               (uint16_t unusedButMandatoryParameter) {}
  void fnMenuGapL                 (uint16_t unusedButMandatoryParameter) {}
  void fnMenuGapR                 (uint16_t unusedButMandatoryParameter) {}
  void fnMenuGapRX                (uint16_t unusedButMandatoryParameter) {}
  void fnSetHP35                  (uint16_t unusedButMandatoryParameter) {}
  void fnSetC47                   (uint16_t unusedButMandatoryParameter) {}
  void fnDiskInfo                 (uint16_t unusedButMandatoryParameter) {}
  void fnLint                     (uint16_t unusedButMandatoryParameter) {}
  void fnSetVolume                (uint16_t unusedButMandatoryParameter) {}
  void fnGetVolume                (uint16_t unusedButMandatoryParameter) {}
  void fnVolumeUp                 (uint16_t unusedButMandatoryParameter) {}
  void fnVolumeDown               (uint16_t unusedButMandatoryParameter) {}
  void fnBuzz                     (uint16_t unusedButMandatoryParameter) {}
  void fnPlay                     (uint16_t unusedButMandatoryParameter) {}
  void fnL100Tokml                (uint16_t unusedButMandatoryParameter) {}
  void fnKmletok100K              (uint16_t unusedButMandatoryParameter) {}
  void fnK100Ktokmk               (uint16_t unusedButMandatoryParameter) {}
  void fnL100Tomgus               (uint16_t unusedButMandatoryParameter) {}
  void fnMgeustok100M             (uint16_t unusedButMandatoryParameter) {}
  void fnK100Ktok100M             (uint16_t unusedButMandatoryParameter) {}
  void fnL100Tomguk               (uint16_t unusedButMandatoryParameter) {}
  void fnMgeuktok100M             (uint16_t unusedButMandatoryParameter) {}
  void fnK100Mtomik               (uint16_t unusedButMandatoryParameter) {}
  void fnBaseMenu                 (uint16_t unusedButMandatoryParameter) {}
  void fnExecutePlusSkip          (uint16_t unusedButMandatoryParameter) {}
  void fnGetDmx                   (uint16_t unusedButMandatoryParameter) {}
#endif // GENERATE_CATALOGS

#ifdef TESTSUITE_BUILD
  void fnDiskInfo                 (uint16_t unusedButMandatoryParameter) {}
#endif //TEST_SUITE


#define NPER_   "n" STD_SUB_P STD_SUB_E STD_SUB_R                    //
#define RANGE_  STD_SUB_R STD_SUB_A STD_SUB_N STD_SUB_G STD_SUB_E    // Strings to maintain table columns below
#define SUPSUB_ STD_SUP_S STD_SUP_U STD_SUP_P STD_SUB_S STD_SUB_U STD_SUB_B

TO_QSPI const item_t indexOfItems[] = {

//This list is generated (manually) from items3.xlsx, EXPORT.C

//            function                      parameter                    item in catalog                                item in softmenu                               TAM min                 max  CATALOG    stackLift       UNDO status    EIM status     In program
/*    0 */  { itemToBeCoded,                NOPARAM,                     "",                                            "0000",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         }, // ITM_NULL

// Items from 1 to 127 are 1 byte OP codes
/*    1 */  { fnNop,                        TM_LABEL,                    "LBL",                                         "LBL",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DECLARE_LABEL},
/*    2 */  { fnGoto,                       TM_LABEL,                    "GTO",                                         "GTO",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/*    3 */  { fnExecute,                    TM_LABEL,                    "XEQ",                                         "XEQ",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/*    4 */  { fnReturn,                     0,                           "RTN",                                         "RTN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*    5 */  { fnIse,                        TM_REGISTER,                 "ISE",                                         "ISE",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*    6 */  { fnIsg,                        TM_REGISTER,                 "ISG",                                         "ISG",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*    7 */  { fnIsz,                        TM_REGISTER,                 "ISZ",                                         "ISZ",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*    8 */  { fnDse,                        TM_REGISTER,                 "DSE",                                         "DSE",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*    9 */  { fnDsl,                        TM_REGISTER,                 "DSL",                                         "DSL",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   10 */  { fnDsz,                        TM_REGISTER,                 "DSZ",                                         "DSZ",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   11 */  { fnXEqualsTo,                  TM_CMP,                      "x= ?",                                        "x= ?",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   12 */  { fnXNotEqual,                  TM_CMP,                      "x" STD_NOT_EQUAL " ?",                        "x" STD_NOT_EQUAL " ?",                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   13 */  { fnCheckValue,                 CHECK_VALUE_POSITIVE_ZERO,   "x=+0?",                                       "x=+0?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   14 */  { fnCheckValue,                 CHECK_VALUE_NEGATIVE_ZERO,   "x=-0?",                                       "x=-0?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   15 */  { fnXAlmostEqual,               TM_CMP,                      "x" STD_ALMOST_EQUAL " ?",                     "x" STD_ALMOST_EQUAL " ?",                     (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   16 */  { fnXLessThan,                  TM_CMP,                      "x< ?",                                        "x< ?",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   17 */  { fnXLessEqual,                 TM_CMP,                      "x" STD_LESS_EQUAL " ?",                       "x" STD_LESS_EQUAL " ?",                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   18 */  { fnXGreaterEqual,              TM_CMP,                      "x" STD_GREATER_EQUAL " ?",                    "x" STD_GREATER_EQUAL " ?",                    (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   19 */  { fnXGreaterThan,               TM_CMP,                      "x> ?",                                        "x> ?",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_COMPARE      },
/*   20 */  { fnIsFlagClear,                TM_FLAGR,                    "FC?",                                         "FC?",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_FLAG         },
/*   21 */  { fnIsFlagSet,                  TM_FLAGR,                    "FS?",                                         "FS?",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_FLAG         },
/*   22 */  { fnCheckInteger,               CHECK_INTEGER_EVEN,          "EVEN?",                                       "EVEN?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   23 */  { fnCheckInteger,               CHECK_INTEGER_ODD,           "ODD?",                                        "ODD?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   24 */  { fnCheckInteger,               CHECK_INTEGER_FP,            "FP?",                                         "FP?",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   25 */  { fnCheckInteger,               CHECK_INTEGER,               "INT?",                                        "INT?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   26 */  { fnCheckValue,                 CHECK_VALUE_COMPLEX,         "CPX?",                                        "CPX?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   27 */  { fnCheckValue,                 CHECK_VALUE_MATRIX,          "MATR?",                                       "MATR?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   28 */  { fnCheckValue,                 CHECK_VALUE_NAN,             "NaN?",                                        "NaN?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   29 */  { fnCheckValue,                 CHECK_VALUE_REAL,            "REAL?",                                       "REAL?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   30 */  { fnCheckValue,                 CHECK_VALUE_SPECIAL,         "SPEC?",                                       "SPEC?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   31 */  { fnIsString,                   NOPARAM,                     "STRI?",                                       "STRI?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   32 */  { fnCheckValue,                 CHECK_VALUE_INFINITY,        STD_PLUS_MINUS STD_INFINITY "?",               STD_PLUS_MINUS STD_INFINITY "?",               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   33 */  { fnIsPrime,                    NOPARAM,                     "PRIME?",                                      "PRIME?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   34 */  { fnIsTopRoutine,               NOPARAM,                     "TOP?",                                        "TOP?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   35 */  { fnKeyEnter,                   NOPARAM/*#JM#*/,             "ENTER" STD_UP_ARROW,                          "ENTER" STD_UP_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   36 */  { fnSwapXY,                     NOPARAM,                     "x" STD_RIGHT_OVER_LEFT_ARROW "y",             "x" STD_RIGHT_OVER_LEFT_ARROW "y",             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/*   37 */  { fnDrop,                       NOPARAM,                     "DROPx",                                       "DROPx",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   38 */  { fnPause,                      TM_VALUE,                    "PAUSE",                                       "PAUSE",                                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NUMBER_8     },
/*   39 */  { fnRollUp,                     NOPARAM,                     "R" STD_UP_ARROW,                              "R" STD_UP_ARROW,                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/*   40 */  { fnRollDown,                   NOPARAM,                     "R" STD_DOWN_ARROW,                            "R" STD_DOWN_ARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/*   41 */  { fnClX,                        NOPARAM,                     "CLX",                                         "CLX",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_DISABLED  | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/*   42 */  { fnFillStack,                  NOPARAM,                     "FILL",                                        "FILL",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   43 */  { fnInput,                      TM_REGISTER,                 "INPUT",                                       "INPUT",                                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_REGISTER     },
/*   44 */  { fnStore,                      TM_STORCL,                   "STO",                                         "STO",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   45 */  { fnStoreAdd,                   NOPARAM,                     "STO+",                                        "STO+",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   46 */  { fnStoreSub,                   NOPARAM,                     "STO-",                                        "STO-",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   47 */  { fnStoreMult,                  NOPARAM,                     "STO" STD_CROSS,                               "STO" STD_CROSS,                               (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   48 */  { fnStoreDiv,                   NOPARAM,                     "STO/",                                        "STO/",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   49 */  { fnCyx,                        NOPARAM,                     "COMB",                                        "C" STD_SUB_y STD_SUB_x,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   50 */  { fnPyx,                        NOPARAM,                     "PERM",                                        "P" STD_SUB_y STD_SUB_x,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   51 */  { fnRecall,                     TM_STORCL,                   "RCL",                                         "RCL",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   52 */  { fnRecallAdd,                  NOPARAM,                     "RCL+",                                        "RCL+",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   53 */  { fnRecallSub,                  NOPARAM,                     "RCL-",                                        "RCL-",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   54 */  { fnRecallMult,                 NOPARAM,                     "RCL" STD_CROSS,                               "RCL" STD_CROSS,                               (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   55 */  { fnRecallDiv,                  NOPARAM,                     "RCL/",                                        "RCL/",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   56 */  { fnIsConverged,                TM_VALUE,                    "CONVG?",                                      "CONVG?",                                      (0 << TAM_MAX_BITS) |     7, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_REGISTER     },
/*   57 */  { fnEntryQ,                     NOPARAM,                     "ENTRY?",                                      "ENTRY?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   58 */  { fnSquare,                     NOPARAM,                     "x" STD_SUP_2,                                 "x" STD_SUP_2,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   59 */  { fnCube,                       NOPARAM,                     "x" STD_SUP_3,                                 "x" STD_SUP_3,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   60 */  { fnPower,                      NOPARAM,                     "y" STD_SUP_x,                                 "y" STD_SUP_x,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   61 */  { fnSquareRoot,                 NOPARAM,                     STD_SQUARE_ROOT STD_x_UNDER_ROOT,              STD_SQUARE_ROOT STD_x_UNDER_ROOT,              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   62 */  { fnCubeRoot,                   NOPARAM,                     STD_CUBE_ROOT STD_x_UNDER_ROOT,                STD_CUBE_ROOT STD_x_UNDER_ROOT,                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   63 */  { fnXthRoot,                    NOPARAM,                     STD_xTH_ROOT STD_y_UNDER_ROOT,                 STD_xTH_ROOT STD_y_UNDER_ROOT,                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   64 */  { fn2Pow,                       NOPARAM,                     "2" STD_SUP_x,                                 "2" STD_SUP_x,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   65 */  { fnExp,                        NOPARAM,                     STD_EulerE STD_SUP_x,                          STD_EulerE STD_SUP_x,                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   66 */  { itemToBeCoded,                NOPARAM,                     "0066",                                        "0066",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*   67 */  { fn10Pow,                      NOPARAM,                     "10" STD_SUP_x,                                "10" STD_SUP_x,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   68 */  { fnLog2,                       NOPARAM/*#JM#*/,             "LB",                                          "LB",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   69 */  { fnLn,                         NOPARAM/*#JM#*/,             "LN",                                          "LN",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM3 change ln to LN
/*   70 */  { fnStopProgram,                NOPARAM,                     "STOP",                                        "R/S",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*   71 */  { fnLog10,                      NOPARAM/*#JM#*/,             "LOG",                                         "LOG",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM Change lg to LOG
/*   72 */  { fnLogXY,                      NOPARAM/*#JM#*/,             "LOG" STD_SUB_x "y",                           "LOG" STD_SUB_x "y",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   73 */  { fnInvert,                     NOPARAM,                     "1/x",                                         "1/x",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   74 */  { fnCos,                        NOPARAM/*#JM#*/,             "COS",                                         "COS",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM
/*   75 */  { fnCosh,                       NOPARAM,                     "cosh",                                        "cosh",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   76 */  { fnSin,                        NOPARAM/*#JM#*/,             "SIN",                                         "SIN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM3
/*   77 */  { fnKey,                        TM_REGISTER,                 "KEY?",                                        "KEY?",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   78 */  { fnSinh,                       NOPARAM,                     "sinh",                                        "sinh",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   79 */  { fnTan,                        NOPARAM/*#JM#*/,             "TAN",                                         "TAN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM3
/*   80 */  { fnTanh,                       NOPARAM,                     "tanh",                                        "tanh",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   81 */  { fnArccos,                     NOPARAM/*#JM#*/,             "ARCCOS",                                      "ACOS",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM
/*   82 */  { fnArccosh,                    NOPARAM,                     "arcosh",                                      "arcosh",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   83 */  { fnArcsin,                     NOPARAM/*#JM#*/,             "ARCSIN",                                      "ASIN",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM
/*   84 */  { fnArcsinh,                    NOPARAM,                     "arsinh",                                      "arsinh",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   85 */  { fnArctan,                     NOPARAM/*#JM#*/,             "ARCTAN",                                      "ATAN",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },//JM
/*   86 */  { fnArctanh,                    NOPARAM,                     "artanh",                                      "artanh",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   87 */  { fnCeil,                       NOPARAM,                     "ceil",                                        "ceil",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   88 */  { fnFloor,                      NOPARAM,                     "floor",                                       "floor",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*   89 */  { fnGcd,                        NOPARAM,                     "GCD",                                         "GCD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   90 */  { fnLcm,                        NOPARAM,                     "LCM",                                         "LCM",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   91 */  { fnDec,                        TM_REGISTER,                 "DECR",                                        "DECR",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   92 */  { fnInc,                        TM_REGISTER,                 "INCR",                                        "INCR",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/*   93 */  { fnIp,                         NOPARAM,                     "IP",                                          "IP",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   94 */  { fnFp,                         NOPARAM,                     "FP",                                          "FP",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   95 */  { fnAdd,                        ITM_ADD,                     "+",                                           "+",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   96 */  { fnSubtract,                   ITM_SUB,                     "-",                                           "-",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   97 */  { fnChangeSign,                 ITM_CHS/*#JM#*/,             "CHS",                                         "CHS",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM Change +/- to CHS
/*   98 */  { fnMultiply,                   ITM_MULT,                    STD_CROSS,                                     STD_CROSS,                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*   99 */  { fnDivide,                     ITM_DIV/*#JM#*/,             STD_DIVIDE,                                    STD_DIVIDE,                                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  100 */  { fnIDiv,                       NOPARAM,                     "IDIV",                                        "IDIV",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  101 */  { fnView,                       TM_M_DIM,                    "VIEW",                                        "VIEW",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_REGISTER     },
/*  102 */  { fnMod,                        NOPARAM,                     "MOD",                                         "MOD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  103 */  { fnMax,                        NOPARAM,                     "max",                                         "max",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  104 */  { fnMin,                        NOPARAM,                     "min",                                         "min",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  105 */  { fnMagnitude,                  NOPARAM,                     "|x|",                                         "|x|",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  106 */  { fnNeighb,                     NOPARAM,                     "NEIGHB",                                      "NEIGHB",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  107 */  { fnNextPrime,                  NOPARAM,                     "NEXTP",                                       "NEXTP",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  108 */  { fnFactorial,                  NOPARAM,                     "x!",                                          "x!",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  109 */  { fnPi,                         NOPARAM,                     STD_pi,                                        STD_pi,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  110 */  { fnClearFlag,                  TM_FLAGW,                    "CF",                                          "CF",                                          (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  111 */  { fnSetFlag,                    TM_FLAGW,                    "SF",                                          "SF",                                          (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  112 */  { fnFlipFlag,                   TM_FLAGW,                    "FF",                                          "FF",                                          (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  113 */  { fnCheckValue,                 CHECK_VALUE_MATRIX_SQUARE,   "M.SQR?",                                      "M.SQR?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*  114 */  { itemToBeCoded,                NOPARAM,                     "LITE",                                        "LITE",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_LITERAL      }, // Literal in a PGM
/*  115 */  { fnAngularModeJM,              amDegree,                    STD_RIGHT_DOUBLE_ARROW "DEG",                  STD_RIGHT_DOUBLE_ARROW "DEG",                  (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  116 */  { fnAngularModeJM,              amDMS /*#JM#*/,              STD_RIGHT_DOUBLE_ARROW "D.MS",                 STD_RIGHT_DOUBLE_ARROW "D.MS",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  117 */  { fnAngularModeJM,              amGrad,                      STD_RIGHT_DOUBLE_ARROW "GRAD",                 STD_RIGHT_DOUBLE_ARROW "GRAD",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  118 */  { fnAngularModeJM,              amMultPi,                    STD_RIGHT_DOUBLE_ARROW "MUL" STD_pi,           STD_RIGHT_DOUBLE_ARROW "MUL" STD_pi,           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  119 */  { fnAngularModeJM,              amRadian,                    STD_RIGHT_DOUBLE_ARROW "RAD",                  STD_RIGHT_DOUBLE_ARROW "RAD",                  (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  120 */  { fnLint,                       NOPARAM,                     "LINT",                                        "LINT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  121 */  { fnSetRoundingMode,            TM_VALUE,                    "RMODE",                                       "RMODE",                                       (0 << TAM_MAX_BITS) |     6, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  122 */  { fnRmd,                        NOPARAM,                     "RMD",                                         "RMD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/*  123 */  { fnLogicalNot,                 NOPARAM,                     "NOT",                                         "NOT",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  124 */  { fnLogicalAnd,                 NOPARAM,                     "AND",                                         "AND",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  125 */  { fnLogicalOr,                  NOPARAM,                     "OR",                                          "OR",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  126 */  { fnLogicalXor,                 NOPARAM,                     "XOR",                                         "XOR",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  127 */  { fnSwapX,                      TM_REGISTER,                 "x" STD_RIGHT_OVER_LEFT_ARROW,                 "x" STD_RIGHT_OVER_LEFT_ARROW,                 (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_REGISTER     },


// Items from 128 to ... are 2 byte OP codes
// Constants
/*  128 */  { fnConstant,                   0,                           "a",                                           "yr.gregor",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  129 */  { fnConstant,                   1,                           "a" STD_SUB_0,                                 "rad.bohr",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  130 */  { fnConstant,                   2,                           "a" STD_SUB_M STD_SUB_o STD_SUB_o STD_SUB_n,   "orb.moon",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  131 */  { fnConstant,                   3,                           "a" STD_SUB_EARTH,                             "orb.earth",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  132 */  { fnConstant,                   4,                           "c",                                           "lightspeed",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  133 */  { fnConstant,                   5,                           "c" STD_SUB_1,                                 "c.radiatn1",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  134 */  { fnConstant,                   6,                           "c" STD_SUB_2,                                 "c.radiatn2",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  135 */  { fnConstant,                   7,                           "e",                                           "charge.elem",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  136 */  { fnConstant,                   8,                           STD_EulerE,                                    STD_EulerE ".euler",                           (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  137 */  { fnConstant,                   9,                           "F",                                           "c.faraday",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  138 */  { fnConstant,                   10,                          "F" STD_SUB_alpha,                             STD_alpha ".feigenbm",                         (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  139 */  { fnConstant,                   11,                          "F" STD_SUB_delta,                             STD_delta ".feigenbm",                         (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  140 */  { fnConstant,                   12,                          "G",                                           "c.grav.nwt",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  141 */  { fnConstant,                   13,                          "G" STD_SUB_0,                                 "cond.quant",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  142 */  { fnConstant,                   14,                          "G" STD_SUB_C,                                 "c.catalan",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  143 */  { fnConstant,                   15,                          "g" STD_SUB_e,                                 "gfact.elec",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  144 */  { fnConstant,                   16,                          "GM" STD_SUB_EARTH,                            "c.grav.geo",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  145 */  { fnConstant,                   17,                          "g" STD_SUB_EARTH,                             "acc.earth",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  146 */  { fnConstant,                   18,                          STD_PLANCK,                                    "c.planck",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  147 */  { fnConstant,                   19,                          STD_PLANCK_2PI,                                "red.planck",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  148 */  { fnConstant,                   20,                          "k",                                           "c.boltzmn",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  149 */  { fnConstant,                   21,                          "K" STD_SUB_J,                                 "c.josephsn",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  150 */  { fnConstant,                   22,                          "l" STD_SUB_P STD_SUB_L,                       "len.planck",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  151 */  { fnConstant,                   23,                          "m" STD_SUB_e,                                 "mass.elec",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  152 */  { fnConstant,                   24,                          "M" STD_SUB_M STD_SUB_o STD_SUB_o STD_SUB_n,   "mass.moon",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  153 */  { fnConstant,                   25,                          "m" STD_SUB_n,                                 "mass.neu",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  154 */  { fnConstant,                   26,                          "m" STD_SUB_n "/m" STD_SUB_p,                  "r.neu.prot",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  155 */  { fnConstant,                   27,                          "m" STD_SUB_p,                                 "mass.prot",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  156 */  { fnConstant,                   28,                          "m" STD_SUB_P STD_SUB_L,                       "mass.planck",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  157 */  { fnConstant,                   29,                          "m" STD_SUB_p "/m" STD_SUB_e,                  "r.prot.elec",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  158 */  { fnConstant,                   30,                          "m" STD_SUB_u,                                 "mass.atom",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  159 */  { fnConstant,                   31,                          "m" STD_SUB_u "c" STD_SUP_2,                   "energy.atom",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  160 */  { fnConstant,                   32,                          "m" STD_SUB_mu,                                "mass.muon",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  161 */  { fnConstant,                   33,                          "M" STD_SUB_SUN,                               "mass.sun",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  162 */  { fnConstant,                   34,                          "M" STD_SUB_EARTH,                             "mass.earth",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  163 */  { fnConstant,                   35,                          "N" STD_SUB_A,                                 "nr.avogadro",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  164 */  { fnConstant,                   36,                          "NaN",                                         "not.a.nr",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  165 */  { fnConstant,                   37,                          "p" STD_SUB_0,                                 "press.atm",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  166 */  { fnConstant,                   38,                          "R",                                           "c.mol.gas",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  167 */  { fnConstant,                   39,                          "r" STD_SUB_e,                                 "rad.elec",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  168 */  { fnConstant,                   40,                          "R" STD_SUB_K,                                 "c.klitzing",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  169 */  { fnConstant,                   41,                          "R" STD_SUB_M STD_SUB_o STD_SUB_o STD_SUB_n,   "rad.moon",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  170 */  { fnConstant,                   42,                          "R" STD_SUB_INFINITY,                          "c.rydberg",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  171 */  { fnConstant,                   43,                          "R" STD_SUB_SUN,                               "rad.sun",                                     (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  172 */  { fnConstant,                   44,                          "R" STD_SUB_EARTH,                             "rad.earth",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  173 */  { fnConstant,                   45,                          "Sa",                                          "majax.earth",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  174 */  { fnConstant,                   46,                          "Sb",                                          "minax.earth",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  175 */  { fnConstant,                   47,                          "Se" STD_SUP_2,                                "sq.eccent1",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  176 */  { fnConstant,                   48,                          "Se'" STD_SUP_2,                               "sq.eccent2",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  177 */  { fnConstant,                   49,                          "Sf" STD_SUP_MINUS_1,                          "f.flatteng",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  178 */  { fnConstant,                   50,                          "T" STD_SUB_0,                                 "temp.stand",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  179 */  { fnConstant,                   51,                          "T" STD_SUB_P,                                 "temp.planck",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  180 */  { fnConstant,                   52,                          "t" STD_SUB_P STD_SUB_L,                       "time.planck",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  181 */  { fnConstant,                   53,                          "V" STD_SUB_m,                                 "volume.gas",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  182 */  { fnConstant,                   54,                          "Z" STD_SUB_0,                                 "imped.vac",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  183 */  { fnConstant,                   55,                          STD_alpha,                                     "c.finestruc",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  184 */  { fnConstant,                   56,                          STD_gamma,                                     "c.grav.nwt",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  185 */  { fnConstant,                   57,                          STD_gamma STD_SUB_E STD_SUB_M,                 "c.eul.masc",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  186 */  { fnConstant,                   58,                          STD_gamma STD_SUB_p,                           "r.gyro.prot",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  187 */  { fnConstant,                   59,                          STD_DELTA STD_nu STD_SUB_C STD_SUB_s,          "frq.hypf.cs",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  188 */  { fnConstant,                   60,                          STD_epsilon STD_SUB_0,                         "epermt.vac",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  189 */  { fnConstant,                   61,                          STD_lambda STD_SUB_C,                          "wavln.elec",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  190 */  { fnConstant,                   62,                          STD_lambda STD_SUB_C STD_SUB_n,                "wavln.neu",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  191 */  { fnConstant,                   63,                          STD_lambda STD_SUB_C STD_SUB_p,                "wavln.prot",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  192 */  { fnConstant,                   64,                          STD_mu STD_SUB_0,                              "mpermb.vac",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  193 */  { fnConstant,                   65,                          STD_mu STD_SUB_B,                              "magn.both",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  194 */  { fnConstant,                   66,                          STD_mu STD_SUB_e,                              "mgmom.elec",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  195 */  { fnConstant,                   67,                          STD_mu STD_SUB_e "/" STD_mu STD_SUB_B,         "r.elec.bohr",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  196 */  { fnConstant,                   68,                          STD_mu STD_SUB_n,                              "magmom.neu",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  197 */  { fnConstant,                   69,                          STD_mu STD_SUB_p,                              "mgmom.prot",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  198 */  { fnConstant,                   70,                          STD_mu STD_SUB_u,                              "magn.nucl",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  199 */  { fnConstant,                   71,                          STD_mu STD_SUB_mu,                             "mgmom.muon",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  200 */  { fnConstant,                   72,                          STD_sigma STD_SUB_B,                           "c.stephbol",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  201 */  { fnConstant,                   73,                          STD_phi,                                       "r.golden",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  202 */  { fnConstant,                   74,                          STD_phi STD_SUB_0,                             "fluxq.magn",                                  (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  203 */  { fnConstant,                   75,                          STD_omega,                                     "vangl.earth",                                 (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  204 */  { fnConstant,                   76,                          "-" STD_INFINITY,                              "inf.minus",                                   (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  205 */  { fnConstant,                   77,                          STD_INFINITY,                                  "inf.plus",                                    (0 << TAM_MAX_BITS) |     0, CAT_CNST | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  206 */  { itemToBeCoded,                78,                          "#",                                           "zero",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/*  207 */  { fnConstant,                   TM_VALUE,                    "CNST",                                        "CNST",                                        (0 << TAM_MAX_BITS) |   215, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8_16  }, // 215 is replaced at run time by NUMBER_OF_CONSTANTS_39 + NUMBER_OF_CONSTANTS_51 + NUMBER_OF_CONSTANTS_1071 + NUMBER_OF_CONSTANTS_34 - 1
/*  208 */  { itemToBeCoded,                NOPARAM,                     "0208",                                        "0208",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  209 */  { itemToBeCoded,                NOPARAM,                     "0209",                                        "0209",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  210 */  { itemToBeCoded,                NOPARAM,                     "0210",                                        "0210",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  211 */  { itemToBeCoded,                NOPARAM,                     "0211",                                        "0211",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  212 */  { itemToBeCoded,                NOPARAM,                     "0212",                                        "0212",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  213 */  { itemToBeCoded,                NOPARAM,                     "0213",                                        "0213",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  214 */  { itemToBeCoded,                NOPARAM,                     "0214",                                        "0214",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  215 */  { itemToBeCoded,                NOPARAM,                     "0215",                                        "0215",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  216 */  { itemToBeCoded,                NOPARAM,                     "0216",                                        "0216",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  217 */  { itemToBeCoded,                NOPARAM,                     "0217",                                        "0217",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  218 */  { itemToBeCoded,                NOPARAM,                     "0218",                                        "0218",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  219 */  { itemToBeCoded,                NOPARAM,                     "0219",                                        "0219",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Conversions
/*  220 */  { fnCvtCToF,                    NOPARAM,                     STD_DEGREE "C" STD_RIGHT_ARROW STD_DEGREE "F", STD_DEGREE "C" STD_RIGHT_ARROW STD_DEGREE "F", (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  221 */  { fnCvtFToC,                    NOPARAM,                     STD_DEGREE "F" STD_RIGHT_ARROW STD_DEGREE "C", STD_DEGREE "F" STD_RIGHT_ARROW STD_DEGREE "C", (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  222 */  { fnCvtDbRatio,                 10,                          "dB" STD_RIGHT_ARROW "pr",                     "dB" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  223 */  { itemToBeCoded,                NOPARAM,                     "0223",                                        "0223",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  224 */  { itemToBeCoded,                NOPARAM,                     "0224",                                        "0224",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  225 */  { fnCvtDbRatio,                 20,                          "dB" STD_RIGHT_ARROW "fr",                     "dB" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  226 */  { itemToBeCoded,                NOPARAM,                     "0226",                                        "0226",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  227 */  { itemToBeCoded,                NOPARAM,                     "0227",                                        "0227",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  228 */  { fnCvtRatioDb,                 10,                          "pr" STD_RIGHT_ARROW "dB",                     "pwr",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  229 */  { itemToBeCoded,                NOPARAM,                     "0229",                                        "0229",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  230 */  { itemToBeCoded,                NOPARAM,                     "0230",                                        "0230",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  231 */  { fnCvtRatioDb,                 20,                          "fr" STD_RIGHT_ARROW "dB",                     "fld",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  232 */  { itemToBeCoded,                NOPARAM,                     "0232",                                        "0232",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  233 */  { itemToBeCoded,                NOPARAM,                     "0233",                                        "0233",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  234 */  { fnCvtAcreHa,                  multiply,                    "acre" STD_RIGHT_ARROW "ha",                   "acre" STD_RIGHT_ARROW,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  235 */  { itemToBeCoded,                NOPARAM,                     "0235",                                        "0235",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  236 */  { fnCvtAcreHa,                  divide,                      "ha" STD_RIGHT_ARROW "acre",                   "ha" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  237 */  { itemToBeCoded,                NOPARAM,                     "0237",                                        "0237",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  238 */  { fnCvtAcreusHa,                multiply,                    "acre" STD_US STD_RIGHT_ARROW "ha",            "acre" STD_US STD_RIGHT_ARROW,                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  239 */  { itemToBeCoded,                NOPARAM,                     "0239",                                        "0239",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  240 */  { fnCvtAcreusHa,                divide,                      "ha" STD_RIGHT_ARROW "acre" STD_US,            "ha" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  241 */  { itemToBeCoded,                NOPARAM,                     "0241",                                        "0241",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  242 */  { fnCvtAtmPa,                   divide,                      "Pa" STD_RIGHT_ARROW "atm",                    "Pa" STD_RIGHT_ARROW "atm",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  243 */  { fnCvtAtmPa,                   multiply,                    "atm" STD_RIGHT_ARROW "Pa",                    "atm" STD_RIGHT_ARROW "Pa",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  244 */  { fnCvtAuM,                     multiply,                    "au" STD_RIGHT_ARROW "m",                      "au" STD_RIGHT_ARROW "m",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  245 */  { fnCvtAuM,                     divide,                      "m" STD_RIGHT_ARROW "au",                      "m" STD_RIGHT_ARROW "au",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  246 */  { fnCvtBarPa,                   multiply,                    "bar" STD_RIGHT_ARROW "Pa",                    "bar" STD_RIGHT_ARROW "Pa",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  247 */  { fnCvtBarPa,                   divide,                      "Pa" STD_RIGHT_ARROW "bar",                    "Pa" STD_RIGHT_ARROW "bar",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  248 */  { fnCvtBtuJ,                    multiply,                    "Btu" STD_RIGHT_ARROW "J",                     "Btu" STD_RIGHT_ARROW "J",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  249 */  { fnCvtBtuJ,                    divide,                      "J" STD_RIGHT_ARROW "Btu",                     "J" STD_RIGHT_ARROW "Btu",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  250 */  { fnCvtCalJ,                    multiply,                    "cal" STD_RIGHT_ARROW "J",                     "cal" STD_RIGHT_ARROW "J",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  251 */  { fnCvtCalJ,                    divide,                      "J" STD_RIGHT_ARROW "cal",                     "J" STD_RIGHT_ARROW "cal",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  252 */  { fnCvtLbfftNm,                 multiply,                    "lbf" STD_DOT "ft" STD_RIGHT_ARROW "Nm",       "lbf" STD_DOT "ft" STD_RIGHT_ARROW,            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  253 */  { itemToBeCoded,                NOPARAM,                     "0253",                                        "0253",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  254 */  { fnCvtLbfftNm,                 divide,                      "Nm" STD_RIGHT_ARROW "lbf" STD_DOT "ft",       "Nm" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  255 */  { itemToBeCoded,                NOPARAM,                     "0255",                                        "0255",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  256 */  { fnCvtCwtKg,                   multiply,                    "cwt" STD_RIGHT_ARROW "kg",                    "cwt" STD_RIGHT_ARROW "kg",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  257 */  { fnCvtCwtKg,                   divide,                      "kg" STD_RIGHT_ARROW "cwt",                    "kg" STD_RIGHT_ARROW "cwt",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  258 */  { fnCvtFtM,                     multiply,                    "ft." STD_RIGHT_ARROW "m",                     "ft." STD_RIGHT_ARROW "m",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  259 */  { fnCvtFtM,                     divide,                      "m" STD_RIGHT_ARROW "ft.",                     "m" STD_RIGHT_ARROW "ft.",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  260 */  { fnCvtSfeetM,                  multiply,                    "survey ft" STD_US STD_RIGHT_ARROW "m",        "survey ft" STD_US STD_RIGHT_ARROW,            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  261 */  { itemToBeCoded,                NOPARAM,                     "0261",                                        "0261",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  262 */  { itemToBeCoded,                NOPARAM,                     "0262",                                        "0262",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  263 */  { fnCvtSfeetM,                  divide,                      "m" STD_RIGHT_ARROW "survey ft" STD_US,        "m" STD_RIGHT_ARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  264 */  { itemToBeCoded,                NOPARAM,                     "0264",                                        "0264",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  265 */  { itemToBeCoded,                NOPARAM,                     "0265",                                        "0265",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  266 */  { fnCvtFlozukMl,                multiply,                    "floz" STD_UK STD_RIGHT_ARROW "ml",            "floz" STD_UK STD_RIGHT_ARROW,                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  267 */  { itemToBeCoded,                NOPARAM,                     "0267",                                        "0267",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  268 */  { fnCvtFlozukMl,                divide,                      "ml" STD_RIGHT_ARROW "floz" STD_UK,            "ml" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  269 */  { itemToBeCoded,                NOPARAM,                     "0269",                                        "0269",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  270 */  { fnCvtFlozusMl,                multiply,                    "floz" STD_US  STD_RIGHT_ARROW "ml",           "floz" STD_US  STD_RIGHT_ARROW,                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  271 */  { itemToBeCoded,                NOPARAM,                     "0271",                                        "0271",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  272 */  { fnCvtFlozusMl,                divide,                      "ml" STD_RIGHT_ARROW "floz" STD_US ,           "ml" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  273 */  { itemToBeCoded,                NOPARAM,                     "0273",                                        "0273",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  274 */  { fnCvtGalukL,                  multiply,                    "gal" STD_UK STD_RIGHT_ARROW "l",              "gal" STD_UK STD_RIGHT_ARROW "l",              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  275 */  { fnCvtGalukL,                  divide,                      "l" STD_RIGHT_ARROW "gal" STD_UK,              "l" STD_RIGHT_ARROW "gal" STD_UK,              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  276 */  { fnCvtGalusL,                  multiply,                    "gal" STD_US STD_RIGHT_ARROW "l",              "gal" STD_US STD_RIGHT_ARROW "l",              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  277 */  { fnCvtGalusL,                  divide,                      "l" STD_RIGHT_ARROW "gal" STD_US,              "l" STD_RIGHT_ARROW "gal" STD_US,              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  278 */  { fnCvtHpeW,                    multiply,                    "hp" STD_SUB_E STD_RIGHT_ARROW "W",            "hp" STD_SUB_E STD_RIGHT_ARROW "W",            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  279 */  { fnCvtHpeW,                    divide,                      "W" STD_RIGHT_ARROW "hp" STD_SUB_E,            "W" STD_RIGHT_ARROW "hp" STD_SUB_E,            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  280 */  { fnCvtHpmW,                    multiply,                    "hp" STD_SUB_M STD_RIGHT_ARROW "W",            "hp" STD_SUB_M STD_RIGHT_ARROW "W",            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  281 */  { fnCvtHpmW,                    divide,                      "W" STD_RIGHT_ARROW "hp" STD_SUB_M,            "W" STD_RIGHT_ARROW "hp" STD_SUB_M,            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  282 */  { fnCvtHpukW,                   multiply,                    "hp" STD_UK STD_RIGHT_ARROW "W",               "hp" STD_UK STD_RIGHT_ARROW "W",               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  283 */  { fnCvtHpukW,                   divide,                      "W" STD_RIGHT_ARROW "hp" STD_UK,               "W" STD_RIGHT_ARROW "hp" STD_UK,               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  284 */  { fnCvtInhgPa,                  multiply,                    "in.Hg" STD_RIGHT_ARROW "Pa",                  "in.Hg" STD_RIGHT_ARROW,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  285 */  { itemToBeCoded,                NOPARAM,                     "0285",                                        "0285",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  286 */  { fnCvtInhgPa,                  divide,                      "Pa" STD_RIGHT_ARROW "in.Hg",                  "Pa" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  287 */  { itemToBeCoded,                NOPARAM,                     "0287",                                        "0287",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  288 */  { fnCvtInchMm,                  multiply,                    "in." STD_RIGHT_ARROW "mm",                    "in." STD_RIGHT_ARROW "mm",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  289 */  { fnCvtInchMm,                  divide,                      "mm" STD_RIGHT_ARROW "in.",                    "mm" STD_RIGHT_ARROW "in.",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  290 */  { fnCvtWhJ,                     multiply,                    "Wh" STD_RIGHT_ARROW "J",                      "Wh" STD_RIGHT_ARROW "J",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  291 */  { fnCvtWhJ,                     divide,                      "J" STD_RIGHT_ARROW "Wh",                      "J" STD_RIGHT_ARROW "Wh",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  292 */  { fnCvtLbKg,                    divide,                      "kg" STD_RIGHT_ARROW "lb.",                    "kg" STD_RIGHT_ARROW "lb.",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  293 */  { fnCvtLbKg,                    multiply,                    "lb." STD_RIGHT_ARROW "kg",                    "lb." STD_RIGHT_ARROW "kg",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  294 */  { fnCvtOzG,                     divide,                      "g" STD_RIGHT_ARROW "oz",                      "g" STD_RIGHT_ARROW "oz",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  295 */  { fnCvtOzG,                     multiply,                    "oz" STD_RIGHT_ARROW "g",                      "oz" STD_RIGHT_ARROW "g",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  296 */  { fnCvtShortcwtKg,              divide,                      "kg" STD_RIGHT_ARROW "short cwt",              "kg" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  297 */  { itemToBeCoded,                NOPARAM,                     "0297",                                        "0297",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  298 */  { fnCvtShortcwtKg,              multiply,                    "short cwt" STD_RIGHT_ARROW "kg",              "short cwt" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  299 */  { itemToBeCoded,                NOPARAM,                     "0299",                                        "0299",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  300 */  { fnCvtStoneKg,                 divide,                      "kg" STD_RIGHT_ARROW "stone",                  "kg" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  301 */  { itemToBeCoded,                NOPARAM,                     "0301",                                        "0301",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  302 */  { fnCvtStoneKg,                 multiply,                    "stone" STD_RIGHT_ARROW "kg",                  "stone" STD_RIGHT_ARROW,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  303 */  { itemToBeCoded,                NOPARAM,                     "0303",                                        "0303",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  304 */  { fnCvtShorttonKg,              divide,                      "kg" STD_RIGHT_ARROW "short ton",              "kg" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  305 */  { itemToBeCoded,                NOPARAM,                     "0305",                                        "0305",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  306 */  { itemToBeCoded,                NOPARAM,                     "0306",                                        "0306",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  307 */  { fnCvtShorttonKg,              multiply,                    "short ton" STD_RIGHT_ARROW "kg",              "short ton" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  308 */  { itemToBeCoded,                NOPARAM,                     "0308",                                        "0308",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  309 */  { itemToBeCoded,                NOPARAM,                     "0309",                                        "0309",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  310 */  { fnCvtTonKg,                   divide,                      "kg" STD_RIGHT_ARROW "ton",                    "kg" STD_RIGHT_ARROW "ton",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  311 */  { fnCvtLiangKg,                 multiply,                    "kg" STD_RIGHT_ARROW "li" STD_a_BREVE "ng",    "kg" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  312 */  { itemToBeCoded,                NOPARAM,                     "0312",                                        "0312",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  313 */  { fnCvtTonKg,                   multiply,                    "ton" STD_RIGHT_ARROW "kg",                    "ton" STD_RIGHT_ARROW "kg",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  314 */  { fnCvtLiangKg,                 divide,                      "li" STD_a_BREVE "ng" STD_RIGHT_ARROW "kg",    "li" STD_a_BREVE "ng" STD_RIGHT_ARROW,         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  315 */  { itemToBeCoded,                NOPARAM,                     "0315",                                        "0315",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  316 */  { fnCvtTrozG,                   divide,                      "g" STD_RIGHT_ARROW "tr.oz",                   "g" STD_RIGHT_ARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  317 */  { itemToBeCoded,                NOPARAM,                     "0317",                                        "0317",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  318 */  { fnCvtTrozG,                   multiply,                    "tr.oz" STD_RIGHT_ARROW "g",                   "tr.oz" STD_RIGHT_ARROW,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  319 */  { itemToBeCoded,                NOPARAM,                     "0319",                                        "0319",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  320 */  { fnCvtLbfN,                    multiply,                    "lbf" STD_RIGHT_ARROW "N",                     "lbf" STD_RIGHT_ARROW "N",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  321 */  { fnCvtLbfN,                    divide,                      "N" STD_RIGHT_ARROW "lbf",                     "N" STD_RIGHT_ARROW "lbf",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  322 */  { fnCvtLyM,                     multiply,                    "l.y." STD_RIGHT_ARROW "m",                    "l.y." STD_RIGHT_ARROW "m",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  323 */  { fnCvtLyM,                     divide,                      "m" STD_RIGHT_ARROW "l.y.",                    "m" STD_RIGHT_ARROW "l.y.",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  324 */  { fnCvtMmhgPa,                  multiply,                    "mm.Hg" STD_RIGHT_ARROW "Pa",                  "mm.Hg" STD_RIGHT_ARROW,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  325 */  { itemToBeCoded,                NOPARAM,                     "0325",                                        "0325",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  326 */  { fnCvtMmhgPa,                  divide,                      "Pa" STD_RIGHT_ARROW "mm.Hg",                  "Pa" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  327 */  { itemToBeCoded,                NOPARAM,                     "0327",                                        "0327",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  328 */  { fnCvtMiKm,                    multiply,                    "mi." STD_RIGHT_ARROW "km",                    "mi." STD_RIGHT_ARROW "km",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  329 */  { fnCvtMiKm,                    divide,                      "km" STD_RIGHT_ARROW "mi.",                    "km" STD_RIGHT_ARROW "mi.",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  330 */  { fnCvtNmiKm,                   divide,                      "km" STD_RIGHT_ARROW "nmi",                    "km" STD_RIGHT_ARROW "nmi",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  331 */  { fnCvtNmiKm,                   multiply,                    "nmi" STD_RIGHT_ARROW "km",                    "nmi" STD_RIGHT_ARROW "km",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  332 */  { fnCvtPcM,                     divide,                      "m" STD_RIGHT_ARROW "pc",                      "m" STD_RIGHT_ARROW "pc",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  333 */  { fnCvtPcM,                     multiply,                    "pc" STD_RIGHT_ARROW "m",                      "pc" STD_RIGHT_ARROW "m",                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  334 */  { fnCvtPointMm,                 divide,                      "mm" STD_RIGHT_ARROW "point",                  "mm" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  335 */  { itemToBeCoded,                NOPARAM,                     "0335",                                        "0335",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  336 */  { fnCvtMileM,                   multiply,                    "mi." STD_RIGHT_ARROW "m",                     "mi." STD_RIGHT_ARROW "m",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  337 */  { fnCvtPointMm,                 multiply,                    "point" STD_RIGHT_ARROW "mm",                  "point" STD_RIGHT_ARROW,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  338 */  { itemToBeCoded,                NOPARAM,                     "0338",                                        "0338",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  339 */  { fnCvtMileM,                   divide,                      "m" STD_RIGHT_ARROW "mi.",                     "m" STD_RIGHT_ARROW "mi.",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  340 */  { fnCvtYardM,                   divide,                      "m" STD_RIGHT_ARROW "yd.",                     "m" STD_RIGHT_ARROW "yd.",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  341 */  { fnCvtYardM,                   multiply,                    "yd." STD_RIGHT_ARROW "m",                     "yd." STD_RIGHT_ARROW "m",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  342 */  { fnCvtPsiPa,                   multiply,                    "psi" STD_RIGHT_ARROW "Pa",                    "psi" STD_RIGHT_ARROW "Pa",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  343 */  { fnCvtPsiPa,                   divide,                      "Pa" STD_RIGHT_ARROW "psi",                    "Pa" STD_RIGHT_ARROW "psi",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  344 */  { fnCvtTorrPa,                  divide,                      "Pa" STD_RIGHT_ARROW "torr",                   "Pa" STD_RIGHT_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  345 */  { itemToBeCoded,                NOPARAM,                     "0345",                                        "0345",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  346 */  { fnCvtTorrPa,                  multiply,                    "torr" STD_RIGHT_ARROW "Pa",                   "torr" STD_RIGHT_ARROW,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  347 */  { itemToBeCoded,                NOPARAM,                     "0347",                                        "0347",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  348 */  { fnCvtYearS,                   divide,                      "s" STD_RIGHT_ARROW "year",                    "s" STD_RIGHT_ARROW "year",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  349 */  { fnCvtYearS,                   multiply,                    "year" STD_RIGHT_ARROW "s",                    "year" STD_RIGHT_ARROW "s",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  350 */  { fnCvtCaratG,                  multiply,                    "carat" STD_RIGHT_ARROW "g",                   "carat" STD_RIGHT_ARROW,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  351 */  { itemToBeCoded,                NOPARAM,                     "0351",                                        "0351",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  352 */  { fnCvtJinKg,                   divide,                      "j" STD_i_MACRON "n" STD_RIGHT_ARROW "kg",     "j" STD_i_MACRON "n" STD_RIGHT_ARROW "kg",     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  353 */  { fnCvtCaratG,                  divide,                      "g" STD_RIGHT_ARROW "carat",                   "g" STD_RIGHT_ARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  354 */  { itemToBeCoded,                NOPARAM,                     "0354",                                        "0354",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  355 */  { fnCvtJinKg,                   multiply,                    "kg" STD_RIGHT_ARROW "j" STD_i_MACRON "n",     "kg" STD_RIGHT_ARROW "j" STD_i_MACRON "n",     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  356 */  { fnCvtQuartL,                  multiply,                    "qt." STD_RIGHT_ARROW "l",                     "qt." STD_RIGHT_ARROW "l",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  357 */  { fnCvtQuartL,                  divide,                      "l" STD_RIGHT_ARROW "qt.",                     "l" STD_RIGHT_ARROW "qt.",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  358 */  { fnCvtFathomM,                 multiply,                    "fathom" STD_RIGHT_ARROW "m",                  "fathom" STD_RIGHT_ARROW,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  359 */  { itemToBeCoded,                NOPARAM,                     "0359",                                        "0359",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  360 */  { fnCvtNMiM,                    multiply,                    "nmi" STD_RIGHT_ARROW "m",                     "nmi" STD_RIGHT_ARROW "m",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  361 */  { fnCvtFathomM,                 divide,                      "m" STD_RIGHT_ARROW "fathom",                  "m" STD_RIGHT_ARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  362 */  { itemToBeCoded,                NOPARAM,                     "0362",                                        "0362",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  363 */  { fnCvtNMiM,                    divide,                      "m" STD_RIGHT_ARROW "nmi",                     "m" STD_RIGHT_ARROW "nmi",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  364 */  { fnCvtBarrelM3,                multiply,                    "barrel" STD_RIGHT_ARROW "m" STD_SUP_3,        "barrel" STD_RIGHT_ARROW,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  365 */  { itemToBeCoded,                NOPARAM,                     "0365",                                        "0365",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  366 */  { fnCvtBarrelM3,                divide,                      "m" STD_SUP_3 STD_RIGHT_ARROW "barrel",        "m" STD_SUP_3 STD_RIGHT_ARROW,                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  367 */  { itemToBeCoded,                NOPARAM,                     "0367",                                        "0367",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  368 */  { itemToBeCoded,                NOPARAM,                     "0368",                                        "0368",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  369 */  { itemToBeCoded,                NOPARAM,                     "0369",                                        "0369",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  370 */  { fnCvtHectareM2,               multiply,                    "ha" STD_RIGHT_ARROW "m" STD_SUP_2,            "ha" STD_RIGHT_ARROW "m" STD_SUP_2,            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  371 */  { fnCvtHectareM2,               divide,                      "m" STD_SUP_2 STD_RIGHT_ARROW "ha",            "m" STD_SUP_2 STD_RIGHT_ARROW "ha",            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  372 */  { fnCvtMuM2,                    divide,                      "m" STD_u_BREVE STD_RIGHT_ARROW "m" STD_SUP_2, "m" STD_u_BREVE STD_RIGHT_ARROW "m" STD_SUP_2, (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  373 */  { fnCvtMuM2,                    multiply,                    "m" STD_SUP_2 STD_RIGHT_ARROW "m" STD_u_BREVE, "m" STD_SUP_2 STD_RIGHT_ARROW "m" STD_u_BREVE, (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  374 */  { fnCvtLiM,                     multiply,                    "l" STD_i_BREVE STD_RIGHT_ARROW "m",           "l" STD_i_BREVE STD_RIGHT_ARROW "m",           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  375 */  { fnCvtLiM,                     divide,                      "m" STD_RIGHT_ARROW "l" STD_i_BREVE,           "m" STD_RIGHT_ARROW "l" STD_i_BREVE,           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  376 */  { fnCvtChiM,                    divide,                      "ch" STD_i_BREVE STD_RIGHT_ARROW "m",          "ch" STD_i_BREVE STD_RIGHT_ARROW "m",          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  377 */  { fnCvtChiM,                    multiply,                    "m" STD_RIGHT_ARROW "ch" STD_i_BREVE,          "m" STD_RIGHT_ARROW "ch" STD_i_BREVE,          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  378 */  { fnCvtYinM,                    divide,                      "y" STD_i_BREVE "n" STD_RIGHT_ARROW "m",       "y" STD_i_BREVE "n" STD_RIGHT_ARROW "m",       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  379 */  { fnCvtYinM,                    multiply,                    "m" STD_RIGHT_ARROW "y" STD_i_BREVE "n",       "m" STD_RIGHT_ARROW "y" STD_i_BREVE "n",       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  380 */  { fnCvtCunM,                    divide,                      "c" STD_u_GRAVE "n" STD_RIGHT_ARROW "m",       "c" STD_u_GRAVE "n" STD_RIGHT_ARROW "m",       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  381 */  { fnCvtCunM,                    multiply,                    "m" STD_RIGHT_ARROW "c" STD_u_GRAVE "n",       "m" STD_RIGHT_ARROW "c" STD_u_GRAVE "n",       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  382 */  { fnCvtZhangM,                  divide,                      "zh" STD_a_GRAVE "ng" STD_RIGHT_ARROW "m",     "zh" STD_a_GRAVE "ng" STD_RIGHT_ARROW,         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  383 */  { itemToBeCoded,                NOPARAM,                     "0383",                                        "0383",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  384 */  { fnCvtZhangM,                  multiply,                    "m" STD_RIGHT_ARROW "zh" STD_a_GRAVE "ng",     "m" STD_RIGHT_ARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  385 */  { itemToBeCoded,                NOPARAM,                     "0385",                                        "0385",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  386 */  { fnCvtFenM,                    divide,                      "f" STD_e_MACRON "n" STD_RIGHT_ARROW "m",      "f" STD_e_MACRON "n" STD_RIGHT_ARROW "m",      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  387 */  { fnCvtFenM,                    multiply,                    "m" STD_RIGHT_ARROW "f" STD_e_MACRON "n",      "m" STD_RIGHT_ARROW "f" STD_e_MACRON "n",      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  388 */  { fnCvtMi2Km2,                  multiply,                    "mi" STD_SUP_2 STD_RIGHT_ARROW "km" STD_SUP_2, "mi" STD_SUP_2 STD_RIGHT_ARROW "km" STD_SUP_2, (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  389 */  { fnCvtMi2Km2,                  divide,                      "km" STD_SUP_2 STD_RIGHT_ARROW "mi" STD_SUP_2, "km" STD_SUP_2 STD_RIGHT_ARROW "mi" STD_SUP_2, (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  390 */  { fnCvtNmi2Km2,                 multiply,                    "nmi" STD_SUP_2 STD_RIGHT_ARROW "km" STD_SUP_2, "nmi" STD_SUP_2 STD_RIGHT_ARROW "km" STD_SUP_2, (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  391 */  { fnCvtNmi2Km2,                 divide,                      "km" STD_SUP_2 STD_RIGHT_ARROW "nmi" STD_SUP_2, "km" STD_SUP_2 STD_RIGHT_ARROW "nmi" STD_SUP_2, (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  392 */  { itemToBeCoded,                NOPARAM,                     "0392",                                        "0392",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  393 */  { itemToBeCoded,                NOPARAM,                     "0393",                                        "0393",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  394 */  { itemToBeCoded,                NOPARAM,                     "0394",                                        "0394",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  395 */  { itemToBeCoded,                NOPARAM,                     "0395",                                        "0395",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Flag, bit, rotation, and logical OPs
/*  396 */  { fnIsFlagClearClear,           TM_FLAGW,                    "FC?C",                                        "FC?C",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  397 */  { fnIsFlagClearSet,             TM_FLAGW,                    "FC?S",                                        "FC?S",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  398 */  { fnIsFlagClearFlip,            TM_FLAGW,                    "FC?F",                                        "FC?F",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  399 */  { fnIsFlagSetClear,             TM_FLAGW,                    "FS?C",                                        "FS?C",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  400 */  { fnIsFlagSetSet,               TM_FLAGW,                    "FS?S",                                        "FS?S",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  401 */  { fnIsFlagSetFlip,              TM_FLAGW,                    "FS?F",                                        "FS?F",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_FLAG         },
/*  402 */  { fnLogicalNand,                NOPARAM,                     "NAND",                                        "NAND",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  403 */  { fnLogicalNor,                 NOPARAM,                     "NOR",                                         "NOR",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  404 */  { fnLogicalXnor,                NOPARAM,                     "XNOR",                                        "XNOR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  405 */  { fnBs,                         TM_VALUE,                    "BS?",                                         "BS?",                                         (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  406 */  { fnBc,                         TM_VALUE,                    "BC?",                                         "BC?",                                         (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  407 */  { fnCb,                         TM_VALUE,                    "CB",                                          "CB",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  408 */  { fnSb,                         TM_VALUE,                    "SB",                                          "SB",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  409 */  { fnFb,                         TM_VALUE,                    "FB",                                          "FB",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  410 */  { fnRl,                         TM_VALUE,                    "RL",                                          "RL",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  411 */  { fnRlc,                        TM_VALUE,                    "RLC",                                         "RLC",                                         (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  412 */  { fnRr,                         TM_VALUE,                    "RR",                                          "RR",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  413 */  { fnRrc,                        TM_VALUE,                    "RRC",                                         "RRC",                                         (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  414 */  { fnSl,                         TM_VALUE,                    "SL",                                          "SL",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  415 */  { fnSr,                         TM_VALUE,                    "SR",                                          "SR",                                          (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  416 */  { fnAsr,                        TM_VALUE,                    "ASR",                                         "ASR",                                         (0 << TAM_MAX_BITS) |    63, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  417 */  { fnLj,                         NOPARAM,                     "LJ",                                          "LJ",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  418 */  { fnRj,                         NOPARAM,                     "RJ",                                          "RJ",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  419 */  { fnMaskl,                      TM_VALUE,                    "MASKL",                                       "MASKL",                                       (0 << TAM_MAX_BITS) |    64, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  420 */  { fnMaskr,                      TM_VALUE,                    "MASKR",                                       "MASKR",                                       (0 << TAM_MAX_BITS) |    64, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  421 */  { fnMirror,                     NOPARAM,                     "MIRROR",                                      "MIRROR",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  422 */  { fnCountBits,                  NOPARAM,                     "#B",                                          "#B",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  423 */  { fnSdl,                        TM_VALUE,                    "SDL",                                         "SDL",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  424 */  { fnSdr,                        TM_VALUE,                    "SDR",                                         "SDR",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/*  425 */  { itemToBeCoded,                NOPARAM,                     "0425",                                        "0425",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  426 */  { itemToBeCoded,                NOPARAM,                     "0426",                                        "0426",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  427 */  { itemToBeCoded,                NOPARAM,                     "0427",                                        "0427",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  428 */  { itemToBeCoded,                NOPARAM,                     "0428",                                        "0428",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  429 */  { itemToBeCoded,                NOPARAM,                     "0429",                                        "0429",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  430 */  { itemToBeCoded,                NOPARAM,                     "0430",                                        "0430",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  431 */  { itemToBeCoded,                NOPARAM,                     "0431",                                        "0431",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  432 */  { itemToBeCoded,                NOPARAM,                     "0432",                                        "0432",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Statistical sums
/*  433 */  { fnSigma,                      1,                           STD_SIGMA "+",                                 STD_SIGMA "+",                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_DISABLED  | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  434 */  { fnSigma,                      2,                           STD_SIGMA "-",                                 STD_SIGMA "-",                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_DISABLED  | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  435 */  { fnStatSum,                    0,                           "n" STD_SIGMA,                                 "n",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  436 */  { fnStatSum,                    SUM_X,                       STD_SIGMA "x",                                 STD_SIGMA "x",                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  437 */  { fnStatSum,                    SUM_Y,                       STD_SIGMA "y",                                 STD_SIGMA "y",                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  438 */  { fnStatSum,                    SUM_X2,                      STD_SIGMA "x" STD_SUP_2,                       STD_SIGMA "x" STD_SUP_2,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  439 */  { fnStatSum,                    SUM_X2Y,                     STD_SIGMA "x" STD_SUP_2 "y",                   STD_SIGMA "x" STD_SUP_2 "y",                   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  440 */  { fnStatSum,                    SUM_Y2,                      STD_SIGMA "y" STD_SUP_2,                       STD_SIGMA "y" STD_SUP_2,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  441 */  { fnStatSum,                    SUM_XY,                      STD_SIGMA "xy",                                STD_SIGMA "xy",                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  442 */  { fnStatSum,                    SUM_lnXlnY,                  STD_SIGMA "lnx" STD_DOT STD_SPACE_6_PER_EM "lny", STD_SIGMA "lnx" STD_DOT STD_SPACE_6_PER_EM "lny", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  443 */  { fnStatSum,                    SUM_lnX,                     STD_SIGMA "lnx",                               STD_SIGMA "lnx",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  444 */  { fnStatSum,                    SUM_ln2X,                    STD_SIGMA "ln" STD_SUP_2 "x",                  STD_SIGMA "ln" STD_SUP_2 "x",                  (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  445 */  { fnStatSum,                    SUM_YlnX,                    STD_SIGMA "y" STD_DOT STD_SPACE_6_PER_EM "lnx", STD_SIGMA "y" STD_DOT STD_SPACE_6_PER_EM "lnx", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  446 */  { fnStatSum,                    SUM_lnY,                     STD_SIGMA "lny",                               STD_SIGMA "lny",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  447 */  { fnStatSum,                    SUM_ln2Y,                    STD_SIGMA "ln" STD_SUP_2 "y",                  STD_SIGMA "ln" STD_SUP_2 "y",                  (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  448 */  { fnStatSum,                    SUM_XlnY,                    STD_SIGMA "x" STD_DOT STD_SPACE_6_PER_EM "lny", STD_SIGMA "x" STD_DOT STD_SPACE_6_PER_EM "lny", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  449 */  { fnStatSum,                    SUM_X2lnY,                   STD_SIGMA "x" STD_SUP_2 STD_DOT STD_SPACE_6_PER_EM "lny", STD_SIGMA "x" STD_SUP_2 STD_DOT STD_SPACE_6_PER_EM "lny", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  450 */  { fnStatSum,                    SUM_lnYonX,                  STD_SIGMA "x" STD_SUP_MINUS STD_SUP_1 STD_DOT STD_SPACE_6_PER_EM "lny", STD_SIGMA "x" STD_SUP_MINUS STD_SUP_1 STD_DOT STD_SPACE_6_PER_EM "lny", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  451 */  { fnStatSum,                    SUM_X2onY,                   STD_SIGMA "x" STD_SUP_2 "y" STD_SUP_MINUS STD_SUP_1, STD_SIGMA "x" STD_SUP_2 "y" STD_SUP_MINUS STD_SUP_1, (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  452 */  { fnStatSum,                    SUM_1onX,                    STD_SIGMA "x" STD_SUP_MINUS STD_SUP_1,         STD_SIGMA "x" STD_SUP_MINUS STD_SUP_1,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  453 */  { fnStatSum,                    SUM_1onX2,                   STD_SIGMA "x" STD_SUP_MINUS STD_SUP_2,         STD_SIGMA "x" STD_SUP_MINUS STD_SUP_2,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  454 */  { fnStatSum,                    SUM_XonY,                    STD_SIGMA "xy" STD_SUP_MINUS STD_SUP_1,        STD_SIGMA "xy" STD_SUP_MINUS STD_SUP_1,        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  455 */  { fnStatSum,                    SUM_1onY,                    STD_SIGMA "y" STD_SUP_MINUS STD_SUP_1,         STD_SIGMA "y" STD_SUP_MINUS STD_SUP_1,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  456 */  { fnStatSum,                    SUM_1onY2,                   STD_SIGMA "y" STD_SUP_MINUS STD_SUP_2,         STD_SIGMA "y" STD_SUP_MINUS STD_SUP_2,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  457 */  { fnStatSum,                    SUM_X3,                      STD_SIGMA "x" STD_SUP_3,                       STD_SIGMA "x" STD_SUP_3,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  458 */  { fnStatSum,                    SUM_X4,                      STD_SIGMA "x" STD_SUP_4,                       STD_SIGMA "x" STD_SUP_4,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/*  459 */  { itemToBeCoded,                NOPARAM,                     "0459",                                        "0459",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  460 */  { itemToBeCoded,                NOPARAM,                     "0460",                                        "0460",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  461 */  { itemToBeCoded,                NOPARAM,                     "0461",                                        "0461",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  462 */  { itemToBeCoded,                NOPARAM,                     "0462",                                        "0462",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// System flags
/*  463 */  { fnGetSystemFlag,              FLAG_TDM24,                  "TDM24",                                       "TDM24",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // The system flags,
/*  464 */  { fnGetSystemFlag,              FLAG_YMD,                    "YMD",                                         "YMD",                                         (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // items from 453 to 493,
/*  465 */  { fnGetSystemFlag,              FLAG_DMY,                    "DMY",                                         "DMY",                                         (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // MUST be in the same
/*  466 */  { fnGetSystemFlag,              FLAG_MDY,                    "MDY",                                         "MDY",                                         (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // order as the flag
/*  467 */  { fnGetSystemFlag,              FLAG_CPXRES,                 "CPXRES",                                      "CPXRES",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // number (8 LSB) defined
/*  468 */  { fnGetSystemFlag,              FLAG_CPXj,                   "CPX" STD_op_j,                                "CPX" STD_op_j,                                (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // in defines.h
/*  469 */  { fnGetSystemFlag,              FLAG_POLAR,                  "POLAR",                                       "POLAR",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  470 */  { fnGetSystemFlag,              FLAG_FRACT,                  "FRACT",                                       "FRACT",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // And TDM24 MUST be
/*  471 */  { fnGetSystemFlag,              FLAG_PROPFR,                 "PROPFR",                                      "PROPFR",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // the first.
/*  472 */  { fnGetSystemFlag,              FLAG_DENANY,                 "DENANY",                                      "DENANY",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  473 */  { fnGetSystemFlag,              FLAG_DENFIX,                 "DENFIX",                                      "DENFIX",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  474 */  { fnGetSystemFlag,              FLAG_CARRY,                  "CARRY",                                       "CARRY",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  475 */  { fnGetSystemFlag,              FLAG_OVERFLOW,               "OVERFL",                                      "OVERFL",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  476 */  { fnGetSystemFlag,              FLAG_LEAD0,                  "LEAD.0",                                      "LEAD.0",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  477 */  { fnGetSystemFlag,              FLAG_ALPHA,                  "ALPHA",                                       "ALPHA",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  478 */  { fnGetSystemFlag,              FLAG_alphaCAP,               STD_alpha "CAP",                               STD_alpha "CAP",                               (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  479 */  { fnGetSystemFlag,              FLAG_RUNTIM,                 "RUNTIM",                                      "RUNTIM",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  480 */  { fnGetSystemFlag,              FLAG_RUNIO,                  "RUNIO",                                       "RUNIO",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  481 */  { fnGetSystemFlag,              FLAG_PRINTS,                 "PRINTS",                                      "PRINTS",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  482 */  { fnGetSystemFlag,              FLAG_TRACE,                  "TRACE",                                       "TRACE",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  483 */  { fnGetSystemFlag,              FLAG_USER,                   "USER",                                        "USER",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  484 */  { fnGetSystemFlag,              FLAG_LOWBAT,                 "LOWBAT",                                      "LOWBAT",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  485 */  { fnGetSystemFlag,              FLAG_SLOW,                   "SLOW",                                        "SLOW",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  486 */  { fnGetSystemFlag,              FLAG_SPCRES,                 "SPCRES",                                      "SPCRES",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  487 */  { fnGetSystemFlag,              FLAG_SSIZE8,                 "SSIZE8",                                      "SSIZE8",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  488 */  { fnGetSystemFlag,              FLAG_QUIET,                  "QUIET",                                       "QUIET",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  489 */  { itemToBeCoded,                NOPARAM,                     "0489",                                        "0489",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  490 */  { fnGetSystemFlag,              FLAG_MULTx,                  "MULT" STD_CROSS,                              "MULT" STD_CROSS,                              (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  491 */  { fnGetSystemFlag,              FLAG_ALLENG,                 "ALLENG",                                      "ALLENG",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  492 */  { fnGetSystemFlag,              FLAG_GROW,                   "GROW",                                        "GROW",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  493 */  { fnGetSystemFlag,              FLAG_AUTOFF,                 "AUTOFF",                                      "AUTOFF",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  494 */  { fnGetSystemFlag,              FLAG_AUTXEQ,                 "AUTXEQ",                                      "AUTXEQ",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  495 */  { fnGetSystemFlag,              FLAG_PRTACT,                 "PRTACT",                                      "PRTACT",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  496 */  { fnGetSystemFlag,              FLAG_NUMIN,                  "NUM.IN",                                      "NUM.IN",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  497 */  { fnGetSystemFlag,              FLAG_ALPIN,                  "ALP.IN",                                      "ALP.IN",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  498 */  { fnGetSystemFlag,              FLAG_ASLIFT,                 "ASLIFT",                                      "ASLIFT",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  499 */  { fnGetSystemFlag,              FLAG_IGN1ER,                 "IGN1ER",                                      "IGN1ER",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  500 */  { fnGetSystemFlag,              FLAG_INTING,                 "INTING",                                      "INTING",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  501 */  { fnGetSystemFlag,              FLAG_SOLVING,                "SOLVING",                                     "SOLVING",                                     (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  502 */  { fnGetSystemFlag,              FLAG_VMDISP,                 "VMDISP",                                      "VMDISP",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  503 */  { fnGetSystemFlag,              FLAG_USB,                    "USB",                                         "USB",                                         (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  504 */  { fnGetSystemFlag,              FLAG_ENDPMT,                 "ENDPMT",                                      "ENDPMT",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  505 */  { fnGetSystemFlag,              FLAG_FRCSRN,                 "FRCSRN",                                      "FRCSRN",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  506 */  { fnGetSystemFlag,              FLAG_HPRP,                   "RP" STD_SUB_H STD_SUB_P,                      "RP" STD_SUB_H STD_SUB_P,                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  507 */  { fnGetSystemFlag,              FLAG_SBdate,                 "SBdate",                                      "SBdate",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  508 */  { fnGetSystemFlag,              FLAG_SBtime,                 "SBtime",                                      "SBtime",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  509 */  { fnGetSystemFlag,              FLAG_SBcr,                   "SBcr",                                        "SBcr",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  510 */  { fnGetSystemFlag,              FLAG_SBcpx,                  "SBcpx",                                       "SBcpx",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  511 */  { fnGetSystemFlag,              FLAG_SBang,                  "SBang",                                       "SBang",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  512 */  { fnGetSystemFlag,              FLAG_SBfrac,                 "SBfrac",                                      "SBfrac",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  513 */  { fnGetSystemFlag,              FLAG_SBint,                  "SBint",                                       "SBint",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  514 */  { fnGetSystemFlag,              FLAG_SBmx,                   "SBmx",                                        "SBmx",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  515 */  { fnGetSystemFlag,              FLAG_SBtvm,                  "SBtvm",                                       "SBtvm",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  516 */  { fnGetSystemFlag,              FLAG_SBoc,                   "SBoc",                                        "SBoc",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  517 */  { fnGetSystemFlag,              FLAG_SBss,                   "SBss",                                        "SBss",                                        (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  518 */  { fnGetSystemFlag,              FLAG_SBclk,                  "SBclk",                                       "SBclk",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  519 */  { fnGetSystemFlag,              FLAG_SBser,                  "SBser",                                       "SBser",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  520 */  { fnGetSystemFlag,              FLAG_SBprn,                  "SBprn",                                       "SBprn",                                       (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  521 */  { fnGetSystemFlag,              FLAG_SBbatV,                 "SBbatV",                                      "SBbatV",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  522 */  { fnGetSystemFlag,              FLAG_SBshfR,                 "SBshfR",                                      "SBshfR",                                      (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  523 */  { fnGetSystemFlag,              FLAG_HPBASE,                 "BASE" STD_SUB_H STD_SUB_P,                    "BASE" STD_SUB_H STD_SUB_P,                    (0 << TAM_MAX_BITS) |     0, CAT_SYFL | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  524 */  { itemToBeCoded,                NOPARAM,                     "0524",                                        "0524",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  525 */  { itemToBeCoded,                NOPARAM,                     "0525",                                        "0525",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  526 */  { itemToBeCoded,                NOPARAM,                     "0526",                                        "0526",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Bufferized items
/*  527 */  { addItemToBuffer,              REGISTER_X,                  "X",                                           "X",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // The
/*  528 */  { addItemToBuffer,              REGISTER_Y,                  "Y",                                           "Y",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // order
/*  529 */  { addItemToBuffer,              REGISTER_Z,                  "Z",                                           "Z",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // of these
/*  530 */  { addItemToBuffer,              REGISTER_T,                  "T",                                           "T",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // 12 lines
/*  531 */  { addItemToBuffer,              REGISTER_A,                  "A",                                           "A",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Must be
/*  532 */  { addItemToBuffer,              REGISTER_B,                  "B",                                           "B",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // kept as
/*  533 */  { addItemToBuffer,              REGISTER_C,                  "C",                                           "C",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // is.
/*  534 */  { addItemToBuffer,              REGISTER_D,                  "D",                                           "D",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Do not
/*  535 */  { addItemToBuffer,              REGISTER_L,                  "L",                                           "L",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // put them
/*  536 */  { addItemToBuffer,              REGISTER_I,                  "I",                                           "I",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // in a
/*  537 */  { addItemToBuffer,              REGISTER_J,                  "J",                                           "J",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // different
/*  538 */  { addItemToBuffer,              REGISTER_K,                  "K",                                           "K",                                           (0 << TAM_MAX_BITS) |     0, CAT_REGS | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // order!
/*  539 */  { addItemToBuffer,              ITM_INDIRECTION,             STD_RIGHT_ARROW,                               STD_RIGHT_ARROW,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  540 */  { addItemToBuffer,              ITM_0,                       "",                                            "0",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  541 */  { addItemToBuffer,              ITM_1,                       "",                                            "1",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  542 */  { addItemToBuffer,              ITM_2,                       "",                                            "2",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  543 */  { addItemToBuffer,              ITM_3,                       "",                                            "3",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  544 */  { addItemToBuffer,              ITM_4,                       "",                                            "4",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  545 */  { addItemToBuffer,              ITM_5,                       "",                                            "5",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  546 */  { addItemToBuffer,              ITM_6,                       "",                                            "6",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  547 */  { addItemToBuffer,              ITM_7,                       "",                                            "7",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  548 */  { addItemToBuffer,              ITM_8,                       "",                                            "8",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  549 */  { addItemToBuffer,              ITM_9,                       "",                                            "9",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  550 */  { addItemToBuffer,              ITM_A,                       "A",                                           "A",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  551 */  { addItemToBuffer,              ITM_B,                       "B",                                           "B",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  552 */  { addItemToBuffer,              ITM_C,                       "C",                                           "C",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  553 */  { addItemToBuffer,              ITM_D,                       "D",                                           "D",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  554 */  { addItemToBuffer,              ITM_E,                       "E",                                           "E",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  555 */  { addItemToBuffer,              ITM_F,                       "F",                                           "F",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  556 */  { addItemToBuffer,              ITM_G,                       "G",                                           "G",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  557 */  { addItemToBuffer,              ITM_H,                       "H",                                           "H",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  558 */  { addItemToBuffer,              ITM_I,                       "I",                                           "I",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  559 */  { addItemToBuffer,              ITM_J,                       "J",                                           "J",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  560 */  { addItemToBuffer,              ITM_K,                       "K",                                           "K",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  561 */  { addItemToBuffer,              ITM_L,                       "L",                                           "L",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  562 */  { addItemToBuffer,              ITM_M,                       "M",                                           "M",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  563 */  { addItemToBuffer,              ITM_N,                       "N",                                           "N",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  564 */  { addItemToBuffer,              ITM_O,                       "O",                                           "O",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  565 */  { addItemToBuffer,              ITM_P,                       "P",                                           "P",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  566 */  { addItemToBuffer,              ITM_Q,                       "Q",                                           "Q",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  567 */  { addItemToBuffer,              ITM_R,                       "R",                                           "R",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  568 */  { addItemToBuffer,              ITM_S,                       "S",                                           "S",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  569 */  { addItemToBuffer,              ITM_T,                       "T",                                           "T",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  570 */  { addItemToBuffer,              ITM_U,                       "U",                                           "U",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  571 */  { addItemToBuffer,              ITM_V,                       "V",                                           "V",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  572 */  { addItemToBuffer,              ITM_W,                       "W",                                           "W",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  573 */  { addItemToBuffer,              ITM_X,                       "X",                                           "X",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  574 */  { addItemToBuffer,              ITM_Y,                       "Y",                                           "Y",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  575 */  { addItemToBuffer,              ITM_Z,                       "Z",                                           "Z",                                           (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  576 */  { addItemToBuffer,              ITM_a,                       "a",                                           "a",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  577 */  { addItemToBuffer,              ITM_b,                       "b",                                           "b",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  578 */  { addItemToBuffer,              ITM_c,                       "c",                                           "c",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  579 */  { addItemToBuffer,              ITM_d,                       "d",                                           "d",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  580 */  { addItemToBuffer,              ITM_e,                       "e",                                           "e",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  581 */  { addItemToBuffer,              ITM_f,                       "f",                                           "f",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  582 */  { addItemToBuffer,              ITM_g,                       "g",                                           "g",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  583 */  { addItemToBuffer,              ITM_h,                       "h",                                           "h",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  584 */  { addItemToBuffer,              ITM_i,                       "i",                                           "i",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  585 */  { addItemToBuffer,              ITM_j,                       "j",                                           "j",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  586 */  { addItemToBuffer,              ITM_k,                       "k",                                           "k",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  587 */  { addItemToBuffer,              ITM_l,                       "l",                                           "l",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  588 */  { addItemToBuffer,              ITM_m,                       "m",                                           "m",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  589 */  { addItemToBuffer,              ITM_n,                       "n",                                           "n",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  590 */  { addItemToBuffer,              ITM_o,                       "o",                                           "o",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  591 */  { addItemToBuffer,              ITM_p,                       "p",                                           "p",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  592 */  { addItemToBuffer,              ITM_q,                       "q",                                           "q",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  593 */  { addItemToBuffer,              ITM_r,                       "r",                                           "r",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  594 */  { addItemToBuffer,              ITM_s,                       "s",                                           "s",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  595 */  { addItemToBuffer,              ITM_t,                       "t",                                           "t",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  596 */  { addItemToBuffer,              ITM_u,                       "u",                                           "u",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  597 */  { addItemToBuffer,              ITM_v,                       "v",                                           "v",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  598 */  { addItemToBuffer,              ITM_w,                       "w",                                           "w",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  599 */  { addItemToBuffer,              ITM_x,                       "x",                                           "x",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  600 */  { addItemToBuffer,              ITM_y,                       "y",                                           "y",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  601 */  { addItemToBuffer,              ITM_z,                       "z",                                           "z",                                           (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  602 */  { addItemToBuffer,              ITM_ALPHA,                   "",                                            STD_ALPHA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  603 */  { addItemToBuffer,              ITM_BETA,                    "",                                            STD_BETA,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  604 */  { addItemToBuffer,              ITM_GAMMA,                   "",                                            STD_GAMMA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  605 */  { addItemToBuffer,              ITM_DELTA,                   "",                                            STD_DELTA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  606 */  { addItemToBuffer,              ITM_EPSILON,                 "",                                            STD_EPSILON,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  607 */  { addItemToBuffer,              ITM_ZETA,                    "",                                            STD_ZETA,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  608 */  { addItemToBuffer,              ITM_ETA,                     "",                                            STD_ETA,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  609 */  { addItemToBuffer,              ITM_THETA,                   "",                                            STD_THETA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  610 */  { addItemToBuffer,              ITM_IOTA,                    "",                                            STD_IOTA,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  611 */  { addItemToBuffer,              ITM_IOTA_DIALYTIKA,          "",                                            STD_IOTA_DIALYTIKA,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  612 */  { addItemToBuffer,              ITM_KAPPA,                   "",                                            STD_KAPPA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  613 */  { addItemToBuffer,              ITM_LAMBDA,                  "",                                            STD_LAMBDA,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  614 */  { addItemToBuffer,              ITM_MU,                      "",                                            STD_MU,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  615 */  { addItemToBuffer,              ITM_NU,                      "",                                            STD_NU,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  616 */  { addItemToBuffer,              ITM_XI,                      "",                                            STD_XI,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  617 */  { addItemToBuffer,              ITM_OMICRON,                 "",                                            STD_OMICRON,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  618 */  { addItemToBuffer,              ITM_PI,                      "",                                            STD_PI,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  619 */  { addItemToBuffer,              ITM_RHO,                     "",                                            STD_RHO,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  620 */  { addItemToBuffer,              ITM_SIGMA,                   "",                                            STD_SIGMA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  621 */  { addItemToBuffer,              ITM_TAU,                     "",                                            STD_TAU,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  622 */  { addItemToBuffer,              ITM_UPSILON,                 "",                                            STD_UPSILON,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  623 */  { addItemToBuffer,              ITM_UPSILON_DIALYTIKA,       "",                                            STD_UPSILON_DIALYTIKA,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  624 */  { addItemToBuffer,              ITM_PHI,                     "",                                            STD_PHI,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  625 */  { addItemToBuffer,              ITM_CHI,                     "",                                            STD_CHI,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  626 */  { addItemToBuffer,              ITM_PSI,                     "",                                            STD_PSI,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  627 */  { addItemToBuffer,              ITM_OMEGA,                   "",                                            STD_OMEGA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  628 */  { addItemToBuffer,              ITM_alpha,                   "",                                            STD_alpha,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  629 */  { addItemToBuffer,              ITM_beta,                    "",                                            STD_beta,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  630 */  { addItemToBuffer,              ITM_gamma,                   "",                                            STD_gamma,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  631 */  { addItemToBuffer,              ITM_delta,                   "",                                            STD_delta,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  632 */  { addItemToBuffer,              ITM_epsilon,                 "",                                            STD_epsilon,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  633 */  { addItemToBuffer,              ITM_zeta,                    "",                                            STD_zeta,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  634 */  { addItemToBuffer,              ITM_eta,                     "",                                            STD_eta,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  635 */  { addItemToBuffer,              ITM_theta,                   "",                                            STD_theta,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  636 */  { addItemToBuffer,              ITM_iota,                    "",                                            STD_iota,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  637 */  { addItemToBuffer,              ITM_iota_DIALYTIKA,          "",                                            STD_iota_DIALYTIKA,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  638 */  { addItemToBuffer,              ITM_kappa,                   "",                                            STD_kappa,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  639 */  { addItemToBuffer,              ITM_lambda,                  "",                                            STD_lambda,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  640 */  { addItemToBuffer,              ITM_mu,                      "",                                            STD_mu,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  641 */  { addItemToBuffer,              ITM_nu,                      "",                                            STD_nu,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  642 */  { addItemToBuffer,              ITM_xi,                      "",                                            STD_xi,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  643 */  { addItemToBuffer,              ITM_omicron,                 "",                                            STD_omicron,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  644 */  { addItemToBuffer,              ITM_pi,                      "",                                            STD_pi,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  645 */  { addItemToBuffer,              ITM_rho,                     "",                                            STD_rho,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  646 */  { addItemToBuffer,              ITM_sigma,                   "",                                            STD_sigma,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  647 */  { addItemToBuffer,              ITM_tau,                     "",                                            STD_tau,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  648 */  { addItemToBuffer,              ITM_upsilon,                 "",                                            STD_upsilon,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  649 */  { addItemToBuffer,              ITM_upsilon_DIALYTIKA,       "",                                            STD_upsilon_DIALYTIKA,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  650 */  { addItemToBuffer,              ITM_phi,                     "",                                            STD_phi,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  651 */  { addItemToBuffer,              ITM_chi,                     "",                                            STD_chi,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  652 */  { addItemToBuffer,              ITM_psi,                     "",                                            STD_psi,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  653 */  { addItemToBuffer,              ITM_omega,                   "",                                            STD_omega,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  654 */  { addItemToBuffer,              ITM_alpha_TONOS,             "",                                            STD_alpha_TONOS,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  655 */  { addItemToBuffer,              ITM_epsilon_TONOS,           "",                                            STD_epsilon_TONOS,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  656 */  { addItemToBuffer,              ITM_eta_TONOS,               "",                                            STD_eta_TONOS,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  657 */  { addItemToBuffer,              ITM_iotaTON,                 "",                                            STD_iota_TONOS,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  658 */  { addItemToBuffer,              ITM_iota_DIALYTIKA_TONOS,    "",                                            STD_iota_DIALYTIKA_TONOS,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  659 */  { addItemToBuffer,              ITM_omicron_TONOS,           "",                                            STD_omicron_TONOS,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  660 */  { addItemToBuffer,              ITM_sigma_end,               "",                                            STD_sigma_end,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  661 */  { addItemToBuffer,              ITM_upsilon_TONOS,           "",                                            STD_upsilon_TONOS,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  662 */  { addItemToBuffer,              ITM_upsilon_DIALYTIKA_TONOS, "",                                            STD_upsilon_DIALYTIKA_TONOS,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  663 */  { addItemToBuffer,              ITM_omega_TONOS,             "",                                            STD_omega_TONOS,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  664 */  { addItemToBuffer,              ITM_A_MACRON,                STD_A_MACRON,                                  STD_A_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  665 */  { addItemToBuffer,              ITM_A_ACUTE,                 STD_A_ACUTE,                                   STD_A_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  666 */  { addItemToBuffer,              ITM_A_BREVE,                 STD_A_BREVE,                                   STD_A_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  667 */  { addItemToBuffer,              ITM_A_GRAVE,                 STD_A_GRAVE,                                   STD_A_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  668 */  { addItemToBuffer,              ITM_A_DIARESIS,              STD_A_DIARESIS,                                STD_A_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  669 */  { addItemToBuffer,              ITM_A_TILDE,                 STD_A_TILDE,                                   STD_A_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  670 */  { addItemToBuffer,              ITM_A_CIRC,                  STD_A_CIRC,                                    STD_A_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  671 */  { addItemToBuffer,              ITM_A_RING,                  STD_A_RING,                                    STD_A_RING,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  672 */  { addItemToBuffer,              ITM_AE,                      STD_AE,                                        STD_AE,                                        (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  673 */  { addItemToBuffer,              ITM_A_OGONEK,                STD_A_OGONEK,                                  STD_A_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  674 */  { addItemToBuffer,              ITM_C_ACUTE,                 STD_C_ACUTE,                                   STD_C_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  675 */  { addItemToBuffer,              ITM_C_CARON,                 STD_C_CARON,                                   STD_C_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  676 */  { addItemToBuffer,              ITM_C_CEDILLA,               STD_C_CEDILLA,                                 STD_C_CEDILLA,                                 (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  677 */  { addItemToBuffer,              ITM_D_STROKE,                STD_D_STROKE,                                  STD_D_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  678 */  { addItemToBuffer,              ITM_D_CARON,                 STD_D_CARON,                                   STD_D_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  679 */  { addItemToBuffer,              ITM_E_MACRON,                STD_E_MACRON,                                  STD_E_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  680 */  { addItemToBuffer,              ITM_E_ACUTE,                 STD_E_ACUTE,                                   STD_E_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  681 */  { addItemToBuffer,              ITM_E_BREVE,                 STD_E_BREVE,                                   STD_E_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  682 */  { addItemToBuffer,              ITM_E_GRAVE,                 STD_E_GRAVE,                                   STD_E_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  683 */  { addItemToBuffer,              ITM_E_DIARESIS,              STD_E_DIARESIS,                                STD_E_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  684 */  { addItemToBuffer,              ITM_E_CIRC,                  STD_E_CIRC,                                    STD_E_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  685 */  { addItemToBuffer,              ITM_E_OGONEK,                STD_E_OGONEK,                                  STD_E_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  686 */  { addItemToBuffer,              ITM_G_BREVE,                 STD_G_BREVE,                                   STD_G_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  687 */  { addItemToBuffer,              ITM_I_MACRON,                STD_I_MACRON,                                  STD_I_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  688 */  { addItemToBuffer,              ITM_I_ACUTE,                 STD_I_ACUTE,                                   STD_I_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  689 */  { addItemToBuffer,              ITM_I_BREVE,                 STD_I_BREVE,                                   STD_I_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  690 */  { addItemToBuffer,              ITM_I_GRAVE,                 STD_I_GRAVE,                                   STD_I_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  691 */  { addItemToBuffer,              ITM_I_DIARESIS,              STD_I_DIARESIS,                                STD_I_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  692 */  { addItemToBuffer,              ITM_I_CIRC,                  STD_I_CIRC,                                    STD_I_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  693 */  { addItemToBuffer,              ITM_I_OGONEK,                STD_I_OGONEK,                                  STD_I_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  694 */  { addItemToBuffer,              ITM_I_DOT,                   STD_I_DOT,                                     STD_I_DOT,                                     (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  695 */  { addItemToBuffer,              ITM_I_DOTLESS,               "I",                                           "I",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  696 */  { addItemToBuffer,              ITM_L_STROKE,                STD_L_STROKE,                                  STD_L_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  697 */  { addItemToBuffer,              ITM_L_ACUTE,                 STD_L_ACUTE,                                   STD_L_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  698 */  { addItemToBuffer,              ITM_L_APOSTROPHE,            STD_L_APOSTROPHE,                              STD_L_APOSTROPHE,                              (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  699 */  { addItemToBuffer,              ITM_N_ACUTE,                 STD_N_ACUTE,                                   STD_N_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  700 */  { addItemToBuffer,              ITM_N_CARON,                 STD_N_CARON,                                   STD_N_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  701 */  { addItemToBuffer,              ITM_N_TILDE,                 STD_N_TILDE,                                   STD_N_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  702 */  { addItemToBuffer,              ITM_O_MACRON,                STD_O_MACRON,                                  STD_O_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  703 */  { addItemToBuffer,              ITM_O_ACUTE,                 STD_O_ACUTE,                                   STD_O_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  704 */  { addItemToBuffer,              ITM_O_BREVE,                 STD_O_BREVE,                                   STD_O_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  705 */  { addItemToBuffer,              ITM_O_GRAVE,                 STD_O_GRAVE,                                   STD_O_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  706 */  { addItemToBuffer,              ITM_O_DIARESIS,              STD_O_DIARESIS,                                STD_O_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  707 */  { addItemToBuffer,              ITM_O_TILDE,                 STD_O_TILDE,                                   STD_O_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  708 */  { addItemToBuffer,              ITM_O_CIRC,                  STD_O_CIRC,                                    STD_O_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  709 */  { addItemToBuffer,              ITM_O_STROKE,                STD_O_STROKE,                                  STD_O_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  710 */  { addItemToBuffer,              ITM_OE,                      STD_OE,                                        STD_OE,                                        (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  711 */  { addItemToBuffer,              ITM_S_SHARP,                 STD_s_SHARP,                                   STD_s_SHARP,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  712 */  { addItemToBuffer,              ITM_S_ACUTE,                 STD_S_ACUTE,                                   STD_S_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  713 */  { addItemToBuffer,              ITM_S_CARON,                 STD_S_CARON,                                   STD_S_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  714 */  { addItemToBuffer,              ITM_S_CEDILLA,               STD_S_CEDILLA,                                 STD_S_CEDILLA,                                 (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  715 */  { addItemToBuffer,              ITM_T_CARON,                 STD_T_CARON,                                   STD_T_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  716 */  { addItemToBuffer,              ITM_T_CEDILLA,               STD_T_CEDILLA,                                 STD_T_CEDILLA,                                 (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  717 */  { addItemToBuffer,              ITM_U_MACRON,                STD_U_MACRON,                                  STD_U_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  718 */  { addItemToBuffer,              ITM_U_ACUTE,                 STD_U_ACUTE,                                   STD_U_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  719 */  { addItemToBuffer,              ITM_U_BREVE,                 STD_U_BREVE,                                   STD_U_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  720 */  { addItemToBuffer,              ITM_U_GRAVE,                 STD_U_GRAVE,                                   STD_U_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  721 */  { addItemToBuffer,              ITM_U_DIARESIS,              STD_U_DIARESIS,                                STD_U_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  722 */  { addItemToBuffer,              ITM_U_TILDE,                 STD_U_TILDE,                                   STD_U_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  723 */  { addItemToBuffer,              ITM_U_CIRC,                  STD_U_CIRC,                                    STD_U_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  724 */  { addItemToBuffer,              ITM_U_RING,                  STD_U_RING,                                    STD_U_RING,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  725 */  { addItemToBuffer,              ITM_W_CIRC,                  STD_W_CIRC,                                    STD_W_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  726 */  { addItemToBuffer,              ITM_Y_CIRC,                  STD_Y_CIRC,                                    STD_Y_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  727 */  { addItemToBuffer,              ITM_Y_ACUTE,                 STD_Y_ACUTE,                                   STD_Y_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  728 */  { addItemToBuffer,              ITM_Y_DIARESIS,              STD_Y_DIARESIS,                                STD_Y_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  729 */  { addItemToBuffer,              ITM_Z_ACUTE,                 STD_Z_ACUTE,                                   STD_Z_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  730 */  { addItemToBuffer,              ITM_Z_CARON,                 STD_Z_CARON,                                   STD_Z_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  731 */  { addItemToBuffer,              ITM_Z_DOT,                   STD_Z_DOT,                                     STD_Z_DOT,                                     (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  732 */  { addItemToBuffer,              ITM_a_MACRON,                STD_a_MACRON,                                  STD_a_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  733 */  { addItemToBuffer,              ITM_a_ACUTE,                 STD_a_ACUTE,                                   STD_a_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  734 */  { addItemToBuffer,              ITM_a_BREVE,                 STD_a_BREVE,                                   STD_a_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  735 */  { addItemToBuffer,              ITM_a_GRAVE,                 STD_a_GRAVE,                                   STD_a_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  736 */  { addItemToBuffer,              ITM_a_DIARESIS,              STD_a_DIARESIS,                                STD_a_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  737 */  { addItemToBuffer,              ITM_a_TILDE,                 STD_a_TILDE,                                   STD_a_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  738 */  { addItemToBuffer,              ITM_a_CIRC,                  STD_a_CIRC,                                    STD_a_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  739 */  { addItemToBuffer,              ITM_a_RING,                  STD_a_RING,                                    STD_a_RING,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  740 */  { addItemToBuffer,              ITM_ae,                      STD_ae,                                        STD_ae,                                        (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  741 */  { addItemToBuffer,              ITM_a_OGONEK,                STD_a_OGONEK,                                  STD_a_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  742 */  { addItemToBuffer,              ITM_c_ACUTE,                 STD_c_ACUTE,                                   STD_c_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  743 */  { addItemToBuffer,              ITM_c_CARON,                 STD_c_CARON,                                   STD_c_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  744 */  { addItemToBuffer,              ITM_c_CEDILLA,               STD_c_CEDILLA,                                 STD_c_CEDILLA,                                 (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  745 */  { addItemToBuffer,              ITM_d_STROKE,                STD_d_STROKE,                                  STD_d_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  746 */  { addItemToBuffer,              ITM_d_APOSTROPHE,            STD_d_APOSTROPHE,                              STD_d_APOSTROPHE,                              (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  747 */  { addItemToBuffer,              ITM_e_MACRON,                STD_e_MACRON,                                  STD_e_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  748 */  { addItemToBuffer,              ITM_e_ACUTE,                 STD_e_ACUTE,                                   STD_e_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  749 */  { addItemToBuffer,              ITM_e_BREVE,                 STD_e_BREVE,                                   STD_e_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  750 */  { addItemToBuffer,              ITM_e_GRAVE,                 STD_e_GRAVE,                                   STD_e_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  751 */  { addItemToBuffer,              ITM_e_DIARESIS,              STD_e_DIARESIS,                                STD_e_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  752 */  { addItemToBuffer,              ITM_e_CIRC,                  STD_e_CIRC,                                    STD_e_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  753 */  { addItemToBuffer,              ITM_e_OGONEK,                STD_e_OGONEK,                                  STD_e_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  754 */  { addItemToBuffer,              ITM_g_BREVE,                 STD_g_BREVE,                                   STD_g_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  755 */  { addItemToBuffer,              ITM_h_STROKE,                "",                                            STD_h_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  756 */  { addItemToBuffer,              ITM_i_MACRON,                STD_i_MACRON,                                  STD_i_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  757 */  { addItemToBuffer,              ITM_i_ACUTE,                 STD_i_ACUTE,                                   STD_i_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  758 */  { addItemToBuffer,              ITM_i_BREVE,                 STD_i_BREVE,                                   STD_i_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  759 */  { addItemToBuffer,              ITM_i_GRAVE,                 STD_i_GRAVE,                                   STD_i_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  760 */  { addItemToBuffer,              ITM_i_DIARESIS,              STD_i_DIARESIS,                                STD_i_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  761 */  { addItemToBuffer,              ITM_i_CIRC,                  STD_i_CIRC,                                    STD_i_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  762 */  { addItemToBuffer,              ITM_i_OGONEK,                STD_i_OGONEK,                                  STD_i_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  763 */  { addItemToBuffer,              ITM_i_DOT,                   "i",                                           "i",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  764 */  { addItemToBuffer,              ITM_i_DOTLESS,               STD_i_DOTLESS,                                 STD_i_DOTLESS,                                 (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  765 */  { addItemToBuffer,              ITM_l_STROKE,                STD_l_STROKE,                                  STD_l_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  766 */  { addItemToBuffer,              ITM_l_ACUTE,                 STD_l_ACUTE,                                   STD_l_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  767 */  { addItemToBuffer,              ITM_l_APOSTROPHE,            STD_l_APOSTROPHE,                              STD_l_APOSTROPHE,                              (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  768 */  { addItemToBuffer,              ITM_n_ACUTE,                 STD_n_ACUTE,                                   STD_n_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  769 */  { addItemToBuffer,              ITM_n_CARON,                 STD_n_CARON,                                   STD_n_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  770 */  { addItemToBuffer,              ITM_n_TILDE,                 STD_n_TILDE,                                   STD_n_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  771 */  { addItemToBuffer,              ITM_o_MACRON,                STD_o_MACRON,                                  STD_o_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  772 */  { addItemToBuffer,              ITM_o_ACUTE,                 STD_o_ACUTE,                                   STD_o_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  773 */  { addItemToBuffer,              ITM_o_BREVE,                 STD_o_BREVE,                                   STD_o_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  774 */  { addItemToBuffer,              ITM_o_GRAVE,                 STD_o_GRAVE,                                   STD_o_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  775 */  { addItemToBuffer,              ITM_o_DIARESIS,              STD_o_DIARESIS,                                STD_o_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  776 */  { addItemToBuffer,              ITM_o_TILDE,                 STD_o_TILDE,                                   STD_o_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  777 */  { addItemToBuffer,              ITM_o_CIRC,                  STD_o_CIRC,                                    STD_o_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  778 */  { addItemToBuffer,              ITM_o_STROKE,                STD_o_STROKE,                                  STD_o_STROKE,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  779 */  { addItemToBuffer,              ITM_oe,                      STD_oe,                                        STD_oe,                                        (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  780 */  { addItemToBuffer,              ITM_r_CARON,                 STD_r_CARON,                                   STD_r_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  781 */  { addItemToBuffer,              ITM_r_ACUTE,                 STD_r_ACUTE,                                   STD_r_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  782 */  { addItemToBuffer,              ITM_s_SHARP,                 STD_s_SHARP,                                   STD_s_SHARP,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  783 */  { addItemToBuffer,              ITM_s_ACUTE,                 STD_s_ACUTE,                                   STD_s_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  784 */  { addItemToBuffer,              ITM_s_CARON,                 STD_s_CARON,                                   STD_s_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  785 */  { addItemToBuffer,              ITM_s_CEDILLA,               STD_s_CEDILLA,                                 STD_s_CEDILLA,                                 (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  786 */  { addItemToBuffer,              ITM_t_APOSTROPHE,            STD_t_APOSTROPHE,                              STD_t_APOSTROPHE,                              (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  787 */  { addItemToBuffer,              ITM_t_CEDILLA,               STD_t_CEDILLA,                                 STD_t_CEDILLA,                                 (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  788 */  { addItemToBuffer,              ITM_u_MACRON,                STD_u_MACRON,                                  STD_u_MACRON,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  789 */  { addItemToBuffer,              ITM_u_ACUTE,                 STD_u_ACUTE,                                   STD_u_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  790 */  { addItemToBuffer,              ITM_u_BREVE,                 STD_u_BREVE,                                   STD_u_BREVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  791 */  { addItemToBuffer,              ITM_u_GRAVE,                 STD_u_GRAVE,                                   STD_u_GRAVE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  792 */  { addItemToBuffer,              ITM_u_DIARESIS,              STD_u_DIARESIS,                                STD_u_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  793 */  { addItemToBuffer,              ITM_u_TILDE,                 STD_u_TILDE,                                   STD_u_TILDE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  794 */  { addItemToBuffer,              ITM_u_CIRC,                  STD_u_CIRC,                                    STD_u_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  795 */  { addItemToBuffer,              ITM_u_RING,                  STD_u_RING,                                    STD_u_RING,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  796 */  { addItemToBuffer,              ITM_w_CIRC,                  STD_w_CIRC,                                    STD_w_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  797 */  { addItemToBuffer,              ITM_x_BAR,                   "",                                            STD_x_BAR,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  798 */  { addItemToBuffer,              ITM_x_CIRC,                  "",                                            STD_x_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  799 */  { addItemToBuffer,              ITM_y_BAR,                   "",                                            STD_y_BAR,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  800 */  { addItemToBuffer,              ITM_y_CIRC,                  STD_y_CIRC,                                    STD_y_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  801 */  { addItemToBuffer,              ITM_y_ACUTE,                 STD_y_ACUTE,                                   STD_y_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  802 */  { addItemToBuffer,              ITM_y_DIARESIS,              STD_y_DIARESIS,                                STD_y_DIARESIS,                                (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  803 */  { addItemToBuffer,              ITM_z_ACUTE,                 STD_z_ACUTE,                                   STD_z_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  804 */  { addItemToBuffer,              ITM_z_CARON,                 STD_z_CARON,                                   STD_z_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  805 */  { addItemToBuffer,              ITM_z_DOT,                   STD_z_DOT,                                     STD_z_DOT,                                     (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  806 */  { addItemToBuffer,              ITM_SPACE,                   "",                                            STD_SPACE,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  807 */  { addItemToBuffer,              ITM_EXCLAMATION_MARK,        "",                                            STD_EXCLAMATION_MARK,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  808 */  { addItemToBuffer,              ITM_DOUBLE_QUOTE,            "",                                            STD_DOUBLE_QUOTE,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  809 */  { addItemToBuffer,              ITM_NUMBER_SIGN,             "",                                            STD_NUMBER_SIGN,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  810 */  { addItemToBuffer,              ITM_DOLLAR,                  "",                                            STD_DOLLAR,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  811 */  { addItemToBuffer,              ITM_PERCENT,                 "",                                            STD_PERCENT,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  812 */  { addItemToBuffer,              ITM_AMPERSAND,               "",                                            STD_AMPERSAND,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  813 */  { addItemToBuffer,              ITM_QUOTE,                   "",                                            STD_QUOTE,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  814 */  { addItemToBuffer,              ITM_LEFT_PARENTHESIS,        "",                                            STD_LEFT_PARENTHESIS,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  815 */  { addItemToBuffer,              ITM_RIGHT_PARENTHESIS,       "",                                            STD_RIGHT_PARENTHESIS,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  816 */  { addItemToBuffer,              ITM_ASTERISK,                "",                                            STD_ASTERISK,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  817 */  { addItemToBuffer,              ITM_PLUS,                    "",                                            STD_PLUS,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  818 */  { addItemToBuffer,              ITM_COMMA,                   "",                                            STD_COMMA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  819 */  { addItemToBuffer,              ITM_MINUS,                   "",                                            STD_MINUS,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  820 */  { addItemToBuffer,              ITM_PERIOD,                  "",                                            STD_PERIOD,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  821 */  { addItemToBuffer,              ITM_SLASH,                   "",                                            STD_SLASH,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  822 */  { addItemToBuffer,              ITM_COLON,                   "",                                            STD_COLON,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  823 */  { addItemToBuffer,              ITM_SEMICOLON,               "",                                            STD_SEMICOLON,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  824 */  { addItemToBuffer,              ITM_LESS_THAN,               "",                                            STD_LESS_THAN,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  825 */  { addItemToBuffer,              ITM_EQUAL,                   "",                                            STD_EQUAL,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  826 */  { addItemToBuffer,              ITM_GREATER_THAN,            "",                                            STD_GREATER_THAN,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  827 */  { addItemToBuffer,              ITM_QUESTION_MARK,           "",                                            STD_QUESTION_MARK,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  828 */  { addItemToBuffer,              ITM_AT,                      "",                                            STD_AT,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  829 */  { addItemToBuffer,              ITM_LEFT_SQUARE_BRACKET,     "",                                            STD_LEFT_SQUARE_BRACKET,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  830 */  { addItemToBuffer,              ITM_BACK_SLASH,              "",                                            STD_BACK_SLASH,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  831 */  { addItemToBuffer,              ITM_RIGHT_SQUARE_BRACKET,    "",                                            STD_RIGHT_SQUARE_BRACKET,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  832 */  { addItemToBuffer,              ITM_CIRCUMFLEX,              "",                                            STD_CIRCUMFLEX,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  833 */  { addItemToBuffer,              ITM_UNDERSCORE,              "",                                            STD_UNDERSCORE,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  834 */  { addItemToBuffer,              ITM_LEFT_CURLY_BRACKET,      "",                                            STD_LEFT_CURLY_BRACKET,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  835 */  { addItemToBuffer,              ITM_PIPE,                    "",                                            STD_PIPE,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  836 */  { addItemToBuffer,              ITM_RIGHT_CURLY_BRACKET,     "",                                            STD_RIGHT_CURLY_BRACKET,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  837 */  { addItemToBuffer,              ITM_TILDE,                   "",                                            STD_TILDE,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  838 */  { addItemToBuffer,              ITM_INVERTED_EXCLAMATION_MARK, "",                                            STD_INVERTED_EXCLAMATION_MARK,                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  839 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_CENT,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  840 */  { addItemToBuffer,              ITM_POUND,                   "",                                            STD_POUND,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  841 */  { addItemToBuffer,              ITM_YEN,                     "",                                            STD_YEN,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  842 */  { addItemToBuffer,              ITM_SECTION,                 "",                                            STD_SECTION,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  843 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_OVERFLOW_CARRY,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  844 */  { addItemToBuffer,              ITM_LEFT_DOUBLE_ANGLE,       "",                                            STD_LEFT_DOUBLE_ANGLE,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  845 */  { addItemToBuffer,              ITM_NOT,                     "",                                            STD_NOT,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  846 */  { addItemToBuffer,              ITM_DEGREE,                  "",                                            STD_DEGREE,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  847 */  { addItemToBuffer,              ITM_PLUS_MINUS,              "",                                            STD_PLUS_MINUS,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  848 */  { addItemToBuffer,              ITM_MICRO,                   "",                                            STD_MICRO,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  849 */  { addItemToBuffer,              ITM_DOT,                     "",                                            STD_DOT,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  850 */  { addItemToBuffer,              ITM_RIGHT_DOUBLE_ANGLE,      "",                                            STD_RIGHT_DOUBLE_ANGLE,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  851 */  { addItemToBuffer,              ITM_ONE_HALF,                "",                                            STD_ONE_HALF,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  852 */  { addItemToBuffer,              ITM_ONE_QUARTER,             "",                                            STD_ONE_QUARTER,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  853 */  { addItemToBuffer,              ITM_INVERTED_QUESTION_MARK,  "",                                            STD_INVERTED_QUESTION_MARK,                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  854 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_ETH,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  855 */  { addItemToBuffer,              ITM_CROSS,                   "",                                            STD_CROSS,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  856 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_eth,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  857 */  { addItemToBuffer,              ITM_OBELUS,                  "",                                            STD_DIVIDE,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  858 */  { addItemToBuffer,              ITM_E_DOT,                   STD_E_DOT,                                     STD_E_DOT,                                     (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  859 */  { addItemToBuffer,              ITM_e_DOT,                   STD_e_DOT,                                     STD_e_DOT,                                     (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  860 */  { addItemToBuffer,              ITM_E_CARON,                 STD_E_CARON,                                   STD_E_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  861 */  { addItemToBuffer,              ITM_e_CARON,                 STD_e_CARON,                                   STD_e_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  862 */  { addItemToBuffer,              ITM_R_ACUTE,                 STD_R_ACUTE,                                   STD_R_ACUTE,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  863 */  { addItemToBuffer,              ITM_R_CARON,                 STD_R_CARON,                                   STD_R_CARON,                                   (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  864 */  { addItemToBuffer,              ITM_U_OGONEK,                STD_U_OGONEK,                                  STD_U_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_AINT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  865 */  { addItemToBuffer,              ITM_u_OGONEK,                STD_u_OGONEK,                                  STD_u_OGONEK,                                  (0 << TAM_MAX_BITS) |     0, CAT_aint | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  866 */  { addItemToBuffer,              ITM_y_UNDER_ROOT,            "",                                            STD_y_UNDER_ROOT,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  867 */  { addItemToBuffer,              ITM_x_UNDER_ROOT,            "",                                            STD_x_UNDER_ROOT,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  868 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_EM,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  869 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_3_PER_EM,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  870 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_4_PER_EM,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  871 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_6_PER_EM,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  872 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_FIGURE,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  873 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_PUNCTUATION,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  874 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SPACE_HAIR,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  875 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_LEFT_SINGLE_QUOTE,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  876 */  { addItemToBuffer,              ITM_RIGHT_SINGLE_QUOTE,      "",                                            STD_RIGHT_SINGLE_QUOTE,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  877 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SINGLE_LOW_QUOTE,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  878 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SINGLE_HIGH_QUOTE,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  879 */  { addItemToBuffer,              ITM_LEFT_DOUBLE_QUOTE,       "",                                            STD_LEFT_DOUBLE_QUOTE,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  880 */  { addItemToBuffer,              ITM_RIGHT_DOUBLE_QUOTE,      "",                                            STD_RIGHT_DOUBLE_QUOTE,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  881 */  { addItemToBuffer,              ITM_DOUBLE_LOW_QUOTE,        "",                                            STD_DOUBLE_LOW_QUOTE,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  882 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_DOUBLE_HIGH_QUOTE,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  883 */  { addItemToBuffer,              ITM_ELLIPSIS,                "",                                            STD_ELLIPSIS,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  884 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_BINARY_ONE,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  885 */  { addItemToBuffer,              ITM_EURO,                    "",                                            STD_EURO,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  886 */  { addItemToBuffer,              ITM_COMPLEX_C,               "",                                            STD_COMPLEX_C,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  887 */  { addItemToBuffer,              ITM_PLANCK,                  "",                                            STD_PLANCK,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  888 */  { addItemToBuffer,              ITM_PLANCK_2PI,              "",                                            STD_PLANCK_2PI,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  889 */  { addItemToBuffer,              ITM_NATURAL_N,               "",                                            STD_NATURAL_N,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  890 */  { addItemToBuffer,              ITM_RATIONAL_Q,              "",                                            STD_RATIONAL_Q,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  891 */  { addItemToBuffer,              ITM_REAL_R,                  "",                                            STD_REAL_R,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  892 */  { addItemToBuffer,              ITM_LEFT_ARROW,              "",                                            STD_LEFT_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  893 */  { addItemToBuffer,              ITM_UP_ARROW,                "",                                            STD_UP_ARROW,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  894 */  { addItemToBuffer,              ITM_RIGHT_ARROW,             "",                                            STD_RIGHT_ARROW,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  895 */  { addItemToBuffer,              ITM_DOWN_ARROW,              "",                                            STD_DOWN_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  896 */  { addItemToBuffer,              ITM_SERIAL_IO,               "",                                            STD_SERIAL_IO,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  897 */  { addItemToBuffer,              ITM_RIGHT_SHORT_ARROW,       "",                                            STD_RIGHT_SHORT_ARROW,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  898 */  { addItemToBuffer,              ITM_LEFT_RIGHT_ARROWS,       "",                                            STD_LEFT_RIGHT_ARROWS,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  899 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_BST,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  900 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SST,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  901 */  { addItemToBuffer,              ITM_HAMBURGER,               "",                                            STD_HAMBURGER,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  902 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_UNDO,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  903 */  { addItemToBuffer,              ITM_FOR_ALL,                 "",                                            STD_FOR_ALL,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  904 */  { addItemToBuffer,              ITM_COMPLEMENT,              "",                                            STD_COMPLEMENT,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  905 */  { addItemToBuffer,              ITM_PARTIAL_DIFF,            "",                                            STD_PARTIAL_DIFF,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  906 */  { addItemToBuffer,              ITM_THERE_EXISTS,            "",                                            STD_THERE_EXISTS,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  907 */  { addItemToBuffer,              ITM_THERE_DOES_NOT_EXIST,    "",                                            STD_THERE_DOES_NOT_EXIST,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  908 */  { addItemToBuffer,              ITM_EMPTY_SET,               "",                                            STD_EMPTY_SET,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  909 */  { addItemToBuffer,              ITM_INCREMENT,               "",                                            STD_INCREMENT,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  910 */  { addItemToBuffer,              ITM_NABLA,                   "",                                            STD_NABLA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  911 */  { addItemToBuffer,              ITM_ELEMENT_OF,              "",                                            STD_ELEMENT_OF,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  912 */  { addItemToBuffer,              ITM_NOT_ELEMENT_OF,          "",                                            STD_NOT_ELEMENT_OF,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  913 */  { addItemToBuffer,              ITM_CONTAINS,                "",                                            STD_CONTAINS,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  914 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_DOES_NOT_CONTAIN,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  915 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_BINARY_ZERO,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  916 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_PRODUCT,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  917 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_MINUS_PLUS,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  918 */  { addItemToBuffer,              ITM_RING,                    "",                                            STD_RING,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  919 */  { addItemToBuffer,              ITM_BULLET,                  "",                                            STD_BULLET,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  920 */  { addItemToBuffer,              ITM_SQUARE_ROOT,             "",                                            STD_SQUARE_ROOT,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  921 */  { addItemToBuffer,              ITM_CUBE_ROOT,               "",                                            STD_CUBE_ROOT,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  922 */  { addItemToBuffer,              ITM_xTH_ROOT,                "",                                            STD_xTH_ROOT,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  923 */  { addItemToBuffer,              ITM_PROPORTIONAL,            "",                                            STD_PROPORTIONAL,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  924 */  { addItemToBuffer,              ITM_INFINITY,                "",                                            STD_INFINITY,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  925 */  { addItemToBuffer,              ITM_RIGHT_ANGLE,             "",                                            STD_RIGHT_ANGLE,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  926 */  { addItemToBuffer,              ITM_IRRATIONAL_I,            "",                                            STD_IRRATIONAL_I,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  927 */  { addItemToBuffer,              ITM_MEASURED_ANGLE,          "",                                            STD_MEASURED_ANGLE,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  928 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_DIVIDES,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  929 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_DOES_NOT_DIVIDE,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  930 */  { addItemToBuffer,              ITM_PARALLEL_SIGN,           "",                                            STD_PARALLEL,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  931 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_NOT_PARALLEL,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  932 */  { addItemToBuffer,              ITM_AND,                     "",                                            STD_AND,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  933 */  { addItemToBuffer,              ITM_OR,                      "",                                            STD_OR,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  934 */  { addItemToBuffer,              ITM_INTERSECTION,            "",                                            STD_INTERSECTION,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  935 */  { addItemToBuffer,              ITM_UNION,                   "",                                            STD_UNION,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  936 */  { addItemToBuffer,              ITM_INTEGRAL_SIGN,           "",                                            STD_INTEGRAL,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  937 */  { addItemToBuffer,              ITM_DOUBLE_INTEGRAL,         "",                                            STD_DOUBLE_INTEGRAL,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  938 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_CONTOUR_INTEGRAL,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  939 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SURFACE_INTEGRAL,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  940 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_RATIO,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  941 */  { addItemToBuffer,              ITM_CHECK_MARK,              "",                                            STD_CHECK_MARK,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  942 */  { addItemToBuffer,              ITM_ASYMPOTICALLY_EQUAL,     "",                                            STD_ASYMPOTICALLY_EQUAL,                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  943 */  { addItemToBuffer,              ITM_ALMOST_EQUAL,            "",                                            STD_ALMOST_EQUAL,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  944 */  { addItemToBuffer,              ITM_COLON_EQUALS,            "",                                            STD_COLON_EQUALS,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  945 */  { addItemToBuffer,              ITM_CORRESPONDS_TO,          "",                                            STD_CORRESPONDS_TO,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  946 */  { addItemToBuffer,              ITM_ESTIMATES,               "",                                            STD_ESTIMATES,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  947 */  { addItemToBuffer,              ITM_NOT_EQUAL,               "",                                            STD_NOT_EQUAL,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  948 */  { addItemToBuffer,              ITM_IDENTICAL_TO,            "",                                            STD_IDENTICAL_TO,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  949 */  { addItemToBuffer,              ITM_LESS_EQUAL,              "",                                            STD_LESS_EQUAL,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  950 */  { addItemToBuffer,              ITM_GREATER_EQUAL,           "",                                            STD_GREATER_EQUAL,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  951 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_MUCH_LESS,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  952 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_MUCH_GREATER,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  953 */  { addItemToBuffer,              ITM_SUN,                     "",                                            STD_SUN,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  954 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_TRANSPOSED,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  955 */  { addItemToBuffer,              ITM_PERPENDICULAR,           "",                                            STD_PERPENDICULAR,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  956 */  { addItemToBuffer,              ITM_XOR,                     "",                                            STD_XOR,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  957 */  { addItemToBuffer,              ITM_NAND,                    "",                                            STD_NAND,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  958 */  { addItemToBuffer,              ITM_NOR,                     "",                                            STD_NOR,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  959 */  { addItemToBuffer,              ITM_WATCH,                   "",                                            STD_WATCH,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  960 */  { addItemToBuffer,              ITM_HOURGLASS,               "",                                            STD_HOURGLASS,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  961 */  { addItemToBuffer,              ITM_PRINTER,                 "",                                            STD_PRINTER,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  962 */  { addItemToBuffer,              ITM_MAT_TL,                  "",                                            STD_MAT_TL,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  963 */  { addItemToBuffer,              ITM_MAT_ML,                  "",                                            STD_MAT_ML,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  964 */  { addItemToBuffer,              ITM_MAT_BL,                  "",                                            STD_MAT_BL,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  965 */  { addItemToBuffer,              ITM_MAT_TR,                  "",                                            STD_MAT_TR,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  966 */  { addItemToBuffer,              ITM_MAT_MR,                  "",                                            STD_MAT_MR,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  967 */  { addItemToBuffer,              ITM_MAT_BR,                  "",                                            STD_MAT_BR,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  968 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_OBLIQUE1,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  969 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_OBLIQUE2,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  970 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_OBLIQUE3,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  971 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_OBLIQUE4,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  972 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_CURSOR,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  973 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_PERIOD34,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  974 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_COMMA34,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  975 */  { addItemToBuffer,              ITM_BATTERY,                 "",                                            STD_BATTERY,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  976 */  { addItemToBuffer,              ITM_PGM_BEGIN,               "",                                            STD_PGM_BEGIN,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  977 */  { addItemToBuffer,              ITM_USER_MODE,               "",                                            STD_USER_MODE,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  978 */  { addItemToBuffer,              ITM_UK,                      "",                                            STD_UK,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  979 */  { addItemToBuffer,              ITM_US,                      "",                                            STD_US,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  980 */  { addItemToBuffer,              ITM_NEG_EXCLAMATION_MARK,    "",                                            STD_NEG_EXCLAMATION_MARK,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  981 */  { addItemToBuffer,              ITM_ex,                      "",                                            STD_RIGHT_OVER_LEFT_ARROW,                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  982 */  { addItemToBuffer,              ITM_Max,                     "",                                            "Max",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  983 */  { addItemToBuffer,              ITM_Min,                     "",                                            "Min",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  984 */  { addItemToBuffer,              ITM_Config,                  "",                                            "Config",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  985 */  { addItemToBuffer,              ITM_Stack,                   "",                                            "Stack",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  986 */  { addItemToBuffer,              ITM_dddEL,                   "",                                            STD_ELLIPSIS "EL",                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  987 */  { addItemToBuffer,              ITM_dddIJ,                   "",                                            STD_ELLIPSIS "IJ",                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  988 */  { addItemToBuffer,              ITM_0P,                      "",                                            "0.",                                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  989 */  { addItemToBuffer,              ITM_1P,                      "",                                            "1.",                                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  990 */  { addItemToBuffer,              ITM_EXPONENT/*jmok*/,        "",                                            "EEX",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  991 */  { addItemToBuffer,              NOPARAM,                     "HEX",                                         "H",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  992 */  { fnGoToRow,                    TM_VALUE,                    "GOTO Row",                                    "GOTO",                                        (0 << TAM_MAX_BITS) |  9999, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  993 */  { fnGoToColumn,                 TM_VALUE,                    "GOTO Column",                                 "GOTO",                                        (0 << TAM_MAX_BITS) |  9999, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  994 */  { fnSolveVar,                   NOPARAM,                     "SOLVE Var",                                   "SOLVE",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  995 */  { fnEqCursorLeft,               NOPARAM,                     "",                                            STD_LEFT_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  996 */  { fnEqCursorRight,              NOPARAM,                     "",                                            STD_RIGHT_ARROW,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  997 */  { addItemToBuffer,              ITM_PAIR_OF_PARENTHESES,     "",                                            "( )",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  998 */  { addItemToBuffer,              ITM_VERTICAL_BAR,            "",                                            "|",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/*  999 */  { addItemToBuffer,              ITM_ALOG_SYMBOL,             "",                                            STD_EulerE STD_SUP_x,                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1000 */  { addItemToBuffer,              ITM_ROOT_SIGN,               "",                                            STD_SQUARE_ROOT STD_SUP_MINUS,                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1001 */  { addItemToBuffer,              ITM_TIMER_SYMBOL,            "",                                            STD_TIMER,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1002 */  { fnIntVar,                     NOPARAM,                     STD_INTEGRAL "fdx Var",                        STD_INTEGRAL "fdx",                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1003 */  { addItemToBuffer,              ITM_SUP_PLUS,                "",                                            STD_SUP_PLUS,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1004 */  { addItemToBuffer,              ITM_SUP_MINUS,               "",                                            STD_SUP_MINUS,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1005 */  { addItemToBuffer,              ITM_SUP_MINUS_1,             "",                                            STD_SUP_MINUS_1,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1006 */  { addItemToBuffer,              ITM_SUP_INFINITY,            "",                                            STD_SUP_INFINITY,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1007 */  { addItemToBuffer,              ITM_SUP_ASTERISK,            "",                                            STD_SUP_ASTERISK,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1008 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_0,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1009 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_1,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1010 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_2,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1011 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_3,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1012 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_4,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1013 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_5,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1014 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_6,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1015 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_7,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1016 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_8,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1017 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_9,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1018 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_A,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1019 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_B,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1020 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_C,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1021 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_D,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1022 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_E,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1023 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_F,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1024 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_G,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1025 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_H,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1026 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_I,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1027 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_J,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1028 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_K,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1029 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_L,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1030 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_M,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1031 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_N,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1032 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_O,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1033 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_P,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1034 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_Q,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1035 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_R,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1036 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_S,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1037 */  { addItemToBuffer,              ITM_SUP_T,                   "",                                            STD_SUP_T,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1038 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_U,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1039 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_V,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1040 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_W,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1041 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_X,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1042 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_Y,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1043 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_Z,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1044 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_a,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1045 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_b,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1046 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_c,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1047 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_d,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1048 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_e,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1049 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_f,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1050 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_g,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1051 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_h,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1052 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_i,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1053 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_j,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1054 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_k,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1055 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_l,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1056 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_m,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1057 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_n,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1058 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_o,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1059 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_p,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1060 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_q,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1061 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_r,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1062 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_s,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1063 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_t,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1064 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_u,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1065 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_v,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1066 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_w,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1067 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_x,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1068 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_y,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1069 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUP_z,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1070 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_alpha,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1071 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_delta,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1072 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_mu,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1073 */  { addItemToBuffer,              ITM_SUB_SUN,                 "",                                            STD_SUB_SUN,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1074 */  { addItemToBuffer,              ITM_SUB_EARTH,               "",                                            STD_SUB_EARTH,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1075 */  { addItemToBuffer,              ITM_SUB_PLUS,                "",                                            STD_SUB_PLUS,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1076 */  { addItemToBuffer,              ITM_SUB_MINUS,               "",                                            STD_SUB_MINUS,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1077 */  { addItemToBuffer,              ITM_SUB_INFINITY,            "",                                            STD_SUB_INFINITY,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1078 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_10,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1079 */  { addItemToBuffer,              ITM_SUB_E_OUTLINE,           "",                                            STD_SUB_E_OUTLINE,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1080 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_0,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1081 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_1,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1082 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_2,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1083 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_3,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1084 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_4,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1085 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_5,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1086 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_6,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1087 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_7,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1088 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_8,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1089 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_9,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1090 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_A,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1091 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_B,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1092 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_C,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1093 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_D,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1094 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_E,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1095 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_F,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1096 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_G,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1097 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_H,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1098 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_I,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1099 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_J,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1100 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_K,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1101 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_L,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1102 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_M,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1103 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_N,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1104 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_O,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1105 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_P,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1106 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_Q,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1107 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_R,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1108 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_S,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1109 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_T,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1110 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_U,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1111 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_V,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1112 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_W,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1113 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_X,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1114 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_Y,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1115 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_Z,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1116 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_a,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1117 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_b,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1118 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_c,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1119 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_d,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1120 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_e,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1121 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_f,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1122 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_g,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1123 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_h,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1124 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_i,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1125 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_j,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1126 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_k,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1127 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_l,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1128 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_m,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1129 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_n,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1130 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_o,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1131 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_p,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1132 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_q,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1133 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_r,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1134 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_s,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1135 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_t,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1136 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_u,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1137 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_v,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1138 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_w,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1139 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_x,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1140 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_y,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1141 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_SUB_z,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1142 */  { addItemToBuffer,              ITM_SUB_pi,                  "",                                            STD_SUB_pi,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1143 */  { addItemToBuffer,              ITM_SUP_pi,                  "",                                            STD_SUP_pi,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1144 */  { addItemToBuffer,              ITM_LEFT_DARROW,             "",                                            STD_LEFT_DASHARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1145 */  { addItemToBuffer,              ITM_UP_DARROW,               "",                                            STD_UP_DASHARROW,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1146 */  { addItemToBuffer,              ITM_RIGHT_DARROW,            "",                                            STD_RIGHT_DASHARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1147 */  { addItemToBuffer,              ITM_DOWN_DARROW,             "",                                            STD_DOWN_DASHARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1148 */  { addItemToBuffer,              ITM_ALTERN_CURRENT,          "",                                            STD_AC,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1149 */  { addItemToBuffer,              ITM_ANGLE,                   "",                                            STD_ANGLE,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1150 */  { addItemToBuffer,              ITM_SUP_1_SUB_B,             "",                                            STD_SUP_1_SUB_B,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1151 */  { addItemToBuffer,              ITM_BST_char,                "",                                            STD_BST,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1152 */  { addItemToBuffer,              ITM_CYCLIC,                  "",                                            STD_CYCLIC,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1153 */  { addItemToBuffer,              ITM_DIRECT_CURRENT,          "",                                            STD_DC,                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1154 */  { addItemToBuffer,              ITM_DOWN_DASHARROW,          "",                                            STD_DOWN_DASHARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1155 */  { addItemToBuffer,              ITM_EulerE,                  "",                                            STD_EulerE,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1156 */  { addItemToBuffer,              ITM_INTEGER_Z,               "",                                            STD_INTEGER_Z,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1157 */  { addItemToBuffer,              ITM_LEFT_DASHARROW,          "",                                            STD_LEFT_DASHARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1158 */  { addItemToBuffer,              ITM_NOT_SUBSET_OF,           "",                                            STD_NOT_SUBSET_OF,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1159 */  { addItemToBuffer,              ITM_op_i_char,               "",                                            STD_op_i,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1160 */  { addItemToBuffer,              ITM_op_j_char,               "",                                            STD_op_j,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1161 */  { addItemToBuffer,              ITM_POLAR_char,              "",                                            STD_SUN,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1162 */  { addItemToBuffer,              ITM_PRODUCT_char,            "",                                            STD_PRODUCT,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1163 */  { addItemToBuffer,              ITM_RIGHT_DASHARROW,         "",                                            STD_RIGHT_DASHARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1164 */  { addItemToBuffer,              ITM_RIGHT_DOUBLE_ARROW,      "",                                            STD_RIGHT_DOUBLE_ARROW,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1165 */  { addItemToBuffer,              ITM_RIGHT_TACK,              "",                                            STD_RIGHT_TACK,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1166 */  { addItemToBuffer,              ITM_SST_char,                "",                                            STD_SST,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1167 */  { addItemToBuffer,              ITM_SUBSET_OF,               "",                                            STD_SUBSET_OF,                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1168 */  { addItemToBuffer,              ITM_SUM_char,                "",                                            STD_SUM,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1169 */  { addItemToBuffer,              ITM_UP_DASHARROW,            "",                                            STD_UP_DASHARROW,                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1170 */  { addItemToBuffer,              ITM_USB_SYMBOL,              "",                                            STD_USB_SYMBOL,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1171 */  { addItemToBuffer,              ITM_LEFT_RIGHT_DOUBLE_ARROW, "",                                            STD_LEFT_RIGHT_DOUBLE_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1172 */  { itemToBeCoded,                NOPARAM,                     "1172",                                        "1172",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1173 */  { itemToBeCoded,                NOPARAM,                     "1173",                                        "1173",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1174 */  { itemToBeCoded,                NOPARAM,                     "1174",                                        "1174",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Reserved variables
/* 1175 */  { addItemToBuffer,              REGISTER_X,                  "X",                                           "X",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Do
/* 1176 */  { addItemToBuffer,              REGISTER_Y,                  "Y",                                           "Y",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // not
/* 1177 */  { addItemToBuffer,              REGISTER_Z,                  "Z",                                           "Z",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // change
/* 1178 */  { addItemToBuffer,              REGISTER_T,                  "T",                                           "T",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // the
/* 1179 */  { addItemToBuffer,              REGISTER_A,                  "A",                                           "A",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // order
/* 1180 */  { addItemToBuffer,              REGISTER_B,                  "B",                                           "B",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // of
/* 1181 */  { addItemToBuffer,              REGISTER_C,                  "C",                                           "C",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // this
/* 1182 */  { addItemToBuffer,              REGISTER_D,                  "D",                                           "D",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // 3
/* 1183 */  { addItemToBuffer,              REGISTER_L,                  "L",                                           "L",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // 0
/* 1184 */  { addItemToBuffer,              REGISTER_I,                  "I",                                           "I",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // reserved
/* 1185 */  { addItemToBuffer,              REGISTER_J,                  "J",                                           "J",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // variables
/* 1186 */  { addItemToBuffer,              REGISTER_K,                  "K",                                           "K",                                           (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // !
/* 1187 */  { itemToBeCoded,                NOPARAM,                     "ADM",                                         "ADM",                                         (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1188 */  { itemToBeCoded,                NOPARAM,                     "D.MAX",                                       "D.MAX",                                       (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1189 */  { itemToBeCoded,                NOPARAM,                     "ISM",                                         "ISM",                                         (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1190 */  { itemToBeCoded,                NOPARAM,                     "REALDF",                                      "REALDF",                                      (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1191 */  { itemToBeCoded,                NOPARAM,                     "#DEC",                                        "#DEC",                                        (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1192 */  { fnIntegrate,                  RESERVED_VARIABLE_ACC,       "ACC",                                         "ACC",                                         (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1193 */  { fnIntegrate,                  RESERVED_VARIABLE_ULIM,      STD_UP_ARROW "Lim",                            STD_UP_ARROW "Lim",                            (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1194 */  { fnIntegrate,                  RESERVED_VARIABLE_LLIM,      STD_DOWN_ARROW "Lim",                          STD_DOWN_ARROW "Lim",                          (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1195 */  { fnTvmVar,                     RESERVED_VARIABLE_FV,        "FV",                                          "FV",                                          (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1196 */  { fnTvmVar,                     RESERVED_VARIABLE_IPONA,     "i%/a",                                        "i%/a",                                        (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1197 */  { fnTvmVar,                     RESERVED_VARIABLE_NPER,      NPER_,                                         NPER_,                                         (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1198 */  { fnTvmVar,                     RESERVED_VARIABLE_PERONA,    "PER/a",                                       "PER/a",                                       (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1199 */  { fnTvmVar,                     RESERVED_VARIABLE_PMT,       "PMT",                                         "PMT",                                         (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1200 */  { fnTvmVar,                     RESERVED_VARIABLE_PV,        "PV",                                          "PV",                                          (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1201 */  { itemToBeCoded,                NOPARAM,                     "GRAMOD",                                      "GRAMOD",                                      (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1202 */  { fnEditLinearEquationMatrixA,  NOPARAM,                     "Mat_A",                                       "Mat A",                                       (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1203 */  { fnEditLinearEquationMatrixB,  NOPARAM,                     "Mat_B",                                       "Mat B",                                       (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1204 */  { fnEditLinearEquationMatrixX,  NOPARAM,                     "Mat_X",                                       "Mat X",                                       (0 << TAM_MAX_BITS) |     0, CAT_RVAR | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1205 */  { itemToBeCoded,                NOPARAM,                     "1205",                                        "1205",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1206 */  { itemToBeCoded,                NOPARAM,                     "1206",                                        "1206",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Probability distributions
/* 1207 */  { itemToBeCoded,                NOPARAM,                     "Binom:",                                      "Binom:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1208 */  { fnBinomialP,                  NOPARAM,                     "Binom" STD_SUB_p,                             "Binom" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1209 */  { fnBinomialL,                  NOPARAM,                     "Binom" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Binom" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1210 */  { fnBinomialR,                  NOPARAM,                     "Binom" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Binom" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1211 */  { fnBinomialI,                  NOPARAM,                     "Binom" STD_SUP_MINUS_1,                       "Binom" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1212 */  { itemToBeCoded,                NOPARAM,                     "Cauch:",                                      "Cauch:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1213 */  { fnCauchyP,                    NOPARAM,                     "Cauch" STD_SUB_p,                             "Cauch" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1214 */  { fnCauchyL,                    NOPARAM,                     "Cauch" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Cauch" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1215 */  { fnCauchyR,                    NOPARAM,                     "Cauch" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Cauch" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1216 */  { fnCauchyI,                    NOPARAM,                     "Cauch" STD_SUP_MINUS_1,                       "Cauch" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1217 */  { itemToBeCoded,                NOPARAM,                     "Expon:",                                      "Expon:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1218 */  { fnExponentialP,               NOPARAM,                     "Expon" STD_SUB_p,                             "Expon" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1219 */  { fnExponentialL,               NOPARAM,                     "Expon" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Expon" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1220 */  { fnExponentialR,               NOPARAM,                     "Expon" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Expon" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1221 */  { fnExponentialI,               NOPARAM,                     "Expon" STD_SUP_MINUS_1,                       "Expon" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1222 */  { itemToBeCoded,                NOPARAM,                     "F:",                                          "F:",                                          (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1223 */  { fnF_P,                        NOPARAM,                     "F" STD_SUB_p "(x)",                           "F" STD_SUB_p "(x)",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1224 */  { fnF_L,                        NOPARAM,                     "F" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R "(x)", "F" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R "(x)", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1225 */  { fnF_R,                        NOPARAM,                     "F" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R "(x)", "F" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R "(x)", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1226 */  { fnF_I,                        NOPARAM,                     "F" STD_SUP_MINUS_1 "(p)",                     "F" STD_SUP_MINUS_1 "(p)",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1227 */  { itemToBeCoded,                NOPARAM,                     "Geom:",                                       "Geom:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1228 */  { fnGeometricP,                 NOPARAM,                     "Geom" STD_SUB_p,                              "Geom" STD_SUB_p,                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1229 */  { fnGeometricL,                 NOPARAM,                     "Geom" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,    "Geom" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1230 */  { fnGeometricR,                 NOPARAM,                     "Geom" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,    "Geom" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1231 */  { fnGeometricI,                 NOPARAM,                     "Geom" STD_SUP_MINUS_1,                        "Geom" STD_SUP_MINUS_1,                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1232 */  { itemToBeCoded,                NOPARAM,                     "Hyper:",                                      "Hyper:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1233 */  { fnHypergeometricP,            NOPARAM,                     "Hyper" STD_SUB_p,                             "Hyper" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1234 */  { fnHypergeometricL,            NOPARAM,                     "Hyper" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Hyper" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1235 */  { fnHypergeometricR,            NOPARAM,                     "Hyper" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Hyper" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1236 */  { fnHypergeometricI,            NOPARAM,                     "Hyper" STD_SUP_MINUS_1,                       "Hyper" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1237 */  { itemToBeCoded,                NOPARAM,                     "LgNrm:",                                      "LgNrm:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1238 */  { fnLogNormalP,                 NOPARAM,                     "LgNrm" STD_SUB_p,                             "LgNrm" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1239 */  { fnLogNormalL,                 NOPARAM,                     "LgNrm" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "LgNrm" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1240 */  { fnLogNormalR,                 NOPARAM,                     "LgNrm" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "LgNrm" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1241 */  { fnLogNormalI,                 NOPARAM,                     "LgNrm" STD_SUP_MINUS_1,                       "LgNrm" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1242 */  { itemToBeCoded,                NOPARAM,                     "Logis:",                                      "Logis:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1243 */  { fnLogisticP,                  NOPARAM,                     "Logis" STD_SUB_p,                             "Logis" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1244 */  { fnLogisticL,                  NOPARAM,                     "Logis" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Logis" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1245 */  { fnLogisticR,                  NOPARAM,                     "Logis" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Logis" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1246 */  { fnLogisticI,                  NOPARAM,                     "Logis" STD_SUP_MINUS_1,                       "Logis" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1247 */  { itemToBeCoded,                NOPARAM,                     "NBin:",                                       "NBin:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1248 */  { fnNegBinomialP,               NOPARAM,                     "NBin" STD_SUB_p,                              "NBin" STD_SUB_p,                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1249 */  { fnNegBinomialL,               NOPARAM,                     "NBin" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,    "NBin" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1250 */  { fnNegBinomialR,               NOPARAM,                     "NBin" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,    "NBin" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1251 */  { fnNegBinomialI,               NOPARAM,                     "NBin" STD_SUP_MINUS_1,                        "NBin" STD_SUP_MINUS_1,                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1252 */  { itemToBeCoded,                NOPARAM,                     "Norml:",                                      "Norml:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1253 */  { fnNormalP,                    NOPARAM,                     "Norml" STD_SUB_p,                             "Norml" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1254 */  { fnNormalL,                    NOPARAM,                     "Norml" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Norml" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1255 */  { fnNormalR,                    NOPARAM,                     "Norml" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Norml" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1256 */  { fnNormalI,                    NOPARAM,                     "Norml" STD_SUP_MINUS_1,                       "Norml" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1257 */  { itemToBeCoded,                NOPARAM,                     "Poiss:",                                      "Poiss:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1258 */  { fnPoissonP,                   NOPARAM,                     "Poiss" STD_SUB_p,                             "Poiss" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1259 */  { fnPoissonL,                   NOPARAM,                     "Poiss" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Poiss" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1260 */  { fnPoissonR,                   NOPARAM,                     "Poiss" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Poiss" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1261 */  { fnPoissonI,                   NOPARAM,                     "Poiss" STD_SUP_MINUS_1,                       "Poiss" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1262 */  { itemToBeCoded,                NOPARAM,                     "t:",                                          "t:",                                          (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1263 */  { fnT_P,                        NOPARAM,                     "t" STD_SUB_p "(x)",                           "t" STD_SUB_p "(x)",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1264 */  { fnT_L,                        NOPARAM,                     "t" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R "(x)", "t" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R "(x)", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1265 */  { fnT_R,                        NOPARAM,                     "t" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R "(x)", "t" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R "(x)", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1266 */  { fnT_I,                        NOPARAM,                     "t" STD_SUP_MINUS_1 "(p)",                     "t" STD_SUP_MINUS_1 "(p)",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1267 */  { itemToBeCoded,                NOPARAM,                     "Weibl:",                                      "Weibl:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1268 */  { fnWeibullP,                   NOPARAM,                     "Weibl" STD_SUB_p,                             "Weibl" STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1269 */  { fnWeibullL,                   NOPARAM,                     "Weibl" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   "Weibl" STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1270 */  { fnWeibullR,                   NOPARAM,                     "Weibl" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   "Weibl" STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1271 */  { fnWeibullI,                   NOPARAM,                     "Weibl" STD_SUP_MINUS_1,                       "Weibl" STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1272 */  { itemToBeCoded,                NOPARAM,                     STD_chi STD_SUP_2 ":",                         STD_chi STD_SUP_2 ":",                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1273 */  { fnChi2P,                      NOPARAM,                     STD_chi STD_SUP_2 STD_SUB_p "(x)",             STD_chi STD_SUP_2 STD_SUB_p "(x)",             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1274 */  { fnChi2L,                      NOPARAM,                     STD_chi STD_SUP_2 STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R "(x)", STD_chi STD_SUP_2 STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R "(x)", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1275 */  { fnChi2R,                      NOPARAM,                     STD_chi STD_SUP_2 STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R "(x)", STD_chi STD_SUP_2 STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R "(x)", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1276 */  { fnChi2I,                      NOPARAM,                     "(" STD_chi STD_SUP_2 ")" STD_SUP_MINUS_1,     "(" STD_chi STD_SUP_2 ")" STD_SUP_MINUS_1,     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1277 */  { itemToBeCoded,                NOPARAM,                     STD_PHI ":",                                   STD_PHI ":",                                   (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1278 */  { fnStdNormalP,                 NOPARAM,                     STD_phi STD_SUB_p,                             STD_phi STD_SUB_p,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1279 */  { fnStdNormalL,                 NOPARAM,                     STD_PHI STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   STD_PHI STD_GAUSS_BLACK_L STD_GAUSS_WHITE_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1280 */  { fnStdNormalR,                 NOPARAM,                     STD_PHI STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   STD_PHI STD_GAUSS_WHITE_L STD_GAUSS_BLACK_R,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1281 */  { fnStdNormalI,                 NOPARAM,                     STD_PHI STD_SUP_MINUS_1,                       STD_PHI STD_SUP_MINUS_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1282 */  { itemToBeCoded,                NOPARAM,                     "1282",                                        "1282",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1283 */  { itemToBeCoded,                NOPARAM,                     "1283",                                        "1283",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1284 */  { itemToBeCoded,                NOPARAM,                     "1284",                                        "1284",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1285 */  { itemToBeCoded,                NOPARAM,                     "1285",                                        "1285",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1286 */  { itemToBeCoded,                NOPARAM,                     "1286",                                        "1286",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1287 */  { itemToBeCoded,                NOPARAM,                     "1287",                                        "1287",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1288 */  { itemToBeCoded,                NOPARAM,                     "1288",                                        "1288",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1289 */  { itemToBeCoded,                NOPARAM,                     "1289",                                        "1289",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1290 */  { itemToBeCoded,                NOPARAM,                     "1290",                                        "1290",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1291 */  { itemToBeCoded,                NOPARAM,                     "1291",                                        "1291",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1292 */  { itemToBeCoded,                NOPARAM,                     "1292",                                        "1292",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1293 */  { itemToBeCoded,                NOPARAM,                     "1293",                                        "1293",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1294 */  { itemToBeCoded,                NOPARAM,                     "1294",                                        "1294",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1295 */  { itemToBeCoded,                NOPARAM,                     "1295",                                        "1295",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1296 */  { itemToBeCoded,                NOPARAM,                     "1296",                                        "1296",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Curve fitting
/* 1297 */  { fnCurveFitting,               TM_VALUE,                    "BestF",                                       "BestF",                                       (0 << TAM_MAX_BITS) |   510, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_16    },
/* 1298 */  { fnCurveFitting_T,             CF_EXPONENTIAL_FITTING_EX,   "ExpF",                                        "ExpF",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1299 */  { fnCurveFitting_T,             CF_LINEAR_FITTING_EX,        "LinF",                                        "LinF",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1300 */  { fnCurveFitting_T,             CF_LOGARITHMIC_FITTING_EX,   "LogF",                                        "LogF",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1301 */  { fnCurveFitting_T,             CF_ORTHOGONAL_FITTING_EX,    "OrthoF",                                      "OrthoF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1302 */  { fnCurveFitting_T,             CF_POWER_FITTING_EX,         "PowerF",                                      "PowerF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1303 */  { fnCurveFitting_T,             CF_GAUSS_FITTING_EX,         "GaussF",                                      "GaussF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1304 */  { fnCurveFitting_T,             CF_CAUCHY_FITTING_EX,        "CauchF",                                      "CauchF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1305 */  { fnCurveFitting_T,             CF_PARABOLIC_FITTING_EX,     "ParabF",                                      "ParabF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1306 */  { fnCurveFitting_T,             CF_HYPERBOLIC_FITTING_EX,    "HypF",                                        "HypF",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1307 */  { fnCurveFitting_T,             CF_ROOT_FITTING_EX,          "RootF",                                       "RootF",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1308 */  { fnCurveFittingReset,          1,                           "AllF",                                        "AllF",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1309 */  { fnCurveFittingReset,          0,                           "ResetF",                                      "ResetF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1310 */  { itemToBeCoded,                NOPARAM,                     "1310",                                        "1310",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1311 */  { itemToBeCoded,                NOPARAM,                     "1311",                                        "1311",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1312 */  { itemToBeCoded,                NOPARAM,                     "1312",                                        "1312",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


// Menus
/* 1313 */  { itemToBeCoded,                NOPARAM,                     "ADV",                                         "ADV",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1314 */  { itemToBeCoded,                NOPARAM,                     "ANGLES",                                      "ANGLES",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1315 */  { itemToBeCoded,                NOPARAM,                     "PRINT",                                       "PRINT",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1316 */  { itemToBeCoded,                NOPARAM/*#JM#*/,             "Area:",                                       "Area:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1317 */  { itemToBeCoded,                NOPARAM/*#JM#*/,             "BITS",                                        "BITS",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1318 */  { itemToBeCoded,                NOPARAM/*#JM#*/,             "CATALOG",                                     "CAT",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },// JM
/* 1319 */  { itemToBeCoded,                NOPARAM,                     "CHARS",                                       "CHARS",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1320 */  { itemToBeCoded,                NOPARAM,                     "CLK",                                         "CLK",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1321 */  { itemToBeCoded,                NOPARAM,                     "CLR",                                         "CLR",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1322 */  { itemToBeCoded,                NOPARAM/*#JM#*/,             "CNST",                                        "CNST",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Keeps the same. Don't havce space for more on kjeyplate
/* 1323 */  { itemToBeCoded,                NOPARAM,                     "CPX",                                         "CPX",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1324 */  { itemToBeCoded,                NOPARAM,                     "CPXS",                                        "CPXS",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1325 */  { itemToBeCoded,                NOPARAM,                     "DATES",                                       "DATES",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1326 */  { itemToBeCoded,                NOPARAM,                     "DISP",                                        "DISP",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1327 */  { itemToBeCoded,                NOPARAM,                     "EQN",                                         "EQN",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1328 */  { itemToBeCoded,                NOPARAM,                     "EXP",                                         "EXP",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1329 */  { itemToBeCoded,                NOPARAM/*#JM#*/,             "Energy:",                                     "Energy:",                                     (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1330 */  { itemToBeCoded,                NOPARAM,                     "FCNS",                                        "FCNS",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1331 */  { itemToBeCoded,                NOPARAM,                     "FIN",                                         "FIN",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1332 */  { itemToBeCoded,                NOPARAM,                     "S.INTS",                                      "S.INTS",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1333 */  { itemToBeCoded,                NOPARAM,                     "FLAG",                                        "FLAG",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1334 */  { fnBaseMenu,                   NOPARAM,                     "MyMenu",                                      "MyM",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1335 */  { itemToBeCoded,                NOPARAM,                     "f'",                                          "f'",                                          (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1336 */  { itemToBeCoded,                NOPARAM,                     "f\"",                                         "f\"",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1337 */  { itemToBeCoded,                NOPARAM,                     "F&p:",                                        "F&p:",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1338 */  { itemToBeCoded,                NOPARAM,                     "L.INTS",                                      "L.INTS",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1339 */  { itemToBeCoded,                NOPARAM,                     "INFO",                                        "INFO",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1340 */  { itemToBeCoded,                NOPARAM,                     "INTS",                                        "INTS",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1341 */  { itemToBeCoded,                NOPARAM,                     "I/O",                                         "I/O",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1342 */  { itemToBeCoded,                NOPARAM,                     "LOOP",                                        "LOOP",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1343 */  { itemToBeCoded,                NOPARAM,                     "MATRS",                                       "MATRS",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1344 */  { itemToBeCoded,                NOPARAM,                     "MATX",                                        "MATX",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1345 */  { itemToBeCoded,                NOPARAM,                     "MENUS",                                       "MENUS",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1346 */  { itemToBeCoded,                NOPARAM,                     "MODE",                                        "MODE",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1347 */  { itemToBeCoded,                NOPARAM,                     "M.SIMQ",                                      "M.SIMQ",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1348 */  { itemToBeCoded,                NOPARAM,                     "M.EDIT",                                      "M.EDIT",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1349 */  { itemToBeCoded,                NOPARAM,                     "MyMenu",                                      "MyM",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1350 */  { itemToBeCoded,                NOPARAM,                     "My" STD_alpha,                                "My" STD_alpha,                                (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1351 */  { itemToBeCoded,                NOPARAM,                     "Mass:",                                       "Mass:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1352 */  { itemToBeCoded,                NOPARAM,                     "ORTHOG",                                      "Orthog",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1353 */  { itemToBeCoded,                NOPARAM,                     "REAL",                                        "REAL",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1354 */  { itemToBeCoded,                NOPARAM,                     "PROB",                                        "PROB",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1355 */  { itemToBeCoded,                NOPARAM,                     "PROGS",                                       "PROGS",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1356 */  { itemToBeCoded,                NOPARAM,                     "P.FN",                                        "P.FN",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1357 */  { itemToBeCoded,                NOPARAM,                     "P.FN" STD_ELLIPSIS,                           "P.FN" STD_ELLIPSIS,                           (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1358 */  { itemToBeCoded,                NOPARAM,                     "Power:",                                      "Power:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1359 */  { itemToBeCoded,                NOPARAM,                     "FFF+:",                                       "FFF+:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1360 */  { itemToBeCoded,                NOPARAM,                     "REALS",                                       "REALS",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1361 */  { itemToBeCoded,                NOPARAM,                     "Solver",                                      "Solver",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1362 */  { itemToBeCoded,                NOPARAM,                     "STAT",                                        "STAT",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1363 */  { itemToBeCoded,                NOPARAM,                     "STK",                                         "STK",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1364 */  { itemToBeCoded,                NOPARAM,                     "STRING",                                      "STRING",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1365 */  { itemToBeCoded,                NOPARAM,                     "TEST",                                        "TEST",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1366 */  { itemToBeCoded,                NOPARAM,                     "TIMES",                                       "TIMES",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1367 */  { itemToBeCoded,                NOPARAM,                     "TRIG",                                        "TRIG",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM
/* 1368 */  { itemToBeCoded,                NOPARAM,                     "TVM",                                         "TVM",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1369 */  { itemToBeCoded,                NOPARAM,                     "CONV",                                        "CONV",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Change U> arrow to CONV. Changed again to UNIT
/* 1370 */  { itemToBeCoded,                NOPARAM,                     "VARS",                                        "VARS",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1371 */  { itemToBeCoded,                NOPARAM,                     "Volume:",                                     "Volume:",                                     (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1372 */  { itemToBeCoded,                NOPARAM,                     "X.FN",                                        "X.FN",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1373 */  { itemToBeCoded,                NOPARAM,                     "Dist:",                                       "Dist:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1374 */  { itemToBeCoded,                NOPARAM,                     STD_alpha "INTL",                              STD_alpha "INTL",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1375 */  { itemToBeCoded,                NOPARAM,                     STD_alpha "Math",                              STD_alpha "Math",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1376 */  { itemToBeCoded,                NOPARAM,                     STD_alpha ".FN",                               STD_alpha ".FN",                               (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Changed a.FN to STRNG
/* 1377 */  { itemToBeCoded,                NOPARAM,                     STD_ALPHA STD_ELLIPSIS STD_OMEGA,              STD_ALPHA STD_ELLIPSIS STD_OMEGA,              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Upper case greek letters
/* 1378 */  { itemToBeCoded,                NOPARAM,                     STD_alpha "Misc",                              STD_alpha "Misc",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Upper case intl letters
/* 1379 */  { itemToBeCoded,                NOPARAM,                     "SYS.FL",                                      "SYS.FL",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1380 */  { itemToBeCoded,                NOPARAM,                     STD_INTEGRAL "f",                              STD_INTEGRAL "f",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1381 */  { fnIntegrate,                  TM_LABEL,                    STD_INTEGRAL "fdx",                            STD_INTEGRAL "fdx",                            (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1382 */  { itemToBeCoded,                NOPARAM,                     STD_ANGLE "CONV",                              STD_ANGLE "CONV",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Change to text DRG and change again to CONV
/* 1383 */  { itemToBeCoded,                NOPARAM,                     STD_alpha STD_ELLIPSIS STD_omega,              STD_alpha STD_ELLIPSIS STD_omega,              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Lower case greek letters
/* 1384 */  { itemToBeCoded,                NOPARAM,                     STD_alpha "intl",                              STD_alpha "intl",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // lower case intl letters
/* 1385 */  { itemToBeCoded,                NOPARAM,                     "",                                            "Tam",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1386 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamCmp",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1387 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamStoRcl",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1388 */  { itemToBeCoded,                NOPARAM,                     "1388",                                        "1388",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1389 */  { itemToBeCoded,                NOPARAM,                     "VAR",                                         "VAR",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1390 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamFlag",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1391 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamShuffle",                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1392 */  { itemToBeCoded,                NOPARAM,                     "PROG",                                        "PROG",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1393 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamLabel",                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1394 */  { fnDynamicMenu,                NOPARAM,                     "",                                            "DYNMNU",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1395 */  { itemToBeCoded,                NOPARAM,                     "PLOT.ST",                                     "PLOT.ST",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1396 */  { itemToBeCoded,                NOPARAM,                     "PLOT.LR",                                     "PLOT.LR",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1397 */  { itemToBeCoded,                NOPARAM,                     "ELLIPT",                                      "Ellipt",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1398 */  { itemToBeCoded,                NOPARAM,                     "MVAR",                                        "MVAR",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // solver variables
/* 1399 */  { itemToBeCoded,                NOPARAM,                     "EQ.EDIT",                                     "EQ.EDIT",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1400 */  { itemToBeCoded,                NOPARAM,                     "STOPW",                                       "STOPW",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1401 */  { itemToBeCoded,                NOPARAM,                     "HIST",                                        "HIST",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1402 */  { itemToBeCoded,                NOPARAM,                     "HPLOT",                                       "HPLOT",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1403 */  { itemToBeCoded,                NOPARAM,                     "1403",                                        "1403",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },


/* 1404 */  { fnIntegerMode,                SIM_1COMPL,                  "1COMPL",                                      "1COMPL",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1405 */  { fnSNAP,                       NOPARAM,                     "SNAP",                                        "SNAP",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1406 */  { fnIntegerMode,                SIM_2COMPL,                  "2COMPL",                                      "2COMPL",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1407 */  { fnMagnitude,                  NOPARAM,                     "ABS",                                         "ABS",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1408 */  { fnAgm,                        NOPARAM,                     "AGM",                                         "AGM",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1409 */  { fnAGraph,                     TM_REGISTER,                 "AGRAPH",                                      "AGRAPH",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1410 */  { fnDisplayFormatAll,           TM_VALUE,                    "ALL" ,                                        "ALL",                                         (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1411 */  { fnAssign,                     0,                           "ASSIGN",                                      "ASN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1412 */  { fnBack,                       TM_VALUE,                    "BACK",                                        "BACK",                                        (0 << TAM_MAX_BITS) |   255, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_SKIP_BACK    },
/* 1413 */  { fnBatteryVoltage,             NOPARAM,                     "BATT?",                                       "BATT?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1414 */  { fnBeep,                       NOPARAM,                     "BEEP",                                        "BEEP",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1415 */  { fnTvmBeginMode,               NOPARAM,                     "BeginP",                                      "Begin",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1416 */  { fnBn,                         NOPARAM,                     "B" STD_SUB_n,                                 "B" STD_SUB_n,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1417 */  { fnBnStar,                     NOPARAM,                     "B" STD_SUB_n STD_SUP_ASTERISK,                "B" STD_SUB_n STD_SUP_ASTERISK,                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1418 */  { fnCase,                       TM_REGISTER,                 "CASE",                                        "CASE",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1419 */  { fnClAll,                      NOT_CONFIRMED,               "CLALL",                                       "CLall",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_DISABLED     },
/* 1420 */  { fnClCVar,                     NOPARAM,                     "CLCVAR",                                      "CLCVAR",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/* 1421 */  { fnClFAll,                     NOT_CONFIRMED,               "CLFALL",                                      "CLFall",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/* 1422 */  { fnFractionType,               NOPARAM,                     "a b/c",                                       "a b/c",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1423 */  { fnClLcd,                      NOPARAM,                     "CLLCD",                                       "CLLCD",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/* 1424 */  { fnClearMenu,                  NOPARAM,                     "CLMENU",                                      "CLMENU",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1425 */  { fnClP,                        TM_LABEL,                    "CLP",                                         "CLP",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1426 */  { fnClPAll,                     NOT_CONFIRMED,               "CLPALL",                                      "CLPall",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1427 */  { fnClearRegisters,             NOT_CONFIRMED,               "CLREGS",                                      "CLREGS",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1428 */  { fnClearStack,                 NOPARAM,                     "CLSTK",                                       "CLSTK",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/* 1429 */  { fnClSigma,                    NOPARAM,                     "CL" STD_SIGMA,                                "CL" STD_SIGMA,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_NONE         },
/* 1430 */  { fnStoreMax,                   NOPARAM,                     "STO" STD_UP_ARROW,                            "Max",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1431 */  { fnConjugate,                  NOPARAM,                     "CONJ",                                        "conj",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1432 */  { fnRecallMax,                  NOPARAM,                     "RCL" STD_UP_ARROW,                            "Max",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1433 */  { fnCoefficientDetermination,   NOPARAM,                     "CORR",                                        "r",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1434 */  { fnPopulationCovariance,       NOPARAM,                     "COV",                                         "cov",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1435 */  { fnCurveFittingLR,             NOPARAM,                     "BestF?",                                      "BestF?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1436 */  { fnCross,                      NOPARAM,                     "CROSS",                                       "cross",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1437 */  { fnCxToRe,                     NOPARAM,                     "CX" STD_RIGHT_ARROW "RE",                     "CX" STD_RIGHT_ARROW "RE",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1438 */  { fnDate,                       NOPARAM,                     "DATE",                                        "DATE",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1439 */  { fnDateTo,                     NOPARAM,                     "DATE" STD_RIGHT_ARROW,                        "DATE" STD_RIGHT_ARROW,                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1440 */  { fnDay,                        NOPARAM,                     "DAY",                                         "DAY",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1441 */  { fnDblDivideRemainder,         NOPARAM,                     "DBLR",                                        "DBLR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1442 */  { fnDblMultiply,                NOPARAM,                     "DBL" STD_CROSS,                               "DBL" STD_CROSS,                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1443 */  { fnDblDivide,                  NOPARAM,                     "DBL/",                                        "DBL/",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1444 */  { fnDecomp,                     NOPARAM,                     "DECOMP",                                      "DECOMP",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1445 */  { fnAngularMode,                amDegree,                    "DEG",                                         "DEG",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1446 */  { itemToBeCoded,                NOPARAM,                     "1446",                                        "1446",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1447 */  { fnStatSa,                     NOPARAM,                     "s(a)",                                        "s(a)",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1448 */  { itemToBeCoded,                NOPARAM,                     "BLUE47",                                      "BLUE47",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1449 */  { fnDot,                        NOPARAM,                     "DOT",                                         "dot",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1450 */  { fnDisplayStack,               TM_VALUE,                    "DSTACK",                                      "DSTACK",                                      (1 << TAM_MAX_BITS) |     4, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1451 */  { fnAngularMode,                amDMS,                       "D.MS",                                        "d.ms",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1452 */  { itemToBeCoded,                NOPARAM,                     "1452",                                        "1452",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1453 */  { fnSetDateFormat,              ITM_DMY,                     "DMY",                                         "DMY",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1454 */  { fnDateToJulian,               NOPARAM,                     "D" STD_RIGHT_ARROW "J",                       "D" STD_RIGHT_ARROW "J",                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1455 */  { fnDeleteVariable,             TM_DELITM,                   "DELITM",                                      "DELITM",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_CANCEL    | EIM_DISABLED | PTP_REGISTER     },
/* 1456 */  { fnEigenvalues,                NOPARAM,                     "EIGVAL",                                      "EIGVAL",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1457 */  { fnEigenvectors,               NOPARAM,                     "EIGVEC",                                      "EIGVEC",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1458 */  { fnReturn,                     0,                           "END",                                         "END",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1459 */  { fnTvmEndMode,                 NOPARAM,                     "ENDP",                                        "End",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1460 */  { fnDisplayFormatEng,           TM_VALUE,                    "ENG",                                         "ENG",                                         (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1461 */  { fnEuclideanNorm,              NOPARAM,                     "ENORM",                                       "ENORM",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1462 */  { fnRecallMin,                  NOPARAM,                     "RCL" STD_DOWN_ARROW,                          "Min",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1463 */  { fnEqDelete,                   NOPARAM,                     "EQ.DEL",                                      "DELETE",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1464 */  { fnEqEdit,                     NOPARAM,                     "EQ.EDI",                                      "EDIT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1465 */  { fnEqNew,                      NOPARAM,                     "EQ.NEW",                                      "NEW",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1466 */  { fnErf,                        NOPARAM,                     "erf",                                         "erf",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1467 */  { fnErfc,                       NOPARAM,                     "erfc",                                        "erfc",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1468 */  { fnRaiseError,                 TM_VALUE,                    "ERR",                                         "ERR",                                         (1 << TAM_MAX_BITS) | (NUMBER_OF_ERROR_CODES - 1), CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1469 */  { fnExitAllMenus,               NOPARAM,                     "EXITALL",                                     "EXITall",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1470 */  { fnExpt,                       NOPARAM,                     "EXPT",                                        "EXPT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1471 */  { fnGetFirstGregorianDay,       NOPARAM,                     "J/G?",                                        "J/G?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1472 */  { fnFib,                        NOPARAM,                     "FIB",                                         "FIB",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1473 */  { fnDisplayFormatFix,           TM_VALUE,                    "FIX",                                         "FIX",                                         (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1474 */  { fnDiskInfo,                   NOPARAM,                     "DISK?",                                       "DISK?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1475 */  { fn1stDeriv,                   TM_LABEL,                    "f'(x)",                                       "f'(x)",                                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1476 */  { fn2ndDeriv,                   TM_LABEL,                    "f\"(x)",                                      "f\"(x)",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1477 */  { itemToBeCoded,                NOPARAM,                     "1477",                                        "1477",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1478 */  { fnGd,                         NOPARAM,                     "g" STD_SUB_d,                                 "g" STD_SUB_d,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1479 */  { fnInvGd,                      NOPARAM,                     "g" STD_SUB_d STD_SUP_MINUS_1,                 "g" STD_SUB_d STD_SUP_MINUS_1,                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1480 */  { fnAngularMode,                amGrad,                      "GRAD",                                        "GRAD",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1481 */  { itemToBeCoded,                NOPARAM,                     "1481",                                        "1481",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1482 */  { fnGotoDot,                    NOPARAM,                     "GTO.",                                        "GTO.",                                        (0 << TAM_MAX_BITS) | 16383, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1483 */  { fnHermite,                    NOPARAM,                     "H" STD_SUB_n,                                 "H" STD_SUB_n,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1484 */  { fnHermiteP,                   NOPARAM,                     "H" STD_SUB_n STD_SUB_P,                       "H" STD_SUB_n STD_SUB_P,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1485 */  { fnImaginaryPart,              NOPARAM,                     "Im",                                          "Im",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1486 */  { fnIndexMatrix,                TM_REGISTER,                 "INDEX",                                       "INDEX",                                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1487 */  { fnIxyz,                       NOPARAM,                     "I" STD_SUB_x STD_SUB_y STD_SUB_z,             "I" STD_SUB_x STD_SUB_y STD_SUB_z,             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1488 */  { fnGammaP,                     NOPARAM,                     "I" STD_GAMMA STD_SUB_p,                       "I" STD_GAMMA STD_SUB_p,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1489 */  { fnGammaQ,                     NOPARAM,                     "I" STD_GAMMA STD_SUB_q,                       "I" STD_GAMMA STD_SUB_q,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1490 */  { fnIncDecI,                    INC_FLAG,                    "I+",                                          "I+",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1491 */  { fnIncDecI,                    DEC_FLAG,                    "I-",                                          "I-",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1492 */  { fnBesselJ,                    NOPARAM,                     "J" STD_SUB_y "(x)",                           "J" STD_SUB_y "(x)",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1493 */  { fnIncDecJ,                    INC_FLAG,                    "J+",                                          "J+",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1494 */  { fnIncDecJ,                    DEC_FLAG,                    "J-",                                          "J-",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1495 */  { fnSetFirstGregorianDay,       NOPARAM,                     "J/G",                                         "J/G",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1496 */  { itemToBeCoded,                NOPARAM,                     "1496",                                        "1496",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1497 */  { fnKeyGtoXeq,                  TM_VALUE,                    "KEY",                                         "KEY",                                         (1 << TAM_MAX_BITS) |    21, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_KEYG_KEYX    },
/* 1498 */  { fnKeyGto,                     TM_KEY,                      "KEYG",                                        "KEYG",                                        (1 << TAM_MAX_BITS) |    21, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1499 */  { fnKeyXeq,                     TM_KEY,                      "KEYX",                                        "KEYX",                                        (1 << TAM_MAX_BITS) |    21, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1500 */  { fnSinc,                       NOPARAM,                     "sinc",                                        "sinc",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1501 */  { fnKeyType,                    TM_REGISTER,                 "KTYP?",                                       "KTYP?",                                       (1 << TAM_MAX_BITS) |    85, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1502 */  { fnLastX,                      NOPARAM,                     "LASTx",                                       "LASTx",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1503 */  { fnCheckLabel,                 TM_LABEL,                    "LBL?",                                        "LBL?",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_LABEL        },
/* 1504 */  { fnIsLeap,                     NOPARAM,                     "LEAP?",                                       "LEAP?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1505 */  { fnLaguerre,                   NOPARAM,                     "L" STD_SUB_m ,                                "L" STD_SUB_m ,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1506 */  { fnLaguerreAlpha,              NOPARAM,                     "L" STD_SUB_m STD_SUB_alpha,                   "L" STD_SUB_m STD_SUB_alpha,                   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1507 */  { fnLnBeta,                     NOPARAM/*#JM#*/,             "LN" STD_beta,                                 "LN" STD_beta,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1508 */  { fnLnGamma,                    NOPARAM/*#JM#*/,             "LN" STD_GAMMA,                                "LN" STD_GAMMA,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1509 */  { fnLoad,                       LM_ALL,                      "LOAD",                                        "LOAD",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1510 */  { fnLoad,                       LM_PROGRAMS,                 "LOADP",                                       "LOADP",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1511 */  { fnLoad,                       LM_REGISTERS,                "LOADR",                                       "LOADR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1512 */  { fnLoad,                       LM_SYSTEM_STATE,             "LOADSS",                                      "LOADSS",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1513 */  { fnLoad,                       LM_SUMS,                     "LOAD" STD_SIGMA,                              "LOAD" STD_SIGMA,                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1514 */  { allocateLocalRegisters,       TM_VALUE,                    "LocR",                                        "LocR",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1515 */  { fnGetLocR,                    NOPARAM,                     "LocR?",                                       "LocR?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1516 */  { fnProcessLR,                  NOPARAM,                     "L.R.",                                        "L.R.",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1517 */  { fnMant,                       NOPARAM,                     "MANT",                                        "MANT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1518 */  { fnEditLinearEquationMatrixX,  NOPARAM,                     "Mat_X",                                       "Mat X",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1519 */  { fnFreeMemory,                 NOPARAM,                     "MEM?",                                        "MEM?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1520 */  { fnProgrammableMenu,           NOPARAM,                     "MENU",                                        "MENU",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1521 */  { fnMonth,                      NOPARAM,                     "MONTH",                                       "MONTH",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1522 */  { fnErrorMessage,               TM_REGISTER,                 "MSG",                                         "MSG",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1523 */  { fnAngularMode,                amMultPi,                    "MUL" STD_pi,                                  "MUL" STD_pi,                                  (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1524 */  { fnNop,                        TM_REGISTER,                 "MVAR",                                        "MVAR",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_REGISTER     },
/* 1525 */  { fnDelRow,                     NOPARAM,                     "M.DELR",                                      "DELR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1526 */  { fnSetMatrixDimensions,        TM_M_DIM,                    "M.DIM",                                       "DIM",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1527 */  { fnGetMatrixDimensions,        NOPARAM,                     "M.DIM?",                                      "DIM?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1528 */  { fnSetDateFormat,              ITM_MDY,                     "MDY",                                         "MDY",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1529 */  { fnEditMatrix,                 NOPARAM,                     "M.EDI",                                       "EDIT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1530 */  { fnEditMatrix,                 TM_REGISTER,                 "M.EDIN",                                      "EDITN",                                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1531 */  { fnGetMatrix,                  NOPARAM,                     "M.GET",                                       "GETM",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1532 */  { fnGoToElement,                NOPARAM,                     "M.GOTO",                                      "GOTO",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1533 */  { fnSetGrowMode,                ON,                          "M.GROW",                                      "GROW",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1534 */  { fnInsRow,                     NOPARAM,                     "M.INSR",                                      "INSR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1535 */  { fnLuDecomposition,            NOPARAM,                     "M.LU",                                        "M.LU",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1536 */  { fnNewMatrix,                  NOPARAM,                     "M.NEW",                                       "NEW",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1537 */  { fnOldMatrix,                  NOPARAM,                     "M.OLD",                                       "OLD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1538 */  { fnPutMatrix,                  NOPARAM,                     "M.PUT",                                       "PUTM",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1539 */  { fnSwapRows,                   NOPARAM,                     "M.R" STD_RIGHT_OVER_LEFT_ARROW "R",           "R" STD_RIGHT_OVER_LEFT_ARROW "R",             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1540 */  { fnSincpi,                     NOPARAM,                     "sinc" STD_pi,                                 "sinc" STD_pi,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1541 */  { fnSetGrowMode,                OFF,                         "M.WRAP",                                      "WRAP",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1542 */  { fnNop,                        NOPARAM,                     "NOP",                                         "NOP",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1543 */  { fnOff,                        NOPARAM,                     "OFF",                                         "OFF",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1544 */  { fnDropY,                      NOPARAM,                     "DROPy",                                       "DROPy",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1545 */  { fnStoreMin,                   NOPARAM,                     "STO" STD_DOWN_ARROW,                          "Min",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1546 */  { fnPgmInt,                     TM_LABEL,                    "PGMINT",                                      "PGMINT",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1547 */  { fnPgmSlv,                     TM_SOLVE,                    "PGMSLV",                                      "PGMSLV",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1548 */  { fnPixel,                      NOPARAM,                     "PIXEL",                                       "PIXEL",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1549 */  { fnPlotStat,                   PLOT_START,                  "SCATR",                                       "SCATR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1550 */  { fnLegendre,                   NOPARAM,                     "P" STD_SUB_n,                                 "P" STD_SUB_n,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1551 */  { fnPoint,                      NOPARAM,                     "POINT",                                       "POINT",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1552 */  { fnLoad,                       LM_NAMED_VARIABLES,          "LOADV",                                       "LOADV",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1553 */  { allocateLocalRegisters,       0,                           "PopLR",                                       "PopLR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1554 */  { itemToBeCoded,                NOPARAM,                     "1554",                                        "1554",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1555 */  { itemToBeCoded,                NOPARAM,                     "1555",                                        "1555",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1556 */  { fnPutKey,                     TM_REGISTER,                 "PUTK",                                        "PUTK",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_REGISTER     },
/* 1557 */  { fnAngularMode,                amRadian,                    "RAD",                                         "RAD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1558 */  { fnGetDmx,                     NOPARAM,                     "DMX?",                                        "DMX?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1559 */  { fnRandom,                     NOPARAM,                     "RAN#",                                        "RAN#",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1560 */  { registerBrowser,              NOPARAM/*#JM#*/,             "REGS",                                        "REGS",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Changed RBR to REGS
/* 1561 */  { fnRecallConfig,               TM_REGISTER,                 "RCLCFG",                                      "Config",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1562 */  { fnRecallElement,              NOPARAM,                     "RCLEL",                                       "RCLEL",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1563 */  { fnRecallIJ,                   NOPARAM,                     "RCLIJ",                                       "RCLIJ",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1564 */  { fnRecallStack,                TM_REGISTER,                 "RCLS",                                        "RCLS",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1565 */  { fnRdp,                        TM_VALUE,                    "RDP",                                         "RDP",                                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1566 */  { fnRealPart,                   NOPARAM,                     "Re",                                          "Re",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1567 */  { fnLoadProgram,                NOPARAM,                     "READP",                                       "READP",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1568 */  { fnReset,                      NOT_CONFIRMED,               "RESET",                                       "RESET",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABL_XEQ | EIM_DISABLED | PTP_DISABLED     },
/* 1569 */  { fnReToCx,                     NOPARAM,                     "RE" STD_RIGHT_ARROW "CX",                     "RE" STD_RIGHT_ARROW "CX",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1570 */  { fnSwapRealImaginary,          NOPARAM,                     "Re" STD_RIGHT_OVER_LEFT_ARROW "Im",           "Re" STD_RIGHT_OVER_LEFT_ARROW "Im",           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1571 */  { fnClP,                        TM_DELITM,                   "DELITM",                                      "DELITM",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1572 */  { fnDeleteMenu,                 TM_DELITM,                   "DELITM",                                      "DELITM",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1573 */  { fnDisplayFormatDsp,           TM_VALUE,                    "DSP",                                         "DSP",                                         (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1574 */  { fnRowNorm,                    NOPARAM,                     "RNORM",                                       "RNORM",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1575 */  { fnExpM1,                      NOPARAM,                     STD_EulerE STD_SUP_x "-1",                     STD_EulerE STD_SUP_x "-1",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1576 */  { fnExportProgram,              TM_LABEL,                    "XPORTP",                                      "XPORTP",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1577 */  { fnRsd,                        TM_VALUE,                    "RSD",                                         "RSD",                                         (1 << TAM_MAX_BITS) |    34, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1578 */  { fnRowSum,                     NOPARAM,                     "RSUM",                                        "RSUM",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1579 */  { fnReturn,                     1,                           "RTN+1",                                       "RTN+1",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1580 */  { fnRegClr,                     NOPARAM,                     "R-CLR",                                       "R-CLR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1581 */  { fnRegCopy,                    NOPARAM,                     "R-COPY",                                      "R-COPY",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1582 */  { fnRegSort,                    NOPARAM,                     "R-SORT",                                      "R-SORT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1583 */  { fnRegSwap,                    NOPARAM,                     "R-SWAP",                                      "R-SWAP",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1584 */  { fnJacobiAmplitude,            NOPARAM,                     STD_psi "(u,m)",                               STD_psi "(u,m)",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1585 */  { fnSampleStdDev,               NOPARAM,                     "s",                                           "s",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1586 */  { fnSave,                       SM_MANUAL_SAVE,              "SAVE",                                        "SAVE",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1587 */  { fnDisplayFormatSci,           TM_VALUE,                    "SCI",                                         "SCI",                                         (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1588 */  { fnGetSignificantDigits,       NOPARAM,                     "SDIGS?",                                      "SDIGS?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1589 */  { fnSeed,                       NOPARAM,                     "SEED",                                        "SEED",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1590 */  { fnSaveProgram,                TM_LABEL,                    "WRITEP",                                      "WRITEP",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1591 */  { configCommon,                 CFG_CHINA,                   "SETCHN",                                      "CHINA",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1592 */  { fnSetDate,                    NOPARAM,                     "SETDAT",                                      "SETDAT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1593 */  { configCommon,                 CFG_EUROPE,                  "SETEUR",                                      "EUROPE",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1594 */  { configCommon,                 CFG_INDIA,                   "SETIND",                                      "INDIA",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1595 */  { configCommon,                 CFG_JAPAN,                   "SETJPN",                                      "JAPAN",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1596 */  { configCommon,                 CFG_DFLT,                    "SETDFLT",                                     "DFLT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1597 */  { fnSetTime,                    NOPARAM,                     "SETTIM",                                      "SETTIM",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1598 */  { configCommon,                 CFG_UK,                      "SETUK",                                       "UK",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1599 */  { configCommon,                 CFG_USA,                     "SETUSA",                                      "USA",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1600 */  { fnSign,                       NOPARAM,                     "sign",                                        "sign",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1601 */  { fnIntegerMode,                SIM_SIGNMT,                  "SIGNMT",                                      "SIGNMT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1602 */  { fnSimultaneousLinearEquation, TM_VALUE,                    "SIM_EQ",                                      "SIM EQ",                                      (1 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1603 */  { fnSkip,                       TM_VALUE,                    "SKIP",                                        "SKIP",                                        (0 << TAM_MAX_BITS) |   255, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_SKIP_BACK    },
/* 1604 */  { fnSlvq,                       NOPARAM,                     "SLVQ",                                        "SLVQ",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1605 */  { fnStandardError,              NOPARAM,                     "s" STD_SUB_m,                                 "s" STD_SUB_m,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1606 */  { fnGetIntegerSignMode,         NOPARAM,                     "ISM?",                                        "ISM?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1607 */  { fnWeightedStandardError,      NOPARAM,                     "s" STD_SUB_m STD_SUB_w,                       "s" STD_SUB_m STD_SUB_w,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1608 */  { fnSolve,                      TM_SOLVE,                    "SOLVE",                                       "SOLVE",                                       (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_REGISTER     },
/* 1609 */  { fnGetStackSize,               NOPARAM,                     "SSIZE?",                                      "SSIZE?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1610 */  { flagBrowser,                  5 /*#JM#*/,                  "STATUS",                                      "STATUS",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1611 */  { fnStoreConfig,                TM_REGISTER,                 "STOCFG",                                      "Config",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1612 */  { fnStoreElement,               NOPARAM,                     "STOEL",                                       "STOEL",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1613 */  { fnStoreIJ,                    NOPARAM,                     "STOIJ",                                       "STOIJ",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1614 */  { fnLnP1,                       NOPARAM,                     "LN(1+x)",                                     "LN(1+x)",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1615 */  { fnStoreStack,                 TM_REGISTER,                 "STOS",                                        "STOS",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1616 */  { fnSumXY,                      NOPARAM,                     "x" STD_SUB_S STD_SUB_U STD_SUB_M,             "x" STD_SUB_S STD_SUB_U STD_SUB_M,             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1617 */  { fnWeightedSampleStdDev,       NOPARAM,                     "s" STD_SUB_w,                                 "s" STD_SUB_w,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1618 */  { fnSampleCovariance,           NOPARAM,                     "s" STD_SUB_x STD_SUB_y,                       "s" STD_SUB_x STD_SUB_y,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1619 */  { fnDisplayFormatTime,          TM_VALUE,                    "TDISP",                                       "TDISP",                                       (0 << TAM_MAX_BITS) |     6, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1620 */  { fnTicks,                      NOPARAM,                     "TICKS",                                       "TICKS",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1621 */  { fnTime,                       NOPARAM,                     "TIME",                                        "TIME",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1622 */  { fnItemTimerApp,               NOPARAM/*#JM#*/,             "STOPW",                                       "STOPW",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1623 */  { fnChebyshevT,                 NOPARAM,                     "T" STD_SUB_n,                                 "T" STD_SUB_n,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1624 */  { fnTone,                       TM_VALUE,                    "TONE",                                        "TONE",                                        (0 << TAM_MAX_BITS) |     9, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NUMBER_8     },
/* 1625 */  { fnSwapT,                      TM_REGISTER,                 "t" STD_RIGHT_OVER_LEFT_ARROW,                 "t" STD_RIGHT_OVER_LEFT_ARROW,                 (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1626 */  { fnUlp,                        NOPARAM,                     "ULP?",                                        "ULP?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1627 */  { fnChebyshevU,                 NOPARAM,                     "U" STD_SUB_n,                                 "U" STD_SUB_n,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1628 */  { fnUnitVector,                 NOPARAM,                     "UNITV",                                       "UNITV",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1629 */  { fnIntegerMode,                SIM_UNSIGN,                  "UNSIGN",                                      "UNSIGN",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1630 */  { fnVarMnu,                     TM_LABEL,                    "VARMNU",                                      "VarMNU",                                      (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_LABEL        },
/* 1631 */  { fnVersion,                    NOPARAM,                     "VERS?",                                       "VERS?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1632 */  { fnIDivR,                      NOPARAM,                     "IDIVR",                                       "IDIVR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1633 */  { fnWday,                       NOPARAM,                     "WDAY",                                        "WDAY",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1634 */  { fnWho,                        NOPARAM,                     "WHO?",                                        "WHO?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1635 */  { fnWnegative,                  NOPARAM,                     "W" STD_SUB_m,                                 "W" STD_SUB_m,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1636 */  { fnWpositive,                  NOPARAM,                     "W" STD_SUB_p,                                 "W" STD_SUB_p,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1637 */  { fnWinverse,                   NOPARAM,                     "W" STD_SUP_MINUS_1,                           "W" STD_SUP_MINUS_1,                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1638 */  { fnSetWordSize,                TM_VALUE,                    "WSIZE",                                       "WSIZE",                                       (0 << TAM_MAX_BITS) |    64, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1639 */  { fnGetWordSize,                NOPARAM,                     "WSIZE?",                                      "WSIZE?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1640 */  { fnMeanXY,                     NOPARAM,                     STD_x_BAR,                                     STD_x_BAR,                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1641 */  { fnGeometricMeanXY,            NOPARAM,                     STD_x_BAR STD_SUB_G,                           STD_x_BAR STD_SUB_G,                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1642 */  { fnWeightedMeanX,              NOPARAM,                     STD_x_BAR STD_SUB_w,                           STD_x_BAR STD_SUB_w,                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1643 */  { fnXIsFny,                     NOPARAM,                     STD_x_CIRC,                                    STD_x_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1644 */  { fnXToDate,                    NOPARAM,                     "x" STD_RIGHT_ARROW "DATE",                    "x" STD_RIGHT_ARROW "DATE",                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1645 */  { fnXToAlpha,                   NOPARAM,                     "x" STD_RIGHT_ARROW STD_alpha,                 "x" STD_RIGHT_ARROW STD_alpha,                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1646 */  { fnQrDecomposition,            NOPARAM,                     "M.QR",                                        "M.QR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1647 */  { fnYear,                       NOPARAM,                     "YEAR",                                        "YEAR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1648 */  { fnYIsFnx,                     NOPARAM,                     STD_y_CIRC,                                    STD_y_CIRC,                                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1649 */  { fnSetDateFormat,              ITM_YMD,                     "YMD",                                         "YMD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1650 */  { fnSwapY,                      TM_REGISTER,                 "y" STD_RIGHT_OVER_LEFT_ARROW,                 "y" STD_RIGHT_OVER_LEFT_ARROW,                 (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1651 */  { fnSwapZ,                      TM_REGISTER,                 "z" STD_RIGHT_OVER_LEFT_ARROW,                 "z" STD_RIGHT_OVER_LEFT_ARROW,                 (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1652 */  { fnAlphaLeng,                  TM_REGISTER,                 STD_alpha "LENG?",                             STD_alpha "LENG?",                             (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1653 */  { fnXmax,                       NOPARAM,                     "x" STD_SUB_M STD_SUB_A STD_SUB_X,             "x" STD_SUB_M STD_SUB_A STD_SUB_X,             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1654 */  { fnXmin,                       NOPARAM,                     "x" STD_SUB_M STD_SUB_I STD_SUB_N,             "x" STD_SUB_M STD_SUB_I STD_SUB_N,             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1655 */  { fnAlphaPos,                   TM_REGISTER,                 STD_alpha "POS?",                              STD_alpha "POS?",                              (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1656 */  { fnAlphaRL,                    TM_REGISTER,                 STD_alpha "RL",                                STD_alpha "RL",                                (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1657 */  { fnAlphaRR,                    TM_REGISTER,                 STD_alpha "RR",                                STD_alpha "RR",                                (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1658 */  { fnAlphaSL,                    TM_REGISTER,                 STD_alpha "SL",                                STD_alpha "SL",                                (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1659 */  { fnAlphaSR,                    TM_REGISTER,                 STD_alpha "SR",                                STD_alpha "SR",                                (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1660 */  { fnAlphaToX,                   TM_REGISTER,                 STD_alpha STD_RIGHT_ARROW "x",                 STD_alpha STD_RIGHT_ARROW "x",                 (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1661 */  { fnBeta,                       NOPARAM,                     STD_beta "(x,y)",                              STD_beta "(x,y)",                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1662 */  { fnGammaXyLower,               NOPARAM,                     STD_gamma STD_SUB_x STD_SUB_y,                 STD_gamma STD_SUB_x STD_SUB_y,                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1663 */  { fnGammaXyUpper,               NOPARAM,                     STD_GAMMA STD_SUB_x STD_SUB_y,                 STD_GAMMA STD_SUB_x STD_SUB_y,                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1664 */  { fnGamma,                      NOPARAM,                     STD_GAMMA "(x)",                               STD_GAMMA "(x)",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1665 */  { fnBesselY,                    NOPARAM,                     "Y" STD_SUB_y "(x)",                           "Y" STD_SUB_y "(x)",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1666 */  { fnDeltaPercent,               NOPARAM,                     STD_DELTA "%",                                 STD_DELTA "%",                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1667 */  { fnGeometricSampleStdDev,      NOPARAM,                     STD_epsilon,                                   STD_epsilon,                                   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1668 */  { fnGeometricStandardError,     NOPARAM,                     STD_epsilon STD_SUB_m,                         STD_epsilon STD_SUB_m,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1669 */  { fnGeometricPopulationStdDev,  NOPARAM,                     STD_epsilon STD_SUB_p,                         STD_epsilon STD_SUB_p,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1670 */  { fnZeta,                       NOPARAM,                     STD_zeta "(x)",                                STD_zeta "(x)",                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1671 */  { fnProgrammableProduct,        TM_LABEL,                    STD_PRODUCT STD_SUB_n,                         STD_PRODUCT STD_SUB_n,                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1672 */  { fnProgrammableSum,            TM_LABEL,                    STD_SUM STD_SUB_n,                             STD_SUM STD_SUB_n,                             (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1673 */  { fnPopulationStdDev,           NOPARAM,                     STD_sigma,                                     STD_sigma,                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1674 */  { fnWeightedPopulationStdDev,   NOPARAM,                     STD_sigma STD_SUB_w,                           STD_sigma STD_SUB_w,                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1675 */  { fnRandomI,                    NOPARAM,                     "RANI#",                                       "RANI#",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1676 */  { fnP_All_Regs,                 5              /*#JM#*/,     STD_PRINTER "x",                               STD_PRINTER "x",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1677 */  { itemToBeCoded,                NOPARAM,                     "1677",                                        "1677",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1678 */  { fnGetRange,                   NOPARAM,                     "RANGE?",                                      "RANGE?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1679 */  { fnM1Pow,                      NOPARAM,                     "(-1)" STD_SUP_x,                              "(-1)" STD_SUP_x,                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1680 */  { fnMulMod,                     NOPARAM,                     STD_CROSS "MOD",                               STD_CROSS "MOD",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1681 */  { fnToDate,                     NOPARAM,                     STD_RIGHT_ARROW "DATE",                        STD_RIGHT_ARROW "DATE",                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1682 */  { fnJacobiSn,                   NOPARAM,                     "sn(u,m)",                                     "sn(u,m)",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1683 */  { fnJacobiCn,                   NOPARAM,                     "cn(u,m)",                                     "cn(u,m)",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1684 */  { fnJacobiDn,                   NOPARAM,                     "dn(u,m)",                                     "dn(u,m)",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1685 */  { fnToHr,                       NOPARAM,                     STD_RIGHT_ARROW "HR",                          ".d",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1686 */  { fnToHms,                      NOPARAM/*#JM#*/,             STD_RIGHT_ARROW "h.ms",                        STD_RIGHT_ARROW "h.ms",                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM mod
/* 1687 */  { fnChangeBase,                 TM_VALUE_CHB,                STD_RIGHT_ARROW "INT",                         "#",                                           (2 << TAM_MAX_BITS) |    16, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1688 */  { itemToBeCoded,                NOPARAM,                     "1688",                                        "1688",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1689 */  { itemToBeCoded,                NOPARAM,                     "1689",                                        "1689",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1690 */  { itemToBeCoded,                NOPARAM,                     "1690",                                        "1690",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1691 */  { fnToReal,                     NOPARAM,                     STD_RIGHT_ARROW "REAL",                        ".d",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1692 */  { fnPcSigmaDeltaPcXmean,        NOPARAM,                     "%" STD_SIGMA "," STD_DELTA "%" STD_x_BAR,     "%" STD_SIGMA "," STD_DELTA "%" STD_x_BAR,     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1693 */  { fnDeltaPercentXmean,          NOPARAM,                     STD_DELTA "%" STD_x_BAR,                       STD_DELTA "%" STD_x_BAR,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1694 */  { fnShuffle,                    TM_SHUFFLE,                  STD_RIGHT_OVER_LEFT_ARROW,                     STD_RIGHT_OVER_LEFT_ARROW,                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_SHUFFLE      },
/* 1695 */  { fnPercent,                    NOPARAM,                     "%",                                           "%",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1696 */  { fnPercentMRR,                 NOPARAM,                     "%MRR",                                        "%MRR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1697 */  { fnPercentT,                   NOPARAM,                     "%T",                                          "%T",                                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1698 */  { fnPercentSigma,               NOPARAM,                     "%" STD_SIGMA,                                 "%" STD_SIGMA,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1699 */  { fnPercentPlusMG,              NOPARAM,                     "%+MG",                                        "%+MG",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1700 */  { fnIntegrate,                  TM_REGISTER,                 STD_INTEGRAL,                                  STD_INTEGRAL,                                  (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1701 */  { fnExpMod,                     NOPARAM,                     "^MOD",                                        "^MOD",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1702 */  { fnDeterminant,                NOPARAM,                     "|M|",                                         "|M|",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1703 */  { fnParallel,                   NOPARAM,                     STD_PARALLEL,                                  STD_PARALLEL,                                  (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM
/* 1704 */  { fnTranspose,                  NOPARAM,                     "[M]" STD_TRANSPOSED,                          "[M]" STD_TRANSPOSED,                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1705 */  { fnInvertMatrix,               NOPARAM,                     "[M]" STD_SUP_MINUS_1,                         "[M]" STD_SUP_MINUS_1,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1706 */  { fnArg_all,                    NOPARAM/*#JM#*/,             STD_MEASURED_ANGLE,                            STD_MEASURED_ANGLE,                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1707 */  { itemToBeCoded,                NOPARAM,                     "1707",                                        "1707",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1708 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "ADV",                             STD_PRINTER "ADV",                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1709 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "CHAR",                            STD_PRINTER "CHAR",                            (0 << TAM_MAX_BITS) |   127, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1710 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "DLAY",                            STD_PRINTER "DLAY",                            (0 << TAM_MAX_BITS) |   127, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1711 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "LCD",                             STD_PRINTER "LCD",                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1712 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "MODE",                            STD_PRINTER "MODE",                            (0 << TAM_MAX_BITS) |     3, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1713 */  { fnExportProgram,              TM_LABEL,                    STD_PRINTER "PROG",                            STD_PRINTER "PROG",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },
/* 1714 */  { fnP_Regs,                     TM_REGISTER,                 STD_PRINTER "r",                               STD_PRINTER "r",                               (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_REGISTER     },
/* 1715 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "REGS",                            STD_PRINTER "REGS",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1716 */  { fnP_All_Regs,                 1              /*#JM#*/,     STD_PRINTER "STK",                             STD_PRINTER "STK",                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1717 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "TAB",                             STD_PRINTER "TAB",                             (0 << TAM_MAX_BITS) |   127, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1718 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "USER",                            STD_PRINTER "USER",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1719 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "WIDTH",                           STD_PRINTER "WIDTH",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1720 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER STD_SIGMA,                         STD_PRINTER STD_SIGMA,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1721 */  { itemToBeCoded,                NOPARAM,                     STD_PRINTER "#",                               STD_PRINTER "#",                               (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },

/* 1722 */  { fontBrowser,                  NOPARAM,                     "FBR",                                         "FBR",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     }, // Font browser

/* 1723 */  { fnUndo,                       NOPARAM,                     "UNDO",                                        STD_UNDO,                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1724 */  { fnPem,                        NOPARAM/*#JM#*/,             "PRGM",                                        "PRGM",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_DISABLED     },//JM Change P/R to PRGM
/* 1725 */  { fnRunProgram,                 NOPARAM,                     "R/S",                                         "R/S",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1726 */  { fnEllipticK,                  NOPARAM,                     "K(m)",                                        "K(m)",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1727 */  { fnEllipticE,                  NOPARAM,                     "E(m)",                                        "E(m)",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1728 */  { fnEllipticPi,                 NOPARAM,                     STD_PI "(n,m)",                                STD_PI "(n,m)",                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1729 */  { fnFlipFlag,                   FLAG_USER,                   "USER",                                        "USER",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1730 */  { fnKeyCC,                      NOPARAM,                     "CC",                                          "CC",                                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1731 */  { fnSHIFTf /*JM*/,              NOPARAM,                     "",                                            "f",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1732 */  { fnSHIFTg /*JM*/,              NOPARAM,                     "",                                            "g",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1733 */  { fnKeyUp,                      NOPARAM,                     "UP",                                          STD_UP_ARROW,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1734 */  { fnBst,                        NOPARAM,                     "BST",                                         STD_HAMBURGER STD_BST,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1735 */  { fnKeyDown,                    NOPARAM,                     "DOWN",                                        STD_DOWN_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1736 */  { fnSst,                        NOPARAM,                     "SST",                                         STD_HAMBURGER STD_SST,                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1737 */  { fnKeyExit,                    NOPARAM,                     "EXIT",                                        "EXIT",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1738 */  { fnKeyBackspace,               NOPARAM/*#JM#*/,             "BKSPC",                                       STD_LEFT_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1739 */  { itemToBeCoded,                NOPARAM,                     "1739",                                        "1739",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1740 */  { fnAim,                        NOPARAM,                     STD_alpha,                                     STD_alpha,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1741 */  { fnKeyDotD,                    NOPARAM,                     ".d",                                          ".d",                                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1742 */  { fnShow_SCROLL,                NOPARAM/*#JM#*/,             "SHOW",                                        "SHOW",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1743 */  { backToSystem,                 NOT_CONFIRMED  /*#JM#*/,     "SYSTEM",                                      "SYSTEM",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1744 */  { itemToBeCoded,                NOPARAM,                     "1744",                                        "1744",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1745 */  { fnVectorAngle,                NOPARAM,                     "V" STD_MEASURED_ANGLE,                        "V" STD_MEASURED_ANGLE,                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1746 */  { fnHarmonicMeanXY,             NOPARAM,                     STD_x_BAR STD_SUB_H,                           STD_x_BAR STD_SUB_H,                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1747 */  { fnRMSMeanXY,                  NOPARAM,                     STD_x_BAR STD_SUB_R STD_SUB_M STD_SUB_S,       STD_x_BAR STD_SUB_R STD_SUB_M STD_SUB_S,       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1748 */  { fnArccos,                     NOPARAM,                     "ACOS",                                        "ACOS",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1749 */  { fnArcsin,                     NOPARAM,                     "ASIN",                                        "ASIN",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1750 */  { fnArctan,                     NOPARAM,                     "ATAN",                                        "ATAN",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1751 */  { fnDeterminant,                NOPARAM,                     "DET",                                         "DET",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1752 */  { fnInvertMatrix,               NOPARAM,                     "INVRT",                                       "INVRT",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1753 */  { fnTranspose,                  NOPARAM,                     "TRANS",                                       "TRANS",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1754 */  { fnProgrammableiProduct,       TM_LABEL,                    "i" STD_PRODUCT STD_SUB_n,                     "i" STD_PRODUCT STD_SUB_n,                     (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1755 */  { fnProgrammableiSum,           TM_LABEL,                    "i" STD_SUM STD_SUB_n,                         "i" STD_SUM STD_SUB_n,                         (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },
/* 1756 */  { fnPlotStat,                   PLOT_ORTHOF,                 "CENTRL",                                      "CENTRL",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1757 */  { fnOldItemError,               NOPARAM,                     ">HIDE<",                                      ">HIDE<",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//Old item
/* 1758 */  { fnPlotCloseSmi,               NOPARAM,                     "s" STD_SUB_m STD_SUB_i,                       "s" STD_SUB_m STD_SUB_i,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1759 */  { fnPlotStat,                   PLOT_LR,                     "ASSESS",                                      "ASSESS",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1760 */  { fnPlotStat,                   PLOT_NXT,                    "NXTFIT",                                      "NXTFIT",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1761 */  { fnPlotStat,                   PLOT_REV,                    "",                                            "",                                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1762 */  { fnPlotZoom,                   NOPARAM,                     "ZOOM",                                        "ZOOM",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1763 */  { fnEllipticFphi,               NOPARAM,                     "F(" STD_phi ",m)",                            "F(" STD_phi ",m)",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1764 */  { fnEllipticEphi,               NOPARAM,                     "E(" STD_phi ",m)",                            "E(" STD_phi ",m)",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1765 */  { fnJacobiZeta,                 NOPARAM,                     STD_ZETA "(" STD_phi ",m)",                    STD_ZETA "(" STD_phi ",m)",                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1766 */  { fnGetHide,                    NOPARAM,                     "HIDE?",                                       "HIDE?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1767 */  { fnEqCalc,                     NOPARAM,                     "Calc",                                        "Calc",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1768 */  { fnSquareRoot,                 NOPARAM,                     "SQRT",                                        "SQRT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1769 */  { fnRecall,                     RESERVED_VARIABLE_FV,        STD_SUB_R STD_SPACE_3_PER_EM "FV",             STD_SUB_R STD_SPACE_3_PER_EM "FV",             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1770 */  { fnRecall,                     RESERVED_VARIABLE_IPONA,     STD_SUB_R STD_SPACE_3_PER_EM "i%/a",           STD_SUB_R STD_SPACE_3_PER_EM "i%/a",           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1771 */  { fnRecall,                     RESERVED_VARIABLE_NPER,      STD_SUB_R STD_SPACE_3_PER_EM NPER_,            STD_SUB_R STD_SPACE_3_PER_EM NPER_,            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1772 */  { fnRecall,                     RESERVED_VARIABLE_PERONA,    STD_SUB_R STD_SPACE_3_PER_EM "PER/a",          STD_SUB_R STD_SPACE_3_PER_EM "PER/a",          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1773 */  { fnRecall,                     RESERVED_VARIABLE_PMT,       STD_SUB_R STD_SPACE_3_PER_EM "PMT",            STD_SUB_R STD_SPACE_3_PER_EM "PMT",            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1774 */  { fnRecall,                     RESERVED_VARIABLE_PV,        STD_SUB_R STD_SPACE_3_PER_EM "PV",             STD_SUB_R STD_SPACE_3_PER_EM "PV",             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1775 */  { fnAtan2,                      NOPARAM /*#JM#*/,            "ATAN2",                                       "ATAN2",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_ENABLED  | PTP_NONE         },
/* 1776 */  { fnAddTimerApp,                NOPARAM,                     "ADD",                                         "ADD",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1777 */  { fnDecisecondTimerApp,         NOPARAM,                     "0.1s",                                        "0.1s",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1778 */  { fnResetTimerApp,              NOPARAM,                     "RESET",                                       "RESET",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1779 */  { fnRecallTimerApp,             TM_REGISTER,                 "RCL",                                         "",                                            (0 << TAM_MAX_BITS) |    99, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1780 */  { fnDeleteBackup,               NOT_CONFIRMED,               "CLBKUP",                                      "CLBKUP",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1781 */  { fnEqSolvGraph,                EQ_SOLVE,                    "cpxSlv",                                      "cpxSlv",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1782 */  { fnEqSolvGraph,                EQ_PLOT,                     "Draw",                                        "Draw",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1783 */  { itemToBeCoded,                NOPARAM,                     "GRAPH",                                       "GRAPH",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1784 */  { graph_eqn,                    1,                           "reDraw",                                      "reDraw",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1785 */  { fn1stDerivEq,                 NOPARAM,                     "f'here",                                      "f'here",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1786 */  { fn2ndDerivEq,                 NOPARAM,                     "f\"here",                                     "f\"here",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1787 */  { fnSetNBins,                   NOPARAM,                     "nBINS",                                       "nBINS",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1788 */  { fnSetLoBin,                   NOPARAM,                     STD_DOWN_ARROW "BIN",                          STD_DOWN_ARROW "BIN",                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1789 */  { fnSetHiBin,                   NOPARAM,                     STD_UP_ARROW "BIN",                            STD_UP_ARROW "BIN",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1790 */  { fnConvertStatsToHisto,        ITM_X,                       "HISTOX",                                      "HISTOX",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1791 */  { fnConvertStatsToHisto,        ITM_Y,                       "HISTOY",                                      "HISTOY",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1792 */  { fnPlotStat,                   H_PLOT,                      "HPLOT",                                       "HPLOT",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1793 */  { fnPlotStat,                   H_NORM,                      "HNORM",                                       "HNORM",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1794 */  { fnSqrt1Px2,                   NOPARAM,                     STD_SQUARE_ROOT "(1+x" STD_SUP_2 ")",          STD_SQUARE_ROOT "(1+x" STD_SUP_2 ")",          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },



//Jaymos C43 extensions
/* 1795 */  { fn_cnst_op_j_pol,             NOPARAM,                     "op_" STD_op_i STD_SUB_SUN,                    STD_op_i STD_SUB_SUN,                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM Operator j
/* 1796 */  { SetSetting,                   JC_BASE_MYM,                 "MyM",                                         "MyM",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM NOBASE MENU SETTING
/* 1797 */  { SetSetting,                   JC_G_DOUBLETAP,              "g.2Tp",                                       "g.2Tp",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM KEY TAP DOUBLE SETTING
/* 1798 */  { SetSetting,                   JC_CPXMULT,                  "CPXmul",                                      "CPXmul",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1799 */  { fnP_All_Regs,                 0,                           STD_PRINTER "ALLr",                            STD_PRINTER "ALLr",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1800 */  { fnMultiplySI,                 85,                          STD_DOT "f",                                   STD_DOT "f",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1801 */  { fnMultiplySI,                 88,                          STD_DOT "p",                                   STD_DOT "p",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1802 */  { fnMultiplySI,                 91,                          STD_DOT "n",                                   STD_DOT "n",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1803 */  { fnMultiplySI,                 94,                          STD_DOT STD_mu,                                STD_DOT STD_mu,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1804 */  { fnMultiplySI,                 97,                          STD_DOT "m",                                   STD_DOT "m",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1805 */  { fnMultiplySI,                 103,                         STD_DOT "k",                                   STD_DOT "k",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1806 */  { fnMultiplySI,                 106,                         STD_DOT "M",                                   STD_DOT "M",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1807 */  { fnMultiplySI,                 109,                         STD_DOT "G",                                   STD_DOT "G",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1808 */  { fnMultiplySI,                 112,                         STD_DOT "T",                                   STD_DOT "T",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1809 */  { addItemToBuffer,              ITM_QOPPA,                   "",                                            STD_QOPPA,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM GREEK
/* 1810 */  { addItemToBuffer,              ITM_DIGAMMA,                 "",                                            STD_DIGAMMA,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM GREEK
/* 1811 */  { addItemToBuffer,              ITM_SAMPI,                   "",                                            STD_SAMPI,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM GREEK
/* 1812 */  { fnJM,                         7,                           "Y" STD_SPACE_3_PER_EM STD_RIGHT_ARROW STD_SPACE_3_PER_EM STD_DELTA, "Y" STD_SPACE_3_PER_EM STD_RIGHT_ARROW STD_SPACE_3_PER_EM STD_DELTA, (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1813 */  { fnJM,                         6,                           STD_DELTA STD_SPACE_3_PER_EM STD_RIGHT_ARROW STD_SPACE_3_PER_EM "Y", STD_DELTA STD_SPACE_3_PER_EM STD_RIGHT_ARROW STD_SPACE_3_PER_EM "Y", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1814 */  { fnJM,                         9,                           "AtoSYM",                                      STD_RIGHT_ARROW STD_SPACE_3_PER_EM "012",      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1815 */  { fnJM,                         8,                           "SYMtoA",                                      STD_RIGHT_ARROW STD_SPACE_3_PER_EM "abc",      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1816 */  { fnEulersFormula,              NOPARAM,                     STD_EulerE STD_SUP_i STD_SUP_x,                STD_EulerE STD_SUP_i STD_SUP_x,                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1817 */  { fnJM,                         11,                          "STO" STD_SPACE_3_PER_EM "3Z",                 "STO" STD_SPACE_3_PER_EM "3Z",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1818 */  { fnJM,                         12,                          "RCL" STD_SPACE_3_PER_EM "3Z",                 "RCL" STD_SPACE_3_PER_EM "3Z",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1819 */  { fnJM,                         13,                          "STO" STD_SPACE_3_PER_EM "3V",                 "STO" STD_SPACE_3_PER_EM "3V",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1820 */  { fnJM,                         14,                          "RCL" STD_SPACE_3_PER_EM "3V",                 "RCL" STD_SPACE_3_PER_EM "3V",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1821 */  { fnJM,                         15,                          "STO" STD_SPACE_3_PER_EM "3I",                 "STO" STD_SPACE_3_PER_EM "3I",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1822 */  { fnJM,                         16,                          "RCL" STD_SPACE_3_PER_EM "3I",                 "RCL" STD_SPACE_3_PER_EM "3I",                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1823 */  { fnJM,                         17,                          "3V" STD_DIVIDE "3I",                          "V" STD_DIVIDE "I",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1824 */  { fnJM,                         18,                          "3I" STD_CROSS "3Z",                           "I" STD_CROSS "Z",                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1825 */  { fnJM,                         19,                          "3V" STD_DIVIDE "3Z",                          "V" STD_DIVIDE "Z",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1826 */  { fnJM,                         20,                          "X" STD_SPACE_3_PER_EM STD_RIGHT_ARROW STD_SPACE_3_PER_EM "BAL", "X" STD_SPACE_3_PER_EM STD_RIGHT_ARROW STD_SPACE_3_PER_EM "BAL", (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EE
/* 1827 */  { fnJM,                         45,                          "op_A",                                        "[A]",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1828 */  { fn_cnst_op_a,                 NOPARAM,                     "op_a",                                        "a",                                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM Operator a
/* 1829 */  { fn_cnst_op_aa,                NOPARAM,                     "op_a" STD_SUP_2,                              "a" STD_SUP_2,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM Operator a.a
/* 1830 */  { fn_cnst_op_j,                 NOPARAM,                     "op_" STD_op_i,                                STD_op_i,                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM Operator j
/* 1831 */  { fnChangeBaseJM,               2,                           "BIN",                                         "BIN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1832 */  { fnChangeBaseJM,               8,                           "OCT",                                         "OCT",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1833 */  { fnChangeBaseJM,               10,                          "DEC",                                         "DEC",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1834 */  { fnChangeBaseJM,               16,                          "HEX",                                         "HEX",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1835 */  { fnSetWordSize,                8,                           "8-BIT",                                       "8-BIT",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1836 */  { fnSetWordSize,                16,                          "16-BIT",                                      "16-BIT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1837 */  { fnSetWordSize,                32,                          "32-BIT",                                      "32-BIT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1838 */  { fnSetWordSize,                64,                          "64-BIT",                                      "64-BIT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM HEX
/* 1839 */  { fnHrDeg,                      NOPARAM,                     "HOUR",                                        "HOUR",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1840 */  { fnMinute,                     NOPARAM,                     "MIN",                                         "MIN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1841 */  { fnSecond,                     NOPARAM,                     "SEC",                                         "SEC",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1842 */  { fnToTime,                     NOPARAM,                     STD_RIGHT_ARROW "TIME",                        STD_RIGHT_ARROW "TIME",                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1843 */  { fnTimeTo,                     NOPARAM,                     "TIME" STD_RIGHT_ARROW,                        "TIME" STD_RIGHT_ARROW,                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1844 */  { SetSetting,                   JC_FRC,                      "FRCSRN",                                      "FRCSRN",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//dr
/* 1845 */  { addItemToBuffer,              ITM_qoppa,                   "",                                            STD_qoppa,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM GREEK
/* 1846 */  { addItemToBuffer,              ITM_digamma,                 "",                                            STD_digamma,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM GREEK
/* 1847 */  { addItemToBuffer,              ITM_sampi,                   "",                                            STD_sampi,                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM GREEK
/* 1848 */  { fnKeyCC,                      KEY_COMPLEX,                 "COMPLEX",                                     "COMPLEX",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM Change CC to COMPLEX
/* 1849 */  { fnToPolar2,                   NOPARAM,                     STD_RIGHT_ARROW "POLAR",                       STD_RIGHT_ARROW "P",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM TEXT & point to function to add POLAR/RECT
/* 1850 */  { fnToRect2,                    NOPARAM,                     STD_RIGHT_ARROW "RECT",                        STD_RIGHT_ARROW "R",                           (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//SWAPPED ARROW DIRECTION & JM TEXT & point to function to add POLAR/RECT
/* 1851 */  { fneRPN,                       1,                           "eRPN",                                        "eRPN",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1852 */  { fneRPN,                       0,                           "RPN",                                         "RPN",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1853 */  { SetSetting,                   JC_ERPN,                     "eRPN",                                        "eRPN",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM eRPN
/* 1854 */  { SetSetting,                   JC_HOME_TRIPLE,              "HOME.3",                                      "HOME.3",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM HOME.3
/* 1855 */  { SetSetting,                   JC_SHFT_4s,                  "SH.4s",                                       "SH.4s",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM SHIFT CANCEL
/* 1856 */  { SetSetting,                   JC_BCR,                      "CPXRES",                                      "CPXRES",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//dr
/* 1857 */  { SetSetting,                   JC_BLZ,                      "LEAD.0",                                      "LEAD.0",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//dr
/* 1858 */  { SetSetting,                   JC_UC,                       "CAPS",                                        "CAPS",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM CASE
/* 1859 */  { SetSetting,                   JC_BASE_HOME,                "HOME",                                        "HOME",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM eRPN
/* 1860 */  { itemToBeCoded,                NOPARAM,                     "Misc:",                                       "Misc:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1861 */  { SetSetting,                   JC_MYM_TRIPLE,               "MyM.3",                                       "MyM.3",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM MYM.3
/* 1862 */  { fnDateTimeToJulian,           NOPARAM,                     "DT" STD_RIGHT_ARROW "J",                      "DT" STD_RIGHT_ARROW "J",                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1863 */  { fnJulianToDateTime,           NOPARAM,                     "J" STD_RIGHT_ARROW "DT",                      "J" STD_RIGHT_ARROW "DT",                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1864 */  { fnDisplayFormatCycle,         NOPARAM,                     "FSE",                                         "FSE",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM UNIT
/* 1865 */  { SetSetting,                   JC_LARGELI,                  "LRG_LI",                                      "LRG_LI",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1866 */  { fnDisplayFormatSigFig,        TM_VALUE,                    "SIG",                                         "SIG",                                         (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },//JM SIGFIG
/* 1867 */  { fnDisplayFormatUnit,          TM_VALUE,                    "UNIT",                                        "UNIT",                                        (0 << TAM_MAX_BITS) | DSP_MAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },//JM UNIT
/* 1868 */  { fnRound2,                     NOPARAM,                     "ROUND",                                       "ROUND",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1869 */  { fnRoundi2,                    NOPARAM,                     "ROUNDI",                                      "ROUNDI",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1870 */  { fnDumpMenus,                  NOPARAM,                     "DUMPMNU",                                     "DUMPMNU",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1871 */  { fnJM_2SI,                     NOPARAM,                     STD_RIGHT_ARROW "I",                           STD_RIGHT_ARROW "I",                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM Copy of 1925
/* 1872 */  { fnChangeBaseMNU,              TM_VALUE_CHB,                STD_RIGHT_ARROW "INT",                         "#",                                           (2 << TAM_MAX_BITS) |    16, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 1873 */  { fnDRG,                        NOPARAM,                     "DRG",                                         "DRG",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 1874 */  { fnCla,                        NOPARAM,                     "CLA",                                         "CLA",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_DISABLED  | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 1875 */  { fnCln,                        NOPARAM,                     "CLN",                                         "CLN",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 1876 */  { SetSetting,                   DM_ANY,                      "DENANY",                                      "DENANY",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM DEN
/* 1877 */  { SetSetting,                   DM_FIX,                      "DENFIX",                                      "DENFIX",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM DEN
/* 1878 */  { itemToBeCoded,                NOPARAM,                     "",                                            "UPPER",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM CASE
/* 1879 */  { itemToBeCoded,                NOPARAM,                     "",                                            "lower",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM CASE
/* 1880 */  { fnListXY,                     NOPARAM,                     "LISTXY",                                      "LISTXY",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1881 */  { fnShowJM,                     JC_ERPN,                     "eRPN?",                                       "eRPN?",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOW
/* 1882 */  { fnSysFreeMem,                 NOPARAM,                     "HEAP",                                        "HEAP",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1883 */  { itemToBeCoded,                NOPARAM,                     "",                                            "Inl. Tst",                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//INLINE_TEST
/* 1884 */  { fnSetInlineTest,              JC_ITM_TST,                  "",                                            "Test",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//INLINE_TEST
/* 1885 */  { fnGetInlineTestBsToX,         NOPARAM,                     "Get BS",                                      "Get BS",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//INLINE_TEST
/* 1886 */  { fnSetInlineTestXToBs,         NOPARAM,                     "Set BS",                                      "Set BS",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//INLINE_TEST
/* 1887 */  { fnInDefault,                  ID_DP,                       "i" STD_SPACE_3_PER_EM "REAL",                 "i" STD_SPACE_3_PER_EM "REAL",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM INPUT DEFAULT
/* 1888 */  { SetSetting,                   DM_PROPFR,                   "PROPFR",                                      "PROPFR",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM PROPFR
/* 1889 */  { fnInDefault,                  ID_CPXDP,                    "i" STD_SPACE_3_PER_EM "CPX",                  "i" STD_SPACE_3_PER_EM "CPX",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM INPUT DEFAULT
/* 1890 */  { fnInDefault,                  ID_SI,                       "i" STD_SPACE_3_PER_EM "SI",                   "i" STD_SPACE_3_PER_EM "SI",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM INPUT DEFAULT
/* 1891 */  { fnInDefault,                  ID_LI,                       "i" STD_SPACE_3_PER_EM "LI",                   "i" STD_SPACE_3_PER_EM "LI",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM INPUT DEFAULT
/* 1892 */  { fnMultiplySI,                 115,                         STD_DOT "P",                                   STD_DOT "P",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM PRE UNIT
/* 1893 */  { fnJM,                         48,                          "f/g",                                         "f/g",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Shift replacement
/* 1894 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamCmpAlpha",                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1895 */  { SetSetting,                   PR_HPBASE,                   "BASE" STD_SUB_H STD_SUB_P,                    "BASE" STD_SUB_H STD_SUB_P,                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1896 */  { fnAsnViewer,                  NOPARAM,                     "KEYMAP",                                      "KEYMAP",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//J=V43
/* 1897 */  { fnSigmaAssign,                16384+ITM_TGLFRT,            STD_SIGMA "a" STD_SUP_b "/" STD_SUB_c,         STD_SIGMA "a" STD_SUP_b "/" STD_SUB_c,         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1898 */  { fnSigmaAssign,                16384+ITM_AIM,               STD_SIGMA STD_alpha,                           STD_SIGMA STD_alpha,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1899 */  { fnSigmaAssign,                16384+ITM_CC,                STD_SIGMA "CC",                                STD_SIGMA "CC",                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1900 */  { fnSigmaAssign,                16384+ITM_SHIFTg,            STD_SIGMA "g",                                 STD_SIGMA "g",                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1901 */  { fnSigmaAssign,                16384-MNU_MyMenu,            STD_SIGMA "MyM",                               STD_SIGMA "MyM",                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1902 */  { fnSigmaAssign,                16384+ITM_DRG,               STD_SIGMA "DRG",                               STD_SIGMA "DRG",                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1903 */  { fnSigmaAssign,                16384+ITM_PR,                STD_SIGMA "PRGM",                              STD_SIGMA "PRGM",                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1904 */  { fnSigmaAssign,                16384+ITM_USERMODE,          STD_SIGMA "USER",                              STD_SIGMA "USER",                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1905 */  { fnSigmaAssign,                16384+-MNU_HOME,             STD_SIGMA "HOME",                              STD_SIGMA "HOME",                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1906 */  { fnSigmaAssign,                16384+ITM_SIGMAPLUS,         STD_SIGMA "+",                                 STD_SIGMA "+",                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1907 */  { fnSigmaAssign,                16384+ITM_SNAP,              STD_SIGMA "SNAP",                              STD_SIGMA "SNAP",                              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1908 */  { fnGetSigmaAssignToX,          NOPARAM,                     STD_SIGMA "+ toX",                             STD_SIGMA "+ toX",                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1909 */  { fnTo_ms,                      NOPARAM,                     ".ms",                                         ".ms",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM DMS HMS
/* 1910 */  { fnFrom_ms,                    NOPARAM,                     ".ms" STD_SUP_MINUS STD_SUP_1,                 ".ms" STD_SUP_MINUS STD_SUP_1,                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM DMS HMS
/* 1911 */  { fnInDefault,                  ID_43S,                      "i" STD_SPACE_3_PER_EM "LI/RL",                "i" STD_SPACE_3_PER_EM "LI/RL",                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM INPUT DEFAULT
/* 1912 */  { fnXEQMXXEQ,                   NOPARAM,                     "X.XEQ",                                       "X.XEQ",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1913 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamAlpha",                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1914 */  { fnKeysManagement,             USER_COPY,                   "COPY" STD_RIGHT_ARROW "U",                    "COPY" STD_RIGHT_ARROW "U",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1915 */  { fnKeysManagement,             USER_43S,                    "WP43",                                        "WP43",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//J=V43
/* 1916 */  { fnKeysManagement,             USER_DM42,                   "DM42",                                        "DM42",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//J=V43
/* 1917 */  { SetSetting,                   PR_HPRP,                     "RP" STD_SUB_H STD_SUB_P,                      "RP" STD_SUB_H STD_SUB_P,                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1918 */  { fnJM_GetXToNORMmode,          NOPARAM,                     "X to" STD_SIGMA "+",                          "X to" STD_SIGMA "+",                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM USER NORMAL
/* 1919 */  { itemToBeCoded,                NOPARAM,                     "",                                            "reserve",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//placeholder
/* 1920 */  { itemToBeCoded,                NOPARAM,                     STD_SIGMA "+NRM",                              STD_SIGMA "+NRM",                              (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1921 */  { itemToBeCoded,                NOPARAM,                     "HOME",                                        "HOME",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM HOME
/* 1922 */  { itemToBeCoded,                NOPARAM,                     "ALPHA",                                       "ALPHA",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM ALPHA
/* 1923 */  { itemToBeCoded,                NOPARAM,                     "BASE",                                        "BASE",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM BASE
/* 1924 */  { itemToBeCoded,                NOPARAM,                     "XEQM",                                        "XEQM",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1925 */  { itemToBeCoded,                NOPARAM,                     "ELEC",                                        "ELEC",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },//JM EE
/* 1926 */  { fnT_ARROW,                    ITM_T_UP_ARROW,              "",                                            STD_UP_ARROW,                                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1927 */  { itemToBeCoded,                NOPARAM,                     "KEYS",                                        "KEYS",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1928 */  { fnT_ARROW,                    ITM_T_DOWN_ARROW,            "",                                            STD_DOWN_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1929 */  { fnT_ARROW,                    ITM_T_HOME,                  "",                                            "HOME",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1930 */  { fnT_ARROW,                    ITM_T_END,                   "",                                            "END",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1931 */  { fnJM,                         46,                          "zyx" STD_RIGHT_ARROW "M",                     "zyx" STD_RIGHT_ARROW "M",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1932 */  { itemToBeCoded,                NOPARAM,                     STD_alpha ".PARSE",                            STD_alpha ".PARSE",                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1933 */  { itemToBeCoded,                NOPARAM,                     "XXEQ",                                        "XXEQ",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1934 */  { fnRange,                      TM_VALUE,                    "RNG",                                         "RNG",                                         (0 << TAM_MAX_BITS) |  6145, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_16    },
/* 1935 */  { flagBrowser,                  0,                           "FLGS",                                        "FLGS",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Changed STATUS
/* 1936 */  { SetSetting,                   CU_I,                        "CPX" STD_op_i,                                "CPX" STD_op_i,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1937 */  { SetSetting,                   CU_J,                        "CPX" STD_op_j,                                "CPX" STD_op_j,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1938 */  { SetSetting,                   SS_4,                        "SSIZE4",                                      "SSIZE4",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1939 */  { SetSetting,                   SS_8,                        "SSIZE8",                                      "SSIZE8",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1940 */  { SetSetting,                   JC_BSR,                      "SPCRES",                                      "SPCRES",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1941 */  { fnCFGsettings,                NOPARAM,                     "CFG",                                         "CFG",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Replacements
/* 1942 */  { SetSetting,                   TF_H12,                      "CLK12",                                       "CLK12",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Replacements
/* 1943 */  { SetSetting,                   TF_H24,                      "CLK24",                                       "CLK24",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Replacements
/* 1944 */  { SetSetting,                   PS_CROSS,                    "MULT" STD_CROSS,                              "MULT" STD_CROSS,                              (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1945 */  { SetSetting,                   PS_DOT,                      "MULT" STD_DOT,                                "MULT" STD_DOT,                                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1946 */  { SetSetting,                   CM_POLAR,                    "POLAR",                                       "POLAR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Replacements
/* 1947 */  { fnJM,                         48,                          "",                                            "",                                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//placeholder for ITM_TST
/* 1948 */  { SetSetting,                   PRTACT,                      "PRNTR",                                       "PRNTR",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM Replacements
/* 1949 */  { SetSetting,                   CM_RECTANGULAR,              "RECT",                                        "RECT",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Replacements
/* 1950 */  { SetSetting,                   DO_SCI,                      "SCIOVR",                                      "SCIOVR",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Replacements
/* 1951 */  { SetSetting,                   DO_ENG,                      "ENGOVR",                                      "ENGOVR",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Replacements
/* 1952 */  { fnT_ARROW,                    ITM_T_LEFT_ARROW,            "",                                            STD_LEFT_ARROW,                                (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1953 */  { fnT_ARROW,                    ITM_T_RIGHT_ARROW,           "",                                            STD_RIGHT_ARROW,                               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1954 */  { fnT_ARROW,                    ITM_T_LLEFT_ARROW,           "",                                            STD_LEFT_DASHARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1955 */  { fnT_ARROW,                    ITM_T_RRIGHT_ARROW,          "",                                            STD_RIGHT_DASHARROW,                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1956 */  { fnXEQNEW,                     NOPARAM,                     "X.NEW",                                       "X.NEW",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1957 */  { fnXSWAP,                      NOPARAM,                     "X.SWAP",                                      "X.SWAP",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1958 */  { addItemToBuffer,              NOPARAM,                     "OCT",                                         "O",                                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1959 */  { fnKeysManagement,             USER_C47,                    "C47",                                         "C47",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1960 */  { fnKeysManagement,             USER_V47,                    "V47",                                         "V47",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1961 */  { fnKeysManagement,             USER_D47,                    "D47",                                         "D47",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1962 */  { fnKeysManagement,             USER_N47,                    "N47",                                         "N47",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1963 */  { fnKeysManagement,             USER_E47,                    "E47",                                         "E47",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1964 */  { itemToBeCoded,                NOPARAM,                     "1964",                                        "1964",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1965 */  { fnXEQMENU,                    1,                           "XEQM01",                                      "XEQM01",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1966 */  { fnXEQMENU,                    2,                           "XEQM02",                                      "XEQM02",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1967 */  { fnXEQMENU,                    3,                           "XEQM03",                                      "XEQM03",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1968 */  { fnXEQMENU,                    4,                           "XEQM04",                                      "XEQM04",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1969 */  { fnXEQMENU,                    5,                           "XEQM05",                                      "XEQM05",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1970 */  { fnXEQMENU,                    6,                           "XEQM06",                                      "XEQM06",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1971 */  { fnXEQMENU,                    7,                           "XEQM07",                                      "XEQM07",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1972 */  { fnXEQMENU,                    8,                           "XEQM08",                                      "XEQM08",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1973 */  { fnXEQMENU,                    9,                           "XEQM09",                                      "XEQM09",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1974 */  { fnXEQMENU,                    10,                          "XEQM10",                                      "XEQM10",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1975 */  { fnXEQMENU,                    11,                          "XEQM11",                                      "XEQM11",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1976 */  { fnXEQMENU,                    12,                          "XEQM12",                                      "XEQM12",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1977 */  { fnXEQMENU,                    13,                          "XEQM13",                                      "XEQM13",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1978 */  { fnXEQMENU,                    14,                          "XEQM14",                                      "XEQM14",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1979 */  { fnXEQMENU,                    15,                          "XEQM15",                                      "XEQM15",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1980 */  { fnXEQMENU,                    16,                          "XEQM16",                                      "XEQM16",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1981 */  { fnXEQMENU,                    17,                          "XEQM17",                                      "XEQM17",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1982 */  { fnXEQMENU,                    18,                          "XEQM18",                                      "XEQM18",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM EXEC
/* 1983 */  { fnXEQMSAVE,                   TM_VALUE,                    "X.SAVE",                                      "X.SAVE",                                      (1 << TAM_MAX_BITS) |    18, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1984 */  { fnXEQMLOAD,                   TM_VALUE,                    "X.LOAD",                                      "X.LOAD",                                      (1 << TAM_MAX_BITS) |    18, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 1985 */  { fnSetBCD,                     JC_BCD,                      "BCD",                                         "BCD",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 1986 */  { fnSetBCD,                     BCD9c ,                      "9CMPL",                                       "9CMPL",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1987 */  { fnSetBCD,                     BCD10c,                      "10CMPL",                                      "10CMPL",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1988 */  { fnSetBCD,                     BCDu,                        "BCDUNS",                                      "BCDUNS",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 1989 */  { fnByteShortcutsS,             6,                           "S06",                                         "S06",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1990 */  { fnByteShortcutsS,             8,                           "S08",                                         "S08",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1991 */  { fnByteShortcutsS,             16,                          "S16",                                         "S16",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1992 */  { fnByteShortcutsS,             32,                          "S32",                                         "S32",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1993 */  { fnByteShortcutsS,             64,                          "S64",                                         "S64",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1994 */  { fnByteShortcutsU,             6,                           "U06",                                         "U06",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1995 */  { fnByteShortcutsU,             8,                           "U08",                                         "U08",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1996 */  { fnByteShortcutsU,             16,                          "U16",                                         "U16",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1997 */  { fnByteShortcutsU,             32,                          "U32",                                         "U32",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1998 */  { fnByteShortcutsU,             64,                          "U64",                                         "U64",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 1999 */  { fnByte,                       1,                           "SL1",                                         "SL1",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 2000 */  { fnByte,                       2,                           "SR1",                                         "SR1",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 2001 */  { fnByte,                       3,                           "RL1",                                         "RL1",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 2002 */  { fnByte,                       4,                           "RR1",                                         "RR1",                                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 2003 */  { fnByte,                       5,                           "W.SWP",                                       "W.SWP",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 2004 */  { fnByte,                       6,                           "B.SWP",                                       "B.SWP",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//JM SHOI
/* 2005 */  { fnClrMod,                     NOPARAM,                     "CLRMOD",                                      "CLRMOD",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_NONE         },//clear HEX mode
/* 2006 */  { fnShoiXRepeats,               TM_VALUE,                    "DISP_SI",                                     "DISP_SI",                                     (0 << TAM_MAX_BITS) |     3, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//JM SHOI
/* 2007 */  { fnScale,                      NOPARAM,                     "X:Y=1",                                       "X:Y=1",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM GRAPHING
/* 2008 */  { fnSetBCD,                     JC_TOPHEX,                   "KEY" STD_SUB_A STD_SUB_MINUS STD_SUB_F,       "KEY" STD_SUB_A STD_SUB_MINUS STD_SUB_F,       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2009 */  { fnPline,                      NOPARAM,                     "LINE",                                        "LINE",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2010 */  { fnPcros,                      NOPARAM,                     "CROSS",                                       "CROSS",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//GRAPH
/* 2011 */  { fnPbox,                       NOPARAM,                     "BOX",                                         "BOX",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//GRAPH
/* 2012 */  { fnPvect,                      NOPARAM,                     "VECT",                                        "VECT",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM VECTOR MODE
/* 2013 */  { fnPNvect,                     NOPARAM,                     "N.VECT",                                      "N.VECT",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM VECTOR MODE
/* 2014 */  { fnPx,                         NOPARAM,                     "Y.AXIS",                                      "Y.AXIS",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2015 */  { fnPy,                         NOPARAM,                     "X.AXIS",                                      "X.AXIS",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2016 */  { fnOldItemError,               NOPARAM,                     ">DMX<",                                       ">DMX<",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//Old item
/* 2017 */  { fnOldItemError,               NOPARAM,                     ">SDIGS<",                                     ">SDIGS<",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//Old item
/* 2018 */  { itemToBeCoded,                NOPARAM,                     "2018",                                        "2018",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2019 */  { fnGetRoundingMode,            NOPARAM,                     "RMODE?",                                      "RMODE?",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2020 */  { fnSetSI_All,                  JC_SI_All,                   "PFX.All",                                     "PFX.All",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2021 */  { fnKeysManagement,             USER_ARESET,                 "A.RESET",                                     "A.RESET",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2022 */  { fnKeysManagement,             USER_MRESET,                 "M.RESET",                                     "M.RESET",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2023 */  { fnKeysManagement,             USER_KRESET,                 "K.RESET",                                     "K.RESET",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2024 */  { fnPintg,                      NOPARAM,                     STD_SIGMA STD_y_BAR STD_DELTA "x",             STD_SIGMA STD_y_BAR STD_DELTA "x",             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2025 */  { fnPdiff,                      NOPARAM,                     STD_DELTA "y/" STD_DELTA "x",                  STD_DELTA "y/" STD_DELTA "x",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2026 */  { fnPrms,                       NOPARAM,                     "RMS",                                         "RMS",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2027 */  { fnPshade,                     NOPARAM,                     STD_INTEGRAL "AREA",                           STD_INTEGRAL "AREA",                           (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2028 */  { itemToBeCoded,                NOPARAM,                     "PLOTMNU",                                     "PLOTMNU",                                     (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2029 */  { SetSetting,                   JC_NL,                       "NUM",                                         "NUM",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2030 */  { itemToBeCoded,                NOPARAM,                     "",                                            "NLock",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2031 */  { itemToBeCoded,                NOPARAM,                     "",                                            "Nulock",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2032 */  { addItemToBuffer,              ITM_EEXCHR,                  "",                                            STD_SUB_E_OUTLINE,                             (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2033 */  { fnClGrf,                      NOPARAM,                     "CLGRF",                                       "CLGRF",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 2034 */  { fnPzoom,                      1,                           "ZOOMx",                                       "ZOOMx",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2035 */  { fnPzoom,                      2,                           "ZOOMy",                                       "ZOOMy",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },//GRAPH
/* 2036 */  { itemToBeCoded,                NOPARAM,                     "TRG",                                         "TRG",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2037 */  { itemToBeCoded,                NOPARAM,                     "SETUP",                                       "SETUP",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2038 */  { fnSafeReset,                  NOPARAM,                     "S.RESET",                                     "S.RESET",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_DISABLED     },
/* 2039 */  { itemToBeCoded,                NOPARAM,                     "2039",                                        "2039",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2040 */  { graph_stat,                   NOPARAM,                     "PLSTAT",                                      "PLSTAT",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2041 */  { fnJM,                         47,                          "M" STD_RIGHT_ARROW "zyx",                     "M" STD_RIGHT_ARROW "zyx",                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2042 */  { fnPlotReset,                  NOPARAM,                     "PLTRST",                                      "PLTRST",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2043 */  { runDMCPmenu,                  CONFIRMED,                   "DMCP",                                        "DMCP",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2044 */  { activateUSBdisk,              CONFIRMED,                   "ActUSB",                                      "ActUSB",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2045 */  { itemToBeCoded,                NOPARAM,                     "Speed:",                                      "Speed:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2046 */  { itemToBeCoded,                NOPARAM,                     "Angle:",                                      "Angle:",                                      (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2047 */  { SetSetting,                   ITM_CPXRES1,                 "CPXRES1",                                     "CPXRES1",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2048 */  { SetSetting,                   ITM_SPCRES1,                 "SPCRES1",                                     "SPCRES1",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2049 */  { SetSetting,                   ITM_CPXRES0,                 "CPXRES0",                                     "CPXRES0",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2050 */  { SetSetting,                   ITM_SPCRES0,                 "SPCRES0",                                     "SPCRES0",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2051 */  { SetSetting,                   ITM_PRTACT1,                 "PRON",                                        "PRON",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2052 */  { SetSetting,                   ITM_PRTACT0,                 "PROFF",                                       "PROFF",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2053 */  { itemToBeCoded,                NOPARAM,                     "2053",                                        "2053",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2054 */  { itemToBeCoded,                NOPARAM,                     "2054",                                        "2054",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2055 */  { itemToBeCoded,                NOPARAM,                     "2055",                                        "2055",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2056 */  { SetSetting,                   JC_IRFRAC,                   "IRFRAC",                                      "IRFRAC",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2057 */  { setFGLSettings,               RB_FGLNOFF,                  "fg.OFF",                                      "fg.OFF",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2058 */  { setFGLSettings,               RB_FGLNLIM,                  "fg.LIM",                                      "fg.LIM",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2059 */  { setFGLSettings,               RB_FGLNFUL,                  "fg.FUL",                                      "fg.FUL",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2060 */  { fnLongPressSwitches,          RB_M124,                     "M.124",                                       "M.124",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2061 */  { fnLongPressSwitches,          RB_F1234,                    "F.1234",                                      "F.1234",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2062 */  { fnLongPressSwitches,          RB_M1234,                    "M.1234",                                      "M.1234",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2063 */  { fnLongPressSwitches,          RB_F14,                      "F.14",                                        "F.14",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2064 */  { fnLongPressSwitches,          RB_M14,                      "M.14",                                        "M.14",                                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2065 */  { fnLongPressSwitches,          RB_F124,                     "F.124",                                       "F.124",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2066 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamLTxt",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2067 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamVTxt",                                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2068 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamNoReg",                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2069 */  { addItemToBuffer,              ITM_LG_SIGN,                 "LOG",                                         "LOG",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2070 */  { addItemToBuffer,              ITM_LN_SIGN,                 "LN",                                          "LN",                                          (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2071 */  { addItemToBuffer,              ITM_SIN_SIGN,                "SIN",                                         "SIN",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2072 */  { addItemToBuffer,              ITM_COS_SIGN,                "COS",                                         "COS",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2073 */  { addItemToBuffer,              ITM_TAN_SIGN,                "TAN",                                         "TAN",                                         (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2074 */  { fnMedianXY,                   NOPARAM,                     "x" STD_SUB_M STD_SUB_E STD_SUB_D STD_SUB_N,   "x" STD_SUB_M STD_SUB_E STD_SUB_D STD_SUB_N,   (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2075 */  { fnLowerQuartileXY,            NOPARAM,                     "x" STD_SUB_Q STD_SUB_1,                       "x" STD_SUB_Q STD_SUB_1,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2076 */  { fnUpperQuartileXY,            NOPARAM,                     "x" STD_SUB_Q STD_SUB_3,                       "x" STD_SUB_Q STD_SUB_3,                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2077 */  { fnMADXY,                      NOPARAM,                     "x" STD_SUB_M STD_SUB_A STD_SUB_D,             "x" STD_SUB_M STD_SUB_A STD_SUB_D,             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2078 */  { fnIQRXY,                      NOPARAM,                     "x" STD_SUB_I STD_SUB_Q STD_SUB_R,             "x" STD_SUB_I STD_SUB_Q STD_SUB_R,             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2079 */  { fnRangeXY,                    NOPARAM,                     "x" RANGE_,                                    "x" RANGE_,                                    (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2080 */  { itemToBeCoded,                NOPARAM,                     "REGR",                                        "REGR",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2081 */  { itemToBeCoded,                NOPARAM,                     "MODEL",                                       "MODEL",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2082 */  { fnPercentileXY,               NOPARAM,                     "x%" STD_SUB_I STD_SUB_L STD_SUB_E,            "x%" STD_SUB_I STD_SUB_L STD_SUB_E,            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2083 */  { fnLINPOL,                     NOPARAM,                     "LINPOL",                                      "LINPOL",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2084 */  { fnCvtNmiKm,                   multiply,                    "knot" STD_RIGHT_ARROW "km/h",                 "knot" STD_RIGHT_ARROW "km/h",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2085 */  { fnCvtNmiKm,                   divide,                      "km/h" STD_RIGHT_ARROW "knot",                 "km/h" STD_RIGHT_ARROW "knot",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2086 */  { fnCvtKmphmps,                 multiply,                    "km/h" STD_RIGHT_ARROW "m/s",                  "km/h" STD_RIGHT_ARROW "m/s",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2087 */  { fnCvtKmphmps,                 divide,                      "m/s" STD_RIGHT_ARROW "km/h",                  "m/s" STD_RIGHT_ARROW "km/h",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2088 */  { fnCvtRpmDegps,                multiply,                    "RPM" STD_RIGHT_ARROW "deg/s",                 "RPM" STD_RIGHT_ARROW "deg/s",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2089 */  { fnCvtRpmDegps,                divide,                      "deg/s" STD_RIGHT_ARROW "RPM",                 "deg/s" STD_RIGHT_ARROW "RPM",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2090 */  { fnCvtMiKm,                    multiply,                    "mph" STD_RIGHT_ARROW "km/h",                  "mph" STD_RIGHT_ARROW "km/h",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2091 */  { fnCvtMiKm,                    divide,                      "km/h" STD_RIGHT_ARROW "mph",                  "km/h" STD_RIGHT_ARROW "mph",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2092 */  { fnCvtMphmps,                  multiply,                    "mph" STD_RIGHT_ARROW "m/s",                   "mph" STD_RIGHT_ARROW "m/s",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2093 */  { fnCvtMphmps,                  divide,                      "m/s" STD_RIGHT_ARROW "mph",                   "m/s" STD_RIGHT_ARROW "mph",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2094 */  { fnCvtRpmRadps,                multiply,                    "RPM" STD_RIGHT_ARROW "rad/s",                 "RPM" STD_RIGHT_ARROW "rad/s",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2095 */  { fnCvtRpmRadps,                divide,                      "rad/s" STD_RIGHT_ARROW "RPM",                 "rad/s" STD_RIGHT_ARROW "RPM",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2096 */  { fnCvtDegRad,                  multiply,                    "deg" STD_RIGHT_ARROW "rad",                   "deg" STD_RIGHT_ARROW "rad",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2097 */  { fnCvtDegRad,                  divide,                      "rad" STD_RIGHT_ARROW "deg",                   "rad" STD_RIGHT_ARROW "deg",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2098 */  { fnCvtDegGrad,                 multiply,                    "deg" STD_RIGHT_ARROW "grad",                  "deg" STD_RIGHT_ARROW "grad",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2099 */  { fnCvtDegGrad,                 divide,                      "grad" STD_RIGHT_ARROW "deg",                  "grad" STD_RIGHT_ARROW "deg",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2100 */  { fnCvtGradRad,                 multiply,                    "grad" STD_RIGHT_ARROW "rad",                  "grad" STD_RIGHT_ARROW "rad",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2101 */  { fnCvtGradRad,                 divide,                      "rad" STD_RIGHT_ARROW "grad",                  "rad" STD_RIGHT_ARROW "grad",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2102 */  { itemToBeCoded,                NOPARAM,                     "TRG",                                         "TRG",                                         (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2103 */  { itemToBeCoded,                NOPARAM,                     "TRG" STD_ELLIPSIS,                            "TRG" STD_ELLIPSIS,                            (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2104 */  { itemToBeCoded,                NOPARAM,                     "2104",                                        "2104",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2105 */  { itemToBeCoded,                NOPARAM,                     "2105",                                        "2105",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2106 */  { itemToBeCoded,                NOPARAM,                     "2106",                                        "2106",                                        (0 << TAM_MAX_BITS) |     0, CAT_FREE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2107 */  { itemToBeCoded,                NOPARAM,                     "PLOT",                                        "PLOT",                                        (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },//JM Change U> arrow to CONV. Changed again to UNIT
/* 2108 */  { itemToBeCoded,                NOPARAM,                     "",                                            "TamNoRegInd",                                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2109 */  { fnSave,                       SM_STATE_SAVE,               "SAVEST",                                      "SAVEST",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2110 */  { fnLoad,                       LM_STATE_LOAD,               "LOADST",                                      "LOADST",                                      (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_CANCEL    | EIM_DISABLED | PTP_NONE         },
/* 2111 */  { fnSetGapChar,                 ITM_DOT,                     "IDOT" STD_DOT,                                "DOT" STD_DOT,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2112 */  { fnSetGapChar,                 ITM_WDOT,                    "IWDOT" STD_SPACE_4_PER_EM STD_WDOT,           "WDOT" STD_SPACE_4_PER_EM STD_WDOT,            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2113 */  { fnSetGapChar,                 ITM_PERIOD,                  "IPER.",                                       "PER.",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2114 */  { fnSetGapChar,                 ITM_WPERIOD,                 "IWPER" STD_SPACE_4_PER_EM STD_WPERIOD,        "WPER" STD_SPACE_4_PER_EM STD_WPERIOD,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2115 */  { fnSetGapChar,                 ITM_COMMA,                   "ICOM,",                                       "COM,",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2116 */  { fnSetGapChar,                 ITM_WCOMMA,                  "IWCOM" STD_SPACE_4_PER_EM STD_WCOMMA,         "WCOM" STD_SPACE_4_PER_EM STD_WCOMMA,          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2117 */  { fnSetGapChar,                 ITM_QUOTE,                   "IWTICK" STD_SPACE_4_PER_EM "'",               "WTICK" STD_SPACE_4_PER_EM "'",                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2118 */  { fnSetGapChar,                 ITM_NQUOTE,                  "ITICK" STD_NQUOTE,                            "TICK" STD_NQUOTE,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2119 */  { fnSetGapChar,                 ITM_SPACE_PUNCTUATION,       "ISPC" STD_OPEN_BOX,                           "SPC" STD_OPEN_BOX,                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2120 */  { fnSetGapChar,                 ITM_SPACE_4_PER_EM,          "INSPC" STD_INV_BRIDGE,                        "NSPC" STD_INV_BRIDGE,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2121 */  { fnSetGapChar,                 ITM_SPACE_EM,                "IWSPC" STD_INV_BRIDGE STD_INV_BRIDGE,         "WSPC" STD_INV_BRIDGE STD_INV_BRIDGE,          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2122 */  { fnSetGapChar,                 ITM_UNDERSCORE,              "IUNDR" STD_UNDERSCORE,                        "UNDR" STD_UNDERSCORE,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2123 */  { fnSetGapChar,                 ITM_NULL,                    "INONE",                                       "NONE",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2124 */  { fnSetGapChar,                 32768+ITM_DOT,               "FDOT" STD_DOT,                                "DOT" STD_DOT,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2125 */  { fnSetGapChar,                 32768+ITM_WDOT,              "FWDOT" STD_SPACE_4_PER_EM STD_WDOT,           "WDOT" STD_SPACE_4_PER_EM STD_WDOT,            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2126 */  { fnSetGapChar,                 32768+ITM_PERIOD,            "FPER.",                                       "PER.",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2127 */  { fnSetGapChar,                 32768+ITM_WPERIOD,           "FWPER" STD_SPACE_4_PER_EM STD_WPERIOD,        "WPER" STD_SPACE_4_PER_EM STD_WPERIOD,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2128 */  { fnSetGapChar,                 32768+ITM_COMMA,             "FCOM,",                                       "COM,",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2129 */  { fnSetGapChar,                 32768+ITM_WCOMMA,            "FWCOM" STD_SPACE_4_PER_EM STD_WCOMMA,         "WCOM" STD_SPACE_4_PER_EM STD_WCOMMA,          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2130 */  { fnSetGapChar,                 32768+ITM_QUOTE,             "FWTICK" STD_SPACE_4_PER_EM "'",               "WTICK" STD_SPACE_4_PER_EM "'",                (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2131 */  { fnSetGapChar,                 32768+ITM_NQUOTE,            "FTICK" STD_NQUOTE,                            "TICK" STD_NQUOTE,                             (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2132 */  { fnSetGapChar,                 32768+ITM_SPACE_PUNCTUATION, "FSPC" STD_OPEN_BOX,                           "SPC" STD_OPEN_BOX,                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2133 */  { fnSetGapChar,                 32768+ITM_SPACE_4_PER_EM,    "FNSPC" STD_INV_BRIDGE,                        "NSPC" STD_INV_BRIDGE,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2134 */  { fnSetGapChar,                 32768+ITM_SPACE_EM,          "FWSPC" STD_INV_BRIDGE STD_INV_BRIDGE,         "WSPC" STD_INV_BRIDGE STD_INV_BRIDGE,          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2135 */  { fnSetGapChar,                 32768+ITM_UNDERSCORE,        "FUNDR" STD_UNDERSCORE,                        "UNDR" STD_UNDERSCORE,                         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2136 */  { fnSetGapChar,                 32768+ITM_NULL,              "FNONE",                                       "NONE",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2137 */  { fnSetGapChar,                 49152+ITM_DOT,               "RDOT" STD_DOT,                                "DOT" STD_DOT,                                 (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2138 */  { fnSetGapChar,                 49152+ITM_WDOT,              "RWDOT" STD_SPACE_4_PER_EM STD_WDOT,           "WDOT" STD_SPACE_4_PER_EM STD_WDOT,            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2139 */  { fnSetGapChar,                 49152+ITM_PERIOD,            "RPER.",                                       "PER.",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2140 */  { fnSetGapChar,                 49152+ITM_WPERIOD,           "RWPER" STD_SPACE_4_PER_EM STD_WPERIOD,        "WPER" STD_SPACE_4_PER_EM STD_WPERIOD,         (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2141 */  { fnSetGapChar,                 49152+ITM_COMMA,             "RCOM,",                                       "COM,",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2142 */  { fnSetGapChar,                 49152+ITM_WCOMMA,            "RWCOM" STD_SPACE_4_PER_EM STD_WCOMMA,         "WCOM" STD_SPACE_4_PER_EM STD_WCOMMA,          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2143 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_WDOT,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2144 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_WPERIOD,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2145 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_WCOMMA ,                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2146 */  { itemToBeCoded,                NOPARAM,                     "",                                            STD_NQUOTE,                                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2147 */  { fnSetFirstGregorianDay,       ITM_JUL_GREG_1582,           "JG.1582",                                     "JG.1582",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2148 */  { fnSetFirstGregorianDay,       ITM_JUL_GREG_1752,           "JG.1752",                                     "JG.1752",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2149 */  { fnSetFirstGregorianDay,       ITM_JUL_GREG_1873,           "JG.1873",                                     "JG.1873",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2150 */  { fnSetFirstGregorianDay,       ITM_JUL_GREG_1949,           "JG.1949",                                     "JG.1949",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2151 */  { itemToBeCoded,                NOPARAM,                     "IPART",                                       "IPART",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2152 */  { itemToBeCoded,                NOPARAM,                     "RADIX",                                       "RADIX",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2153 */  { itemToBeCoded,                NOPARAM,                     "FPART",                                       "FPART",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2154 */  { itemToBeCoded,                NOPARAM,                     "set>TXT",                                     "set>TXT",                                     (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2155 */  { fnSettingsDispFormatGrpL,     TM_VALUE,                    "IPGRP",                                       "IPGRP",                                       (2 << TAM_MAX_BITS) |     9, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2156 */  { fnSettingsDispFormatGrp1Lo,   TM_VALUE,                    "IPGRP1x",                                     "IPGRP1x",                                     (0 << TAM_MAX_BITS) |     9, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2157 */  { fnSettingsDispFormatGrp1L,    TM_VALUE,                    "IPGRP1",                                      "IPGRP1",                                      (0 << TAM_MAX_BITS) |     9, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2158 */  { fnSettingsDispFormatGrpR,     TM_VALUE,                    "FPGRP",                                       "FPGRP",                                       (2 << TAM_MAX_BITS) |     9, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2159 */  { fnMenuGapL,                   MNU_GAP_L,                   "IPART",                                       "IPART",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2160 */  { fnMenuGapRX,                  MNU_GAP_RX,                  "RADIX",                                       "RADIX",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2161 */  { fnMenuGapR,                   MNU_GAP_R,                   "FPART",                                       "FPART",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2162 */  { fnKeysManagement,             USER_MENG,                   "M.ENG",                                       "M.ENG",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2163 */  { fnKeysManagement,             USER_MFIN,                   "M.FIN",                                       "M.FIN",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2164 */  { fnKeysManagement,             USER_MCPX,                   "M.CPX",                                       "M.CPX",                                       (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2165 */  { addItemToBuffer,              ITM_op_j_SIGN,               "op_" STD_op_i,                                STD_op_i,                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2166 */  { addItemToBuffer,              ITM_poly_SIGN,               "cubic",                                       "cubic",                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2167 */  { fnCvtNmiMi,                   multiply,                    "nmi" STD_RIGHT_ARROW "mi.",                   "nmi" STD_RIGHT_ARROW "mi.",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2168 */  { fnCvtNmiMi,                   divide,                      "mi." STD_RIGHT_ARROW "nmi",                   "mi." STD_RIGHT_ARROW "nmi",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2169 */  { fnCvtFurtom,                  multiply,                    "fur" STD_RIGHT_ARROW "m",                     "fur" STD_RIGHT_ARROW "m",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2170 */  { fnCvtFurtom,                  divide,                      "m" STD_RIGHT_ARROW "fur",                     "m" STD_RIGHT_ARROW "fur",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2171 */  { fnCvtFtntos,                  multiply,                    "ftn" STD_RIGHT_ARROW "s",                     "ftn" STD_RIGHT_ARROW "s",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2172 */  { fnCvtFtntos,                  divide,                      "s" STD_RIGHT_ARROW "ftn",                     "s" STD_RIGHT_ARROW "ftn",                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2173 */  { fnCvtFpftomps,                multiply,                    "fur/ftn" STD_RIGHT_ARROW "m/s",               "fur/ftn" STD_RIGHT_ARROW "m/s",               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2174 */  { fnCvtFpftomps,                divide,                      "m/s" STD_RIGHT_ARROW "fur/ftn",               "m/s" STD_RIGHT_ARROW "fur/ftn",               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2175 */  { fnCvtBrdstom,                 multiply,                    "brds" STD_RIGHT_ARROW "m",                    "brds" STD_RIGHT_ARROW "m",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2176 */  { fnCvtBrdstom,                 divide,                      "m" STD_RIGHT_ARROW "brds",                    "m" STD_RIGHT_ARROW "brds",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2177 */  { fnCvtFirtokg,                 multiply,                    "fir" STD_RIGHT_ARROW "kg",                    "fir" STD_RIGHT_ARROW "kg",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2178 */  { fnCvtFirtokg,                 divide,                      "kg" STD_RIGHT_ARROW "fir",                    "kg" STD_RIGHT_ARROW "fir",                    (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2179 */  { fnCvtFpftokph,                multiply,                    "fur/ftn" STD_RIGHT_ARROW "km/h",              "fur/ftn" STD_RIGHT_ARROW "km/h",              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2180 */  { fnCvtFpftokph,                divide,                      "km/h" STD_RIGHT_ARROW "fur/ftn",              "km/h" STD_RIGHT_ARROW "fur/ftn",              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2181 */  { fnCvtBrdstoin,                multiply,                    "brds" STD_RIGHT_ARROW "in.",                  "brds" STD_RIGHT_ARROW "in.",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2182 */  { fnCvtBrdstoin,                divide,                      "in." STD_RIGHT_ARROW "brds",                  "in." STD_RIGHT_ARROW "brds",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2183 */  { fnCvtFirtolb,                 multiply,                    "fir" STD_RIGHT_ARROW "lb.",                   "fir" STD_RIGHT_ARROW "lb.",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2184 */  { fnCvtFirtolb,                 divide,                      "lb." STD_RIGHT_ARROW "fir",                   "lb." STD_RIGHT_ARROW "fir",                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2185 */  { fnCvtFpftomph,                multiply,                    "fur/ftn" STD_RIGHT_ARROW "mph",               "fur/ftn" STD_RIGHT_ARROW "mph",               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2186 */  { fnCvtFpftomph,                divide,                      "mph" STD_RIGHT_ARROW "fur/ftn",               "mph" STD_RIGHT_ARROW "fur/ftn",               (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2187 */  { fnCvtFpstokph,                multiply,                    "ft/s" STD_RIGHT_ARROW "km/h",                 "ft/s" STD_RIGHT_ARROW "km/h",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2188 */  { fnCvtFpstokph,                divide,                      "km/h" STD_RIGHT_ARROW "ft/s",                 "km/h" STD_RIGHT_ARROW "ft/s",                 (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2189 */  { fnCvtFpstomps,                multiply,                    "ft/s" STD_RIGHT_ARROW "m/s",                  "ft/s" STD_RIGHT_ARROW "m/s",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2190 */  { fnCvtFpstomps,                divide,                      "m/s" STD_RIGHT_ARROW "ft/s",                  "m/s" STD_RIGHT_ARROW "ft/s",                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2191 */  { SetSetting,                   JC_SS,                       SUPSUB_,                                       SUPSUB_,                                       (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2192 */  { itemToBeCoded,                NOPARAM,                     "",                                            "SCRNRM",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2193 */  { itemToBeCoded,                NOPARAM,                     "",                                            "SCRSUP",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2194 */  { itemToBeCoded,                NOPARAM,                     "",                                            "SCRSUB",                                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2195 */  { fnHide,                       TM_VALUE,                    "HIDE",                                        "HIDE",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2196 */  { fnDenMax,                     TM_VALUE,                    "DMX",                                         "DMX",                                         (0 << TAM_MAX_BITS) | MAX_DENMAX, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_16    },
/* 2197 */  { fnSetSignificantDigits,       TM_VALUE,                    "SDIGS",                                       "SDIGS",                                       (0 << TAM_MAX_BITS) |    34, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2198 */  { fnSetVolume,                  TM_VALUE,                    "VOL",                                         "VOL",                                         (0 << TAM_MAX_BITS) |    11, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NUMBER_8     },
/* 2199 */  { fnGetVolume,                  NOPARAM,                     "VOL?",                                        "VOL?",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2200 */  { fnVolumeUp,                   NOPARAM,                     "VOL" STD_UP_ARROW,                            "VOL" STD_UP_ARROW,                            (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2201 */  { fnVolumeDown,                 NOPARAM,                     "VOL" STD_DOWN_ARROW,                          "VOL" STD_DOWN_ARROW,                          (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2202 */  { fnBuzz,                       NOPARAM,                     "BUZZ",                                        "BUZZ",                                        (0 << TAM_MAX_BITS) |     0, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_NONE         },
/* 2203 */  { fnPlay,                       TM_REGISTER,                 "PLAY",                                        "PLAY",                                        (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_REGISTER     },
/* 2204 */  { fnL100Tokml,                  multiply,                    "l/hkm" STD_RIGHT_ARROW "km/l",                "l/100km" STD_RIGHT_ARROW,                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2205 */  { fnL100Tokml,                  divide,                      "km/l" STD_RIGHT_ARROW "l/hkm",                "km/l" STD_RIGHT_ARROW,                        (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2206 */  { fnKmletok100K,                multiply,                    "km/l" STD_SUB_e STD_RIGHT_ARROW "E/hkm",      "km/l" STD_SUB_e STD_RIGHT_ARROW,              (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2207 */  { fnKmletok100K,                divide,                      "E/hkm" STD_RIGHT_ARROW "km/l" STD_SUB_e,      "kWh/100km" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2208 */  { fnK100Ktokmk,                 multiply,                    "E/hkm" STD_RIGHT_ARROW "km/E",                "kWh/100km" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2209 */  { fnK100Ktokmk,                 divide,                      "km/E" STD_RIGHT_ARROW "E/hkm",                "km/kWh" STD_RIGHT_ARROW,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2210 */  { fnL100Tomgus,                 multiply,                    "l/hkm" STD_RIGHT_ARROW "mpg" STD_US,          "l/100km" STD_RIGHT_ARROW,                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2211 */  { fnL100Tomgus,                 divide,                      "mpg" STD_US STD_RIGHT_ARROW "l/hkm",          "mpg" STD_US STD_RIGHT_ARROW,                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2212 */  { fnMgeustok100M,               multiply,                    "mge" STD_US STD_RIGHT_ARROW "E/100mi",        "mge" STD_US STD_RIGHT_ARROW,                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2213 */  { fnMgeustok100M,               divide,                      "E/100mi" STD_RIGHT_ARROW "mge" STD_US,        "kWh/100mi" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2214 */  { fnK100Ktok100M,               multiply,                    "E/hkm" STD_RIGHT_ARROW "E/100mi",             "kWh/100km" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2215 */  { fnK100Ktok100M,               divide,                      "E/100mi" STD_RIGHT_ARROW "E/hkm",             "kWh/100mi" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2216 */  { fnL100Tomguk,                 multiply,                    "l/hkm" STD_RIGHT_ARROW "mpg" STD_UK,          "l/100km" STD_RIGHT_ARROW,                     (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2217 */  { fnL100Tomguk,                 divide,                      "mpg" STD_UK STD_RIGHT_ARROW "l/hkm",          "mpg" STD_UK STD_RIGHT_ARROW,                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2218 */  { fnMgeuktok100M,               multiply,                    "mge" STD_UK STD_RIGHT_ARROW "E/100mi",        "mge" STD_UK STD_RIGHT_ARROW,                  (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2219 */  { fnMgeuktok100M,               divide,                      "E/100mi" STD_RIGHT_ARROW "mge" STD_UK,        "kWh/100mi" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2220 */  { fnK100Mtomik,                 multiply,                    "E/100mi" STD_RIGHT_ARROW "mi/E",              "kWh/100mi" STD_RIGHT_ARROW,                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2221 */  { fnK100Mtomik,                 divide,                      "mi/E" STD_RIGHT_ARROW "E/100mi",              "mi/kWh" STD_RIGHT_ARROW,                      (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_NONE         },
/* 2222 */  { itemToBeCoded,                NOPARAM,                     "Ymmv:",                                       "Ymmv:",                                       (0 << TAM_MAX_BITS) |     0, CAT_MENU | SLS_UNCHANGED | US_UNCHANGED | EIM_DISABLED | PTP_DISABLED     },
/* 2223 */  { fnExecutePlusSkip,            TM_LABEL,                    "XEQ.SKP",                                     "XEQ.SKP",                                     (0 << TAM_MAX_BITS) |    99, CAT_FNCT | SLS_ENABLED   | US_ENABLED   | EIM_DISABLED | PTP_LABEL        },

/* 2224 */  { itemToBeCoded,                NOPARAM,                     "",                                            "Last item",                                   (0 << TAM_MAX_BITS) |     0, CAT_NONE | SLS_ENABLED   | US_UNCHANGED | EIM_DISABLED},
};
