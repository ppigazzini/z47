// SPDX-License-Identifier: GPL-3.0-only
//
// The whole cost of compiling c43 source into a headless parity harness.
//
// WHY THIS EXISTS (REPORT-31 M31-9). A parity oracle must be COMPILED FROM c43
// source, or it cannot see c43 move -- see docs/70-tests-and-verification.md and
// __DEV/reports/REPORT-31-C-ORACLE.md. The first two conversions (M31-2 flags,
// M31-3 program_serialization) each reached that by hand-building a per-lane mock
// `c47.h` for the file under test. That works, but it is the same defect one level
// down: a mock header carries hand-copied constants, and a hand-copied constant
// does not move when c43 moves either.
//
// M31-4/M31-5 then measured the alternative and it is both cheaper and strictly
// more faithful: upstream's OWN `src/c47/c47.h` compiles in a headless harness
// with nothing hand-written at all -- given the vendored `dep/decNumberICU`
// headers, the generated `src/generated/constantPointers.h`, and the six
// placeholder typedefs below. Every constant, struct and prototype then comes
// from the pin.
//
// WHY GTK APPEARS AT ALL. `defines.h` refuses to compile unless one of PC_BUILD /
// DMCP_BUILD is defined, and under PC_BUILD `c47.h` pulls <gtk/gtk.h> and
// <gdk/gdk.h>. A headless unit harness has no business linking a GUI toolkit, so
// `build/tests/common/gtk/gtk.h` and `build/tests/common/gdk/gdk.h` shadow those
// two system headers with stubs that include this file. The names below are the
// only GTK/glib/cairo spellings the core headers need: they appear in struct
// fields and prototypes that a state or register harness never touches, so only
// the NAMES have to exist -- no layout, no ABI, no linkage.
//
// THE SET IS MINIMAL, BY LEAVE-ONE-OUT. Measured 2026-08-03 at pin b9e1cc0c1:
// dropping any one of the six breaks the compile of `registers.c` or
// `saveRestoreCalcState.c`, and five further candidates tried (`guint`, `gint`,
// `gchar`, `GdkEventButton`, `GdkEventKey`) are redundant. To re-derive after a
// resync, delete one line and rebuild a converted lane; if it still compiles, the
// line is dead and should go.
//
// KEYBOARD IS THE ONE FILE THIS DOES NOT REACH (REPORT-31 M31-6/M31-13).
// `keyboard.c` reads `GdkEvent` FIELDS and declares a `GdkEventButton` BY VALUE,
// so a placeholder name is not enough and it needs the real gtk+-3.0 headers.
// That is why the keyboard lane is a full-core differential rather than a linked
// oracle -- do not try to grow this file until it covers keyboard.c.

#if !defined(Z47_C43_HARNESS_PRELUDE_H)
  #define Z47_C43_HARNESS_PRELUDE_H

  // Incomplete struct/union tags on purpose: a harness that tries to dereference
  // one of these gets a compile error rather than a plausible-looking zero.
  typedef struct _Z47HarnessGtkWidget GtkWidget;
  typedef union _Z47HarnessGdkEvent GdkEvent;
  typedef struct _Z47HarnessCairo cairo_t;

  typedef void *gpointer;
  typedef int gboolean;
  typedef long long gint64;

#endif // Z47_C43_HARNESS_PRELUDE_H
