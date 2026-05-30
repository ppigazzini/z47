const mpz_struct = extern struct {
    _mp_alloc: c_int,
    _mp_size: c_int,
    _mp_d: [*c]c_ulong,
};

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

pub fn longIntegerValueType(comptime use_fake_stack_state_harness_surface: bool) type {
    return if (use_fake_stack_state_harness_surface) u32 else mpz_struct;
}

pub fn initUnsignedLongInteger(
    comptime use_fake_stack_state_harness_surface: bool,
    long_integer: anytype,
    value: u32,
) void {
    if (use_fake_stack_state_harness_surface) {
        FakeLongIntegerAbi.longIntegerInit(&long_integer[0]);
        FakeLongIntegerAbi.uInt32ToLongInteger(value, &long_integer[0]);
        return;
    }

    ProdLongIntegerAbi.__gmpz_init(&long_integer[0]);
    ProdLongIntegerAbi.__gmpz_set_ui(&long_integer[0], @intCast(value));
}

pub fn freeLongInteger(comptime use_fake_stack_state_harness_surface: bool, long_integer: anytype) void {
    if (use_fake_stack_state_harness_surface) {
        FakeLongIntegerAbi.longIntegerFree(&long_integer[0]);
        return;
    }

    ProdLongIntegerAbi.__gmpz_clear(&long_integer[0]);
}