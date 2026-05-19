pub const calcRegister_t = i16;
pub const angularMode_t = c_int;
pub const rounding_t = c_int;
pub const trigType_t = c_int;

pub const pcg32_random_t = extern struct {
    state: u64,
    inc: u64,
};

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

pub const amRadian: angularMode_t = 0;
pub const amDegree: angularMode_t = 2;
pub const amNone: angularMode_t = 5;
pub const amPolar: angularMode_t = 16;
pub const amAngleMask: u32 = 15;

pub const DEC_ROUND_CEILING: rounding_t = 0;
pub const DEC_ROUND_HALF_UP: rounding_t = 2;
pub const DEC_ROUND_HALF_EVEN: rounding_t = 3;
pub const DEC_ROUND_DOWN: rounding_t = 5;
pub const DEC_ROUND_FLOOR: rounding_t = 6;

pub const trigSin: trigType_t = 0;
pub const trigCos: trigType_t = 1;

pub const dtLongInteger: u32 = 0;
pub const dtReal34: u32 = 1;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtDate: u32 = 4;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;

pub const LI_ZERO: u32 = 0;
pub const LI_NEGATIVE: u32 = 1;
pub const LI_POSITIVE: u32 = 2;

pub const ifLongIntegerDoAngleReduction = true;

pub const ERROR_NONE: u8 = 0;
pub const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 2;
pub const ERROR_OUT_OF_RANGE: u8 = 3;
pub const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
pub const ERROR_OVERFLOW_MINUS_INF: u8 = 5;

pub const FLAG_CPXRES: i32 = 0x8004;
pub const FLAG_CARRY: i32 = 0x800b;
pub const FLAG_OVERFLOW: i32 = 0x800c;
pub const FLAG_SPCRES: i32 = 0x8017;
pub const FLAG_HPRP: i32 = 0x802b;

pub const SIM_UNSIGN: u8 = 0;
pub const SIM_1COMPL: u8 = 1;
pub const SIM_SIGNMT: u8 = 3;
pub const TI_FALSE: u8 = 12;

pub const DECNEG: u8 = 0x80;
const DECINF: u8 = 0x40;
const DECNAN: u8 = 0x20;
const DECSNAN: u8 = 0x10;
const DECSPECIAL: u8 = 0x70;
const DECNUMUNITS = 25;

pub const real_t = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [DECNUMUNITS]u16,
};

pub const real34_t = extern struct {
    bytes: [16]u8,
};

pub const realContext_t = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: rounding_t,
    traps: u32,
    status: u32,
    clamp: u8,
};

pub const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]c_ulong,
};

pub const longInteger_t = [1]mpz_struct;

pub const VoidCallback = ?*const fn () callconv(.c) void;

pub extern var ctxtReal34: realContext_t;
pub extern var ctxtReal39: realContext_t;
pub extern var ctxtReal51: realContext_t;
pub extern var ctxtReal75: realContext_t;
pub extern var shortIntegerMode: u8;
pub extern var shortIntegerMask: u64;
pub extern var shortIntegerSignBit: u64;
pub extern var currentAngularMode: angularMode_t;
pub extern var thereIsSomethingToUndo: bool;
pub extern var pcg32_global: pcg32_random_t;
pub extern var temporaryInformation: u8;
pub extern var lastErrorCode: u8;

pub extern fn saveLastX() bool;
pub extern fn saveForUndo() void;
pub extern fn getRegisterDataType(reg: calcRegister_t) u32;
pub extern fn getRegisterTag(reg: calcRegister_t) u32;
pub extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
pub extern fn registerMin(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
pub extern fn registerMax(regist1: calcRegister_t, regist2: calcRegister_t, dest: calcRegister_t) void;
pub extern fn adjustResult(
    res: calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: calcRegister_t,
    op2: calcRegister_t,
    op3: calcRegister_t,
) void;

pub extern fn getRegisterAsReal(reg: calcRegister_t, value: ?*real_t) bool;
pub extern fn getRegisterAsRealAngle(reg: calcRegister_t, value: *real_t, angle_mode: *angularMode_t, reduce_longinteger_angle: bool) bool;
pub extern fn getRegisterAsComplex(reg: calcRegister_t, real: *real_t, imag: *real_t) bool;
pub extern fn getRegisterAsShortInt(reg: calcRegister_t, sign: ?*bool, val: ?*u64, overflow: ?*bool, fractional: ?*bool) bool;
pub extern fn getRegisterAsLongInt(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) bool;
pub extern fn convertLongIntegerRegisterToReal(reg: calcRegister_t, real: *real_t, real_context: *realContext_t) void;
pub extern fn convertReal34ToLongIntegerRegister(real: *const real34_t, dest: calcRegister_t, rounding_mode: rounding_t) void;
pub extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const mpz_struct, regist: calcRegister_t) void;
pub extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, reg: calcRegister_t) void;
pub extern fn convertShortIntegerRegisterToUInt64(reg: calcRegister_t, sign: ?*i16, value: ?*u64) void;
pub extern fn getFlag(flag: u16) bool;
pub extern fn getSystemFlag(flag: i32) bool;
pub extern fn setSystemFlag(flag: i32) void;
pub extern fn clearSystemFlag(flag: i32) void;
pub extern fn forceSystemFlag(sf: c_uint, set: c_int) void;
pub extern fn fnSetFlag(flag: i32) void;
pub extern fn fnRefreshState() void;
pub extern fn setRegisterTag(reg: calcRegister_t, tag: u32) void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
pub extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: angularMode_t) void;
pub extern fn convertRealToLongIntegerRegister(real: *const real_t, dest: calcRegister_t, rounding_mode: rounding_t) void;
pub extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) void;
pub extern fn convertAngleFromTo(angle: *real_t, from_angular_mode: angularMode_t, to_angular_mode: angularMode_t, real_context: *realContext_t) void;
pub extern fn realPolarToRectangular(
    magnitude: *const real_t,
    angle: *const real_t,
    real: *real_t,
    imag: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn realRectangularToPolar(
    real: *const real_t,
    imag: *const real_t,
    magnitude: *real_t,
    theta: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn realNextToward(x: *const real_t, y: *const real_t, result: *real_t, real_context: *realContext_t) void;
pub extern fn complexMagnitude(real: *const real_t, imag: *const real_t, magnitude: *real_t, real_context: *realContext_t) void;

pub extern fn processRealComplexMonadicFunction(realf: VoidCallback, complexf: VoidCallback) void;
pub extern fn processIntRealComplexMonadicFunction(
    realf: VoidCallback,
    complexf: VoidCallback,
    shortintf: VoidCallback,
    longintf: VoidCallback,
) void;
pub extern fn processIntRealComplexDyadicFunction(
    realf: VoidCallback,
    complexf: VoidCallback,
    shortintf: VoidCallback,
    longintf: VoidCallback,
) void;

pub extern fn integerPartNoOp() void;
pub extern fn integerPartReal(mode: rounding_t) void;
pub extern fn integerPartCplx(mode: rounding_t) void;
pub extern fn liftStack() void;
pub extern fn reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn fnDrop(unused_but_mandatory_parameter: u16) void;
pub extern fn fnDropY(unused_but_mandatory_parameter: u16) void;
pub extern fn getUptimeMs() u32;
pub extern fn getFreeRamMemory() u32;
pub extern fn getFreeFlash() u32;

pub extern fn unitVectorCplx() void;
pub extern fn decQuadIsNaN(value: *const real34_t) u32;
pub extern fn decQuadIsZero(value: *const real34_t) u32;
pub extern fn decQuadIsNegative(value: *const real34_t) u32;
pub extern fn real34ToIntegralValue(source: *const real34_t, destination: *real34_t, mode: rounding_t) void;
pub extern fn real34IsInfinite(value: *const real34_t) bool;
pub extern fn real34GetExponent(value: *const real34_t) i32;
pub extern fn real34NextPlus(source: *const real34_t, destination: *real34_t) void;
pub extern fn real34NextMinus(source: *const real34_t, destination: *real34_t) void;
pub extern fn real34Subtract(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) void;
pub extern fn convertAngle34FromTo(angle: *real34_t, from_mode: angularMode_t, to_mode: angularMode_t) void;
pub extern fn C47_WP34S_Cvt2RadSinCosTan(angle: *const real_t, mode: angularMode_t, sin: ?*real_t, cos: ?*real_t, tan: ?*real_t, real_context: *realContext_t) void;
pub extern fn C47_WP34S_Asin(x: *const real_t, angle: *real_t, real_context: *realContext_t) void;
pub extern fn C47_WP34S_Acos(x: *const real_t, angle: *real_t, real_context: *realContext_t) void;
pub extern fn C47_WP34S_Atan(x: *const real_t, angle: *real_t, real_context: *realContext_t) void;
pub extern fn C47_WP34S_Atan2(y: *const real_t, x: *const real_t, angle: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_betai(b: *const real_t, a: *const real_t, x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_SinhCosh(x: *const real_t, sin_out: ?*real_t, cos_out: ?*real_t, real_context: *realContext_t) void;
pub extern fn WP34S_ArcSinh(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_ArcTanh(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Tanh(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Erf(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Erfc(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Bernoulli(x: *const real_t, res: *real_t, bnstar: bool, real_context: *realContext_t) void;
pub extern fn WP34S_InverseW(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_InverseComplexW(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_LambertW(x: *const real_t, res: *real_t, negative_branch: bool, real_context: *realContext_t) void;
pub extern fn WP34S_ComplexLambertW(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Factorial(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_ComplexGamma(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Ln(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Ln1P(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_ExpM1(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn logxyLonI(denom: *const real_t) void;
pub extern fn logxyReal(denom: *const real_t) void;
pub extern fn logxyCplx(denom: *const real_t) void;
pub extern fn lnComplex(real: *const real_t, imag: *const real_t, ln_real: *real_t, ln_imag: *real_t, real_context: *realContext_t) void;
pub extern fn sqrt1Px2Complex(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;
pub extern fn divComplexComplex(
    numer_real: *const real_t,
    numer_imag: *const real_t,
    denom_real: *const real_t,
    denom_imag: *const real_t,
    quotient_real: *real_t,
    quotient_imag: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn mulComplexi(
    in_real: *const real_t,
    in_imag: *const real_t,
    product_real: *real_t,
    product_imag: *real_t,
) void;
pub extern fn mulComplexComplex(
    factor1_real: *const real_t,
    factor1_imag: *const real_t,
    factor2_real: *const real_t,
    factor2_imag: *const real_t,
    product_real: *real_t,
    product_imag: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn mulComplexReal(
    factor1_real: *const real_t,
    factor1_imag: *const real_t,
    factor2: *const real_t,
    product_real: *real_t,
    product_imag: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn WP34S_intMultiply(y: u64, x: u64) u64;
pub extern fn WP34S_intGCD(y: u64, x: u64) u64;
pub extern fn WP34S_intLCM(y: u64, x: u64) u64;
pub extern fn WP34S_intAdd(x: u64, y: u64) u64;
pub extern fn WP34S_intSubtract(x: u64, y: u64) u64;
pub extern fn WP34S_int2pow(x: u64) u64;
pub extern fn WP34S_int10pow(x: u64) u64;
pub extern fn WP34S_intLog10(x: u64) u64;
pub extern fn WP34S_intLog2(x: u64) u64;
pub extern fn WP34S_intAbs(x: u64) u64;
pub extern fn WP34S_intChs(x: u64) u64;
pub extern fn WP34S_build_value(x: u64, sign: i32) u64;
pub extern fn WP34S_extract_value(val: u64, sign: *i32) u64;
pub extern fn WP34S_Mod(x: *const real_t, y: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn decimal128ToNumber(source: *const real34_t, destination: *real_t) *real_t;
pub extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberDivide(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberSquareRoot(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberExp(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberAdd(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberSubtract(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberFMA(result: *real_t, lhs: *const real_t, rhs: *const real_t, term: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberFromUInt32(result: *real_t, rhs: u32) *real_t;
pub extern fn __gmpz_clear(op: *mpz_struct) void;
pub extern fn __gmpz_cmp(lhs: *const mpz_struct, rhs: *const mpz_struct) c_int;
pub extern fn __gmpz_set_si(op: *mpz_struct, value: c_long) void;
pub extern fn __gmpz_add(result: *mpz_struct, lhs: *const mpz_struct, rhs: *const mpz_struct) void;
pub extern fn int32ToReal(source: i32, destination: *real_t) void;
pub extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: rounding_t, real_context: *realContext_t) void;
pub extern fn realCompareEqual(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsEqual(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsGreaterThan(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realIsAnInteger(x: *const real_t) bool;
pub extern fn divRealComplex(
    numer: *const real_t,
    denom_real: *const real_t,
    denom_imag: *const real_t,
    quotient_real: *real_t,
    quotient_imag: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn fnInvertMatrix(unused_but_mandatory_parameter: u16) void;
pub extern fn realSetNaN(value: *real_t) void;
pub extern fn realSetZero(value: *real_t) void;
pub extern fn realSetOne(value: *real_t) void;
pub extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;

pub extern fn z47_math_wrappers_build_sign_result(result: i32) void;
pub extern fn z47_math_wrappers_change_sign_long_integer() void;
pub extern fn z47_math_wrappers_square_long_integer() void;
pub extern fn z47_math_wrappers_cube_long_integer() void;
pub extern fn z47_math_wrappers_const_0() *const real_t;
pub extern fn z47_math_wrappers_const_1() *const real_t;
pub extern fn z47_math_wrappers_const_minus_1() *const real_t;
pub extern fn z47_math_wrappers_const_2() *const real_t;
pub extern fn z47_math_wrappers_const_1on2() *const real_t;
pub const retained = struct {
    pub extern fn z47_math_wrappers_retained_fnBn(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnBnStar(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnExpt(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnWpositive(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnWnegative(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnWinverse(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnGcd(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnLcm(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnMod(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnRmd(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnUlp(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnMant(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnRoundi(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnNeighb(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnIxyz(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnFactorial(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnRealPart(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnImaginaryPart(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnArg(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnMagnitude(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnConjugate(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnSwapRealImaginary(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnAtan2(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnPercent(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnAdd(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnSubtract(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnMultiply(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDivide(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnIDiv(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnIDivR(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDblMultiply(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnRound(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDecomp(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckInteger(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDec(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnInc(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXLessThan(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXLessEqual(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXGreaterThan(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXGreaterEqual(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXEqualsTo(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXNotEqual(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnXAlmostEqual(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnIsConverged(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckType(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckReal(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckNumber(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckAngle(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckMatrix(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckMatrixSquare(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckForZero(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckIsVect2d(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckIsVect3d(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckNaN(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckInfinite(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckSpecial(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckPlusZero(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCheckMinusZero(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnGetType(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDblDivide(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDblDivideRemainder(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnToPolar2(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnToRect2(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnToRect(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnParallel(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnUnitVector(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnSdl(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnSdr(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnSquareRoot(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCubeRoot(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnPercentMRR(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnPercentPlusMG(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnPercentT(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDeltaPercent(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnFib(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnLINPOL(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnCross(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnDot(unused_but_mandatory_parameter: u16) void;
    pub extern fn z47_math_wrappers_retained_fnLogXY(unused_but_mandatory_parameter: u16) void;
};
pub extern fn z47_math_wrappers_const_2e6() *const real_t;
pub extern fn z47_math_wrappers_const_90() *const real_t;
pub extern fn z47_math_wrappers_const_180() *const real_t;
pub extern fn z47_math_wrappers_const_1oneE() *const real_t;
pub extern fn z47_math_wrappers_const_ln2() *const real_t;
pub extern fn z47_math_wrappers_const_ln10() *const real_t;
pub extern fn z47_math_wrappers_const_pi() *const real_t;
pub extern fn z47_math_wrappers_const_plus_infinity() *const real_t;
pub extern fn z47_math_wrappers_const_minus_infinity() *const real_t;
pub extern fn z47_math_wrappers_minus_one_power_long_integer() void;
pub extern fn z47_math_wrappers_integer_part_long_integer() void;
pub extern fn z47_math_wrappers_integer_part_short_integer() void;
pub extern fn z47_math_wrappers_fractional_part_long_integer() void;
pub extern fn z47_math_wrappers_fractional_part_short_integer() void;
pub extern fn z47_math_wrappers_fractional_part_real() void;
pub extern fn z47_math_wrappers_gcd_int() void;
pub extern fn z47_math_wrappers_gcd_short_integer() void;
pub extern fn z47_math_wrappers_lcm_int() void;
pub extern fn z47_math_wrappers_lcm_short_integer() void;
pub extern fn z47_math_wrappers_fact_real() void;
pub extern fn z47_math_wrappers_fact_cplx() void;
pub extern fn z47_math_wrappers_fact_long_integer() void;
pub extern fn z47_math_wrappers_fact_short_integer() void;
pub extern fn z47_math_wrappers_mod_real() void;
pub extern fn z47_math_wrappers_mod_short_integer() void;
pub extern fn z47_math_wrappers_mod_long_integer() void;
pub extern fn z47_math_wrappers_rmd_real() void;
pub extern fn z47_math_wrappers_rmd_short_integer() void;
pub extern fn z47_math_wrappers_rmd_long_integer() void;
pub extern fn z47_math_wrappers_neighb_real() void;
pub extern fn z47_math_wrappers_neighb_short_integer() void;
pub extern fn z47_math_wrappers_neighb_long_integer() void;
pub extern fn z47_math_wrappers_small_base_power_long_integer(base_value: u32) i32;
pub extern fn z47_math_wrappers_report_int_pow_real_domain_error() void;
pub extern fn z47_math_wrappers_report_exp_real_domain_error() void;
pub extern fn z47_math_wrappers_report_arcsin_real_domain_error() void;
pub extern fn z47_math_wrappers_report_arccos_real_domain_error() void;
pub extern fn z47_math_wrappers_report_arctan_real_domain_error() void;
pub extern fn z47_math_wrappers_report_arccosh_real_domain_error() void;
pub extern fn z47_math_wrappers_report_arctanh_real_positive_one_domain_error() void;
pub extern fn z47_math_wrappers_report_arctanh_real_negative_one_domain_error() void;
pub extern fn z47_math_wrappers_report_arctanh_real_domain_error() void;
pub extern fn z47_math_wrappers_report_eulers_formula_complex_domain_error() void;
pub extern fn z47_math_wrappers_report_eulers_formula_real_domain_error() void;
pub extern fn z47_math_wrappers_report_sign_real_nan_error() void;
pub extern fn z47_math_wrappers_report_invert_real_divide_by_zero_error() void;
pub extern fn z47_math_wrappers_report_sinh_cosh_real_domain_error() void;
pub extern fn z47_math_wrappers_report_tanh_real_domain_error() void;
pub extern fn z47_math_wrappers_report_square_real_domain_error() void;
pub extern fn z47_math_wrappers_report_tan_real_pole_error() void;
pub extern fn z47_math_wrappers_report_cube_real_domain_error() void;
pub extern fn z47_math_wrappers_report_sinc_real_domain_error() void;
pub extern fn z47_math_wrappers_report_sincpi_real_domain_error() void;
pub extern fn z47_math_wrappers_report_exp_m1_real_domain_error() void;
pub extern fn z47_math_wrappers_report_ln_p1_real_zero_domain_error() void;
pub extern fn z47_math_wrappers_report_ln_p1_real_infinite_domain_error() void;
pub extern fn z47_math_wrappers_report_ln_p1_real_negative_domain_error() void;
pub extern fn z47_math_wrappers_report_ln_p1_cplx_zero_domain_error() void;
pub extern fn moreInfoOnError(msg1: [*:0]const u8, msg2: ?[*:0]const u8, msg3: ?[*:0]const u8, msg4: ?[*:0]const u8) void;
pub extern fn z47_math_wrappers_seed_defaults(seed: *u64, seq: *u64) void;
pub extern fn z47_math_wrappers_do_int_random_i() void;

pub fn registerShortIntegerPtr(reg: calcRegister_t) *align(1) u64 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn setRegisterLongIntegerSign(reg: calcRegister_t, sign: u32) void {
    setRegisterTag(reg, sign);
}

pub fn real34SetPositiveSign(value: *real34_t) void {
    value.bytes[15] &= 0x7f;
}

pub fn registerReal34Bytes(reg: calcRegister_t) *align(1) [16]u8 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn registerReal34Ptr(reg: calcRegister_t) *align(1) real34_t {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn registerImag34Ptr(reg: calcRegister_t) *align(1) real34_t {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    return @ptrCast(bytes + @sizeOf(real34_t));
}

pub fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}

pub fn setRegisterAngularMode(reg: calcRegister_t, mode: angularMode_t) void {
    setRegisterTag(reg, @intCast(mode));
}

pub fn getComplexRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}

pub fn setComplexRegisterAngularMode(reg: calcRegister_t, mode: angularMode_t) void {
    setRegisterTag(reg, (@as(u32, @intCast(mode)) & amAngleMask) | (getRegisterTag(reg) & @as(u32, @intCast(amPolar))));
}

pub fn setComplexRegisterPolarMode(reg: calcRegister_t, mode: angularMode_t) void {
    const polar_mask: u32 = @intCast(amPolar);
    const mode_bits: u32 = @intCast(mode);
    const base_tag = if ((mode_bits & polar_mask) != 0)
        getRegisterTag(reg) & amAngleMask
    else
        @as(u32, @intCast(amNone));

    setRegisterTag(reg, base_tag | (mode_bits & polar_mask));
}

pub fn setTemporaryInformation(condition: bool) void {
    temporaryInformation = TI_FALSE + @as(u8, @intFromBool(condition));
}

pub fn getRegisterLongIntegerSign(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}

pub inline fn realIsSpecial(value: *const real_t) bool {
    return (value.bits & DECSPECIAL) != 0;
}

pub inline fn realIsInfinite(value: *const real_t) bool {
    return (value.bits & DECINF) != 0;
}

pub inline fn realIsNaN(value: *const real_t) bool {
    return (value.bits & (DECNAN | DECSNAN)) != 0;
}

pub inline fn realIsNegative(value: *const real_t) bool {
    return (value.bits & DECNEG) != 0;
}

pub inline fn real34IsNaN(value: *const real34_t) bool {
    return decQuadIsNaN(value) != 0;
}

pub inline fn real34IsZero(value: *const real34_t) bool {
    return decQuadIsZero(value) != 0;
}

pub inline fn real34IsNegative(value: *const real34_t) bool {
    return decQuadIsNegative(value) != 0;
}

pub inline fn realIsZero(value: *const real_t) bool {
    return value.digits == 1 and value.lsu[0] == 0 and !realIsSpecial(value);
}

pub inline fn realChangeSign(value: *real_t) void {
    value.bits ^= 0x80;
}

pub inline fn realSetPositiveSign(value: *real_t) void {
    value.bits &= 0x7f;
}

pub inline fn realMultiply(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberMultiply(result, lhs, rhs, real_context);
}

pub inline fn realDivide(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberDivide(result, lhs, rhs, real_context);
}

pub inline fn realSquareRoot(rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberSquareRoot(result, rhs, real_context);
}

pub inline fn realAdd(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberAdd(result, lhs, rhs, real_context);
}

pub inline fn realSubtract(lhs: *const real_t, rhs: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberSubtract(result, lhs, rhs, real_context);
}

pub inline fn realFMA(factor1: *const real_t, factor2: *const real_t, term: *const real_t, result: *real_t, real_context: *realContext_t) void {
    _ = decNumberFMA(result, factor1, factor2, term, real_context);
}

pub inline fn uInt32ToReal(source: u32, destination: *real_t) void {
    _ = decNumberFromUInt32(destination, source);
}
