// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors
// SPDX-FileCopyrightText: Copyright (c) 2017 Christoph Giesselink (HP82240B Roman-8 font table, GPL-2.0-or-later)

//! Zig port of src/c47-gtk/hal/printerWindow.c: the simulator's built-in HP
//! 82240B print-out window. sendByteIR() hands every byte to
//! printerWindowByte(), which decodes the HP 82240 byte stream into a bitmap of
//! 166 dot columns by 8 dot rows per paper line. Ctrl+P opens the window, which
//! offers advancing the paper, clearing the print-out and copying it to the
//! clipboard as text or as an image.
//!
//! The window exists only with OPTION_IR_PRINTING; without it both exports keep
//! upstream's empty bodies.

const std = @import("std");
const opts = @import("host_gtk_options");
const gtk_decls = @import("gtk_gui_host_decls.zig");

const GtkWidget = gtk_decls.GtkWidget;
const GdkRectangle = gtk_decls.GdkRectangle;
const gtk_window_new = gtk_decls.gtk_window_new;
const gtk_window_set_default_size = gtk_decls.gtk_window_set_default_size;
const gtk_window_set_title = gtk_decls.gtk_window_set_title;
const gtk_container_add = gtk_decls.gtk_container_add;
const gtk_widget_set_size_request = gtk_decls.gtk_widget_set_size_request;
const gtk_drawing_area_new = gtk_decls.gtk_drawing_area_new;
const gtk_widget_set_tooltip_text = gtk_decls.gtk_widget_set_tooltip_text;
const g_signal_connect_data = gtk_decls.g_signal_connect_data;

const ir_printing = opts.ir_printing;

const columns = 166; // dot columns per line of the HP 82240
const rows = 8; // dot rows per line, bit 0 is the top row
const max_lines = 20000; // lines kept before the oldest is discarded
const first_line_alloc = 256; // lines allocated when the first line is printed
const default_scale = 2; // screen pixels per printer dot at the default window width
const margin = 8; // screen pixels of white paper around the print-out
const esc = 27;

const Line = [columns]u8;

// HP 82240B Roman-8 font, codes 32 to 255, 5 dot columns per character, bit 0 is
// the top row. Taken from GraphFont.cpp of the HP82240B printer simulator by
// Christoph Giesselink.
const roman8_font = [224][5]u8{
    .{ 0x00, 0x00, 0x00, 0x00, 0x00 }, // 32
    .{ 0x00, 0x00, 0x5F, 0x00, 0x00 }, // 33
    .{ 0x00, 0x07, 0x00, 0x07, 0x00 }, // 34
    .{ 0x14, 0x7F, 0x14, 0x7F, 0x14 }, // 35
    .{ 0x24, 0x2A, 0x7F, 0x2A, 0x12 }, // 36
    .{ 0x23, 0x13, 0x08, 0x64, 0x62 }, // 37
    .{ 0x36, 0x49, 0x56, 0x20, 0x50 }, // 38
    .{ 0x00, 0x00, 0x07, 0x00, 0x00 }, // 39
    .{ 0x00, 0x1C, 0x22, 0x41, 0x00 }, // 40
    .{ 0x00, 0x41, 0x22, 0x1C, 0x00 }, // 41
    .{ 0x08, 0x2A, 0x1C, 0x2A, 0x08 }, // 42
    .{ 0x08, 0x08, 0x3E, 0x08, 0x08 }, // 43
    .{ 0x00, 0xB0, 0x70, 0x00, 0x00 }, // 44
    .{ 0x08, 0x08, 0x08, 0x08, 0x08 }, // 45
    .{ 0x00, 0x60, 0x60, 0x00, 0x00 }, // 46
    .{ 0x20, 0x10, 0x08, 0x04, 0x02 }, // 47
    .{ 0x3C, 0x62, 0x52, 0x4A, 0x3C }, // 48
    .{ 0x00, 0x44, 0x7E, 0x40, 0x00 }, // 49
    .{ 0x64, 0x52, 0x4A, 0x4A, 0x44 }, // 50
    .{ 0x24, 0x42, 0x4A, 0x4A, 0x34 }, // 51
    .{ 0x10, 0x18, 0x14, 0x7E, 0x10 }, // 52
    .{ 0x2E, 0x4A, 0x4A, 0x4A, 0x32 }, // 53
    .{ 0x38, 0x54, 0x52, 0x52, 0x20 }, // 54
    .{ 0x02, 0x62, 0x12, 0x0A, 0x06 }, // 55
    .{ 0x34, 0x4A, 0x4A, 0x4A, 0x34 }, // 56
    .{ 0x04, 0x4A, 0x4A, 0x2A, 0x1C }, // 57
    .{ 0x00, 0x36, 0x36, 0x00, 0x00 }, // 58
    .{ 0x00, 0xB6, 0x76, 0x00, 0x00 }, // 59
    .{ 0x08, 0x14, 0x22, 0x41, 0x00 }, // 60
    .{ 0x14, 0x14, 0x14, 0x14, 0x14 }, // 61
    .{ 0x41, 0x22, 0x14, 0x08, 0x00 }, // 62
    .{ 0x02, 0x01, 0x51, 0x09, 0x06 }, // 63
    .{ 0x3E, 0x41, 0x5D, 0x49, 0x4E }, // 64
    .{ 0x7C, 0x12, 0x12, 0x12, 0x7C }, // 65
    .{ 0x7E, 0x4A, 0x4A, 0x4A, 0x34 }, // 66
    .{ 0x3C, 0x42, 0x42, 0x42, 0x24 }, // 67
    .{ 0x7E, 0x42, 0x42, 0x24, 0x18 }, // 68
    .{ 0x7E, 0x4A, 0x4A, 0x4A, 0x42 }, // 69
    .{ 0x7E, 0x0A, 0x0A, 0x0A, 0x02 }, // 70
    .{ 0x3C, 0x42, 0x42, 0x52, 0x74 }, // 71
    .{ 0x7E, 0x08, 0x08, 0x08, 0x7E }, // 72
    .{ 0x00, 0x42, 0x7E, 0x42, 0x00 }, // 73
    .{ 0x20, 0x40, 0x40, 0x40, 0x3E }, // 74
    .{ 0x7E, 0x08, 0x14, 0x22, 0x40 }, // 75
    .{ 0x7E, 0x40, 0x40, 0x40, 0x40 }, // 76
    .{ 0x7E, 0x04, 0x18, 0x04, 0x7E }, // 77
    .{ 0x7E, 0x04, 0x08, 0x10, 0x7E }, // 78
    .{ 0x3C, 0x42, 0x42, 0x42, 0x3C }, // 79
    .{ 0x7E, 0x12, 0x12, 0x12, 0x0C }, // 80
    .{ 0x3C, 0x42, 0x52, 0x22, 0x5C }, // 81
    .{ 0x7E, 0x12, 0x12, 0x32, 0x4C }, // 82
    .{ 0x24, 0x4A, 0x4A, 0x4A, 0x30 }, // 83
    .{ 0x02, 0x02, 0x7E, 0x02, 0x02 }, // 84
    .{ 0x3E, 0x40, 0x40, 0x40, 0x3E }, // 85
    .{ 0x0E, 0x30, 0x40, 0x30, 0x0E }, // 86
    .{ 0x7E, 0x20, 0x18, 0x20, 0x7E }, // 87
    .{ 0x42, 0x24, 0x18, 0x24, 0x42 }, // 88
    .{ 0x06, 0x08, 0x70, 0x08, 0x06 }, // 89
    .{ 0x62, 0x52, 0x4A, 0x46, 0x42 }, // 90
    .{ 0x00, 0x7F, 0x41, 0x41, 0x00 }, // 91
    .{ 0x02, 0x04, 0x08, 0x10, 0x20 }, // 92
    .{ 0x00, 0x41, 0x41, 0x7F, 0x00 }, // 93
    .{ 0x04, 0x02, 0x01, 0x02, 0x04 }, // 94
    .{ 0x80, 0x80, 0x80, 0x80, 0x80 }, // 95
    .{ 0x00, 0x03, 0x04, 0x00, 0x00 }, // 96
    .{ 0x20, 0x54, 0x54, 0x54, 0x78 }, // 97
    .{ 0x7F, 0x44, 0x44, 0x44, 0x38 }, // 98
    .{ 0x38, 0x44, 0x44, 0x44, 0x44 }, // 99
    .{ 0x38, 0x44, 0x44, 0x44, 0x7F }, // 100
    .{ 0x38, 0x54, 0x54, 0x54, 0x18 }, // 101
    .{ 0x08, 0x7E, 0x09, 0x02, 0x00 }, // 102
    .{ 0x18, 0xA4, 0xA4, 0xA4, 0x78 }, // 103
    .{ 0x7F, 0x04, 0x04, 0x04, 0x78 }, // 104
    .{ 0x00, 0x44, 0x7D, 0x40, 0x00 }, // 105
    .{ 0x40, 0x80, 0x84, 0x7D, 0x00 }, // 106
    .{ 0x7F, 0x10, 0x28, 0x44, 0x00 }, // 107
    .{ 0x00, 0x41, 0x7F, 0x40, 0x00 }, // 108
    .{ 0x7C, 0x04, 0x38, 0x04, 0x78 }, // 109
    .{ 0x7C, 0x04, 0x04, 0x04, 0x78 }, // 110
    .{ 0x38, 0x44, 0x44, 0x44, 0x38 }, // 111
    .{ 0xFC, 0x24, 0x24, 0x24, 0x18 }, // 112
    .{ 0x18, 0x24, 0x24, 0x24, 0xFC }, // 113
    .{ 0x7C, 0x08, 0x04, 0x04, 0x04 }, // 114
    .{ 0x48, 0x54, 0x54, 0x54, 0x24 }, // 115
    .{ 0x04, 0x3F, 0x44, 0x20, 0x00 }, // 116
    .{ 0x3C, 0x40, 0x40, 0x40, 0x7C }, // 117
    .{ 0x1C, 0x20, 0x40, 0x20, 0x1C }, // 118
    .{ 0x3C, 0x40, 0x30, 0x40, 0x3C }, // 119
    .{ 0x44, 0x28, 0x10, 0x28, 0x44 }, // 120
    .{ 0x1C, 0xA0, 0xA0, 0xA0, 0x7C }, // 121
    .{ 0x44, 0x64, 0x54, 0x4C, 0x44 }, // 122
    .{ 0x08, 0x36, 0x41, 0x41, 0x00 }, // 123
    .{ 0x00, 0x00, 0x7F, 0x00, 0x00 }, // 124
    .{ 0x00, 0x41, 0x41, 0x36, 0x08 }, // 125
    .{ 0x08, 0x04, 0x08, 0x10, 0x08 }, // 126
    .{ 0x55, 0x2A, 0x55, 0x2A, 0x55 }, // 127
    .{ 0x00, 0x00, 0x00, 0x00, 0x00 }, // 128
    .{ 0x08, 0x08, 0x2A, 0x08, 0x08 }, // 129
    .{ 0x22, 0x14, 0x08, 0x14, 0x22 }, // 130
    .{ 0x10, 0x20, 0x7F, 0x01, 0x01 }, // 131
    .{ 0x20, 0x40, 0x3E, 0x01, 0x02 }, // 132
    .{ 0x41, 0x63, 0x55, 0x49, 0x63 }, // 133
    .{ 0x7F, 0x7F, 0x3E, 0x1C, 0x08 }, // 134
    .{ 0x04, 0x7C, 0x04, 0x7C, 0x04 }, // 135
    .{ 0x30, 0x49, 0x4A, 0x4C, 0x38 }, // 136
    .{ 0x50, 0x58, 0x54, 0x52, 0x51 }, // 137
    .{ 0x51, 0x52, 0x54, 0x58, 0x50 }, // 138
    .{ 0x14, 0x34, 0x1C, 0x16, 0x14 }, // 139
    .{ 0x30, 0x48, 0x48, 0x30, 0x48 }, // 140
    .{ 0x08, 0x08, 0x2A, 0x1C, 0x08 }, // 141
    .{ 0x08, 0x1C, 0x2A, 0x08, 0x08 }, // 142
    .{ 0x7C, 0x20, 0x20, 0x1C, 0x20 }, // 143
    .{ 0x0F, 0x08, 0x00, 0x78, 0x28 }, // 144
    .{ 0x00, 0x07, 0x05, 0x07, 0x00 }, // 145
    .{ 0x08, 0x14, 0x2A, 0x14, 0x22 }, // 146
    .{ 0x22, 0x14, 0x2A, 0x14, 0x08 }, // 147
    .{ 0x7F, 0x08, 0x08, 0x08, 0x08 }, // 148
    .{ 0x00, 0x00, 0xF8, 0x00, 0x00 }, // 149
    .{ 0x00, 0xE8, 0xA8, 0xB8, 0x00 }, // 150
    .{ 0x00, 0x1D, 0x15, 0x17, 0x00 }, // 151
    .{ 0x00, 0x15, 0x15, 0x1F, 0x00 }, // 152
    .{ 0x00, 0x00, 0x68, 0x80, 0x00 }, // 153
    .{ 0x00, 0x80, 0x80, 0x74, 0x00 }, // 154
    .{ 0x60, 0x60, 0x00, 0x60, 0x60 }, // 155
    .{ 0x00, 0x00, 0x0D, 0x10, 0x00 }, // 156
    .{ 0x00, 0x10, 0x10, 0x0D, 0x00 }, // 157
    .{ 0x00, 0x1F, 0x04, 0x0A, 0x10 }, // 158
    .{ 0x00, 0x1E, 0x02, 0x02, 0x1C }, // 159
    .{ 0x60, 0x50, 0x58, 0x64, 0x42 }, // 160
    .{ 0x78, 0x15, 0x16, 0x14, 0x78 }, // 161
    .{ 0x78, 0x16, 0x15, 0x16, 0x78 }, // 162
    .{ 0x7C, 0x55, 0x56, 0x54, 0x44 }, // 163
    .{ 0x7C, 0x56, 0x55, 0x56, 0x44 }, // 164
    .{ 0x7C, 0x55, 0x54, 0x55, 0x44 }, // 165
    .{ 0x00, 0x46, 0x7D, 0x46, 0x00 }, // 166
    .{ 0x00, 0x45, 0x7C, 0x45, 0x00 }, // 167
    .{ 0x00, 0x00, 0x02, 0x01, 0x00 }, // 168
    .{ 0x00, 0x01, 0x02, 0x00, 0x00 }, // 169
    .{ 0x00, 0x02, 0x01, 0x02, 0x00 }, // 170
    .{ 0x00, 0x01, 0x00, 0x01, 0x00 }, // 171
    .{ 0x02, 0x01, 0x02, 0x04, 0x02 }, // 172
    .{ 0x3C, 0x41, 0x42, 0x40, 0x3C }, // 173
    .{ 0x38, 0x42, 0x41, 0x42, 0x38 }, // 174
    .{ 0x58, 0x7E, 0x59, 0x41, 0x02 }, // 175
    .{ 0x01, 0x01, 0x01, 0x01, 0x01 }, // 176
    .{ 0x04, 0x08, 0x72, 0x09, 0x04 }, // 177
    .{ 0x18, 0xA0, 0xA2, 0xA1, 0x78 }, // 178
    .{ 0x00, 0x07, 0x05, 0x07, 0x00 }, // 179
    .{ 0x1E, 0xA1, 0xA1, 0x61, 0x12 }, // 180
    .{ 0x18, 0xA4, 0xA4, 0x64, 0x24 }, // 181
    .{ 0x7C, 0x0A, 0x11, 0x22, 0x7D }, // 182
    .{ 0x78, 0x0A, 0x09, 0x0A, 0x71 }, // 183
    .{ 0x00, 0x00, 0x7D, 0x00, 0x00 }, // 184
    .{ 0x30, 0x48, 0x45, 0x40, 0x20 }, // 185
    .{ 0x5D, 0x22, 0x22, 0x22, 0x5D }, // 186
    .{ 0x48, 0x7E, 0x49, 0x41, 0x02 }, // 187
    .{ 0x2B, 0x2C, 0x78, 0x2C, 0x2B }, // 188
    .{ 0x08, 0x56, 0x55, 0x35, 0x08 }, // 189
    .{ 0x40, 0x48, 0x3E, 0x09, 0x01 }, // 190
    .{ 0x18, 0x24, 0x7E, 0x24, 0x24 }, // 191
    .{ 0x20, 0x56, 0x55, 0x56, 0x78 }, // 192
    .{ 0x38, 0x56, 0x55, 0x56, 0x18 }, // 193
    .{ 0x30, 0x4A, 0x49, 0x4A, 0x30 }, // 194
    .{ 0x38, 0x42, 0x41, 0x42, 0x78 }, // 195
    .{ 0x20, 0x54, 0x56, 0x55, 0x78 }, // 196
    .{ 0x38, 0x54, 0x56, 0x55, 0x18 }, // 197
    .{ 0x30, 0x48, 0x4A, 0x49, 0x30 }, // 198
    .{ 0x38, 0x40, 0x42, 0x41, 0x78 }, // 199
    .{ 0x20, 0x55, 0x56, 0x54, 0x78 }, // 200
    .{ 0x38, 0x55, 0x56, 0x54, 0x18 }, // 201
    .{ 0x30, 0x49, 0x4A, 0x48, 0x30 }, // 202
    .{ 0x38, 0x41, 0x42, 0x40, 0x78 }, // 203
    .{ 0x20, 0x55, 0x54, 0x55, 0x78 }, // 204
    .{ 0x38, 0x55, 0x54, 0x55, 0x18 }, // 205
    .{ 0x30, 0x49, 0x48, 0x49, 0x30 }, // 206
    .{ 0x38, 0x41, 0x40, 0x41, 0x78 }, // 207
    .{ 0x78, 0x17, 0x15, 0x17, 0x78 }, // 208
    .{ 0x00, 0x4A, 0x79, 0x42, 0x00 }, // 209
    .{ 0x5C, 0x32, 0x2A, 0x26, 0x1D }, // 210
    .{ 0x7E, 0x09, 0x7E, 0x49, 0x49 }, // 211
    .{ 0x20, 0x57, 0x55, 0x57, 0x78 }, // 212
    .{ 0x00, 0x48, 0x7A, 0x41, 0x00 }, // 213
    .{ 0x58, 0x24, 0x54, 0x48, 0x34 }, // 214
    .{ 0x74, 0x54, 0x7C, 0x54, 0x5C }, // 215
    .{ 0x78, 0x15, 0x14, 0x15, 0x78 }, // 216
    .{ 0x00, 0x49, 0x7A, 0x40, 0x00 }, // 217
    .{ 0x38, 0x45, 0x44, 0x45, 0x38 }, // 218
    .{ 0x3C, 0x41, 0x40, 0x41, 0x3C }, // 219
    .{ 0x7C, 0x54, 0x56, 0x55, 0x44 }, // 220
    .{ 0x00, 0x49, 0x78, 0x41, 0x00 }, // 221
    .{ 0xFE, 0x25, 0x25, 0x25, 0x1A }, // 222
    .{ 0x38, 0x46, 0x45, 0x46, 0x38 }, // 223
    .{ 0x78, 0x14, 0x16, 0x15, 0x78 }, // 224
    .{ 0x7A, 0x15, 0x16, 0x15, 0x78 }, // 225
    .{ 0x22, 0x55, 0x56, 0x55, 0x78 }, // 226
    .{ 0x08, 0x7F, 0x49, 0x22, 0x1C }, // 227
    .{ 0x30, 0x48, 0x4A, 0x3F, 0x02 }, // 228
    .{ 0x00, 0x44, 0x7E, 0x45, 0x00 }, // 229
    .{ 0x00, 0x45, 0x7E, 0x44, 0x00 }, // 230
    .{ 0x38, 0x44, 0x46, 0x45, 0x38 }, // 231
    .{ 0x38, 0x45, 0x46, 0x44, 0x38 }, // 232
    .{ 0x3A, 0x45, 0x46, 0x45, 0x38 }, // 233
    .{ 0x30, 0x4A, 0x49, 0x4A, 0x31 }, // 234
    .{ 0x48, 0x55, 0x56, 0x55, 0x24 }, // 235
    .{ 0x40, 0x51, 0x2A, 0x09, 0x00 }, // 236
    .{ 0x3C, 0x40, 0x42, 0x41, 0x3C }, // 237
    .{ 0x04, 0x09, 0x70, 0x09, 0x04 }, // 238
    .{ 0x18, 0xA1, 0xA0, 0xA1, 0x78 }, // 239
    .{ 0x41, 0x7F, 0x55, 0x14, 0x08 }, // 240
    .{ 0x00, 0xFE, 0x24, 0x24, 0x18 }, // 241
    .{ 0x00, 0x18, 0x18, 0x00, 0x00 }, // 242
    .{ 0x7C, 0x20, 0x20, 0x1C, 0x20 }, // 243
    .{ 0x06, 0x4F, 0x7F, 0x01, 0x7F }, // 244
    .{ 0x15, 0x1F, 0x38, 0x24, 0x72 }, // 245
    .{ 0x04, 0x04, 0x04, 0x04, 0x04 }, // 246
    .{ 0x17, 0x08, 0x34, 0x22, 0x70 }, // 247
    .{ 0x17, 0x08, 0x04, 0x6A, 0x58 }, // 248
    .{ 0x00, 0x28, 0x35, 0x35, 0x2E }, // 249
    .{ 0x26, 0x29, 0x29, 0x29, 0x26 }, // 250
    .{ 0x08, 0x14, 0x2A, 0x14, 0x22 }, // 251
    .{ 0x7F, 0x7F, 0x7F, 0x7F, 0x7F }, // 252
    .{ 0x22, 0x14, 0x2A, 0x14, 0x08 }, // 253
    .{ 0x00, 0x24, 0x2E, 0x24, 0x00 }, // 254
    .{ 0x00, 0x00, 0x00, 0x00, 0x00 }, // 255
};

const CairoContext = opaque {};
const CairoSurface = opaque {};
const CairoPattern = opaque {};
const GtkAdjustment = opaque {};
const GtkClipboard = opaque {};
const GdkPixbuf = opaque {};

// The leading fields of GdkEventKey, as far as keyval: the handler reads the
// event through GTK's pointer and never copies it.
const GdkEventKey = extern struct {
    type: c_int,
    window: ?*anyopaque,
    send_event: i8,
    time: u32,
    state: c_uint,
    keyval: c_uint,
};

const GTK_WINDOW_TOPLEVEL: c_int = 0;
const GTK_ORIENTATION_HORIZONTAL: c_int = 0;
const GTK_ORIENTATION_VERTICAL: c_int = 1;
const GTK_POLICY_AUTOMATIC: c_int = 1;
const GTK_POLICY_NEVER: c_int = 2;
const CAIRO_FORMAT_RGB24: c_int = 1;
const CAIRO_FILTER_NEAREST: c_int = 3;
const GDK_CONTROL_MASK: c_uint = 1 << 2;
const G_SOURCE_REMOVE: c_int = 0;
const TRUE: c_int = 1;
const FALSE: c_int = 0;

const GDK_KEY_A: c_uint = 0x041;
const GDK_KEY_C: c_uint = 0x043;
const GDK_KEY_I: c_uint = 0x049;
const GDK_KEY_L: c_uint = 0x04c;
const GDK_KEY_P: c_uint = 0x050;
const GDK_KEY_W: c_uint = 0x057;
const GDK_KEY_a: c_uint = 0x061;
const GDK_KEY_c: c_uint = 0x063;
const GDK_KEY_i: c_uint = 0x069;
const GDK_KEY_l: c_uint = 0x06c;
const GDK_KEY_p: c_uint = 0x070;
const GDK_KEY_w: c_uint = 0x077;
const GDK_KEY_Escape: c_uint = 0xff1b;
const GDK_KEY_Home: c_uint = 0xff50;
const GDK_KEY_Up: c_uint = 0xff52;
const GDK_KEY_Down: c_uint = 0xff54;
const GDK_KEY_Page_Up: c_uint = 0xff55;
const GDK_KEY_Page_Down: c_uint = 0xff56;
const GDK_KEY_End: c_uint = 0xff57;
const GDK_KEY_KP_Home: c_uint = 0xff95;
const GDK_KEY_KP_Up: c_uint = 0xff97;
const GDK_KEY_KP_Down: c_uint = 0xff99;
const GDK_KEY_KP_Page_Up: c_uint = 0xff9a;
const GDK_KEY_KP_Page_Down: c_uint = 0xff9b;
const GDK_KEY_KP_End: c_uint = 0xff9c;

// GDK_SELECTION_CLIPBOARD = _GDK_MAKE_ATOM(69) = GUINT_TO_POINTER(69).
const GDK_SELECTION_CLIPBOARD: ?*anyopaque = @ptrFromInt(69);

const SourceFn = *const fn (?*anyopaque) callconv(.c) c_int;

// print.zig's HP 82240 Roman-8 to Unicode table.
extern const hp82240CharMap: [256]u16;
extern var frmCalc: ?*GtkWidget;
// gtkGui.c's onUIActivity: keeps _lcdSBRefresh() from running the main loop
// while a window is moved, resized or focused.
extern fn z47_onUIActivity(widget: ?*anyopaque, event: ?*anyopaque, data: ?*anyopaque) c_int;

extern fn gtk_window_get_size(window: ?*GtkWidget, width: *c_int, height: *c_int) void;
extern fn gtk_window_get_position(window: ?*GtkWidget, x: *c_int, y: *c_int) void;
extern fn gtk_window_move(window: ?*GtkWidget, x: c_int, y: c_int) void;
extern fn gtk_window_resize(window: ?*GtkWidget, width: c_int, height: c_int) void;
extern fn gtk_window_present(window: ?*GtkWidget) void;
extern fn gtk_window_present_with_time(window: ?*GtkWidget, timestamp: u32) void;
extern fn gtk_get_current_event_time() u32;
extern fn gtk_widget_hide(widget: ?*GtkWidget) void;
extern fn gtk_widget_show_all(widget: ?*GtkWidget) void;
extern fn gtk_widget_get_visible(widget: ?*GtkWidget) c_int;
extern fn gtk_widget_queue_draw(widget: ?*GtkWidget) void;
extern fn gtk_widget_get_allocated_width(widget: ?*GtkWidget) c_int;
extern fn gtk_box_new(orientation: c_int, spacing: c_int) ?*GtkWidget;
extern fn gtk_box_pack_start(box: ?*GtkWidget, child: ?*GtkWidget, expand: c_int, fill: c_int, padding: c_uint) void;
extern fn gtk_container_set_border_width(container: ?*GtkWidget, border_width: c_uint) void;
extern fn gtk_button_new_with_label(label: [*:0]const u8) ?*GtkWidget;
extern fn gtk_scrolled_window_new(hadjustment: ?*GtkAdjustment, vadjustment: ?*GtkAdjustment) ?*GtkWidget;
extern fn gtk_scrolled_window_set_policy(scrolled_window: ?*GtkWidget, hscrollbar_policy: c_int, vscrollbar_policy: c_int) void;
extern fn gtk_scrolled_window_get_vadjustment(scrolled_window: ?*GtkWidget) ?*GtkAdjustment;
extern fn gtk_adjustment_get_value(adjustment: ?*GtkAdjustment) f64;
extern fn gtk_adjustment_set_value(adjustment: ?*GtkAdjustment, value: f64) void;
extern fn gtk_adjustment_get_upper(adjustment: ?*GtkAdjustment) f64;
extern fn gtk_adjustment_get_page_size(adjustment: ?*GtkAdjustment) f64;
extern fn gtk_clipboard_get(selection: ?*anyopaque) ?*GtkClipboard;
extern fn gtk_clipboard_set_text(clipboard: ?*GtkClipboard, text: [*]const u8, len: c_int) void;
extern fn gtk_clipboard_set_image(clipboard: ?*GtkClipboard, pixbuf: *GdkPixbuf) void;
extern fn gdk_pixbuf_get_from_surface(surface: ?*CairoSurface, src_x: c_int, src_y: c_int, width: c_int, height: c_int) ?*GdkPixbuf;
extern fn g_object_unref(object: *anyopaque) void;
extern fn g_timeout_add(interval: c_uint, function: SourceFn, data: ?*anyopaque) c_uint;
extern fn g_idle_add(function: SourceFn, data: ?*anyopaque) c_uint;
extern fn cairo_create(target: ?*CairoSurface) ?*CairoContext;
extern fn cairo_destroy(cr: ?*CairoContext) void;
extern fn cairo_save(cr: ?*CairoContext) void;
extern fn cairo_restore(cr: ?*CairoContext) void;
extern fn cairo_translate(cr: ?*CairoContext, tx: f64, ty: f64) void;
extern fn cairo_scale(cr: ?*CairoContext, sx: f64, sy: f64) void;
extern fn cairo_set_source_rgb(cr: ?*CairoContext, red: f64, green: f64, blue: f64) void;
extern fn cairo_set_source_surface(cr: ?*CairoContext, surface: ?*CairoSurface, x: f64, y: f64) void;
extern fn cairo_get_source(cr: ?*CairoContext) ?*CairoPattern;
extern fn cairo_pattern_set_filter(pattern: ?*CairoPattern, filter: c_int) void;
extern fn cairo_paint(cr: ?*CairoContext) void;
extern fn cairo_clip_extents(cr: ?*CairoContext, x1: *f64, y1: *f64, x2: *f64, y2: *f64) void;
extern fn cairo_image_surface_create(format: c_int, width: c_int, height: c_int) ?*CairoSurface;
extern fn cairo_image_surface_get_data(surface: ?*CairoSurface) ?[*]u8;
extern fn cairo_image_surface_get_stride(surface: ?*CairoSurface) c_int;
extern fn cairo_image_surface_get_width(surface: ?*CairoSurface) c_int;
extern fn cairo_image_surface_get_height(surface: ?*CairoSurface) c_int;
extern fn cairo_surface_flush(surface: ?*CairoSurface) void;
extern fn cairo_surface_mark_dirty(surface: ?*CairoSurface) void;
extern fn cairo_surface_destroy(surface: ?*CairoSurface) void;

const gpa = std.heap.c_allocator;

var lines: std.ArrayList(Line) = .empty; // print-out bitmap, one entry per paper line; the last is the line being printed
var column: u8 = 0; // next dot column on the current line
var text: std.ArrayList(u8) = .empty; // UTF-8 characters of the print-out, graphic data excluded
var esc_pending = false;
var graphic_length: u8 = 0; // graphic bytes still to come after ESC n
var expanded = false;
var underlined = false;

var window: ?*GtkWidget = null;
var drawing: ?*GtkWidget = null;
var scrolled: ?*GtkWidget = null;
var scale: i32 = default_scale; // screen pixels per printer dot, follows the window width
var update_id: c_uint = 0; // pending window update, 0 when none
var scroll_pending = false;
// x, y: offset from the calculator window; width, height: size. Width is 0
// until the window was shown.
var geometry: GdkRectangle = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
var restore_pending = false; // true from a show until the saved size is applied again

fn lineCount() i32 {
    return @intCast(lines.items.len);
}

fn newLine() void {
    if (lines.items.len == max_lines) {
        _ = lines.orderedRemove(0);
    }
    if (lines.items.len == lines.capacity) {
        const grown = if (lines.capacity == 0) first_line_alloc else @min(lines.capacity * 2, max_lines);
        lines.ensureTotalCapacityPrecise(gpa, grown) catch @panic("HP 82240B print-out: out of memory");
    }
    lines.appendAssumeCapacity(@splat(0));
    column = 0;
}

fn setColumn(dots: u8) void {
    if (column >= columns) {
        newLine();
    }
    lines.items[lines.items.len - 1][column] = dots;
    column += 1;
}

fn separatorColumns() void {
    if (column == 0) return;
    var i: u8 = if (expanded) 2 else 1;
    while (i > 0 and column < columns) : (i -= 1) {
        setColumn(if (underlined) 0x80 else 0x00);
    }
}

fn appendText(bytes: []const u8) void {
    text.appendSlice(gpa, bytes) catch {};
}

fn character(c: u8) void {
    separatorColumns();
    for (roman8_font[c - ' ']) |font_dots| {
        const dots = font_dots | @as(u8, if (underlined) 0x80 else 0x00);
        setColumn(dots);
        if (expanded) {
            setColumn(dots);
        }
    }
    separatorColumns();

    if (c < 0x80) {
        appendText(&.{c});
    } else if (hp82240CharMap[c] != 0) {
        var utf8: [4]u8 = undefined;
        const len = std.unicode.utf8Encode(hp82240CharMap[c], &utf8) catch return appendText("?");
        appendText(utf8[0..len]);
    } else {
        appendText("?");
    }
}

fn init() void {
    if (lines.items.len == 0) {
        newLine();
    }
}

fn scrollToBottom(data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    if (scrolled != null) {
        const adj = gtk_scrolled_window_get_vadjustment(scrolled);
        gtk_adjustment_set_value(adj, gtk_adjustment_get_upper(adj) - gtk_adjustment_get_page_size(adj));
    }
    return G_SOURCE_REMOVE;
}

fn update(data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    update_id = 0;
    if (drawing != null) {
        gtk_widget_set_size_request(drawing, columns + 2 * margin, lineCount() * rows * scale + 2 * margin);
        gtk_widget_queue_draw(drawing);
        if (scroll_pending) {
            scroll_pending = false;
            _ = g_idle_add(scrollToBottom, null); // after the layout has applied the new height
        }
    }
    return G_SOURCE_REMOVE;
}

// Schedules one window update; bytes arriving before it fires share it.
fn scheduleUpdate(scroll: bool) void {
    if (drawing == null) return;
    scroll_pending = scroll_pending or scroll;
    if (update_id == 0) {
        update_id = g_timeout_add(100, update, null);
    }
}

// The IR printer output of the simulator (hal/print_ir.c's sendByteIR): every
// byte goes to the print-out window. Defined here rather than beside the other
// HAL stubs so the HAL object depends on nothing: the window belongs to the GUI
// object, which the core already calls.
pub export fn sendByteIR(c: u8) callconv(.c) void {
    printerWindowByte(c);
}

// Decodes one byte of the HP 82240 byte stream.
pub export fn printerWindowByte(c: u8) callconv(.c) void {
    if (comptime !ir_printing) return;
    init();

    if (esc_pending) {
        esc_pending = false;
        switch (c) {
            255 => { // reset
                expanded = false;
                underlined = false;
            },
            253 => expanded = true,
            252 => expanded = false,
            251 => underlined = true,
            250 => underlined = false,
            1...columns => graphic_length = c,
            else => {},
        }
        return;
    }

    if (graphic_length > 0) {
        graphic_length -= 1;
        setColumn(c);
        if (expanded) {
            setColumn(c);
        }
    } else if (c == esc) {
        esc_pending = true;
        return;
    } else if (c == 0x04 or c == '\n') {
        appendText("\n");
        newLine();
        scheduleUpdate(true);
        return;
    } else if (c >= ' ') {
        character(c);
    }

    scheduleUpdate(false);
}

// Paints lines first to last - 1 with their top left dot at x, y, dot_scale
// screen pixels per dot. The dots are written to an image of one pixel per dot,
// which one paint enlarges without smoothing.
fn paintLines(cr: ?*CairoContext, first: i32, last: i32, x: f64, y: f64, dot_scale: i32) void {
    if (last <= first) return;

    const surface = cairo_image_surface_create(CAIRO_FORMAT_RGB24, columns, (last - first) * rows);
    defer cairo_surface_destroy(surface);
    cairo_surface_flush(surface);
    // A print-out taller than cairo's largest image gives an error surface,
    // which has no data to write.
    const data = cairo_image_surface_get_data(surface) orelse return;
    const stride: usize = @intCast(cairo_image_surface_get_stride(surface));
    const first_line: usize = @intCast(first);
    const last_line: usize = @intCast(last);
    for (lines.items[first_line..last_line], 0..) |*line, line_offset| {
        for (0..rows) |row| {
            const pixels: [*]u32 = @ptrCast(@alignCast(data + (line_offset * rows + row) * stride));
            const bit: u3 = @intCast(row);
            for (line, 0..) |dots, col| {
                pixels[col] = if (((dots >> bit) & 0x01) != 0) 0x000000 else 0xFFFFFF;
            }
        }
    }
    cairo_surface_mark_dirty(surface);

    cairo_save(cr);
    cairo_translate(cr, x, y);
    cairo_scale(cr, @floatFromInt(dot_scale), @floatFromInt(dot_scale));
    cairo_set_source_surface(cr, surface, 0, 0);
    cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_NEAREST);
    cairo_paint(cr);
    cairo_restore(cr);
}

fn createImage() ?*CairoSurface {
    const width = columns * scale + 2 * margin;
    const height = lineCount() * rows * scale + 2 * margin;
    const surface = cairo_image_surface_create(CAIRO_FORMAT_RGB24, width, height);
    const cr = cairo_create(surface);

    cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
    cairo_paint(cr);
    paintLines(cr, 0, lineCount(), margin, margin, scale);
    cairo_destroy(cr);
    return surface;
}

fn draw(widget: ?*GtkWidget, cr: ?*CairoContext, data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    var x1: f64 = 0;
    var y1: f64 = 0;
    var x2: f64 = 0;
    var y2: f64 = 0;
    const line_height = rows * scale;
    const allocated_width: i32 = gtk_widget_get_allocated_width(widget);
    const left = @divTrunc(allocated_width - columns * scale, 2); // the paper is centred in the window

    cairo_clip_extents(cr, &x1, &y1, &x2, &y2);
    cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
    cairo_paint(cr);

    const first_line = @max(@divTrunc(@as(i32, @trunc(y1)) - margin, line_height), 0);
    const last_line = @min(@divTrunc(@as(i32, @trunc(y2)) - margin, line_height) + 1, lineCount());
    paintLines(cr, first_line, last_line, @floatFromInt(left), @floatFromInt(margin + first_line * line_height), scale);
    return FALSE;
}

// The dot size is the largest whole number of screen pixels that fits the
// window width.
fn sizeAllocate(widget: ?*GtkWidget, allocation: *const GdkRectangle, data: ?*anyopaque) callconv(.c) void {
    _ = widget;
    _ = data;
    const width: i32 = allocation.width;
    const fitted = @max(@divTrunc(width - 2 * margin, columns), 1);
    if (fitted != scale) {
        scale = fitted;
        scheduleUpdate(false);
    }
}

fn clear(widget: ?*GtkWidget, data: ?*anyopaque) callconv(.c) void {
    _ = widget;
    _ = data;
    lines.clearRetainingCapacity();
    esc_pending = false;
    graphic_length = 0;
    text.clearRetainingCapacity();
    newLine();
    scheduleUpdate(false);
}

fn advance(widget: ?*GtkWidget, data: ?*anyopaque) callconv(.c) void {
    _ = widget;
    _ = data;
    printerWindowByte('\n');
}

fn copyText(widget: ?*GtkWidget, data: ?*anyopaque) callconv(.c) void {
    _ = widget;
    _ = data;
    const clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    gtk_clipboard_set_text(clipboard, text.items.ptr, @intCast(text.items.len));
}

fn copyImage(widget: ?*GtkWidget, data: ?*anyopaque) callconv(.c) void {
    _ = widget;
    _ = data;
    const clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
    const surface = createImage();
    defer cairo_surface_destroy(surface);
    const pixbuf = gdk_pixbuf_get_from_surface(surface, 0, 0, cairo_image_surface_get_width(surface), cairo_image_surface_get_height(surface)) orelse return;

    gtk_clipboard_set_image(clipboard, pixbuf);
    g_object_unref(pixbuf);
}

fn scrollBy(line_steps: f64, pages: f64) void {
    const adj = gtk_scrolled_window_get_vadjustment(scrolled);
    const line_pixels: f64 = @floatFromInt(rows * scale);
    gtk_adjustment_set_value(adj, gtk_adjustment_get_value(adj) + line_steps * line_pixels + pages * gtk_adjustment_get_page_size(adj));
}

// Keeps the offset from the calculator window and the size. On Wayland GTK
// returns 0 for both positions, so the offset is 0 and the window manager places
// the window.
fn saveGeometry() void {
    var calc_x: c_int = 0;
    var calc_y: c_int = 0;

    gtk_window_get_position(frmCalc, &calc_x, &calc_y);
    gtk_window_get_position(window, &geometry.x, &geometry.y);
    geometry.x -= calc_x;
    geometry.y -= calc_y;
    gtk_window_get_size(window, &geometry.width, &geometry.height);
}

// Hides the window, keeps its offset and size for the next show, and hands the
// keyboard focus back to the calculator window. The time of the event that
// hides the window lets the window manager accept the focus change.
fn hide(widget: ?*GtkWidget, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = widget;
    _ = event;
    _ = data;
    saveGeometry();
    gtk_widget_hide(window);
    gtk_window_present_with_time(frmCalc, gtk_get_current_event_time());
    return TRUE;
}

// Records the position and size the window manager reports, so a hide keeps the
// size the user last gave the window.
fn configure(widget: ?*GtkWidget, event: ?*anyopaque, data: ?*anyopaque) callconv(.c) c_int {
    _ = widget;
    _ = event;
    _ = data;
    if (gtk_widget_get_visible(window) != 0 and !restore_pending) {
        saveGeometry();
    }
    return FALSE;
}

// Applies the saved size once the window is shown. A window manager may
// configure a window that is shown again with its first size, KWin on Wayland
// does, and only a resize after that configure keeps the size the user gave the
// window.
fn restoreSize(data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    gtk_window_resize(window, geometry.width, geometry.height);
    restore_pending = false;
    return G_SOURCE_REMOVE;
}

fn keyPressed(widget: ?*GtkWidget, event: *const GdkEventKey, data: ?*anyopaque) callconv(.c) c_int {
    _ = data;
    if ((event.state & GDK_CONTROL_MASK) != 0) {
        switch (event.keyval) {
            GDK_KEY_a, GDK_KEY_A => advance(widget, null),
            GDK_KEY_c, GDK_KEY_C => copyText(widget, null),
            GDK_KEY_i, GDK_KEY_I => copyImage(widget, null),
            GDK_KEY_l, GDK_KEY_L => clear(widget, null),
            GDK_KEY_p, GDK_KEY_P, GDK_KEY_w, GDK_KEY_W => _ = hide(window, null, null),
            else => return FALSE,
        }
        return TRUE;
    }

    switch (event.keyval) {
        GDK_KEY_Up, GDK_KEY_KP_Up => scrollBy(-1, 0),
        GDK_KEY_Down, GDK_KEY_KP_Down => scrollBy(1, 0),
        GDK_KEY_Page_Up, GDK_KEY_KP_Page_Up => scrollBy(0, -1),
        GDK_KEY_Page_Down, GDK_KEY_KP_Page_Down => scrollBy(0, 1),
        GDK_KEY_Home, GDK_KEY_KP_Home => gtk_adjustment_set_value(gtk_scrolled_window_get_vadjustment(scrolled), 0),
        GDK_KEY_End, GDK_KEY_KP_End => _ = scrollToBottom(null),
        GDK_KEY_Escape => _ = hide(window, null, null),
        else => return FALSE,
    }
    return TRUE;
}

// g_signal_connect(): GTK calls every handler through a generic pointer.
fn connect(instance: ?*GtkWidget, signal: [*:0]const u8, handler: anytype) void {
    _ = g_signal_connect_data(instance, signal, @ptrCast(handler), null, null, 0);
}

fn addButton(buttons: ?*GtkWidget, label: [*:0]const u8, tooltip: [*:0]const u8, handler: *const fn (?*GtkWidget, ?*anyopaque) callconv(.c) void) void {
    const button = gtk_button_new_with_label(label);
    gtk_widget_set_tooltip_text(button, tooltip);
    connect(button, "clicked", handler);
    gtk_box_pack_start(buttons, button, FALSE, FALSE, 0);
}

fn createWindow() void {
    var calc_width: c_int = 0;
    var calc_height: c_int = 0;

    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(window, "HP 82240B print-out");
    gtk_window_get_size(frmCalc, &calc_width, &calc_height);
    gtk_window_set_default_size(window, columns * default_scale + 2 * margin + 24, calc_height); // as high as the calculator window
    connect(window, "delete-event", &hide);
    connect(window, "key-press-event", &keyPressed);
    connect(window, "configure-event", &configure);
    // The guard the calculator window has against a main loop run while Windows
    // moves or resizes it.
    connect(window, "configure-event", &z47_onUIActivity);
    connect(window, "button-press-event", &z47_onUIActivity);
    connect(window, "focus-in-event", &z47_onUIActivity);
    connect(window, "focus-out-event", &z47_onUIActivity);

    const box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_container_add(window, box);

    const buttons = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
    gtk_container_set_border_width(buttons, 4);
    gtk_box_pack_start(box, buttons, FALSE, FALSE, 0);

    addButton(buttons, "Advance", "Advance the paper by one line (Ctrl+A)", &advance);
    addButton(buttons, "Clear", "Clear the print-out (Ctrl+L)", &clear);
    addButton(buttons, "Copy text", "Copy the printed characters to the clipboard (Ctrl+C). Glyphs sent as graphic data are not included.", &copyText);
    addButton(buttons, "Copy image", "Copy the print-out to the clipboard as image (Ctrl+I)", &copyImage);

    scrolled = gtk_scrolled_window_new(null, null);
    gtk_scrolled_window_set_policy(scrolled, GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
    gtk_box_pack_start(box, scrolled, TRUE, TRUE, 0);

    drawing = gtk_drawing_area_new();
    connect(drawing, "draw", &draw);
    connect(drawing, "size-allocate", &sizeAllocate);
    gtk_container_add(scrolled, drawing);
    scheduleUpdate(true);
}

// Shows the print-out window, or hides it when it is shown; Ctrl+P on the
// simulator.
pub export fn printerWindowToggle() callconv(.c) void {
    if (comptime !ir_printing) return;
    var calc_x: c_int = 0;
    var calc_y: c_int = 0;

    init();
    if (window == null) {
        createWindow();
    } else if (gtk_widget_get_visible(window) != 0) {
        _ = hide(window, null, null);
        return;
    }
    gtk_window_get_position(frmCalc, &calc_x, &calc_y);
    if (geometry.width > 0) {
        gtk_window_move(window, calc_x + geometry.x, calc_y + geometry.y);
        gtk_window_set_default_size(window, geometry.width, geometry.height);
        gtk_window_resize(window, geometry.width, geometry.height);
        restore_pending = true;
        _ = g_timeout_add(100, restoreSize, null);
    } else {
        var calc_width: c_int = 0;
        var calc_height: c_int = 0;
        gtk_window_get_size(frmCalc, &calc_width, &calc_height);
        gtk_window_move(window, calc_x + calc_width + margin, calc_y); // first show: to the right of the calculator window
    }
    gtk_widget_show_all(window);
    gtk_window_present(window);
    scheduleUpdate(true);
}
