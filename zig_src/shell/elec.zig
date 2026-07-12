// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/mathematics/elec.c: the electrical-engineering
// transforms -- delta<->star, symmetrical-components<->ABC, three-phase Z=V/I,
// V=I*Z, I=V/Z, X->ABC balanced set, and triple flip-polar. Faithful
// line-by-line port preserving the exact ctxtReal39 complex-math operation
// order and the CPXRES / SPCRES / ASLIFT gating.
//
// Gated on OPTION_ELEC exactly as elec.c: every entry point is always exported
// (the items table references them unconditionally), but the body only compiles
// where option_elec is set -- the host and DMCP package 3. On every other build
// (DMCP packages 1/2/4 and DMCP5) the bodies are comptime-elided to empty
// no-ops, mirroring elec.c's `#if defined(OPTION_ELEC)` empty stubs, so the
// symbols still resolve at link without pulling the feature into tight flash.
//
// Verified on the host by src/testSuite/tests/elec.txt; built green on every
// DMCP package and DMCP5 variant.

const frontier_build_options = @import("frontier_build_options");
const option_elec: bool = frontier_build_options.option_elec;

// ---------------------------------------------------------------------------
// Types -- shared ABI bindings. The hand-mirrored C-ABI layouts
// (real_t/real34_t/realContext_t/cplx_t) now come from the single-source-of-truth
// abi module; only the local spellings are aliased so the ported body is stable.
// ---------------------------------------------------------------------------
const abi = @import("abi");
const frontier_error = @import("error.zig");
const frontier_real_type = @import("real_type.zig");
const frontier_register_value_conversions = @import("register_value_conversions.zig");
const consts = abi.constants;
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;
const cplx_t = abi.Complex;
const calcRegister_t = i16;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_L: calcRegister_t = 108;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const dtComplex34: u32 = 2;
const amPolar: u32 = 16;
const amAngleMask: u32 = 15;
const amNone: u32 = 5;

const FLAG_CPXRES = 0x8004;
const FLAG_SPCRES = 0x8017;
const FLAG_ASLIFT = 0xc023;

const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const TI_ABC: u16 = 72;
const TI_ABBCCA: u16 = 73;
const TI_012: u16 = 74;
const NOPARAM: u16 = 9876;
const REAL34_SIZE_IN_BYTES: usize = 16;

// decNumber bit flags (realType.h) -- from the shared ABI bindings.
const DECNEG = abi.DECNEG;
const DECNAN = abi.DECNAN;
const DECSNAN = abi.DECSNAN;
const DECSPECIAL = abi.DECSPECIAL;

// Three-phase named-register ids (elec.c defines).
const TripleRegZ1_96: calcRegister_t = 96;
const TripleRegV1_90: calcRegister_t = 90;
const TripleRegI1_93: calcRegister_t = 93;
const TripleRegV2_91: calcRegister_t = 91;
const TripleRegV3_92: calcRegister_t = 92;
const TripleRegI2_94: calcRegister_t = 94;
const TripleRegI3_95: calcRegister_t = 95;
const TripleRegZ2_97: calcRegister_t = 97;
const TripleRegZ3_98: calcRegister_t = 98;

// Named, typed constant-blob accessors live in the shared abi module
// (zig_src/abi/constants.zig): consts.const1on2(), const3(), root3on2(),
// const1e_37() -- no magic offsets or unchecked casts in this body.

// ---------------------------------------------------------------------------
// Globals and function externs
// ---------------------------------------------------------------------------
extern var ctxtReal39: realContext_t;
extern var temporaryInformation: u8;

extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) ?*anyopaque;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn getSystemFlag(flag: c_int) bool;
extern fn setSystemFlag(flag: c_uint) void;
extern fn saveForUndo() void;
extern fn liftStack() void;
extern fn fnDrop(unusedButMandatoryParameter: u16) void;
extern fn fnSwapX(regist: u16) void;
extern fn fnToRect2(unusedButMandatoryParameter: u16) void;
extern fn copySourceRegisterToDestRegister(src: calcRegister_t, dst: calcRegister_t) void;

extern fn decNumberCopy(dst: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberDivide(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn realCompareAbsLessThan(a: *align(1) const real_t, b: *align(1) const real_t) bool;

extern fn decQuadIsZero(x: *align(1) const real34_t) u32;

// ---------------------------------------------------------------------------
// Real-number helper macros (realType.h), inlined.
// ---------------------------------------------------------------------------
inline fn realCopy(src: *align(1) const real_t, dst: *real_t) void {
    _ = decNumberCopy(dst, src);
}
inline fn realChangeSign(x: *real_t) void {
    x.bits ^= DECNEG;
}
inline fn realDivide(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realIsZero(x: *align(1) const real_t) bool {
    return x.lsu[0] == 0 and x.digits == 1 and (x.bits & DECSPECIAL) == 0;
}
inline fn realIsNaN(x: *align(1) const real_t) bool {
    return (x.bits & (DECNAN | DECSNAN)) != 0;
}
inline fn real34IsZero(x: *align(1) const real34_t) bool {
    return decQuadIsZero(x) != 0;
}
const registerImag34Data = abi.registerImag34;
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}
inline fn setComplexRegisterPolarMode(reg: calcRegister_t, pm: u32) void {
    const angle = if ((pm & amPolar) != 0) (getRegisterTag(reg) & amAngleMask) else amNone;
    setRegisterTag(reg, angle | (pm & amPolar));
}

// Complex arithmetic comes from the shared abi runtime wrappers (abi.runtime):
// rt.add/mul/div take a *Complex and thread ctxtReal39.
const rt = abi.runtime;
inline fn getRegCplx(reg: calcRegister_t, c: *cplx_t) void {
    _ = frontier_register_value_conversions.getRegisterAsComplex(reg, &c.Real, &c.Imag);
}
inline fn putRegCplx(c: *const cplx_t, reg: calcRegister_t) void {
    frontier_register_value_conversions.convertComplexToResultRegister(&c.Real, &c.Imag, reg);
}

// ---------------------------------------------------------------------------
// Static helpers (elec.c)
// ---------------------------------------------------------------------------
fn elecImagIsDust(im: *align(1) const real_t) bool {
    if (realIsZero(im)) {
        return true;
    }
    return realCompareAbsLessThan(im, consts.const1e_37()); // ELEC_DUST_FILTER == true
}

fn elecInputIsComplex(regs: []const calcRegister_t) bool {
    for (regs) |r| {
        if (getRegisterDataType(r) == dtComplex34 and !real34IsZero(registerImag34Data(r))) {
            return true;
        }
    }
    return false;
}

// Error surface: the core returns an error instead of calling
// displayCalcErrorMessage inline; the exported wrapper maps it back at the ABI
// boundary. The SPCRES NaN-substitution path is a success (it recovers), so it
// stays in the core.
const Error = error{ArgExceedsDomain};

fn reportError(e: Error) void {
    switch (e) {
        error.ArgExceedsDomain => frontier_error.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X),
    }
}

fn checkResults(results: []const *cplx_t) Error!void {
    if (getSystemFlag(FLAG_CPXRES)) {
        return;
    }
    var bad = false;
    for (results) |res| {
        if (!elecImagIsDust(&res.Imag) or realIsNaN(&res.Real) or realIsNaN(&res.Imag)) {
            bad = true;
            break;
        }
    }
    if (!bad) {
        return;
    }
    if (getSystemFlag(FLAG_SPCRES)) {
        for (results) |res| {
            frontier_real_type.realSetNaN(&res.Real);
            frontier_real_type.realSetZero(&res.Imag);
        }
        return;
    }
    return error.ArgExceedsDomain;
}

fn elecGetXYZ(x: *cplx_t, y: *cplx_t, z: *cplx_t) void {
    getRegCplx(REGISTER_X, x);
    getRegCplx(REGISTER_Y, y);
    getRegCplx(REGISTER_Z, z);
}

fn elecPutResults(l: *const cplx_t, x: *const cplx_t, y: *const cplx_t, z: *const cplx_t) void {
    putRegCplx(l, REGISTER_L);
    putRegCplx(x, REGISTER_X);
    putRegCplx(y, REGISTER_Y);
    putRegCplx(z, REGISTER_Z);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_X);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_Y);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_Z);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_L);
}

fn elecSetAOperators(aOp: *cplx_t, aaOp: *cplx_t) void {
    // a = 1 angle 120deg = -1/2 + j*root3/2 ; a^2 = conjugate of a
    realCopy(consts.const1on2(), &aOp.Real);
    realChangeSign(&aOp.Real);
    realCopy(consts.root3on2(), &aOp.Imag);
    realCopy(&aOp.Real, &aaOp.Real);
    realCopy(&aOp.Imag, &aaOp.Imag);
    realChangeSign(&aaOp.Imag);
}

fn flipPolar(regist: calcRegister_t) void {
    const notX = (regist != REGISTER_X);
    if (notX) {
        fnSwapX(@intCast(regist));
    }
    {
        var zReal: real_t = undefined;
        var zImag: real_t = undefined;
        if (getRegisterDataType(REGISTER_X) != dtComplex34) {
            if (frontier_register_value_conversions.getRegisterAsComplex(REGISTER_X, &zReal, &zImag)) {
                frontier_register_value_conversions.convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
            }
        } else if (getComplexRegisterPolarMode(REGISTER_X) != amPolar) {
            setComplexRegisterPolarMode(REGISTER_X, amPolar);
        } else {
            fnToRect2(NOPARAM);
        }
    }
    if (notX) {
        fnSwapX(@intCast(regist));
    }
}

fn elecGetTriple(base: calcRegister_t, r1: *cplx_t, r2: *cplx_t, r3: *cplx_t) void {
    getRegCplx(base, r1);
    getRegCplx(base + 1, r2);
    getRegCplx(base + 2, r3);
}

fn elecStoreTriple(base: calcRegister_t, r1: *const cplx_t, r2: *const cplx_t, r3: *const cplx_t) void {
    liftStack();
    putRegCplx(r3, REGISTER_X); // phase 3 (deepest) into X
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    putRegCplx(r2, REGISTER_X); // phase 2 into X, phase 3 rolls to Y
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    putRegCplx(r1, REGISTER_X); // phase 1 into X, phase 2 -> Y, phase 3 -> Z
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_X);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_Y);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_Z);
    setSystemFlag(FLAG_ASLIFT);
    copySourceRegisterToDestRegister(REGISTER_X, base + 0);
    copySourceRegisterToDestRegister(REGISTER_Y, base + 1);
    copySourceRegisterToDestRegister(REGISTER_Z, base + 2);
}

// ---------------------------------------------------------------------------
// Public item entry points
// ---------------------------------------------------------------------------
fn fnDeltaToStarCore() Error!void {
    var x: cplx_t = undefined;
    var y: cplx_t = undefined;
    var z: cplx_t = undefined;
    var s: cplx_t = undefined;
    var xy: cplx_t = undefined;
    var yz: cplx_t = undefined;
    var zx: cplx_t = undefined;
    var rx: cplx_t = undefined;
    var ry: cplx_t = undefined;
    var rz: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ REGISTER_X, REGISTER_Y, REGISTER_Z };
    const results = [_]*cplx_t{ &rx, &ry, &rz };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetXYZ(&x, &y, &z);
    rt.add(&x, &y, &s); // s = x + y + z
    rt.add(&s, &z, &s);
    rt.mul(&z, &x, &zx); // pairwise products
    rt.mul(&x, &y, &xy);
    rt.mul(&y, &z, &yz);
    rt.div(&zx, &s, &rx); // X = (z*x) / s
    rt.div(&xy, &s, &ry); // Y = (x*y) / s
    rt.div(&yz, &s, &rz); // Z = (y*z) / s
    try checkResults(&results);
    saveForUndo();
    setSystemFlag(FLAG_ASLIFT);
    elecPutResults(&x, &rx, &ry, &rz); // L = original X
    temporaryInformation = TI_ABC;
}

pub export fn fnDeltaToStar(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnDeltaToStarCore() catch |e| reportError(e);
}

fn fnStarToDeltaCore() Error!void {
    var x: cplx_t = undefined;
    var y: cplx_t = undefined;
    var z: cplx_t = undefined;
    var p: cplx_t = undefined;
    var t: cplx_t = undefined;
    var rx: cplx_t = undefined;
    var ry: cplx_t = undefined;
    var rz: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ REGISTER_X, REGISTER_Y, REGISTER_Z };
    const results = [_]*cplx_t{ &rx, &ry, &rz };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetXYZ(&x, &y, &z);
    rt.mul(&x, &y, &p); // p = x*y + y*z + z*x
    rt.mul(&y, &z, &t);
    rt.add(&p, &t, &p);
    rt.mul(&z, &x, &t);
    rt.add(&p, &t, &p);
    rt.div(&p, &z, &rx); // X = p / z
    rt.div(&p, &x, &ry); // Y = p / x
    rt.div(&p, &y, &rz); // Z = p / y
    try checkResults(&results);
    saveForUndo();
    setSystemFlag(FLAG_ASLIFT);
    elecPutResults(&x, &rx, &ry, &rz); // L = original X
    temporaryInformation = TI_ABBCCA;
}

pub export fn fnStarToDelta(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnStarToDeltaCore() catch |e| reportError(e);
}

fn fnSymToAbcCore() Error!void {
    var a2: cplx_t = undefined;
    var a1: cplx_t = undefined;
    var a0: cplx_t = undefined;
    var va: cplx_t = undefined;
    var vb: cplx_t = undefined;
    var vc: cplx_t = undefined;
    var aOp: cplx_t = undefined;
    var aaOp: cplx_t = undefined;
    var t: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ REGISTER_X, REGISTER_Y, REGISTER_Z };
    const results = [_]*cplx_t{ &vc, &vb, &va };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetXYZ(&a2, &a1, &a0); // X = A2, Y = A1, Z = A0
    elecSetAOperators(&aOp, &aaOp);
    rt.add(&a0, &a1, &va); // Va = A0 + A1 + A2
    rt.add(&va, &a2, &va);
    rt.mul(&aaOp, &a1, &vb); // Vb = A0 + a^2*A1 + a*A2
    rt.mul(&aOp, &a2, &t);
    rt.add(&vb, &t, &vb);
    rt.add(&vb, &a0, &vb);
    rt.mul(&aOp, &a1, &vc); // Vc = A0 + a*A1 + a^2*A2
    rt.mul(&aaOp, &a2, &t);
    rt.add(&vc, &t, &vc);
    rt.add(&vc, &a0, &vc);
    try checkResults(&results);
    saveForUndo();
    setSystemFlag(FLAG_ASLIFT);
    elecPutResults(&a2, &vc, &vb, &va); // L = original X (A2)
    temporaryInformation = TI_ABC;
}

pub export fn fnSymToAbc(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnSymToAbcCore() catch |e| reportError(e);
}

fn fnAbcToSymCore() Error!void {
    var vc: cplx_t = undefined;
    var vb: cplx_t = undefined;
    var va: cplx_t = undefined;
    var s0: cplx_t = undefined;
    var s1: cplx_t = undefined;
    var s2: cplx_t = undefined;
    var aOp: cplx_t = undefined;
    var aaOp: cplx_t = undefined;
    var t: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ REGISTER_X, REGISTER_Y, REGISTER_Z };
    const results = [_]*cplx_t{ &s2, &s1, &s0 };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetXYZ(&vc, &vb, &va); // X = Vc, Y = Vb, Z = Va
    elecSetAOperators(&aOp, &aaOp);
    rt.add(&va, &vb, &s0); // A0 = (Va + Vb + Vc) / 3
    rt.add(&s0, &vc, &s0);
    realDivide(&s0.Real, consts.const3(), &s0.Real, &ctxtReal39);
    realDivide(&s0.Imag, consts.const3(), &s0.Imag, &ctxtReal39);
    rt.mul(&aOp, &vb, &s1); // A1 = (Va + a*Vb + a^2*Vc) / 3
    rt.mul(&aaOp, &vc, &t);
    rt.add(&s1, &t, &s1);
    rt.add(&s1, &va, &s1);
    realDivide(&s1.Real, consts.const3(), &s1.Real, &ctxtReal39);
    realDivide(&s1.Imag, consts.const3(), &s1.Imag, &ctxtReal39);
    rt.mul(&aaOp, &vb, &s2); // A2 = (Va + a^2*Vb + a*Vc) / 3
    rt.mul(&aOp, &vc, &t);
    rt.add(&s2, &t, &s2);
    rt.add(&s2, &va, &s2);
    realDivide(&s2.Real, consts.const3(), &s2.Real, &ctxtReal39);
    realDivide(&s2.Imag, consts.const3(), &s2.Imag, &ctxtReal39);
    try checkResults(&results);
    saveForUndo();
    setSystemFlag(FLAG_ASLIFT);
    elecPutResults(&vc, &s2, &s1, &s0); // L = original X (Vc)
    temporaryInformation = TI_012;
}

pub export fn fnAbcToSym(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnAbcToSymCore() catch |e| reportError(e);
}

fn fnTripleZfromVICore() Error!void {
    var v1: cplx_t = undefined;
    var v2: cplx_t = undefined;
    var v3: cplx_t = undefined;
    var ii1: cplx_t = undefined;
    var ii2: cplx_t = undefined;
    var ii3: cplx_t = undefined;
    var z1: cplx_t = undefined;
    var z2: cplx_t = undefined;
    var z3: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ TripleRegV1_90, TripleRegV2_91, TripleRegV3_92, TripleRegI1_93, TripleRegI2_94, TripleRegI3_95 };
    const results = [_]*cplx_t{ &z1, &z2, &z3 };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetTriple(TripleRegV1_90, &v1, &v2, &v3);
    elecGetTriple(TripleRegI1_93, &ii1, &ii2, &ii3);
    rt.div(&v1, &ii1, &z1); // Z1 = V1 / I1
    rt.div(&v2, &ii2, &z2);
    rt.div(&v3, &ii3, &z3);
    try checkResults(&results);
    saveForUndo();
    elecStoreTriple(TripleRegZ1_96, &z1, &z2, &z3);
}

pub export fn fnTripleZfromVI(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnTripleZfromVICore() catch |e| reportError(e);
}

fn fnTripleVfromIZCore() Error!void {
    var ii1: cplx_t = undefined;
    var ii2: cplx_t = undefined;
    var ii3: cplx_t = undefined;
    var z1: cplx_t = undefined;
    var z2: cplx_t = undefined;
    var z3: cplx_t = undefined;
    var v1: cplx_t = undefined;
    var v2: cplx_t = undefined;
    var v3: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ TripleRegI1_93, TripleRegI2_94, TripleRegI3_95, TripleRegZ1_96, TripleRegZ2_97, TripleRegZ3_98 };
    const results = [_]*cplx_t{ &v1, &v2, &v3 };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetTriple(TripleRegI1_93, &ii1, &ii2, &ii3);
    elecGetTriple(TripleRegZ1_96, &z1, &z2, &z3);
    rt.mul(&ii1, &z1, &v1); // V1 = I1 * Z1
    rt.mul(&ii2, &z2, &v2);
    rt.mul(&ii3, &z3, &v3);
    try checkResults(&results);
    saveForUndo();
    elecStoreTriple(TripleRegV1_90, &v1, &v2, &v3);
}

pub export fn fnTripleVfromIZ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnTripleVfromIZCore() catch |e| reportError(e);
}

fn fnTripleIfromVZCore() Error!void {
    var v1: cplx_t = undefined;
    var v2: cplx_t = undefined;
    var v3: cplx_t = undefined;
    var z1: cplx_t = undefined;
    var z2: cplx_t = undefined;
    var z3: cplx_t = undefined;
    var ii1: cplx_t = undefined;
    var ii2: cplx_t = undefined;
    var ii3: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{ TripleRegV1_90, TripleRegV2_91, TripleRegV3_92, TripleRegZ1_96, TripleRegZ2_97, TripleRegZ3_98 };
    const results = [_]*cplx_t{ &ii1, &ii2, &ii3 };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    elecGetTriple(TripleRegV1_90, &v1, &v2, &v3);
    elecGetTriple(TripleRegZ1_96, &z1, &z2, &z3);
    rt.div(&v1, &z1, &ii1); // I1 = V1 / Z1
    rt.div(&v2, &z2, &ii2);
    rt.div(&v3, &z3, &ii3);
    try checkResults(&results);
    saveForUndo();
    elecStoreTriple(TripleRegI1_93, &ii1, &ii2, &ii3);
}

pub export fn fnTripleIfromVZ(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnTripleIfromVZCore() catch |e| reportError(e);
}

fn fnTripleFlipPolarCore() Error!void {
    saveForUndo();
    flipPolar(REGISTER_X);
    flipPolar(REGISTER_Y);
    flipPolar(REGISTER_Z);
}

pub export fn fnTripleFlipPolar(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnTripleFlipPolarCore() catch |e| reportError(e);
}

fn fnCopyXtoAbcCore() Error!void {
    var x: cplx_t = undefined;
    var rx: cplx_t = undefined;
    var ry: cplx_t = undefined;
    var aOp: cplx_t = undefined;
    var aaOp: cplx_t = undefined;
    const inRegs = [_]calcRegister_t{REGISTER_X};
    const results = [_]*cplx_t{ &rx, &ry, &x };
    if (elecInputIsComplex(&inRegs)) {
        setSystemFlag(FLAG_CPXRES);
    }
    getRegCplx(REGISTER_X, &x); // x = source phasor
    elecSetAOperators(&aOp, &aaOp);
    rt.mul(&aOp, &x, &ry); // a*x   -> Y
    rt.mul(&aaOp, &x, &rx); // a^2*x -> X
    try checkResults(&results);
    saveForUndo();
    fnDrop(NOPARAM); // consume the input
    putRegCplx(&x, REGISTER_L); // L = original x
    liftStack();
    putRegCplx(&x, REGISTER_X); // x is the base of the set
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    putRegCplx(&ry, REGISTER_X); // a*x into X, x rolls to Y
    setSystemFlag(FLAG_ASLIFT);
    liftStack();
    putRegCplx(&rx, REGISTER_X); // a^2*x into X, a*x -> Y, x -> Z
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_X);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_Y);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_Z);
    frontier_register_value_conversions.convertComplexRegisterToRealIfZeroImag(REGISTER_L);
    temporaryInformation = TI_ABC;
}

pub export fn fnCopyXtoAbc(unusedButMandatoryParameter: u16) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (option_elec) fnCopyXtoAbcCore() catch |e| reportError(e);
}
