// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

/*
Math changes:

1. addon.c: Added fnArg_all which uses fnArg, but gives a result of 0 for a real
   and longint input. The testSuite is not ifluenced. Not needed to modify |x|,
   as it already works for a real and longint.
   (testSuite not in use for fnArg, therefore also not added)

2. bufferize.c: closenim: changed the default for (0 CC EXIT to 0) instead of i.
   (testSuite not ifluenced).

Todo


All the below: because both Last x and savestack does not work due to multiple steps.

  5. Added Star > Delta. Change and put in separate c file, and sort out savestack.
  6. vice versa
  7. SYM>ABC
  8. ABC>SYM
  9. e^theta. redo in math file,
  10. three phase Ohms Law: 17,18,19


 Check for savestack in jm.c
*/


void fnEdit (uint16_t unusedParamButMandatory) {
  //fnEdit: this is simply the stub with the currently working edit routines, linked via ITM_EDIT, which is also located on long press Backspace.
  //All might have to be changed have a propoer generic EDIT function.
  #if !defined(TESTSUITE_BUILD)
    if(tam.mode != 0) goto err;
    switch(calcMode) {
      case CM_NORMAL :
        if(currentMenu() == -MNU_EQN || currentMenu() == -MNU_Sfdx || currentMenu() == -MNU_Solver_TOOL || currentMenu() == -MNU_Sf_TOOL || currentMenu() == -MNU_GRAPHS ||
           (currentMenu() == -MNU_MVAR && (currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE))         ) {
          showSoftmenu(-MNU_EQN);
          runFunction(ITM_EQ_EDI);
        } else if(getRegisterDataType(REGISTER_X) == dtString) {
          calcModeAim(NOPARAM);
          runFunction(ITM_XEDIT);
        }
        else {
          goto err;
        }
        break;
      case CM_AIM :
        runFunction(ITM_XEDIT);
        break;
      default:
err:
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "Calculator mode or type not supported for EDIT command");
          moreInfoOnError("In function fnEdit:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        break;
    }
  #endif
}


#ifdef DMCP_BUILD
  void standardScreenDump(void) {
  resetShiftState();                  //JM To avoid f or g top left of the screen, clear to make sure
  int32_t vol = 0;
  vol = getBeepVolume();
  fnSetVolume(11);
  _Buzz(100,5);
  xcopy(tmpString, errorMessage, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);       //backup portion of the "message buffer" area in DMCP used by ERROR..AIM..NIM buffers, to the tmpstring area in DMCP. DMCP uses this area during create_screenshot.
  create_screenshot(0);      //Screen dump
  xcopy(errorMessage, tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);        //   This total area must be less than the tmpString storage area, which it is.
  _Buzz(100,5);
  fnSetVolume((uint16_t)vol);
}
#endif //DMCP_BUILD


bool_t anyKeyWaiting(void) {
  #if defined(DMCP_BUILD)
    return key_empty() == 0 || key_tail() != -1;
  #elif defined(PC_BUILD) // !DMCP_BUILD
    //printf("KeyWaiting keyCode=%u",currentKeyCode);
    return currentKeyCode == 32; //EXIT1 / EXIT key //Do not us gtk_events_pending() as it triggers for timers too
  #endif // PC_BUILD
  return false;
}



bool_t exitKeyWaiting(void) {
  #if defined(DMCP_BUILD)
    bool_t checkKey = C47PopKeyNoBuffer(DISPLAY_WAIT_FOR_RELEASE) == 32;
    if(!checkKey) {
      key_pop_all();
      clearKeyBuffer();
    }
    return checkKey;
  #elif defined(PC_BUILD) // !DMCP_BUILD
    //printf("KeyWaiting keyCode=%u",currentKeyCode);
    return currentKeyCode == 32; //EXIT1 / EXIT key //Do not us gtk_events_pending() as it triggers for timers too
  #endif // PC_BUILD
  return false;
}


int C47PopKeyNoBuffer(bool_t displayWaitForRelease) {
  int tmpf = -1;
  #if defined(DMCP_BUILD)
    if(!anyKeyWaiting()) return -1;
    if(displayWaitForRelease) {
      #if !defined(TESTSUITE_BUILD)
        showString("Waiting for key ...", &standardFont, 20, 40, vmNormal, false, false);
      #endif //!TESTSUITE_BUILD
      force_refresh(force);
////Monitor key codes on screen
//char sss[22];
//sprintf(sss,"%i   AA ",sys_last_key());
//print_linestr(sss,true);
    }
    wait_for_key_release(0);
    bool_t signalToDoScreenDump = false;
    bool_t signalToDoEXIT       = false;
    bool_t signalToDoRS         = false;
    int tmpz = -1;
    while(anyKeyWaiting()) {
      tmpz = key_pop();
      if(tmpz > 0) tmpf = tmpz;                     //use the last key in the buffer
      if(tmpz == 44) signalToDoScreenDump = true;   //if any key in the buffer is 44
      if(tmpz == 33) signalToDoEXIT = true;
      if(tmpz == 36) signalToDoRS = true;
    }

    if(signalToDoScreenDump) {
      standardScreenDump();
      tmpf = 0;
    }
    if(signalToDoRS) {
      tmpf = 36;
    }
    if(signalToDoEXIT) {
      tmpf = 33;
    }
    return tmpf - 1;        //EXIT = 33-1
  #else // !DMCP_BUILD
    tmpf = currentKeyCode;
    currentKeyCode = 255;
    return tmpf;           //EXIT = 32
  #endif // DMCP_BUILD
}


void fnShoiXRepeats(uint16_t numberOfRepeats) {           //JM SHOIDISP
  displayStackSHOIDISP = numberOfRepeats;                 //   0-3
  fnRefreshState();

  //if(getRegisterDataType(REGISTER_X) == dtShortInteger) {
  //  fnChangeBaseJM(getRegisterTag(REGISTER_X));
  //}
  //else {
  //  if(lastIntegerBase > 1 && lastIntegerBase <= 16) {
  //    fnChangeBaseJM(lastIntegerBase);
  //  }
  //}
}


void fnCFGsettings(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    runFunction(ITM_FF);
    showSoftmenu(-MNU_SYSFL);
  #endif // !TESTSUITE_BUILD
}


//=-=-=-=-=-=-==-=-
//input is date
//output is ymd coded decimal yyyy.mmdd in the form of a normal decimal
void fnFrom_ymd(uint16_t unusedButMandatoryParameter){
  #if !defined(TESTSUITE_BUILD)
    if(getRegisterDataType(REGISTER_X) == dtDate) {
      fnToReal(NOPARAM);
    }
  #endif // !TESTSUITE_BUILD
}



//=-=-=-=-=-=-==-=-
//input is time or DMS
//output is sexagesima coded decimal ddd.mmsssssss in the form of a normal decimal
void fnFrom_ms(uint16_t unusedButMandatoryParameter){
  #if !defined(TESTSUITE_BUILD)
    char tmpString100[100];
    char tmpString100_OUT[100];
    tmpString100[0] = 0;
    tmpString100_OUT[0] = 0;

    if(getRegisterDataType(REGISTER_X) == dtTime) {
      temporaryInformation = TI_FROM_MS_TIME;
    }
    else if(getRegisterDataType(REGISTER_X) == dtReal34 && getRegisterAngularMode(REGISTER_X) != amNone) {
      if(getRegisterAngularMode(REGISTER_X) != amDMS) {
        fnAngularModeJM(amDMS);
      }
      temporaryInformation = TI_FROM_MS_DEG;
    }
    else {
      temporaryInformation = TI_NO_INFO;
    }

    if(temporaryInformation != TI_NO_INFO) {
      if(temporaryInformation == TI_FROM_MS_TIME) {
        copyRegisterToClipboardString2(REGISTER_X, tmpString100);
      }
      if(temporaryInformation == TI_FROM_MS_DEG) {
        real34ToDisplayString(REGISTER_REAL34_DATA(REGISTER_X), getRegisterAngularMode(REGISTER_X), tmpString100, &standardFont, SCREEN_WIDTH, NUMBER_OF_DISPLAY_DIGITS, !LIMITEXP, FRONTSPACE, NOIRFRAC);
        int16_t tmp_i = 0;
        while(tmpString100[tmp_i] != 0 && tmpString100[tmp_i+1] != 0) { //pre-condition the dd.mmssss to replaxce spaces with zeroes
          //printf("%c %d", tmpString100[tmp_i], tmpString100[tmp_i]);
          if((uint8_t)tmpString100[tmp_i] == 128 && (uint8_t)tmpString100[tmp_i+1] == 176) {
            tmpString100[tmp_i]   = ' ';
            tmpString100[tmp_i+1] = 'o';
          }
          if((uint8_t)tmpString100[tmp_i] == 'o' && (uint8_t)tmpString100[tmp_i+1] == ' ') {
            tmpString100[tmp_i+1] = '0';
          }
          if((uint8_t)tmpString100[tmp_i] == ':' && (uint8_t)tmpString100[tmp_i+1] == ' ') {
            tmpString100[tmp_i+1] = '0';
          }
          if((uint8_t)tmpString100[tmp_i] == '\'' && (uint8_t)tmpString100[tmp_i+1] == ' ') {
            tmpString100[tmp_i+1] = '0';
          }
          tmp_i++;
        }
      }

      //printf(" ------- 002 >>>%s<<<\n", tmpString100);

      int16_t tmp_j, tmp_i;
      tmp_i = tmp_j = 0;
      bool_t decimalflag = false;
      while(tmpString100[tmp_i] != 0) {
        //printf("%c %d",(uint8_t)tmpString100[tmp_i], (uint8_t)tmpString100[tmp_i]);
        switch((uint8_t)tmpString100[tmp_i]) {
          case '0' :
          case '1' :
          case '2' :
          case '3' :
          case '4' :
          case '5' :
          case '6' :
          case '7' :
          case '8' :
          case '9' :
          case '+' :
          case '-' :
            //printf("-\n");
            tmpString100_OUT[tmp_j] = (uint8_t)tmpString100[tmp_i];
            tmpString100_OUT[++tmp_j] = 0;
            break;
          case 'o' :
          case ':' :
          case '.' :
          case ',' :
            if(!decimalflag) {
              //printf("decimal\n");
              decimalflag = true;
              tmpString100_OUT[tmp_j] = '.';
              tmpString100_OUT[++tmp_j] = 0;
            }
            break;
          default:
            //printf("ignore.\n");
            break;
        }
        tmp_i++;
      }

      if(tmpString100_OUT[0] != 0) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        stringToReal34(tmpString100_OUT, REGISTER_REAL34_DATA(REGISTER_X));
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          printf("\n ------- 003 >>>%s<<<\n",tmpString100_OUT);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
    }

    //stringToReal(tmpString100, &value, &ctxtReal39);
  #endif // !TESTSUITE_BUILD
}


/*
* If in direct entry, accept h.ms, example 1.23 [.ms] would be 1:23:00. Do not change the ADM.
* If closed in X: and X is REAL/integer, then convert this to h.ms. Do not change the ADM.
* If closed in X: and X is already a Time in visible hms like 1:23:45, then change the time to REAL, then tag the REAL with d.ms (‘’) in the form 1°23’45.00’’. Do not change the ADM.
* if closed in X: and X is already d.ms, then convert X to time in h:ms.Do not change the ADM.
*/
//


// 2023-09-07
// Current operation:
//   A.    From NIM press .ms: always real/integer (no angle), converting the digits to “h” ”m” ”s”:
//   a.    Example 1.2345 .ms -> 1:23:45, No change.
//
//   B.    With H:M:S (1:23:45) in X, press .ms (again): rewrite the hexadecimal digits and tag as angle
//   a.    Example 1:23:45 in X, .ms -> 1°23’45’’ tagged angle, No change
//
//   C.    With Real/Integer (hours) in X press .ms: -> convert X hours to HMS:
//   a.    Example 1.2345 ENTER, .ms -> 1:14:04.2, No change.
//
//   D.    Tagged angle in X: RAD GRAD MULpi in X, .ms: no action. Proposed change.
//
//   E.    Tagged angle in X: DMS, press .ms: rewrite D:M:S to H:M:S. No change.
//   a.    Press .ms again, see (B)
//
//   F.    Tagged angle in X: DEG, .ms: do >>DMS
//   a.    Press again, see (E), the cyclic continue as now, no change
//
// I propose these CHANGES for Tagged angles only:
//   D.    Tagged angle in X: RAD GRAD MULpi in X, .ms: Change to do: >>DMS
//   a.    Press again, see (E), the cyclic continue as now, no change




void fnTo_ms(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    switch(calcMode) { //JM
      case CM_NIM:
        addItemToNimBuffer(ITM_ms);
        break;

      case CM_NORMAL:
        copySourceRegisterToDestRegister(REGISTER_L, TEMP_REGISTER_1); // STO TMP

        switch(getRegisterDataType(REGISTER_X)) { //if integer, make a real
          case dtShortInteger:
            convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            break;
          case dtLongInteger:
            convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
            break;
          default:
            break;
        }

        if(getRegisterDataType(REGISTER_X) == dtReal34) {
          if(getRegisterAngularMode(REGISTER_X) == amDMS) {
            if(calcMode == CM_NORMAL) {
              fnToReal(0);
            }
            else if(calcMode == CM_NIM) {
              addItemToNimBuffer(ITM_dotD);
            }
            fnHRtoTM(0);
          }
          else if(getRegisterAngularMode(REGISTER_X) == amDegree // ||
//             getRegisterAngularMode(REGISTER_X) == amRadian ||
//             getRegisterAngularMode(REGISTER_X) == amGrad   ||
//             getRegisterAngularMode(REGISTER_X) == amMultPi
            ) {
            fnAngularModeJM(amDMS);
          }
          else if(getRegisterAngularMode(REGISTER_X) == amNone) {
            fnHRtoTM(0);
          }
          else {
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            #if (EXTRA_INFO_ON_CALC_ERROR == 1)
              sprintf(errorMessage, "cannot calculate specific type/tag");
              moreInfoOnError("In function fnTo_ms:", errorMessage, NULL, NULL);
            #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
          }
        }
        else if(getRegisterDataType(REGISTER_X) == dtTime) {
          fnToHr(0);
          setRegisterAngularMode(REGISTER_X, amDegree);
          fnCvtFromCurrentAngularMode(amDMS);
        }

        copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L); // STO TMP
        break;

      case CM_REGISTER_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_FONT_BROWSER:
      case CM_PLOT_STAT:
      case CM_LISTXY: //JM
      case CM_GRAPH:  //JM
        break;

      default:
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnTo_ms", calcMode, ".ms");
        displayBugScreen(errorMessage);
    }
  #endif // !TESTSUITE_BUILD
}


void addzeroes(char *st, uint8_t ix) {
  uint_fast8_t iy;
  strcpy(st, "1");
  for(iy = 0; iy < ix; iy++) {
    strcat(st, "0");
  }
}


void fnMultiplySI(uint16_t multiplier) {
  copySourceRegisterToDestRegister(REGISTER_L, TEMP_REGISTER_1); // STO TMP
  char mult[64];
  char divi[64];
  mult[0] = 0;
  divi[0] = 0;

  uint16_t base = 10;

  if(multiplier > 100 && multiplier <= 100 + 18) {
    addzeroes(mult, multiplier - 100);
    base = 10;
  }
  else if(multiplier < 100 && multiplier >= 100 - 18) {
    addzeroes(divi, 100 - multiplier);
    base = 10;
  }
  else if(multiplier == 100) {
    strcpy(mult, "1");
    base = 10;
  }
  else if(multiplier > 200 && multiplier <= 200 + 50) {
    addzeroes(mult, multiplier - 200);
    base = 2;
  }
  else if(multiplier == 200) {
    strcpy(mult, "1");
    base = 2;
  }


  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  longInteger_t lgInt;
  longIntegerInit(lgInt);

  if(mult[0] != 0) {
    stringToLongInteger(mult + (mult[0] == '+' ? 1 : 0), base, lgInt);
    convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
    longIntegerFree(lgInt);
    fnMultiply(0);
  }
  else if(divi[0] != 0) {
    stringToLongInteger(divi + (divi[0] == '+' ? 1 : 0), base, lgInt);
    convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
    longIntegerFree(lgInt);
    fnDivide(0);
  }

  adjustResult(REGISTER_X, false, false, REGISTER_X, REGISTER_Y, -1);
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L); // STO TMP
}


#define forcedLiftTheStack true

static void cpxToStk(const real_t *real1, const real_t *real2, const bool_t sl) {
  if(sl == forcedLiftTheStack) setSystemFlag(FLAG_ASLIFT);
  liftStack();
//  reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
//  realToReal34(real1, REGISTER_REAL34_DATA(REGISTER_X));
//  realToReal34(real2, REGISTER_IMAG34_DATA(REGISTER_X));
//  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  convertComplexToResultRegister(real1, real2, REGISTER_X);
}


void fn_cnst_op_j(uint16_t unusedButMandatoryParameter) {
  if(calcMode == CM_NIM || calcMode == CM_MIM) {
    fnKeyCC(ITM_op_j);
  }
  else {
    cpxToStk(const_0, const_1, !forcedLiftTheStack);
  }
}


void fn_cnst_op_j_pol(uint16_t unusedButMandatoryParameter) {
  if(calcMode == CM_NIM || calcMode == CM_MIM) {
    fnKeyCC(ITM_op_j_pol);
  }
  else {
    cpxToStk(const_0, const_1, !forcedLiftTheStack);
    fnToPolar2(0);
  }
}


void fn_cnst_op_aa(uint16_t unusedButMandatoryParameter) {
  cpxToStk(const_1on2, const_root3on2, !forcedLiftTheStack);
  chsCplx();
}


void fn_cnst_op_a(uint16_t unusedButMandatoryParameter) {
  fn_cnst_op_aa(0);
  conjCplx();
}


void fn_cnst_0_cpx(uint16_t unusedButMandatoryParameter) {
  cpxToStk(const_0, const_0, !forcedLiftTheStack);
}


void fn_cnst_1_cpx(uint16_t unusedButMandatoryParameter) {
  cpxToStk(const_1, const_0, !forcedLiftTheStack);
}

struct cmplxPair {
  real_t r, i;
};

void fn_cnst_op_A(uint16_t unusedButMandatoryParameter) {
  complex34Matrix_t matrixC;

  if(!saveLastX()) {
    return;
  }

  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  convertRealToResultRegister(const_0, REGISTER_X,amNone);

  //Initialize Memory for Matrix
  if(initMatrixRegister(REGISTER_X, 3, 3, true)) {
  }
  else {
    displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
    #if (EXTRA_INFO_ON_CALC_ERROR == 1)
      sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
      moreInfoOnError("In function fn_cnst_op_A:", errorMessage, NULL, NULL);
    #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    return;
  }
  adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);

  linkToComplexMatrixRegister(REGISTER_X,  &matrixC);

  real_t const__rt3on2, const_rt3on2, const__1on2;
  realDivide(const_rt3,const_2,&const_rt3on2,&ctxtReal39);
  realDivide(const_rt3,const_2,&const__rt3on2,&ctxtReal39);
  realSetNegativeSign(&const__rt3on2);
  realCopy(const_1on2,&const__1on2);
  realSetNegativeSign(&const__1on2);

  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[4]));
  realToReal34(&const__rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[4]));
  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[5]));
  realToReal34(&const_rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[5]));
  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[7]));
  realToReal34(&const_rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[7]));
  realToReal34(&const__1on2, VARIABLE_REAL34_DATA(&matrixC.matrixElements[8]));
  realToReal34(&const__rt3on2, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[8]));

  for (int i = 0; i < 3; i++) {
    realToReal34(const_1, VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]));
    real34Zero(VARIABLE_IMAG34_DATA(&matrixC.matrixElements[i]));
    if(i != 0) {
      realToReal34(const_1, VARIABLE_REAL34_DATA(&matrixC.matrixElements[i*3]));
      real34Zero(VARIABLE_IMAG34_DATA(&matrixC.matrixElements[i*3]));
    }
  }
  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
}



TO_QSPI static const struct {
    unsigned rows  : 2;
    unsigned cols  : 2;
    unsigned x     : 2;
    unsigned y     : 2;
    unsigned z     : 2;
    unsigned xdef  : 2;
    unsigned ydef  : 2;
    unsigned zdef  : 2;
} vecCreate[] = {
//  type     r  c   x    y    z   xdef ydef zdef
    [ 1] = { 3, 1,  2 ,  1,   0,   2,   2,   2 },     // 3x1 vector created from xyz FOR ELEC menu
    [ 2] = { 1, 3,  0 ,  1,   2,   2,   2,   2 },     // 1x3 vector created from zyx FOR MATX menu
    [ 3] = { 1, 3,  0 ,  1,   2,   0,   0,   1 },     // 1x3 unity vectors 100
    [ 4] = { 1, 3,  0 ,  1,   2,   0,   1,   0 },     // 1x3 unity vectors 010
    [ 5] = { 1, 3,  0 ,  1,   2,   1,   0,   0 },     // 1x3 unity vectors 001

    [ 6] = { 1, 2,  0 ,  1,   3,   2,   2,   3 },     // 1x2 vector created from yx
    [ 7] = { 1, 2,  0 ,  1,   3,   0,   1,   3 },     // 1x2 unity vectors 10
    [ 8] = { 1, 2,  0 ,  1,   3,   1,   0,   3 }      // 1x2 unity vectors 01

    // r c is the size of the matrix to be created, eg. 1x3 or 2x1 etc.
    // x y z are the matrix element number mapping to the register name, eg. x=2 means x register goes to internal matrix element 2; 3 means not copied
    // xdef/ydef/zdef
    //   = 1/0 : the value to be pre-loaded into the matrix element
    //   = 2   : the value is copied from register X, Y or Z to the specified matrix element
    //   = 3   : not copied
  };


static bool_t processDefaultVector(calcRegister_t regist, uint8_t p, uint8_t d, struct cmplxPair *x, bool_t *complexCoefs) {
  if(d == 2) {
    if(!getRegisterAsComplexOrReal(regist, &x[p].r, &x[p].i, complexCoefs)) {
      return false;
    }
  } 
  else if(d < 2) {
    realCopy(d == 1 ? const_1 : const_0, &x[p].r);
  }
  return true;
}


void fnConvertStkToMx(uint16_t constVector) {
  bool_t complexCoefs = false;
  struct cmplxPair x[3];
  real34Matrix_t matrix;
  complex34Matrix_t matrixC;
  uint16_t elements;

  elements = vecCreate[constVector].rows * vecCreate[constVector].cols;

  if(!processDefaultVector(REGISTER_X, vecCreate[constVector].x, vecCreate[constVector].xdef, x, &complexCoefs)) return;
  if(!processDefaultVector(REGISTER_Y, vecCreate[constVector].y, vecCreate[constVector].ydef, x, &complexCoefs)) return;
  if(max(vecCreate[constVector].z, vecCreate[constVector].zdef) != 3 && 
     !processDefaultVector(REGISTER_Z, vecCreate[constVector].z, vecCreate[constVector].zdef, x, &complexCoefs)) return;

  if(!saveLastX()) {
    return;
  }

  if(vecCreate[constVector].xdef < 2 || vecCreate[constVector].ydef < 2 || vecCreate[constVector].zdef < 2) {
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
  } else {
    fnDrop(NOPARAM);
    if(elements > 2) {
      fnDrop(NOPARAM);
    }
  }


  if(getRegisterDataType(REGISTER_X) != dtReal34Matrix && getRegisterDataType(REGISTER_X) != dtComplex34Matrix) {
    //Initialize Memory for Matrix
    if(initMatrixRegister(REGISTER_X, vecCreate[constVector].rows, vecCreate[constVector].cols, complexCoefs)) {
    }
    else {
      displayCalcErrorMessage(ERROR_NOT_ENOUGH_MEMORY_FOR_NEW_MATRIX, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "Not enough memory for a %" PRIu32 STD_CROSS "%" PRIu32 " matrix", 1, 1);
        moreInfoOnError("In function fnConvertStkToMx:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return;
    }
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  }


  if(complexCoefs) {
    linkToComplexMatrixRegister(REGISTER_X,  &matrixC);
  } else {
    linkToRealMatrixRegister(REGISTER_X,  &matrix);
  }


  for (int i = 0; i < elements; i++) {
    if(complexCoefs) {
      realToReal34(&x[elements-1-i].r, VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]));
      realToReal34(&x[elements-1-i].i, VARIABLE_IMAG34_DATA(&matrixC.matrixElements[i]));
    }
    else {
      realToReal34(&x[elements-1-i].r, &matrix.matrixElements[i]);
    }
  }

  adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);

}

void fnConvertMxToStk(uint16_t param) {
  real34Matrix_t matrix;
  complex34Matrix_t matrixC;

  if(!(getRegisterDataType(REGISTER_X) == dtReal34Matrix || getRegisterDataType(REGISTER_X) == dtComplex34Matrix)) {
    return;
  }

  if(!saveLastX()) {
    return;
  }

  copySourceRegisterToDestRegister(REGISTER_X,TEMP_REGISTER_1);
  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  convertRealToResultRegister(const_0, REGISTER_X,amNone);
  convertRealToResultRegister(const_0, REGISTER_Y,amNone);
  convertRealToResultRegister(const_0, REGISTER_Z,amNone);

  if(getRegisterDataType(TEMP_REGISTER_1) == dtComplex34Matrix) {
    linkToComplexMatrixRegister(TEMP_REGISTER_1,  &matrixC);
  } else {
    linkToRealMatrixRegister(TEMP_REGISTER_1,  &matrix);
  }


  for (int i = 0; i < 3; i++) {
    uint16_t rg = vecCreate[param].x == 2-i ? REGISTER_X : vecCreate[param].y == 2-i ? REGISTER_Y : vecCreate[param].z == 2-i ? REGISTER_Z : 0;
    if(getRegisterDataType(TEMP_REGISTER_1) == dtComplex34Matrix) {
      real34Copy(VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]),REGISTER_REAL34_DATA(rg));
      real34Copy(VARIABLE_REAL34_DATA(&matrixC.matrixElements[i]),REGISTER_IMAG34_DATA(rg));
    }
    else {
      real34Copy(&matrix.matrixElements[i],REGISTER_REAL34_DATA(rg));
    }
    adjustResult(rg, false, false, rg, -1, -1);
  }
}


//Rounding
void fnJM_2SI(uint16_t unusedButMandatoryParameter) { //Convert Real to Longint; Longint to shortint; shortint to longint
  if(calcMode == CM_NIM) {
    if((   (nimNumberPart == NP_INT_BASE && aimBuffer[strlen(aimBuffer) - 1] == '#')
        || (nimNumberPart == NP_INT_10 && lastIntegerBase > 0)   )) {
      #if defined (PC_BUILD)
        printf("Do not react when in NIM SI\n");
      #endif //PC_BUILD
      return;
    }
  }
  longInteger_t tmp1, tmp3;
  switch(getRegisterDataType(REGISTER_X)) {
    case dtLongInteger:
      convertLongIntegerRegisterToLongInteger(REGISTER_X, tmp3);
      if(shortIntegerMode == SIM_UNSIGN && longIntegerIsNegative(tmp3)) {
        temporaryInformation = TI_DATA_NEG_OVRFL;
      }
      convertLongIntegerRegisterToShortIntegerRegister(REGISTER_X, REGISTER_X); //default to 10
      if(lastIntegerBase >= 2 && lastIntegerBase <= 16 && lastIntegerBase != 10) {
        fnChangeBase(lastIntegerBase);
      }
      convertShortIntegerRegisterToLongInteger(REGISTER_X, tmp1);

      if(longIntegerCompare(tmp1,tmp3) != 0) {
        if(temporaryInformation != TI_DATA_NEG_OVRFL) {
          temporaryInformation = TI_DATA_LOSS;             // I cannot think of which condition will reach here, without other overflows overriding, but leaving it in
        }
        setSystemFlag(FLAG_OVERFLOW);
      }
      longIntegerFree(tmp1);
      longIntegerFree(tmp3);

      break;
    case dtReal34:
      fnRoundi(0);
      break;
    case dtShortInteger:
      convertShortIntegerRegisterToLongIntegerRegister(REGISTER_X, REGISTER_X); //This shortint to longint!
      lastIntegerBase = 0;                                                      //JMNIM clear lastintegerbase, to switch off hex mode
      fnRefreshState();                                                         //JMNIM
      break;
    default:
      break;
  }
}


/* JM UNIT********************************************//**                                                JM UNIT
 * \brief Adds the power of 10 using numeric font to displayString                                        JM UNIT
 *        Converts to units like m, M, k, etc.                                                            JM UNIT
 * \param[out] displayString char*     Result string                                                      JM UNIT
 * \param[in]  exponent int32_t Power of 10 to format                                                     JM UNIT
 * \return void                                                                                           JM UNIT
 ***********************************************                                                          JM UNIT */
void exponentToUnitDisplayString(int32_t exponent, bool_t flag2To10, char *displayString, char *displayValueString, bool_t nimMode) {               //JM UNIT

TO_QSPI static const char SIprefixes[64]  = "q  r  y  z  a  f  p  n  u  m     k  M  G  T  P  E  Z  Y  R  Q  ";
TO_QSPI static const char ITSIprefixes[16] = "K  M  G  T  P  ";

  displayString[0] = ' ';
  displayString[1] = 0;
  displayString[2] = 0;
  displayString[3] = 0;

  if(!flag2To10 && !getSystemFlag(FLAG_2TO10)) {
      if((-15 <= exponent && exponent <= 15) ||
        (-30 <= exponent && exponent <= 30 && getSystemFlag(FLAG_PFX_ALL))) {
        displayString[1] = SIprefixes[exponent + 30];
        if(displayString[1] == 'u') {
          displayString[1] = STD_mu[0]; displayString[2] = STD_mu[1];
        }
      }
  }
  else if(flag2To10) {                            //exponent of 2^(10/3)

      if((3 <= exponent && exponent <= 15)) {
        displayString[1] = ITSIprefixes[exponent - 3];
        displayString[2] = 'i';
      }
    }

  if(displayString[1] == 0) {
    strcpy(displayString, PRODUCT_SIGN);                                                                //JM UNIT Below, copy of
    displayString += 2;                                                                                 //JM UNIT exponentToDisplayString in display.c
    strcpy(displayString, STD_SUB_10);                                                                  //JM UNIT
    displayString += 2;                                                                                 //JM UNIT
    displayString[0] = 0;                                                                               //JM UNIT
    if(nimMode) {                                                                                       //JM UNIT
      if(exponent != 0) {                                                                               //JM UNIT
        supNumberToDisplayString(exponent, displayString, displayValueString, false);                   //JM UNIT
      }                                                                                                 //JM UNIT
    }                                                                                                   //JM UNIT
    else {                                                                                              //JM UNIT
      supNumberToDisplayString(exponent, displayString, displayValueString, false);                     //JM UNIT
    }                                                                                                   //JM UNIT
  }                                                                                                     //JM UNIT
}                                                                                                       //JM UNIT


void fnDisplayFormatCycle (uint16_t unusedButMandatoryParameter) {
  if(DM_Cycling == 0 && softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PREFIX) {
    fnDisplayFormatUnit(displayFormatDigits);
  }
  else if(displayFormat == DF_UN) {
    fnDisplayFormatSigFig(displayFormatDigits);
  }
  else if(displayFormat == DF_SF ) {
    fnDisplayFormatAll(displayFormatDigits);
  }
  else if(displayFormat == DF_ALL) {
    fnDisplayFormatFix(displayFormatDigits);
  }
  else if(displayFormat == DF_FIX) {
    fnDisplayFormatSci(displayFormatDigits);
  }
  else if(displayFormat == DF_SCI) {
    fnDisplayFormatEng(displayFormatDigits);
  }
  else if(displayFormat == DF_ENG) {
    fnDisplayFormatUnit(displayFormatDigits);
  }
  DM_Cycling = 1;
}


//change the current state from the old state?
void fnAngularModeJM(uint16_t AMODE) { //Setting to HMS does not change AM
  #if !defined(TESTSUITE_BUILD)

  copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
  if(AMODE == TM_HMS) {
    if(getRegisterDataType(REGISTER_X) == dtTime) {
      goto to_return;
    }
    if(getRegisterDataType(REGISTER_X) == dtReal34 && getRegisterAngularMode(REGISTER_X) != amNone) {
      fnCvtFromCurrentAngularMode(amDegree);
    }

    if(calcMode == CM_NORMAL) {
      fnToReal(0);
    }
    else if(calcMode == CM_NIM) {
      addItemToNimBuffer(ITM_dotD);
    }

    fnHRtoTM(0); //covers longint & real
  }
  else {
    if(getRegisterDataType(REGISTER_X) == dtTime) {
      fnToHr(0); //covers time
      setRegisterAngularMode(REGISTER_X, amDegree);
      fnCvtFromCurrentAngularMode(AMODE);
      //fnAngularMode(AMODE);                             Remove updating of ADM to the same mode
    }

    if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
      //printf("###AA fnAngularModeJM (%i)<= %i\n",REGISTER_X, AMODE);
      //printf("###BB fnAngularModeJM (%i)=> %i\n",REGISTER_X, getRegisterTag(REGISTER_X));

      setComplexRegisterAngularMode(REGISTER_X, AMODE);
      setComplexRegisterPolarMode(REGISTER_X, amPolar);
      //printf("###CC fnAngularModeJM (%i)=> %i\n",REGISTER_X, getRegisterTag(REGISTER_X));
    }
    else {
      if((getRegisterDataType(REGISTER_X) != dtReal34) || ((getRegisterDataType(REGISTER_X) == dtReal34) && getRegisterAngularMode(REGISTER_X) == amNone)) {

        if(calcMode == CM_NORMAL) {         //convert longint, and strip all angles to real.
          fnToReal(0);
        }
        else if(calcMode == CM_NIM) {
          addItemToNimBuffer(ITM_dotD);
        }

        uint16_t currentAngularModeOld = currentAngularMode;
        fnAngularMode(AMODE);
        fnCvtFromCurrentAngularMode(currentAngularMode);
        currentAngularMode = currentAngularModeOld;       //Remove updating of ADM to the same mode (set in fnCvtFromCurrentAngularMode())
      }
      else { //convert existing tagged angle
        fnCvtFromCurrentAngularMode(AMODE);
      }
    }
  }

  to_return:
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
  #endif //TESTSUITE_BUILD
}



void DRG_cyc(uint16_t * dest) {
    DRG_Cycling = 1;
    switch(*dest) {
      case amNone:   *dest = currentAngularMode; break; //converts from to the same, i.e. get to current angle mode
      case amRadian: *dest = amGrad;             break;
      case amGrad:   *dest = amDegree;           break;
      case amDegree: *dest = amRadian;           break;
      case amDMS:    *dest = amDegree;           break;
      case amMultPi: *dest = amRadian;           break; //do not support Mulpi but at least get out of it
      default: ;
    }
  }


void fnDRG(uint16_t unusedButMandatoryParameter) {
  switch(getRegisterDataType(REGISTER_X)) {
    case dtTime:
    case dtDate:
    case dtString:
    case dtReal34Matrix:
    case dtConfig:
      goto to_return_noLastX;
      break;
    default: ;
  }

  copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
  uint16_t dest = 9999;

  if(getRegisterDataType(REGISTER_X) == dtComplex34 || getRegisterDataType(REGISTER_X) == dtComplex34Matrix) {
    setComplexRegisterPolarMode(REGISTER_X, amPolar);      //re-set it to Polar iven if it was there already
    dest = getComplexRegisterAngularMode(REGISTER_X);
    DRG_cyc(&dest);
    setComplexRegisterAngularMode(REGISTER_X,dest);

  }
  else if(getRegisterDataType(REGISTER_X) == dtShortInteger) {           // If shortinteger in X, convert to real
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);                          //is probably none already
  }
  else if(getRegisterDataType(REGISTER_X) == dtLongInteger) {            // If longinteger in X, convert to real
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
    setRegisterAngularMode(REGISTER_X, amNone);                          //is probably none already
  }

  if(getRegisterDataType(REGISTER_X) == dtReal34) {                      // if real
    dest = getRegisterAngularMode(REGISTER_X);

    if(dest != amNone && dest != currentAngularMode && DRG_Cycling != 1) {   //first step: convert tagged angle to ADM
      fnCvtToCurrentAngularMode(dest);
      goto to_return;
    }

    DRG_cyc(&dest);
    fnCvtFromCurrentAngularMode(dest);
    //currentAngularMode = dest;          //remove setting of ADM!
  }

  to_return:
  copySourceRegisterToDestRegister(TEMP_REGISTER_1, REGISTER_L);
  to_return_noLastX:
  return;
}


void shrinkNimBuffer(void) {                      //JMNIM vv
  int16_t lastChar; //if digits in NIMBUFFER, ensure switch to NIM,
  int16_t hexD = 0;
  bool_t reached_end = false;
  lastChar = strlen(aimBuffer) - 1;
  if(lastChar >= 1) {
    uint_fast16_t ix = 0;
    while(aimBuffer[ix] != 0) { //if # found in nimbuffer, return and do nothing
      if(aimBuffer[ix] >= 'A') {
        hexD++;
      }
      if(aimBuffer[ix] == '#' || aimBuffer[ix] == '.' || reached_end) { //chr(35) = "#"
        aimBuffer[ix] = 0;
        reached_end = true;
        //printf(">>> ***A # found. hexD=%d\n",hexD);
      }
      else {
        //printf(">>> ***B # not found in %s:%d=%d hexD=%d\n",nimBuffer,ix,nimBuffer[ix],hexD);
      }
      ix++;
    }
    if(hexD > 0) {
      nimNumberPart = NP_INT_16;
    }
    else {
      nimNumberPart = NP_INT_10;
    }
    //calcMode = CM_NIM;
  }
}                                                 //JMNIM ^^


void fnChangeBaseJM(uint16_t BASE) {
  #if !defined(TESTSUITE_BUILD)
    //printf(">>> §§§ fnChangeBaseJMa Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n", calcMode, nimBuffer, lastIntegerBase, nimNumberPart);
    shrinkNimBuffer();
    fnChangeBase(BASE);

    if(getSystemFlag(FLAG_HPBASE)) {
      for(uint16_t regist = REGISTER_X + 1; regist < REGISTER_X + (getSystemFlag(FLAG_SSIZE8) ? 8 : 4); regist ++ ) {
        if(getRegisterDataType(regist) == dtShortInteger) {
          if(2 <= BASE && BASE <= 16) {
            setRegisterTag(regist, BASE);
          }
          fnRefreshState();
        }
      }
    }

    nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
  #endif // !TESTSUITE_BUILD
}


void fnChangeBaseMNU(uint16_t BASE) {
  #if !defined(TESTSUITE_BUILD)

    if(calcMode == CM_AIM) {
      addItemToBuffer(ITM_toINT);
      return;
    }

    //printf(">>> §§§ fnChangeBaseMNUa Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n", calcMode, nimBuffer, lastIntegerBase, nimNumberPart);
    shrinkNimBuffer();
    //printf(">>> §§§ fnChangeBaseMNUb Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n", calcMode, nimBuffer, lastIntegerBase, nimNumberPart);

    if(lastIntegerBase == 0 && calcMode == CM_NORMAL && BASE > 1 && BASE <= 16) {
      //printf(">>> §§§fnChangeBaseMNc CM_NORMAL: convert non-shortint-mode to %d & return\n", BASE);
      fnChangeBaseJM(BASE);
      return;
    }

    if(calcMode == CM_NORMAL && BASE == NOPARAM) {
      //printf(">>> §§§fnChangeBaseMNd CM_NORMAL: convert non-shortint-mode to TAM\n");
      runFunction(ITM_toINT);
      return;
    }

    if(BASE > 1 && BASE <= 16) { //BASIC CONVERSION IN X REGISTER, OR DIGITS IN NIMBUFFER IF IN CM_NORMAL
      //printf(">>> §§§1 convert base to %d & return\n", BASE);
      fnChangeBaseJM(BASE);
      nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
      return;
    }

    if(aimBuffer[0] == 0 && calcMode == CM_NORMAL && BASE == NOPARAM) { //IF # FROM MENU & TAM.
      //printf(">>> §§§2 # FROM MENU: nimBuffer[0]=0; use runfunction\n");
      runFunction(ITM_toINT);
      nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
      return;
    }

    if(aimBuffer[0] != 0 && calcMode == CM_NIM) { //IF # FROM MENU, while in NIM, just add to NimBuffer
      //printf(">>> §§§3 # nimBuffer in use, addItemToNimBuffer\n");
      addItemToNimBuffer(ITM_toINT);
      nimBufferToDisplayBuffer(aimBuffer, nimBufferDisplay + 2);
      return;
    }

  #endif // !TESTSUITE_BUILD
}

/********************************************//**
 * \brief Set Input_Default
 *
 * \param[in] inputDefault uint16_t
 * \return void
 ***********************************************/
void fnInDefault(uint16_t inputDefault) {
  Input_Default = inputDefault;
  lastIntegerBase = 0;
  fnRefreshState();
}


void fnByteShortcutsS(uint16_t size) { //JM POC BASE2 vv
  fnSetWordSize(size);
  fnIntegerMode(SIM_2COMPL);
}


void fnByteShortcutsU(uint16_t size) {
  fnSetWordSize(size);
  fnIntegerMode(SIM_UNSIGN);
}


void fnP_Alpha(void) {
  #if !defined(TESTSUITE_BUILD)
    if(calcMode != CM_AIM) {
      #if defined(DMCP_BUILD)
        beep(440, 50);
        beep(4400, 50);
        beep(440, 50);
      #endif // DMCP_BUILD
      return;
    }
    xcopy(tmpString, aimBuffer, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);       //backup portion of the "message buffer" area in DMCP used by ERROR..AIM..NIM buffers, to the tmpstring area in DMCP. DMCP uses this area during create_screenshot.
    create_filename(".REGS.TSV");

    #if (VERBOSE_LEVEL >= 1)
      clearScreen(2);
      print_linestr("Output Aim Buffer to drive:", true);
      print_linestr(filename_csv, false);
    #endif // VERBOSE_LEVEL >= 1

    tmpString_csv_out(5);          //aimBuffer now already copied to tmpString
    xcopy(aimBuffer,tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH);        //   This total area must be less than the tmpString storage area, which it is.
    //print_linestr(aimBuffer,false);
  #endif
}



void fnP_Regs (uint16_t registerNo) {
  #if !defined(TESTSUITE_BUILD)
    if(calcMode != CM_NORMAL) {
      #if defined(DMCP_BUILD)
        beep(440, 50);
        beep(4400, 50);
        beep(440, 50);
      #endif // DMCP_BUILD
      return;
    }

    create_filename(".REGS.TSV");

    #if (VERBOSE_LEVEL >= 1)
      clearScreen(3);
      print_linestr("Output regs to drive:", true);
      print_linestr(filename_csv, false);
    #endif // VERBOSE_LEVEL >= 1

    stackregister_csv_out((int16_t)registerNo, (int16_t)registerNo, !ONELINE);

  #endif // !TESTSUITE_BUILD
}



void fnP_All_Regs(uint16_t option) {
  #if !defined(TESTSUITE_BUILD)
    if(calcMode != CM_NORMAL && calcMode != CM_NO_UNDO) {
      #if defined(DMCP_BUILD)
        beep(440, 50);
        beep(4400, 50);
        beep(440, 50);
      #endif // DMCP_BUILD
      return;
    }

    create_filename(".REGS.TSV");

    #if (VERBOSE_LEVEL >= 1)
      clearScreen(4);
      print_linestr("Output regs to drive:", true);
      print_linestr(filename_csv, false);
    #endif // VERBOSE_LEVEL >= 1

    switch(option) {
      case PRN_ALL:
        stackregister_csv_out(REGISTER_X, REGISTER_W, !ONELINE);
        stackregister_csv_out(0, 99, !ONELINE);
        if(currentNumberOfLocalRegisters > 0) stackregister_csv_out(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters - 1, !ONELINE);
        if(numberOfNamedVariables > 0) stackregister_csv_out(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1, !ONELINE);


        //stackregister_csv_out(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER+100, !ONELINE);
        break;

      case PRN_STK:
        if(getSystemFlag(FLAG_SSIZE8)) {
          stackregister_csv_out(REGISTER_X, REGISTER_D, !ONELINE);
        }
        else {
          stackregister_csv_out(REGISTER_X, REGISTER_T, !ONELINE);
        }
        break;

      case PRN_GLOBALr:
        stackregister_csv_out(0, 99, !ONELINE);
        break;

      case PRN_LOCALr:
        if(currentNumberOfLocalRegisters > 0) stackregister_csv_out(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + currentNumberOfLocalRegisters - 1, !ONELINE);
        break;

      case PRN_NAMEDr:
        if(numberOfNamedVariables > 0) stackregister_csv_out(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1, !ONELINE);
        break;

      case PRN_Xr:
        stackregister_csv_out(REGISTER_X, REGISTER_X, !ONELINE);
        break;

      case PRN_TMP:
        stackregister_csv_out(TEMP_REGISTER_1, TEMP_REGISTER_1, !ONELINE);
        break;

      case PRN_XYr:
        stackregister_csv_out(REGISTER_X, REGISTER_Y, ONELINE);
        break;

      default: ;
    }
  #endif // !TESTSUITE_BUILD
}


void doubleToXRegisterReal34(double x) { //Convert from double to X register REAL34
  setSystemFlag(FLAG_ASLIFT);
  liftStack();
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  snprintf(tmpString, TMP_STR_LENGTH, "%.16e", x);
  stringToReal34(tmpString, REGISTER_REAL34_DATA(REGISTER_X));
  //adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
  setSystemFlag(FLAG_ASLIFT);
}


void fnStrtoReg(const char buffer[], calcRegister_t regist) {                             //DONE
  int16_t mem = stringByteLength(buffer) + 1;
  reallocateRegister(regist, dtString, TO_BLOCKS(mem), amNone);
  xcopy(REGISTER_STRING_DATA(regist), buffer, mem);
}

void fnStrtoX(const char buffer[]) {                             //DONE
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();
  fnStrtoReg(buffer, REGISTER_X);
  setSystemFlag(FLAG_ASLIFT);
}


void fnStrInputReal34(char inp1[]) { // CONVERT STRING to REAL IN X      //DONE
  tmpString[0] = 0;
  strcat(tmpString, inp1);
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  stringToReal34(tmpString, REGISTER_REAL34_DATA(REGISTER_X));
  setSystemFlag(FLAG_ASLIFT);
}


void fnStrInputLongint(char inp1[]) { // CONVERT STRING to Longint X      //DONE
  tmpString[0] = 0;
  strcat(tmpString, inp1);
  setSystemFlag(FLAG_ASLIFT); // 5
  liftStack();

  longInteger_t lgInt;
  longIntegerInit(lgInt);
  stringToLongInteger(tmpString + (tmpString[0] == '+' ? 1 : 0), 10, lgInt);
  convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_X);
  longIntegerFree(lgInt);
  setSystemFlag(FLAG_ASLIFT);
}


void fnRCL(int16_t inp) { //DONE
  setSystemFlag(FLAG_ASLIFT);
  if(inp == TEMP_REGISTER_1) {
    liftStack();
    copySourceRegisterToDestRegister(inp, REGISTER_X);
  }
  else {
    fnRecall(inp);
  }
}


double convert_to_double(calcRegister_t regist) { //Convert from X register to double
  double y;
  real_t tmpy;
  switch(getRegisterDataType(regist)) {
    case dtLongInteger:
      convertLongIntegerRegisterToReal(regist, &tmpy, &ctxtReal39);
      break;
    case dtReal34:
      real34ToReal(REGISTER_REAL34_DATA(regist), &tmpy);
      break;
    default:
      return 0;
  }
  realToString(&tmpy, tmpString);
  y = strtof(tmpString, NULL);
  return y;
}


void timeToReal34(uint16_t hms) { //always 24 hour time;
  calcRegister_t regist = REGISTER_X;
  real34_t real34, value34, tmp34, h34, m34, s34;
  int32_t sign;
  uint32_t digits, tDigits = 0u, bDigits;
  bool_t isValid12hTime = false; //, isAfternoon = false;

  real34Copy(REGISTER_REAL34_DATA(regist), &real34);
  sign = real34IsNegative(&real34);

  // Pre-rounding
  int32ToReal34(10, &value34);
  int32ToReal34(10, &tmp34);
  for(bDigits = 0; bDigits < (isValid12hTime ? 14 : 16); ++bDigits) {
    if(real34CompareAbsLessThan(&h34, &value34)) {
      break;
    }
    real34Multiply(&value34, &tmp34, &value34);
  }
  tDigits = (isValid12hTime ? 14 : 16);
  isValid12hTime = false;

  for(digits = bDigits; digits < tDigits; ++digits) {
    real34Multiply(&real34, &value34, &real34);
  }
  real34ToIntegralValue(&real34, &real34, DEC_ROUND_HALF_UP);
  for(digits = bDigits; digits < tDigits; ++digits) {
    real34Divide(&real34, &value34, &real34);
  }
  tDigits = 0u;
  real34SetPositiveSign(&real34);

  if(hms == 3) {
    //total seconds
    reallocateRegister(regist, dtReal34, 0, amNone);
    real34Copy(&real34, REGISTER_REAL34_DATA(regist));
    return;
  }

  // Seconds
  //real34ToIntegralValue(&real34, &s34, DEC_ROUND_DOWN);
  real34Copy(&real34, &s34);
  real34Subtract(&real34, &s34, &real34); // Fractional part
  int32ToReal34(60, &value34);
  // Minutes
  real34Divide(&s34, &value34, &m34);
  real34ToIntegralValue(&m34, &m34, DEC_ROUND_DOWN);
  real34DivideRemainder(&s34, &value34, &s34);
  // Hours
  real34Divide(&m34, &value34, &h34);
  real34ToIntegralValue(&h34, &h34, DEC_ROUND_DOWN);
  real34DivideRemainder(&m34, &value34, &m34);

  switch(hms) {
    case 0: //h
      int32ToReal34(sign ? -1 : +1, &value34);
      real34Multiply(&h34, &value34, &h34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&h34, REGISTER_REAL34_DATA(regist));
      break;

    case 1: //m
      int32ToReal34(sign ? -1 : +1, &value34);
      real34Multiply(&m34, &value34, &m34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&m34, REGISTER_REAL34_DATA(regist));
      break;

    case 2: //s
      int32ToReal34(sign ? -1 : +1, &value34);
      real34Multiply(&s34, &value34, &s34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&s34, REGISTER_REAL34_DATA(regist));
      break;

    default: ;
  }
}


void dms34ToReal34(uint16_t dms) {
  real34_t angle34;
  calcRegister_t regist = REGISTER_X;
  real34_t value34, d34, m34, s34, fs34;
  real34Copy(REGISTER_REAL34_DATA(regist), &angle34);

  //    char degStr[27];
  uint32_t m, s, fs;
  int16_t sign;

  real_t temp, degrees, minutes, seconds;

  real34ToReal(&angle34, &temp);

  sign = realIsNegative(&temp) ? -1 : 1;
  realSetPositiveSign(&temp);

  // Get the degrees
  realToIntegralValue(&temp, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

  // Get the minutes
  realSubtract(&temp, &degrees, &temp, &ctxtReal39);
  temp.exponent += 2; // temp = temp * 100
  realToIntegralValue(&temp, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

  // Get the seconds
  realSubtract(&temp, &minutes, &temp, &ctxtReal39);
  temp.exponent += 2; // temp = temp * 100
  realToIntegralValue(&temp, &seconds, DEC_ROUND_DOWN, &ctxtReal39);

  // Get the fractional seconds
  realSubtract(&temp, &seconds, &temp, &ctxtReal39);
  temp.exponent += 2; // temp = temp * 100

  fs = realToUint32C47(&temp);
  s  = realToUint32C47(&seconds);
  m  = realToUint32C47(&minutes);

  if(fs >= 100) {
    fs -= 100;
    s++;
  }

  if(s >= 60) {
    s -= 60;
    m++;
  }

  if(m >= 60)  {
    m -= 60;
    realAdd(&degrees, const_1, &degrees, &ctxtReal39);
  }

  switch(dms)  {
    case 0: //d
      int32ToReal34(sign, &value34);
      realToReal34(&degrees, &d34);
      real34Multiply(&d34, &value34, &d34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&d34, REGISTER_REAL34_DATA(regist));
      break;

    case 1: //m
      int32ToReal34(m, &m34);
      int32ToReal34(sign, &value34);
      real34Multiply(&m34, &value34, &m34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&m34, REGISTER_REAL34_DATA(regist));
      break;

    case 2: //s
      int32ToReal34(fs, &fs34);
      int32ToReal34(100, &value34);
      real34Divide(&fs34, &value34, &fs34);

      int32ToReal34(s, &s34);
      real34Add(&s34, &fs34, &s34);

      int32ToReal34(sign, &value34);
      real34Multiply(&s34, &value34, &s34);
      reallocateRegister(regist, dtReal34, 0, amNone);
      real34Copy(&s34, REGISTER_REAL34_DATA(regist));
      break;

    default: ;
  }
}


void notSexa(void) {
  copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
  displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
  #if (EXTRA_INFO_ON_CALC_ERROR == 1)
    sprintf(errorMessage, "data type %s cannot be converted!", getRegisterDataTypeName(REGISTER_X, false, false));
    moreInfoOnError("In function notSexagecimal:", errorMessage, NULL, NULL);
  #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
}


void fnHrDeg(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(0);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(0);
  }
  else {
    notSexa();
  }
}


void fnMinute(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }
  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(1);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(1);
  }
  else {
    notSexa();
  }
}


void fnSecond(uint16_t unusedButMandatoryParameter){
  if(!saveLastX()) {
    return;
  }
  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(2);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(2);
  }
  else {
    notSexa();
  }
}


void fnTimeTo(uint16_t unusedButMandatoryParameter) {
  if(!saveLastX()) {
    return;
  }

  if(getRegisterAngularMode(REGISTER_X) == amDMS && getRegisterDataType(REGISTER_X) == dtReal34) {
    dms34ToReal34(0);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    dms34ToReal34(1);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    dms34ToReal34(2);
  }
  else if(getRegisterDataType(REGISTER_X) == dtTime) {
    timeToReal34(0);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    timeToReal34(1);
    liftStack();
    copySourceRegisterToDestRegister(REGISTER_L, REGISTER_X);
    timeToReal34(2);
  }
  else {
    notSexa();
    return;
  }
}


/********************************************//**
 * \brief Check if time is valid (e.g. 10:61:61 is invalid)
 *
 * \param[in] hour real34_t*
 * \param[in] minute real34_t*
 * \param[in] second real34_t*
 * \return bool_t true if valid
 ***********************************************/
bool_t isValidTime(const real34_t *hour, const real34_t *minute, const real34_t *second) {
  real34_t val;

  // second
  real34ToIntegralValue(second, &val, DEC_ROUND_FLOOR), real34Subtract(second, &val, &val);
  if(!real34IsZero(&val)) {
    return false;
  }

  int32ToReal34(0, &val), real34Compare(second, &val, &val);
  if(real34ToInt32(&val) < 0) {
    return false;
  }

  int32ToReal34(59, &val), real34Compare(second, &val, &val);
  if(real34ToInt32(&val) > 0) {
    return false;
  }

  // minute
  real34ToIntegralValue(minute, &val, DEC_ROUND_FLOOR), real34Subtract(minute, &val, &val);
  if(!real34IsZero(&val)) {
    return false;
  }

  int32ToReal34(0, &val), real34Compare(minute, &val, &val);
  if(real34ToInt32(&val) < 0) {
    return false;
  }

  int32ToReal34(59, &val), real34Compare(minute, &val, &val);
  if(real34ToInt32(&val) > 0) {
    return false;
  }

  // hour
  real34ToIntegralValue(hour, &val, DEC_ROUND_FLOOR), real34Subtract(hour, &val, &val);
  if(!real34IsZero(&val)) {
    return false;
  }

  int32ToReal34(0, &val), real34Compare(hour, &val, &val);
  if(real34ToInt32(&val) < 0) {
    return false;
  }

  int32ToReal34(23, &val), real34Compare(hour, &val, &val);
  if(real34ToInt32(&val) > 0) {
    return false;
  }

  // Valid time
  return true;
}


TO_QSPI const calcRegister_t toTimeParamReg[3] = {REGISTER_Z, REGISTER_Y, REGISTER_X};
void fnToTime(uint16_t unusedButMandatoryParameter) {
  real34_t hr, m, s;
  real34_t *part[3];
  uint_fast8_t i;

  if(!saveLastX()) {
    return;
  }

  part[0] = &hr;
  part[1] = &m;
  part[2] = &s; //hrMs

  for(i=0; i<3; ++i) {
    switch(getRegisterDataType(toTimeParamReg[i])) {
      case dtLongInteger:
        convertLongIntegerRegisterToReal34(toTimeParamReg[i], part[i]);
        break;

      case dtReal34:
        if(getRegisterAngularMode(toTimeParamReg[i])) {
          real34ToIntegralValue(REGISTER_REAL34_DATA(toTimeParamReg[i]), part[i], DEC_ROUND_DOWN);
          break;
        }
        /* fallthrough */

      default:
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "data type %s cannot be converted to a time!", getRegisterDataTypeName(toTimeParamReg[i], false, false));
          moreInfoOnError("In function fnToTime:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
        return;
    }
  }

  // valid date
  fnDropY(NOPARAM);
  fnDropY(NOPARAM);

  real34Multiply(const34_3600, &hr, &hr); //hr is now seconds
  real34Multiply(const34_60, &m, &m); //m is now seconds
  real34Add(&hr, &m, &hr);
  real34Add(&hr, &s, &hr);

  reallocateRegister(REGISTER_X, dtTime, 0, amNone);
  real34Copy(&hr, REGISTER_REAL34_DATA(REGISTER_X));
}



// ** ITFRAC *****************************************************************************
// ** IRFRAC parameters: input minimum: 1E-16
// **                  : input maximum: 999 999 999 excluding the IR factor
// **                  : DMX maximum setting 32500
// **                  : Output numerator, excluding IR factor: 999 999 999
// **                  : internal max 1E9-1 after IR constant divided
// **                  : Accuracy 24 digits; 
// **                  : Internally uses 12 digits in denom seeker for integer conversions
// **                  : Internally uses 26 digits for denom seeker real
// **                  : Internally uses 26 digits for fraction comparison, 
// ** ************************************************************************************
// **
// ** 24 digits guaranteed. 24+2 used, as this has proven to need only 24+1
// ** decNumber number of digits needed for IRFRAC
// ** optimised and verified for the input range offered
#define K_ctxtReal_denominator_finder                           26  //Continuous fraction representation
#define K_ctxtReal_integer_conversion_find_lowest_err_fraction  12  //Determine correct fraction to use from continuous fraction expansion matrix
#define K_ctxtReal_irrational_detection                         26  //This is used for multiple of input constant too large, as well as for irrational tolerance, relative.
#define K_ctxtReal_find_multiple_of_irr                         26  //This is used to determine the whole multiple.

int32_t getSmallestDenom(const real_t *val) { // ignore numerator determined, as this needs to be re-calculated in the main algo
  /*
  ** Adapted from:
  ** https://www.ics.uci.edu/~eppstein/numth/frap.c
  **
  ** find rational approximation to given real number
  ** David Eppstein / UC Irvine / 8 Aug 1993
  ** With corrections from Arno Formella, May 2008
  **
  ** based on the theory of continued fractions
  ** if x = a1 + 1/(a2 + 1/(a3 + 1/(a4 + ...)))
  ** then best approximation is found by truncating this series
  ** (with some adjustments in the last term).
  **
  ** Note the fraction can be recovered as the first column of the matrix
  **  ( a1 1 ) ( a2 1 ) ( a3 1 ) ...
  **  ( 1  0 ) ( 1  0 ) ( 1  0 )
  ** Instead of keeping the sequence of continued fraction terms,
  ** we just keep the last partial product of these matrices.
  */

  realContext_t ctxtReal_denom_finder = ctxtReal39;
  ctxtReal_denom_finder.digits = K_ctxtReal_denominator_finder;
  real_t xx, temp;
  realCopy(val, &xx);

  int32_t m[2][2];
  m[0][0] = 1;

  int32_t maxden, ai, dd;
  if(denMax == 0 || denMax > MAX_DENMAX) {
    maxden = MAX_INTERNAL_DENMAX;
  } else {
    maxden = denMax;
  }
  int32ToReal(maxden,&temp);
  realDivide(const_1on4,&temp,&temp,&ctxtReal_denom_finder);
  if(realCompareLessThan(&xx,&temp)) {
    //printf("Lower than 0.25/DMX, quitting before fraction loop.\n");  // Any value lower than 0.5/DMX will be deemed 0. Make the threshold 1/2 of 0.5/DMX
    dd = 1;
    goto nothingTodo;
  }


  /* initialize matrix */
  m[0][0] = m[1][1] = 1;
  m[0][1] = m[1][0] = 0;

  /* loop finding terms until denom gets too big */
  while(m[1][0] *  ( ai = realToInt32C47(&xx) ) + m[1][1] <= maxden) {
    //printf("  ai = %12i  condition:%8i<%6i ",ai, m[1][0] * ai + m[1][1], maxden ); printf("  m00=%8i m11=%8i m01=%8i m10=%8i   ", m[0][0], m[1][1], m[0][1], m[1][0]); printRealToConsole(&xx,"  xx="," + m[1][1] \n");
    int32_t t;
    t = m[0][0] * ai + m[0][1];
    m[0][1] = m[0][0];
    m[0][0] = t;
    t = m[1][0] * ai + m[1][1];
    m[1][1] = m[1][0];
    m[1][0] = t;

    int32ToReal(ai,&temp);
    realSubtract(&xx,&temp,&xx,&ctxtReal_denom_finder);
    //printf("                                               "); printf("  m00=%8i m11=%8i m01=%8i m10=%8i   ", m[0][0], m[1][1], m[0][1], m[1][0]); printRealToConsole(&xx,"  xx="," + m[1][1] \n");
    if(realIsZero(&xx) || realCompareAbsLessThan(&xx, const_1e_24)) {
      break;  // AF: division by zero
    }
    realDivide(const_1,&xx,&xx,&ctxtReal_denom_finder);
    if(realCompareGreaterThan(&xx,const_10p9__1)) {         // let 1/xx ceiling to const_10p9__1
      realCopy(const_10p9__1,&xx);
    }
    if(realIsSpecial(&xx)) {
      #if defined(PC_BUILD)
        errorf("Representation failure. Quitting fraction loop.");
        printRealToConsole(&xx,"xx:","\n");
        fflush(stderr);
      #endif //PC_BUILD
      dd = 1;
      goto nothingTodo;
    }
  }

  //Pick the correct num/denom from the matrix
  realContext_t ctxtReal_integer_conversion_find_lowest_err_fraction = ctxtReal39;
  ctxtReal_integer_conversion_find_lowest_err_fraction.digits = K_ctxtReal_integer_conversion_find_lowest_err_fraction;
  real_t num1, den1, num2, den2;
  real_t frac1, frac2;
  real_t err1, err2;
  // Convert int32_t integers to reals
  int32ToReal(m[0][0], &num1);
  int32ToReal(m[1][0], &den1);
  int32ToReal(m[0][1], &num2);
  int32ToReal(m[1][1], &den2);
  //decNumberFromInt32(&num1, m[0][0]);
  //decNumberFromInt32(&den1, m[1][0]);
  //decNumberFromInt32(&num2, m[0][1]);
  //decNumberFromInt32(&den2, m[1][1]);

  // Compute fractions num/den: frac = num / den
  realDivide(&num1, &den1, &frac1, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  realDivide(&num2, &den2, &frac2, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  // Compute errors: err = |value - fraction|
  realSubtract(val, &frac1, &err1, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  realCopyAbs(&err1, &err1);
  realSubtract(val, &frac2, &err2, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  realCopyAbs(&err2, &err2);
  real_t cmpResult;           // to store comparison result
  // Compare errors: if err2 < err1, update m accordingly
  realCompare(&err2, &err1, &cmpResult, &ctxtReal_integer_conversion_find_lowest_err_fraction);
  // cmpResult will hold -1 if err2 < err1, 0 if equal, 1 if err2 > err1
  // Check if err2 < err1 and swap output if needed
  // printRealToConsole(&err1,"\nerr1: "," "); printf("%d/%d      ",m[0][0],m[1][0]);
  // printRealToConsole(&err2,  "err2: "," "); printf("%d/%d\n",    m[0][1],m[1][1]);
  if (realIsNegative(&cmpResult)) {
      m[0][0] = m[0][1];
      m[1][0] = m[1][1];
  }
  //ignore numerator for the IRFRAC application - that is re-done later, report the denominator
  dd = m[1][0];
  // printf("----> Selected %d\n",dd);
  if(dd == 0) {
    dd = 1;
  }
nothingTodo:
  //printf(">>> %i / %i \n",  m[0][0], dd);
  return dd;
}

//** Helper to help create and format output string
void changeToSup(uint64_t numer, char *str) {  //numerator
  int16_t  endingZero = 0;
  str[0]=0;
  _numerator(numer, str, &endingZero);

}

//** Helper to help create and format output string
void changeToSub(uint64_t denom, char *str) {  //denominator
  int16_t  endingZero = 1;
  str[0]='/';
  str[1]=0;
  _denominator(denom, str, &endingZero);
}

//** Helper to help create and format output string
void changeToWholeString(int32_t intt, char *str, char *str1) {
  str[0]=0;
  longInteger_t lgInt;
  longIntegerInit(lgInt);
  int32ToLongInteger(intt, lgInt);
  longIntegerToDisplayString(lgInt, str, 30, SCREEN_WIDTH, 20, true);
  strcat(str,str1);
  longIntegerFree(lgInt);
}


//** Main IRFRAC search and conversion function
bool_t checkForAndChange(char *displayString, const real_t *valueReal, const real_t *valueRealAbs, const real_t *constant, const real_t *findingIrrationalTolerance, const char *constantStr,  bool_t frontSpace, bool_t complexMixedNumbers) {
    #define DISALLOW_MIXED_NUMBER_CONSTANTS true // Dont allow 1 e + e/3, rather write 1 1/3 e
    #define DISALLOW_MIXED_NUMBER_COMPLEX   false  // Dont allow 1 2/3 and 1e+2e/3, rather use 5/3 and 5e/3
    realContext_t ctxtReal_irrational_detection = ctxtReal39;
    ctxtReal_irrational_detection.digits = K_ctxtReal_irrational_detection;
    realContext_t ctxtReal_find_multiple_of_irr = ctxtReal39;
    ctxtReal_find_multiple_of_irr.digits = K_ctxtReal_find_multiple_of_irr;

    char cStr[16];
    bool_t useMixedNumbers = getSystemFlag(FLAG_PROPFR) && (DISALLOW_MIXED_NUMBER_COMPLEX ? !complexMixedNumbers : true);
    //printf(">>>## useMixedNumbers %u\n",useMixedNumbers);
    real_t smallestDenomR, newConstant, multipleOfNewConstant, multipleOfNewConstant_ip, multipleOfNewConstant_fp, multConstant;

    char denomStr[20], wholePart[30], resultingIntStr[100], tmpstr[50];
    tmpstr[0]=0;
    denomStr[0] = 0;
    wholePart[0] = 0;
    resultingIntStr[0] = 0;
    int32_t multipleOfNewConstantInteger = 0;
    char sign[2];

    if(realIsPositive(valueReal)) {
      strcpy(sign, "+");
    }
    else {
      strcpy(sign, "-");
    }

    //Returning: Real is too small
    if(realCompareLessThan(valueRealAbs, const_1e_16)) {
      return false;
    }
    //Returning: Multiple of constant is too large
    realDivide(valueRealAbs,constant,&multConstant,&ctxtReal_irrational_detection);                                               //TRYOUT 12 instead of 27
    if(realCompareGreaterThan(&multConstant, const_10p9__1)) {   //reduce whole multiple range to 34-24 = 10 digits. Use 10p9__1 = 999 999 999. (was const_2p31__1 = 2 147 483 647)
      return false;
    }


    //See if the multiplier to the constant has a whole denominator

#define IRFRAC_ENGINE
#ifndef IRFRAC_ENGINE
    //* This section uses the standard fraction() to calculate the denominator
    int16_t sign1, lessEqualGreater;
    uint64_t intPart, numer, denom;
    reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
    realToReal34(&multConstant,REGISTER_REAL34_DATA(TEMP_REGISTER_1));
    fraction(TEMP_REGISTER_1, &sign1, &intPart, &numer, &denom, &lessEqualGreater);   //does not yet work in all the frac modes.
    //printf("aaaaaaa: %i%llu + %llu / %llu \n",sign1,intPart,numer,denom);
    int32_t smallestDenom = denom;
#endif //FRACT_ENGINE
#ifdef IRFRAC_ENGINE
    //* This section uses the new special demoninator search engine
    int32_t smallestDenom = getSmallestDenom(&multConstant);                                                    //denominator
#endif //IRFRAC_ENGINE


    //Create a new constant comprising the constant divided by the whole denominator
    int32ToReal(smallestDenom, &smallestDenomR);
    realDivide(constant, &smallestDenomR, &newConstant, &ctxtReal39);

    //See if there is a whole multiple of the new constant
    realDivide(valueRealAbs, &newConstant, &multipleOfNewConstant, &ctxtReal_find_multiple_of_irr);
    realToIntegralValue(&multipleOfNewConstant, &multipleOfNewConstant_ip, DEC_ROUND_HALF_UP, &ctxtReal_find_multiple_of_irr);
    realSubtract(&multipleOfNewConstant, &multipleOfNewConstant_ip, &multipleOfNewConstant_fp, &ctxtReal_find_multiple_of_irr);
    multipleOfNewConstantInteger = abs(realToInt32C47(&multipleOfNewConstant_ip));                              //numerator

    //See if the ip is out of range (use the Real check not the integer check to protect agains > 32 bit integer max)
    if(realCompareAbsGreaterThan(&multipleOfNewConstant_ip, const_10p9__1)) {   //reduce whole multiple range to 34-24 = 10 digits. Use 10p9__1 = 999 999 999. (was const_2p31__1 = 2 147 483 647)
      return false;
    }

  real_t findingIrrationalTolerance1;
  realMultiply(findingIrrationalTolerance, &smallestDenomR, &findingIrrationalTolerance1, &ctxtReal_irrational_detection);         // do relative convergence // MUST TRY 12. SEEMS TO WORK ON 12



// DEBUG CODE
//                                printRealToConsole(constant,"\n\nconstant=","\n");
//                                printRealToConsole(valueReal,"valueReal=","\n");
//                                printRealToConsole(&multConstant,"multConstant=","\n");
//                                printf("smallestDenom:%i\n",smallestDenom);
//                                printRealToConsole(&newConstant,"newConstant=","\n");
//                                printRealToConsole(&multipleOfNewConstant,"multipleOfNewConstant=","\n");
//                                printRealToConsole(&multipleOfNewConstant_ip,"multipleOfNewConstant_ip=","\n");
//                                printRealToConsole(&multipleOfNewConstant_fp,"multipleOfNewConstant_fp=","\n");

//                                printf(">>>multipleOfNewConstantInteger:%i>1? SmallestDenom:%i\n", multipleOfNewConstantInteger, smallestDenom);
//                                printf(" Numer=%i Denom:%i\n---\n", multipleOfNewConstantInteger, smallestDenom);
//                                printRealToConsole(&multipleOfNewConstant_fp,"fp:","--\n");
//                                printRealToConsole(findingIrrationalTolerance,"tol:","--\n");
//                                printf("realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance):%i\n",realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance));
//                                printf(">>> %i ", multipleOfNewConstantInteger);
//                                printf("QQ:%s§\n",displayString);
//                                char teststr[1000];
//                                char teststr1[1000];
//                                sprintf(teststr,">>>@@@1 |%s|%s|%s| %i %i\n", resultingIntStr, constantStr, denomStr, (int16_t)stringByteLength(resultingIntStr)-1, resultingIntStr[stringByteLength(resultingIntStr)-1]);
//                                stringToASCII(teststr,teststr1);
//                                printf("%s\n",teststr1);
//                                printf(">>>multipleOfNewConstantInteger:%i>=1? realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance):%i\n", multipleOfNewConstantInteger, realCompareAbsLessThan(&multipleOfNewConstant_fp,findingIrrationalTolerance));


    if((DISALLOW_MIXED_NUMBER_CONSTANTS && constantStr[0]!=0 && multipleOfNewConstantInteger > smallestDenom) && useMixedNumbers && smallestDenom != 1) {   //remove this last "&& useMixedNumbers" to change to "3/4 e" instead of "3e/4"
      cStr[0] = 0;
    }
    else {
      strcpy(cStr,constantStr);
    }


// DEBUG CODE
//                                printRealToConsole(valueReal,"\n\nInputvalue: valueReal=","\n");
//                                printRealToConsole(constant,"    constant=","\n");
//                                printf("    §%s§   §%s§   §%s§\n", resultingIntStr, constantStr, denomStr);
//                                printRealToConsole(&findingIrrationalTolerance1,"findingIrrationalTolerance1=","\n");
//                                char displayString2[200];
//                                stringToASCII(constantStr,displayString2);
//                                printf("constantStr:%s\n",displayString2);
//                                printf("Numerator: multipleOfNewConstantInteger   %i\n",multipleOfNewConstantInteger);
//                                printf("Denominator: smallestDenom                         /            %i\n",smallestDenom);
//                                printRealToConsole(&multipleOfNewConstant_fp,"&multipleOfNewConstant_fp=","\n");
//                                char displayString1[200];
//                                stringToASCII(resultingIntStr,displayString1); printf("BBB1 ---> %s %u %u %u %u %u %u %u %u\n",displayString1,(uint8_t)(displayString[0]),(uint8_t)(displayString[1]),(uint8_t)(displayString[2]),(uint8_t)(displayString[3]),(uint8_t)(displayString[4]),(uint8_t)(displayString[5]),(uint8_t)(displayString[6]),(uint8_t)(displayString[7]));

    if(multipleOfNewConstantInteger >= 1 && realCompareAbsLessThan(&multipleOfNewConstant_fp,&findingIrrationalTolerance1)) {

// DEBUG CODE
//                                printf("A whole multiple %i of the 'new' constant exists\n", multipleOfNewConstantInteger);
//                                printf("  useMixedNumbers = %u\n", useMixedNumbers);

      if(multipleOfNewConstantInteger > smallestDenom  &&  smallestDenom > 1  && multipleOfNewConstantInteger != 0 && useMixedNumbers && smallestDenom != 1) {   // Numer > Denom;
        int32_t wholeInteger = multipleOfNewConstantInteger / smallestDenom;
        multipleOfNewConstantInteger = multipleOfNewConstantInteger - (wholeInteger * smallestDenom);

// DEBUG CODE
//                                printf("B  wholeInteger %i, multipleOfNewConstantInteger %i of the 'new' constant exists\n", wholeInteger, multipleOfNewConstantInteger);
        char useMixedNumbersSep[3];
        if(cStr[0]==0) {                                                                                          // no constant
          useMixedNumbersSep[0] = STD_SPACE_4_PER_EM[0];
          useMixedNumbersSep[1] = STD_SPACE_4_PER_EM[1];
          useMixedNumbersSep[2] = 0;
          changeToWholeString(wholeInteger,wholePart,useMixedNumbersSep);
          strcat(wholePart,useMixedNumbersSep);                                                                   // "1 "
        }
        else {                                                                                                    // constant with numbers
          useMixedNumbersSep[0] = sign[0];
          useMixedNumbersSep[1] = sign[1];
          useMixedNumbersSep[2] = 0;
          if(wholeInteger == 1) {
            sprintf(wholePart, "%s%s", cStr, useMixedNumbersSep);                                                 // "e+"
          }
          else {
            changeToWholeString(wholeInteger,wholePart,PRODUCT_SIGN);
            strcat(wholePart,cStr);
            strcat(wholePart,useMixedNumbersSep);                                                                 // "2xe+"
          }
        }
      }

      if(cStr[0] == 0) {                                                                                          // no constant
        if(smallestDenom > 1) {
          changeToSup(multipleOfNewConstantInteger, tmpstr);                                                      // numerator
        }
        else {
          return false;
          //return false, to abort and use standard decimal instead of "1."
          //sprintf(tmpstr,"%i",(int)multipleOfNewConstantInteger);                                                 //==1
          //strcat(tmpstr,RADIX34_MARK_STRING);
        }
        sprintf(resultingIntStr, "%s%s", wholePart, tmpstr);                                                        // "1 1"
      }
      else {                                                                                                      // constant
        if(multipleOfNewConstantInteger == 1) {
          sprintf(resultingIntStr,"%s", wholePart);                                                                 // "e+" or "2xe+"
        }
        else {
          sprintf(tmpstr,"%i%s",(int)multipleOfNewConstantInteger,PRODUCT_SIGN);
          sprintf(resultingIntStr, "%s%s", wholePart, tmpstr);                                                      // "e+1" or "2xe+1"
        }
      }
    } else {                                                                                  // A whole multiple %i of the 'new' constant does not exist
        if(smallestDenom == 1) {
          return false;   //unlikely
          //return false, to abort and use standard decimal instead of "1."
          //sprintf(resultingIntStr,"%i", (int)multipleOfNewConstantInteger);                                       // if denom = 1, then use large font
        }
        else {
          changeToSup(multipleOfNewConstantInteger, resultingIntStr);                                             // if denom <> 0, then use superscript, knowing there is a denom
        }

    }

// DEBUG CODE
//                                printf("QQ1 %s\n",wholePart);       printf("BBB1 ---> %u %u %u %u %u %u %u %u\n",(uint8_t)(wholePart[0]),(uint8_t)(wholePart[1]),(uint8_t)(wholePart[2]),(uint8_t)(wholePart[3]),(uint8_t)(wholePart[4]),(uint8_t)(wholePart[5]),(uint8_t)(wholePart[6]),(uint8_t)(wholePart[7]));
//                                printf("  2 %s\n",tmpstr);          printf("BBB2 ---> %u %u %u %u %u %u %u %u\n",(uint8_t)(tmpstr[0]),(uint8_t)(tmpstr[1]),(uint8_t)(tmpstr[2]),(uint8_t)(tmpstr[3]),(uint8_t)(tmpstr[4]),(uint8_t)(tmpstr[5]),(uint8_t)(tmpstr[6]),(uint8_t)(tmpstr[7]));
//                                printf("  3 %s\n",resultingIntStr); printf("BBB3 ---> %u %u %u %u %u %u %u %u\n",(uint8_t)(resultingIntStr[0]),(uint8_t)(resultingIntStr[1]),(uint8_t)(resultingIntStr[2]),(uint8_t)(resultingIntStr[3]),(uint8_t)(resultingIntStr[4]),(uint8_t)(resultingIntStr[5]),(uint8_t)(resultingIntStr[6]),(uint8_t)(resultingIntStr[7]));
//                                char teststr[1000];
//                                sprintf(teststr,">>>@@@2 |%s|%s|%s| %i %i\n", resultingIntStr, constantStr, denomStr, (int16_t)stringByteLength(resultingIntStr)-1, resultingIntStr[stringByteLength(resultingIntStr)-1]);
//                                char teststr2[1000];
//                                stringToASCII(teststr,teststr2);
//                                printf("%s\n",teststr2);

    if(smallestDenom > 1) {
      changeToSub(smallestDenom, denomStr);                                                                     // "/12"
    }

    if((resultingIntStr[stringByteLength(resultingIntStr)-1]==' ' || resultingIntStr[max(0,stringByteLength(resultingIntStr)-1)]==0) &&  denomStr[0]=='/' && cStr[0]==0) {
      sprintf(tmpstr, STD_SUP_1 "%s", denomStr);
      strcpy(denomStr, tmpstr);
    }

  real_t roundingTolerance1;
  irfractionTolerence(smallestDenom * 6 + 1, &roundingTolerance1);                                              // relative convergence, add (6x+1) i.e about 0.43 digits + 1 for safety margin)

// DEBUG CODE
//                               printRealToConsole(&multipleOfNewConstant_fp,"&multipleOfNewConstant_fp=","\n");
//                               printRealToConsole(&roundingTolerance1,"roundingTolerance1=","\n");
//                               printRealToConsole(&findingIrrationalTolerance1,"findingIrrationalTolerance1=","\n");

    displayString[0] = 0;
    if(!realCompareAbsGreaterThan(&multipleOfNewConstant_fp,&findingIrrationalTolerance1)) {                                     // irrational tolerance found, show irrational and fraction
      if(!realCompareAbsLessThan(&multipleOfNewConstant_fp,&roundingTolerance1) ){                                               // prepend the tags; FDIGS=34 is normal, i.e. no lying, meaning opening up the tolerance band for zero
        strcat(displayString, STD_ALMOST_EQUAL);
      }

      if(sign[0]=='+') {
        if(frontSpace) {
          strcat(displayString, STD_SPACE_4_PER_EM);  //changed, not allowing for a space equal length to "-"
          if(resultingIntStr[0] !=0 ) {
            strcat(displayString, resultingIntStr);
          }
          strcat(displayString,cStr);
          strcat(displayString,denomStr);                              // " 2xe+" "e" "/3"
        }
        else {
          if(resultingIntStr[0] != 0) {
            strcat(displayString, resultingIntStr);
          }
          strcat(displayString,cStr);
          strcat(displayString,denomStr);                              // "2xe+" "e" "/3"
        }
      }
      else { // "-"
        strcat(displayString, STD_SPACE_4_PER_EM "-");
        if(resultingIntStr[0] !=0 ) {
          strcat(displayString, resultingIntStr);
        }
        strcat(displayString,cStr);
        strcat(displayString,denomStr);                                // "-2xe+" "e" "/3"
      }

      if(cStr[0] == 0 && constantStr[0] !=0) {                         // "-2/3" "e"
        strcat(displayString,STD_SPACE_4_PER_EM);
        strcat(displayString,PRODUCT_SIGN);
        strcat(displayString,STD_SPACE_4_PER_EM);
        strcat(displayString,constantStr);
      }

      return true;             //successful IRFRAC conversion, displaying as fraction
    }
    else {
      return false;            //unsuccessful IRFRAC conversion, displaying as decimal
    }
  }


void fnConstantR(uint16_t constantAddr, uint16_t *constNr, real_t *rVal) {
  uint16_t constant =constantAddr;
  *constNr = constant;
  //printf(">>> %u\n",constant);
  if(constant < NUMBER_OF_CONSTANTS_39) { // 39 digit constants
    realCopy((real_t *)(constants + constant * REAL39_SIZE_IN_BYTES), rVal);
  }
  else if(constant < NUMBER_OF_CONSTANTS_39 + NUMBER_OF_CONSTANTS_51) { // 51 digit constants (gamma coefficients)
    realCopy((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * REAL39_SIZE_IN_BYTES + (constant - NUMBER_OF_CONSTANTS_39) * REAL51_SIZE_IN_BYTES), rVal);
  }
  else if(constant < NUMBER_OF_CONSTANTS_39 + NUMBER_OF_CONSTANTS_51 + NUMBER_OF_CONSTANTS_1071) { // 1071 digit constant
    realCopy((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * REAL39_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_51 * REAL51_SIZE_IN_BYTES + (constant - NUMBER_OF_CONSTANTS_39 - NUMBER_OF_CONSTANTS_51) * REAL1071_SIZE_IN_BYTES), rVal);
  }
  else if(constant < NUMBER_OF_CONSTANTS_39 + NUMBER_OF_CONSTANTS_51 + NUMBER_OF_CONSTANTS_1071 + NUMBER_OF_CONSTANTS_2139) { // 2139 digit constant
    realCopy((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * REAL39_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_51 * REAL51_SIZE_IN_BYTES + (constant - NUMBER_OF_CONSTANTS_39 - NUMBER_OF_CONSTANTS_51) * REAL1071_SIZE_IN_BYTES), rVal);
  }
  else { // 34 digit constants
    real34ToReal((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * REAL39_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_51 * REAL51_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_1071 * REAL1071_SIZE_IN_BYTES + (constant - NUMBER_OF_CONSTANTS_39 - NUMBER_OF_CONSTANTS_51 - NUMBER_OF_CONSTANTS_1071) * REAL34_SIZE_IN_BYTES), rVal);
    real34ToReal((real_t *)(constants + NUMBER_OF_CONSTANTS_39 * REAL39_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_51 * REAL51_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_1071 * REAL1071_SIZE_IN_BYTES + NUMBER_OF_CONSTANTS_2139 * REAL2139_SIZE_IN_BYTES + (constant - NUMBER_OF_CONSTANTS_39 - NUMBER_OF_CONSTANTS_51 - NUMBER_OF_CONSTANTS_1071 - NUMBER_OF_CONSTANTS_2139) * REAL34_SIZE_IN_BYTES), rVal);
  }
}


void fnSafeReset (uint16_t unusedButMandatoryParameter) {
  if(!jm_G_DOUBLETAP && !ShiftTimoutMode && !HOME3 && !MYM3) {
    fgLN            = RBX_FGLNFUL;  //not in conditional clear
    jm_G_DOUBLETAP  = true;
    ShiftTimoutMode = true;
    HOME3           = true;
    MYM3            = false;
    BASE_HOME       = false;
    BASE_MYM        = true;
  }
  else {
    fgLN            = RBX_FGLNOFF;  //not in conditional clear
    jm_G_DOUBLETAP  = false;
    ShiftTimoutMode = false;
    HOME3           = false;
    MYM3            = false;
    BASE_HOME       = false;
    BASE_MYM        = true;
  }
}


#if !defined(TESTSUITE_BUILD)
  static void assignToMyMenu_(uint16_t position) {
    if(position < 18) {
      _assignItem(&userMenuItems[position]);
    }
    cachedDynamicMenu = 0;
  }


  static void assignToMyAlpha_(uint16_t position) {
    if(position < 18) {
      _assignItem(&userAlphaItems[position]);
    }
    cachedDynamicMenu = 0;
  }
#endif // !TESTSUITE_BUILD


void fnRESET_MyM(uint16_t param) {
  //Pre-assign the MyMenu                   //JM
  #if !defined(TESTSUITE_BUILD)
    BASE_MYM = false;                                                   //JM prevent slow updating of 6 menu items
    for(int8_t fn = 1; fn <= 6; fn++) {
      if(param == ITM_RIBBON_SAV) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_SYSTEM2; break;
          case 2: itemToBeAssigned = ITM_ACTUSB;  break;
          case 3: itemToBeAssigned = ITM_SAVE;    break;
          case 4: itemToBeAssigned = ITM_LOAD;    break;
          case 5: itemToBeAssigned = ITM_SAVEST;  break;
          case 6: itemToBeAssigned = ITM_LOADST;  break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_FIN) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_PC;      break;
          case 2: itemToBeAssigned = ITM_DELTAPC; break;
          case 3: itemToBeAssigned = ITM_YX;      break;
          case 4: itemToBeAssigned = ITM_SQUARE;  break;
          case 5: itemToBeAssigned = ITM_10x;     break;
          case 6: itemToBeAssigned = -MNU_FIN;    break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_CPX) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_DRG;      break;
          case 2: itemToBeAssigned = ITM_CC;       break;
          case 3: itemToBeAssigned = ITM_EE_EXP_TH;break;
          case 4: itemToBeAssigned = ITM_EXP;      break;
          case 5: itemToBeAssigned = ITM_op_j_pol; break;
          case 6: itemToBeAssigned = ITM_op_j;     break;
          default:break;
        }
      }

      //C47 et al
          else if(!isR47FAM && param == ITM_RIBBON_ENG) {
            switch(fn) {
              case 1: itemToBeAssigned = -MNU_CPX;     break;
              case 2: itemToBeAssigned = -MNU_MATX;    break;
              case 3: itemToBeAssigned = ITM_CONSTpi;  break;
              case 4: itemToBeAssigned = ITM_op_j;     break;
              case 5: itemToBeAssigned = ITM_EXP;      break;
              case 6: itemToBeAssigned = -MNU_TRG_C47; break;
              default:break;
            }
          }
      //R47
          else if(isR47FAM && param == ITM_RIBBON_ENG) {
            switch(fn) {
              case 1: itemToBeAssigned = ITM_op_j;     break;
              case 2: itemToBeAssigned = -MNU_CPX;     break;
              case 3: itemToBeAssigned = ITM_CONSTpi;  break;
              case 4: itemToBeAssigned = -MNU_MATX;    break;
              case 5: itemToBeAssigned = -MNU_TRG_R47; break;
              case 6: itemToBeAssigned = ITM_EXP;      break;
              default:break;
            }
          }
      //END CONDITIONAL

      else if(param == ITM_RIBBON_C47) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_DRG;      break;
          case 2: itemToBeAssigned = ITM_YX;       break;
          case 3: itemToBeAssigned = ITM_SQUARE;   break;
          case 4: itemToBeAssigned = ITM_10x;      break;
          case 5: itemToBeAssigned = ITM_EXP;      break;
          case 6: itemToBeAssigned = ITM_op_j;     break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_C47PL) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_DRG;      break;
          case 2: itemToBeAssigned = ITM_DSP;      break;
          case 3: itemToBeAssigned = ITM_DREAL;    break;
          case 4: itemToBeAssigned = ITM_FF;       break;
          case 5: itemToBeAssigned = ITM_Rup;      break;
          case 6: itemToBeAssigned = ITM_XFACT;    break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_R47) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_op_j;     break;
          case 2: itemToBeAssigned = ITM_op_j_pol; break;
          case 3: itemToBeAssigned = ITM_XFACT;    break;
          case 4: itemToBeAssigned = ITM_XTHROOT;  break;
          case 5: itemToBeAssigned = ITM_10x;      break;
          case 6: itemToBeAssigned = ITM_EXP;      break;
          default:break;
        }
      }
      else if(param == ITM_RIBBON_R47PL) {
        switch(fn) {
          case 1: itemToBeAssigned = ITM_TIMER;    break;
          case 2: itemToBeAssigned = ITM_DSP;      break;
          case 3: itemToBeAssigned = ITM_DREAL;    break;
          case 4: itemToBeAssigned = ITM_FF;       break;
          case 5: itemToBeAssigned = -MNU_LOOP;    break;
          case 6: itemToBeAssigned = -MNU_TEST;    break;
          default:break;
        }
      }
      else {
        itemToBeAssigned = ASSIGN_CLEAR;
      }

      if(itemToBeAssigned == -MNU_PFN) {
        strcpy(aimBuffer,"P.FN");
        assignGetName1();
      }
      else if(itemToBeAssigned == -MNU_HOME) {
        strcpy(aimBuffer,"HOME");
        assignGetName1();
      }

      assignToMyMenu_(fn - 1);
      if(param == 0) {
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyMenu_(6 + fn - 1);
        itemToBeAssigned = ASSIGN_CLEAR;
        assignToMyMenu_(12 + fn - 1);
      }
    }
    BASE_MYM = true;                                           //JM Menu system default (removed from reset_jm_defaults)
    refreshScreen(42);
  #endif // !TESTSUITE_BUILD
}


void fnRESET_Mya(void){
  //Pre-assign the MyAlpha Menu                   //JM
  #if !defined(TESTSUITE_BUILD)
    for(int8_t fn = 1; fn <= 6; fn++) {
      itemToBeAssigned = ASSIGN_CLEAR;
      assignToMyAlpha_(fn - 1);
      itemToBeAssigned = ASSIGN_CLEAR;
      assignToMyAlpha_(6 + fn - 1);
      itemToBeAssigned = ASSIGN_CLEAR;
      assignToMyAlpha_(12 + fn - 1);
    }
//    itemToBeAssigned = -MNU_ALPHA;
//    assignToMyAlpha_(5);
    refreshScreen(43);
  #endif // !TESTSUITE_BUILD
}


//Softmenus:
//--------------------------------------------------------------------------------------------
//JM To determine the menu number for a given menuId          //JMvv
int16_t mm(int16_t id) {
  int16_t m;
  m = 0;
  if(id != 0) { // Search by ID
    while(softmenu[m].menuItem != 0) {
      //printf(">>> mm %d %d %d %s \n",id, m, softmenu[m].menuItem, indexOfItems[-softmenu[m].menuItem].itemSoftmenuName);
      if(softmenu[m].menuItem == id) {
        //printf("####>> mm() broken out id=%i m=%i\n",id,m);
        break;
      }
      m++;
    }
  }
  return m;
}                                                             //JM^^

#if !defined(TESTSUITE_BUILD)
  //vv EXTRA DRAWINGS FOR RADIO_BUTTON AND CHECK_BOX
  #define JM_LINE2_DRAW
  #undef JM_LINE2_DRAW
  #if defined(JM_LINE2_DRAW)
    void JM_LINE2(uint32_t xx, uint32_t yy) {                          // To draw the lines for radiobutton on screen
      uint32_t x, y;
      y = yy-3-1;
      for(x=xx-66+1; x<min(xx-1,SCREEN_WIDTH); x++) {
        if(mod(x, 2) == 0) {
          setBlackPixel(x, y);
          setBlackPixel(x, y+2);
        }
        else {
          setBlackPixel(x, y+1);
        }
      }
    }
  #endif // JM_LINE2_DRAW


  #define RB_EXTRA_BORDER
  //#undef RB_EXTRA_BORDER
  #define RB_CLEAR_CENTER
  #undef RB_CLEAR_CENTER
  #if defined(RB_EXTRA_BORDER)
    void rbColumnCcccccc(uint32_t xx, uint32_t yy) {
      lcd_fill_rect(xx,yy+2,1,7,  0);
    }
  #endif // RB_EXTRA_BORDER


  void rbColumnCcSssssCc(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+8, 1, 2,  0);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+3, 1, 5,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+1, 1, 1,  0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCcSssssssCc(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+9, 1, 2,  0);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+2, 1, 7,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy, 1, 2,  0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCSssCccSssC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel (xx, yy+10);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+7, 1, 3,  0xFF);
    lcd_fill_rect(xx, yy+4, 1, 3,  0);
    lcd_fill_rect(xx, yy+1, 1, 3,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel (xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCSsCSssCSsC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+8, 1, 2,  0xFF);
    setWhitePixel(xx, yy+7);
    lcd_fill_rect(xx, yy+4, 1, 3,  0xFF);
    setWhitePixel(xx, yy+3);
    lcd_fill_rect(xx, yy+1, 1, 2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCcSsNnnSsCc(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+9, 1, 2,  0);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+7, 1, 2,  0xFF);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+4, 1, 3,  0);
    #endif // RB_CLEAR_CENTER

    lcd_fill_rect(xx, yy+2, 1, 2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy+0, 1, 2,  0);
    #endif // RB_EXTRA_BORDER
  }


  void rbColumnCSsNnnnnSsC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel (xx, yy+10);
    #endif //RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+8,1,2,  0xFF);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+3,1,5,  0);
    #endif //RB_CLEAR_CENTER

    lcd_fill_rect(xx, yy+1,1,2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif //RB_EXTRA_BORDERf
  }


  void rbColumnCSNnnnnnnSC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif //RB_EXTRA_BORDER

    setBlackPixel(xx, yy+9);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+2, 1, 7,  0);
    #endif //RB_CLEAR_CENTER

    setBlackPixel (xx, yy+1);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif //RB_EXTRA_BORDER
  }


  #if defined(RB_EXTRA_BORDER)
    void cbColumnCcccccccccc(uint32_t xx, uint32_t yy) {
      lcd_fill_rect(xx, yy+0, 1, 11,  0);
    }
  #endif // RB_EXTRA_BORDER


  void cbColumnCSssssssssC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif //RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+1, 1, 9,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx,yy+0);
    #endif //RB_EXTRA_BORDER
  }


  void cbColumnCSsCccccSsC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+10);
    #endif // RB_EXTRA_BORDER

    lcd_fill_rect(xx, yy+8, 1, 2,  0xFF);
    lcd_fill_rect(xx, yy+3, 1, 5,  0);
    lcd_fill_rect(xx, yy+1, 1, 2,  0xFF);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void cbColumnCSNnnnnnnSC(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx,yy+10);
    #endif // RB_EXTRA_BORDER

    setBlackPixel(xx, yy+9);

    #if defined(RB_CLEAR_CENTER)
      lcd_fill_rect(xx, yy+2, 1, 7,  0);
    #endif // RB_CLEAR_CENTER

    setBlackPixel(xx, yy+1);

    #if defined(RB_EXTRA_BORDER)
      setWhitePixel(xx, yy+0);
    #endif // RB_EXTRA_BORDER
  }


  void RB_CHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      rbColumnCcccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    rbColumnCcSssssCc(xx+1, yy);
    rbColumnCcSssssssCc(xx+2, yy);
    rbColumnCSssCccSssC(xx+3, yy);
    rbColumnCSsCSssCSsC(xx+4, yy);
    rbColumnCSsCSssCSsC(xx+5, yy);
    rbColumnCSsCSssCSsC(xx+6, yy);
    rbColumnCSssCccSssC(xx+7, yy);
    rbColumnCcSssssssCc(xx+8, yy);
    rbColumnCcSssssCc(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  rbColumnCcccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }


  void RB_UNCHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      rbColumnCcccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    rbColumnCcSssssCc(xx+1, yy);
    rbColumnCcSsNnnSsCc(xx+2, yy);
    rbColumnCSsNnnnnSsC(xx+3, yy);
    rbColumnCSNnnnnnnSC(xx+4, yy);
    rbColumnCSNnnnnnnSC(xx+5, yy);
    rbColumnCSNnnnnnnSC(xx+6, yy);
    rbColumnCSsNnnnnSsC(xx+7, yy);
    rbColumnCcSsNnnSsCc(xx+8, yy);
    rbColumnCcSssssCc(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  rbColumnCcccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }


  void CB_CHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy-1, 10, 11, 0);
      cbColumnCcccccccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    cbColumnCSssssssssC(xx+1, yy);
    cbColumnCSssssssssC(xx+2, yy);
    cbColumnCSsCccccSsC(xx+3, yy);
    rbColumnCSsCSssCSsC(xx+4, yy);
    rbColumnCSsCSssCSsC(xx+5, yy);
    rbColumnCSsCSssCSsC(xx+6, yy);
    cbColumnCSsCccccSsC(xx+7, yy);
    cbColumnCSssssssssC(xx+8, yy);
    cbColumnCSssssssssC(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  cbColumnCcccccccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }


  void CB_UNCHECKED(uint32_t xx, uint32_t yy) {
    #if defined(RB_EXTRA_BORDER)
      lcd_fill_rect(xx, yy-1, 10, 11, 0);
      cbColumnCcccccccccc(xx+0, yy);
    #endif // RB_EXTRA_BORDER
    cbColumnCSssssssssC(xx+1, yy);
    cbColumnCSNnnnnnnSC(xx+2, yy);
    cbColumnCSNnnnnnnSC(xx+3, yy);
    cbColumnCSNnnnnnnSC(xx+4, yy);
    cbColumnCSNnnnnnnSC(xx+5, yy);
    cbColumnCSNnnnnnnSC(xx+6, yy);
    cbColumnCSNnnnnnnSC(xx+7, yy);
    cbColumnCSNnnnnnnSC(xx+8, yy);
    cbColumnCSssssssssC(xx+9, yy);
    //#if defined(RB_EXTRA_BORDER)
    //  cbColumnCcccccccccc(xx+10, yy);
    //#endif // RB_EXTRA_BORDER
  }
  //^^
#endif // !TESTSUITE_BUILD


void fnSetBCD (uint16_t bcd) {
  switch(bcd) {
    case BCD9c:
    case BCD10c:
    case BCDu:
      bcdDisplaySign = bcd;
      break;
    default: ;
  }
}


void setFGLSettings(uint16_t option) {
  switch(option) {
    case RBX_FGLNOFF:
    case RBX_FGLNLIM:
    case RBX_FGLNFUL:
      fgLN = (uint8_t)option;
      break;
    default:
      fgLN = RBX_FGLNFUL;
  }
}


void fnLongPressSwitches (uint16_t option) {
  switch(option) {
    case RBX_F14:
    case RBX_F124:
    case RBX_F1234:
      LongPressF = option;
      break;
    case RBX_M14   :
    case RBX_M124  :
    case RBX_M1234 :
      LongPressM = option;
      break;
    default:
      LongPressM = RBX_M1234;
      LongPressF = RBX_F124;
  }
}


