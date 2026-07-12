pub const calcRegister_t = i16;

pub fn registerShortIntegerPtr(get_register_data_pointer: anytype, regist: calcRegister_t) *align(1) u64 {
    const ptr = get_register_data_pointer(regist) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn setRawShortIntegerRegister(
    reallocate_register: anytype,
    get_register_data_pointer: anytype,
    dt_short_integer: u32,
    short_integer_size_in_blocks: u16,
    regist: calcRegister_t,
    base: u32,
    value: u64,
) void {
    reallocate_register(regist, dt_short_integer, short_integer_size_in_blocks, base);
    registerShortIntegerPtr(get_register_data_pointer, regist).* = value;
}
