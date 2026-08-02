const runtime = @import("../runtime/stack_runtime.zig");

fn savedRegisterFor(reg: runtime.calcRegister_t) runtime.calcRegister_t {
    // each live register's saved shadow sits a fixed offset away
    return runtime.SAVED_REGISTER_X - runtime.REGISTER_X + reg;
}

fn clearSavedStackRegisters() void {
    var reg = runtime.getStackTop();
    while (true) {
        runtime.clearRegister(savedRegisterFor(reg));
        if (reg == runtime.REGISTER_X) {
            break;
        }
        reg -= 1;
    }
}

pub fn saveForUndo() void {
    const mode_blocks_undo = runtime.calcMode == runtime.CM_NIM or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_MIM;
    if ((mode_blocks_undo and runtime.thereIsSomethingToUndo) or runtime.calcMode == runtime.CM_NO_UNDO) {
        return;
    }

    runtime.clearRegister(runtime.TEMP_REGISTER_2_SAVED_STATS);
    runtime.SAVED_SIGMA_lastAddRem = runtime.SIGMA_NONE;

    runtime.savedSystemFlags0 = runtime.systemFlags0;
    runtime.savedSystemFlags1 = runtime.systemFlags1;

    if (runtime.currentInputVariable != runtime.INVALID_VARIABLE) {
        if ((runtime.currentInputVariable & 0x8000) != 0) {
            runtime.currentInputVariable |= 0x4000;
        } else {
            runtime.currentInputVariable &= 0xbfff;
        }
    }

    if ((runtime.entryStatus & 0x01) != 0) {
        runtime.entryStatus |= 0x02;
    } else {
        runtime.entryStatus &= 0xfd;
    }

    var reg = runtime.getStackTop();
    while (true) {
        runtime.copySourceRegisterToDestRegister(reg, savedRegisterFor(reg));
        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
            clearSavedStackRegisters();
            runtime.clearRegister(runtime.SAVED_REGISTER_L);
            runtime.thereIsSomethingToUndo = false;
            runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
            return;
        }
        if (reg == runtime.REGISTER_X) {
            break;
        }
        reg -= 1;
    }

    runtime.copySourceRegisterToDestRegister(runtime.REGISTER_L, runtime.SAVED_REGISTER_L);
    if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
        clearSavedStackRegisters();
        runtime.clearRegister(runtime.SAVED_REGISTER_L);
        runtime.thereIsSomethingToUndo = false;
        runtime.lastErrorCode = runtime.ERROR_RAM_FULL;
        return;
    }

    runtime.lrSelectionUndo = runtime.lrSelection;
    if (runtime.statisticalSumsPointer == null) {
        runtime.freeC47Blocks(runtime.savedStatisticalSumsPointer, runtime.statisticalSumsBlocks());
        runtime.savedStatisticalSumsPointer = null;
    } else {
        runtime.lrChosenUndo = runtime.lrChosen;
        if (runtime.savedStatisticalSumsPointer == null) {
            runtime.savedStatisticalSumsPointer = runtime.allocC47Blocks(runtime.statisticalSumsBlocks());
        }
        _ = runtime.xcopy(runtime.savedStatisticalSumsPointer, runtime.statisticalSumsPointer, runtime.statisticalSumsBytes());
    }

    runtime.thereIsSomethingToUndo = true;
}

pub fn fnUndo() void {
    if (runtime.thereIsSomethingToUndo) {
        undo();
    }
}

pub fn undo() void {
    const was_solving = runtime.getSystemFlag(runtime.FLAG_SOLVING);
    const was_inting = runtime.getSystemFlag(runtime.FLAG_INTING);

    const last_error_code_mem = runtime.lastErrorCode;
    runtime.lastErrorCode = runtime.ERROR_NONE;
    runtime.recallStatsMatrix();
    if (runtime.lastErrorCode == runtime.ERROR_NONE) {
        runtime.lastErrorCode = last_error_code_mem;
    }

    if (runtime.currentInputVariable != runtime.INVALID_VARIABLE) {
        if ((runtime.currentInputVariable & 0x4000) != 0) {
            runtime.currentInputVariable |= 0x8000;
        } else {
            runtime.currentInputVariable &= 0x7fff;
        }
    }

    if ((runtime.entryStatus & 0x02) != 0) {
        runtime.entryStatus |= 0x01;
    } else {
        runtime.entryStatus &= 0xfe;
    }

    if (runtime.SAVED_SIGMA_lastAddRem == runtime.SIGMA_PLUS and runtime.statisticalSumsPointer != null) {
        runtime.fnSigmaAddRem(runtime.SIGMA_MINUS);
    } else if (runtime.SAVED_SIGMA_lastAddRem == runtime.SIGMA_MINUS and runtime.statisticalSumsPointer != null) {
        runtime.restoreSavedSigmaLastXYAndAdd();
    }

    runtime.systemFlags0 = runtime.savedSystemFlags0;
    runtime.systemFlags1 = runtime.savedSystemFlags1;

    var reg = runtime.getStackTop();
    while (true) {
        runtime.copySourceRegisterToDestRegister(savedRegisterFor(reg), reg);
        if (reg == runtime.REGISTER_X) {
            break;
        }
        reg -= 1;
    }

    runtime.copySourceRegisterToDestRegister(runtime.SAVED_REGISTER_L, runtime.REGISTER_L);

    runtime.lrSelection = runtime.lrSelectionUndo;
    if (runtime.savedStatisticalSumsPointer == null) {
        runtime.freeC47Blocks(runtime.statisticalSumsPointer, runtime.statisticalSumsBlocks());
        runtime.statisticalSumsPointer = null;
        runtime.lrChosen = 0;
    } else {
        runtime.lrChosen = runtime.lrChosenUndo;
        if (runtime.statisticalSumsPointer == null) {
            runtime.statisticalSumsPointer = runtime.allocC47Blocks(runtime.statisticalSumsBlocks());
        }
        _ = runtime.xcopy(runtime.statisticalSumsPointer, runtime.savedStatisticalSumsPointer, runtime.statisticalSumsBytes());
    }

    runtime.SAVED_SIGMA_lastAddRem = runtime.SIGMA_NONE;
    runtime.thereIsSomethingToUndo = false;
    runtime.clearRegister(runtime.TEMP_REGISTER_2_SAVED_STATS);

    if (was_solving != runtime.getSystemFlag(runtime.FLAG_SOLVING)) {
        runtime.flipSystemFlag(runtime.FLAG_SOLVING);
    }
    if (was_inting != runtime.getSystemFlag(runtime.FLAG_INTING)) {
        runtime.flipSystemFlag(runtime.FLAG_INTING);
    }
}
