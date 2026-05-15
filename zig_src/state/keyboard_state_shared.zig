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
                    fnKeyUp(0);
                    runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_STACK);
                    runtime.refreshScreen(118);
                } else {
                    fnKeyDown(0);
                    runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_MENU | runtime.SCRUPD_MANUAL_STACK);
                    runtime.refreshScreen(119);
                }

                runtime.keyActionProcessed = true;
                return;
            }

            runtime.processKeyActionRetained(item);
        }

        pub fn fnKeyEnter(unused_but_mandatory_parameter: u16) void {
            runtime.fnKeyEnterRetained(unused_but_mandatory_parameter);
        }

        pub fn fnKeyExit(unused_but_mandatory_parameter: u16) void {
            runtime.fnKeyExitRetained(unused_but_mandatory_parameter);
        }

        pub fn fnKeyCC(complex_type: u16) void {
            if (runtime.calcMode == runtime.CM_NIM and complex_type != @as(u16, @intCast(runtime.KEY_COMPLEX))) {
                runtime.addItemToNimBuffer(runtime.ITM_CC);
                return;
            }

            switch (runtime.calcMode) {
                runtime.CM_REGISTER_BROWSER,
                runtime.CM_FLAG_BROWSER,
                runtime.CM_ASN_BROWSER,
                runtime.CM_FONT_BROWSER,
                runtime.CM_PLOT_STAT,
                runtime.CM_TIMER,
                runtime.CM_LISTXY,
                runtime.CM_GRAPH,
                => return,
                else => runtime.fnKeyCCRetained(complex_type),
            }
        }

        pub fn fnKeyBackspace(unused_but_mandatory_parameter: u16) void {
            if (runtime.tam.mode == 0 and runtime.calcMode == runtime.CM_NIM) {
                runtime.addItemToNimBuffer(runtime.ITM_BACKSPACE_ITEM);
                runtime.screenUpdatingMode &= ~(runtime.SCRUPD_MANUAL_STACK | runtime.SCRUPD_SKIP_STACK_ONE_TIME);
                return;
            }

            runtime.fnKeyBackspaceRetained(unused_but_mandatory_parameter);
        }

        pub fn fnKeyUp(unused_but_mandatory_parameter: u16) void {
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

            runtime.fnKeyUpRetained(unused_but_mandatory_parameter);
        }

        pub fn fnKeyDown(unused_but_mandatory_parameter: u16) void {
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

            runtime.fnKeyDownRetained(unused_but_mandatory_parameter);
        }

        pub fn fnKeyDotD(unused_but_mandatory_parameter: u16) void {
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
                else => runtime.fnKeyDotDRetained(unused_but_mandatory_parameter),
            }
        }
    };
}
