// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "math_wrappers_test_runtime.h"

void pcg32_srandom_r(pcg32_random_t *rng, uint64_t initstate, uint64_t initseq);
uint32_t pcg32_random_r(pcg32_random_t *rng);
void realRandomU01(real_t *res);
void fnRandom(uint16_t unusedButMandatoryParameter);
void fnRandomI(uint16_t unusedButMandatoryParameter);
void fnSeed(uint16_t unusedButMandatoryParameter);

void oracle_pcg32_srandom_r(pcg32_random_t *rng, uint64_t initstate, uint64_t initseq);
uint32_t oracle_pcg32_random_r(pcg32_random_t *rng);
void oracle_realRandomU01(real_t *res);
void oracle_fnRandom(uint16_t unusedButMandatoryParameter);
void oracle_fnRandomI(uint16_t unusedButMandatoryParameter);
void oracle_fnSeed(uint16_t unusedButMandatoryParameter);

static void configureDefaultRandomSurface(void) {
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 7, 0);
  mathWrappersSetRealYInput(true, 2, 0);
  mathWrappersSetLongIntegerInput(true, -4);
  mathWrappersSetLongIntegerYInput(true, 9);
  mathWrappersSetSeedInput(UINT64_C(0x0102030405060708), UINT64_C(0x1112131415161718));
  mathWrappersSetPcgState(UINT64_C(0x853c49e6748fea9b), UINT64_C(0xda3e39cb94b95bdb));
  mathWrappersSetUptimeMs(0x12345678u);
  mathWrappersSetFreeRamMemory(0x11223344u);
  mathWrappersSetFreeFlash(0x55667788u);
}

static int compareReal(const char *name, const real_t *expected, const real_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s real mismatch\n"
          "  expected: exp=%d bits=%u coeff_hi=%04x coeff_lo=%04x\n"
          "  actual:   exp=%d bits=%u coeff_hi=%04x coeff_lo=%04x\n",
          name,
          expected->exponent,
          expected->bits,
          expected->lsu[1],
          expected->lsu[0],
          actual->exponent,
          actual->bits,
          actual->lsu[1],
          actual->lsu[0]);
  return 1;
}

static int compareSnapshot(const char *name,
                           const math_wrappers_snapshot_t *expected,
                           const math_wrappers_snapshot_t *actual) {
  if(memcmp(expected, actual, sizeof(*expected)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "%s snapshot mismatch\n"
          "  expected: dtype=%u tag=%u drop=%u lift=%u saveUndo=%u randomI=%u pcg=%" PRIu64 "/%" PRIu64 " undo=%u\n"
          "  actual:   dtype=%u tag=%u drop=%u lift=%u saveUndo=%u randomI=%u pcg=%" PRIu64 "/%" PRIu64 " undo=%u\n",
          name,
          expected->final_register_data_type,
          expected->final_register_tag,
          expected->fn_drop_calls,
          expected->lift_stack_calls,
          expected->save_for_undo_calls,
          expected->process_int_real_complex_dyadic_calls,
          expected->final_pcg_state,
          expected->final_pcg_inc,
          expected->final_there_is_something_to_undo,
          actual->final_register_data_type,
          actual->final_register_tag,
          actual->fn_drop_calls,
          actual->lift_stack_calls,
          actual->save_for_undo_calls,
          actual->process_int_real_complex_dyadic_calls,
          actual->final_pcg_state,
          actual->final_pcg_inc,
          actual->final_there_is_something_to_undo);
  return 1;
}

static int runDirectPcgRandomCase(void) {
  pcg32_random_t expected_rng = { UINT64_C(0x0123456789abcdef), UINT64_C(0x0fedcba987654321) | 1 };
  pcg32_random_t actual_rng = expected_rng;
  const uint32_t expected = oracle_pcg32_random_r(&expected_rng);
  const uint32_t actual = pcg32_random_r(&actual_rng);

  if(expected == actual && memcmp(&expected_rng, &actual_rng, sizeof(expected_rng)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "pcg32_random_r mismatch\n"
          "  expected: result=%" PRIu32 " state=%" PRIu64 "/%" PRIu64 "\n"
          "  actual:   result=%" PRIu32 " state=%" PRIu64 "/%" PRIu64 "\n",
          expected,
          expected_rng.state,
          expected_rng.inc,
          actual,
          actual_rng.state,
          actual_rng.inc);
  return 1;
}

static int runDirectPcgSeedCase(void) {
  pcg32_random_t expected_rng = { 0, 0 };
  pcg32_random_t actual_rng = { 0, 0 };

  oracle_pcg32_srandom_r(&expected_rng, UINT64_C(0x1234567890abcdef), UINT64_C(0x0102030405060708));
  pcg32_srandom_r(&actual_rng, UINT64_C(0x1234567890abcdef), UINT64_C(0x0102030405060708));

  if(memcmp(&expected_rng, &actual_rng, sizeof(expected_rng)) == 0) {
    return 0;
  }

  fprintf(stderr,
          "pcg32_srandom_r mismatch\n"
          "  expected: %" PRIu64 "/%" PRIu64 "\n"
          "  actual:   %" PRIu64 "/%" PRIu64 "\n",
          expected_rng.state,
          expected_rng.inc,
          actual_rng.state,
          actual_rng.inc);
  return 1;
}

static int runDirectRandomCase(void) {
  real_t expected;
  real_t actual;

  mathWrappersReset();
  configureDefaultRandomSurface();
  oracle_realRandomU01(&expected);
  const uint64_t expected_state = pcg32_global.state;
  const uint64_t expected_inc = pcg32_global.inc;

  mathWrappersReset();
  configureDefaultRandomSurface();
  realRandomU01(&actual);

  if(compareReal("realRandomU01", &expected, &actual) != 0) {
    return 1;
  }
  if(expected_state != pcg32_global.state || expected_inc != pcg32_global.inc) {
    fprintf(stderr,
            "realRandomU01 pcg state mismatch\n"
            "  expected: %" PRIu64 "/%" PRIu64 "\n"
            "  actual:   %" PRIu64 "/%" PRIu64 "\n",
            expected_state,
            expected_inc,
            pcg32_global.state,
            pcg32_global.inc);
    return 1;
  }

  return 0;
}

static int runCommandCase(const char *name,
                          void (*oracle_fn)(uint16_t),
                          void (*zig_fn)(uint16_t),
                          void (*configure)(void)) {
  math_wrappers_snapshot_t expected;
  math_wrappers_snapshot_t actual;

  mathWrappersReset();
  if(configure != NULL) {
    configure();
  }
  oracle_fn(0);
  mathWrappersCapture(&expected);

  mathWrappersReset();
  if(configure != NULL) {
    configure();
  }
  zig_fn(0);
  mathWrappersCapture(&actual);

  return compareSnapshot(name, &expected, &actual);
}

static void configureFnRandom(void) {
  configureDefaultRandomSurface();
}

static void configureFnSeedExplicit(void) {
  configureDefaultRandomSurface();
  mathWrappersSetSeedInput(UINT64_C(0x1122334455667788), UINT64_C(0x8877665544332211));
}

static void configureFnSeedDefault(void) {
  configureDefaultRandomSurface();
  mathWrappersSetSeedInput(0, 0);
}

static void configureFnRandomIReal(void) {
  configureDefaultRandomSurface();
  mathWrappersSetRegisterSurface(dtReal34, amNone);
  mathWrappersSetRealInput(true, 8, 0);
  mathWrappersSetRealYInput(true, 3, 0);
}

static void configureFnRandomILongInt(void) {
  configureDefaultRandomSurface();
  mathWrappersSetRegisterSurface(dtLongInteger, amNone);
  mathWrappersSetLongIntegerInput(true, -3);
  mathWrappersSetLongIntegerYInput(true, 5);
}

int main(void) {
  int failures = 0;

  failures += runDirectPcgRandomCase();
  failures += runDirectPcgSeedCase();
  failures += runDirectRandomCase();
  failures += runCommandCase("fnRandom", oracle_fnRandom, fnRandom, &configureFnRandom);
  failures += runCommandCase("fnSeed explicit", oracle_fnSeed, fnSeed, &configureFnSeedExplicit);
  failures += runCommandCase("fnSeed default", oracle_fnSeed, fnSeed, &configureFnSeedDefault);
  failures += runCommandCase("fnRandomI real", oracle_fnRandomI, fnRandomI, &configureFnRandomIReal);
  failures += runCommandCase("fnRandomI longint", oracle_fnRandomI, fnRandomI, &configureFnRandomILongInt);

  if(failures != 0) {
    fprintf(stderr, "math random parity failed: %d case(s)\n", failures);
    return 1;
  }

  return 0;
}