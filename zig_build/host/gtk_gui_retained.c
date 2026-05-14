// SPDX-License-Identifier: GPL-3.0-only

#include "c47.h"

extern gboolean z47_btnPressed_signal(GtkWidget *widget, GdkEvent *event, gpointer data);
extern gboolean z47_btnReleased_signal(GtkWidget *widget, GdkEvent *event, gpointer data);

#define Z47_GTK_CALLBACK_ALIAS_btnFnPressed_wrapper btnFnPressed_wrapper
#define Z47_GTK_CALLBACK_ALIAS_btnFnReleased_wrapper btnFnReleased_wrapper
#define Z47_GTK_CALLBACK_ALIAS_btnPressed z47_btnPressed_signal
#define Z47_GTK_CALLBACK_ALIAS_btnReleased z47_btnReleased_signal
#define Z47_GTK_CALLBACK_ALIAS_destroyCalc destroyCalc
#define Z47_GTK_CALLBACK_ALIAS_drawScreen drawScreen
#define Z47_GTK_CALLBACK_ALIAS_keyPressed keyPressed
#define Z47_GTK_CALLBACK_ALIAS_keyReleased keyReleased
#define Z47_GTK_CALLBACK_ALIAS_onConfigureEvent onConfigureEvent
#define Z47_GTK_CALLBACK_ALIAS_onScreenChanged onScreenChanged
#define Z47_GTK_CALLBACK_ALIAS_onUIActivity onUIActivity

#undef G_CALLBACK
#define G_CALLBACK(callback) ((GCallback)(Z47_GTK_CALLBACK_ALIAS_##callback))

#include "../../src/c47-gtk/gtkGui.c"