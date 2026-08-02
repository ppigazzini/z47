pub const calcRegister_t = i16;

pub fn setTemporaryInformation(temporary_information: *u8, ti_false: u8, condition: bool) void {
    temporary_information.* = ti_false + @as(u8, @intFromBool(condition));
}

pub fn invalidShortIntegerError(
    display_error: anytype,
    error_invalid_data_type_for_op: u8,
    err_register_line: calcRegister_t,
    regist: calcRegister_t,
) void {
    display_error(error_invalid_data_type_for_op, err_register_line, regist);
}

pub fn wordSizeError(
    display_error: anytype,
    error_word_size_too_small: u8,
    err_register_line: calcRegister_t,
    register_x: calcRegister_t,
) void {
    display_error(error_word_size_too_small, err_register_line, register_x);
}
