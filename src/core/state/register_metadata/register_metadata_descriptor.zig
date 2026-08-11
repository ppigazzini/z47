const runtime = @import("register_metadata_runtime.zig");
const codec = @import("register_descriptor_codec.zig"); // std-only descriptor bit-field codec

const invalid_data_type: u32 = 31;

fn descriptorDataType(descriptor: runtime.register_descriptor_t) u32 {
    return codec.dataType(descriptor);
}

fn descriptorTag(descriptor: runtime.register_descriptor_t) u32 {
    return codec.tag(descriptor);
}

fn descriptorPointer(descriptor: runtime.register_descriptor_t) u16 {
    return codec.pointer(descriptor);
}

fn withDataTypeTag(descriptor: runtime.register_descriptor_t, data_type: u16, tag: u32) runtime.register_descriptor_t {
    return codec.withDataTypeTag(descriptor, data_type, tag);
}

fn withTag(descriptor: runtime.register_descriptor_t, tag: u32) runtime.register_descriptor_t {
    return codec.withTag(descriptor, tag);
}

fn withPointer(descriptor: runtime.register_descriptor_t, mem_ptr: u16) runtime.register_descriptor_t {
    return codec.withPointer(descriptor, mem_ptr);
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
            runtime.reportNoNamedVariablesBug("getRegisterDataType");
        } else {
            runtime.reportNamedVariableNotDefined("In function getRegisterDataType:", reg);
        }

        return invalid_data_type;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return descriptorDataType(runtime.reservedDataTypeDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return descriptorDataType(descriptor);
        } else if (runtime.noLocalRegisterFrame()) {
            runtime.moreInfoOnError("In function getRegisterDataType:", "no local registers defined!", "", "");
        } else {
            runtime.reportLocalRegisterNotDefined("In function getRegisterDataType:", reg);
        }
        return invalid_data_type;
    }

    runtime.reportRegisterAboveLastBug("getRegisterDataType", reg);
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
            runtime.reportNoNamedVariablesBug("getRegisterDataPointer");
        } else {
            runtime.reportNamedVariableNotDefined("In function getRegisterDataPointer:", reg);
        }

        return null;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return dataPointerFromDescriptor(descriptor);
        } else if (runtime.noLocalRegisterFrame()) {
            runtime.moreInfoOnError("In function getRegisterDataPointer:", "no local registers defined!", "", null);
        } else {
            runtime.reportLocalRegisterNotDefined("In function getRegisterDataPointer:", reg);
        }

        return null;
    }

    runtime.reportRegisterAboveLastBug("getRegisterDataPointer", reg);
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
            runtime.reportNoNamedVariablesBug("getRegisterTag");
        } else {
            runtime.reportNamedVariableNotDefined("In function getRegisterTag:", reg);
        }

        return 0;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return descriptorTag(runtime.reservedDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return descriptorTag(descriptor);
        } else if (runtime.noLocalRegisterFrame()) {
            runtime.moreInfoOnError("In function getRegisterTag:", "no local registers defined!", "", "");
        } else {
            runtime.reportLocalRegisterNotDefined("In function getRegisterTag:", reg);
        }

        return 0;
    }

    runtime.reportRegisterAboveLastBug("getRegisterTag", reg);
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
            runtime.reportNoNamedVariablesBug("setRegisterDataType");
        } else {
            runtime.reportNamedVariableNotDefined("In function setRegisterDataType:", reg);
        }

        return;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        // Nothing to do, as in setRegisterDataPointer(): allReservedVariables[] is
        // const, so a reserved variable's type and tag are fixed. The write this
        // replaces indexed allNamedVariables[] with a RESERVED index, so it retyped
        // an unrelated named variable.
        return;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            _ = runtime.trySetLocalDescriptor(reg, withDataTypeTag(descriptor, data_type, tag));
            return;
        } else if (runtime.noLocalRegisterFrame()) {
            runtime.moreInfoOnError("In function setRegisterDataType:", "no local registers defined!", "", "");
        } else {
            runtime.reportLocalRegisterNotDefined("In function setRegisterDataType:", reg);
        }

        return;
    }

    runtime.reportRegisterAboveLastBug("setRegisterDataType", reg);
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

        if (runtime.numberOfNamedVariables == 0) {
            // Upstream's text here names local registers; the branch is the
            // named-variable one, and this is the only accessor whose empty-block
            // case is a hint rather than a bug screen.
            runtime.moreInfoOnError("In function setRegisterDataPointer:", "no local registers defined!", null, null);
        } else {
            runtime.reportNamedVariableNotDefined("In function setRegisterDataPointer:", reg);
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
        } else if (runtime.noLocalRegisterFrame()) {
            runtime.moreInfoOnError("In function setRegisterDataPointer:", "no local registers defined!", "", "");
        } else {
            runtime.reportLocalRegisterNotDefined("In function setRegisterDataPointer:", reg);
        }

        return;
    }

    runtime.reportRegisterAboveLastBug("setRegisterDataPointer", reg);
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
            runtime.reportNoNamedVariablesBug("setRegisterTag");
        } else {
            runtime.reportNamedVariableNotDefined("In function setRegisterTag:", reg);
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
        } else if (runtime.noLocalRegisterFrame()) {
            runtime.moreInfoOnError("In function setRegisterTag:", "no local registers defined!", "", "");
        } else {
            runtime.reportLocalRegisterNotDefined("In function setRegisterTag:", reg);
        }

        return;
    }

    runtime.reportRegisterAboveLastBug("setRegisterTag", reg);
}
