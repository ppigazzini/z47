// SPDX-License-Identifier: GPL-3.0-only

#include <string.h>

#include "math_wrappers_test_runtime.h"

static math_wrappers_snapshot_t snapshot;
static bool_t save_last_x_result = true;

void mathWrappersReset(void) {
  memset(&snapshot, 0, sizeof(snapshot));
  save_last_x_result = true;
  snapshot.save_last_x_result = true;
  snapshot.integer_part_real_mode = -1;
  snapshot.integer_part_cplx_mode = -1;
  snapshot.sinh_cosh_real_trig_type = -1;
  snapshot.sinh_cosh_cplx_trig_type = -1;
}

void mathWrappersSetSaveLastXResult(bool_t result) {
  save_last_x_result = result;
  snapshot.save_last_x_result = result;
}

void mathWrappersCapture(math_wrappers_snapshot_t *out) {
  *out = snapshot;
}

bool_t saveLastX(void) {
  snapshot.save_last_x_calls++;
  return save_last_x_result;
}

void registerMin(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest) {
  snapshot.register_min_calls++;
  snapshot.register_min_reg1 = regist1;
  snapshot.register_min_reg2 = regist2;
  snapshot.register_min_dest = dest;
}

void registerMax(calcRegister_t regist1, calcRegister_t regist2, calcRegister_t dest) {
  snapshot.register_max_calls++;
  snapshot.register_max_reg1 = regist1;
  snapshot.register_max_reg2 = regist2;
  snapshot.register_max_dest = dest;
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

void processRealComplexMonadicFunction(void (*realf)(void), void (*complexf)(void)) {
  snapshot.process_real_complex_monadic_calls++;
  if(realf != NULL) {
    realf();
  }
  if(complexf != NULL) {
    complexf();
  }
}

void processIntRealComplexMonadicFunction(void (*realf)(void),
                                         void (*complexf)(void),
                                         void (*shortintf)(void),
                                         void (*longintf)(void)) {
  snapshot.process_int_real_complex_monadic_calls++;
  if(realf != NULL) {
    realf();
  }
  if(complexf != NULL) {
    complexf();
  }
  if(shortintf != NULL) {
    shortintf();
  }
  if(longintf != NULL) {
    longintf();
  }
}

void integerPartNoOp(void) {
  snapshot.integer_part_noop_calls++;
}

void integerPartReal(enum rounding mode) {
  snapshot.integer_part_real_calls++;
  snapshot.integer_part_real_mode = mode;
}

void integerPartCplx(enum rounding mode) {
  snapshot.integer_part_cplx_calls++;
  snapshot.integer_part_cplx_mode = mode;
}

void sinhCoshReal(trigType_t trigType) {
  snapshot.sinh_cosh_real_calls++;
  snapshot.sinh_cosh_real_trig_type = trigType;
}

void sinhCoshCplx(trigType_t trigType) {
  snapshot.sinh_cosh_cplx_calls++;
  snapshot.sinh_cosh_cplx_trig_type = trigType;
}