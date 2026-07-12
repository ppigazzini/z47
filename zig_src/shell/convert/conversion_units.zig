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

const abi = @import("abi"); // shared ABI bindings
const label_truncate = @import("../display/text/label_truncate.zig"); // std-only label arrow truncation
const frontier_addons = @import("../extensions/addons.zig");
const frontier_date_time = @import("date_time.zig");
const frontier_error = @import("../error.zig");
const frontier_items = @import("../display/items/items.zig");
const frontier_register_value_conversions = @import("../register_value_conversions.zig");
const real_t = abi.Real;
const realContext_t = abi.RealContext;

extern var ctxtReal39: realContext_t;
// `constants` is an extern byte array; @extern yields a pointer to its base.

extern fn decNumberMultiply(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberDivide(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberAdd(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;
extern fn decNumberSubtract(res: *real_t, a: *align(1) const real_t, b: *align(1) const real_t, ctx: *realContext_t) *real_t;

extern fn saveLastX() bool;
extern fn getSystemFlag(flag: i32) bool;
extern fn moreInfoOnError(m1: [*:0]const u8, m2: ?[*:0]const u8, m3: ?[*:0]const u8, m4: ?[*:0]const u8) void;
extern fn adjustResult(res: i16, drop_y: bool, set_cpx: bool, op1: i16, op2: i16, op3: i16) void;
extern fn getRegisterDataType(reg: i16) u32;
extern fn getRegisterTag(reg: i16) u32;
extern fn setRegisterTag(reg: i16, tag: u32) void;
extern fn fnToReal(p: u16) void;
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

// ---- generated data (offsets into `constants`) ----
const OFF_const_minusInfinity = 1684;
const OFF_const_plusInfinity = 1696;
const OFF_const_0 = 1708;
const OFF_const_1 = 4932;
const OFF_const_9on5 = 4992;
const OFF_const_32 = 5300;
const OFF_const_273p15 = 3992;
const OFF_const_459p67 = 4008;
const OFF_const39_kBeVK = 4024;
const OFF_const_9on10 = 4884;
const OFF_const39_180onPi = 5336;
const OFF_const39_200onPi = 5384;
const OFF_const_10 = 5208;
const OFF_const_20 = 5232;

// conversionFactors[constFactorEND]: offset into `constants`, or null.
const conversionFactorOffsets = [_]?u32{
    1948, // 0 constFactorFt2Hectare = const_Ft2ToHa
    1964, // 1 constFactorFt2M2 = const_Ft2ToM2
    7608, // 2 constFactorHectareKm2 = const_100
    2444, // 3 constFactorAcreHa = const_AccreToHa
    2464, // 4 constFactorAcreusHa = const39_AccreusToHa
    3240, // 5 constFactorAtmPa = const_AtmToPa
    2152, // 6 constFactorAuM = const_AuToM
    3228, // 7 constFactorBarPa = const_BarToPa
    3048, // 8 constFactorBtuJ = const_BtuToJ
    3032, // 9 constFactorCalJ = const_CalToJ
    3324, // 10 constFactorLbfftNm = const_LbfftToNm
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
    3296, // 21 constFactorHpeW = const_HpeToW
    3256, // 22 constFactorHpmW = const_HpmToW
    3272, // 23 constFactorHpukW = const_HpukToW
    3176, // 24 constFactorInhgPa = const_InhgToPa
    1920, // 25 constFactorInchMm = const_InchToMm
    3068, // 26 constFactorWhJ = const_WhToJ
    2748, // 27 constFactorLbKg = const_LbToKg
    2712, // 28 constFactorOzG = const_OzToG
    2780, // 29 constFactorShortcwtKg = const_ShortcwtToKg
    2764, // 30 constFactorStoneKg = const_StoneToKg
    2816, // 31 constFactorShorttonKg = const_ShorttonToKg
    2832, // 32 constFactorTonKg = const_LongtonToKg
    5232, // 33 constFactorLiangKg = const_20
    2732, // 34 constFactorTrozG = const_TrozToG
    3104, // 35 constFactorLbfN = const_LbfToN
    2172, // 36 constFactorLyM = const_LyToM
    3160, // 37 constFactorMmhgPa = const_MmhgToPa
    2048, // 38 constFactorMiKm = const_MiToKm
    2084, // 39 constFactorNmiKm = const_NmiToKm
    2192, // 40 constFactorPcM = const39_PcToM
    1884, // 41 constFactorPointMm = const39_PointToMm
    2312, // 42 constFactorMileM = const_MiToM
    2016, // 43 constFactorYardM = const_YardToM
    3192, // 44 constFactorPsiPa = const39_PsiToPa
    3124, // 45 constFactorTorrPa = const39_TorrToPa
    3308, // 46 constFactorYearS = const_YearToS
    2700, // 47 constFactorCaratG = const_CaratToG
    5004, // 48 constFactorJinKg = const_2
    2664, // 49 constFactorQuartL = const_QuartToL
    2032, // 50 constFactorFathomM = const_FathomToM
    2328, // 51 constFactorNMiM = const_NmiToM
    2680, // 52 constFactorBarrelM3 = const_BarrelToM3
    5588, // 53 constFactorHectareM2 = const_10000
    2500, // 54 constFactorMuM2 = const_MuToM2
    2228, // 55 constFactorLiM = const_LiToM
    5088, // 56 constFactorChiM = const_3
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
    3980, // 67 constFactorInchCm = const_InchToCm
    2100, // 68 constFactorNmiMi = const39_NmiToMi
    3348, // 69 constFactorFurtom = const_furToM
    3364, // 70 constFactorFtntos = const_ftnToS
    3380, // 71 constFactorFpftomps = const_fpfToMps
    3400, // 72 constFactorBrdstom = const_brdsTom
    3412, // 73 constFactorFirtokg = const_firToKg
    3428, // 74 constFactorFpftokph = const_fpfToKph
    3448, // 75 constFactorBrdstoin = const_brdsToIn
    3468, // 76 constFactorFirtolb = const_firToLb
    3480, // 77 constFactorFpftomph = const39_fpfToMph
    3516, // 78 constFactorFpstokph = const_fpsToKph
    3532, // 79 constFactorFpstomps = const_fpsToMps
    7608, // 80 constFactorL100Tokml = const_100
    null, // 81 constFactorKmletok100K (no factor)
    7608, // 82 constFactorK100Ktokmk = const_100
    null, // 83 constFactorL100Tomgus (no factor)
    null, // 84 constFactorMgeustok100M (no factor)
    2048, // 85 constFactorK100Ktok100M = const_MiToKm
    null, // 86 constFactorL100Tomguk (no factor)
    null, // 87 constFactorMgeuktok100M (no factor)
    7608, // 88 constFactorK100Mtomik = const_100
    3548, // 89 constFactorCupcFzus = const_CupcFzus
    3560, // 90 constFactorCupcMl = const_CupcMl
    3580, // 91 constFactorCupukFzuk = const_CupukFzuk
    3592, // 92 constFactorCupukMl = const_CupukMl
    3580, // 93 constFactorFzukCupuk = const_CupukFzuk
    3608, // 94 constFactorFzukTbspuk = const_FzukTbspuk
    3620, // 95 constFactorFzukTspuk = const_FzukTspuk
    3548, // 96 constFactorFzusCupc = const_CupcFzus
    3632, // 97 constFactorFzusTbspc = const_FzusTbspc
    3644, // 98 constFactorFzusTspc = const_FzusTspc
    3560, // 99 constFactorMlCupc = const_CupcMl
    3592, // 100 constFactorMlCupuk = const_CupukMl
    3656, // 101 constFactorMlPintlq = const_PintlqMl
    3672, // 102 constFactorMlPintuk = const_PintukMl
    3688, // 103 constFactorMlQt = const_QtMl
    3704, // 104 constFactorMlQtus = const_QtusMl
    3720, // 105 constFactorMlTbspc = const_TbspcMl
    3740, // 106 constFactorMlTbspuk = const_TbspukMl
    3760, // 107 constFactorMlTspc = const_TspcMl
    3780, // 108 constFactorMlTspuk = const39_TspukMl
    3656, // 109 constFactorPintlqMl = const_PintlqMl
    3672, // 110 constFactorPintukMl = const_PintukMl
    3688, // 111 constFactorQtMl = const_QtMl
    3704, // 112 constFactorQtusMl = const_QtusMl
    3632, // 113 constFactorTbspcFzus = const_FzusTbspc
    3720, // 114 constFactorTbspcMl = const_TbspcMl
    3608, // 115 constFactorTbspukFzuk = const_FzukTbspuk
    3740, // 116 constFactorTbspukMl = const_TbspukMl
    3644, // 117 constFactorTspcFzus = const_FzusTspc
    3760, // 118 constFactorTspcMl = const_TspcMl
    3620, // 119 constFactorTspukFzuk = const_FzukTspuk
    3780, // 120 constFactorTspukMl = const39_TspukMl
    3816, // 121 constFactorMlIn3 = const_In3Ml
    3816, // 122 constFactorIn3Ml = const_In3Ml
    3832, // 123 constFactorFt3Gluk = const_Ft3Gluk
    3832, // 124 constFactorGlukFt3 = const_Ft3Gluk
    3868, // 125 constFactorLFt3 = const_Ft3L
    3868, // 126 constFactorFt3L = const_Ft3L
    3888, // 127 constFactorLQtus = const_LQtus
    3888, // 128 constFactorQtusL = const_LQtus
    3908, // 129 constFactorGlukFzuk = const_GlukFzuk
    3908, // 130 constFactorFzukGluk = const_GlukFzuk
    3920, // 131 constFactorGlusFzus = const_GlusFzus
    3920, // 132 constFactorFzusGlus = const_GlusFzus
    156, // 133 constFactoreVJ = const_e
    156, // 134 constFactorJeV = const_e
    3932, // 135 constFactormmBanana = const_bananamm
    3932, // 136 constFactorBananamm = const_bananamm
    3944, // 137 constFactorInchBanana = const39_bananaInch
    3944, // 138 constFactorBananaInch = const39_bananaInch
    3080, // 139 constFactorErgJ = const_ErgToJ
    3092, // 140 constFactorFoeJ = const_FoeToJ
    2852, // 141 constFactorKnotMps = const39_KnotToMps
    5336, // 142 constFactor180onPi = const39_180onPi
    2960, // 143 constFactorSlugKg = const39_SlugToKg
    2996, // 144 constFactorSlinchKg = const39_SlinchToKg
    2996, // 145 constFactorBlobKg = const39_SlinchToKg
    5456, // 146 constFactorTonneKg = const_1000
    4136, // 147 constFactorLbsft2Pa = const39_Lbsft2ToPa
    4112, // 148 constFactorInlbsNm = const_InlbsToNm
    2960, // 149 constFactorLbsftNpm = const39_SlugToKg
    436, // 150 constFactorKgfN = const_gEarth
    4172, // 151 constFactorKsiMpa = const39_KsiToMpa
    4076, // 152 constFactorLbsBlob = const39_BlobInLbs
    4208, // 153 constFactorLbsin3Tmm3 = const39_Lbsin3ToTmm3
    4244, // 154 constFactorLbsin3Kgm3 = const39_Lbsin3ToKgm3
    4280, // 155 constFactorKgm3Blobin3 = const39_Kgm3ToBlobin3
    4572, // 156 constFactorKgm3Tmm3 = const_1e_12
    4316, // 157 constFactorLbsftKgm = const39_LbsftToKgm
    4352, // 158 constFactorIn3Mm3 = const_In3ToMm3
    4368, // 159 constFactorIn2Mm2 = const_In2ToMm2
    4384, // 160 constFactorIn4Mm4 = const_In4ToMm4
    4404, // 161 constFactorIn6Mm6 = const_In6ToMm6
    436, // 162 constFactorKgmNpm = const_gEarth
    4060, // 163 constFactorInchM = const_InchToM
    2748, // 164 constFactorLbfKgf = const_LbToKg
    2888, // 165 constFactorMphKnot = const39_MphToKnot
    2924, // 166 constFactorMphFps = const39_MphToFps
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

    if (!frontier_register_value_conversions.getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;

    if (invert and realIsZero(&re_x)) {
        if (getSystemFlag(FLAG_SPCRES)) {
            frontier_register_value_conversions.convertRealToResultRegister(@alignCast(cst(if (realIsNegative(&re_x)) OFF_const_minusInfinity else OFF_const_plusInfinity)), REGISTER_X, amNone);
        } else {
            frontier_error.displayCalcErrorMessage(ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN, ERR_REGISTER_LINE, REGISTER_X);
            if (comptime extra_info) moreInfoOnError("In function unitConversion:", "cannot calculate divide by zero", null, null);
        }
    }

    if (invert) rDiv(consts.c4856(), &re_x, &re_x);
    if (multiply_divide == multiply) rMul(&re_x, coefficient, &re_x) else rDiv(&re_x, coefficient, &re_x);

    frontier_register_value_conversions.convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}

pub export fn fnUnitConvert(arg: u16) callconv(.c) void {
    const md: u16 = arg & 0x8000;
    const invert = (arg & 0x4000) != 0;
    const idx: usize = arg & 0x3fff;
    // C indexes conversionFactors[idx] without a bounds check; a non-conversion
    // arg (idx past the table) reads a null/absent factor there and converts
    // nothing. Guard the index so the safe-indexed Zig array matches that
    // do-nothing behaviour instead of panicking.
    if (idx >= conversionFactorOffsets.len) {
        return;
    }
    if (conversionFactorOffsets[idx]) |offset| {
        unitConversion(cst(offset), md, invert);
    }
}

pub export fn fnCvtTemp(ix: u16) callconv(.c) void {
    var re_x: real_t = undefined;
    if (!frontier_register_value_conversions.getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;

    const row = cvtTempOffsets[ix];
    if (row[0] != OFF_const_0) rSub(&re_x, cst(row[0]), &re_x);
    if (row[1] != OFF_const_1) rDiv(&re_x, cst(row[1]), &re_x);
    if (row[2] != OFF_const_1) rMul(&re_x, cst(row[2]), &re_x);
    if (row[3] != OFF_const_0) rAdd(&re_x, cst(row[3]), &re_x);

    frontier_register_value_conversions.convertRealToResultRegister(&re_x, REGISTER_X, amNone);
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
        frontier_date_time.fnHMStoTM(0);
        fnToReal(0);
    } else {
        frontier_date_time.fnHRtoTM(0);
        frontier_addons.fnFrom_ms(0);
    }
}

pub export fn fnCvtRatioDb(ten_or_twenty: u16) callconv(.c) void {
    var re_x: real_t = undefined;
    if (!frontier_register_value_conversions.getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;
    WP34S_Log10(&re_x, &re_x, &ctxtReal39);
    rMul(&re_x, cst(if (ten_or_twenty == 10) OFF_const_10 else OFF_const_20), &re_x);
    frontier_register_value_conversions.convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}

pub export fn fnCvtDbRatio(ten_or_twenty: u16) callconv(.c) void {
    var re_x: real_t = undefined;
    if (!frontier_register_value_conversions.getRegisterAsReal(REGISTER_X, &re_x)) return;
    if (!saveLastX()) return;
    rDiv(&re_x, cst(if (ten_or_twenty == 10) OFF_const_10 else OFF_const_20), &re_x);
    realPower10(&re_x, &re_x, &ctxtReal39);
    frontier_register_value_conversions.convertRealToResultRegister(&re_x, REGISTER_X, amNone);
    adjustResult(REGISTER_X, false, false, -1, -1, -1);
}

// ─── configurable-conversion pair subsystem (conversionUnits.c) ───
// NEW upstream feature (master fd83b4a4). Additive/unreached by the pinned
// testSuite (no items.c dispatch wiring yet). convPair table + pure-logic
// helpers; the softmenu/HPCONV name helpers are a later slice.
const ITM_NULL: i16 = 0;
const fInMim_t = abi.FInMim;
const conversion_pairs = @import("conversion_pairs.zig"); // std-only pair table + predicates

const NUM_CONVERT_PAIRS = conversion_pairs.NUM_CONVERT_PAIRS;

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
    .{ .itemNr = 2860 }, // ITM_MPHtoKNOT
    .{ .itemNr = 2861 }, // ITM_KNOTtoMPH
    .{ .itemNr = 2862 }, // ITM_MPHtoFPS
    .{ .itemNr = 2863 }, // ITM_FPStoMPH
};

// The pair table, findPair, and the lookup predicates now live in
// conversion_pairs.zig (std-only, natively tested); these wrappers keep the
// exact C-ABI export symbols and delegate.
pub export fn conversionPartner(input: i16, unity: ?*i16, exponent: ?*i8, type_out: ?*u8) callconv(.c) i16 {
    return conversion_pairs.conversionPartner(input, unity, exponent, type_out);
}

pub export fn isItemConversion(itemNr: i16) callconv(.c) bool {
    return conversion_pairs.isItemConversion(itemNr);
}

pub export fn areBothConvertConfigurable(item1Nr: i16, item2Nr: i16) callconv(.c) bool {
    return conversion_pairs.areBothConvertConfigurable(item1Nr, item2Nr);
}

pub export fn isStandardPair(item1Nr: i16, item2Nr: i16) callconv(.c) bool {
    return conversion_pairs.isStandardPair(item1Nr, item2Nr);
}

pub export fn isOneOfAConvertPair(x: u16, itemNr: i16, oddNrPartner: *i16) callconv(.c) bool {
    return conversion_pairs.isOneOfAConvertPair(x, itemNr, oddNrPartner);
}

pub export fn runConversionToSI(itemNr: i16) callconv(.c) void {
    const entry = conversion_pairs.findPair(itemNr) orelse return; // not a conversion item; nothing to do
    if (entry.unity != ITM_NULL) {
        frontier_items.runFunction(entry.unity); // execute a conversion
    }
    if (entry.exponent != 0) {
        frontier_addons.fnMultiplySI(@intCast(@as(i32, 100) + entry.exponent)); // scale by 10^exponent
    }
}

pub export fn runConversionFromSI(itemNr: i16) callconv(.c) void {
    const entry = conversion_pairs.findPair(itemNr) orelse return;
    if (entry.exponent != 0) {
        frontier_addons.fnMultiplySI(@intCast(@as(i32, 100) - entry.exponent)); // undo the exponent
    }
    if (entry.unity != ITM_NULL) {
        if (conversion_pairs.findPair(entry.unity)) |unityEntry| { // a unity outside convertPairs[] must not crash
            frontier_items.runFunction(unityEntry.partner); // inverse of the unity step
        }
    }
    frontier_items.runFunction(entry.partner); // inverse of the user's choice
}

// ─── conversion-name slice: softmenu-name helpers (conversionUnits.c:778+) ───
// item_t / indexOfItems: exact layout copied from items.zig /
// softmenus.zig (must match src/c47 typeDefinitions.h item_t).
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
fn truncateAtArrow(label: [*c]u8) void {
    label_truncate.truncateAtArrow(label, STD_RIGHT_ARROW, STD_LEFT_ARROW);
}

pub export fn fullConvSoftMenuItemNameInclHPCONV(item: i16, outString: [*c]u8) callconv(.c) void {
    if (!isItemConversion(item)) { // not a conversion: plain softmenu name
        _ = stringCopy(outString, &indexOfItems[@intCast(item)].itemSoftmenuName);
        return;
    }
    const useNameExcludingRightArrowOnLeft: i16 = item;
    const useNameExcludingRightArrowOnRight: i16 = conversionPartner(item, null, null, null);
    var scratch: [64]u8 = undefined;
    _ = stringCopy(&scratch, &indexOfItems[@intCast(useNameExcludingRightArrowOnLeft)].itemSoftmenuName); // left side up to arrow
    truncateAtArrow(&scratch);
    _ = stringCopy(outString, &scratch);
    _ = stringCopy(outString + @as(usize, @intCast(stringByteLength(outString))), STD_RIGHT_ARROW); // arrow between sides
    _ = stringCopy(&scratch, &indexOfItems[@intCast(useNameExcludingRightArrowOnRight)].itemSoftmenuName); // right side up to arrow
    truncateAtArrow(&scratch);
    _ = stringCopy(outString + @as(usize, @intCast(stringByteLength(outString))), &scratch);
}

// Cross-owner globals for executionConversionPartner — EXACT decls copied from
// softmenus.zig (struct layouts must match that owner).
const userMenuItem_t = abi.UserMenuItem;
const userMenu_t = abi.UserMenu;
const softmenu_t = abi.Softmenu;
const softmenuStack_t = abi.SoftmenuStack;
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
    if (!isItemConversion(item)) { // not a conversion: plain softmenu name, no partner work
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
    if (areBothConvertConfigurable(item, softKeyPartner) and !isStandardPair(item, softKeyPartner)) { // custom non-standard pair of the SAME configurable UT
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
        if (itemNrPair) |p| p.* = 0; // standard pair (or mismatched UTs)
        if (pairName != null) {
            fullConvSoftMenuItemNameInclHPCONV(item, pairName); // delegate the standard-pair name
        }
    }
}

comptime { // keep MimFunctionsType3Conv referenced until fType==3 dispatch lands
    _ = &MimFunctionsType3Conv;
}
