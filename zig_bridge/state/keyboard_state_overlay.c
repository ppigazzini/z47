// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

#include "keyboard_statusbar_mask.h"

#if defined(PC_BUILD)
extern void z47_keyboard_state_retained_btnPressed(GtkWidget *notUsed, GdkEvent *event, gpointer data);
extern void z47_keyboard_state_retained_btnClicked(GtkWidget *notUsed, gpointer data);

static void repairStopStatusbarMask(uint8_t previousProgramRunStop, uint8_t previousScreenUpdatingMode) {
	if((previousProgramRunStop == PGM_RUNNING || previousProgramRunStop == PGM_PAUSED) &&
	   programRunStop == PGM_WAITING &&
	   (lastKeyItemDetermined == ITM_RS || lastKeyItemDetermined == ITM_EXIT1) &&
	   !getSystemFlag(FLAG_INTING) &&
	   !getSystemFlag(FLAG_SOLVING)) {
		screenUpdatingMode = clearStatusbarUpdateFlags(previousScreenUpdatingMode);
	}
}

void btnPressed(GtkWidget *notUsed, GdkEvent *event, gpointer data) {
	const uint8_t previousProgramRunStop = programRunStop;
	const uint8_t previousScreenUpdatingMode = screenUpdatingMode;

	z47_keyboard_state_retained_btnPressed(notUsed, event, data);
	repairStopStatusbarMask(previousProgramRunStop, previousScreenUpdatingMode);
}

void btnClicked(GtkWidget *notUsed, gpointer data) {
	GdkEvent mouseButton = {0};

	mouseButton.button.button = 1;
	btnPressed(notUsed, &mouseButton, data);
	btnReleased(notUsed, &mouseButton, data);
}
#endif

#if defined(DMCP_BUILD)
extern void z47_keyboard_state_retained_btnPressed(void *data);
extern void z47_keyboard_state_retained_btnClicked(void *unused, void *data);

void btnPressed(void *data) {
	z47_keyboard_state_retained_btnPressed(data);
}

void btnClicked(void *unused, void *data) {
	(void)unused;
	btnPressed(data);
	btnReleased(data);
}
#endif