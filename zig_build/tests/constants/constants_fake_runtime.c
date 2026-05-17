// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "constants_test_runtime.h"

static constants_snapshot_t snapshot;
static bool_t constants_initialized = false;
static real_t constant_values[NOUC];
static real34_t register_x_real34;
static const real_t pi_value = {314};

uint16_t currentSolverStatus;
char errorMessage[256];
const real_t *realtConstants[NOUC];
const real_t *const39_pi = &pi_value;

static void ensureConstantsInitialized(void) {
  if(constants_initialized) {
    return;
  }

  for(uint16_t i = 0; i < NOUC; ++i) {
    constant_values[i].id = i;
    realtConstants[i] = &constant_values[i];
  }

  constants_initialized = true;
}

static calcRegister_t regFromReal34Ptr(real34_t *destination) {
  return destination == &register_x_real34 ? REGISTER_X : (calcRegister_t)-1;
}

real34_t *z47_constants_test_register_real34_data(calcRegister_t reg) {
  (void)reg;
  return &register_x_real34;
}

void constantsRuntimeReset(void) {
  ensureConstantsInitialized();
  memset(&snapshot, 0, sizeof(snapshot));
  memset(errorMessage, 0, sizeof(errorMessage));
  currentSolverStatus = 0xffffu;
  register_x_real34.id = 0xffffu;
  snapshot.real_to_real34_destination_reg = -1;
  snapshot.convert_real_to_result_dest = -1;
  snapshot.adjust_result_res = -1;
  snapshot.adjust_result_op1 = -1;
  snapshot.adjust_result_op2 = -1;
  snapshot.adjust_result_op3 = -1;
}

void constantsRuntimeCapture(constants_snapshot_t *out) {
  snapshot.current_solver_status = currentSolverStatus;
  snapshot.register_x_real34_id = register_x_real34.id;
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
  snapshot.real_to_real34_source_id = source->id;
  snapshot.real_to_real34_destination_reg = regFromReal34Ptr(destination);
  destination->id = source->id;
}

void convertRealToResultRegister(const real_t *source, calcRegister_t dest, angularMode_t angle) {
  snapshot.convert_real_to_result_register_calls++;
  snapshot.convert_real_to_result_source_id = source->id;
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

bool_t z47_constants_runtime_validate_constant(uint16_t constant) {
  if(constant >= NOUC) {
    sprintf(errorMessage, "parameter constant (%" PRIu16 ") is out of bounds, constant must be less or equal to %" PRId32, constant, NOUC - 1);
    moreInfoOnError("In function fnConstant:", errorMessage, NULL, NULL);
    return false;
  }

  return true;
}

void z47_constants_runtime_store_constant_in_x(uint16_t constant) {
  reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
  realToReal34(realtConstants[constant], REGISTER_REAL34_DATA(REGISTER_X));
}

void z47_constants_runtime_store_pi_in_x(void) {
  convertRealToResultRegister(const39_pi, REGISTER_X, amNone);
}