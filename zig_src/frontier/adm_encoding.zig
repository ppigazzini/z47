// SPDX-License-Identifier: GPL-3.0-only
//
// Pure legacy external-ADM angular-mode encoding, lifted from frontier_config.zig
// (src/c47/config.c). The RCL/SET ADM interface stores the angular mode in an
// external encoding (0=DEG, 1=D.MS, 2=RAD, 3=MULT-pi, 4=GRAD) that differs from
// angularMode_t order (amRadian, amGrad, amDegree, amDMS, amMultPi). It is a pure
// bijection over the five modes -- std-only, no register/dec/GTK/global coupling --
// so it lives here as a module exercised natively under `zig build test:unit`. The
// config owner keeps its fnGetADM/fnSetADM C-ABI wrappers, reads/writes
// currentAngularMode, and delegates.
//
// testSuite-BLIND (config ADM save/restore is not in the oracle suite), so the
// native tests below are the first automated coverage of the encoding.

const std = @import("std");

// angularMode_t (typeDefinitions.h).
pub const amRadian: u8 = 0;
pub const amGrad: u8 = 1;
pub const amDegree: u8 = 2;
pub const amDMS: u8 = 3;
pub const amMultPi: u8 = 4;

// Indexed by angularMode_t -> external ADM value.
const angularModeToAdm = [5]u8{ 2, 4, 0, 1, 3 };
// Indexed by the external ADM value -> angularMode_t.
const admToAngularMode = [5]u8{ amDegree, amDMS, amRadian, amMultPi, amGrad };

/// The external ADM encoding of `angular_mode` (an angularMode_t value), or 0 when
/// out of range (mirrors config.h's `admValue()` guard).
pub fn admValue(angular_mode: i32) u8 {
    return if (angular_mode >= 0 and @as(usize, @intCast(angular_mode)) < angularModeToAdm.len)
        angularModeToAdm[@intCast(angular_mode)]
    else
        0;
}

/// The angularMode_t for an external ADM `adm` value, or null when out of range
/// (config.c then leaves the mode unchanged instead of calling fnAngularMode).
pub fn angularModeFromAdm(adm: u32) ?u8 {
    return if (adm < admToAngularMode.len) admToAngularMode[adm] else null;
}

const testing = std.testing;

test "admValue / angularModeFromAdm round-trips every angular mode" {
    for ([_]u8{ amRadian, amGrad, amDegree, amDMS, amMultPi }) |am| {
        try testing.expectEqual(am, angularModeFromAdm(admValue(am)).?);
    }
}

test "external ADM encoding matches the legacy RCL ADM mapping (0=DEG..4=GRAD)" {
    try testing.expectEqual(@as(u8, 0), admValue(amDegree));
    try testing.expectEqual(@as(u8, 1), admValue(amDMS));
    try testing.expectEqual(@as(u8, 2), admValue(amRadian));
    try testing.expectEqual(@as(u8, 3), admValue(amMultPi));
    try testing.expectEqual(@as(u8, 4), admValue(amGrad));
}

test "angularModeFromAdm maps every external ADM value back" {
    try testing.expectEqual(@as(u8, amDegree), angularModeFromAdm(0).?);
    try testing.expectEqual(@as(u8, amDMS), angularModeFromAdm(1).?);
    try testing.expectEqual(@as(u8, amRadian), angularModeFromAdm(2).?);
    try testing.expectEqual(@as(u8, amMultPi), angularModeFromAdm(3).?);
    try testing.expectEqual(@as(u8, amGrad), angularModeFromAdm(4).?);
}

test "out-of-range inputs fall back safely" {
    try testing.expectEqual(@as(u8, 0), admValue(5)); // amNone and beyond
    try testing.expectEqual(@as(u8, 0), admValue(-1));
    try testing.expectEqual(@as(?u8, null), angularModeFromAdm(5));
    try testing.expectEqual(@as(?u8, null), angularModeFromAdm(99));
}
