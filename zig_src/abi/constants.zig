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
