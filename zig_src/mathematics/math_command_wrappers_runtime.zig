const build_options = @import("math_command_wrappers_build_options");
const use_fake_wp34s_harness_surface = @hasDecl(build_options, "use_fake_wp34s_harness_surface") and build_options.use_fake_wp34s_harness_surface;
pub const harness_surface_is_fake = use_fake_wp34s_harness_surface;
pub const is_testsuite_build = @hasDecl(build_options, "is_testsuite_build") and build_options.is_testsuite_build;
// Mirrors "#if defined(DMCP_BUILD) && HARDWARE_MODEL == HWM_DM42" in wp34s.c:
// the DM42 firmware uses smaller fallback buffers and reduced precision in the
// WP34S_Mod / WP34S_BigMod range reduction. Only the "dmcp" build sets it.
pub const wp34s_mod_small_buffers = @hasDecl(build_options, "wp34s_mod_small_buffers") and build_options.wp34s_mod_small_buffers;

// Heavy/cold math owners run from executable QSPI (XIP) on the flash-limited
// DM42 old_hw firmware to keep main FLASH free; host/dmcp5/macOS keep the
// normal section (no-op there). Same mechanism as the dateTime owner.
const dm42_pkg_xip = @hasDecl(build_options, "dm42_pkg_xip") and build_options.dm42_pkg_xip;
pub const code_section = if (dm42_pkg_xip)
    ".qspi"
else if (@import("builtin").target.os.tag == .macos)
    "__TEXT,__text"
else
    ".text";

// Mirrors EXTRA_INFO_ON_CALC_ERROR (src/c47/defines.h): the console
// extra-error-info path is compiled out under TESTSUITE_BUILD and on DMCP
// firmware, and kept on the hosted on-screen-keyboard simulator. Dropping it
// from the firmware also keeps the diagnostic strings out of the flash image.
pub const extra_info_on_calc_error = !is_testsuite_build and
    @import("builtin").target.os.tag != .freestanding;

pub const calcRegister_t = i16;
pub const angularMode_t = c_int;
pub const rounding_t = c_int;
pub const trigType_t = c_int;

pub const pcg32_random_t = extern struct {
    state: u64,
    inc: u64,
};

pub const NOPARAM: u16 = 9876;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_T: calcRegister_t = 103;
pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
pub const REGISTER_L: calcRegister_t = 108;

pub const amRadian: angularMode_t = 0;
pub const amGrad: angularMode_t = 1;
pub const amDegree: angularMode_t = 2;
pub const amDMS: angularMode_t = 3;
pub const amMultPi: angularMode_t = 4;
pub extern fn copySourceRegisterToDestRegister(source_register: calcRegister_t, dest_register: calcRegister_t) void;
pub const amNone: angularMode_t = 5;
pub const amPolar: angularMode_t = 16;
pub const amPolarCYL: angularMode_t = 64;
pub const amPolarSPH: angularMode_t = 128;
pub const amAngleMask: u32 = 15;

pub const DEC_ROUND_CEILING: rounding_t = 0;
pub const DEC_ROUND_HALF_UP: rounding_t = 2;
pub const DEC_ROUND_HALF_EVEN: rounding_t = 3;
pub const DEC_ROUND_HALF_DOWN: rounding_t = 4;
pub const DEC_ROUND_DOWN: rounding_t = 5;
pub const DEC_ROUND_FLOOR: rounding_t = 6;

pub const trigSin: trigType_t = 0;
pub const trigCos: trigType_t = 1;

pub const dtLongInteger: u32 = 0;
pub const dtReal34: u32 = 1;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtDate: u32 = 4;
pub const dtString: u32 = 5;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;
pub const dtConfig: u32 = 9;

pub const LI_ZERO: u32 = 0;
pub const LI_NEGATIVE: u32 = 1;
pub const LI_POSITIVE: u32 = 2;

pub const ifLongIntegerDoAngleReduction = true;

pub const ERROR_NONE: u8 = 0;
pub const ERROR_ARG_EXCEEDS_FUNCTION_DOMAIN: u8 = 1;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = if (use_fake_wp34s_harness_surface) 2 else 24;
pub const ERROR_OUT_OF_RANGE: u8 = if (use_fake_wp34s_harness_surface) 3 else 8;
pub const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
pub const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
pub const ERROR_RAM_FULL: u8 = if (use_fake_wp34s_harness_surface) 6 else 11;
pub const ERROR_MATRIX_MISMATCH: u8 = if (use_fake_wp34s_harness_surface) 7 else 21;

pub const FLAG_CPXRES: i32 = 0x8004;
pub const FLAG_PROPFR: i32 = 0x8008;
pub const FLAG_CARRY: i32 = 0x800b;
pub const FLAG_OVERFLOW: i32 = 0x800c;
pub const FLAG_SPCRES: i32 = 0x8017;
pub const FLAG_ASLIFT: i32 = 0x8019;
pub const FLAG_HPRP: i32 = 0x802b;

pub const SIM_UNSIGN: u8 = 0;
pub const SIM_1COMPL: u8 = 1;
pub const SIM_2COMPL: u8 = 2;
pub const SIM_SIGNMT: u8 = 3;
pub const TI_FALSE: u8 = 12;
pub const TI_REGTYPE: u8 = 123;
pub const TI_VECTOR: u8 = 127;

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

pub const complex34_t = extern struct {
    real: real34_t,
    imag: real34_t,
};

pub const matrixHeader_t = if (use_fake_wp34s_harness_surface)
    extern struct {
        matrixRows: u16,
        matrixColumns: u16,
    }
else
    packed struct(u32) {
        matrixRows: u12,
        matrixColumns: u12,
        mtag: u6,
        notUsed: u2,
    };

pub const real34Matrix_t = if (use_fake_wp34s_harness_surface)
    extern struct {
        header: matrixHeader_t,
        matrixElements: [4]real34_t,
    }
else
    extern struct {
        header: matrixHeader_t,
        matrixElements: [*c]real34_t,
    };

pub const complex34Matrix_t = if (use_fake_wp34s_harness_surface)
    extern struct {
        header: matrixHeader_t,
        matrixElements: [4]complex34_t,
    }
else
    extern struct {
        header: matrixHeader_t,
        matrixElements: [*c]complex34_t,
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
pub extern var shortIntegerWordSize: u8;
pub extern var shortIntegerMask: u64;
pub extern var shortIntegerSignBit: u64;
pub extern var currentAngularMode: angularMode_t;
pub extern var thereIsSomethingToUndo: bool;
pub extern var pcg32_global: pcg32_random_t;
pub extern var significantDigits: u8;
pub extern var temporaryInformation: u8;
pub extern var lastErrorCode: u8;
pub extern var systemFlags0: u64;
pub extern var systemFlags1: u64;
pub extern var const_NaN: *const real_t;

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
pub extern fn getRegisterAsLongIntQuiet(reg: calcRegister_t, val: *mpz_struct, fractional: ?*bool) c_int;
pub extern fn convertLongIntegerRegisterToLongInteger(reg: calcRegister_t, long_integer: *mpz_struct) void;
pub extern fn convertShortIntegerRegisterToLongInteger(reg: calcRegister_t, long_integer: *mpz_struct) void;
pub extern fn convertLongIntegerRegisterToReal(reg: calcRegister_t, real: *real_t, real_context: *realContext_t) void;
pub extern fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertTimeRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertReal34RegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertReal34ToLongIntegerRegister(real: *const real34_t, dest: calcRegister_t, rounding_mode: rounding_t) void;
pub extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const mpz_struct, regist: calcRegister_t) void;
pub extern fn convertLongIntegerToShortIntegerRegister(long_integer: *const mpz_struct, base: u32, regist: calcRegister_t) void;
pub extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, reg: calcRegister_t) void;
pub extern fn convertShortIntegerRegisterToUInt64(reg: calcRegister_t, sign: ?*i16, value: ?*u64) void;
pub extern fn convertShortIntegerRegisterToReal(source: calcRegister_t, destination: *real_t, real_context: *realContext_t) void;
pub extern fn convergenceTolerence(tol: *real_t) void;
pub extern fn WP34S_RelativeError(x: *const real_t, y: *const real_t, tol: *const real_t, real_context: *realContext_t) bool;
pub extern fn WP34S_AbsoluteError(x: *const real_t, y: *const real_t, tol: *const real_t, real_context: *realContext_t) bool;
pub extern fn WP34S_ComplexRelativeError(
    x_real: *const real_t,
    x_imag: *const real_t,
    y_real: *const real_t,
    y_imag: *const real_t,
    tol: *const real_t,
    real_context: *realContext_t,
) bool;
pub extern fn WP34S_ComplexAbsError(
    x_real: *const real_t,
    x_imag: *const real_t,
    y_real: *const real_t,
    y_imag: *const real_t,
    tol: *const real_t,
    real_context: *realContext_t,
) bool;
pub extern fn getFlag(flag: u16) bool;
pub extern fn getSystemFlag(flag: i32) bool;
pub extern fn setSystemFlag(flag: i32) void;
pub extern fn clearSystemFlag(flag: i32) void;
pub extern fn fnChangeBase(base: u16) void;
pub extern fn forceSystemFlag(sf: c_uint, set: c_int) void;
pub extern fn fnSetFlag(flag: i32) void;
pub extern fn fnRefreshState() void;
pub extern fn setLastintegerBasetoZero() void;
pub extern fn setRegisterTag(reg: calcRegister_t, tag: u32) void;
pub extern fn linkToComplexMatrixRegister(reg: calcRegister_t, matrix: *complex34Matrix_t) void;
pub extern fn linkToRealMatrixRegister(reg: calcRegister_t, matrix: *real34Matrix_t) void;
pub extern fn realMatrixInit(matrix: *real34Matrix_t, rows: u16, columns: u16) bool;
pub extern fn complexMatrixInit(matrix: *complex34Matrix_t, rows: u16, columns: u16) bool;
pub extern fn realMatrixFree(matrix: *real34Matrix_t) void;
pub extern fn complexMatrixFree(matrix: *complex34Matrix_t) void;
pub extern fn convertReal34MatrixToReal34MatrixRegister(matrix: *const real34Matrix_t, reg: calcRegister_t) void;
pub extern fn convertComplex34MatrixToComplex34MatrixRegister(matrix: *const complex34Matrix_t, reg: calcRegister_t) void;
pub extern fn convertReal34MatrixRegisterToReal34Matrix(reg: calcRegister_t, matrix: *real34Matrix_t) void;
pub extern fn convertReal34MatrixRegisterToComplex34Matrix(reg: calcRegister_t, matrix: *complex34Matrix_t) void;
pub extern fn convertReal34MatrixRegisterToComplex34MatrixRegister(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertReal34MatrixToComplex34Matrix(real_matrix: *const real34Matrix_t, complex_matrix: *complex34Matrix_t) void;
pub extern fn realVectorSize(matrix: *const real34Matrix_t) u16;
pub extern fn dotRealVectors(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34_t) void;
pub extern fn crossRealVectors(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) void;
pub extern fn complexVectorSize(matrix: *const complex34Matrix_t) u16;
pub extern fn dotComplexVectors(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res_r: *real34_t, res_i: *real34_t) void;
pub extern fn crossComplexVectors(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
pub extern fn getRegisterDataTypeName(reg: calcRegister_t, article: bool, abbreviated: bool) [*:0]const u8;
pub extern fn convertRealToResultRegister(real: *const real_t, dest: calcRegister_t, angle_mode: angularMode_t) void;
pub extern fn convertRealToLongIntegerRegister(real: *const real_t, dest: calcRegister_t, rounding_mode: rounding_t) void;
pub extern fn convertComplexToResultRegister(real: *const real_t, imag: *const real_t, dest: calcRegister_t) void;
pub extern fn fraction(regist: calcRegister_t, sign: *i16, int_part: *u64, numer: *u64, denom: *u64, less_equal_greater: *i16) bool;
pub extern fn convertAngleFromTo(angle: *real_t, from_angular_mode: angularMode_t, to_angular_mode: angularMode_t, real_context: *realContext_t) void;
pub extern fn mod2Pi(x: *const real_t, result: *real_t, real_context: *realContext_t) void;
pub extern fn real34RectangularToPolar(real: *const real34_t, imag: *const real34_t, magnitude: *real34_t, theta: *real34_t) void;
pub extern fn roundToSignificantDigits(source: *const real_t, destination: *real_t, digits: i32, real_context: *realContext_t) void;
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
pub extern fn processRealComplexDyadicFunction(realf: VoidCallback, complexf: VoidCallback) void;
pub extern fn elementwiseRema(realf: VoidCallback) void;
pub extern fn elementwiseRemaReal(realf: VoidCallback) void;
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
pub extern fn addLonITime() void;
pub extern fn addTimeLonI() void;
pub extern fn addLonIDate() void;
pub extern fn addDateLonI() void;
pub extern fn addLonICplx() void;
pub extern fn addCplxLonI() void;
pub extern fn addTimeTime() void;
pub extern fn addTimeReal() void;
pub extern fn addRealTime() void;
pub extern fn addDateReal() void;
pub extern fn addRealDate() void;
pub extern fn addRemaLonI() void;
pub extern fn addLonIRema() void;
pub extern fn addRemaRema() void;
pub extern fn addRemaCxma() void;
pub extern fn addCxmaRema() void;
pub extern fn addRemaShoI() void;
pub extern fn addShoIRema() void;
pub extern fn addRemaReal() void;
pub extern fn addRealRema() void;
pub extern fn addRemaCplx() void;
pub extern fn addCplxRema() void;
pub extern fn addCxmaLonI() void;
pub extern fn addLonICxma() void;
pub extern fn addCxmaCxma() void;
pub extern fn addCxmaShoI() void;
pub extern fn addShoICxma() void;
pub extern fn addCxmaReal() void;
pub extern fn addRealCxma() void;
pub extern fn addCxmaCplx() void;
pub extern fn addCplxCxma() void;
pub extern fn addShoICplx() void;
pub extern fn addCplxShoI() void;
pub extern fn addRealCplx() void;
pub extern fn addCplxReal() void;
pub extern fn addCplxCplx() void;
pub extern fn subLonITime() void;
pub extern fn subTimeLonI() void;
pub extern fn subDateLonI() void;
pub extern fn subLonICplx() void;
pub extern fn subCplxLonI() void;
pub extern fn subTimeTime() void;
pub extern fn subTimeReal() void;
pub extern fn subRealTime() void;
pub extern fn subDateDate() void;
pub extern fn subDateReal() void;
pub extern fn subRemaLonI() void;
pub extern fn subLonIRema() void;
pub extern fn subRemaRema() void;
pub extern fn subRemaCxma() void;
pub extern fn subCxmaRema() void;
pub extern fn subRemaShoI() void;
pub extern fn subShoIRema() void;
pub extern fn subRemaReal() void;
pub extern fn subRealRema() void;
pub extern fn subRemaCplx() void;
pub extern fn subCplxRema() void;
pub extern fn subCxmaLonI() void;
pub extern fn subLonICxma() void;
pub extern fn subCxmaCxma() void;
pub extern fn subCxmaShoI() void;
pub extern fn subShoICxma() void;
pub extern fn subCxmaReal() void;
pub extern fn subRealCxma() void;
pub extern fn subCxmaCplx() void;
pub extern fn subCplxCxma() void;
pub extern fn subShoICplx() void;
pub extern fn subCplxShoI() void;
pub extern fn subRealCplx() void;
pub extern fn subCplxReal() void;
pub extern fn subCplxCplx() void;
pub extern fn mulLonITime() void;
pub extern fn mulTimeLonI() void;
pub extern fn mulLonIRema() void;
pub extern fn mulRemaLonI() void;
pub extern fn mulLonICxma() void;
pub extern fn mulCxmaLonI() void;
pub extern fn mulLonICplx() void;
pub extern fn mulCplxLonI() void;
pub extern fn mulTimeShoI() void;
pub extern fn mulShoITime() void;
pub extern fn mulTimeReal() void;
pub extern fn mulRealTime() void;
pub extern fn mulRemaRema() void;
pub extern fn mulRemaCxma() void;
pub extern fn mulCxmaRema() void;
pub extern fn mulRemaShoI() void;
pub extern fn mulShoIRema() void;
pub extern fn mulRemaReal() void;
pub extern fn mulRealRema() void;
pub extern fn mulRemaCplx() void;
pub extern fn mulCplxRema() void;
pub extern fn mulCxmaCxma() void;
pub extern fn mulCxmaShoI() void;
pub extern fn mulShoICxma() void;
pub extern fn mulCxmaReal() void;
pub extern fn mulRealCxma() void;
pub extern fn mulCxmaCplx() void;
pub extern fn mulCplxCxma() void;
pub extern fn mulShoICplx() void;
pub extern fn mulCplxShoI() void;
pub extern fn mulRealCplx() void;
pub extern fn mulCplxReal() void;
pub extern fn mulCplxCplx() void;
pub extern fn divLonITime() void;
pub extern fn divTimeLonI() void;
pub extern fn divLonICplx() void;
pub extern fn divCplxLonI() void;
pub extern fn divTimeShoI() void;
pub extern fn divShoITime() void;
pub extern fn divTimeReal() void;
pub extern fn divRealTime() void;
pub extern fn divTimeTime() void;
pub extern fn divRemaLonI() void;
pub extern fn divLonIRema() void;
pub extern fn divRemaRema() void;
pub extern fn divRemaCxma() void;
pub extern fn divRemaShoI() void;
pub extern fn divShoIRema() void;
pub extern fn divRemaReal() void;
pub extern fn divRealRema() void;
pub extern fn divRemaCplx() void;
pub extern fn divCplxRema() void;
pub extern fn divCxmaLonI() void;
pub extern fn divLonICxma() void;
pub extern fn divCxmaRema() void;
pub extern fn divCxmaCxma() void;
pub extern fn divCxmaShoI() void;
pub extern fn divShoICxma() void;
pub extern fn divCxmaReal() void;
pub extern fn divRealCxma() void;
pub extern fn divCxmaCplx() void;
pub extern fn divCplxCxma() void;
pub extern fn divShoICplx() void;
pub extern fn divCplxShoI() void;
pub extern fn divRealCplx() void;
pub extern fn divCplxReal() void;
pub extern fn divCplxCplx() void;

pub extern fn integerPartNoOp() void;
pub extern fn integerPartReal(mode: rounding_t) void;
pub extern fn integerPartCplx(mode: rounding_t) void;
pub extern fn liftStack() void;
pub extern fn reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn fnDrop(unused_but_mandatory_parameter: u16) void;
pub extern fn fnDropY(unused_but_mandatory_parameter: u16) void;
pub extern fn fnUndo(unused_but_mandatory_parameter: u16) void;
pub extern fn getUptimeMs() u32;
pub extern fn getFreeRamMemory() u32;
pub extern fn getFreeFlash() u32;

pub extern fn unitVectorCplx() void;
pub extern fn decQuadAdd(res: *real34_t, operand1: *const real34_t, operand2: *const real34_t, context: *realContext_t) *real34_t;
pub extern fn decQuadDivide(res: *real34_t, operand1: *const real34_t, operand2: *const real34_t, context: *realContext_t) *real34_t;
pub extern fn decQuadMultiply(res: *real34_t, operand1: *const real34_t, operand2: *const real34_t, context: *realContext_t) *real34_t;
pub extern fn decQuadIsNaN(value: *const real34_t) u32;
pub extern fn decQuadIsZero(value: *const real34_t) u32;
pub extern fn decQuadIsNegative(value: *const real34_t) u32;
pub extern fn internalDateToJulianDay(source: *real34_t, destination: *real34_t) void;
pub extern fn julianDayToInternalDate(source: *real34_t, destination: *real34_t) void;
pub extern fn real34ToIntegralValue(source: *const real34_t, destination: *real34_t, mode: rounding_t) void;
pub extern fn real34IsInfinite(value: *const real34_t) bool;
pub extern fn real34GetExponent(value: *const real34_t) i32;
pub extern fn real34NextPlus(source: *const real34_t, destination: *real34_t) void;
pub extern fn real34NextMinus(source: *const real34_t, destination: *real34_t) void;
pub extern fn realToReal34(source: *const real_t, destination: *real34_t) void;
pub extern fn real34Subtract(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) void;

pub inline fn real34Add(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) void {
    _ = decQuadAdd(res, operand1, operand2, &ctxtReal34);
}

pub inline fn real34Divide(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) void {
    _ = decQuadDivide(res, operand1, operand2, &ctxtReal34);
}

pub inline fn real34Multiply(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) void {
    _ = decQuadMultiply(res, operand1, operand2, &ctxtReal34);
}
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
pub extern fn WP34S_Logxy(numer: *const real_t, denom: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn sqrt1Px2Complex(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;
pub extern fn sqrtComplex(real: *const real_t, imag: *const real_t, res_real: *real_t, res_imag: *real_t, real_context: *realContext_t) void;
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
pub extern fn WP34S_intDivide(y: u64, x: u64) u64;
pub extern fn WP34S_intAdd(x: u64, y: u64) u64;
pub extern fn WP34S_intSubtract(x: u64, y: u64) u64;
pub extern fn WP34S_int2pow(x: u64) u64;
pub extern fn WP34S_int10pow(x: u64) u64;
pub extern fn WP34S_intLog10(x: u64) u64;
pub extern fn WP34S_intLog2(x: u64) u64;
pub extern fn WP34S_intAbs(x: u64) u64;
pub extern fn WP34S_intSqrt(x: u64) u64;
pub extern fn WP34S_intChs(x: u64) u64;
pub extern fn WP34S_build_value(x: u64, sign: i32) u64;
pub extern fn WP34S_extract_value(val: u64, sign: *i32) u64;
pub extern fn WP34S_Mod(x: *const real_t, y: *const real_t, res: *real_t, real_context: *realContext_t) void;
pub extern fn WP34S_BigMod(x: *const real_t, y: *const real_t, res: *real_t, real_context: *realContext_t) void;
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
pub extern fn __gmpz_init(op: *mpz_struct) void;
pub extern fn __gmpz_cmp_ui(lhs: *const mpz_struct, rhs: c_ulong) c_int;
pub extern fn __gmpz_tdiv_q_ui(result: *mpz_struct, op: *const mpz_struct, divisor: c_ulong) c_ulong;
pub extern fn __gmpz_get_ui(op: *const mpz_struct) c_ulong;
pub extern fn __gmpz_cmp(lhs: *const mpz_struct, rhs: *const mpz_struct) c_int;
pub extern fn __gmpz_set_si(op: *mpz_struct, value: c_long) void;
pub extern fn __gmpz_set_ui(op: *mpz_struct, value: c_ulong) void;
pub extern fn __gmpz_add(result: *mpz_struct, lhs: *const mpz_struct, rhs: *const mpz_struct) void;
pub extern fn __gmpz_add_ui(result: *mpz_struct, lhs: *const mpz_struct, rhs: c_ulong) void;
pub extern fn __gmpz_mul(result: *mpz_struct, lhs: *const mpz_struct, rhs: *const mpz_struct) void;
pub extern fn __gmpz_mul_2exp(result: *mpz_struct, lhs: *const mpz_struct, rhs: c_ulong) void;
pub extern fn __gmpz_sub(result: *mpz_struct, lhs: *const mpz_struct, rhs: *const mpz_struct) void;
pub extern fn __gmpz_sub_ui(result: *mpz_struct, lhs: *const mpz_struct, rhs: c_ulong) void;
pub extern fn __gmpz_mul_ui(result: *mpz_struct, lhs: *const mpz_struct, rhs: c_ulong) void;
pub extern fn __gmpz_gcd(result: *mpz_struct, lhs: *const mpz_struct, rhs: *const mpz_struct) void;
pub extern fn __gmpz_lcm(result: *mpz_struct, lhs: *const mpz_struct, rhs: *const mpz_struct) void;
pub extern fn __gmpz_tdiv_qr(quotient: *mpz_struct, remainder: *mpz_struct, dividend: *const mpz_struct, divisor: *const mpz_struct) void;
pub extern fn __gmpz_tdiv_r(result: *mpz_struct, dividend: *const mpz_struct, divisor: *const mpz_struct) void;
pub extern fn __gmpz_fdiv_q_ui(result: *mpz_struct, op: *const mpz_struct, divisor: c_ulong) c_ulong;
pub extern fn __gmpz_rootrem(root: *mpz_struct, rem: *mpz_struct, op: *const mpz_struct, n: c_ulong) void;
pub extern fn int32ToReal(source: i32, destination: *real_t) void;
pub extern fn decNumberCompare(result: *real_t, lhs: *const real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn decNumberFromString(result: *real_t, source: [*:0]const u8, real_context: *realContext_t) *real_t;
pub extern fn decNumberPlus(result: *real_t, rhs: *const real_t, real_context: *realContext_t) *real_t;
pub extern fn realToIntegralValue(source: *const real_t, destination: *real_t, mode: rounding_t, real_context: *realContext_t) void;
pub extern fn realCompareEqual(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareLessThan(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsEqual(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realCompareAbsGreaterThan(number1: *const real_t, number2: *const real_t) bool;
pub extern fn realIsAnInteger(x: *const real_t) bool;
pub extern fn real34IsAnInteger(value: *const real34_t) bool;
pub extern fn divRealComplex(
    numer: *const real_t,
    denom_real: *const real_t,
    denom_imag: *const real_t,
    quotient_real: *real_t,
    quotient_imag: *real_t,
    real_context: *realContext_t,
) void;
pub extern fn fnInvertMatrix(unused_but_mandatory_parameter: u16) void;
pub extern fn fnMatrixSquareRoot(unused_but_mandatory_parameter: u16) void;
pub extern fn realSetNaN(value: *real_t) void;
pub extern fn realSetZero(value: *real_t) void;
pub extern fn realSetOne(value: *real_t) void;
pub extern fn realPower(base: *const real_t, exponent: *const real_t, result: *real_t, real_context: *realContext_t) void;
pub extern fn PowerReal(base: *const real_t, exponent: *const real_t, result: *real_t, real_context: *realContext_t) void;
pub extern fn PowerComplex(base_real: *const real_t, base_imag: *const real_t, exponent_real: *const real_t, exponent_imag: *const real_t, result_real: *real_t, result_imag: *real_t, real_context: *realContext_t) u8;
pub extern fn convertRealToReal34ResultRegister(real: *const real_t, dest: calcRegister_t) void;
pub extern fn realToInt32C47(source: *const real_t, err: ?*bool) i32;

pub extern fn z47_math_wrappers_build_sign_result(result: i32) void;
pub extern fn z47_math_wrappers_change_sign_long_integer() void;
pub extern fn z47_math_wrappers_square_long_integer() void;
pub extern fn z47_math_wrappers_cube_long_integer() void;
pub extern fn z47_math_wrappers_long_integer_fibonacci(n: u32, result: *mpz_struct) void;
pub extern fn z47_math_wrappers_const_0() *const real_t;
pub extern fn z47_math_wrappers_const_1() *const real_t;
pub extern fn z47_math_wrappers_const_minus_1() *const real_t;
pub extern fn z47_math_wrappers_const_2() *const real_t;
pub extern fn z47_math_wrappers_const_3() *const real_t;
pub extern fn z47_math_wrappers_const_5() *const real_t;
pub extern fn z47_math_wrappers_const_100() *const real_t;
pub extern fn z47_math_wrappers_const_1on2() *const real_t;
pub extern fn z47_math_wrappers_const_1on3() *const real_t;
pub extern fn z47_math_wrappers_const_phi() *const real_t;
pub const legacy = struct {
    const legacy_prefix = "z47_math_" ++ "wrappers_" ++ "legacy_";
    const RetainedU16Fn = *const fn (u16) callconv(.c) void;

    const raw_fnBn: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnBn" });
    const raw_fnBnStar: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnBnStar" });
    const raw_fnExpt: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnExpt" });
    const raw_fnWpositive: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnWpositive" });
    const raw_fnWnegative: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnWnegative" });
    const raw_fnWinverse: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnWinverse" });
    const raw_fnGcd: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnGcd" });
    const raw_fnLcm: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnLcm" });
    const raw_fnMod: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnMod" });
    const raw_fnRmd: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnRmd" });
    const raw_fnUlp: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnUlp" });
    const raw_fnMant: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnMant" });
    const raw_fnRoundi: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnRoundi" });
    const raw_fnNeighb: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnNeighb" });
    const raw_fnIxyz: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnIxyz" });
    const raw_fnFactorial: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnFactorial" });
    const raw_fnRealPart: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnRealPart" });
    const raw_fnImaginaryPart: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnImaginaryPart" });
    const raw_fnArg: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnArg" });
    const raw_fnMagnitude: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnMagnitude" });
    const raw_fnConjugate: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnConjugate" });
    const raw_fnSwapRealImaginary: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnSwapRealImaginary" });
    const raw_fnAtan2: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnAtan2" });
    const raw_fnPercent: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnPercent" });
    const raw_fnAdd: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnAdd" });
    const raw_fnSubtract: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnSubtract" });
    const raw_fnMultiply: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnMultiply" });
    const raw_fnDivide: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDivide" });
    const raw_fnIDiv: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnIDiv" });
    const raw_fnIDivR: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnIDivR" });
    const raw_fnDblMultiply: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDblMultiply" });
    const raw_fnRound: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnRound" });
    const raw_fnDecomp: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDecomp" });
    const raw_fnCheckInteger: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckInteger" });
    const raw_fnDec: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDec" });
    const raw_fnInc: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnInc" });
    const legacy_fnXLessThan: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXLessThan" });
    const legacy_fnXLessEqual: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXLessEqual" });
    const legacy_fnXGreaterThan: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXGreaterThan" });
    const legacy_fnXGreaterEqual: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXGreaterEqual" });
    const legacy_fnXEqualsTo: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXEqualsTo" });
    const legacy_fnXNotEqual: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXNotEqual" });
    const legacy_fnXAlmostEqual: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnXAlmostEqual" });

    pub inline fn fnXLessThan(parameter: u16) void {
        legacy_fnXLessThan(parameter);
    }

    pub inline fn fnXLessEqual(parameter: u16) void {
        legacy_fnXLessEqual(parameter);
    }

    pub inline fn fnXGreaterThan(parameter: u16) void {
        legacy_fnXGreaterThan(parameter);
    }

    pub inline fn fnXGreaterEqual(parameter: u16) void {
        legacy_fnXGreaterEqual(parameter);
    }

    pub inline fn fnXEqualsTo(parameter: u16) void {
        legacy_fnXEqualsTo(parameter);
    }

    pub inline fn fnXNotEqual(parameter: u16) void {
        legacy_fnXNotEqual(parameter);
    }

    pub inline fn fnXAlmostEqual(parameter: u16) void {
        legacy_fnXAlmostEqual(parameter);
    }

    pub inline fn fnRound(parameter: u16) void {
        raw_fnRound(parameter);
    }

    pub inline fn fnAdd(parameter: u16) void {
        raw_fnAdd(parameter);
    }

    pub inline fn fnSubtract(parameter: u16) void {
        raw_fnSubtract(parameter);
    }

    pub inline fn fnMultiply(parameter: u16) void {
        raw_fnMultiply(parameter);
    }

    pub inline fn fnDivide(parameter: u16) void {
        raw_fnDivide(parameter);
    }

    pub inline fn fnIDiv(parameter: u16) void {
        raw_fnIDiv(parameter);
    }

    pub inline fn fnIDivR(parameter: u16) void {
        raw_fnIDivR(parameter);
    }

    pub inline fn fnDec(parameter: u16) void {
        raw_fnDec(parameter);
    }

    pub inline fn fnInc(parameter: u16) void {
        raw_fnInc(parameter);
    }




    pub inline fn fnDblMultiply(parameter: u16) void {
        raw_fnDblMultiply(parameter);
    }

    pub inline fn fnDblDivide(parameter: u16) void {
        raw_fnDblDivide(parameter);
    }

    pub inline fn fnDblDivideRemainder(parameter: u16) void {
        raw_fnDblDivideRemainder(parameter);
    }

    pub inline fn fnAtan2(parameter: u16) void {
        raw_fnAtan2(parameter);
    }
    const raw_fnIsConverged: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnIsConverged" });
    const raw_fnCheckType: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckType" });
    const raw_fnCheckReal: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckReal" });
    const raw_fnCheckNumber: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckNumber" });
    const raw_fnCheckAngle: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckAngle" });
    const raw_fnCheckMatrix: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckMatrix" });
    const raw_fnCheckMatrixSquare: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckMatrixSquare" });
    const raw_fnCheckForZero: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckForZero" });
    const raw_fnCheckIsVect2d: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckIsVect2d" });
    const raw_fnCheckIsVect3d: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckIsVect3d" });
    const raw_fnCheckNaN: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckNaN" });
    const raw_fnCheckInfinite: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckInfinite" });
    const raw_fnCheckSpecial: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckSpecial" });
    const raw_fnCheckPlusZero: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckPlusZero" });
    const raw_fnCheckMinusZero: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCheckMinusZero" });
    const raw_fnGetType: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnGetType" });
    const raw_fnDblDivide: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDblDivide" });
    const raw_fnDblDivideRemainder: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDblDivideRemainder" });
    const raw_fnPercentMRR: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnPercentMRR" });
    const raw_fnPercentPlusMG: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnPercentPlusMG" });
    const raw_fnPercentT: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnPercentT" });
    const raw_fnDeltaPercent: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDeltaPercent" });
    const raw_fnFib: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnFib" });
    const raw_fnLINPOL: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnLINPOL" });
    const raw_fnCross: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnCross" });
    const raw_fnDot: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnDot" });
    const raw_fnLogXY: RetainedU16Fn = @extern(RetainedU16Fn, .{ .name = legacy_prefix ++ "fnLogXY" });
};
pub extern fn z47_math_wrappers_const_2e6() *const real_t;
pub extern fn z47_math_wrappers_const_90() *const real_t;
pub extern fn z47_math_wrappers_const_180() *const real_t;
pub extern fn z47_math_wrappers_const_1oneE() *const real_t;
pub extern fn z47_math_wrappers_const_ln2() *const real_t;
pub extern fn z47_math_wrappers_const_ln10() *const real_t;
pub extern fn z47_math_wrappers_const_piOn4() *const real_t;
pub extern fn z47_math_wrappers_const_3piOn4() *const real_t;
pub extern fn z47_math_wrappers_const_piOn2() *const real_t;
pub extern fn z47_math_wrappers_const_3piOn2() *const real_t;
pub extern fn z47_math_wrappers_const_pi() *const real_t;
pub extern fn z47_math_wrappers_const75_piOn4() *const real_t;
pub extern fn z47_math_wrappers_const75_piOn2() *const real_t;
pub extern fn z47_math_wrappers_const75_pi() *const real_t;
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

// Extern surface for the Zig-owned addition/subtraction dispatch cells
// (math_addition_cells_owned.zig / math_subtraction_cells_owned.zig). These
// resolve against the C product surface still in the dispatch bridge or the
// frontier/state owners; the cell owners are excluded from the fake-harness
// parity lanes.
pub extern fn decQuadSubtract(res: *real34_t, operand1: *const real34_t, operand2: *const real34_t, context: *realContext_t) *real34_t;

pub inline fn real34SubtractMacro(operand1: *const real34_t, operand2: *const real34_t, res: *real34_t) void {
    _ = decQuadSubtract(res, operand1, operand2, &ctxtReal34);
}

pub extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn convertComplex34MatrixRegisterToComplex34Matrix(regist: calcRegister_t, matrix: *complex34Matrix_t) void;

pub const font_t = opaque {};
pub extern const standardFont: font_t;
pub extern const numericFont: font_t;
pub extern var tmpString: [*c]u8;
pub extern var roundingMode: u8;
pub extern const roundingModeTable: [7]rounding_t;
pub extern fn fnSwapXY(unused_but_mandatory_parameter: u16) void;
pub extern fn convertLongIntegerRegisterToTimeRegister(source: calcRegister_t, destination: calcRegister_t) void;
pub extern fn elementwiseRealRema(realf: VoidCallback) void;
pub extern fn elementwiseCxmaReal(cplxf: VoidCallback) void;
pub extern fn elementwiseRealCxma(cplxf: VoidCallback) void;
pub extern fn addRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) void;
pub extern fn subtractRealMatrices(y: *const real34Matrix_t, x: *const real34Matrix_t, res: *real34Matrix_t) void;
pub extern fn addComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) void;
pub extern fn subtractComplexMatrices(y: *const complex34Matrix_t, x: *const complex34Matrix_t, res: *complex34Matrix_t) void;
pub extern fn stringGlyphLength(str: [*c]const u8) i32;
pub extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
pub extern fn longIntegerRegisterToDisplayString(regist: calcRegister_t, display_string: [*c]u8, str_lg: i32, max_width: i16, max_exp: i16, allow_large_li: bool) void;
pub extern fn timeToDisplayString(regist: calcRegister_t, display_string: [*c]u8, ignore_t_disp: bool) void;
pub extern fn dateToDisplayString(regist: calcRegister_t, display_string: [*c]u8) void;
pub extern fn real34MatrixToDisplayString(regist: calcRegister_t, display_string: [*c]u8) void;
pub extern fn complex34MatrixToDisplayString(regist: calcRegister_t, display_string: [*c]u8) void;
pub extern fn shortIntegerToDisplayString(regist: calcRegister_t, display_string: [*c]u8, determine_font: bool, base_override: u8) void;
pub extern fn fractionToDisplayString(regist: calcRegister_t, display_string: [*c]u8) void;
pub extern fn real34ToDisplayString(real34: *align(1) const real34_t, tag: u32, display_string: [*c]u8, font: *const font_t, max_width: i16, display_has_n_digits: i16, limit_exponent: bool, front_space: bool, limit_irfrac: c_int) void;
pub extern fn complex34ToDisplayString(complex34: *align(1) const complex34_t, display_string: [*c]u8, font: *const font_t, max_width: i16, display_has_n_digits: i16, limit_exponent: bool, front_space: bool, limit_irfrac: c_int, tag_angle: u16, tag_polar: bool) void;

pub fn registerShortIntegerPtr(reg: calcRegister_t) *align(1) u64 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn setRegisterLongIntegerSign(reg: calcRegister_t, sign: u32) void {
    setRegisterTag(reg, sign);
}

pub const TI_PERC: u8 = 2;
pub const TI_PERCD: u8 = 3;

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

pub fn registerComplex34Ptr(reg: calcRegister_t) *align(1) complex34_t {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn registerMatrixHeaderPtr(reg: calcRegister_t) *align(1) matrixHeader_t {
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

pub fn getRegisterShortIntegerBase(reg: calcRegister_t) u32 {
    return getRegisterTag(reg);
}

pub fn getComplexRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & amAngleMask);
}

pub fn getComplexRegisterPolarMode(reg: calcRegister_t) angularMode_t {
    return @intCast(getRegisterTag(reg) & @as(u32, @intCast(amPolar)));
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

pub fn isRegisterMatrix3dVector(reg: calcRegister_t) bool {
    if (getRegisterDataType(reg) != dtReal34Matrix) {
        return false;
    }

    const header = registerMatrixHeaderPtr(reg);
    return (header.matrixRows == 1 and header.matrixColumns == 3) or (header.matrixRows == 3 and header.matrixColumns == 1);
}

pub fn isRegisterMatrix2dVector(reg: calcRegister_t) bool {
    if (getRegisterDataType(reg) != dtReal34Matrix) {
        return false;
    }

    const header = registerMatrixHeaderPtr(reg);
    return (header.matrixRows == 1 and header.matrixColumns == 2) or (header.matrixRows == 2 and header.matrixColumns == 1);
}

pub fn isRegisterMatrixVector(reg: calcRegister_t) bool {
    return isRegisterMatrix2dVector(reg) or isRegisterMatrix3dVector(reg);
}

pub fn getVectorRegisterAngularMode(reg: calcRegister_t) angularMode_t {
    return if (getRegisterDataType(reg) == dtReal34Matrix) @intCast(getRegisterTag(reg) & amAngleMask) else amNone;
}

pub fn setVectorRegisterAngularMode(reg: calcRegister_t, mode: angularMode_t) void {
    setRegisterTag(reg, (@as(u32, @intCast(mode)) & amAngleMask) | (getRegisterTag(reg) & @as(u32, @intCast(amPolar))));
}

pub fn getVectorRegisterPolarMode(reg: calcRegister_t) angularMode_t {
    if (getRegisterDataType(reg) != dtReal34Matrix or (getRegisterTag(reg) & amAngleMask) == @as(u32, @intCast(amNone))) {
        return amNone;
    }

    if (isRegisterMatrix3dVector(reg)) {
        return if ((getRegisterTag(reg) & @as(u32, @intCast(amPolar))) == @as(u32, @intCast(amPolar))) amPolarSPH else amPolarCYL;
    }

    if (isRegisterMatrix2dVector(reg)) {
        return @intCast(getRegisterTag(reg) & @as(u32, @intCast(amPolar)));
    }

    return amNone;
}

pub fn setVectorRegisterPolarMode(reg: calcRegister_t, mode: angularMode_t) void {
    const current_tag = getRegisterTag(reg);
    const next_tag: u32 = if (mode == amNone)
        (current_tag & ~(@as(u32, @intCast(amAngleMask | amPolar)))) + @as(u32, @intCast(amNone))
    else blk: {
        const with_polar = (current_tag & @as(u32, @intCast(amAngleMask | amPolar))) |
            (if (mode == amPolarSPH or mode == amPolar) @as(u32, @intCast(amPolar)) else 0);
        break :blk with_polar & (if (mode == amPolarCYL) ((~@as(u32, @intCast(amPolar))) & @as(u32, @intCast(amAngleMask | amPolar))) else 255);
    };

    setRegisterTag(reg, next_tag);
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

pub inline fn real34IsSpecial(value: *const real34_t) bool {
    return real34IsNaN(value) or real34IsInfinite(value);
}

pub inline fn real34IsZero(value: *const real34_t) bool {
    return decQuadIsZero(value) != 0;
}

pub inline fn real34IsNegative(value: *const real34_t) bool {
    return decQuadIsNegative(value) != 0;
}

pub inline fn real34ToReal(source: *const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
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
