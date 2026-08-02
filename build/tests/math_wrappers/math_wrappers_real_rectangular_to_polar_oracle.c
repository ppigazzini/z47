// SPDX-License-Identifier: GPL-3.0-only

#include "../../../src/c47/c47.h"

typedef enum {
  INPUT_TEXT,
  INPUT_POS_INF,
  INPUT_NEG_INF,
  INPUT_NAN,
} inputKind_t;

typedef struct {
  const char *name;
  inputKind_t realKind;
  const char *realText;
  inputKind_t imagKind;
  const char *imagText;
} realRectangularToPolarCase_t;

void z47_math_wrappers_owned_realRectangularToPolar(const real_t *real, const real_t *imag, real_t *magnitude, real_t *theta, realContext_t *realContext);
void realRectangularToPolar(const real_t *real, const real_t *imag, real_t *magnitude, real_t *theta, realContext_t *realContext);

static const realRectangularToPolarCase_t realRectangularToPolarCases[] = {
  {"real_nan", INPUT_NAN, NULL, INPUT_TEXT, "1"},
  {"imag_nan", INPUT_TEXT, "1", INPUT_NAN, NULL},
  {"neg_inf_neg_inf", INPUT_NEG_INF, NULL, INPUT_NEG_INF, NULL},
  {"neg_inf_pos", INPUT_NEG_INF, NULL, INPUT_TEXT, "2"},
  {"pos_inf_neg_inf", INPUT_POS_INF, NULL, INPUT_NEG_INF, NULL},
  {"pos_inf_pos_inf", INPUT_POS_INF, NULL, INPUT_POS_INF, NULL},
  {"finite_pos_inf", INPUT_TEXT, "2", INPUT_POS_INF, NULL},
  {"finite_neg_inf", INPUT_TEXT, "2", INPUT_NEG_INF, NULL},
  {"zero_zero", INPUT_TEXT, "0", INPUT_TEXT, "0"},
  {"zero_pos_axis", INPUT_TEXT, "0", INPUT_TEXT, "3"},
  {"zero_neg_axis", INPUT_TEXT, "0", INPUT_TEXT, "-3"},
  {"neg_real_axis", INPUT_TEXT, "-3", INPUT_TEXT, "0"},
  {"pos_real_axis", INPUT_TEXT, "3", INPUT_TEXT, "0"},
  {"quadrant_i", INPUT_TEXT, "3", INPUT_TEXT, "4"},
  {"quadrant_ii", INPUT_TEXT, "-3", INPUT_TEXT, "4"},
  {"quadrant_iii", INPUT_TEXT, "-3", INPUT_TEXT, "-4"},
  {"quadrant_iv", INPUT_TEXT, "3", INPUT_TEXT, "-4"},
};

static void initRuntime(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  c47MemInBlocks = 0;
  gmpMemInBytes = 0;
  fnReset(CONFIRMED);
}

static void initInput(real_t *value, inputKind_t kind, const char *text) {
  switch(kind) {
    case INPUT_TEXT:
      stringToReal(text, value, &ctxtReal39);
      break;
    case INPUT_POS_INF:
      realCopy(const_plusInfinity, value);
      break;
    case INPUT_NEG_INF:
      realCopy(const_minusInfinity, value);
      break;
    case INPUT_NAN:
      realSetNaN(value);
      break;
  }
}

static bool_t sameReal(const real_t *expected, const real_t *actual) {
  if(realIsNaN(expected) && realIsNaN(actual)) {
    return true;
  }

  return realCompareEqual(expected, actual);
}

static void printMismatch(const realRectangularToPolarCase_t *testCase, const real_t *expectedMagnitude, const real_t *expectedTheta, const real_t *actualMagnitude, const real_t *actualTheta) {
  char expectedMagnitudeText[TMP_STR_LENGTH];
  char expectedThetaText[TMP_STR_LENGTH];
  char actualMagnitudeText[TMP_STR_LENGTH];
  char actualThetaText[TMP_STR_LENGTH];

  realToString(expectedMagnitude, expectedMagnitudeText);
  realToString(expectedTheta, expectedThetaText);
  realToString(actualMagnitude, actualMagnitudeText);
  realToString(actualTheta, actualThetaText);

  printf("realRectangularToPolar oracle mismatch for %s\n", testCase->name);
  printf("  expected: (%s, %s)\n", expectedMagnitudeText, expectedThetaText);
  printf("  actual:   (%s, %s)\n", actualMagnitudeText, actualThetaText);
}

static int runCase(const realRectangularToPolarCase_t *testCase) {
  real_t real;
  real_t imag;
  real_t expectedMagnitude;
  real_t expectedTheta;
  real_t actualMagnitude;
  real_t actualTheta;

  initInput(&real, testCase->realKind, testCase->realText);
  initInput(&imag, testCase->imagKind, testCase->imagText);

  realRectangularToPolar(&real, &imag, &expectedMagnitude, &expectedTheta, &ctxtReal39);
  z47_math_wrappers_owned_realRectangularToPolar(&real, &imag, &actualMagnitude, &actualTheta, &ctxtReal39);

  if(!sameReal(&expectedMagnitude, &actualMagnitude) || !sameReal(&expectedTheta, &actualTheta)) {
    printMismatch(testCase, &expectedMagnitude, &expectedTheta, &actualMagnitude, &actualTheta);
    return 1;
  }

  return 0;
}

int main(void) {
  size_t failures = 0;

  initRuntime();

  for(size_t i = 0; i < sizeof(realRectangularToPolarCases) / sizeof(realRectangularToPolarCases[0]); ++i) {
    failures += (size_t)runCase(&realRectangularToPolarCases[i]);
  }

  if(failures != 0) {
    printf("realRectangularToPolar oracle failed %zu case(s)\n", failures);
    return 1;
  }

  printf("realRectangularToPolar oracle passed %zu case(s)\n", sizeof(realRectangularToPolarCases) / sizeof(realRectangularToPolarCases[0]));
  return 0;
}
