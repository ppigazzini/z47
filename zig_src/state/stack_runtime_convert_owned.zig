const build_options = @import("stack_state_build_options");
const runtime = @import("stack_runtime.zig");

const use_fake_stack_state_harness_surface =
    @hasDecl(build_options, "use_fake_stack_state_harness_surface") and
    build_options.use_fake_stack_state_harness_surface;

const calcRegister_t = runtime.calcRegister_t;
const real_t = runtime.real_t;

// A real34 value is a 16-byte decimal128 (decQuad). Byte 15 carries the sign
// bit, matching the upstream real34IsPositive / real34SetPositiveSign macros.
const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real34_t = abi.Real34;

const complex34_t = abi.Complex34;

// Upstream matrixHeader_t packs four bitfields into 32 bits, first field in the
// least-significant bits on the little-endian build target.
const matrixHeader_t = abi.MatrixHeader;

const real34Matrix_t = extern struct {
    header: matrixHeader_t,
    matrixElements: ?[*]real34_t,
};

const complex34Matrix_t = extern struct {
    header: matrixHeader_t,
    matrixElements: ?[*]complex34_t,
};

const amDMS: u32 = 3;
const amAngleMask: u32 = 15;
const TI_FROM_DMS: u8 = 79;
const TI_FROM_HMS: u8 = 82;
const TI_FROM_DATEX: u8 = 84;
const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
const FLAG_CPXRES: u16 = 0x8004;

extern fn getRegisterDataType(reg: calcRegister_t) u32;
extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
extern fn getRegisterTag(reg: calcRegister_t) u32;
extern fn setRegisterTag(reg: calcRegister_t, tag: u32) void;
extern fn copySourceRegisterToDestRegister(source_register: calcRegister_t, dest_register: calcRegister_t) void;
extern fn convertRealToResultRegister(value: *const real_t, dest: calcRegister_t, angle: u32) void;
extern fn convertRealToReal34ResultRegister(value: *const real_t, dest: calcRegister_t) void;
extern fn convertRealToImag34ResultRegister(value: *const real_t, dest: calcRegister_t) void;
extern fn convertLongIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertShortIntegerRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertTimeRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn convertDateRegisterToReal34Register(source: calcRegister_t, destination: calcRegister_t) void;
extern fn setLastintegerBasetoZero() void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn checkTimeRange(time34: *const real34_t) void;
extern fn checkDateRange(date34: *const real34_t) void;
extern fn getSystemFlag(sf: i32) bool;
extern fn undo() void;
extern fn rsdRema(digits: u16) void;
extern fn rsdCxma(digits: u16) void;
extern fn linkToRealMatrixRegister(regist: calcRegister_t, linked_matrix: *real34Matrix_t) void;
extern fn linkToComplexMatrixRegister(regist: calcRegister_t, linked_matrix: *complex34Matrix_t) void;
extern fn decQuadIsZero(source: *const real34_t) u32;
extern fn decQuadIsInfinite(source: *const real34_t) u32;
extern fn decimal128ToNumber(source: *const real34_t, destination: *real_t) *real_t;
extern fn fnSetFlag(flag: u16) void;
extern fn fnRefreshState() void;

extern var temporaryInformation: u8;
extern var significantDigits: u8;
extern var lastErrorCode: u8;

extern fn z47_stack_runtime_try_fn_to_real_complex_zero() bool;
extern fn z47_stack_runtime_try_fn_to_real_real34() bool;
extern fn z47_stack_runtime_try_fn_to_real_long_integer() bool;
extern fn z47_stack_runtime_try_fn_to_real_short_integer() bool;
extern fn z47_stack_runtime_try_fn_to_real_time() bool;
extern fn z47_stack_runtime_try_fn_to_real_date() bool;
extern fn z47_stack_runtime_adjust_result_scalar_core(res: calcRegister_t) bool;
extern fn z47_stack_runtime_adjust_result_real_matrix_core(res: calcRegister_t) bool;
extern fn z47_stack_runtime_adjust_result_complex_matrix_core(res: calcRegister_t) bool;
extern fn z47_stack_runtime_adjust_result_set_cpxres() void;

fn registerReal34(reg: calcRegister_t) *real34_t {
    return @ptrCast(getRegisterDataPointer(reg).?);
}

fn registerImag34(reg: calcRegister_t) *real34_t {
    const base: [*]u8 = @ptrCast(getRegisterDataPointer(reg).?);
    return @ptrCast(base + @sizeOf(real34_t));
}

fn real34ToReal(source: *const real34_t, destination: *real_t) void {
    _ = decimal128ToNumber(source, destination);
}

fn adjustRealRegister(reg: calcRegister_t, val: *real34_t) void {
    if (decQuadIsInfinite(val) != 0) {
        const code: u8 = if ((val.bytes[15] & 0x80) == 0) ERROR_OVERFLOW_PLUS_INF else ERROR_OVERFLOW_MINUS_INF;
        displayCalcErrorMessage(code, runtime.ERR_REGISTER_LINE, reg);
    } else if (decQuadIsZero(val) != 0) {
        val.bytes[15] &= 0x7F;
    }
}

pub fn tryFnToRealComplexZero() bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_try_fn_to_real_complex_zero();
    }

    if (getRegisterDataType(runtime.REGISTER_X) != runtime.dtComplex34) {
        return false;
    }
    if (decQuadIsZero(registerImag34(runtime.REGISTER_X)) == 0) {
        return false;
    }

    var real_part: real_t = undefined;
    real34ToReal(registerReal34(runtime.REGISTER_X), &real_part);
    convertRealToResultRegister(&real_part, runtime.REGISTER_X, runtime.amNone);
    return true;
}

pub fn tryFnToRealReal34() bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_try_fn_to_real_real34();
    }

    if (getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34) {
        return false;
    }

    copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    const angular_mode = getRegisterTag(runtime.REGISTER_X) & amAngleMask;
    if (angular_mode != runtime.amNone) {
        if (angular_mode == amDMS) {
            temporaryInformation = TI_FROM_DMS;
        }
        setRegisterTag(runtime.REGISTER_X, runtime.amNone);
    }
    return true;
}

pub fn tryFnToRealLongInteger() bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_try_fn_to_real_long_integer();
    }

    if (getRegisterDataType(runtime.REGISTER_X) != runtime.dtLongInteger) {
        return false;
    }

    copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    return true;
}

pub fn tryFnToRealShortInteger() bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_try_fn_to_real_short_integer();
    }

    if (getRegisterDataType(runtime.REGISTER_X) != runtime.dtShortInteger) {
        return false;
    }

    copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    setLastintegerBasetoZero();
    return true;
}

pub fn tryFnToRealTime() bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_try_fn_to_real_time();
    }

    if (getRegisterDataType(runtime.REGISTER_X) != runtime.dtTime) {
        return false;
    }

    temporaryInformation = TI_FROM_HMS;
    copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    return true;
}

pub fn tryFnToRealDate() bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_try_fn_to_real_date();
    }

    if (getRegisterDataType(runtime.REGISTER_X) != runtime.dtDate) {
        return false;
    }

    temporaryInformation = TI_FROM_DATEX;
    copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertDateRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    return true;
}

pub fn adjustResultScalarCore(res: calcRegister_t) bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_adjust_result_scalar_core(res);
    }

    const result_data_type = getRegisterDataType(res);
    if (result_data_type != runtime.dtReal34 and
        result_data_type != runtime.dtTime and
        result_data_type != runtime.dtDate and
        result_data_type != runtime.dtComplex34)
    {
        return false;
    }

    if (getSystemFlag(runtime.FLAG_SPCRES) == false and lastErrorCode == 0) {
        switch (result_data_type) {
            runtime.dtReal34, runtime.dtTime, runtime.dtDate => {
                adjustRealRegister(res, registerReal34(res));
            },
            runtime.dtComplex34 => {
                adjustRealRegister(res, registerReal34(res));
                adjustRealRegister(res, registerImag34(res));
            },
            else => {},
        }
    }

    if (lastErrorCode == 0) {
        if (result_data_type == runtime.dtTime) {
            checkTimeRange(registerReal34(res));
        }
        if (result_data_type == runtime.dtDate) {
            checkDateRange(registerReal34(res));
        }
    }

    if (lastErrorCode != 0) {
        undo();
        return true;
    }

    var tmp: real_t = undefined;
    switch (result_data_type) {
        runtime.dtReal34 => {
            if (significantDigits != 0 and significantDigits < 34) {
                real34ToReal(registerReal34(res), &tmp);
                convertRealToReal34ResultRegister(&tmp, res);
            }
        },
        runtime.dtComplex34 => {
            if (significantDigits != 0 and significantDigits < 34) {
                real34ToReal(registerReal34(res), &tmp);
                convertRealToReal34ResultRegister(&tmp, res);
                real34ToReal(registerImag34(res), &tmp);
                convertRealToImag34ResultRegister(&tmp, res);
            }
        },
        else => {},
    }

    return true;
}

pub fn adjustResultRealMatrixCore(res: calcRegister_t) bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_adjust_result_real_matrix_core(res);
    }

    if (getRegisterDataType(res) != runtime.dtReal34Matrix) {
        return false;
    }

    var matrix: real34Matrix_t = undefined;
    if (getSystemFlag(runtime.FLAG_SPCRES) == false and lastErrorCode == 0) {
        linkToRealMatrixRegister(res, &matrix);
        const count: u32 = @as(u32, matrix.header.matrixRows) * @as(u32, matrix.header.matrixColumns);
        const elements = matrix.matrixElements.?;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            adjustRealRegister(res, &elements[i]);
        }
    }

    if (lastErrorCode != 0) {
        undo();
        return true;
    }

    if (significantDigits != 0 and significantDigits < 34) {
        rsdRema(significantDigits);
    }

    return true;
}

pub fn adjustResultComplexMatrixCore(res: calcRegister_t) bool {
    if (use_fake_stack_state_harness_surface) {
        return z47_stack_runtime_adjust_result_complex_matrix_core(res);
    }

    if (getRegisterDataType(res) != runtime.dtComplex34Matrix) {
        return false;
    }

    var matrix: complex34Matrix_t = undefined;
    if (getSystemFlag(runtime.FLAG_SPCRES) == false and lastErrorCode == 0) {
        linkToComplexMatrixRegister(res, &matrix);
        const count: u32 = @as(u32, matrix.header.matrixRows) * @as(u32, matrix.header.matrixColumns);
        const elements = matrix.matrixElements.?;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            adjustRealRegister(res, &elements[i].re);
            adjustRealRegister(res, &elements[i].im);
        }
    }

    if (lastErrorCode != 0) {
        undo();
        return true;
    }

    if (significantDigits != 0 and significantDigits < 34) {
        rsdCxma(significantDigits);
    }

    return true;
}

pub fn adjustResultSetCpxRes() void {
    if (use_fake_stack_state_harness_surface) {
        z47_stack_runtime_adjust_result_set_cpxres();
        return;
    }

    fnSetFlag(FLAG_CPXRES);
    fnRefreshState();
}
