const std = @import("std");
// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/display.c: the number/value -> display-string formatter
// and the SHOW renderer. Faithful, line-by-line port of every public function:
// the fnDisplayFormat* setters, exponent/sup/sub number formatting,
// real34/complex34/angle34 -> display string (FIX/SCI/ENG/ALL/SIG/UN modes with
// IRFRAC fraction substitution and digit grouping), fraction / short-integer /
// long-integer / date / time / matrix / vector -> display string, the
// _numerator/_denominator/strPrepend helpers, realToSci, mimShowElement, fnC47Show
// (the multi-font SHOW page builder), and _view/fnView/fnAview/fnPrompt.
//
// Notes on the build matrix (defines.h):
//   * SAVE_SPACE_DM42_9 is #undef'd for every z47 build target (sim, dmcp pkg4,
//     dmcp5): it is only set for the legacy single-file no-QSPI old_hw build.
//     So the big `#if !defined(SAVE_SPACE_DM42_9)` block (RegName, SHOW_reset,
//     printXSHOW, dispM and the full fnC47Show body) is LIVE on every target and
//     is ported unconditionally; the SAVE_SPACE fallback `fnView(REGISTER_X)`
//     is dead and omitted.
//   * IR_PRINTING gates printViewAview / printInputPrompt (print.c). It is ON for
//     host (sim/test) and DMCP5, OFF for every old_hw DMCP package. The frontier
//     object is built once per (target, options); ir_printing is a build option
//     wired per package, and the calls are guarded `if (comptime ir_printing)`.
//     When off those symbols do not exist, so they must not be referenced.
//   * OPTION_VECTOR gates the 2D/3D-vector special-case in
//     real34MatrixToDisplayString. ON for host and DMCP5, OFF for DMCP pkg 1/2/4.
//     Gated `if (comptime option_vector)`; the vector helpers/STD glyphs are only
//     referenced under that guard.
//   * EXTRA_INFO_ON_CALC_ERROR: the moreInfoOnError console hints are 1 on host,
//     0 on DMCP/testSuite; gated on the extra_info build option like the siblings.
//   * REAL34_WIDTH_TEST==0, PC_BUILD_TELLTALE undef, VERBOSE_SCREEN/MONITOR_*
//     undef, DEBUGUNDO undef, SIG_VARIABLE_JUMP undef: those branches are dead and
//     omitted (the #else / non-defined arm is ported).
//
// Decimal infrastructure mirrors the sibling bufferize owner exactly: const_* /
// const34_* / const39_* are NOT symbols -- they are constantPointers.h macros over
// the shared `constants` blob, bound by byte offset; real34*/real* operations are
// decQuad*/decNumber*/byte-sign inline wrappers; longInteger_t is mpz via __gmpz_*.
// The grouping / SEPARATOR_* / RADIX34_MARK_STRING / Rx / COMPLEX_UNIT /
// PRODUCT_SIGN runtime macros are reproduced inline.
//
// font tables (standardFont/numericFont/tinyFont) are real extern const structs,
// taken by &name. No DMCP ROM screen calls live in display.c (the lcd_*/showString
// drawing is delegated to screen.c externs), so there are no ROM trampolines or
// limb-size (OS32/OS64) splits in this file. display.c is reached by the testSuite
// (number formatting), so byte-exactness is verified by `zig build test`.

const frontier_build_options = @import("frontier_build_options");
const dmcp_build: bool = frontier_build_options.dmcp_build;
const extra_info: bool = frontier_build_options.extra_info_on_calc_error;
const ir_printing: bool = frontier_build_options.ir_printing;
const option_vector: bool = frontier_build_options.option_vector;

// ---------------------------------------------------------------------------
// Types (matching the C build's layout, mirrored from sibling owners)
// ---------------------------------------------------------------------------
const bool_t = u8;
const calcRegister_t = i16;
const angularMode_t = c_int;

const DECNUMUNITS = 25;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const real34_t = abi.Real34;
const complex34_t = abi.Complex34;
const realContext_t = abi.RealContext;

const font_t = opaque {};

const item_t = abi.Item;

// matrixHeader_t is a bitfield struct {rows:12; cols:12; mtag:6; notUsed:2}.
// Access via the two 12-bit fields packed into a u32; reproduce with explicit
// shifts so the layout is unambiguous.
const matrixHeader_t = abi.MatrixHeader;
const real34Matrix_t = abi.Real34Matrix;
const complex34Matrix_t = abi.Complex34Matrix;

// mpz / longInteger
const mp_limb_t = usize;
const mpz_struct = abi.Mpz;
const longInteger_t = [1]mpz_struct;

// ---------------------------------------------------------------------------
// Numeric constants (defines.h / typeDefinitions.h / *.h)
// ---------------------------------------------------------------------------
const DSP_MAX: u16 = 19;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;
const DF_SF: u8 = 4;
const DF_UN: u8 = 5;

const CM_NORMAL: u8 = 0;
const CM_NIM: u8 = 2;
const CM_PEM: u8 = 3;

const CF_OFF: u8 = 0;
const CF_NORMAL: u8 = 1;

const amRadian: angularMode_t = 0;
const amGrad: angularMode_t = 1;
const amDegree: angularMode_t = 2;
const amDMS: angularMode_t = 3;
const amMultPi: angularMode_t = 4;
const amNone: angularMode_t = 5;
const amSecond: angularMode_t = 6;
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;
const amPolarCYL: u32 = 64;
const amPolarSPH: u32 = 128;

const NOIRFRAC: c_int = 0;
const LIMITIRFRAC: c_int = 1;
const LIGHTIRFRAC: c_int = 2;
const FULLIRFRAC: c_int = 3;
const irfracOption_t = c_int;

const LIMITEXP: bool_t = 1;
const FRONTSPACE: bool_t = 1;

const NUMBER_OF_DISPLAY_DIGITS: c_int = 20;

const TMP_STR_LENGTH: usize = 2560;
const WRITE_BUFFER_LEN: i32 = 4096;
const ERROR_MESSAGE_LENGTH: usize = 512;
const DISPLAY_VALUE_LEN: usize = 80;
const SCREEN_WIDTH: i16 = 400;
const SHOWLineSize: i16 = 120;
const SHOWLineMax: u8 = @intCast(TMP_STR_LENGTH / @as(usize, @intCast(SHOWLineSize))); // 21

const REGISTER_X: calcRegister_t = 100;
const REGISTER_T: calcRegister_t = 103;
const REGISTER_Z: calcRegister_t = 102;
const FIRST_GLOBAL_REGISTER: calcRegister_t = 0;
const LAST_SPARE_REGISTER: calcRegister_t = 125;
const FIRST_NAMED_VARIABLE: calcRegister_t = 256;

const Y_POSITION_OF_REGISTER_T_LINE: i16 = 24;
const Y_POSITION_OF_ERR_LINE: i16 = 60; // Y_POSITION_OF_REGISTER_Z_LINE
const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;
const dtConfig: u32 = 9;

const NOPARAM: u16 = 9876;
const ITM_VIEW: u16 = 101;
const ITM_NOP: u16 = 1542;
const ITM_RS: u16 = 1725;
const ITM_UP1: u16 = 1733;
const ITM_DOWN1: u16 = 1735;
const ITM_AVIEW: u16 = 2018;
const ITM_PROMPT: u16 = 2020;
const MNU_SHOW: i16 = 2315;
const MNU_XXFCNS: i16 = 2596;

const clrStatusBar: bool_t = 1;
const clrRegisterLines: bool_t = 1;
const clrSoftkeys: bool_t = 1;
const stdnumEnlarge: c_int = 2;
const nocompress: c_int = 0;
const regXp: bool_t = 1;
const toDisplayVectorMatrix: bool_t = 1;

const TI_NO_INFO: u8 = 0;
const TI_SHOW_REGISTER: u8 = 14;
const TI_VIEW_REGISTER: u8 = 15;
const TI_INACCURATE: u8 = 48;
const TI_SHOW_REGISTER_BIG: u8 = 75;
const TI_SHOW_REGISTER_SMALL: u8 = 76;
const TI_SHOW_REGISTER_TINY: u8 = 77;
const TI_SHOWNOTHING: u8 = 93;

const PGM_RUNNING: u8 = 1;
const SCRUPD_MANUAL_STATUSBAR: u8 = 0x01;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;

const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const bugMsgValueFor: usize = 0;

const SIM_UNSIGN: u8 = 0;
const SIM_1COMPL: u8 = 1;
const SIM_2COMPL: u8 = 2;
const SIM_SIGNMT: u8 = 3;

const BCD9c: u8 = 219;
const BCD10c: u8 = 220;

const noBaseOverride: u8 = 0;

// DEC rounding modes (decContext.h enum: CEILING=0, UP=1, HALF_UP=2,
// HALF_EVEN=3, HALF_DOWN=4, DOWN=5, FLOOR=6).
const DEC_ROUND_HALF_UP: c_int = 2;
const DEC_ROUND_DOWN: c_int = 5;

// System flags (defines.h hex codes).
const FLAG_SIGZEROS: c_int = 0x806a;
const FLAG_TDM24: c_int = 0x8000;
const FLAG_DMY: c_int = 0xc002;
const FLAG_MDY: c_int = 0xc003;
const FLAG_CPXj: c_int = 0x8005;
const FLAG_FRACT: c_int = 0x8007;
const FLAG_PROPFR: c_int = 0x8008;
const FLAG_LEAD0: c_int = 0x800d;
const FLAG_MULTx: c_int = 0x801b;
const FLAG_ENGOVR: c_int = 0x801c;
const FLAG_FRCSRN: c_int = 0x802a;
const FLAG_2TO10: c_int = 0x803D;
const FLAG_CPXMULT: c_int = 0x8044;
const FLAG_LARGELI: c_int = 0x8046;
const FLAG_IRFRAC: c_int = 0x8047;
const FLAG_PFX_ALL: c_int = 0x8049;
const FLAG_USB: c_int = 0xc028;

// ---------------------------------------------------------------------------
// STD_* byte sequences (fonts.h)
// ---------------------------------------------------------------------------
const PRODUCT_SIGN_unused = {}; // PRODUCT_SIGN is a runtime macro (see productSign)
const STD_SUB_10 = "\xa4\x7d";
const STD_SUP_0 = "\xa1\x60";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_SUP_1 = "\xa1\x61";
const STD_SUP_2 = "\xa1\x62";
const STD_SPACE_HAIR = "\xa0\x0a";
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_MINUS = "\xa0\x8b";
const STD_LEFT_SINGLE_QUOTE = "\xa0\x18";
const STD_RIGHT_SINGLE_QUOTE = "\xa0\x19";
const STD_INFINITY = "\xa2\x1e";
const STD_ALMOST_EQUAL = "\xa2\x48";
const STD_SPACE_4_PER_EM = "\xa0\x05";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_SPACE_FIGURE = "\xa0\x07";
const STD_SPACE_6_PER_EM = "\xa0\x06";
const STD_SPACE_3_PER_EM = "\xa0\x04";
const STD_MEASURED_ANGLE = "\xa2\x21";
const STD_SUP_pir = "\xac\x66";
const STD_SUP_BOLD_r = "\x82\xb3";
const STD_SUP_BOLD_g = "\x9d\x4d";
const STD_DEGREE = "\x80\xb0";
const STD_RIGHT_DOUBLE_QUOTE = "\xa0\x1d";
const STD_SQUARE_ROOT = "\xa2\x1a";
const STD_SUB_2 = "\xa0\x82";
const STD_SUB_3 = "\xa0\x83";
const STD_SUB_5 = "\xa0\x85";
const STD_SUB_7 = "\xa0\x87";
const STD_pi = "\x83\xc0";
const STD_EulerE = "\xa1\x47";
const STD_phi_m = "\x83\xd5";
const STD_NOCHAR: u8 = 1;
const STD_SUB_b = "\xa4\x9d";
const STD_SUB_c = "\xa4\x9e";
const STD_SUB_d = "\xa4\x9f";
const STD_SUB_o = "\xa4\xaa";
const STD_SUB_f = "\xa4\xa1";
const STD_BASE_2 = "\xa4\x61";
const STD_BASE_1 = "\xa4\x60";
const STD_BASE_9 = "\xa4\x68";
const STD_SUB_A = "\xa4\xd0";
const STD_INTEGER_Z_SMALL = "\xa1\x25";
const STD_ELLIPSIS = "\xa0\x26";
const STD_BINARY_ZERO = "\xa2\x0e";
const STD_BINARY_ONE = "\xa0\x27";
const NUM_0_b = "\xa4\x73";
const STD_CROSS = "\x80\xd7";
const STD_DOT = "\x80\xb7";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";
const STD_SUP_p = "\xa4\x91";
const STD_SUP_s = "\xa4\x94";
const STD_SUP_c = "\xa4\x84";

// Composite IRFRAC labels (from real34ToDisplayString2; OPT1 variants).
const oneOverPi = "(" ++ STD_pi ++ STD_SUP_MINUS ++ STD_SUP_1 ++ STD_SPACE_HAIR ++ ")";
const oneOverE = "(" ++ STD_EulerE ++ STD_SUP_MINUS ++ STD_SUP_1 ++ STD_SPACE_HAIR ++ ")";

// ---------------------------------------------------------------------------
// const_* / const34_* / const39_* : constantPointers.h macros over `constants`.
// ---------------------------------------------------------------------------
const constR = abi.constants.cstRAligned;
const constR34 = abi.constants.cst34;
const const_1 = constR(4856);
const const_1000 = constR(5380);
const const_1024 = constR(5392);
const const_60 = constR(5296);
const const_3600 = constR(5448);
const const_86400 = constR(5524);
const const_100 = constR(7532);
const const_24 = constR(5168);
const const_12 = constR(5144);
const const39_ln2 = constR(4628);
const const39_root2 = constR(4664);
const const39_pi = constR(1848);
const const39_eE = constR(176);
const const39_PHI = constR(1596);
const const39_rt3 = constR(5720);
const const39_rt5 = constR(5756);
const const39_rt7 = constR(5792);
const const39_rtpi = constR(5852);
const const39_1onpi = constR(5888);
const const39_1oneE = constR(4388);
const const39_pisq = constR(5924);
const const39_eEsq = constR(5960);
const const39_1onpisq = constR(5996);
const const39_1oneEsq = constR(6032);
const const_plusInfinity = constR(1696);
const const_minusInfinity = constR(1684);
const const_1e_24 = constR(4472);
const const34_1e_24 = constR34(16248);
const const34_2p32 = constR34(16888);

// ---------------------------------------------------------------------------
// font tables: real extern const structs (taken by &name).
// ---------------------------------------------------------------------------
extern const standardFont: font_t;
extern const numericFont: font_t;
extern const tinyFont: font_t;

// indexOfItems is a C array -> bind by address.
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
// commonBugScreenMessages[N][SIZE]; bind by address (each row is a char[100]).
const commonBugScreenMessages = @extern([*c]const [100]u8, .{ .name = "commonBugScreenMessages" });

// ---------------------------------------------------------------------------
// Extern globals (defined in the c47 globals hub / other owners).
// ---------------------------------------------------------------------------
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var displayValueX: [DISPLAY_VALUE_LEN]u8;
extern var updateDisplayValueX: bool_t;
extern var calcMode: u8;
extern var IrFractionsCurrentStatus: u8;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var dispBase: u8;
const baseDigits = @extern([*c]const u8, .{ .name = "baseDigits" });
extern var fontForShortInteger: ?*const font_t;
extern var shortIntegerMode: u8;
extern var shortIntegerWordSize: u8;
extern var shortIntegerMask: u64;
extern var shortIntegerSignBit: u64;
extern var bcdDisplaySign: u8;
extern var ctxtReal34: realContext_t;
extern var ctxtReal39: realContext_t;
extern var ctxtReal75: realContext_t;
extern var currentAngularMode: angularMode_t;
extern var temporaryInformation: u8;
extern var showRegis: u16;
extern var overrideShowBottomLine: u8;
extern var currentViewRegister: u16;
extern var programRunStop: u8;
extern var screenUpdatingMode: u8;
extern var systemFlags0: u64;
extern var systemFlags1: u64;
extern var numberOfNamedVariables: u16;
extern var significantDigits: u8;
extern var displayStack: u8;
extern var Input_Default: u8;
extern var DM_Cycling: u8;
extern var lastErrorCode: u8;
extern var matrixIndex: u16;
extern var errorMessageRegisterLine: calcRegister_t;
// openMatrixMIMPointer is an any34Matrix_t union; we only touch header + element
// pointer of real34Matrix_t / complex34Matrix_t views. Bind to the bigger of the
// two layouts via a union-like extern.
const any34Matrix_t = abi.Any34Matrix;
extern var openMatrixMIMPointer: any34Matrix_t;
// grouping globals
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingRight: u8;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;

// ---------------------------------------------------------------------------
// Function externs (cross-owner / runtime / libc / decNumber / GMP).
// ---------------------------------------------------------------------------
extern fn getSystemFlag(sf: c_int) bool_t;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn fnRefreshState() void;
extern fn getRegisterDataType(regist: calcRegister_t) u32;
extern fn getRegisterDataPointer(regist: calcRegister_t) [*c]u8;
extern fn getRegisterTag(regist: calcRegister_t) u32;
extern fn setRegisterTag(regist: calcRegister_t, tag: u32) void;
extern fn getRegisterDataTypeName(regist: calcRegister_t, article: bool_t, padWithBlanks: bool_t) [*c]const u8;
extern fn regInRange(r: u16) bool_t;
extern fn currentMenu() i16;
extern fn checkForAndChange(displayString: [*c]u8, value: *real_t, valueAbs: *real_t, cnst: *const real_t, tolerance: *const real_t, name: [*c]const u8, frontSpace: bool_t, complex: bool_t) bool_t;
extern fn displayBugScreen(msg: [*c]const u8) void;
extern fn fnPause(duration: u16) void;
extern fn fnStopProgram(p: u16) void;
extern fn fraction(regist: calcRegister_t, sign: *i16, intPart: *u64, numer: *u64, denom: *u64, lessEqualGreater: *i16) bool_t;
extern fn internalDateToJulianDay(d: *const real34_t, j: *real34_t) void;
extern fn decomposeJulianDay(jd: *const real34_t, year: *real34_t, month: *real34_t, day: *real34_t) void;
extern fn getIRegisterAsInt(asArrayPointer: bool_t) i16;
extern fn getJRegisterAsInt(asArrayPointer: bool_t) i16;
extern fn viewRegName2(prefix: [*c]u8, prefixWidth: *i16) void;
extern fn registerFMAOutputString(regist: calcRegister_t, prefix: [*c]const u8, displayString: [*c]u8) bool_t;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, matrix: *real34Matrix_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, matrix: *complex34Matrix_t) void;
extern fn showRealMatrix(matrix: *const real34Matrix_t, prefixWidth: i16, toDisplay: bool_t, regXposition: bool_t) void;
extern fn showComplexMatrix(matrix: *const complex34Matrix_t, prefixWidth: i16, am: angularMode_t, polarMode: bool_t, regXposition: bool_t) void;
extern fn refreshRegisterLine(line: calcRegister_t) void;
extern fn refreshScreen(source: u16) void;
extern fn clearScreenOld(a: bool_t, b: bool_t, c: bool_t) void;
extern fn drawSinglePixelFullWidthLine(y: c_int) void;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: c_int, showLeadingCols: bool_t, showEndingCols: bool_t) u32;
extern fn showSoftmenu(id: i16) void;
extern fn displayCalcErrorMessage(errorCode: u8, errMessageRegisterLine: calcRegister_t, errRegisterLine: calcRegister_t) void;
extern fn moreInfoOnError(m1: [*c]const u8, m2: [*c]const u8, m3: [*c]const u8, m4: [*c]const u8) void;

// IR_PRINTING-only print helpers (only referenced when ir_printing is on).
const printViewAview = if (ir_printing) @extern(*const fn (func: u16, regist: u16) callconv(.c) void, .{ .name = "printViewAview" }) else {};
const printInputPrompt = if (ir_printing) @extern(*const fn (func: u16, regist: u16) callconv(.c) void, .{ .name = "printInputPrompt" }) else {};

// string / glyph helpers
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn stringWidth(str: [*c]const u8, font: *const font_t, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) i16;
extern fn stringWidthC47(str: [*c]const u8, mode: c_int, comp: c_int, withLeadingEmptyRows: bool_t, withEndingEmptyRows: bool_t) u32;
extern fn stringGlyphLength(str: [*c]const u8) i32;
extern fn stringLastGlyph(str: [*c]const u8) i16;
extern fn stringNextGlyph(str: [*c]const u8, pos: i16) i16;
extern fn stringPrevNumberGlyph(str: [*c]const u8, pos: i16) i16;
extern fn stringAfterPixels(str: [*c]const u8, font: *const font_t, width: i16, a: bool_t, b: bool_t) [*c]u8;
extern fn stringAfterPixelsC47(str: [*c]const u8, mode: c_int, comp: c_int, width: u32, a: bool_t, b: bool_t) [*c]u8;

// libc
extern fn strlen(s: [*c]const u8) usize;
extern fn strcat(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strchr(s: [*c]const u8, c: c_int) [*c]u8;
extern fn strstr(h: [*c]const u8, n: [*c]const u8) [*c]u8;
extern fn strncmp(a: [*c]const u8, b: [*c]const u8, n: usize) c_int;
extern fn strcmp(a: [*c]const u8, b: [*c]const u8) c_int;
extern fn memset(s: ?*anyopaque, c: c_int, n: usize) ?*anyopaque;
extern fn memmove(d: ?*anyopaque, s: ?*const anyopaque, n: usize) ?*anyopaque;
extern fn sprintf(buf: [*c]u8, fmt: [*c]const u8, ...) c_int;

// real34 / real arithmetic = decQuad/decNumber (libdecnumber).
extern fn decimal128ToNumber(d: *const real34_t, dn: *real_t) *real_t;
extern fn decimal128FromNumber(d: *real34_t, dn: *const real_t, set: *realContext_t) *real34_t;
extern fn decQuadCopy(r: *align(1) real34_t, a: *align(1) const real34_t) *align(1) real34_t;
extern fn decQuadDigits(d: *align(1) const real34_t) u32;
extern fn decQuadGetExponent(d: *align(1) const real34_t) i32;
extern fn decQuadGetCoefficient(d: *align(1) const real34_t, bcd: [*c]u8) i32;
extern fn decQuadZero(r: *align(1) real34_t) *align(1) real34_t;
extern fn decQuadReduce(r: *align(1) real34_t, a: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadIsZero(d: *align(1) const real34_t) u32;
extern fn decQuadIsInfinite(d: *align(1) const real34_t) u32;
extern fn decQuadIsNaN(d: *align(1) const real34_t) u32;
extern fn decQuadToString(d: *align(1) const real34_t, str: [*c]u8) [*c]u8;
extern fn decQuadFromString(r: *align(1) real34_t, str: [*c]const u8, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadRemainder(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadDivide(r: *align(1) real34_t, a: *align(1) const real34_t, b: *align(1) const real34_t, ctx: *realContext_t) *align(1) real34_t;
extern fn decQuadToIntegralValue(r: *align(1) real34_t, a: *align(1) const real34_t, ctx: *realContext_t, round: c_int) *align(1) real34_t;
extern fn decQuadToUInt32(d: *align(1) const real34_t, ctx: *realContext_t, round: c_int) u32;

// real (decNumber) helpers used by display.c
extern fn realToInt32C47(r: *const real_t, err: ?*bool_t) i32;
extern fn realToUint32C47(r: *const real_t, err: ?*bool_t) u32;
extern fn real34IsAnInteger(x: *const real34_t) bool_t;
extern fn real34CompareAbsLessThan(a: *const real34_t, b: *const real34_t) bool_t;
extern fn real34CompareEqual(a: *const real34_t, b: *const real34_t) bool_t;
extern fn real34FromDegToDms(a: *const real34_t, res: *real34_t) void;
extern fn realCompareAbsLessThan(a: *const real_t, b: *const real_t) bool_t;
extern fn realCompareLessThan(a: *const real_t, b: *const real_t) bool_t;
extern fn realCompareGreaterEqual(a: *const real_t, b: *const real_t) bool_t;
extern fn realCompareLessEqual(a: *const real_t, b: *const real_t) bool_t;
extern fn realToIntegralValue(a: *const real_t, res: *real_t, round: c_int, ctx: *realContext_t) void;
extern fn roundToSignificantDigits(a: *const real_t, res: *real_t, digits: u16, ctx: *realContext_t) void;
extern fn WP34S_Ln(x: *const real_t, res: *real_t, ctx: *realContext_t) void;
extern fn convertAngleFromTo(a: *real_t, from: angularMode_t, to: angularMode_t, ctx: *realContext_t) void;
extern fn convertAngle34FromTo(a: *real34_t, from: angularMode_t, to: angularMode_t) void;
extern fn convertRealToLongInteger(a: *const real_t, lgInt: *mpz_struct, round: c_int) void;
// real* operations are decNumber* macros (note the arg-order swap: result first).
extern fn decNumberFromString(r: *real_t, str: [*c]const u8, ctx: *realContext_t) *real_t;
extern fn decNumberToString(r: *const real_t, str: [*c]u8) [*c]u8;
extern fn decNumberCopy(dst: *real_t, src: *const real_t) *real_t;
extern fn decNumberDivide(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberPower(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberPlus(res: *real_t, a: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberRemainder(res: *real_t, a: *const real_t, b: *const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberFromInt32(r: *real_t, v: i32) *real_t;
extern fn decNumberGetBCD(dn: *const real_t, bcd: [*c]u8) [*c]u8;
// real symbols (true functions, not macros).
extern fn realSetOne(r: *real_t) void;
extern fn realSetZero(r: *real_t) void;
extern fn realRectangularToPolar(real: *const real_t, imag: *const real_t, magnitude: *real_t, theta: *real_t, ctx: *realContext_t) void;
// inline wrappers matching the realType.h macro call shapes.
inline fn stringToReal(str: [*c]const u8, r: *real_t, ctx: *realContext_t) void {
    _ = decNumberFromString(r, str, ctx);
}
inline fn realToString(r: *const real_t, str: [*c]u8) void {
    _ = decNumberToString(r, str);
}
inline fn realDivide(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberDivide(res, a, b, ctx);
}
inline fn realMultiply(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberMultiply(res, a, b, ctx);
}
inline fn realPower(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberPower(res, a, b, ctx);
}
inline fn realAdd(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberAdd(res, a, b, ctx);
}
inline fn realSubtract(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberSubtract(res, a, b, ctx);
}
inline fn realPlus(a: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberPlus(res, a, ctx);
}
inline fn realDivideRemainder(a: *const real_t, b: *const real_t, res: *real_t, ctx: *realContext_t) void {
    _ = decNumberRemainder(res, a, b, ctx);
}
inline fn int32ToReal(v: i32, r: *real_t) void {
    _ = decNumberFromInt32(r, v);
}

// GMP (real symbols are __gmpz_*).
extern fn __gmpz_init(op: [*c]mpz_struct) void;
extern fn __gmpz_init2(op: [*c]mpz_struct, n: c_ulong) void;
extern fn __gmpz_clear(op: [*c]mpz_struct) void;
extern fn __gmpz_add_ui(rop: [*c]mpz_struct, op1: [*c]const mpz_struct, op2: c_ulong) void;
extern fn __gmpz_tdiv_q_ui(q: [*c]mpz_struct, n: [*c]const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_tdiv_ui(n: [*c]const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_fdiv_ui(n: [*c]const mpz_struct, d: c_ulong) c_ulong;
extern fn __gmpz_sizeinbase(op: [*c]const mpz_struct, base: c_int) usize;
extern fn convertLongIntegerRegisterToLongInteger(regist: calcRegister_t, lgInt: [*c]mpz_struct) void;
// longIntegerToDisplayString / longIntegerToAllocatedString are DEFINED below
// (pub export); they are public functions of display.c.

// ---------------------------------------------------------------------------
// Owned file-static globals (display.c defines these; other C units reference
// `startingLine`/`source` via the FBR / show machinery).
// ---------------------------------------------------------------------------
pub export var startingLine: i16 = 0;
pub export var IntShowMode: i16 = 0;
pub export var source: i16 = 0;

const SHOWAUTO: i16 = 0;
const SHOWSML: i16 = 1;
const SHOWTNY: i16 = 2;

// ---------------------------------------------------------------------------
// min / max / modulo (C macros).
// ---------------------------------------------------------------------------
inline fn minI(a: i32, b: i32) i32 {
    return if (a < b) a else b;
}
inline fn maxI(a: i32, b: i32) i32 {
    return if (a > b) a else b;
}
// modulo(n,d) for d>0 : ((n%d)<0 ? n%d+d : n%d)
inline fn modulo(n: i32, d: i32) i32 {
    const r = @rem(n, d);
    return if (r < 0) r + d else r;
}
inline fn absI(a: i32) i32 {
    return if (a < 0) -a else a;
}

// ---------------------------------------------------------------------------
// runtime macros over globals
// ---------------------------------------------------------------------------
const ID_DP: u8 = 2;
inline fn checkHP() bool {
    return significantDigits <= 16 and displayStack == 1 and exponentLimit == 99 and Input_Default == ID_DP and (calcMode == CM_NORMAL or calcMode == CM_NIM);
}
inline fn runningOnSimOrUSB() bool {
    if (comptime dmcp_build) {
        return getSystemFlag(FLAG_USB) != 0;
    } else {
        return true;
    }
}
inline fn showmode() bool {
    return calcMode == CM_NORMAL and (temporaryInformation == TI_SHOW_REGISTER or temporaryInformation == TI_SHOW_REGISTER_BIG or temporaryInformation == TI_SHOW_REGISTER_SMALL or temporaryInformation == TI_SHOW_REGISTER_TINY or temporaryInformation == TI_SHOWNOTHING);
}
// NUMBER_OF_DISPLAY_REAL_CONTEXT_DIGITS
inline fn nbrDispRealCtxDigits() c_int {
    return if (displayFormat == DF_ALL or getSystemFlag(FLAG_2TO10) != 0) NUMBER_OF_DISPLAY_DIGITS + 1 else @as(c_int, displayFormatDigits) + 2;
}

inline fn productSign() [*c]const u8 {
    return if (getSystemFlag(FLAG_MULTx) != 0) STD_CROSS else STD_DOT;
}
inline fn complexUnit() [*c]const u8 {
    return if (getSystemFlag(FLAG_CPXj) != 0) STD_op_j else STD_op_i;
}

// ---------------------------------------------------------------------------
// SEPARATOR_* / RADIX34_MARK_STRING / Rx runtime macros.
//
// Rt/Lt/Rx return a char* into indexOfItems[item].itemSoftmenuName (or the
// synthesized "\1\1\0" when item==0). gapChar1Left/Right/Radix then map a bare
// punctuation byte to a fixed single-byte-separator literal. The display.c code
// uses the result both as a 2-byte index (sep[0], sep[1]) and as a char* passed
// to strcpy / xcopy / stringWidth, so reproduce the actual pointer.
// ---------------------------------------------------------------------------
const lit_comma1 = ",\x01\x00";
const lit_dot1 = ".\x01\x00";
const lit_quote1 = "'\x01\x00";
const lit_underscore1 = "_\x01\x00";
const lit_11 = "\x01\x01\x00";

fn itemStr(gapItem: u16) [*c]const u8 {
    if (gapItem == 0) {
        return lit_11;
    }
    return &indexOfItems[gapItem].itemSoftmenuName;
}
// gapChar1Left/Right: applies when Lt[0]!=0 && Lt[1]==0 && Lt[2]==0
fn gapChar1LR(gapItem: u16) [*c]const u8 {
    const s = itemStr(gapItem);
    if (s[0] != 0 and s[1] == 0 and s[2] == 0) {
        return switch (s[0]) {
            ',' => lit_comma1,
            '.' => lit_dot1,
            '\'' => lit_quote1,
            '_' => lit_underscore1,
            else => s,
        };
    }
    return s;
}
// gapChar1Radix: applies when Rx[0]!=0 && (Rx[1]==0 || Rx[2]==0). Only ',' / '.'.
fn gapChar1Radix(gapItem: u16) [*c]const u8 {
    const s = itemStr(gapItem);
    if (s[0] != 0 and (s[1] == 0 or s[2] == 0)) {
        return switch (s[0]) {
            ',' => lit_comma1,
            '.' => lit_dot1,
            else => s,
        };
    }
    return s;
}
inline fn SEPARATOR_LEFT() [*c]const u8 {
    return gapChar1LR(gapItemLeft);
}
inline fn SEPARATOR_RIGHT() [*c]const u8 {
    return gapChar1LR(gapItemRight);
}
// SEPARATOR_FRAC = gapItemFrac==0 ? "\1\1\0" : indexOfItems[gapItemFrac].itemSoftmenuName
// gapItemFrac = gapItemLeft==0 ? 0 : ITM_SPACE_4_PER_EM
const ITM_SPACE_4_PER_EM: u16 = 870;
inline fn gapItemFrac() u16 {
    return if (gapItemLeft == 0) 0 else ITM_SPACE_4_PER_EM;
}
inline fn SEPARATOR_FRAC() [*c]const u8 {
    const gf = gapItemFrac();
    if (gf == 0) return lit_11;
    return &indexOfItems[gf].itemSoftmenuName;
}
// Rx = indexOfItems[gapItemRadix].itemSoftmenuName (raw, no gapChar1 mapping)
inline fn Rx() [*c]const u8 {
    return &indexOfItems[gapItemRadix].itemSoftmenuName;
}
// RADIX34_MARK_STRING = gapChar1Radix
inline fn RADIX34_MARK_STRING() [*c]const u8 {
    return gapChar1Radix(gapItemRadix);
}

// SEPARATOR_(digitCount) / GROUPWIDTH_(digitCount)
inline fn SEPARATOR_(digitCount: i32) [*c]const u8 {
    return if (digitCount >= 0) SEPARATOR_LEFT() else SEPARATOR_RIGHT();
}
inline fn GROUPWIDTH_LEFT() i32 {
    return grpGroupingLeft;
}
inline fn GROUPWIDTH_RIGHT() i32 {
    return grpGroupingRight;
}
inline fn GROUPWIDTH_LEFT1() u16 {
    return if (grpGroupingGr1Left == 0) @as(u16, grpGroupingLeft) else @as(u16, grpGroupingGr1Left);
}
inline fn GROUPWIDTH_LEFT1X() i32 {
    return grpGroupingGr1LeftOverflow;
}
inline fn GROUPWIDTH_(digitCount: i32) i32 {
    return if (digitCount >= 0) GROUPWIDTH_LEFT() else GROUPWIDTH_RIGHT();
}
inline fn GROUP1_OVFL(digitCount: i32, exp: i32) i32 {
    return if (grpGroupingGr1LeftOverflow > 0 and exp == @as(i32, GROUPWIDTH_LEFT1()) and digitCount + 1 == @as(i32, GROUPWIDTH_LEFT1())) grpGroupingGr1LeftOverflow else 0;
}
inline fn digitCountNEW(digitCount: i32) i32 {
    return if (digitCount + 1 > @as(i32, GROUPWIDTH_LEFT1())) digitCount - @as(i32, GROUPWIDTH_LEFT1()) else digitCount;
}
inline fn IS_SEPARATOR_(digitCount: i32) bool {
    if (digitCount + 1 == @as(i32, GROUPWIDTH_LEFT1())) return true;
    if (digitCount + 1 > @as(i32, GROUPWIDTH_LEFT1()) or digitCount < 0) {
        const gw = GROUPWIDTH_(digitCount);
        return modulo(digitCountNEW(digitCount), gw) == gw - 1;
    }
    return false;
}
inline fn GROUPLEFT_DISABLED() bool {
    return GROUPWIDTH_LEFT() == 0 or gapItemLeft == 0;
}
inline fn GROUPRIGHT_DISABLED() bool {
    return GROUPWIDTH_RIGHT() == 0 or gapItemRight == 0;
}

// ---------------------------------------------------------------------------
// register data accessors (REGISTER_*_DATA / VARIABLE_*_DATA macros).
// ---------------------------------------------------------------------------
const reg34 = abi.registerReal34;
const regComplex34 = abi.registerComplex34;
const regShortInteger = abi.registerShortInteger;
const regMatrixHeader = abi.registerMatrixHeader;
const SIZEOF_STR_LG_INT_HEADER: usize = 4; // sizeof(strLgIntHeader_t)
const regString = abi.registerString;
// VARIABLE_REAL34_DATA(a)=((real34_t*)(a)); VARIABLE_IMAG34_DATA(a)=((real34_t*)(a)+1)
inline fn varReal34(c: *align(1) const complex34_t) *align(1) const real34_t {
    return @ptrCast(c);
}
inline fn varImag34(c: *align(1) const complex34_t) *align(1) const real34_t {
    const p: [*]align(1) const real34_t = @ptrCast(c);
    return &p[1];
}
inline fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn getComplexRegisterPolarMode(reg: calcRegister_t) u32 {
    return getRegisterTag(reg) & amPolar;
}

// stringByteLength(str)=(int32_t)strlen(str)
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}

// ---------------------------------------------------------------------------
// real34 / real arithmetic wrappers (the realType.h macros).
// ---------------------------------------------------------------------------
inline fn real34ToReal(source_: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(@ptrCast(source_), destination);
}
inline fn realToReal34(source_: *const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(@ptrCast(destination), source_, &ctxtReal34);
}
inline fn real34Copy(source_: *align(1) const real34_t, destination: *align(1) real34_t) void {
    _ = decQuadCopy(destination, source_);
}
// C narrows the uint32_t/int32_t decQuad results to int16_t (truncation). The
// special-value sentinel exponents (e.g. for Inf/NaN) overflow i16, which is fine
// in C; reproduce with a low-16-bit truncation rather than a checked @intCast.
inline fn real34Digits(source_: *align(1) const real34_t) i16 {
    return @bitCast(@as(u16, @truncate(decQuadDigits(source_))));
}
inline fn real34GetExponent(source_: *align(1) const real34_t) i16 {
    return @bitCast(@as(u16, @truncate(@as(u32, @bitCast(decQuadGetExponent(source_))))));
}
inline fn real34GetCoefficient(source_: *align(1) const real34_t, bcd: [*c]u8) i32 {
    return decQuadGetCoefficient(source_, bcd);
}
inline fn real34IsNegative(source_: *align(1) const real34_t) bool {
    return (source_.bytes[15] & 0x80) == 0x80;
}
inline fn real34IsPositive(source_: *align(1) const real34_t) bool {
    return (source_.bytes[15] & 0x80) == 0;
}
inline fn real34SetNegativeSign(operand: *align(1) real34_t) void {
    operand.bytes[15] |= 0x80;
}
inline fn real34SetPositiveSign(operand: *align(1) real34_t) void {
    operand.bytes[15] &= 0x7F;
}
inline fn real34IsZero(source_: *align(1) const real34_t) bool {
    return decQuadIsZero(source_) != 0;
}
inline fn real34IsInfinite(source_: *align(1) const real34_t) bool {
    return decQuadIsInfinite(source_) != 0;
}
inline fn real34IsNaN(source_: *align(1) const real34_t) bool {
    return decQuadIsNaN(source_) != 0;
}
inline fn real34Reduce(operand: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadReduce(res, operand, &ctxtReal34);
}
inline fn real34ToString(source_: *align(1) const real34_t, destination: [*c]u8) void {
    _ = decQuadToString(source_, destination);
}
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34CopyAbs(source_: *align(1) const real34_t, destination: *align(1) real34_t) void {
    real34Copy(source_, destination);
    real34SetPositiveSign(destination);
}
inline fn real34Divide(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadDivide(res, a, b, &ctxtReal34);
}
inline fn real34DivideRemainder(a: *align(1) const real34_t, b: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadRemainder(res, a, b, &ctxtReal34);
}
inline fn real34ToIntegralValue(a: *align(1) const real34_t, res: *align(1) real34_t, round: c_int) void {
    _ = decQuadToIntegralValue(res, a, &ctxtReal34, round);
}
inline fn real34ToUInt32(a: *align(1) const real34_t) u32 {
    return decQuadToUInt32(a, &ctxtReal34, DEC_ROUND_DOWN);
}
inline fn realCopy(source_: *const real_t, destination: *real_t) void {
    destination.* = source_.*;
}
inline fn realCopyAbs(source_: *const real_t, destination: *real_t) void {
    destination.* = source_.*;
    destination.bits &= 0x7F;
}
inline fn realIsNegative(r: *const real_t) bool {
    return (r.bits & 0x80) != 0;
}
// realIsZero(x) = decNumberIsZero(x) macro = lsu[0]==0 && digits==1 && !(bits&DECSPECIAL)
const DECSPECIAL: u8 = 0x70;
inline fn realIsZeroB(r: *const real_t) bool {
    return r.lsu[0] == 0 and r.digits == 1 and (r.bits & DECSPECIAL) == 0;
}
inline fn realSetPositiveSign(operand: *real_t) void {
    operand.bits &= 0x7F;
}
inline fn realSetNegativeSign(operand: *real_t) void {
    operand.bits |= 0x80;
}
inline fn realGetExponent(r: *const real_t) i32 {
    return r.digits + r.exponent - 1;
}

// longInteger wrappers (longIntegerType.h static inlines).
inline fn longIntegerInit(op: *longInteger_t) void {
    __gmpz_init(&op[0]);
}
inline fn longIntegerFree(op: *longInteger_t) void {
    __gmpz_clear(&op[0]);
}
inline fn longIntegerIsZero(op: *const longInteger_t) bool {
    return op[0]._mp_size == 0;
}
inline fn longIntegerIsNegative(op: *const longInteger_t) bool {
    return op[0]._mp_size < 0;
}
inline fn longIntegerBits(op: *const longInteger_t) u32 {
    return @intCast(__gmpz_sizeinbase(&op[0], 2));
}
inline fn longIntegerModuloUInt(op: *const longInteger_t, d: u32) u32 {
    return @intCast(__gmpz_fdiv_ui(&op[0], d));
}
inline fn longIntegerDivideUInt(op: *const longInteger_t, d: u32, q: *longInteger_t) void {
    _ = __gmpz_tdiv_q_ui(&q[0], &op[0], d);
}

// extra-info hint (host only, gated like siblings).
inline fn moreInfoOnErr(where: [*c]const u8, hint: [*c]const u8, displayString: [*c]const u8) void {
    if (comptime extra_info) {
        if (comptime !dmcp_build) {
            moreInfoOnError(where, hint, displayString, null);
        }
    }
}

// NOTE: the eight fnDisplayFormat* setters and fnDisplayFormatReset are NOT
// ported here. frontier.zig (the host hub) already owns and exports the
// fnDisplayFormat* family; the display.c copies are the ones the legacy shim
// renamed to z47_frontier_legacy_*. Re-exporting them here would collide, so
// they are intentionally omitted (renamed-away owners).

// ===========================================================================
// exponentToDisplayString / supNumberToDisplayString / subNumberToDisplayString
// ===========================================================================
pub export fn exponentToDisplayString(exponent: i32, displayString_in: [*c]u8, displayValueString_in: [*c]u8, nimMode: bool_t) callconv(.c) void {
    var displayString = displayString_in;
    _ = strcpy(displayString, productSign());
    displayString += 2;
    _ = strcpy(displayString, STD_SUB_10);
    displayString += 2;
    displayString[0] = 0;

    if (displayValueString_in != null) {
        var dv = displayValueString_in;
        dv[0] = 'e';
        dv += 1;
        dv[0] = 0;
    }

    if (nimMode != 0) {
        if (exponent != 0) {
            supNumberToDisplayString(exponent, displayString, displayValueString_in, 0);
        }
    } else {
        supNumberToDisplayString(exponent, displayString, displayValueString_in, 0);
    }
}

pub export fn supNumberToDisplayString(supNumber_in: i32, displayString_in: [*c]u8, displayValueString: [*c]u8, insertGap: bool_t) callconv(.c) void {
    var supNumber = supNumber_in;
    var displayString = displayString_in;
    if (displayValueString != null) {
        abi.fmtCStr(displayValueString, "{d}", .{ supNumber });
    }

    if (supNumber == 0) {
        _ = strcat(displayString, STD_SUP_0);
    } else {
        var digitCount: i16 = 0;
        var greaterThan9999: bool = false;

        if (supNumber < 0) {
            supNumber = -supNumber;
            _ = strcat(displayString, STD_SUP_MINUS);
            displayString += 2;
        }

        greaterThan9999 = (supNumber > 9999);
        while (supNumber > 0) {
            const digit: i16 = @intCast(@rem(supNumber, 10));
            supNumber = @divTrunc(supNumber, 10);

            _ = xcopy(displayString + 2, displayString, @intCast(stringByteLength(displayString) + 1));

            displayString[0] = STD_SUP_0[0];
            displayString[1] = STD_SUP_0[1];
            displayString[1] +%= @intCast(digit);

            if (insertGap != 0 and greaterThan9999 and supNumber > 0 and !GROUPLEFT_DISABLED()) {
                digitCount += 1;
                if (@rem(digitCount, GROUPWIDTH_LEFT()) == 0) {
                    const sl = SEPARATOR_LEFT();
                    if (sl[1] != 1) {
                        _ = xcopy(displayString + 2, displayString, @intCast(stringByteLength(displayString) + 1));
                        displayString[0] = sl[0];
                        displayString[1] = sl[1];
                    } else if (sl[0] != 1) {
                        _ = xcopy(displayString + 1, displayString, @intCast(stringByteLength(displayString) + 1));
                        displayString[0] = sl[0];
                    }
                }
            }
        }
    }

    _ = strcat(displayString, STD_SPACE_HAIR);
}

pub export fn subNumberToDisplayString(subNumber_in: i32, displayString_in: [*c]u8, displayValueString: [*c]u8) callconv(.c) void {
    var subNumber = subNumber_in;
    var displayString = displayString_in;
    if (displayValueString != null) {
        abi.fmtCStr(displayValueString, "{d}", .{ subNumber });
    }

    if (subNumber < 0) {
        subNumber = -subNumber;
        _ = strcat(displayString, STD_SUB_MINUS);
        displayString += 2;
    }

    if (subNumber == 0) {
        _ = strcat(displayString, STD_SUB_0);
    } else {
        while (subNumber > 0) {
            const digit: i16 = @intCast(@rem(subNumber, 10));
            subNumber = @divTrunc(subNumber, 10);

            _ = xcopy(displayString + 2, displayString, @intCast(stringByteLength(displayString) + 1));

            displayString[0] = STD_SUB_0[0];
            displayString[1] = STD_SUB_0[1];
            displayString[1] +%= @intCast(digit);
        }
    }
}

extern fn exponentToUnitDisplayString(exponent: i32, flag2To10: bool_t, displayString: [*c]u8, displayValueString: [*c]u8, nimMode: bool_t) void;

// ===========================================================================
// real34ToDisplayString (public wrapper: shrink digits until it fits maxWidth)
// ===========================================================================
pub export fn real34ToDisplayString(real34: *align(1) const real34_t, tag: u32, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits_in: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: irfracOption_t) callconv(.c) void {
    var displayHasNDigits = displayHasNDigits_in;
    const savedDisplayFormatDigits = displayFormatDigits;
    const savedDisplayFormat = displayFormat;
    const ovrENG: bool = getSystemFlag(FLAG_ENGOVR) != 0;

    if (calcMode == CM_PEM) {
        displayFormat = DF_ALL;
        clearSystemFlag(@intCast(FLAG_ENGOVR));
    }

    if (displayFormat == DF_SF and checkHP()) {
        displayHasNDigits = 10;
    }

    while (true) {
        if (updateDisplayValueX != 0) {
            displayValueX[0] = 0;
        }
        if (tag == amNone) {
            real34ToDisplayString2(real34, displayString, displayHasNDigits, limitExponent, 0, frontSpace, isReal, limitIrfrac);
        } else {
            angle34ToDisplayString2(real34, @intCast(tag), displayString, displayHasNDigits, limitExponent, frontSpace, limitIrfrac);
        }

        if (displayFormat == DF_ALL or displayFormat == DF_SF) {
            if (displayHasNDigits == 2) {
                break;
            }
            displayHasNDigits -= 1;
        } else {
            if (displayFormatDigits == 0) {
                break;
            }
            displayFormatDigits -= 1;
        }
        if (!(stringWidth(displayString, font, 1, 1) > maxWidth)) break;
    }

    displayFormat = savedDisplayFormat;
    displayFormatDigits = savedDisplayFormatDigits;
    if (ovrENG) {
        setSystemFlag(@intCast(FLAG_ENGOVR));
    }
}

const isComplex: bool_t = 1;
const isReal: bool_t = 0;

// ===========================================================================
// angle34ToDisplayString2
// ===========================================================================
pub export fn angle34ToDisplayString2(angle34: *align(1) const real34_t, modeIn: u8, displayString: [*c]u8, displayHasNDigits: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: irfracOption_t) callconv(.c) void {
    const mode: u8 = modeIn & @as(u8, @intCast(amAngleMask));
    if (mode == amDMS) {
        var degStr: [100]u8 = undefined;
        var m: u32 = undefined;
        var s: u32 = undefined;
        var fs: u32 = undefined;
        var sign: i16 = undefined;
        var angle34Dms: real34_t = undefined;
        var angleDms: real_t = undefined;
        var degrees: real_t = undefined;
        var minutes: real_t = undefined;
        var seconds: real_t = undefined;

        real34FromDegToDms(@ptrCast(angle34), &angle34Dms);
        real34ToReal(&angle34Dms, &angleDms);

        sign = @intFromBool(realIsNegative(&angleDms));
        realSetPositiveSign(&angleDms);

        realToIntegralValue(&angleDms, &degrees, DEC_ROUND_DOWN, &ctxtReal39);

        realSubtract(&angleDms, &degrees, &angleDms, &ctxtReal39);
        angleDms.exponent += 2;
        realToIntegralValue(&angleDms, &minutes, DEC_ROUND_DOWN, &ctxtReal39);

        realSubtract(&angleDms, &minutes, &angleDms, &ctxtReal39);
        angleDms.exponent += 2;
        realToIntegralValue(&angleDms, &seconds, DEC_ROUND_DOWN, &ctxtReal39);

        realSubtract(&angleDms, &seconds, &angleDms, &ctxtReal39);
        angleDms.exponent += 2;

        fs = realToUint32C47(&angleDms, null);
        s = realToUint32C47(&seconds, null);
        m = realToUint32C47(&minutes, null);

        if (fs >= 100) {
            fs -= 100;
            s += 1;
        }
        if (s >= 60) {
            s -= 60;
            m += 1;
        }
        if (m >= 60) {
            m -= 60;
            realAdd(&degrees, const_1, &degrees, &ctxtReal39);
        }

        var tmp: real34_t = undefined;
        realToReal34(&degrees, &tmp);
        const savedDisplayFormatDigits = displayFormatDigits;
        const savedDisplayFormat = displayFormat;
        displayFormatDigits = 0;
        displayFormat = DF_ALL;
        real34ToDisplayString2(&tmp, &degStr, displayHasNDigits, limitExponent, 0, frontSpace, 1, limitIrfrac);
        if (degStr[0] == ' ' and degStr[1] != 0) {
            _ = memmove(&degStr, @as([*c]u8, &degStr) + 1, strlen(&degStr));
        }
        displayFormatDigits = savedDisplayFormatDigits;
        displayFormat = savedDisplayFormat;

        const slen: i32 = @intCast(strlen(&degStr));
        const rx = Rx();
        const radix = RADIX34_MARK_STRING();
        const mlen: i32 = if ((rx[0] & 0x80) != 0) @intCast(strlen(radix)) else @intCast(strlen(rx));
        const marker: [*c]const u8 = if ((rx[0] & 0x80) != 0) radix else rx;
        if (slen >= mlen and strcmp(@as([*c]const u8, &degStr) + @as(usize, @intCast(slen - mlen)), marker) == 0) {
            degStr[@intCast(slen - mlen)] = 0;
        }

        var tt: [4]u8 = undefined;
        if (radix[1] != 1) {
            _ = strcpy(&tt, radix);
        } else {
            tt[0] = radix[0];
            tt[1] = 0;
        }

        abi.fmtCStr(displayString, "{s}{s}" ++ STD_DEGREE ++ "{s}{d}" ++ STD_RIGHT_SINGLE_QUOTE ++ "{s}{d}{s}{d:0>2}" ++ STD_RIGHT_DOUBLE_QUOTE, .{ @as([*:0]const u8, @as([*c]const u8, if (sign != 0) "-" else " ")), @as([*:0]const u8, @as([*c]const u8, &degStr)), @as([*:0]const u8, @as([*c]const u8, if (m < 10) " " else "")), m, @as([*:0]const u8, @as([*c]const u8, if (s < 10) " " else "")), s, @as([*:0]const u8, @as([*c]const u8, &tt)), fs });
    } else if (mode == amMultPi) {
        real34ToDisplayString2(angle34, displayString, displayHasNDigits, limitExponent, @intFromBool(mode == amSecond), frontSpace, isReal, limitIrfrac);
        _ = strcat(displayString, STD_SUP_pir);
    } else {
        real34ToDisplayString2(angle34, displayString, displayHasNDigits, limitExponent, @intFromBool(mode == amSecond), frontSpace, isReal, limitIrfrac);

        if (mode == amRadian) {
            _ = strcat(displayString, STD_SUP_BOLD_r);
        } else if (mode == amGrad) {
            _ = strcat(displayString, STD_SUP_BOLD_g);
        } else if (mode == amDegree) {
            _ = strcat(displayString, STD_DEGREE);
        } else if (mode == amSecond) {
            _ = strcat(displayString, "s");
        } else {
            _ = strcat(displayString, "?");
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "angle34ToDisplayString2", @as(c_int, mode), "mode" });
            displayBugScreen(errorMessage);
        }
    }
}

// ===========================================================================
// real34ToDisplayString2 (the core FIX/SCI/ENG/ALL/SIG/UN formatter)
// ===========================================================================
const MAX_DIGITS: i16 = 37;

const IrfracReplacement = struct {
    cnst: *const real_t,
    name: [*c]const u8,
    option: irfracOption_t,
};

fn irfracReplacements() [15]IrfracReplacement {
    return .{
        .{ .cnst = const_1, .name = "", .option = NOIRFRAC },
        .{ .cnst = const39_rt3, .name = STD_SQUARE_ROOT ++ STD_SUB_3, .option = LIMITIRFRAC },
        .{ .cnst = const39_root2, .name = STD_SQUARE_ROOT ++ STD_SUB_2, .option = LIMITIRFRAC },
        .{ .cnst = const39_pi, .name = STD_pi, .option = LIMITIRFRAC },
        .{ .cnst = const39_eE, .name = STD_EulerE, .option = LIGHTIRFRAC },
        .{ .cnst = const39_PHI, .name = STD_phi_m, .option = LIGHTIRFRAC },
        .{ .cnst = const39_rt5, .name = STD_SQUARE_ROOT ++ STD_SUB_5, .option = LIGHTIRFRAC },
        .{ .cnst = const39_rt7, .name = STD_SQUARE_ROOT ++ STD_SUB_7, .option = LIGHTIRFRAC },
        .{ .cnst = const39_rtpi, .name = STD_SQUARE_ROOT ++ STD_pi, .option = LIGHTIRFRAC },
        .{ .cnst = const39_1onpi, .name = oneOverPi, .option = LIGHTIRFRAC },
        .{ .cnst = const39_1oneE, .name = oneOverE, .option = LIGHTIRFRAC },
        .{ .cnst = const39_pisq, .name = "(" ++ STD_pi ++ STD_SUP_2 ++ STD_SPACE_HAIR ++ STD_SPACE_HAIR ++ ")", .option = FULLIRFRAC },
        .{ .cnst = const39_eEsq, .name = "(" ++ STD_EulerE ++ STD_SUP_2 ++ STD_SPACE_HAIR ++ STD_SPACE_HAIR ++ ")", .option = FULLIRFRAC },
        .{ .cnst = const39_1onpisq, .name = "(" ++ STD_pi ++ STD_SUP_MINUS ++ STD_SUP_2 ++ STD_SPACE_HAIR ++ STD_SPACE_HAIR ++ ")", .option = FULLIRFRAC },
        .{ .cnst = const39_1oneEsq, .name = "(" ++ STD_EulerE ++ STD_SUP_MINUS ++ STD_SUP_2 ++ STD_SPACE_HAIR ++ STD_SPACE_HAIR ++ ")", .option = FULLIRFRAC },
    };
}

// radix mark into tt[4]; returns nothing, the C code copies bytes then strcat.
fn radixTT(tt: *[4]u8) void {
    const radix = RADIX34_MARK_STRING();
    if (radix[1] != 1) {
        _ = strcpy(tt, radix);
    } else {
        tt[0] = radix[0];
        tt[1] = 0;
    }
}

fn real34ToDisplayString2(real34_in: *align(1) const real34_t, displayString: [*c]u8, displayHasNDigits: i16, limitExponent: bool_t, noFix: bool_t, frontSpace: bool_t, complex: bool_t, limitIrfrac: irfracOption_t) void {
    // real34 is passed const but the 2TO10/UN path mutates *real34 then restores it.
    const real34: *align(1) real34_t = @constCast(real34_in);
    const exponentUNlimit1024max: i32 = if (getSystemFlag(FLAG_PFX_ALL) != 0) 7 else 5;
    // SIG0: when set, DF_SF keeps trailing significant zeros (and rounds at the
    // sig boundary); when clear, no trailing zeros are emitted. (defines.h FLAG_SIGZEROS)
    const forceSigZeroes: bool = getSystemFlag(FLAG_SIGZEROS) != 0;

    var charIndex: u8 = undefined;
    var valueIndex: u8 = undefined;
    var digitToRound: i16 = 0;
    var digitsToDisplay: i16 = 0;
    var numDigits: i16 = undefined;
    var digitPointer: i16 = undefined;
    var firstDigit: i16 = undefined;
    var lastDigit: i16 = undefined;
    var i: i16 = undefined;
    var digitCount: i16 = undefined;
    var digitsToTruncate: i16 = undefined;
    var exponent: i16 = undefined;
    var sign: i32 = undefined;
    var ovrSCI: bool = false;
    var ovrENG: bool = false;
    var firstDigitAfterPeriod: bool = true;
    var value34: real34_t = undefined;

    var exponentUNlimit: i32 = 0;
    var flag2To10: bool = getSystemFlag(FLAG_2TO10) != 0;
    var flag2To10_baseunit_integer: bool = false;
    var tmpIp: real_t = undefined;
    var real34bak: real34_t = undefined;
    real34Copy(real34, &real34bak);
    if (flag2To10 and displayFormat == DF_UN) {
        blk2to10: {
            var x: real_t = undefined;
            var xx: real_t = undefined;
            real34ToReal(real34, &x);

            if (!(realCompareAbsLessThan(&x, const_1024) != 0)) {
                const neg: bool = realIsNegative(&x);
                if (neg) {
                    realSetPositiveSign(&x);
                }
                realCopy(&x, &xx);

                var c: realContext_t = ctxtReal39;
                var maxExponent: c_int = x.exponent + x.digits;
                c.digits = if (showmode()) 39 else minI(75, maxI(0, maxExponent) + nbrDispRealCtxDigits());
                WP34S_Ln(&x, &x, &c);
                maxExponent = x.exponent + x.digits;
                c.digits = if (showmode()) 39 else minI(75, maxI(0, maxExponent) + nbrDispRealCtxDigits());
                realDivide(&x, const39_ln2, &x, &c);
                x.exponent -= 1;

                realToIntegralValue(&x, &tmpIp, DEC_ROUND_DOWN, &c);
                const tmpx: i32 = realToInt32C47(&tmpIp, null);
                if (tmpx > exponentUNlimit1024max) {
                    // overRange
                    flag2To10 = false;
                    break :blk2to10;
                }
                exponentUNlimit = tmpx;
                int32ToReal(exponentUNlimit, &tmpIp);

                realDivide(const_1000, const_1024, &x, &ctxtReal39);
                realPower(&x, &tmpIp, &x, &ctxtReal39);
                realMultiply(&xx, &x, &x, &ctxtReal39);

                if (neg) {
                    realSetNegativeSign(&x);
                }
                realToReal34(&x, real34);
            } else {
                flag2To10_baseunit_integer = true;
                flag2To10 = false;
            }
        }
    }

    var value: real_t = undefined;

    if (limitIrfrac != NOIRFRAC) {
        if (getSystemFlag(FLAG_IRFRAC) != 0 and IrFractionsCurrentStatus != CF_OFF and !(real34CompareAbsLessThan(real34, const34_1e_24) != 0) and !(real34IsAnInteger(real34) != 0)) {
            const toleranceIrrational: *const real_t = const_1e_24;
            var valueReal: real_t = undefined;
            var valueRealAbs: real_t = undefined;
            const replacements = irfracReplacements();

            real34ToReal(real34, &valueReal);
            realCopyAbs(&valueReal, &valueRealAbs);
            for (0..replacements.len) |ridx| {
                const rep = replacements[ridx];
                if ((limitIrfrac >= rep.option and runningOnSimOrUSB()) or limitIrfrac == FULLIRFRAC) {
                    if (checkForAndChange(displayString, &valueReal, &valueRealAbs, rep.cnst, toleranceIrrational, rep.name, frontSpace, complex) != 0) {
                        IrFractionsCurrentStatus = CF_NORMAL;
                        return;
                    }
                }
            }
        }
    }
    IrFractionsCurrentStatus = CF_NORMAL;

    // sigfig
    if (displayFormat == DF_SF) {
        exponent = @intCast(@as(i32, real34GetExponent(real34)) + @as(i32, real34Digits(real34)) - 1);
        if (absI(exponent) <= displayHasNDigits) {
            // C uses char[100] here; the SF reduce/skip walk can index a few
            // bytes past the real34ToString terminator (harmless stack reads in
            // C). Zero-initialize and oversize so those reads stay in-bounds and
            // see a terminator, keeping the algorithm's outcome identical.
            var tmpString100: [256]u8 = std.mem.zeroes([256]u8);
            var reduced: real34_t = undefined;
            var tmp1: real_t = undefined;

            real34ToReal(real34, &tmp1);
            var c: realContext_t = ctxtReal39;
            c.digits = if (showmode()) 39 else nbrDispRealCtxDigits();
            if (forceSigZeroes) {
                roundToSignificantDigits(&tmp1, &tmp1, @as(u16, displayFormatDigits) + 1, &c);
            }
            realToReal34(&tmp1, &reduced);
            real34Reduce(&reduced, &reduced);
            real34ToString(&reduced, &tmpString100);
            var ii: i8 = 0;
            while (tmpString100[@intCast(ii)] != 0) {
                while (tmpString100[@intCast(ii)] == '0') {
                    if (tmpString100[@intCast(ii)] == 0) break;
                    ii += 1;
                }
                if (tmpString100[@intCast(ii)] == '.') {
                    ii += 1;
                    while (tmpString100[@intCast(ii)] == '0') {
                        if (tmpString100[@intCast(ii)] == 0) break;
                        ii += 1;
                    }
                    if (tmpString100[@intCast(ii)] != 0) {
                        ii = ii + @as(i8, @intCast(displayFormatDigits)) + 1;
                        var jj: i8 = ii;
                        while (tmpString100[@intCast(jj)] != 0 and tmpString100[@intCast(jj)] != 'E') {
                            jj += 1;
                        }
                        if (tmpString100[@intCast(jj)] == 'E') {
                            while (tmpString100[@intCast(jj)] != 0) {
                                tmpString100[@intCast(ii)] = tmpString100[@intCast(jj)];
                                jj += 1;
                                ii += 1;
                            }
                            tmpString100[@intCast(ii)] = 0;
                        }
                    }
                    break;
                } else {
                    ii += 1;
                }
            }
            stringToReal(&tmpString100, &value, &ctxtReal39);
        } else {
            real34ToReal(real34, &value);
        }
    } else {
        real34ToReal(real34, &value);
    }

    if (checkHP()) {
        ctxtReal39.digits = minI(10, displayHasNDigits);
        realPlus(&value, &value, &ctxtReal39);
        ctxtReal39.digits = 39;
    }

    realToReal34(&value, &value34);
    if (displayFormat == DF_SF) {
        real34Reduce(&value34, &value34);
    }
    if (real34IsNegative(real34)) {
        real34SetNegativeSign(&value34);
    }

    var tmpString100b: [100]u8 = undefined;
    const bcd: [*c]u8 = &tmpString100b;
    _ = memset(bcd, 0, @intCast(MAX_DIGITS));

    sign = real34GetCoefficient(&value34, bcd + 1);
    exponent = @intCast(real34GetExponent(&value34));

    digitPointer = 1;
    while (digitPointer <= MAX_DIGITS - 3) : (digitPointer += 1) {
        if (bcd[@intCast(digitPointer)] != 0) break;
    }

    if (digitPointer >= MAX_DIGITS - 2) {
        firstDigit = 0;
        lastDigit = 0;
        numDigits = 1;
        exponent = 0;
    } else {
        firstDigit = digitPointer;
        digitPointer = MAX_DIGITS - 3;
        while (digitPointer >= 1) : (digitPointer -= 1) {
            if (bcd[@intCast(digitPointer)] == 0) {
                exponent += 1;
            } else break;
        }
        lastDigit = digitPointer;
        numDigits = lastDigit - firstDigit;
        exponent += numDigits;
        numDigits += 1;
    }

    if (limitExponent != 0) {
        if (exponent > exponentLimit) {
            if (real34IsPositive(&value34)) {
                if (frontSpace != 0) {
                    _ = strcpy(displayString, " " ++ STD_LEFT_SINGLE_QUOTE ++ STD_INFINITY ++ STD_RIGHT_SINGLE_QUOTE);
                } else {
                    _ = strcpy(displayString, STD_LEFT_SINGLE_QUOTE ++ STD_INFINITY ++ STD_RIGHT_SINGLE_QUOTE);
                }
                if (updateDisplayValueX != 0) {
                    _ = strcpy(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "9e9999");
                }
            } else if (real34IsNegative(&value34)) {
                _ = strcpy(displayString, "-" ++ STD_LEFT_SINGLE_QUOTE ++ STD_INFINITY ++ STD_RIGHT_SINGLE_QUOTE);
                if (updateDisplayValueX != 0) {
                    _ = strcpy(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "-9e9999");
                }
            }
            return;
        } else if (exponent < -exponentLimit or (exponentHideLimit != 0 and exponent < -exponentHideLimit and currentMenu() != -MNU_XXFCNS)) {
            if (real34IsPositive(&value34)) {
                _ = strcpy(displayString, STD_ALMOST_EQUAL ++ "0");
                if (updateDisplayValueX != 0) {
                    _ = strcpy(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "0");
                }
            } else if (real34IsNegative(&value34)) {
                _ = strcpy(displayString, STD_ALMOST_EQUAL ++ "-0");
                if (updateDisplayValueX != 0) {
                    _ = strcpy(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "-0");
                }
            }
            return;
        }
    }

    if (real34IsInfinite(&value34)) {
        if (real34IsNegative(&value34)) {
            _ = strcpy(displayString, "-" ++ STD_INFINITY);
            if (updateDisplayValueX != 0) {
                _ = strcpy(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "-9e9999");
            }
        } else {
            _ = strcpy(displayString, " " ++ STD_INFINITY);
            if (updateDisplayValueX != 0) {
                _ = strcpy(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "9e9999");
            }
        }
        return;
    }

    if (real34IsNaN(&value34)) {
        real34ToString(&value34, displayString);
        if (updateDisplayValueX != 0) {
            real34ToString(&value34, @as([*c]u8, &displayValueX) + strlen(&displayValueX));
        }
        return;
    }

    charIndex = 0;
    valueIndex = if (updateDisplayValueX != 0) @intCast(strlen(&displayValueX)) else 0;

    // ALL mode
    if (displayFormat == DF_ALL) {
        digitsToTruncate = @intCast(maxI(numDigits - displayHasNDigits, 0));
        numDigits -= digitsToTruncate;
        lastDigit -= digitsToTruncate;

        if (bcd[@intCast(lastDigit + 1)] == 9) {
            bcd[@intCast(lastDigit)] += 1;
            while (bcd[@intCast(lastDigit)] == 10) {
                bcd[@intCast(lastDigit)] = 0;
                lastDigit -= 1;
                numDigits -= 1;
                bcd[@intCast(lastDigit)] += 1;
            }
            if (lastDigit < firstDigit) {
                firstDigit -= 1;
                lastDigit = firstDigit;
                numDigits = 1;
                exponent += 1;
            }
        }

        if (noFix != 0 or exponent >= displayHasNDigits or
            exponent <= -displayHasNDigits or
            (displayFormatDigits != 0 and exponent < -@as(i32, displayFormatDigits)) or
            (displayFormatDigits == 0 and exponent < numDigits - displayHasNDigits))
        {
            digitsToDisplay = @intCast(minI(displayHasNDigits, numDigits - 1));
            digitToRound = @intCast(minI(firstDigit + digitsToDisplay, lastDigit));
            ovrSCI = getSystemFlag(FLAG_ENGOVR) == 0;
            ovrENG = getSystemFlag(FLAG_ENGOVR) != 0;
        } else {
            if (bcd[@intCast(lastDigit + 1)] >= 5) {
                bcd[@intCast(lastDigit)] += 1;
            }
            while (bcd[@intCast(lastDigit)] == 10) {
                bcd[@intCast(lastDigit)] = 0;
                lastDigit -= 1;
                numDigits -= 1;
                bcd[@intCast(lastDigit)] += 1;
            }
            if (lastDigit < firstDigit) {
                firstDigit -= 1;
                lastDigit = firstDigit;
                numDigits = 1;
                exponent += 1;
            }
            while (numDigits > 1 and bcd[@intCast(lastDigit)] == 0) {
                lastDigit -= 1;
                numDigits -= 1;
            }

            if (sign != 0) {
                displayString[charIndex] = '-';
                charIndex += 1;
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '-';
                    valueIndex += 1;
                }
            } else {
                if (frontSpace != 0) {
                    displayString[charIndex] = ' ';
                    charIndex += 1;
                }
            }

            if (exponent < 0) {
                displayString[charIndex] = '0';
                charIndex += 1;
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '0';
                    valueIndex += 1;
                }
                displayString[charIndex] = 0;
                var tt: [4]u8 = undefined;
                radixTT(&tt);
                _ = strcat(displayString, &tt);
                charIndex +%= @intCast(strlen(&tt));
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '.';
                    valueIndex += 1;
                }

                digitCount = 0;
                i = exponent + 1;
                while (i < 0) : ({
                    i += 1;
                    digitCount -= 1;
                }) {
                    if (digitCount != 0 and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == 0) {
                        const sr = SEPARATOR_RIGHT();
                        const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                        _ = xcopy(displayString + charIndex, sr, n);
                        charIndex +%= @intCast(n);
                    }
                    displayString[charIndex] = '0';
                    charIndex += 1;
                    if (updateDisplayValueX != 0) {
                        displayValueX[valueIndex] = '0';
                        valueIndex += 1;
                    }
                }

                digitPointer = firstDigit;
                while (digitPointer < firstDigit + @as(i16, @intCast(minI(@as(i32, displayHasNDigits) - 1 - exponent, numDigits)))) : ({
                    digitPointer += 1;
                    digitCount -= 1;
                }) {
                    if (digitCount != 0 and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == 0) {
                        const sr = SEPARATOR_RIGHT();
                        const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                        _ = xcopy(displayString + charIndex, sr, n);
                        charIndex +%= @intCast(n);
                    }
                    displayString[charIndex] = '0' + bcd[@intCast(digitPointer)];
                    charIndex += 1;
                    if (updateDisplayValueX != 0) {
                        displayValueX[valueIndex] = '0' + bcd[@intCast(digitPointer)];
                        valueIndex += 1;
                    }
                }
            } else {
                digitCount = exponent;
                digitPointer = firstDigit;
                while (digitPointer <= lastDigit + @as(i16, @intCast(maxI(exponent - numDigits + 1, 0)))) : ({
                    digitPointer += 1;
                    digitCount -= 1;
                }) {
                    if (digitCount != -1 and digitCount != exponent and GROUPWIDTH_(digitCount) != 0 and IS_SEPARATOR_(digitCount) and (GROUP1_OVFL(digitCount, exponent) == 0 or bcd[@intCast(digitPointer - 1)] >= GROUP1_OVFL(digitCount, exponent) + 1)) {
                        _ = xcopy(displayString + charIndex, SEPARATOR_(digitCount), 2);
                        charIndex +%= 2;
                    }
                    if (digitPointer <= lastDigit) {
                        displayString[charIndex] = '0' + bcd[@intCast(digitPointer)];
                        charIndex += 1;
                        if (updateDisplayValueX != 0) {
                            displayValueX[valueIndex] = '0' + bcd[@intCast(digitPointer)];
                            valueIndex += 1;
                        }
                    } else {
                        displayString[charIndex] = '0';
                        charIndex += 1;
                        if (updateDisplayValueX != 0) {
                            displayValueX[valueIndex] = '0';
                            valueIndex += 1;
                        }
                    }
                    if (digitCount == 0) {
                        displayString[charIndex] = 0;
                        var tt: [4]u8 = undefined;
                        radixTT(&tt);
                        _ = strcat(displayString, &tt);
                        charIndex +%= @intCast(strlen(&tt));
                        if (updateDisplayValueX != 0) {
                            displayValueX[valueIndex] = '.';
                            valueIndex += 1;
                        }
                    }
                }
            }

            displayString[charIndex] = 0;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = 0;
            }
            return;
        }
    }

    // FIX / SIG / 2to10-baseunit-integer mode
    if (displayFormat == DF_FIX or displayFormat == DF_SF or flag2To10_baseunit_integer) {
        if (noFix != 0 or exponent >= (if (checkHP()) @as(i16, 11) else displayHasNDigits) or
            ((displayFormat == DF_SF) and (exponent < (if (getSystemFlag(FLAG_ENGOVR) != 0) @as(i16, -2) else -3))) or
            ((displayFormat != DF_SF) and (exponent < -@as(i32, displayFormatDigits))) or
            (displayFormat == DF_SF and exponent - @as(i32, displayFormatDigits) < -(if (checkHP()) @as(i32, 11) else displayHasNDigits)) or
            (displayFormat == DF_SF and !checkHP() and exponent - @as(i32, displayFormatDigits) > @as(i32, GROUPWIDTH_LEFT1())))
        {
            digitsToDisplay = @intCast(minI(displayFormatDigits, (if (checkHP()) @as(i16, 11) else displayHasNDigits) - 1));
            digitToRound = @intCast(minI(firstDigit + digitsToDisplay, lastDigit));
            ovrSCI = getSystemFlag(FLAG_ENGOVR) == 0;
            ovrENG = getSystemFlag(FLAG_ENGOVR) != 0;
        } else {
            var displayFormatDigits_Active: u8 = undefined;
            if (displayFormat == DF_SF) {
                displayFormatDigits_Active = @intCast(minI(maxI((@as(i32, displayFormatDigits) + 1) - exponent - 1, 0), 255));
            } else {
                displayFormatDigits_Active = displayFormatDigits;
            }
            digitsToTruncate = @intCast(maxI(numDigits - @as(i32, displayFormatDigits_Active) - exponent - 1, 0));
            numDigits -= digitsToTruncate;
            lastDigit -= digitsToTruncate;

            if (displayFormat == DF_SF and firstDigit + @as(i16, displayFormatDigits) <= 34 and forceSigZeroes) {
                digitToRound = firstDigit + @as(i16, displayFormatDigits);
            } else {
                digitToRound = lastDigit;
            }

            if (bcd[@intCast(digitToRound + 1)] >= 5) {
                bcd[@intCast(digitToRound)] += 1;
            }
            while (bcd[@intCast(digitToRound)] == 10) {
                bcd[@intCast(digitToRound)] = 0;
                digitToRound -= 1;
                if (displayFormat == DF_SF) {
                    numDigits -= 1;
                }
                bcd[@intCast(digitToRound)] += 1;
            }
            if (displayFormat == DF_SF and forceSigZeroes) {
                lastDigit = digitToRound;
            }
            if (digitToRound < firstDigit) {
                firstDigit -= 1;
                lastDigit = firstDigit;
                numDigits = 1;
                if (displayFormat == DF_SF) {
                    displayFormatDigits_Active -%= 1;
                }
                exponent += 1;
            }

            if (displayFormat == DF_SF and forceSigZeroes) {
                if ((@as(i32, displayFormatDigits) + 1) - exponent - 1 < 0) {
                    digitCount = firstDigit + @as(i16, displayFormatDigits) + 1;
                    while (digitCount <= 34) : (digitCount += 1) {
                        bcd[@intCast(digitCount)] = 0;
                    }
                }
            }

            if (sign != 0) {
                displayString[charIndex] = '-';
                charIndex += 1;
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '-';
                    valueIndex += 1;
                }
            } else {
                if (frontSpace != 0) {
                    displayString[charIndex] = ' ';
                    charIndex += 1;
                }
            }

            if (exponent < 0) {
                displayString[charIndex] = '0';
                charIndex += 1;
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '0';
                    valueIndex += 1;
                }
                displayString[charIndex] = 0;
                var tt: [4]u8 = undefined;
                radixTT(&tt);
                _ = strcat(displayString, &tt);
                charIndex +%= @intCast(strlen(&tt));
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '.';
                    valueIndex += 1;
                }

                digitCount = 0;
                i = exponent + 1;
                while (i < 0) : ({
                    i += 1;
                    digitCount -= 1;
                }) {
                    if (digitCount != 0 and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == 0) {
                        const sr = SEPARATOR_RIGHT();
                        const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                        _ = xcopy(displayString + charIndex, sr, n);
                        charIndex +%= @intCast(n);
                    }
                    displayString[charIndex] = '0';
                    charIndex += 1;
                    if (updateDisplayValueX != 0) {
                        displayValueX[valueIndex] = '0';
                        valueIndex += 1;
                    }
                }

                digitPointer = firstDigit;
                while (digitPointer <= lastDigit) : ({
                    digitPointer += 1;
                    digitCount -= 1;
                }) {
                    if (digitCount != 0 and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == 0) {
                        const sr = SEPARATOR_RIGHT();
                        const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                        _ = xcopy(displayString + charIndex, sr, n);
                        charIndex +%= @intCast(n);
                    }
                    displayString[charIndex] = '0' + bcd[@intCast(digitPointer)];
                    charIndex += 1;
                    if (updateDisplayValueX != 0) {
                        displayValueX[valueIndex] = '0' + bcd[@intCast(digitPointer)];
                        valueIndex += 1;
                    }
                }

                var zerosAfter: i32 = @as(i32, displayFormatDigits_Active) + exponent + 1 - numDigits;
                if (displayFormat == DF_SF and !forceSigZeroes) {
                    zerosAfter = 0; // no-zero: emit no trailing fractional zeros
                }
                i = 1;
                while (i <= zerosAfter) : ({
                    i += 1;
                    digitCount -= 1;
                }) {
                    if (!GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == 0) {
                        const sr = SEPARATOR_RIGHT();
                        const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                        _ = xcopy(displayString + charIndex, sr, n);
                        charIndex +%= @intCast(n);
                    }
                    displayString[charIndex] = '0';
                    charIndex += 1;
                    if (updateDisplayValueX != 0) {
                        displayValueX[valueIndex] = '0';
                        valueIndex += 1;
                    }
                }
            } else {
                digitCount = exponent;
                digitPointer = firstDigit;
                var fixLoopEnd: i16 = firstDigit + exponent + @as(i16, displayFormatDigits_Active);
                if (displayFormat == DF_SF and !forceSigZeroes) {
                    // no-zero: stop at the last significant digit, never before the integer part
                    fixLoopEnd = @intCast(minI(fixLoopEnd, maxI(lastDigit, firstDigit + exponent)));
                }
                while (digitPointer <= fixLoopEnd) : ({
                    digitPointer += 1;
                    digitCount -= 1;
                }) {
                    if (digitCount != -1 and digitCount != exponent and GROUPWIDTH_(digitCount) != 0 and IS_SEPARATOR_(digitCount) and (GROUP1_OVFL(digitCount, exponent) == 0 or bcd[@intCast(digitPointer - 1)] >= GROUP1_OVFL(digitCount, exponent) + 1)) {
                        _ = xcopy(displayString + charIndex, SEPARATOR_(digitCount), 2);
                        charIndex +%= 2;
                    }
                    if (digitPointer <= lastDigit) {
                        displayString[charIndex] = '0' + bcd[@intCast(digitPointer)];
                        charIndex += 1;
                        if (updateDisplayValueX != 0) {
                            displayValueX[valueIndex] = '0' + bcd[@intCast(digitPointer)];
                            valueIndex += 1;
                        }
                    } else {
                        displayString[charIndex] = '0';
                        charIndex += 1;
                        if (updateDisplayValueX != 0) {
                            displayValueX[valueIndex] = '0';
                            valueIndex += 1;
                        }
                    }
                    if (digitCount == 0) {
                        displayString[charIndex] = 0;
                        var tt: [4]u8 = undefined;
                        radixTT(&tt);
                        _ = strcat(displayString, &tt);
                        charIndex +%= @intCast(strlen(&tt));
                        if (updateDisplayValueX != 0) {
                            displayValueX[valueIndex] = '.';
                            valueIndex += 1;
                        }
                    }
                }
            }

            displayString[charIndex] = 0;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = 0;
            }
            return;
        }
    }

    // SCI mode
    if (ovrSCI or displayFormat == DF_SCI) {
        if (!ovrSCI) {
            digitsToDisplay = displayFormatDigits;
            digitToRound = @intCast(minI(firstDigit + @as(i16, displayFormatDigits), lastDigit));
        }
        if (bcd[@intCast(digitToRound + 1)] >= 5) {
            bcd[@intCast(digitToRound)] += 1;
        }
        while (bcd[@intCast(digitToRound)] == 10) {
            bcd[@intCast(digitToRound)] = 0;
            digitToRound -= 1;
            numDigits -= 1;
            bcd[@intCast(digitToRound)] += 1;
        }
        if (digitToRound < firstDigit) {
            firstDigit -= 1;
            numDigits = 1;
            exponent += 1;
        }

        if (sign != 0) {
            displayString[charIndex] = '-';
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '-';
                valueIndex += 1;
            }
        } else {
            if (frontSpace != 0) {
                displayString[charIndex] = ' ';
                charIndex += 1;
            }
        }

        displayString[charIndex] = '0' + bcd[@intCast(firstDigit)];
        charIndex += 1;
        if (updateDisplayValueX != 0) {
            displayValueX[valueIndex] = '0' + bcd[@intCast(firstDigit)];
            valueIndex += 1;
        }

        displayString[charIndex] = 0;
        var tt: [4]u8 = undefined;
        radixTT(&tt);
        _ = strcat(displayString, &tt);
        charIndex +%= @intCast(strlen(&tt));
        if (updateDisplayValueX != 0) {
            displayValueX[valueIndex] = '.';
            valueIndex += 1;
        }

        digitCount = -1;
        digitPointer = firstDigit + 1;
        while (digitPointer < firstDigit + @as(i16, @intCast(minI(numDigits, digitsToDisplay + 1)))) : ({
            digitPointer += 1;
            digitCount -= 1;
        }) {
            if (!firstDigitAfterPeriod and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT())))))) - 1) {
                const sr = SEPARATOR_RIGHT();
                const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                _ = xcopy(displayString + charIndex, sr, n);
                charIndex +%= @intCast(n);
            } else {
                firstDigitAfterPeriod = false;
            }
            displayString[charIndex] = '0' + bcd[@intCast(digitPointer)];
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '0' + bcd[@intCast(digitPointer)];
                valueIndex += 1;
            }
        }

        digitPointer = 0;
        while (digitPointer <= digitsToDisplay - numDigits) : ({
            digitPointer += 1;
            digitCount -= 1;
        }) {
            if (!firstDigitAfterPeriod and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT())))))) - 1) {
                const sr = SEPARATOR_RIGHT();
                const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                _ = xcopy(displayString + charIndex, sr, n);
                charIndex +%= @intCast(n);
            } else {
                firstDigitAfterPeriod = false;
            }
            displayString[charIndex] = '0';
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '0';
                valueIndex += 1;
            }
        }

        displayString[charIndex] = 0;
        if (updateDisplayValueX != 0) {
            displayValueX[valueIndex] = 0;
        }

        if (exponent != 0) {
            if (updateDisplayValueX != 0) {
                exponentToDisplayString(exponent, displayString + charIndex, @as([*c]u8, &displayValueX) + valueIndex, 0);
            } else {
                exponentToDisplayString(exponent, displayString + charIndex, null, 0);
            }
        }
        return;
    }

    // ENG / UN mode
    if (ovrENG or displayFormat == DF_ENG or displayFormat == DF_UN) {
        if (!ovrENG) {
            digitsToDisplay = displayFormatDigits;
            digitToRound = @intCast(minI(firstDigit + digitsToDisplay, lastDigit));
        }

        if (bcd[@intCast(digitToRound + 1)] >= 5) {
            bcd[@intCast(digitToRound)] += 1;
        }
        bcd[@intCast(digitToRound + 1)] = 0;
        bcd[@intCast(digitToRound + 2)] = 0;

        while (bcd[@intCast(digitToRound)] == 10) {
            bcd[@intCast(digitToRound)] = 0;
            digitToRound -= 1;
            numDigits -= 1;
            bcd[@intCast(digitToRound)] += 1;
        }
        if (digitToRound < firstDigit) {
            firstDigit -= 1;
            numDigits = 1;
            exponent += 1;
        }

        if (sign != 0) {
            displayString[charIndex] = '-';
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '-';
                valueIndex += 1;
            }
        } else {
            if (frontSpace != 0) {
                displayString[charIndex] = ' ';
                charIndex += 1;
            }
        }

        displayString[charIndex] = '0' + bcd[@intCast(firstDigit)];
        charIndex += 1;
        if (updateDisplayValueX != 0) {
            displayValueX[valueIndex] = '0' + bcd[@intCast(firstDigit)];
            valueIndex += 1;
        }
        firstDigit += 1;
        numDigits -= 1;
        digitsToDisplay -= 1;
        while (modulo(exponent, 3) != 0) {
            exponent -= 1;
            displayString[charIndex] = '0' + bcd[@intCast(firstDigit)];
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '0' + bcd[@intCast(firstDigit)];
                valueIndex += 1;
            }
            firstDigit += 1;
            numDigits -= 1;
            digitsToDisplay -= 1;
        }

        if (flag2To10 and displayFormat == DF_UN) {
            while (exponent != exponentUNlimit * 3) {
                if (exponent > exponentUNlimit * 3) {
                    exponent -= 1;
                } else if (exponent < exponentUNlimit * 3) {
                    exponent += 1;
                }
                displayString[charIndex] = '0' + bcd[@intCast(firstDigit)];
                charIndex += 1;
                if (updateDisplayValueX != 0) {
                    displayValueX[valueIndex] = '0' + bcd[@intCast(firstDigit)];
                    valueIndex += 1;
                }
                firstDigit += 1;
                numDigits -= 1;
                digitsToDisplay -= 1;
            }
        }

        displayString[charIndex] = 0;
        var tt: [4]u8 = undefined;
        radixTT(&tt);
        _ = strcat(displayString, &tt);
        charIndex +%= @intCast(strlen(&tt));
        if (updateDisplayValueX != 0) {
            displayValueX[valueIndex] = '.';
            valueIndex += 1;
        }

        digitCount = -1;
        digitPointer = firstDigit;
        while (digitPointer < firstDigit + @as(i16, @intCast(minI(numDigits, digitsToDisplay + 1)))) : ({
            digitPointer += 1;
            digitCount -= 1;
        }) {
            if (!firstDigitAfterPeriod and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT())))))) - 1) {
                const sr = SEPARATOR_RIGHT();
                const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                _ = xcopy(displayString + charIndex, sr, n);
                charIndex +%= @intCast(n);
            } else {
                firstDigitAfterPeriod = false;
            }
            displayString[charIndex] = '0' + bcd[@intCast(digitPointer)];
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '0' + bcd[@intCast(digitPointer)];
                valueIndex += 1;
            }
        }

        digitPointer = 0;
        while (digitPointer <= digitsToDisplay - @as(i16, @intCast(maxI(0, numDigits)))) : ({
            digitPointer += 1;
            digitCount -= 1;
        }) {
            if (!firstDigitAfterPeriod and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT())))))) - 1) {
                const sr = SEPARATOR_RIGHT();
                const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
                _ = xcopy(displayString + charIndex, sr, n);
                charIndex +%= @intCast(n);
            } else {
                firstDigitAfterPeriod = false;
            }
            displayString[charIndex] = '0';
            charIndex += 1;
            if (updateDisplayValueX != 0) {
                displayValueX[valueIndex] = '0';
                valueIndex += 1;
            }
        }

        displayString[charIndex] = 0;
        if (updateDisplayValueX != 0) {
            displayValueX[valueIndex] = 0;
        }

        if (exponent != 0) {
            if (displayFormat != DF_UN) {
                if (updateDisplayValueX != 0) {
                    exponentToDisplayString(exponent, displayString + charIndex, @as([*c]u8, &displayValueX) + valueIndex, 0);
                } else {
                    exponentToDisplayString(exponent, displayString + charIndex, null, 0);
                }
            } else {
                exponentToUnitDisplayString(exponent, @intFromBool(flag2To10), displayString + charIndex, @as([*c]u8, &displayValueX) + valueIndex, 0);
            }
        }
    }
    if (flag2To10 and displayFormat == DF_UN) {
        real34Copy(&real34bak, real34);
    }
}

// ===========================================================================
// complex34ToDisplayString / complex34ToDisplayString2 / strPrepend
// ===========================================================================
pub export fn complex34ToDisplayString(complex34: *align(1) const complex34_t, displayString: [*c]u8, font: *const font_t, maxWidth: i16, displayHasNDigits_in: i16, limitExponent: bool_t, frontSpace: bool_t, limitIrfrac: irfracOption_t, tagAngle: u16, tagPolar: bool_t) callconv(.c) void {
    var displayHasNDigits = displayHasNDigits_in;
    const savedDisplayFormatDigits = displayFormatDigits;
    const saveddisplayFormat = displayFormat;

    const digitWidth: i16 = stringWidth("0", font, 0, 0);

    if (updateDisplayValueX != 0) {
        displayValueX[0] = 0;
    }

    complex34ToDisplayString2(complex34, displayString, displayHasNDigits, limitExponent, frontSpace, tagAngle, tagPolar, limitIrfrac);
    var noFix: bool = false;
    var overflow: i16 = stringWidth(displayString, font, 1, 1) - maxWidth;
    while (overflow > 0) {
        const overflowDigits: i16 = @intCast(maxI(@divTrunc(@divTrunc(@as(i32, overflow), digitWidth), 4), 1));

        if (displayHasNDigits == 2) {
            break;
        }

        if (displayFormat == DF_ALL) {
            displayHasNDigits = @intCast(maxI(displayHasNDigits - overflowDigits, 2));
        } else {
            if (displayFormat == DF_FIX) {
                if (displayFormatDigits == 0 or noFix) {
                    noFix = true;
                    displayHasNDigits = @intCast(maxI(displayHasNDigits - overflowDigits, 2));
                    displayFormatDigits = @intCast(minI(displayHasNDigits - 1, savedDisplayFormatDigits));
                } else {
                    displayFormatDigits = @intCast(maxI(@as(i32, displayFormatDigits) - overflowDigits, 0));
                }
            } else {
                displayFormatDigits = @intCast(maxI(@as(i32, displayFormatDigits) - overflowDigits, 3));
                if (displayFormatDigits == 3) {
                    displayFormat = DF_ALL;
                }
            }
        }

        if (updateDisplayValueX != 0) {
            displayValueX[0] = 0;
        }

        complex34ToDisplayString2(complex34, displayString, displayHasNDigits, limitExponent, frontSpace, tagAngle, tagPolar, limitIrfrac);
        overflow = stringWidth(displayString, font, 1, 1) - maxWidth;
    }

    displayFormatDigits = savedDisplayFormatDigits;
    displayFormat = saveddisplayFormat;
}

pub export fn strPrepend(dest: [*c]u8, prefix: [*c]u8) callconv(.c) void {
    var ii: i16 = @intCast(stringByteLength(prefix));
    if (ii == 0 or ii > 20) {
        return;
    }
    while (ii > 0) {
        _ = strcat(dest, " ");
        ii -= 1;
    }
    var jj: i16 = @intCast(stringByteLength(dest) - 1);
    ii = @intCast(stringByteLength(prefix));
    while (jj - ii >= 0) {
        dest[@intCast(jj)] = dest[@intCast(jj - ii)];
        jj -= 1;
    }
    ii -= 1;
    while (ii >= 0) {
        dest[@intCast(ii)] = prefix[@intCast(ii)];
        ii -= 1;
    }
}

fn complex34ToDisplayString2(complex34: *align(1) const complex34_t, displayString: [*c]u8, displayHasNDigits: i16, limitExponent: bool_t, frontSpace: bool_t, tagAngle: u16, tagPolar: bool_t, limitIrfrac: irfracOption_t) void {
    const imagOffset: i16 = 100;
    var real34_: real34_t = undefined;
    var imag34: real34_t = undefined;
    var absimag34: real34_t = undefined;
    var real: real_t = undefined;
    var imagIc: real_t = undefined;

    if (tagPolar != 0) {
        real34ToReal(varReal34(complex34), &real);
        real34ToReal(varImag34(complex34), &imagIc);

        var c: realContext_t = ctxtReal39;
        const maxExponent: c_int = maxI(real.exponent + real.digits, imagIc.exponent + imagIc.digits);
        c.digits = if (showmode()) 39 else minI(75, maxI(0, maxExponent) + nbrDispRealCtxDigits() + 2);
        realRectangularToPolar(&real, &imagIc, &real, &imagIc, &c);
        c.digits = if (showmode()) 39 else 3 + nbrDispRealCtxDigits();
        convertAngleFromTo(&imagIc, amRadian, if (tagAngle == amNone) currentAngularMode else @intCast(tagAngle), &c);

        realToReal34(&real, &real34_);
        realToReal34(&imagIc, &imag34);
    } else {
        real34Copy(varReal34(complex34), &real34_);
        real34Copy(varImag34(complex34), &imag34);
    }

    real34ToDisplayString2(&real34_, displayString, displayHasNDigits, limitExponent, 0, frontSpace, isComplex, limitIrfrac);
    if (updateDisplayValueX != 0) {
        if (tagPolar != 0) {
            _ = strcat(&displayValueX, "j");
        } else {
            _ = strcat(&displayValueX, "i");
        }
    }

    real34ToDisplayString2(&imag34, displayString + @as(usize, @intCast(imagOffset)), displayHasNDigits, limitExponent, 0, @intFromBool(FRONTSPACE == 0), isComplex, limitIrfrac);

    if (!real34IsZero(&real34_) and strncmp(displayString + @as(usize, @intCast(imagOffset)), STD_ALMOST_EQUAL, 2) == 0) {
        displayString[@intCast(imagOffset)] = STD_NOCHAR;
        displayString[@intCast(imagOffset + 1)] = STD_NOCHAR;
        if (strncmp(displayString, STD_ALMOST_EQUAL, 2) != 0) {
            strPrepend(displayString, @constCast(STD_ALMOST_EQUAL));
        }
    }

    if (tagPolar != 0) {
        _ = strcat(displayString, STD_SPACE_4_PER_EM ++ STD_MEASURED_ANGLE ++ STD_SPACE_4_PER_EM);
        const kk: u16 = @intCast(stringByteLength(displayString));
        angle34ToDisplayString2(&imag34, @intCast(if (tagAngle == amNone) @as(angularMode_t, currentAngularMode) else @as(angularMode_t, @intCast(tagAngle))), displayString + kk, displayHasNDigits, limitExponent, 0, limitIrfrac);
        if (strncmp(displayString + kk, STD_ALMOST_EQUAL, 2) == 0) {
            displayString[kk] = STD_NOCHAR;
            displayString[kk + 1] = STD_NOCHAR;
        }
    } else {
        if (strncmp(displayString + @as(usize, @intCast(stringByteLength(displayString) - 2)), STD_SPACE_HAIR, 2) != 0) {
            _ = strcat(displayString, STD_SPACE_HAIR);
        }

        if (real34IsZero(&real34_) and !real34IsNegative(&real34_) and !real34IsZero(&imag34)) {
            displayString[0] = 0;
        } else {
            var iidx: i16 = imagOffset;
            var imagNegative: bool = false;
            while (iidx < imagOffset + @as(i16, @intCast(minI(4, stringByteLength(displayString + @as(usize, @intCast(imagOffset))))))) {
                if (displayString[@intCast(iidx)] >= '0' and displayString[@intCast(iidx)] <= '9') {
                    break;
                }
                if (displayString[@intCast(iidx)] == '-') {
                    displayString[@intCast(iidx)] = STD_NOCHAR;
                    _ = strcat(displayString, "-");
                    imagNegative = true;
                    break;
                }
                iidx = imagOffset + stringNextGlyph(displayString + @as(usize, @intCast(imagOffset)), iidx - imagOffset);
            }

            if (!imagNegative) {
                _ = strcat(displayString, "+");
            }
        }

        if (getSystemFlag(FLAG_CPXMULT) != 0) {
            _ = strcat(displayString, complexUnit());
            real34CopyAbs(&imag34, &absimag34);
            _ = strcat(displayString, productSign());
            _ = xcopy(strchr(displayString, 0), displayString + @as(usize, @intCast(imagOffset)), @intCast(strlen(displayString + @as(usize, @intCast(imagOffset))) + 1));
        }

        if (getSystemFlag(FLAG_CPXMULT) == 0) {
            real34CopyAbs(&imag34, &absimag34);
            _ = xcopy(strchr(displayString, 0), displayString + @as(usize, @intCast(imagOffset)), @intCast(strlen(displayString + @as(usize, @intCast(imagOffset))) + 1));
            _ = strcat(displayString, STD_SPACE_HAIR);
            _ = strcat(displayString, STD_SPACE_HAIR);
            _ = strcat(displayString, complexUnit());
        }
    }
}

// ===========================================================================
// _numerator / _denominator / fractionToDisplayString
// ===========================================================================
pub export fn _numerator(numer_in: u64, displayString: [*c]u8, endingZero: *i16) callconv(.c) void {
    var numer = numer_in;
    var u: i16 = undefined;
    var gap: i16 = -1;
    const insertAt: i16 = endingZero.*;
    while (true) {
        gap += 1;
        if (gap == GROUPWIDTH_LEFT()) {
            gap = 0;
            endingZero.* += 1;
            _ = xcopy(displayString + @as(usize, @intCast(insertAt + 2)), displayString + @as(usize, @intCast(insertAt)), @intCast(endingZero.* - insertAt));
            endingZero.* += 1;
            const sf = SEPARATOR_FRAC();
            displayString[@intCast(insertAt)] = sf[0];
            displayString[@intCast(insertAt + 1)] = sf[1];
        }

        u = @intCast(numer % 10);
        numer /= 10;
        endingZero.* += 1;
        _ = xcopy(displayString + @as(usize, @intCast(insertAt + 2)), displayString + @as(usize, @intCast(insertAt)), @intCast(endingZero.* - insertAt));
        endingZero.* += 1;

        displayString[@intCast(insertAt)] = STD_SUP_0[0];
        displayString[@intCast(insertAt + 1)] = STD_SUP_0[1];
        displayString[@intCast(insertAt + 1)] +%= @intCast(u);
        if (numer == 0) break;
    }
}

pub export fn _denominator(denom_in: u64, displayString: [*c]u8, endingZero: *i16) callconv(.c) void {
    var denom = denom_in;
    var u: i16 = undefined;
    var gap: i16 = -1;
    const insertAt: i16 = endingZero.*;
    while (true) {
        gap += 1;
        if (gap == GROUPWIDTH_LEFT()) {
            gap = 0;
            endingZero.* += 1;
            _ = xcopy(displayString + @as(usize, @intCast(insertAt + 2)), displayString + @as(usize, @intCast(insertAt)), @intCast(endingZero.* - insertAt));
            endingZero.* += 1;
            const sf = SEPARATOR_FRAC();
            displayString[@intCast(insertAt)] = sf[0];
            displayString[@intCast(insertAt + 1)] = sf[1];
        }

        u = @intCast(denom % 10);
        denom /= 10;
        endingZero.* += 1;
        _ = xcopy(displayString + @as(usize, @intCast(insertAt + 2)), displayString + @as(usize, @intCast(insertAt)), @intCast(endingZero.* - insertAt));
        endingZero.* += 1;
        displayString[@intCast(insertAt)] = STD_SUB_0[0];
        displayString[@intCast(insertAt + 1)] = STD_SUB_0[1];
        displayString[@intCast(insertAt + 1)] +%= @intCast(u);
        if (denom == 0) break;
    }
}

pub export fn fractionToDisplayString(regist: calcRegister_t, displayString: [*c]u8) callconv(.c) void {
    var sign: i16 = undefined;
    var lessEqualGreater: i16 = undefined;
    var intPart: u64 = undefined;
    var numer: u64 = undefined;
    var denom: u64 = undefined;
    var u: i16 = undefined;
    var insertAt: i16 = undefined;
    var endingZero: i16 = undefined;
    var gap: i16 = undefined;

    const prependFraction: bool = fraction(regist, &sign, &intPart, &numer, &denom, &lessEqualGreater) != 0;

    if (getSystemFlag(FLAG_FRCSRN) != 0) {
        const xyzt = "xyzt";
        if (lessEqualGreater == -1) {
            abi.fmtCStr(displayString, "{c}" ++ STD_SPACE_PUNCTUATION ++ ">" ++ STD_SPACE_PUNCTUATION, .{ @as(u8, @intCast(@as(c_int, xyzt[@intCast(regist - REGISTER_X)]))) });
        } else if (lessEqualGreater == 0) {
            abi.fmtCStr(displayString, "{c}" ++ STD_SPACE_PUNCTUATION ++ "=" ++ STD_SPACE_PUNCTUATION, .{ @as(u8, @intCast(@as(c_int, xyzt[@intCast(regist - REGISTER_X)]))) });
        } else if (lessEqualGreater == 1) {
            abi.fmtCStr(displayString, "{c}" ++ STD_SPACE_PUNCTUATION ++ "<" ++ STD_SPACE_PUNCTUATION, .{ @as(u8, @intCast(@as(c_int, xyzt[@intCast(regist - REGISTER_X)]))) });
        } else {
            _ = strcpy(displayString, "?" ++ STD_SPACE_PUNCTUATION);
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "fractionToDisplayString", @as(c_int, lessEqualGreater), "lessEqualGreater" });
            displayBugScreen(errorMessage);
        }
    } else if (prependFraction) {
        if (lessEqualGreater == -1) {
            abi.fmtCStr(displayString, ">" ++ STD_SPACE_PUNCTUATION, .{});
        } else if (lessEqualGreater == 0) {
            displayString[0] = 0;
        } else if (lessEqualGreater == 1) {
            abi.fmtCStr(displayString, "<" ++ STD_SPACE_PUNCTUATION, .{});
        } else {
            _ = strcpy(displayString, "?" ++ STD_SPACE_PUNCTUATION);
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "fractionToDisplayString", @as(c_int, lessEqualGreater), "lessEqualGreater" });
            displayBugScreen(errorMessage);
        }
    } else {
        displayString[0] = 0;
    }

    endingZero = @intCast(strlen(displayString));

    if (getSystemFlag(FLAG_PROPFR) != 0 and intPart != 0) {
        if (updateDisplayValueX != 0) {
            abi.fmtBufZ(&displayValueX, "{s}{d} {d}/{d}", .{ std.mem.span(@as([*:0]const u8, if (sign == -1) "-" else "")), @as(u32, @intCast(intPart)), @as(u32, @intCast(numer)), @as(u32, @intCast(denom)) });
        }

        if (sign == -1) {
            _ = strcat(displayString, "-");
            endingZero += 1;
        }

        insertAt = endingZero;
        gap = -1;
        while (true) {
            gap += 1;
            if (gap == GROUPWIDTH_LEFT()) {
                gap = 0;
                endingZero += 1;
                _ = xcopy(displayString + @as(usize, @intCast(insertAt + 2)), displayString + @as(usize, @intCast(insertAt)), @intCast(endingZero - insertAt));
                endingZero += 1;
                const sl = SEPARATOR_LEFT();
                displayString[@intCast(insertAt)] = sl[0];
                displayString[@intCast(insertAt + 1)] = sl[1];
            }

            u = @intCast(intPart % 10);
            intPart /= 10;
            endingZero += 1;
            _ = xcopy(displayString + @as(usize, @intCast(insertAt + 1)), displayString + @as(usize, @intCast(insertAt)), @intCast(endingZero - insertAt));
            displayString[@intCast(insertAt)] = '0' + @as(u8, @intCast(u));
            if (intPart == 0) break;
        }

        _ = strcat(displayString, STD_SPACE_PUNCTUATION);
        endingZero += 2;
    } else {
        if (updateDisplayValueX != 0) {
            abi.fmtBufZ(&displayValueX, "{s}{d}/{d}", .{ std.mem.span(@as([*:0]const u8, if (sign == -1) "-" else "")), @as(u32, @intCast(numer)), @as(u32, @intCast(denom)) });
        }

        if (sign == -1) {
            _ = strcat(displayString, STD_SUP_MINUS);
            endingZero += 2;
        }
    }

    _numerator(numer, displayString, &endingZero);

    _ = strcat(displayString, "/");
    endingZero += 1;

    _denominator(denom, displayString, &endingZero);
}

// ===========================================================================
// addBaseNumber / longIntegerToHexDisplayString / shortIntegerToDisplayString
// ===========================================================================
pub export fn addBaseNumber(displayString: [*c]u8, base: i16) callconv(.c) void {
    if (base <= 16) {
        _ = strcat(displayString, STD_BASE_2);
        displayString[strlen(displayString) - 1] +%= @intCast(base - 2);
    } else {
        _ = strcat(displayString, STD_SUB_0);
        displayString[strlen(displayString) - 1] +%= @intCast(@divTrunc(base, 10));
        _ = strcat(displayString, STD_SUB_0);
        displayString[strlen(displayString) - 1] +%= @intCast(@rem(base, 10));
    }
}

pub export fn longIntegerToHexDisplayString(regist: calcRegister_t, displayString: [*c]u8, determineFont: bool_t, baseOverride: u8, width: i32) callconv(.c) void {
    _ = determineFont;
    _ = baseOverride;
    var i: u16 = @intCast(TMP_STR_LENGTH / 2);
    displayString[0] = 0;
    if (dispBase < 2) {
        return;
    }

    var lgInt: longInteger_t = undefined;
    var sign: bool = undefined;
    var digit: i32 = undefined;

    convertLongIntegerRegisterToLongInteger(regist, &lgInt[0]);

    if (longIntegerIsZero(&lgInt)) {
        displayString[0] = '0';
        displayString[1] = 0;
        addBaseNumber(displayString, @intCast(dispBase));
        longIntegerFree(&lgInt);
        fontForShortInteger = &numericFont;
        return;
    }

    sign = lgInt[0]._mp_size < 0;

    while (!longIntegerIsZero(&lgInt)) {
        digit = @intCast(longIntegerModuloUInt(&lgInt, @intCast(dispBase)));
        longIntegerDivideUInt(&lgInt, @intCast(dispBase), &lgInt);
        displayString[i] = baseDigits[@intCast(digit)];
        i += 1;
    }

    longIntegerFree(&lgInt);

    if (sign) {
        displayString[i] = '-';
        i += 1;
    }

    {
        var k: u16 = i - 1;
        var j: u16 = 0;
        while (k >= TMP_STR_LENGTH / 2) : ({
            k -%= 1;
            j += 1;
        }) {
            displayString[j] = displayString[k];
            displayString[j + 1] = 0;
        }
    }

    const lastTinyCharIfTooLong: usize = 256;
    if (stringWidth(displayString, &numericFont, 0, 1) +
        stringWidth(STD_SUB_0 ++ STD_SUB_0, &numericFont, 0, 1) +
        stringWidth("  X:" ++ STD_INTEGER_Z_SMALL ++ ": ", &standardFont, 0, 1) <= width)
    {
        fontForShortInteger = &numericFont;
        addBaseNumber(displayString, @intCast(dispBase));
    } else if (stringWidth(displayString, &standardFont, 0, 1) + stringWidth(STD_SUB_0 ++ STD_SUB_0, &standardFont, 0, 1) + stringWidth("  X:" ++ STD_INTEGER_Z_SMALL ++ ": ", &standardFont, 0, 1) <= width) {
        fontForShortInteger = &standardFont;
        addBaseNumber(displayString, @intCast(dispBase));
    } else {
        fontForShortInteger = &tinyFont;
        if (stringWidth(displayString, &tinyFont, 1, 1) +
            stringWidth(STD_SUB_0 ++ STD_SUB_0, &tinyFont, 1, 1) >= width * 4)
        {
            displayString[lastTinyCharIfTooLong + 0] = STD_ELLIPSIS[0];
            displayString[lastTinyCharIfTooLong + 1] = STD_ELLIPSIS[1];
            displayString[lastTinyCharIfTooLong + 2] = 0;
        }
        addBaseNumber(displayString, @intCast(dispBase));
    }
}

pub export fn shortIntegerToDisplayString(regist: calcRegister_t, displayString: [*c]u8, determineFont: bool_t, baseOverride: u8) callconv(.c) void {
    var i: i16 = undefined;
    var j: i16 = undefined;
    var k: i16 = undefined;
    var unit: i16 = undefined;
    var gap: i16 = undefined;
    var digit: i16 = undefined;
    var bitsPerDigit: i16 = undefined;
    var maxDigits: i16 = undefined;
    var base: i16 = undefined;
    var number: u64 = undefined;
    var sign: u64 = undefined;

    number = regShortInteger(regist).*;
    const orgnumber: u64 = number;

    var bcdFlag: bool = false;
    if (baseOverride == 1) {
        base = 10;
        bcdFlag = true;
    } else if (baseOverride == 0) {
        base = @intCast(getRegisterTag(regist));
        if (base <= 1 or base >= 17) {
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "shortIntegerToDisplayString", @as(c_int, base), "base" });
            displayBugScreen(errorMessage);
            base = 10;
        }
    } else {
        base = baseOverride;
    }

    if (shortIntegerMode == SIM_UNSIGN or base == 2 or base == 4 or base == 8 or base == 16) {
        sign = 0;
    } else {
        sign = number & shortIntegerSignBit;
    }

    if (sign != 0) {
        if (shortIntegerMode == SIM_2COMPL) {
            number |= ~shortIntegerMask;
            number = ~number +% 1;
        } else if (shortIntegerMode == SIM_1COMPL) {
            number = ~number;
        } else if (shortIntegerMode == SIM_SIGNMT) {
            number &= ~shortIntegerSignBit;
        } else {
            abi.fmtBufZ(errorMessage[0..512], "In function {s}:{d} is an unexpected value for {s}!", .{ "shortIntegerToDisplayString", @as(c_int, shortIntegerMode), "shortIntegerMode" });
            displayBugScreen(errorMessage);
        }
        number &= shortIntegerMask;
    }

    i = ERROR_MESSAGE_LENGTH / 2;

    if (number == 0) {
        if (base == 10 and bcdFlag) {
            var ss: [5]u8 = undefined;
            if (bcdDisplaySign == BCD9c) {
                _ = strcpy(displayString + @as(usize, @intCast(i)), "1001");
                _ = strcpy(&ss, STD_BASE_9);
            } else if (bcdDisplaySign == BCD10c) {
                _ = strcpy(displayString + @as(usize, @intCast(i)), "0000");
                _ = strcpy(&ss, STD_SUB_o);
            } else {
                _ = strcpy(displayString + @as(usize, @intCast(i)), "0000");
                _ = strcpy(&ss, STD_SUB_o);
            }
            i += 4;
            digit = 1;
            displayString[@intCast(i)] = ss[1];
            i += 1;
            displayString[@intCast(i)] = ss[0];
            i += 1;
        } else {
            displayString[@intCast(i)] = '0';
            i += 1;
            digit = 1;
        }
    } else {
        digit = 0;
    }

    if (GROUPLEFT_DISABLED()) {
        gap = 0;
    } else {
        if (base == 2) {
            gap = 4;
        } else if (base == 4 or base == 16) {
            gap = 2;
        } else if (base == 8) {
            gap = 3;
        } else if (base == 10 and bcdFlag) {
            gap = 1;
        } else if (base <= 16) {
            gap = 3;
        } else {
            gap = 4;
        }
    }

    var firstNonZero: u8 = 0;
    while (number != 0) {
        if (gap != 0 and digit != 0 and @rem(digit, gap) == 0) {
            displayString[@intCast(i)] = ' ';
            i += 1;
        }
        digit += 1;

        unit = @intCast(number % @as(u64, @intCast(base)));
        number /= @intCast(base);
        if (unit != 0) {
            firstNonZero += 1;
        }

        if (bcdFlag and base == 10) {
            if (bcdDisplaySign == BCD9c) {
                unit = 9 - unit;
            } else if (bcdDisplaySign == BCD10c) {
                if (firstNonZero == 0) {
                    unit = 0;
                } else if (firstNonZero == 1) {
                    unit = 9 - unit + 1;
                    firstNonZero += 1;
                } else {
                    unit = 9 - unit;
                    firstNonZero += 1;
                }
            }

            displayString[@intCast(i)] = '0' + @as(u8, @intCast(unit & 0x0001));
            i += 1;
            displayString[@intCast(i)] = '0' + @as(u8, @intCast((unit & 0x0002) >> 1));
            i += 1;
            displayString[@intCast(i)] = '0' + @as(u8, @intCast((unit & 0x0004) >> 2));
            i += 1;
            displayString[@intCast(i)] = '0' + @as(u8, @intCast((unit & 0x0008) >> 3));
            i += 1;

            if ((orgnumber & 0x0FFFFFFFFFFFFFFF) <= 99999999999) {
                var ss: [5]u8 = undefined;
                if (unit == 0) {
                    _ = strcpy(&ss, STD_SUB_o);
                    displayString[@intCast(i)] = ss[1];
                    i += 1;
                    displayString[@intCast(i)] = ss[0];
                    i += 1;
                } else {
                    _ = strcpy(&ss, STD_BASE_1);
                    displayString[@intCast(i)] = ss[1] +% @as(u8, @intCast(unit)) -% 1;
                    i += 1;
                    displayString[@intCast(i)] = ss[0];
                    i += 1;
                }
            }
        } else {
            displayString[@intCast(i)] = baseDigits[@intCast(unit)];
            i += 1;
        }
    }

    if (getSystemFlag(FLAG_LEAD0) != 0) {
        if (base == 2) {
            bitsPerDigit = 1;
        } else if (base == 4) {
            bitsPerDigit = 2;
        } else if (base == 8) {
            bitsPerDigit = 3;
        } else if (base == 16) {
            bitsPerDigit = 4;
        } else {
            bitsPerDigit = 0;
        }

        if (bitsPerDigit != 0) {
            maxDigits = @divTrunc(@as(i16, shortIntegerWordSize), bitsPerDigit);
            if (@rem(@as(i16, shortIntegerWordSize), bitsPerDigit) != 0) {
                maxDigits += 1;
            }
            while (digit < maxDigits) {
                if (gap != 0 and @rem(digit, gap) == 0) {
                    displayString[@intCast(i)] = ' ';
                    i += 1;
                }
                digit += 1;
                displayString[@intCast(i)] = '0';
                i += 1;
            }
        }
    }

    if (sign != 0) {
        displayString[@intCast(i)] = '-';
        i += 1;
    }

    const SUB_bcd = STD_SUB_b ++ STD_SUB_c ++ STD_SUB_d;

    if (determineFont != 0) {
        // 1st try numeric font 30..39
        fontForShortInteger = &numericFont;
        k = i - 1;
        j = 0;
        while (k >= ERROR_MESSAGE_LENGTH / 2) : ({
            k -= 1;
            j += 1;
        }) {
            if (displayString[@intCast(k)] == ' ') {
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
                j += 1;
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
            } else {
                displayString[@intCast(j)] = displayString[@intCast(k)];
            }
        }
        displayString[@intCast(j)] = 0;
        if (bcdFlag and base == 10) {
            _ = strcat(displayString, SUB_bcd);
        } else {
            addBaseNumber(displayString, base);
        }
        if (stringWidth(displayString, fontForShortInteger.?, 0, 0) < SCREEN_WIDTH) {
            return;
        }

        // 2nd try numeric font NUM_0_b range
        k = i - 1;
        j = 0;
        while (k >= ERROR_MESSAGE_LENGTH / 2) : ({
            k -= 1;
            j += 1;
        }) {
            if (displayString[@intCast(k)] == ' ') {
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
                j += 1;
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
            } else if (0x30 <= displayString[@intCast(k)] and displayString[@intCast(k)] <= 0x39) {
                displayString[@intCast(j)] = NUM_0_b[0];
                j += 1;
                displayString[@intCast(j)] = NUM_0_b[1] -% '0' +% displayString[@intCast(k)];
            } else {
                displayString[@intCast(j)] = displayString[@intCast(k)];
            }
        }
        displayString[@intCast(j)] = 0;
        if (bcdFlag and base == 10) {
            _ = strcat(displayString, SUB_bcd);
        } else {
            addBaseNumber(displayString, base);
        }
        if (stringWidth(displayString, fontForShortInteger.?, 0, 0) < SCREEN_WIDTH) {
            return;
        }

        // 3rd try standard font 30..39
        fontForShortInteger = &standardFont;
        k = i - 1;
        j = 0;
        while (k >= ERROR_MESSAGE_LENGTH / 2) : ({
            k -= 1;
            j += 1;
        }) {
            if (displayString[@intCast(k)] == ' ') {
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
                j += 1;
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
            } else {
                displayString[@intCast(j)] = displayString[@intCast(k)];
            }
        }
        displayString[@intCast(j)] = 0;
        if (bcdFlag and base == 10) {
            _ = strcat(displayString, SUB_bcd);
        } else {
            addBaseNumber(displayString, base);
        }
        if (stringWidth(displayString, fontForShortInteger.?, 0, 0) < SCREEN_WIDTH) {
            return;
        }

        // 4th try standard font binary glyphs
        k = i - 1;
        j = 0;
        while (k >= ERROR_MESSAGE_LENGTH / 2) : ({
            k -= 1;
            j += 1;
        }) {
            if (displayString[@intCast(k)] == ' ') {
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
                j += 1;
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
            } else if (displayString[@intCast(k)] == '0') {
                displayString[@intCast(j)] = STD_BINARY_ZERO[0];
                j += 1;
                displayString[@intCast(j)] = STD_BINARY_ZERO[1];
            } else if (displayString[@intCast(k)] == '1') {
                displayString[@intCast(j)] = STD_BINARY_ONE[0];
                j += 1;
                displayString[@intCast(j)] = STD_BINARY_ONE[1];
            } else {
                displayString[@intCast(j)] = displayString[@intCast(k)];
            }
        }
        displayString[@intCast(j)] = 0;
        if (bcdFlag and base == 10) {
            _ = strcat(displayString, SUB_bcd);
        } else {
            addBaseNumber(displayString, base);
        }
        if (stringWidth(displayString, fontForShortInteger.?, 0, 0) < SCREEN_WIDTH) {
            return;
        }

        moreInfoOnErr("In function shortIntegerToDisplayString: the integer data representation is too wide (1)!", displayString, null);
        _ = strcpy(displayString, "Integer data representation too wide!");
    } else {
        fontForShortInteger = &standardFont;

        k = i - 1;
        j = 0;
        while (k >= ERROR_MESSAGE_LENGTH / 2) : ({
            k -= 1;
            j += 1;
        }) {
            if (displayString[@intCast(k)] == ' ') {
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
                j += 1;
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
            } else {
                displayString[@intCast(j)] = displayString[@intCast(k)];
            }
        }
        displayString[@intCast(j)] = 0;
        if (bcdFlag and base == 10) {
            _ = strcat(displayString, SUB_bcd);
        } else {
            addBaseNumber(displayString, base);
        }
        if (stringWidth(displayString, fontForShortInteger.?, 0, 0) < SCREEN_WIDTH) {
            return;
        }

        k = i - 1;
        j = 0;
        while (k >= ERROR_MESSAGE_LENGTH / 2) : ({
            k -= 1;
            j += 1;
        }) {
            if (displayString[@intCast(k)] == ' ') {
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[0];
                j += 1;
                displayString[@intCast(j)] = STD_SPACE_PUNCTUATION[1];
            } else if (displayString[@intCast(k)] == '0') {
                displayString[@intCast(j)] = STD_BINARY_ZERO[0];
                j += 1;
                displayString[@intCast(j)] = STD_BINARY_ZERO[1];
            } else if (displayString[@intCast(k)] == '1') {
                displayString[@intCast(j)] = STD_BINARY_ONE[0];
                j += 1;
                displayString[@intCast(j)] = STD_BINARY_ONE[1];
            } else {
                displayString[@intCast(j)] = displayString[@intCast(k)];
            }
        }
        displayString[@intCast(j)] = 0;
        if (bcdFlag and base == 10) {
            _ = strcat(displayString, SUB_bcd);
        } else {
            addBaseNumber(displayString, base);
        }
        if (stringWidth(displayString, fontForShortInteger.?, 0, 0) < SCREEN_WIDTH) {
            return;
        }

        moreInfoOnErr("In function shortIntegerToDisplayString: the integer data representation is too wide (2)!", displayString, null);
        _ = strcpy(displayString, "Integer data representation to wide!");
    }
}

// ===========================================================================
// long-integer register helpers + insertSepsIntoIntegerText + display strings
// ===========================================================================
pub export fn longIntegerRegisterToDisplayString(regist: calcRegister_t, displayString: [*c]u8, strLg: i32, max_Width: i16, maxExp: i16, allowLARGELI: bool_t) callconv(.c) void {
    var lgInt: longInteger_t = undefined;
    convertLongIntegerRegisterToLongInteger(regist, &lgInt[0]);
    longIntegerToDisplayString(&lgInt[0], displayString, strLg, max_Width, maxExp, allowLARGELI);
    longIntegerFree(&lgInt);
}

// emitSciDigits: the DF_SCI body lifted out (matches the inlined SCI path in
// real34ToDisplayString2), fed from a digit-per-byte bcd[] (MSD first) so a long
// real can supply up to digitsToDisplay digits. (display.c emitSciDigits)
fn emitSciDigits(bcd: [*c]u8, firstDigit_in: i16, lastDigit: i16, numDigits_in: i16, exponent_in: i32, sign: bool_t, digitToRound_in: i16, digitsToDisplay: i16, frontSpace: bool_t, displayString: [*c]u8) void {
    _ = lastDigit;
    var charIndex: i32 = 0;
    var valueIndex: i32 = 0;
    var digitCount: i16 = undefined;
    var digitPointer: i16 = undefined;
    var firstDigitAfterPeriod: bool = true;

    var firstDigit = firstDigit_in;
    var numDigits = numDigits_in;
    var exponent = exponent_in;
    var digitToRound = digitToRound_in;

    // Round the displayed number
    if (bcd[@intCast(digitToRound + 1)] >= 5) {
        bcd[@intCast(digitToRound)] += 1;
    }
    // Transfer the carry
    while (bcd[@intCast(digitToRound)] == 10) {
        bcd[@intCast(digitToRound)] = 0;
        digitToRound -= 1;
        numDigits -= 1;
        bcd[@intCast(digitToRound)] += 1;
    }
    // Case when 9.9999 rounds to 10.0000
    if (digitToRound < firstDigit) {
        firstDigit -= 1;
        numDigits = 1;
        exponent += 1;
    }
    // Sign
    if (sign != 0) {
        displayString[@intCast(charIndex)] = '-';
        charIndex += 1;
        if (updateDisplayValueX != 0) {
            displayValueX[@intCast(valueIndex)] = '-';
            valueIndex += 1;
        }
    } else {
        if (frontSpace != 0) {
            displayString[@intCast(charIndex)] = ' ';
            charIndex += 1;
        }
    }
    // First digit
    displayString[@intCast(charIndex)] = '0' + bcd[@intCast(firstDigit)];
    charIndex += 1;
    if (updateDisplayValueX != 0) {
        displayValueX[@intCast(valueIndex)] = '0' + bcd[@intCast(firstDigit)];
        valueIndex += 1;
    }
    // Radix mark
    displayString[@intCast(charIndex)] = 0;
    var tt: [4]u8 = undefined;
    radixTT(&tt);
    _ = strcat(displayString, &tt);
    charIndex +%= @intCast(strlen(&tt));
    if (updateDisplayValueX != 0) {
        displayValueX[@intCast(valueIndex)] = '.';
        valueIndex += 1;
    }
    // Significant digits
    digitCount = -1;
    digitPointer = firstDigit + 1;
    while (digitPointer < firstDigit + @as(i16, @intCast(minI(numDigits, digitsToDisplay + 1)))) : ({
        digitPointer += 1;
        digitCount -= 1;
    }) {
        if (!firstDigitAfterPeriod and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT())))))) - 1) {
            const sr = SEPARATOR_RIGHT();
            const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
            _ = xcopy(displayString + @as(usize, @intCast(charIndex)), sr, n);
            charIndex +%= @intCast(n);
        } else {
            firstDigitAfterPeriod = false;
        }
        displayString[@intCast(charIndex)] = '0' + bcd[@intCast(digitPointer)];
        charIndex += 1;
        if (updateDisplayValueX != 0) {
            displayValueX[@intCast(valueIndex)] = '0' + bcd[@intCast(digitPointer)];
            valueIndex += 1;
        }
    }
    // The ending zeros
    digitPointer = 0;
    while (digitPointer <= digitsToDisplay - numDigits) : ({
        digitPointer += 1;
        digitCount -= 1;
    }) {
        if (!firstDigitAfterPeriod and !GROUPRIGHT_DISABLED() and modulo(digitCount, @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT()))))))) == @as(i32, @intCast(@as(u16, @bitCast(@as(i16, @intCast(GROUPWIDTH_RIGHT())))))) - 1) {
            const sr = SEPARATOR_RIGHT();
            const n: u32 = if (sr[0] != 1) (if (sr[1] != 1) 2 else 1) else 0;
            _ = xcopy(displayString + @as(usize, @intCast(charIndex)), sr, n);
            charIndex +%= @intCast(n);
        } else {
            firstDigitAfterPeriod = false;
        }
        displayString[@intCast(charIndex)] = '0';
        charIndex += 1;
        if (updateDisplayValueX != 0) {
            displayValueX[@intCast(valueIndex)] = '0';
            valueIndex += 1;
        }
    }
    displayString[@intCast(charIndex)] = 0;
    if (updateDisplayValueX != 0) {
        displayValueX[@intCast(valueIndex)] = 0;
    }
    // Append the ten exponent
    if (exponent != 0) {
        if (updateDisplayValueX != 0) {
            exponentToDisplayString(exponent, displayString + @as(usize, @intCast(charIndex)), @as([*c]u8, &displayValueX) + @as(usize, @intCast(valueIndex)), 0);
        } else {
            exponentToDisplayString(exponent, displayString + @as(usize, @intCast(charIndex)), null, 0);
        }
    }
}

// realSCIToDisplayString renders work in SCI form into displayString via
// emitSciDigits, showing digitsToDisplay digits after the radix.
// bcd points to caller-supplied scratch (>= maxDigits bytes). (display.c)
fn realSCIToDisplayString(work: *const real_t, displayString: [*c]u8, digitsToDisplay_in: i16, frontSpace: bool_t, bcd: [*c]u8, maxDigits: i16) void {
    var numDigits: i16 = undefined;
    var digitPointer: i16 = undefined;
    var firstDigit: i16 = undefined;
    var lastDigit: i16 = undefined;
    var digitToRound: i16 = undefined;
    var exponent: i16 = undefined;
    var sign: i32 = undefined;
    var digitsToDisplay = digitsToDisplay_in;

    _ = memset(bcd, 0, @intCast(maxDigits));

    sign = @intFromBool(realIsNegative(work));
    exponent = @intCast(work.exponent);
    _ = decNumberGetBCD(work, bcd + 1);

    digitPointer = 1;
    while (digitPointer <= @as(i16, @intCast(work.digits))) : (digitPointer += 1) {
        if (bcd[@intCast(digitPointer)] != 0) {
            break;
        }
    }

    if (digitPointer > @as(i16, @intCast(work.digits))) { // value is 0.0
        firstDigit = 0;
        lastDigit = 0;
        numDigits = 1;
        exponent = 0;
    } else {
        firstDigit = digitPointer;
        // Fold trailing zeros into the exponent.
        digitPointer = @intCast(work.digits);
        while (digitPointer >= 1) : (digitPointer -= 1) {
            if (bcd[@intCast(digitPointer)] == 0) {
                exponent += 1;
            } else {
                break;
            }
        }
        lastDigit = digitPointer;
        numDigits = lastDigit - firstDigit;
        exponent += numDigits;
        numDigits += 1; // exponent is now the power of the MSD, numDigits the inclusive count
    }

    digitsToDisplay = @intCast(minI(digitsToDisplay, numDigits - 1)); // no trailing zeros

    digitToRound = @intCast(minI(firstDigit + digitsToDisplay, lastDigit));

    emitSciDigits(bcd, firstDigit, lastDigit, numDigits, exponent, @intCast(sign), digitToRound, digitsToDisplay, frontSpace, displayString);
}

pub export fn longIntegerRegisterToRealDisplayString(regist: calcRegister_t, displayString: [*c]u8, strLg: i32, maxWidth: i16, minimum: i32, removeTrailingRadix: bool_t) callconv(.c) void {
    var lgInt: longInteger_t = undefined;
    convertLongIntegerRegisterToLongInteger(regist, &lgInt[0]);
    longIntegerToAllocatedString(&lgInt[0], displayString, strLg);
    longIntegerFree(&lgInt);
    var tmp4: real_t = undefined;
    var tmpReal: real_t = undefined;
    stringToReal(displayString, &tmpReal, &ctxtReal75);
    int32ToReal(minimum, &tmp4);
    if (minimum == 0 or !(realCompareAbsLessThan(&tmpReal, &tmp4) != 0)) {
        const font = if (getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont;
        // The long path is only for the wide-LI caller, which selects DF_ALL and
        // sets displayFormatDigits above DSP_MAX. Every other caller (capped at
        // DSP_MAX) and every other format uses the old real34 delegation.
        if (displayFormat == DF_ALL and displayFormatDigits > DSP_MAX) {
            const regDispMaxDigits: i16 = 48; // buffer ceiling for shown digits
            var bcdScratch: [100]u8 = undefined;
            var c: realContext_t = ctxtReal75;
            c.digits = regDispMaxDigits;
            realPlus(&tmpReal, &tmpReal, &c);
            var digitsToDisplay: i16 = regDispMaxDigits - 1; // fill the width
            while (true) {
                realSCIToDisplayString(&tmpReal, displayString, digitsToDisplay, @intFromBool(FRONTSPACE == 0), @as([*c]u8, &bcdScratch), @intCast(bcdScratch.len));
                if (digitsToDisplay == 0) {
                    break;
                }
                digitsToDisplay -= 1;
                if (!(stringWidth(displayString, font, 1, 1) > maxWidth)) break;
            }
        } else {
            var tmpReal34: real34_t = undefined;
            realToReal34(&tmpReal, &tmpReal34);
            real34ToDisplayString(&tmpReal34, amNone, displayString, font, maxWidth, 34, LIMITEXP, @intFromBool(FRONTSPACE == 0), NOIRFRAC);
        }

        if (removeTrailingRadix != 0) {
            const lastGlyphPosition = stringLastGlyph(displayString);
            const radix = RADIX34_MARK_STRING();
            if (displayString[@intCast(lastGlyphPosition)] == radix[0] and (displayString[@intCast(lastGlyphPosition + 1)] == radix[1] or radix[1] == 1)) {
                displayString[@intCast(lastGlyphPosition)] = 0;
            }
        }
    }
}

fn insertSepsIntoIntegerText(displayString: [*c]u8) void {
    if (!GROUPLEFT_DISABLED() and GROUPWIDTH_LEFT1() > 0) {
        var len: i16 = @intCast(strlen(displayString));
        const digitOne: i16 = if (displayString[0] == '-') 1 else 0;
        var Grp1: i16 = if (GROUPWIDTH_LEFT1X() > 0 and (@as(i32, displayString[@intCast(digitOne)]) - 48 <= GROUPWIDTH_LEFT1X()) and (len - digitOne == @as(i16, @intCast(GROUPWIDTH_LEFT1())) + 1)) @as(i16, @intCast(GROUPWIDTH_LEFT1())) + 1 else @as(i16, @intCast(GROUPWIDTH_LEFT1()));
        Grp1 = if (len >= (if (checkHP()) @as(i16, 10) else 20)) @as(i16, @intCast(GROUPWIDTH_LEFT())) else Grp1;
        var ii: i16 = len - Grp1;
        if (ii > 0 and (ii != 1 or displayString[0] != '-')) {
            const sl = SEPARATOR_LEFT();
            if (sl[1] != 1) {
                _ = xcopy(displayString + @as(usize, @intCast(ii + 2)), displayString + @as(usize, @intCast(ii)), @intCast(len - ii + 1));
                displayString[@intCast(ii)] = sl[0];
                displayString[@intCast(ii + 1)] = sl[1];
            } else if (sl[0] != 1) {
                _ = xcopy(displayString + @as(usize, @intCast(ii + 1)), displayString + @as(usize, @intCast(ii)), @intCast(len - ii + 1));
                displayString[@intCast(ii)] = sl[0];
            }

            len = @intCast(strlen(displayString));
            ii = len - @as(i16, @intCast(GROUPWIDTH_LEFT())) - (Grp1 + (if (sl[1] == 1) @as(i16, 1) else 2));
            while (ii > 0) : (ii -= @intCast(GROUPWIDTH_LEFT())) {
                if (ii != 1 or displayString[0] != '-') {
                    if (sl[1] != 1) {
                        _ = xcopy(displayString + @as(usize, @intCast(ii + 2)), displayString + @as(usize, @intCast(ii)), @intCast(len - ii + 1));
                        displayString[@intCast(ii)] = sl[0];
                        displayString[@intCast(ii + 1)] = sl[1];
                        len += 2;
                    } else if (sl[0] != 1) {
                        _ = xcopy(displayString + @as(usize, @intCast(ii + 1)), displayString + @as(usize, @intCast(ii)), @intCast(len - ii + 1));
                        displayString[@intCast(ii)] = sl[0];
                        len += 1;
                    }
                }
            }
        }
    }
}

pub export fn longIntegerToDisplayString(lgInt: [*c]mpz_struct, displayString: [*c]u8, strLg: i32, max_Width: i16, maxExp: i16, allowLARGELI: bool_t) callconv(.c) void {
    var exponentStep: i16 = undefined;
    var exponentStep1: i16 = undefined;
    var exponentShift: u32 = undefined;
    var exponentShiftLimit: u32 = undefined;
    var maxWidth: i16 = undefined;

    const lg: *longInteger_t = @ptrCast(lgInt);
    if (longIntegerIsNegative(lg)) {
        maxWidth = max_Width;
    } else {
        maxWidth = max_Width - 8;
    }

    const sl = SEPARATOR_LEFT();
    exponentShift = @intFromFloat(@as(f64, @floatFromInt(longIntegerBits(lg) - 1)) * 0.3010299956639811952137);
    exponentStep = if (GROUPWIDTH_LEFT() == 0 or (sl[0] == 1 and sl[1] == 1)) 1 else @intCast(GROUPWIDTH_LEFT());
    exponentStep1 = if (sl[0] == 1 and sl[1] == 1) 1 else @intCast(GROUPWIDTH_LEFT1());

    exponentShift = (exponentShift / @as(u32, @intCast(exponentStep)) + 1) * @as(u32, @intCast(exponentStep));
    exponentShiftLimit = (@as(u32, @bitCast(@as(i32, maxExp - exponentStep1))) / @as(u32, @intCast(exponentStep)) + 1) * @as(u32, @intCast(exponentStep));
    if (exponentShift > exponentShiftLimit) {
        exponentShift -= exponentShiftLimit;
        var ix: i32 = @intCast(exponentShift);
        while (ix >= 1) : (ix -= 1) {
            if (ix >= 9) {
                longIntegerDivideUInt(lg, 1000000000, lg);
                ix -= 8;
            } else if (ix >= 4) {
                longIntegerDivideUInt(lg, 10000, lg);
                ix -= 3;
            } else {
                longIntegerDivideUInt(lg, 10, lg);
            }
        }
    } else {
        exponentShift = 0;
    }

    longIntegerToAllocatedString(lgInt, displayString, strLg);

    if (updateDisplayValueX != 0) {
        _ = strcpy(&displayValueX, displayString);
    }

    insertSepsIntoIntegerText(displayString);

    if (stringWidth(displayString, if (allowLARGELI != 0 and getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, 0, 0) > maxWidth) {
        var exponentString: [14]u8 = undefined;
        var lastRemovedDigit: u8 = undefined;
        var lastChar: i16 = undefined;
        var stringStep: i16 = undefined;
        var tenExponent: i16 = undefined;

        stringStep = if (GROUPLEFT_DISABLED()) 1 else @as(i16, @intCast(GROUPWIDTH_LEFT())) + (if (sl[1] == 1) @as(i16, 1) else 2);
        tenExponent = exponentStep + @as(i16, @intCast(exponentShift));
        lastChar = @as(i16, @intCast(strlen(displayString))) - stringStep;
        lastRemovedDigit = displayString[@intCast(lastChar + (if (sl[1] == 1) @as(i16, 1) else 2))];
        displayString[@intCast(lastChar)] = 0;
        if (updateDisplayValueX != 0) {
            displayValueX[@intCast(@as(i32, @intCast(strlen(&displayValueX))) - maxI(GROUPWIDTH_LEFT(), 1))] = 0;
        }
        exponentString[0] = 0;
        exponentToDisplayString(tenExponent, &exponentString, null, 0);
        while (stringWidth(displayString, if (allowLARGELI != 0 and getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, 0, 1) + stringWidth(&exponentString, if (allowLARGELI != 0 and getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, 1, 0) > maxWidth) {
            lastChar -= stringStep;
            tenExponent += exponentStep;
            lastRemovedDigit = displayString[@intCast(lastChar + (if (sl[1] == 1) @as(i16, 1) else 2))];
            displayString[@intCast(lastChar)] = 0;
            if (updateDisplayValueX != 0) {
                displayValueX[@intCast(@as(i32, @intCast(strlen(&displayValueX))) - maxI(GROUPWIDTH_LEFT(), 1))] = 0;
            }
            exponentString[0] = 0;
            exponentToDisplayString(tenExponent, &exponentString, null, 0);
        }

        if (lastRemovedDigit >= '5') {
            lastChar = @intCast(strlen(displayString) - 1);
            displayString[@intCast(lastChar)] += 1;
            while (displayString[@intCast(lastChar)] > '9') {
                displayString[@intCast(lastChar)] = '0';
                lastChar -= 1;
                while (lastChar >= 0 and (displayString[@intCast(lastChar)] < '0' or displayString[@intCast(lastChar)] > '9')) {
                    lastChar -= 1;
                }
                if (lastChar >= 0) {
                    displayString[@intCast(lastChar)] += 1;
                } else {
                    lastChar = if (displayString[0] == '-') 1 else 0;
                    _ = xcopy(displayString + @as(usize, @intCast(lastChar + 1)), displayString + @as(usize, @intCast(lastChar)), @intCast(strlen(displayString) + 1));
                    displayString[@intCast(lastChar)] = '1';
                    if (sl[1] != 1) {
                        if (!GROUPLEFT_DISABLED() and displayString[@intCast(lastChar + @as(i16, @intCast(GROUPWIDTH_LEFT())) + 2)] == sl[1]) {
                            _ = xcopy(displayString + @as(usize, @intCast(lastChar + 3)), displayString + @as(usize, @intCast(lastChar + 1)), @intCast(strlen(displayString)));
                            displayString[@intCast(lastChar + 1)] = sl[0];
                            displayString[@intCast(lastChar + 2)] = sl[1];
                        }
                    } else if (sl[0] != 1) {
                        if (!GROUPLEFT_DISABLED() and displayString[@intCast(lastChar + @as(i16, @intCast(GROUPWIDTH_LEFT())) + 1)] == sl[0]) {
                            _ = xcopy(displayString + @as(usize, @intCast(lastChar + 2)), displayString + @as(usize, @intCast(lastChar + 1)), @intCast(strlen(displayString)));
                            displayString[@intCast(lastChar + 1)] = sl[0];
                        }
                    }

                    if (stringWidth(displayString, if (allowLARGELI != 0 and getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, 0, 1) + stringWidth(&exponentString, if (allowLARGELI != 0 and getSystemFlag(FLAG_LARGELI) != 0) &numericFont else &standardFont, 1, 0) > maxWidth) {
                        lastChar = @as(i16, @intCast(strlen(displayString))) - stringStep;
                        tenExponent += exponentStep;
                        displayString[@intCast(lastChar)] = 0;
                        if (updateDisplayValueX != 0) {
                            displayValueX[@intCast(@as(i32, @intCast(strlen(&displayValueX))) - maxI(GROUPWIDTH_LEFT(), 1))] = 0;
                        }
                        exponentString[0] = 0;
                        exponentToDisplayString(tenExponent, &exponentString, null, 0);
                    }
                }
            }

            if (updateDisplayValueX != 0) {
                lastChar = @intCast(strlen(&displayValueX) - 1);
                displayValueX[@intCast(lastChar)] += 1;
                while (lastChar > 0 and '0' <= displayValueX[@intCast(lastChar - 1)] and displayValueX[@intCast(lastChar - 1)] <= '9' and displayValueX[@intCast(lastChar)] > '9') {
                    displayValueX[@intCast(lastChar)] = '0';
                    lastChar -= 1;
                    displayValueX[@intCast(lastChar)] += 1;
                }
                if (displayValueX[@intCast(lastChar)] > '9') {
                    _ = xcopy(@as([*c]u8, &displayValueX) + 1, &displayValueX, @intCast(strlen(&displayValueX) + 1));
                    displayValueX[@intCast(lastChar)] = '1';
                    lastChar += 1;
                    displayValueX[@intCast(lastChar)] = '0';
                }
            }
        }

        _ = strcat(displayString, &exponentString);

        if (updateDisplayValueX != 0) {
            abi.fmtCStr(@as([*c]u8, &displayValueX) + strlen(&displayValueX), "e{d}", .{ @as(c_int, tenExponent) });
        }
    }
}

pub export fn longIntegerToAllocatedString(lgInt: [*c]const mpz_struct, str: [*c]u8, strLen: i32) callconv(.c) void {
    var numberOfDigits: i32 = undefined;
    var stringLen: i32 = undefined;
    var counter: i32 = undefined;
    var x: longInteger_t = undefined;

    str[0] = '0';
    str[1] = 0;
    if (lgInt[0]._mp_size == 0) {
        return;
    }

    numberOfDigits = @intCast(__gmpz_sizeinbase(lgInt, 10));
    if (lgInt[0]._mp_size < 0) {
        stringLen = numberOfDigits + 2;
        str[0] = '-';
    } else {
        stringLen = numberOfDigits + 1;
    }

    if (strLen < stringLen) {
        abi.fmtBufZ(errorMessage[0..512], "In function longIntegerToAllocatedString: the string str ({d} bytes) is too small to hold the base 10 representation of lgInt, {d} are needed!", .{ strLen, stringLen });
        displayBugScreen(errorMessage);
        return;
    }

    str[@intCast(stringLen - 1)] = 0;

    __gmpz_init2(&x[0], @intCast(__gmpz_sizeinbase(lgInt, 2)));
    __gmpz_add_ui(&x[0], lgInt, 0);
    x[0]._mp_size = if (x[0]._mp_size < 0) -x[0]._mp_size else x[0]._mp_size;

    stringLen -= 2;
    counter = numberOfDigits;
    while (x[0]._mp_size != 0) {
        str[@intCast(stringLen)] = '0' + @as(u8, @intCast(__gmpz_tdiv_ui(&x[0], 10)));
        stringLen -= 1;
        _ = __gmpz_tdiv_q_ui(&x[0], &x[0], 10);
        counter -= 1;
    }

    if (counter == 1) {
        _ = xcopy(str + @as(usize, @intCast(stringLen)), str + @as(usize, @intCast(stringLen + 1)), @intCast(numberOfDigits));
    }

    __gmpz_clear(&x[0]);
}

// ===========================================================================
// dateToDisplayString / timeToDisplayString
// ===========================================================================
const FLAG_TDM24_v: c_int = FLAG_TDM24;
const FLAG_DMY_v: c_int = FLAG_DMY;
const FLAG_MDY_v: c_int = FLAG_MDY;

pub export fn dateToDisplayString(regist: calcRegister_t, displayString: [*c]u8) callconv(.c) void {
    var j: real34_t = undefined;
    var y: real34_t = undefined;
    var yy: real34_t = undefined;
    var m: real34_t = undefined;
    var d: real34_t = undefined;
    var yearval64: u64 = undefined;
    var sign: [2]u8 = .{ 0, 0 };

    internalDateToJulianDay(reg34(regist), &j);
    decomposeJulianDay(&j, &y, &m, &d);
    if (real34IsNegative(&y)) {
        sign[0] = '-';
    }
    real34CopyAbs(&y, &y);
    real34CopyAbs(&y, &yy);
    real34DivideRemainder(&y, const34_2p32, &y);
    real34Divide(&yy, const34_2p32, &yy);
    real34ToIntegralValue(&yy, &yy, DEC_ROUND_DOWN);
    yearval64 = (@as(u64, real34ToUInt32(&yy)) << 32) | @as(u64, real34ToUInt32(&y));

    if (getSystemFlag(FLAG_DMY_v) != 0) {
        abi.fmtCStr(displayString, "{d:0>2}.{d:0>2}.{s}{d:0>4}", .{ real34ToUInt32(&d), real34ToUInt32(&m), @as([*:0]const u8, @as([*c]const u8, &sign)), @as(u32, @intCast(yearval64)) });
    } else if (getSystemFlag(FLAG_MDY_v) != 0) {
        abi.fmtCStr(displayString, "{d:0>2}/{d:0>2}/{s}{d:0>4}", .{ real34ToUInt32(&m), real34ToUInt32(&d), @as([*:0]const u8, @as([*c]const u8, &sign)), @as(u32, @intCast(yearval64)) });
    } else {
        abi.fmtCStr(displayString, "{s}{d:0>4}-{d:0>2}-{d:0>2}", .{ @as([*:0]const u8, @as([*c]const u8, &sign)), @as(u32, @intCast(yearval64)), real34ToUInt32(&m), real34ToUInt32(&d) });
    }
}

pub export fn timeToDisplayString(regist: calcRegister_t, displayString: [*c]u8, ignoreTDisp: bool_t) callconv(.c) void {
    var real: real_t = undefined;
    var value: real_t = undefined;
    var tmp: real_t = undefined;
    var h: real_t = undefined;
    var m: real_t = undefined;
    var s: real_t = undefined;
    var hli: longInteger_t = undefined;
    var sign: i32 = undefined;
    var i: i32 = undefined;
    var digits: u32 = undefined;
    var tDigits: u32 = 0;
    var bDigits: u32 = undefined;
    var m32: u32 = undefined;
    var s32: u32 = undefined;
    var digitBuf: [16]u8 = undefined;
    var digitBuf2: [48]u8 = undefined;
    var bufPtr: [*c]u8 = undefined;
    var isValid12hTime: bool = false;
    var isAfternoon: bool = false;
    const savedDisplayFormat = displayFormat;
    const savedDisplayFormatDigits = displayFormatDigits;

    real34ToReal(reg34(regist), &real);
    sign = @intFromBool(realIsNegative(&real));

    if (timeDisplayFormatDigits == 0) {
        realDivide(const_1, const_1000, &value, &ctxtReal39);
    } else if ((timeDisplayFormatDigits == 1) or (timeDisplayFormatDigits == 2)) {
        realCopy(const_60, &value);
    } else {
        realSetOne(&value);
        i = 3;
        while (i < timeDisplayFormatDigits) : (i += 1) {
            value.exponent -= 1;
            if (i == 5) break;
        }
    }
    if (realCompareAbsLessThan(&real, const_1) != 0) {
        realSetOne(&tmp);
        tmp.exponent -= 33;
        realDivideRemainder(&real, &tmp, &tmp, &ctxtReal39);
    } else {
        realSetZero(&tmp);
    }
    if (realCompareAbsLessThan(&real, &value) != 0 or (ignoreTDisp != 0 and !realIsZeroB(&tmp))) {
        if (ignoreTDisp != 0 or (timeDisplayFormatDigits == 0)) {
            displayFormat = DF_ALL;
            displayFormatDigits = 0;
        } else {
            displayFormat = if (getSystemFlag(FLAG_ENGOVR) != 0) DF_ENG else DF_SCI;
            displayFormatDigits = 3;
        }
        real34ToDisplayString(reg34(regist), amSecond, displayString, &standardFont, 2000, if (ignoreTDisp != 0) 34 else 16, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC);
        displayFormatDigits = savedDisplayFormatDigits;
        displayFormat = savedDisplayFormat;
        return;
    }
    displayFormatDigits = savedDisplayFormatDigits;
    displayFormat = savedDisplayFormat;

    realDivide(&real, const_3600, &h, &ctxtReal39);
    realSetPositiveSign(&h);
    realToIntegralValue(&h, &h, DEC_ROUND_DOWN, &ctxtReal39);

    if (ignoreTDisp == 0) {
        switch (timeDisplayFormatDigits) {
            0 => {
                blk0: {
                    isValid12hTime = (sign == 0) and (getSystemFlag(FLAG_TDM24_v) == 0) and (realCompareLessThan(&real, const_86400) != 0);
                    if (realCompareAbsLessThan(&h, const_100) != 0) {
                        bDigits = 0;
                    } else {
                        bDigits = @intCast(16 - 2 * @as(i32, @intFromBool(isValid12hTime)));
                    }
                    tDigits = @intCast(15 - 2 * @as(i32, @intFromBool(isValid12hTime)));
                    isValid12hTime = false;
                    // do_rounding
                    digits = bDigits;
                    while (digits < tDigits) : (digits += 1) {
                        real.exponent += 1;
                    }
                    realToIntegralValue(&real, &real, if (timeDisplayFormatDigits == 0) DEC_ROUND_HALF_UP else DEC_ROUND_DOWN, &ctxtReal39);
                    digits = bDigits;
                    while (digits < tDigits) : (digits += 1) {
                        real.exponent -= 1;
                    }
                    tDigits = 0;
                    break :blk0;
                }
            },
            1, 2 => {
                realDivide(&real, const_60, &real, &ctxtReal39);
                realToIntegralValue(&real, &real, DEC_ROUND_DOWN, &ctxtReal39);
                realMultiply(&real, const_60, &real, &ctxtReal39);
            },
            else => {
                tDigits = @as(u32, timeDisplayFormatDigits) + 1;
                bDigits = 4;
                // do_rounding
                digits = bDigits;
                while (digits < tDigits) : (digits += 1) {
                    real.exponent += 1;
                }
                realToIntegralValue(&real, &real, if (timeDisplayFormatDigits == 0) DEC_ROUND_HALF_UP else DEC_ROUND_DOWN, &ctxtReal39);
                digits = bDigits;
                while (digits < tDigits) : (digits += 1) {
                    real.exponent -= 1;
                }
                tDigits = 0;
            },
        }
    }
    realSetPositiveSign(&real);

    realToIntegralValue(&real, &s, DEC_ROUND_DOWN, &ctxtReal39);
    realSubtract(&real, &s, &real, &ctxtReal39);
    realDivide(&s, const_60, &m, &ctxtReal39);
    realToIntegralValue(&m, &m, DEC_ROUND_DOWN, &ctxtReal39);
    realDivideRemainder(&s, const_60, &s, &ctxtReal39);
    realDivideRemainder(&m, const_60, &m, &ctxtReal39);

    if ((getSystemFlag(FLAG_TDM24_v) == 0) and (sign == 0)) {
        if (realCompareLessThan(&h, const_24) != 0) {
            isValid12hTime = true;
            if (realCompareGreaterEqual(&h, const_12) != 0) {
                isAfternoon = true;
                if (!(realCompareLessEqual(&h, const_12) != 0)) {
                    realSubtract(&h, const_12, &h, &ctxtReal39);
                }
            } else if (realIsZeroB(&h)) {
                realAdd(&h, const_12, &h, &ctxtReal39);
            }
        }
    }

    _ = strcpy(displayString, if (sign != 0) "-" else " ");
    longIntegerInit(&hli);
    convertRealToLongInteger(&h, &hli[0], DEC_ROUND_DOWN);
    longIntegerToAllocatedString(&hli[0], &digitBuf2, @intCast(@sizeOf(@TypeOf(digitBuf2))));
    longIntegerFree(&hli);

    bufPtr = &digitBuf2;
    digitBuf[1] = 0;
    digits = @intCast(strlen(&digitBuf2));
    while (digits > 0) : (digits -= 1) {
        digitBuf[0] = bufPtr[0];
        bufPtr += 1;
        _ = strcat(displayString, &digitBuf);
        if ((@rem(digits, @as(u32, @intCast(GROUPWIDTH_LEFT()))) == 1) and (digits > 1)) {
            var tt: [4]u8 = undefined;
            tt[0] = 0;
            const sl = SEPARATOR_LEFT();
            if (sl[1] != 1) {
                _ = strcpy(&tt, sl);
            } else if (sl[0] != 1) {
                tt[0] = sl[0];
                tt[1] = 0;
            }
            _ = strcat(displayString, &tt);
        }
        tDigits += 1;
    }

    tDigits += 1;
    if ((ignoreTDisp == 0) and (timeDisplayFormatDigits == 1 or timeDisplayFormatDigits == 2 or (tDigits) > (if (isValid12hTime) @as(u32, 16) else 18))) {
        m32 = realToUint32C47(&m, null);
        abi.fmtBufZ(&digitBuf, ":{d:0>2}", .{m32});
        _ = strcat(displayString, &digitBuf);
    } else {
        m32 = realToUint32C47(&m, null);
        s32 = realToUint32C47(&s, null);
        abi.fmtBufZ(&digitBuf, ":{d:0>2}:{d:0>2}", .{ m32, s32 });
        _ = strcat(displayString, &digitBuf);

        digits = 0;
        realSetZero(&value);
        while (true) {
            realSubtract(&real, &value, &real, &ctxtReal39);
            if (ignoreTDisp != 0 or (timeDisplayFormatDigits == 0)) {
                if (realIsZeroB(&real)) break;
            } else {
                if (digits + 4 > timeDisplayFormatDigits) break;
            }
            if ((ignoreTDisp == 0)) {
                tDigits += 1;
                if (tDigits > (if (isValid12hTime) @as(u32, 16) else 18)) break;
            }
            real.exponent += 1;
            realToIntegralValue(&real, &value, DEC_ROUND_DOWN, &ctxtReal39);

            if (digits == 0) {
                var tt: [4]u8 = undefined;
                const radix = RADIX34_MARK_STRING();
                if (radix[1] != 1) {
                    _ = strcpy(&tt, radix);
                } else {
                    tt[0] = radix[0];
                    tt[1] = 0;
                }
                _ = strcat(displayString, &tt);
            } else if (@rem(digits, @as(u32, @intCast(GROUPWIDTH_RIGHT()))) == 0) {
                var tt: [4]u8 = undefined;
                tt[0] = 0;
                const sr = SEPARATOR_RIGHT();
                if (sr[1] != 1) {
                    _ = strcpy(&tt, sr);
                } else if (sr[0] != 1) {
                    tt[0] = sr[0];
                    tt[1] = 0;
                }
                _ = strcat(displayString, &tt);
            }

            s32 = realToUint32C47(&value, null);
            abi.fmtBufZ(&digitBuf, "{d}", .{s32});
            _ = strcat(displayString, &digitBuf);
            digits += 1;
        }
    }

    if (isAfternoon) {
        _ = strcat(displayString, "p.m.");
    } else if (isValid12hTime) {
        _ = strcat(displayString, "a.m.");
    }
}

// ===========================================================================
// matrix / vector display strings + mimShowElement
// ===========================================================================
const STD_COMPLEX_C = "\xa1\x02";

// OPTION_VECTOR register-vector helpers (only referenced under option_vector).
inline fn isRegisterMatrix2dVector(reg: calcRegister_t) bool {
    if (getRegisterDataType(reg) != dtReal34Matrix) return false;
    const h = regMatrixHeader(reg);
    const r = h.matrixRows;
    const c = h.matrixColumns;
    return (r == 1 and c == 2) or (r == 2 and c == 1);
}
inline fn isRegisterMatrix3dVector(reg: calcRegister_t) bool {
    if (getRegisterDataType(reg) != dtReal34Matrix) return false;
    const h = regMatrixHeader(reg);
    const r = h.matrixRows;
    const c = h.matrixColumns;
    return (r == 1 and c == 3) or (r == 3 and c == 1);
}
inline fn getVectorRegisterPolarMode(reg: calcRegister_t) u32 {
    if (getRegisterDataType(reg) == dtReal34Matrix and (getRegisterTag(reg) & amAngleMask) != amNone) {
        if (isRegisterMatrix3dVector(reg)) {
            return if ((getRegisterTag(reg) & amPolar) == amPolar) amPolarSPH else amPolarCYL;
        } else if (isRegisterMatrix2dVector(reg)) {
            return getRegisterTag(reg) & amPolar;
        } else {
            return 0;
        }
    }
    return 0;
}

pub export fn real34MatrixToDisplayString(regist: calcRegister_t, displayString: [*c]u8) callconv(.c) void {
    if (comptime option_vector) {
        if (isRegisterMatrix2dVector(regist)) {
            abi.fmtCStr(displayString, "[2D Vector]{s}", .{ @as([*:0]const u8, @as([*c]const u8, if (getVectorRegisterPolarMode(regist) == amPolar) STD_SPACE_HAIR ++ STD_SUP_p else "")) });
            return;
        } else if (isRegisterMatrix3dVector(regist)) {
            abi.fmtCStr(displayString, "[3D Vector]{s}", .{ @as([*:0]const u8, @as([*c]const u8, if (getVectorRegisterPolarMode(regist) == amPolarSPH) STD_SPACE_HAIR ++ STD_SUP_s else if (getVectorRegisterPolarMode(regist) == amPolarCYL) STD_SPACE_HAIR ++ STD_SUP_c else "")) });
            return;
        }
    }
    const matrixHeader = regMatrixHeader(regist);
    abi.fmtCStr(displayString, "[{d}" ++ STD_CROSS ++ "{d} Matrix]", .{ @as(c_uint, matrixHeader.matrixRows), @as(c_uint, matrixHeader.matrixColumns) });
}

pub export fn complex34MatrixToDisplayString(regist: calcRegister_t, displayString: [*c]u8) callconv(.c) void {
    const matrixHeader = regMatrixHeader(regist);
    abi.fmtCStr(displayString, "[{d}" ++ STD_CROSS ++ "{d} " ++ STD_COMPLEX_C ++ " Matrix]", .{ @as(c_uint, matrixHeader.matrixRows), @as(c_uint, matrixHeader.matrixColumns) });
}

pub export fn vectorToDisplayString(regist: calcRegister_t, displayString: [*c]u8) callconv(.c) bool_t {
    if (getRegisterDataType(regist) == dtReal34Matrix) {
        const matrixHeader = regMatrixHeader(regist);
        const r = matrixHeader.matrixRows;
        const c = matrixHeader.matrixColumns;
        if ((r == 1 and c == 3) or (r == 3 and c == 1) or (r == 1 and c == 2) or (r == 2 and c == 1)) {
            var matrix: real34Matrix_t = undefined;
            linkToRealMatrixRegister(regist, &matrix);
            showRealMatrix(&matrix, 0, @intFromBool(toDisplayVectorMatrix == 0), regXp);
            abi.fmtCStr(displayString, "{s}", .{ @as([*:0]const u8, errorMessage) });
            return 1;
        }
    }
    return 0;
}

fn _complex34ToShowTmpString(r: *align(1) const real34_t, im: *align(1) const real34_t) void {
    var last: i16 = undefined;
    var real34_: real34_t = undefined;

    real34ToDisplayString(r, amNone, tmpString, &standardFont, 2000, 34, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC);

    real34Copy(im, &real34_);
    last = SHOWLineSize;
    while (tmpString[@intCast(last)] != 0) {
        last += 1;
    }
    _ = xcopy(tmpString + @as(usize, @intCast(last)), if (real34IsNegative(&real34_)) @as([*c]const u8, "-") else "+", 1);
    last += 1;
    _ = xcopy(tmpString + @as(usize, @intCast(last)), complexUnit(), 2);
    last += 1;
    _ = xcopy(tmpString + @as(usize, @intCast(last)), productSign(), 3);

    real34SetPositiveSign(&real34_);
    real34ToDisplayString(&real34_, amNone, tmpString + @as(usize, @intCast(2 * SHOWLineSize)), &standardFont, 2000, 34, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC);

    if (stringWidth(tmpString + @as(usize, @intCast(SHOWLineSize)), &standardFont, 1, 1) + stringWidth(tmpString + @as(usize, @intCast(2 * SHOWLineSize)), &standardFont, 1, 1) <= SCREEN_WIDTH) {
        last = SHOWLineSize;
        while (tmpString[@intCast(last)] != 0) {
            last += 1;
        }
        _ = xcopy(tmpString + @as(usize, @intCast(last)), tmpString + @as(usize, @intCast(2 * SHOWLineSize)), @intCast(strlen(tmpString + @as(usize, @intCast(2 * SHOWLineSize))) + 1));
        tmpString[@intCast(2 * SHOWLineSize)] = 0;
    }

    if (stringWidth(tmpString, &standardFont, 1, 1) + stringWidth(tmpString + @as(usize, @intCast(SHOWLineSize)), &standardFont, 1, 1) <= SCREEN_WIDTH) {
        last = 0;
        while (tmpString[@intCast(last)] != 0) {
            last += 1;
        }
        _ = xcopy(tmpString + @as(usize, @intCast(last)), tmpString + @as(usize, @intCast(SHOWLineSize)), @intCast(strlen(tmpString + @as(usize, @intCast(SHOWLineSize))) + 1));
        _ = xcopy(tmpString + @as(usize, @intCast(SHOWLineSize)), tmpString + @as(usize, @intCast(2 * SHOWLineSize)), @intCast(strlen(tmpString + @as(usize, @intCast(2 * SHOWLineSize))) + 1));
        tmpString[@intCast(2 * SHOWLineSize)] = 0;
    }
}

pub export fn mimShowElement() callconv(.c) void {
    const savedDisplayFormat = displayFormat;
    const savedDisplayFormatDigits = displayFormatDigits;

    const i: i16 = getIRegisterAsInt(1);
    const j: i16 = getJRegisterAsInt(1);

    displayFormat = DF_ALL;
    displayFormatDigits = 0;

    var ix: u8 = 0;
    while (ix <= SHOWLineMax) : (ix += 1) {
        tmpString[@as(usize, ix) * @as(usize, @intCast(SHOWLineSize))] = 0;
    }

    temporaryInformation = TI_SHOW_REGISTER;

    const cols = openMatrixMIMPointer.realMatrix.header.matrixColumns;
    const elemIdx: usize = @intCast(@as(i32, i) * @as(i32, cols) + @as(i32, j));
    if (getRegisterDataType(@intCast(matrixIndex)) == dtReal34Matrix) {
        const elems: [*]align(1) real34_t = @ptrCast(openMatrixMIMPointer.realMatrix.matrixElements);
        real34ToDisplayString(&elems[elemIdx], amNone, tmpString, &standardFont, 2000, 34, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC);
    } else {
        const celems: [*]align(1) complex34_t = @ptrCast(openMatrixMIMPointer.complexMatrix.matrixElements);
        _complex34ToShowTmpString(varReal34(&celems[elemIdx]), varImag34(&celems[elemIdx]));
    }

    displayFormat = savedDisplayFormat;
    displayFormatDigits = savedDisplayFormatDigits;
}

// ===========================================================================
// SHOW machinery (#if !SAVE_SPACE_DM42_9 is LIVE on every z47 target)
// ===========================================================================
extern fn menu(n: u8) i16;

inline fn isXFNregisterValid3r(r: calcRegister_t) bool {
    if (!(getRegisterDataType(r) == dtReal34 or getRegisterDataType(r) == dtLongInteger)) return false;
    if (!(getRegisterDataType(r + 1) == dtReal34 or getRegisterDataType(r + 1) == dtLongInteger)) return false;
    if (!(getRegisterDataType(r + 2) == dtReal34 or getRegisterDataType(r + 2) == dtLongInteger)) return false;
    // inputAngleError3r(r) = !registerIsNoAngle(r+1) || !registerIsNoAngle(r+2)
    if (!registerIsNoAngle(r + 1) or !registerIsNoAngle(r + 2)) return false;
    return true;
}
inline fn registerIsNoAngle(r: calcRegister_t) bool {
    return (getRegisterDataType(r) == dtReal34 and getRegisterAngularMode(r) == amNone) or getRegisterDataType(r) == dtLongInteger;
}
inline fn isXFNShowing(r: calcRegister_t) bool {
    return menu(0) == -MNU_SHOW and menu(1) == -MNU_XXFCNS and isXFNregisterValid3r(r);
}

fn RegName() void {
    var tmp: i16 = undefined;
    viewRegName2(tmpString + 2100, &tmp);
}

fn SHOW_reset() void {
    var ix: u8 = 0;
    while (ix <= SHOWLineMax) : (ix += 1) {
        tmpString[@as(usize, ix) * @as(usize, @intCast(SHOWLineSize))] = 0;
    }
    temporaryInformation = TI_SHOW_REGISTER_SMALL;
    RegName();
}

fn checkAndEat(source_p: *i16, last: i16, dest: *i16) void {
    var ix: u8 = 0;
    if (source_p.* < last and !GROUPLEFT_DISABLED()) {
        while (ix < 16) : (ix += 1) {
            if (tmpString[@intCast(dest.* - 2)] == STD_SPACE_PUNCTUATION[0] and tmpString[@intCast(dest.* - 1)] == STD_SPACE_PUNCTUATION[1]) break;
            if (tmpString[@intCast(dest.* - 1)] == 32) break;
            dest.* -= 1;
            source_p.* -= 1;
        }
        tmpString[@intCast(dest.*)] = 0;
    }
}

fn printXSHOW(am: i16, d: i16, df: i16, dfd: i16, dt: i16, tagPolar: bool_t) void {
    displayFormat = @intCast(df);
    displayFormatDigits = @intCast(dfd);
    var last: i16 = undefined;
    var src: i16 = undefined;
    var dest: i16 = undefined;
    var ww: i16 = undefined;
    const sreg: calcRegister_t = @intCast(showRegis);
    RegName();
    ww = stringWidth(tmpString + 2100, &numericFont, 1, 1);

    if (dt == dtReal34) {
        var real34_: real34_t = undefined;
        real34Copy(reg34(sreg), &real34_);
        convertAngle34FromTo(&real34_, getRegisterAngularMode(sreg), @intCast(am));
        real34ToDisplayString(&real34_, @intCast(am), tmpString + 2100 + @as(usize, @intCast(stringByteLength(tmpString + 2100))), &numericFont, SCREEN_WIDTH - ww - 8 * 2, 34, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC);
    } else if (dt == dtComplex34) {
        complex34ToDisplayString(regComplex34(sreg), tmpString + 2100 + @as(usize, @intCast(stringByteLength(tmpString + 2100))), &numericFont, SCREEN_WIDTH - ww - 8 * 2, 34, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC, @intCast(getComplexRegisterAngularMode(sreg)), tagPolar);
    }

    if (stringWidth(tmpString + 2100, &numericFont, 1, 1) > SCREEN_WIDTH) {
        tmpString[2100] = 0;
    }

    last = 2100 + @as(i16, @intCast(stringByteLength(tmpString + 2100)));
    src = 2100;
    dest = d;
    while (src < last and stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1) <= SCREEN_WIDTH - 8 * 2) {
        tmpString[@intCast(dest)] = tmpString[@intCast(src)];
        if ((tmpString[@intCast(dest)] & 0x80) != 0) {
            dest += 1;
            src += 1;
            tmpString[@intCast(dest)] = tmpString[@intCast(src)];
        }
        src += 1;
        dest += 1;
        tmpString[@intCast(dest)] = 0;
    }
}

fn dispM(regist: u16, prefix: [*c]u8) void {
    var prefixWidth: u32 = 0;
    const baseY: i16 = 20;
    const prefixPre: bool_t = 0;
    const prefixPost: bool_t = 0;
    prefixWidth = @intCast(stringWidth(prefix, &standardFont, 1, 1));
    temporaryInformation = TI_SHOWNOTHING;
    if (getRegisterDataType(@intCast(regist)) == dtReal34Matrix) {
        var matrix: real34Matrix_t = undefined;
        linkToRealMatrixRegister(@intCast(regist), &matrix);
        showRealMatrix(&matrix, @intCast(prefixWidth), toDisplayVectorMatrix, @intFromBool(regXp == 0));
        if (lastErrorCode != 0) {
            refreshRegisterLine(errorMessageRegisterLine);
        }
        if (prefixWidth > 0) {
            _ = showString(prefix, &standardFont, 1, baseY, 0, prefixPre, prefixPost);
        }
        if (temporaryInformation == TI_INACCURATE and regist == REGISTER_X) {
            _ = showString("This result may be inaccurate", &standardFont, 1, @intCast(Y_POSITION_OF_ERR_LINE), 0, 1, 1);
        }
    } else if (getRegisterDataType(@intCast(regist)) == dtComplex34Matrix) {
        var matrix: complex34Matrix_t = undefined;
        linkToComplexMatrixRegister(@intCast(regist), &matrix);
        showComplexMatrix(&matrix, @intCast(prefixWidth), getComplexRegisterAngularMode(@intCast(regist)), @intFromBool(getComplexRegisterPolarMode(@intCast(regist)) == amPolar), @intFromBool(regXp == 0));
        if (lastErrorCode != 0) {
            refreshRegisterLine(errorMessageRegisterLine);
        }
        if (prefixWidth > 0) {
            _ = showString(prefix, &standardFont, 1, baseY, 0, prefixPre, prefixPost);
        }
        if (temporaryInformation == TI_INACCURATE and regist == REGISTER_X) {
            _ = showString("This result may be inaccurate", &standardFont, 1, @intCast(Y_POSITION_OF_ERR_LINE), 0, 1, 1);
        }
    }
}

fn prepLongintIntoLines(last: *i16, src: *i16, dest: *i16, fontToUse: *const font_t, maxWidth: i16, numberOfLines: i16, startingLine_p: *i16) void {
    // checktmpStringSep(SEP, a): previous 2 bytes != double-byte sep, prev byte
    // != single-byte sep, prev 2 bytes != STD_SPACE_FIGURE
    var SEP: [*c]const u8 = SEPARATOR_LEFT();
    var GRPWID: i8 = @intCast(GROUPWIDTH_LEFT());
    var GRP_DISABLED: bool = GROUPLEFT_DISABLED();

    if (strchr(errorMessage, '.') != null or strstr(errorMessage, RADIX34_MARK_STRING()) != null) {
        SEP = SEPARATOR_RIGHT();
        GRPWID = @intCast(GROUPWIDTH_RIGHT());
        GRP_DISABLED = GROUPRIGHT_DISABLED();
    }
    _ = stringWidth(SEP, fontToUse, 1, 1); // Width_0 (unused beyond allowedWidth below)
    const Width_0: i16 = stringWidth(SEP, fontToUse, 1, 1);

    var d: i16 = undefined;
    dest.* = 0;
    var sourceReturn: i16 = 0;
    d = 0;
    while (d <= numberOfLines * SHOWLineSize) : (d += SHOWLineSize) {
        tmpString[@intCast(d)] = 0;
    }
    d = startingLine_p.* * SHOWLineSize;
    while (d <= (startingLine_p.* + (numberOfLines - 1 + 1)) * SHOWLineSize) : (d += SHOWLineSize) {
        const dCounter: i16 = d - startingLine_p.* * SHOWLineSize;
        dest.* = dCounter;

        while ((src.* < last.*) and (dest.* < @as(i16, @intCast(TMP_STR_LENGTH)) - 6)) {
            tmpString[@intCast(dest.*)] = errorMessage[@intCast(src.*)];
            var bytesToAdd: i32 = 1;

            if ((tmpString[@intCast(dest.*)] & 0x80) != 0) {
                dest.* += 1;
                src.* += 1;
                tmpString[@intCast(dest.*)] = errorMessage[@intCast(src.*)];
                bytesToAdd = 2;
            }
            dest.* += 1;
            tmpString[@intCast(dest.*)] = 0;
            src.* += 1;

            const currentWidth: i16 = stringWidth(tmpString + @as(usize, @intCast(dCounter)), fontToUse, 1, 1);
            const allowedWidth: i16 = maxWidth - (if (dCounter == 0) @as(i16, 0) else Width_0);

            if (currentWidth >= allowedWidth) {
                dest.* -= @intCast(bytesToAdd);
                src.* -= @intCast(bytesToAdd);
                tmpString[@intCast(dest.*)] = 0;
                break;
            }
        }

        var cnt: u8 = @as(u8, @bitCast(GRPWID)) +% 1;
        while (true) {
            const c2 = cnt;
            cnt -%= 1;
            if (!(c2 != 0 and src.* < last.* and !GRP_DISABLED)) break;
            // checktmpStringSep(SEP, *dest)
            const a = dest.*;
            const isSep =
                (SEP[1] != 1 and tmpString[@intCast(a - 2)] == SEP[0] and tmpString[@intCast(a - 1)] == SEP[1]) or
                (SEP[1] == 1 and tmpString[@intCast(a - 1)] == SEP[0]) or
                (tmpString[@intCast(a - 2)] == STD_SPACE_FIGURE[0] and tmpString[@intCast(a - 1)] == STD_SPACE_FIGURE[1]);
            if (!isSep) {
                dest.* -= 1;
                src.* -= 1;
            } else {
                dest.* -= 1;
                src.* -= 1;
                if ((SEP[0] & 0x80) != 0 and SEP[1] != 1) {
                    dest.* -= 1;
                    src.* -= 1;
                }
                break;
            }
        }

        tmpString[@intCast(dest.*)] = 0;
        if (d == (startingLine_p.* + (numberOfLines - 1)) * SHOWLineSize) {
            sourceReturn = src.*;
        }
    }

    src.* = sourceReturn;
}

pub export fn realToSci(num: *const real_t, dispString: [*c]u8) callconv(.c) void {
    var p: [*c]u8 = undefined;
    const radix: [*c]const u8 = Rx();
    var sep: [*c]const u8 = SEPARATOR_RIGHT();
    var neg: c_int = undefined;
    var exp: c_int = undefined;
    var mi: c_int = 0;
    var ival: c_int = 1;
    var d: c_int = 0;
    const sepGroup: c_int = GROUPWIDTH_RIGHT();

    if (realGetExponent(num) > 672 or num.digits > 672) {
        sep = STD_SPACE_FIGURE;
    }

    exp = realGetExponent(num);
    realToString(num, dispString + 1500);
    if (realIsZeroB(num)) {
        abi.fmtCStr(dispString, "0{s}0", .{ @as([*:0]const u8, radix) });
        return;
    }

    neg = @intFromBool((dispString + 1500)[0] == '-');
    p = dispString + 1500 + @as(usize, @intCast(neg));

    while (p[0] != 0 and (p[0] < '0' or p[0] > '9')) {
        p += 1;
    }

    if (p[0] == '0' and (p + 1)[0] == '.') {
        p += 2;
        while (p[0] == '0') {
            p += 1;
        }
    }
    dispString[@intCast(mi)] = if (neg != 0) '-' else ' ';
    mi += 1;
    dispString[@intCast(mi)] = p[0];
    mi += 1;
    p += 1;
    if (p[0] == '.') {
        p += 1;
    }
    if (p[0] != 'E') {
        dispString[@intCast(mi)] = radix[0];
        mi += 1;
        if ((radix[0] & 0x80) != 0 and radix[1] != 0 and radix[1] != 1) {
            dispString[@intCast(mi)] = radix[1];
            mi += 1;
        }
    }

    while (p[0] != 0 and p[0] != 'E' and ival < 1000) {
        if (p[0] >= '0' and p[0] <= '9') {
            if (d > 0 and @rem(d, sepGroup) == 0 and !GROUPRIGHT_DISABLED()) {
                dispString[@intCast(mi)] = sep[0];
                mi += 1;
                if ((sep[0] & 0x80) != 0 and sep[1] != 0 and sep[1] != 1) {
                    dispString[@intCast(mi)] = sep[1];
                    mi += 1;
                }
            }
            dispString[@intCast(mi)] = p[0];
            mi += 1;
            ival += 1;
            d += 1;
        }
        p += 1;
    }

    while (mi > 1 and
        ((dispString[@intCast(mi - 1)] == '0') or
            (dispString[@intCast(mi - 2)] == sep[0] and sep[1] != 0 and sep[1] != 1 and dispString[@intCast(mi - 1)] == sep[1]) or
            (dispString[@intCast(mi - 1)] == sep[0] and sep[1] != 0 and sep[1] != 1 and dispString[@intCast(mi)] == sep[1])))
    {
        mi -= 1;
    }
    if (mi > 0 and (dispString[@intCast(mi - 1)] == radix[0] and (radix[1] == 0 or radix[1] == 1 or (radix[1] != 0 and radix[1] != 1 and dispString[@intCast(mi - 1)] == radix[1])))) {
        mi -= 1;
    }
    if (mi > 1 and (dispString[@intCast(mi - 2)] == radix[0] and (radix[1] != 0 and radix[1] != 1 and dispString[@intCast(mi - 1)] == radix[1]))) {
        mi -= 2;
    }

    dispString[@intCast(mi)] = 0;
    var tt: [32]u8 = undefined;
    exponentToDisplayString(exp, &tt, null, 0);
    abi.fmtCStr(dispString + @as(usize, @intCast(mi)), "{s}", .{ @as([*:0]const u8, @as([*c]const u8, &tt)) });
}

fn showShortIntegerLine(showRegis_p: calcRegister_t, tag: i16, startOffset: i16, numLines: i16, showName: bool) void {
    var src: i16 = undefined;
    var last: i16 = undefined;
    var d: i16 = undefined;
    var dest: i16 = undefined;
    var prefixWidth: i16 = undefined;
    const lastSlot: i16 = startOffset + (numLines - 1) * SHOWLineSize;
    setRegisterTag(showRegis_p, @intCast(tag));
    if (showName) {
        viewRegName2(tmpString + 2400, &prefixWidth);
    } else {
        tmpString[2400] = 0;
    }
    shortIntegerToDisplayString(showRegis_p, tmpString + 2400 + @as(usize, @intCast(stringByteLength(tmpString + 2400))), 1, noBaseOverride);
    last = 2400 + @as(i16, @intCast(stringByteLength(tmpString + 2400)));
    src = 2400;
    tmpString[@intCast(startOffset)] = 0;
    d = startOffset;
    while (d <= lastSlot) : (d += SHOWLineSize) {
        dest = d;
        tmpString[@intCast(d)] = 0;
        if (dest != startOffset) {
            _ = strcat(tmpString + @as(usize, @intCast(dest)), "  ");
            dest += 2;
        }
        while (src < last and (dest - d) < SHOWLineSize - 2) {
            tmpString[@intCast(dest)] = tmpString[@intCast(src)];
            if ((tmpString[@intCast(dest)] & 0x80) != 0) {
                dest += 1;
                src += 1;
                tmpString[@intCast(dest)] = tmpString[@intCast(src)];
            }
            src += 1;
            dest += 1;
            tmpString[@intCast(dest)] = 0;
        }
        checkAndEat(&src, last, &dest);
    }
}

// ===========================================================================
// fnC47Show (SAVE_SPACE_DM42_9 is undef -> this full body is live everywhere)
// ===========================================================================
const dtXFN: i32 = 100;

pub export fn fnC47Show(fnShow_param: u16) callconv(.c) void {
    const savedDisplayFormat = displayFormat;
    const savedDisplayFormatDigits = displayFormatDigits;
    const ssf0: u64 = systemFlags0;
    const ssf1: u64 = systemFlags1;
    var thereIsANextLine: bool = undefined;
    var dest: i16 = 0;
    var last: i16 = 0;
    var d: i16 = undefined;
    var i: i16 = undefined;
    var offset: i16 = undefined;
    var bytesProcessed: i16 = undefined;
    var aa: i16 = undefined;
    var bb: i16 = undefined;
    var cc: i16 = undefined;
    var dd: i16 = undefined;
    var numberOfLines: i16 = 0;

    displayFormat = DF_ALL;
    displayFormatDigits = 0;
    clearSystemFlag(@intCast(FLAG_IRFRAC));

    switch (fnShow_param) {
        NOPARAM => {
            showSoftmenu(-MNU_SHOW);
            source = 0;
            showRegis = REGISTER_X;
            startingLine = 0;
            IntShowMode = SHOWAUTO;
        },
        ITM_RS => {
            if (getRegisterDataType(@intCast(showRegis)) == dtLongInteger or isXFNShowing(@intCast(showRegis))) {
                if (IntShowMode == SHOWTNY) {
                    startingLine = 0;
                    source = 0;
                    IntShowMode = SHOWAUTO;
                } else if (IntShowMode != SHOWSML) {
                    startingLine = 0;
                    source = 0;
                    IntShowMode = SHOWSML;
                } else {
                    startingLine += 10;
                    if (startingLine >= 30 or source == last) {
                        startingLine = 0;
                        source = 0;
                        IntShowMode = SHOWTNY;
                    }
                }
            }
        },
        ITM_UP1 => {
            source = 0;
            startingLine = 0;
            IntShowMode = SHOWAUTO;
            if (showRegis == 9999) {
                showRegis = @intCast(REGISTER_X);
            } else {
                if (showRegis >= @as(u16, @intCast(FIRST_NAMED_VARIABLE)) + numberOfNamedVariables - 1) {
                    showRegis = @intCast(FIRST_GLOBAL_REGISTER);
                } else if (showRegis == @as(u16, @intCast(LAST_SPARE_REGISTER))) {
                    showRegis = @intCast(FIRST_NAMED_VARIABLE);
                } else {
                    showRegis += 1;
                }
                while (regInRange(showRegis) == 0 and showRegis < @as(u16, @intCast(FIRST_NAMED_VARIABLE)) + numberOfNamedVariables) {
                    showRegis += 1;
                }
            }
        },
        ITM_DOWN1 => {
            source = 0;
            startingLine = 0;
            IntShowMode = SHOWAUTO;
            if (showRegis == 9999) {
                showRegis = @intCast(REGISTER_X);
            } else {
                if (showRegis == @as(u16, @intCast(FIRST_GLOBAL_REGISTER))) {
                    showRegis = @intCast(@as(i32, FIRST_NAMED_VARIABLE) + numberOfNamedVariables - 1);
                } else if (showRegis == @as(u16, @intCast(FIRST_NAMED_VARIABLE))) {
                    showRegis = @intCast(LAST_SPARE_REGISTER);
                } else {
                    showRegis -= 1;
                }
                while (regInRange(showRegis) == 0 and showRegis != @as(u16, @intCast(FIRST_GLOBAL_REGISTER))) {
                    showRegis -= 1;
                }
            }
        },
        ITM_NOP => {},
        else => {},
    }

    refreshScreen(153);

    SHOW_reset();

    var selection: i32 = @intCast(getRegisterDataType(@intCast(showRegis)));

    if (isXFNShowing(@intCast(showRegis))) {
        switch (showRegis) {
            90, 93, 96, @as(u16, @intCast(REGISTER_X)), @as(u16, @intCast(REGISTER_T)) => {
                selection = dtXFN;
            },
            else => {},
        }
    }

    blk_switch: {
        if (selection == dtXFN) {
            _ = strcpy(errorMessage, tmpString + 2100);
            if (registerFMAOutputString(@intCast(showRegis), if (showRegis == @as(u16, @intCast(REGISTER_X))) "XY+Z = " else if (showRegis == @as(u16, @intCast(REGISTER_T))) "TA+B = " else "FMA: ", errorMessage + @as(usize, @intCast(stringByteLength(errorMessage)))) != 0) {
                // goto XFNentryPoint -> falls into the dtLongInteger body after the strcpy
                fnC47Show_longIntBody(&last, &dest, &numberOfLines);
            }
            break :blk_switch;
        } else if (selection == dtLongInteger) {
            _ = strcpy(errorMessage, tmpString + 2100);
            longIntegerRegisterToDisplayString(@intCast(showRegis), errorMessage + @as(usize, @intCast(stringByteLength(tmpString + 2100))), WRITE_BUFFER_LEN, 25 * SCREEN_WIDTH, 1010, 0);
            fnC47Show_longIntBody(&last, &dest, &numberOfLines);
            break :blk_switch;
        } else if (selection == dtReal34) {
            temporaryInformation = TI_SHOW_REGISTER_BIG;
            var angleM: i16 = @intCast(getRegisterAngularMode(@intCast(showRegis)));
            if (angleM == amDMS) {
                angleM = amDegree;
            }
            real34ToDisplayString(reg34(@intCast(showRegis)), @intCast(angleM), tmpString + 2100 + @as(usize, @intCast(stringByteLength(tmpString + 2100))), &numericFont, SCREEN_WIDTH * 2, 34, @intFromBool(LIMITEXP == 0), @intFromBool(FRONTSPACE == 0), NOIRFRAC);
            last = 2100 + @as(i16, @intCast(stringByteLength(tmpString + 2100)));
            source = 2100;
            d = 0;
            while (d <= 3 * SHOWLineSize) : (d += SHOWLineSize) {
                dest = d;
                tmpString[@intCast(d)] = 0;
                while (source < last and stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1) <= SCREEN_WIDTH - 8 * 2 - 5) {
                    const sl = SEPARATOR_LEFT();
                    const sr = SEPARATOR_RIGHT();
                    if ((tmpString[@intCast(source)] == sl[0] and (if (sl[1] == 1) true else tmpString[@intCast(source + 1)] == sl[1])) or
                        (tmpString[@intCast(source)] == sr[0] and (if (sr[1] == 1) true else tmpString[@intCast(source + 1)] == sr[1])))
                    {
                        aa = source;
                        if ((tmpString[@intCast(aa)] & 0x80) != 0) aa += 2;
                        if ((tmpString[@intCast(aa)] & 0x80) != 0) aa += 2;
                        if ((tmpString[@intCast(aa)] & 0x80) != 0) aa += 2;
                        if ((tmpString[@intCast(aa)] & 0x80) != 0) aa += 2;
                        var tmpString20: [20]u8 = undefined;
                        tmpString20[0] = 0;
                        _ = xcopy(&tmpString20, tmpString + @as(usize, @intCast(source)), @intCast(aa - source));
                        tmpString20[@intCast(aa - source)] = 0;
                        if (stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1) + stringWidth(&tmpString20, &numericFont, 1, 1) > SCREEN_WIDTH - 8 * 2 - 5) {
                            break;
                        }
                    }

                    tmpString[@intCast(dest)] = tmpString[@intCast(source)];
                    if ((tmpString[@intCast(dest)] & 0x80) != 0) {
                        dest += 1;
                        source += 1;
                        tmpString[@intCast(dest)] = tmpString[@intCast(source)];
                    }
                    source += 1;
                    dest += 1;
                    tmpString[@intCast(dest)] = 0;
                }
            }

            if (getRegisterAngularMode(@intCast(showRegis)) != amNone) {
                aa = 0;
                bb = 0;
                cc = 0;
                dd = 0;
                switch (getRegisterAngularMode(@intCast(showRegis))) {
                    amDegree => {
                        aa = amDMS;
                        bb = amRadian;
                        cc = amMultPi;
                        dd = amGrad;
                    },
                    amRadian => {
                        aa = amMultPi;
                        bb = amDegree;
                        cc = amDMS;
                        dd = amGrad;
                    },
                    amGrad => {
                        aa = amDegree;
                        bb = amDMS;
                        cc = amRadian;
                        dd = amMultPi;
                    },
                    amMultPi => {
                        aa = amRadian;
                        bb = amDegree;
                        cc = amDMS;
                        dd = amGrad;
                    },
                    amDMS => {
                        aa = amDMS;
                        bb = amRadian;
                        cc = amMultPi;
                        dd = amGrad;
                    },
                    else => {},
                }

                overrideShowBottomLine = 40;
                printXSHOW(aa, 2 * SHOWLineSize, displayFormat, displayFormatDigits, dtReal34, 0);
                printXSHOW(bb, 3 * SHOWLineSize, displayFormat, displayFormatDigits, dtReal34, 0);
                printXSHOW(cc, 4 * SHOWLineSize, displayFormat, displayFormatDigits, dtReal34, 0);
                printXSHOW(dd, 5 * SHOWLineSize, displayFormat, displayFormatDigits, dtReal34, 0);
            } else {
                overrideShowBottomLine = 30;
                setSystemFlag(@intCast(FLAG_ENGOVR));
                printXSHOW(amNone, 3 * SHOWLineSize, DF_SF, 6, dtReal34, 0);
                printXSHOW(amNone, 4 * SHOWLineSize, DF_UN, 3, dtReal34, 0);
                printXSHOW(amNone, 5 * SHOWLineSize, DF_SCI, 3, dtReal34, 0);
            }
            break :blk_switch;
        } else if (selection == dtComplex34) {
            temporaryInformation = TI_SHOW_REGISTER_BIG;

            complex34ToDisplayString(regComplex34(@intCast(showRegis)), tmpString, &numericFont, 2000, 34, LIMITEXP, FRONTSPACE, NOIRFRAC, @intCast(getComplexRegisterAngularMode(@intCast(showRegis))), @intFromBool(getComplexRegisterPolarMode(@intCast(showRegis)) != 0));
            i = @as(i16, @intCast(stringByteLength(tmpString))) - 1;
            while (i > 0) : (i -= 1) {
                if (tmpString[@intCast(i)] == 0x08) {
                    tmpString[@intCast(i)] = 0x05;
                }
            }

            last = 2100;
            while (tmpString[@intCast(last)] != 0) {
                last += 1;
            }
            _ = xcopy(tmpString + @as(usize, @intCast(last)), tmpString + 0, @intCast(strlen(tmpString + 0) + 1));
            tmpString[0] = 0;

            const strWid: i32 = stringWidth(tmpString + 2100, &numericFont, 1, 1);
            d = 2100;
            var hadFirstRealDigit: i16 = 0;
            while (d < 2100 + @as(i16, @intCast(stringByteLength(tmpString + 2100)))) {
                if (hadFirstRealDigit == 0 and tmpString[@intCast(d)] >= '0' and tmpString[@intCast(d)] <= '9') {
                    hadFirstRealDigit = d - 2100;
                }
                if (hadFirstRealDigit > 0 and (tmpString[@intCast(d)] == '+' or tmpString[@intCast(d)] == '-')) {
                    break;
                }
                d = 2100 + stringNextGlyph(tmpString + 2100, d - 2100);
            }
            const tmpp: i8 = @bitCast(tmpString[@intCast(d)]);
            tmpString[@intCast(d)] = 0;
            const strWidReal: i32 = stringWidth(tmpString + 2100, &numericFont, 1, 1);
            tmpString[@intCast(d)] = @bitCast(tmpp);
            const strWidImag: i32 = stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1);
            var strWidCur: i32 = 0;
            var changedOverToImag: bool = false;

            last = 2100 + @as(i16, @intCast(stringByteLength(tmpString + 2100)));
            source = 2100;
            d = 0;
            while (d <= 3 * SHOWLineSize) : (d += SHOWLineSize) {
                dest = d;
                tmpString[@intCast(d)] = 0;
                while (source < last and stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1) <= SCREEN_WIDTH - 8 * 2 - 5) {
                    tmpString[@intCast(dest)] = tmpString[@intCast(source)];
                    if ((tmpString[@intCast(dest)] & 0x80) != 0) {
                        dest += 1;
                        source += 1;
                        tmpString[@intCast(dest)] = tmpString[@intCast(source)];
                    }
                    source += 1;
                    dest += 1;
                    tmpString[@intCast(dest)] = 0;

                    const strWidLim: i32 = @divTrunc(55 * (if (changedOverToImag) strWidImag else strWidReal), 100);
                    strWidCur = stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1);

                    if ((strWidCur >= SCREEN_WIDTH - 60 and strWidCur > strWidLim) and tmpString[@intCast(source - 2)] == 160 and tmpString[@intCast(source - 1)] == 5) {
                        break;
                    }
                    if (d == 0 and source - 2100 > hadFirstRealDigit and strWid > SCREEN_WIDTH and (!(getComplexRegisterPolarMode(@intCast(showRegis)) == amPolar) and (tmpString[@intCast(source)] == '+' or tmpString[@intCast(source)] == '-'))) {
                        break;
                    }
                    if (source - 2100 > hadFirstRealDigit and (tmpString[@intCast(source)] == '+' or tmpString[@intCast(source + 1)] == '-')) {
                        changedOverToImag = true;
                    }
                    const radix = RADIX34_MARK_STRING();
                    const cu = complexUnit();
                    if (d > 0 and
                        ((!(getComplexRegisterPolarMode(@intCast(showRegis)) == amPolar) and (tmpString[@intCast(source)] == '+' or tmpString[@intCast(source)] == '-')) or
                            (stringWidth(tmpString + @as(usize, @intCast(d)), &numericFont, 1, 1) >= @divTrunc(@as(i32, SCREEN_WIDTH) * 4, 5) and tmpString[@intCast(source)] == radix[0] and tmpString[@intCast(source + 1)] == radix[1]) or
                            (getSystemFlag(FLAG_CPXMULT) != 0 and tmpString[@intCast(source)] == cu[0] and tmpString[@intCast(source + 1)] == cu[1])))
                    {
                        break;
                    }
                }
            }

            overrideShowBottomLine = 20;
            setSystemFlag(@intCast(FLAG_ENGOVR));
            printXSHOW(amNone, 4 * SHOWLineSize, DF_SF, 4, dtComplex34, 1);
            printXSHOW(amNone, 5 * SHOWLineSize, DF_SF, 4, dtComplex34, 0);
            break :blk_switch;
        } else if (selection == dtShortInteger) {
            temporaryInformation = TI_SHOW_REGISTER_BIG;

            var aa2: i16 = 0;
            var aa3: i16 = 0;
            var aa4: i16 = 0;
            var aa5: i16 = 0;
            aa = @intCast(getRegisterTag(@intCast(showRegis)));
            switch (aa) {
                2 => {
                    aa2 = 8;
                    aa3 = 10;
                    aa4 = 16;
                    aa5 = aa;
                },
                4 => {
                    aa2 = 2;
                    aa3 = 8;
                    aa4 = 16;
                    aa5 = aa;
                },
                8 => {
                    aa2 = 2;
                    aa3 = 10;
                    aa4 = 16;
                    aa5 = aa;
                },
                10 => {
                    aa2 = 2;
                    aa3 = 8;
                    aa4 = 16;
                    aa5 = aa;
                },
                16 => {
                    aa2 = 2;
                    aa3 = 8;
                    aa4 = 10;
                    aa5 = aa;
                },
                3, 5, 6, 7, 9, 11, 12, 13, 14, 15 => {
                    aa2 = 2;
                    aa3 = 10;
                    aa4 = 16;
                    aa5 = aa;
                },
                else => {},
            }
            showShortIntegerLine(@intCast(showRegis), aa2, 0, 2, true);
            showShortIntegerLine(@intCast(showRegis), aa3, 2 * SHOWLineSize, 1, false);
            showShortIntegerLine(@intCast(showRegis), aa4, 3 * SHOWLineSize, 1, false);
            showShortIntegerLine(@intCast(showRegis), aa5, 4 * SHOWLineSize, 2, false);

            setRegisterTag(@intCast(showRegis), @intCast(aa));
            break :blk_switch;
        } else if (selection == dtTime) {
            _ = strcpy(tmpString, tmpString + 2100);
            temporaryInformation = TI_SHOW_REGISTER_BIG;
            timeToDisplayString(@intCast(showRegis), tmpString + @as(usize, @intCast(stringByteLength(tmpString + 2100))), 1);
            break :blk_switch;
        } else if (selection == dtDate) {
            _ = strcpy(tmpString, tmpString + 2100);
            temporaryInformation = TI_SHOW_REGISTER_BIG;
            dateToDisplayString(@intCast(showRegis), tmpString + @as(usize, @intCast(stringByteLength(tmpString + 2100))));
            break :blk_switch;
        } else if (selection == dtString) {
            SHOW_reset();
            temporaryInformation = TI_SHOW_REGISTER_BIG;
            offset = 0;
            thereIsANextLine = true;
            bytesProcessed = 2100;
            _ = strcat(tmpString + 2100, "'");
            _ = strcat(tmpString + 2100, regString(@intCast(showRegis)));
            _ = strcat(tmpString + 2100, "'");
            while (thereIsANextLine) {
                _ = xcopy(tmpString + @as(usize, @intCast(offset)), tmpString + @as(usize, @intCast(bytesProcessed)), @intCast(stringByteLength(tmpString + @as(usize, @intCast(bytesProcessed))) + 1));
                thereIsANextLine = false;
                const strw = stringAfterPixelsC47(tmpString + @as(usize, @intCast(offset)), stdnumEnlarge, nocompress, @intCast(SCREEN_WIDTH - 1), 0, 1);
                if (strw[0] != 0) {
                    strw[0] = 0;
                    thereIsANextLine = true;
                }
                bytesProcessed += @intCast(stringByteLength(tmpString + @as(usize, @intCast(offset))));
                offset += SHOWLineSize;
                tmpString[@intCast(offset)] = 0;
            }
            if (offset <= 4 * SHOWLineSize) {
                break :blk_switch;
            }

            SHOW_reset();
            temporaryInformation = TI_SHOW_REGISTER_SMALL;
            offset = 0;
            thereIsANextLine = true;
            bytesProcessed = 2100;
            _ = strcat(tmpString + 2100, "'");
            _ = strcat(tmpString + 2100, regString(@intCast(showRegis)));
            _ = strcat(tmpString + 2100, "'");
            while (thereIsANextLine) {
                _ = xcopy(tmpString + @as(usize, @intCast(offset)), tmpString + @as(usize, @intCast(bytesProcessed)), @intCast(stringByteLength(tmpString + @as(usize, @intCast(bytesProcessed))) + 1));
                thereIsANextLine = false;
                const remainingString = stringAfterPixels(tmpString + @as(usize, @intCast(offset)), &standardFont, SCREEN_WIDTH, 0, 1);
                if (remainingString[0] != 0) {
                    remainingString[0] = 0;
                    thereIsANextLine = true;
                }
                bytesProcessed += @intCast(stringByteLength(tmpString + @as(usize, @intCast(offset))));
                offset += SHOWLineSize;
                tmpString[@intCast(offset)] = 0;
            }
            break :blk_switch;
        } else if (selection == dtConfig) {
            temporaryInformation = TI_SHOW_REGISTER_BIG;
            _ = xcopy(tmpString, "Configuration data", 19);
            break :blk_switch;
        } else if (selection == dtReal34Matrix or selection == dtComplex34Matrix) {
            clearScreenOld(@intFromBool(clrStatusBar == 0), clrRegisterLines, clrSoftkeys);
            dispM(showRegis, tmpString + 2100);
            drawSinglePixelFullWidthLine(Y_POSITION_OF_REGISTER_T_LINE - 4);
            temporaryInformation = TI_SHOWNOTHING;
            if (programRunStop == PGM_RUNNING) {
                refreshScreen(150);
                fnPause(10);
                temporaryInformation = TI_NO_INFO;
            }
            break :blk_switch;
        } else {
            temporaryInformation = TI_NO_INFO;
            displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, @intCast(showRegis));
            if (comptime extra_info) {
                if (comptime !dmcp_build) {
                    abi.fmtBufZ(errorMessage[0..512], "cannot SHOW {s}{s}", .{ @as([*:0]const u8, tmpString + 2100), @as([*:0]const u8, getRegisterDataTypeName(@intCast(showRegis), 1, 0)) });
                    moreInfoOnError("In function fnC47Show:", errorMessage, null, null);
                }
            }
            return;
        }
    }

    displayFormat = savedDisplayFormat;
    displayFormatDigits = savedDisplayFormatDigits;
    systemFlags0 = ssf0;
    systemFlags1 = ssf1;
}

// The dtLongInteger / XFN shared body (XFNentryPoint .. end of case dtLongInteger).
fn fnC47Show_longIntBody(last: *i16, dest: *i16, numberOfLines: *i16) void {
    last.* = @intCast(stringByteLength(errorMessage));
    const glyphNumber: i16 = @intCast(stringGlyphLength(errorMessage));

    blk_li: {
        if (IntShowMode == SHOWAUTO) {
            if (glyphNumber < 170) {
                temporaryInformation = TI_SHOW_REGISTER_BIG;
                numberOfLines.* = 6;
                startingLine = 0;
                const sourcemem: i16 = source;
                const destmem: i16 = dest.*;
                prepLongintIntoLines(last, &source, dest, &numericFont, SCREEN_WIDTH, numberOfLines.*, &startingLine);
                if (tmpString[@intCast(numberOfLines.* * SHOWLineSize)] == 0) {
                    break :blk_li;
                }
                source = sourcemem;
                dest.* = destmem;
                IntShowMode = SHOWSML;
            } else {
                IntShowMode = SHOWSML;
            }
        }

        if (IntShowMode == SHOWSML) {
            SHOW_reset();
            temporaryInformation = TI_SHOW_REGISTER_SMALL;
            numberOfLines.* = 10;
            prepLongintIntoLines(last, &source, dest, &standardFont, SCREEN_WIDTH, numberOfLines.*, &startingLine);
            if (tmpString[0] != 0) {
                // goto goBreak1
                fnC47Show_goBreak1(numberOfLines.*);
                break :blk_li;
            } else {
                startingLine = 0;
                source = 0;
                dest.* = 0;
                IntShowMode = SHOWTNY;
            }
        }

        if (IntShowMode == SHOWTNY) {
            SHOW_reset();
            temporaryInformation = TI_SHOW_REGISTER_TINY;
            numberOfLines.* = @intCast(minI(21, SHOWLineMax));
            startingLine = 0;
            prepLongintIntoLines(last, &source, dest, &tinyFont, SCREEN_WIDTH, numberOfLines.*, &startingLine);
            fnC47Show_goBreak1(numberOfLines.*);
        }
    }
}

fn fnC47Show_goBreak1(numberOfLines: i16) void {
    if (tmpString[@intCast(numberOfLines * SHOWLineSize)] != 0) {
        var ii: i16 = stringLastGlyph(tmpString + @as(usize, @intCast((numberOfLines - 1) * SHOWLineSize)));
        source = stringPrevNumberGlyph(errorMessage, source);

        if (IntShowMode == SHOWSML) {
            while (ii > 10 and (stringWidth(tmpString + @as(usize, @intCast((numberOfLines - 1) * SHOWLineSize)), &standardFont, 1, 1) + stringWidth(STD_ELLIPSIS, &standardFont, 1, 1) + stringWidth(STD_SPACE_6_PER_EM, &standardFont, 1, 1)) >= SCREEN_WIDTH) {
                source = stringPrevNumberGlyph(errorMessage, source);
                tmpString[@intCast((numberOfLines - 1) * SHOWLineSize + ii)] = 0;
                ii = stringPrevNumberGlyph(tmpString + @as(usize, @intCast((numberOfLines - 1) * SHOWLineSize)), ii);
            }
        }

        _ = xcopy(tmpString + @as(usize, @intCast((numberOfLines - 1) * SHOWLineSize + ii)), STD_ELLIPSIS, 2);
        ii += 2;
        _ = xcopy(tmpString + @as(usize, @intCast((numberOfLines - 1) * SHOWLineSize + ii)), STD_SPACE_6_PER_EM, 2);
        ii += 2;
        tmpString[@intCast((numberOfLines - 1) * SHOWLineSize + ii)] = 0;
    }
}

// ===========================================================================
// _view / fnView / fnAview / fnPrompt
// ===========================================================================
fn _view(regist: u16) void {
    if (regInRange(regist) != 0) {
        currentViewRegister = regist;
        temporaryInformation = TI_VIEW_REGISTER;
        if (programRunStop == PGM_RUNNING) {
            screenUpdatingMode &= ~(SCRUPD_MANUAL_STATUSBAR | SCRUPD_SKIP_STATUSBAR_ONE_TIME);
            refreshScreen(151);
        }
    }
}

pub export fn fnView(regist: u16) callconv(.c) void {
    _view(regist);
    if (comptime ir_printing) {
        printViewAview(ITM_VIEW, regist);
    }
}

pub export fn fnAview(regist: u16) callconv(.c) void {
    _view(regist);
    if (comptime ir_printing) {
        printViewAview(ITM_AVIEW, regist);
    }
}

pub export fn fnPrompt(regist: u16) callconv(.c) void {
    _view(regist);
    if (comptime ir_printing) {
        printInputPrompt(ITM_PROMPT, regist);
    }
    fnStopProgram(NOPARAM);
}
