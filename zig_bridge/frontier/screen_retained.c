// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#define fnSNAP z47_frontier_retained_fnSNAP
#include "../../src/c47/screen.c"

void z47_frontier_snap_screenshot_with_message_backup(void) {
#if defined(PC_BUILD)
	xcopy(tmpString, errorMessage, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);
	fnScreenDump(0);
	xcopy(errorMessage, tmpString, ERROR_MESSAGE_LENGTH + AIM_BUFFER_LENGTH + NIM_BUFFER_LENGTH + TAM_BUFFER_LENGTH);
#elif defined(DMCP_BUILD)
	standardScreenDump();
#endif
}

void z47_frontier_snap_backup_tam(uint8_t *dst) {
	xcopy(dst, tamBuffer, TAM_BUFFER_LENGTH);
}

void z47_frontier_snap_restore_tam(const uint8_t *src) {
	xcopy(tamBuffer, src, TAM_BUFFER_LENGTH);
}