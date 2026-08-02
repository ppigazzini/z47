// SPDX-License-Identifier: GPL-3.0-only

#include "../../../src/c47/c47.h"

void z47_math_wrappers_owned_lnComplex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext);
void lnComplex(const real_t *real, const real_t *imag, real_t *lnReal, real_t *lnImag, realContext_t *realContext);

typedef struct {
  const char *name;
  const char *realText;
  const char *imagText;
} lnComplexCase_t;

static const lnComplexCase_t lnComplexCases[] = {
  {"zero", "0", "0"},
  {"positive_real_axis", "2", "0"},
  {"negative_real_axis_pos_zero", "-2", "0"},
  {"negative_real_axis_neg_zero", "-2", "-0"},
  {"positive_imag_axis", "0", "3"},
  {"negative_imag_axis", "0", "-3"},
  {"quadrant_i", "3", "4"},
  {"quadrant_ii", "-3", "4"},
  {"quadrant_iii", "-3", "-4"},
  {"quadrant_iv", "3", "-4"},
  {"tiny_real_large_imag", "1e-40", "7"},
  {"large_real_tiny_imag", "1e40", "-1e-20"},
};

static void initRuntime(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  c47MemInBlocks = 0;
  gmpMemInBytes = 0;
  fnReset(CONFIRMED);
}

static void printMismatch(const lnComplexCase_t *testCase, const real_t *expectedReal, const real_t *expectedImag, const real_t *actualReal, const real_t *actualImag) {
  char expectedRealText[TMP_STR_LENGTH];
  char expectedImagText[TMP_STR_LENGTH];
  char actualRealText[TMP_STR_LENGTH];
  char actualImagText[TMP_STR_LENGTH];

  realToString(expectedReal, expectedRealText);
  realToString(expectedImag, expectedImagText);
  realToString(actualReal, actualRealText);
  realToString(actualImag, actualImagText);

  printf("lnComplex oracle mismatch for %s (%s, %s)\n", testCase->name, testCase->realText, testCase->imagText);
  printf("  expected: (%s, %s)\n", expectedRealText, expectedImagText);
  printf("  actual:   (%s, %s)\n", actualRealText, actualImagText);
}

static int runCase(const lnComplexCase_t *testCase) {
  real_t real;
  real_t imag;
  real_t expectedReal;
  real_t expectedImag;
  real_t actualReal;
  real_t actualImag;

  stringToReal(testCase->realText, &real, &ctxtReal39);
  stringToReal(testCase->imagText, &imag, &ctxtReal39);

  lnComplex(&real, &imag, &expectedReal, &expectedImag, &ctxtReal39);
  z47_math_wrappers_owned_lnComplex(&real, &imag, &actualReal, &actualImag, &ctxtReal39);

  if(!realCompareEqual(&expectedReal, &actualReal) || !realCompareEqual(&expectedImag, &actualImag)) {
    printMismatch(testCase, &expectedReal, &expectedImag, &actualReal, &actualImag);
    return 1;
  }

  return 0;
}

int main(void) {
  size_t failures = 0;

  initRuntime();

  for(size_t i = 0; i < sizeof(lnComplexCases) / sizeof(lnComplexCases[0]); ++i) {
    failures += (size_t)runCase(&lnComplexCases[i]);
  }

  if(failures != 0) {
    printf("lnComplex oracle failed %zu case(s)\n", failures);
    return 1;
  }

  printf("lnComplex oracle passed %zu case(s)\n", sizeof(lnComplexCases) / sizeof(lnComplexCases[0]));
  return 0;
}
