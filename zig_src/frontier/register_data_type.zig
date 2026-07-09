// SPDX-License-Identifier: GPL-3.0-only
//! Pure register data-type classification lifted out of the frontier owners.
//! isPrintableScalarType was duplicated verbatim in frontier.zig and
//! frontier_print_all_regs.zig; dataTypeNameKnown backed getDataTypeName in
//! frontier_debug.zig. All three are switch predicates over the defines.h `dt`
//! enum with no runtime coupling, so they move here (imports only std, runs
//! under `zig build test:unit`). The owners delegate.
//!
//! The dt values mirror defines.h and are verified against upstream C by the
//! audit-constant-parity gate, so they cannot drift silently.

const std = @import("std");

pub const dtLongInteger: u32 = 0;
pub const dtReal34: u32 = 1;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtDate: u32 = 4;
pub const dtString: u32 = 5;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;
pub const dtConfig: u32 = 9;

/// True for the scalar register types that print directly (the printAll and
/// SNAP paths treat these as printable-in-place).
pub fn isPrintableScalarType(dt: u32) bool {
    return switch (dt) {
        dtLongInteger, dtReal34, dtShortInteger, dtString, dtDate, dtTime => true,
        else => false,
    };
}

/// True for the register types getDataTypeName has a name-table entry for.
pub fn dataTypeNameKnown(dt: u32) bool {
    return switch (dt) {
        dtLongInteger, dtTime, dtDate, dtString, dtReal34Matrix, dtComplex34Matrix, dtShortInteger, dtReal34, dtComplex34, dtConfig => true,
        else => false,
    };
}

const testing = std.testing;

test "isPrintableScalarType accepts the scalar types and rejects the rest" {
    for ([_]u32{ dtLongInteger, dtReal34, dtShortInteger, dtString, dtDate, dtTime }) |dt| {
        try testing.expect(isPrintableScalarType(dt));
    }
    for ([_]u32{ dtComplex34, dtReal34Matrix, dtComplex34Matrix, dtConfig, 10, 255 }) |dt| {
        try testing.expect(!isPrintableScalarType(dt));
    }
}

test "dataTypeNameKnown accepts every defined dt and rejects out-of-range" {
    var dt: u32 = 0;
    while (dt <= 9) : (dt += 1) {
        try testing.expect(dataTypeNameKnown(dt));
    }
    try testing.expect(!dataTypeNameKnown(10));
    try testing.expect(!dataTypeNameKnown(255));
}
