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
 * \file asnBrowser.c The assign browser application
 ***********************************************/
#include "browsers/asnBrowser.h"
#include "typeDefinitions.h"

#include "items.h"
#include "flags.h"
#include "fonts.h"
#include "c43Extensions/radioButtonCatalog.h"
#include "charString.h"
#include "screen.h"
#include "softmenus.h"
#include <string.h>

#include "c47.h"



#if !defined(TESTSUITE_BUILD)
  #if !defined(SAVE_SPACE_DM42_8ASN)
  static void fnAsnDisplay(uint8_t page) {                // Heavily modified by JM from the original fnShow
  #define YOFF 32
    int xx,yy;
    int kk = 0;
    int16_t key;
    int16_t pixelsPerSoftKey;
    char Name[16];
    xx = 0;
    yy = 1;
    clearScreen();
    showSoftmenuCurrentPart();
        showString(fnAsnDisplayUSER ? "(USER KEYS)" : "(STD KEYS)", &standardFont, 280, YOFF, vmNormal, false, false);
        switch(page) {
          case 1:   showString("unshifted keyboard mapping", &standardFont, 30, YOFF, vmNormal, false, false); break;
          case 2:   showString("f-shift keyboard mapping",   &standardFont, 30, YOFF, vmNormal, false, false); break;
          case 3:   showString("g-shift keyboard mapping",   &standardFont, 30, YOFF, vmNormal, false, false); break;
          case 4:   showString("alpha keyboard mapping",     &standardFont, 30, YOFF, vmNormal, false, false); break;
          case 5:   showString("alpha f-shift mapping",      &standardFont, 30, YOFF, vmNormal, false, false); break;
          case 6:   showString("alpha g-shift mapping",      &standardFont, 30, YOFF, vmNormal, false, false); break;
          default:break;
        }
    showString( "[" STD_UP_ARROW "][" STD_DOWN_ARROW "] Browse - [.] View STD keys", &standardFont, 30, 220, vmNormal, false, false);

    for(key=0; key<37; key++) {
      if(key == 6 || key ==12 || key == 17 || key == 22 || key == 27 || key == 32) {
          xx = 0;
          yy ++;
      }
      if(key == 12) pixelsPerSoftKey = (int)((float)SCREEN_WIDTH / 3.0f + 0.5f); else
      if(key <  12) pixelsPerSoftKey = (int)((float)SCREEN_WIDTH / 6.0f + 0.5f); else
                    pixelsPerSoftKey = (int)((float)SCREEN_WIDTH / 5.0f + 0.5f);

      bool_t Norm_Key_00_used = false;
      if(fnAsnDisplayUSER) {
        switch(page) {// in user mode, user keys override if set, and if not set, the allows +NRM to override
          case 1:
             kk = kbd_usr[key].primary;  //not even the +NRM key location, therefore normal user operation
           break;
          case 2: kk = kbd_usr[key].fShifted; break;
          case 3: kk = kbd_usr[key].gShifted; break;
          case 4: kk = kbd_usr[key].primaryAim;  break;
          case 5: kk = kbd_usr[key].fShiftedAim; break;
          case 6: kk = kbd_usr[key].gShiftedAim; break;
          default: ;
        }
      }
      else {
        switch(page) { //in non-user mode, +NRM overrides kbd_std
          case 1: if(key == Norm_Key_00_key) {
              kk = Norm_Key_00.func;
              Norm_Key_00_used = Norm_Key_00.func != kbd_std[key].primary;    //only display in reverse and [] if different from kbd_std
            }
            else {
              kk = kbd_std[key].primary;
            }
            break;
          case 2: kk = kbd_std[key].fShifted; break;
          case 3: kk = kbd_std[key].gShifted; break;
          case 4: kk = kbd_std[key].primaryAim; break;
          case 5: kk = kbd_std[key].fShiftedAim; break;
          case 6: kk = kbd_std[key].gShiftedAim; break;
          default: ;
        }
      }

      strcpy(Name, indexOfItems[max(kk,-kk)].itemSoftmenuName);
      if(strcmp(Name, "0000") == 0) {
        Name[0]=0;
      }
      if (Norm_Key_00_used) {
         if((Norm_Key_00.funcParam[0] != 0) && ((Norm_Key_00.func == -MNU_DYNAMIC)|| (Norm_Key_00.func == ITM_XEQ) || (Norm_Key_00.func == ITM_RCL)))  {
          strcpy(Name, (char *)&Norm_Key_00.funcParam);       // name of a user menu, program or variable assigned to the Norm key
        }         
      }
      else {
        char *funcParam = (char *)getNthString((uint8_t *)userKeyLabel, key*6+(page-1));
        if((funcParam[0] != 0) && ((strcmp(Name, "DYNMNU") == 0) || (strcmp(Name, "XEQ") == 0) || (strcmp(Name, "RCL") == 0)))  {
          strcpy(Name, (char *)getNthString((uint8_t *)userKeyLabel, key*6+(page-1)));       // name of a user menu, program or variable assigned to a key
        }
      }


      char tmp3[20];
      tmp3[0]=0;
      if(Norm_Key_00_used) {
        stringAppend(tmp3 + stringByteLength(tmp3), "[");
        stringAppend(tmp3 + stringByteLength(tmp3), Name);
        stringAppend(tmp3 + stringByteLength(tmp3), "]");
        Name[0]=0;
        stringAppend(Name + stringByteLength(Name), tmp3);
      }

      showKey(Name, xx*pixelsPerSoftKey, xx*pixelsPerSoftKey+pixelsPerSoftKey, YOFF+yy*SOFTMENU_HEIGHT, YOFF+(yy+1)*SOFTMENU_HEIGHT, xx == 5, !Norm_Key_00_used ? vmNormal : vmReverse, true, true, NOVAL, NOVAL, NOTEXT);

      if(fnAsnDisplayUSER &&
          ( ((page == 1) && (kbd_std[key].primary == kbd_usr[key].primary)  )       ||
            ((page == 2) && (kbd_std[key].fShifted == kbd_usr[key].fShifted))       ||
            ((page == 3) && (kbd_std[key].gShifted == kbd_usr[key].gShifted))       ||
            ((page == 4) && (kbd_std[key].primaryAim == kbd_usr[key].primaryAim))   ||
            ((page == 5) && (kbd_std[key].fShiftedAim == kbd_usr[key].fShiftedAim)) ||
            ((page == 6) && (kbd_std[key].gShiftedAim == kbd_usr[key].gShiftedAim))
           )
        ) {
        greyOutBox(xx*pixelsPerSoftKey, xx*pixelsPerSoftKey+pixelsPerSoftKey, YOFF+yy*SOFTMENU_HEIGHT, YOFF+(yy+1)*SOFTMENU_HEIGHT);
      }
    xx++;
    }

    temporaryInformation = TI_NO_INFO;
  }
  #endif // !SAVE_SPACE_DM42_8ASN
#endif // !TESTSUITE_BUILD


void fnAsnViewer(uint16_t unusedButMandatoryParameter) {
#if !defined(TESTSUITE_BUILD)
  #if !defined(SAVE_SPACE_DM42_8ASN)
    hourGlassIconEnabled = false;
    if(calcMode != CM_ASN_BROWSER) {
      previousCalcMode = calcMode;
      calcMode = CM_ASN_BROWSER;
      clearSystemFlag(FLAG_ALPHA);
      currentAsnScr = 1;
      return;
    }
  fnAsnDisplay(currentAsnScr);
  #endif // !SAVE_SPACE_DM42_8ASN
#endif // !TESTSUITE_BUILD

  }
