// SPDX-License-Identifier: GPL-3.0-only
//
// Statistical-distribution parity harness driver. It runs the ported Zig
// distribution owners against independent high-precision golden values, using
// the real decNumber library (linked) through distribution_fake_runtime for the
// register/UI surface. A pass means the Zig owner reproduces the mathematical
// result to >= ~30 significant digits.
//
// The harness is bootstrapped on exponential -- already verified by the 9530
// testSuite -- to prove the pattern; pareto/uniform (which the testSuite cannot
// reach) are then added the same way.

const std = @import("std");
const fake = @import("distribution_fake_runtime.zig");
const exponential = @import("exponential_owner");

const REGISTER_X: i16 = 100;
const REGISTER_R: i16 = 116;

const DistFn = *const fn (u16) void;

var failures: u32 = 0;

fn check(name: []const u8, golden: [*:0]const u8) void {
    if (fake.z47_distribution_parity_matches(REGISTER_X, golden)) return;
    failures += 1;
    std.debug.print("  FAIL {s}: golden = {s}\n", .{ name, std.mem.span(golden) });
    fake.z47_distribution_parity_print(REGISTER_X);
}

// Run fn with X=x_str (and R=r_str), then compare register X to golden.
fn case2(name: []const u8, f: DistFn, x_str: [*:0]const u8, r_str: [*:0]const u8, golden: [*:0]const u8) void {
    fake.z47_distribution_parity_reset();
    fake.z47_distribution_parity_set_register(REGISTER_X, x_str);
    fake.z47_distribution_parity_set_register(REGISTER_R, r_str);
    f(0);
    check(name, golden);
}

pub fn main() void {
    fake.z47_distribution_parity_init();

    // Exponential, lambda = 1.
    // PDF(x)=e^-x, CDF(x)=1-e^-x, CDFu(x)=e^-x, QF(p)=-ln(1-p).
    case2("expP(1,1)", &exponential.exponentialP, "1", "1", "0.367879441171442321595523770161460867");
    case2("expP(2,1)", &exponential.exponentialP, "2", "1", "0.135335283236612691893999494972484403");
    case2("expL(1,1)", &exponential.exponentialL, "1", "1", "0.632120558828557678404476229838539133");
    case2("expL(2,1)", &exponential.exponentialL, "2", "1", "0.864664716763387308106000505027515597");
    case2("expR(1,1)", &exponential.exponentialR, "1", "1", "0.367879441171442321595523770161460867");
    case2("expR(2,1)", &exponential.exponentialR, "2", "1", "0.135335283236612691893999494972484403");
    // PDF with lambda = 2 at x=1: 2*e^-2.
    case2("expP(1,2)", &exponential.exponentialP, "1", "2", "0.270670566473225383787998989944968807");
    // CDF with lambda = 2 at x=0.5: 1-e^-1.
    case2("expL(0.5,2)", &exponential.exponentialL, "0.5", "2", "0.632120558828557678404476229838539133");
    // QF (inverse): p=0.5, lambda=1 -> ln(2); p=0.5, lambda=2 -> ln(2)/2.
    case2("expI(0.5,1)", &exponential.exponentialI, "0.5", "1", "0.693147180559945309417232121458176568");
    case2("expI(0.5,2)", &exponential.exponentialI, "0.5", "2", "0.346573590279972654708616060729088284");

    if (failures == 0) {
        std.debug.print("distribution parity: all cases passed\n", .{});
    } else {
        std.debug.print("distribution parity: {d} FAILURES\n", .{failures});
        std.process.exit(1);
    }
}
