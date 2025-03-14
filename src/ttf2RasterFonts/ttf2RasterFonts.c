// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <ft2build.h>
#include FT_FREETYPE_H

/* Turn off -Wunused-result for a specific function call */
#define ignoreReturnedValue(function) (__extension__ ({ __typeof__ (function) __x = (function); (void) __x; }))

FT_Library library;
FT_Error   error;
FILE       *cFile, *hFile, *sortingOrder;
int        byte, numBits, pos, nbGlyphRanks;
char       line[500];

struct {
  uint16_t codePoint;
  int16_t  rank1;
  int16_t  rank2;
} glyphRank[1000];

const char* getErrorMessage(FT_Error err) {
  #undef __FTERRORS_H__
  #define FT_ERRORDEF( e, v, s )  case e: return s;
  #define FT_ERROR_START_LIST     switch(err) {
  #define FT_ERROR_END_LIST       }
  #include FT_ERRORS_H
  return "(Unknown error)";
}

uint16_t hexToUint(const char *hexa) {
    // the inialisation to zero prevents a 'variable used is not initialized' warning on Mac:
    uint16_t uint=0;

  if(   (('0' <= hexa[0] && hexa[0] <= '9') || ('A' <= hexa[0] && hexa[0] <= 'F') || ('a' <= hexa[0] && hexa[0] <= 'f'))
     && (('0' <= hexa[1] && hexa[1] <= '9') || ('A' <= hexa[1] && hexa[1] <= 'F') || ('a' <= hexa[1] && hexa[1] <= 'f'))
     && (('0' <= hexa[2] && hexa[2] <= '9') || ('A' <= hexa[2] && hexa[2] <= 'F') || ('a' <= hexa[2] && hexa[1] <= 'f'))
     && (('0' <= hexa[3] && hexa[3] <= '9') || ('A' <= hexa[3] && hexa[3] <= 'F') || ('a' <= hexa[3] && hexa[1] <= 'f'))) {
    if('0' <= hexa[0] && hexa[0] <= '9') {
      uint = hexa[0] - '0';
    }
    else if('a' <= hexa[0] && hexa[0] <= 'f') {
      uint = hexa[0] - 'a' + 10;
    }
    else {
      uint = hexa[0] - 'A' + 10;
    }

    if('0' <= hexa[1] && hexa[1] <= '9') {
      uint = uint*16 + hexa[1] - '0';
    }
    else if('a' <= hexa[1] && hexa[1] <= 'f') {
      uint = uint*16 + hexa[1] - 'a' + 10;
    }
    else {
      uint = uint*16 + hexa[1] - 'A' + 10;
    }

    if('0' <= hexa[2] && hexa[2] <= '9') {
      uint = uint*16 + hexa[2] - '0';
    }
    else if('a' <= hexa[2] && hexa[2] <= 'f') {
      uint = uint*16 + hexa[2] - 'a' + 10;
    }
    else {
      uint = uint*16 + hexa[2] - 'A' + 10;
    }

    if('0' <= hexa[3] && hexa[3] <= '9') {
      uint = uint*16 + hexa[3] - '0';
    }
    else if('a' <= hexa[3] && hexa[3] <= 'f') {
      uint = uint*16 + hexa[3] - 'a' + 10;
    }
    else {
      uint = uint*16 + hexa[3] - 'A' + 10;
    }
  }
  else {
    fprintf(stderr, "\nMissformed hexadecimal code point. The code %c%c%c%c is erroneous.\n", hexa[0], hexa[1], hexa[2], hexa[3]);
    exit(0);
  }

  return uint;
}

int sortCharCodes(const void *a, const void *b) {
  return  *(int *)a - *(int *)b;
}

void addBit(int bit) {
  byte <<= 1;
  byte |= bit;
  numBits++;
  if(numBits == 8) {
    fprintf(cFile, "\\x%02x", byte);
    numBits = 0;
    byte = 0;
  }
}

void exportCStructure(const char *fontsPath, const char *ttfName) {
  FT_Face   face;
  FT_UInt   glyphIndex;
  FT_ULong  charCode;
  FT_ULong  charCodes[1000];
  FT_Vector pen;
  char      glyphName[100];
  char      ttfName2[100], path[200], *fontName;
  int       x, y, cc, bit; // ,dataLength
  int       fontHeightPixels, unitsPerEm, onePixelSize, numberOfGlyphs;
  int       colsBeforeGlyph, colsGlyph, colsAfterGlyph;
  int       rowsAboveGlyph, rowsGlyph, rowsBelowGlyph;
  int       i, rank1, rank2;

  /////////////////////
  // Open the face 0 //
  /////////////////////
  sprintf(path, "%s/%s", fontsPath, ttfName);
  if((error = FT_New_Face(library, path, 0, &face)) != FT_Err_Ok) {
    fprintf(stderr, "Error during face creation from file %s\n", path);
    fprintf(stderr, "Error %d : %s\n", error, getErrorMessage(error));
    exit(1);
  }

  ///////////////////
  // Set font size //
  ///////////////////
  unitsPerEm       = face->units_per_EM;
  onePixelSize     = unitsPerEm==1000 ? 50 : 32;      // ???
  fontHeightPixels = unitsPerEm / onePixelSize; // What is the correct formula?
  if((error = FT_Set_Pixel_Sizes(face, 0, fontHeightPixels)) != FT_Err_Ok) {
    fprintf(stderr, "Error during FT_Set_Pixel_Sizes from file %s\n", ttfName);
    fprintf(stderr, "Error %d : %s\n", error, getErrorMessage(error));
    exit(1);
  }

  ///////////////////////
  // Get the font name //
  ///////////////////////
  strcpy(ttfName2, ttfName);
  x = strlen(ttfName2) - 4;
  ttfName2[x] = 0; // truncates .ttf
  while(--x>=0 && ttfName2[x] != '/') {
  }
  if(x < 0) {
    x = 0;
  }
  if(ttfName2[x] == '/') {
    fontName = ttfName2 + x + 6;
  }
  else {
    fontName = ttfName2 + x + 5;
  }

  fontName[0] |= 0x20; // 1st letter lower case
  #if defined(DEBUG)
    printf("fontName=<%s>\n", fontName);
  #endif // DEBUG


  //////////////////////////////////////////////////////////////
  // Get the number of glyphs and sort them per unicode point //
  //////////////////////////////////////////////////////////////
  numberOfGlyphs = 0;
  charCode = FT_Get_First_Char(face, &glyphIndex);

  while(glyphIndex) {
    if(32 <= charCode && charCode <= 0x7ffful) {
      #if defined(DEBUG)
        printf("%u %04X \n",glyphIndex, (uint16_t)charCode);
      #endif
      charCodes[numberOfGlyphs++] = charCode;
    }

    charCode = FT_Get_Next_Char(face, charCode, &glyphIndex);
  }

  qsort(charCodes, numberOfGlyphs, sizeof(charCodes[0]), sortCharCodes);

  //////////////////////
  // Face infomations //
  //////////////////////
  #if defined(DEBUG)
    printf("There are %3d glyphs in face 0 of %s\n", numberOfGlyphs,  ttfName);
    printf("ascender=%d descender=%d\n", face->ascender/onePixelSize, face->descender/onePixelSize);
  #endif // DEBUG

  ///////////////////////////////////////
  // Go thru all glyphs to render them //
  ///////////////////////////////////////
  fprintf(cFile, "TO_QSPI const font_t %s = {\n", fontName);
  fprintf(cFile, "  .id             = %d,\n", fontName[0] == 'n' ? 0 : (fontName[0] == 's' ? 1 : 2));
  //fprintf(cFile, "  .name           = \"%s\",\n", fontName);
  //fprintf(cFile, "  .ascender       = %d,\n", face->ascender/onePixelSize);
  //fprintf(cFile, "  .descender      = %d,\n", face->descender/onePixelSize);
  fprintf(cFile, "  .numberOfGlyphs = %d,\n", numberOfGlyphs);
  fprintf(cFile, "  .glyphs = {\n\n");

  pen.x = 0;
  pen.y = (fontHeightPixels - face->ascender/onePixelSize)*64;

  FT_Set_Transform(face, NULL, &pen);
  for(cc=0; cc<numberOfGlyphs; cc++) {
    glyphIndex = FT_Get_Char_Index(face, charCodes[cc]);
    if(glyphIndex == 0) {
      fprintf(stderr, "character code 0x%04x not undefined in %s\n", (unsigned int)charCodes[cc], ttfName);
    }
    else {
      if(cc != 0) {
        fprintf(cFile, ",\n\n");
      }

      FT_Get_Glyph_Name(face, glyphIndex, glyphName, 100);
      #if defined(DEBUG)
        printf("font=%s glyphIndex=%4d   charCode=0x%04x   %s\n", fontName, glyphIndex, (unsigned int)(charCodes[cc]>=0x0080 ? charCodes[cc]|0x8000 : charCodes[cc]), glyphName);
      #endif // DEBUG

      if((error = FT_Load_Glyph(face, glyphIndex, FT_LOAD_RENDER)) != FT_Err_Ok) {
        fprintf(stderr, "warning: failed FT_Load_Glyph 0x%04x\n", (unsigned int)charCodes[cc]);
        fprintf(stderr, "Error %d : %s\n", error, getErrorMessage(error));
      }

      ///////////////////////////////////////////////
      // rank1 and rank2 for standard font sorting //
      ///////////////////////////////////////////////
      if(fontName[0] == 's') { // Standard font
        for(i=0; i<nbGlyphRanks; i++) {
          if(charCodes[cc] == glyphRank[i].codePoint) {
            break;
          }
        }

        if(i >= nbGlyphRanks) {
          fprintf(stderr, "Code point U+%04x is not in file res/fonts/sortingOrder.csv\n", (unsigned int)charCodes[cc]);
          exit(1);
        }

        rank1 = glyphRank[i].rank1;
        rank2 = glyphRank[i].rank2;
      }
      else {
        rank1 = 0;
        rank2 = 0;
      }
      #if defined(DEBUG)
        printf("rank1: %3d    rank2: %3d\n", rank1, rank2);
      #endif // DEBUG

      //////////////////////////
      // Columns in the glyph //
      //////////////////////////
      colsBeforeGlyph = face->glyph->metrics.horiBearingX/64;
      colsGlyph       = face->glyph->bitmap.width;
      colsAfterGlyph  = face->glyph->metrics.horiAdvance/64 - colsBeforeGlyph - colsGlyph;
      if(colsBeforeGlyph < 0) {
        colsGlyph += colsBeforeGlyph;
        colsBeforeGlyph = 0;
      }
      #if defined(DEBUG)
        printf("Columns: Bef=%2d Col=%2d Aft=%2d\n", colsBeforeGlyph, colsGlyph, colsAfterGlyph);
      #endif // DEBUG

      ///////////////////////
      // Rows in the glyph //
      ///////////////////////
      rowsAboveGlyph = face->ascender/onePixelSize - face->glyph->metrics.horiBearingY/64;
      rowsGlyph      = face->glyph->bitmap.rows;
      rowsBelowGlyph = face->glyph->metrics.horiBearingY/64 - face->descender/onePixelSize - rowsGlyph;
      if(rowsAboveGlyph < 0) {
        rowsGlyph += rowsAboveGlyph;
        rowsAboveGlyph = 0;
      }
      #if defined(DEBUG)
        printf("Rows   : %2d %2d %2d\n", rowsAboveGlyph, rowsGlyph, rowsBelowGlyph);
      #endif // DEBUG

      //////////////////////
      // Render the glyph //
      //////////////////////
      fprintf(cFile, "    // %s\n", glyphName);

      fprintf(cFile, "    {.charCode=0x%04x, .colsBeforeGlyph=%2d, .colsGlyph=%2d, .colsAfterGlyph=%2d, .rowsAboveGlyph=%2d, .rowsGlyph=%2d, .rowsBelowGlyph=%2d, .rank1=%3d, .rank2=%3d,\n",
                      (unsigned int)(charCodes[cc]>=0x0080 ? charCodes[cc]|0x8000 : charCodes[cc]), colsBeforeGlyph, colsGlyph, colsAfterGlyph, rowsAboveGlyph, rowsGlyph, rowsBelowGlyph, rank1, rank2);
      fprintf(cFile, "     .data=\"");

      for(y=0; y<rowsGlyph; y++) {
        byte = 0;

        for(x=0; x<colsGlyph; x++) {
          bit = face->glyph->bitmap.buffer[y * face->glyph->bitmap.width + x] >= 128 ? 1 : 0;
          #if defined(DEBUG)
            putchar(bit == 1 ? '#' : '.');
          #endif // DEBUG
          addBit(bit);
        }

        #if defined(DEBUG)
          putchar('\n');
        #endif // DEBUG
        while(numBits != 0) {
          addBit(0);
        }
      }

      fprintf(cFile, "\"}");
    }
  }

  fprintf(cFile, "}\n};\n");

  /////////////////////////////
  // Free the face ressources //
  /////////////////////////////
  FT_Done_Face(face);
}

void processFiles(const char *fontsPath, const char *outputFile) {
  ////////////////
  // Open files //
  ////////////////
  char sortingOrderPath[300];

  sprintf(sortingOrderPath, "xlsxio_xlsx2csv -b %s/sortingOrder.xlsx", fontsPath);
  system(sortingOrderPath);

  sprintf(sortingOrderPath, "%s/sortingOrder.xlsx.sortingOrder.csv", fontsPath);
  sortingOrder = fopen(sortingOrderPath, "rb");
  cFile        = fopen(outputFile, "wb");

  if(sortingOrder == NULL) {
    fprintf(stderr, "Cannot open file %s\n", sortingOrderPath);
    exit(1);
  }

  ////////////////////////////
  // Read the sorting order //
  ////////////////////////////
  nbGlyphRanks = 0;
  ignoreReturnedValue(fgets(line, 500, sortingOrder)); // Header
  ignoreReturnedValue(fgets(line, 500, sortingOrder));
  while(!feof(sortingOrder)) {
    glyphRank[nbGlyphRanks].codePoint = hexToUint(line + 2);

    pos = 7;
    glyphRank[nbGlyphRanks].rank1 = atoi(line + pos);

    while(line[pos++] != ',') ;
    glyphRank[nbGlyphRanks].rank2 = atoi(line + pos);

    nbGlyphRanks++;

    ignoreReturnedValue(fgets(line, 500, sortingOrder));
  }

  fclose(sortingOrder);
  sprintf(sortingOrderPath, "rm -rf %s/sortingOrder.xlsx.sortingOrder.csv", fontsPath);
  system(sortingOrderPath);

  /////////////////////////////////////
  // Initialize the freetype library //
  /////////////////////////////////////
  if((error = FT_Init_FreeType(&library)) != FT_Err_Ok) {
    fprintf(stderr, "Error during freetype2 library initialisation.\n");
    fprintf(stderr, "Error %d : %s\n", error, getErrorMessage(error));
    exit(1);
  }

  fprintf(cFile, "// SPDX-License-Identifier: GPL-3.0-only\n");
  fprintf(cFile, "// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors\n\n");

  fprintf(cFile, "/********************************************//**\n");
  fprintf(cFile, " * \\file rasterFontsData.c C structures of the raster fonts\n");
  fprintf(cFile, " ***********************************************/\n\n");

  fprintf(cFile, "/**********************************************************************************************\n");
  fprintf(cFile, "* Do not edit this file manually! It's automagically generated by the program ttf2RasterFonts *\n");
  fprintf(cFile, "***********************************************************************************************/\n\n");

  fprintf(cFile, "#include \"c47.h\"\n\n");

  ///////////////////////////
  // Generate the C arrays //
  ///////////////////////////
  exportCStructure(fontsPath, "C47__NumericFont.ttf");
  exportCStructure(fontsPath, "C47__StandardFont.ttf");    //JM ^^
  exportCStructure(fontsPath, "C47__TinyFont.ttf");

  fclose(cFile);

  ////////////////////////////////
  // Close the freetype library //
  ////////////////////////////////
  FT_Done_FreeType(library);
}

int main(int argc, char* argv[]) {
  if(argc < 3) {
    printf("Usage: ttf2RasterFonts <font dir> <output file>\n");
    return 1;
  }

  processFiles(argv[1], argv[2]);

  return 0;
}
