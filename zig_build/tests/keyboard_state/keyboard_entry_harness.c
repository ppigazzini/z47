// SPDX-License-Identifier: GPL-3.0-only
//
// Keyboard ENTRY-layer parity harness.
//
// The main testSuite drives functions directly (funcToTest), so the keyboard
// entry path -- btnClicked -> btnPressed/btnReleased -> determineItem ->
// processKeyAction -> mode transitions -- is never exercised on host. This
// harness drives a real physical-key sequence through the host btnClicked
// export and asserts, for each click, that the entry path (a) dispatched the
// key to the correct item and (b) drove the expected calc-mode transition.
//
// The key string is the kbd_std array INDEX (0..36) as two decimal digits
// (determineItem: key_no = (data[0]-'0')*10 + data[1]-'0'; kbdStdAt(key_no)),
// not the printed keyId. Indices are read from src/c47/assign.c kbd_std_C47.
//
// Scope: this verifies the entry DISPATCH and mode logic. The full NIM
// value-commit-to-X path (e.g. asserting 1 2 ENTER 3 + == 15) needs additional
// startup state this bare harness does not set up, and is a follow-up slice.

#include <c47.h>
#include <decQuad.h>
#include <stdio.h>
#include <string.h>

// The 6 screen/keyboard globals testSuite.c normally provides; this harness
// replaces testSuite.c, so it must define them itself (the GTK/HAL surface is
// inert in this build).
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// btnClicked is declared in keyboard.h (void btnClicked(GtkWidget*, gpointer));
// on the host it resolves to keyboard_state.zig btnClickedHost, which builds a
// synthetic left-click event then runs btnPressed + btnReleased on `data` (the
// 2-digit kbd_std index string).
typedef struct {
  const char *index;       // kbd_std_C47 array index, 2 digits
  int16_t     expectItem;  // item determineItem must return for that key
  uint8_t     expectMode;  // calcMode after processKeyAction handles it
  const char *name;
} keyStep_t;

int main(void) {
  // The number-input path commits via the calc memory allocator; without this
  // the NIM number silently fails to materialise in X (the GMP allocators must
  // be installed exactly as the sim/testSuite do at startup).
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  fnReset(CONFIRMED);
  // fnReset does NOT install the configuration defaults (Input_Default,
  // displayFormat, roundingMode, ...); the sim does this at startup. Without it
  // closeNim cannot route the NIM integer to a real34 and the number never lands
  // in X. Install them as the sim does.
  resetOtherConfigurationStuff(true);

  const keyStep_t seq[] = {
    {"28", ITM_1,     CM_NIM,    "1"},
    {"29", ITM_2,     CM_NIM,    "2"},
    {"12", ITM_ENTER, CM_NORMAL, "ENTER"},
    {"30", ITM_3,     CM_NIM,    "3"},
    {"36", ITM_ADD,   CM_NORMAL, "+"},
  };
  const int steps = (int)(sizeof(seq) / sizeof(seq[0]));

  for(int i = 0; i < steps; ++i) {
    btnClicked(NULL, (gpointer)seq[i].index);

    if(lastKeyItemDetermined != seq[i].expectItem) {
      printf("FAIL: key '%s' (%s) dispatched item %d, expected %d\n",
             seq[i].index, seq[i].name, (int)lastKeyItemDetermined,
             (int)seq[i].expectItem);
      return 1;
    }
    if(calcMode != seq[i].expectMode) {
      printf("FAIL: after key '%s' (%s) calcMode = %u, expected %u\n",
             seq[i].index, seq[i].name, (unsigned)calcMode,
             (unsigned)seq[i].expectMode);
      return 1;
    }
  }

  // Scenario 1b: NIM digit ACCUMULATION through the entry path. Typing 1 2 3
  // must build the number "+123" in the NIM buffer (aimBuffer), proving the keys
  // flow btnClicked -> processKeyAction -> addItemToNimBuffer end to end, not just
  // that the first digit is dispatched. (Committing the NIM number to X with a
  // real arithmetic result additionally needs the calculator config state --
  // Input_Default and friends -- that the sim installs at startup beyond
  // fnReset; asserting the computed value is a follow-up slice.)
  fnReset(CONFIRMED);
  btnClicked(NULL, (gpointer)"28"); // 1
  btnClicked(NULL, (gpointer)"29"); // 2
  btnClicked(NULL, (gpointer)"30"); // 3
  if(calcMode != CM_NIM) {
    printf("FAIL: after digits 1 2 3, calcMode = %u, expected CM_NIM (%u)\n",
           (unsigned)calcMode, (unsigned)CM_NIM);
    return 1;
  }
  if(strcmp(aimBuffer, "+123") != 0) {
    printf("FAIL: after digits 1 2 3, NIM buffer = \"%s\", expected \"+123\"\n",
           aimBuffer);
    return 1;
  }

  // Scenario 2: the full numeric keypad. Every digit key must dispatch to the
  // matching ITM_<n> and put the calculator in number-input mode -- a regression
  // guard on the kbd_std_C47 layout-index lookup across the whole digit row.
  fnReset(CONFIRMED);
  const keyStep_t digits[] = {
    {"33", ITM_0, CM_NIM, "0"}, {"28", ITM_1, CM_NIM, "1"},
    {"29", ITM_2, CM_NIM, "2"}, {"30", ITM_3, CM_NIM, "3"},
    {"23", ITM_4, CM_NIM, "4"}, {"24", ITM_5, CM_NIM, "5"},
    {"25", ITM_6, CM_NIM, "6"}, {"18", ITM_7, CM_NIM, "7"},
    {"19", ITM_8, CM_NIM, "8"}, {"20", ITM_9, CM_NIM, "9"},
  };
  const int digitCount = (int)(sizeof(digits) / sizeof(digits[0]));
  for(int i = 0; i < digitCount; ++i) {
    btnClicked(NULL, (gpointer)digits[i].index);
    if(lastKeyItemDetermined != digits[i].expectItem) {
      printf("FAIL: digit key '%s' (%s) dispatched item %d, expected %d\n",
             digits[i].index, digits[i].name, (int)lastKeyItemDetermined,
             (int)digits[i].expectItem);
      return 1;
    }
    if(calcMode != digits[i].expectMode) {
      printf("FAIL: after digit '%s' calcMode = %u, expected CM_NIM (%u)\n",
             digits[i].index, (unsigned)calcMode, (unsigned)CM_NIM);
      return 1;
    }
  }

  // Scenario 3: an OPERATOR key EXECUTES its function on the stack and produces
  // a concrete arithmetic result. Preset Y=12, X=3, then click "+" (index 36):
  // btnClicked -> btnPressed -> determineItem(ITM_ADD) -> processKeyAction ->
  // the addition runs, leaving X=15. This proves the entry path actually drives
  // computation, not just dispatch -- using preset registers to avoid the NIM
  // number-commit, which needs more startup state than fnReset installs.
  fnReset(CONFIRMED);
  resetOtherConfigurationStuff(true);
  reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
  int32ToReal34(12, REGISTER_REAL34_DATA(REGISTER_Y));
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_X));
  btnClicked(NULL, (gpointer)"36"); // +
  {
    char xbuf[64];
    if(getRegisterDataType(REGISTER_X) != dtReal34) {
      printf("FAIL: after preset 12, 3 then '+', X type = %u, expected dtReal34"
             " (%u)\n", (unsigned)getRegisterDataType(REGISTER_X),
             (unsigned)dtReal34);
      return 1;
    }
    decQuadToString((decQuad *)REGISTER_REAL34_DATA(REGISTER_X), xbuf);
    if(strcmp(xbuf, "15") != 0) {
      printf("FAIL: after preset 12, 3 then '+', X = \"%s\", expected \"15\"\n",
             xbuf);
      return 1;
    }
  }

  printf("KEYBOARD ENTRY PARITY: OK (dispatch + modes for 1 2 ENTER 3 +; NIM "
         "accumulation 1 2 3 -> \"+123\"; full 0-9 digit-row dispatch; the '+' "
         "key computes 12 + 3 = 15 on the stack)\n");
  return 0;
}
