const descriptor_owned = @import("register_metadata_descriptor_owned.zig");
const payload_owned = @import("register_metadata_payload_owned.zig");
const reallocate_owned = @import("register_metadata_reallocate_owned.zig");
const variables_owned = @import("register_metadata_variables_owned.zig");
const runtime = @import("register_metadata_runtime.zig");

pub export fn setRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t, max_data_len: u16) void {
    payload_owned.setRegisterMaxDataLengthInBlocks(reg, max_data_len);
}

pub export fn getRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t) u16 {
    return payload_owned.getRegisterMaxDataLengthInBlocks(reg);
}

pub export fn getRegisterFullSizeInBlocks(reg: runtime.calcRegister_t) u16 {
    return payload_owned.getRegisterFullSizeInBlocks(reg);
}

pub export fn copySourceRegisterToDestRegister(source_register: runtime.calcRegister_t, dest_register: runtime.calcRegister_t) void {
    reallocate_owned.copySourceRegisterToDestRegister(source_register, dest_register);
}

pub export fn reallocateRegister(reg: runtime.calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    reallocate_owned.reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}

pub export fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void {
    runtime.allocateLocalRegistersRetained(number_of_registers_to_allocate);
}

pub export fn validateName(name: [*c]const u8) bool {
    return variables_owned.validateName(name);
}

pub export fn isUniqueMenuName(name: [*c]const u8) bool {
    return variables_owned.isUniqueMenuName(name);
}

pub export fn allocateNamedVariable(variable_name: [*c]const u8, data_type: u32, full_data_size_in_blocks: u16) void {
    variables_owned.allocateNamedVariable(variable_name, data_type, full_data_size_in_blocks);
}

pub export fn fnDeleteVariable(regist: u16) void {
    variables_owned.deleteVariable(regist);
}

pub export fn fnDeleteAllVariables(confirmation: u16) void {
    variables_owned.deleteAllVariables(confirmation);
}

pub export fn fnClearAllVariables(confirmation: u16) void {
    variables_owned.clearAllVariables(confirmation);
}

pub export fn findNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    return variables_owned.findNamedVariable(variable_name);
}

pub export fn findOrAllocateNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    return variables_owned.findOrAllocateNamedVariable(variable_name);
}

pub export fn isFunctionAllowingNewVariable(op: u16) bool {
    return variables_owned.isFunctionAllowingNewVariable(op);
}

pub export fn getRegisterDataType(reg: runtime.calcRegister_t) u32 {
    return descriptor_owned.getRegisterDataType(reg);
}

pub export fn getRegisterDataPointer(reg: runtime.calcRegister_t) ?*anyopaque {
    return descriptor_owned.getRegisterDataPointer(reg);
}

pub export fn getRegisterTag(reg: runtime.calcRegister_t) u32 {
    return descriptor_owned.getRegisterTag(reg);
}

pub export fn setRegisterDataType(reg: runtime.calcRegister_t, data_type: u16, tag: u32) void {
    descriptor_owned.setRegisterDataType(reg, data_type, tag);
}

pub export fn setRegisterDataPointer(reg: runtime.calcRegister_t, mem_ptr: ?*const anyopaque) void {
    descriptor_owned.setRegisterDataPointer(reg, mem_ptr);
}

pub export fn setRegisterTag(reg: runtime.calcRegister_t, tag: u32) void {
    descriptor_owned.setRegisterTag(reg, tag);
}
