// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/slvp.c: SLVP, every root of a polynomial
// given its coefficient vector. Exports slvp.h's fnSlvp. Covered by slvp.txt.
//
// Coefficients and roots are cplx_t slots at 75 digits, the layout
// calculateEigenvalues works on. The general case builds the monic companion
// matrix and hands it to the already-Zig-owned eigensolver in matrix/eigen.zig,
// which shares this object -- upstream drops the `static` on its copy under
// OPTION_SLVP_POLY, the Zig side only needs the `pub`.
//
// OPTION_SLVP_POLY is #undef'd for some flash-limited DM42 packages, where the
// whole body compiles away and fnSlvp is an empty stub (items.zig still binds
// the symbol, and softmenus.zig strikes the item out).

const abi = @import("abi");
const consts = abi.constants;
const const_0 = consts.const_0;
const const_1 = consts.const_1;
const const75_2pi = consts.const75_2pi;

const runtime = @import("command_wrappers/runtime.zig");
const math_matrix_eigen = @import("matrix/eigen.zig");
const math_real_predicates = @import("compare/real_predicates.zig");
const math_slvc = @import("slvc.zig");

const real_t = runtime.real_t;
const cplx_t = runtime.cplx_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const realContext_t = runtime.realContext_t;
const ctxtReal34 = &runtime.ctxtReal34;
const ctxtReal39 = &runtime.ctxtReal39;
const ctxtReal75 = &runtime.ctxtReal75;

const REGISTER_X = runtime.REGISTER_X;
const ERR_REGISTER_LINE = runtime.ERR_REGISTER_LINE;
const NIM_REGISTER_LINE = runtime.REGISTER_X; // ERR_REGISTER_LINE's companion, as in slvc.zig
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN = runtime.ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN;
const ERROR_INVALID_DATA_TYPE_FOR_OP = runtime.ERROR_INVALID_DATA_TYPE_FOR_OP;
const ERROR_MATRIX_MISMATCH = runtime.ERROR_MATRIX_MISMATCH;
const ERROR_RAM_FULL = runtime.ERROR_RAM_FULL;
const ERROR_MESSAGE_LENGTH = 512; // defines.h
const STD_CROSS = "\x80\xd7"; // fonts.h
// c47.h's `extern char *errorMessage`, the shared 512-byte diagnostic buffer.
extern var errorMessage: [*:0]u8;

const displayCalcErrorMessage = runtime.displayCalcErrorMessage;
const moreInfoOnError = runtime.moreInfoOnError;
const getRegisterDataType = runtime.getRegisterDataType;
const dtReal34Matrix = runtime.dtReal34Matrix;
const dtComplex34Matrix = runtime.dtComplex34Matrix;
const linkToRealMatrixRegister = runtime.linkToRealMatrixRegister;
const linkToComplexMatrixRegister = runtime.linkToComplexMatrixRegister;
const realElems = abi.matrixRealElems;
const complexElems = abi.matrixComplexElems;
const realMatrixInit = runtime.realMatrixInit;
const complexMatrixInit = runtime.complexMatrixInit;
const realMatrixFree = runtime.realMatrixFree;
const complexMatrixFree = runtime.complexMatrixFree;
const convertReal34MatrixToReal34MatrixRegister = runtime.convertReal34MatrixToReal34MatrixRegister;
const convertComplex34MatrixToComplex34MatrixRegister = runtime.convertComplex34MatrixToComplex34MatrixRegister;
const saveLastX = runtime.saveLastX;
const adjustResult = runtime.adjustResult;
const realIsZero = math_real_predicates.realIsZero;
const realIsSpecial = math_real_predicates.realIsSpecial;
const divComplexComplex = runtime.divComplexComplex;

// The real ops all come from the shared runtime bindings; this owner adds no
// decNumber extern of its own. realCopy has no shared form: upstream's
// decNumberCopy moves the header plus only the units `digits` covers, and for
// the fixed-size Real of a 75-digit build a whole-struct assignment is the same
// value with the unread tail defined as well.
const realAdd = runtime.realAdd;
const realMultiply = runtime.realMultiply;
const realDivide = runtime.realDivide;
const realSetZero = runtime.realSetZero;
const realChangeSign = runtime.realChangeSign;
const realCompareEqual = runtime.realCompareEqual;

inline fn realCopy(source: *const real_t, destination: *real_t) void {
    destination.* = source.*;
}
inline fn realGetExponent(source: *const real_t) i32 {
    return source.digits + source.exponent - 1;
}

// REAL_SIZE_IN_BLOCKS(75) == 15 (realType.h: (10 + 2*(75/3)) bytes / 4).
const real_size_in_blocks_75: usize = 15;

// ---------------------------------------------------------------------------
// _slotIsZero / _rootsOfXdEqualsW
// ---------------------------------------------------------------------------
fn slotIsZero(c: *const cplx_t) bool {
    return realIsZero(&c.Real) and realIsZero(&c.Imag);
}

// All d roots of x^d = w, w != 0, in angle order; every root has magnitude
// |w|^(1/d). Exact and O(d) where the companion matrix through the eigenvalue
// solver is O(d^3).
//
// clean_noise: only real coefficients cap how small a genuine root component
// can be; complex ones carry independent exponents, so their output stays raw.
fn rootsOfXdEqualsW(
    w: *const cplx_t,
    d: u16,
    roots: [*]cplx_t,
    clean_noise: bool,
    realContext: *realContext_t,
) void {
    var mag: real_t = undefined;
    var theta: real_t = undefined;
    var rho: real_t = undefined;
    var oneOnD: real_t = undefined;
    var dReal: real_t = undefined;
    var kReal: real_t = undefined;
    var angle: real_t = undefined;

    runtime.realRectangularToPolar(w, &mag, &theta, realContext);
    runtime.int32ToReal(d, &dReal);
    realDivide(const_1(), &dReal, &oneOnD, realContext);
    runtime.realPower(&mag, &oneOnD, &rho, realContext);
    const rhoExponent = realGetExponent(&rho);
    const noiseFloor = rhoExponent - realContext.digits + 5;

    var k: u16 = 0;
    while (k < d) : (k += 1) {
        const re = &roots[k].Real;
        const im = &roots[k].Imag;
        runtime.int32ToReal(k, &kReal);
        realMultiply(const75_2pi(), &kReal, &angle, realContext);
        realAdd(&angle, &theta, &angle, realContext);
        realDivide(&angle, &dReal, &angle, realContext);
        runtime.realPolarToRectangular(&rho, &angle, &roots[k], realContext);
        // For real w a component sitting a full working precision below the
        // root magnitude is angle-placement noise, not data.
        if (clean_noise and !realIsZero(re) and realGetExponent(re) < noiseFloor) {
            realSetZero(re);
        }
        if (clean_noise and !realIsZero(im) and realGetExponent(im) < noiseFloor) {
            realSetZero(im);
        }
    }
}

// ---------------------------------------------------------------------------
// fnSlvp (SLVP)
//
// X = coefficient vector (highest degree first) ==> X = row vector of all
// roots, input to regL. SLVP executes no user code: no engine nesting and no
// engineNestingRefused interaction.
// ---------------------------------------------------------------------------
pub export fn fnSlvp(unused_but_mandatory_parameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (comptime !runtime.option_slvp_poly) return;

    var xr: real34Matrix_t = undefined;
    var xc: complex34Matrix_t = undefined;
    var rows: u16 = undefined;
    var cols: u16 = undefined;
    var complexCoefs: bool = undefined;

    const dt = getRegisterDataType(REGISTER_X);
    if (dt == dtReal34Matrix) {
        complexCoefs = false;
        linkToRealMatrixRegister(REGISTER_X, &xr);
        rows = xr.header.matrixRows;
        cols = xr.header.matrixColumns;
    } else if (dt == dtComplex34Matrix) {
        complexCoefs = true;
        linkToComplexMatrixRegister(REGISTER_X, &xc);
        rows = xc.header.matrixRows;
        cols = xc.header.matrixColumns;
    } else {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function fnSlvp:", "SLVP expects a coefficient vector in X", null, null);
        }
        return;
    }

    if (rows != 1 and cols != 1) {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "SLVP needs a coefficient vector, not ({d}" ++ STD_CROSS ++ "{d})", .{ rows, cols });
            moreInfoOnError("In function fnSlvp:", errorMessage, null, null);
        }
        return;
    }
    const m: u32 = @as(u32, rows) * @as(u32, cols);

    // m coefficient slots plus up to m-1 root slots.
    const wsSize: usize = real_size_in_blocks_75 * m * 4;
    const coefRaw = runtime.allocC47Blocks(wsSize) orelse {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function fnSlvp:", "Ram full", null, null);
        }
        return;
    };
    const coef: [*]cplx_t = @ptrCast(@alignCast(coefRaw));
    const roots: [*]cplx_t = coef + m;

    var realContent = true;
    var finiteCoefs = true;
    var j: u32 = 0;
    while (j < m) : (j += 1) {
        if (complexCoefs) {
            const el = &complexElems(&xc)[j];
            runtime.real34ToReal(&el.real, &coef[j].Real);
            runtime.real34ToReal(&el.imag, &coef[j].Imag);
            realContent = realContent and realIsZero(&coef[j].Imag);
        } else {
            runtime.real34ToReal(&realElems(&xr)[j], &coef[j].Real);
            realSetZero(&coef[j].Imag);
        }
        finiteCoefs = finiteCoefs and !realIsSpecial(&coef[j].Real) and !realIsSpecial(&coef[j].Imag);
    }

    // A leading zero coefficient carries no degree: drop it silently, the SLVC
    // precedent.
    var lead: u32 = 0;
    while (lead < m and slotIsZero(&coef[lead])) lead += 1;
    if (m - lead < 2) { // a constant, or nothing at all, has no roots
        runtime.freeC47Blocks(coefRaw, wsSize);
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function fnSlvp:", "the polynomial needs degree 1 or higher after leading zeros are dropped", null, null);
        }
        return;
    }
    const n: u16 = @intCast(m - lead - 1); // the degree, and the number of roots delivered

    // Each trailing zero coefficient is one exact root at 0: deflate, solve
    // degree d = n - k.
    var k: u16 = 0;
    while (k < n and slotIsZero(&coef[m - 1 - k])) k += 1;
    const d: u16 = n - k;

    {
        const aLead: *const cplx_t = &coef[lead];

        if (d == 0) {
            // x^n: every root is 0, the appended zeros below are the whole answer.
        } else if (d == 1) {
            if (realContent and finiteCoefs) {
                realCopy(&coef[lead + 1].Real, &roots[0].Real);
                realChangeSign(&roots[0].Real);
                realDivide(&roots[0].Real, &aLead.Real, &roots[0].Real, ctxtReal34);
                realSetZero(&roots[0].Imag);
            } else {
                divComplexComplex(&coef[lead + 1], aLead, &roots[0], ctxtReal75);
                realChangeSign(&roots[0].Real);
                realChangeSign(&roots[0].Imag);
            }
        } else {
            var middleZero = true;
            j = lead + 1;
            while (j < lead + d) : (j += 1) {
                if (!slotIsZero(&coef[j])) {
                    middleZero = false;
                    break;
                }
            }

            if (middleZero) {
                // x^d = w in closed form.
                var w: cplx_t = undefined;
                if (realContent and finiteCoefs) {
                    realDivide(&coef[lead + d].Real, &aLead.Real, &w.Real, ctxtReal39);
                    realSetZero(&w.Imag);
                } else {
                    divComplexComplex(&coef[lead + d], aLead, &w, ctxtReal75);
                }
                realChangeSign(&w.Real);
                realChangeSign(&w.Imag);
                rootsOfXdEqualsW(&w, d, roots, realContent, if (realContent and finiteCoefs) ctxtReal39 else ctxtReal75);
            } else {
                // Monic companion matrix through the EIGEN QR solver.
                const dz: usize = d;
                const bulkSize: usize = real_size_in_blocks_75 * (dz * dz * 2 * 2 + dz * 7);
                const bulkRaw = runtime.allocC47Blocks(bulkSize) orelse {
                    runtime.freeC47Blocks(coefRaw, wsSize);
                    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
                    if (runtime.extra_info_on_calc_error) {
                        moreInfoOnError("In function fnSlvp:", "Ram full", null, null);
                    }
                    return;
                };
                const bulk: [*]cplx_t = @ptrCast(@alignCast(bulkRaw));
                const a = bulk;
                const eig = bulk + dz * dz;
                const scratch = bulk + dz * dz * 2;

                var idx: usize = 0;
                while (idx < dz * dz) : (idx += 1) {
                    realSetZero(&a[idx].Real);
                    realSetZero(&a[idx].Imag);
                }
                var i: usize = 0;
                while (i + 1 < dz) : (i += 1) { // superdiagonal of ones
                    realCopy(const_1(), &a[i * dz + i + 1].Real);
                }
                i = 0;
                while (i < dz) : (i += 1) { // bottom row element i = -b_i, b_i the monic coefficient of x^i
                    const dst = &a[(dz - 1) * dz + i];
                    const src = &coef[lead + d - @as(u32, @intCast(i))];
                    if (realContent and finiteCoefs) {
                        realDivide(&src.Real, &aLead.Real, &dst.Real, ctxtReal75);
                        realChangeSign(&dst.Real);
                        realSetZero(&dst.Imag);
                    } else {
                        divComplexComplex(src, aLead, dst, ctxtReal75);
                        realChangeSign(&dst.Real);
                        realChangeSign(&dst.Imag);
                    }
                }

                math_matrix_eigen.calculateEigenvalues(a, scratch, eig, d, true, true, ctxtReal75);
                if (runtime.lastErrorCode != runtime.ERROR_NONE) {
                    // Abort or refusal: write nothing, the central undo puts X and L back.
                    runtime.freeC47Blocks(bulkRaw, bulkSize);
                    runtime.freeC47Blocks(coefRaw, wsSize);
                    return;
                }
                {
                    var onlyRealRoots = false;
                    var pureImaginaryPair = false;
                    if (realContent and finiteCoefs and d <= 3) {
                        // Rounding the monic companion to 75 digits splits a double root by about 1E-38: imaginary parts are set to zero when the discriminant of
                        // the Real34 coefficients is not negative, and for a cubic the pair's real parts when a d = b c, (x - r)(x^2 + s) up to scale.
                        var c159 = runtime.ctxtReal75;
                        c159.digits = 159;
                        onlyRealRoots = math_slvc.realCubicHasOnlyRealRoots(if (d == 3) &aLead.Real else const_0(), &coef[lead + d - 2].Real, &coef[lead + d - 1].Real, &coef[lead + d].Real, 150, null, &c159);
                        if (d == 3) {
                            var ad: real_t = undefined;
                            var bc: real_t = undefined;
                            realMultiply(&aLead.Real, &coef[lead + 3].Real, &ad, ctxtReal75);
                            realMultiply(&coef[lead + 1].Real, &coef[lead + 2].Real, &bc, ctxtReal75);
                            pureImaginaryPair = realCompareEqual(&ad, &bc);
                        }
                    }
                    i = 0;
                    while (i < dz) : (i += 1) {
                        const re = &roots[i].Real;
                        const im = &roots[i].Imag;
                        realCopy(&eig[i * dz + i].Real, re);
                        realCopy(&eig[i * dz + i].Imag, im);
                        if (onlyRealRoots) {
                            realSetZero(im);
                        } else if (pureImaginaryPair and !realIsZero(im)) {
                            realSetZero(re);
                        } else if (realContent and finiteCoefs and d > 3) {
                            // The QR iteration stops at a diagonal change of 1E-37: a real part 36 orders below the imaginary part is residue of the
                            // iteration, not a feature of the root.
                            if (!realIsZero(im) and realGetExponent(re) < realGetExponent(im) - 36) {
                                realSetZero(re);
                            }
                        }
                    }
                }
                runtime.freeC47Blocks(bulkRaw, bulkSize);
            }
        }
    }

    { // the deflated roots at 0, after the solved roots
        var i: usize = d;
        while (i < n) : (i += 1) {
            realSetZero(&roots[i].Real);
            realSetZero(&roots[i].Imag);
        }
    }

    var isComplex = false;
    {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            if (!realIsZero(&roots[i].Imag)) {
                isComplex = true;
                break;
            }
        }
    }

    // The result matrix is allocated, then L, then X is overwritten: every
    // failure leaves X and L untouched.
    if (isComplex) {
        var res: complex34Matrix_t = undefined;
        if (!complexMatrixInit(&res, 1, n)) {
            runtime.freeC47Blocks(coefRaw, wsSize);
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                moreInfoOnError("In function fnSlvp:", "Ram full", null, null);
            }
            return;
        }
        if (!saveLastX()) {
            complexMatrixFree(&res);
            runtime.freeC47Blocks(coefRaw, wsSize);
            return;
        }
        const elems = complexElems(&res);
        var i: usize = 0;
        while (i < n) : (i += 1) {
            runtime.realToReal34(&roots[i].Real, &elems[i].real);
            runtime.realToReal34(&roots[i].Imag, &elems[i].imag);
        }
        convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
        complexMatrixFree(&res);
    } else {
        var res: real34Matrix_t = undefined;
        if (!realMatrixInit(&res, 1, n)) {
            runtime.freeC47Blocks(coefRaw, wsSize);
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE);
            if (runtime.extra_info_on_calc_error) {
                moreInfoOnError("In function fnSlvp:", "Ram full", null, null);
            }
            return;
        }
        if (!saveLastX()) {
            realMatrixFree(&res);
            runtime.freeC47Blocks(coefRaw, wsSize);
            return;
        }
        const elems = realElems(&res);
        var i: usize = 0;
        while (i < n) : (i += 1) {
            runtime.realToReal34(&roots[i].Real, &elems[i]);
        }
        convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        realMatrixFree(&res);
    }

    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    runtime.freeC47Blocks(coefRaw, wsSize);
}
