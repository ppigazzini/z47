const std = @import("std");
const abi = @import("abi"); // shared ABI bindings
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

// The register's string, terminator included. A register with no data block
// copies nothing, which is the case GCC's flags on the Windows build.
pub fn copyRegisterStringTo(dest: [*]u8, regist: runtime.calcRegister_t) void {
    const reg_data = getRegisterDataPointer(regist) orelse return;
    const reg_str: [*:0]const u8 = @ptrCast(@as([*]const u8, @ptrCast(reg_data)) + @sizeOf(abi.StrLgIntHeader));
    const len = std.mem.len(reg_str) + 1;
    @memmove(dest[0..len], reg_str[0..len]);
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

// typeDefinitions.h angularMode_t, and the two virtual polar bits registers.h
// adds above the five tag bits for a 3D vector.
const amAngleMask: u32 = 15;
const amPolar: u32 = 16;
const amPolarCYL: u32 = 64;
const amPolarSPH: u32 = 128;

fn isMatrix2dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 2) or (rows == 2 and cols == 1);
}

fn isMatrix3dVector(rows: u16, cols: u16) bool {
    return (rows == 1 and cols == 3) or (rows == 3 and cols == 1);
}

// null for a register that is not a real matrix
fn realMatrixHeader(regist: runtime.calcRegister_t) ?*align(1) const abi.MatrixHeader {
    if (getRegisterDataType(regist) != runtime.dtReal34Matrix) {
        return null;
    }
    return @ptrCast(getRegisterDataPointer(regist).?);
}

pub fn isRegisterMatrix3dVector(regist: runtime.calcRegister_t) bool {
    const header = realMatrixHeader(regist) orelse return false;
    return isMatrix3dVector(header.matrixRows, header.matrixColumns);
}

pub fn isRegisterMatrix2dVector(regist: runtime.calcRegister_t) bool {
    const header = realMatrixHeader(regist) orelse return false;
    return isMatrix2dVector(header.matrixRows, header.matrixColumns);
}

pub fn isRegisterMatrixVector(regist: runtime.calcRegister_t) bool {
    const header = realMatrixHeader(regist) orelse return false;
    return isMatrix3dVector(header.matrixRows, header.matrixColumns) or isMatrix2dVector(header.matrixRows, header.matrixColumns);
}

// amPolarSPH or amPolarCYL for a 3D vector, amPolar or 0 for a 2D vector, and 0
// for a vector without an angular mode or for any other register.
pub fn getVectorRegisterPolarMode(regist: runtime.calcRegister_t) u32 {
    const header = realMatrixHeader(regist) orelse return 0;

    const tag = getRegisterTag(regist);
    if ((tag & amAngleMask) == runtime.amNone) {
        return 0;
    }
    if (isMatrix3dVector(header.matrixRows, header.matrixColumns)) {
        return if ((tag & amPolar) != 0) amPolarSPH else amPolarCYL;
    }
    if (isMatrix2dVector(header.matrixRows, header.matrixColumns)) {
        return tag & amPolar;
    }
    return 0;
}

// polarMode is 0, amPolar, amPolarSPH or amPolarCYL.
pub fn setVectorRegisterPolarMode(regist: runtime.calcRegister_t, polarMode: u32) void {
    var tag = getRegisterTag(regist);
    if (polarMode == 0) {
        tag = (tag & ~(amAngleMask | amPolar)) + runtime.amNone; // if Polar is cleared, also clear angle
    } else {
        tag &= amAngleMask | amPolar;
        if (polarMode == amPolarSPH or polarMode == amPolar) {
            tag |= amPolar; // existing status, with polar bit ORred for 2DPolar or SPH
        } else if (polarMode == amPolarCYL) {
            tag &= ~amPolar; // ANDed to force Polar 0 for CYL
        }
    }
    setRegisterTag(regist, tag);
}

// A long integer, or a real without an angular mode.
pub fn registerIsNoAngle(regist: runtime.calcRegister_t) bool {
    const data_type = getRegisterDataType(regist);
    return (data_type == runtime.dtReal34 and (getRegisterTag(regist) & amAngleMask) == runtime.amNone) or data_type == runtime.dtLongInteger;
}

// inputAngleError3r is true for any other type in the two registers above.
pub fn isXFNregisterValid3r(regist: runtime.calcRegister_t) bool {
    const data_type = getRegisterDataType(regist);
    return (data_type == runtime.dtReal34 or data_type == runtime.dtLongInteger) and registerIsNoAngle(regist + 1) and registerIsNoAngle(regist + 2);
}
