// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/equation.c: the EQN equation editor + recursive
// formula parser/evaluator (RPN shunting-yard). UNCOVERED by the testSuite (no
// test gate) - verified by build only. Faithful line-by-line translation
// preserving the exact order of every real34_t operation and the byte-for-byte
// string/menu buffer manipulations.
//
// No renames (equation_legacy.c just #include'd equation.c). All public commands
// are exported under their REAL C names: fnEqNew, fnEqEdit, fnEqCla, fnEqDelete,
// fnEqCursorLeft, fnEqCursorRight, fnEqCalc, setEquation, deleteEquation,
// showEquation, parseEquation, isDyadicFunction. The static helpers stay private.
//
// EXTRA_INFO_ON_CALC_ERROR sprintf hints are stripped under TESTSUITE/DMCP and
// omitted. The host-only display in showEquation is reproduced faithfully (it is
// a public command; the glyph layout has no effect on register results but the
// cursorShown/rightEllipsis out-params and tmpString contents are preserved).

const runtime = @import("solve_runtime.zig");
const solve_build_options = @import("solve_build_options");

// hal/gui.h: calcModeAimGui() is a no-op macro on DMCP builds (and when the sim
// has no on-screen keyboard); only the on-screen-keyboard host links the real fn.
const is_dmcp_build = @hasDecl(solve_build_options, "is_dmcp_build") and solve_build_options.is_dmcp_build;

const real34_t = abi.Real34;
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = abi.RealContext;

const calcRegister_t = runtime.calcRegister_t;
const bool_t = bool;

// ---------------------------------------------------------------------------
// Structures (typeDefinitions.h)
// ---------------------------------------------------------------------------
const formulaHeader_t = extern struct {
    pointerToFormulaData: u16,
    sizeInBlocks: u8,
    unused: u8,
};

const item_t = abi.Item;

const font_t = opaque {};

const dynamicSoftmenu_t = extern struct {
    menuItem: i16,
    numItems: i16,
    menuContent: [*c]u8,
};
const softmenuStack_t = abi.SoftmenuStack;

// ---------------------------------------------------------------------------
// defines.h / items.h values (verified)
// ---------------------------------------------------------------------------
const REGISTER_X: calcRegister_t = 100;
const REGISTER_Y: calcRegister_t = 101;
const REGISTER_K: calcRegister_t = 111;
const ERR_REGISTER_LINE: calcRegister_t = 102;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const INVALID_VARIABLE: u16 = 2199;
const FIRST_RESERVED_VARIABLE: u16 = 2000; // defines.h: RESERVED_VARIABLE_X = FIRST_RESERVED_VARIABLE = LAST_NAMED_VARIABLE(1999)+1

const ERROR_RAM_FULL: u8 = 11;
const ERROR_FUNCTION_NOT_FOUND: u8 = 7;
const ERROR_SYNTAX_ERROR_IN_EQUATION: u8 = 45;
const ERROR_EQUATION_TOO_COMPLEX: u8 = 46;
const ERROR_RESERVED_VARIABLE_NAME: u8 = 61;
const ERROR_NONE: u8 = 0;

const FLAG_SOLVING: u32 = 0xc026;
const FLAG_ASLIFT: u32 = 0xc023;
const FLAG_ALPHA: u32 = 0x800e;
const FLAG_NUMLOCK: u32 = 0x8043;
const FLAG_MULTx: i32 = 0x801b;

const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtString: u32 = 5;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const TI_NO_INFO: u8 = 0;
const TI_FUNCTION: u8 = 113;

const SOLVER_STATUS_EQUATION_MODE: u16 = 0x200c;
const SOLVER_STATUS_EQUATION_SOLVER: u16 = 0x0000;
const SOLVER_STATUS_EQUATION_INTEGRATE: u16 = 0x0004;
const SOLVER_STATUS_EQUATION_1ST_DERIVATIVE: u16 = 0x0008;
const SOLVER_STATUS_EQUATION_2ND_DERIVATIVE: u16 = 0x000C;
const SOLVER_STATUS_EQUATION_GRAPHER: u16 = 0x2000;

const CM_EIM: u8 = 13;
const NC_NORMAL: u8 = 0;
const AC_LOWER: u8 = 1; // CAPS_EQN_DEFAULT
const SCRUPD_AUTO: u8 = 0x00;
const vmNormal: u8 = 0;

const EQUATION_AIM_BUFFER: u16 = 0xffff;
const EQUATION_NO_CURSOR: u16 = 0xffff;
const EQUATION_PARSER_MVAR: u16 = 0;
const EQUATION_PARSER_XEQ: u16 = 1;

const AIM_BUFFER_LENGTH: usize = 1024;
const REAL34_SIZE_IN_BYTES: usize = 16;

const FIRST_CONSTANT: u32 = 128; // CST_01
const LAST_CONSTANT: u32 = 212; // CST_84
const LAST_ITEM: u32 = 2860;
const EIM_STATUS: u16 = 0x0100;
const EIM_ENABLED: u16 = 1 << 8;

const CMP_BINARY: i32 = 0;
const CMP_NAME: i32 = 3;

const C47_NULL: u16 = 65535;

const SCREEN_WIDTH: i16 = 400;
const SCREEN_HEIGHT: i16 = 240;
const SOFTMENU_HEIGHT: i16 = 23;
const Y_POSITION_OF_REGISTER_Y_LINE: i16 = 96;
const Y_POSITION_OF_REGISTER_X_LINE: i16 = 132;
const DF_ALL: u8 = 0;

// ITM_* opcodes (items.h)
const ITM_sin: u16 = 76;
const ITM_arcsin: u16 = 83;
const ITM_cos: u16 = 74;
const ITM_arccos: u16 = 81;
const ITM_tan: u16 = 79;
const ITM_arctan: u16 = 85;
const ITM_sinh: u16 = 78;
const ITM_arsinh: u16 = 84;
const ITM_cosh: u16 = 75;
const ITM_arcosh: u16 = 82;
const ITM_tanh: u16 = 80;
const ITM_artanh: u16 = 86;
const ITM_atan2: u16 = 1775;
const ITM_MAGNITUDE: u16 = 105;
const ITM_CEIL: u16 = 87;
const ITM_EXP: u16 = 65;
const ITM_FLOOR: u16 = 88;
const ITM_GDM1: u16 = 1479;
const ITM_GD: u16 = 1478;
const ITM_LOG2: u16 = 68;
const ITM_LOG10: u16 = 71;
const ITM_LN: u16 = 69;
const ITM_Max: u16 = 2654;
const ITM_Min: u16 = 2655;
const ITM_WM1: u16 = 1637;
const ITM_GAMMAX: u16 = 1664;
const ITM_SQUAREROOTX: u16 = 61;
const ITM_zetaX: u16 = 1670;
const ITM_CUBEROOT: u16 = 62;
const ITM_XTHROOT: u16 = 63;
const ITM_CONSTpi: u16 = 109;
const ITM_op_j: u16 = 1830;
const ITM_ADD: u16 = 95;
const ITM_SUB: u16 = 96;
const ITM_MULT: u16 = 98;
const ITM_DIV: u16 = 99;
const ITM_IDIV: u16 = 100;
const ITM_MOD: u16 = 102;
const ITM_YX: u16 = 60;
const ITM_XFACT: u16 = 108;
const ITM_COMB: u16 = 49;
const ITM_PERM: u16 = 50;
const ITM_LOGXY: u16 = 72;
const ITM_RMD: u16 = 122;
const ITM_HN: u16 = 1483;
const ITM_HNP: u16 = 1484;
const ITM_Lm: u16 = 1505;
const ITM_LmALPHA: u16 = 1506;
const ITM_Pn: u16 = 1550;
const ITM_Tn: u16 = 1623;
const ITM_Un: u16 = 1627;
const ITM_RCL: i16 = 51;
const ITM_MAX: u16 = 103;
const ITM_MIN: u16 = 104;
const ITM_CALC: u16 = 1767;
const ITM_DRAW: u16 = 2372;
const ITM_FPHERE: u16 = 2377;
const ITM_FPPHERE: u16 = 2378;
const ITM_INTEGRAL_YX: u16 = 1690;

const MNU_GRAPHS: u16 = 2374;
const MNU_Sf_TOOL: u16 = 2375;
const MNU_Solver_TOOL: u16 = 2376;

// PARSER_OPERATOR_ITM_* (equation.c #defines)
const PARSER_OPERATOR_ITM_PARENTHESIS_LEFT: u16 = 5000;
const PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT: u16 = 5001;
const PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT: u16 = 5002;
const PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT: u16 = 5003;
const PARSER_OPERATOR_ITM_EQUAL: u16 = 5004;
const PARSER_OPERATOR_ITM_YX: u16 = 5005;
const PARSER_OPERATOR_ITM_XFACT: u16 = 5006;
const PARSER_OPERATOR_ITM_END_OF_FORMULA: u16 = 5007;

const PARSER_HINT_NUMERIC: u16 = 0;
const PARSER_HINT_OPERATOR: u16 = 1;
const PARSER_HINT_FUNCTION: u16 = 2;
const PARSER_HINT_VARIABLE: u16 = 3;

const PARSER_OPERATOR_STACK_SIZE: u32 = 10;
const PARSER_NUMERIC_STACK_SIZE: u32 = PARSER_OPERATOR_STACK_SIZE;

// STD_* glyph strings (fonts.h)
const STD_CROSS = "\x80\xd7";
const STD_DOT = "\x80\xb7";
const STD_CURSOR = "\xa4\x27";
const STD_ELLIPSIS = "\xa0\x26";
const STD_EulerE = "\xa1\x47";
const STD_SPACE_PUNCTUATION = "\xa0\x08";
const STD_SUB_0 = "\xa0\x80";
const STD_SUB_10 = "\xa4\x7d";
const STD_SUP_0 = "\xa1\x60";
const STD_SUP_MINUS = "\xa1\x6b";
const STD_SUP_PLUS = "\xa1\x6a";
const STD_pi = "\x83\xc0";
const STD_i = "\x69";
const STD_j = "\x6a";
const STD_op_i = "\xa1\x48";
const STD_op_j = "\xa1\x49";

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var currentSolverStatus: u16;
extern var currentSolverVariable: u16;
extern var currentFormula: u16;
extern var numberOfFormulae: u16;
extern var graphVariabl1: calcRegister_t;
extern var allFormulae: [*c]formulaHeader_t;
extern var aimBuffer: [*c]u8;
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;
extern var xCursor: u32;
extern var yCursor: u32;
extern var calcMode: u8;
extern var nextChar: u8;
extern var scrLock: u8;
extern var alphaCase: u8;
extern var screenUpdatingMode: u8;
extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var updateOldConstants: bool;
extern var ram: [*c]u32;

// C `item_t indexOfItems[]` is an ARRAY: bind the address (gotcha #1). The `[*]`
// pointer form loaded the array's first bytes as the pointer -> wild deref in the
// EIM equation-catalog search.
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });
extern const standardFont: font_t;
// C arrays: bind the address, not the data-as-pointer (gotcha #1). The pointer
// form would crash dynamicSoftmenu[...] accesses like fnSolveVar/fnIntegrateVar.
const dynamicSoftmenu = @extern([*c]dynamicSoftmenu_t, .{ .name = "dynamicSoftmenu" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });

extern var ctxtReal34: realContext_t;

// ---------------------------------------------------------------------------
// Constants blob accessors
// ---------------------------------------------------------------------------
inline fn const_NaN() *align(1) const real_t {
    return consts.c812();
}
inline fn const34_0() *align(1) const real34_t {
    return consts.q16200();
}
inline fn const34_1() *align(1) const real34_t {
    return consts.q16312();
}

// ---------------------------------------------------------------------------
// real34_t / real_t externs and macros
// ---------------------------------------------------------------------------
extern fn decimal128FromNumber(dest: *align(1) real34_t, src: *align(1) const real_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadSubtract(res: *align(1) real34_t, op1: *align(1) const real34_t, op2: *align(1) const real34_t, ctxt: *realContext_t) *align(1) real34_t;
extern fn decQuadZero(dest: *align(1) real34_t) *align(1) real34_t;
extern fn decQuadIsZero(source: *align(1) const real34_t) bool;
extern fn decQuadIsNaN(source: *align(1) const real34_t) bool;
extern fn decQuadFromString(dest: *align(1) real34_t, str: [*:0]const u8, ctxt: *realContext_t) *align(1) real34_t;

inline fn realToReal34(source: *align(1) const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}
inline fn real34Copy(source: *align(1) const real34_t, destination: *align(1) real34_t) void {
    const src: *align(1) const [2]u64 = @ptrCast(source);
    const dst: *align(1) [2]u64 = @ptrCast(destination);
    dst[0] = src[0];
    dst[1] = src[1];
}
inline fn real34Subtract(op1: *align(1) const real34_t, op2: *align(1) const real34_t, res: *align(1) real34_t) void {
    _ = decQuadSubtract(res, op1, op2, &ctxtReal34);
}
inline fn real34SetZero(destination: *align(1) real34_t) void {
    _ = decQuadZero(destination);
}
inline fn real34IsZero(source: *align(1) const real34_t) bool {
    return decQuadIsZero(source);
}
inline fn real34IsNaN(source: *align(1) const real34_t) bool {
    return decQuadIsNaN(source);
}
inline fn stringToReal34(source: [*:0]const u8, destination: *align(1) real34_t) void {
    _ = decQuadFromString(destination, source, &ctxtReal34);
}

// ---------------------------------------------------------------------------
// Register / stack / program externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
inline fn registerReal34Ptr(reg: calcRegister_t) *align(1) real34_t {
    return @ptrCast(getRegisterDataPointer(reg).?);
}
inline fn registerImag34Ptr(reg: calcRegister_t) *align(1) real34_t {
    const base: [*]u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(base + REAL34_SIZE_IN_BYTES);
}
inline fn registerStringPtr(reg: calcRegister_t) [*c]u8 {
    const base: [*]u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return base + STR_LGINT_HEADER_SIZE;
}
const STR_LGINT_HEADER_SIZE: usize = 4;

extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u32, tag: u32) void;
extern fn clearRegister(regist: calcRegister_t) void;

extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: i32) bool;
extern fn liftStack() void;
extern fn fnToReal(unused: u16) void;
extern fn fnDrop(unused: u16) void;
extern fn runFunction(item: i16) void;
extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn adjustResult(res: calcRegister_t, drop_y: bool, set_cpx_res: bool, op1: calcRegister_t, op2: calcRegister_t, op3: calcRegister_t) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn displayBugScreen(msg: [*:0]const u8) void;

extern fn findNamedVariable(variableName: [*:0]const u8) calcRegister_t;
extern fn findOrAllocateNamedVariable(variableName: [*:0]const u8) calcRegister_t;
extern fn validateName(name: [*:0]const u8) bool;
extern fn refreshRegisterLine(regist: calcRegister_t) void;
inline fn calcModeAimGui() void {
    if (!is_dmcp_build) {
        const f = @extern(*const fn () callconv(.c) void, .{ .name = "calcModeAimGui" });
        f();
    }
}

// memory blocks
extern fn allocC47Blocks(sizeInBlocks: usize) ?*anyopaque;
extern fn reallocC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) ?*anyopaque;
extern fn reduceC47Blocks(pcMemPtr: ?*anyopaque, oldSizeInBlocks: usize, newSizeInBlocks: usize) void;
extern fn freeC47Blocks(pcMemPtr: ?*anyopaque, sizeInBlocks: usize) void;

// strings / display
extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparisonType: i32) i32;
extern fn compareChar(char1: [*c]const u8, char2: [*c]const u8) i32;
extern fn stringGlyphLength(str: [*c]const u8) i32;
extern fn stringWidth(str: [*c]const u8, font: *const font_t, withLeadingEmptyRows: bool, withEndingEmptyRows: bool) i16;
extern fn showString(str: [*c]const u8, font: *const font_t, x: u32, y: u32, videoMode: u8, showLeadingCols: bool, showEndingCols: bool) u32;
extern fn strlen(s: [*c]const u8) usize;
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}

// PRODUCT_SIGN macro: getSystemFlag(FLAG_MULTx) ? STD_CROSS : STD_DOT
inline fn PRODUCT_SIGN() [*:0]const u8 {
    return if (getSystemFlag(FLAG_MULTx)) STD_CROSS else STD_DOT;
}

inline fn TO_PCMEMPTR(p: u16) [*c]u8 {
    if (p == C47_NULL) return null;
    return @ptrCast(ram + p);
}
inline fn TO_C47MEMPTR(p: ?*anyopaque) u16 {
    if (p == null) return C47_NULL;
    const pu: [*]u32 = @ptrCast(@alignCast(p.?));
    return @intCast((@intFromPtr(pu) - @intFromPtr(ram)) / @sizeOf(u32));
}
inline fn TO_BLOCKS(n: u32) usize {
    return (n + 3) >> 2; // BYTES_PER_BLOCK=4, BPB=2
}

// ---------------------------------------------------------------------------
// functionAlias table
// ---------------------------------------------------------------------------
const functionAlias_t = struct {
    name: [:0]const u8,
    opCode: u16,
};

const functionAlias = [_]functionAlias_t{
    .{ .name = "sin", .opCode = ITM_sin },
    .{ .name = "asin", .opCode = ITM_arcsin },
    .{ .name = "arsin", .opCode = ITM_arcsin },
    .{ .name = "arcsin", .opCode = ITM_arcsin },
    .{ .name = "cos", .opCode = ITM_cos },
    .{ .name = "acos", .opCode = ITM_arccos },
    .{ .name = "arcos", .opCode = ITM_arccos },
    .{ .name = "arccos", .opCode = ITM_arccos },
    .{ .name = "tan", .opCode = ITM_tan },
    .{ .name = "atan", .opCode = ITM_arctan },
    .{ .name = "artan", .opCode = ITM_arctan },
    .{ .name = "arctan", .opCode = ITM_arctan },
    .{ .name = "SINH", .opCode = ITM_sinh },
    .{ .name = "ASINH", .opCode = ITM_arsinh },
    .{ .name = "asinh", .opCode = ITM_arsinh },
    .{ .name = "arcsinh", .opCode = ITM_arsinh },
    .{ .name = "COSH", .opCode = ITM_cosh },
    .{ .name = "ACOSH", .opCode = ITM_arcosh },
    .{ .name = "acosh", .opCode = ITM_arcosh },
    .{ .name = "arccosh", .opCode = ITM_arcosh },
    .{ .name = "TANH", .opCode = ITM_tanh },
    .{ .name = "ATANH", .opCode = ITM_artanh },
    .{ .name = "atanh", .opCode = ITM_artanh },
    .{ .name = "arctanh", .opCode = ITM_artanh },
    .{ .name = "atan2", .opCode = ITM_atan2 },
    .{ .name = "ABS", .opCode = ITM_MAGNITUDE },
    .{ .name = "abs", .opCode = ITM_MAGNITUDE },
    .{ .name = "CEIL", .opCode = ITM_CEIL },
    .{ .name = "EXP", .opCode = ITM_EXP },
    .{ .name = "exp", .opCode = ITM_EXP },
    .{ .name = "FLOOR", .opCode = ITM_FLOOR },
    .{ .name = "g" ++ "\xa4\x9f" ++ "\xa1\x6b" ++ "\xa1\x61", .opCode = ITM_GDM1 }, // g STD_SUB_d STD_SUP_MINUS STD_SUP_1
    .{ .name = "g" ++ "\xa4\x9f" ++ "^-1", .opCode = ITM_GDM1 }, // g STD_SUB_d "^-1"
    .{ .name = "gd" ++ "\xa1\x6b" ++ "\xa1\x61", .opCode = ITM_GDM1 }, // gd STD_SUP_MINUS STD_SUP_1
    .{ .name = "gd^-1", .opCode = ITM_GDM1 },
    .{ .name = "gd", .opCode = ITM_GD },
    .{ .name = "g" ++ "\xa4\x9f", .opCode = ITM_GD }, // g STD_SUB_d
    .{ .name = "lB", .opCode = ITM_LOG2 },
    .{ .name = "lb", .opCode = ITM_LOG2 },
    .{ .name = "LG2", .opCode = ITM_LOG2 },
    .{ .name = "lg", .opCode = ITM_LOG10 },
    .{ .name = "ln", .opCode = ITM_LN },
    .{ .name = "LOG" ++ "\xa0\x81" ++ "\xa0\x80", .opCode = ITM_LOG10 }, // LOG STD_SUB_1 STD_SUB_0
    .{ .name = "LOG" ++ "\xa0\x82", .opCode = ITM_LOG2 }, // LOG STD_SUB_2
    .{ .name = "LOG10", .opCode = ITM_LOG10 },
    .{ .name = "LOG2", .opCode = ITM_LOG2 },
    .{ .name = "log" ++ "\xa0\x81" ++ "\xa0\x80", .opCode = ITM_LOG10 },
    .{ .name = "log" ++ "\xa0\x82", .opCode = ITM_LOG2 },
    .{ .name = "log10", .opCode = ITM_LOG10 },
    .{ .name = "log", .opCode = ITM_LOG10 },
    .{ .name = "log2", .opCode = ITM_LOG2 },
    .{ .name = "MAX", .opCode = ITM_Max },
    .{ .name = "MIN", .opCode = ITM_Min },
    .{ .name = "W" ++ "\xa1\x6b" ++ "\xa1\x61", .opCode = ITM_WM1 }, // W STD_SUP_MINUS STD_SUP_1
    .{ .name = "W^-1", .opCode = ITM_WM1 },
    .{ .name = "\x83\x93", .opCode = ITM_GAMMAX }, // STD_GAMMA
    .{ .name = "\xa2\x1a", .opCode = ITM_SQUAREROOTX }, // STD_SQUARE_ROOT
    .{ .name = "\x83\xb6", .opCode = ITM_zetaX }, // STD_zeta
    .{ .name = "\xa2\x1b", .opCode = ITM_CUBEROOT }, // STD_CUBE_ROOT
    .{ .name = "\xa2\x1c", .opCode = ITM_XTHROOT }, // STD_xTH_ROOT
};

// ===========================================================================
// Public commands
// ===========================================================================
const bugScreenUnknownOperator: [*:0]const u8 = "In function _parseWord: Unknown operator appeared!";
const bugScreenUnknownFormulaParserMode: [*:0]const u8 = "In function _parseWord: Unknown mode of formula parser!";

pub export fn fnEqNew(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (numberOfFormulae == 0) {
        allFormulae = @ptrCast(@alignCast(allocC47Blocks(TO_BLOCKS(@sizeOf(formulaHeader_t)))));
        if (allFormulae != null) {
            numberOfFormulae = 1;
            currentFormula = 0;
            allFormulae[0].pointerToFormulaData = C47_NULL;
            allFormulae[0].sizeInBlocks = 0;
            graphVariabl1 = 0;
            currentSolverVariable = INVALID_VARIABLE;
        } else {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            return;
        }
    } else {
        const newPtr: [*c]formulaHeader_t = @ptrCast(@alignCast(allocC47Blocks(TO_BLOCKS(@sizeOf(formulaHeader_t)) * (numberOfFormulae + 1))));
        if (newPtr != null) {
            var i: u32 = 0;
            while (i < numberOfFormulae) : (i += 1) {
                newPtr[i + @intFromBool(i > currentFormula)] = allFormulae[i];
            }
            currentFormula += 1;
            newPtr[currentFormula].pointerToFormulaData = C47_NULL;
            newPtr[currentFormula].sizeInBlocks = 0;
            freeC47Blocks(allFormulae, TO_BLOCKS(@sizeOf(formulaHeader_t)) * (numberOfFormulae));
            allFormulae = newPtr;
            numberOfFormulae += 1;
            graphVariabl1 = 0;
        } else {
            displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            return;
        }
    }
    fnEqEdit(NOPARAM);
}

pub export fn fnEqEdit(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (currentFormula < numberOfFormulae) {
        const equationString: [*c]const u8 = TO_PCMEMPTR(allFormulae[currentFormula].pointerToFormulaData);
        if (equationString != null) {
            _ = xcopy(aimBuffer, equationString, @intCast(stringByteLength(equationString) + 1));
        } else {
            aimBuffer[0] = 0;
        }
        calcMode = CM_EIM;
        alphaCase = CAPS_EQN_DEFAULT();
        nextChar = NC_NORMAL;
        clearSystemFlag(FLAG_NUMLOCK);
        scrLock = NC_NORMAL;
        setSystemFlag(FLAG_ALPHA);
        yCursor = 0;
        xCursor = if (equationString != null) @intCast(stringGlyphLength(equationString)) else 0;
        calcModeAimGui();
    }
}

inline fn CAPS_EQN_DEFAULT() u8 {
    return AC_LOWER;
}

pub export fn fnEqCla() linksection(runtime.code_section) callconv(.c) void {
    xCursor = 0;
    aimBuffer[0] = 0;
}

pub export fn fnEqDelete(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    deleteEquation(currentFormula);
}

pub export fn fnEqCursorLeft(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (xCursor > 0) {
        xCursor -= 1;
    }
}

pub export fn fnEqCursorRight(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    if (xCursor < @as(u32, @intCast(stringGlyphLength(aimBuffer)))) {
        xCursor += 1;
    }
}

pub export fn fnEqCalc(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    setSystemFlag(FLAG_SOLVING);
    parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    adjustResult(REGISTER_X, false, false, REGISTER_X, -1, -1);
    clearSystemFlag(FLAG_SOLVING);
    temporaryInformation = TI_FUNCTION;
}

pub export fn setEquation(equationId: u16, equationString: [*c]const u8) linksection(runtime.code_section) callconv(.c) void {
    const newSizeInBlocks: usize = TO_BLOCKS(@intCast(stringByteLength(equationString) + 1));
    var newPtr: ?*anyopaque = undefined;
    if (allFormulae[equationId].sizeInBlocks == 0) {
        newPtr = allocC47Blocks(newSizeInBlocks);
    } else {
        newPtr = reallocC47Blocks(TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData), allFormulae[equationId].sizeInBlocks, newSizeInBlocks);
    }
    if (newPtr != null) {
        allFormulae[equationId].pointerToFormulaData = TO_C47MEMPTR(newPtr);
    } else {
        displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return;
    }
    allFormulae[equationId].sizeInBlocks = @intCast(newSizeInBlocks);
    _ = xcopy(TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData), equationString, @intCast(stringByteLength(equationString) + 1));
}

pub export fn deleteEquation(equationId: u16) linksection(runtime.code_section) callconv(.c) void {
    if (equationId < numberOfFormulae) {
        if (allFormulae[equationId].sizeInBlocks > 0) {
            freeC47Blocks(TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData), allFormulae[equationId].sizeInBlocks);
        }
        var i: u16 = equationId + 1;
        while (i < numberOfFormulae) : (i += 1) {
            allFormulae[i - 1] = allFormulae[i];
        }
        reduceC47Blocks(allFormulae, TO_BLOCKS(@sizeOf(formulaHeader_t)) * numberOfFormulae, TO_BLOCKS(@sizeOf(formulaHeader_t)) * (numberOfFormulae - 1));
        numberOfFormulae -= 1;
        if (numberOfFormulae == 0) {
            allFormulae = null;
        }
        if (numberOfFormulae > 0 and currentFormula >= numberOfFormulae) {
            currentFormula = numberOfFormulae - 1;
        }
        graphVariabl1 = 0;
        currentSolverVariable = INVALID_VARIABLE;
    }
}

// ===========================================================================
// showEquation helpers
// ===========================================================================
fn _showExponent(bufPtr: *[*c]u8, strPtr: *[*c]const u8, strWidth: *i16) linksection(runtime.code_section) void {
    strPtr.* += 1;
    switch (strPtr.*[0]) {
        '+' => {
            bufPtr.*[0] = STD_SUP_PLUS[0];
            bufPtr.*[1] = STD_SUP_PLUS[1];
        },
        '-' => {
            bufPtr.*[0] = STD_SUP_MINUS[0];
            bufPtr.*[1] = STD_SUP_MINUS[1];
        },
        else => {
            bufPtr.*[0] = STD_SUP_0[0];
            bufPtr.*[1] = STD_SUP_0[1] +% (strPtr.*[0] - '0');
        },
    }
    bufPtr.*[2] = 0;
    strWidth.* += stringWidth(bufPtr.*, &standardFont, true, true);
    bufPtr.* += 2;
}

fn _checkExponent(strPtr_in: [*c]const u8) linksection(runtime.code_section) u32 {
    var strPtr = strPtr_in;
    var digits: u32 = 0;
    while (true) {
        switch (strPtr[0]) {
            '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' => {
                digits += 1;
                strPtr += 1;
            },
            '^', ',', '.' => {
                return 0;
            },
            '+', '-' => {
                if (digits == 0) {
                    digits += 1;
                    strPtr += 1;
                } else {
                    return digits;
                }
            },
            else => {
                return digits;
            },
        }
    }
}

fn _addSpace(bufPtr: *[*c]u8, strWidth: *i16, doubleBytednessHistory: *u32) linksection(runtime.code_section) void {
    var spaceShallBeAdded: bool_t = true;
    if ((@intFromPtr(bufPtr.*) >= @intFromPtr(tmpString) + 2) and (compareChar(bufPtr.* - 2, STD_SPACE_PUNCTUATION) == 0)) {
        spaceShallBeAdded = false;
    }
    if ((@intFromPtr(bufPtr.*) >= @intFromPtr(tmpString) + 1) and ((doubleBytednessHistory.* & 1) == 0 and (bufPtr.* - 1)[0] == ' ')) {
        spaceShallBeAdded = false;
    }
    if (spaceShallBeAdded) {
        bufPtr.*[0] = STD_SPACE_PUNCTUATION[0];
        bufPtr.*[1] = STD_SPACE_PUNCTUATION[1];
        bufPtr.*[2] = 0;
        strWidth.* += stringWidth(bufPtr.*, &standardFont, true, true);
        bufPtr.* += 2;
        doubleBytednessHistory.* |= 1;
        doubleBytednessHistory.* <<= 1;
    }
}

pub export fn showEquation(equationId: u16, startAt: u16, cursorAt: u16, dryRun: bool_t, cursorShown_in: ?*bool_t, rightEllipsis_in: ?*bool_t) linksection(runtime.code_section) callconv(.c) void {
    const X_OFF: i8 = if (cursorAt == EQUATION_NO_CURSOR) 0 else 20;
    if (equationId < numberOfFormulae or equationId == EQUATION_AIM_BUFFER) {
        var bufPtr: [*c]u8 = tmpString;
        var strPtr: [*c]const u8 = if (equationId == EQUATION_AIM_BUFFER) aimBuffer else TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData);
        var strLength: u16 = 0;
        var strWidth: i16 = 0;
        var glyphWidth: i16 = 0;
        var doubleBytednessHistory: u32 = 0;
        var tmpVal: u32 = 0;
        var inLabel: bool_t = false;
        var unaryMinus: bool_t = true;
        var inNumeric: bool_t = true;
        var beginningOfNumber: bool_t = true;
        var inExponent: bool_t = false;
        var tmpPtr: [*c]const u8 = strPtr;

        var _cursorShown: bool_t = undefined;
        var _rightEllipsis: bool_t = undefined;
        const cursorShown: *bool_t = cursorShown_in orelse &_cursorShown;
        const rightEllipsis: *bool_t = rightEllipsis_in orelse &_rightEllipsis;
        cursorShown.* = false;
        rightEllipsis.* = false;

        {
            var i: u32 = 0;
            while (i < 7) : (i += 1) {
                tmpPtr += if ((tmpPtr[0] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
                if (tmpPtr[0] == ':') {
                    inLabel = (startAt <= (i + 1));
                    tmpVal = i;
                    break;
                } else if (tmpPtr[0] == '(') {
                    inLabel = false;
                    tmpVal = i;
                    break;
                }
            }
        }
        bufPtr = tmpString;

        if (startAt > 0) {
            bufPtr[0] = STD_ELLIPSIS[0];
            bufPtr[1] = STD_ELLIPSIS[1];
            bufPtr[2] = 0;
            strWidth += stringWidth(bufPtr, &standardFont, true, true);
            bufPtr += 2;
        }
        if (startAt == cursorAt) {
            bufPtr[0] = STD_CURSOR[0];
            bufPtr[1] = STD_CURSOR[1];
            bufPtr[2] = 0;
            strWidth += stringWidth(bufPtr, &standardFont, true, true);
            bufPtr += 2;
            cursorShown.* = true;
        }

        while (strPtr[0] != 0) {
            strLength += 1;
            if (strLength > startAt) {
                doubleBytednessHistory <<= 1;
                bufPtr[0] = strPtr[0];

                if ((!inLabel) and strPtr[0] == ':') {
                    // Argument separator
                    _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
                    bufPtr[0] = strPtr[0];
                    bufPtr[1] = 0;
                    strWidth += stringWidth(bufPtr, &standardFont, true, true);
                    bufPtr[1] = STD_SPACE_PUNCTUATION[0];
                    bufPtr[2] = STD_SPACE_PUNCTUATION[1];
                    bufPtr[3] = 0;
                    doubleBytednessHistory <<= 1;
                    doubleBytednessHistory |= 1;
                    bufPtr += 1;
                    unaryMinus = true;
                    inNumeric = true;
                    beginningOfNumber = true;
                    inExponent = false;
                } else if (strPtr[0] == ':') {
                    // End of label
                    bufPtr[1] = 0;
                    strWidth += stringWidth(bufPtr, &standardFont, true, true);
                    bufPtr[1] = ' ';
                    bufPtr[2] = 0;
                    doubleBytednessHistory <<= 1;
                    bufPtr += 1;
                    inLabel = false;
                } else if ((!inLabel) and unaryMinus and strPtr[0] == '-') {
                    // Unary minus
                    if (strLength > 1) {
                        _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
                    }
                    bufPtr[0] = strPtr[0];
                    bufPtr[1] = 0;
                    unaryMinus = false;
                    inExponent = false;
                } else if ((!inLabel) and strPtr[0] == '(') {
                    // Opening parenthesis
                    bufPtr[1] = 0;
                    strWidth += stringWidth(bufPtr, &standardFont, true, true);
                    bufPtr[1] = STD_SPACE_PUNCTUATION[0];
                    bufPtr[2] = STD_SPACE_PUNCTUATION[1];
                    bufPtr[3] = 0;
                    doubleBytednessHistory <<= 1;
                    doubleBytednessHistory |= 1;
                    bufPtr += 1;
                    unaryMinus = true;
                    inNumeric = true;
                    beginningOfNumber = true;
                    inExponent = false;
                } else if ((!inLabel) and (cursorAt == EQUATION_NO_CURSOR and strPtr[0] == '^' and blk: {
                    tmpVal = _checkExponent(strPtr + 1);
                    break :blk tmpVal != 0;
                })) {
                    // Power (if not editing)
                    var i: u32 = 0;
                    while (i < tmpVal) : (i += 1) {
                        _showExponent(&bufPtr, &strPtr, &strWidth);
                    }
                    bufPtr[0] = 0;
                    bufPtr -= 2;
                    strWidth -= stringWidth(bufPtr, &standardFont, true, true);
                    doubleBytednessHistory |= 1;
                    i = 1;
                    while (i < tmpVal) : (i += 1) {
                        doubleBytednessHistory <<= 1;
                        doubleBytednessHistory |= 1;
                    }
                    unaryMinus = false;
                    inExponent = false;
                } else if ((!inLabel) and (strPtr[0] == ')' or strPtr[0] == '^')) {
                    // Closing parenthesis or power (when editing)
                    _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
                    bufPtr[0] = strPtr[0];
                    bufPtr[1] = 0;
                    unaryMinus = false;
                    inExponent = false;
                } else if ((!inLabel) and inNumeric and inExponent and (strPtr[0] == '+' or strPtr[0] == '-')) {
                    // Sign of exponent
                    bufPtr[1] = 0;
                    unaryMinus = false;
                    inNumeric = false;
                    beginningOfNumber = false;
                    inExponent = false;
                } else if ((!inLabel) and (strPtr[0] == '=' or strPtr[0] == '+' or strPtr[0] == '-' or strPtr[0] == '/' or strPtr[0] == '!' or strPtr[0] == '|')) {
                    // Operators
                    if (strPtr[0] != '|' or (strLength > (startAt + 1))) {
                        _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
                    }
                    bufPtr[0] = strPtr[0];
                    bufPtr[1] = 0;
                    strWidth += stringWidth(bufPtr, &standardFont, true, true);
                    bufPtr[1] = STD_SPACE_PUNCTUATION[0];
                    bufPtr[2] = STD_SPACE_PUNCTUATION[1];
                    bufPtr[3] = 0;
                    doubleBytednessHistory <<= 1;
                    doubleBytednessHistory |= 1;
                    bufPtr += 1;
                    unaryMinus = false;
                    inNumeric = true;
                    beginningOfNumber = true;
                    inExponent = false;
                } else if ((!inLabel) and (compareChar(strPtr, STD_CROSS) == 0 or compareChar(strPtr, STD_DOT) == 0)) {
                    // Multiply
                    _addSpace(&bufPtr, &strWidth, &doubleBytednessHistory);
                    const ps = PRODUCT_SIGN();
                    bufPtr[0] = ps[0];
                    bufPtr[1] = ps[1];
                    bufPtr[2] = 0;
                    strWidth += stringWidth(bufPtr, &standardFont, true, true);
                    bufPtr[2] = STD_SPACE_PUNCTUATION[0];
                    bufPtr[3] = STD_SPACE_PUNCTUATION[1];
                    bufPtr[4] = 0;
                    doubleBytednessHistory <<= 1;
                    doubleBytednessHistory |= 3;
                    bufPtr += 2;
                    unaryMinus = false;
                    inNumeric = true;
                    beginningOfNumber = true;
                    inExponent = false;
                } else if ((!inLabel) and ((strPtr[0] >= '0' and strPtr[0] <= '9') or strPtr[0] == '.' or strPtr[0] == ',')) {
                    // Numbers
                    bufPtr[1] = 0;
                    unaryMinus = false;
                    inExponent = false;
                    beginningOfNumber = false;
                } else if ((!inLabel) and inNumeric and (!beginningOfNumber) and (!inExponent) and (strPtr[0] == 'E')) {
                    // Exponent
                    if (cursorAt == EQUATION_NO_CURSOR) {
                        const ps = PRODUCT_SIGN();
                        bufPtr[0] = ps[0];
                        bufPtr[1] = ps[1];
                        bufPtr[2] = STD_SUB_10[0];
                        bufPtr[3] = STD_SUB_10[1];
                        bufPtr[4] = 0;
                        doubleBytednessHistory <<= 1;
                        doubleBytednessHistory |= 3;
                        strWidth += stringWidth(bufPtr, &standardFont, true, true);
                        bufPtr += 4;
                        tmpVal = _checkExponent(strPtr + 1);
                        var i: u32 = 0;
                        while (i < tmpVal) : (i += 1) {
                            _showExponent(&bufPtr, &strPtr, &strWidth);
                        }
                        bufPtr[0] = 0;
                        bufPtr -= 2;
                        strWidth -= stringWidth(bufPtr, &standardFont, true, true);
                        i = 0;
                        while (i < tmpVal) : (i += 1) {
                            doubleBytednessHistory <<= 1;
                            doubleBytednessHistory |= 1;
                        }
                        unaryMinus = false;
                        inExponent = false;
                        beginningOfNumber = false;
                    } else {
                        bufPtr[1] = 0;
                        unaryMinus = false;
                        inExponent = true;
                        beginningOfNumber = false;
                    }
                } else if ((strPtr[0] & 0x80) != 0) {
                    // Other double-byte characters
                    bufPtr[1] = (strPtr + 1)[0];
                    bufPtr[2] = 0;
                    doubleBytednessHistory |= 1;
                    unaryMinus = false;
                    inNumeric = false;
                    inExponent = false;
                    beginningOfNumber = false;
                } else {
                    // Other single-byte characters
                    bufPtr[1] = 0;
                    unaryMinus = false;
                    inNumeric = false;
                    inExponent = false;
                    beginningOfNumber = false;
                }

                // Add the character
                glyphWidth = stringWidth(bufPtr, &standardFont, true, true);
                strWidth += glyphWidth;

                // Cursor
                if (strLength == cursorAt) {
                    bufPtr += if ((doubleBytednessHistory & 0x00000001) != 0) @as(usize, 2) else @as(usize, 1);
                    bufPtr[0] = STD_CURSOR[0];
                    bufPtr[1] = STD_CURSOR[1];
                    bufPtr[2] = 0;
                    glyphWidth = stringWidth(bufPtr, &standardFont, true, true);
                    strWidth += glyphWidth;
                    doubleBytednessHistory <<= 1;
                    doubleBytednessHistory |= 1;
                    cursorShown.* = true;
                }

                // Trailing ellipsis
                if (strWidth > (SCREEN_WIDTH - 2 - X_OFF)) {
                    glyphWidth = stringWidth(STD_ELLIPSIS, &standardFont, true, true);
                    while (true) {
                        if (bufPtr[0] == STD_CURSOR[0] and bufPtr[1] == STD_CURSOR[1]) {
                            cursorShown.* = false;
                        }
                        strWidth -= stringWidth(bufPtr, &standardFont, true, true);
                        bufPtr[0] = 0;
                        if ((strWidth + glyphWidth) <= (SCREEN_WIDTH - 2 - X_OFF)) {
                            break;
                        }
                        doubleBytednessHistory >>= 1;
                        bufPtr -= if ((doubleBytednessHistory & 0x00000001) != 0) @as(usize, 2) else @as(usize, 1);
                    }
                    bufPtr[0] = STD_ELLIPSIS[0];
                    bufPtr[1] = STD_ELLIPSIS[1];
                    bufPtr[2] = 0;
                    rightEllipsis.* = true;
                    break;
                }

                // Increment bufPtr
                bufPtr += if ((doubleBytednessHistory & 0x00000001) != 0) @as(usize, 2) else @as(usize, 1);
            }
            strPtr += if ((strPtr[0] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
        }

        if ((!dryRun) and (cursorShown.* or cursorAt == EQUATION_NO_CURSOR)) {
            _ = showString(tmpString, &standardFont, @intCast(1 + X_OFF), @intCast(SCREEN_HEIGHT - SOFTMENU_HEIGHT * 3 + 2), vmNormal, true, true);
        }
    }
}

// ===========================================================================
// _menuItem
// ===========================================================================
fn _menuItem(item: i16, bufPtr: [*c]u8) linksection(runtime.code_section) void {
    const name = &indexOfItems[@intCast(item)].itemSoftmenuName[0];
    _ = xcopy(bufPtr, name, @intCast(stringByteLength(name) + 1));
    bufPtr[@intCast(stringByteLength(name) + 1)] = 0;
}

// ===========================================================================
// parser stack helpers (operate on mvarBuffer)
// ===========================================================================
inline fn PARSER_OPERATOR_STACK(mvarBuffer: [*c]u8) [*]u16 {
    return @ptrCast(@alignCast(mvarBuffer));
}
inline fn PARSER_NUMERIC_STACK(mvarBuffer: [*c]u8) [*]align(1) real34_t {
    return @ptrCast(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2 + REAL34_SIZE_IN_BYTES * 2);
}
inline fn PARSER_LEFT_VALUE_REAL(mvarBuffer: [*c]u8) *align(1) real34_t {
    return @ptrCast(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2);
}
inline fn PARSER_LEFT_VALUE_IMAG(mvarBuffer: [*c]u8) *align(1) real34_t {
    return @ptrCast(mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2 + REAL34_SIZE_IN_BYTES);
}
inline fn PARSER_NUMERIC_STACK_POINTER(mvarBuffer: [*c]u8) [*]u8 {
    return mvarBuffer + PARSER_OPERATOR_STACK_SIZE * 2 + REAL34_SIZE_IN_BYTES * (2 + 2 * PARSER_NUMERIC_STACK_SIZE);
}

fn _operatorPriority(func: u16) linksection(runtime.code_section) u32 {
    switch (func) {
        ITM_MULT, ITM_DIV => {
            return 8;
        },
        ITM_ADD, ITM_SUB => {
            return 10;
        },
        PARSER_OPERATOR_ITM_YX => {
            return 7;
        },
        PARSER_OPERATOR_ITM_XFACT => {
            return 5;
        },
        PARSER_OPERATOR_ITM_PARENTHESIS_LEFT, PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT, PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT, PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT, PARSER_OPERATOR_ITM_EQUAL => {
            return 1;
        },
        else => {
            return 3;
        },
    }
}

fn _pushNumericStack(mvarBuffer: [*c]u8, re: *align(1) const real34_t, im: *align(1) const real34_t) linksection(runtime.code_section) void {
    const sp = PARSER_NUMERIC_STACK_POINTER(mvarBuffer);
    const stack = PARSER_NUMERIC_STACK(mvarBuffer);
    if (sp[0] < PARSER_NUMERIC_STACK_SIZE) {
        real34Copy(re, &stack[@as(usize, sp[0]) * 2]);
        real34Copy(im, &stack[@as(usize, sp[0]) * 2 + 1]);
        sp[0] += 1;
    } else {
        displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}

fn _popNumericStack(mvarBuffer: [*c]u8, re: *align(1) real34_t, im: ?*align(1) real34_t) linksection(runtime.code_section) void {
    const sp = PARSER_NUMERIC_STACK_POINTER(mvarBuffer);
    const stack = PARSER_NUMERIC_STACK(mvarBuffer);
    if (sp[0] > 0) {
        sp[0] -= 1;
        real34Copy(&stack[@as(usize, sp[0]) * 2], re);
        if (im) |imp| {
            real34Copy(&stack[@as(usize, sp[0]) * 2 + 1], imp);
        }
    } else {
        displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        realToReal34(const_NaN(), re);
        if (im) |imp| {
            realToReal34(const_NaN(), imp);
        }
    }
}

fn _runDyadicFunction(mvarBuffer: [*c]u8, item: u16) linksection(runtime.code_section) void {
    var re: real34_t = undefined;
    var im: real34_t = undefined;
    liftStack();
    clearRegister(REGISTER_X);
    liftStack();

    _popNumericStack(mvarBuffer, &re, &im);
    if (real34IsZero(&im) or real34IsNaN(&im)) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        real34Copy(&re, registerReal34Ptr(REGISTER_X));
    } else {
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        real34Copy(&re, registerReal34Ptr(REGISTER_X));
        real34Copy(&im, registerImag34Ptr(REGISTER_X));
    }

    _popNumericStack(mvarBuffer, &re, &im);
    if (real34IsZero(&im) or real34IsNaN(&im)) {
        reallocateRegister(REGISTER_Y, dtReal34, 0, amNone);
        real34Copy(&re, registerReal34Ptr(REGISTER_Y));
    } else {
        reallocateRegister(REGISTER_Y, dtComplex34, 0, amNone);
        real34Copy(&re, registerReal34Ptr(REGISTER_Y));
        real34Copy(&im, registerImag34Ptr(REGISTER_Y));
    }

    runFunction(@bitCast(item));

    if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), registerImag34Ptr(REGISTER_X));
    } else {
        fnToReal(NOPARAM);
        _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), const34_0());
    }
    fnDrop(NOPARAM);
}

fn _runMonadicFunction(mvarBuffer: [*c]u8, item: u16) linksection(runtime.code_section) void {
    var re: real34_t = undefined;
    var im: real34_t = undefined;
    liftStack();
    clearRegister(REGISTER_X);

    _popNumericStack(mvarBuffer, &re, &im);
    if (real34IsZero(&im) or real34IsNaN(&im)) {
        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
        real34Copy(&re, registerReal34Ptr(REGISTER_X));
    } else {
        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
        real34Copy(&re, registerReal34Ptr(REGISTER_X));
        real34Copy(&im, registerImag34Ptr(REGISTER_X));
    }

    runFunction(@bitCast(item));
    temporaryInformation = TI_NO_INFO;

    if (getRegisterDataType(REGISTER_X) == dtComplex34) {
        _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), registerImag34Ptr(REGISTER_X));
    } else {
        fnToReal(NOPARAM);
        _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), const34_0());
    }
    fnDrop(NOPARAM);
}

pub export fn isDyadicFunction(item: u16) linksection(runtime.code_section) callconv(.c) bool {
    switch (item) {
        PARSER_OPERATOR_ITM_YX, ITM_COMB, ITM_PERM, ITM_YX, ITM_LOGXY, ITM_ADD, ITM_SUB, ITM_MULT, ITM_DIV, ITM_IDIV, ITM_MOD, ITM_MAX, ITM_MIN, ITM_RMD, ITM_HN, ITM_HNP, ITM_Lm, ITM_LmALPHA, ITM_Pn, ITM_Tn, ITM_Un, ITM_atan2, ITM_XTHROOT => {
            return true;
        },
        else => {
            return false;
        },
    }
}

fn _runEqFunction(mvarBuffer: [*c]u8, item: u16) linksection(runtime.code_section) void {
    if (isDyadicFunction(item)) {
        _runDyadicFunction(mvarBuffer, item);
    } else {
        _runMonadicFunction(mvarBuffer, item);
    }
}

fn _processOperator(func: u16, mvarBuffer: [*c]u8) linksection(runtime.code_section) void {
    const opStack = PARSER_OPERATOR_STACK(mvarBuffer);
    var opStackTop: u32 = 0xffffffff;
    {
        var i: u32 = 0;
        while (i < PARSER_OPERATOR_STACK_SIZE) : (i += 1) {
            if ((i == PARSER_OPERATOR_STACK_SIZE) or (opStack[i] == 0)) {
                opStackTop = i;
                break;
            }
        }
    }
    if (opStackTop != 0xffffffff) {
        // flush operator stack: closing parenthesis, equal, or end of formula
        if (func == PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT or func == PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT or func == PARSER_OPERATOR_ITM_EQUAL or func == PARSER_OPERATOR_ITM_END_OF_FORMULA) {
            var i: i32 = @as(i32, @intCast(opStackTop)) - 1;
            outer: while (i >= 0) : (i -= 1) {
                const iu: usize = @intCast(i);
                switch (opStack[iu]) {
                    PARSER_OPERATOR_ITM_PARENTHESIS_LEFT => {
                        if (func == PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT) {
                            displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        }
                    },
                    PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT => {
                        _runEqFunction(mvarBuffer, ITM_MAGNITUDE);
                        if (func == PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT) {
                            displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        }
                    },
                    PARSER_OPERATOR_ITM_YX => {
                        _runEqFunction(mvarBuffer, ITM_YX);
                    },
                    PARSER_OPERATOR_ITM_XFACT => {
                        _runEqFunction(mvarBuffer, ITM_XFACT);
                    },
                    else => {
                        _runEqFunction(mvarBuffer, opStack[iu]);
                    },
                }
                switch (opStack[iu]) {
                    ITM_ADD, ITM_SUB, ITM_MULT, ITM_DIV, PARSER_OPERATOR_ITM_YX, PARSER_OPERATOR_ITM_XFACT => {
                        opStack[iu] = 0;
                    },
                    else => {
                        opStack[iu] = 0;
                        if (func == PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT or func == PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT) {
                            return;
                        }
                        displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        break :outer;
                    },
                }
            }
            switch (func) {
                PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT => {
                    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT => {
                    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                },
                PARSER_OPERATOR_ITM_EQUAL => {
                    fnToReal(NOPARAM);
                    _popNumericStack(mvarBuffer, PARSER_LEFT_VALUE_REAL(mvarBuffer), PARSER_LEFT_VALUE_IMAG(mvarBuffer));
                },
                else => {
                    setSystemFlag(FLAG_ASLIFT);
                    liftStack();
                    const sp = PARSER_NUMERIC_STACK_POINTER(mvarBuffer);
                    const stack = PARSER_NUMERIC_STACK(mvarBuffer);
                    const leftReal = PARSER_LEFT_VALUE_REAL(mvarBuffer);
                    const leftImag = PARSER_LEFT_VALUE_IMAG(mvarBuffer);
                    if ((real34IsZero(leftImag) or real34IsNaN(leftImag)) and (real34IsZero(&stack[@as(usize, sp[0]) * 2 - 1]) or real34IsNaN(&stack[@as(usize, sp[0]) * 2 - 1]))) {
                        reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
                        real34Subtract(&stack[@as(usize, sp[0]) * 2 - 2], leftReal, registerReal34Ptr(REGISTER_X));
                    } else {
                        reallocateRegister(REGISTER_X, dtComplex34, 0, amNone);
                        real34Subtract(&stack[@as(usize, sp[0]) * 2 - 2], leftReal, registerReal34Ptr(REGISTER_X));
                        real34Subtract(&stack[@as(usize, sp[0]) * 2 - 1], leftImag, registerImag34Ptr(REGISTER_X));
                    }
                    sp[0] -= 1;
                },
            }
            return;
        }

        // stack is empty
        if (opStackTop == 0) {
            opStack[0] = func;
            return;
        }

        // other cases
        var i: u32 = opStackTop;
        while (i > 0) : (i -= 1) {
            // factorial
            if (func == PARSER_OPERATOR_ITM_XFACT) {
                _runEqFunction(mvarBuffer, ITM_XFACT);
                return;
            }
            // push an operator
            else if ((_operatorPriority(opStack[i - 1]) < 4) // parenthesis
            or (_operatorPriority(opStack[i - 1]) & (~@as(u32, 1))) > (_operatorPriority(func) & (~@as(u32, 1))) // higher priority
            or ((_operatorPriority(opStack[i - 1]) & (~@as(u32, 1))) == (_operatorPriority(func) & (~@as(u32, 1))) and (_operatorPriority(func) & 1) != 0)) { // same priority and right-associative
                if (i < PARSER_OPERATOR_STACK_SIZE) {
                    opStack[i] = func;
                } else {
                    displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                }
                return;
            }
            // pop an operator
            else {
                _runEqFunction(mvarBuffer, if (opStack[i - 1] == PARSER_OPERATOR_ITM_YX) ITM_YX else if (opStack[i - 1] == PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT) ITM_MAGNITUDE else opStack[i - 1]);
                if (i == 1) {
                    opStack[i - 1] = func;
                    return;
                } else {
                    opStack[i - 1] = 0;
                }
            }
        }
    } else {
        displayCalcErrorMessage(ERROR_EQUATION_TOO_COMPLEX, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    }
}

fn _parseWord(strPtr: [*c]u8, parseMode: u16, parserHint: u16, mvarBuffer: [*c]u8, pointerInFormula: [*c]const u8) linksection(runtime.code_section) void {
    var tmpVal: u32 = 0;
    if (parserHint != PARSER_HINT_NUMERIC and stringGlyphLength(strPtr) > 7) {
        displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return;
    }
    if (strPtr[0] == 0) {
        return;
    }

    switch (parseMode) {
        EQUATION_PARSER_MVAR => {
            if (parserHint == PARSER_HINT_VARIABLE) {
                if (updateOldConstants) { // Need to update constants format by adding a # prefix
                    var ci: u32 = FIRST_CONSTANT;
                    while (ci <= LAST_CONSTANT) : (ci += 1) {
                        if (compareString(&indexOfItems[ci].itemCatalogName[0], strPtr, CMP_NAME) == 0) {
                            var formulaPtr: [*c]u8 = mvarBuffer + strlen(mvarBuffer);
                            var k: u16 = 0;
                            const lim: u16 = @intCast(strlen(pointerInFormula) + 1);
                            while (k < lim) : (k += 1) { // insert # in formula buffer
                                formulaPtr[1] = formulaPtr[0];
                                formulaPtr[0] = '#';
                                formulaPtr -= 1;
                            }
                            break;
                        }
                    }
                    return;
                }
                var bufPtr: [*c]u8 = mvarBuffer;
                if (compareString(STD_pi, strPtr, CMP_NAME) == 0) { // check for pi
                    return;
                }
                if (compareString(STD_i, strPtr, CMP_NAME) == 0 or compareString(STD_j, strPtr, CMP_NAME) == 0 or compareString(STD_op_i, strPtr, CMP_NAME) == 0 or compareString(STD_op_j, strPtr, CMP_NAME) == 0) { // check for i
                    return;
                }
                while (bufPtr[0] != 0) { // check for duplicates
                    if (compareString(bufPtr, strPtr, CMP_NAME) == 0) {
                        return;
                    }
                    bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                    tmpVal += 1;
                }
                if (strPtr[0] == '#') { // check for constants
                    var ci: u32 = FIRST_CONSTANT;
                    while (ci <= LAST_CONSTANT) : (ci += 1) {
                        if (compareString(&indexOfItems[ci].itemCatalogName[0], strPtr + 1, CMP_NAME) == 0) {
                            return;
                        }
                    }
                }
                if (validateName(@ptrCast(strPtr))) {
                    const variable: calcRegister_t = findOrAllocateNamedVariable(@ptrCast(strPtr));
                    _ = xcopy(bufPtr, strPtr, @intCast(stringByteLength(strPtr) + 1));
                    bufPtr += @as(usize, @intCast(stringByteLength(strPtr) + 1));
                    bufPtr[0] = 0;
                    if (((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER or (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_GRAPHER) and @as(u16, @bitCast(variable)) >= FIRST_RESERVED_VARIABLE) {
                        displayCalcErrorMessage(ERROR_RESERVED_VARIABLE_NAME, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        _ = xcopy(errorMessage, strPtr, @intCast(stringByteLength(strPtr) + 1));
                        screenUpdatingMode = SCRUPD_AUTO;
                        refreshRegisterLine(ERR_REGISTER_LINE);
                    } else {
                        if (tmpVal == 3 and ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE)) {
                            _menuItem(MNU_Sf_TOOL, bufPtr);
                            bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                            _menuItem(ITM_INTEGRAL_YX, bufPtr);
                        } else if (tmpVal == 3 and ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_GRAPHER)) {
                            _menuItem(MNU_GRAPHS, bufPtr);
                            bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                            _menuItem(ITM_DRAW, bufPtr);
                        } else if (tmpVal == 3 and ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER)) {
                            _menuItem(MNU_Solver_TOOL, bufPtr);
                            bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                            _menuItem(ITM_CALC, bufPtr);
                        } else if (tmpVal == 3 and ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE)) {
                            _menuItem(MNU_GRAPHS, bufPtr);
                            bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                            _menuItem(ITM_FPHERE, bufPtr);
                        } else if (tmpVal == 3 and ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE)) {
                            _menuItem(MNU_GRAPHS, bufPtr);
                            bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                            _menuItem(ITM_FPPHERE, bufPtr);
                        }
                    }
                } else {
                    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                }
            }
        },
        EQUATION_PARSER_XEQ => {
            if (parserHint == PARSER_HINT_VARIABLE) {
                if (compareString(STD_pi, strPtr, CMP_NAME) == 0) { // check for pi
                    runFunction(ITM_CONSTpi);
                    _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), const34_0());
                    fnDrop(NOPARAM);
                    return;
                }
                if (compareString(STD_i, strPtr, CMP_NAME) == 0 or compareString(STD_j, strPtr, CMP_NAME) == 0 or compareString(STD_op_i, strPtr, CMP_NAME) == 0 or compareString(STD_op_j, strPtr, CMP_NAME) == 0) { // check for i
                    runFunction(ITM_op_j);
                    _pushNumericStack(mvarBuffer, const34_0(), const34_1());
                    fnDrop(NOPARAM);
                    return;
                }
                if (strPtr[0] == '#') { // check for constants
                    var ci: u32 = FIRST_CONSTANT;
                    while (ci <= LAST_CONSTANT) : (ci += 1) {
                        if (compareString(&indexOfItems[ci].itemCatalogName[0], strPtr + 1, CMP_NAME) == 0) {
                            runFunction(@intCast(ci));
                            _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), const34_0());
                            fnDrop(NOPARAM);
                            return;
                        }
                    }
                }
                if (validateName(@ptrCast(strPtr))) {
                    reallyRunFunction(ITM_RCL, @bitCast(@as(i16, @truncate(findNamedVariable(@ptrCast(strPtr))))));
                    if (getRegisterDataType(REGISTER_X) == dtComplex34) {
                        _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), registerImag34Ptr(REGISTER_X));
                    } else {
                        fnToReal(NOPARAM);
                        _pushNumericStack(mvarBuffer, registerReal34Ptr(REGISTER_X), const34_0());
                    }
                    fnDrop(NOPARAM);
                } else {
                    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                }
            } else if (parserHint == PARSER_HINT_NUMERIC) {
                var val: real34_t = undefined;
                var jj: i16 = @truncate(stringByteLength(strPtr));
                while (jj >= 0) {
                    if (strPtr[@intCast(jj)] == ',') {
                        strPtr[@intCast(jj)] = '.';
                    }
                    jj -= 1;
                }
                stringToReal34(@ptrCast(strPtr), &val);
                _pushNumericStack(mvarBuffer, &val, const34_0());
            } else if (parserHint == PARSER_HINT_OPERATOR) {
                if (compareString("+", strPtr, CMP_BINARY) == 0) {
                    _processOperator(ITM_ADD, mvarBuffer);
                } else if (compareString("-", strPtr, CMP_BINARY) == 0) {
                    _processOperator(ITM_SUB, mvarBuffer);
                } else if (compareString(STD_CROSS, strPtr, CMP_BINARY) == 0 or compareString(STD_DOT, strPtr, CMP_BINARY) == 0) {
                    _processOperator(ITM_MULT, mvarBuffer);
                } else if (compareString("/", strPtr, CMP_BINARY) == 0) {
                    _processOperator(ITM_DIV, mvarBuffer);
                } else if (compareString("^", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_YX, mvarBuffer);
                } else if (compareString("!", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_XFACT, mvarBuffer);
                } else if (compareString("(", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_PARENTHESIS_LEFT, mvarBuffer);
                } else if (compareString(")", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_PARENTHESIS_RIGHT, mvarBuffer);
                } else if (compareString("|", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_VERTICAL_BAR_LEFT, mvarBuffer);
                } else if (compareString("|)", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_VERTICAL_BAR_RIGHT, mvarBuffer);
                } else if (compareString("=", strPtr, CMP_BINARY) == 0) {
                    _processOperator(PARSER_OPERATOR_ITM_EQUAL, mvarBuffer);
                } else if (compareString(":", strPtr, CMP_BINARY) == 0) {
                    // label or parameter separator will be skipped
                } else {
                    displayBugScreen(bugScreenUnknownOperator);
                }
            } else if (parserHint == PARSER_HINT_FUNCTION) {
                {
                    var i: usize = 0;
                    while (i < functionAlias.len) : (i += 1) {
                        if (compareString(functionAlias[i].name.ptr, strPtr, CMP_NAME) == 0) {
                            _processOperator(functionAlias[i].opCode, mvarBuffer);
                            return;
                        }
                    }
                }
                {
                    var i: u32 = 1;
                    while (i < LAST_ITEM) : (i += 1) {
                        if (((indexOfItems[i].status & EIM_STATUS) == EIM_ENABLED) and (indexOfItems[i].param <= NOPARAM) and (compareString(&indexOfItems[i].itemCatalogName[0], strPtr, CMP_NAME) == 0)) {
                            _processOperator(@intCast(i), mvarBuffer);
                            return;
                        }
                    }
                }
                {
                    var i: u32 = 1;
                    while (i < LAST_ITEM) : (i += 1) {
                        if (((indexOfItems[i].status & EIM_STATUS) == EIM_ENABLED) and (indexOfItems[i].param <= NOPARAM) and (compareString(&indexOfItems[i].itemSoftmenuName[0], strPtr, CMP_NAME) == 0)) {
                            _processOperator(@intCast(i), mvarBuffer);
                            return;
                        }
                    }
                }
                displayCalcErrorMessage(ERROR_FUNCTION_NOT_FOUND, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            }
        },
        else => {
            displayBugScreen(bugScreenUnknownFormulaParserMode);
        },
    }
}

pub export fn parseEquation(equationId: u16, parseMode: u16, buffer: [*c]u8, mvarBuffer: [*c]u8) linksection(runtime.code_section) callconv(.c) void {
    var strPtr: [*c]const u8 = TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData);
    var bufPtr: [*c]u8 = buffer;
    var pointerInFormula: [*c]const u8 = strPtr;
    var numericCount: i16 = 0;
    var equalAppeared: bool_t = false;
    var labeled: bool_t = false;
    var afterClosingParenthesis: bool_t = false;
    var unaryMinusCanOccur: bool_t = true;
    var afterSpace: bool_t = false;
    var inExponent: bool_t = false;
    var exponentSignCanOccur: bool_t = false;

    if (!updateOldConstants) {
        const opStack = PARSER_OPERATOR_STACK(mvarBuffer);
        var i: u32 = 0;
        while (i < PARSER_OPERATOR_STACK_SIZE) : (i += 1) {
            opStack[i] = 0;
        }
        real34SetZero(PARSER_LEFT_VALUE_REAL(mvarBuffer));
        real34SetZero(PARSER_LEFT_VALUE_IMAG(mvarBuffer));
        const stack = PARSER_NUMERIC_STACK(mvarBuffer);
        i = 0;
        while (i < PARSER_NUMERIC_STACK_SIZE) : (i += 1) {
            realToReal34(const_NaN(), &stack[i * 2]);
            realToReal34(const_NaN(), &stack[i * 2 + 1]);
        }
        PARSER_NUMERIC_STACK_POINTER(mvarBuffer)[0] = 0;
    }

    {
        var i: u32 = 0;
        while (i < 7) : (i += 1) {
            strPtr += if ((strPtr[0] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
            if (strPtr[0] == ':') {
                labeled = true;
                strPtr += 1;
                break;
            } else if (strPtr[0] == '(') {
                labeled = false;
                break;
            }
        }
    }
    if (!labeled) {
        strPtr = TO_PCMEMPTR(allFormulae[equationId].pointerToFormulaData);
    }

    while (strPtr[0] != 0) {
        while (strPtr[0] == ' ') {
            afterSpace = true;
            strPtr += 1;
        }

        sw: switch (strPtr[0]) {
            ';' => {
                displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                return;
            },

            '(' => {
                if (bufPtr != buffer) {
                    bufPtr[0] = 0;
                    bufPtr += 1;
                    strPtr += 1;
                    if (stringGlyphLength(buffer) == numericCount) {
                        displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                        return;
                    } else {
                        _parseWord(buffer, parseMode, PARSER_HINT_FUNCTION, mvarBuffer, pointerInFormula);
                        bufPtr = buffer;
                        buffer[0] = 0;
                        pointerInFormula = strPtr;
                        numericCount = 0;
                        afterClosingParenthesis = false;
                        unaryMinusCanOccur = true;
                        afterSpace = false;
                        inExponent = false;
                        exponentSignCanOccur = false;
                        break :sw;
                    }
                }
                continue :sw '=';
            },

            '=', '+', '-', '/', ')', '^', '!', ':', '|' => {
                if (equalAppeared and (strPtr[0] == '=')) {
                    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                    return;
                } else if ((bufPtr != buffer) and (strPtr[0] == '|')) {
                    bufPtr[0] = 0;
                    bufPtr += 1;
                    _parseWord(buffer, parseMode, PARSER_HINT_REGULAR(buffer, numericCount), mvarBuffer, pointerInFormula);
                    bufPtr = buffer;
                    pointerInFormula = strPtr;
                    numericCount = 0;
                    bufPtr[0] = '|';
                    bufPtr += 1;
                    bufPtr[0] = ')';
                    bufPtr += 1;
                    bufPtr[0] = 0;
                    afterClosingParenthesis = true;
                    unaryMinusCanOccur = false;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                } else if (strPtr[0] == '^' and strPtr[1] == '(' and (@intFromPtr(bufPtr) - @intFromPtr(buffer)) == 2 and buffer[0] == STD_EulerE[0] and buffer[1] == STD_EulerE[1]) {
                    // 'Euler e' (fancy e) as a function
                    _ = strcpy(buffer, "EXP");
                    strPtr += 2;
                    _parseWord(buffer, parseMode, PARSER_HINT_FUNCTION, mvarBuffer, pointerInFormula);
                    bufPtr = buffer;
                    buffer[0] = 0;
                    pointerInFormula = strPtr;
                    numericCount = 0;
                    afterClosingParenthesis = false;
                    unaryMinusCanOccur = true;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                    break :sw;
                } else if (exponentSignCanOccur and (strPtr[0] == '+' or strPtr[0] == '-')) {
                    // exponent sign
                    bufPtr[0] = strPtr[0];
                    bufPtr += 1;
                    strPtr += 1;
                    numericCount += 1;
                    afterClosingParenthesis = false;
                    unaryMinusCanOccur = false;
                    afterSpace = false;
                    inExponent = true;
                    exponentSignCanOccur = false;
                    break :sw;
                } else if (bufPtr != buffer) {
                    bufPtr[0] = 0;
                    bufPtr += 1;
                    _parseWord(buffer, parseMode, PARSER_HINT_REGULAR(buffer, numericCount), mvarBuffer, pointerInFormula);
                    afterClosingParenthesis = (strPtr[0] == ')');
                    unaryMinusCanOccur = false;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                } else if (unaryMinusCanOccur and strPtr[0] == '-') {
                    // unary minus
                    buffer[0] = '-';
                    buffer[1] = '1';
                    buffer[2] = 0;
                    _parseWord(buffer, parseMode, PARSER_HINT_NUMERIC, mvarBuffer, pointerInFormula);
                    const ps = PRODUCT_SIGN();
                    buffer[0] = ps[0];
                    buffer[1] = ps[1];
                    buffer[2] = 0;
                    _parseWord(buffer, parseMode, PARSER_HINT_OPERATOR, mvarBuffer, pointerInFormula);
                    bufPtr = buffer;
                    buffer[0] = 0;
                    pointerInFormula = strPtr;
                    numericCount = 0;
                    afterClosingParenthesis = false;
                    unaryMinusCanOccur = false;
                    strPtr += 1;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                    break :sw;
                } else if ((strPtr[0] == '(') or (strPtr[0] == '|' and !afterClosingParenthesis)) {
                    afterClosingParenthesis = false;
                    unaryMinusCanOccur = true;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                } else if (strPtr[0] == ')' or strPtr[0] == '|') {
                    if (strPtr[0] == '|') {
                        bufPtr = buffer;
                        pointerInFormula = strPtr;
                        numericCount = 0;
                        bufPtr[0] = '|';
                        bufPtr += 1;
                        bufPtr[0] = ')';
                        bufPtr += 1;
                        bufPtr[0] = 0;
                    }
                    afterClosingParenthesis = true;
                    unaryMinusCanOccur = false;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                } else if (afterClosingParenthesis and strPtr[0] != ':') {
                    afterClosingParenthesis = false;
                    unaryMinusCanOccur = false;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                } else {
                    displayCalcErrorMessage(ERROR_SYNTAX_ERROR_IN_EQUATION, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                    return;
                }

                if (strPtr[0] == '=') {
                    equalAppeared = true;
                    unaryMinusCanOccur = true;
                    afterSpace = false;
                    inExponent = false;
                    exponentSignCanOccur = false;
                }

                if (compareString("|)", buffer, CMP_BINARY) != 0) {
                    buffer[0] = strPtr[0];
                    strPtr += 1;
                    buffer[1] = 0;
                } else {
                    strPtr += 1;
                }
                _parseWord(buffer, parseMode, PARSER_HINT_OPERATOR, mvarBuffer, pointerInFormula);
                bufPtr = buffer;
                buffer[0] = 0;
                pointerInFormula = strPtr;
                numericCount = 0;
                inExponent = false;
                exponentSignCanOccur = false;
                break :sw;
            },

            else => {
                if (afterSpace) {
                    bufPtr[0] = 0;
                    bufPtr += 1;
                    _parseWord(buffer, parseMode, PARSER_HINT_REGULAR(buffer, numericCount), mvarBuffer, pointerInFormula);
                    bufPtr = buffer;
                    pointerInFormula = strPtr;
                    numericCount = 0;
                    afterSpace = false;
                }

                if ((strPtr[0] >= '0' and strPtr[0] <= '9') or strPtr[0] == '.' or strPtr[0] == ',') {
                    numericCount += 1;
                    exponentSignCanOccur = false;
                } else if ((!inExponent) and (strPtr[0] == 'E') and (numericCount != 0) and blk: {
                    bufPtr[0] = 0;
                    break :blk numericCount == stringGlyphLength(buffer);
                }) {
                    numericCount += 1;
                    inExponent = true;
                    exponentSignCanOccur = true;
                } else {
                    inExponent = false;
                    exponentSignCanOccur = false;
                }

                if (compareChar(strPtr, STD_CROSS) == 0 or compareChar(strPtr, STD_DOT) == 0) {
                    bufPtr[0] = 0;
                    bufPtr += 1;
                    _parseWord(buffer, parseMode, PARSER_HINT_REGULAR(buffer, numericCount), mvarBuffer, pointerInFormula);
                    buffer[0] = strPtr[0];
                    strPtr += 1;
                    buffer[1] = strPtr[0];
                    strPtr += 1;
                    buffer[2] = 0;
                    _parseWord(buffer, parseMode, PARSER_HINT_OPERATOR, mvarBuffer, pointerInFormula);
                    bufPtr = buffer;
                    buffer[0] = 0;
                    pointerInFormula = strPtr;
                    numericCount = 0;
                } else {
                    bufPtr[0] = strPtr[0];
                    bufPtr += 1;
                    const wasDouble = (strPtr[0] & 0x80) != 0;
                    strPtr += 1;
                    if (wasDouble) {
                        bufPtr[0] = strPtr[0];
                        bufPtr += 1;
                        strPtr += 1;
                    }
                }

                afterClosingParenthesis = false;
                unaryMinusCanOccur = false;
                afterSpace = false;
            },
        }
        if (lastErrorCode != ERROR_NONE) {
            return;
        }
    }
    if (bufPtr != buffer) {
        bufPtr[0] = 0;
        bufPtr += 1;
        _parseWord(buffer, parseMode, PARSER_HINT_REGULAR(buffer, numericCount), mvarBuffer, pointerInFormula);
    }

    if (parseMode == EQUATION_PARSER_MVAR) {
        var tmpVal: u32 = 0;
        bufPtr = mvarBuffer;
        while (bufPtr[0] != 0) {
            bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
            tmpVal += 1;
        }
        if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_SOLVER) {
            while (tmpVal < 4) : (tmpVal += 1) {
                bufPtr[0] = 0;
                bufPtr += 1;
            }
            if (tmpVal == 4) {
                _menuItem(MNU_Solver_TOOL, bufPtr);
                bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                _menuItem(ITM_CALC, bufPtr);
            }
        } else if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_GRAPHER) {
            while (tmpVal < 4) : (tmpVal += 1) {
                bufPtr[0] = 0;
                bufPtr += 1;
            }
            if (tmpVal == 4) {
                _menuItem(MNU_GRAPHS, bufPtr);
                bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                _menuItem(ITM_DRAW, bufPtr);
            }
        } else if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_INTEGRATE) {
            while (tmpVal < 4) : (tmpVal += 1) {
                bufPtr[0] = 0;
                bufPtr += 1;
            }
            if (tmpVal == 4) {
                _menuItem(MNU_Sf_TOOL, bufPtr);
                bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                _menuItem(ITM_INTEGRAL_YX, bufPtr);
            }
        } else if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE or (currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_2ND_DERIVATIVE) {
            while (tmpVal < 4) : (tmpVal += 1) {
                bufPtr[0] = 0;
                bufPtr += 1;
            }
            if (tmpVal == 4) {
                if ((currentSolverStatus & SOLVER_STATUS_EQUATION_MODE) == SOLVER_STATUS_EQUATION_1ST_DERIVATIVE) {
                    _menuItem(MNU_GRAPHS, bufPtr);
                    bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                    _menuItem(ITM_FPHERE, bufPtr);
                } else {
                    _menuItem(MNU_GRAPHS, bufPtr);
                    bufPtr += @as(usize, @intCast(stringByteLength(bufPtr) + 1));
                    _menuItem(ITM_FPPHERE, bufPtr);
                }
            }
        }
    }
    if (parseMode == EQUATION_PARSER_XEQ) {
        _processOperator(PARSER_OPERATOR_ITM_END_OF_FORMULA, mvarBuffer);
    }
}

// PARSER_HINT_REGULAR macro
inline fn PARSER_HINT_REGULAR(buffer: [*c]const u8, numericCount: i16) u16 {
    return if (stringGlyphLength(buffer) == numericCount) PARSER_HINT_NUMERIC else PARSER_HINT_VARIABLE;
}
