pub const calcRegister_t = i16;

pub fn getRegisterShortIntegerBase(get_register_tag: anytype, regist: calcRegister_t) u32 {
    return get_register_tag(regist);
}

pub fn setRegisterShortIntegerBase(set_register_tag: anytype, regist: calcRegister_t, base: u32) void {
    set_register_tag(regist, base);
}