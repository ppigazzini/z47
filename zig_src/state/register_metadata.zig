const builtin = @import("builtin");
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

fn dataPointerFromDescriptor(descriptor: runtime.register_descriptor_t) ?*anyopaque {
    return runtime.toPcMemPtr(descriptorPointer(descriptor));
}

fn tryGetDataPointerForMaxLengthGet(reg: runtime.calcRegister_t, data_ptr: *?*anyopaque, type_reg: *runtime.calcRegister_t) bool {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        data_ptr.* = dataPointerFromDescriptor(runtime.globalDescriptor(reg));
        type_reg.* = reg;
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            data_ptr.* = dataPointerFromDescriptor(descriptor);
            type_reg.* = @intCast(reg - runtime.FIRST_NAMED_VARIABLE);
            return data_ptr.* != null;
        }
        return false;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        data_ptr.* = dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
        type_reg.* = @intCast(reg - runtime.FIRST_RESERVED_VARIABLE);
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            data_ptr.* = dataPointerFromDescriptor(descriptor);
            type_reg.* = reg;
            return data_ptr.* != null;
        }
    }

    return false;
}

fn tryGetDataPointerForFullSize(reg: runtime.calcRegister_t, data_ptr: *?*anyopaque) bool {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        data_ptr.* = dataPointerFromDescriptor(runtime.globalDescriptor(reg));
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            data_ptr.* = dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
        return false;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        data_ptr.* = dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            data_ptr.* = dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
    }

    return false;
}

fn tryGetDataPointerForMaxLengthSet(reg: runtime.calcRegister_t, data_ptr: *?*anyopaque) bool {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        data_ptr.* = dataPointerFromDescriptor(runtime.globalDescriptor(reg));
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            data_ptr.* = dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
        return false;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return false;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            data_ptr.* = dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
    }

    return false;
}

fn matrixMaxLengthInBlocks(data_ptr: ?*const anyopaque, data_type: u32) u16 {
    return runtime.matrixPayloadSizeInBlocks(
        data_ptr,
        if (data_type == runtime.dtReal34Matrix) runtime.real34SizeInBlocks() else runtime.complex34SizeInBlocks(),
    );
}

fn isSyntheticReservedCopySource(reg: runtime.calcRegister_t) bool {
    return reg == runtime.RESERVED_VARIABLE_ADM or
        reg == runtime.RESERVED_VARIABLE_DENMAX or
        reg == runtime.RESERVED_VARIABLE_ISM or
        reg == runtime.RESERVED_VARIABLE_REALDF or
        reg == runtime.RESERVED_VARIABLE_NDEC;
}

fn normalizeLetteredReservedRegister(reg: runtime.calcRegister_t) runtime.calcRegister_t {
    if (reg >= runtime.FIRST_RESERVED_VARIABLE and reg < runtime.FIRST_NAMED_RESERVED_VARIABLE) {
        return reg - runtime.FIRST_RESERVED_VARIABLE + runtime.REGISTER_X;
    }
    return reg;
}

fn copyPayloadSizeWithoutHeader(source_reg: runtime.calcRegister_t, data_type: u32) ?u16 {
    return switch (data_type) {
        runtime.dtLongInteger,
        runtime.dtString,
        runtime.dtReal34Matrix,
        runtime.dtComplex34Matrix,
        => getRegisterMaxDataLengthInBlocks(source_reg),
        runtime.dtTime,
        runtime.dtDate,
        runtime.dtShortInteger,
        runtime.dtReal34,
        runtime.dtComplex34,
        runtime.dtConfig,
        => 0,
        else => null,
    };
}

fn getVariableFullSizeInBlocks(reg: runtime.calcRegister_t, data_type: u32) u16 {
    var data_ptr: ?*anyopaque = null;

    if (!tryGetDataPointerForFullSize(reg, &data_ptr)) {
        return runtime.retainedGetRegisterFullSizeInBlocks(reg);
    }

    return switch (data_type) {
        runtime.dtLongInteger, runtime.dtString => runtime.dataMaxLengthInBlocks(data_ptr) + runtime.strLgIntHeaderSizeInBlocks(),
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => matrixMaxLengthInBlocks(data_ptr, data_type) + runtime.matrixHeaderSizeInBlocks(),
        else => runtime.retainedGetRegisterFullSizeInBlocks(reg),
    };
}

pub export fn setRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t, max_data_len: u16) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetRegisterMaxDataLengthInBlocks(reg, max_data_len);
        return;
    }

    var data_ptr: ?*anyopaque = null;

    if (tryGetDataPointerForMaxLengthSet(reg, &data_ptr)) {
        runtime.setDataMaxLengthInBlocks(data_ptr, max_data_len);
        return;
    }

    runtime.retainedSetRegisterMaxDataLengthInBlocks(reg, max_data_len);
}

pub export fn getRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t) u16 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedGetRegisterMaxDataLengthInBlocks(reg);
    }

    var data_ptr: ?*anyopaque = null;
    var type_reg = reg;

    if (!tryGetDataPointerForMaxLengthGet(reg, &data_ptr, &type_reg)) {
        return runtime.retainedGetRegisterMaxDataLengthInBlocks(reg);
    }

    const data_type = getRegisterDataType(type_reg);
    if (data_type == runtime.dtReal34Matrix or data_type == runtime.dtComplex34Matrix) {
        return matrixMaxLengthInBlocks(data_ptr, data_type);
    }

    return runtime.dataMaxLengthInBlocks(data_ptr);
}

pub export fn getRegisterFullSizeInBlocks(reg: runtime.calcRegister_t) u16 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedGetRegisterFullSizeInBlocks(reg);
    }

    return switch (getRegisterDataType(reg)) {
        runtime.dtLongInteger,
        runtime.dtString,
        runtime.dtReal34Matrix,
        runtime.dtComplex34Matrix,
        => getVariableFullSizeInBlocks(reg, getRegisterDataType(reg)),
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => runtime.real34SizeInBlocks(),
        runtime.dtShortInteger => runtime.shortIntegerSizeInBlocks(),
        runtime.dtComplex34 => runtime.complex34SizeInBlocks(),
        runtime.dtConfig => runtime.configSizeInBlocks(),
        else => runtime.retainedGetRegisterFullSizeInBlocks(reg),
    };
}

pub export fn copySourceRegisterToDestRegister(source_register: runtime.calcRegister_t, dest_register: runtime.calcRegister_t) void {
    if (builtin.target.os.tag == .freestanding or isSyntheticReservedCopySource(source_register)) {
        runtime.retainedCopySourceRegisterToDestRegister(source_register, dest_register);
        return;
    }

    const normalized_source = normalizeLetteredReservedRegister(source_register);
    const normalized_dest = normalizeLetteredReservedRegister(dest_register);
    const source_type = getRegisterDataType(normalized_source);
    const source_full_size = getRegisterFullSizeInBlocks(normalized_source);

    if (getRegisterDataType(normalized_dest) != source_type or getRegisterFullSizeInBlocks(normalized_dest) != source_full_size) {
        const payload_size = copyPayloadSizeWithoutHeader(normalized_source, source_type) orelse {
            runtime.retainedCopySourceRegisterToDestRegister(source_register, dest_register);
            return;
        };

        stack_runtime.reallocateRegister(normalized_dest, source_type, payload_size, runtime.amNone);
        if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
            return;
        }
    }

    _ = stack_runtime.xcopy(
        getRegisterDataPointer(normalized_dest),
        getRegisterDataPointer(normalized_source),
        stack_runtime.bytesFromBlocks(source_full_size),
    );
    setRegisterTag(normalized_dest, getRegisterTag(normalized_source));
}

pub export fn getRegisterDataType(reg: runtime.calcRegister_t) u32 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedGetRegisterDataType(reg);
    }

    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return descriptorDataType(runtime.globalDescriptor(reg));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return descriptorDataType(descriptor);
        }
        return runtime.retainedGetRegisterDataType(reg);
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return descriptorDataType(runtime.reservedDataTypeDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return descriptorDataType(descriptor);
        }
    }

    return runtime.retainedGetRegisterDataType(reg);
}

pub export fn getRegisterDataPointer(reg: runtime.calcRegister_t) ?*anyopaque {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedGetRegisterDataPointer(reg);
    }

    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return runtime.toPcMemPtr(descriptorPointer(runtime.globalDescriptor(reg)));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return runtime.toPcMemPtr(descriptorPointer(descriptor));
        }
        return runtime.retainedGetRegisterDataPointer(reg);
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return runtime.toPcMemPtr(descriptorPointer(runtime.reservedDescriptor(reg)));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return runtime.toPcMemPtr(descriptorPointer(descriptor));
        }
    }

    return runtime.retainedGetRegisterDataPointer(reg);
}

pub export fn getRegisterTag(reg: runtime.calcRegister_t) u32 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.retainedGetRegisterTag(reg);
    }

    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return descriptorTag(runtime.globalDescriptor(reg));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return descriptorTag(descriptor);
        }
        return runtime.retainedGetRegisterTag(reg);
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return descriptorTag(runtime.reservedDescriptor(reg));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return descriptorTag(descriptor);
        }
    }

    return runtime.retainedGetRegisterTag(reg);
}

pub export fn setRegisterDataType(reg: runtime.calcRegister_t, data_type: u16, tag: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetRegisterDataType(reg, data_type, tag);
        return;
    }

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
        runtime.retainedSetRegisterDataType(reg, data_type, tag);
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
    }

    runtime.retainedSetRegisterDataType(reg, data_type, tag);
}

pub export fn setRegisterDataPointer(reg: runtime.calcRegister_t, mem_ptr: ?*const anyopaque) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetRegisterDataPointer(reg, mem_ptr);
        return;
    }

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
        runtime.retainedSetRegisterDataPointer(reg, mem_ptr);
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
    }

    runtime.retainedSetRegisterDataPointer(reg, mem_ptr);
}

pub export fn setRegisterTag(reg: runtime.calcRegister_t, tag: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.retainedSetRegisterTag(reg, tag);
        return;
    }

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
        runtime.retainedSetRegisterTag(reg, tag);
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
    }

    runtime.retainedSetRegisterTag(reg, tag);
}
