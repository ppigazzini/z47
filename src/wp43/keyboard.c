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

#include "keyboard.h"

#include "assign.h"
#include "bufferize.h"
#include "browsers/asnBrowser.h"
#include "calcMode.h"
#include "charString.h"
#include "config.h"
#include "constants.h"
#include "constantPointers.h"
#include "debug.h"
#include "display.h"
#include "error.h"
#include "flags.h"
#include "hal/gui.h"
#include "items.h"
#include "c43Extensions/jm.h"
#include "c43Extensions/keyboardTweak.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "mathematics/matrix.h"
#include "memory.h"
#include "plotstat.h"
#include "programming/manage.h"
#include "programming/nextStep.h"
#include "programming/programmableMenu.h"
#include "recall.h"
#include "registers.h"
#include "registerValueConversions.h"
#include "screen.h"
#include "softmenus.h"
#include "solver/equation.h"
#include "solver/graph.h"
#include "sort.h"
#include "stack.h"
#include "stats.h"
#include "timer.h"
#include "ui/tam.h"
#include "c43Extensions/xeqm.h"
#include "c43Extensions/addons.h"

#include "c43Extensions/textfiles.h"
#include "c43Extensions/keyboardTweak.h"
#include "c43Extensions/graphText.h"
#include "c43Extensions/xeqm.h"

#if(REAL34_WIDTH_TEST == 1)
  #include "registerValueConversions.h"
#endif // (REAL34_WIDTH_TEST == 1)
#include <string.h>

#include "wp43.h"


#if !defined(TESTSUITE_BUILD)

TO_QSPI static const char bugScreenNonexistentMenu[] = "In function determineFunctionKeyItem: nonexistent menu specified!";
TO_QSPI static const char bugScreenItemNotDetermined[] = "In function determineItem: item was not determined!";

  int16_t determineFunctionKeyItem_C47(const char *data, bool_t shiftF, bool_t shiftG) { //Added itemshift param JM
    int16_t item = ITM_NOP;
    dynamicMenuItem = -1;
    int16_t itemShift = (shiftF ? 6 : (shiftG ? 12 : 0));
    int16_t fn = *(data) - '0' - 1;
    const softmenu_t *sm;
    int16_t row, menuId = softmenuStack[0].softmenuId;
    int16_t firstItem = softmenuStack[0].firstItem;


    #if defined(VERBOSEKEYS)
      printf(">>>>Z 0090 determineFunctionKeyItem       data=|%s| data[0]=%d fn=%d item=%d itemShift=%d (Global) FN_key_pressed=%d\n", data, data[0], fn, item, itemShift, FN_key_pressed);
    #endif // VERBOSEKEYS
    #if defined(PC_BUILD)
      char tmp[200];
      sprintf(tmp,"^^^^determineFunctionKeyItem_C47(%d): itemShift=%d menuId=%d menuItem=%d", fn, itemShift, menuId, -softmenu[menuId].menuItem);
      jm_show_comment(tmp);
    #endif // PC_BUILD

    if(IS_BASEBLANK_(menuId)) {
      return item;
    }

    #pragma GCC diagnostic push
    #pragma GCC diagnostic ignored "-Wimplicit-fallthrough"
#if defined(VERBOSEKEYS)
printf(">>>>Z 0090a determineFunctionKeyItem       -softmenu[menuId].menuItem=%i\n",-softmenu[menuId].menuItem);
#endif // VERBOSEKEYS
    switch(-softmenu[menuId].menuItem) {
      case MNU_MyMenu: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = userMenuItems[dynamicMenuItem].item;
        break;
      }

      case MNU_MyAlpha: {
        if(calcMode != CM_EIM) {
          dynamicMenuItem = firstItem + itemShift + fn;
          item = userAlphaItems[dynamicMenuItem].item;
        }
#if defined(VERBOSEKEYS)
printf(">>>>Z 0091   case MNU_MyAlpha             data=|%s| data[0]=%d item=%d itemShift=%d (Global) FN_key_pressed=%d\n",data,data[0],item,itemShift, FN_key_pressed);
printf(">>>>  0092     dynamicMenuItem=%d\n",dynamicMenuItem);
printf(">>>>  0093     firstItem=%d itemShift=%d fn=%d",firstItem, itemShift, fn);
#endif //VERBOSEKEYS

        break;
      }

      case MNU_DYNAMIC: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = userMenus[currentUserMenu].menuItem[dynamicMenuItem].item;
        break;
      }

      case MNU_PROG: {
        dynamicMenuItem = firstItem + itemShift + fn;
        if(tam.function == ITM_GTOP) {
          item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : ITM_GTOP);
        }
        else {
          item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : MNU_DYNAMIC);
        }
        break;
      }

      case MNU_VAR: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : MNU_DYNAMIC);
        break;
      }

      case MNU_MVAR: {
        dynamicMenuItem = firstItem + itemShift + fn;
        if(tam.mode) {
          item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : MNU_DYNAMIC);
        }
        else if(currentMvarLabel != INVALID_VARIABLE) {
          item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : ITM_SOLVE_VAR);
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER) && dynamicMenuItem == 5) {
          item = ITM_CALC;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER) && dynamicMenuItem == 4) {
          item = ITM_DRAW;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER) && dynamicMenuItem == 3) {
          item = ITM_CPXSLV;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && *getNthString(dynamicSoftmenu[softmenuStack[0].softmenuId].menuContent, dynamicMenuItem) == 0) {
          item = ITM_NOP;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE) && dynamicMenuItem == 5) {
          item = ITM_FPHERE;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE) && dynamicMenuItem == 4) {
          item = ITM_DRAW;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) && dynamicMenuItem == 5) {
          item = ITM_FPPHERE;
        }
        else if((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) && (currentSolverStatus & SOLVER_STATUS_INTERACTIVE) && ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) && dynamicMenuItem == 4) {
          item = ITM_DRAW;
        }
        else if(dynamicMenuItem >= dynamicSoftmenu[menuId].numItems) {
          item = ITM_NOP;
        }
        else if(!(currentSolverStatus & SOLVER_STATUS_INTERACTIVE)) {
          item = MNU_DYNAMIC;
        }
        else if( ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE) && dynamicMenuItem == 2) {
          item = ITM_DRAW;
        }
        else if((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE) {
          item = ITM_Sfdx_VAR;
        }
        else {
          item = ITM_SOLVE_VAR;
        }
        break;
      }

      case MNU_MATRS:
      case MNU_STRINGS:
      case MNU_DATES:
      case MNU_TIMES:
      case MNU_ANGLES:
      case MNU_SINTS:
      case MNU_LINTS:
      case MNU_REALS:
      case MNU_CPXS: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : (tam.mode == TM_DELITM) ? MNU_DYNAMIC : ITM_RCL);
        break;
      }

      case MNU_PROGS: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = (dynamicMenuItem >= dynamicSoftmenu[menuId].numItems ? ITM_NOP : (tam.mode == TM_DELITM) ? MNU_DYNAMIC : ITM_XEQ);
        break;
      }

      case MNU_MENUS: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = ITM_NOP;
        if(dynamicMenuItem < dynamicSoftmenu[menuId].numItems) {
          for(uint16_t i = 0; softmenu[i].menuItem < 0; ++i) {
#if defined(VERBOSEKEYS)
printf(">>>>Z 0093b determineFunctionKeyItem  case MNU_MENUS:     i=%u softmenu[i].menuItem=%i name:=%s\n",i,softmenu[i].menuItem, indexOfItems[-softmenu[i].menuItem].itemCatalogName);
#endif //VERBOSEKEYS
            if(compareString((char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem), indexOfItems[-softmenu[i].menuItem].itemCatalogName, CMP_NAME) == 0) {
              if(tam.mode == TM_DELITM) {
                item = MNU_DYNAMIC;
                tam.value = numberOfUserMenus;
              }
              else {
                item = softmenu[i].menuItem;
#if defined(VERBOSEKEYS)
printf(">>>>Z 0093c determineFunctionKeyItem  item = %i:   name:=%s\n",item, indexOfItems[-item].itemCatalogName);
#endif //VERBOSEKEYS
              }
            }
          }
          for(uint32_t i = 0; i < numberOfUserMenus; ++i) {
            if(compareString((char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem), userMenus[i].menuName, CMP_NAME) == 0) {
              if(tam.mode == TM_DELITM) {
                item = MNU_DYNAMIC;
                tam.value = i;
              }
              else {
                item = -MNU_DYNAMIC;
                currentUserMenu = i;
              }
            }
          }
        }
        break;
      }

      case ITM_MENU: {
        dynamicMenuItem = firstItem + itemShift + fn;
        item = ITM_MENU;
        break;
      }

      case MNU_EQN: {
        if(numberOfFormulae == 0 && (firstItem + itemShift + fn) > 0) {
          break;
        }
        /* fallthrough */
      }

      default: {
        sm = &softmenu[menuId];
        row = min(3, (sm->numItems + modulo(firstItem - sm->numItems, 6))/6 - firstItem/6) - 1;
        if(itemShift/6 <= row && firstItem + itemShift + fn < sm->numItems) {
          item = (sm->softkeyItem)[firstItem + itemShift + fn] % 10000;

          if(item == ITM_PROD_SIGN) {
            item = (getSystemFlag(FLAG_MULTx) ? ITM_DOT : ITM_CROSS);
          }

          if(softmenu[menuId].menuItem == -MNU_ALPHA && calcMode == CM_PEM && item == ITM_ASSIGN) {
            item = ITM_NULL;
          }
        }
      #if defined(VERBOSEKEYS)
      printf(">>>>Z 0094 Fallthrough item=%d \n",item);
      #endif //VERBOSEKEYS
      }
    }

  #if defined(VERBOSEKEYS)
  printf(">>>>Z 0094B    calcMode == %u  data=|%s| data[0]=%d item=%d itemShift=%d (Global) FN_key_pressed=%d\n",calcMode, data,data[0],item,itemShift, FN_key_pressed);
  printf(">>>>  0095     dynamicMenuItem=%d\n",dynamicMenuItem);
  printf(">>>>  0096     firstItem=%d itemShift=%d fn=%d\n",firstItem, itemShift, fn);
  #endif //VERBOSEKEYS

  #pragma GCC diagnostic pop
    if(calcMode == CM_ASSIGN && item != ITM_NOP && item != ITM_NULL) {
      switch(-softmenu[menuId].menuItem) {
        case MNU_PROG:
        case MNU_PROGS: {
          #if defined(VERBOSEKEYS)
          printf("0096a PROG or PROGS: registerno:%s\n", (char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem) );
          printf("0096b %d %d %d\n",findNamedLabel((char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem)), - FIRST_LABEL, + ASSIGN_LABELS);
          #endif //VERBOSEKEYS
          return findNamedLabel((char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem)) - FIRST_LABEL + ASSIGN_LABELS;
        }
        case MNU_VAR:
        case MNU_MATRS:
        case MNU_STRINGS:
        case MNU_DATES:
        case MNU_TIMES:
        case MNU_ANGLES:
        case MNU_SINTS:
        case MNU_LINTS:
        case MNU_REALS:
        case MNU_CPXS: {
          return findNamedVariable((char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem)) - FIRST_NAMED_VARIABLE + ASSIGN_NAMED_VARIABLES;
        }
        case MNU_MENUS: {
          if(item == -MNU_DYNAMIC) {
            for(int32_t i = 0; i < numberOfUserMenus; ++i) {
              if(compareString((char *)getNthString(dynamicSoftmenu[menuId].menuContent, dynamicMenuItem), userMenus[i].menuName, CMP_NAME) == 0) {
                return ASSIGN_USER_MENU - i;
              }
            }
            displayBugScreen(bugScreenNonexistentMenu);
#if defined(VERBOSEKEYS)
printf(">>>>  0086 item=%d \n",item);
#endif //VERBOSEKEYS
            return item;
          }
          else {
#if defined(VERBOSEKEYS)
printf(">>>>  0087 item=%d \n",item);
#endif //VERBOSEKEYS
            return item;
          }
        }
        default: {
#if defined(VERBOSEKEYS)
printf(">>>>  0088 item=%d \n",item);
#endif //VERBOSEKEYS
          return item;
      }
    }
    }
    else {
#if defined(VERBOSEKEYS)
printf(">>>>  0089 item=%d \n",item);
#endif //VERBOSEKEYS
      return item;
    }
  }



  #if defined(PC_BUILD)
    void btnFnClicked(GtkWidget *notUsed, gpointer data) {
//      GdkEvent mouseButton; //JM
//      mouseButton.button.button = 1; //JM

//      btnFnPressed(notUsed, &mouseButton, data);
//      btnFnReleased(notUsed, &mouseButton, data);
#if defined(VERBOSEKEYS)
printf(">>>>Z 0070 btnFnClicked data=|%s| data[0]=%d\n",(char*)data, ((char*)data)[0]);
#endif //VERBOSEKEYS
      executeFunction(data, 0);
    }
#endif // PC_BUILD

#if defined(DMCP_BUILD)
    void btnFnClicked(void *unused, void *data) {
//      btnFnPressed(data); //JM
//      btnFnReleased(data); //JM
      executeFunction(data, 0);
    }
#endif // DMCP_BUILD



  #if defined(PC_BUILD)
    void btnFnClickedP(GtkWidget *notUsed, gpointer data) { //JM Added this portion to be able to go to NOP on emulator
      GdkEvent mouseButton;
      mouseButton.button.button = 1;
      mouseButton.type = 0;
      btnFnPressed(notUsed, &mouseButton, data);
    }

    void btnFnClickedR(GtkWidget *notUsed, gpointer data) { //JM Added this portion to be able to go to NOP on emulator
      GdkEvent mouseButton;
      mouseButton.button.button = 1;
      mouseButton.type = 0;
      btnFnReleased(notUsed, &mouseButton, data);
    }
  #endif // PC_BUILD


    void execAutoRepeat(uint16_t key) {
    #if defined(DMCP_BUILD)
      char charKey[6];
      bool_t f = shiftF;
      bool_t g = shiftG;
      uint8_t origScreenUpdatingMode = screenUpdatingMode;
      sprintf(charKey, "%02d", key -1);

      fnTimerStart(TO_AUTO_REPEAT, key, KEY_AUTOREPEAT_PERIOD);

      btnClicked(NULL, (char *)charKey);
      screenUpdatingMode = origScreenUpdatingMode;
      //btnPressed(charKey);
      shiftF = f;
      shiftG = g;
      refreshLcd();
      lcd_refresh_dma();
    #endif // DMCP_BUILD
    }


    //Closing catalog menu only if it is a real catalog entry.
    //  The previous system closes a normal menu if the CAT main menu happens to be in one of the older menu slots in the menu stack
    //    and that happens if you call CAT and then say CLK or any other menu and runn a command from there. Then CAT is present and the menu closed after the command executed.

    static void closeAllCatalogMenus(void) {
        switch(-softmenu[softmenuStack[0].softmenuId].menuItem) {
          //          case MNU_CATALOG :  //option to include if we need to close the actual CAT menu too, i.e. jump back to before CAT (like 42S does
          case MNU_VARS :
          case MNU_PROGS :
          case MNU_CHARS :
          case MNU_ANGLES :
          case MNU_CPXS :
          case MNU_DATES :
          case MNU_FCNS :
          case MNU_LINTS :
          case MNU_MATRS :
          case MNU_MENUS :
          case MNU_REALS :
          case MNU_SINTS :
          case MNU_STRINGS :
          case MNU_TIMES :
          case MNU_ALPHA_OMEGA :
          case MNU_ALPHAMISC :
          case MNU_ALPHA :
          case MNU_CONST : {
            popSoftmenu();
            //         closeAllCatalogMenus(); //Option to recurse and close more than one menu level until all the CAT related menus are out
          }
          default: break;
        }
      }



    static void _closeCatalog(void) {
      bool_t inCatalog = false;
      for(int i = 0; i < SOFTMENU_STACK_SIZE; ++i) {
        if(softmenu[softmenuStack[i].softmenuId].menuItem == -MNU_CATALOG) {
          inCatalog = true;
          break;
        }
      }
      if(inCatalog || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_CONST) {
        switch(-softmenu[softmenuStack[0].softmenuId].menuItem) {
          case MNU_TAM:
          case MNU_TAMNONREG:
          case MNU_TAMCMP:
          case MNU_TAMSTORCL:
          case MNU_TAMFLAG:
          case MNU_TAMSHUFFLE:
          case MNU_TAMLABEL:
          case ITM_DELITM: {
            // TAM menus are processed elsewhere
            break;
          }
          default: {
            leaveAsmMode();
            //popSoftmenu();        //removed in favour of the more selective closing
            closeAllCatalogMenus();

        }
      }
    }
  }



bool_t lastshiftF = false;
bool_t lastshiftG = false;
bool_t lowercaseselected;

  static void processAimInput(int16_t item) {
    int16_t item1 = 0;
#if defined(PC_BUILD)
    char tmp[200]; sprintf(tmp,"^^^^processAimInput:AIM %d nextChar=%d",item,nextChar); jm_show_comment(tmp);
    #if defined(PAIMDEBUG)
      printf("%s, |%s|\n",tmp,aimBuffer);
    #endif //PAIMDEBUG
#endif //PC_BUILD

    if(scrLock != NC_NORMAL) {
      nextChar = scrLock;
    }

    if(keyReplacements(item, &item1, numLock, lastshiftF, lastshiftG) > 0) {  //JMvv
      if(item1 > 0) {
        addItemToBuffer(item1);
        #if defined(PAIMDEBUG)
          printf("---#K %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
        keyActionProcessed = true;
      }
    }

    else if(lowercaseselected && (ITM_A <= item && item <= ITM_Z)) {
      addItemToBuffer(item + 26);
        #if defined(PAIMDEBUG)
          printf("---#J %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(!lowercaseselected && (ITM_A <= item && item <= ITM_Z)) {  //JM
      addItemToBuffer(item);
        #if defined(PAIMDEBUG)
          printf("---#I %d +%s+\n",keyActionProcessed, aimBuffer);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(!lowercaseselected && (ITM_a <= item && item <= ITM_z)) {  //JM
      addItemToBuffer(item - 26);
        #if defined(PAIMDEBUG)
          printf("---#H %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(lowercaseselected && (ITM_a <= item && item <= ITM_z)) {  //JM
      addItemToBuffer(item);
        #if defined(PAIMDEBUG)
          printf("---#G %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(item == ITM_COLON || item == ITM_COMMA || item == ITM_QUESTION_MARK || item == ITM_SPACE || item == ITM_UNDERSCORE) {  //JM vv DIRECT LETTERS
      addItemToBuffer(item);
        #if defined(PAIMDEBUG)
          printf("---#F %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(lowercaseselected && ((ITM_ALPHA <= item && item <= ITM_OMEGA) || (ITM_QOPPA <= item && item <= ITM_SAMPI))) {  //JM GREEK
      addItemToBuffer(item /* +(ITM_alpha - ITM_ALPHA) */); //JM Remove the ability to shift to lower cap greek for the reason that the limited greek on the keyboard are defined per case, not generic
        #if defined(PAIMDEBUG)
          printf("---#E %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(!lowercaseselected && ((ITM_ALPHA <= item && item <= ITM_OMEGA) || (ITM_QOPPA <= item && item <= ITM_SAMPI))) {  //JM GREEK
      addItemToBuffer(item);
        #if defined(PAIMDEBUG)
          printf("---#D %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(item == ITM_DOWN_ARROW) {
      if(nextChar == NC_NORMAL) nextChar = NC_SUBSCRIPT; else if(nextChar == NC_SUPERSCRIPT) nextChar = NC_NORMAL; //JM stack the SUP/NORMAL/SUB
        #if defined(PAIMDEBUG)
          printf("---#C %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(item == ITM_UP_ARROW) {
      if(nextChar == NC_NORMAL) nextChar = NC_SUPERSCRIPT; else if(nextChar == NC_SUBSCRIPT) nextChar = NC_NORMAL; //JM stack the SUP/NORMAL/SUB
        #if defined(PAIMDEBUG)
          printf("---#B %d\n",keyActionProcessed);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    else if(indexOfItems[item].func == addItemToBuffer) {
      addItemToBuffer(item);
        #if defined(PAIMDEBUG)
          printf("---#A %d\n",keyActionProcessed);
          printf("###---> 3, |%s|\n",aimBuffer);
        #endif //PAIMDEBUG
      keyActionProcessed = true;
    }

    if(keyActionProcessed) {
      refreshScreen();
    }

  #if defined(PC_BUILD)
    sprintf(tmp,"^^^^processAimInput:AIM:end %d, processed %d",item,keyActionProcessed); jm_show_comment(tmp);
    #if defined(PAIMDEBUG)
      printf("%s, |%s|\n",tmp,aimBuffer);
    #endif //PAIMDEBUG
  #endif //PC_BUILD
  }






  uint8_t asnKey[4] = {0, 0, 0, 0};


  #if defined(PC_BUILD)
    void btnFnPressed(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
      if(event->type == GDK_DOUBLE_BUTTON_PRESS || event->type == GDK_TRIPLE_BUTTON_PRESS) { // return unprocessed for double or triple click
        return;
      }
      if(event->button.button == 2) { // Middle click
        shiftF = true;
        shiftG = false;
      }
      if(event->button.button == 3) { // Right click
        shiftF = false;
        shiftG = true;
      }
  #endif // PC_BUILD
  #if defined(DMCP_BUILD)
    void btnFnPressed(void *data) {
  #endif // DMCP_BUILD

#if defined(VERBOSEKEYS)
printf(">>>>Z 0010 btnFnPressed SET FN_key_pressed            ; data=|%s| data[0]=%d shiftF=%d shiftG=%d\n",(char*)data, ((char*)data)[0],shiftF, shiftG);
#endif //VERBOSEKEYS
      temporaryInformation = TI_NO_INFO;
      FN_key_pressed = *((char *)data) - '0' + 37;  //to render 38-43, as per original keypress

      asnKey[0] = ((uint8_t *)data)[0];
      asnKey[1] = 0;

      if(programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED) {
        setLastKeyCode((*((char *)data) - '0') + 37);
      }
      else {
        lastKeyCode = 0;
      }

      if(programRunStop == PGM_PAUSED) {
        programRunStop = PGM_KEY_PRESSED_WHILE_PAUSED;
        return;
      }


      lastshiftF = shiftF;
      lastshiftG = shiftG;


      if(tam.mode == TM_KEY && !tam.keyInputFinished) {
        // not processed here
        return;
      }
      if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && !(tam.alpha && tam.mode != TM_NEWMENU)) {

      #if defined(VERBOSEKEYS)
        printf(">>>>Z 0011 btnFnPressed >>determineFunctionKeyItem_C47; data=|%s| data[0]=%d shiftF=%d shiftG=%d\n", (char*)data, ((char*)data)[0], shiftF, shiftG);
      #endif //VERBOSEKEYS
              int16_t item = determineFunctionKeyItem_C47((char *)data, shiftF, shiftG);
      #if defined(VERBOSEKEYS)
        printf(">>>>Z 011a btnFnPressed >>determineFunctionKeyItem_C47; data=|%s| data[0]=%d shiftF=%d shiftG=%d\n", (char*)data, ((char*)data)[0], shiftF, shiftG);
      #endif //VERBOSEKEYS

      #pragma GCC diagnostic push
      #pragma GCC diagnostic ignored "-Wimplicit-fallthrough"
        switch(-softmenu[softmenuStack[0].softmenuId].menuItem) {
        case MNU_MENUS: {
            if(item <= ASSIGN_USER_MENU) {
              currentUserMenu = ASSIGN_USER_MENU - item;
              item = -MNU_DYNAMIC;
            }
            /* fallthrough */
        }
          case MNU_CATALOG:
          case MNU_CHARS:
          case MNU_PROGS:
          case MNU_VARS: {
//            #if(FN_KEY_TIMEOUT_TO_NOP == 1)
//              showFunctionName(item, 1000, "SF:A"); // 1000ms = 1s
//            #else // (FN_KEY_TIMEOUT_TO_NOP != 1)
              showFunctionNameItem = item;
//            #endif // (FN_KEY_TIMEOUT_TO_NOP == 1)
            break;
        }
        default: {
            updateAssignTamBuffer();
        }
      }
      #pragma GCC diagnostic pop
        _closeCatalog();
      }
      else if(calcMode != CM_REGISTER_BROWSER && calcMode != CM_FLAG_BROWSER && calcMode != CM_ASN_BROWSER && calcMode != CM_FONT_BROWSER) {

        #if defined(VERBOSEKEYS)
        printf(">>>>Z 0012 btnFnPressed >>determineFunctionKeyItem_C47; data=|%s| data[0]=%d shiftF=%d shiftG=%d\n",(char*)data, ((char*)data)[0],shiftF, shiftG);
        #endif //VERBOSEKEYS

        int16_t item = determineFunctionKeyItem_C47((char *)data, shiftF, shiftG);
/*
        if(shiftF || shiftG) {
          screenUpdatingMode &= ~SCRUPD_MANUAL_SHIFT_STATUS;
          clearShiftState();
        }

        shiftF = false;
        shiftG = false;
*/
        #if defined(VERBOSEKEYS)
        printf(">>>>Z 0012 btnFnPressed >determineFunctionKeyItem_C47?; data=|%s| data[0]=%d shiftF=%d shiftG=%d\n",(char*)data, ((char*)data)[0],shiftF, shiftG);
        #endif //VERBOSEKEYS

        if( (item != ITM_NOP && item != ITM_NULL) ||                  //JM allow entry into statemachine if item=blank (NOP) but f(item) or g(item) is not blank
            (determineFunctionKeyItem_C47((char *)data, true, false) != ITM_NOP && determineFunctionKeyItem_C47((char *)data, true, false) != ITM_NULL) ||
            (determineFunctionKeyItem_C47((char *)data, false, true) != ITM_NOP && determineFunctionKeyItem_C47((char *)data, false, true) != ITM_NULL)
           ) {

        #if defined(VERBOSEKEYS)
        printf(">>>>Z 0013 btnFnPressed >>btnFnPressed_StateMachine; data=|%s| data[0]=%d shiftF=%d shiftG=%d\n",(char*)data, ((char*)data)[0],shiftF, shiftG);
        #endif //VERBOSEKEYS

          lastErrorCode = 0;
          btnFnPressed_StateMachine(NULL, data);    //JM This calls original state analysing btnFnPressed routing, which is now renamed to "statemachine" in keyboardtweaks
                                                    // JM never allow a function key to directly enter into a buffer - always via the key detection btnFnPressed_StateMachine
/*
          if(calcMode != CM_ASSIGN && indexOfItems[item].func == addItemToBuffer) {
            // If we are in the catalog then a normal key press should affect the Alpha Selection Buffer to choose
            // an item from the catalog, but a function key press should put the item in the AIM (or TAM) buffer
            // Use this variable to distinguish between the two
            if(calcMode == CM_PEM && !tam.mode) {
              if(getSystemFlag(FLAG_ALPHA)) {
                pemAlpha(item);
              }
              else {
                addStepInProgram(item);
              }
              hourGlassIconEnabled = false;
            }
            else {
              fnKeyInCatalog = 1;
              addItemToBuffer(item);
              fnKeyInCatalog = 0;
            }
            if(calcMode == CM_EIM && !tam.mode) {   //this EIM portion moved to after release, to allow longpress and double press
              while(softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_EQ_EDIT) {
                popSoftmenu();
              }
            }
            _closeCatalog();
            refreshScreen();
          }

          else {
            #if(FN_KEY_TIMEOUT_TO_NOP == 1)
              showFunctionName(item, 1000); // 1000ms = 1s
            #else // (FN_KEY_TIMEOUT_TO_NOP != 1)
              showFunctionNameItem = item;
            #endif // (FN_KEY_TIMEOUT_TO_NOP == 1)
          }
*/
        }
        else {
          showFunctionNameItem = ITM_NOP;
        }
      }
    }





  static bool_t _assignToMenu(uint8_t *data) {
    switch(-softmenu[softmenuStack[0].softmenuId].menuItem) {
      case MNU_MyMenu: {
        assignToMyMenu((*data - '1') + (shiftG ? 12 : shiftF ? 6 : 0));
        calcMode = previousCalcMode;
        shiftF = shiftG = false;
        _closeCatalog();
        refreshScreen();
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return true;
      }
      case MNU_MyAlpha: {
        assignToMyAlpha((*data - '1') + (shiftG ? 12 : shiftF ? 6 : 0));
        calcMode = previousCalcMode;
        shiftF = shiftG = false;
        _closeCatalog();
        refreshScreen();
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return true;
      }
      case MNU_DYNAMIC: {
        assignToUserMenu((*data - '1') + (shiftG ? 12 : shiftF ? 6 : 0));
        calcMode = previousCalcMode;
        shiftF = shiftG = false;
        _closeCatalog();
        refreshScreen();
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return true;
      }
      case MNU_CATALOG:
      case MNU_ALPHA: //JM
      case MNU_CHARS:
      case MNU_PROGS:
      case MNU_VARS:
      case MNU_MENUS: {
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return false;
      }
      default: {
        displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        #if defined(PC_BUILD)
          moreInfoOnError("In function _assignToMenu:", "the menu", indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemCatalogName, "is write-protected.");
        #endif // PC_BUILD
        calcMode = previousCalcMode;
        shiftF = shiftG = false;
        _closeCatalog();
        refreshScreen();
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return true;
      }
    }
  }

bool_t lastUserMode = false;
int16_t lastItem = 0;

  #if defined(PC_BUILD)
    void btnFnReleased(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
  #endif // PC_BUILD
  #if defined(DMCP_BUILD)
    void btnFnReleased(void *data) {
  #endif // DMCP_BUILD
    if(programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED) {
      programRunStop = PGM_RESUMING;
      screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
      return;
    }

    if(calcMode != CM_REGISTER_BROWSER && calcMode != CM_FLAG_BROWSER && calcMode != CM_ASN_BROWSER && calcMode != CM_FONT_BROWSER) {
      if(tam.mode == TM_KEY && !tam.keyInputFinished) {
        if(tam.digitsSoFar == 0) {
          switch(((char *)data)[0]) {
            case '1': {
              tamProcessInput(shiftG ? ITM_1 :                  ITM_0);
              tamProcessInput(shiftG ? ITM_3 : shiftF ? ITM_7 : ITM_1);
              break;
            }
            case '2': {
              tamProcessInput(shiftG ? ITM_1 :                  ITM_0);
              tamProcessInput(shiftG ? ITM_4 : shiftF ? ITM_8 : ITM_2);
              break;
            }
            case '3': {
              tamProcessInput(shiftG ? ITM_1 :                  ITM_0);
              tamProcessInput(shiftG ? ITM_5 : shiftF ? ITM_9 : ITM_3);
              break;
            }
            case '4': {
              tamProcessInput(     (shiftG || shiftF) ? ITM_1 : ITM_0);
              tamProcessInput(shiftG ? ITM_6 : shiftF ? ITM_0 : ITM_4);
              break;
            }
            case '5': {
              tamProcessInput(     (shiftG || shiftF) ? ITM_1 : ITM_0);
              tamProcessInput(shiftG ? ITM_7 : shiftF ? ITM_1 : ITM_5);
              break;
            }
            case '6': {
              tamProcessInput(     (shiftG || shiftF) ? ITM_1 : ITM_0);
              tamProcessInput(shiftG ? ITM_8 : shiftF ? ITM_2 : ITM_6);
              break;
            }
          }
          shiftF = shiftG = false;
          refreshScreen();
        }
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return;
      }

      if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && !(tam.alpha && tam.mode != TM_NEWMENU)) {
        if(!(previousCalcMode == CM_AIM && ((uint8_t *)data)[0] == '6')) {       //prevent "ALPHA" on F6 to be overwritten
          if(_assignToMenu((uint8_t *)data)) {
            if(previousCalcMode == CM_AIM) {         //vvJM btnFnReleased
              showSoftmenu(-MNU_ALPHA);              //
              refreshScreen();                       //
            }                                        //^^JM
            return;
          }
        } else {
          return;
        }
      }


      btnFnReleased_StateMachine(NULL, data);            //This function does the longpress differentiation, and calls ExecuteFunctio below, via fnbtnclicked
    }

    fnTimerStop(TO_3S_CTFF);      //dr
    fnTimerStop(TO_CL_LONG);      //dr
  }






  /********************************************//**
   * \brief Executes one function from a softmenu
   * \return void
   ***********************************************/
  void executeFunction(const char *data, int16_t item_) {
    int16_t item = ITM_NOP;

      #if defined(VERBOSEKEYS)
        printf("keyboard.c: executeFunction %i (beginning of executeFunction): %i, %s tam.mode=%i calcMode=%u aimBuffer=%s\n", item, softmenu[softmenuStack[0].softmenuId].menuItem, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName, tam.mode, calcMode, aimBuffer);
      #endif //VERBOSEKEYS


    if(calcMode != CM_REGISTER_BROWSER && calcMode != CM_FLAG_BROWSER && calcMode != CM_ASN_BROWSER && calcMode != CM_FONT_BROWSER) {

      if(data[0] == 0) { item = item_;

      }
      else {

        #if defined(VERBOSEKEYS)
        printf(">>>> R000A >>determineFunctionKeyItem_C47 %d |%s| shiftF=%d, shiftG=%d tam.mode=%i\n",item, data, shiftF, shiftG, tam.mode);
        #endif //VERBOSEKEYS

        item = determineFunctionKeyItem_C47((char *)data, shiftF, shiftG); }

        #if defined(VERBOSEKEYS)
        printf(">>>> R000B                                %d |%s| shiftF=%d, shiftG=%d tam.mode=%i\n",item, data, shiftF, shiftG, tam.mode);
        #endif //VERBOSEKEYS

        #if defined(PC_BUILD)
          printf(">>>Function selected: executeFunction data=|%s| f=%d g=%d tam.mode=%i\n",(char *)data, shiftF, shiftG, tam.mode);
          if(item<0)  printf("    item=%d=%s f=%d g=%d\n",item,indexOfItems[-item].itemCatalogName, shiftF, shiftG);
          if(item>=0) printf("    item=%d=%s f=%d g=%d\n",item,indexOfItems[item].itemCatalogName, shiftF, shiftG);
        #endif //PC_BUILD

        resetShiftState();                               //shift cancelling delayed to this point after state machine

        #if defined(VERBOSEKEYS)
        printf(">>>> R000C                                %d |%s| shiftF=%d, shiftG=%d tam.mode=%i\n",item, data, shiftF, shiftG, tam.mode);
        #endif //VERBOSEKEYS


//TOCHECK: JM Changed showFunctionNameItem to item below, due to something 43S did to the showfunction sequencing
//Problem below: Execution of softkeys does not work when this WP43 change (showFunctionNameItem) is done. Commented out.

      if(/*showFunctionNameItem*/item != 0) {
/* //JM vv Rmove the possibility for error by removing code that may conflict with the state machine
        item = showFunctionNameItem;
      #if(FN_KEY_TIMEOUT_TO_NOP == 1)
        hideFunctionName();
      #else // FN_KEY_TIMEOUT_TO_NOP != 1
*/
        showFunctionNameItem = 0;
/*
      #endif // FN_KEY_TIMEOUT_TO_NOP == 1
*/
        if(calcMode != CM_CONFIRMATION && data[0] != 0 && !running_program_jm) { //JM data is used if operation is from the real keyboard. item is used directly if called from XEQM
          lastErrorCode = 0;

          if(calcMode != CM_PEM && item == -MNU_Sfdx) {
            tamEnterMode(MNU_Sfdx);
            refreshScreen();
            screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
            return;
          }
          else if(calcMode != CM_PEM && item == ITM_INTEGRAL) {
            reallyRunFunction(item, currentSolverVariable);
            refreshScreen();
            screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
            return;
          }
          else if(item < 0) { // softmenu
            if(calcMode == CM_ASSIGN && itemToBeAssigned == 0 && softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_MENUS) {
              itemToBeAssigned = item;
            }
            else {
              #if defined(VERBOSEKEYS)
                printf(">>>Function: executeFunction showSoftmenu(%d)\n",item);
              #endif //VERBOSEKEYS
              showSoftmenu(item);
              if(item == -MNU_ALPHA) {
                fnAim(0);
              }
              if((item == -MNU_Solver || item == -MNU_Sf || item == -MNU_1STDERIV || item == -MNU_2NDDERIV) && lastErrorCode != 0) {
                popSoftmenu();
                currentSolverStatus &= ~SOLVER_STATUS_INTERACTIVE;
                currentSolverStatus &= ~SOLVER_STATUS_EQUATION_MODE;
              }
            }
            refreshScreen();
            screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
            return;
          }
          if(tam.mode && catalog && (tam.digitsSoFar || tam.function == ITM_BESTF || tam.function == ITM_CNST || (!tam.indirect && (tam.mode == TM_VALUE || tam.mode == TM_VALUE_CHB || (tam.mode == TM_KEY && !tam.keyInputFinished))))) {
            // disabled
          }
          else if(tam.function == ITM_GTOP && catalog == CATALOG_PROG) {
            runFunction(item);
            tamLeaveMode();
            hourGlassIconEnabled = false;
            _closeCatalog();
            refreshScreen();
            screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
            return;
          }
          else if(calcMode == CM_PEM && catalog && catalog != CATALOG_MVAR && (!tam.mode || tam.function != ITM_CLP)) { // TODO: is that correct
            fnKeyInCatalog = 1;
            if(indexOfItems[item].func == fnGetSystemFlag && (tam.mode == TM_FLAGR || tam.mode == TM_FLAGW) && !tam.indirect) {
              tam.value = (indexOfItems[item].param & 0xff);
              tam.alpha = true;
              addStepInProgram(tamOperation());
              tamLeaveMode();
            }
            else if(tam.mode) {
              const char *itmLabel = dynmenuGetLabel(dynamicMenuItem);
              uint16_t nameLength = stringByteLength(itmLabel);
              xcopy(aimBuffer, itmLabel, nameLength + 1);
              tam.alpha = true;
              addStepInProgram(tamOperation());
              tamLeaveMode();
            }
            else {
              #if defined(VERBOSEKEYS)
                printf(">>>Function: executeFunction runFunction(%d)\n",item);
              #endif //VERBOSEKEYS
              runFunction(item);
            }
            hourGlassIconEnabled = false;
            _closeCatalog();
            fnKeyInCatalog = 0;
            refreshScreen();
            screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
            return;
          }
          else if(calcMode == CM_PEM && !getSystemFlag(FLAG_ALPHA) && (item == ITM_toINT || item == ITM_HASH_JM)) {
            if(aimBuffer[0]!=0) {
              pemAddNumber(ITM_toINT);
              screenUpdatingMode &= ~SCRUPD_MANUAL_STACK;
              refreshScreen();
              return;
            } else {
              //no action, continue to insert the command
            }
          }


          #if defined(VERBOSEKEYS)
          printf(">>>> R000D                                %d |%s| shiftF=%d, shiftG=%d tam.mode=%i\n",item, data, shiftF, shiftG, tam.mode);
          #endif //VERBOSEKEYS

          // If we are in the catalog then a normal key press should affect the Alpha Selection Buffer to choose
          // an item from the catalog, but a function key press should put the item in the AIM (or TAM) buffer
          // Use this variable to distinguish between the two
          fnKeyInCatalog = 1;
          if(tam.mode && catalog && (tam.digitsSoFar || tam.function == ITM_BESTF || tam.function == ITM_CNST || (!tam.indirect && (tam.mode == TM_VALUE || tam.mode == TM_VALUE_CHB)))) {
            // disabled
          }
          else if(tam.mode && (!tam.alpha || isAlphabeticSoftmenu())) {
            bool_t isInConfig = tam.mode == TM_FLAGW && softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_SYSFL;   //JM Do not drop out of SYSFLG

            addItemToBuffer(item);

            if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_MODE && isInConfig && item != ITM_EXIT1 && item != ITM_BACKSPACE) { //JM do not drop out of SYSFLG
              fnCFGsettings(0);       //JM
            }                         //JM
          }
  //          else if((calcMode == CM_NORMAL || calcMode == CM_AIM) && isAlphabeticSoftmenu()) {
  //            if(calcMode == CM_NORMAL) {
  //              fnAim(NOPARAM);
  //            }
  //            addItemToBuffer(item);
  //JM this is handled later
  //          }

          else if(calcMode == CM_EIM && ((catalog && catalog != CATALOG_MVAR) ||
                  ( softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQ_EDIT &&                       //Allow only EIM enabled functions through to be added as text
                    item != ITM_EQ_LEFT && item != ITM_EQ_RIGHT && item != CHR_num && item != CHR_case &&
                    (indexOfItems[item].status & EIM_STATUS) == EIM_ENABLED
                    )
                  ))  {
            addItemToBuffer(item);
            while(softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_EQ_EDIT) {
              popSoftmenu();
            }
          }
          else if((calcMode == CM_NORMAL || calcMode == CM_NIM) && (ITM_0<=item && item<=ITM_F) && (!catalog || catalog == CATALOG_MVAR)) {
            addItemToNimBuffer(item);
          }
          else if((calcMode == CM_NIM) && ((item==ITM_DRG || item == ITM_DMS2 || item == ITM_dotD) && !catalog)) {   //JM
            addItemToNimBuffer(item);
          }                                                                                      //JM
          else if(calcMode == CM_MIM && softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_M_EDIT && (item != ITM_CC && item != ITM_op_j && item != ITM_op_j_pol)) { //JM added ITM_CC to let it work in matrix edit
            addItemToBuffer(item);
          }
          else if(item > 0) { // function
            if(calcMode == CM_NORMAL && (
                (lastIntegerBase ==  2 && item == ITM_2BIN) ||
                (lastIntegerBase ==  8 && item == ITM_2OCT) ||
                (lastIntegerBase == 10 && item == ITM_2DEC) ||
                (lastIntegerBase == 16 && item == ITM_2HEX)    )) {
              lastIntegerBase = 0;
              screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
              goto noMoreToDo;
            }
            if(calcMode == CM_NIM && (item != ITM_CC && item != ITM_op_j && item != ITM_op_j_pol) && item!=ITM_HASH_JM && item!=ITM_toHMS && item!=ITM_ms) {  //JMNIM Allow NIM not closed, so that JMNIM can change the bases without ierrors thrown
              closeNim();
              if(calcMode != CM_NIM) {
                if(indexOfItems[item].func == fnConstant) {
                  setSystemFlag(FLAG_ASLIFT);
                }
              }
            }
            if(calcMode == CM_AIM && !(isAlphabeticSoftmenu() || isJMAlphaOnlySoftmenu())) {
              closeAim();
            }
            if(tam.alpha && calcMode != CM_ASSIGN && tam.mode != TM_NEWMENU &&
              !( (tam.mode==TM_STORCL || tam.mode==TM_LABEL || tam.mode == TM_M_DIM || tam.mode == TM_REGISTER || tam.mode == TM_CMP)
                  && (item == CHR_num || item == CHR_case) )
              ) {
              tamLeaveMode();
            }

            #if defined(VERBOSEKEYS)
            printf(">>>> R000E                                %d |%s| shiftF=%d, shiftG=%d tam.mode=%i\n",item, data, shiftF, shiftG, tam.mode);
            #endif //VERBOSEKEYS

            if(lastErrorCode == 0) {
              if(temporaryInformation == TI_VIEW) {
                temporaryInformation = TI_NO_INFO;
                updateMatrixHeightCache();
              }
              else {
                temporaryInformation = TI_NO_INFO;
              }
              if(programRunStop == PGM_WAITING) {
                programRunStop = PGM_STOPPED;
              }
              if(calcMode == CM_ASSIGN && itemToBeAssigned == 0 && item != ITM_NOP) {
                if(tam.alpha) {
                  processAimInput(item);
                  if(stringGlyphLength(aimBuffer) > 6) {
                    assignLeaveAlpha();
                    assignGetName1();
                  }
                }
                else if(item == ITM_AIM) { // in case α is already assigned
                  assignEnterAlpha();
                  keyActionProcessed = true;
                }
                else {
                  itemToBeAssigned = item;

                  if(previousCalcMode == CM_AIM) {                            //JMvv close menu to allow only one charac
                    switch(-softmenu[softmenuStack[0].softmenuId].menuItem) {
                      case MNU_ALPHAINTL:
                      case MNU_ALPHA_OMEGA:
                      case MNU_ALPHAMATH:
                      case MNU_MyAlpha:
                      case MNU_ALPHAMISC:
                      case MNU_alpha_omega:
                      case MNU_ALPHAintl: {
                        popSoftmenu();
                        showSoftmenu(-MNU_MyAlpha); //push MyAlpha in case ALPHA is up (likely)
                      }
                      default:;
                    }
                  }                           //JM^^                          //JM^^
                }
              }
              else if(calcMode == CM_ASSIGN && tam.alpha && tam.mode != TM_NEWMENU && item != ITM_NOP) {
                processAimInput(item);
                if(stringGlyphLength(aimBuffer) > 6) {
                  assignLeaveAlpha();
                  assignGetName2();
                }
              }
              else {
                #if defined(VERBOSEKEYS)
                  printf("keyboard.c: executeFunction %i (before runfunction): %i, %s tam.mode=%i\n", item, softmenu[softmenuStack[0].softmenuId].menuItem, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName, tam.mode);
                #endif //VERBOSEKEYS

                runFunction(item);

                if(calcMode == CM_EIM && !tam.mode) {
                  switch (-softmenu[softmenuStack[0].softmenuId].menuItem) {
                    //case MNU_ALPHAINTL:
                    case MNU_ALPHA_OMEGA:
                    case MNU_ALPHAMATH:
                    case MNU_MyAlpha:
                    case MNU_ALPHAMISC:
                    case MNU_alpha_omega: {
                    //case MNU_ALPHAintl:
                      while(softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_EQ_EDIT) {
                        popSoftmenu();
                      }
                      default:;
                    }
                  }
                }

                #if defined(VERBOSEKEYS)
                  printf("keyboard.c: executeFunction %i (after runfunction): %i, %s tam.mode=%i\n", item, softmenu[softmenuStack[0].softmenuId].menuItem, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName, tam.mode);
                #endif //VERBOSEKEYS
              }
            }
          }

          noMoreToDo:

          #if defined(VERBOSEKEYS)
          printf(">>>> R000F                                %d |%s| shiftF=%d, shiftG=%d tam.mode=%i\n",item, data, shiftF, shiftG, tam.mode);
          #endif //VERBOSEKEYS

          _closeCatalog();
          fnKeyInCatalog = 0;
        }
      }
    }
    #if defined(PC_BUILD)
      printf(">>>  refreshScreen3 from keyboard.c executeFunction\n");
    #endif
    refreshScreen();
//TODO 2023-04-15 check here. It needs to be changed not to always refresh the screen.

    screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
    #if defined(VERBOSEKEYS)
      printf("keyboard.c: executeFunction (end): %i, %s\n", softmenu[softmenuStack[0].softmenuId].menuItem, indexOfItems[-softmenu[softmenuStack[0].softmenuId].menuItem].itemSoftmenuName);
    #endif //VERBOSEKEYS
  }


bool_t allowShiftsToClearError = false;
#define stringToKeyNumber(data)         ((*((char *)data) - '0')*10 + *(((char *)data)+1) - '0')





  int16_t determineItem(const char *data) {
    delayCloseNim = false;
    int16_t result;
    const calcKey_t *key;

    dynamicMenuItem = -1;

    int8_t key_no = stringToKeyNumber(data);

    #if defined(PC_BUILD)
      char tmp[200]; sprintf(tmp,"^^^^^^^keyboard.c: determineitem: key_no: %d:",key_no); jm_show_comment(tmp);
    #endif //PC_BUILD

    //.    if(kbd_usr[36].primaryTam == ITM_EXIT1) //opposite keyboard V43 LT, 43S, V43 RT
    key = getSystemFlag(FLAG_USER) ? (kbd_usr + key_no) : (kbd_std + key_no);
    //.    else
    //.      key = getSystemFlag(FLAG_USER) && ((calcMode == CM_NORMAL) || (calcMode == CM_AIM) || (calcMode == CM_NIM) || (calcMode == CM_EIM) || (calcMode == CM_PLOT_STAT) || (calcMode == CM_GRAPH) || (calcMode == CM_LISTXY)) ? (kbd_usr + key_no) : (kbd_std + key_no);    //JM Added (calcMode == CM_NORMAL) to prevent user substitution in AIM and TAM

    fnTimerExec(TO_FN_EXEC);                                  //dr execute queued fn

    #if defined(PC_BUILD)
      sprintf(tmp,"^^^^^^^keyboard.c: determineitem: key->primary1: %d:",key->primary); jm_show_comment(tmp);
    #endif //PC_BUILD

    switch(key->primary) {                              //JMSHOW vv
      case      ITM_UP1:
      case      ITM_DOWN1: break;                       //JM SHOWregis unchanged
      case      ITM_RCL: break;
      default:  SHOWregis = 9999; break;
    }                                                   //JMSHOW ^^

    bool_t gShiftOverride = false;
    result = ITM_SIGMAPLUS;
    gShiftOverride = Check_SigmaPlus_Assigned(&result, key_no);

    if (!gShiftOverride) {                              //disable long and double press if Sigma+ is shift g
      Setup_MultiPresses( key->primary );
    }

    #if defined(PC_BUILD)
      sprintf(tmp,"^^^^^^^keyboard.c: determineitem: key->primary2: %d:",key->primary); jm_show_comment(tmp);
    #endif //PC_BUILD

    // Shift f pressed and JM REMOVED shift g not active
    if(key->primary == ITM_SHIFTf && (calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM  || calcMode == CM_MIM || calcMode == CM_EIM || calcMode == CM_PEM || calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH || calcMode == CM_ASSIGN || calcMode == CM_ASN_BROWSER)) {   //JM shifts
      if(temporaryInformation == TI_SHOW_REGISTER || temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL) allowShiftsToClearError = true; //JM
      Shft_timeouts = true;
      if(ShiftTimoutMode) {
        fnTimerStart(TO_FG_TIMR, TO_FG_TIMR, JM_SHIFT_TIMER); //^^
      }
      if(temporaryInformation == TI_VIEW) {
        temporaryInformation = TI_NO_INFO;
        updateMatrixHeightCache();
      }
      else {
        temporaryInformation = TI_NO_INFO;
      }
      if(lastErrorCode != 0) allowShiftsToClearError = true;                                                                                         //JM shifts
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      lastErrorCode = 0;

      fnTimerStop(TO_FG_LONG);                                //dr

      shiftF = !shiftF;
      shiftG = false;                                         //JM no shifted menu on g-shift-key as in WP43S
      lastshiftF = shiftF;
      lastshiftG = shiftG;
      showShiftState();
      refreshModeGui();                                       //JM refreshModeGui

      screenUpdatingMode &= ~SCRUPD_MANUAL_SHIFT_STATUS;
      return ITM_NOP;
    }
    // Shift g pressed and JM REMOVED shift f not active
    else if((key->primary == ITM_SHIFTg || gShiftOverride) && (calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM  || calcMode == CM_MIM || calcMode == CM_EIM || calcMode == CM_PEM || calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH || calcMode == CM_ASSIGN || calcMode == CM_ASN_BROWSER)) {   //JM shifts
      if(temporaryInformation == TI_SHOW_REGISTER || temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL) allowShiftsToClearError = true; //JM
      Shft_timeouts = true;
      if(ShiftTimoutMode) {
        fnTimerStart(TO_FG_TIMR, TO_FG_TIMR, JM_SHIFT_TIMER); //^^
      }
      if(temporaryInformation == TI_VIEW) {
        temporaryInformation = TI_NO_INFO;
        updateMatrixHeightCache();
      }
      else {
        temporaryInformation = TI_NO_INFO;
      }
      if(lastErrorCode != 0) allowShiftsToClearError = true;                                                                                         //JM shifts
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      lastErrorCode = 0;

      fnTimerStop(TO_FG_LONG);                                //dr

      shiftG = !shiftG;
      shiftF = false;                                         //JM no shifted menu on g-shift-key as in WP43S
      lastshiftF = shiftF;
      lastshiftG = shiftG;
      showShiftState();
      refreshModeGui();                                       //JM refreshModeGui


      screenUpdatingMode &= ~SCRUPD_MANUAL_SHIFT_STATUS;
      return ITM_NOP;
    }

    // JM Shift fg pressed  //JM shifts change f/g to a single function key toggle to match DM42 keyboard
    else if(key->primary == KEY_fg && (calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM  || calcMode == CM_MIM || calcMode == CM_EIM || calcMode == CM_PEM || calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH || calcMode == CM_ASSIGN || calcMode == CM_ASN_BROWSER)) {   //JM shifts
      Shft_timeouts = true;
      fnTimerStart(TO_FG_LONG, TO_FG_LONG, JM_TO_FG_LONG);    //vv dr
      if(ShiftTimoutMode) {
        fnTimerStart(TO_FG_TIMR, TO_FG_TIMR, JM_SHIFT_TIMER); //^^
      }
      if(temporaryInformation == TI_VIEW || temporaryInformation == TI_SHOW_REGISTER || temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL) allowShiftsToClearError = true; //JM
      if(temporaryInformation == TI_VIEW) {
        temporaryInformation = TI_NO_INFO;
        updateMatrixHeightCache();
      }
      else {
          temporaryInformation = TI_NO_INFO;
      }
      if(lastErrorCode != 0) allowShiftsToClearError = true;
      if(programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
      }
      lastErrorCode = 0;

      fg_processing_jm();

      lastshiftF = shiftF;
      lastshiftG = shiftG;
      showShiftState();
      refreshModeGui();

      screenUpdatingMode &= ~SCRUPD_MANUAL_SHIFT_STATUS;
      return ITM_NOP;
    }
    #if defined(PC_BUILD)
      sprintf(tmp,"^^^^^^^keyboard.c: determineitem: key->primary3: %d:",key->primary); jm_show_comment(tmp);
    #endif //PC_BUILD

                                                                                                                         //JM shifts
    if( !tam.mode && (calcMode == CM_NIM || calcMode == CM_NORMAL) && (lastIntegerBase >= 2 && topHex) && (key_no >= 0 && key_no <= 5 )) {               //JMNIM vv Added direct A-F for hex entry
      result = shiftF ? key->fShifted :
               shiftG ? key->gShifted :
                        key->primaryAim;
      //printf(">>> ±±±§§§ keys key:%d result:%d Calmode:%d, nimbuffer:%s, lastbase:%d, nimnumberpart:%d\n",key_no, result, calcMode,nimBuffer,lastIntegerBase, nimNumberPart);
      return result;
    }
    else                                                                                                                        //JM^^

    if(calcMode == CM_AIM || (catalog && catalog != CATALOG_MVAR && calcMode != CM_NIM) || calcMode == CM_EIM || tam.alpha || (calcMode == CM_ASSIGN && (previousCalcMode == CM_AIM || previousCalcMode == CM_EIM)) || (calcMode == CM_PEM && getSystemFlag(FLAG_ALPHA))) {
      result = shiftF ? key->fShiftedAim :
               shiftG ? key->gShiftedAim :
                        key->primaryAim;
      if(calcMode == CM_PEM && getSystemFlag(FLAG_ALPHA)) {
        if(result == ITM_DOWN_ARROW || scrLock == NC_SUBSCRIPT) {
          nextChar = NC_SUBSCRIPT;
        }
        else if(result == ITM_UP_ARROW || scrLock == NC_SUPERSCRIPT) {
          nextChar = NC_SUPERSCRIPT;
        }
      }
    }
    else if(tam.mode) {
      result = key->primaryTam; // No shifted function in TAM
    }
    else if(calcMode == CM_NORMAL || calcMode == CM_NIM || calcMode == CM_MIM || calcMode == CM_FONT_BROWSER || calcMode == CM_FLAG_BROWSER || calcMode == CM_ASN_BROWSER || calcMode == CM_REGISTER_BROWSER || calcMode == CM_BUG_ON_SCREEN || calcMode == CM_CONFIRMATION || calcMode == CM_PEM || calcMode == CM_PLOT_STAT || calcMode == CM_GRAPH || calcMode == CM_ASSIGN || calcMode == CM_TIMER  || calcMode == CM_LISTXY) {
      result = shiftF ? key->fShifted :
               shiftG ? key->gShifted :
                        key->primary;
    }
    else {
      displayBugScreen(bugScreenItemNotDetermined);
      result = 0;
    }

    #if defined(PC_BUILD)
      sprintf(tmp,"^^^^^^^keyboard.c: determineitem: result1: %d:",result); jm_show_comment(tmp);
    #endif //PC_BUILD

    if(!Check_SigmaPlus_Assigned(&result, key_no)) {
      Check_MultiPresses(&result, key_no);        //JM
    }

    #if defined(PC_BUILD)
      sprintf(tmp,"^^^^^^^keyboard.c: determineitem: result3: %d:",result); jm_show_comment(tmp);
    #endif //PC_BUILD

    if(result == ITM_PROD_SIGN) {
      result = (getSystemFlag(FLAG_MULTx) ? ITM_CROSS : ITM_DOT);
    }

//    if((shiftF || shiftG) && result != ITM_SNAP) {
//      screenUpdatingMode &= ~SCRUPD_MANUAL_SHIFT_STATUS;
//      clearShiftState();
//    }

    if(result != ITM_SNAP) {
      resetShiftState();
    }

    if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && (result == ITM_NOP || result == ITM_NULL)) {
      result = ITM_LBL;
    }

    if(calcMode == CM_REGISTER_BROWSER) {
      switch(key->primary) {
        case ITM_0:
        case ITM_1:
        case ITM_2:
        case ITM_3:
        case ITM_4:
        case ITM_5:
        case ITM_6:
        case ITM_7:
        case ITM_8:
        case ITM_9:
        case ITM_PERIOD:
        case ITM_RS:
        case ITM_UP1:
        case ITM_DOWN1:
        case ITM_EXIT1:
        case ITM_ENTER:
        case ITM_RCL: {
          break;
        }
        default: {
          switch(key->primaryAim) {
            case ITM_A:
            case ITM_B:
            case ITM_C:
            case ITM_D:
            case ITM_L:
            case ITM_I:
            case ITM_J:
            case ITM_K: {
              result = key->primaryAim;
            }
          }
        }
      }
    }

    return result;
  }



    typedef struct {
      uint8_t itm;
      uint8_t itm2;
      uint8_t itm3;
      uint8_t itm4;
    } circ_t;
    uint8_t circPtr =  0;
    uint8_t circPtr2 = 0;
    uint8_t circPtr3 = 0;
    uint8_t circPtr4 = 0;
    TO_QSPI const circ_t circ[] = {
                  {7 , 2 , 2 , 2 },   //0
                  {18, 23, 23, 23},   //1
                  {30, 18, 18, 18},   //2
                  {24, 12, 9 , 20},   //3
                  {12, 29, 13, 9 },   //4
                  {28, 33, 0,  0 },   //5
                  {20, 29, 0 , 0 },   //6
                  {18, 30, 0 , 0 },   //7
                  {29, 0 , 0 , 0 },   //8
                  {0 , 0 , 0 , 0 },   //9
                };
    bool_t checkNumber(uint8_t keyCode) {
      if((circPtr == 0 && keyCode==7) || circPtr > nbrOfElements(circ)) circPtr = 0;
      if(circ[circPtr].itm==keyCode) circPtr++; else circPtr = 0;
      if(circPtr == 9 && keyCode==29) {
        fnSetHP35(0);
        return true;
      }
      if((circPtr2 == 0 && keyCode==2) || circPtr2 > nbrOfElements(circ)) circPtr2 = 0;
      if(circ[circPtr2].itm2==keyCode) circPtr2++; else circPtr2 = 0;
      if(circPtr2 == 8 && keyCode==30) {
        fnSetC47(0);
        return true;
      }
      if((circPtr3 == 0 && keyCode==2) || circPtr3 > nbrOfElements(circ)) circPtr3 = 0;
      if(circ[circPtr3].itm3==keyCode) circPtr3++; else circPtr3 = 0;
      if(circPtr3 == 5 && keyCode==13) {
        fnSetJM(0);
        return true;
      }
      if((circPtr4 == 0 && keyCode==2) || circPtr4 > nbrOfElements(circ)) circPtr4 = 0;
      if(circ[circPtr4].itm4==keyCode) circPtr4++; else circPtr4 = 0;
      if(circPtr4 == 5 && keyCode==9) {
        fnSetRJ(0);
        return true;
      }
      //printf("RRRR %i %u %u\n", keyCode, circPtr, circPtr2);
      return false;
    }





  #if defined(PC_BUILD)
    void btnClicked(GtkWidget *notUsed, gpointer data) {
      GdkEvent mouseButton;
      mouseButton.button.button = 1;
      mouseButton.type = 0;

      btnPressed(notUsed, &mouseButton, data);
      btnReleased(notUsed, &mouseButton, data);
  }
  #endif // PC_BUILD

  #if defined(DMCP_BUILD)
    void btnClicked(void *unused, void *data) {
      btnPressed(data);
      btnReleased(data);
    }
  #endif // DMCP_BUILD

bool_t nimWhenButtonPressed = false;                  //PHM eRPN 2021-07


#if defined(PC_BUILD)
  void btnClickedP(GtkWidget *w, gpointer data) {                          //JM PRESSED FOR KEYBOARD F REPEAT
    GdkEvent mouseButton;
    mouseButton.button.button = 1;
    mouseButton.type = 0;
    btnPressed(w, &mouseButton, data);
  }

  void btnClickedR(GtkWidget *w, gpointer data) {                          //JM PRESSED FOR KEYBOARD F REPEAT
    GdkEvent mouseButton;
    mouseButton.button.button = 1;
    btnReleased(w, &mouseButton, data);
  }




    void btnPressed(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
      nimWhenButtonPressed = (calcMode == CM_NIM);                  //PHM eRPN 2021-07

      int keyCode = (*((char *)data) - '0')*10 + *(((char *)data) + 1) - '0';
      if(checkNumber((uint8_t)keyCode)) {
        return;
      }

      asnKey[0] = ((uint8_t *)data)[0];
      asnKey[1] = ((uint8_t *)data)[1];
      asnKey[2] = 0;

     if(programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED) {
        setLastKeyCode(keyCode + 1);
      }
      else {
        lastKeyCode = 0;
      }

      if(event->type == GDK_DOUBLE_BUTTON_PRESS || event->type == GDK_TRIPLE_BUTTON_PRESS) { // return unprocessed for double or triple click
        return;
      }
      if(event->button.button == 2) { // Middle click
        shiftF = true;
        shiftG = false;
      }
      if(event->button.button == 3) { // Right click
        shiftF = false;
        shiftG = true;
      }
      bool_t f = shiftF;
      bool_t g = shiftG;
      bool_t ff = lastshiftF;
      bool_t gg = lastshiftG;
      lastshiftF = shiftF;
      lastshiftG = shiftG;
      int16_t item = determineItem((char *)data);

      #if defined(VERBOSEKEYS)
        printf(">>>>Z 1001 btnPressed       data=|%s| data[0]=%u item=%d \n", (char *)data, ((char *)data)[0], item);
      #endif // VERBOSEKEYS
      if(programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED) {
        if((item == ITM_RS || item == ITM_EXIT1) && !getSystemFlag(FLAG_INTING) && !getSystemFlag(FLAG_SOLVING)) {
          programRunStop = PGM_WAITING;
          showFunctionNameItem = 0;
        }
        else if(programRunStop == PGM_PAUSED) {
          programRunStop = PGM_KEY_PRESSED_WHILE_PAUSED;
        }
        return;
      }

      char *funcParam = "";

      if(getSystemFlag(FLAG_USER)) {
        int keyStateCode = (getSystemFlag(FLAG_ALPHA) ? 3 : 0) + (g ? 2 : f ? 1 : 0);
        funcParam = (char *)getNthString((uint8_t *)userKeyLabel, keyCode * 6 + keyStateCode);
        xcopy(tmpString, funcParam, stringByteLength(funcParam) + 1);
      }
      else {
        *tmpString = 0;
      }

      showFunctionNameItem = 0;
      char tmp[200]; sprintf(tmp,"^^^^btnPressed START item=%d data=\'%s\'",item,(char *)data); jm_show_comment(tmp);

      if(item != ITM_NOP && item != ITM_NULL) {
        #if defined(PC_BUILD_TELLTALE)
          sprintf(tmp,"keyboard.c: btnPressed 1--> processKeyAction(%d) which is str:%s\n",item,(char *)data); jm_show_calc_state(tmp);
        #endif //PC_BUILD_TELLTALE

        processKeyAction(item);

        #if defined(PC_BUILD_TELLTALE)
          sprintf(tmp,"keyboard.c: btnPressed 2--> processKeyAction(%d) which is str:%s\n",item,(char *)data); jm_show_calc_state(tmp);
        #endif //PC_BUILD_TELLTALE

        if(!keyActionProcessed) {
          showFunctionName(item, 1000, funcParam);// "SF:B"); // 1000ms = 1s
        }
      }
      if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && tamBuffer[0] == 0) {
        shiftF = f;
        shiftG = g;
        lastshiftF = ff;
        lastshiftG = gg;
      }

        sprintf(tmp,"^^^^btnPressed End item=%d:\'%s\' showFunctionNameItem=%d\n",item,(char *)data,showFunctionNameItem); jm_show_comment(tmp);
    }

    char key[3] = {0, 0, 0};
    static void convertXYToKey(int x, int y) {
      int xMin, xMax, yMin, yMax;
      key[0] = 0;
      key[1] = 0;
      key[2] = 0;

      for(int i=0; i<43; i++) {
        xMin = calcKeyboard[i].x;
        yMin = calcKeyboard[i].y;
        if(i == 10 && currentBezel == 2 && (tam.mode == TM_LABEL || (tam.mode == TM_SOLVE && (tam.function != ITM_SOLVE || calcMode != CM_PEM)) || (tam.mode == TM_KEY && tam.keyInputFinished))) {
          xMax = xMin + calcKeyboard[10].width[3];
          yMax = yMin + calcKeyboard[10].height[3];
        }
        else {
          xMax = xMin + calcKeyboard[i].width[currentBezel];
          yMax = yMin + calcKeyboard[i].height[currentBezel];
        }

        if(   xMin <= x && x <= xMax
           && yMin <= y && y <= yMax) {
          if(i < 6) { // Function key
            key[0] = '1' + i;
          }
          else {
            key[0] = '0' + (i - 6)/10;
            key[1] = '0' + (i - 6)%10;
          }
          break;
        }
      }
    }

    void frmCalcMouseButtonPressed(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
      if(key[0] == 0) { // The previous click must be released
        convertXYToKey((int)event->button.x, (int)event->button.y);
        if(key[0] == 0) {
          return;
        }

        if(key[1] == 0) { // Soft function key
          btnFnPressed(NULL, event, (gpointer)key);
        }
        else { // Not a soft function key
          btnPressed(NULL, event, (gpointer)key);
        }
      }
    }

    void frmCalcMouseButtonReleased(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
      if(key[0] == 0) {
        return;
      }

      if(key[1] == 0) { // Soft function key
        btnFnReleased(NULL, event, (gpointer)key);
      }
      else { // Not a soft function key
        btnReleased(NULL, event, (gpointer)key);
      }

      key[0] = 0;
    }
  #endif // PC_BUILD


  #if defined(DMCP_BUILD)
    void btnPressed(void *data) {
      nimWhenButtonPressed = (calcMode == CM_NIM);                  //PHM eRPN 2021-07
      int16_t item;
      int keyCode = (*((char *)data) - '0')*10 + *(((char *)data) + 1) - '0';
      if(checkNumber((uint8_t)keyCode)) {
        return;
      }

      bool_t f = shiftF;
      bool_t g = shiftG;

      asnKey[0] = ((uint8_t *)data)[0];
      asnKey[1] = ((uint8_t *)data)[1];
      asnKey[2] = 0;

      if(programRunStop == PGM_RUNNING || programRunStop == PGM_PAUSED) {
        lastKeyCode = keyCode;
      }
      else {
        lastKeyCode = 0;
      }

//      if(keyAutoRepeat) {            // AUTOREPEAT
//        //beep(880, 50);
//        item = previousItem;
//      }
//      else {
        lastshiftF = shiftF;
        lastshiftG = shiftG;
        item = determineItem((char *)data);
      //  previousItem = item;
      //}
      if(calcMode == CM_PEM && (item == ITM_SST || item == ITM_BST)) {
        shiftF = f;
        shiftG = g;
      }

      char *funcParam = "";

      if(getSystemFlag(FLAG_USER)) {
        int keyStateCode = (getSystemFlag(FLAG_ALPHA) ? 3 : 0) + (g ? 2 : f ? 1 : 0);
        funcParam = (char *)getNthString((uint8_t *)userKeyLabel, keyCode * 6 + keyStateCode);
        xcopy(tmpString, funcParam, stringByteLength(funcParam) + 1);
      }
      else {
        *tmpString = 0;
      }

      showFunctionNameItem = 0;
      if(item != ITM_NOP && item != ITM_NULL) {
        processKeyAction(item);
        if(!keyActionProcessed) {
          showFunctionName(item, 1000, funcParam); //"SF:C"); // 1000ms = 1s
        }
      }
      if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && tamBuffer[0] == 0) {
        shiftF = f;
        shiftG = g;
      }
    }
  #endif // DMCP_BUILD



  bool_t checkShifts(const char *data) {
    const calcKey_t *key;

    int8_t key_no = stringToKeyNumber(data);

    key = getSystemFlag(FLAG_USER) && ((calcMode == CM_NORMAL) || (calcMode == CM_AIM) || (calcMode == CM_EIM) || (calcMode == CM_NIM)) ? (kbd_usr + key_no) : (kbd_std + key_no);

    if(key->primary == ITM_SHIFTf || key->primary == ITM_SHIFTg || key->primary == KEY_fg) {
      return true;
    }
    else {
      return false;
    }
  }




  #if defined(PC_BUILD)
    void btnReleased(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
        jm_show_calc_state("##### keyboard.c: btnReleased begin");
  #endif // PC_BUILD
  #if defined(DMCP_BUILD)
    void btnReleased(void *data) {
  #endif // DMCP_BUILD
      int16_t item;
      Shft_timeouts = false;                         //JM SHIFT NEW
      JM_auto_longpress_enabled = 0;                 //JM TIMER CLRCLSTK ON LONGPRESS

      if(programRunStop == PGM_KEY_PRESSED_WHILE_PAUSED) {
        programRunStop = PGM_RESUMING;
        screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
        return;
      }
    if(calcMode == CM_ASN_BROWSER && lastItem == ITM_PERIOD) {
      fnAsnDisplayUSER = true;
      lastItem = 0;
//      refreshScreen();
      goto RELEASE_END;
      return;
    }

      if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && tamBuffer[0] == 0) {
        assignToKey((char *)data);
        if(previousCalcMode == CM_AIM) {             //vv JM RETURN TO AIM MODE
          showSoftmenu(-MNU_ALPHA);                  //
        }                                            //^^ JM
        calcMode = previousCalcMode;
        shiftF = shiftG = false;
        refreshScreen();
      }
      else if(showFunctionNameItem != 0) {
        item = showFunctionNameItem;
        #if defined(PC_BUILD)
          char tmp[200]; sprintf(tmp,"^^^^btnReleased %d:\'%s\'",item,(char *)data); jm_show_comment(tmp);
        #endif //PC_BUILD

        if(calcMode == CM_NIM && delayCloseNim && item != ITM_ms && item != ITM_CC && item != ITM_op_j && item != ITM_op_j) {
          delayCloseNim = false;
          closeNim();                 //JM moved here, from bufferize see JMCLOSE, to retain NIM if needed for .ms. Only a problem due to longpress.
          screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
        }

        fnTimerStop(TO_3S_CTFF);      //dr

        hideFunctionName();
        if(item < 0) {
          showSoftmenu(item);
        }
        else {
          int keyCode = (*((char *)data) - '0')*10 + *(((char *)data) + 1) - '0';
          int keyStateCode = (getSystemFlag(FLAG_ALPHA) ? 3 : 0) + (shiftG ? 2 : shiftF ? 1 : 0);
          char *funcParam = (char *)getNthString((uint8_t *)userKeyLabel, keyCode * 6 + keyStateCode);
        #if defined(PC_BUILD)
          if(item == ITM_RS || item == ITM_XEQ) {
            key[0] = 0;
          }
          #endif // PC_BUILD

          if(item != ITM_NOP && tam.alpha && indexOfItems[item].func != addItemToBuffer) {
            // We are in TAM mode so need to cancel first (equivalent to EXIT)
            tamLeaveMode();
          }
          if(item == ITM_RCL && getSystemFlag(FLAG_USER) && funcParam[0] != 0) {
            calcRegister_t var = findNamedVariable(funcParam);
            if(var != INVALID_VARIABLE) {
              reallyRunFunction(item, var);
            }
            else {
              displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, REGISTER_X);
              #if(EXTRA_INFO_ON_CALC_ERROR == 1)
                sprintf(errorMessage, "string '%s' is not a named variable", funcParam);
                moreInfoOnError("In function btnReleased:", errorMessage, NULL, NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            }
          }
          else if(item == ITM_XEQ && getSystemFlag(FLAG_USER) && funcParam[0] != 0) {
            calcRegister_t label = findNamedLabel(funcParam);
            if(label != INVALID_VARIABLE) {
              reallyRunFunction(item, label);
            }
            else {
              displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
              #if(EXTRA_INFO_ON_CALC_ERROR == 1)
                sprintf(errorMessage, "string '%s' is not a named label", funcParam);
                moreInfoOnError("In function btnReleased:", errorMessage, NULL, NULL);
              #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
            }
          }
          else {
            runFunction(item);
          }
        }
      }
//#if defined(DMCP_BUILD)
//      else if(keyAutoRepeat) {         // AUTOREPEAT
//        btnPressed(data);
//      }
//  #endif // DMCP_BUILD

RELEASE_END:
      if(allowShiftsToClearError || !checkShifts((char *)data)) {
        #if defined(PC_BUILD)
          char tmp[200]; sprintf(tmp,">>> btnReleased (%s):   refreshScreen from keyboard.c  which is the main normal place for it.", (char *)data); jm_show_comment(tmp);
          jm_show_calc_state("      ##### keyboard.c: btnReleased end");
        #endif //PC_BUILD
        refreshScreen(); //JM PROBLEM. THIS MUST BE REMOVED FOR MOST CASES
//TODO 2023-04-15 check here. It needs to be changed not to always refresh the screen.
      }
      screenUpdatingMode &= ~SCRUPD_ONE_TIME_FLAGS;
      allowShiftsToClearError = false;

      fnTimerStop(TO_CL_LONG);    //dr
    }




#endif //!TESTSUITE_BUILD
  void leavePem(void) {
    if(freeProgramBytes >= 4) { // Push the programs to the end of RAM
      uint32_t newProgramSize = (uint32_t)((uint8_t *)(ram + RAM_SIZE) - beginOfProgramMemory) - (freeProgramBytes & 0xfffc);
      uint16_t localStepNumber = currentLocalStepNumber;
      uint16_t programNumber = currentProgramNumber;
      uint16_t fdLocalStepNumber = firstDisplayedLocalStepNumber;
      bool_t inRam = (programList[currentProgramNumber - 1].step > 0);
      if(inRam) {
        currentStep           += (freeProgramBytes & 0xfffc);
        firstDisplayedStep    += (freeProgramBytes & 0xfffc);
        beginOfCurrentProgram += (freeProgramBytes & 0xfffc);
        endOfCurrentProgram   += (freeProgramBytes & 0xfffc);
      }
      freeProgramBytes &= 0x03;
      resizeProgramMemory(TO_BLOCKS(newProgramSize));
      scanLabelsAndPrograms();
      if(inRam) {
        currentLocalStepNumber = localStepNumber;
        currentProgramNumber = programNumber;
        firstDisplayedLocalStepNumber = fdLocalStepNumber;
        defineCurrentStep();
        defineFirstDisplayedStep();
        defineCurrentProgramFromCurrentStep();
      }
    }
  }

#if !defined(TESTSUITE_BUILD)
  void processKeyAction(int16_t item) {
    #if defined(PC_BUILD)
      printf(">>>> processKeyAction: item=%d  programRunStop=%d\n",item,programRunStop);
    #endif //PC_BUILD
    keyActionProcessed = false;
    lowercaseselected = ((alphaCase == AC_LOWER && !lastshiftF) || (alphaCase == AC_UPPER && lastshiftF /*&& !numLock*/)); //JM remove last !numlock if you want the shift, during numlock, to produce lower case

    if(lastErrorCode != 0 && item != ITM_EXIT1 && item != ITM_BACKSPACE) {
      lastErrorCode = 0;
    }

    if(temporaryInformation == TI_VIEW) {
      temporaryInformation = TI_NO_INFO;
      updateMatrixHeightCache();
      if(item == ITM_UP1 || item == ITM_DOWN1 || item == ITM_EXIT1) {
        temporaryInformation = TI_VIEW;
      }
    }
    else if(item != ITM_UP1 && item != ITM_DOWN1 && item != ITM_EXIT1 && item != ITM_BACKSPACE) {
      temporaryInformation = TI_NO_INFO;
    }
    if(programRunStop == PGM_WAITING) {
      programRunStop = PGM_STOPPED;
    }

    #if(REAL34_WIDTH_TEST == 1)
      longInteger_t lgInt;
      longIntegerInit(lgInt);
    #endif // (REAL34_WIDTH_TEST == 1)

    if(item == KEY_COMPLEX && calcMode == CM_MIM) {   //JM Allow COMPLEX to function as CC if in Matrix
      item = ITM_CC;
    }

    if((calcMode == CM_GRAPH || calcMode == CM_PLOT_STAT) && item != ITM_BACKSPACE && item != ITM_EXIT1 && item != ITM_UP1 && item != ITM_DOWN1) {
      keyActionProcessed = true;
    } else

    if(calcMode == CM_ASN_BROWSER && item != ITM_PERIOD && item != ITM_USERMODE && item != ITM_BACKSPACE && item != ITM_EXIT1 && item != ITM_UP1 && item != ITM_DOWN1) {
      keyActionProcessed = true;
    } else

    switch(item) {
      case ITM_BACKSPACE: {
        if(calcMode == CM_NIM || calcMode == CM_AIM || calcMode == CM_EIM) {
          temporaryInformation = TI_NO_INFO;
          refreshRegisterLine(NIM_REGISTER_LINE); }
        else {
          //JM No if needed, it does nothing if not in NIM. TO DISPLAY NUMBER KEYPRESS DIRECTLY AFTER PRESS, NOT ONLY UPON RELEASE          break;
          keyActionProcessed = true;   //JM move this to before fnKeyBackspace to allow fnKeyBackspace to cancel it if needed to allow this function via timing out to NOP, and this is incorporated with the CLRDROP
          fnKeyBackspace(NOPARAM);
          temporaryInformation = TI_NO_INFO;
        }
        break;
      }

      case ITM_UP1: {
        if(calcMode != CM_CONFIRMATION) {
          keyActionProcessed = true;   //JM swapped to before fnKeyUp to be able to check if key was processed below. Chose to process it here, as fnKeyUp does not have access to item.
          fnKeyUp(NOPARAM);
          if(!keyActionProcessed) {    //JMvv
            addItemToBuffer(ITM_UP_ARROW);    //Let the arrows produce arrow up and arrow down in ALPHA mode
          }                            //JM^^
          if(currentSoftmenuScrolls() || calcMode != CM_NORMAL) {
            refreshScreen();
          }
          keyActionProcessed = true;
          #if(REAL34_WIDTH_TEST == 1)
            if(++largeur > SCREEN_WIDTH) {
              largeur--;
            }
            uIntToLongInteger(largeur, lgInt);
            convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_Z);
          #endif // (REAL34_WIDTH_TEST == 1)
        } else {
          keyActionProcessed = true;
        }
        break;
      }

      case ITM_DOWN1: {
        if(calcMode != CM_CONFIRMATION) {
          keyActionProcessed = true;   //swapped to before fnKeyUp to be able to check if key was processed below. Chose to process it here, as fnKeyUp does not have access to item.
          fnKeyDown(NOPARAM);
          if(!keyActionProcessed){     //JM
             addItemToBuffer(ITM_DOWN_ARROW);    //Let the arrows produce arrow up and arrow down in ALPHA mode
          }                            //JM^^
          if(currentSoftmenuScrolls() || calcMode != CM_NORMAL) {
            refreshScreen();
          }
          keyActionProcessed = true;
          #if(REAL34_WIDTH_TEST == 1)
            if(--largeur < 20) {
              largeur++;
            }
            uIntToLongInteger(largeur, lgInt);
            convertLongIntegerToLongIntegerRegister(lgInt, REGISTER_Z);
          #endif // (REAL34_WIDTH_TEST == 1)
        } else {
          keyActionProcessed = true;
        }
        break;
      }

      case ITM_EXIT1: {
        if(calcMode == CM_PEM) {
          fnKeyExit(NOPARAM);
          keyActionProcessed = true;            //Removed to force EXIT on the RELEASE cycle to make it do fnKeyExit later to allow NOP
        }
        if(temporaryInformation != TI_NO_INFO) {
          temporaryInformation = TI_NO_INFO;
          keyActionProcessed = true;
          refreshScreen();
        }
        break;
      }

      case ITM_op_j_pol:
      case ITM_op_j:
      case ITM_CC:
      case ITM_dotD: {
        if(calcMode == CM_ASSIGN) {
          if(itemToBeAssigned == 0) {
            itemToBeAssigned = item;
          }
          else {
            tamBuffer[0] = 0;
          }
          keyActionProcessed = true;
        }
        else if(calcMode == CM_REGISTER_BROWSER || calcMode == CM_FLAG_BROWSER || calcMode == CM_ASN_BROWSER || calcMode == CM_FONT_BROWSER || calcMode == CM_TIMER) {
          keyActionProcessed = true;
        }
        else if(calcMode == CM_PEM && item == ITM_dotD && aimBuffer[0] == 0) {
          addStepInProgram(ITM_toREAL);
          keyActionProcessed = true;
        }
        break;
      }

      case ITM_ENTER: {
        if(calcMode == CM_ASSIGN) {
          if(itemToBeAssigned == 0) {
            if(tam.alpha) {
              assignLeaveAlpha();
              assignGetName1();
            }
            else {
              itemToBeAssigned = ASSIGN_CLEAR;
              if(previousCalcMode == CM_AIM) {
                showSoftmenu(-MNU_MyAlpha); //JM push MyAlpha in case ALPHA is up (likely)
              }
            }
          }
          else {
            if(tam.alpha && tam.mode != TM_NEWMENU) {
              assignLeaveAlpha();
              assignGetName2();
            }
            else if(tam.alpha) {
              tamBuffer[0] = 0;
            }
          }
          keyActionProcessed = true;
        }
        else if(calcMode == CM_REGISTER_BROWSER || calcMode == CM_FLAG_BROWSER || calcMode == CM_ASN_BROWSER || calcMode == CM_FONT_BROWSER) {
          keyActionProcessed = true;
        }
        else if(tam.mode) {

// To TEST and investigate 2023-10-02
// User menu name create: ASN + USER 'DDD' has a problem by exiting to MyAlpha

          tamProcessInput(ITM_ENTER);
          keyActionProcessed = true;
        }
        else if(calcMode == CM_NIM) {                             //JMvv
          addItemToBuffer(item);
          keyActionProcessed = true;
        }                                                         //JM^^
        break;
      }


      case CHR_caseUP: {                                                   //From keyboard: logic for Up/Dn case/num
        if(numLock)  { }
          else if(alphaCase == AC_LOWER)  { processKeyAction(CHR_case); }
            else if(alphaCase == AC_UPPER)  { processKeyAction(CHR_numL); }
        nextChar = NC_NORMAL;
        keyActionProcessed = true;
        break;
      }
      case CHR_caseDN: {                                                   //From keyboard: logic for Up/Dn case/num
        if(numLock)  { alphaCase = AC_UPPER; processKeyAction(CHR_numU); } else
          if(alphaCase == AC_UPPER)  { processKeyAction(CHR_case); }
        nextChar = NC_NORMAL;
        keyActionProcessed = true;
        break;
      }


      case CHR_numL: {
        if(!numLock)  { processKeyAction(CHR_num); }
        keyActionProcessed = true;
        break;
      }
      case CHR_numU: {
        if(numLock)  { processKeyAction(CHR_num); }
        keyActionProcessed = true;
        break;
      }
      case CHR_num: {                                                      //Toggle numlock from shifted arrow shortcut
        alphaCase = AC_UPPER;
        numLock = !numLock;
        if(!numLock) { nextChar = NC_NORMAL;}
        showAlphaModeonGui(); //dr JM, see keyboardtweaks
        keyActionProcessed = true;
        break;
      }


      case CHR_case: {                                                      //Toggle capslock from shifted arrow shortcut
        numLock = false;
        int16_t sm = softmenu[softmenuStack[0].softmenuId].menuItem;
        nextChar = NC_NORMAL;
        if(alphaCase == AC_LOWER) {
          alphaCase = AC_UPPER;
          if(sm == -MNU_alpha_omega || sm == -MNU_ALPHAintl) {
            softmenuStack[0].softmenuId--; // Switch case menu
          }
        }
        else {
          alphaCase = AC_LOWER;
          if(sm == -MNU_ALPHA_OMEGA || sm == -MNU_ALPHAINTL) {
            softmenuStack[0].softmenuId++; // Switch case menu
          }
        }
        showAlphaModeonGui(); //dr JM, see keyboardtweaks
        keyActionProcessed = true;
        break;
      }


      default:
      {
        #if defined(PC_BUILD)
          printf("Switch - default: processKeyAction: calcMode=%d itemToBeAssigned=%d item=%d\n",calcMode, itemToBeAssigned, item);
        #endif //PC_BUILD
        if(calcMode == CM_ASSIGN && itemToBeAssigned != 0 && item == ITM_USERMODE) {
          while(softmenuStack[0].softmenuId > 1) {
            popSoftmenu();
          }
          if(previousCalcMode == CM_AIM) {
            softmenuStack[0].softmenuId = 1;
            calcModeAimGui();
          }
          else {
            leaveAsmMode();
          }
          keyActionProcessed = true;
        }
        else if(calcMode == CM_ASSIGN && itemToBeAssigned == 0 && item == ITM_USERMODE) {
          tamEnterMode(ITM_ASSIGN);
          calcMode = previousCalcMode;
          keyActionProcessed = true;
        }
        else if(calcMode == CM_ASSIGN && item == ITM_AIM) {
          assignEnterAlpha();
          keyActionProcessed = true;
        }
        else if((calcMode != CM_PEM || !getSystemFlag(FLAG_ALPHA)) && catalog && catalog != CATALOG_MVAR) {
          if(ITM_A <= item && item <= ITM_Z && lowercaseselected) {
            addItemToBuffer(item + 26);
            keyActionProcessed = true;
          }

          else if(((ITM_ALPHA <= item && item <= ITM_OMEGA) || (ITM_QOPPA <= item && item <= ITM_SAMPI)) && lowercaseselected) {  //JM GREEK
            addItemToBuffer(item +  ((ITM_ALPHA <= item && item <= ITM_OMEGA) ? (ITM_alpha - ITM_ALPHA) : (ITM_qoppa - ITM_QOPPA)));
            keyActionProcessed = true;
          }

          else if(item == ITM_DOWN_ARROW || item == ITM_UP_ARROW) {
            addItemToBuffer(item);
            keyActionProcessed = true;
          }
          break;
        }
        else if(calcMode == CM_NORMAL && SHOWregis != 9999) {
          fnRecall(SHOWregis);
          setSystemFlag(FLAG_ASLIFT);
          keyActionProcessed = true;
          temporaryInformation = TI_COPY_FROM_SHOW;
        }
        else if(tam.mode) {
          if(tam.alpha) {
            if(indexOfItems[item].func == addItemToBuffer || item < 0) {
              processAimInput(item);
            }
            else {
              keyActionProcessed = true;
            }
          }
          else {
            addItemToBuffer(item);
            keyActionProcessed = true;
          }
          break;
        }
        else {
          switch(calcMode) {
            case CM_NORMAL: {
              #if defined(PC_BUILD_VERBOSE0)
                 #if defined(PC_BUILD)
                   printf("$"); //####
                 #endif
              #endif
              if(item == ITM_EXPONENT || item == ITM_PERIOD || (ITM_0 <= item && item <= ITM_9)) {
                addItemToNimBuffer(item);
                keyActionProcessed = true;
              }
              // Following commands do not timeout to NOP
              else if(item == ITM_UNDO || item == ITM_BST || item == ITM_SST || item == ITM_PR || item == ITM_AIM) {
                runFunction(item);
                keyActionProcessed = true;
              }
              break;
            }

            case CM_AIM: {
//JM In AIM, BST and SST is not reaching here, as it is reconfigured for CAPS lock and NUM lock
              if(item == ITM_BST || item == ITM_SST) {
                closeAim();
                runFunction(item);
                keyActionProcessed = true;
              }
              else {
                processAimInput(item);
              }
              break;
            }

            case CM_EIM: {
              #if defined(PC_BUILD_VERBOSE0)
                 #if defined(PC_BUILD)
                   printf("^"); //####
                 #endif
              #endif
              processAimInput(item);
              refreshRegisterLine(AIM_REGISTER_LINE);   //JM  No if needed, it does nothing if not in NIM. TO DISPLAY NUMBER KEYPRESS DIRECTLY AFTER PRESS, NOT ONLY UPON RELEASE          break;
              break;
            }

            case CM_NIM: {
              #if defined(PC_BUILD_VERBOSE0)
                #if defined(PC_BUILD)
                  printf("&"); //####
                #endif
              #endif

              if(item == ITM_BST || item == ITM_SST) {
                closeNim();
                runFunction(item);
                keyActionProcessed = true;
              }
              else {
                keyActionProcessed = true;
                if(item == ITM_toINT || item == ITM_HASH_JM) resetShiftState();
                addItemToNimBuffer(item);
                if( ((ITM_0 <= item && item <= ITM_9) || ((ITM_A <= item && item <= ITM_F) && (lastIntegerBase >= 2) && topHex) ) || item == ITM_CHS || item == ITM_EXPONENT || item == ITM_PERIOD) {   //JMvv Direct keypresses; //JMNIM Added direct A-F for hex entry
                  refreshRegisterLine(REGISTER_X);
                }                                                                                   //JM^^
              }
              break;
            }

            case CM_MIM: {
              addItemToBuffer(item);
              keyActionProcessed = true;
              break;
            }

            case CM_REGISTER_BROWSER: {
              if(item == ITM_PERIOD) {
                rbr1stDigit = true;
                if(rbrMode == RBR_GLOBAL) {
                  if(currentNumberOfLocalRegisters != 0) {
                    rbrMode = RBR_LOCAL;
                    currentRegisterBrowserScreen = FIRST_LOCAL_REGISTER;
                  }
                  else {
                    rbrMode = RBR_NAMED;
                    currentRegisterBrowserScreen = FIRST_NAMED_VARIABLE;
                  }
                }
                else if(rbrMode == RBR_LOCAL) {
                  rbrMode = RBR_NAMED;
                  currentRegisterBrowserScreen = FIRST_NAMED_VARIABLE;
                }
                else if(rbrMode == RBR_NAMED) {
                  rbrMode = RBR_GLOBAL;
                  currentRegisterBrowserScreen = REGISTER_X;
                }
              }
              else if(item == ITM_RS) {
                rbr1stDigit = true;
                showContent = !showContent;
              }
              else if(item == ITM_RCL) {
                rbr1stDigit = true;
                if(rbrMode == RBR_GLOBAL || rbrMode == RBR_LOCAL) {
                  calcMode = previousCalcMode;
                  fnRecall(currentRegisterBrowserScreen);
                  setSystemFlag(FLAG_ASLIFT);
                }
                else if(rbrMode == RBR_NAMED) {
                  calcMode = previousCalcMode;
                  if(currentRegisterBrowserScreen >= FIRST_NAMED_VARIABLE + numberOfNamedVariables) { // Reserved variables
                    currentRegisterBrowserScreen -= FIRST_NAMED_VARIABLE + numberOfNamedVariables;
                    currentRegisterBrowserScreen += FIRST_RESERVED_VARIABLE + 12;
                  }
                  fnRecall(currentRegisterBrowserScreen);
                  setSystemFlag(FLAG_ASLIFT);
                }
              }
              else if(ITM_0 <= item && item <= ITM_9) {
                if(rbr1stDigit) {
                  rbr1stDigit = false;
                  rbrRegister = item - ITM_0;
                }
                else {
                  rbr1stDigit = true;
                  rbrRegister = rbrRegister*10 + item - ITM_0;

                  switch(rbrMode) {
                    case RBR_GLOBAL: {
                      currentRegisterBrowserScreen = rbrRegister;
                      break;
                    }
                    case RBR_LOCAL: {
                      rbrRegister = (rbrRegister >= currentNumberOfLocalRegisters ? 0 : rbrRegister);
                      currentRegisterBrowserScreen = FIRST_LOCAL_REGISTER + rbrRegister;
                      break;
                    }
                    case RBR_NAMED: {
                      rbrMode = RBR_GLOBAL;
                      currentRegisterBrowserScreen = rbrRegister;
                      break;
                    }
                  }
                }
              }
              else if(ITM_A <= item && item <= ITM_D) {
                rbrMode = RBR_GLOBAL;
                rbr1stDigit = true;
                currentRegisterBrowserScreen = item - ITM_A + REGISTER_A;
              }
              else if(ITM_I <= item && item <= ITM_K) {
                rbrMode = RBR_GLOBAL;
                rbr1stDigit = true;
                currentRegisterBrowserScreen = item - ITM_I + REGISTER_I;
              }
              else if(item == ITM_L) {
                rbrMode = RBR_GLOBAL;
                rbr1stDigit = true;
                currentRegisterBrowserScreen = REGISTER_L;
              }

              keyActionProcessed = true;
              break;
            }

            case CM_ASN_BROWSER: {
              lastItem = 0;
              lastUserMode = false;
              if(item == ITM_PERIOD) {
                fnAsnDisplayUSER = false;
                keyActionProcessed = true;
                lastItem = item;
                refreshScreen();
              } else
              if(item == ITM_USERMODE) {
                runFunction(item);
                keyActionProcessed = true;
//                refreshScreen();
              }
              break;
            }

            case CM_FLAG_BROWSER:
            case CM_FONT_BROWSER:
            case CM_ERROR_MESSAGE:
            case CM_BUG_ON_SCREEN: {
              keyActionProcessed = true;
              break;
            }

            case CM_GRAPH:
            case CM_PLOT_STAT:
            case CM_LISTXY: {
              if(item == ITM_SNAP) {
                runFunction(item);
                keyActionProcessed = true;
              }
              break;
            }

            case CM_CONFIRMATION: { //ITM_ENTER & ITM_EXIT1 do not reach here, it goes to fnKeyEnter and fnKeyExit
              if(item == ITEM_CONF_Y || item == ITM_XEQ || item == ITM_ENTER) { // Yes or XEQ or ENTER
                calcMode = previousCalcMode;
                confirmedFunction(CONFIRMED);
              }

              else if(item == ITEM_CONF_N || item == ITM_EXIT1) { // No
                calcMode = previousCalcMode;
              }

              else {
                temporaryInformation = TI_ARE_YOU_SURE;
              }

              keyActionProcessed = true;
              break;
            }

            case CM_PEM: {
              if(item == ITM_PR) {
                leavePem();
                calcModeNormal();
                keyActionProcessed = true;
              }
              else if(item == ITM_OFF) {
                fnOff(NOPARAM);
                keyActionProcessed = true;
              }
              else if(item == ITM_SST) {
                fnSst(NOPARAM);
                keyActionProcessed = true;
                refreshScreen();
              }
              else if(item == ITM_BST) {
                fnBst(NOPARAM);
                keyActionProcessed = true;
                refreshScreen();
              }
              else if(aimBuffer[0] != 0 && !getSystemFlag(FLAG_ALPHA) && (item == ITM_HASH_JM || item == ITM_toINT || (nimNumberPart == NP_INT_BASE && item == ITM_RCL))) {
                if(item == ITM_HASH_JM ) item = ITM_toINT;
                pemAddNumber(item);
                keyActionProcessed = true;
                if(item == ITM_RCL) {
                  currentStep = findPreviousStep(currentStep);
                  --currentLocalStepNumber;
                  if(!programListEnd) {
                    scrollPemBackwards();
                  }
                }
              }
              else if(item == ITM_RS) {
                addStepInProgram(ITM_STOP);
                keyActionProcessed = true;
              }
              break;
            }

            case CM_ASSIGN: {
              if(item > 0 && itemToBeAssigned == 0) {
                if(tam.alpha) {
                  processAimInput(item);
                  if(stringGlyphLength(aimBuffer) > 6) {
                    assignLeaveAlpha();
                    assignGetName1();
                  }
                }
                else {
                  itemToBeAssigned = item;
                  if(previousCalcMode == CM_AIM) softmenuStack[0].softmenuId = 1;     //JM change ALPHA to MyAlpha to be able to write ASN target
                }
                keyActionProcessed = true;
              }
              else if(item != 0 && itemToBeAssigned != 0) {
                if(tam.alpha && tam.mode != TM_NEWMENU) {
                  if(item > 0) {
                    processAimInput(item);
                    if(stringGlyphLength(aimBuffer) > 6) {
                      assignLeaveAlpha();
                      assignGetName2();
                    }
                    keyActionProcessed = true;
                  }
                }
                else {
                  switch(item) {
                    case ITM_ENTER:
                    case ITM_SHIFTf:
                    case ITM_SHIFTg:
                    case ITM_USERMODE:
                    case ITM_EXIT1:
                    case KEY_fg:        //JM
                    case ITM_BACKSPACE: {
                      break;
                    }
                    default: {
                      tamBuffer[0] = 0;
                      keyActionProcessed = true;
                  }
                }
              }
              }
              break;
            }

            case CM_TIMER: {
              printf("ITEM: %d\n", item);
              switch(item) {
                case ITM_RS: {
                  fnStartStopTimerApp();
                  break;
                }
                case ITM_0:
                case ITM_1:
                case ITM_2:
                case ITM_3:
                case ITM_4:
                case ITM_5:
                case ITM_6:
                case ITM_7:
                case ITM_8:
                case ITM_9: {
                  fnDigitKeyTimerApp(item - ITM_0);
                  break;
                }
                case ITM_PERIOD: {
                  fnDotTimerApp();
                  break;
                }
                case ITM_ADD: {
                  fnPlusTimerApp();
                  break;
                }
                case ITM_RCL: {
                  runFunction(ITM_TIMER_RCL);
                  break;
              }
              }
              keyActionProcessed = true;
              break;
            }

            default: {
              sprintf(errorMessage, "In function processKeyAction: %" PRIu8 " is an unexpected value while processing calcMode!", calcMode);
              displayBugScreen(errorMessage);
            }
          }
          #if defined(RECORDLOG)
            #if defined(PC_BUILD)
              if(keyActionProcessed) {                         //JMEXEC
                capture_sequence("keyActionProcessed:", item);  //JMEXEC
              }                                                //JMEXEC
            #endif
          #endif // RECORDLOG
        }
      }
    }
    #if(REAL34_WIDTH_TEST == 1)
      longIntegerFree(lgInt);
    #endif // (REAL34_WIDTH_TEST == 1)
  }


  static void menuUp(void) {
    int16_t menuId = softmenuStack[0].softmenuId;
    int16_t sm = softmenu[menuId].menuItem;

    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
    if(temporaryInformation == TI_NO_INFO && lastErrorCode == ERROR_NONE) {
      screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
    }
    if((sm == -MNU_alpha_omega || sm == -MNU_ALPHAintl) && alphaCase == AC_LOWER) {
      alphaCase = AC_UPPER;
      showAlphaModeonGui(); //dr JM, see keyboardtweaks
      softmenuStack[0].softmenuId--; // Switch to the upper case menu
    }
    else if((sm == -MNU_ALPHAMISC || sm == -MNU_ALPHAMATH || sm == -MNU_ALPHA) && alphaCase == AC_LOWER && arrowCasechange) {  //JMcase
      alphaCase = AC_UPPER;
      showAlphaModeonGui(); //dr JM, see keyboardtweaks
    }
    else {
      int16_t itemShift = (catalog == CATALOG_NONE ? 18 : 6);
      if((softmenuStack[0].firstItem + itemShift) < (menuId < NUMBER_OF_DYNAMIC_SOFTMENUS ? dynamicSoftmenu[menuId].numItems : softmenu[menuId].numItems)) {
        softmenuStack[0].firstItem += itemShift;
      }
      else {
        softmenuStack[0].firstItem = 0;
      }

      setCatalogLastPos();
    }
  }



  static void menuDown(void) {
    int16_t menuId = softmenuStack[0].softmenuId;
    int16_t sm = softmenu[menuId].menuItem;

    screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
    if(temporaryInformation == TI_NO_INFO && lastErrorCode == ERROR_NONE) {
      screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
    }

    if((sm == -MNU_ALPHA_OMEGA || sm == -MNU_ALPHAINTL) && alphaCase == AC_UPPER) {
      alphaCase = AC_LOWER;
      showAlphaModeonGui(); //dr JM, see keyboardtweaks
      softmenuStack[0].softmenuId++; // Switch to the lower case menu
    }
    else if((sm == -MNU_ALPHAMISC || sm == -MNU_ALPHAMATH || sm == -MNU_ALPHA) && alphaCase == AC_UPPER && arrowCasechange) {  //JMcase
      alphaCase = AC_LOWER;
      showAlphaModeonGui(); //dr JM, see keyboardtweaks
    }
    else {
      int16_t itemShift = (catalog == CATALOG_NONE ? 18 : 6);

      if((softmenuStack[0].firstItem - itemShift) >= 0) {
        softmenuStack[0].firstItem -= itemShift;
      }
      else if((softmenuStack[0].firstItem - itemShift) >= -5) {
        softmenuStack[0].firstItem = 0;
      }
      else {
        if(menuId < NUMBER_OF_DYNAMIC_SOFTMENUS) {
          softmenuStack[0].firstItem = ((dynamicSoftmenu[menuId].numItems - 1)/6) / (itemShift/6) * itemShift;
        }
        else {
          softmenuStack[0].firstItem = ((       softmenu[menuId].numItems - 1)/6) / (itemShift/6) * itemShift;
        }
      }
      setCatalogLastPos();
    }
  }
#endif // !TESTSUITE_BUILD



void fnKeyEnter(uint16_t unusedButMandatoryParameter) {
  doRefreshSoftMenu = true;     //dr
  #if !defined(TESTSUITE_BUILD)
    if(changeFractionModeOnENTER) {
      setSystemFlag(FLAG_FRACT);
      changeFractionModeOnENTER = false;
    }
    switch(calcMode) {
      case CM_NORMAL: {

        if(!eRPN || !nimWhenButtonPressed || (eRPN && programRunStop == PGM_RUNNING )) {                 //vv PHM eRPN 2021-07
          setSystemFlag(FLAG_ASLIFT);
          #if defined(DEBUGUNDO)
            printf(">>> saveForUndo from fnKeyEnterA\n");
          #endif // DEBUGUNDO
          saveForUndo();
          if(lastErrorCode == ERROR_RAM_FULL) {
          goto undo_disabled;
          }

          liftStack();
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto ram_full;
          }
          copySourceRegisterToDestRegister(REGISTER_Y, REGISTER_X);
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto ram_full;
          }
        }

        if(eRPN) {
          setSystemFlag(FLAG_ASLIFT);
        }
        else {                                               //^^ PHM eRPN 2021-07
          clearSystemFlag(FLAG_ASLIFT);
        }                                                    //PHM eRPN 2021-07
        break;
      }

      case CM_AIM: {
          if(softmenuStack[0].softmenuId <= 1 || softmenu[softmenuStack[1].softmenuId].menuItem == -MNU_ALPHA) {
            popSoftmenu();
          }
          if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHA) {  //JM get out of the ALPHA menu and go to MyM fto satisfy the old enter routines
            softmenuStack[0].softmenuId = 1;                                  //JM
          }                                                                   //JM

        calcModeNormal();
        popSoftmenu();

        if(aimBuffer[0] == 0) {
          #if defined(DEBUGUNDO)
            printf(">>> undo from fnKeyEnter\n");
          #endif // DEBUGUNDO
          undo();
        }
        else {
          int16_t len = stringByteLength(aimBuffer) + 1;

          reallocateRegister(REGISTER_X, dtString, TO_BLOCKS(len), amNone);
          xcopy(REGISTER_STRING_DATA(REGISTER_X), aimBuffer, len);

          if(!eRPN) {                                  //PHM eRPN 2021-07
            setSystemFlag(FLAG_ASLIFT);
          #if defined(DEBUGUNDO)
              printf(">>> saveForUndo from fnKeyEnterB\n");
          #endif // DEBUGUNDO
            saveForUndo();
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto undo_disabled;
          }
            liftStack();
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto ram_full;
          }
            clearSystemFlag(FLAG_ASLIFT);

          copySourceRegisterToDestRegister(REGISTER_Y, REGISTER_X);
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto ram_full;
          }
          aimBuffer[0] = 0;              //PHM JM Keeping the structure like 43S, to be able to pick up changes from their side easier
        }
        else {
          setSystemFlag(FLAG_ASLIFT);
          aimBuffer[0] = 0;              //PHM JM Keeping the structure like 43S, to be able to pick up changes from their side easier
        }
        }
        break;
      }

      case CM_MIM: {
        mimEnter(false);
        break;
      }

//       43S code not in use: PHM.
//       JM Keeping the structure like in 43S, to be able to pick up changes
//JM: 2022-09-04:
//JM: This code does not seem to be "not-used" See bug report Gitlab #80. code seems needed.
//JM: PHM is not active in the project anymore. Restored this code:
      case CM_NIM: {
        closeNim();

        if(calcMode != CM_NIM && lastErrorCode == 0) {
          setSystemFlag(FLAG_ASLIFT);
          #if defined(DEBUGUNDO)
            printf(">>> saveForUndo from fnKeyEnterC\n");
          #endif // DEBUGUNDO
          saveForUndo();
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto undo_disabled;
          }
          liftStack();
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto ram_full;
          }
          clearSystemFlag(FLAG_ASLIFT);
          copySourceRegisterToDestRegister(REGISTER_Y, REGISTER_X);
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto ram_full;
          }
        }
        break;
      }
//JM ^^ ---2022-09-04

      case CM_EIM: {
        if(aimBuffer[0] != 0) {
          setEquation(currentFormula, aimBuffer);
        }
        if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQ_EDIT) {
          calcModeNormal();
          if(allFormulae[currentFormula].pointerToFormulaData == WP43_NULL) {
            deleteEquation(currentFormula);
          }
        }
        popSoftmenu();
        break;
      }

      case CM_REGISTER_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FONT_BROWSER:
      case CM_ERROR_MESSAGE:
      case CM_BUG_ON_SCREEN:
      case CM_PLOT_STAT:
      case CM_LISTXY:                     //JM
      case CM_GRAPH: {                     //JM
        break;
      }

      case CM_TIMER: {
        fnEnterTimerApp();
        break;
      }

      case CM_CONFIRMATION: {
        calcMode = previousCalcMode;
        confirmedFunction(CONFIRMED);
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyEnter", calcMode, "ENTER");
        displayBugScreen(errorMessage);
    }
    }
    return;

undo_disabled:
    temporaryInformation = TI_UNDO_DISABLED;
    return;

ram_full:
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    #if defined(DEBUGUNDO)
      printf(">>> Undo from fnKeyEnterD\n");
    #endif // DEBUGUNDO
    fnUndo(NOPARAM);
    return;
  #endif // !TESTSUITE_BUILD
}



#if !defined(TESTSUITE_BUILD)
  static void stayInAIM(void) {
    if(calcMode == CM_AIM && (softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_ALPHA && softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_MyAlpha) ) {   //JM
      softmenuStack[0].softmenuId = mm_MNU_ALPHA;    //JM
      setSystemFlag(FLAG_ALPHA);                     //JM
    }                                                //JM ^^

    if(calcMode != CM_AIM && (softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHA ||
                              softmenu[softmenuStack[1].softmenuId].menuItem == -MNU_ALPHA)) { //JMvv : If ALPHA, switch back to AIM
      setSystemFlag(FLAG_ALPHA);                                          //JM
      calcMode = CM_AIM;
    }                                                                     //JM ^^

    refreshModeGui(); //JM refreshModeGui
  }
#endif // !TESTSUITE_BUILD



void fnKeyExit(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    if(tam.mode == TM_KEY && !tam.keyInputFinished) {
      if(tam.digitsSoFar == 0) {
        tamProcessInput(ITM_2);
        tamProcessInput(ITM_1);
        shiftF = shiftG = false;
        refreshScreen();
      }
      return;
    }
    if(lastErrorCode == 0 && softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_MVAR) {
      currentSolverStatus &= ~SOLVER_STATUS_INTERACTIVE;
    }

    doRefreshSoftMenu = true;     //dr

  #if defined(PC_BUILD)
    jm_show_calc_state("fnKeyExit");
  #endif

    switch(calcMode) {
        case CM_REGISTER_BROWSER:
        case CM_FLAG_BROWSER:
        case CM_ASN_BROWSER:
        case CM_FONT_BROWSER:
        case CM_CONFIRMATION:
        case CM_ERROR_MESSAGE:
        case CM_BUG_ON_SCREEN: {
            // Browser or message should be closed first
            break;
      }

      default: {
            if(catalog) {
                if(lastErrorCode != 0) {
                    lastErrorCode = 0;
                }
                else {
                    if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_SYSFL) {                                                       //JM auto recover out of SYSFL
                      numberOfTamMenusToPop = 2;                                                   //JM
                      tamLeaveMode();                                                              //JM
                      return;                                                                      //JM
                    }                                                                              //JM
                    leaveAsmMode();
                    popSoftmenu();
                    if(tam.mode) {
                        numberOfTamMenusToPop--;
                    }
                }
                return;
            }
      }
    }

    if(tam.mode) {
      if(numberOfTamMenusToPop > 1) {
        popSoftmenu();
        numberOfTamMenusToPop--;
      }
      else {
        if(calcMode == CM_PEM) {
          aimBuffer[0] = 0;
        }
        tamLeaveMode();
        if(calcMode == CM_PEM) {
          scrollPemBackwards();
        }
      }
      return;
    }

    switch(calcMode) {
      case CM_REGISTER_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FONT_BROWSER:
      case CM_CONFIRMATION:
      case CM_ERROR_MESSAGE:
      case CM_BUG_ON_SCREEN: {
        // Browser or message should be closed first
        break;
      }

      case CM_NORMAL: {
        if(softmenu[softmenuStack[0].softmenuId].menuItem == -ITM_MENU) {
          dynamicMenuItem = NUMBER_OF_DYNAMIC_SOFTMENUS + 1;
          fnProgrammableMenu(NOPARAM);
          return;
        }
      }

      default: {
      }
    }

    switch(calcMode) {
      case CM_NORMAL: {
        if(temporaryInformation == TI_SHOW_REGISTER || temporaryInformation == TI_SHOW_REGISTER_SMALL || temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_VIEW) {
          temporaryInformation = TI_NO_INFO;
        }
        else if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else {
          if(softmenuStack[0].softmenuId <= 1) { // MyMenu or MyAlpha is displayed
            currentInputVariable = INVALID_VARIABLE;
            if(BASE_HOME) {
               showSoftmenu(-MNU_HOME);
            }
            else if(BASE_MYM) {
              BASE_OVERRIDEONCE = true;
              showSoftmenu(-MNU_MyMenu);
            }                             //If none selected, do not display any menu, keep the screen blank
          }
          else {                  //jm: this is where 43S cleared an error
            popSoftmenu();
            stayInAIM(); //JM
          }
          screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
          if(temporaryInformation == TI_NO_INFO) {
            screenUpdatingMode |= SCRUPD_SKIP_STACK_ONE_TIME;
          }
        }
        break;
      }

      case CM_AIM: {
        if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHA) {  //JM get out of the ALPHA menu and go to MyM fto satisfy the old exit routines
          softmenuStack[0].softmenuId = 1;                                  //JM
        }                                                                   //JM

        if(running_program_jm || (softmenuStack[0].softmenuId <= 1 && softmenu[softmenuStack[1].softmenuId].menuItem != -MNU_ALPHA)) { // MyMenu or MyAlpha is displayed
          closeAim();
          #if defined(DEBUGUNDO)
            printf(">>> saveForUndo from fnKeyExitA\n");
          #endif  // DEBUGUNDO
          updateMatrixHeightCache();
          saveForUndo();
          if(lastErrorCode == ERROR_RAM_FULL) {
            goto undo_disabled;
          }
        }
        else {
          popSoftmenu();
          stayInAIM();
        }
        break;
      }

      case CM_NIM: {
        addItemToNimBuffer(ITM_EXIT1);
        updateMatrixHeightCache();
        break;
      }

      case CM_MIM: {
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else if(temporaryInformation == TI_SHOW_REGISTER) {
          temporaryInformation = TI_NO_INFO;
        }
        else {
          if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_M_EDIT) {
            mimEnter(true);
            if(matrixIndex == findNamedVariable(statMx)) {
              calcSigma(0);
            }
            mimFinalize();
            calcModeNormal();
            updateMatrixHeightCache();
          }
          screenUpdatingMode = SCRUPD_AUTO;
          popSoftmenu(); // close softmenu dedicated for the MIM
        }
        break;
      }

      case CM_PEM: {
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
          break;
        }
        if(getSystemFlag(FLAG_ALPHA) && !tam.mode) {
          bool_t isInAlphaSubmenu = false;
          switch(-softmenu[softmenuStack[1].softmenuId].menuItem) {
            case MNU_ALPHAINTL:
            case MNU_ALPHAintl:
            case MNU_ALPHAMATH:
            case MNU_ALPHA_OMEGA:
            case MNU_alpha_omega:
            case MNU_ALPHA:
            case MNU_MyAlpha:
              isInAlphaSubmenu = true;
              break;
          }
          if(isInAlphaSubmenu) {
            popSoftmenu();
            break;
          }
        }
        if(getSystemFlag(FLAG_ALPHA) && aimBuffer[0] == 0 && !tam.mode) {
          pemAlpha(ITM_BACKSPACE);
          fnBst(NOPARAM); // Set the PGM pointer to the original position
          break;
        }
        if(aimBuffer[0] != 0 && !tam.mode) {
          if(getSystemFlag(FLAG_ALPHA)) {
            pemCloseAlphaInput();
          }
          else if(nimNumberPart == NP_INT_BASE) {
            break;
          }
          else {
            pemCloseNumberInput();
          }
          aimBuffer[0] = 0;
          fnBst(NOPARAM); // Set the PGM pointer to the original position
          break;
        }
        if(softmenuStack[0].softmenuId > 1) { // not MyMenu and not MyAlpha
          popSoftmenu();
          break;
        }

        aimBuffer[0] = 0;
        leavePem();
        calcModeNormal();
        #if defined(DEBUGUNDO)
          printf(">>> saveForUndo from fnKeyExitB\n");
        #endif // DEBUGUNDO
        saveForUndo();
        if(lastErrorCode == ERROR_RAM_FULL) {
          goto undo_disabled;
        }
        break;
      }

      case CM_EIM: {
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else {
          if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQ_EDIT) {
            calcModeNormal();
            if(allFormulae[currentFormula].pointerToFormulaData == WP43_NULL) {
              deleteEquation(currentFormula);
            }
          }
          popSoftmenu();
        }
        break;
      }

      case CM_REGISTER_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FONT_BROWSER: {
        rbr1stDigit = true;
        calcMode = previousCalcMode;
        break;
      }

      case CM_TIMER: {
        screenUpdatingMode = SCRUPD_AUTO;
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else {
          fnLeaveTimerApp();
        }
        break;
      }

      case CM_BUG_ON_SCREEN: {
        calcMode = previousCalcMode;
        break;
      }

      case CM_LISTXY:                      //JM vv
        calcMode = CM_GRAPH;
        softmenuStack[0].firstItem = 0;
        break;                              //JM ^^

      case CM_GRAPH:
      case CM_PLOT_STAT: {
        if(calcMode == CM_PLOT_STAT) {
          for(int16_t ii = 0; ii < 3; ii++) {
            if( (softmenuStack[0].softmenuId > 1) && !(
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_HIST) ||
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_PLOTTING) ||
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_MODEL) ||
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_REGR)
               )) {
              popSoftmenu();
            }
          }
        }
        else {
          popSoftmenu();
        }

        lastPlotMode = PLOT_NOTHING;
        plotSelection = 0;

        calcModeNormal();
        #if defined(DEBUGUNDO)
          printf(">>> Undo from fnKeyExit\n");
        #endif // DEBUGUNDO
        fnUndo(NOPARAM);
        fnClDrawMx();
        restoreStats();
        break;
      }

      case CM_CONFIRMATION: {
        calcMode = previousCalcMode;
        temporaryInformation = TI_NO_INFO;
        if(programRunStop == PGM_WAITING) {
          programRunStop = PGM_STOPPED;
        }
        break;
      }

      case CM_ASSIGN: {
        if((softmenuStack[0].softmenuId <= 1 && softmenuStack[1].softmenuId <= 1) || (previousCalcMode == CM_EIM && softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQ_EDIT)) { // MyMenu or MyAlpha is displayed
          calcMode = previousCalcMode;
          if(tam.alpha) {
            assignLeaveAlpha();
          }
        }
        else {
          popSoftmenu();
          if(previousCalcMode == CM_AIM) { //JM
            stayInAIM();                   //JM
          }                                //JM
        }
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyExit", calcMode, "EXIT");
        displayBugScreen(errorMessage);
    }

    last_CM = 253; //Force redraw   //JMvvv Show effect of Exit immediately
    refreshScreen();                //JM^^^
    }
    return;

undo_disabled:
    temporaryInformation = TI_UNDO_DISABLED;
    return;
  #endif // !TESTSUITE_BUILD
}



void fnKeyCC(uint16_t complex_Type) {    //JM Using 'unusedButMandatoryParameter' complex_Type=KEY_COMPLEX
  doRefreshSoftMenu = true;     //dr
  #if !defined(TESTSUITE_BUILD)
    uint32_t dataTypeX, dataTypeY;
    bool_t polarOk, rectOk;

    // The switch statement is broken up here, due to multiple conditions.                      //JM
    if((calcMode == CM_NIM) && (complex_Type == KEY_COMPLEX)) {
      addItemToNimBuffer(ITM_EXIT1);
    }    //JM Allow COMPLEX to be used from NIM

    if(calcMode == CM_NORMAL || ((calcMode == CM_NIM) && (complex_Type == KEY_COMPLEX))) {      //JM
      dataTypeX = getRegisterDataType(REGISTER_X);
      dataTypeY = getRegisterDataType(REGISTER_Y);

      polarOk = (( dataTypeY == dtLongInteger || (dataTypeY == dtReal34 && getRegisterAngularMode(REGISTER_Y) == amNone  ))                                      //radius not allowed to be an angle if polar entry
         && ( dataTypeX == dtLongInteger || (dataTypeX == dtReal34    /*can be angle or not */                      )) && getSystemFlag(FLAG_POLAR) );           //real not allowed to be an angle if rect entry
      rectOk  = (( dataTypeY == dtLongInteger || (dataTypeY == dtReal34 && getRegisterAngularMode(REGISTER_Y) == amNone  ))                                      //real not allowed to be an angle if rect entry
         && ( dataTypeX == dtLongInteger || (dataTypeX == dtReal34 && getRegisterAngularMode(REGISTER_X) == amNone  )) && !getSystemFlag(FLAG_POLAR) );          //imag not allowed to be an angle if rect entry

      //CC needs in POLAR mode Y=r, X=ϑ;
      //CC needs in RECT mode, Y=real, X=imag
      if(polarOk || rectOk) {  //imag not allowed to be an angle if rect entry
        runFunction(ITM_REtoCX);
      }
      else if(dataTypeX == dtComplex34) {
        runFunction(ITM_CXtoRE);
      }
      else if(dataTypeX == dtReal34Matrix && dataTypeY == dtReal34Matrix) {
        runFunction(ITM_REtoCX);
      }
      else if(dataTypeX == dtComplex34Matrix) {
        runFunction(ITM_CXtoRE);
      }
      else {
        if( (!polarOk && getSystemFlag(FLAG_POLAR)) || (!rectOk && !getSystemFlag(FLAG_POLAR))) {
          displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        }
        else {
          displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X); // Invalid input data type for this operation
        }
      #if(EXTRA_INFO_ON_CALC_ERROR == 1)
        if(!polarOk && getSystemFlag(FLAG_POLAR)) {
          sprintf(errorMessage, "You cannot use CC or COMPLEX to create a Polar complex number with %s(%s) in X and %s(%s) in Y!",       getDataTypeName(getRegisterDataType(REGISTER_X), true, false), getRegisterTagName((REGISTER_X), 0), getDataTypeName(getRegisterDataType(REGISTER_Y), true, false), getRegisterTagName((REGISTER_Y), 0));
        } else
        if(!rectOk && !getSystemFlag(FLAG_POLAR)) {
          sprintf(errorMessage, "You cannot use CC or COMPLEX to create a Rectangular complex number with %s(%s) in X and %s(%s) in Y!", getDataTypeName(getRegisterDataType(REGISTER_X), true, false), getRegisterTagName((REGISTER_X), 0), getDataTypeName(getRegisterDataType(REGISTER_Y), true, false), getRegisterTagName((REGISTER_Y), 0));
        } else
        sprintf(errorMessage, "You cannot use CC or COMPLEX with %s in X and %s in Y!", getDataTypeName(getRegisterDataType(REGISTER_X), true, false), getDataTypeName(getRegisterDataType(REGISTER_Y), true, false));
        moreInfoOnError("In function fnKeyCC:", errorMessage, NULL, NULL);
      #endif // (EXTRA_INFO_ON_CALC_ERROR == 1)
      }
      return;                            //JM
    }

    if(complex_Type == ITM_op_j) {
      temporaryFlagRect = true;
      temporaryFlagPolar = false;
    }
    else if(complex_Type == ITM_op_j_pol) {
      temporaryFlagRect = false;
      temporaryFlagPolar = true;
    }
    else {
      temporaryFlagRect = false;
      temporaryFlagPolar = false;
    }

    switch(calcMode) {                     //JM
      case CM_NIM: {
        addItemToNimBuffer(ITM_CC);
        break;
      }

      case CM_MIM: {
        mimAddNumber(ITM_CC);
        break;
      }

      case CM_PEM: {
        if(aimBuffer[0] != 0 && !getSystemFlag(FLAG_ALPHA)) {
          pemAddNumber(ITM_CC);
        }
        break;
      }

      case CM_EIM:
      case CM_REGISTER_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FONT_BROWSER:
      case CM_PLOT_STAT:
      case CM_TIMER:
      case CM_LISTXY:                     //JM
      case CM_GRAPH: {                     //JM
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyCC", calcMode, "CC");
        displayBugScreen(errorMessage);
      }
    }
  #endif // !TESTSUITE_BUILD
}



void fnKeyBackspace(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    uint16_t lg;
#if !defined(SAVE_SPACE_DM42_10)
    uint8_t *nextStep;
#endif //SAVE_SPACE_DM42_10

    if(temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL) {
      temporaryInformation = TI_NO_INFO;
      keyActionProcessed = true;
      return;
    }

    if(tam.mode) {
      tamProcessInput(ITM_BACKSPACE);
      return;
    }

    switch(calcMode) {
      case CM_NORMAL: {
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else {
//          runFunction(ITM_CLX);          //JM old
          showFunctionName(ITM_CLX, 1000, ""); //JM 1000ms = 1s
        }
        break;
      }

      case CM_AIM: {
        if(catalog && catalog != CATALOG_MVAR) {
          if(stringByteLength(aimBuffer) > 0) {
            lg = stringLastGlyph(aimBuffer);
            aimBuffer[lg] = 0;
            xCursor = showString(aimBuffer, &standardFont, 1, Y_POSITION_OF_AIM_LINE + 6, vmNormal, true, true);
          }
        }
        else if(stringByteLength(aimBuffer) > 0) {

#if defined(TEXT_MULTILINE_EDIT)
//JMCURSORvv SPLIT STRING AT CURSOR POSITION
          uint8_t T_cursorPos_tmp;
          T_cursorPos_tmp = aimBuffer[T_cursorPos];
          aimBuffer[T_cursorPos] = 0;                  //break it at the current cursor
          lg = stringLastGlyph(aimBuffer);             //find beginning of last glyoh, to delete
          aimBuffer[lg] = 0;                           //delete it
          aimBuffer[T_cursorPos] = T_cursorPos_tmp;    //Restore broken glyph in middle at break point
          uint16_t ix = 0;
          while(aimBuffer[ix+T_cursorPos] != 0) {      //copy second part to append to first part
            aimBuffer[ix+lg] = aimBuffer[ix+T_cursorPos];
            ix++;
          }
          aimBuffer[ix+lg]=0;                          //end new buffer
          //printf("newXCursor=%d  T_cursorPos=%d  stringLastGlyph(aimBuffer)=%d\n",newXCursor,T_cursorPos,stringLastGlyph(aimBuffer));
          if(T_cursorPos <= 1 + stringLastGlyph(aimBuffer)) {
            fnT_ARROW(ITM_T_LEFT_ARROW);                               //move cursor one left
          }
//JMCURSOR^^
#else // !TEXT_MULTILINE_EDIT
          lg = stringLastGlyph(aimBuffer);
          aimBuffer[lg] = 0;
#endif // TEXT_MULTILINE_EDIT

        }
        break;
      }

      case CM_NIM: {
        addItemToNimBuffer(ITM_BACKSPACE);
        break;
      }

      case CM_MIM: {
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else {
          mimAddNumber(ITM_BACKSPACE);
        }
        break;
      }

      case CM_EIM: {
        if(xCursor > 0) {
          char *srcPos = aimBuffer;
          char *dstPos = aimBuffer;
          char *lstPos = aimBuffer + stringNextGlyph(aimBuffer, stringLastGlyph(aimBuffer));
          --xCursor;
          for(uint32_t i = 0; i < xCursor; ++i) {
            dstPos += (*dstPos & 0x80) ? 2 : 1;
          }
          srcPos = dstPos + ((*dstPos & 0x80) ? 2 : 1);
          for(; srcPos <= lstPos;) {
            *(dstPos++) = *(srcPos++);
          }
        }
        break;
      }

      //case CM_ASM_OVER_NORMAL:
      //  addItemToBuffer(ITM_BACKSPACE);
      //  break;
      //}

      case CM_REGISTER_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FONT_BROWSER: {
        calcMode = previousCalcMode;
        break;
      }

      case CM_BUG_ON_SCREEN:
      case CM_PLOT_STAT:
      case CM_GRAPH: {
        if(calcMode == CM_PLOT_STAT) {
          for(int16_t ii = 0; ii < 3; ii++) {
            if( (softmenuStack[0].softmenuId > 1) && !(
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_HIST) ||
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_PLOTTING) ||
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_MODEL) ||
              (-softmenu[softmenuStack[0].softmenuId].menuItem == MNU_REGR)
              )) {
              popSoftmenu();
            }
          }
        }
        else {
          popSoftmenu();
        }

        lastPlotMode = PLOT_NOTHING;
        plotSelection = 0;

        calcModeNormal();
        #if defined(DEBUGUNDO)
          printf(">>> Undo from fnKeyExit\n");
        #endif // DEBUGUNDO
        fnUndo(NOPARAM);
        fnClDrawMx();
        restoreStats();
        break;
      }

      case CM_LISTXY: {                    //JM vv
        calcMode = previousCalcMode;
        keyActionProcessed = true;
        break;
      }                                    //JM ^^

      case CM_CONFIRMATION: {
        calcMode = previousCalcMode;
        temporaryInformation = TI_NO_INFO;
        if(programRunStop == PGM_WAITING) {
          programRunStop = PGM_STOPPED;
        }
        break;
      }

      case CM_PEM: {
        #if !defined(SAVE_SPACE_DM42_10)

        if(lastErrorCode != 0) {
          lastErrorCode = 0;
          return;
        }
        if(getSystemFlag(FLAG_ALPHA)) {
          pemAlpha(ITM_BACKSPACE);
          if(aimBuffer[0] == 0 && !getSystemFlag(FLAG_ALPHA)) {
            if(currentLocalStepNumber > 1) {
              --currentLocalStepNumber;
              defineCurrentStep();
              if(!programListEnd) {
                scrollPemBackwards();
            }
            }
            else {
              pemCursorIsZerothStep = true;
            }
          }
        }
        else if(aimBuffer[0] == 0) {
          if(currentLocalStepNumber > 1) {
            pemCursorIsZerothStep = false;
          }
          if(!pemCursorIsZerothStep) {
            nextStep = findNextStep(currentStep);
            if(*currentStep != 255 || *(currentStep + 1) != 255) { // Not the last END
              deleteStepsFromTo(currentStep, nextStep);
            }
            if(currentLocalStepNumber > 1) {
              --currentLocalStepNumber;
              defineCurrentStep();
            }
            else {
              pemCursorIsZerothStep = true;
            }
            scrollPemBackwards();
          }
        }
        else {
          pemAddNumber(ITM_BACKSPACE);
          if(aimBuffer[0] == 0 && currentLocalStepNumber > 1) {
            currentStep = findPreviousStep(currentStep);
            --currentLocalStepNumber;
            if(!programListEnd) {
              scrollPemBackwards();
            }
          }
        }
        #endif // !SAVE_SPACE_DM42_10
        break;
      }

      case CM_ASSIGN: {
        if(itemToBeAssigned == 0) {
          if(!tam.alpha) {
            calcMode = previousCalcMode;
          }
          else if(stringByteLength(aimBuffer) != 0) {
            // Delete the last character
            int16_t lg = stringLastGlyph(aimBuffer);
            aimBuffer[lg] = 0;
          }
          else {
            assignLeaveAlpha();
            itemToBeAssigned = ITM_BACKSPACE;
          }
        }
        else {
          if(!tam.alpha) {
            itemToBeAssigned = 0;
          }
          else if(stringByteLength(aimBuffer) != 0) {
            // Delete the last character
            int16_t lg = stringLastGlyph(aimBuffer);
            aimBuffer[lg] = 0;
          }
          else {
            assignLeaveAlpha();
            if(asnKey[1] != 0) {
              assignToKey((char *)asnKey);
            }
            else {
              _assignToMenu(asnKey);
            }
            calcMode = previousCalcMode;
            shiftF = shiftG = false;
            refreshScreen();
          }
        }
        break;
      }

      case CM_TIMER: {
        if(lastErrorCode != 0) {
          lastErrorCode = 0;
        }
        else {
          fnBackspaceTimerApp();
        }
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyBackspace", calcMode, "BACKSPACE");
        displayBugScreen(errorMessage);
    }
    }
  #endif // !TESTSUITE_BUILD
}


#if !defined(TESTSUITE_BUILD)
static bool_t activatescroll(void) { //jm
   //This is the portion that allows the arrows shortcut to SHOW in NORMAL MODE
   int16_t menuId = softmenuStack[0].softmenuId; //JM
   return (calcMode == CM_NORMAL) &&
          (temporaryInformation == TI_SHOW_REGISTER_BIG || temporaryInformation == TI_SHOW_REGISTER_SMALL) &&
          (softmenu[menuId].menuItem != -MNU_EQN)
//remove menu interlock completely, since the NEW SHOW takes over the screen and does not respect menu operation
//    &&    (
//            ((menuId == 0) && !BASE_MYM) ||
//            ((menuId == 0) && (softmenu[menuId].numItems<=18)) ||
//            ((menuId >= NUMBER_OF_DYNAMIC_SOFTMENUS) && (softmenu[menuId].numItems<=18))
//          )
          ;
 }
 #endif // !TESTSUITE_BUILD

#define RBR_INCDEC1 10

void fnKeyUp(uint16_t unusedButMandatoryParameter) {
  doRefreshSoftMenu = true;     //dr
  #if !defined(TESTSUITE_BUILD)
    int16_t menuId = softmenuStack[0].softmenuId; //JM

    if(activatescroll() && !tam.mode) { //JMSHOW vv
      fnShow_SCROLL(1);
      refreshScreen();
      return;
    }                              //JMSHOW ^^

    if(tam.mode == TM_KEY && !tam.keyInputFinished) {
      if(tam.digitsSoFar == 0) {
        tamProcessInput(ITM_1);
        tamProcessInput(ITM_9);
        shiftF = shiftG = false;
        refreshScreen();
      }
      return;
    }
    if(tam.mode && !catalog) {
      if(tam.alpha) {
        resetAlphaSelectionBuffer();
        if(currentSoftmenuScrolls()) {
          menuUp();
        }
        else {
          alphaCase = AC_UPPER;
        }
      }
      else {
        addItemToBuffer(ITM_Max);
      }
      return;
    }

    if((calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM) && softmenu[softmenuStack[0].softmenuId].menuItem == -ITM_MENU) {
      dynamicMenuItem = NUMBER_OF_DYNAMIC_SOFTMENUS + 1;
      fnProgrammableMenu(NOPARAM);
      return;
    }

    switch(calcMode) {
      case CM_NORMAL:
      case CM_AIM:
      case CM_NIM:
      case CM_EIM:
      case CM_PLOT_STAT:
      case CM_GRAPH: {
        doRefreshSoftMenu = true;     //jm
        resetAlphaSelectionBuffer();

        //JM Arrow up and down if no menu other than AHOME of MyA       //JMvv
        if(!arrowCasechange && calcMode == CM_AIM && isJMAlphaSoftmenu(menuId)) {
          fnT_ARROW(ITM_UP1);
        }
              //ignoring the base menu, MY_ALPHA_MENU below
              // make this keyActionProcessed = false; to have arrows up and down placed in bufferize
              // make arrowCasechnage true
                                                                       //JM^^
        else

        if(currentSoftmenuScrolls()) {
          menuUp();
        }
        else if((calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM) && (numberOfFormulae < 2 || softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_EQN)) {
          screenUpdatingMode = SCRUPD_AUTO;
          if(calcMode == CM_NIM) {
            closeNim();
          }
          if(calcMode == CM_AIM) {
            closeAim();
          }
          fnBst(NOPARAM);
          #if defined(DMCP_BUILD)
            lcd_refresh();
          #else // !DMCP_BUILD
            refreshLcd(NULL);
          #endif // DMCP_BUILD
        }
        if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PLOT_LR){
          strcpy(plotStatMx, "STATS");
          fnPlotStat(PLOT_NXT);
        }
        else if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQN){
          if(currentFormula == 0) {
            currentFormula = numberOfFormulae;
          }
          --currentFormula;
          screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
        }
        else {
          //alphaCase = AC_UPPER;
        }
        break;
      }

      case CM_REGISTER_BROWSER: {
        rbr1stDigit = true;
        if(rbrMode == RBR_GLOBAL) {
          currentRegisterBrowserScreen = modulo(currentRegisterBrowserScreen + RBR_INCDEC1, FIRST_LOCAL_REGISTER);
        }
        else if(rbrMode == RBR_LOCAL) {
          currentRegisterBrowserScreen = modulo(currentRegisterBrowserScreen - FIRST_LOCAL_REGISTER + 1, currentNumberOfLocalRegisters) + FIRST_LOCAL_REGISTER;
        }
        else if(rbrMode == RBR_NAMED) {
          currentRegisterBrowserScreen = modulo(currentRegisterBrowserScreen - FIRST_NAMED_VARIABLE + 1, numberOfNamedVariables + LAST_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE - 11) + FIRST_NAMED_VARIABLE;
        }
        else {
          sprintf(errorMessage, commonBugScreenMessages[bugMsgRbrMode], "fnKeyUp", "UP", rbrMode);
          displayBugScreen(errorMessage);
        }
        break;
      }

      case CM_FLAG_BROWSER: {
        currentFlgScr--;                          //JM removed the 3-x part
        break;
      }

      case CM_ASN_BROWSER: {
        currentAsnScr++;                          //JM removed the 3-x part
        if(currentAsnScr == 0 ||currentAsnScr >= 7) {
          currentAsnScr = 1;
        }
        break;
      }

      case CM_FONT_BROWSER: {
        if(currentFntScr >= 2) {
          currentFntScr--;
        }
        break;
      }

      case CM_PEM: {
        resetAlphaSelectionBuffer();
        if(getSystemFlag(FLAG_ALPHA) && alphaCase == AC_LOWER) {
          alphaCase = AC_UPPER;
          if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_alpha_omega || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHAintl) {
            softmenuStack[0].softmenuId--; // Switch to the upper case menu
          }
        }
        else if(currentSoftmenuScrolls()) {
          menuUp();
        }
        else {
          if(getSystemFlag(FLAG_ALPHA) && aimBuffer[0] == 0 && !tam.mode) {
            pemAlpha(ITM_BACKSPACE);
          }
          fnBst(NOPARAM);
        }
        break;
      }

      case CM_LISTXY: {                    //JM vv
        ListXYposition += 10;
        break;
      }                                    //JM ^^

      case CM_MIM: {
        #if defined(NOMATRIXCURSORS)
          if(currentSoftmenuScrolls()) {   //JM remove to allow normal arrows to work as cursors
            menuUp();                      //JM
          }                                //JM
        #else  // !NOMATRIXCURSORS             //JM
          keyActionProcessed = false;      //JM
        #endif // NOMATRIXCURSORS             //JM
        break;                             //JM
      }

      case CM_ASSIGN: {
        if(currentSoftmenuScrolls()) {
          menuUp();
        }
        else if(tam.alpha && alphaCase == AC_LOWER) {
          alphaCase = AC_UPPER;
        }
        else if(tam.alpha && itemToBeAssigned == 0 && aimBuffer[0] == 0) {
          assignLeaveAlpha();
          itemToBeAssigned = ITM_UP1;
        }
        else if(tam.alpha && aimBuffer[0] == 0) {
          assignLeaveAlpha();
          if(asnKey[1] != 0) {
            assignToKey((char *)asnKey);
          }
          else {
            _assignToMenu(asnKey);
          }
          calcMode = previousCalcMode;
          shiftF = shiftG = false;
          refreshScreen();
        }
        break;
      }

      case CM_TIMER: {
        fnUpTimerApp();
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyUp", calcMode, "UP");
        displayBugScreen(errorMessage);
    }
    }
  #endif // !TESTSUITE_BUILD
}



void fnKeyDown(uint16_t unusedButMandatoryParameter) {
  doRefreshSoftMenu = true;     //dr
  #if !defined(TESTSUITE_BUILD)
    int16_t menuId = softmenuStack[0].softmenuId; //JM

    if(activatescroll() && !tam.mode) { //JMSHOW vv
      fnShow_SCROLL(2);
      refreshScreen();
      return;
    }                             //JMSHOW ^^

    if(tam.mode == TM_KEY && !tam.keyInputFinished) {
      if(tam.digitsSoFar == 0) {
        tamProcessInput(ITM_2);
        tamProcessInput(ITM_0);
        shiftF = shiftG = false;
        refreshScreen();
      }
      return;
    }
    if(tam.mode && !catalog) {
      if(tam.alpha) {
        resetAlphaSelectionBuffer();
        if(currentSoftmenuScrolls()) {
          menuDown();
        }
        else {
          alphaCase = AC_LOWER;
        }
      }
      else {
        addItemToBuffer(ITM_Min);
      }
      return;
    }

    if((calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM) && softmenu[softmenuStack[0].softmenuId].menuItem == -ITM_MENU) {
      dynamicMenuItem = NUMBER_OF_DYNAMIC_SOFTMENUS + 1;
      fnProgrammableMenu(NOPARAM);
      return;
    }

    switch(calcMode) {
      case CM_NORMAL:
      case CM_AIM:
      case CM_NIM:
      case CM_EIM:
      case CM_PLOT_STAT:
      case CM_GRAPH: {
        doRefreshSoftMenu = true;     //jm
        resetAlphaSelectionBuffer();

        //JM Arrow up and down if AHOME of MyA       //JMvv
        if(!arrowCasechange && calcMode == CM_AIM && isJMAlphaSoftmenu(menuId)) {
          fnT_ARROW(ITM_DOWN1);
        }
              //ignoring the base menu, MY_ALPHA_MENU below
              // make this keyActionProcessed = false; to have arrows up and down placed in bufferize
              // make arrowCasechnage true
                                                                       //JM^^
        else

        if(currentSoftmenuScrolls()) {
          menuDown();
        }
        else if((calcMode == CM_NORMAL || calcMode == CM_AIM || calcMode == CM_NIM) && (numberOfFormulae < 2 || softmenu[softmenuStack[0].softmenuId].menuItem != -MNU_EQN)) {
          screenUpdatingMode = SCRUPD_AUTO;
          if(calcMode == CM_NIM) {
            closeNim();
          }
          if(calcMode == CM_AIM) {
            closeAim();
          }
          fnSst(NOPARAM);
          #if defined(DMCP_BUILD)
            lcd_refresh();
          #else // !DMCP_BUILD
            refreshLcd(NULL);
          #endif // DMCP_BUILD
        }
        if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PLOT_LR){
          strcpy(plotStatMx, "STATS");
          fnPlotStat(PLOT_REV); //REVERSE
        }
        else if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQN){
          ++currentFormula;
          if(currentFormula == numberOfFormulae) {
            currentFormula = 0;
          }
          screenUpdatingMode &= ~SCRUPD_MANUAL_MENU;
        }
        else {
          //alphaCase = AC_LOWER;
        }
        break;
      }

      case CM_REGISTER_BROWSER: {
        rbr1stDigit = true;
        if(rbrMode == RBR_GLOBAL) {
          currentRegisterBrowserScreen = modulo(currentRegisterBrowserScreen - RBR_INCDEC1, FIRST_LOCAL_REGISTER);
        }
        else if(rbrMode == RBR_LOCAL) {
          currentRegisterBrowserScreen = modulo(currentRegisterBrowserScreen - FIRST_LOCAL_REGISTER - 1, currentNumberOfLocalRegisters) + FIRST_LOCAL_REGISTER;
        }
        else if(rbrMode == RBR_NAMED) {
          currentRegisterBrowserScreen = modulo(currentRegisterBrowserScreen - FIRST_NAMED_VARIABLE - 1, numberOfNamedVariables + LAST_RESERVED_VARIABLE - FIRST_RESERVED_VARIABLE - 11) + FIRST_NAMED_VARIABLE;
        }
        else {
          sprintf(errorMessage, commonBugScreenMessages[bugMsgRbrMode], "fnKeyDown", "DOWN", rbrMode);
          displayBugScreen(errorMessage);
        }
        break;
      }

    case CM_FLAG_BROWSER: {
        currentFlgScr++;                          //JM removed the 3-x part
        break;
      }

    case CM_ASN_BROWSER: {
        currentAsnScr--;
        if(currentAsnScr == 0 || currentAsnScr >= 7) {
          currentAsnScr = 6;
        }
        break;
      }

      case CM_FONT_BROWSER: {
        if(currentFntScr < numScreensNumericFont + numScreensStandardFont + numScreensTinyFont) {
          currentFntScr++;
        }
        break;
      }

      case CM_PEM: {
        resetAlphaSelectionBuffer();
        if(getSystemFlag(FLAG_ALPHA) && alphaCase == AC_UPPER) {
          alphaCase = AC_LOWER;
          if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHA_OMEGA || softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHAINTL) {
            softmenuStack[0].softmenuId++; // Switch to the lower case menu
          }
        }
        else if(currentSoftmenuScrolls()) {
          menuDown();
        }
        else {
          if(getSystemFlag(FLAG_ALPHA) && aimBuffer[0] == 0 && !tam.mode) {
            pemAlpha(ITM_BACKSPACE);
            fnBst(NOPARAM); // Set the PGM pointer to the original position
          }
          fnSst(NOPARAM);
        }
        break;
      }

      case CM_LISTXY: {                     //JM vv
        ListXYposition -= 10;
        break;
      }                                     //JM ^^

      case CM_MIM: {
        #if defined(NOMATRIXCURSORS)
          if(currentSoftmenuScrolls()) {   //JM remove to allow normal arrows to work as cursors
            menuDown();                    //JM
          }                                //JM
        #else  // !NOMATRIXCURSORS             //JM
          keyActionProcessed = false;      //JM
        #endif // NOMATRIXCURSORS             //JM
        break;                             //JM
      }

      case CM_ASSIGN: {
        if(currentSoftmenuScrolls()) {
          menuDown();
        }
        else if(tam.alpha && (itemToBeAssigned == 0 || tam.mode == TM_NEWMENU) && alphaCase == AC_UPPER) {
          alphaCase = AC_LOWER;
        }
        else if(tam.alpha && itemToBeAssigned == 0 && aimBuffer[0] == 0) {
          assignLeaveAlpha();
          itemToBeAssigned = ITM_DOWN1;
        }
        else if(tam.alpha && aimBuffer[0] == 0) {
          assignLeaveAlpha();
          if(asnKey[1] != 0) {
            assignToKey((char *)asnKey);
          }
          else {
            _assignToMenu(asnKey);
          }
          calcMode = previousCalcMode;
          shiftF = shiftG = false;
          refreshScreen();
        }
        break;
      }

      case CM_TIMER: {
        fnDownTimerApp();
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyDown", calcMode, "DOWN");
        displayBugScreen(errorMessage);
    }
    }
  #endif // !TESTSUITE_BUILD
}



void fnKeyDotD(uint16_t unusedButMandatoryParameter) {
  #if !defined(TESTSUITE_BUILD)
    switch(calcMode) {
      case CM_NORMAL: {
        constantFractionsOn = false; //JM
        if(getSystemFlag(FLAG_FRACT)) {
          clearSystemFlag(FLAG_FRACT);
        }
        else {
          runFunction(ITM_toREAL);
        }
        break;
      }

      case CM_NIM: {
        addItemToNimBuffer(ITM_dotD);
        break;
      }

      case CM_REGISTER_BROWSER:
      case CM_FLAG_BROWSER:
      case CM_ASN_BROWSER:
      case CM_FONT_BROWSER:
      case CM_PLOT_STAT:
      case CM_GRAPH:
      case CM_MIM:
      case CM_EIM:
      case CM_TIMER:
      case CM_LISTXY: {                    //JM
        break;
      }

      default: {
        sprintf(errorMessage, commonBugScreenMessages[bugMsgCalcModeWhileProcKey], "fnKeyDotD", calcMode, ".d!");
        displayBugScreen(errorMessage);
      }
    }
  #endif // !TESTSUITE_BUILD
}



void setLastKeyCode(int key) {
  if(1 <= key && key <= 43) {
    if(key <=  6) {
      lastKeyCode = key      + 20;
    }
    else if(key <= 12) {
      lastKeyCode = key -  6 + 30;
    }
    else if(key <= 17) {
      lastKeyCode = key - 12 + 40;
    }
    else if(key <= 22) {
      lastKeyCode = key - 17 + 50;
    }
    else if(key <= 27) {
      lastKeyCode = key - 22 + 60;
    }
    else if(key <= 32) {
      lastKeyCode = key - 27 + 70;
    }
    else if(key <= 37) {
      lastKeyCode = key - 32 + 80;
    }
    else if(key <= 43) {
      lastKeyCode = key - 37 + 10; // function keys
    }
  }
}
