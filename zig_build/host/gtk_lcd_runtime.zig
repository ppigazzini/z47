const std = @import("std");

const SCREEN_WIDTH: u32 = 400;
const SCREEN_HEIGHT: u32 = 240;
const ON_PIXEL: u32 = 0x303030;
const OFF_PIXEL: u32 = 0xe0e0e0;
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

extern fn abort() noreturn;
extern fn printf(format: [*c]const u8, ...) c_int;
extern fn gtk_widget_queue_draw_area(widget: ?*anyopaque, x: c_int, y: c_int, width: c_int, height: c_int) void;
extern fn gtk_events_pending() c_int;
extern fn gtk_main_iteration() c_int;

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
            const pixel = if (((tmp_char >> @intCast(j)) & 1) != 0) ON_PIXEL else OFF_PIXEL;
            (line_start - (i * 8) - j)[0] = pixel;
        }
    }

    line_buf[0] = 0;
    gtk_widget_queue_draw_area(screen, 0, @intCast(SCREEN_HEIGHT - row - 1), 400, 1);
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

    var srcbits: u32 = 0;
    if (fill == BLT_SET and blt_op != BLT_XOR) {
        srcbits = if (blt_op == BLT_ANDN) lowmask << @intCast(bit_off) else 0;
    } else {
        srcbits = (val & lowmask) << @intCast(bit_off);
    }

    const srcbytes = [4]u8{
        @truncate(srcbits >> 0),
        @truncate(srcbits >> 8),
        @truncate(srcbits >> 16),
        @truncate(srcbits >> 24),
    };

    const base = lcd_buffer + (y * (LCD_LINE_SIZE + 2)) + byte_i + 2;

    var i: u32 = 0;
    while (i < bytes_needed) : (i += 1) {
        switch (blt_op) {
            BLT_OR => base[i] |= srcbytes[i],
            BLT_XOR => base[i] ^= srcbytes[i],
            BLT_ANDN => base[i] &= ~srcbytes[i],
            else => return,
        }
    }

    lcd_buffer[y * (LCD_LINE_SIZE + 2)] = 1;
}

pub export var clearScreenCounter: i16 = 0;

pub export fn lcd_fill_rect(x: u32, y: u32, dx: u32, dy: u32, val: c_int) callconv(.c) void {
    const end_x = x + dx;
    const end_y = y + dy;

    if (end_x > SCREEN_WIDTH or end_y > SCREEN_HEIGHT) return;

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

pub export fn refresh_gui() callconv(.c) void {
    while (gtk_events_pending() != 0) {
        if (ui_is_active != 0) break;
        _ = gtk_main_iteration();
    }
}

pub export fn _lcdRefresh() callconv(.c) void {
    lcd_refresh();
}

pub export fn _lcdBandRefresh(y: u32, dy: u32) callconv(.c) void {
    _ = y;
    _ = dy;
    lcd_refresh();
}

pub export fn _lcdSBRefresh() callconv(.c) void {
    lcd_refresh();
}
