// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

void z47_flags_runtime_handle_write_protected_flag(void) {
  temporaryInformation = TI_NO_INFO;
  if(programRunStop == PGM_WAITING) {
    programRunStop = PGM_STOPPED;
  }
  displayCalcErrorMessage(ERROR_WRITE_PROTECTED_SYSTEM_FLAG, ERR_REGISTER_LINE, REGISTER_X);
}

void z47_flags_runtime_enter_alpha_mode(void) {
  if(calcMode != CM_EIM) {
    calcModeAim(NOPARAM);
  }
}

void z47_flags_runtime_leave_alpha_mode(void) {
  if(calcMode == CM_EIM) {
    if(softmenu[softmenuStack[0].softmenuId].menuItem == -MNU_EQ_EDIT) {
      calcModeNormal();
      if(allFormulae[currentFormula].pointerToFormulaData == C47_NULL) {
        deleteEquation(currentFormula);
      }
    }
    popSoftmenu();
  }
  else {
    calcModeNormal();
  }
}

void z47_flags_runtime_request_clf_all_confirmation(void) {
  setConfirmationMode(fnClFAll);
}