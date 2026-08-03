// SPDX-License-Identifier: GPL-3.0-only
//
// Full-core differential for the math command wrappers.
//
// This stage asserts the ENVIRONMENT and runs no comparison cases: that c43's
// fourteen mathematics/*.c compile and link into the full core beside the Zig
// owners that replaced them, and that the renamed references are distinct code
// from the owner's. That a file compiles clean against upstream's own c47.h does
// not predict this. The renames have to survive the real headers, and the failure
// that matters is the one that still LINKS -- a name that resolves to the owner's
// symbol makes the differential compare a thing against itself.

#include "c47.h"

#include <stdio.h>

// Screen/GUI globals the core references; normally testSuite.c's. Headless here.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// The renamed references live in math_wrappers_full_core_oracle.c. Declared here
// so this file can take their addresses; each is c43's own function under an
// `oracle_` name.
void oracle_fnCheckNumber(uint16_t unusedButMandatoryParameter);
void oracle_fnRound(uint16_t unusedButMandatoryParameter);
void oracle_fnIDiv(uint16_t unusedButMandatoryParameter);
void oracle_fnToPolar2(uint16_t unusedButMandatoryParameter);
void oracle_fnUnitVector(uint16_t unusedButMandatoryParameter);
void oracle_fnConjugate(uint16_t unusedButMandatoryParameter);
void oracle_fnAtan2(uint16_t unusedButMandatoryParameter);
void oracle_curtReal(uint16_t unusedButMandatoryParameter);

// typeError is the shared handler c43's headers reduce every per-file `*Error` to
// when EXTRA_INFO_ON_CALC_ERROR is not 1. It is not renamed, so both sides hold
// the same pointer in their dispatch tables' error slots.
void typeError(void);

// c43's five type-dispatch TABLES, renamed alongside the functions. Referencing
// them here is what proves the rename reached file-scope state and not only
// functions -- a missed table would link silently against the Zig owner's.
extern void (*const oracle_idiv[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_idivr[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_arctan2[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_Round[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const oracle_unitVector[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);

// The owner-side tables, for the identity check below. c43 does not declare these
// in c47.h -- they are file-scope in mathematics/*.c -- so they are declared here.
// The Zig owner exports Round, idiv and idivr under c43's own names; arctan2,
// unitVector and curtReal it keeps internal, so only these three can be compared.
extern void (*const idiv[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const idivr[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS][NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);
extern void (*const Round[NUMBER_OF_DATA_TYPES_FOR_CALCULATIONS])(void);

int main(void) {
  // Take one address per family and one per dispatch table. The compiler cannot
  // fold these away and the linker must resolve every one, so a missing or
  // misspelled rename is a link error rather than a green run.
  const void *anchors[] = {
    (const void *)&oracle_fnCheckNumber,
    (const void *)&oracle_fnRound,
    (const void *)&oracle_fnIDiv,
    (const void *)&oracle_fnToPolar2,
    (const void *)&oracle_fnUnitVector,
    (const void *)&oracle_fnConjugate,
    (const void *)&oracle_fnAtan2,
    (const void *)&oracle_curtReal,
    (const void *)oracle_idiv,
    (const void *)oracle_idivr,
    (const void *)oracle_arctan2,
    (const void *)oracle_Round,
    (const void *)oracle_unitVector,
  };

  // The reference and the owner must be DIFFERENT code. If a rename were missed,
  // `oracle_X` and `X` would be one symbol and this would catch it -- which is the
  // failure mode that matters, because it is the one that still links.
  if((const void *)&oracle_fnCheckNumber == (const void *)&fnCheckNumber) {
    printf("math-wrappers full-core: oracle_fnCheckNumber IS fnCheckNumber -- rename did not take\n");
    return 1;
  }
  if((const void *)oracle_Round == (const void *)Round) {
    printf("math-wrappers full-core: oracle_Round IS Round -- dispatch-table rename did not take\n");
    return 1;
  }
  if((const void *)oracle_idiv == (const void *)idiv) {
    printf("math-wrappers full-core: oracle_idiv IS idiv -- dispatch-table rename did not take\n");
    return 1;
  }
  if((const void *)oracle_idivr == (const void *)idivr) {
    printf("math-wrappers full-core: oracle_idivr IS idivr -- dispatch-table rename did not take\n");
    return 1;
  }

  // c43's error slots must hold the shared typeError, not a per-file handler.
  // If a build turns EXTRA_INFO_ON_CALC_ERROR on, c43 declares real roundError /
  // idivError / ... functions instead, they need renaming like everything else,
  // and this catches the day that changes rather than letting the reference and
  // the owner quietly disagree about which handler the table holds.
  if((const void *)oracle_Round[5] != (const void *)&typeError) {
    printf("math-wrappers full-core: oracle_Round error slot is not typeError\n");
    return 1;
  }
  if((const void *)oracle_Round[9] != (const void *)&typeError) {
    printf("math-wrappers full-core: oracle_Round trailing error slot is not typeError\n");
    return 1;
  }

  for(size_t i = 0; i < sizeof(anchors) / sizeof(anchors[0]); i++) {
    if(anchors[i] == NULL) {
      printf("math-wrappers full-core: anchor %zu is NULL\n", i);
      return 1;
    }
  }

  printf("math-wrappers full-core: environment links (96 renamed symbols, 14 c43 files, 0 comparison cases)\n");
  return 0;
}
