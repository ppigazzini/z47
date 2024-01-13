/* This file is part of C47.
 *
 * C47 is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * C47 is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with C47.  If not, see <http://www.gnu.org/licenses/>.
 */



//#define DISPLOADING

#include "c43Extensions/textfiles.h"

#include "charString.h"
#include "c43Extensions/graphText.h"
#include "registers.h"
#include "screen.h"
#include <string.h>
#include "typeDefinitions.h"

#include "c47.h"

typedef struct {
  char     itemName[30];
} nstr;

TO_QSPI static const nstr ClipBoardMsg[] = { 
/*0*/  { "Real matrix " },
/*1*/  { " too large for transfer" },
/*2*/  { "Complex matrix " },
/*3*/  { "res/PROGRAMS" },
/*4*/  { "C43_LOG.TXT" },
/*5*/  { "Alpha buffer: " },
/*6*/  { "XYZTABCDLIJK" }
};



uint8_t reg_Name(int16_t no) {
  return (no>=100 && no<=111) ? ClipBoardMsg[6].itemName[no-100] : 0;

//  switch(no) {
//    case 100: return 'X'; break;
//    case 101: return 'Y'; break;
//    case 102: return 'Z'; break;
//    case 103: return 'T'; break;
//    case 104: return 'A'; break;
//    case 105: return 'B'; break;
//    case 106: return 'C'; break;
//    case 107: return 'D'; break;
//    case 108: return 'L'; break;
//    case 109: return 'I'; break;
//    case 110: return 'J'; break;
//    case 111: return 'K'; break;
//    default:  return 0;   break;
//  }
}


void addChrBothSides(uint8_t t, char * str) {
  char tt[4];
  tt[0] = t;
  tt[1] = 0;
  xcopy(str + 1, str, stringByteLength(str) + 1);
  str[0] = t;
  strcat(str, tt);
}


void addStrBothSides(char * str, char * str_b, char * str_e) {
  xcopy(str + stringByteLength(str_b), str, stringByteLength(str) + 1);
  xcopy(str, str_b, stringByteLength(str_b));
  xcopy(str + stringByteLength(str), str_e, stringByteLength(str_e) + 1);
}


void copyRegisterToClipboardString2(calcRegister_t regist, char *clipboardString) {
  #if !defined(TESTSUITE_BUILD)
    switch(getRegisterDataType(regist)) {
      case dtLongInteger:
      case dtTime:
      case dtDate:
      case dtString:
      case dtShortInteger:
        copyRegisterToClipboardString(regist, clipboardString);
        addChrBothSides(34,clipboardString);   //JMCSV
        break;

      case dtReal34Matrix: {
        dataBlock_t *dblock = REGISTER_REAL34_MATRIX_DBLOCK(regist);
        int rows, columns;
        rows = dblock->matrixRows;
        columns = dblock->matrixColumns;
        if(rows*columns*46 < TMP_STR_LENGTH) {
          copyRegisterToClipboardString(regist, clipboardString);
          //printf(">>>:: %u ?? %u\n",rows*columns*46,stringByteLength(clipboardString));
        }
        else {
          sprintf(clipboardString, "%s%dx%d%s", ClipBoardMsg[0].itemName, rows, columns, ClipBoardMsg[1].itemName);  //Real matrix   too large for transfer
        }
        break;
      }

      case dtComplex34Matrix: {
        dataBlock_t *dblock = REGISTER_REAL34_MATRIX_DBLOCK(regist);
        int rows, columns;
        rows = dblock->matrixRows;
        columns = dblock->matrixColumns;
        if(rows*columns*92 < TMP_STR_LENGTH) {
          copyRegisterToClipboardString(regist, clipboardString);
          //printf(">>>:: %u ?? %u\n", rows*columns*92, stringByteLength(clipboardString));
        }
        else {
          sprintf(clipboardString, "%s%dx%d%s", ClipBoardMsg[2].itemName, rows, columns, ClipBoardMsg[1].itemName);  //Complex matrix   too large for transfer
        }
        break;
      }

      default:
        copyRegisterToClipboardString(regist, clipboardString);
        break;
    }
  #endif // !TESTSUITE_BUILD
}


//USING tmpString !!
void stackregister_csv_out(int16_t reg_b, int16_t reg_e, bool_t oneLine) {
  #if !defined(TESTSUITE_BUILD)
    char tmp_b[100], tmp_e[100];

    int16_t ix = reg_b;
    while(ix <= reg_e) {
      tmpString[0] = 0;
      tmp_b[0] = 0;
      tmp_e[0] = 0;
      if(ix >= 100 && ix <= 111) {
        tmp_b[1] = 0;
        tmp_b[0] = reg_Name(ix);
        strcat(tmp_b, CSV_TAB);
        }

      else if(ix >= 0 && ix <= 99) {
        sprintf(tmp_b, "%sR%02d%s%s", CSV_STR, ix, CSV_STR, CSV_TAB);
      }
      else if(ix >= FIRST_LOCAL_REGISTER && ix <= LAST_LOCAL_REGISTER) {
        sprintf(tmp_b, "%sR.%03d%s%s", CSV_STR, ix-100, CSV_STR, CSV_TAB);
      }
      else if(ix >= FIRST_NAMED_VARIABLE && ix <= LAST_NAMED_VARIABLE) {
        sprintf(tmp_b, "%sN%03d%s%s%s%s%s%s", CSV_STR, ix-100, CSV_STR, CSV_TAB, CSV_STR, (char *)allNamedVariables[ix - FIRST_NAMED_VARIABLE].variableName + 1, CSV_STR, CSV_TAB);
      }

      #if(VERBOSE_LEVEL >= 1)
        print_linestr("-2b", false);
      #endif // VERBOSE_LEVEL >= 1
      
      char tmpString2[TMP_STR_LENGTH];
      copyRegisterToClipboardString2((calcRegister_t)ix, tmpString);
      utf8ToString((uint8_t *)tmpString, tmpString2);
      stringToASCII(tmpString2, tmpString);

      #if(VERBOSE_LEVEL >= 1)
        char tmpTmp[TMP_STR_LENGTH+100];
        sprintf(tmpTmp, "-2c: len=%u:%s", (uint16_t)stringByteLength(tmpString), tmpString);
        print_linestr(tmpTmp, false);
      #endif // VERBOSE_LEVEL >= 1

      if(!oneLine || ix == reg_e) {         //use tabs, except at the last register, use newline
        strcat(tmp_e, CSV_NEWLINE);
      } else {
        strcat(tmp_e, CSV_TAB);
      }

      //printf(">>>: §%s§%s§%s§\n", tmp_b, tmp, tmp_e);
      addStrBothSides(tmpString, tmp_b, tmp_e);
      //printf(">>>: §%s§\n", tmp);

      #if(VERBOSE_LEVEL >= 1)
        sprintf(tmpTmp,"-2d: len=%u:%s", (uint16_t)stringByteLength(tmpString), tmpString);
        print_linestr(tmpTmp, false);
      #endif // VERBOSE_LEVEL >= 1

      export_append_line(tmpString);                    //Output append to CSV file

      #if(VERBOSE_LEVEL >= 1)
        sprintf(tmpString, ":(ix=%u)------->", ix);
        print_linestr(tmpString, false);
      #endif // VERBOSE_LEVEL >= 1

      ++ix;
    }
  #endif // !TESTSUITE_BUILD
}

void aimBuffer_csv_out(void) {
  #if !defined(TESTSUITE_BUILD)
    export_append_line(CSV_STR);                    //Output append to CSV file
    export_append_line(ClipBoardMsg[5].itemName);  //"Alpha buffer: " //Output append to CSV file
    export_append_line(CSV_STR);                    //Output append to CSV file
    export_append_line(CSV_TAB);                    //Output append to CSV file
    export_append_line(CSV_STR);                    //Output append to CSV file
    export_append_line(tmpString);                  //Output append to CSV file    //aimBuffer now in tmpString
    export_append_line(CSV_STR);                    //Output append to CSV file
    export_append_line(CSV_NEWLINE);                //Output append to CSV file
  #endif // !TESTSUITE_BUILD
}


//**********************************************************************************************************
#if !defined(TESTSUITE_BUILD)
  int16_t export_string_to_file(const char line1[TMP_STR_LENGTH]) {
    return export_string_to_filename(line1, APPEND, ClipBoardMsg[3].itemName, ClipBoardMsg[4].itemName);  //"res/PROGRAMS", "C43_LOG.TXT"
  }
#endif // !TESTSUITE_BUILD


//################################################################################################
// OUTPUT is in TMPSTR
void displaywords(char *line1) {  //Preprocessor and display
  char bb[2];
  char aa[2];
  bool_t state_comments = false;
  aa[1] = 0;
  bb[1] = 0;
  bb[0] = 0;

  #if(VERBOSE_LEVEL >= 2)
    print_linestr("Code:", true);
  #endif // VERBOSE_LEVEL >= 2
  //printf("4:%s\n", line1);

  #if(VERBOSE_LEVEL >= 2)
    char tmp[400];          //Messages
    sprintf(tmp, " F: Displaywords: %lu bytes.\n", stringByteLength(line1));
    print_linestr(tmp, false);
    print_linestr(line1, false);
  #endif // VERBOSE_LEVEL >= 2

  if(line1[stringByteLength(line1)-1] != 32) {
    strcat(line1, " ");
  }

  tmpString[0] = 32;
  tmpString[1] =  0;

  int16_t ix = 0;
  while(line1[ix] != 0) {
    aa[0] = line1[ix];
    bb[0] = line1[ix+1];

    if((aa[0]=='/' && bb[0]=='/') && state_comments == false) {         //start comment on double slash
      state_comments = true;
      ix++; //skip the second slash
    }
    else if(state_comments && (aa[0]==13 || aa[0]==10)) {    //stop comment mode at end of line
      state_comments = false;
      strcat(tmpString, " ");
    }
    else if(!state_comments) {                //proceed only if not comment mode
      switch(aa[0]) {
        case ' ':                         //remove all whitespace
        case  8:
        case 13:
        case 10:
        case ',': if(strlen(tmpString) != 0) {
                    if(tmpString[strlen(tmpString)-1] != ' ') {
                      strcat(tmpString, " ");
                    }
                  }
                  break;
        default: strcat(tmpString, aa);
      }
    }

    ix++;
  }
  //printf("5:%s\n", line1);

  #if defined(DISPLOADING)
    char ll[50];
    ll[0] = 0;
  #endif // DISPLOADING
  aa[0] = 0;
  aa[1] = 0;                  //remove consequtive spaces
  ix = 1;
  line1[0] = 0;
  while(tmpString[ix] != 0) {
    aa[0] = tmpString[ix];
    if(tmpString[ix-1] != ' ') {
      strcat(line1, aa);
      #if defined(DISPLOADING)
        strcat(ll, aa);
        if(strlen(ll) > 30 && aa[0] == ' ') {
          #if(VERBOSE_LEVEL >= 2)
            print_linestr(ll, false);
          #endif
          ll[0] = 0;
        }
      #endif // DISPLOADING
    }
    else {
      if(aa[0] != ' ') {
        strcat(line1, aa);
        #if defined(DISPLOADING)
          strcat(ll, aa);
          if(strlen(ll) > 36) {
            #if(VERBOSE_LEVEL >= 2)
              print_linestr(ll, false);
            #endif // VERBOSE_LEVEL >= 2
            ll[0] = 0;
          }
        #endif // DISPLOADING
      }
    }
    ix++;
  }
  #if defined(DISPLOADING)
  if(ll[0] != 0) {
    #if(VERBOSE_LEVEL >= 2)
      print_linestr(ll, false);
    #endif
  }
  #endif // DISPLOADING
//printf("6:%s\n", line1);
}


uint32_t t_line_x, t_line_y;

void print_inlinestr(const char *line1, bool_t endline) {
  #if !defined(TESTSUITE_BUILD)
    char l1[100];    //Clip the string at 40
    l1[0] = 0;
    int16_t ix = 0;
    int16_t ixx;
    ixx = stringByteLength(line1);
    while(ix < ixx && ix < 98 && t_line_x + stringWidth(l1, &standardFont, true, true) < SCREEN_WIDTH-12) {
      xcopy(l1, line1, ix+1);
      l1[ix+1] = 0;
      ix = stringNextGlyph(line1, ix);
    }
    if(t_line_y < SCREEN_HEIGHT) {
      t_line_x = showString(l1, &standardFont, t_line_x, t_line_y, vmNormal, true, true);
    }
    if(endline) {
      t_line_y += 20;
      t_line_x = 0;
    }
    force_refresh(force);
  #endif // !TESTSUITE_BUILD
}


void print_Register_line(calcRegister_t regist, char *before, char *after, bool_t line_init) {
  #if !defined(TESTSUITE_BUILD)
    char str[TMP_STR_LENGTH];

    copyRegisterToClipboardString2(regist, str);
    addStrBothSides(str, before, after);

    print_numberstr(str, line_init);
  #endif // !TESTSUITE_BUILD
}
