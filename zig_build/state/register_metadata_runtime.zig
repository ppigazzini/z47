const stack_runtime = @import("stack_runtime.zig");

pub const calcRegister_t = stack_runtime.calcRegister_t;
pub const register_descriptor_t = stack_runtime.register_descriptor_t;

pub const REGISTER_X = stack_runtime.REGISTER_X;
pub const LAST_GLOBAL_REGISTER = stack_runtime.LAST_GLOBAL_REGISTER;
pub const FIRST_NAMED_VARIABLE: calcRegister_t = 256;
pub const LAST_NAMED_VARIABLE: calcRegister_t = 1999;
pub const FIRST_RESERVED_VARIABLE: calcRegister_t = 2000;
pub const FIRST_NAMED_RESERVED_VARIABLE: calcRegister_t = 2026;
pub const LAST_RESERVED_VARIABLE: calcRegister_t = 2047;
pub const FIRST_LOCAL_REGISTER = stack_runtime.FIRST_LOCAL_REGISTER;
pub const LAST_LOCAL_REGISTER = stack_runtime.LAST_LOCAL_REGISTER;

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
extern fn z47_register_metadata_to_pc_mem_ptr(mem_ptr: u16) ?*anyopaque;
extern fn z47_register_metadata_to_c47_mem_ptr(mem_ptr: ?*const anyopaque) u16;
extern fn z47_registers_retained_getRegisterDataType(reg: calcRegister_t) u32;
extern fn z47_registers_retained_getRegisterDataPointer(reg: calcRegister_t) ?*anyopaque;
extern fn z47_registers_retained_getRegisterTag(reg: calcRegister_t) u32;
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

pub fn toPcMemPtr(mem_ptr: u16) ?*anyopaque {
    return z47_register_metadata_to_pc_mem_ptr(mem_ptr);
}

pub fn toC47MemPtr(mem_ptr: ?*const anyopaque) u16 {
    return z47_register_metadata_to_c47_mem_ptr(mem_ptr);
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

pub fn retainedSetRegisterDataType(reg: calcRegister_t, data_type: u16, tag: u32) void {
    z47_registers_retained_setRegisterDataType(reg, data_type, tag);
}

pub fn retainedSetRegisterDataPointer(reg: calcRegister_t, mem_ptr: ?*const anyopaque) void {
    z47_registers_retained_setRegisterDataPointer(reg, mem_ptr);
}

pub fn retainedSetRegisterTag(reg: calcRegister_t, tag: u32) void {
    z47_registers_retained_setRegisterTag(reg, tag);
}
