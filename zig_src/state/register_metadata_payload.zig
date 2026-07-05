const descriptor_owned = @import("register_metadata_descriptor.zig");
const runtime = @import("register_metadata_runtime.zig");
const stack_runtime = @import("stack_runtime.zig");

pub fn tryGetDataPointerForMaxLengthGet(reg: runtime.calcRegister_t, data_ptr: *?*anyopaque, type_reg: *runtime.calcRegister_t) bool {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        data_ptr.* = descriptor_owned.dataPointerFromDescriptor(runtime.globalDescriptor(reg));
        type_reg.* = reg;
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            data_ptr.* = descriptor_owned.dataPointerFromDescriptor(descriptor);
            type_reg.* = @intCast(reg - runtime.FIRST_NAMED_VARIABLE);
            return data_ptr.* != null;
        }
        return false;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        data_ptr.* = descriptor_owned.dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
        type_reg.* = @intCast(reg - runtime.FIRST_RESERVED_VARIABLE);
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            data_ptr.* = descriptor_owned.dataPointerFromDescriptor(descriptor);
            type_reg.* = reg;
            return data_ptr.* != null;
        }
    }

    return false;
}

pub fn tryGetDataPointerForFullSize(reg: runtime.calcRegister_t, data_ptr: *?*anyopaque) bool {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        data_ptr.* = descriptor_owned.dataPointerFromDescriptor(runtime.globalDescriptor(reg));
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            data_ptr.* = descriptor_owned.dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
        return false;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        data_ptr.* = descriptor_owned.dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            data_ptr.* = descriptor_owned.dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
    }

    return false;
}

pub fn tryGetDataPointerForMaxLengthSet(reg: runtime.calcRegister_t, data_ptr: *?*anyopaque) bool {
    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        data_ptr.* = descriptor_owned.dataPointerFromDescriptor(runtime.globalDescriptor(reg));
        return data_ptr.* != null;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            data_ptr.* = descriptor_owned.dataPointerFromDescriptor(descriptor);
            return data_ptr.* != null;
        }
        return false;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return false;
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            data_ptr.* = descriptor_owned.dataPointerFromDescriptor(descriptor);
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

pub fn copyPayloadSizeWithoutHeader(source_reg: runtime.calcRegister_t, data_type: u32) ?u16 {
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

pub fn isVariableSizedDataType(data_type: u32) bool {
    return data_type == runtime.dtLongInteger or
        data_type == runtime.dtString or
        data_type == runtime.dtReal34Matrix or
        data_type == runtime.dtComplex34Matrix;
}

pub fn normalizePayloadSizeInBlocks(data_type: u32, requested_size_in_blocks: u16) u16 {
    return switch (data_type) {
        runtime.dtComplex34 => runtime.complex34SizeInBlocks(),
        runtime.dtReal34,
        runtime.dtTime,
        runtime.dtDate,
        => runtime.real34SizeInBlocks(),
        runtime.dtShortInteger => runtime.shortIntegerSizeInBlocks(),
        runtime.dtConfig => runtime.configSizeInBlocks(),
        runtime.dtLongInteger => runtime.alignLongIntegerBlocks(requested_size_in_blocks),
        else => requested_size_in_blocks,
    };
}

pub fn allocationSizeInBlocks(data_type: u32, payload_size_in_blocks: u16) u16 {
    return switch (data_type) {
        runtime.dtString,
        runtime.dtLongInteger,
        => payload_size_in_blocks + runtime.strLgIntHeaderSizeInBlocks(),
        runtime.dtReal34Matrix,
        runtime.dtComplex34Matrix,
        => payload_size_in_blocks + runtime.matrixHeaderSizeInBlocks(),
        else => payload_size_in_blocks,
    };
}

fn getVariableFullSizeInBlocks(reg: runtime.calcRegister_t, data_type: u32) u16 {
    var data_ptr: ?*anyopaque = null;

    if (!tryGetDataPointerForFullSize(reg, &data_ptr)) {
        return 0;
    }

    return switch (data_type) {
        runtime.dtLongInteger, runtime.dtString => runtime.dataMaxLengthInBlocks(data_ptr) + runtime.strLgIntHeaderSizeInBlocks(),
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => matrixMaxLengthInBlocks(data_ptr, data_type) + runtime.matrixHeaderSizeInBlocks(),
        else => 0,
    };
}

pub fn setRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t, max_data_len: u16) void {
    var data_ptr: ?*anyopaque = null;
    var descriptor: runtime.register_descriptor_t = 0;

    if (tryGetDataPointerForMaxLengthSet(reg, &data_ptr)) {
        runtime.setDataMaxLengthInBlocks(data_ptr, max_data_len);
        return;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE and runtime.numberOfNamedVariables == 0) {
        stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        return;
    }

    if (reg > runtime.LAST_LOCAL_REGISTER) {
        stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        return;
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE and !runtime.tryGetNamedDescriptor(reg, &descriptor)) {
        return;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        data_ptr = descriptor_owned.dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
        if (data_ptr != null) {
            runtime.setDataMaxLengthInBlocks(data_ptr, max_data_len);
            return;
        }
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER and reg > runtime.LAST_RESERVED_VARIABLE and !runtime.tryGetLocalDescriptor(reg, &descriptor)) {
        return;
    }
}

pub fn getRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t) u16 {
    var data_ptr: ?*anyopaque = null;
    var type_reg = reg;

    if (!tryGetDataPointerForMaxLengthGet(reg, &data_ptr, &type_reg)) {
        if (reg <= runtime.LAST_NAMED_VARIABLE and runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
            return 0;
        }

        if (reg > runtime.LAST_LOCAL_REGISTER) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
            return 0;
        }

        return 0;
    }

    const data_type = descriptor_owned.getRegisterDataType(type_reg);
    if (data_type == runtime.dtReal34Matrix or data_type == runtime.dtComplex34Matrix) {
        return matrixMaxLengthInBlocks(data_ptr, data_type);
    }

    return runtime.dataMaxLengthInBlocks(data_ptr);
}

pub fn getRegisterFullSizeInBlocks(reg: runtime.calcRegister_t) u16 {
    return switch (descriptor_owned.getRegisterDataType(reg)) {
        runtime.dtLongInteger,
        runtime.dtString,
        runtime.dtReal34Matrix,
        runtime.dtComplex34Matrix,
        => getVariableFullSizeInBlocks(reg, descriptor_owned.getRegisterDataType(reg)),
        runtime.dtTime, runtime.dtDate, runtime.dtReal34 => runtime.real34SizeInBlocks(),
        runtime.dtShortInteger => runtime.shortIntegerSizeInBlocks(),
        runtime.dtComplex34 => runtime.complex34SizeInBlocks(),
        runtime.dtConfig => runtime.configSizeInBlocks(),
        else => blk: {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
            break :blk 0;
        },
    };
}