// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>

#include "c47.h"

void z47_solver_report_label_not_found_pgm_int(const char *buf) {
  displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  sprintf(errorMessage, "string '%s' is not a named label", buf);
  moreInfoOnError("In function fnPgmInt:", errorMessage, NULL, NULL);
#endif
}

void z47_solver_report_out_of_range_pgm_int(uint16_t label) {
  displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  sprintf(errorMessage, "unexpected parameter %u", label);
  moreInfoOnError("In function fnPgmInt:", errorMessage, NULL, NULL);
#endif
}

void z47_solver_clear_uses_formula_status(void) {
  currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
}
