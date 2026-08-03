// SPDX-License-Identifier: GPL-3.0-only
//
// Shadows the system <gtk/gtk.h> for headless parity harnesses ONLY.
//
// Under PC_BUILD, upstream's `c47.h` includes <gtk/gtk.h>. A harness that puts
// `build/tests/common` on its include path ahead of the system paths gets this
// file instead, which is the whole reason a lane can compile c43 core source
// without linking a GUI toolkit. See c43_harness_prelude.h for why the six names
// are enough and for the one file (keyboard.c) they are not enough for.
//
// This is NOT a GTK implementation and must never grow into one. If a harness
// needs real GTK behaviour it wants the full-core harness (addFullCoreHarness),
// which links the real toolkit.

#if !defined(Z47_HARNESS_GTK_H)
  #define Z47_HARNESS_GTK_H

  // Spelled relative so it resolves from this file's own directory whatever the
  // -I order is, and so check-harness-includes.py validates it.
  #include "../c43_harness_prelude.h"

#endif // Z47_HARNESS_GTK_H
