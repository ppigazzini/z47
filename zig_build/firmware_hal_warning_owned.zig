const KEY_ENTER: c_int = 13;
const KEY_BSP: c_int = 17;
const KEY_EXIT: c_int = 33;

extern fn strtok(str: [*c]u8, delim: [*c]const u8) [*c]u8;
extern fn lcd_puts(line: c_int, text: [*c]const u8) void;
extern fn lcd_putsRAt(line: c_int, col: c_int, text: [*c]const u8) void;
extern fn lcd_refresh() void;
extern fn lcd_clear_buf() void;
extern fn lcd_setLine(line: c_int, row: c_int) void;
extern var t24: c_int;
extern fn wait_for_key_release(timeout: c_int) void;
extern fn runner_get_key(arg: ?*anyopaque) c_int;
extern fn is_menu_auto_off() c_int;
extern fn disp_disk_info(title: [*c]const u8) void;
extern fn wait_for_key_press() void;

fn isExitKey(key: c_int) bool {
    return key == KEY_EXIT or key == KEY_BSP;
}

pub fn showWarning(str: [*c]u8) void {
    const delim = "\n";
    var ptr = strtok(str, "\n");

    lcd_clear_buf();
    lcd_putsRAt(t24, 0, "                   WARNING");
    lcd_setLine(t24, 1);

    while (ptr != null) {
        lcd_puts(t24, ptr);
        ptr = strtok(null, delim);
    }

    lcd_putsRAt(t24, 8, "Press [ENTER] to continue.");
    lcd_refresh();
    wait_for_key_release(-1);

    while (true) {
        const key = runner_get_key(null);
        if (key == KEY_ENTER or isExitKey(key) or is_menu_auto_off() != 0) {
            break;
        }
    }
}

pub fn fnDiskInfo(unused_but_mandatory_parameter: u16) void {
    _ = unused_but_mandatory_parameter;
    disp_disk_info("Disk Info");
    wait_for_key_press();
}
