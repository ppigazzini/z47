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

#endif // !C47_GTK_H
