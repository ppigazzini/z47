const stack_runtime = @import("stack_runtime.zig");

pub const calcRegister_t = stack_runtime.calcRegister_t;
pub const register_descriptor_t = stack_runtime.register_descriptor_t;
pub const dtLongInteger = stack_runtime.dtLongInteger;
pub const dtReal34 = stack_runtime.dtReal34;
pub const amNone = stack_runtime.amNone;
pub const amPolar: u32 = 16;
pub const FLAG_POLAR: i32 = 0x8006;
pub const dtComplex34: u32 = 2;
pub const dtTime: u32 = 3;
pub const dtDate: u32 = 4;
pub const dtString: u32 = 5;
pub const dtReal34Matrix: u32 = 6;
pub const dtComplex34Matrix: u32 = 7;
pub const dtShortInteger: u32 = 8;
pub const dtConfig: u32 = 9;

pub const REGISTER_X = stack_runtime.REGISTER_X;
pub const LAST_GLOBAL_REGISTER = stack_runtime.LAST_GLOBAL_REGISTER;
pub const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
pub const LAST_NAMED_VARIABLE: calcRegister_t = 1999;
pub const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
pub const FIRST_NAMED_RESERVED_VARIABLE: calcRegister_t = 2026;
pub const LAST_RESERVED_VARIABLE: calcRegister_t = 2047;
pub const FIRST_LOCAL_REGISTER = stack_runtime.FIRST_LOCAL_REGISTER;
pub const LAST_LOCAL_REGISTER = stack_runtime.LAST_LOCAL_REGISTER;
pub const RESERVED_VARIABLE_ADM: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE;
pub const RESERVED_VARIABLE_DENMAX: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 1;
pub const RESERVED_VARIABLE_ISM: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 2;
pub const RESERVED_VARIABLE_REALDF: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 3;
pub const RESERVED_VARIABLE_NDEC: calcRegister_t = FIRST_NAMED_RESERVED_VARIABLE + 4;
pub const INVALID_VARIABLE: calcRegister_t = @intCast(stack_runtime.INVALID_VARIABLE);

pub const ITM_INPUT: u16 = 43;
pub const ITM_STO: u16 = 44;
pub const ITM_STOADD: u16 = 45;
pub const ITM_STOSUB: u16 = 46;
pub const ITM_STOMULT: u16 = 47;
pub const ITM_STODIV: u16 = 48;
pub const ITM_KEYQ: u16 = 77;
pub const ITM_MVAR: u16 = 1524;
pub const ITM_M_DIM: u16 = 1526;
pub const ITM_STOMAX: u16 = 1430;
pub const ITM_STOMIN: u16 = 1545;
pub const ITM_SOLVE: u16 = 1608;
pub const ITM_STOCFG: u16 = 1611;
pub const ITM_Tex: u16 = 1625;
pub const ITM_XtoALPHA: u16 = 1645;
pub const ITM_Xex: u16 = 127;
pub const ITM_Yex: u16 = 1650;
pub const ITM_Zex: u16 = 1651;
pub const ITM_INTEGRAL: u16 = 1700;

pub extern var currentAngularMode: u32;
pub extern var numberOfNamedVariables: u16;

extern fn z47_register_metadata_get_global_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_set_global_descriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void;
extern fn z47_register_metadata_try_get_named_descriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool;
extern fn z47_register_metadata_try_set_named_descriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool;
extern fn z47_register_metadata_get_named_descriptor_unchecked(index: u16) register_descriptor_t;
extern fn z47_register_metadata_set_named_descriptor_unchecked(index: u16, descriptor: register_descriptor_t) void;
extern fn z47_register_metadata_try_get_local_descriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool;
extern fn z47_register_metadata_try_set_local_descriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool;
extern fn z47_register_metadata_get_reserved_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_get_reserved_data_type_descriptor(reg: calcRegister_t) register_descriptor_t;
extern fn z47_register_metadata_reserved_allows_data_type_write(reg: calcRegister_t) bool;
extern fn z47_register_metadata_get_data_max_length_in_blocks(data_ptr: ?*const anyopaque) u16;
extern fn z47_register_metadata_set_data_max_length_in_blocks(data_ptr: ?*anyopaque, max_data_len: u16) void;
extern fn z47_register_metadata_get_matrix_payload_size_in_blocks(data_ptr: ?*const anyopaque, element_size_in_blocks: u16) u16;
extern fn z47_register_metadata_str_lg_int_header_size_in_blocks() u16;
extern fn z47_register_metadata_matrix_header_size_in_blocks() u16;
extern fn z47_register_metadata_complex34_size_in_blocks() u16;
extern fn z47_register_metadata_short_integer_size_in_blocks() u16;
extern fn z47_register_metadata_config_size_in_blocks() u16;
extern fn z47_register_metadata_memory_block_available(size_in_blocks: u16) bool;
extern fn z47_register_metadata_align_long_integer_blocks(size_in_blocks: u16) u16;
extern fn z47_register_metadata_initialize_matrix_header_1x1(data_ptr: ?*anyopaque) void;
extern fn z47_register_metadata_report_ram_full() void;
extern fn z47_register_metadata_to_pc_mem_ptr(mem_ptr: u16) ?*anyopaque;
extern fn z47_register_metadata_to_c47_mem_ptr(mem_ptr: ?*const anyopaque) u16;
extern fn z47_register_metadata_builtin_menu_item_count() u32;
extern fn z47_register_metadata_builtin_menu_item_is_menu(index: u32) bool;
extern fn z47_register_metadata_builtin_menu_item_name(index: u32) [*c]const u8;
extern fn z47_register_metadata_user_menu_count() u32;
extern fn z47_register_metadata_user_menu_name(index: u32) [*c]const u8;
extern fn z47_register_metadata_compare_menu_names(left: [*c]const u8, right: [*c]const u8) i32;
extern fn z47_register_metadata_find_reserved_variable_name(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t;
extern fn z47_register_metadata_report_invalid_name() void;
extern fn z47_register_metadata_report_undef_source_var() void;
extern fn z47_register_metadata_report_cannot_delete_predef_item() void;
extern fn z47_register_metadata_request_delete_all_variables_confirmation() void;
extern fn z47_registers_retained_getRegisterDataType(reg: calcRegister_t) u32;
extern fn z47_registers_retained_getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
extern fn z47_registers_retained_getRegisterTag(reg: calcRegister_t) u32;
extern fn z47_registers_retained_allocateNamedVariable(variable_name: [*c]const u8, data_type: u32, full_data_size_in_blocks: u16) void;
extern fn z47_registers_retained_fnDeleteVariable(regist: u16) void;
extern fn z47_registers_retained_fnDeleteAllVariables(confirmation: u16) void;
extern fn z47_registers_retained_copySourceRegisterToDestRegister(source_register: calcRegister_t, dest_register: calcRegister_t) void;
extern fn z47_registers_retained_reallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void;
extern fn z47_registers_retained_setRegisterMaxDataLengthInBlocks(reg: calcRegister_t, max_data_len: u16) void;
extern fn z47_registers_retained_getRegisterMaxDataLengthInBlocks(reg: calcRegister_t) u16;
extern fn z47_registers_retained_getRegisterFullSizeInBlocks(reg: calcRegister_t) u16;
extern fn z47_registers_retained_setRegisterDataType(reg: calcRegister_t, data_type: u16, tag: u32) void;
extern fn z47_registers_retained_setRegisterDataPointer(reg: calcRegister_t, mem_ptr: ?*const anyopaque) void;
extern fn z47_registers_retained_setRegisterTag(reg: calcRegister_t, tag: u32) void;

pub fn globalDescriptor(reg: calcRegister_t) register_descriptor_t {
    return z47_register_metadata_get_global_descriptor(reg);
}

pub fn setGlobalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) void {
    z47_register_metadata_set_global_descriptor(reg, descriptor);
}

pub fn tryGetNamedDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return z47_register_metadata_try_get_named_descriptor(reg, descriptor);
}

pub fn trySetNamedDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return z47_register_metadata_try_set_named_descriptor(reg, descriptor);
}

pub fn namedDescriptorUnchecked(index: u16) register_descriptor_t {
    return z47_register_metadata_get_named_descriptor_unchecked(index);
}

pub fn setNamedDescriptorUnchecked(index: u16, descriptor: register_descriptor_t) void {
    z47_register_metadata_set_named_descriptor_unchecked(index, descriptor);
}

pub fn tryGetLocalDescriptor(reg: calcRegister_t, descriptor: *register_descriptor_t) bool {
    return z47_register_metadata_try_get_local_descriptor(reg, descriptor);
}

pub fn trySetLocalDescriptor(reg: calcRegister_t, descriptor: register_descriptor_t) bool {
    return z47_register_metadata_try_set_local_descriptor(reg, descriptor);
}

pub fn reservedDescriptor(reg: calcRegister_t) register_descriptor_t {
    return z47_register_metadata_get_reserved_descriptor(reg);
}

pub fn reservedDataTypeDescriptor(reg: calcRegister_t) register_descriptor_t {
    return z47_register_metadata_get_reserved_data_type_descriptor(reg);
}

pub fn reservedAllowsDataTypeWrite(reg: calcRegister_t) bool {
    return z47_register_metadata_reserved_allows_data_type_write(reg);
}

pub fn dataMaxLengthInBlocks(data_ptr: ?*const anyopaque) u16 {
    return z47_register_metadata_get_data_max_length_in_blocks(data_ptr);
}

pub fn setDataMaxLengthInBlocks(data_ptr: ?*anyopaque, max_data_len: u16) void {
    z47_register_metadata_set_data_max_length_in_blocks(data_ptr, max_data_len);
}

pub fn matrixPayloadSizeInBlocks(data_ptr: ?*const anyopaque, element_size_in_blocks: u16) u16 {
    return z47_register_metadata_get_matrix_payload_size_in_blocks(data_ptr, element_size_in_blocks);
}

pub fn strLgIntHeaderSizeInBlocks() u16 {
    return z47_register_metadata_str_lg_int_header_size_in_blocks();
}

pub fn matrixHeaderSizeInBlocks() u16 {
    return z47_register_metadata_matrix_header_size_in_blocks();
}

pub fn real34SizeInBlocks() u16 {
    return stack_runtime.real34SizeInBlocks();
}

pub fn complex34SizeInBlocks() u16 {
    return z47_register_metadata_complex34_size_in_blocks();
}

pub fn shortIntegerSizeInBlocks() u16 {
    return z47_register_metadata_short_integer_size_in_blocks();
}

pub fn configSizeInBlocks() u16 {
    return z47_register_metadata_config_size_in_blocks();
}

pub fn memoryBlockAvailable(size_in_blocks: u16) bool {
    return z47_register_metadata_memory_block_available(size_in_blocks);
}

pub fn alignLongIntegerBlocks(size_in_blocks: u16) u16 {
    return z47_register_metadata_align_long_integer_blocks(size_in_blocks);
}

pub fn initializeMatrixHeader1x1(data_ptr: ?*anyopaque) void {
    z47_register_metadata_initialize_matrix_header_1x1(data_ptr);
}

pub fn reportRamFull() void {
    z47_register_metadata_report_ram_full();
}

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    return z47_register_metadata_to_pc_mem_ptr(mem_ptr);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    return z47_register_metadata_to_c47_mem_ptr(mem_ptr);
}

pub fn builtinMenuItemCount() u32 {
    return z47_register_metadata_builtin_menu_item_count();
}

pub fn builtinMenuItemIsMenu(index: u32) bool {
    return z47_register_metadata_builtin_menu_item_is_menu(index);
}

pub fn builtinMenuItemName(index: u32) [*c]const u8 {
    return z47_register_metadata_builtin_menu_item_name(index);
}

pub fn userMenuCount() u32 {
    return z47_register_metadata_user_menu_count();
}

pub fn userMenuName(index: u32) [*c]const u8 {
    return z47_register_metadata_user_menu_name(index);
}

pub fn compareMenuNames(left: [*c]const u8, right: [*c]const u8) i32 {
    return z47_register_metadata_compare_menu_names(left, right);
}

pub fn findReservedVariableName(variable_name: [*c]const u8, glyph_length: u8) calcRegister_t {
    return z47_register_metadata_find_reserved_variable_name(variable_name, glyph_length);
}

pub fn reportInvalidName() void {
    z47_register_metadata_report_invalid_name();
}

pub fn reportUndefSourceVar() void {
    z47_register_metadata_report_undef_source_var();
}

pub fn reportCannotDeletePredefItem() void {
    z47_register_metadata_report_cannot_delete_predef_item();
}

pub fn requestDeleteAllVariablesConfirmation() void {
    z47_register_metadata_request_delete_all_variables_confirmation();
}

pub fn retainedGetRegisterDataType(reg: calcRegister_t) u32 {
    return z47_registers_retained_getRegisterDataType(reg);
}

pub fn retainedGetRegisterDataPointer(reg: calcRegister_t) ?*anyopaque {
    return z47_registers_retained_getRegisterDataPointer(reg);
}

pub fn retainedGetRegisterTag(reg: calcRegister_t) u32 {
    return z47_registers_retained_getRegisterTag(reg);
}

pub fn retainedAllocateNamedVariable(variable_name: [*c]const u8, data_type: u32, full_data_size_in_blocks: u16) void {
    z47_registers_retained_allocateNamedVariable(variable_name, data_type, full_data_size_in_blocks);
}

pub fn retainedFnDeleteVariable(regist: u16) void {
    z47_registers_retained_fnDeleteVariable(regist);
}

pub fn retainedFnDeleteAllVariables(confirmation: u16) void {
    z47_registers_retained_fnDeleteAllVariables(confirmation);
}

pub fn retainedCopySourceRegisterToDestRegister(source_register: calcRegister_t, dest_register: calcRegister_t) void {
    z47_registers_retained_copySourceRegisterToDestRegister(source_register, dest_register);
}

pub fn retainedReallocateRegister(reg: calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    z47_registers_retained_reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}

pub fn retainedSetRegisterMaxDataLengthInBlocks(reg: calcRegister_t, max_data_len: u16) void {
    z47_registers_retained_setRegisterMaxDataLengthInBlocks(reg, max_data_len);
}

pub fn retainedGetRegisterMaxDataLengthInBlocks(reg: calcRegister_t) u16 {
    return z47_registers_retained_getRegisterMaxDataLengthInBlocks(reg);
}

pub fn retainedGetRegisterFullSizeInBlocks(reg: calcRegister_t) u16 {
    return z47_registers_retained_getRegisterFullSizeInBlocks(reg);
}

pub fn retainedSetRegisterDataType(reg: calcRegister_t, data_type: u16, tag: u32) void {
    z47_registers_retained_setRegisterDataType(reg, data_type, tag);
}

pub fn retainedSetRegisterDataPointer(reg: calcRegister_t, mem_ptr: ?*const anyopaque) void {
    z47_registers_retained_setRegisterDataPointer(reg, mem_ptr);
}

pub fn retainedSetRegisterTag(reg: calcRegister_t, tag: u32) void {
    z47_registers_retained_setRegisterTag(reg, tag);
}
