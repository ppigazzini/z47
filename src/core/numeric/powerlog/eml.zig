// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/eml.c: EML, e^Y - Ln X, real and complex.
// Faithful line-by-line translation preserving the exact order of every real_t
// operation (eml.txt checks results to the last digit). Exports fnEML with C
// linkage; emlReal and emlCplx stay private. OPTION_EML is defined for every
// target built here, so the body is unconditional -- the C compiles the whole file
// out without it, and items.c then binds the item to itemToBeCoded instead.

const runtime = @import("../command_wrappers/runtime.zig");
const math_real_predicates = @import("../compare/real_predicates.zig");
const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;

const realIsInfinite = runtime.realIsInfinite;
const realIsNegative = runtime.realIsNegative;
const realIsPositive = math_real_predicates.realIsPositive;
const realIsZero = runtime.realIsZero;
const realSetNaN = runtime.realSetNaN;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY

const realSetPlusInfinity = runtime.realSetPlusInfinity;
const realSetMinusInfinity = runtime.realSetMinusInfinity;

fn cpxresSet() bool {
    return runtime.getFlag(@intCast(runtime.FLAG_CPXRES));
}

fn spcresSet() bool {
    return runtime.getSystemFlag(runtime.FLAG_SPCRES);
}

fn reportDomainError(function_name: [*:0]const u8, message: [*:0]const u8) void {
    runtime.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(function_name, message, null, null);
    }
}

/// e^Y(real34) - Ln X(real34) ==> X(real34)
fn emlReal() callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var exp: real_t = undefined;
    var ln: real_t = undefined;

    if (!runtime.getRegisterAsReal(REGISTER_X, &x) or !runtime.getRegisterAsReal(REGISTER_Y, &y)) {
        return;
    }

    if (realIsNegative(&x) and cpxresSet()) {
        emlCplx();
        return;
    }

    // e^Y domain and special value checks
    if (realIsInfinite(&y) and !spcresSet()) {
        reportDomainError("In function emlReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as Y input of eml when flag SPCRES is not set");
        return;
    }

    // Ln X domain and special value checks
    if (realIsZero(&x)) {
        if (spcresSet()) {
            realSetPlusInfinity(&x);
        } else {
            reportDomainError("In function emlReal:", "cannot calculate Ln(0)");
            return;
        }
    } else if (realIsInfinite(&x)) {
        if (!spcresSet()) {
            reportDomainError("In function emlReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of eml when flag SPCRES is not set");
            return;
        } else if (realIsPositive(&x)) {
            runtime.realExp(&y, &exp, &runtime.ctxtReal39);
            if (realIsInfinite(&exp)) {
                realSetNaN(&x);
            } else {
                realSetMinusInfinity(&x);
            }
        } else if (cpxresSet()) {
            emlCplx();
            return;
        }
    } else {
        runtime.realExp(&y, &exp, &runtime.ctxtReal75);
        runtime.WP34S_Ln(&x, &ln, &runtime.ctxtReal75);
        runtime.realSubtract(&exp, &ln, &x, &runtime.ctxtReal75);
    }
    runtime.convertRealToResultRegister(&x, REGISTER_X, runtime.amNone);
}

/// e^Y(complex34) - Ln X(complex34) ==> X(complex34)
fn emlCplx() callconv(.c) void {
    var x: cplx_t = undefined;
    var y: cplx_t = undefined;
    var exp: cplx_t = undefined;
    var ln: cplx_t = undefined;

    if (!runtime.getRegisterAsComplex(REGISTER_Y, &y) or !runtime.getRegisterAsComplex(REGISTER_X, &x)) {
        return;
    }

    if (realIsZero(&x.Real) and realIsZero(&x.Imag) and !spcresSet()) {
        reportDomainError("In function emlCplx:", "cannot calculate eml(0)");
        return;
    }

    runtime.expComplex(&y, &exp, &runtime.ctxtReal75);
    runtime.lnComplex(&x, &ln, &runtime.ctxtReal75);
    runtime.subComplex(&exp, &ln, &x, &runtime.ctxtReal75);
    runtime.convertComplexToResultRegister(&x, REGISTER_X);
}

/// regX ==> regL and e^regY - Ln(regX) ==> regX. Drops Y, enables stack lift and
/// refreshes the stack.
pub export fn fnEML(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    runtime.processRealComplexDyadicFunction(&emlReal, &emlCplx);
}
