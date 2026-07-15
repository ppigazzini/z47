const runtime = @import("../runtime/stack_runtime.zig");
const memory_owned = @import("../runtime/register_memory.zig");

fn complexImagPointer(data_ptr: ?*anyopaque) ?*anyopaque {
    const ptr = data_ptr orelse return null;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const imag_offset: usize = @intCast(memory_owned.bytesFromBlocks(runtime.real34SizeInBlocks()));
    return @ptrCast(bytes + imag_offset);
}

fn clearRange(start: runtime.calcRegister_t, end: runtime.calcRegister_t) void {
    var reg = start;
    while (reg <= end) : (reg += 1) {
        clearRegister(reg);
    }
}

pub fn clearX() void {
    clearRegister(runtime.REGISTER_X);
}

pub fn clearStack() void {
    clearRange(runtime.REGISTER_X, runtime.getStackTop());
}

pub fn clearRegister(reg: runtime.calcRegister_t) void {
    if (runtime.lastIntegerBase == 0 and (runtime.inputDefault() == runtime.ID_43S or runtime.inputDefault() == runtime.ID_DP)) {
        if (runtime.getRegisterDataType(reg) == runtime.dtReal34) {
            memory_owned.zeroReal34(runtime.getRegisterDataPointer(reg));
            runtime.setRegisterDataType(reg, @intCast(runtime.dtReal34), runtime.amNone);
        } else {
            runtime.reallocateRegister(reg, runtime.dtReal34, 0, runtime.amNone);
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
            memory_owned.zeroReal34(runtime.getRegisterDataPointer(reg));
        }
        return;
    }

    if (runtime.lastIntegerBase == 0 and runtime.inputDefault() == runtime.ID_CPXDP) {
        const complex_tag = if (runtime.getSystemFlag(runtime.FLAG_POLAR)) runtime.currentAngularMode | runtime.amPolar else runtime.amNone;

        if (runtime.getRegisterDataType(reg) == runtime.dtComplex34) {
            const data_ptr = runtime.getRegisterDataPointer(reg);
            memory_owned.zeroReal34(data_ptr);
            memory_owned.zeroReal34(complexImagPointer(data_ptr));
            runtime.setRegisterDataType(reg, @intCast(runtime.dtComplex34), complex_tag);
        } else {
            runtime.reallocateRegister(reg, runtime.dtComplex34, runtime.real34SizeInBlocks() * 2, complex_tag);
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
            const data_ptr = runtime.getRegisterDataPointer(reg);
            memory_owned.zeroReal34(data_ptr);
            memory_owned.zeroReal34(complexImagPointer(data_ptr));
        }
        return;
    }

    if (runtime.lastIntegerBase == 0 and runtime.inputDefault() == runtime.ID_LI) {
        runtime.storeZeroLongInteger(reg);
        return;
    }

    if (runtime.lastIntegerBase != 0) {
        runtime.storeZeroShortInteger(reg, runtime.lastIntegerBase);
        return;
    }
}

pub fn clearRegisters(confirmation: u16) void {
    if (confirmation == runtime.NOT_CONFIRMED and runtime.programRunStop != runtime.PGM_RUNNING) {
        runtime.requestClearRegistersConfirmation();
        return;
    }

    clearRange(0, runtime.REGISTER_X - 1);

    var local_index: u8 = 0;
    const local_count = runtime.currentLocalRegisterCount();
    while (local_index < local_count) : (local_index += 1) {
        clearRegister(runtime.FIRST_LOCAL_REGISTER + @as(runtime.calcRegister_t, @intCast(local_index)));
    }

    if (!runtime.getSystemFlag(runtime.FLAG_SSIZE8)) {
        clearRange(runtime.REGISTER_A, runtime.REGISTER_D);
    }

    clearRange(runtime.REGISTER_I, runtime.REGISTER_W);
}
