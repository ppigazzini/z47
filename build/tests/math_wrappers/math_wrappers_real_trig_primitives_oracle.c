// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "../../../upstream/src/c47/c47.h"

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
} unaryCase_t;

void z47_math_wrappers_owned_C47_WP34S_Asin(const real_t *x, real_t *angle, realContext_t *realContext);
void z47_math_wrappers_owned_C47_WP34S_Acos(const real_t *x, real_t *angle, realContext_t *realContext);
void z47_math_wrappers_owned_WP34S_SinhCosh(const real_t *x, real_t *sinhOut, real_t *coshOut, realContext_t *realContext);
void z47_math_wrappers_owned_WP34S_Tanh(const real_t *x, real_t *res, realContext_t *realContext);
void z47_math_wrappers_owned_WP34S_ArcSinh(const real_t *x, real_t *res, realContext_t *realContext);
void z47_math_wrappers_owned_WP34S_ArcTanh(const real_t *x, real_t *res, realContext_t *realContext);

static const unaryCase_t asinCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"plus_zero", INPUT_TEXT, "0"},
  {"minus_zero", INPUT_TEXT, "-0"},
  {"half", INPUT_TEXT, "0.5"},
  {"minus_half", INPUT_TEXT, "-0.5"},
  {"one", INPUT_TEXT, "1"},
  {"minus_one", INPUT_TEXT, "-1"},
  {"out_of_domain_pos", INPUT_TEXT, "2"},
  {"out_of_domain_neg", INPUT_TEXT, "-2"},
};

static const unaryCase_t acosCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"plus_zero", INPUT_TEXT, "0"},
  {"minus_zero", INPUT_TEXT, "-0"},
  {"half", INPUT_TEXT, "0.5"},
  {"minus_half", INPUT_TEXT, "-0.5"},
  {"one", INPUT_TEXT, "1"},
  {"minus_one", INPUT_TEXT, "-1"},
  {"out_of_domain_pos", INPUT_TEXT, "2"},
  {"out_of_domain_neg", INPUT_TEXT, "-2"},
};

static const unaryCase_t sinhCoshCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"plus_zero", INPUT_TEXT, "0"},
  {"minus_zero", INPUT_TEXT, "-0"},
  {"small", INPUT_TEXT, "0.25"},
  {"minus_small", INPUT_TEXT, "-0.25"},
  {"two", INPUT_TEXT, "2"},
  {"minus_two", INPUT_TEXT, "-2"},
  {"pos_inf", INPUT_POS_INF, NULL},
  {"neg_inf", INPUT_NEG_INF, NULL},
};

static const unaryCase_t tanhCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"plus_zero", INPUT_TEXT, "0"},
  {"minus_zero", INPUT_TEXT, "-0"},
  {"quarter", INPUT_TEXT, "0.25"},
  {"minus_quarter", INPUT_TEXT, "-0.25"},
  {"ten", INPUT_TEXT, "10"},
  {"minus_ten", INPUT_TEXT, "-10"},
  {"hundred", INPUT_TEXT, "100"},
  {"minus_hundred", INPUT_TEXT, "-100"},
  {"pos_inf", INPUT_POS_INF, NULL},
  {"neg_inf", INPUT_NEG_INF, NULL},
};

static const unaryCase_t arcSinhCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"plus_zero", INPUT_TEXT, "0"},
  {"minus_zero", INPUT_TEXT, "-0"},
  {"quarter", INPUT_TEXT, "0.25"},
  {"minus_quarter", INPUT_TEXT, "-0.25"},
  {"ten", INPUT_TEXT, "10"},
  {"minus_ten", INPUT_TEXT, "-10"},
  {"pos_inf", INPUT_POS_INF, NULL},
  {"neg_inf", INPUT_NEG_INF, NULL},
};

static const unaryCase_t arcTanhCases[] = {
  {"nan", INPUT_NAN, NULL},
  {"plus_zero", INPUT_TEXT, "0"},
  {"minus_zero", INPUT_TEXT, "-0"},
  {"quarter", INPUT_TEXT, "0.25"},
  {"minus_quarter", INPUT_TEXT, "-0.25"},
  {"near_one", INPUT_TEXT, "0.9"},
  {"near_minus_one", INPUT_TEXT, "-0.9"},
  {"one", INPUT_TEXT, "1"},
  {"minus_one", INPUT_TEXT, "-1"},
  {"out_of_domain_pos", INPUT_TEXT, "2"},
  {"out_of_domain_neg", INPUT_TEXT, "-2"},
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

  char expectedText[TMP_STR_LENGTH];
  char actualText[TMP_STR_LENGTH];

  realToString(expected, expectedText);
  realToString(actual, actualText);
  return strcmp(expectedText, actualText) == 0;
}

static void printUnaryMismatch(const char *groupName, const unaryCase_t *testCase, const real_t *expected, const real_t *actual) {
  char expectedText[TMP_STR_LENGTH];
  char actualText[TMP_STR_LENGTH];

  realToString(expected, expectedText);
  realToString(actual, actualText);

  printf("%s oracle mismatch for %s\n", groupName, testCase->name);
  printf("  expected: %s\n", expectedText);
  printf("  actual:   %s\n", actualText);
}

static int runAsinCase(const unaryCase_t *testCase) {
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&x, testCase->kind, testCase->text);
  C47_WP34S_Asin(&x, &expected, &ctxtReal39);
  z47_math_wrappers_owned_C47_WP34S_Asin(&x, &actual, &ctxtReal39);

  if(!sameReal(&expected, &actual)) {
    printUnaryMismatch("asin", testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

static int runAcosCase(const unaryCase_t *testCase) {
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&x, testCase->kind, testCase->text);
  C47_WP34S_Acos(&x, &expected, &ctxtReal39);
  z47_math_wrappers_owned_C47_WP34S_Acos(&x, &actual, &ctxtReal39);

  if(!sameReal(&expected, &actual)) {
    printUnaryMismatch("acos", testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

static int runSinhCoshCase(const unaryCase_t *testCase) {
  real_t x;
  real_t expectedSinh;
  real_t expectedCosh;
  real_t actualSinh;
  real_t actualCosh;

  initInput(&x, testCase->kind, testCase->text);
  WP34S_SinhCosh(&x, &expectedSinh, &expectedCosh, &ctxtReal39);
  z47_math_wrappers_owned_WP34S_SinhCosh(&x, &actualSinh, &actualCosh, &ctxtReal39);

  if(!sameReal(&expectedSinh, &actualSinh)) {
    printUnaryMismatch("sinh", testCase, &expectedSinh, &actualSinh);
    return 1;
  }

  if(!sameReal(&expectedCosh, &actualCosh)) {
    printUnaryMismatch("cosh", testCase, &expectedCosh, &actualCosh);
    return 1;
  }

  return 0;
}

static int runTanhCase(const unaryCase_t *testCase) {
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&x, testCase->kind, testCase->text);
  WP34S_Tanh(&x, &expected, &ctxtReal39);
  z47_math_wrappers_owned_WP34S_Tanh(&x, &actual, &ctxtReal39);

  if(!sameReal(&expected, &actual)) {
    printUnaryMismatch("tanh", testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

static int runArcSinhCase(const unaryCase_t *testCase) {
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&x, testCase->kind, testCase->text);
  WP34S_ArcSinh(&x, &expected, &ctxtReal51);
  z47_math_wrappers_owned_WP34S_ArcSinh(&x, &actual, &ctxtReal51);

  if(!sameReal(&expected, &actual)) {
    printUnaryMismatch("arcsinh", testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

static int runArcTanhCase(const unaryCase_t *testCase) {
  real_t x;
  real_t expected;
  real_t actual;

  initInput(&x, testCase->kind, testCase->text);
  WP34S_ArcTanh(&x, &expected, &ctxtReal39);
  z47_math_wrappers_owned_WP34S_ArcTanh(&x, &actual, &ctxtReal39);

  if(!sameReal(&expected, &actual)) {
    printUnaryMismatch("arctanh", testCase, &expected, &actual);
    return 1;
  }

  return 0;
}

int main(void) {
  size_t failures = 0;
  const size_t totalCases =
      sizeof(asinCases) / sizeof(asinCases[0]) +
      sizeof(acosCases) / sizeof(acosCases[0]) +
      sizeof(sinhCoshCases) / sizeof(sinhCoshCases[0]) +
      sizeof(tanhCases) / sizeof(tanhCases[0]) +
      sizeof(arcSinhCases) / sizeof(arcSinhCases[0]) +
      sizeof(arcTanhCases) / sizeof(arcTanhCases[0]);

  initRuntime();

  for(size_t i = 0; i < sizeof(asinCases) / sizeof(asinCases[0]); ++i) {
    failures += (size_t)runAsinCase(&asinCases[i]);
  }

  for(size_t i = 0; i < sizeof(acosCases) / sizeof(acosCases[0]); ++i) {
    failures += (size_t)runAcosCase(&acosCases[i]);
  }

  for(size_t i = 0; i < sizeof(sinhCoshCases) / sizeof(sinhCoshCases[0]); ++i) {
    failures += (size_t)runSinhCoshCase(&sinhCoshCases[i]);
  }

  for(size_t i = 0; i < sizeof(tanhCases) / sizeof(tanhCases[0]); ++i) {
    failures += (size_t)runTanhCase(&tanhCases[i]);
  }

  for(size_t i = 0; i < sizeof(arcSinhCases) / sizeof(arcSinhCases[0]); ++i) {
    failures += (size_t)runArcSinhCase(&arcSinhCases[i]);
  }

  for(size_t i = 0; i < sizeof(arcTanhCases) / sizeof(arcTanhCases[0]); ++i) {
    failures += (size_t)runArcTanhCase(&arcTanhCases[i]);
  }

  if(failures != 0) {
    printf("real trig primitive oracle failed %zu case(s)\n", failures);
    return 1;
  }

  printf("real trig primitive oracle passed %zu case(s)\n", totalCases);
  return 0;
}
