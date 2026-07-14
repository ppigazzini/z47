// SPDX-License-Identifier: GPL-3.0-only
const abi = @import("abi");
const consts = abi.constants;
const const__1 = consts.const__1;
//
// Zig owner for src/c47/mathematics/ortho_polynom.c: orthogonal polynomials
// (Hermite He/H, Laguerre L / L_alpha, Legendre P, Chebyshev T / U). Faithful
// line-by-line translation; covered by hermite.txt / hermite_p.txt /
// laguerre.txt / laguerre_alpha.txt / legendre.txt / chebyshev_t.txt /
// chebyshev_u.txt. The static getOrthoPolyParam helper stays private; the
// fnHermite/... commands and fnOrthoPoly are exported with C linkage. The
// SAVE_SPACE_DM42_12ORTHO gate is dead on every z47 build, so the bodies are
// ported unconditionally. The EXTRA_INFO_ON_CALC_ERROR hints become fixed
// moreInfoOnError strings (no-op under TESTSUITE/DMCP). WP34S_OrthoPoly is the
// Zig-ported owner in math_wp34s.zig (extern'd here). The ORTHOPOLY_*
// kind values are verified against defines.h (H=0, HE=1, L=2, L_ALPHA=3,
// LEGENDRE_P=4, CHEBYSHEV_T=5, CHEBYSHEV_U=6).

const runtime = @import("../dispatch/command_wrappers_runtime.zig");
const math_comparison_reals = @import("../compare/comparison_reals.zig");
const math_wp34s = @import("wp34s.zig");
const real_t = runtime.real_t;
const realContext_t = runtime.realContext_t;
const calcRegister_t = runtime.calcRegister_t;

const REGISTER_X = runtime.REGISTER_X;
const REGISTER_Y = runtime.REGISTER_Y;
const REGISTER_Z = runtime.REGISTER_Z;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const amNone = runtime.amNone;

const NOPARAM: u16 = 9876;

const ORTHOPOLY_HERMITE_H: u16 = 0;
const ORTHOPOLY_HERMITE_HE: u16 = 1;
const ORTHOPOLY_LAGUERRE_L: u16 = 2;
const ORTHOPOLY_LAGUERRE_L_ALPHA: u16 = 3;
const ORTHOPOLY_LEGENDRE_P: u16 = 4;
const ORTHOPOLY_CHEBYSHEV_T: u16 = 5;
const ORTHOPOLY_CHEBYSHEV_U: u16 = 6;

const getRegisterAsReal = runtime.getRegisterAsReal;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const realSetZero = runtime.realSetZero;
const realIsSpecial = runtime.realIsSpecial;
const realIsNegative = runtime.realIsNegative;
const realIsAnInteger = runtime.realIsAnInteger;
const convertRealToResultRegister = runtime.convertRealToResultRegister;
const fnDropY = runtime.fnDropY;
const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;

// realCompareLessEqual is not in runtime; extern it.

// WP34S_OrthoPoly is the Zig-ported owner in math_wp34s.zig.

extern var ctxtReal39: realContext_t;

// Blob constants.
const cstR = abi.constants.cstRAligned;

fn getOrthoPolyParam(regist: calcRegister_t, val: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool {
    _ = realContext;
    if (!getRegisterAsReal(regist, val)) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);
        moreInfoOnError("In function getOrthoPolyParam:", "Incompatible type for orthogonal polynomial.", null, null);
        return false;
    }
    return true;
}

pub export fn fnOrthoPoly(kind: u16) linksection(runtime.code_section) callconv(.c) void {
    var x: real_t = undefined;
    var y: real_t = undefined;
    var z: real_t = undefined;
    var ans: real_t = undefined;

    if (!saveLastX()) {
        return;
    }
    if (getOrthoPolyParam(REGISTER_X, &x, &ctxtReal39) and getOrthoPolyParam(REGISTER_Y, &y, &ctxtReal39)) {
        realSetZero(&z);
        if ((kind != ORTHOPOLY_LAGUERRE_L_ALPHA) or getOrthoPolyParam(REGISTER_Z, &z, &ctxtReal39)) {
            if (realIsSpecial(&y) or realIsNegative(&y) or (!realIsAnInteger(&y)) or math_comparison_reals.realCompareLessEqual(&z, const__1())) {
                displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
                moreInfoOnError("In function fnOrthoPoly:", "Y must be a nonnegative integer.", if (kind == ORTHOPOLY_LAGUERRE_L_ALPHA) "In addition, Z must be greater than -1." else null, null);
            } else {
                math_wp34s.WP34S_OrthoPoly(kind, &x, &y, &z, &ans, &ctxtReal39);
                convertRealToResultRegister(&ans, REGISTER_X, amNone);
                if (kind == ORTHOPOLY_LAGUERRE_L_ALPHA) {
                    fnDropY(NOPARAM);
                }
            }
        }
    }
    adjustResult(REGISTER_X, true, false, REGISTER_X, REGISTER_Y, -1);
}

pub export fn fnHermite(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_HERMITE_HE);
}
pub export fn fnHermiteP(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_HERMITE_H);
}
pub export fn fnLaguerre(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_LAGUERRE_L);
}
pub export fn fnLaguerreAlpha(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_LAGUERRE_L_ALPHA);
}
pub export fn fnLegendre(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_LEGENDRE_P);
}
pub export fn fnChebyshevT(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_CHEBYSHEV_T);
}
pub export fn fnChebyshevU(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    fnOrthoPoly(ORTHOPOLY_CHEBYSHEV_U);
}
