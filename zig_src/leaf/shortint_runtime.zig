pub const calcRegister_t = i16;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_L: calcRegister_t = 108;
pub const ERR_REGISTER_LINE: calcRegister_t = 102;

pub const dtLongInteger: u32 = 0;
pub const dtShortInteger: u32 = 8;
pub const SHORT_INTEGER_SIZE_IN_BLOCKS: u16 = 2;

pub const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
pub const ERROR_WORD_SIZE_TOO_SMALL: u8 = 14;
pub const TI_FALSE: u8 = 12;

pub const FLAG_CARRY: u32 = 0x800b;
pub const FLAG_ASLIFT: u32 = 0xc023;

pub extern var shortIntegerWordSize: u8;
pub extern var shortIntegerMask: u64;
pub extern var shortIntegerSignBit: u64;
pub extern var thereIsSomethingToUndo: bool;
pub extern var temporaryInformation: u8;

pub extern fn getRegisterAsRawShortInt(reg: calcRegister_t, val: *u64, base: ?*u32) bool;
pub extern fn saveLastX() bool;
pub extern fn liftStack() void;
pub extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: calcRegister_t, err_register_line: calcRegister_t) void;
pub extern fn reallocateRegister(regist: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
pub extern fn getRegisterDataPointer(regist: calcRegister_t) ?*anyopaque;
pub extern fn getSystemFlag(sf: i32) bool;
pub extern fn setSystemFlag(sf: u32) void;
pub extern fn forceSystemFlag(sf: u32, set: c_int) void;
pub extern fn fnSetWordSize(ws: u16) void;
pub extern fn adjustResult(
    res: calcRegister_t,
    drop_y: bool,
    set_cpx_res: bool,
    op1: calcRegister_t,
    op2: calcRegister_t,
    op3: calcRegister_t,
) void;
pub extern fn convertUInt64ToShortIntegerRegister(sign: i16, value: u64, base: u32, regist: calcRegister_t) void;
pub extern fn convertShortIntegerRegisterToLongIntegerRegister(source: calcRegister_t, destination: calcRegister_t) void;

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

pub fn invalidShortIntegerError(regist: calcRegister_t) void {
    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, regist);
}

pub fn wordSizeError() void {
    displayCalcErrorMessage(ERROR_WORD_SIZE_TOO_SMALL, ERR_REGISTER_LINE, REGISTER_X);
}
