// SPDX-License-Identifier: GPL-3.0-only

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>

#include "c47.h"

void fnMaskl(uint16_t numberOfBits);
void fnMaskr(uint16_t numberOfBits);
void fnCountBits(uint16_t unusedButMandatoryParameter);
void fnCb(uint16_t bit);
void fnSb(uint16_t bit);
void fnFb(uint16_t bit);
void fnBc(uint16_t bit);
void fnBs(uint16_t bit);

void oracle_fnMaskl(uint16_t numberOfBits);
void oracle_fnMaskr(uint16_t numberOfBits);
void oracle_fnCountBits(uint16_t unusedButMandatoryParameter);
void oracle_fnCb(uint16_t bit);
void oracle_fnSb(uint16_t bit);
void oracle_fnFb(uint16_t bit);
void oracle_fnBc(uint16_t bit);
void oracle_fnBs(uint16_t bit);

typedef void (*logical_shortint_fn)(uint16_t);

static bool stateEquals(const parity_runtime_state_t *left, const parity_runtime_state_t *right,
                        uint8_t left_ti, uint8_t right_ti,
                        bool_t left_undo, bool_t right_undo) {
  return left->x_raw == right->x_raw &&
         left->x_base == right->x_base &&
         left->x_data_type == right->x_data_type &&
         left->l_raw == right->l_raw &&
         left->l_base == right->l_base &&
         left->l_data_type == right->l_data_type &&
         left->saved_last_x == right->saved_last_x &&
         left->lifted_stack == right->lifted_stack &&
         left->last_error_code == right->last_error_code &&
         left->last_error_message_register == right->last_error_message_register &&
         left->last_error_register == right->last_error_register &&
         left_ti == right_ti &&
         left_undo == right_undo;
}

static void failCase(const char *name, unsigned int arg,
                     const parity_runtime_state_t *expected, uint8_t expected_ti, bool_t expected_undo,
                     const parity_runtime_state_t *actual, uint8_t actual_ti, bool_t actual_undo) {
  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: x=%#018llx base=%u l=%#018llx lbase=%u saved=%d lifted=%d err=%u/%d/%d ti=%u undo=%d\n"
          "  actual:   x=%#018llx base=%u l=%#018llx lbase=%u saved=%d lifted=%d err=%u/%d/%d ti=%u undo=%d\n",
          name,
          arg,
          (unsigned long long)expected->x_raw,
          expected->x_base,
          (unsigned long long)expected->l_raw,
          expected->l_base,
          expected->saved_last_x,
          expected->lifted_stack,
          expected->last_error_code,
          expected->last_error_message_register,
          expected->last_error_register,
          expected_ti,
          expected_undo,
          (unsigned long long)actual->x_raw,
          actual->x_base,
          (unsigned long long)actual->l_raw,
          actual->l_base,
          actual->saved_last_x,
          actual->lifted_stack,
          actual->last_error_code,
          actual->last_error_message_register,
          actual->last_error_register,
          actual_ti,
          actual_undo);
}

static int runCase(const char *name, logical_shortint_fn oracle, logical_shortint_fn zig_fn,
                   uint8_t word_size, uint64_t x_raw, uint32_t x_base, uint16_t arg,
                   bool_t get_shortint_ok, bool_t save_last_x_ok) {
  parity_runtime_state_t expected_state;
  parity_runtime_state_t actual_state;
  uint8_t expected_ti;
  uint8_t actual_ti;
  bool_t expected_undo;
  bool_t actual_undo;

  parityResetState(word_size, x_raw, x_base);
  paritySetGetShortIntOk(get_shortint_ok);
  paritySetSaveLastXOk(save_last_x_ok);
  oracle(arg);
  expected_state = parityRuntimeState;
  expected_ti = temporaryInformation;
  expected_undo = thereIsSomethingToUndo;

  parityResetState(word_size, x_raw, x_base);
  paritySetGetShortIntOk(get_shortint_ok);
  paritySetSaveLastXOk(save_last_x_ok);
  zig_fn(arg);
  actual_state = parityRuntimeState;
  actual_ti = temporaryInformation;
  actual_undo = thereIsSomethingToUndo;

  if(!stateEquals(&expected_state, &actual_state, expected_ti, actual_ti, expected_undo, actual_undo)) {
    failCase(name, arg, &expected_state, expected_ti, expected_undo, &actual_state, actual_ti, actual_undo);
    return 1;
  }

  return 0;
}

static int runGoldenCase(const char *name, logical_shortint_fn zig_fn,
                         uint8_t word_size, uint64_t x_raw, uint32_t x_base, uint16_t arg,
                         uint64_t expected_x_raw, uint32_t expected_x_base,
                         bool_t expected_lifted_stack) {
  parity_runtime_state_t actual_state;

  parityResetState(word_size, x_raw, x_base);
  zig_fn(arg);
  actual_state = parityRuntimeState;

  if(actual_state.x_raw != expected_x_raw ||
     actual_state.x_base != expected_x_base ||
     actual_state.x_data_type != dtShortInteger ||
     actual_state.saved_last_x ||
     actual_state.lifted_stack != expected_lifted_stack ||
     actual_state.last_error_code != 0 ||
     actual_state.last_error_message_register != 0 ||
     actual_state.last_error_register != 0 ||
     temporaryInformation != 0 ||
     thereIsSomethingToUndo != true) {
    fprintf(stderr,
            "%s(%u) golden mismatch\n"
            "  expected: x=%#018llx base=%u lifted=%d\n"
            "  actual:   x=%#018llx base=%u lifted=%d err=%u/%d/%d ti=%u undo=%d\n",
            name,
            arg,
            (unsigned long long)expected_x_raw,
            expected_x_base,
            expected_lifted_stack,
            (unsigned long long)actual_state.x_raw,
            actual_state.x_base,
            actual_state.lifted_stack,
            actual_state.last_error_code,
            actual_state.last_error_message_register,
            actual_state.last_error_register,
            temporaryInformation,
            thereIsSomethingToUndo);
    return 1;
  }

  return 0;
}

int main(void) {
  int failures = 0;

  failures += runCase("fnMaskl", oracle_fnMaskl, fnMaskl, 8, 0x12u, 16, 0, true, true);
  failures += runCase("fnMaskl", oracle_fnMaskl, fnMaskl, 8, 0x12u, 16, 5, true, true);
  failures += runCase("fnMaskl", oracle_fnMaskl, fnMaskl, 8, 0x12u, 16, 9, true, true);
  failures += runGoldenCase("fnMaskl", fnMaskl, 64, 0x12u, 16, 64, UINT64_MAX, 2, true);

  failures += runCase("fnMaskr", oracle_fnMaskr, fnMaskr, 8, 0x12u, 16, 0, true, true);
  failures += runCase("fnMaskr", oracle_fnMaskr, fnMaskr, 8, 0x12u, 16, 5, true, true);
  failures += runCase("fnMaskr", oracle_fnMaskr, fnMaskr, 8, 0x12u, 16, 9, true, true);
  failures += runGoldenCase("fnMaskr", fnMaskr, 64, 0x12u, 16, 64, UINT64_MAX, 2, true);

  failures += runCase("fnCountBits", oracle_fnCountBits, fnCountBits, 64, 0, 2, 0, true, true);
  failures += runCase("fnCountBits", oracle_fnCountBits, fnCountBits, 64, 0xffffffffffffffffULL, 2, 0, true, true);
  failures += runCase("fnCountBits", oracle_fnCountBits, fnCountBits, 16, 0x0f0f, 16, 0, true, true);
  failures += runCase("fnCountBits", oracle_fnCountBits, fnCountBits, 16, 0x0f0f, 16, 0, false, true);
  failures += runCase("fnCountBits", oracle_fnCountBits, fnCountBits, 16, 0x0f0f, 16, 0, true, false);

  failures += runCase("fnCb", oracle_fnCb, fnCb, 16, 0xffff, 16, 0, true, true);
  failures += runCase("fnCb", oracle_fnCb, fnCb, 16, 0xffff, 16, 15, true, true);
  failures += runCase("fnCb", oracle_fnCb, fnCb, 16, 0xffff, 16, 17, true, true);

  failures += runCase("fnSb", oracle_fnSb, fnSb, 16, 0, 16, 0, true, true);
  failures += runCase("fnSb", oracle_fnSb, fnSb, 16, 0, 16, 15, true, true);
  failures += runCase("fnSb", oracle_fnSb, fnSb, 16, 0, 16, 17, true, true);

  failures += runCase("fnFb", oracle_fnFb, fnFb, 16, 0xaaaa, 16, 1, true, true);
  failures += runCase("fnFb", oracle_fnFb, fnFb, 16, 0xaaaa, 16, 15, true, true);
  failures += runCase("fnFb", oracle_fnFb, fnFb, 16, 0xaaaa, 16, 17, true, true);

  failures += runCase("fnBc", oracle_fnBc, fnBc, 16, 0, 16, 5, true, true);
  failures += runCase("fnBc", oracle_fnBc, fnBc, 16, 0x20, 16, 5, true, true);
  failures += runCase("fnBc", oracle_fnBc, fnBc, 16, 0x20, 16, 17, true, true);

  failures += runCase("fnBs", oracle_fnBs, fnBs, 16, 0, 16, 5, true, true);
  failures += runCase("fnBs", oracle_fnBs, fnBs, 16, 0x20, 16, 5, true, true);
  failures += runCase("fnBs", oracle_fnBs, fnBs, 16, 0x20, 16, 17, true, true);

  if(failures != 0) {
    fprintf(stderr, "%d logical short-integer parity checks failed\n", failures);
    return 1;
  }

  puts("logical short-integer parity checks passed");
  return 0;
}