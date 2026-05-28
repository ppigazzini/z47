const builtin = @import("builtin");
const runtime = @import("register_metadata_runtime.zig");
const stack_runtime = @import("stack_runtime.zig");

const pointer_mask: runtime.register_descriptor_t = 0x0000ffff;
const data_type_mask: runtime.register_descriptor_t = 0x000f0000;
const tag_mask: runtime.register_descriptor_t = 0x01f00000;
const data_type_shift: u5 = 16;
const tag_shift: u5 = 20;
const invalid_data_type: u32 = 31;
const validateNameMaxGlyphs: usize = 7;
const glyph_A: u16 = 0x41;
const glyph_Z: u16 = 0x5a;
const glyphA: u16 = 0x61;
const glyphZ: u16 = 0x7a;
const glyph_A_grave: u16 = 0x00c0;
const glyphCross: u16 = 0x00d7;
const glyphDivide: u16 = 0x00f7;
const glyphZCaron: u16 = 0x017e;
const glyphIotaDialytikaTonos: u16 = 0x0390;
const glyphSampi: u16 = 0x03e1;
const glyphSubAlpha: u16 = 0x2296;
const glyphSubMu: u16 = 0x2298;
const glyphSupA: u16 = 0x2482;
const glyph_sub_Z: u16 = 0x24e9;

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

fn isReservedRegister(reg: runtime.calcRegister_t) bool {
    return reg > runtime.LAST_NAMED_VARIABLE and reg <= runtime.LAST_RESERVED_VARIABLE;
}

fn normalizeLetteredReservedRegister(reg: runtime.calcRegister_t) runtime.calcRegister_t {
    if (reg >= runtime.FIRST_RESERVED_VARIABLE and reg < runtime.FIRST_NAMED_RESERVED_VARIABLE) {
        return reg - runtime.FIRST_RESERVED_VARIABLE + runtime.REGISTER_X;
    }
    return reg;
}

fn copyPayloadSizeWithoutHeader(sourceReg: runtime.calcRegister_t, dataType: u32) ?u16 {
    return switch (dataType) {
        runtime.dtLongInteger,
        runtime.dtString,
        runtime.dtReal34Matrix,
        runtime.dtComplex34Matrix,
        => getRegisterMaxDataLengthInBlocks(sourceReg),
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

fn isVariableSizedDataType(dataType: u32) bool {
    return dataType == runtime.dtLongInteger or
        dataType == runtime.dtString or
        dataType == runtime.dtReal34Matrix or
        dataType == runtime.dtComplex34Matrix;
}

fn normalizePayloadSizeInBlocks(dataType: u32, requestedSizeInBlocks: u16) u16 {
    return switch (dataType) {
        runtime.dtComplex34 => runtime.complex34SizeInBlocks(),
        runtime.dtReal34,
        runtime.dtTime,
        runtime.dtDate,
        => runtime.real34SizeInBlocks(),
        runtime.dtShortInteger => runtime.shortIntegerSizeInBlocks(),
        runtime.dtConfig => runtime.configSizeInBlocks(),
        runtime.dtLongInteger => runtime.alignLongIntegerBlocks(requestedSizeInBlocks),
        else => requestedSizeInBlocks,
    };
}

fn allocationSizeInBlocks(dataType: u32, payloadSizeInBlocks: u16) u16 {
    return switch (dataType) {
        runtime.dtString,
        runtime.dtLongInteger,
        => payloadSizeInBlocks + runtime.strLgIntHeaderSizeInBlocks(),
        runtime.dtReal34Matrix,
        runtime.dtComplex34Matrix,
        => payloadSizeInBlocks + runtime.matrixHeaderSizeInBlocks(),
        else => payloadSizeInBlocks,
    };
}

fn validateNameGlyphLength(name: [*:0]const u8) usize {
    var glyphLength: usize = 0;
    var offset: usize = 0;

    while (name[offset] != 0) {
        offset += if ((name[offset] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
        glyphLength += 1;
    }

    return glyphLength;
}

fn validateNameNextGlyphOffset(name: [*:0]const u8, offset: usize) usize {
    return offset + if ((name[offset] & 0x80) != 0) @as(usize, 2) else @as(usize, 1);
}

fn validateNameGlyphCode(name: [*:0]const u8, offset: usize) u16 {
    const first = name[offset];

    if ((first & 0x80) != 0) {
        return (@as(u16, first & 0x7f) << 8) | @as(u16, name[offset + 1]);
    }

    return @as(u16, first);
}

fn needsReallocate(reg: runtime.calcRegister_t, dataType: u32, payloadSizeInBlocks: u16) bool {
    const currentType = getRegisterDataType(reg);
    if (currentType != dataType) {
        return true;
    }

    if (isVariableSizedDataType(currentType)) {
        return getRegisterMaxDataLengthInBlocks(reg) != payloadSizeInBlocks;
    }

    return false;
}

fn getVariableFullSizeInBlocks(reg: runtime.calcRegister_t, dataType: u32) u16 {
    var dataPtr: ?*anyopaque = null;

    if (!tryGetDataPointerForFullSize(reg, &dataPtr)) {
        return runtime.getRegisterFullSizeInBlocksRetained(reg);
    }

    return switch (dataType) {
        runtime.dtLongInteger, runtime.dtString => runtime.dataMaxLengthInBlocks(dataPtr) + runtime.strLgIntHeaderSizeInBlocks(),
        runtime.dtReal34Matrix, runtime.dtComplex34Matrix => matrixMaxLengthInBlocks(dataPtr, dataType) + runtime.matrixHeaderSizeInBlocks(),
        else => runtime.getRegisterFullSizeInBlocksRetained(reg),
    };
}

pub export fn setRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t, maxDataLen: u16) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.setRegisterMaxDataLengthInBlocksRetained(reg, maxDataLen);
        return;
    }

    var dataPtr: ?*anyopaque = null;
    var descriptor: runtime.register_descriptor_t = 0;

    if (tryGetDataPointerForMaxLengthSet(reg, &dataPtr)) {
        runtime.setDataMaxLengthInBlocks(dataPtr, maxDataLen);
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
        dataPtr = dataPointerFromDescriptor(runtime.reservedDescriptor(reg));
        if (dataPtr != null) {
            runtime.setDataMaxLengthInBlocks(dataPtr, maxDataLen);
            return;
        }
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER and reg > runtime.LAST_RESERVED_VARIABLE and !runtime.tryGetLocalDescriptor(reg, &descriptor)) {
        return;
    }

    runtime.setRegisterMaxDataLengthInBlocksRetained(reg, maxDataLen);
}

pub export fn getRegisterMaxDataLengthInBlocks(reg: runtime.calcRegister_t) u16 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.getRegisterMaxDataLengthInBlocksRetained(reg);
    }

    var dataPtr: ?*anyopaque = null;
    var typeReg = reg;

    if (!tryGetDataPointerForMaxLengthGet(reg, &dataPtr, &typeReg)) {
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

    const dataType = getRegisterDataType(typeReg);
    if (dataType == runtime.dtReal34Matrix or dataType == runtime.dtComplex34Matrix) {
        return matrixMaxLengthInBlocks(dataPtr, dataType);
    }

    return runtime.dataMaxLengthInBlocks(dataPtr);
}

pub export fn getRegisterFullSizeInBlocks(reg: runtime.calcRegister_t) u16 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.getRegisterFullSizeInBlocksRetained(reg);
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
        else => blk: {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
            break :blk 0;
        },
    };
}

pub export fn copySourceRegisterToDestRegister(sourceRegister: runtime.calcRegister_t, destRegister: runtime.calcRegister_t) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.copySourceRegisterToDestRegisterRetained(sourceRegister, destRegister);
        return;
    }

    if (isSyntheticReservedCopySource(sourceRegister)) {
        return;
    }

    const normalizedSource = normalizeLetteredReservedRegister(sourceRegister);
    const normalizedDest = normalizeLetteredReservedRegister(destRegister);
    const sourceType = getRegisterDataType(normalizedSource);
    const sourceFullSize = getRegisterFullSizeInBlocks(normalizedSource);

    if (getRegisterDataType(normalizedDest) != sourceType or getRegisterFullSizeInBlocks(normalizedDest) != sourceFullSize) {
        const payloadSize = copyPayloadSizeWithoutHeader(normalizedSource, sourceType) orelse {
            return;
        };

        reallocateRegister(normalizedDest, sourceType, payloadSize, runtime.amNone);
        if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
            return;
        }
    }

    _ = stack_runtime.xcopy(
        getRegisterDataPointer(normalizedDest),
        getRegisterDataPointer(normalizedSource),
        stack_runtime.bytesFromBlocks(sourceFullSize),
    );
    setRegisterTag(normalizedDest, getRegisterTag(normalizedSource));
}

pub export fn reallocateRegister(reg: runtime.calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    if (builtin.target.os.tag == .freestanding or isReservedRegister(reg)) {
        runtime.reallocateRegisterRetained(reg, data_type, data_size_without_data_len_blocks, tag);
        return;
    }

    const normalized_payload_size = normalizePayloadSizeInBlocks(data_type, data_size_without_data_len_blocks);
    const allocated_size = allocationSizeInBlocks(data_type, normalized_payload_size);

    if (needsReallocate(reg, data_type, normalized_payload_size)) {
        if (!runtime.memoryBlockAvailable(allocated_size)) {
            runtime.reportRamFull();
            return;
        }

        stack_runtime.freeRegisterData(reg);
        const data_ptr = if (allocated_size == 0) null else stack_runtime.allocC47Blocks(allocated_size);
        if (allocated_size != 0 and data_ptr == null) {
            runtime.reportRamFull();
            return;
        }

        setRegisterDataPointer(reg, data_ptr);
        setRegisterDataType(reg, @intCast(data_type), tag);

        if (data_type == runtime.dtReal34Matrix or data_type == runtime.dtComplex34Matrix) {
            runtime.initializeMatrixHeader1x1(data_ptr);
        } else {
            setRegisterMaxDataLengthInBlocks(reg, normalized_payload_size);
        }
    }

    if (data_type == runtime.dtComplex34 and stack_runtime.getSystemFlag(runtime.FLAG_POLAR)) {
        setRegisterTag(reg, runtime.currentAngularMode | runtime.amPolar);
    } else {
        setRegisterTag(reg, tag);
    }
}

pub export fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void {
    runtime.allocateLocalRegistersRetained(number_of_registers_to_allocate);
}

pub export fn validateName(name: [*c]const u8) bool {
    if (name == null) {
        return false;
    }

    const text: [*:0]const u8 = @ptrCast(name);
    const glyphLength = validateNameGlyphLength(text);

    if (glyphLength > validateNameMaxGlyphs or glyphLength == 0) {
        return false;
    }

    const first = validateNameGlyphCode(text, 0);

    if (first < glyph_A) {
        return false;
    }
    if (first > glyph_Z and first < glyphA) {
        return false;
    }
    if (first > glyphZ and first < glyph_A_grave) {
        return false;
    }
    if (first == glyphCross or first == glyphDivide) {
        return false;
    }
    if (first > glyphZCaron and first < glyphIotaDialytikaTonos) {
        return false;
    }
    if (first > glyphSampi and first < glyphSubAlpha) {
        return false;
    }
    if (first > glyphSubMu and first < glyphSupA) {
        return false;
    }
    if (first > glyph_sub_Z) {
        return false;
    }

    var offset = validateNameNextGlyphOffset(text, 0);
    while (text[offset] != 0) : (offset = validateNameNextGlyphOffset(text, offset)) {
        switch (text[offset]) {
            '+', '-', ':', '/', '^', '(', ')', '=', ';', '|', '!', ' ' => return false,
            else => {},
        }

        if (validateNameGlyphCode(text, offset) == glyphCross) {
            return false;
        }
    }

    return true;
}

pub export fn isUniqueMenuName(name: [*c]const u8) bool {
    if (name == null) {
        return false;
    }

    var index: u32 = 0;
    while (index < runtime.builtinMenuItemCount()) : (index += 1) {
        if (!runtime.builtinMenuItemIsMenu(index)) {
            continue;
        }

        if (runtime.compareMenuNames(name, runtime.builtinMenuItemName(index)) == 0) {
            return false;
        }
    }

    index = 0;
    while (index < runtime.userMenuCount()) : (index += 1) {
        if (runtime.compareMenuNames(name, runtime.userMenuName(index)) == 0) {
            return false;
        }
    }

    return true;
}

pub export fn allocateNamedVariable(variable_name: [*c]const u8, data_type: u32, full_data_size_in_blocks: u16) void {
    if (variable_name == null) {
        return;
    }

    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyphLength = validateNameGlyphLength(text);

    if (glyphLength < 1 or glyphLength > validateNameMaxGlyphs) {
        return;
    }

    if (runtime.findReservedVariableName(variable_name, @intCast(glyphLength)) != runtime.INVALID_VARIABLE) {
        runtime.reportInvalidName();
        return;
    }

    if (!validateName(variable_name)) {
        runtime.reportInvalidName();
        return;
    }

    if (runtime.numberOfNamedVariables == 0) {
        if (!runtime.allocateFirstNamedVariableHeader()) {
            runtime.reportRamFull();
            return;
        }

        runtime.storeNamedVariableName(0, variable_name);
        setRegisterDataType(runtime.FIRST_NAMED_VARIABLE, @intCast(data_type), runtime.amNone);
        setRegisterDataPointer(runtime.FIRST_NAMED_VARIABLE, stack_runtime.allocC47Blocks(full_data_size_in_blocks));
        return;
    }

    if (runtime.numberOfNamedVariables == (runtime.LAST_NAMED_VARIABLE - runtime.FIRST_NAMED_VARIABLE + 1)) {
        runtime.reportTooManyVariables();
        return;
    }

    var new_index: u16 = 0;
    if (!runtime.appendNamedVariableHeader(&new_index)) {
        runtime.reportRamFull();
        return;
    }

    runtime.storeNamedVariableName(new_index, variable_name);

    const register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(new_index));
    setRegisterDataType(register, @intCast(data_type), runtime.amNone);
    setRegisterDataPointer(register, stack_runtime.allocC47Blocks(full_data_size_in_blocks));
}

pub export fn fnDeleteVariable(regist: u16) void {
    const register: runtime.calcRegister_t = @intCast(regist);
    const named_variable_limit = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables));

    if (register >= runtime.FIRST_NAMED_VARIABLE and register < named_variable_limit) {
        const index: u16 = @intCast(register - runtime.FIRST_NAMED_VARIABLE);
        runtime.removeNamedVariableRecallAssignment(index);
        stack_runtime.freeRegisterData(register);

        var shift_index = index;
        while (shift_index + 1 < runtime.numberOfNamedVariables) : (shift_index += 1) {
            runtime.setNamedDescriptorUnchecked(shift_index, runtime.namedDescriptorUnchecked(shift_index + 1));
            runtime.storeNamedVariableName(shift_index, runtime.namedVariableName(shift_index + 1));
        }

        runtime.clearNamedVariableSlot(runtime.numberOfNamedVariables - 1);
        runtime.shrinkNamedVariableHeaderStorage();
        runtime.numberOfNamedVariables -= 1;
        return;
    }

    if (register >= runtime.FIRST_NAMED_VARIABLE and register < runtime.LAST_NAMED_VARIABLE) {
        runtime.reportUndefSourceVar();
        return;
    }

    runtime.reportCannotDeletePredefItem();
}

fn initializeSimEqMatrix(variable_name: [*:0]const u8) void {
    allocateNamedVariable(variable_name, runtime.dtReal34Matrix, runtime.real34SizeInBlocks() + runtime.matrixHeaderSizeInBlocks());
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    const register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables - 1));
    const data_ptr = getRegisterDataPointer(register);

    runtime.initializeMatrixHeader1x1(data_ptr);
    stack_runtime.real34SetZero(firstMatrixElementPointer(data_ptr));
}

fn initSimEqMatABX() void {
    initializeSimEqMatrix("Mat_A");
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    initializeSimEqMatrix("Mat_B");
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return;
    }

    initializeSimEqMatrix("Mat_X");
}

fn refreshSimEqMatrix(variable_name: [*:0]const u8) void {
    const register = findOrAllocateNamedVariable(variable_name);
    if (register == runtime.INVALID_VARIABLE) {
        return;
    }

    reallocateRegister(register, runtime.dtReal34Matrix, runtime.real34SizeInBlocks(), runtime.amNone);
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    const data_ptr = getRegisterDataPointer(register);
    runtime.initializeMatrixHeader1x1(data_ptr);
    stack_runtime.real34SetZero(firstMatrixElementPointer(data_ptr));
}

fn firstMatrixElementPointer(data_ptr: ?*anyopaque) ?*anyopaque {
    const ptr = data_ptr orelse return null;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const payload_offset: usize = @intCast(stack_runtime.bytesFromBlocks(runtime.matrixHeaderSizeInBlocks()));
    return @ptrCast(bytes + payload_offset);
}

fn refreshSimEqMatABX() void {
    refreshSimEqMatrix("Mat_A");
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    refreshSimEqMatrix("Mat_B");
    if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
        return;
    }

    refreshSimEqMatrix("Mat_X");
}

fn namedVariableNameEquals(index: u16, variable_name: [*:0]const u8) bool {
    return runtime.compareMenuNames(runtime.namedVariableName(index), variable_name) == 0;
}

fn preserveNamedVariableDuringClear(index: u16) bool {
    return namedVariableNameEquals(index, "STATS") or
        namedVariableNameEquals(index, "HISTO") or
        namedVariableNameEquals(index, "Mat_A") or
        namedVariableNameEquals(index, "Mat_B") or
        namedVariableNameEquals(index, "Mat_X");
}

pub export fn fnDeleteAllVariables(confirmation: u16) void {
    if (confirmation == stack_runtime.NOT_CONFIRMED and stack_runtime.programRunStop != stack_runtime.PGM_RUNNING) {
        runtime.requestDeleteAllVariablesConfirmation();
        return;
    }

    var variable_index = runtime.numberOfNamedVariables;
    while (variable_index > 0) : (variable_index -= 1) {
        fnDeleteVariable(@intCast(runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(variable_index - 1))));
    }

    initSimEqMatABX();
    runtime.temporaryInformation = if (stack_runtime.programRunStop != stack_runtime.PGM_RUNNING)
        runtime.TI_DEL_ALL_VARIABLES
    else
        runtime.TI_NO_INFO;
}

pub export fn fnClearAllVariables(confirmation: u16) void {
    if (confirmation == stack_runtime.NOT_CONFIRMED and stack_runtime.programRunStop != stack_runtime.PGM_RUNNING) {
        runtime.requestClearAllVariablesConfirmation();
        return;
    }

    var variable_index = runtime.numberOfNamedVariables;
    while (variable_index > 0) {
        const index = variable_index - 1;
        variable_index -= 1;

        if (preserveNamedVariableDuringClear(index)) {
            continue;
        }

        stack_runtime.clearRegister(runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(index)));
    }

    runtime.clearSigma();
    refreshSimEqMatABX();
    runtime.temporaryInformation = if (stack_runtime.programRunStop != stack_runtime.PGM_RUNNING)
        runtime.TI_CLEAR_ALL_VARIABLES
    else
        runtime.TI_NO_INFO;
}

pub export fn findNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyphLength = validateNameGlyphLength(text);

    if (glyphLength < 1 or glyphLength > 7) {
        return runtime.INVALID_VARIABLE;
    }

    const reserved = runtime.findReservedVariableName(variable_name, @intCast(glyphLength));
    if (reserved != runtime.INVALID_VARIABLE) {
        return reserved;
    }

    var index: u16 = 0;
    while (index < runtime.numberOfNamedVariables) : (index += 1) {
        if (runtime.compareMenuNames(runtime.namedVariableName(index), variable_name) == 0) {
            return runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(index));
        }
    }

    return runtime.INVALID_VARIABLE;
}

pub export fn findOrAllocateNamedVariable(variable_name: [*c]const u8) runtime.calcRegister_t {
    const text: [*:0]const u8 = @ptrCast(variable_name);
    const glyphLength = validateNameGlyphLength(text);

    if (glyphLength < 1 or glyphLength > 7) {
        return runtime.INVALID_VARIABLE;
    }

    const register = findNamedVariable(variable_name);
    if (register != runtime.INVALID_VARIABLE) {
        return register;
    }

    if (runtime.numberOfNamedVariables > (runtime.LAST_NAMED_VARIABLE - runtime.FIRST_NAMED_VARIABLE)) {
        return runtime.INVALID_VARIABLE;
    }

    allocateNamedVariable(variable_name, runtime.dtReal34, runtime.real34SizeInBlocks());
    if (stack_runtime.lastErrorCode != stack_runtime.ERROR_NONE) {
        return runtime.INVALID_VARIABLE;
    }

    const new_register = runtime.FIRST_NAMED_VARIABLE + @as(runtime.calcRegister_t, @intCast(runtime.numberOfNamedVariables - 1));
    stack_runtime.real34SetZero(getRegisterDataPointer(new_register));
    return new_register;
}

pub export fn isFunctionAllowingNewVariable(op: u16) bool {
    return switch (op) {
        runtime.ITM_INPUT,
        runtime.ITM_STO,
        runtime.ITM_STOADD,
        runtime.ITM_STOSUB,
        runtime.ITM_STOMULT,
        runtime.ITM_STODIV,
        runtime.ITM_KEYQ,
        runtime.ITM_M_DIM,
        runtime.ITM_MVAR,
        runtime.ITM_SOLVE,
        runtime.ITM_STOCFG,
        runtime.ITM_STOMAX,
        runtime.ITM_STOMIN,
        runtime.ITM_XtoALPHA,
        runtime.ITM_Xex,
        runtime.ITM_Yex,
        runtime.ITM_Zex,
        runtime.ITM_Tex,
        runtime.ITM_INTEGRAL,
        => true,
        else => false,
    };
}

pub export fn getRegisterDataType(reg: runtime.calcRegister_t) u32 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.getRegisterDataTypeRetained(reg);
    }

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

pub export fn getRegisterDataPointer(reg: runtime.calcRegister_t) ?*anyopaque {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.getRegisterDataPointerRetained(reg);
    }

    var descriptor: runtime.register_descriptor_t = 0;

    if (reg <= runtime.LAST_GLOBAL_REGISTER) {
        return runtime.toPcMemPtr(descriptorPointer(runtime.globalDescriptor(reg)));
    }

    if (reg <= runtime.LAST_NAMED_VARIABLE) {
        if (runtime.tryGetNamedDescriptor(reg, &descriptor)) {
            return runtime.toPcMemPtr(descriptorPointer(descriptor));
        }

        if (runtime.numberOfNamedVariables == 0) {
            stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
        }

        return null;
    }

    if (reg <= runtime.LAST_RESERVED_VARIABLE) {
        return runtime.toPcMemPtr(descriptorPointer(runtime.reservedDescriptor(reg)));
    }

    if (reg <= runtime.LAST_LOCAL_REGISTER) {
        if (runtime.tryGetLocalDescriptor(reg, &descriptor)) {
            return runtime.toPcMemPtr(descriptorPointer(descriptor));
        }

        return null;
    }

    stack_runtime.lastErrorCode = stack_runtime.ERROR_OUT_OF_RANGE;
    return null;
}

pub export fn getRegisterTag(reg: runtime.calcRegister_t) u32 {
    if (builtin.target.os.tag == .freestanding) {
        return runtime.getRegisterTagRetained(reg);
    }

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

pub export fn setRegisterDataType(reg: runtime.calcRegister_t, data_type: u16, tag: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.setRegisterDataTypeRetained(reg, data_type, tag);
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

pub export fn setRegisterDataPointer(reg: runtime.calcRegister_t, mem_ptr: ?*const anyopaque) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.setRegisterDataPointerRetained(reg, mem_ptr);
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

pub export fn setRegisterTag(reg: runtime.calcRegister_t, tag: u32) void {
    if (builtin.target.os.tag == .freestanding) {
        runtime.setRegisterTagRetained(reg, tag);
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
