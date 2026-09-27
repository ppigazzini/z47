// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


#include "c47.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

// The headless testSuite renders into a real 1bpp frame buffer so plot and
// display output can be snapshotted and hashed. bitblt24, lcd_fill_rect and
// lcd_buffer_pixel_on are the c47-gtk software blitter; the buffer keeps the
// same 52-byte row stride (a two-byte prefix and 50 data bytes per row) as the
// simulator so screen.c and fnScreenDump address it identically. A few guard
// bytes are added so a 24-bit blit at the last column cannot run off the end.

static void ensureLcdBuffer(void) {
  if(lcd_buffer == NULL) {
    lcd_buffer = (uint8_t *)calloc(SCREEN_HEIGHT * (SCREEN_WIDTH / 8 + 2) + 16, 1) + 2;
  }
}

void bitblt24(uint32_t x, uint32_t dx, uint32_t y, uint32_t val, int blt_op, int fill) {
  ensureLcdBuffer();
  if(dx < 1 || dx > 24) {
    return;
  }
  if(x >= SCREEN_WIDTH || x + dx > SCREEN_WIDTH) {
    return;
  }
  x = SCREEN_WIDTH - dx - x;

  const uint32_t byte_i  = x >> 3;
  const uint32_t bit_off = x & 7u;
  const uint32_t lowmask = (1u << dx) - 1u;
  const uint32_t bytes_needed = (bit_off + dx + 7) / 8;

  const uint32_t srcbits = (val & lowmask) << bit_off;
  const uint32_t fillbits = (fill == BLT_SET) ? lowmask << bit_off : 0u;  // BLT_SET: the dx columns are written white before BLT_OR and black before BLT_ANDN
  uint8_t srcbytes[4] = {
    (uint8_t)(srcbits >> 0),
    (uint8_t)(srcbits >> 8),
    (uint8_t)(srcbits >> 16),
    (uint8_t)(srcbits >> 24),
  };
  uint8_t fillbytes[4] = {
    (uint8_t)(fillbits >> 0),
    (uint8_t)(fillbits >> 8),
    (uint8_t)(fillbits >> 16),
    (uint8_t)(fillbits >> 24),
  };
  uint8_t *j = &lcd_buffer[y * (LCD_LINE_SIZE + 2) + byte_i + 2];
  switch(blt_op) {
    case BLT_OR:   for(uint32_t i = 0; i < bytes_needed; i++) { j[i] = (j[i] | fillbytes[i]) & ~srcbytes[i]; } break;
    case BLT_XOR:  for(uint32_t i = 0; i < bytes_needed; i++) { j[i] ^=  srcbytes[i]; } break;
    case BLT_ANDN: for(uint32_t i = 0; i < bytes_needed; i++) { j[i] = (j[i] & ~fillbytes[i]) | srcbytes[i]; } break;
    default:       return;
  }
  lcd_buffer[y * (LCD_LINE_SIZE + 2)] = 1u; // mark line dirty
}

void lcd_fill_rect(uint32_t x, uint32_t y, uint32_t dx, uint32_t dy, int val) {
  uint32_t line, col, cols, endX = x + dx, endY = y + dy;
  if(endX > SCREEN_WIDTH || endY > SCREEN_HEIGHT) {
    return;
  }
  int blt_op = val ? BLT_OR : BLT_ANDN;
  for(col = x; col < endX; col += 24) {
    cols = (24u < endX - col) ? 24u : (endX - col);
    for(line = y; line < endY; line++) {
      bitblt24(col, cols, line, 0xFFFFFF, blt_op, BLT_NONE);
    }
  }
}

bool_t lcd_buffer_pixel_on(uint32_t x, uint32_t y) {
  ensureLcdBuffer();
  if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) {
    return false;
  }
  const uint8_t *line_buf = lcd_buffer + 52 * y;
  const uint32_t bitIndex = SCREEN_WIDTH - 1 - x;
  const uint32_t byte_i = bitIndex >> 3;
  const uint32_t bit_j = bitIndex & 7u;
  return !((line_buf[2 + byte_i] >> bit_j) & 1u);
}

uint8_t *lcd_line_addr(int row) {
  ensureLcdBuffer();
  if(row < 0 || row >= SCREEN_HEIGHT) {    // the same refusal as the c47-gtk twin, so an out of range row cannot differ between the two builds
    char tmp[1000];
    sprintf(tmp, "row = %" PRIi32 ", it should be >= 0 and < %" PRIi32 "!\n", (int32_t)row, (int32_t)SCREEN_HEIGHT);
    abortf(tmp);
  }
  lcd_buffer[52 * row] = 1u;               // marks the line dirty, as DMCP does
  return lcd_buffer + 52 * row + 2;
}

void _lcdRefresh(void) {
}

void _lcdSBRefresh(void) {
}

void lcd_refresh_lines(uint8_t ln, uint8_t cnt) {
}

void refresh_gui(void) {
}

void LCD_write_line(uint8_t *line_buf) {
}

void lcd_refresh(void) {
}

int create_dir(char *dir) {
  return 0;
}
