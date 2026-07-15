// SPDX-License-Identifier: GPL-3.0-only
//! Zig owner for the z47_math_wrappers_report_* domain-error reporters; a
//! parity-only C copy lives at
//! zig_build/tests/math_wrappers/math_wrappers_runtime_helpers.c. Message
//! strings are byte-for-byte the upstream ones, including the C47 font glyph
//! escapes (src/c47/fonts.h).

const builtin = @import("builtin");
const runtime = @import("runtime.zig");

const std_plus_minus = "\x80\xb1"; // STD_PLUS_MINUS
const std_infinity = "\xa2\x1e"; // STD_INFINITY
const std_degree = "\x80\xb0"; // STD_DEGREE

fn reportDomainError(comptime message1: [*:0]const u8, comptime message2: ?[*:0]const u8, comptime message3: ?[*:0]const u8) linksection(runtime.code_section) void {
    runtime.displayCalcErrorMessage(runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
    if (runtime.extra_info_on_calc_error) {
        runtime.moreInfoOnError(message1, message2, message3, null);
    }
}

pub export fn z47_math_wrappers_report_sinc_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function sincReal:", "cannot divide a real34 by " ++ std_plus_minus ++ std_infinity ++ " when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_sincpi_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function sincpiReal:", "cannot divide a real34 by " ++ std_plus_minus ++ std_infinity ++ " when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_exp_m1_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function expM1Real:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of exp when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_ln_p1_real_zero_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function lnP1Real:", "cannot calculate Ln(0) in Ln(1 + x)", null);
}

pub export fn z47_math_wrappers_report_ln_p1_real_infinite_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function lnP1Real:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of ln(x+1) when flag SPCRES is not set", null);
}

pub export fn z47_math_wrappers_report_ln_p1_real_negative_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function lnP1Real:", "cannot calculate Ln of a negative number when CPXRES is not set!", null);
}

pub export fn z47_math_wrappers_report_ln_p1_cplx_zero_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function lnP1Cplx:", "cannot calculate Ln(0) in Ln(1 + x)", null);
}

pub export fn z47_math_wrappers_report_exp_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function expReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of exp when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_arcsin_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arcsinReal:", "|X| > 1", "and CPXRES is not set!");
}

pub export fn z47_math_wrappers_report_arccos_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arccosReal:", "|X| > 1", "and CPXRES is not set!");
}

pub export fn z47_math_wrappers_report_arctan_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arctanReal:", "X = " ++ std_plus_minus ++ std_infinity, null);
}

pub export fn z47_math_wrappers_report_arccosh_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arccoshReal:", "X < 1", "and CPXRES is not set!");
}

pub export fn z47_math_wrappers_report_arctanh_real_positive_one_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arctanhReal:", "X = 1", "and DANGER flag is not set!");
}

pub export fn z47_math_wrappers_report_arctanh_real_negative_one_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arctanhReal:", "X = -1", "and DANGER flag is not set!");
}

pub export fn z47_math_wrappers_report_arctanh_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function arctanhReal:", "|X| > 1", "and CPXRES is not set!");
}

pub export fn z47_math_wrappers_report_int_pow_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function intPowReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of 10^x when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_eulers_formula_complex_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function eulersFormulaCplx:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as real or imag X input when flag SPCRES is not set", null);
}

pub export fn z47_math_wrappers_report_eulers_formula_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function eulersFormulaReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input when flag SPCRES is not set", null);
}

pub export fn z47_math_wrappers_report_sign_real_nan_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function signReal:", "cannot use NaN as X input of SIGN", null);
}

pub export fn z47_math_wrappers_report_invert_real_divide_by_zero_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function invertReal:", "cannot divide a real by 0", null);
}

pub export fn z47_math_wrappers_report_sinh_cosh_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function sinhCoshReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of sinh when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_tanh_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function tanhReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of tanh when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_square_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function squareReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of curt when flag D is not set", null);
}

pub export fn z47_math_wrappers_report_tan_real_pole_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function tanReal:", "X = " ++ std_plus_minus ++ "90" ++ std_degree, null);
}

pub export fn z47_math_wrappers_report_cube_real_domain_error() linksection(runtime.code_section) callconv(.c) void {
    reportDomainError("In function cubeReal:", "cannot use " ++ std_plus_minus ++ std_infinity ++ " as X input of curt when flag D is not set", null);
}
