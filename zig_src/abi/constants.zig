// SPDX-License-Identifier: GPL-3.0-only
//
// L1 bindings -- typed accessors into the generated `constants` blob
// (REPORT-23 §5/§6 P3). Owners previously reached the blob with a raw
// `@extern([*]const u8,"constants") + <magic offset>` then an unchecked
// `@ptrCast` (773 offset refs across the tree, the offset-crash class). Here the
// offset lives once, behind a named, typed accessor returning `*const Real`.
//
// The offsets are the post-pin-advance generateConstants layout (host + DMCP
// package 3, which share one blob layout; pinned by src/testSuite/tests/elec.txt
// and the pkg-3 build). When the L1 generator lands (REPORT-23 Phase 0) it emits
// these named accessors from constantPointers.h; until then they are
// hand-maintained here, seeded with the elec pilot's constants and grown per
// owner as the refactor rolls out.

const types = @import("types.zig");
const Real = types.Real;

const constants = @extern([*]const u8, .{ .name = "constants" });

inline fn at(comptime offset: u32) *align(1) const Real {
    return @ptrCast(constants + offset);
}

// --- Seeded for the elec pilot (mathematics/elec.c) ---
pub inline fn const1on2() *align(1) const Real {
    return at(4580);
}
pub inline fn const3() *align(1) const Real {
    return at(5012);
}
pub inline fn root3on2() *align(1) const Real {
    return at(4772);
}
pub inline fn const1e_37() *align(1) const Real {
    return at(4436);
}

// --- math_gd ---
pub inline fn const39piOn2() *align(1) const Real {
    return at(4880);
}
pub inline fn const39piOn4() *align(1) const Real {
    return at(4736);
}
pub inline fn const__1() *align(1) const Real {
    return at(4376);
}
pub inline fn const_1() *align(1) const Real {
    return at(4856);
}
pub inline fn const_2() *align(1) const Real {
    return at(4928);
}
pub inline fn const_1on2() *align(1) const Real {
    return at(4580);
}
pub inline fn const_10() *align(1) const Real {
    return at(5132);
}
pub inline fn const_360() *align(1) const Real {
    return at(5356);
}
pub inline fn const_400() *align(1) const Real {
    return at(5368);
}
pub inline fn const1071_pi() *align(1) const Real {
    return at(9932);
}
pub inline fn const2139_2pi() *align(1) const Real {
    return at(10656);
}
pub inline fn const__4() *align(1) const Real {
    return at(4364);
}
pub inline fn const_1on4() *align(1) const Real {
    return at(4532);
}
pub inline fn const39_1on3() *align(1) const Real {
    return at(4544);
}
pub inline fn const39_pi() *align(1) const Real {
    return at(1848);
}
pub inline fn const39_piOn2() *align(1) const Real {
    return at(4880);
}
pub inline fn const39_piOn4() *align(1) const Real {
    return at(4736);
}
pub inline fn const75_2pi() *align(1) const Real {
    return at(7640);
}
pub inline fn const_1e_32() *align(1) const Real {
    return at(5708);
}
pub inline fn const_1e_37() *align(1) const Real {
    return at(4436);
}
pub inline fn const_1e_49() *align(1) const Real {
    return at(4424);
}
pub inline fn const__1Off() *align(1) const Real {
    return at(4376);
}
pub inline fn const_3Off() *align(1) const Real {
    return at(5012);
}
pub inline fn const_0() *align(1) const Real {
    return at(1708);
}
pub inline fn const_1on10() *align(1) const Real {
    return at(4520);
}
pub inline fn const_60() *align(1) const Real {
    return at(5296);
}
pub inline fn const_100() *align(1) const Real {
    return at(7532);
}
pub inline fn const_3() *align(1) const Real {
    return at(5012);
}
pub inline fn const_4() *align(1) const Real {
    return at(5024);
}
pub inline fn const_5() *align(1) const Real {
    return at(5072);
}
pub inline fn const_8() *align(1) const Real {
    return at(5108);
}
pub inline fn const_24() *align(1) const Real {
    return at(5168);
}
pub inline fn const_90() *align(1) const Real {
    return at(7544);
}
pub inline fn const75_piOn2() *align(1) const Real {
    return at(7472);
}
pub inline fn const39_gammaEM() *align(1) const Real {
    return at(1256);
}
pub inline fn const39_egamma() *align(1) const Real {
    return at(4592);
}
pub inline fn const_NaN() *align(1) const Real {
    return at(812);
}
pub inline fn const39_2pi() *align(1) const Real {
    return at(1812);
}
pub inline fn const39_ln2piOn2() *align(1) const Real {
    return at(4820);
}
pub inline fn const_12() *align(1) const Real {
    return at(5144);
}
pub inline fn const_1260() *align(1) const Real {
    return at(5408);
}
pub inline fn const_1680() *align(1) const Real {
    return at(5420);
}
pub inline fn const39_root3on2() *align(1) const Real {
    return at(4772);
}
pub inline fn const_9() *align(1) const Real {
    return at(5120);
}
pub inline fn const_54() *align(1) const Real {
    return at(5248);
}
pub inline fn const_2916() *align(1) const Real {
    return at(5432);
}
