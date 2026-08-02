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
const owners = @import("dist_owners");
const exponential = owners.exponential;
const pareto = owners.pareto;
const uniform = owners.uniform;
const gev = owners.gev;

const REGISTER_X: i16 = 100;
const REGISTER_M: i16 = 112;
const REGISTER_N: i16 = 113;
const REGISTER_Q: i16 = 115;
const REGISTER_R: i16 = 116;
const REGISTER_S: i16 = 117;

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

// Uniform: X plus low (REGISTER_M) and high (REGISTER_N); `discrete` is the fn arg.
fn caseU(name: []const u8, f: DistFn, discrete: u16, x: [*:0]const u8, low: [*:0]const u8, high: [*:0]const u8, golden: [*:0]const u8) void {
    fake.z47_distribution_parity_reset();
    fake.z47_distribution_parity_set_register(REGISTER_X, x);
    fake.z47_distribution_parity_set_register(REGISTER_M, low);
    fake.z47_distribution_parity_set_register(REGISTER_N, high);
    f(discrete);
    check(name, golden);
}

// GEV: X plus mu (REGISTER_M), sigma (REGISTER_S) and xi (REGISTER_Q).
fn caseG(name: []const u8, f: DistFn, x: [*:0]const u8, mu: [*:0]const u8, sigma: [*:0]const u8, xi: [*:0]const u8, golden: [*:0]const u8) void {
    fake.z47_distribution_parity_reset();
    fake.z47_distribution_parity_set_register(REGISTER_X, x);
    fake.z47_distribution_parity_set_register(REGISTER_M, mu);
    fake.z47_distribution_parity_set_register(REGISTER_S, sigma);
    fake.z47_distribution_parity_set_register(REGISTER_Q, xi);
    f(0);
    check(name, golden);
}

// Type I Pareto: X plus sigma (REGISTER_S) and alpha (REGISTER_Q).
fn caseP(name: []const u8, f: DistFn, x: [*:0]const u8, sigma: [*:0]const u8, alpha: [*:0]const u8, golden: [*:0]const u8) void {
    fake.z47_distribution_parity_reset();
    fake.z47_distribution_parity_set_register(REGISTER_X, x);
    fake.z47_distribution_parity_set_register(REGISTER_S, sigma);
    fake.z47_distribution_parity_set_register(REGISTER_Q, alpha);
    f(0);
    check(name, golden);
}

// Type II Pareto: X plus mu (REGISTER_M), sigma (REGISTER_S) and alpha (REGISTER_Q).
fn caseP2(name: []const u8, f: DistFn, x: [*:0]const u8, mu: [*:0]const u8, sigma: [*:0]const u8, alpha: [*:0]const u8, golden: [*:0]const u8) void {
    fake.z47_distribution_parity_reset();
    fake.z47_distribution_parity_set_register(REGISTER_X, x);
    fake.z47_distribution_parity_set_register(REGISTER_M, mu);
    fake.z47_distribution_parity_set_register(REGISTER_S, sigma);
    fake.z47_distribution_parity_set_register(REGISTER_Q, alpha);
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

    // Type I Pareto (scale sigma=2, shape alpha=1.5) at x=5; QF at p=0.5.
    caseP("paretoP", &pareto.paretoP, "5", "2", "1.5", "0.075894663844041103967973445066385245");
    caseP("paretoL", &pareto.paretoL, "5", "2", "1.5", "0.747017787186529653440088516445382517");
    caseP("paretoU", &pareto.paretoU, "5", "2", "1.5", "0.252982212813470346559911483554617483");
    caseP("paretoI", &pareto.paretoI, "0.5", "2", "1.5", "3.17480210393639894950341127854461652");
    // Type II GPD (mu=1, sigma=3, alpha=1.5) at x=5; QF at p=0.6.
    caseP2("pareto2P", &pareto.pareto2P, "5", "1", "3", "1.5", "0.060121255473181574430455429655323727");
    caseP2("pareto2L", &pareto.pareto2L, "5", "1", "3", "1.5", "0.719434141125152652657874661608489276");
    caseP2("pareto2U", &pareto.pareto2U, "5", "1", "3", "1.5", "0.280565858874847347342125338391510724");
    caseP2("pareto2I", &pareto.pareto2I, "0.6", "1", "3", "1.5", "3.52604724796057990866973425036971083");

    // Continuous Uniform on [2, 7] (discrete = 0).
    caseU("uniformP", &uniform.uniformP, 0, "4", "2", "7", "0.2");
    caseU("uniformL", &uniform.uniformL, 0, "4", "2", "7", "0.4");
    caseU("uniformU", &uniform.uniformU, 0, "4", "2", "7", "0.6");
    // fnUniformI always applies the discrete-style quantile floor((1-p)*low +
    // p*(high+1)); it does not branch on `discrete`. p=0.3 -> floor(3.8) = 3.
    caseU("uniformI", &uniform.uniformI, 0, "0.3", "2", "7", "3");
    // p == 1 hits the realCopy(high) boundary branch -> high (= 7).
    caseU("uniformI-unity", &uniform.uniformI, 0, "1", "2", "7", "7");
    caseU("uniformP-oob", &uniform.uniformP, 0, "10", "2", "7", "0"); // x above high -> 0
    caseU("uniformL-below", &uniform.uniformL, 0, "0", "2", "7", "0"); // x below low -> 0
    caseU("uniformL-above", &uniform.uniformL, 0, "10", "2", "7", "1"); // x above high -> 1
    // Discrete Uniform on integers [1, 6] (discrete = 1).
    caseU("uniformP-d", &uniform.uniformP, 1, "3", "1", "6", "0.166666666666666666666666666666666667");
    caseU("uniformL-d", &uniform.uniformL, 1, "3", "1", "6", "0.5");
    caseU("uniformU-d", &uniform.uniformU, 1, "3", "1", "6", "0.666666666666666666666666666666666667");
    caseU("uniformI-d", &uniform.uniformI, 1, "0.5", "1", "6", "4");

    // GEV, xi = 0.5 (mu=0, sigma=1) at x=2 -> t = 0.25; QF round-trips p=e^-0.25.
    // The PDF reproduces upstream's t^(t+1) exponent (its comment says t^(xi+1)).
    caseG("gevL", &gev.gevL, "2", "0", "1", "0.5", "0.778800783071404868245170266978320647");
    caseG("gevR", &gev.gevR, "2", "0", "1", "0.5", "0.221199216928595131754829733021679353");
    caseG("gevP", &gev.gevP, "2", "0", "1", "0.5", "0.137673828725795936903995265687411962");
    caseG("gevI", &gev.gevI, "0.778800783071404868245170266978320647", "0", "1", "0.5", "2");
    // GEV, xi = 0 (Gumbel) at x=1 -> t = e^-1; exercises the realFMA branch.
    caseG("gevL-gumbel", &gev.gevL, "1", "0", "1", "0", "0.692200627555346353865421997182789761");
    caseG("gevP-gumbel", &gev.gevP, "1", "0", "1", "0", "0.176266384070865029614622604509631273");
    caseG("gevI-gumbel", &gev.gevI, "0.692200627555346353865421997182789761", "0", "1", "0", "1");

    if (failures == 0) {
        std.debug.print("distribution parity: all cases passed\n", .{});
    } else {
        std.debug.print("distribution parity: {d} FAILURES\n", .{failures});
        std.process.exit(1);
    }
}
