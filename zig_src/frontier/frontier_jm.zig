// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/c47Extensions/jm.c: fnSigmaAssign (assign the +NRM key),
// flipPolar, fnJM (the ELEC RPN-program dispatcher) plus the PC-only telltale
// helpers jm_show_calc_state / jm_show_comment. This is a faithful, line-by-line
// port of the C.
//
// fnJM's body is gated on OPTION_ELEC: upstream defines.h enables it for the host
// build and for DMCP package 3 / DMCP5, and #undef's it for the flash-limited
// DMCP packages 1, 2 and 4. The frontier object is compiled once per package, so
// the gate is carried through the frontier_build_options.option_elec flag (set by
// firmware.zig's frontierDistributionStrip). When OPTION_ELEC is off the function
// is the empty "item 255 is NOP" stub, exactly like the C.
//
// jm_show_calc_state / jm_show_comment are #if PC_BUILD in the C and the
// PC_BUILD_TELLTALE / PC_BUILD_VERBOSE2 inner blocks are never enabled for the z47
// host build, so both reduce to empty bodies on the host and are absent on
// firmware (gated on !dmcp_build). They are referenced by many other files on the
// host, so they must be provided there.
//
// jm.c is not reachable from the testSuite; verification is by build/link across
// every target plus the boundary gates.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const option_elec: bool = frontier_build_options.option_elec;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------
const bool_t = bool;
const calcRegister_t = i16;
const angularMode_t = c_int;

const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const frontier_addons = @import("frontier_addons.zig"); // M-callconv: Zig-to-Zig
const frontier_error = @import("frontier_error.zig"); // M-callconv: Zig-to-Zig
const frontier_radio_button_catalog = @import("frontier_radio_button_catalog.zig"); // M-callconv: Zig-to-Zig
const frontier_register_value_conversions = @import("frontier_register_value_conversions.zig"); // M-callconv: Zig-to-Zig
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const normKey_t = abi.NormKey;
const calcKey_t = abi.CalcKey;

// ---------------------------------------------------------------------------
// Constants / enum values (verified against defines.h / typeDefinitions.h)
// ---------------------------------------------------------------------------
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_L: calcRegister_t = 108;
const REGISTER_I: calcRegister_t = 109;
const REGISTER_J: calcRegister_t = 110;
const REGISTER_K: calcRegister_t = 111;
const TEMP_REGISTER_1: calcRegister_t = 135;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const dtComplex34: u32 = 2;

const amNone: angularMode_t = 5;
const amPolar: u32 = 16;

const FLAG_USER: u16 = 0x8014;
const FLAG_ASLIFT: u16 = 0xc023;

const ERROR_CANNOT_ASSIGN_HERE: u8 = 47;

const TI_ABC: u8 = 72;
const TI_ABBCCA: u8 = 73;
const TI_012: u8 = 74;

// calcModel values (defines.h).
const USER_DM42: u8 = 45;
const USER_C47: u8 = 46;
const USER_R47f_g: u8 = 61;
const USER_R47bk_fg: u8 = 62;
const USER_R47fg_bk: u8 = 63;
const USER_R47fg_g: u8 = 64;

// fnJM register #defines.
const JMTEMP: calcRegister_t = TEMP_REGISTER_1; // 135
const JM_TEMP_I: calcRegister_t = REGISTER_I; // 109
const JM_TEMP_J: calcRegister_t = REGISTER_J; // 110
const JM_TEMP_K: calcRegister_t = REGISTER_K; // 111

const TripleRegZ1_96: c_int = 96;
const TripleRegZ2_97: c_int = 97;
const TripleRegZ3_98: c_int = 98;
const TripleRegV1_90: c_int = 90;
const TripleRegV2_91: c_int = 91;
const TripleRegV3_92: c_int = 92;
const TripleRegI1_93: c_int = 93;
const TripleRegI2_94: c_int = 94;
const TripleRegI3_95: c_int = 95;

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var calcModel: u8;
extern var temporaryInformation: u8;
extern var ctxtReal34: realContext_t;
extern var Norm_Key_00: normKey_t;

extern const kbd_std_C47: [37]calcKey_t;
extern const kbd_std_DM42: [37]calcKey_t;
extern const kbd_std_R47f_g: [37]calcKey_t;
extern const kbd_std_R47bk_fg: [37]calcKey_t;
extern const kbd_std_R47fg_bk: [37]calcKey_t;
extern const kbd_std_R47fg_g: [37]calcKey_t;

// ---------------------------------------------------------------------------
// Function externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;

extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn adjustResult(result: calcRegister_t, dropY: bool_t, setCpxRes: bool_t, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn saveForUndo() void;
extern fn liftStack() void;
extern fn setSystemFlag(flag: u16) void;

extern fn fnClearFlag(flag: u16) void;

extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;

// fn* item handlers: all have the void(uint16_t) C ABI.
extern fn fnAdd(p: u16) void;
extern fn fnMultiply(p: u16) void;
extern fn fnDivide(p: u16) void;
extern fn fnSwapXY(p: u16) void;
const FnU16 = *const fn (p: u16) callconv(.c) void;
const c_fnSwapX = @extern(FnU16, .{ .name = "fnSwapX" });
const c_fnRCL = @extern(FnU16, .{ .name = "fnRCL" });
const c_fn3Sto = @extern(FnU16, .{ .name = "fn3Sto" });

extern fn fnToRect2(p: u16) void;

// These three are called with register codes (int/int16); the C ABI param is
// uint16_t, so truncate exactly as the implicit C conversion does.
inline fn fnSwapX(regist: anytype) void {
    c_fnSwapX(@bitCast(@as(i16, @intCast(regist))));
}
inline fn fnRCL(regist: anytype) void {
    c_fnRCL(@bitCast(@as(i16, @intCast(regist))));
}
inline fn fn3Sto(regist: anytype) void {
    c_fn3Sto(@bitCast(@as(i16, @intCast(regist))));
}

// decQuad (real34) helpers.
extern fn decQuadFromString(r: *real34_t, str: [*:0]const u8, ctx: *realContext_t) *real34_t;

// ---------------------------------------------------------------------------
// Inline wrappers (the C macros)
// ---------------------------------------------------------------------------
const reg34 = abi.registerReal34Aligned;
// REGISTER_IMAG34_DATA(a) = getRegisterDataPointer(a) + REAL34_SIZE_IN_BYTES (16).
const regImag34 = abi.registerImag34Aligned;
inline fn stringToReal34(source: [*:0]const u8, destination: *real34_t) void {
    _ = decQuadFromString(destination, source, &ctxtReal34);
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}
inline fn setComplexRegisterPolarMode(reg: calcRegister_t, pm: u32) void {
    // setRegisterTag(reg, (((pm & amPolar) != 0) ? (getRegisterTag(reg) & amAngleMask) : amNone) | (pm & amPolar))
    const base: u32 = if ((pm & amPolar) != 0) (getRegisterTag(reg) & 15) else @as(u32, @intCast(amNone));
    setRegisterTag(reg, base | (pm & amPolar));
}

// kbd_std model-selection macro (c47.h). Only the DMCP-buildable model variants
// are referenced (the PC-only E47/D47/V47/N47 forms are not used by jm.c).
inline fn kbdStd() [*]const calcKey_t {
    if (calcModel == USER_C47) return &kbd_std_C47;
    if (calcModel == USER_DM42) return &kbd_std_DM42;
    if (calcModel == USER_R47f_g) return &kbd_std_R47f_g;
    if (calcModel == USER_R47bk_fg) return &kbd_std_R47bk_fg;
    if (calcModel == USER_R47fg_bk) return &kbd_std_R47fg_bk;
    if (calcModel == USER_R47fg_g) return &kbd_std_R47fg_g;
    return &kbd_std_C47;
}
// Norm_Key_00_key (defines.h:554).
inline fn normKey00Key() i16 {
    return if (calcModel == USER_C47) 0 else if (calcModel == USER_DM42) 0 else if (calcModel == USER_R47f_g) -1 else if (calcModel == USER_R47bk_fg) 10 else if (calcModel == USER_R47fg_bk) 11 else -1;
}

inline fn moreInfoOnErr(m1: [*:0]const u8, m2: [*:0]const u8) void {
    if (comptime extra_info) {
        moreInfoOnError(m1, m2, null, null);
    }
}

// ---------------------------------------------------------------------------
// nprimes — defined in jm.c (uint16_t nprimes = 0).
// ---------------------------------------------------------------------------
pub export var nprimes: u16 = 0;

// ===========================================================================
// jm_show_calc_state / jm_show_comment (PC_BUILD only; telltale/verbose blocks
// are never enabled for the z47 host build, so both are empty on host, absent on
// firmware).
// ===========================================================================
fn jmShowCalcStateImpl(comment: [*c]u8) callconv(.c) void {
    _ = comment;
}
fn jmShowCommentImpl(comment: [*c]u8) callconv(.c) void {
    _ = comment;
}
comptime {
    if (!dmcp_build) {
        @export(&jmShowCalcStateImpl, .{ .name = "jm_show_calc_state", .linkage = .strong });
        @export(&jmShowCommentImpl, .{ .name = "jm_show_comment", .linkage = .strong });
    }
}

// ===========================================================================
// fnSigmaAssign
// ===========================================================================
pub export fn fnSigmaAssign(sigmaAssign: u16) callconv(.c) void {
    if (normKey00Key() != -1) {
        const tt: i16 = @bitCast(sigmaAssign);
        Norm_Key_00.func = tt -% 16384;
        Norm_Key_00.funcParam[0] = 0;
        Norm_Key_00.used = Norm_Key_00.func != kbdStd()[@intCast(normKey00Key())].primary;
        frontier_radio_button_catalog.fnRefreshState();
        fnClearFlag(FLAG_USER);
    } else {
        Norm_Key_00.used = false;
        frontier_error.displayCalcErrorMessage(ERROR_CANNOT_ASSIGN_HERE, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        moreInfoOnErr("In function fnSigmaAssign: ", "the NRM key is not available.");
    }
}

// ===========================================================================
// flipPolar
// ===========================================================================
pub export fn flipPolar() callconv(.c) void {
    var zReal: real_t = undefined;
    var zImag: real_t = undefined;
    if (getRegisterDataType(REGISTER_X) != dtComplex34) {
        if (!frontier_register_value_conversions.getRegisterAsComplex(REGISTER_X, &zReal, &zImag)) {
            return;
        }
        frontier_register_value_conversions.convertComplexToResultRegister(&zReal, &zImag, REGISTER_X);
        return;
    }

    if (getComplexRegisterPolarMode(REGISTER_X) != amPolar) {
        setComplexRegisterPolarMode(REGISTER_X, amPolar);
    } else {
        fnToRect2(9876); // NOPARAM
    }
}

// ===========================================================================
// fnJM (body gated on OPTION_ELEC)
// ===========================================================================
pub export fn fnJM(JM_OPCODE: u16) callconv(.c) void {
    if (comptime !option_elec) {
        return; // Item 255 is NOP
    }

    if (JM_OPCODE == 6) { // Delta to Star
        saveForUndo();
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);
        copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);
        copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);
        fnAdd(0);
        fnSwapXY(0);

        fnAdd(0);
        copySourceRegisterToDestRegister(REGISTER_X, JMTEMP);
        fnRCL(JM_TEMP_K);
        fnRCL(JM_TEMP_J);
        fnMultiply(0);
        fnSwapXY(0);
        fnDivide(0);

        fnRCL(JMTEMP);
        fnRCL(JM_TEMP_I);
        fnRCL(JM_TEMP_J);
        fnMultiply(0);
        fnSwapXY(0);
        fnDivide(0);

        fnRCL(JMTEMP);
        fnRCL(JM_TEMP_I);
        fnRCL(JM_TEMP_K);
        fnMultiply(0);
        fnSwapXY(0);
        fnDivide(0);

        copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);

        temporaryInformation = TI_ABC;

        adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
        adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
        adjustResult(REGISTER_Z, false, true, REGISTER_Z, -1, -1);
    } else if (JM_OPCODE == 7) { // Star to Delta
        saveForUndo();
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);
        copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);
        copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);

        fnMultiply(0);
        fnSwapXY(0);
        fnRCL(JM_TEMP_I);
        fnMultiply(0);
        fnAdd(0);
        fnRCL(JM_TEMP_J);
        fnRCL(JM_TEMP_K);
        fnMultiply(0);
        fnAdd(0);
        copySourceRegisterToDestRegister(REGISTER_X, JMTEMP);

        fnRCL(JM_TEMP_J);
        fnDivide(0);

        fnRCL(JMTEMP);
        fnRCL(JM_TEMP_I);
        fnDivide(0);

        fnRCL(JMTEMP);
        fnRCL(JM_TEMP_K);
        fnDivide(0);

        copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);

        temporaryInformation = TI_ABBCCA;
        adjustResult(REGISTER_X, false, true, REGISTER_X, -1, -1);
        adjustResult(REGISTER_Y, false, true, REGISTER_Y, -1, -1);
        adjustResult(REGISTER_Z, false, true, REGISTER_Z, -1, -1);
    } else if (JM_OPCODE == 8) { // SYMMETRICAL COMP to ABC
        saveForUndo();
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);
        copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);
        copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);
        fnAdd(0);
        fnAdd(0);

        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_a(0);
        fnRCL(JM_TEMP_I);
        fnMultiply(0);
        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_aa(0);
        fnRCL(JM_TEMP_J);
        fnMultiply(0);
        fnAdd(0);
        fnRCL(JM_TEMP_K);
        fnAdd(0);

        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_aa(0);
        fnRCL(JM_TEMP_I);
        fnMultiply(0);
        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_a(0);
        fnRCL(JM_TEMP_J);
        fnMultiply(0);
        fnAdd(0);
        fnRCL(JM_TEMP_K);
        fnAdd(0);

        copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);

        temporaryInformation = TI_ABC;
    } else if (JM_OPCODE == 9) { // ABC to SYMMETRICAL COMP
        saveForUndo();
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);
        copySourceRegisterToDestRegister(REGISTER_Y, JM_TEMP_J);
        copySourceRegisterToDestRegister(REGISTER_Z, JM_TEMP_K);
        fnAdd(0);
        fnAdd(0);
        liftStack();
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        stringToReal34("3", reg34(REGISTER_X));
        stringToReal34("0", regImag34(REGISTER_X));
        copySourceRegisterToDestRegister(REGISTER_X, JMTEMP);
        fnDivide(0);

        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_a(0);
        fnRCL(JM_TEMP_J);
        fnMultiply(0);
        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_aa(0);
        fnRCL(JM_TEMP_I);
        fnMultiply(0);
        fnAdd(0);
        fnRCL(JM_TEMP_K);
        fnAdd(0);
        fnRCL(JMTEMP);
        fnDivide(0);

        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_aa(0);
        fnRCL(JM_TEMP_J);
        fnMultiply(0);
        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_a(0);
        fnRCL(JM_TEMP_I);
        fnMultiply(0);
        fnAdd(0);
        fnRCL(JM_TEMP_K);
        fnAdd(0);
        fnRCL(JMTEMP);
        fnDivide(0);

        copySourceRegisterToDestRegister(JM_TEMP_I, REGISTER_L);

        temporaryInformation = TI_012;
    } else if (JM_OPCODE == 17) { // V/I
        saveForUndo();
        fnRCL(TripleRegV3_92);
        fnRCL(TripleRegI3_95);
        fnDivide(0);
        fnRCL(TripleRegV2_91);
        fnRCL(TripleRegI2_94);
        fnDivide(0);
        fnRCL(TripleRegV1_90);
        fnRCL(TripleRegI1_93);
        fnDivide(0);
        fn3Sto(TripleRegZ1_96);
    } else if (JM_OPCODE == 18) { // IZ
        saveForUndo();
        fnRCL(TripleRegI3_95);
        fnRCL(TripleRegZ3_98);
        fnMultiply(0);
        fnRCL(TripleRegI2_94);
        fnRCL(TripleRegZ2_97);
        fnMultiply(0);
        fnRCL(TripleRegI1_93);
        fnRCL(TripleRegZ1_96);
        fnMultiply(0);
        fn3Sto(TripleRegV1_90);
    } else if (JM_OPCODE == 19) { // V/Z
        saveForUndo();
        fnRCL(TripleRegV3_92);
        fnRCL(TripleRegZ3_98);
        fnDivide(0);
        fnRCL(TripleRegV2_91);
        fnRCL(TripleRegZ2_97);
        fnDivide(0);
        fnRCL(TripleRegV1_90);
        fnRCL(TripleRegZ1_96);
        fnDivide(0);
        fn3Sto(TripleRegI1_93);
    } else if (JM_OPCODE == 20) { // Copy Create X>ABC
        saveForUndo();
        setSystemFlag(FLAG_ASLIFT);
        copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_I);

        fnRCL(JM_TEMP_I);
        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_a(0);
        fnMultiply(0);

        fnRCL(JM_TEMP_I);
        setSystemFlag(FLAG_ASLIFT);
        frontier_addons.fn_cnst_op_aa(0);
        copySourceRegisterToDestRegister(REGISTER_X, JM_TEMP_J);
        fnMultiply(0);

        temporaryInformation = TI_ABC;
    } else if (JM_OPCODE == 21) { // V/Z
        saveForUndo();
        flipPolar();
        fnSwapX(REGISTER_Y);
        flipPolar();
        fnSwapX(REGISTER_Y);
        fnSwapX(REGISTER_Z);
        flipPolar();
        fnSwapX(REGISTER_Z);
    }
    // Item 255 is NOP
}
