const runtime = @import("stack_runtime.zig");

fn registerWithOffset(base: runtime.calcRegister_t, offset: u16) runtime.calcRegister_t {
    return base + @as(runtime.calcRegister_t, @intCast(offset));
}

fn complexImagPointer(dataPtr: ?*anyopaque) ?*anyopaque {
    const ptr = dataPtr orelse return null;
    const bytes: [*]align(1) u8 = @ptrCast(ptr);
    const imagOffset: usize = @intCast(runtime.bytesFromBlocks(runtime.real34SizeInBlocks()));
    return @ptrCast(bytes + imagOffset);
}

fn adjustResultArgumentIsComplex(reg: runtime.calcRegister_t) bool {
    if (reg < 0) {
        return false;
    }

    const dataType = runtime.getRegisterDataType(reg);
    return dataType == runtime.dtComplex34 or dataType == runtime.dtComplex34Matrix;
}

fn swapRegs(sourceReg: runtime.calcRegister_t, targetReg: u16) void {
    const savedDescriptor = runtime.globalDescriptor(sourceReg);
    var targetDescriptor: runtime.register_descriptor_t = 0;

    if (runtime.tryGetSwapTargetDescriptor(targetReg, &targetDescriptor)) {
        runtime.setGlobalDescriptor(sourceReg, targetDescriptor);
        _ = runtime.trySetSwapTargetDescriptor(targetReg, savedDescriptor);
        return;
    }

    runtime.reportInvalidSwapTarget(targetReg);
}

pub export fn fnClX(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    runtime.clearRegister(runtime.REGISTER_X);
}

pub export fn fnClearStack(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    const stackTop = runtime.getStackTop();
    var reg = runtime.REGISTER_X;
    while (reg <= stackTop) : (reg += 1) {
        runtime.clearRegister(reg);
    }
}

pub export fn clearRegister(reg: runtime.calcRegister_t) void {
    if (runtime.lastIntegerBase == 0 and (runtime.inputDefault() == runtime.ID_43S or runtime.inputDefault() == runtime.ID_DP)) {
        if (runtime.getRegisterDataType(reg) == runtime.dtReal34) {
            runtime.real34SetZero(runtime.getRegisterDataPointer(reg));
            runtime.setRegisterDataType(reg, @intCast(runtime.dtReal34), runtime.amNone);
        } else {
            runtime.reallocateRegister(reg, runtime.dtReal34, 0, runtime.amNone);
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
            runtime.real34SetZero(runtime.getRegisterDataPointer(reg));
        }
        return;
    }

    if (runtime.lastIntegerBase == 0 and runtime.inputDefault() == runtime.ID_CPXDP) {
        const complexTag = if (runtime.getSystemFlag(runtime.FLAG_POLAR)) runtime.currentAngularMode | runtime.amPolar else runtime.amNone;

        if (runtime.getRegisterDataType(reg) == runtime.dtComplex34) {
            const dataPtr = runtime.getRegisterDataPointer(reg);
            runtime.real34SetZero(dataPtr);
            runtime.real34SetZero(complexImagPointer(dataPtr));
            runtime.setRegisterDataType(reg, @intCast(runtime.dtComplex34), complexTag);
        } else {
            runtime.reallocateRegister(reg, runtime.dtComplex34, runtime.real34SizeInBlocks() * 2, complexTag);
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
            const dataPtr = runtime.getRegisterDataPointer(reg);
            runtime.real34SetZero(dataPtr);
            runtime.real34SetZero(complexImagPointer(dataPtr));
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

    runtime.clearRegisterRetained(reg);
}

pub export fn fnClearRegisters(confirmation: u16) void {
    if (confirmation == runtime.NOT_CONFIRMED and runtime.programRunStop != runtime.PGM_RUNNING) {
        runtime.requestClearRegistersConfirmation();
        return;
    }

    var reg: runtime.calcRegister_t = 0;
    while (reg < runtime.REGISTER_X) : (reg += 1) {
        runtime.clearRegister(reg);
    }

    var localIndex: u8 = 0;
    const localCount = runtime.currentLocalRegisterCount();
    while (localIndex < localCount) : (localIndex += 1) {
        runtime.clearRegister(runtime.FIRST_LOCAL_REGISTER + @as(runtime.calcRegister_t, @intCast(localIndex)));
    }

    if (!runtime.getSystemFlag(runtime.FLAG_SSIZE8)) {
        reg = runtime.REGISTER_A;
        while (reg <= runtime.REGISTER_D) : (reg += 1) {
            runtime.clearRegister(reg);
        }
    }

    reg = runtime.REGISTER_I;
    while (reg <= runtime.REGISTER_W) : (reg += 1) {
        runtime.clearRegister(reg);
    }
}

pub export fn fnRegClr(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    var startReg: u16 = 0;
    var count: u16 = 0;

    runtime.lastErrorCode = runtime.getRegClrRangeRetained(&startReg, &count);
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        var reg = startReg;
        while (reg < startReg + count) : (reg += 1) {
            runtime.clearRegister(@intCast(reg));
        }
        return;
    }

    runtime.reportRegisterCommandError(runtime.lastErrorCode);
}

pub export fn fnRegSwap(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    var sourceStart: u16 = 0;
    var count: u16 = 0;
    var destinationStart: u16 = 0;

    runtime.lastErrorCode = runtime.getRegSwapRangeRetained(&sourceStart, &count, &destinationStart);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    if (destinationStart < sourceStart + count and sourceStart < destinationStart + count) {
        runtime.reportRegisterCommandError(runtime.ERROR_OUT_OF_RANGE);
        return;
    }

    var index: u16 = 0;
    while (index < count) : (index += 1) {
        const sourceReg = @as(runtime.calcRegister_t, @intCast(sourceStart + index));
        const destinationReg = @as(runtime.calcRegister_t, @intCast(destinationStart + index));
        const savedDescriptor = runtime.globalDescriptor(sourceReg);
        runtime.setGlobalDescriptor(sourceReg, runtime.globalDescriptor(destinationReg));
        runtime.setGlobalDescriptor(destinationReg, savedDescriptor);
    }
}

pub export fn fnRegCopy(unusedButMandatoryParameter: u16) void {
    var partialLoad = false;
    var sourceStart: u16 = 0;
    var count: u16 = 0;
    var destinationStart: u16 = 0;

    runtime.lastErrorCode = runtime.getRegCopyParamsRetained(&partialLoad, &sourceStart, &count, &destinationStart);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    if (partialLoad) {
        _ = unusedButMandatoryParameter;
        runtime.doPartialRegisterLoad(sourceStart, count, destinationStart);
        return;
    }

    if (sourceStart > destinationStart) {
        var index: u16 = 0;
        while (index < count) : (index += 1) {
            runtime.copySourceRegisterToDestRegister(
                @as(runtime.calcRegister_t, @intCast(sourceStart + index)),
                @as(runtime.calcRegister_t, @intCast(destinationStart + index)),
            );
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
        }
        return;
    }

    if (sourceStart < destinationStart) {
        var index = count;
        while (index > 0) {
            index -= 1;
            runtime.copySourceRegisterToDestRegister(
                @as(runtime.calcRegister_t, @intCast(sourceStart + index)),
                @as(runtime.calcRegister_t, @intCast(destinationStart + index)),
            );
            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                return;
            }
        }
    }
}

pub export fn fnRegSort(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    var startReg: u16 = 0;
    var count: u16 = 0;

    runtime.lastErrorCode = runtime.getRegClrRangeRetained(&startReg, &count);
    if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.reportRegisterCommandError(runtime.lastErrorCode);
        return;
    }

    switch (runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(startReg)))) {
        runtime.dtLongInteger, runtime.dtShortInteger, runtime.dtReal34 => {
            var index: u16 = startReg + 1;
            while (index < startReg + count) : (index += 1) {
                const dataType = runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(index)));
                if (dataType != runtime.dtLongInteger and dataType != runtime.dtShortInteger and dataType != runtime.dtReal34) {
                    runtime.reportRegisterCommandError(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
                    return;
                }
            }
        },
        runtime.dtTime, runtime.dtDate, runtime.dtString => {
            const firstType = runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(startReg)));
            var index: u16 = startReg + 1;
            while (index < startReg + count) : (index += 1) {
                if (runtime.getRegisterDataType(@as(runtime.calcRegister_t, @intCast(index))) != firstType) {
                    runtime.reportRegisterCommandError(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP);
                    return;
                }
            }
        },
        else => {},
    }

    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.sortRegisterRange(startReg, startReg + count - 1);
    }
}

pub export fn fnToReal(unusedButMandatoryParameter: u16) void {
    if (runtime.tryFnToRealComplexZero()) {
        return;
    }

    if (runtime.tryFnToRealLongInteger()) {
        return;
    }

    if (runtime.tryFnToRealShortInteger()) {
        return;
    }

    if (runtime.tryFnToRealTime()) {
        return;
    }

    if (runtime.tryFnToRealDate()) {
        return;
    }

    if (runtime.tryFnToRealReal34()) {
        return;
    }

    runtime.toRealRetained(unusedButMandatoryParameter);
}

pub export fn adjustResult(res: runtime.calcRegister_t, dropY: bool, setCpxRes: bool, op1: runtime.calcRegister_t, op2: runtime.calcRegister_t, op3: runtime.calcRegister_t) void {
    const oneArgumentIsComplex = adjustResultArgumentIsComplex(op1) or adjustResultArgumentIsComplex(op2) or adjustResultArgumentIsComplex(op3);

    if (runtime.adjustResultScalarCore(res) or runtime.adjustResultRealMatrixCore(res) or runtime.adjustResultComplexMatrixCore(res)) {
        if (runtime.lastErrorCode != runtime.ERROR_NONE) {
            return;
        }
    } else if (runtime.lastErrorCode != runtime.ERROR_NONE) {
        runtime.undoRetained();
        return;
    }

    if (setCpxRes and oneArgumentIsComplex and runtime.getRegisterDataType(res) != runtime.dtString) {
        runtime.adjustResultSetCpxRes();
    }

    if (dropY) {
        fnDropY(0);
    }
}

pub export fn liftStack() void {
    const stackTop = runtime.getStackTop();

    if (runtime.getSystemFlag(runtime.FLAG_ASLIFT)) {
        if (runtime.currentInputVariable != runtime.INVALID_VARIABLE) {
            runtime.currentInputVariable |= @as(u16, 0x8000);
        }
        runtime.freeRegisterData(stackTop);

        var reg = stackTop;
        while (reg > runtime.REGISTER_X) : (reg -= 1) {
            runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg - 1));
        }
    } else {
        runtime.freeRegisterData(runtime.REGISTER_X);
    }

    runtime.setRegisterDataPointerMutable(runtime.REGISTER_X, runtime.allocC47Blocks(runtime.real34SizeInBlocks()));
    runtime.setRegisterDataType(runtime.REGISTER_X, @intCast(runtime.dtReal34), runtime.amNone);
}

pub export fn saveLastX() bool {
    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_X, runtime.REGISTER_L);
    return runtime.lastErrorCode == runtime.ERROR_NONE;
}

pub export fn fnGetLocR(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    liftStack();
    runtime.storeLocalRegisterCountInX();
}

pub export fn _Drop(reg: runtime.calcRegister_t) void {
    const stackTop = runtime.getStackTop();
    if (reg == stackTop) {
        return;
    }

    runtime.freeRegisterData(reg);

    var current = reg;
    while (current < stackTop) : (current += 1) {
        runtime.setGlobalDescriptor(current, runtime.globalDescriptor(current + 1));
    }

    const sizeInBlocks = runtime.getRegisterFullSizeInBlocks(stackTop);
    const dataPtr = runtime.allocC47Blocks(sizeInBlocks);
    if (dataPtr != null) {
        runtime.setRegisterDataPointerMutable(stackTop - 1, dataPtr);
        runtime.xcopyBlocks(
            runtime.getRegisterDataPointer(stackTop - 1),
            runtime.getRegisterDataPointer(stackTop),
            sizeInBlocks,
        );
    } else {
        runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
    }
}

pub export fn fnDrop(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    _Drop(runtime.REGISTER_X);
}

pub export fn fnDropY(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    _Drop(runtime.REGISTER_Y);
}

pub export fn fnDropZ(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    _Drop(runtime.REGISTER_Z);
}

pub export fn fnDropT(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    _Drop(runtime.REGISTER_T);
}

pub export fn fnDropN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 8));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        _Drop(runtime.REGISTER_X);
    }
}

pub export fn fnRollUp(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    const stackTop = runtime.getStackTop();
    const savedDescriptor = runtime.globalDescriptor(stackTop);

    var reg = stackTop;
    while (reg > runtime.REGISTER_X) : (reg -= 1) {
        runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg - 1));
    }
    runtime.setGlobalDescriptor(runtime.REGISTER_X, savedDescriptor);
}

pub export fn fnRollDown(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    const stackTop = runtime.getStackTop();
    const savedDescriptor = runtime.globalDescriptor(runtime.REGISTER_X);

    var reg = runtime.REGISTER_X;
    while (reg < stackTop) : (reg += 1) {
        runtime.setGlobalDescriptor(reg, runtime.globalDescriptor(reg + 1));
    }
    runtime.setGlobalDescriptor(stackTop, savedDescriptor);
}

pub export fn fnDisplayStack(numberOfStackLines: u16) void {
    runtime.displayStack = @intCast(numberOfStackLines);
}

pub export fn fnSwapX(reg: u16) void {
    swapRegs(runtime.REGISTER_X, reg);
}

pub export fn fnSwapY(reg: u16) void {
    swapRegs(runtime.REGISTER_Y, reg);
}

pub export fn fnSwapZ(reg: u16) void {
    swapRegs(runtime.REGISTER_Z, reg);
}

pub export fn fnSwapT(reg: u16) void {
    swapRegs(runtime.REGISTER_T, reg);
}

pub export fn fnSwapN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 4));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        swapRegs(registerWithOffset(runtime.REGISTER_X, index), @intCast(registerWithOffset(runtime.REGISTER_X, number + index)));
    }
}

pub export fn fnDupN(number: u16) void {
    const count: u16 = @min(number, @as(u16, 4));
    var index: u16 = 0;
    while (index < count) : (index += 1) {
        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
        runtime.fnRecall(@intCast(registerWithOffset(runtime.REGISTER_X, number - 1)));
    }
}

pub export fn fnSwapXY(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    const savedDescriptor = runtime.globalDescriptor(runtime.REGISTER_X);
    runtime.setGlobalDescriptor(runtime.REGISTER_X, runtime.globalDescriptor(runtime.REGISTER_Y));
    runtime.setGlobalDescriptor(runtime.REGISTER_Y, savedDescriptor);
}

pub export fn fnShuffle(registerOrder: u16) void {
    var index: u16 = 0;
    while (index < 4) : (index += 1) {
        const currentReg = registerWithOffset(runtime.REGISTER_X, index);
        const savedReg = registerWithOffset(runtime.SAVED_REGISTER_X, index);
        const savedDescriptor = runtime.globalDescriptor(currentReg);
        runtime.setGlobalDescriptor(currentReg, runtime.globalDescriptor(savedReg));
        runtime.setGlobalDescriptor(savedReg, savedDescriptor);
    }

    index = 0;
    while (index < 4) : (index += 1) {
        const registerOffset: u16 = (registerOrder >> @intCast(index * 2)) & 3;
        runtime.copySourceRegisterToDestRegister(registerWithOffset(runtime.SAVED_REGISTER_X, registerOffset), registerWithOffset(runtime.REGISTER_X, index));
    }
}

pub export fn fnFillStack(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    const stackTop = runtime.getStackTop();
    const dataTypeX = runtime.getRegisterDataType(runtime.REGISTER_X);
    const dataSizeXInBlocks = runtime.getRegisterFullSizeInBlocks(runtime.REGISTER_X);
    const tag = runtime.getRegisterTag(runtime.REGISTER_X);

    var reg = runtime.REGISTER_Y;
    while (reg <= stackTop) : (reg += 1) {
        runtime.freeRegisterData(reg);
        runtime.setRegisterDataType(reg, @intCast(dataTypeX), tag);

        const newDataPointer = runtime.allocC47Blocks(dataSizeXInBlocks);
        if (newDataPointer != null) {
            runtime.setRegisterDataPointerMutable(reg, newDataPointer);
            runtime.xcopyBlocks(newDataPointer, runtime.getRegisterDataPointer(runtime.REGISTER_X), dataSizeXInBlocks);
        } else {
            runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
            return;
        }
    }
}

pub export fn fnGetStackSize(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;

    liftStack();
    runtime.storeStackSizeInX(if (runtime.getSystemFlag(runtime.FLAG_SSIZE8)) 8 else 4);
}

pub export fn saveForUndo() void {
    runtime.saveForUndoRetained();
}

pub export fn fnUndo(unusedButMandatoryParameter: u16) void {
    _ = unusedButMandatoryParameter;
    if (runtime.thereIsSomethingToUndo) {
        undo();
    }
}

pub export fn undo() void {
    runtime.undoRetained();
}

pub export fn fillStackWithReal0() void {
    runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtReal34, 0, runtime.amNone);
    runtime.real34SetZero(runtime.getRegisterDataPointer(runtime.REGISTER_X));
    fnFillStack(0);
}
