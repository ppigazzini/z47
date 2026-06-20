pub fn implementation(comptime runtime: type) type {
    return struct {
        fn isGraphMode() bool {
            return runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH;
        }

        fn canHandleFlagBrowserArrowProcess(item: i16) bool {
            if (item != runtime.ITM_UP1_ITEM and item != runtime.ITM_DOWN1_ITEM) {
                return false;
            }

            return runtime.calcMode == runtime.CM_FLAG_BROWSER and
                runtime.tam.mode == 0 and
                runtime.lastErrorCode == 0 and
                runtime.temporaryInformation == runtime.TI_NO_INFO and
                runtime.programRunStop != runtime.PGM_WAITING and
                !isGraphMode();
        }

        fn itemIsUppercaseLetter(item: i32) bool {
            return item >= runtime.ITM_A and item <= runtime.ITM_Z;
        }

        fn itemIsLowercaseLetter(item: i32) bool {
            return item >= runtime.ITM_a and item <= runtime.ITM_z;
        }

        pub fn caseReplacements(lower_case_selected: runtime.bool_t, item: i16, item_out: *i16) runtime.bool_t {
            item_out.* = item;

            if (lower_case_selected and itemIsUppercaseLetter(item)) {
                item_out.* = item + @as(i16, @intCast(runtime.ITM_a - runtime.ITM_A));
                return true;
            }

            if (!lower_case_selected and itemIsUppercaseLetter(item)) {
                return true;
            }

            if (!lower_case_selected and itemIsLowercaseLetter(item)) {
                item_out.* = item - @as(i16, @intCast(runtime.ITM_a - runtime.ITM_A));
                return true;
            }

            if (lower_case_selected and itemIsLowercaseLetter(item)) {
                return true;
            }

            return false;
        }

        pub fn keyReplacements(item: i16, item1: *i16, numlock_enabled: runtime.bool_t, f_shift: runtime.bool_t, g_shift: runtime.bool_t) runtime.bool_t {
            if (!(runtime.calcMode == runtime.CM_AIM or
                runtime.calcMode == runtime.CM_EIM or
                runtime.calcMode == runtime.CM_PEM or
                (runtime.tam.mode != 0 and runtime.tam.alpha) or
                (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned == 0)))
            {
                return item1.* != 0;
            }

            if (g_shift) {
                switch (item) {
                    runtime.ITM_sigma => item1.* = runtime.ITM_SIGMA,
                    runtime.ITM_delta => item1.* = runtime.ITM_DELTA,
                    runtime.ITM_NULL => item1.* = runtime.ITM_SPACE,
                    else => {},
                }
            } else if (numlock_enabled) {
                var normalized_item = item;
                if (item >= runtime.ITM_A + 26 and item <= runtime.ITM_Z + 26) {
                    normalized_item += 26;
                }

                var index: usize = 15;
                while (index < 37) : (index += 1) {
                    const std_key = runtime.kbdStdAt(index);

                    if (std_key.primaryAim == runtime.ITM_EXIT1 or
                        std_key.primaryAim == runtime.ITM_UP1 or
                        std_key.primaryAim == runtime.ITM_DOWN1 or
                        std_key.primaryAim == runtime.ITM_BACKSPACE)
                    {
                        continue;
                    }

                    if (!f_shift and normalized_item == std_key.primaryAim) {
                        const key = if (runtime.getSystemFlag(runtime.FLAG_USER)) runtime.kbd_usr[index] else std_key;
                        item1.* = key.gShiftedAim;
                        break;
                    }

                    if (f_shift and index >= 31 and normalized_item == std_key.gShiftedAim) {
                        const key = if (runtime.getSystemFlag(runtime.FLAG_USER)) runtime.kbd_usr[index] else std_key;
                        item1.* = key.primaryAim;
                        break;
                    }
                }
            }

            return item1.* != 0;
        }

        pub fn numlockReplacements(item: i16, numlock_enabled: runtime.bool_t, f_shift: runtime.bool_t, g_shift: runtime.bool_t) u16 {
            var item1: i16 = 0;
            if (keyReplacements(item, &item1, numlock_enabled, f_shift, g_shift)) {
                return runtime.maxAbs(item1);
            }

            return runtime.maxAbs(item);
        }

        pub fn setLastKeyCode(key: i32) void {
            if (key < 1 or key > 43) {
                return;
            }

            if (key <= 6) {
                runtime.lastKeyCode = @intCast(key + 20);
            } else if (key <= 12) {
                runtime.lastKeyCode = @intCast(key - 6 + 30);
            } else if (key <= 17) {
                runtime.lastKeyCode = @intCast(key - 12 + 40);
            } else if (key <= 22) {
                runtime.lastKeyCode = @intCast(key - 17 + 50);
            } else if (key <= 27) {
                runtime.lastKeyCode = @intCast(key - 22 + 60);
            } else if (key <= 32) {
                runtime.lastKeyCode = @intCast(key - 27 + 70);
            } else if (key <= 37) {
                runtime.lastKeyCode = @intCast(key - 32 + 80);
            } else {
                runtime.lastKeyCode = @intCast(key - 37 + 10);
            }
        }

        pub fn processKeyAction(item: i16) void {
            if (canHandleFlagBrowserArrowProcess(item)) {
                runtime.keyActionProcessed = false;
                runtime.keyActionProcessed = true;

                if (item == runtime.ITM_UP1_ITEM) {
                    keyUp(0);
                    runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_STACK);
                    runtime.refreshScreen(118);
                } else {
                    keyDown(0);
                    runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_STACK);
                    runtime.refreshScreen(119);
                }

                runtime.keyActionProcessed = true;
                return;
            }

            runtime.processKeyActionRetained(item);
        }

        pub fn keyEnter(unused_but_mandatory_parameter: u16) void {
            runtime.keyEnterRetained(unused_but_mandatory_parameter);
        }

        pub fn keyExit(unused_but_mandatory_parameter: u16) void {
            runtime.keyExitRetained(unused_but_mandatory_parameter);
        }

        // fnKeyCC type-check macros (keyboard.c:4061-4063).
        fn ccIsAngle(typ: u8, tag: u8) bool {
            return typ == runtime.dtReal34 and tag != runtime.amNone;
        }
        fn ccIsValidAngle(typ: u8, tag: u8) bool {
            _ = tag;
            return typ == runtime.dtLongInteger or typ == runtime.dtReal34;
        }
        fn ccIsRadius(typ: u8, tag: u8) bool {
            return typ == runtime.dtLongInteger or (typ == runtime.dtReal34 and tag == runtime.amNone);
        }

        pub fn keyCC(complex_type: u16) void {
            const key_complex: u16 = @intCast(runtime.KEY_COMPLEX);
            runtime.doRefreshSoftMenu = true;
            if (runtime.calcMode == runtime.CM_NIM and complex_type == key_complex) {
                runtime.addItemToNimBuffer(runtime.ITM_EXIT1); // Allow COMPLEX from NIM
            }

            if (runtime.calcMode == runtime.CM_NORMAL or (runtime.calcMode == runtime.CM_NIM and complex_type == key_complex)) {
                var sdataTypeX: u8 = @intCast(runtime.getRegisterDataType(runtime.REGISTER_X));
                var sdataAtagX: u8 = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_X));
                var sdataTypeY: u8 = @intCast(runtime.getRegisterDataType(runtime.REGISTER_Y));
                var sdataAtagY: u8 = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_Y));
                var toClearPolar = false;
                if (runtime.getSystemFlag(runtime.FLAG_POLAR) and ccIsAngle(sdataTypeY, sdataAtagY) and ccIsRadius(sdataTypeX, sdataAtagX)) {
                    runtime.fnSwapXY(0);
                } else if (!runtime.getSystemFlag(runtime.FLAG_POLAR) and ccIsAngle(sdataTypeY, sdataAtagY) and ccIsRadius(sdataTypeX, sdataAtagX)) {
                    runtime.fnSwapXY(0);
                    runtime.setSystemFlag(@intCast(runtime.FLAG_POLAR));
                    toClearPolar = true;
                } else if (!runtime.getSystemFlag(runtime.FLAG_POLAR) and ccIsAngle(sdataTypeX, sdataAtagX) and ccIsRadius(sdataTypeY, sdataAtagY)) {
                    runtime.setSystemFlag(@intCast(runtime.FLAG_POLAR));
                    toClearPolar = true;
                }

                sdataTypeX = @intCast(runtime.getRegisterDataType(runtime.REGISTER_X));
                sdataTypeY = @intCast(runtime.getRegisterDataType(runtime.REGISTER_Y));
                sdataAtagX = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_X));
                sdataAtagY = @intCast(runtime.getRegisterAngularMode(runtime.REGISTER_Y));

                const polarOk = ccIsRadius(sdataTypeY, sdataAtagY) and ccIsValidAngle(sdataTypeX, sdataAtagX) and runtime.getSystemFlag(runtime.FLAG_POLAR);
                const rectOk = ccIsRadius(sdataTypeY, sdataAtagY) and ccIsRadius(sdataTypeX, sdataAtagX) and !runtime.getSystemFlag(runtime.FLAG_POLAR);

                if (polarOk or rectOk) {
                    runtime.fnReToCx(0);
                } else if (sdataTypeX == runtime.dtComplex34) {
                    runtime.fnCxToRe(0);
                } else if (sdataTypeX == runtime.dtReal34Matrix and sdataTypeY == runtime.dtReal34Matrix) {
                    runtime.fnReToCx(0);
                } else if (sdataTypeX == runtime.dtComplex34Matrix) {
                    runtime.fnCxToRe(0);
                } else {
                    if ((!polarOk and runtime.getSystemFlag(runtime.FLAG_POLAR)) or (!rectOk and !runtime.getSystemFlag(runtime.FLAG_POLAR))) {
                        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_POLAR_RECT, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                    } else {
                        runtime.displayCalcErrorMessage(runtime.ERROR_INVALID_DATA_TYPE_FOR_OP, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                    }
                    if (comptime !runtime.is_dmcp_build) { // EXTRA_INFO_ON_CALC_ERROR
                        const dtnX = runtime.getDataTypeName(@intCast(runtime.getRegisterDataType(runtime.REGISTER_X)), true, false);
                        const dtnY = runtime.getDataTypeName(@intCast(runtime.getRegisterDataType(runtime.REGISTER_Y)), true, false);
                        if (!polarOk and runtime.getSystemFlag(runtime.FLAG_POLAR)) {
                            _ = runtime.sprintf(runtime.errorMessage, "You cannot use CC or COMPLEX to create a Polar complex number with %s(%s) in X and %s(%s) in Y!", dtnX, runtime.getRegisterTagName(runtime.REGISTER_X, false), dtnY, runtime.getRegisterTagName(runtime.REGISTER_Y, false));
                        } else if (!rectOk and !runtime.getSystemFlag(runtime.FLAG_POLAR)) {
                            _ = runtime.sprintf(runtime.errorMessage, "You cannot use CC or COMPLEX to create a Rectangular complex number with %s(%s) in X and %s(%s) in Y!", dtnX, runtime.getRegisterTagName(runtime.REGISTER_X, false), dtnY, runtime.getRegisterTagName(runtime.REGISTER_Y, false));
                        } else {
                            _ = runtime.sprintf(runtime.errorMessage, "You cannot use CC or COMPLEX with %s in X and %s in Y!", dtnX, dtnY);
                            runtime.moreInfoOnError("In function fnKeyCC:", runtime.errorMessage, null, null);
                        }
                    }
                }
                if (toClearPolar) {
                    runtime.clearSystemFlag(@intCast(runtime.FLAG_POLAR));
                }
                return;
            }

            if (complex_type == @as(u16, @intCast(runtime.ITM_op_j))) {
                runtime.temporaryFlagRect = true;
                runtime.temporaryFlagPolar = false;
            } else if (complex_type == @as(u16, @intCast(runtime.ITM_op_j_pol))) {
                runtime.temporaryFlagRect = false;
                runtime.temporaryFlagPolar = true;
            } else {
                runtime.temporaryFlagRect = false;
                runtime.temporaryFlagPolar = false;
            }

            switch (runtime.calcMode) {
                runtime.CM_NIM => runtime.addItemToNimBuffer(runtime.ITM_CC),
                runtime.CM_MIM => runtime.mimAddNumber(runtime.ITM_CC),
                runtime.CM_PEM => {
                    if (runtime.aimBuffer[0] != 0 and !runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                        runtime.pemAddNumber(runtime.ITM_CC, true);
                    }
                },
                runtime.CM_EIM,
                runtime.CM_REGISTER_BROWSER,
                runtime.CM_FLAG_BROWSER,
                runtime.CM_ASN_BROWSER,
                runtime.CM_FONT_BROWSER,
                runtime.CM_PLOT_STAT,
                runtime.CM_TIMER,
                runtime.CM_LISTXY,
                runtime.CM_GRAPH,
                => {},
                else => runtime.bugScreenWhileProcKey("fnKeyCC", "CC"),
            }
        }

        pub fn keyBackspace(unused_but_mandatory_parameter: u16) void {
            if (runtime.tam.mode == 0 and runtime.calcMode == runtime.CM_NIM) {
                runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE_ITEM);
                runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_SKIP_STACK_ONE_TIME);
                return;
            }

            runtime.keyBackspaceRetained(unused_but_mandatory_parameter);
        }

        pub fn keyUp(unused_but_mandatory_parameter: u16) void {
            switch (runtime.calcMode) {
                runtime.CM_FLAG_BROWSER => {
                    runtime.currentFlgScr +%= 1;
                    return;
                },
                runtime.CM_LISTXY => {
                    runtime.ListXYposition += 10;
                    runtime.keyActionProcessed = true;
                    return;
                },
                else => {},
            }

            runtime.keyUpRetained(unused_but_mandatory_parameter);
        }

        pub fn keyDown(unused_but_mandatory_parameter: u16) void {
            switch (runtime.calcMode) {
                runtime.CM_FLAG_BROWSER => {
                    runtime.currentFlgScr -%= 1;
                    return;
                },
                runtime.CM_LISTXY => {
                    runtime.ListXYposition -= 10;
                    runtime.keyActionProcessed = true;
                    return;
                },
                else => {},
            }

            runtime.keyDownRetained(unused_but_mandatory_parameter);
        }

        pub fn keyDotD(unused_but_mandatory_parameter: u16) void {
            _ = unused_but_mandatory_parameter;
            switch (runtime.calcMode) {
                runtime.CM_NORMAL => {
                    const flag = if (runtime.getSystemFlag(runtime.FLAG_IRFRQ)) runtime.FLAG_IRFRAC else runtime.FLAG_FRACT;
                    if (runtime.getSystemFlag(@intCast(flag))) {
                        runtime.clearSystemFlag(flag);
                    } else {
                        runtime.runFunction(runtime.ITM_toREAL);
                    }
                    return;
                },
                runtime.CM_NIM => {
                    runtime.addItemToNimBuffer(runtime.ITM_dotD);
                    return;
                },
                runtime.CM_REGISTER_BROWSER,
                runtime.CM_FLAG_BROWSER,
                runtime.CM_ASN_BROWSER,
                runtime.CM_FONT_BROWSER,
                runtime.CM_PLOT_STAT,
                runtime.CM_GRAPH,
                runtime.CM_MIM,
                runtime.CM_EIM,
                runtime.CM_TIMER,
                runtime.CM_LISTXY,
                => return,
                else => runtime.bugScreenWhileProcKey("fnKeyDotD", ".d!"),
            }
        }
    };
}
