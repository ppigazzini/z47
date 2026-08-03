// SPDX-License-Identifier: GPL-3.0-only
//
// keyboard parity: the Zig owner against c43's own keyboard.c, in one binary
// (REPORT-31 M31-13).
//
// keyboard_state_oracle.c compiles c43's keyboard.c a second time under `oracle_`
// names beside the Zig owner that replaced it. Both implementations then drive
// ONE calculator -- the same stack, the same NIM/AIM buffer, the same softmenu
// stack, the same flags -- so nothing is modelled and a difference can only come
// from the code under test. The reference is c43 source compiled at build time,
// so it moves when c43 moves.
//
// WHAT THIS REPLACED: a 238-line hand-written oracle covering ~4% of keyboard.c,
// whose driver had ALREADY deleted its handler cases because the model no longer
// matched the ported handlers -- leaving four pure translation helpers checked
// against a hand-written reference. That is the shape this report exists to
// remove, and it was the last one in the tree.
//
// THE REAL WORK HERE IS THE STATE DIFF, not the linking (Annex A.3). A keystroke
// may change the calculator mode, the input buffers, the stack, the softmenu
// stack, the shift state, the error and the temporary-information line -- and a
// full core carries orders of magnitude more state than a unit harness, so
// snapshotting the wrong set means either missing a divergence or reporting
// noise. What is snapshotted below is what a key handler is allowed to touch.
//
// SEED / RUN / SNAPSHOT / RE-SEED / RUN / SNAPSHOT, and the re-seed includes the
// oracle's OWN copies of keyboard.c's file-scope state (`key`, `asnKey`,
// `releaseOverride`, `showScreenDismissed`, `shiftKeyClearsError`): they persist
// across calls, and the two implementations hold separate ones, so a case that
// did not reset them would inherit the previous case's divergence.

#include <c47.h>

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Screen/GUI globals the core references; normally testSuite.c's. Headless here.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// ---------------------------------------------------------------------------
// The two implementations. Unprefixed names are the Zig owner's exports
// (declared by upstream's keyboard.h via <c47.h>); `oracle_` ones are c43's.
// ---------------------------------------------------------------------------
extern void oracle_fnKeyEnter(uint16_t unusedButMandatoryParameter);
extern void oracle_fnKeyExit(uint16_t unusedButMandatoryParameter);
extern void oracle_fnKeyCC(uint16_t unusedButMandatoryParameter);
extern void oracle_fnKeyBackspace(uint16_t unusedButMandatoryParameter);
extern void oracle_fnKeyUp(uint16_t unusedButMandatoryParameter);
extern void oracle_fnKeyDown(uint16_t unusedButMandatoryParameter);
extern void oracle_fnKeyDotD(uint16_t unusedButMandatoryParameter);
extern void oracle_setLastKeyCode(int keyIndex);
extern void oracle_processKeyAction(int16_t item);

// keyboard.c's own file-scope state, in both copies. Reset when the fixture is
// seeded. The Zig owner exports its three under the c43 names
// (keyboard_state_runtime.zig) but no header declares them, so they are declared
// here rather than reached through <c47.h>.
//
// `key` is NOT in this set: it is a PC_BUILD-only mouse-coordinate scratch used
// by convertXYToKey/frmCalcMouseButton*, which this lane does not drive, and the
// Zig owner does not export it at all.
extern uint8_t asnKey[4];
extern bool_t  releaseOverride;
extern bool_t  showScreenDismissed;
extern bool_t  shiftKeyClearsError;

// The core->shell host-hook table (src/abi/host_state.zig). It matters HERE.
//
// The Zig owner routes displayBugScreen through `abi.host.showBugScreen`, which
// is a NO-OP until a hook is installed; c43's keyboard.c calls error.c's
// displayBugScreen directly, and that sets calcMode = CM_BUG_ON_SCREEN. With the
// table empty, every `default:` arm of the seven fnKey* handlers -- the
// "unexpected calcMode while processing key" bug screens, which BOTH
// implementations reach -- looked like a divergence: c43 ended in
// CM_BUG_ON_SCREEN and z47 did not. That is the harness's fault, not the port's,
// and it is invisible from either side alone. Installing the real renderers makes
// the two sides comparable.
extern void (*z47HostShowBugScreenHook)(const char *msg);
extern void (*z47HostRequestRefreshHook)(uint16_t id);

extern uint8_t oracle_asnKey[4];
extern bool_t  oracle_releaseOverride;
extern bool_t  oracle_showScreenDismissed;
extern bool_t  oracle_shiftKeyClearsError;

static int failures = 0;

static void fail(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  printf("FAIL: ");
  vprintf(fmt, args);
  printf("\n");
  va_end(args);
  failures++;
}

// ---------------------------------------------------------------------------
// What a keystroke is allowed to change.
// ---------------------------------------------------------------------------
typedef struct {
  uint8_t  calcMode;
  uint8_t  temporaryInformation;
  uint8_t  lastErrorCode;
  uint8_t  previousErrorCode;
  uint8_t  lastKeyCode;
  uint8_t  currentFlgScr;
  uint8_t  screenUpdatingMode;
  uint8_t  programRunStop;
  uint8_t  nextChar;
  uint8_t  alphaCase;
  uint8_t  nimNumberPart;
  bool_t   keyActionProcessed;
  bool_t   shiftF;
  bool_t   shiftG;
  bool_t   lastshiftF;
  bool_t   lastshiftG;
  int16_t  ListXYposition;
  int16_t  catalog;
  int16_t  numberOfTamMenusToPop;
  uint64_t systemFlags0;
  uint64_t systemFlags1;
  uint16_t globalFlags[8];

  softmenuStack_t softmenuStack[SOFTMENU_STACK_SIZE];
  tamState_t      tam;

  // The input buffer is the point of most of these handlers: backspace, ENTER
  // out of NIM, a catalog selection. It is a NUL-terminated C string in a
  // 1024-byte arena, so compare the whole arena -- a handler that leaves a
  // different tail behind is a real difference in what the next keystroke reads.
  char aimBuffer[AIM_BUFFER_LENGTH];

  // The stack, by descriptor. ENTER lifts it, EXIT may drop it.
  registerHeader_t globalRegister[NUMBER_OF_GLOBAL_REGISTERS];
} snapshot_t;

static snapshot_t snapshotA;
static snapshot_t snapshotB;

static void takeSnapshot(snapshot_t *out) {
  memset(out, 0, sizeof(*out));
  out->calcMode = calcMode;
  out->temporaryInformation = temporaryInformation;
  out->lastErrorCode = lastErrorCode;
  out->previousErrorCode = previousErrorCode;
  out->lastKeyCode = lastKeyCode;
  out->currentFlgScr = currentFlgScr;
  out->screenUpdatingMode = screenUpdatingMode;
  out->programRunStop = programRunStop;
  out->nextChar = nextChar;
  out->alphaCase = alphaCase;
  out->nimNumberPart = nimNumberPart;
  out->keyActionProcessed = keyActionProcessed;
  out->shiftF = shiftF;
  out->shiftG = shiftG;
  out->lastshiftF = lastshiftF;
  out->lastshiftG = lastshiftG;
  out->ListXYposition = ListXYposition;
  out->catalog = catalog;
  out->numberOfTamMenusToPop = numberOfTamMenusToPop;
  out->systemFlags0 = systemFlags0;
  out->systemFlags1 = systemFlags1;
  memcpy(out->globalFlags, globalFlags, sizeof(out->globalFlags));
  memcpy(out->softmenuStack, softmenuStack, sizeof(out->softmenuStack));
  memcpy(&out->tam, &tam, sizeof(out->tam));
  if(aimBuffer != NULL) {
    memcpy(out->aimBuffer, aimBuffer, sizeof(out->aimBuffer));
  }
  memcpy(out->globalRegister, globalRegister, sizeof(out->globalRegister));
}

#define CHECK_FIELD(field, fmt)                                                              \
  if(snapshotA.field != snapshotB.field) {                                                   \
    fail("%s: " #field " z47=" fmt " c43=" fmt, caseName, snapshotA.field, snapshotB.field);  \
    return 1;                                                                                \
  }

static int reportSnapshotMismatch(const char *caseName) {
  if(memcmp(&snapshotA, &snapshotB, sizeof(snapshotA)) == 0) {
    return 0;
  }

  CHECK_FIELD(calcMode, "%u")
  CHECK_FIELD(temporaryInformation, "%u")
  CHECK_FIELD(lastErrorCode, "%u")
  CHECK_FIELD(previousErrorCode, "%u")
  CHECK_FIELD(lastKeyCode, "%u")
  CHECK_FIELD(currentFlgScr, "%u")
  CHECK_FIELD(screenUpdatingMode, "%u")
  CHECK_FIELD(programRunStop, "%u")
  CHECK_FIELD(nextChar, "%u")
  CHECK_FIELD(alphaCase, "%u")
  CHECK_FIELD(nimNumberPart, "%u")
  CHECK_FIELD(keyActionProcessed, "%d")
  CHECK_FIELD(shiftF, "%d")
  CHECK_FIELD(shiftG, "%d")
  CHECK_FIELD(lastshiftF, "%d")
  CHECK_FIELD(lastshiftG, "%d")
  CHECK_FIELD(ListXYposition, "%d")
  CHECK_FIELD(catalog, "%d")
  CHECK_FIELD(numberOfTamMenusToPop, "%d")
  // The two u64 fields do not go through CHECK_FIELD: `uint64_t` is `unsigned
  // long` on this host and `unsigned long long` on the firmware, so a fixed
  // conversion in the macro is right on one target and a varargs type mismatch on
  // the other. Cast at the call instead.
  if (snapshotA.systemFlags0 != snapshotB.systemFlags0) {
    fail("%s: systemFlags0 z47=%llu c43=%llu", caseName,
         (unsigned long long)snapshotA.systemFlags0, (unsigned long long)snapshotB.systemFlags0);
    return 1;
  }
  if (snapshotA.systemFlags1 != snapshotB.systemFlags1) {
    fail("%s: systemFlags1 z47=%llu c43=%llu", caseName,
         (unsigned long long)snapshotA.systemFlags1, (unsigned long long)snapshotB.systemFlags1);
    return 1;
  }

  for(int i = 0; i < 8; i++) {
    if(snapshotA.globalFlags[i] != snapshotB.globalFlags[i]) {
      fail("%s: globalFlags[%d] z47=%u c43=%u", caseName, i, snapshotA.globalFlags[i], snapshotB.globalFlags[i]);
      return 1;
    }
  }
  for(int i = 0; i < SOFTMENU_STACK_SIZE; i++) {
    if(memcmp(&snapshotA.softmenuStack[i], &snapshotB.softmenuStack[i], sizeof(softmenuStack_t)) != 0) {
      fail("%s: softmenuStack[%d] z47{id=%u} c43{id=%u}", caseName, i,
           snapshotA.softmenuStack[i].softmenuId, snapshotB.softmenuStack[i].softmenuId);
      return 1;
    }
  }
  if(memcmp(&snapshotA.tam, &snapshotB.tam, sizeof(tamState_t)) != 0) {
    fail("%s: tam state differs -- z47{mode=%u func=%d digitsSoFar=%u} c43{mode=%u func=%d digitsSoFar=%u}",
         caseName, snapshotA.tam.mode, snapshotA.tam.function, snapshotA.tam.digitsSoFar,
         snapshotB.tam.mode, snapshotB.tam.function, snapshotB.tam.digitsSoFar);
    return 1;
  }
  if(memcmp(snapshotA.aimBuffer, snapshotB.aimBuffer, sizeof(snapshotA.aimBuffer)) != 0) {
    for(size_t i = 0; i < sizeof(snapshotA.aimBuffer); i++) {
      if(snapshotA.aimBuffer[i] != snapshotB.aimBuffer[i]) {
        fail("%s: aimBuffer differs at byte %zu: z47=0x%02x c43=0x%02x (z47=\"%.32s\" c43=\"%.32s\")",
             caseName, i, (unsigned char)snapshotA.aimBuffer[i], (unsigned char)snapshotB.aimBuffer[i],
             snapshotA.aimBuffer, snapshotB.aimBuffer);
        return 1;
      }
    }
  }
  for(size_t i = 0; i < NUMBER_OF_GLOBAL_REGISTERS; i++) {
    if(memcmp(&snapshotA.globalRegister[i], &snapshotB.globalRegister[i], sizeof(registerHeader_t)) != 0) {
      fail("%s: globalRegister[%zu] z47{ptr=%u type=%u tag=%u} c43{ptr=%u type=%u tag=%u}", caseName, i,
           snapshotA.globalRegister[i].pointerToRegisterData, snapshotA.globalRegister[i].dataType,
           snapshotA.globalRegister[i].tag,
           snapshotB.globalRegister[i].pointerToRegisterData, snapshotB.globalRegister[i].dataType,
           snapshotB.globalRegister[i].tag);
      return 1;
    }
  }

  fail("%s: snapshots differ but no field was identified -- widen the report", caseName);
  return 1;
}

// ---------------------------------------------------------------------------
// The fixture, parameterised by the calculator mode under test.
// ---------------------------------------------------------------------------
static uint8_t fixtureMode;
static const char *fixtureBuffer;

static void buildFixture(void) {
  fnReset(CONFIRMED);

  // A non-trivial stack, so a lift or a drop is visible.
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(11, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
  int32ToReal34(22, REGISTER_REAL34_DATA(REGISTER_Y));
  reallocateRegister(REGISTER_Z, dtReal34, 0, amNone);
  int32ToReal34(33, REGISTER_REAL34_DATA(REGISTER_Z));
  reallocateRegister(REGISTER_T, dtReal34, 0, amNone);
  int32ToReal34(44, REGISTER_REAL34_DATA(REGISTER_T));

  // Reach the input modes through the REAL entry path rather than assigning
  // calcMode and strcpy'ing the buffer.
  //
  // This is not fastidiousness. NIM's state is a triple -- calcMode, aimBuffer
  // and nimNumberPart -- and forcing only the first two produces a calculator
  // that cannot exist: `addItemToNimBuffer` then computes
  // `strchr(aimBuffer, '.') - aimBuffer` with no '.' present, which is a null
  // pointer subtraction. c43 folds the garbage into an int16_t and carries on;
  // z47 traps. Neither answer is meaningful, because the reference is undefined
  // there -- so the fixture has to seed a state the reference can be in.
  //
  // The browser and application modes carry no such invariant: they are a mode
  // flag and nothing else, so assigning calcMode is exactly how they are entered.
  if(fixtureMode == CM_NIM) {
    for(const char *c = fixtureBuffer; c != NULL && *c != 0; c++) {
      addItemToNimBuffer((int16_t)(ITM_0 + (*c - '0')));
    }
  }
  else if(fixtureMode == CM_AIM) {
    calcModeAim(NOPARAM);
    for(const char *c = fixtureBuffer; c != NULL && *c != 0; c++) {
      addItemToBuffer((uint16_t)(ITM_A + (*c - 'A')));
    }
  }
  else {
    calcMode = fixtureMode;
  }

  // keyboard.c's file-scope state, on BOTH sides. The two implementations hold
  // separate copies, so an un-reset one carries the previous case's divergence
  // into this one -- the exact failure the seed/run/snapshot discipline exists
  // to prevent, and one a unit harness never has to think about.
  memset(asnKey, 0, sizeof(asnKey));
  releaseOverride = false;
  showScreenDismissed = false;
  shiftKeyClearsError = false;
  memset(oracle_asnKey, 0, sizeof(oracle_asnKey));
  oracle_releaseOverride = false;
  oracle_showScreenDismissed = false;
  oracle_shiftKeyClearsError = false;

  lastErrorCode = ERROR_NONE;
  previousErrorCode = ERROR_NONE;
  temporaryInformation = TI_NO_INFO;
  keyActionProcessed = false;
}

typedef void (*keyHandler_t)(uint16_t);

static int diffKeyHandler(const char *name, keyHandler_t zigSide, keyHandler_t c43Side) {
  char caseName[128];
  snprintf(caseName, sizeof(caseName), "%s in calcMode %u%s%s", name, fixtureMode,
           fixtureBuffer ? " buffer=" : "", fixtureBuffer ? fixtureBuffer : "");

  buildFixture();
  zigSide(NOPARAM);
  takeSnapshot(&snapshotA);

  buildFixture();
  c43Side(NOPARAM);
  takeSnapshot(&snapshotB);

  return reportSnapshotMismatch(caseName);
}

// ---------------------------------------------------------------------------
// Check 1 -- the eight entry points the deleted oracle modelled, swept across
// the calculator modes each of them branches on.
// ---------------------------------------------------------------------------
static const struct {
  const char *name;
  keyHandler_t zigSide;
  keyHandler_t c43Side;
} keyHandlers[] = {
  {"fnKeyEnter",     fnKeyEnter,     oracle_fnKeyEnter},
  {"fnKeyExit",      fnKeyExit,      oracle_fnKeyExit},
  {"fnKeyCC",        fnKeyCC,        oracle_fnKeyCC},
  {"fnKeyBackspace", fnKeyBackspace, oracle_fnKeyBackspace},
  {"fnKeyUp",        fnKeyUp,        oracle_fnKeyUp},
  {"fnKeyDown",      fnKeyDown,      oracle_fnKeyDown},
  {"fnKeyDotD",      fnKeyDotD,      oracle_fnKeyDotD},
};

static const struct {
  uint8_t mode;
  const char *buffer;
} modeFixtures[] = {
  {CM_NORMAL,           NULL},
  {CM_NIM,              "123"},
  {CM_NIM,              "1"},
  // NO empty-buffer NIM fixture. CM_NIM with an empty aimBuffer is a state the
  // calculator cannot reach -- entering numeric input always puts at least one
  // character in the buffer -- and forcing it makes z47's closeNim() evaluate
  // strlen("") - 1 and trap on the unsigned underflow while c43 wraps to -1. The
  // divergence is the harness's, not the port's: a differential must seed states
  // the reference can actually be in.
  {CM_AIM,              "ABC"},
  // NO empty-buffer AIM fixture, and this one is worth recording rather than
  // just dropping. Entering alpha mode with `calcModeAim(NOPARAM)` and no text,
  // then pressing DOWN, takes fnKeyDown -> fnT_ARROW(ITM_DOWN1) ->
  // stringNextGlyph(aimBuffer, T_cursorPos) with T_cursorPos still negative:
  // z47 TRAPS on the @intCast in abi/c47_string.zig:nextGlyph, and c43 indexes
  // the buffer out of bounds and carries on. The reference is undefined there, so
  // a differential cannot say which is right -- z47's answer is the safer one and
  // the comparison would be pinning c43's accident. It is a memory-safety
  // question (REPORT-30's subject), not a parity one, and it wants triaging
  // there: whether T_cursorPos can really be negative on a user's first DOWN in
  // an empty alpha buffer is the question, and this harness is not the place to
  // answer it.
  {CM_PEM,              NULL},
  {CM_ASSIGN,           NULL},
  {CM_REGISTER_BROWSER, NULL},
  {CM_FLAG_BROWSER,     NULL},
  {CM_FONT_BROWSER,     NULL},
  {CM_PLOT_STAT,        NULL},
  {CM_GRAPH,            NULL},
  {CM_LISTXY,           NULL},
  {CM_TIMER,            NULL},
  {CM_ERROR_MESSAGE,    NULL},
  {CM_BUG_ON_SCREEN,    NULL},
  {CM_CONFIRMATION,     NULL},
};

static int runKeyHandlerDifferential(void) {
  int before = failures;

  for(size_t f = 0; f < sizeof(modeFixtures) / sizeof(modeFixtures[0]); f++) {
    fixtureMode = modeFixtures[f].mode;
    fixtureBuffer = modeFixtures[f].buffer;
    for(size_t h = 0; h < sizeof(keyHandlers) / sizeof(keyHandlers[0]); h++) {
      diffKeyHandler(keyHandlers[h].name, keyHandlers[h].zigSide, keyHandlers[h].c43Side);
    }
  }

  if(failures == before) {
    printf("PASS: the 7 fnKey* handlers agree with c43 across %zu calculator-mode fixtures\n",
           sizeof(modeFixtures) / sizeof(modeFixtures[0]));
  }
  return failures - before;
}

// ---------------------------------------------------------------------------
// Check 2 -- setLastKeyCode, over the WHOLE key-index space plus the boundaries
// on either side.
//
// It is a row/column encoder with five ranges, and a hand-picked case set is
// exactly how a membership table goes stale unnoticed (FLAG_IMPLOT, REPORT-31
// M31-2). Sweeping the encoding space costs nothing here.
// ---------------------------------------------------------------------------
static int runSetLastKeyCodeDifferential(void) {
  int before = failures;

  for(int keyIndex = -2; keyIndex <= 46; keyIndex++) {
    char caseName[64];
    snprintf(caseName, sizeof(caseName), "setLastKeyCode(%d)", keyIndex);

    fixtureMode = CM_NORMAL;
    fixtureBuffer = NULL;

    buildFixture();
    setLastKeyCode(keyIndex);
    takeSnapshot(&snapshotA);

    buildFixture();
    oracle_setLastKeyCode(keyIndex);
    takeSnapshot(&snapshotB);

    reportSnapshotMismatch(caseName);
  }

  if(failures == before) {
    printf("PASS: setLastKeyCode agrees with c43 over the whole key index range (-2..46)\n");
  }
  return failures - before;
}

// ---------------------------------------------------------------------------
// Check 3 -- processKeyAction, the dispatcher every physical key ends up in.
//
// `keyboard_entry_harness` drives it through btnClicked with real key indices;
// this drives it directly with item codes, which reaches the arms a physical
// keyboard cannot produce in one press.
// ---------------------------------------------------------------------------
static const int16_t dispatchItems[] = {
  ITM_NULL, ITM_ENTER, ITM_EXIT1, ITM_BACKSPACE, ITM_UP1, ITM_DOWN1, ITM_CC,
  ITM_0, ITM_1, ITM_9, ITM_PERIOD, ITM_EXPONENT, ITM_ADD, ITM_SUB, ITM_MULT, ITM_DIV,
  ITM_A, ITM_Z, ITM_a, ITM_z, ITM_SPACE, ITM_SHIFTf, ITM_SHIFTg,
  ITM_RCL, ITM_STO, ITM_XEQ, ITM_RS, ITM_CLSTK, ITM_DROP,
};

static int runProcessKeyActionDifferential(void) {
  int before = failures;

  for(size_t f = 0; f < sizeof(modeFixtures) / sizeof(modeFixtures[0]); f++) {
    fixtureMode = modeFixtures[f].mode;
    fixtureBuffer = modeFixtures[f].buffer;

    for(size_t i = 0; i < sizeof(dispatchItems) / sizeof(dispatchItems[0]); i++) {
      char caseName[128];
      snprintf(caseName, sizeof(caseName), "processKeyAction(%d) in calcMode %u",
               dispatchItems[i], fixtureMode);

      buildFixture();
      processKeyAction(dispatchItems[i]);
      takeSnapshot(&snapshotA);

      buildFixture();
      oracle_processKeyAction(dispatchItems[i]);
      takeSnapshot(&snapshotB);

      reportSnapshotMismatch(caseName);
    }
  }

  if(failures == before) {
    printf("PASS: processKeyAction agrees with c43 over %zu items x %zu modes\n",
           sizeof(dispatchItems) / sizeof(dispatchItems[0]),
           sizeof(modeFixtures) / sizeof(modeFixtures[0]));
  }
  return failures - before;
}

int main(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);

  // Bind the core's host hooks to the same shell functions c43's keyboard.c
  // calls directly, so both implementations have the same observable effect.
  z47HostShowBugScreenHook = displayBugScreen;
  z47HostRequestRefreshHook = refreshScreen;

  runSetLastKeyCodeDifferential();
  runKeyHandlerDifferential();
  runProcessKeyActionDifferential();

  if(failures != 0) {
    printf("KEYBOARD PARITY: %d check(s) FAILED\n", failures);
    return 1;
  }
  printf("KEYBOARD PARITY: OK\n");
  return 0;
}
