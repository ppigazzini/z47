const std = @import("std");
const consts = abi.constants;
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/ui/matrixEditor.c — the *residue* of the matrix editor
// that the sibling matrix_* owners do NOT already provide.
//
// Division of labour (verified by grep across zig_src/frontier/):
//   * The ~30 PUBLIC matrixEditor.c functions (fnEditMatrix, fnOldMatrix,
//     fnGoToElement, fnGoToRow, fnGoToColumn, fnSetGrowMode, fnIncDecI,
//     fnIncDecJ, fnInsRow, fnAddRow, fnInsCol, fnAddCol, fnDelRow, fnDelCol,
//     getIRegisterAsInt, getJRegisterAsInt, setIRegisterAsInt,
//     setJRegisterAsInt, wrapIJ, _fnInsRow, _fnInsCol, mimFinalize, mimRestore,
//     mimAddNumber, mimRunFunction, showMatrixEditor, mimEnter) are reimplemented
//     in Zig and exported by frontier.zig (which dispatches into the matrix_*
//     module owners: matrix_editor_entry, matrix_editor_refresh, matrix_nav,
//     matrix_goto_grow, matrix_lifecycle, matrix_mim_add, matrix_mim_run,
//     matrix_mutation). The matrix_editor_legacy.c shim #defines those names away
//     to z47_frontier_legacy_* so the C bodies never collide. Those legacy
//     symbols are dead (nothing references z47_frontier_legacy_<matrix>).
//     => This owner does NOT export any of them.
//
//   * What the legacy object STILL provided to the link and no Zig owner did:
//       (a) the 4 NON-renamed publics of matrixEditor.c:
//           showRealMatrix, showComplexMatrix, getRealMatrixColumnWidths,
//           getComplexMatrixColumnWidths;
//       (b) the file-scope globals: openMatrixMIMPointer, matEditMode, scrollRow,
//           scrollColumn, tmpRow, matrixIndex (the sibling owners declare these
//           `extern` — calc_mode_owned, goto_grow_owned, etc. — but the
//           DEFINITION lived in the legacy object);
//       (c) all 49 z47_frontier_matrix_* bridge helpers the sibling modules call
//           (defined ONLY in the shim, declared `extern fn` by the siblings).
//     => This owner provides (a)+(b)+(c). It is, in effect, the rest of
//        matrixEditor.c plus the bridge layer.
//
// Build flavour, matching the sibling owners and the dominant C config:
//   OPTION_VECTOR is ON (defines.h:70; only #undef'd in space-saving DMCP
//   packages). OPTION_VECTOR_EDIT is OFF (defines.h:73). IR_PRINTING trace blocks
//   are omitted (siblings treat it as never defined). The PC_BUILD refreshLcd()
//   tail of mimRunFunction is host-only (!dmcp_build). EXTRA_INFO_ON_CALC_ERROR
//   console hints are gated on extra_info && !dmcp_build — but those all live in
//   the renamed publics, which are elsewhere, so none appear here.
//
// matrixEditor.c is not reachable from the testSuite directly; verification is
// build/link across every target plus the distributions/boundary gates. The
// render/show code is exercised via the matrix_editor_refresh owner which calls
// z47_frontier_matrix_render_editor_body -> showRealMatrix/showComplexMatrix.

const builtin = @import("builtin");
const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const old_hw: bool = frontier_build_options.old_hw;

const LIBRARY_FN_BASE: usize = if (old_hw) 0x08000201 else 0x08000301;

const code_section = if (dmcp_build and old_hw)
    ".qspi_data"
else if (builtin.target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// ===========================================================================
// Types (reused verbatim from frontier_calc_mode_owned.zig so the union/struct
// layout matches the siblings' externs exactly).
// ===========================================================================
const bool_t = bool;
const calcRegister_t = i16;
const angularMode_t = c_int; // C enum -> int ABI
const videoMode_t = c_int;
const real34_t = abi.Real34;
const complex34_t = extern struct { re: real34_t, im: real34_t };
// decNumber (real_t): big enough working buffer. The matrix display code only
// passes real_t by pointer to extern helpers and never inspects the layout, but
// we still need a correctly-sized storage type for the on-stack `aa,bb,cc,theta`
// locals. DECNUMDIGITS=75 -> lsu has ceil(75/3)=25 units (uint16). Header is
// digits(i32)+exponent(i32)+bits(u8)+pad. Use the canonical c47 layout.
const decNumberUnit = u16;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = opaque {};
const decContext = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};
const font_t = opaque {};

const matrixHeader_t = packed struct(u32) {
    matrixRows: u12,
    matrixColumns: u12,
    mtag: u6,
    notUsed: u2,
};
const real34Matrix_t = extern struct {
    header: matrixHeader_t,
    matrixElements: ?[*]real34_t,
};
const complex34Matrix_t = extern struct {
    header: matrixHeader_t,
    matrixElements: ?[*]complex34_t,
};
const AnyMatrix = extern union {
    header: matrixHeader_t,
    realMatrix: real34Matrix_t,
    complexMatrix: complex34Matrix_t,
};

// ===========================================================================
// Constants (verified against defines.h / typeDefinitions.h / items.h /
// display.h / fonts.h / matrixEditor.h).
// ===========================================================================
const INVALID_VARIABLE: u16 = 2199;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

const amNone: angularMode_t = 5;
const amRadian: angularMode_t = 0;
const amPolar: u32 = 16;
const amAngleMask: u6 = 15;

const DEC_FLAG: u16 = 1;
const DEC_ROUND_DOWN: c_int = 5;

const FLAG_POLAR: c_int = 0x8006;
const FLAG_MULTx: c_int = 0x801b;
const FLAG_ENGOVR: c_int = 0x801c;
const FLAG_GROW: c_int = 0x801d;
const FLAG_WRAPEND: c_int = 0xc01a;
const FLAG_ASLIFT: c_int = 0xc023;
const FLAG_WRAPEDG: c_int = 0xc03F;
const FLAG_IRFRAC: c_int = 0x8047;
const FLAG_3DPHYS: c_int = 0x8065;

const MNU_M_EDIT: i16 = 1348;

const ITM_ENTER: i16 = 35;
const ITM_CHS: i16 = 97;
const ITM_CONSTpi: i16 = 109;
const ITM_PERIOD: i16 = 820;
const ITM_EXPONENT: i16 = 990;
const ITM_M_GOTO_ROW: i16 = 992;
const ITM_0: i16 = 540;
const ITM_9: i16 = 549;
const ITM_CC: i16 = 1730;
const ITM_BACKSPACE: i16 = 1738;
const ITM_op_j_pol: i16 = 1795;
const ITM_op_j: i16 = 1830;
const NOPARAM: u16 = 9876;

const NP_INT_10: u8 = 1;
const NP_REAL_FLOAT_PART: u8 = 4;
const NP_FRACTION_DENOMINATOR: u8 = 6;
const NP_COMPLEX_INT_PART: u8 = 7;
const NP_COMPLEX_FLOAT_PART: u8 = 8;
const NP_COMPLEX_EXPONENT: u8 = 9;
const NP_HP32SII_DENOMINATOR: u8 = 10;
const NP_COMPLEX_FRACTION_DENOMINATOR: u8 = 11;
const NP_COMPLEX_HP32SII_DENOMINATOR: u8 = 12;

const TI_SHOW_REGISTER: u8 = 14;
const CM_MIM: u8 = 12;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_I: calcRegister_t = 109;
const REGISTER_J: calcRegister_t = 110;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const Y_POSITION_OF_NIM_LINE: u32 = 132;
const Y_POSITION_OF_REGISTER_X_LINE: i16 = 132;
const Y_POSITION_OF_REGISTER_T_LINE: i16 = 24;
const REGISTER_LINE_HEIGHT: i16 = 36;
const SCREEN_WIDTH: i16 = 400;
const NUMBER_OF_DISPLAY_DIGITS: i16 = 20;
const SOFTMENU_STACK_SIZE: usize = 8;
const SHOWLineSize: usize = 120;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;
const ERROR_OPERATION_UNDEFINED: u8 = 13;

const NUMERIC_FONT_HEIGHT: i16 = 36;
const STANDARD_FONT_HEIGHT: i16 = 22;
const NUMERIC_FONT_HEIGHT_: i16 = NUMERIC_FONT_HEIGHT - 4;
const STANDARD_FONT_HEIGHT_: i16 = STANDARD_FONT_HEIGHT - 2;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;

// irfracOption_t (display.h): LIMITIRFRAC=1, LIGHTIRFRAC=2.
const irfracOption_t = c_int;
const LIMITIRFRAC: irfracOption_t = 1;
const LIGHTIRFRAC: irfracOption_t = 2;
const LIMITEXP: bool_t = true;
const FRONTSPACE: bool_t = true;

const LCD_EMPTY_VALUE: c_int = 0xFF;

// matrixEditor.h
const MATRIX_LINE_WIDTH: i16 = 380;
const MATRIX_MAX_ROWS: usize = 5;
const MATRIX_MAX_COLUMNS: usize = 11;

// regXp / toDisplayVectorMatrix are `#define ... true` in matrix.h.
const regXp: bool_t = true;
const toDisplayVectorMatrix: bool_t = true;

// addFlag macro.
const addFlag: bool_t = true;

// String constants (fonts.h byte sequences).
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SPACE_FIGURE = "\xa0\x07";
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_ELLIPSIS = "\xa0\x26";
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_10 = "\xa4\x7d";
const STD_MAT_TL = "\xa3\xa1";
const STD_MAT_ML = "\xa3\xa2";
const STD_MAT_BL = "\xa3\xa3";
const STD_MAT_TR = "\xa3\xa4";
const STD_MAT_MR = "\xa3\xa5";
const STD_MAT_BR = "\xa3\xa6";
const STD_SUP_BOLD_T = "\x9d\x40";
const STD_SUP_c = "\xa4\x84";
const STD_SUP_p = "\xa4\x91";
const STD_SUP_s = "\xa4\x94";
const STD_MEASURED_ANGLE = "\xa2\x21";
const STD_DOT = "\x80\xb7";
const STD_CROSS = "\x80\xd7";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const FLAG_CPXj: c_int = 0x8005;

// ===========================================================================
// Globals — DEFINED HERE (the siblings declare these `extern`).
// matEditMode is file-local in matrixEditor.c and referenced nowhere else; we
// still export it so the legacy symbol set is preserved exactly.
// ===========================================================================
// These are mutable RAM globals (matrixEditor.c file-scope, normal .data/.bss);
// they must NOT go into .qspi (read-only XIP flash). Default section.
// C's `any34Matrix_t openMatrixMIMPointer;` is a file-scope global -> .bss
// ZERO-initialized, so .realMatrix.matrixElements starts NULL. `= undefined`
// would leave garbage: getMatrixFromRegister's `matrixElements != null` guard
// then passes on the first edit and frees a wild pointer (freeC47Blocks ->
// toC47MemPtr @intCast panic in Debug / heap corruption in ReleaseFast). Match
// C's zero-init.
pub export var openMatrixMIMPointer: AnyMatrix = std.mem.zeroes(AnyMatrix);
pub export var matEditMode: bool_t = false;
pub export var scrollRow: u16 = 0;
pub export var scrollColumn: u16 = 0;
pub export var tmpRow: u16 = 0;
pub export var matrixIndex: u16 = INVALID_VARIABLE;

// ===========================================================================
// External globals (c47 owns these).
// ===========================================================================
extern var calcMode: u8;
extern var lastErrorCode: u8;
extern var cursorEnabled: u8;
extern var xCursor: u32;
extern var yCursor: u32;
extern var cursorFont: *const font_t;
extern var aimBuffer: [*c]u8;
extern var nimBufferDisplay: [*c]u8;
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var errorMessageRegisterLine: calcRegister_t;
extern var nimNumberPart: u8;
extern var lastDenominator: u32;
extern var temporaryInformation: u8;
extern var temporaryFlagRect: bool_t;
extern var temporaryFlagPolar: bool_t;
extern var currentAngularMode: angularMode_t;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var exponentLimit: i16;

extern const numericFont: font_t;
extern const standardFont: font_t;

// ctxtReal39 is a realContext_t value; referenced only by address.
extern var ctxtReal39: realContext_t;

// const39_pi / const39_piOn2 / const_0 are `#define`s into the shared
// `constants` byte blob ((real_t *)(constants + offset)), NOT linkable symbols.
// Bind the blob by address and index by the generated byte offsets, matching
// frontier_conversion_angles_owned.zig.
const constants = @extern([*]const u8, .{ .name = "constants" });
const cstReal = consts.cstR;
const OFF_const39_pi: u32 = 1848;
const OFF_const39_piOn2: u32 = 4880;
const OFF_const_0: u32 = 1708;
const const39_pi = cstReal(OFF_const39_pi);
const const39_piOn2 = cstReal(OFF_const39_piOn2);
const const_0 = cstReal(OFF_const_0);

const softmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    softkeyItem: [*c]const i16,
};
const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};
const softmenu = @extern([*]const softmenu_t, .{ .name = "softmenu" });
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;

// ===========================================================================
// External functions.
// ===========================================================================
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;

extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool_t;

extern fn hideCursor() void;
extern fn clearRegisterLine(regist: calcRegister_t, clearTop: bool_t, clearBottom: bool_t) void;
extern fn refreshRegisterLine(regist: calcRegister_t) void;
extern fn updateMatrixHeightCache() void;
extern fn setLastintegerBasetoZero() void;
extern fn showSoftmenu(id: i16) void;
extern fn mimShowElement() void;

extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: videoMode_t, showLeadingCols: bool_t, showEndingCols: bool_t) u32;
extern fn stringWidth(str: [*c]const u8, font: *const font_t, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) i16;
extern fn displayNim(nim: [*c]const u8, lastBase: [*c]const u8, wLastBaseNumeric: i16, wLastBaseStandard: i16) void;
extern fn real34ToDisplayString(real34: *const real34_t, tag: u32, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: irfracOption_t) void;
extern fn complex34ToDisplayString(complex34: *const complex34_t, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: irfracOption_t, tagAngle: u16, tagPolar: bool_t) void;

extern fn addItemToNimBuffer(item: i16) void;
extern fn closeNimWithFraction(dest: *real34_t) void;
extern fn closeNimWithComplex(dest_r: *real34_t, dest_i: *real34_t) void;
extern fn reallyRunFunction(func: i16, param: u16) void;

extern fn real34IsAnInteger(x: *const real34_t) bool_t;
extern fn realCompareLessThan(n1: *const real_t, n2: *const real_t) bool_t;
extern fn decQuadZero(r: *real34_t) *real34_t;
extern fn decQuadFromInt32(r: *real34_t, v: i32) *real34_t;
extern fn decQuadFromString(r: *real34_t, s: [*c]const u8, ctx: *const realContext_t) *real34_t;
// decQuadFromNumber / decQuadToNumber are `#define`s over the linkable
// decimal128 functions (decQuad.h); bind the real symbols.
extern fn decimal128FromNumber(r: *real34_t, n: *align(1) const real_t, ctx: *const realContext_t) *real34_t;
extern fn decimal128ToNumber(r: *const real34_t, n: *real_t) *real_t;
extern fn decNumberCopy(dst: *real_t, src: *align(1) const real_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *const real_t, b: *const real_t, ctx: *const realContext_t) *real_t;
extern var ctxtReal34: realContext_t;

extern fn realRectangularToPolar(real: *const real_t, imag: *const real_t, magnitude: *real_t, theta: *real_t, ctx: *const realContext_t) void;
extern fn realPolarToRectangular(magnitude: *const real_t, theta: *const real_t, real: *real_t, imag: *real_t, ctx: *const realContext_t) void;
extern fn convertAngleFromTo(angle: *real_t, fromAngularMode: angularMode_t, toAngularMode: angularMode_t, ctx: *const realContext_t) void;

extern fn convert3DtoSPH(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, th2: *real_t, am: u8, ctx: *const decContext) void;
extern fn convert3DtoCYL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, z: *real_t, am: u8, ctx: *const decContext) void;
extern fn convert2DtoPOL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, am: u8, ctx: *const decContext) void;

extern fn convertReal34MatrixToComplex34Matrix(source: *const real34Matrix_t, destination: *complex34Matrix_t) void;
extern fn realMatrixFree(matrix: *real34Matrix_t) void;
extern fn complexMatrixFree(matrix: *complex34Matrix_t) void;
extern fn convertComplex34MatrixToComplex34MatrixRegister(matrix: *const complex34Matrix_t, regist: calcRegister_t) void;
extern fn convertReal34MatrixToReal34MatrixRegister(matrix: *const real34Matrix_t, regist: calcRegister_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, linkedMatrix: *complex34Matrix_t) void;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, linkedMatrix: *real34Matrix_t) void;
extern fn insRowRealMatrix(matrix: *real34Matrix_t, beforeRowNo: u16, add: bool_t) void;
extern fn insRowComplexMatrix(matrix: *complex34Matrix_t, beforeRowNo: u16, add: bool_t) void;
extern fn insColRealMatrix(matrix: *real34Matrix_t, beforeColNo: u16, add: bool_t) void;
extern fn insColComplexMatrix(matrix: *complex34Matrix_t, beforeColNo: u16, add: bool_t) void;
extern fn delRowRealMatrix(matrix: *real34Matrix_t, rowNo: u16) void;
extern fn delRowComplexMatrix(matrix: *complex34Matrix_t, rowNo: u16) void;
extern fn delColRealMatrix(matrix: *real34Matrix_t, colNo: u16) void;
extern fn delColComplexMatrix(matrix: *complex34Matrix_t, colNo: u16) void;
extern fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;

extern fn getRegisterTag(regist: calcRegister_t) u32;

// isRegisterMatrixVector / getVectorRegisterPolarMode are `#define` macros in
// registers.h (not linkable symbols); reproduce them inline.
// isMatrix2dVector / isMatrix3dVector (defines.h).
inline fn isMatrix2dVectorRC(rows: u32, cols: u32) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}
inline fn isMatrix3dVectorRC(rows: u32, cols: u32) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}
inline fn registerMatrixHeader(regist: calcRegister_t) *align(1) const matrixHeader_t {
    return @ptrCast(getRegisterDataPointer(regist));
}
inline fn isRegisterMatrix3dVector(regist: calcRegister_t) bool {
    if (getRegisterDataType(regist) != dtReal34Matrix) return false;
    const h = registerMatrixHeader(regist);
    return isMatrix3dVectorRC(h.matrixRows, h.matrixColumns);
}
inline fn isRegisterMatrix2dVector(regist: calcRegister_t) bool {
    if (getRegisterDataType(regist) != dtReal34Matrix) return false;
    const h = registerMatrixHeader(regist);
    return isMatrix2dVectorRC(h.matrixRows, h.matrixColumns);
}
inline fn isRegisterMatrixVector(regist: calcRegister_t) bool_t {
    return isRegisterMatrix3dVector(regist) or isRegisterMatrix2dVector(regist);
}
const amPolarSPH: u16 = 128; // virtual bit (registers.h)
const amPolarCYL: u16 = 64; // virtual bit (registers.h)
inline fn getVectorRegisterPolarMode(regist: calcRegister_t) u16 {
    if ((getRegisterDataType(regist) == dtReal34Matrix) and ((getRegisterTag(regist) & amAngleMask) != amNone)) {
        if (isRegisterMatrix3dVector(regist)) {
            return if ((getRegisterTag(regist) & amPolar) == amPolar) amPolarSPH else amPolarCYL;
        } else if (isRegisterMatrix2dVector(regist)) {
            return @intCast(getRegisterTag(regist) & amPolar);
        } else {
            return 0;
        }
    }
    return 0;
}

// longInteger (GMP mpz_t) helpers used by getRegisterAsInt/setRegisterAsInt.
// mpz_t is __mpz_struct[1]; a longInteger_t value decays to mpz_ptr
// (= *__mpz_struct). We store one __mpz_struct and pass its address.
const MpzStruct = extern struct { mp_alloc: c_int, mp_size: c_int, mp_d: ?*anyopaque };
extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, longInteger: *MpzStruct) void;
extern fn convertReal34ToLongInteger(real34: *const real34_t, lgInt: *MpzStruct, mode: c_int) void;
extern fn convertLongIntegerToLongIntegerRegister(longInteger: *const MpzStruct, regist: calcRegister_t) void;
extern fn __gmpz_init(op: *MpzStruct) void;
extern fn __gmpz_clear(op: *MpzStruct) void;
extern fn __gmpz_get_si(op: *const MpzStruct) c_long;
extern fn __gmpz_set_si(op: *MpzStruct, v: c_long) void;

// libc.
extern fn strlen(s: [*c]const u8) usize;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strstr(haystack: [*c]const u8, needle: [*c]const u8) [*c]u8;
extern fn sprintf(buf: [*c]u8, fmt: [*c]const u8, ...) c_int;

// lcd_fill_rect — DMCP SDK fixed-address library call on firmware
// (LIBRARY_FN_BASE + 60); real symbol on host. (Mirrors asn_browser owner.)
const LcdFillRectFn = *const fn (x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void;
const c_lcd_fill_rect = @extern(LcdFillRectFn, .{ .name = "lcd_fill_rect" });
inline fn lcdFillRect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) void {
    if (comptime dmcp_build) {
        const f: LcdFillRectFn = @ptrFromInt(LIBRARY_FN_BASE + 60);
        f(x, y, dx, dy, val);
    } else {
        c_lcd_fill_rect(x, y, dx, dy, val);
    }
}

// ===========================================================================
// Macro-equivalent inline helpers.
// ===========================================================================
// calcModeNormalGui: empty macro on firmware (hal/gui.h), real symbol on host.
const VoidFn = *const fn () callconv(.c) void;
inline fn calcModeNormalGui() void {
    if (comptime !dmcp_build) @extern(VoidFn, .{ .name = "calcModeNormalGui" })();
}

inline fn real34SetZero(d: *real34_t) void {
    _ = decQuadZero(d);
}
inline fn real34SetOne(d: *real34_t) void {
    _ = decQuadFromInt32(d, 1);
}
inline fn real34Copy(src: *const real34_t, dst: *real34_t) void {
    dst.* = src.*;
}
inline fn complex34Copy(src: *const complex34_t, dst: *complex34_t) void {
    dst.* = src.*;
}
inline fn real34ChangeSign(op: *real34_t) void {
    op.bytes[15] ^= 0x80;
}
inline fn real34SetPositiveSign(op: *real34_t) void {
    op.bytes[15] &= 0x7F;
}
inline fn real34IsNegative(op: *const real34_t) bool {
    return (op.bytes[15] & 0x80) == 0x80;
}
inline fn real34ToReal(src: *const real34_t, dst: *real_t) void {
    _ = decimal128ToNumber(src, dst);
}
inline fn realToReal34(src: *align(1) const real_t, dst: *real34_t) void {
    _ = decimal128FromNumber(dst, src, &ctxtReal34);
}
inline fn realCopy(src: *align(1) const real_t, dst: *real_t) void {
    _ = decNumberCopy(dst, src);
}
inline fn realSetPositiveSign(op: *real_t) void {
    op.bits &= 0x7F;
}
inline fn realAdd(a: *const real_t, b: *const real_t, res: *real_t, ctx: *const realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn stringToReal34(src: [*c]const u8, dst: *real34_t) void {
    _ = decQuadFromString(dst, src, &ctxtReal34);
}
// VARIABLE_REAL34_DATA / VARIABLE_IMAG34_DATA on a complex34_t*.
inline fn cRe(c: *complex34_t) *real34_t {
    return &c.re;
}
inline fn cIm(c: *complex34_t) *real34_t {
    return &c.im;
}
inline fn reg34(reg: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regCplx(reg: calcRegister_t) *complex34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg)));
}
inline fn regImag34(reg: calcRegister_t) *real34_t {
    return @ptrCast(@alignCast(getRegisterDataPointer(reg) + 16));
}

// Vector geometry macros (OPTION_VECTOR; defines.h).
inline fn isMatrix2dVector(rows: c_int, cols: c_int) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}
inline fn isMatrix3dVector(rows: c_int, cols: c_int) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}
inline fn isMatrixVector(rows: c_int, cols: c_int) bool {
    return isMatrix3dVector(rows, cols) or isMatrix2dVector(rows, cols);
}
inline fn getTagAngularMode(tag: u32) u8 {
    return @intCast(tag & amAngleMask);
}
inline fn is2dVectorPolar(tag: u32) bool {
    return (tag & amPolar) == amPolar;
}
// is3dVectorPolarSPHCYL: the SPH/CYL discriminator. In c47 this is
// `((tag & amPolar) == amPolar)` selecting SPH; here SPH=polar-bit-set,
// CYL=polar-bit-clear with a non-amNone angular mode. (defines.h)
inline fn is3dVectorPolarSPHCYL(tag: u32) bool {
    return (tag & amPolar) == amPolar;
}
inline fn is3dVectorPolarSPH(tag: u32) bool {
    return getTagAngularMode(tag) != amNone and is3dVectorPolarSPHCYL(tag);
}
inline fn is3dVectorPolarCYL(tag: u32) bool {
    return getTagAngularMode(tag) != amNone and !is3dVectorPolarSPHCYL(tag);
}
inline fn isMatrix2dVectorPOL(rows: c_int, cols: c_int, tag: u32) bool {
    return isMatrix2dVector(rows, cols) and is2dVectorPolar(tag);
}
inline fn isMatrix3dVectorSPH(rows: c_int, cols: c_int, tag: u32) bool {
    return isMatrix3dVector(rows, cols) and is3dVectorPolarSPH(tag);
}
inline fn isMatrix3dVectorCYL(rows: c_int, cols: c_int, tag: u32) bool {
    return isMatrix3dVector(rows, cols) and is3dVectorPolarCYL(tag);
}

inline fn imax(a: anytype, b: anytype) @TypeOf(a, b) {
    return if (a > b) a else b;
}
inline fn imin(a: anytype, b: anytype) @TypeOf(a, b) {
    return if (a < b) a else b;
}

// COMPLEX_UNIT / PRODUCT_SIGN runtime macros.
inline fn complexUnit() [*c]const u8 {
    return if (getSystemFlag(FLAG_CPXj)) STD_op_j else STD_op_i;
}
inline fn productSign() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx)) STD_CROSS else STD_DOT;
}

// ===========================================================================
// matrixEditor.c file-scope STATIC helpers that the show* code / vectors need.
// (getRegisterAsInt/setRegisterAsInt also back the z47_frontier_matrix_*_register
// helpers below.)
// ===========================================================================
fn getRegisterAsInt(asArrayPointer: bool_t, reg: calcRegister_t) i16 {
    var tmp_lgInt: MpzStruct = undefined;
    var ret: i16 = 0;

    // The convert* helpers allocate (longIntegerInit) the destination
    // themselves; matching the C, we only init explicitly in the else branch.
    if (getRegisterDataType(reg) == dtLongInteger) {
        convertLongIntegerRegisterToLongInteger(reg, &tmp_lgInt);
    } else if (getRegisterDataType(reg) == dtReal34) {
        convertReal34ToLongInteger(reg34(reg), &tmp_lgInt, DEC_ROUND_DOWN);
    } else {
        __gmpz_init(&tmp_lgInt);
    }
    ret = @truncate(@as(i32, @intCast(__gmpz_get_si(&tmp_lgInt))));
    __gmpz_clear(&tmp_lgInt);

    if (asArrayPointer) ret -= 1;
    return ret;
}

fn setRegisterAsInt(asArrayPointer: bool_t, toStoreIn: i16, reg: calcRegister_t) void {
    var toStore = toStoreIn;
    if (asArrayPointer) toStore += 1;
    var tmp_lgInt: MpzStruct = undefined;
    __gmpz_init(&tmp_lgInt);
    __gmpz_set_si(&tmp_lgInt, toStore);
    convertLongIntegerToLongIntegerRegister(&tmp_lgInt, reg);
    __gmpz_clear(&tmp_lgInt);
}

inline fn getIRegisterAsIntL(asArrayPointer: bool_t) i16 {
    return getRegisterAsInt(asArrayPointer, REGISTER_I);
}
inline fn getJRegisterAsIntL(asArrayPointer: bool_t) i16 {
    return getRegisterAsInt(asArrayPointer, REGISTER_J);
}

// _resetCursorPos (static in matrixEditor.c). Used by the init-aim helpers.
fn resetCursorPos() void {
    clearRegisterLine(NIM_REGISTER_LINE, false, true);
    _ = sprintf(tmpString, "%" ++ "d;%" ++ "d= ", @as(c_int, getRegisterAsInt(false, REGISTER_I)), @as(c_int, getRegisterAsInt(false, REGISTER_J)));
    xCursor = showString(tmpString, &numericFont, 0, Y_POSITION_OF_NIM_LINE, 0, true, true) + 1;
    yCursor = Y_POSITION_OF_NIM_LINE;
    cursorEnabled = 1;
    cursorFont = &numericFont;
    setLastintegerBasetoZero();
}

// displayVectorAngle (static, OPTION_VECTOR).
fn displayVectorAngle(matrix: *const real34Matrix_t, j: c_int, rows: c_int, cols: c_int, toBeAngle: *u8) void {
    if (getTagAngularMode(matrix.header.mtag) != amNone) {
        if (isMatrix3dVector(rows, cols)) {
            if (is3dVectorPolarSPH(matrix.header.mtag) and (j == 1 or j == 2)) {
                toBeAngle.* = getTagAngularMode(matrix.header.mtag);
            } else if (is3dVectorPolarCYL(matrix.header.mtag) and (j == 1)) {
                toBeAngle.* = getTagAngularMode(matrix.header.mtag);
            }
        } else if (isMatrix2dVector(rows, cols)) {
            if (is2dVectorPolar(matrix.header.mtag) and (j == 1)) {
                toBeAngle.* = getTagAngularMode(matrix.header.mtag);
            }
        }
    }
}

// extractVectorElement34 (static, OPTION_VECTOR).
fn extractVectorElement34(matrix: *const real34Matrix_t, j: c_int, ii: c_int, rows: c_int, cols: c_int, element: *real34_t, toBeAngle: *u8, digits: u16, aa: *real_t, bb: *real_t, cc: *real_t) void {
    const is2d = isMatrix2dVector(rows, cols);
    const is3d = isMatrix3dVector(rows, cols);
    if (!is2d and !is3d) {
        real34Copy(&matrix.matrixElements.?[@intCast(ii)], element);
        return;
    }

    // decContext c = ctxtReal39; with optional digit tweak.
    var c: decContext = undefined;
    // ctxtReal39 is opaque to us; copy via byte read using its address. Since we
    // do not know the exact runtime size at comptime safely, reconstruct the
    // fields we touch. The c47 decContext is a fixed POD; copy the whole struct.
    c = @as(*const decContext, @ptrCast(@alignCast(&ctxtReal39))).*;
    if (!getSystemFlag(FLAG_IRFRAC)) {
        c.digits = @as(i32, @intCast(digits)) + 3;
    }

    if (isMatrix3dVectorSPH(rows, cols, matrix.header.mtag)) {
        convert3DtoSPH(matrix, aa, bb, cc, toBeAngle.*, &c);
        if (getSystemFlag(FLAG_3DPHYS)) {
            switch (j) {
                0 => realToReal34(aa, element),
                1 => realToReal34(cc, element),
                2 => realToReal34(bb, element),
                else => {},
            }
        } else {
            switch (j) {
                0 => realToReal34(aa, element),
                1 => realToReal34(bb, element),
                2 => realToReal34(cc, element),
                else => {},
            }
        }
    } else if (isMatrix3dVectorCYL(rows, cols, matrix.header.mtag)) {
        convert3DtoCYL(matrix, aa, bb, cc, toBeAngle.*, &c);
        switch (j) {
            0 => realToReal34(aa, element),
            1 => realToReal34(bb, element),
            2 => realToReal34(cc, element),
            else => {},
        }
    } else if (isMatrix2dVectorPOL(rows, cols, matrix.header.mtag)) {
        convert2DtoPOL(matrix, aa, bb, toBeAngle.*, &c);
        switch (j) {
            0 => realToReal34(aa, element),
            1 => realToReal34(bb, element),
            else => {},
        }
    } else {
        real34Copy(&matrix.matrixElements.?[@intCast(ii)], element);
    }
}

// ===========================================================================
// PUBLIC (non-renamed) matrixEditor.c functions.
// ===========================================================================

const MATRIX_LINE_WIDTH_C: i16 = MATRIX_LINE_WIDTH;

pub export fn showRealMatrix(matrix: *const real34Matrix_t, prefixWidth: i16, toDisplayIn: bool_t, regXposition: bool_t) callconv(.c) void {
    var rows: c_int = matrix.header.matrixRows;
    var cols: c_int = matrix.header.matrixColumns;
    var Y_POS: i16 = Y_POSITION_OF_REGISTER_X_LINE;
    var X_POS: i16 = 0;
    var totalWidth: i16 = 0;
    var width: i16 = 0;
    var font: *const font_t = &numericFont;
    var fontHeight: i16 = NUMERIC_FONT_HEIGHT_;
    const maxWidth: i16 = MATRIX_LINE_WIDTH_C - prefixWidth;
    var colWidth = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var rPadWidth = std.mem.zeroes([MATRIX_MAX_ROWS * MATRIX_MAX_COLUMNS]i16);
    var allElementsInColAreIntegers = std.mem.zeroes([MATRIX_MAX_COLUMNS]bool_t);
    const forEditor = matrix == &openMatrixMIMPointer.realMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    var sCol: u16 = if (forEditor) scrollColumn else 0;
    const tmpDisplayFormat: u16 = displayFormat;
    const tmpDisplayFormatDigits: u8 = displayFormatDigits;
    var toDisplay = toDisplayIn;

    Y_POS = Y_POSITION_OF_REGISTER_X_LINE - NUMERIC_FONT_HEIGHT_;

    var colVector = false;
    if (cols == 1 and rows > 1) {
        colVector = true;
        cols = rows;
        rows = 1;
    }

    if (forEditor or rows > 1) toDisplay = true;
    _ = strcpy(errorMessage, "[");

    var maxCols: u16 = if (cols > MATRIX_MAX_COLUMNS) MATRIX_MAX_COLUMNS else @intCast(cols);
    const maxRows: u16 = if (rows > MATRIX_MAX_ROWS) MATRIX_MAX_ROWS else @intCast(rows);
    if (@as(c_int, maxCols) + @as(c_int, sCol) >= cols) {
        maxCols = @intCast(cols - @as(c_int, sCol));
    }

    const matSelRow: i16 = if (colVector) getJRegisterAsIntL(true) else getIRegisterAsIntL(true);
    const matSelCol: i16 = if (colVector) getIRegisterAsIntL(true) else getJRegisterAsIntL(true);

    var vm: videoMode_t = 0;
    var digits: i16 = 0;

    font = &numericFont;
    // In C the `smallFont:` label sits INSIDE the `if(rows >= ...)` block, and
    // every `goto smallFont` jumps directly to it (bypassing the if), so a retry
    // always re-runs the standardFont/Y_POS reset. Reproduce with a flag that is
    // set on each `continue :smallFont` so the reset block runs on retries even
    // when `rows < threshold`.
    var atSmallFontLabel: bool = false;
    smallFont: while (true) {
        if (atSmallFontLabel or rows >= (if (forEditor) @as(c_int, 4) else @as(c_int, 5))) {
            font = &standardFont;
            fontHeight = STANDARD_FONT_HEIGHT_;
            Y_POS = Y_POSITION_OF_REGISTER_X_LINE - STANDARD_FONT_HEIGHT_;
        }

        if (!forEditor) {
            Y_POS += REGISTER_LINE_HEIGHT;
        }
        const rightEllipsis = (cols > @as(c_int, maxCols)) and (cols > @as(c_int, maxCols) + @as(c_int, sCol));
        const leftEllipsis = (sCol > 0);

        if (!regXposition and prefixWidth > 0) {
            Y_POS = Y_POSITION_OF_REGISTER_T_LINE - REGISTER_LINE_HEIGHT + 1 + @as(i16, @intCast(maxRows)) * fontHeight;
        }
        if (!regXposition and prefixWidth > 0 and font == &standardFont) {
            Y_POS += (if (maxRows == 1) STANDARD_FONT_HEIGHT_ else REGISTER_LINE_HEIGHT - STANDARD_FONT_HEIGHT_);
        }

        const allowIntegerDisplay = !(isMatrixVector(@intCast(maxRows), @intCast(maxCols)) and (is3dVectorPolarSPH(matrix.header.mtag) or is3dVectorPolarCYL(matrix.header.mtag) or is2dVectorPolar(matrix.header.mtag)));
        {
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                allElementsInColAreIntegers[j] = allowIntegerDisplay;
                if (allElementsInColAreIntegers[j]) {
                    var i: usize = 0;
                    while (i < maxRows) : (i += 1) {
                        if (!real34IsAnInteger(&matrix.matrixElements.?[i * @as(usize, @intCast(cols)) + j])) {
                            allElementsInColAreIntegers[j] = false;
                            break;
                        }
                    }
                }
            }
        }

        var baseWidth: i16 = (if (leftEllipsis) stringWidth(STD_ELLIPSIS ++ " ", font, true, true) else 0) + (if (rightEllipsis) stringWidth(" " ++ STD_ELLIPSIS, font, true, true) else 0);
        var mtxWidth = getRealMatrixColumnWidths(matrix, prefixWidth, font, &colWidth, &rPadWidth, &digits, maxCols, &allElementsInColAreIntegers);
        var noFix = (mtxWidth < 0);
        mtxWidth = if (mtxWidth < 0) -mtxWidth else mtxWidth;
        totalWidth = baseWidth + mtxWidth;

        if (displayFormat == DF_ALL and noFix) {
            displayFormat = if (getSystemFlag(FLAG_ENGOVR)) DF_ENG else DF_SCI;
            displayFormatDigits = @intCast(digits);
        }
        if (totalWidth > maxWidth or leftEllipsis) {
            if (font == &numericFont) {
                displayFormat = @intCast(tmpDisplayFormat);
                displayFormatDigits = tmpDisplayFormatDigits;
                atSmallFontLabel = true;
                continue :smallFont;
            } else {
                displayFormat = DF_SCI;
                displayFormatDigits = 3;
                mtxWidth = getRealMatrixColumnWidths(matrix, prefixWidth, font, &colWidth, &rPadWidth, &digits, maxCols, &allElementsInColAreIntegers);
                noFix = (mtxWidth < 0);
                mtxWidth = if (mtxWidth < 0) -mtxWidth else mtxWidth;
                totalWidth = baseWidth + mtxWidth;
                if (totalWidth > maxWidth) {
                    maxCols -= 1;
                    atSmallFontLabel = true;
                    continue :smallFont;
                }
            }
        }

        if (forEditor) {
            if ((matSelCol < @as(i16, @intCast(sCol))) and leftEllipsis) {
                scrollColumn -= 1;
                sCol -= 1;
                atSmallFontLabel = true;
                continue :smallFont;
            } else if ((matSelCol >= @as(i16, @intCast(sCol)) + @as(i16, @intCast(maxCols))) and rightEllipsis) {
                scrollColumn += 1;
                sCol += 1;
                atSmallFontLabel = true;
                continue :smallFont;
            }
        }

        {
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                baseWidth += colWidth[j] + stringWidth(STD_SPACE_FIGURE, font, true, true);
            }
        }
        baseWidth -= stringWidth(STD_SPACE_FIGURE, font, true, true);
        baseWidth += 3;

        var endChar = std.mem.zeroes([6]u8);
        _ = strcpy(&endChar, if (isMatrix3dVectorCYL(rows, cols, matrix.header.mtag))
            "]" ++ STD_SPACE_HAIR ++ STD_SUP_c
        else if (isMatrix3dVectorSPH(rows, cols, matrix.header.mtag))
            "]" ++ STD_SPACE_HAIR ++ STD_SUP_s
        else if (isMatrix2dVectorPOL(rows, cols, matrix.header.mtag))
            "]" ++ STD_SPACE_HAIR ++ STD_SUP_p
        else
            "]");

        if (!regXposition and prefixWidth > 0) {
            X_POS = prefixWidth;
        } else if (!forEditor) {
            X_POS = SCREEN_WIDTH - 1 - ((if (colVector) stringWidth("[", font, true, true) + stringWidth(&endChar, font, true, true) + stringWidth(STD_SUP_BOLD_T, font, true, true) else stringWidth("[", font, true, true) + stringWidth(&endChar, font, true, true)) + baseWidth) - (if (font == &standardFont) @as(i16, 0) else @as(i16, 1));
        }

        if (toDisplay) {
            if (forEditor) {
                clearRegisterLine(REGISTER_X, true, true);
                clearRegisterLine(REGISTER_Y, true, true);
                if (rows >= (if (font == &standardFont) @as(c_int, 3) else @as(c_int, 2))) {
                    clearRegisterLine(REGISTER_Z, true, true);
                }
                if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                    clearRegisterLine(REGISTER_T, true, true);
                }
            } else if (!regXposition and prefixWidth > 0) {
                clearRegisterLine(REGISTER_T, true, true);
                if (rows >= 2) {
                    clearRegisterLine(REGISTER_Z, true, true);
                }
                if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                    clearRegisterLine(REGISTER_Y, true, true);
                }
                if (rows == 4 and font != &standardFont) {
                    clearRegisterLine(REGISTER_X, true, true);
                }
            }
        }
        const displayFormat1: u16 = displayFormat;
        const displayFormatDigits1: u8 = displayFormatDigits;

        var colX: i16 = 0;
        var aa: real_t = undefined;
        var bb: real_t = undefined;
        var cc: real_t = undefined;

        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            if (toDisplay) {
                colX = stringWidth("[", font, true, true);
                _ = showString(if (maxRows == 1) "[" else if (i == 0) STD_MAT_TL else if (i + 1 == maxRows) STD_MAT_BL else STD_MAT_ML, font, @intCast(X_POS + 5), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - i)) * fontHeight), 0, false, false);
                if (leftEllipsis) {
                    _ = showString(STD_ELLIPSIS ++ " ", font, @intCast(X_POS + 5 + stringWidth("[", font, true, true)), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - i)) * fontHeight), 0, true, false);
                    colX += stringWidth(STD_ELLIPSIS ++ " ", font, true, true);
                }
            }

            var j: usize = 0;
            const jLimit: usize = maxCols + (if (rightEllipsis) @as(usize, 1) else 0);
            while (j < jLimit) : (j += 1) {
                if (allElementsInColAreIntegers[j]) {
                    displayFormat = DF_FIX;
                    displayFormatDigits = 0;
                } else {
                    displayFormat = @intCast(displayFormat1);
                    displayFormatDigits = displayFormatDigits1;
                }

                if (((i == maxRows - 1) and (rows > @as(c_int, maxRows) + @as(c_int, sRow))) or ((j == maxCols) and rightEllipsis) or ((i == 0) and (sRow > 0))) {
                    _ = strcpy(tmpString, " " ++ STD_ELLIPSIS);
                    vm = 0;
                } else {
                    var toBeAngle: u8 = amNone;
                    displayVectorAngle(matrix, @intCast(j), rows, cols, &toBeAngle);
                    var element: real34_t = undefined;

                    if (displayFormat != DF_ALL) {
                        digits = 15;
                    }
                    extractVectorElement34(matrix, @intCast(j), @intCast((i + sRow) * @as(usize, @intCast(cols)) + j + sCol), rows, cols, &element, &toBeAngle, @intCast(digits), &aa, &bb, &cc);
                    real34ToDisplayString(&element, toBeAngle, tmpString, font, colWidth[j], digits, LIMITEXP, FRONTSPACE, if (cols * rows > 3) LIMITIRFRAC else LIGHTIRFRAC);

                    if (toDisplay) {
                        if (forEditor and matSelRow == @as(i16, @intCast(i + sRow)) and matSelCol == @as(i16, @intCast(j + sCol))) {
                            lcdFillRect(@intCast(X_POS + 5 + colX), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - i)) * fontHeight), @intCast(colWidth[j]), if (font == &numericFont) 32 else 20, LCD_EMPTY_VALUE);
                            vm = 1;
                        } else {
                            vm = 0;
                        }
                    }
                }
                if (toDisplay) {
                    width = stringWidth(tmpString, font, true, true) + 1;
                    _ = showString(tmpString, font, @intCast(X_POS + 5 + colX + (if ((j == maxCols) and rightEllipsis) -stringWidth(" ", font, true, true) else (colWidth[j] - width) - rPadWidth[i * MATRIX_MAX_COLUMNS + j])), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - i)) * fontHeight), vm, true, false);
                    colX += colWidth[j] + stringWidth(STD_SPACE_FIGURE, font, true, true) - 1;
                } else {
                    if (j > 0) {
                        _ = strcat(errorMessage, " ");
                    }
                    _ = strcat(errorMessage, tmpString);
                }
            }

            if (toDisplay) {
                _ = showString(if (maxRows == 1) &endChar else if (i == 0) STD_MAT_TR else if (i + 1 == maxRows) STD_MAT_BR else STD_MAT_MR, font, @intCast(X_POS + stringWidth("[", font, true, true) + baseWidth), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - i)) * fontHeight), 0, true, false);
                if (colVector) {
                    _ = showString(STD_SUP_BOLD_T, font, @intCast(X_POS + stringWidth("[", font, true, true) + stringWidth(&endChar, font, true, true) + baseWidth), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - i)) * fontHeight), 0, true, false);
                }
            } else {
                _ = strcat(errorMessage, &endChar);
                if (colVector) {
                    _ = strcat(errorMessage, STD_SUP_BOLD_T);
                }
            }
        }

        break :smallFont;
    }

    displayFormat = @intCast(tmpDisplayFormat);
    displayFormatDigits = tmpDisplayFormatDigits;
}

pub export fn getRealMatrixColumnWidths(matrix: *const real34Matrix_t, prefixWidth: i16, font: *const font_t, colWidthPtr: [*c]i16, rPadWidthPtr: [*c]i16, digitsPtr: *i16, maxColsIn: u16, allElementsInColAreIntegersPtr: [*c]bool_t) callconv(.c) i16 {
    var tmpStringL = std.mem.zeroes([200]u8);
    const colVector = matrix.header.matrixColumns == 1 and matrix.header.matrixRows > 1;
    const rows: c_int = if (colVector) 1 else matrix.header.matrixColumns; // note: see below
    _ = rows;
    const rowsReal: c_int = if (colVector) 1 else matrix.header.matrixRows;
    const actualCols: c_int = if (colVector) matrix.header.matrixRows else matrix.header.matrixColumns;
    const cols: c_int = if (actualCols > @as(c_int, maxColsIn)) @as(c_int, maxColsIn) else actualCols;
    const maxRows: c_int = if (rowsReal > MATRIX_MAX_ROWS) MATRIX_MAX_ROWS else rowsReal;
    const forEditor = matrix == &openMatrixMIMPointer.realMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    const sCol: u16 = if (forEditor) scrollColumn else 0;
    const maxWidth: i16 = MATRIX_LINE_WIDTH_C - prefixWidth;
    var totalWidth: i16 = 0;
    var maxRightWidth = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var maxLeftWidth = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    const exponentOutOfRange: i16 = 0x4000;
    var noFix = false;
    const dspDigits: i16 = displayFormatDigits;

    const maxCols: usize = maxColsIn;

    var startDigitCountDown: u16 = @intCast(imax(imin(@as(c_int, displayFormatDigits) * (if (displayFormat == DF_ALL) @as(c_int, 2) else @as(c_int, 1)), imax(@divTrunc(@as(c_int, 50), cols) - 2, 0)), 10));
    if (isMatrix3dVector(rowsReal, cols)) {
        startDigitCountDown = 5;
    } else if (isMatrix2dVector(rowsReal, cols)) {
        startDigitCountDown = 7;
    }

    begin: while (true) {
        var k: c_int = startDigitCountDown;
        kloop: while (k >= 1) : (k -= 1) {
            if (displayFormat == DF_ALL) {
                digitsPtr.* = @intCast(k);
            }
            if (displayFormat == DF_ALL and noFix) {
                displayFormat = if (getSystemFlag(FLAG_ENGOVR)) DF_ENG else DF_SCI;
                displayFormatDigits = @intCast(k);
            }

            const displayFormat1: u16 = displayFormat;
            const displayFormatDigits1: u8 = displayFormatDigits;
            var aa: real_t = undefined;
            var bb: real_t = undefined;
            var cc: real_t = undefined;

            var i: usize = 0;
            while (i < maxRows) : (i += 1) {
                var j: usize = 0;
                while (j < maxCols) : (j += 1) {
                    var r34Val: real34_t = undefined;
                    var toBeAngle: u8 = amNone;
                    displayVectorAngle(matrix, @intCast(j), rowsReal, cols, &toBeAngle);
                    const calcDigits: u16 = if (displayFormat == DF_ALL) @as(u16, @intCast(k)) else 15;
                    extractVectorElement34(matrix, @intCast(j), @intCast((i + sRow) * @as(usize, @intCast(cols)) + j + sCol), rowsReal, cols, &r34Val, &toBeAngle, calcDigits, &aa, &bb, &cc);

                    const r34sign = real34IsNegative(&r34Val);
                    real34SetPositiveSign(&r34Val);

                    if (allElementsInColAreIntegersPtr[j]) {
                        displayFormat = DF_FIX;
                        displayFormatDigits = 0;
                    } else {
                        displayFormat = @intCast(displayFormat1);
                        displayFormatDigits = displayFormatDigits1;
                    }

                    real34ToDisplayString(&r34Val, toBeAngle, &tmpStringL, font, maxWidth, @intCast(calcDigits), LIMITEXP, FRONTSPACE, if (cols * rowsReal > 3) LIMITIRFRAC else LIGHTIRFRAC);
                    if (displayFormat == DF_ALL and !noFix and strstr(&tmpStringL, STD_SUB_10) != null) {
                        noFix = true;
                        totalWidth = 0;
                        var p: usize = 0;
                        while (p < MATRIX_MAX_COLUMNS) : (p += 1) {
                            maxRightWidth[p] = 0;
                            maxLeftWidth[p] = 0;
                        }
                        continue :begin;
                    }

                    var width: i16 = stringWidth(&tmpStringL, font, true, true) + 1;
                    rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j] = 0;
                    if (strstr(&tmpStringL, ".") != null or strstr(&tmpStringL, ",") != null) {
                        var xStr: [*c]u8 = &tmpStringL;
                        while (xStr.* != 0) : (xStr += 1) {
                            const isEngLike = (displayFormat == DF_ENG or (displayFormat == DF_ALL and getSystemFlag(FLAG_ENGOVR)));
                            const cond1 = (displayFormat != DF_ENG and (displayFormat != DF_ALL or !getSystemFlag(FLAG_ENGOVR))) and (xStr.* == '.' or xStr.* == ',');
                            const cond2 = isEngLike and xStr[0] == 0x80 and (xStr[1] == 0x87 or xStr[1] == 0xd7);
                            if (cond1 or cond2) {
                                rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j] = stringWidth(xStr, font, true, true) + 1;
                                if (maxRightWidth[j] < rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j]) {
                                    maxRightWidth[j] = rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j];
                                }
                                break;
                            }
                        }
                        if (maxLeftWidth[j] < (width - rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j])) {
                            maxLeftWidth[j] = (width - rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j]);
                        }
                    } else {
                        if (r34sign and strstr(&tmpStringL, "/") != null) {
                            width += stringWidth("-", font, true, true);
                        }
                        rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j] = width | exponentOutOfRange;
                    }
                }
            }

            displayFormat = @intCast(displayFormat1);
            displayFormatDigits = displayFormatDigits1;

            {
                var pi: usize = 0;
                while (pi < maxRows) : (pi += 1) {
                    var j: usize = 0;
                    while (j < maxCols) : (j += 1) {
                        if ((rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] & exponentOutOfRange) != 0) {
                            if ((maxLeftWidth[j] + maxRightWidth[j]) < (rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] & (~exponentOutOfRange))) {
                                maxLeftWidth[j] = (rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] & (~exponentOutOfRange)) - maxRightWidth[j];
                            }
                        }
                    }
                }
            }
            {
                var pi: usize = 0;
                while (pi < maxRows) : (pi += 1) {
                    var j: usize = 0;
                    while (j < maxCols) : (j += 1) {
                        if ((rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] & exponentOutOfRange) != 0) {
                            rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] = 0;
                        } else {
                            rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] -= maxRightWidth[j];
                            rPadWidthPtr[pi * MATRIX_MAX_COLUMNS + j] *= -1;
                        }
                    }
                }
            }
            {
                var j: usize = 0;
                while (j < maxCols) : (j += 1) {
                    colWidthPtr[j] = (maxLeftWidth[j] + maxRightWidth[j]);
                    totalWidth += colWidthPtr[j] + stringWidth(STD_SPACE_FIGURE, font, true, true) * 2;
                }
            }
            totalWidth -= stringWidth(STD_SPACE_FIGURE, font, true, true);
            if (noFix) {
                displayFormat = DF_ALL;
                displayFormatDigits = @intCast(dspDigits);
            }
            if (displayFormat != DF_ALL) {
                break :kloop;
            } else if (totalWidth <= maxWidth) {
                digitsPtr.* = @intCast(k);
                break :kloop;
            } else if (k > 1) {
                totalWidth = 0;
                var j: usize = 0;
                while (j < maxCols) : (j += 1) {
                    maxRightWidth[j] = 0;
                    maxLeftWidth[j] = 0;
                }
            }
        }
        break :begin;
    }
    return totalWidth * (if (noFix) @as(i16, -1) else @as(i16, 1));
}

pub export fn showComplexMatrix(matrix: *const complex34Matrix_t, prefixWidth: i16, angleMode: angularMode_t, polarMode: bool_t, regXposition: bool_t) callconv(.c) void {
    var rows: c_int = matrix.header.matrixRows;
    var cols: c_int = matrix.header.matrixColumns;
    var Y_POS: i16 = Y_POSITION_OF_REGISTER_X_LINE;
    var X_POS: i16 = 0;
    var totalWidth: i16 = 0;
    var width: i16 = 0;
    var font: *const font_t = &numericFont;
    var fontHeight: i16 = NUMERIC_FONT_HEIGHT_;
    const maxWidth: i16 = MATRIX_LINE_WIDTH_C - prefixWidth;
    var colWidth = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var colWidth_r = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var colWidth_i = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var rPadWidth_r = std.mem.zeroes([MATRIX_MAX_ROWS * MATRIX_MAX_COLUMNS]i16);
    var rPadWidth_i = std.mem.zeroes([MATRIX_MAX_ROWS * MATRIX_MAX_COLUMNS]i16);
    const forEditor = matrix == &openMatrixMIMPointer.complexMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    var sCol: u16 = if (forEditor) scrollColumn else 0;
    const tmpDisplayFormat: u16 = displayFormat;
    const tmpExponentLimit: i16 = exponentLimit;
    const tmpDisplayFormatDigits: u8 = displayFormatDigits;
    const tmpMultX = getSystemFlag(FLAG_MULTx);

    Y_POS = Y_POSITION_OF_REGISTER_X_LINE - NUMERIC_FONT_HEIGHT_;

    var colVector = false;
    if (cols == 1 and rows > 1) {
        colVector = true;
        cols = rows;
        rows = 1;
    }

    var maxCols: c_int = if (cols > MATRIX_MAX_COLUMNS) MATRIX_MAX_COLUMNS else cols;
    const maxRows: c_int = if (rows > MATRIX_MAX_ROWS) MATRIX_MAX_ROWS else rows;

    const matSelRow: i16 = if (colVector) getJRegisterAsIntL(true) else getIRegisterAsIntL(true);
    const matSelCol: i16 = if (colVector) getIRegisterAsIntL(true) else getJRegisterAsIntL(true);

    var vm: videoMode_t = 0;
    if (maxCols + @as(c_int, sCol) >= cols) {
        maxCols = cols - @as(c_int, sCol);
    }

    var digits: i16 = 0;

    font = &numericFont;
    // See showRealMatrix: the C `smallFont:` label is inside the `if(rows>=...)`
    // block and every `goto smallFont` jumps into it, so retries always re-run
    // the standardFont/Y_POS reset. The flag reproduces that.
    var atSmallFontLabel: bool = false;
    smallFont: while (true) {
        if (atSmallFontLabel or rows >= (if (forEditor) @as(c_int, 4) else @as(c_int, 5))) {
            font = &standardFont;
            fontHeight = STANDARD_FONT_HEIGHT_;
            Y_POS = Y_POSITION_OF_REGISTER_X_LINE - STANDARD_FONT_HEIGHT_ + 2;
        }

        if (!forEditor) {
            Y_POS += REGISTER_LINE_HEIGHT;
        }
        const rightEllipsis = (cols > maxCols) and (cols > maxCols + @as(c_int, sCol));
        const leftEllipsis = (sCol > 0);

        if (!regXposition and prefixWidth > 0) {
            Y_POS = Y_POSITION_OF_REGISTER_T_LINE - REGISTER_LINE_HEIGHT + 1 + @as(i16, @intCast(maxRows)) * fontHeight;
        }
        if (!regXposition and prefixWidth > 0 and font == &standardFont) {
            Y_POS += (if (maxRows == 1) STANDARD_FONT_HEIGHT_ else REGISTER_LINE_HEIGHT - STANDARD_FONT_HEIGHT_);
        }

        var baseWidth: i16 = (if (leftEllipsis) stringWidth(STD_ELLIPSIS ++ " ", font, true, true) else 0) + (if (rightEllipsis) stringWidth(STD_ELLIPSIS, font, true, true) else 0);
        totalWidth = baseWidth + getComplexMatrixColumnWidths(matrix, prefixWidth, font, &colWidth, &colWidth_r, &colWidth_i, &rPadWidth_r, &rPadWidth_i, &digits, @intCast(maxCols), angleMode, polarMode);
        if (totalWidth > maxWidth or leftEllipsis) {
            if (font == &numericFont) {
                atSmallFontLabel = true;
                continue :smallFont;
            } else if (exponentLimit > 99) {
                exponentLimit = 99;
                atSmallFontLabel = true;
                continue :smallFont;
            } else {
                displayFormat = DF_SCI;
                displayFormatDigits = 2;
                clearSystemFlag(FLAG_MULTx);
                totalWidth = baseWidth + getComplexMatrixColumnWidths(matrix, prefixWidth, font, &colWidth, &colWidth_r, &colWidth_i, &rPadWidth_r, &rPadWidth_i, &digits, @intCast(maxCols), angleMode, polarMode);
                if (totalWidth > maxWidth) {
                    maxCols -= 1;
                    atSmallFontLabel = true;
                    continue :smallFont;
                }
            }
        }
        if (forEditor) {
            if (matSelCol < @as(i16, @intCast(sCol))) {
                scrollColumn -= 1;
                sCol -= 1;
                atSmallFontLabel = true;
                continue :smallFont;
            } else if (matSelCol >= @as(i16, @intCast(sCol)) + @as(i16, @intCast(maxCols))) {
                scrollColumn += 1;
                sCol += 1;
                atSmallFontLabel = true;
                continue :smallFont;
            }
        }
        {
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                baseWidth += colWidth[j] + stringWidth(STD_SPACE_FIGURE, font, true, true);
            }
        }
        baseWidth -= stringWidth(STD_SPACE_FIGURE, font, true, true);

        if (!regXposition and prefixWidth > 0) {
            X_POS = prefixWidth;
        } else if (!forEditor) {
            X_POS = SCREEN_WIDTH - ((if (colVector) stringWidth("[]" ++ STD_SUP_BOLD_T, font, true, true) else stringWidth("[]", font, true, true)) + baseWidth) - (if (font == &standardFont) @as(i16, 0) else @as(i16, 1));
        }

        if (forEditor) {
            clearRegisterLine(REGISTER_X, true, true);
            clearRegisterLine(REGISTER_Y, true, true);
            if (rows >= (if (font == &standardFont) @as(c_int, 3) else @as(c_int, 2))) {
                clearRegisterLine(REGISTER_Z, true, true);
            }
            if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                clearRegisterLine(REGISTER_T, true, true);
            }
        } else if (!regXposition and prefixWidth > 0) {
            clearRegisterLine(REGISTER_T, true, true);
            if (rows >= 2) {
                clearRegisterLine(REGISTER_Z, true, true);
            }
            if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                clearRegisterLine(REGISTER_Y, true, true);
            }
            if (rows == 4 and font != &standardFont) {
                clearRegisterLine(REGISTER_X, true, true);
            }
        }

        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            var colX: i16 = stringWidth("[", font, true, true);
            _ = showString(if (maxRows == 1) "[" else if (i == 0) STD_MAT_TL else if (i + 1 == maxRows) STD_MAT_BL else STD_MAT_ML, font, @intCast(X_POS + 1), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), 0, true, false);
            if (leftEllipsis) {
                _ = showString(STD_ELLIPSIS ++ " ", font, @intCast(X_POS + stringWidth("[", font, true, true)), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), 0, true, false);
                colX += stringWidth(STD_ELLIPSIS ++ " ", font, true, true);
            }
            var j: usize = 0;
            const jLimit: usize = @as(usize, @intCast(maxCols)) + (if (rightEllipsis) @as(usize, 1) else 0);
            while (j < jLimit) : (j += 1) {
                var re: real34_t = undefined;
                var im: real34_t = undefined;
                const elem = &matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(cols)) + j + sCol];
                if (polarMode) {
                    var x: real_t = undefined;
                    var y: real_t = undefined;
                    real34ToReal(&elem.re, &x);
                    real34ToReal(&elem.im, &y);
                    realRectangularToPolar(&x, &y, &x, &y, &ctxtReal39);
                    convertAngleFromTo(&y, amRadian, angleMode, &ctxtReal39);
                    realToReal34(&x, &re);
                    realToReal34(&y, &im);
                } else {
                    real34Copy(&elem.re, &re);
                    real34Copy(&elem.im, &im);
                }

                if (((@as(c_int, @intCast(i)) == maxRows - 1) and (rows > maxRows + @as(c_int, sRow))) or ((j == @as(usize, @intCast(maxCols))) and rightEllipsis) or ((i == 0) and (sRow > 0))) {
                    _ = strcpy(tmpString, STD_ELLIPSIS);
                    vm = 0;
                } else {
                    tmpString[0] = 0;
                    real34ToDisplayString(&re, amNone, tmpString, font, colWidth_r[j], if (displayFormat == DF_ALL) digits else 15, LIMITEXP, FRONTSPACE, LIMITIRFRAC);
                    if (forEditor and matSelRow == @as(i16, @intCast(i + sRow)) and matSelCol == @as(i16, @intCast(j + sCol))) {
                        lcdFillRect(@intCast(X_POS + colX), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), @intCast(colWidth[j]), if (font == &numericFont) 32 else 20, LCD_EMPTY_VALUE);
                        vm = 1;
                    } else {
                        vm = 0;
                    }
                }
                width = stringWidth(tmpString, font, true, true) + 1;
                _ = showString(tmpString, font, @intCast(X_POS + colX + (if ((j == @as(usize, @intCast(maxCols))) and rightEllipsis) stringWidth(STD_SPACE_FIGURE, font, true, true) - width else (colWidth_r[j] - width) - rPadWidth_r[i * MATRIX_MAX_COLUMNS + j])), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), vm, true, false);
                if (strcmpEq(tmpString, STD_ELLIPSIS) == false) {
                    const neg = real34IsNegative(&im);
                    var cpxUnitWidth: i16 = 0;

                    if (polarMode) {
                        _ = strcpy(tmpString, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
                    } else {
                        _ = strcpy(tmpString, "+");
                        _ = strcat(tmpString, complexUnit());
                        _ = strcat(tmpString, productSign());
                    }
                    cpxUnitWidth = stringWidth(tmpString, font, true, true);
                    width = cpxUnitWidth;
                    if (!polarMode) {
                        if (neg) {
                            tmpString[0] = '-';
                            real34SetPositiveSign(&im);
                        }
                    }
                    _ = showString(tmpString, font, @intCast(X_POS + colX + colWidth_r[j] + (width - stringWidth(tmpString, font, true, true))), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), vm, true, false);

                    real34ToDisplayString(&im, if (polarMode) @as(u32, @bitCast(@as(i32, angleMode))) else amNone, tmpString, font, colWidth_i[j], if (displayFormat == DF_ALL) digits else 15, LIMITEXP, !FRONTSPACE, LIMITIRFRAC);
                    width = stringWidth(tmpString, font, true, true) + 1;
                    _ = showString(tmpString, font, @intCast(X_POS + colX + colWidth_r[j] + cpxUnitWidth + (if ((j == @as(usize, @intCast(maxCols - 1))) and rightEllipsis) @as(i16, 0) else (colWidth_i[j] - width) - rPadWidth_i[i * MATRIX_MAX_COLUMNS + j])), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), vm, true, false);
                }
                colX += colWidth[j] + stringWidth(STD_SPACE_FIGURE, font, true, true);
            }
            _ = showString(if (maxRows == 1) "]" else if (i == 0) STD_MAT_TR else if (i + 1 == maxRows) STD_MAT_BR else STD_MAT_MR, font, @intCast(X_POS + stringWidth("[", font, true, true) + baseWidth - 1), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), 0, true, false);
            if (colVector) {
                _ = showString(STD_SUP_BOLD_T, font, @intCast(X_POS + stringWidth("[]", font, true, true) + baseWidth), @intCast(Y_POS - @as(i16, @intCast(maxRows - 1 - @as(c_int, @intCast(i)))) * fontHeight), 0, true, false);
            }
        }
        break :smallFont;
    }

    displayFormat = @intCast(tmpDisplayFormat);
    displayFormatDigits = tmpDisplayFormatDigits;
    exponentLimit = tmpExponentLimit;
    if (tmpMultX) {
        setSystemFlag(FLAG_MULTx);
    }
}

pub export fn getComplexMatrixColumnWidths(matrix: *const complex34Matrix_t, prefixWidth: i16, font: *const font_t, colWidthPtr: [*c]i16, colWidth_rPtr: [*c]i16, colWidth_iPtr: [*c]i16, rPadWidth_rPtr: [*c]i16, rPadWidth_iPtr: [*c]i16, digitsPtr: *i16, maxColsIn: u16, angleMode: angularMode_t, polarMode: bool_t) callconv(.c) i16 {
    var tmpStringL = std.mem.zeroes([200]u8);
    const colVector = matrix.header.matrixColumns == 1 and matrix.header.matrixRows > 1;
    const rows: c_int = if (colVector) 1 else matrix.header.matrixRows;
    const actualCols: c_int = if (colVector) matrix.header.matrixRows else matrix.header.matrixColumns;
    const cols: c_int = if (actualCols > @as(c_int, maxColsIn)) @as(c_int, maxColsIn) else actualCols;
    const maxRows: c_int = if (rows > MATRIX_MAX_ROWS) MATRIX_MAX_ROWS else rows;
    const forEditor = matrix == &openMatrixMIMPointer.complexMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    const sCol: u16 = if (forEditor) scrollColumn else 0;
    const maxWidth: i16 = MATRIX_LINE_WIDTH_C - prefixWidth;
    var totalWidth: i16 = 0;
    var maxRightWidth_r = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var maxLeftWidth_r = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var maxRightWidth_i = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    var maxLeftWidth_i = std.mem.zeroes([MATRIX_MAX_COLUMNS]i16);
    const exponentOutOfRange: i16 = 0x4000;
    const maxCols: usize = maxColsIn;

    var cpxUnitWidth: i16 = 0;
    if (polarMode) {
        _ = strcpy(&tmpStringL, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
    } else {
        _ = strcpy(&tmpStringL, "+");
        _ = strcat(&tmpStringL, complexUnit());
        _ = strcat(&tmpStringL, productSign());
    }
    cpxUnitWidth = stringWidth(&tmpStringL, font, true, true);

    var k: c_int = imax(imin(@as(c_int, displayFormatDigits) * (if (displayFormat == DF_ALL) @as(c_int, 2) else @as(c_int, 1)), imax(@divTrunc(@as(c_int, 50), cols) - 2, 0)), 10);
    while (k >= 1) : (k -= 1) {
        if (displayFormat == DF_ALL) {
            digitsPtr.* = @intCast(k);
        }
        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                var c34Val: complex34_t = undefined;
                complex34Copy(&matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol], &c34Val);
                if (polarMode) {
                    var x: real_t = undefined;
                    var y: real_t = undefined;
                    real34ToReal(&c34Val.re, &x);
                    real34ToReal(&c34Val.im, &y);
                    realRectangularToPolar(&x, &y, &x, &y, &ctxtReal39);
                    convertAngleFromTo(&y, amRadian, angleMode, &ctxtReal39);
                    realToReal34(&x, &c34Val.re);
                    realToReal34(&y, &c34Val.im);
                }

                rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j] = 0;
                real34SetPositiveSign(&c34Val.re);
                var c34sign = real34IsNegative(&matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol].re);
                real34ToDisplayString(&c34Val.re, amNone, &tmpStringL, font, maxWidth, if (displayFormat == DF_ALL) @as(i16, @intCast(k)) else 15, LIMITEXP, FRONTSPACE, LIMITIRFRAC);
                var width: i16 = stringWidth(&tmpStringL, font, true, true) + 1;
                if (strstr(&tmpStringL, ".") != null or strstr(&tmpStringL, ",") != null) {
                    var xStr: [*c]u8 = &tmpStringL;
                    while (xStr.* != 0) : (xStr += 1) {
                        const isEngLike = (displayFormat == DF_ENG or (displayFormat == DF_ALL and getSystemFlag(FLAG_ENGOVR)));
                        const cond1 = (displayFormat != DF_ENG and (displayFormat != DF_ALL or !getSystemFlag(FLAG_ENGOVR))) and (xStr.* == '.' or xStr.* == ',');
                        const cond2 = isEngLike and xStr[0] == 0x80 and (xStr[1] == 0x87 or xStr[1] == 0xd7);
                        if (cond1 or cond2) {
                            rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j] = stringWidth(xStr, font, true, true) + 1;
                            if (maxRightWidth_r[j] < rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j]) {
                                maxRightWidth_r[j] = rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j];
                            }
                            break;
                        }
                    }
                    if (maxLeftWidth_r[j] < (width - rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j])) {
                        maxLeftWidth_r[j] = (width - rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j]);
                    }
                } else {
                    if (c34sign and strstr(&tmpStringL, "/") != null) {
                        width += stringWidth("-", font, true, true);
                    }
                    rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j] = width | exponentOutOfRange;
                }

                rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j] = 0;
                c34sign = false;
                if (!polarMode) {
                    c34sign = real34IsNegative(&matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol].im);
                    real34SetPositiveSign(&c34Val.im);
                }
                real34ToDisplayString(&c34Val.im, if (polarMode) @as(u32, @bitCast(@as(i32, angleMode))) else amNone, &tmpStringL, font, maxWidth, if (displayFormat == DF_ALL) @as(i16, @intCast(k)) else 15, LIMITEXP, !FRONTSPACE, LIMITIRFRAC);
                width = stringWidth(&tmpStringL, font, true, true) + 1;
                if (strstr(&tmpStringL, ".") != null or strstr(&tmpStringL, ",") != null) {
                    var xStr: [*c]u8 = &tmpStringL;
                    while (xStr.* != 0) : (xStr += 1) {
                        const isEngLike = (displayFormat == DF_ENG or (displayFormat == DF_ALL and getSystemFlag(FLAG_ENGOVR)));
                        const cond1 = (displayFormat != DF_ENG and (displayFormat != DF_ALL or !getSystemFlag(FLAG_ENGOVR))) and (xStr.* == '.' or xStr.* == ',');
                        const cond2 = isEngLike and xStr[0] == 0x80 and (xStr[1] == 0x87 or xStr[1] == 0xd7);
                        if (cond1 or cond2) {
                            rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j] = stringWidth(xStr, font, true, true) + 1;
                            if (maxRightWidth_i[j] < rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j]) {
                                maxRightWidth_i[j] = rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j];
                            }
                            break;
                        }
                    }
                    if (maxLeftWidth_i[j] < (width - rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j])) {
                        maxLeftWidth_i[j] = (width - rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j]);
                    }
                } else {
                    if (c34sign and strstr(&tmpStringL, "/") != null) {
                        width += stringWidth("-", font, true, true);
                    }
                    rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j] = width | exponentOutOfRange;
                }
            }
        }
        {
            var pi: usize = 0;
            while (pi < maxRows) : (pi += 1) {
                var j: usize = 0;
                while (j < maxCols) : (j += 1) {
                    if ((rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] & exponentOutOfRange) != 0) {
                        if ((maxLeftWidth_r[j] + maxRightWidth_r[j]) < (rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] & (~exponentOutOfRange))) {
                            maxLeftWidth_r[j] = (rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] & (~exponentOutOfRange)) - maxRightWidth_r[j];
                        }
                    }
                    if ((rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] & exponentOutOfRange) != 0) {
                        if ((maxLeftWidth_i[j] + maxRightWidth_i[j]) < (rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] & (~exponentOutOfRange))) {
                            maxLeftWidth_i[j] = (rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] & (~exponentOutOfRange)) - maxRightWidth_i[j];
                        }
                    }
                }
            }
        }
        {
            var pi: usize = 0;
            while (pi < maxRows) : (pi += 1) {
                var j: usize = 0;
                while (j < maxCols) : (j += 1) {
                    if ((rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] & exponentOutOfRange) != 0) {
                        rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] = 0;
                    } else {
                        rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] -= maxRightWidth_r[j];
                        rPadWidth_rPtr[pi * MATRIX_MAX_COLUMNS + j] *= -1;
                    }
                    if ((rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] & exponentOutOfRange) != 0) {
                        rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] = 0;
                    } else {
                        rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] -= maxRightWidth_i[j];
                        rPadWidth_iPtr[pi * MATRIX_MAX_COLUMNS + j] *= -1;
                    }
                }
            }
        }
        {
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                colWidth_rPtr[j] = maxLeftWidth_r[j] + maxRightWidth_r[j];
                colWidth_iPtr[j] = maxLeftWidth_i[j] + maxRightWidth_i[j];
                colWidthPtr[j] = colWidth_rPtr[j] + (if (colWidth_iPtr[j] > 0) (cpxUnitWidth + colWidth_iPtr[j]) else 0);
                totalWidth += colWidthPtr[j] + stringWidth(STD_SPACE_FIGURE, font, true, true) * 2;
            }
        }
        totalWidth -= stringWidth(STD_SPACE_FIGURE, font, true, true);
        if (displayFormat != DF_ALL) {
            break;
        } else if (totalWidth <= maxWidth) {
            digitsPtr.* = @intCast(k);
            break;
        } else if (k > 1) {
            totalWidth = 0;
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                maxRightWidth_r[j] = 0;
                maxLeftWidth_r[j] = 0;
                maxRightWidth_i[j] = 0;
                maxLeftWidth_i[j] = 0;
            }
        }
    }
    return totalWidth;
}

extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
inline fn strcmpEq(a: [*c]const u8, b: [*c]const u8) bool {
    return strcmp(a, b) == 0;
}

// ===========================================================================
// z47_frontier_matrix_* BRIDGE HELPERS (defined only in the shim previously).
// Signatures must match the siblings' `extern fn` declarations exactly.
// ===========================================================================

pub export fn z47_frontier_matrix_get_register_as_int(regist: u16, as_array_pointer: bool) callconv(.c) i16 {
    return getRegisterAsInt(as_array_pointer, @bitCast(regist));
}

pub export fn z47_frontier_matrix_set_register_as_int(regist: u16, as_array_pointer: bool, to_store: i16) callconv(.c) void {
    setRegisterAsInt(as_array_pointer, to_store, @bitCast(regist));
}

pub export fn z47_frontier_matrix_is_register_matrix_vector(regist: u16) callconv(.c) bool {
    return isRegisterMatrixVector(@bitCast(regist));
}

pub export fn z47_frontier_matrix_vector_polar_mode(regist: u16) callconv(.c) u16 {
    return getVectorRegisterPolarMode(@bitCast(regist));
}

pub export fn z47_frontier_matrix_open_rows() callconv(.c) u16 {
    return openMatrixMIMPointer.header.matrixRows;
}

pub export fn z47_frontier_matrix_open_cols() callconv(.c) u16 {
    return openMatrixMIMPointer.header.matrixColumns;
}

pub export fn z47_frontier_matrix_commit_open_to_register() callconv(.c) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, @bitCast(matrixIndex));
    } else {
        convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, @bitCast(matrixIndex));
    }
}

pub export fn z47_frontier_matrix_calc_mode_normal_gui() callconv(.c) void {
    calcModeNormalGui();
}

pub export fn z47_frontier_matrix_hide_cursor() callconv(.c) void {
    hideCursor();
    cursorEnabled = 0;
}

pub export fn z47_frontier_matrix_reload_open_matrix_from_register() callconv(.c) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        if (openMatrixMIMPointer.realMatrix.matrixElements != null) {
            realMatrixFree(&openMatrixMIMPointer.realMatrix);
        }
        convertReal34MatrixRegisterToReal34Matrix(@bitCast(matrixIndex), &openMatrixMIMPointer.realMatrix);
    } else {
        if (openMatrixMIMPointer.complexMatrix.matrixElements != null) {
            complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
        }
        convertComplex34MatrixRegisterToComplex34Matrix(@bitCast(matrixIndex), &openMatrixMIMPointer.complexMatrix);
    }
}
extern fn convertReal34MatrixRegisterToReal34Matrix(regist: calcRegister_t, matrix: *real34Matrix_t) void;
extern fn convertComplex34MatrixRegisterToComplex34Matrix(regist: calcRegister_t, matrix: *complex34Matrix_t) void;

// callByIndexedMatrix dispatch (matrixEditor.c static). The inc/dec real/complex
// helpers are file-local.
fn incIReal(matrix: *real34Matrix_t) bool_t {
    setRegisterAsInt(true, getRegisterAsInt(true, REGISTER_I) + 1, REGISTER_I);
    _ = wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns);
    return false;
}
fn decIReal(matrix: *real34Matrix_t) bool_t {
    setRegisterAsInt(true, getRegisterAsInt(true, REGISTER_I) - 1, REGISTER_I);
    _ = wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns);
    return false;
}
fn incJReal(matrix: *real34Matrix_t) bool_t {
    setRegisterAsInt(true, getRegisterAsInt(true, REGISTER_J) + 1, REGISTER_J);
    if (wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns)) {
        insRowRealMatrix(matrix, matrix.header.matrixRows, addFlag); // addFlag: append at the true end (rows is swapped to 1 for colVector)
        return true;
    }
    return false;
}
fn decJReal(matrix: *real34Matrix_t) bool_t {
    setRegisterAsInt(true, getRegisterAsInt(true, REGISTER_J) - 1, REGISTER_J);
    _ = wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns);
    return false;
}
fn incJComplex(matrix: *complex34Matrix_t) bool_t {
    setRegisterAsInt(true, getRegisterAsInt(true, REGISTER_J) + 1, REGISTER_J);
    if (wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns)) {
        insRowComplexMatrix(matrix, matrix.header.matrixRows, addFlag); // addFlag: append at the true end (rows is swapped to 1 for colVector)
        return true;
    }
    return false;
}

// callByIndexedMatrix: dispatch on the open matrix's data type.
fn callByIndexedMatrix(realFn: *const fn (*real34Matrix_t) bool_t, complexFn: *const fn (*complex34Matrix_t) bool_t) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        _ = realFn(&openMatrixMIMPointer.realMatrix);
    } else {
        _ = complexFn(&openMatrixMIMPointer.complexMatrix);
    }
}
fn incIComplex(matrix: *complex34Matrix_t) bool_t {
    return incIReal(@ptrCast(matrix));
}
fn decIComplex(matrix: *complex34Matrix_t) bool_t {
    return decIReal(@ptrCast(matrix));
}
fn decJComplex(matrix: *complex34Matrix_t) bool_t {
    return decJReal(@ptrCast(matrix));
}

pub export fn z47_frontier_matrix_inc_dec_i(mode: u16) callconv(.c) void {
    callByIndexedMatrix(if (mode == DEC_FLAG) decIReal else incIReal, if (mode == DEC_FLAG) decIComplex else incIComplex);
}

pub export fn z47_frontier_matrix_inc_dec_j(mode: u16) callconv(.c) void {
    callByIndexedMatrix(if (mode == DEC_FLAG) decJReal else incJReal, if (mode == DEC_FLAG) decJComplex else incJComplex);
}

pub export fn z47_frontier_matrix_insert_row(add: bool) callconv(.c) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        insRowRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getRegisterAsInt(true, REGISTER_I)), add);
    } else {
        insRowComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getRegisterAsInt(true, REGISTER_I)), add);
    }
}

pub export fn z47_frontier_matrix_insert_col(add: bool) callconv(.c) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        insColRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getRegisterAsInt(true, REGISTER_J)), add);
    } else {
        insColComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getRegisterAsInt(true, REGISTER_J)), add);
    }
}

pub export fn z47_frontier_matrix_delete_row() callconv(.c) void {
    if (openMatrixMIMPointer.header.matrixRows > 1) {
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            delRowRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getRegisterAsInt(true, REGISTER_I)));
        } else {
            delRowComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getRegisterAsInt(true, REGISTER_I)));
        }
    }
}

pub export fn z47_frontier_matrix_delete_col() callconv(.c) void {
    if (openMatrixMIMPointer.header.matrixColumns > 1) {
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            delColRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getRegisterAsInt(true, REGISTER_J)));
        } else {
            delColComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getRegisterAsInt(true, REGISTER_J)));
        }
    }
}

pub export fn z47_frontier_matrix_finalize_open_matrix_memory() callconv(.c) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        if (openMatrixMIMPointer.realMatrix.matrixElements != null) {
            realMatrixFree(&openMatrixMIMPointer.realMatrix);
        }
    } else if (getRegisterDataType(@bitCast(matrixIndex)) == dtComplex34Matrix) {
        if (openMatrixMIMPointer.complexMatrix.matrixElements != null) {
            complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
        }
    }
}

pub export fn z47_frontier_matrix_aim_is_empty() callconv(.c) bool {
    return aimBuffer[0] == 0;
}

pub export fn z47_frontier_matrix_reset_cursor_pos() callconv(.c) void {
    resetCursorPos();
}

pub export fn z47_frontier_matrix_init_aim_exponent() callconv(.c) void {
    aimBuffer[0] = '+';
    aimBuffer[1] = '1';
    aimBuffer[2] = '.';
    aimBuffer[3] = 0;
    nimNumberPart = NP_REAL_FLOAT_PART;
    resetCursorPos();
}

pub export fn z47_frontier_matrix_init_aim_period() callconv(.c) void {
    aimBuffer[0] = '+';
    aimBuffer[1] = '0';
    aimBuffer[2] = 0;
    nimNumberPart = NP_INT_10;
    resetCursorPos();
}

pub export fn z47_frontier_matrix_init_aim_digit() callconv(.c) void {
    aimBuffer[0] = '+';
    aimBuffer[1] = 0;
    nimNumberPart = NP_INT_10;
    resetCursorPos();
}

pub export fn z47_frontier_matrix_aim_is_single_plus_digit() callconv(.c) bool {
    return (aimBuffer[0] == '+') and (aimBuffer[1] != 0) and (aimBuffer[2] == 0);
}

pub export fn z47_frontier_matrix_aim_clear_single_plus_digit() callconv(.c) void {
    aimBuffer[1] = 0;
    hideCursor();
    cursorEnabled = 0;
}

pub export fn z47_frontier_matrix_zero_current_element() callconv(.c) void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getRegisterAsInt(true, REGISTER_I);
    const col: i16 = getRegisterAsInt(true, REGISTER_J);
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        real34SetZero(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    } else {
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].re);
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].im);
    }
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn z47_frontier_matrix_change_sign_current_element() callconv(.c) void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getRegisterAsInt(true, REGISTER_I);
    const col: i16 = getRegisterAsInt(true, REGISTER_J);
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        real34ChangeSign(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    } else {
        real34ChangeSign(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].re);
        real34ChangeSign(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].im);
    }
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn z47_frontier_matrix_make_j_element() callconv(.c) void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getRegisterAsInt(true, REGISTER_I);
    const col: i16 = getRegisterAsInt(true, REGISTER_J);

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        var cxma: complex34Matrix_t = undefined;
        convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
        realMatrixFree(&openMatrixMIMPointer.realMatrix);
        convertComplex34MatrixToComplex34MatrixRegister(&cxma, @bitCast(matrixIndex));
        if ((getSystemFlag(FLAG_POLAR) and !temporaryFlagRect) or temporaryFlagPolar) {
            setRegisterTag(@bitCast(matrixIndex), @as(u32, @bitCast(@as(i32, currentAngularMode))) | amPolar);
        }
        openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
        openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
        openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;
    } else {
        const elm = &openMatrixMIMPointer.complexMatrix.matrixElements.?[@intCast(@as(c_int, row) * cols + @as(c_int, col))];
        if ((getSystemFlag(FLAG_POLAR) and !temporaryFlagRect) or temporaryFlagPolar) {
            var theta: real_t = undefined;
            realCopy(const39_piOn2, &theta);
            convertAngleFromTo(&theta, amRadian, currentAngularMode, &ctxtReal39);
            real34SetOne(&elm.re);
            realToReal34(&theta, &elm.im);
        } else {
            real34SetZero(&elm.re);
            real34SetOne(&elm.im);
        }
    }
}

pub export fn z47_frontier_matrix_set_current_to_pi() callconv(.c) void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getRegisterAsInt(true, REGISTER_I);
    const col: i16 = getRegisterAsInt(true, REGISTER_J);
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        realToReal34(const39_pi, &openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    } else {
        realToReal34(const39_pi, &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].re);
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].im);
    }
}

pub export fn z47_frontier_matrix_can_append_pi_literal() callconv(.c) bool {
    return nimNumberPart == NP_COMPLEX_INT_PART and aimBuffer[strlen(aimBuffer) - 1] == 'i';
}

pub export fn z47_frontier_matrix_append_pi_literal_and_enter() callconv(.c) void {
    _ = strcat(aimBuffer, "3.141592653589793238462643383279503");
    reallyRunFunction(ITM_ENTER, NOPARAM);
}

pub export fn z47_frontier_matrix_add_item_to_nim_buffer(item: i16) callconv(.c) void {
    addItemToNimBuffer(item);
}

var saved_is_complex: bool_t = false;
var saved_re: real34_t = undefined;
var saved_im: real34_t = undefined;

pub export fn z47_frontier_matrix_open_is_complex() callconv(.c) bool {
    return getRegisterDataType(@bitCast(matrixIndex)) == dtComplex34Matrix;
}

pub export fn z47_frontier_matrix_capture_selected_before() callconv(.c) void {
    const i: i16 = getRegisterAsInt(true, REGISTER_I);
    const j: i16 = getRegisterAsInt(true, REGISTER_J);
    saved_is_complex = z47_frontier_matrix_open_is_complex();
    const idx: usize = @intCast(@as(c_int, i) * @as(c_int, openMatrixMIMPointer.header.matrixColumns) + @as(c_int, j));

    if (saved_is_complex) {
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].re, &saved_re);
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].im, &saved_im);
    } else {
        real34Copy(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx], &saved_re);
        real34SetZero(&saved_im);
    }
}

pub export fn z47_frontier_matrix_load_selected_into_register_x() callconv(.c) void {
    const i: i16 = getRegisterAsInt(true, REGISTER_I);
    const j: i16 = getRegisterAsInt(true, REGISTER_J);
    var re: real34_t = undefined;
    var im: real34_t = undefined;
    const isComplex = z47_frontier_matrix_open_is_complex();
    const idx: usize = @intCast(@as(c_int, i) * @as(c_int, openMatrixMIMPointer.header.matrixColumns) + @as(c_int, j));

    if (isComplex) {
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].re, &re);
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].im, &im);
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        real34Copy(&re, &regCplx(REGISTER_X).re);
        real34Copy(&im, regImag34(REGISTER_X));
    } else {
        real34Copy(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx], &re);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        real34Copy(&re, reg34(REGISTER_X));
    }
}

pub export fn z47_frontier_matrix_run_item_function(func: i16, param: u16) callconv(.c) void {
    reallyRunFunction(func, param);
}

pub export fn z47_frontier_matrix_register_type(reg: u16) callconv(.c) u32 {
    return getRegisterDataType(@bitCast(reg));
}

pub export fn z47_frontier_matrix_convert_register_x_long_to_real34() callconv(.c) void {
    convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
}

pub export fn z47_frontier_matrix_convert_register_x_short_to_real34() callconv(.c) void {
    convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
}

pub export fn z47_frontier_matrix_apply_register_x_to_selected() callconv(.c) bool {
    const i: i16 = getRegisterAsInt(true, REGISTER_I);
    const j: i16 = getRegisterAsInt(true, REGISTER_J);
    const isComplex = z47_frontier_matrix_open_is_complex();
    const idx: usize = @intCast(@as(c_int, i) * @as(c_int, openMatrixMIMPointer.header.matrixColumns) + @as(c_int, j));

    if (isComplex and getRegisterDataType(REGISTER_X) == dtComplex34) {
        complex34Copy(regCplx(REGISTER_X), &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx]);
        return false;
    }

    if (isComplex) {
        real34Copy(reg34(REGISTER_X), &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].re);
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].im);
        return false;
    }

    if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        var cxma: complex34Matrix_t = undefined;
        var ans: complex34_t = undefined;

        complex34Copy(regCplx(REGISTER_X), &ans);
        convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
        realMatrixFree(&openMatrixMIMPointer.realMatrix);
        convertComplex34MatrixToComplex34MatrixRegister(&cxma, @bitCast(matrixIndex));
        openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
        openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
        openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;

        complex34Copy(&ans, &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx]);
        return true;
    }

    real34Copy(reg34(REGISTER_X), &openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    return false;
}

pub export fn z47_frontier_matrix_restore_saved_selected_if_x_and_not_converted() callconv(.c) void {
    if (matrixIndex != @as(u16, @bitCast(REGISTER_X))) {
        return;
    }

    const i: i16 = getRegisterAsInt(true, REGISTER_I);
    const j: i16 = getRegisterAsInt(true, REGISTER_J);

    if (saved_is_complex) {
        var linkedMatrix: complex34Matrix_t = undefined;
        convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, REGISTER_X);
        linkToComplexMatrixRegister(REGISTER_X, &linkedMatrix);
        const idx: usize = @intCast(@as(c_int, i) * @as(c_int, linkedMatrix.header.matrixColumns) + @as(c_int, j));
        real34Copy(&saved_re, &linkedMatrix.matrixElements.?[idx].re);
        real34Copy(&saved_im, &linkedMatrix.matrixElements.?[idx].im);
    } else {
        var linkedMatrix: real34Matrix_t = undefined;
        convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, REGISTER_X);
        linkToRealMatrixRegister(REGISTER_X, &linkedMatrix);
        const idx: usize = @intCast(@as(c_int, i) * @as(c_int, linkedMatrix.header.matrixColumns) + @as(c_int, j));
        real34Copy(&saved_re, &linkedMatrix.matrixElements.?[idx]);
    }
}

pub export fn z47_frontier_matrix_update_height_cache() callconv(.c) void {
    updateMatrixHeightCache();
}

pub export fn z47_frontier_matrix_softmenu_has_m_edit() callconv(.c) bool {
    var i: usize = 0;
    while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
        if (softmenu[@intCast(softmenuStack[i].softmenuId)].menuItem == -MNU_M_EDIT) {
            return true;
        }
    }
    return false;
}

pub export fn z47_frontier_matrix_softmenu_top_is_m_edit() callconv(.c) bool {
    return softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_M_EDIT;
}

pub export fn z47_frontier_matrix_show_m_edit_softmenu() callconv(.c) void {
    showSoftmenu(-MNU_M_EDIT);
}

pub export fn z47_frontier_matrix_scroll_row_get() callconv(.c) u16 {
    return scrollRow;
}

pub export fn z47_frontier_matrix_scroll_row_set(row: u16) callconv(.c) void {
    scrollRow = row;
}

pub export fn z47_frontier_matrix_render_editor_body(colVector: bool, rows: i16, cols: i16, matSelRow: i16, matSelCol: i16) callconv(.c) void {
    _ = rows;
    var width: i16 = 0;

    if (aimBuffer[0] == 0) {
        clearRegisterLine(NIM_REGISTER_LINE, true, true);
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            showRealMatrix(&openMatrixMIMPointer.realMatrix, 0, toDisplayVectorMatrix, !regXp);
        } else {
            showComplexMatrix(&openMatrixMIMPointer.complexMatrix, 0, currentAngularMode, getSystemFlag(FLAG_POLAR), !regXp);
        }
    } else {
        clearRegisterLine(NIM_REGISTER_LINE, false, true);
    }

    const hairArg: [*c]const u8 = if (aimBuffer[0] == 0) STD_SPACE_HAIR else "";
    const spaceArg: [*c]const u8 = if (aimBuffer[0] == 0 or aimBuffer[0] == '-') "" else " ";
    _ = sprintf(tmpString, "%" ++ "d;%" ++ "d=" ++ STD_SPACE_4_PER_EM ++ "%s%s%s", @as(c_int, if (colVector) matSelCol + 1 else matSelRow + 1), @as(c_int, if (colVector) 1 else matSelCol + 1), hairArg, spaceArg, nimBufferDisplay);
    width = stringWidth(tmpString, &numericFont, true, true) + 1;
    if (aimBuffer[0] == 0) {
        const selIdx: usize = @intCast(@as(c_int, matSelRow) * @as(c_int, cols) + @as(c_int, matSelCol));
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            real34ToDisplayString(&openMatrixMIMPointer.realMatrix.matrixElements.?[selIdx], amNone, tmpString + strlen(tmpString), &numericFont, SCREEN_WIDTH - width, NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, LIGHTIRFRAC);
        } else {
            complex34ToDisplayString(&openMatrixMIMPointer.complexMatrix.matrixElements.?[selIdx], tmpString + strlen(tmpString), &numericFont, SCREEN_WIDTH - width, NUMBER_OF_DISPLAY_DIGITS, LIMITEXP, FRONTSPACE, LIMITIRFRAC, @as(u16, @bitCast(@as(i16, @truncate(currentAngularMode)))), getSystemFlag(FLAG_POLAR));
        }

        _ = showString(tmpString, &numericFont, 0, Y_POSITION_OF_NIM_LINE, 0, true, false);
    } else {
        if (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/') {
            var lastBase = std.mem.zeroes([12]u8);
            var lb: [*c]u8 = &lastBase;
            const ld: u32 = lastDenominator;
            if (ld >= 1000) {
                lb[0] = STD_SUB_0[0];
                lb += 1;
                lb[0] = @intCast(@as(u32, STD_SUB_0[1]) + (ld / 1000));
                lb += 1;
            }
            if (ld >= 100) {
                lb[0] = STD_SUB_0[0];
                lb += 1;
                lb[0] = @intCast(@as(u32, STD_SUB_0[1]) + (ld % 1000 / 100));
                lb += 1;
            }
            if (ld >= 10) {
                lb[0] = STD_SUB_0[0];
                lb += 1;
                lb[0] = @intCast(@as(u32, STD_SUB_0[1]) + (ld % 100 / 10));
                lb += 1;
            }
            lb[0] = STD_SUB_0[0];
            lb += 1;
            lb[0] = @intCast(@as(u32, STD_SUB_0[1]) + (ld % 10));
            lb += 1;
            lb[0] = 0;
            displayNim(tmpString, &lastBase, stringWidth(&lastBase, &numericFont, true, true), stringWidth(&lastBase, &standardFont, true, true));
        } else {
            displayNim(tmpString, "", 0, 0);
        }
    }

    if (temporaryInformation == TI_SHOW_REGISTER and calcMode == CM_MIM) {
        mimShowElement();
        clearRegisterLine(REGISTER_T, true, true);
        refreshRegisterLine(REGISTER_T);
        if (tmpString[SHOWLineSize] != 0) {
            clearRegisterLine(REGISTER_Z, true, true);
            refreshRegisterLine(REGISTER_Z);
        }
    }

    if (lastErrorCode != ERROR_NONE) {
        refreshRegisterLine(errorMessageRegisterLine);
    }
}

pub export fn z47_frontier_matrix_mim_enter_apply_aim_buffer() callconv(.c) void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getRegisterAsInt(true, REGISTER_I);
    const col: i16 = getRegisterAsInt(true, REGISTER_J);
    var realChanged: bool_t = false;
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (aimBuffer[0] == 0) {
        return;
    }

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        var real34tmp: real34_t = undefined;
        const real34Ptr = &openMatrixMIMPointer.realMatrix.matrixElements.?[idx];

        switch (nimNumberPart) {
            NP_FRACTION_DENOMINATOR, NP_HP32SII_DENOMINATOR => {
                closeNimWithFraction(&real34tmp);
                realChanged = true;
            },
            NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_FRACTION_DENOMINATOR, NP_COMPLEX_HP32SII_DENOMINATOR => {
                var cxma: complex34Matrix_t = undefined;
                convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
                realMatrixFree(&openMatrixMIMPointer.realMatrix);
                convertComplex34MatrixToComplex34MatrixRegister(&cxma, @bitCast(matrixIndex));
                openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
                openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
                openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;
                const complex34Ptr = &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx];
                closeNimWithComplex(&complex34Ptr.re, &complex34Ptr.im);
            },
            else => {
                stringToReal34(aimBuffer, &real34tmp);
                realChanged = true;
            },
        }

        if (realChanged) {
            real34Copy(&real34tmp, real34Ptr);
        }
    } else {
        const complex34Ptr = &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx];

        switch (nimNumberPart) {
            NP_FRACTION_DENOMINATOR, NP_HP32SII_DENOMINATOR => {
                closeNimWithFraction(&complex34Ptr.re);
                real34SetZero(&complex34Ptr.im);
            },
            NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_FRACTION_DENOMINATOR, NP_COMPLEX_HP32SII_DENOMINATOR => {
                closeNimWithComplex(&complex34Ptr.re, &complex34Ptr.im);
            },
            else => {
                stringToReal34(aimBuffer, &complex34Ptr.re);
                real34SetZero(&complex34Ptr.im);
            },
        }
    }

    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
    hideCursor();
    cursorEnabled = 0;
    setSystemFlag(FLAG_ASLIFT);
}

pub export fn z47_frontier_matrix_mim_enter_commit_open_matrix() callconv(.c) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, @bitCast(matrixIndex));
        setRegisterTag(@bitCast(matrixIndex), openMatrixMIMPointer.header.mtag);
    } else {
        convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, @bitCast(matrixIndex));
        setRegisterTag(@bitCast(matrixIndex), openMatrixMIMPointer.header.mtag);
    }
}

// ===========================================================================
// wrapIJ — file-local copy used by the inc/dec helpers above. The PUBLIC wrapIJ
// is exported by frontier.zig (matrix_nav module); this private impl mirrors it
// so callByIndexedMatrix stays self-contained without taking a dependency on the
// sibling's internal name.
// ===========================================================================
fn wrapIJImpl(rows: u16, cols: u16) bool_t {
    clearSystemFlag(FLAG_WRAPEDG);
    clearSystemFlag(FLAG_WRAPEND);
    if (getRegisterAsInt(true, REGISTER_I) < 0) {
        setRegisterAsInt(true, @intCast(@as(c_int, rows) - 1), REGISTER_I);
        setSystemFlag(FLAG_WRAPEDG);
        setRegisterAsInt(true, if (getRegisterAsInt(true, REGISTER_J) == 0) @as(i16, @intCast(@as(c_int, cols) - 1)) else getRegisterAsInt(true, REGISTER_J) - 1, REGISTER_J);
        if (getRegisterAsInt(true, REGISTER_J) == @as(i16, @intCast(@as(c_int, cols) - 1)) and getRegisterAsInt(true, REGISTER_I) == @as(i16, @intCast(@as(c_int, rows) - 1))) {
            setSystemFlag(FLAG_WRAPEND);
        }
    } else {
        if (getRegisterAsInt(true, REGISTER_I) == @as(i16, @bitCast(rows))) {
            setRegisterAsInt(true, 0, REGISTER_I);
            setSystemFlag(FLAG_WRAPEDG);
            setRegisterAsInt(true, if (getRegisterAsInt(true, REGISTER_J) == @as(i16, @intCast(@as(c_int, cols) - 1))) 0 else getRegisterAsInt(true, REGISTER_J) + 1, REGISTER_J);
            if (getRegisterAsInt(true, REGISTER_J) == 0 and getRegisterAsInt(true, REGISTER_I) == 0) {
                setSystemFlag(FLAG_WRAPEND);
            }
        }
    }

    if (getRegisterAsInt(true, REGISTER_J) < 0) {
        setRegisterAsInt(true, @intCast(@as(c_int, cols) - 1), REGISTER_J);
        setSystemFlag(FLAG_WRAPEDG);
        setRegisterAsInt(true, if (getRegisterAsInt(true, REGISTER_I) == 0) @as(i16, @intCast(@as(c_int, rows) - 1)) else getRegisterAsInt(true, REGISTER_I) - 1, REGISTER_I);
        if (getRegisterAsInt(true, REGISTER_J) == @as(i16, @intCast(@as(c_int, cols) - 1)) and getRegisterAsInt(true, REGISTER_I) == @as(i16, @intCast(@as(c_int, rows) - 1))) {
            setSystemFlag(FLAG_WRAPEND);
        }
    } else {
        if (getRegisterAsInt(true, REGISTER_J) == @as(i16, @bitCast(cols))) {
            setRegisterAsInt(true, 0, REGISTER_J);
            setSystemFlag(FLAG_WRAPEDG);
            setRegisterAsInt(true, if ((!getSystemFlag(FLAG_GROW)) and (getRegisterAsInt(true, REGISTER_I) == @as(i16, @intCast(@as(c_int, rows) - 1)))) 0 else getRegisterAsInt(true, REGISTER_I) + 1, REGISTER_I);
            if (getRegisterAsInt(true, REGISTER_I) == 0 and getRegisterAsInt(true, REGISTER_J) == 0) {
                setSystemFlag(FLAG_WRAPEND);
            }
        }
    }
    return getRegisterAsInt(true, REGISTER_I) == @as(i16, @bitCast(rows));
}

comptime {
    // Force-reference the lifecycle/dead globals so they are not stripped and so
    // the legacy symbol set is preserved exactly.
    _ = &matEditMode;
    _ = &tmpRow;
}
