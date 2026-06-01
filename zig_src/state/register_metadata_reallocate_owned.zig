const descriptor_owned = @import("register_metadata_descriptor_owned.zig");
const payload_owned = @import("register_metadata_payload_owned.zig");
const memory_owned = @import("register_memory_owned.zig");
const runtime = @import("register_metadata_runtime.zig");
const stack_runtime = @import("stack_runtime.zig");

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

fn needsReallocate(reg: runtime.calcRegister_t, data_type: u32, payload_size_in_blocks: u16) bool {
    const current_type = descriptor_owned.getRegisterDataType(reg);
    if (current_type != data_type) {
        return true;
    }

    if (payload_owned.isVariableSizedDataType(current_type)) {
        return payload_owned.getRegisterMaxDataLengthInBlocks(reg) != payload_size_in_blocks;
    }

    return false;
}

pub fn copySourceRegisterToDestRegister(source_register: runtime.calcRegister_t, dest_register: runtime.calcRegister_t) void {
    if (isSyntheticReservedCopySource(source_register)) {
        return;
    }

    const normalized_source = normalizeLetteredReservedRegister(source_register);
    const normalized_dest = normalizeLetteredReservedRegister(dest_register);
    const source_type = descriptor_owned.getRegisterDataType(normalized_source);
    const source_full_size = payload_owned.getRegisterFullSizeInBlocks(normalized_source);

    if (descriptor_owned.getRegisterDataType(normalized_dest) != source_type or payload_owned.getRegisterFullSizeInBlocks(normalized_dest) != source_full_size) {
        const payload_size = payload_owned.copyPayloadSizeWithoutHeader(normalized_source, source_type) orelse {
            return;
        };

        reallocateRegister(normalized_dest, source_type, payload_size, runtime.amNone);
        if (stack_runtime.lastErrorCode == stack_runtime.ERROR_RAM_FULL) {
            return;
        }
    }

    _ = stack_runtime.xcopy(
        descriptor_owned.getRegisterDataPointer(normalized_dest),
        descriptor_owned.getRegisterDataPointer(normalized_source),
        memory_owned.bytesFromBlocks(source_full_size),
    );
    descriptor_owned.setRegisterTag(normalized_dest, descriptor_owned.getRegisterTag(normalized_source));
}

pub fn reallocateRegister(reg: runtime.calcRegister_t, data_type: u32, data_size_without_data_len_blocks: u16, tag: u32) void {
    if (isReservedRegister(reg)) {
        // Reserved descriptors are storage-bound; migrating callers may still attempt reallocation.
        // Keep this as a no-op to avoid recursive retained dispatch and preserve backing pointers.
        return;
    }

    const normalized_payload_size = payload_owned.normalizePayloadSizeInBlocks(data_type, data_size_without_data_len_blocks);
    const allocated_size = payload_owned.allocationSizeInBlocks(data_type, normalized_payload_size);

    if (needsReallocate(reg, data_type, normalized_payload_size)) {
        if (!runtime.memoryBlockAvailable(allocated_size)) {
            runtime.reportRamFull();
            return;
        }

        memory_owned.freeRegisterData(reg);
        const data_ptr = if (allocated_size == 0) null else stack_runtime.allocC47Blocks(allocated_size);
        if (allocated_size != 0 and data_ptr == null) {
            runtime.reportRamFull();
            return;
        }

        descriptor_owned.setRegisterDataPointer(reg, data_ptr);
        descriptor_owned.setRegisterDataType(reg, @intCast(data_type), tag);

        if (data_type == runtime.dtReal34Matrix or data_type == runtime.dtComplex34Matrix) {
            runtime.initializeMatrixHeader1x1(data_ptr);
        } else {
            payload_owned.setRegisterMaxDataLengthInBlocks(reg, normalized_payload_size);
        }
    }

    if (data_type == runtime.dtComplex34 and stack_runtime.getSystemFlag(runtime.FLAG_POLAR)) {
        descriptor_owned.setRegisterTag(reg, runtime.currentAngularMode | runtime.amPolar);
    } else {
        descriptor_owned.setRegisterTag(reg, tag);
    }
}