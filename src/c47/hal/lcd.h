// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file hal/lcd.h
 * LCD related functions.
 */
#if !defined(LCD_H)
  #define LCD_H

#if defined(DMCP_BUILD)
  static inline void _lcdRefresh(void) {
    lcd_refresh();
  }
  static inline void _lcdSBRefresh(void) {
    lcd_refresh();
  }
  static inline void _lcdBandRefresh(uint32_t y, uint32_t dy) {
    lcd_refresh();
  }
  // lcd_fill_rect from dmcp.h
  // lcd_refresh   from dmcp.h
  // LCD_write_line from dmcp.h

#else
  #define 	LCD_LINE_SIZE   50
  #define 	LCD_LINE_BUF_SIZE   (LCD_LINE_SIZE+4)
  #define LCD_SET_VALUE   0   // Black pixel
  #define LCD_EMPTY_VALUE 255 // White (or empty) pixel
  typedef enum { BLT_OR = 0, BLT_ANDN = 1, BLT_XOR = 2 } blt_op_t;
  typedef enum { BLT_NONE = 0, BLT_SET  = 1 } blt_fill_t;

  
  // void lcd_fill_ptrn(int x, int y, int dx, int dy, int ptrn1, int ptrn2);
  /**
   * Refresh the LCD with the draw buffer contents.
   */
  void _lcdRefresh    (void);
  void _lcdSBRefresh  (void);
  void _lcdBandRefresh(uint32_t y, uint32_t dy);

  // mimic DMCP functions
 /**
  * Fills a rectangle with either black or white.
  *
  * \param[in] x   x coordinate from 0 (left) to 399 (right)
  * \param[in] y   y coordinate from 0 (top) to 239 (bottom)
  * \param[in] dx  width of the rect (inclusive of the ends)
  * \param[in] dy  height of the rect (inclusive of the ends)
  * \param[in] val LCD_SET_VALUE (black) or LCD_EMPTY_VALUE (white) for the filled
  *                rectangle
  */
  void lcd_fill_rect (uint32_t x, uint32_t y, uint32_t dx, uint32_t dy, int val);
  void LCD_write_line (uint8_t *buf);
  uint8_t * lcd_line_addr ( int y);	
  void bitblt24 ( uint32_t x, uint32_t dx, uint32_t y, uint32_t val, int blt_op, int fill );
  void lcd_clear_buf ();
  void lcd_refresh ();
  void lcd_refresh_lines (uint ln, uint cnt);

  void refresh_gui(void);
#endif // DMCP_BUILD

 /**
  * Sets a single black pixel on the screen.
  *
  * \param[in] x x coordinate from 0 (left) to 399 (right)
  * \param[in] y y coordinate from 0 (top) to 239 (bottom)
  */
  static inline void setBlackPixel(uint32_t x, uint32_t y) {
    bitblt24(x, 1, y, 1, BLT_OR,   BLT_NONE);
  }

 /**
  * Sets a single white pixel on the screen.
  *
  * \param[in] x x coordinate from 0 (left) to 399 (right)
  * \param[in] y y coordinate from 0 (top) to 239 (bottom)
  */
  static inline void setWhitePixel(uint32_t x, uint32_t y) {
    bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
  }

 /**
  * Turns a single black pixel to a white pixel or vice versa on the screen.
  *
  * \param[in] x x coordinate from 0 (left) to 399 (right)
  * \param[in] y y coordinate from 0 (top) to 239 (bottom)
  */
  static inline void flipPixel(uint32_t x, uint32_t y) {
    bitblt24(x, 1, y, 1, BLT_XOR,  BLT_NONE);
  }

#endif // !LCD_H
