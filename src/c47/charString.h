/* This file is part of 43S.
 *
 * 43S is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * 43S is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 43S.  If not, see <http://www.gnu.org/licenses/>.
 */

/********************************************//**
 * \file charString.h
 ***********************************************/
#if !defined(CHARSTRING_H)
#define CHARSTRING_H

#include "typeDefinitions.h"
#include <stdint.h>

/********************************************//**
 * \brief Returns a pointer to the last glyph of a string
 *
 * \param[in] str const char*
 * \return int16_t              Pointer to the last glyph
 ***********************************************/
int16_t  stringLastGlyph  (const char *str);

/********************************************//**
 * \brief Returns a pointer to the glyph after pos a string
 *
 * \param[in] str const char*
 * \param[in] pos int16_t       Location after which search the next glyph
 * \return int16_t              Pointer to the glyph after pos
 ***********************************************/
int16_t  stringNextGlyphNoEndCheck_JM  (const char *str, int16_t pos);
int16_t  stringNextGlyph  (const char *str, int16_t pos);

/********************************************//**              //JM
 * \brief Returns a pointer to the glyph before pos a string
 *
 * \param[in] str const char*
 * \param[in] pos int16_t       Location after which search the next glyph
 * \return int16_t              Pointer to the glyph after pos
 ***********************************************/
int16_t  stringPrevGlyph  (const char *str, int16_t pos);     //JM

/********************************************//**
 * \brief Returns a string length in byte
 *
 * \param[in] str const char*
 * \return int32_t
 ***********************************************/
int32_t  stringByteLength (const char *str);

/********************************************//**
 * \brief Returns a string length in glyphs
 *
 * \param[in] str const char*
 * \return int32_t
 ***********************************************/
int32_t  stringGlyphLength(const char *str);

/********************************************//**
 * \brief Calculates a string width in pixel using a certain font
 *
 * \param[in] str const char*             String whose length is to calculate
 * \param[in] font font_t*                Font
 * \param[in] withLeadingEmptyRows bool_t With the leading empty rows
 * \param[in] withEndingEmptyRows bool_t  With the ending empty rows
 * \return int16_t                        Width in pixel of the string
 ***********************************************/
int16_t  stringWidth      (const char *str, const font_t *font, bool_t withLeadingEmptyRows, bool_t withEndingEmptyRows);
uint16_t charCodeFromString(const char *ch, uint16_t *offset);
void     charCodeHPReplacement(uint16_t * charCode);

/********************************************//**
 * \brief Calculates the first character which does not fit to specified width using a certain font
 *
 * \param[in] str const char*             String
 * \param[in] font font_t*                Font
 * \param[in] width int16_t               Width of where to show the string
 * \param[in] withLeadingEmptyRows bool_t With the leading empty rows
 * \param[in] withEndingEmptyRows bool_t  With the ending empty rows
 * \return char*                          Width in pixel of the string
 ***********************************************/
char    *stringAfterPixels(const char *str, const font_t *font, int16_t width, bool_t withLeadingEmptyRows, bool_t withEndingEmptyRows);


/********************************************//**
 * \brief Converts an unicode code point to utf8
 *
 * \param[in]  codePoint uint32_t Unicode code point
 * \param[out] utf8 uint8_t*      utf8 string
 * \return void
 ***********************************************/
void     codePointToUtf8  (uint32_t codePoint, uint8_t *utf8);

/********************************************//**
 * \brief Converts one utf8 char to an unicode code point
 *
 * \param[in]  utf8 uint8_t*      utf8 string
 * \param[out] codePoint uint32_t Unicode code point
 * \return void
 ***********************************************/
uint32_t utf8ToCodePoint  (const uint8_t *utf8, uint32_t *codePoint);

/**
 * Copies the string including the terminating null byte
 *
 * \param[out] dest
 * \param[in] source
 * \return a pointer to the end (i.e. terminating null byte) of the resulting string dest
 */
char    *stringAppend     (char *dest, const char *source);

void     expandConversionName(char *msg1);
void     compressConversionName(char *msg1);

void     stringToUtf8     (const char *str, uint8_t *utf8);
void     utf8ToString     (const uint8_t *utf8, char *str);
void     stringToASCII    (const char *str, char *ascii);
void stringToFileNameChars(const char *str, char *ascii);
void    *xcopy            (void *dest, const void *source, int n);
  #if !defined(DMCP_BUILD)
    void strReplace         (char *haystack, const char *needle, const char *newNeedle);
  #endif // !DMCP_BUILD
#endif // !CHARSTRING_H
