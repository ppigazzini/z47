const runtime = @import("frontier_runtime.zig");

const DSP_MAX: u16 = 19;
const FLAG_FRACT: c_uint = 0x8007;
const FLAG_PROPFR: c_uint = 0x8008;
const FLAG_TRACE: c_uint = 0x8013;
const FLAG_PRTACT: c_uint = 0xc020;
const FLAG_INTING: c_uint = 0xc025;
const FLAG_SOLVING: c_uint = 0xc026;
const FLAG_FRCYC: c_uint = 0x8041;
const FLAG_IRFRAC: c_uint = 0x8047;
const FLAG_IRFRQ: c_uint = 0xc048;
const FLAG_PRTEN: u16 = 0x8067;
const FLAG_NORM: u16 = 0x8068;

const SETTING_AMODE: c_int = 0x0080;
const SETTING_SINT_MODE: c_int = 0x0083;

const TI_VERSION: u8 = 10;
const TI_WHO: u8 = 11;
const TI_RESET: u8 = 8;

const CM_NORMAL: u8 = 0;
const CM_CONFIRMATION: u8 = 11;
const CM_NO_UNDO: u8 = 16;

const ERROR_NONE: u8 = 0;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const ERROR_MATRIX_MISMATCH: u8 = 21;
const ERROR_NO_SUMMATION_DATA: u8 = 28;
const ERROR_PRINTING_DISABLED: u8 = 63;

const CONFIRMED: u16 = 9877;
const NOT_CONFIRMED: u16 = 9878;
const NOPARAM: u16 = 9876;

const USER_KRESET: u16 = 24;
const ITM_RIBBON_C47: u16 = 2509;
const ITM_RIBBON_R47: u16 = 2511;

const FIRST_GLOBAL_REGISTER: u16 = 0;
const LAST_GLOBAL_REGISTER: u16 = 125;
const FIRST_NAMED_VARIABLE: u16 = 256;
const FIRST_LOCAL_REGISTER: u16 = 7000;

const REGISTER_X: i16 = 100;
const REGISTER_Y: i16 = 101;
const REGISTER_Z: i16 = 102;
const REGISTER_T: u16 = 103;
const REGISTER_D: u16 = 107;
const REGISTER_W: u16 = 125;

const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const NIM_REGISTER_LINE: i16 = REGISTER_X;

const FLAG_SSIZE8: c_int = 0x8018;

const PGM_STOPPED: u8 = 0;
const PGM_RUNNING: u8 = 1;
const PGM_WAITING: u8 = 2;
const PGM_SINGLE_STEP: u8 = 6;

const PRN_ALL: u16 = 0;
const PRN_STK: u16 = 1;
const PRN_REGS: u16 = 2;
const PRN_GLOBALr: u16 = 3;
const PRN_LOCALr: u16 = 4;
const PRN_NAMEDr: u16 = 5;
const PRN_Xr: u16 = 6;
const PRN_XYr: u16 = 7;
const PRN_TMP: u16 = 8;

const TEMP_REGISTER_1: u16 = 135;

const LINE_FULL: c_int = 0;
const LINE_LEFT: c_int = 1;
const LINE_RIGHT: c_int = 2;

const MNU_GAP_L: i16 = 2151;
const MNU_GAP_RX: i16 = 2152;
const MNU_GAP_R: i16 = 2153;

const PROFF: u16 = 0;
const PRON: u16 = 1;
const MAN: u16 = 0;
const NORM: u16 = 1;
const TRACE: u16 = 2;
const STRACE: u16 = 3;

const PRINT_BYTE: c_int = 0;
const PRINT_CHAR: c_int = 1;
const PRINT_TAB: c_int = 2;
const PRINT_ALPHA: c_int = 3;

const DF_DMX_MIN: i16 = 99;
const DF_HIDE_MIN: i16 = 12;

const DF_ALL: u8 = 0;
const DF_FIX: u8 = 1;
const DF_SCI: u8 = 2;
const DF_ENG: u8 = 3;
const DF_SF: u8 = 4;
const DF_UN: u8 = 5;

const dtLongInteger: u32 = 0;
const dtReal34: u32 = 1;
const dtComplex34: u32 = 2;
const dtTime: u32 = 3;
const dtDate: u32 = 4;
const dtString: u32 = 5;
const dtReal34Matrix: u32 = 6;
const dtComplex34Matrix: u32 = 7;
const dtShortInteger: u32 = 8;

extern var displayFormat: u8;
extern var displayFormatDigits: u8;
extern var timeDisplayFormatDigits: u8;
extern var DM_Cycling: u8;
extern var gapItemLeft: u16;
extern var gapItemRight: u16;
extern var gapItemRadix: u16;
extern var grpGroupingLeft: u8;
extern var grpGroupingGr1LeftOverflow: u8;
extern var grpGroupingGr1Left: u8;
extern var grpGroupingRight: u8;
extern var shortIntegerMode: u8;
extern var temporaryInformation: u8;
extern var roundingMode: u8;
extern var significantDigits: u8;
extern var dispBase: u8;
extern var fractionDigits: u8;
extern var currentAngularMode: c_int;
extern var exponentLimit: i16;
extern var exponentHideLimit: i16;
extern var calcMode: u8;
extern var previousCalcMode: u8;
extern var programRunStop: u8;
extern var lastErrorCode: u8;
extern var previousErrorCode: u8;
extern var currentKeyCode: u8;
extern var thereIsSomethingToUndo: bool;
extern var numberOfNamedVariables: u16;
extern var statisticalSumsPointer: ?*anyopaque;

const ConfirmedFunction = *const fn (u16) callconv(.c) void;
extern var confirmedFunction: ?ConfirmedFunction;

const PrinterState = extern struct {
    print_on: bool,
    trace_done: bool,
    print_blank_line: u8,
    print_mode: c_int,
    printer_model: c_int,
    delay: u16,
};

extern var printerState: PrinterState;

extern fn clearSystemFlag(sf: c_uint) void;
extern fn setSystemFlag(sf: c_uint) void;
extern fn getSystemFlag(sf: c_int) bool;
extern fn flipSystemFlag(sf: c_uint) void;
extern fn setSystemFlagChanged(sf: c_int) void;
extern fn fnSetFlag(flag: u16) void;
extern fn fnClearFlag(flag: u16) void;
extern fn fnRefreshState() void;
extern fn showSoftmenu(menu: i16) void;
extern fn setLineDelay(delay: u16) void;
extern fn print_lf() void;
extern fn printProgram(list: bool, lines: u16) void;
extern fn cmdPrint(arg: u16, op: c_int) void;
extern fn popSoftmenu() void;
extern fn setConfirmationMode(func: ConfirmedFunction) void;
extern fn fnClSigma(unused_but_mandatory_parameter: u16) void;
extern fn allocateLocalRegisters(number_of_registers_to_allocate: u16) void;
extern fn clearRegister(regist: i16) void;
extern fn fnExitAllMenus(unused_but_mandatory_parameter: u16) void;
extern fn fnDeleteUserMenus(confirmation: u16) void;
extern fn fnRESET_MyM(param: u16) void;
extern fn fnRESET_Mya() void;
extern fn createHOME() void;
extern fn createPFN() void;
extern fn initUserKeyArgument() void;
extern fn fnDeleteAllVariables(confirmation: u16) void;
extern fn fnClFAll(confirmation: u16) void;
extern fn z47_frontier_push_u32_to_x(value: u32) void;
extern fn z47_frontier_release_saved_statistical_sums() void;
extern fn z47_frontier_is_r47_fam() bool;

extern fn printReg(regist: u16, label: ?[*:0]const u8, eq: bool, where: c_int, pr_sigma: bool) void;
extern fn getRegParam(f: ?*bool, s: *u16, n: *u16, d: ?*u16) u8;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern fn z47_frontier_print_reg_range(first_register_no: u16, last_register_no: u16) bool;
extern fn z47_frontier_current_number_of_local_registers() u16;
extern fn z47_frontier_print_exit_pressed() bool;
extern fn z47_frontier_print_sigma_line(index: u16) void;
extern fn z47_frontier_print_alpha_register(register_no: u16) void;
extern fn getRegisterDataType(regist: i16) u32;
extern fn z47_frontier_x_real_matrix_rows() u16;
extern fn z47_frontier_x_real_matrix_cols() u16;
extern fn z47_frontier_x_complex_matrix_rows() u16;
extern fn z47_frontier_x_complex_matrix_cols() u16;
extern fn z47_frontier_x_real_matrix_element_to_temp1(index: u32) void;
extern fn z47_frontier_x_complex_matrix_element_to_temp1(index: u32) void;
extern fn create_filename(file_suffix: [*:0]const u8) void;
extern fn stackregister_csv_out(reg_b: i16, reg_e: i16, one_line: bool) void;
extern fn z47_frontier_print_set_printer_sbi(status: bool) void;
extern fn z47_frontier_print_get_unicode_value(regist: i16) u16;

fn clampDisplayDigits(display_format_n: u16) u8 {
    const clamped: u16 = if (display_format_n > DSP_MAX) DSP_MAX else display_format_n;
    return @as(u8, @intCast(clamped));
}

fn displayFormatReset(display_format_n: u16) void {
    displayFormatDigits = clampDisplayDigits(display_format_n);
    clearSystemFlag(FLAG_FRACT);
    DM_Cycling = 0;
}

fn isPrintableScalarType(dt: u32) bool {
    return switch (dt) {
        dtLongInteger, dtReal34, dtShortInteger, dtString, dtDate, dtTime => true,
        else => false,
    };
}

pub export fn fnSNAP(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnSNAP(unused_but_mandatory_parameter);
}

pub export fn fnDisplayFormatFix(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_FIX;
    fnRefreshState();
}

pub export fn fnDisplayFormatSci(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_SCI;
    fnRefreshState();
}

pub export fn fnDisplayFormatEng(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_ENG;
    fnRefreshState();
}

pub export fn fnDisplayFormatAll(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_ALL;
    fnRefreshState();
}

pub export fn fnDisplayFormatSigFig(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_SF;
    fnRefreshState();
}

pub export fn fnDisplayFormatUnit(display_format_n: u16) callconv(.c) void {
    displayFormatReset(display_format_n);
    displayFormat = DF_UN;
    fnRefreshState();
}

pub export fn fnDisplayFormatDsp(display_format_n: u16) callconv(.c) void {
    displayFormatDigits = clampDisplayDigits(display_format_n);
    clearSystemFlag(FLAG_FRACT);
    fnRefreshState();
}

pub export fn fnDisplayFormatTime(display_format_n: u16) callconv(.c) void {
    timeDisplayFormatDigits = clampDisplayDigits(display_format_n);
}

pub export fn fnDynamicMenu(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnDynamicMenu(unused_but_mandatory_parameter);
}

pub export fn fnNop(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnNop(unused_but_mandatory_parameter);
}

pub export fn fnCFGsettings(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnCFGsettings(unused_but_mandatory_parameter);
}

pub export fn fnP_PrinterOnOff(op: u16) callconv(.c) void {
    if (op == PRON) {
        printerState.print_on = true;
        setSystemFlag(FLAG_PRTACT);
        fnSetFlag(FLAG_PRTEN);
    } else if (op == PROFF) {
        printerState.print_on = false;
        clearSystemFlag(FLAG_PRTACT);
        fnClearFlag(FLAG_PRTEN);
    }
}

pub export fn fnP_PrinterMode(mode: u16) callconv(.c) void {
    if (mode == MAN) {
        fnClearFlag(FLAG_NORM);
        fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == NORM) {
        fnSetFlag(FLAG_NORM);
        fnClearFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == TRACE) {
        fnClearFlag(FLAG_NORM);
        fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
    } else if (mode == STRACE) {
        fnSetFlag(FLAG_NORM);
        fnSetFlag(@as(u16, @intCast(FLAG_TRACE)));
    }
}

pub export fn fnSetPrinter(model: u16) callconv(.c) void {
    printerState.printer_model = @as(c_int, @intCast(model));
}

pub export fn fnP_SetDelay(delay: u16) callconv(.c) void {
    printerState.delay = delay;
    setLineDelay(delay);
}

pub export fn fnP_Advance(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_print_set_printer_sbi(true);
    print_lf();
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_PrinterList(lines: u16) callconv(.c) void {
    printProgram(true, lines);
}

pub export fn fnP_Byte(byte: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    cmdPrint(byte, PRINT_BYTE);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_Char(register_no: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    const character = z47_frontier_print_get_unicode_value(@as(i16, @intCast(register_no)));
    cmdPrint(character, PRINT_CHAR);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_Tab(column: u16) callconv(.c) void {
    z47_frontier_print_set_printer_sbi(true);
    cmdPrint(column, PRINT_TAB);
    z47_frontier_print_set_printer_sbi(false);
}

pub export fn fnP_LCD(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        return;
    }
    fnSNAP(9876);
}

pub export fn fnSetGapChar(char_param: u16) callconv(.c) void {
    const group = char_param & 49152;
    const value = char_param & 16383;
    if (group == 0) {
        gapItemLeft = value;
    } else if (group == 32768) {
        gapItemRight = value;
    } else if (group == 49152) {
        gapItemRadix = value;
    }
}

pub export fn fnSettingsDispFormatGrpL(param: u16) callconv(.c) void {
    grpGroupingLeft = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrp1Lo(param: u16) callconv(.c) void {
    grpGroupingGr1LeftOverflow = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrp1L(param: u16) callconv(.c) void {
    grpGroupingGr1Left = @as(u8, @intCast(param));
}

pub export fn fnSettingsDispFormatGrpR(param: u16) callconv(.c) void {
    grpGroupingRight = @as(u8, @intCast(param));
}

pub export fn fnMenuGapL(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_L);
}

pub export fn fnMenuGapRX(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_RX);
}

pub export fn fnMenuGapR(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    showSoftmenu(-MNU_GAP_R);
}

pub export fn fnIntegerMode(mode: u16) callconv(.c) void {
    if (shortIntegerMode != @as(u8, @intCast(mode))) {
        setSystemFlagChanged(SETTING_SINT_MODE);
    }
    shortIntegerMode = @as(u8, @intCast(mode));
    fnRefreshState();
}

pub export fn fnWho(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    temporaryInformation = TI_WHO;
}

pub export fn fnVersion(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    temporaryInformation = TI_VERSION;
}

pub export fn fnSetRoundingMode(rm: u16) callconv(.c) void {
    roundingMode = @as(u8, @intCast(rm));
}

pub export fn fnSetSignificantDigits(s: u16) callconv(.c) void {
    significantDigits = @as(u8, @intCast(s));
    if (significantDigits == 0) {
        significantDigits = 34;
    }
}

pub export fn fnSetBaseNr(s: u16) callconv(.c) void {
    dispBase = @as(u8, @intCast(s));
    if (dispBase == 1) {
        dispBase = 0;
    }
}

pub export fn fnSetFractionDigits(s: u16) callconv(.c) void {
    fractionDigits = @as(u8, @intCast(s));
    if (fractionDigits == 0) {
        fractionDigits = 34;
    }
}

pub export fn fnAngularMode(am: u16) callconv(.c) void {
    if (currentAngularMode != @as(c_int, @intCast(am))) {
        setSystemFlagChanged(SETTING_AMODE);
    }
    currentAngularMode = @as(c_int, @intCast(am));
    fnRefreshState();
}

pub export fn fnFractionType(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;

    var state: u8 = 0;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRAC)))) state += 8;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRQ)))) state += 4;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PROPFR)))) state += 2;
    if (getSystemFlag(@as(c_int, @intCast(FLAG_FRACT)))) state += 1;

    if (getSystemFlag(@as(c_int, @intCast(FLAG_FRCYC)))) {
        state = switch (state) {
            0b0000 => 0b0001,
            0b0010 => 0b0011,
            0b0100 => 0b1100,
            0b0110 => 0b1110,
            0b0001 => 0b1110,
            0b0011 => 0b0001,
            0b1100 => 0b0011,
            0b1110 => 0b1100,
            else => 0b0011,
        };

        if ((state & 8) != 0) setSystemFlag(FLAG_IRFRAC) else clearSystemFlag(FLAG_IRFRAC);
        if ((state & 4) != 0) setSystemFlag(FLAG_IRFRQ) else clearSystemFlag(FLAG_IRFRQ);
        if ((state & 2) != 0) setSystemFlag(FLAG_PROPFR) else clearSystemFlag(FLAG_PROPFR);
        if ((state & 1) != 0) setSystemFlag(FLAG_FRACT) else clearSystemFlag(FLAG_FRACT);
    } else {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_IRFRQ)))) {
            flipSystemFlag(FLAG_IRFRAC);
        } else {
            flipSystemFlag(FLAG_FRACT);
        }
    }
}

pub export fn fnRange(r: u16) callconv(.c) void {
    exponentLimit = @as(i16, @intCast(r));
    if (exponentLimit < DF_DMX_MIN) {
        exponentLimit = DF_DMX_MIN;
    }
}

pub export fn fnHide(h: u16) callconv(.c) void {
    exponentHideLimit = @as(i16, @intCast(h));
    if (exponentHideLimit > 0 and exponentHideLimit < DF_HIDE_MIN) {
        exponentHideLimit = DF_HIDE_MIN;
    }
}

pub export fn fnConfirmationYes(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        popSoftmenu();
        if (confirmedFunction) |func| {
            func(CONFIRMED);
        }
    }
}

pub export fn fnConfirmationNo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    if (calcMode == CM_CONFIRMATION) {
        calcMode = previousCalcMode;
        popSoftmenu();
    }
}

pub export fn fnGetRange(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_push_u32_to_x(@as(u32, @intCast(exponentLimit)));
}

pub export fn fnGetHide(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_push_u32_to_x(@as(u32, @intCast(exponentHideLimit)));
}

pub export fn fnGetLastErr(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    z47_frontier_push_u32_to_x(@as(u32, previousErrorCode));
}

pub export fn fnClAll(confirmation: u16) callconv(.c) void {
    if (confirmation == NOT_CONFIRMED) {
        setConfirmationMode(&fnClAll);
        return;
    }

    fnClPAll(CONFIRMED);
    fnClSigma(CONFIRMED);
    z47_frontier_release_saved_statistical_sums();

    allocateLocalRegisters(0);

    var regist: u16 = FIRST_GLOBAL_REGISTER;
    while (regist <= LAST_GLOBAL_REGISTER) : (regist += 1) {
        clearRegister(@as(i16, @intCast(regist)));
    }
    thereIsSomethingToUndo = false;

    fnExitAllMenus(NOPARAM);
    fnDeleteUserMenus(CONFIRMED);

    if (z47_frontier_is_r47_fam()) {
        fnRESET_MyM(ITM_RIBBON_R47);
    } else {
        fnRESET_MyM(ITM_RIBBON_C47);
    }

    fnRESET_Mya();
    createHOME();
    createPFN();

    fnKeysManagement(USER_KRESET);
    initUserKeyArgument();
    fnDeleteAllVariables(CONFIRMED);
    fnClFAll(CONFIRMED);

    temporaryInformation = TI_RESET;
    if (programRunStop == PGM_WAITING) {
        programRunStop = PGM_STOPPED;
    }
}

pub export fn fnP_User(unused_but_mandatory_parameter: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnP_User(unused_but_mandatory_parameter);
}

pub export fn fnP_Alpha(register_no: u16) callconv(.c) void {
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        z47_frontier_print_alpha_register(register_no);
        return;
    }

    runtime.z47_frontier_retained_fnP_Alpha(register_no);
}

pub export fn fnP_Sigma(unused_but_mandatory_parameter: u16) callconv(.c) void {
    _ = unused_but_mandatory_parameter;
    currentKeyCode = 255;

    if (statisticalSumsPointer != null) {
        if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
            if (!getSystemFlag(@as(c_int, @intCast(FLAG_PRTEN))) and (programRunStop == PGM_RUNNING or programRunStop == PGM_SINGLE_STEP)) {
                displayCalcErrorMessage(ERROR_PRINTING_DISABLED, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                return;
            }

            var regist: u16 = 0;
            while (regist < 28) : (regist += 1) {
                z47_frontier_print_sigma_line(regist);
                if (z47_frontier_print_exit_pressed()) {
                    return;
                }
            }
        }
        return;
    }

    displayCalcErrorMessage(ERROR_NO_SUMMATION_DATA, ERR_REGISTER_LINE, REGISTER_X);
}

pub export fn fnP_All_Regs(option: u16) callconv(.c) void {
    if (getSystemFlag(@as(c_int, @intCast(FLAG_PRTACT)))) {
        var s: u16 = 0;
        var n: u16 = 0;

        switch (option) {
            PRN_ALL => {
                if (z47_frontier_print_reg_range(@as(u16, @intCast(REGISTER_X)), REGISTER_W)) return;
                if (z47_frontier_print_reg_range(0, 99)) return;

                const local_count = z47_frontier_current_number_of_local_registers();
                if (local_count > 0) {
                    if (z47_frontier_print_reg_range(FIRST_LOCAL_REGISTER, FIRST_LOCAL_REGISTER + local_count - 1)) return;
                }

                if (numberOfNamedVariables > 0) {
                    _ = z47_frontier_print_reg_range(FIRST_NAMED_VARIABLE, FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1);
                }
            },
            PRN_REGS => {
                lastErrorCode = getRegParam(null, &s, &n, null);
                if (lastErrorCode == ERROR_NONE) {
                    _ = z47_frontier_print_reg_range(s, (s + n) - 1);
                } else {
                    displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
                }
            },
            PRN_Xr => {
                printReg(@as(u16, @intCast(REGISTER_X)), null, false, LINE_FULL, false);
            },
            PRN_STK => {
                const stack_top: u16 = if (getSystemFlag(FLAG_SSIZE8)) REGISTER_D else REGISTER_T;
                _ = z47_frontier_print_reg_range(stack_top, @as(u16, @intCast(REGISTER_X)));
            },
            PRN_XYr => {
                const x_type = getRegisterDataType(REGISTER_X);
                if (isPrintableScalarType(x_type)) {
                    const y_type = getRegisterDataType(REGISTER_Y);
                    if (isPrintableScalarType(y_type)) {
                        printReg(@as(u16, @intCast(REGISTER_X)), null, false, LINE_LEFT, false);
                        printReg(@as(u16, @intCast(REGISTER_Y)), null, false, LINE_RIGHT, false);
                        return;
                    }
                    displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_Y);
                    return;
                }

                if (x_type == dtReal34Matrix) {
                    const rows = z47_frontier_x_real_matrix_rows();
                    const cols = z47_frontier_x_real_matrix_cols();

                    if (cols == 2) {
                        var i: u32 = 0;
                        while (i < rows) : (i += 1) {
                            const left_index = i * 2;
                            z47_frontier_x_real_matrix_element_to_temp1(left_index);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_real_matrix_element_to_temp1(left_index + 1);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    if (rows == 2) {
                        var j: u32 = 0;
                        while (j < cols) : (j += 1) {
                            z47_frontier_x_real_matrix_element_to_temp1(j);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_real_matrix_element_to_temp1(j + cols);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
                    return;
                }

                if (x_type == dtComplex34Matrix) {
                    const rows = z47_frontier_x_complex_matrix_rows();
                    const cols = z47_frontier_x_complex_matrix_cols();

                    if (cols == 2) {
                        var i: u32 = 0;
                        while (i < rows) : (i += 1) {
                            const left_index = i * 2;
                            z47_frontier_x_complex_matrix_element_to_temp1(left_index);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_complex_matrix_element_to_temp1(left_index + 1);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    if (rows == 2) {
                        var j: u32 = 0;
                        while (j < cols) : (j += 1) {
                            z47_frontier_x_complex_matrix_element_to_temp1(j);
                            printReg(TEMP_REGISTER_1, null, false, LINE_LEFT, false);

                            z47_frontier_x_complex_matrix_element_to_temp1(j + cols);
                            printReg(TEMP_REGISTER_1, null, false, LINE_RIGHT, false);
                        }
                        return;
                    }

                    displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
                    return;
                }

                displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, REGISTER_X);
            },
            else => {
                // No-op for unsupported print-to-printer options in this command.
            },
        }
        return;
    }

    if (calcMode != CM_NORMAL and calcMode != CM_NO_UNDO) {
        return;
    }

    create_filename(".REGS.TSV");

    var s: u16 = 0;
    var n: u16 = 0;
    const local_count = z47_frontier_current_number_of_local_registers();

    switch (option) {
        PRN_ALL => {
            stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_W)), false);
            stackregister_csv_out(0, 99, false);
            if (local_count > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_LOCAL_REGISTER)), @as(i16, @intCast(FIRST_LOCAL_REGISTER + local_count - 1)), false);
            }
            if (numberOfNamedVariables > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_NAMED_VARIABLE)), @as(i16, @intCast(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1)), false);
            }
        },
        PRN_REGS => {
            lastErrorCode = getRegParam(null, &s, &n, null);
            if (lastErrorCode == ERROR_NONE) {
                stackregister_csv_out(@as(i16, @intCast(s)), @as(i16, @intCast((s + n) - 1)), false);
            } else {
                displayCalcErrorMessage(lastErrorCode, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
            }
        },
        PRN_STK => {
            if (getSystemFlag(FLAG_SSIZE8)) {
                stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_D)), false);
            } else {
                stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_T)), false);
            }
        },
        PRN_GLOBALr => {
            stackregister_csv_out(0, 99, false);
        },
        PRN_LOCALr => {
            if (local_count > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_LOCAL_REGISTER)), @as(i16, @intCast(FIRST_LOCAL_REGISTER + local_count - 1)), false);
            }
        },
        PRN_NAMEDr => {
            if (numberOfNamedVariables > 0) {
                stackregister_csv_out(@as(i16, @intCast(FIRST_NAMED_VARIABLE)), @as(i16, @intCast(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1)), false);
            }
        },
        PRN_Xr => {
            stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_X)), false);
        },
        PRN_TMP => {
            stackregister_csv_out(@as(i16, @intCast(TEMP_REGISTER_1)), @as(i16, @intCast(TEMP_REGISTER_1)), false);
        },
        PRN_XYr => {
            stackregister_csv_out(@as(i16, @intCast(REGISTER_X)), @as(i16, @intCast(REGISTER_Y)), true);
        },
        else => {},
    }
}

pub export fn fnKeysManagement(choice: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnKeysManagement(choice);
}

pub export fn fnPlotStat(plot_mode: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnPlotStat(plot_mode);
}

pub export fn fnEditMatrix(regist: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnEditMatrix(regist);
}

pub export fn fnClPAll(confirmation: u16) callconv(.c) void {
    runtime.z47_frontier_retained_fnClPAll(confirmation);
}