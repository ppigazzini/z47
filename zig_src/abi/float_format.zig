// SPDX-License-Identifier: GPL-3.0-only
//
// Byte-exact C `%.<P>e` / `%.<P>f` / `%<w>.<P>g` float formatters (REPORT-23 /
// MILESTONES-4 M24 float axis). std-only, zero externs -- so the format oracle
// (`zig_build/tests/format/format_parity.zig`) imports and proves THIS exact
// code byte-identical to libc over a fuzz matrix, and the shipping `abi`
// re-exports it.
//
// Why not std.fmt: C `printf("%.Pe", x)` prints the EXACT decimal expansion of
// the f64 to P+1 significant digits with round-half-to-even -- NOT the shortest
// round-trip repr std.fmt emits (proven divergent in the oracle: 0.3 -> C
// "2.9999999999999999e-01" vs Zig "3.0000000000000000e-1"). std.fmt cannot
// reproduce the display/CSV/backup/save bytes the sprintf sites write.
//
// How, without bignum DIVISION (the flash-heavy std.math.big.int overflowed the
// DMCP pkg3 firmware): a finite f64 is `m * 2^be` exactly, so
//   be >= 0:  |x| = (m << be)              as an integer,        point exp 0
//   be <  0:  |x| = (m * 5^(-be)) x 10^be  (m*2^be = m*5^-be*10^be)
// Either way the EXACT decimal digits are the digits of an INTEGER, obtained
// with only multiply-by-small (repeated *2 or *5) and decimal extraction
// (divmod by 1e9) -- no bignum/bignum division, no allocator. Rounding to P
// significant digits (half-even) is then plain digit-string manipulation.
// Non-reentrant like the C sprintf it replaces (single-threaded calculator);
// all scratch is stack-local.

const std = @import("std");

// 5^1074 (the widest case, subnormal min) is ~2493 bits ~ 78 u32 limbs; 96 has
// margin. m << 971 (max normal) is only ~1024 bits.
const LIMBS = 96;

const Big = struct {
    l: [LIMBS]u32 = @splat(0),
    n: usize = 0,

    fn setU64(self: *Big, v: u64) void {
        self.l = @splat(0);
        self.l[0] = @truncate(v);
        self.l[1] = @truncate(v >> 32);
        self.n = if (v >> 32 != 0) 2 else if (v != 0) 1 else 0;
    }

    fn mulSmall(self: *Big, x: u32) void {
        var carry: u64 = 0;
        var i: usize = 0;
        while (i < self.n) : (i += 1) {
            const p = @as(u64, self.l[i]) * x + carry;
            self.l[i] = @truncate(p);
            carry = p >> 32;
        }
        while (carry != 0) {
            self.l[self.n] = @truncate(carry);
            carry >>= 32;
            self.n += 1;
        }
    }

    fn isZero(self: *const Big) bool {
        return self.n == 0;
    }

    /// Divide in place by 1e9; return the remainder (0..1e9-1).
    fn divmod1e9(self: *Big) u32 {
        var rem: u64 = 0;
        var i: usize = self.n;
        while (i > 0) {
            i -= 1;
            const cur = (rem << 32) | self.l[i];
            self.l[i] = @truncate(cur / 1000000000);
            rem = cur % 1000000000;
        }
        while (self.n > 0 and self.l[self.n - 1] == 0) self.n -= 1;
        return @truncate(rem);
    }
};

/// Full significant decimal digits of |m*2^be| (no leading zeros) into `buf`;
/// returns { d, x } where value = d[0].d[1..] x 10^x.
fn decimalOf(m: u64, be: i64, buf: []u8) struct { d: []u8, x: i64 } {
    var b = Big{};
    b.setU64(m);
    var pt: i64 = 0;
    if (be >= 0) {
        var i: i64 = 0;
        while (i < be) : (i += 1) b.mulSmall(2);
    } else {
        var i: i64 = 0;
        while (i < -be) : (i += 1) b.mulSmall(5);
        pt = be;
    }
    // Extract decimal (9 digits per 1e9 chunk), least-significant first.
    var tmp: [800]u8 = undefined;
    var tn: usize = 0;
    if (b.isZero()) {
        tmp[0] = '0';
        tn = 1;
    } else {
        while (!b.isZero()) {
            var chunk = b.divmod1e9();
            var k: usize = 0;
            while (k < 9) : (k += 1) {
                tmp[tn] = @intCast('0' + chunk % 10);
                tn += 1;
                chunk /= 10;
            }
        }
        while (tn > 1 and tmp[tn - 1] == '0') tn -= 1; // strip high-end zeros
    }
    // Reverse into buf (most-significant first).
    var j: usize = 0;
    while (j < tn) : (j += 1) buf[j] = tmp[tn - 1 - j];
    return .{ .d = buf[0..tn], .x = @as(i64, @intCast(tn)) - 1 + pt };
}

/// Round digit string `d` (all significant) to K digits, half-even. `out` gets
/// K chars. Returns 1 if a carry created a new leading digit (caller does X+=1).
fn roundDigits(d: []const u8, K: usize, out: []u8) usize {
    if (d.len <= K) {
        @memcpy(out[0..d.len], d);
        for (out[d.len..K]) |*c| c.* = '0';
        return 0;
    }
    @memcpy(out[0..K], d[0..K]);
    const rd = d[K];
    var roundup = false;
    if (rd > '5') {
        roundup = true;
    } else if (rd == '5') {
        var allzero = true;
        for (d[K + 1 ..]) |c| {
            if (c != '0') {
                allzero = false;
                break;
            }
        }
        roundup = if (!allzero) true else ((out[K - 1] - '0') & 1) == 1;
    }
    if (roundup) {
        var i = K;
        var carry = true;
        while (i > 0 and carry) {
            i -= 1;
            if (out[i] == '9') {
                out[i] = '0';
            } else {
                out[i] += 1;
                carry = false;
            }
        }
        if (carry) {
            out[0] = '1';
            for (out[1..K]) |*c| c.* = '0';
            return 1;
        }
    }
    return 0;
}

const Writer = struct {
    b: []u8,
    p: usize = 0,
    fn c(self: *Writer, ch: u8) void {
        self.b[self.p] = ch;
        self.p += 1;
    }
    fn s(self: *Writer, str: []const u8) void {
        @memcpy(self.b[self.p..][0..str.len], str);
        self.p += str.len;
    }
};

/// Writes sign/inf/nan/zero prefix; returns null when the value is fully handled
/// (inf/nan/zero), else the mantissa/exponent to format.
fn special(w: *Writer, bits: u64, precision: usize, comptime is_fixed: bool) ?struct { m: u64, be: i64 } {
    const neg = (bits >> 63) != 0;
    const raw_exp: u64 = (bits >> 52) & 0x7ff;
    const frac: u64 = bits & 0xFFFFFFFFFFFFF;
    if (raw_exp == 0x7ff) {
        if (frac != 0) w.s("nan") else w.s(if (neg) "-inf" else "inf");
        return null;
    }
    if (neg) w.c('-');
    if (raw_exp == 0 and frac == 0) {
        w.c('0');
        if (precision > 0) {
            w.c('.');
            for (0..precision) |_| w.c('0');
        }
        if (!is_fixed) w.s("e+00");
        return null;
    }
    if (raw_exp == 0) return .{ .m = frac, .be = -1074 }; // subnormal
    return .{ .m = frac | (1 << 52), .be = @as(i64, @intCast(raw_exp)) - 1075 };
}

/// Byte-exact C `%.<precision>e` of a finite f64 into `buf`; returns the slice
/// (no trailing NUL). For composing into a larger `fmtCStr` line.
pub fn fmtExpBuf(buf: []u8, precision: usize, value: f64) []u8 {
    var w = Writer{ .b = buf };
    const bits: u64 = @bitCast(value);
    const mb = special(&w, bits, precision, false) orelse return buf[0..w.p];

    var dbuf: [800]u8 = undefined;
    const dec = decimalOf(mb.m, mb.be, &dbuf);
    var rbuf: [64]u8 = undefined;
    const K = precision + 1;
    const bump = roundDigits(dec.d, K, &rbuf);
    const x = dec.x + @as(i64, @intCast(bump));

    w.c(rbuf[0]);
    if (precision > 0) {
        w.c('.');
        w.s(rbuf[1..K]);
    }
    w.c('e');
    w.c(if (x < 0) '-' else '+');
    const ax: u64 = @intCast(if (x < 0) -x else x);
    var eb: [8]u8 = undefined;
    const es = std.fmt.bufPrint(&eb, "{d}", .{ax}) catch unreachable;
    if (es.len < 2) w.c('0');
    w.s(es);
    return buf[0..w.p];
}

/// Byte-exact C `%.<precision>f` (fixed notation, no exponent) of a finite f64
/// into `buf`; returns the slice (no trailing NUL). C `%f` == `%.6f`.
pub fn fmtFixedBuf(buf: []u8, precision: usize, value: f64) []u8 {
    var w = Writer{ .b = buf };
    const bits: u64 = @bitCast(value);
    const mb = special(&w, bits, precision, true) orelse return buf[0..w.p];

    var dbuf: [800]u8 = undefined;
    const dec = decimalOf(mb.m, mb.be, &dbuf);
    // Keep digits from position dec.x down to -precision: K = dec.x + 1 + precision.
    const ki = dec.x + 1 + @as(i64, @intCast(precision));
    if (ki <= 0) {
        // |x| < 10^-precision: rounds to 0.00..0, or up to one ulp (10^-precision).
        var roundup = false;
        if (ki == 0) {
            const c0 = dec.d[0];
            if (c0 > '5') {
                roundup = true;
            } else if (c0 == '5') {
                var rest_nz = false;
                for (dec.d[1..]) |c| {
                    if (c != '0') {
                        rest_nz = true;
                        break;
                    }
                }
                roundup = rest_nz; // else half-even to 0 (even)
            }
        }
        if (roundup) {
            if (precision == 0) {
                w.c('1');
            } else {
                w.c('0');
                w.c('.');
                for (0..precision - 1) |_| w.c('0');
                w.c('1');
            }
        } else {
            w.c('0');
            if (precision > 0) {
                w.c('.');
                for (0..precision) |_| w.c('0');
            }
        }
        return buf[0..w.p];
    }
    const K: usize = @intCast(ki);
    var rbuf: [800]u8 = undefined;
    const bump = roundDigits(dec.d, K, &rbuf);
    const x = dec.x + @as(i64, @intCast(bump));
    const ksz: i64 = @intCast(K);

    // Emit positions x..0 (integer) then -1..-precision (fraction); digit at
    // position pos is rbuf[x-pos] when that index is in [0,K), else '0'.
    if (x < 0) {
        w.c('0');
    } else {
        var pos: i64 = x;
        while (pos >= 0) : (pos -= 1) {
            const idx = x - pos;
            w.c(if (idx >= 0 and idx < ksz) rbuf[@intCast(idx)] else '0');
        }
    }
    if (precision > 0) {
        w.c('.');
        var pos: i64 = -1;
        const lo: i64 = -@as(i64, @intCast(precision));
        while (pos >= lo) : (pos -= 1) {
            const idx = x - pos;
            w.c(if (idx >= 0 and idx < ksz) rbuf[@intCast(idx)] else '0');
        }
    }
    return buf[0..w.p];
}

/// C `%<width>.<P>g/G` for a finite f64 (the softmenus %5.G plot-zoom label).
/// Reuses the exact %e/%f engines: pick sci vs fixed by the rounded exponent,
/// strip trailing zeros (no `#`), apply case, right-justify to width with
/// spaces. `precision` is the raw %g precision (0 -> effective 1).
pub fn fmtGBuf(buf: []u8, width: usize, precision: usize, upper: bool, value: f64) []u8 {
    const P = if (precision == 0) 1 else precision;
    var tmp: [800]u8 = undefined;
    var body: [800]u8 = undefined;
    var blen: usize = 0;

    // Exponent X after rounding to P significant digits (via the exact %e).
    const e = fmtExpBuf(&tmp, P - 1, value);
    const epos = std.mem.indexOfScalar(u8, e, 'e').?;
    const esign: i64 = if (e[epos + 1] == '-') -1 else 1;
    var x: i64 = 0;
    for (e[epos + 2 ..]) |ch| x = x * 10 + @as(i64, ch - '0');
    x *= esign;

    if (x >= -4 and x < @as(i64, @intCast(P))) {
        const fp: usize = @intCast(@as(i64, @intCast(P)) - 1 - x);
        const fr = fmtFixedBuf(body[0..], fp, value);
        blen = fr.len;
    } else {
        @memcpy(body[0..e.len], e);
        blen = e.len;
    }

    // Strip trailing zeros in the mantissa (keep any exponent tail).
    var s = body[0..blen];
    const ei = std.mem.indexOfScalar(u8, s, 'e');
    const mant_end = ei orelse s.len;
    if (std.mem.indexOfScalar(u8, s[0..mant_end], '.') != null) {
        var end = mant_end;
        while (end > 0 and s[end - 1] == '0') end -= 1;
        if (end > 0 and s[end - 1] == '.') end -= 1;
        if (ei) |j| {
            const tail_len = s.len - j;
            std.mem.copyForwards(u8, s[end .. end + tail_len], s[j..]);
            s = s[0 .. end + tail_len];
        } else {
            s = s[0..end];
        }
    }

    if (upper) {
        for (s) |*ch| {
            if (ch.* == 'e') ch.* = 'E';
        }
    }

    var pos: usize = 0;
    if (s.len < width) {
        for (0..width - s.len) |_| {
            buf[pos] = ' ';
            pos += 1;
        }
    }
    @memcpy(buf[pos..][0..s.len], s);
    pos += s.len;
    return buf[0..pos];
}
