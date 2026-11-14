// SPDX-License-Identifier: GPL-3.0-only

#define STUB(name) void name(void) {}

// The random lane links the fake-surface mathematics object without the
// arithmetic oracle, and that object's expM1 owner reaches addComplex. No case
// in this lane drives it.
STUB(addComplex)
