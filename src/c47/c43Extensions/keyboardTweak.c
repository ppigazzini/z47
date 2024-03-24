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

/* ADDITIONAL C43 functions and routines */

/********************************************//**
 * \file keyboardTweak.c
 ***********************************************/

#include "c43Extensions/keyboardTweak.h"

#include "bufferize.h"
#include "calcMode.h"
#include "charString.h"
#include "flags.h"
#include "fonts.h"
#include "hal/gui.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "keyboard.h"
#include "screen.h"
#include "stack.h"
#include "statusBar.h"
#include "softmenus.h"
#include "timer.h"

#include <string.h>
#include "c47.h"

void fnSHIFTf(uint16_t unusedButMandatoryParameter) {
  shiftF = true;
  shiftG = false;
}


void fnSHIFTg(uint16_t unusedButMandatoryParameter) {
  shiftF = false;
  shiftG = true;
}


void fnSHIFTfg(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    btnClicked(NULL, "27");
  #endif // !TESTSUITE_BUILD
}



void keyClick(uint8_t length) {  //Debugging on scope, a pulse after every key edge. !!!!! Destroys the prior volume setting
  #if defined(DMCP_BUILD)
    #if defined(DM42_KEYCLICK)
      while(get_beep_volume() < 11) {
        beep_volume_up();
      }
      start_buzzer_freq(1000000); //Click 1kHz for 1 ms
      sys_delay((uint32_t)length);
      stop_buzzer();
    #endif // DM42_KEYCLICK
  #endif // DMCP_BUILD
}


void showAlphaModeonGui(void) {
  #if defined(PC_BUILD)
    char tmp[200];
    sprintf(tmp, "^^^^showAlphaModeonGui\n");
    jm_show_comment(tmp);
  #endif // PC_BUILD

  if(calcMode == CM_AIM || calcMode == CM_EIM || tam.mode) {                      //vv dr JM
    #if !defined(TESTSUITE_BUILD)
      showHideAlphaMode();
    #endif // !TESTSUITE_BUILD
    calcModeAimGui();
  }                                                         //^^
  doRefreshSoftMenu = true;             //jm
}


void showShiftState(void) {
  #if !defined(TESTSUITE_BUILD)
    //showAlphaModeonGui();

    #if defined(PC_BUILD_TELLTALE)
      printf("    >>> showShiftState: calcMode=%d\n", calcMode);
    #endif // PC_BUILD_TELLTALE

    if(temporaryInformation != TI_SHOW_REGISTER_BIG && temporaryInformation != TI_SHOW_REGISTER_SMALL && temporaryInformation != TI_SHOW_REGISTER) {
      if(shiftF) {                        //SEE screen.c:refreshScreen
        showGlyph(STD_MODE_F, &standardFont, X_SHIFT, Y_SHIFT, vmNormal, true, true);   // f is pixel 4+8+3 wide
        show_f_jm();
        showHideAlphaMode();
      }
      else if(shiftG) {                   //SEE screen.c:refreshScreen
        showGlyph(STD_MODE_G, &standardFont, X_SHIFT, Y_SHIFT, vmNormal, true, true);   // g is pixel 4+10+1 wide
        show_g_jm();
        showHideAlphaMode();
      }
      else {
        clearShiftState();
        clear_fg_jm();
        showHideAlphaMode();
      }
    }
  #endif // !TESTSUITE_BUILD
}


/********************************************//**  //JM Retain this because of convenience
 * \brief Resets shift keys status and clears the
 * corresponding area on the screen
 *
 * \param void
 * \return void
 *
 ***********************************************/
void resetShiftState(void) {
  fnTimerStop(TO_FG_LONG);
  fnTimerStop(TO_FG_TIMR);

  fnTimerStop(TO_3S_CTFF);     //to make sure a repeated key does not restart the f shift which just reset
  fnTimerStop(TO_AUTO_REPEAT);

  if(shiftF || shiftG) {                                                        //vv dr
    shiftF = false;
    shiftG = false;
    screenUpdatingMode &= ~SCRUPD_MANUAL_SHIFT_STATUS;
    showShiftState();
    refreshScreen();
    refreshModeGui();                                                             //JM refreshModeGui
  }                                                                             //^^
}


void resetKeytimers(void) {
  resetShiftState();
  //fnTimerStop(TO_FG_LONG);
  //fnTimerStop(TO_FG_TIMR);

  fnTimerStop(TO_CL_LONG);

  //additionally
  fnTimerStop(TO_FN_LONG);
}


#if !defined(TESTSUITE_BUILD)
  /********************************************//**
  * \brief Displays the f or g shift state in the
  * upper left corner of the T register line
  *
  * \param void
  * \return void
  ***********************************************/
  void show_f_jm(void) {
    //showSoftmenuCurrentPart();                                                    //JM - Redraw boxes etc after shift is shown
    //JMTOCHECK2        if(softmenuStackPointer >= 0) {                             //JM - Display dot in the f - line
    if(!FN_timeouts_in_progress && calcMode != CM_ASN_BROWSER) {
      if(!ULFL) {
        underline(1);
        ULFL = !ULFL;
        doRefreshSoftMenu = true;
      }
      if(ULGL) {
        underline(2);
        ULGL = !ULGL;
        doRefreshSoftMenu = true;
      }
    }
    //}                                                                             //JM - Display dot in the f - line
  }


  void show_g_jm(void) {
    //showSoftmenuCurrentPart();                                                    //JM - Redraw boxes etc after shift is shown
    //JMTOCHECK2        if(softmenuStackPointer >= 0) {                             //JM - Display dot in the g - line
    if(!FN_timeouts_in_progress && calcMode != CM_ASN_BROWSER) {
      if(ULFL) {
        underline(1);
        ULFL = !ULFL;
        doRefreshSoftMenu = true;
      }
      if(!ULGL) {
        underline(2);
        ULGL = !ULGL;
        doRefreshSoftMenu = true;
      }
    }
    //}                                                                             //JM - Display dot in the g - line
  }


  void clear_fg_jm(void) {
    //showSoftmenuCurrentPart();            //JM TO REMOVE STILL !!                 //JM - Redraw boxes etc after shift is shown
    if(!FN_timeouts_in_progress) {        //Cancel lines
      if(ULFL) {
        underline(1);
        ULFL = !ULFL;
        doRefreshSoftMenu = true;
      }
      if(ULGL) {
        underline(2);
        ULGL = !ULGL;
        doRefreshSoftMenu = true;
      }
    }
  }


  void fg_processing_jm(void) {
    if(ShiftTimoutMode || HOME3 || MYM3) {
      if(HOME3 || MYM3) {
        if(fnTimerGetStatus(TO_3S_CTFF) == TMR_RUNNING) {
          JM_SHIFT_HOME_TIMER1++;
          if(JM_SHIFT_HOME_TIMER1 >= 3) {
            fnTimerStop(TO_FG_TIMR);      //dr
            fnTimerStop(TO_3S_CTFF);
            shiftF = false;               // Set it up, for flags to be cleared below.
            shiftG = true;
            if(HOME3 || MYM3) {
              #if defined(PC_BUILD)
                jm_show_calc_state("keyboardtweak.c: fg_processing_jm: HOME3");
              #endif // PC_BUILD
              if(HOME3 && currentMenu() == -MNU_HOME) {                    //JM shifts
              //printf("popping\n");
                popSoftmenu();                                                    //JM shifts
              }
              else {
                if(calcMode == CM_AIM || calcMode == CM_EIM) {                    //JM shifts
                  showSoftmenu(-MNU_MyAlpha);
                }
                else {                                                            //JM SHIFTS
                  if(HOME3) {
                    showSoftmenu(-MNU_HOME);
                  }
                  else if(MYM3) {
                    BASE_OVERRIDEONCE = true;
                    showSoftmenu(-MNU_MyMenu);
                  }                             //If none selected, do not display any menu, keep the screen blank
                }                                                                 //JM shifts
              }                                                                   //JM shifts
              showSoftmenuCurrentPart();
            }                                                                     //JM shifts
          }
        }
        if(fnTimerGetStatus(TO_3S_CTFF) == TMR_STOPPED) {
          JM_SHIFT_HOME_TIMER1 = 1;
          fnTimerStart(TO_3S_CTFF, TO_3S_CTFF, JM_TO_3S_CTFF);                    //dr
        }
      }
    }

    if(!shiftF && !shiftG) {                                                      //JM shifts
      shiftF = true;                                                              //JM shifts
      shiftG = false;
    }                                                                             //JM shifts
    else if(shiftF && !shiftG) {                                                  //JM shifts
      shiftF = false;                                                             //JM shifts
      shiftG = true;                                                              //JM shifts
    }
    else if(!shiftF && shiftG) {                                                  //JM shifts
      shiftF = false;                                                             //JM shifts
      shiftG = false;                                                             //JM shifts
    }
    else if(shiftF && shiftG) {                                                   //JM shifts  should never be possible. included for completeness
      shiftF = false;                                                             //JM shifts
      shiftG = false;                                                             //JM shifts
    }                                                                             //JM shifts
  }


  int16_t Check_SigmaPlus_Assigned(int16_t * result, int16_t tempkey) {
    //JM NORMKEY CHANGE NORMAL MODE KEY SIGMA+ TO SOMETHING
    if((calcMode == CM_NORMAL || calcMode == CM_NIM) &&
       (!catalog || (catalog && (Norm_Key_00_VAR != ITM_SHIFTg && Norm_Key_00_VAR != ITM_SHIFTf && Norm_Key_00_VAR != KEY_fg))) &&
       (  (!shiftF && !shiftG && (tempkey == Norm_Key_00_key) && ((kbd_std + Norm_Key_00_key)->primary == *result) )  ||  ((Norm_Key_00_VAR == KEY_fg) && (tempkey == Norm_Key_00_key) && ((kbd_std + Norm_Key_00_key)->primary == *result) )  )
       ) {
      *result = Norm_Key_00_VAR;
      return (Norm_Key_00_VAR == ITM_SHIFTg || Norm_Key_00_VAR == ITM_SHIFTf || Norm_Key_00_VAR == KEY_fg) ? Norm_Key_00_VAR : 0;
    }
    return 0;
  }


  void Setup_MultiPresses(int16_t result) {                            //Setup and start double press for DROP timer, and check for second press
    JM_auto_doublepress_autodrop_enabled = 0;                          //JM TIMER CLRDROP. Autodrop means double click normal key.
    int16_t tmp = 0;
    if(calcMode == CM_NORMAL && result == ITM_BACKSPACE && tam.mode == 0) {             //Set up backspace double click to DROP
      tmp = ITM_DROP;
    }

    if(tmp != 0) {
      if(fnTimerGetStatus(TO_CL_DROP) == TMR_RUNNING) {
        JM_auto_doublepress_autodrop_enabled = tmp;                    //Signal to DROP, i.e. that the second press of the same button was received
      }
      fnTimerStart(TO_CL_DROP, TO_CL_DROP, JM_CLRDROP_TIMER);
    }
    fnTimerStop(TO_FG_LONG);                        //dr
    fnTimerStop(TO_FN_LONG);                        //dr
  }


  void Check_MultiPresses(int16_t *result, int8_t key_no) { //Set up longpress
    int16_t longpressDelayedkey1 = 0;                                   //To Setup the timer locally for the next timed stage
            longpressDelayedkey2 = 0;                                   //To Store the next timed stage
            longpressDelayedkey3 = 0;                                   //To Store the next timed stage


    int16_t           tmpp_ = getSystemFlag(FLAG_USER) ? kbd_usr[key_no].primary  : kbd_std[key_no].primary;
    int16_t tmpf = 0, tmpf_ = getSystemFlag(FLAG_USER) ? kbd_usr[key_no].fShifted : kbd_std[key_no].fShifted;
    int16_t tmpg = 0, tmpg_ = getSystemFlag(FLAG_USER) ? kbd_usr[key_no].gShifted : kbd_std[key_no].gShifted;
    if((calcMode == CM_NORMAL || calcMode == CM_NIM) && tam.mode==0) {  //longpress yellow math functions on the first two rows, menus allowed provided it is within keys 00-14
      if(   ((key_no >= 0 && key_no < 15) && (LongPressM == RB_M1234 || LongPressM == RB_M124))  //any mathkeys
         || (/*(key_no >= 0 && key_no < 15) && (LongPressM == RB_M14) && */(tmpp_ == ITM_DRG && tmpf_ == ITM_USERMODE ) ) //DRG anywhere mathkeys
         || (tmpp_ == ITM_XEQ && tmpf_ == ITM_AIM)                                               //anywhere
        ) {
        if(!shiftF && !shiftG) {
          longpressDelayedkey1 = tmpf_;
          tmpf = tmpf_;
          if(LongPressM == RB_M1234) {
            longpressDelayedkey3 = tmpg_;
            tmpg = tmpg_;
          }
        }
      }
    }                                                                   //yellow and blue function keys ^^

    char *funcParam = (char *)getNthString((uint8_t *)userKeyLabel, key_no); //keyCode * 6 + g ? 2 : f ? 1 : 0);
    //printf("\n\n >>>> ## result=%i key_no=%i *funcParam=%s  [0]=%u\n", *result, key_no, (char*)funcParam, ((char*)funcParam)[0]);

    switch(calcMode) {
      case CM_ASSIGN :
      case CM_NORMAL : {                                         //longpress special keys
        switch(*result) {

          case ITM_XEQ:
            if(tam.mode == 0 && ((char*)funcParam)[0] == 0 && (getSystemFlag(FLAG_USER) ? kbd_usr[key_no].primary == kbd_std[key_no].primary : true)) { //If XEQ (always primary) is not the standard position, or if XEQ has a parameter then do not inject it into the long press cycle
              if(tmpp_ == ITM_XEQ && tmpf == ITM_AIM) {
                if(getSystemFlag(FLAG_SH_LONGPRESS)) {
                  if(LongPressM == RB_M14) {
                    longpressDelayedkey1 = ITM_AIM;
                    longpressDelayedkey2 = 0;
                    longpressDelayedkey3 = -MNU_XXEQ;
                  } else if(LongPressM == RB_M124) {
                    longpressDelayedkey1 = ITM_AIM;
                    longpressDelayedkey2 = 0;
                    longpressDelayedkey3 = -MNU_XXEQ;
                  } else if(LongPressM == RB_M1234) {
                    longpressDelayedkey1 = ITM_AIM;
                    longpressDelayedkey2 = -MNU_XXEQ;
                    longpressDelayedkey3 = tmpg;
                  }
              } else {
                longpressDelayedkey1 = -MNU_XXEQ;
                longpressDelayedkey2 = tmpf_;
                longpressDelayedkey3 = tmpg_;
              }
            }
          }
            break;

          case ITM_BACKSPACE:
            if(tam.mode == 0) {
              longpressDelayedkey2 = longpressDelayedkey1;
              longpressDelayedkey1 = ITM_CLSTK;    //backspace longpress to CLSTK
            }
            break;

          case ITM_EXIT1:
            longpressDelayedkey2 = ITM_CLRMOD;     //EXIT longpress DOES CLRMOD
            longpressDelayedkey1 = ITM_BASEMENU;
            break;

          case ITM_DRG:
              longpressDelayedkey1 = 0;
              longpressDelayedkey2 = 0;
              longpressDelayedkey3 = 0;
              if(tmpp_ == ITM_DRG) {
                if(LongPressM == RB_M14) {
                  longpressDelayedkey1 = tmpf == ITM_USERMODE && getSystemFlag(FLAG_SH_LONGPRESS) ? ITM_USERMODE : 0;
                  longpressDelayedkey2 = 0;
                  longpressDelayedkey3 = 0;
                } else if(LongPressM == RB_M124) {
                  longpressDelayedkey1 = ITM_USERMODE;
                  longpressDelayedkey2 = 0;
                  longpressDelayedkey3 = 0 ;
                } else if(LongPressM == RB_M1234) {
                  longpressDelayedkey1 = ITM_USERMODE;
                  longpressDelayedkey2 = tmpg;
                  longpressDelayedkey3 = 0;
                }
              }
            break;
          default:;
        }
        break;
      }
      case CM_NIM : {
        switch(*result) {
          case ITM_XEQ:
            if(tam.mode == 0 && ((char*)funcParam)[0] == 0 && (getSystemFlag(FLAG_USER) ? kbd_usr[key_no].primary == kbd_std[key_no].primary : true)) { //If XEQ (always primary) is not the standard position, or if XEQ has a parameter then do not inject it into the long press cycle
              if(getSystemFlag(FLAG_SH_LONGPRESS) && tmpp_ == ITM_XEQ && tmpf == ITM_AIM) {
                if(LongPressM == RB_M14) {
                  longpressDelayedkey1 = ITM_AIM;
                  longpressDelayedkey2 = 0;
                  longpressDelayedkey3 = -MNU_XXEQ;
                } else if(LongPressM == RB_M124) {
                  longpressDelayedkey1 = ITM_AIM;
                  longpressDelayedkey2 = 0;
                  longpressDelayedkey3 = -MNU_XXEQ;
                } else if(LongPressM == RB_M1234) {
                  longpressDelayedkey1 = ITM_AIM;
                  longpressDelayedkey2 = -MNU_XXEQ;
                  longpressDelayedkey3 = tmpg;
                }
              } else {
                longpressDelayedkey1 = -MNU_XXEQ;
                longpressDelayedkey2 = tmpf_;
                longpressDelayedkey3 = tmpg_;
              }
            }
            break;
          case ITM_BACKSPACE:
            if(tam.mode == 0) {
              longpressDelayedkey1 = ITM_CLN;      //BACKSPACE longpress clears input buffer
            }
            break;
          case ITM_EXIT1:
              longpressDelayedkey2 = ITM_CLRMOD;   //EXIT longpress DOES CLRMOD
              longpressDelayedkey1 = ITM_BASEMENU;
              break;
          case ITM_DRG:
              longpressDelayedkey1 = 0;
              longpressDelayedkey2 = 0;
              longpressDelayedkey3 = 0;
              if(tmpp_ == ITM_DRG) {
                if(LongPressM == RB_M14) {
                  longpressDelayedkey1 = tmpf == ITM_USERMODE && getSystemFlag(FLAG_SH_LONGPRESS) ? ITM_USERMODE : 0;
                  longpressDelayedkey2 = 0;
                  longpressDelayedkey3 = 0;
                } else if(LongPressM == RB_M124) {
                  longpressDelayedkey1 = ITM_USERMODE;
                  longpressDelayedkey2 = 0;
                  longpressDelayedkey3 = 0 ;
                } else if(LongPressM == RB_M1234) {
                  longpressDelayedkey1 = ITM_USERMODE;
                  longpressDelayedkey2 = tmpg;
                  longpressDelayedkey3 = 0;
                }
              }
            break;
          default:;
        }
        if( (*result == ITM_ms || longpressDelayedkey1 == ITM_ms || longpressDelayedkey2 == ITM_ms || longpressDelayedkey3 == ITM_ms ) || //.ms needs NIM mode to be open if the user intends it to be open.
            (*result == ITM_CC || longpressDelayedkey1 == ITM_CC || longpressDelayedkey2 == ITM_CC || longpressDelayedkey3 == ITM_CC ) ||
            (*result == ITM_op_j || longpressDelayedkey1 == ITM_op_j || longpressDelayedkey2 == ITM_op_j || longpressDelayedkey3 == ITM_op_j ) ||
            (*result == ITM_op_j_pol || longpressDelayedkey1 == ITM_op_j_pol || longpressDelayedkey2 == ITM_op_j_pol || longpressDelayedkey3 == ITM_op_j_pol )) {
          delayCloseNim = true;
        }
        break;
      }
      case CM_AIM : {
        switch(*result) {
          case ITM_BACKSPACE:
            if(tam.mode == 0) {
                longpressDelayedkey1 = ITM_CLA;      //BACKSPACE longpress clears input buffer
              }
            break;
          case ITM_EXIT1:
            longpressDelayedkey2 = ITM_CLRMOD;   //EXIT longpress DOES CLRMOD
            longpressDelayedkey1 =-MNU_MyAlpha;
            break;
          case ITM_ENTER:
            if(tam.mode == 0) {
              longpressDelayedkey1 = ITM_XSWAP;
              // longpressDelayedkey2 = ITM_XPARSE; //not yet implemented
            }
            break;
          default:;
        }
        break;
      }
      case CM_EIM : {
        switch(*result) {
          case ITM_BACKSPACE:
            if(tam.mode == 0) {
              longpressDelayedkey1 = ITM_CLA;      //BACKSPACE longpress clears input buffer
            }
            break;
          case ITM_EXIT1:
            longpressDelayedkey1 = ITM_CLRMOD;   //EXIT longpress DOES CLRMOD
            break;
          case ITM_ENTER:
            if(tam.mode == 0) {
              longpressDelayedkey1 = ITM_XSWAP;
            }
            break;
          default:;
        }
        break;
      }
      default : {
        switch(*result) {
          case ITM_EXIT1    :
            longpressDelayedkey1 = ITM_CLRMOD;   //EXIT longpress DOES CLRMOD
            break;
          default:;
        }
        break;
      }
    }

    if(longpressDelayedkey1 != 0) {       //if activated key pressed
      JM_auto_longpress_enabled = longpressDelayedkey1;
      fnTimerStart(TO_CL_LONG, TO_CL_LONG, JM_TO_CL_LONG);    //dr

      //JM TIMER CLRDROP. Autodrop means double click normal key.
      if(JM_auto_doublepress_autodrop_enabled != 0) {
        hideFunctionName();
        undo();
        showFunctionName(JM_auto_doublepress_autodrop_enabled, FUNCTION_NOPTIME, "SF:M");            //JM CLRDROP
        *result = JM_auto_doublepress_autodrop_enabled;
        fnTimerStop(TO_CL_DROP);          //JM TIMER CLRDROP ON DOUBLE BACKSPACE
        setSystemFlag(FLAG_ASLIFT);       //JM TIMER CLRDROP ON DOUBLE BACKSPACE
      }
    }
  }


  //******************* JM LONGPRESS & JM DOUBLE CLICK START *******************************
  int16_t nameFunction(int16_t fn, bool_t shiftF, bool_t shiftG) { //JM LONGPRESS vv
    int16_t func = 0;

    char str[3];
    str[0] = '0' + fn;
    str[1] = 0;

    func = determineFunctionKeyItem_C47(str, shiftF, shiftG);

    #if defined(PC_BUILD)
      printf(">>> nameFunction fn=%i shifts=%u %u: %s %s\n", fn, shiftF, shiftG, indexOfItems[abs(func)].itemCatalogName, indexOfItems[abs(func)].itemSoftmenuName);
    #endif // PC_BUILD

    return abs(func);
  }


  //CONCEPT - actual timing was changed:

  /* Switching profile, to jump to g[FN]:
                    set g
  ____-----_______--------->
      P    R      P

    |>              btnFnPressed:  mark time and ignore if FN_double_click is not set
          |>         btnFnReleased: if t<t0 then set FN_double_click AND prevent normal MAIN keypress
                |>  btnFnPressed:  if t<t1 AND if FN_double_click then jump start to g[FN]


  Standard procedure LONGPRESS:

    | 800 | 800 | 800 |    ms     Monitored while LONGPRESSED
  ___+-----|-----|-----|--> NOP    Press and time out to NOP
  ___+---x_|_____|_____|___        Press and release within Fx time. Fx selected upon release
  ___+-----|--x__|_____|___        Press and hold, release within f(Fx) time. f(Fx) selected upon release
  ___+-----|-----|--___|___        Press and hold and hold, release within g(Fx) time. g(Fx) selected upon release
          |     |     |

  At x, at time 0, wait 75 ms to see if a press happens, i.e. double click.
  - After 75 ms, execute function.
  - If before 75 ms, key is pressed, jump to the beginning of g(Fx) state.

      STATE #1 #2 #3 #4
  ___________---___---_____       STATES indicated

  ----------x1 x2 x3 x4           X's indicate transitions X


  Detail for x (transition press/release):

  STATE1  | STATE2  | STATE3
          |t=0      |t=75 ms
  --------E______   |             Showing release and immediate execution at "E" (previous system, no LONGPRESS no DOUBLE click)
  --------x_________E_____        Showing release at x and delayed execution "E" (if double click is to be detected)
          #########              ## shows DEAD TIME where C43 does not react to the key release that already happened
                    ^             ^ shows the point where the x command is executed if no double press recognised.

  --------x_______G-|-----        Starting with key already pressed, release at x, re-press shown at 60 ms, double click registered, g-shift activated, COMMAND displayed, timing started to NOP if not released.

  --------x_________E             Starting with key already pressed, release at x, no repress within 75 ms execute Fx.
  --------x_________|_C---        Starting with key already pressed, release at x, re-press shown at 85 ms, timing cycle C re-started on Fx.


  Double click release:
  Timing is reset to start 800 ms from G again
  --------x_______G---E__        Starting with key already pressed, release at x, re-press shown at 60 ms, double click registered, g-shift activated, COMMAND displayed, timing started, key released

  //Summary
    //Process starts in btnFnReleased, with a FN key released.
    //  do timecheck, i.e. zero the timer
    //At the next press, i.e. btnFnPressed, check for a 5 ms < re-press < 75 ms gap, which, indicates a double press. (5 ms = debounce check).
    //Set a flag here, to let the refresh cyclic check for 75 ms and, if exceeded, execute the function

  */


  //**************JM DOUBLE CLICK SUPPORT vv **********************************
  void FN_cancel() {
    FN_key_pressed = 0;
    FN_timeouts_in_progress = false;
    fnTimerStop(TO_FN_LONG);                                  //dr
  }


  //*************----------*************------- FN KEY PRESSED -------***************-----------------
  void btnFnPressed_StateMachine
    #if defined(PC_BUILD)                                                           //JM LONGPRESS FN
      (GtkWidget *unused, gpointer data)
    #endif // PC_BUILD
    #if defined(DMCP_BUILD)
      (void *unused, void *data)
    #endif // DMCP_BUILD
    {

    bool_t exexute_double_g;
    bool_t double_click_detected;

    //#if define(INLINE_TEST)
    //  if(testEnabled) {
    //    fnSwStart(1);
    //  }
    //#endif // INLINE_TEST

    FN_timed_out_to_RELEASE_EXEC = false;

    //Change states according to PRESS/RELEASE incoming sequence
    if(FN_state == ST_2_REL1) {
      FN_state = ST_3_PRESS2;
    }
    else {
      FN_state =  ST_1_PRESS1;
    }

    //FN_key_pressed = *((char *)data) - '0' + 37;  //to render 38-43, as per original keypress

    if(FN_state == ST_3_PRESS2 && fnTimerGetStatus(TO_FN_EXEC) != TMR_RUNNING) {  //JM BUGFIX (INVERTED) The first  usage did not work due to the timer which was in stopped mode, not in expired mode.
      //----------------Copied here
      underline_softkey(FN_key_pressed-38, 3, false);   //Purposely in row 3 which does not exist, just to activate the clear previous line

      hideFunctionName();

      //IF 2-->3 is longer than double click time, then move back to state 1
      FN_timeouts_in_progress = false;
      FN_state = ST_1_PRESS1;
    }



    if(fnTimerGetStatus(TO_FN_EXEC) == TMR_RUNNING) {         //vv dr new try
      if(FN_key_pressed_last != FN_key_pressed) {       //first press
        fnTimerExec(TO_FN_EXEC);
        FN_handle_timed_out_to_EXEC = true;
        exexute_double_g = false;
      }
      else {                                            //second press
        FN_handle_timed_out_to_EXEC = false;
        exexute_double_g = true;
        fnTimerStop(TO_FN_EXEC);
      }
      //PLACE ANY CONDITION PREVENTING DOUBLE CLICK HERE
      //  old:if(softmenuStack[0].softmenuId == 0) exexute_double_g = false; //JM prevent double click from executing nothing and showing a line, if no menu is showing
    }
    else {
      FN_handle_timed_out_to_EXEC = true;
      exexute_double_g = false;
    }                                                         //^^

    if(FN_state == ST_1_PRESS1) {
      FN_key_pressed_last = FN_key_pressed;
    }

    //printf("^^^^ softmenu=%d -MNU_ALPHA=%d currentFirstItem=%d\n", softmenu[softmenuStack[0].softmenuId].menuItem, -MNU_ALPHA, softmenuStack[0].firstItem);
    //**************JM DOUBLE CLICK DETECTION ******************************* // JM FN-DOUBLE
    double_click_detected = false;                                            //JM FN-DOUBLE - Dip detection flag
    if((jm_G_DOUBLETAP && !BLOCK_DOUBLEPRESS_MENU(softmenuStack[0].softmenuId,FN_key_pressed-38,0)  )) {
      if(exexute_double_g) {
        if(FN_key_pressed !=0 && FN_key_pressed == FN_key_pressed_last) {     //Identified valid double press dip, the same key in rapid succession
          shiftF = false;                                                     //JM
          shiftG = true;                                                      //JM
          double_click_detected = true;                                       //JM --> FORCE INTO LONGPRESS
          FN_handle_timed_out_to_EXEC = false;                //dr
        }
      }
      else {
        FN_timeouts_in_progress = false;         //still in no shift mode
        fnTimerStop(TO_FN_LONG);                              //dr
      }
    }

    //STAGE 1 AND 3 GO HERE
    //**************JM LONGPRESS ****************************************************
    if((FN_state == ST_1_PRESS1 || FN_state == ST_3_PRESS2) && (!FN_timeouts_in_progress || double_click_detected) && FN_key_pressed != 0) {
      FN_timeouts_in_progress = true;
      fnTimerStart(TO_FN_LONG, TO_FN_LONG,  FN_state == ST_1_PRESS1 ? TIME_FN_12XX_TO_F : TIME_FN_DOUBLE_G_TO_NOP);    //dr
      FN_timed_out_to_NOP = false;


      if(!shiftF && !shiftG) {
        char *varCatalogItem = "SF:U";
        int16_t Dyn = nameFunction(FN_key_pressed-37, shiftF, shiftG);
        //printf("dynamicMenuItem=%i %i\n", dynamicMenuItem, Dyn);
        if(dynamicMenuItem > -1 && !DEBUGSFN) {
          varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
        }
        showFunctionName(Dyn, 0, varCatalogItem);
        underline_softkey(FN_key_pressed-38, 0, !true /*dontclear at first call*/); //JMUL inverted clearflag
      }


      else if(shiftF && !shiftG) {
        char *varCatalogItem = "SF:V";
        int16_t Dyn = nameFunction(FN_key_pressed-37, shiftF, shiftG);
        //printf("dynamicMenuItem=%i %i\n", dynamicMenuItem, Dyn);
        if(dynamicMenuItem > -1 && !DEBUGSFN) {
          varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
        }
        showFunctionName(Dyn, 0,  varCatalogItem);
        underline_softkey(FN_key_pressed-38, 1, !true /*dontclear at first call*/); //JMUL inverted clearflag
      }


      else if(!shiftF && shiftG) {
        char *varCatalogItem = "SF:W";
        int16_t Dyn = nameFunction(FN_key_pressed-37, shiftF, shiftG);
        //printf("dynamicMenuItem=%i\n", dynamicMenuItem);
        if(dynamicMenuItem > -1 && !DEBUGSFN) {
          varCatalogItem = dynmenuGetLabel(dynamicMenuItem);
        }
        showFunctionName(Dyn, 0,  varCatalogItem);
        underline_softkey(FN_key_pressed-38, 2, !true /*dontclear at first call*/); //JMUL inverted clearflag
      }                                                                       //further shifts are done within FN_handler
    }
    //#if defined(INLINE_TEST)
    //  if(testEnabled) {
    //    fnSwStop(1);
    //  }
    //#endif // INLINE_TEST
  }


  //*************----------*************------- FN KEY RELEASED -------***************-----------------
  void btnFnReleased_StateMachine
    #if defined(PC_BUILD)                                                             //JM LONGPRESS FN
      (GtkWidget *unused, gpointer data)
    #endif // PC_BUILD
    #if defined(DMCP_BUILD)
      (void *unused, void *data)
    #endif // DMCP_BUILD
    {
    //#if defined(INLINE_TEST)
    //  if(testEnabled) {
    //    fnSwStart(2);
    //  }
    //#endif // INLINE_TEST

    #if defined(VERBOSEKEYS)
      printf(">>>>Z 0050A btnFnReleased_StateMachine ------------------ FN_state=%d\n", FN_state);
    #endif // VERBOSEKEYS

    if(FN_state == ST_3_PRESS2) {
      FN_state = ST_4_REL2;
    }
    else {
      FN_state = ST_2_REL1;
    }

    #if defined(VERBOSEKEYS)
      printf(">>>>Z 0050B btnFnReleased_StateMachine ------------------ FN_state=%d\n", FN_state);
    #endif // VERBOSEKEYS

    if(jm_G_DOUBLETAP && !BLOCK_DOUBLEPRESS_MENU(softmenuStack[0].softmenuId,FN_key_pressed-38,0) && FN_state == ST_2_REL1 && FN_handle_timed_out_to_EXEC) {
      uint8_t offset =  0;
      if(shiftF && !shiftG) {
        offset =  6;
      }
      else if(!shiftF && shiftG) {
        offset = 12;
      }
      fnTimerStart(TO_FN_EXEC, FN_key_pressed + offset, TIME_FN_DOUBLE_RELEASE);

      #if defined(VERBOSEKEYS)
        printf(">>>>Z 0050 btnFnReleased_StateMachine ------------------ Start TO_FN_EXEC\n          data=|%s| data[0]=%d (Global) FN_key_pressed=%d +offset=%d\n",(char*)data,((char*)data)[0], FN_key_pressed, offset);
      #endif // VERBOSEKEYS

      //FN_key_pressed = *((char *)data) - '0' + 37;  //to render 38-43, as per original keypress
      //This parameter of the timer is non-standard: 38-43 for unshifted, +6 for f, +12 for g.
    }

      // **************JM LONGPRESS EXECUTE****************************************************
    char charKey[3];
    charKey[0]=0;
    bool_t EXEC_pri;
    EXEC_pri = (FN_timeouts_in_progress && (FN_key_pressed != 0));
    // EXEC_FROM_LONGPRESS_RELEASE     EXEC_FROM_LONGPRESS_TIMEOUT  EXEC FN primary
    if((FN_timed_out_to_RELEASE_EXEC || FN_timed_out_to_NOP || EXEC_pri ))  {                  //JM DOUBLE: If slower ON-OFF than half the limit (250 ms)
      underline_softkey(FN_key_pressed-38, 3, false);   //Purposely in row 3 which does not exist, just to activate the clear previous line
      charKey[1]=0;
      charKey[0]=FN_key_pressed + (-37+48);

      hideFunctionName();

      if(!FN_timed_out_to_NOP && fnTimerGetStatus(TO_FN_EXEC) != TMR_RUNNING) {
        btnFnClicked(unused, charKey);                                             //Execute
      }

      if(!(calcMode == CM_REGISTER_BROWSER || calcMode == CM_FLAG_BROWSER || calcMode == CM_ASN_BROWSER || calcMode == CM_FONT_BROWSER || calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH  || calcMode == CM_LISTXY)) {
        if((calcMode == CM_ASSIGN && itemToBeAssigned == 0) || FN_timed_out_to_NOP) { //Clear any possible underline residues
          showSoftmenuCurrentPart();
        }
      }

      resetShiftState();
      FN_cancel();
    }

    //**************JM LONGPRESS AND JM DOUBLE ^^ *********************************************   // JM FN-DOUBLE
    //#if defined(INLINE_TEST)
    //  if(testEnabled) {
    //    fnSwStop(2);
    //  }
    //#endif // INLINE_TEST
  }


  void execFnTimeout(uint16_t key) {                          //dr - delayed call of the primary function key
    char charKey[3];
    charKey[1] = 0;
    charKey[0] = key + (-37+48);

    #if defined(VERBOSEKEYS)
      printf(">>>>Z RRR3 execFnTimeout              ------------------       TO_FN_EXEC\n          charKey=|%s| charkey[0]=%d key+11=%d \n", charKey, charKey[0], key+11);
    #endif // VERBOSEKEYS

    btnFnClicked(NULL, (char *)charKey);
  }


  void shiftCutoff(uint16_t unusedButMandatoryParameter) {        //dr - press shift three times within one second to call HOME timer
    fnTimerStop(TO_3S_CTFF);
  }
  //---------------------------------------------------------------
#endif // !TESTSUITE_BUILD


//numlock replacements require the case to be upper case
uint16_t numlockReplacements(uint16_t id, int16_t item, bool_t NL, bool_t FSHIFT, bool_t GSHIFT) {
  int16_t item1 = 0;
  //printf("####A>>%u %u %u\n", id, item, item1);

  if(keyReplacements(item, &item1, NL, FSHIFT, GSHIFT)) {
    return max(item1, -item1);
  }
  else {
    return max(item, -item);
  }
}


 //Note item1 MUST be set to 0 prior to calling.
 bool_t keyReplacements(int16_t item, int16_t *item1, bool_t NL, bool_t FSHIFT, bool_t GSHIFT) {
   //printf("####B>> %d %d\n", item, *item1);
   if(calcMode == CM_AIM || calcMode == CM_EIM || calcMode == CM_PEM || (tam.mode && tam.alpha) || (calcMode == CM_ASSIGN && itemToBeAssigned == 0)) {

    if(GSHIFT) {        //ensure that sigma and delta stays uppercase
      switch(item) {
        case ITM_sigma:         *item1 = ITM_SIGMA;        break;
        case ITM_delta:         *item1 = ITM_DELTA;        break;
        case ITM_NULL:          *item1 = ITM_SPACE;        break;
        default:                                           break;
      }
    }

    else if(NL) {       //JMvv Numlock translation: Assumes lower case is NOT active
      
      item -= (ITM_A + 26 <= item && item <= ITM_Z + 26) ? -26 : 0; //Ensures lower case is NOT active
      uint16_t ix = 15; //from EEX to the bottom of the keyboard, last key 37
      while(ix < 37) {        
        if(kbd_std[ix].primaryAim != ITM_EXIT1 && kbd_std[ix].primaryAim != ITM_UP1 && kbd_std[ix].primaryAim != ITM_DOWN1 && kbd_std[ix].primaryAim != ITM_BACKSPACE) {
          if(!FSHIFT && item == kbd_std[ix].primaryAim) {
            *item1 = getSystemFlag(FLAG_USER) ? kbd_usr[ix].gShiftedAim : kbd_std[ix].gShiftedAim;
            break;
          }
          if(FSHIFT && ix >= 31 && item == kbd_std[ix].gShiftedAim) {                            //Originally for C47: ITM_MINUS, ITM_PLUS, ITM_SLASH, ITM_PERIOD, ITM_0
            *item1 = getSystemFlag(FLAG_USER) ? kbd_usr[ix].primaryAim : kbd_std[ix].primaryAim;
            break;
          }
        }
        ix++;
      }

    }
  }
  return *item1 != 0;
}


#if defined(DMCP_BUILD)                                           //vv dr - internal keyBuffer POC
  //#define JMSHOWCODES_KB0   // top line left    Key value from DM42. Not necessarily pushed to buffer.
  //#define JMSHOWCODES_KB1   // top line middle  Key and  dT value
  //#define JMSHOWCODES_KB2   // main screen      Telltales keys, times, etc.
  //#define JMSHOWCODES_KB3   // top line right   Single Double Triple

  void keyBuffer_pop(void) {
    int tmpKey;

    do {
      tmpKey = -1;
      if(!fullKeyBuffer()) {
        tmpKey = key_pop();
        if(tmpKey >= 0) {
          inKeyBuffer(tmpKey);
        }
      }
    } while(tmpKey >= 0);
  }

  #if defined(JMSHOWCODES_KB0)
    uint16_t tmpxx = 1;
  #endif // JMSHOWCODES_KB0

  #if defined(BUFFER_CLICK_DETECTION)
    kb_buffer_t buffer = {{}, {}, 0, 0};
  #else // !BUFFER_CLICK_DETECTION
    kb_buffer_t buffer = {{}, 0, 0};
  #endif //BUFFER_CLICK_DETECTION

  // Stores 1 Byte in the ring buffer
  //
  // Returns:
  //     BUFFER_FAIL       ring buffer is full. No further byte can be stored
  //     BUFFER_SUCCESS    the byte was stored
  uint8_t inKeyBuffer(uint8_t byte) {
    #if defined(BUFFER_CLICK_DETECTION)
      uint32_t now  = (uint32_t)sys_current_ms();
    #endif // BUFFER_CLICK_DETECTION

    uint8_t  next = ((buffer.write + 1) & BUFFER_MASK);

    if(buffer.read == next) {
      return BUFFER_FAIL;  // full
    }

    // EXPERIMENT Do not allow the same key to be stored multiple times. Only key changes stored.
    if(buffer.data[(buffer.write - 1) & BUFFER_MASK] == byte) {
      #if defined(JMSHOWCODES_KB0)
        char aaa[16];
        sprintf   (aaa,"%2d ",byte);
        showString(aaa,&standardFont, tmpxx++, 1, vmNormal, true, true);
      #endif // JMSHOWCODES_KB0

      return BUFFER_FAIL;  // duplicate
    }
    // END EXPERIMENT

    #if defined(JMSHOWCODES_KB0)
      tmpxx = 1;
    #endif // JMSHOWCODES_KB0

    buffer.data[buffer.write & BUFFER_MASK] = byte;

    #if defined(BUFFER_CLICK_DETECTION)
      buffer.time[buffer.write & BUFFER_MASK] = now;
    #endif // BUFFER_CLICK_DETECTION

    buffer.write = next;

    return BUFFER_SUCCESS;
  }


// Fetches 1 byte from the ring buffer if at least one is ready to be fetched
//
// Returns:
//     BUFFER_FAIL       Fetches 1 byte from the ring buffer if at least one is ready to be fetched
//     BUFFER_SUCCESS    1 byte was fetched
#if defined(BUFFER_CLICK_DETECTION)
  #if defined(BUFFER_KEY_COUNT)
    uint8_t outKeyBuffer(uint8_t *pKey, uint8_t *pKeyCount, uint32_t *pTime, uint32_t *pTimeSpan_1, uint32_t *pTimeSpan_B)
  #else // !BUFFER_KEY_COUNT
    uint8_t outKeyBuffer(uint8_t *pKey, uint32_t *pTime, uint32_t *pTimeSpan_1, uint32_t *pTimeSpan_B)
  #endif // BUFFER_KEY_COUNT
#else // !BUFFER_CLICK_DETECTION
  #if defined(BUFFER_KEY_COUNT)
    uint8_t outKeyBuffer(uint8_t *pKey, uint8_t *pKeyCount)
  #else // !BUFFER_KEY_COUNT
    uint8_t outKeyBuffer(uint8_t *pKey)
  #endif // BUFFER_KEY_COUNT
#endif // BUFFER_CLICK_DETECTION
{
  if(buffer.read == buffer.write) {
    return BUFFER_FAIL;  // empty
  }

  uint8_t actKey = buffer.data[buffer.read];
  *pKey = actKey;
  #if defined(BUFFER_KEY_COUNT)
    uint8_t keyCount = 0;
    if(actKey > 0) {
      keyCount++;
      if(buffer.data[(buffer.read - 2) & BUFFER_MASK] == actKey) {
        keyCount++;
        if(buffer.data[(buffer.read - 4) & BUFFER_MASK] == actKey) {
          keyCount++;
        }
      }
    }
    *pKeyCount = keyCount;
  #endif // BUFFER_KEY_COUNT

  #if defined(BUFFER_CLICK_DETECTION)
    uint32_t actTime = buffer.time[buffer.read];
    *pTime = actTime;
    uint32_t oldTime;

    oldTime = buffer.time[(buffer.read - 1) & BUFFER_MASK];
    if(actTime >= oldTime) {
      *pTimeSpan_1 = actTime - oldTime;
    }
    else {            // protect uint overflow
      *pTimeSpan_1 = actTime;
    }

    #if defined(BUFFER_KEY_COUNT)
      if(keyCount > 2) {
        oldTime = buffer.time[(buffer.read - 4) & BUFFER_MASK];
      }
      else {
    #else // !BUFFER_KEY_COUNT
           {
    #endif // BUFFER_KEY_COUNT
      oldTime = buffer.time[(buffer.read - 2) & BUFFER_MASK];
    }
    if(actTime >= oldTime) {
      *pTimeSpan_B = actTime - oldTime;
    }
    else {            // protect uint overflow
      *pTimeSpan_B = actTime;
    }
  #endif // BUFFER_CLICK_DETECTION

  buffer.read = (buffer.read + 1) & BUFFER_MASK;

  #if defined(BUFFER_CLICK_DETECTION)
    uint8_t detectionResult = outKeyBufferDoubleClick();
    #if defined(JMSHOWCODES_KB1)
      fnDisplayStack(2);
      char aaa[50];
      sprintf(aaa, "k=%2d dT=%5lu:%d", *pByte, *pTimeSpan, (uint8_t)tmpTime);
      showString(aaa, &standardFont, 220, 1, vmNormal, true, true);
    #endif // JMSHOWCODES_KB1
  #endif // BUFFER_CLICK_DETECTION

  return BUFFER_SUCCESS;
}


/* Switching profile, single press, double press and triple press:

SINGLEPRESS:
unknown  waiting   pres    rel
---D3--x_____D2____x---D1--x_
      t-3         t-2     t-1


DOUBLEPRESS:
unknown  waiting   pres    rel    pres
-------x___________x-------x______x-
      t-4    D3   t-3  D2 t-2 D1 t-1


TRIPLEPRESS:
unknown  waiting   pres    rel    pres   rel    pres
-------x___________x-------x______x------x______x-
                          t-4 D3 t-3 D2 t-2 D1 t-1



Circular key buffer:

 Pointers are ready to read and ready to write.
 Pointers are incremented after action.
 Allow writing of 3 keys ahead, into: R+0, R+1, R+2. R+3 is blocked.
 Allow reading of 3 keys up to R=W, which is not read.

 +------------------------------------+
 |   1                                | emptyKeyBuffer, not used
 | R 2 W   R=W: Empty buffer, cannot  | outKeyBuffer
 |   3          read.                 |
 |   4                                |    (Will not pop a key which is not pushed. Can look at 4 places back directly at the stack. )
 +------------------------------------+
 |   1 W   W+1 NOT= R: Space for 1+   | isMoreBufferSpace, used by keyBuffer_pop writing to the buffer only when there is space
 | R 2                                |
 |   3                                |
 |   4                                |
 +------------------------------------+
 |   1                                | inKeyBuffer
 | R 2                                |
 |   3 W   R+1=W: Write buffer full.  |    (must avoid this one, because the key is lost then. Must rather test first and keep the key in the DM42 buffer)
 |   4            Failed. Return      |
 +------------------------------------+

 +-------------------------------------------------------------------------------+
 |   1 W    X     iv.block access to inKeyBuffer, i.e. keep key in DM42 buffer.  |
 | R 2 ov      i.write o and move down v                                         |
 |   3 o v      ii.write o and move down v                                       |
 |   4 o  v      iii.write o and move down v                                     |
 +-------------------------------------------------------------------------------+
*/


// Returns: true if double click
uint8_t outKeyBufferDoubleClick(void) {
  #if defined(BUFFER_CLICK_DETECTION)
    //WARNING! this triggers conseq double click to be 'triple' click but does not check it is the SAME key.
    //Buffer of 4 to short for that. Buffer of 8 sufficient.
    //Can be fixed by having a single byte added to the rolling stack catching the key which was rolled out

    int16_t dTime_1, dTime_2, dTime_3;
    bool_t  doubleclicked, tripleclicked;
    uint8_t outDoubleclick;

    //note Delta Time 1 is the most recent, Delta time 3 is the oldest
    dTime_1 = (uint16_t) buffer.time[(buffer.read-1) & BUFFER_MASK] - (uint16_t) buffer.time[(buffer.read-2) & BUFFER_MASK];
    dTime_2 = (uint16_t) buffer.time[(buffer.read-2) & BUFFER_MASK] - (uint16_t) buffer.time[(buffer.read-3) & BUFFER_MASK];
    dTime_3 = (uint16_t) buffer.time[(buffer.read-3) & BUFFER_MASK] - (uint16_t) buffer.time[(buffer.read-4) & BUFFER_MASK];

    #define D1 150 //400 //space before last press, released time
    #define D2 200 //length of first press, pressed down time

  doubleclicked =
         buffer.data[(buffer.read-1) & BUFFER_MASK] != 0   //check that the last incoming keys was a press, not a release
      && buffer.data[(buffer.read-1) & BUFFER_MASK] == buffer.data[(buffer.read-3) & BUFFER_MASK]   //check that the two last keys are the same, otherwise itis a glisando
      && (dTime_1 > 10 ) && (dTime_1 < D1)                //check no chatter > 10 ms & released width is not longer than limit
      && (dTime_2 > 10 ) && (dTime_2 < D2);               //check no chatter > 10 ms & pressed width is not longer than limit

  if(dTime_1+dTime_2 > D1+D2) {
    doubleclicked = false;
  }

  #define TD1 150 //space before last press, released time
  #define TD2 200 //length of middle press, pressed down time
  #define TD3 150 //space before middle press, i.e. released time after first press

  tripleclicked =
         buffer.data[(buffer.read-1) & BUFFER_MASK] != 0   //check that the last incoming keys was a press, not a release
      && buffer.data[(buffer.read-1) & BUFFER_MASK] == buffer.data[(buffer.read-3) & BUFFER_MASK]   //check that the two last keys are the same, otherwise itis a glisando
      && buffer.data[(buffer.read-1) & BUFFER_MASK] == buffer.data[(buffer.read-5) & BUFFER_MASK]   //check that the previous key is the same. If buffer is 4 long only, it will wrap and not check the first triple press
      && (dTime_1 > 10 ) && (dTime_1 < TD1)                //check no chatter > 10 ms & released width is not longer than limit
      && (dTime_2 > 10 ) && (dTime_2 < TD2)                //check no chatter > 10 ms & pressed width is not longer than limit
      && (dTime_3 > 10 ) && (dTime_3 < TD3);               //check no chatter > 10 ms & pressed width is not longer than limit

  if(dTime_1+dTime_2+dTime_3 > TD1+TD2+TD3) {
    tripleclicked = false;
  }

  if(tripleclicked) {
    outDoubleclick = 3;
    }
  else if(doubleclicked) {
    outDoubleclick = 2;
  }
  else if(buffer.data[(buffer.read-1) & BUFFER_MASK] != 0) {
    outDoubleclick = 1;
  }
  else {
    outDoubleclick = 0;
  }

  #if defined(JMSHOWCODES_KB2)
    char line[50], line1[100];
    fnDisplayStack(2);
    sprintf(line1,"R%-1dW%-1d -1:%-5d -2:%-5d -3:%-5d -4:%-5d  ", (uint16_t)buffer.read,(uint16_t)buffer.write,
      (uint16_t)buffer.time[(buffer.read-1) & BUFFER_MASK], (uint16_t)buffer.time[(buffer.read-2) & BUFFER_MASK],(uint16_t)buffer.time[(buffer.read-3) & BUFFER_MASK],(uint16_t)buffer.time[(buffer.read-4) & BUFFER_MASK]);
    showString(line1, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_T - REGISTER_X), vmNormal, true, true);
    sprintf(line, "B-1:%d %d %d %d", (uint16_t)buffer.data[(buffer.read-1) & BUFFER_MASK], (uint16_t)buffer.data[(buffer.read-2) & BUFFER_MASK], (uint16_t)buffer.data[(buffer.read-3) & BUFFER_MASK], (uint16_t)buffer.data[(buffer.read-4) & BUFFER_MASK]);
    sprintf(line1, "%-16s   D1:%d D2:%d D3:%d    ", line,dTime_1, dTime_2, dTime_3);
    showString(line1, &standardFont, 1, Y_POSITION_OF_REGISTER_X_LINE - REGISTER_LINE_HEIGHT*(REGISTER_Z - REGISTER_X), vmNormal, true, true);
  #endif // JMSHOWCODES_KB2

  #if defined(JMSHOWCODES_KB3)
    char line2[10];
    line2[0] = 0;
    if( outDoubleclick == 1) {
      strcat(line2, "S");
      showString(line2, &standardFont, SCREEN_WIDTH-11, 0, vmNormal, true, true);
    }
    else
    if( outDoubleclick == 2) {
      strcat(line2, "D");
      showString(line2, &standardFont, SCREEN_WIDTH-11, 0, vmNormal, true, true);
    }
    else
    if( outDoubleclick == 3) {
      strcat(line2, "T");
      showString(line2, &standardFont, SCREEN_WIDTH-11, 0, vmNormal, true, true);
    }
    else {
      strcat(line2, " ");
      showString(line2, &standardFont, SCREEN_WIDTH-11, 0, vmNormal, true, true);
      //refreshStatusBar();
    }
  #endif // JMSHOWCODES_KB3

  return outDoubleclick;
#else // !BUFFER_CLICK_DETECTION
  return 255;
#endif // BUFFER_CLICK_DETECTION
}


// Returns:
//     true              ring buffer is full
bool_t fullKeyBuffer(void) {
  return buffer.read == ((buffer.write + 1) & BUFFER_MASK);
}


// Returns:
//     true              ring buffer is empty
bool_t emptyKeyBuffer(void) {
  return buffer.read == buffer.write;
}
#endif // DMCP_BUILD                                                    //^^



//########################################
void fnT_ARROW(uint16_t command) {
  #if !defined(TESTSUITE_BUILD)
    #if defined(TEXT_MULTILINE_EDIT)
      uint16_t ixx;
      uint16_t current_cursor_x_old;
      uint16_t current_cursor_y_old;

      #if defined(PC_BUILD)
        char tmp[200]; sprintf(tmp,"^^^^fnT_ARROW: command=%d current_cursor_x=%d current_cursor_y=%d \n",command,current_cursor_x, current_cursor_y); jm_show_comment(tmp);
      #endif //PC_BUILD

      switch(command) {
        case ITM_T_LEFT_ARROW: /*STD_LEFT_ARROW */
          T_cursorPos = stringPrevGlyph(aimBuffer, T_cursorPos);
          if(T_cursorPos < displayAIMbufferoffset && displayAIMbufferoffset > 0) {
            displayAIMbufferoffset = stringPrevGlyph(aimBuffer, displayAIMbufferoffset);
          }
          break;

        case ITM_T_RIGHT_ARROW: /*STD_RIGHT_ARROW*/
          ixx = T_cursorPos;
          T_cursorPos = stringNextGlyph(aimBuffer, T_cursorPos);
          incOffset();
          break;

        case ITM_T_LLEFT_ARROW: /*STD_FARLEFT_ARROW */
          ixx = 0;
          while(ixx<10) {
            fnT_ARROW(ITM_T_LEFT_ARROW);
            ixx++;
          }
          break;

        case ITM_T_RRIGHT_ARROW: /*STD_FARRIGHT_ARROW*/
          ixx = 0;
          while(ixx<10) {
            fnT_ARROW(ITM_T_RIGHT_ARROW);
            ixx++;
          }
          break;

        case ITM_T_UP_ARROW: /*UP */                       //JMCURSOR try make the cursor upo be more accurate. Add up the char widths...
          ixx = 0;
          current_cursor_x_old = current_cursor_x;
          current_cursor_y_old = current_cursor_y;
          fnT_ARROW(ITM_T_RIGHT_ARROW);
          while(ixx < 75 && (current_cursor_x >= current_cursor_x_old+5 || current_cursor_y == current_cursor_y_old)) {
            fnT_ARROW(ITM_T_LEFT_ARROW);
            showStringEdC43(lines ,displayAIMbufferoffset, T_cursorPos, aimBuffer, 1, -100, vmNormal, true, true, true);  //display up to the cursor
            ixx++;
          }
          break;

        case ITM_T_DOWN_ARROW: /*DN*/
          ixx = 0;
          current_cursor_x_old = current_cursor_x;
          current_cursor_y_old = current_cursor_y;
          fnT_ARROW(ITM_T_LEFT_ARROW);
          while(ixx < 75 && (current_cursor_x+5 <= current_cursor_x_old || current_cursor_y == current_cursor_y_old)) {
            fnT_ARROW(ITM_T_RIGHT_ARROW);
            showStringEdC43(lines ,displayAIMbufferoffset, T_cursorPos, aimBuffer, 1, -100, vmNormal, true, true, true);  //display up to the cursor
            ixx++;

            //printf("###^^^ %d %d %d %d %d\n",ixx,current_cursor_x, current_cursor_x_old, current_cursor_y, current_cursor_y_old);
          }
          break;

        case ITM_UP1: /*HOME */
            T_cursorPos = 0;
            displayAIMbufferoffset = 0;
            break;

        case ITM_DOWN1: /*END*/
            T_cursorPos = stringByteLength(aimBuffer) - 1;
            T_cursorPos = stringNextGlyph(aimBuffer, T_cursorPos);
            fnT_ARROW(ITM_T_RIGHT_ARROW);
            findOffset();
            break;


        default: break;
      }

      //printf(">>> T_cursorPos %d", T_cursorPos);
      if(T_cursorPos > stringNextGlyph(aimBuffer, stringLastGlyph(aimBuffer))) {
        T_cursorPos = stringNextGlyph(aimBuffer, stringLastGlyph(aimBuffer));
      }
      if(T_cursorPos < 0) {
        T_cursorPos = 0;
      }
      //printf(">>> T_cursorPos limits %d\n",T_cursorPos);
    #endif // TEXT_MULTILINE_EDIT
  #endif // !TESTSUITE_BUILD
}


void fnCla(uint16_t unusedButMandatoryParameter) {
  if(calcMode == CM_AIM) {
    //Not using calcModeAim becose some modes are reset which should not be
    aimBuffer[0]=0;
    T_cursorPos = 0;
    nextChar = scrLock;
    xCursor = 1;
    yCursor = Y_POSITION_OF_AIM_LINE + 6;
    cursorFont = &standardFont;
    cursorEnabled = true;
    last_CM=252;
    #if !defined(TESTSUITE_BUILD)
      clearRegisterLine(AIM_REGISTER_LINE, true, true);
      refreshRegisterLine(AIM_REGISTER_LINE);        //JM Execute here, to make sure that the 5/2 line check is done
    #endif // !TESTSUITE_BUILD
    last_CM=253;
  }
  else if(calcMode == CM_EIM) {
    while(xCursor > 0) {
      fnKeyBackspace(0);
    }
    refreshRegisterLine(NIM_REGISTER_LINE);
  }
}


void fnCln(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
   strcpy(aimBuffer,"+0");
   fnKeyBackspace(0);
   setSystemFlag(FLAG_ASLIFT);
   screenUpdatingMode = SCRUPD_AUTO;
//   refreshScreen();
  #endif // !TESTSUITE_BUILD
}


void refreshModeGui(void) {
  if(!tam.mode) {
    switch(calcMode) {
      case CM_AIM:
      case CM_EIM:
        calcModeAimGui();
        break;

      case CM_NORMAL:
        calcModeNormalGui();
        break;

      case CM_PEM:
        if(getSystemFlag(FLAG_ALPHA)) {
          calcModeAimGui();
        }
        else {
          calcModeNormalGui();
        }
        break;
    }
  }
}
