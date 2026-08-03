// SPDX-License-Identifier: GPL-3.0-only
//
// The calculator, as far as c43's flags.c is concerned.
//
// WHY THIS CLAIMS UPSTREAM'S GUARD (REPORT-31 M31-2). `flags.c` sits next to the
// real `c47.h`, and a quoted `#include "c47.h"` searches the including file's own
// directory first -- no `-I` can outrank that. Defining `C47_H` here before
// pulling `flags.c` in makes the real header a no-op and this file the
// environment the oracle compiles against. The sibling oracles that include
// upstream `.c` files from `mathematics/` do not need the trick, because there is
// no `c47.h` in that directory.
//
// WHY IT INCLUDES UPSTREAM HEADERS RATHER THAN COPYING VALUES. This file used to
// carry ~110 hand-written `#define`s -- every FLAG_*, TI_*, JC_*, the write-protect
// test. That is the SAME defect one level down from the one REPORT-31 is about: a
// c43 constant change would leave the harness's copy behind and the lane green.
// `defines.h`, `items.h` and `typeDefinitions.h` are pure headers with no includes
// of their own, so they cost five opaque placeholder typedefs and buy every
// constant and struct straight from the pin.
//
// WHY THIS IS NOT `build/tests/c43_oracle.zig`'s SHAPE (REPORT-31 M31-9, decided
// 2026-08-03). Later conversions do not build a mock header at all: they put
// upstream's OWN `src/c47/c47.h` on the include path with the six placeholder
// typedefs from `build/tests/common/c43_harness_prelude.h`, which is cheaper and
// strictly more faithful. This lane was NOT retrofitted onto that. It is green,
// verified, and seen to fail (adding FLAG_QUIET to c43's refreshStateFlags turns
// six sweep cases red), and rebuilding a working oracle for stylistic uniformity
// risks the conversion for no verification gain. The divergence in style is
// deliberate. If this lane ever needs reworking for another reason, take the
// c43_oracle.zig shape then.

#ifndef C47_H
#define C47_H

#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef bool bool_t;
typedef int16_t calcRegister_t;

// Placeholders for the numeric/GUI types `typeDefinitions.h` mentions in structs
// the flag cluster never touches. Only the NAMES have to exist; nothing in this
// lane reads or lays out a real34_t, and no harness struct crosses an ABI boundary
// with the Zig owner.
typedef struct {
  uint8_t opaque[64];
} real_t;
typedef struct {
  uint8_t opaque[16];
} real34_t;
typedef struct {
  real34_t real;
  real34_t imag;
} complex34_t;
typedef struct {
  uint64_t state;
  uint64_t inc;
} pcg32_random_t;
typedef struct Z47FlagsHarnessGtkWidget GtkWidget;

#include "../../../upstream/src/c47/defines.h"
#include "../../../upstream/src/c47/items.h"
#include "../../../upstream/src/c47/typeDefinitions.h"
// The jmConfig values SetSetting switches on (TF_*, CU_*, PS_*, SS_*, CM_*, DO_*,
// JC_*) live here, not in defines.h.
#include "../../../upstream/src/c47/c47Extensions/radioButtonCatalog.h"

// ---------------------------------------------------------------------------
// The state both implementations share. Defined by flags_fake_runtime.c; each
// parity case seeds it, runs one side, snapshots, re-seeds and runs the other.
// ---------------------------------------------------------------------------
extern uint64_t systemFlags0;
extern uint64_t systemFlags1;
extern uint32_t lastIntegerBase;
extern uint8_t screenUpdatingMode;
extern uint16_t globalFlags[8];
extern localFlags_t *currentLocalFlags;
extern uint8_t temporaryInformation;
extern uint8_t programRunStop;
extern uint8_t alphaCase;
extern uint8_t scrLock;
extern uint8_t nextChar;
extern uint8_t calcMode;

// The equation-editor fixture `_clearAlpha` walks when calcMode == CM_EIM. Real
// arrays, not stubs: the branch that reads them is now compiled from c43 source
// on the oracle side and taken by the Zig owner's production path on the other,
// so both have to find the same equation there.
extern const softmenu_t softmenu[];
extern softmenuStack_t softmenuStack[SOFTMENU_STACK_SIZE];
extern formulaHeader_t *allFormulae;
extern uint16_t currentFormula;

// Error-reporting surface. `EXTRA_INFO_ON_CALC_ERROR` is upstream's own value
// (1 on a PC build), so those branches COMPILE here rather than being configured
// away -- an upstream edit inside one of them is then at least a build failure
// instead of silence.
extern char *tmpString;
extern char *errorMessage;
extern const char commonBugScreenMessages[NUMBER_OF_BUG_SCREEN_MESSAGES][SIZE_OF_EACH_BUG_SCREEN_MESSAGE];

// ---------------------------------------------------------------------------
// Everything flags.c calls out to. The counting bodies live in
// flags_fake_runtime.c and are shared by BOTH implementations, which is the
// point: the two sides are indistinguishable to their environment.
// ---------------------------------------------------------------------------
void fnRefreshState(void);
void reallyClearStatusBar(uint8_t info);
void fnChangeBaseJM(uint16_t base);
void showAlphaModeonGui(void);
void leaveTamModeIfEnabled(void);
void calcModeAim(uint16_t unusedButMandatoryParameter);
void calcModeNormal(void);
void popSoftmenu(void);
void deleteEquation(uint16_t equation);
void setConfirmationMode(void (*func)(uint16_t));
void displayCalcErrorMessage(uint8_t errorCode, calcRegister_t errMessageRegisterLine, calcRegister_t disUsedCanBeRemoved);
void displayBugScreen(const char *msg);
void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4);

// The Zig owner's exports, under their c43 names -- this is the side under test.
#include "../../../upstream/src/c47/flags.h"

#endif
