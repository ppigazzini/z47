// SPDX-License-Identifier: GPL-3.0-only
//
// C reference side of the ln-complex oracle.
//
// The oracle differentiates the Zig owner's lnComplex against upstream's, so it
// needs the real src/c47/mathematics/ln.c body -- not a stub. But that file also
// defines fnLn / lnReal / lnCplx, and the Zig owner exports those, so linking it
// whole is a wall of duplicate symbols. Include it with only those three renamed:
// lnComplex itself keeps its name and its real implementation, which is the whole
// point (renaming the function under test is how a harness silently neuters its
// own oracle -- see the harness-headers note).
//
// The renamed entry points are never called; they exist only so the translation
// unit still compiles as a whole.

#define fnLn   z47_ln_complex_reference_fnLn
#define lnReal z47_ln_complex_reference_lnReal
#define lnCplx z47_ln_complex_reference_lnCplx

#include "../../../upstream/src/c47/mathematics/ln.c"

#undef fnLn
#undef lnReal
#undef lnCplx
