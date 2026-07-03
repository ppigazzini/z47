// SPDX-License-Identifier: GPL-3.0-only
//
// L1 bindings -- shared ABI types (REPORT-23 §5). Single source of truth for the
// C numeric layouts the owners previously each hand-mirrored (36 owners defined
// their own `const real_t = extern struct {...}`; this centralizes that one copy
// and pins the layout at comptime so a toolchain/pin change is caught here rather
// than corrupting decNumber at runtime -- the M10.4/M16 crash class REPORT-23 §2
// calls out).
//
// These mirror src/c47 (decNumber.h `decNumber`, decQuad `real34_t`,
// decContext `realContext_t`). The layout is proven by the parity oracles that
// already pass against the pinned upstream C; the asserts below pin the Zig side
// of that contract. When the L1 generator lands (REPORT-23 Phase 0) it emits this
// file from the pinned headers; until then it is hand-maintained and asserted.

const std = @import("std");

/// decNumber real_t: DECNUMDIGITS-backed decimal. DECNUMUNITS = 25 (7*DECDPUN..).
pub const DECNUMUNITS = 25;
pub const Real = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

/// decQuad-backed 34-digit real (16 raw bytes).
pub const Real34 = extern struct { bytes: [16]u8 };

/// Byte-compatible opaque view of `Real` for owners that only pass it to C as a
/// handle (zero-init + &x) and never read fields. Same size/align as `Real`, so
/// it is a drop-in for the `{ bytes: [60]u8 align(4) }` owners the migration
/// task converts.
pub const RealBlob = extern struct { bytes: [60]u8 align(4) };

/// decContext.
pub const RealContext = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};

/// A complex value as a pair of `Real` (the C `CPLX(x)` passes &x.Real, &x.Imag).
pub const Complex = extern struct { Real: Real, Imag: Real };

/// decQuad complex (two Real34).
pub const Complex34 = extern struct { real: Real34, imag: Real34 };

/// Subroutine-level header (run-time stack frame).
pub const SubroutineLevelHeader = extern struct {
    returnProgramNumber: i16,
    returnLocalStep: u16,
    numberOfLocalFlags: u8,
    numberOfLocalRegisters: u8,
    subroutineLevel: u16,
    ptrToNextLevel: u16,
    ptrToPreviousLevel: u16,
};

/// Typed constant-blob accessors (L1), reached as `abi.constants.const1on2()`.
pub const constants = @import("constants.zig");

/// Typed C-runtime wrappers (L1), reached as `abi.runtime.add(&a, &b, &r)`.
pub const runtime = @import("runtime.zig");

// decNumber bit flags (realType.h), shared by the owners that inspect `Real.bits`.
pub const DECNEG: u8 = 0x80;
pub const DECINF: u8 = 0x40;
pub const DECNAN: u8 = 0x20;
pub const DECSNAN: u8 = 0x10;
pub const DECSPECIAL: u8 = DECINF | DECNAN | DECSNAN;

comptime {
    // Pin the Zig layout of the C-shared types. A mismatch here is a build error,
    // not a silent runtime reinterpretation.
    std.debug.assert(@offsetOf(Real, "digits") == 0);
    std.debug.assert(@offsetOf(Real, "exponent") == 4);
    std.debug.assert(@offsetOf(Real, "bits") == 8);
    std.debug.assert(@offsetOf(Real, "lsu") == 10);
    std.debug.assert(@sizeOf(Real) == 60);
    std.debug.assert(@sizeOf(Real34) == 16);
    std.debug.assert(@sizeOf(Complex) == 2 * @sizeOf(Real));
    std.debug.assert(@sizeOf(Complex34) == 32);
    std.debug.assert(@sizeOf(SubroutineLevelHeader) == 12);
}

// Colocated hermetic tests (REPORT-23 §7.2) -- run by `zig build idiom-test`.
// These assert the ABI contract the C parity oracle cannot express directly.
const testing = std.testing;

test "Real matches the C decNumber ABI (size/offsets)" {
    try testing.expectEqual(@as(usize, 60), @sizeOf(Real));
    try testing.expectEqual(@as(usize, 4), @alignOf(Real));
    try testing.expectEqual(@as(usize, 0), @offsetOf(Real, "digits"));
    try testing.expectEqual(@as(usize, 10), @offsetOf(Real, "lsu"));
}

test "Complex is two back-to-back Reals" {
    try testing.expectEqual(@sizeOf(Real), @offsetOf(Complex, "Imag"));
    try testing.expectEqual(2 * @sizeOf(Real), @sizeOf(Complex));
}

test "RealBlob is a drop-in for Real (same size and align)" {
    try testing.expectEqual(@sizeOf(Real), @sizeOf(RealBlob));
    try testing.expectEqual(@alignOf(Real), @alignOf(RealBlob));
}

test "decNumber special-flag mask is INF|NAN|SNAN" {
    try testing.expectEqual(@as(u8, DECINF | DECNAN | DECSNAN), DECSPECIAL);
}
