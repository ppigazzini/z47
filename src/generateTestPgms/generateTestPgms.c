// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

static uint8_t * _insertItem( int32_t item, uint8_t *currentStep) {
  if(item < 128) {
    *(currentStep++) = item;
  }
  else {
    *(currentStep++) = (item>> 8) | 0x80;
    *(currentStep++) =  item      & 0xff;
  }
  return currentStep;
}

int main(int argc, char* argv[]) {
  uint8_t memory[65536], *currentStep;
  FILE *testPgms;
  uint32_t sizeOfPgms;

  if(argc < 2) {
    printf("Usage: generateTestPgms <output file>\n");
    return 1;
  }

  memset(memory, 0, 65536);
  currentStep = memory;

  { // Prime number checker
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 5; // String length
    *(currentStep++) = 'P';
    *(currentStep++) = 'r';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_IP;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_SQUAREROOTX;

    *(currentStep++) = ITM_IP;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 1;

    // 10
    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 2;

    // 20
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 30
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 40
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 50
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 60
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 70
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 80
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 90
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 100
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    // 110
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_XLT;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 2;

    // 120
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_MOD;

    *(currentStep++) = ITM_XNE;
    *(currentStep++) = VALUE_0;

    *(currentStep++) = ITM_RTN;

    // 130
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_STOP;

    // 133
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len1
    // 1
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len2
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '2';

    // 2
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len3
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    // 3
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len4
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 3;

    // 4
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len5
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 4;

    // 5
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len6
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 4;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 5;

    // 6
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len7
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 4;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 5;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 6;

    // 7
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Len8
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'e';
    *(currentStep++) = 'n';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 4;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 5;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 6;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 7;

    // 8
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Bairstow polynomial root finder; Edits and corrections by L Locklear, entered by JM
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; // String length
    *(currentStep++) = 'B';
    *(currentStep++) = 'a';
    *(currentStep++) = 'i';
    *(currentStep++) = 'r';
    *(currentStep++) = 's';
    *(currentStep++) = 't';
    *(currentStep++) = 'o';

    *(currentStep++) = (ITM_ALL >> 8) | 0x80;
    *(currentStep++) =  ITM_ALL       & 0xff;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_CLCVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_CLCVAR       & 0xff;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 19; // String length
    *(currentStep++) = 'P';
    *(currentStep++) = 'o';
    *(currentStep++) = 'l';
    *(currentStep++) = 'y';
    *(currentStep++) = 'n';
    *(currentStep++) = 'o';
    *(currentStep++) = 'm';
    *(currentStep++) = 'i';
    *(currentStep++) = 'a';
    *(currentStep++) = 'l';
    *(currentStep++) = ' ';
    *(currentStep++) = 'd';
    *(currentStep++) = 'e';
    *(currentStep++) = 'g';
    *(currentStep++) = 'r';
    *(currentStep++) = 'e';
    *(currentStep++) = 'e';
    *(currentStep++) = ' ';
    *(currentStep++) = '?';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_IP;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 90;

    // 10
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'A' - 'A'; // A

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = 'x';
    *(currentStep++) = '^';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_ADD;

    // 20
    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STOSUB;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'A' - 'A'; // A

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    // 30
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_XNE;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 100 + 'B' - 'A'; // B

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 10; // String length
    *(currentStep++) = 'T';
    *(currentStep++) = 'o';
    *(currentStep++) = 'l';
    *(currentStep++) = 'e';
    *(currentStep++) = 'r';
    *(currentStep++) = 'a';
    *(currentStep++) = 'n';
    *(currentStep++) = 'c';
    *(currentStep++) = 'e';
    *(currentStep++) = '?';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 99;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 10;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '3';

    // 40
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_XLT;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 96;

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 100 + 'D' - 'A'; // D

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 59;

    // 50
    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 11;

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 10;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_XNE;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    // 60
    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 12;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 13;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 9; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'a';
    *(currentStep++) = 's';
    *(currentStep++) = 't';
    *(currentStep++) = ' ';
    *(currentStep++) = 'r';
    *(currentStep++) = 'o';
    *(currentStep++) = 'o';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'B' - 'A'; // B

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 93;

    // 70
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'C' - 'A'; // C

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_STODIV;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    // 80
    *(currentStep++) = ITM_ISG;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'C' - 'A'; // C

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'D' - 'A'; // D

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 97;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 98;

    // 90
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 58;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 89;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '3';
    *(currentStep++) = '0';

    // 100
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    // 110
    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'E' - 'A'; // E

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    // 120
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 96;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 89;

    // 130
    *(currentStep++) = ITM_ISG;
    *(currentStep++) = 89;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'E' - 'A'; // E

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 84;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 85;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '3';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '3';

    // 140
    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 89;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '6';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 93;

    // 150
    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 55;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    // 160
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 96;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    // 170
    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 89;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = 89;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 55;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 93;

    // 180
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 93;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 96;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    // 190
    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 84;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 85;

    // 200
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 87;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 96;

    // 210
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 84;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 85;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 88;

    // 220
    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 86;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 87;

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 86;

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_XGT;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 56;

    // 230
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 87;

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 97;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 57;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 56;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 86;

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 97;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 57;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 87;

    // 240
    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 86;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 96;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 98;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 98;

    *(currentStep++) = ITM_XGT;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 4;

    // 250
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 99;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 97;

    *(currentStep++) = ITM_XGT;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 58;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 59;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '3';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    // 260
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 93;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 91;

    // 270
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = 94;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 90;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 90;

    // 280
    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 11;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 95;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 96;

    // 290
    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_SQUAREROOTX;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_SQUAREROOTX;

    // 300
    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 12;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 12; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '.';
    *(currentStep++) = '.';
    *(currentStep++) = ' ';
    *(currentStep++) = 'c';
    *(currentStep++) = 'o';
    *(currentStep++) = 'n';
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'n';
    *(currentStep++) = 'u';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    // 310
    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 92;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_SQUAREROOTX;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    // 320
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 92;

    *(currentStep++) = ITM_SQUAREROOTX;

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 13;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 12; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '.';
    *(currentStep++) = '.';
    *(currentStep++) = ' ';
    *(currentStep++) = 'c';
    *(currentStep++) = 'o';
    *(currentStep++) = 'n';
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'n';
    *(currentStep++) = 'u';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_CHS;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 91;

    // 330
    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 91;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 4;

    *(currentStep++) = (ITM_CLSTK >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSTK       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++)= STRING_LABEL_VARIABLE;
    *(currentStep++) = 11; // String length
    *(currentStep++) = 'E';
    *(currentStep++) = 'r';
    *(currentStep++) = 'r';
    *(currentStep++) = 'o';
    *(currentStep++) = 'r';
    *(currentStep++) = ' ';
    *(currentStep++) = 'm';
    *(currentStep++) = '>';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '!';

    *(currentStep++) = ITM_RTN;

    // 337
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Speed test. See: https://forum.swissmicros.com/viewtopic.php?p=17308
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 5; // String length
    *(currentStep++) = 'S';
    *(currentStep++) = 'p';
    *(currentStep++) = 'e';
    *(currentStep++) = 'e';
    *(currentStep++) = 'd';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 10;

    *(currentStep++) = (ITM_TICKS >> 8) | 0x80;
    *(currentStep++) =  ITM_TICKS       & 0xff;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 11;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 12;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    // 10
    *(currentStep++) = ITM_arctan;

    *(currentStep++) = ITM_sin;

    *(currentStep++) = ITM_EXP;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '3';

    *(currentStep++) = ITM_1ONX;

    *(currentStep++) = ITM_YX;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = 11;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 12;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_ADD;

    // 20
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 12;

    *(currentStep++) = ITM_DSE;
    *(currentStep++) = 10;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_TICKS >> 8) | 0x80;
    *(currentStep++) =  ITM_TICKS       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_DIV;

    // 28
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Factorial: the recursive way ReM page 261
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; // String length
    *(currentStep++) = 'R';
    *(currentStep++) = 'e';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'F';
    *(currentStep++) = 'a';
    *(currentStep++) = 'c';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_IP;

    *(currentStep++) = ITM_XGT;
    *(currentStep++) = VALUE_1;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_LocR >> 8) | 0x80;
    *(currentStep++) =  ITM_LocR       & 0xff;
    *(currentStep++) = 1;

    // 10
    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE; // .00

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'F';
    *(currentStep++) = 'a';
    *(currentStep++) = 'c';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE; // .00

    *(currentStep++) = ITM_RTN;

    // 15
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 209
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_CONSTpi;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RTN;

    // 6
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // STAT GR1 GRAPH1 TEST
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = 'g';
    *(currentStep++) = 'r';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;
    *(currentStep++) = (ITM_RAD >> 8)     | 0x80;
    *(currentStep++) =  ITM_RAD           & 0xff;
    *(currentStep++) = (ITM_dotD >> 8)    | 0x80;
    *(currentStep++) =  ITM_dotD          & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 1;
    *(currentStep++) = ITM_STO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

      *(currentStep++) = ITM_RCL;
      *(currentStep++) = 2;
      *(currentStep++) = ITM_RCL;
      *(currentStep++) = 1;
      *(currentStep++) = ITM_SUB;

        *(currentStep++) = ITM_RCL;
        *(currentStep++) = 2;
        *(currentStep++) = ITM_DECR;
        *(currentStep++) = 100; //X

        *(currentStep++) = ITM_LITERAL;
        *(currentStep++) = STRING_LONG_INTEGER;
        *(currentStep++) = 1;  // String length
        *(currentStep++) = '2';

        *(currentStep++) = ITM_IDIV;
        *(currentStep++) = ITM_DIV;

        *(currentStep++) = ITM_LITERAL;
        *(currentStep++) = STRING_LONG_INTEGER;
        *(currentStep++) = 1;  // String length
        *(currentStep++) = '1';
        *(currentStep++) = ITM_SUB;
        *(currentStep++) = ITM_LITERAL;
        *(currentStep++) = STRING_LONG_INTEGER;
        *(currentStep++) = 1;  // String length
        *(currentStep++) = '5';
        *(currentStep++) = ITM_MULT;
        *(currentStep++) = ITM_CONSTpi;
        *(currentStep++) = ITM_MULT;
        *(currentStep++) = ITM_ENTER;

        *(currentStep++) = (ITM_sinc >> 8)       | 0x80;
        *(currentStep++) =  ITM_sinc             & 0xff;
        *(currentStep++) = ITM_XexY;                        //swap the stack x, y
        *(currentStep++) = (ITM_SIGMAPLUS >> 8)  | 0x80;    //Enter stats pair incorrectly oriented x<>y
        *(currentStep++) =  ITM_SIGMAPLUS        & 0xff;

      *(currentStep++) = ITM_DSZ;
      *(currentStep++) = 1;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_T_LINF >> 8)      | 0x80;
    *(currentStep++) =  ITM_T_LINF            & 0xff;
    *(currentStep++) = (ITM_PLOT_ASSESS >> 8)   | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS         & 0xff;
    *(currentStep++) = (ITM_PLOT_NXT >> 8)  | 0x80;
    *(currentStep++) =  ITM_PLOT_NXT        & 0xff;
    *(currentStep++) = ITM_STOP;

    *(currentStep++) = (ITM_T_PARABF >> 8)    | 0x80;
    *(currentStep++) =  ITM_T_PARABF          & 0xff;
    *(currentStep++) = (ITM_PLOT_ASSESS >> 8)   | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS         & 0xff;
    *(currentStep++) = ITM_STOP;


    *(currentStep++) = ITM_RTN;
    // 6
    *(currentStep++) = (ITM_END >> 8)       | 0x80;
    *(currentStep++) =  ITM_END             & 0xff;

  }

  { // OM page 212
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'K';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'r';

    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_CONSTpi;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'B';
    *(currentStep++) = 'A';
    *(currentStep++) = 'S';
    *(currentStep++) = 'e';                       //C47 mod JM

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_SIGMA[0];
    *(currentStep++) = STD_SIGMA[1];
    *(currentStep++) = 'B';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'B';
    *(currentStep++) = 'A';
    *(currentStep++) = 'S';
    *(currentStep++) = 'e';                       //C47 mod JM

    // 10
    *(currentStep++) = ITM_INPUT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'h';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'V';
    *(currentStep++) = 'O';
    *(currentStep++) = 'L';
    *(currentStep++) = 'U';
    *(currentStep++) = 'M';
    *(currentStep++) = 'E';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_SIGMA[0];
    *(currentStep++) = STD_SIGMA[1];
    *(currentStep++) = 'V';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'V';
    *(currentStep++) = 'O';
    *(currentStep++) = 'L';
    *(currentStep++) = 'U';
    *(currentStep++) = 'M';
    *(currentStep++) = 'E';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'r';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'B';
    *(currentStep++) = 'A';
    *(currentStep++) = 'S';
    *(currentStep++) = 'e';                       //C47 mod JM

    // 20
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_SIGMA[0];
    *(currentStep++) = STD_SIGMA[1];
    *(currentStep++) = 'S';

    *(currentStep++) = ITM_RTN;

    // 25
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 224
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'X';

    *(currentStep++) = (ITM_RAN >> 8) | 0x80;
    *(currentStep++) =  ITM_RAN       & 0xff;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 24;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = 24;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'X';

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'Y';

    *(currentStep++) = (ITM_LocR >> 8) | 0x80;
    *(currentStep++) =  ITM_LocR       & 0xff;
    *(currentStep++) = 2;

    // 10
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'A' - 'A'; // A

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 24;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 100; // X

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    *(currentStep++) = ITM_CF;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'C' - 'A'; // C

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    *(currentStep++) = ITM_XLT;
    *(currentStep++) = 101; // Y

    // 20
    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'B' - 'A'; // B

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'D' - 'A'; // D

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'C' - 'A'; // C

    *(currentStep++) = ITM_FS;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'A' - 'A'; // A

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'B' - 'A'; // B

    *(currentStep++) = ITM_SF;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    // 30
    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'D' - 'A'; // D

    // 35
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 226
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'Z';

    *(currentStep++) = (ITM_SIGN >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGN       & 0xff;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'A' - 'A'; // A

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_L_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_L_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_L_IN_KS_CODE;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'B' - 'A'; // B

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    // 10
    *(currentStep++) = ITM_XGT;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'C' - 'A'; // C

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_L_IN_KS_CODE;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 100 + 'C' - 'A'; // C

    *(currentStep++) = ITM_Rdown;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'B' - 'A'; // B

    *(currentStep++) = ITM_Xex;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_L_IN_KS_CODE;

    // 20
    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_Z_IN_KS_CODE;

    *(currentStep++) = ITM_ISG;
    *(currentStep++) = REGISTER_L_IN_KS_CODE;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 100 + 'A' - 'A'; // A

    // 23
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 233
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 5; // String length
    *(currentStep++) = 'P';
    *(currentStep++) = 'F';
    *(currentStep++) = 'a';
    *(currentStep++) = 'l';
    *(currentStep++) = 'l';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'b';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    // 10
    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    *(currentStep++) = (CST_18 >> 8) | 0x80;
    *(currentStep++) =  CST_18       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'b';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    // 20
    *(currentStep++) = ITM_XGT;
    *(currentStep++) = VALUE_0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_DROP;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_DROP;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    // 30
    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOSUB;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    // 40
    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    // 42
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 235
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 's';
    *(currentStep++) = 'c';
    *(currentStep++) = 'i';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_alpha[0];
    *(currentStep++) = STD_alpha[1];

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_beta[0];
    *(currentStep++) = STD_beta[1];

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    // 10
    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_gamma[0];
    *(currentStep++) = STD_gamma[1];

    *(currentStep++) = (ITM_RAD >> 8) | 0x80;
    *(currentStep++) =  ITM_RAD       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_omega[0];
    *(currentStep++) = STD_omega[1];

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    // 20
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_omega[0];
    *(currentStep++) = STD_omega[1];

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_sin;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_gamma[0];
    *(currentStep++) = STD_gamma[1];

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_beta[0];
    *(currentStep++) = STD_beta[1];

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_SUB;

    // 30
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 2; // String length
    *(currentStep++) = STD_alpha[0];
    *(currentStep++) = STD_alpha[1];

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_SUB;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_XGT;
    *(currentStep++) = VALUE_0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_DROP;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    // 40
    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_DROP;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOSUB;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    // 50
    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'f';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'f';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    // 57
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 237
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'O';
    *(currentStep++) = 'M';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'S';
    *(currentStep++) = 'a';
    *(currentStep++) = 't';
    *(currentStep++) = 'e';
    *(currentStep++) = 'l';
    *(currentStep++) = 'l';

    *(currentStep++) = ITM_INPUT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_INPUT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'y';

    *(currentStep++) = ITM_INPUT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'x';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_INPUT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'y';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    // 10
    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'a';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'y';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'y';

    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_SQUARE;

    *(currentStep++) = ITM_ADD;

    // 20
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; // String length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_YX;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'a';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 108; // L

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_XGT;
    *(currentStep++) = VALUE_0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_DROP;

    // 30
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 3;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_DROP;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 3;

    // 40
    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOSUB;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'x';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_DROP;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOSUB;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'y';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'x';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    // 50
    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_DELTA[0];
    *(currentStep++) = STD_DELTA[1];
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'd';
    *(currentStep++) = 'y';
    *(currentStep++) = '\x80';
    *(currentStep++) = '\xf7';
    *(currentStep++) = 'd';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'y';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'y';

    *(currentStep++) = ITM_STOP;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    // 57
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 247 (for Σn)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = STD_SIGMA[0];
    *(currentStep++) = STD_SIGMA[1];
    *(currentStep++) = 'V';

    *(currentStep++) = ITM_SQUAREROOTX;

    *(currentStep++) = ITM_RTN;

    // 4
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 248 (for Πn)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'P';
    *(currentStep++) = 'R';
    *(currentStep++) = 'O';
    *(currentStep++) = 'D';

    *(currentStep++) = ITM_SQUAREROOTX;

    *(currentStep++) = ITM_1ONX;

    *(currentStep++) = ITM_RTN;

    // 5
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 256 (for solver)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 5; // String length
    *(currentStep++) = 'F';
    *(currentStep++) = 'r';
    *(currentStep++) = 'e';
    *(currentStep++) = 'e';
    *(currentStep++) = 'F';

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = 'e';
    *(currentStep++) = 'i';
    *(currentStep++) = 'g';
    *(currentStep++) = 'h';
    *(currentStep++) = 't';

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'v';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = (CST_18 >> 8) | 0x80;
    *(currentStep++) =  CST_18       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '-';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    // 10
    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'v';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = ITM_RCLSUB;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = 'e';
    *(currentStep++) = 'i';
    *(currentStep++) = 'g';
    *(currentStep++) = 'h';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RTN;

    // 15
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // No root (Const)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; // String length
    *(currentStep++) = 'S';
    *(currentStep++) = 'l';
    *(currentStep++) = 'v';
    *(currentStep++) = 'C';
    *(currentStep++) = 'n';
    *(currentStep++) = 's';
    *(currentStep++) = 't';

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '3';

    *(currentStep++) = ITM_RTN;

    // 5
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // No root (Extremum)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; // String length
    *(currentStep++) = 'S';
    *(currentStep++) = 'l';
    *(currentStep++) = 'v';
    *(currentStep++) = 'E';
    *(currentStep++) = 'x';
    *(currentStep++) = 't';
    *(currentStep++) = 'r';

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RTN;

    // 8
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 258 (for solver)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'F';
    *(currentStep++) = 'r';
    *(currentStep++) = 'e';
    *(currentStep++) = 'e';
    *(currentStep++) = 'F';
    *(currentStep++) = 'p';

    *(currentStep++) = (CST_18 >> 8) | 0x80;
    *(currentStep++) =  CST_18       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '-';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'v';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = ITM_RCLSUB;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = 'e';
    *(currentStep++) = 'i';
    *(currentStep++) = 'g';
    *(currentStep++) = 'h';
    *(currentStep++) = 't';

    // 10
    *(currentStep++) = ITM_RTN;

    // 11
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 258 (calls the equation above)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'F';
    *(currentStep++) = 'r';
    *(currentStep++) = 'e';
    *(currentStep++) = 'F';
    *(currentStep++) = 'p';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = 'e';
    *(currentStep++) = 'i';
    *(currentStep++) = 'g';
    *(currentStep++) = 'h';
    *(currentStep++) = 't';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '5';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'h';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'v';
    *(currentStep++) = STD_SUB_0[0];
    *(currentStep++) = STD_SUB_0[1];

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '5';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    // 10
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_PGMSLV >> 8) | 0x80;
    *(currentStep++) =  ITM_PGMSLV       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'F';
    *(currentStep++) = 'r';
    *(currentStep++) = 'e';
    *(currentStep++) = 'e';
    *(currentStep++) = 'F';
    *(currentStep++) = 'p';

    *(currentStep++) = (ITM_SOLVE >> 8) | 0x80;
    *(currentStep++) =  ITM_SOLVE       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 't';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';
    *(currentStep++) = 'e';

    *(currentStep++) = ITM_RTN;

    // 15
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 263 (for integrator)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'I';
    *(currentStep++) = 'B';
    *(currentStep++) = 'e';
    *(currentStep++) = 's';
    *(currentStep++) = 's';
    *(currentStep++) = 'I';

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = (ITM_MVAR >> 8) | 0x80;
    *(currentStep++) =  ITM_MVAR       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_sin;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_cos;

    *(currentStep++) = ITM_RTN;

    // 9
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 265 (for integrator)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'I';
    *(currentStep++) = 'B';
    *(currentStep++) = 'e';
    *(currentStep++) = 's';
    *(currentStep++) = 's';
    *(currentStep++) = 'P';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_sin;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 'x';

    *(currentStep++) = ITM_cos;

    *(currentStep++) = ITM_RTN;

    // 7
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // OM page 265 (calls the equation above)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'I';
    *(currentStep++) = 'n';
    *(currentStep++) = 't';
    *(currentStep++) = 'P';

    *(currentStep++) = (ITM_RAD >> 8) | 0x80;
    *(currentStep++) =  ITM_RAD       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = (ITM_PGMINT >> 8) | 0x80;
    *(currentStep++) =  ITM_PGMINT       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'I';
    *(currentStep++) = 'B';
    *(currentStep++) = 'e';
    *(currentStep++) = 's';
    *(currentStep++) = 's';
    *(currentStep++) = 'P';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 5; // String length
    *(currentStep++) = STD_DOWN_ARROW[0];
    *(currentStep++) = STD_DOWN_ARROW[1];
    *(currentStep++) = 'L';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';

    // 10
    *(currentStep++) = ITM_CONSTpi;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 5; // String length
    *(currentStep++) = STD_UP_ARROW[0];
    *(currentStep++) = STD_UP_ARROW[1];
    *(currentStep++) = 'L';
    *(currentStep++) = 'i';
    *(currentStep++) = 'm';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 5;  // String length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'A';
    *(currentStep++) = 'C';
    *(currentStep++) = 'C';

    *(currentStep++) = (ITM_INTEGRAL >> 8) | 0x80;
    *(currentStep++) =  ITM_INTEGRAL       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 1; // String length
    *(currentStep++) = 't';

    *(currentStep++) = ITM_VIEW;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_CONSTpi;

    *(currentStep++) = ITM_DIV;

    // 16
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Elementary cellular automaton (for testing AGRAPH) [VERY SLOW ON DMCP]
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 3; // String length
    *(currentStep++) = 'E';
    *(currentStep++) = 'C';
    *(currentStep++) = 'A';

    *(currentStep++) = (ITM_UNSIGN >> 8) | 0x80;
    *(currentStep++) =  ITM_UNSIGN       & 0xff;

    *(currentStep++) = (ITM_WSIZE >> 8) | 0x80;
    *(currentStep++) =  ITM_WSIZE       & 0xff;
    *(currentStep++) = 64;

    *(currentStep++) = (ITM_INPUT >> 8) | 0x80;
    *(currentStep++) =  ITM_INPUT       & 0xff;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; // String length
    *(currentStep++) = 'R';
    *(currentStep++) = 'U';
    *(currentStep++) = 'L';
    *(currentStep++) = 'E';

    *(currentStep++) = (ITM_toINT >> 8) | 0x80;
    *(currentStep++) =  ITM_toINT       & 0xff;
    *(currentStep++) = 10;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = REGISTER_K_IN_KS_CODE;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_CLLCD >> 8) | 0x80;
    *(currentStep++) =  ITM_CLLCD       & 0xff;

    // 10
    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; // String length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 40;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_CLX;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 40;

    *(currentStep++) = ITM_IP;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 7;

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    // 20
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '6';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = REGISTER_Z_IN_KS_CODE;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 8;

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '6';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = REGISTER_Z_IN_KS_CODE;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 9;

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    // 30
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '6';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = REGISTER_Z_IN_KS_CODE;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 10;

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_PAUSE;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_ISE;
    *(currentStep++) = 40;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 70;

    // 40
    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 71;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 70;

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 71;

    *(currentStep++) = ITM_PAUSE;
    *(currentStep++) = 99;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 44;

    // 50
    *(currentStep++) = ITM_Rdown;

    *(currentStep++) = ITM_FC;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 50;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 55;

    *(currentStep++) = ITM_XEQ;
    *(currentStep++) = 51;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_Rdown;

    *(currentStep++) = ITM_DSL;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 55;

    *(currentStep++) = ITM_RTN;

    // 60
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 50;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_SHORT_INTEGER;
    *(currentStep++) = 16; // Base
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 56;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_DSL;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 56;

    *(currentStep++) = ITM_Rdown;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_SHORT_INTEGER;
    *(currentStep++) = 16; // Base
    *(currentStep++) = 15;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 8;

    *(currentStep++) = ITM_Rdown;

    // 70
    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 51;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '6';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_2X;

    *(currentStep++) = (ITM_RAN >> 8) | 0x80;
    *(currentStep++) =  ITM_RAN       & 0xff;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = (ITM_toINT >> 8) | 0x80;
    *(currentStep++) =  ITM_toINT       & 0xff;
    *(currentStep++) = 16;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_Xex;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    // 80
    *(currentStep++) = (ITM_Yex >> 8) | 0x80;
    *(currentStep++) =  ITM_Yex       & 0xff;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 5; // String length
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 65;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_SHORT_INTEGER;
    *(currentStep++) = 16; // Base
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_DSL;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 65;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 45;

    // 90
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '2';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 66;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '6';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 63;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_SHORT_INTEGER;
    *(currentStep++) = 16; // Base
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '3';

    // 100
    *(currentStep++) = ITM_SF;
    *(currentStep++) = FLAG_C;

    *(currentStep++) = (ITM_RLC >> 8) | 0x80;
    *(currentStep++) =  ITM_RLC       & 0xff;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_RL >> 8) | 0x80;
    *(currentStep++) =  ITM_RL       & 0xff;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_RR >> 8) | 0x80;
    *(currentStep++) =  ITM_RR       & 0xff;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_2X;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_K_IN_KS_CODE;

    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_SR >> 8) | 0x80;
    *(currentStep++) =  ITM_SR       & 0xff;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    // 110
    *(currentStep++) = (ITM_SL >> 8) | 0x80;
    *(currentStep++) =  ITM_SL       & 0xff;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_LOGICALOR;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_DSL;
    *(currentStep++) = 88;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 63;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_DSL;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 66;

    // 120
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1; // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '2';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2; // String length
    *(currentStep++) = '1';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 67;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 45;

    *(currentStep++) = (ITM_MASKL >> 8) | 0x80;
    *(currentStep++) =  ITM_MASKL       & 0xff;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LOGICALAND;

    // 130
    *(currentStep++) = (ITM_SR >> 8) | 0x80;
    *(currentStep++) =  ITM_SR       & 0xff;
    *(currentStep++) = 62;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = 45;

    *(currentStep++) = (ITM_MASKR >> 8) | 0x80;
    *(currentStep++) =  ITM_MASKR       & 0xff;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_SL >> 8) | 0x80;
    *(currentStep++) =  ITM_SL       & 0xff;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LOGICALOR;

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_2X;

    // 140
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_K_IN_KS_CODE;

    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_SR >> 8) | 0x80;
    *(currentStep++) =  ITM_SR       & 0xff;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = (ITM_SL >> 8) | 0x80;
    *(currentStep++) =  ITM_SL       & 0xff;
    *(currentStep++) = 63;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 46;

    *(currentStep++) = (ITM_CB >> 8) | 0x80;
    *(currentStep++) =  ITM_CB       & 0xff;
    *(currentStep++) = 63;

    *(currentStep++) = ITM_LOGICALOR;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 45;

    *(currentStep++) = (ITM_MASKL >> 8) | 0x80;
    *(currentStep++) =  ITM_MASKL       & 0xff;
    *(currentStep++) = 1;

    // 150
    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_SR >> 8) | 0x80;
    *(currentStep++) =  ITM_SR       & 0xff;
    *(currentStep++) = 63;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 45;

    *(currentStep++) = ITM_DECR;
    *(currentStep++) = 45;

    *(currentStep++) = (ITM_MASKR >> 8) | 0x80;
    *(currentStep++) =  ITM_MASKR       & 0xff;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_SL >> 8) | 0x80;
    *(currentStep++) =  ITM_SL       & 0xff;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_LOGICALOR;

    *(currentStep++) = ITM_ENTER;

    // 160
    *(currentStep++) = ITM_2X;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_K_IN_KS_CODE;

    *(currentStep++) = ITM_LOGICALAND;

    *(currentStep++) = (ITM_SR >> 8) | 0x80;
    *(currentStep++) =  ITM_SR       & 0xff;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 46;

    *(currentStep++) = (ITM_CB >> 8) | 0x80;
    *(currentStep++) =  ITM_CB       & 0xff;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LOGICALOR;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = INDIRECT_REGISTER;
    *(currentStep++) = 46;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = 45;

    // 170
    *(currentStep++) = ITM_DSL;
    *(currentStep++) = 44;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 67;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 5; // String length
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '8';

    *(currentStep++) = (ITM_R_COPY >> 8) | 0x80;
    *(currentStep++) =  ITM_R_COPY       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    *(currentStep++) = ITM_RTN;

    // 177
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Another test for AGRAPH
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; // String length
    *(currentStep++) = 'P';
    *(currentStep++) = 'I';
    *(currentStep++) = 'C';
    *(currentStep++) = 'T';
    *(currentStep++) = 'U';
    *(currentStep++) = 'R';
    *(currentStep++) = 'E';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = BINARY_SHORT_INTEGER;
    *(currentStep++) = 16; // Base
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;
    *(currentStep++) = 0xff;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = BINARY_SHORT_INTEGER;
    *(currentStep++) = 16; // Base
    *(currentStep++) = 0x01;
    *(currentStep++) = 0x00;
    *(currentStep++) = 0x00;
    *(currentStep++) = 0x00;
    *(currentStep++) = 0x00;
    *(currentStep++) = 0x00;
    *(currentStep++) = 0x00;
    *(currentStep++) = 0x80;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 2;  // String length
    *(currentStep++) = '6';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ENTER;

    // 10
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_CLLCD >> 8) | 0x80;
    *(currentStep++) =  ITM_CLLCD       & 0xff;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 1;

    *(currentStep++) = ITM_DSE;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_AGRAPH >> 8) | 0x80;
    *(currentStep++) =  ITM_AGRAPH       & 0xff;
    *(currentStep++) = 0;

    // 20
    *(currentStep++) = ITM_RTN;

    // 21
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Logarithmic spiral (test for POINT)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'S';
    *(currentStep++) = 'P';
    *(currentStep++) = 'I';
    *(currentStep++) = 'R';
    *(currentStep++) = 'A';
    *(currentStep++) = 'L';

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    *(currentStep++) = ITM_XEQU;
    *(currentStep++) = VALUE_0;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '.';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_XEQU;
    *(currentStep++) = VALUE_0;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_MAGNITUDE;

    // 10
    *(currentStep++) = ITM_STO;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = (ITM_LocR >> 8) | 0x80;
    *(currentStep++) =  ITM_LocR       & 0xff;
    *(currentStep++) = 4;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = (ITM_CLLCD >> 8) | 0x80;
    *(currentStep++) =  ITM_CLLCD       & 0xff;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    // 20
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4;  // String length
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '.';

    *(currentStep++) = ITM_DIV;

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_RAD2;

    *(currentStep++) = ITM_sin;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_EXP;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    // 30
    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_RAD2;

    *(currentStep++) = ITM_cos;

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_EXP;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 2;



    // 40
    *(currentStep++) = (ITM_toPOL2 >> 8) | 0x80;
    *(currentStep++) =  ITM_toPOL2       & 0xff;

    *(currentStep++) = ITM_FC;
    *(currentStep++) = SYSTEM_FLAG_NUMBER;
    *(currentStep++) = FLAG_HPRP & 0xff;
    *(currentStep++) = ITM_XexY;


    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 3;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XLE;
    *(currentStep++) = REGISTER_Y_IN_KS_CODE;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = (ITM_ROUNDI2 >> 8) | 0x80;
    *(currentStep++) =  ITM_ROUNDI2       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 2;

    // 50
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = (ITM_ROUNDI2 >> 8) | 0x80;
    *(currentStep++) =  ITM_ROUNDI2       & 0xff;

    *(currentStep++) = ITM_SF;
    *(currentStep++) = SYSTEM_FLAG_NUMBER;
    *(currentStep++) = FLAG_IGN1ER & 0xff;

    *(currentStep++) = (ITM_POINT >> 8) | 0x80;
    *(currentStep++) =  ITM_POINT       & 0xff;

    *(currentStep++) = ITM_CF;
    *(currentStep++) = SYSTEM_FLAG_NUMBER;
    *(currentStep++) = FLAG_IGN1ER & 0xff;

    *(currentStep++) = ITM_PAUSE;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 3;

    *(currentStep++) = ITM_1ONX;

    *(currentStep++) = (ITM_SDL >> 8) | 0x80;
    *(currentStep++) =  ITM_SDL       & 0xff;
    *(currentStep++) = 3;

    // 60
    *(currentStep++) = ITM_IP;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = REGISTER_X_IN_KS_CODE;

    *(currentStep++) = ITM_STOADD;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 0;

    // 64
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // Lissajous curve (test for PIXEL)
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'L';
    *(currentStep++) = 'I';
    *(currentStep++) = 'S';
    *(currentStep++) = 'S';
    *(currentStep++) = 'A';
    *(currentStep++) = 'J';

    *(currentStep++) = (ITM_RAD >> 8) | 0x80;
    *(currentStep++) =  ITM_RAD       & 0xff;

    *(currentStep++) = (ITM_LocR >> 8) | 0x80;
    *(currentStep++) =  ITM_LocR       & 0xff;
    *(currentStep++) = 5;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_CONSTpi;

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 3;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    *(currentStep++) = ITM_MAGNITUDE;

    // 10
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_MAGNITUDE;

    *(currentStep++) = ITM_MAX;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 4;

    *(currentStep++) = ITM_STOMULT;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 3;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 1;  // String length
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    *(currentStep++) = (ITM_CLLCD >> 8) | 0x80;
    *(currentStep++) =  ITM_CLLCD       & 0xff;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = 0;

    // 20
    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    *(currentStep++) = (ITM_toREAL >> 8) | 0x80;
    *(currentStep++) =  ITM_toREAL       & 0xff;

    *(currentStep++) = (ITM_SDR >> 8) | 0x80;
    *(currentStep++) =  ITM_SDR       & 0xff;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_ENTER;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = REGISTER_J_IN_KS_CODE;

    *(currentStep++) = ITM_RCLDIV;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 4;

    *(currentStep++) = ITM_RCLADD;
    *(currentStep++) = REGISTER_K_IN_KS_CODE;

    *(currentStep++) = ITM_sin;

    *(currentStep++) = (ITM_SDL >> 8) | 0x80;
    *(currentStep++) =  ITM_SDL       & 0xff;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    // 30
    *(currentStep++) = ITM_XexY;

    *(currentStep++) = ITM_RCLMULT;
    *(currentStep++) = REGISTER_I_IN_KS_CODE;

    *(currentStep++) = ITM_RCLDIV;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 4;

    *(currentStep++) = ITM_cos;

    *(currentStep++) = (ITM_SDL >> 8) | 0x80;
    *(currentStep++) =  ITM_SDL       & 0xff;
    *(currentStep++) = 2;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 2;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 3;

    *(currentStep++) = ITM_XLT;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    *(currentStep++) = ITM_RTN;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 1;

    // 40
    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = (ITM_ROUNDI2 >> 8) | 0x80;
    *(currentStep++) =  ITM_ROUNDI2       & 0xff;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 2;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_LONG_INTEGER;
    *(currentStep++) = 3;  // String length
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = (ITM_ROUNDI2 >> 8) | 0x80;
    *(currentStep++) =  ITM_ROUNDI2       & 0xff;

    *(currentStep++) = ITM_SF;
    *(currentStep++) = SYSTEM_FLAG_NUMBER;
    *(currentStep++) = FLAG_IGN1ER & 0xff;

    *(currentStep++) = (ITM_PIXEL >> 8) | 0x80;
    *(currentStep++) =  ITM_PIXEL       & 0xff;

    *(currentStep++) = ITM_CF;
    *(currentStep++) = SYSTEM_FLAG_NUMBER;
    *(currentStep++) = FLAG_IGN1ER & 0xff;

    // 50
    *(currentStep++) = ITM_PAUSE;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_INC;
    *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE + 0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = 0;

    // 53
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }

  { // All OP's
    // 1
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 6; // String length
    *(currentStep++) = 'A';
    *(currentStep++) = 'l';
    *(currentStep++) = 'l';
    *(currentStep++) = 'O';
    *(currentStep++) = 'p';
    *(currentStep++) = 's';

    int32_t item;
    for(item=1; item<LAST_ITEM; item++) {
      switch (indexOfItems[item].status & PTP_STATUS) {
        case PTP_NONE: {
          if(item != ITM_END) {
            currentStep = _insertItem(item,currentStep);
          }
          break;
        }
        case PTP_DECLARE_LABEL: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'A' - 'A' + 100; // A

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'L' - 'A' + 100; // L

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'a' - 'a' + FIRST_LC_LOCAL_LABEL;  // a

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'l' - 'a' + FIRST_LC_LOCAL_LABEL;  // l

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 6; // String length
          *(currentStep++) = 'C';
          *(currentStep++) = STD_i_ACUTE[0];
          *(currentStep++) = STD_i_ACUTE[1];
          *(currentStep++) = 'm';
          *(currentStep++) = 'k';
          *(currentStep++) = 'e';

          break;
        }
        case PTP_LABEL: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'A' - 'A' + 100; // A

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'L' - 'A' + 100; // L

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'a' - 'a' + FIRST_LC_LOCAL_LABEL;  // a

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 'l' - 'a' + FIRST_LC_LOCAL_LABEL;  // l

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 6; // String length
          *(currentStep++) = 'C';
          *(currentStep++) = STD_i_ACUTE[0];
          *(currentStep++) = STD_i_ACUTE[1];
          *(currentStep++) = 'm';
          *(currentStep++) = 'k';
          *(currentStep++) = 'e';

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 5;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';
          *(currentStep++) = STD_alpha[0];
          *(currentStep++) = STD_alpha[1];

          break;
        }
        case PTP_REGISTER: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          break;
        }
        case PTP_FLAG: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FLAG_X;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FLAG_K;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FLAG_M;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FLAG_W;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FIRST_LOCAL_FLAG;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = LAST_LOCAL_FLAG;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = SYSTEM_FLAG_NUMBER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = SYSTEM_FLAG_NUMBER;
          *(currentStep++) = NUMBER_OF_SYSTEM_FLAGS - 1;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_FLAG;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';
          break;
        }
        case PTP_NUMBER_8: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          break;
        }
        case PTP_NUMBER_16: {
          if(isFunctionOldParam16(item)) {  // original Param16 functions without indirection support (little endian parameter)
            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) & 0xff; // little endian
            *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) >> 8;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) & 0xff;  // little endian
            *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) >> 8;
          }
          else {                        // new Param16 functions with indirection support (big endian parameter)
            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) >> 8;   // BIG endian
            *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) & 0xff;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) >> 8;    // BIG endian
            *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) & 0xff;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(item,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
          }
          break;
        }

        case PTP_COMPARE: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = VALUE_0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = VALUE_1;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 99;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          break;
        }

        case PTP_KEYG_KEYX: {
          for(int i=0; i<=1; i++) {
            int32_t op = (i == 0 ? ITM_GTO : ITM_XEQ);
            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 1;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = 21;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = 'A' - 'A' + 100; // A

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = 'E' - 'A' + 100; // E

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = STRING_LABEL_VARIABLE;
            *(currentStep++) = 5;
            *(currentStep++) = 'L';
            *(currentStep++) = 'a';
            *(currentStep++) = 'b';
            *(currentStep++) = 'e';
            *(currentStep++) = 'l';

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 0;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = 99;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_X_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = REGISTER_W_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_REGISTER;
            *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

            currentStep = _insertItem(ITM_KEY,currentStep);
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
            *(currentStep++) = op;
            *(currentStep++) = INDIRECT_VARIABLE;
            *(currentStep++) = 3;
            *(currentStep++) = 'V';
            *(currentStep++) = 'a';
            *(currentStep++) = 'r';
          }
          break;
        }

        case PTP_SKIP_BACK: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

          break;
        }

        case PTP_NUMBER_8_16: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) =  1;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) =  79;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          break;
        }

        case PTP_SHUFFLE: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 27;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 228;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = 255;

          break;
        }

        case PTP_MENU: {
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 4;
          *(currentStep++) = 'M';
          *(currentStep++) = 'e';
          *(currentStep++) = 'n';
          *(currentStep++) = 'u';

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 0;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = 99;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_X_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_K_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_M_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = REGISTER_W_IN_KS_CODE;

          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_REGISTER;
          *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;


          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = INDIRECT_VARIABLE;
          *(currentStep++) = 3;
          *(currentStep++) = 'V';
          *(currentStep++) = 'a';
          *(currentStep++) = 'r';

          break;
        }

        case PTP_LITERAL: {
          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_SHORT_INTEGER;
          *(currentStep++) = 2; // Base
          *(currentStep++) = 1;
          *(currentStep++) = 2;
          *(currentStep++) = 3;
          *(currentStep++) = 4;
          *(currentStep++) = 5;
          *(currentStep++) = 6;
          *(currentStep++) = 7;
          *(currentStep++) = 0xF8;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_SHORT_INTEGER;
          *(currentStep++) = 3; // Base
          *(currentStep++) = 1;
          *(currentStep++) = 2;
          *(currentStep++) = 3;
          *(currentStep++) = 4;
          *(currentStep++) = 5;
          *(currentStep++) = 6;
          *(currentStep++) = 7;
          *(currentStep++) = 0xF8;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_SHORT_INTEGER;
          *(currentStep++) = 4; // Base
          *(currentStep++) = 1;
          *(currentStep++) = 2;
          *(currentStep++) = 3;
          *(currentStep++) = 4;
          *(currentStep++) = 5;
          *(currentStep++) = 6;
          *(currentStep++) = 7;
          *(currentStep++) = 0xF8;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_SHORT_INTEGER;
          *(currentStep++) = 8; // Base
          *(currentStep++) = 1;
          *(currentStep++) = 2;
          *(currentStep++) = 3;
          *(currentStep++) = 4;
          *(currentStep++) = 5;
          *(currentStep++) = 6;
          *(currentStep++) = 7;
          *(currentStep++) = 0xF8;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_SHORT_INTEGER;
          *(currentStep++) = 10; // Base
          *(currentStep++) = 1;
          *(currentStep++) = 2;
          *(currentStep++) = 3;
          *(currentStep++) = 4;
          *(currentStep++) = 5;
          *(currentStep++) = 6;
          *(currentStep++) = 7;
          *(currentStep++) = 0xF8;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_SHORT_INTEGER;
          *(currentStep++) = 16; // Base
          *(currentStep++) = 1;
          *(currentStep++) = 2;
          *(currentStep++) = 3;
          *(currentStep++) = 4;
          *(currentStep++) = 5;
          *(currentStep++) = 6;
          *(currentStep++) = 7;
          *(currentStep++) = 0xF8;

          *(currentStep++) = (ITM_NOP >> 8) | 0x80; // TODO: implement ITM_LITERAL BINARY_LONG_INTEGER
          *(currentStep++) =  ITM_NOP       & 0xff;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_REAL34;
          *(currentStep++) =  1;
          *(currentStep++) =  2;
          *(currentStep++) =  3;
          *(currentStep++) =  4;
          *(currentStep++) =  5;
          *(currentStep++) =  6;
          *(currentStep++) =  7;
          *(currentStep++) =  8;
          *(currentStep++) =  9;
          *(currentStep++) = 10;
          *(currentStep++) = 11;
          *(currentStep++) = 12;
          *(currentStep++) = 13;
          *(currentStep++) = 14;
          *(currentStep++) = 15;
          *(currentStep++) = 16;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = BINARY_COMPLEX34;
          *(currentStep++) =  1;
          *(currentStep++) =  2;
          *(currentStep++) =  3;
          *(currentStep++) =  4;
          *(currentStep++) =  5;
          *(currentStep++) =  6;
          *(currentStep++) =  7;
          *(currentStep++) =  8;
          *(currentStep++) =  9;
          *(currentStep++) = 10;
          *(currentStep++) = 11;
          *(currentStep++) = 12;
          *(currentStep++) = 13;
          *(currentStep++) = 14;
          *(currentStep++) = 15;
          *(currentStep++) = 16;
          *(currentStep++) = 17;
          *(currentStep++) = 18;
          *(currentStep++) = 19;
          *(currentStep++) = 20;
          *(currentStep++) = 21;
          *(currentStep++) = 22;
          *(currentStep++) = 23;
          *(currentStep++) = 24;
          *(currentStep++) = 25;
          *(currentStep++) = 26;
          *(currentStep++) = 27;
          *(currentStep++) = 28;
          *(currentStep++) = 29;
          *(currentStep++) = 30;
          *(currentStep++) = 31;
          *(currentStep++) = 32;

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_SHORT_INTEGER;
          *(currentStep++) =  16; // Base
          *(currentStep++) =  6;  // String length
          *(currentStep++) =  'A';
          *(currentStep++) =  'B';
          *(currentStep++) =  'C';
          *(currentStep++) =  'D';
          *(currentStep++) =  'E';
          *(currentStep++) =  'F';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_SHORT_INTEGER;
          *(currentStep++) =  16; // Base
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  'A';
          *(currentStep++) =  'B';
          *(currentStep++) =  'C';
          *(currentStep++) =  'D';
          *(currentStep++) =  'E';
          *(currentStep++) =  'F';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_LONG_INTEGER;
          *(currentStep++) =  6;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_COMPLEX34;
          *(currentStep++) = 4; // String length
          *(currentStep++) = '1';
          *(currentStep++) = '-';
          *(currentStep++) = 'i';
          *(currentStep++) = '2';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_TIME;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '2';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_TIME;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_DATE;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '2';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';
          *(currentStep++) =  '6';
          *(currentStep++) =  '7';
          *(currentStep++) =  '8';
          *(currentStep++) =  '9';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_DMS;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '7';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_DMS;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_RADIAN;
          *(currentStep++) =  6;  // String length
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_RADIAN;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_GRAD;
          *(currentStep++) =  8;  // String length
          *(currentStep++) =  '1';
          *(currentStep++) =  '9';
          *(currentStep++) =  '8';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_GRAD;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_DEGREE;
          *(currentStep++) =  8;  // String length
          *(currentStep++) =  '1';
          *(currentStep++) =  '7';
          *(currentStep++) =  '9';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_DEGREE;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_MULTPI;
          *(currentStep++) =  6;  // String length
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_ANGLE_MULTPI;
          *(currentStep++) =  7;  // String length
          *(currentStep++) =  '-';
          *(currentStep++) =  '1';
          *(currentStep++) =  '.';
          *(currentStep++) =  '2';
          *(currentStep++) =  '3';
          *(currentStep++) =  '4';
          *(currentStep++) =  '5';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 0; // Empty string

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 20; // String length
          *(currentStep++) = 'A';
          *(currentStep++) = ' ';
          *(currentStep++) = 'm';
          *(currentStep++) = 'e';
          *(currentStep++) = 's';
          *(currentStep++) = 's';
          *(currentStep++) = 'a';
          *(currentStep++) = 'g';
          *(currentStep++) = 'e';
          *(currentStep++) = ' ';
          *(currentStep++) = 'i';
          *(currentStep++) = 'n';
          *(currentStep++) = ' ';
          *(currentStep++) = 'E';
          *(currentStep++) = 'n';
          *(currentStep++) = 'g';
          *(currentStep++) = 'l';
          *(currentStep++) = 'i';
          *(currentStep++) = 's';
          *(currentStep++) = 'h';

          *(currentStep++) = ITM_LITERAL;
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 24; // String length
          *(currentStep++) = 'U';
          *(currentStep++) = 'n';
          *(currentStep++) = 'e';
          *(currentStep++) = ' ';
          *(currentStep++) = 'c';
          *(currentStep++) = 'h';
          *(currentStep++) = 'a';
          *(currentStep++) = STD_i_CIRC[0];
          *(currentStep++) = STD_i_CIRC[1];
          *(currentStep++) = 'n';
          *(currentStep++) = 'e';
          *(currentStep++) = ' ';
          *(currentStep++) = 'e';
          *(currentStep++) = 'n';
          *(currentStep++) = ' ';
          *(currentStep++) = 'f';
          *(currentStep++) = 'r';
          *(currentStep++) = 'a';
          *(currentStep++) = 'n';
          *(currentStep++) = STD_c_CEDILLA[0];
          *(currentStep++) = STD_c_CEDILLA[1];
          *(currentStep++) = 'a';
          *(currentStep++) = 'i';
          *(currentStep++) = 's';

          break;
        }

        case PTP_REM:
          currentStep = _insertItem(item,currentStep);
          *(currentStep++) = STRING_LABEL_VARIABLE;
          *(currentStep++) = 18;
          *(currentStep++) = 'T';
          *(currentStep++) = 'h';
          *(currentStep++) = 'i';
          *(currentStep++) = 's';
          *(currentStep++) = ' ';
          *(currentStep++) = 'i';
          *(currentStep++) = 's';
          *(currentStep++) = ' ';
          *(currentStep++) = 'a';
          *(currentStep++) = ' ';
          *(currentStep++) = 'c';
          *(currentStep++) = 'o';
          *(currentStep++) = 'm';
          *(currentStep++) = 'm';
          *(currentStep++) = 'e';
          *(currentStep++) = 'n';
          *(currentStep++) = 't';
          *(currentStep++) = '.';
          break;

        case PTP_DISABLED:
          break;
      }
    }
    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;
  }




//-----JACO GENERATED FROM SPREADSHEET vvvvvvvvvv

{ // JACO EX DEMO OM p 111 (Gilileo's example from HP-27 OH)
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; //String Length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '5';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = (ITM_BESTF >> 8) | 0x80;
    *(currentStep++) =  ITM_BESTF       & 0xff;
    *(currentStep++) = 0;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_LR >> 8) | 0x80;
    *(currentStep++) =  ITM_LR       & 0xff;

    *(currentStep++) = (ITM_PLOT_ASSESS >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS       & 0xff;

    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;

}  //


{ // JACO EX DEMO OM p113 (Hephaestus example from various HP sources as per Walter
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; //String Length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '3';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '3';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '2';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = (ITM_BESTF >> 8) | 0x80;
    *(currentStep++) =  ITM_BESTF       & 0xff;
    *(currentStep++) = 0;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_LR >> 8) | 0x80;
    *(currentStep++) =  ITM_LR       & 0xff;

    *(currentStep++) = (ITM_PLOT_ASSESS >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS       & 0xff;

    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;

}  //



{ //  JACO EX DEMO OM p115 (Silas example from the HP-15C OH
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; //String Length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '5';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; //String Length
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '5';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '7';
    *(currentStep++) = '.';
    *(currentStep++) = '2';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '7';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '8';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = (ITM_BESTF >> 8) | 0x80;
    *(currentStep++) =  ITM_BESTF       & 0xff;
    *(currentStep++) = 0;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_LR >> 8) | 0x80;
    *(currentStep++) =  ITM_LR       & 0xff;

    *(currentStep++) = (ITM_PLOT_ASSESS >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS       & 0xff;

    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;

}  //



{ // JACO EX DEMO0 is a 100 point Gaussian perfect distribution.
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; //String Length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '5';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '.';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '.';
    *(currentStep++) = '4';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '5';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '5';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '5';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '6';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 16; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 16; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; //String Length
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 16; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 18; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 17; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 19; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '8';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '5';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '5';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '7';
    *(currentStep++) = '6';
    *(currentStep++) = '7';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '2';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '2';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '3';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '.';
    *(currentStep++) = '3';
    *(currentStep++) = '3';
    *(currentStep++) = '0';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '4';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '4';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '8';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '4';
    *(currentStep++) = '2';
    *(currentStep++) = '6';
    *(currentStep++) = '4';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '6';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '2';
    *(currentStep++) = '2';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '6';
    *(currentStep++) = '2';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '6';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '6';
    *(currentStep++) = '.';
    *(currentStep++) = '4';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '7';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '6';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '7';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '.';
    *(currentStep++) = '5';
    *(currentStep++) = '4';
    *(currentStep++) = '9';
    *(currentStep++) = '3';
    *(currentStep++) = '8';
    *(currentStep++) = '1';
    *(currentStep++) = '8';
    *(currentStep++) = '8';
    *(currentStep++) = '0';
    *(currentStep++) = '3';
    *(currentStep++) = '9';
    *(currentStep++) = '2';
    *(currentStep++) = '0';
    *(currentStep++) = '1';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '9';
    *(currentStep++) = '.';
    *(currentStep++) = '8';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '5';
    *(currentStep++) = '0';
    *(currentStep++) = '5';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '9';
    *(currentStep++) = '9';
    *(currentStep++) = '1';
    *(currentStep++) = '6';
    *(currentStep++) = '9';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '4';
    *(currentStep++) = '.';
    *(currentStep++) = '9';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 20; //String Length
    *(currentStep++) = '3';
    *(currentStep++) = '.';
    *(currentStep++) = '7';
    *(currentStep++) = '3';
    *(currentStep++) = '7';
    *(currentStep++) = '5';
    *(currentStep++) = '7';
    *(currentStep++) = '1';
    *(currentStep++) = '3';
    *(currentStep++) = '2';
    *(currentStep++) = '7';
    *(currentStep++) = '9';
    *(currentStep++) = '4';
    *(currentStep++) = '4';
    *(currentStep++) = '3';
    *(currentStep++) = '5';
    *(currentStep++) = 'e';
    *(currentStep++) = '-';
    *(currentStep++) = '1';
    *(currentStep++) = '1';

    *(currentStep++) = ITM_XexY;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = (ITM_BESTF >> 8) | 0x80;
    *(currentStep++) =  ITM_BESTF       & 0xff;
    *(currentStep++) = 0;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_LR >> 8) | 0x80;
    *(currentStep++) =  ITM_LR       & 0xff;

    *(currentStep++) = (ITM_PLOT_ASSESS >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS       & 0xff;

    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;

}  //


{ // JACO EX DEMO2 is a 4 sample example which produces valid values for L.R. to be Gaussian peak, Cauchy and parabolic.
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; //String Length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '2';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 6; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '-';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 6; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; //String Length
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 6; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '9';
    *(currentStep++) = '0';
    *(currentStep++) = '5';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '+';
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '8';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = '0';
    *(currentStep++) = '.';
    *(currentStep++) = '0';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = (ITM_BESTF >> 8) | 0x80;
    *(currentStep++) =  ITM_BESTF       & 0xff;
    *(currentStep++) = 0;
    *(currentStep++) = 0;

    *(currentStep++) = (ITM_LR >> 8) | 0x80;
    *(currentStep++) =  ITM_LR       & 0xff;

    *(currentStep++) = (ITM_PLOT_ASSESS >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_ASSESS       & 0xff;

    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;

}  //


{ // JACO EX DEMO1 is the 100 pair 11 000 V instrumentation example.
    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 7; //String Length
    *(currentStep++) = 'S';
    *(currentStep++) = 'T';
    *(currentStep++) = 'A';
    *(currentStep++) = 'T';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '1';

    *(currentStep++) = (ITM_CLSIGMA >> 8) | 0x80;
    *(currentStep++) =  ITM_CLSIGMA       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 3; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_LBL;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = 'L';
    *(currentStep++) = 'P';
    *(currentStep++) = '1';
    *(currentStep++) = 'a';

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 5; //String Length
    *(currentStep++) = '1';
    *(currentStep++) = '1';
    *(currentStep++) = '0';
    *(currentStep++) = '0';
    *(currentStep++) = '0';

    *(currentStep++) = (ITM_RAN >> 8) | 0x80;
    *(currentStep++) =  ITM_RAN       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 2; //String Length
    *(currentStep++) = '2';
    *(currentStep++) = '2';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_STO;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_RAN >> 8) | 0x80;
    *(currentStep++) =  ITM_RAN       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; //String Length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = ITM_RCL;
    *(currentStep++) = 1;

    *(currentStep++) = (ITM_RAN >> 8) | 0x80;
    *(currentStep++) =  ITM_RAN       & 0xff;

    *(currentStep++) = ITM_LITERAL;
    *(currentStep++) = STRING_REAL34;
    *(currentStep++) = 1; //String Length
    *(currentStep++) = '4';

    *(currentStep++) = ITM_MULT;

    *(currentStep++) = ITM_ADD;

    *(currentStep++) = (ITM_SIGMAPLUS >> 8) | 0x80;
    *(currentStep++) =  ITM_SIGMAPLUS       & 0xff;

    *(currentStep++) = ITM_DSZ;
    *(currentStep++) = 0;

    *(currentStep++) = ITM_GTO;
    *(currentStep++) = STRING_LABEL_VARIABLE;
    *(currentStep++) = 4; //String Length
    *(currentStep++) = 'L';
    *(currentStep++) = 'P';
    *(currentStep++) = '1';
    *(currentStep++) = 'a';

    *(currentStep++) = (ITM_PLOT_SCATR >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_SCATR       & 0xff;

    *(currentStep++) = (ITM_PLOT_CENTRL >> 8) | 0x80;
    *(currentStep++) =  ITM_PLOT_CENTRL       & 0xff;

    *(currentStep++) = (ITM_END >> 8) | 0x80;
    *(currentStep++) =  ITM_END       & 0xff;

}  //


//JACO DEMO END

//-----JACO GENERATED FROM SPREADSHEET ^^^^^^^^^^




  *(currentStep++) = 255; // .END.
  *(currentStep++) = 255; // .END.

  testPgms = fopen(argv[1], "wb");
  if(testPgms == NULL) {
    fprintf(stderr, "Cannot create file %s\n", argv[1]);
    exit(1);
  }

  sizeOfPgms = currentStep - memory;
  fwrite(&sizeOfPgms, 1, sizeof(sizeOfPgms), testPgms);
  fwrite(memory,      1, sizeOfPgms,         testPgms);
  fclose(testPgms);

  printf("Test programs generated: %s\n", argv[1]);

  return 0;
}
