// _swapRegs' target resolution. stack.c holds the target in a uint16_t and
// tests only the UPPER bound of each band -- `regist < FIRST_NAMED_VARIABLE +
// numberOfNamedVariables` with no lower bound -- so a target in the 137..255 gap
// or the 2048..6999 label band takes the named or local arm with a negative
// index and swaps a header in front of the array. Refusing those two bands is
// the only difference here: every target the bands really contain resolves
// exactly as upstream resolves it, and no _swapRegs caller passes one of the
// gaps, so the refusal reports the same failure upstream's final else would.
const descriptor_storage = @import("register_descriptor_storage.zig");

pub const calcRegister_t = i16;
pub const register_descriptor_t = u32;
pub const LAST_GLOBAL_REGISTER: calcRegister_t = 136;

// The C compares the uint16_t target against int constants, so a target above
// 32767 is simply past every band; narrowing it to calcRegister_t first would
// trap on exactly those values.
const highest_addressable_target: u16 = 32767;

pub fn tryGetSwapTargetDescriptor(reg: u16, descriptor: *register_descriptor_t) bool {
    if (reg > highest_addressable_target) return false;
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
    if (reg > highest_addressable_target) return false;
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
