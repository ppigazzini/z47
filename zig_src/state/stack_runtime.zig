const build_options = @import("stack_state_build_options");
const command_control_owned = @import("stack_runtime_command_control_owned.zig");
const conversion_owned = @import("stack_runtime_conversion_owned.zig");
const descriptor_storage = @import("register_descriptor_storage_owned.zig");
const long_integer_owned = @import("stack_runtime_long_integer_owned.zig");
const product_real_owned = @import("stack_runtime_product_real_owned.zig");
const register_range_owned = @import("stack_runtime_register_range_owned.zig");
const swap_descriptor_owned = @import("stack_runtime_swap_descriptor_owned.zig");

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
const PRODUCT_DEC_ROUND_DOWN = product_real_owned.PRODUCT_DEC_ROUND_DOWN;
const product_rounding_t = product_real_owned.product_rounding_t;
const ProductReal = product_real_owned.ProductReal;
const ProductReal34 = product_real_owned.ProductReal34;
const ProductRealContext = product_real_owned.ProductRealContext;

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

const longIntegerValue_t = long_integer_owned.longIntegerValueType(use_fake_stack_state_harness_surface);

extern fn realToIntegralValue(source: *const ProductReal, destination: *ProductReal, mode: product_rounding_t, real_context: *ProductRealContext) void;
extern fn realCompareAbsLessThan(number1: *const ProductReal, number2: *const ProductReal) bool;
extern fn realToInt32C47(source: *const ProductReal, err: ?*bool) i32;

pub const longInteger_t = [1]longIntegerValue_t;

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
    long_integer_owned.initUnsignedLongInteger(use_fake_stack_state_harness_surface, long_integer, value);
}

fn freeLongInteger(long_integer: *longInteger_t) void {
    long_integer_owned.freeLongInteger(use_fake_stack_state_harness_surface, long_integer);
}

fn registerReal34Ptr(reg: calcRegister_t) *align(1) ProductReal34 {
    const ptr = getRegisterDataPointer(reg) orelse unreachable;
    return @ptrCast(ptr);
}

fn productReal34ToReal(source: *const ProductReal34, destination: *ProductReal) void {
    product_real_owned.productReal34ToReal(source, destination);
}

fn productUInt32ToReal(source: u32, destination: *ProductReal) void {
    product_real_owned.productUInt32ToReal(source, destination);
}

fn productRealIsNegative(value: *const ProductReal) bool {
    return product_real_owned.productRealIsNegative(value);
}

fn productRealSetPositiveSign(value: *ProductReal) void {
    product_real_owned.productRealSetPositiveSign(value);
}

fn productRealSubtract(lhs: *const ProductReal, rhs: *const ProductReal, result: *ProductReal, real_context: *ProductRealContext) void {
    product_real_owned.productRealSubtract(lhs, rhs, result, real_context);
}

fn validateRegisterSourceRange(load_into_memory: ?bool, start: u16, count: *u16) u8 {
    const register_x: u16 = @intCast(REGISTER_X);
    const first_local_register: u16 = @intCast(FIRST_LOCAL_REGISTER);
    return register_range_owned.validateRegisterSourceRange(
        load_into_memory,
        start,
        count,
        register_x,
        first_local_register,
        currentLocalRegisterCount(),
        ERROR_OUT_OF_RANGE,
        ERROR_NONE,
    );
}

fn validateRegisterDestinationRange(start: u16, count: u16) u8 {
    const register_x: u16 = @intCast(REGISTER_X);
    const first_local_register: u16 = @intCast(FIRST_LOCAL_REGISTER);
    return register_range_owned.validateRegisterDestinationRange(
        start,
        count,
        register_x,
        first_local_register,
        currentLocalRegisterCount(),
        ERROR_OUT_OF_RANGE,
        ERROR_NONE,
    );
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

    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
    start.* = @intCast(realToInt32C47(&integer_part, null));

    productRealSubtract(&x, &integer_part, &x, product_real_owned.realContext39());
    x.exponent += 2;
    realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
    count.* = @intCast(realToInt32C47(&integer_part, null));

    if (destination) |dest| {
        productRealSubtract(&x, &integer_part, &x, product_real_owned.realContext39());
        x.exponent += 3;
        realToIntegralValue(&x, &integer_part, PRODUCT_DEC_ROUND_DOWN, product_real_owned.realContext39());
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
    return conversion_owned.getStackTop();
}

pub fn real34SizeInBlocks() u16 {
    return conversion_owned.real34SizeInBlocks();
}

pub fn tryFnToRealComplexZero() bool {
    return conversion_owned.tryFnToRealComplexZero();
}

pub fn tryFnToRealReal34() bool {
    return conversion_owned.tryFnToRealReal34();
}

pub fn tryFnToRealLongInteger() bool {
    return conversion_owned.tryFnToRealLongInteger();
}

pub fn tryFnToRealShortInteger() bool {
    return conversion_owned.tryFnToRealShortInteger();
}

pub fn tryFnToRealTime() bool {
    return conversion_owned.tryFnToRealTime();
}

pub fn tryFnToRealDate() bool {
    return conversion_owned.tryFnToRealDate();
}

pub fn adjustResultSetCpxRes() void {
    conversion_owned.adjustResultSetCpxRes();
}

pub fn adjustResultScalarCore(res: calcRegister_t) bool {
    return conversion_owned.adjustResultScalarCore(res);
}

pub fn adjustResultRealMatrixCore(res: calcRegister_t) bool {
    return conversion_owned.adjustResultRealMatrixCore(res);
}

pub fn adjustResultComplexMatrixCore(res: calcRegister_t) bool {
    return conversion_owned.adjustResultComplexMatrixCore(res);
}

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return descriptor_storage.globalDescriptor(reg);
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    descriptor_storage.setGlobalDescriptor(reg, descriptor);
}

pub fn tryGetSwapTargetDescriptor(reg: u16, descriptor: *register_descriptor_t) bool {
    return swap_descriptor_owned.tryGetSwapTargetDescriptor(reg, descriptor);
}

pub fn trySetSwapTargetDescriptor(reg: u16, descriptor: register_descriptor_t) bool {
    return swap_descriptor_owned.trySetSwapTargetDescriptor(reg, descriptor);
}

pub fn reportInvalidSwapTarget(reg: u16) void {
    _ = reg;
    displayCalcErrorMessage(ERROR_OUT_OF_RANGE, REGISTER_Z, REGISTER_X);
}

pub fn statisticalSumsBlocks() u16 {
    return conversion_owned.statisticalSumsBlocks();
}

pub fn statisticalSumsBytes() u32 {
    return conversion_owned.statisticalSumsBytes();
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
    command_control_owned.requestClearRegistersConfirmation();
}

pub fn doPartialRegisterLoad(s: u16, n: u16, d: u16) void {
    command_control_owned.doPartialRegisterLoad(s, n, d);
}

pub fn sortRegisterRange(range_start: u16, range_end: u16) void {
    command_control_owned.sortRegisterRange(range_start, range_end);
}

pub fn reportRegisterCommandError(error_code: u8) void {
    command_control_owned.reportRegisterCommandError(error_code);
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
