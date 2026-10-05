// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/**
 * \file c47-gtk.h
 */
#if !defined(C47_GTK_H)
  #define C47_GTK_H

  #include <gtk/gtk.h>
  #include <stdbool.h>

  #if defined(NDEBUG)
    #define BASEPATH "./"
  #else
    #define BASEPATH "../../../"
  #endif

  extern GtkWidget *frmCalc;
  gboolean scriptInjectGtkKey(uint32_t keyval);
  gboolean scriptInjectKeyHeadless(uint32_t keyval);

  /**
   * Decodes one byte of the HP 82240 byte stream into the print-out window.
   * \param[in] c byte sent to the printer
   */
  void printerWindowByte(uint8_t c);

  /**
   * Shows the print-out window, or hides it when it is shown.
   */
  void printerWindowToggle(void);

  /**
   * Sets ui_is_active for 100 ms, which keeps _lcdSBRefresh() from running the main loop while a window is moved, resized or focused.
   */
  gboolean onUIActivity(GtkWidget *w, GdkEvent *event, gpointer data);

#endif // !C47_GTK_H
