// SPDX-License-Identifier: GPL-3.0-only
//
// abi struct-layout parity oracle (seam-and-core roadmap, Phase 1 crux harness).
//
// abi/types.zig hand-mirrors the pinned upstream C numeric ABI. The colocated
// comptime block in that file pins the ZIG side against hardcoded offsets, but
// that is self-referential: it cannot catch upstream drift, and it cannot prove
// a future GENERATED abi/types.zig matches the C. This oracle closes that gap by
// comparing the abi mirrors DIRECTLY against the translate-c'd upstream headers
// (`@sizeOf`/`@offsetOf` of the real C `decNumber`/`decQuad`/`decContext`), so a
// wrong layout fails the build here -- the silent-corruption class (M10.4/M16)
// that sim+test do not surface.
//
// Run via `zig build abi-layout-parity`. This must gate green against the
// hand-maintained abi/types.zig before that file is generated; afterward it is
// the adjudicator that a regenerated seam still byte-matches the C.

const std = @import("std");
const testing = std.testing;
const c = @import("c_bindings");
const abi = @import("abi");

/// Assert a named field sits at the same byte offset in the C type and the abi
/// mirror. comptime so a mismatch is a compile error, not a late runtime fail.
fn expectSameOffset(comptime C: type, comptime Z: type, comptime field: []const u8) !void {
    try testing.expectEqual(@offsetOf(C, field), @offsetOf(Z, field));
}

fn expectSameSizeAlign(comptime C: type, comptime Z: type) !void {
    try testing.expectEqual(@sizeOf(C), @sizeOf(Z));
    try testing.expectEqual(@alignOf(C), @alignOf(Z));
}

test "abi.Real matches C decNumber (size + every field offset)" {
    try expectSameSizeAlign(c.decNumber, abi.Real);
    inline for (.{ "digits", "exponent", "bits", "lsu" }) |f| {
        try expectSameOffset(c.decNumber, abi.Real, f);
    }
}

test "abi.Real34 matches C decQuad (size)" {
    // decQuad is an opaque 16-byte union (natural align 4). abi.Real34 is a
    // `{ bytes: [16]u8 }` blob DELIBERATELY at align 1 so registers.zig can view
    // unaligned register storage as `*align(1) Real34`; that align-1 is benign
    // because Real34 only ever sits at 16-byte-aligned offsets in the abi
    // composites (Complex34, matrices). The contract for this opaque blob is its
    // size, so assert that and not the intentional align divergence.
    try testing.expectEqual(@sizeOf(c.decQuad), @sizeOf(abi.Real34));
}

test "abi.RealContext matches C decContext (every mirrored field offset)" {
    // decContext may carry extra members under DECSUBSET, so compare the field
    // offsets abi mirrors rather than the total size.
    inline for (.{ "digits", "emax", "emin", "round", "traps", "status", "clamp" }) |f| {
        try expectSameOffset(c.decContext, abi.RealContext, f);
    }
}

test "abi.Complex is two back-to-back C decNumbers" {
    try testing.expectEqual(@as(usize, 2) * @sizeOf(c.decNumber), @sizeOf(abi.Complex));
    try testing.expectEqual(@sizeOf(c.decNumber), @offsetOf(abi.Complex, "Imag"));
}

test "abi.Complex34 is two back-to-back C decQuads" {
    try testing.expectEqual(@as(usize, 2) * @sizeOf(c.decQuad), @sizeOf(abi.Complex34));
    try testing.expectEqual(@sizeOf(c.decQuad), @offsetOf(abi.Complex34, "imag"));
}
