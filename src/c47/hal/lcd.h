// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/**
 * \file hal/lcd.h
 * LCD related functions.
 */
#if !defined(LCD_H)
  #define LCD_H

  #if defined(DMCP_BUILD)
    // lcd_fill_rect from dmcp.h
    // lcd_refresh   from dmcp.h
    static inline void setBlackPixel(uint32_t x, uint32_t y) {
      bitblt24(x, 1, y, 1, BLT_OR,   BLT_NONE);
    }
    static inline void setWhitePixel(uint32_t x, uint32_t y) {
      bitblt24(x, 1, y, 1, BLT_ANDN, BLT_NONE);
    }
    static inline void flipPixel(uint32_t x, uint32_t y) {
      bitblt24(x, 1, y, 1, BLT_XOR,  BLT_NONE);
    }
    static inline void _lcdRefresh(void) {
      lcd_forced_refresh();
    }
    static inline void _lcdSBRefresh(void) {
      lcd_refresh_lines(0,20);
    }


  #else
    #define LCD_SET_VALUE   0   // Black pixel
    #define LCD_EMPTY_VALUE 255 // White (or empty) pixel

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

    /**
     * Refresh the LCD with the draw buffer contents.
     */
    void _lcdRefresh   (void);
    void _lcdSBRefresh(void);

    /**
     * Sets a single black pixel on the screen.
     *
     * \param[in] x x coordinate from 0 (left) to 399 (right)
     * \param[in] y y coordinate from 0 (top) to 239 (bottom)
     */
    void setBlackPixel (uint32_t x, uint32_t y);

    /**
     * Sets a single white pixel on the screen.
     *
     * \param[in] x x coordinate from 0 (left) to 399 (right)
     * \param[in] y y coordinate from 0 (top) to 239 (bottom)
     */
    void setWhitePixel (uint32_t x, uint32_t y);

    /**
     * Turns a single black pixel to a white pixel or vice versa on the screen.
     *
     * \param[in] x x coordinate from 0 (left) to 399 (right)
     * \param[in] y y coordinate from 0 (top) to 239 (bottom)
     */
    void flipPixel     (uint32_t x, uint32_t y);
  #endif // DMCP_BUILD

#endif // !LCD_H
