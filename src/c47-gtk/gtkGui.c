// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"


//#define DEBUGMODES


static int16_t _keyCodeFromGdkKey(uint32_t gdkKey);


#if defined(PC_BUILD)
  #include <gtk/gtk.h>
  #include <gdk/gdk.h>

  #include "gtkGui.h"

  GtkWidget *grid;
  #if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
    GtkWidget *backgroundImage;
    GtkWidget *lblFKey2;
    GtkWidget *lblGKey2;
    //GtkWidget *lblEKey;
    //GtkWidget *lblEEKey;
    //GtkWidget *lblSKey;
    GtkWidget *lblBehindScreen;

    GtkWidget *btn11,   *btn12,   *btn13,   *btn14,   *btn15,   *btn16;
    GtkWidget *btn21,   *btn22,   *btn23,   *btn24,   *btn25,   *btn26;
    GtkWidget *lbl21F,  *lbl22F,  *lbl23F,  *lbl24F,  *lbl25F,  *lbl26F;
    GtkWidget *lbl21G,  *lbl22G,  *lbl23G,  *lbl24G,  *lbl25G,  *lbl26G;
    GtkWidget *lbl21L,  *lbl22L,  *lbl23L,  *lbl24L,  *lbl25L,  *lbl26L;
    GtkWidget *lbl21Gr, *lbl22Gr, *lbl23Gr, *lbl24Gr, *lbl25Gr, *lbl26Gr;
    GtkWidget *btn21A,  *btn22A,  *btn23A,  *btn24A,  *btn25A,  *btn26A;    //dr - new AIM
    GtkWidget *lbl21Fa, *lbl22Fa, *lbl23Fa, *lbl24Fa, *lbl25Fa, *lbl26Fa;                                 //JM

    GtkWidget *btn31,   *btn32,   *btn33,   *btn34,   *btn35,   *btn36;
    GtkWidget *lbl31F,  *lbl32F,  *lbl33F,  *lbl34F,  *lbl35F,  *lbl36F;
    GtkWidget *lbl31G,  *lbl32G,  *lbl33G,  *lbl34G,  *lbl35G,  *lbl36G;
    GtkWidget *lbl31L,  *lbl32L,  *lbl33L,  *lbl34L,  *lbl35L,  *lbl36L;
    GtkWidget *lbl31Gr, *lbl32Gr, *lbl33Gr, *lbl34Gr, *lbl35Gr, *lbl36Gr;
    GtkWidget *btn31A,  *btn32A,  *btn33A,  *btn34A,  *btn35A,  *btn36A;    //dr - new AIM
    GtkWidget *lbl31Fa, *lbl32Fa, *lbl33Fa,  *lbl34Fa, *lbl35Fa, *lbl36Fa;                                 //JMALPHA2

    GtkWidget *btn41,   *btn42,   *btn43,   *btn44,   *btn45;
    GtkWidget *lbl41F,  *lbl42F,  *lbl43F,  *lbl44F,  *lbl45F;
    GtkWidget *lbl41G,  *lbl42G,  *lbl43G,  *lbl44G,  *lbl45G;
    GtkWidget *lbl41L,  *lbl42L,  *lbl43L,  *lbl44L,  *lbl45L;
    GtkWidget *lbl41Gr, *lbl42Gr, *lbl43Gr, *lbl44Gr, *lbl45Gr;
    GtkWidget           *btn42A,  *btn43A,  *btn44A;                        //vv dr - new AIM
    GtkWidget *lbl41Fa, *lbl42Fa, *lbl43Fa, *lbl44Fa, *lbl45Fa;                                 //^^

    GtkWidget *btn51,   *btn52,   *btn53,   *btn54,   *btn55;
    GtkWidget *lbl51F,  *lbl52F,  *lbl53F,  *lbl54F,  *lbl55F;
    GtkWidget *lbl51G,  *lbl52G,  *lbl53G,  *lbl54G,  *lbl55G;
    GtkWidget *lbl51L,  *lbl52L,  *lbl53L,  *lbl54L,  *lbl55L;
    GtkWidget *lbl51Gr, *lbl52Gr, *lbl53Gr, *lbl54Gr, *lbl55Gr;
    GtkWidget           *btn52A,  *btn53A,  *btn54A,  *btn55A;              //vv dr - new AIM
    GtkWidget *lbl51Fa, *lbl52Fa, *lbl53Fa, *lbl54Fa, *lbl55Fa;             //^^

    GtkWidget *btn61,   *btn62,   *btn63,   *btn64,   *btn65;
    GtkWidget *lbl61F,  *lbl62F,  *lbl63F,  *lbl64F,  *lbl65F;
    GtkWidget *lbl61G,  *lbl62G,  *lbl63G,  *lbl64G,  *lbl65G;
    GtkWidget *lbl61L,  *lbl62L,  *lbl63L,  *lbl64L,  *lbl65L;
    GtkWidget *lbl61Gr, *lbl62Gr, *lbl63Gr, *lbl64Gr, *lbl65Gr;
    GtkWidget           *btn62A,  *btn63A,  *btn64A,  *btn65A;              //vv dr - new AIM
    GtkWidget *lbl61Fa, *lbl62Fa, *lbl63Fa, *lbl64Fa, *lbl65Fa;             //^^

    GtkWidget *btn71,   *btn72,   *btn73,   *btn74,   *btn75;
    GtkWidget *lbl71F,  *lbl72F,  *lbl73F,  *lbl74F,  *lbl75F;
    GtkWidget *lbl71G,  *lbl72G,  *lbl73G,  *lbl74G,  *lbl75G;
    GtkWidget *lbl71L,  *lbl72L,  *lbl73L,  *lbl74L,  *lbl75L;
    GtkWidget *lbl71Gr, *lbl72Gr, *lbl73Gr, *lbl74Gr, *lbl75Gr;
    GtkWidget *btn71A,  *btn72A,  *btn73A,  *btn74A,  *btn75A;              //vv dr - new AIM
    GtkWidget *lbl71Fa, *lbl72Fa, *lbl73Fa, *lbl74Fa, *lbl75Fa;             //^^

    GtkWidget *btn81,   *btn82,   *btn83,   *btn84,   *btn85;
    GtkWidget *lbl81F,  *lbl82F,  *lbl83F,  *lbl84F,  *lbl85F;
    GtkWidget *lbl81G,  *lbl82G,  *lbl83G,  *lbl84G,  *lbl85G;
    GtkWidget *lbl81L,  *lbl82L,  *lbl83L,  *lbl84L,  *lbl85L;
    GtkWidget *lbl81Gr, *lbl82Gr, *lbl83Gr, *lbl84Gr, *lbl85Gr;
    GtkWidget           *btn82A,  *btn83A,  *btn84A,  *btn85A;              //vv dr - new AIM
    GtkWidget           *lbl82Fa, *lbl83Fa, *lbl84Fa, *lbl85Fa;             //^^
    //GtkWidget *lblOn; //JM
    //JM7 GtkWidget  *lblConfirmY; //JM for Y/N
    //JM7 GtkWidget  *lblConfirmN; //JM for Y/N

    char *cssData;
  #endif // (SIMULATOR_ON_SCREEN_KEYBOARD == 1)



  static gint destroyCalc(GtkWidget* w, GdkEventAny* e, gpointer data) {
    fnStopTimerApp();
    saveCalc();
    gtk_main_quit();

    return 0;
  }


  // The screen-changed event does not seem to be generated reliably.
  //static void onScreenChanged(GtkWidget *w, GdkScreen *oldScreen, gpointer data) {
  //  debugf("Screen changed: force a redraw");
  //  gtk_widget_queue_draw(w);
  //}

  static gboolean onConfigureEvent(GtkWidget *w, GdkEventConfigure *event, gpointer data) {
    //debugf("Configure event: force a redraw");
    gtk_widget_queue_draw(w);
    return FALSE;
  }


//  void btn_Clicked_Gen(bool_t shF, bool_t shG, char *st) {
//    GtkWidget *w;
//    w = NULL;
//    shiftG = shG;
//    uint8_t alphaCase_MEM = alphaCase;
//    bool_t numLock_MEM;  numLock_MEM = getSystemFlag(FLAG_NUMLOCK);  clearSystemFlag(FLAG_NUMLOCK);
//    bool_t u_mem = getSystemFlag(FLAG_USER); clearSystemFlag(FLAG_USER);
//    btnClicked(w, st);
//    if(u_mem) setSystemFlag(FLAG_USER);
//    if(numLock_MEM) {
//      setSystemFlag(FLAG_NUMLOCK);
//    }
//    else {
//      clearSystemFlag(FLAG_NUMLOCK);
//    }
//    alphaCase = alphaCase_MEM;
//    refreshStatusBar();
//  }



  //JM Lower case alpha letters from PC --> produce letters in the current case.
  //JM Upper case alpha letters from PC --> change case and produce letter. Restore case.


//  //JM ALPHA SECTION FOR ALPHAMODE - LOWER CASE PC LETTER INPUT. USE LETTER
//  void btnClicked_LC(GtkWidget *w, gpointer data) {
//    bool_t numLock_MEM;
//    numLock_MEM = getSystemFlag(FLAG_NUMLOCK);
//    clearSystemFlag(FLAG_NUMLOCK);
//    btnClicked(w, data);
//    if(numLock_MEM) {
//      setSystemFlag(FLAG_NUMLOCK);
//    }
//    else {
//      clearSystemFlag(FLAG_NUMLOCK);
//    }
//    refreshStatusBar();
//  }


//  //JM ALPHA SECTION FOR ALPHAMODE -  UPPER CASE PC LETTER INPUT. INVERT C47 CASE. USE LETTER.
//  void btnClicked_UC(GtkWidget *w, gpointer data) {
//    uint8_t alphaCase_MEM;
//    bool_t numLock_MEM;
//    alphaCase_MEM = alphaCase;
//    numLock_MEM = getSystemFlag(FLAG_NUMLOCK);
//    if(alphaCase == AC_UPPER && !pcKeyboardCapsLockEngaged) {alphaCase = AC_LOWER;}
//    else if(alphaCase == AC_LOWER && !pcKeyboardCapsLockEngaged) {alphaCase = AC_UPPER;}
//    clearSystemFlag(FLAG_NUMLOCK);
//    btnClicked(w, data);
//    alphaCase = alphaCase_MEM;
//    if(numLock_MEM) {
//      setSystemFlag(FLAG_NUMLOCK);
//    }
//    else {
//      clearSystemFlag(FLAG_NUMLOCK);
//    }
//    refreshStatusBar();
//  }


  //JM NUMERIC SECTION FOR ALPHAMODE - FORCE Numeral - Numbers from PC --> produce numbers.
  void btnClicked_NU(GtkWidget *w, gpointer data) {
    bool_t numLock_MEM;
    numLock_MEM = getSystemFlag(FLAG_NUMLOCK);

    clearSystemFlag(FLAG_NUMLOCK);
    shiftF = false;       //JM
    shiftG = true;      //JM
    btnClicked(w, data);

    if(numLock_MEM) {
      setSystemFlag(FLAG_NUMLOCK);
    }
    else {
      clearSystemFlag(FLAG_NUMLOCK);
    }
    refreshStatusBar();
  }

//  //Shifted numbers !@#$%^&*() from PC --> activate shift and use numnber 1234567890. Restore case.
//  void btnClicked_SNU(GtkWidget *w, gpointer data) {
//    bool_t numLock_MEM;
//    numLock_MEM = getSystemFlag(FLAG_NUMLOCK);
//
//    clearSystemFlag(FLAG_NUMLOCK);
//    shiftF = true;       //JM
//    shiftG = false;        //JM
//    //btnClicked(NULL, "34");     //Alphadot
//    btnClicked(w, data);
//
//    //Only : is working at this point
//    if(numLock_MEM) {
//      setSystemFlag(FLAG_NUMLOCK);
//    }
//    else {
//      clearSystemFlag(FLAG_NUMLOCK);
//    }
//    refreshStatusBar();
//  }


  uint32_t CTRL_State = 0;
  uint32_t SHIFT_State = 0;
  uint32_t event_keyval = 99999999;

  uint32_t event_command_shift = 0;
  uint32_t event_key_command = 99999999;

  #define AlphaArrowsOffAndUpDn       ((bool_t)( \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_SYSFL ||       \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_VAR ||         \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_PROG ||        \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHA_OMEGA || \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_alpha_omega || \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHAMISC ||   \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHAMATH ||   \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHAINTL ||   \
                                    softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_ALPHAintl ))




  #define EXITIFNIM true
  #define DISABLED  true

  TO_QSPI const char alphakeysC47[38]      = "abcdefghijkl#mno##pqrs#tuvw#xyz_#:,? ";
  TO_QSPI const char alphakeysR47[38]      = "abcdefghij###klm##nopq#rstu#vwxy#z,? ";
  //TO_QSPI const char asciikeysFrom0020[34] = " !\"#$%&\'()*+,-./:;<=>?@[\\]^_{|}~¡";


//                                  w, event_keyval,  97,         shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode ,                   "f",         00",                       modes,         CM_NORMAL,                  ITM_SIGMAPLUS
  static bool_t shortCutCommand(GtkWidget *w, int key,      int keyCode, bool_t condition1,            bool_t exitIfInNIM, bool_t disable, char *shift, char *keyForBtnClicked, uint16_t modes, int16_t requiredCalcMode2, int16_t itemForRunFunction) {
    if(key == keyCode && condition1 && !disable) {
//      #if defined(VERBOSEKEYS)
        printf("\n       shortCutCommand: Disable=%i, Key detected %5i=%5i: exitIfInNIM=%i keyForBtnClicked:%s, calcMode=%i, tam.mode=%i\n",disable, key, keyCode, exitIfInNIM, keyForBtnClicked, calcMode, tam.mode);
//        #endif //VERBOSEKEYS
    }

    if(disable) {
      #if defined(VERBOSEKEYS)
        printf("       shortCutCommand: Returning, shortcut disabled\n");
      #endif //VERBOSEKEYS
      return false;                                  //exit directly for disallowed input condition
    }
    if(labelText && !(key == '\'' || key == GDK_KEY_Up || key == GDK_KEY_Down)) {
      #if defined(VERBOSEKEYS)
        printf("       shortCutCommand: Returning, shortcut blocked in 'labelText'\n");
      #endif //VERBOSEKEYS
      return false;      //exit directly, not allowing shortcuts during label entry, except to start text using "'"
    }
    if( (shiftF || shiftG) &&
        !(shift[0]==0 && keyForBtnClicked[0]!='-') &&
        !(shiftF && shift[0]=='f' && keyForBtnClicked[0]!='-') &&
        !(shiftG && shift[0]=='g' && keyForBtnClicked[0]!='-')) {
      #if defined(VERBOSEKEYS)
        printf("       shortCutCommand: Returning, shift pressed, but no direct key command programmed for shift\n");
      #endif //VERBOSEKEYS
      return false;
    }

    if(key == keyCode && condition1) {
      printf("       shortCutCommand: \n");
      temporaryInformation = TI_NO_INFO;

      //Handle clean NIM if needed and if allowed
        if(exitIfInNIM && (calcMode == CM_NIM) && (calcMode != requiredCalcMode2)) {   //if requiredCalcMode2 then no auto NIM clearing, and handle function below
        printf("       shortCutCommand: Reset mode to NORMAL\n");
        closeNim(); // changed to direct closeNim to prevent a shift from operating fEXIT or gEXIT. //btnClicked(w, "32");                  //EXIT if in NIM
      }

      //Handle menus
      if(itemForRunFunction < 0) {
        #if defined(VERBOSEKEYS)
        //printf("\n       shortCutCommand: Disable=%i, Key detected %5i=%5i: exitIfInNIM=%i keyForBtnClicked:%s, calcMode=%i, tam.mode=%i\n",disable, key, keyCode, exitIfInNIM, keyForBtnClicked, calcMode, tam.mode);
          printf("       shortCutCommand: Handle menus: key:%i: showSoftmenu %i\n",keyCode, itemForRunFunction);
        #endif //VERBOSEKEYS
        showSoftmenu(itemForRunFunction);
        screenUpdatingMode = SCRUPD_AUTO;
        refreshScreen(1);
        return true;
      }

      //Handle functions
      if(((1 << calcMode) & modes) || calcMode == requiredCalcMode2) {
        #if defined(VERBOSEKEYS)
        //printf("\n       shortCutCommand: Disable=%i, Key detected %5i=%5i: exitIfInNIM=%i keyForBtnClicked:%s, calcMode=%i, tam.mode=%i\n",disable, key, keyCode, exitIfInNIM, keyForBtnClicked, calcMode, tam.mode);
          printf("       shortCutCommand: Handle functions: key:%i: showSoftmenu %i\n",keyCode, itemForRunFunction);
        #endif //VERBOSEKEYS

        //Handle key presses
        if(keyForBtnClicked[0] != '-') {
          #if defined(VERBOSEKEYS)
            printf("       shortCutCommand: Handle key presses: key:%i: btnClicked %s\n",keyCode, keyForBtnClicked);
          #endif //VERBOSEKEYS
          if(shift[0] == 'f') {
            shiftF = true;
            shiftG = false;
          }
          else if(shift[0] == 'g') {
            shiftF = false;
            shiftG = true;
          }
          btnClicked(w, keyForBtnClicked);
          screenUpdatingMode = SCRUPD_AUTO;
          refreshScreen(2);
          return true;
        }

        //Handle direct functions
        if(itemForRunFunction >= 0) {
          #if defined(VERBOSEKEYS)
            printf("       shortCutCommand: Handle direct functions: key:%i: runFunction  %i\n",keyCode, itemForRunFunction);
          #endif //VERBOSEKEYS
          runFunction(itemForRunFunction);
          screenUpdatingMode = SCRUPD_AUTO;
          refreshScreen(3);
          return true;
        }
      }
    }
    #if defined(VERBOSEKEYS)
      printf("       shortCutCommand: No action found\n");
    #endif //VERBOSEKEYS
    return false;
  }


//                                    w, event_keyval,  97,         shortcutProfile == USER_C47,  tam.mode ,      "f",        00",                    modes,                CM_NORMAL,                  ITM_SIGMAPLUS
  static bool_t shortCutFNCommand(GtkWidget *w, int key,      int keyCode, bool_t condition1,            bool_t disable, char *shift, char *keyForBtnClicked, uint16_t modes, int16_t requiredCalcMode2, int16_t itemForRunFunction) {
    if(key == keyCode && condition1 && !disable) {
//    #if defined(VERBOSEKEYS)
        printf("\n       shortCutFNCommand: Disable=%i, Key detected %5i=%5i: keyForBtnClicked:%s, calcMode=%i, tam.mode=%i\n",disable, key, keyCode, keyForBtnClicked, calcMode, tam.mode);
//    #endif //VERBOSEKEYS
    }

    if(disable) return false;                                  //exit directly for disallowed input condition
    if(labelText) return false;                     //exit directly, not allowing label entry

    if(key == keyCode && condition1) {
      #if defined(VERBOSEKEYS)
        printf("       shortCutFNCommand: \n");
      #endif //VERBOSEKEYS
      temporaryInformation = TI_NO_INFO;

//      //Handle menus
//      if(itemForRunFunction < 0) {
//        //printf("\n       shortCutFNCommand: Disable=%i, Key detected %5i=%5i: keyForBtnClicked:%s, calcMode=%i, tam.mode=%i\n",disable, key, keyCode, keyForBtnClicked, calcMode, tam.mode);
//        printf("       shortCutFNCommand: Handle menus: key:%i: showSoftmenu %i\n",keyCode, itemForRunFunction);
//        showSoftmenu(itemForRunFunction);
//        screenUpdatingMode = SCRUPD_AUTO;
//        refreshScreen(4);
//        return true;
//      }

      //Handle functions
      if(((1 << calcMode) & modes) || calcMode == requiredCalcMode2) {
        #if defined(VERBOSEKEYS)
          //printf("\n       shortCutFNCommand: Disable=%i, Key detected %5i=%5i: keyForBtnClicked:%s, calcMode=%i, tam.mode=%i\n",disable, key, keyCode, keyForBtnClicked, calcMode, tam.mode);
          printf("       shortCutFNCommand: Handle functions: key:%i: showSoftmenu %i\n",keyCode, itemForRunFunction);
        #endif //VERBOSEKEYS

        //Handle key presses
        if(keyForBtnClicked[0] != '-') {
          #if defined(VERBOSEKEYS)
            printf("                       Handle key presses: key:%i: btnClicked %s F=%i G=%i\n",keyCode, keyForBtnClicked, shiftF, shiftG);
          #endif //VERBOSEKEYS
          if(shift[0] == 'f') {
            shiftF = true;
            shiftG = false;
          }
          else if(shift[0] == 'g') {
            shiftF = false;
            shiftG = true;
          }
          #if defined(VERBOSEKEYS)
            printf("                       Handle key clicks: key:%i: btnClicked %s\n",keyCode, keyForBtnClicked);
          #endif //VERBOSEKEYS
          btnFnClicked(w, keyForBtnClicked);
          screenUpdatingMode = SCRUPD_AUTO;
          refreshScreen(5);
          return true;
        }


//        //Handle direct functions
//        if(itemForRunFunction >= 0) {
//          printf("       shortCutFNCommand: Handle direct functions: key:%i: runFunction  %i\n",keyCode, itemForRunFunction);
//          runFunction(itemForRunFunction);
//          screenUpdatingMode = SCRUPD_AUTO;
//          refreshScreen(6);
//          return true;
//        }
      }
    }
    return false;
  }


//  static uint16_t asciiToItem(uint8_t in) {
//    if('0' <= in && '9' >= in) return ITM_0 + (in - '0'); else
//    if('A' <= in && 'Z' >= in) return ITM_A + (in - 'A'); else
//    if('a' <= in && 'z' >= in) return ITM_a + (in - 'a'); else
//    for(int g=0; g <= stringByteLength(asciikeysFrom0020);) {
//      if(asciikeysFrom0020[g] == in) {
//        return ITM_SPACE + g;
//      }
//      g++;
//    }
//    return 0;
//  }


  static void sendKey(int16_t sent) {
    #if defined(VERBOSEKEYS)
      printf("Sending ... %i\n", sent);
    #endif //VERBOSEKEYS
    showHideAlphaMode();
    if((calcMode == CM_PEM) && !tam.mode && getSystemFlag(FLAG_ALPHA) && !catalog) {
      pemAlpha(sent);
    } else {
        processAimInput(sent);
      }
    }


  static bool_t checkNormal(int16_t keyNr, int16_t item) {
    int16_t result = Norm_Key_00_item_in_layout;
    int16_t ss = Check_Norm_Key_00_Assigned(&result, keyNr);
    //printf("aaaaa ss=%i result=%i  ss==item=%i\n",ss, result, ss==item);
    return (ss == item);
  }


#if defined(DONOTINCLUDE)
   Didier experiment on FR
   Pressing  AltGr generates two key events:                                                                                   8421
   PC Key pressed:  _keyval=65507 _state=    4 ---Ctr--------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0  0100  GDK_KEY_Control_L
   PC Key pressed:  _keyval=65514 _state=   20 ---Ctr---Num--------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0 10100  GDK_KEY_Alt_R
   Releasing  AltGr generates also two key events:
   PC Key released: _keyval=65507 _state=    8 ------Alt------------ (SHIFT_State=    0)(F=0 G=0)                              1000  GDK_KEY_Control_L
   PC Key released: _keyval=65514 _state=    0 --------------------- (SHIFT_State=    0)(F=0 G=0)                              0000  GDK_KEY_Alt_R
   For Shift:
   PC Key pressed:  _keyval=65505 _state=    1 Shf------------------ (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0  0001  GDK_KEY_Shift_L     (GDK_KEY_Shift_R +1)
   PC Key released: _keyval=65505 _state=    0 --------------------- (SHIFT_State=65536)(F=0 G=0)                              0000
   For control:
   PC Key pressed:  _keyval=65507 _state=    4 ---Ctr--------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0  0100  GDK_KEY_Control_L
   PC Key released: _keyval=65507 _state=    0 --------------------- (SHIFT_State=    0)(F=0 G=0)                              0000


   Dani experiment on CH/FR/DE
   PC Key pressed:  _keyval=65507 _state=    4 ---Ctr-------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0
   PC Key pressed:  _keyval=65514 _state=   20 ---Ctr---Num-------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0
   PC Key released: _keyval=65507 _state=    8 ------Alt----------- (SHIFT_State=    0)(F=0 G=0)`
   PC Key released: _keyval=65514 _state=    0 -------------------- (SHIFT_State=    0)(F=0 G=0)`
   PC Key pressed:  _keyval=65505 _state=    1 Shf----------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0`
   PC Key released: _keyval=65505 _state=    0 -------------------- (SHIFT_State=65536)(F=0 G=0)`
   PC Key pressed:  _keyval=65507 _state=    4 ---Ctr-------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0`        GDK_KEY_Control_L
   PC Key released: _keyval=65507 _state=    0 -------------------- (SHIFT_State=    0)(F=0 G=0)`
   PC Key pressed:  _keyval=65513 _state=    0 -------------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0`        GDK_KEY_Alt_L
   PC Key released: _keyval=65513 _state=    0 -------------------- (SHIFT_State=    0)(F=0 G=0)`


   Didier 4
   PC Key pressed:  _keyval=65507 _state=    4 ------b2 ------------ (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0 AltGr_P=0 Ctrl_P=1 Valid_P=0 Ctrl_R=0 AltGr_R=0
   PC Key pressed:  _keyval=65514 _state=   20 ------b2 ---b4 ------ (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0 AltGr_P=1 Ctrl_P=0 Valid_P=0 Ctrl_R=0 AltGr_R=0
   PC Key pressed:  _keyval=   35 _state=   28 ------b2 b3 b4 ------ (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0 AltGr_P=0 Ctrl_P=0 Valid_P=1 Ctrl_R=0 AltGr_R=0
      Sim key processing: CTRL_State=0 tam.mode=0 event_keyval=   35 calcMode=0 catalog=0 getSystemFlag(FLAG_ALPHA)=0
      ### Command key: CTRL_State=0 SHFT_State=0 tam.mode=0 event_keyval=35 => event_key_command=35 calcMode=0 catalog=0 getSystemFlag(FLAG_ALPHA)=0
          shortCutCommand: No action found
          ...
          shortCutCommand: No action found
          shortCutCommand: Disable=0, Key detected    35=   35: exitIfInNIM=0 keyForBtnClicked:01, calcMode=0, tam.mode=0
          shortCutCommand:
          shortCutCommand: Handle functions: key:35: showSoftmenu 1872
          shortCutCommand: Handle key presses: key:35: btnClicked 01
      refrsh(100): Cnt= 82 OVR CM= 0 scr..upd: 39=   10 0111#2=>              SkpSTK SHFT  TI=   0 CL=UP tam:    0 MENUid= 0:-1349:MyM
   >>>>Z 1001 btnPressed       data=|01| data[0]=48 item=1872 calcMode=0
   Switch - default: processKeyAction: calcMode=0 itemToBeAssigned=1830 item=1872 SHOWMODE=0
   items.c: runfunction (before tamEnterMode): -1349, MyM
   items.c: runfunction (after tamEnterMode): -2068, TamNoReg
      refrsh(117): Cnt= 83 OVR CM= 0 scr..upd:  0=         0#2=>                     AUTO  TI=   0 CL=UP tam:10002 MENUid=131:-2068:TamNoReg
      refrsh(  2): Cnt= 84 OVR CM= 0 scr..upd:  0=         0#2=>                     AUTO  TI=   0 CL=UP tam:10002 MENUid=131:-2068:TamNoReg
   PC Key released: _keyval=   35 _state=   28 ------b2 b3 b4 ------ (SHIFT_State=    0)(F=0 G=0) AltGr_P=0 Ctrl_P=0 Valid_P=1 Ctrl_R=0 AltGr_R=0
   PC Key released: _keyval=65507 _state=    8 ---------b3 --------- (SHIFT_State=    0)(F=0 G=0) AltGr_P=0 Ctrl_P=0 Valid_P=1 Ctrl_R=0 AltGr_R=0
   PC Key released: _keyval=65514 _state=    0 --------------------- (SHIFT_State=    0)(F=0 G=0) AltGr_P=0 Ctrl_P=0 Valid_P=0 Ctrl_R=0 AltGr_R=0

Didier problem: Control does not operate g
   PC Key pressed:  _keyval=65507 _state=    4 ------b2 ------------ (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0 AltGr_P=0 Ctrl_P=1 Valid_P=0 Ctrl_R=0 AltGr_R=0
   PC Key released: _keyval=65507 _state=    0 --------------------- (SHIFT_State=    0)(F=0 G=0) AltGr_P=0 Ctrl_P=0 Valid_P=0 Ctrl_R=0 AltGr_R=0

Jacos Mac, Control works
   PC Key pressed:  _keyval=65507 _state=    0 --------------------- (SHIFT_State=    0)(F=0 G=0) labelText=0 plainTextMode=0 AltGr_P=0 Ctrl_P=0 Valid_P=0 Ctrl_R=0 AltGr_R=0
   PC Key released: _keyval=65507 _state=    4 ------b2 ------------ (SHIFT_State=    0)(F=0 G=0) AltGr_P=0 Ctrl_P=1 Valid_P=0 Ctrl_R=0 AltGr_R=0


#endif //DONOTINCLUDE


  #define event_key_strip_capslock        (( ('A' <= event->keyval && event->keyval <= 'Z') || ('a' <= event->keyval && event->keyval <= 'z')) ? (((event->keyval) & 0xFFFFDF) + (0x20 & ~(event_command_shift >> (16 - 5)))) : event->keyval)
  uint32_t previousEventStateR = 0;
  uint32_t previousEventKeyR = 0;
  uint32_t previousEventStateP = 0;
  uint32_t previousEventKeyP = 0;
  #define C47SpecialKey_AltGr_Pressed           (event->keyval == GDK_KEY_Alt_R     && event->state  & 0b10100)
  #define C47SpecialKey_Ctrl_Pressed            (swapCtrlCode ? (event->keyval == GDK_KEY_Control_L && !(event->state  & 0b00100)) : (event->keyval == GDK_KEY_Control_L && event->state  & 0b00100))
  //This swapctrlcode control code is used to test Didier's FR
  #define C47SpecialKey_Valid_Pressed           (!C47SpecialKey_AltGr_Pressed && !C47SpecialKey_Ctrl_Pressed && event->state & 0b11100)
  //C47SpecialKey_Valid_Released not required as normal keys are not evaluated on release
  #define C47SpecialKey_Ctrl_Released          ((event->keyval == GDK_KEY_Control_L && event->state  & 0b00000) && (previousEventKeyP == GDK_KEY_Control_L && previousEventStateP == 0b00100))
  #define C47SpecialKey_AltGr_Released          (event->keyval == GDK_KEY_Alt_R     && event->state  & 0b00000  &&  previousEventKeyR == GDK_KEY_Control_L && previousEventStateR == 0b1000)



  gboolean keyReleased(GtkWidget *w, GdkEventKey *event, gpointer data) {     //JM
    if(event_keyval == event->keyval + CTRL_State) event_keyval = 99999999;
    char strr[30];
    strr[0]=0;
    #if defined(VERBOSEKEYS)
      strcat(strr,(((event->state) & 0x0001) != 0) ? "b0 " : "---");
      strcat(strr,(((event->state) & 0x0002) != 0) ? "b1 " : "---");
      strcat(strr,(((event->state) & 0x0004) != 0) ? "b2 " : "---");
      strcat(strr,(((event->state) & 0x0008) != 0) ? "b3 " : "---");
      strcat(strr,(((event->state) & 0x0010) != 0) ? "b4 " : "---");
      strcat(strr,(((event->state) & 0x0020) != 0) ? "b5 " : "---");
      strcat(strr,(((event->state) & 0x0040) != 0) ? "b6 " : "---");
    #endif //VERBOSEKEYS
    #if defined(VERBOSEKEYS) || defined(VERBOSE_MINIMUM)
      printf("PC Key released: _keyval=%5d _state=%5d %s (SHIFT_State=%5u)(F=%u G=%u) AltGr_P=%i Ctrl_P=%i Valid_P=%i Ctrl_R=%i AltGr_R=%i\n", event->keyval, (uint16_t)(event->state), strr, SHIFT_State,shiftF,shiftG,
                  C47SpecialKey_AltGr_Pressed, C47SpecialKey_Ctrl_Pressed, C47SpecialKey_Valid_Pressed, C47SpecialKey_Ctrl_Released, C47SpecialKey_AltGr_Released);
      fflush(stdout);
    #endif //VERBOSEKEYS

    if(C47SpecialKey_Ctrl_Released) goto returnKeyReleasedFalse;

    if(C47SpecialKey_AltGr_Released) { //clear any valid or invalid prior control key activation
      SHIFT_State = 0;
      event_command_shift = 0;
      CTRL_State = 0;
      shiftF = false;
      shiftG = false;
      refreshStatusBar();
      showShiftState();
      goto returnKeyReleasedFalse;
    }

    switch(event->keyval) {
      case GDK_KEY_Shift_L: //left shift
      case GDK_KEY_Shift_R: //right shift
          event_command_shift = 0;
          if(SHIFT_State != 0) {     //f-shift activated on the release of the shift key, to allow for standard PC shifted chars

            if(checkNormal( 0,KEY_fg))     btnClicked(w, "00"); else
            if(checkNormal(10,KEY_fg))     btnClicked(w, "10"); else
            if(checkNormal(11,KEY_fg))     btnClicked(w, "11"); else
            if(checkNormal( 0,ITM_SHIFTf)) btnClicked(w, "00"); else
            if(checkNormal(10,ITM_SHIFTf)) btnClicked(w, "10"); else
            if(checkNormal(11,ITM_SHIFTf)) btnClicked(w, "11"); else

            if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary)) == ITM_SHIFTf) btnClicked(w, "10"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[ 0].primary : kbd_std[ 0].primary)) == KEY_fg    ) btnClicked(w, "00"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary)) == KEY_fg    ) btnClicked(w, "10"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary)) == KEY_fg    ) btnClicked(w, "11"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[27].primary : kbd_std[27].primary)) == KEY_fg    ) btnClicked(w, "27"); else
            {
              shiftF = !shiftF;
              shiftG = false;
              refreshStatusBar();
              showShiftState();
            }
          }
          SHIFT_State = 0;
          break;

      case GDK_KEY_Control_L: // Left Ctrl
      case GDK_KEY_Control_R: // right Ctrl
          if(CTRL_State != 0) {

            if(checkNormal( 0,KEY_fg))     btnClicked(w, "00"); else
            if(checkNormal(10,KEY_fg))     btnClicked(w, "10"); else
            if(checkNormal(11,KEY_fg))     btnClicked(w, "11"); else
            if(checkNormal( 0,ITM_SHIFTg)) btnClicked(w, "00"); else
            if(checkNormal(10,ITM_SHIFTg)) btnClicked(w, "10"); else
            if(checkNormal(11,ITM_SHIFTg)) btnClicked(w, "11"); else

            if((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary) == ITM_SHIFTg) btnClicked(w, "11"); else
            {
              shiftF = false;
              shiftG = !shiftG;
              refreshStatusBar();
              showShiftState();
            }


        }
        CTRL_State = 0;
        break;


      case GDK_KEY_F1: // F1                                                    //**************-- FUNCTION KEYS --***************//
                  //                                                       //JM Added this portion to be able to go to NOP on emulator
        #if defined(VERBOSEKEYS)
          printf("key FNPressed - RELEASE: F1\n");
        #endif
        if(labelText || !tam.mode || (tam.mode && AlphaArrowsOffAndUpDn)) {
          btnFnClickedR(w, "1");
        }
        break;

      case GDK_KEY_F2: // F2
        #if defined(VERBOSEKEYS)
          printf("key FNPressed - RELEASE: F2\n");
        #endif
        if(labelText || !tam.mode || (tam.mode && AlphaArrowsOffAndUpDn)) {
          btnFnClickedR(w, "2");
        }
        break;

      case GDK_KEY_F3: // F3
        #if defined(VERBOSEKEYS)
          printf("key FNPressed - RELEASE: F3\n");
        #endif
        if(labelText || !tam.mode || (tam.mode && AlphaArrowsOffAndUpDn)) {
          btnFnClickedR(w, "3");
        }
        break;

      case GDK_KEY_F4: // F4
        #if defined(VERBOSEKEYS)
          printf("key FNPressed - RELEASE: F4\n");
        #endif
        if(labelText || !tam.mode || (tam.mode && AlphaArrowsOffAndUpDn)) {
          btnFnClickedR(w, "4");
        }
        break;

      case GDK_KEY_F5: // F5
        #if defined(VERBOSEKEYS)
          printf("key FNPressed - RELEASE: F5\n");
        #endif
        if(labelText || !tam.mode || (tam.mode && AlphaArrowsOffAndUpDn)) {
          btnFnClickedR(w, "5");
        }
        break;

      case GDK_KEY_F6: // F6
        #if defined(VERBOSEKEYS)
          printf("key FNPressed - RELEASE: F6\n");
        #endif
        if(labelText || !tam.mode || (tam.mode && AlphaArrowsOffAndUpDn)) {
          btnFnClickedR(w, "6");
        }
        break;

      default:
        break;

    }
    if(event->keyval != GDK_KEY_Shift_L && event->keyval != GDK_KEY_Shift_R) {
      SHIFT_State = 0;
    }

returnKeyReleasedFalse:
    //printf("Released1 %d (SHIFT_State=%u)(shiftF=%u)\n", event->keyval,SHIFT_State,shiftF);
    previousEventStateR = event->state;
    previousEventKeyR   = event->keyval;
    return FALSE;
  }


  gboolean keyPressed(GtkWidget *w, GdkEventKey *event, gpointer data) {
    event_keyval = event->keyval + CTRL_State;

    char strr[30];
    strr[0]=0;
    #if defined(VERBOSEKEYS)
      strcat(strr,(((event->state) & 0x0001) != 0) ? "b0 " : "---");
      strcat(strr,(((event->state) & 0x0002) != 0) ? "b1 " : "---");
      strcat(strr,(((event->state) & 0x0004) != 0) ? "b2 " : "---");
      strcat(strr,(((event->state) & 0x0008) != 0) ? "b3 " : "---");
      strcat(strr,(((event->state) & 0x0010) != 0) ? "b4 " : "---");
      strcat(strr,(((event->state) & 0x0020) != 0) ? "b5 " : "---");
      strcat(strr,(((event->state) & 0x0040) != 0) ? "b6 " : "---");
    #endif //VERBOSEKEYS
    #if defined(VERBOSEKEYS) || defined(VERBOSE_MINIMUM)
      printf(  "PC Key pressed:  _keyval=%5d _state=%5d %s (SHIFT_State=%5u)(F=%u G=%u) labelText=%i plainTextMode=%i AltGr_P=%i Ctrl_P=%i Valid_P=%i Ctrl_R=%i AltGr_R=%i\n", event->keyval, event->state, strr, SHIFT_State,shiftF,shiftG,labelText, plainTextMode,
                  C47SpecialKey_AltGr_Pressed, C47SpecialKey_Ctrl_Pressed, C47SpecialKey_Valid_Pressed, C47SpecialKey_Ctrl_Released, C47SpecialKey_AltGr_Released);
      fflush(stdout);
    #endif //VERBOSEKEYS

    //printf("AltGr #1:%s         ; keyval=%u state=%u, event_key_strip_capslock=%u\n",
    //(event->keyval == GDK_KEY_at) ? "+@" : (event->keyval == GDK_KEY_numbersign) ? "+#" : (event->keyval == GDK_KEY_bar) ? "+|" : "",
    //(uint16_t)event->keyval, (uint16_t)event->state, (uint16_t)event_key_strip_capslock);

    if(C47SpecialKey_Ctrl_Pressed) goto continueWithOldDetections;

    if(C47SpecialKey_AltGr_Pressed) { //clear any valid or invalid prior control key activation
      SHIFT_State = 0;
      event_command_shift = 0;
      CTRL_State = 0;
      shiftF = false;
      shiftG = false;
      refreshStatusBar();
      showShiftState();
      goto returnKeyPressedFalse;
    }

    SHIFT_State = 0;
    switch(event_keyval) {
      case GDK_KEY_Shift_L: //left shift
      case GDK_KEY_Shift_R: //right shift
        SHIFT_State = 65536;
        event_command_shift = 65536;
        //printf("key pressed: Shift Activated\n");
        break;

      case GDK_KEY_Control_L: // left Ctrl
      case GDK_KEY_Control_R: // right Ctrl
        //printf("key pressed: CTRL Activated\n");
        CTRL_State = 65536;
        break;
      default:;
    }


    if(CTRL_State == 65536 && !C47SpecialKey_Ctrl_Pressed) goto continueWithOldDetections;

    if(!((calcMode == CM_AIM || calcMode == CM_EIM || tam.mode || (calcMode == CM_PEM && getSystemFlag(FLAG_ALPHA)) || tam.alpha))) {
      switch(event_key_strip_capslock) {
        case GDK_KEY_f: //f

            if(checkNormal( 0,ITM_SHIFTf)) btnClicked(w, "00"); else
            if(checkNormal(10,ITM_SHIFTf)) btnClicked(w, "10"); else
            if(checkNormal(11,ITM_SHIFTf)) btnClicked(w, "11"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary) == ITM_SHIFTf )) btnClicked(w, "10"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary) == ITM_SHIFTf )) btnClicked(w, "11"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary) == KEY_fg     )) btnClicked(w, "10"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary) == KEY_fg     )) btnClicked(w, "11"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[27].primary : kbd_std[27].primary) == KEY_fg     )) btnClicked(w, "27");
          break;
        case GDK_KEY_g: //g

            if(checkNormal( 0,ITM_SHIFTg)) btnClicked(w, "00"); else
            if(checkNormal(10,ITM_SHIFTg)) btnClicked(w, "10"); else
            if(checkNormal(11,ITM_SHIFTg)) btnClicked(w, "11"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary) == ITM_SHIFTg )) btnClicked(w, "11"); else
            if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary) == ITM_SHIFTg )) btnClicked(w, "10"); else
            {
              shiftF = false;
              shiftG = !shiftG;
              refreshStatusBar();
              showShiftState();
            }
            // if(((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary) == KEY_fg     )) btnClicked(w, "11"); else
            // if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary) == KEY_fg     )) btnClicked(w, "10"); else
            // if(((getSystemFlag(FLAG_USER) ? kbd_usr[27].primary : kbd_std[27].primary) == KEY_fg     )) btnClicked(w, "27");
          break;
        default:break;
      }
    }

//#define VERBOSEKEYS

//Bits for modes
//  0 CM_NORMAL
//  1 CM_AIM
//  2 CM_NIM
//  3 CM_PEM
//  4 CM_ASSIGN
//  5 CM_REGISTER_BROWSER
//  6 CM_FLAG_BROWSER
//  7 CM_FONT_BROWSER
//  8 CM_PLOT_STAT
//  9 CM_ERROR_MESSAGE
// 10 CM_BUG_ON_SCREEN
// 11 CM_CONFIRMATION
// 12 CM_MIM
// 13 CM_EIM
// 14 CM_TIMER
// 15 CM_GRAPH
// 16 CM_NO_UNDO
// 17 CM_ASN_BROWSER
// 18 CM_LISTXY

#if defined(VERBOSEKEYS) || defined(VERBOSE_MINIMUM)
  printf("   Sim key processing: CTRL_State=%i tam.mode=%i event_keyval=%5i calcMode=%i catalog=%i getSystemFlag(FLAG_ALPHA)=%i\n", CTRL_State, tam.mode, event_keyval, calcMode, catalog, getSystemFlag(FLAG_ALPHA));
  fflush(stdout);
#endif //VERBOSEKEYS

//event_key_command = event->keyval + (('A' <= event->keyval && event->keyval <= 'Z') ? 'a' - 'A' : 0)    // remove caps lock effect for commands, 'a' to 'z'
//                                  - (('A' <= event->keyval && event->keyval <= 'Z') && event_command_shift == 65536 ? 'a' - 'A' : 0);                     // consider only shift button status to get caps for commands


//#define allowAltGrKey ((event->state & 16) == 16) this will also allow the actual involved AltGr shifts. Narrowing will make it more accurate but may exclude other non-standard bitmasks
#define allowAltGrKey (C47SpecialKey_Valid_Pressed)
#define tamArrows (labelText || tam.mode == TM_FLAGW || tam.mode == TM_FLAGR)

if(     (CTRL_State != 65536 || allowAltGrKey)
     && (!catalog || (catalog && currentMenu() == -MNU_MVAR))
     && (!(tamArrows || tam.mode == TM_STORCL || tam.mode == TM_MENU) || (uint8_t)(event->keyval) == GDK_KEY_apostrophe)
     && (    calcMode == CM_NORMAL
         ||  calcMode == CM_NIM
         ||  calcMode == CM_PEM
         ||  calcMode == CM_TIMER
         || (calcMode == CM_ASSIGN && itemToBeAssigned == 0)//do not include ASN TO here, as you need to assign to a KEY or a SOFTKEY using the MOUSE
        )
     && !getSystemFlag(FLAG_ALPHA)
  ) {
  event_key_command = event_key_strip_capslock;   // remain in lower case, do not translate or use dead keys
  #if defined(VERBOSEKEYS)
    printf("\n   ### Command key: CTRL_State=%i SHFT_State=%i tam.mode=%i event_keyval=%i => event_key_command=%i calcMode=%i catalog=%i getSystemFlag(FLAG_ALPHA)=%i\n", CTRL_State, SHIFT_State, tam.mode, event_keyval, event_key_command, calcMode, catalog, getSystemFlag(FLAG_ALPHA));
  #endif //VERBOSEKEYS

//C47 & R47 AltGr============
//if((event->keyval == 65514) || ((event->state & 16) == 16)) { //AltGr Dani & Didier 0x14 for AltGr, and 0x1C for \#
    //printf("AltGr #2 (NM ) %s detected; keyval=%u state=%u, event_key_command=%u\n",
    //(event->keyval == GDK_KEY_at) ? "+@" : (event->keyval == GDK_KEY_numbersign) ? "+#" : (event->keyval == GDK_KEY_bar) ? "+|" : "",
    //(uint16_t)event->keyval, (uint16_t)event->state, (uint16_t)event_key_command);
//}


  //list of special case keys, server non-CM_xxx modes
  switch(event_keyval) {
    case GDK_KEY_backslash:
    case GDK_KEY_z:
      if(SHOWMODE){// || currentMenu() == -MNU_TIMERF) {
        btnClicked(w, "35");  //R/S
        goto returnKeyPressedFalse;
      }
      break;
    default:;
  }


//C47 & R47============
  if(shortCutCommand(w, event_key_command, GDK_KEY_a           /* a 97    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "00",        0b0100000000001101,         -1,        ITM_SIGMAPLUS ))        {goto returnKeyPressedFalse;} else        //                  [a]ccumulate
  if(shortCutCommand(w, event_key_command, GDK_KEY_v           /* v 118   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "01",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} else        //                     in[v]erse
  if(shortCutCommand(w, event_key_command, GDK_KEY_q           /* q 113   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "02",                   0b01101,         -1,      ITM_SQUAREROOTX ))        {goto returnKeyPressedFalse;} else        //                        s[q]rt
  if(shortCutCommand(w, event_key_command, GDK_KEY_o           /* o 111   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,            ITM_LOG10 ))        {goto returnKeyPressedFalse;} else        //                         l[o]g
  if(shortCutCommand(w, event_key_command, GDK_KEY_l           /* l 108   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "04",                   0b01101,         -1,               ITM_LN ))        {goto returnKeyPressedFalse;} else        //                          [l]n
  if(shortCutCommand(w, event_key_command, GDK_KEY_x           /* x 120   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,             FALSE,    "",   "05",                   0b01101,         -1,              ITM_XEQ ))        {goto returnKeyPressedFalse;} else        //                         [x]eq
  if(shortCutCommand(w, event_key_command, GDK_KEY_m           /* m 109   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "06",                   0b01101,         -1,              ITM_STO ))        {goto returnKeyPressedFalse;} else        //                      [m]emory
  if(shortCutCommand(w, event_key_command, GDK_KEY_r           /* r 114   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "07",                   0b01101,         -1,              ITM_RCL ))        {goto returnKeyPressedFalse;} else        //                         [r]cl
  if(shortCutCommand(w, event_key_command, GDK_KEY_d           /* d 100   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "08",                   0b01101,         -1,            ITM_Rdown ))        {goto returnKeyPressedFalse;} else        //                        [d]own
  if(shortCutCommand(w, event_key_command, GDK_KEY_s           /* s 115   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "09",                   0b01101,         -1,              ITM_sin ))        {goto returnKeyPressedFalse;} else        //                        [s]ine
  if(shortCutCommand(w, event_key_command, GDK_KEY_i           /* i 105   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "09",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} else        //                             i
  if(shortCutCommand(w, event_key_command, GDK_KEY_j           /* j 106   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "09",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} else        //                             i
  if(shortCutCommand(w, event_key_command, GDK_KEY_k           /* k 107   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_op_j_pol ))    {goto returnKeyPressedFalse;} else        //                             i
  if(shortCutCommand(w, event_key_command, GDK_KEY_c           /* c 99    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "10",                   0b01101,         -1,              ITM_cos ))        {goto returnKeyPressedFalse;} else        //                      [c]osine
  if(shortCutCommand(w, event_key_command, GDK_KEY_t           /* t 116   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "11",                   0b01101,         -1,              ITM_tan ))        {goto returnKeyPressedFalse;} else        //                     [t]angent
  if(shortCutCommand(w, event_key_command, GDK_KEY_Return      /* ENTER 65293 */,                                                        FALSE, !EXITIFNIM,             FALSE,    "",   "12",                   0b01101,         -1,            ITM_ENTER ))        {goto returnKeyPressedFalse;} else        //                           key
  if(shortCutCommand(w, event_key_command, GDK_KEY_Tab         /* tab 65289   */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "13",                   0b01101,         -1,             ITM_XexY ))        {goto returnKeyPressedFalse;} else        //                        s[w]ap
  if(shortCutCommand(w, event_key_command, GDK_KEY_w           /* w 119   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "13",                   0b01101,         -1,             ITM_XexY ))        {goto returnKeyPressedFalse;} else        //                        s[w]ap
  if(shortCutCommand(w, event_key_command, GDK_KEY_n           /* n 110   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "14",                   0b01101,         -1,              ITM_CHS ))        {goto returnKeyPressedFalse;} else        //                CHS [n]egative
  if(shortCutCommand(w, event_key_command, GDK_KEY_e           /* e 101   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "15",                   0b01101,         -1,         ITM_EXPONENT ))        {goto returnKeyPressedFalse;} else        //                    [e]xponent
  if(shortCutCommand(w, event_key_command, GDK_KEY_greater     /* > 62    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_DRG ))        {goto returnKeyPressedFalse;} else        //                     [=]>D,R,G
  if(shortCutCommand(w, event_key_command, GDK_KEY_Y           /* Y 89    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} else        //                         [y]^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_X           /* X 88    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,          KEY_COMPLEX ))        {goto returnKeyPressedFalse;} else        //                     comple[X]
  if(shortCutCommand(w, event_key_command, GDK_KEY_R           /* R 82    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_toREC2 ))        {goto returnKeyPressedFalse;} else        //                           ->R
  if(shortCutCommand(w, event_key_command, GDK_KEY_P           /* P 80    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_toPOL2 ))        {goto returnKeyPressedFalse;} else        //                           ->P
  if(shortCutCommand(w, event_key_command, GDK_KEY_p           /* p 112   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,          ITM_CONSTpi ))        {goto returnKeyPressedFalse;} else        //                            pi
  if(shortCutCommand(w, event_key_command, GDK_KEY_V           /* V 86    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} else        //                     in[V]erse
  if(shortCutCommand(w, event_key_command, GDK_KEY_y           /* y 121   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,          ITM_XTHROOT ))        {goto returnKeyPressedFalse;} else        //               xth root of [Y]
  if(shortCutCommand(w, event_key_command, GDK_KEY_C           /* C 67    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_arccos ))        {goto returnKeyPressedFalse;} else        //                   arc[C]osine
  if(shortCutCommand(w, event_key_command, GDK_KEY_S           /* S 83    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_arcsin ))        {goto returnKeyPressedFalse;} else        //                     arc[S]ine
  if(shortCutCommand(w, event_key_command, GDK_KEY_T           /* T 84    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_arctan ))        {goto returnKeyPressedFalse;} else        //                  arc[T]angent
  if(shortCutCommand(w, event_key_command, GDK_KEY_L           /* L 76    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_EXP ))        {goto returnKeyPressedFalse;} else        //                  anti[L]n e^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_O           /* O 79    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_10x ))        {goto returnKeyPressedFalse;} else        //                antil[O]g 10^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_Q           /* Q 81    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} else        //                      s[Q]uare
  if(shortCutCommand(w, event_key_command, GDK_KEY_D           /* D 68    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_Rup ))        {goto returnKeyPressedFalse;} else        //                        Up [D]
  if(shortCutCommand(w, event_key_command, GDK_KEY_I           /* I 73    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_DISP ))        {goto returnKeyPressedFalse;} else        //                        D[I]SP
  if(shortCutCommand(w, event_key_command, GDK_KEY_J           /* J 74    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,             -MNU_EXP ))        {goto returnKeyPressedFalse;} else        //                           EXP
  if(shortCutCommand(w, event_key_command, GDK_KEY_K           /* K 75    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,             -MNU_STK ))        {goto returnKeyPressedFalse;} else        //                         ST[K]
  if(shortCutCommand(w, event_key_command, GDK_KEY_M           /* M 77    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_MODE ))        {goto returnKeyPressedFalse;} else        //                        [M]ODE

  if(shortCutCommand(w, event_key_command, GDK_KEY_F           /* F 70    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,          -MNU_PREFIX ))        {goto returnKeyPressedFalse;} else        //                      PRE[F]IX

  if(shortCutCommand(w, event_key_command, GDK_KEY_percent     /* % 37    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               ITM_PC ))        {goto returnKeyPressedFalse;} else        //                           [%]
  if(shortCutCommand(w, event_key_command, GDK_KEY_exclam      /* ! 33    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,            ITM_XFACT ))        {goto returnKeyPressedFalse;} else        //                          x[!]
  if(shortCutCommand(w, event_key_command, GDK_KEY_U           /* U 85    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,    "",  "-01",                    0xffff,         -1,         ITM_USERMODE ))        {goto returnKeyPressedFalse;} else        //                        [U]SER
  if(shortCutCommand(w, event_key_command, GDK_KEY_apostrophe  /* ' 39    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,             FALSE,   "f",   "05",                   0b11101,         -1,              ITM_AIM ))        {goto returnKeyPressedFalse;} else        //                     alpha [']
  if(shortCutCommand(w, event_key_command, GDK_KEY_G           /* G 71    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,             FALSE,   "g",   "05",                   0b01101,         -1,              ITM_GTO ))        {goto returnKeyPressedFalse;} else        //                         [g]TO
  if(shortCutCommand(w, event_key_command, GDK_KEY_A           /* A 65    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_ARG ))        {goto returnKeyPressedFalse;} else        //                       [A]ngle
  if(shortCutCommand(w, event_key_command, GDK_KEY_Z           /* Z 90    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_MAGNITUDE ))        {goto returnKeyPressedFalse;} else        //                        Si[Z]e
  if(shortCutCommand(w, event_key_command, GDK_KEY_bar         /* | 124   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_MAGNITUDE ))        {goto returnKeyPressedFalse;} else        //                Size [|] (dup)
  if(shortCutCommand(w, event_key_command, 126       /*DUP left   | 124/6 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_MAGNITUDE ))        {goto returnKeyPressedFalse;} else        //                Size [|] (dup)
  if(shortCutCommand(w, event_key_command, GDK_KEY_F7          /*   65476 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_n ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_F8          /*   65477 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_u ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_F9          /*   65478 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_m ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_F10         /*   65479 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_k ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_F11         /*   65480 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_M ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_W           /* W 87    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,            ITM_LASTX ))        {goto returnKeyPressedFalse;} else        //                        Last X
  if(shortCutCommand(w, event_key_command, GDK_KEY_equal       /* = 61    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} else        //                      .d (dup)
  if(shortCutCommand(w, event_key_command, GDK_KEY_E           /* E 69    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               CST_09 ))        {goto returnKeyPressedFalse;} else        //                     Euler's E
  if(shortCutCommand(w, event_key_command, GDK_KEY_N           /* N 78    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "f",   "35",                   0b01101,     CM_PEM,               ITM_PR ))        {goto returnKeyPressedFalse;} else        //                       PRGM N]
  if(shortCutCommand(w, event_key_command, GDK_KEY_b           /* b 98    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,     CM_PEM,              ITM_LBL ))        {goto returnKeyPressedFalse;} else        //                       LBL [B]
  if(shortCutCommand(w, event_key_command, GDK_KEY_u           /* u 117   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "f",   "16",                   0b01101,     CM_PEM,               ITM_PR ))        {goto returnKeyPressedFalse;} else        //                        [u]ndo
  if(shortCutCommand(w, event_key_command, GDK_KEY_H           /* H 72    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_HOME ))        {goto returnKeyPressedFalse;} else        //                        [H]ome
  if(shortCutCommand(w, event_key_command, GDK_KEY_B           /* B 66    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,          -MNU_MyMenu ))        {goto returnKeyPressedFalse;} else        //                    MyMenu [b]
  if(shortCutCommand(w, event_key_command, GDK_KEY_less        /* < 60    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_RTN ))        {goto returnKeyPressedFalse;} else        //                       RTN [<]
  if(shortCutCommand(w, event_key_command, GDK_KEY_twosuperior /* ² 178   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} else        //     Square on French keyboard
  if(shortCutCommand(w, event_key_command, GDK_KEY_colon       /* : 58    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,   "g",   "00",                   0b01101,         -1,           ITM_TGLFRT ))        {goto returnKeyPressedFalse;} else        //                          ab/c
  if(shortCutCommand(w, event_key_command, GDK_KEY_numbersign  /* # 35    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "01",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} else        //                             #
  if(shortCutCommand(w, event_key_command, GDK_KEY_quotedbl    /* " 34  FR*/    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "01",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} else        //                             #
  if(shortCutCommand(w, event_key_command, GDK_KEY_at          /* @ 64    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_eacute      /* é 233 FR*/    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_asciicircum /* ^ 94    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,   "f",   "01",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} else        //                         [y]^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_dollar      /* $ 36    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "02",                   0b11101,         -1,               ITM_ms ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_ampersand   /* & 38    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "f",   "00",                   0b11101,         -1,               ITM_RI ))        {goto returnKeyPressedFalse;} else        //                            >I
  if(shortCutCommand(w, event_key_command, GDK_KEY_backslash   /* \ 92    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "35",        0b0100000000001101,         -1,              ITM_STOP))        {goto returnKeyPressedFalse;} else        //                         [x]eq
  if(shortCutCommand(w, event_key_command, 96        /*DUP left   \ 92/6  */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "35",                   0b01101,         -1,              ITM_STOP))        {goto returnKeyPressedFalse;} else        //                         [x]eq
  if(shortCutCommand(w, event_key_command, GDK_KEY_z           /* z 122 DE*/    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "35",                   0b01101,         -1,              ITM_STOP))        {goto returnKeyPressedFalse;} else        //                         [x]eq
//                                             PC_GTK3_code                                          Logic Condition to enable line,  Close NIM,   Disabling state,  Shift/KEYno ,            Valid CalcMode requiredCalcMode2  itemForRunFunction

  if(shortCutCommand(w, event_key_command, GDK_KEY_Q           /* Q 81    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "00",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} else        //                      s[Q]uare
  if(shortCutCommand(w, event_key_command, GDK_KEY_i           /* i 105   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "f",   "00",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} else        //                             i
  if(shortCutCommand(w, event_key_command, GDK_KEY_j           /* j 106   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "f",   "00",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} else        //                             i
  if(shortCutCommand(w, event_key_command, GDK_KEY_q           /* q 113   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "01",                   0b01101,         -1,      ITM_SQUAREROOTX ))        {goto returnKeyPressedFalse;} else        //                        s[q]rt
  if(shortCutCommand(w, event_key_command, GDK_KEY_k           /* k 107   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "f",   "01",                   0b11101,         -1,             ITM_op_j_pol ))    {goto returnKeyPressedFalse;} else        //                          ipol
  if(shortCutCommand(w, event_key_command, GDK_KEY_v           /* v 118   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "02",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} else        //                     in[v]erse
  if(shortCutCommand(w, event_key_command, GDK_KEY_Y           /* Y 89    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} else        //                         [y]^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_asciicircum /* ^ 94    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} else        //                         [y]^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_o           /* o 111   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "04",                   0b01101,         -1,            ITM_LOG10 ))        {goto returnKeyPressedFalse;} else        //                         l[o]g
  if(shortCutCommand(w, event_key_command, GDK_KEY_l           /* l 108   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "05",                   0b01101,         -1,               ITM_LN ))        {goto returnKeyPressedFalse;} else        //                          [l]n
  if(shortCutCommand(w, event_key_command, GDK_KEY_m           /* m 109   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "06",                   0b01101,         -1,              ITM_STO ))        {goto returnKeyPressedFalse;} else        //                      [m]emory
  if(shortCutCommand(w, event_key_command, GDK_KEY_r           /* r 114   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "07",                   0b01101,         -1,              ITM_RCL ))        {goto returnKeyPressedFalse;} else        //                         [r]cl
  if(shortCutCommand(w, event_key_command, GDK_KEY_d           /* d 100   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "08",                   0b01101,         -1,            ITM_Rdown ))        {goto returnKeyPressedFalse;} else        //                        [d]own
  if(shortCutCommand(w, event_key_command, GDK_KEY_greater     /* > 62    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "09",                   0b01101,         -1,              ITM_DRG ))        {goto returnKeyPressedFalse;} else        //                     [=]>D,R,G
  if(shortCutCommand(w, event_key_command, GDK_KEY_f           /* f 102   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "10",                   0b01101,         -1,           ITM_SHIFTf ))        {goto returnKeyPressedFalse;} else        //                             f
  if(shortCutCommand(w, event_key_command, GDK_KEY_g           /* g 103   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "11",                   0b01101,         -1,           ITM_SHIFTg ))        {goto returnKeyPressedFalse;} else        //                             g
  if(shortCutCommand(w, event_key_command, GDK_KEY_E           /* E 69 EE */    ,                                                        FALSE, !EXITIFNIM,             FALSE,    "",   "12",                   0b01101,         -1,            ITM_ENTER ))        {goto returnKeyPressedFalse;} else        //                           key
  if(shortCutCommand(w, event_key_command, GDK_KEY_w           /* w 119   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "13",                   0b01101,         -1,             ITM_XexY ))        {goto returnKeyPressedFalse;} else        //                        s[w]ap
  if(shortCutCommand(w, event_key_command, GDK_KEY_n           /* n 110   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "14",                   0b01101,         -1,              ITM_CHS ))        {goto returnKeyPressedFalse;} else        //                CHS [n]egative
  if(shortCutCommand(w, event_key_command, GDK_KEY_e           /* e 101   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "15",                   0b01101,         -1,         ITM_EXPONENT ))        {goto returnKeyPressedFalse;} else        //                    [e]xponent
  if(shortCutCommand(w, event_key_command, GDK_KEY_a           /* a 97    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_SIGMAPLUS ))        {goto returnKeyPressedFalse;} else        //                  [a]ccumulate
  if(shortCutCommand(w, event_key_command, GDK_KEY_x           /* x 120   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "17",                   0b01101,         -1,              ITM_XEQ ))        {goto returnKeyPressedFalse;} else        //                         [x]eq
  if(shortCutCommand(w, event_key_command, GDK_KEY_apostrophe  /* ' 39    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "f",   "17",                   0b01101,         -1,              ITM_AIM ))        {goto returnKeyPressedFalse;} else        //                     alpha [']
  if(shortCutCommand(w, event_key_command, GDK_KEY_G           /* G 71    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "g",   "17",                   0b01101,         -1,              ITM_GTO ))        {goto returnKeyPressedFalse;} else        //                         [g]TO
  if(shortCutCommand(w, event_key_command, GDK_KEY_M           /* M 77    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_PREF ))        {goto returnKeyPressedFalse;} else        //                      PREF [M}
  if(shortCutCommand(w, event_key_command, GDK_KEY_s           /* s 115   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_sin ))        {goto returnKeyPressedFalse;} else        //                        [s]ine
  if(shortCutCommand(w, event_key_command, GDK_KEY_c           /* c 99    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_cos ))        {goto returnKeyPressedFalse;} else        //                      [c]osine
  if(shortCutCommand(w, event_key_command, GDK_KEY_t           /* t 116   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_tan ))        {goto returnKeyPressedFalse;} else        //                     [t]angent
  if(shortCutCommand(w, event_key_command, GDK_KEY_V           /* V 86    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} else        //                     in[v]erse
  if(shortCutCommand(w, event_key_command, GDK_KEY_colon       /* : 58    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,   "g",   "34",                   0b01101,         -1,           ITM_TGLFRT ))        {goto returnKeyPressedFalse;} else        //                          ab/c
  if(shortCutCommand(w, event_key_command, GDK_KEY_numbersign  /* # 35    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "05",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} else        //                             #
  if(shortCutCommand(w, event_key_command, GDK_KEY_quotedbl    /* " 34  FR*/    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "05",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} else        //                             #
  if(shortCutCommand(w, event_key_command, GDK_KEY_at          /* @ 64    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_eacute      /* é 233 FR*/    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_asciicircum /* ^ 94    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} else        //                         [y]^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_dollar      /* $ 36    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "02",                   0b11101,         -1,               ITM_ms ))        {goto returnKeyPressedFalse;} else        //                            .d
  if(shortCutCommand(w, event_key_command, GDK_KEY_ampersand   /* & 38    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "04",                   0b11101,         -1,               ITM_RI ))        {goto returnKeyPressedFalse;} else        //                            >I
#if defined(RASPBERRY)
  if(shortCutCommand(w, event_key_command, GDK_KEY_period      /* . 46    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} else        //                      s[Q]uare
  if(shortCutCommand(w, event_key_command, GDK_KEY_comma       /* , 44    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} else        //                         [y]^x
  if(shortCutCommand(w, event_key_command, GDK_KEY_semicolon   /* ; 59    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_DRG ))        {goto returnKeyPressedFalse;} else        //                     [=]>D,R,G
#endif // RASPBERRY

#if defined(VERBOSEKEYS)
  printf("------------------------ Checked commands, skipping to rest of key detections\n");
#else
  {}
#endif

}
else if(     (CTRL_State != 65536 || allowAltGrKey)
     && (    calcMode == CM_NORMAL
         ||  calcMode == CM_PEM
        )
     && !getSystemFlag(FLAG_ALPHA)
  ) {

    if(tam.mode == TM_STORCL) {
      #if defined(VERBOSEKEYS)
        printf("------------------------ Checking STO/RCL ancillary functions event->keyval=%i, GDK_KEY_Up=%i\n",event->keyval, GDK_KEY_Up);
      #endif
      if(shortCutCommand(w, event->keyval, GDK_KEY_Up         ,   shortcutProfile == USER_C47                               , !EXITIFNIM, !DISABLED,    "",   "17", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, GDK_KEY_Down       ,   shortcutProfile == USER_C47                               , !EXITIFNIM, !DISABLED,    "",   "22", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, GDK_KEY_Up         ,                                  shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "22", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, GDK_KEY_Down       ,                                  shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "27", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutFNCommand(w, event_keyval, GDK_KEY_Right     ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,      FALSE,               "",   "1" , 0b01001, -1, 0))        {goto returnKeyPressedFalse;} else        //  F6 Rt
      if(shortCutCommand(w, event->keyval, '/'                ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "21", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, '*'                ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "26", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, '-'                ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "31", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, '+'                ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "36", 0b01001, -1, 0))        {return false;} else        //                         [x]eq

      if((event->keyval >= GDK_KEY_A && event->keyval <= GDK_KEY_Z) || (event->keyval >= GDK_KEY_a && event->keyval <= GDK_KEY_z)) {
        switch(event->keyval) {
          case GDK_KEY_X:                         addItemToBuffer(ITM_REG_X); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_Y:                         addItemToBuffer(ITM_REG_Y); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_Z:                         addItemToBuffer(ITM_REG_Z); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_T:                         addItemToBuffer(ITM_REG_T); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_A:                         addItemToBuffer(ITM_REG_A); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_B:                         addItemToBuffer(ITM_REG_B); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_C:                         addItemToBuffer(ITM_REG_C); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_D:                         addItemToBuffer(ITM_REG_D); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_L:                         addItemToBuffer(ITM_REG_L); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_I:                         addItemToBuffer(ITM_REG_I); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_J:                         addItemToBuffer(ITM_REG_J); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_K:                         addItemToBuffer(ITM_REG_K); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_M:                         addItemToBuffer(ITM_REG_M); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_N:                         addItemToBuffer(ITM_REG_N); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_P:                         addItemToBuffer(ITM_REG_P); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_Q:                         addItemToBuffer(ITM_REG_Q); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_R:                         addItemToBuffer(ITM_REG_R); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_S:                         addItemToBuffer(ITM_REG_S); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_E:                         addItemToBuffer(ITM_REG_E); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_F:                         addItemToBuffer(ITM_REG_F); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_G:                         addItemToBuffer(ITM_REG_G); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_H:                         addItemToBuffer(ITM_REG_H); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_O:                         addItemToBuffer(ITM_REG_O); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_U:                         addItemToBuffer(ITM_REG_U); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_V:                         addItemToBuffer(ITM_REG_V); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_W:                         addItemToBuffer(ITM_REG_W); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_X - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_X); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_Y - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_Y); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_Z - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_Z); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_T - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_T); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_A - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_A); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_B - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_B); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_C - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_C); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_D - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_D); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_L - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_L); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_I - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_I); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_J - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_J); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_K - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_K); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_M - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_M); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_N - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_N); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_P - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_P); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_Q - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_Q); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_R - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_R); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_S - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_S); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_E - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_E); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_F - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_F); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_G - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_G); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_H - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_H); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_O - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_O); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_U - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_U); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_V - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_V); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          case GDK_KEY_W - GDK_KEY_A + GDK_KEY_a: addItemToBuffer(ITM_REG_W); screenUpdatingMode = SCRUPD_AUTO; refreshScreen(3); return false;
          default:;
          }
        }

      #if defined(VERBOSEKEYS)
        printf("------------------------ Checked STO/RCL arrow +-*/, skipping to rest of key detections\n");
      #else
        {}
      #endif
    }
    else if((tamArrows) && !getSystemFlag(FLAG_ALPHA)) {
      #if defined(VERBOSEKEYS)
        printf("------------------------ Checking GTO Up Dn ancillary functions event->keyval=%i, GDK_KEY_Up=%i\n",event->keyval, GDK_KEY_Up);
      #endif
      if(shortCutCommand(w, event->keyval, GDK_KEY_Up         ,   shortcutProfile == USER_C47                               , !EXITIFNIM, !DISABLED,    "",   "17", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, GDK_KEY_Down       ,   shortcutProfile == USER_C47                               , !EXITIFNIM, !DISABLED,    "",   "22", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, GDK_KEY_Up         ,                                  shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "22", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      if(shortCutCommand(w, event->keyval, GDK_KEY_Down       ,                                  shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED,    "",   "27", 0b01001, -1, 0))        {return false;} else        //                         [x]eq
      #if defined(VERBOSEKEYS)
        printf("------------------------ Checked GTO Up Dn, skipping to rest of key detections\n");
      #else
        {}
      #endif
    }
  }



//New Matrix arrows
if(   (CTRL_State != 65536 || allowAltGrKey)
   && !catalog
   && (calcMode == CM_NORMAL || calcMode == CM_MIM || calcMode == CM_EIM)
   && IS_SIM_ARROW_ALLOWED_IN_MENU(currentMenu(), event_keyval)
  ) {
  #if defined(VERBOSEKEYS)
      printf("------------------------ Checking Matrix arrows functions\n");
  #endif

  //                  *w, int key     ,keyCode,   condition1,                                                         disable,  *shift, *keyForBtnClicked,      modes,  requiredCalcMode2,     itemForRunFunction
  if(shortCutFNCommand(w, event_keyval, GDK_KEY_Up    /* F1 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "1",         3 << 13,         -1,          0    ))        {goto returnKeyPressedFalse;} else        //  F1 Up
  if(shortCutFNCommand(w, event_keyval, GDK_KEY_Down  /* F2 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "2",         3 << 13,         -1,          0    ))        {goto returnKeyPressedFalse;} else        //  F2 Dn
  if(shortCutFNCommand(w, event_keyval, GDK_KEY_Left  /* F5 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "5",         3 << 13,         -1,          0    ))        {goto returnKeyPressedFalse;} else        //  F5 Lt
  if(shortCutFNCommand(w, event_keyval, GDK_KEY_Right /* F6 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "6",         3 << 13,         -1,          0    ))        {goto returnKeyPressedFalse;} else        //  F6 Rt
  #if defined(VERBOSEKEYS)
    printf("------------------------ Checked matrix arrows detection, skipping to rest of key detections\n");
  #else
    {}
  #endif
}

//New ALPHA SECTION
int32_t ll;

if(   (CTRL_State != 65536 || allowAltGrKey)
   && (   (catalog && currentMenu() != -MNU_MVAR)
        || calcMode == CM_AIM
        || calcMode == CM_EIM
        ||(calcMode == CM_PEM    && getSystemFlag(FLAG_ALPHA))
        ||(calcMode == CM_ASSIGN && getSystemFlag(FLAG_ALPHA))
        ||(calcMode == CM_NORMAL && (tam.mode == TM_REGISTER || tam.mode == TM_FLAGW || tam.mode == TM_FLAGR))
        ||(labelText )
      )
  ) {

//if((event->keyval == 65514) || ((event->state & 16) == 16)) { //AltGr Dani & Didier 0x14 for AltGr, and 0x1C for \#
    //printf("AltGr #3 (AIM) %s detected; keyval=%u state=%u, event_key_command=%u\n",
    //(event->keyval == GDK_KEY_at) ? "+@" : (event->keyval == GDK_KEY_numbersign) ? "+#" : (event->keyval == GDK_KEY_bar) ? "+|" : "",
    //(uint16_t)event->keyval, (uint16_t)event->state, (uint16_t)event_key_command);
//}

    //old way
    //  if(32 <= event_keyval && event_keyval <= 255) {
    //    ll = asciiToItem((uint8_t)event_keyval);
    //    if(ll > 0) {
    //      sendKey(ll);
    //      screenUpdatingMode = SCRUPD_AUTO;
    //      refreshScreen(8);
    //      return false;
    //    }
    //    else {
    //      goto nextchar;
    //    }
    //  }

    uint8_t alphaCase_MEM = alphaCase;
    ll = event->keyval;

    //Deadkey ^ simulation
    //if(ll=='a') ll = 65106;

    if('A' <= ll && ll <= 'Z' && alphaCase == AC_UPPER) {         //A-Z is shifted on PC, and flips
      ll += ('a' - 'A');
      alphaCase = AC_LOWER;
    }
    else if('A' <= ll && ll <= 'Z' && alphaCase == AC_LOWER) {
      alphaCase = AC_UPPER;
    }
    else if('a' <= ll && ll <= 'z' && alphaCase == AC_UPPER) {    //a-z is natural on PC, and if CAPS(o) produce CAPS
      ll -= ('a' - 'A');
    }
    else if('a' <= ll && ll <= 'z' && alphaCase == AC_LOWER) {    //a-z is natural on PC, and if CAPS( ) produces LC
    }
  //refreshStatusBar();

    ll = _keyCodeFromGdkKey(ll);        //utilise the raw key event value, which will be contain a-z or A-Z
    if(ll > 0) {
      sendKey(ll);
      screenUpdatingMode = SCRUPD_AUTO;
      refreshStatusBar();
      refreshScreen(8);
      refreshLcd(NULL);
      resetShiftState();
      alphaCase = alphaCase_MEM;
      goto returnKeyPressedFalse;
    }
    else if(ll == -1) {   //do not continue looking for keys
      screenUpdatingMode = SCRUPD_AUTO;
      alphaCase = alphaCase_MEM;
      refreshStatusBar();
      refreshScreen(8);
      refreshLcd(NULL);
      resetShiftState();
      goto returnKeyPressedFalse;
    }
    alphaCase = alphaCase_MEM;

    #if defined(VERBOSEKEYS)
      printf("------------------------ Done new alpha detection, skipping to rest of key detections\n");
    #endif
  }




continueWithOldDetections:
    #if defined(VERBOSEKEYS) || defined(VERBOSE_MINIMUM)
      printf("   Continue with old key detection using event_keyval=%u\n\n",event_keyval);
      fflush(stdout);
    #endif

      switch(event_keyval) {
        case GDK_KEY_H+65536: // Ctrl H
        case GDK_KEY_h+65536: // Ctrl h
          CTRL_State = 0;
          printf("key pressed: CTRL+h Hardcopy\n");
          copyScreenToClipboard();
          break;

      case 83+65536: // Ctrl S
      case 115+65536: // Ctrl s
        CTRL_State = 0;
        printf("key pressed: CTRL+s SNAP\n");
        fnSNAP(NOPARAM);
        break;

      case 120+65536: // CTRL x
      case 88+65536: // CTRL X
      case 99+65536: // CTRL c
      case 67+65536: // CTRL C
        CTRL_State = 0;
        printf("key pressed: CTRL+c/x Copy x register to clipboard\n");
        copyRegisterXToClipboard();
        break;

      case 100+65536: // CTRL d
      case 68+65536: // CTRL D
        CTRL_State = 0;
        printf("key pressed: CTRL+d Copy Stack registers to clipboard\n");
        copyStackRegistersToClipboard();
        break;

      case 97+65536: // CTRL a
      case 65+65536: // CTRL A
        CTRL_State = 0;
        printf("key pressed: CTRL+d Copy All registers to clipboard\n");
        copyAllRegistersToClipboard();
        break;

      default:;
    }



    //JM ALPHA SECTION FOR ALPHAMODE - TAKE OVER ALPHA KEYBOARD
    if(calcMode == CM_AIM || calcMode == CM_EIM || tam.mode || (calcMode == CM_PEM && getSystemFlag(FLAG_ALPHA)) || tam.alpha) {
      printf(">>>>> ALPHA SECTION Keyboard Key Code = %d\n", event_keyval);fflush(stdout);
      switch(event_keyval) {

        //ROW 0
        case GDK_KEY_Up:                                               //JM     // CursorUp //JM
          if(AlphaArrowsOffAndUpDn) {
            btnClicked(w,  isR47FAM?"22":"17");   //Up
          }
          else if(calcMode == CM_EIM) {
            btnClicked(w, isR47FAM?"22":"17");   //Up
          }
          else {
            if(!tam.mode) {
              btnFnClicked(w, "1");  //F1
            }
          }
          break;
        case GDK_KEY_Down:                                               //JM     // CursorDown //JM
          if(AlphaArrowsOffAndUpDn)
            btnClicked(w, isR47FAM?"27":"22");   //Up
          else if(calcMode == CM_EIM)
            btnClicked(w, isR47FAM?"27":"22");   //Dn
          else
            btnFnClicked(w, "2");  //F2
          break;
        case GDK_KEY_Left:                                               //JM     // CursorLt BST //JM Left
          if(AlphaArrowsOffAndUpDn) {
          }
//          else if(calcMode == CM_EIM) {                 //removed, because EQ_EDIT was changed long ago to have left right arrows on every key.
//            int16_t jj = softmenuStack[0].firstItem;
//            softmenuStack[0].firstItem = 0;
//            btnFnClicked(w, "5");  //F1
//            softmenuStack[0].firstItem = jj;
//            showSoftmenuCurrentPart();
//          }
//          else
          {
            #if defined(ALTERNATE_ALPHA_F1)
              btnFnClicked(w, "1");  //F5
            #elif defined(ALTERNATE_ALPHA_F5)
              btnFnClicked(w, "5");  //F5
            #else
              btnFnClicked(w, "5");  //F5
            #endif //ALTERNATE_ALPHA_F1
          }
          break;
        case GDK_KEY_Right:                                               //JM     // CursorRt SST //JM Right
          if(AlphaArrowsOffAndUpDn) {
          }
  //        else if(calcMode == CM_EIM) {                 //removed, because EQ_EDIT was changed long ago to have left right arrows on every key.
  //          int16_t jj = softmenuStack[0].firstItem;
  //          softmenuStack[0].firstItem = 0;
  //          btnFnClicked(w, "6");  //F6
  //          softmenuStack[0].firstItem = jj;
  //          showSoftmenuCurrentPart();
  //        }
  //        else
          {
            btnFnClicked(w, "6");  //F6
          }
          break;


        //ROW 1
        case GDK_KEY_F1: // F1                                                    //**************-- FUNCTION KEYS --***************//
          if(calcMode == CM_EIM || AlphaArrowsOffAndUpDn || labelText) {
            #if defined(VERBOSEKEYS)
              printf("key FNPressed - PRESS: F1\n");
            #endif
            btnFnClickedP(w, "1");
          }
          else {
            #if defined(VERBOSEKEYS)
              printf("key FNpressed: F1\n");
            #endif
            btnFnClicked(w, "1");
          }
          break;
        case GDK_KEY_F2: // F2
          if(calcMode == CM_EIM || AlphaArrowsOffAndUpDn || labelText) {
            #if defined(VERBOSEKEYS)
              printf("key FNPressed - PRESS: F2\n");
            #endif
            btnFnClickedP(w, "2");
          }
          else {
            #if defined(VERBOSEKEYS)
              printf("key FNpressed: F2\n");
            #endif
            btnFnClicked(w, "2");
          }
          break;
        case GDK_KEY_F3: // F3
          if(calcMode == CM_EIM || AlphaArrowsOffAndUpDn || labelText) {
            #if defined(VERBOSEKEYS)
              printf("key FNPressed - PRESS: F3\n");
            #endif
            btnFnClickedP(w, "3");
          }
          else {
            #if defined(VERBOSEKEYS)
              printf("key FNpressed: F3\n");
            #endif
            btnFnClicked(w, "3");
          }
          break;
        case GDK_KEY_F4: // F4
          if(calcMode == CM_EIM || AlphaArrowsOffAndUpDn || labelText) {
            #if defined(VERBOSEKEYS)
              printf("key FNPressed - PRESS: F4\n");
            #endif
            btnFnClickedP(w, "4");
          }
          else {
            #if defined(VERBOSEKEYS)
              printf("key FNpressed: F4\n");
            #endif
            btnFnClicked(w, "4");
          }
          break;
        case GDK_KEY_F5: // F5
          if(calcMode == CM_EIM || AlphaArrowsOffAndUpDn || labelText) {
            #if defined(VERBOSEKEYS)
              printf("key FNPressed - PRESS: F5\n");
            #endif
            btnFnClickedP(w, "5");
          }
          else {
            #if defined(VERBOSEKEYS)
              printf("key FNpressed: F5\n");
            #endif
            btnFnClicked(w, "5");
          }
          break;
        case GDK_KEY_F6: // F6
          if(calcMode == CM_EIM || AlphaArrowsOffAndUpDn || labelText) {
            #if defined(VERBOSEKEYS)
              printf("key FNPressed - PRESS: F6\n");
            #endif
            btnFnClickedP(w, "6");
          }
          else {
            #if defined(VERBOSEKEYS)
              printf("key FNpressed: F6\n");
            #endif
            btnFnClicked(w, "6");
          }
          break;



        //ROW 2
        case 65:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM.    //**************-- ALPHA KEYS UPPER CASE --***************//
        case 66:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 67:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 68:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 69:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 70:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 94:  //^

        //ROW 3
        case 71:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 72:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 73:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 74:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 75:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 76:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 124:  //|
          break;

        //ROW 4
        case 77:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 78:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 79:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 177: //+-

        //ROW 5
        case 80:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 81:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 82:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 83:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 6
        case 84:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 85:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 86:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 87:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 7
        case 88:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 89:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 90:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //JM ALPHA LOWER CASE SECTION FOR ALPHAMODE - TAKE OVER ALPHA KEYBOARD
        //ROW 2
        case 65+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM     //**************-- ALPHA KEYS LOWER CASE --***************//
        case 66+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 67+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 68+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 69+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 70+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 3
        case 71+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 72+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 73+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 74+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 75+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 76+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 4
        case 77+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 78+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 79+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 5
        case 80+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 81+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 82+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 83+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 6
        case 84+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 85+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 86+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 87+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        //ROW 7
        case 88+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 89+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
        case 90+32:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM

        case 95:                //JM UNDERSCORE   //JM
        case 58:                 // COLON.        //JM
        case 59:                 // semicolon.    //JM
        case 44:                 // ,             //JM
        case 63:                 // ?             //JM
        case 32:                //JM SPACE        //JM

          printf("-------------------------------------------\n\n\n######## MISSING OLD TEXT OUTPUT A %i ########\n\n", event_keyval);
          break;



        //ROW 4
        case GDK_KEY_KP_Enter:                                               //JM    // Enter
        case GDK_KEY_Return:                                                 //JM    // Enter
          btnClicked(w, "12");
          break;
        case GDK_KEY_BackSpace: // Backspace
          btnClicked(w, "16");
          break;
        case GDK_KEY_KP_Delete:
        case GDK_KEY_Delete: // Delete
          fnT_ARROW(ITM_T_RIGHT_ARROW);
          btnClicked(w, "16");
          break;

        //ROW 5
        case GDK_KEY_Home:                                               //JM     // HOME  //JM
          btnClicked(w, "17");
          break;

        //ROW 6
        case GDK_KEY_End:                                               //JM     // END  //JM
          btnClicked(w, "22");
          break;

        //JM  NUMERALS FOR ALPHAMODE - TAKE OVER ALPHA KEYBOARD
        //ROW 5
        case 65463: // 7
        case 48+7:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM     //**************-- NUM KEYS  --***************//
          btnClicked_NU(w, "18");                                            // Numbers from PC --> produce numbers.
          break;
        case 65464: // 8
        case 48+8:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "19");
          break;
        case 65465: // 9
        case 48+9:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "20");
          break;

        //ROW 6
        case 65460: // 4
        case 48+4:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "23");
          break;
        case 65461: // 5
        case 48+5:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "24");
          break;
        case 65462: // 6
        case 48+6:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "25");
          break;

        //ROW 7
        case 65457: // 1
        case 48+1:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "28");
          break;
        case 65458: // 2
        case 48+2:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "29");
          break;
        case 65459: // 3
        case 48+3:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "30");
          break;

        //ROW 8
        case 65456: // 0
        case 48+0:  //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM
          btnClicked_NU(w, "33");
          break;
        case 46:    //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM             // .        //JM
        case 65454: //JM SHIFTED CAPITAL ALPHA AND SHIFTED NUMERAL  //JM             // .        //JM
          btnClicked_NU(w, "34");
          break;

        //OPERATORS / * - +
        case 65455: // / //JM
        case 47:              // divide                   //JM     //**************-- OTHER DIRECT ALPHA MODE KEYBOARD KEYS  --***************//
          btnClicked_NU(w, "21");
          break;
        case 65450: // * //JM
        case 42:              // mult                     //JM     //**************-- OTHER DIRECT ALPHA MODE KEYBOARD KEYS  --***************//
          btnClicked_NU(w, "26");
          break;
        case 65453: // - //JM
        case 45:              // sub                      //JM     //**************-- OTHER DIRECT ALPHA MODE KEYBOARD KEYS  --***************//
          btnClicked_NU(w, "31");
          break;
        case 65451: // + //JM
        case 43:              // plus                     //JM     //**************-- OTHER DIRECT ALPHA MODE KEYBOARD KEYS  --***************//
          btnClicked_NU(w, "36");
          break;

        case 65307:              // Esc EXIT      //JM                   //JM     //**************-- OTHER DIRECT ALPHA MODE KEYBOARD KEYS  --***************//
          btnClicked(w, "32");
          break;

        default: ;

      }
      goto returnKeyPressedFalse;
    }
    else {
      //ORIGINAL MODIFIED KEYBOARD DETECTION
      //FOR NON AIM MODE. AIM HAS RETURNED AT THIS POINT SO NO IF NEEDED
      switch(event_keyval) {

        case GDK_KEY_question: // Question mark is blank key
          if(calcModel == USER_R47fg_bk && (calcMode == CM_NORMAL || calcMode == CM_NIM)) {
            btnClicked(w, "11");
          } else
          if(calcModel == USER_R47bk_fg && (calcMode == CM_NORMAL || calcMode == CM_NIM)) {
            btnClicked(w, "10");
          }
          break;

        case GDK_KEY_Left:                                               //JM     // CursorLt  //JM Left
          btnFnClicked(w, "5");  //F5
          break;
        case GDK_KEY_Right:                                               //JM     // CursorRt  //JM Right
          btnFnClicked(w, "6");  //F6
          break;

        //ROW 1
        case GDK_KEY_F1: // F1                       //JM Changed these to btnFnPressed from btnFnClicked
          //printf("key pressed: F1\n");
          btnFnClickedP(w, "1");
          break;

        case GDK_KEY_F2: // F2
          //printf("key pressed: F2\n");
          btnFnClickedP(w, "2");
          break;

        case GDK_KEY_F3: // F3
          //printf("key pressed: F3\n");
          btnFnClickedP(w, "3");
          break;

        case GDK_KEY_F4: // F4
          //printf("key pressed: F4\n");
          btnFnClickedP(w, "4");
          break;

        case GDK_KEY_F5: // F5
          //printf("key pressed: F5\n");
          btnFnClickedP(w, "5");
          break;

        case GDK_KEY_F6: // F6
          //printf("key pressed: F6\n");
          btnFnClickedP(w, "6");
          break;


        case 97:  // a  //dr
        case 118: // v //dr
        case 113: // q //dr
        case 111: // o //dr
        case 108: // l //dr
        case 120: // x //dr
        case 109: // m //dr
        case 114: // r
        case 100: // d //dr
        case 112: // p         //dr                //JM Special case: p = x^2
        case 61: // =          //                //JM Special case: = = DRG
        case 121: // y         //dr                //JM Special case: y: y^x
        case 115: // s //dr
        case 99:  // c //dr
        case 116: // t //dr

          printf("-------------------------------------------\n\n\n######## MISSING OLD TEXT OUTPUT B %i ########\n\n", event_keyval);
          break;

        //ROW 4
        case GDK_KEY_KP_Enter: // Enter
        case 65293: // Enter
          //printf("key pressed: ENTER\n");
          btnClicked(w, "12");
          break;

        //dr    case 65289: // Tab
        case 119: // w //dr
          //printf("key pressed: w x<>y\n"); //dr
          btnClicked(w, "13");
          break;

        case 110: // n //dr
          //printf("key pressed: n +/-\n"); //dr
          btnClicked(w, "14");
          break;

        //dr    case 69:  // E
        case 101: // e //dr
        //printf("key pressed: e EXP\n"); //dr
          btnClicked(w, "15");
          break;

        case GDK_KEY_BackSpace: // Backspace
          //printf("key pressed: Backspace\n");
          btnClicked(w, "16");
          break;

        //ROW 5
        case GDK_KEY_Up: // CursorUp //JM
                                //JM
          //printf("key pressed: <Up>\n"); //dr
          btnClicked(w, isR47FAM?"22":"17");
          break;

        case 55:    // 7
        case 65463: // 7
          //printf("key pressed: 7\n");
          btnClicked(w, "18");
          break;

        case 56:    // 8
        case 65464: // 8
          //printf("key pressed: 8\n");
          btnClicked(w, "19");
          break;

        case 57:    // 9
        case 65465: // 9
          //printf("key pressed: 9\n");
          btnClicked(w, "20");
          break;

        case 47:    // / //JM
        case 65455: // / //JM
          //printf("key pressed: divide\n"); //dr
          btnClicked(w, "21");
          break;

        //ROW 6
        case GDK_KEY_Down: // CursorDown //JM
                                  //JM
          //printf("key pressed: <Down>\n"); //dr
          btnClicked(w, isR47FAM?"27":"22");
          break;

        case 52:    // 4
        case 65460: // 4
          //printf("key pressed: 4\n");
          btnClicked(w, "23");
          break;

        case 53:    // 5
        case 65461: // 5
          //printf("key pressed: 5\n");
          btnClicked(w, "24");
          break;

        case 54:    // 6
        case 65462: // 6
          //printf("key pressed: 6\n");
          btnClicked(w, "25");
          break;

        case 42:    // * //JM
        case 65450: // * //JM
          //printf("key pressed: multiply\n"); //dr
          btnClicked(w, "26");
          break;

        //ROW 7
        case 49:    // 1
        case 65457: // 1
          //printf("key pressed: 1\n");
          btnClicked(w, "28");
          break;

        case 50:    // 2
        case 65458: // 2
          //printf("key pressed: 2\n");
          btnClicked(w, "29");
          break;

        case 51:    // 3
        case 65459: // 3
          //printf("key pressed: 3\n");
          btnClicked(w, "30");
          break;

        case 45:    // - //JM
        case 65453: // - //JM
          //printf("key pressed: subtract\n"); //dr
          btnClicked(w, "31");
          break;

        //ROW 8
        case 65307: // Esc //JM
                          //JM
          //printf("key pressed: EXIT\n"); //dr
          btnClicked(w, "32");
          break;

        case 48:    // 0
        case 65456: // 0
          //printf("key pressed: 0\n");
          btnClicked(w, "33");
          break;

        case 44:    // ,
        case 46:    // .
        case 65454: // .
          //printf("key pressed: .\n");
          btnClicked(w, "34");
          break;

//taken over        case 92: // \                                //JM R/S changed to \ as on Mac CTRL is something else.
//taken over          //printf("key pressed: \\ R/S\n");
//taken over          btnClicked(w, "35");
//taken over          break;


        case 43:    // + //JM
        case 65451: // + //JM
          //printf("key pressed: add\n"); //dr
          btnClicked(w, "36");
          break;

        /*//JM- Reinstated
        case 72:  // H    //JM REMOVE CAP H. ONLY lower case wil print
        case 104: // h
          //printf("key pressed: h Hardcopy to clipboard\n");
          copyScreenToClipboard();
          break;
        */

        case GDK_KEY_Control_L: // left Ctrl
        case GDK_KEY_Control_R: // right Ctrl
          //printf("key pressed: CTRL Activated\n");
          CTRL_State = 65536;
          break;

        default: ;
      }
    }
returnKeyPressedFalse:
    previousEventStateP = event->state;
    previousEventKeyP   = event->keyval;
    return FALSE;
  }


  #if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
    /* Reads the CSS file to configure the calc's GUI style. */
    static void prepareCssData(void) {
      FILE *cssFile;
      char *toReplace, *replaceWith, needle[100], newNeedle[100];
      int  fileLg;

      // Convert the pre-CSS data to CSS data
      cssFile = fopen(CSSFILE, "rb");
      if(cssFile == NULL) {
        moreInfoOnError("In function prepareCssData:", "error opening file " CSSFILE "!", NULL, NULL);
        exit(1);
      }

      // Get the file length
      fseek(cssFile, 0L, SEEK_END);
      fileLg = ftell(cssFile);
      fseek(cssFile, 0L, SEEK_SET);

      cssData = malloc(2*fileLg); // To be sure there is enough space
      if(cssData == NULL) {
        moreInfoOnError("In function prepareCssData:", "error allocating 10000 bytes for CSS data", NULL, NULL);
        exit(1);
      }

      ignoreReturnedValue(fread(cssData, 1, fileLg, cssFile));
      fclose(cssFile);
      cssData[fileLg] = 0;

      toReplace = strstr(cssData, "/* Replace $");
      while(toReplace != NULL) {
        int i = -1;
        toReplace += 11;
        while(toReplace[++i] != ' ') {
          needle[i] = toReplace[i];
        }
        needle[i] = 0;

        *toReplace = ' ';

        replaceWith = strstr(toReplace, " with ");
        if(replaceWith == NULL) {
          moreInfoOnError("In function prepareCssData:", "Can't find \" with \" after \"/* Replace $\" in CSS file " CSSFILE, NULL, NULL);
          exit(1);
        }

        replaceWith[1] = ' ';
        replaceWith += 6;
        i = -1;
        while(replaceWith[++i] != ' ') {
          newNeedle[i] = replaceWith[i];
        }
        newNeedle[i] = 0;

        strReplace(toReplace, needle, newNeedle);

        toReplace = strstr(cssData, "/* Replace $");
      }

      if(strstr(cssData, "$") != NULL) {
        moreInfoOnError("In function prepareCssData:", "There is still an unreplaced $ in the CSS file!\nPlease check file " CSSFILE, NULL, NULL);
        printf("%s\n", cssData);
        exit(1);
      }
    }



    typedef struct {              //JM VALUES DEMO
      char     C47 [16];
      char     C47A[16];
      char     R47 [16];
      char     R47A[16];
    } shortCut_t;

    const shortCut_t shortCutString[] = {
      {"a",        "A",  "Q",         "A"},  //00
      {"v",        "B",  "q",         "B"},  //00
      {"q",        "C",  "v",         "C"},  //00
      {"o",        "D",  "Y",         "D"},  //00
      {"l",        "E",  "o",         "E"},  //00
      {"x",        "F",  "l",         "F"},  //00

      {"m",        "G",  "m",         "G"},  //00
      {"r",        "H",  "r",         "H"},  //00
      {"d",        "I",  "d",         "I"},  //00
      {"s",        "J",  ">",         "J"},  //00
      {"c",        "K",  "" ,         "" },  //00
      {"t",        "L",  "" ,         "" },  //00

      {"Enter",    "",   "Enter",     "" },  //00
      {"w",        "M",  "w",         "K"},  //00
      {"n",        "N",  "n",         "L"},  //00
      {"e",        "O",  "e",         "M"},  //00
      {"Backspace","",   "Backspace", "" },  //00

      {"Up",       "",   "x",         ""},   //00
      {"7" ,       "P",  "7",         "N"},  //00
      {"8" ,       "Q",  "8",         "O"},  //00
      {"9" ,       "R",  "9",         "P"},  //00
      {"/" ,       "S",  "/" ,        "Q" }, //00

      {"Dn",       "",   "Up",        ""},   //00
      {"4" ,       "T",  "4",         "R"},  //00
      {"5" ,       "U",  "5",         "S"},  //00
      {"6" ,       "V",  "6",         "T"},  //00
      {"x" ,       "W",  "x" ,        "U" }, //00

      {"f/g",      "",   "Dn",        ""},   //00
      {"1" ,       "X",  "1",         "V"},  //00
      {"2" ,       "Y",  "2",         "W"},  //00
      {"3" ,       "Z",  "3",         "X"},  //00
      {"-" ,       "_",  "-" ,        "Y" }, //00

      {"Esc",      "",   "Esc",       ""},   //00
      {"0" ,       ":",  "0",         "Z"},  //00
      {"." ,       ".",  ".",         ","},  //00
      {"\\" ,      "?",  "\\",        "?"},  //00
      {"+" ,     "Space","+" ,        "Space" } //00
    };


    /********************************************//**
    * \brief Hides all the widgets on the calc GUI
    *
    * \param void
    * \return void
    ***********************************************/
    void hideAllWidgets(void) {
      gtk_widget_hide(lblFKey2);  //JMLINES
      gtk_widget_hide(lblGKey2);  //JMLINES
      gtk_widget_hide(btn11);
      gtk_widget_hide(btn12);
      gtk_widget_hide(btn13);
      gtk_widget_hide(btn14);
      gtk_widget_hide(btn15);
      gtk_widget_hide(btn16);

      gtk_widget_hide(btn21);
      gtk_widget_hide(btn22);
      gtk_widget_hide(btn23);
      gtk_widget_hide(btn24);
      gtk_widget_hide(btn25);
      gtk_widget_hide(btn26);
      gtk_widget_hide(btn21A);  //vv dr - new AIM
      gtk_widget_hide(btn22A);
      gtk_widget_hide(btn23A);
      gtk_widget_hide(btn24A);
      gtk_widget_hide(btn25A);
      gtk_widget_hide(btn26A);  //^^

      gtk_widget_hide(lbl21F);
      gtk_widget_hide(lbl21G);
      gtk_widget_hide(lbl21L);
      gtk_widget_hide(lbl22F);
      gtk_widget_hide(lbl22G);
      gtk_widget_hide(lbl22L);
      gtk_widget_hide(lbl23F);
      gtk_widget_hide(lbl23G);
      gtk_widget_hide(lbl23L);
      gtk_widget_hide(lbl24F);
      gtk_widget_hide(lbl24G);
      gtk_widget_hide(lbl24L);
      gtk_widget_hide(lbl25F);
      gtk_widget_hide(lbl25G);
      gtk_widget_hide(lbl25L);
      gtk_widget_hide(lbl26F);
      gtk_widget_hide(lbl26G);
      gtk_widget_hide(lbl26L);
      gtk_widget_hide(lbl21Gr);
      gtk_widget_hide(lbl22Gr);
      gtk_widget_hide(lbl23Gr);
      gtk_widget_hide(lbl24Gr);
      gtk_widget_hide(lbl25Gr);
      gtk_widget_hide(lbl26Gr);

      gtk_widget_hide(lbl21Fa); //JM AIM2
      gtk_widget_hide(lbl22Fa); //JM AIM2
      gtk_widget_hide(lbl23Fa); //JM AIM2
      gtk_widget_hide(lbl24Fa); //JM AIM2
      gtk_widget_hide(lbl25Fa); //JM AIM2
      gtk_widget_hide(lbl26Fa); //JM AIM2


      gtk_widget_hide(btn31);
      gtk_widget_hide(btn32);
      gtk_widget_hide(btn33);
      gtk_widget_hide(btn34);
      gtk_widget_hide(btn35);
      gtk_widget_hide(btn36);
      gtk_widget_hide(btn31A);  //vv dr - new AIM
      gtk_widget_hide(btn32A);
      gtk_widget_hide(btn33A);
      gtk_widget_hide(btn34A);
      gtk_widget_hide(btn35A);
      gtk_widget_hide(btn36A);  //^^

      gtk_widget_hide(lbl31F);
      gtk_widget_hide(lbl31G);
      gtk_widget_hide(lbl31L);
      gtk_widget_hide(lbl32F);
      gtk_widget_hide(lbl32G);
      gtk_widget_hide(lbl32L);
      gtk_widget_hide(lbl33F);
      gtk_widget_hide(lbl33G);
      gtk_widget_hide(lbl33L);
      gtk_widget_hide(lbl34F);
      gtk_widget_hide(lbl34G);
      gtk_widget_hide(lbl34L);
      gtk_widget_hide(lbl35F);
      gtk_widget_hide(lbl35G);
      gtk_widget_hide(lbl35L);
      gtk_widget_hide(lbl36F);
      gtk_widget_hide(lbl36G);
      gtk_widget_hide(lbl36L);
      gtk_widget_hide(lbl31Gr);
      gtk_widget_hide(lbl32Gr);
      gtk_widget_hide(lbl33Gr);
      gtk_widget_hide(lbl34Gr);
      gtk_widget_hide(lbl35Gr);
      gtk_widget_hide(lbl36Gr);

      gtk_widget_hide(lbl31Fa); //JM AIM2
      gtk_widget_hide(lbl32Fa); //JM AIM2
      gtk_widget_hide(lbl33Fa); //JM AIM2
      gtk_widget_hide(lbl34Fa); //JM AIM2
      gtk_widget_hide(lbl35Fa); //JM AIM2
      gtk_widget_hide(lbl36Fa); //JM AIM2

      //gtk_widget_hide(lbl34Fa); //JMALPHA2
      //gtk_widget_hide(lbl35Fa); //JMALPHA2

      gtk_widget_hide(btn41);
      gtk_widget_hide(btn42);
      gtk_widget_hide(btn43);
      gtk_widget_hide(btn44);
      gtk_widget_hide(btn45);
      gtk_widget_hide(btn42A);  //vv dr - new AIM
      gtk_widget_hide(btn43A);
      gtk_widget_hide(btn44A);  //^^

      gtk_widget_hide(lbl41F);
      gtk_widget_hide(lbl41G);
      gtk_widget_hide(lbl41L);
      gtk_widget_hide(lbl42F);
      gtk_widget_hide(lbl42G);
      gtk_widget_hide(lbl42L);
      gtk_widget_hide(lbl43F);
      gtk_widget_hide(lbl43G);
      gtk_widget_hide(lbl43L);
      gtk_widget_hide(lbl44F);
      gtk_widget_hide(lbl44G);
      gtk_widget_hide(lbl44L);
      //gtk_widget_hide(lbl44P);
      gtk_widget_hide(lbl45F);
      gtk_widget_hide(lbl45G);
      gtk_widget_hide(lbl45L);
      gtk_widget_hide(lbl41Gr);
      gtk_widget_hide(lbl42Gr);
      gtk_widget_hide(lbl43Gr);
      gtk_widget_hide(lbl44Gr);
      gtk_widget_hide(lbl45Gr);
      gtk_widget_hide(lbl41Fa); //JM
      gtk_widget_hide(lbl42Fa); //vv dr - new AIM
      gtk_widget_hide(lbl43Fa); //^^
      gtk_widget_hide(lbl44Fa); //JM AIM2
      gtk_widget_hide(lbl45Fa); //JM

      gtk_widget_hide(btn51);
      gtk_widget_hide(btn52);
      gtk_widget_hide(btn53);
      gtk_widget_hide(btn54);
      gtk_widget_hide(btn55);
      gtk_widget_hide(btn52A);  //vv dr - new AIM
      gtk_widget_hide(btn53A);
      gtk_widget_hide(btn54A);
      gtk_widget_hide(btn55A);  //^^

      gtk_widget_hide(lbl51F);
      gtk_widget_hide(lbl51G);
      gtk_widget_hide(lbl51L);
      gtk_widget_hide(lbl52F);
      gtk_widget_hide(lbl52G);
      gtk_widget_hide(lbl52L);
      gtk_widget_hide(lbl53F);
      gtk_widget_hide(lbl53G);
      gtk_widget_hide(lbl53L);
      gtk_widget_hide(lbl54F);
      gtk_widget_hide(lbl54G);
      gtk_widget_hide(lbl54L);
      gtk_widget_hide(lbl55F);
      gtk_widget_hide(lbl55G);
      gtk_widget_hide(lbl55L);
      gtk_widget_hide(lbl51Gr);
      gtk_widget_hide(lbl52Gr);
      gtk_widget_hide(lbl53Gr);
      gtk_widget_hide(lbl54Gr);
      gtk_widget_hide(lbl55Gr);
      gtk_widget_hide(lbl51Fa);
      gtk_widget_hide(lbl52Fa); //vv dr - new AIM
      gtk_widget_hide(lbl53Fa);
      gtk_widget_hide(lbl54Fa);
      gtk_widget_hide(lbl55Fa); //^^

      gtk_widget_hide(btn61);
      gtk_widget_hide(btn62);
      gtk_widget_hide(btn63);
      gtk_widget_hide(btn64);
      gtk_widget_hide(btn65);
      gtk_widget_hide(btn62A);  //vv dr - new AIM
      gtk_widget_hide(btn63A);
      gtk_widget_hide(btn64A);
      gtk_widget_hide(btn65A);  //^^

      gtk_widget_hide(lbl61F);
      gtk_widget_hide(lbl61G);
      gtk_widget_hide(lbl61L);
      gtk_widget_hide(lbl62F);
      gtk_widget_hide(lbl62G);
      gtk_widget_hide(lbl62L);
      gtk_widget_hide(lbl63F);
      gtk_widget_hide(lbl63G);
      gtk_widget_hide(lbl63L);
      gtk_widget_hide(lbl64F);
      gtk_widget_hide(lbl64G);
      gtk_widget_hide(lbl64L);
      gtk_widget_hide(lbl65F);
      gtk_widget_hide(lbl65G);
      gtk_widget_hide(lbl65L);
      gtk_widget_hide(lbl61Gr);
      gtk_widget_hide(lbl62Gr);
      gtk_widget_hide(lbl63Gr);
      gtk_widget_hide(lbl64Gr);
      gtk_widget_hide(lbl65Gr);
      gtk_widget_hide(lbl61Fa);
      gtk_widget_hide(lbl62Fa);
      gtk_widget_hide(lbl63Fa);
      gtk_widget_hide(lbl64Fa);
      gtk_widget_hide(lbl65Fa); //^^

      gtk_widget_hide(btn71);
      gtk_widget_hide(btn72);
      gtk_widget_hide(btn73);
      gtk_widget_hide(btn74);
      gtk_widget_hide(btn75);
      gtk_widget_hide(btn71A);
      gtk_widget_hide(btn72A);  //vv dr - new AIM
      gtk_widget_hide(btn73A);
      gtk_widget_hide(btn74A);
      gtk_widget_hide(btn75A);  //^^

      gtk_widget_hide(lbl71F);
      gtk_widget_hide(lbl71G);
      gtk_widget_hide(lbl71L);
      gtk_widget_hide(lbl72F);
      gtk_widget_hide(lbl72G);
      gtk_widget_hide(lbl72L);
      gtk_widget_hide(lbl73F);
      gtk_widget_hide(lbl73G);
      gtk_widget_hide(lbl73L);
      gtk_widget_hide(lbl74F);
      gtk_widget_hide(lbl74G);
      gtk_widget_hide(lbl74L);
      gtk_widget_hide(lbl75F);
      gtk_widget_hide(lbl75G);
      gtk_widget_hide(lbl75L);
      gtk_widget_hide(lbl71Gr);
      gtk_widget_hide(lbl72Gr);
      gtk_widget_hide(lbl73Gr);
      gtk_widget_hide(lbl74Gr);
      gtk_widget_hide(lbl75Gr);
      gtk_widget_hide(lbl71Fa);
      gtk_widget_hide(lbl72Fa);
      gtk_widget_hide(lbl73Fa);
      gtk_widget_hide(lbl74Fa);
      gtk_widget_hide(lbl75Fa); //^^

      gtk_widget_hide(btn81);
      gtk_widget_hide(btn82);
      gtk_widget_hide(btn83);
      gtk_widget_hide(btn84);
      gtk_widget_hide(btn85);
      gtk_widget_hide(btn82A);  //vv dr - new AIM
      gtk_widget_hide(btn83A);
      gtk_widget_hide(btn84A);
      gtk_widget_hide(btn85A);  //^^

      gtk_widget_hide(lbl81F);
      gtk_widget_hide(lbl81G);
      gtk_widget_hide(lbl81L);
      gtk_widget_hide(lbl82F);
      gtk_widget_hide(lbl82G);
      gtk_widget_hide(lbl82L);
      gtk_widget_hide(lbl83F);
      gtk_widget_hide(lbl83G);
      gtk_widget_hide(lbl83L);
      gtk_widget_hide(lbl84F);
      gtk_widget_hide(lbl84G);
      gtk_widget_hide(lbl84L);
      gtk_widget_hide(lbl85F);
      gtk_widget_hide(lbl85G);
      gtk_widget_hide(lbl85L);
      gtk_widget_hide(lbl81Gr);
      gtk_widget_hide(lbl82Gr);
      gtk_widget_hide(lbl83Gr);
      gtk_widget_hide(lbl84Gr);
      gtk_widget_hide(lbl85Gr);
      gtk_widget_hide(lbl82Fa); //vv dr - new AIM
      gtk_widget_hide(lbl83Fa);
      gtk_widget_hide(lbl84Fa);
      gtk_widget_hide(lbl85Fa); //^^

      //gtk_widget_hide(lblOn);
      //JM7 gtk_widget_hide(lblConfirmY);  //JM Y/N
      //JM7 gtk_widget_hide(lblConfirmN);  //JM Y/N

    }



    void moveLabels(void) {
      int            xPos, yPos;
      GtkRequisition lblF, lblG;

      if(calcLandscape) {
        xPos = X_LEFT_LANDSCAPE;
        yPos = Y_TOP_LANDSCAPE;
      }
      else {
        xPos = X_LEFT_PORTRAIT;
        yPos = Y_TOP_PORTRAIT + DELTA_KEYS_Y;
      }

      #if defined(__MINGW64__)
        yPos += 5;
      #endif

      gtk_widget_get_preferred_size(  lbl21F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl21G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl21F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl21G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl21Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl21Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl21Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl21Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl22F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl22G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl22F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl22G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl22Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl22Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl22Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl22Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl23F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl23G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl23F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl23G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl23Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl23Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl23Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl23Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl24F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl24G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl24F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl24G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl24Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl24Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl24Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl24Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl25F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl25G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl25F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl25G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl25Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl25Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl25Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl25Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl26F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl26G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl26F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl26G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl26Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl26Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl26Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl26Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y;
      gtk_widget_get_preferred_size(  lbl31F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl31G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl31F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl31G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl31Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl31Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl31Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl31Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl32F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl32G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl32F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl32G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl32Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl32Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl32Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl32Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl33F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl33G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl33F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl33G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl33Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl33Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl33Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl33Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl34F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl34G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl34F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl34G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl34Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl34Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl34Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl34Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl35F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl35G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl35F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl35G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl35Gr, NULL, &lblG);                                                               //JM !! GR
      gtk_fixed_move(GTK_FIXED(grid), lbl35Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);  //JM !! GR
      gtk_widget_get_preferred_size(  lbl35Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl35Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl36F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl36G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl36F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl36G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl36Gr, NULL, &lblG);                                                               //JM !! GR
      gtk_fixed_move(GTK_FIXED(grid), lbl36Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);  //JM !! GR
      gtk_widget_get_preferred_size(  lbl36Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl36Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y;
      gtk_widget_get_preferred_size(  lbl41F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl41G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl41F, (2*xPos+KEY_WIDTH_1+DELTA_KEYS_X-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl41G, (2*xPos+KEY_WIDTH_1+DELTA_KEYS_X+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl41Gr, NULL, &lblG);                                                               //JM !! GR
      gtk_fixed_move(GTK_FIXED(grid), lbl41Gr, xPos+KEY_WIDTH_1*4/3, yPos - Y_OFFSET_Aim);  //JM !! GR
      gtk_widget_get_preferred_size(  lbl41Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl41Fa, xPos-KEY_WIDTH_1*0, yPos - Y_OFFSET_Aim);  //^^

      xPos += 2*DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl42F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl42G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl42F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP/2-lblG.width+2)/2-GAP/2, yPos - Y_OFFSET_Aim);           //JMWIDTH MODIFIED FOR EXP, CPX & BASE mod
      gtk_fixed_move(GTK_FIXED(grid), lbl42G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP/2-lblG.width+2)/2-GAP/2, yPos - Y_OFFSET_Aim);           //JMWIDTH MODIFIED FOR EXP, CPX & BASE mod
      gtk_widget_get_preferred_size(  lbl42Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl42Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl42Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl42Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl43F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl43G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl43F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP/2-lblG.width+2)/2, yPos - Y_OFFSET_Aim);                 //JMWIDTH MODIFIED FOR EXP, CPX & BASE mod
      gtk_fixed_move(GTK_FIXED(grid), lbl43G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP/2-lblG.width+2)/2, yPos - Y_OFFSET_Aim);                 //JMWIDTH MODIFIED FOR EXP, CPX & BASE mod
      gtk_widget_get_preferred_size(  lbl43Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl43Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl43Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl43Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl44F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl44G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl44F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP/2-lblG.width+2)/2, yPos - Y_OFFSET_Aim);                 //JMWIDTH MODIFIED FOR EXP, CPX & BASE mod
      gtk_fixed_move(GTK_FIXED(grid), lbl44G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP/2-lblG.width+2)/2, yPos - Y_OFFSET_Aim);                 //JMWIDTH MODIFIED FOR EXP, CPX & BASE mod
      gtk_widget_get_preferred_size(  lbl44Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl44Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl44Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl44Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X;
      gtk_widget_get_preferred_size(  lbl45F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl45G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl45F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl45G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl45Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl45Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;

      if(calcMode != CM_AIM) {
        gtk_widget_get_preferred_size(  lbl51F, NULL, &lblF);
        gtk_widget_get_preferred_size(  lbl51G, NULL, &lblG);
        gtk_fixed_move(GTK_FIXED(grid), lbl51F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);//JM align [f] arrowUp (*0-40)
        gtk_fixed_move(GTK_FIXED(grid), lbl51G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);//JM align [f] arrowUp (*0-40)
      }
      gtk_widget_get_preferred_size(  lbl51Gr, NULL, &lblG); //JMAHOME
      gtk_widget_get_preferred_size(  lbl51Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      //gtk_fixed_move(GTK_FIXED(grid), lbl51Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim); //JMAHOME
      gtk_fixed_move(GTK_FIXED(grid), lbl51Gr, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl51Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_widget_get_preferred_size(  lbl52F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl52G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl52F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl52G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl52Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl52Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl52Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl52Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl53F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl53G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl53F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl53G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl53Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl53Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl53Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl53Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl54F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl54G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl54F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl54G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl54Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl54Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl54Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl54Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl55F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl55G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl55F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl55G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl55Gr, NULL, &lblG);                                                                //JM GREEK
      gtk_fixed_move(GTK_FIXED(grid), lbl55Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);   //JM GREEK
      gtk_widget_get_preferred_size(  lbl55Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl55Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;

      if(calcMode != CM_AIM) {
        gtk_widget_get_preferred_size(  lbl61F, NULL, &lblF);
        gtk_widget_get_preferred_size(  lbl61G, NULL, &lblG);
        gtk_fixed_move(GTK_FIXED(grid), lbl61F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);   //JM align [f] arrowDn (*0-40)
        gtk_fixed_move(GTK_FIXED(grid), lbl61G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);   //JM align [f] arrowDn (*0-40)
      }
      gtk_widget_get_preferred_size(  lbl61Gr, NULL, &lblG); //JMAHOME2                                                                       //JM10
      gtk_widget_get_preferred_size(  lbl61Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      //gtk_fixed_move(GTK_FIXED(grid), lbl61Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);          //JM10
      gtk_fixed_move(GTK_FIXED(grid), lbl61Gr, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);      //JM JMAHOME2 ALPHA BLUE MENU LABELS //^^
      gtk_fixed_move(GTK_FIXED(grid), lbl61Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_widget_get_preferred_size(  lbl62F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl62G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl62F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl62G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl62Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl62Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl62Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl62Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl63F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl63G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl63F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl63G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl63Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl63Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl63Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl63Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl64F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl64G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl64F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl64G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl64Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl64Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl64Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl64Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl65F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl65G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl65F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl65G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl65Gr, NULL, &lblG);                                                                //JM
      gtk_fixed_move(GTK_FIXED(grid), lbl65Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);   //JM
      gtk_widget_get_preferred_size(  lbl65Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl65Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;


      //Not interfering with the dots on the f/g button
      if(calcModel != USER_C47 && calcModel != USER_DM42) {
        if(calcMode != CM_AIM) {
          gtk_widget_get_preferred_size(  lbl71F, NULL, &lblF); //JM REMOVE SHIFT LABELS
          gtk_widget_get_preferred_size(  lbl71G, NULL, &lblG);
          gtk_fixed_move(GTK_FIXED(grid), lbl71F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //Gap removed to cover up fixed squares
          gtk_fixed_move(GTK_FIXED(grid), lbl71G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //Gap removed to cover up fixed squares
        }
        gtk_widget_get_preferred_size(  lbl71Gr, NULL, &lblG);
        gtk_widget_get_preferred_size(  lbl71Fa, NULL, &lblF);                                                                        //vv dr - new AIM
        //gtk_fixed_move(GTK_FIXED(grid), lbl71Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim);
        gtk_fixed_move(GTK_FIXED(grid), lbl71Gr, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);      //JM JMAHOME2 ALPHA BLUE MENU LABELS //^^
        gtk_fixed_move(GTK_FIXED(grid), lbl71Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^
      }

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_widget_get_preferred_size(  lbl72F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl72G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl72F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl72G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl72Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl72Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl72Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl72Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl73F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl73G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl73F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl73G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl73Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl73Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl73Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl73Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl74F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl74G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl74F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl74G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl74Gr, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl74Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl74Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl74Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl75F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl75G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl75F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl75G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl75Gr, NULL, &lblG);                                                                //JM added
      gtk_fixed_move(GTK_FIXED(grid), lbl75Gr, xPos+KEY_WIDTH_2*2/3,                              yPos - Y_OFFSET_Aim);   //JMadded
      gtk_widget_get_preferred_size(  lbl75Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl75Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;
      gtk_widget_get_preferred_size(  lbl81F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl81G, NULL, &lblG);



      //-last one  gtk_fixed_move(GTK_FIXED(grid), lbl81F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      //-last one  gtk_fixed_move(GTK_FIXED(grid), lbl81G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      //JM MANUAL positioning
      //gtk_fixed_move(GTK_FIXED(grid), lbl81F, (2*xPos+KEY_WIDTH_1-22)/2, yPos - Y_OFFSET_Aim);   //JM

      //JMPRT removed for template-  gtk_fixed_move(GTK_FIXED(grid), lbl81G, (2*xPos+KEY_WIDTH_1+lblF.width+2)/2 + 15, yPos + 10);                       //JM
      //gtk_widget_get_preferred_size(  lblOn, NULL, &lblF);                                                          //JM

      gtk_fixed_move(GTK_FIXED(grid), lbl81F, (2*xPos+KEY_WIDTH_1-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl81G, (2*xPos+KEY_WIDTH_1+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      //gtk_fixed_move(GTK_FIXED(grid), lblOn,  (2*xPos+KEY_WIDTH_1+lblF.width+2*GAP-lblG.width+2)/2 -10, yPos - Y_OFFSET_Aim);
      //gtk_fixed_move(GTK_FIXED(grid), lblOn,  (2*xPos+KEY_WIDTH_1-20)/2, yPos + 38);    //JM

      //gtk_widget_get_preferred_size(  lbl81Gr, NULL, &lblG);         //JMPRTA                                                     //JM++_ //JMAPRT
      //gtk_fixed_move(GTK_FIXED(grid), lbl81Gr, xPos+KEY_WIDTH_1*2/3,                              yPos - Y_OFFSET_Aim); //JM ++ //JMAPRT
      //JMPRT removed for template-    gtk_fixed_move(GTK_FIXED(grid), lbl81Gr, (2*xPos+KEY_WIDTH_1+lblF.width+2)/2 + 20, yPos + 10);      //JM JMAPRT ALPHA BLUE MENU LABELS //^^
      //JM^^



      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_widget_get_preferred_size(  lbl82F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl82G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl82F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl82G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl82Gr, NULL, &lblG);                                                                            //JM ALPHA BLUE MENU LABELS
      gtk_widget_get_preferred_size(  lbl82Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      //gtk_fixed_move(GTK_FIXED(grid), lbl82Gr, (2*xPos+KEY_WIDTH_2-GAP-lblG.width+2)/2,           yPos + GAP - Y_OFFSET_Aim); //JM ALPHA BLUE MENU LABELS //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl82Gr, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);      //JM ALPHA BLUE MENU LABELS //^^
      gtk_fixed_move(GTK_FIXED(grid), lbl82Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl83F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl83G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl83F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl83G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl83Gr, NULL, &lblG);                                                                            //JM ALPHA BLUE MENU LABELS
      gtk_widget_get_preferred_size(  lbl83Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      //gtk_fixed_move(GTK_FIXED(grid), lbl83Gr, (2*xPos+KEY_WIDTH_2-GAP-lblG.width+2)/2,           yPos + GAP - Y_OFFSET_Aim); //JM ALPHA BLUE MENU LABELS //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl83Gr, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);      //JM ALPHA BLUE MENU LABELS //^^
      gtk_fixed_move(GTK_FIXED(grid), lbl83Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl84F, NULL, &lblF);
      gtk_widget_get_preferred_size(  lbl84G, NULL, &lblG);
      gtk_fixed_move(GTK_FIXED(grid), lbl84F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_fixed_move(GTK_FIXED(grid), lbl84G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);
      gtk_widget_get_preferred_size(  lbl84Gr, NULL, &lblG);                                                                            //JM ALPHA BLUE MENU LABELS
      gtk_widget_get_preferred_size(  lbl84Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      //gtk_fixed_move(GTK_FIXED(grid), lbl84Gr, (2*xPos+KEY_WIDTH_2-GAP-lblG.width+2)/2,           yPos + GAP - Y_OFFSET_Aim); //JM ALPHA BLUE MENU LABELS //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl84Gr, (2*xPos+KEY_WIDTH_2+lblF.width+GAP*4-lblG.width+2)/2, yPos - Y_OFFSET_Aim);      //JM ALPHA BLUE MENU LABELS //^^              //JM MANUAL GAP ADJUSTMENT TO 4x
      gtk_fixed_move(GTK_FIXED(grid), lbl84Fa, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_widget_get_preferred_size(  lbl85F, NULL, &lblF);
      //gtk_fixed_move(GTK_FIXED(grid), lbl85F, (2*xPos+KEY_WIDTH_2-lblF.width+2)/2, yPos - Y_OFFSET_Aim); //JM

      //gtk_widget_get_preferred_size(  lblOn,  NULL, &lblF); //JM
      gtk_widget_get_preferred_size(  lbl85G, NULL, &lblG);

      gtk_fixed_move(GTK_FIXED(grid), lbl85F, (2*xPos+KEY_WIDTH_2-lblF.width-GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim); //JM
      gtk_fixed_move(GTK_FIXED(grid), lbl85G, (2*xPos+KEY_WIDTH_2+lblF.width+GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim); //JM
      gtk_widget_get_preferred_size(  lbl85Gr, NULL, &lblG);                                                                              //JM ALPHA BLUE MENU LABELS
      gtk_widget_get_preferred_size(  lbl85Fa, NULL, &lblF);                                                                        //vv dr - new AIM
      //gtk_fixed_move(GTK_FIXED(grid), lbl85Gr, (2*xPos+KEY_WIDTH_2-GAP-lblG.width+2)/2,           yPos + GAP - Y_OFFSET_Aim);   //JM ALPHA BLUE MENU LABELS //vv dr - new AIM
      gtk_fixed_move(GTK_FIXED(grid), lbl85Gr, (2*xPos+KEY_WIDTH_2+lblF.width+2*GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);        //JM ALPHA BLUE MENU LABELS //^^
      gtk_fixed_move(GTK_FIXED(grid), lbl85Fa, (2*xPos+KEY_WIDTH_2-lblF.width-2*GAP-lblG.width+2)/2, yPos - Y_OFFSET_Aim);  //^^

    }


// Function to get button name from widget pointer
const char* get_button_name(GtkWidget* widget) {
    if(!widget) return "NULL";

    // Row 1 buttons
    if(widget == btn11) return "btn11";
    if(widget == btn12) return "btn12";
    if(widget == btn13) return "btn13";
    if(widget == btn14) return "btn14";
    if(widget == btn15) return "btn15";
    if(widget == btn16) return "btn16";

    // Row 2 buttons and labels
    if(widget == btn21) return "btn21";
    if(widget == btn22) return "btn22";
    if(widget == btn23) return "btn23";
    if(widget == btn24) return "btn24";
    if(widget == btn25) return "btn25";
    if(widget == btn26) return "btn26";
    if(widget == btn21A) return "btn21A";
    if(widget == btn22A) return "btn22A";
    if(widget == btn23A) return "btn23A";
    if(widget == btn24A) return "btn24A";
    if(widget == btn25A) return "btn25A";
    if(widget == btn26A) return "btn26A";
    if(widget == lbl21F) return "lbl21F";
    if(widget == lbl22F) return "lbl22F";
    if(widget == lbl23F) return "lbl23F";
    if(widget == lbl24F) return "lbl24F";
    if(widget == lbl25F) return "lbl25F";
    if(widget == lbl26F) return "lbl26F";
    if(widget == lbl21G) return "lbl21G";
    if(widget == lbl22G) return "lbl22G";
    if(widget == lbl23G) return "lbl23G";
    if(widget == lbl24G) return "lbl24G";
    if(widget == lbl25G) return "lbl25G";
    if(widget == lbl26G) return "lbl26G";
    if(widget == lbl21L) return "lbl21L";
    if(widget == lbl22L) return "lbl22L";
    if(widget == lbl23L) return "lbl23L";
    if(widget == lbl24L) return "lbl24L";
    if(widget == lbl25L) return "lbl25L";
    if(widget == lbl26L) return "lbl26L";
    if(widget == lbl21Gr) return "lbl21Gr";
    if(widget == lbl22Gr) return "lbl22Gr";
    if(widget == lbl23Gr) return "lbl23Gr";
    if(widget == lbl24Gr) return "lbl24Gr";
    if(widget == lbl25Gr) return "lbl25Gr";
    if(widget == lbl26Gr) return "lbl26Gr";
    if(widget == lbl21Fa) return "lbl21Fa";
    if(widget == lbl22Fa) return "lbl22Fa";
    if(widget == lbl23Fa) return "lbl23Fa";
    if(widget == lbl24Fa) return "lbl24Fa";
    if(widget == lbl25Fa) return "lbl25Fa";
    if(widget == lbl26Fa) return "lbl26Fa";

    // Row 3 buttons and labels
    if(widget == btn31) return "btn31";
    if(widget == btn32) return "btn32";
    if(widget == btn33) return "btn33";
    if(widget == btn34) return "btn34";
    if(widget == btn35) return "btn35";
    if(widget == btn36) return "btn36";
    if(widget == btn31A) return "btn31A";
    if(widget == btn32A) return "btn32A";
    if(widget == btn33A) return "btn33A";
    if(widget == btn34A) return "btn34A";
    if(widget == btn35A) return "btn35A";
    if(widget == btn36A) return "btn36A";
    if(widget == lbl31F) return "lbl31F";
    if(widget == lbl32F) return "lbl32F";
    if(widget == lbl33F) return "lbl33F";
    if(widget == lbl34F) return "lbl34F";
    if(widget == lbl35F) return "lbl35F";
    if(widget == lbl36F) return "lbl36F";
    if(widget == lbl31G) return "lbl31G";
    if(widget == lbl32G) return "lbl32G";
    if(widget == lbl33G) return "lbl33G";
    if(widget == lbl34G) return "lbl34G";
    if(widget == lbl35G) return "lbl35G";
    if(widget == lbl36G) return "lbl36G";
    if(widget == lbl31L) return "lbl31L";
    if(widget == lbl32L) return "lbl32L";
    if(widget == lbl33L) return "lbl33L";
    if(widget == lbl34L) return "lbl34L";
    if(widget == lbl35L) return "lbl35L";
    if(widget == lbl36L) return "lbl36L";
    if(widget == lbl31Gr) return "lbl31Gr";
    if(widget == lbl32Gr) return "lbl32Gr";
    if(widget == lbl33Gr) return "lbl33Gr";
    if(widget == lbl34Gr) return "lbl34Gr";
    if(widget == lbl35Gr) return "lbl35Gr";
    if(widget == lbl36Gr) return "lbl36Gr";
    if(widget == lbl31Fa) return "lbl31Fa";
    if(widget == lbl32Fa) return "lbl32Fa";
    if(widget == lbl33Fa) return "lbl33Fa";
    if(widget == lbl34Fa) return "lbl34Fa";
    if(widget == lbl35Fa) return "lbl35Fa";
    if(widget == lbl36Fa) return "lbl36Fa";

    // Row 4 buttons and labels
    if(widget == btn41) return "btn41";
    if(widget == btn42) return "btn42";
    if(widget == btn43) return "btn43";
    if(widget == btn44) return "btn44";
    if(widget == btn45) return "btn45";
    if(widget == btn42A) return "btn42A";
    if(widget == btn43A) return "btn43A";
    if(widget == btn44A) return "btn44A";
    if(widget == lbl41F) return "lbl41F";
    if(widget == lbl42F) return "lbl42F";
    if(widget == lbl43F) return "lbl43F";
    if(widget == lbl44F) return "lbl44F";
    if(widget == lbl45F) return "lbl45F";
    if(widget == lbl41G) return "lbl41G";
    if(widget == lbl42G) return "lbl42G";
    if(widget == lbl43G) return "lbl43G";
    if(widget == lbl44G) return "lbl44G";
    if(widget == lbl45G) return "lbl45G";
    if(widget == lbl41L) return "lbl41L";
    if(widget == lbl42L) return "lbl42L";
    if(widget == lbl43L) return "lbl43L";
    if(widget == lbl44L) return "lbl44L";
    if(widget == lbl45L) return "lbl45L";
    if(widget == lbl41Gr) return "lbl41Gr";
    if(widget == lbl42Gr) return "lbl42Gr";
    if(widget == lbl43Gr) return "lbl43Gr";
    if(widget == lbl44Gr) return "lbl44Gr";
    if(widget == lbl45Gr) return "lbl45Gr";
    if(widget == lbl41Fa) return "lbl41Fa";
    if(widget == lbl42Fa) return "lbl42Fa";
    if(widget == lbl43Fa) return "lbl43Fa";
    if(widget == lbl44Fa) return "lbl44Fa";
    if(widget == lbl45Fa) return "lbl45Fa";

    // Row 5 buttons and labels
    if(widget == btn51) return "btn51";
    if(widget == btn52) return "btn52";
    if(widget == btn53) return "btn53";
    if(widget == btn54) return "btn54";
    if(widget == btn55) return "btn55";
    if(widget == btn52A) return "btn52A";
    if(widget == btn53A) return "btn53A";
    if(widget == btn54A) return "btn54A";
    if(widget == btn55A) return "btn55A";
    if(widget == lbl51F) return "lbl51F";
    if(widget == lbl52F) return "lbl52F";
    if(widget == lbl53F) return "lbl53F";
    if(widget == lbl54F) return "lbl54F";
    if(widget == lbl55F) return "lbl55F";
    if(widget == lbl51G) return "lbl51G";
    if(widget == lbl52G) return "lbl52G";
    if(widget == lbl53G) return "lbl53G";
    if(widget == lbl54G) return "lbl54G";
    if(widget == lbl55G) return "lbl55G";
    if(widget == lbl51L) return "lbl51L";
    if(widget == lbl52L) return "lbl52L";
    if(widget == lbl53L) return "lbl53L";
    if(widget == lbl54L) return "lbl54L";
    if(widget == lbl55L) return "lbl55L";
    if(widget == lbl51Gr) return "lbl51Gr";
    if(widget == lbl52Gr) return "lbl52Gr";
    if(widget == lbl53Gr) return "lbl53Gr";
    if(widget == lbl54Gr) return "lbl54Gr";
    if(widget == lbl55Gr) return "lbl55Gr";
    if(widget == lbl51Fa) return "lbl51Fa";
    if(widget == lbl52Fa) return "lbl52Fa";
    if(widget == lbl53Fa) return "lbl53Fa";
    if(widget == lbl54Fa) return "lbl54Fa";
    if(widget == lbl55Fa) return "lbl55Fa";

    // Row 6 buttons and labels
    if(widget == btn61) return "btn61";
    if(widget == btn62) return "btn62";
    if(widget == btn63) return "btn63";
    if(widget == btn64) return "btn64";
    if(widget == btn65) return "btn65";
    if(widget == btn62A) return "btn62A";
    if(widget == btn63A) return "btn63A";
    if(widget == btn64A) return "btn64A";
    if(widget == btn65A) return "btn65A";
    if(widget == lbl61F) return "lbl61F";
    if(widget == lbl62F) return "lbl62F";
    if(widget == lbl63F) return "lbl63F";
    if(widget == lbl64F) return "lbl64F";
    if(widget == lbl65F) return "lbl65F";
    if(widget == lbl61G) return "lbl61G";
    if(widget == lbl62G) return "lbl62G";
    if(widget == lbl63G) return "lbl63G";
    if(widget == lbl64G) return "lbl64G";
    if(widget == lbl65G) return "lbl65G";
    if(widget == lbl61L) return "lbl61L";
    if(widget == lbl62L) return "lbl62L";
    if(widget == lbl63L) return "lbl63L";
    if(widget == lbl64L) return "lbl64L";
    if(widget == lbl65L) return "lbl65L";
    if(widget == lbl61Gr) return "lbl61Gr";
    if(widget == lbl62Gr) return "lbl62Gr";
    if(widget == lbl63Gr) return "lbl63Gr";
    if(widget == lbl64Gr) return "lbl64Gr";
    if(widget == lbl65Gr) return "lbl65Gr";
    if(widget == lbl61Fa) return "lbl61Fa";
    if(widget == lbl62Fa) return "lbl62Fa";
    if(widget == lbl63Fa) return "lbl63Fa";
    if(widget == lbl64Fa) return "lbl64Fa";
    if(widget == lbl65Fa) return "lbl65Fa";

    // Row 7 buttons and labels
    if(widget == btn71) return "btn71";
    if(widget == btn72) return "btn72";
    if(widget == btn73) return "btn73";
    if(widget == btn74) return "btn74";
    if(widget == btn75) return "btn75";
    if(widget == btn71A) return "btn71A";
    if(widget == btn72A) return "btn72A";
    if(widget == btn73A) return "btn73A";
    if(widget == btn74A) return "btn74A";
    if(widget == btn75A) return "btn75A";
    if(widget == lbl71F) return "lbl71F";
    if(widget == lbl72F) return "lbl72F";
    if(widget == lbl73F) return "lbl73F";
    if(widget == lbl74F) return "lbl74F";
    if(widget == lbl75F) return "lbl75F";
    if(widget == lbl71G) return "lbl71G";
    if(widget == lbl72G) return "lbl72G";
    if(widget == lbl73G) return "lbl73G";
    if(widget == lbl74G) return "lbl74G";
    if(widget == lbl75G) return "lbl75G";
    if(widget == lbl71L) return "lbl71L";
    if(widget == lbl72L) return "lbl72L";
    if(widget == lbl73L) return "lbl73L";
    if(widget == lbl74L) return "lbl74L";
    if(widget == lbl75L) return "lbl75L";
    if(widget == lbl71Gr) return "lbl71Gr";
    if(widget == lbl72Gr) return "lbl72Gr";
    if(widget == lbl73Gr) return "lbl73Gr";
    if(widget == lbl74Gr) return "lbl74Gr";
    if(widget == lbl75Gr) return "lbl75Gr";
    if(widget == lbl71Fa) return "lbl71Fa";
    if(widget == lbl72Fa) return "lbl72Fa";
    if(widget == lbl73Fa) return "lbl73Fa";
    if(widget == lbl74Fa) return "lbl74Fa";
    if(widget == lbl75Fa) return "lbl75Fa";

    // Row 8 buttons and labels
    if(widget == btn81) return "btn81";
    if(widget == btn82) return "btn82";
    if(widget == btn83) return "btn83";
    if(widget == btn84) return "btn84";
    if(widget == btn85) return "btn85";
    if(widget == btn82A) return "btn82A";
    if(widget == btn83A) return "btn83A";
    if(widget == btn84A) return "btn84A";
    if(widget == btn85A) return "btn85A";
    if(widget == lbl81F) return "lbl81F";
    if(widget == lbl82F) return "lbl82F";
    if(widget == lbl83F) return "lbl83F";
    if(widget == lbl84F) return "lbl84F";
    if(widget == lbl85F) return "lbl85F";
    if(widget == lbl81G) return "lbl81G";
    if(widget == lbl82G) return "lbl82G";
    if(widget == lbl83G) return "lbl83G";
    if(widget == lbl84G) return "lbl84G";
    if(widget == lbl85G) return "lbl85G";
    if(widget == lbl81L) return "lbl81L";
    if(widget == lbl82L) return "lbl82L";
    if(widget == lbl83L) return "lbl83L";
    if(widget == lbl84L) return "lbl84L";
    if(widget == lbl85L) return "lbl85L";
    if(widget == lbl81Gr) return "lbl81Gr";
    if(widget == lbl82Gr) return "lbl82Gr";
    if(widget == lbl83Gr) return "lbl83Gr";
    if(widget == lbl84Gr) return "lbl84Gr";
    if(widget == lbl85Gr) return "lbl85Gr";
    if(widget == lbl82Fa) return "lbl82Fa";
    if(widget == lbl83Fa) return "lbl83Fa";
    if(widget == lbl84Fa) return "lbl84Fa";
    if(widget == lbl85Fa) return "lbl85Fa";

    return "UNKNOWN_WIDGET";
}



//----------------------------------------------------------------------------------
static void print_label_bytes(const uint8_t* data, int length) {
  for(int i = 0; i < length; i++) {
    printf("0x%02x ", data[i]);
  }
  printf("(");
  for(int i = 0; i < length; i++) {
    printf("%c", (data[i] >= 32 && data[i] < 127) ? data[i] : '.');
  }
  printf("  dec: ");
  for(int i = 0; i < length; i++) {
    printf("%03d ", data[i]);
  }
  printf(")\n");
}

static bool is_valid_utf8(const char *s, size_t *error_offset);


bool_t check_label_consistency(const uint8_t* lbl, const char* context) {
    if (!lbl) {
        printf("GTK3 Setup utf issue: NULL label in %s\n", context);
        return 1;
    }

    // Calculate length safely (stop at 22 or null terminator)
    int len = 0;
    while (lbl[len] != 0 && len < 22) {
        len++;
    }

    if (len == 0) {
        return 0; // Empty string is OK
    }

    size_t bad_pos = 0;
    if (!is_valid_utf8((const char*)lbl, &bad_pos)) {
        printf("GTK3 Setup utf issue: Invalid UTF-8 at position %zu in %s: ",
               bad_pos, context);
        print_label_bytes(lbl, len);
        return 1;
    }

    return 0; // All good
}


//----------------------------------------------------------------------------------


bool debugLabelConsistency(const uint8_t *lbl, const char *ctx, const calcKey_t *key, GtkWidget *btn, bool showBtn) {
  if(!check_label_consistency(lbl,ctx)) {
    return false;
  }
  if(key) {
    print_label_bytes(lbl,16);
    if(showBtn&&btn)printf("     : key details - btn:=%s\n",get_button_name(btn));
    printf("       key->primaryAim = %d ",key->primaryAim);
    printStringToConsole(indexOfItems[key->primaryAim].itemSoftmenuName,"...itemSoftmenuName ="," ");
    printStringToConsole(indexOfItems[key->primaryAim].itemSoftmenuName,"primaryAim AA:","\n");
    printf("       key->fShiftedAim = %d ",key->fShiftedAim);
    printStringToConsole(indexOfItems[key->fShiftedAim].itemSoftmenuName,"...itemSoftmenuName ="," ");
    printStringToConsole(indexOfItems[key->fShiftedAim].itemSoftmenuName,"fShiftedAim AA:","\n");
    printf("       key->gShiftedAim = %d ",key->gShiftedAim);
    printStringToConsole(indexOfItems[key->gShiftedAim].itemSoftmenuName,"...itemSoftmenuName ="," ");
    printStringToConsole(indexOfItems[key->gShiftedAim].itemSoftmenuName,"gShiftedAim AA:","\n\n");
  }
  return true;
}



void labelCaptionNormal(const calcKey_t *key, GtkWidget *button, GtkWidget *lblF, GtkWidget *lblG, GtkWidget *lblL) {
  uint8_t lbl[22];
  int16_t keyLogicalId;

  if(key->keyId < 30) {
    keyLogicalId = key->keyId -21;
  }
  else if(key->keyId < 40) {
    keyLogicalId = key->keyId -25;
  }
  else if(key->keyId < 50) {
    keyLogicalId = key->keyId -29;
  }
  else if(key->keyId < 60) {
    keyLogicalId = key->keyId -34;
  }
  else if(key->keyId < 70) {
    keyLogicalId = key->keyId -39;
  }
  else if(key->keyId < 80) {
    keyLogicalId = key->keyId -44;
  }
  else {
    keyLogicalId = key->keyId -49;
  }

  bool_t R47LongpressColour = false;


  if(key->primary == 0) {
    lbl[0] = 0;
  }
  else {
    //stringToUtf8(indexOfItems[max(key->primary, -key->primary)].itemSoftmenuName, lbl);
    char sstmp[16];
    strcpy(sstmp, indexOfItems[max(key->primary, -key->primary)].itemSoftmenuName);
    if((key->primary == ITM_op_j || key->primary == ITM_op_j_pol) && getSystemFlag(FLAG_CPXj)) sstmp[1]++;
    if(key->primary == ITM_EE_EXP_TH && getSystemFlag(FLAG_CPXj)) sstmp[3]++;
    stringToUtf8(sstmp, lbl);
    if((userKeyLabelSize > 0) && ((strcmp((char *)lbl, "DYNMNU") == 0) || (strcmp((char *)lbl, "XEQ") == 0) || (strcmp((char *)lbl, "RCL") == 0))) {
      if(*(getNthString((uint8_t *)userKeyLabel, keyLogicalId*6)) != 0) {
        stringToUtf8((char *)getNthString((uint8_t *)userKeyLabel, keyLogicalId*6),lbl);
      }
    }
  }

      bool_t Norm_Key_00_used = ((calcMode == CM_NORMAL || calcMode == CM_NIM || calcMode == CM_PEM || calcMode == CM_TIMER )
                                  && key->keyId == Norm_Key_00_keyID
                                  && Norm_Key_00.func != Norm_Key_00_item_in_layout
                                  && !getSystemFlag(FLAG_USER)
                                  );

      if(Norm_Key_00_used) {                                       //Sigma+NRM: JChange the name inside the Sigma+ button; allow USER mode, but override the USER setting for Sigma+, except for shiftg which is not overriden
        //stringToUtf8(indexOfItems[max(Norm_Key_00_VAR, -Norm_Key_00_VAR)].itemSoftmenuName, lbl);
        char sstmp[16];
        if((Norm_Key_00.funcParam[0] != 0) && ((Norm_Key_00.func == -MNU_DYNAMIC) || (Norm_Key_00.func == ITM_XEQ) || (Norm_Key_00.func == ITM_RCL)))  {
          strcpy(sstmp, (char *)&Norm_Key_00.funcParam);       // name of a user menu, program or variable assigned to the Norm key
        }
        else {
          strcpy(sstmp, indexOfItems[max(Norm_Key_00.func, -Norm_Key_00.func)].itemSoftmenuName);
          if((Norm_Key_00.func == ITM_op_j || Norm_Key_00.func == ITM_op_j_pol) && getSystemFlag(FLAG_CPXj)) sstmp[1]++;
          if(Norm_Key_00.func == ITM_EE_EXP_TH && getSystemFlag(FLAG_CPXj)) sstmp[3]++;
        }
        stringToUtf8(sstmp, lbl);
      }

      gtk_button_set_label(GTK_BUTTON(button), (gchar *)lbl);
      //printf("--THIS IS NORMAL mode primary-position:   %s\n",lbl);

      //if(strcmp((char *)lbl, "/") == 0 && key->keyId == 55) {    //JM if "/", re-do to "÷". Presumed easier than to fix the UTf8 conversion above.
      //  gtk_button_set_label(GTK_BUTTON(button), "÷");           //JM DIV
      //}                                                          //JM

      if((key->primary == ITM_AIM && getSystemFlag(FLAG_USER) && calcMode == CM_NORMAL && key->keyId == Norm_Key_00_keyID) ||                       //Sigma+NRM: Colour the alpha key gold if assigned.
        (key->primary == Norm_Key_00_item_in_layout && calcMode == CM_NORMAL && Norm_Key_00.func == ITM_AIM && key->keyId == Norm_Key_00_keyID)) {
        gtk_widget_set_name(button, "AlphaKey");
      }
      else if(key->primary == ITM_SHIFTf  || (key->primary == Norm_Key_00_item_in_layout && Norm_Key_00.func == ITM_SHIFTf && key->keyId == Norm_Key_00_keyID) ) { //Sigma+NRM: Colour the shiftf key yellow if assigned.
        gtk_widget_set_name(button, "calcKeyF");
      }
      else if(key->primary == ITM_SHIFTg  || (key->primary == Norm_Key_00_item_in_layout && Norm_Key_00.func == ITM_SHIFTg && key->keyId == Norm_Key_00_keyID) ) { //Sigma+NRM: Colour the shiftg key blue if assigned.
        gtk_widget_set_name(button, "calcKeyG");
      }
      else if(key->primary == KEY_fg  || (key->primary == Norm_Key_00_item_in_layout && Norm_Key_00.func == KEY_fg && key->keyId == Norm_Key_00_keyID) ) { //Sigma+NRM: Colour the shiftfg key yellow if assigned.
        gtk_widget_set_name(button, "calcKeyFG");
      }
      else if((key->primary >= ITM_0 && key->primary <= ITM_9) || key->primary == ITM_PERIOD) {
        gtk_widget_set_name(button, "calcNumericKey");
      }
      else if(strcmp((char *)lbl, "÷") == 0 && key->keyId == 55) {      //JM increase the font size of the operators to the numeric key size
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else if(strcmp((char *)lbl, "×") == 0 && key->keyId == 65) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else if(strcmp((char *)lbl, "-") == 0 && key->keyId == 75) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else if(strcmp((char *)lbl, "+") == 0 && key->keyId == 85) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else {
        gtk_widget_set_name(button, "calcKey");
      }
char sstmp[16];

//  stringToUtf8(indexOfItems[max(key->fShifted, -key->fShifted)].itemSoftmenuName, lbl);
  if(key->fShifted == 0) {
      sstmp[0] = 0;
  }
  else {
    strcpy(sstmp, indexOfItems[max(key->fShifted, -key->fShifted)].itemSoftmenuName);
  }

  if((key->fShifted == ITM_op_j || key->fShifted == ITM_op_j_pol) && getSystemFlag(FLAG_CPXj)) sstmp[1]++;
  if(key->fShifted == ITM_EE_EXP_TH && getSystemFlag(FLAG_CPXj)) sstmp[3]++;
  stringToUtf8(sstmp, lbl);
  if((userKeyLabelSize > 0) && ((strcmp((char *)lbl, "DYNMNU") == 0) || (strcmp((char *)lbl, "XEQ") == 0) || (strcmp((char *)lbl, "RCL") == 0))) {
    if(*(getNthString((uint8_t *)userKeyLabel, keyLogicalId*6+1)) != 0) {
      stringToUtf8((char *)getNthString((uint8_t *)userKeyLabel, keyLogicalId*6+1),lbl);
    }
  }

  if(strcmp((char *)lbl, "SST") == 0) {
      char tt[20];
      strcpy(tt, STD_HAMBURGER);
      strcat(tt, isR47FAM ? STD_DOWN_BLOCKARROW : STD_SST);
      stringToUtf8(tt, lbl);
  } else
  if(strcmp((char *)lbl, "BST") == 0) {
      char tt[20];
      strcpy(tt, STD_HAMBURGER);
      strcat(tt, isR47FAM ? STD_UP_BLOCKARROW : STD_BST);
      stringToUtf8(tt, lbl);
  }

  if(key->primary == ITM_SHIFTg && key->keyId == 71) {
    strcpy((char *)lbl,"      "); //blank the dots above the shift g key, if it is shift g specifically instead of shift f/g
  }

  gtk_label_set_label(GTK_LABEL(lblF), (gchar *)lbl);
  //printf("--THIS IS f-shifted:               %s\n",lbl);

  if(R47LongpressColour) {
    gtk_widget_set_name(lblF, "letter");
  }
  else if(key->fShifted < 0) {
    gtk_widget_set_name(lblF, "fShiftedUnderline");
  }
  else {
    gtk_widget_set_name(lblF, "fShifted");
  }

//  if(key->gShifted == ITM_op_j) strcpy((char *)lbl, getSystemFlag(FLAG_CPXj)   ? "j"  : "i");
//  else
  if(isR47FAM && (key->primary == ITM_SHIFTf)) {
    if(key->gShifted == ITM_NULL) {
      strcpy(sstmp, indexOfItems[MNU_HOME].itemSoftmenuName);
    }
    else {
      strcpy(sstmp, indexOfItems[max(key->gShifted, -key->gShifted)].itemSoftmenuName);
    }
    R47LongpressColour = true;
  }
  else if(isR47FAM && key->primary == ITM_SHIFTg) {
    if(key->gShifted == ITM_NULL) {
      strcpy(sstmp, indexOfItems[MNU_MyMenu].itemSoftmenuName);
    }
    else {
      strcpy(sstmp, indexOfItems[max(key->gShifted, -key->gShifted)].itemSoftmenuName);
    }
    R47LongpressColour = true;
  }
  else if(isR47FAM && key->primary == KEY_fg) {
    if(getSystemFlag(FLAG_HOME_TRIPLE) || getSystemFlag(FLAG_MYM_TRIPLE)) {
      if(key->gShifted == ITM_NULL) {
        if(getSystemFlag(FLAG_HOME_TRIPLE)) {
          strcpy(sstmp, indexOfItems[MNU_HOME].itemSoftmenuName);
        }
        else if (getSystemFlag(FLAG_MYM_TRIPLE)) {
          strcpy(sstmp, indexOfItems[MNU_MyMenu].itemSoftmenuName);
        }
      }
      else {
        strcpy(sstmp, indexOfItems[max(key->gShifted, -key->gShifted)].itemSoftmenuName);
      }
    }
    else {
      sstmp[0] = 0;
    }
    R47LongpressColour = true;
  }
  else if(key->gShifted == 0) {
    lbl[0] = 0;
  }
  else {
    strcpy(sstmp, indexOfItems[max(key->gShifted, -key->gShifted)].itemSoftmenuName);
  }

  if((key->gShifted == ITM_op_j || key->gShifted == ITM_op_j_pol) && getSystemFlag(FLAG_CPXj)) sstmp[1]++;
  if(key->gShifted == ITM_EE_EXP_TH && getSystemFlag(FLAG_CPXj)) sstmp[3]++;
  stringToUtf8(sstmp, lbl);
  if((userKeyLabelSize > 0) && ((strcmp((char *)lbl, "DYNMNU") == 0) || (strcmp((char *)lbl, "XEQ") == 0) || (strcmp((char *)lbl, "RCL") == 0))) {
    if(*(getNthString((uint8_t *)userKeyLabel, keyLogicalId*6+2)) != 0) {
      stringToUtf8((char *)getNthString((uint8_t *)userKeyLabel, keyLogicalId*6+2),lbl);
    }
  }

  if(strcmp((char *)lbl, "MODE#") == 0 && key->keyId == 22) {
    strcpy((char *)lbl,"#");
  }
  else if(strcmp((char *)lbl, "LINPOL") == 0) {
    strcpy((char *)lbl,"LIN");
  }

  gtk_label_set_label(GTK_LABEL(lblG), (gchar *)lbl);

  if(R47LongpressColour) {
    gtk_widget_set_name(lblG, "letter");
  }
  else if(key->gShifted < 0 /*|| key->gShifted == ITM_TIMER*/) {
    gtk_widget_set_name(lblG, "gShiftedUnderline");
  }
  else {
    gtk_widget_set_name(lblG, "gShifted");
  }

  stringToUtf8(indexOfItems[key->primaryAim].itemSoftmenuName, lbl);
  if(key->primaryAim == 0) {
     lbl[0] = 0;
  }

  if(lbl[0] == 32 && lbl[1] == 0) {     //JM SPACE |  OPEN BOX 9251,  0xE2 0x90 0xA3  |  0xE2 0x90 0xA0 for SP.
    lbl[0]=0xC2;          //JM SPACE the space character is not in the font. \rather use . . for space.
    lbl[1]=0xB7;          //JM SPACE
    lbl[2]='_';           //JM SPACE
    lbl[3]=0xc2;          //JM SPACE
    lbl[4]=0xb7;          //JM SPACE
    lbl[5]=0;             //JM SPACE
  }                       //JM SPACE

  if(debugLabelConsistency(lbl, "Normal", key, button, true)) return;
  gtk_label_set_label(GTK_LABEL(lblL), (gchar *)lbl);
  gtk_widget_set_name(lblL, "letter");
}


    //dr
    void labelCaptionAimFa(const calcKey_t* key, GtkWidget* lblF) {
      uint8_t lbl[22];
      bool_t R47LongpressColour = false;

      if(key->primaryAim == ITM_NULL) {
        lbl[0] = 0;
      }
      else if(isR47FAM && key->fShiftedAim == ITM_NULL && key->primaryAim == ITM_SHIFTf) {
        if(tam.alpha) {
          stringToUtf8(indexOfItems[MNU_TAMALPHA].itemSoftmenuName, lbl);
        }
        else {
          stringToUtf8(indexOfItems[MNU_ALPHA].itemSoftmenuName, lbl);
        }
        R47LongpressColour = true;
      }
      else if(isR47FAM && key->fShiftedAim == ITM_NULL && key->primaryAim == ITM_SHIFTg) {
        stringToUtf8(indexOfItems[MNU_MyAlpha].itemSoftmenuName, lbl);
        R47LongpressColour = true;
      }
      else if(isR47FAM && key->primaryAim == KEY_fg) {
        if(getSystemFlag(FLAG_HOME_TRIPLE)) {
          if(tam.alpha) {
            stringToUtf8(indexOfItems[MNU_TAMALPHA].itemSoftmenuName, lbl);
          }
          else {
            stringToUtf8(indexOfItems[MNU_ALPHA].itemSoftmenuName, lbl);
          }
        }
        else if(getSystemFlag(FLAG_MYM_TRIPLE)) {
          stringToUtf8(indexOfItems[MNU_MyAlpha].itemSoftmenuName, lbl);
        }
        else {
          lbl[0] = 0;
        }
        R47LongpressColour = true;
      }
      else {
          stringToUtf8(indexOfItems[numlockReplacements(4,max(key->fShiftedAim, -key->fShiftedAim),getSystemFlag(FLAG_NUMLOCK),true,false)].itemSoftmenuName, lbl);
      }

      if(lbl[0] == 32 && lbl[1]==0) {
        lbl[0]=0xC2;          //JM SPACE the space character is not in the font. \rather use . . for space.
        lbl[1]=0xB7;          //JM SPACE
        lbl[2]='_';           //JM SPACE
        lbl[3]=0xc2;          //JM SPACE
        lbl[4]=0xb7;          //JM SPACE
        lbl[5]=0;             //JM SPACE
      }
      else if(key->fShiftedAim == CHR_caseUP || key->fShiftedAim == CHR_caseDN) {
        lbl[5] = 0;
      }

      if(debugLabelConsistency(lbl, "labelCaptionAimFa", key, NULL, false)) return;
      gtk_label_set_label(GTK_LABEL(lblF), (gchar*)lbl);
      if(R47LongpressColour) {
        gtk_widget_set_name(lblF, "letter");
      }
      else if(key->primary < 0) {
        gtk_widget_set_name(lblF, "fShiftedUnderline");
      }
      else {
        gtk_widget_set_name(lblF, "fShifted");
      }
    }




    void labelCaptionAim(const calcKey_t *key, GtkWidget *button, GtkWidget *lblG, GtkWidget *lblL) {
      uint8_t lbl[22];

      if(key->keyLblAim == ITM_SHIFTf) {
        strcpy((char *)lbl, indexOfItems[ITM_SHIFTf].itemSoftmenuName);
      }
      else if(key->keyLblAim == ITM_SHIFTg) {
        strcpy((char *)lbl, indexOfItems[ITM_SHIFTg].itemSoftmenuName);
      }
      else if(key->keyLblAim == KEY_fg) {
        strcpy((char *)lbl, indexOfItems[KEY_fg].itemSoftmenuName);
      }
      else if(key->primaryAim == ITM_NULL || key->gShiftedAim == ITM_NULL) {
        lbl[0] = 0;
      }
      else {
        if( shiftG && (ITM_A <= key->primaryAim && key->primaryAim <= ITM_Z)) {
          stringToUtf8(indexOfItems[numlockReplacements(5,max(key->gShiftedAim, -key->gShiftedAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG)].itemSoftmenuName, lbl);
        }
        else {
          if( ((!shiftF && (alphaCase == AC_LOWER)) || ( shiftF && (alphaCase == AC_UPPER))) && (ITM_A <= key->primaryAim && key->primaryAim <= ITM_Z)) {
            stringToUtf8(indexOfItems[numlockReplacements(5,max(key->primaryAim, -key->primaryAim) + 26, getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG)].itemSoftmenuName, lbl);
          }
          else {
            if(shiftF) stringToUtf8(indexOfItems[numlockReplacements(6,max(key->fShiftedAim, -key->fShiftedAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG)].itemSoftmenuName, lbl); else
            if(shiftG) stringToUtf8(indexOfItems[numlockReplacements(6,max(key->gShiftedAim, -key->gShiftedAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG)].itemSoftmenuName, lbl); else
            stringToUtf8(indexOfItems[numlockReplacements(6,max(key->primaryAim, -key->primaryAim), getSystemFlag(FLAG_NUMLOCK), shiftF, shiftG)].itemSoftmenuName, lbl);
          }
        }
      }
      //printf("####B^^ %d %d %d %d %u %s\n", numLock, shiftF,shiftG,calcMode==CM_AIM, lbl[0], (gchar*)lbl);
      if(lbl[0] == 32 && lbl[1]==0) {
        lbl[0]=0xC2;          //JM SPACE the space character is not in the font. \rather use . . for space.
        lbl[1]=0xB7;          //JM SPACE
        lbl[2]='_';           //JM SPACE
        lbl[3]=0xc2;          //JM SPACE
        lbl[4]=0xb7;          //JM SPACE
        lbl[5]=0;             //JM SPACE
      }

      gtk_button_set_label(GTK_BUTTON(button), (gchar *)lbl);
      //printf("--THIS IS AIM primary face:               %s\n",lbl);

      //Specify the different categories of coloured zones
      if(key->keyLblAim == ITM_SHIFTf) {
        gtk_widget_set_name(button, "calcKeyF");
      }
      else if(key->keyLblAim == ITM_SHIFTg) {
        gtk_widget_set_name(button, "calcKeyG");
      }
      else if(key->keyLblAim == KEY_fg) {                                 //JM
        gtk_widget_set_name(button, "calcKeyFG");                          //JM
      }
      else {
        /*        //vv dr - new AIM
        if((key->fShiftedAim == key->keyLblAim || key->fShiftedAim == ITM_PROD_SIGN) && key->keyLblAim != ITM_NULL) {
          gtk_widget_set_name(button, "calcKeyGoldenBorder");
        }
        else {*/  //^^
          gtk_widget_set_name(button, "calcKey");
        /*}*/       //dr - new AIM
      }

      stringToUtf8(indexOfItems[numlockReplacements(10,key->gShiftedAim, getSystemFlag(FLAG_NUMLOCK), false, true)].itemSoftmenuName, lbl);

      //GShift set label
      if(key->gShiftedAim == 0) {
        lbl[0] = 0;
      }

      gtk_label_set_label(GTK_LABEL(lblG), (gchar *)lbl);
      //printf("--THIS IS AIM g-position:                 %s\n",lbl);

      //GShift colours
      if(key->gShiftedAim < 0) {
        gtk_widget_set_name(lblG, "gShiftedUnderline");     //dr - new AIM
      }
      else {
        gtk_widget_set_name(lblG, "AimfShifted");
      }

      //Primaries, convert to UTF
      if(key->primaryAim == 0) {
        lbl[0] = 0;
      }
      else {
        stringToUtf8(indexOfItems[key->primaryAim].itemSoftmenuName, lbl);  //Convert to UTF !
      }

      if(lbl[0] == 32 && lbl[1] == 0) {     //JM SPACE |  OPEN BOX 9251,  0xE2 0x90 0xA3  |  0xE2 0x90 0xA0 for SP.
        lbl[0]=0xC2;          //JM SPACE the space character is not in the font. \rather use . . for space.
        lbl[1]=0xB7;          //JM SPACE
        lbl[2]=' ';           //JM SPACE
        lbl[3]=0xc2;          //JM SPACE
        lbl[4]=0xb7;          //JM SPACE
        lbl[5]=0;             //JM SPACE
      }                       //JM SPACE

      if(debugLabelConsistency(lbl, "labelCaptionAim", key, button, true)) return;
      //LOAD letter in AIM, NOT SURE WHERE THIS IS. SUSPECT C47 DOES NOT USE IT
      gtk_label_set_label(GTK_LABEL(lblL), (gchar *)lbl);
      gtk_widget_set_name(lblL, "letter");
    }



    void labelCaptionTam(const calcKey_t *key, GtkWidget *button) {
      uint8_t lbl[22];

      lbl[0] = 0;
      if(key->primaryTam != ITM_NULL) {
        stringToUtf8(indexOfItems[key->primaryTam].itemSoftmenuName, lbl);
      }

      //THIS IS FOR TAM
      gtk_button_set_label(GTK_BUTTON(button), (gchar *)lbl);

      if(strcmp((char *)lbl, "/") == 0 && key->keyId == 55) {    //JM if "/", re-do to "÷". Presumed easier than to fix the UTf8 conversion above.
        gtk_button_set_label(GTK_BUTTON(button), "÷");           //JM DIV
      }                                                          //JM

      if(key->primaryTam == ITM_SHIFTf) {
        gtk_widget_set_name(button, "calcKeyF");
      }
      else if(key->primaryTam == ITM_SHIFTg) {
        gtk_widget_set_name(button, "calcKeyG");
      }
      else if(key->primaryTam == KEY_fg) {                              //JM
        gtk_widget_set_name(button, "calcKeyFG");                        //JM
      }

      else if(strcmp((char *)lbl, "/") == 0 && key->keyId == 55) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else if(strcmp((char *)lbl, "×") == 0 && key->keyId == 65) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else if(strcmp((char *)lbl, "-") == 0 && key->keyId == 75) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators
      else if(strcmp((char *)lbl, "+") == 0 && key->keyId == 85) {      //JM increase the font size of the operators
        gtk_widget_set_name(button, "calcNumericKey");                  //JM increase the font size of the operators
      }                                                                 //JM increase the font size of the operators

      else {
        gtk_widget_set_name(button, "calcKey");
      }
    }

    void calcModeNormalGui(void) {
      #if defined(DEBUGMODES) && defined(PC_BUILD)
        printf(">>> @@@ calcModeNormalGui     calcMode=%d tam.alpha=%d\n", calcMode, tam.alpha);
      #endif // DEBUGMODES && PC_BUILD

      const calcKey_t *keys;

      keys = getSystemFlag(FLAG_USER) ? kbd_usr : kbd_std;

      hideAllWidgets();

      gtk_widget_show( lblFKey2);  //JMLINES
      gtk_widget_show( lblGKey2);  //JMLINES

      labelCaptionNormal(keys++, btn21, lbl21F, lbl21G, lbl21L);
      labelCaptionNormal(keys++, btn22, lbl22F, lbl22G, lbl22L);
      labelCaptionNormal(keys++, btn23, lbl23F, lbl23G, lbl23L);
      labelCaptionNormal(keys++, btn24, lbl24F, lbl24G, lbl24L);
      labelCaptionNormal(keys++, btn25, lbl25F, lbl25G, lbl25L);
      labelCaptionNormal(keys++, btn26, lbl26F, lbl26G, lbl26L);

      labelCaptionNormal(keys++, btn31, lbl31F, lbl31G, lbl31L);
      labelCaptionNormal(keys++, btn32, lbl32F, lbl32G, lbl32L);
      labelCaptionNormal(keys++, btn33, lbl33F, lbl33G, lbl33L);
      labelCaptionNormal(keys++, btn34, lbl34F, lbl34G, lbl34L);
      labelCaptionNormal(keys++, btn35, lbl35F, lbl35G, lbl35L);
      labelCaptionNormal(keys++, btn36, lbl36F, lbl36G, lbl36L);

      labelCaptionNormal(keys++, btn41, lbl41F, lbl41G, lbl41L);
      labelCaptionNormal(keys++, btn42, lbl42F, lbl42G, lbl42L);
      labelCaptionNormal(keys++, btn43, lbl43F, lbl43G, lbl43L);
      labelCaptionNormal(keys++, btn44, lbl44F, lbl44G, lbl44L);
      labelCaptionNormal(keys++, btn45, lbl45F, lbl45G, lbl45L);

      labelCaptionNormal(keys++, btn51, lbl51F, lbl51G, lbl51L);
      labelCaptionNormal(keys++, btn52, lbl52F, lbl52G, lbl52L);
      labelCaptionNormal(keys++, btn53, lbl53F, lbl53G, lbl53L);
      labelCaptionNormal(keys++, btn54, lbl54F, lbl54G, lbl54L);
      labelCaptionNormal(keys++, btn55, lbl55F, lbl55G, lbl55L);

      labelCaptionNormal(keys++, btn61, lbl61F, lbl61G, lbl61L);
      labelCaptionNormal(keys++, btn62, lbl62F, lbl62G, lbl62L);
      labelCaptionNormal(keys++, btn63, lbl63F, lbl63G, lbl63L);
      labelCaptionNormal(keys++, btn64, lbl64F, lbl64G, lbl64L);
      labelCaptionNormal(keys++, btn65, lbl65F, lbl65G, lbl65L);

      labelCaptionNormal(keys++, btn71, lbl71F, lbl71G, lbl71L);
      labelCaptionNormal(keys++, btn72, lbl72F, lbl72G, lbl72L);
      labelCaptionNormal(keys++, btn73, lbl73F, lbl73G, lbl73L);
      labelCaptionNormal(keys++, btn74, lbl74F, lbl74G, lbl74L);
      labelCaptionNormal(keys++, btn75, lbl75F, lbl75G, lbl75L);

      labelCaptionNormal(keys++, btn81, lbl81F, lbl81G, lbl81L);
      labelCaptionNormal(keys++, btn82, lbl82F, lbl82G, lbl82L);
      labelCaptionNormal(keys++, btn83, lbl83F, lbl83G, lbl83L);
      labelCaptionNormal(keys++, btn84, lbl84F, lbl84G, lbl84L);
      labelCaptionNormal(keys++, btn85, lbl85F, lbl85G, lbl85L);

      gtk_widget_show(btn11);
      gtk_widget_show(btn12);
      gtk_widget_show(btn13);
      gtk_widget_show(btn14);
      gtk_widget_show(btn15);
      gtk_widget_show(btn16);

      gtk_widget_show(btn21);
      gtk_widget_show(btn22);
      gtk_widget_show(btn23);
      gtk_widget_show(btn24);
      gtk_widget_show(btn25);
      gtk_widget_show(btn26);

      gtk_widget_show(lbl21F);
      gtk_widget_show(lbl21G);
      gtk_widget_show(lbl21L);
      gtk_widget_show(lbl22F);
      gtk_widget_show(lbl22G);
      gtk_widget_show(lbl22L);
      gtk_widget_show(lbl23F);
      gtk_widget_show(lbl23G);
      gtk_widget_show(lbl23L);
      gtk_widget_show(lbl24F);
      gtk_widget_show(lbl24G);
      gtk_widget_show(lbl24L);
      gtk_widget_show(lbl25F);
      gtk_widget_show(lbl25G);
      gtk_widget_show(lbl25L);
      gtk_widget_show(lbl26L);
      gtk_widget_show(lbl26F);
      gtk_widget_show(lbl26G);

      gtk_widget_show(btn31);
      gtk_widget_show(btn32);
      gtk_widget_show(btn33);
      gtk_widget_show(btn34);
      gtk_widget_show(btn35);
      gtk_widget_show(btn36);

      gtk_widget_show(lbl31F);
      gtk_widget_show(lbl31G);
      gtk_widget_show(lbl31L);
      gtk_widget_show(lbl32F);
      gtk_widget_show(lbl32G);
      gtk_widget_show(lbl32L);
      gtk_widget_show(lbl33F);
      gtk_widget_show(lbl33G);
      gtk_widget_show(lbl33L);
      gtk_widget_show(lbl34F);
      gtk_widget_show(lbl34G);
      gtk_widget_show(lbl34L);
      gtk_widget_show(lbl35L); // JM !!
      gtk_widget_show(lbl36L); // JM !!

      gtk_widget_show(lbl35F); //JM3 SIN/COS/TAN to DM42
      gtk_widget_show(lbl35G); //JM3 SIN/COS/TAN to DM42
      gtk_widget_show(lbl36F); //JM3 SIN/COS/TAN to DM42
      gtk_widget_show(lbl36G); //JM3 SIN/COS/TAN to DM42

      gtk_widget_show(btn41);
      gtk_widget_show(btn42);
      gtk_widget_show(btn43);
      gtk_widget_show(btn44);
      gtk_widget_show(btn45);

      gtk_widget_show(lbl41F);
      gtk_widget_show(lbl41G);
      gtk_widget_show(lbl42F);
      gtk_widget_show(lbl42G);
      gtk_widget_show(lbl42L);
      gtk_widget_show(lbl43F);
      gtk_widget_show(lbl43G);
      gtk_widget_show(lbl43L);
      gtk_widget_show(lbl44F);
      gtk_widget_show(lbl44G);
      gtk_widget_show(lbl44L);
      //gtk_widget_show(lbl44P);
      gtk_widget_show(lbl45F);
      gtk_widget_show(lbl45G);

      gtk_widget_show(btn51);
      gtk_widget_show(btn52);
      gtk_widget_show(btn53);
      gtk_widget_show(btn54);
      gtk_widget_show(btn55);

      gtk_widget_show(lbl51F);
      gtk_widget_show(lbl51G);
      gtk_widget_show(lbl51L);
      gtk_widget_show(lbl52F);
      gtk_widget_show(lbl52G);
      gtk_widget_show(lbl52L);
      gtk_widget_show(lbl53F);
      gtk_widget_show(lbl53G);
      gtk_widget_show(lbl53L);
      gtk_widget_show(lbl54F);
      gtk_widget_show(lbl54G);
      gtk_widget_show(lbl54L);
      gtk_widget_show(lbl55F);
      gtk_widget_show(lbl55G);
      gtk_widget_show(lbl55L);

      gtk_widget_show(btn61);
      gtk_widget_show(btn62);
      gtk_widget_show(btn63);
      gtk_widget_show(btn64);
      gtk_widget_show(btn65);

      gtk_widget_show(lbl61F);
      gtk_widget_show(lbl61G);
      gtk_widget_show(lbl61L);
      gtk_widget_show(lbl62F);
      gtk_widget_show(lbl62G);
      gtk_widget_show(lbl62L);
      gtk_widget_show(lbl63F);
      gtk_widget_show(lbl63G);
      gtk_widget_show(lbl63L);
      gtk_widget_show(lbl64F);
      gtk_widget_show(lbl64G);
      gtk_widget_show(lbl64L);
      gtk_widget_show(lbl65F);
      gtk_widget_show(lbl65G);
      gtk_widget_show(lbl65L); //JM added

      gtk_widget_show(btn71);
      gtk_widget_show(btn72);
      gtk_widget_show(btn73);
      gtk_widget_show(btn74);
      gtk_widget_show(btn75);

      if(calcModel != USER_C47 && calcModel != USER_DM42) {
        gtk_widget_show(lbl71F); //JM REMOVE SHIFT LABEL
        gtk_widget_show(lbl71G); //JM REMOVE SHIFT LABEL
      }
      gtk_widget_show(lbl71L);
      gtk_widget_show(lbl72F);
      gtk_widget_show(lbl72G);
      gtk_widget_show(lbl72L);
      gtk_widget_show(lbl73F);
      gtk_widget_show(lbl73G);
      gtk_widget_show(lbl73L);
      gtk_widget_show(lbl74F);
      gtk_widget_show(lbl74G);
      gtk_widget_show(lbl74L);
      gtk_widget_show(lbl75F);
      gtk_widget_show(lbl75G);
      gtk_widget_show(lbl75L); //JM asdded


      gtk_widget_show(btn81);
      gtk_widget_show(btn82);
      gtk_widget_show(btn83);
      gtk_widget_show(btn84);
      gtk_widget_show(btn85);

      gtk_widget_show(lbl81F);
      gtk_widget_show(lbl81G); //JM
      gtk_widget_show(lbl81L);
      gtk_widget_show(lbl82F);
      gtk_widget_show(lbl82G);
      gtk_widget_show(lbl82L);
      gtk_widget_show(lbl83F);
      gtk_widget_show(lbl83G);
      gtk_widget_show(lbl83L);
      gtk_widget_show(lbl84F);
      gtk_widget_show(lbl84G);
      gtk_widget_show(lbl84L);
      gtk_widget_show(lbl85F);
      gtk_widget_show(lbl85G);
      gtk_widget_show(lbl85L);  //JM add ?

      //gtk_widget_show(lblOn);
      //JM7  gtk_widget_show(lblConfirmY);  //JM Y/N
      //JM7  gtk_widget_show(lblConfirmN);  //JM Y/N

      moveLabels();
    }

    void calcModeAimGui(void) {
      #if defined(DEBUGMODES) && defined(PC_BUILD)
        printf(">>> @@@ calcModeAimGui      calcMode=%d tam.alpha=%d\n", calcMode, tam.alpha);
      #endif // DEBUGMODES && PC_BUILD


      const calcKey_t *keys;

      keys = getSystemFlag(FLAG_USER) ? kbd_usr : kbd_std;

      hideAllWidgets();

      labelCaptionAimFa(keys, lbl21Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn21A, lbl21Gr, lbl21L);     //vv dr - new AIM
      labelCaptionAimFa(keys, lbl22Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn22A, lbl22Gr, lbl22L);
      labelCaptionAimFa(keys, lbl23Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn23A, lbl23Gr, lbl23L);
      labelCaptionAimFa(keys, lbl24Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn24A, lbl24Gr, lbl24L);
      labelCaptionAimFa(keys, lbl25Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn25A, lbl25Gr, lbl25L);
      labelCaptionAimFa(keys, lbl26Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn26A, lbl26Gr, lbl26L);

      labelCaptionAimFa(keys, lbl31Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn31A, lbl31Gr, lbl31L);
      labelCaptionAimFa(keys, lbl32Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn32A, lbl32Gr, lbl32L);
      labelCaptionAimFa(keys, lbl33Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn33A, lbl33Gr, lbl33L);
      labelCaptionAimFa(keys, lbl34Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn34A, lbl34Gr, lbl34L);
      labelCaptionAimFa(keys, lbl35Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn35A, lbl35Gr, lbl35L);
      labelCaptionAimFa(keys, lbl36Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn36A, lbl36Gr, lbl36L);     //^^

      labelCaptionAimFa(keys, lbl41Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn41,  lbl41Gr, lbl41L);
      labelCaptionAimFa(keys, lbl42Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn42A, lbl42Gr, lbl42L);
      labelCaptionAimFa(keys, lbl43Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn43A, lbl43Gr, lbl43L);
      labelCaptionAimFa(keys, lbl44Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn44A, lbl44Gr, lbl44L);     //^^
      labelCaptionAimFa(keys, lbl45Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn45,  lbl45Gr, lbl45L);

      labelCaptionAimFa(keys, lbl51Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn51,  lbl51Gr, lbl51L);
      labelCaptionAimFa(keys, lbl52Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn52A, lbl52Gr, lbl52L);
      labelCaptionAimFa(keys, lbl53Fa);
      labelCaptionAim(keys++, btn53A, lbl53Gr, lbl53L);
      labelCaptionAimFa(keys, lbl54Fa);
      labelCaptionAim(keys++, btn54A, lbl54Gr, lbl54L);
      labelCaptionAimFa(keys, lbl55Fa);
      labelCaptionAim(keys++, btn55A, lbl55Gr, lbl55L);     //^^

      labelCaptionAimFa(keys, lbl61Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn61,  lbl61Gr, lbl61L);
      labelCaptionAimFa(keys, lbl62Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn62A, lbl62Gr, lbl62L);
      labelCaptionAimFa(keys, lbl63Fa);
      labelCaptionAim(keys++, btn63A, lbl63Gr, lbl63L);
      labelCaptionAimFa(keys, lbl64Fa);
      labelCaptionAim(keys++, btn64A, lbl64Gr, lbl64L);
      labelCaptionAimFa(keys, lbl65Fa);
      labelCaptionAim(keys++, btn65A, lbl65Gr, lbl65L);     //^^

      labelCaptionAimFa(keys, lbl71Fa);                     //vv dr - new AIM //JM newest AIM
      labelCaptionAim(keys++, btn71A, lbl71Gr, lbl71L);
      labelCaptionAimFa(keys, lbl72Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn72A, lbl72Gr, lbl72L);
      labelCaptionAimFa(keys, lbl73Fa);
      labelCaptionAim(keys++, btn73A, lbl73Gr, lbl73L);
      labelCaptionAimFa(keys, lbl74Fa);
      labelCaptionAim(keys++, btn74A, lbl74Gr, lbl74L);
      labelCaptionAimFa(keys, lbl75Fa);
      labelCaptionAim(keys++, btn75A, lbl75Gr, lbl75L);     //^^

      labelCaptionAim(keys++, btn81,  lbl81Gr, lbl81L);
      labelCaptionAimFa(keys, lbl82Fa);                     //vv dr - new AIM
      labelCaptionAim(keys++, btn82A, lbl82Gr, lbl82L);
      labelCaptionAimFa(keys, lbl83Fa);
      labelCaptionAim(keys++, btn83A, lbl83Gr, lbl83L);
      labelCaptionAimFa(keys, lbl84Fa);
      labelCaptionAim(keys++, btn84A, lbl84Gr, lbl84L);
      labelCaptionAimFa(keys, lbl85Fa);
      labelCaptionAim(keys++, btn85A, lbl85Gr, lbl85L);     //^^

      gtk_widget_show(btn11);
      gtk_widget_show(btn12);
      gtk_widget_show(btn13);
      gtk_widget_show(btn14);
      gtk_widget_show(btn15);
      gtk_widget_show(btn16);

      gtk_widget_show(btn21A);      //vv dr - new AIM
      gtk_widget_show(btn22A);
      gtk_widget_show(btn23A);
      gtk_widget_show(btn24A);
      gtk_widget_show(btn25A);
      gtk_widget_show(btn26A);

      gtk_widget_show(lbl21Fa);    //JM
      gtk_widget_show(lbl22Fa);    //JM
      gtk_widget_show(lbl23Fa);    //JM
      gtk_widget_show(lbl24Fa);    //JM AIM2
      gtk_widget_show(lbl25Fa);    //JM AIM2
      gtk_widget_show(lbl26Fa);    //JM AIM2

      /*gtk_widget_show(lbl21L);
      gtk_widget_show(lbl22L);
      gtk_widget_show(lbl23L);
      gtk_widget_show(lbl24L);
      gtk_widget_show(lbl25L);
      gtk_widget_show(lbl26L);*/    //^^
      //gtk_widget_show(lbl26F);
      //gtk_widget_show(lbl26G);
      gtk_widget_show(lbl21Gr);
      gtk_widget_show(lbl22Gr);
      gtk_widget_show(lbl23Gr);
      gtk_widget_show(lbl24Gr);
      gtk_widget_show(lbl25Gr);
      gtk_widget_show(lbl26Gr);

      gtk_widget_show(btn31A);      //vv dr - new AIM
      gtk_widget_show(btn32A);
      gtk_widget_show(btn33A);
      gtk_widget_show(btn34A);
      gtk_widget_show(btn35A);
      gtk_widget_show(btn36A);      //^^


      gtk_widget_show(lbl31Fa);    //JM AIM2
      gtk_widget_show(lbl32Fa);    //JM AIM2
      gtk_widget_show(lbl33Fa);    //JM AIM2
      gtk_widget_show(lbl34Fa);    //JM AIM2
      gtk_widget_show(lbl35Fa);    //JM AIM2
      gtk_widget_show(lbl36Fa);    //JM AIM2


      //gtk_widget_show(lbl34Fa);    //JMALPHA2
      //gtk_widget_show(lbl35Fa);    //JMALPHA2

      //gtk_widget_show(lbl31F);  JM
      //gtk_widget_show(lbl31L);    //dr - new AIM
      //gtk_widget_show(lbl32L);    //dr - new AIM
      //gtk_widget_show(lbl33L);    //dr - new AIM
      //gtk_widget_show(lbl34L);    //dr - new AIM
      //gtk_widget_show(lbl35L); // JM !!    //dr - new AIM
      //gtk_widget_show(lbl36L); // JM !!    //dr - new AIM
      gtk_widget_show(lbl31Gr);
      gtk_widget_show(lbl32Gr);
      gtk_widget_show(lbl33Gr);
      gtk_widget_show(lbl34Gr);
      gtk_widget_show(lbl35Gr); //JM !! GR
      gtk_widget_show(lbl36Gr); //JM !! GR

      gtk_widget_show(btn41);
      gtk_widget_show(btn42A);      //vv dr - new AIM
      gtk_widget_show(btn43A);
      gtk_widget_show(btn44A);      //^^
      gtk_widget_show(btn45);

      //gtk_widget_show(lbl41F);
      //gtk_widget_show(lbl41G);
      //gtk_widget_show(lbl42L);    //dr - new AIM
      //gtk_widget_show(lbl43L);
      gtk_widget_show(lbl41Fa);     //JM
      gtk_widget_show(lbl42Fa);
      gtk_widget_show(lbl43Fa);     //^^
      gtk_widget_show(lbl44Fa);    //JM AIM2
      //gtk_widget_show(lbl44L);    //dr - new AIM
      //gtk_widget_show(lbl44P);
      //gtk_widget_show(lbl45F);
      //gtk_widget_show(lbl45G);
      gtk_widget_show(lbl41Gr);
      gtk_widget_show(lbl42Gr);
      gtk_widget_show(lbl43Gr);
      gtk_widget_show(lbl44Gr);
      gtk_widget_show(lbl45Fa);     //^^

      gtk_widget_show(btn51);
      gtk_widget_show(btn52A);      //vv dr - new AIM
      gtk_widget_show(btn53A);
      gtk_widget_show(btn54A);
      gtk_widget_show(btn55A);      //^^

      gtk_widget_show(lbl51L);

      //gtk_widget_show(lbl51G); //JM__
      //gtk_widget_show(lbl55F); //JM__
      //gtk_widget_show(lbl55G); //JM__
      /*gtk_widget_show(lbl52L);      //vv dr - new AIM
      gtk_widget_show(lbl53L);
      gtk_widget_show(lbl54L);
      gtk_widget_show(lbl55L);*/
      gtk_widget_show(lbl51Fa);
      gtk_widget_show(lbl52Fa);
      gtk_widget_show(lbl53Fa);
      gtk_widget_show(lbl54Fa);
      gtk_widget_show(lbl55Fa);     //^^
      gtk_widget_show(lbl51Gr);  //JMAHOME
      gtk_widget_show(lbl52Gr);
      gtk_widget_show(lbl53Gr);
      gtk_widget_show(lbl54Gr);
      gtk_widget_show(lbl55Gr);   //JM GREEK

      gtk_widget_show(btn61);
      gtk_widget_show(btn62A);      //vv dr - new AIM
      gtk_widget_show(btn63A);
      gtk_widget_show(btn64A);
      gtk_widget_show(btn65A);      //^^

//      gtk_widget_show(lbl61L);
      /*gtk_widget_show(lbl62L);      //vv dr - new AIM
      gtk_widget_show(lbl63L);
      gtk_widget_show(lbl64L);
      gtk_widget_show(lbl65L); //JM added*/
      gtk_widget_show(lbl61Fa);
      gtk_widget_show(lbl62Fa);
      gtk_widget_show(lbl63Fa);
      gtk_widget_show(lbl64Fa);
      gtk_widget_show(lbl65Fa);     //^^
      gtk_widget_show(lbl61Gr); //JMAHOME2
      gtk_widget_show(lbl62Gr);
      gtk_widget_show(lbl63Gr);
      gtk_widget_show(lbl64Gr);
      gtk_widget_show(lbl65Gr); //JM ==

      gtk_widget_show(btn71);
      gtk_widget_show(btn71A);
      gtk_widget_show(btn72A);      //vv dr - new AIM
      gtk_widget_show(btn73A);
      gtk_widget_show(btn74A);
      gtk_widget_show(btn75A);      //^^

//      gtk_widget_show(lbl71L);
      /*gtk_widget_show(lbl72L);      //vv dr - new AIM
      gtk_widget_show(lbl73L);
      gtk_widget_show(lbl74L);
      gtk_widget_show(lbl75L); //JM added*/
      gtk_widget_show(lbl71Fa);
      gtk_widget_show(lbl72Fa);
      gtk_widget_show(lbl73Fa);
      gtk_widget_show(lbl74Fa);
      gtk_widget_show(lbl75Fa);     //^^
      gtk_widget_show(lbl71Gr);
      gtk_widget_show(lbl72Gr);
      gtk_widget_show(lbl73Gr);
      gtk_widget_show(lbl74Gr);
      gtk_widget_show(lbl75Gr); //JM ==

      gtk_widget_show(btn81);
      gtk_widget_show(btn82A);      //vv dr - new AIM
      gtk_widget_show(btn83A);
      gtk_widget_show(btn84A);
      gtk_widget_show(btn85A);      //^^

 //     gtk_widget_show(lbl81L);
      gtk_widget_show(lbl81F); //JM added OFF with Layout 42 LAYOUT42
      gtk_widget_show(lbl81G); //JM added OFF with Layout 42 LAYOUT42
      /*gtk_widget_show(lbl82L);      //vv dr - new AIM
      gtk_widget_show(lbl83L);
      gtk_widget_show(lbl84L);
      gtk_widget_show(lbl85L);  //JM add ?*/
      gtk_widget_show(lbl82Fa);
      gtk_widget_show(lbl83Fa);
      gtk_widget_show(lbl84Fa);
      gtk_widget_show(lbl85Fa);     //^^
      //gtk_widget_show(lbl85F); //JM
      //gtk_widget_show(lbl85G); //JM

      //gtk_widget_show(lbl81Gr); //JMAPRT
      gtk_widget_show(lbl82Gr);
      gtk_widget_show(lbl83Gr);
      gtk_widget_show(lbl84Gr); //JM TT
      gtk_widget_show(lbl85Gr); //JM

      //gtk_widget_show(lblOn);
      //JM7 gtk_widget_show(lblConfirmY);  //JM Y/N
      //JM7 gtk_widget_show(lblConfirmN);  //JM Y/N

      moveLabels();
    }

    void calcModeTamGui(void) {
      #if defined(DEBUGMODES) && defined(PC_BUILD)
        printf(">>> @@@ calcModeTamGui      calcMode=%d tam.alpha=%d\n", calcMode, tam.alpha);
      #endif // DEBUGMODES && PC_BUILD

      const calcKey_t *keys;

      keys = getSystemFlag(FLAG_USER) ? kbd_usr : kbd_std;

      hideAllWidgets();

      labelCaptionTam(keys++, btn21);
      labelCaptionTam(keys++, btn22);
      labelCaptionTam(keys++, btn23);
      labelCaptionTam(keys++, btn24);
      labelCaptionTam(keys++, btn25);
      labelCaptionTam(keys++, btn26);

      labelCaptionTam(keys++, btn31);
      labelCaptionTam(keys++, btn32);
      labelCaptionTam(keys++, btn33);
      labelCaptionTam(keys++, btn34);
      labelCaptionTam(keys++, btn35);
      labelCaptionTam(keys++, btn36);

      labelCaptionTam(keys++, btn41);
      labelCaptionTam(keys++, btn42);
      labelCaptionTam(keys++, btn43);
      labelCaptionTam(keys++, btn44);
      labelCaptionTam(keys++, btn45);

      labelCaptionTam(keys++, btn51);
      labelCaptionTam(keys++, btn52);
      labelCaptionTam(keys++, btn53);
      labelCaptionTam(keys++, btn54);
      labelCaptionTam(keys++, btn55);

      labelCaptionTam(keys++, btn61);
      labelCaptionTam(keys++, btn62);
      labelCaptionTam(keys++, btn63);
      labelCaptionTam(keys++, btn64);
      labelCaptionTam(keys++, btn65);

      labelCaptionTam(keys++, btn71);
      labelCaptionTam(keys++, btn72);
      labelCaptionTam(keys++, btn73);
      labelCaptionTam(keys++, btn74);
      labelCaptionTam(keys++, btn75);

      labelCaptionTam(keys++, btn81);
      labelCaptionTam(keys++, btn82);
      labelCaptionTam(keys++, btn83);
      labelCaptionTam(keys++, btn84);
      labelCaptionTam(keys++, btn85);

      hideAllWidgets();

      gtk_widget_show(btn11);
      gtk_widget_show(btn12);
      gtk_widget_show(btn13);
      gtk_widget_show(btn14);
      gtk_widget_show(btn15);
      gtk_widget_show(btn16);

      gtk_widget_show(btn21);
      gtk_widget_show(btn22);
      gtk_widget_show(btn23);
      gtk_widget_show(btn24);
      gtk_widget_show(btn25);
      gtk_widget_show(btn26);

      gtk_widget_show(btn31);
      gtk_widget_show(btn32);
      gtk_widget_show(btn33);
      gtk_widget_show(btn34);
      gtk_widget_show(btn35);
      gtk_widget_show(btn36);

      gtk_widget_show(btn41);
      gtk_widget_show(btn42);
      gtk_widget_show(btn43);
      gtk_widget_show(btn44);
      gtk_widget_show(btn45);

      gtk_widget_show(btn51);
      gtk_widget_show(btn52);
      gtk_widget_show(btn53);
      gtk_widget_show(btn54);
      gtk_widget_show(btn55);

      gtk_widget_show(btn61);
      gtk_widget_show(btn62);
      gtk_widget_show(btn63);
      gtk_widget_show(btn64);
      gtk_widget_show(btn65);

      gtk_widget_show(btn71);
      gtk_widget_show(btn72);
      gtk_widget_show(btn73);
      gtk_widget_show(btn74);
      gtk_widget_show(btn75);

      gtk_widget_show(btn81);
      gtk_widget_show(btn82);
      gtk_widget_show(btn83);
      gtk_widget_show(btn84);
      gtk_widget_show(btn85);

      moveLabels();
    }
  #endif // SIMULATOR_ON_SCREEN_KEYBOARD == 1



const gdkKeyMap_t gdkKeyMap[] = {

//TOREMOVEGREEKKEY vv
//C47 has no direct key input Greek letters
//jm_greek   { .item = ITM_ALPHA                      ,  .gdkKey = GDK_KEY_Greek_ALPHA                 },
//jm_greek   { .item = ITM_BETA                       ,  .gdkKey = GDK_KEY_Greek_BETA                  },
//jm_greek   { .item = ITM_GAMMA                      ,  .gdkKey = GDK_KEY_Greek_GAMMA                 },
//jm_greek   { .item = ITM_DELTA                      ,  .gdkKey = GDK_KEY_Greek_DELTA                 },
//jm_greek   { .item = ITM_EPSILON                    ,  .gdkKey = GDK_KEY_Greek_EPSILON               },
//jm_greek   { .item = ITM_ZETA                       ,  .gdkKey = GDK_KEY_Greek_ZETA                  },
//jm_greek   { .item = ITM_ETA                        ,  .gdkKey = GDK_KEY_Greek_ETA                   },
//jm_greek   { .item = ITM_THETA                      ,  .gdkKey = GDK_KEY_Greek_THETA                 },
//jm_greek   { .item = ITM_IOTA                       ,  .gdkKey = GDK_KEY_Greek_IOTA                  },
//jm_greek   { .item = ITM_IOTA_DIALYTIKA             ,  .gdkKey = GDK_KEY_Greek_IOTAdieresis          },
//jm_greek   { .item = ITM_KAPPA                      ,  .gdkKey = GDK_KEY_Greek_KAPPA                 },
//jm_greek   { .item = ITM_LAMBDA                     ,  .gdkKey = GDK_KEY_Greek_LAMBDA                },
//jm_greek   { .item = ITM_MU                         ,  .gdkKey = GDK_KEY_Greek_MU                    },
//jm_greek   { .item = ITM_NU                         ,  .gdkKey = GDK_KEY_Greek_NU                    },
//jm_greek   { .item = ITM_XI                         ,  .gdkKey = GDK_KEY_Greek_XI                    },
//jm_greek   { .item = ITM_OMICRON                    ,  .gdkKey = GDK_KEY_Greek_OMICRON               },
//jm_greek   { .item = ITM_PI                         ,  .gdkKey = GDK_KEY_Greek_PI                    },
//jm_greek   { .item = ITM_RHO                        ,  .gdkKey = GDK_KEY_Greek_RHO                   },
//jm_greek   { .item = ITM_SIGMA                      ,  .gdkKey = GDK_KEY_Greek_SIGMA                 },
//jm_greek   { .item = ITM_TAU                        ,  .gdkKey = GDK_KEY_Greek_TAU                   },
//jm_greek   { .item = ITM_UPSILON                    ,  .gdkKey = GDK_KEY_Greek_UPSILON               },
//jm_greek   { .item = ITM_UPSILON_DIALYTIKA          ,  .gdkKey = GDK_KEY_Greek_UPSILONdieresis       },
//jm_greek   { .item = ITM_PHI                        ,  .gdkKey = GDK_KEY_Greek_PHI                   },
//jm_greek   { .item = ITM_CHI                        ,  .gdkKey = GDK_KEY_Greek_CHI                   },
//jm_greek   { .item = ITM_PSI                        ,  .gdkKey = GDK_KEY_Greek_PSI                   },
//jm_greek   { .item = ITM_OMEGA                      ,  .gdkKey = GDK_KEY_Greek_OMEGA                 },
//jm_greek   { .item = ITM_alpha                      ,  .gdkKey = GDK_KEY_Greek_alpha                 },
//jm_greek   { .item = ITM_beta                       ,  .gdkKey = GDK_KEY_Greek_beta                  },
//jm_greek   { .item = ITM_gamma                      ,  .gdkKey = GDK_KEY_Greek_gamma                 },
//jm_greek   { .item = ITM_delta                      ,  .gdkKey = GDK_KEY_Greek_delta                 },
//jm_greek   { .item = ITM_epsilon                    ,  .gdkKey = GDK_KEY_Greek_epsilon               },
//jm_greek   { .item = ITM_zeta                       ,  .gdkKey = GDK_KEY_Greek_zeta                  },
//jm_greek   { .item = ITM_eta                        ,  .gdkKey = GDK_KEY_Greek_eta                   },
//jm_greek   { .item = ITM_theta                      ,  .gdkKey = GDK_KEY_Greek_theta                 },
//jm_greek   { .item = ITM_iota                       ,  .gdkKey = GDK_KEY_Greek_iota                  },
//jm_greek   { .item = ITM_iota_DIALYTIKA             ,  .gdkKey = GDK_KEY_Greek_iotadieresis          },
//jm_greek   { .item = ITM_kappa                      ,  .gdkKey = GDK_KEY_Greek_kappa                 },
//jm_greek   { .item = ITM_lambda                     ,  .gdkKey = GDK_KEY_Greek_lambda                },
//jm_greek   { .item = ITM_mu                         ,  .gdkKey = GDK_KEY_Greek_mu                    },
//jm_greek   { .item = ITM_nu                         ,  .gdkKey = GDK_KEY_Greek_nu                    },
//jm_greek   { .item = ITM_xi                         ,  .gdkKey = GDK_KEY_Greek_xi                    },
//jm_greek   { .item = ITM_omicron                    ,  .gdkKey = GDK_KEY_Greek_omicron               },
//jm_greek   { .item = ITM_pi                         ,  .gdkKey = GDK_KEY_Greek_pi                    },
//jm_greek   { .item = ITM_rho                        ,  .gdkKey = GDK_KEY_Greek_rho                   },
//jm_greek   { .item = ITM_sigma                      ,  .gdkKey = GDK_KEY_Greek_sigma                 },
//jm_greek   { .item = ITM_tau                        ,  .gdkKey = GDK_KEY_Greek_tau                   },
//jm_greek   { .item = ITM_upsilon                    ,  .gdkKey = GDK_KEY_Greek_upsilon               },
//jm_greek   { .item = ITM_upsilon_DIALYTIKA          ,  .gdkKey = GDK_KEY_Greek_upsilondieresis       },
//jm_greek   { .item = ITM_phi                        ,  .gdkKey = GDK_KEY_Greek_phi                   },
//jm_greek   { .item = ITM_chi                        ,  .gdkKey = GDK_KEY_Greek_chi                   },
//jm_greek   { .item = ITM_psi                        ,  .gdkKey = GDK_KEY_Greek_psi                   },
//jm_greek   { .item = ITM_omega                      ,  .gdkKey = GDK_KEY_Greek_omega                 },
//jm_greek   { .item = ITM_alpha_TONOS                ,  .gdkKey = GDK_KEY_Greek_alphaaccent           },
//jm_greek   { .item = ITM_epsilon_TONOS              ,  .gdkKey = GDK_KEY_Greek_epsilonaccent         },
//jm_greek   { .item = ITM_eta_TONOS                  ,  .gdkKey = GDK_KEY_Greek_etaaccent             },
//jm_greek   { .item = ITM_iotaTON                    ,  .gdkKey = GDK_KEY_Greek_iotaaccent            },
//jm_greek   { .item = ITM_iota_DIALYTIKA_TONOS       ,  .gdkKey = GDK_KEY_Greek_iotaaccentdieresis    },
//jm_greek   { .item = ITM_omicron_TONOS              ,  .gdkKey = GDK_KEY_Greek_omicronaccent         },
//jm_greek   { .item = ITM_sigma_end                  ,  .gdkKey = GDK_KEY_Greek_finalsmallsigma       },
//jm_greek   { .item = ITM_upsilon_TONOS              ,  .gdkKey = GDK_KEY_Greek_upsilonaccent         },
//jm_greek   { .item = ITM_upsilon_DIALYTIKA_TONOS    ,  .gdkKey = GDK_KEY_Greek_upsilonaccentdieresis },
//jm_greek   { .item = ITM_omega_TONOS                ,  .gdkKey = GDK_KEY_Greek_omegaaccent           },
//jm_greek //  { .item = ITM_QOPPA                      ,  .gdkKey = GDK_KEY_Greek_QOPPA                 },
//jm_greek //  { .item = ITM_DIGAMMA                    ,  .gdkKey = GDK_KEY_Greek_DIGAMMA               },
//jm_greek //  { .item = ITM_SAMPI                      ,  .gdkKey = GDK_KEY_Greek_SAMPI                 },
//jm_greek //  { .item = ITM_qoppa                      ,  .gdkKey = GDK_KEY_Greek_qoppa                 },
//jm_greek //  { .item = ITM_digamma                    ,  .gdkKey = GDK_KEY_Greek_digamma               },
//jm_greek //  { .item = ITM_sampi                      ,  .gdkKey = GDK_KEY_Greek_sampi                 },
//TOREMOVEGREEKKEY ^^
  { .item = ITM_A_MACRON                   ,  .gdkKey = GDK_KEY_Amacron                     },
  { .item = ITM_A_ACUTE                    ,  .gdkKey = GDK_KEY_Aacute                      },
  { .item = ITM_A_BREVE                    ,  .gdkKey = GDK_KEY_Abreve                      },
  { .item = ITM_A_GRAVE                    ,  .gdkKey = GDK_KEY_Agrave                      },
  { .item = ITM_A_DIARESIS                 ,  .gdkKey = GDK_KEY_Adiaeresis                  },
  { .item = ITM_A_TILDE                    ,  .gdkKey = GDK_KEY_Atilde                      },
  { .item = ITM_A_CIRC                     ,  .gdkKey = GDK_KEY_Acircumflex                 },
  { .item = ITM_A_RING                     ,  .gdkKey = GDK_KEY_Aring                       },
  { .item = ITM_AE                         ,  .gdkKey = GDK_KEY_AE                          },
  { .item = ITM_A_OGONEK                   ,  .gdkKey = GDK_KEY_Aogonek                     },
  { .item = ITM_C_ACUTE                    ,  .gdkKey = GDK_KEY_Cacute                      },
  { .item = ITM_C_CARON                    ,  .gdkKey = GDK_KEY_Ccaron                      },
  { .item = ITM_C_CEDILLA                  ,  .gdkKey = GDK_KEY_Ccedilla                    },
  { .item = ITM_D_STROKE                   ,  .gdkKey = GDK_KEY_Dstroke                     },
  { .item = ITM_D_CARON                    ,  .gdkKey = GDK_KEY_Dcaron                      },
  { .item = ITM_E_MACRON                   ,  .gdkKey = GDK_KEY_Emacron                     },
  { .item = ITM_E_ACUTE                    ,  .gdkKey = GDK_KEY_Eacute                      },
//  #define ITM_E_BREVE 681                                ,                                        ,
  { .item = ITM_E_GRAVE                    ,  .gdkKey = GDK_KEY_Egrave                      },
  { .item = ITM_E_DIARESIS                 ,  .gdkKey = GDK_KEY_Ediaeresis                  },
  { .item = ITM_E_CIRC                     ,  .gdkKey = GDK_KEY_Ecircumflex                 },
  { .item = ITM_E_OGONEK                   ,  .gdkKey = GDK_KEY_Eogonek                     },
  { .item = ITM_G_BREVE                    ,  .gdkKey = GDK_KEY_Gbreve                      },
  { .item = ITM_I_MACRON                   ,  .gdkKey = GDK_KEY_Imacron                     },
  { .item = ITM_I_ACUTE                    ,  .gdkKey = GDK_KEY_Iacute                      },
  { .item = ITM_I_BREVE                    ,  .gdkKey = GDK_KEY_Ibreve                      },
  { .item = ITM_I_GRAVE                    ,  .gdkKey = GDK_KEY_Igrave                      },
  { .item = ITM_I_DIARESIS                 ,  .gdkKey = GDK_KEY_Idiaeresis                  },
  { .item = ITM_I_CIRC                     ,  .gdkKey = GDK_KEY_Icircumflex                 },
  { .item = ITM_I_OGONEK                   ,  .gdkKey = GDK_KEY_Iogonek                     },
//  #define ITM_I_DOT 694                                ,                                        ,
//  #define ITM_I_DOTLESS 695                                ,                                        ,
  { .item = ITM_L_STROKE                   ,  .gdkKey = GDK_KEY_Lstroke                     },
  { .item = ITM_L_ACUTE                    ,  .gdkKey = GDK_KEY_Lacute                      },
//  #define ITM_L_APOSTROPHE 698                                ,                                        ,
  { .item = ITM_N_ACUTE                    ,  .gdkKey = GDK_KEY_Nacute                      },
  { .item = ITM_N_CARON                    ,  .gdkKey = GDK_KEY_Ncaron                      },
  { .item = ITM_N_TILDE                    ,  .gdkKey = GDK_KEY_Ntilde                      },
  { .item = ITM_O_MACRON                   ,  .gdkKey = GDK_KEY_Omacron                     },
  { .item = ITM_O_ACUTE                    ,  .gdkKey = GDK_KEY_Oacute                      },
//  #define ITM_O_BREVE 704                                ,                                        ,
  { .item = ITM_O_GRAVE                    ,  .gdkKey = GDK_KEY_Ograve                      },
  { .item = ITM_O_DIARESIS                 ,  .gdkKey = GDK_KEY_Odiaeresis                  },
  { .item = ITM_O_TILDE                    ,  .gdkKey = GDK_KEY_Otilde                      },
  { .item = ITM_O_CIRC                     ,  .gdkKey = GDK_KEY_Ocircumflex                 },
//  #define ITM_O_STROKE 709                                ,                                        ,
  { .item = ITM_OE                         ,  .gdkKey = GDK_KEY_OE                          },
  { .item = ITM_S_SHARP                    ,  .gdkKey = GDK_KEY_ssharp                      },
  { .item = ITM_S_ACUTE                    ,  .gdkKey = GDK_KEY_Sacute                      },
  { .item = ITM_S_CARON                    ,  .gdkKey = GDK_KEY_Scaron                      },
  { .item = ITM_S_CEDILLA                  ,  .gdkKey = GDK_KEY_Scedilla                    },
  { .item = ITM_T_CARON                    ,  .gdkKey = GDK_KEY_Tcaron                      },
  { .item = ITM_T_CEDILLA                  ,  .gdkKey = GDK_KEY_Tcedilla                    },
  { .item = ITM_U_MACRON                   ,  .gdkKey = GDK_KEY_Umacron                     },
  { .item = ITM_U_ACUTE                    ,  .gdkKey = GDK_KEY_Uacute                      },
  { .item = ITM_U_BREVE                    ,  .gdkKey = GDK_KEY_Ubreve                      },
  { .item = ITM_U_GRAVE                    ,  .gdkKey = GDK_KEY_Ugrave                      },
  { .item = ITM_U_DIARESIS                 ,  .gdkKey = GDK_KEY_Udiaeresis                  },
  { .item = ITM_U_TILDE                    ,  .gdkKey = GDK_KEY_Utilde                      },
  { .item = ITM_U_CIRC                     ,  .gdkKey = GDK_KEY_Ucircumflex                 },
  { .item = ITM_U_RING                     ,  .gdkKey = GDK_KEY_Uring                       },
  { .item = ITM_W_CIRC                     ,  .gdkKey = GDK_KEY_Wcircumflex                 },
  { .item = ITM_Y_CIRC                     ,  .gdkKey = GDK_KEY_Ycircumflex                 },
  { .item = ITM_Y_ACUTE                    ,  .gdkKey = GDK_KEY_Yacute                      },
  { .item = ITM_Y_DIARESIS                 ,  .gdkKey = GDK_KEY_Ydiaeresis                  },
  { .item = ITM_Z_ACUTE                    ,  .gdkKey = GDK_KEY_Zacute                      },
  { .item = ITM_Z_CARON                    ,  .gdkKey = GDK_KEY_Zcaron                      },
  { .item = ITM_Z_DOT                      ,  .gdkKey = GDK_KEY_Zabovedot                   },
  { .item = ITM_a_MACRON                   ,  .gdkKey = GDK_KEY_amacron                     },
  { .item = ITM_a_ACUTE                    ,  .gdkKey = GDK_KEY_aacute                      },
  { .item = ITM_a_BREVE                    ,  .gdkKey = GDK_KEY_abreve                      },
  { .item = ITM_a_GRAVE                    ,  .gdkKey = GDK_KEY_agrave                      },
  { .item = ITM_a_DIARESIS                 ,  .gdkKey = GDK_KEY_adiaeresis                  },
  { .item = ITM_a_TILDE                    ,  .gdkKey = GDK_KEY_atilde                      },
  { .item = ITM_a_CIRC                     ,  .gdkKey = GDK_KEY_acircumflex                 },
  { .item = ITM_a_RING                     ,  .gdkKey = GDK_KEY_aring                       },
  { .item = ITM_ae                         ,  .gdkKey = GDK_KEY_ae                          },
  { .item = ITM_a_OGONEK                   ,  .gdkKey = GDK_KEY_aogonek                     },
  { .item = ITM_c_ACUTE                    ,  .gdkKey = GDK_KEY_cacute                      },
  { .item = ITM_c_CARON                    ,  .gdkKey = GDK_KEY_ccaron                      },
  { .item = ITM_c_CEDILLA                  ,  .gdkKey = GDK_KEY_ccedilla                    },
  { .item = ITM_d_STROKE                   ,  .gdkKey = GDK_KEY_dstroke                     },
//  #define ITM_d_APOSTROPHE 746                                ,                                        ,
  { .item = ITM_e_MACRON                   ,  .gdkKey = GDK_KEY_emacron                     },
  { .item = ITM_e_ACUTE                    ,  .gdkKey = GDK_KEY_eacute                      },
//  #define ITM_e_BREVE 749                                ,                                        ,
  { .item = ITM_e_GRAVE                    ,  .gdkKey = GDK_KEY_egrave                      },
  { .item = ITM_e_DIARESIS                 ,  .gdkKey = GDK_KEY_ediaeresis                  },
  { .item = ITM_e_CIRC                     ,  .gdkKey = GDK_KEY_ecircumflex                 },
  { .item = ITM_e_OGONEK                   ,  .gdkKey = GDK_KEY_eogonek                     },
  { .item = ITM_g_BREVE                    ,  .gdkKey = GDK_KEY_gbreve                      },
  { .item = ITM_h_STROKE                   ,  .gdkKey = GDK_KEY_hstroke                     },
  { .item = ITM_i_MACRON                   ,  .gdkKey = GDK_KEY_imacron                     },
  { .item = ITM_i_ACUTE                    ,  .gdkKey = GDK_KEY_iacute                      },
  { .item = ITM_i_BREVE                    ,  .gdkKey = GDK_KEY_ibreve                      },
  { .item = ITM_i_GRAVE                    ,  .gdkKey = GDK_KEY_igrave                      },
  { .item = ITM_i_DIARESIS                 ,  .gdkKey = GDK_KEY_idiaeresis                  },
  { .item = ITM_i_CIRC                     ,  .gdkKey = GDK_KEY_icircumflex                 },
  { .item = ITM_i_OGONEK                   ,  .gdkKey = GDK_KEY_iogonek                     },
//  #define ITM_i_DOT 763                                ,                                        ,
  { .item = ITM_i_DOTLESS                  ,  .gdkKey = GDK_KEY_idotless                    },
  { .item = ITM_l_STROKE                   ,  .gdkKey = GDK_KEY_lstroke                     },
  { .item = ITM_l_ACUTE                    ,  .gdkKey = GDK_KEY_lacute                      },
//  #define ITM_l_APOSTROPHE 767                                ,                                        ,
  { .item = ITM_n_ACUTE                    ,  .gdkKey = GDK_KEY_nacute                      },
  { .item = ITM_n_CARON                    ,  .gdkKey = GDK_KEY_ncaron                      },
  { .item = ITM_n_TILDE                    ,  .gdkKey = GDK_KEY_ntilde                      },
  { .item = ITM_o_MACRON                   ,  .gdkKey = GDK_KEY_omacron                     },
  { .item = ITM_o_ACUTE                    ,  .gdkKey = GDK_KEY_oacute                      },
//  #define ITM_o_BREVE 773                                ,                                        ,
  { .item = ITM_o_GRAVE                    ,  .gdkKey = GDK_KEY_ograve                      },
  { .item = ITM_o_DIARESIS                 ,  .gdkKey = GDK_KEY_odiaeresis                  },
  { .item = ITM_o_TILDE                    ,  .gdkKey = GDK_KEY_otilde                      },
  { .item = ITM_o_CIRC                     ,  .gdkKey = GDK_KEY_ocircumflex                 },
//  #define ITM_o_STROKE 778                                ,                                        ,
  { .item = ITM_oe                         ,  .gdkKey = GDK_KEY_oe                          },
  { .item = ITM_r_CARON                    ,  .gdkKey = GDK_KEY_rcaron                      },
  { .item = ITM_r_ACUTE                    ,  .gdkKey = GDK_KEY_racute                      },
//  #define ITM_s_SHARP 782                                ,                                        ,
  { .item = ITM_s_ACUTE                    ,  .gdkKey = GDK_KEY_sacute                      },
  { .item = ITM_s_CARON                    ,  .gdkKey = GDK_KEY_scaron                      },
  { .item = ITM_s_CEDILLA                  ,  .gdkKey = GDK_KEY_scedilla                    },
//  #define ITM_t_APOSTROPHE 786                                ,                                        ,
  { .item = ITM_t_CEDILLA                  ,  .gdkKey = GDK_KEY_tcedilla                    },
  { .item = ITM_u_MACRON                   ,  .gdkKey = GDK_KEY_umacron                     },
  { .item = ITM_u_ACUTE                    ,  .gdkKey = GDK_KEY_uacute                      },
  { .item = ITM_u_BREVE                    ,  .gdkKey = GDK_KEY_ubreve                      },
  { .item = ITM_u_GRAVE                    ,  .gdkKey = GDK_KEY_ugrave                      },
  { .item = ITM_u_DIARESIS                 ,  .gdkKey = GDK_KEY_udiaeresis                  },
  { .item = ITM_u_TILDE                    ,  .gdkKey = GDK_KEY_utilde                      },
  { .item = ITM_u_CIRC                     ,  .gdkKey = GDK_KEY_ucircumflex                 },
  { .item = ITM_u_RING                     ,  .gdkKey = GDK_KEY_uring                       },
  { .item = ITM_w_CIRC                     ,  .gdkKey = GDK_KEY_wcircumflex                 },
//  #define ITM_x_BAR 797                                ,                                        ,
//  #define ITM_x_CIRC 798                                ,                                        ,
//  #define ITM_y_BAR 799                                ,                                        ,
  { .item = ITM_y_CIRC                     ,  .gdkKey = GDK_KEY_ycircumflex                 },
  { .item = ITM_y_ACUTE                    ,  .gdkKey = GDK_KEY_yacute                      },
  { .item = ITM_y_DIARESIS                 ,  .gdkKey = GDK_KEY_ydiaeresis                  },
  { .item = ITM_z_ACUTE                    ,  .gdkKey = GDK_KEY_zacute                      },
  { .item = ITM_z_CARON                    ,  .gdkKey = GDK_KEY_zcaron                      },
  { .item = ITM_z_DOT                      ,  .gdkKey = GDK_KEY_zabovedot                   },

  { .item = ITM_LEFT_SQUARE_BRACKET        ,  .gdkKey = GDK_KEY_bracketleft                 },
  { .item = ITM_BACK_SLASH                 ,  .gdkKey = GDK_KEY_backslash                   },
  { .item = ITM_RIGHT_SQUARE_BRACKET       ,  .gdkKey = GDK_KEY_bracketright                },
  { .item = ITM_CIRCUMFLEX                 ,  .gdkKey = GDK_KEY_asciicircum                 },
  { .item = ITM_UNDERSCORE                 ,  .gdkKey = GDK_KEY_underscore                  },
  { .item = ITM_LEFT_CURLY_BRACKET         ,  .gdkKey = GDK_KEY_braceleft                   },
  { .item = ITM_PIPE                       ,  .gdkKey = GDK_KEY_bar                         },
  { .item = ITM_RIGHT_CURLY_BRACKET        ,  .gdkKey = GDK_KEY_braceright                  },
  { .item = ITM_TILDE                      ,  .gdkKey = GDK_KEY_asciitilde                  },

  { .item = ITM_INVERTED_EXCLAMATION_MARK  ,  .gdkKey = GDK_KEY_exclamdown                  },
  { .item = ITM_CENT                       ,  .gdkKey = GDK_KEY_cent                        },
  { .item = ITM_POUND                      ,  .gdkKey = GDK_KEY_sterling                    },
  { .item = ITM_YEN                        ,  .gdkKey = GDK_KEY_yen                         },
  { .item = ITM_SECTION                    ,  .gdkKey = GDK_KEY_section                     },
//  #define ITM_OVERFLOW_CARRY 843                                ,                                        ,
  { .item = ITM_LEFT_DOUBLE_ANGLE          ,  .gdkKey = GDK_KEY_guillemotleft               },
  { .item = ITM_NOT                        ,  .gdkKey = GDK_KEY_notsign                     },
  { .item = ITM_DEGREE                     ,  .gdkKey = GDK_KEY_degree                      },
  { .item = ITM_PLUS_MINUS                 ,  .gdkKey = GDK_KEY_plusminus                   },
  { .item = ITM_MICRO                      ,  .gdkKey = GDK_KEY_mu                          },
//  #define ITM_DOT 849                                ,                                        ,
  { .item = ITM_RIGHT_DOUBLE_ANGLE         ,  .gdkKey = GDK_KEY_guillemotright              },
  { .item = ITM_ONE_HALF                   ,  .gdkKey = GDK_KEY_onehalf                     },
  { .item = ITM_ONE_QUARTER                ,  .gdkKey = GDK_KEY_onequarter                  },
  { .item = ITM_ONE_HALF                   ,  .gdkKey = GDK_KEY_onehalf                     },
  { .item = ITM_INVERTED_QUESTION_MARK     ,  .gdkKey = GDK_KEY_questiondown                },
  { .item = ITM_ETH                        ,  .gdkKey = GDK_KEY_ETH                         },
  { .item = ITM_CROSS                      ,  .gdkKey = GDK_KEY_multiply                    },
  { .item = ITM_eth                        ,  .gdkKey = GDK_KEY_eth                         },
//  #define ITM_OBELUS 857                                ,                                        ,
  { .item = ITM_E_DOT                      ,  .gdkKey = GDK_KEY_Eabovedot                   },
  { .item = ITM_e_DOT                      ,  .gdkKey = GDK_KEY_eabovedot                   },
  { .item = ITM_E_CARON                    ,  .gdkKey = GDK_KEY_Ecaron                      },
  { .item = ITM_e_CARON                    ,  .gdkKey = GDK_KEY_ecaron                      },
  { .item = ITM_R_ACUTE                    ,  .gdkKey = GDK_KEY_Racute                      },
  { .item = ITM_R_CARON                    ,  .gdkKey = GDK_KEY_Rcaron                      },
  { .item = ITM_U_OGONEK                   ,  .gdkKey = GDK_KEY_Uogonek                     },
  { .item = ITM_u_OGONEK                   ,  .gdkKey = GDK_KEY_uogonek                     },
//  #define ITM_y_UNDER_ROOT 866                                ,                                        ,
//  #define ITM_x_UNDER_ROOT 867                                ,                                        ,
  { .item = ITM_SPACE_EM                   ,  .gdkKey = GDK_KEY_emspace                     },
  { .item = ITM_SPACE_3_PER_EM             ,  .gdkKey = GDK_KEY_em3space                    },
  { .item = ITM_SPACE_4_PER_EM             ,  .gdkKey = GDK_KEY_em4space                    },
//  #define ITM_SPACE_6_PER_EM 871                                ,                                        ,
  { .item = ITM_SPACE_FIGURE               ,  .gdkKey = GDK_KEY_digitspace                  },
  { .item = ITM_SPACE_PUNCTUATION          ,  .gdkKey = GDK_KEY_punctspace                  },
  { .item = ITM_SPACE_HAIR                 ,  .gdkKey = GDK_KEY_hairspace                   },
  { .item = ITM_LEFT_SINGLE_QUOTE          ,  .gdkKey = GDK_KEY_leftsinglequotemark         },
  { .item = ITM_RIGHT_SINGLE_QUOTE         ,  .gdkKey = GDK_KEY_rightsinglequotemark        },
  { .item = ITM_SINGLE_LOW_QUOTE           ,  .gdkKey = GDK_KEY_singlelowquotemark          },
//  #define ITM_SINGLE_HIGH_QUOTE 878                                ,                                        ,
  { .item = ITM_LEFT_DOUBLE_QUOTE          ,  .gdkKey = GDK_KEY_leftdoublequotemark         },
  { .item = ITM_RIGHT_DOUBLE_QUOTE         ,  .gdkKey = GDK_KEY_rightdoublequotemark        },
  { .item = ITM_DOUBLE_LOW_QUOTE           ,  .gdkKey = GDK_KEY_doublelowquotemark          },
//  #define ITM_DOUBLE_HIGH_QUOTE 882                                ,                                        ,
  { .item = ITM_ELLIPSIS                   ,  .gdkKey = GDK_KEY_ellipsis                    },
//  #define ITM_BINARY_ONE 884                                ,                                        ,
  { .item = ITM_EURO                       ,  .gdkKey = GDK_KEY_EuroSign                    },
//  #define ITM_COMPLEX_C 886                                ,                                        ,
//  #define ITM_PLANCK 887                                ,                                        ,
//  #define ITM_PLANCK_2PI 888                                ,                                        ,
//  #define ITM_NATURAL_N 889                                ,                                        ,
//  #define ITM_RATIONAL_Q 890                                ,                                        ,
//  #define ITM_REAL_R 891                                ,                                        ,
  { .item = ITM_LEFT_ARROW                 ,  .gdkKey = GDK_KEY_leftarrow                   },
  { .item = ITM_UP_ARROW                   ,  .gdkKey = GDK_KEY_uparrow                     },
  { .item = ITM_RIGHT_ARROW                ,  .gdkKey = GDK_KEY_rightarrow                  },
  { .item = ITM_DOWN_ARROW                 ,  .gdkKey = GDK_KEY_downarrow                   },
//  #define ITM_SERIAL_IO 896                                ,                                        ,
//  #define ITM_RIGHT_SHORT_ARROW 897                                ,                                        ,
//  #define ITM_LEFT_RIGHT_ARROWS 898                                ,                                        ,
//  #define ITM_BST_char 899                                ,                                        ,
//  #define ITM_SST_char 900                                ,                                        ,
//  #define ITM_HAMBURGER 901                                ,                                        ,
//  #define ITM_UNDO_SIGN 902                                ,                                        ,
//  #define ITM_FOR_ALL 903                                ,                                        ,
//  #define ITM_COMPLEMENT 904                                ,                                        ,
  { .item = ITM_PARTIAL_DIFF               ,  .gdkKey = GDK_KEY_partialderivative           },
//  #define ITM_THERE_EXISTS 906                                ,                                        ,
//  #define ITM_THERE_DOES_NOT_EXIST 907                                ,                                        ,
  { .item = ITM_EMPTY_SET                  ,  .gdkKey = GDK_KEY_emptyset                    },
//  #define ITM_INCREMENT 909                                ,                                        ,
  { .item = ITM_NABLA                      ,  .gdkKey = GDK_KEY_nabla                       },
  { .item = ITM_ELEMENT_OF                 ,  .gdkKey = GDK_KEY_elementof                   },
  { .item = ITM_NOT_ELEMENT_OF             ,  .gdkKey = GDK_KEY_notelementof                },
  { .item = ITM_CONTAINS                   ,  .gdkKey = GDK_KEY_containsas                  },
//  #define ITM_DOES_NOT_CONTAIN 914                                ,                                        ,
//  #define ITM_BINARY_ZERO 915                                ,                                        ,
//  #define ITM_PRODUCT 916                                ,                                        ,
  { .item = ITM_MINUS_PLUS                 ,  .gdkKey = GDK_KEY_plusminus                   },
  { .item = ITM_RING                       ,  .gdkKey = GDK_KEY_jot                         },
  { .item = ITM_BULLET                     ,  .gdkKey = GDK_KEY_enfilledcircbullet          },
  { .item = ITM_SQUARE_ROOT                ,  .gdkKey = GDK_KEY_squareroot                  },
  { .item = ITM_CUBEROOT_SIGN              ,  .gdkKey = GDK_KEY_cuberoot                    },
//  #define ITM_xTH_ROOT 922                                ,                                        ,
//  #define ITM_PROPORTIONAL 923                                ,                                        ,
  { .item = ITM_INFINITY                   ,  .gdkKey = GDK_KEY_infinity                    },
//  #define ITM_RIGHT_ANGLE 925                                ,                                        ,
//  #define ITM_ANGLE_SIGN 926                                ,                                        ,
//  #define ITM_MEASURED_ANGLE 927                                ,                                        ,
//  #define ITM_DIVIDES 928                                ,                                        ,
//  #define ITM_DOES_NOT_DIVIDE 929                                ,                                        ,
//  #define ITM_PARALLEL_SIGN 930                                ,                                        ,
//  #define ITM_NOT_PARALLEL 931                                ,                                        ,
  { .item = ITM_AND                        ,  .gdkKey = GDK_KEY_logicaland                  },
  { .item = ITM_OR                         ,  .gdkKey = GDK_KEY_logicalor                   },
  { .item = ITM_INTERSECTION               ,  .gdkKey = GDK_KEY_intersection                },
  { .item = ITM_UNION                      ,  .gdkKey = GDK_KEY_union                       },
  { .item = ITM_INTEGRAL_SIGN              ,  .gdkKey = GDK_KEY_integral                    },
  { .item = ITM_DOUBLE_INTEGRAL            ,  .gdkKey = GDK_KEY_dintegral                   },
//  #define ITM_CONTOUR_INTEGRAL 938                                ,                                        ,
//  #define ITM_SURFACE_INTEGRAL 939                                ,                                        ,
//  #define ITM_RATIO 940                                ,                                        ,
  { .item = ITM_CHECK_MARK                 ,  .gdkKey = GDK_KEY_checkmark                   },
  { .item = ITM_ASYMPOTICALLY_EQUAL        ,  .gdkKey = GDK_KEY_similarequal                },
  { .item = ITM_ALMOST_EQUAL               ,  .gdkKey = GDK_KEY_approximate                 },
//  #define ITM_COLON_EQUALS 944                                ,                                        ,
//  #define ITM_CORRESPONDS_TO 945                                ,                                        ,
//  #define ITM_ESTIMATES 946                                ,                                        ,
  { .item = ITM_NOT_EQUAL                  ,  .gdkKey = GDK_KEY_notequal                    },
  { .item = ITM_IDENTICAL_TO               ,  .gdkKey = GDK_KEY_identical                   },
  { .item = ITM_LESS_EQUAL                 ,  .gdkKey = GDK_KEY_lessthanequal               },
  { .item = ITM_GREATER_EQUAL              ,  .gdkKey = GDK_KEY_greaterthanequal            },
//  #define ITM_MUCH_LESS 951                                ,                                        ,
//  #define ITM_MUCH_GREATER 952                                ,                                        ,
//  #define ITM_SUN 953                                ,                                        ,
  { .item = ITM_TRANSPOSED                 ,  .gdkKey = GDK_KEY_downtack                    },

//  #define ITM_PERPENDICULAR 955                                ,                                        ,
//  #define ITM_XOR 956                                ,                                        ,
//  #define ITM_NAND 957                                ,                                        ,
//  #define ITM_NOR 958                                ,                                        ,
//  #define ITM_WATCH 959                                ,                                        ,
//  #define ITM_HOURGLASS 960                                ,                                        ,
//  #define ITM_PRINTER 961                                ,                                        ,
//  #define ITM_MAT_TL 962                                ,                                        ,
//  #define ITM_MAT_ML 963                                ,                                        ,
//  #define ITM_MAT_BL 964                                ,                                        ,
//  #define ITM_MAT_TR 965                                ,                                        ,
//  #define ITM_MAT_MR 966                                ,                                        ,
//  #define ITM_MAT_BR 967                                ,                                        ,
//  #define ITM_OBLIQUE1 968                                ,                                        ,
//  #define ITM_OBLIQUE2 969                                ,                                        ,
//  #define ITM_OBLIQUE3 970                                ,                                        ,
//  #define ITM_OBLIQUE4 971                                ,                                        ,
//  #define ITM_CURSOR 972                                ,                                        ,
//  #define ITM_PERIOD34 973                                ,                                        ,
//  #define ITM_COMMA34 974                                ,                                        ,
//  #define ITM_BATTERY 975                                ,                                        ,
//  #define ITM_PGM_BEGIN 976                                ,                                        ,
//  #define ITM_USER_MODE 977                                ,                                        ,
//  #define ITM_UK 978                                ,                                        ,
//  #define ITM_US 979                                ,                                        ,
//  #define ITM_NEG_EXCLAMATION_MARK 980                                ,                                        ,
//  #define ITM_ex 981                                ,                                        ,
//  #define ITM_Max 982                                ,                                        ,
//  #define ITM_Min 983                                ,                                        ,
//  #define ITM_Config 984                                ,                                        ,
//  #define ITM_Stack 985                                ,                                        ,
//  #define ITM_dddEL 986                                ,                                        ,
//  #define ITM_dddIJ 987                                ,                                        ,
//  #define ITM_0P 988                                ,                                        ,
//  #define ITM_1P 989                                ,                                        ,
//  #define ITM_EXPONENT 990                                ,                                        ,
//  #define ITM_HEX 991                                ,                                        ,
//  #define ITM_M_GOTO_ROW 992                                ,                                        ,
//  #define ITM_M_GOTO_COLUMN 993                                ,                                        ,
//  #define ITM_SOLVE_VAR 994                                ,                                        ,
//  #define ITM_EQ_LEFT 995                                ,                                        ,
//  #define ITM_EQ_RIGHT 996                                ,                                        ,
//  #define ITM_PAIR_OF_PARENTHESES 997                                ,                                        ,
//  #define ITM_VERTICAL_BAR 998                                ,                                        ,
//  #define ITM_ALOG_SYMBOL 999                                ,                                        ,
//  #define ITM_ROOT_SIGN 1000                                ,                                        ,
//  #define ITM_TIMER_SYMBOL 1001                                ,                                        ,
//  #define ITM_Sfdx_VAR 1002                                ,                                        ,
//  #define ITM_SUP_PLUS 1003                                ,                                        ,
//  #define ITM_SUP_MINUS 1004                                ,                                        ,
//  #define ITM_1005 1005                                ,                                        ,
//  #define ITM_SUP_INFINITY 1006                                ,                                        ,
//  #define ITM_SUP_ASTERISK 1007                                ,                                        ,
  { .item = ITM_SUP_0                      ,  .gdkKey = GDK_KEY_zerosuperior                },
  { .item = ITM_SUP_1                      ,  .gdkKey = GDK_KEY_onesuperior                 },
  { .item = ITM_SUP_2                      ,  .gdkKey = GDK_KEY_twosuperior                 },
  { .item = ITM_SUP_3                      ,  .gdkKey = GDK_KEY_threesuperior               },
  { .item = ITM_SUP_4                      ,  .gdkKey = GDK_KEY_foursuperior                },
  { .item = ITM_SUP_5                      ,  .gdkKey = GDK_KEY_fivesuperior                },
  { .item = ITM_SUP_6                      ,  .gdkKey = GDK_KEY_sixsuperior                 },
  { .item = ITM_SUP_7                      ,  .gdkKey = GDK_KEY_sevensuperior               },
  { .item = ITM_SUP_8                      ,  .gdkKey = GDK_KEY_eightsuperior               },
  { .item = ITM_SUP_9                      ,  .gdkKey = GDK_KEY_ninesuperior                },

//NOTE: This is considered the maximum

//  #define ITM_SUP_A 1018                                ,                                        ,
//  #define ITM_SUP_B 1019                                ,                                        ,
//  #define ITM_SUP_C 1020                                ,                                        ,
//  #define ITM_SUP_D 1021                                ,                                        ,
//  #define ITM_SUP_E 1022                                ,                                        ,
//  #define ITM_SUP_F 1023                                ,                                        ,
//  #define ITM_SUP_G 1024                                ,                                        ,
//  #define ITM_SUP_H 1025                                ,                                        ,
//  #define ITM_SUP_I 1026                                ,                                        ,
//  #define ITM_SUP_J 1027                                ,                                        ,
//  #define ITM_SUP_K 1028                                ,                                        ,
//  #define ITM_SUP_L 1029                                ,                                        ,
//  #define ITM_SUP_M 1030                                ,                                        ,
//  #define ITM_SUP_N 1031                                ,                                        ,
//  #define ITM_SUP_O 1032                                ,                                        ,
//  #define ITM_SUP_P 1033                                ,                                        ,
//  #define ITM_SUP_Q 1034                                ,                                        ,
//  #define ITM_SUP_R 1035                                ,                                        ,
//  #define ITM_SUP_S 1036                                ,                                        ,
//  #define ITM_SUP_T 1037                                ,                                        ,
//  #define ITM_SUP_U 1038                                ,                                        ,
//  #define ITM_SUP_V 1039                                ,                                        ,
//  #define ITM_SUP_W 1040                                ,                                        ,
//  #define ITM_SUP_X 1041                                ,                                        ,
//  #define ITM_SUP_Y 1042                                ,                                        ,
//  #define ITM_SUP_Z 1043                                ,                                        ,
//  #define ITM_SUP_a 1044                                ,                                        ,
//  #define ITM_SUP_b 1045                                ,                                        ,
//  #define ITM_SUP_c 1046                                ,                                        ,
//  #define ITM_SUP_d 1047                                ,                                        ,
//  #define ITM_SUP_e 1048                                ,                                        ,
//  #define ITM_SUP_f 1049                                ,                                        ,
//  #define ITM_SUP_g 1050                                ,                                        ,
//  #define ITM_SUP_h 1051                                ,                                        ,
//  #define ITM_SUP_i 1052                                ,                                        ,
//  #define ITM_SUP_j 1053                                ,                                        ,
//  #define ITM_SUP_k 1054                                ,                                        ,
//  #define ITM_SUP_l 1055                                ,                                        ,
//  #define ITM_SUP_m 1056                                ,                                        ,
//  #define ITM_SUP_n 1057                                ,                                        ,
//  #define ITM_SUP_o 1058                                ,                                        ,
//  #define ITM_SUP_p 1059                                ,                                        ,
//  #define ITM_SUP_q 1060                                ,                                        ,
//  #define ITM_SUP_r 1061                                ,                                        ,
//  #define ITM_SUP_s 1062                                ,                                        ,
//  #define ITM_SUP_t 1063                                ,                                        ,
//  #define ITM_SUP_u 1064                                ,                                        ,
//  #define ITM_SUP_v 1065                                ,                                        ,
//  #define ITM_SUP_w 1066                                ,                                        ,
//  #define ITM_SUP_x 1067                                ,                                        ,
//  #define ITM_SUP_y 1068                                ,                                        ,
//  #define ITM_SUP_z 1069                                ,                                        ,
//  #define ITM_SUB_alpha 1070                                ,                                        ,
//  #define ITM_SUB_delta 1071                                ,                                        ,
//  #define ITM_SUB_mu 1072                                ,                                        ,
//  #define ITM_SUB_SUN 1073                                ,                                        ,
//  #define ITM_SUB_EARTH 1074                                ,                                        ,
//  #define ITM_SUB_PLUS 1075                                ,                                        ,
//  #define ITM_SUB_MINUS 1076                                ,                                        ,
//  #define ITM_SUB_INFINITY 1077                                ,                                        ,
//  #define ITM_SUB_10 1078                                ,                                        ,
//  #define ITM_SUB_E_OUTLINE 1079                                ,                                        ,

//  #define ITM_SUB_A 1090                                ,                                        ,
//  #define ITM_SUB_B 1091                                ,                                        ,
//  #define ITM_SUB_C 1092                                ,                                        ,
//  #define ITM_SUB_D 1093                                ,                                        ,
//  #define ITM_SUB_E 1094                                ,                                        ,
//  #define ITM_SUB_F 1095                                ,                                        ,
//  #define ITM_SUB_G 1096                                ,                                        ,
//  #define ITM_SUB_H 1097                                ,                                        ,
//  #define ITM_SUB_I 1098                                ,                                        ,
//  #define ITM_SUB_J 1099                                ,                                        ,
//  #define ITM_SUB_K 1100                                ,                                        ,
//  #define ITM_SUB_L 1101                                ,                                        ,
//  #define ITM_SUB_M 1102                                ,                                        ,
//  #define ITM_SUB_N 1103                                ,                                        ,
//  #define ITM_SUB_O 1104                                ,                                        ,
//  #define ITM_SUB_P 1105                                ,                                        ,
//  #define ITM_SUB_Q 1106                                ,                                        ,
//  #define ITM_SUB_R 1107                                ,                                        ,
//  #define ITM_SUB_S 1108                                ,                                        ,
//  #define ITM_SUB_T 1109                                ,                                        ,
//  #define ITM_SUB_U 1110                                ,                                        ,
//  #define ITM_SUB_V 1111                                ,                                        ,
//  #define ITM_SUB_W 1112                                ,                                        ,
//  #define ITM_SUB_X 1113                                ,                                        ,
//  #define ITM_SUB_Y 1114                                ,                                        ,
//  #define ITM_SUB_Z 1115                                ,                                        ,
//  #define ITM_SUB_a 1116                                ,                                        ,
//  #define ITM_SUB_b 1117                                ,                                        ,
//  #define ITM_SUB_c 1118                                ,                                        ,
//  #define ITM_SUB_d 1119                                ,                                        ,
//  #define ITM_SUB_e 1120                                ,                                        ,
//  #define ITM_SUB_f 1121                                ,                                        ,
//  #define ITM_SUB_g 1122                                ,                                        ,
//  #define ITM_SUB_h 1123                                ,                                        ,
//  #define ITM_SUB_i 1124                                ,                                        ,
//  #define ITM_SUB_j 1125                                ,                                        ,
//  #define ITM_SUB_k 1126                                ,                                        ,
//  #define ITM_SUB_l 1127                                ,                                        ,
//  #define ITM_SUB_m 1128                                ,                                        ,
//  #define ITM_SUB_n 1129                                ,                                        ,
//  #define ITM_SUB_o 1130                                ,                                        ,
//  #define ITM_SUB_p 1131                                ,                                        ,
//  #define ITM_SUB_q 1132                                ,                                        ,
//  #define ITM_SUB_r 1133                                ,                                        ,
//  #define ITM_SUB_s 1134                                ,                                        ,
//  #define ITM_SUB_t 1135                                ,                                        ,
//  #define ITM_SUB_u 1136                                ,                                        ,
//  #define ITM_SUB_v 1137                                ,                                        ,
//  #define ITM_SUB_w 1138                                ,                                        ,
//  #define ITM_SUB_x 1139                                ,                                        ,
//  #define ITM_SUB_y 1140                                ,                                        ,
//  #define ITM_SUB_z 1141                                ,                                        ,

    {.item = 0                            ,  .gdkKey = 0                                    }
};

const deadKeysMap_t deadKeysMap[] = {
//    item           item_macron      item_acute      item_breve      item_grave      item_diaresis      item_tilde      item_circ       item_caron     item_ogonek    item_ring      item_cedilla   item_stroke    item_dot
    { ITM_A        , ITM_A_MACRON   , ITM_A_ACUTE   , ITM_A_BREVE   , ITM_A_GRAVE   , ITM_A_DIARESIS   , ITM_A_TILDE   , ITM_A_CIRC    , ITM_A        , ITM_A_OGONEK , ITM_A_RING   , ITM_A        , ITM_A        , ITM_A        },
    { ITM_C        , ITM_C          , ITM_C_ACUTE   , ITM_C         , ITM_C         , ITM_C            , ITM_C         , ITM_C         , ITM_C_CARON  , ITM_C        , ITM_C        , ITM_C_CEDILLA, ITM_C        , ITM_C        },
    { ITM_D        , ITM_D          , ITM_D         , ITM_D         , ITM_D         , ITM_D            , ITM_D         , ITM_D         , ITM_D_CARON  , ITM_D        , ITM_D        , ITM_D        , ITM_D_STROKE , ITM_D        },
    { ITM_E        , ITM_E_MACRON   , ITM_E_ACUTE   , ITM_E_BREVE   , ITM_E_GRAVE   , ITM_E_DIARESIS   , ITM_E         , ITM_E_CIRC    , ITM_E_CARON  , ITM_E_OGONEK , ITM_E        , ITM_E        , ITM_E        , ITM_E_DOT    },
    { ITM_G        , ITM_G          , ITM_G         , ITM_G_BREVE   , ITM_G         , ITM_G            , ITM_G         , ITM_G         , ITM_G        , ITM_G        , ITM_G        , ITM_G        , ITM_G        , ITM_G        },
    { ITM_I        , ITM_I_MACRON   , ITM_I_ACUTE   , ITM_I_BREVE   , ITM_I_GRAVE   , ITM_I_DIARESIS   , ITM_I         , ITM_I_CIRC    , ITM_I        , ITM_I_OGONEK , ITM_I        , ITM_I        , ITM_I        , ITM_I_DOT    },
    { ITM_L        , ITM_L          , ITM_L_ACUTE   , ITM_L         , ITM_L         , ITM_L            , ITM_L         , ITM_L         , ITM_L        , ITM_L        , ITM_L        , ITM_L        , ITM_L_STROKE , ITM_L        },
    { ITM_N        , ITM_N          , ITM_N_ACUTE   , ITM_N         , ITM_N         , ITM_N            , ITM_N_TILDE   , ITM_N         , ITM_N_CARON  , ITM_N        , ITM_N        , ITM_N        , ITM_N        , ITM_N        },
    { ITM_O        , ITM_O_MACRON   , ITM_O_ACUTE   , ITM_O_BREVE   , ITM_O_GRAVE   , ITM_O_DIARESIS   , ITM_O_TILDE   , ITM_O_CIRC    , ITM_O        , ITM_O        , ITM_O        , ITM_O        , ITM_O_STROKE , ITM_O        },
    { ITM_R        , ITM_R          , ITM_R_ACUTE   , ITM_R         , ITM_R         , ITM_R            , ITM_R         , ITM_R         , ITM_R_CARON  , ITM_R        , ITM_R        , ITM_R        , ITM_R        , ITM_R        },
    { ITM_S        , ITM_S          , ITM_S_ACUTE   , ITM_S         , ITM_S         , ITM_S            , ITM_S         , ITM_S         , ITM_S_CARON  , ITM_S        , ITM_S        , ITM_S_CEDILLA, ITM_S        , ITM_S        },
    { ITM_T        , ITM_T          , ITM_T         , ITM_T         , ITM_T         , ITM_T            , ITM_T         , ITM_T         , ITM_T_CARON  , ITM_T        , ITM_T        , ITM_T_CEDILLA, ITM_T        , ITM_T        },
    { ITM_U        , ITM_U_MACRON   , ITM_U_ACUTE   , ITM_U_BREVE   , ITM_U_GRAVE   , ITM_U_DIARESIS   , ITM_U_TILDE   , ITM_U_CIRC    , ITM_U        , ITM_U_OGONEK , ITM_U_RING   , ITM_U        , ITM_U        , ITM_U        },
    { ITM_W        , ITM_W          , ITM_W         , ITM_W         , ITM_W         , ITM_W            , ITM_W         , ITM_W_CIRC    , ITM_W        , ITM_W        , ITM_W        , ITM_W        , ITM_W        , ITM_W        },
    { ITM_Y        , ITM_Y          , ITM_Y_ACUTE   , ITM_Y         , ITM_Y         , ITM_Y_DIARESIS   , ITM_Y         , ITM_Y_CIRC    , ITM_Y        , ITM_Y        , ITM_Y        , ITM_Y        , ITM_Y        , ITM_Y        },
    { ITM_Z        , ITM_Z          , ITM_Z_ACUTE   , ITM_Z         , ITM_Z         , ITM_Z            , ITM_Z         , ITM_Z         , ITM_Z_CARON  , ITM_Z        , ITM_Z        , ITM_Z        , ITM_Z        , ITM_Z_DOT    },
    { ITM_a        , ITM_a_MACRON   , ITM_a_ACUTE   , ITM_a_BREVE   , ITM_a_GRAVE   , ITM_a_DIARESIS   , ITM_a_TILDE   , ITM_a_CIRC    , ITM_a        , ITM_a_OGONEK , ITM_a_RING   , ITM_a        , ITM_a        , ITM_a        },
    { ITM_c        , ITM_c          , ITM_c_ACUTE   , ITM_c         , ITM_c         , ITM_c            , ITM_c         , ITM_c         , ITM_c_CARON  , ITM_c        , ITM_c        , ITM_c_CEDILLA, ITM_c        , ITM_c        },
    { ITM_d        , ITM_d          , ITM_d         , ITM_d         , ITM_d         , ITM_d            , ITM_d         , ITM_d         , ITM_d        , ITM_d        , ITM_d        , ITM_d        , ITM_d_STROKE , ITM_d        },
    { ITM_e        , ITM_e_MACRON   , ITM_e_ACUTE   , ITM_e_BREVE   , ITM_e_GRAVE   , ITM_e_DIARESIS   , ITM_e         , ITM_e_CIRC    , ITM_e_CARON  , ITM_e_OGONEK , ITM_e        , ITM_e        , ITM_e        , ITM_e_DOT    },
    { ITM_g        , ITM_g          , ITM_g         , ITM_g_BREVE   , ITM_g         , ITM_g            , ITM_g         , ITM_g         , ITM_g        , ITM_g        , ITM_g        , ITM_g        , ITM_g        , ITM_g        },
    { ITM_h        , ITM_h          , ITM_h         , ITM_h         , ITM_h         , ITM_h            , ITM_h         , ITM_h         , ITM_h        , ITM_h        , ITM_h        , ITM_h        , ITM_h_STROKE , ITM_h        },
    { ITM_i        , ITM_i_MACRON   , ITM_i_ACUTE   , ITM_i_BREVE   , ITM_i_GRAVE   , ITM_i_DIARESIS   , ITM_i         , ITM_i_CIRC    , ITM_i        , ITM_i_OGONEK , ITM_i        , ITM_i        , ITM_i        , ITM_i_DOT    },
    { ITM_l        , ITM_l          , ITM_l_ACUTE   , ITM_l         , ITM_l         , ITM_l            , ITM_l         , ITM_l         , ITM_l        , ITM_l        , ITM_l        , ITM_l        , ITM_l_STROKE , ITM_l        },
    { ITM_n        , ITM_n          , ITM_n_ACUTE   , ITM_n         , ITM_n         , ITM_n            , ITM_n_TILDE   , ITM_n         , ITM_n_CARON  , ITM_n        , ITM_n        , ITM_n        , ITM_n        , ITM_n        },
    { ITM_o        , ITM_o_MACRON   , ITM_o_ACUTE   , ITM_o_BREVE   , ITM_o_GRAVE   , ITM_o_DIARESIS   , ITM_o_TILDE   , ITM_o_CIRC    , ITM_o        , ITM_o        , ITM_o        , ITM_o        , ITM_o_STROKE , ITM_o        },
    { ITM_r        , ITM_r          , ITM_r_ACUTE   , ITM_r         , ITM_r         , ITM_r            , ITM_r         , ITM_r         , ITM_r_CARON  , ITM_r        , ITM_r        , ITM_r        , ITM_r        , ITM_r        },
    { ITM_s        , ITM_s          , ITM_s_ACUTE   , ITM_s         , ITM_s         , ITM_s            , ITM_s         , ITM_s         , ITM_s_CARON  , ITM_s        , ITM_s        , ITM_s_CEDILLA, ITM_s        , ITM_s        },
    { ITM_t        , ITM_t          , ITM_t         , ITM_t         , ITM_t         , ITM_t            , ITM_t         , ITM_t         , ITM_t        , ITM_t        , ITM_t        , ITM_t_CEDILLA, ITM_t        , ITM_t        },
    { ITM_u        , ITM_u_MACRON   , ITM_u_ACUTE   , ITM_u_BREVE   , ITM_u_GRAVE   , ITM_u_DIARESIS   , ITM_u_TILDE   , ITM_u_CIRC    , ITM_u        , ITM_u_OGONEK , ITM_u_RING   , ITM_u        , ITM_u        , ITM_u        },
    { ITM_w        , ITM_w          , ITM_w         , ITM_w         , ITM_w         , ITM_w            , ITM_w         , ITM_w_CIRC    , ITM_w        , ITM_w        , ITM_w        , ITM_w        , ITM_w        , ITM_w        },
    { ITM_x        , ITM_x          , ITM_x         , ITM_x         , ITM_x         , ITM_x            , ITM_x         , ITM_x_CIRC    , ITM_x        , ITM_x        , ITM_x        , ITM_x        , ITM_x        , ITM_x        },
    { ITM_y        , ITM_y          , ITM_y_ACUTE   , ITM_y         , ITM_y         , ITM_y_DIARESIS   , ITM_y         , ITM_y_CIRC    , ITM_y        , ITM_y        , ITM_y        , ITM_y        , ITM_y        , ITM_y        },
    { ITM_z        , ITM_z          , ITM_z_ACUTE   , ITM_z         , ITM_z         , ITM_z            , ITM_z         , ITM_z         , ITM_z_CARON  , ITM_z        , ITM_z        , ITM_z        , ITM_z        , ITM_z_DOT    },
    { ITM_SPACE    , ITM_SPACE      , ITM_SPACE     , ITM_SPACE     , ITM_SPACE     , ITM_SPACE        , ITM_TILDE     , ITM_CIRCUMFLEX, ITM_SPACE    , ITM_SPACE    , ITM_RING     , ITM_SPACE    , ITM_SPACE    , ITM_DOT      },
    { 0            , 0              , 0             , 0             , 0             , 0                , 0             , 0             , 0            , 0            , 0            , 0            , 0            , 0            }
};


static int16_t _getGdkKeyItem (uint32_t gdkKey) {
  if( (GDK_KEY_Shift_L <= gdkKey && gdkKey <= GDK_KEY_Hyper_R)
        || (GDK_KEY_Home <= gdkKey && gdkKey <= GDK_KEY_Begin)
        || (GDK_KEY_F1 <= gdkKey && gdkKey <= GDK_KEY_F14)
        || (GDK_KEY_zerosubscript < gdkKey)) {
    return 0;
  }
  else if(GDK_KEY_0 <= gdkKey && gdkKey <= GDK_KEY_9 ) {
    return ITM_0 + (gdkKey - GDK_KEY_0);
  }
  else if(GDK_KEY_A <= gdkKey && gdkKey <= GDK_KEY_Z ) {
    return ITM_A + (gdkKey - GDK_KEY_A);
  }
  else if(GDK_KEY_a <= gdkKey && gdkKey <= GDK_KEY_z ) {
    return ITM_a + (gdkKey - GDK_KEY_a);
  }
  else if(GDK_KEY_KP_0 <= gdkKey && gdkKey <= GDK_KEY_KP_9 ) {
    return ITM_0 + (gdkKey - GDK_KEY_KP_0);
  }
  else if(GDK_KEY_KP_Multiply <= gdkKey && gdkKey <= GDK_KEY_KP_Divide ) {
    return ITM_ASTERISK + (gdkKey - GDK_KEY_KP_Multiply);
  }
  else if(GDK_KEY_space <= gdkKey && gdkKey <= GDK_KEY_slash ) {
    return ITM_SPACE + (gdkKey - GDK_KEY_space);
  }
  else if(GDK_KEY_colon <= gdkKey && gdkKey <= GDK_KEY_at ) {
    return ITM_COLON + (gdkKey - GDK_KEY_colon);
  }
  else if(GDK_KEY_zerosubscript <= gdkKey && gdkKey <= GDK_KEY_ninesubscript ) {
    return ITM_SUB_0 + (gdkKey - GDK_KEY_zerosubscript);
  }
  else {
    int16_t i=0;
    //printf("starting table search ...");
    while(gdkKeyMap[i].item != 0) {
      if(gdkKeyMap[i].gdkKey == gdkKey) {
        break;
      }
      i++;
    }
    //printf("_getGdkKeyItem deadKey=%i gdkKey=%i ->\n", deadKey, gdkKey);
    //printf("               %i ->\n", gdkKeyMap[i].item);
    //printf("table search done.");
    return gdkKeyMap[i].item;
  }
  return 0;
}


static int16_t _getDeadKeyItem (int16_t item) {
  //printf("::: _getDeadKeyItem %i\n",item);
  int16_t i=0;
  if(deadKey == GDK_KEY_F12) {
    switch(item){
      case ITM_A: return ITM_ALPHA; break;
      case ITM_B: return ITM_BETA; break;
      case ITM_C: return ITM_GAMMA; break;
      case ITM_D: return ITM_DELTA; break;
      case ITM_E: return ITM_EPSILON; break;
      case ITM_F: return ITM_PHI; break;
      case ITM_G: return ITM_GAMMA; break;
      case ITM_H: return ITM_CHI; break;
      case ITM_I: return ITM_IOTA; break;
      case ITM_J: return ITM_ETA; break;
      case ITM_K: return ITM_KAPPA; break;
      case ITM_L: return ITM_LAMBDA; break;
      case ITM_M: return ITM_MU; break;
      case ITM_N: return ITM_NU; break;
      case ITM_O: return ITM_OMEGA; break;
      case ITM_P: return ITM_PI; break;
      case ITM_Q: return ITM_OMICRON; break;
      case ITM_R: return ITM_RHO; break;
      case ITM_S: return ITM_SIGMA; break;
      case ITM_T: return ITM_TAU; break;
      case ITM_U: return ITM_THETA; break;
      case ITM_V: return ITM_QOPPA; break;
      case ITM_W: return ITM_PSI; break;
      case ITM_X: return ITM_XI; break;
      case ITM_Y: return ITM_UPSILON; break;
      case ITM_Z: return ITM_ZETA; break;
      case ITM_a: return ITM_alpha; break;
      case ITM_b: return ITM_beta; break;
      case ITM_c: return ITM_gamma; break;
      case ITM_d: return ITM_delta; break;
      case ITM_e: return ITM_epsilon; break;
      case ITM_f: return ITM_phi; break;
      case ITM_g: return ITM_gamma; break;
      case ITM_h: return ITM_chi; break;
      case ITM_i: return ITM_iota; break;
      case ITM_j: return ITM_eta; break;
      case ITM_k: return ITM_kappa; break;
      case ITM_l: return ITM_lambda; break;
      case ITM_m: return ITM_mu; break;
      case ITM_n: return ITM_nu; break;
      case ITM_o: return ITM_omega; break;
      case ITM_p: return ITM_pi; break;
      case ITM_q: return ITM_omicron; break;
      case ITM_r: return ITM_rho; break;
      case ITM_s: return ITM_sigma; break;
      case ITM_t: return ITM_tau; break;
      case ITM_u: return ITM_theta; break;
      case ITM_v: return ITM_qoppa; break;
      case ITM_w: return ITM_psi; break;
      case ITM_x: return ITM_xi; break;
      case ITM_y: return ITM_upsilon; break;
      case ITM_z: return ITM_zeta; break;
      default:;
    }
  }
  else while(deadKeysMap[i].item != 0) {
    if(deadKeysMap[i].item == item) {
      switch(deadKey) {
        case GDK_KEY_dead_macron :
          return deadKeysMap[i].item_macron;

        case GDK_KEY_dead_acute :
          return deadKeysMap[i].item_acute;

        case GDK_KEY_dead_breve :
          return deadKeysMap[i].item_breve;

        case GDK_KEY_dead_grave :
          return deadKeysMap[i].item_grave;

        case GDK_KEY_dead_diaeresis :
          return deadKeysMap[i].item_diaresis;

        case GDK_KEY_dead_tilde :
          return deadKeysMap[i].item_tilde;

        case GDK_KEY_dead_circumflex:
          return deadKeysMap[i].item_circ;

        case GDK_KEY_dead_ogonek :
          return deadKeysMap[i].item_ogonek;

        case GDK_KEY_dead_abovering :
          return deadKeysMap[i].item_ring;

        case GDK_KEY_dead_cedilla :
          return deadKeysMap[i].item_cedilla;

        case GDK_KEY_dead_stroke :
          return deadKeysMap[i].item_stroke;

        case GDK_KEY_dead_abovedot :
          return deadKeysMap[i].item_dot;
      }
    }
    i++;
  }
  return item;
}


static int16_t _keyCodeFromGdkKey(uint32_t gdkK) {
    uint32_t gdkKey = gdkK;
    int16_t item;
//  printf("**[DL]** _keyCodeFromGdkKey gdkKey %x capslock state %d\n", gdkKey, gdk_keymap_get_caps_lock_state(gdk_keymap_get_for_display(gdk_display_get_default())));

    if(testDeadKeys) {
      switch(gdkKey) {
        case '^' :
          gdkKey = GDK_KEY_dead_circumflex;   // ^ circumflex test dead key resulting in a -> â
          break;
        case '`' :
          gdkKey = GDK_KEY_dead_grave;        // ' grave test dead key resulting in a -> à
          break;
        case '\'' :
          gdkKey = GDK_KEY_dead_acute;        // ` grave test dead key resulting in a -> á
          break;
        case '~' :
          gdkKey = GDK_KEY_dead_tilde;        // ~ tilde above test dead key resulting in a -> ã
          break;
        case '/' :
          gdkKey = GDK_KEY_dead_stroke;       // / slash test dead key resulting in O -> Ø
          break;
        default:;
      }
    }
    switch(gdkKey) {
      //dead keys detection
      case GDK_KEY_F12  :
      case GDK_KEY_dead_macron  :
      case GDK_KEY_dead_acute  :
      case GDK_KEY_dead_breve  :
      case GDK_KEY_dead_grave  :
      case GDK_KEY_dead_diaeresis :
      case GDK_KEY_dead_tilde :
      case GDK_KEY_dead_circumflex:
      case GDK_KEY_dead_ogonek  :
      case GDK_KEY_dead_abovering :
      case GDK_KEY_dead_cedilla :
      case GDK_KEY_dead_stroke :
      case GDK_KEY_dead_abovedot :
        if(deadKey != 0 && deadKey == gdkKey && testDeadKeys) {
          //printf("Cancel deadkey\n");
          deadKey = 0;
          switch(gdkKey) {
            case GDK_KEY_dead_circumflex :
              gdkKey = '^';  // circumflex test dead key
              break;
            case GDK_KEY_dead_grave :
              gdkKey = '`'; // grave test dead key
              break;
            case GDK_KEY_dead_acute :
              gdkKey = '\'';  // grave test dead key
              break;
            case GDK_KEY_dead_tilde :
              gdkKey = '~';  // tilde above test dead key
              break;
            case GDK_KEY_dead_stroke :
              gdkKey = '/';  // slash test dead key
              break;
            default:;
          }
          showHideAlphaMode();
          refreshLcd(NULL);
          goto cancelledDeadkey;
        }
        else {
          deadKey = gdkKey;
          showHideAlphaMode();
          refreshLcd(NULL);
          return -1;
        }
      default:
        cancelledDeadkey:

        switch(gdkKey) {
          case GDK_KEY_Tab:
                    item = ITM_CR; break;
          case '`': item = ITM_NQUOTE; break;
          case '*': item = ITM_PROD_SIGN; break;
          default : item = _getGdkKeyItem(gdkKey); break;       //normal translation (also done by prior key code)
          }
        if(item == ITM_PROD_SIGN) {
          item = (getSystemFlag(FLAG_MULTx) ? ITM_CROSS : ITM_DOT);
        }
        //printf("     gdkKey=%i deadKey=%i item=%i\n",gdkKey, deadKey, item);

        if(item != 0) {
          if(deadKey != 0) {
            item = _getDeadKeyItem(item);
            deadKey = 0;
          }
        }
        return item;
      }
    }

static bool is_valid_utf8(const char *s, size_t *error_offset) {
    const unsigned char *p = (const unsigned char *)s;
    size_t i = 0;
    while (*p) {
        if (*p < 0x80) {
            p++; i++;
        } else if ((*p & 0xE0) == 0xC0) {
            if ((p[1] & 0xC0) != 0x80 || (*p & 0xFE) == 0xC0) {
                if (error_offset) *error_offset = i;
                return false;
            }
            p += 2; i += 2;
        } else if ((*p & 0xF0) == 0xE0) {
            if ((p[1] & 0xC0) != 0x80 || (p[2] & 0xC0) != 0x80) {
                if (error_offset) *error_offset = i;
                return false;
            }
            uint32_t cp = ((p[0] & 0x0F) << 12) | ((p[1] & 0x3F) << 6) | (p[2] & 0x3F);
            if (cp < 0x800 || (cp >= 0xD800 && cp <= 0xDFFF)) {
                if (error_offset) *error_offset = i;
                return false;
            }
            if (cp == 0xFFFE || cp == 0xFFFF) {
                if (error_offset) *error_offset = i;
                return false;
            }
            p += 3; i += 3;
        } else if ((*p & 0xF8) == 0xF0) {
            if ((p[1] & 0xC0) != 0x80 || (p[2] & 0xC0) != 0x80 || (p[3] & 0xC0) != 0x80) {
                if (error_offset) *error_offset = i;
                return false;
            }
            uint32_t cp = ((p[0] & 0x07) << 18) | ((p[1] & 0x3F) << 12) |
                          ((p[2] & 0x3F) << 6) | (p[3] & 0x3F);
            if (cp < 0x10000 || cp > 0x10FFFF) {
                if (error_offset) *error_offset = i;
                return false;
            }
            if ((cp & 0xFFFF) == 0xFFFE || (cp & 0xFFFF) == 0xFFFF) {
                if (error_offset) *error_offset = i;
                return false;
            }
            p += 4; i += 4;
        } else {
            if (error_offset) *error_offset = i;
            return false;
        }
    }
    return true;
}

static bool check_utf_string(const char *widget_name, const char *what, const char *s) {
    if (!s) return false;
    size_t bad_pos = 0;
    if (!is_valid_utf8(s, &bad_pos)) {
        printf("*** UTF-8 ERROR in %s %s at byte offset %zu ***\n",
               widget_name, what, bad_pos);
        printf("Corrupted string: ");
        for (const char *p = s; *p; p++) {
            printf("\\x%02x", (unsigned char)*p);
        }
        printf("\n");
        return true;
    }
    return false;
}

#if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
#define CHECK_WIDGET_CONSISTENCY_CHECK(widget_var, widget_name) do { \
    GtkWidget *widget = widget_var; \
    if (!widget) { \
        printf("Widget %s is NULL - skipping\n", widget_name); \
    } else if (!GTK_IS_WIDGET(widget)) { \
        printf("Widget %s (%p) is not a valid GTK widget - skipping\n", \
               widget_name, (void*)widget); \
    } else { \
        bool consistency_found = false; \
        \
        consistency_found |= check_utf_string(widget_name, "tooltip", \
            gtk_widget_get_tooltip_text(widget)); \
        consistency_found |= check_utf_string(widget_name, "tooltip markup", \
            gtk_widget_get_tooltip_markup(widget)); \
        \
        if (GTK_IS_BUTTON(widget)) { \
            consistency_found |= check_utf_string(widget_name, "button label", \
                gtk_button_get_label(GTK_BUTTON(widget))); \
        } \
        if (GTK_IS_LABEL(widget)) { \
            const char *text = gtk_label_get_text(GTK_LABEL(widget)); \
            consistency_found |= check_utf_string(widget_name, "label text", text); \
            const char *markup = gtk_label_get_label(GTK_LABEL(widget)); \
            if (markup && markup != text) { \
                consistency_found |= check_utf_string(widget_name, "label markup", markup); \
            } \
        } \
        \
        if (!consistency_found) { \
            if(false) printf("Checking %s: %p - OK\n", widget_name, (void*)widget); \
        } else { \
            abort(); \
        } \
    } \
} while(0)



void check_all_btn_widgets_for_consistency(void) {
    printf("Checking all btn widgets for consistency...\n");

    // Row 1 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn11, "btn11");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn12, "btn12");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn13, "btn13");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn14, "btn14");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn15, "btn15");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn16, "btn16");

    // Row 2 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn21, "btn21");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn22, "btn22");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn23, "btn23");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn24, "btn24");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn25, "btn25");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn26, "btn26");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn21A, "btn21A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn22A, "btn22A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn23A, "btn23A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn24A, "btn24A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn25A, "btn25A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn26A, "btn26A");

    // Row 3 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn31, "btn31");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn32, "btn32");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn33, "btn33");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn34, "btn34");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn35, "btn35");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn36, "btn36");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn31A, "btn31A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn32A, "btn32A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn33A, "btn33A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn34A, "btn34A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn35A, "btn35A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn36A, "btn36A");

    // Row 4 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn41, "btn41");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn42, "btn42");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn43, "btn43");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn44, "btn44");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn45, "btn45");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn42A, "btn42A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn43A, "btn43A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn44A, "btn44A");

    // Row 5 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn51, "btn51");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn52, "btn52");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn53, "btn53");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn54, "btn54");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn55, "btn55");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn52A, "btn52A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn53A, "btn53A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn54A, "btn54A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn55A, "btn55A");

    // Row 6 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn61, "btn61");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn62, "btn62");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn63, "btn63");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn64, "btn64");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn65, "btn65");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn62A, "btn62A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn63A, "btn63A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn64A, "btn64A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn65A, "btn65A");

    // Row 7 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn71, "btn71");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn72, "btn72");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn73, "btn73");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn74, "btn74");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn75, "btn75");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn71A, "btn71A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn72A, "btn72A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn73A, "btn73A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn74A, "btn74A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn75A, "btn75A");

    // Row 8 buttons
    CHECK_WIDGET_CONSISTENCY_CHECK(btn81, "btn81");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn82, "btn82");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn83, "btn83");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn84, "btn84");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn85, "btn85");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn82A, "btn82A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn83A, "btn83A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn84A, "btn84A");
    CHECK_WIDGET_CONSISTENCY_CHECK(btn85A, "btn85A");

    printf("Consistency check complete - none found.\n");
}
#endif // SIMULATOR_ON_SCREEN_KEYBOARD == 1

  static gboolean btnFnPressed_wrapper(GtkWidget *widget, GdkEvent *event, gpointer data) {
    btnFnPressed(widget, event, data);
    return FALSE;  // Let GTK continue event processing
  }

  static gboolean btnFnReleased_wrapper(GtkWidget *widget, GdkEvent *event, gpointer data) {
    btnFnReleased(widget, event, data);
    return FALSE;  // Let GTK continue event processing
  }

static guint ui_settle_timer = 0;

// Helper to clear the active flag after UI settles
static gboolean clear_ui_active_flag(gpointer data) {
    ui_is_active = FALSE;
    ui_settle_timer = 0;
    return FALSE;
}

// Single handler for all UI events
static gboolean onUIActivity(GtkWidget *w, GdkEvent *event, gpointer data) {
    ui_is_active = TRUE;

    if(ui_settle_timer) {
        g_source_remove(ui_settle_timer);
    }
    ui_settle_timer = g_timeout_add(100, clear_ui_active_flag, NULL);

    return FALSE;  // Let event continue processing
}


  /********************************************//**
  * \brief Creates the calc's GUI window with all the widgets
  *
  * \param void
  * \return void
  ***********************************************/
  void setupUI(void) {
    #if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
      int            numBytes, xPos, yPos;
      GError         *error;
      GtkCssProvider *cssProvider;
      GdkDisplay     *cssDisplay;
      GdkScreen      *cssScreen;

      prepareCssData();

      cssProvider = gtk_css_provider_new();
      cssDisplay  = gdk_display_get_default();
      cssScreen   = gdk_display_get_default_screen(cssDisplay);
      gtk_style_context_add_provider_for_screen(cssScreen, GTK_STYLE_PROVIDER(cssProvider), GTK_STYLE_PROVIDER_PRIORITY_USER);

      error = NULL;
      gtk_css_provider_load_from_data(cssProvider, cssData, -1, &error);
      if(error != NULL) {
        moreInfoOnError("In function setupUI:", "error while loading CSS style sheet " CSSFILE, NULL, NULL);
        exit(1);
      }
      g_object_unref(cssProvider);
      free(cssData);

      // Get the monitor geometry to determine whether the calc is portrait or landscape
      GdkRectangle monitor;
      gdk_monitor_get_geometry(gdk_display_get_monitor(gdk_display_get_default(), 0), &monitor);
      //gdk_screen_get_monitor_geometry(gdk_screen_get_default(), 0, &monitor);

      if(calcAutoLandscapePortrait) {
        calcLandscape = (monitor.height < 1025);
      }

      // The main window
      frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);

      if(calcLandscape) {
        gtk_window_set_default_size(GTK_WINDOW(frmCalc), 1000, 540);
      }
      else {
        #if NARROW_SCREEN == 0
          gtk_window_set_default_size(GTK_WINDOW(frmCalc),  526, 980);
        #else // NARROW_SCREEN != 0 --> 400x1280 raspberry screen
          gtk_window_set_default_size(GTK_WINDOW(frmCalc),  400, 862);
        #endif // NARROW_SCREEN == 0
      }

      gtk_widget_set_name(frmCalc, "mainWindow");
      gtk_window_set_resizable(GTK_WINDOW(frmCalc), FALSE);
      #if CALCMODEL == USER_R47
        gtk_window_set_title(GTK_WINDOW(frmCalc), "R47");                   //JM NAME
      #else
        gtk_window_set_title(GTK_WINDOW(frmCalc), "C47");                   //JM NAME
      #endif // CALCMODEL == USER_R47
      g_signal_connect(frmCalc, "destroy", G_CALLBACK(destroyCalc), NULL);
      g_signal_connect(frmCalc, "key_press_event", G_CALLBACK(keyPressed), NULL);
      g_signal_connect(frmCalc, "key_release_event", G_CALLBACK(keyReleased), NULL);  //JM CTRL

      //g_signal_connect(frmCalc, "screen-changed", G_CALLBACK(onScreenChanged), NULL); // The screen-changed event does not seem to be generated reliably.
      g_signal_connect(frmCalc, "configure-event", G_CALLBACK(onConfigureEvent), NULL);

      g_signal_connect(frmCalc, "configure-event", G_CALLBACK(onUIActivity), NULL);
      g_signal_connect(frmCalc, "button-press-event", G_CALLBACK(onUIActivity), NULL);
      g_signal_connect(frmCalc, "focus-in-event", G_CALLBACK(onUIActivity), NULL);
      g_signal_connect(frmCalc, "focus-out-event", G_CALLBACK(onUIActivity), NULL);

      #if (BIG_SCREEN_COEF > 1) || NARROW_SCREEN
        gtk_window_set_decorated(GTK_WINDOW(frmCalc), FALSE);
        gtk_window_set_position(GTK_WINDOW(frmCalc), GTK_WIN_POS_CENTER);
      #endif // BIG_SCREEN_COEF > 1 || NARROW_SCREEN

      gtk_widget_add_events(GTK_WIDGET(frmCalc), GDK_CONFIGURE);

      // Fixed grid to freely put widgets on it
      grid = gtk_fixed_new();
      gtk_container_add(GTK_CONTAINER(frmCalc), grid);



      if(modelString[0] == 0) {
        strcpy(modelString,"res/");
        strcat(modelString, isR47FAM?"R47":"C47");
        if(calcLandscape) {
          strcat(modelString,"short.png");
        }
        else {
          strcat(modelString,".png");
        }
      }
      else {
        char modelString2[50];
        strcpy(modelString2,"res/");
        strcat(modelString2,modelString);
        strcpy(modelString,modelString2);
      }


      // Backround image
      #if NARROW_SCREEN == 0
        backgroundImage = gtk_image_new_from_file(modelString);
        gtk_fixed_put(GTK_FIXED(grid), backgroundImage, 0, 0);
      #else // NARROW_SCREEN != 0 --> 400x1280 raspberry screen
        backgroundImage = gtk_image_new_from_file("res/dm42l_L1_narrow_screen.png");
        gtk_fixed_put(GTK_FIXED(grid), backgroundImage, 0, 240);
      #endif // NARROW_SCREEN == 0




      // Frame around the f key
      lblFKey2 = gtk_label_new("");
      gtk_widget_set_name(lblFKey2, "fSoftkeyArea");
      if(kbd_usr[10].primary == ITM_SHIFTf) {                        //JM only draw the thin lines under the expansion f/g keys if the origianl fg key is used.
        gtk_widget_set_size_request(lblFKey2, 61-8-2-2,  5-2);
        gtk_fixed_put(GTK_FIXED(grid), lblFKey2, 350+4+2, 563-1);
      }

      // Frame around the g key
      lblGKey2 = gtk_label_new("");
      gtk_widget_set_name(lblGKey2, "gSoftkeyArea");
      if(kbd_usr[11].primary == ITM_SHIFTg) {                        //JM only draw the thin lines under the expansion f/g keys if the origianl fg key is used.
        gtk_widget_set_size_request(lblGKey2, 61-8-2-2,  5-2);
        gtk_fixed_put(GTK_FIXED(grid), lblGKey2, 350+4+2 + DELTA_KEYS_X, 563-1);
      }

      // Frame around the Sigma+ key
      //lblEKey = gtk_label_new("");
      //gtk_widget_set_name(lblEKey,"eSoftkeyArea");
      //gtk_widget_set_size_request(lblEKey, 61-8-2-2,  5-2);
      //gtk_fixed_put(GTK_FIXED(grid), lblEKey, 350+4+2 - 4 * DELTA_KEYS_X, 563-1 - DELTA_KEYS_Y);

      // Frame around the Sigma- key
      //lblEEKey = gtk_label_new("");
      //gtk_widget_set_name(lblEEKey,"eSoftkeyArea");
      //gtk_widget_set_size_request(lblEEKey, 61-8-2-2,  5-2);
      //gtk_fixed_put(GTK_FIXED(grid), lblEEKey, 350+4+2 - 4 * DELTA_KEYS_X, 563-1 - 2*DELTA_KEYS_Y);


      // Frame around the SIN key
      //lblSKey = gtk_label_new("");
      //gtk_widget_set_name(lblSKey,"eSoftkeyArea");
      //gtk_widget_set_size_request(lblSKey, 61-8-2-2,  5-2);
      //gtk_fixed_put(GTK_FIXED(grid), lblSKey, 350+4+2 - 1 * DELTA_KEYS_X, 563-1 -0* DELTA_KEYS_Y);

      // Area for the softkeys
      //lblSoftkeyArea1 = gtk_label_new("");
      //gtk_widget_set_name(lblSoftkeyArea1, "softkeyArea");
      //gtk_widget_set_size_request(lblSoftkeyArea1, 460, 40);
      //gtk_fixed_put(GTK_FIXED(grid), lblSoftkeyArea1, 33, 72+168+50);

      //lblSoftkeyArea2 = gtk_label_new("");
      //gtk_widget_set_name(lblSoftkeyArea2, "softkeyArea");
      //gtk_widget_set_size_request(lblSoftkeyArea2, 460, 44);
      //gtk_fixed_put(GTK_FIXED(grid), lblSoftkeyArea2, 33, 72+168+50+66);



      // Behind screen
      /*lblBehindScreen = gtk_label_new("");                          //vv JM
      gtk_widget_set_name(lblBehindScreen, "behindScreen");
      gtk_widget_set_size_request(lblBehindScreen, 412, 252);
      gtk_fixed_put(GTK_FIXED(grid), lblBehindScreen, 57, 66);*/    //^^



      // LCD screen 400x240
      screen = gtk_drawing_area_new();
      gtk_widget_set_size_request(screen, SCREEN_WIDTH, SCREEN_HEIGHT);
      gtk_widget_set_tooltip_text(GTK_WIDGET(screen), "Copy to clipboard:\n CTRL+h: Screen image\n CTRL+c/x: X Register\n CTRL+d: Lettered Registers\n CTRL+a: All Registers\nCTRL+s: SNAP\n");  //JM
      #if NARROW_SCREEN == 0
        gtk_fixed_put(GTK_FIXED(grid), screen, 63, 72);
      #else // NARROW_SCREEN != 0 --> 400x1280 raspberry screen
        gtk_fixed_put(GTK_FIXED(grid), screen, 0, 0);
      #endif // NARROW_SCREEN == 0
      screenStride = cairo_format_stride_for_width(CAIRO_FORMAT_RGB24, SCREEN_WIDTH)/4;
      numBytes = screenStride * SCREEN_HEIGHT * 4;
      screenData = malloc(numBytes);
      if(screenData == NULL) {
        sprintf(errorMessage, "error allocating %d x %d = %d bytes for screenData", screenStride * 4, SCREEN_HEIGHT, numBytes);
        moreInfoOnError("In function setupUI:", errorMessage, NULL, NULL);
        exit(1);
      }

      g_signal_connect(screen, "draw", G_CALLBACK(drawScreen), NULL);


      // 1st row: F1 to F6 buttons
      if(enableFunctionKeysDisplay) {
        btn11 = gtk_button_new_with_label("F1");
        btn12 = gtk_button_new_with_label("F2");
        btn13 = gtk_button_new_with_label("F3");
        btn14 = gtk_button_new_with_label("F4");
        btn15 = gtk_button_new_with_label("F5");
        btn16 = gtk_button_new_with_label("F6");
      }
      else {
        btn11 = gtk_button_new_with_label("");
        btn12 = gtk_button_new_with_label("");
        btn13 = gtk_button_new_with_label("");
        btn14 = gtk_button_new_with_label("");
        btn15 = gtk_button_new_with_label("");
        btn16 = gtk_button_new_with_label("");
      }

      gtk_widget_set_tooltip_text(GTK_WIDGET(btn11), "F1");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn12), "F2");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn13), "F3");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn14), "F4");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn15), "F5");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn16), "F6");

      gtk_widget_set_size_request(btn11, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn12, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn13, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn14, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn15, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn16, KEY_WIDTH_1, 0);

      gtk_widget_set_name(btn11, "calcKey");
      gtk_widget_set_name(btn12, "calcKey");
      gtk_widget_set_name(btn13, "calcKey");
      gtk_widget_set_name(btn14, "calcKey");
      gtk_widget_set_name(btn15, "calcKey");
      gtk_widget_set_name(btn16, "calcKey");

      g_signal_connect(btn11, "button-press-event",   G_CALLBACK(btnFnPressed_wrapper),  "1");
      g_signal_connect(btn12, "button-press-event",   G_CALLBACK(btnFnPressed_wrapper),  "2");
      g_signal_connect(btn13, "button-press-event",   G_CALLBACK(btnFnPressed_wrapper),  "3");
      g_signal_connect(btn14, "button-press-event",   G_CALLBACK(btnFnPressed_wrapper),  "4");
      g_signal_connect(btn15, "button-press-event",   G_CALLBACK(btnFnPressed_wrapper),  "5");
      g_signal_connect(btn16, "button-press-event",   G_CALLBACK(btnFnPressed_wrapper),  "6");
      g_signal_connect(btn11, "button-release-event", G_CALLBACK(btnFnReleased_wrapper), "1");
      g_signal_connect(btn12, "button-release-event", G_CALLBACK(btnFnReleased_wrapper), "2");
      g_signal_connect(btn13, "button-release-event", G_CALLBACK(btnFnReleased_wrapper), "3");
      g_signal_connect(btn14, "button-release-event", G_CALLBACK(btnFnReleased_wrapper), "4");
      g_signal_connect(btn15, "button-release-event", G_CALLBACK(btnFnReleased_wrapper), "5");
      g_signal_connect(btn16, "button-release-event", G_CALLBACK(btnFnReleased_wrapper), "6");

      gtk_widget_set_focus_on_click(btn11, FALSE);
      gtk_widget_set_focus_on_click(btn12, FALSE);
      gtk_widget_set_focus_on_click(btn13, FALSE);
      gtk_widget_set_focus_on_click(btn14, FALSE);
      gtk_widget_set_focus_on_click(btn15, FALSE);
      gtk_widget_set_focus_on_click(btn16, FALSE);

      xPos = X_LEFT_PORTRAIT;
      yPos = Y_TOP_PORTRAIT;
      gtk_fixed_put(GTK_FIXED(grid), btn11, xPos, yPos);

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn12, xPos, yPos);

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn13, xPos, yPos);

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn14, xPos, yPos);

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn15, xPos, yPos);

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn16, xPos, yPos);

int keyCnt = 0;
int keyCntA = 0;
      // 2nd row
      btn21   = gtk_button_new();
      btn22   = gtk_button_new();
      btn23   = gtk_button_new();
      btn24   = gtk_button_new();
      btn25   = gtk_button_new();
      btn26   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn21), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "a");  //vv dr
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn22), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "v");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn23), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "q");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn24), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "o");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn25), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "l");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn26), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "x");  //^^
      btn21A  = gtk_button_new();                           //vv dr - new AIM
      btn22A  = gtk_button_new();
      btn23A  = gtk_button_new();
      btn24A  = gtk_button_new();
      btn25A  = gtk_button_new();
      btn26A  = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn21A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "A");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn22A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "B");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn23A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "C");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn24A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "D");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn25A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "E");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn26A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "F"); //^^
      lbl21F  = gtk_label_new("");
      lbl22F  = gtk_label_new("");
      lbl23F  = gtk_label_new("");
      lbl24F  = gtk_label_new("");
      lbl25F  = gtk_label_new("");
      lbl26F  = gtk_label_new("");
      lbl21Fa = gtk_label_new("");          //JM
      lbl22Fa = gtk_label_new("");          //JM
      lbl23Fa = gtk_label_new("");          //JM
      lbl24Fa = gtk_label_new("");          //JM AIM2
      lbl25Fa = gtk_label_new("");          //JM AIM2
      lbl26Fa = gtk_label_new("");          //JM AIM2
      lbl21G  = gtk_label_new("");
      lbl22G  = gtk_label_new("");
      lbl23G  = gtk_label_new("");
      lbl24G  = gtk_label_new("");
      lbl25G  = gtk_label_new("");
      lbl26G  = gtk_label_new("");
      lbl21L  = gtk_label_new("");
      lbl22L  = gtk_label_new("");
      lbl23L  = gtk_label_new("");
      lbl24L  = gtk_label_new("");
      lbl25L  = gtk_label_new("");
      lbl26L  = gtk_label_new("");
      lbl21Gr = gtk_label_new("");
      lbl22Gr = gtk_label_new("");
      lbl23Gr = gtk_label_new("");
      lbl24Gr = gtk_label_new("");
      lbl25Gr = gtk_label_new("");
      lbl26Gr = gtk_label_new("");

      gtk_widget_set_size_request(btn21,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn22,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn23,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn24,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn25,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn26,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn21A, KEY_WIDTH_1, 0);  //vv dr - new AIM
      gtk_widget_set_size_request(btn22A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn23A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn24A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn25A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn26A, KEY_WIDTH_1, 0);  //^^

      //gtk_widget_set_name(lbl21Fa,  "fShiftedUnderline"); //JMALPHA2


      g_signal_connect(btn21,  "button-press-event",   G_CALLBACK(btnPressed),  "00");
      g_signal_connect(btn22,  "button-press-event",   G_CALLBACK(btnPressed),  "01");
      g_signal_connect(btn23,  "button-press-event",   G_CALLBACK(btnPressed),  "02");
      g_signal_connect(btn24,  "button-press-event",   G_CALLBACK(btnPressed),  "03");
      g_signal_connect(btn25,  "button-press-event",   G_CALLBACK(btnPressed),  "04");
      g_signal_connect(btn26,  "button-press-event",   G_CALLBACK(btnPressed),  "05");
      g_signal_connect(btn21,  "button-release-event", G_CALLBACK(btnReleased), "00");
      g_signal_connect(btn22,  "button-release-event", G_CALLBACK(btnReleased), "01");
      g_signal_connect(btn23,  "button-release-event", G_CALLBACK(btnReleased), "02");
      g_signal_connect(btn24,  "button-release-event", G_CALLBACK(btnReleased), "03");
      g_signal_connect(btn25,  "button-release-event", G_CALLBACK(btnReleased), "04");
      g_signal_connect(btn26,  "button-release-event", G_CALLBACK(btnReleased), "05");
      g_signal_connect(btn21A, "button-press-event",   G_CALLBACK(btnPressed),  "00");    //vv dr - new AIM
      g_signal_connect(btn22A, "button-press-event",   G_CALLBACK(btnPressed),  "01");
      g_signal_connect(btn23A, "button-press-event",   G_CALLBACK(btnPressed),  "02");
      g_signal_connect(btn24A, "button-press-event",   G_CALLBACK(btnPressed),  "03");
      g_signal_connect(btn25A, "button-press-event",   G_CALLBACK(btnPressed),  "04");
      g_signal_connect(btn26A, "button-press-event",   G_CALLBACK(btnPressed),  "05");
      g_signal_connect(btn21A, "button-release-event", G_CALLBACK(btnReleased), "00");
      g_signal_connect(btn22A, "button-release-event", G_CALLBACK(btnReleased), "01");
      g_signal_connect(btn23A, "button-release-event", G_CALLBACK(btnReleased), "02");
      g_signal_connect(btn24A, "button-release-event", G_CALLBACK(btnReleased), "03");
      g_signal_connect(btn25A, "button-release-event", G_CALLBACK(btnReleased), "04");
      g_signal_connect(btn26A, "button-release-event", G_CALLBACK(btnReleased), "05");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl21F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl22F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl23F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl24F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl25F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl26F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl21G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl22G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl23G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl24G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl25G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl26G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl21Fa, 0, 0);            //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl22Fa, 0, 0);            //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl23Fa, 0, 0);            //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl24Fa, 0, 0);            //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl25Fa, 0, 0);            //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl26Fa, 0, 0);            //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl21Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl22Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl23Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl24Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl25Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl26Gr, 0, 0);

      if(calcLandscape) {
        xPos = X_LEFT_LANDSCAPE;
        yPos = Y_TOP_LANDSCAPE;
      }
      else {
        xPos = X_LEFT_PORTRAIT;
        yPos += DELTA_KEYS_Y;
      }

      gtk_fixed_put(GTK_FIXED(grid), btn21,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl21L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn21A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn22,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl22L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn22A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn23,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl23L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn23A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn24,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl24L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn24A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn25,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl25L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn25A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn26,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl26L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn26A, xPos,                         yPos);   //dr - new AIM



      // 3rd row
      btn31   = gtk_button_new();
      btn32   = gtk_button_new();
      btn33   = gtk_button_new();
      btn34   = gtk_button_new();
      btn35   = gtk_button_new();
      btn36   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn31), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "m");  //vv dr
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn32), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "r");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn33), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "d");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn34), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "s");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn35), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "c");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn36), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "t");  //^^
      btn31A  = gtk_button_new();                           //vv dr - new AIM
      btn32A  = gtk_button_new();
      btn33A  = gtk_button_new();
      btn34A  = gtk_button_new();
      btn35A  = gtk_button_new();
      btn36A  = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn31A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "G");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn32A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "H");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn33A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "I");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn34A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "J");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn35A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "K");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn36A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "L"); //^^
      lbl31F  = gtk_label_new("");
      lbl32F  = gtk_label_new("");
      lbl33F  = gtk_label_new("");
      lbl34F  = gtk_label_new("");
      lbl35F  = gtk_label_new("");
      lbl36F  = gtk_label_new("");
      lbl31Fa = gtk_label_new("");          //JM AIM2
      lbl32Fa = gtk_label_new("");          //JM AIM2
      lbl33Fa = gtk_label_new("");          //JM AIM2
      lbl34Fa = gtk_label_new("");          //JM AIM2
      lbl35Fa = gtk_label_new("");          //JM AIM2
      lbl36Fa = gtk_label_new("");          //JM AIM2
      //lbl34Fa  = gtk_label_new("");  //JMALPHA2
      //lbl35Fa  = gtk_label_new("");  //JMALPHA2
      lbl31G  = gtk_label_new("");
      lbl32G  = gtk_label_new("");
      lbl33G  = gtk_label_new("");
      lbl34G  = gtk_label_new("");
      lbl35G  = gtk_label_new("");
      lbl36G  = gtk_label_new("");

      lbl31L  = gtk_label_new("");
      lbl32L  = gtk_label_new("");
      lbl33L  = gtk_label_new("");
      lbl34L  = gtk_label_new("");
      lbl35L  = gtk_label_new("");
      lbl36L  = gtk_label_new("");

      lbl31Gr = gtk_label_new("");
      lbl32Gr = gtk_label_new("");
      lbl33Gr = gtk_label_new("");
      lbl34Gr = gtk_label_new("");
      lbl35Gr = gtk_label_new("");
      lbl36Gr = gtk_label_new("");

      gtk_widget_set_size_request(btn31,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn32,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn33,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn34,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn35,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn36,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn31A, KEY_WIDTH_1, 0);  //vv dr- new AIM
      gtk_widget_set_size_request(btn32A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn33A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn34A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn35A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn36A, KEY_WIDTH_1, 0);  //^^

      //gtk_widget_set_name(lbl33H,  "fShifted");
      //gtk_widget_set_name(lbl34H,  "fShifted");  //JM CAPS JMALPHA2
      //gtk_widget_set_name(lbl34H,  "gShifted");  //JM removed1

      g_signal_connect(btn31,  "button-press-event",   G_CALLBACK(btnPressed), "06");
      g_signal_connect(btn32,  "button-press-event",   G_CALLBACK(btnPressed), "07");
      g_signal_connect(btn33,  "button-press-event",   G_CALLBACK(btnPressed), "08");
      g_signal_connect(btn34,  "button-press-event",   G_CALLBACK(btnPressed), "09");
      g_signal_connect(btn35,  "button-press-event",   G_CALLBACK(btnPressed), "10");
      g_signal_connect(btn36,  "button-press-event",   G_CALLBACK(btnPressed), "11");
      g_signal_connect(btn31,  "button-release-event", G_CALLBACK(btnReleased), "06");
      g_signal_connect(btn32,  "button-release-event", G_CALLBACK(btnReleased), "07");
      g_signal_connect(btn33,  "button-release-event", G_CALLBACK(btnReleased), "08");
      g_signal_connect(btn34,  "button-release-event", G_CALLBACK(btnReleased), "09");
      g_signal_connect(btn35,  "button-release-event", G_CALLBACK(btnReleased), "10");
      g_signal_connect(btn36,  "button-release-event", G_CALLBACK(btnReleased), "11");
      g_signal_connect(btn31A, "button-press-event",   G_CALLBACK(btnPressed), "06");    //vv dr - new AIM
      g_signal_connect(btn32A, "button-press-event",   G_CALLBACK(btnPressed), "07");
      g_signal_connect(btn33A, "button-press-event",   G_CALLBACK(btnPressed), "08");
      g_signal_connect(btn34A, "button-press-event",   G_CALLBACK(btnPressed), "09");
      g_signal_connect(btn35A, "button-press-event",   G_CALLBACK(btnPressed), "10");
      g_signal_connect(btn36A, "button-press-event",   G_CALLBACK(btnPressed), "11");
      g_signal_connect(btn31A, "button-release-event", G_CALLBACK(btnReleased), "06");
      g_signal_connect(btn32A, "button-release-event", G_CALLBACK(btnReleased), "07");
      g_signal_connect(btn33A, "button-release-event", G_CALLBACK(btnReleased), "08");
      g_signal_connect(btn34A, "button-release-event", G_CALLBACK(btnReleased), "09");
      g_signal_connect(btn35A, "button-release-event", G_CALLBACK(btnReleased), "10");
      g_signal_connect(btn36A, "button-release-event", G_CALLBACK(btnReleased), "11");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl31F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl32F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl33F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl34F,  0, 0);
      //gtk_fixed_put(GTK_FIXED(grid), lbl34Fa, 0, 0);            //JMALPHA2
      //gtk_fixed_put(GTK_FIXED(grid), lbl35Fa, 0, 0);            //JMALPHA2
      gtk_fixed_put(GTK_FIXED(grid), lbl35F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl36F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl31Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl32Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl33Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl34Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl35Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl36Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl31G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl32G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl33G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl34G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl35G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl36G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl31Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl32Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl33Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl34Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl35Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl36Gr, 0, 0);

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y;
      gtk_fixed_put(GTK_FIXED(grid), btn31,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl31L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn31A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn32,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl32L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn32A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn33,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl33L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn33A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn34,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl34L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn34A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn35,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl35L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn35A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn36,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl36L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn36A, xPos,                         yPos);   //dr - new AIM



      // 4th row
      btn41   = gtk_button_new();
      btn42   = gtk_button_new();
      btn43   = gtk_button_new();
      btn44   = gtk_button_new();
      btn45   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn41), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "Enter");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn42), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "w");  //vv dr
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn43), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "n");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn44), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "e");  //^^
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn45), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "Backspace");
      btn42A  = gtk_button_new();
      btn43A  = gtk_button_new();
      btn44A  = gtk_button_new();
                                                                              keyCntA++;
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn42A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //    "M");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn43A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //    "N");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn44A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;keyCntA++;    //    "O"); //^^
      lbl41F  = gtk_label_new("");
      lbl42F  = gtk_label_new("");
      lbl43F  = gtk_label_new("");
      lbl44F  = gtk_label_new("");
      lbl45F  = gtk_label_new("");
      lbl41Fa = gtk_label_new("");  //JM
      lbl42Fa = gtk_label_new("");  //vv dr - new AIM
      lbl43Fa = gtk_label_new("");  //^^
      lbl44Fa = gtk_label_new("");          //JM AIM2
      lbl45Fa = gtk_label_new("");  //^^
      lbl41G  = gtk_label_new("");
      lbl42G  = gtk_label_new("");
      lbl43G  = gtk_label_new("");
      lbl44G  = gtk_label_new("");
      lbl45G  = gtk_label_new("");
      lbl41L  = gtk_label_new("");
      lbl42L  = gtk_label_new("");
      lbl43L  = gtk_label_new("");
      lbl44L  = gtk_label_new("");
      lbl45L  = gtk_label_new("");
      lbl41Gr = gtk_label_new("");
      lbl42Gr = gtk_label_new("");
      lbl43Gr = gtk_label_new("");
      lbl44Gr = gtk_label_new("");
      lbl45Gr = gtk_label_new("");

      gtk_widget_set_size_request(btn41,  KEY_WIDTH_1 + DELTA_KEYS_X, 0);
      gtk_widget_set_size_request(btn42,  KEY_WIDTH_1,                0);
      gtk_widget_set_size_request(btn43,  KEY_WIDTH_1,                0);
      gtk_widget_set_size_request(btn44,  KEY_WIDTH_1,                0);
      gtk_widget_set_size_request(btn45,  KEY_WIDTH_1,                0);
      gtk_widget_set_size_request(btn42A, KEY_WIDTH_1,                0);    //vv dr - new AIM
      gtk_widget_set_size_request(btn43A, KEY_WIDTH_1,                0);
      gtk_widget_set_size_request(btn44A, KEY_WIDTH_1,                0);    //^^


      g_signal_connect(btn41, "button-press-event",    G_CALLBACK(btnPressed),  "12");
      g_signal_connect(btn42, "button-press-event",    G_CALLBACK(btnPressed),  "13");
      g_signal_connect(btn43,  "button-press-event",   G_CALLBACK(btnPressed),  "14");
      g_signal_connect(btn44,  "button-press-event",   G_CALLBACK(btnPressed),  "15");
      g_signal_connect(btn45,  "button-press-event",   G_CALLBACK(btnPressed),  "16");
      g_signal_connect(btn41,  "button-release-event", G_CALLBACK(btnReleased), "12");
      g_signal_connect(btn42,  "button-release-event", G_CALLBACK(btnReleased), "13");
      g_signal_connect(btn43,  "button-release-event", G_CALLBACK(btnReleased), "14");
      g_signal_connect(btn44,  "button-release-event", G_CALLBACK(btnReleased), "15");
      g_signal_connect(btn45,  "button-release-event", G_CALLBACK(btnReleased), "16");
      g_signal_connect(btn42A, "button-press-event",   G_CALLBACK(btnPressed),  "13");    //vv dr - new AIM
      g_signal_connect(btn43A, "button-press-event",   G_CALLBACK(btnPressed),  "14");
      g_signal_connect(btn44A, "button-press-event",   G_CALLBACK(btnPressed),  "15");
      g_signal_connect(btn42A, "button-release-event", G_CALLBACK(btnReleased), "13");
      g_signal_connect(btn43A, "button-release-event", G_CALLBACK(btnReleased), "14");
      g_signal_connect(btn44A, "button-release-event", G_CALLBACK(btnReleased), "15");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl41F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl42F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl43F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl44F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl45F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl41Fa, 0, 0);    //JM
      gtk_fixed_put(GTK_FIXED(grid), lbl42Fa, 0, 0);    //vv dr - new AIM
      gtk_fixed_put(GTK_FIXED(grid), lbl43Fa, 0, 0);    //^^
      gtk_fixed_put(GTK_FIXED(grid), lbl44Fa, 0, 0);    //^^ AIM2
      gtk_fixed_put(GTK_FIXED(grid), lbl45Fa, 0, 0);    //^^
      gtk_fixed_put(GTK_FIXED(grid), lbl41G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl42G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl43G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl44G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl45G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl41Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl42Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl43Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl44Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl45Gr, 0, 0);

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y;
      gtk_fixed_put(GTK_FIXED(grid), btn41,  xPos,                          yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl41L, xPos + KEY_WIDTH_1 + DELTA_KEYS_X + 4, yPos + Y_OFFSET_LETTER);

      xPos += DELTA_KEYS_X*2;
      gtk_fixed_put(GTK_FIXED(grid), btn42,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl42L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn42A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn43,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl43L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn43A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn44,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl44L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      //gtk_fixed_put(GTK_FIXED(grid), lbl44P, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos -  1);
      gtk_fixed_put(GTK_FIXED(grid), btn44A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X;
      gtk_fixed_put(GTK_FIXED(grid), btn45,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl45L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);



      // 5th row
      btn51   = gtk_button_new();
      btn52   = gtk_button_new();
      btn53   = gtk_button_new();
      btn54   = gtk_button_new();
      btn55   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn51), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Up"); //JM
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn52), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "7");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn53), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "8");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn54), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "9");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn55), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "/");  //JM
      btn52A   = gtk_button_new();                          //vv dr - new AIM
      btn53A   = gtk_button_new();
      btn54A   = gtk_button_new();
      btn55A   = gtk_button_new();                                            keyCntA++;
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn52A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "P");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn53A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "Q");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn54A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "R");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn55A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "S"); //^^
      lbl51F  = gtk_label_new("");
      lbl52F  = gtk_label_new("");
      lbl53F  = gtk_label_new("");
      lbl54F  = gtk_label_new("");
      lbl55F  = gtk_label_new("");
      lbl51Fa = gtk_label_new("");
      lbl52Fa = gtk_label_new("");  //vv dr - new AIM
      lbl53Fa = gtk_label_new("");
      lbl54Fa = gtk_label_new("");
      lbl55Fa = gtk_label_new("");  //^^
      lbl51G  = gtk_label_new("");
      lbl52G  = gtk_label_new("");
      lbl53G  = gtk_label_new("");
      lbl54G  = gtk_label_new("");
      lbl55G  = gtk_label_new("");
      lbl51L  = gtk_label_new("");
      lbl52L  = gtk_label_new("");
      lbl53L  = gtk_label_new("");
      lbl54L  = gtk_label_new("");
      lbl55L  = gtk_label_new("");
      lbl51Gr = gtk_label_new("");
      lbl52Gr = gtk_label_new("");
      lbl53Gr = gtk_label_new("");
      lbl54Gr = gtk_label_new("");
      lbl55Gr = gtk_label_new("");

      gtk_widget_set_size_request(btn51,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn52,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn53,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn54,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn55,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn52A, KEY_WIDTH_2, 0);  //vv dr - new AIM
      gtk_widget_set_size_request(btn53A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn54A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn55A, KEY_WIDTH_2, 0);  //^^

      g_signal_connect(btn51,  "button-press-event",   G_CALLBACK(btnPressed),  "17");
      g_signal_connect(btn52,  "button-press-event",   G_CALLBACK(btnPressed),  "18");
      g_signal_connect(btn53,  "button-press-event",   G_CALLBACK(btnPressed),  "19");
      g_signal_connect(btn54,  "button-press-event",   G_CALLBACK(btnPressed),  "20");
      g_signal_connect(btn55,  "button-press-event",   G_CALLBACK(btnPressed),  "21");
      g_signal_connect(btn51,  "button-release-event", G_CALLBACK(btnReleased), "17");
      g_signal_connect(btn52,  "button-release-event", G_CALLBACK(btnReleased), "18");
      g_signal_connect(btn53,  "button-release-event", G_CALLBACK(btnReleased), "19");
      g_signal_connect(btn54,  "button-release-event", G_CALLBACK(btnReleased), "20");
      g_signal_connect(btn55,  "button-release-event", G_CALLBACK(btnReleased), "21");
      g_signal_connect(btn52A, "button-press-event",   G_CALLBACK(btnPressed),  "18");    //vv dr - new AIM
      g_signal_connect(btn53A, "button-press-event",   G_CALLBACK(btnPressed),  "19");
      g_signal_connect(btn54A, "button-press-event",   G_CALLBACK(btnPressed),  "20");
      g_signal_connect(btn55A, "button-press-event",   G_CALLBACK(btnPressed),  "21");
      g_signal_connect(btn52A, "button-release-event", G_CALLBACK(btnReleased), "18");
      g_signal_connect(btn53A, "button-release-event", G_CALLBACK(btnReleased), "19");
      g_signal_connect(btn54A, "button-release-event", G_CALLBACK(btnReleased), "20");
      g_signal_connect(btn55A, "button-release-event", G_CALLBACK(btnReleased), "21");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl51F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl52F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl53F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl54F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl55F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl51Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl52Fa, 0, 0);    //vv dr - new AIM
      gtk_fixed_put(GTK_FIXED(grid), lbl53Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl54Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl55Fa, 0, 0);    //^^
      gtk_fixed_put(GTK_FIXED(grid), lbl51G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl52G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl53G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl54G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl55G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl51Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl52Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl53Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl54Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl55Gr, 0, 0);

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;
      gtk_fixed_put(GTK_FIXED(grid), btn51,  xPos,                         yPos);
      //gtk_fixed_put(GTK_FIXED(grid), lbl51L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);  //JM remove arrow in text

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_fixed_put(GTK_FIXED(grid), btn52,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl52L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn52A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn53,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl53L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn53A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn54,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl54L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn54A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn55,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl55L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn55A, xPos,                         yPos);   //dr - new AIM



      // 6th row
      btn61   = gtk_button_new();
      btn62   = gtk_button_new();
      btn63   = gtk_button_new();
      btn64   = gtk_button_new();
      btn65   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn61), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Down"); //JM
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn62), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "4");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn63), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "5");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn64), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "6");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn65), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "*");  //JM
      btn62A  = gtk_button_new();                           //vv dr - new AIM
      btn63A  = gtk_button_new();
      btn64A  = gtk_button_new();
      btn65A  = gtk_button_new();                                             keyCntA++;
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn62A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "T");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn63A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "U");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn64A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "V");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn65A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "W"); //^^
      lbl61F  = gtk_label_new("");
      lbl62F  = gtk_label_new("");
      lbl63F  = gtk_label_new("");
      lbl64F  = gtk_label_new("");
      lbl65F  = gtk_label_new("");
      lbl61Fa = gtk_label_new("");
      lbl62Fa = gtk_label_new("");  //vv dr - new AIM
      lbl63Fa = gtk_label_new("");
      lbl64Fa = gtk_label_new("");
      lbl65Fa = gtk_label_new("");  //^^
      lbl61G  = gtk_label_new("");
      lbl62G  = gtk_label_new("");
      lbl63G  = gtk_label_new("");
      lbl64G  = gtk_label_new("");
      lbl65G  = gtk_label_new("");
      lbl61L  = gtk_label_new("");
      lbl62L  = gtk_label_new("");
      lbl63L  = gtk_label_new("");
      lbl64L  = gtk_label_new("");
      lbl65L  = gtk_label_new("");
      lbl61Gr = gtk_label_new("");
      lbl62Gr = gtk_label_new("");
      lbl63Gr = gtk_label_new("");
      lbl64Gr = gtk_label_new("");
      lbl65Gr = gtk_label_new("");

      gtk_widget_set_size_request(btn61,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn62,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn63,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn64,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn65,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn62A, KEY_WIDTH_2, 0);  //vv dr - new AIM
      gtk_widget_set_size_request(btn63A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn64A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn65A, KEY_WIDTH_2, 0);  //^^

      g_signal_connect(btn61,  "button-press-event",   G_CALLBACK(btnPressed),  "22");
      g_signal_connect(btn62,  "button-press-event",   G_CALLBACK(btnPressed),  "23");
      g_signal_connect(btn63,  "button-press-event",   G_CALLBACK(btnPressed),  "24");
      g_signal_connect(btn64,  "button-press-event",   G_CALLBACK(btnPressed),  "25");
      g_signal_connect(btn65,  "button-press-event",   G_CALLBACK(btnPressed),  "26");
      g_signal_connect(btn61,  "button-release-event", G_CALLBACK(btnReleased), "22");
      g_signal_connect(btn62,  "button-release-event", G_CALLBACK(btnReleased), "23");
      g_signal_connect(btn63,  "button-release-event", G_CALLBACK(btnReleased), "24");
      g_signal_connect(btn64,  "button-release-event", G_CALLBACK(btnReleased), "25");
      g_signal_connect(btn65,  "button-release-event", G_CALLBACK(btnReleased), "26");
      g_signal_connect(btn62A, "button-press-event",   G_CALLBACK(btnPressed),  "23");    //vv - new AIM
      g_signal_connect(btn63A, "button-press-event",   G_CALLBACK(btnPressed),  "24");
      g_signal_connect(btn64A, "button-press-event",   G_CALLBACK(btnPressed),  "25");
      g_signal_connect(btn65A, "button-press-event",   G_CALLBACK(btnPressed),  "26");
      g_signal_connect(btn62A, "button-release-event", G_CALLBACK(btnReleased), "23");
      g_signal_connect(btn63A, "button-release-event", G_CALLBACK(btnReleased), "24");
      g_signal_connect(btn64A, "button-release-event", G_CALLBACK(btnReleased), "25");
      g_signal_connect(btn65A, "button-release-event", G_CALLBACK(btnReleased), "26");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl61F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl62F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl63F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl64F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl61Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl62Fa, 0, 0);    //vv dr - new AIM
      gtk_fixed_put(GTK_FIXED(grid), lbl63Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl64Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl65Fa, 0, 0);    //^^
      gtk_fixed_put(GTK_FIXED(grid), lbl65F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl61G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl62G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl63G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl64G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl65G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl61Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl62Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl63Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl64Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl65Gr, 0, 0);

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;
      gtk_fixed_put(GTK_FIXED(grid), btn61,  xPos,                         yPos);
      //gtk_fixed_put(GTK_FIXED(grid), lbl61L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);  //JM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_fixed_put(GTK_FIXED(grid), btn62,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl62L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn62A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn63,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl63L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn63A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn64,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl64L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      //gtk_fixed_put(GTK_FIXED(grid), lbl64H, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos -  1);  //JM
      gtk_fixed_put(GTK_FIXED(grid), btn64A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn65,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl65L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn65A, xPos,                         yPos);   //dr - new AIM



      // 7th row
      btn71   = gtk_button_new();
      btn72   = gtk_button_new();
      btn73   = gtk_button_new();
      btn74   = gtk_button_new();
      btn75   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn71), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Shift"); //JM //jm shortcut
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn72), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "1");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn73), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "2");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn74), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "3");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn75), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "-");  //JM
      btn71A  = gtk_button_new();                           //vv dr - new AIM
      btn72A   = gtk_button_new();                          //vv dr - new AIM
      btn73A   = gtk_button_new();
      btn74A   = gtk_button_new();
      btn75A   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn71A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "f/g");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn72A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "X");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn73A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "Y");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn74A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "Z");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn75A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       "_"); //dr ^^^^ - new AIM
      lbl71F  = gtk_label_new("");
      lbl72F  = gtk_label_new("");
      lbl73F  = gtk_label_new("");
      lbl74F  = gtk_label_new("");
      lbl75F  = gtk_label_new("");
      lbl71Fa = gtk_label_new("");
      lbl72Fa = gtk_label_new("");  //vv dr - new AIM
      lbl73Fa = gtk_label_new("");
      lbl74Fa = gtk_label_new("");
      lbl75Fa = gtk_label_new("");  //^^
      lbl71G  = gtk_label_new("");
      lbl72G  = gtk_label_new("");
      lbl73G  = gtk_label_new("");
      lbl74G  = gtk_label_new("");
      lbl75G  = gtk_label_new("");
      lbl71L  = gtk_label_new("");
      lbl72L  = gtk_label_new("");
      lbl73L  = gtk_label_new("");
      lbl74L  = gtk_label_new("");
      lbl75L  = gtk_label_new("");
      lbl71Gr = gtk_label_new("");
      lbl72Gr = gtk_label_new("");
      lbl73Gr = gtk_label_new("");
      lbl74Gr = gtk_label_new("");
      lbl75Gr = gtk_label_new("");

      gtk_widget_set_size_request(btn71,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn71A, KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn72,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn73,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn74,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn75,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn72A, KEY_WIDTH_2, 0);  //vv dr - new AIM
      gtk_widget_set_size_request(btn73A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn74A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn75A, KEY_WIDTH_2, 0);  //^^


      g_signal_connect(btn71,  "button-press-event",   G_CALLBACK(btnPressed),  "27");
      g_signal_connect(btn72,  "button-press-event",   G_CALLBACK(btnPressed),  "28");
      g_signal_connect(btn73,  "button-press-event",   G_CALLBACK(btnPressed),  "29");
      g_signal_connect(btn74,  "button-press-event",   G_CALLBACK(btnPressed),  "30");
      g_signal_connect(btn75,  "button-press-event",   G_CALLBACK(btnPressed),  "31");
      g_signal_connect(btn71,  "button-release-event", G_CALLBACK(btnReleased), "27");
      g_signal_connect(btn72,  "button-release-event", G_CALLBACK(btnReleased), "28");
      g_signal_connect(btn73,  "button-release-event", G_CALLBACK(btnReleased), "29");
      g_signal_connect(btn74,  "button-release-event", G_CALLBACK(btnReleased), "30");
      g_signal_connect(btn75,  "button-release-event", G_CALLBACK(btnReleased), "31");
      g_signal_connect(btn71A, "button-press-event",   G_CALLBACK(btnPressed),  "27");
      g_signal_connect(btn72A, "button-press-event",   G_CALLBACK(btnPressed),  "28");    //vv dr - new AIM
      g_signal_connect(btn73A, "button-press-event",   G_CALLBACK(btnPressed),  "29");
      g_signal_connect(btn74A, "button-press-event",   G_CALLBACK(btnPressed),  "30");
      g_signal_connect(btn75A, "button-press-event",   G_CALLBACK(btnPressed),  "31");
      g_signal_connect(btn71A, "button-release-event", G_CALLBACK(btnReleased), "27");
      g_signal_connect(btn72A, "button-release-event", G_CALLBACK(btnReleased), "28");
      g_signal_connect(btn73A, "button-release-event", G_CALLBACK(btnReleased), "29");
      g_signal_connect(btn74A, "button-release-event", G_CALLBACK(btnReleased), "30");
      g_signal_connect(btn75A, "button-release-event", G_CALLBACK(btnReleased), "31");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl71F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl72F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl73F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl74F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl75F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl71Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl72Fa, 0, 0);    //vv dr - new AIM
      gtk_fixed_put(GTK_FIXED(grid), lbl73Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl74Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl75Fa, 0, 0);    //^^
      gtk_fixed_put(GTK_FIXED(grid), lbl71G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl72G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl73G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl74G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl75G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl71Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl72Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl73Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl74Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl75Gr, 0, 0);

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;
      gtk_fixed_put(GTK_FIXED(grid), btn71,  xPos,                         yPos);
      //gtk_fixed_put(GTK_FIXED(grid), lbl71L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER); //JM
      //gtk_fixed_put(GTK_FIXED(grid), lbl71H, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos -  1); //JM
      gtk_fixed_put(GTK_FIXED(grid), btn71A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_fixed_put(GTK_FIXED(grid), btn72,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl72L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn72A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn73,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl73L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn73A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn74,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl74L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn74A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn75,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl75L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn75A, xPos,                         yPos);   //dr - new AIM



      // 8th row
      btn81   = gtk_button_new();
      btn82   = gtk_button_new();
      btn83   = gtk_button_new();
      btn84   = gtk_button_new();
      btn85   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn81), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Esc");  //JM
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn82), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "0");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn83), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  ". ,");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn84), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "\\"); //JM Changed from Ctrl to backslash 92
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn85), isR47FAM?shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "+");  //JM
      btn82A  = gtk_button_new();                           //vv dr - new AIM
      btn83A  = gtk_button_new();
      btn84A  = gtk_button_new();
      btn85A  = gtk_button_new();                                             keyCntA++;              //
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn82A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       ":");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn83A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       ".");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn84A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       "?");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn85A), isR47FAM?shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       "Space"); //^^
      lbl81F  = gtk_label_new("");
      lbl82F  = gtk_label_new("");
      lbl83F  = gtk_label_new("");
      lbl84F  = gtk_label_new("");
      lbl85F  = gtk_label_new("");
      lbl82Fa = gtk_label_new("");  //vv dr - new AIM
      lbl83Fa = gtk_label_new("");
      lbl84Fa = gtk_label_new("");
      lbl85Fa = gtk_label_new("");  //^^
      lbl81G  = gtk_label_new("");
      lbl82G  = gtk_label_new("");
      lbl83G  = gtk_label_new("");
      lbl84G  = gtk_label_new("");
      lbl85G  = gtk_label_new("");
      lbl81L  = gtk_label_new("");
      lbl82L  = gtk_label_new("");
      lbl83L  = gtk_label_new("");
      lbl84L  = gtk_label_new("");
      lbl85L  = gtk_label_new("");
      lbl81Gr = gtk_label_new("");
      lbl82Gr = gtk_label_new("");
      lbl83Gr = gtk_label_new("");
      lbl84Gr = gtk_label_new("");
      lbl85Gr = gtk_label_new("");
      //lblOn   = gtk_label_new("ON");

      gtk_widget_set_size_request(btn81,  KEY_WIDTH_1, 0);
      gtk_widget_set_size_request(btn82,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn83,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn84,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn85,  KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn82A, KEY_WIDTH_2, 0);  //vv dr - new AIM
      gtk_widget_set_size_request(btn83A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn84A, KEY_WIDTH_2, 0);
      gtk_widget_set_size_request(btn85A, KEY_WIDTH_2, 0);  //^^

      //gtk_widget_set_name(lblOn,  "On");

      g_signal_connect(btn81,  "button-press-event",   G_CALLBACK(btnPressed),  "32");
      g_signal_connect(btn82,  "button-press-event",   G_CALLBACK(btnPressed),  "33");
      g_signal_connect(btn83,  "button-press-event",   G_CALLBACK(btnPressed),  "34");
      g_signal_connect(btn84,  "button-press-event",   G_CALLBACK(btnPressed),  "35");
      g_signal_connect(btn85,  "button-press-event",   G_CALLBACK(btnPressed),  "36");
      g_signal_connect(btn81,  "button-release-event", G_CALLBACK(btnReleased), "32");
      g_signal_connect(btn82,  "button-release-event", G_CALLBACK(btnReleased), "33");
      g_signal_connect(btn83,  "button-release-event", G_CALLBACK(btnReleased), "34");
      g_signal_connect(btn84,  "button-release-event", G_CALLBACK(btnReleased), "35");
      g_signal_connect(btn85,  "button-release-event", G_CALLBACK(btnReleased), "36");
      g_signal_connect(btn82A, "button-press-event",   G_CALLBACK(btnPressed),  "33");    //vv dr - new AIM
      g_signal_connect(btn83A, "button-press-event",   G_CALLBACK(btnPressed),  "34");
      g_signal_connect(btn84A, "button-press-event",   G_CALLBACK(btnPressed),  "35");
      g_signal_connect(btn85A, "button-press-event",   G_CALLBACK(btnPressed),  "36");
      g_signal_connect(btn82A, "button-release-event", G_CALLBACK(btnReleased), "33");
      g_signal_connect(btn83A, "button-release-event", G_CALLBACK(btnReleased), "34");
      g_signal_connect(btn84A, "button-release-event", G_CALLBACK(btnReleased), "35");
      g_signal_connect(btn85A, "button-release-event", G_CALLBACK(btnReleased), "36");  //^^

      gtk_fixed_put(GTK_FIXED(grid), lbl81F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl82F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl83F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl84F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl85F,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl82Fa, 0, 0);    //vv dr - new AIM
      gtk_fixed_put(GTK_FIXED(grid), lbl83Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl84Fa, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl85Fa, 0, 0);    //^^
      gtk_fixed_put(GTK_FIXED(grid), lbl81G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl82G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl83G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl84G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl85G,  0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl81Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl82Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl83Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl84Gr, 0, 0);
      gtk_fixed_put(GTK_FIXED(grid), lbl85Gr, 0, 0);

      xPos = calcLandscape ? X_LEFT_LANDSCAPE : X_LEFT_PORTRAIT;

      yPos += DELTA_KEYS_Y + 1;
      gtk_fixed_put(GTK_FIXED(grid), btn81,  xPos,                         yPos);
      //gtk_fixed_put(GTK_FIXED(grid), lbl81L, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);   //JM REMOVED Superfluous EXIT in Gr
      //gtk_fixed_put(GTK_FIXED(grid), lbl81H, xPos + KEY_WIDTH_1 + X_OFFSET_LETTER, yPos -  1);  //JM
      gtk_fixed_move(GTK_FIXED(grid), lbl81G, xPos+KEY_WIDTH_1+ X_OFFSET_LETTER, yPos + 38); //JM+++ REMOVED AGAIN. OFF IS MANUALLY INSERTED SOMEHOW
      //gtk_fixed_put(GTK_FIXED(grid), lblOn,   0, 0);     //JM Removed ON to 81

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_1;
      gtk_fixed_put(GTK_FIXED(grid), btn82,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl82L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn82A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn83,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl83L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn83A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn84,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl84L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn84A, xPos,                         yPos);   //dr - new AIM

      xPos += DELTA_KEYS_X + LARGE_KEY_SPACING_2;
      gtk_fixed_put(GTK_FIXED(grid), btn85,  xPos,                         yPos);
      gtk_fixed_put(GTK_FIXED(grid), lbl85L, xPos + KEY_WIDTH_2 + X_OFFSET_LETTER, yPos + Y_OFFSET_LETTER);
      gtk_fixed_put(GTK_FIXED(grid), btn85A, xPos,                         yPos);   //dr - new AIM


      // gtk_fixed_put(GTK_FIXED(grid), lblOn,   0, 0);     //JM Removed ON to 81

      gtk_widget_show_all(frmCalc);

    #else // SIMULATOR_ON_SCREEN_KEYBOARD == 0
      // The main window
      frmCalc = gtk_window_new(GTK_WINDOW_TOPLEVEL);
      gtk_window_set_default_size(GTK_WINDOW(frmCalc), SCREEN_WIDTH*BIG_SCREEN_COEF, SCREEN_HEIGHT*BIG_SCREEN_COEF);
      gtk_window_set_decorated(GTK_WINDOW(frmCalc), FALSE);
      gtk_window_set_position(GTK_WINDOW(frmCalc), GTK_WIN_POS_CENTER);

      gtk_widget_set_name(frmCalc, "mainWindow");
      gtk_window_set_resizable(GTK_WINDOW(frmCalc), FALSE);
      g_signal_connect(frmCalc, "destroy", G_CALLBACK(destroyCalc), NULL);
      g_signal_connect(frmCalc, "key_press_event", G_CALLBACK(keyPressed), NULL);
      g_signal_connect(frmCalc, "key_release_event", G_CALLBACK(keyReleased), NULL);  //JM CTRL

      gtk_widget_add_events(GTK_WIDGET(frmCalc), GDK_CONFIGURE);

      // Fixed grid to freely put widgets on it
      grid = gtk_fixed_new();
      gtk_container_add(GTK_CONTAINER(frmCalc), grid);

      // Big LCD screen
      screen = gtk_drawing_area_new();
      gtk_widget_set_size_request(screen, SCREEN_WIDTH*BIG_SCREEN_COEF, SCREEN_HEIGHT*BIG_SCREEN_COEF);
      gtk_fixed_put(GTK_FIXED(grid), screen, 0, 0);
      screenStride = cairo_format_stride_for_width(CAIRO_FORMAT_RGB24, SCREEN_WIDTH)/4;
      int numBytes = screenStride * SCREEN_HEIGHT * 4;
      screenData = malloc(numBytes);
      if(screenData == NULL) {
        sprintf(errorMessage, "error allocating %d x %d = %d bytes for screenData", screenStride * 4, SCREEN_HEIGHT, numBytes);
        moreInfoOnError("In function setupUI:", errorMessage, NULL, NULL);
        exit(1);
      }

      g_signal_connect(screen, "draw", G_CALLBACK(drawScreen), NULL);

      gtk_widget_show_all(frmCalc);
    #endif //  (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
    lcd_buffer = malloc(SCREEN_HEIGHT*(SCREEN_WIDTH/8+2)+2)+2;
    lcd_clear_buf ();

  check_all_btn_widgets_for_consistency();
  }
#endif // PC_BUILD
