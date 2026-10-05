const std = @import("std");

// lcd_buffer holds one bit per pixel with the DMCP polarity: a set bit is a
// white pixel and a clear bit a black one. LCD_write_line paints it that way,
// bitblt24's BLT_OR clears bits (draws black) and BLT_ANDN sets them (draws
// white), and lcd_fill_rect takes its val as a flag, not as a byte: 0 selects
// BLT_ANDN and fills white, anything else selects BLT_OR and fills black. The
// names LCD_SET_VALUE (0, fills white) and LCD_EMPTY_VALUE (255, fills black)
// come from dmcp.h and are the other way round from what they suggest.
const SCREEN_WIDTH: u32 = 400;
const SCREEN_HEIGHT: u32 = 240;
const ON_PIXEL: u32 = 0x303030;
const OFF_PIXEL: u32 = 0xe0e0e0;
const G_PRIORITY_LOW: c_int = 300;
const LCD_LINE_SIZE: u32 = 50;
const BLT_OR: c_int = 0;
const BLT_ANDN: c_int = 1;
const BLT_XOR: c_int = 2;
const BLT_NONE: c_int = 0;
const BLT_SET: c_int = 1;

pub export var ui_is_active: c_int = 0;

extern var lcd_buffer: [*c]u8;
extern var screenData: [*c]u32;
extern var screenStride: c_short;
extern var screen: ?*anyopaque;
extern var headlessMode: bool;
// True while setPrinterSBI() refreshes the status bar for the print annunciator,
// which changes twice per printed line and so does not wait for a painted frame.
extern var printerIconRefresh: bool;

// A queued draw waits on the frame clock, so it is still unpainted when the
// event queue is empty.
var drawQueued: bool = false;

extern fn abort() noreturn;
extern fn printf(format: [*c]const u8, ...) c_int;
extern fn gtk_widget_queue_draw_area(widget: ?*anyopaque, x: c_int, y: c_int, width: c_int, height: c_int) void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;
extern fn gtk_main_level() c_uint;
extern fn gtk_widget_get_mapped(widget: ?*anyopaque) c_int;
extern fn g_timeout_add_full(priority: c_int, interval: c_uint, function: *const fn (?*anyopaque) callconv(.c) c_int, data: ?*anyopaque, notify: ?*const fn (?*anyopaque) callconv(.c) void) c_uint;
extern fn g_source_remove(tag: c_uint) c_int;

fn linePtr(row: u32) [*c]u8 {
    return lcd_buffer + (52 * row);
}

pub export fn lcd_line_addr(row: c_int) callconv(.c) [*c]u8 {
    if (row < 0 or row >= SCREEN_HEIGHT) {
        _ = printf("lcd_line_addr: row out of range\n");
        abort();
    }

    linePtr(@intCast(row))[0] = 1;
    return linePtr(@intCast(row)) + 2;
}

pub export fn LCD_write_line(line_buf: [*c]u8) callconv(.c) void {
    if (line_buf[1] >= SCREEN_HEIGHT) {
        _ = printf("LCD_write_line: row out of range\n");
        abort();
    }

    const row: u32 = line_buf[1];
    const stride: usize = @intCast(screenStride);
    const line_start = screenData + ((SCREEN_HEIGHT - row) * stride) - 1;

    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        const tmp_char: u8 = line_buf[i + 2];
        var j: u32 = 0;
        while (j < 8) : (j += 1) {
            const pixel = if (((tmp_char >> @intCast(j)) & 1) != 0) OFF_PIXEL else ON_PIXEL;
            (line_start - (i * 8) - j)[0] = pixel;
        }
    }

    line_buf[0] = 0;
    if (!headlessMode and screen != null) {
        gtk_widget_queue_draw_area(screen, 0, @intCast(SCREEN_HEIGHT - row - 1), 400, 1);
        drawQueued = true;
    }
}

pub export fn lcd_clear_buf() callconv(.c) void {
    var row: u32 = 0;
    while (row < SCREEN_HEIGHT) : (row += 1) {
        const line_buf = linePtr(row);

        var c: u32 = 2;
        while (c < 52) : (c += 1) {
            line_buf[c] = 255;
        }

        line_buf[1] = @intCast(SCREEN_HEIGHT - row - 1);
        line_buf[0] = 1;
        LCD_write_line(line_buf);
    }
}

pub export fn lcd_refresh() callconv(.c) void {
    drawQueued = false;
    var row: u32 = 0;
    while (row < SCREEN_HEIGHT) : (row += 1) {
        if (linePtr(row)[0] != 0) {
            LCD_write_line(linePtr(row));
        }
    }
}

pub export fn lcd_refresh_lines(ln: u8, cnt: u8) callconv(.c) void {
    if (@as(u16, ln) + @as(u16, cnt) >= SCREEN_HEIGHT) {
        _ = printf("lcd_refresh_lines: range out of bounds\n");
        abort();
    }

    var row: u32 = ln;
    while (row < @as(u32, ln) + @as(u32, cnt)) : (row += 1) {
        LCD_write_line(linePtr(row));
    }
}

pub export fn bitblt24(x_in: u32, dx: u32, y: u32, val: u32, blt_op: c_int, fill: c_int) callconv(.c) void {
    if (dx < 1 or dx > 24) return;
    if (x_in >= SCREEN_WIDTH or x_in + dx > SCREEN_WIDTH) return;

    const x = SCREEN_WIDTH - dx - x_in;
    const byte_i = x >> 3;
    const bit_off = x & 7;
    const lowmask = (@as(u32, 1) << @intCast(dx)) - 1;
    const bytes_needed = (bit_off + dx + 7) / 8;

    const srcbits: u32 = (val & lowmask) << @intCast(bit_off);
    // BLT_SET: the dx columns are written white before BLT_OR and black before BLT_ANDN
    const fillbits: u32 = if (fill == BLT_SET) lowmask << @intCast(bit_off) else 0;

    const srcbytes = [4]u8{
        @truncate(srcbits >> 0),
        @truncate(srcbits >> 8),
        @truncate(srcbits >> 16),
        @truncate(srcbits >> 24),
    };
    const fillbytes = [4]u8{
        @truncate(fillbits >> 0),
        @truncate(fillbits >> 8),
        @truncate(fillbits >> 16),
        @truncate(fillbits >> 24),
    };

    const base = lcd_buffer + (y * (LCD_LINE_SIZE + 2)) + byte_i + 2;

    var i: u32 = 0;
    while (i < bytes_needed) : (i += 1) {
        switch (blt_op) {
            BLT_OR => base[i] = (base[i] | fillbytes[i]) & ~srcbytes[i],
            BLT_XOR => base[i] ^= srcbytes[i],
            BLT_ANDN => base[i] = (base[i] & ~fillbytes[i]) | srcbytes[i],
            else => return,
        }
    }

    lcd_buffer[y * (LCD_LINE_SIZE + 2)] = 1;
}

pub export var clearScreenCounter: i16 = 0;

pub export fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void {
    // Unsigned wraparound (as in C) so an off-screen rect from a negative-width
    // caller is rejected by the bounds test rather than panicking.
    const end_x = x +% dx;
    const end_y = y +% dy;

    if (end_x > SCREEN_WIDTH or end_y > SCREEN_HEIGHT) return;

    // val is a flag: 0 (LCD_SET_VALUE) fills white through BLT_ANDN, anything
    // else fills black through BLT_OR.
    const blt_op: c_int = if (val != 0) BLT_OR else BLT_ANDN;

    var col: u32 = x;
    while (col < end_x) : (col += 24) {
        const cols = if (end_x - col < 24) (end_x - col) else 24;

        var line: u32 = y;
        while (line < end_y) : (line += 1) {
            bitblt24(col, cols, line, 0xFFFFFF, blt_op, BLT_NONE);
        }
    }
}

// Reads one pixel off the surface LCD_write_line writes, so a capture takes an
// overlay too, not only what the composition left in lcd_buffer. The screen
// and menu dumps use it to serialise the LCD into a BMP. bool_t is a one-byte
// 0/1 here.
pub export fn lcd_buffer_pixel_on(x: u32, y: u32) callconv(.c) u8 {
    if (x >= SCREEN_WIDTH or y >= SCREEN_HEIGHT) {
        return 0;
    }
    const stride: usize = @intCast(screenStride);
    return @intFromBool(screenData[(y + 1) * stride - SCREEN_WIDTH + x] == ON_PIXEL);
}

pub export fn refresh_gui() callconv(.c) void {
    if (headlessMode) return;
    while (gtk_events_pending() != 0) {
        if (ui_is_active != 0) break;
        _ = gtk_main_iteration();
    }
}

pub export fn _lcdRefresh() callconv(.c) void {
    lcd_refresh();
}

// Kept alive so the id stays valid to remove.
fn pumpGuardTick(data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    return 1;
}

pub export fn _lcdSBRefresh() callconv(.c) void {
    lcd_refresh();
    // gtk_main_level() is 0 in the batch runs (--writeexportall, --mockup,
    // --dumpmenus, --exec, --script), which paint before gtk_main() and never
    // release a blocked pump.
    if (drawQueued and gtk_main_level() > 0 and !headlessMode and ui_is_active == 0 and !printerIconRefresh and screen != null and gtk_widget_get_mapped(screen) != 0) {
        // 20 ms cap on the pump; below GDK_PRIORITY_REDRAW, so a ready frame
        // paints first.
        const pumpGuard = g_timeout_add_full(G_PRIORITY_LOW, 20, pumpGuardTick, null, null);
        _ = gtk_main_iteration();
        _ = g_source_remove(pumpGuard);
        refresh_gui();
    }
}
