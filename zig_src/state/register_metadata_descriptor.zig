const runtime = @import("register_metadata_runtime.zig");
const stack_runtime = @import("stack_runtime.zig");

const pointer_mask: runtime.register_descriptor_t = 0x0000ffff;
const data_type_mask: runtime.register_descriptor_t = 0x000f0000;
const tag_mask: runtime.register_descriptor_t = 0x01f00000;
const data_type_shift: u5 = 16;
const tag_shift: u5 = 20;
const invalid_data_type: u32 = 31;

fn descriptorDataType(descriptor: runtime.register_descriptor_t) u32 {
    return (descriptor & data_type_mask) >> data_type_shift;
}

fn descriptorTag(descriptor: runtime.register_descriptor_t) u32 {
    return (descriptor & tag_mask) >> tag_shift;
}

fn descriptorPointer(descriptor: runtime.register_descriptor_t) u16 {
    return @intCast(descriptor & pointer_mask);
}

fn withDataTypeTag(descriptor: runtime.register_descriptor_t, data_type: u16, tag: u32) runtime.register_descriptor_t {
    return (descriptor & ~(data_type_mask | tag_mask)) |
        ((@as(runtime.register_descriptor_t, data_type) & 0xf) << data_type_shift) |
        ((tag & 0x1f) << tag_shift);
}

fn withTag(descriptor: runtime.register_descriptor_t, tag: u32) runtime.register_descriptor_t {
    return (descriptor & ~tag_mask) | ((tag & 0x1f) << tag_shift);
}

fn withPointer(descriptor: runtime.register_descriptor_t, mem_ptr: u16) runtime.register_descriptor_t {
    return (descriptor & ~pointer_mask) | @as(runtime.register_descriptor_t, mem_ptr);
}

pub fn dataPointerFromDescriptor(descriptor: runtime.register_descriptor_t) ?*anyopaque {
    return runtime.toPcMemPtr(descriptorPointer(descriptor));
}

pub fn getRegisterDataType(reg: runtime.calcRegister_t) u32 {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return descriptorDataType(runtime.globalDescriptor(reg));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return descriptorDataType(descriptor);
        }

        if (runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        }

        return invalid_data_type;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return descriptorDataType(runtime.reservedDataTypeDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return descriptorDataType(descriptor);
        }
        return invalid_data_type;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
    return invalid_data_type;
}

pub fn getRegisterDataPointer(reg: runtime.calcRegister_t) ?*anyopaque {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return dataPointerFromDescriptor(runtime.globalDescriptor(reg));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return dataPointerFromDescriptor(descriptor);
        }

        if (runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        }

        return null;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return dataPointerFromDescriptor(descriptor);
        }

        return null;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
    return null;
}

pub fn getRegisterTag(reg: runtime.calcRegister_t) u32 {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return descriptorTag(runtime.globalDescriptor(reg));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return descriptorTag(descriptor);
        }

        if (runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        }

        return 0;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return descriptorTag(runtime.reservedDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return descriptorTag(descriptor);
        }

        return 0;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
    return 0;
}

pub fn setRegisterDataType(reg: runtime.calcRegister_t, data_type: u16, tag: u32) void {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        runtime.setGlobalDescriptor(reg, withDataTypeTag(runtime.globalDescriptor(reg), data_type, tag));
        return;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            _ = runtime.trySetNamedDescriptor(reg, withDataTypeTag(descriptor, data_type, tag));
            return;
        }

        if (runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        }

        return;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        if (runtime.reservedAllowsDataTypeWrite(reg)) {
            const index: u16 = @intCast(reg - runtime.FIRST_RESERVED_VARIABLE);
            descriptor = runtime.namedDescriptorUnchecked(index);
            runtime.setNamedDescriptorUnchecked(index, withDataTypeTag(descriptor, data_type, tag));
        }
        return;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            _ = runtime.trySetLocalDescriptor(reg, withDataTypeTag(descriptor, data_type, tag));
            return;
        }

        return;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
}

pub fn setRegisterDataPointer(reg: runtime.calcRegister_t, mem_ptr: ?*const anyopaque) void {
    var descriptor: runtime.register_descriptor_t = 0;
    const encoded = runtime.toC47MemPtr(mem_ptr);

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        runtime.setGlobalDescriptor(reg, withPointer(runtime.globalDescriptor(reg), encoded));
        return;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            _ = runtime.trySetNamedDescriptor(reg, withPointer(descriptor, encoded));
            return;
        }

        return;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            _ = runtime.trySetLocalDescriptor(reg, withPointer(descriptor, encoded));
            return;
        }

        return;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
}

pub fn setRegisterTag(reg: runtime.calcRegister_t, tag: u32) void {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        runtime.setGlobalDescriptor(reg, withTag(runtime.globalDescriptor(reg), tag));
        return;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            _ = runtime.trySetNamedDescriptor(reg, withTag(descriptor, tag));
            return;
        }

        if (runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        }

        return;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            _ = runtime.trySetLocalDescriptor(reg, withTag(descriptor, tag));
            return;
        }

        return;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
}