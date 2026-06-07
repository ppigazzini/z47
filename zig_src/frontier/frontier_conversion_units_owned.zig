// SPDX-License-Identifier: GPL-3.0-only
//
// Zig owner for src/c47/conversionUnits.c: the unit-conversion command surface
// (fnUnitConvert + the conversionFactors table, temperature/angle/fuel-economy/
// HMS/dB conversions). Exported with C linkage and force-included by
// frontier.zig. All 13 entry points are testSuite-covered.
//
// Conversion constants are macros into a single `extern const uint8_t constants[]`
// blob; their byte offsets (stable across build configs) are generated from
// constantPointers.h, and pointers are formed at runtime from the linked base.

const build_options = @import("frontier_build_options");
const extra_info: bool = build_options.extra_info_on_calc_error;

const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const amNone: c_int = 5;
const amRadian: c_int = 0;
const amGrad: c_int = 1;
const amDegree: c_int = 2;
const amAngleMask: u32 = 15;
const dtReal34: u32 = 1;
const multiply: u16 = 0;
const divide: u16 = 0x8000;
const inverting: bool = true;
const noninverting: bool = false;
const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
const FLAG_SPCRES: i32 = 0x8017;

const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [25]u16,
};
const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: c_int,
    traps: u32,
    status: u32,
    clamp: u8,
};

extern var ctxtReal39: realContext_t;
// `constants` is an extern byte array; @extern yields a pointer to its base.
const constants = @extern([*]const u8, .{ .name = "constants" });

extern fn decNumberMultiply(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;

extern fn getRegisterAsReal(reg: i16, value: *real_t) bool;
extern fn saveLastX() bool;
extern fn getSystemFlag(flag: i32) bool;
extern fn convertRealToResultRegister(src: *align(1) const real_t, dest: i16, angle: c_int) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_line: i16, err_register_line: i16) void;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn adjustResult(res: i16, drop_y: bool, set_cpx: bool, op1: i16, op2: i16, op3: i16) void;
extern fn getRegisterDataType(reg: i16) u32;
extern fn getRegisterTag(reg: i16) u32;
extern fn setRegisterTag(reg: i16, tag: u32) void;
extern fn fnHMStoTM(p: u16) void;
extern fn fnToReal(p: u16) void;
extern fn fnHRtoTM(p: u16) void;
extern fn fnFrom_ms(p: u16) void;
extern fn WP34S_Log10(x: *const real_t, res: *real_t, ctx: *realContext_t) void;
extern fn realPower10(x: *const real_t, res: *real_t, ctx: *realContext_t) void;

// `constants` is a byte array (alignment 1); the C macros cast (real_t *) and
// access it unaligned, which arm64/x86/Cortex-M tolerate. Return an align(1)
// pointer so we match that without asserting 4-byte alignment.
inline fn cst(offset: u32) *align(1) const real_t {
    return @ptrCast(constants + offset);
}
inline fn realIsZero(r: *const real_t) bool {
    return r.digits == 1 and r.lsu[0] == 0 and (r.bits & 0x70) == 0;
}
inline fn realIsNegative(r: *const real_t) bool {
    return (r.bits & 0x80) != 0;
}
inline fn rMul(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t) void {
    _ = decNumberMultiply(res, a, b, &ctxtReal39);
}
inline fn rDiv(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t) void {
    _ = decNumberDivide(res, a, b, &ctxtReal39);
}
inline fn rAdd(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t) void {
    _ = decNumberAdd(res, a, b, &ctxtReal39);
}
inline fn rSub(a: *align(1) const real_t, b: *align(1) const real_t, res: *real_t) void {
    _ = decNumberSubtract(res, a, b, &ctxtReal39);
}
inline fn getRegisterAngularMode(reg: i16) c_int {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}
inline fn setRegisterAngularMode(reg: i16, am: u32) void {
    setRegisterTag(reg, am);
}

// ---- generated data (offsets into `constants`); see scripted port note ----
const OFF_const_minusInfinity = 1684;
const OFF_const_plusInfinity = 1696;
const OFF_const_0 = 1708;
const OFF_const_1 = 4368;
const OFF_const_9on5 = 4428;
const OFF_const_32 = 4736;
const OFF_const_273p15 = 3808;
const OFF_const_459p67 = 3824;
const OFF_const39_kBeVK = 3840;
const OFF_const_9on10 = 4320;
const OFF_const39_180onPi = 4772;
const OFF_const39_200onPi = 4820;
const OFF_const_GaluseqE = 5320;
const OFF_const_100 = 7024;
const OFF_const_GalusToL = 2628;
const OFF_const_MiToKm = 2048;
const OFF_const_GalukToL = 2648;
const OFF_const_10 = 4644;
const OFF_const_20 = 4668;

// conversionFactors[constFactorEND]: offset into `constants`, or null.
const conversionFactorOffsets = [_]?u32{
    1948, // 0 constFactorFt2Hectare = const_Ft2ToHa
    1964, // 1 constFactorFt2M2 = const_Ft2ToM2
    7024, // 2 constFactorHectareKm2 = const_100
    2444, // 3 constFactorAcreHa = const_AccreToHa
    2464, // 4 constFactorAcreusHa = const39_AccreusToHa
    3060, // 5 constFactorAtmPa = const_AtmToPa
    2152, // 6 constFactorAuM = const_AuToM
    3048, // 7 constFactorBarPa = const_BarToPa
    2868, // 8 constFactorBtuJ = const_BtuToJ
    2852, // 9 constFactorCalJ = const_CalToJ
    3144, // 10 constFactorLbfftNm = const_LbfftToNm
    2796, // 11 constFactorCwtKg = const_CwtToKg
    1932, // 12 constFactorFtM = const_FtToM
    1980, // 13 constFactorSfeetM = const39_SfeetToM
    2548, // 14 constFactorFlozukIn3 = const_FlozukToIn3
    2512, // 15 constFactorFlozukMl = const_FlozukToMl
    2580, // 16 constFactorFlozusIn3 = const_FlozusToIn3
    2528, // 17 constFactorFlozusMl = const_FlozusToMl
    2596, // 18 constFactorFt3toGalUS = const_Ft3ToGalUS
    2648, // 19 constFactorGalukL = const_GalukToL
    2628, // 20 constFactorGalusL = const_GalusToL
    3116, // 21 constFactorHpeW = const_HpeToW
    3076, // 22 constFactorHpmW = const_HpmToW
    3092, // 23 constFactorHpukW = const_HpukToW
    2996, // 24 constFactorInhgPa = const_InhgToPa
    1920, // 25 constFactorInchMm = const_InchToMm
    2888, // 26 constFactorWhJ = const_WhToJ
    2748, // 27 constFactorLbKg = const_LbToKg
    2712, // 28 constFactorOzG = const_OzToG
    2780, // 29 constFactorShortcwtKg = const_ShortcwtToKg
    2764, // 30 constFactorStoneKg = const_StoneToKg
    2816, // 31 constFactorShorttonKg = const_ShorttonToKg
    2832, // 32 constFactorTonKg = const_TonToKg
    4668, // 33 constFactorLiangKg = const_20
    2732, // 34 constFactorTrozG = const_TrozToG
    2924, // 35 constFactorLbfN = const_LbfToN
    2172, // 36 constFactorLyM = const_LyToM
    2980, // 37 constFactorMmhgPa = const_MmhgToPa
    2048, // 38 constFactorMiKm = const_MiToKm
    2084, // 39 constFactorNmiKm = const_NmiToKm
    2192, // 40 constFactorPcM = const39_PcToM
    1884, // 41 constFactorPointMm = const39_PointToMm
    2312, // 42 constFactorMileM = const_MiToM
    2016, // 43 constFactorYardM = const_YardToM
    3012, // 44 constFactorPsiPa = const39_PsiToPa
    2944, // 45 constFactorTorrPa = const39_TorrToPa
    3128, // 46 constFactorYearS = const_YearToS
    2700, // 47 constFactorCaratG = const_CaratToG
    4440, // 48 constFactorJinKg = const_2
    2664, // 49 constFactorQuartL = const_QuartToL
    2032, // 50 constFactorFathomM = const_FathomToM
    2328, // 51 constFactorNMiM = const_NmiToM
    2680, // 52 constFactorBarrelM3 = const_BarrelToM3
    5024, // 53 constFactorHectareM2 = const_10000
    2500, // 54 constFactorMuM2 = const_MuToM2
    2228, // 55 constFactorLiM = const_LiToM
    4524, // 56 constFactorChiM = const_3
    2264, // 57 constFactorYinM = const_YinToM
    2276, // 58 constFactorCunM = const_CunToM
    2288, // 59 constFactorZhangM = const_ZhangToM
    2300, // 60 constFactorFenM = const_FenToM
    2064, // 61 constFactorMi2Km2 = const_MiSqToKmSq
    2136, // 62 constFactorNmi2Km2 = const_NmiSqToKmSq
    2344, // 63 constFactorKmphmps = const39_Kmphmps
    2380, // 64 constFactorRpmDegps = const_RpmDegps
    2392, // 65 constFactorMphmps = const_Mphmps
    2408, // 66 constFactorRpmRadps = const39_RpmRadps
    3796, // 67 constFactorInchCm = const_InchToCm
    2100, // 68 constFactorNmiMi = const39_NmiToMi
    3168, // 69 constFactorFurtom = const_furToM
    3184, // 70 constFactorFtntos = const_ftnToS
    3200, // 71 constFactorFpftomps = const_fpfToMps
    3220, // 72 constFactorBrdstom = const_brdsTom
    3232, // 73 constFactorFirtokg = const_firToKg
    3248, // 74 constFactorFpftokph = const_fpfToKph
    3268, // 75 constFactorBrdstoin = const_brdsToIn
    3288, // 76 constFactorFirtolb = const_firToLb
    3312, // 77 constFactorFpftomph = const_fpfToMph
    3332, // 78 constFactorFpstokph = const_fpsToKph
    3348, // 79 constFactorFpstomps = const_fpsToMps
    7024, // 80 constFactorL100Tokml = const_100
    null, // 81 constFactorKmletok100K
    7024, // 82 constFactorK100Ktokmk = const_100
    null, // 83 constFactorL100Tomgus
    null, // 84 constFactorMgeustok100M
    2048, // 85 constFactorK100Ktok100M = const_MiToKm
    null, // 86 constFactorL100Tomguk
    null, // 87 constFactorMgeuktok100M
    7024, // 88 constFactorK100Mtomik = const_100
    3364, // 89 constFactorCupcFzus = const_CupcFzus
    3376, // 90 constFactorCupcMl = const_CupcMl
    3396, // 91 constFactorCupukFzuk = const_CupukFzuk
    3408, // 92 constFactorCupukMl = const_CupukMl
    3396, // 93 constFactorFzukCupuk = const_CupukFzuk
    3424, // 94 constFactorFzukTbspuk = const_FzukTbspuk
    3436, // 95 constFactorFzukTspuk = const_FzukTspuk
    3364, // 96 constFactorFzusCupc = const_CupcFzus
    3448, // 97 constFactorFzusTbspc = const_FzusTbspc
    3460, // 98 constFactorFzusTspc = const_FzusTspc
    3376, // 99 constFactorMlCupc = const_CupcMl
    3408, // 100 constFactorMlCupuk = const_CupukMl
    3472, // 101 constFactorMlPintlq = const_PintlqMl
    3488, // 102 constFactorMlPintuk = const_PintukMl
    3504, // 103 constFactorMlQt = const_QtMl
    3520, // 104 constFactorMlQtus = const_QtusMl
    3536, // 105 constFactorMlTbspc = const_TbspcMl
    3556, // 106 constFactorMlTbspuk = const_TbspukMl
    3576, // 107 constFactorMlTspc = const_TspcMl
    3596, // 108 constFactorMlTspuk = const39_TspukMl
    3472, // 109 constFactorPintlqMl = const_PintlqMl
    3488, // 110 constFactorPintukMl = const_PintukMl
    3504, // 111 constFactorQtMl = const_QtMl
    3520, // 112 constFactorQtusMl = const_QtusMl
    3448, // 113 constFactorTbspcFzus = const_FzusTbspc
    3536, // 114 constFactorTbspcMl = const_TbspcMl
    3424, // 115 constFactorTbspukFzuk = const_FzukTbspuk
    3556, // 116 constFactorTbspukMl = const_TbspukMl
    3460, // 117 constFactorTspcFzus = const_FzusTspc
    3576, // 118 constFactorTspcMl = const_TspcMl
    3436, // 119 constFactorTspukFzuk = const_FzukTspuk
    3596, // 120 constFactorTspukMl = const39_TspukMl
    3632, // 121 constFactorMlIn3 = const_In3Ml
    3632, // 122 constFactorIn3Ml = const_In3Ml
    3648, // 123 constFactorFt3Gluk = const_Ft3Gluk
    3648, // 124 constFactorGlukFt3 = const_Ft3Gluk
    3684, // 125 constFactorLFt3 = const_Ft3L
    3684, // 126 constFactorFt3L = const_Ft3L
    3704, // 127 constFactorLQtus = const_LQtus
    3704, // 128 constFactorQtusL = const_LQtus
    3724, // 129 constFactorGlukFzuk = const_GlukFzuk
    3724, // 130 constFactorFzukGluk = const_GlukFzuk
    3736, // 131 constFactorGlusFzus = const_GlusFzus
    3736, // 132 constFactorFzusGlus = const_GlusFzus
    156, // 133 constFactoreVJ = const_e
    156, // 134 constFactorJeV = const_e
    3748, // 135 constFactormmBanana = const_bananamm
    3748, // 136 constFactorBananamm = const_bananamm
    3760, // 137 constFactorInchBanana = const39_bananaInch
    3760, // 138 constFactorBananaInch = const39_bananaInch
    2900, // 139 constFactorErgJ = const_ErgToJ
    2912, // 140 constFactorFoeJ = const_FoeToJ
};

// (x - B) / C * D + E temperature-conversion coefficient offsets (see cvtTempConsts).
const cvtTempOffsets = [12][4]u32{
    .{ OFF_const_0, OFF_const_1, OFF_const_9on5, OFF_const_32 }, // C->F
    .{ OFF_const_32, OFF_const_9on5, OFF_const_1, OFF_const_0 }, // F->C
    .{ OFF_const_0, OFF_const_1, OFF_const_1, OFF_const_273p15 }, // C->K
    .{ OFF_const_273p15, OFF_const_1, OFF_const_1, OFF_const_0 }, // K->C
    .{ OFF_const_0, OFF_const_9on5, OFF_const_1, OFF_const_0 }, // RA->K
    .{ OFF_const_0, OFF_const_1, OFF_const_9on5, OFF_const_0 }, // K->RA
    .{ OFF_const_459p67, OFF_const_1, OFF_const_1, OFF_const_0 }, // RA->F
    .{ OFF_const_0, OFF_const_1, OFF_const_1, OFF_const_459p67 }, // F->RA
    .{ OFF_const_0, OFF_const39_kBeVK, OFF_const_1, OFF_const_0 }, // EVKB->K
    .{ OFF_const_0, OFF_const_1, OFF_const39_kBeVK, OFF_const_0 }, // K->EVKB
    .{ OFF_const_32, OFF_const_9on5, OFF_const_1, OFF_const_273p15 }, // F->K
    .{ OFF_const_273p15, OFF_const_1, OFF_const_9on5, OFF_const_32 }, // K->F
};

fn unitConversion(coefficient: *align(1) const real_t, multiply_divide: u16, invert: bool) void {
    var re_x: real_t = undefined;

    if (!getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;

    if (invert and realIsZero(&re_x)) {
        if (getSystemFlag(FLAG_SPCRES)) {
            convertRealToResultRegister(cst(if (realIsNegative(&re_x)) OFF_const_minusInfinity else OFF_const_plusInfinity), REGISTER_X, amNone);
        } else {
            displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) moreInfoOnError("In function unitConversion:", "cannot calculate divide by zero", null, null);
        }
    }

    if (invert) rDiv(cst(OFF_const_1), &re_x, &re_x);
    if (multiply_divide == multiply) rMul(&re_x, coefficient, &re_x) else rDiv(&re_x, coefficient, &re_x);

    convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}

pub export fn fnUnitConvert(arg: u16) callconv(.c) void {
    const md: u16 = arg & 0x8000;
    const invert = (arg & 0x4000) != 0;
    const idx: usize = arg & 0x3fff;
    if (conversionFactorOffsets[idx]) |offset| {
        unitConversion(cst(offset), md, invert);
    }
}

pub export fn fnCvtTemp(ix: u16) callconv(.c) void {
    var re_x: real_t = undefined;
    if (!getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;

    const row = cvtTempOffsets[ix];
    if (row[0] != OFF_const_0) rSub(&re_x, cst(row[0]), &re_x);
    if (row[1] != OFF_const_1) rDiv(&re_x, cst(row[1]), &re_x);
    if (row[2] != OFF_const_1) rMul(&re_x, cst(row[2]), &re_x);
    if (row[3] != OFF_const_0) rAdd(&re_x, cst(row[3]), &re_x);

    convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}

inline fn cvtAngle(reg_mode_a: c_int, reg_mode_b: c_int, multiply_divide: u16, coeff_offset: u32) void {
    if (getRegisterDataType(REGISTER_X) == dtReal34 and
        ((getRegisterAngularMode(REGISTER_X) == reg_mode_a and multiply_divide == divide) or
            (getRegisterAngularMode(REGISTER_X) == reg_mode_b and multiply_divide == multiply)))
    {
        setRegisterAngularMode(REGISTER_X, amNone);
    }
    unitConversion(cst(coeff_offset), multiply_divide, noninverting);
}

pub export fn fnCvtDegRad(multiply_divide: u16) callconv(.c) void {
    cvtAngle(amDegree, amRadian, multiply_divide, OFF_const39_180onPi);
}
pub export fn fnCvtDegGrad(multiply_divide: u16) callconv(.c) void {
    cvtAngle(amDegree, amGrad, multiply_divide, OFF_const_9on10);
}
pub export fn fnCvtGradRad(multiply_divide: u16) callconv(.c) void {
    cvtAngle(amGrad, amRadian, multiply_divide, OFF_const39_200onPi);
}

pub export fn fnKmletok100K(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide; // bidirectional formula
    var factor: real_t = undefined;
    rMul(cst(OFF_const_GaluseqE), cst(OFF_const_100), &factor);
    rDiv(&factor, cst(OFF_const_GalusToL), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnL100Tomgus(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(cst(OFF_const_100), cst(OFF_const_GalusToL), &factor);
    rDiv(&factor, cst(OFF_const_MiToKm), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnMgeustok100M(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(cst(OFF_const_GaluseqE), cst(OFF_const_100), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnL100Tomguk(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(cst(OFF_const_100), cst(OFF_const_GalukToL), &factor);
    rDiv(&factor, cst(OFF_const_MiToKm), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnMgeuktok100M(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(cst(OFF_const_GaluseqE), cst(OFF_const_100), &factor);
    rMul(&factor, cst(OFF_const_GalukToL), &factor);
    rDiv(&factor, cst(OFF_const_GalusToL), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnCvtHMSHR(multiply_divide: u16) callconv(.c) void {
    if (multiply_divide == divide) {
        fnHMStoTM(0);
        fnToReal(0);
    } else {
        fnHRtoTM(0);
        fnFrom_ms(0);
    }
}

pub export fn fnCvtRatioDb(ten_or_twenty: u16) callconv(.c) void {
    var re_x: real_t = undefined;
    if (!getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;
    WP34S_Log10(&re_x, &re_x, &ctxtReal39);
    rMul(&re_x, cst(if (ten_or_twenty == 10) OFF_const_10 else OFF_const_20), &re_x);
    convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}

pub export fn fnCvtDbRatio(ten_or_twenty: u16) callconv(.c) void {
    var re_x: real_t = undefined;
    if (!getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;
    rDiv(&re_x, cst(if (ten_or_twenty == 10) OFF_const_10 else OFF_const_20), &re_x);
    realPower10(&re_x, &re_x, &ctxtReal39);
    convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}
