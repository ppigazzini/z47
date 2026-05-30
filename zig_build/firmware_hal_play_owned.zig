const audio_volume_owned = @import("firmware_hal_audio_volume_owned.zig");
const buzz_owned = @import("firmware_hal_buzz_owned.zig");

const FLAG_QUIET: u16 = 0x8019;
const KEY_BSP: c_int = 17;
const KEY_EXIT: c_int = 33;
const REGISTER_X: i16 = 100;
const REGISTER_Z: i16 = 102;
const ERROR_MATRIX_MISMATCH: u8 = 21;
const ERROR_INVALID_DATA_TYPE_FOR_OP: u8 = 24;
const NIM_REGISTER_LINE: i16 = REGISTER_X;
const ERR_REGISTER_LINE: i16 = REGISTER_Z;
const SCRUPD_AUTO: u8 = 0x00;
const SCRUPD_SKIP_STATUSBAR_ONE_TIME: u8 = 0x10;
const DT_REAL34_MATRIX: u32 = 6;
const DEC_ROUND_DOWN: c_int = 5;

const DecContext = opaque {};

const DecQuad = extern union {
    bytes: [16]u8,
    shorts: [8]u16,
    words: [4]u32,
};

const Real34Matrix = extern struct {
    header_raw: u32,
    matrixElements: [*c]DecQuad,
};

extern fn getSystemFlag(flag: u16) c_int;
extern fn getRegisterDataType(regist: i16) u32;
extern fn linkToRealMatrixRegister(regist: i16, linked_matrix: [*c]Real34Matrix) void;
extern fn decQuadToUInt32(source: [*c]const DecQuad, context: *DecContext, round: c_int) u32;
extern var ctxtReal34: DecContext;
extern fn displayCalcErrorMessage(error_code: u8, err_message_register_line: i16, err_register_line: i16) void;
extern var screenUpdatingMode: u8;
extern fn sys_delay(ms: u32) void;
extern fn key_empty() c_int;
extern fn key_pop() c_int;
extern fn key_pop_all() void;

fn isExitKey(key: c_int) bool {
    return key == KEY_EXIT or key == KEY_BSP;
}

fn matrixRows(header_raw: u32) u16 {
    return @truncate(header_raw & 0x0fff);
}

fn matrixCols(header_raw: u32) u16 {
    return @truncate((header_raw >> 12) & 0x0fff);
}

fn real34ToUInt32(value: [*c]const DecQuad) u32 {
    return decQuadToUInt32(value, &ctxtReal34, DEC_ROUND_DOWN);
}

pub fn fnPlay(regist: u16) void {
    const reg: i16 = @intCast(regist);

    if (getRegisterDataType(reg) != DT_REAL34_MATRIX) {
        displayCalcErrorMessage(ERROR_INVALID_DATA_TYPE_FOR_OP, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
        return;
    }

    if (getSystemFlag(FLAG_QUIET) != 0) {
        return;
    }

    var matrix: Real34Matrix = undefined;
    linkToRealMatrixRegister(reg, &matrix);

    const cols = matrixCols(matrix.header_raw);
    if (cols != 2 and cols != 3) {
        displayCalcErrorMessage(ERROR_MATRIX_MISMATCH, ERR_REGISTER_LINE, REGISTER_X);
        return;
    }

    screenUpdatingMode = SCRUPD_AUTO;
    screenUpdatingMode |= SCRUPD_SKIP_STATUSBAR_ONE_TIME;

    const rows = matrixRows(matrix.header_raw);
    var i: u16 = 0;
    while (i < rows) : (i += 1) {
        const base: usize = @as(usize, i) * cols;
        const frequency = real34ToUInt32(&matrix.matrixElements[base]);
        const ms_delay = real34ToUInt32(&matrix.matrixElements[base + 1]);

        if (cols == 3) {
            const volume: u16 = @truncate(real34ToUInt32(&matrix.matrixElements[base + 2]));
            audio_volume_owned.fnSetVolume(volume);
        }

        buzz_owned.buzz(frequency, ms_delay);
        if (ms_delay > 0) {
            sys_delay(@divTrunc(ms_delay, 8));
        }

        while (key_empty() == 0) {
            if (isExitKey(key_pop())) {
                key_pop_all();
                return;
            }
        }
    }
}
