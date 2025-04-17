// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors


#include "c47.h"

    void setBlackPixel(uint32_t x, uint32_t y) {
      //if(y >= (uint32_t)(-6)) return;  //JM allowing allowing -1..-5 for top row text

      if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) {
        printf("In function setBlackPixel: x=%u or %d, y=%u or %d outside the screen!\n", x, (int32_t)(x), y, (int32_t)(y) );
        return;
      }

      *(screenData + y*screenStride + x) = ON_PIXEL;
      screenChange = true;
    }


    void setWhitePixel(uint32_t x, uint32_t y) {
      //if(y >= (uint32_t)(-6)) return;  //JM allowing allowing -1..-5 for top row text

      if(x>=SCREEN_WIDTH || y>=SCREEN_HEIGHT) {
        printf("In function setWhitePixel: x=%u or %d, y=%u or %d outside the screen!\n", x, (int32_t)x, y, (int32_t)y);
        return;
      }

      *(screenData + y*screenStride + x) = OFF_PIXEL;
      screenChange = true;
    }


    void flipPixel(uint32_t x, uint32_t y) {
      if(x >= SCREEN_WIDTH || y >= SCREEN_HEIGHT) {
        printf("In function flipPixel: x=%u, y=%u outside the screen!\n", x, y);
        return;
      }

      *(screenData + y*screenStride + x) ^= (ON_PIXEL ^ OFF_PIXEL);
      screenChange = true;
    }



    int16_t clearScreenCounter = 0;                       //JM ClearScreen Test
    void lcd_fill_rect(uint32_t x, uint32_t y, uint32_t dx, uint32_t dy, int val) {
      uint32_t line, col, pixelColor, *pixel, endX = x + dx, endY = y + dy;

      //if(y >= (uint32_t)(-100)) { //JM allowing -100 to measure the size in pixels; allowing -1..-5 for top row text
      //  return;
      //}

      if(x == 0 && y == 0 && dx == SCREEN_WIDTH && dy == SCREEN_HEIGHT) {  //JMTOCHECK is this needed?
        #if defined(MONITOR_CLRSCR)
          printf("   >>> screen.c: clearScreen: calcmode=%u clearScreenCounter=%d\n",calcMode, clearScreenCounter++);    //JMYY ClearScreen Test  #endif
        #endif
        clear_ul(); //JMUL
      }

      if(endX > SCREEN_WIDTH || endY > SCREEN_HEIGHT) {
        #if defined(MONITOR_CLRSCR)
          printf("In function lcd_fill_rect: x=%u, y=%u, dx=%u, dy=%u, val=%d outside the screen!\n", x, y, dx, dy, val);
        #endif
        return;
      }

      pixelColor = (val == LCD_SET_VALUE ? OFF_PIXEL : ON_PIXEL);
      for(line=y; line<endY; line++) {
        for(col=x, pixel=screenData + line*screenStride + x; col<endX; col++, pixel++) {
          *pixel = pixelColor;
        }
      }

      #if defined(DEBUGCLEARS)
        plotrect(x, y, x+dx, y+dy);
      #endif // DEBUGCLEARS

      screenChange = true;
    }



    void refresh_gui(void) {
        while(gtk_events_pending()) {
          gtk_main_iteration();
        }
    }


    //#include <execinfo.h>
    void _lcdRefresh(void) {              //called by force_refresh() and _printHalfSecUpdate_Integer()
        //void *callstack[128];
        //int frames = backtrace(callstack, 128);
        //char **strs = backtrace_symbols(callstack, frames);
        //printf("_lcdRefresh called from function: %s\n", strs[1]);
        //free(strs);
        if(screenChange) {
          gtk_widget_queue_draw(screen);
          #if defined(FULLUPDATE) // (UGLY)
            refresh_gui();
          #endif // FULLUPDATE (UGLY)
        }
    }


    void _lcdSBRefresh(void) {
        //void *callstack[128];
        //int frames = backtrace(callstack, 128);
        //char **strs = backtrace_symbols(callstack, frames);
        //printf("_lcdSBRefresh called from function: %s\n", strs[1]);
        //free(strs);
        if(screenChange) {
          gtk_widget_queue_draw_area(screen, 0, 0, 400, 20);
          #if defined(FULLUPDATE) // (UGLY)
            refresh_gui();
          #endif // FULLUPDATE (UGLY)
        }
    }

