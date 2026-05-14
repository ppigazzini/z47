// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

gboolean z47_btnPressed_signal(GtkWidget *widget, GdkEvent *event, gpointer data) {
	btnPressed(widget, event, data);
	return FALSE;
}

gboolean z47_btnReleased_signal(GtkWidget *widget, GdkEvent *event, gpointer data) {
	btnReleased(widget, event, data);
	return FALSE;
}