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
  inputKind_t yKind;
  const char *yText;
  inputKind_t xKind;
  const char *xText;
} atan2Case_t;

void z47_math_wrappers_owned_C47_WP34S_Atan2(const real_t *y, const real_t *x, real_t *angle, realContext_t *realContext);
void C47_WP34S_Atan2(const real_t *y, const real_t *x, real_t *angle, realContext_t *realContext);

static const atan2Case_t atan2Cases[] = {
  {"y_nan", INPUT_NAN, NULL, INPUT_TEXT, "1"},
  {"x_nan", INPUT_TEXT, "1", INPUT_NAN, NULL},
  {"pos_zero_pos_zero", INPUT_TEXT, "0", INPUT_TEXT, "0"},
  {"neg_zero_pos_zero", INPUT_TEXT, "-0", INPUT_TEXT, "0"},
  {"pos_zero_neg_zero", INPUT_TEXT, "0", INPUT_TEXT, "-0"},
  {"neg_zero_neg_zero", INPUT_TEXT, "-0", INPUT_TEXT, "-0"},
  {"pos_zero_neg_real", INPUT_TEXT, "0", INPUT_TEXT, "-2"},
  {"neg_zero_neg_real", INPUT_TEXT, "-0", INPUT_TEXT, "-2"},
  {"neg_zero_pos_real", INPUT_TEXT, "-0", INPUT_TEXT, "2"},
  {"positive_y_zero_x", INPUT_TEXT, "3", INPUT_TEXT, "0"},
  {"negative_y_zero_x", INPUT_TEXT, "-3", INPUT_TEXT, "0"},
  {"pos_inf_pos_inf", INPUT_POS_INF, NULL, INPUT_POS_INF, NULL},
  {"pos_inf_neg_inf", INPUT_POS_INF, NULL, INPUT_NEG_INF, NULL},
  {"neg_inf_pos_inf", INPUT_NEG_INF, NULL, INPUT_POS_INF, NULL},
  {"neg_inf_neg_inf", INPUT_NEG_INF, NULL, INPUT_NEG_INF, NULL},
  {"quadrant_i", INPUT_TEXT, "4", INPUT_TEXT, "3"},
  {"quadrant_ii", INPUT_TEXT, "4", INPUT_TEXT, "-3"},
  {"quadrant_iii", INPUT_TEXT, "-4", INPUT_TEXT, "-3"},
  {"quadrant_iv", INPUT_TEXT, "-4", INPUT_TEXT, "3"},
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

static void printMismatch(const atan2Case_t *testCase, const real_t *expected, const real_t *actual) {
  char expectedText[TMP_STR_LENGTH];
  char actualText[TMP_STR_LENGTH];

  realToString(expected, expectedText);
  realToString(actual, actualText);

  printf("atan2 oracle mismatch for %s\n", testCase->name);
  printf("  expected: %s\n", expectedText);
  printf("  actual:   %s\n", actualText);
}

static int runCase(const atan2Case_t *testCase) {
  real_t y;
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&y, testCase->yKind, testCase->yText);
  initInput(&x, testCase->xKind, testCase->xText);

  C47_WP34S_Atan2(&y, &x, &expected, &ctxtReal39);
  z47_math_wrappers_owned_C47_WP34S_Atan2(&y, &x, &actual, &ctxtReal39);

  if(!sameReal(&expected, &actual)) {
    printMismatch(testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

int main(void) {
  size_t failures = 0;

  initRuntime();

  for(size_t i = 0; i < sizeof(atan2Cases) / sizeof(atan2Cases[0]); ++i) {
    failures += (size_t)runCase(&atan2Cases[i]);
  }

  if(failures != 0) {
    printf("atan2 oracle failed %zu case(s)\n", failures);
    return 1;
  }

  printf("atan2 oracle passed %zu case(s)\n", sizeof(atan2Cases) / sizeof(atan2Cases[0]));
  return 0;
}
