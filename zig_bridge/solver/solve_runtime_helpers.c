// SPDX-License-Identifier: GPL-3.0-only

#include <stdio.h>

#include "c47.h"

bool_t z47_solver_is_label(uint16_t label) {
  return FIRST_LABEL <= label && label <= LAST_LABEL;
}

bool_t z47_solver_is_stack_register(uint16_t label) {
  return REGISTER_X <= label && label <= REGISTER_T;
}

bool_t z47_solver_is_invalid_variable(uint16_t variable) {
  return variable == INVALID_VARIABLE;
}

uint16_t z47_solver_label_to_program(uint16_t label) {
  return label - FIRST_LABEL;
}

void z47_solver_report_label_not_found(const char *buf) {
  displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  sprintf(errorMessage, "string '%s' is not a named label", buf);
  moreInfoOnError("In function fnPgmSlv:", errorMessage, NULL, NULL);
#endif
}

void z47_solver_report_out_of_range(uint16_t label) {
  displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
#if (EXTRA_INFO_ON_CALC_ERROR == 1)
  sprintf(errorMessage, "unexpected parameter %u", label);
  moreInfoOnError("In function fnPgmSlv:", errorMessage, NULL, NULL);
#endif
}