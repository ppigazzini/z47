// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "../../../src/c47/c47.h"

typedef enum {
  INPUT_TEXT,
  INPUT_POS_INF,
  INPUT_NEG_INF,
  INPUT_NAN,
} inputKind_t;

typedef struct {
  const char *name;
  inputKind_t kind;
  const char *text;
} atanCase_t;

void z47_math_wrappers_owned_C47_WP34S_Atan(const real_t *x, real_t *angle, realContext_t *realContext);
void C47_WP34S_Atan(const real_t *x, real_t *angle, realContext_t *realContext);

static const atanCase_t atanCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"pos_zero", INPUT_TEXT, "0"},
  {"neg_zero", INPUT_TEXT, "-0"},
  {"small_positive", INPUT_TEXT, "0.1"},
  {"small_negative", INPUT_TEXT, "-0.1"},
  {"fractional_positive", INPUT_TEXT, "0.75"},
  {"fractional_negative", INPUT_TEXT, "-0.75"},
  {"one", INPUT_TEXT, "1"},
  {"minus_one", INPUT_TEXT, "-1"},
  {"two", INPUT_TEXT, "2"},
  {"minus_two", INPUT_TEXT, "-2"},
  {"ten", INPUT_TEXT, "10"},
  {"minus_ten", INPUT_TEXT, "-10"},
  {"huge", INPUT_TEXT, "1E100"},
  {"minus_huge", INPUT_TEXT, "-1E100"},
  {"pos_inf", INPUT_POS_INF, NULL},
  {"neg_inf", INPUT_NEG_INF, NULL},
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
  char expectedText[TMP_STR_LENGTH];
  char actualText[TMP_STR_LENGTH];

  realToString(expected, expectedText);
  realToString(actual, actualText);
  return strcmp(expectedText, actualText) == 0;
}

static void printMismatch(const atanCase_t *testCase, const real_t *expected, const real_t *actual) {
  char expectedText[TMP_STR_LENGTH];
  char actualText[TMP_STR_LENGTH];

  realToString(expected, expectedText);
  realToString(actual, actualText);

  printf("atan oracle mismatch for %s\n", testCase->name);
  printf("  expected: %s\n", expectedText);
  printf("  actual:   %s\n", actualText);
}

static int runCase(const atanCase_t *testCase) {
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&x, testCase->kind, testCase->text);

  C47_WP34S_Atan(&x, &expected, &ctxtReal39);
  z47_math_wrappers_owned_C47_WP34S_Atan(&x, &actual, &ctxtReal39);

  if(!sameReal(&expected, &actual)) {
    printMismatch(testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

int main(void) {
  size_t failures = 0;

  initRuntime();

  for(size_t i = 0; i < sizeof(atanCases) / sizeof(atanCases[0]); ++i) {
    failures += (size_t)runCase(&atanCases[i]);
  }

  if(failures != 0) {
    printf("atan oracle failed %zu case(s)\n", failures);
    return 1;
  }

  printf("atan oracle passed %zu case(s)\n", sizeof(atanCases) / sizeof(atanCases[0]));
  return 0;
}