const std = @import("std");

const build_options = @import("stack_state_build_options");
const mutation_owned = @import("stack_mutation.zig");
const memory_owned = @import("register_memory.zig");
const undo_owned = @import("stack_undo.zig");

const runtime = @import("stack_runtime.zig");
const use_fake_stack_state_harness_surface = @hasDecl(build_options, "use_fake_stack_state_harness_surface") and build_options.use_fake_stack_state_harness_surface;

const matrix_header_size_in_blocks: u16 = 1;
const amAngleMask: u32 = 15;
const amDMS: u32 = 3;
const FLAG_CPXRES: u16 = 0x8004;
const ERROR_OVERFLOW_PLUS_INF: u8 = 4;
const ERROR_OVERFLOW_MINUS_INF: u8 = 5;
const TI_FROM_DMS: u8 = 79;
const TI_FROM_HMS: u8 = 82;
const TI_FROM_DATEX: u8 = 84;

const abi = @import("abi"); // L1 shared bindings (REPORT-23 §5)
const real34_t = abi.Real34;

const complex34_t = abi.Complex34;

extern var significantDigits: u8;
extern var temporaryInformation: u8;

extern fn setRegisterTag(reg: runtime.calcRegister_t, tag: u32) void;
extern fn decQuadIsInfinite(value: *const real34_t) u32;
extern fn decQuadIsZero(value: *const real34_t) u32;
extern fn convertLongIntegerRegisterToReal34Register(source: runtime.calcRegister_t, destination: runtime.calcRegister_t) void;
extern fn convertShortIntegerRegisterToReal34Register(source: runtime.calcRegister_t, destination: runtime.calcRegister_t) void;
extern fn convertTimeRegisterToReal34Register(source: runtime.calcRegister_t, destination: runtime.calcRegister_t) void;
extern fn convertDateRegisterToReal34Register(source: runtime.calcRegister_t, destination: runtime.calcRegister_t) void;
extern fn setLastintegerBasetoZero() void;
extern fn checkTimeRange(time34: *const real34_t) void;
extern fn checkDateRange(date34: *const real34_t) void;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: runtime.calcRegister_t, err_register_line: runtime.calcRegister_t) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnRefreshState() void;
extern fn rsdReal(digits: u16) void;
extern fn rsdCplx(digits: u16) void;
extern fn rsdRema(digits: u16) void;
extern fn rsdCxma(digits: u16) void;

fn constOpaque(ptr: ?*anyopaque) ?*const anyopaque {
    return if (ptr) |value| @ptrCast(value) else null;
}

fn registerReal34Ptr(reg: runtime.calcRegister_t) *align(1) real34_t {
    const ptr = runtime.getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

fn registerImag34Ptr(reg: runtime.calcRegister_t) *align(1) real34_t {
    const ptr = runtime.getRegisterDataPointer(reg) orelse unreachable;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    return @ptrCast(bytes + @sizeOf(real34_t));
}

fn getRegisterAngularMode(reg: runtime.calcRegister_t) u32 {
    return runtime.getRegisterTag(reg) & amAngleMask;
}

fn setRegisterAngularMode(reg: runtime.calcRegister_t, mode: u32) void {
    setRegisterTag(reg, mode);
}

fn real34IsInfinite(value: *const real34_t) bool {
    return decQuadIsInfinite(value) != 0;
}

fn real34IsZero(value: *const real34_t) bool {
    return decQuadIsZero(value) != 0;
}

fn real34IsNegative(value: *const real34_t) bool {
    return (value.bytes[15] & 0x80) != 0;
}

fn real34SetPositiveSign(value: *real34_t) void {
    value.bytes[15] &= 0x7f;
}

fn setRegisterRaw(reg: runtime.calcRegister_t, data_type: u32, tag: u32, data_ptr: ?*anyopaque) void {
    runtime.setRegisterDataType(reg, @intCast(data_type), tag);
    runtime.setRegisterDataPointer(reg, constOpaque(data_ptr));
}

fn withRegisterMappedToX(res: runtime.calcRegister_t, rounder: *const fn (u16) callconv(.c) void) void {
    if (res == runtime.REGISTER_X) {
        rounder(significantDigits);
        return;
    }

    const x_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const x_tag = runtime.getRegisterTag(runtime.REGISTER_X);
    const x_ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X);

    const res_type = runtime.getRegisterDataType(res);
    const res_tag = runtime.getRegisterTag(res);
    const res_ptr = runtime.getRegisterDataPointer(res);

    setRegisterRaw(runtime.REGISTER_X, res_type, res_tag, res_ptr);
    setRegisterRaw(res, x_type, x_tag, x_ptr);
    rounder(significantDigits);

    const rounded_type = runtime.getRegisterDataType(runtime.REGISTER_X);
    const rounded_tag = runtime.getRegisterTag(runtime.REGISTER_X);
    const rounded_ptr = runtime.getRegisterDataPointer(runtime.REGISTER_X);

    setRegisterRaw(res, rounded_type, rounded_tag, rounded_ptr);
    setRegisterRaw(runtime.REGISTER_X, x_type, x_tag, x_ptr);
}

fn matrixPayloadOffsetBytes() usize {
    return @intCast(memory_owned.bytesFromBlocks(matrix_header_size_in_blocks));
}

fn complex34SizeInBlocks() u16 {
    return runtime.real34SizeInBlocks() * 2;
}

fn realMatrixElementsPtr(res: runtime.calcRegister_t) [*]align(1) real34_t {
    const ptr = runtime.getRegisterDataPointer(res) orelse unreachable;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    return @ptrCast(bytes + matrixPayloadOffsetBytes());
}

fn complexMatrixElementsPtr(res: runtime.calcRegister_t) [*]align(1) complex34_t {
    const ptr = runtime.getRegisterDataPointer(res) orelse unreachable;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    return @ptrCast(bytes + matrixPayloadOffsetBytes());
}

fn realMatrixElementCount(res: runtime.calcRegister_t) usize {
    const total_blocks: usize = @intCast(runtime.getRegisterFullSizeInBlocks(res));
    const element_blocks: usize = @intCast(runtime.real34SizeInBlocks());
    return (total_blocks - matrix_header_size_in_blocks) / element_blocks;
}

fn complexMatrixElementCount(res: runtime.calcRegister_t) usize {
    const total_blocks: usize = @intCast(runtime.getRegisterFullSizeInBlocks(res));
    const element_blocks: usize = @intCast(complex34SizeInBlocks());
    return (total_blocks - matrix_header_size_in_blocks) / element_blocks;
}

fn normalizeResultRealRegister(reg: runtime.calcRegister_t, value: *align(1) real34_t) void {
    if (real34IsInfinite(value)) {
        displayCalcErrorMessage(
            if (real34IsNegative(value)) ERROR_OVERFLOW_MINUS_INF else ERROR_OVERFLOW_PLUS_INF,
            runtime.REGISTER_Z,
            reg,
        );
    } else if (real34IsZero(value)) {
        real34SetPositiveSign(value);
    }
}

fn tryToRealComplexZero() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtComplex34) {
        return false;
    }

    if (!real34IsZero(registerImag34Ptr(runtime.REGISTER_X))) {
        return false;
    }

    const source_bytes: [*]align(1) const u8 = abi.registerBytes(runtime.REGISTER_X);
    var real_part: [@sizeOf(real34_t)]u8 = undefined;
    @memcpy(real_part[0..], source_bytes[0..real_part.len]);

    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);

    const dest_bytes: [*]align(1) u8 = abi.registerBytes(runtime.REGISTER_X);
    @memcpy(dest_bytes[0..real_part.len], real_part[0..]);
    return true;
}

fn tryToRealReal34() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtReal34) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    if (getRegisterAngularMode(runtime.REGISTER_X) != runtime.amNone) {
        if (getRegisterAngularMode(runtime.REGISTER_X) == amDMS) {
            temporaryInformation = TI_FROM_DMS;
        }
        setRegisterAngularMode(runtime.REGISTER_X, runtime.amNone);
    }

    return true;
}

fn tryToRealLongInteger() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtLongInteger) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertLongIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    return true;
}

fn tryToRealShortInteger() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtShortInteger) {
        return false;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertShortIntegerRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    setLastintegerBasetoZero();
    return true;
}

fn tryToRealTime() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtTime) {
        return false;
    }

    temporaryInformation = TI_FROM_HMS;
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertTimeRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    return true;
}

fn tryToRealDate() bool {
    if (runtime.getRegisterDataType(runtime.REGISTER_X) != runtime.dtDate) {
        return false;
    }

    temporaryInformation = TI_FROM_DATEX;
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    convertDateRegisterToReal34Register(runtime.REGISTER_X, runtime.REGISTER_X);
    return true;
}

fn reportToRealInvalidType() void {
    displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
}

fn adjustResultScalarCore(res: runtime.calcRegister_t) bool {
    const result_data_type = runtime.getRegisterDataType(res);

    if (result_data_type != runtime.dtReal34 and result_data_type != runtime.dtTime and result_data_type != runtime.dtDate and result_data_type != runtime.dtComplex34) {
        return false;
    }

    if (!runtime.getSystemFlag(runtime.FLAG_SPCRES) and runtime.lastErrorCode == runtime.ERROR_NONE) {
        switch (result_data_type) {
            runtime.dtReal34, runtime.dtTime, runtime.dtDate => normalizeResultRealRegister(res, registerReal34Ptr(res)),
            runtime.dtComplex34 => {
                normalizeResultRealRegister(res, registerReal34Ptr(res));
                normalizeResultRealRegister(res, registerImag34Ptr(res));
            },
            else => unreachable,
        }
    }

    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        if (result_data_type == runtime.dtTime) {
            checkTimeRange(registerReal34Ptr(res));
        }
        if (result_data_type == runtime.dtDate) {
            checkDateRange(registerReal34Ptr(res));
        }
    }

    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        undo_owned.undo();
        return true;
    }

    if (significantDigits != 0 and significantDigits < 34) {
        switch (result_data_type) {
            runtime.dtReal34 => withRegisterMappedToX(res, rsdReal),
            runtime.dtComplex34 => withRegisterMappedToX(res, rsdCplx),
            else => {},
        }
    }

    return true;
}

fn adjustResultRealMatrixCore(res: runtime.calcRegister_t) bool {
    if (runtime.getRegisterDataType(res) != runtime.dtReal34Matrix) {
        return false;
    }

    if (!runtime.getSystemFlag(runtime.FLAG_SPCRES) and runtime.lastErrorCode == runtime.ERROR_NONE) {
        const elements = realMatrixElementsPtr(res);
        for (0..realMatrixElementCount(res)) |index| {
            normalizeResultRealRegister(res, &elements[index]);
        }
    }

    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        undo_owned.undo();
        return true;
    }

    if (significantDigits != 0 and significantDigits < 34) {
        withRegisterMappedToX(res, rsdRema);
    }

    return true;
}

fn adjustResultComplexMatrixCore(res: runtime.calcRegister_t) bool {
    if (runtime.getRegisterDataType(res) != runtime.dtComplex34Matrix) {
        return false;
    }

    if (!runtime.getSystemFlag(runtime.FLAG_SPCRES) and runtime.lastErrorCode == runtime.ERROR_NONE) {
        const elements = complexMatrixElementsPtr(res);
        for (0..complexMatrixElementCount(res)) |index| {
            normalizeResultRealRegister(res, &elements[index].real);
            normalizeResultRealRegister(res, &elements[index].imag);
        }
    }

    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        undo_owned.undo();
        return true;
    }

    if (significantDigits != 0 and significantDigits < 34) {
        withRegisterMappedToX(res, rsdCxma);
    }

    return true;
}

fn adjustResultSetCpxRes() void {
    fnSetFlag(FLAG_CPXRES);
    fnRefreshState();
}

fn adjustResultArgumentIsComplex(reg: runtime.calcRegister_t) bool {
    if (reg < 0) {
        return false;
    }

    const data_type = runtime.getRegisterDataType(reg);
    return data_type == runtime.dtComplex34 or data_type == runtime.dtComplex34Matrix;
}

pub fn toReal(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;

    if (use_fake_stack_state_harness_surface) {
        if (runtime.tryFnToRealComplexZero()) {
            return;
        }

        if (runtime.tryFnToRealLongInteger()) {
            return;
        }

        if (runtime.tryFnToRealShortInteger()) {
            return;
        }

        if (runtime.tryFnToRealTime()) {
            return;
        }

        if (runtime.tryFnToRealDate()) {
            return;
        }

        if (runtime.tryFnToRealReal34()) {
            return;
        }

        reportToRealInvalidType();
        return;
    }

    if (tryToRealComplexZero()) {
        return;
    }

    if (tryToRealLongInteger()) {
        return;
    }

    if (tryToRealShortInteger()) {
        return;
    }

    if (tryToRealTime()) {
        return;
    }

    if (tryToRealDate()) {
        return;
    }

    if (tryToRealReal34()) {
        return;
    }

    reportToRealInvalidType();
}

pub fn adjustResult(
    res: runtime.calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: runtime.calcRegister_t,
    op2: runtime.calcRegister_t,
    op3: runtime.calcRegister_t,
) void {
    const one_argument_is_complex = adjustResultArgumentIsComplex(op1) or
        adjustResultArgumentIsComplex(op2) or
        adjustResultArgumentIsComplex(op3);

    if (use_fake_stack_state_harness_surface) {
        if (runtime.adjustResultScalarCore(res) or runtime.adjustResultRealMatrixCore(res) or runtime.adjustResultComplexMatrixCore(res)) {
            if (runtime.lastErrorCode != runtime.ERROR_NONE) {
                return;
            }
        } else if (runtime.lastErrorCode != runtime.ERROR_NONE) {
            undo_owned.undo();
            return;
        }

        if (set_cpx_res and one_argument_is_complex and runtime.getRegisterDataType(res) != runtime.dtString) {
            runtime.adjustResultSetCpxRes();
        }

        if (drop_y) {
            mutation_owned.dropY();
        }
        return;
    }

    if (adjustResultScalarCore(res) or adjustResultRealMatrixCore(res) or adjustResultComplexMatrixCore(res)) {
        if (runtime.lastErrorCode != runtime.ERROR_NONE) {
            return;
        }
    } else if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        undo_owned.undo();
        return;
    }

    if (set_cpx_res and one_argument_is_complex and runtime.getRegisterDataType(res) != runtime.dtString) {
        adjustResultSetCpxRes();
    }

    if (drop_y) {
        mutation_owned.dropY();
    }
}
