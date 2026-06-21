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

  extern GtkWidget *grid;
  #if (SIMULATOR_ON_SCREEN_KEYBOARD == 1)
    extern GtkWidget *backgroundImage;
    extern GtkWidget *lblFKey2;
    extern GtkWidget *lblGKey2;
    //GtkWidget *lblEKey;
    //GtkWidget *lblEEKey;
    //GtkWidget *lblSKey;
    extern GtkWidget *lblBehindScreen;

    extern GtkWidget *btn11,   *btn12,   *btn13,   *btn14,   *btn15,   *btn16;
    extern GtkWidget *btn21,   *btn22,   *btn23,   *btn24,   *btn25,   *btn26;
    extern GtkWidget *lbl21F,  *lbl22F,  *lbl23F,  *lbl24F,  *lbl25F,  *lbl26F;
    extern GtkWidget *lbl21G,  *lbl22G,  *lbl23G,  *lbl24G,  *lbl25G,  *lbl26G;
    extern GtkWidget *lbl21L,  *lbl22L,  *lbl23L,  *lbl24L,  *lbl25L,  *lbl26L;
    extern GtkWidget *lbl21Gr, *lbl22Gr, *lbl23Gr, *lbl24Gr, *lbl25Gr, *lbl26Gr;
    extern GtkWidget *btn21A,  *btn22A,  *btn23A,  *btn24A,  *btn25A,  *btn26A;    //dr - new AIM
    extern GtkWidget *lbl21Fa, *lbl22Fa, *lbl23Fa, *lbl24Fa, *lbl25Fa, *lbl26Fa;                                 //JM

    extern GtkWidget *btn31,   *btn32,   *btn33,   *btn34,   *btn35,   *btn36;
    extern GtkWidget *lbl31F,  *lbl32F,  *lbl33F,  *lbl34F,  *lbl35F,  *lbl36F;
    extern GtkWidget *lbl31G,  *lbl32G,  *lbl33G,  *lbl34G,  *lbl35G,  *lbl36G;
    extern GtkWidget *lbl31L,  *lbl32L,  *lbl33L,  *lbl34L,  *lbl35L,  *lbl36L;
    extern GtkWidget *lbl31Gr, *lbl32Gr, *lbl33Gr, *lbl34Gr, *lbl35Gr, *lbl36Gr;
    extern GtkWidget *btn31A,  *btn32A,  *btn33A,  *btn34A,  *btn35A,  *btn36A;    //dr - new AIM
    extern GtkWidget *lbl31Fa, *lbl32Fa, *lbl33Fa,  *lbl34Fa, *lbl35Fa, *lbl36Fa;                                 //JMALPHA2

    extern GtkWidget *btn41,   *btn42,   *btn43,   *btn44,   *btn45;
    extern GtkWidget *lbl41F,  *lbl42F,  *lbl43F,  *lbl44F,  *lbl45F;
    extern GtkWidget *lbl41G,  *lbl42G,  *lbl43G,  *lbl44G,  *lbl45G;
    extern GtkWidget *lbl41L,  *lbl42L,  *lbl43L,  *lbl44L,  *lbl45L;
    extern GtkWidget *lbl41Gr, *lbl42Gr, *lbl43Gr, *lbl44Gr, *lbl45Gr;
    extern GtkWidget           *btn42A,  *btn43A,  *btn44A;                        //vv dr - new AIM
    extern GtkWidget *lbl41Fa, *lbl42Fa, *lbl43Fa, *lbl44Fa, *lbl45Fa;                                 //^^

    extern GtkWidget *btn51,   *btn52,   *btn53,   *btn54,   *btn55;
    extern GtkWidget *lbl51F,  *lbl52F,  *lbl53F,  *lbl54F,  *lbl55F;
    extern GtkWidget *lbl51G,  *lbl52G,  *lbl53G,  *lbl54G,  *lbl55G;
    extern GtkWidget *lbl51L,  *lbl52L,  *lbl53L,  *lbl54L,  *lbl55L;
    extern GtkWidget *lbl51Gr, *lbl52Gr, *lbl53Gr, *lbl54Gr, *lbl55Gr;
    extern GtkWidget           *btn52A,  *btn53A,  *btn54A,  *btn55A;              //vv dr - new AIM
    extern GtkWidget *lbl51Fa, *lbl52Fa, *lbl53Fa, *lbl54Fa, *lbl55Fa;             //^^

    extern GtkWidget *btn61,   *btn62,   *btn63,   *btn64,   *btn65;
    extern GtkWidget *lbl61F,  *lbl62F,  *lbl63F,  *lbl64F,  *lbl65F;
    extern GtkWidget *lbl61G,  *lbl62G,  *lbl63G,  *lbl64G,  *lbl65G;
    extern GtkWidget *lbl61L,  *lbl62L,  *lbl63L,  *lbl64L,  *lbl65L;
    extern GtkWidget *lbl61Gr, *lbl62Gr, *lbl63Gr, *lbl64Gr, *lbl65Gr;
    extern GtkWidget           *btn62A,  *btn63A,  *btn64A,  *btn65A;              //vv dr - new AIM
    extern GtkWidget *lbl61Fa, *lbl62Fa, *lbl63Fa, *lbl64Fa, *lbl65Fa;             //^^

    extern GtkWidget *btn71,   *btn72,   *btn73,   *btn74,   *btn75;
    extern GtkWidget *lbl71F,  *lbl72F,  *lbl73F,  *lbl74F,  *lbl75F;
    extern GtkWidget *lbl71G,  *lbl72G,  *lbl73G,  *lbl74G,  *lbl75G;
    extern GtkWidget *lbl71L,  *lbl72L,  *lbl73L,  *lbl74L,  *lbl75L;
    extern GtkWidget *lbl71Gr, *lbl72Gr, *lbl73Gr, *lbl74Gr, *lbl75Gr;
    extern GtkWidget *btn71A,  *btn72A,  *btn73A,  *btn74A,  *btn75A;              //vv dr - new AIM
    extern GtkWidget *lbl71Fa, *lbl72Fa, *lbl73Fa, *lbl74Fa, *lbl75Fa;             //^^

    extern GtkWidget *btn81,   *btn82,   *btn83,   *btn84,   *btn85;
    extern GtkWidget *lbl81F,  *lbl82F,  *lbl83F,  *lbl84F,  *lbl85F;
    extern GtkWidget *lbl81G,  *lbl82G,  *lbl83G,  *lbl84G,  *lbl85G;
    extern GtkWidget *lbl81L,  *lbl82L,  *lbl83L,  *lbl84L,  *lbl85L;
    extern GtkWidget *lbl81Gr, *lbl82Gr, *lbl83Gr, *lbl84Gr, *lbl85Gr;
    extern GtkWidget           *btn82A,  *btn83A,  *btn84A,  *btn85A;              //vv dr - new AIM
    extern GtkWidget           *lbl82Fa, *lbl83Fa, *lbl84Fa, *lbl85Fa;             //^^
    //GtkWidget *lblOn; //JM
    //JM7 GtkWidget  *lblConfirmY; //JM for Y/N
    //JM7 GtkWidget  *lblConfirmN; //JM for Y/N

    extern char *cssData;
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
  #define C47SpecialKey_AltGr_Pressed           (event->keyval == GDK_KEY_Alt_R     && event->state  & 0b10100)
  #define C47SpecialKey_Ctrl_Pressed            (swapCtrlCode ? (event->keyval == GDK_KEY_Control_L && !(event->state  & 0b00100)) : (event->keyval == GDK_KEY_Control_L && event->state  & 0b00100))
  //This swapctrlcode control code is used to test Didier's FR
  #define C47SpecialKey_Valid_Pressed           (!C47SpecialKey_AltGr_Pressed && !C47SpecialKey_Ctrl_Pressed && event->state & 0b11100)
  //C47SpecialKey_Valid_Released not required as normal keys are not evaluated on release
  #define C47SpecialKey_Ctrl_Released          ((event->keyval == GDK_KEY_Control_L && event->state  & 0b00000) && (previousEventKeyP == GDK_KEY_Control_L && previousEventStateP == 0b00100))
  #define C47SpecialKey_AltGr_Released          (event->keyval == GDK_KEY_Alt_R     && event->state  & 0b00000  &&  previousEventKeyR == GDK_KEY_Control_L && previousEventStateR == 0b1000)





  // z47_keyPressed_c_impl ported to Zig (gtk_gui_keypress_owned.zig, re-exported
  // via gtk_gui_runtime.zig). The full C body was removed during the gtkGui.c
  // retirement campaign; the symbol is now provided by the Zig owner.


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



//----------------------------------------------------------------------------------

extern bool z47_is_valid_utf8(const char *s, size_t *error_offset); // Zig owner: gtk_gui_label_owned.zig




//----------------------------------------------------------------------------------





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
  // setupUI ported to Zig (gtk_gui_setup_ui_owned.zig, exported via
  // gtk_gui_runtime.zig). The widget globals remain defined in this file and
  // are written by the Zig owner through extern var; check_all_btn_widgets_for_
  // consistency stays in C above and is called from the Zig setupUI.
#endif // PC_BUILD
