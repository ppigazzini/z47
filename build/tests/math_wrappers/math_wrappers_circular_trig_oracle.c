// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "../../../src/c47/c47.h"

typedef enum {
  CTX_39,
  CTX_75,
} contextKind_t;

typedef enum {
  INPUT_TEXT,
  INPUT_NAN,
  INPUT_PI_ON4,
  INPUT_PI_ON2,
  INPUT_PI,
  INPUT_3PI_ON2,
} inputKind_t;

typedef struct {
  const char *name;
  contextKind_t contextKind;
  angularMode_t mode;
  inputKind_t inputKind;
  const char *text;
} circularTrigCase_t;

void z47_math_wrappers_owned_C47_WP34S_Cvt2RadSinCosTan(const real_t *angle, angularMode_t mode, real_t *sin, real_t *cos, real_t *tan, realContext_t *realContext);
void C47_WP34S_Cvt2RadSinCosTan(const real_t *angle, angularMode_t mode, real_t *sin, real_t *cos, real_t *tan, realContext_t *realContext);

static const circularTrigCase_t circularTrigCases[] = {
  {"nan_radian_39", CTX_39, amRadian, INPUT_NAN, NULL},
  {"zero_degree_39", CTX_39, amDegree, INPUT_TEXT, "0"},
  {"pi_on4_radian_39", CTX_39, amRadian, INPUT_PI_ON4, NULL},
  {"pi_on2_radian_39", CTX_39, amRadian, INPUT_PI_ON2, NULL},
  {"three_pi_on2_radian_39", CTX_39, amRadian, INPUT_3PI_ON2, NULL},
  {"degree_45_75", CTX_75, amDegree, INPUT_TEXT, "45"},
  {"degree_225_75", CTX_75, amDegree, INPUT_TEXT, "225"},
  {"degree_negative_30_75", CTX_75, amDegree, INPUT_TEXT, "-30"},
  {"grad_50_75", CTX_75, amGrad, INPUT_TEXT, "50"},
  {"grad_250_75", CTX_75, amGrad, INPUT_TEXT, "250"},
  {"multpi_quarter_75", CTX_75, amMultPi, INPUT_TEXT, "0.25"},
  {"multpi_five_quarters_75", CTX_75, amMultPi, INPUT_TEXT, "1.25"},
  {"degree_450_75", CTX_75, amDegree, INPUT_TEXT, "450"},
  {"radian_small_75", CTX_75, amRadian, INPUT_TEXT, "0.1"},
  {"radian_large_negative_75", CTX_75, amRadian, INPUT_TEXT, "-10"},
};

static realContext_t *selectContext(contextKind_t contextKind) {
  return contextKind == CTX_75 ? &ctxtReal75 : &ctxtReal39;
}

static void initRuntime(void) {
  mp_set_memory_functions(allocGmp, reallocGmp, freeGmp);
  c47MemInBlocks = 0;
  gmpMemInBytes = 0;
  fnReset(CONFIRMED);
}

static void initInput(real_t *value, inputKind_t kind, const char *text, realContext_t *realContext) {
  switch(kind) {
    case INPUT_TEXT:
      stringToReal(text, value, realContext);
      break;
    case INPUT_NAN:
      realSetNaN(value);
      break;
    case INPUT_PI_ON4:
      realCopy(const75_piOn4, value);
      break;
    case INPUT_PI_ON2:
      realCopy(const75_piOn2, value);
      break;
    case INPUT_PI:
      realCopy(const75_pi, value);
      break;
    case INPUT_3PI_ON2:
      realCopy(const75_pi, value);
      realAdd(value, const75_piOn2, value, realContext);
      break;
  }
}

static bool_t sameReal(const real_t *expected, const real_t *actual) {
  char expectedText[TMP_STR_LENGTH];
  char actualText[TMP_STR_LENGTH];

  if(realIsNaN(expected) && realIsNaN(actual)) {
    return true;
  }

  realToString(expected, expectedText);
  realToString(actual, actualText);
  return strcmp(expectedText, actualText) == 0;
}

static void printMismatch(const circularTrigCase_t *testCase,
                          const real_t *expectedSin,
                          const real_t *expectedCos,
                          const real_t *expectedTan,
                          const real_t *actualSin,
                          const real_t *actualCos,
                          const real_t *actualTan) {
  char expectedSinText[TMP_STR_LENGTH];
  char expectedCosText[TMP_STR_LENGTH];
  char expectedTanText[TMP_STR_LENGTH];
  char actualSinText[TMP_STR_LENGTH];
  char actualCosText[TMP_STR_LENGTH];
  char actualTanText[TMP_STR_LENGTH];

  realToString(expectedSin, expectedSinText);
  realToString(expectedCos, expectedCosText);
  realToString(expectedTan, expectedTanText);
  realToString(actualSin, actualSinText);
  realToString(actualCos, actualCosText);
  realToString(actualTan, actualTanText);

  printf("circular trig oracle mismatch for %s\n", testCase->name);
  printf("  expected: (%s, %s, %s)\n", expectedSinText, expectedCosText, expectedTanText);
  printf("  actual:   (%s, %s, %s)\n", actualSinText, actualCosText, actualTanText);
}

static int runCase(const circularTrigCase_t *testCase) {
  real_t angle;
  real_t expectedSin;
  real_t expectedCos;
  real_t expectedTan;
  real_t actualSin;
  real_t actualCos;
  real_t actualTan;
  realContext_t *realContext = selectContext(testCase->contextKind);

  initInput(&angle, testCase->inputKind, testCase->text, realContext);
  C47_WP34S_Cvt2RadSinCosTan(&angle, testCase->mode, &expectedSin, &expectedCos, &expectedTan, realContext);
  z47_math_wrappers_owned_C47_WP34S_Cvt2RadSinCosTan(&angle, testCase->mode, &actualSin, &actualCos, &actualTan, realContext);

  if(!sameReal(&expectedSin, &actualSin) || !sameReal(&expectedCos, &actualCos) || !sameReal(&expectedTan, &actualTan)) {
    printMismatch(testCase, &expectedSin, &expectedCos, &expectedTan, &actualSin, &actualCos, &actualTan);
    return 1;
  }

  return 0;
}

int main(void) {
  size_t failures = 0;

  initRuntime();

  for(size_t i = 0; i < sizeof(circularTrigCases) / sizeof(circularTrigCases[0]); ++i) {
    failures += (size_t)runCase(&circularTrigCases[i]);
  }

  if(failures != 0) {
    printf("circular trig oracle failed %zu case(s)\n", failures);
    return 1;
  }

  printf("circular trig oracle passed %zu case(s)\n", sizeof(circularTrigCases) / sizeof(circularTrigCases[0]));
  return 0;
}
