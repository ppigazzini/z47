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



  // gdkKeyMap[] / deadKeysMap[] data moved to gtk_gui_keymap_owned.zig.




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
