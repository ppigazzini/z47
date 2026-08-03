// SPDX-License-Identifier: GPL-3.0-only
//
// The one calculator state the calc-state lanes agree to look at.
//
// WHY THIS IS SHARED. Two lanes exercise
// saveRestoreCalcState.c from opposite directions: `saveload_roundtrip` asserts
// that z47's save->load->save is idempotent (a metamorphic relation, which needs
// no external reference), and `calc_state_parity` asserts that z47's bytes equal
// c43's (a differential, which is the only thing that holds the .sav FORMAT to
// c43). They are only comparable if they serialize the SAME calculator, and
// buildState() was already the well-exercised one -- every angular tag, real and
// complex matrices, named variables of four types, local registers, statistics,
// user menus, a non-default display configuration. Copying it would have created
// two fixtures that drift apart, which is this report's own defect in miniature.
//
// EXTRACTED VERBATIM from save_load_roundtrip_harness.c, deliberately: the
// committed golden snapshot is the byte output of THIS state, so any edit here
// changes the golden. Treat an unexplained golden change after touching this file
// as a finding, not a chore.
//
// Include it exactly once per harness binary: it defines the screen/GUI globals
// the core references (normally testSuite.c's) as well as the fixture.

#if !defined(Z47_CALC_STATE_FIXTURE_H)
  #define Z47_CALC_STATE_FIXTURE_H

#define MAX_SAVE (1u << 20)

// Screen/GUI globals the core references; normally defined by testSuite.c,
// which this harness replaces. The harness is headless so they stay unused.
GtkWidget      *screen;
calcKeyboard_t  calcKeyboard[43];
int             currentBezel;
int16_t         screenStride;
uint32_t       *screenData;
bool_t          screenChange;


static long readWholeFile(const char *path, unsigned char *buf, long cap) {
  FILE *f = fopen(path, "rb");
  if(!f) {
    return -1;
  }
  long n = (long)fread(buf, 1, (size_t)cap, f);
  fclose(f);
  return n;
}

// Build a deterministic, non-trivial state so the save exercises the dynamic
// sections (registers with values, a couple of flags) rather than only the
// empty defaults.
static void buildState(void) {
  fnReset(CONFIRMED);

  // Populate global (stack) registers with a DIVERSE set of data types so the
  // GLOBAL_REGISTERS save/restore exercises every value-codec branch of
  // registerToSaveString / restoreRegister (not just dtReal34): real34 (plain
  // and angular-tagged), complex34, short integer, long integer, time, date.
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
  int32ToReal34(-42, REGISTER_REAL34_DATA(REGISTER_Y));

  // real34 with an angular tag -> "Real:DEG"
  reallocateRegister(REGISTER_Z, dtReal34, 0, amDegree);
  int32ToReal34(90, REGISTER_REAL34_DATA(REGISTER_Z));

  // complex34 (3 + 4i)
  reallocateRegister(REGISTER_T, dtComplex34, 0, amNone);
  int32ToReal34(3, REGISTER_REAL34_DATA(REGISTER_T));
  int32ToReal34(4, REGISTER_IMAG34_DATA(REGISTER_T));

  // short integer (hex base)
  convertUInt64ToShortIntegerRegister(0, 0xDEADBEEFULL, 16, REGISTER_A);

  // long integer (arbitrary precision)
  {
    longInteger_t li;
    longIntegerInit(li);
    stringToLongInteger("123456789012345678901234567890", 10, li);
    convertLongIntegerToLongIntegerRegister(li, REGISTER_B);
    longIntegerFree(li);
  }

  // time and date
  reallocateRegister(REGISTER_C, dtTime, 0, amNone);
  int32ToReal34(3600, REGISTER_REAL34_DATA(REGISTER_C));
  reallocateRegister(REGISTER_D, dtDate, 0, amNone);
  int32ToReal34(20260622, REGISTER_REAL34_DATA(REGISTER_D));

  // Every angular tag, so the textTag codec (DEG/DMS/RAD/MULTPI/GRAD + polar)
  // is fully exercised on save AND restore.
  reallocateRegister(0, dtReal34, 0, amRadian);
  int32ToReal34(1, REGISTER_REAL34_DATA(0));
  reallocateRegister(1, dtReal34, 0, amGrad);
  int32ToReal34(2, REGISTER_REAL34_DATA(1));
  reallocateRegister(2, dtReal34, 0, amDMS);
  int32ToReal34(3, REGISTER_REAL34_DATA(2));
  reallocateRegister(3, dtReal34, 0, amMultPi);
  int32ToReal34(4, REGISTER_REAL34_DATA(3));

  // complex34 in polar mode (tag carries amPolar + an angular mode) -> "Cplx:DEGp"
  reallocateRegister(4, dtComplex34, 0, amPolar | amDegree);
  int32ToReal34(5, REGISTER_REAL34_DATA(4));
  int32ToReal34(45, REGISTER_IMAG34_DATA(4));

  // string register
  {
    const char *s = "Hello, C47 \"state\"!";
    reallocateRegister(5, dtString, TO_BLOCKS((int)strlen(s) + 1), amNone);
    strcpy(REGISTER_STRING_DATA(5), s);
  }

  // real34 matrix (2x3) with distinct element values
  initMatrixRegister(6, 2, 3, false);
  for(int e = 0; e < 6; ++e) {
    int32ToReal34(e * 10 + 1, REGISTER_REAL34_MATRIX_ELEMENTS(6) + e);
  }

  // complex34 matrix (2x2) with distinct re/im element values
  initMatrixRegister(7, 2, 2, true);
  for(int e = 0; e < 4; ++e) {
    int32ToReal34(e + 1,   VARIABLE_REAL34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(7) + e));
    int32ToReal34(e + 100, VARIABLE_IMAG34_DATA(REGISTER_COMPLEX34_MATRIX_ELEMENTS(7) + e));
  }

  // 3x3 real matrix (a square dimension distinct from the 2x3/2x2 above), so
  // the matrix save/restore covers a different rows*cols geometry.
  initMatrixRegister(8, 3, 3, false);
  for(int e = 0; e < 9; ++e) {
    int32ToReal34(e * 7 + 2, REGISTER_REAL34_MATRIX_ELEMENTS(8) + e);
  }

  // Named variables of two types land in the NAMED_VARIABLES section.
  allocateNamedVariable("TESTVAR", dtReal34, REAL34_SIZE_IN_BLOCKS);
  int32ToReal34(777, REGISTER_REAL34_DATA(findNamedVariable("TESTVAR")));
  {
    const char *sv = "named string!";
    allocateNamedVariable("STRVAR", dtString, TO_BLOCKS((int)strlen(sv) + 1));
    strcpy(REGISTER_STRING_DATA(findNamedVariable("STRVAR")), sv);
  }
  {
    longInteger_t li;
    longIntegerInit(li);
    stringToLongInteger("9999999999999999999999", 10, li);
    allocateNamedVariable("LIVAR", dtLongInteger, 1);
    convertLongIntegerToLongIntegerRegister(li, findNamedVariable("LIVAR"));
    longIntegerFree(li);
  }
  {
    // A named real variable carrying an angular tag, so the NAMED_VARIABLES
    // textTag codec is exercised on a named entry (not only on stack registers).
    allocateNamedVariable("ANGVAR", dtReal34, REAL34_SIZE_IN_BLOCKS);
    calcRegister_t av = findNamedVariable("ANGVAR");
    reallocateRegister(av, dtReal34, 0, amDegree);
    int32ToReal34(45, REGISTER_REAL34_DATA(av));
  }
  {
    // A named date variable, so the NAMED_VARIABLES section covers the dtDate
    // value type for a named entry (not only the stack date register).
    allocateNamedVariable("DATEVAR", dtReal34, REAL34_SIZE_IN_BLOCKS);
    calcRegister_t dv = findNamedVariable("DATEVAR");
    reallocateRegister(dv, dtDate, 0, amNone);
    int32ToReal34(20240229, REGISTER_REAL34_DATA(dv));
  }
  allocateNamedVariable("CPXVAR", dtComplex34, COMPLEX34_SIZE_IN_BLOCKS);
  {
    calcRegister_t v = findNamedVariable("CPXVAR");
    int32ToReal34(11, REGISTER_REAL34_DATA(v));
    int32ToReal34(22, REGISTER_IMAG34_DATA(v));
  }

  // Accumulate two-variable statistics so the STATISTICAL_SUMS section (and the
  // stat-sum value codec) is exercised rather than left empty.
  {
    const int32_t xs[] = {2, 5, 11}, ys[] = {3, 7, 13};
    for(int k = 0; k < 3; ++k) {
      reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
      int32ToReal34(xs[k], REGISTER_REAL34_DATA(REGISTER_X));
      reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
      int32ToReal34(ys[k], REGISTER_REAL34_DATA(REGISTER_Y));
      fnSigmaAddRem(1); // Sigma+
    }
  }

  // MyMenu / MyAlpha items (the MYMENU / MYALPHA sections) with an argument name.
  userMenuItems[0].item = ITM_ADD;
  userMenuItems[1].item = ITM_SUB;
  strcpy(userAlphaItems[0].argumentName, "Av");
  userAlphaItems[0].item = 100;

  // A user menu with items (the USER_MENUS section, otherwise empty).
  createMenu("UMENU");
  if(numberOfUserMenus > 0) {
    userMenus[numberOfUserMenus - 1].menuItem[0].item = ITM_ADD;
    strcpy(userMenus[numberOfUserMenus - 1].menuItem[1].argumentName, "X");
    userMenus[numberOfUserMenus - 1].menuItem[1].item = 42;
  }

  // Local registers: allocate a subroutine frame with a few registers so the
  // LOCAL_REGISTERS section -- and, on restore, the Zig parser for a non-empty
  // local frame -- is exercised by the round-trip instead of staying at count 0.
  // Mix value types so the local-section codec path is covered, not just dtReal34.
  allocateLocalRegisters(3);
  reallocateRegister(FIRST_LOCAL_REGISTER + 0, dtReal34, 0, amNone);
  int32ToReal34(111, REGISTER_REAL34_DATA(FIRST_LOCAL_REGISTER + 0));
  reallocateRegister(FIRST_LOCAL_REGISTER + 1, dtReal34, 0, amDegree);
  int32ToReal34(222, REGISTER_REAL34_DATA(FIRST_LOCAL_REGISTER + 1));
  convertUInt64ToShortIntegerRegister(0, 0xABCDULL, 16, FIRST_LOCAL_REGISTER + 2);

  // Restore the diverse X/Y values consumed by the statistics accumulation.
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  int32ToReal34(1234, REGISTER_REAL34_DATA(REGISTER_X));
  reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
  int32ToReal34(-42, REGISTER_REAL34_DATA(REGISTER_Y));

  // A couple of user flags land in the GLOBAL_FLAGS section.
  fnSetFlag(5);
  fnSetFlag(42);

  // Non-default display configuration so the OTHER_CONFIGURATION_STUFF codec is
  // exercised on save AND restore, not just the reset defaults. The round-trip
  // (Zig load then re-save) catches a mis-encoded or mis-parsed config field.
  displayFormat = DF_SCI;
  displayFormatDigits = 6;
  roundingMode = RM_HALF_UP;
  timeDisplayFormatDigits = 4;
  displayStack = 2;
  setSystemFlag(FLAG_FRACT); // exercise the SYSTEM_FLAGS section
  setSystemFlag(FLAG_POLAR);
  significantDigits = 16;
  exponentLimit = 42;
  firstGregorianDay = 2299161; // non-default (a uint32 config field)
}

#endif // Z47_CALC_STATE_FIXTURE_H
