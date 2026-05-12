pub const calcRegister_t = i16;

pub const REGISTER_X: calcRegister_t = 100;
pub const ERR_REGISTER_LINE: calcRegister_t = 102;

pub const dtShortInteger: u32 = 8;
pub const SHORT_INTEGER_SIZE_IN_BLOCKS: u16 = 2;

pub const ERROR_WORD_SIZE_TOO_SMALL: u8 = 14;
pub const TI_FALSE: u8 = 12;

pub extern var shortIntegerWordSize: u8;
pub extern var shortIntegerMask: u64;
pub extern var thereIsSomethingToUndo: bool;
pub extern var temporaryInformation: u8;

pub extern fn getRegisterAsRawShortInt(reg: calcRegister_t, val: *u64, base: ?*u32) bool;
pub extern fn saveLastX() bool;
pub extern fn liftStack() void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
pub extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn getRegisterDataPointer(regist: calcRegister_t) ?*anyopaque;
pub extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: calcRegister_t) void;

pub fn registerShortIntegerPtr(regist: calcRegister_t) *align(1) u64 {
    const ptr = getRegisterDataPointer(regist) orelse unreachable;
    return @ptrCast(ptr);
}

pub fn setRawShortIntegerRegister(regist: calcRegister_t, base: u32, value: u64) void {
    reallocateRegister(regist, dtShortInteger, SHORT_INTEGER_SIZE_IN_BLOCKS, base);
    registerShortIntegerPtr(regist).* = value;
}

pub fn setTemporaryInformation(condition: bool) void {
    temporaryInformation = TI_FALSE + @as(u8, @intFromBool(condition));
}

pub fn wordSizeError() void {
    displayCalcErrorMessage(ERROR_WORD_SIZE_TOO_SMALL, ERR_REGISTER_LINE, REGISTER_X);
}