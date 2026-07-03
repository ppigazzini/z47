// SPDX-License-Identifier: GPL-3.0-only
const consts = abi.constants;
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

const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real_t = abi.Real;
const realContext_t = abi.RealContext;

extern var ctxtReal39: realContext_t;
// `constants` is an extern byte array; @extern yields a pointer to its base.

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
const cst = consts.cstR;
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
const OFF_const_1 = 4856;
const OFF_const_9on5 = 4916;
const OFF_const_32 = 5224;
const OFF_const_273p15 = 3916;
const OFF_const_459p67 = 3932;
const OFF_const39_kBeVK = 3948;
const OFF_const_9on10 = 4808;
const OFF_const39_180onPi = 5260;
const OFF_const39_200onPi = 5308;
const OFF_const_10 = 5132;
const OFF_const_20 = 5156;

// conversionFactors[constFactorEND]: offset into `constants`, or null.
const conversionFactorOffsets = [_]?u32{
    1948, // 0 constFactorFt2Hectare = const_Ft2ToHa
    1964, // 1 constFactorFt2M2 = const_Ft2ToM2
    7532, // 2 constFactorHectareKm2 = const_100
    2444, // 3 constFactorAcreHa = const_AccreToHa
    2464, // 4 constFactorAcreusHa = const39_AccreusToHa
    3168, // 5 constFactorAtmPa = const_AtmToPa
    2152, // 6 constFactorAuM = const_AuToM
    3156, // 7 constFactorBarPa = const_BarToPa
    2976, // 8 constFactorBtuJ = const_BtuToJ
    2960, // 9 constFactorCalJ = const_CalToJ
    3252, // 10 constFactorLbfftNm = const_LbfftToNm
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
    3224, // 21 constFactorHpeW = const_HpeToW
    3184, // 22 constFactorHpmW = const_HpmToW
    3200, // 23 constFactorHpukW = const_HpukToW
    3104, // 24 constFactorInhgPa = const_InhgToPa
    1920, // 25 constFactorInchMm = const_InchToMm
    2996, // 26 constFactorWhJ = const_WhToJ
    2748, // 27 constFactorLbKg = const_LbToKg
    2712, // 28 constFactorOzG = const_OzToG
    2780, // 29 constFactorShortcwtKg = const_ShortcwtToKg
    2764, // 30 constFactorStoneKg = const_StoneToKg
    2816, // 31 constFactorShorttonKg = const_ShorttonToKg
    2832, // 32 constFactorTonKg = const_LongtonToKg
    5156, // 33 constFactorLiangKg = const_20
    2732, // 34 constFactorTrozG = const_TrozToG
    3032, // 35 constFactorLbfN = const_LbfToN
    2172, // 36 constFactorLyM = const_LyToM
    3088, // 37 constFactorMmhgPa = const_MmhgToPa
    2048, // 38 constFactorMiKm = const_MiToKm
    2084, // 39 constFactorNmiKm = const_NmiToKm
    2192, // 40 constFactorPcM = const39_PcToM
    1884, // 41 constFactorPointMm = const39_PointToMm
    2312, // 42 constFactorMileM = const_MiToM
    2016, // 43 constFactorYardM = const_YardToM
    3120, // 44 constFactorPsiPa = const39_PsiToPa
    3052, // 45 constFactorTorrPa = const39_TorrToPa
    3236, // 46 constFactorYearS = const_YearToS
    2700, // 47 constFactorCaratG = const_CaratToG
    4928, // 48 constFactorJinKg = const_2
    2664, // 49 constFactorQuartL = const_QuartToL
    2032, // 50 constFactorFathomM = const_FathomToM
    2328, // 51 constFactorNMiM = const_NmiToM
    2680, // 52 constFactorBarrelM3 = const_BarrelToM3
    5512, // 53 constFactorHectareM2 = const_10000
    2500, // 54 constFactorMuM2 = const_MuToM2
    2228, // 55 constFactorLiM = const_LiToM
    5012, // 56 constFactorChiM = const_3
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
    3904, // 67 constFactorInchCm = const_InchToCm
    2100, // 68 constFactorNmiMi = const39_NmiToMi
    3276, // 69 constFactorFurtom = const_furToM
    3292, // 70 constFactorFtntos = const_ftnToS
    3308, // 71 constFactorFpftomps = const_fpfToMps
    3328, // 72 constFactorBrdstom = const_brdsTom
    3340, // 73 constFactorFirtokg = const_firToKg
    3356, // 74 constFactorFpftokph = const_fpfToKph
    3376, // 75 constFactorBrdstoin = const_brdsToIn
    3396, // 76 constFactorFirtolb = const_firToLb
    3420, // 77 constFactorFpftomph = const_fpfToMph
    3440, // 78 constFactorFpstokph = const_fpsToKph
    3456, // 79 constFactorFpstomps = const_fpsToMps
    7532, // 80 constFactorL100Tokml = const_100
    null, // 81 constFactorKmletok100K (no factor)
    7532, // 82 constFactorK100Ktokmk = const_100
    null, // 83 constFactorL100Tomgus (no factor)
    null, // 84 constFactorMgeustok100M (no factor)
    2048, // 85 constFactorK100Ktok100M = const_MiToKm
    null, // 86 constFactorL100Tomguk (no factor)
    null, // 87 constFactorMgeuktok100M (no factor)
    7532, // 88 constFactorK100Mtomik = const_100
    3472, // 89 constFactorCupcFzus = const_CupcFzus
    3484, // 90 constFactorCupcMl = const_CupcMl
    3504, // 91 constFactorCupukFzuk = const_CupukFzuk
    3516, // 92 constFactorCupukMl = const_CupukMl
    3504, // 93 constFactorFzukCupuk = const_CupukFzuk
    3532, // 94 constFactorFzukTbspuk = const_FzukTbspuk
    3544, // 95 constFactorFzukTspuk = const_FzukTspuk
    3472, // 96 constFactorFzusCupc = const_CupcFzus
    3556, // 97 constFactorFzusTbspc = const_FzusTbspc
    3568, // 98 constFactorFzusTspc = const_FzusTspc
    3484, // 99 constFactorMlCupc = const_CupcMl
    3516, // 100 constFactorMlCupuk = const_CupukMl
    3580, // 101 constFactorMlPintlq = const_PintlqMl
    3596, // 102 constFactorMlPintuk = const_PintukMl
    3612, // 103 constFactorMlQt = const_QtMl
    3628, // 104 constFactorMlQtus = const_QtusMl
    3644, // 105 constFactorMlTbspc = const_TbspcMl
    3664, // 106 constFactorMlTbspuk = const_TbspukMl
    3684, // 107 constFactorMlTspc = const_TspcMl
    3704, // 108 constFactorMlTspuk = const39_TspukMl
    3580, // 109 constFactorPintlqMl = const_PintlqMl
    3596, // 110 constFactorPintukMl = const_PintukMl
    3612, // 111 constFactorQtMl = const_QtMl
    3628, // 112 constFactorQtusMl = const_QtusMl
    3556, // 113 constFactorTbspcFzus = const_FzusTbspc
    3644, // 114 constFactorTbspcMl = const_TbspcMl
    3532, // 115 constFactorTbspukFzuk = const_FzukTbspuk
    3664, // 116 constFactorTbspukMl = const_TbspukMl
    3568, // 117 constFactorTspcFzus = const_FzusTspc
    3684, // 118 constFactorTspcMl = const_TspcMl
    3544, // 119 constFactorTspukFzuk = const_FzukTspuk
    3704, // 120 constFactorTspukMl = const39_TspukMl
    3740, // 121 constFactorMlIn3 = const_In3Ml
    3740, // 122 constFactorIn3Ml = const_In3Ml
    3756, // 123 constFactorFt3Gluk = const_Ft3Gluk
    3756, // 124 constFactorGlukFt3 = const_Ft3Gluk
    3792, // 125 constFactorLFt3 = const_Ft3L
    3792, // 126 constFactorFt3L = const_Ft3L
    3812, // 127 constFactorLQtus = const_LQtus
    3812, // 128 constFactorQtusL = const_LQtus
    3832, // 129 constFactorGlukFzuk = const_GlukFzuk
    3832, // 130 constFactorFzukGluk = const_GlukFzuk
    3844, // 131 constFactorGlusFzus = const_GlusFzus
    3844, // 132 constFactorFzusGlus = const_GlusFzus
    156, // 133 constFactoreVJ = const_e
    156, // 134 constFactorJeV = const_e
    3856, // 135 constFactormmBanana = const_bananamm
    3856, // 136 constFactorBananamm = const_bananamm
    3868, // 137 constFactorInchBanana = const39_bananaInch
    3868, // 138 constFactorBananaInch = const39_bananaInch
    3008, // 139 constFactorErgJ = const_ErgToJ
    3020, // 140 constFactorFoeJ = const_FoeToJ
    2852, // 141 constFactorKnotMps = const39_KnotToMps
    5260, // 142 constFactor180onPi = const39_180onPi
    2888, // 143 constFactorSlugKg = const39_SlugToKg
    2924, // 144 constFactorSlinchKg = const39_SlinchToKg
    2924, // 145 constFactorBlobKg = const39_SlinchToKg
    5380, // 146 constFactorTonneKg = const_1000
    4060, // 147 constFactorLbsft2Pa = const39_Lbsft2ToPa
    4036, // 148 constFactorInlbsNm = const_InlbsToNm
    2888, // 149 constFactorLbsftNpm = const39_SlugToKg
    436, // 150 constFactorKgfN = const_gEarth
    4096, // 151 constFactorKsiMpa = const39_KsiToMpa
    4000, // 152 constFactorLbsBlob = const39_BlobInLbs
    4132, // 153 constFactorLbsin3Tmm3 = const39_Lbsin3ToTmm3
    4168, // 154 constFactorLbsin3Kgm3 = const39_Lbsin3ToKgm3
    4204, // 155 constFactorKgm3Blobin3 = const39_Kgm3ToBlobin3
    4496, // 156 constFactorKgm3Tmm3 = const_1e_12
    4240, // 157 constFactorLbsftKgm = const39_LbsftToKgm
    4276, // 158 constFactorIn3Mm3 = const_In3ToMm3
    4292, // 159 constFactorIn2Mm2 = const_In2ToMm2
    4308, // 160 constFactorIn4Mm4 = const_In4ToMm4
    4328, // 161 constFactorIn6Mm6 = const_In6ToMm6
    436, // 162 constFactorKgmNpm = const_gEarth
    3984, // 163 constFactorInchM = const_InchToM
    2748, // 164 constFactorLbfKgf = const_LbToKg
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

    if (invert) rDiv(consts.c4856(), &re_x, &re_x);
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
    rMul(consts.c5828(), consts.c7532(), &factor);
    rDiv(&factor, consts.c2628(), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnL100Tomgus(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(consts.c7532(), consts.c2628(), &factor);
    rDiv(&factor, consts.c2048(), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnMgeustok100M(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(consts.c5828(), consts.c7532(), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnL100Tomguk(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(consts.c7532(), consts.c2648(), &factor);
    rDiv(&factor, consts.c2048(), &factor);
    unitConversion(&factor, multiply, inverting);
}

pub export fn fnMgeuktok100M(multiply_divide: u16) callconv(.c) void {
    _ = multiply_divide;
    var factor: real_t = undefined;
    rMul(consts.c5828(), consts.c7532(), &factor);
    rMul(&factor, consts.c2648(), &factor);
    rDiv(&factor, consts.c2628(), &factor);
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

// ─── M10.3 port: configurable-conversion pair subsystem (conversionUnits.c) ───
// NEW upstream feature (master fd83b4a4). Additive/unreached by the pinned
// testSuite (no items.c dispatch wiring yet). convPair table + pure-logic
// helpers; the softmenu/HPCONV name helpers are a later slice.
const ITM_NULL: i16 = 0;
const fInMim_t = extern struct { itemNr: u16 };
extern fn runFunction(func: i16) void;
extern fn fnMultiplySI(param: u16) void;

const NUM_CONVERT_PAIRS = 314;

const unitType_t = u8;
const UT_NOT_CONFIGURABLE: unitType_t = 0;
const UT_DISTANCE: unitType_t = 1;
const UT_AREA: unitType_t = 2;
const UT_VOLUME: unitType_t = 3;
const UT_MASS: unitType_t = 4;
const UT_TIME: unitType_t = 5;
const UT_TEMPERATURE: unitType_t = 6;
const UT_PRESSURE: unitType_t = 7;
const UT_ENERGY: unitType_t = 8;
const UT_POWER: unitType_t = 9;
const UT_FORCE: unitType_t = 10;
const UT_TORQUE: unitType_t = 11;
const UT_SPEED: unitType_t = 12;
const UT_ANGLE: unitType_t = 13;
const UT_ANGULAR_SPEED: unitType_t = 14;
const UT_FUELECON: unitType_t = 15;
const UT_EVECON: unitType_t = 16;
const UT_ACCELERATION: unitType_t = 17;
const UT_DENSITY: unitType_t = 18;
const UT_LINEAR_FORCE_DENSITY: unitType_t = 19;

const convPair_t = extern struct {
    item: i16,
    partner: i16,
    unity: i16,
    exponent: i8,
    type: u8,
};

const convertPairs = [NUM_CONVERT_PAIRS]convPair_t{
    .{ .item = 220, .partner = 221, .unity = 2673, .exponent = 0, .type = 6 },
    .{ .item = 221, .partner = 220, .unity = 2665, .exponent = 0, .type = 6 },
    .{ .item = 222, .partner = 228, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 223, .partner = 224, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 224, .partner = 223, .unity = 226, .exponent = 0, .type = 2 },
    .{ .item = 225, .partner = 231, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 226, .partner = 227, .unity = 0, .exponent = 0, .type = 2 },
    .{ .item = 227, .partner = 226, .unity = 226, .exponent = 0, .type = 2 },
    .{ .item = 228, .partner = 222, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 229, .partner = 230, .unity = 0, .exponent = 6, .type = 2 },
    .{ .item = 230, .partner = 229, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 231, .partner = 225, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 232, .partner = 233, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 233, .partner = 232, .unity = 274, .exponent = 0, .type = 3 },
    .{ .item = 234, .partner = 236, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 235, .partner = 237, .unity = 237, .exponent = -3, .type = 3 },
    .{ .item = 236, .partner = 234, .unity = 234, .exponent = 4, .type = 2 },
    .{ .item = 237, .partner = 235, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 238, .partner = 240, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 239, .partner = 241, .unity = 274, .exponent = 0, .type = 3 },
    .{ .item = 240, .partner = 238, .unity = 238, .exponent = 4, .type = 2 },
    .{ .item = 241, .partner = 239, .unity = 255, .exponent = 0, .type = 3 },
    .{ .item = 242, .partner = 243, .unity = 243, .exponent = 0, .type = 7 },
    .{ .item = 243, .partner = 242, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 244, .partner = 245, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 245, .partner = 244, .unity = 244, .exponent = 0, .type = 1 },
    .{ .item = 246, .partner = 247, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 247, .partner = 246, .unity = 246, .exponent = 0, .type = 7 },
    .{ .item = 248, .partner = 249, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 249, .partner = 248, .unity = 248, .exponent = 0, .type = 8 },
    .{ .item = 250, .partner = 251, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 251, .partner = 250, .unity = 250, .exponent = 0, .type = 8 },
    .{ .item = 252, .partner = 254, .unity = 0, .exponent = 0, .type = 11 },
    .{ .item = 253, .partner = 255, .unity = 255, .exponent = 0, .type = 3 },
    .{ .item = 254, .partner = 252, .unity = 252, .exponent = 0, .type = 11 },
    .{ .item = 255, .partner = 253, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 256, .partner = 257, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 257, .partner = 256, .unity = 256, .exponent = 0, .type = 4 },
    .{ .item = 258, .partner = 259, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 259, .partner = 258, .unity = 258, .exponent = 0, .type = 1 },
    .{ .item = 260, .partner = 263, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 261, .partner = 262, .unity = 262, .exponent = 0, .type = 3 },
    .{ .item = 262, .partner = 261, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 263, .partner = 260, .unity = 260, .exponent = 0, .type = 1 },
    .{ .item = 264, .partner = 265, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 265, .partner = 264, .unity = 237, .exponent = -3, .type = 3 },
    .{ .item = 266, .partner = 268, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 267, .partner = 269, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 268, .partner = 266, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 269, .partner = 267, .unity = 237, .exponent = -3, .type = 3 },
    .{ .item = 270, .partner = 272, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 271, .partner = 273, .unity = 276, .exponent = 0, .type = 3 },
    .{ .item = 272, .partner = 270, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 273, .partner = 271, .unity = 255, .exponent = 0, .type = 3 },
    .{ .item = 274, .partner = 275, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 275, .partner = 274, .unity = 274, .exponent = 0, .type = 3 },
    .{ .item = 276, .partner = 277, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 277, .partner = 276, .unity = 276, .exponent = 0, .type = 3 },
    .{ .item = 278, .partner = 279, .unity = 0, .exponent = 0, .type = 9 },
    .{ .item = 279, .partner = 278, .unity = 278, .exponent = 0, .type = 9 },
    .{ .item = 280, .partner = 281, .unity = 0, .exponent = 0, .type = 9 },
    .{ .item = 281, .partner = 280, .unity = 280, .exponent = 0, .type = 9 },
    .{ .item = 282, .partner = 283, .unity = 0, .exponent = 0, .type = 9 },
    .{ .item = 283, .partner = 282, .unity = 282, .exponent = 0, .type = 9 },
    .{ .item = 284, .partner = 286, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 285, .partner = 306, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 286, .partner = 284, .unity = 284, .exponent = 0, .type = 7 },
    .{ .item = 287, .partner = 312, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 288, .partner = 289, .unity = 0, .exponent = -3, .type = 1 },
    .{ .item = 289, .partner = 288, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 290, .partner = 291, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 291, .partner = 290, .unity = 290, .exponent = 0, .type = 8 },
    .{ .item = 292, .partner = 293, .unity = 293, .exponent = 0, .type = 4 },
    .{ .item = 293, .partner = 292, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 294, .partner = 295, .unity = 295, .exponent = -3, .type = 4 },
    .{ .item = 295, .partner = 294, .unity = 0, .exponent = -3, .type = 4 },
    .{ .item = 296, .partner = 298, .unity = 298, .exponent = 0, .type = 4 },
    .{ .item = 297, .partner = 301, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 298, .partner = 296, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 299, .partner = 315, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 300, .partner = 302, .unity = 302, .exponent = 0, .type = 4 },
    .{ .item = 301, .partner = 297, .unity = 299, .exponent = -3, .type = 3 },
    .{ .item = 302, .partner = 300, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 303, .partner = 383, .unity = 385, .exponent = -3, .type = 3 },
    .{ .item = 304, .partner = 307, .unity = 307, .exponent = 0, .type = 4 },
    .{ .item = 305, .partner = 394, .unity = 395, .exponent = -3, .type = 3 },
    .{ .item = 306, .partner = 285, .unity = 287, .exponent = -3, .type = 3 },
    .{ .item = 307, .partner = 304, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 308, .partner = 365, .unity = 369, .exponent = -3, .type = 3 },
    .{ .item = 309, .partner = 392, .unity = 393, .exponent = -3, .type = 3 },
    .{ .item = 310, .partner = 313, .unity = 313, .exponent = 0, .type = 4 },
    .{ .item = 311, .partner = 314, .unity = 314, .exponent = 0, .type = 4 },
    .{ .item = 312, .partner = 287, .unity = 287, .exponent = -3, .type = 3 },
    .{ .item = 313, .partner = 310, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 314, .partner = 311, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 315, .partner = 299, .unity = 299, .exponent = -3, .type = 3 },
    .{ .item = 316, .partner = 318, .unity = 318, .exponent = -3, .type = 4 },
    .{ .item = 317, .partner = 351, .unity = 351, .exponent = -3, .type = 3 },
    .{ .item = 318, .partner = 316, .unity = 0, .exponent = -3, .type = 4 },
    .{ .item = 319, .partner = 354, .unity = 354, .exponent = -3, .type = 3 },
    .{ .item = 320, .partner = 321, .unity = 0, .exponent = 0, .type = 10 },
    .{ .item = 321, .partner = 320, .unity = 320, .exponent = 0, .type = 10 },
    .{ .item = 322, .partner = 323, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 323, .partner = 322, .unity = 322, .exponent = 0, .type = 1 },
    .{ .item = 324, .partner = 326, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 325, .partner = 359, .unity = 356, .exponent = 0, .type = 3 },
    .{ .item = 326, .partner = 324, .unity = 324, .exponent = 0, .type = 7 },
    .{ .item = 327, .partner = 362, .unity = 262, .exponent = 0, .type = 3 },
    .{ .item = 328, .partner = 329, .unity = 0, .exponent = 3, .type = 1 },
    .{ .item = 329, .partner = 328, .unity = 336, .exponent = 0, .type = 1 },
    .{ .item = 330, .partner = 331, .unity = 360, .exponent = 0, .type = 1 },
    .{ .item = 331, .partner = 330, .unity = 0, .exponent = 3, .type = 1 },
    .{ .item = 332, .partner = 333, .unity = 333, .exponent = 0, .type = 1 },
    .{ .item = 333, .partner = 332, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 334, .partner = 337, .unity = 337, .exponent = -3, .type = 1 },
    .{ .item = 335, .partner = 369, .unity = 369, .exponent = -3, .type = 3 },
    .{ .item = 336, .partner = 339, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 337, .partner = 334, .unity = 0, .exponent = -3, .type = 1 },
    .{ .item = 338, .partner = 385, .unity = 385, .exponent = -3, .type = 3 },
    .{ .item = 339, .partner = 336, .unity = 336, .exponent = 0, .type = 1 },
    .{ .item = 340, .partner = 341, .unity = 341, .exponent = 0, .type = 1 },
    .{ .item = 341, .partner = 340, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 342, .partner = 343, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 343, .partner = 342, .unity = 342, .exponent = 0, .type = 7 },
    .{ .item = 344, .partner = 346, .unity = 346, .exponent = 0, .type = 7 },
    .{ .item = 345, .partner = 393, .unity = 393, .exponent = -3, .type = 3 },
    .{ .item = 346, .partner = 344, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 347, .partner = 395, .unity = 395, .exponent = -3, .type = 3 },
    .{ .item = 348, .partner = 349, .unity = 349, .exponent = 0, .type = 5 },
    .{ .item = 349, .partner = 348, .unity = 0, .exponent = 0, .type = 5 },
    .{ .item = 350, .partner = 353, .unity = 0, .exponent = -3, .type = 4 },
    .{ .item = 351, .partner = 317, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 352, .partner = 355, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 353, .partner = 350, .unity = 350, .exponent = -3, .type = 4 },
    .{ .item = 354, .partner = 319, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 355, .partner = 352, .unity = 352, .exponent = 0, .type = 4 },
    .{ .item = 356, .partner = 357, .unity = 0, .exponent = 0, .type = 3 },
    .{ .item = 357, .partner = 356, .unity = 356, .exponent = 0, .type = 3 },
    .{ .item = 358, .partner = 361, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 359, .partner = 325, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 360, .partner = 363, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 361, .partner = 358, .unity = 358, .exponent = 0, .type = 1 },
    .{ .item = 362, .partner = 327, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 363, .partner = 360, .unity = 360, .exponent = 0, .type = 1 },
    .{ .item = 364, .partner = 366, .unity = 0, .exponent = 3, .type = 3 },
    .{ .item = 365, .partner = 308, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 366, .partner = 364, .unity = 364, .exponent = 3, .type = 3 },
    .{ .item = 367, .partner = 368, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 368, .partner = 367, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 369, .partner = 335, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 370, .partner = 371, .unity = 0, .exponent = 0, .type = 2 },
    .{ .item = 371, .partner = 370, .unity = 0, .exponent = 4, .type = 2 },
    .{ .item = 372, .partner = 373, .unity = 0, .exponent = 0, .type = 2 },
    .{ .item = 373, .partner = 372, .unity = 372, .exponent = 0, .type = 2 },
    .{ .item = 374, .partner = 375, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 375, .partner = 374, .unity = 374, .exponent = 0, .type = 1 },
    .{ .item = 376, .partner = 377, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 377, .partner = 376, .unity = 376, .exponent = 0, .type = 1 },
    .{ .item = 378, .partner = 379, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 379, .partner = 378, .unity = 378, .exponent = 0, .type = 1 },
    .{ .item = 380, .partner = 381, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 381, .partner = 380, .unity = 380, .exponent = 0, .type = 1 },
    .{ .item = 382, .partner = 384, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 383, .partner = 303, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 384, .partner = 382, .unity = 382, .exponent = 0, .type = 1 },
    .{ .item = 385, .partner = 338, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 386, .partner = 387, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 387, .partner = 386, .unity = 386, .exponent = 0, .type = 1 },
    .{ .item = 388, .partner = 389, .unity = 0, .exponent = 6, .type = 2 },
    .{ .item = 389, .partner = 388, .unity = 388, .exponent = 6, .type = 2 },
    .{ .item = 390, .partner = 391, .unity = 0, .exponent = 6, .type = 2 },
    .{ .item = 391, .partner = 390, .unity = 390, .exponent = 6, .type = 2 },
    .{ .item = 392, .partner = 309, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 393, .partner = 345, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 394, .partner = 305, .unity = 266, .exponent = -3, .type = 3 },
    .{ .item = 395, .partner = 347, .unity = 0, .exponent = -3, .type = 3 },
    .{ .item = 1902, .partner = 1903, .unity = 270, .exponent = -3, .type = 3 },
    .{ .item = 1903, .partner = 1902, .unity = 276, .exponent = 0, .type = 3 },
    .{ .item = 2084, .partner = 2085, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2085, .partner = 2084, .unity = 2743, .exponent = 0, .type = 12 },
    .{ .item = 2086, .partner = 2087, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2087, .partner = 2086, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2088, .partner = 2089, .unity = 2745, .exponent = 0, .type = 14 },
    .{ .item = 2089, .partner = 2088, .unity = 2094, .exponent = 0, .type = 14 },
    .{ .item = 2090, .partner = 2091, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2091, .partner = 2090, .unity = 2092, .exponent = 0, .type = 12 },
    .{ .item = 2092, .partner = 2093, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2093, .partner = 2092, .unity = 2092, .exponent = 0, .type = 12 },
    .{ .item = 2094, .partner = 2095, .unity = 0, .exponent = 0, .type = 14 },
    .{ .item = 2095, .partner = 2094, .unity = 2094, .exponent = 0, .type = 14 },
    .{ .item = 2096, .partner = 2097, .unity = 0, .exponent = 0, .type = 13 },
    .{ .item = 2097, .partner = 2096, .unity = 2096, .exponent = 0, .type = 13 },
    .{ .item = 2098, .partner = 2099, .unity = 2100, .exponent = 0, .type = 13 },
    .{ .item = 2099, .partner = 2098, .unity = 2096, .exponent = 0, .type = 13 },
    .{ .item = 2100, .partner = 2101, .unity = 0, .exponent = 0, .type = 13 },
    .{ .item = 2101, .partner = 2100, .unity = 2100, .exponent = 0, .type = 13 },
    .{ .item = 2163, .partner = 2164, .unity = 0, .exponent = -2, .type = 1 },
    .{ .item = 2164, .partner = 2163, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 2167, .partner = 2168, .unity = 336, .exponent = 0, .type = 1 },
    .{ .item = 2168, .partner = 2167, .unity = 360, .exponent = 0, .type = 1 },
    .{ .item = 2169, .partner = 2170, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 2170, .partner = 2169, .unity = 2169, .exponent = 0, .type = 1 },
    .{ .item = 2171, .partner = 2172, .unity = 0, .exponent = 0, .type = 5 },
    .{ .item = 2172, .partner = 2171, .unity = 2171, .exponent = 0, .type = 5 },
    .{ .item = 2173, .partner = 2174, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2174, .partner = 2173, .unity = 2173, .exponent = 0, .type = 12 },
    .{ .item = 2175, .partner = 2176, .unity = 0, .exponent = 0, .type = 1 },
    .{ .item = 2176, .partner = 2175, .unity = 2175, .exponent = 0, .type = 1 },
    .{ .item = 2177, .partner = 2178, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2178, .partner = 2177, .unity = 2177, .exponent = 0, .type = 4 },
    .{ .item = 2179, .partner = 2180, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2180, .partner = 2179, .unity = 2173, .exponent = 0, .type = 12 },
    .{ .item = 2181, .partner = 2182, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 2182, .partner = 2181, .unity = 2175, .exponent = 0, .type = 1 },
    .{ .item = 2183, .partner = 2184, .unity = 293, .exponent = 0, .type = 4 },
    .{ .item = 2184, .partner = 2183, .unity = 2177, .exponent = 0, .type = 4 },
    .{ .item = 2185, .partner = 2186, .unity = 2092, .exponent = 0, .type = 12 },
    .{ .item = 2186, .partner = 2185, .unity = 2173, .exponent = 0, .type = 12 },
    .{ .item = 2187, .partner = 2188, .unity = 2086, .exponent = 0, .type = 12 },
    .{ .item = 2188, .partner = 2187, .unity = 2189, .exponent = 0, .type = 12 },
    .{ .item = 2189, .partner = 2190, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2190, .partner = 2189, .unity = 2189, .exponent = 0, .type = 12 },
    .{ .item = 2204, .partner = 2205, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2205, .partner = 2204, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2206, .partner = 2207, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2207, .partner = 2206, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2208, .partner = 2209, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2209, .partner = 2208, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2210, .partner = 2211, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2211, .partner = 2210, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2212, .partner = 2213, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2213, .partner = 2212, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2214, .partner = 2215, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2215, .partner = 2214, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2216, .partner = 2217, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2217, .partner = 2216, .unity = 0, .exponent = 0, .type = 15 },
    .{ .item = 2218, .partner = 2219, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2219, .partner = 2218, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2220, .partner = 2221, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2221, .partner = 2220, .unity = 0, .exponent = 0, .type = 16 },
    .{ .item = 2464, .partner = 2465, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 2465, .partner = 2464, .unity = 2464, .exponent = 0, .type = 8 },
    .{ .item = 2466, .partner = 2467, .unity = 2163, .exponent = -2, .type = 1 },
    .{ .item = 2467, .partner = 2466, .unity = 2468, .exponent = -3, .type = 1 },
    .{ .item = 2468, .partner = 2469, .unity = 0, .exponent = -3, .type = 1 },
    .{ .item = 2469, .partner = 2468, .unity = 2468, .exponent = -3, .type = 1 },
    .{ .item = 2658, .partner = 2659, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 2659, .partner = 2658, .unity = 2658, .exponent = 0, .type = 8 },
    .{ .item = 2660, .partner = 2661, .unity = 0, .exponent = 0, .type = 8 },
    .{ .item = 2661, .partner = 2660, .unity = 2660, .exponent = 0, .type = 8 },
    .{ .item = 2665, .partner = 2666, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2666, .partner = 2665, .unity = 2665, .exponent = 0, .type = 6 },
    .{ .item = 2667, .partner = 2668, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2668, .partner = 2667, .unity = 2667, .exponent = 0, .type = 6 },
    .{ .item = 2669, .partner = 2670, .unity = 2673, .exponent = 0, .type = 6 },
    .{ .item = 2670, .partner = 2669, .unity = 2667, .exponent = 0, .type = 6 },
    .{ .item = 2671, .partner = 2672, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2672, .partner = 2671, .unity = 2671, .exponent = 0, .type = 6 },
    .{ .item = 2673, .partner = 2674, .unity = 0, .exponent = 0, .type = 6 },
    .{ .item = 2674, .partner = 2673, .unity = 2673, .exponent = 0, .type = 6 },
    .{ .item = 2743, .partner = 2744, .unity = 0, .exponent = 0, .type = 12 },
    .{ .item = 2744, .partner = 2743, .unity = 2743, .exponent = 0, .type = 12 },
    .{ .item = 2745, .partner = 2746, .unity = 0, .exponent = 0, .type = 14 },
    .{ .item = 2746, .partner = 2745, .unity = 2745, .exponent = 0, .type = 14 },
    .{ .item = 2747, .partner = 2748, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2748, .partner = 2747, .unity = 2747, .exponent = 0, .type = 4 },
    .{ .item = 2749, .partner = 2750, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2750, .partner = 2749, .unity = 2749, .exponent = 0, .type = 4 },
    .{ .item = 2751, .partner = 2752, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2752, .partner = 2751, .unity = 2751, .exponent = 0, .type = 4 },
    .{ .item = 2753, .partner = 2754, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2754, .partner = 2753, .unity = 2753, .exponent = 0, .type = 4 },
    .{ .item = 2800, .partner = 2801, .unity = 0, .exponent = 0, .type = 7 },
    .{ .item = 2801, .partner = 2800, .unity = 2800, .exponent = 0, .type = 7 },
    .{ .item = 2802, .partner = 2803, .unity = 0, .exponent = 0, .type = 11 },
    .{ .item = 2803, .partner = 2802, .unity = 2802, .exponent = 0, .type = 11 },
    .{ .item = 2804, .partner = 2805, .unity = 0, .exponent = 0, .type = 19 },
    .{ .item = 2805, .partner = 2804, .unity = 2804, .exponent = 0, .type = 19 },
    .{ .item = 2806, .partner = 2807, .unity = 0, .exponent = 0, .type = 10 },
    .{ .item = 2807, .partner = 2806, .unity = 2806, .exponent = 0, .type = 10 },
    .{ .item = 2808, .partner = 2809, .unity = 2809, .exponent = 0, .type = 17 },
    .{ .item = 2809, .partner = 2808, .unity = 0, .exponent = 0, .type = 17 },
    .{ .item = 2810, .partner = 2811, .unity = 2811, .exponent = 0, .type = 17 },
    .{ .item = 2811, .partner = 2810, .unity = 0, .exponent = 0, .type = 17 },
    .{ .item = 2812, .partner = 2813, .unity = 0, .exponent = 6, .type = 7 },
    .{ .item = 2813, .partner = 2812, .unity = 2812, .exponent = 6, .type = 7 },
    .{ .item = 2814, .partner = 2815, .unity = 2821, .exponent = 0, .type = 18 },
    .{ .item = 2815, .partner = 2814, .unity = 2818, .exponent = 0, .type = 18 },
    .{ .item = 2816, .partner = 2817, .unity = 2823, .exponent = 0, .type = 18 },
    .{ .item = 2817, .partner = 2816, .unity = 2818, .exponent = 0, .type = 18 },
    .{ .item = 2818, .partner = 2819, .unity = 0, .exponent = 0, .type = 18 },
    .{ .item = 2819, .partner = 2818, .unity = 2818, .exponent = 0, .type = 18 },
    .{ .item = 2820, .partner = 2821, .unity = 2821, .exponent = 0, .type = 18 },
    .{ .item = 2821, .partner = 2820, .unity = 0, .exponent = 0, .type = 18 },
    .{ .item = 2822, .partner = 2823, .unity = 2823, .exponent = 0, .type = 18 },
    .{ .item = 2823, .partner = 2822, .unity = 0, .exponent = 0, .type = 18 },
    .{ .item = 2824, .partner = 2825, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2825, .partner = 2824, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2826, .partner = 2827, .unity = 0, .exponent = -6, .type = 3 },
    .{ .item = 2827, .partner = 2826, .unity = 2826, .exponent = -6, .type = 3 },
    .{ .item = 2828, .partner = 2829, .unity = 0, .exponent = -6, .type = 2 },
    .{ .item = 2829, .partner = 2828, .unity = 2828, .exponent = -6, .type = 2 },
    .{ .item = 2830, .partner = 2831, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2831, .partner = 2830, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2832, .partner = 2833, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2833, .partner = 2832, .unity = 0, .exponent = 0, .type = 0 },
    .{ .item = 2834, .partner = 2835, .unity = 0, .exponent = 0, .type = 19 },
    .{ .item = 2835, .partner = 2834, .unity = 2834, .exponent = 0, .type = 19 },
    .{ .item = 2836, .partner = 2837, .unity = 320, .exponent = 0, .type = 10 },
    .{ .item = 2837, .partner = 2836, .unity = 2806, .exponent = 0, .type = 10 },
    .{ .item = 2838, .partner = 2839, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2839, .partner = 2838, .unity = 2838, .exponent = 0, .type = 4 },
    .{ .item = 2840, .partner = 2841, .unity = 0, .exponent = 0, .type = 4 },
    .{ .item = 2841, .partner = 2840, .unity = 2840, .exponent = 0, .type = 4 },
};

const MimFunctionsType3Conv = [NUM_CONVERT_PAIRS]fInMim_t{
    .{ .itemNr = 220 },
    .{ .itemNr = 221 },
    .{ .itemNr = 222 },
    .{ .itemNr = 223 },
    .{ .itemNr = 224 },
    .{ .itemNr = 225 },
    .{ .itemNr = 226 },
    .{ .itemNr = 227 },
    .{ .itemNr = 228 },
    .{ .itemNr = 229 },
    .{ .itemNr = 230 },
    .{ .itemNr = 231 },
    .{ .itemNr = 232 },
    .{ .itemNr = 233 },
    .{ .itemNr = 234 },
    .{ .itemNr = 235 },
    .{ .itemNr = 236 },
    .{ .itemNr = 237 },
    .{ .itemNr = 238 },
    .{ .itemNr = 239 },
    .{ .itemNr = 240 },
    .{ .itemNr = 241 },
    .{ .itemNr = 242 },
    .{ .itemNr = 243 },
    .{ .itemNr = 244 },
    .{ .itemNr = 245 },
    .{ .itemNr = 246 },
    .{ .itemNr = 247 },
    .{ .itemNr = 248 },
    .{ .itemNr = 249 },
    .{ .itemNr = 250 },
    .{ .itemNr = 251 },
    .{ .itemNr = 252 },
    .{ .itemNr = 253 },
    .{ .itemNr = 254 },
    .{ .itemNr = 255 },
    .{ .itemNr = 256 },
    .{ .itemNr = 257 },
    .{ .itemNr = 258 },
    .{ .itemNr = 259 },
    .{ .itemNr = 260 },
    .{ .itemNr = 261 },
    .{ .itemNr = 262 },
    .{ .itemNr = 263 },
    .{ .itemNr = 264 },
    .{ .itemNr = 265 },
    .{ .itemNr = 266 },
    .{ .itemNr = 267 },
    .{ .itemNr = 268 },
    .{ .itemNr = 269 },
    .{ .itemNr = 270 },
    .{ .itemNr = 271 },
    .{ .itemNr = 272 },
    .{ .itemNr = 273 },
    .{ .itemNr = 274 },
    .{ .itemNr = 275 },
    .{ .itemNr = 276 },
    .{ .itemNr = 277 },
    .{ .itemNr = 278 },
    .{ .itemNr = 279 },
    .{ .itemNr = 280 },
    .{ .itemNr = 281 },
    .{ .itemNr = 282 },
    .{ .itemNr = 283 },
    .{ .itemNr = 284 },
    .{ .itemNr = 285 },
    .{ .itemNr = 286 },
    .{ .itemNr = 287 },
    .{ .itemNr = 288 },
    .{ .itemNr = 289 },
    .{ .itemNr = 290 },
    .{ .itemNr = 291 },
    .{ .itemNr = 292 },
    .{ .itemNr = 293 },
    .{ .itemNr = 294 },
    .{ .itemNr = 295 },
    .{ .itemNr = 296 },
    .{ .itemNr = 297 },
    .{ .itemNr = 298 },
    .{ .itemNr = 299 },
    .{ .itemNr = 300 },
    .{ .itemNr = 301 },
    .{ .itemNr = 302 },
    .{ .itemNr = 303 },
    .{ .itemNr = 304 },
    .{ .itemNr = 305 },
    .{ .itemNr = 306 },
    .{ .itemNr = 307 },
    .{ .itemNr = 308 },
    .{ .itemNr = 309 },
    .{ .itemNr = 310 },
    .{ .itemNr = 311 },
    .{ .itemNr = 312 },
    .{ .itemNr = 313 },
    .{ .itemNr = 314 },
    .{ .itemNr = 315 },
    .{ .itemNr = 316 },
    .{ .itemNr = 317 },
    .{ .itemNr = 318 },
    .{ .itemNr = 319 },
    .{ .itemNr = 320 },
    .{ .itemNr = 321 },
    .{ .itemNr = 322 },
    .{ .itemNr = 323 },
    .{ .itemNr = 324 },
    .{ .itemNr = 325 },
    .{ .itemNr = 326 },
    .{ .itemNr = 327 },
    .{ .itemNr = 328 },
    .{ .itemNr = 329 },
    .{ .itemNr = 330 },
    .{ .itemNr = 331 },
    .{ .itemNr = 332 },
    .{ .itemNr = 333 },
    .{ .itemNr = 334 },
    .{ .itemNr = 335 },
    .{ .itemNr = 336 },
    .{ .itemNr = 337 },
    .{ .itemNr = 338 },
    .{ .itemNr = 339 },
    .{ .itemNr = 340 },
    .{ .itemNr = 341 },
    .{ .itemNr = 342 },
    .{ .itemNr = 343 },
    .{ .itemNr = 344 },
    .{ .itemNr = 345 },
    .{ .itemNr = 346 },
    .{ .itemNr = 347 },
    .{ .itemNr = 348 },
    .{ .itemNr = 349 },
    .{ .itemNr = 350 },
    .{ .itemNr = 351 },
    .{ .itemNr = 352 },
    .{ .itemNr = 353 },
    .{ .itemNr = 354 },
    .{ .itemNr = 355 },
    .{ .itemNr = 356 },
    .{ .itemNr = 357 },
    .{ .itemNr = 358 },
    .{ .itemNr = 359 },
    .{ .itemNr = 360 },
    .{ .itemNr = 361 },
    .{ .itemNr = 362 },
    .{ .itemNr = 363 },
    .{ .itemNr = 364 },
    .{ .itemNr = 365 },
    .{ .itemNr = 366 },
    .{ .itemNr = 367 },
    .{ .itemNr = 368 },
    .{ .itemNr = 369 },
    .{ .itemNr = 370 },
    .{ .itemNr = 371 },
    .{ .itemNr = 372 },
    .{ .itemNr = 373 },
    .{ .itemNr = 374 },
    .{ .itemNr = 375 },
    .{ .itemNr = 376 },
    .{ .itemNr = 377 },
    .{ .itemNr = 378 },
    .{ .itemNr = 379 },
    .{ .itemNr = 380 },
    .{ .itemNr = 381 },
    .{ .itemNr = 382 },
    .{ .itemNr = 383 },
    .{ .itemNr = 384 },
    .{ .itemNr = 385 },
    .{ .itemNr = 386 },
    .{ .itemNr = 387 },
    .{ .itemNr = 388 },
    .{ .itemNr = 389 },
    .{ .itemNr = 390 },
    .{ .itemNr = 391 },
    .{ .itemNr = 392 },
    .{ .itemNr = 393 },
    .{ .itemNr = 394 },
    .{ .itemNr = 395 },
    .{ .itemNr = 1902 },
    .{ .itemNr = 1903 },
    .{ .itemNr = 2084 },
    .{ .itemNr = 2085 },
    .{ .itemNr = 2086 },
    .{ .itemNr = 2087 },
    .{ .itemNr = 2088 },
    .{ .itemNr = 2089 },
    .{ .itemNr = 2090 },
    .{ .itemNr = 2091 },
    .{ .itemNr = 2092 },
    .{ .itemNr = 2093 },
    .{ .itemNr = 2094 },
    .{ .itemNr = 2095 },
    .{ .itemNr = 2096 },
    .{ .itemNr = 2097 },
    .{ .itemNr = 2098 },
    .{ .itemNr = 2099 },
    .{ .itemNr = 2100 },
    .{ .itemNr = 2101 },
    .{ .itemNr = 2163 },
    .{ .itemNr = 2164 },
    .{ .itemNr = 2167 },
    .{ .itemNr = 2168 },
    .{ .itemNr = 2169 },
    .{ .itemNr = 2170 },
    .{ .itemNr = 2171 },
    .{ .itemNr = 2172 },
    .{ .itemNr = 2173 },
    .{ .itemNr = 2174 },
    .{ .itemNr = 2175 },
    .{ .itemNr = 2176 },
    .{ .itemNr = 2177 },
    .{ .itemNr = 2178 },
    .{ .itemNr = 2179 },
    .{ .itemNr = 2180 },
    .{ .itemNr = 2181 },
    .{ .itemNr = 2182 },
    .{ .itemNr = 2183 },
    .{ .itemNr = 2184 },
    .{ .itemNr = 2185 },
    .{ .itemNr = 2186 },
    .{ .itemNr = 2187 },
    .{ .itemNr = 2188 },
    .{ .itemNr = 2189 },
    .{ .itemNr = 2190 },
    .{ .itemNr = 2204 },
    .{ .itemNr = 2205 },
    .{ .itemNr = 2206 },
    .{ .itemNr = 2207 },
    .{ .itemNr = 2208 },
    .{ .itemNr = 2209 },
    .{ .itemNr = 2210 },
    .{ .itemNr = 2211 },
    .{ .itemNr = 2212 },
    .{ .itemNr = 2213 },
    .{ .itemNr = 2214 },
    .{ .itemNr = 2215 },
    .{ .itemNr = 2216 },
    .{ .itemNr = 2217 },
    .{ .itemNr = 2218 },
    .{ .itemNr = 2219 },
    .{ .itemNr = 2220 },
    .{ .itemNr = 2221 },
    .{ .itemNr = 2464 },
    .{ .itemNr = 2465 },
    .{ .itemNr = 2466 },
    .{ .itemNr = 2467 },
    .{ .itemNr = 2468 },
    .{ .itemNr = 2469 },
    .{ .itemNr = 2658 },
    .{ .itemNr = 2659 },
    .{ .itemNr = 2660 },
    .{ .itemNr = 2661 },
    .{ .itemNr = 2665 },
    .{ .itemNr = 2666 },
    .{ .itemNr = 2667 },
    .{ .itemNr = 2668 },
    .{ .itemNr = 2669 },
    .{ .itemNr = 2670 },
    .{ .itemNr = 2671 },
    .{ .itemNr = 2672 },
    .{ .itemNr = 2673 },
    .{ .itemNr = 2674 },
    .{ .itemNr = 2743 },
    .{ .itemNr = 2744 },
    .{ .itemNr = 2745 },
    .{ .itemNr = 2746 },
    .{ .itemNr = 2747 },
    .{ .itemNr = 2748 },
    .{ .itemNr = 2749 },
    .{ .itemNr = 2750 },
    .{ .itemNr = 2751 },
    .{ .itemNr = 2752 },
    .{ .itemNr = 2753 },
    .{ .itemNr = 2754 },
    .{ .itemNr = 2800 },
    .{ .itemNr = 2801 },
    .{ .itemNr = 2802 },
    .{ .itemNr = 2803 },
    .{ .itemNr = 2804 },
    .{ .itemNr = 2805 },
    .{ .itemNr = 2806 },
    .{ .itemNr = 2807 },
    .{ .itemNr = 2808 },
    .{ .itemNr = 2809 },
    .{ .itemNr = 2810 },
    .{ .itemNr = 2811 },
    .{ .itemNr = 2812 },
    .{ .itemNr = 2813 },
    .{ .itemNr = 2814 },
    .{ .itemNr = 2815 },
    .{ .itemNr = 2816 },
    .{ .itemNr = 2817 },
    .{ .itemNr = 2818 },
    .{ .itemNr = 2819 },
    .{ .itemNr = 2820 },
    .{ .itemNr = 2821 },
    .{ .itemNr = 2822 },
    .{ .itemNr = 2823 },
    .{ .itemNr = 2824 },
    .{ .itemNr = 2825 },
    .{ .itemNr = 2826 },
    .{ .itemNr = 2827 },
    .{ .itemNr = 2828 },
    .{ .itemNr = 2829 },
    .{ .itemNr = 2830 },
    .{ .itemNr = 2831 },
    .{ .itemNr = 2832 },
    .{ .itemNr = 2833 },
    .{ .itemNr = 2834 },
    .{ .itemNr = 2835 },
    .{ .itemNr = 2836 },
    .{ .itemNr = 2837 },
    .{ .itemNr = 2838 },
    .{ .itemNr = 2839 },
    .{ .itemNr = 2841 },
    .{ .itemNr = 2840 },
};

fn findPair(input: i16) ?*const convPair_t {                                     // binary search; null if not found
    var lo: u16 = 0;
    var hi: u16 = NUM_CONVERT_PAIRS;
    while (lo < hi) {
        const mid: u16 = (lo + hi) >> 1;
        if (convertPairs[mid].item < input) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }
    return if (lo < NUM_CONVERT_PAIRS and convertPairs[lo].item == input) &convertPairs[lo] else null;
}

pub export fn conversionPartner(input: i16, unity: ?*i16, exponent: ?*i8, type_out: ?*u8) callconv(.c) i16 {
    const entry = findPair(input) orelse return 0;                              // not found
    if (unity) |p| p.* = entry.unity;
    if (exponent) |p| p.* = entry.exponent;
    if (type_out) |p| p.* = entry.type;
    return entry.partner;
}

pub export fn isItemConversion(itemNr: i16) callconv(.c) bool {
    return findPair(itemNr) != null;                                            // search itemNr in the table items
}

pub export fn areBothConvertConfigurable(item1Nr: i16, item2Nr: i16) callconv(.c) bool {
    const entry1 = findPair(item1Nr) orelse return false;
    const entry2 = findPair(item2Nr) orelse return false;
    return entry1.type == entry2.type and entry1.type != UT_NOT_CONFIGURABLE;   // same configurable type
}

pub export fn isStandardPair(item1Nr: i16, item2Nr: i16) callconv(.c) bool {     // item2Nr is the standard table partner of item1Nr
    return item2Nr != 0 and conversionPartner(item1Nr, null, null, null) == item2Nr;
}

pub export fn isOneOfAConvertPair(x: u16, itemNr: i16, oddNrPartner: *i16) callconv(.c) bool {
    const entry = findPair(itemNr) orelse return false;                         // not a conversion-pair member
    if ((x & 1) == 0) {
        oddNrPartner.* = entry.partner;                                         // even x = left softkey: report partner
    }
    return true;
}

pub export fn runConversionToSI(itemNr: i16) callconv(.c) void {
    const entry = findPair(itemNr) orelse return;                               // not a conversion item; nothing to do
    if (entry.unity != ITM_NULL) {
        runFunction(entry.unity);                                              // execute a conversion
    }
    if (entry.exponent != 0) {
        fnMultiplySI(@intCast(@as(i32, 100) + entry.exponent));                // scale by 10^exponent
    }
}

pub export fn runConversionFromSI(itemNr: i16) callconv(.c) void {
    const entry = findPair(itemNr) orelse return;
    if (entry.exponent != 0) {
        fnMultiplySI(@intCast(@as(i32, 100) - entry.exponent));                // undo the exponent
    }
    if (entry.unity != ITM_NULL) {
        runFunction(findPair(entry.unity).?.partner);                          // inverse of the unity step
    }
    runFunction(entry.partner);                                                 // inverse of the user's choice
}

// ─── conversion-name slice: softmenu-name helpers (conversionUnits.c:778+) ───
// item_t / indexOfItems: exact layout copied from frontier_items_owned.zig /
// frontier_softmenus_owned.zig (must match src/c47 typeDefinitions.h item_t).
const item_t = abi.Item;
const indexOfItems = @extern([*c]const item_t, .{ .name = "indexOfItems" });

// Right/left arrow glyphs (re-declared locally; match the softmenus owner).
const STD_RIGHT_ARROW: [*:0]const u8 = "\xa1\x92";
const STD_LEFT_ARROW: [*:0]const u8 = "\xa1\x90";

extern fn strlen(s: [*c]const u8) usize;
inline fn stringByteLength(str: [*c]const u8) i32 {
    return @intCast(strlen(str));
}
// stringCopy is a macro for stpcpy (returns pointer to dst's terminating NUL).
fn stpcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8 {
    var d = dst;
    var s = src;
    while (s[0] != 0) {
        d[0] = s[0];
        d += 1;
        s += 1;
    }
    d[0] = 0;
    return d;
}
inline fn stringCopy(dst: [*c]u8, src: [*c]const u8) [*c]u8 {
    return stpcpy(dst, src);
}
// truncateAtArrow/truncateAtString: ~8-line pair duplicated locally from
// frontier_softmenus_owned.zig (those copies are private there).
fn truncateAtString(label: [*c]u8, search: [*c]const u8) void {
    var i: usize = 0;
    while (label[i + 1] != 0) {
        if (search[0] == label[i] and search[1] == label[i + 1]) {
            label[i] = 0;
            break;
        }
        i += 1;
    }
}
fn truncateAtArrow(label: [*c]u8) void {
    var sample: [4]u8 = undefined;
    _ = stringCopy(&sample, STD_RIGHT_ARROW);
    truncateAtString(label, &sample);
    _ = stringCopy(&sample, STD_LEFT_ARROW);
    truncateAtString(label, &sample);
}

pub export fn fullConvSoftMenuItemNameInclHPCONV(item: i16, outString: [*c]u8) callconv(.c) void {
    if (!isItemConversion(item)) {                                               // not a conversion: plain softmenu name
        _ = stringCopy(outString, &indexOfItems[@intCast(item)].itemSoftmenuName);
        return;
    }
    const useNameExcludingRightArrowOnLeft: i16 = item;
    const useNameExcludingRightArrowOnRight: i16 = conversionPartner(item, null, null, null);
    var scratch: [64]u8 = undefined;
    _ = stringCopy(&scratch, &indexOfItems[@intCast(useNameExcludingRightArrowOnLeft)].itemSoftmenuName); // left side up to arrow
    truncateAtArrow(&scratch);
    _ = stringCopy(outString, &scratch);
    _ = stringCopy(outString + @as(usize, @intCast(stringByteLength(outString))), STD_RIGHT_ARROW);        // arrow between sides
    _ = stringCopy(&scratch, &indexOfItems[@intCast(useNameExcludingRightArrowOnRight)].itemSoftmenuName); // right side up to arrow
    truncateAtArrow(&scratch);
    _ = stringCopy(outString + @as(usize, @intCast(stringByteLength(outString))), &scratch);
}

// Cross-owner globals for executionConversionPartner — EXACT decls copied from
// frontier_softmenus_owned.zig (struct layouts must match that owner).
const userMenuItem_t = extern struct {
    item: i16,
    unused: i16, // padding (present in the C struct)
    argumentName: [16]u8,
};
const userMenu_t = extern struct {
    menuName: [16]u8,
    menuItem: [18]userMenuItem_t,
};
const softmenu_t = abi.Softmenu;
const softmenuStack_t = extern struct {
    softmenuId: i16,
    firstItem: i16,
    userMenuId: i16,
    calcMode: u8,
};
extern var dynamicMenuItem: i16;
const softmenu = @extern([*c]const softmenu_t, .{ .name = "softmenu" });
const softmenuStack = @extern([*c]softmenuStack_t, .{ .name = "softmenuStack" });
const userMenuItems = @extern([*c]userMenuItem_t, .{ .name = "userMenuItems" });
extern var userMenus: [*c]userMenu_t;
extern var currentUserMenu: u16;
const MNU_MyMenu: i16 = 1349;
const MNU_DYNAMIC: i16 = 1394;
const FLAG_HPCONV: i32 = 0x8042;

pub export fn executionConversionPartner(item: i16, itemNrPair: ?*i16, pairName: [*c]u8) callconv(.c) void {
    if (!isItemConversion(item)) {                                               // not a conversion: plain softmenu name, no partner work
        if (itemNrPair) |p| p.* = 0;
        if (pairName != null) {
            _ = stringCopy(pairName, &indexOfItems[@intCast(item)].itemSoftmenuName);
        }
        return;
    }
    const softKeyIx: i16 = dynamicMenuItem ^ 1;
    const curMenu: i16 = -%softmenu[@intCast(softmenuStack[0].softmenuId)].menuItem;
    // dynamicMenuItem is -1 outside a softmenu selection (e.g. when a running
    // program executes a conversion step), making softKeyIx negative. The C
    // indexes userMenuItems/userMenus with a signed int16_t and reads out of
    // bounds; the garbage never forms a configurable pair, so it falls through
    // to the standard-pair name. Guard the negative index (which @intCast cannot
    // represent) and yield the same "no partner" outcome without the OOB read.
    const softKeyPartner: i16 = if (softKeyIx >= 0 and curMenu == MNU_MyMenu)
        userMenuItems[@intCast(softKeyIx)].item
    else if (softKeyIx >= 0 and curMenu == MNU_DYNAMIC)
        userMenus[@intCast(currentUserMenu)].menuItem[@intCast(softKeyIx)].item
    else
        0;
    if (areBothConvertConfigurable(item, softKeyPartner) and !isStandardPair(item, softKeyPartner)) {  // custom non-standard pair of the SAME configurable UT
        if (itemNrPair) |p| p.* = softKeyPartner;
        if (pairName != null) {
            const leftItem: i16 = if (getSystemFlag(FLAG_HPCONV)) conversionPartner(softKeyPartner, null, null, null) else item;
            const rightItem: i16 = if (getSystemFlag(FLAG_HPCONV)) conversionPartner(item, null, null, null) else softKeyPartner;
            var scratch: [64]u8 = undefined;
            _ = stringCopy(&scratch, &indexOfItems[@intCast(leftItem)].itemSoftmenuName);
            truncateAtArrow(&scratch);
            _ = stringCopy(pairName, &scratch);
            _ = stringCopy(pairName + @as(usize, @intCast(stringByteLength(pairName))), STD_RIGHT_ARROW);
            _ = stringCopy(&scratch, &indexOfItems[@intCast(rightItem)].itemSoftmenuName);
            truncateAtArrow(&scratch);
            _ = stringCopy(pairName + @as(usize, @intCast(stringByteLength(pairName))), &scratch);
        }
    } else {
        if (itemNrPair) |p| p.* = 0;                                            // standard pair (or mismatched UTs)
        if (pairName != null) {
            fullConvSoftMenuItemNameInclHPCONV(item, pairName);                 // delegate the standard-pair name
        }
    }
}

comptime {                                                                       // keep MimFunctionsType3Conv referenced until fType==3 dispatch lands
    _ = &MimFunctionsType3Conv;
}
