// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"


//#define DEBUGMODES


extern int16_t z47_keyCodeFromGdkKey(uint32_t gdkKey); // Zig owner: gtk_gui_keymap_owned.zig
extern void z47_prepareCssData(void); // Zig owner: gtk_gui_css_owned.zig
extern void hideAllWidgets(void); // Zig owner: gtk_gui_display_owned.zig
extern void calcModeTamGui(void); // Zig owner: gtk_gui_display_owned.zig
extern void calcModeAimGui(void); // Zig owner: gtk_gui_display_owned.zig
extern void calcModeNormalGui(void); // Zig owner: gtk_gui_display_owned.zig
extern void moveLabels(void); // Zig owner: gtk_gui_display_owned.zig
extern void z47_print_label_bytes(const uint8_t* data, int length); // Zig owner: gtk_gui_label_owned.zig
extern bool_t z47_check_label_consistency(const uint8_t* lbl, const char* context); // Zig owner: gtk_gui_label_owned.zig
extern bool z47_check_utf_string(const char *widget_name, const char *what, const char *s); // Zig owner: gtk_gui_label_owned.zig


#if defined(PC_BUILD)
  #include <gtk/gtk.h>
  #include <gdk/gdk.h>

  #include "gtkGui.h"
  extern gboolean z47_btnPressed_signal(GtkWidget *widget, GdkEvent *event, gpointer data);
  extern gboolean z47_btnReleased_signal(GtkWidget *widget, GdkEvent *event, gpointer data);
  extern gboolean z47_btnFnPressed_wrapper(GtkWidget *widget, GdkEvent *event, gpointer data);
  extern gboolean z47_btnFnReleased_wrapper(GtkWidget *widget, GdkEvent *event, gpointer data);
  extern gint z47_destroyCalc(GtkWidget *widget, GdkEventAny *event, gpointer data);
  extern gboolean z47_onConfigureEvent(GtkWidget *widget, GdkEventConfigure *event, gpointer data);
  extern gboolean z47_onUIActivity(GtkWidget *widget, GdkEvent *event, gpointer data);
  extern gboolean z47_drawScreen_wrapper(GtkWidget *widget, cairo_t *cr, gpointer data);
  extern gboolean z47_keyPressed_wrapper(GtkWidget *w, GdkEventKey *event, gpointer data);
  extern gboolean z47_keyReleased_wrapper(GtkWidget *w, GdkEventKey *event, gpointer data);
  extern void z47_setupUI_preamble(void);
  extern void z47_setupUI_no_keyboard_shell(void);

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

  // The screen-changed event does not seem to be generated reliably.
  //static void onScreenChanged(GtkWidget *w, GdkScreen *oldScreen, gpointer data) {
  //  debugf("Screen changed: force a redraw");
  //  gtk_widget_queue_draw(w);
  //}


//  void btn_Clicked_Gen(bool_t shF, bool_t shG, char *st) {
//    GtkWidget *w;
//    w = NULL;
//    shiftG = shG;
//    uint8_t alphaCase_MEM = alphaCase;
//    bool_t numLock_MEM;  numLock_MEM = getSystemFlag(FLAG_NUMLOCK);  clearSystemFlag(FLAG_NUMLOCK);
//    bool_t u_mem = getSystemFlag(FLAG_USER); clearSystemFlag(FLAG_USER);
//    btnClicked(w, st);
//    if(u_mem) {
//      setSystemFlag(FLAG_USER);
//    }
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
//    if(alphaCase == AC_UPPER && !pcKeyboardCapsLockEngaged) {
//      alphaCase = AC_LOWER;
//    }
//    else if(alphaCase == AC_LOWER && !pcKeyboardCapsLockEngaged) {
//      alphaCase = AC_UPPER;
//    }
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
  extern void btnClicked_NU(GtkWidget *w, gpointer data);

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
  extern bool_t shortCutCommand(GtkWidget *w, int key, int keyCode, bool_t condition1, bool_t exitIfInNIM, bool_t disable, char *shift, char *keyForBtnClicked, uint16_t modes, int16_t requiredCalcMode2, int16_t itemForRunFunction);


//                                    w, event_keyval,  97,         shortcutProfile == USER_C47,  tam.mode ,      "f",        00",                    modes,                CM_NORMAL,                  ITM_SIGMAPLUS
  extern bool_t shortCutFNCommand(GtkWidget *w, int key, int keyCode, bool_t condition1, bool_t disable, char *shift, char *keyForBtnClicked, uint16_t modes, int16_t requiredCalcMode2, int16_t itemForRunFunction);


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


  extern void sendKey(int16_t sent);


  extern bool_t checkNormal(int16_t keyNr, int16_t item);


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



  gboolean z47_keyReleased_c_impl(GtkWidget *w, GdkEventKey *event, gpointer data) {     //JM
    if(event_keyval == event->keyval + CTRL_State) {
      event_keyval = 99999999;
    }
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

    if(C47SpecialKey_Ctrl_Released) {
      goto returnKeyReleasedFalse;
    }

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

                 if(checkNormal( 0, KEY_fg))     btnClicked(w, "00");
            else if(checkNormal(10, KEY_fg))     btnClicked(w, "10");
            else if(checkNormal(11, KEY_fg))     btnClicked(w, "11");
            else if(checkNormal( 0, ITM_SHIFTf)) btnClicked(w, "00");
            else if(checkNormal(10, ITM_SHIFTf)) btnClicked(w, "10");
            else if(checkNormal(11, ITM_SHIFTf)) btnClicked(w, "11");

            else if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary)) == ITM_SHIFTf) btnClicked(w, "10");
            else if(((getSystemFlag(FLAG_USER) ? kbd_usr[ 0].primary : kbd_std[ 0].primary)) == KEY_fg    ) btnClicked(w, "00");
            else if(((getSystemFlag(FLAG_USER) ? kbd_usr[10].primary : kbd_std[10].primary)) == KEY_fg    ) btnClicked(w, "10");
            else if(((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary)) == KEY_fg    ) btnClicked(w, "11");
            else if(((getSystemFlag(FLAG_USER) ? kbd_usr[27].primary : kbd_std[27].primary)) == KEY_fg    ) btnClicked(w, "27");
            else {
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
                 if(checkNormal( 0, KEY_fg))     btnClicked(w, "00");
            else if(checkNormal(10, KEY_fg))     btnClicked(w, "10");
            else if(checkNormal(11, KEY_fg))     btnClicked(w, "11");
            else if(checkNormal( 0, ITM_SHIFTg)) btnClicked(w, "00");
            else if(checkNormal(10, ITM_SHIFTg)) btnClicked(w, "10");
            else if(checkNormal(11, ITM_SHIFTg)) btnClicked(w, "11");

            else if((getSystemFlag(FLAG_USER) ? kbd_usr[11].primary : kbd_std[11].primary) == ITM_SHIFTg) btnClicked(w, "11");
            else {
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


  gboolean z47_keyPressed_c_impl(GtkWidget *w, GdkEventKey *event, gpointer data) {
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

    if(C47SpecialKey_Ctrl_Pressed) {
      goto continueWithOldDetections;
    }

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


    if(CTRL_State == 65536 && !C47SpecialKey_Ctrl_Pressed) {
      goto continueWithOldDetections;
    }

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
       if(shortCutCommand(w, event_key_command, GDK_KEY_a           /* a 97    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "00",        0b0100000000001101,         -1,        ITM_SIGMAPLUS ))        {goto returnKeyPressedFalse;} //               [a]ccumulate
  else if(shortCutCommand(w, event_key_command, GDK_KEY_v           /* v 118   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "01",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} //                  in[v]erse
  else if(shortCutCommand(w, event_key_command, GDK_KEY_q           /* q 113   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "02",                   0b01101,         -1,      ITM_SQUAREROOTX ))        {goto returnKeyPressedFalse;} //                     s[q]rt
  else if(shortCutCommand(w, event_key_command, GDK_KEY_o           /* o 111   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,            ITM_LOG10 ))        {goto returnKeyPressedFalse;} //                      l[o]g
  else if(shortCutCommand(w, event_key_command, GDK_KEY_l           /* l 108   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "04",                   0b01101,         -1,               ITM_LN ))        {goto returnKeyPressedFalse;} //                       [l]n
  else if(shortCutCommand(w, event_key_command, GDK_KEY_x           /* x 120   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,             FALSE,    "",   "05",                   0b01101,         -1,              ITM_XEQ ))        {goto returnKeyPressedFalse;} //                      [x]eq
  else if(shortCutCommand(w, event_key_command, GDK_KEY_m           /* m 109   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "06",                   0b01101,         -1,              ITM_STO ))        {goto returnKeyPressedFalse;} //                   [m]emory
  else if(shortCutCommand(w, event_key_command, GDK_KEY_r           /* r 114   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "07",                   0b01101,         -1,              ITM_RCL ))        {goto returnKeyPressedFalse;} //                      [r]cl
  else if(shortCutCommand(w, event_key_command, GDK_KEY_d           /* d 100   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "08",                   0b01101,         -1,            ITM_Rdown ))        {goto returnKeyPressedFalse;} //                     [d]own
  else if(shortCutCommand(w, event_key_command, GDK_KEY_s           /* s 115   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "09",                   0b01101,         -1,              ITM_sin ))        {goto returnKeyPressedFalse;} //                     [s]ine
  else if(shortCutCommand(w, event_key_command, GDK_KEY_i           /* i 105   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "09",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} //                          i
  else if(shortCutCommand(w, event_key_command, GDK_KEY_j           /* j 106   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "09",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} //                          i
  else if(shortCutCommand(w, event_key_command, GDK_KEY_k           /* k 107   */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_op_j_pol ))    {goto returnKeyPressedFalse;} //                          i
  else if(shortCutCommand(w, event_key_command, GDK_KEY_c           /* c 99    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "10",                   0b01101,         -1,              ITM_cos ))        {goto returnKeyPressedFalse;} //                   [c]osine
  else if(shortCutCommand(w, event_key_command, GDK_KEY_t           /* t 116   */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,    "",   "11",                   0b01101,         -1,              ITM_tan ))        {goto returnKeyPressedFalse;} //                  [t]angent
  else if(shortCutCommand(w, event_key_command, GDK_KEY_Return      /* ENTER 65293 */,                                                        FALSE, !EXITIFNIM,             FALSE,    "",   "12",                   0b01101,         -1,            ITM_ENTER ))        {goto returnKeyPressedFalse;} //                        key
  else if(shortCutCommand(w, event_key_command, GDK_KEY_Tab         /* tab 65289   */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "13",                   0b01101,         -1,             ITM_XexY ))        {goto returnKeyPressedFalse;} //                     s[w]ap
  else if(shortCutCommand(w, event_key_command, GDK_KEY_w           /* w 119   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "13",                   0b01101,         -1,             ITM_XexY ))        {goto returnKeyPressedFalse;} //                     s[w]ap
  else if(shortCutCommand(w, event_key_command, GDK_KEY_n           /* n 110   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "14",                   0b01101,         -1,              ITM_CHS ))        {goto returnKeyPressedFalse;} //             CHS [n]egative
  else if(shortCutCommand(w, event_key_command, GDK_KEY_e           /* e 101   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,    "",   "15",                   0b01101,         -1,         ITM_EXPONENT ))        {goto returnKeyPressedFalse;} //                 [e]xponent
  else if(shortCutCommand(w, event_key_command, GDK_KEY_greater     /* > 62    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_DRG ))        {goto returnKeyPressedFalse;} //                  [=]>D,R,G
  else if(shortCutCommand(w, event_key_command, GDK_KEY_Y           /* Y 89    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} //                      [y]^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_X           /* X 88    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,          KEY_COMPLEX ))        {goto returnKeyPressedFalse;} //                  comple[X]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_R           /* R 82    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_toREC2 ))        {goto returnKeyPressedFalse;} //                        ->R
  else if(shortCutCommand(w, event_key_command, GDK_KEY_P           /* P 80    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_toPOL2 ))        {goto returnKeyPressedFalse;} //                        ->P
  else if(shortCutCommand(w, event_key_command, GDK_KEY_p           /* p 112   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,          ITM_CONSTpi ))        {goto returnKeyPressedFalse;} //                         pi
  else if(shortCutCommand(w, event_key_command, GDK_KEY_V           /* V 86    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} //                  in[V]erse
  else if(shortCutCommand(w, event_key_command, GDK_KEY_y           /* y 121   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,          ITM_XTHROOT ))        {goto returnKeyPressedFalse;} //            xth root of [Y]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_C           /* C 67    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_arccos ))        {goto returnKeyPressedFalse;} //                arc[C]osine
  else if(shortCutCommand(w, event_key_command, GDK_KEY_S           /* S 83    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_arcsin ))        {goto returnKeyPressedFalse;} //                  arc[S]ine
  else if(shortCutCommand(w, event_key_command, GDK_KEY_T           /* T 84    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_arctan ))        {goto returnKeyPressedFalse;} //               arc[T]angent
  else if(shortCutCommand(w, event_key_command, GDK_KEY_L           /* L 76    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_EXP ))        {goto returnKeyPressedFalse;} //               anti[L]n e^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_O           /* O 79    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_10x ))        {goto returnKeyPressedFalse;} //             antil[O]g 10^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_Q           /* Q 81    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} //                   s[Q]uare
  else if(shortCutCommand(w, event_key_command, GDK_KEY_D           /* D 68    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_Rup ))        {goto returnKeyPressedFalse;} //                     Up [D]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_I           /* I 73    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_DISP ))        {goto returnKeyPressedFalse;} //                     D[I]SP
  else if(shortCutCommand(w, event_key_command, GDK_KEY_J           /* J 74    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,             -MNU_EXP ))        {goto returnKeyPressedFalse;} //                        EXP
  else if(shortCutCommand(w, event_key_command, GDK_KEY_K           /* K 75    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,             -MNU_STK ))        {goto returnKeyPressedFalse;} //                      ST[K]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_M           /* M 77    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_MODE ))        {goto returnKeyPressedFalse;} //                     [M]ODE

  else if(shortCutCommand(w, event_key_command, GDK_KEY_F           /* F 70    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,          -MNU_PREFIX ))        {goto returnKeyPressedFalse;} //                   PRE[F]IX

  else if(shortCutCommand(w, event_key_command, GDK_KEY_percent     /* % 37    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               ITM_PC ))        {goto returnKeyPressedFalse;} //                        [%]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_exclam      /* ! 33    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,            ITM_XFACT ))        {goto returnKeyPressedFalse;} //                       x[!]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_U           /* U 85    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,    "",  "-01",                    0xffff,         -1,         ITM_USERMODE ))        {goto returnKeyPressedFalse;} //                     [U]SER
  else if(shortCutCommand(w, event_key_command, GDK_KEY_apostrophe  /* ' 39    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,             FALSE,   "f",   "05",                   0b11101,         -1,              ITM_AIM ))        {goto returnKeyPressedFalse;} //                  alpha [']
  else if(shortCutCommand(w, event_key_command, GDK_KEY_G           /* G 71    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,             FALSE,   "g",   "05",                   0b01101,         -1,              ITM_GTO ))        {goto returnKeyPressedFalse;} //                      [g]TO
  else if(shortCutCommand(w, event_key_command, GDK_KEY_A           /* A 65    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_ARG ))        {goto returnKeyPressedFalse;} //                    [A]ngle
  else if(shortCutCommand(w, event_key_command, GDK_KEY_Z           /* Z 90    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_MAGNITUDE ))        {goto returnKeyPressedFalse;} //                     Si[Z]e
  else if(shortCutCommand(w, event_key_command, GDK_KEY_bar         /* | 124   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_MAGNITUDE ))        {goto returnKeyPressedFalse;} //             Size [|] (dup)
  else if(shortCutCommand(w, event_key_command, 126       /*DUP left   | 124/6 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_MAGNITUDE ))        {goto returnKeyPressedFalse;} //             Size [|] (dup)
  else if(shortCutCommand(w, event_key_command, GDK_KEY_F7          /*   65476 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_n ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_F8          /*   65477 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_u ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_F9          /*   65478 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_m ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_F10         /*   65479 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_k ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_F11         /*   65480 */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_SI_M ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_W           /* W 87    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,            ITM_LASTX ))        {goto returnKeyPressedFalse;} //                     Last X
  else if(shortCutCommand(w, event_key_command, GDK_KEY_equal       /* = 61    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} //                   .d (dup)
  else if(shortCutCommand(w, event_key_command, GDK_KEY_E           /* E 69    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               CST_09 ))        {goto returnKeyPressedFalse;} //                  Euler's E
  else if(shortCutCommand(w, event_key_command, GDK_KEY_N           /* N 78    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "f",   "35",                   0b01101,     CM_PEM,               ITM_PR ))        {goto returnKeyPressedFalse;} //                    PRGM N]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_b           /* b 98    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,     CM_PEM,              ITM_LBL ))        {goto returnKeyPressedFalse;} //                    LBL [B]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_u           /* u 117   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "f",   "16",                   0b01101,     CM_PEM,               ITM_PR ))        {goto returnKeyPressedFalse;} //                     [u]ndo
  else if(shortCutCommand(w, event_key_command, GDK_KEY_H           /* H 72    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_HOME ))        {goto returnKeyPressedFalse;} //                     [H]ome
  else if(shortCutCommand(w, event_key_command, GDK_KEY_B           /* B 66    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,          -MNU_MyMenu ))        {goto returnKeyPressedFalse;} //                 MyMenu [b]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_less        /* < 60    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_RTN ))        {goto returnKeyPressedFalse;} //                    RTN [<]
  else if(shortCutCommand(w, event_key_command, GDK_KEY_twosuperior /* ² 178   */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} //  Square on French keyboard
  else if(shortCutCommand(w, event_key_command, GDK_KEY_colon       /* : 58    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,   "g",   "00",                   0b01101,         -1,           ITM_TGLFRT ))        {goto returnKeyPressedFalse;} //                       ab/c
  else if(shortCutCommand(w, event_key_command, GDK_KEY_numbersign  /* # 35    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "01",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} //                          #
  else if(shortCutCommand(w, event_key_command, GDK_KEY_quotedbl    /* " 34  FR*/    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "01",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} //                          #
  else if(shortCutCommand(w, event_key_command, GDK_KEY_at          /* @ 64    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_eacute      /* é 233 FR*/    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_asciicircum /* ^ 94    */    ,                                  shortcutProfile == USER_C47,  EXITIFNIM,          tam.mode,   "f",   "01",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} //                      [y]^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_dollar      /* $ 36    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "g",   "02",                   0b11101,         -1,               ITM_ms ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_ampersand   /* & 38    */    ,                                  shortcutProfile == USER_C47, !EXITIFNIM,          tam.mode,   "f",   "00",                   0b11101,         -1,               ITM_RI ))        {goto returnKeyPressedFalse;} //                         >I
  else if(shortCutCommand(w, event_key_command, GDK_KEY_backslash   /* \ 92    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "35",        0b0100000000001101,         -1,              ITM_STOP))        {goto returnKeyPressedFalse;} //                      [x]eq
  else if(shortCutCommand(w, event_key_command, 96        /*DUP left   \ 92/6  */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "35",                   0b01101,         -1,              ITM_STOP))        {goto returnKeyPressedFalse;} //                      [x]eq
  else if(shortCutCommand(w, event_key_command, GDK_KEY_z           /* z 122 DE*/    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "35",                   0b01101,         -1,              ITM_STOP))        {goto returnKeyPressedFalse;} //                      [x]eq
//                                             PC_GTK3_code                                                          Logic Condition to enable line,  Close NIM,   Disabling state,  Shift/KEYno, Valid CalcMode       requiredCalcMode2     itemForRunFunction

  else if(shortCutCommand(w, event_key_command, GDK_KEY_Q           /* Q 81    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "00",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} //                   s[Q]uare
  else if(shortCutCommand(w, event_key_command, GDK_KEY_i           /* i 105   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "f",   "00",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} //                          i
  else if(shortCutCommand(w, event_key_command, GDK_KEY_j           /* j 106   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "f",   "00",                   0b11101,         -1,             ITM_op_j ))        {goto returnKeyPressedFalse;} //                          i
  else if(shortCutCommand(w, event_key_command, GDK_KEY_q           /* q 113   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "01",                   0b01101,         -1,      ITM_SQUAREROOTX ))        {goto returnKeyPressedFalse;} //                     s[q]rt
  else if(shortCutCommand(w, event_key_command, GDK_KEY_k           /* k 107   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "f",   "01",                   0b11101,         -1,             ITM_op_j_pol ))    {goto returnKeyPressedFalse;} //                       ipol
  else if(shortCutCommand(w, event_key_command, GDK_KEY_v           /* v 118   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "02",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} //                  in[v]erse
  else if(shortCutCommand(w, event_key_command, GDK_KEY_Y           /* Y 89    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} //                      [y]^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_asciicircum /* ^ 94    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} //                      [y]^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_o           /* o 111   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "04",                   0b01101,         -1,            ITM_LOG10 ))        {goto returnKeyPressedFalse;} //                      l[o]g
  else if(shortCutCommand(w, event_key_command, GDK_KEY_l           /* l 108   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "05",                   0b01101,         -1,               ITM_LN ))        {goto returnKeyPressedFalse;} //                       [l]n
  else if(shortCutCommand(w, event_key_command, GDK_KEY_m           /* m 109   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "06",                   0b01101,         -1,              ITM_STO ))        {goto returnKeyPressedFalse;} //                   [m]emory
  else if(shortCutCommand(w, event_key_command, GDK_KEY_r           /* r 114   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "07",                   0b01101,         -1,              ITM_RCL ))        {goto returnKeyPressedFalse;} //                      [r]cl
  else if(shortCutCommand(w, event_key_command, GDK_KEY_d           /* d 100   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "08",                   0b01101,         -1,            ITM_Rdown ))        {goto returnKeyPressedFalse;} //                     [d]own
  else if(shortCutCommand(w, event_key_command, GDK_KEY_greater     /* > 62    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "09",                   0b01101,         -1,              ITM_DRG ))        {goto returnKeyPressedFalse;} //                  [=]>D,R,G
  else if(shortCutCommand(w, event_key_command, GDK_KEY_f           /* f 102   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "10",                   0b01101,         -1,           ITM_SHIFTf ))        {goto returnKeyPressedFalse;} //                          f
  else if(shortCutCommand(w, event_key_command, GDK_KEY_g           /* g 103   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "11",                   0b01101,         -1,           ITM_SHIFTg ))        {goto returnKeyPressedFalse;} //                          g
  else if(shortCutCommand(w, event_key_command, GDK_KEY_E           /* E 69 EE */    ,                                                        FALSE, !EXITIFNIM,             FALSE,    "",   "12",                   0b01101,         -1,            ITM_ENTER ))        {goto returnKeyPressedFalse;} //                        key
  else if(shortCutCommand(w, event_key_command, GDK_KEY_w           /* w 119   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "13",                   0b01101,         -1,             ITM_XexY ))        {goto returnKeyPressedFalse;} //                     s[w]ap
  else if(shortCutCommand(w, event_key_command, GDK_KEY_n           /* n 110   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "14",                   0b01101,         -1,              ITM_CHS ))        {goto returnKeyPressedFalse;} //             CHS [n]egative
  else if(shortCutCommand(w, event_key_command, GDK_KEY_e           /* e 101   */    ,                                                        FALSE, !EXITIFNIM,          tam.mode,    "",   "15",                   0b01101,         -1,         ITM_EXPONENT ))        {goto returnKeyPressedFalse;} //                 [e]xponent
  else if(shortCutCommand(w, event_key_command, GDK_KEY_a           /* a 97    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,        ITM_SIGMAPLUS ))        {goto returnKeyPressedFalse;} //               [a]ccumulate
  else if(shortCutCommand(w, event_key_command, GDK_KEY_x           /* x 120   */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",   "17",                   0b01101,         -1,              ITM_XEQ ))        {goto returnKeyPressedFalse;} //                      [x]eq
  else if(shortCutCommand(w, event_key_command, GDK_KEY_apostrophe  /* ' 39    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "f",   "17",                   0b01101,         -1,              ITM_AIM ))        {goto returnKeyPressedFalse;} //                  alpha [']
  else if(shortCutCommand(w, event_key_command, GDK_KEY_G           /* G 71    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,             FALSE,   "g",   "17",                   0b01101,         -1,              ITM_GTO ))        {goto returnKeyPressedFalse;} //                      [g]TO
  else if(shortCutCommand(w, event_key_command, GDK_KEY_M           /* M 77    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,             FALSE,    "",  "-01",     0b0000011000000001101,         -1,            -MNU_PREF ))        {goto returnKeyPressedFalse;} //                   PREF [M}
  else if(shortCutCommand(w, event_key_command, GDK_KEY_s           /* s 115   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_sin ))        {goto returnKeyPressedFalse;} //                     [s]ine
  else if(shortCutCommand(w, event_key_command, GDK_KEY_c           /* c 99    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_cos ))        {goto returnKeyPressedFalse;} //                   [c]osine
  else if(shortCutCommand(w, event_key_command, GDK_KEY_t           /* t 116   */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_tan ))        {goto returnKeyPressedFalse;} //                  [t]angent
  else if(shortCutCommand(w, event_key_command, GDK_KEY_V           /* V 86    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,             ITM_1ONX ))        {goto returnKeyPressedFalse;} //                  in[v]erse
  else if(shortCutCommand(w, event_key_command, GDK_KEY_colon       /* : 58    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,   "g",   "34",                   0b01101,         -1,           ITM_TGLFRT ))        {goto returnKeyPressedFalse;} //                       ab/c
  else if(shortCutCommand(w, event_key_command, GDK_KEY_numbersign  /* # 35    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "05",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} //                          #
  else if(shortCutCommand(w, event_key_command, GDK_KEY_quotedbl    /* " 34  FR*/    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "05",                   0b11101,         -1,          ITM_HASH_JM ))        {goto returnKeyPressedFalse;} //                          #
  else if(shortCutCommand(w, event_key_command, GDK_KEY_at          /* @ 64    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_eacute      /* é 233 FR*/    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "03",                   0b11101,         -1,             ITM_dotD ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_asciicircum /* ^ 94    */    ,                                  shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",   "03",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} //                      [y]^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_dollar      /* $ 36    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "02",                   0b11101,         -1,               ITM_ms ))        {goto returnKeyPressedFalse;} //                         .d
  else if(shortCutCommand(w, event_key_command, GDK_KEY_ampersand   /* & 38    */    ,                                  shortcutProfile == USER_R47, !EXITIFNIM,          tam.mode,   "g",   "04",                   0b11101,         -1,               ITM_RI ))        {goto returnKeyPressedFalse;} //                         >I

  #if defined(RASPBERRY)
  else if(shortCutCommand(w, event_key_command, GDK_KEY_period      /* . 46    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,           ITM_SQUARE ))        {goto returnKeyPressedFalse;} //                   s[Q]uare
  else if(shortCutCommand(w, event_key_command, GDK_KEY_comma       /* , 44    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,               ITM_YX ))        {goto returnKeyPressedFalse;} //                      [y]^x
  else if(shortCutCommand(w, event_key_command, GDK_KEY_semicolon   /* ; 59    */    ,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47,  EXITIFNIM,          tam.mode,    "",  "-01",                   0b01101,         -1,              ITM_DRG ))        {goto returnKeyPressedFalse;} //                  [=]>D,R,G
  #endif // RASPBERRY

  #if defined(VERBOSEKEYS)
  else {
    printf("------------------------ Checked commands, skipping to rest of key detections\n");
  }
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
           if(shortCutCommand(w, event->keyval, GDK_KEY_Up    , shortcutProfile == USER_C47                               , !EXITIFNIM, !DISABLED, "", "17", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutCommand(w, event->keyval, GDK_KEY_Down  , shortcutProfile == USER_C47                               , !EXITIFNIM, !DISABLED, "", "22", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutCommand(w, event->keyval, GDK_KEY_Up    ,                                shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "22", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutCommand(w, event->keyval, GDK_KEY_Down  ,                                shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "27", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutFNCommand(w, event_keyval, GDK_KEY_Right, shortcutProfile == USER_C47 || shortcutProfile == USER_R47,      FALSE,            "", "1" , 0b01001, -1, 0))  { goto returnKeyPressedFalse;} //  F6 Rt
      else if(shortCutCommand(w, event->keyval, '/'           , shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "21", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutCommand(w, event->keyval, '*'           , shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "26", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutCommand(w, event->keyval, '-'           , shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "31", 0b01001, -1, 0))  { return false;}               //  [x]eq
      else if(shortCutCommand(w, event->keyval, '+'           , shortcutProfile == USER_C47 || shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "36", 0b01001, -1, 0))  { return false;}               //  [x]eq

      else if((event->keyval >= GDK_KEY_A && event->keyval <= GDK_KEY_Z) || (event->keyval >= GDK_KEY_a && event->keyval <= GDK_KEY_z)) {
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
      #endif
    }
    else if((tamArrows) && !getSystemFlag(FLAG_ALPHA)) {
      #if defined(VERBOSEKEYS)
        printf("------------------------ Checking GTO Up Dn ancillary functions event->keyval=%i, GDK_KEY_Up=%i\n",event->keyval, GDK_KEY_Up);
      #endif
           if(shortCutCommand(w, event->keyval, GDK_KEY_Up  , shortcutProfile == USER_C47                            , !EXITIFNIM, !DISABLED, "", "17", 0b01001, -1, 0)) {return false;} // [x]eq
      else if(shortCutCommand(w, event->keyval, GDK_KEY_Down, shortcutProfile == USER_C47                            , !EXITIFNIM, !DISABLED, "", "22", 0b01001, -1, 0)) {return false;} // [x]eq
      else if(shortCutCommand(w, event->keyval, GDK_KEY_Up  ,                             shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "22", 0b01001, -1, 0)) {return false;} // [x]eq
      else if(shortCutCommand(w, event->keyval, GDK_KEY_Down,                             shortcutProfile == USER_R47, !EXITIFNIM, !DISABLED, "", "27", 0b01001, -1, 0)) {return false;} // [x]eq
      #if defined(VERBOSEKEYS)
      else {
        printf("------------------------ Checked GTO Up Dn, skipping to rest of key detections\n");
      }
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

  //                       *w, int key     ,keyCode,                   condition1,                                              disable, *shift, *keyForBtnClicked, modes,  requiredCalcMode2, itemForRunFunction
       if(shortCutFNCommand(w, event_keyval, GDK_KEY_Up    /* F1 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "1",         3 << 13,         -1,          0    )) {goto returnKeyPressedFalse;} // F1 Up
  else if(shortCutFNCommand(w, event_keyval, GDK_KEY_Down  /* F2 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "2",         3 << 13,         -1,          0    )) {goto returnKeyPressedFalse;} // F2 Dn
  else if(shortCutFNCommand(w, event_keyval, GDK_KEY_Left  /* F5 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "5",         3 << 13,         -1,          0    )) {goto returnKeyPressedFalse;} // F5 Lt
  else if(shortCutFNCommand(w, event_keyval, GDK_KEY_Right /* F6 */,   shortcutProfile == USER_C47 || shortcutProfile == USER_R47, FALSE  ,    "",  "6",         3 << 13,         -1,          0    )) {goto returnKeyPressedFalse;} // F6 Rt
  #if defined(VERBOSEKEYS)
  else {
    printf("------------------------ Checked matrix arrows detection, skipping to rest of key detections\n");
  }
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
    //if(ll=='a') {
    //  ll = 65106;
    //}

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

    ll = z47_keyCodeFromGdkKey(ll);        //utilise the raw key event value, which will be contain a-z or A-Z
    if(ll > 0) {
      lastshiftF = shiftF;
      lastshiftG = shiftG;
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

        case GDK_KEY_M+65536: // Ctrl M
        case GDK_KEY_m+65536: // Ctrl m
          CTRL_State = 0;
          printf("key pressed: CTRL+m Menu copy\n");
          copyMenuToClipboard();
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
            btnClicked(w, isR47FAM ? "22" : "17");   //Up
          }
          else if(calcMode == CM_EIM) {
            btnClicked(w, isR47FAM ? "22" : "17");   //Up
          }
          else {
            if(!tam.mode) {
              btnFnClicked(w, "1");  //F1
            }
          }
          break;
        case GDK_KEY_Down:                                               //JM     // CursorDown //JM
          if(AlphaArrowsOffAndUpDn) {
            btnClicked(w, isR47FAM ? "27" : "22");   //Up
          }
          else if(calcMode == CM_EIM) {
            btnClicked(w, isR47FAM ? "27" : "22");   //Dn
          }
          else {
            btnFnClicked(w, "2");  //F2
          }
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
          }
          else if(calcModel == USER_R47bk_fg && (calcMode == CM_NORMAL || calcMode == CM_NIM)) {
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
          btnClicked(w, isR47FAM ? "22" : "17");
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
          btnClicked(w, isR47FAM ? "27" : "22");
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

extern bool z47_is_valid_utf8(const char *s, size_t *error_offset); // Zig owner: gtk_gui_label_owned.zig




//----------------------------------------------------------------------------------


bool debugLabelConsistency(const uint8_t *lbl, const char *ctx, const calcKey_t *key, GtkWidget *btn, bool showBtn) {
  if(!z47_check_label_consistency(lbl,ctx)) {
    return false;
  }
  if(key) {
    z47_print_label_bytes(lbl, 16);
    if(showBtn&&btn) {
      printf("     : key details - btn:=%s\n", get_button_name(btn));
    }
    printf("       key->primaryAim = %d ", key->primaryAim);
    printStringToConsole(indexOfItems[key->primaryAim].itemSoftmenuName, "...itemSoftmenuName =", " ");
    printStringToConsole(indexOfItems[key->primaryAim].itemSoftmenuName, "primaryAim AA:", "\n");
    printf("       key->fShiftedAim = %d ", key->fShiftedAim);
    printStringToConsole(indexOfItems[key->fShiftedAim].itemSoftmenuName, "...itemSoftmenuName =", " ");
    printStringToConsole(indexOfItems[key->fShiftedAim].itemSoftmenuName, "fShiftedAim AA:", "\n");
    printf("       key->gShiftedAim = %d ", key->gShiftedAim);
    printStringToConsole(indexOfItems[key->gShiftedAim].itemSoftmenuName, "...itemSoftmenuName =", " ");
    printStringToConsole(indexOfItems[key->gShiftedAim].itemSoftmenuName, "gShiftedAim AA:", "\n\n");
  }
  return true;
}



extern void z47_labelCaptionNormal(const calcKey_t *key, GtkWidget *button, GtkWidget *lblF, GtkWidget *lblG, GtkWidget *lblL); // Zig owner: gtk_gui_label_owned.zig


    //dr
    extern void z47_labelCaptionAimFa(const calcKey_t *key, GtkWidget *lblF); // Zig owner: gtk_gui_label_owned.zig




    extern void z47_labelCaptionAim(const calcKey_t *key, GtkWidget *button, GtkWidget *lblG, GtkWidget *lblL); // Zig owner: gtk_gui_label_owned.zig



    extern void z47_labelCaptionTam(const calcKey_t *key, GtkWidget *button); // Zig owner: gtk_gui_label_owned.zig



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




#if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
#define CHECK_WIDGET_CONSISTENCY_CHECK(widget_var, widget_name) do {                                                  \
    GtkWidget *widget = widget_var;                                                                                   \
    if(!widget) {                                                                                                     \
      printf("Widget %s is NULL - skipping\n", widget_name);                                                          \
    }                                                                                                                 \
    else if(!GTK_IS_WIDGET(widget)) {                                                                                 \
      printf("Widget %s (%p) is not a valid GTK widget - skipping\n", widget_name, (void*)widget);                    \
    }                                                                                                                 \
    else {                                                                                                            \
      bool consistency_found = false;                                                                                 \
                                                                                                                      \
      consistency_found |= z47_check_utf_string(widget_name, "tooltip", gtk_widget_get_tooltip_text(widget));             \
      consistency_found |= z47_check_utf_string(widget_name, "tooltip markup", gtk_widget_get_tooltip_markup(widget));    \
                                                                                                                      \
      if(GTK_IS_BUTTON(widget)) {                                                                                     \
        consistency_found |= z47_check_utf_string(widget_name, "button label", gtk_button_get_label(GTK_BUTTON(widget))); \
      }                                                                                                               \
      if(GTK_IS_LABEL(widget)) {                                                                                      \
        const char *text = gtk_label_get_text(GTK_LABEL(widget));                                                     \
        consistency_found |= z47_check_utf_string(widget_name, "label text", text);                                       \
        const char *markup = gtk_label_get_label(GTK_LABEL(widget));                                                  \
        if(markup && markup != text) {                                                                                \
          consistency_found |= z47_check_utf_string(widget_name, "label markup", markup);                                 \
      }                                                                                                               \
    }                                                                                                                 \
                                                                                                                      \
    if(!consistency_found) {                                                                                          \
      if(false) {                                                                                                     \
        printf("Checking %s: %p - OK\n", widget_name, (void*)widget);                                                 \
      }                                                                                                               \
    }                                                                                                                 \
    else {                                                                                                            \
      abort();                                                                                                        \
    }                                                                                                                 \
  }                                                                                                                   \
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


  /********************************************//**
  * \brief Creates the calc's GUI window with all the widgets
  *
  * \param void
  * \return void
  ***********************************************/
  void setupUI(void) {
    #if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
      int            xPos, yPos;
      GError         *error;
      GtkCssProvider *cssProvider;
      GdkDisplay     *cssDisplay;
      GdkScreen      *cssScreen;

      z47_prepareCssData();

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

      z47_setupUI_preamble();


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

      g_signal_connect(btn11, "button-press-event",   G_CALLBACK(z47_btnFnPressed_wrapper),  "1");
      g_signal_connect(btn12, "button-press-event",   G_CALLBACK(z47_btnFnPressed_wrapper),  "2");
      g_signal_connect(btn13, "button-press-event",   G_CALLBACK(z47_btnFnPressed_wrapper),  "3");
      g_signal_connect(btn14, "button-press-event",   G_CALLBACK(z47_btnFnPressed_wrapper),  "4");
      g_signal_connect(btn15, "button-press-event",   G_CALLBACK(z47_btnFnPressed_wrapper),  "5");
      g_signal_connect(btn16, "button-press-event",   G_CALLBACK(z47_btnFnPressed_wrapper),  "6");
      g_signal_connect(btn11, "button-release-event", G_CALLBACK(z47_btnFnReleased_wrapper), "1");
      g_signal_connect(btn12, "button-release-event", G_CALLBACK(z47_btnFnReleased_wrapper), "2");
      g_signal_connect(btn13, "button-release-event", G_CALLBACK(z47_btnFnReleased_wrapper), "3");
      g_signal_connect(btn14, "button-release-event", G_CALLBACK(z47_btnFnReleased_wrapper), "4");
      g_signal_connect(btn15, "button-release-event", G_CALLBACK(z47_btnFnReleased_wrapper), "5");
      g_signal_connect(btn16, "button-release-event", G_CALLBACK(z47_btnFnReleased_wrapper), "6");

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn21), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "a");  //vv dr
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn22), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "v");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn23), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "q");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn24), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "o");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn25), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "l");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn26), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;    //  "x");  //^^
      btn21A  = gtk_button_new();                           //vv dr - new AIM
      btn22A  = gtk_button_new();
      btn23A  = gtk_button_new();
      btn24A  = gtk_button_new();
      btn25A  = gtk_button_new();
      btn26A  = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn21A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "A");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn22A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "B");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn23A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "C");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn24A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "D");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn25A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "E");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn26A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //   "F"); //^^
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


      g_signal_connect(btn21,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "00");
      g_signal_connect(btn22,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "01");
      g_signal_connect(btn23,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "02");
      g_signal_connect(btn24,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "03");
      g_signal_connect(btn25,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "04");
      g_signal_connect(btn26,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "05");
      g_signal_connect(btn21,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "00");
      g_signal_connect(btn22,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "01");
      g_signal_connect(btn23,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "02");
      g_signal_connect(btn24,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "03");
      g_signal_connect(btn25,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "04");
      g_signal_connect(btn26,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "05");
      g_signal_connect(btn21A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "00");    //vv dr - new AIM
      g_signal_connect(btn22A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "01");
      g_signal_connect(btn23A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "02");
      g_signal_connect(btn24A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "03");
      g_signal_connect(btn25A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "04");
      g_signal_connect(btn26A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "05");
      g_signal_connect(btn21A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "00");
      g_signal_connect(btn22A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "01");
      g_signal_connect(btn23A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "02");
      g_signal_connect(btn24A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "03");
      g_signal_connect(btn25A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "04");
      g_signal_connect(btn26A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "05");  //^^

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn31), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "m");  //vv dr
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn32), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "r");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn33), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "d");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn34), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "s");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn35), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "c");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn36), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "t");  //^^
      btn31A  = gtk_button_new();                           //vv dr - new AIM
      btn32A  = gtk_button_new();
      btn33A  = gtk_button_new();
      btn34A  = gtk_button_new();
      btn35A  = gtk_button_new();
      btn36A  = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn31A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "G");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn32A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "H");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn33A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "I");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn34A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "J");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn35A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "K");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn36A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;    //    "L"); //^^
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

      g_signal_connect(btn31,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "06");
      g_signal_connect(btn32,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "07");
      g_signal_connect(btn33,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "08");
      g_signal_connect(btn34,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "09");
      g_signal_connect(btn35,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "10");
      g_signal_connect(btn36,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "11");
      g_signal_connect(btn31,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "06");
      g_signal_connect(btn32,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "07");
      g_signal_connect(btn33,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "08");
      g_signal_connect(btn34,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "09");
      g_signal_connect(btn35,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "10");
      g_signal_connect(btn36,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "11");
      g_signal_connect(btn31A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "06");    //vv dr - new AIM
      g_signal_connect(btn32A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "07");
      g_signal_connect(btn33A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "08");
      g_signal_connect(btn34A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "09");
      g_signal_connect(btn35A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "10");
      g_signal_connect(btn36A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal), "11");
      g_signal_connect(btn31A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "06");
      g_signal_connect(btn32A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "07");
      g_signal_connect(btn33A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "08");
      g_signal_connect(btn34A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "09");
      g_signal_connect(btn35A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "10");
      g_signal_connect(btn36A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "11");  //^^

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn41), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "Enter");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn42), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "w");  //vv dr
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn43), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "n");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn44), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "e");  //^^
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn45), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;// "Backspace");
      btn42A  = gtk_button_new();
      btn43A  = gtk_button_new();
      btn44A  = gtk_button_new();
                                                                                keyCntA++;
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn42A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //    "M");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn43A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //    "N");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn44A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;keyCntA++;    //    "O"); //^^
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


      g_signal_connect(btn41, "button-press-event",    G_CALLBACK(z47_btnPressed_signal),  "12");
      g_signal_connect(btn42, "button-press-event",    G_CALLBACK(z47_btnPressed_signal),  "13");
      g_signal_connect(btn43,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "14");
      g_signal_connect(btn44,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "15");
      g_signal_connect(btn45,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "16");
      g_signal_connect(btn41,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "12");
      g_signal_connect(btn42,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "13");
      g_signal_connect(btn43,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "14");
      g_signal_connect(btn44,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "15");
      g_signal_connect(btn45,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "16");
      g_signal_connect(btn42A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "13");    //vv dr - new AIM
      g_signal_connect(btn43A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "14");
      g_signal_connect(btn44A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "15");
      g_signal_connect(btn42A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "13");
      g_signal_connect(btn43A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "14");
      g_signal_connect(btn44A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "15");  //^^

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn51), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Up"); //JM
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn52), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "7");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn53), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "8");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn54), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "9");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn55), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "/");  //JM
      btn52A   = gtk_button_new();                          //vv dr - new AIM
      btn53A   = gtk_button_new();
      btn54A   = gtk_button_new();
      btn55A   = gtk_button_new();                                              keyCntA++;
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn52A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "P");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn53A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "Q");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn54A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "R");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn55A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //     "S"); //^^
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

      g_signal_connect(btn51,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "17");
      g_signal_connect(btn52,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "18");
      g_signal_connect(btn53,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "19");
      g_signal_connect(btn54,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "20");
      g_signal_connect(btn55,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "21");
      g_signal_connect(btn51,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "17");
      g_signal_connect(btn52,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "18");
      g_signal_connect(btn53,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "19");
      g_signal_connect(btn54,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "20");
      g_signal_connect(btn55,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "21");
      g_signal_connect(btn52A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "18");    //vv dr - new AIM
      g_signal_connect(btn53A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "19");
      g_signal_connect(btn54A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "20");
      g_signal_connect(btn55A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "21");
      g_signal_connect(btn52A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "18");
      g_signal_connect(btn53A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "19");
      g_signal_connect(btn54A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "20");
      g_signal_connect(btn55A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "21");  //^^

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn61), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Down"); //JM
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn62), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "4");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn63), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "5");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn64), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "6");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn65), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "*");  //JM
      btn62A  = gtk_button_new();                           //vv dr - new AIM
      btn63A  = gtk_button_new();
      btn64A  = gtk_button_new();
      btn65A  = gtk_button_new();                                               keyCntA++;
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn62A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "T");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn63A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "U");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn64A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "V");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn65A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "W"); //^^
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

      g_signal_connect(btn61,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "22");
      g_signal_connect(btn62,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "23");
      g_signal_connect(btn63,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "24");
      g_signal_connect(btn64,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "25");
      g_signal_connect(btn65,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "26");
      g_signal_connect(btn61,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "22");
      g_signal_connect(btn62,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "23");
      g_signal_connect(btn63,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "24");
      g_signal_connect(btn64,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "25");
      g_signal_connect(btn65,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "26");
      g_signal_connect(btn62A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "23");    //vv - new AIM
      g_signal_connect(btn63A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "24");
      g_signal_connect(btn64A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "25");
      g_signal_connect(btn65A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "26");
      g_signal_connect(btn62A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "23");
      g_signal_connect(btn63A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "24");
      g_signal_connect(btn64A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "25");
      g_signal_connect(btn65A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "26");  //^^

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn71), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Shift"); //JM //jm shortcut
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn72), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "1");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn73), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "2");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn74), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "3");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn75), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "-");  //JM
      btn71A  = gtk_button_new();                           //vv dr - new AIM
      btn72A   = gtk_button_new();                          //vv dr - new AIM
      btn73A   = gtk_button_new();
      btn74A   = gtk_button_new();
      btn75A   = gtk_button_new();
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn71A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "f/g");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn72A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "X");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn73A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "Y");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn74A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //      "Z");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn75A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       "_"); //dr ^^^^ - new AIM
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


      g_signal_connect(btn71,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "27");
      g_signal_connect(btn72,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "28");
      g_signal_connect(btn73,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "29");
      g_signal_connect(btn74,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "30");
      g_signal_connect(btn75,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "31");
      g_signal_connect(btn71,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "27");
      g_signal_connect(btn72,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "28");
      g_signal_connect(btn73,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "29");
      g_signal_connect(btn74,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "30");
      g_signal_connect(btn75,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "31");
      g_signal_connect(btn71A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "27");
      g_signal_connect(btn72A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "28");    //vv dr - new AIM
      g_signal_connect(btn73A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "29");
      g_signal_connect(btn74A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "30");
      g_signal_connect(btn75A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "31");
      g_signal_connect(btn71A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "27");
      g_signal_connect(btn72A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "28");
      g_signal_connect(btn73A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "29");
      g_signal_connect(btn74A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "30");
      g_signal_connect(btn75A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "31");  //^^

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
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn81), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "Esc");  //JM
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn82), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "0");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn83), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  ". ,");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn84), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "\\"); //JM Changed from Ctrl to backslash 92
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn85), isR47FAM ? shortCutString[keyCnt].R47 : shortCutString[keyCnt].C47); keyCnt++;//  "+");  //JM
      btn82A  = gtk_button_new();                           //vv dr - new AIM
      btn83A  = gtk_button_new();
      btn84A  = gtk_button_new();
      btn85A  = gtk_button_new();                                               keyCntA++;              //
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn82A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       ":");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn83A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       ".");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn84A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       "?");
      gtk_widget_set_tooltip_text(GTK_WIDGET(btn85A), isR47FAM ? shortCutString[keyCntA].R47A : shortCutString[keyCntA].C47A); keyCntA++;              //       "Space"); //^^
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

      g_signal_connect(btn81,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "32");
      g_signal_connect(btn82,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "33");
      g_signal_connect(btn83,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "34");
      g_signal_connect(btn84,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "35");
      g_signal_connect(btn85,  "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "36");
      g_signal_connect(btn81,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "32");
      g_signal_connect(btn82,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "33");
      g_signal_connect(btn83,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "34");
      g_signal_connect(btn84,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "35");
      g_signal_connect(btn85,  "button-release-event", G_CALLBACK(z47_btnReleased_signal), "36");
      g_signal_connect(btn82A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "33");    //vv dr - new AIM
      g_signal_connect(btn83A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "34");
      g_signal_connect(btn84A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "35");
      g_signal_connect(btn85A, "button-press-event",   G_CALLBACK(z47_btnPressed_signal),  "36");
      g_signal_connect(btn82A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "33");
      g_signal_connect(btn83A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "34");
      g_signal_connect(btn84A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "35");
      g_signal_connect(btn85A, "button-release-event", G_CALLBACK(z47_btnReleased_signal), "36");  //^^

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
      z47_setupUI_no_keyboard_shell();

      gtk_widget_show_all(frmCalc);
    #endif //  (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
    lcd_buffer = malloc(SCREEN_HEIGHT*(SCREEN_WIDTH/8+2)+2)+2;
    lcd_clear_buf ();

  check_all_btn_widgets_for_consistency();
  }
#endif // PC_BUILD
