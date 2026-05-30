const MRET_EXIT: c_int = -2;
const MRET_SAVESTATE: c_int = 777;
const MRET_LOADSTATE: c_int = 888;

const KEY_ENTER: c_int = 13;
const KEY_BSP: c_int = 17;
const KEY_EXIT: c_int = 33;

extern fn strcpy(dst: [*c]u8, src: [*c]const u8) [*c]u8;
extern fn lcd_puts(line: c_int, text: [*c]const u8) void;
extern fn lcd_putsRAt(line: c_int, col: c_int, text: [*c]const u8) void;
extern fn lcd_refresh() void;
extern fn lcd_refresh_wait() void;
extern fn wait_for_key_release(timeout: c_int) void;
extern fn runner_get_key(arg: ?*anyopaque) c_int;
extern fn is_menu_auto_off() c_int;
extern fn set_reset_state_file(path: [*c]const u8) void;
extern var t24: c_int;

fn isExitKey(key: c_int) bool {
    return key == KEY_EXIT or key == KEY_BSP;
}

pub fn saveStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    lcd_puts(t24, "Saving state ...");
    lcd_puts(t24, fname);
    lcd_refresh();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    set_reset_state_file(fpath);
    return MRET_SAVESTATE;
}

pub fn loadStatefile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    _ = fname;

    lcd_puts(t24, "");
    lcd_puts(t24, "WARNING: Current calculator state");
    lcd_puts(t24, "will be lost.");
    lcd_puts(t24, "");
    lcd_puts(t24, "");
    lcd_puts(t24, "Press [ENTER] to confirm.");
    lcd_refresh();

    wait_for_key_release(-1);

    while (true) {
        const key = runner_get_key(null);
        if (isExitKey(key)) {
            return 0;
        }
        if (is_menu_auto_off() != 0) {
            return MRET_EXIT;
        }
        if (key == KEY_ENTER) {
            break;
        }
    }

    lcd_putsRAt(t24, 6, "  Loading ...");
    lcd_refresh_wait();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    set_reset_state_file(fpath);
    return MRET_LOADSTATE;
}

pub fn saveProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    lcd_puts(t24, "Saving program ...");
    lcd_puts(t24, fname);
    lcd_refresh();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    return MRET_SAVESTATE;
}

pub fn loadProgramfile(fpath: [*c]const u8, fname: [*c]const u8, data: ?*anyopaque) c_int {
    _ = fname;

    lcd_putsRAt(t24, 6, "  Loading ...");
    lcd_refresh_wait();

    if (data != null) {
        _ = strcpy(@ptrCast(data.?), fpath);
    }
    return MRET_LOADSTATE;
}
