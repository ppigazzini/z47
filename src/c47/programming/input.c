// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


/********************************************//**
 * \file input.c
 ***********************************************/

#include "c47.h"

void fnInput(uint16_t regist) {
  if(programRunStop == PGM_RUNNING) {
    programRunStop = PGM_WAITING;
    currentInputVariable = regist;
    fnRecall(regist);
    refreshScreen(10);
    #if defined(DMCP_BUILD)
      lcd_refresh();
    #else // !DMCP_BUILD
      refreshLcd(NULL);
    #endif // DMCP_BUILD
  }
}



void fnVarMnu(uint16_t label) {
  #if !defined(TESTSUITE_BUILD)
    currentMvarLabel = label;
    showSoftmenu(-MNU_MVAR);
  #endif // !TESTSUITE_BUILD
}


#if defined(PC_BUILD)
  int32_t gTime = 0;
  bool_t  gRemoveTimer = false;
  guint   gTimerId = 0;
  static gboolean gTimer(gpointer user_data) {
    gTime++;
    if(gRemoveTimer) {
      return FALSE;
    }
    else {
      return TRUE;
    }
  }
#endif //PC_BUILD



#define keySleep           true
#define reFreshAfterSleep  true
#if defined (DMCP_BUILD)
// sleepTime = 0 : do not time out, sleep only. Until a key is pressed.
// sleepTime = 1 : return without sleep, without timer, with no delay.
// sleepTime > 1 : means number of ms sleeping. Or until a key is pressed.
void goToSleepForMs(uint32_t sleepTime, bool_t refreshScr) {
  if(sleepTime == 1) return;
  if(sleepTime > 1) {
    sys_timer_start(TIMER_IDX_REFRESH_SLEEP, sleepTime);
  }
  CLR_ST(STAT_RUNNING);
  SET_ST(STAT_SUSPENDED);
  do {
    sys_sleep();
  } while(!ST(STAT_PGM_END) && key_empty() && emptyKeyBuffer() && !ST(STAT_CLK_WKUP_FLAG));
  CLR_ST(STAT_CLK_WKUP_FLAG);
  CLR_ST(STAT_SUSPENDED);
  SET_ST(STAT_RUNNING);
  if(sleepTime > 1) {
    sys_timer_disable(TIMER_IDX_REFRESH_SLEEP);
  }
}
#endif //DMCP_BUILD


void fnPause(uint16_t dur) {
  int32_t duration = dur;
    if(duration == 99) {      //99 signifies infinity, which is 2 hours on battery, and (2^31-1)/10 seconds = 59652 hours on USB. Note that this is determined at the start of pause, not changing during timing
      if(!runningOnSimOrUSB) {
        duration = 2*60*60*10; //2 hours
      }
      else {
        duration = 0x7FFFFFFF; //maximum counter value of 59652 hours
      }
    }

  #if !defined(TESTSUITE_BUILD)
    uint8_t previousProgramRunStop = programRunStop;
    programRunStop = PGM_PAUSED;


    if(previousProgramRunStop != PGM_RUNNING) {
      leaveTamModeIfEnabled();
    }

    #if defined(DMCP_BUILD)
      if(dur == 99) {
            uint32_t targetMs = sys_current_ms() + (uint32_t)duration * 10;
            wait_for_key_release(0);
            key_pop();
        for(; programRunStop == PGM_PAUSED || programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED;) {
          // char aaa[111];sprintf(aaa,"###2 now=%lu tgt=%lu", sys_current_ms(), targetMs); print_linestr(aaa, false);
          int key = key_pop();
          key = convertKeyCode(key);
          if(key > 0) {
            //char aaa[111];sprintf(aaa,"###3 key=%d", key); print_linestr(aaa, false);
            if(key == 28 || key == 11) { //f key on C47 and R47. These keys will not work to continue the 'press any key!'
              continue;
            } else
            if(key == 44) { //DISP for special SCREEN DUMP key code. To be 16 but shift decoding already done to 44 in DMCP
              standardScreenDump();
              wait_for_key_release(0);
              uint8_t outKey;
              while (!emptyKeyBuffer()) {
                outKeyBuffer(&outKey);
              }
              lastItem = SCREENDUMP;
            } else
            if((key == 36 || key == 33) && previousProgramRunStop == PGM_RUNNING) {
              previousProgramRunStop = programRunStop = PGM_WAITING;
            }
            setLastKeyCode(key);
            fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, PROGRAM_KB_ACTV);
            wait_for_key_release(0);
            key_pop();
            if(key != 44) {
              break;
            }
          }
          if(sys_current_ms() >= targetMs && !runningOnSimOrUSB && key != 44) {
            break;
          }

          dmcpResetAutoOff();
          goToSleepForMs(0, !reFreshAfterSleep);
        }
        screenUpdatingMode = SCRUPD_AUTO;
        refreshScreen(1201);
      } else {


        lcd_refresh();
        for(int32_t i = 0; i < duration && (programRunStop == PGM_PAUSED || programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED); ++i) {
          if(previousProgramRunStop != PGM_RUNNING) {
            screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
            refreshScreen(12);
            lcd_refresh();
          }
          int key = key_pop();
          key = convertKeyCode(key);
          if(key > 0) {
            if((key == 36 || key == 33) && previousProgramRunStop == PGM_RUNNING) { //JM R/S or EXIT
              previousProgramRunStop = programRunStop = PGM_WAITING;
            }
            setLastKeyCode(key);
            fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, PROGRAM_KB_ACTV);
            wait_for_key_release(0);
            key_pop();
            break;
          }
          dmcpResetAutoOff(); //prevent auto off occurring within the pause, which causes an unrecoverable sleep and impossibility to switch calculator back on
          fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, programRunStop == PGM_RUNNING ? PROGRAM_KB_ACTV : TO_KB_ACTV_MEDIUM); //prevent dying out of the activity timer
          sys_delay(100);
        }
        if(dur != 0 && previousProgramRunStop != PGM_RUNNING){
          screenUpdatingMode &= SCRUPD_AUTO;
          refreshScreen(1204);
          lcd_refresh();
        }
      }


    #else // !DMCP_BUILD  PC_BUILD
      if(gTimerId != 0) {
        g_source_remove(gTimerId);
        gTimerId = 0;
      }
      if(duration == 0) {
        g_main_context_iteration(g_main_context_default(), FALSE);
      } else {
        gTime = 0;
        gRemoveTimer = false;

        gTimerId = g_timeout_add(100, (GSourceFunc) gTimer, NULL);
        refreshLcd(NULL);
        int32_t i = 1;
        while(gTime <= duration && (programRunStop == PGM_PAUSED || programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED)) {
          g_main_context_iteration (g_main_context_default (), duration == 0 ? FALSE : TRUE);
          if(gTime == i) { //arrive here every 100ms, do nothing, just increment the counter to trap the next 100ms
            i++;
            if(previousProgramRunStop != PGM_RUNNING && programRunStop != PGM_PAUSED) {
              screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
              refreshScreen(12);
              refreshLcd(NULL);
            }
          }
        }
        gRemoveTimer = true;
      } // duration == 0
    #endif // PC_BUILD
    if(programRunStop == PGM_WAITING) {
      previousProgramRunStop = PGM_WAITING;
    }
    programRunStop = previousProgramRunStop;
    if(programRunStop != PGM_RUNNING) {
      screenUpdatingMode &= ~SCRUPD_MANUAL_STATUSBAR;
      refreshScreen(13);
      #if defined(DMCP_BUILD)
        lcd_refresh();
      #else // !DMCP_BUILD
        refreshLcd(NULL);
      #endif // DMCP_BUILD
        }
  #endif // !TESTSUITE_BUILD
}





static uint16_t _getKeyArg(uint16_t regist) {
  real34_t arg;

  #pragma GCC diagnostic push
  #pragma GCC diagnostic ignored "-Wimplicit-fallthrough"
  switch(getRegisterDataType(regist)) {
    case dtLongInteger: {
      convertLongIntegerRegisterToReal34(regist, &arg);
      break;
    }
    case dtReal34: {
      if(getRegisterAngularMode(regist) == amNone) {
        real34ToIntegralValue(REGISTER_REAL34_DATA(regist), &arg, DEC_ROUND_DOWN);
        break;
      }
      /* fallthrough */
    }
    default: {
      displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "cannot use %s for the parameter of CASE", getRegisterDataTypeName(REGISTER_X, true, false));
        moreInfoOnError("In function _getKeyArg:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      return 0;
    }
  }
  #pragma GCC diagnostic pop

  if(real34CompareLessThan(&arg, const34_1)) {
    return 0;
  }
  else if(real34CompareGreaterEqual(&arg, const34_65535)) {
    return 65534u;
  }
  else {
    return real34ToUInt32(&arg);
  }
}



void fnKey(uint16_t regist) {
  // no key was pressed
  if(lastKeyCode == 0) {
    temporaryInformation = TI_TRUE;
    #if defined(PC_BUILD)
      while(gtk_events_pending()) {
        gtk_main_iteration();
      }
    #elif defined(DMCP_BUILD)
      dmcpResetAutoOff(); //prevent auto off occurring within a GTO loop with KEY?, which causes an unrecoverable sleep and impossibility to switch calculator back on
      fnTimerStart(TO_KB_ACTV, TO_KB_ACTV, programRunStop == PGM_RUNNING ? PROGRAM_KB_ACTV : TO_KB_ACTV_MEDIUM); //prevent dying out of the activity timer
    #endif //PC_BUILD
  }

  // a key was pressed
  else {
    temporaryInformation = TI_FALSE;
    if(regist <= LAST_NAMED_VARIABLE) {
      longInteger_t kc;
      longIntegerInit(kc);
      uInt32ToLongInteger(lastKeyCode, kc);
      convertLongIntegerToLongIntegerRegister(kc, regist);
      longIntegerFree(kc);
      lastKeyCode = 0;
    }
    else {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "register %u is out of range", regist);
        moreInfoOnError("In function fnKey:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
    }
  }
}



void fnKeyType(uint16_t regist) {
  uint16_t keyCode = _getKeyArg(regist);
  longInteger_t kt;
  longIntegerInit(kt);
  switch(keyCode) {
    case 82: uInt32ToLongInteger( 0u, kt); break;
    case 72: uInt32ToLongInteger( 1u, kt); break;
    case 73: uInt32ToLongInteger( 2u, kt); break;
    case 74: uInt32ToLongInteger( 3u, kt); break;
    case 62: uInt32ToLongInteger( 4u, kt); break;
    case 63: uInt32ToLongInteger( 5u, kt); break;
    case 64: uInt32ToLongInteger( 6u, kt); break;
    case 52: uInt32ToLongInteger( 7u, kt); break;
    case 53: uInt32ToLongInteger( 8u, kt); break;
    case 54: uInt32ToLongInteger( 9u, kt); break;

    case 43:
    case 44:
    case 83: uInt32ToLongInteger(10u, kt); break;

    case 35:
    case 36: uInt32ToLongInteger(11u, kt); break;

    case 11:
    case 12:
    case 13:
    case 14:
    case 15:
    case 16: uInt32ToLongInteger(12u, kt); break;

    case 21:
    case 22:
    case 23:
    case 24:
    case 25:
    case 26:
    case 31:
    case 32:
    case 33:
    case 34:
    case 41:
    case 42:
    case 45:
    case 51:
    case 55:
    case 61:
    case 65:
    case 71:
    case 75:
    case 81:
    case 84:
    case 85: uInt32ToLongInteger(13u, kt); break;

    default: {
      displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
      #if (EXTRA_INFO_ON_CALC_ERROR == 1)
        sprintf(errorMessage, "keycode %u is out of range", keyCode);
        moreInfoOnError("In function fnKeyType:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      longIntegerFree(kt);
      return;
    }
  }
  liftStack();
  convertLongIntegerToLongIntegerRegister(kt, REGISTER_X);
  longIntegerFree(kt);
}



void fnPutKey(uint16_t regist) {
  #if !defined(TESTSUITE_BUILD)
    char kc[4];
    uint16_t keyCode = _getKeyArg(regist);

    programRunStop = PGM_WAITING;

    switch(keyCode) {
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16: kc[0] = keyCode - 10 + '0'; kc[1] = 0;  btnFnClicked(NULL, kc); break;

      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
      case 26: sprintf(kc, "%02u", keyCode - 21 + 0);  btnClicked(NULL, kc);   break;

      case 31:
      case 32:
      case 33:
      case 34:
      case 35:
      case 36: sprintf(kc, "%02u", keyCode - 31 + 6);  btnClicked(NULL, kc);   break;

      case 41:
      case 42:
      case 43:
      case 44:
      case 45: sprintf(kc, "%02u", keyCode - 41 + 12); btnClicked(NULL, kc);   break;

      case 51:
      case 52:
      case 53:
      case 54:
      case 55: sprintf(kc, "%02u", keyCode - 51 + 17); btnClicked(NULL, kc);   break;

      case 61:
      case 62:
      case 63:
      case 64:
      case 65: sprintf(kc, "%02u", keyCode - 61 + 22); btnClicked(NULL, kc);   break;

      case 71:
      case 72:
      case 73:
      case 74:
      case 75: sprintf(kc, "%02u", keyCode - 71 + 27); btnClicked(NULL, kc);   break;

      case 81:
      case 82:
      case 83:
      case 84:
      case 85: sprintf(kc, "%02u", keyCode - 81 + 32); btnClicked(NULL, kc);   break;

      default: {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        #if (EXTRA_INFO_ON_CALC_ERROR == 1)
          sprintf(errorMessage, "keycode %u is out of range", keyCode);
          moreInfoOnError("In function fnPutKey:", errorMessage, NULL, NULL);
        #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
    }

    programRunStop = PGM_WAITING;
  #endif // !TESTSUITE_BUILD
}



void fnEntryQ(uint16_t unusedButMandatoryParameter) {
  if(entryStatus & 0x01) {
    temporaryInformation = TI_TRUE;
  }
  else {
    temporaryInformation = TI_FALSE;
  }
}
