// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>
#include <string.h>

#include "c47.h"

void fnAsr(uint16_t numberOfShifts);
void fnSl(uint16_t numberOfShifts);
void fnSr(uint16_t numberOfShifts);
void fnRl(uint16_t numberOfShifts);
void fnRr(uint16_t numberOfShifts);
void fnRlc(uint16_t numberOfShifts);
void fnRrc(uint16_t numberOfShifts);
void fnLj(uint16_t unusedButMandatoryParameter);
void fnRj(uint16_t unusedButMandatoryParameter);
void fnMirror(uint16_t unusedButMandatoryParameter);
void fnSwapEndian(uint16_t bitWidth);
void fnZip(uint16_t unusedButMandatoryParameter);
void fnUnzip(uint16_t unusedButMandatoryParameter);

void oracle_fnAsr(uint16_t numberOfShifts);
void oracle_fnSl(uint16_t numberOfShifts);
void oracle_fnSr(uint16_t numberOfShifts);
void oracle_fnRl(uint16_t numberOfShifts);
void oracle_fnRr(uint16_t numberOfShifts);
void oracle_fnRlc(uint16_t numberOfShifts);
void oracle_fnRrc(uint16_t numberOfShifts);
void oracle_fnLj(uint16_t unusedButMandatoryParameter);
void oracle_fnRj(uint16_t unusedButMandatoryParameter);
void oracle_fnMirror(uint16_t unusedButMandatoryParameter);
void oracle_fnSwapEndian(uint16_t bitWidth);
void oracle_fnZip(uint16_t unusedButMandatoryParameter);
void oracle_fnUnzip(uint16_t unusedButMandatoryParameter);

typedef void (*rotate_bits_fn)(uint16_t);

static int snapshotsEqual(const rotate_bits_snapshot_t *left, const rotate_bits_snapshot_t *right) {
  return left->word_size == right->word_size &&
         left->mask == right->mask &&
         left->sign_bit == right->sign_bit &&
         left->temporary_information == right->temporary_information &&
         left->undo_flag == right->undo_flag &&
         left->runtime_state.x_raw == right->runtime_state.x_raw &&
         left->runtime_state.x_base == right->runtime_state.x_base &&
         left->runtime_state.x_data_type == right->runtime_state.x_data_type &&
         left->runtime_state.y_raw == right->runtime_state.y_raw &&
         left->runtime_state.y_base == right->runtime_state.y_base &&
         left->runtime_state.y_data_type == right->runtime_state.y_data_type &&
         left->runtime_state.z_raw == right->runtime_state.z_raw &&
         left->runtime_state.z_base == right->runtime_state.z_base &&
         left->runtime_state.z_data_type == right->runtime_state.z_data_type &&
         left->runtime_state.l_raw == right->runtime_state.l_raw &&
         left->runtime_state.l_base == right->runtime_state.l_base &&
         left->runtime_state.l_data_type == right->runtime_state.l_data_type &&
         left->runtime_state.get_shortint_ok == right->runtime_state.get_shortint_ok &&
         left->runtime_state.save_last_x_ok == right->runtime_state.save_last_x_ok &&
         left->runtime_state.saved_last_x == right->runtime_state.saved_last_x &&
         left->runtime_state.lifted_stack == right->runtime_state.lifted_stack &&
         left->runtime_state.carry_flag == right->runtime_state.carry_flag &&
         left->runtime_state.aslift_flag == right->runtime_state.aslift_flag &&
         left->runtime_state.last_error_code == right->runtime_state.last_error_code &&
         left->runtime_state.last_error_message_register == right->runtime_state.last_error_message_register &&
         left->runtime_state.last_error_register == right->runtime_state.last_error_register &&
         left->runtime_state.adjust_result_calls == right->runtime_state.adjust_result_calls;
}

static int reportMismatch(const char *name,
                          uint16_t arg,
                          const rotate_bits_snapshot_t *expected,
                          const rotate_bits_snapshot_t *actual) {
  if(snapshotsEqual(expected, actual)) {
    return 0;
  }

  fprintf(stderr,
          "%s(%u) parity mismatch\n"
          "  expected: ws=%u mask=%#018llx sign=%#018llx x=%#018llx/%u/%u y=%#018llx/%u/%u z=%#018llx/%u/%u l=%#018llx/%u/%u carry=%d aslift=%d saved=%d lifted=%d adjust=%u err=%u/%d/%d ti=%u undo=%d\n"
          "  actual:   ws=%u mask=%#018llx sign=%#018llx x=%#018llx/%u/%u y=%#018llx/%u/%u z=%#018llx/%u/%u l=%#018llx/%u/%u carry=%d aslift=%d saved=%d lifted=%d adjust=%u err=%u/%d/%d ti=%u undo=%d\n",
          name,
          arg,
          expected->word_size,
          (unsigned long long)expected->mask,
          (unsigned long long)expected->sign_bit,
          (unsigned long long)expected->runtime_state.x_raw,
          expected->runtime_state.x_base,
          expected->runtime_state.x_data_type,
          (unsigned long long)expected->runtime_state.y_raw,
          expected->runtime_state.y_base,
          expected->runtime_state.y_data_type,
          (unsigned long long)expected->runtime_state.z_raw,
          expected->runtime_state.z_base,
          expected->runtime_state.z_data_type,
          (unsigned long long)expected->runtime_state.l_raw,
          expected->runtime_state.l_base,
          expected->runtime_state.l_data_type,
          expected->runtime_state.carry_flag,
          expected->runtime_state.aslift_flag,
          expected->runtime_state.saved_last_x,
          expected->runtime_state.lifted_stack,
          expected->runtime_state.adjust_result_calls,
          expected->runtime_state.last_error_code,
          expected->runtime_state.last_error_message_register,
          expected->runtime_state.last_error_register,
          expected->temporary_information,
          expected->undo_flag,
          actual->word_size,
          (unsigned long long)actual->mask,
          (unsigned long long)actual->sign_bit,
          (unsigned long long)actual->runtime_state.x_raw,
          actual->runtime_state.x_base,
          actual->runtime_state.x_data_type,
          (unsigned long long)actual->runtime_state.y_raw,
          actual->runtime_state.y_base,
          actual->runtime_state.y_data_type,
          (unsigned long long)actual->runtime_state.z_raw,
          actual->runtime_state.z_base,
          actual->runtime_state.z_data_type,
          (unsigned long long)actual->runtime_state.l_raw,
          actual->runtime_state.l_base,
          actual->runtime_state.l_data_type,
          actual->runtime_state.carry_flag,
          actual->runtime_state.aslift_flag,
          actual->runtime_state.saved_last_x,
          actual->runtime_state.lifted_stack,
          actual->runtime_state.adjust_result_calls,
          actual->runtime_state.last_error_code,
          actual->runtime_state.last_error_message_register,
          actual->runtime_state.last_error_register,
          actual->temporary_information,
          actual->undo_flag);
  return 1;
}

static int runCase(const char *name,
                   rotate_bits_fn oracle_fn,
                   rotate_bits_fn zig_fn,
                   uint8_t word_size,
                   uint64_t x_raw,
                   uint32_t x_base,
                   uint64_t y_raw,
                   uint32_t y_base,
                   uint64_t z_raw,
                   uint32_t z_base,
                   bool_t carry_flag,
                   uint16_t arg) {
  rotate_bits_snapshot_t expected;
  rotate_bits_snapshot_t actual;

  rotateBitsResetState(word_size, x_raw, x_base, y_raw, y_base, z_raw, z_base, carry_flag);
  oracle_fn(arg);
  rotateBitsCapture(&expected);

  rotateBitsResetState(word_size, x_raw, x_base, y_raw, y_base, z_raw, z_base, carry_flag);
  zig_fn(arg);
  rotateBitsCapture(&actual);

  return reportMismatch(name, arg, &expected, &actual);
}

static int runSaveLastXFailureCase(void) {
  rotate_bits_snapshot_t expected;
  rotate_bits_snapshot_t actual;

  rotateBitsResetState(16, 0x1ce7u, 2, 0, 2, 0, 2, false);
  parityRuntimeState.save_last_x_ok = false;
  oracle_fnAsr(1);
  rotateBitsCapture(&expected);

  rotateBitsResetState(16, 0x1ce7u, 2, 0, 2, 0, 2, false);
  parityRuntimeState.save_last_x_ok = false;
  fnAsr(1);
  rotateBitsCapture(&actual);

  return reportMismatch("fnAsr", 1, &expected, &actual);
}

static int runZipInvalidYCase(void) {
  rotate_bits_snapshot_t expected;
  rotate_bits_snapshot_t actual;

  rotateBitsResetState(16, 0x1ce7u, 2, 0x9c2cu, 2, 0, 2, false);
  parityRuntimeState.y_data_type = dtLongInteger;
  oracle_fnZip(0);
  rotateBitsCapture(&expected);

  rotateBitsResetState(16, 0x1ce7u, 2, 0x9c2cu, 2, 0, 2, false);
  parityRuntimeState.y_data_type = dtLongInteger;
  fnZip(0);
  rotateBitsCapture(&actual);

  return reportMismatch("fnZip", 0, &expected, &actual);
}

int main(void) {
  int failures = 0;

  failures += runCase("fnAsr", oracle_fnAsr, fnAsr, 16, 0x1ce7u, 2, 0, 2, 0, 2, false, 1);
  failures += runCase("fnAsr", oracle_fnAsr, fnAsr, 16, 0x9ce6u, 2, 0, 2, 0, 2, true, 1);
  failures += runCase("fnAsr", oracle_fnAsr, fnAsr, 10, 0x25au, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnSl", oracle_fnSl, fnSl, 16, 0x1ce7u, 2, 0, 2, 0, 2, true, 1);
  failures += runCase("fnSl", oracle_fnSl, fnSl, 64, 0x8120000000010001ULL, 16, 0, 16, 0, 16, false, 8);
  failures += runCase("fnSl", oracle_fnSl, fnSl, 10, 0x155u, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnSr", oracle_fnSr, fnSr, 16, 0x9ce6u, 2, 0, 2, 0, 2, true, 1);
  failures += runCase("fnSr", oracle_fnSr, fnSr, 64, 0x8120000000010181ULL, 16, 0, 16, 0, 16, false, 8);
  failures += runCase("fnSr", oracle_fnSr, fnSr, 10, 0x157u, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnRl", oracle_fnRl, fnRl, 16, 0x9ce7u, 2, 0, 2, 0, 2, false, 1);
  failures += runCase("fnRl", oracle_fnRl, fnRl, 64, 0x8000000000000000ULL, 16, 0, 16, 0, 16, false, 1);
  failures += runCase("fnRl", oracle_fnRl, fnRl, 10, 0x155u, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnRr", oracle_fnRr, fnRr, 16, 0x1ce7u, 2, 0, 2, 0, 2, false, 1);
  failures += runCase("fnRr", oracle_fnRr, fnRr, 64, 0x8120000000010181ULL, 16, 0, 16, 0, 16, false, 8);
  failures += runCase("fnRr", oracle_fnRr, fnRr, 10, 0x157u, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnRlc", oracle_fnRlc, fnRlc, 16, 0x1ce7u, 2, 0, 2, 0, 2, true, 1);
  failures += runCase("fnRlc", oracle_fnRlc, fnRlc, 64, 0x8120000000010001ULL, 16, 0, 16, 0, 16, false, 8);
  failures += runCase("fnRlc", oracle_fnRlc, fnRlc, 10, 0x155u, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnRrc", oracle_fnRrc, fnRrc, 16, 0x9ce6u, 2, 0, 2, 0, 2, true, 1);
  failures += runCase("fnRrc", oracle_fnRrc, fnRrc, 64, 0x8000000000010001ULL, 16, 0, 16, 0, 16, true, 8);
  failures += runCase("fnRrc", oracle_fnRrc, fnRrc, 10, 0x157u, 16, 0, 16, 0, 16, false, 2);

  failures += runCase("fnLj", oracle_fnLj, fnLj, 5, 0x01u, 2, 0x123u, 10, 0x456u, 10, false, 0);
  failures += runCase("fnLj", oracle_fnLj, fnLj, 5, 0x10u, 2, 0x123u, 10, 0x456u, 10, false, 0);
  failures += runCase("fnLj", oracle_fnLj, fnLj, 64, 0x01u, 16, 0x123u, 10, 0x456u, 10, false, 0);

  failures += runCase("fnRj", oracle_fnRj, fnRj, 5, 0x01u, 2, 0x123u, 10, 0x456u, 10, false, 0);
  failures += runCase("fnRj", oracle_fnRj, fnRj, 5, 0x04u, 2, 0x123u, 10, 0x456u, 10, false, 0);
  failures += runCase("fnRj", oracle_fnRj, fnRj, 64, 0x00u, 2, 0x123u, 10, 0x456u, 10, false, 0);

  failures += runCase("fnMirror", oracle_fnMirror, fnMirror, 8, 0x0fu, 2, 0, 2, 0, 2, false, 0);
  failures += runCase("fnMirror", oracle_fnMirror, fnMirror, 16, 0x1ce7u, 2, 0, 2, 0, 2, false, 0);

  failures += runCase("fnSwapEndian", oracle_fnSwapEndian, fnSwapEndian, 16, 0x1234u, 16, 0, 16, 0, 16, false, 8);
  failures += runCase("fnSwapEndian", oracle_fnSwapEndian, fnSwapEndian, 13, 0x1234u, 16, 0, 16, 0, 16, false, 8);
  failures += runCase("fnSwapEndian", oracle_fnSwapEndian, fnSwapEndian, 48, 0x001122334455ULL, 16, 0, 16, 0, 16, false, 16);

  failures += runCase("fnZip", oracle_fnZip, fnZip, 16, 0x1ce7u, 2, 0x9c2cu, 2, 0, 2, false, 0);
  failures += runCase("fnZip", oracle_fnZip, fnZip, 10, 0x15u, 2, 0x0au, 2, 0, 2, false, 0);
  failures += runCase("fnZip", oracle_fnZip, fnZip, 13, 0x55u, 2, 0x78u, 2, 0, 2, false, 0);

  failures += runCase("fnUnzip", oracle_fnUnzip, fnUnzip, 16, 0x5cb5u, 2, 0x1234u, 10, 0x5678u, 10, false, 0);
  failures += runCase("fnUnzip", oracle_fnUnzip, fnUnzip, 10, 0x199u, 2, 0x1234u, 10, 0x5678u, 10, false, 0);
  failures += runCase("fnUnzip", oracle_fnUnzip, fnUnzip, 13, 0x0b91u, 2, 0x1234u, 10, 0x5678u, 10, false, 0);

  failures += runSaveLastXFailureCase();
  failures += runZipInvalidYCase();

  if(failures != 0) {
    fprintf(stderr, "%d rotate-bits parity checks failed\n", failures);
    return 1;
  }

  puts("rotate-bits parity checks passed");
  return 0;
}