const std = @import("std");
const builtin = @import("builtin");
const load_owned = @import("calc_state_load.zig");
const runtime = @import("calc_state_runtime.zig");
const save_owned = @import("calc_state_save.zig");
const restore_owned = @import("calc_state_restore.zig");

const is_dmcp_build = builtin.target.os.tag == .freestanding;

var compat_saved_calc_model: u16 = 0;
var compat_loaded_version: u32 = 0;

fn parseIntCompat(comptime T: type, str: [*:0]const u8) T {
    return std.fmt.parseInt(T, std.mem.span(str), 10) catch 0;
}

fn saveCalcBackupHost() callconv(.c) void {
    runtime.saveCalcBackup();
}

fn restoreCalcBackupHost() callconv(.c) void {
    runtime.restoreCalcBackup();
}

comptime {
    // Force the shared decNumber contexts + solver context + error state (base).
    _ = @import("decimal_context.zig");
    _ = @import("solver_context.zig");
    _ = @import("error_state.zig");
    _ = @import("calc_globals.zig");
    _ = @import("real_special_values.zig");
    _ = @import("system_flags_state.zig");
    _ = @import("byte_copy.zig");
    _ = @import("transient_status.zig");
    _ = @import("screen_update_state.zig");
    _ = @import("error_report.zig");
    if (!is_dmcp_build) {
        @export(&saveCalcBackupHost, .{ .name = "saveCalc" });
        @export(&restoreCalcBackupHost, .{ .name = "restoreCalc" });
    }
}

pub export fn doLoad(load_mode: u16, s: u16, n: u16, d: u16, load_type: u16) void {
    load_owned.doLoad(load_mode, s, n, d, load_type);
}

pub export fn fnLoad(load_mode: u16) void {
    load_owned.load(load_mode);
}

pub export fn fnLoadAuto() void {
    load_owned.loadAuto();
}

pub export fn fnSaveAuto(unused_but_mandatory_parameter: u16) void {
    load_owned.saveAuto(unused_but_mandatory_parameter);
}

pub export fn fnSave(save_mode: u16) void {
    load_owned.save(save_mode);
}

pub export fn z47_calc_state_reset_load_context() void {
    compat_saved_calc_model = 0;
    compat_loaded_version = 0;
}

pub export fn z47_calc_state_set_saved_calc_model(saved_calc_model: u16) void {
    compat_saved_calc_model = saved_calc_model;
}

pub export fn z47_calc_state_get_saved_calc_model() u16 {
    return compat_saved_calc_model;
}

pub export fn z47_calc_state_set_loaded_version(version: u32) void {
    compat_loaded_version = version;
}

pub export fn z47_calc_state_get_loaded_version() u32 {
    return compat_loaded_version;
}

pub export fn z47_calc_state_get_version_allowed() u32 {
    return runtime.VERSION_ALLOWED;
}

pub export fn z47_calc_state_get_config_file_version() u32 {
    return runtime.CONFIG_FILE_VERSION;
}

pub export fn z47_calc_state_restore_one_section(load_mode: u16, s: u16, n: u16, d: u16, allow_user_keys: bool) bool {
    // Host-only: DMCP firmware loads via the C retained path, so this symbol is
    // never called there. `comptime` forces the host branch out of firmware.
    return restore_owned.restoreOneSection(load_mode, s, n, d, allow_user_keys);
}

pub export fn z47_calc_state_save_sections() void {
    // Host-only: the DMCP firmware saves via the C retained path, so this symbol
    // is never called there. Gating it keeps the Zig section writer out of
    // firmware (byte-identical flash) while
    // still resolving the io_owned extern.
    save_owned.writeSaveSections();
}

pub export fn stringToUint8(str: [*:0]const u8) u8 {
    return parseIntCompat(u8, str);
}

pub export fn stringToUint32(str: [*:0]const u8) u32 {
    return parseIntCompat(u32, str);
}

pub export fn stringToInt16(str: [*:0]const u8) i16 {
    return parseIntCompat(i16, str);
}

pub export fn stringToInt32(str: [*:0]const u8) i32 {
    return parseIntCompat(i32, str);
}

pub export fn toInt32(str: [*:0]const u8) i32 {
    return stringToInt32(str);
}

pub export fn readLine(line: [*c]u8, maxLen: usize) void {
    const out = line orelse return;
    if (maxLen == 0) {
        return;
    }
    const end = maxLen - 1; // last writable slot; reserve one byte for '\0'
    var idx: usize = 0;

    if (runtime.ioEof() == 0) {
        _ = runtime.ioFileRead(&out[idx], 1);
        while ((out[idx] == '\n' or out[idx] == '\r') and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&out[idx], 1);
        }

        while (idx < end and out[idx] != '\n' and out[idx] != '\r' and runtime.ioEof() == 0) {
            idx += 1;
            _ = runtime.ioFileRead(&out[idx], 1);
        }
        // line longer than buffer: drain to EOL so the next read resyncs
        while (out[idx] != '\n' and out[idx] != '\r' and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&out[idx], 1);
        }
    }

    out[idx] = 0;
}

// read2Lines (saveRestoreCalcState.c): like readLine but reads two lines,
// preserving an empty line between registers saved as empty strings — it has to
// disambiguate CRLF/LFCR pairs from a genuine blank line.
pub export fn read2Lines(line1: [*c]u8, maxLen1: usize, line2: [*c]u8, maxLen2: usize) void {
    const l1 = line1 orelse return;
    const l2 = line2 orelse return;
    // last writable slot in each buffer (one byte reserved for '\0')
    const end1: usize = if (maxLen1 == 0) 0 else maxLen1 - 1;
    const end2: usize = if (maxLen2 == 0) 0 else maxLen2 - 1;
    var idx1: usize = 0;
    if (runtime.ioEof() == 0) {
        _ = runtime.ioFileRead(&l1[idx1], 1);
        while ((l1[idx1] == '\n' or l1[idx1] == '\r') and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&l1[idx1], 1);
        }
        while (idx1 < end1 and l1[idx1] != '\n' and l1[idx1] != '\r' and runtime.ioEof() == 0) {
            idx1 += 1;
            _ = runtime.ioFileRead(&l1[idx1], 1);
        }
        // overflow: drain to EOL so eol1 and the file position stay correct
        while (l1[idx1] != '\n' and l1[idx1] != '\r' and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&l1[idx1], 1);
        }
    }
    const eol1 = l1[idx1];
    l1[idx1] = 0;

    var idx2: usize = 0;
    if (runtime.ioEof() == 0) {
        _ = runtime.ioFileRead(&l2[idx2], 1);
        const eol2 = l2[idx2];
        if ((((eol1 == '\n') and (eol2 == '\n')) or ((eol1 == '\r') and (eol2 == '\r'))) and runtime.ioEof() == 0) {
            l2[idx2] = 0;
            return;
        }
        if ((((eol1 == '\r') and (eol2 == '\n')) or ((eol1 == '\n') and (eol2 == '\r'))) and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&l2[idx2], 1);
            if (((l2[idx2] == '\n') or (l2[idx2] == '\r')) and runtime.ioEof() == 0) {
                l2[idx2] = 0;
                return;
            }
        }
        while (idx2 < end2 and l2[idx2] != '\n' and l2[idx2] != '\r' and runtime.ioEof() == 0) {
            idx2 += 1;
            _ = runtime.ioFileRead(&l2[idx2], 1);
        }
        // overflow: drain to EOL so the next read resyncs
        while (l2[idx2] != '\n' and l2[idx2] != '\r' and runtime.ioEof() == 0) {
            _ = runtime.ioFileRead(&l2[idx2], 1);
        }
    }
    l2[idx2] = 0;
}

// Canonical string→number leaf helpers (saveRestoreCalcState.c), base 0 like the
// C strtol/strtoul/strtoll/strtoull/strtof originals (the int16/int32/uint8/
// uint32 variants are exported above).
extern fn strtoll(s: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_longlong;
extern fn strtoull(s: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_ulonglong;
extern fn strtol(s: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_long;
extern fn strtoul(s: [*c]const u8, endptr: ?*[*c]u8, base: c_int) c_ulong;
extern fn strtof(s: [*c]const u8, endptr: ?*[*c]u8) f32;
pub export fn stringToInt64(str: [*:0]const u8) i64 {
    return @intCast(strtoll(str, null, 0));
}
pub export fn stringToUint64(str: [*:0]const u8) u64 {
    return @intCast(strtoull(str, null, 0));
}
pub export fn stringToInt8(str: [*:0]const u8) i8 {
    return @truncate(strtol(str, null, 0));
}
pub export fn stringToUint16(str: [*:0]const u8) u16 {
    return @truncate(strtoul(str, null, 0));
}
pub export fn stringToFloat(str: [*:0]const u8) f32 {
    return strtof(str, null);
}

// Pre-001090500 reverse-blue-key parameter migration (saveRestoreCalcState.c).
pub export fn convert001090400T001090500(parameter: u8, offset: u8) u8 {
    return if (parameter < 20) parameter +% offset else parameter;
}

// Scratch buffer shared with the (now Zig) register codec / save owner; was a
// plain global in saveRestoreCalcState.c.
pub export var aimBuffer1: [400]u8 = std.mem.zeroes([400]u8);

pub export fn fnDeleteBackup(confirmation: u16) void {
    _ = confirmation;
}

pub export fn fnLoadedFile(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
}
