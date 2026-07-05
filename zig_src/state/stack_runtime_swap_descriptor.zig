const descriptor_storage = @import("register_descriptor_storage.zig");

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;
pub const LAST_GLOBAL_REGISTER: calcRegister_t = 136;

pub fn tryGetSwapTargetDescriptor(reg: u16, descriptor: *register_descriptor_t) bool {
    const target_reg: calcRegister_t = @intCast(reg);

    if (target_reg <= LAST_GLOBAL_REGISTER) {
        descriptor.* = descriptor_storage.globalDescriptor(target_reg);
        return true;
    }

    if (descriptor_storage.tryGetNamedDescriptor(target_reg, descriptor)) {
        return true;
    }

    return descriptor_storage.tryGetLocalDescriptor(target_reg, descriptor);
}

pub fn trySetSwapTargetDescriptor(reg: u16, descriptor: register_descriptor_t) bool {
    const target_reg: calcRegister_t = @intCast(reg);

    if (target_reg <= LAST_GLOBAL_REGISTER) {
        descriptor_storage.setGlobalDescriptor(target_reg, descriptor);
        return true;
    }

    if (descriptor_storage.trySetNamedDescriptor(target_reg, descriptor)) {
        return true;
    }

    return descriptor_storage.trySetLocalDescriptor(target_reg, descriptor);
}