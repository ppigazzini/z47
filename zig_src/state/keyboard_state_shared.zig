pub fn implementation(comptime runtime: type) type {
    return struct {
        fn isGraphMode() bool {
            return runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH;
        }

        fn canHandleFlagBrowserArrowProcess(item: i16) bool {
            if (item != runtime.ITM_UP1 and item != runtime.ITM_DOWN1) {
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

                if (item == runtime.ITM_UP1) {
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

        // fnKeyEnter goto targets (keyboard.c labels at the tail of the function).
        fn keyEnterRamFull() void {
            runtime.displayCalcErrorMessage(runtime.ERROR_RAM_FULL, runtime.ERR_REGISTER_LINE, runtime.NIM_REGISTER_LINE);
            runtime.fnUndo(runtime.NOPARAM);
        }
        fn keyEnterUndoDisabled() void {
            runtime.temporaryInformation = runtime.TI_UNDO_DISABLED;
        }

        pub fn keyEnter(unused_but_mandatory_parameter: u16) void {
            _ = unused_but_mandatory_parameter;
            runtime.doRefreshSoftMenu = true;
            switch (runtime.calcMode) {
                runtime.CM_NORMAL => {
                    if (!runtime.getSystemFlag(runtime.FLAG_ERPN) or
                        (!runtime.nimWhenButtonPressed and runtime.programRunStop != runtime.PGM_RUNNING) or
                        (runtime.getSystemFlag(runtime.FLAG_ERPN) and runtime.programRunStop == runtime.PGM_RUNNING))
                    {
                        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                        runtime.saveForUndo();
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            keyEnterUndoDisabled();
                            return;
                        }
                        runtime.liftStack();
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            keyEnterRamFull();
                            return;
                        }
                        runtime.copySourceRegisterToDestRegister(runtime.REGISTER_Y, runtime.REGISTER_X);
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            keyEnterRamFull();
                            return;
                        }
                    }

                    if (runtime.getSystemFlag(runtime.FLAG_ERPN)) {
                        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                    } else {
                        runtime.clearSystemFlag(runtime.FLAG_ASLIFT);
                    }
                },

                runtime.CM_AIM => {
                    if (runtime.softmenuStack[0].softmenuId <= 1 or runtime.menu(1) == -runtime.MNU_ALPHA) {
                        runtime.popSoftmenu();
                    }
                    if (runtime.currentMenu() == -runtime.MNU_ALPHA) { // leave the ALPHA menu, go to MyM
                        runtime.softmenuStack[0].softmenuId = 1;
                    }

                    runtime.calcModeNormal();
                    runtime.popSoftmenu();

                    if (runtime.aimBuffer[0] == 0) {
                        runtime.undo();
                    } else {
                        const lenInBytes: i16 = @intCast(runtime.strlen(runtime.aimBuffer) + 1);

                        runtime.reallocateRegister(runtime.REGISTER_X, runtime.dtString, runtime.toBlocks(@intCast(lenInBytes)), runtime.amNone);
                        _ = runtime.xcopy(runtime.registerStringData(runtime.REGISTER_X), runtime.aimBuffer, @intCast(lenInBytes));

                        runtime.printTraceX(runtime.LINE_FULL); // IR_PRINTING

                        if (!runtime.getSystemFlag(runtime.FLAG_ERPN)) {
                            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                            runtime.saveForUndo();
                            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                                keyEnterUndoDisabled();
                                return;
                            }
                            runtime.liftStack();
                            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                                keyEnterRamFull();
                                return;
                            }
                            runtime.clearSystemFlag(runtime.FLAG_ASLIFT);

                            runtime.copySourceRegisterToDestRegister(runtime.REGISTER_Y, runtime.REGISTER_X);
                            if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                                keyEnterRamFull();
                                return;
                            }
                            runtime.aimBuffer[0] = 0;
                        } else {
                            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                            runtime.aimBuffer[0] = 0;
                        }
                    }
                },

                runtime.CM_MIM => {
                    runtime.mimEnter(false);
                },

                runtime.CM_NIM => {
                    runtime.closeNim();

                    if (runtime.calcMode != runtime.CM_NIM and runtime.lastErrorCode == 0) {
                        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                        runtime.saveForUndo();
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            keyEnterUndoDisabled();
                            return;
                        }
                        runtime.liftStack();
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            keyEnterRamFull();
                            return;
                        }
                        runtime.clearSystemFlag(runtime.FLAG_ASLIFT);
                        runtime.copySourceRegisterToDestRegister(runtime.REGISTER_Y, runtime.REGISTER_X);
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            keyEnterRamFull();
                            return;
                        }
                    }
                },

                runtime.CM_EIM => {
                    if (runtime.aimBuffer[0] != 0) {
                        runtime.setEquation(runtime.currentFormula, runtime.aimBuffer);
                        runtime.parseEquation(runtime.currentFormula, runtime.EQUATION_PARSER_MVAR, runtime.aimBuffer, runtime.tmpString);
                        if (runtime.lastErrorCode != 0) { // Stay in Edit mode for the current equation
                            if (runtime.toPcMemPtr(runtime.allFormulae[@intCast(runtime.currentFormula)].pointerToFormulaData)) |equationString| {
                                _ = runtime.xcopy(runtime.aimBuffer, equationString, @intCast(runtime.strlen(equationString) + 1));
                            } else {
                                runtime.aimBuffer[0] = 0;
                            }
                            runtime.refreshRegisterLine(runtime.ERR_REGISTER_LINE);
                            return;
                        }
                    }
                    if (runtime.currentMenu() == -runtime.MNU_EQ_EDIT) {
                        runtime.calcModeNormal();
                        if (runtime.allFormulae[@intCast(runtime.currentFormula)].pointerToFormulaData == runtime.C47_NULL) {
                            runtime.deleteEquation(runtime.currentFormula);
                        }
                    }
                    runtime.popSoftmenu();
                },

                runtime.CM_REGISTER_BROWSER,
                runtime.CM_FLAG_BROWSER,
                runtime.CM_ASN_BROWSER,
                runtime.CM_FONT_BROWSER,
                runtime.CM_ERROR_MESSAGE,
                runtime.CM_BUG_ON_SCREEN,
                runtime.CM_PLOT_STAT,
                runtime.CM_LISTXY,
                runtime.CM_GRAPH,
                => {},

                runtime.CM_TIMER => {
                    runtime.fnRegAddTimerApp(runtime.NOPARAM); // ENTER
                },

                runtime.CM_CONFIRMATION => {
                    runtime.temporaryInformation = runtime.TI_ARE_YOU_SURE; // Keep confirmation message on screen
                },

                else => runtime.bugScreenWhileProcKey("fnKeyEnter", "ENTER"),
            }
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
            _ = unused_but_mandatory_parameter;

            if (runtime.tam.mode != 0) {
                runtime.tamProcessInput(@intCast(runtime.ITM_BACKSPACE));
                return;
            }

            switch (runtime.calcMode) {
                runtime.CM_NORMAL => {
                    if (runtime.temporaryInformation == runtime.TI_VIEW_REGISTER) {
                        runtime.temporaryInformation = runtime.TI_NO_INFO;
                        runtime.keyActionProcessed = true;
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                        return;
                    } else if (runtime.isShowMode()) {
                        runtime.temporaryInformation = runtime.TI_NO_INFO;
                        runtime.keyActionProcessed = true;
                        runtime.closeShowMenu();
                        return;
                    } else if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
                        return;
                    } else {
                        if (runtime.temporaryInformation != runtime.TI_NO_INFO) {
                            runtime.temporaryInformation = runtime.TI_NO_INFO;
                            runtime.keyActionProcessed = true;
                            runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                            runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                            if (runtime.lastErrorCode != 0) {
                                runtime.lastErrorCode = 0;
                            }
                        }
                        if (runtime.getSystemFlag(runtime.FLAG_CLX_DROP)) {
                            runtime.showFunctionName(runtime.ITM_DROP, 1000, "");
                        } else {
                            runtime.showFunctionName(runtime.ITM_CLX, 1000, "");
                        }
                    }
                },

                runtime.CM_AIM => {
                    if (runtime.catalog != 0 and runtime.catalog != runtime.CATALOG_MVAR) {
                        if (runtime.strlen(runtime.aimBuffer) > 0) {
                            const lg: usize = @intCast(runtime.stringLastGlyph(runtime.aimBuffer));
                            runtime.aimBuffer[lg] = 0;
                            runtime.xCursor = runtime.showString(runtime.aimBuffer, runtime.standardFont, 1, runtime.Y_POSITION_OF_AIM_LINE + 6, runtime.vmNormal, true, true);
                        }
                    } else if (runtime.strlen(runtime.aimBuffer) > 0) {
                        // TEXT_MULTILINE_EDIT: split the buffer at the cursor, drop the
                        // glyph before it, then rejoin the tail.
                        const t_cursor: usize = @intCast(runtime.T_cursorPos);
                        const t_cursor_tmp = runtime.aimBuffer[t_cursor];
                        runtime.aimBuffer[t_cursor] = 0;
                        const lg: usize = @intCast(runtime.stringLastGlyph(runtime.aimBuffer));
                        runtime.aimBuffer[lg] = 0;
                        runtime.aimBuffer[t_cursor] = t_cursor_tmp;
                        var ix: usize = 0;
                        while (runtime.aimBuffer[ix + t_cursor] != 0) : (ix += 1) {
                            runtime.aimBuffer[ix + lg] = runtime.aimBuffer[ix + t_cursor];
                        }
                        runtime.aimBuffer[ix + lg] = 0;
                        if (runtime.T_cursorPos <= 1 + runtime.stringLastGlyph(runtime.aimBuffer)) {
                            runtime.fnT_ARROW(runtime.ITM_T_LEFT_ARROW);
                        }
                    }
                },

                runtime.CM_NIM => {
                    runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE);
                    runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_SKIP_STACK_ONE_TIME);
                },

                runtime.CM_MIM => {
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                    } else {
                        runtime.mimAddNumber(runtime.ITM_BACKSPACE);
                    }
                },

                runtime.CM_EIM => {
                    if (runtime.xCursor > 0) {
                        const buf = runtime.aimBuffer;
                        const lst: usize = @intCast(runtime.stringNextGlyph(buf, runtime.stringLastGlyph(buf)));
                        runtime.xCursor -= 1;
                        var dst: usize = 0;
                        var i: u32 = 0;
                        while (i < runtime.xCursor) : (i += 1) {
                            dst += if ((buf[dst] & 0x80) != 0) @as(usize, 2) else 1;
                        }
                        var src: usize = dst + (if ((buf[dst] & 0x80) != 0) @as(usize, 2) else 1);
                        while (src <= lst) {
                            buf[dst] = buf[src];
                            dst += 1;
                            src += 1;
                        }
                    }
                },

                runtime.CM_REGISTER_BROWSER, runtime.CM_FLAG_BROWSER, runtime.CM_FONT_BROWSER => {
                    runtime.calcMode = runtime.previousCalcMode;
                },

                runtime.CM_ASN_BROWSER => {
                    keyExit(runtime.NOPARAM); // Rather use the Exit routine as the code is the same
                },

                runtime.CM_BUG_ON_SCREEN,
                runtime.CM_LISTXY,
                runtime.CM_GRAPH,
                runtime.CM_PLOT_STAT,
                runtime.CM_CONFIRMATION,
                => {
                    runtime.temporaryInformation = runtime.TI_ARE_YOU_SURE; // Keep confirmation message on screen
                    if (runtime.programRunStop == runtime.PGM_WAITING) {
                        runtime.programRunStop = runtime.PGM_STOPPED;
                    }
                },

                runtime.CM_PEM => {
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                        return;
                    }
                    if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                        runtime.pemAlpha(runtime.ITM_BACKSPACE);
                        if (runtime.aimBuffer[0] == 0 and runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                            // close if no characters left
                            runtime.pemAlpha(runtime.ITM_BACKSPACE);
                        }
                        if (runtime.aimBuffer[0] == 0 and !runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                            if (runtime.currentLocalStepNumber > 1) {
                                runtime.currentLocalStepNumber -= 1;
                                runtime.defineCurrentStep();
                                if (!runtime.programListEnd) {
                                    runtime.scrollPemBackwards();
                                }
                            } else {
                                runtime.pemCursorIsZerothStep = true;
                            }
                        }
                    } else if (runtime.aimBuffer[0] == 0) {
                        if (runtime.currentLocalStepNumber > 1) {
                            runtime.pemCursorIsZerothStep = false;
                        }
                        if (!runtime.pemCursorIsZerothStep) {
                            const next_step = runtime.findNextStep(runtime.currentStep);
                            if (runtime.currentStep[0] != 255 or runtime.currentStep[1] != 255) { // Not the last END
                                runtime.deleteStepsFromTo(runtime.currentStep, next_step);
                            }
                            if (runtime.currentLocalStepNumber > 1) {
                                runtime.currentLocalStepNumber -= 1;
                                runtime.defineCurrentStep();
                            } else {
                                runtime.pemCursorIsZerothStep = true;
                            }
                            runtime.scrollPemBackwards();
                        }
                    } else {
                        runtime.pemAddNumber(runtime.ITM_BACKSPACE, true);
                        if (runtime.aimBuffer[0] == 0 and runtime.currentLocalStepNumber > 1) {
                            runtime.currentStep = runtime.findPreviousStep(runtime.currentStep);
                            runtime.currentLocalStepNumber -= 1;
                            if (!runtime.programListEnd) {
                                runtime.scrollPemBackwards();
                            }
                        }
                    }
                },

                runtime.CM_ASSIGN => {
                    if (runtime.itemToBeAssigned == 0) {
                        if (!runtime.tam.alpha) {
                            runtime.calcMode = runtime.previousCalcMode;
                            runtime.showFunctionName(runtime.ITM_CLX, 1000, "");
                        } else if (runtime.strlen(runtime.aimBuffer) != 0) {
                            // Delete the character before the cursor
                            if (runtime.alphaCursor > 0) {
                                runtime.deleteAlphaCharacter(&runtime.alphaCursor);
                            }
                        } else {
                            runtime.assignLeaveAlpha();
                            runtime.itemToBeAssigned = runtime.ITM_BACKSPACE;
                        }
                    } else {
                        if (!runtime.tam.alpha) {
                            runtime.itemToBeAssigned = 0;
                        } else if (runtime.strlen(runtime.aimBuffer) != 0) {
                            // Delete the character before the cursor
                            if (runtime.T_cursorPos > 0) {
                                runtime.deleteAlphaCharacter(&runtime.T_cursorPos);
                            }
                        } else {
                            runtime.assignLeaveAlpha();
                            if (runtime.asnKey[1] != 0) {
                                runtime.assignToKey(&runtime.asnKey[0]);
                            } else {
                                runtime.assignToMenu(&runtime.asnKey[0]);
                            }
                            runtime.calcMode = runtime.previousCalcMode;
                            runtime.shiftF = false;
                            runtime.shiftG = false;
                            runtime.refreshScreen(129);
                        }
                    }
                },

                runtime.CM_TIMER => {
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                    } else {
                        runtime.fnBackspaceTimerApp();
                    }
                },

                else => runtime.bugScreenWhileProcKey("fnKeyBackspace", "BACKSPACE"),
            }
        }

        pub fn keyUp(unused_but_mandatory_parameter: u16) void {
            _ = unused_but_mandatory_parameter;
            const menuId = runtime.softmenuStack[0].softmenuId;

            if (runtime.tam.mode != 0 and runtime.tam.alpha and runtime.currentMenu() == -runtime.MNU_TAMALPHA) {
                runtime.fnAlphaCursorHome(runtime.NOPARAM);
                runtime.tamProcessInput(runtime.ITM_NOP); // To update the tam buffer
                return;
            }
            if (runtime.tam.mode == runtime.TM_KEY and !runtime.tam.keyInputFinished) {
                if (runtime.tam.digitsSoFar == 0) {
                    runtime.tamProcessInput(runtime.ITM_1);
                    runtime.tamProcessInput(runtime.ITM_9);
                    runtime.shiftF = false;
                    runtime.shiftG = false;
                    runtime.refreshScreen(131);
                }
                return;
            }
            if (runtime.softmenuItemAt(menuId) != -runtime.MNU_REG and runtime.softmenuItemAt(menuId) != -runtime.MNU_FLG and runtime.tam.mode != 0 and runtime.catalog == 0) {
                if (runtime.tam.alpha) {
                    runtime.resetAlphaSelectionBuffer();
                    if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuUp();
                    } else {
                        runtime.alphaCase = runtime.AC_UPPER;
                    }
                } else {
                    runtime.addItemToBuffer(runtime.ITM_Max);
                }
                return;
            }
            if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_NIM) and runtime.currentMenu() == -runtime.ITM_MENU) {
                runtime.dynamicMenuItem = 18;
                runtime.fnProgrammableMenu(runtime.NOPARAM);
                return;
            }

            switch (runtime.calcMode) {
                runtime.CM_NORMAL, runtime.CM_AIM, runtime.CM_NIM, runtime.CM_EIM, runtime.CM_PLOT_STAT, runtime.CM_GRAPH => {
                    runtime.doRefreshSoftMenu = true;
                    runtime.resetAlphaSelectionBuffer();

                    if (!runtime.arrowCasechange and runtime.calcMode == runtime.CM_AIM and runtime.isJMAlphaSoftmenu(menuId)) {
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.fnT_ARROW(@intCast(runtime.ITM_UP1));
                    } else if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuUp();
                    } else if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_NIM) and (runtime.numberOfFormulae < 2 or runtime.currentMenu() != -runtime.MNU_EQN)) {
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                        if (runtime.calcMode == runtime.CM_NIM) {
                            runtime.closeNim();
                        }
                        if (runtime.calcMode == runtime.CM_AIM) {
                            runtime.closeAim();
                        }
                        runtime.fnBst(runtime.NOPARAM);
                        _ = runtime.refreshLcd(null);
                    }
                    if (runtime.currentMenu() == -runtime.MNU_PLOT_ASSESS) {
                        _ = runtime.strcpy(&runtime.plotStatMx[0], "STATS");
                        runtime.fnPlotStat(runtime.PLOT_NXT);
                    } else if (runtime.currentMenu() == -runtime.MNU_EQN) {
                        if (runtime.currentFormula == 0) {
                            runtime.currentFormula = runtime.numberOfFormulae;
                        }
                        runtime.currentFormula -%= 1;
                        if (runtime.numberOfFormulae > 1) {
                            runtime.currentSolverVariable = runtime.INVALID_VARIABLE;
                            runtime.graphVariabl1 = 0;
                        }
                        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
                    }
                },

                runtime.CM_REGISTER_BROWSER => {
                    runtime.rbr1stDigit = true;
                    if (runtime.rbrMode == runtime.RBR_GLOBAL) {
                        runtime.currentRegisterBrowserScreen = @intCast(runtime.modulo(@as(i32, runtime.currentRegisterBrowserScreen) + runtime.RBR_INCDEC1, runtime.LAST_GLOBAL_REGISTER_SCREEN + runtime.RBR_INCDEC1));
                    } else if (runtime.rbrMode == runtime.RBR_LOCAL) {
                        runtime.currentRegisterBrowserScreen = @intCast(runtime.modulo(@as(i32, runtime.currentRegisterBrowserScreen) - runtime.FIRST_LOCAL_REGISTER + 1, runtime.currentNumberOfLocalRegisters()) + runtime.FIRST_LOCAL_REGISTER);
                    } else if (runtime.rbrMode == runtime.RBR_NAMED) {
                        runtime.currentRegisterBrowserScreen = @intCast(runtime.modulo(@as(i32, runtime.currentRegisterBrowserScreen) - runtime.FIRST_NAMED_VARIABLE + 1, @as(i32, runtime.numberOfNamedVariables) + runtime.LAST_RESERVED_VARIABLE - runtime.FIRST_RESERVED_VARIABLE - (runtime.NUMBER_OF_LETTERED_VARIABLES - 1)) + runtime.FIRST_NAMED_VARIABLE);
                    } else {
                        runtime.bugScreenRbrMode("fnKeyUp", "UP", runtime.rbrMode);
                    }
                },

                runtime.CM_FLAG_BROWSER => {
                    runtime.currentFlgScr +%= 1; // [DL] reverse order
                },

                runtime.CM_ASN_BROWSER => {
                    runtime.currentAsnScr +%= 1; // JM removed the 3-x part
                    if (runtime.currentAsnScr == 0 or runtime.currentAsnScr >= 7) {
                        runtime.currentAsnScr = if (runtime.previousCalcMode == runtime.CM_AIM or runtime.previousCalcMode == runtime.CM_EIM or runtime.tam.alpha) 4 else 1;
                    }
                },

                runtime.CM_FONT_BROWSER => {
                    if (runtime.currentFntScr >= 2) {
                        runtime.currentFntScr -= 1;
                    }
                },

                runtime.CM_PEM => {
                    runtime.resetAlphaSelectionBuffer();
                    if (runtime.getSystemFlag(runtime.FLAG_ALPHA) and runtime.alphaCase == runtime.AC_LOWER) {
                        runtime.alphaCase = runtime.AC_UPPER;
                        if (runtime.currentMenu() == -runtime.MNU_alpha_omega or runtime.currentMenu() == -runtime.MNU_ALPHAintl) {
                            runtime.softmenuStack[0].softmenuId -= 1; // Switch to the upper case menu
                        }
                    } else if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuUp();
                    } else {
                        if (runtime.getSystemFlag(runtime.FLAG_ALPHA) and runtime.aimBuffer[0] == 0 and runtime.tam.mode == 0) {
                            runtime.pemAlpha(runtime.ITM_BACKSPACE);
                        }
                        runtime.fnBst(runtime.NOPARAM);
                    }
                },

                runtime.CM_LISTXY => {
                    runtime.ListXYposition += 10;
                    runtime.keyActionProcessed = true;
                },

                runtime.CM_MIM => {
                    // NOMATRIXCURSORS defined: arrows navigate the matrix unless a
                    // non-TAMSTO/TAMRCL softmenu (or any catalog) is scrolling.
                    if (runtime.currentSoftmenuScrolls() and (runtime.catalog != 0 or (runtime.currentMenu() != -runtime.MNU_TAMSTO and runtime.currentMenu() != -runtime.MNU_TAMRCL))) {
                        runtime.menuUp();
                    }
                },

                runtime.CM_ASSIGN => {
                    if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuUp();
                    } else if (runtime.tam.alpha and runtime.alphaCase == runtime.AC_LOWER) {
                        runtime.alphaCase = runtime.AC_UPPER;
                    } else if (runtime.tam.alpha and runtime.itemToBeAssigned == 0 and runtime.aimBuffer[0] == 0) {
                        runtime.assignLeaveAlpha();
                        runtime.itemToBeAssigned = runtime.ITM_UP1;
                    } else if (runtime.tam.alpha and runtime.aimBuffer[0] == 0) {
                        runtime.assignLeaveAlpha();
                        if (runtime.asnKey[1] != 0) {
                            runtime.assignToKey(&runtime.asnKey[0]);
                        } else {
                            runtime.assignToMenu(&runtime.asnKey[0]);
                        }
                        runtime.calcMode = runtime.previousCalcMode;
                        runtime.shiftF = false;
                        runtime.shiftG = false;
                        runtime.refreshScreen(132);
                    }
                },

                runtime.CM_TIMER => {
                    runtime.fnUpTimerApp();
                },

                else => runtime.bugScreenWhileProcKey("fnKeyUp", "UP"),
            }
        }

        pub fn keyDown(unused_but_mandatory_parameter: u16) void {
            _ = unused_but_mandatory_parameter;
            const menuId = runtime.softmenuStack[0].softmenuId;

            if (runtime.tam.mode != 0 and runtime.tam.alpha and runtime.currentMenu() == -runtime.MNU_TAMALPHA) {
                runtime.fnAlphaCursorEnd(runtime.NOPARAM);
                runtime.tamProcessInput(runtime.ITM_NOP); // To update the tam buffer
                return;
            }
            if (runtime.tam.mode == runtime.TM_KEY and !runtime.tam.keyInputFinished) {
                if (runtime.tam.digitsSoFar == 0) {
                    runtime.tamProcessInput(runtime.ITM_2);
                    runtime.tamProcessInput(runtime.ITM_0);
                    runtime.shiftF = false;
                    runtime.shiftG = false;
                    runtime.refreshScreen(134);
                }
                return;
            }
            if (runtime.softmenuItemAt(menuId) != -runtime.MNU_REG and runtime.softmenuItemAt(menuId) != -runtime.MNU_FLG and runtime.tam.mode != 0 and runtime.catalog == 0) {
                if (runtime.tam.alpha) {
                    runtime.resetAlphaSelectionBuffer();
                    if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuDown();
                    } else {
                        runtime.alphaCase = runtime.AC_LOWER;
                    }
                } else {
                    runtime.addItemToBuffer(runtime.ITM_Min);
                }
                return;
            }
            if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_NIM) and runtime.currentMenu() == -runtime.ITM_MENU) {
                runtime.dynamicMenuItem = 19;
                runtime.fnProgrammableMenu(runtime.NOPARAM);
                return;
            }

            switch (runtime.calcMode) {
                runtime.CM_NORMAL, runtime.CM_AIM, runtime.CM_NIM, runtime.CM_EIM, runtime.CM_PLOT_STAT, runtime.CM_GRAPH => {
                    runtime.doRefreshSoftMenu = true;
                    runtime.resetAlphaSelectionBuffer();

                    if (!runtime.arrowCasechange and runtime.calcMode == runtime.CM_AIM and runtime.isJMAlphaSoftmenu(menuId)) {
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.fnT_ARROW(@intCast(runtime.ITM_DOWN1));
                    } else if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuDown();
                    } else if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_NIM) and (runtime.numberOfFormulae < 2 or runtime.currentMenu() != -runtime.MNU_EQN)) {
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                        if (runtime.calcMode == runtime.CM_NIM) {
                            runtime.closeNim();
                        }
                        if (runtime.calcMode == runtime.CM_AIM) {
                            runtime.closeAim();
                        }
                        runtime.fnSst(runtime.NOPARAM);
                        _ = runtime.refreshLcd(null);
                    }
                    if (runtime.currentMenu() == -runtime.MNU_PLOT_ASSESS) {
                        _ = runtime.strcpy(&runtime.plotStatMx[0], "STATS");
                        runtime.fnPlotStat(runtime.PLOT_REV); // REVERSE
                    } else if (runtime.currentMenu() == -runtime.MNU_EQN) {
                        runtime.currentFormula +%= 1;
                        if (runtime.currentFormula == runtime.numberOfFormulae) {
                            runtime.currentFormula = 0;
                        }
                        if (runtime.numberOfFormulae > 1) {
                            runtime.currentSolverVariable = runtime.INVALID_VARIABLE;
                            runtime.graphVariabl1 = 0;
                        }
                        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
                    }
                },

                runtime.CM_REGISTER_BROWSER => {
                    runtime.rbr1stDigit = true;
                    if (runtime.rbrMode == runtime.RBR_GLOBAL) {
                        runtime.currentRegisterBrowserScreen = @intCast(runtime.modulo(@as(i32, runtime.currentRegisterBrowserScreen) - runtime.RBR_INCDEC1, runtime.LAST_GLOBAL_REGISTER_SCREEN + runtime.RBR_INCDEC1));
                    } else if (runtime.rbrMode == runtime.RBR_LOCAL) {
                        runtime.currentRegisterBrowserScreen = @intCast(runtime.modulo(@as(i32, runtime.currentRegisterBrowserScreen) - runtime.FIRST_LOCAL_REGISTER - 1, runtime.currentNumberOfLocalRegisters()) + runtime.FIRST_LOCAL_REGISTER);
                    } else if (runtime.rbrMode == runtime.RBR_NAMED) {
                        runtime.currentRegisterBrowserScreen = @intCast(runtime.modulo(@as(i32, runtime.currentRegisterBrowserScreen) - runtime.FIRST_NAMED_VARIABLE - 1, @as(i32, runtime.numberOfNamedVariables) + runtime.LAST_RESERVED_VARIABLE - runtime.FIRST_RESERVED_VARIABLE - (runtime.NUMBER_OF_LETTERED_VARIABLES - 1)) + runtime.FIRST_NAMED_VARIABLE);
                    } else {
                        runtime.bugScreenRbrMode("fnKeyDown", "DOWN", runtime.rbrMode);
                    }
                },

                runtime.CM_FLAG_BROWSER => {
                    runtime.currentFlgScr -%= 1; // [DL] reverse order
                },

                runtime.CM_ASN_BROWSER => {
                    runtime.currentAsnScr -%= 1;
                    if (runtime.currentAsnScr == 0 or runtime.currentAsnScr >= 7 or ((runtime.previousCalcMode == runtime.CM_AIM or runtime.previousCalcMode == runtime.CM_EIM or runtime.tam.alpha) and runtime.currentAsnScr < 4)) {
                        runtime.currentAsnScr = 6;
                    }
                },

                runtime.CM_FONT_BROWSER => {
                    if (runtime.currentFntScr < @as(u16, runtime.numScreensNumericFont) + runtime.numScreensStandardFont + runtime.numScreensTinyFont) {
                        runtime.currentFntScr += 1;
                    }
                },

                runtime.CM_PEM => {
                    runtime.resetAlphaSelectionBuffer();
                    if (runtime.getSystemFlag(runtime.FLAG_ALPHA) and runtime.alphaCase == runtime.AC_UPPER) {
                        runtime.alphaCase = runtime.AC_LOWER;
                        if (runtime.currentMenu() == -runtime.MNU_ALPHA_OMEGA or runtime.currentMenu() == -runtime.MNU_ALPHAINTL) {
                            runtime.softmenuStack[0].softmenuId += 1; // Switch to the lower case menu
                        }
                    } else if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuDown();
                    } else {
                        if (runtime.getSystemFlag(runtime.FLAG_ALPHA) and runtime.aimBuffer[0] == 0 and runtime.tam.mode == 0) {
                            runtime.pemAlpha(runtime.ITM_BACKSPACE);
                            runtime.fnBst(runtime.NOPARAM); // Set the PGM pointer to the original position
                        }
                        runtime.fnSst(runtime.NOPARAM);
                    }
                },

                runtime.CM_LISTXY => {
                    runtime.ListXYposition -= 10;
                    runtime.keyActionProcessed = true;
                },

                runtime.CM_MIM => {
                    if (runtime.currentSoftmenuScrolls() and (runtime.catalog != 0 or (runtime.currentMenu() != -runtime.MNU_TAMSTO and runtime.currentMenu() != -runtime.MNU_TAMRCL))) {
                        runtime.menuDown();
                    }
                },

                runtime.CM_ASSIGN => {
                    if (runtime.currentSoftmenuScrolls()) {
                        runtime.menuDown();
                    } else if (runtime.tam.alpha and (runtime.itemToBeAssigned == 0 or runtime.tam.mode == runtime.TM_NEWMENU) and runtime.alphaCase == runtime.AC_UPPER) {
                        runtime.alphaCase = runtime.AC_LOWER;
                    } else if (runtime.tam.alpha and runtime.itemToBeAssigned == 0 and runtime.aimBuffer[0] == 0) {
                        runtime.assignLeaveAlpha();
                        runtime.itemToBeAssigned = runtime.ITM_DOWN1;
                    } else if (runtime.tam.alpha and runtime.aimBuffer[0] == 0) {
                        runtime.assignLeaveAlpha();
                        if (runtime.asnKey[1] != 0) {
                            runtime.assignToKey(&runtime.asnKey[0]);
                        } else {
                            runtime.assignToMenu(&runtime.asnKey[0]);
                        }
                        runtime.calcMode = runtime.previousCalcMode;
                        runtime.shiftF = false;
                        runtime.shiftG = false;
                        runtime.refreshScreen(135);
                    }
                },

                runtime.CM_TIMER => {
                    runtime.fnDownTimerApp();
                },

                else => runtime.bugScreenWhileProcKey("fnKeyDown", "DOWN"),
            }
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
