// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_solver_tvm_begin_mode(void) {
  clearSystemFlag(FLAG_ENDPMT);
}

void z47_solver_tvm_end_mode(void) {
  setSystemFlag(FLAG_ENDPMT);
}
