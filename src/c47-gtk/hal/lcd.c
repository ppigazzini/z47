// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


#include "c47.h"

#if defined(PC_BUILD) && !defined(WIN32)
#include <execinfo.h>
#include <dlfcn.h>
#include <stdarg.h>

void print_caller(const char *format, ...) {
  void *cs[64];
  va_list ap;

  backtrace(cs, 64);
  Dl_info infoA, infoB;
  dladdr(cs[1], &infoA);
  dladdr(cs[2], &infoB);
  printf("%s%s%s called from: %s%-30s%s",COLOR_CYAN, infoA.dli_sname, COLOR_DEFAULT, COLOR_BLUE, infoB.dli_sname, COLOR_DEFAULT);

  if (format != NULL) {
    printf("| ");
    va_start(ap, format);
    vprintf(format, ap);
    va_end(ap);
  }
  printf("\n");

}
#endif //PC_BUILD

uint8_t * lcd_line_addr (int row) {
  lcd_buffer[52 * (row)] = 1u;
  return lcd_buffer + row * 52 + 2;
}


void 	LCD_write_line (uint8_t *line_buf) {
  // adapting data in lcd_buffer for GTK and write to the LCD widget
  int i, j, row=line_buf[1];
  uint8_t tmpChar;
  uint32_t *lineStart = screenData + (SCREEN_HEIGHT - row) * screenStride - 1;
  for (i=0;i<50;i++){
    tmpChar = line_buf[i+2];
    for (j=0;j<8;j++){
      *(lineStart - i * 8 - j) = (tmpChar>>j&1u)?ON_PIXEL:OFF_PIXEL;
    }
  }
  line_buf[0] = 0u; // Mark updated
  gtk_widget_queue_draw_area(screen, 0, SCREEN_HEIGHT - row - 1, 400, 1);
}


void 	lcd_clear_buf () {
  for (uint8_t row = 0; row < SCREEN_HEIGHT; row++) {
    uint8_t *line_buf = lcd_buffer + 52 * row;
    for (uint8_t c = 2; c < 52; c++) {
      line_buf[c] = 255u;
    }
    line_buf[1] = SCREEN_HEIGHT - row - 1;
    line_buf[0] = 1u;
    LCD_write_line(line_buf);
  }
}

void lcd_refresh () {
  bool_t changed = false;
  for (uint8_t row = 0; row < SCREEN_HEIGHT; row++) {
    if (lcd_buffer[52 * row]) { // check dirty flag byte for line
      changed = true;
      LCD_write_line(&lcd_buffer[52 * row]);
    }
  }
#if defined(FULLUPDATE) // (UGLY)
  if (changed) {
    refresh_gui();
  }
#endif // FULLUPDATE (UGLY)
}

void lcd_refresh_lines (uint8_t ln, uint8_t cnt){
  // no dirty line check
  for (uint8_t row = ln; row < ln + cnt; row++) {
    LCD_write_line(&lcd_buffer[52 * row]);
  }
}



void bitblt24	(	uint32_t x, uint32_t dx, uint32_t y, uint32_t val, int blt_op, int fill ) {
  if (dx < 1 || dx > 24) return;

  if (x >= SCREEN_WIDTH || x + dx > SCREEN_WIDTH) {
    printf("In function bitblt24: xmin=%d xmax=%d, y=%d outside the screen!\n", (int32_t)(x),  (int32_t)(x+dx-1), (int32_t)(y) );
    return;
  }
  x = SCREEN_WIDTH - dx - x;

  const uint32_t byte_i   = x >> 3;
  const uint32_t bit_off  = x & 7u;

  const uint32_t lowmask  = (1u << dx) - 1u;

  uint32_t srcbits;
  if (fill == BLT_SET && blt_op != BLT_XOR) {
    srcbits = (blt_op == BLT_ANDN) ? lowmask << bit_off : 0u;
  } else {
    srcbits = (val & lowmask) << bit_off;
  }
  uint8_t srcbytes[4] = {
    (uint8_t)(srcbits >> 0),
    (uint8_t)(srcbits >> 8),
    (uint8_t)(srcbits >> 16),
    (uint8_t)(srcbits >> 24),
  };
  uint8_t *j = &lcd_buffer[y * (LCD_LINE_SIZE + 2) + byte_i + 2];
  switch (blt_op) {
    case BLT_OR:   for (int i = 0; i < 4; i++) j[i] |=  srcbytes[i]; break;
    case BLT_XOR:  for (int i = 0; i < 4; i++) j[i] ^=  srcbytes[i]; break;
    case BLT_ANDN: for (int i = 0; i < 4; i++) j[i] &= ~srcbytes[i]; break;
    default: return;
  }
  lcd_buffer[y * (LCD_LINE_SIZE + 2)] = 1u; // Mark line dirty
}


int16_t clearScreenCounter = 0;                       //JM ClearScreen Test
void lcd_fill_rect(uint32_t x, uint32_t y, uint32_t dx, uint32_t dy, int val) {
  uint32_t line, col, cols, endX = x + dx, endY = y + dy;

  if(x == 0 && y == 0 && dx == SCREEN_WIDTH && dy == SCREEN_HEIGHT) {  //JMTOCHECK is this needed?
    #if defined(MONITOR_CLRSCR)
      printf("   >>> screen.c: clearScreen: calcmode=%u clearScreenCounter=%d\n",calcMode, clearScreenCounter++);    //JMYY ClearScreen Test  #endif
    #endif
    // clear_ul(); //JMUL
  }

  if(endX > SCREEN_WIDTH || endY > SCREEN_HEIGHT) {
    #if defined(MONITOR_CLRSCR)
      printf("In function lcd_fill_rect: x=%u, y=%u, dx=%u, dy=%u, val=%d outside the screen!\n", x, y, dx, dy, val);
                                    #if defined(ANALYSE_REFRESH)
                                      print_caller();
                                    #endif //ANALYSE_REFRESH
    #endif
    return;
  }
  int blt_op = val ? BLT_OR : BLT_ANDN;
  for (col = x; col < endX; col += 24) {
    cols = min(24, endX - col);
    for(line = y; line < endY; line++) {
      bitblt24(col, cols, line, 0xFFFFFF, blt_op, BLT_NONE);
    }
  }

  #if defined(DEBUGCLEARS)
    plotrect(x, y, x+dx, y+dy);
  #endif // DEBUGCLEARS
}

gboolean ui_is_active = FALSE;

void refresh_gui(void) {
  while(gtk_events_pending()) {
    if(ui_is_active) break;  // Exit if UI active - original W32 issue, but safer on all OS
    gtk_main_iteration();
  }
}


void _lcdRefresh(void) {              //called by force_refresh() and _printHalfSecUpdate_Integer()
          #if defined(ANALYSE_REFRESH)
            print_caller(NULL);
          #endif //ANALYSE_REFRESH
  lcd_refresh();
  // _lcdBandRefreshHelper(0, SCREEN_HEIGHT);
}
void _lcdBandRefresh(uint32_t y, uint32_t dy) {
           #if defined(ANALYSE_REFRESH)
            print_caller("y=%u, dy=%u\n",y, dy);
           #endif //ANALYSE_REFRESH
  lcd_refresh();
  // _lcdBandRefreshHelper(y, dy);
}

void _lcdSBRefresh(void) {
          #if defined(ANALYSE_REFRESH)
            print_caller(NULL);
          #endif //ANALYSE_REFRESH
  lcd_refresh();
  // _lcdBandRefreshHelper(0, 20);
}


