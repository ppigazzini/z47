pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;

pub const REGISTER_X: calcRegister_t = 100;
pub const REGISTER_Y: calcRegister_t = 101;
pub const REGISTER_Z: calcRegister_t = 102;
pub const REGISTER_T: calcRegister_t = 103;
pub const REGISTER_D: calcRegister_t = 107;
pub const REGISTER_L: calcRegister_t = 108;

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

pub const ERROR_NONE: u8 = 0;
pub const ERROR_OUT_OF_RANGE: u8 = 8;
pub const ERROR_RAM_FULL: u8 = 11;

pub const SIGMA_NONE: i8 = 0;
pub const SIGMA_PLUS: u16 = 1;
pub const SIGMA_MINUS: u16 = 2;

pub const dtLongInteger: u32 = 0;
pub const dtReal34: u32 = 1;
pub const amNone: u32 = 5;

pub const CM_AIM: u8 = 1;
pub const CM_NIM: u8 = 2;
pub const CM_MIM: u8 = 12;
pub const CM_NO_UNDO: u8 = 16;

extern fn z47_stack_runtime_get_stack_top() calcRegister_t;
extern fn z47_stack_runtime_real34_size_in_blocks() u16;
extern fn z47_stack_runtime_get_global_register_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_stack_runtime_set_global_register_descriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void;
extern fn z47_stack_runtime_get_swap_target_descriptor(reg: u16, descriptor: *register_descriptor_t) bool;
extern fn z47_stack_runtime_set_swap_target_descriptor(reg: u16, descriptor: register_descriptor_t) bool;
extern fn z47_stack_runtime_report_invalid_swap_target(reg: u16) void;
extern fn z47_stack_runtime_statistical_sums_blocks() u16;
extern fn z47_stack_runtime_statistical_sums_bytes() u32;
extern fn z47_stack_runtime_store_stack_size_in_x(size: u32) void;
extern fn z47_stack_runtime_restore_saved_sigma_last_xy_and_add() void;
extern fn z47_stack_runtime_real34_set_zero(dest: ?*anyopaque) void;

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

pub extern var currentInputVariable: u16;
pub extern var displayStack: u8;
pub extern var calcMode: u8;
pub extern var thereIsSomethingToUndo: bool;
pub extern var lastErrorCode: u8;
pub extern var entryStatus: u8;

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

pub fn getStackTop() calcRegister_t {
    return z47_stack_runtime_get_stack_top();
}

pub fn real34SizeInBlocks() u16 {
    return z47_stack_runtime_real34_size_in_blocks();
}

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return z47_stack_runtime_get_global_register_descriptor(reg);
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    z47_stack_runtime_set_global_register_descriptor(reg, descriptor);
}

pub fn tryGetSwapTargetDescriptor(reg: u16, descriptor: *register_descriptor_t) bool {
    return z47_stack_runtime_get_swap_target_descriptor(reg, descriptor);
}

pub fn trySetSwapTargetDescriptor(reg: u16, descriptor: register_descriptor_t) bool {
    return z47_stack_runtime_set_swap_target_descriptor(reg, descriptor);
}

pub fn reportInvalidSwapTarget(reg: u16) void {
    z47_stack_runtime_report_invalid_swap_target(reg);
}

pub fn statisticalSumsBlocks() u16 {
    return z47_stack_runtime_statistical_sums_blocks();
}

pub fn statisticalSumsBytes() u32 {
    return z47_stack_runtime_statistical_sums_bytes();
}

pub fn storeStackSizeInX(size: u32) void {
    z47_stack_runtime_store_stack_size_in_x(size);
}

pub fn restoreSavedSigmaLastXYAndAdd() void {
    z47_stack_runtime_restore_saved_sigma_last_xy_and_add();
}

pub fn real34SetZero(dest: ?*anyopaque) void {
    z47_stack_runtime_real34_set_zero(dest);
}

pub fn freeRegisterData(reg: calcRegister_t) void {
    freeC47Blocks(getRegisterDataPointer(reg), getRegisterFullSizeInBlocks(reg));
}

pub fn bytesFromBlocks(size_in_blocks: usize) u32 {
    return @intCast(size_in_blocks << 2);
}

pub fn xcopyBlocks(dest: ?*anyopaque, source: ?*anyopaque, size_in_blocks: usize) void {
    _ = xcopy(dest, source, bytesFromBlocks(size_in_blocks));
}

pub fn setRegisterDataPointerMutable(reg: calcRegister_t, mem_ptr: ?*anyopaque) void {
    setRegisterDataPointer(reg, mem_ptr);
}
