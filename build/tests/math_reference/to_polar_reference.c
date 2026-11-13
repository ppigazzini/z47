// SPDX-License-Identifier: GPL-3.0-only
//
// C reference side of the rectangular-to-polar differential.
//
// The rectangular-to-polar lane compares the Zig owner against upstream's own
// mathematics/toPolar.c. Linked as it is, that file would collide with the Zig
// owners' exports of the same names, so it is included here with every global
// it defines renamed to oracle_<name>. Its calls between those globals rename
// with them, so the reference is c43's code throughout. The list is the
// object's own symbol table (nm --defined-only -g of toPolar.c compiled
// alone), not a header: a global the list misses is a duplicate symbol at link
// time, never a silent stand-in.

#define fnToPolar2                   oracle_fnToPolar2
#define fnToPolar_CX                 oracle_fnToPolar_CX
#define fnToPolar_HP                 oracle_fnToPolar_HP
#define real34RectangularToPolar     oracle_real34RectangularToPolar
#define realRectangularToPolar       oracle_realRectangularToPolar
#define realRectangularToPolarCached oracle_realRectangularToPolarCached

#include "../../../upstream/src/c47/mathematics/toPolar.c"
