pub fn implementation(comptime runtime: type) type {
    return struct {
        fn isGraphMode() bool {
            return runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH;
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

        fn lastKeyCodeFor(key: i32) ?u8 {
            if (key < 1 or key > 43) return null;
            if (key <= 6) return @intCast(key + 20);
            if (key <= 12) return @intCast(key - 6 + 30);
            if (key <= 17) return @intCast(key - 12 + 40);
            if (key <= 22) return @intCast(key - 17 + 50);
            if (key <= 27) return @intCast(key - 22 + 60);
            if (key <= 32) return @intCast(key - 27 + 70);
            if (key <= 37) return @intCast(key - 32 + 80);
            return @intCast(key - 37 + 10);
        }

        pub fn setLastKeyCode(key: i32) void {
            if (lastKeyCodeFor(key)) |code| {
                runtime.lastKeyCode = code;
            }
        }

        pub fn executeFunction(data: [*c]const u8, item_: i16) void {
            // keyboard.c executeFunction (928-1430). VERBOSEKEYS / VERBOSE_*
            // tracing dropped; EXTRA_INFO_ON_CALC_ERROR gated as elsewhere.
            const ITM_0: i16 = @intCast(runtime.ITM_0);
            var item: i16 = runtime.ITM_NOP;
            runtime.FN_timed_out_to_NOP_or_Executed = true;

            if (runtime.calcMode != runtime.CM_REGISTER_BROWSER and runtime.calcMode != runtime.CM_FLAG_BROWSER and runtime.calcMode != runtime.CM_ASN_BROWSER and runtime.calcMode != runtime.CM_FONT_BROWSER) {
                if (data[0] == 0) {
                    item = item_;
                } else {
                    item = determineFunctionKeyItem_C47(data, runtime.shiftF, runtime.shiftG);
                    if (runtime.calcMode == runtime.CM_NIM and (item == runtime.ITM_HASH_JM or item == runtime.ITM_toINT)) {
                        runtime.addItemToNimBuffer(item);
                        item = runtime.ITM_NOP;
                    }
                    runtime.lastKeyItemDetermined = item;
                }

                if (runtime.calcMode == runtime.CM_GRAPH and runtime.currentMenu() == -runtime.MNU_PLOT_FUNC and (item == runtime.VAR_LX or item == runtime.VAR_UX)) {
                    runtime.calcMode = runtime.CM_NORMAL;
                    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                    runtime.clearScreen();
                    runtime.refreshScreen(127);
                    runtime.showSoftmenu(-runtime.MNU_GRAPHS);
                    item = 0;
                }

                if ((runtime.currentMenu() == -runtime.MNU_DYNAMIC) or (runtime.currentMenu() == -runtime.MNU_HOME) or (runtime.currentMenu() == -runtime.MNU_PFN)) {
                    _ = runtime.setCurrentUserMenu(item, &runtime.userMenus[runtime.currentUserMenu].menuItem[@intCast(runtime.dynamicMenuItem)].argumentName);
                }

                if (runtime.calcMode == runtime.CM_PEM and runtime.isFunctionItemAMenu(item)) {
                    switch (item) {
                        runtime.ITM_GAP_R => item = -runtime.MNU_GAP_R,
                        runtime.ITM_GAP_L => item = -runtime.MNU_GAP_L,
                        runtime.ITM_GAP_RX => item = -runtime.MNU_GAP_RX,
                        else => {},
                    }
                }

                runtime.resetShiftState();

                if (item != 0) {
                    runtime.showFunctionNameItem = 0;
                    if (runtime.calcMode != runtime.CM_CONFIRMATION and data[0] != 0) {
                        runtime.lastErrorCode = 0;

                        if (runtime.calcMode != runtime.CM_PEM and item == -runtime.MNU_Sfdx) {
                            runtime.tamEnterMode(runtime.MNU_Sfdx);
                            runtime.refreshScreen(109);
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
                            return;
                        } else if (runtime.calcMode != runtime.CM_PEM and (item == runtime.ITM_INTEGRAL or item == runtime.ITM_INTEGRAL_YX)) {
                            switch (runtime.calcMode) {
                                runtime.CM_NIM => runtime.closeNim(),
                                runtime.CM_AIM => runtime.closeAim(),
                                else => {},
                            }
                            runtime.reallyRunFunction(item, runtime.currentSolverVariable);
                            runtime.refreshScreen(110);
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
                            return;
                        } else if (item < 0) { // softmenu
                            if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned == 0 and runtime.currentMenu() == -runtime.MNU_MENUS) {
                                runtime.itemToBeAssigned = item;
                                runtime.leaveAsmMode();
                                runtime.popSoftmenu();
                            } else if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and (item == -runtime.MNU_HOME or item == -runtime.MNU_PFN or item == -runtime.MNU_MyMenu)) {
                                runtime.itemToBeAssigned = item;
                                runtime.leaveAsmMode();
                                runtime.showSoftmenu(item);
                            } else if ((runtime.tam.mode == runtime.TM_MENU) and (item != -runtime.MNU_MENU) and !runtime.tam.alpha) {
                                if ((runtime.currentMenu() == -runtime.MNU_TAMINDIRECT) and ((item == -runtime.MNU_VAR) or (item == -runtime.MNU_REG))) {
                                    runtime.showSoftmenu(item);
                                } else {
                                    runtime.fnKeyInCatalog = true;
                                    if (item < 0) {
                                        item = -item;
                                    }
                                    runtime.addItemToBuffer(@bitCast(item));
                                }
                            } else {
                                runtime.showSoftmenu(item);
                                if (isGraphMode()) {
                                    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                                    if (item == -runtime.MNU_GRAPHS) {
                                        runtime.calcMode = runtime.CM_NORMAL;
                                        runtime.fnUndo(runtime.NOPARAM);
                                    }
                                }
                                if (item == -runtime.MNU_ALPHA) {
                                    runtime.fnAim(0);
                                }
                                if ((item == -runtime.MNU_Solver or item == -runtime.MNU_Grapher or item == -runtime.MNU_Sf or item == -runtime.MNU_1STDERIV or item == -runtime.MNU_2NDDERIV or item == -runtime.MNU_Sf_TOOL or item == -runtime.MNU_Solver_TOOL) and runtime.lastErrorCode != 0) {
                                    runtime.popSoftmenu();
                                    runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_INTERACTIVE;
                                    runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_EQUATION_MODE;
                                }
                            }
                            runtime.refreshScreen(111);
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
                            return;
                        }

                        if (runtime.tam.mode != 0 and runtime.catalog != 0 and (runtime.tam.digitsSoFar != 0 or runtime.isFunctionOldParam16(@bitCast(runtime.tam.function)) or (!runtime.tam.indirect and (runtime.tam.mode == runtime.TM_VALUE or runtime.tam.mode == runtime.TM_VALUE_CHB or (runtime.tam.mode == runtime.TM_KEY and !runtime.tam.keyInputFinished))))) {
                            // disabled
                        } else if (runtime.tam.function == runtime.ITM_GTOP and runtime.catalog == runtime.CATALOG_PROG) {
                            runtime.runFunction(item);
                            runtime.leaveTamModeIfEnabled();
                            runtime.hourGlassIconEnabled = false;
                            _closeCatalog();
                            runtime.refreshScreen(112);
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
                            return;
                        } else if ((runtime.tam.mode != 0 or runtime.getItemFunc(item) != runtime.addItemToBufferPtr()) and runtime.calcMode == runtime.CM_PEM and runtime.catalog == 0 and (runtime.tam.mode == runtime.TM_FLAGR or runtime.tam.mode == runtime.TM_FLAGW) and !(runtime.tam.mode != 0 and runtime.tam.function == runtime.ITM_DELP)) {
                            if ((runtime.tam.mode == runtime.TM_FLAGR or runtime.tam.mode == runtime.TM_FLAGW) and (item != runtime.ITM_INDIRECTION) and !runtime.tam.indirect) {
                                runtime.tam.value = @intCast(runtime.indexOfItemsParam(item) & 0xff);
                                runtime.addStepInProgram(runtime.tamOperation());
                                runtime.leaveTamModeIfEnabled();
                            }
                        } else if ((runtime.tam.mode != 0 or runtime.getItemFunc(item) != runtime.addItemToBufferPtr()) and runtime.calcMode == runtime.CM_PEM and runtime.catalog != 0 and runtime.catalog != runtime.CATALOG_MVAR and !(runtime.tam.mode != 0 and runtime.tam.function == runtime.ITM_DELP)) {
                            runtime.fnKeyInCatalog = true;
                            if (runtime.itemFuncEquals(item, @ptrCast(&runtime.fnGetSystemFlag)) and (runtime.tam.mode == runtime.TM_FLAGR or runtime.tam.mode == runtime.TM_FLAGW) and !runtime.tam.indirect) {
                                runtime.tam.value = @intCast(runtime.indexOfItemsParam(item) & 0xff);
                                runtime.tam.alpha = true;
                                runtime.addStepInProgram(runtime.tamOperation());
                                runtime.leaveTamModeIfEnabled();
                            } else if (runtime.itemFuncIsAddItemToBuffer(item)) {
                                if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                                    processAimInput(item);
                                    if (runtime.tam.mode != 0) {
                                        runtime.popSoftmenu();
                                    }
                                } else {
                                    runtime.addStepInProgram(item);
                                }
                                runtime.hourGlassIconEnabled = false;
                            } else if (runtime.tam.mode != 0) {
                                const itmLabel = runtime.dynmenuGetLabel(runtime.dynamicMenuItem);
                                const nameLength: u16 = @intCast(runtime.stringByteLength(itmLabel));
                                _ = runtime.xcopy(runtime.aimBuffer, itmLabel, @as(u32, nameLength) + 1);
                                runtime.tam.alpha = true;
                                runtime.addStepInProgram(runtime.tamOperation());
                                runtime.leaveTamModeIfEnabled();
                            } else {
                                runtime.runFunction(item);
                            }
                            runtime.hourGlassIconEnabled = false;
                            _closeCatalog();
                            runtime.fnKeyInCatalog = false;
                            runtime.refreshScreen(113);
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
                            return;
                        } else if (runtime.calcMode == runtime.CM_PEM and !runtime.getSystemFlag(runtime.FLAG_ALPHA) and (item == runtime.ITM_toINT or item == runtime.ITM_HASH_JM)) {
                            if (runtime.aimBuffer[0] != 0) {
                                runtime.pemAddNumber(runtime.ITM_toINT, true);
                                runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
                                runtime.refreshScreen(115);
                                return;
                            }
                        }

                        runtime.fnKeyInCatalog = true;
                        if (runtime.tam.mode != 0 and runtime.catalog != 0 and (runtime.tam.digitsSoFar != 0 or runtime.isFunctionOldParam16(@bitCast(runtime.tam.function)) or (!runtime.tam.indirect and (runtime.tam.mode == runtime.TM_VALUE or runtime.tam.mode == runtime.TM_VALUE_CHB)))) {
                            // disabled
                        } else if (runtime.tam.mode != 0 and (!runtime.tam.alpha or runtime.isAlphabeticSoftmenu()) and !(runtime.tam.mode == runtime.TM_VALUE and (item == runtime.ITM_TAMMAX or item == runtime.ITM_YY_TRACK or item == runtime.ITM_YY_OFF))) {
                            const isInConfig = runtime.tam.mode == runtime.TM_FLAGW and runtime.currentMenu() == -runtime.MNU_SYSFL;
                            if (runtime.menu(1) == -runtime.MNU_TAMALPHA and runtime.isAlphaSubmenu(0)) {
                                runtime.popSoftmenu();
                                runtime.numberOfTamMenusToPop -= 1;
                            }
                            runtime.addItemToBuffer(@bitCast(item));
                            if ((runtime.currentMenu() == -runtime.MNU_MODE or runtime.currentMenu() == -runtime.MNU_PREF) and isInConfig and item != runtime.ITM_EXIT1 and item != runtime.ITM_BACKSPACE) {
                                runtime.fnCFGsettings(0);
                            }
                        } else if (runtime.calcMode == runtime.CM_EIM and ((runtime.catalog != 0 and runtime.catalog != runtime.CATALOG_MVAR) or (runtime.currentMenu() == -runtime.MNU_EQ_EDIT and item != runtime.ITM_EQ_LEFT and item != runtime.ITM_EQ_RIGHT and item != runtime.CHR_num and item != runtime.CHR_case and (runtime.indexOfItemsStatus(item) & runtime.EIM_STATUS) == runtime.EIM_ENABLED))) {
                            if (runtime.currentMenu() == -runtime.MNU_CONST) {
                                runtime.addItemToBuffer(@bitCast(runtime.ITM_NUMBER_SIGN));
                            }
                            runtime.addItemToBuffer(@bitCast(item));
                            while (runtime.currentMenu() != -runtime.MNU_EQ_EDIT) {
                                runtime.popSoftmenu();
                            }
                        } else if ((runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM) and (ITM_0 <= item and item <= runtime.ITM_F) and (runtime.catalog == 0 or runtime.catalog == runtime.CATALOG_MVAR)) {
                            if (runtime.lastIntegerBase == 0) {
                                runtime.lastIntegerBase = 16;
                            }
                            runtime.addItemToNimBuffer(item);
                        } else if ((runtime.calcMode == runtime.CM_NIM) and ((item == runtime.ITM_DMS2 or item == runtime.ITM_dotD) and runtime.catalog == 0)) {
                            runtime.addItemToNimBuffer(item);
                        } else if (runtime.calcMode == runtime.CM_MIM and runtime.currentMenu() != -runtime.MNU_M_EDIT and (item != runtime.ITM_CC and item != runtime.ITM_op_j and item != runtime.ITM_op_j_pol)) {
                            runtime.addItemToBuffer(@bitCast(item));
                        } else if (item > 0) { // function
                            blk: {
                                if (runtime.calcMode == runtime.CM_NORMAL and ((runtime.lastIntegerBase == 2 and item == runtime.ITM_2BIN) or (runtime.lastIntegerBase == 8 and item == runtime.ITM_2OCT) or (runtime.lastIntegerBase == 10 and item == runtime.ITM_2DEC) or (runtime.lastIntegerBase == 16 and item == runtime.ITM_2HEX))) {
                                    runtime.setLastintegerBasetoZero();
                                    runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
                                    break :blk;
                                }
                                if (runtime.calcMode == runtime.CM_NIM and item != runtime.ITM_CC and item != runtime.ITM_op_j and item != runtime.ITM_op_j_pol and item != runtime.ITM_HASH_JM and item != runtime.ITM_toINT and item != runtime.ITM_ms) {
                                    runtime.closeNim();
                                    if (runtime.calcMode != runtime.CM_NIM) {
                                        if (runtime.itemFuncEquals(item, @ptrCast(&runtime.fnConstant))) {
                                            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                                        }
                                    }
                                }
                                if (item == runtime.ITM_KEYMAP) {
                                    runtime.cursorEnabled = false;
                                }
                                if (runtime.calcMode == runtime.CM_AIM and !(runtime.isAlphabeticSoftmenu() or runtime.isJMAlphaOnlySoftmenu() or item == runtime.ITM_KEYMAP)) {
                                    runtime.closeAim();
                                }
                                if (runtime.tam.mode != 0 and runtime.tam.alpha) {
                                    if (item == runtime.ITM_T_LEFT_ARROW) {
                                        runtime.fnAlphaCursorLeft(runtime.NOPARAM);
                                        runtime.tamProcessInput(@intCast(runtime.ITM_T_LEFT_ARROW));
                                        break :blk;
                                    } else if (item == runtime.ITM_T_RIGHT_ARROW) {
                                        runtime.fnAlphaCursorRight(runtime.NOPARAM);
                                        runtime.tamProcessInput(@intCast(runtime.ITM_NOP));
                                        break :blk;
                                    } else if (item == runtime.ITM_NOP) {
                                        runtime.tamProcessInput(@intCast(runtime.ITM_NOP));
                                        break :blk;
                                    }
                                }
                                if (runtime.tam.alpha and runtime.calcMode != runtime.CM_ASSIGN and runtime.tam.mode != runtime.TM_NEWMENU and !((runtime.tam.mode == runtime.TM_STORCL or runtime.tam.mode == runtime.TM_LABEL or runtime.tam.mode == runtime.TM_LBLONLY or runtime.tam.mode == runtime.TM_SOLVE or runtime.tam.mode == runtime.TM_KEY or runtime.tam.mode == runtime.TM_M_DIM or runtime.tam.mode == runtime.TM_REGISTER or runtime.tam.mode == runtime.TM_CMP or runtime.tam.mode == runtime.TM_STRING) and (item == runtime.CHR_num or item == runtime.CHR_case or item == runtime.ITM_SCR or item == runtime.ITM_USERMODE))) {
                                    if (runtime.calcMode != runtime.CM_PEM or item != runtime.ITM_NOP) {
                                        runtime.leaveTamModeIfEnabled();
                                    }
                                } else if (runtime.tam.mode == runtime.TM_VALUE and (item == runtime.ITM_TAMMAX or item == runtime.ITM_YY_TRACK or item == runtime.ITM_YY_OFF)) {
                                    runtime.leaveTamModeIfEnabled();
                                }

                                if (runtime.lastErrorCode == 0) {
                                    if (runtime.temporaryInformation == runtime.TI_VIEW_REGISTER) {
                                        runtime.updateMatrixHeightCache();
                                    }
                                    runtime.temporaryInformation = runtime.TI_NO_INFO;
                                    if (runtime.programRunStop == runtime.PGM_WAITING) {
                                        runtime.programRunStop = runtime.PGM_STOPPED;
                                    }
                                    if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned == 0 and item != runtime.ITM_NOP) {
                                        if (item == runtime.CHR_case) {
                                            runtime.SetSetting(runtime.JC_UC);
                                        } else if (item == runtime.CHR_num) {
                                            runtime.SetSetting(runtime.JC_NL);
                                        } else if (runtime.tam.alpha) {
                                            processAimInput(item);
                                            if (runtime.stringGlyphLength(runtime.aimBuffer) > 6) {
                                                runtime.assignLeaveAlpha();
                                                runtime.assignGetName1();
                                            }
                                        } else if (item == runtime.ITM_AIM) {
                                            runtime.assignEnterAlpha();
                                            runtime.keyActionProcessed = true;
                                        } else {
                                            if (item == runtime.ITM_XEQ and runtime.dynamicMenuItem > -1) {
                                                const varCatalogItem = runtime.dynmenuGetLabel(runtime.dynamicMenuItem);
                                                if (runtime.strcmp(varCatalogItem, "XEQ") != 0) {
                                                    const regist = runtime.findNamedLabel(varCatalogItem, runtime.GLOBAL_LABELS);
                                                    if (regist != @as(i16, @intCast(runtime.INVALID_VARIABLE))) {
                                                        item = @intCast(@as(i32, regist) - runtime.FIRST_LABEL + runtime.ASSIGN_LABELS);
                                                    } else {
                                                        runtime.displayCalcErrorMessage(runtime.ERROR_LABEL_NOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                                                        if (comptime !runtime.is_dmcp_build) {
                                                            runtime.fmtCStr(runtime.errorMessage, "string '{s}' is not a named label", .{@as([*:0]const u8, varCatalogItem)});
                                                            runtime.moreInfoOnError("In function executeFunction:", runtime.errorMessage, null, null);
                                                        }
                                                    }
                                                }
                                            } else if (item == runtime.ITM_RCL and runtime.dynamicMenuItem > -1) {
                                                const varCatalogItem = runtime.dynmenuGetLabel(runtime.dynamicMenuItem);
                                                if (runtime.strcmp(varCatalogItem, "RCL") != 0) {
                                                    const regist = runtime.findNamedVariable(varCatalogItem);
                                                    if (regist != @as(i16, @intCast(runtime.INVALID_VARIABLE))) {
                                                        item = @intCast(@as(i32, regist) - runtime.FIRST_NAMED_VARIABLE + runtime.ASSIGN_NAMED_VARIABLES);
                                                    } else {
                                                        runtime.displayCalcErrorMessage(runtime.ERROR_LABEL_NOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                                                        if (comptime !runtime.is_dmcp_build) {
                                                            runtime.fmtCStr(runtime.errorMessage, "string '{s}' is not a named variable", .{@as([*:0]const u8, varCatalogItem)});
                                                            runtime.moreInfoOnError("In function executeFunction:", runtime.errorMessage, null, null);
                                                        }
                                                    }
                                                }
                                            }
                                            runtime.itemToBeAssigned = item;
                                            if (runtime.previousCalcMode == runtime.CM_AIM and runtime.isAlphaSubmenu(0)) {
                                                runtime.popSoftmenu();
                                                runtime.showSoftmenu(-runtime.MNU_MyAlpha);
                                            }
                                        }
                                    } else if (runtime.calcMode == runtime.CM_ASSIGN and runtime.tam.alpha and runtime.tam.mode != runtime.TM_NEWMENU and item != runtime.ITM_NOP) {
                                        processAimInput(item);
                                        if (runtime.stringGlyphLength(runtime.aimBuffer) > 6) {
                                            runtime.assignLeaveAlpha();
                                            runtime.assignGetName2();
                                        }
                                    } else {
                                        runtime.runFunction(item);

                                        // Double execution when a custom conversion: additional to the
                                        // runFunction which operated the 'normal' conversion (keyboard.c:1384)
                                        if (!(runtime.programRunStop == runtime.PGM_RUNNING or runtime.programRunStop == runtime.PGM_PAUSED) and runtime.calcMode != runtime.CM_PEM and item > 0 and runtime.isItemConversion(item)) {
                                            var itemNrPair: i16 = undefined;
                                            runtime.executionConversionPartner(item, &itemNrPair, null);
                                            if (itemNrPair != 0) { // non-zero = custom non-standard pair needing the round-trip via SI
                                                if (!runtime.getSystemFlag(runtime.FLAG_HPCONV)) { // normal CONV_HP clear
                                                    runtime.runConversionToSI(item);
                                                    runtime.runConversionFromSI(itemNrPair);
                                                } else { // flipped CONV_HP set
                                                    runtime.runFunction(runtime.conversionPartner(item, null, null, null));
                                                    runtime.runConversionToSI(itemNrPair);
                                                    runtime.runConversionFromSI(runtime.conversionPartner(item, null, null, null));
                                                }
                                                runtime.temporaryInformation = runtime.TI_CONV_MENU_STR;
                                            }
                                        }

                                        if (runtime.calcMode == runtime.CM_EIM and runtime.tam.mode == 0) {
                                            if (runtime.isAlphaSubmenu(0)) {
                                                while (runtime.currentMenu() != -runtime.MNU_EQ_EDIT) {
                                                    runtime.popSoftmenu();
                                                }
                                            }
                                        } else if (((runtime.calcMode == runtime.CM_PEM and runtime.tam.mode == 0 and runtime.getSystemFlag(runtime.FLAG_ALPHA)) or runtime.calcMode == runtime.CM_AIM) and runtime.itemFuncIsAddItemToBuffer(item)) {
                                            runtime.popSoftmenu();
                                        }
                                    }
                                }
                            }
                        }

                        // noMoreToDo:
                        _closeCatalog();
                        runtime.fnKeyInCatalog = false;
                    } else if (runtime.calcMode == runtime.CM_CONFIRMATION and (item == runtime.ITM_YES or item == runtime.ITM_NO)) {
                        runtime.runFunction(item);
                    }
                } else if (runtime.calcMode == runtime.CM_CONFIRMATION) {
                    runtime.temporaryInformation = runtime.TI_ARE_YOU_SURE;
                }
            }
            runtime.refreshScreen(114);
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
        }

        // keyboard.c CatalogMenus[] (398-423): menus closed on a real CAT entry.
        const catalog_menus = [_]i16{
            runtime.MNU_ALPHA_OMEGA, runtime.MNU_ALPHAMISC, runtime.MNU_ALPHA,
            runtime.MNU_FCNS,        runtime.MNU_CONST,     runtime.MNU_CHARS,
            runtime.MNU_PROGS,       runtime.MNU_VARS,      runtime.MNU_MENUS,
            runtime.MNU_CONFIGS,     runtime.MNU_MATRS,     runtime.MNU_DATES,
            runtime.MNU_TIMES,       runtime.MNU_SINTS,     runtime.MNU_STRINGS,
            runtime.MNU_NUMBRS,      runtime.MNU_CPXS,      runtime.MNU_REALS,
            runtime.MNU_ANGLES,      runtime.MNU_LINTS,     runtime.MNU_ALLVARS,
        };

        pub fn closeAllCatalogMenus() void {
            // keyboard.c closeAllCatalogMenus (425-434).
            const menu_id = -runtime.currentMenu();
            for (catalog_menus) |cm| {
                if (menu_id == cm) {
                    runtime.popSoftmenu();
                    break;
                }
            }
        }

        pub fn assignToMenu(data: [*c]u8) runtime.bool_t {
            // keyboard.c _assignToMenu (748-807). goto endReturnTrue -> labeled block.
            const position: u16 = @intCast((@as(i32, data[0]) - '1') + (if (runtime.shiftG) @as(i32, 12) else if (runtime.shiftF) @as(i32, 6) else 0));
            end_true: {
                switch (-runtime.currentMenu()) {
                    runtime.MNU_MyMenu => {
                        runtime.assignToMyMenu(position);
                        break :end_true;
                    },
                    runtime.MNU_MyAlpha => {
                        runtime.assignToMyAlpha(position);
                        break :end_true;
                    },
                    runtime.MNU_DYNAMIC => {
                        runtime.assignToUserMenu(position);
                        break :end_true;
                    },
                    runtime.MNU_HOME => {
                        if (!runtime.setCurrentUserMenu(-runtime.MNU_DYNAMIC, @constCast("HOME"))) {
                            return false;
                        }
                        runtime.assignToUserMenu(position);
                        break :end_true;
                    },
                    runtime.MNU_PFN => {
                        if (!runtime.setCurrentUserMenu(-runtime.MNU_DYNAMIC, @constCast("P.FN"))) {
                            return false;
                        }
                        runtime.assignToUserMenu(position);
                        break :end_true;
                    },
                    runtime.MNU_CATALOG, runtime.MNU_ALPHA, runtime.MNU_CHARS, runtime.MNU_PROGS, runtime.MNU_VARS, runtime.MNU_MENUS => {
                        runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
                        return false;
                    },
                    else => {
                        runtime.displayCalcErrorMessage(runtime.ERROR_CANNOT_ASSIGN_HERE, runtime.ERR_REGISTER_LINE, runtime.NIM_REGISTER_LINE);
                        if (comptime !runtime.is_dmcp_build) {
                            runtime.moreInfoOnError("In function _assignToMenu:", "the menu", runtime.indexOfItemsCatalogName(-runtime.currentMenu()), "is write-protected.");
                        }
                        // C falls through into endReturnTrue.
                    },
                }
            }
            // endReturnTrue:
            runtime.calcMode = runtime.previousCalcMode;
            runtime.shiftF = false;
            runtime.shiftG = false;
            _closeCatalog();
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
            runtime.refreshScreen(103);
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_ONE_TIME_FLAGS;
            return true;
        }

        pub fn _closeCatalog() void {
            // keyboard.c _closeCatalog (437-469).
            var in_catalog = false;
            var i: usize = 0;
            while (i < runtime.SOFTMENU_STACK_SIZE) : (i += 1) {
                if (runtime.softmenu[@intCast(runtime.softmenuStack[i].softmenuId)].menuItem == -runtime.MNU_CATALOG) {
                    in_catalog = true;
                    break;
                }
            }
            if (in_catalog or runtime.currentMenu() == -runtime.MNU_CONST) {
                switch (-runtime.currentMenu()) {
                    runtime.MNU_TAM, runtime.MNU_TAMVARONLY, runtime.MNU_TAMNONREG, runtime.MNU_TAMCMP, runtime.MNU_TAMSTO, runtime.MNU_TAMRCL, runtime.MNU_TAMFLAG, runtime.MNU_TAMSHUFFLE, runtime.MNU_TAMLABEL, runtime.MNU_TAMLBLONLY, runtime.MNU_TAMLOCALLABEL, runtime.ITM_DELITM => {
                        // TAM menus are processed elsewhere.
                    },
                    else => {
                        runtime.leaveAsmMode();
                        closeAllCatalogMenus();
                    },
                }
            }
        }

        pub fn determineItem(data: [*c]const u8) i16 {
            // keyboard.c determineItem (1511-1734). VERBOSEKEYS / jm_show_comment
            // tracing dropped. stringToKeyNumber is the inline macro.
            const ITM_0: i16 = @intCast(runtime.ITM_0);
            const ITM_9: i16 = @intCast(runtime.ITM_9);

            runtime.delayCloseNim = false;
            var result: i16 = 0;
            runtime.dynamicMenuItem = -1;
            const key_no: i8 = @intCast((@as(i32, data[0]) - '0') * 10 + @as(i32, data[1]) - '0');
            const key: runtime.calcKey_t = if (runtime.getSystemFlag(runtime.FLAG_USER)) runtime.kbd_usr[@intCast(key_no)] else runtime.kbdStdAt(@intCast(key_no));

            runtime.fnTimerExec(runtime.TO_FN_EXEC);

            if ((key.primary != runtime.ITM_SHIFTf) and (key.primary != runtime.KEY_fg) and (!runtime.showMode() or !(key.primary == runtime.ITM_RCL or key.primary == runtime.ITM_RS or key.primary == runtime.ITM_UP1 or key.primary == runtime.ITM_DOWN1 or (runtime.allowShowDigits and key.primary >= ITM_0 and key.primary <= ITM_9)))) {
                runtime.showRegis = 9999;
            }

            var shiftOverride: i16 = 0;
            result = runtime.normKey00ItemInLayout();
            shiftOverride = runtime.Check_Norm_Key_00_Assigned(&result, key_no);

            if (shiftOverride == 0) {
                runtime.Setup_MultiPresses(key.primary);
            }

            // SHOWMODE f / fg: send EXIT over to the key release.
            if (runtime.showMode() and (key.primary == runtime.KEY_fg or key.primary == runtime.ITM_SHIFTf)) {
                runtime.shiftF = true;
                runtime.shiftG = false;
                runtime.lastItem = key.primary;
                runtime.resetKeytimers();
                runtime.screenUpdatingMode = runtime.SCRUPD_MANUAL_STATUSBAR | runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_SHIFT_STATUS;
                return runtime.ITM_NOP;
            }

            // shift-button processing
            if (runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_NIM or runtime.calcMode == runtime.CM_MIM or runtime.calcMode == runtime.CM_EIM or runtime.calcMode == runtime.CM_PEM or runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_GRAPH or runtime.calcMode == runtime.CM_ASSIGN or runtime.calcMode == runtime.CM_ASN_BROWSER or runtime.calcMode == runtime.CM_REGISTER_BROWSER or runtime.calcMode == runtime.CM_FLAG_BROWSER or runtime.calcMode == runtime.CM_FONT_BROWSER or runtime.calcMode == runtime.CM_TIMER) {
                if (key.primary == runtime.ITM_SHIFTf or shiftOverride == runtime.ITM_SHIFTf) {
                    commonShiftProcessing(@intCast(runtime.ITM_SHIFTf));
                    return runtime.ITM_NOP;
                } else if (key.primary == runtime.ITM_SHIFTg or shiftOverride == runtime.ITM_SHIFTg) {
                    commonShiftProcessing(@intCast(runtime.ITM_SHIFTg));
                    return runtime.ITM_NOP;
                } else if (key.primary == runtime.KEY_fg or shiftOverride == runtime.KEY_fg) {
                    commonShiftProcessing(@intCast(runtime.KEY_fg));
                    return runtime.ITM_NOP;
                }
            } else if ((key.primary == runtime.KEY_fg or key.primary == runtime.ITM_SHIFTf or key.primary == runtime.ITM_SHIFTg) and (runtime.calcMode == runtime.CM_PLOT_STAT or runtime.calcMode == runtime.CM_LISTXY)) {
                if (runtime.lastErrorCode != 0) {
                    runtime.shiftKeyClearsError = true;
                }
                if (runtime.programRunStop == runtime.PGM_WAITING) {
                    runtime.programRunStop = runtime.PGM_STOPPED;
                }
                runtime.lastErrorCode = 0;
                return runtime.ITM_NOP;
            }

            if (runtime.tam.mode == 0 and (runtime.calcMode == runtime.CM_NIM or runtime.calcMode == runtime.CM_NORMAL) and (runtime.lastIntegerBase >= 2 and runtime.getSystemFlag(runtime.FLAG_TOPHEX)) and (key_no >= 0 and key_no <= 5)) {
                result = if (runtime.shiftF) key.fShifted else if (runtime.shiftG) key.gShifted else key.primaryAim;
                switch (result) {
                    runtime.ITM_SHIFTf, runtime.ITM_SHIFTg, runtime.KEY_fg => result = runtime.ITM_NOP,
                    else => {},
                }
                runtime.Check_MultiPresses(&result, key_no);
                return result;
            } else if (runtime.calcMode == runtime.CM_AIM or (runtime.catalog != 0 and runtime.catalog != runtime.CATALOG_MVAR and runtime.calcMode != runtime.CM_NIM) or runtime.calcMode == runtime.CM_EIM or runtime.tam.alpha or (runtime.calcMode == runtime.CM_ASSIGN and (runtime.previousCalcMode == runtime.CM_AIM or runtime.previousCalcMode == runtime.CM_EIM)) or (runtime.calcMode == runtime.CM_PEM and runtime.getSystemFlag(runtime.FLAG_ALPHA))) {
                result = if (runtime.shiftF) key.fShiftedAim else if (runtime.shiftG) key.gShiftedAim else key.primaryAim;
                if (runtime.calcMode == runtime.CM_PEM and runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                    if (result == runtime.ITM_DOWN_ARROW or runtime.scrLock == runtime.NC_SUBSCRIPT) {
                        runtime.nextChar = runtime.NC_SUBSCRIPT;
                    } else if (result == runtime.ITM_UP_ARROW or runtime.scrLock == runtime.NC_SUPERSCRIPT) {
                        runtime.nextChar = runtime.NC_SUPERSCRIPT;
                    }
                } else if ((result == runtime.ITM_COMMA or result == runtime.ITM_PERIOD) and (runtime.calcMode == runtime.CM_EIM or runtime.calcMode == runtime.CM_AIM) and runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                    switch ((@as(i16, if (runtime.shiftG) 2 else 0)) + (@as(i16, if (runtime.getSystemFlag(runtime.FLAG_NUMLOCK)) 1 else 0))) {
                        1 => result = runtime.radix34MarkDecItm(),
                        3 => result = runtime.radix34MarkNotDecItm(),
                        else => {},
                    }
                }
                if ((runtime.calcMode == runtime.CM_EIM) and (result == -runtime.MNU_AIMCATALOG)) {
                    result = -runtime.MNU_EIMCATALOG;
                }
            } else if (runtime.tam.mode != 0) {
                result = key.primaryTam;
            } else if (runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_NIM or runtime.calcMode == runtime.CM_MIM or runtime.calcMode == runtime.CM_FONT_BROWSER or runtime.calcMode == runtime.CM_FLAG_BROWSER or runtime.calcMode == runtime.CM_ASN_BROWSER or runtime.calcMode == runtime.CM_REGISTER_BROWSER or runtime.calcMode == runtime.CM_BUG_ON_SCREEN or runtime.calcMode == runtime.CM_CONFIRMATION or runtime.calcMode == runtime.CM_PEM or isGraphMode() or runtime.calcMode == runtime.CM_ASSIGN or runtime.calcMode == runtime.CM_TIMER or runtime.calcMode == runtime.CM_LISTXY) {
                result = if (runtime.shiftF) key.fShifted else if (runtime.shiftG) key.gShifted else key.primary;
                if (runtime.calcMode == runtime.CM_REGISTER_BROWSER) {
                    if (runtime.shiftF and key.primaryAim >= runtime.ITM_A and key.primaryAim <= runtime.ITM_Z) {
                        result = key.primaryAim;
                    }
                }
            } else {
                runtime.displayBugScreen("In function determineItem: item was not determined!");
                result = 0;
            }

            if (runtime.Check_Norm_Key_00_Assigned(&result, key_no) == 0) {
                runtime.Check_MultiPresses(&result, key_no);
            }

            if (result == runtime.ITM_PROD_SIGN) {
                result = if (runtime.getSystemFlag(runtime.FLAG_MULTx)) runtime.ITM_CROSS else runtime.ITM_DOT;
            }

            if (result != runtime.ITM_SNAP) {
                runtime.resetShiftState();
            }

            if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and (result == runtime.ITM_NOP or result == runtime.ITM_NULL)) {
                result = runtime.ITM_LBL;
            }

            if (runtime.calcMode == runtime.CM_REGISTER_BROWSER) {
                switch (key.primary) {
                    ITM_0...ITM_9, runtime.ITM_RCL => {},
                    else => {
                        if (key.primaryAim >= runtime.ITM_A and key.primaryAim <= runtime.ITM_Z) {
                            result = key.primaryAim;
                        }
                    },
                }
            }
            return result;
        }

        pub fn commonShiftProcessing(shiftkey: u16) void {
            // keyboard.c commonShiftProcessing (1437-1507). VERBOSEKEYS dropped.
            const sk: i16 = @intCast(shiftkey);
            if (sk == runtime.KEY_fg) {
                runtime.Shft_LongPress_f_g = false;
                runtime.Shft_timeouts = true;
                runtime.fnTimerStart(runtime.TO_FG_LONG, @intCast(runtime.TO_FG_LONG), runtime.JM_TO_FG_LONG);
                if (runtime.getSystemFlag(runtime.FLAG_SHFT_4s)) {
                    runtime.fnTimerStart(runtime.TO_FG_TIMR, @intCast(runtime.TO_FG_TIMR), runtime.JM_SHIFT_TIMER);
                }
            } else if (sk == runtime.ITM_SHIFTf or sk == runtime.ITM_SHIFTg) {
                runtime.Shft_LongPress_f_g = true;
                if (runtime.Shft_LongPress_f_g and runtime.getSystemFlag(runtime.FLAG_SH_LONGPRESS)) {
                    runtime.fnTimerStart(runtime.TO_FG_LONG, @intCast(runtime.TO_FG_LONG), @intFromFloat(@as(f64, @floatFromInt(runtime.JM_TO_FG_LONG)) * 1.5));
                }
            }

            if (runtime.temporaryInformation == runtime.TI_VIEW_REGISTER or runtime.showMode()) {
                runtime.shiftKeyClearsError = true;
            }
            if (runtime.temporaryInformation == runtime.TI_VIEW_REGISTER) {
                runtime.temporaryInformation = runtime.TI_NO_INFO;
                runtime.updateMatrixHeightCache();
            }
            if (runtime.lastErrorCode != 0) {
                runtime.shiftKeyClearsError = true;
            }
            if (runtime.programRunStop == runtime.PGM_WAITING) {
                runtime.programRunStop = runtime.PGM_STOPPED;
            }
            runtime.lastErrorCode = 0;

            if (sk == runtime.KEY_fg) {
                runtime.fg_processing_jm();
            } else if (sk == runtime.ITM_SHIFTf) {
                runtime.shiftF = !runtime.shiftF;
                runtime.shiftG = false;
            } else if (sk == runtime.ITM_SHIFTg) {
                runtime.shiftF = false;
                runtime.shiftG = !runtime.shiftG;
            }
            runtime.lastshiftF = runtime.shiftF;
            runtime.lastshiftG = runtime.shiftG;

            if (runtime.temporaryInformation != runtime.TI_NO_INFO and !runtime.shiftG and !runtime.shiftF) {
                runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_SHIFT_STATUS | runtime.SCRUPD_MANUAL_STACK);
                runtime.temporaryInformation = runtime.TI_NO_INFO;
                runtime.refreshScreen(1201);
            }

            if (runtime.showMode() or runtime.currentMenu() == -runtime.MNU_SHOW) {
                runtime.closeShowMenu();
            }

            runtime.showShiftState();
            runtime.refreshModeGui();
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_SHIFT_STATUS;
        }

        // determineFunctionKeyItem_C47 default/MNU_EQN-fallthrough case body.
        fn fnKeyItemDefault(menuId: i16, firstItem: i16, itemShift: i16, fn_: i16) i16 {
            var item: i16 = runtime.ITM_NOP;
            const sm = &runtime.softmenu[@intCast(menuId)];
            const row: i32 = @min(@as(i32, 3), @divTrunc(@as(i32, sm.numItems) + runtime.modulo(firstItem - sm.numItems, 6), 6) - @divTrunc(@as(i32, firstItem), 6)) - 1;
            if (@divTrunc(@as(i32, itemShift), 6) <= row and firstItem + itemShift + fn_ < sm.numItems) {
                item = @rem(sm.softkeyItem[@intCast(firstItem + itemShift + fn_)], 10000);
                if (item == runtime.ITM_PROD_SIGN) {
                    item = if (runtime.getSystemFlag(runtime.FLAG_MULTx)) runtime.ITM_DOT else runtime.ITM_CROSS;
                }
                if (runtime.softmenu[@intCast(menuId)].menuItem == -runtime.MNU_ALPHA and runtime.calcMode == runtime.CM_PEM and item == runtime.ITM_ASSIGN) {
                    item = runtime.ITM_NULL;
                }
            }
            return item;
        }

        pub fn determineFunctionKeyItem_C47(data: [*c]const u8, shiftF: runtime.bool_t, shiftG: runtime.bool_t) i16 {
            // keyboard.c determineFunctionKeyItem_C47 (12-333). VERBOSEKEYS /
            // PC_BUILD jm_show_comment tracing dropped.
            var item: i16 = runtime.ITM_NOP;
            runtime.dynamicMenuItem = -1;
            const itemShift: i16 = if (shiftF) 6 else if (shiftG) 12 else 0;
            const fn_: i16 = @as(i16, data[0]) - '0' - 1;
            const menuId: i16 = runtime.softmenuStack[0].softmenuId;
            const firstItem: i16 = runtime.softmenuStack[0].firstItem;

            if (runtime.isBaseBlank(menuId)) {
                return item;
            }

            switch (-runtime.softmenu[@intCast(menuId)].menuItem) {
                runtime.MNU_MyMenu => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = runtime.userMenuItems[@intCast(runtime.dynamicMenuItem)].item;
                    _ = runtime.setCurrentUserMenu(item, &runtime.userMenuItems[@intCast(runtime.dynamicMenuItem)].argumentName);
                },
                runtime.MNU_MyAlpha => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = runtime.userAlphaItems[@intCast(runtime.dynamicMenuItem)].item;
                },
                runtime.MNU_DYNAMIC => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = runtime.userMenus[runtime.currentUserMenu].menuItem[@intCast(runtime.dynamicMenuItem)].item;
                },
                runtime.MNU_PROG => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    if (runtime.tam.function == runtime.ITM_GTOP) {
                        item = if (runtime.dynamicMenuItem >= runtime.dynamicSoftmenu[@intCast(menuId)].numItems) runtime.ITM_NOP else runtime.ITM_GTOP;
                    } else {
                        item = if (runtime.dynamicMenuItem >= runtime.dynamicSoftmenu[@intCast(menuId)].numItems) runtime.ITM_NOP else runtime.MNU_DYNAMIC;
                    }
                },
                runtime.MNU_VAR => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = if (runtime.dynamicMenuItem >= runtime.dynamicSoftmenu[@intCast(menuId)].numItems) runtime.ITM_NOP else runtime.MNU_DYNAMIC;
                },
                runtime.MNU_MVAR => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    const numItems = runtime.dynamicSoftmenu[@intCast(menuId)].numItems;
                    const usesFormulaInteractive = (runtime.currentSolverStatus & runtime.SOLVER_STATUS_USES_FORMULA) != 0 and (runtime.currentSolverStatus & runtime.SOLVER_STATUS_INTERACTIVE) != 0;
                    const eqnMode = runtime.currentSolverStatus & runtime.SOLVER_STATUS_EQUATION_MODE;
                    if (runtime.tam.mode != 0) {
                        item = if (runtime.dynamicMenuItem >= numItems) runtime.ITM_NOP else runtime.MNU_DYNAMIC;
                    } else if (runtime.currentMvarLabel != runtime.INVALID_VARIABLE) {
                        item = if (runtime.dynamicMenuItem >= numItems) runtime.ITM_NOP else runtime.ITM_SOLVE_VAR;
                    } else if (usesFormulaInteractive and eqnMode == runtime.SOLVER_STATUS_EQUATION_GRAPHER and runtime.dynamicMenuItem == 5) {
                        item = runtime.ITM_DRAW;
                    } else if (usesFormulaInteractive and eqnMode == runtime.SOLVER_STATUS_EQUATION_GRAPHER and runtime.dynamicMenuItem == 4) {
                        item = -runtime.MNU_GRAPHS;
                    } else if (usesFormulaInteractive and eqnMode == runtime.SOLVER_STATUS_EQUATION_SOLVER and runtime.dynamicMenuItem == 5) {
                        item = runtime.ITM_CALC;
                    } else if (usesFormulaInteractive and eqnMode == runtime.SOLVER_STATUS_EQUATION_SOLVER and runtime.dynamicMenuItem == 4) {
                        item = -runtime.MNU_Solver_TOOL;
                    } else if (usesFormulaInteractive and runtime.getNthString(runtime.dynamicSoftmenu[@intCast(runtime.softmenuStack[0].softmenuId)].menuContent, runtime.dynamicMenuItem)[0] == 0) {
                        item = runtime.ITM_NOP;
                    } else if (runtime.isEqn1stDer() and runtime.dynamicMenuItem == 5) {
                        item = runtime.ITM_FPHERE;
                    } else if (runtime.isEqn1stDer() and runtime.dynamicMenuItem == 4) {
                        item = -runtime.MNU_GRAPHS;
                    } else if (runtime.isEqn2ndDer() and runtime.dynamicMenuItem == 5) {
                        item = runtime.ITM_FPPHERE;
                    } else if (runtime.isEqn2ndDer() and runtime.dynamicMenuItem == 4) {
                        item = -runtime.MNU_GRAPHS;
                    } else if (runtime.dynamicMenuItem >= numItems) {
                        item = runtime.ITM_NOP;
                    } else if ((runtime.currentSolverStatus & runtime.SOLVER_STATUS_INTERACTIVE) == 0) {
                        item = runtime.MNU_DYNAMIC;
                    } else if (runtime.isEqnIntegrate() and runtime.dynamicMenuItem == 4) {
                        item = -runtime.MNU_Sf_TOOL;
                    } else if (runtime.isEqnIntegrate() and runtime.dynamicMenuItem == 5) {
                        item = runtime.ITM_INTEGRAL_YX;
                    } else if (runtime.isEqnIntegrate()) {
                        item = runtime.ITM_Sfdx_VAR;
                    } else {
                        item = runtime.ITM_SOLVE_VAR;
                    }
                },
                runtime.MNU_CONFIGS, runtime.MNU_MATRS, runtime.MNU_DATES, runtime.MNU_TIMES, runtime.MNU_SINTS, runtime.MNU_STRINGS, runtime.MNU_NUMBRS, runtime.MNU_CPXS, runtime.MNU_REALS, runtime.MNU_ANGLES, runtime.MNU_LINTS, runtime.MNU_ALLVARS => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = if (runtime.dynamicMenuItem >= runtime.dynamicSoftmenu[@intCast(menuId)].numItems) runtime.ITM_NOP else if (runtime.tam.mode == runtime.TM_DELITM) runtime.MNU_DYNAMIC else runtime.ITM_RCL;
                },
                runtime.MNU_PROGS => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = if (runtime.dynamicMenuItem >= runtime.dynamicSoftmenu[@intCast(menuId)].numItems) runtime.ITM_NOP else if (runtime.tam.mode == runtime.TM_DELITM) runtime.MNU_DYNAMIC else runtime.ITM_XEQ;
                },
                runtime.MNU_MENU, runtime.MNU_MENUS => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = runtime.ITM_NOP;
                    if (runtime.dynamicMenuItem < runtime.dynamicSoftmenu[@intCast(menuId)].numItems) {
                        var i: u16 = 0;
                        while (runtime.softmenu[i].menuItem < 0) : (i += 1) {
                            if (runtime.compareString(runtime.getNthString(runtime.dynamicSoftmenu[@intCast(menuId)].menuContent, runtime.dynamicMenuItem), runtime.indexOfItemsCatalogName(-runtime.softmenu[i].menuItem), runtime.CMP_NAME) == 0) {
                                if (runtime.tam.mode == runtime.TM_DELITM) {
                                    item = runtime.MNU_DYNAMIC;
                                    runtime.tam.value = @intCast(runtime.numberOfUserMenus);
                                } else {
                                    item = runtime.softmenu[i].menuItem;
                                }
                            }
                        }
                        var j: u32 = 0;
                        while (j < runtime.numberOfUserMenus) : (j += 1) {
                            if (runtime.compareString(runtime.getNthString(runtime.dynamicSoftmenu[@intCast(menuId)].menuContent, runtime.dynamicMenuItem), &runtime.userMenus[j].menuName, runtime.CMP_NAME) == 0) {
                                if (runtime.tam.mode == runtime.TM_DELITM) {
                                    item = runtime.MNU_DYNAMIC;
                                    runtime.tam.value = @intCast(j);
                                } else {
                                    item = -runtime.MNU_DYNAMIC;
                                    if (runtime.calcMode != runtime.CM_ASSIGN) {
                                        runtime.currentUserMenu = @intCast(j);
                                    }
                                }
                            }
                        }
                    }
                },
                runtime.ITM_MENU => {
                    runtime.dynamicMenuItem = firstItem + itemShift + fn_;
                    item = runtime.ITM_MENU;
                },
                runtime.MNU_EQN => {
                    if (!(runtime.numberOfFormulae == 0 and (firstItem + itemShift + fn_) > 0)) {
                        item = fnKeyItemDefault(menuId, firstItem, itemShift, fn_);
                    }
                },
                else => {
                    item = fnKeyItemDefault(menuId, firstItem, itemShift, fn_);
                },
            }

            if (runtime.calcMode == runtime.CM_ASSIGN and item != runtime.ITM_NOP and item != runtime.ITM_NULL) {
                switch (-runtime.softmenu[@intCast(menuId)].menuItem) {
                    runtime.MNU_PROG, runtime.MNU_PROGS => {
                        return @intCast(@as(i32, runtime.findNamedLabel(runtime.getNthString(runtime.dynamicSoftmenu[@intCast(menuId)].menuContent, runtime.dynamicMenuItem), runtime.GLOBAL_LABELS)) - runtime.FIRST_LABEL + runtime.ASSIGN_LABELS);
                    },
                    runtime.MNU_VAR, runtime.MNU_CONFIGS, runtime.MNU_MATRS, runtime.MNU_DATES, runtime.MNU_TIMES, runtime.MNU_SINTS, runtime.MNU_STRINGS, runtime.MNU_NUMBRS, runtime.MNU_CPXS, runtime.MNU_REALS, runtime.MNU_ANGLES, runtime.MNU_LINTS, runtime.MNU_ALLVARS => {
                        return @intCast(@as(i32, runtime.findNamedVariable(runtime.getNthString(runtime.dynamicSoftmenu[@intCast(menuId)].menuContent, runtime.dynamicMenuItem))) - runtime.FIRST_NAMED_VARIABLE + runtime.ASSIGN_NAMED_VARIABLES);
                    },
                    runtime.MNU_MENUS => {
                        if (item == -runtime.MNU_DYNAMIC) {
                            var i: i32 = 0;
                            while (i < runtime.numberOfUserMenus) : (i += 1) {
                                if (runtime.compareString(runtime.getNthString(runtime.dynamicSoftmenu[@intCast(menuId)].menuContent, runtime.dynamicMenuItem), &runtime.userMenus[@intCast(i)].menuName, runtime.CMP_NAME) == 0) {
                                    return @intCast(@as(i32, runtime.ASSIGN_USER_MENU) - i);
                                }
                            }
                            runtime.displayBugScreen("In function determineFunctionKeyItem: nonexistent menu specified!");
                            return item;
                        } else {
                            return item;
                        }
                    },
                    else => {
                        return item;
                    },
                }
            } else {
                if (item == 0) {
                    return runtime.ITM_NOP;
                }
                return item;
            }
        }

        pub fn checkKeyShifts(data: [*c]const u8) runtime.bool_t {
            // keyboard.c checkKeyShifts (2014-2027). stringToKeyNumber(data) is a
            // macro: (data[0]-'0')*10 + data[1]-'0' (keyboard.c:1434).
            const key_no: usize = @intCast((@as(i32, data[0]) - '0') * 10 + @as(i32, data[1]) - '0');
            const use_usr = runtime.getSystemFlag(runtime.FLAG_USER) and
                (runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_AIM or
                    runtime.calcMode == runtime.CM_EIM or runtime.calcMode == runtime.CM_NIM);
            const primary = if (use_usr) runtime.kbd_usr[key_no].primary else runtime.kbdStdAt(key_no).primary;
            return primary == runtime.ITM_SHIFTf or primary == runtime.ITM_SHIFTg or primary == runtime.KEY_fg;
        }

        pub fn leavePem() void {
            // keyboard.c leavePem (2309-2334): push programs to the end of RAM.
            if (runtime.freeProgramBytes >= 4) {
                const byte_diff: usize = @intFromPtr(runtime.ram + runtime.RAM_SIZE_IN_BLOCKS) - @intFromPtr(runtime.beginOfProgramMemory);
                const new_program_size: u32 = @as(u32, @truncate(byte_diff)) - @as(u32, runtime.freeProgramBytes & 0xfffc);
                const local_step_number = runtime.currentLocalStepNumber;
                const program_number = runtime.currentProgramNumber;
                const fd_local_step_number = runtime.firstDisplayedLocalStepNumber;
                const in_ram = runtime.programList[@as(usize, runtime.currentProgramNumber) - 1].step > 0;
                if (in_ram) {
                    const off: usize = runtime.freeProgramBytes & 0xfffc;
                    runtime.currentStep += off;
                    runtime.firstDisplayedStep += off;
                    runtime.beginOfCurrentProgram += off;
                    runtime.endOfCurrentProgram += off;
                }
                runtime.freeProgramBytes &= 0x03;
                runtime.resizeProgramMemory(runtime.toBlocks(new_program_size));
                runtime.scanLabelsAndPrograms();
                if (in_ram) {
                    runtime.currentLocalStepNumber = local_step_number;
                    runtime.currentProgramNumber = program_number;
                    runtime.firstDisplayedLocalStepNumber = fd_local_step_number;
                    runtime.defineCurrentStep();
                    runtime.defineFirstDisplayedStep();
                    runtime.defineCurrentProgramFromCurrentStep();
                }
            }
        }

        pub fn processAimInput(item: i16) void {
            // keyboard.c processAimInput (475-568). The PC_BUILD jm_show_comment
            // tracing is dropped (empty without PC_BUILD_VERBOSE2, which is #undef).
            var item1: i16 = 0;

            if (runtime.scrLock != runtime.NC_NORMAL) {
                runtime.nextChar = runtime.scrLock;
            }

            var itemOut: i16 = item;
            if (keyReplacements(item, &item1, runtime.getSystemFlag(runtime.FLAG_NUMLOCK), runtime.lastshiftF, runtime.lastshiftG)) {
                if (item1 > 0) {
                    runtime.addItemToBuffer(@bitCast(item1));
                    runtime.keyActionProcessed = true;
                }
            } else if (caseReplacements(runtime.lowercaseSelected(), item, &itemOut)) {
                runtime.addItemToBuffer(@bitCast(itemOut));
                runtime.keyActionProcessed = true;
            } else if (item == runtime.ITM_COLON or item == runtime.ITM_COMMA or item == runtime.ITM_QUESTION_MARK or item == runtime.ITM_SPACE or item == runtime.ITM_UNDERSCORE) {
                runtime.addItemToBuffer(@bitCast(item));
                runtime.keyActionProcessed = true;
            } else if (item == runtime.ITM_DOWN_ARROW) {
                if (runtime.nextChar == runtime.NC_NORMAL) {
                    runtime.nextChar = runtime.NC_SUBSCRIPT;
                } else if (runtime.nextChar == runtime.NC_SUPERSCRIPT) {
                    runtime.nextChar = runtime.NC_NORMAL;
                }
                runtime.keyActionProcessed = true;
            } else if (item == runtime.ITM_UP_ARROW) {
                if (runtime.nextChar == runtime.NC_NORMAL) {
                    runtime.nextChar = runtime.NC_SUPERSCRIPT;
                } else if (runtime.nextChar == runtime.NC_SUBSCRIPT) {
                    runtime.nextChar = runtime.NC_NORMAL;
                }
                runtime.keyActionProcessed = true;
            } else if (item >= 0 and runtime.itemFuncIsAddItemToBuffer(item)) {
                // C reads indexOfItems[item] unguarded; negative menu items reach
                // here (processKeyAction's tam.alpha path forwards item < 0), so the
                // index is guarded to avoid the panic. The OOB read in C effectively
                // never matches addItemToBuffer, so item < 0 -> no action, as here.
                runtime.addItemToBuffer(@bitCast(item));
                runtime.keyActionProcessed = true;
            }

            if (runtime.keyActionProcessed) {
                runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
            }

            runtime.showHideAlphaMode();
        }

        pub fn processKeyAction(item_arg: i16) void {
            // keyboard.c processKeyAction (2336-3293). `item` is reassigned in
            // several prongs, so take a mutable local copy of the argument.
            var item = item_arg;
            // ITM_0/ITM_9/ITM_NOP/INVALID_VARIABLE are u16 in the runtime; alias
            // them as i16 for arithmetic/comparison against the signed `item`.
            const ITM_0: i16 = @intCast(runtime.ITM_0);
            const ITM_9: i16 = @intCast(runtime.ITM_9);
            const INVALID_VARIABLE: i16 = @intCast(runtime.INVALID_VARIABLE);

            runtime.keyActionProcessed = false;

            if (runtime.lastErrorCode != 0 and item != runtime.ITM_EXIT1 and item != runtime.ITM_BACKSPACE) {
                runtime.lastErrorCode = 0;
                runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                runtime.refreshScreen(138);
            }

            if (runtime.temporaryInformation == runtime.TI_VIEW_REGISTER) {
                runtime.temporaryInformation = runtime.TI_NO_INFO;
                runtime.updateMatrixHeightCache();
                if (item == runtime.ITM_UP1 or item == runtime.ITM_DOWN1 or item == runtime.ITM_EXIT1 or item == runtime.ITM_BACKSPACE) {
                    runtime.temporaryInformation = runtime.TI_VIEW_REGISTER;
                }
            } else if (runtime.temporaryInformation != runtime.TI_NO_INFO and item != runtime.ITM_UP1 and item != runtime.ITM_DOWN1 and item != runtime.ITM_EXIT1 and item != runtime.ITM_BACKSPACE and
                !(((item == runtime.ITM_RCL or item == runtime.ITM_RS or (item >= ITM_0 and item <= ITM_9 and runtime.allowShowDigits)) and runtime.showMode())))
            {
                if (runtime.showMode()) {
                    runtime.closeShowMenu();
                }
                runtime.temporaryInformation = runtime.TI_NO_INFO;
                runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
            }

            if (runtime.calcMode == runtime.CM_GRAPH and runtime.currentMenu() == -runtime.MNU_PLOT_FUNC and ((item >= ITM_0 and item <= ITM_9) or item == runtime.ITM_PERIOD)) {
                runtime.calcMode = runtime.CM_NORMAL;
                runtime.showSoftmenu(-runtime.MNU_GRAPHS);
                runtime.screenUpdatingMode &= runtime.SCRUPD_MANUAL_MENU;
                runtime.refreshScreen(125);
            }

            if (runtime.programRunStop == runtime.PGM_WAITING) {
                runtime.programRunStop = runtime.PGM_STOPPED;
            }

            if (item == runtime.KEY_COMPLEX and runtime.calcMode == runtime.CM_MIM) {
                item = runtime.ITM_CC;
            }

            if (runtime.calcMode == runtime.CM_NORMAL and runtime.showMode() and runtime.currentMenu() != -runtime.MNU_EQN) {
                switch (item) {
                    runtime.ITM_UP1, runtime.ITM_DOWN1, runtime.ITM_RS => {
                        runtime.fnC47Show(@bitCast(item));
                        runtime.keyActionProcessed = true;
                        return;
                    },
                    else => {},
                }
            }

            if (isGraphMode()) {
                runtime.temporaryInformation = runtime.TI_NO_INFO;
            }

            if (isGraphMode() and item != runtime.ITM_BACKSPACE and item != runtime.ITM_EXIT1 and item != runtime.ITM_UP1 and item != runtime.ITM_DOWN1 and item != runtime.ITM_SNAP) {
                runtime.keyActionProcessed = true;
            } else if (runtime.calcMode == runtime.CM_ASN_BROWSER and item != runtime.ITM_PERIOD and item != runtime.ITM_USERMODE and item != runtime.ITM_BACKSPACE and item != runtime.ITM_EXIT1 and item != runtime.ITM_UP1 and item != runtime.ITM_DOWN1) {
                runtime.keyActionProcessed = true;
            } else {
                switch (item) {
                    runtime.ITM_BACKSPACE => {
                        if (runtime.calcMode == runtime.CM_NIM or runtime.calcMode == runtime.CM_AIM or runtime.calcMode == runtime.CM_EIM) {
                            runtime.temporaryInformation = runtime.TI_NO_INFO;
                            runtime.refreshRegisterLine(runtime.NIM_REGISTER_LINE);
                        } else if (runtime.tam.mode != 0) {
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
                        } else if (runtime.calcMode == runtime.CM_PEM) {
                            // Let backspace fall through to Release, bypassing the
                            // fnKeyBackspace below (the C `break` does just this).
                        } else {
                            runtime.keyActionProcessed = true;
                            keyBackspace(runtime.NOPARAM);
                            if (runtime.calcMode != runtime.CM_CONFIRMATION) {
                                runtime.temporaryInformation = runtime.TI_NO_INFO;
                            }
                        }
                    },

                    runtime.ITM_UP1 => {
                        if (runtime.calcMode != runtime.CM_CONFIRMATION) {
                            runtime.keyActionProcessed = true;
                            keyUp(runtime.NOPARAM);
                            if (!runtime.keyActionProcessed) {
                                runtime.addItemToBuffer(@bitCast(runtime.ITM_UP_ARROW));
                            }
                            if (runtime.calcMode != runtime.CM_LISTXY and (runtime.currentSoftmenuScrolls() or !(runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_PEM) or runtime.temporaryInformation != runtime.TI_NO_INFO)) {
                                runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_STACK);
                                runtime.refreshScreen(118);
                            }
                            runtime.keyActionProcessed = true;
                        } else {
                            runtime.keyActionProcessed = true;
                        }
                    },

                    runtime.ITM_DOWN1 => {
                        if (runtime.calcMode != runtime.CM_CONFIRMATION) {
                            runtime.keyActionProcessed = true;
                            keyDown(runtime.NOPARAM);
                            if (!runtime.keyActionProcessed) {
                                runtime.addItemToBuffer(@bitCast(runtime.ITM_DOWN_ARROW));
                            }
                            if (runtime.calcMode != runtime.CM_LISTXY and (runtime.currentSoftmenuScrolls() or !(runtime.calcMode == runtime.CM_NORMAL or runtime.calcMode == runtime.CM_PEM) or runtime.temporaryInformation != runtime.TI_NO_INFO)) {
                                runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_STACK);
                                runtime.refreshScreen(119);
                            }
                            runtime.keyActionProcessed = true;
                        } else {
                            runtime.keyActionProcessed = true;
                        }
                    },

                    runtime.ITM_EXIT1 => {
                        if (runtime.showMode() or runtime.calcMode == runtime.CM_LISTXY) {
                            keyExit(runtime.NOPARAM);
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_PEM) {
                            if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                                keyExit(runtime.NOPARAM);
                                runtime.keyActionProcessed = true;
                            }
                        }
                        if ((runtime.temporaryInformation != runtime.TI_NO_INFO) and (runtime.calcMode != runtime.CM_CONFIRMATION)) {
                            runtime.temporaryInformation = runtime.TI_NO_INFO;
                            runtime.keyActionProcessed = true;
                            runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_MANUAL_STATUSBAR);
                            runtime.refreshScreen(120);
                        } else if (runtime.lastErrorCode != 0) {
                            runtime.lastErrorCode = 0;
                            runtime.refreshRegisterLine(runtime.ERR_REGISTER_LINE);
                            runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                            runtime.refreshScreen(139);
                            runtime.keyActionProcessed = true;
                        } else if (runtime.temporaryInformation == runtime.TI_NO_INFO and
                            ((runtime.softmenuStack[0].softmenuId == 0) or
                                ((runtime.programRunStop == runtime.PGM_RUNNING or runtime.programRunStop == runtime.PGM_PAUSED) and (item == runtime.ITM_RS or item == runtime.ITM_EXIT1))))
                        {
                            runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STATUSBAR | runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME);
                            runtime.refreshScreen(140);
                        }
                    },

                    runtime.ITM_op_j_pol, runtime.ITM_op_j, runtime.ITM_CC => {
                        if (runtime.calcMode == runtime.CM_ASSIGN) {
                            if (runtime.itemToBeAssigned == 0) {
                                runtime.itemToBeAssigned = item;
                            } else {
                                runtime.tamBuffer[0] = 0;
                            }
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_REGISTER_BROWSER or runtime.calcMode == runtime.CM_FLAG_BROWSER or runtime.calcMode == runtime.CM_ASN_BROWSER or runtime.calcMode == runtime.CM_FONT_BROWSER or runtime.calcMode == runtime.CM_TIMER) {
                            runtime.keyActionProcessed = true;
                        }
                    },

                    runtime.ITM_ENTER => {
                        if (runtime.calcMode == runtime.CM_ASSIGN) {
                            if (runtime.itemToBeAssigned == 0) {
                                if (runtime.tam.alpha) {
                                    runtime.assignLeaveAlpha();
                                    runtime.assignGetName1();
                                    if (runtime.menu(1) == -runtime.MNU_ALPHA) {
                                        runtime.popSoftmenu();
                                    }
                                    if (runtime.menu(0) == -runtime.MNU_ALPHA) {
                                        runtime.popSoftmenu();
                                    }
                                } else {
                                    runtime.itemToBeAssigned = runtime.ASSIGN_CLEAR;
                                    if (runtime.previousCalcMode == runtime.CM_AIM) {
                                        runtime.showSoftmenu(-runtime.MNU_MyAlpha);
                                    }
                                }
                            } else {
                                if (runtime.tam.alpha and runtime.tam.mode != runtime.TM_NEWMENU) {
                                    runtime.assignLeaveAlpha();
                                    runtime.assignGetName2();
                                } else if (runtime.tam.alpha) {
                                    runtime.tamBuffer[0] = 0;
                                }
                            }
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_REGISTER_BROWSER or runtime.calcMode == runtime.CM_FLAG_BROWSER or runtime.calcMode == runtime.CM_ASN_BROWSER or runtime.calcMode == runtime.CM_FONT_BROWSER) {
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_CONFIRMATION) {
                            runtime.temporaryInformation = runtime.TI_ARE_YOU_SURE;
                            runtime.keyActionProcessed = true;
                        } else if (runtime.tam.mode != 0) {
                            runtime.tamProcessInput(@intCast(runtime.ITM_ENTER));
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_NIM) {
                            runtime.addItemToBuffer(@bitCast(item));
                            runtime.keyActionProcessed = true;
                        }
                    },

                    runtime.CHR_caseUP => {
                        if (runtime.getSystemFlag(runtime.FLAG_NUMLOCK)) {} else if (runtime.alphaCase == runtime.AC_LOWER) {
                            processKeyAction(runtime.CHR_case);
                        } else if (runtime.alphaCase == runtime.AC_UPPER) {
                            processKeyAction(runtime.CHR_numL);
                        }
                        runtime.nextChar = runtime.NC_NORMAL;
                        runtime.keyActionProcessed = true;
                    },

                    runtime.CHR_caseDN => {
                        if (runtime.getSystemFlag(runtime.FLAG_NUMLOCK)) {
                            runtime.alphaCase = runtime.AC_UPPER;
                            processKeyAction(runtime.CHR_numU);
                        } else if (runtime.alphaCase == runtime.AC_UPPER) {
                            processKeyAction(runtime.CHR_case);
                        }
                        runtime.nextChar = runtime.NC_NORMAL;
                        runtime.keyActionProcessed = true;
                    },

                    runtime.CHR_numL => {
                        if (!runtime.getSystemFlag(runtime.FLAG_NUMLOCK)) {
                            processKeyAction(runtime.CHR_num);
                        }
                        runtime.keyActionProcessed = true;
                    },

                    runtime.CHR_numU => {
                        if (runtime.getSystemFlag(runtime.FLAG_NUMLOCK)) {
                            processKeyAction(runtime.CHR_num);
                        }
                        runtime.keyActionProcessed = true;
                    },

                    runtime.CHR_num => {
                        runtime.alphaCase = runtime.AC_UPPER;
                        runtime.fnFlipFlag(@intCast(runtime.FLAG_NUMLOCK));
                        if (!runtime.getSystemFlag(runtime.FLAG_NUMLOCK)) {
                            runtime.nextChar = runtime.NC_NORMAL;
                        }
                        runtime.showAlphaModeonGui();
                        runtime.keyActionProcessed = true;
                    },

                    runtime.CHR_case => {
                        runtime.clearSystemFlag(@intCast(runtime.FLAG_NUMLOCK));
                        const sm = runtime.currentMenu();
                        runtime.nextChar = runtime.NC_NORMAL;
                        if (runtime.alphaCase == runtime.AC_LOWER) {
                            runtime.alphaCase = runtime.AC_UPPER;
                            if (sm == -runtime.MNU_alpha_omega or sm == -runtime.MNU_ALPHAintl) {
                                runtime.softmenuStack[0].softmenuId -= 1;
                            }
                        } else {
                            runtime.alphaCase = runtime.AC_LOWER;
                            if (sm == -runtime.MNU_ALPHA_OMEGA or sm == -runtime.MNU_ALPHAINTL) {
                                runtime.softmenuStack[0].softmenuId += 1;
                            }
                        }
                        runtime.showAlphaModeonGui();
                        runtime.keyActionProcessed = true;
                    },

                    else => {
                        if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned != 0 and item == runtime.ITM_USERMODE) {
                            while (runtime.softmenuStack[0].softmenuId > 1) {
                                runtime.popSoftmenu();
                            }
                            if (runtime.previousCalcMode == runtime.CM_AIM) {
                                runtime.softmenuStack[0].softmenuId = 1;
                                runtime.calcModeAimGui();
                            } else {
                                runtime.leaveAsmMode();
                            }
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_ASSIGN and runtime.itemToBeAssigned == 0 and item == runtime.ITM_USERMODE) {
                            runtime.tamEnterMode(runtime.ITM_USERMODE);
                            runtime.calcMode = runtime.previousCalcMode;
                            runtime.keyActionProcessed = true;
                        } else if (runtime.calcMode == runtime.CM_ASSIGN and item == runtime.ITM_AIM) {
                            runtime.assignEnterAlpha();
                            runtime.keyActionProcessed = true;
                        } else if ((runtime.calcMode != runtime.CM_PEM or !runtime.getSystemFlag(runtime.FLAG_ALPHA)) and runtime.catalog != 0 and runtime.catalog != runtime.CATALOG_MVAR) {
                            if (runtime.ITM_A <= item and item <= runtime.ITM_Z and runtime.lowercaseSelected()) {
                                runtime.addItemToBuffer(@bitCast(item + (runtime.ITM_a - runtime.ITM_A)));
                                runtime.keyActionProcessed = true;
                            } else if (item == runtime.ITM_DOWN_ARROW or item == runtime.ITM_UP_ARROW) {
                                runtime.addItemToBuffer(@bitCast(item));
                                runtime.keyActionProcessed = true;
                            }
                        } else if (runtime.tam.mode != 0) {
                            if (runtime.tam.alpha) {
                                // C reads indexOfItems[item] before `|| item < 0`; the
                                // reorder keeps the boolean result while avoiding the
                                // out-of-range index for negative menu items.
                                if (item < 0 or runtime.itemFuncIsAddItemToBuffer(item)) {
                                    processAimInput(item);
                                } else {
                                    runtime.keyActionProcessed = true;
                                }
                            } else {
                                if (comptime runtime.is_dmcp_build) {
                                    runtime.wait_for_key_release(0);
                                    _ = runtime.key_pop();
                                }
                                runtime.addItemToBuffer(@bitCast(item));
                                if (comptime runtime.is_dmcp_build) {
                                    _ = runtime.key_push(0);
                                }
                                runtime.keyActionProcessed = true;
                            }
                        } else if (item == runtime.ITM_SNAP) {
                            runtime.runFunction(item);
                            runtime.keyActionProcessed = true;
                        } else {
                            switch (runtime.calcMode) {
                                runtime.CM_NORMAL => {
                                    if (runtime.showMode()) {
                                        if (item == runtime.ITM_RCL) {
                                            runtime.keyActionProcessed = true;
                                            runtime.fnRecall(runtime.showRegis);
                                            runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                                            runtime.temporaryInformation = runtime.TI_COPY_FROM_SHOW;
                                            runtime.closeShowMenu();
                                        } else if (ITM_0 <= item and item <= ITM_9 and runtime.allowShowDigits) {
                                            runtime.keyActionProcessed = true;
                                            if (runtime.showRegis % 10 == 0 and runtime.showRegis <= 90) {
                                                runtime.showRegis += @intCast(item - ITM_0);
                                            } else {
                                                runtime.showRegis = @intCast((item - ITM_0) * 10);
                                            }
                                            runtime.fnC47Show(runtime.ITM_NOP);
                                        }
                                    } else if (item == runtime.ITM_EXPONENT or item == runtime.ITM_PERIOD or (ITM_0 <= item and item <= ITM_9)) {
                                        runtime.addItemToNimBuffer(item);
                                        runtime.refreshRegisterLine(runtime.REGISTER_X);
                                        runtime.keyActionProcessed = true;
                                    } else if (item == runtime.ITM_UNDO or item == runtime.ITM_BST or item == runtime.ITM_SST or item == runtime.ITM_PR or item == runtime.ITM_AIM or item == runtime.ITM_SNAP) {
                                        runtime.runFunction(item);
                                        runtime.keyActionProcessed = true;
                                    } else if (item == runtime.ITM_RS) {
                                        runtime.showStep();
                                        runtime.keyActionProcessed = true;
                                        runtime.showFunctionNameItem = 0;
                                        if (comptime runtime.is_dmcp_build) {
                                            runtime.lcd_refresh();
                                        } else {
                                            _ = runtime.refreshLcd(null);
                                        }
                                    }
                                },

                                runtime.CM_AIM => {
                                    if (item == runtime.ITM_BST or item == runtime.ITM_SST) {
                                        runtime.closeAim();
                                        runtime.runFunction(item);
                                        runtime.keyActionProcessed = true;
                                    } else {
                                        runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_SKIP_STACK_ONE_TIME);
                                        processAimInput(item);
                                        runtime.refreshRegisterLine(runtime.AIM_REGISTER_LINE);
                                    }
                                },

                                runtime.CM_EIM => {
                                    processAimInput(item);
                                    runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_SKIP_MENU_ONE_TIME);
                                    runtime.refreshScreen(130);
                                },

                                runtime.CM_NIM => {
                                    if (item == runtime.ITM_BST or item == runtime.ITM_SST) {
                                        runtime.closeNim();
                                        runtime.runFunction(item);
                                        runtime.keyActionProcessed = true;
                                    } else {
                                        runtime.keyActionProcessed = true;
                                        if (item == runtime.ITM_toINT or item == runtime.ITM_HASH_JM) {
                                            runtime.resetShiftState();
                                        }

                                        if (runtime.calcMode == runtime.CM_NIM and (item == runtime.ITM_RI or item == runtime.ITM_dotD) and (runtime.nimNumberPart == runtime.NP_INT_10 or runtime.nimNumberPart == runtime.NP_INT_16) and runtime.lastIntegerBase > 0) {
                                            runtime.lastIntegerBase = 0;
                                            runtime.nimNumberPart = if (runtime.hexDigits == 0) runtime.NP_INT_10 else runtime.NP_INT_16;
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
                                            runtime.resetShiftState();
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_SKIP_STACK_ONE_TIME;
                                            runtime.keyActionProcessed = true;
                                        } else if (runtime.calcMode == runtime.CM_NIM and (item == runtime.ITM_RI or item == runtime.ITM_dotD) and runtime.nimNumberPart == runtime.NP_INT_BASE and runtime.aimBuffer[runtime.strlen(runtime.aimBuffer) - 1] == '#') {
                                            runtime.lastIntegerBase = 0;
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
                                            runtime.resetShiftState();
                                            runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE);
                                            runtime.keyActionProcessed = true;
                                        } else if (runtime.calcMode == runtime.CM_NIM and item == runtime.ITM_HASH_JM and runtime.nimNumberPart == runtime.NP_INT_BASE and runtime.aimBuffer[runtime.strlen(runtime.aimBuffer) - 1] == '#') {
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
                                            runtime.resetShiftState();
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STACK;
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_SKIP_STACK_ONE_TIME;
                                            runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE);
                                            runtime.keyActionProcessed = true;
                                        } else if (runtime.calcMode == runtime.CM_NIM and item == runtime.ITM_PERIOD and runtime.nimNumberPart == runtime.NP_INT_BASE and runtime.aimBuffer[runtime.strlen(runtime.aimBuffer) - 1] == '#') {
                                            runtime.lastIntegerBase = 0;
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
                                            runtime.resetShiftState();
                                            runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE);
                                            runtime.addItemToNimBuffer(runtime.ITM_PERIOD);
                                            runtime.refreshRegisterLine(runtime.REGISTER_X);
                                            runtime.keyActionProcessed = true;
                                        } else if (runtime.calcMode == runtime.CM_NIM and item == runtime.ITM_HASH_JM and runtime.nimNumberPart == runtime.NP_REAL_FLOAT_PART and runtime.aimBuffer[runtime.strlen(runtime.aimBuffer) - 1] == '.') {
                                            runtime.lastIntegerBase = 0;
                                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
                                            runtime.resetShiftState();
                                            runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE);
                                            runtime.addItemToNimBuffer(runtime.ITM_toINT);
                                            runtime.refreshRegisterLine(runtime.REGISTER_X);
                                            runtime.keyActionProcessed = true;
                                        } else {
                                            runtime.addItemToNimBuffer(item);
                                        }

                                        if (((ITM_0 <= item and item <= ITM_9) or item == runtime.ITM_toINT or item == runtime.ITM_HASH_JM or item == runtime.ITM_ms or ((runtime.ITM_A <= item and item <= runtime.ITM_F) and (runtime.lastIntegerBase >= 2) and runtime.getSystemFlag(runtime.FLAG_TOPHEX))) or item == runtime.ITM_CHS or item == runtime.ITM_EXPONENT or item == runtime.ITM_PERIOD) {
                                            runtime.refreshRegisterLine(runtime.REGISTER_X);
                                        }
                                    }
                                },

                                runtime.CM_MIM => {
                                    runtime.addItemToBuffer(@bitCast(item));
                                    runtime.keyActionProcessed = true;
                                },

                                runtime.CM_REGISTER_BROWSER => {
                                    if (item == runtime.ITM_PERIOD) {
                                        runtime.rbr1stDigit = true;
                                        if (runtime.rbrMode == runtime.RBR_GLOBAL) {
                                            if (runtime.currentNumberOfLocalRegisters() != 0) {
                                                runtime.rbrMode = runtime.RBR_LOCAL;
                                                runtime.currentRegisterBrowserScreen = @intCast(runtime.FIRST_LOCAL_REGISTER);
                                            } else {
                                                runtime.rbrMode = runtime.RBR_NAMED;
                                                runtime.currentRegisterBrowserScreen = @intCast(runtime.FIRST_NAMED_VARIABLE);
                                            }
                                        } else if (runtime.rbrMode == runtime.RBR_LOCAL) {
                                            runtime.rbrMode = runtime.RBR_NAMED;
                                            runtime.currentRegisterBrowserScreen = @intCast(runtime.FIRST_NAMED_VARIABLE);
                                        } else if (runtime.rbrMode == runtime.RBR_NAMED) {
                                            runtime.rbrMode = runtime.RBR_GLOBAL;
                                            runtime.currentRegisterBrowserScreen = runtime.REGISTER_X;
                                        }
                                    } else if (item == runtime.ITM_RS) {
                                        runtime.rbr1stDigit = true;
                                        runtime.showContent = !runtime.showContent;
                                    } else if (item == runtime.ITM_RCL) {
                                        runtime.rbr1stDigit = true;
                                        runtime.calcMode = runtime.previousCalcMode;
                                        if (runtime.rbrMode == runtime.RBR_GLOBAL or runtime.rbrMode == runtime.RBR_LOCAL) {
                                            runtime.fnRecall(@bitCast(runtime.currentRegisterBrowserScreen));
                                            runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                                            runtime.refreshScreen(128);
                                        } else if (runtime.rbrMode == runtime.RBR_NAMED) {
                                            if (@as(i32, runtime.currentRegisterBrowserScreen) >= runtime.FIRST_NAMED_VARIABLE + @as(i32, runtime.numberOfNamedVariables)) {
                                                runtime.currentRegisterBrowserScreen = @intCast(@as(i32, runtime.currentRegisterBrowserScreen) - (runtime.FIRST_NAMED_VARIABLE + @as(i32, runtime.numberOfNamedVariables)));
                                                runtime.currentRegisterBrowserScreen = @intCast(@as(i32, runtime.currentRegisterBrowserScreen) + (runtime.FIRST_RESERVED_VARIABLE + runtime.NUMBER_OF_LETTERED_VARIABLES));
                                            }
                                            runtime.fnRecall(@bitCast(runtime.currentRegisterBrowserScreen));
                                        }
                                        runtime.setSystemFlag(runtime.FLAG_ASLIFT);
                                        runtime.temporaryInformation = runtime.TI_STORCL;
                                        runtime.lastParam = runtime.currentRegisterBrowserScreen;
                                    } else if (ITM_0 <= item and item <= ITM_9) {
                                        if (runtime.rbr1stDigit) {
                                            runtime.rbr1stDigit = false;
                                            runtime.rbrRegister = item - ITM_0;
                                        } else {
                                            runtime.rbr1stDigit = true;
                                            runtime.rbrRegister = @intCast(@as(i32, runtime.rbrRegister) * 10 + @as(i32, item) - @as(i32, ITM_0));

                                            switch (runtime.rbrMode) {
                                                runtime.RBR_GLOBAL => {
                                                    runtime.currentRegisterBrowserScreen = runtime.rbrRegister;
                                                },
                                                runtime.RBR_LOCAL => {
                                                    if (@as(i32, runtime.rbrRegister) >= @as(i32, runtime.currentNumberOfLocalRegisters())) {
                                                        runtime.rbrRegister = 0;
                                                    }
                                                    runtime.currentRegisterBrowserScreen = @intCast(runtime.FIRST_LOCAL_REGISTER + @as(i32, runtime.rbrRegister));
                                                },
                                                runtime.RBR_NAMED => {
                                                    runtime.rbrMode = runtime.RBR_GLOBAL;
                                                    runtime.currentRegisterBrowserScreen = runtime.rbrRegister;
                                                },
                                                else => {},
                                            }
                                        }
                                    } else if (runtime.ITM_X <= item and item <= runtime.ITM_Z) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = item - runtime.ITM_X + runtime.REGISTER_X;
                                    } else if (item == runtime.ITM_T) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = runtime.REGISTER_T;
                                    } else if (runtime.ITM_A <= item and item <= runtime.ITM_D) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = item - runtime.ITM_A + runtime.REGISTER_A;
                                    } else if (item == runtime.ITM_L) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = runtime.REGISTER_L;
                                    } else if (runtime.ITM_I <= item and item <= runtime.ITM_K) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = item - runtime.ITM_I + runtime.REGISTER_I;
                                    } else if (item == runtime.ITM_M) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = runtime.REGISTER_M;
                                    } else if (item == runtime.ITM_N) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = runtime.REGISTER_N;
                                    } else if (runtime.ITM_P <= item and item <= runtime.ITM_S) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = item - runtime.ITM_P + runtime.REGISTER_P;
                                    } else if (runtime.ITM_E <= item and item <= runtime.ITM_H) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = item - runtime.ITM_E + runtime.REGISTER_E;
                                    } else if (item == runtime.ITM_O) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = runtime.REGISTER_O;
                                    } else if (runtime.ITM_U <= item and item <= runtime.ITM_W) {
                                        runtime.rbrMode = runtime.RBR_GLOBAL;
                                        runtime.rbr1stDigit = true;
                                        runtime.currentRegisterBrowserScreen = item - runtime.ITM_U + runtime.REGISTER_U;
                                    }

                                    runtime.keyActionProcessed = true;
                                },

                                runtime.CM_ASN_BROWSER => {
                                    runtime.lastItem = 0;
                                    runtime.lastUserMode = false;
                                    if (item == runtime.ITM_PERIOD) {
                                        runtime.fnAsnDisplayUSER = false;
                                        runtime.keyActionProcessed = true;
                                        runtime.lastItem = item;
                                        runtime.refreshScreen(121);
                                    } else if (item == runtime.ITM_USERMODE) {
                                        runtime.runFunction(item);
                                        runtime.keyActionProcessed = true;
                                    }
                                },

                                runtime.CM_FLAG_BROWSER, runtime.CM_FONT_BROWSER, runtime.CM_ERROR_MESSAGE, runtime.CM_BUG_ON_SCREEN => {
                                    runtime.keyActionProcessed = true;
                                },

                                runtime.CM_GRAPH, runtime.CM_PLOT_STAT, runtime.CM_LISTXY => {},

                                runtime.CM_CONFIRMATION => {
                                    runtime.temporaryInformation = runtime.TI_ARE_YOU_SURE;
                                    runtime.keyActionProcessed = true;
                                },

                                runtime.CM_PEM => {
                                    if (item == runtime.ITM_PR) {
                                        leavePem();
                                        runtime.calcModeNormal();
                                        runtime.extractPFNMenus();
                                        runtime.keyActionProcessed = true;
                                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                                    } else if (item == runtime.ITM_OFF) {
                                        runtime.fnOff(runtime.NOPARAM);
                                        runtime.keyActionProcessed = true;
                                    } else if (item == runtime.ITM_SST) {
                                        runtime.fnSst(runtime.NOPARAM);
                                        runtime.keyActionProcessed = true;
                                        runtime.refreshScreen(122);
                                    } else if (item == runtime.ITM_BST) {
                                        runtime.fnBst(runtime.NOPARAM);
                                        runtime.keyActionProcessed = true;
                                        runtime.refreshScreen(123);
                                    } else if (runtime.aimBuffer[0] != 0 and !runtime.getSystemFlag(runtime.FLAG_ALPHA) and (item == runtime.ITM_HASH_JM or item == runtime.ITM_toINT or (runtime.nimNumberPart == runtime.NP_INT_BASE and item == runtime.ITM_RCL))) {
                                        if (item == runtime.ITM_HASH_JM) {
                                            item = runtime.ITM_toINT;
                                        }
                                        runtime.pemAddNumber(item, true);
                                        runtime.keyActionProcessed = true;
                                        if (item == runtime.ITM_RCL) {
                                            runtime.currentStep = runtime.findPreviousStep(runtime.currentStep);
                                            runtime.currentLocalStepNumber -= 1;
                                            if (!runtime.programListEnd) {
                                                runtime.scrollPemBackwards();
                                            }
                                        }
                                    } else if (item == runtime.ITM_RS) {
                                        runtime.addStepInProgram(runtime.ITM_STOP);
                                        runtime.keyActionProcessed = true;
                                    } else if (item == runtime.ITM_dotD and runtime.aimBuffer[0] == 0) {
                                        runtime.addStepInProgram(runtime.ITM_toREAL);
                                        runtime.keyActionProcessed = true;
                                    }
                                },

                                runtime.CM_ASSIGN => {
                                    if (item > 0 and runtime.itemToBeAssigned == 0) {
                                        if (runtime.tam.alpha) {
                                            processAimInput(item);
                                            if (runtime.stringGlyphLength(runtime.aimBuffer) > 6) {
                                                runtime.assignLeaveAlpha();
                                                runtime.assignGetName1();
                                            }
                                        } else {
                                            if (item == runtime.ITM_XEQ and runtime.tmpString[0] != 0 and (runtime.getSystemFlag(runtime.FLAG_USER) or ((@as(i16, runtime.currentKeyCode) == runtime.normKey00Key()) and (runtime.keyStateCode == 0) and runtime.Norm_Key_00.used))) {
                                                var label: [15]u8 = undefined;
                                                _ = runtime.xcopy(&label, runtime.tmpString, @intCast(runtime.stringByteLength(runtime.tmpString) + 1));
                                                const regist = runtime.findNamedLabel(&label, runtime.GLOBAL_LABELS);
                                                if (regist != INVALID_VARIABLE) {
                                                    item = @intCast(@as(i32, regist) - runtime.FIRST_LABEL + runtime.ASSIGN_LABELS);
                                                } else {
                                                    runtime.displayCalcErrorMessage(runtime.ERROR_LABEL_NOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                                                    if (comptime !runtime.is_dmcp_build) { // EXTRA_INFO_ON_CALC_ERROR
                                                        runtime.fmtCStr(runtime.errorMessage, "string '{s}' is not a named label", .{runtime.sliceTo(@as([*c]const u8, &label), 0)});
                                                        runtime.moreInfoOnError("In function processKeyAction:", runtime.errorMessage, null, null);
                                                    }
                                                }
                                            } else if (item == runtime.ITM_RCL and runtime.tmpString[0] != 0 and (runtime.getSystemFlag(runtime.FLAG_USER) or ((@as(i16, runtime.currentKeyCode) == runtime.normKey00Key()) and (runtime.keyStateCode == 0) and runtime.Norm_Key_00.used))) {
                                                var varName: [15]u8 = undefined;
                                                _ = runtime.xcopy(&varName, runtime.tmpString, @intCast(runtime.stringByteLength(runtime.tmpString) + 1));
                                                const regist = runtime.findNamedVariable(&varName);
                                                if (regist != INVALID_VARIABLE) {
                                                    item = @intCast(@as(i32, regist) - runtime.FIRST_NAMED_VARIABLE + runtime.ASSIGN_NAMED_VARIABLES);
                                                } else {
                                                    runtime.displayCalcErrorMessage(runtime.ERROR_LABEL_NOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                                                    if (comptime !runtime.is_dmcp_build) { // EXTRA_INFO_ON_CALC_ERROR
                                                        runtime.fmtCStr(runtime.errorMessage, "string '{s}' is not a named variable", .{runtime.sliceTo(@as([*c]const u8, &varName), 0)});
                                                        runtime.moreInfoOnError("In function processKeyAction:", runtime.errorMessage, null, null);
                                                    }
                                                }
                                            }

                                            runtime.itemToBeAssigned = @bitCast(numlockReplacements(item, runtime.getSystemFlag(runtime.FLAG_NUMLOCK), false, false));
                                            if (runtime.ITM_A <= runtime.itemToBeAssigned and runtime.itemToBeAssigned <= runtime.ITM_Z and runtime.lowercaseSelected()) {
                                                runtime.itemToBeAssigned += (runtime.ITM_a - runtime.ITM_A);
                                            }

                                            if (runtime.previousCalcMode == runtime.CM_AIM) {
                                                runtime.softmenuStack[0].softmenuId = 1;
                                            }
                                        }
                                        runtime.keyActionProcessed = true;
                                    } else if (item != 0 and runtime.itemToBeAssigned != 0) {
                                        if (runtime.tam.alpha and runtime.tam.mode != runtime.TM_NEWMENU) {
                                            if (item > 0) {
                                                processAimInput(item);
                                                if (runtime.stringGlyphLength(runtime.aimBuffer) > 6) {
                                                    runtime.assignLeaveAlpha();
                                                    runtime.assignGetName2();
                                                }
                                                runtime.keyActionProcessed = true;
                                            }
                                        } else {
                                            switch (item) {
                                                runtime.ITM_ENTER, runtime.ITM_SHIFTf, runtime.ITM_SHIFTg, runtime.ITM_USERMODE, runtime.ITM_EXIT1, runtime.KEY_fg, runtime.ITM_BACKSPACE => {},
                                                else => {
                                                    // HOME_AND_PFN_KEYS is undefined on this lane,
                                                    // so only the unconditional else body remains.
                                                    runtime.tamBuffer[0] = 0;
                                                    runtime.keyActionProcessed = true;
                                                },
                                            }
                                        }
                                    }
                                },

                                runtime.CM_TIMER => {
                                    if (item == runtime.ITM_TIMER_R_S or item == runtime.ITM_RS) {
                                        runtime.fnStartStopTimerApp(runtime.NOPARAM);
                                    } else if (item >= ITM_0 and item <= ITM_9) {
                                        runtime.fnDigitKeyTimerApp(@bitCast(item - ITM_0));
                                    } else if (item == runtime.ITM_PERIOD) {
                                        runtime.fnRegAddLapTimerApp(runtime.NOPARAM);
                                    } else if (item == runtime.ITM_SIGMAPLUS) {
                                        runtime.fnAddTimerApp(runtime.NOPARAM);
                                    } else if (item == runtime.ITM_ADD) {
                                        runtime.fnAddLapTimerApp(runtime.NOPARAM);
                                    } else if (item == runtime.ITM_RCL) {
                                        runtime.runFunction(runtime.ITM_TIMER_RCL);
                                    }
                                    runtime.keyActionProcessed = true;
                                },

                                else => {
                                    runtime.fmtCStr(runtime.errorMessage, "In function processKeyAction: {d} is an unexpected value while processing calcMode!", .{@as(u32, runtime.calcMode)});
                                    runtime.displayBugScreen(runtime.errorMessage);
                                },
                            }
                        }
                    },
                }
            }
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
            _ = unused_but_mandatory_parameter;

            if (runtime.tam.mode == runtime.TM_KEY and !runtime.tam.keyInputFinished) {
                if (runtime.tam.digitsSoFar == 0) {
                    runtime.tamProcessInput(runtime.ITM_2);
                    runtime.tamProcessInput(runtime.ITM_1);
                    runtime.shiftF = false;
                    runtime.shiftG = false;
                    runtime.refreshScreen(124);
                }
                return;
            }
            if (runtime.lastErrorCode == 0 and runtime.currentMenu() == -runtime.MNU_MVAR) {
                runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_INTERACTIVE;
            }

            runtime.doRefreshSoftMenu = true;
            runtime.jm_show_calc_state("fnKeyExit");

            if (runtime.getSystemFlag(runtime.FLAG_INTING) or runtime.getSystemFlag(runtime.FLAG_SOLVING)) {
                runtime.displayCalcErrorMessage(runtime.ERROR_SOLVER_ABORT, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                return; // Done elsewhere
            }

            // First pass: close any open catalog (skipped for browser/message modes).
            switch (runtime.calcMode) {
                runtime.CM_REGISTER_BROWSER,
                runtime.CM_FLAG_BROWSER,
                runtime.CM_ASN_BROWSER,
                runtime.CM_FONT_BROWSER,
                runtime.CM_CONFIRMATION,
                runtime.CM_ERROR_MESSAGE,
                runtime.CM_BUG_ON_SCREEN,
                => {},
                else => {
                    if (runtime.catalog != 0 and (runtime.catalog != runtime.CATALOG_MVAR or runtime.tam.mode == 0)) {
                        if (runtime.lastErrorCode != 0) {
                            runtime.lastErrorCode = 0;
                        } else {
                            if (runtime.currentMenu() == -runtime.MNU_SYSFL) { // auto recover out of SYSFL
                                runtime.numberOfTamMenusToPop = 2;
                                runtime.leaveTamModeIfEnabled();
                                return;
                            }
                            runtime.leaveAsmMode();
                            runtime.popSoftmenu();
                            if (runtime.tam.mode != 0) {
                                runtime.numberOfTamMenusToPop -= 1;
                            }
                        }
                        return;
                    }
                },
            }

            if (runtime.tam.mode != 0) { // if in TAM mode
                if (runtime.numberOfTamMenusToPop > 1 and runtime.currentMenu() != -runtime.MNU_TAMALPHA) {
                    if (runtime.tam.colon and runtime.catalog == 0) {
                        runtime.tam.colon = false;
                        runtime.tamProcessInput(runtime.ITM_NOP); // to update the tam buffer
                    }
                    runtime.popSoftmenu();
                    runtime.numberOfTamMenusToPop -= 1;
                } else {
                    if (runtime.calcMode == runtime.CM_PEM) {
                        runtime.aimBuffer[0] = 0;
                    }
                    runtime.leaveTamModeIfEnabled();
                    if (runtime.calcMode == runtime.CM_PEM) {
                        runtime.scrollPemBackwards();
                    }
                }
                return;
            }

            // Second pass: NORMAL-mode custom menu exit.
            switch (runtime.calcMode) {
                runtime.CM_REGISTER_BROWSER,
                runtime.CM_FLAG_BROWSER,
                runtime.CM_ASN_BROWSER,
                runtime.CM_FONT_BROWSER,
                runtime.CM_CONFIRMATION,
                runtime.CM_ERROR_MESSAGE,
                runtime.CM_BUG_ON_SCREEN,
                => {},
                runtime.CM_NORMAL => {
                    if (runtime.currentMenu() == -runtime.ITM_MENU) {
                        runtime.dynamicMenuItem = 20;
                        runtime.fnProgrammableMenu(runtime.NOPARAM);
                        return;
                    }
                },
                else => {},
            }

            // Main pass: per-calcMode exit behaviour.
            var undo_disabled = false;
            switch (runtime.calcMode) {
                runtime.CM_NORMAL => {
                    if (runtime.temporaryInformation == runtime.TI_VIEW_REGISTER) {
                        runtime.temporaryInformation = runtime.TI_NO_INFO;
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                    } else if (runtime.temporaryInformation == runtime.TI_SHOW_REGISTER or runtime.isShowMode()) {
                        runtime.temporaryInformation = runtime.TI_NO_INFO;
                        runtime.closeShowMenu();
                    } else if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                    } else {
                        if (runtime.currentMenu() == -runtime.MNU_GRAPHS and runtime.menu(1) == -runtime.MNU_PLOT_FUNC) {
                            runtime.calcMode = runtime.CM_GRAPH;
                            runtime.fnEqSolvGraph(runtime.EQ_PLOT_LU);
                            runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        } else if (runtime.softmenuStack[0].softmenuId <= 1) { // MyMenu/MyAlpha shown
                            runtime.currentInputVariable = runtime.INVALID_VARIABLE;
                            if (runtime.getSystemFlag(runtime.FLAG_BASE_HOME)) {
                                runtime.showSoftmenu(-runtime.MNU_HOME);
                            } else if (runtime.getSystemFlag(runtime.FLAG_BASE_MYM)) {
                                runtime.BASE_OVERRIDEONCE = true;
                                runtime.showSoftmenu(-runtime.MNU_MyMenu);
                            }
                        } else { // 43S cleared an error here
                            runtime.popSoftmenu();
                            if (runtime.currentMenu() == -runtime.MNU_MVAR and
                                (runtime.currentSolverStatus & runtime.SOLVER_STATUS_EQUATION_MODE) == runtime.SOLVER_STATUS_EQUATION_INTEGRATE and
                                (runtime.currentSolverStatus & runtime.SOLVER_STATUS_SINGLE_VARIABLE) != 0)
                            {
                                runtime.popSoftmenu();
                                runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_EQUATION_MODE;
                                runtime.currentSolverStatus &= ~runtime.SOLVER_STATUS_INTERACTIVE;
                            }
                            runtime.stayInAIM();
                        }
                        runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;

                        if (runtime.getRegisterDataType(runtime.REGISTER_X) == runtime.dtShortInteger) {
                            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_MENU;
                        } else if (runtime.temporaryInformation == runtime.TI_NO_INFO) {
                            runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STACK_ONE_TIME;
                        }
                    }
                },

                runtime.CM_AIM => {
                    if (runtime.currentMenu() == -runtime.MNU_ALPHA) { // leave ALPHA menu, go to MyM
                        runtime.softmenuStack[0].softmenuId = 1;
                    }

                    if (runtime.softmenuStack[0].softmenuId <= 1 and runtime.menu(1) != -runtime.MNU_ALPHA) {
                        runtime.closeAim();
                        runtime.updateMatrixHeightCache();
                        runtime.saveForUndo();
                        if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                            undo_disabled = true;
                        }
                    } else {
                        runtime.popSoftmenu();
                        runtime.stayInAIM();
                    }
                },

                runtime.CM_NIM => {
                    runtime.addItemToNimBuffer(runtime.ITM_EXIT1);
                    runtime.updateMatrixHeightCache();
                },

                runtime.CM_MIM => {
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                    } else if (runtime.temporaryInformation == runtime.TI_SHOW_REGISTER) {
                        runtime.temporaryInformation = runtime.TI_NO_INFO;
                    } else {
                        if (runtime.currentMenu() == -runtime.MNU_M_EDIT) {
                            runtime.mimEnter(true);
                            if (@as(i32, runtime.matrixIndex) == @as(i32, runtime.findNamedVariable(&runtime.statMx[0]))) {
                                runtime.calcSigma(0);
                            }
                            runtime.mimFinalize();
                            runtime.calcModeNormal();
                            runtime.updateMatrixHeightCache();
                        }
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.screenUpdatingMode |= runtime.SCRUPD_SKIP_STATUSBAR_ONE_TIME;
                        runtime.popSoftmenu(); // close softmenu dedicated for the MIM
                    }
                },

                runtime.CM_PEM => pem: {
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                        break :pem;
                    }
                    if (runtime.getSystemFlag(runtime.FLAG_ALPHA) and runtime.tam.mode == 0) {
                        if (runtime.isAlphaSubmenu(0)) {
                            runtime.popSoftmenu(); // Alpha sub-menu: just pop it
                            break :pem;
                        }
                    }
                    if (runtime.getSystemFlag(runtime.FLAG_ALPHA) and runtime.aimBuffer[0] == 0 and runtime.tam.mode == 0) {
                        runtime.pemAlpha(runtime.ITM_BACKSPACE);
                        runtime.fnBst(runtime.NOPARAM); // restore PGM pointer
                        break :pem;
                    }
                    if (runtime.aimBuffer[0] != 0 and runtime.tam.mode == 0) {
                        if (runtime.getSystemFlag(runtime.FLAG_ALPHA)) {
                            runtime.pemCloseAlphaInput();
                        } else if (runtime.nimNumberPart == runtime.NP_INT_BASE) {
                            break :pem;
                        } else {
                            runtime.pemCloseNumberInput();
                        }
                        runtime.aimBuffer[0] = 0;
                        runtime.fnBst(runtime.NOPARAM); // restore PGM pointer
                        break :pem;
                    }
                    if (runtime.softmenuStack[0].softmenuId > 1 and runtime.currentMenu() != -runtime.MNU_PFN) {
                        runtime.popSoftmenu();
                        break :pem;
                    } else if (runtime.currentMenu() == -runtime.MNU_PFN) {
                        runtime.extractPFNMenus(); // exit menus immediately when coming out of PEM
                    }

                    runtime.aimBuffer[0] = 0;
                    leavePem();
                    runtime.calcModeNormal();
                    runtime.saveForUndo();
                    if (runtime.lastErrorCode == runtime.ERROR_RAM_FULL) {
                        undo_disabled = true;
                    }
                },

                runtime.CM_EIM => {
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                    } else {
                        if (runtime.currentMenu() == -runtime.MNU_EQ_EDIT) {
                            if (runtime.allFormulae[@intCast(runtime.currentFormula)].pointerToFormulaData != runtime.C47_NULL) {
                                runtime.parseEquation(runtime.currentFormula, runtime.EQUATION_PARSER_MVAR, runtime.aimBuffer, runtime.tmpString);
                                if (runtime.lastErrorCode != 0) {
                                    runtime.deleteEquation(runtime.currentFormula);
                                    runtime.lastErrorCode = 0;
                                }
                            } else {
                                runtime.deleteEquation(runtime.currentFormula);
                            }
                            runtime.calcModeNormal();
                        }
                        runtime.popSoftmenu();
                    }
                },

                runtime.CM_REGISTER_BROWSER, runtime.CM_FLAG_BROWSER, runtime.CM_FONT_BROWSER => {
                    runtime.rbr1stDigit = true;
                    runtime.calcMode = runtime.previousCalcMode;
                    if (runtime.calcMode == runtime.CM_TIMER) {
                        runtime.previousCalcMode = runtime.CM_NORMAL;
                    }
                },

                runtime.CM_ASN_BROWSER => {
                    if (runtime.previousCalcMode == runtime.CM_AIM or runtime.tam.alpha) {
                        if (runtime.currentMenu() == -runtime.MNU_AIMCATALOG) {
                            runtime.popSoftmenu();
                        }
                        runtime.showSoftmenu(-runtime.MNU_ALPHA);
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                    } else {
                        if (runtime.previousCalcMode == runtime.CM_EIM) {
                            if (runtime.currentMenu() == -runtime.MNU_EIMCATALOG) {
                                runtime.popSoftmenu();
                            }
                            runtime.showSoftmenu(-runtime.MNU_EQ_EDIT);
                        }
                        runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                        runtime.calcMode = runtime.CM_NORMAL; // get the stack back, then switch back
                        runtime.refreshScreen(0);
                    }
                    runtime.calcMode = runtime.previousCalcMode;
                },

                runtime.CM_TIMER => {
                    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                    if (runtime.lastErrorCode != 0) {
                        runtime.lastErrorCode = 0;
                    } else {
                        runtime.fnLeaveTimerApp();
                    }
                },

                runtime.CM_BUG_ON_SCREEN => {
                    runtime.calcMode = runtime.previousCalcMode;
                },

                runtime.CM_LISTXY => {
                    runtime.calcMode = runtime.CM_GRAPH;
                    runtime.reDraw = true;
                    runtime.keyActionProcessed = true;
                    runtime.fnRefreshState();
                },

                runtime.CM_GRAPH, runtime.CM_PLOT_STAT => {
                    if (runtime.calcMode == runtime.CM_PLOT_STAT) {
                        for (0..3) |_| {
                            if (runtime.softmenuStack[0].softmenuId > 1 and !(-runtime.currentMenu() == runtime.MNU_HIST or
                                -runtime.currentMenu() == runtime.MNU_PLOTTING or
                                -runtime.currentMenu() == runtime.MNU_MODEL or
                                -runtime.currentMenu() == runtime.MNU_REGR))
                            {
                                runtime.popSoftmenu();
                            }
                        }
                    } else {
                        if (runtime.currentMenu() == -runtime.MNU_PLOT_FUNC and runtime.menu(1) == -runtime.MNU_GRAPHS) {
                            runtime.popSoftmenu();
                        }
                        runtime.popSoftmenu();
                    }

                    if (runtime.currentMenu() == -runtime.MNU_TIMERF) {
                        runtime.clearScreen();
                        runtime.fnItemTimerApp(runtime.NOPARAM);
                        return;
                    }

                    runtime.lastPlotMode = runtime.PLOT_NOTHING;
                    runtime.plotSelection = 0;

                    runtime.calcModeNormal();
                    runtime.SAVED_SIGMA_lastAddRem = runtime.SIGMA_NONE;
                    const sf0 = runtime.systemFlags0;
                    const sf1 = runtime.systemFlags1;
                    runtime.fnUndo(runtime.NOPARAM);
                    runtime.systemFlags0 = sf0;
                    runtime.systemFlags1 = sf1;
                    runtime.fnClDrawMx(1);
                    if (runtime.statMx[0] != 'S') {
                        runtime.printStatus(0, runtime.errorMessageAt(runtime.RESTORING_STATS), runtime.force_status);
                        runtime.restoreStats();
                    }
                    runtime.screenUpdatingMode = runtime.SCRUPD_AUTO;
                    runtime.forceSBupdate();
                },

                runtime.CM_CONFIRMATION => {
                    runtime.calcMode = runtime.previousCalcMode;
                    runtime.popSoftmenu(); // Pop MNU_YESNO
                    runtime.temporaryInformation = runtime.TI_NO_INFO;
                    if (runtime.programRunStop == runtime.PGM_WAITING) {
                        runtime.programRunStop = runtime.PGM_STOPPED;
                    }
                },

                runtime.CM_ASSIGN => {
                    if ((runtime.softmenuStack[0].softmenuId <= 1 and runtime.softmenuStack[1].softmenuId <= 1) or
                        (runtime.previousCalcMode == runtime.CM_EIM and runtime.currentMenu() == -runtime.MNU_EQ_EDIT))
                    {
                        runtime.calcMode = runtime.previousCalcMode;
                        if (runtime.tam.alpha) {
                            runtime.assignLeaveAlpha();
                        }
                    } else {
                        runtime.popSoftmenu();
                        if (runtime.previousCalcMode == runtime.CM_AIM) {
                            runtime.stayInAIM();
                        }
                    }
                },

                else => runtime.bugScreenWhileProcKey("fnKeyExit", "EXIT"),
            }

            if (undo_disabled) {
                runtime.temporaryInformation = runtime.TI_UNDO_DISABLED;
                return;
            }

            runtime.last_CM = runtime.calcMode; // sunsetting refresh-prioritisation method
            runtime.screenUpdatingMode &= ~runtime.SCRUPD_MANUAL_STATUSBAR;
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
                            runtime.fmtCStr(runtime.errorMessage, "You cannot use CC or COMPLEX to create a Polar complex number with {s}({s}) in X and {s}({s}) in Y!", .{ @as([*:0]const u8, dtnX), @as([*:0]const u8, runtime.getRegisterTagName(runtime.REGISTER_X, false)), @as([*:0]const u8, dtnY), @as([*:0]const u8, runtime.getRegisterTagName(runtime.REGISTER_Y, false)) });
                        } else if (!rectOk and !runtime.getSystemFlag(runtime.FLAG_POLAR)) {
                            runtime.fmtCStr(runtime.errorMessage, "You cannot use CC or COMPLEX to create a Rectangular complex number with {s}({s}) in X and {s}({s}) in Y!", .{ @as([*:0]const u8, dtnX), @as([*:0]const u8, runtime.getRegisterTagName(runtime.REGISTER_X, false)), @as([*:0]const u8, dtnY), @as([*:0]const u8, runtime.getRegisterTagName(runtime.REGISTER_Y, false)) });
                        } else {
                            runtime.fmtCStr(runtime.errorMessage, "You cannot use CC or COMPLEX with {s} in X and {s} in Y!", .{ @as([*:0]const u8, dtnX), @as([*:0]const u8, dtnY) });
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
                                _ = assignToMenu(&runtime.asnKey[0]);
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
                    // Default (!NOMATRIXCURSORS, see defines.h #define/#undef):
                    // arrows navigate the matrix. keyActionProcessed=false lets the
                    // ITM_UP1 handler add ITM_UP_ARROW (moves the cell cursor up).
                    if (runtime.currentSoftmenuScrolls() and runtime.catalog != 0) {
                        runtime.menuUp();
                    } else {
                        runtime.keyActionProcessed = false;
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
                            _ = assignToMenu(&runtime.asnKey[0]);
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
                    if (runtime.currentFntScr < @as(u16, runtime.numScreensNumericFont) + runtime.numScreensNumericFontBold + runtime.numScreensStandardFont + runtime.numScreensTinyFont) {
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
                    // NOMATRIXCURSORS is #define'd then immediately #undef'd in
                    // defines.h, so the default (!NOMATRIXCURSORS) branch is live:
                    // arrows navigate the matrix. Leaving keyActionProcessed=false
                    // lets the ITM_DOWN1 handler add ITM_DOWN_ARROW (moves the cell
                    // cursor down). The port previously copied the NOMATRIXCURSORS
                    // branch, so up/down keys did nothing in the matrix editor.
                    if (runtime.currentSoftmenuScrolls() and runtime.catalog != 0) {
                        runtime.menuDown();
                    } else {
                        runtime.keyActionProcessed = false;
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
                            _ = assignToMenu(&runtime.asnKey[0]);
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
