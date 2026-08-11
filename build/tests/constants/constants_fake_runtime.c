// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "constants_test_runtime.h"

static constants_snapshot_t snapshot;
static real34_t register_x_real34;

uint16_t currentSolverStatus;
static char errorMessage__stg[512];
char *errorMessage = errorMessage__stg;

// Which constant a call reached, named the way c43's own blob names one: the
// byte offset of the real_t inside the generated `constants` array. Both sides
// of the lane resolve pi through the const39_pi macro and the constant table
// through realtConstants, so the offset is exactly the thing they must agree
// on. Reading an identity out of the decNumber itself would not do -- several
// constants share a leading digit count, so const39_pi and const39_2pi would be
// indistinguishable, which is the very confusion the lane exists to catch.
static uint16_t constantOffset(const real_t *source) {
  return (uint16_t)((const uint8_t *)source - constants);
}

static calcRegister_t regFromReal34Ptr(real34_t *destination) {
  return destination == &register_x_real34 ? REGISTER_X : (calcRegister_t)-1;
}

real34_t *z47_constants_test_register_real34_data(calcRegister_t reg) {
  (void)reg;
  return &register_x_real34;
}

void constantsRuntimeReset(void) {
  memset(&snapshot, 0, sizeof(snapshot));
  memset(errorMessage, 0, 512);
  currentSolverStatus = 0xffffu;
  register_x_real34.constant_offset = 0xffffu;
  snapshot.real_to_real34_destination_reg = -1;
  snapshot.convert_real_to_result_dest = -1;
  snapshot.adjust_result_res = -1;
  snapshot.adjust_result_op1 = -1;
  snapshot.adjust_result_op2 = -1;
  snapshot.adjust_result_op3 = -1;
}

void constantsRuntimeCapture(constants_snapshot_t *out) {
  snapshot.current_solver_status = currentSolverStatus;
  snapshot.register_x_constant_offset = register_x_real34.constant_offset;
  *out = snapshot;
}

void moreInfoOnError(const char *m1, const char *m2, const char *m3, const char *m4) {
  (void)m3;
  (void)m4;

  snapshot.more_info_calls++;
  snprintf(snapshot.more_info_line1, sizeof(snapshot.more_info_line1), "%s", m1 == NULL ? "" : m1);
  snprintf(snapshot.more_info_line2, sizeof(snapshot.more_info_line2), "%s", m2 == NULL ? "" : m2);
}

void liftStack(void) {
  snapshot.lift_stack_calls++;
}

void reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag) {
  snapshot.reallocate_register_calls++;
  snapshot.reallocate_register_reg = regist;
  snapshot.reallocate_register_data_type = dataType;
  snapshot.reallocate_register_data_size_without_data_len_blocks = dataSizeWithoutDataLenBlocks;
  snapshot.reallocate_register_tag = tag;
}

void realToReal34(const real_t *source, real34_t *destination) {
  snapshot.real_to_real34_calls++;
  snapshot.real_to_real34_source_offset = constantOffset(source);
  snapshot.real_to_real34_destination_reg = regFromReal34Ptr(destination);
  destination->constant_offset = constantOffset(source);
}

void convertRealToResultRegister(const real_t *source, calcRegister_t dest, angularMode_t angle) {
  snapshot.convert_real_to_result_register_calls++;
  snapshot.convert_real_to_result_source_offset = constantOffset(source);
  snapshot.convert_real_to_result_dest = dest;
  snapshot.convert_real_to_result_angle = angle;

  reallocateRegister(dest, dtReal34, 0, angle);
  realToReal34(source, REGISTER_REAL34_DATA(dest));
}

void adjustResult(calcRegister_t res,
                  bool_t dropY,
                  bool_t setCpxRes,
                  calcRegister_t op1,
                  calcRegister_t op2,
                  calcRegister_t op3) {
  snapshot.adjust_result_calls++;
  snapshot.adjust_result_res = res;
  snapshot.adjust_result_drop_y = dropY;
  snapshot.adjust_result_set_cpx_res = setCpxRes;
  snapshot.adjust_result_op1 = op1;
  snapshot.adjust_result_op2 = op2;
  snapshot.adjust_result_op3 = op3;
}

void setLastintegerBasetoZero(void) {
  snapshot.set_lastinteger_base_to_zero_calls++;
}
