// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/differentiate.c: numerical first/second
// derivative commands (finite differences, ported from WP34s). UNCOVERED by the
// testSuite (no test gate) - verified by build only. Faithful line-by-line
// translation preserving the exact order of every real_t operation.
//
// fn1stDeriv is exported here as z47_solver_fn1stDeriv (the symbol solve.zig's
// dispatcher calls). The other public commands (fn2ndDeriv, fn1stDerivEq,
// fn2ndDerivEq) keep their real C names. The static helpers stay private.
//
// The finite-difference stencil tables and fdValues array live as
// `TO_QSPI static const` data in finite_differences.h (file-local, not
// linkable), so they are reproduced verbatim here. The `desc` field of each
// stencil is only used inside dead `#if 0` blocks and is dropped.
//
// EXTRA_INFO_ON_CALC_ERROR sprintf hints are stripped under TESTSUITE/DMCP
// (EXTRA_INFO_ON_CALC_ERROR == 0) so they are omitted. The errorMessage TI
// string built at the end of calcDeriv is reproduced (display only; no effect
// on the computed result).

const runtime = @import("solve_runtime.zig");

// DECNUMDIGITS=75, DECDPUN=3 => DECNUMUNITS=ceil(75/3)=25; decNumberUnit=u16.
const abi = @import("abi"); // shared ABI bindings
const equation = @import("equation.zig");
const real_t = abi.Real;
const real34_t = abi.Real34;
const realContext_t = abi.RealContext;

const calcRegister_t = runtime.calcRegister_t;
const bool_t = bool;

// ---------------------------------------------------------------------------
// finite_differences.h  (MAX_ORDER=7, MAX_F_EVAL=15)
// ---------------------------------------------------------------------------
const MAX_ORDER: i32 = 7;
const MAX_F_EVAL: i32 = 2 * MAX_ORDER + 1;

const FINITE_DIFF_COEFF = struct {
    n: u8,
    order: u8,
    denom: u8,
    coeff: []const u8,
};

const d1_3_central = FINITE_DIFF_COEFF{ .n = 1, .order = 1, .denom = 1, .coeff = &.{ 2, 0, 3 } };
const d1_2_lower_middle = FINITE_DIFF_COEFF{ .n = 1, .order = 1, .denom = 3, .coeff = &.{ 2, 3, 0 } };
const d1_2_upper_middle = FINITE_DIFF_COEFF{ .n = 1, .order = 1, .denom = 3, .coeff = &.{ 0, 2, 3 } };
const d1_5_central = FINITE_DIFF_COEFF{ .n = 2, .order = 1, .denom = 4, .coeff = &.{ 3, 5, 0, 6, 2 } };
const d1_3_lower_middle = FINITE_DIFF_COEFF{ .n = 2, .order = 1, .denom = 1, .coeff = &.{ 3, 7, 8, 0, 0 } };
const d1_3_upper_middle = FINITE_DIFF_COEFF{ .n = 2, .order = 1, .denom = 1, .coeff = &.{ 0, 0, 9, 10, 2 } };
const d1_2_lower = FINITE_DIFF_COEFF{ .n = 2, .order = 1, .denom = 3, .coeff = &.{ 2, 3, 0, 0, 0 } };
const d1_2_upper = FINITE_DIFF_COEFF{ .n = 2, .order = 1, .denom = 3, .coeff = &.{ 0, 0, 0, 2, 3 } };
const d1_7_central = FINITE_DIFF_COEFF{ .n = 3, .order = 1, .denom = 11, .coeff = &.{ 2, 12, 13, 0, 14, 15, 3 } };
const d1_4_lower_middle = FINITE_DIFF_COEFF{ .n = 3, .order = 1, .denom = 16, .coeff = &.{ 17, 12, 18, 19, 0, 0, 0 } };
const d1_4_upper_middle = FINITE_DIFF_COEFF{ .n = 3, .order = 1, .denom = 16, .coeff = &.{ 0, 0, 0, 20, 21, 15, 1 } };
const d1_3_lower = FINITE_DIFF_COEFF{ .n = 3, .order = 1, .denom = 1, .coeff = &.{ 8, 5, 22, 0, 0, 0, 0 } };
const d1_3_upper = FINITE_DIFF_COEFF{ .n = 3, .order = 1, .denom = 1, .coeff = &.{ 0, 0, 0, 0, 23, 6, 9 } };
const d1_9_central = FINITE_DIFF_COEFF{ .n = 4, .order = 1, .denom = 24, .coeff = &.{ 8, 25, 26, 27, 0, 28, 29, 30, 9 } };
const d1_5_lower_middle = FINITE_DIFF_COEFF{ .n = 4, .order = 1, .denom = 4, .coeff = &.{ 8, 31, 32, 33, 34, 0, 0, 0, 0 } };
const d1_5_upper_middle = FINITE_DIFF_COEFF{ .n = 4, .order = 1, .denom = 4, .coeff = &.{ 0, 0, 0, 0, 35, 36, 37, 38, 9 } };
const d1_4_lower = FINITE_DIFF_COEFF{ .n = 4, .order = 1, .denom = 16, .coeff = &.{ 20, 39, 40, 41, 0, 0, 0, 0, 0 } };
const d1_4_upper = FINITE_DIFF_COEFF{ .n = 4, .order = 1, .denom = 16, .coeff = &.{ 0, 0, 0, 0, 0, 42, 43, 44, 19 } };
const d1_11_central = FINITE_DIFF_COEFF{ .n = 5, .order = 1, .denom = 45, .coeff = &.{ 17, 34, 46, 47, 48, 0, 49, 50, 51, 35, 1 } };
const d1_6_lower_middle = FINITE_DIFF_COEFF{ .n = 5, .order = 1, .denom = 11, .coeff = &.{ 52, 53, 54, 55, 56, 57, 0, 0, 0, 0, 0 } };
const d1_6_upper_middle = FINITE_DIFF_COEFF{ .n = 5, .order = 1, .denom = 11, .coeff = &.{ 0, 0, 0, 0, 0, 58, 55, 56, 59, 60, 4 } };
const d1_5_lower = FINITE_DIFF_COEFF{ .n = 5, .order = 1, .denom = 4, .coeff = &.{ 34, 61, 62, 63, 64, 0, 0, 0, 0, 0, 0 } };
const d1_5_upper = FINITE_DIFF_COEFF{ .n = 5, .order = 1, .denom = 4, .coeff = &.{ 0, 0, 0, 0, 0, 0, 65, 66, 67, 68, 35 } };
const d1_13_central = FINITE_DIFF_COEFF{ .n = 6, .order = 1, .denom = 69, .coeff = &.{ 22, 70, 71, 72, 73, 74, 0, 75, 76, 77, 78, 79, 23 } };
const d1_7_lower_middle = FINITE_DIFF_COEFF{ .n = 6, .order = 1, .denom = 11, .coeff = &.{ 80, 70, 81, 82, 83, 84, 85, 0, 0, 0, 0, 0, 0 } };
const d1_7_upper_middle = FINITE_DIFF_COEFF{ .n = 6, .order = 1, .denom = 11, .coeff = &.{ 0, 0, 0, 0, 0, 0, 86, 87, 88, 89, 90, 79, 91 } };
const d1_6_lower = FINITE_DIFF_COEFF{ .n = 6, .order = 1, .denom = 11, .coeff = &.{ 58, 92, 93, 94, 95, 96, 0, 0, 0, 0, 0, 0, 0 } };
const d1_6_upper = FINITE_DIFF_COEFF{ .n = 6, .order = 1, .denom = 11, .coeff = &.{ 0, 0, 0, 0, 0, 0, 0, 97, 98, 99, 100, 101, 57 } };
const d1_15_central = FINITE_DIFF_COEFF{ .n = 7, .order = 1, .denom = 102, .coeff = &.{ 103, 104, 105, 106, 107, 108, 109, 0, 110, 111, 112, 113, 114, 115, 116 } };
const d1_8_lower_middle = FINITE_DIFF_COEFF{ .n = 7, .order = 1, .denom = 117, .coeff = &.{ 118, 119, 120, 121, 122, 123, 124, 125, 0, 0, 0, 0, 0, 0, 0 } };
const d1_8_upper_middle = FINITE_DIFF_COEFF{ .n = 7, .order = 1, .denom = 117, .coeff = &.{ 0, 0, 0, 0, 0, 0, 0, 126, 127, 128, 129, 130, 131, 132, 11 } };
const d1_7_lower = FINITE_DIFF_COEFF{ .n = 7, .order = 1, .denom = 11, .coeff = &.{ 85, 133, 134, 135, 136, 137, 138, 0, 0, 0, 0, 0, 0, 0, 0 } };
const d1_7_upper = FINITE_DIFF_COEFF{ .n = 7, .order = 1, .denom = 11, .coeff = &.{ 0, 0, 0, 0, 0, 0, 0, 0, 139, 140, 141, 142, 143, 144, 86 } };

const d2_3_central = FINITE_DIFF_COEFF{ .n = 1, .order = 2, .denom = 3, .coeff = &.{ 3, 17, 3 } };
const d2_5_central = FINITE_DIFF_COEFF{ .n = 2, .order = 2, .denom = 4, .coeff = &.{ 2, 38, 145, 38, 2 } };
const d2_3_lower_middle = FINITE_DIFF_COEFF{ .n = 2, .order = 2, .denom = 3, .coeff = &.{ 3, 17, 3, 0, 0 } };
const d2_3_upper_middle = FINITE_DIFF_COEFF{ .n = 2, .order = 2, .denom = 3, .coeff = &.{ 0, 0, 3, 17, 3 } };
const d2_7_central = FINITE_DIFF_COEFF{ .n = 3, .order = 2, .denom = 146, .coeff = &.{ 1, 147, 148, 132, 148, 147, 1 } };
const d2_4_lower_middle = FINITE_DIFF_COEFF{ .n = 3, .order = 2, .denom = 3, .coeff = &.{ 2, 10, 23, 1, 0, 0, 0 } };
const d2_4_upper_middle = FINITE_DIFF_COEFF{ .n = 3, .order = 2, .denom = 3, .coeff = &.{ 0, 0, 0, 1, 23, 10, 2 } };
const d2_3_lower = FINITE_DIFF_COEFF{ .n = 3, .order = 2, .denom = 3, .coeff = &.{ 3, 17, 3, 0, 0, 0, 0 } };
const d2_3_upper = FINITE_DIFF_COEFF{ .n = 3, .order = 2, .denom = 3, .coeff = &.{ 0, 0, 0, 0, 3, 17, 3 } };
const d2_9_central = FINITE_DIFF_COEFF{ .n = 4, .order = 2, .denom = 149, .coeff = &.{ 15, 150, 151, 152, 153, 152, 151, 150, 15 } };
const d2_5_lower_middle = FINITE_DIFF_COEFF{ .n = 4, .order = 2, .denom = 4, .coeff = &.{ 19, 154, 155, 156, 157, 0, 0, 0, 0 } };
const d2_5_upper_middle = FINITE_DIFF_COEFF{ .n = 4, .order = 2, .denom = 4, .coeff = &.{ 0, 0, 0, 0, 157, 156, 155, 154, 19 } };
const d2_4_lower = FINITE_DIFF_COEFF{ .n = 4, .order = 2, .denom = 3, .coeff = &.{ 17, 158, 5, 8, 0, 0, 0, 0, 0 } };
const d2_4_upper = FINITE_DIFF_COEFF{ .n = 4, .order = 2, .denom = 3, .coeff = &.{ 0, 0, 0, 0, 0, 8, 5, 158, 17 } };
const d2_11_central = FINITE_DIFF_COEFF{ .n = 5, .order = 2, .denom = 159, .coeff = &.{ 6, 160, 161, 162, 163, 164, 163, 162, 161, 160, 6 } };
const d2_6_lower_middle = FINITE_DIFF_COEFF{ .n = 5, .order = 2, .denom = 4, .coeff = &.{ 91, 165, 166, 66, 167, 14, 0, 0, 0, 0, 0 } };
const d2_6_upper_middle = FINITE_DIFF_COEFF{ .n = 5, .order = 2, .denom = 4, .coeff = &.{ 0, 0, 0, 0, 0, 14, 167, 66, 166, 165, 91 } };
const d2_5_lower = FINITE_DIFF_COEFF{ .n = 5, .order = 2, .denom = 4, .coeff = &.{ 157, 168, 169, 170, 171, 0, 0, 0, 0, 0, 0 } };
const d2_5_upper = FINITE_DIFF_COEFF{ .n = 5, .order = 2, .denom = 4, .coeff = &.{ 0, 0, 0, 0, 0, 0, 171, 170, 169, 168, 157 } };
const d2_13_central = FINITE_DIFF_COEFF{ .n = 6, .order = 2, .denom = 172, .coeff = &.{ 173, 174, 76, 175, 176, 177, 178, 177, 176, 175, 76, 174, 173 } };
const d2_7_lower_middle = FINITE_DIFF_COEFF{ .n = 6, .order = 2, .denom = 146, .coeff = &.{ 57, 179, 180, 181, 182, 183, 184, 0, 0, 0, 0, 0, 0 } };
const d2_7_upper_middle = FINITE_DIFF_COEFF{ .n = 6, .order = 2, .denom = 146, .coeff = &.{ 0, 0, 0, 0, 0, 0, 184, 183, 182, 181, 180, 179, 57 } };
const d2_6_lower = FINITE_DIFF_COEFF{ .n = 6, .order = 2, .denom = 4, .coeff = &.{ 13, 185, 186, 187, 188, 189, 0, 0, 0, 0, 0, 0, 0 } };
const d2_6_upper = FINITE_DIFF_COEFF{ .n = 6, .order = 2, .denom = 4, .coeff = &.{ 0, 0, 0, 0, 0, 0, 0, 189, 188, 187, 186, 185, 13 } };
const d2_15_central = FINITE_DIFF_COEFF{ .n = 7, .order = 2, .denom = 190, .coeff = &.{ 191, 192, 193, 194, 195, 196, 197, 198, 197, 196, 195, 194, 193, 192, 191 } };
const d2_8_lower_middle = FINITE_DIFF_COEFF{ .n = 7, .order = 2, .denom = 146, .coeff = &.{ 199, 144, 200, 201, 202, 203, 204, 205, 0, 0, 0, 0, 0, 0, 0 } };
const d2_8_upper_middle = FINITE_DIFF_COEFF{ .n = 7, .order = 2, .denom = 146, .coeff = &.{ 0, 0, 0, 0, 0, 0, 0, 205, 204, 203, 202, 201, 200, 144, 199 } };
const d2_7_lower = FINITE_DIFF_COEFF{ .n = 7, .order = 2, .denom = 146, .coeff = &.{ 184, 206, 207, 208, 209, 210, 211, 0, 0, 0, 0, 0, 0, 0, 0 } };
const d2_7_upper = FINITE_DIFF_COEFF{ .n = 7, .order = 2, .denom = 146, .coeff = &.{ 0, 0, 0, 0, 0, 0, 0, 0, 211, 210, 209, 208, 207, 206, 184 } };

const d1_derivatives = [_]?*const FINITE_DIFF_COEFF{
    &d1_15_central,     &d1_13_central,     &d1_11_central,     &d1_9_central,
    &d1_8_lower_middle, &d1_8_upper_middle, &d1_7_central,      &d1_7_lower_middle,
    &d1_7_upper_middle, &d1_7_lower,        &d1_7_upper,        &d1_6_lower_middle,
    &d1_6_upper_middle, &d1_6_lower,        &d1_6_upper,        &d1_5_central,
    &d1_5_lower_middle, &d1_5_upper_middle, &d1_5_lower,        &d1_5_upper,
    &d1_4_lower_middle, &d1_4_upper_middle, &d1_4_lower,        &d1_4_upper,
    &d1_3_central,      &d1_3_lower_middle, &d1_3_upper_middle, &d1_3_lower,
    &d1_3_upper,        &d1_2_lower_middle, &d1_2_upper_middle, &d1_2_lower,
    &d1_2_upper,        null,
};

const d2_derivatives = [_]?*const FINITE_DIFF_COEFF{
    &d2_15_central,     &d2_13_central,     &d2_11_central,     &d2_9_central,
    &d2_8_lower_middle, &d2_8_upper_middle, &d2_7_central,      &d2_7_lower_middle,
    &d2_7_upper_middle, &d2_7_lower,        &d2_7_upper,        &d2_6_lower_middle,
    &d2_6_upper_middle, &d2_6_lower,        &d2_6_upper,        &d2_5_central,
    &d2_5_lower_middle, &d2_5_upper_middle, &d2_5_lower,        &d2_5_upper,
    &d2_4_lower_middle, &d2_4_upper_middle, &d2_4_lower,        &d2_4_upper,
    &d2_3_central,      &d2_3_lower_middle, &d2_3_upper_middle, &d2_3_lower,
    &d2_3_upper,        null,
};

const finite_difference_table = [_][*]const ?*const FINITE_DIFF_COEFF{
    &d1_derivatives,
    &d2_derivatives,
};

const fdValues = [212]i32{
    0,       2,       -1,       1,       12,        -8,        8,          -4,
    3,       -3,      4,        60,      9,         -45,       45,         -9,
    6,       -2,      -18,      11,      -11,       18,        5,          -5,
    840,     -32,     168,      -672,    672,       -168,      32,         -16,
    36,      -48,     25,       -25,     48,        -36,       16,         42,
    -57,     26,      -26,      57,      -42,       2520,      -150,       600,
    -2100,   2100,    -600,     150,     -12,       75,        -200,       300,
    -300,    137,     -137,     200,     -75,       -122,      234,        -214,
    77,      -77,     214,      -234,    122,       27720,     -72,        495,
    -2200,   7425,    -23760,   23760,   -7425,     2200,      -495,       72,
    10,      225,     -400,     450,     -360,      147,       -147,       360,
    -450,    400,     -225,     -10,     810,       -1980,     2540,       -1755,
    522,     -522,    1755,     -2540,   1980,      -810,      360360,     -15,
    245,     -1911,   9555,     -35035,  105105,    -315315,   315315,     -105105,
    35035,   -9555,   1911,     -245,    15,        420,       -60,        490,
    -1764,   3675,    -4900,    4410,    -2940,     1089,      -1089,      2940,
    -4410,   4900,    -3675,    1764,    -490,      -1019,     3015,       -4920,
    4745,    -2637,   669,      -669,    2637,      -4745,     4920,       -3015,
    1019,    -30,     180,      -27,     270,       5040,      128,        -1008,
    8064,    -14350,  -56,      114,     -104,      35,        7,          25200,
    -125,    1000,    -6000,    42000,   -73766,    61,        -156,       -154,
    -164,    294,     -236,     71,      831600,    -50,       864,        44000,
    -222750, 1425600, -2480478, -972,    2970,      -5080,     5265,       -3132,
    812,     260,     -614,     744,     -461,      116,       75675600,   900,
    -17150,  160524,  -1003275, 4904900, -22072050, 132432300, -228812298, -126,
    -3618,   7380,    -9490,    7911,    -4014,     938,       -5547,      16080,
    -25450,  23340,   -11787,   2552,
};

// ---------------------------------------------------------------------------
// differentiate.h enum
// ---------------------------------------------------------------------------
const DERIVATIVE_FIRST_CENTRAL: u16 = 0;
const DERIVATIVE_SECOND_CENTRAL: u16 = 1;

// ---------------------------------------------------------------------------
// defines.h values (verified)
//   FIRST_LABEL=2044 LAST_LABEL=6999 INVALID_VARIABLE=2199
//   REGISTER_X=100 T=103 L=108; TEMP_REGISTER_1=135; ERR_REGISTER_LINE=REGISTER_Z=102
//   ERROR_NONE=0 ERROR_LABEL_NOT_FOUND=6 ERROR_OUT_OF_RANGE=8
//   FLAG_SOLVING=0xc026; SOLVER_STATUS_USES_FORMULA=0x0100
//   dtReal34=1; amNone=5; NOPARAM=9876
//   TI_1ST_DERIVATIVE=57 TI_2ND_DERIVATIVE=58
//   ITM_RCL=51 ITM_STO=44; AIM_BUFFER_LENGTH=1024; EQUATION_PARSER_XEQ=1
// ---------------------------------------------------------------------------
const FIRST_LABEL: u16 = 2200; // INVALID_VARIABLE=2199 precedes FIRST_LABEL; the //2044 C comment is stale
const LAST_LABEL: u16 = 6999;
const INVALID_VARIABLE: u16 = 2199;

const REGISTER_X: calcRegister_t = 100;
const REGISTER_T: calcRegister_t = 103;
const TEMP_REGISTER_1: calcRegister_t = 135;
const ERR_REGISTER_LINE: calcRegister_t = 102;

const ERROR_NONE: u8 = 0;
const ERROR_LABEL_NOT_FOUND: u8 = 6;
const ERROR_OUT_OF_RANGE: u8 = 8;

const FLAG_SOLVING: u32 = 0xc026;
const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;

const dtReal34: u32 = 1;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const TI_1ST_DERIVATIVE: u8 = 57;
const TI_2ND_DERIVATIVE: u8 = 58;

const ITM_RCL: i16 = 51;
const ITM_STO: i16 = 44;
const AIM_BUFFER_LENGTH: usize = 1024;
const EQUATION_PARSER_XEQ: u16 = 1;

// STD_delta / STD_DELTA + "x"/"X" labels (fonts.h)
const STD_delta_x: [*:0]const u8 = "\x83\xb4x";
const STD_delta_X: [*:0]const u8 = "\x83\xb4X";
const STD_DELTA_x: [*:0]const u8 = "\x83\x94x";
const STD_DELTA_X: [*:0]const u8 = "\x83\x94X";
const STD_delta_eq: [*:0]const u8 = "\x83\xb4="; // STD_delta "="

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var dynamicMenuItem: i16;
extern var currentSolverStatus: u16;
extern var currentSolverVariable: u16;
extern var currentFormula: u16;
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;

extern var ctxtReal4: realContext_t;
extern var ctxtReal39: realContext_t;

// ---------------------------------------------------------------------------
// Constants blob accessor: const_1on10
// ---------------------------------------------------------------------------
inline fn const_1on10() *align(1) const real_t {
    return consts.c4520();
}

// ---------------------------------------------------------------------------
// decNumber primitives / real_t macro reproductions
// ---------------------------------------------------------------------------
extern fn decNumberCopy(res: *real_t, source: *align(1) const real_t) *real_t;
extern fn decNumberFMA(res: *real_t, f1: *const real_t, f2: *const real_t, term: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberMultiply(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberPlus(res: *real_t, operand: *const real_t, ctxt: *realContext_t) *real_t;
extern fn decNumberFromInt32(res: *real_t, source: i32) *real_t;
extern fn decNumberFromUInt32(res: *real_t, source: u32) *real_t;
extern fn decNumberToString(source: *const real_t, dest: [*c]u8) [*c]u8;

inline fn realCopy(source: *align(1) const real_t, destination: *real_t) void {
    _ = decNumberCopy(destination, source);
}
inline fn realFMA(f1: *const real_t, f2: *const real_t, term: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberFMA(res, f1, f2, term, ctxt);
}
inline fn realMultiply(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberMultiply(res, op1, op2, ctxt);
}
inline fn realDivide(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberDivide(res, op1, op2, ctxt);
}
inline fn realPlus(operand: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberPlus(res, operand, ctxt);
}
inline fn int32ToReal(source: i32, destination: *real_t) void {
    _ = decNumberFromInt32(destination, source);
}
inline fn uInt32ToReal(source: u32, destination: *real_t) void {
    _ = decNumberFromUInt32(destination, source);
}
inline fn realIsSpecial(source: *const real_t) bool {
    return (source.bits & 0x70) != 0;
}
inline fn realToString(source: *const real_t, destination: [*c]u8) [*c]u8 {
    return decNumberToString(source, destination);
}

extern fn realSetZero(value: *real_t) void;
extern fn realSetNaN(value: *real_t) void;

// real34_t macros
extern fn decimal128ToNumber(source: *align(1) const real34_t, destination: *real_t) *real_t;
extern fn decimal128FromNumber(dest: *align(1) real34_t, src: *const real_t, ctxt: *realContext_t) *align(1) real34_t;
extern var ctxtReal34: realContext_t;
inline fn real34ToReal(source: *align(1) const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}
inline fn realToReal34(source: *const real_t, destination: *align(1) real34_t) void {
    _ = decimal128FromNumber(destination, source, &ctxtReal34);
}

// ---------------------------------------------------------------------------
// Register / stack / program externs
// ---------------------------------------------------------------------------
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
const registerReal34Ptr = abi.registerReal34;
extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn getRegisterAsReal(reg: calcRegister_t, val: *real_t) bool;
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u32, tag: u32) void;
extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: u32) void;
extern fn copySourceRegisterToDestRegister(rSource: calcRegister_t, rDest: calcRegister_t) void;

extern fn getSystemFlag(sf: i32) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn saveForUndo() void;
extern fn undo() void;
extern fn fnToReal(unused: u16) void;
extern fn fnDrop(unused: u16) void;
extern fn fnFillStack(unused: u16) void;
extern fn execProgram(label: u16) void;
extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
const GLOBAL_LABELS: u8 = 253; // namedLabels_t: STRING_LABEL_VARIABLE
const ALL_LABELS: u8 = 0; // namedLabels_t: search local then global
extern fn findNamedLabel(label_name: [*:0]const u8, label_type: u8) calcRegister_t;
extern fn letteredRegisterName(regist: calcRegister_t) u8;

// libc string helpers
extern fn strcpy(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strcat(dest: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn strlen(s: [*c]const u8) usize;
inline fn stringByteLength(s: [*c]const u8) i32 {
    return @intCast(strlen(s));
}

fn calcDerivOfOrder(label: u16, order: u16) linksection(runtime.code_section) void {
    calcDeriv(@bitCast(label), finite_difference_table[order]);
}

fn derivativeCommon(label_in: u16, order: u16, ti: u8) linksection(runtime.code_section) void {
    var label = label_in;
    currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
    const solving: bool_t = getSystemFlag(@bitCast(FLAG_SOLVING));
    var buf: [2]u8 = undefined;

    setSystemFlag(FLAG_SOLVING);
    if (label >= FIRST_LABEL and label <= LAST_LABEL) {
        calcDerivOfOrder(label, order);
        temporaryInformation = ti;
    } else if (REGISTER_X <= @as(calcRegister_t, @intCast(label)) and @as(calcRegister_t, @intCast(label)) <= REGISTER_T) {
        // Interactive mode
        buf[0] = letteredRegisterName(@intCast(label));
        buf[1] = 0;
        label = @bitCast(@as(i16, @truncate(findNamedLabel(@ptrCast(&buf[0]), GLOBAL_LABELS))));
        if (label == INVALID_VARIABLE) {
            displayCalcErrorMessage(ERROR_LABEL_NOT_FOUND, ERR_REGISTER_LINE, REGISTER_X);
        } else {
            calcDerivOfOrder(label, order);
            temporaryInformation = ti;
        }
    } else {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
    }
    if (!solving) {
        clearSystemFlag(FLAG_SOLVING);
    }
}

pub export fn z47_solver_fn1stDeriv(label: u16) linksection(runtime.code_section) callconv(.c) void {
    derivativeCommon(label, DERIVATIVE_FIRST_CENTRAL, TI_1ST_DERIVATIVE);
}

pub export fn fn2ndDeriv(label: u16) linksection(runtime.code_section) callconv(.c) void {
    derivativeCommon(label, DERIVATIVE_SECOND_CENTRAL, TI_2ND_DERIVATIVE);
}

fn derivativeEquation(order: u16, ti: u8) linksection(runtime.code_section) void {
    // new method to maintain solver variable
    reallyRunFunction(ITM_RCL, currentSolverVariable);
    copySourceRegisterToDestRegister(REGISTER_X, TEMP_REGISTER_1);
    currentSolverStatus |= SOLVER_STATUS_USES_FORMULA;
    calcDerivOfOrder(INVALID_VARIABLE, order);
    reallyRunFunction(ITM_RCL, TEMP_REGISTER_1);
    reallyRunFunction(ITM_STO, currentSolverVariable);
    fnDrop(NOPARAM);
    temporaryInformation = ti;
}

pub export fn fn1stDerivEq(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    derivativeEquation(DERIVATIVE_FIRST_CENTRAL, TI_1ST_DERIVATIVE);
}

pub export fn fn2ndDerivEq(unusedButMandatoryParameter: u16) linksection(runtime.code_section) callconv(.c) void {
    _ = unusedButMandatoryParameter;
    derivativeEquation(DERIVATIVE_SECOND_CENTRAL, TI_2ND_DERIVATIVE);
}

// =========================================================================== //
// The following routines are ported from WP34s.
// =========================================================================== //
fn deriv_found_lbl(deltaX: calcRegister_t, h: *real_t) linksection(runtime.code_section) void {
    execProgram(@bitCast(deltaX));
    fnToReal(NOPARAM);
    if (getRegisterDataType(REGISTER_X) == dtReal34) {
        real34ToReal(registerReal34Ptr(REGISTER_X), h);
    } else {
        lastErrorCode = ERROR_NONE;
        realCopy(const_1on10(), h);
    }
}

const deriv_lbls = [_][*:0]const u8{ STD_delta_x, STD_delta_X, STD_DELTA_x, STD_DELTA_X };

fn deriv_default_h(h: *real_t) linksection(runtime.code_section) void {
    saveForUndo();
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    realToReal34(h, registerReal34Ptr(REGISTER_X));
    fnFillStack(NOPARAM);

    dynamicMenuItem = -1;
    var i: usize = 0;
    while (i < deriv_lbls.len) : (i += 1) {
        const deltaX = findNamedLabel(deriv_lbls[i], ALL_LABELS);
        if (@as(u16, @bitCast(@as(i16, @truncate(deltaX)))) != INVALID_VARIABLE) {
            deriv_found_lbl(deltaX, h);
            undo();
            return;
        }
    }
    undo();
    h.exponent -= 16;
}

fn _differentiatorIteration(label: calcRegister_t, r0: *real_t) linksection(runtime.code_section) void {
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    realToReal34(r0, registerReal34Ptr(REGISTER_X));
    fnFillStack(NOPARAM);

    if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
        reallyRunFunction(ITM_STO, currentSolverVariable);
        equation.parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    } else {
        dynamicMenuItem = -1;
        execProgram(@bitCast(label));
        fnToReal(NOPARAM);
    }

    if (getRegisterDataType(REGISTER_X) == dtReal34) {
        real34ToReal(registerReal34Ptr(REGISTER_X), r0);
    } else {
        lastErrorCode = ERROR_NONE;
        realSetNaN(r0);
    }
}

// Try to compute a single derivative estimate from a stencil
fn calcOneDeriv(stencil: *const FINITE_DIFF_COEFF, fxIn: [*]const real_t, h: *const real_t, r: *real_t, realContext: *realContext_t) linksection(runtime.code_section) bool_t {
    const maxi: u16 = 2 * @as(u16, stencil.n) + 1;
    var t: real_t = undefined;
    var s: real_t = undefined;
    const fx: [*]const real_t = fxIn + @as(usize, @intCast(MAX_ORDER - @as(i32, stencil.n)));

    // Check if all f(x) are defined or not
    var i: u16 = 0;
    while (i < maxi) : (i += 1) {
        if (stencil.coeff[i] != 0 and realIsSpecial(&fx[i])) {
            return false;
        }
    }

    // All values are defined where required so calculate the weighted sum
    realSetZero(&s);
    i = 0;
    while (i < maxi) : (i += 1) {
        if (stencil.coeff[i] != 0) {
            int32ToReal(fdValues[stencil.coeff[i]], &t);
            realFMA(&fx[i], &t, &s, &s, realContext);
        }
    }
    // Inefficiently factor in the derivative order
    uInt32ToReal(@bitCast(fdValues[stencil.denom]), &t);
    i = 0;
    while (i < stencil.order) : (i += 1) {
        realMultiply(&t, h, &t, realContext);
    }
    realDivide(&s, &t, r, realContext);
    return true;
}

// Compute the function values f(x + k h), k = -MAX_ORDER .. MAX_ORDER
fn calcFuncValues(label: calcRegister_t, x: *const real_t, fx: [*]real_t, h: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var t: real_t = undefined;
    var i: i32 = 0;
    while (i < MAX_F_EVAL) : (i += 1) {
        int32ToReal(i - MAX_ORDER, &t);
        realFMA(&t, h, x, &fx[@intCast(i)], realContext);
        _differentiatorIteration(label, &fx[@intCast(i)]);
    }
}

// Evaluate the function at stencil points and compute "best" estimate
fn calcDeriv(label: calcRegister_t, finDiff: [*]const ?*const FINITE_DIFF_COEFF) linksection(runtime.code_section) void {
    var x: real_t = undefined;
    var h: real_t = undefined;
    var fx: [@intCast(MAX_F_EVAL)]real_t = undefined;

    if (!getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    if (!realIsSpecial(&x)) {
        realCopy(&x, &h); // Pass X into the h determination code to allow relative steps
        deriv_default_h(&h);

        // Compute the function at the finite difference points
        saveForUndo();
        calcFuncValues(label, &x, &fx, &h, &ctxtReal39);
        undo();

        // Try finite differences until we get a result
        var i: usize = 0;
        while (finDiff[i] != null) : (i += 1) {
            if (calcOneDeriv(finDiff[i].?, &fx, &h, &x, &ctxtReal39)) {
                // Add string, for display at TI
                var c: realContext_t = ctxtReal4;
                c.digits = 2;
                var hh: real_t = undefined;
                realPlus(&h, &hh, &c);
                _ = strcpy(errorMessage, STD_delta_eq);
                _ = decNumberToString(&hh, errorMessage + @as(usize, @intCast(stringByteLength(errorMessage))));
                _ = strcat(errorMessage, "; ");
                convertRealToResultRegister(&x, REGISTER_X, amNone);
                return;
            }
        }
    }
    // No estimate possible
    realSetNaN(&x);
    // Add string, for display at TI
    errorMessage[0] = 0;

    convertRealToResultRegister(&x, REGISTER_X, amNone);
}
