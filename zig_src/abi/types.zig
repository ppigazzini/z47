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

/// Typed constant-blob accessors (L1), reached as `abi.constants.const1on2()`.
pub const constants = @import("constants.zig");

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
}
