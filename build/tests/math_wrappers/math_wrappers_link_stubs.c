// SPDX-License-Identifier: GPL-3.0-only

#include <stdint.h>
#include <string.h>

// addition.c (addStriReal/addStriCplx) trims a leading space from its result.
// Faithful definition (master uses stringByteLength/xcopy; memmove/strlen are
// equivalent here) so the oracle matches the Zig port if that path is hit.
void trimLeadingSpace(char *stringToTrim) {
    if (stringToTrim[0] == ' ') {
        memmove(stringToTrim, stringToTrim + 1, strlen(stringToTrim));
    }
}

// get_type.zig forms its result in decQuad, reading const34_1000 out of the
// generated constant blob, exactly as checkValue.c does. This lane links neither
// decNumber nor the blob, so both symbols are filled in here.
//
// Nothing in this lane calls them: fnGetType is compared in the full-core
// math-wrapper differential, where the real decQuad and the real blob are
// present. A stub that is reached would silently answer 0; if a case is ever
// added here that reaches one, it will read this comment first.
uint8_t constants[1];

void *decQuadFromUInt32(void *res, uint32_t value) {
    (void)value;
    return res;
}

// real34SetZero is decNumber's decQuadZero in c43, and this lane links no
// decNumber. The imaginary part of a real matrix reaches it once per element,
// through the Zig owner, while the oracle's copy of imaginaryPart.c expands the
// mock header's real34SetZero to sixteen zero bytes. So this writes those same
// sixteen bytes, which is the zero both sides of this lane share.
void *decQuadZero(void *res) {
    memset(res, 0, 16);
    return res;
}
