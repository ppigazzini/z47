const build_options = @import("stack_state_build_options");
const descriptor_storage = @import("register_descriptor_storage.zig");
const long_integer_owned = @import("stack_runtime_long_integer.zig");

const use_fake_stack_state_harness_surface =
    @hasDecl(build_options, "use_fake_stack_state_harness_surface") and
    build_options.use_fake_stack_state_harness_surface;

pub const calcRegister_t = i16;
pub const REGISTER_X: calcRegister_t = 100;

const longIntegerValue_t = long_integer_owned.longIntegerValueType(use_fake_stack_state_harness_surface);
const longInteger_t = [1]longIntegerValue_t;

extern fn convertLongIntegerToLongIntegerRegister(long_integer: *const longIntegerValue_t, regist: calcRegister_t) void;
extern fn convertLongIntegerToShortIntegerRegister(long_integer: *const longIntegerValue_t, base: u32, regist: calcRegister_t) void;

fn initUnsignedLongInteger(long_integer: *longInteger_t, value: u32) void {
    long_integer_owned.initUnsignedLongInteger(use_fake_stack_state_harness_surface, long_integer, value);
}

fn freeLongInteger(long_integer: *longInteger_t) void {
    long_integer_owned.freeLongInteger(use_fake_stack_state_harness_surface, long_integer);
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
