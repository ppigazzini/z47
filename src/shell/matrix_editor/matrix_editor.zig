const std = @import("std");
const matrix_mim_run = @import("matrix_mim_run.zig");
const matrix_mim_add = @import("matrix_mim_add.zig");
const matrix_nav = @import("matrix_nav.zig");
const consts = abi.constants;
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/ui/matrixEditor.c — the *residue* of the matrix editor
// that the sibling matrix_* owners do NOT already provide.
//
// Division of labour (verified by grep across src/shell/):
//   * The ~30 PUBLIC matrixEditor.c functions (fnEditMatrix, fnOldMatrix,
//     fnGoToElement, fnGoToRow, fnGoToColumn, fnSetGrowMode, fnIncDecI,
//     fnIncDecJ, fnInsRow, fnAddRow, fnInsCol, fnAddCol, fnDelRow, fnDelCol,
//     getIRegisterAsInt, getJRegisterAsInt, setIRegisterAsInt,
//     setJRegisterAsInt, wrapIJ, _fnInsRow, _fnInsCol, mimFinalize, mimRestore,
//     mimAddNumber, mimRunFunction, showMatrixEditor, mimEnter) are reimplemented
//     in Zig and exported by shell.zig (which dispatches into the matrix_*
//     module owners: matrix_editor_entry, matrix_editor_refresh, matrix_nav,
//     matrix_goto_grow, matrix_lifecycle, matrix_mim_add, matrix_mim_run,
//     matrix_mutation).
//     => This owner does NOT export any of them.
//
//   * The parts of matrixEditor.c that no sibling matrix_* owner provides:
//       (a) the 4 NON-renamed publics of matrixEditor.c:
//           showRealMatrix, showComplexMatrix, getRealMatrixColumnWidths,
//           getComplexMatrixColumnWidths;
//       (b) the file-scope globals: openMatrixMIMPointer, scrollRow,
//           scrollColumn, tmpRow, matrixIndex (the sibling owners declare these
//           `extern` — calc_mode_owned, goto_grow_owned, etc. — but the
//           DEFINITION lives here);
//       (c) all 49 z47_frontier_matrix_* bridge helpers the sibling modules call
//           (defined here, declared `extern fn` by the siblings).
//     => This owner provides (a)+(b)+(c). It is, in effect, the rest of
//        matrixEditor.c plus the bridge layer.
//
// Build flavour, matching the sibling owners and the dominant C config:
//   OPTION_VECTOR is ON (defines.h:70; only #undef'd in space-saving DMCP
//   packages). OPTION_VECTOR_EDIT is OFF (defines.h:73). The two OPTION_IR_PRINTING
//   trace calls matrixEditor.c makes — printTraceString for the number-entry
//   buffer mimEnter closes, printTrace for the j/CC complex promotion — are
//   reproduced here behind the print owner's ir_printing flag. The PC_BUILD
//   refreshLcd() tail of mimRunFunction is host-only (!dmcp_build).
//   EXTRA_INFO_ON_CALC_ERROR console hints are gated on extra_info; the one that
//   lands here is the "works in MIM only" refusal shared by _fnInsRow, _fnInsCol,
//   fnDelRow and fnDelCol, which is why it takes the refusing function's name.
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
// Types (reused verbatim from calc_mode.zig so the union/struct
// layout matches the siblings' externs exactly).
// ===========================================================================
const bool_t = bool;
const calcRegister_t = i16;
const angularMode_t = c_int; // C enum -> int ABI
const videoMode_t = c_int;
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
// decNumber (real_t): big enough working buffer. The matrix display code only
// passes real_t by pointer to extern helpers and never inspects the layout, but
// we still need a correctly-sized storage type for the on-stack `aa,bb,cc,theta`
// locals. DECNUMDIGITS=75 -> lsu has ceil(75/3)=25 units (uint16). Header is
// digits(i32)+exponent(i32)+bits(u8)+pad. Use the canonical c47 layout.
const decNumberUnit = u16;
const abi = @import("abi"); // shared ABI bindings
const matrix_wrap = @import("matrix_wrap.zig"); // std-only matrix I/J cursor wrap
const frontier_bufferize = @import("../display/bufferize.zig");
const frontier_char_string = @import("../display/text/char_string.zig");
const frontier_conversion_angles = @import("../convert/conversion_angles.zig");
const frontier_display = @import("../display/display.zig");
const frontier_error = @import("../error.zig");
const frontier_items = @import("../display/items/items.zig");
const frontier_print = @import("../print/print.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
const frontier_screen = @import("../display/screen.zig");
const frontier_softmenus = @import("../display/softmenus/softmenus.zig");
const real_t = abi.Real;
const realContext_t = abi.RealContext;
// decContext layout is centralized in abi.RealContext (oracle-verified == C
// decContext by abi-layout-parity); alias instead of re-mirroring the fields.
const decContext = abi.RealContext;
const font_t = abi.Font;

const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;
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
const FLAG_M_ALL: c_int = 0x8072;
const FLAG_SIGZEROS: c_int = 0x806a;
const FLAG_SSIZE8: c_int = 0x8018;
const FLAG_GROW: c_int = 0x801d;
const FLAG_WRAPEND: c_int = 0xc01a;
const FLAG_ASLIFT: c_int = 0xc023;
const FLAG_WRAPEDG: c_int = 0xc03F;
const FLAG_IRFRAC: c_int = 0x8047;
const FLAG_3DPHYS: c_int = 0x8065;

const MNU_M_EDIT: i16 = 3079;

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
const TI_SHOW_REGISTER_BIG: u8 = 75;
const TI_SHOW_REGISTER_SMALL: u8 = 76;
const TI_SHOW_REGISTER_TINY: u8 = 77;
const TI_SHOWNOTHING: u8 = 93;
const CM_NORMAL: u8 = 0;
const CM_MIM: u8 = 12;

// SHOWMODE (defines.h): the whole screen belongs to the SHOW, so a matrix drawn
// under it may use every row.
inline fn SHOWMODE() bool {
    return calcMode == CM_NORMAL and switch (temporaryInformation) {
        TI_SHOW_REGISTER, TI_SHOW_REGISTER_BIG, TI_SHOW_REGISTER_SMALL, TI_SHOW_REGISTER_TINY, TI_SHOWNOTHING => true,
        else => false,
    };
}

const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_Z: calcRegister_t = 102;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_D: calcRegister_t = 107;
const SAVED_REGISTER_X: calcRegister_t = 126;
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
const ERROR_MESSAGE_LENGTH: usize = 512;

const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const option_vector: bool = frontier_build_options.option_vector;
const option_mx_show: bool = frontier_build_options.option_mx_show;

const LINE_NOLF: u16 = 3;

const NUMERIC_FONT_HEIGHT: i16 = 36;
const STANDARD_FONT_HEIGHT: i16 = 22;
const NUMERIC_FONT_HEIGHT_: i16 = NUMERIC_FONT_HEIGHT - 4;
const STANDARD_FONT_HEIGHT_: i16 = STANDARD_FONT_HEIGHT - 2;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;
const DF_SF: u8 = 4;
const DF_UN: u8 = 5;

// irfracOption_t (display.h): LIMITIRFRAC=1, LIGHTIRFRAC=2.
const irfracOption_t = c_int;
const LIMITIRFRAC: irfracOption_t = 1;
const LIGHTIRFRAC: irfracOption_t = 2;
const LIMITEXP: bool_t = true;
const FRONTSPACE: bool_t = true;

const LCD_EMPTY_VALUE: c_int = 0xFF;
const LCD_SET_VALUE: c_int = 0;

// matrixEditor.h
const MATRIX_LINE_WIDTH: i16 = 380;
const MATRIX_MAX_ROWS: usize = 9; // measure cap outside SHOW
// sizes the row scratch arrays
const MATRIX_MAX_ROWS_ON_SHOW: usize = if (option_mx_show) 11 else 9;
const MATRIX_MAX_ROWS_ON_VIEW: usize = 7; // VIEW keeps the stack, so it stops above the menu
const MATRIX_MAX_ROWS_ON_STACK: usize = 5; // a matrix on the stack grows from the X line up
// above any rendered string, so real34ToDisplayString keeps the requested digit count
const UNSHRUNK_WIDTH: i16 = 9999;
const MATRIX_MAX_COLUMNS: usize = 14; // max width: no radix on the elements, so single-digit columns fit 14

// regXp is a `#define ... true` in matrix.h.
const regXp: bool_t = true;

// STRIP_INTEGER_MATRIX_RADIX (matrixEditor.c): an all-integer column is drawn in
// FIX 0, and the trailing radix that leaves behind is dropped.
const STRIP_INTEGER_MATRIX_RADIX: bool = true;

// addFlag macro.
const addFlag: bool_t = true;

// String constants (fonts.h byte sequences).
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_ALMOST_EQUAL = "\xa2\x48";
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
// matEditMode went with upstream's "remove two globals that are never read or
// written" at the 6559a9c59 pin.
// ===========================================================================
// These are mutable RAM globals (matrixEditor.c file-scope, normal .data/.bss);
// they must NOT go into .qspi (read-only XIP flash). Default section.
// C's `any34Matrix_t openMatrixMIMPointer;` is a file-scope global -> .bss
// ZERO-initialized, so .realMatrix.matrixElements starts NULL. `= undefined`
// would leave garbage: getMatrixFromRegister's `matrixElements != null` guard
// then passes on the first edit and frees a wild pointer (freeC47Blocks ->
// toC47MemPtr @intCast panic in `debug` / heap corruption in `fast`). Match
// C's zero-init.
pub export var openMatrixMIMPointer: AnyMatrix = std.mem.zeroes(AnyMatrix);
pub export var scrollRow: u16 = 0;
pub export var scrollColumn: u16 = 0;
pub export var tmpRow: u16 = 0;
pub export var matrixIndex: u16 = INVALID_VARIABLE;

/// A reshape can leave scrollColumn past the last column of the new shape. Both
/// display paths then derive their column count as `cols - sCol` on unsigned, which
/// wraps to an enormous width. Bound it to the shape the matrix actually has, and
/// reset the stored offset so the next redraw starts from the left.
fn boundScrollColumn(forEditor: bool, sCol: u16, cols: u16) u16 {
    if (forEditor and sCol >= cols) {
        scrollColumn = 0;
        return 0;
    }
    return sCol;
}

// ===========================================================================
// External globals (c47 owns these).
// ===========================================================================
extern var calcMode: u8;
extern var lastErrorCode: u8;
extern var lastFunc: i16;
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
extern var showMatrixUserDisplayFormat: u8;
extern var showMatrixUserDisplayFormatDigits: u8;
extern var displayFormatDigits: u8;
extern var exponentLimit: i16;

extern const numericFont: font_t;
extern const standardFont: font_t;

// ctxtReal39 is a realContext_t value; referenced only by address.
extern var ctxtReal39: realContext_t;

// const39_pi / const39_piOn2 / const_0 are `#define`s into the shared
// `constants` byte blob ((real_t *)(constants + offset)), NOT linkable symbols.
// Bind the blob by address and index by the generated byte offsets, matching
// conversion_angles.zig.
const const39_pi = consts.c1848();
const const39_piOn2 = consts.c4880();
const const_0 = consts.c1708();

const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;
const softmenu = @extern([*]const softmenu_t, .{ .name = "softmenu" });
extern var softmenuStack: [SOFTMENU_STACK_SIZE]softmenuStack_t;

// ===========================================================================
// External functions.
// ===========================================================================
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*]u8;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn reallocateRegister(regist: calcRegister_t, dataType: u32, dataSizeWithoutDataLenBlocks: u16, tag: u32) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;
extern fn saveForUndo() void;
inline fn getStackTop() calcRegister_t {
    return if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
}

extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool_t;

extern fn real34IsAnInteger(x: *const real34_t) bool_t;
extern fn decQuadIsZero(d: *const real34_t) u32;
inline fn real34IsZero(source_: *const real34_t) bool {
    return decQuadIsZero(source_) != 0;
}
extern fn realCompareLessThan(n1: *const real_t, n2: *const real_t) bool_t;
extern fn decQuadZero(r: *real34_t) *real34_t;
extern fn decQuadDigits(d: *const real34_t) u32;
extern fn decQuadGetExponent(d: *const real34_t) i32;
// C narrows both decQuad results to int16_t; the special-value sentinel exponents
// overflow i16, which is fine there, so truncate rather than @intCast.
inline fn real34Digits(source_: *const real34_t) i16 {
    return @bitCast(@as(u16, @truncate(decQuadDigits(source_))));
}
inline fn real34GetExponent(source_: *const real34_t) i16 {
    return @bitCast(@as(u16, @truncate(@as(u32, @bitCast(decQuadGetExponent(source_))))));
}
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

extern fn convert3DtoSPH(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, th2: *real_t, am: u8, ctx: *const decContext) void;
extern fn convert3DtoCYL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, z: *real_t, am: u8, ctx: *const decContext) void;
extern fn convert2DtoPOL(matrix: *const real34Matrix_t, r: *real_t, th1: *real_t, am: u8, ctx: *const decContext) void;

extern fn realMatrixFree(matrix: *real34Matrix_t) void;
extern fn complexMatrixFree(matrix: *complex34Matrix_t) void;
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
    return abi.registerMatrixHeader(regist);
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
const MpzStruct = abi.Mpz;
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
    return &c.real;
}
inline fn cIm(c: *complex34_t) *real34_t {
    return &c.imag;
}
const reg34 = abi.registerReal34Aligned;
const regCplx = abi.registerComplex34Aligned;
const regImag34 = abi.registerImag34Aligned;

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
        frontier_register_value_conversions.convertLongIntegerRegisterToLongInteger(reg, &tmp_lgInt);
    } else if (getRegisterDataType(reg) == dtReal34) {
        frontier_register_value_conversions.convertReal34ToLongInteger(reg34(reg), &tmp_lgInt, DEC_ROUND_DOWN);
    } else {
        __gmpz_init(&tmp_lgInt);
    }
    // longIntegerToInt32 is a plain assignment in C, so it narrows by
    // truncation. c_long is 64-bit on the host, and an I or J register can
    // legitimately hold a value outside int32.
    ret = @truncate(__gmpz_get_si(&tmp_lgInt));
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
    frontier_register_value_conversions.convertLongIntegerToLongIntegerRegister(&tmp_lgInt, reg);
    __gmpz_clear(&tmp_lgInt);
}

// getRegisterAsInt / setRegisterAsInt above address the USER's I and J. Nothing in
// this file may call them except getIRegisterAsInt, getJRegisterAsInt,
// setIRegisterAsInt and setJRegisterAsInt below, which answer the shadow pair while
// the editor is open. Reading the raw registers there reports the user's I and J,
// which are 0 with the editor open -- one less than that, as an array pointer.

// _resetCursorPos (static in matrixEditor.c). Used by the init-aim helpers.
fn resetCursorPos() void {
    frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, false, true);
    abi.fmtBufZ(tmpString[0..2560], "{d};{d}= ", .{ @as(i32, getIRegisterAsInt(false)), @as(i32, getJRegisterAsInt(false)) });
    xCursor = frontier_screen.showString(tmpString, &numericFont, 0, Y_POSITION_OF_NIM_LINE, 0, 1, 1) + 1;
    yCursor = Y_POSITION_OF_NIM_LINE;
    cursorEnabled = 1;
    cursorFont = &numericFont;
    frontier_screen.setLastintegerBasetoZero();
}

// displayVectorAngle (static). OPTION_VECTOR is undefined on every DM42 package,
// where the C compiles this whole body away and leaves toBeAngle as the caller
// set it, so a tagged polar vector's element renders as a plain number there.
fn displayVectorAngle(matrix: *const real34Matrix_t, j: c_int, rows: c_int, cols: c_int, toBeAngle: *u8) void {
    if (comptime !option_vector) return;
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
    // OPTION_VECTOR is undefined on every DM42 package. There the C's polar branch
    // is not compiled at all and the function is only its noPolarVector tail, the
    // rectangular copy below.
    if (comptime !option_vector) {
        real34Copy(&matrix.matrixElements.?[@intCast(ii)], element);
        return;
    }
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

// C hands these int16_t screen coordinates to showString's uint32_t parameters by
// implicit conversion. MATRIX_LINE_WIDTH leaves no room for the brackets, so a
// matrix that only just fits it starts left of column zero and the value is
// negative; wrap it exactly as C does rather than refusing the cast.
inline fn screenPos(v: i16) u32 {
    return @bitCast(@as(i32, v));
}

// The one copy of the integer-column rule, used by the viewer and by
// updateMatrixHeightCache so the height cache and the drawn matrix cannot drift
// apart.
pub export fn getRealMatrixIntegerColumns(matrix: *const real34Matrix_t, dispFormat: u16, cols: u16, sRow: u16, sCol: u16, maxRows: u16, maxCols: u16, allElementsInColAreIntegers: [*c]bool_t) callconv(.c) void {
    const allowIntegerDisplay = dispFormat != DF_ENG and dispFormat != DF_UN and dispFormat != DF_SF and
        !(isMatrixVector(@intCast(maxRows), @intCast(maxCols)) and (is3dVectorPolarSPH(matrix.header.mtag) or is3dVectorPolarCYL(matrix.header.mtag) or is2dVectorPolar(matrix.header.mtag)));
    var j: usize = 0;
    while (j < maxCols) : (j += 1) {
        allElementsInColAreIntegers[j] = allowIntegerDisplay;
        if (!allElementsInColAreIntegers[j]) continue;
        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            const element = &matrix.matrixElements.?[(i + sRow) * @as(usize, cols) + j + sCol];
            // An integer column is drawn in FIX 0, and past 1E15 the digits after
            // the radix would be clamped out of the E-form. Take the column out of
            // integer mode once it is too big to display.
            if (!real34IsAnInteger(element) or (real34Digits(element) > 1 and real34GetExponent(element) + real34Digits(element) - 1 >= 15)) {
                allElementsInColAreIntegers[j] = false;
                break;
            }
        }
    }
}

// The SHOW page test: not used on VIEW or on the stack display.
inline fn MX_SHOW_PAGE(prefixWidth: i16, regXposition: bool_t) bool {
    return option_mx_show and SHOWMODE() and prefixWidth > 0 and !regXposition;
}

// The upright fit test.
// ALL draws every significant digit a value has, so where the layout the stack line uses shows the whole
// matrix in ALL there is nothing left for another page to open up. A column vector is measured in the
// one-line form it takes there. The measurement is in the standard font and in ALL, with the trailing
// radix of an integer stripped, the form an integer column is drawn in.
// Real only. The complex path passes false for keepOneLine, so a complex matrix takes the rolled out page
// whenever it fits, whether or not the upright page shows it whole. Replicating this needs a second
// measuring function over complex34Matrix_t: getComplexMatrixColumnWidths measures that same width already
// but calls showsVerticalVector itself, so it cannot be the pre-test without circularity. The gain is a
// small complex matrix on the one line it already fits on.
fn matrixFitsUpright(matrix: *const real34Matrix_t, prefixWidth: i16) bool {
    if (comptime !option_mx_show) return false;
    const rows: usize = matrix.header.matrixRows;
    const cols: usize = matrix.header.matrixColumns;
    const colVector = (cols == 1 and rows > 1);
    const upRows: usize = if (colVector) 1 else rows;
    const upCols: usize = if (colVector) rows else cols;
    var tmpStr: [200]u8 = @splat(0);
    const tmpFormat = displayFormat;
    const tmpFormatDigits = displayFormatDigits;
    var width: i16 = frontier_char_string.stringWidth("[" ++ STD_MAT_BR, &standardFont, true, true);
    if (upCols > MATRIX_MAX_COLUMNS or upRows > MATRIX_MAX_ROWS_ON_SHOW) {
        return false; // more than the upright layout draws
    }
    displayFormat = DF_ALL;
    displayFormatDigits = 0;
    var j: usize = 0;
    while (j < upCols) : (j += 1) {
        var widest: i16 = 0;
        var i: usize = 0;
        while (i < upRows) : (i += 1) {
            frontier_display.real34ToDisplayString(&matrix.matrixElements.?[if (colVector) j else i * cols + j], amNone, &tmpStr, &standardFont, UNSHRUNK_WIDTH, 34, @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIMITIRFRAC);
            if (STRIP_INTEGER_MATRIX_RADIX) {
                frontier_char_string.stripTrailingRadix(&tmpStr);
            }
            const element = frontier_char_string.stringWidth(&tmpStr, &standardFont, true, true);
            widest = if (element > widest) element else widest;
        }
        width += widest + frontier_char_string.stringWidth(STD_SPACE_FIGURE, &standardFont, true, true);
    }
    displayFormat = tmpFormat;
    displayFormatDigits = tmpFormatDigits;
    return width <= MATRIX_LINE_WIDTH - prefixWidth;
}

// The SHOW vertical vector test.
// A plain vector shows one element per line, and so does a matrix whose elements plus one blank line
// between its rows fit the page. Tagged and polar vectors keep the one-line form, and so does the stack
// line during an active SHOW state. keepOneLine is the matrix the upright layout already shows whole.
fn showsVerticalVector(header: *align(1) const matrixHeader_t, prefixWidth: i16, regXposition: bool_t, keepOneLine: bool) bool {
    if (comptime !option_mx_show) return false;
    const rows: u32 = header.matrixRows;
    const cols: u32 = header.matrixColumns;
    return SHOWMODE() and prefixWidth > 0 and !regXposition and !keepOneLine and
        (if (rows == 1 or cols == 1) rows * cols >= 2 else rows * cols + rows - 1 <= MATRIX_MAX_ROWS_ON_SHOW) and
        getTagAngularMode(header.mtag) == amNone and !is2dVectorPolar(header.mtag);
}

// The vertical vector budget: screen width less prefix, brackets and the ^T of a transposed row vector.
fn showsVerticalVectorMaxWidth(header: *align(1) const matrixHeader_t, font: *const font_t, prefixWidth: i16) i16 {
    return SCREEN_WIDTH - 1 - prefixWidth - frontier_char_string.stringWidth("[", font, true, true) - frontier_char_string.stringWidth(STD_MAT_BR, font, true, true) -
        // the rolled out page sets the matrix bracket outside the row brackets
        (if (header.matrixRows > 1 and header.matrixColumns > 1) frontier_char_string.stringWidth("[]", font, true, true) else 0) -
        (if (header.matrixRows == 1) frontier_char_string.stringWidth(STD_SUP_BOLD_T, font, true, true) else 0);
}

// SHOW format and vector reshape.
// M.ALL set: the optimised ALL page. M.ALL clear: the stashed user format. A row vector folds to a
// column, marked ^T.
fn reshapeVerticalVector(header: *align(1) const matrixHeader_t, prefixWidth: i16, regXposition: bool_t, keepOneLine: bool, rows: *c_int, cols: *c_int, colVector: *bool, transposedVector: *bool) bool {
    const verticalVector = showsVerticalVector(header, prefixWidth, regXposition, keepOneLine);
    colVector.* = false;
    transposedVector.* = false;
    if (comptime option_mx_show) {
        if (SHOWMODE() and prefixWidth > 0) {
            // one M.ALL page, digits 0
            displayFormat = if (getSystemFlag(FLAG_M_ALL)) DF_ALL else showMatrixUserDisplayFormat;
            displayFormatDigits = if (getSystemFlag(FLAG_M_ALL)) 0 else showMatrixUserDisplayFormatDigits;
        }
    }
    if (verticalVector) {
        if (rows.* == 1) { // a row vector folds, marked ^T
            transposedVector.* = true;
            rows.* = cols.*;
            cols.* = 1;
        } else if (cols.* > 1) { // a matrix rolls out row by row into one column
            rows.* = rows.* * cols.*;
            cols.* = 1;
        }
    } else if (cols.* == 1 and rows.* > 1) {
        colVector.* = true;
        cols.* = rows.*;
        rows.* = 1;
    }
    return verticalVector;
}

// The SIG fit of one value.
// Lowers the SIG count with the window at 34; the internal width shrink flips plain values to sci.
// Returns true when digits shed.
fn sigFitReal34(value: *const real34_t, tag: u8, dest: [*c]u8, font: *const font_t, budget: i16, frontSpace: bool_t) bool {
    const tmpDigits = displayFormatDigits;
    var ddFree: c_int = 33;
    var dd: c_int = 33;
    while (dd >= 1) : (dd -= 1) { // SIG n shows n+1 digits
        displayFormatDigits = @intCast(dd);
        frontier_display.real34ToDisplayString(value, tag, dest, font, UNSHRUNK_WIDTH, 34, @intFromBool(LIMITEXP), @intFromBool(frontSpace), LIMITIRFRAC);
        if (strstr(dest, STD_SUB_10) == null) { // the unconstrained best count
            ddFree = dd;
            break;
        }
    }
    var chosen: c_int = 0;
    var fallback: c_int = 0;
    dd = 33;
    while (dd >= 1) : (dd -= 1) {
        displayFormatDigits = @intCast(dd);
        frontier_display.real34ToDisplayString(value, tag, dest, font, UNSHRUNK_WIDTH, 34, @intFromBool(LIMITEXP), @intFromBool(frontSpace), LIMITIRFRAC);
        if (frontier_char_string.stringWidth(dest, font, true, true) <= budget) {
            if (strstr(dest, STD_SUB_10) == null) { // plain wins over sci
                chosen = dd;
                break;
            }
            if (fallback == 0) {
                fallback = dd; // sci-only fallback count
            }
        }
    }
    if (chosen == 0) {
        chosen = if (fallback > 0) fallback else 1;
        displayFormatDigits = @intCast(chosen);
        frontier_display.real34ToDisplayString(value, tag, dest, font, UNSHRUNK_WIDTH, 34, @intFromBool(LIMITEXP), @intFromBool(frontSpace), LIMITIRFRAC);
    }
    displayFormatDigits = tmpDigits;
    return chosen < ddFree; // shed when below the free fit
}

// The laid flat page test.
// A vector, a two row matrix or a two column matrix that the upright page cannot show whole runs its
// rows, or its columns, along the line and wraps. A column runs flat once the page cannot take every row,
// a row once it is wider than the columns the line takes. keepOneLine is the matrix the upright layout
// already shows whole, which needs no other page.
fn laysFlatOnShow(header: *align(1) const matrixHeader_t, prefixWidth: i16, regXposition: bool_t, keepOneLine: bool) bool {
    if (comptime !option_mx_show) return false;
    const rows: u32 = header.matrixRows;
    const cols: u32 = header.matrixColumns;
    if (!(SHOWMODE() and prefixWidth > 0 and !regXposition) or keepOneLine or getTagAngularMode(header.mtag) != amNone or is2dVectorPolar(header.mtag)) {
        return false;
    }
    if (rows == 1 or cols == 1) {
        return rows * cols > MATRIX_MAX_ROWS_ON_SHOW; // the upright page shows them all up to its line count
    }
    if (rows == 2) {
        return rows * cols + rows - 1 > MATRIX_MAX_ROWS_ON_SHOW; // wider than the rolled out page takes
    }
    if (cols == 2) {
        return rows > MATRIX_MAX_ROWS_ON_SHOW;
    }
    return false;
}

// The width of a rendered element up to and including its radix mark, which is what the cells are
// aligned on.
fn flatLeftWidth(str: [*c]const u8, font: *const font_t) i16 {
    var head: [200]u8 = @splat(0);
    var used: usize = 0;
    var scan: [*c]const u8 = str;
    while (scan.* != 0) : (scan += 1) {
        head[used] = scan.*;
        used += 1;
        if (scan.* == '.' or scan.* == ',') {
            break;
        }
    }
    head[used] = 0;
    return frontier_char_string.stringWidth(&head, font, true, true);
}

// The laid flat page.
// One matrix row, or one matrix column, runs along the line and wraps to the next until the page is
// full. Every line after the first names the row or the column it carries. The brackets sit at the two
// ends only, and a page read by column closes with the transpose mark.
fn showRealMatrixFlat(matrix: *const real34Matrix_t, prefixWidth: i16) void {
    if (comptime !option_mx_show) return;
    var elem: [200]u8 = @splat(0);
    const font: *const font_t = &standardFont;
    const rows: usize = matrix.header.matrixRows;
    const cols: usize = matrix.header.matrixColumns;
    const byColumn = (cols == 1) or (rows > 2 and cols == 2);
    const runs: usize = if (byColumn) cols else rows;
    const runLength: usize = if (byColumn) rows else cols;
    const gap: i16 = frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
    // the row and column names sit left of the bracket
    const labelWidth: i16 = if (runs > 1) frontier_char_string.stringWidth("r2: ", font, true, true) else 0;
    const leftMargin: i16 = if (prefixWidth > labelWidth) prefixWidth else labelWidth;
    const avail: i16 = SCREEN_WIDTH - 1 - leftMargin - frontier_char_string.stringWidth("[]", font, true, true) - (if (byColumn) frontier_char_string.stringWidth(STD_SUP_BOLD_T, font, true, true) else 0);
    const tmpDisplayFormat = displayFormat;
    const tmpDisplayFormatDigits = displayFormatDigits;
    var maxLeft: i16 = 0;
    var maxRight: i16 = 0;
    var cellWidth: i16 = avail;
    var fontHeight: i16 = STANDARD_FONT_HEIGHT_;
    var perLine: usize = 1;
    var linesPerRun: usize = runLength;
    var totalLines: usize = runs * runLength;
    var digits: i16 = 34;

    // the whole page is one stream, so the integer rule is taken over all of it
    var allIntegers: bool_t = true;
    getRealMatrixIntegerColumns(matrix, displayFormat, @intCast(cols), 0, 0, @intCast(rows), 1, @ptrCast(&allIntegers));
    var element: usize = 0;
    while (allIntegers and element < rows * cols) : (element += 1) {
        const value = &matrix.matrixElements.?[element];
        if (!real34IsAnInteger(value) or (real34Digits(value) > 1 and real34GetExponent(value) + real34Digits(value) - 1 >= 15)) {
            allIntegers = false;
        }
    }
    if (allIntegers) {
        displayFormat = DF_FIX;
        displayFormatDigits = 0;
    }

    // the widest count whose whole page fits, the rule the upright page uses; below two the mantissa goes
    digits = 34;
    while (digits >= 2) : (digits -= 1) {
        maxLeft = 0;
        maxRight = 0;
        element = 0;
        while (element < rows * cols) : (element += 1) {
            frontier_display.real34ToDisplayString(&matrix.matrixElements.?[element], amNone, &elem, font, UNSHRUNK_WIDTH, digits, @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIMITIRFRAC);
            if (STRIP_INTEGER_MATRIX_RADIX and allIntegers) {
                frontier_char_string.stripTrailingRadix(&elem);
            }
            const left = flatLeftWidth(&elem, font);
            const whole = frontier_char_string.stringWidth(&elem, font, true, true);
            maxLeft = if (left > maxLeft) left else maxLeft;
            maxRight = if ((whole - left) > maxRight) (whole - left) else maxRight;
        }
        cellWidth = maxLeft + maxRight;
        perLine = @intCast(@divTrunc(avail + gap, cellWidth + gap));
        perLine = if (perLine < 1) 1 else perLine;
        linesPerRun = (runLength + perLine - 1) / perLine;
        totalLines = runs * linesPerRun;
        if (displayFormat != DF_ALL or totalLines <= MATRIX_MAX_ROWS_ON_SHOW) {
            break; // a format the user set keeps its own count, so only the ALL page searches for one
        }
    }
    const overflows = totalLines > MATRIX_MAX_ROWS_ON_SHOW;
    if (overflows) {
        totalLines = (MATRIX_MAX_ROWS_ON_SHOW / runs) * runs; // the page ends on a whole set of rows, or of columns
    }
    if (totalLines > MATRIX_MAX_ROWS) {
        fontHeight = STANDARD_FONT_HEIGHT_ - 1;
    }

    const X_POS: i16 = leftMargin;
    var Y_POS: i16 = Y_POSITION_OF_REGISTER_T_LINE - REGISTER_LINE_HEIGHT + 1 + @as(i16, @intCast(totalLines)) * fontHeight;
    Y_POS += (if (totalLines == 1) STANDARD_FONT_HEIGHT_ else REGISTER_LINE_HEIGHT - STANDARD_FONT_HEIGHT_);
    lcdFillRect(screenPos(X_POS), screenPos(Y_POS - @as(i16, @intCast(totalLines - 1)) * fontHeight), @intCast(SCREEN_WIDTH - X_POS), @intCast(@as(i16, @intCast(totalLines - 1)) * fontHeight + STANDARD_FONT_HEIGHT), LCD_SET_VALUE);

    var runLabel = [4]u8{ if (byColumn) 'c' else 'r', '0', ':', 0 };
    const cellsX: i16 = X_POS + frontier_char_string.stringWidth("[", font, true, true);
    var lastCell: i16 = 0;
    var line: usize = 0;
    while (line < totalLines) : (line += 1) {
        const lineY: i16 = Y_POS - @as(i16, @intCast(totalLines - 1 - line)) * fontHeight;
        const run = line % runs; // the rows, or the columns, alternate line by line so their elements stay side by side
        if (line < runs) { // the matrix bracket keeps the height it has on any other page, one line per row or column
            _ = frontier_screen.showString(if (runs == 1) "[" else if (line == 0) STD_MAT_TL else STD_MAT_BL, font, screenPos(X_POS), screenPos(lineY), 0, 1, 0);
        }
        if (line > 0 and runs > 1) { // a vector is one run, so there is nothing to name
            runLabel[1] = @intCast('1' + run);
            _ = frontier_screen.showString(&runLabel, font, 1, screenPos(lineY), 0, 1, 0);
        }
        var cell: usize = 0;
        while (cell < perLine) : (cell += 1) {
            const within = (line / runs) * perLine + cell;
            if (within >= runLength) {
                break;
            }
            if (overflows and line >= totalLines - runs and cell + 1 == perLine) { // every row, or every column, ends on its own ellipsis
                _ = frontier_screen.showString(STD_ELLIPSIS, font, screenPos(cellsX + @as(i16, @intCast(cell)) * (cellWidth + gap)), screenPos(lineY), 0, 1, 0);
                break;
            }
            frontier_display.real34ToDisplayString(&matrix.matrixElements.?[if (byColumn) within * cols + run else run * runLength + within], amNone, &elem, font, UNSHRUNK_WIDTH, digits, @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIMITIRFRAC);
            if (STRIP_INTEGER_MATRIX_RADIX and allIntegers) {
                frontier_char_string.stripTrailingRadix(&elem);
            }
            const elemX: i16 = cellsX + @as(i16, @intCast(cell)) * (cellWidth + gap) + maxLeft - flatLeftWidth(&elem, font);
            _ = frontier_screen.showString(&elem, font, screenPos(elemX), screenPos(lineY), 0, 1, 0);
        }
    }
    // The closing bracket keeps the same height and sits at the end of the last row, or of the last column
    if (overflows) { // the last cell of every row holds the ellipsis, so the bracket follows that
        lastCell = cellsX + @as(i16, @intCast(perLine - 1)) * (cellWidth + gap) + frontier_char_string.stringWidth(STD_ELLIPSIS, font, true, true);
    } else {
        const lastChunk = runLength - ((totalLines / runs) - 1) * perLine;
        lastCell = cellsX + @as(i16, @intCast(if (lastChunk > perLine) perLine else lastChunk)) * (cellWidth + gap) - gap;
    }
    line = totalLines - runs;
    while (line < totalLines) : (line += 1) {
        const lineY: i16 = Y_POS - @as(i16, @intCast(totalLines - 1 - line)) * fontHeight;
        _ = frontier_screen.showString(if (runs == 1) "]" else if (line + 1 == totalLines) STD_MAT_BR else STD_MAT_TR, font, screenPos(lastCell), screenPos(lineY), 0, 1, 0);
    }
    if (byColumn) {
        _ = frontier_screen.showString(STD_SUP_BOLD_T, font, screenPos(lastCell + frontier_char_string.stringWidth("]", font, true, true)), screenPos(Y_POS), 0, 1, 0);
    }
    displayFormat = tmpDisplayFormat;
    displayFormatDigits = tmpDisplayFormatDigits;
}

// A NULL `dest` draws the matrix. A non-NULL `dest` collects a one-row vector
// into it as a string and draws nothing. Each element is formatted at the end of
// `dest`, so `dest` is also the element scratch; tmpString is touched only when
// `dest` is NULL, which is what makes tmpString itself a valid `dest`.
pub export fn showRealMatrix(matrix: *const real34Matrix_t, prefixWidth: i16, regXposition: bool_t, dest: [*c]u8) callconv(.c) void {
    var rows: c_int = matrix.header.matrixRows;
    var cols: c_int = matrix.header.matrixColumns;
    var Y_POS: i16 = Y_POSITION_OF_REGISTER_X_LINE;
    var X_POS: i16 = 0;
    var totalWidth: i16 = 0;
    var width: i16 = 0;
    var font: *const font_t = &numericFont;
    var fontHeight: i16 = NUMERIC_FONT_HEIGHT_;
    var maxWidth: i16 = MATRIX_LINE_WIDTH_C - prefixWidth;
    var colWidth: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var rPadWidth: [MATRIX_MAX_ROWS_ON_SHOW * MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var allElementsInColAreIntegers: [MATRIX_MAX_COLUMNS]bool_t = @splat(false);
    const forEditor = matrix == &openMatrixMIMPointer.realMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    var sCol: u16 = if (forEditor) scrollColumn else 0;
    const tmpDisplayFormat: u16 = displayFormat;
    const tmpDisplayFormatDigits: u8 = displayFormatDigits;

    Y_POS = Y_POSITION_OF_REGISTER_X_LINE - NUMERIC_FONT_HEIGHT_;

    // Reshape and page format
    var colVector = false;
    var transposedVector = false;
    const fitsUpright = matrixFitsUpright(matrix, prefixWidth); // the upright layout shows it whole, so no other page is tried
    const verticalVector = reshapeVerticalVector(&matrix.header, prefixWidth, regXposition, fitsUpright, &rows, &cols, &colVector, &transposedVector);
    const showFormat: u16 = displayFormat; // restored on the font retry
    const showPage = MX_SHOW_PAGE(prefixWidth, regXposition); // the SHOW page, never the stack line
    const fixPage = showPage and displayFormat == DF_FIX;

    // One row only: a multi-row matrix, or the editor's own matrix, leaves dest
    // empty and the caller shows [n<*>n Matrix] instead.
    if (dest != null and (forEditor or rows > 1)) {
        dest[0] = 0;
        return;
    }

    if (comptime option_mx_show) {
        if (dest == null and !forEditor and laysFlatOnShow(&matrix.header, prefixWidth, regXposition, fitsUpright)) {
            showRealMatrixFlat(matrix, prefixWidth);
            displayFormat = @intCast(tmpDisplayFormat);
            displayFormatDigits = tmpDisplayFormatDigits;
            return;
        }
    }

    sCol = boundScrollColumn(forEditor, sCol, @intCast(cols));

    const toDisplay = (dest == null);

    if (dest != null) {
        _ = strcpy(dest, "[");
    }

    // The row limit per context
    var maxCols: u16 = if (cols > MATRIX_MAX_COLUMNS) MATRIX_MAX_COLUMNS else @intCast(cols);
    const rowLimit: usize = if (!regXposition and prefixWidth > 0)
        (if (SHOWMODE()) MATRIX_MAX_ROWS_ON_SHOW else MATRIX_MAX_ROWS_ON_VIEW)
    else
        MATRIX_MAX_ROWS_ON_STACK;
    const maxRows: u16 = if (rows > rowLimit) @intCast(rowLimit) else @intCast(rows);
    if (@as(c_int, maxCols) + @as(c_int, sCol) >= cols) {
        maxCols = @intCast(cols - @as(c_int, sCol));
    }

    // The rolled out page: every element on its own line, one blank line between the rows of the matrix it came from
    const groupCols: usize = if (verticalVector and matrix.header.matrixRows >= 2 and matrix.header.matrixColumns >= 2) matrix.header.matrixColumns else 0;
    const totalLines: usize = if (groupCols != 0) maxRows + matrix.header.matrixRows - 1 else maxRows;

    const matSelRow: i16 = if (colVector) getJRegisterAsInt(true) else getIRegisterAsInt(true);
    const matSelCol: i16 = if (colVector) getIRegisterAsInt(true) else getJRegisterAsInt(true);

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
        // The font choice. SHOW fits 5 numeric rows; padded SIG takes the small font.
        if (atSmallFontLabel or rows >= (if (showPage) @as(c_int, 6) else (if (forEditor) @as(c_int, 4) else @as(c_int, 5))) or
            (verticalVector and displayFormat == DF_SF and getSystemFlag(FLAG_SIGZEROS)))
        {
            font = &standardFont;
            fontHeight = STANDARD_FONT_HEIGHT_;
            Y_POS = Y_POSITION_OF_REGISTER_X_LINE - STANDARD_FONT_HEIGHT_;
        }
        // The vertical page layout
        if (verticalVector) {
            maxWidth = showsVerticalVectorMaxWidth(&matrix.header, font, prefixWidth); // same budget the column-width function fits against
        }
        if (comptime option_mx_show) {
            if (totalLines > MATRIX_MAX_ROWS) {
                fontHeight = STANDARD_FONT_HEIGHT_ - 1; // 11 rows at 19 px fit the screen
            }
        }

        if (!forEditor) {
            Y_POS += REGISTER_LINE_HEIGHT;
        }
        const rightEllipsis = (cols > @as(c_int, maxCols)) and (cols > @as(c_int, maxCols) + @as(c_int, sCol));
        const leftEllipsis = (sCol > 0);

        if (!regXposition and prefixWidth > 0) {
            Y_POS = Y_POSITION_OF_REGISTER_T_LINE - REGISTER_LINE_HEIGHT + 1 + @as(i16, @intCast(totalLines)) * fontHeight;
        }
        if (!regXposition and prefixWidth > 0 and font == &standardFont) {
            Y_POS += (if (totalLines == 1) STANDARD_FONT_HEIGHT_ else REGISTER_LINE_HEIGHT - STANDARD_FONT_HEIGHT_);
        }

        // Measure the column widths: the selected page format under OPTION_MX_SHOW, the user format without it
        getRealMatrixIntegerColumns(matrix, if (option_mx_show) displayFormat else tmpDisplayFormat, @intCast(cols), sRow, sCol, maxRows, maxCols, &allElementsInColAreIntegers);

        var baseWidth: i16 = (if (leftEllipsis) frontier_char_string.stringWidth(STD_ELLIPSIS ++ " ", font, true, true) else 0) + (if (rightEllipsis) frontier_char_string.stringWidth(" " ++ STD_ELLIPSIS, font, true, true) else 0);
        var mtxWidth = getRealMatrixColumnWidths(matrix, prefixWidth, regXposition, font, &colWidth, &rPadWidth, &digits, maxCols, &allElementsInColAreIntegers);
        var noFix = (mtxWidth < 0);
        mtxWidth = if (mtxWidth < 0) -mtxWidth else mtxWidth;
        totalWidth = baseWidth + mtxWidth;

        if (displayFormat == DF_ALL and noFix and getSystemFlag(FLAG_M_ALL)) { // the user format is kept unless M.ALL lets the bias make it fit
            displayFormat = if (getSystemFlag(FLAG_ENGOVR)) DF_ENG else DF_SCI;
            displayFormatDigits = @intCast(digits);
        }
        // Shed digits: retry small font
        if (totalWidth > maxWidth or leftEllipsis or (showPage and font == &numericFont and digits < 34)) {
            if (font == &numericFont) {
                displayFormat = @intCast(showFormat);
                displayFormatDigits = tmpDisplayFormatDigits;
                atSmallFontLabel = true;
                continue :smallFont;
            } else {
                if (tmpDisplayFormat == DF_ALL or getSystemFlag(FLAG_M_ALL)) { // the user format is used unless ALL may be biased to make it fit
                    displayFormat = if (getSystemFlag(FLAG_ENGOVR)) DF_ENG else DF_SCI; // ENGOVR decides the exponent form everywhere
                    displayFormatDigits = 3;
                }
                // the ellipsis takes its width off the budget, else the fit is measured without it
                mtxWidth = getRealMatrixColumnWidths(matrix, prefixWidth + baseWidth, regXposition, font, &colWidth, &rPadWidth, &digits, maxCols, &allElementsInColAreIntegers);
                noFix = (mtxWidth < 0);
                mtxWidth = if (mtxWidth < 0) -mtxWidth else mtxWidth;
                totalWidth = baseWidth + mtxWidth;
                // the width call fits without the ellipsis the caller adds, so an unfloored shrink strips every column
                if (totalWidth > maxWidth and maxCols > 1) {
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
                baseWidth += colWidth[j] + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
            }
        }
        baseWidth -= frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
        baseWidth += 3;

        var endChar: [6]u8 = @splat(0);
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
            X_POS = SCREEN_WIDTH - 1 - ((if (colVector) frontier_char_string.stringWidth("[", font, true, true) + frontier_char_string.stringWidth(&endChar, font, true, true) + frontier_char_string.stringWidth(STD_SUP_BOLD_T, font, true, true) else frontier_char_string.stringWidth("[", font, true, true) + frontier_char_string.stringWidth(&endChar, font, true, true)) + baseWidth) - (if (font == &standardFont) @as(i16, 0) else @as(i16, 1));
        }

        if (toDisplay) {
            if (forEditor) {
                frontier_screen.clearRegisterLine(REGISTER_X, true, true);
                frontier_screen.clearRegisterLine(REGISTER_Y, true, true);
                if (rows >= (if (font == &standardFont) @as(c_int, 3) else @as(c_int, 2))) {
                    frontier_screen.clearRegisterLine(REGISTER_Z, true, true);
                }
                if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                    frontier_screen.clearRegisterLine(REGISTER_T, true, true);
                }
            } else if (!regXposition and prefixWidth > 0) {
                // Blank the area behind the matrix.
                lcdFillRect(screenPos(X_POS), screenPos(Y_POS - @as(i16, @intCast(totalLines - 1)) * fontHeight), @intCast(frontier_char_string.stringWidth("[", font, true, true) + baseWidth + frontier_char_string.stringWidth(&endChar, font, true, true) + (if (transposedVector) frontier_char_string.stringWidth(STD_SUP_BOLD_T, font, true, true) else 0)), @intCast(if (font == &numericFont) @as(i16, @intCast(totalLines - 1)) * fontHeight + NUMERIC_FONT_HEIGHT else @as(i16, @intCast(totalLines - 1)) * fontHeight + STANDARD_FONT_HEIGHT), LCD_SET_VALUE);
            } else {
                // The stack position: a partial refresh leaves stale register text
                // in the band the matrix covers.
                lcdFillRect(screenPos(X_POS), screenPos(Y_POS - @as(i16, @intCast(maxRows - 1)) * fontHeight), @intCast(frontier_char_string.stringWidth("[", font, true, true) + baseWidth + frontier_char_string.stringWidth(&endChar, font, true, true)), @intCast(if (font == &numericFont) @as(i16, @intCast(maxRows - 1)) * fontHeight + NUMERIC_FONT_HEIGHT_ else @as(i16, @intCast(maxRows - 1)) * fontHeight + STANDARD_FONT_HEIGHT_), LCD_SET_VALUE);
            }
        }
        const displayFormat1: u16 = displayFormat;
        const displayFormatDigits1: u8 = displayFormatDigits;

        var colX: i16 = 0;
        var aa: real_t = undefined;
        var bb: real_t = undefined;
        var cc: real_t = undefined;

        // The rolled out page labels each row after the first in the prefix column
        const outerBracket: i16 = if (groupCols != 0) frontier_char_string.stringWidth("[", font, true, true) else 0;
        if (toDisplay and groupCols != 0) {
            var rowLabel = [4]u8{ 'r', '0', ':', 0 };
            var group: usize = 1;
            while (group < matrix.header.matrixRows) : (group += 1) {
                rowLabel[1] = @intCast('1' + group);
                _ = frontier_screen.showString(&rowLabel, &standardFont, 1, screenPos(Y_POS - @as(i16, @intCast(totalLines - 1 - group * (groupCols + 1))) * fontHeight), 0, 1, 0);
            }
        }

        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            const lineFromBottom: usize = if (groupCols != 0) (totalLines - 1 - (i + i / groupCols)) else (maxRows - 1 - i);
            if (toDisplay) {
                colX = frontier_char_string.stringWidth("[", font, true, true);
                _ = frontier_screen.showString(if (groupCols != 0) "[" else if (maxRows == 1) "[" else if (i == 0) STD_MAT_TL else if (i + 1 == maxRows) STD_MAT_BL else STD_MAT_ML, font, screenPos(X_POS + 5 + outerBracket), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 0, 0);
                if (groupCols != 0 and i == 0) { // the matrix bracket opens outside the row bracket of the first element
                    _ = frontier_screen.showString("[", font, screenPos(X_POS + 5), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 0, 0);
                }
                if (leftEllipsis) {
                    _ = frontier_screen.showString(STD_ELLIPSIS ++ " ", font, screenPos(X_POS + 5 + outerBracket + frontier_char_string.stringWidth("[", font, true, true)), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
                    colX += frontier_char_string.stringWidth(STD_ELLIPSIS ++ " ", font, true, true);
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

                var elem: [*c]u8 = undefined;
                if (dest == null) {
                    elem = tmpString;
                } else {
                    if (j > 0) {
                        _ = strcat(dest, " ");
                    }
                    elem = dest + strlen(dest); // stringByteLength
                }

                if (((i == maxRows - 1) and (rows > @as(c_int, maxRows) + @as(c_int, sRow))) or ((j == maxCols) and rightEllipsis) or ((i == 0) and (sRow > 0))) {
                    _ = strcpy(elem, " " ++ STD_ELLIPSIS);
                    vm = 0;
                } else {
                    var toBeAngle: u8 = amNone;
                    displayVectorAngle(matrix, @intCast(j), rows, cols, &toBeAngle);
                    var element: real34_t = undefined;

                    if (displayFormat != DF_ALL) {
                        // SHOW opens to 34 digits; the FIX page window is 33 so e33 up takes the sci form
                        digits = if (fixPage) 33 else (if (showPage) @as(i16, 34) else 15);
                    }
                    extractVectorElement34(matrix, @intCast(j), @intCast((i + sRow) * @as(usize, @intCast(cols)) + j + sCol), rows, cols, &element, &toBeAngle, @intCast(digits), &aa, &bb, &cc);
                    if (displayFormat == DF_SF and verticalVector) {
                        _ = sigFitReal34(&element, toBeAngle, elem, font, maxWidth - 4, FRONTSPACE); // same budget as measured
                    } else {
                        frontier_display.real34ToDisplayString(&element, toBeAngle, elem, font, colWidth[j], digits, @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), if (cols * rows > 3) LIMITIRFRAC else LIGHTIRFRAC);
                    }

                    if (STRIP_INTEGER_MATRIX_RADIX and allElementsInColAreIntegers[j]) {
                        frontier_char_string.stripTrailingRadix(elem);
                    }

                    if (toDisplay) {
                        if (forEditor and matSelRow == @as(i16, @intCast(i + sRow)) and matSelCol == @as(i16, @intCast(j + sCol))) {
                            lcdFillRect(screenPos(X_POS + 5 + outerBracket + colX), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), @intCast(colWidth[j]), if (font == &numericFont) 32 else 20, LCD_EMPTY_VALUE);
                            vm = 1;
                        } else {
                            vm = 0;
                        }
                    }
                }
                if (toDisplay) {
                    width = frontier_char_string.stringWidth(elem, font, true, true) + 1;
                    _ = frontier_screen.showString(elem, font, screenPos(X_POS + 5 + outerBracket + colX + (if ((j == maxCols) and rightEllipsis) -frontier_char_string.stringWidth(" ", font, true, true) else (colWidth[j] - width) - rPadWidth[i * MATRIX_MAX_COLUMNS + j])), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), vm, 1, 0);
                    colX += colWidth[j] + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) - 1;
                }
            }

            if (toDisplay) {
                _ = frontier_screen.showString(if (groupCols != 0) "]" else if (maxRows == 1) &endChar else if (i == 0) STD_MAT_TR else if (i + 1 == maxRows) STD_MAT_BR else STD_MAT_MR, font, screenPos(X_POS + outerBracket + frontier_char_string.stringWidth("[", font, true, true) + baseWidth), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
                if (groupCols != 0 and i + 1 == maxRows) { // the matrix bracket closes outside the row bracket of the last element
                    _ = frontier_screen.showString("]", font, screenPos(X_POS + outerBracket + frontier_char_string.stringWidth("[]", font, true, true) + baseWidth), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
                }
                if (colVector) {
                    _ = frontier_screen.showString(STD_SUP_BOLD_T, font, screenPos(X_POS + frontier_char_string.stringWidth("[", font, true, true) + frontier_char_string.stringWidth(&endChar, font, true, true) + baseWidth), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
                }
            }
            if (dest != null) {
                _ = strcat(dest, &endChar);
                if (colVector) {
                    _ = strcat(dest, STD_SUP_BOLD_T);
                }
            }
        }

        if (toDisplay and transposedVector) { // the ^T on the closing bracket
            _ = frontier_screen.showString(STD_SUP_BOLD_T, font, screenPos(X_POS + frontier_char_string.stringWidth("[", font, true, true) + frontier_char_string.stringWidth(STD_MAT_BR, font, true, true) + baseWidth), screenPos(Y_POS), 0, 1, 0);
        }

        break :smallFont;
    }

    // Restore the format globals
    displayFormat = @intCast(tmpDisplayFormat);
    displayFormatDigits = tmpDisplayFormatDigits;
}

pub export fn getRealMatrixColumnWidths(matrix: *const real34Matrix_t, prefixWidth: i16, regXposition: bool_t, font: *const font_t, colWidthPtr: [*c]i16, rPadWidthPtr: [*c]i16, digitsPtr: *i16, maxColsIn: u16, allElementsInColAreIntegersPtr: [*c]bool_t) callconv(.c) i16 {
    // The measured page shape
    var tmpStringL: [200]u8 = @splat(0);
    const showPage = MX_SHOW_PAGE(prefixWidth, regXposition); // the SHOW page, never the stack line
    const fixPage = showPage and displayFormat == DF_FIX;
    const verticalVector = showsVerticalVector(&matrix.header, prefixWidth, regXposition, matrixFitsUpright(matrix, prefixWidth)); // one shared column under SHOW
    const colVector = !verticalVector and matrix.header.matrixColumns == 1 and matrix.header.matrixRows > 1;
    // A column vector is laid out as one row, so the row count collapses to 1 and
    // the element count moves into the column count below.
    const rowsReal: c_int = if (verticalVector) @as(c_int, matrix.header.matrixRows) * @as(c_int, matrix.header.matrixColumns) else if (colVector) 1 else matrix.header.matrixRows;
    const actualCols: c_int = if (verticalVector) 1 else if (colVector) matrix.header.matrixRows else matrix.header.matrixColumns;
    const cols: c_int = if (actualCols > @as(c_int, maxColsIn)) @as(c_int, maxColsIn) else actualCols;
    const rowLimit: c_int = if (showPage) MATRIX_MAX_ROWS_ON_SHOW else MATRIX_MAX_ROWS; // SHOW takes more rows
    const maxRows: c_int = if (rowsReal > rowLimit) rowLimit else rowsReal;
    const forEditor = matrix == &openMatrixMIMPointer.realMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    const sCol: u16 = if (forEditor) scrollColumn else 0;
    // The width budget
    const maxWidth: i16 = if (verticalVector) showsVerticalVectorMaxWidth(&matrix.header, font, prefixWidth) else MATRIX_LINE_WIDTH_C - prefixWidth;
    var totalWidth: i16 = 0;
    var maxRightWidth: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var maxLeftWidth: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    const exponentOutOfRange: i16 = 0x4000;
    var noFix = false;
    const dspDigits: i16 = displayFormatDigits;
    var sfShed = false; // a row shed digits

    const maxCols: usize = maxColsIn;

    // The SHOW starting count
    var startDigitCountDown: u16 = @intCast(imax(imin(@as(c_int, displayFormatDigits) * (if (displayFormat == DF_ALL) @as(c_int, 2) else @as(c_int, 1)), imax(@divTrunc(@as(c_int, 50), cols) - 2, 0)), 10));
    if (showPage) {
        startDigitCountDown = 34; // start at full precision
        if (displayFormat == DF_SF) {
            startDigitCountDown = 33; // SIG n shows n+1 digits
        } else if (displayFormat == DF_FIX) { // cap FIX at 34 total digits
            var maxE: i16 = 0;
            var i: usize = 0;
            while (i < maxRows) : (i += 1) {
                var j: usize = 0;
                while (j < maxCols) : (j += 1) {
                    const e34 = &matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol];
                    const e: i16 = if (real34IsZero(e34)) 0 else real34GetExponent(e34) + real34Digits(e34) - 1;
                    // plain-renderable rows only; e33 up takes the sci form through the 33 window
                    if (!allElementsInColAreIntegersPtr[j] and e > maxE and e <= 32) {
                        maxE = e;
                    }
                }
            }
            startDigitCountDown = @intCast(imax(imin(33 - @as(c_int, maxE), 99), 1));
        }
    } else if (isMatrix3dVector(rowsReal, cols)) {
        startDigitCountDown = 5;
    } else if (isMatrix2dVector(rowsReal, cols)) {
        startDigitCountDown = 7;
    }

    begin: while (true) {
        var k: c_int = startDigitCountDown;
        kloop: while (k >= 1) : (k -= 1) {
            if (displayFormat == DF_ALL) {
                digitsPtr.* = @intCast(k);
            } else if (showPage) { // the shared maximised count
                displayFormatDigits = if (displayFormat == DF_SF and verticalVector) 34 else @intCast(k);
                digitsPtr.* = @intCast(k);
            }
            if (displayFormat == DF_ALL and noFix and getSystemFlag(FLAG_M_ALL)) { // something like SCI
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
                    // Measure one element: integer columns at 15 digits, SHOW at 34; the FIX page window is 33
                    const calcDigits: u16 = if (displayFormat == DF_ALL and !allElementsInColAreIntegersPtr[j]) @as(u16, @intCast(k)) else (if (fixPage) @as(u16, 33) else (if (showPage) @as(u16, 34) else 15));
                    // A row steps by the matrix width, not by the count of columns on screen.
                    extractVectorElement34(matrix, @intCast(j), @intCast((i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol), rowsReal, cols, &r34Val, &toBeAngle, calcDigits, &aa, &bb, &cc);

                    const r34sign = real34IsNegative(&r34Val);

                    if (allElementsInColAreIntegersPtr[j]) {
                        displayFormat = DF_FIX;
                        displayFormatDigits = 0;
                    } else {
                        displayFormat = @intCast(displayFormat1);
                        displayFormatDigits = displayFormatDigits1;
                    }

                    if (displayFormat == DF_SF and verticalVector) {
                        if (sigFitReal34(&r34Val, toBeAngle, &tmpStringL, font, maxWidth - 4, FRONTSPACE)) { // per-row SIG self-fit
                            sfShed = true;
                        }
                    } else {
                        // no internal shrink under SHOW: it hides shed digits and flips SIG to sci; the k countdown does the fitting
                        frontier_display.real34ToDisplayString(&r34Val, toBeAngle, &tmpStringL, font, if (showPage) UNSHRUNK_WIDTH else maxWidth, @intCast(calcDigits), @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), if (cols * rowsReal > 3) LIMITIRFRAC else LIGHTIRFRAC);
                    }
                    if (r34sign) { // the signed value rounds as the cell does; its sign is measured as the front space
                        if (std.mem.indexOfScalar(u8, std.mem.sliceTo(&tmpStringL, 0), '-')) |minusSign| {
                            tmpStringL[minusSign] = ' ';
                        }
                    }
                    if (STRIP_INTEGER_MATRIX_RADIX and allElementsInColAreIntegersPtr[j]) {
                        frontier_char_string.stripTrailingRadix(&tmpStringL);
                    }
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

                    // Align on the radix
                    var width: i16 = frontier_char_string.stringWidth(&tmpStringL, font, true, true) + 1;
                    rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j] = 0;
                    // vector SIG skips the line-up
                    if ((strstr(&tmpStringL, ".") != null or strstr(&tmpStringL, ",") != null) and !(verticalVector and displayFormat == DF_SF)) {
                        var xStr: [*c]u8 = &tmpStringL;
                        while (xStr.* != 0) : (xStr += 1) {
                            const isEngLike = (displayFormat == DF_ENG or (displayFormat == DF_ALL and getSystemFlag(FLAG_ENGOVR)));
                            const cond1 = (displayFormat != DF_ENG and (displayFormat != DF_ALL or !getSystemFlag(FLAG_ENGOVR))) and (xStr.* == '.' or xStr.* == ',');
                            const cond2 = isEngLike and xStr[0] == 0x80 and (xStr[1] == 0x87 or xStr[1] == 0xd7);
                            if (cond1 or cond2) {
                                rPadWidthPtr[i * MATRIX_MAX_COLUMNS + j] = frontier_char_string.stringWidth(xStr, font, true, true) + 1;
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
                        if (r34sign and (strstr(&tmpStringL, "/") != null or strstr(&tmpStringL, STD_ALMOST_EQUAL) != null)) {
                            width += frontier_char_string.stringWidth("-", font, true, true);
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
                    // One gap per column and a 3-pixel end margin: the sum the drawing
                    // code lays out, so the fit is neither heavy nor light.
                    totalWidth += colWidthPtr[j] + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
                }
            }
            totalWidth -= frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) - 3;
            if (noFix) {
                displayFormat = DF_ALL;
                displayFormatDigits = @intCast(dspDigits);
            }
            if (displayFormat != DF_ALL and !showPage) {
                break :kloop;
            } else if (totalWidth <= maxWidth) {
                // nothing shed: the font retry rests
                digitsPtr.* = if (showPage and k == startDigitCountDown and !sfShed) 34 else @intCast(k);
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
    var maxWidth: i16 = MATRIX_LINE_WIDTH_C - prefixWidth;
    var colWidth: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var colWidth_r: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var colWidth_i: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var rPadWidth_r: [MATRIX_MAX_ROWS_ON_SHOW * MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var rPadWidth_i: [MATRIX_MAX_ROWS_ON_SHOW * MATRIX_MAX_COLUMNS]i16 = @splat(0);
    const forEditor = matrix == &openMatrixMIMPointer.complexMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    var sCol: u16 = if (forEditor) scrollColumn else 0;
    const tmpDisplayFormat: u16 = displayFormat;
    const tmpExponentLimit: i16 = exponentLimit;
    const tmpDisplayFormatDigits: u8 = displayFormatDigits;
    const tmpMultX = getSystemFlag(FLAG_MULTx);

    Y_POS = Y_POSITION_OF_REGISTER_X_LINE - NUMERIC_FONT_HEIGHT_;

    // Reshape and page format. A complex vector has no integer form to keep, so keepOneLine is false.
    var colVector = false;
    var transposedVector = false;
    const verticalVector = reshapeVerticalVector(&matrix.header, prefixWidth, regXposition, false, &rows, &cols, &colVector, &transposedVector);
    const showPage = MX_SHOW_PAGE(prefixWidth, regXposition); // the SHOW page, never the stack line
    const fixPage = showPage and displayFormat == DF_FIX;

    sCol = boundScrollColumn(forEditor, sCol, @intCast(cols));

    var maxCols: c_int = if (cols > MATRIX_MAX_COLUMNS) MATRIX_MAX_COLUMNS else cols;
    const rowLimit: c_int = if (!regXposition and prefixWidth > 0) // VIEW / SHOW / stack
        (if (SHOWMODE()) MATRIX_MAX_ROWS_ON_SHOW else MATRIX_MAX_ROWS_ON_VIEW)
    else
        MATRIX_MAX_ROWS_ON_STACK;
    const maxRows: c_int = if (rows > rowLimit) rowLimit else rows;

    // The rolled out page: every element on its own line, one blank line between the rows of the matrix it came from
    const groupCols: usize = if (verticalVector and matrix.header.matrixRows >= 2 and matrix.header.matrixColumns >= 2) matrix.header.matrixColumns else 0;
    const totalLines: c_int = if (groupCols != 0) maxRows + @as(c_int, matrix.header.matrixRows) - 1 else maxRows;

    const matSelRow: i16 = if (colVector) getJRegisterAsInt(true) else getIRegisterAsInt(true);
    const matSelCol: i16 = if (colVector) getIRegisterAsInt(true) else getJRegisterAsInt(true);

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
    var sfPartWidth: i16 = 0;
    smallFont: while (true) {
        // The font choice. SHOW fits 5 numeric rows; padded SIG takes the small font.
        if (atSmallFontLabel or rows >= (if (showPage) @as(c_int, 6) else (if (forEditor) @as(c_int, 4) else @as(c_int, 5))) or
            (verticalVector and displayFormat == DF_SF and getSystemFlag(FLAG_SIGZEROS)))
        {
            font = &standardFont;
            fontHeight = STANDARD_FONT_HEIGHT_;
            Y_POS = Y_POSITION_OF_REGISTER_X_LINE - STANDARD_FONT_HEIGHT_ + 2;
        }
        // The vertical page layout: the same budget plus a figure space
        if (verticalVector) {
            maxWidth = showsVerticalVectorMaxWidth(&matrix.header, font, prefixWidth) + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
        }
        // The SIG part budget
        sfPartWidth = 0;
        if (verticalVector and displayFormat == DF_SF) {
            var unitStr: [64]u8 = @splat(0);
            if (polarMode) {
                _ = strcpy(&unitStr, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
            } else {
                _ = strcpy(&unitStr, "+");
                _ = strcat(&unitStr, complexUnit());
                _ = strcat(&unitStr, productSign());
            }
            sfPartWidth = @divTrunc(maxWidth - frontier_char_string.stringWidth(&unitStr, font, true, true) - frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) - 2, 2);
        }
        if (comptime option_mx_show) {
            if (totalLines > MATRIX_MAX_ROWS) {
                fontHeight = STANDARD_FONT_HEIGHT_ - 1; // 11 rows at 19 px fit the screen
            }
        }

        if (!forEditor) {
            Y_POS += REGISTER_LINE_HEIGHT;
        }
        const rightEllipsis = (cols > maxCols) and (cols > maxCols + @as(c_int, sCol));
        const leftEllipsis = (sCol > 0);

        if (!regXposition and prefixWidth > 0) {
            Y_POS = Y_POSITION_OF_REGISTER_T_LINE - REGISTER_LINE_HEIGHT + 1 + @as(i16, @intCast(totalLines)) * fontHeight;
        }
        if (!regXposition and prefixWidth > 0 and font == &standardFont) {
            Y_POS += (if (totalLines == 1) STANDARD_FONT_HEIGHT_ else REGISTER_LINE_HEIGHT - STANDARD_FONT_HEIGHT_);
        }

        // Measure the column widths
        var baseWidth: i16 = (if (leftEllipsis) frontier_char_string.stringWidth(STD_ELLIPSIS ++ " ", font, true, true) else 0) + (if (rightEllipsis) frontier_char_string.stringWidth(STD_ELLIPSIS, font, true, true) else 0);
        totalWidth = baseWidth + getComplexMatrixColumnWidths(matrix, prefixWidth, regXposition, font, &colWidth, &colWidth_r, &colWidth_i, &rPadWidth_r, &rPadWidth_i, &digits, @intCast(maxCols), angleMode, polarMode);
        // Shed digits: retry small font
        if (totalWidth > maxWidth or leftEllipsis or (showPage and font == &numericFont and digits < 34)) {
            if (font == &numericFont) {
                atSmallFontLabel = true;
                continue :smallFont;
            } else if (exponentLimit > 99) {
                exponentLimit = 99;
                atSmallFontLabel = true;
                continue :smallFont;
            } else {
                if (tmpDisplayFormat == DF_ALL or getSystemFlag(FLAG_M_ALL)) { // the user format is used unless ALL may be biased to make it fit
                    displayFormat = if (getSystemFlag(FLAG_ENGOVR)) DF_ENG else DF_SCI; // ENGOVR decides the exponent form everywhere
                    displayFormatDigits = 2;
                }
                clearSystemFlag(FLAG_MULTx);
                // the ellipsis takes its width off the budget
                totalWidth = baseWidth + getComplexMatrixColumnWidths(matrix, prefixWidth + baseWidth, regXposition, font, &colWidth, &colWidth_r, &colWidth_i, &rPadWidth_r, &rPadWidth_i, &digits, @intCast(maxCols), angleMode, polarMode);
                // the width call fits without the ellipsis the caller adds, so an unfloored shrink strips every column
                if (totalWidth > maxWidth and maxCols > 1) {
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
                baseWidth += colWidth[j] + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
            }
        }
        baseWidth -= frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);

        if (!regXposition and prefixWidth > 0) {
            X_POS = prefixWidth;
        } else if (!forEditor) {
            X_POS = SCREEN_WIDTH - ((if (colVector) frontier_char_string.stringWidth("[]" ++ STD_SUP_BOLD_T, font, true, true) else frontier_char_string.stringWidth("[]", font, true, true)) + baseWidth) - (if (font == &standardFont) @as(i16, 0) else @as(i16, 1));
        }

        if (forEditor) {
            frontier_screen.clearRegisterLine(REGISTER_X, true, true);
            frontier_screen.clearRegisterLine(REGISTER_Y, true, true);
            if (rows >= (if (font == &standardFont) @as(c_int, 3) else @as(c_int, 2))) {
                frontier_screen.clearRegisterLine(REGISTER_Z, true, true);
            }
            if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                frontier_screen.clearRegisterLine(REGISTER_T, true, true);
            }
        } else if (!regXposition and prefixWidth > 0) {
            frontier_screen.clearRegisterLine(REGISTER_T, true, true);
            if (rows >= 2) {
                frontier_screen.clearRegisterLine(REGISTER_Z, true, true);
            }
            if (rows >= (if (font == &standardFont) @as(c_int, 4) else @as(c_int, 3))) {
                frontier_screen.clearRegisterLine(REGISTER_Y, true, true);
            }
            if (rows == 4 and font != &standardFont) {
                frontier_screen.clearRegisterLine(REGISTER_X, true, true);
            }
        } else {
            // The stack position: a partial refresh leaves stale register text in
            // the band the matrix covers.
            lcdFillRect(screenPos(X_POS), screenPos(Y_POS - @as(i16, @intCast(totalLines - 1)) * fontHeight), @intCast((if (colVector) frontier_char_string.stringWidth("[]" ++ STD_SUP_BOLD_T, font, true, true) else frontier_char_string.stringWidth("[]", font, true, true)) + baseWidth), @intCast(if (font == &numericFont) @as(i16, @intCast(totalLines - 1)) * fontHeight + NUMERIC_FONT_HEIGHT else @as(i16, @intCast(totalLines - 1)) * fontHeight + STANDARD_FONT_HEIGHT), LCD_SET_VALUE);
        }

        // Draw the rows. The rolled out page labels each row after the first in the prefix column.
        const outerBracket: i16 = if (groupCols != 0) frontier_char_string.stringWidth("[", font, true, true) else 0;
        if (groupCols != 0) {
            var rowLabel = [4]u8{ 'r', '0', ':', 0 };
            var group: usize = 1;
            while (group < matrix.header.matrixRows) : (group += 1) {
                rowLabel[1] = @intCast('1' + group);
                _ = frontier_screen.showString(&rowLabel, &standardFont, 1, screenPos(Y_POS - @as(i16, @intCast(totalLines - 1 - @as(c_int, @intCast(group * (groupCols + 1))))) * fontHeight), 0, 1, 0);
            }
        }

        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            const lineFromBottom: c_int = if (groupCols != 0) (totalLines - 1 - @as(c_int, @intCast(i + i / groupCols))) else (maxRows - 1 - @as(c_int, @intCast(i)));
            var colX: i16 = frontier_char_string.stringWidth("[", font, true, true);
            _ = frontier_screen.showString(if (groupCols != 0) "[" else if (maxRows == 1) "[" else if (i == 0) STD_MAT_TL else if (i + 1 == maxRows) STD_MAT_BL else STD_MAT_ML, font, screenPos(X_POS + 1 + outerBracket), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
            if (groupCols != 0 and i == 0) { // the matrix bracket opens outside the row bracket of the first element
                _ = frontier_screen.showString("[", font, screenPos(X_POS + 1), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
            }
            if (leftEllipsis) {
                _ = frontier_screen.showString(STD_ELLIPSIS ++ " ", font, screenPos(X_POS + outerBracket + frontier_char_string.stringWidth("[", font, true, true)), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
                colX += frontier_char_string.stringWidth(STD_ELLIPSIS ++ " ", font, true, true);
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
                    real34ToReal(&elem.real, &x);
                    real34ToReal(&elem.imag, &y);
                    realRectangularToPolar(&x, &y, &x, &y, &ctxtReal39);
                    frontier_conversion_angles.convertAngleFromTo(&y, amRadian, angleMode, &ctxtReal39);
                    realToReal34(&x, &re);
                    realToReal34(&y, &im);
                } else {
                    real34Copy(&elem.real, &re);
                    real34Copy(&elem.imag, &im);
                }

                if (((@as(c_int, @intCast(i)) == maxRows - 1) and (rows > maxRows + @as(c_int, sRow))) or ((j == @as(usize, @intCast(maxCols))) and rightEllipsis) or ((i == 0) and (sRow > 0))) {
                    _ = strcpy(tmpString, STD_ELLIPSIS);
                    vm = 0;
                } else {
                    tmpString[0] = 0;
                    if (displayFormat == DF_SF and verticalVector) {
                        _ = sigFitReal34(&re, amNone, tmpString, font, sfPartWidth, FRONTSPACE); // same budget as measured
                    } else {
                        frontier_display.real34ToDisplayString(&re, amNone, tmpString, font, colWidth_r[j], if (displayFormat == DF_ALL) digits else (if (fixPage) @as(i16, 33) else (if (showPage) @as(i16, 34) else 15)), @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIMITIRFRAC);
                    }
                    if (forEditor and matSelRow == @as(i16, @intCast(i + sRow)) and matSelCol == @as(i16, @intCast(j + sCol))) {
                        lcdFillRect(screenPos(X_POS + outerBracket + colX), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), @intCast(colWidth[j]), if (font == &numericFont) 32 else 20, LCD_EMPTY_VALUE);
                        vm = 1;
                    } else {
                        vm = 0;
                    }
                }
                width = frontier_char_string.stringWidth(tmpString, font, true, true) + 1;
                _ = frontier_screen.showString(tmpString, font, screenPos(X_POS + outerBracket + colX + (if ((j == @as(usize, @intCast(maxCols))) and rightEllipsis) frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) - width else (colWidth_r[j] - width) - rPadWidth_r[i * MATRIX_MAX_COLUMNS + j])), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), vm, 1, 0);
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
                    cpxUnitWidth = frontier_char_string.stringWidth(tmpString, font, true, true);
                    width = cpxUnitWidth;
                    if (!polarMode) {
                        if (neg) {
                            tmpString[0] = '-';
                            real34SetPositiveSign(&im);
                        }
                    }
                    _ = frontier_screen.showString(tmpString, font, screenPos(X_POS + outerBracket + colX + colWidth_r[j] + (width - frontier_char_string.stringWidth(tmpString, font, true, true))), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), vm, 1, 0);

                    if (displayFormat == DF_SF and verticalVector) {
                        _ = sigFitReal34(&im, if (polarMode) @as(u8, @intCast(angleMode)) else amNone, tmpString, font, sfPartWidth, !FRONTSPACE);
                    } else {
                        frontier_display.real34ToDisplayString(&im, if (polarMode) @as(u32, @bitCast(@as(i32, angleMode))) else amNone, tmpString, font, colWidth_i[j], if (displayFormat == DF_ALL) digits else (if (fixPage) @as(i16, 33) else (if (showPage) @as(i16, 34) else 15)), @intFromBool(LIMITEXP), @intFromBool(!FRONTSPACE), LIMITIRFRAC);
                    }
                    width = frontier_char_string.stringWidth(tmpString, font, true, true) + 1;
                    _ = frontier_screen.showString(tmpString, font, screenPos(X_POS + outerBracket + colX + colWidth_r[j] + cpxUnitWidth + (if ((j == @as(usize, @intCast(maxCols - 1))) and rightEllipsis) @as(i16, 0) else (colWidth_i[j] - width) - rPadWidth_i[i * MATRIX_MAX_COLUMNS + j])), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), vm, 1, 0);
                }
                colX += colWidth[j] + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
            }
            _ = frontier_screen.showString(if (groupCols != 0) "]" else if (maxRows == 1) "]" else if (i == 0) STD_MAT_TR else if (i + 1 == maxRows) STD_MAT_BR else STD_MAT_MR, font, screenPos(X_POS + outerBracket + frontier_char_string.stringWidth("[", font, true, true) + baseWidth - 1), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
            if (groupCols != 0 and i + 1 == maxRows) { // the matrix bracket closes outside the row bracket of the last element
                _ = frontier_screen.showString("]", font, screenPos(X_POS + outerBracket + frontier_char_string.stringWidth("[]", font, true, true) + baseWidth - 1), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
            }
            if (colVector) {
                _ = frontier_screen.showString(STD_SUP_BOLD_T, font, screenPos(X_POS + frontier_char_string.stringWidth("[]", font, true, true) + baseWidth), screenPos(Y_POS - @as(i16, @intCast(lineFromBottom)) * fontHeight), 0, 1, 0);
            }
        }
        if (transposedVector) { // the ^T on the closing bracket
            _ = frontier_screen.showString(STD_SUP_BOLD_T, font, screenPos(X_POS + frontier_char_string.stringWidth("[", font, true, true) + frontier_char_string.stringWidth(STD_MAT_BR, font, true, true) + baseWidth - 1), screenPos(Y_POS), 0, 1, 0);
        }

        break :smallFont;
    }

    // Restore the format globals
    displayFormat = @intCast(tmpDisplayFormat);
    displayFormatDigits = tmpDisplayFormatDigits;
    exponentLimit = tmpExponentLimit;
    if (tmpMultX) {
        setSystemFlag(FLAG_MULTx);
    }
}

pub export fn getComplexMatrixColumnWidths(matrix: *const complex34Matrix_t, prefixWidth: i16, regXposition: bool_t, font: *const font_t, colWidthPtr: [*c]i16, colWidth_rPtr: [*c]i16, colWidth_iPtr: [*c]i16, rPadWidth_rPtr: [*c]i16, rPadWidth_iPtr: [*c]i16, digitsPtr: *i16, maxColsIn: u16, angleMode: angularMode_t, polarMode: bool_t) callconv(.c) i16 {
    // The measured page shape
    var tmpStringL: [200]u8 = @splat(0);
    const showPage = MX_SHOW_PAGE(prefixWidth, regXposition); // the SHOW page, never the stack line
    const fixPage = showPage and displayFormat == DF_FIX;
    // one shared column under SHOW; a complex vector has no integer form to keep
    const verticalVector = showsVerticalVector(&matrix.header, prefixWidth, regXposition, false);
    const colVector = !verticalVector and matrix.header.matrixColumns == 1 and matrix.header.matrixRows > 1;
    const rows: c_int = if (verticalVector) @as(c_int, matrix.header.matrixRows) * @as(c_int, matrix.header.matrixColumns) else if (colVector) 1 else matrix.header.matrixRows;
    const actualCols: c_int = if (verticalVector) 1 else if (colVector) matrix.header.matrixRows else matrix.header.matrixColumns;
    const cols: c_int = if (actualCols > @as(c_int, maxColsIn)) @as(c_int, maxColsIn) else actualCols;
    const rowLimit: c_int = if (showPage) MATRIX_MAX_ROWS_ON_SHOW else MATRIX_MAX_ROWS; // SHOW takes more rows
    const maxRows: c_int = if (rows > rowLimit) rowLimit else rows;
    const forEditor = matrix == &openMatrixMIMPointer.complexMatrix;
    const sRow: u16 = if (forEditor) scrollRow else 0;
    const sCol: u16 = if (forEditor) scrollColumn else 0;
    // The width budget, widened by one figure space on the vertical page
    const maxWidth: i16 = if (verticalVector) showsVerticalVectorMaxWidth(&matrix.header, font, prefixWidth) + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) else MATRIX_LINE_WIDTH_C - prefixWidth;
    var totalWidth: i16 = 0;
    var maxRightWidth_r: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var maxLeftWidth_r: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var maxRightWidth_i: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    var maxLeftWidth_i: [MATRIX_MAX_COLUMNS]i16 = @splat(0);
    const exponentOutOfRange: i16 = 0x4000;
    var sfShed = false; // a part shed digits
    const maxCols: usize = maxColsIn;

    // The complex unit width
    var cpxUnitWidth: i16 = 0;
    if (polarMode) {
        _ = strcpy(&tmpStringL, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
    } else {
        _ = strcpy(&tmpStringL, "+");
        _ = strcat(&tmpStringL, complexUnit());
        _ = strcat(&tmpStringL, productSign());
    }
    cpxUnitWidth = frontier_char_string.stringWidth(&tmpStringL, font, true, true);
    // half the line per part
    const sfPartWidth: i16 = @divTrunc(maxWidth - cpxUnitWidth - frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) - 2, 2);

    // The SHOW starting count
    var startDigitCountDown: c_int = if (showPage) 34 // start at full precision
        else imax(imin(@as(c_int, displayFormatDigits) * (if (displayFormat == DF_ALL) @as(c_int, 2) else @as(c_int, 1)), imax(@divTrunc(@as(c_int, 50), cols) - 2, 0)), 10);
    if (showPage and displayFormat == DF_SF) {
        startDigitCountDown = 33; // SIG n shows n+1 digits
    } else if (showPage and displayFormat == DF_FIX) { // cap FIX at 34 total digits
        var maxE: i16 = 0;
        var i: usize = 0;
        while (i < maxRows) : (i += 1) {
            var j: usize = 0;
            while (j < maxCols) : (j += 1) {
                const c34 = &matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol];
                const eRe: i16 = if (real34IsZero(&c34.real)) 0 else real34GetExponent(&c34.real) + real34Digits(&c34.real) - 1;
                const eIm: i16 = if (real34IsZero(&c34.imag)) 0 else real34GetExponent(&c34.imag) + real34Digits(&c34.imag) - 1;
                // plain-renderable parts only; e33 up takes the sci form through the 33 window
                if (eRe > maxE and eRe <= 32) {
                    maxE = eRe;
                }
                if (eIm > maxE and eIm <= 32) {
                    maxE = eIm;
                }
            }
        }
        startDigitCountDown = imax(imin(33 - @as(c_int, maxE), 99), 1);
    }
    var k: c_int = startDigitCountDown;
    while (k >= 1) : (k -= 1) {
        if (displayFormat == DF_ALL) {
            digitsPtr.* = @intCast(k);
        } else if (showPage) { // the shared maximised count
            displayFormatDigits = if (displayFormat == DF_SF and verticalVector) 34 else @intCast(k);
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
                    real34ToReal(&c34Val.real, &x);
                    real34ToReal(&c34Val.imag, &y);
                    realRectangularToPolar(&x, &y, &x, &y, &ctxtReal39);
                    frontier_conversion_angles.convertAngleFromTo(&y, amRadian, angleMode, &ctxtReal39);
                    realToReal34(&x, &c34Val.real);
                    realToReal34(&y, &c34Val.imag);
                }

                rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j] = 0;
                real34SetPositiveSign(&c34Val.real);
                var c34sign = real34IsNegative(&matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol].real);
                // Measure the real part
                if (displayFormat == DF_SF and verticalVector) {
                    if (sigFitReal34(&c34Val.real, amNone, &tmpStringL, font, sfPartWidth, FRONTSPACE)) { // per-part SIG self-fit
                        sfShed = true;
                    }
                } else {
                    // no internal shrink under SHOW: it hides shed digits and flips SIG to sci; the k countdown does the fitting
                    frontier_display.real34ToDisplayString(&c34Val.real, amNone, &tmpStringL, font, if (showPage) UNSHRUNK_WIDTH else maxWidth, if (displayFormat == DF_ALL) @as(i16, @intCast(k)) else (if (fixPage) @as(i16, 33) else (if (showPage) @as(i16, 34) else 15)), @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIMITIRFRAC);
                }
                var width: i16 = frontier_char_string.stringWidth(&tmpStringL, font, true, true) + 1;
                // vector SIG skips the line-up
                if ((strstr(&tmpStringL, ".") != null or strstr(&tmpStringL, ",") != null) and !(verticalVector and displayFormat == DF_SF)) {
                    var xStr: [*c]u8 = &tmpStringL;
                    while (xStr.* != 0) : (xStr += 1) {
                        const isEngLike = (displayFormat == DF_ENG or (displayFormat == DF_ALL and getSystemFlag(FLAG_ENGOVR)));
                        const cond1 = (displayFormat != DF_ENG and (displayFormat != DF_ALL or !getSystemFlag(FLAG_ENGOVR))) and (xStr.* == '.' or xStr.* == ',');
                        const cond2 = isEngLike and xStr[0] == 0x80 and (xStr[1] == 0x87 or xStr[1] == 0xd7);
                        if (cond1 or cond2) {
                            rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j] = frontier_char_string.stringWidth(xStr, font, true, true) + 1;
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
                    if (c34sign and (strstr(&tmpStringL, "/") != null or strstr(&tmpStringL, STD_ALMOST_EQUAL) != null)) {
                        width += frontier_char_string.stringWidth("-", font, true, true);
                    }
                    rPadWidth_rPtr[i * MATRIX_MAX_COLUMNS + j] = width | exponentOutOfRange;
                }

                rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j] = 0;
                c34sign = false;
                if (!polarMode) {
                    // The sign the imaginary column budgets a '-' for is the
                    // element's REAL part, the same one the real column tested:
                    // the width rule keys both halves off the leading sign.
                    c34sign = real34IsNegative(&matrix.matrixElements.?[(i + sRow) * @as(usize, @intCast(actualCols)) + j + sCol].real);
                    real34SetPositiveSign(&c34Val.imag);
                }
                // Measure the imaginary part
                if (displayFormat == DF_SF and verticalVector) {
                    if (sigFitReal34(&c34Val.imag, if (polarMode) @as(u8, @intCast(angleMode)) else amNone, &tmpStringL, font, sfPartWidth, !FRONTSPACE)) {
                        sfShed = true;
                    }
                } else {
                    // no internal shrink under SHOW: it hides shed digits and flips SIG to sci; the k countdown does the fitting
                    frontier_display.real34ToDisplayString(&c34Val.imag, if (polarMode) @as(u32, @bitCast(@as(i32, angleMode))) else amNone, &tmpStringL, font, if (showPage) UNSHRUNK_WIDTH else maxWidth, if (displayFormat == DF_ALL) @as(i16, @intCast(k)) else (if (fixPage) @as(i16, 33) else (if (showPage) @as(i16, 34) else 15)), @intFromBool(LIMITEXP), @intFromBool(!FRONTSPACE), LIMITIRFRAC);
                }
                width = frontier_char_string.stringWidth(&tmpStringL, font, true, true) + 1;
                // vector SIG skips the line-up
                if ((strstr(&tmpStringL, ".") != null or strstr(&tmpStringL, ",") != null) and !(verticalVector and displayFormat == DF_SF)) {
                    var xStr: [*c]u8 = &tmpStringL;
                    while (xStr.* != 0) : (xStr += 1) {
                        const isEngLike = (displayFormat == DF_ENG or (displayFormat == DF_ALL and getSystemFlag(FLAG_ENGOVR)));
                        const cond1 = (displayFormat != DF_ENG and (displayFormat != DF_ALL or !getSystemFlag(FLAG_ENGOVR))) and (xStr.* == '.' or xStr.* == ',');
                        const cond2 = isEngLike and xStr[0] == 0x80 and (xStr[1] == 0x87 or xStr[1] == 0xd7);
                        if (cond1 or cond2) {
                            rPadWidth_iPtr[i * MATRIX_MAX_COLUMNS + j] = frontier_char_string.stringWidth(xStr, font, true, true) + 1;
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
                        width += frontier_char_string.stringWidth("-", font, true, true);
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
                totalWidth += colWidthPtr[j] + frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true) * 2;
            }
        }
        totalWidth -= frontier_char_string.stringWidth(STD_SPACE_FIGURE, font, true, true);
        if (displayFormat != DF_ALL and !showPage) {
            break;
        } else if (totalWidth <= maxWidth) {
            // nothing shed: the font retry rests
            digitsPtr.* = if (showPage and k == startDigitCountDown and !sfShed) 34 else @intCast(k);
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
// z47_frontier_matrix_* BRIDGE HELPERS.
// Signatures must match the siblings' `extern fn` declarations exactly.
// ===========================================================================

pub fn z47_frontier_matrix_get_register_as_int(regist: u16, as_array_pointer: bool) i16 {
    return getRegisterAsInt(as_array_pointer, @bitCast(regist));
}

pub fn z47_frontier_matrix_set_register_as_int(regist: u16, as_array_pointer: bool, to_store: i16) void {
    setRegisterAsInt(as_array_pointer, to_store, @bitCast(regist));
}

pub fn z47_frontier_matrix_is_register_matrix_vector(regist: u16) bool {
    return isRegisterMatrixVector(@bitCast(regist));
}

pub fn z47_frontier_matrix_vector_polar_mode(regist: u16) u16 {
    return getVectorRegisterPolarMode(@bitCast(regist));
}

pub fn z47_frontier_matrix_open_rows() u16 {
    return openMatrixMIMPointer.header.matrixRows;
}

pub fn z47_frontier_matrix_open_cols() u16 {
    return openMatrixMIMPointer.header.matrixColumns;
}

pub fn z47_frontier_matrix_commit_open_to_register() void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        frontier_register_value_conversions.convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, @bitCast(matrixIndex));
    } else {
        frontier_register_value_conversions.convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, @bitCast(matrixIndex));
    }
}

pub fn z47_frontier_matrix_calc_mode_normal_gui() void {
    calcModeNormalGui();
}

pub fn z47_frontier_matrix_hide_cursor() void {
    frontier_screen.hideCursor();
    cursorEnabled = 0;
}

pub fn z47_frontier_matrix_reload_open_matrix_from_register() void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        if (openMatrixMIMPointer.realMatrix.matrixElements != null) {
            realMatrixFree(&openMatrixMIMPointer.realMatrix);
        }
        frontier_register_value_conversions.convertReal34MatrixRegisterToReal34Matrix(@bitCast(matrixIndex), &openMatrixMIMPointer.realMatrix);
    } else {
        if (openMatrixMIMPointer.complexMatrix.matrixElements != null) {
            complexMatrixFree(&openMatrixMIMPointer.complexMatrix);
        }
        frontier_register_value_conversions.convertComplex34MatrixRegisterToComplex34Matrix(@bitCast(matrixIndex), &openMatrixMIMPointer.complexMatrix);
    }
}

// callByIndexedMatrix dispatch (matrixEditor.c static). The inc/dec real/complex
// helpers are file-local.
fn incIReal(matrix: *real34Matrix_t) callconv(.c) bool {
    setIRegisterAsInt(true, getIRegisterAsInt(true) + 1);
    _ = wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns);
    return false;
}
fn decIReal(matrix: *real34Matrix_t) callconv(.c) bool {
    setIRegisterAsInt(true, getIRegisterAsInt(true) - 1);
    _ = wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns);
    return false;
}
fn incJReal(matrix: *real34Matrix_t) callconv(.c) bool {
    setJRegisterAsInt(true, getJRegisterAsInt(true) + 1);
    if (wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns)) {
        insRowRealMatrix(matrix, matrix.header.matrixRows, addFlag); // addFlag: append at the true end (rows is swapped to 1 for colVector)
        return true;
    }
    return false;
}
fn decJReal(matrix: *real34Matrix_t) callconv(.c) bool {
    setJRegisterAsInt(true, getJRegisterAsInt(true) - 1);
    _ = wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns);
    return false;
}
fn incJComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    setJRegisterAsInt(true, getJRegisterAsInt(true) + 1);
    if (wrapIJImpl(matrix.header.matrixRows, matrix.header.matrixColumns)) {
        insRowComplexMatrix(matrix, matrix.header.matrixRows, addFlag); // addFlag: append at the true end (rows is swapped to 1 for colVector)
        return true;
    }
    return false;
}

// The matrix.c callByIndexedMatrix, not a local stand-in: it reads the INDEXED
// REGISTER into a matrix of its own, refuses an out-of-range cursor, and writes the
// result back when the callback reports a change. Walking openMatrixMIMPointer here
// instead would only work with the editor open, and I+/J+/STOSEQ/RCLSEQ run outside it.
extern fn callByIndexedMatrix(real_f: ?*const fn (*real34Matrix_t) callconv(.c) bool, complex_f: ?*const fn (*complex34Matrix_t) callconv(.c) bool) void;
fn incIComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    return incIReal(@ptrCast(matrix));
}
fn decIComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    return decIReal(@ptrCast(matrix));
}
fn decJComplex(matrix: *complex34Matrix_t) callconv(.c) bool {
    return decJReal(@ptrCast(matrix));
}

pub fn z47_frontier_matrix_inc_dec_i(mode: u16) void {
    callByIndexedMatrix(if (mode == DEC_FLAG) decIReal else incIReal, if (mode == DEC_FLAG) decIComplex else incIComplex);
}

pub fn z47_frontier_matrix_inc_dec_j(mode: u16) void {
    callByIndexedMatrix(if (mode == DEC_FLAG) decJReal else incJReal, if (mode == DEC_FLAG) decJComplex else incJComplex);
}

pub fn z47_frontier_matrix_insert_row(add: bool) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        insRowRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getIRegisterAsInt(true)), add);
    } else {
        insRowComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getIRegisterAsInt(true)), add);
    }
}

pub fn z47_frontier_matrix_insert_col(add: bool) void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        insColRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getJRegisterAsInt(true)), add);
    } else {
        insColComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getJRegisterAsInt(true)), add);
    }
}

pub fn z47_frontier_matrix_delete_row() void {
    if (openMatrixMIMPointer.header.matrixRows > 1) {
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            delRowRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getIRegisterAsInt(true)));
        } else {
            delRowComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getIRegisterAsInt(true)));
        }
    }
}

pub fn z47_frontier_matrix_delete_col() void {
    if (openMatrixMIMPointer.header.matrixColumns > 1) {
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            delColRealMatrix(&openMatrixMIMPointer.realMatrix, @bitCast(getJRegisterAsInt(true)));
        } else {
            delColComplexMatrix(&openMatrixMIMPointer.complexMatrix, @bitCast(getJRegisterAsInt(true)));
        }
    }
}

pub fn z47_frontier_matrix_finalize_open_matrix_memory() void {
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

pub fn z47_frontier_matrix_aim_is_empty() bool {
    return aimBuffer[0] == 0;
}

pub fn z47_frontier_matrix_reset_cursor_pos() void {
    resetCursorPos();
}

pub fn z47_frontier_matrix_init_aim_exponent() void {
    aimBuffer[0] = '+';
    aimBuffer[1] = '1';
    aimBuffer[2] = '.';
    aimBuffer[3] = 0;
    nimNumberPart = NP_REAL_FLOAT_PART;
    resetCursorPos();
}

pub fn z47_frontier_matrix_init_aim_period() void {
    aimBuffer[0] = '+';
    aimBuffer[1] = '0';
    aimBuffer[2] = 0;
    nimNumberPart = NP_INT_10;
    resetCursorPos();
}

pub fn z47_frontier_matrix_init_aim_digit() void {
    aimBuffer[0] = '+';
    aimBuffer[1] = 0;
    nimNumberPart = NP_INT_10;
    resetCursorPos();
}

pub fn z47_frontier_matrix_aim_is_single_plus_digit() bool {
    return (aimBuffer[0] == '+') and (aimBuffer[1] != 0) and (aimBuffer[2] == 0);
}

pub fn z47_frontier_matrix_aim_clear_single_plus_digit() void {
    aimBuffer[1] = 0;
    frontier_screen.hideCursor();
    cursorEnabled = 0;
}

pub fn z47_frontier_matrix_zero_current_element() void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getIRegisterAsInt(true);
    const col: i16 = getJRegisterAsInt(true);
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        real34SetZero(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    } else {
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].real);
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].imag);
    }
    setSystemFlag(FLAG_ASLIFT);
}

pub fn z47_frontier_matrix_change_sign_current_element() void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getIRegisterAsInt(true);
    const col: i16 = getJRegisterAsInt(true);
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        real34ChangeSign(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    } else {
        real34ChangeSign(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].real);
        real34ChangeSign(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].imag);
    }
    setSystemFlag(FLAG_ASLIFT);
}

/// The j / CC arm of mimAddNumber with an empty number-entry buffer: promote the
/// open matrix to complex (or set the current element to the imaginary unit) and
/// trace the keystroke, which `item` identifies.
pub fn z47_frontier_matrix_make_j_element(item: i16) void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getIRegisterAsInt(true);
    const col: i16 = getJRegisterAsInt(true);

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        var cxma: complex34Matrix_t = undefined;
        frontier_register_value_conversions.convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
        realMatrixFree(&openMatrixMIMPointer.realMatrix);
        frontier_register_value_conversions.convertComplex34MatrixToComplex34MatrixRegister(&cxma, @bitCast(matrixIndex));
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
            frontier_conversion_angles.convertAngleFromTo(&theta, amRadian, currentAngularMode, &ctxtReal39);
            real34SetOne(&elm.real);
            // realToReal34, where the C reaches for real34Copy. That macro copies
            // sixteen raw bytes, and theta is a real_t -- a decNumber whose first
            // sixteen bytes are its digit count, exponent and flags, not a
            // decimal128 -- so the C stores the struct header into the imaginary
            // part and the new element's angle is whatever those fields encode.
            // A deliberate divergence: converting is what the surrounding code
            // means, and reproducing the copy would write a value no reader of
            // this matrix can interpret.
            realToReal34(&theta, &elm.imag);
        } else {
            real34SetZero(&elm.real);
            real34SetOne(&elm.imag);
        }
    }
    frontier_print.printTrace(lastFunc, @bitCast(item));
}

pub fn z47_frontier_matrix_set_current_to_pi() void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getIRegisterAsInt(true);
    const col: i16 = getJRegisterAsInt(true);
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        realToReal34(const39_pi, &openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    } else {
        realToReal34(const39_pi, &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].real);
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].imag);
    }
}

pub fn z47_frontier_matrix_can_append_pi_literal() bool {
    return nimNumberPart == NP_COMPLEX_INT_PART and aimBuffer[strlen(aimBuffer) - 1] == 'i';
}

pub fn z47_frontier_matrix_append_pi_literal_and_enter() void {
    _ = strcat(aimBuffer, "3.141592653589793238462643383279503");
    frontier_items.reallyRunFunction(ITM_ENTER, NOPARAM);
}

pub fn z47_frontier_matrix_add_item_to_nim_buffer(item: i16) void {
    frontier_bufferize.addItemToNimBuffer(item);
}

var saved_is_complex: bool_t = false;
var saved_re: real34_t = undefined;
var saved_im: real34_t = undefined;
// The cell the run started on. mimRunFunction reads the cursor once, before the
// function it dispatches gets a chance to move it, and every later read and write
// of the run addresses that same cell.
var saved_i: i16 = 0;
var saved_j: i16 = 0;

pub fn z47_frontier_matrix_open_is_complex() bool {
    return getRegisterDataType(@bitCast(matrixIndex)) == dtComplex34Matrix;
}

pub fn z47_frontier_matrix_capture_selected_before() void {
    saved_i = getIRegisterAsInt(true);
    saved_j = getJRegisterAsInt(true);
    const i: i16 = saved_i;
    const j: i16 = saved_j;
    saved_is_complex = z47_frontier_matrix_open_is_complex();
    const idx: usize = @intCast(@as(c_int, i) * @as(c_int, openMatrixMIMPointer.header.matrixColumns) + @as(c_int, j));

    if (saved_is_complex) {
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].real, &saved_re);
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].imag, &saved_im);
    } else {
        real34Copy(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx], &saved_re);
        real34SetZero(&saved_im);
    }
}

// mimEnter promotes a real matrix to complex when the pending entry is complex,
// so the type is asked again afterwards: from here on the element reads, the
// dyadic Y staging and the write-back all address the promoted layout.
pub fn z47_frontier_matrix_recheck_open_is_complex() void {
    saved_is_complex = z47_frontier_matrix_open_is_complex();
}

pub fn z47_frontier_matrix_load_selected_into_register_x() void {
    const i: i16 = saved_i;
    const j: i16 = saved_j;
    var re: real34_t = undefined;
    var im: real34_t = undefined;
    const isComplex = saved_is_complex;
    const idx: usize = @intCast(@as(c_int, i) * @as(c_int, openMatrixMIMPointer.header.matrixColumns) + @as(c_int, j));

    if (isComplex) {
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].real, &re);
        real34Copy(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].imag, &im);
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        real34Copy(&re, &regCplx(REGISTER_X).real);
        real34Copy(&im, regImag34(REGISTER_X));
    } else {
        real34Copy(&openMatrixMIMPointer.realMatrix.matrixElements.?[idx], &re);
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        real34Copy(&re, reg34(REGISTER_X));
    }
}

pub fn z47_frontier_matrix_run_item_function(func: i16, param: u16) void {
    frontier_items.reallyRunFunction(func, param);
}

// A dyadic function needs the matrix element the editor started from in Y, so it
// is staged there from the value captured before mimEnter.
pub fn z47_frontier_matrix_stage_dyadic_operand_in_y() void {
    if (saved_is_complex) {
        reallocateRegister(REGISTER_Y, dtComplex34, 0, amNone);
        real34Copy(&saved_re, &regCplx(REGISTER_Y).real);
        real34Copy(&saved_im, regImag34(REGISTER_Y));
    } else {
        reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
        real34Copy(&saved_re, reg34(REGISTER_Y));
    }
}

// The editor leaves the stack as it was, so Y upwards comes back from the undo
// buffer the run saved before the operation.
pub fn z47_frontier_matrix_restore_stack_above_x() void {
    var regist: calcRegister_t = getStackTop();
    while (regist >= REGISTER_Y) : (regist -= 1) {
        copySourceRegisterToDestRegister(SAVED_REGISTER_X - REGISTER_X + regist, regist);
    }
}

pub fn z47_frontier_matrix_register_type(reg: u16) u32 {
    return getRegisterDataType(@bitCast(reg));
}

pub fn z47_frontier_matrix_convert_register_x_long_to_real34() void {
    frontier_register_value_conversions.convertLongIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
}

pub fn z47_frontier_matrix_convert_register_x_short_to_real34() void {
    frontier_register_value_conversions.convertShortIntegerRegisterToReal34Register(REGISTER_X, REGISTER_X);
}

pub fn z47_frontier_matrix_apply_register_x_to_selected() bool {
    const i: i16 = saved_i;
    const j: i16 = saved_j;
    // Same capture the read used, so both halves address the matrix the editor
    // was opened on.
    const isComplex = saved_is_complex;
    const idx: usize = @intCast(@as(c_int, i) * @as(c_int, openMatrixMIMPointer.header.matrixColumns) + @as(c_int, j));

    if (isComplex and getRegisterDataType(REGISTER_X) == dtComplex34) {
        complex34Copy(regCplx(REGISTER_X), &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx]);
        return false;
    }

    if (isComplex) {
        real34Copy(reg34(REGISTER_X), &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].real);
        real34SetZero(&openMatrixMIMPointer.complexMatrix.matrixElements.?[idx].imag);
        return false;
    }

    if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        var cxma: complex34Matrix_t = undefined;
        var ans: complex34_t = undefined;

        complex34Copy(regCplx(REGISTER_X), &ans);
        frontier_register_value_conversions.convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
        realMatrixFree(&openMatrixMIMPointer.realMatrix);
        frontier_register_value_conversions.convertComplex34MatrixToComplex34MatrixRegister(&cxma, @bitCast(matrixIndex));
        openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
        openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
        openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;

        complex34Copy(&ans, &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx]);
        return true;
    }

    real34Copy(reg34(REGISTER_X), &openMatrixMIMPointer.realMatrix.matrixElements.?[idx]);
    return false;
}

pub fn z47_frontier_matrix_restore_saved_selected_if_x_and_not_converted() void {
    if (matrixIndex != @as(u16, @bitCast(REGISTER_X))) {
        return;
    }

    const i: i16 = saved_i;
    const j: i16 = saved_j;

    if (saved_is_complex) {
        var linkedMatrix: complex34Matrix_t = undefined;
        frontier_register_value_conversions.convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, REGISTER_X);
        linkToComplexMatrixRegister(REGISTER_X, &linkedMatrix);
        const idx: usize = @intCast(@as(c_int, i) * @as(c_int, linkedMatrix.header.matrixColumns) + @as(c_int, j));
        real34Copy(&saved_re, &linkedMatrix.matrixElements.?[idx].real);
        real34Copy(&saved_im, &linkedMatrix.matrixElements.?[idx].imag);
    } else {
        var linkedMatrix: real34Matrix_t = undefined;
        frontier_register_value_conversions.convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, REGISTER_X);
        linkToRealMatrixRegister(REGISTER_X, &linkedMatrix);
        const idx: usize = @intCast(@as(c_int, i) * @as(c_int, linkedMatrix.header.matrixColumns) + @as(c_int, j));
        real34Copy(&saved_re, &linkedMatrix.matrixElements.?[idx]);
    }
}

pub fn z47_frontier_matrix_update_height_cache() void {
    frontier_screen.updateMatrixHeightCache();
}

pub fn z47_frontier_matrix_softmenu_has_m_edit() bool {
    var i: usize = 0;
    while (i < SOFTMENU_STACK_SIZE) : (i += 1) {
        if (softmenu[@intCast(softmenuStack[i].softmenuId)].menuItem == -MNU_M_EDIT) {
            return true;
        }
    }
    return false;
}

pub fn z47_frontier_matrix_softmenu_top_is_m_edit() bool {
    return softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem == -MNU_M_EDIT;
}

pub fn z47_frontier_matrix_show_m_edit_softmenu() void {
    frontier_softmenus.showSoftmenu(-MNU_M_EDIT);
}

pub fn z47_frontier_matrix_scroll_row_get() u16 {
    return scrollRow;
}

pub fn z47_frontier_matrix_scroll_row_set(row: u16) void {
    scrollRow = row;
}

pub fn z47_frontier_matrix_render_editor_body(colVector: bool, rows: i16, cols: i16, matSelRow: i16, matSelCol: i16) void {
    _ = rows;
    var width: i16 = 0;

    if (aimBuffer[0] == 0) {
        frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, true, true);
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            showRealMatrix(&openMatrixMIMPointer.realMatrix, 0, !regXp, null);
        } else {
            showComplexMatrix(&openMatrixMIMPointer.complexMatrix, 0, currentAngularMode, getSystemFlag(FLAG_POLAR), !regXp);
        }
    } else {
        frontier_screen.clearRegisterLine(NIM_REGISTER_LINE, false, true);
    }

    const hairArg: [*c]const u8 = if (aimBuffer[0] == 0) STD_SPACE_HAIR else "";
    const spaceArg: [*c]const u8 = if (aimBuffer[0] == 0 or aimBuffer[0] == '-') "" else " ";
    abi.fmtBufZ(tmpString[0..2560], "{d};{d}=" ++ STD_SPACE_4_PER_EM ++ "{s}{s}{s}", .{ @as(i32, if (colVector) matSelCol + 1 else matSelRow + 1), @as(i32, if (colVector) 1 else matSelCol + 1), std.mem.span(hairArg), std.mem.span(spaceArg), std.mem.span(nimBufferDisplay) });
    width = frontier_char_string.stringWidth(tmpString, &numericFont, true, true) + 1;
    if (aimBuffer[0] == 0) {
        const selIdx: usize = @intCast(@as(c_int, matSelRow) * @as(c_int, cols) + @as(c_int, matSelCol));
        if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
            frontier_display.real34ToDisplayString(&openMatrixMIMPointer.realMatrix.matrixElements.?[selIdx], amNone, tmpString + strlen(tmpString), &numericFont, SCREEN_WIDTH - width, NUMBER_OF_DISPLAY_DIGITS, @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIGHTIRFRAC);
        } else {
            frontier_display.complex34ToDisplayString(&openMatrixMIMPointer.complexMatrix.matrixElements.?[selIdx], tmpString + strlen(tmpString), &numericFont, SCREEN_WIDTH - width, NUMBER_OF_DISPLAY_DIGITS, @intFromBool(LIMITEXP), @intFromBool(FRONTSPACE), LIMITIRFRAC, @as(u16, @bitCast(@as(i16, @truncate(currentAngularMode)))), @intFromBool(getSystemFlag(FLAG_POLAR)));
        }

        _ = frontier_screen.showString(tmpString, &numericFont, 0, Y_POSITION_OF_NIM_LINE, 0, 1, 0);
    } else {
        if (aimBuffer[0] != 0 and aimBuffer[strlen(aimBuffer) - 1] == '/') {
            var lastBase: [12]u8 = @splat(0);
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
            frontier_screen.displayNim(tmpString, &lastBase, frontier_char_string.stringWidth(&lastBase, &numericFont, true, true), frontier_char_string.stringWidth(&lastBase, &standardFont, true, true));
        } else {
            frontier_screen.displayNim(tmpString, "", 0, 0);
        }
    }

    if (temporaryInformation == TI_SHOW_REGISTER and calcMode == CM_MIM) {
        frontier_display.mimShowElement();
        frontier_screen.clearRegisterLine(REGISTER_T, true, true);
        frontier_screen.refreshRegisterLine(REGISTER_T);
        if (tmpString[SHOWLineSize] != 0) {
            frontier_screen.clearRegisterLine(REGISTER_Z, true, true);
            frontier_screen.refreshRegisterLine(REGISTER_Z);
        }
    }

    if (lastErrorCode != ERROR_NONE) {
        frontier_screen.refreshRegisterLine(errorMessageRegisterLine);
    }
}

pub fn z47_frontier_matrix_mim_enter_apply_aim_buffer() void {
    const cols: c_int = openMatrixMIMPointer.header.matrixColumns;
    const row: i16 = getIRegisterAsInt(true);
    const col: i16 = getJRegisterAsInt(true);
    var realChanged: bool_t = false;
    const idx: usize = @intCast(@as(c_int, row) * cols + @as(c_int, col));

    if (aimBuffer[0] == 0) {
        return;
    }

    // The value being closed goes to the printer before it is applied. The
    // leading '+' the number-entry buffer carries is a sign placeholder, not
    // part of the typed number, so a positive entry is traced without it.
    if (aimBuffer[0] == '+') {
        frontier_print.printTraceString(aimBuffer + 1, LINE_NOLF);
    } else {
        frontier_print.printTraceString(aimBuffer, LINE_NOLF);
    }

    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        var real34tmp: real34_t = undefined;
        const real34Ptr = &openMatrixMIMPointer.realMatrix.matrixElements.?[idx];

        switch (nimNumberPart) {
            NP_FRACTION_DENOMINATOR, NP_HP32SII_DENOMINATOR => {
                frontier_bufferize.closeNimWithFraction(&real34tmp);
                realChanged = true;
            },
            NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_FRACTION_DENOMINATOR, NP_COMPLEX_HP32SII_DENOMINATOR => {
                var cxma: complex34Matrix_t = undefined;
                frontier_register_value_conversions.convertReal34MatrixToComplex34Matrix(&openMatrixMIMPointer.realMatrix, &cxma);
                realMatrixFree(&openMatrixMIMPointer.realMatrix);
                frontier_register_value_conversions.convertComplex34MatrixToComplex34MatrixRegister(&cxma, @bitCast(matrixIndex));
                openMatrixMIMPointer.complexMatrix.header.matrixRows = cxma.header.matrixRows;
                openMatrixMIMPointer.complexMatrix.header.matrixColumns = cxma.header.matrixColumns;
                openMatrixMIMPointer.complexMatrix.matrixElements = cxma.matrixElements;
                const complex34Ptr = &openMatrixMIMPointer.complexMatrix.matrixElements.?[idx];
                frontier_bufferize.closeNimWithComplex(&complex34Ptr.real, &complex34Ptr.imag);
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
                frontier_bufferize.closeNimWithFraction(&complex34Ptr.real);
                real34SetZero(&complex34Ptr.imag);
            },
            NP_COMPLEX_INT_PART, NP_COMPLEX_FLOAT_PART, NP_COMPLEX_EXPONENT, NP_COMPLEX_FRACTION_DENOMINATOR, NP_COMPLEX_HP32SII_DENOMINATOR => {
                frontier_bufferize.closeNimWithComplex(&complex34Ptr.real, &complex34Ptr.imag);
            },
            else => {
                stringToReal34(aimBuffer, &complex34Ptr.real);
                real34SetZero(&complex34Ptr.imag);
            },
        }
    }

    aimBuffer[0] = 0;
    nimBufferDisplay[0] = 0;
    frontier_screen.hideCursor();
    cursorEnabled = 0;
    setSystemFlag(FLAG_ASLIFT);
}

pub fn z47_frontier_matrix_mim_enter_commit_open_matrix() void {
    if (getRegisterDataType(@bitCast(matrixIndex)) == dtReal34Matrix) {
        frontier_register_value_conversions.convertReal34MatrixToReal34MatrixRegister(&openMatrixMIMPointer.realMatrix, @bitCast(matrixIndex));
        setRegisterTag(@bitCast(matrixIndex), openMatrixMIMPointer.header.mtag);
    } else {
        frontier_register_value_conversions.convertComplex34MatrixToComplex34MatrixRegister(&openMatrixMIMPointer.complexMatrix, @bitCast(matrixIndex));
        setRegisterTag(@bitCast(matrixIndex), openMatrixMIMPointer.header.mtag);
    }
}

// ===========================================================================
// wrapIJ — file-local copy used by the inc/dec helpers above. The PUBLIC wrapIJ
// is exported by shell.zig (matrix_nav module); this private impl mirrors it
// so callByIndexedMatrix stays self-contained without taking a dependency on the
// sibling's internal name.
// ===========================================================================
fn wrapIJImpl(rows: u16, cols: u16) bool_t {
    const r = matrix_wrap.wrapIJ(
        getIRegisterAsInt(true),
        getJRegisterAsInt(true),
        rows,
        cols,
        getSystemFlag(FLAG_GROW),
    );
    setIRegisterAsInt(true, r.i);
    setJRegisterAsInt(true, r.j);
    if (r.wrap_edge) setSystemFlag(FLAG_WRAPEDG) else clearSystemFlag(FLAG_WRAPEDG);
    if (r.wrap_end) setSystemFlag(FLAG_WRAPEND) else clearSystemFlag(FLAG_WRAPEND);
    return r.at_rows;
}

comptime {
    // Force-reference the lifecycle/dead global so it is not stripped and so
    // matrixEditor.c's symbol set is preserved exactly.
    _ = &tmpRow;
}

// The shadow row/column pair: the Matrix Editor's cursor while it is open, and the
// vector functions' walking index while they cross a matrix. The user's I and J keep
// their value and their type. While the shadow is closed the accessors address the
// real registers; while it is open (editor mode, or a vector function's walk) they
// address the shadow, so the user's I/J are never clobbered. shadowI/J persist to
// backup.cfg beside matrixIndex, so the editor reopens on the cell it was left on.
pub export var shadowI: i16 = 0; // 0-based, i.e. what asArrayPointer=true reports
pub export var shadowJ: i16 = 0;
var ijShadowActive: bool = false; // for the vector functions; the editor is spotted by its calcMode

fn ijIsShadowed() bool {
    return calcMode == CM_MIM or ijShadowActive;
}

/// Which matrix was indexed, and the shadow row/column under it. Opaque: filled by
/// saveMatrixIndexState and put back by restoreMatrixIndexState.
pub const MatrixIndexState = extern struct {
    matrixIndex: u16,
    savedI: i16,
    savedJ: i16,
};

pub export fn saveMatrixIndexState(state: *MatrixIndexState) callconv(.c) void {
    state.matrixIndex = matrixIndex;
    state.savedI = shadowI;
    state.savedJ = shadowJ;
    ijShadowActive = true; // from here the walking index goes to the shadow; the user's I and J are not touched
}

pub export fn restoreMatrixIndexState(state: *const MatrixIndexState) callconv(.c) void {
    ijShadowActive = false;
    shadowI = state.savedI; // an editor open underneath keeps the cursor it had
    shadowJ = state.savedJ;
    matrixIndex = state.matrixIndex;
}

// The I and J register accessors. Upstream defines them here (ui/matrixEditor.c:364),
// and they are the matrix editor's own row/column cursor: they belong with the
// state they read, not in the module root. A root force-imports; it does not export.
pub export fn getIRegisterAsInt(as_array_pointer: bool) callconv(.c) i16 {
    if (ijIsShadowed()) return if (as_array_pointer) shadowI else shadowI + 1;
    return z47_frontier_matrix_get_register_as_int(REGISTER_I, as_array_pointer);
}

pub export fn getJRegisterAsInt(as_array_pointer: bool) callconv(.c) i16 {
    if (ijIsShadowed()) return if (as_array_pointer) shadowJ else shadowJ + 1;
    return z47_frontier_matrix_get_register_as_int(REGISTER_J, as_array_pointer);
}

pub export fn setIRegisterAsInt(as_array_pointer: bool, to_store: i16) callconv(.c) void {
    if (ijIsShadowed()) {
        shadowI = if (as_array_pointer) to_store else to_store - 1;
        return;
    }
    z47_frontier_matrix_set_register_as_int(REGISTER_I, as_array_pointer, to_store);
}

pub export fn setJRegisterAsInt(as_array_pointer: bool, to_store: i16) callconv(.c) void {
    if (ijIsShadowed()) {
        shadowJ = if (as_array_pointer) to_store else to_store - 1;
        return;
    }
    z47_frontier_matrix_set_register_as_int(REGISTER_J, as_array_pointer, to_store);
}

// The matrix-editor mode guard. It answers a question about THIS editor's own
// state, so it lives with that state rather than in the module root.
pub fn matrixInEditorMode() bool {
    return calcMode == CM_MIM;
}

pub fn matrixEnsureEditorMode(where: [*:0]const u8) bool {
    if (matrixInEditorMode()) {
        return true;
    }
    matrixModeUndefinedError(where);
    return false;
}

/// The refusal every matrix-editor entry point makes outside CM_MIM. The console
/// hint names the function that refused, so the caller supplies its
/// "In function <name>:" prefix.
pub fn matrixModeUndefinedError(where: [*:0]const u8) void {
    frontier_error.displayCalcErrorMessage(ERROR_OPERATION_UNDEFINED, ERR_REGISTER_LINE);
    if (comptime extra_info) {
        abi.fmtBufZ(errorMessage[0..ERROR_MESSAGE_LENGTH], "works in MIM only", .{});
        frontier_error.moreInfoOnErrorImpl(where, errorMessage, null, null);
    }
}

// No editor-mode guard, as fnIncDecI: J+ and J- walk the INDEXED matrix.
pub export fn fnIncDecJ(mode: u16) callconv(.c) void {
    matrix_nav.incDec(.col, mode);
}

// Neither mimAddNumber nor mimRunFunction tests calcMode: both start straight
// into the work. Every call site already sits inside a CM_MIM branch, so a mode
// guard here would only add a refusal, and an error code, that c47 never raises.
pub export fn mimAddNumber(item: i16) callconv(.c) void {
    matrix_mim_add.run(item);
}

pub export fn mimRunFunction(func: i16, param: u16) callconv(.c) void {
    matrix_mim_run.run(func, param);
}
