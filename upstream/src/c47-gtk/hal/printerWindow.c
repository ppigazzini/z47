// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors
// SPDX-FileCopyrightText: Copyright (c) 2017 Christoph Giesselink (HP82240B Roman-8 font table, GPL-2.0-or-later)

#include "c47.h"
#include "c47-gtk.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

/*
*  Built-in HP 82240B print-out window of the simulator.
*  sendByteIR() hands every byte to printerWindowByte(), which decodes the HP 82240 byte stream into a bitmap of 166 dot columns by 8 dot rows per line.
*  Ctrl+P opens the window. The window offers advancing the paper, clearing the print-out and copying it to the clipboard as text or as image.
*/

#define PRT_COLUMNS 166      // dot columns per line of the HP 82240
#define PRT_ROWS 8           // dot rows per line, bit 0 is the top row
#define PRT_MAX_LINES 20000  // lines kept before the oldest is discarded
#define PRT_SCALE 2          // screen pixels per printer dot at the default window width
#define PRT_MARGIN 8         // screen pixels of white paper around the print-out
#define PRT_ESC 27

#if defined(OPTION_IR_PRINTING)

// HP 82240B Roman-8 font, codes 32 to 255, 5 dot columns per character, bit 0 is the top row.
// Taken from GraphFont.cpp of the HP82240B printer simulator by Christoph Giesselink.
// clang-format off
static const uint8_t roman8Font[224][5] = {
  {0x00, 0x00, 0x00, 0x00, 0x00},  // 32
  {0x00, 0x00, 0x5F, 0x00, 0x00},  // 33
  {0x00, 0x07, 0x00, 0x07, 0x00},  // 34
  {0x14, 0x7F, 0x14, 0x7F, 0x14},  // 35
  {0x24, 0x2A, 0x7F, 0x2A, 0x12},  // 36
  {0x23, 0x13, 0x08, 0x64, 0x62},  // 37
  {0x36, 0x49, 0x56, 0x20, 0x50},  // 38
  {0x00, 0x00, 0x07, 0x00, 0x00},  // 39
  {0x00, 0x1C, 0x22, 0x41, 0x00},  // 40
  {0x00, 0x41, 0x22, 0x1C, 0x00},  // 41
  {0x08, 0x2A, 0x1C, 0x2A, 0x08},  // 42
  {0x08, 0x08, 0x3E, 0x08, 0x08},  // 43
  {0x00, 0xB0, 0x70, 0x00, 0x00},  // 44
  {0x08, 0x08, 0x08, 0x08, 0x08},  // 45
  {0x00, 0x60, 0x60, 0x00, 0x00},  // 46
  {0x20, 0x10, 0x08, 0x04, 0x02},  // 47
  {0x3C, 0x62, 0x52, 0x4A, 0x3C},  // 48
  {0x00, 0x44, 0x7E, 0x40, 0x00},  // 49
  {0x64, 0x52, 0x4A, 0x4A, 0x44},  // 50
  {0x24, 0x42, 0x4A, 0x4A, 0x34},  // 51
  {0x10, 0x18, 0x14, 0x7E, 0x10},  // 52
  {0x2E, 0x4A, 0x4A, 0x4A, 0x32},  // 53
  {0x38, 0x54, 0x52, 0x52, 0x20},  // 54
  {0x02, 0x62, 0x12, 0x0A, 0x06},  // 55
  {0x34, 0x4A, 0x4A, 0x4A, 0x34},  // 56
  {0x04, 0x4A, 0x4A, 0x2A, 0x1C},  // 57
  {0x00, 0x36, 0x36, 0x00, 0x00},  // 58
  {0x00, 0xB6, 0x76, 0x00, 0x00},  // 59
  {0x08, 0x14, 0x22, 0x41, 0x00},  // 60
  {0x14, 0x14, 0x14, 0x14, 0x14},  // 61
  {0x41, 0x22, 0x14, 0x08, 0x00},  // 62
  {0x02, 0x01, 0x51, 0x09, 0x06},  // 63
  {0x3E, 0x41, 0x5D, 0x49, 0x4E},  // 64
  {0x7C, 0x12, 0x12, 0x12, 0x7C},  // 65
  {0x7E, 0x4A, 0x4A, 0x4A, 0x34},  // 66
  {0x3C, 0x42, 0x42, 0x42, 0x24},  // 67
  {0x7E, 0x42, 0x42, 0x24, 0x18},  // 68
  {0x7E, 0x4A, 0x4A, 0x4A, 0x42},  // 69
  {0x7E, 0x0A, 0x0A, 0x0A, 0x02},  // 70
  {0x3C, 0x42, 0x42, 0x52, 0x74},  // 71
  {0x7E, 0x08, 0x08, 0x08, 0x7E},  // 72
  {0x00, 0x42, 0x7E, 0x42, 0x00},  // 73
  {0x20, 0x40, 0x40, 0x40, 0x3E},  // 74
  {0x7E, 0x08, 0x14, 0x22, 0x40},  // 75
  {0x7E, 0x40, 0x40, 0x40, 0x40},  // 76
  {0x7E, 0x04, 0x18, 0x04, 0x7E},  // 77
  {0x7E, 0x04, 0x08, 0x10, 0x7E},  // 78
  {0x3C, 0x42, 0x42, 0x42, 0x3C},  // 79
  {0x7E, 0x12, 0x12, 0x12, 0x0C},  // 80
  {0x3C, 0x42, 0x52, 0x22, 0x5C},  // 81
  {0x7E, 0x12, 0x12, 0x32, 0x4C},  // 82
  {0x24, 0x4A, 0x4A, 0x4A, 0x30},  // 83
  {0x02, 0x02, 0x7E, 0x02, 0x02},  // 84
  {0x3E, 0x40, 0x40, 0x40, 0x3E},  // 85
  {0x0E, 0x30, 0x40, 0x30, 0x0E},  // 86
  {0x7E, 0x20, 0x18, 0x20, 0x7E},  // 87
  {0x42, 0x24, 0x18, 0x24, 0x42},  // 88
  {0x06, 0x08, 0x70, 0x08, 0x06},  // 89
  {0x62, 0x52, 0x4A, 0x46, 0x42},  // 90
  {0x00, 0x7F, 0x41, 0x41, 0x00},  // 91
  {0x02, 0x04, 0x08, 0x10, 0x20},  // 92
  {0x00, 0x41, 0x41, 0x7F, 0x00},  // 93
  {0x04, 0x02, 0x01, 0x02, 0x04},  // 94
  {0x80, 0x80, 0x80, 0x80, 0x80},  // 95
  {0x00, 0x03, 0x04, 0x00, 0x00},  // 96
  {0x20, 0x54, 0x54, 0x54, 0x78},  // 97
  {0x7F, 0x44, 0x44, 0x44, 0x38},  // 98
  {0x38, 0x44, 0x44, 0x44, 0x44},  // 99
  {0x38, 0x44, 0x44, 0x44, 0x7F},  // 100
  {0x38, 0x54, 0x54, 0x54, 0x18},  // 101
  {0x08, 0x7E, 0x09, 0x02, 0x00},  // 102
  {0x18, 0xA4, 0xA4, 0xA4, 0x78},  // 103
  {0x7F, 0x04, 0x04, 0x04, 0x78},  // 104
  {0x00, 0x44, 0x7D, 0x40, 0x00},  // 105
  {0x40, 0x80, 0x84, 0x7D, 0x00},  // 106
  {0x7F, 0x10, 0x28, 0x44, 0x00},  // 107
  {0x00, 0x41, 0x7F, 0x40, 0x00},  // 108
  {0x7C, 0x04, 0x38, 0x04, 0x78},  // 109
  {0x7C, 0x04, 0x04, 0x04, 0x78},  // 110
  {0x38, 0x44, 0x44, 0x44, 0x38},  // 111
  {0xFC, 0x24, 0x24, 0x24, 0x18},  // 112
  {0x18, 0x24, 0x24, 0x24, 0xFC},  // 113
  {0x7C, 0x08, 0x04, 0x04, 0x04},  // 114
  {0x48, 0x54, 0x54, 0x54, 0x24},  // 115
  {0x04, 0x3F, 0x44, 0x20, 0x00},  // 116
  {0x3C, 0x40, 0x40, 0x40, 0x7C},  // 117
  {0x1C, 0x20, 0x40, 0x20, 0x1C},  // 118
  {0x3C, 0x40, 0x30, 0x40, 0x3C},  // 119
  {0x44, 0x28, 0x10, 0x28, 0x44},  // 120
  {0x1C, 0xA0, 0xA0, 0xA0, 0x7C},  // 121
  {0x44, 0x64, 0x54, 0x4C, 0x44},  // 122
  {0x08, 0x36, 0x41, 0x41, 0x00},  // 123
  {0x00, 0x00, 0x7F, 0x00, 0x00},  // 124
  {0x00, 0x41, 0x41, 0x36, 0x08},  // 125
  {0x08, 0x04, 0x08, 0x10, 0x08},  // 126
  {0x55, 0x2A, 0x55, 0x2A, 0x55},  // 127
  {0x00, 0x00, 0x00, 0x00, 0x00},  // 128
  {0x08, 0x08, 0x2A, 0x08, 0x08},  // 129
  {0x22, 0x14, 0x08, 0x14, 0x22},  // 130
  {0x10, 0x20, 0x7F, 0x01, 0x01},  // 131
  {0x20, 0x40, 0x3E, 0x01, 0x02},  // 132
  {0x41, 0x63, 0x55, 0x49, 0x63},  // 133
  {0x7F, 0x7F, 0x3E, 0x1C, 0x08},  // 134
  {0x04, 0x7C, 0x04, 0x7C, 0x04},  // 135
  {0x30, 0x49, 0x4A, 0x4C, 0x38},  // 136
  {0x50, 0x58, 0x54, 0x52, 0x51},  // 137
  {0x51, 0x52, 0x54, 0x58, 0x50},  // 138
  {0x14, 0x34, 0x1C, 0x16, 0x14},  // 139
  {0x30, 0x48, 0x48, 0x30, 0x48},  // 140
  {0x08, 0x08, 0x2A, 0x1C, 0x08},  // 141
  {0x08, 0x1C, 0x2A, 0x08, 0x08},  // 142
  {0x7C, 0x20, 0x20, 0x1C, 0x20},  // 143
  {0x0F, 0x08, 0x00, 0x78, 0x28},  // 144
  {0x00, 0x07, 0x05, 0x07, 0x00},  // 145
  {0x08, 0x14, 0x2A, 0x14, 0x22},  // 146
  {0x22, 0x14, 0x2A, 0x14, 0x08},  // 147
  {0x7F, 0x08, 0x08, 0x08, 0x08},  // 148
  {0x00, 0x00, 0xF8, 0x00, 0x00},  // 149
  {0x00, 0xE8, 0xA8, 0xB8, 0x00},  // 150
  {0x00, 0x1D, 0x15, 0x17, 0x00},  // 151
  {0x00, 0x15, 0x15, 0x1F, 0x00},  // 152
  {0x00, 0x00, 0x68, 0x80, 0x00},  // 153
  {0x00, 0x80, 0x80, 0x74, 0x00},  // 154
  {0x60, 0x60, 0x00, 0x60, 0x60},  // 155
  {0x00, 0x00, 0x0D, 0x10, 0x00},  // 156
  {0x00, 0x10, 0x10, 0x0D, 0x00},  // 157
  {0x00, 0x1F, 0x04, 0x0A, 0x10},  // 158
  {0x00, 0x1E, 0x02, 0x02, 0x1C},  // 159
  {0x60, 0x50, 0x58, 0x64, 0x42},  // 160
  {0x78, 0x15, 0x16, 0x14, 0x78},  // 161
  {0x78, 0x16, 0x15, 0x16, 0x78},  // 162
  {0x7C, 0x55, 0x56, 0x54, 0x44},  // 163
  {0x7C, 0x56, 0x55, 0x56, 0x44},  // 164
  {0x7C, 0x55, 0x54, 0x55, 0x44},  // 165
  {0x00, 0x46, 0x7D, 0x46, 0x00},  // 166
  {0x00, 0x45, 0x7C, 0x45, 0x00},  // 167
  {0x00, 0x00, 0x02, 0x01, 0x00},  // 168
  {0x00, 0x01, 0x02, 0x00, 0x00},  // 169
  {0x00, 0x02, 0x01, 0x02, 0x00},  // 170
  {0x00, 0x01, 0x00, 0x01, 0x00},  // 171
  {0x02, 0x01, 0x02, 0x04, 0x02},  // 172
  {0x3C, 0x41, 0x42, 0x40, 0x3C},  // 173
  {0x38, 0x42, 0x41, 0x42, 0x38},  // 174
  {0x58, 0x7E, 0x59, 0x41, 0x02},  // 175
  {0x01, 0x01, 0x01, 0x01, 0x01},  // 176
  {0x04, 0x08, 0x72, 0x09, 0x04},  // 177
  {0x18, 0xA0, 0xA2, 0xA1, 0x78},  // 178
  {0x00, 0x07, 0x05, 0x07, 0x00},  // 179
  {0x1E, 0xA1, 0xA1, 0x61, 0x12},  // 180
  {0x18, 0xA4, 0xA4, 0x64, 0x24},  // 181
  {0x7C, 0x0A, 0x11, 0x22, 0x7D},  // 182
  {0x78, 0x0A, 0x09, 0x0A, 0x71},  // 183
  {0x00, 0x00, 0x7D, 0x00, 0x00},  // 184
  {0x30, 0x48, 0x45, 0x40, 0x20},  // 185
  {0x5D, 0x22, 0x22, 0x22, 0x5D},  // 186
  {0x48, 0x7E, 0x49, 0x41, 0x02},  // 187
  {0x2B, 0x2C, 0x78, 0x2C, 0x2B},  // 188
  {0x08, 0x56, 0x55, 0x35, 0x08},  // 189
  {0x40, 0x48, 0x3E, 0x09, 0x01},  // 190
  {0x18, 0x24, 0x7E, 0x24, 0x24},  // 191
  {0x20, 0x56, 0x55, 0x56, 0x78},  // 192
  {0x38, 0x56, 0x55, 0x56, 0x18},  // 193
  {0x30, 0x4A, 0x49, 0x4A, 0x30},  // 194
  {0x38, 0x42, 0x41, 0x42, 0x78},  // 195
  {0x20, 0x54, 0x56, 0x55, 0x78},  // 196
  {0x38, 0x54, 0x56, 0x55, 0x18},  // 197
  {0x30, 0x48, 0x4A, 0x49, 0x30},  // 198
  {0x38, 0x40, 0x42, 0x41, 0x78},  // 199
  {0x20, 0x55, 0x56, 0x54, 0x78},  // 200
  {0x38, 0x55, 0x56, 0x54, 0x18},  // 201
  {0x30, 0x49, 0x4A, 0x48, 0x30},  // 202
  {0x38, 0x41, 0x42, 0x40, 0x78},  // 203
  {0x20, 0x55, 0x54, 0x55, 0x78},  // 204
  {0x38, 0x55, 0x54, 0x55, 0x18},  // 205
  {0x30, 0x49, 0x48, 0x49, 0x30},  // 206
  {0x38, 0x41, 0x40, 0x41, 0x78},  // 207
  {0x78, 0x17, 0x15, 0x17, 0x78},  // 208
  {0x00, 0x4A, 0x79, 0x42, 0x00},  // 209
  {0x5C, 0x32, 0x2A, 0x26, 0x1D},  // 210
  {0x7E, 0x09, 0x7E, 0x49, 0x49},  // 211
  {0x20, 0x57, 0x55, 0x57, 0x78},  // 212
  {0x00, 0x48, 0x7A, 0x41, 0x00},  // 213
  {0x58, 0x24, 0x54, 0x48, 0x34},  // 214
  {0x74, 0x54, 0x7C, 0x54, 0x5C},  // 215
  {0x78, 0x15, 0x14, 0x15, 0x78},  // 216
  {0x00, 0x49, 0x7A, 0x40, 0x00},  // 217
  {0x38, 0x45, 0x44, 0x45, 0x38},  // 218
  {0x3C, 0x41, 0x40, 0x41, 0x3C},  // 219
  {0x7C, 0x54, 0x56, 0x55, 0x44},  // 220
  {0x00, 0x49, 0x78, 0x41, 0x00},  // 221
  {0xFE, 0x25, 0x25, 0x25, 0x1A},  // 222
  {0x38, 0x46, 0x45, 0x46, 0x38},  // 223
  {0x78, 0x14, 0x16, 0x15, 0x78},  // 224
  {0x7A, 0x15, 0x16, 0x15, 0x78},  // 225
  {0x22, 0x55, 0x56, 0x55, 0x78},  // 226
  {0x08, 0x7F, 0x49, 0x22, 0x1C},  // 227
  {0x30, 0x48, 0x4A, 0x3F, 0x02},  // 228
  {0x00, 0x44, 0x7E, 0x45, 0x00},  // 229
  {0x00, 0x45, 0x7E, 0x44, 0x00},  // 230
  {0x38, 0x44, 0x46, 0x45, 0x38},  // 231
  {0x38, 0x45, 0x46, 0x44, 0x38},  // 232
  {0x3A, 0x45, 0x46, 0x45, 0x38},  // 233
  {0x30, 0x4A, 0x49, 0x4A, 0x31},  // 234
  {0x48, 0x55, 0x56, 0x55, 0x24},  // 235
  {0x40, 0x51, 0x2A, 0x09, 0x00},  // 236
  {0x3C, 0x40, 0x42, 0x41, 0x3C},  // 237
  {0x04, 0x09, 0x70, 0x09, 0x04},  // 238
  {0x18, 0xA1, 0xA0, 0xA1, 0x78},  // 239
  {0x41, 0x7F, 0x55, 0x14, 0x08},  // 240
  {0x00, 0xFE, 0x24, 0x24, 0x18},  // 241
  {0x00, 0x18, 0x18, 0x00, 0x00},  // 242
  {0x7C, 0x20, 0x20, 0x1C, 0x20},  // 243
  {0x06, 0x4F, 0x7F, 0x01, 0x7F},  // 244
  {0x15, 0x1F, 0x38, 0x24, 0x72},  // 245
  {0x04, 0x04, 0x04, 0x04, 0x04},  // 246
  {0x17, 0x08, 0x34, 0x22, 0x70},  // 247
  {0x17, 0x08, 0x04, 0x6A, 0x58},  // 248
  {0x00, 0x28, 0x35, 0x35, 0x2E},  // 249
  {0x26, 0x29, 0x29, 0x29, 0x26},  // 250
  {0x08, 0x14, 0x2A, 0x14, 0x22},  // 251
  {0x7F, 0x7F, 0x7F, 0x7F, 0x7F},  // 252
  {0x22, 0x14, 0x2A, 0x14, 0x08},  // 253
  {0x00, 0x24, 0x2E, 0x24, 0x00},  // 254
  {0x00, 0x00, 0x00, 0x00, 0x00}   // 255
};
// clang-format on

extern const uint16_t hp82240CharMap[256];

static uint8_t (*prtLines)[PRT_COLUMNS] = NULL;  // print-out bitmap, one entry per paper line
static int32_t prtLineCount = 0;                 // lines in use, the last one is the line being printed
static int32_t prtLineAlloc = 0;
static int16_t prtColumn = 0;    // next dot column on the current line
static GString *prtText = NULL;  // characters of the print-out, graphic data excluded
static bool prtEsc = false;
static uint8_t prtGraphicLength = 0;  // graphic bytes still to come after ESC n
static bool prtExpanded = false;
static bool prtUnderlined = false;

static GtkWidget *prtWindow = NULL;
static GtkWidget *prtDrawing = NULL;
static GtkWidget *prtScrolled = NULL;
static int32_t prtScale = PRT_SCALE;  // screen pixels per printer dot, follows the window width
static guint prtUpdateId = 0;         // pending window update, 0 when none
static bool prtScrollPending = false;
static GdkRectangle prtGeometry = {0, 0, 0, 0};  // x, y: offset from the calculator window; width, height: size; width 0 until the window was shown
static bool prtRestorePending = false;           // true from a show until the saved size is applied again

static void _prtNewLine(void) {
  if(prtLineCount == PRT_MAX_LINES) {
    memmove(prtLines[0], prtLines[1], (size_t)(PRT_MAX_LINES - 1) * PRT_COLUMNS);
    prtLineCount--;
  }
  if(prtLineCount == prtLineAlloc) {
    prtLineAlloc = (prtLineAlloc == 0 ? 256 : prtLineAlloc * 2);
    if(prtLineAlloc > PRT_MAX_LINES) {
      prtLineAlloc = PRT_MAX_LINES;
    }
    prtLines = realloc(prtLines, (size_t)prtLineAlloc * PRT_COLUMNS);
  }
  memset(prtLines[prtLineCount], 0, PRT_COLUMNS);
  prtLineCount++;
  prtColumn = 0;
}

static void _prtSetColumn(uint8_t dots) {
  if(prtColumn >= PRT_COLUMNS) {
    _prtNewLine();
  }
  prtLines[prtLineCount - 1][prtColumn++] = dots;
}

static void _prtSeparatorColumns(void) {
  if(prtColumn > 0) {
    for(int i = (prtExpanded ? 2 : 1); i > 0 && prtColumn < PRT_COLUMNS; i--) {
      _prtSetColumn(prtUnderlined ? 0x80 : 0x00);
    }
  }
}

static void _prtCharacter(uint8_t c) {
  _prtSeparatorColumns();
  for(int i = 0; i < 5; i++) {
    uint8_t dots = roman8Font[c - ' '][i] | (prtUnderlined ? 0x80 : 0x00);
    _prtSetColumn(dots);
    if(prtExpanded) {
      _prtSetColumn(dots);
    }
  }
  _prtSeparatorColumns();

  if(c < 0x80) {
    g_string_append_c(prtText, (gchar)c);
  } else if(hp82240CharMap[c] != 0) {
    g_string_append_unichar(prtText, hp82240CharMap[c]);
  } else {
    g_string_append_c(prtText, '?');
  }
}

static void _prtInit(void) {
  if(prtLines == NULL) {
    prtText = g_string_new(NULL);
    _prtNewLine();
  }
}

static gboolean _prtScrollToBottom(gpointer data) {
  if(prtScrolled != NULL) {
    GtkAdjustment *adj = gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(prtScrolled));
    gtk_adjustment_set_value(adj, gtk_adjustment_get_upper(adj) - gtk_adjustment_get_page_size(adj));
  }
  return G_SOURCE_REMOVE;
}

static gboolean _prtUpdate(gpointer data) {
  prtUpdateId = 0;
  if(prtDrawing != NULL) {
    gtk_widget_set_size_request(prtDrawing, PRT_COLUMNS + 2 * PRT_MARGIN, prtLineCount * PRT_ROWS * prtScale + 2 * PRT_MARGIN);
    gtk_widget_queue_draw(prtDrawing);
    if(prtScrollPending) {
      prtScrollPending = false;
      g_idle_add(_prtScrollToBottom, NULL);  // after the layout has applied the new height
    }
  }
  return G_SOURCE_REMOVE;
}

//
//  Schedule one window update; bytes arriving before it fires share it
//
static void _prtScheduleUpdate(bool scroll) {
  if(prtDrawing != NULL) {
    prtScrollPending |= scroll;
    if(prtUpdateId == 0) {
      prtUpdateId = g_timeout_add(100, _prtUpdate, NULL);
    }
  }
}

//
//  Decode one byte of the HP 82240 byte stream
//
void printerWindowByte(uint8_t c) {
  _prtInit();

  if(prtEsc) {
    prtEsc = false;
    switch(c) {
      case 255: {  // reset
        prtExpanded = false;
        prtUnderlined = false;
        break;
      }
      case 253: {
        prtExpanded = true;
        break;
      }
      case 252: {
        prtExpanded = false;
        break;
      }
      case 251: {
        prtUnderlined = true;
        break;
      }
      case 250: {
        prtUnderlined = false;
        break;
      }
      default: {
        if(c >= 1 && c <= PRT_COLUMNS) {
          prtGraphicLength = c;
        }
      }
    }
    return;
  }

  if(prtGraphicLength > 0) {
    prtGraphicLength--;
    _prtSetColumn(c);
    if(prtExpanded) {
      _prtSetColumn(c);
    }
  } else if(c == PRT_ESC) {
    prtEsc = true;
    return;
  } else if(c == 0x04 || c == '\n') {
    g_string_append_c(prtText, '\n');
    _prtNewLine();
    _prtScheduleUpdate(true);
    return;
  } else if(c >= ' ') {
    _prtCharacter(c);
  }

  _prtScheduleUpdate(false);
}

//
//  Paint lines first to last - 1 with their top left dot at x, y, scale screen pixels per dot.
//  The dots are written to an image of one pixel per dot, which one paint enlarges without smoothing.
//
static void _prtPaintLines(cairo_t *cr, int32_t first, int32_t last, double x, double y, int32_t scale) {
  cairo_surface_t *surface;
  uint8_t *data;
  int stride;

  if(last <= first) {
    return;
  }
  surface = cairo_image_surface_create(CAIRO_FORMAT_RGB24, PRT_COLUMNS, (last - first) * PRT_ROWS);
  cairo_surface_flush(surface);
  data = cairo_image_surface_get_data(surface);
  stride = cairo_image_surface_get_stride(surface);
  for(int32_t line = first; line < last; line++) {
    for(int16_t row = 0; row < PRT_ROWS; row++) {
      uint32_t *pixel = (uint32_t *)(data + ((line - first) * PRT_ROWS + row) * stride);
      for(int16_t col = 0; col < PRT_COLUMNS; col++) {
        pixel[col] = ((prtLines[line][col] >> row) & 0x01) ? 0x000000 : 0xFFFFFF;
      }
    }
  }
  cairo_surface_mark_dirty(surface);

  cairo_save(cr);
  cairo_translate(cr, x, y);
  cairo_scale(cr, scale, scale);
  cairo_set_source_surface(cr, surface, 0, 0);
  cairo_pattern_set_filter(cairo_get_source(cr), CAIRO_FILTER_NEAREST);
  cairo_paint(cr);
  cairo_restore(cr);
  cairo_surface_destroy(surface);
}

static cairo_surface_t *_prtCreateImage(void) {
  int32_t width = PRT_COLUMNS * prtScale + 2 * PRT_MARGIN;
  int32_t height = prtLineCount * PRT_ROWS * prtScale + 2 * PRT_MARGIN;
  cairo_surface_t *surface = cairo_image_surface_create(CAIRO_FORMAT_RGB24, width, height);
  cairo_t *cr = cairo_create(surface);

  cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
  cairo_paint(cr);
  _prtPaintLines(cr, 0, prtLineCount, PRT_MARGIN, PRT_MARGIN, prtScale);
  cairo_destroy(cr);
  return surface;
}

static gboolean _prtDraw(GtkWidget *widget, cairo_t *cr, gpointer data) {
  double x1, y1, x2, y2;
  int32_t firstLine, lastLine;
  int32_t lineHeight = PRT_ROWS * prtScale;
  int32_t left = (gtk_widget_get_allocated_width(widget) - PRT_COLUMNS * prtScale) / 2;  // the paper is centred in the window

  cairo_clip_extents(cr, &x1, &y1, &x2, &y2);
  cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
  cairo_paint(cr);

  firstLine = ((int32_t)y1 - PRT_MARGIN) / lineHeight;
  lastLine = ((int32_t)y2 - PRT_MARGIN) / lineHeight + 1;
  if(firstLine < 0) {
    firstLine = 0;
  }
  if(lastLine > prtLineCount) {
    lastLine = prtLineCount;
  }
  _prtPaintLines(cr, firstLine, lastLine, left, PRT_MARGIN + firstLine * lineHeight, prtScale);
  return FALSE;
}

//
//  The dot size is the largest whole number of screen pixels that fits the window width
//
static void _prtSizeAllocate(GtkWidget *widget, GdkRectangle *allocation, gpointer data) {
  int32_t scale = (allocation->width - 2 * PRT_MARGIN) / PRT_COLUMNS;

  if(scale < 1) {
    scale = 1;
  }
  if(scale != prtScale) {
    prtScale = scale;
    _prtScheduleUpdate(false);
  }
}

static void _prtClear(GtkWidget *widget, gpointer data) {
  prtLineCount = 0;
  prtEsc = false;
  prtGraphicLength = 0;
  g_string_truncate(prtText, 0);
  _prtNewLine();
  _prtScheduleUpdate(false);
}

static void _prtAdvance(GtkWidget *widget, gpointer data) {
  printerWindowByte('\n');
}

static void _prtCopyText(GtkWidget *widget, gpointer data) {
  GtkClipboard *clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  gtk_clipboard_set_text(clipboard, prtText->str, (gint)prtText->len);
}

static void _prtCopyImage(GtkWidget *widget, gpointer data) {
  GtkClipboard *clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  cairo_surface_t *surface = _prtCreateImage();
  GdkPixbuf *pixbuf = gdk_pixbuf_get_from_surface(surface, 0, 0, cairo_image_surface_get_width(surface), cairo_image_surface_get_height(surface));

  gtk_clipboard_set_image(clipboard, pixbuf);
  g_object_unref(pixbuf);
  cairo_surface_destroy(surface);
}

static void _prtScrollBy(double lines, double pages) {
  GtkAdjustment *adj = gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(prtScrolled));

  gtk_adjustment_set_value(adj, gtk_adjustment_get_value(adj) + lines * PRT_ROWS * prtScale + pages * gtk_adjustment_get_page_size(adj));
}

//
//  Keep the offset from the calculator window and the size. On Wayland GTK returns 0 for both positions, so the offset is 0 and the window manager places the window.
//
static void _prtSaveGeometry(void) {
  int calcX, calcY;

  gtk_window_get_position(GTK_WINDOW(frmCalc), &calcX, &calcY);
  gtk_window_get_position(GTK_WINDOW(prtWindow), &prtGeometry.x, &prtGeometry.y);
  prtGeometry.x -= calcX;
  prtGeometry.y -= calcY;
  gtk_window_get_size(GTK_WINDOW(prtWindow), &prtGeometry.width, &prtGeometry.height);
}

//
//  Hide the window, keep its offset and size for the next show, and hand the keyboard focus back to the calculator window.
//  The time of the event that hides the window lets the window manager accept the focus change.
//
static gboolean _prtHide(GtkWidget *widget, GdkEvent *event, gpointer data) {
  _prtSaveGeometry();
  gtk_widget_hide(prtWindow);
  gtk_window_present_with_time(GTK_WINDOW(frmCalc), gtk_get_current_event_time());
  return TRUE;
}

//
//  Record the position and size the window manager reports, so a hide keeps the size the user last gave the window
//
static gboolean _prtConfigure(GtkWidget *widget, GdkEventConfigure *event, gpointer data) {
  if(gtk_widget_get_visible(prtWindow) && !prtRestorePending) {
    _prtSaveGeometry();
  }
  return FALSE;
}

//
//  Apply the saved size once the window is shown. A window manager may configure a window that is shown again with its first size, KWin on Wayland does,
//  and only a resize after that configure keeps the size the user gave the window.
//
static gboolean _prtRestoreSize(gpointer data) {
  gtk_window_resize(GTK_WINDOW(prtWindow), prtGeometry.width, prtGeometry.height);
  prtRestorePending = false;
  return G_SOURCE_REMOVE;
}

static gboolean _prtKeyPressed(GtkWidget *widget, GdkEventKey *event, gpointer data) {
  if(event->state & GDK_CONTROL_MASK) {
    switch(event->keyval) {
      case GDK_KEY_a:
      case GDK_KEY_A: {
        _prtAdvance(widget, NULL);
        return TRUE;
      }
      case GDK_KEY_c:
      case GDK_KEY_C: {
        _prtCopyText(widget, NULL);
        return TRUE;
      }
      case GDK_KEY_i:
      case GDK_KEY_I: {
        _prtCopyImage(widget, NULL);
        return TRUE;
      }
      case GDK_KEY_l:
      case GDK_KEY_L: {
        _prtClear(widget, NULL);
        return TRUE;
      }
      case GDK_KEY_p:
      case GDK_KEY_P:
      case GDK_KEY_w:
      case GDK_KEY_W: {
        _prtHide(prtWindow, NULL, NULL);
        return TRUE;
      }
      default: {
        break;
      }
    }
    return FALSE;
  }

  switch(event->keyval) {
    case GDK_KEY_Up:
    case GDK_KEY_KP_Up: {
      _prtScrollBy(-1, 0);
      return TRUE;
    }
    case GDK_KEY_Down:
    case GDK_KEY_KP_Down: {
      _prtScrollBy(1, 0);
      return TRUE;
    }
    case GDK_KEY_Page_Up:
    case GDK_KEY_KP_Page_Up: {
      _prtScrollBy(0, -1);
      return TRUE;
    }
    case GDK_KEY_Page_Down:
    case GDK_KEY_KP_Page_Down: {
      _prtScrollBy(0, 1);
      return TRUE;
    }
    case GDK_KEY_Home:
    case GDK_KEY_KP_Home: {
      gtk_adjustment_set_value(gtk_scrolled_window_get_vadjustment(GTK_SCROLLED_WINDOW(prtScrolled)), 0);
      return TRUE;
    }
    case GDK_KEY_End:
    case GDK_KEY_KP_End: {
      _prtScrollToBottom(NULL);
      return TRUE;
    }
    case GDK_KEY_Escape: {
      _prtHide(prtWindow, NULL, NULL);
      return TRUE;
    }
    default: {
      return FALSE;
    }
  }
}

static void _prtCreateWindow(void) {
  GtkWidget *box, *buttons, *button;
  int calcWidth, calcHeight;

  prtWindow = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  gtk_window_set_title(GTK_WINDOW(prtWindow), "HP 82240B print-out");
  gtk_window_get_size(GTK_WINDOW(frmCalc), &calcWidth, &calcHeight);
  gtk_window_set_default_size(GTK_WINDOW(prtWindow), PRT_COLUMNS * PRT_SCALE + 2 * PRT_MARGIN + 24, calcHeight);  // as high as the calculator window
  g_signal_connect(prtWindow, "delete-event", G_CALLBACK(_prtHide), NULL);
  g_signal_connect(prtWindow, "key-press-event", G_CALLBACK(_prtKeyPressed), NULL);
  g_signal_connect(prtWindow, "configure-event", G_CALLBACK(_prtConfigure), NULL);
  g_signal_connect(prtWindow, "configure-event", G_CALLBACK(onUIActivity), NULL);  // the guard the calculator window has against a main loop run while Windows moves or resizes it
  g_signal_connect(prtWindow, "button-press-event", G_CALLBACK(onUIActivity), NULL);
  g_signal_connect(prtWindow, "focus-in-event", G_CALLBACK(onUIActivity), NULL);
  g_signal_connect(prtWindow, "focus-out-event", G_CALLBACK(onUIActivity), NULL);

  box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
  gtk_container_add(GTK_CONTAINER(prtWindow), box);

  buttons = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
  gtk_container_set_border_width(GTK_CONTAINER(buttons), 4);
  gtk_box_pack_start(GTK_BOX(box), buttons, FALSE, FALSE, 0);

  button = gtk_button_new_with_label("Advance");
  gtk_widget_set_tooltip_text(button, "Advance the paper by one line (Ctrl+A)");
  g_signal_connect(button, "clicked", G_CALLBACK(_prtAdvance), NULL);
  gtk_box_pack_start(GTK_BOX(buttons), button, FALSE, FALSE, 0);

  button = gtk_button_new_with_label("Clear");
  gtk_widget_set_tooltip_text(button, "Clear the print-out (Ctrl+L)");
  g_signal_connect(button, "clicked", G_CALLBACK(_prtClear), NULL);
  gtk_box_pack_start(GTK_BOX(buttons), button, FALSE, FALSE, 0);

  button = gtk_button_new_with_label("Copy text");
  gtk_widget_set_tooltip_text(button, "Copy the printed characters to the clipboard (Ctrl+C). Glyphs sent as graphic data are not included.");
  g_signal_connect(button, "clicked", G_CALLBACK(_prtCopyText), NULL);
  gtk_box_pack_start(GTK_BOX(buttons), button, FALSE, FALSE, 0);

  button = gtk_button_new_with_label("Copy image");
  gtk_widget_set_tooltip_text(button, "Copy the print-out to the clipboard as image (Ctrl+I)");
  g_signal_connect(button, "clicked", G_CALLBACK(_prtCopyImage), NULL);
  gtk_box_pack_start(GTK_BOX(buttons), button, FALSE, FALSE, 0);

  prtScrolled = gtk_scrolled_window_new(NULL, NULL);
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(prtScrolled), GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
  gtk_box_pack_start(GTK_BOX(box), prtScrolled, TRUE, TRUE, 0);

  prtDrawing = gtk_drawing_area_new();
  g_signal_connect(prtDrawing, "draw", G_CALLBACK(_prtDraw), NULL);
  g_signal_connect(prtDrawing, "size-allocate", G_CALLBACK(_prtSizeAllocate), NULL);
  gtk_container_add(GTK_CONTAINER(prtScrolled), prtDrawing);
  _prtScheduleUpdate(true);
}

//
//  Show the print-out window, or hide it when it is shown; Ctrl+P on the simulator
//
void printerWindowToggle(void) {
  int calcX, calcY, calcWidth, calcHeight;

  _prtInit();
  if(prtWindow == NULL) {
    _prtCreateWindow();
  } else if(gtk_widget_get_visible(prtWindow)) {
    _prtHide(prtWindow, NULL, NULL);
    return;
  }
  gtk_window_get_position(GTK_WINDOW(frmCalc), &calcX, &calcY);
  if(prtGeometry.width > 0) {
    gtk_window_move(GTK_WINDOW(prtWindow), calcX + prtGeometry.x, calcY + prtGeometry.y);
    gtk_window_set_default_size(GTK_WINDOW(prtWindow), prtGeometry.width, prtGeometry.height);
    gtk_window_resize(GTK_WINDOW(prtWindow), prtGeometry.width, prtGeometry.height);
    prtRestorePending = true;
    g_timeout_add(100, _prtRestoreSize, NULL);
  } else {
    gtk_window_get_size(GTK_WINDOW(frmCalc), &calcWidth, &calcHeight);
    gtk_window_move(GTK_WINDOW(prtWindow), calcX + calcWidth + PRT_MARGIN, calcY);  // first show: to the right of the calculator window
  }
  gtk_widget_show_all(prtWindow);
  gtk_window_present(GTK_WINDOW(prtWindow));
  _prtScheduleUpdate(true);
}

#else  // !OPTION_IR_PRINTING

void printerWindowByte(uint8_t c) {
}

void printerWindowToggle(void) {
}

#endif  // OPTION_IR_PRINTING
