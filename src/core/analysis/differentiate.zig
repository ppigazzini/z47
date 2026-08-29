// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
//
// Zig owner for src/c47/solver/differentiate.c: numerical first/second
// derivative commands (finite differences, ported from WP34s). Faithful
// line-by-line translation preserving the exact order of every real_t operation.
//
// The public commands (fnPgmDrv, fn1stDerivVar, fn2ndDerivVar, fn1stDerivEq,
// fn2ndDerivEq) keep their C names. The static helpers stay private.
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
//   REGISTER_X=100 T=103; ERR_REGISTER_LINE=REGISTER_Z=102
//   ERROR_NONE=0 ERROR_OUT_OF_RANGE=8 ERROR_NO_PROGRAM_SPECIFIED=54
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
const ERR_REGISTER_LINE: calcRegister_t = 102;

const ERROR_NONE: u8 = 0;
const ERROR_OUT_OF_RANGE: u8 = 8;

const FLAG_SOLVING: u32 = 0xc026;
const SOLVER_STATUS_USES_FORMULA: u16 = 0x0100;

const dtReal34: u32 = 1;
const amNone: u32 = 5;
const NOPARAM: u16 = 9876;

const TI_1ST_DERIVATIVE: u8 = 57;
const TI_2ND_DERIVATIVE: u8 = 58;
const TI_DERIV_STEP: u8 = 144;

// h starts at x/10, the coarsest step a 15 point stencil is worth taking, and stops at x*1e-16, the step this engine used
// for every stencil before the ladder. DERIV_TOLERANCE_DIGITS is the digits a sample carries less one for the coefficient
// sum, which is what two estimates are compared against.
const DERIV_FIRST_SHIFT: i32 = 1;
const DERIV_LAST_SHIFT: i32 = 16;
const DERIV_TOLERANCE_DIGITS: i32 = 32;

const FIRST_UC_LOCAL_LABEL: u16 = 100; // A, the first upper-case local label
const LAST_LOCAL_LABEL: u16 = 123; // l, the last lower-case local label
const ERROR_NO_PROGRAM_SPECIFIED: u8 = 54;
const CMP_NAME: i32 = 3;
const MNU_MVAR: i16 = 3088;
const FLAG_INTING: u32 = 0xc025;
const SOLVER_STATUS_INTERACTIVE: u16 = 0x0002;
const SOLVER_STATUS_EQUATION_MODE: u16 = 0x200c;
const SOLVER_STATUS_EQUATION_1ST_DERIVATIVE: u16 = 0x0008;
const SOLVER_STATUS_EQUATION_2ND_DERIVATIVE: u16 = 0x000C;

const ITM_RCL: i16 = 51;
const ITM_STO: i16 = 44;
const AIM_BUFFER_LENGTH: usize = 1024;
const TMP_STR_LENGTH: usize = 2560;
const EQUATION_PARSER_XEQ: u16 = 1;
const EQUATION_PARSER_MVAR: u16 = 0;
const FIRST_NAMED_VARIABLE: u16 = 256;
const LAST_NAMED_VARIABLE: u16 = 1999;
const ERROR_VARIABLE_NOT_SELECTED: u8 = 57;
const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

const STD_delta_eq: [*:0]const u8 = "\x83\xb4="; // STD_delta "="
const STD_delta_SUB_d: [*:0]const u8 = "\x83\xb4\xa4\x9f"; // STD_delta STD_SUB_d, the step variable's name

// ---------------------------------------------------------------------------
// Globals
// ---------------------------------------------------------------------------
extern var lastErrorCode: u8;
extern var temporaryInformation: u8;
extern var dynamicMenuItem: i16;
extern var currentSolverStatus: u16;
extern var currentSolverVariable: u16;
extern var currentFormula: u16;
extern var currentSolverProgram: u16;
extern var currentDerivProgram: u16;
extern var currentMvarLabel: u16;
extern var significantDigits: u8;
// Set and cleared with the graph accuracy reduction in execute_rpn_function_graphAcc.
extern var graphAccActive: bool;

// defines.h: significantDigits == 0 ? 12 : significantDigits.
inline fn significantDigitsForEqnGraphs() i32 {
    return if (significantDigits == 0) 12 else significantDigits;
}
extern var tmpString: [*c]u8;
extern var errorMessage: [*c]u8;

extern var ctxtReal4: realContext_t;
extern var ctxtReal39: realContext_t;

// ---------------------------------------------------------------------------
// Constants blob accessor: const_1
// ---------------------------------------------------------------------------
inline fn const_1() *align(1) const real_t {
    return consts.c4856();
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
extern fn decNumberCopyAbs(res: *real_t, source: *const real_t) *real_t;
extern fn decNumberSubtract(res: *real_t, op1: *const real_t, op2: *const real_t, ctxt: *realContext_t) *real_t;
extern fn realCompareAbsLessThan(number1: *align(1) const real_t, number2: *align(1) const real_t) bool;

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
inline fn realCopyAbs(source: *const real_t, destination: *real_t) void {
    _ = decNumberCopyAbs(destination, source);
}
inline fn realSubtract(op1: *const real_t, op2: *const real_t, res: *real_t, ctxt: *realContext_t) void {
    _ = decNumberSubtract(res, op1, op2, ctxt);
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
extern fn realSetOne(value: *real_t) void;
// realIsZero macro (decNumberIsZero, DECSPECIAL = 0x70)
inline fn realIsZero(dn: *align(1) const real_t) bool {
    return dn.lsu[0] == 0 and dn.digits == 1 and (dn.bits & 0x70) == 0;
}
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
extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_len: u16, tag: u32) void;
extern fn convertRealToResultRegister(x: *const real_t, dest: calcRegister_t, angle: u32) void;

extern fn getSystemFlag(sf: i32) bool;
extern fn setSystemFlag(sf: c_uint) void;
extern fn clearSystemFlag(sf: c_uint) void;
extern fn saveForUndo() void;
extern fn undo() void;
extern fn fnToReal(unused: u16) void;
extern fn fnFillStack(unused: u16) void;
extern fn execProgram(label: u16) void;
extern fn reallyRunFunction(func: i16, param: u16) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn findNamedVariable(variable_name: [*:0]const u8) calcRegister_t;
extern fn findProgramLabel(label: u16, caller: [*:0]const u8) calcRegister_t;
extern fn compareString(stra: [*c]const u8, strb: [*c]const u8, comparison_type: i32) i32;
extern fn showSoftmenu(id: i16) void;

// deriv_pgm_variable / MVAR-aware sampling externs
const PGM_WAITING: u8 = 2;
const PGM_RUNNING: u8 = 1;
const ERROR_SOLVER_ABORT: u8 = 60;
const MAX_MVAR_DECLARATIONS: u16 = 18;
const ITM_REM: u16 = 1554;
const ITM_MVAR: u16 = 1524;
const STRING_LABEL_VARIABLE: u8 = 253;
const MAX_LABEL_NAME_LENGTH: usize = 14;
extern var programRunStop: u8;
extern var numberOfLabels: u16;
extern var labelList: [*c]abi.LabelList;
extern fn exitKeyWaiting() bool_t;
extern fn getRegisterAsRealQuiet(reg: calcRegister_t, val: *real_t) bool;
extern fn findOrAllocateNamedVariable(variable_name: [*:0]const u8) calcRegister_t;
extern fn getNthString(ptr: [*c]u8, n: i16) [*c]u8;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn checkOpCodeOfStep(step: [*c]const u8, op: u16) bool;
extern fn findNextStep(step: [*c]u8) [*c]u8;
extern fn boundProgramNameLength(nameStart: [*c]const u8, claimedLength: u8) u8;
extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
extern fn saveRegisterSnapshot(reg: calcRegister_t, s: *snap_t) callconv(.c) void;
extern fn restoreRegisterSnapshot(reg: calcRegister_t, s: *snap_t) callconv(.c) void;
const mpz_struct = abi.Mpz;
// registerValueConversions.h's snap_t. real34_t is decQuad, a union over
// `uint64_t longs[2]`, so C aligns the two real slots to 8 and the struct reads
// t@0, r@8, i@24, li@40, siVal@56, siBase@64, tag@68, mem@72, blocks@80. The ABI
// binding for a real34 is a byte array with alignment 1, so the two slots need
// the alignment spelled out or they land seven bytes early -- and the owner that
// writes this struct, register_conversions.zig, declares it the same way.
const snap_t = extern struct {
    t: u8 = 0,
    r: real34_t align(8) = undefined,
    i: real34_t align(8) = undefined,
    li: mpz_struct = undefined,
    siVal: u64 = 0,
    siBase: u32 = 0,
    tag: u32 = 0,
    mem: ?*anyopaque = null,
    blocks: u16 = 0,
};

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

// A program that declares MVARs has more than one thing it could be differentiated with respect to, and the answer depends
// on which, so the MVAR menu is opened for the user to say, the way the solver and the integrator do. The variable key
// stores the point and takes the selection, and f' on the last softkey runs it. Inside a running program, or under another
// engine, there is nobody to press a key: the derivative is taken there and then, with respect to the selected variable.
fn deriv_open_mvar_menu(label: u16, order: u16, solving: bool_t) linksection(runtime.code_section) bool_t {
    if (programRunStop == PGM_RUNNING or solving or getSystemFlag(@bitCast(FLAG_INTING))) {
        return false;
    }
    currentSolverProgram = label - FIRST_LABEL;
    currentMvarLabel = INVALID_VARIABLE; // the menu builds from currentSolverProgram, and its variable key acts for the solver rather than for VARMNU
    currentSolverStatus &= ~SOLVER_STATUS_EQUATION_MODE;
    currentSolverStatus |= if (order == DERIVATIVE_FIRST_CENTRAL) SOLVER_STATUS_EQUATION_1ST_DERIVATIVE else SOLVER_STATUS_EQUATION_2ND_DERIVATIVE;
    currentSolverStatus |= SOLVER_STATUS_INTERACTIVE;
    showSoftmenu(-MNU_MVAR);
    return true;
}

// PGMDRV names the program f' and f" differentiate, the way PGMSLV names the solver's and PGMPLT the plotter's. It is a
// slot of its own so that taking a derivative does not repoint what SOLVE, INT and PLOT will run next.
pub export fn fnPgmDrv(label: u16) linksection(runtime.code_section) callconv(.c) void {
    const resolved: u16 = @bitCast(findProgramLabel(label, "In function fnPgmDrv:"));
    if (resolved != INVALID_VARIABLE) {
        currentDerivProgram = resolved - FIRST_LABEL;
    }
}

// f' and f" in the SOLVE form: from the keyboard the operand is a program and the MVAR menu opens on it, so the variable is
// picked off a softkey. As a program step the operand is a variable, the program is the one PGMDRV named and the variable
// is the parameter.
fn derivativeVariable(variable: u16, order: u16, ti: u8) linksection(runtime.code_section) void {
    var probeValue: real_t = undefined;
    var savedRegister: snap_t = undefined;

    if ((FIRST_UC_LOCAL_LABEL <= variable and variable <= LAST_LOCAL_LABEL) or
        (FIRST_LABEL <= variable and variable <= LAST_LABEL) or
        (REGISTER_X <= @as(i32, variable) and @as(i32, variable) <= REGISTER_T))
    {
        currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA; // a formula left in play would otherwise build the menu from its variables rather than the program's
        fnPgmDrv(variable);
        if (lastErrorCode == ERROR_NONE) {
            _ = deriv_open_mvar_menu(currentDerivProgram + FIRST_LABEL, order, getSystemFlag(@bitCast(FLAG_SOLVING)));
        }
        return;
    }
    if (!(FIRST_NAMED_VARIABLE <= variable and variable <= LAST_NAMED_VARIABLE)) {
        displayCalcErrorMessage(ERROR_OUT_OF_RANGE, ERR_REGISTER_LINE, REGISTER_X);
        runtime.infoUnexpectedParameter("In function derivativeVariable:", variable);
        return;
    }
    if (currentDerivProgram >= numberOfLabels) {
        displayCalcErrorMessage(ERROR_NO_PROGRAM_SPECIFIED, ERR_REGISTER_LINE, REGISTER_X);
        moreInfoOnError("In function derivativeVariable:", "no program named by PGMDRV", null, null);
        return;
    }

    const solving = getSystemFlag(@bitCast(FLAG_SOLVING));
    setSystemFlag(FLAG_SOLVING);
    currentSolverStatus &= ~SOLVER_STATUS_USES_FORMULA;
    currentSolverVariable = variable;
    reallyRunFunction(ITM_STO, currentSolverVariable); // the point comes off the stack, as SOLVE takes its guesses, and calcDeriv reads it from X
    // The sampling stores each point in the variable, so the given point is kept here and put back after, leaving the
    // variable on the value it was differentiated at.
    const restore = getRegisterAsRealQuiet(@bitCast(currentSolverVariable), &probeValue);
    if (restore) {
        saveRegisterSnapshot(@bitCast(currentSolverVariable), &savedRegister);
    }
    calcDerivOfOrder(currentDerivProgram + FIRST_LABEL, order);
    if (restore) {
        restoreRegisterSnapshot(@bitCast(currentSolverVariable), &savedRegister);
    }
    temporaryInformation = ti;
    if (!solving) {
        clearSystemFlag(FLAG_SOLVING);
    }
}

pub export fn fn1stDerivVar(variable: u16) linksection(runtime.code_section) callconv(.c) void {
    derivativeVariable(variable, DERIVATIVE_FIRST_CENTRAL, TI_1ST_DERIVATIVE);
}

pub export fn fn2ndDerivVar(variable: u16) linksection(runtime.code_section) callconv(.c) void {
    derivativeVariable(variable, DERIVATIVE_SECOND_CENTRAL, TI_2ND_DERIVATIVE);
}

fn derivativeEquation(order: u16, ti: u8) linksection(runtime.code_section) void {
    // FLAG_SOLVING suppresses the per-item undo snapshot, so the one calcDeriv takes before sampling
    // survives to be restored, and it is what lets execProgram run a body at all.
    const solving = getSystemFlag(@bitCast(FLAG_SOLVING));

    setSystemFlag(FLAG_SOLVING);
    if (!(currentSolverVariable >= FIRST_NAMED_VARIABLE and currentSolverVariable <= LAST_NAMED_VARIABLE)) {
        // Nothing selected. A formula with exactly one variable leaves no choice, so take it, as fnEqSolvGraph does. A
        // program is excluded: its variables are its MVAR declarations, and a formula in the pool is not one of them.
        // Parsed into the tail of tmpString, as softmenus.c does, to leave aimBuffer alone.
        if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
            equation.parseEquation(currentFormula, EQUATION_PARSER_MVAR, tmpString + TMP_STR_LENGTH - AIM_BUFFER_LENGTH, tmpString);
            if (tmpString[0] != 0 and getNthString(tmpString, 1)[0] == 0) {
                currentSolverVariable = @intCast(findOrAllocateNamedVariable(tmpString));
            }
        }
        if (!(currentSolverVariable >= FIRST_NAMED_VARIABLE and currentSolverVariable <= LAST_NAMED_VARIABLE)) {
            if (!solving) {
                clearSystemFlag(FLAG_SOLVING);
            }
            displayCalcErrorMessage(ERROR_VARIABLE_NOT_SELECTED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            moreInfoOnError("In function derivativeEquation:", "no variable selected for the derivative", null, null);
            return;
        }
    }
    // new method to maintain solver variable
    reallyRunFunction(ITM_RCL, currentSolverVariable);
    // The sampling stores each point in the variable, so its own value is kept here and put back after. A register cannot
    // hold it: for a program the user's code runs in between and reaches every temporary register, which is what used to
    // hand the variable back holding a number out of that program.
    var probeValue: real_t = undefined;
    var savedRegister: snap_t = undefined;
    const restore = currentSolverVariable != INVALID_VARIABLE and getRegisterAsRealQuiet(@bitCast(currentSolverVariable), &probeValue);
    if (restore) {
        saveRegisterSnapshot(@bitCast(currentSolverVariable), &savedRegister);
    }
    if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) == 0 and currentSolverProgram < numberOfLabels) {
        calcDerivOfOrder(currentSolverProgram + FIRST_LABEL, order); // the MVAR menu was opened on a program, so that is what this key differentiates
    } else {
        currentSolverStatus |= SOLVER_STATUS_USES_FORMULA;
        calcDerivOfOrder(INVALID_VARIABLE, order);
    }
    if (restore) {
        restoreRegisterSnapshot(@bitCast(currentSolverVariable), &savedRegister);
    }
    temporaryInformation = ti;
    if (!solving) {
        clearSystemFlag(FLAG_SOLVING);
    }
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
// Is the step variable one of the current formula's own variables? A function that uses it writes to it while it is being
// sampled, so it cannot also be the step. The list searched here is the same parse the MVAR menu is built from. The program
// side of the same question is answered by deriv_pgm_variable, which reports a declaration of the name while it is already
// walking them.
fn deriv_formula_uses_delta() linksection(runtime.code_section) bool_t {
    equation.parseEquation(currentFormula, EQUATION_PARSER_MVAR, tmpString + TMP_STR_LENGTH - AIM_BUFFER_LENGTH, tmpString);
    var i: i16 = 0;
    while (getNthString(tmpString, i)[0] != 0) : (i += 1) {
        if (compareString(getNthString(tmpString, i), STD_delta_SUB_d, CMP_NAME) == 0) {
            return true;
        }
    }
    return false;
}

// The step the user set, which is the step variable. It is taken as it stands and the ladder is not walked at all. False
// means it was not there, h is left alone, and the caller scales it per pass. Asked once per derivative, since none of this
// can change while the ladder runs.
fn deriv_user_step(h: *real_t, usesDelta: bool_t) linksection(runtime.code_section) bool_t {
    var given: real_t = undefined;

    if (!usesDelta) {
        const deltaX = findNamedVariable(STD_delta_SUB_d);
        if (@as(u16, @bitCast(deltaX)) != INVALID_VARIABLE and getRegisterAsRealQuiet(deltaX, &given) and
            !realIsZero(&given) and !realIsSpecial(&given))
        {
            realCopy(&given, h);
            return true;
        }
    }
    return false;
}

// Digits a sample is good for, and how far the step is worth shrinking. Normally 34. While a graph is drawn the calculator
// works to the SDIGS setting instead, so two estimates can never match to 34 digits, the step shrinks all the way down and
// the samples cancel to nothing. The solver reads the same setting for its own tolerance.
fn deriv_tolerance_digits() linksection(runtime.code_section) i32 {
    return if (graphAccActive) @max(significantDigitsForEqnGraphs() - 2, 4) else DERIV_TOLERANCE_DIGITS;
}

fn deriv_last_shift() linksection(runtime.code_section) i32 {
    return if (graphAccActive) @divTrunc(deriv_tolerance_digits(), 2) else DERIV_LAST_SHIFT;
}

// Do two estimates of the same derivative, taken a factor of ten apart in h, agree to better than the cancellation the
// finer one suffers? A sample carries 34 digits and the points are h apart, so differencing them loses the digits they
// share and the error is about 1e-DERIV_TOLERANCE_DIGITS times ten to the shift, for each order of the derivative.
// Agreement means the truncation of the coarser estimate is already below that, so the coarser one is the better of the
// two. The gap between the pair is handed back for the caller to rank the pairs by, whether they agreed or not.
fn deriv_agrees(coarse: *const real_t, fine: *const real_t, shift: i32, order: u8, difference: *real_t) linksection(runtime.code_section) bool_t {
    var tolerance: real_t = undefined;

    realSubtract(fine, coarse, difference, &ctxtReal39);
    if (realIsZero(difference)) {
        return true;
    }
    realCopyAbs(fine, &tolerance);
    tolerance.exponent += shift * @as(i32, order) - deriv_tolerance_digits();
    return realCompareAbsLessThan(difference, &tolerance);
}

// A program that declares MVARs takes its argument from named storage (RCL 'x'), not from the stack, so the
// sample point has to be stored where the program will recall it. Return the variable to perturb, or
// INVALID_VARIABLE for a program that declares none and therefore reads the stack. Among several MVARs the
// caller's selection wins whenever the program declares it, matching what the MVAR softmenu and the
// equation derivative differentiate with respect to; otherwise the first declaration, which is the argument
// by convention and the leftmost key of the MVAR menu.
fn deriv_pgm_variable(label: calcRegister_t, usesDelta: ?*bool_t) linksection(runtime.code_section) calcRegister_t {
    var first: calcRegister_t = @bitCast(INVALID_VARIABLE);

    if (label < @as(calcRegister_t, @bitCast(FIRST_LABEL)) or label > @as(calcRegister_t, @bitCast(LAST_LABEL)) or
        @as(u16, @bitCast(label)) - FIRST_LABEL >= numberOfLabels)
    {
        return @bitCast(INVALID_VARIABLE);
    }
    var step: [*c]u8 = labelList[@as(u16, @bitCast(label)) - FIRST_LABEL].instructionPointer;

    var declared: u16 = 0;
    while (declared < MAX_MVAR_DECLARATIONS) : (declared += 1) {
        while (checkOpCodeOfStep(step, ITM_REM)) { // a REM ahead of an MVAR is transparent, as in the MVAR softmenu
            step = findNextStep(step);
        }
        if (!(checkOpCodeOfStep(step, ITM_MVAR) and step[2] == STRING_LABEL_VARIABLE)) {
            break;
        }
        const nameLength = boundProgramNameLength(step + 4, step[3]);
        if (nameLength == 0 or nameLength > MAX_LABEL_NAME_LENGTH) {
            break;
        }
        var name: [MAX_LABEL_NAME_LENGTH + 1]u8 = undefined;
        _ = xcopy(&name, step + 4, nameLength);
        name[nameLength] = 0;
        if (usesDelta != null and compareString(&name, STD_delta_SUB_d, CMP_NAME) == 0) { // the program declares the step variable, so it writes it and it is no step
            usesDelta.?.* = true;
        }
        const variable = findOrAllocateNamedVariable(@ptrCast(&name));
        if (variable != @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) {
            if (@as(u16, @bitCast(variable)) == currentSolverVariable) {
                return variable;
            }
            if (first == @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) {
                first = variable;
            }
        }
        step = findNextStep(step);
    }
    return first;
}

fn _differentiatorIteration(label: calcRegister_t, variable: calcRegister_t, r0: *real_t) linksection(runtime.code_section) void {
    reallocateRegister(REGISTER_X, dtReal34, 0, amNone);
    realToReal34(r0, registerReal34Ptr(REGISTER_X));
    fnFillStack(NOPARAM);

    if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
        reallyRunFunction(ITM_STO, currentSolverVariable);
        equation.parseEquation(currentFormula, EQUATION_PARSER_XEQ, tmpString, tmpString + AIM_BUFFER_LENGTH);
    } else {
        if (variable != @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) { // feed both channels: the stack for a program that consumes X, the variable for one that recalls its MVAR
            reallyRunFunction(ITM_STO, @bitCast(variable));
        }
        dynamicMenuItem = -1;
        execProgram(@bitCast(label));
        fnToReal(NOPARAM);
    }

    if (lastErrorCode == ERROR_NONE and getRegisterDataType(REGISTER_X) == dtReal34) {
        real34ToReal(registerReal34Ptr(REGISTER_X), r0);
    } else {
        // The function is not defined at this point, maybe outside its domain, so the sample is made a NaN and the stencil
        // that reads it is refused, which makes the ladder take its points closer in. The error must be cleared: left
        // standing, the next sample's fnExecute takes it for its own goto having failed, steps the caller back onto this
        // derivative and restarts it, endlessly.
        if (lastErrorCode != ERROR_SOLVER_ABORT) { // an abort is the one error that stays: calcFuncValues reads it to stop the sampling and the caller to stop the run
            lastErrorCode = ERROR_NONE;
        }
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
fn calcFuncValues(label: calcRegister_t, variable: calcRegister_t, x: *const real_t, fx: [*]real_t, h: *real_t, realContext: *realContext_t) linksection(runtime.code_section) void {
    var t: real_t = undefined;
    var i: i32 = 0;
    while (i < MAX_F_EVAL) : (i += 1) {
        if (lastErrorCode == ERROR_SOLVER_ABORT or programRunStop == PGM_WAITING or exitKeyWaiting()) {
            // calcOneDeriv rejects a stencil only on the samples that stencil reads, so a narrow one would
            // still succeed on the points already taken and hand back a value beside the abort. Poison them
            // all to make the abort the only outcome.
            lastErrorCode = ERROR_SOLVER_ABORT;
            if (programRunStop == PGM_RUNNING) { // halt the outer program too, as every other abort point does
                programRunStop = PGM_WAITING;
            }
            var j: i32 = 0;
            while (j < MAX_F_EVAL) : (j += 1) {
                realSetNaN(&fx[@intCast(j)]);
            }
            return;
        }
        int32ToReal(i - MAX_ORDER, &t);
        realFMA(&t, h, x, &fx[@intCast(i)], realContext);
        _differentiatorIteration(label, variable, &fx[@intCast(i)]);
    }
}

// Evaluate the function at stencil points and compute "best" estimate
fn calcDeriv(label: calcRegister_t, finDiff: [*]const ?*const FINITE_DIFF_COEFF) linksection(runtime.code_section) void {
    var x: real_t = undefined;
    var h: real_t = undefined;
    var probeValue: real_t = undefined;
    var estimate: real_t = undefined;
    var coarse: real_t = undefined;
    var gap: real_t = undefined;
    var best: real_t = undefined;
    var bestGap: real_t = undefined;
    var fx: [@intCast(MAX_F_EVAL)]real_t = undefined;
    var savedRegister: snap_t = undefined;
    var variable: calcRegister_t = @bitCast(INVALID_VARIABLE);
    var userStep: bool_t = false;
    var usesDelta: bool_t = false;
    var coarseStencil: i32 = -1;
    var coarseShift: i32 = 0;
    var bestShift: i32 = 0;
    const lastShift = deriv_last_shift();

    if (!getRegisterAsReal(REGISTER_X, &x)) {
        return;
    }

    var haveResult = false;

    if (!realIsSpecial(&x)) {
        if ((currentSolverStatus & SOLVER_STATUS_USES_FORMULA) != 0) {
            usesDelta = deriv_formula_uses_delta();
        } else {
            const probeError = lastErrorCode; // an MVAR name the variable allocator rejects raises here, before any sampling the caller asked for

            lastErrorCode = ERROR_NONE;
            variable = deriv_pgm_variable(label, &usesDelta);
            if (lastErrorCode != ERROR_NONE) { // no room for the MVAR: the user is told, rather than given the wrong answer a fall back to the stack would return
                return;
            }
            lastErrorCode = probeError;
            if (variable != @as(calcRegister_t, @bitCast(INVALID_VARIABLE)) and !getRegisterAsRealQuiet(variable, &probeValue)) {
                variable = @bitCast(INVALID_VARIABLE); // differentiate only with respect to something numeric
            }
        }

        userStep = deriv_user_step(&h, usesDelta);

        // Walk the step down a decade at a time. Each step gives one estimate, and two estimates from the same stencil
        // that agree say the coarser step's truncation is already lost in the noise, so the coarser one is taken: it is
        // the one that threw away the fewest digits. A step the user set is taken as it stands, so the first pass is the
        // only one.
        var settled = false;
        var shift: i32 = DERIV_FIRST_SHIFT;
        while (shift <= lastShift) : (shift += 1) {
            if (variable != @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) {
                // Kept here rather than in a register: the user program runs between the save and the restore and every
                // temporary register is scratch to something it can call, RCL of a stack register among them. The snapshot
                // carries the type and the tag, so the value comes back as itself and not as the real34 the sampling
                // stored. It is taken again for each step, because the restore hands back the long integer it holds.
                // getRegisterAsRealQuiet has already turned away everything the snapshot does not cover.
                saveRegisterSnapshot(variable, &savedRegister);
            }
            if (!userStep) {
                realCopy(&x, &h); // the step is relative to x, and at x = 0 it collapses and the weighted sum would be divided by zero
                if (realIsZero(&h)) {
                    realCopy(const_1(), &h);
                }
                h.exponent -= shift;
            }

            // Compute the function at the finite difference points
            saveForUndo();
            calcFuncValues(label, variable, &x, &fx, &h, &ctxtReal39);
            undo();
            if (variable != @as(calcRegister_t, @bitCast(INVALID_VARIABLE))) { // undo() rolls back the stack only, so the sampled variable is put back here
                restoreRegisterSnapshot(variable, &savedRegister);
            }
            if (lastErrorCode == ERROR_SOLVER_ABORT) {
                break;
            }

            // Try finite differences until we get a result
            var stencil: i32 = -1;
            var i: usize = 0;
            while (finDiff[i] != null) : (i += 1) {
                if (calcOneDeriv(finDiff[i].?, &fx, &h, &estimate, &ctxtReal39)) {
                    stencil = @intCast(i);
                    break;
                }
            }
            if (stencil < 0) { // every stencil rejected this step's samples, so take the points closer in. A step the user set does not move, so there is nothing to retry
                if (userStep) {
                    break;
                }
                continue;
            }
            if (userStep) {
                realCopy(&estimate, &x);
                haveResult = true;
                break;
            }
            if (stencil == coarseStencil) {
                if (deriv_agrees(&coarse, &estimate, shift, finDiff[@intCast(stencil)].?.order, &gap)) {
                    settled = true;
                    break;
                }
                // The two are a decade apart, so the gap between them is smallest where the truncation of the coarser one
                // and the cancellation of the finer one balance. The coarser member of the closest pair is therefore the
                // best the ladder saw, and it is what the answer falls back to when no pair ever agrees.
                if (bestShift == 0 or realCompareAbsLessThan(&gap, &bestGap)) {
                    realCopy(&coarse, &best);
                    realCopy(&gap, &bestGap);
                    bestShift = coarseShift;
                }
            }
            realCopy(&estimate, &coarse);
            coarseStencil = stencil;
            coarseShift = shift;
        }

        if (!haveResult) settle: {
            if (!settled) {
                if (coarseStencil < 0) { // no step gave a usable set of samples
                    break :settle;
                }
                if (bestShift != 0) { // the ladder ran out without a pair ever agreeing, so the closest pair is as near as this function gets
                    realCopy(&best, &coarse);
                    coarseShift = bestShift;
                }
            }
            // The coarser of the two estimates is the answer, and its own step is what the display reports.
            realCopy(&x, &h);
            if (realIsZero(&h)) {
                realCopy(const_1(), &h);
            }
            h.exponent -= coarseShift;
            realCopy(&coarse, &x);
            haveResult = true;
        }
    }

    if (haveResult) {
        // Add string, for display at TI
        var c: realContext_t = ctxtReal4;
        c.digits = 2;
        var hh: real_t = undefined;
        realPlus(&h, &hh, &c);
        _ = strcpy(errorMessage, STD_delta_eq);
        _ = decNumberToString(&hh, errorMessage + @as(usize, @intCast(stringByteLength(errorMessage))));
        _ = strcat(errorMessage, "; ");
    } else {
        // No estimate possible
        realSetNaN(&x);
        // Add string, for display at TI
        errorMessage[0] = 0;
    }

    convertRealToResultRegister(&x, REGISTER_X, amNone);
}
