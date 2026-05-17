pub const calcRegister_t = i16;
pub const angularMode_t = c_int;
pub const rounding_t = c_int;
pub const trigType_t = c_int;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;

pub const amRadian: angularMode_t = 0;
pub const amNone: angularMode_t = 5;
pub const amAngleMask: u32 = 15;

pub const DEC_ROUND_CEILING: rounding_t = 0;
pub const DEC_ROUND_FLOOR: rounding_t = 6;

pub const trigSin: trigType_t = 0;
pub const trigCos: trigType_t = 1;

pub const dtLongInteger: u32 = 0;
pub const dtReal34: u32 = 1;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;

pub const LI_ZERO: u32 = 0;
pub const LI_NEGATIVE: u32 = 1;
pub const LI_POSITIVE: u32 = 2;

pub const ifLongIntegerDoAngleReduction = true;

pub const ERROR_NONE: u8 = 0;
pub const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;

pub const FLAG_SPCRES: i32 = 0x8017;

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

pub const VoidCallback = ?*const fn () callconv(.c) void;

pub extern var ctxtReal39: realContext_t;
pub extern var ctxtReal51: realContext_t;
pub extern var ctxtReal75: realContext_t;

pub extern fn saveLastX() bool;
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

pub extern fn getRegisterAsReal(reg: calcRegister_t, value: *real_t) bool;
pub extern fn getRegisterAsRealAngle(reg: calcRegister_t, value: *real_t, angle_mode: *angularMode_t, reduce_longinteger_angle: bool) bool;
pub extern fn getRegisterAsComplex(reg: calcRegister_t, real: *real_t, imag: *real_t) bool;
pub extern fn getSystemFlag(flag: i32) bool;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
pub extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: angularMode_t) void;
pub extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) void;

pub extern fn processRealComplexMonadicFunction(realf: VoidCallback, complexf: VoidCallback) void;
pub extern fn processIntRealComplexMonadicFunction(
    realf: VoidCallback,
    complexf: VoidCallback,
    shortintf: VoidCallback,
    longintf: VoidCallback,
) void;

pub extern fn integerPartNoOp() void;
pub extern fn integerPartReal(mode: rounding_t) void;
pub extern fn integerPartCplx(mode: rounding_t) void;

pub extern fn unitVectorCplx() void;
pub extern fn decQuadIsNaN(value: *const real34_t) u32;
pub extern fn decQuadIsZero(value: *const real34_t) u32;
pub extern fn decQuadIsNegative(value: *const real34_t) u32;
pub extern fn C47_WP34S_Cvt2RadSinCosTan(angle: *const real_t, mode: angularMode_t, sin: ?*real_t, cos: ?*real_t, tan: ?*real_t, real_context: *realContext_t) void;
pub extern fn WP34S_SinhCosh(x: *const real_t, sin_out: ?*real_t, cos_out: ?*real_t, real_context: *realContext_t) void;
pub extern fn WP34S_Tanh(x: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn divComplexComplex(
    numer_real: *const real_t,
    numer_imag: *const real_t,
    denom_real: *const real_t,
    denom_imag: *const real_t,
    quotient_real: *real_t,
    quotient_imag: *real_t,
    real_context: *realContext_t,
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
pub extern fn WP34S_intMultiply(y: u64, x: u64) u64;
pub extern fn WP34S_intChs(x: u64) u64;
pub extern fn WP34S_extract_value(val: u64, sign: *i32) u64;
pub extern fn decNumberMultiply(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberDivide(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberExp(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn realCompareAbsEqual(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsGreaterThan(number1: *const real_t, number2: *const real_t) bool;
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

pub extern fn z47_math_wrappers_build_sign_result(result: i32) void;
pub extern fn z47_math_wrappers_change_sign_long_integer() void;
pub extern fn z47_math_wrappers_square_long_integer() void;
pub extern fn z47_math_wrappers_cube_long_integer() void;
pub extern fn z47_math_wrappers_const_0() *const real_t;
pub extern fn z47_math_wrappers_const_1() *const real_t;
pub extern fn z47_math_wrappers_const_2e6() *const real_t;
pub extern fn z47_math_wrappers_const_plus_infinity() *const real_t;
pub extern fn z47_math_wrappers_const_minus_infinity() *const real_t;
pub extern fn z47_math_wrappers_report_exp_real_domain_error() void;
pub extern fn z47_math_wrappers_report_sign_real_nan_error() void;
pub extern fn z47_math_wrappers_report_invert_real_divide_by_zero_error() void;
pub extern fn z47_math_wrappers_report_sinh_cosh_real_domain_error() void;
pub extern fn z47_math_wrappers_report_tanh_real_domain_error() void;
pub extern fn z47_math_wrappers_report_square_real_domain_error() void;
pub extern fn z47_math_wrappers_report_tan_real_pole_error() void;
pub extern fn z47_math_wrappers_report_cube_real_domain_error() void;

pub fn registerShortIntegerPtr(reg: calcRegister_t) *align(1) u64 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn registerReal34Bytes(reg: calcRegister_t) *align(1) [16]u8 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn registerReal34Ptr(reg: calcRegister_t) *align(1) real34_t {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn getRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
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
