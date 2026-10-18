// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/distributions/normal.c: the standard, parametrised and
// log-normal distribution commands and the WP34S kernels of the standard normal
// behind them, which the Student t, Poisson and hypergeometric owners also
// call. The entry points load register X, the location in M and the
// scale in S through WP34S_CheckDistributionParameters and keep their own
// bodies, since the normal has no row in the descriptor table. A log-normal
// argument whose logarithm cancels the location by more than 32 digits, and a
// location-scale quantile that cancels as deeply, are recomputed at 159 digits.
// Tagged linksection(dr.code_section) so the code runs from QSPI on the
// flash-limited old_hw DM42.

const dr = @import("distribution_runtime.zig");
pub const real_t = dr.real_t;
pub const realContext_t = dr.realContext_t;

pub const NormalType = enum(u16) { std_normal = 0, param_normal = 1, log_normal = 2 };

// normalCheckDomain: a finite location and a positive finite scale, unless the
// standard normal asked.
fn checkDomain(registers_valid: bool, x: *real_t, first: ?*real_t, second: ?*real_t, third: ?*real_t, parameter: u16) linksection(dr.code_section) callconv(.c) bool {
    _ = x;
    _ = third;
    if (!registers_valid) {
        return false;
    }

    if (parameter == @backingInt(NormalType.std_normal)) {
        return true;
    }
    const i = first.?;
    const j = second.?;

    if (dr.realIsSpecial(i) or dr.realIsSpecial(j) or dr.realIsZero(j) or dr.realIsNegative(j)) {
        dr.displayDomainErrorMessage(dr.ERROR_INVALID_DISTRIBUTION_PARAM, dr.ERR_REGISTER_LINE);
        dr.moreInfoOnError("In function normalCheckDomain:", "parameters must be finite and \x83\xc3 > 0", null, null);
        return false;
    }
    return true;
}

fn normalParameters(t: NormalType, x: *real_t, i: *real_t, j: *real_t) linksection(dr.code_section) bool {
    const mu: ?*real_t = if (t == .std_normal) null else i;
    const sigma: ?*real_t = if (t == .std_normal) null else j;

    return dr.WP34S_CheckDistributionParameters(x, dr.REGISTER_M, mu, dr.REGISTER_S, sigma, 0, null, @backingInt(t), checkDomain);
}

// The standardised log-normal argument; true when its logarithm cancels the
// location so deeply that the extended path has to recompute it.
fn normalLogTransform(x: *const real_t, mu: *const real_t, sigma: *const real_t, standard: *real_t, original: *real_t) linksection(dr.code_section) bool {
    var logarithm: real_t = undefined;

    dr.realCopy(x, original);
    dr.WP34S_Ln(original, &logarithm, &dr.ctxtReal75);
    dr.realSubtract(&logarithm, mu, standard, &dr.ctxtReal75);
    if (dr.WP34S_HasCancellation(&logarithm, mu, standard, 32)) {
        return true;
    }
    dr.realDivide(standard, sigma, standard, &dr.ctxtReal75);
    return false;
}

pub fn normalP(t: NormalType) linksection(dr.code_section) void {
    var val: real_t = undefined;
    var alval: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var ans: real_t = undefined;
    const stdn = t == .std_normal;
    const logn = t == .log_normal;
    const calculation_context: *realContext_t = if (logn) &dr.ctxtReal75 else &dr.ctxtReal51;
    var extended = false;

    if (normalParameters(t, &val, &mu, &sigma)) {
        if (logn and dr.realIsZero(&val)) {
            dr.setZero(&ans);
        } else if (logn and dr.realIsNegative(&val)) {
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&ans);
            } else {
                dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
                dr.moreInfoOnError("In function normalP:", "cannot calculate for x < 0", null, null);
                return;
            }
        } else {
            if (!stdn) {
                if (logn) {
                    extended = normalLogTransform(&val, &mu, &sigma, &val, &alval);
                } else {
                    dr.realSubtract(&val, &mu, &val, calculation_context);
                    dr.realDivide(&val, &sigma, &val, calculation_context);
                }
            }
            if (extended) {
                normalLogPdfExtended(&alval, &mu, &sigma, &ans);
            } else {
                wp34sPdfQ(&val, &ans, calculation_context);
                if (!stdn) {
                    dr.realDivide(&ans, &sigma, &ans, calculation_context);
                }
                if (logn) {
                    dr.realDivide(&ans, &alval, &ans, calculation_context);
                }
                if (!dr.realIsSpecial(&val) and dr.realIsZero(&ans)) {
                    dr.realNextToward(&ans, dr.const1(), &ans, calculation_context);
                }
            }
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// normalL and normalR: one body, selected by `upper`, the only difference
// between the two upstream functions.
fn normalCdfCommand(t: NormalType, upper: bool) linksection(dr.code_section) void {
    var val: real_t = undefined;
    var original: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var ans: real_t = undefined;
    const stdn = t == .std_normal;
    const logn = t == .log_normal;
    const calculation_context: *realContext_t = if (logn) &dr.ctxtReal75 else &dr.ctxtReal51;
    var extended = false;

    if (normalParameters(t, &val, &mu, &sigma)) {
        if (logn and dr.realIsZero(&val)) {
            if (upper) {
                dr.setOne(&ans);
            } else {
                dr.setZero(&ans);
            }
        } else if (logn and dr.realIsNegative(&val)) {
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&ans);
            } else {
                dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
                dr.moreInfoOnError(if (upper) "In function normalR:" else "In function normalL:", "cannot calculate for x < 0", null, null);
                return;
            }
        } else {
            if (!stdn) {
                if (logn) {
                    extended = normalLogTransform(&val, &mu, &sigma, &val, &original);
                } else {
                    dr.realSubtract(&val, &mu, &val, calculation_context);
                    dr.realDivide(&val, &sigma, &val, calculation_context);
                }
            }
            if (extended) {
                normalLogCdfExtended(&original, &mu, &sigma, &ans, upper);
            } else if (upper) {
                wp34sCdfuQ(&val, &ans, calculation_context);
            } else {
                wp34sCdfQ(&val, &ans, calculation_context);
            }
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

pub fn normalL(t: NormalType) linksection(dr.code_section) void {
    normalCdfCommand(t, false);
}

pub fn normalR(t: NormalType) linksection(dr.code_section) void {
    normalCdfCommand(t, true);
}

pub fn normalI(t: NormalType) linksection(dr.code_section) void {
    var val: real_t = undefined;
    var mu: real_t = undefined;
    var sigma: real_t = undefined;
    var ans: real_t = undefined;
    var quantile: real_t = undefined;
    var scaled: real_t = undefined;
    const stdn = t == .std_normal;
    const logn = t == .log_normal;
    const calculation_context: *realContext_t = if (stdn) &dr.ctxtReal39 else &dr.ctxtReal75;
    var extended = false;

    if (normalParameters(t, &val, &mu, &sigma)) {
        if (dr.realIsNaN(&val) or dr.realCompareLessEqual(&val, dr.const0()) or dr.realCompareGreaterEqual(&val, dr.const1())) {
            if (dr.getSystemFlag(dr.FLAG_SPCRES)) {
                dr.setNaN(&ans);
                dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
            } else {
                dr.displayDomainErrorMessage(dr.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, dr.ERR_REGISTER_LINE);
                dr.moreInfoOnError("In function normalI:", "the argument must be 0 < x < 1", null, null);
            }
            return;
        }
        wp34sQfQ(&val, &quantile, calculation_context);
        if (!stdn) {
            dr.realMultiply(&quantile, &sigma, &scaled, calculation_context);
            dr.realFMA(&quantile, &sigma, &mu, &ans, calculation_context);
            if (dr.WP34S_HasCancellation(&mu, &scaled, &ans, 32)) {
                normalQuantileResultExtended(&val, &quantile, &mu, &sigma, &ans, logn);
                extended = true;
            }
            if (logn and !extended) {
                dr.realExponential(&ans, &ans, calculation_context);
                if (!dr.realIsSpecial(&mu) and !dr.realIsSpecial(&sigma)) {
                    if (dr.realIsZero(&ans)) {
                        dr.realNextToward(&ans, dr.const1(), &ans, calculation_context);
                    } else if (dr.realIsInfinite(&ans)) {
                        dr.realNextToward(&ans, dr.const0(), &ans, calculation_context);
                    }
                }
            }
        } else {
            dr.realCopy(&quantile, &ans);
        }
        dr.convertRealToResultRegister(&ans, dr.REGISTER_X, dr.amNone);
        dr.adjustResult(dr.REGISTER_X, false, false, dr.REGISTER_X, -1, -1);
    }
}

// A central normal probability from its alternating power series, added to or
// taken from `offset`.
fn normalCentralCdf(x: *const real_t, offset: *const real_t, res: *real_t, real_context: *realContext_t, upper: bool) linksection(dr.code_section) void {
    var square_storage: dr.Real159 = undefined;
    var term_storage: dr.Real159 = undefined;
    var sum_storage: dr.Real159 = undefined;
    var previous_storage: dr.Real159 = undefined;
    var numerator_storage: dr.Real159 = undefined;
    var denominator_storage: dr.Real159 = undefined;
    var root_two_pi_storage: dr.Real159 = undefined;
    var delta_storage: dr.Real159 = undefined;
    const square = square_storage.ptr();
    const term = term_storage.ptr();
    const sum = sum_storage.ptr();
    const previous = previous_storage.ptr();
    const numerator = numerator_storage.ptr();
    const denominator = denominator_storage.ptr();
    const root_two_pi = root_two_pi_storage.ptr();
    const delta = delta_storage.ptr();
    const two_pi = dr.twoPiForContext(real_context);

    dr.realMultiply(x, x, square, real_context);
    dr.realMultiply(square, dr.const1on2(), square, real_context);
    dr.realChangeSign(square);
    dr.setOne(term);
    dr.setOne(sum);
    var n: i32 = 1;
    while (n < 1000) : (n += 1) {
        dr.realMultiply(term, square, term, real_context);
        dr.int32ToReal(2 * n - 1, numerator);
        dr.realMultiply(term, numerator, term, real_context);
        dr.int32ToReal(n * (2 * n + 1), denominator);
        dr.realDivide(term, denominator, term, real_context);
        dr.realCopy(sum, previous);
        dr.realAdd(sum, term, sum, real_context);
        if (dr.realEqual(sum, previous)) {
            break;
        }
    }
    dr.realMultiply(x, sum, delta, real_context);
    dr.realSquareRoot(two_pi, root_two_pi, real_context);
    dr.realDivide(delta, root_two_pi, delta, real_context);
    if (upper) {
        dr.realSubtract(offset, delta, res, real_context);
    } else {
        dr.realAdd(offset, delta, res, real_context);
    }
}

// A normal density in an extended context.
fn normalPdfExtended(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var root_two_pi_storage: dr.Real159 = undefined;
    const root_two_pi = root_two_pi_storage.ptr();

    dr.realMultiply(x, x, res, real_context);
    dr.realMultiply(res, dr.const1on2(), res, real_context);
    dr.realChangeSign(res);
    dr.realExponential(res, res, real_context);
    dr.realSquareRoot(dr.const2139TwoPi(), root_two_pi, real_context);
    dr.realDivide(res, root_two_pi, res, real_context);
    if (!dr.realIsSpecial(x) and dr.realIsZero(res)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    }
}

// The upper normal tail by a modified Lentz continued fraction.
fn normalUpperTailExtended(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var an_storage: dr.Real159 = undefined;
    var b_storage: dr.Real159 = undefined;
    var c_storage: dr.Real159 = undefined;
    var d_storage: dr.Real159 = undefined;
    var h_storage: dr.Real159 = undefined;
    var index_storage: dr.Real159 = undefined;
    var pdf_storage: dr.Real159 = undefined;
    var square_storage: dr.Real159 = undefined;
    var t_storage: dr.Real159 = undefined;
    var u_storage: dr.Real159 = undefined;
    var v_storage: dr.Real159 = undefined;
    const an = an_storage.ptr();
    const b = b_storage.ptr();
    const c = c_storage.ptr();
    const d = d_storage.ptr();
    const h = h_storage.ptr();
    const index = index_storage.ptr();
    const pdf = pdf_storage.ptr();
    const square = square_storage.ptr();
    const t = t_storage.ptr();
    const u = u_storage.ptr();
    const v = v_storage.ptr();

    dr.realMultiply(x, x, square, real_context);
    dr.realMultiply(square, dr.const1on2(), square, real_context);
    dr.realAdd(square, dr.const1on2(), b, real_context);
    dr.setPlusInfinity(c);
    dr.realDivide(dr.const1(), b, d, real_context);
    dr.realCopy(d, h);
    dr.setZero(index);
    var n: i32 = 0;
    while (n < 1000) : (n += 1) {
        dr.realAdd(index, dr.const1(), index, real_context);
        dr.realSubtract(dr.const1on2(), index, t, real_context);
        dr.realMultiply(index, t, an, real_context);
        dr.realAdd(b, dr.const2(), b, real_context);
        dr.realFMA(an, d, b, v, real_context);
        dr.realDivide(dr.const1(), v, d, real_context);
        dr.realDivide(an, c, t, real_context);
        dr.realAdd(b, t, c, real_context);
        dr.realMultiply(d, c, t, real_context);
        dr.realMultiply(h, t, u, real_context);
        if (dr.realEqual(u, h)) {
            break;
        }
        dr.realCopy(u, h);
    }
    normalPdfExtended(x, pdf, real_context);
    dr.realMultiply(pdf, x, res, real_context);
    dr.realMultiply(res, h, res, real_context);
    dr.realMultiply(res, dr.const1on2(), res, real_context);
}

// A normal probability in an extended context.
fn normalCdfExtended(x: *const real_t, res: *real_t, real_context: *realContext_t, upper: bool) linksection(dr.code_section) void {
    var abs_x_storage: dr.Real159 = undefined;
    var tail_storage: dr.Real159 = undefined;
    const abs_x = abs_x_storage.ptr();
    const tail = tail_storage.ptr();
    const negative = dr.realIsNegative(x);

    dr.realCopyAbs(x, abs_x);
    if (dr.realLessThan(abs_x, dr.const8())) {
        normalCentralCdf(x, dr.const1on2(), res, real_context, upper);
    } else {
        normalUpperTailExtended(abs_x, tail, real_context);
        if ((upper and !negative) or (!upper and negative)) {
            dr.realCopy(tail, res);
        } else {
            dr.realSubtract(dr.const1(), tail, res, real_context);
        }
    }
    if (dr.realIsZero(res)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    } else if (dr.realEqual(res, dr.const1())) {
        dr.realNextToward(res, dr.const0(), res, real_context);
    }
}

// A log-normal density after severe logarithmic cancellation.
fn normalLogPdfExtended(x: *const real_t, mu: *const real_t, sigma: *const real_t, res: *real_t) linksection(dr.code_section) void {
    var extended_result_storage: dr.Real159 = undefined;
    var standard_storage: dr.Real159 = undefined;
    const extended_result = extended_result_storage.ptr();
    const standard = standard_storage.ptr();
    var real_context: realContext_t = dr.ctxtReal75;

    real_context.digits = 159;
    real_context.status = 0;
    dr.WP34S_LnExtended(x, standard, &real_context);
    dr.realSubtract(standard, mu, standard, &real_context);
    dr.realDivide(standard, sigma, standard, &real_context);
    normalPdfExtended(standard, extended_result, &real_context);
    dr.realDivide(extended_result, sigma, extended_result, &real_context);
    dr.realDivide(extended_result, x, extended_result, &real_context);
    if (dr.realIsZero(extended_result)) {
        dr.realNextToward(extended_result, dr.const1(), extended_result, &real_context);
    }
    // Keep the source and destination at the same capacity until the value has
    // been shortened. roundToSignificantDigits copies before rounding when its
    // pointers differ, so writing a p159 source directly to a real_t would
    // overrun the latter's p75 storage.
    dr.roundToSignificantDigits(extended_result, extended_result, 34, &real_context);
    dr.realCopy(extended_result, res);
}

// A log-normal probability after severe logarithmic cancellation.
fn normalLogCdfExtended(x: *const real_t, mu: *const real_t, sigma: *const real_t, res: *real_t, upper: bool) linksection(dr.code_section) void {
    var extended_result_storage: dr.Real159 = undefined;
    var standard_storage: dr.Real159 = undefined;
    const extended_result = extended_result_storage.ptr();
    const standard = standard_storage.ptr();
    var real_context: realContext_t = dr.ctxtReal75;

    real_context.digits = 159;
    real_context.status = 0;
    dr.WP34S_LnExtended(x, standard, &real_context);
    dr.realSubtract(standard, mu, standard, &real_context);
    dr.realDivide(standard, sigma, standard, &real_context);
    normalCdfExtended(standard, extended_result, &real_context, upper);
    dr.roundToSignificantDigits(extended_result, extended_result, 34, &real_context);
    dr.realCopy(extended_result, res);
}

// A location-scale quantile after severe final cancellation.
fn normalQuantileResultExtended(probability: *const real_t, estimate: *const real_t, mu: *const real_t, sigma: *const real_t, res: *real_t, logn: bool) linksection(dr.code_section) void {
    var extended_result_storage: dr.Real159 = undefined;
    const extended_result = extended_result_storage.ptr();
    var real_context: realContext_t = dr.ctxtReal75;

    real_context.digits = 159;
    real_context.status = 0;
    normalQuantileExtended(probability, estimate, extended_result, &real_context);
    dr.realFMA(extended_result, sigma, mu, extended_result, &real_context);
    if (logn) {
        dr.realExponential(extended_result, extended_result, &real_context);
        if (dr.realIsZero(extended_result)) {
            dr.realNextToward(extended_result, dr.const1(), extended_result, &real_context);
        } else if (dr.realIsInfinite(extended_result)) {
            dr.realNextToward(extended_result, dr.const0(), extended_result, &real_context);
        }
    }
    dr.roundToSignificantDigits(extended_result, extended_result, 34, &real_context);
    dr.realCopy(extended_result, res);
}

// A normal quantile refined after severe location-scale cancellation: two
// third-order steps from the estimate at the extended context.
fn normalQuantileExtended(probability: *const real_t, estimate: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) void {
    var p_storage: dr.Real159 = undefined;
    var q_storage: dr.Real159 = undefined;
    var r_storage: dr.Real159 = undefined;
    var s_storage: dr.Real159 = undefined;
    var target_storage: dr.Real159 = undefined;
    const p = p_storage.ptr();
    const q = q_storage.ptr();
    const r = r_storage.ptr();
    const s = s_storage.ptr();
    const target = target_storage.ptr();
    const lower = dr.realCompareLessEqual(probability, dr.const1on2());

    dr.realCopyAbs(estimate, p);
    if (lower) {
        dr.realCopy(probability, target);
    } else {
        dr.realSubtract(dr.const1(), probability, target, real_context);
    }
    var n: i32 = 0;
    while (n < 2) : (n += 1) {
        if (dr.realLessThan(p, dr.const8())) {
            normalCentralCdf(p, dr.const1on2(), q, real_context, true);
        } else {
            normalUpperTailExtended(p, q, real_context);
        }
        dr.realSubtract(q, target, q, real_context);
        dr.realMultiply(p, p, r, real_context);
        dr.realMultiply(r, dr.const1on2(), r, real_context);
        dr.realChangeSign(r);
        dr.realExponential(r, r, real_context);
        dr.realSquareRoot(dr.const2139TwoPi(), s, real_context);
        dr.realDivide(r, s, r, real_context);
        dr.realDivide(q, r, q, real_context);
        dr.realMultiply(q, q, r, real_context);
        dr.realMultiply(r, q, r, real_context);
        dr.realMultiply(p, p, s, real_context);
        dr.realMultiply(s, dr.const2(), s, real_context);
        dr.realAdd(s, dr.const1(), s, real_context);
        dr.realMultiply(r, s, r, real_context);
        dr.realDivide(r, dr.const6(), r, real_context);
        dr.realMultiply(p, dr.const1on2(), s, real_context);
        dr.realMultiply(s, q, s, real_context);
        dr.realMultiply(s, q, s, real_context);
        dr.realAdd(s, r, r, real_context);
        dr.realAdd(r, q, q, real_context);
        dr.realAdd(q, p, p, real_context);
    }
    if (lower) {
        dr.realChangeSign(p);
    }
    dr.realCopy(p, res);
}

// Either standard normal probability through the complementary error function.
fn cdfQ(x: *const real_t, res: *real_t, real_context: *realContext_t, upper: bool) linksection(dr.code_section) void {
    var p: real_t = undefined;

    dr.realSquareRoot(dr.const2(), &p, real_context);
    dr.realDivide(x, &p, res, real_context);
    if (!upper) {
        dr.realChangeSign(res);
    }
    dr.WP34S_Erfc(res, res, real_context);
    dr.realMultiply(res, dr.const1on2(), res, real_context);
    if (!dr.realIsSpecial(x)) {
        if (dr.realIsZero(res)) {
            dr.realNextToward(res, dr.const1(), res, real_context);
        } else if (dr.realEqual(res, dr.const1())) {
            dr.realNextToward(res, dr.const0(), res, real_context);
        }
    }
}

pub fn wp34sPdfQ(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    const two_pi = if (real_context.digits > 39) dr.const75TwoPi() else dr.const39_2pi();

    dr.realMultiply(x, x, res, real_context);
    dr.realMultiply(res, dr.const1on2(), res, real_context);
    dr.realChangeSign(res);
    dr.realExponential(res, res, real_context);
    dr.realSquareRoot(two_pi, &p, real_context);
    dr.realDivide(res, &p, res, real_context);
    if (!dr.realIsSpecial(x) and dr.realIsZero(res)) {
        dr.realNextToward(res, dr.const1(), res, real_context);
    }
}

pub fn wp34sCdfuQ(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    cdfQ(x, res, real_context, true);
}

pub fn wp34sCdfQ(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    cdfQ(x, res, real_context, false);
}

/// WP34S_qf_q_est: a signed guess for the normal quantile of any 0 < p < 1, with
/// the smaller tail returned in resY when asked.
pub fn wp34sQfQEst(x: *const real_t, res: *real_t, res_y: ?*real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var is_small = false;

    // qf_q_int_est
    dr.realMinus(x, &p, real_context);
    dr.realAdd(&p, dr.const1(), &p, real_context);
    if (dr.realLessThan(x, &p)) {
        is_small = true;
        dr.realCopy(x, &p);
    }

    dr.realMultiply(dr.const2(), dr.const1on10(), &q, real_context);

    if (dr.realLessThan(&p, &q)) {
        dr.WP34S_Ln(&p, &q, real_context);
        dr.realMultiply(&q, dr.const2(), &q, real_context);
        dr.realChangeSign(&q);
        dr.realSubtract(&q, dr.const1(), &r, real_context);
        dr.realMultiply(&r, dr.const39_2pi(), &r, real_context);
        dr.realSquareRoot(&r, &r, real_context);
        dr.realMultiply(&r, &p, &r, real_context);
        dr.WP34S_Ln(&r, &r, real_context);
        dr.realMultiply(&r, dr.const2(), &r, real_context);
        dr.realChangeSign(&r);
        dr.realSquareRoot(&r, &r, real_context);
        dr.int32ToReal(264, &s);
        s.exponent -= 3; // s = s / 1000
        dr.realDivide(&s, &q, &q, real_context);
        dr.realAdd(&q, &r, &q, real_context);
    } else { // qf_q_mid
        dr.realMinus(&p, &q, real_context);
        dr.realAdd(&q, dr.const1on2(), &q, real_context);
        dr.realSquareRoot(dr.const39_2pi(), &r, real_context);
        dr.realMultiply(&q, &r, &q, real_context);
        dr.realMultiply(&q, &q, &r, real_context);
        dr.realMultiply(&r, &q, &r, real_context);
        dr.realDivide(&r, dr.const5(), &r, real_context);
        dr.realAdd(&q, &r, &q, real_context);
    }

    dr.realCopy(&q, res);
    if (res_y) |y| {
        dr.realCopy(&p, y);
    }
    // qf_q_signfix
    if (is_small) {
        dr.realChangeSign(res);
    }
}

pub fn wp34sQfQ(x: *const real_t, res: *real_t, real_context: *realContext_t) linksection(dr.code_section) callconv(.c) void {
    var p: real_t = undefined;
    var q: real_t = undefined;
    var r: real_t = undefined;
    var s: real_t = undefined;
    var reg0: real_t = undefined;
    var half = false;
    var loops: i32 = undefined;
    var refine = true;

    wp34sQfQEst(x, &p, &reg0, real_context);
    if (dr.realIsNegative(&p)) {
        half = true;
    }
    loops = if (real_context.digits > 39) 3 else 2;
    dr.realSetPositiveSign(&p);
    dr.realAdd(&p, dr.const1(), &q, real_context);
    dr.roundToSignificantDigits(&q, &q, 3, real_context);
    if (dr.realEqual(&q, dr.const1())) {
        loops -= 1;
        dr.realCopy(&p, &q);
        q.exponent += 16; // q = q * 1e16
        refine = dr.realGreaterThan(&q, dr.const1());
    }
    if (refine) {
        while (true) { // qf_q_refine
            if (dr.realCompareGreaterEqual(&p, dr.const1())) {
                wp34sCdfuQ(&p, &q, real_context);
                dr.realSubtract(&q, &reg0, &q, real_context);
            } else { // qf_q_small
                dr.realSubtract(dr.const1on2(), &reg0, &q, real_context); // 1/2 - reg0 is exact, so the residual (1/2 - reg0) - delta is rounded once
                normalCentralCdf(&p, &q, &q, real_context, true);
            }
            // qf_q_common
            wp34sPdfQ(&p, &r, real_context);
            dr.realDivide(&q, &r, &q, real_context);
            dr.realMultiply(&q, &q, &r, real_context);
            dr.realMultiply(&r, &q, &r, real_context);
            dr.realMultiply(&p, &p, &s, real_context);
            dr.realMultiply(&s, dr.const2(), &s, real_context);
            dr.realAdd(&s, dr.const1(), &s, real_context);
            dr.realMultiply(&r, &s, &r, real_context);
            dr.realDivide(&r, dr.const6(), &r, real_context);
            dr.realMultiply(&p, dr.const1on2(), &s, real_context);
            dr.realMultiply(&s, &q, &s, real_context);
            dr.realMultiply(&s, &q, &s, real_context);
            dr.realAdd(&s, &r, &r, real_context);
            dr.realAdd(&r, &q, &q, real_context);
            dr.realAdd(&q, &p, &p, real_context);
            loops -= 1;
            if (loops <= 0) {
                break;
            }
        }
    }
    // qf_q_out
    if (half) {
        dr.realChangeSign(&p);
    }
    dr.realCopy(&p, res);
}
