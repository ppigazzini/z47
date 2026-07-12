// SPDX-License-Identifier: GPL-3.0-only
//
// Pure WP34S/C47 double->string display formatting, lifted from
// frontier_register_value_conversions.zig (src/c47/registerValueConversions.c
// sci_fmt + convertDoubleToString). Distinct from abi.float_format (the
// byte-exact libc %e/%g family): this is the calculator's own fixed-15-digit
// scientific form plus the sign/locale-separator normalization the register
// converters wrap around it.
//
// The C originals write through a `char *` (a C pointer); here they take a plain
// `[]u8` slice whose length is the C `n` bound, so the module imports only std and
// is exercised natively under `zig build test:unit`. The frontier owner keeps its
// `pub export` C-pointer C-ABI wrappers and delegates the buffer work here.
//
// These paths are testSuite-BLIND (only the graph/plot/stat/config-battery code
// calls them), so the native byte-pinning tests below are their only automated
// coverage -- the extraction is verbatim to keep behaviour identical.

const std = @import("std");

/// Format `x` into `buf` in the C47 scientific form ("d.ddddddddddddddde+NN"),
/// NUL-terminated. `buf.len` plays the role of the C `n` bound (the exponent is
/// only appended while `i + 6 < buf.len`, matching the C `i < n - 6`). Callers
/// pass a 100-byte buffer. Byte-identical to registerValueConversions.c sci_fmt.
pub fn sciFmt(buf: []u8, x_arg: f64) void {
    var x = x_arg;
    var exp: i32 = 0;
    var i: usize = 0;
    if (x < 0) {
        buf[i] = '-';
        i += 1;
        x = -x;
    }

    while (x != 0 and x < 1.0) {
        x *= 10.0;
        exp -= 1;
    }
    while (x >= 10.0) {
        x /= 10.0;
        exp += 1;
    }

    var m: u64 = @intFromFloat(x * 1e15 + 0.5);
    if (m >= 10000000000000000) {
        m /= 10;
        exp += 1;
    }

    buf[i] = '0' + @as(u8, @intCast(m / 1000000000000000));
    i += 1;
    buf[i] = '.';
    i += 1;

    const divs = [_]u64{
        1000000000000000, 100000000000000, 10000000000000,
        1000000000000,    100000000000,    10000000000,
        1000000000,       100000000,       10000000,
        1000000,          100000,          10000,
        1000,             100,             10,
    };

    var j: usize = 1;
    while (j < 15 and i + 6 < buf.len) : (j += 1) {
        buf[i] = '0' + @as(u8, @intCast((m / divs[j]) % 10));
        i += 1;
    }

    const dest = buf[i..];
    const written = std.fmt.bufPrint(dest, "e{s}{d:0>2}", .{ if (exp < 0) "-" else "+", @abs(exp) }) catch dest[0..0];
    i += written.len;
    buf[i] = 0;
}

/// Reformat `buf` (already NUL-terminated, `buf.len` == the C `n`) into the
/// canonical register-display string: force a leading sign, force '.' as the
/// decimal separator, and strip stray separators/spaces; falls back to "NaN" on a
/// malformed layout. Byte-identical to convertDoubleToString (its PC_BUILD
/// host-only diagnostic printf is dropped, as in the owner).
pub fn normalizeDoubleString(buf: []u8, x: f64) void {
    var i: usize = 2;
    var j: usize = 2;
    var err: bool = false;

    sciFmt(buf, x);

    if (buf[0] != '-') {
        i = 0;
        while (buf[i] != 0) {
            i += 1;
        }
        buf[i + 1] = 0;
        while (i != 0) {
            buf[i] = buf[i - 1];
            i -= 1;
        }
        buf[0] = '+';
    }

    if (buf[0] != 0 and (buf[1] == '+' or buf[1] != '-') and (buf[2] == '.' or buf[2] == ',')) {
        buf[2] = '.';
        i = 3;
        j = 3;
        while (buf[i] != 0) {
            if (buf[i] == ',' or buf[i] == '.' or buf[i] == ' ') {
                buf[j] = 0;
            } else {
                buf[j] = buf[i];
                j += 1;
            }
            i += 1;
        }
        buf[j] = 0;
    } else {
        err = true;
    }

    if (err) {
        buf[0] = 'N';
        buf[1] = 'a';
        buf[2] = 'N';
        buf[3] = 0;
    }
}

// ===========================================================================
// Tests -- native byte-pinning (run under `zig build test:unit`). These are the
// ONLY automated coverage of this testSuite-blind formatter. Expected strings are
// hand-derived from the C algorithm (15 fractional digits, "e{+/-}NN" exponent).
// ===========================================================================
const testing = std.testing;

fn asStr(buf: []const u8) []const u8 {
    const nul = std.mem.indexOfScalar(u8, buf, 0) orelse buf.len;
    return buf[0..nul];
}

test "sciFmt: zero" {
    var buf: [100]u8 = undefined;
    sciFmt(&buf, 0.0);
    try testing.expectEqualStrings("0.00000000000000e+00", asStr(&buf));
}

test "sciFmt: a negative unit value" {
    var buf: [100]u8 = undefined;
    sciFmt(&buf, -1.0);
    try testing.expectEqualStrings("-1.00000000000000e+00", asStr(&buf));
}

test "sciFmt: a fractional mantissa" {
    var buf: [100]u8 = undefined;
    sciFmt(&buf, 1.5);
    try testing.expectEqualStrings("1.50000000000000e+00", asStr(&buf));
}

test "sciFmt: a value below 1 gets a negative exponent" {
    var buf: [100]u8 = undefined;
    sciFmt(&buf, 0.05);
    try testing.expectEqualStrings("5.00000000000000e-02", asStr(&buf));
}

test "sciFmt: a value with a positive exponent" {
    var buf: [100]u8 = undefined;
    sciFmt(&buf, 1000.0);
    try testing.expectEqualStrings("1.00000000000000e+03", asStr(&buf));
}

test "normalizeDoubleString: a positive value gains a leading '+'" {
    var buf: [100]u8 = undefined;
    normalizeDoubleString(&buf, 1.5);
    try testing.expectEqualStrings("+1.50000000000000e+00", asStr(&buf));
}

test "normalizeDoubleString: a negative value keeps its '-'" {
    var buf: [100]u8 = undefined;
    normalizeDoubleString(&buf, -1.0);
    try testing.expectEqualStrings("-1.00000000000000e+00", asStr(&buf));
}

test "normalizeDoubleString: zero" {
    var buf: [100]u8 = undefined;
    normalizeDoubleString(&buf, 0.0);
    try testing.expectEqualStrings("+0.00000000000000e+00", asStr(&buf));
}
