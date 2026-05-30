const build_options = @import("stack_state_build_options");
const descriptor_storage = @import("register_descriptor_storage_owned.zig");

const use_fake_stack_state_harness_surface =
    @hasDecl(build_options, "use_fake_stack_state_harness_surface") and
    build_options.use_fake_stack_state_harness_surface;

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_T: calcRegister_t = 103;
pub const REGISTER_A: calcRegister_t = 104;
pub const REGISTER_D: calcRegister_t = 107;
pub const REGISTER_I: calcRegister_t = 109;
pub const REGISTER_L: calcRegister_t = 108;
pub const REGISTER_W: calcRegister_t = 125;

pub const SAVED_REGISTER_X: calcRegister_t = 126;
pub const SAVED_REGISTER_L: calcRegister_t = 134;
pub const TEMP_REGISTER_2_SAVED_STATS: calcRegister_t = 136;
pub const LAST_GLOBAL_REGISTER: calcRegister_t = 136;

pub const FIRST_LOCAL_REGISTER: calcRegister_t = 7000;
pub const LAST_LOCAL_REGISTER: calcRegister_t = 7098;

pub const INVALID_VARIABLE: u16 = 2199;

pub const FLAG_SSIZE8: i32 = 0x8018;
pub const FLAG_ASLIFT: i32 = 0xc023;
pub const FLAG_INTING: i32 = 0xc025;
pub const FLAG_SOLVING: i32 = 0xc026;
pub const FLAG_SPCRES: i32 = 0x8017;

pub const ERR_REGISTER_LINE: calcRegister_t = REGISTER_Z;
pub const NIM_REGISTER_LINE: calcRegister_t = REGISTER_X;

pub const ERROR_NONE: u8 = 0;
pub const ERROR_OUT_OF_RANGE: u8 = 8;
pub const ERROR_RAM_FULL: u8 = 11;
pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;

pub const PGM_RUNNING: u8 = 1;
pub const NOT_CONFIRMED: u16 = 9878;
pub const ID_43S: u8 = 0;
pub const ID_DP: u8 = 2;
pub const ID_CPXDP: u8 = 4;
pub const ID_LI: u8 = 7;

pub const SIGMA_NONE: i8 = 0;
pub const SIGMA_PLUS: u16 = 1;
pub const SIGMA_MINUS: u16 = 2;

pub const dtLongInteger: u32 = 0;
pub const dtReal34: u32 = 1;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtDate: u32 = 4;
pub const dtString: u32 = 5;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;
pub const amNone: u32 = 5;
pub const amPolar: u32 = 16;
pub const FLAG_POLAR: i32 = 0x8006;
pub const LM_REGISTERS_PARTIAL: u16 = 6;
pub const manualLoad: u16 = 1;
const product_rounding_t = c_int;
const PRODUCT_DEC_ROUND_DOWN: product_rounding_t = 5;
const product_real_negative_bit: u8 = 0x80;

const ProductReal = extern struct {
    digits: i32,
    exponent: i32,
    bits: u8,
    lsu: [25]u16,
};

const ProductReal34 = extern struct {
    bytes: [16]u8,
};

const ProductRealContext = extern struct {
    digits: i32,
    emax: i32,
    emin: i32,
    round: product_rounding_t,
    traps: u32,
    status: u32,
    clamp: u8,
};

pub const real_t = if (use_fake_stack_state_harness_surface)
    extern struct {
        bytes: [8]u8,
    }
else
    extern struct {
        digits: i32,
        exponent: i32,
        bits: u8,
        lsu: [25]u16,
    };

pub const CM_AIM: u8 = 1;
pub const CM_NIM: u8 = 2;
pub const CM_MIM: u8 = 12;
pub const CM_NO_UNDO: u8 = 16;

pub const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]c_ulong,
};

const longIntegerValue_t = if (use_fake_stack_state_harness_surface) u32 else mpz_struct;

const FakeLongIntegerAbi = struct {
    extern fn longIntegerInit(value: *u32) void;
    extern fn uInt32ToLongInteger(source: u32, dest: *u32) void;
    extern fn longIntegerFree(value: *u32) void;
};

const ProdLongIntegerAbi = struct {
    extern fn __gmpz_clear(op: *mpz_struct) void;
    extern fn __gmpz_init(op: *mpz_struct) void;
    extern fn __gmpz_set_ui(op: *mpz_struct, value: c_ulong) void;
};

extern var ctxtReal39: ProductRealContext;
extern fn decimal128ToNumber(source: *const ProductReal34, destination: *ProductReal) *ProductReal;
extern fn decNumberFromUInt32(result: *ProductReal, rhs: u32) *ProductReal;
extern fn decNumberSubtract(result: *ProductReal, lhs: *const ProductReal, rhs: *const ProductReal, real_context: *ProductRealContext) *ProductReal;
extern fn realToIntegralValue(source: *const ProductReal, destination: *ProductReal, mode: product_rounding_t, real_context: *ProductRealContext) void;
extern fn realCompareAbsLessThan(number1: *const ProductReal, number2: *const ProductReal) bool;
extern fn realToInt32C47(source: *const ProductReal, err: ?*bool) i32;

pub const longInteger_t = [1]longIntegerValue_t;

extern fn z47_stack_runtime_get_stack_top() calcRegister_t;
extern fn z47_stack_runtime_real34_size_in_blocks() u16;
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
extern fn z47_stack_runtime_statistical_sums_blocks() u16;
extern fn z47_stack_runtime_statistical_sums_bytes() u32;
extern fn z47_stack_runtime_request_clear_registers_confirmation() void;
extern fn z47_stack_runtime_do_partial_register_load(s: u16, n: u16, d: u16) void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
extern fn convertRealToResultRegister(value: *const real_t, dest: calcRegister_t, angle: u32) void;
extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const longIntegerValue_t, regist: calcRegister_t) void;
extern fn convertLongIntegerToShortIntegerRegister(long_integer: *const longIntegerValue_t, base: u32, regist: calcRegister_t) void;
extern fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void;
extern fn fnClearRegisters(confirmation: u16) callconv(.c) void;
extern fn setConfirmationMode(handler: *const fn (confirmation: u16) callconv(.c) void) void;

pub extern fn clearRegister(reg: calcRegister_t) void;
pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn setSystemFlag(sf: u32) void;
pub extern fn flipSystemFlag(sf: u32) void;
pub extern fn allocC47Blocks(size_in_blocks: usize) ?*anyopaque;
pub extern fn freeC47Blocks(ptr: ?*anyopaque, size_in_blocks: usize) void;
pub extern fn getRegisterFullSizeInBlocks(reg: calcRegister_t) u16;
pub extern fn getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
pub extern fn setRegisterDataPointer(reg: calcRegister_t, mem_ptr: ?*const anyopaque) void;
pub extern fn getRegisterDataType(reg: calcRegister_t) u32;
pub extern fn getRegisterTag(reg: calcRegister_t) u32;
pub extern fn setRegisterDataType(reg: calcRegister_t, data_type: u16, tag: u32) void;
pub extern fn xcopy(dest: ?*anyopaque, source: ?*const anyopaque, n: u32) ?*anyopaque;
pub extern fn copySourceRegisterToDestRegister(source_register: calcRegister_t, dest_register: calcRegister_t) void;
pub extern fn fnRecall(reg: u16) void;
pub extern fn recallStatsMatrix() void;
pub extern fn fnSigmaAddRem(selection: u16) void;
pub extern fn reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn z47_registers_retained_get_reg_clr_range(s: *u16, n: *u16) u8;
pub extern fn z47_registers_retained_get_reg_swap_range(s: *u16, n: *u16, d: *u16) u8;
pub extern fn z47_registers_retained_get_reg_copy_params(f: *bool, s: *u16, n: *u16, d: *u16) u8;
pub extern fn z47_registers_retained_sort_reg(range_start: u16, range_end: u16) void;

pub extern var currentInputVariable: u16;
pub extern var displayStack: u8;
pub extern var calcMode: u8;
pub extern var thereIsSomethingToUndo: bool;
pub extern var lastErrorCode: u8;
pub extern var entryStatus: u8;
pub extern var programRunStop: u8;
pub extern var currentAngularMode: u32;
pub extern var lastIntegerBase: u32;
pub extern var Input_Default: u8;

pub extern var lrSelection: u16;
pub extern var lrSelectionUndo: u16;
pub extern var lrChosen: u16;
pub extern var lrChosenUndo: u16;

pub extern var systemFlags0: u64;
pub extern var systemFlags1: u64;
pub extern var savedSystemFlags0: u64;
pub extern var savedSystemFlags1: u64;

pub extern var SAVED_SIGMA_lastAddRem: i8;

pub extern var statisticalSumsPointer: ?*anyopaque;
pub extern var savedStatisticalSumsPointer: ?*anyopaque;
pub extern var SAVED_SIGMA_LASTX: real_t;
pub extern var SAVED_SIGMA_LASTY: real_t;

fn initUnsignedLongInteger(long_integer: *longInteger_t, value: u32) void {
    if (use_fake_stack_state_harness_surface) {
        FakeLongIntegerAbi.longIntegerInit(&long_integer[0]);
        FakeLongIntegerAbi.uInt32ToLongInteger(value, &long_integer[0]);
        return;
    }

    ProdLongIntegerAbi.__gmpz_init(&long_integer[0]);
    ProdLongIntegerAbi.__gmpz_set_ui(&long_integer[0], @intCast(value));
}

fn freeLongInteger(long_integer: *longInteger_t) void {
    if (use_fake_stack_state_harness_surface) {
        FakeLongIntegerAbi.longIntegerFree(&long_integer[0]);
        return;
    }

    ProdLongIntegerAbi.__gmpz_clear(&long_integer[0]);
}

fn registerReal34Ptr(reg: calcRegister_t) *align(1) ProductReal34 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

fn productReal34ToReal(source: *const ProductReal34, destination: *ProductReal) void {
    _ = decimal128ToNumber(source, destination);
}

fn productUInt32ToReal(source: u32, destination: *ProductReal) void {
    _ = decNumberFromUInt32(destination, source);
}

fn productRealIsNegative(value: *const ProductReal) bool {
    return (value.bits & product_real_negative_bit) != 0;
}

fn productRealSetPositiveSign(value: *ProductReal) void {
    value.bits &= 0x7f;
}

fn productRealSubtract(lhs: *const ProductReal, rhs: *const ProductReal, result: *ProductReal, real_context: *ProductRealContext) void {
    _ = decNumberSubtract(result, lhs, rhs, real_context);
}

fn rangeExceedsLimit(start: u16, count: u16, exclusive_upper_bound: u16) bool {
    return @as(u32, start) + @as(u32, count) >= @as(u32, exclusive_upper_bound);
}

fn resolveRegisterRange(start: u16, count: *u16, exclusive_upper_bound: u16) u8 {
    if (rangeExceedsLimit(start, count.*, exclusive_upper_bound)) {
        return ERROR_OUT_OF_RANGE;
    }

    if (count.* == 0) {
        count.* = exclusive_upper_bound - start;
    }

    return ERROR_NONE;
}

fn validateRegisterSourceRange(load_into_memory: ?bool, start: u16, count: *u16) u8 {
    const register_x: u16 = @intCast(REGISTER_X);
    const first_local_register: u16 = @intCast(FIRST_LOCAL_REGISTER);
    const local_limit = first_local_register + @as(u16, currentLocalRegisterCount());

    if (start < register_x) {
        return resolveRegisterRange(start, count, register_x);
    }

    if (start < first_local_register) {
        return resolveRegisterRange(start, count, first_local_register);
    }

    if (start < local_limit) {
        if (load_into_memory != null and load_into_memory.?) {
            return ERROR_OUT_OF_RANGE;
        }

        return resolveRegisterRange(start, count, local_limit);
    }

    return ERROR_OUT_OF_RANGE;
}

fn validateRegisterDestinationRange(start: u16, count: u16) u8 {
    const register_x: u16 = @intCast(REGISTER_X);
    const first_local_register: u16 = @intCast(FIRST_LOCAL_REGISTER);
    const local_limit = first_local_register + @as(u16, currentLocalRegisterCount());

    if (start < register_x) {
        return if (rangeExceedsLimit(start, count, register_x)) ERROR_OUT_OF_RANGE else ERROR_NONE;
    }

    if (start < first_local_register) {
        return if (rangeExceedsLimit(start, count, first_local_register)) ERROR_OUT_OF_RANGE else ERROR_NONE;
    }

    if (start < local_limit) {
        return if (rangeExceedsLimit(start, count, local_limit)) ERROR_OUT_OF_RANGE else ERROR_NONE;
    }

    return ERROR_OUT_OF_RANGE;
}

fn getRegParamProduct(load_into_memory: ?*bool, start: *u16, count: *u16, destination: ?*u16) u8 {
    var x: ProductReal = undefined;
    var integer_part: ProductReal = undefined;
    var thousand: ProductReal = undefined;

    if (getRegisterDataType(REGISTER_X) != dtReal34) {
        return ERROR_INVALID_DATA_TYPE_FOR_OP;
    }

    start.* = 0;
    count.* = 0;
    if (destination) |dest| {
        dest.* = 0;
    }

    productReal34ToReal(registerReal34Ptr(REGISTER_X), &x);
    productUInt32ToReal(1000, &thousand);
    if (!realCompareAbsLessThan(&x, &thousand)) {
        return ERROR_OUT_OF_RANGE;
    }

    if (load_into_memory) |load| {
        load.* = productRealIsNegative(&x);
    } else if (productRealIsNegative(&x)) {
        return ERROR_OUT_OF_RANGE;
    }
    productRealSetPositiveSign(&x);

    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, &ctxtReal39);
    start.* = @intCast(realToInt32C47(&integer_part, null));

    productRealSubtract(&x, &integer_part, &x, &ctxtReal39);
    x.exponent += 2;
    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, &ctxtReal39);
    count.* = @intCast(realToInt32C47(&integer_part, null));

    if (destination) |dest| {
        productRealSubtract(&x, &integer_part, &x, &ctxtReal39);
        x.exponent += 3;
        realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, &ctxtReal39);
        dest.* = @intCast(realToInt32C47(&integer_part, null));
    }

    const source_error = validateRegisterSourceRange(
        if (load_into_memory) |load| load.* else null,
        start.*,
        count,
    );
    if (source_error != ERROR_NONE) {
        return source_error;
    }

    if (destination) |dest| {
        return validateRegisterDestinationRange(dest.*, count.*);
    }

    return ERROR_NONE;
}

pub fn getStackTop() calcRegister_t {
    return z47_stack_runtime_get_stack_top();
}

pub fn real34SizeInBlocks() u16 {
    return z47_stack_runtime_real34_size_in_blocks();
}

pub fn tryFnToRealComplexZero() bool {
    return z47_stack_runtime_try_fn_to_real_complex_zero();
}

pub fn tryFnToRealReal34() bool {
    return z47_stack_runtime_try_fn_to_real_real34();
}

pub fn tryFnToRealLongInteger() bool {
    return z47_stack_runtime_try_fn_to_real_long_integer();
}

pub fn tryFnToRealShortInteger() bool {
    return z47_stack_runtime_try_fn_to_real_short_integer();
}

pub fn tryFnToRealTime() bool {
    return z47_stack_runtime_try_fn_to_real_time();
}

pub fn tryFnToRealDate() bool {
    return z47_stack_runtime_try_fn_to_real_date();
}

pub fn adjustResultSetCpxRes() void {
    z47_stack_runtime_adjust_result_set_cpxres();
}

pub fn adjustResultScalarCore(res: calcRegister_t) bool {
    return z47_stack_runtime_adjust_result_scalar_core(res);
}

pub fn adjustResultRealMatrixCore(res: calcRegister_t) bool {
    return z47_stack_runtime_adjust_result_real_matrix_core(res);
}

pub fn adjustResultComplexMatrixCore(res: calcRegister_t) bool {
    return z47_stack_runtime_adjust_result_complex_matrix_core(res);
}

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return descriptor_storage.globalDescriptor(reg);
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    descriptor_storage.setGlobalDescriptor(reg, descriptor);
}

pub fn tryGetSwapTargetDescriptor(reg: u16, descriptor: *register_descriptor_t) bool {
    const target_reg: calcRegister_t = @intCast(reg);

    if (target_reg <= LAST_GLOBAL_REGISTER) {
        descriptor.* = descriptor_storage.globalDescriptor(target_reg);
        return true;
    }

    if (descriptor_storage.tryGetNamedDescriptor(target_reg, descriptor)) {
        return true;
    }

    return descriptor_storage.tryGetLocalDescriptor(target_reg, descriptor);
}

pub fn trySetSwapTargetDescriptor(reg: u16, descriptor: register_descriptor_t) bool {
    const target_reg: calcRegister_t = @intCast(reg);

    if (target_reg <= LAST_GLOBAL_REGISTER) {
        descriptor_storage.setGlobalDescriptor(target_reg, descriptor);
        return true;
    }

    if (descriptor_storage.trySetNamedDescriptor(target_reg, descriptor)) {
        return true;
    }

    return descriptor_storage.trySetLocalDescriptor(target_reg, descriptor);
}

pub fn reportInvalidSwapTarget(reg: u16) void {
    _ = reg;
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, REGISTER_Z, REGISTER_X);
}

pub fn statisticalSumsBlocks() u16 {
    return z47_stack_runtime_statistical_sums_blocks();
}

pub fn statisticalSumsBytes() u32 {
    return z47_stack_runtime_statistical_sums_bytes();
}

pub fn storeStackSizeInX(size: u32) void {
    var stack: longInteger_t = undefined;
    initUnsignedLongInteger(&stack, size);
    defer freeLongInteger(&stack);

    convertLongIntegerToLongIntegerRegister(&stack[0], REGISTER_X);
}

pub fn storeLocalRegisterCountInX() void {
    var count: longInteger_t = undefined;
    initUnsignedLongInteger(&count, descriptor_storage.currentLocalRegisterCount());
    defer freeLongInteger(&count);

    convertLongIntegerToLongIntegerRegister(&count[0], REGISTER_X);
}

pub fn currentLocalRegisterCount() u8 {
    return descriptor_storage.currentLocalRegisterCount();
}

pub fn inputDefault() u8 {
    return Input_Default;
}

pub fn storeZeroLongInteger(reg: calcRegister_t) void {
    var long_integer: longInteger_t = undefined;
    initUnsignedLongInteger(&long_integer, 0);
    defer freeLongInteger(&long_integer);

    convertLongIntegerToLongIntegerRegister(&long_integer[0], reg);
}

pub fn storeZeroShortInteger(reg: calcRegister_t, base: u32) void {
    var long_integer: longInteger_t = undefined;
    initUnsignedLongInteger(&long_integer, 0);
    defer freeLongInteger(&long_integer);

    convertLongIntegerToShortIntegerRegister(&long_integer[0], base, reg);
}

pub fn requestClearRegistersConfirmation() void {
    if (use_fake_stack_state_harness_surface) {
        z47_stack_runtime_request_clear_registers_confirmation();
        return;
    }

    setConfirmationMode(&fnClearRegisters);
}

pub fn doPartialRegisterLoad(s: u16, n: u16, d: u16) void {
    if (use_fake_stack_state_harness_surface) {
        z47_stack_runtime_do_partial_register_load(s, n, d);
        return;
    }

    doLoad(LM_REGISTERS_PARTIAL, s, n, d, manualLoad);
}

pub fn sortRegisterRange(range_start: u16, range_end: u16) void {
    z47_registers_retained_sort_reg(range_start, range_end);
}

pub fn reportRegisterCommandError(error_code: u8) void {
    if (use_fake_stack_state_harness_surface) {
        displayCalcErrorMessage(error_code, REGISTER_X, REGISTER_X);
        return;
    }

    displayCalcErrorMessage(error_code, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

pub fn restoreSavedSigmaLastXYAndAdd() void {
    convertRealToResultRegister(&SAVED_SIGMA_LASTX, REGISTER_X, amNone);
    convertRealToResultRegister(&SAVED_SIGMA_LASTY, REGISTER_Y, amNone);
    fnSigmaAddRem(SIGMA_PLUS);
}

pub fn getRegClrRange(s: *u16, n: *u16) u8 {
    if (use_fake_stack_state_harness_surface) {
        return z47_registers_retained_get_reg_clr_range(s, n);
    }

    return getRegParamProduct(null, s, n, null);
}

pub fn getRegSwapRange(s: *u16, n: *u16, d: *u16) u8 {
    if (use_fake_stack_state_harness_surface) {
        return z47_registers_retained_get_reg_swap_range(s, n, d);
    }

    return getRegParamProduct(null, s, n, d);
}

pub fn getRegCopyParams(f: *bool, s: *u16, n: *u16, d: *u16) u8 {
    if (use_fake_stack_state_harness_surface) {
        return z47_registers_retained_get_reg_copy_params(f, s, n, d);
    }

    return getRegParamProduct(f, s, n, d);
}
