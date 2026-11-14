// SPDX-License-Identifier: GPL-3.0-only
//
// matrix-editor parity: z47's matrix editor against c43's, in one binary.
//
// WHAT THIS LANE IS FOR. The matrix editor (ui/matrixEditor.c upstream,
// src/shell/matrix_editor/ here) is where I and J move, where they wrap at the
// edges of a matrix under FLAG_WRAPEDG and FLAG_WRAPEND, where FLAG_GROW turns a
// step past the last element into a new row, and where rows and columns are
// inserted and deleted. The testSuite drives none of it, and no lane compared it
// with c43 before this one.
//
// HOW IT WORKS. matrix_editor_oracle.c compiles c43's own matrixEditor.c a second
// time under `oracle_` names. Both implementations then share one calculator --
// the register file, the matrix codecs, the flags and the editor's own variables
// (matrixIndex, openMatrixMIMPointer, I and J's shadows) -- so a difference can
// only come from the code under test.
//
// SEED / RUN / SNAPSHOT, twice. Each case is a short sequence of editor
// operations. It is run once through the Zig owners and once through c43's
// bodies, each from a freshly seeded calculator, and the two snapshots are
// compared. A side enters the editor through its own fnEditMatrix or reaches an
// indexed matrix through the shared fnIndexMatrix, never by assigning
// matrixIndex or calcMode.
//
// WHAT IS NOT COMPARED: pixels. The editor draws, and both sides draw through
// the same display code, but this lane compares state -- flags, I and J, the
// editor's variables, the open matrix and the matrix register.

#include <c47.h>

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include "../common/harness_resource_budget.h"

// Screen/GUI globals the core references; normally testSuite.c's. Headless here.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;

// The core->shell host-hook table. The editor redraws and reports errors through
// it, and an unbound hook is a no-op that would hide what c43's direct calls do.
extern void (*z47HostShowBugScreenHook)(const char *msg);
extern void (*z47HostRequestRefreshHook)(uint16_t id);

// matrixEditor.c's own variables that no upstream header declares. Both sides
// share the owner's definitions (see matrix_editor_oracle.c).
extern uint16_t scrollRow;
extern uint16_t scrollColumn;
extern uint16_t tmpRow;

// ---------------------------------------------------------------------------
// The two implementations. Unprefixed names are the Zig owners' exports,
// declared by upstream's matrixEditor.h via <c47.h>; `oracle_` ones are c43's.
// ---------------------------------------------------------------------------
extern void    oracle_fnEditMatrix(uint16_t regist);
extern void    oracle_fnGoToRow(uint16_t row);
extern void    oracle_fnGoToColumn(uint16_t col);
extern void    oracle_fnSetGrowMode(uint16_t growFlag);
extern void    oracle_fnIncDecI(uint16_t mode);
extern void    oracle_fnIncDecJ(uint16_t mode);
extern void    oracle_fnInsRow(uint16_t unusedParamButMandatory);
extern void    oracle_fnAddRow(uint16_t unusedParamButMandatory);
extern void    oracle_fnInsCol(uint16_t unusedParamButMandatory);
extern void    oracle_fnAddCol(uint16_t unusedParamButMandatory);
extern void    oracle_fnDelRow(uint16_t unusedParamButMandatory);
extern void    oracle_fnDelCol(uint16_t unusedParamButMandatory);
extern void    oracle_setIRegisterAsInt(bool_t asArrayPointer, int16_t toStore);
extern void    oracle_setJRegisterAsInt(bool_t asArrayPointer, int16_t toStore);
extern void    oracle_mimEnter(bool_t commit);
extern void    oracle_mimFinalize(void);

typedef struct {
  const char *name;
  void      (*editMatrix)(uint16_t);
  void      (*goToRow)(uint16_t);
  void      (*goToColumn)(uint16_t);
  void      (*setGrowMode)(uint16_t);
  void      (*incDecI)(uint16_t);
  void      (*incDecJ)(uint16_t);
  void      (*insRow)(uint16_t);
  void      (*addRow)(uint16_t);
  void      (*insCol)(uint16_t);
  void      (*addCol)(uint16_t);
  void      (*delRow)(uint16_t);
  void      (*delCol)(uint16_t);
  void      (*setI)(bool_t, int16_t);
  void      (*setJ)(bool_t, int16_t);
  void      (*mimEnter)(bool_t);
  void      (*mimFinalize)(void);
} side_t;

static const side_t OWNER = {
  "z47", fnEditMatrix, fnGoToRow, fnGoToColumn, fnSetGrowMode, fnIncDecI, fnIncDecJ,
  fnInsRow, fnAddRow, fnInsCol, fnAddCol, fnDelRow, fnDelCol,
  setIRegisterAsInt, setJRegisterAsInt, mimEnter, mimFinalize,
};

static const side_t ORACLE = {
  "c43", oracle_fnEditMatrix, oracle_fnGoToRow, oracle_fnGoToColumn, oracle_fnSetGrowMode,
  oracle_fnIncDecI, oracle_fnIncDecJ, oracle_fnInsRow, oracle_fnAddRow, oracle_fnInsCol,
  oracle_fnAddCol, oracle_fnDelRow, oracle_fnDelCol, oracle_setIRegisterAsInt,
  oracle_setJRegisterAsInt, oracle_mimEnter, oracle_mimFinalize,
};

static int failures = 0;
static int cases = 0;

static void fail(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  printf("FAIL: ");
  vprintf(fmt, ap);
  printf("\n");
  va_end(ap);
  failures++;
}

// ---------------------------------------------------------------------------
// The fixture: a matrix in R10, and the three flags the editor branches on.
// ---------------------------------------------------------------------------
#define MATRIX_REGISTER 10

typedef struct {
  const char *name;
  uint16_t    rows;
  uint16_t    cols;
  bool_t      complex;
} shape_t;

static const shape_t SHAPES[] = {
  { "1x1",        1, 1, false },
  { "1x3",        1, 3, false },
  { "3x1",        3, 1, false },
  { "2x3",        2, 3, false },
  { "complex2x2", 2, 2, true  },
};

typedef struct {
  const char *name;
  bool_t      wrapEdge;
  bool_t      wrapEnd;
  bool_t      grow;
} flags_t;

static const flags_t FLAG_SETS[] = {
  { "none",          false, false, false },
  { "wrapEdg",       true,  false, false },
  { "wrapEnd",       false, true,  false },
  { "wrapEdg+End",   true,  true,  false },
  { "grow",          false, false, true  },
  { "grow+wrapEdg",  true,  false, true  },
};

static void seedMatrix(const shape_t *shape) {
  initMatrixRegister(MATRIX_REGISTER, shape->rows, shape->cols, shape->complex);
  const int n = shape->rows * shape->cols;
  for(int e = 0; e < n; e++) {
    if(shape->complex) {
      int32ToReal34(e + 1,  VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(MATRIX_REGISTER) + e));
      int32ToReal34(-e - 1, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(MATRIX_REGISTER) + e));
    }
    else {
      int32ToReal34(e + 1, REGISTER_REAL34_MATRIX_ELEMENTS(MATRIX_REGISTER) + e);
    }
  }
}

static void seed(const shape_t *shape, const flags_t *flags) {
  fnReset(CONFIRMED);
  seedMatrix(shape);
  flags->wrapEdge ? setSystemFlag(FLAG_WRAPEDG) : clearSystemFlag(FLAG_WRAPEDG);
  flags->wrapEnd  ? setSystemFlag(FLAG_WRAPEND) : clearSystemFlag(FLAG_WRAPEND);
  flags->grow     ? setSystemFlag(FLAG_GROW)    : clearSystemFlag(FLAG_GROW);
  lastErrorCode = ERROR_NONE;
  temporaryInformation = TI_NO_INFO;
}

// ---------------------------------------------------------------------------
// The snapshot: everything the editor's state functions can leave behind.
// ---------------------------------------------------------------------------
typedef struct {
  uint64_t systemFlags0;
  uint64_t systemFlags1;
  uint8_t  lastErrorCode;
  uint8_t  temporaryInformation;
  uint8_t  calcMode;
  uint16_t matrixIndex;
  uint16_t scrollRow;
  uint16_t scrollColumn;
  uint16_t tmpRow;
  int16_t  shadowI;
  int16_t  shadowJ;
  char     registers[512];
  char     openMatrix[2048];
  char     matrixRegister[2048];
} snapshot_t;

static void appendReal34(char *dest, size_t size, const real34_t *value) {
  char text[64];
  real34ToString(value, text);
  size_t used = strlen(dest);
  snprintf(dest + used, size - used, "%s ", text);
}

static void describeMatrix(char *dest, size_t size, uint16_t rows, uint16_t cols, bool_t complex, const void *elements) {
  snprintf(dest, size, "%ux%u%s: ", rows, cols, complex ? "c" : "");
  if(elements == NULL) {
    return;
  }
  for(int e = 0; e < rows * cols; e++) {
    if(complex) {
      appendReal34(dest, size, VARIABLE_REAL34_DATA((const complex34_t *)elements + e));
      appendReal34(dest, size, VARIABLE_IMAG34_DATA((const complex34_t *)elements + e));
    }
    else {
      appendReal34(dest, size, (const real34_t *)elements + e);
    }
  }
}

static void describeRegister(char *dest, size_t size, calcRegister_t regist) {
  const uint32_t type = getRegisterDataType(regist);
  size_t used = strlen(dest);
  if(type == dtReal34) {
    char text[64];
    real34ToString(REGISTER_REAL34_DATA(regist), text);
    snprintf(dest + used, size - used, "r%d=%s ", regist, text);
  }
  else {
    snprintf(dest + used, size - used, "r%d:type%u ", regist, (unsigned)type);
  }
}

static void takeSnapshot(snapshot_t *out) {
  memset(out, 0, sizeof(*out));
  out->systemFlags0         = systemFlags0;
  out->systemFlags1         = systemFlags1;
  out->lastErrorCode        = lastErrorCode;
  out->temporaryInformation = temporaryInformation;
  out->calcMode             = calcMode;
  out->matrixIndex          = matrixIndex;
  out->scrollRow            = scrollRow;
  out->scrollColumn         = scrollColumn;
  out->tmpRow               = tmpRow;
  out->shadowI              = shadowI;
  out->shadowJ              = shadowJ;

  describeRegister(out->registers, sizeof(out->registers), REGISTER_I);
  describeRegister(out->registers, sizeof(out->registers), REGISTER_J);
  describeRegister(out->registers, sizeof(out->registers), REGISTER_X);

  if(calcMode == CM_MIM) {
    const bool_t complex = getRegisterDataType(matrixIndex) == dtComplex34Matrix;
    describeMatrix(out->openMatrix, sizeof(out->openMatrix),
                   openMatrixMIMPointer.header.matrixRows, openMatrixMIMPointer.header.matrixColumns, complex,
                   complex ? (const void *)openMatrixMIMPointer.complexMatrix.matrixElements
                           : (const void *)openMatrixMIMPointer.realMatrix.matrixElements);
  }

  const uint32_t type = getRegisterDataType(MATRIX_REGISTER);
  if(type == dtReal34Matrix || type == dtComplex34Matrix) {
    const matrixHeader_t *header = REGISTER_MATRIX_HEADER(MATRIX_REGISTER);
    const bool_t complex = type == dtComplex34Matrix;
    describeMatrix(out->matrixRegister, sizeof(out->matrixRegister), header->matrixRows, header->matrixColumns, complex,
                   complex ? (const void *)REGISTER_COMPLEX34_MATRIX_ELEMENTS(MATRIX_REGISTER)
                           : (const void *)REGISTER_REAL34_MATRIX_ELEMENTS(MATRIX_REGISTER));
  }
  else {
    snprintf(out->matrixRegister, sizeof(out->matrixRegister), "type%u", (unsigned)type);
  }
}

static void compareSnapshots(const char *caseName, const snapshot_t *z, const snapshot_t *c) {
  if(z->systemFlags0 != c->systemFlags0 || z->systemFlags1 != c->systemFlags1) {
    fail("%s: systemFlags z47=%016llx/%016llx c43=%016llx/%016llx", caseName,
         (unsigned long long)z->systemFlags0, (unsigned long long)z->systemFlags1,
         (unsigned long long)c->systemFlags0, (unsigned long long)c->systemFlags1);
  }
  if(z->lastErrorCode != c->lastErrorCode) {
    fail("%s: lastErrorCode z47=%u c43=%u", caseName, z->lastErrorCode, c->lastErrorCode);
  }
  if(z->temporaryInformation != c->temporaryInformation) {
    fail("%s: temporaryInformation z47=%u c43=%u", caseName, z->temporaryInformation, c->temporaryInformation);
  }
  if(z->calcMode != c->calcMode) {
    fail("%s: calcMode z47=%u c43=%u", caseName, z->calcMode, c->calcMode);
  }
  if(z->matrixIndex != c->matrixIndex || z->scrollRow != c->scrollRow || z->scrollColumn != c->scrollColumn
     || z->tmpRow != c->tmpRow || z->shadowI != c->shadowI || z->shadowJ != c->shadowJ) {
    fail("%s: editor variables z47=(index %u scroll %u,%u tmpRow %u shadow %d,%d) c43=(index %u scroll %u,%u tmpRow %u shadow %d,%d)",
         caseName, z->matrixIndex, z->scrollRow, z->scrollColumn, z->tmpRow, z->shadowI, z->shadowJ,
         c->matrixIndex, c->scrollRow, c->scrollColumn, c->tmpRow, c->shadowI, c->shadowJ);
  }
  if(strcmp(z->registers, c->registers) != 0) {
    fail("%s: registers z47=[%s] c43=[%s]", caseName, z->registers, c->registers);
  }
  if(strcmp(z->openMatrix, c->openMatrix) != 0) {
    fail("%s: open matrix z47=[%s] c43=[%s]", caseName, z->openMatrix, c->openMatrix);
  }
  if(strcmp(z->matrixRegister, c->matrixRegister) != 0) {
    fail("%s: matrix register z47=[%s] c43=[%s]", caseName, z->matrixRegister, c->matrixRegister);
  }
}

// ---------------------------------------------------------------------------
// The cases. A case is a sequence of steps, run against one side's functions.
// ---------------------------------------------------------------------------
typedef enum {
  STEP_INDEX,        // the shared fnIndexMatrix(R10): an indexed matrix, not MIM
  STEP_EDIT,         // the side's fnEditMatrix(R10): enter MIM
  STEP_SET_IJ,       // the side's I and J setters, 0-based
  STEP_INC_I, STEP_DEC_I, STEP_INC_J, STEP_DEC_J,
  STEP_INS_ROW, STEP_ADD_ROW, STEP_INS_COL, STEP_ADD_COL, STEP_DEL_ROW, STEP_DEL_COL,
  STEP_GOTO,         // the side's fnGoToRow then fnGoToColumn, 1-based
  STEP_GROW_MODE,    // the side's fnSetGrowMode
  STEP_COMMIT,       // the side's mimEnter(true) then mimFinalize
} step_kind_t;

typedef struct {
  step_kind_t kind;
  int16_t     a;
  int16_t     b;
} step_t;

static void runStep(const side_t *side, step_t step) {
  switch(step.kind) {
    case STEP_INDEX:     fnIndexMatrix(MATRIX_REGISTER);            break;
    case STEP_EDIT:      side->editMatrix(MATRIX_REGISTER);         break;
    case STEP_SET_IJ:    side->setI(true, step.a); side->setJ(true, step.b); break;
    case STEP_INC_I:     side->incDecI(INC_FLAG);                   break;
    case STEP_DEC_I:     side->incDecI(DEC_FLAG);                   break;
    case STEP_INC_J:     side->incDecJ(INC_FLAG);                   break;
    case STEP_DEC_J:     side->incDecJ(DEC_FLAG);                   break;
    case STEP_INS_ROW:   side->insRow(NOPARAM);                     break;
    case STEP_ADD_ROW:   side->addRow(NOPARAM);                     break;
    case STEP_INS_COL:   side->insCol(NOPARAM);                     break;
    case STEP_ADD_COL:   side->addCol(NOPARAM);                     break;
    case STEP_DEL_ROW:   side->delRow(NOPARAM);                     break;
    case STEP_DEL_COL:   side->delCol(NOPARAM);                     break;
    case STEP_GOTO:      side->goToRow((uint16_t)step.a); side->goToColumn((uint16_t)step.b); break;
    case STEP_GROW_MODE: side->setGrowMode((uint16_t)step.a);       break;
    case STEP_COMMIT:    side->mimEnter(true); side->mimFinalize(); break;
  }
}

static void runCase(const char *caseName, const shape_t *shape, const flags_t *flags, const step_t *steps, int stepCount) {
  snapshot_t z, c;

  harnessBudgetSetCase(caseName);
  seed(shape, flags);
  for(int s = 0; s < stepCount; s++) {
    runStep(&OWNER, steps[s]);
  }
  takeSnapshot(&z);

  seed(shape, flags);
  for(int s = 0; s < stepCount; s++) {
    runStep(&ORACLE, steps[s]);
  }
  takeSnapshot(&c);
  harnessBudgetCaseFinished();

  compareSnapshots(caseName, &z, &c);
  cases++;
}

static const struct { const char *name; step_kind_t kind; } MOVES[] = {
  { "incI", STEP_INC_I }, { "decI", STEP_DEC_I }, { "incJ", STEP_INC_J }, { "decJ", STEP_DEC_J },
};

static const struct { const char *name; step_kind_t kind; } EDITS[] = {
  { "insRow", STEP_INS_ROW }, { "addRow", STEP_ADD_ROW }, { "insCol", STEP_INS_COL },
  { "addCol", STEP_ADD_COL }, { "delRow", STEP_DEL_ROW }, { "delCol", STEP_DEL_COL },
};

// I and J at the four corners: the wrap rules decide what happens at an edge, so
// the corners are the classes. A 1xN or Nx1 matrix makes two corners coincide.
static void cornerOf(const shape_t *shape, int corner, int16_t *i, int16_t *j) {
  *i = (corner & 1) ? (int16_t)(shape->rows - 1) : 0;
  *j = (corner & 2) ? (int16_t)(shape->cols - 1) : 0;
}

static void runMoveCases(void) {
  char caseName[160];
  for(size_t s = 0; s < sizeof(SHAPES) / sizeof(SHAPES[0]); s++) {
    for(size_t f = 0; f < sizeof(FLAG_SETS) / sizeof(FLAG_SETS[0]); f++) {
      for(int corner = 0; corner < 4; corner++) {
        int16_t i, j;
        cornerOf(&SHAPES[s], corner, &i, &j);
        for(size_t m = 0; m < sizeof(MOVES) / sizeof(MOVES[0]); m++) {
          // Indexed: the shared fnIndexMatrix, then the side's own I/J moves.
          const step_t indexed[] = { { STEP_INDEX, 0, 0 }, { STEP_SET_IJ, i, j }, { MOVES[m].kind, 0, 0 } };
          snprintf(caseName, sizeof(caseName), "indexed/%s/%s/at%d,%d/%s", SHAPES[s].name, FLAG_SETS[f].name, i, j, MOVES[m].name);
          runCase(caseName, &SHAPES[s], &FLAG_SETS[f], indexed, 3);

          // Twice in a row, so a wrap that moves to the next row or column is
          // followed by a step from where it landed.
          const step_t twice[] = { { STEP_INDEX, 0, 0 }, { STEP_SET_IJ, i, j }, { MOVES[m].kind, 0, 0 }, { MOVES[m].kind, 0, 0 } };
          snprintf(caseName, sizeof(caseName), "indexed/%s/%s/at%d,%d/%s x2", SHAPES[s].name, FLAG_SETS[f].name, i, j, MOVES[m].name);
          runCase(caseName, &SHAPES[s], &FLAG_SETS[f], twice, 4);
        }
      }
    }
  }
}

static void runEditCases(void) {
  char caseName[160];
  for(size_t s = 0; s < sizeof(SHAPES) / sizeof(SHAPES[0]); s++) {
    for(size_t f = 0; f < sizeof(FLAG_SETS) / sizeof(FLAG_SETS[0]); f++) {
      for(int corner = 0; corner < 4; corner++) {
        int16_t i, j;
        cornerOf(&SHAPES[s], corner, &i, &j);
        for(size_t e = 0; e < sizeof(EDITS) / sizeof(EDITS[0]); e++) {
          const step_t edit[] = { { STEP_EDIT, 0, 0 }, { STEP_SET_IJ, i, j }, { EDITS[e].kind, 0, 0 }, { STEP_COMMIT, 0, 0 } };
          snprintf(caseName, sizeof(caseName), "mim/%s/%s/at%d,%d/%s", SHAPES[s].name, FLAG_SETS[f].name, i, j, EDITS[e].name);
          runCase(caseName, &SHAPES[s], &FLAG_SETS[f], edit, 4);
        }
      }
    }
  }
}

// GOTO: in range, at both ends, and out of range in each coordinate.
static void runGotoCases(void) {
  static const struct { int16_t row; int16_t col; } TARGETS[] = {
    { 1, 1 }, { 2, 2 }, { 3, 3 }, { 0, 1 }, { 1, 0 }, { 4, 1 }, { 1, 4 },
  };
  char caseName[160];
  for(size_t s = 0; s < sizeof(SHAPES) / sizeof(SHAPES[0]); s++) {
    for(size_t t = 0; t < sizeof(TARGETS) / sizeof(TARGETS[0]); t++) {
      const step_t go[] = { { STEP_EDIT, 0, 0 }, { STEP_GOTO, TARGETS[t].row, TARGETS[t].col } };
      snprintf(caseName, sizeof(caseName), "goto/%s/%d,%d", SHAPES[s].name, TARGETS[t].row, TARGETS[t].col);
      runCase(caseName, &SHAPES[s], &FLAG_SETS[0], go, 2);
    }
  }
}

static void runGrowModeCases(void) {
  char caseName[160];
  for(size_t f = 0; f < sizeof(FLAG_SETS) / sizeof(FLAG_SETS[0]); f++) {
    for(int16_t mode = 0; mode < 2; mode++) {
      const step_t grow[] = { { STEP_GROW_MODE, mode, 0 } };
      snprintf(caseName, sizeof(caseName), "growMode/%s/%d", FLAG_SETS[f].name, mode);
      runCase(caseName, &SHAPES[0], &FLAG_SETS[f], grow, 1);
    }
  }
}

int main(void) {
  harnessInstallResourceBudget("matrix-editor parity");
  z47HostShowBugScreenHook = displayBugScreen;
  z47HostRequestRefreshHook = refreshScreen;

  runMoveCases();
  runEditCases();
  runGotoCases();
  runGrowModeCases();

  if(failures != 0) {
    printf("MATRIX-EDITOR PARITY: %d of %d case(s) FAILED\n", failures, cases);
    return 1;
  }
  printf("MATRIX-EDITOR PARITY: %d cases agree\n", cases);
  return 0;
}
