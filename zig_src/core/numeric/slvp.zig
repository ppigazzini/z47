// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/slvp.c: SLVP, every root of a polynomial
// given its coefficient vector. Exports slvp.h's fnSlvp. Covered by slvp.txt.
//
// Coefficients and roots live in interleaved complex slots of real_t at 75
// digits: slot i is (c[2i] re, c[2i+1] im), the layout calculateEigenvalues
// works on. The general case builds the monic companion matrix and hands it to
// the already-Zig-owned QR eigensolver in matrix/eigen.zig, which shares this
// object -- upstream drops the `static` on its copy under OPTION_SLVP, the Zig
// side only needs the `pub`.
//
// OPTION_SLVP is #undef'd for the flash-limited DM42 firmware, where the whole
// body compiles away and fnSlvp is an empty stub (items.zig still binds the
// symbol, and softmenus.zig strikes the item out).

const abi = @import("abi");
const consts = abi.constants;
const const_1 = consts.const_1;
const const_1on2 = consts.const_1on2;
const const75_2pi = consts.const75_2pi;

const runtime = @import("command_wrappers/runtime.zig");
const math_division_cells = @import("arithmetic/division_cells.zig");
const math_matrix_eigen = @import("matrix/eigen.zig");
const math_real_predicates = @import("compare/real_predicates.zig");

const real_t = runtime.real_t;
const real34Matrix_t = runtime.real34Matrix_t;
const complex34Matrix_t = runtime.complex34Matrix_t;
const realContext_t = runtime.realContext_t;
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
const divComplexComplex = math_division_cells.divComplexComplex;

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
fn slotIsZero(c: [*]const real_t) bool {
    return realIsZero(&c[0]) and realIsZero(&c[1]);
}

// All d roots of x^d = w, w != 0, in angle order; every root has magnitude
// |w|^(1/d). The QR engine refuses a circulant companion matrix
// (isProblematicMatrix), so this closed form is the only path for such
// polynomials, not an optimisation.
//
// clean_noise: only real coefficients cap how small a genuine root component
// can be; complex ones carry independent exponents, so their output stays raw.
fn rootsOfXdEqualsW(
    wRe: *const real_t,
    wIm: *const real_t,
    d: u16,
    roots: [*]real_t,
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

    runtime.realRectangularToPolar(wRe, wIm, &mag, &theta, realContext);
    runtime.int32ToReal(d, &dReal);
    realDivide(const_1(), &dReal, &oneOnD, realContext);
    runtime.realPower(&mag, &oneOnD, &rho, realContext);
    const rhoExponent = realGetExponent(&rho);
    const noiseFloor = rhoExponent - realContext.digits + 5;

    var k: u16 = 0;
    while (k < d) : (k += 1) {
        const re = &roots[@as(usize, k) * 2];
        const im = &roots[@as(usize, k) * 2 + 1];
        runtime.int32ToReal(k, &kReal);
        realMultiply(const75_2pi(), &kReal, &angle, realContext);
        realAdd(&angle, &theta, &angle, realContext);
        realDivide(&angle, &dReal, &angle, realContext);
        runtime.realPolarToRectangular(&rho, &angle, re, im, realContext);
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
    if (comptime !runtime.option_slvp) return;

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
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function fnSlvp:", "SLVP expects a coefficient vector in X", null, null);
        }
        return;
    }

    if (rows != 1 and cols != 1) {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
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
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function fnSlvp:", "Ram full", null, null);
        }
        return;
    };
    const coef: [*]real_t = @ptrCast(@alignCast(coefRaw));
    const roots: [*]real_t = coef + m * 2;

    // Real coefficients cap how small a genuine root component can be (a
    // near-real pair a+-bi is encoded through b squared); complex ones carry
    // independent exponents and get no cleanup.
    var realContent = true;
    var j: u32 = 0;
    while (j < m) : (j += 1) {
        if (complexCoefs) {
            const el = &complexElems(&xc)[j];
            runtime.real34ToReal(&el.real, &coef[j * 2]);
            runtime.real34ToReal(&el.imag, &coef[j * 2 + 1]);
            realContent = realContent and realIsZero(&coef[j * 2 + 1]);
        } else {
            runtime.real34ToReal(&realElems(&xr)[j], &coef[j * 2]);
            realSetZero(&coef[j * 2 + 1]);
        }
    }

    // A leading zero coefficient carries no degree: drop it silently, the SLVC
    // precedent.
    var lead: u32 = 0;
    while (lead < m and slotIsZero(coef + lead * 2)) lead += 1;
    if (m - lead < 2) { // a constant, or nothing at all, has no roots
        runtime.freeC47Blocks(coefRaw, wsSize);
        displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
        if (runtime.extra_info_on_calc_error) {
            moreInfoOnError("In function fnSlvp:", "the polynomial needs degree 1 or higher after leading zeros are dropped", null, null);
        }
        return;
    }
    const n: u16 = @intCast(m - lead - 1); // the degree, and the number of roots delivered

    // Each trailing zero coefficient is one exact root at 0: deflate, solve
    // degree d = n - k.
    var k: u16 = 0;
    while (k < n and slotIsZero(coef + (m - 1 - k) * 2)) k += 1;
    const d: u16 = n - k;

    {
        const aLead: [*]const real_t = coef + lead * 2;

        if (d == 0) {
            // x^n: every root is 0, the appended zeros below are the whole answer.
        } else if (d == 1) {
            divComplexComplex(&coef[(lead + 1) * 2], &coef[(lead + 1) * 2 + 1], &aLead[0], &aLead[1], &roots[0], &roots[1], ctxtReal75);
            realChangeSign(&roots[0]);
            realChangeSign(&roots[1]);
        } else {
            var middleZero = true;
            j = lead + 1;
            while (j < lead + d) : (j += 1) {
                if (!slotIsZero(coef + j * 2)) {
                    middleZero = false;
                    break;
                }
            }

            if (middleZero) {
                // x^d = w in closed form: the QR engine refuses this circulant
                // companion shape.
                var wRe: real_t = undefined;
                var wIm: real_t = undefined;
                divComplexComplex(&coef[(lead + d) * 2], &coef[(lead + d) * 2 + 1], &aLead[0], &aLead[1], &wRe, &wIm, ctxtReal75);
                realChangeSign(&wRe);
                realChangeSign(&wIm);
                rootsOfXdEqualsW(&wRe, &wIm, d, roots, realContent, ctxtReal75);
            } else {
                // Monic companion matrix through the EIGEN QR solver.
                const dz: usize = d;
                const bulkSize: usize = real_size_in_blocks_75 * (dz * dz * 2 * 4 + dz * 2);
                const bulkRaw = runtime.allocC47Blocks(bulkSize) orelse {
                    runtime.freeC47Blocks(coefRaw, wsSize);
                    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                    if (runtime.extra_info_on_calc_error) {
                        moreInfoOnError("In function fnSlvp:", "Ram full", null, null);
                    }
                    return;
                };
                const bulk: [*]real_t = @ptrCast(@alignCast(bulkRaw));
                const a = bulk;
                const q = bulk + dz * dz * 2;
                const r = bulk + dz * dz * 2 * 2;
                const eig = bulk + dz * dz * 2 * 3;
                const previousDiagonal = bulk + dz * dz * 2 * 4;

                var idx: usize = 0;
                while (idx < dz * dz * 2) : (idx += 1) realSetZero(&a[idx]);
                var i: usize = 0;
                while (i + 1 < dz) : (i += 1) { // superdiagonal of ones
                    realCopy(const_1(), &a[(i * dz + i + 1) * 2]);
                }
                i = 0;
                while (i < dz) : (i += 1) { // bottom row element i = -b_i, b_i the monic coefficient of x^i
                    const dst = &a[((dz - 1) * dz + i) * 2];
                    const src = coef + (lead + d - @as(u32, @intCast(i))) * 2;
                    divComplexComplex(&src[0], &src[1], &aLead[0], &aLead[1], dst, &a[((dz - 1) * dz + i) * 2 + 1], ctxtReal75);
                    realChangeSign(dst);
                    realChangeSign(&a[((dz - 1) * dz + i) * 2 + 1]);
                }

                {
                    // The engine's circulant screen reads only real parts, so a
                    // complex polynomial with purely imaginary middle coefficients
                    // and a real constant would be refused although it is not
                    // x^d = w at all: a diagonal similarity (superdiagonal 1/2,
                    // bottom row scaled by powers of 2) keeps every eigenvalue and
                    // makes the companion invisible to the screen.
                    const bottom = a + (dz - 1) * dz * 2;
                    var looksCirculant = !realIsZero(&bottom[0]);
                    i = 1;
                    while (looksCirculant and i < dz) : (i += 1) {
                        looksCirculant = realIsZero(&bottom[i * 2]);
                    }
                    if (looksCirculant) {
                        var two: real_t = undefined;
                        var scale: real_t = undefined;
                        realAdd(const_1(), const_1(), &two, ctxtReal75);
                        realCopy(const_1(), &scale);
                        i = 0;
                        while (i + 1 < dz) : (i += 1) {
                            realCopy(const_1on2(), &a[(i * dz + i + 1) * 2]);
                        }
                        i = dz;
                        while (i > 0) { // bottom row element i gains the factor 2^(d-1-i)
                            i -= 1;
                            realMultiply(&bottom[i * 2], &scale, &bottom[i * 2], ctxtReal75);
                            realMultiply(&bottom[i * 2 + 1], &scale, &bottom[i * 2 + 1], ctxtReal75);
                            realMultiply(&scale, &two, &scale, ctxtReal75);
                        }
                    }
                }

                math_matrix_eigen.calculateEigenvalues(a, q, r, eig, previousDiagonal, d, true, true, ctxtReal75);
                if (runtime.lastErrorCode != runtime.ERROR_NONE) {
                    // Abort or refusal: write nothing, the central undo puts X and L back.
                    runtime.freeC47Blocks(bulkRaw, bulkSize);
                    runtime.freeC47Blocks(coefRaw, wsSize);
                    return;
                }
                i = 0;
                while (i < dz) : (i += 1) {
                    const re = &roots[i * 2];
                    const im = &roots[i * 2 + 1];
                    realCopy(&eig[(i * dz + i) * 2], re);
                    realCopy(&eig[(i * dz + i) * 2 + 1], im);
                    if (realContent) {
                        // A component 36 orders below the root's dominant component
                        // is QR convergence residue: 34-digit real coefficients
                        // cannot encode a root feature that small; complex ones can,
                        // so their output stays raw.
                        const dominant = if (realIsZero(re) or (!realIsZero(im) and realGetExponent(im) > realGetExponent(re))) im else re;
                        const topExponent = realGetExponent(dominant);
                        if (!realIsZero(re) and realGetExponent(re) < topExponent - 36) {
                            realSetZero(re);
                        }
                        if (!realIsZero(im) and realGetExponent(im) < topExponent - 36) {
                            realSetZero(im);
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
            realSetZero(&roots[i * 2]);
            realSetZero(&roots[i * 2 + 1]);
        }
    }

    var isComplex = false;
    {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            if (!realIsZero(&roots[i * 2 + 1])) {
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
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
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
            runtime.realToReal34(&roots[i * 2], &elems[i].real);
            runtime.realToReal34(&roots[i * 2 + 1], &elems[i].imag);
        }
        convertComplex34MatrixToComplex34MatrixRegister(&res, REGISTER_X);
        complexMatrixFree(&res);
    } else {
        var res: real34Matrix_t = undefined;
        if (!realMatrixInit(&res, 1, n)) {
            runtime.freeC47Blocks(coefRaw, wsSize);
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
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
            runtime.realToReal34(&roots[i * 2], &elems[i]);
        }
        convertReal34MatrixToReal34MatrixRegister(&res, REGISTER_X);
        realMatrixFree(&res);
    }

    adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
    runtime.freeC47Blocks(coefRaw, wsSize);
}
