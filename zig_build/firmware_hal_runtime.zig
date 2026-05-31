const export_audio_owned = @import("firmware_hal_export_audio_owned.zig");
const export_printer_owned = @import("firmware_hal_export_printer_owned.zig");
const io_path_bridge_owned = @import("firmware_hal_io_path_bridge_owned.zig");
const file_io_bridge_owned = @import("firmware_hal_file_io_bridge_owned.zig");
const statefile_bridge_owned = @import("firmware_hal_statefile_bridge_owned.zig");
const programfile_bridge_owned = @import("firmware_hal_programfile_bridge_owned.zig");
const warning_bridge_owned = @import("firmware_hal_warning_bridge_owned.zig");

var io_write_enabled: c_int = 0;
var io_read_enabled: c_int = 0;

pub export fn audioTone(frequency: u32) callconv(.c) void {
    export_audio_owned.audioTone(frequency);
}

pub export fn dm42_squeak() callconv(.c) void {
    export_audio_owned.dm42Squeak();
}

pub export fn fnSetVolume(volume: u16) callconv(.c) void {
    export_audio_owned.fnSetVolume(volume);
}

pub export fn getBeepVolume() callconv(.c) u16 {
    return export_audio_owned.getBeepVolume();
}

pub export fn fnGetVolume(unused_but_mandatory_parameter: u16) callconv(.c) void {
    export_audio_owned.fnGetVolume(unused_but_mandatory_parameter);
}

pub export fn fnVolumeUp(unused_but_mandatory_parameter: u16) callconv(.c) void {
    export_audio_owned.fnVolumeUp(unused_but_mandatory_parameter);
}

pub export fn fnVolumeDown(unused_but_mandatory_parameter: u16) callconv(.c) void {
    export_audio_owned.fnVolumeDown(unused_but_mandatory_parameter);
}

pub export fn _Buzz(frequency: u32, ms_delay: u32) callconv(.c) void {
    export_audio_owned.buzz(frequency, ms_delay);
}

pub export fn fnBuzz(unused_but_mandatory_parameter: u16) callconv(.c) void {
    export_audio_owned.fnBuzz(unused_but_mandatory_parameter);
}

pub export fn fnPlay(regist: u16) callconv(.c) void {
    export_audio_owned.fnPlay(regist);
}

pub export fn getLineDelay() callconv(.c) u32 {
    return export_printer_owned.getLineDelay();
}

pub export fn setLineDelay(delay: u16) callconv(.c) void {
    export_printer_owned.setLineDelay(delay);
}

pub export fn sendByteIR(byte: u8) callconv(.c) void {
    export_printer_owned.sendByteIR(byte);
}

pub export fn _ioFileNameFromFilePath(path: c_int, filename: [*c]u8) callconv(.c) c_int {
    return io_path_bridge_owned.ioFileNameFromFilePath(path, filename);
}

pub export fn ioFileOpen(path: c_int, mode: c_int) callconv(.c) c_int {
    return file_io_bridge_owned.ioFileOpen(path, mode, &io_write_enabled, &io_read_enabled);
}

pub export fn ioFileWrite(buffer: ?*const anyopaque, size: u32) callconv(.c) void {
    file_io_bridge_owned.ioFileWrite(buffer, size);
}

pub export fn ioFileRead(buffer: ?*anyopaque, size: u32) callconv(.c) u32 {
    return file_io_bridge_owned.ioFileRead(buffer, size);
}

pub export fn ioFileSeek(position: u32) callconv(.c) void {
    file_io_bridge_owned.ioFileSeek(position);
}

pub export fn ioFileClose() callconv(.c) void {
    file_io_bridge_owned.ioFileClose(&io_write_enabled, &io_read_enabled);
}

pub export fn ioEof() callconv(.c) c_int {
    return file_io_bridge_owned.ioEof();
}

pub export fn ioFileRemove(path: c_int, error_number: ?*u32) callconv(.c) c_int {
    return file_io_bridge_owned.ioFileRemove(path, error_number);
}

pub export fn save_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    return statefile_bridge_owned.saveStatefile(fpath, fname, data);
}

pub export fn load_statefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    return statefile_bridge_owned.loadStatefile(fpath, fname, data);
}

pub export fn save_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    return programfile_bridge_owned.saveProgramfile(fpath, fname, data);
}

pub export fn load_programfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) callconv(.c) c_int {
    return programfile_bridge_owned.loadProgramfile(fpath, fname, data);
}

pub export fn show_warning(str: [*c]u8) callconv(.c) void {
    warning_bridge_owned.showWarning(str);
}

pub export fn fnDiskInfo(unused_but_mandatory_parameter: u16) callconv(.c) void {
    warning_bridge_owned.fnDiskInfo(unused_but_mandatory_parameter);
}
