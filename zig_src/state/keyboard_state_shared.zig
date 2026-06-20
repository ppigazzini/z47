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
                                        runtime.leavePem();
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
                                                const regist = runtime.findNamedLabel(&label);
                                                if (regist != INVALID_VARIABLE) {
                                                    item = @intCast(@as(i32, regist) - runtime.FIRST_LABEL + runtime.ASSIGN_LABELS);
                                                } else {
                                                    runtime.displayCalcErrorMessage(runtime.ERROR_LABEL_NOT_FOUND, runtime.ERR_REGISTER_LINE, runtime.REGISTER_X);
                                                    if (comptime !runtime.is_dmcp_build) { // EXTRA_INFO_ON_CALC_ERROR
                                                        _ = runtime.sprintf(runtime.errorMessage, "string '%s' is not a named label", @as([*c]u8, &label));
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
                                                        _ = runtime.sprintf(runtime.errorMessage, "string '%s' is not a named variable", @as([*c]u8, &varName));
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
                                    _ = runtime.sprintf(runtime.errorMessage, "In function processKeyAction: %u is an unexpected value while processing calcMode!", @as(c_uint, runtime.calcMode));
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
                    runtime.leavePem();
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
