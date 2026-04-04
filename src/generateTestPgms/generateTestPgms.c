// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

#include "c47.h"

uint8_t memory[65536], *currenStep;

void *xcopy(void *dest, const void *source, uint32_t n) {
  char       *pDest   = (char *)dest;
  const char *pSource = (char *)source;

  if(pSource > pDest) {
    while(n--) {
      *pDest++ = *pSource++;
    }
  }
  else {
    if(pSource < pDest) {
      while(n--) {
        pDest[n] = pSource[n];
      }
    }
  }

  return dest;
}


static void _insertItem(int16_t item) {
  if(item < 128) {
    *(currentStep++) = item;
  }
  else {
    *(currentStep++) = (uint8_t)((item >> 8) | 0x80);
    *(currentStep++) = (uint8_t)( item       & 0xff);
  }
}


static void _insertString(const char *s) {
  int32_t lg = strlen(s);

  *(currentStep++) = (uint8_t)lg;

  for(int32_t i=0; i<lg; i++) {
    *(currentStep++) = (uint8_t)s[i];
  }
}


static void _insertLabelVariableString(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empty string as a label or a variable!\n");
    return;
  }

  if(lg > 14) {
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a label or a variable!\n");
    return;
  }

  *(currentStep++) = STRING_LABEL_VARIABLE;
  _insertString(s);
}


static void       _insertReal34StringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empty string as a real34!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a real34!\n");
    return;
  }

                       _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_REAL34;
  _insertString(s);
}


static void _insertTimeStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empty string as a time!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a time!\n");
    return;
  }

                       _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_TIME;
  _insertString(s);
}


static void _insertDateStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empty string as a date!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a date!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_DATE;
  _insertString(s);
}


static void _insertAngleDegreeStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as an angle in degree!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for an angle in degree!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_ANGLE_DEGREE;
  _insertString(s);
}


static void _insertAngleDmsStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as an angle in DMS!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for an angle in DMS!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_ANGLE_DMS;
  _insertString(s);
}


static void _insertAngleGradStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as an angle in grad!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for an angle in grad!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_ANGLE_GRAD;
  _insertString(s);
}


static void _insertAngleMultpiStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as an angle in multPi!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for an angle in multPi!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_ANGLE_MULTPI;
  _insertString(s);
}


static void _insertAngleRadianStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as an angle in radian!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for an angle in radian!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_ANGLE_RADIAN;
  _insertString(s);
}


static void _insertReal34BinaryLiteral(const char *s) {
  real34_t r;

  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as a real34!\n");
    return;
  }

  if(lg > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a real34!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = BINARY_REAL34;

  stringToReal34(s, &r);
  uint8_t *u = (uint8_t *)(&r);
  for(int32_t i=0; i<16; i++) {
    *(currentStep++) = *(u + i);
  }
}


static void _insertLongIntegerStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as a long integer!\n");
    return;
  }

  if(lg > 255) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a long integer!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_LONG_INTEGER;
  _insertString(s);
}


static void _insertShortIntegerStringLiteral(const char *s, uint8_t base) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as a short integer!\n");
    return;
  }

  if(lg > 65) { // minus sign   +   64 bits
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a short integer!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_SHORT_INTEGER;
  *(currentStep++) = base;
  _insertString(s);
}


static void _insertShortIntegerBinaryLiteral(uint64_t shortInteger, uint8_t base) {
  _insertItem(ITM_LITERAL);
  *(currentStep++) = BINARY_SHORT_INTEGER;
  *(currentStep++) = base;

  uint8_t *u = (uint8_t *)(&shortInteger);
  for(int32_t i=0; i<=7; i++) {
    *(currentStep++) = *(u + i);
  }
}


static void _insertComplex34StringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg < 4) { // 0+i0
    abortf("In generateTestPgms.c, there is an attempt to insert a too short string as a complex34!\n");
    return;
  }

  if(lg > 86) { // 2 real34   +   minus sign   +   i
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a complex34!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_COMPLEX34;
  _insertString(s);
}


static void _insertComplex34BinaryLiteral(const char *s1, const char *s2) {
  real34_t r;

  int32_t lg1 = strlen(s1);

  if(lg1 == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as real part of a complex34!\n");
    return;
  }

  if(lg1 > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a real part of a complex34!\n");
    return;
  }

  int32_t lg2 = strlen(s2);

  if(lg2 == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empy string as imaginary part of a complex34!\n");
    return;
  }

  if(lg2 > 42) { // 34 digits   +   minis sign   +   decimal separator   +   e   +   minus sign   +   4 for exponent
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a imaginary part of a complex34!\n");
    return;
  }

  _insertItem(ITM_LITERAL);
  *(currentStep++) = BINARY_COMPLEX34;

  stringToReal34(s1, &r);
  uint8_t *u = (uint8_t *)(&r);
  for(int32_t i=0; i<16; i++) {
    *(currentStep++) = *(u + i);
  }

  stringToReal34(s2, &r);
  u = (uint8_t *)(&r);
  for(int32_t i=0; i<16; i++) {
    *(currentStep++) = *(u + i);
  }
}


static void             _insertStringLiteral(const char *s) {
  int32_t lg = strlen(s);

  if(lg > 255) {
    abortf("In generateTestPgms.c, there is an attempt to insert a too long character string!\n");
    return;
  }

                       _insertItem(ITM_LITERAL);
  *(currentStep++) = STRING_LABEL_VARIABLE;
  _insertString(s);
}


static void _insertComment(const char *s) {
  int32_t lg = strlen(s);

  if(lg > 255) {
    abortf("In generateTestPgms.c, there is an attempt to insert a too long character string!\n");
    return;
  }

  _insertItem(ITM_REM);
  *(currentStep++) = STRING_LABEL_VARIABLE;
  _insertString(s);
}


static void _insertIndirectAccessVariable(const char *s) {
  int32_t lg = strlen(s);

  if(lg == 0) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empty string as a variable!\n");
    return;
  }

  if(lg > 14) {
    abortf("In generateTestPgms.c, there is an attempt to insert a too long string for a variable!\n");
    return;
  }

  *(currentStep++) = INDIRECT_VARIABLE;
  _insertString(s);
}


static void _insertIndirectAccessRegister(uint8_t reg) {

  if(reg > 244) {
    abortf("In generateTestPgms.c, there is an attempt to insert an empty string as a variable!\n");
    return;
  }

  *(currentStep++) = INDIRECT_REGISTER;
  *(currentStep++) = reg;
}


int main(int argc, char* argv[]) {
  FILE *testPgms;
  uint32_t sizeOfPgms;

  if(argc < 2) {
    printf("Usage: generateTestPgms <output file>\n");
    return 1;
  }

  memset(memory, 0, 65536);
  currentStep = memory;

  { // Prime number checker
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Prime"                );
                         _insertItem(  ITM_MAGNITUDE          );
                         _insertItem(  ITM_IP                 );
                         _insertItem(  ITM_STO                );
                  *(currentStep++) =   0                       ;
                         _insertItem(  ITM_SQUAREROOTX        );
                         _insertItem(  ITM_IP                 );
                         _insertItem(  ITM_STO                );
                  *(currentStep++) =   2                       ;
          _insertReal34StringLiteral(  "1"                    );
                         _insertItem(  ITM_STO                );
                  *(currentStep++) =   1                       ;
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "1"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
                         _insertItem(  ITM_LBL                );
                  *(currentStep++) =   2                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "8"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "8"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "6"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "4"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "10"                   );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "2"                    );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
          _insertReal34StringLiteral(  "10"                   );
                         _insertItem(  ITM_XEQ                );
                  *(currentStep++) =   9                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   1                       ;
                         _insertItem(  ITM_XLT                );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE   ;
                         _insertItem(  ITM_GTO                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   0                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   0                       ;
                         _insertItem(  ITM_STOP               );
                         _insertItem(  ITM_LBL                );
                  *(currentStep++) =   9                       ;
                         _insertItem(  ITM_STOADD             );
                  *(currentStep++) =   1                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   0                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   1                       ;
                         _insertItem(  ITM_MOD                );
                         _insertItem(  ITM_XNE                );
                  *(currentStep++) =   VALUE_0                 ;
                         _insertItem(  ITM_RTN                );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   0                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   1                       ;
                         _insertItem(  ITM_STOP               );
                         _insertItem(  ITM_END                );
  }

  { // Len1
                         _insertItem(  ITM_END                );
  }

  { // Len2
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len2"                 );
                         _insertItem(  ITM_END                );
  }

  { // Len3
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len3"                 );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_END                );
  }

  { // Len4
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len4"                 );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   3                       ;
                         _insertItem(  ITM_END                );
  }

  { // Len5
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len5"                 );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   3                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   4                       ;
                         _insertItem(  ITM_END                );
  }

  { // Len6
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len6"                 );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   3                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   4                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   5                       ;
                         _insertItem(  ITM_END                );
  }

  { // Len7
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len7"                 );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   3                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   4                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   5                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   6                       ;
                         _insertItem(  ITM_END                );
  }

  { // Len8
                         _insertItem(  ITM_LBL                );
          _insertLabelVariableString(  "Len8"                 );
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   2                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   3                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   4                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   5                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   6                       ;
                         _insertItem(  ITM_RCL                );
                  *(currentStep++) =   7                       ;
                         _insertItem(  ITM_END                );
  }

  { // Bairstow polynomial root finder; Edits and corrections by L Locklear, entered by JM
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "Bairsto"             );
                         _insertItem(  ITM_ALL               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_CLCVAR            );
                         _insertItem(  ITM_CLSTK             );
                _insertStringLiteral(  "Polynomial degree?"  );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_MAGNITUDE         );
                         _insertItem(  ITM_IP                );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   90                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
          _insertReal34StringLiteral(  "1e3"                 );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   100 + 'A' - 'A'        ; // A
                _insertStringLiteral(  "x^"                  );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_CLSTK             );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STOSUB            );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_ISG               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   100 + 'A' - 'A'        ; // A
                         _insertItem(  ITM_CLSTK             );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_XNE               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   100 + 'B' - 'A'        ; // B
                _insertStringLiteral(  "Tolerance?"          );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   99                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   10                     ;
          _insertReal34StringLiteral(  "3"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
                         _insertItem(  ITM_XLT               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   2                      ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   96                     ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   100 + 'D' - 'A'        ; // D
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   59                     ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   11                     ;
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   10                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   2                      ;
          _insertReal34StringLiteral(  "2"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
                         _insertItem(  ITM_XNE               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   12                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   90                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   13                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   90                     ;
                _insertStringLiteral(  "Last root"           );
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   100 + 'B' - 'A'        ; // B
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
          _insertReal34StringLiteral(  "1e3"                 );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   100 + 'C' - 'A'        ; // C
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_STODIV            );
       _insertIndirectAccessRegister(  93                    );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_ISG               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   100 + 'C' - 'A'        ; // C
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   100 + 'D' - 'A'        ; // D
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   97                     ;
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   98                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   58                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
          _insertReal34StringLiteral(  "1e3"                 );
                         _insertItem(  ITM_DIV               );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   89                     ;
          _insertReal34StringLiteral(  "30"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   94                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   94                     ;
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  92                    );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO);
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   100 + 'E' - 'A'        ; // E
                         _insertItem(  ITM_RCL)               ;
       _insertIndirectAccessRegister(  91                    );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  94                    );
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_CHS               );
                         _insertItem(  ITM_STOADD            );
       _insertIndirectAccessRegister(  94                    );
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  92                    );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   96                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_CHS               );
                         _insertItem(  ITM_STOADD            );
       _insertIndirectAccessRegister(  94                    );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   89                     ;
                         _insertItem(  ITM_ISG               );
                  *(currentStep++) =   89                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   100 + 'E' - 'A'        ; // E
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  92                    );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   84                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   85                     ;
          _insertReal34StringLiteral(  "30"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
          _insertReal34StringLiteral(  "1e3"                 );
                         _insertItem(  ITM_DIV               );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   89                     ;
          _insertReal34StringLiteral(  "60"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   94                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   94                     ;
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  92                    );
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   55                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  91                    );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  94                    );
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_CHS               );
                         _insertItem(  ITM_STOADD            );
       _insertIndirectAccessRegister(  94                    );
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  92                    );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   96                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_CHS               );
                         _insertItem(  ITM_STOADD            );
       _insertIndirectAccessRegister(  94                    );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   89                     ;
                         _insertItem(  ITM_ISG               );
                  *(currentStep++) =   89                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   55                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  92                    );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  93                    );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   96                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   84                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   85                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   87                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   96                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   84                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   85                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   93                     ;
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_ADD)               ;
                         _insertItem(  ITM_RCL)               ;
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   86                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   87                     ;
                         _insertItem(  ITM_MAGNITUDE         );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE  ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   86                     ;
                         _insertItem(  ITM_MAGNITUDE         );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_XGT               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   56                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   87                     ;
                         _insertItem(  ITM_MAGNITUDE         );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   97                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   57                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   56                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   86                     ;
                         _insertItem(  ITM_MAGNITUDE         );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   97                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   57                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   87                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   86                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   96                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   98                     ;
          _insertReal34StringLiteral(  "1e4"                 );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE  ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   98                     ;
                         _insertItem(  ITM_XGT               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   4                      ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   99                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   97                     ;
                         _insertItem(  ITM_XGT               );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE  ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   58                     ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   59                     ;
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
          _insertReal34StringLiteral(  "31"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   93                     ;
          _insertReal34StringLiteral(  "1e3"                 );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  92                    );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  91                    );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_ISG               );
                  *(currentStep++) =   94                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   90                     ;
          _insertReal34StringLiteral(  "2"                   );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   90                     ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   11                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   95                     ;
                         _insertItem(  ITM_CHS               );
          _insertReal34StringLiteral(  "2"                   );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_SQUARE            );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   96                     ;
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_SQUAREROOTX       );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_SQUAREROOTX       );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   12                     ;
                         _insertItem(  ITM_CLSTK             );
                _insertStringLiteral(  "... continue"        );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_CHS               );
          _insertReal34StringLiteral(  "2"                   );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_SQUARE            );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_SQUAREROOTX       );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   92                     ;
                         _insertItem(  ITM_SQUAREROOTX       );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   13                     ;
                         _insertItem(  ITM_CLSTK             );
                _insertStringLiteral(  "... continue"        );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_CHS               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_CLSTK             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   91                     ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   4                      ;
                         _insertItem(  ITM_CLSTK             );
                _insertStringLiteral(  "Error m>80!"         );
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_END               );
  }

  { // Speed test. See: https://forum.swissmicros.com/viewtopic.php?p=17308
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "Speed"               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   10                     ;
                         _insertItem(  ITM_TICKS             );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   0                      ;
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   11                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   12                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_arctan            );
                         _insertItem(  ITM_sin               );
                         _insertItem(  ITM_EXP               );
          _insertReal34StringLiteral(  "3"                   );
                         _insertItem(  ITM_1ONX              );
                         _insertItem(  ITM_YX                );
                         _insertItem(  ITM_STOADD            );
                  *(currentStep++) =   11                     ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   12                     ;
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_ADD               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   12                     ;
                         _insertItem(  ITM_DSE               );
                  *(currentStep++) =   10                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_TICKS             );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_SUB               );
          _insertReal34StringLiteral(  "10"                  );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_END               );
  }

  { // Factorial: the recursive way ReM page 261
                         _insertItem(  ITM_LBL                         );
          _insertLabelVariableString(  "ReMp261"                       );
                         _insertItem(  ITM_LBL                         );
          _insertLabelVariableString(  "Fact"                          );
                         _insertItem(  ITM_IP                          );
                         _insertItem(  ITM_XGT                         );
                  *(currentStep++) =   VALUE_1                          ;
                         _insertItem(  ITM_GTO                         );
                  *(currentStep++) =   0                                ;
          _insertReal34StringLiteral(  "1"                             );
                         _insertItem(  ITM_RTN                         );
                         _insertItem(  ITM_LBL                         );
                  *(currentStep++) =   0                                ;
                         _insertItem(  ITM_LocR                        );
                  *(currentStep++) =   1                                ;
                         _insertItem(  ITM_STO                         );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE  ; // .00
                         _insertItem(  ITM_DECR)                        ;
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE            ;
                         _insertItem(  ITM_XEQ                         );
          _insertLabelVariableString(  "Fact"                          );
                         _insertItem(  ITM_RCLMULT                     );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE  ; // .00
                         _insertItem(  ITM_RTN                         );
                         _insertItem(  ITM_END                         );
  }

  { // OM page 209
                         _insertItem(  ITM_LBL       );
          _insertLabelVariableString(  "OMp209"      );
                         _insertItem(  ITM_SQUARE    );
                         _insertItem(  ITM_CONSTpi   );
                         _insertItem(  ITM_MULT      );
                         _insertItem(  ITM_RTN       );
                         _insertItem(  ITM_END       );
  }

  { // STAT GR1 GRAPH1 TEST
                         _insertItem(  ITM_LBL          );
          _insertLabelVariableString(  "STATgr"         );
                         _insertItem(  ITM_CLSIGMA      );
                         _insertItem(  ITM_RAD          );
                         _insertItem(  ITM_dotD         );
          _insertReal34StringLiteral(  "101"            );
                         _insertItem(  ITM_STO          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_STO          );
                  *(currentStep++) =   2                 ;
                         _insertItem(  ITM_LBL          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_RCL          );
                  *(currentStep++) =   2                 ;
                         _insertItem(  ITM_RCL          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_SUB          );
                         _insertItem(  ITM_RCL          );
                  *(currentStep++) =   2                 ;
                         _insertItem(  ITM_DECR         );
                  *(currentStep++) =   100               ; //X
     _insertLongIntegerStringLiteral(  "2"              );
                         _insertItem(  ITM_IDIV         );
                         _insertItem(  ITM_DIV          );
     _insertLongIntegerStringLiteral(  "1"              );
                         _insertItem(  ITM_SUB          );
     _insertLongIntegerStringLiteral(  "5"              );
                         _insertItem(  ITM_MULT         );
                         _insertItem(  ITM_CONSTpi      );
                         _insertItem(  ITM_MULT         );
                         _insertItem(  ITM_ENTER        );
                         _insertItem(  ITM_sinc         );
                         _insertItem(  ITM_XexY         );                        //swap the stack x, y
                         _insertItem(  ITM_SIGMAPLUS    );    //Enter stats pair incorrectly oriented x<>y
                         _insertItem(  ITM_DSZ          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_GTO          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_T_LINF       );
                         _insertItem(  ITM_PLOT_ASSESS  );
                         _insertItem(  ITM_PLOT_NXT     );
                         _insertItem(  ITM_STOP         );
                         _insertItem(  ITM_T_PARABF     );
                         _insertItem(  ITM_PLOT_ASSESS  );
                         _insertItem(  ITM_STOP         );
                         _insertItem(  ITM_RTN          );
                         _insertItem(  ITM_END          );

  }

  { // OM page 212
                         _insertItem(  ITM_LBL        );
          _insertLabelVariableString(  "OMp212"       );
                         _insertItem(  ITM_LBL        );
          _insertLabelVariableString(  "K"            );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "r"            );
                         _insertItem(  ITM_SQUARE     );
                         _insertItem(  ITM_CONSTpi    );
                         _insertItem(  ITM_MULT       );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "BASe"         );
                         _insertItem(  ITM_STOADD     );
          _insertLabelVariableString(  STD_SIGMA "B"  );
                         _insertItem(  ITM_VIEW       );
          _insertLabelVariableString(  "BASe"         );
                         _insertItem(  ITM_INPUT      );
          _insertLabelVariableString(  "h"            );
                         _insertItem(  ITM_MULT       );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "VOLUME"       );
                         _insertItem(  ITM_STOADD     );
          _insertLabelVariableString(  STD_SIGMA "V"  );
                         _insertItem(  ITM_VIEW       );
          _insertLabelVariableString(  "VOLUME"       );
                         _insertItem(  ITM_RCL        );
          _insertLabelVariableString(  "r"            );
                         _insertItem(  ITM_DIV        );
     _insertLongIntegerStringLiteral(  "2"            );
                         _insertItem(  ITM_MULT       );
                         _insertItem(  ITM_RCL        );
          _insertLabelVariableString(  "BASe"         );
     _insertLongIntegerStringLiteral(  "2"            );
                         _insertItem(  ITM_MULT       );
                         _insertItem(  ITM_ADD        );
                         _insertItem(  ITM_STOADD     );
          _insertLabelVariableString(  STD_SIGMA "S"  );
                         _insertItem(  ITM_RTN        );
                         _insertItem(  ITM_END        );
  }

  { // OM page 224
                         _insertItem(  ITM_LBL                              );
          _insertLabelVariableString(  "OMp224"                             );
                         _insertItem(  ITM_LBL                              );
          _insertLabelVariableString(  "X"                                  );
                         _insertItem(  ITM_RAN                              );
                         _insertItem(  ITM_STO                              );
       _insertIndirectAccessRegister(    24                                 );
                         _insertItem(  ITM_ISG                              );
                  *(currentStep++) =   24                                    ;
                         _insertItem(  ITM_GTO                              );
          _insertLabelVariableString(  "X"                                  );
                         _insertItem(  ITM_RTN                              );
                         _insertItem(  ITM_LBL                              );
          _insertLabelVariableString(  "Y"                                  );
                         _insertItem(  ITM_LocR                             );
                  *(currentStep++) =   2                                     ;
                         _insertItem(  ITM_LBL                              );
                  *(currentStep++) =   100 + 'A' - 'A'                       ; // A
                         _insertItem(  ITM_RCL                              );
                  *(currentStep++) =   24                                    ;
                         _insertItem(  ITM_STO                              );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE       ;
                         _insertItem(  ITM_INC                              );
                  *(currentStep++) =   100                                   ; // X
                         _insertItem(  ITM_STO                              );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 1   ;
                         _insertItem(  ITM_CF)                               ;
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE       ;
                         _insertItem(  ITM_LBL)                              ;
                  *(currentStep++) =   100 + 'C' - 'A'                       ; // C
                         _insertItem(  ITM_RCL                              );
       _insertIndirectAccessRegister(  FIRST_LOCAL_REGISTER_IN_KS_CODE      );
                         _insertItem(  ITM_RCL                              );
       _insertIndirectAccessRegister(  FIRST_LOCAL_REGISTER_IN_KS_CODE + 1  );
                         _insertItem(  ITM_XLT                              );
                  *(currentStep++) =   101                                   ; // Y
                         _insertItem(  ITM_GTO                              );
                  *(currentStep++) =   100 + 'B' - 'A'                       ; // B
                         _insertItem(  ITM_LBL                              );
                  *(currentStep++) =   100 + 'D' - 'A'                       ; // D
                         _insertItem(  ITM_ISG                              );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE       ;
                         _insertItem(  ITM_ISG                              );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 1   ;
                         _insertItem(  ITM_GTO                              );
                  *(currentStep++) =   100 + 'C' - 'A'                       ; // C
                         _insertItem(  ITM_FS                               );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE       ;
                         _insertItem(  ITM_GTO                              );
                  *(currentStep++) =   100 + 'A' - 'A'                       ; // A
                         _insertItem(  ITM_RTN                              );
                         _insertItem(  ITM_LBL                              );
                  *(currentStep++) =   100 + 'B' - 'A'                       ; // B
                         _insertItem(  ITM_SF                               );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE       ;
                         _insertItem(  ITM_STO                              );
       _insertIndirectAccessRegister(  FIRST_LOCAL_REGISTER_IN_KS_CODE      );
                         _insertItem(  ITM_XexY                             );
                         _insertItem(  ITM_STO                              );
       _insertIndirectAccessRegister(  FIRST_LOCAL_REGISTER_IN_KS_CODE + 1  );
                         _insertItem(  ITM_XexY                             );
                         _insertItem(  ITM_GTO                              );
                  *(currentStep++) =   100 + 'D' - 'A'                       ; // D
                         _insertItem(  ITM_END                              );
  }

  { // OM page 226
                         _insertItem(  ITM_LBL                 );
          _insertLabelVariableString(  "OMp226"                );
                         _insertItem(  ITM_LBL                 );
          _insertLabelVariableString(  "Z"                     );
                         _insertItem(  ITM_SIGN                );
                         _insertItem(  ITM_LBL                 );
                  *(currentStep++) =   100 + 'A' - 'A'          ; // A
                         _insertItem(  ITM_RCL                 );
                  *(currentStep++) =   REGISTER_L_IN_KS_CODE    ;
                         _insertItem(  ITM_RCL                 );
                  *(currentStep++) =   REGISTER_L_IN_KS_CODE    ;
                         _insertItem(  ITM_RCL                 );
       _insertIndirectAccessRegister(  REGISTER_L_IN_KS_CODE   );
                         _insertItem(  ITM_LBL                 );
                  *(currentStep++) =   100 + 'B' - 'A'          ; // B
                         _insertItem(  ITM_RCL                 );
       _insertIndirectAccessRegister(  REGISTER_X_IN_KS_CODE   );
                         _insertItem(  ITM_XGT                 );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE    ;
                         _insertItem(  ITM_GTO                 );
                  *(currentStep++) =   100 + 'C' - 'A'          ; // C
                         _insertItem(  ITM_XexY                );
                         _insertItem(  ITM_RCL                 );
                  *(currentStep++) =   REGISTER_L_IN_KS_CODE    ;
                         _insertItem(  ITM_ADD                 );
                         _insertItem(  ITM_LBL                 );
                  *(currentStep++) =   100 + 'C' - 'A'          ; // C
                         _insertItem(  ITM_Rdown               );
                         _insertItem(  ITM_ISG                 );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE    ;
                         _insertItem(  ITM_GTO                 );
                  *(currentStep++) =   100 + 'B' - 'A'          ; // B
                         _insertItem(  ITM_Xex                 );
       _insertIndirectAccessRegister(  REGISTER_L_IN_KS_CODE   );
                         _insertItem(  ITM_STO                 );
       _insertIndirectAccessRegister(  REGISTER_Z_IN_KS_CODE   );
                         _insertItem(  ITM_ISG                 );
                  *(currentStep++) =   REGISTER_L_IN_KS_CODE    ;
                         _insertItem(  ITM_GTO                 );
                  *(currentStep++) =   100 + 'A' - 'A'          ; // A
                         _insertItem(  ITM_END                 );
  }

  { // OM page 233
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "OMp233"              );
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "PFall"               );
          _insertReal34StringLiteral(  ".5"                  );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_DELTA "t"         );
          _insertReal34StringLiteral(  ".003"                );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "b"                   );
          _insertReal34StringLiteral(  "1e3"                 );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "f"                   );
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  CST_18                );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "b"                   );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_SQUARE            );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_XGT               );
                  *(currentStep++) =   VALUE_0                ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_DROP              );
          _insertReal34StringLiteral(  "2"                   );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   3                      ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_DROP              );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   3                      ;
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_STOSUB            );
          _insertLabelVariableString(  "f"                   );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "f"                   );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_END               );
  }

  { // OM page 235
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "OMp235"              );
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "Osci"                );
          _insertReal34StringLiteral(  ".2"                  );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_DELTA "t"         );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_alpha             );
          _insertReal34StringLiteral(  ".5"                  );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_beta              );
          _insertReal34StringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_gamma             );
                         _insertItem(  ITM_RAD               );
          _insertReal34StringLiteral(  ".3"                  );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_omega             );
          _insertReal34StringLiteral(  "1.5"                 );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "f"                   );
          _insertReal34StringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "t")                   ;
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_omega             );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_sin               );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_gamma             );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_beta              );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_alpha             );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "f"                   );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_SUB               );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_XGT               );
                  *(currentStep++) =   VALUE_0                ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_DROP              );
     _insertLongIntegerStringLiteral(  "2"                   );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   3                      ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_DROP              );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   3                      ;
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_STOSUB            );
          _insertLabelVariableString(  "f"                   );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "f"                   );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "df" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_END               );
  }

  { // OM page 237
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "OMp237"              );
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "Satell"              );
                         _insertItem(  ITM_INPUT             );
          _insertLabelVariableString(  "x"                   );
                         _insertItem(  ITM_INPUT             );
          _insertLabelVariableString(  "y"                   );
                         _insertItem(  ITM_INPUT             );
          _insertLabelVariableString(  "dx" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_INPUT             );
          _insertLabelVariableString(  "dy" STD_DIVIDE "dt"  );
          _insertReal34StringLiteral(  ".1"                  );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  STD_DELTA "t"         );
     _insertLongIntegerStringLiteral(  "1"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "a"                   );
     _insertLongIntegerStringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "y"                   );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "y"                   );
                         _insertItem(  ITM_SQUARE            );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "x"                   );
                         _insertItem(  ITM_SQUARE            );
                         _insertItem(  ITM_ADD               );
          _insertReal34StringLiteral(  "-1.5"                );
                         _insertItem(  ITM_YX                );
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  "a"                   );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   108                    ; // L
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  "x"                   );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_XGT               );
                  *(currentStep++) =   VALUE_0                ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_DROP              );
     _insertLongIntegerStringLiteral(  "2"                   );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_XexY              );
     _insertLongIntegerStringLiteral(  "2"                   );
                         _insertItem(  ITM_DIV               );
                         _insertItem(  ITM_XexY              );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   3                      ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_DROP              );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   3                      ;
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOSUB            );
          _insertLabelVariableString(  "dx" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_DROP              );
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOSUB            );
          _insertLabelVariableString(  "dy" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "t"                   );
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  "dx" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "x"                   );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "x"                   );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_RCL               );
          _insertLabelVariableString(  STD_DELTA "t"         );
                         _insertItem(  ITM_RCLMULT           );
          _insertLabelVariableString(  "dy" STD_DIVIDE "dt"  );
                         _insertItem(  ITM_STOADD            );
          _insertLabelVariableString(  "y"                   );
                         _insertItem(  ITM_VIEW              );
          _insertLabelVariableString(  "y"                   );
                         _insertItem(  ITM_STOP              );
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_END               );
  }

  { // OM page 247 (for Σn)
                         _insertItem(  ITM_LBL          );
          _insertLabelVariableString(  STD_SIGMA "V"    );
                         _insertItem(  ITM_SQUAREROOTX  );
                         _insertItem(  ITM_RTN          );
                         _insertItem(  ITM_END          );
  }

  { // OM page 248 (for Πn)
                         _insertItem(  ITM_LBL          );
          _insertLabelVariableString(  "PROD"           );
                         _insertItem(  ITM_SQUAREROOTX  );
                         _insertItem(  ITM_1ONX         );
                         _insertItem(  ITM_RTN          );
                         _insertItem(  ITM_END          );
  }

  { // OM page 256 (for solver)
                         _insertItem(  ITM_LBL        );
          _insertLabelVariableString(  "FreeF"        );
                         _insertItem(  ITM_MVAR       );
          _insertLabelVariableString(  "height"       );
                         _insertItem(  ITM_MVAR       );
          _insertLabelVariableString(  "h" STD_SUB_0  );
                         _insertItem(  ITM_MVAR       );
          _insertLabelVariableString(  "v" STD_SUB_0  );
                         _insertItem(  ITM_MVAR       );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  CST_18         );
     _insertLongIntegerStringLiteral(  "-2"           );
                         _insertItem(  ITM_DIV        );
                         _insertItem(  ITM_RCLMULT    );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  ITM_RCLADD     );
          _insertLabelVariableString(  "v" STD_SUB_0  );
                         _insertItem(  ITM_RCLMULT    );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  ITM_RCLADD     );
          _insertLabelVariableString(  "h" STD_SUB_0  );
                         _insertItem(  ITM_RCLSUB     );
          _insertLabelVariableString(  "height"       );
                         _insertItem(  ITM_RTN        );
                         _insertItem(  ITM_END        );
  }

  { // No root (Const)
                         _insertItem(  ITM_LBL    );
          _insertLabelVariableString(  "SlvCnst"  );
                         _insertItem(  ITM_MVAR   );
          _insertLabelVariableString(  "x"        );
     _insertLongIntegerStringLiteral(  "3"        );
                         _insertItem(  ITM_RTN    );
                         _insertItem(  ITM_END    );
  }

  { // No root (Extremum)
                         _insertItem(  ITM_LBL      );
          _insertLabelVariableString(  "SlvExtr"    );
                         _insertItem(  ITM_MVAR     );
          _insertLabelVariableString(  "x"          );
                         _insertItem(  ITM_RCL      );
          _insertLabelVariableString(  "x"          );
                         _insertItem(  ITM_RCLMULT  );
          _insertLabelVariableString(  "x"          );
     _insertLongIntegerStringLiteral(  "1"          );
                         _insertItem(  ITM_ADD      );
                         _insertItem(  ITM_RTN      );
                         _insertItem(  ITM_END      );
  }

  { // OM page 258 (for solver)
                         _insertItem(  ITM_LBL        );
          _insertLabelVariableString(  "FreeFp"       );
                         _insertItem(  CST_18         );
     _insertLongIntegerStringLiteral(  "-2"           );
                         _insertItem(  ITM_DIV        );
                         _insertItem(  ITM_RCLMULT    );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  ITM_RCLADD     );
          _insertLabelVariableString(  "v" STD_SUB_0  );
                         _insertItem(  ITM_RCLMULT    );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  ITM_RCLADD     );
          _insertLabelVariableString(  "h" STD_SUB_0  );
                         _insertItem(  ITM_RCLSUB     );
          _insertLabelVariableString(  "height"       );
                         _insertItem(  ITM_RTN        );
                         _insertItem(  ITM_END        );
  }

  { // OM page 258 (calls the equation above)
                         _insertItem(  ITM_LBL        );
          _insertLabelVariableString(  "FreFp2"       );
     _insertLongIntegerStringLiteral(  "0"            );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "height"       );
     _insertLongIntegerStringLiteral(  "50"           );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "h" STD_SUB_0  );
     _insertLongIntegerStringLiteral(  "15"           );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "v" STD_SUB_0  );
     _insertLongIntegerStringLiteral(  "5"            );
                         _insertItem(  ITM_STO        );
          _insertLabelVariableString(  "time"         );
     _insertLongIntegerStringLiteral(  "10"           );
                         _insertItem(  ITM_PGMSLV     );
          _insertLabelVariableString(  "FreeFp"       );
                         _insertItem(  ITM_SOLVE      );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  ITM_VIEW       );
          _insertLabelVariableString(  "time"         );
                         _insertItem(  ITM_RTN        );
                         _insertItem(  ITM_END        );
  }

  { // OM page 263 (for integrator)
                         _insertItem(  ITM_LBL      );
          _insertLabelVariableString(  "IBessI"     );
                         _insertItem(  ITM_MVAR     );
          _insertLabelVariableString(  "x"          );
                         _insertItem(  ITM_MVAR     );
          _insertLabelVariableString(  "t"          );
                         _insertItem(  ITM_RCL      );
          _insertLabelVariableString(  "t"          );
                         _insertItem(  ITM_sin      );
                         _insertItem(  ITM_RCLMULT  );
          _insertLabelVariableString(  "x"          );
                         _insertItem(  ITM_cos      );
                         _insertItem(  ITM_RTN      );
                         _insertItem(  ITM_END      );
  }

  { // OM page 265 (for integrator)
                         _insertItem(  ITM_LBL      );
          _insertLabelVariableString(  "IBessP"     );
                         _insertItem(  ITM_RCL      );
          _insertLabelVariableString(  "t"          );
                         _insertItem(  ITM_sin      );
                         _insertItem(  ITM_RCLMULT  );
          _insertLabelVariableString(  "x"          );
                         _insertItem(  ITM_cos      );
                         _insertItem(  ITM_RTN      );
                         _insertItem(  ITM_END      );
  }

  { // OM page 265 (calls the equation above)
                         _insertItem(  ITM_LBL              );
          _insertLabelVariableString(  "IntP"               );
                         _insertItem(  ITM_RAD              );
     _insertLongIntegerStringLiteral(  "0"                  );
                         _insertItem(  ITM_STO              );
          _insertLabelVariableString(  "t"                  );
                         _insertItem(  ITM_PGMINT           );
          _insertLabelVariableString(  "IBessP"             );
     _insertLongIntegerStringLiteral(  "0"                  );
                         _insertItem(  ITM_STO              );
          _insertLabelVariableString(  STD_DOWN_ARROW "Lim" );
                         _insertItem(  ITM_CONSTpi          );
                         _insertItem(  ITM_STO              );
          _insertLabelVariableString(  STD_UP_ARROW "Lim"   );
          _insertReal34StringLiteral(  "0.001"              );
                         _insertItem(  ITM_STO              );
          _insertLabelVariableString(  "ACC"                );
                         _insertItem(  ITM_INTEGRAL         );
          _insertLabelVariableString(  "t"                  );
                         _insertItem(  ITM_VIEW             );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE ;
                         _insertItem(  ITM_CONSTpi          );
                         _insertItem(  ITM_DIV              );
                         _insertItem(  ITM_END              );
  }

  { // Elementary cellular automaton (for testing AGRAPH) [VERY SLOW ON DMCP]
                         _insertItem(  ITM_LBL               );
          _insertLabelVariableString(  "ECA"                 );
                         _insertItem(  ITM_UNSIGN            );
                         _insertItem(  ITM_WSIZE             );
                  *(currentStep++) =   64                     ;
                         _insertItem(  ITM_INPUT             );
          _insertLabelVariableString(  "RULE"                );
                         _insertItem(  ITM_toINT             );
                  *(currentStep++) =   10                     ;
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   REGISTER_K_IN_KS_CODE  ;
     _insertLongIntegerStringLiteral(  "0"                   );
     _insertLongIntegerStringLiteral(  "0"                   );
                         _insertItem(  ITM_CLLCD             );
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   1                      ;
     _insertLongIntegerStringLiteral(  "0"                   );
          _insertReal34StringLiteral(  "0.4"                 );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   40                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_CLX               );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   40                     ;
                         _insertItem(  ITM_IP                );
                         _insertItem(  ITM_AGRAPH            );
                  *(currentStep++) =   7                      ;
                         _insertItem(  ITM_DECR              );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE  ;
     _insertLongIntegerStringLiteral(  "64"                  );
                         _insertItem(  ITM_RCLADD            );
                  *(currentStep++) =   REGISTER_Z_IN_KS_CODE  ;
                         _insertItem(  ITM_XexY              );
                         _insertItem(  ITM_AGRAPH            );
                  *(currentStep++) =   8                      ;
                         _insertItem(  ITM_DECR              );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE  ;
     _insertLongIntegerStringLiteral(  "64"                  );
                         _insertItem(  ITM_RCLADD            );
                  *(currentStep++) =   REGISTER_Z_IN_KS_CODE  ;
                         _insertItem(  ITM_XexY              );
                         _insertItem(  ITM_AGRAPH            );
                  *(currentStep++) =   9                      ;
                         _insertItem(  ITM_DECR              );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE  ;
     _insertLongIntegerStringLiteral(  "64"                  );
                         _insertItem(  ITM_RCLADD            );
                  *(currentStep++) =   REGISTER_Z_IN_KS_CODE  ;
                         _insertItem(  ITM_XexY              );
                         _insertItem(  ITM_AGRAPH            );
                  *(currentStep++) =   10                     ;
                         _insertItem(  ITM_DECR              );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE  ;
     _insertLongIntegerStringLiteral(  "0"                   );
                         _insertItem(  ITM_XexY              );
                         _insertItem(  ITM_PAUSE             );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_ISE               );
                  *(currentStep++) =   40                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   70                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   71                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   70                     ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   71                     ;
                         _insertItem(  ITM_PAUSE             );
                  *(currentStep++) =   99                     ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   1                      ;
     _insertLongIntegerStringLiteral(  "17"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_Rdown             );
                         _insertItem(  ITM_FC                );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   50                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   55                     ;
                         _insertItem(  ITM_XEQ               );
                  *(currentStep++) =   51                     ;
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  44                    );
                         _insertItem(  ITM_Rdown             );
                         _insertItem(  ITM_DSL               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   55                     ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   50                     ;
    _insertShortIntegerStringLiteral(  "0", 16               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   56                     ;
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  44                    );
                         _insertItem(  ITM_DSL               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   56                     ;
                         _insertItem(  ITM_Rdown             );
    _insertShortIntegerStringLiteral(  "100000000000000", 16 );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   8                      ;
                         _insertItem(  ITM_Rdown             );
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   51                     ;
     _insertLongIntegerStringLiteral(  "64"                  );
                         _insertItem(  ITM_2X                );
                         _insertItem(  ITM_RAN               );
                         _insertItem(  ITM_MULT              );
                         _insertItem(  ITM_toINT             );
                  *(currentStep++) =   16                     ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_Xex               );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE  ;
                         _insertItem(  ITM_Yex               );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE  ;
          _insertReal34StringLiteral(  "37.02"               );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   65                     ;
    _insertShortIntegerStringLiteral(  "0", 16               );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  44                    );
                         _insertItem(  ITM_DSL               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   65                     ;
     _insertLongIntegerStringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   45                     ;
     _insertLongIntegerStringLiteral(  "20"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   46                     ;
     _insertLongIntegerStringLiteral(  "17"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   66                     ;
     _insertLongIntegerStringLiteral(  "63"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   63                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  45                    );
    _insertShortIntegerStringLiteral(  "3", 16               );
                         _insertItem(  ITM_SF                );
                  *(currentStep++) =   FLAG_C                 ;
                         _insertItem(  ITM_RLC               );
       _insertIndirectAccessRegister(  88                    );
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_RL                );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_RR                );
       _insertIndirectAccessRegister(  88                    );
                         _insertItem(  ITM_ENTER             );
                         _insertItem(  ITM_2X                );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   REGISTER_K_IN_KS_CODE  ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SR                );
       _insertIndirectAccessRegister(  REGISTER_Y_IN_KS_CODE );
                         _insertItem(  ITM_SL                );
       _insertIndirectAccessRegister(  88                    );
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  46                    );
                         _insertItem(  ITM_LOGICALOR         );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  46                    );
                         _insertItem(  ITM_DSL               );
                  *(currentStep++) =   88                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   63                     ;
                         _insertItem(  ITM_INC               );
                  *(currentStep++) =   45                     ;
                         _insertItem(  ITM_INC               );
                  *(currentStep++) =   46                     ;
                         _insertItem(  ITM_DSL               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   66                     ;
     _insertLongIntegerStringLiteral(  "0"                   );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   45                     ;
     _insertLongIntegerStringLiteral(  "20"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   46                     ;
     _insertLongIntegerStringLiteral(  "16"                  );
                         _insertItem(  ITM_STO               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_LBL               );
                  *(currentStep++) =   67                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  45                    );
                         _insertItem(  ITM_MASKL             );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SR                );
                  *(currentStep++) =   62                     ;
                         _insertItem(  ITM_INC               );
                  *(currentStep++) =   45                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  45                    );
                         _insertItem(  ITM_DECR              );
                  *(currentStep++) =   45                     ;
                         _insertItem(  ITM_MASKR             );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SL                );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_LOGICALOR         );
                         _insertItem(  ITM_ENTER             );
                         _insertItem(  ITM_2X                );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   REGISTER_K_IN_KS_CODE  ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SR                );
       _insertIndirectAccessRegister(  REGISTER_Y_IN_KS_CODE );
                         _insertItem(  ITM_SL                );
                  *(currentStep++) =   63                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  46                    );
                         _insertItem(  ITM_CB                );
                  *(currentStep++) =   63                     ;
                         _insertItem(  ITM_LOGICALOR         );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  46                    );
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  45                    );
                         _insertItem(  ITM_MASKL             );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SR                );
                  *(currentStep++) =   63                     ;
                         _insertItem(  ITM_INC               );
                  *(currentStep++) =   45                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  45                    );
                         _insertItem(  ITM_DECR              );
                  *(currentStep++) =   45                     ;
                         _insertItem(  ITM_MASKR             );
                  *(currentStep++) =   2                      ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SL                );
                  *(currentStep++) =   1                      ;
                         _insertItem(  ITM_LOGICALOR         );
                         _insertItem(  ITM_ENTER             );
                         _insertItem(  ITM_2X                );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   REGISTER_K_IN_KS_CODE  ;
                         _insertItem(  ITM_LOGICALAND        );
                         _insertItem(  ITM_SR                );
       _insertIndirectAccessRegister(  REGISTER_Y_IN_KS_CODE );
                         _insertItem(  ITM_INC               );
                  *(currentStep++) =   46                     ;
                         _insertItem(  ITM_RCL               );
       _insertIndirectAccessRegister(  46                    );
                         _insertItem(  ITM_CB                );
                  *(currentStep++) =   0                      ;
                         _insertItem(  ITM_LOGICALOR         );
                         _insertItem(  ITM_STO               );
       _insertIndirectAccessRegister(  46                    );
                         _insertItem(  ITM_INC               );
                  *(currentStep++) =   45                     ;
                         _insertItem(  ITM_DSL               );
                  *(currentStep++) =   44                     ;
                         _insertItem(  ITM_GTO               );
                  *(currentStep++) =   67                     ;
          _insertReal34StringLiteral(  "20.18"               );
                         _insertItem(  ITM_R_COPY            );
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE  ;
                         _insertItem(  ITM_RCL               );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE  ;
                         _insertItem(  ITM_RTN               );
                         _insertItem(  ITM_END               );
  }

  { // Another test for AGRAPH
                         _insertItem(  ITM_LBL                 );
          _insertLabelVariableString(  "PICTURE"               );
    _insertShortIntegerBinaryLiteral(  0xffffffffffffffff, 16  );
                         _insertItem(  ITM_STO                 );
                  *(currentStep++) =   0                        ;
    _insertShortIntegerBinaryLiteral(  0x8000000000000001, 16  );
                         _insertItem(  ITM_STO                 );
                  *(currentStep++) =   1                        ;
     _insertLongIntegerStringLiteral(  "62"                    );
                         _insertItem(  ITM_STO                 );
                  *(currentStep++) =   2                        ;
     _insertLongIntegerStringLiteral(  "100"                   );
                         _insertItem(  ITM_ENTER               );
     _insertLongIntegerStringLiteral(  "151"                   );
                         _insertItem(  ITM_CLLCD               );
                         _insertItem(  ITM_AGRAPH              );
                  *(currentStep++) =   0                        ;
                         _insertItem(  ITM_AGRAPH              );
                  *(currentStep++) =   0                        ;
                         _insertItem(  ITM_LBL                 );
                  *(currentStep++) =   1                        ;
                         _insertItem(  ITM_AGRAPH              );
                  *(currentStep++) =   1                        ;
                         _insertItem(  ITM_DSE                 );
                  *(currentStep++) =   2                        ;
                         _insertItem(  ITM_GTO                 );
                  *(currentStep++) =   1                        ;
                         _insertItem(  ITM_AGRAPH              );
                  *(currentStep++) =   0                        ;
                         _insertItem(  ITM_AGRAPH              );
                  *(currentStep++) =   0                        ;
                         _insertItem(  ITM_RTN                 );
                         _insertItem(  ITM_END                 );
  }

  { // Logarithmic spiral (test for POINT)
                         _insertItem(  ITM_LBL                             );
          _insertLabelVariableString(  "SPIRAL"                            );
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE                ;
                         _insertItem(  ITM_XEQU                            );
                  *(currentStep++) =   VALUE_0                              ;
          _insertReal34StringLiteral(  "1."                                );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE                ;
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE                ;
                         _insertItem(  ITM_XEQU                            );
                  *(currentStep++) =   VALUE_0                              ;
          _insertReal34StringLiteral(  "0.3"                               );
                         _insertItem(  ITM_MAGNITUDE                       );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE                ;
                         _insertItem(  ITM_LocR                            );
                  *(currentStep++) =   4                                    ;
     _insertLongIntegerStringLiteral(  "1"                                 );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
     _insertLongIntegerStringLiteral(  "0"                                 );
                         _insertItem(  ITM_ENTER                           );
                         _insertItem(  ITM_CLLCD                           );
                         _insertItem(  ITM_LBL                             );
                  *(currentStep++) =   0                                    ;
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
          _insertReal34StringLiteral(  "500."                              );
                         _insertItem(  ITM_DIV                             );
                         _insertItem(  ITM_ENTER                           );
                         _insertItem(  ITM_ENTER                           );
                         _insertItem(  ITM_RAD2                            );
                         _insertItem(  ITM_sin                             );
                         _insertItem(  ITM_XexY                            );
                         _insertItem(  ITM_RCLMULT                         );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE                ;
                         _insertItem(  ITM_EXP                             );
                         _insertItem(  ITM_MULT                            );
                         _insertItem(  ITM_RCLMULT                         );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE                ;
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 1  ;
                         _insertItem(  ITM_XexY                            );
                         _insertItem(  ITM_ENTER                           );
                         _insertItem(  ITM_RAD2                            );
                         _insertItem(  ITM_cos                             );
                         _insertItem(  ITM_XexY                            );
                         _insertItem(  ITM_RCLMULT                         );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE                ;
                         _insertItem(  ITM_EXP                             );
                         _insertItem(  ITM_MULT                            );
                         _insertItem(  ITM_RCLMULT                         );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE                ;
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 2  ;
                         _insertItem(  ITM_toPOL2                          );
                         _insertItem(  ITM_FC                              );
                  *(currentStep++) =   SYSTEM_FLAG_NUMBER                   ;
                  *(currentStep++) =   FLAG_HPRP & 0xff                     ;
                         _insertItem(  ITM_XexY                            );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 3  ;
     _insertLongIntegerStringLiteral(  "234"                               );
                         _insertItem(  ITM_XLE                             );
                  *(currentStep++) =   REGISTER_Y_IN_KS_CODE                ;
                         _insertItem(  ITM_RTN                             );
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 1  ;
     _insertLongIntegerStringLiteral(  "120"                               );
                         _insertItem(  ITM_ADD                             );
                         _insertItem(  ITM_ROUNDI2                         );
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 2  ;
     _insertLongIntegerStringLiteral(  "200"                               );
                         _insertItem(  ITM_ADD                             );
                         _insertItem(  ITM_ROUNDI2                         );
                         _insertItem(  ITM_SF                              );
                  *(currentStep++) =   SYSTEM_FLAG_NUMBER                   ;
                  *(currentStep++) =   FLAG_IGN1ER & 0xff                   ;
                         _insertItem(  ITM_POINT                           );
                         _insertItem(  ITM_CF                              );
                  *(currentStep++) =   SYSTEM_FLAG_NUMBER                   ;
                  *(currentStep++) =   FLAG_IGN1ER & 0xff                   ;
                         _insertItem(  ITM_PAUSE                           );
                  *(currentStep++) =   0                                    ;
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 3  ;
                         _insertItem(  ITM_1ONX                            );
                         _insertItem(  ITM_SDL                             );
                  *(currentStep++) =   3                                    ;
                         _insertItem(  ITM_IP                              );
                         _insertItem(  ITM_INC                             );
                  *(currentStep++) =   REGISTER_X_IN_KS_CODE                ;
                         _insertItem(  ITM_STOADD                          );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
                         _insertItem(  ITM_GTO                             );
                  *(currentStep++) =   0                                    ;
                         _insertItem(  ITM_END                             );
  }

  { // Lissajous curve (test for PIXEL)
                         _insertItem(  ITM_LBL                             );
          _insertLabelVariableString(  "LISSAJ"                            );
                         _insertItem(  ITM_RAD                             );
                         _insertItem(  ITM_LocR                            );
                  *(currentStep++) =   5                                    ;
     _insertLongIntegerStringLiteral(  "200"                               );
                         _insertItem(  ITM_CONSTpi                         );
                         _insertItem(  ITM_MULT                            );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 3  ;
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE                ;
                         _insertItem(  ITM_MAGNITUDE                       );
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE                ;
                         _insertItem(  ITM_MAGNITUDE                       );
                         _insertItem(  ITM_MAX                             );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 4  ;
                         _insertItem(  ITM_STOMULT                         );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 3  ;
     _insertLongIntegerStringLiteral(  "0"                                 );
                         _insertItem(  ITM_ENTER                           );
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
                         _insertItem(  ITM_CLLCD                           );
                         _insertItem(  ITM_LBL                             );
                  *(currentStep++) =   0                                    ;
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
                         _insertItem(  ITM_toREAL                          );
                         _insertItem(  ITM_SDR                             );
                  *(currentStep++) =   2                                    ;
                         _insertItem(  ITM_ENTER                           );
                         _insertItem(  ITM_RCLMULT                         );
                  *(currentStep++) =   REGISTER_J_IN_KS_CODE                ;
                         _insertItem(  ITM_RCLDIV                          );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 4  ;
                         _insertItem(  ITM_RCLADD                          );
                  *(currentStep++) =   REGISTER_K_IN_KS_CODE                ;
                         _insertItem(  ITM_sin                             );
                         _insertItem(  ITM_SDL                             );
                  *(currentStep++) =   2                                    ;
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 1  ;
                         _insertItem(  ITM_XexY                            );
                         _insertItem(  ITM_RCLMULT                         );
                  *(currentStep++) =   REGISTER_I_IN_KS_CODE                ;
                         _insertItem(  ITM_RCLDIV                          );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 4  ;
                         _insertItem(  ITM_cos                             );
                         _insertItem(  ITM_SDL                             );
                  *(currentStep++) =   2                                    ;
                         _insertItem(  ITM_STO                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 2  ;
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 3  ;
                         _insertItem(  ITM_XLT                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
                         _insertItem(  ITM_RTN                             );
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 1  ;
     _insertLongIntegerStringLiteral(  "120"                               );
                         _insertItem(  ITM_ADD                             );
                         _insertItem(  ITM_ROUNDI2                         );
                         _insertItem(  ITM_RCL                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 2  ;
     _insertLongIntegerStringLiteral(  "200"                               );
                         _insertItem(  ITM_ADD                             );
                         _insertItem(  ITM_ROUNDI2                         );
                         _insertItem(  ITM_SF                              );
                  *(currentStep++) =   SYSTEM_FLAG_NUMBER                   ;
                  *(currentStep++) =   FLAG_IGN1ER & 0xff                   ;
                         _insertItem(  ITM_PIXEL                           );
                         _insertItem(  ITM_CF                              );
                  *(currentStep++) =   SYSTEM_FLAG_NUMBER                   ;
                  *(currentStep++) =   FLAG_IGN1ER & 0xff                   ;
                         _insertItem(  ITM_PAUSE                           );
                  *(currentStep++) =   0                                    ;
                         _insertItem(  ITM_INC                             );
                  *(currentStep++) =   FIRST_LOCAL_REGISTER_IN_KS_CODE + 0  ;
                         _insertItem(  ITM_GTO                             );
                  *(currentStep++) =   0                                    ;
                         _insertItem(  ITM_END                             );
  }

  { // All OP's
                         _insertItem(ITM_LBL);
          _insertLabelVariableString("AllOps");

    int32_t item;
    for(item=1; item<LAST_ITEM; item++) {
      switch (indexOfItems[item].status & PTP_STATUS) {
        case PTP_NONE: {
          if(item != ITM_END) {
                               _insertItem(item);
          }
          break;
        }
        case PTP_DECLARE_LABEL: {
                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

                               _insertItem(item);
                        *(currentStep++) = 'A' - 'A' + 100; // A

                               _insertItem(item);
                        *(currentStep++) = 'L' - 'A' + 100; // L

                               _insertItem(item);
                        *(currentStep++) = 'a' - 'a' + FIRST_LC_LOCAL_LABEL;  // a

                               _insertItem(item);
                        *(currentStep++) = 'l' - 'a' + FIRST_LC_LOCAL_LABEL;  // l

                               _insertItem(item);
                _insertLabelVariableString("C" STD_i_ACUTE "mke");

          break;
        }
        case PTP_LABEL: {
                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;


                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;


                               _insertItem(item);
                        *(currentStep++) = 'A' - 'A' + 100; // A

                               _insertItem(item);
                        *(currentStep++) = 'L' - 'A' + 100; // L

                               _insertItem(item);
                        *(currentStep++) = 'a' - 'a' + FIRST_LC_LOCAL_LABEL;  // a

                               _insertItem(item);
                        *(currentStep++) = 'l' - 'a' + FIRST_LC_LOCAL_LABEL;  // l

                               _insertItem(item);
                _insertLabelVariableString("C" STD_i_ACUTE "mke");

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);


                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);


                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);


                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);


                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);


                               _insertItem(item);
             _insertIndirectAccessVariable("Var" STD_alpha);

          break;
        }
        case PTP_REGISTER: {
                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

                               _insertItem(item);
                        *(currentStep++) = REGISTER_X_IN_KS_CODE;

                               _insertItem(item);
                        *(currentStep++) = REGISTER_W_IN_KS_CODE;

                               _insertItem(item);
                        *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

                               _insertItem(item);
                        *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

                               _insertItem(item);
                _insertLabelVariableString("Var");

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessVariable("Var");

          break;
        }
        case PTP_FLAG: {
                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

                               _insertItem(item);
                        *(currentStep++) = FLAG_X;

                               _insertItem(item);
                        *(currentStep++) = FLAG_K;

                               _insertItem(item);
                        *(currentStep++) = FLAG_M;

                               _insertItem(item);
                        *(currentStep++) = FLAG_W;

                               _insertItem(item);
                        *(currentStep++) = FIRST_LOCAL_FLAG;

                               _insertItem(item);
                        *(currentStep++) = LAST_LOCAL_FLAG;

                               _insertItem(item);
                        *(currentStep++) = SYSTEM_FLAG_NUMBER;
                        *(currentStep++) = 0;

                               _insertItem(item);
                        *(currentStep++) = SYSTEM_FLAG_NUMBER;
                        *(currentStep++) = NUMBER_OF_SYSTEM_FLAGS - 1;

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_FLAG);

                               _insertItem(item);
             _insertIndirectAccessVariable("Var");
          break;
        }
        case PTP_NUMBER_8: {
                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessVariable("Var");

          break;
        }
        case PTP_NUMBER_16: {
          if(isFunctionOldParam16(item)) {  // original Param16 functions without indirection support (little endian parameter)
                                 _insertItem(item);
                          *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) & 0xff; // little endian
                          *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) >> 8;

                                 _insertItem(item);
                          *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) & 0xff;  // little endian
                          *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) >> 8;
          }
          else {                        // new Param16 functions with indirection support (big endian parameter)
                                 _insertItem(item);
                          *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) >> 8;   // BIG endian
                          *(currentStep++) = (indexOfItems[item].tamMinMax >> TAM_MAX_BITS) & 0xff;

                                 _insertItem(item);
                          *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) >> 8;    // BIG endian
                          *(currentStep++) = (indexOfItems[item].tamMinMax & TAM_MAX_MASK) & 0xff;

                                 _insertItem(item);
               _insertIndirectAccessRegister(0);

                                 _insertItem(item);
               _insertIndirectAccessRegister(99);

                                 _insertItem(item);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(item);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(item);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(item);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(item);
               _insertIndirectAccessVariable("Var");
          }
          break;
        }

        case PTP_COMPARE: {
                               _insertItem(item);
                        *(currentStep++) = VALUE_0;

                               _insertItem(item);
                        *(currentStep++) = VALUE_1;

                               _insertItem(item);
                        *(currentStep++) = 0;

                               _insertItem(item);
                        *(currentStep++) = 99;

                               _insertItem(item);
                        *(currentStep++) = REGISTER_X_IN_KS_CODE;

                               _insertItem(item);
                        *(currentStep++) = REGISTER_W_IN_KS_CODE;

                               _insertItem(item);
                        *(currentStep++) = FIRST_LOCAL_REGISTER_IN_KS_CODE;

                               _insertItem(item);
                        *(currentStep++) = LAST_LOCAL_REGISTER_IN_KS_CODE;

                               _insertItem(item);
                _insertLabelVariableString("Var");

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessVariable("Var");

          break;
        }

        case PTP_KEYG_KEYX: {
          for(int i=0; i<=1; i++) {
            int32_t op = (i == 0 ? ITM_GTO : ITM_XEQ);
                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 1;
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
                          *(currentStep++) = 21;
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(0);
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(99);
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
                          *(currentStep++) = 0;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
                          *(currentStep++) = 99;

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
                          *(currentStep++) = 'A' - 'A' + 100; // A

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
                          *(currentStep++) = 'E' - 'A' + 100; // E

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
                  _insertLabelVariableString("Label");

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(0);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(99);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                                 _insertItem(ITM_KEY);
               _insertIndirectAccessVariable("Var");
                          *(currentStep++) = op;
               _insertIndirectAccessVariable("Var");
          }
          break;
        }

        case PTP_SKIP_BACK: {
                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax >> TAM_MAX_BITS;

                               _insertItem(item);
                        *(currentStep++) = indexOfItems[item].tamMinMax & TAM_MAX_MASK;

          break;
        }

        case PTP_NUMBER_8_16: {
                               _insertItem(item);
                        *(currentStep++) =  1;

                               _insertItem(item);
                        *(currentStep++) =  79;

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);

                               _insertItem(item);
          _insertIndirectAccessVariable("Var");

          break;
        }

        case PTP_SHUFFLE: {
                               _insertItem(item);
                        *(currentStep++) = 0;

                               _insertItem(item);
                        *(currentStep++) = 27;

                               _insertItem(item);
                        *(currentStep++) = 228;

                               _insertItem(item);
                        *(currentStep++) = 255;

          break;
        }

        case PTP_MENU: {
                               _insertItem(item);
                _insertLabelVariableString("Menu");

                               _insertItem(item);
             _insertIndirectAccessRegister(0);

                               _insertItem(item);
             _insertIndirectAccessRegister(99);


                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_X_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_K_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_M_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(REGISTER_W_IN_KS_CODE);

                               _insertItem(item);
             _insertIndirectAccessRegister(FIRST_LOCAL_REGISTER_IN_KS_CODE);


                               _insertItem(item);
             _insertIndirectAccessRegister(LAST_LOCAL_REGISTER_IN_KS_CODE);


                               _insertItem(item);
          _insertIndirectAccessVariable("Var");

          break;
        }

        case PTP_LITERAL: {
          _insertShortIntegerBinaryLiteral(0xf807060504030201, 2);
          _insertShortIntegerBinaryLiteral(0xf807060504030201, 3);
          _insertShortIntegerBinaryLiteral(0xf807060504030201, 4);
          _insertShortIntegerBinaryLiteral(0xf807060504030201, 8);
          _insertShortIntegerBinaryLiteral(0xf807060504030201, 10);
          _insertShortIntegerBinaryLiteral(0xf807060504030201, 16);
                               _insertItem(ITM_NOP); // TODO: implement ITM_LITERAL BINARY_LONG_INTEGER
                _insertReal34BinaryLiteral("4.224835011040144513774020064192513e-6083");
             _insertComplex34BinaryLiteral("4.224835011040144513774020064192513e-6083", "4.81839027104401517790084321196529e-1924");
          _insertShortIntegerStringLiteral("ABCDEF", 16);
          _insertShortIntegerStringLiteral("-ABCDEF", 16);
           _insertLongIntegerStringLiteral("-12345");
             _insertComplex34StringLiteral("1-i2");
                  _insertTimeStringLiteral("21.2345");
                  _insertTimeStringLiteral("-1.2345");
                  _insertDateStringLiteral("2456789");
              _insertAngleDmsStringLiteral("71.2345");
              _insertAngleDmsStringLiteral("-1.2345");
           _insertAngleRadianStringLiteral("1.2345");
           _insertAngleRadianStringLiteral("-1.2345");
             _insertAngleGradStringLiteral("198.2345");
             _insertAngleGradStringLiteral("-1.2345");
           _insertAngleDegreeStringLiteral("179.2345");
           _insertAngleDegreeStringLiteral("-1.2345");
           _insertAngleMultpiStringLiteral("1.2345");
           _insertAngleMultpiStringLiteral("-1.2345");
                      _insertStringLiteral("");
                      _insertStringLiteral("A message in English");
                      _insertStringLiteral("Une cha" STD_i_CIRC "ne en fran" STD_c_CEDILLA "ais");
          break;
        }

        case PTP_REM:
          _insertComment("This is a comment.");
          break;

        case PTP_DISABLED:
          break;
      }
    }
                         _insertItem(ITM_END);
  }




//-----JACO GENERATED FROM SPREADSHEET vvvvvvvvvv

{ // JACO EX DEMO OM p 111 (Gilileo's example from HP-27 OH)
                         _insertItem(ITM_LBL);
          _insertLabelVariableString("STAT111");
                         _insertItem(ITM_CLSIGMA);

          _insertReal34StringLiteral("30");
          _insertReal34StringLiteral("2.0");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("50");
          _insertReal34StringLiteral("2.5");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("90");
          _insertReal34StringLiteral("3.5");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("130");
          _insertReal34StringLiteral("4.0");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("150");
          _insertReal34StringLiteral("4.5");
                         _insertItem(ITM_SIGMAPLUS);

                         _insertItem(ITM_BESTF);
                  *(currentStep++) = 0;
                  *(currentStep++) = 0;

                         _insertItem(ITM_LR);
                         _insertItem(ITM_PLOT_ASSESS);
                         _insertItem(ITM_END);

}


{ // JACO EX DEMO OM p113 (Hephaestus example from various HP sources as per Walter
                         _insertItem(ITM_LBL);
          _insertLabelVariableString("STAT113");
                         _insertItem(ITM_CLSIGMA);

          _insertReal34StringLiteral("696");
          _insertReal34StringLiteral("1945");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1330");
          _insertReal34StringLiteral("1955");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1750");
          _insertReal34StringLiteral("1965");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2243");
          _insertReal34StringLiteral("1971");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2484");
          _insertReal34StringLiteral("1973");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("994");
          _insertReal34StringLiteral("1950");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1512");
          _insertReal34StringLiteral("1960");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2162");
          _insertReal34StringLiteral("1970");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2382");
          _insertReal34StringLiteral("1972");
                         _insertItem(ITM_SIGMAPLUS);

                         _insertItem(ITM_BESTF);
                  *(currentStep++) = 0;
                  *(currentStep++) = 0;

                         _insertItem(ITM_LR);
                         _insertItem(ITM_PLOT_ASSESS);
                         _insertItem(ITM_END);

}



{ //  JACO EX DEMO OM p115 (Silas example from the HP-15C OH
                         _insertItem(ITM_LBL);
          _insertLabelVariableString("STAT115");
                         _insertItem(ITM_CLSIGMA);

          _insertReal34StringLiteral("4.63");
          _insertReal34StringLiteral("0");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("5.78");
          _insertReal34StringLiteral("20");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("6.61");
          _insertReal34StringLiteral("40");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("7.21");
          _insertReal34StringLiteral("60");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("7.78");
          _insertReal34StringLiteral("80");
                         _insertItem(ITM_SIGMAPLUS);

                         _insertItem(ITM_BESTF);
                  *(currentStep++) = 0;
                  *(currentStep++) = 0;

                         _insertItem(ITM_LR);
                         _insertItem(ITM_PLOT_ASSESS);
                         _insertItem(ITM_END);
}



{ // JACO EX DEMO0 is a 100 point Gaussian perfect distribution.
                         _insertItem(ITM_LBL);
          _insertLabelVariableString("STAT000");
                         _insertItem(ITM_CLSIGMA);

          _insertReal34StringLiteral("-5.0");
          _insertReal34StringLiteral("1.3887943864964e-11");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.9");
          _insertReal34StringLiteral("3.73757132794424e-11");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.8");
          _insertReal34StringLiteral("9.85950557599145e-11");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.7");
          _insertReal34StringLiteral("2.54938188039194e-10");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.6");
          _insertReal34StringLiteral("6.46143177310602e-10");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.5");
          _insertReal34StringLiteral("1.60522805518558e-09");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.4");
          _insertReal34StringLiteral("3.90893843426479e-09");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.3");
          _insertReal34StringLiteral("9.33028757450481e-09");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.2");
          _insertReal34StringLiteral("2.18295779512542e-08");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.1");
          _insertReal34StringLiteral("5.00621802076691e-08");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-4.0");
          _insertReal34StringLiteral("1.12535174719256e-07");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.9");
          _insertReal34StringLiteral("2.47959601804496e-07");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.8");
          _insertReal34StringLiteral("5.35534780279297e-07");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.7");
          _insertReal34StringLiteral("1.13372713874794e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.6");
          _insertReal34StringLiteral("2.35257520000972e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.5");
          _insertReal34StringLiteral("4.78511739212891e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.4");
          _insertReal34StringLiteral("9.54016287307904e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.3");
          _insertReal34StringLiteral("1.86437423315165e-05");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.2");
          _insertReal34StringLiteral("3.57128496416346e-05");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.1");
          _insertReal34StringLiteral("6.70548243028099e-05");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-3.0");
          _insertReal34StringLiteral("0.000123409804086678");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.9");
          _insertReal34StringLiteral("0.000222629856918886");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.8");
          _insertReal34StringLiteral("0.000393669040655073");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.7");
          _insertReal34StringLiteral("0.000682328052756367");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.6");
          _insertReal34StringLiteral("0.00115922917390458");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.5");
          _insertReal34StringLiteral("0.00193045413622769");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.4");
          _insertReal34StringLiteral("0.00315111159844441");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.3");
          _insertReal34StringLiteral("0.00504176025969093");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.2");
          _insertReal34StringLiteral("0.00790705405159337");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.1");
          _insertReal34StringLiteral("0.0121551783299148");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-2.0");
          _insertReal34StringLiteral("0.0183156388887341");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.9");
          _insertReal34StringLiteral("0.0270518468663502");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.8");
          _insertReal34StringLiteral("0.0391638950989869");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.7");
          _insertReal34StringLiteral("0.0555762126114828");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.6");
          _insertReal34StringLiteral("0.0773047404432994");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.5");
          _insertReal34StringLiteral("0.105399224561864");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.4");
          _insertReal34StringLiteral("0.140858420921045");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.3");
          _insertReal34StringLiteral("0.184519523992989");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.2");
          _insertReal34StringLiteral("0.236927758682121");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.1");
          _insertReal34StringLiteral("0.298197279429887");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-1.0");
          _insertReal34StringLiteral("0.367879441171442");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.9");
          _insertReal34StringLiteral("0.44485806622294");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.8");
          _insertReal34StringLiteral("0.527292424043048");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.7");
          _insertReal34StringLiteral("0.612626394184415");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.6");
          _insertReal34StringLiteral("0.69767632607103");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.5");
          _insertReal34StringLiteral("0.778800783071404");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.4");
          _insertReal34StringLiteral("0.852143788966211");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.3");
          _insertReal34StringLiteral("0.913931185271228");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.2");
          _insertReal34StringLiteral("0.960789439152323");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("-0.1");
          _insertReal34StringLiteral("0.990049833749168");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.0");
          _insertReal34StringLiteral("1");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.1");
          _insertReal34StringLiteral("0.990049833749168");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.2");
          _insertReal34StringLiteral("0.960789439152324");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.3");
          _insertReal34StringLiteral("0.913931185271229");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.4");
          _insertReal34StringLiteral("0.852143788966212");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.5");
          _insertReal34StringLiteral("0.778800783071406");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.6");
          _insertReal34StringLiteral("0.697676326071032");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.7");
          _insertReal34StringLiteral("0.612626394184417");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.8");
          _insertReal34StringLiteral("0.527292424043049");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.9");
          _insertReal34StringLiteral("0.444858066222942");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.0");
          _insertReal34StringLiteral("0.367879441171443");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.1");
          _insertReal34StringLiteral("0.298197279429888");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.2");
          _insertReal34StringLiteral("0.236927758682122");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.3");
          _insertReal34StringLiteral("0.18451952399299");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.4");
          _insertReal34StringLiteral("0.140858420921045");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.5");
          _insertReal34StringLiteral("0.105399224561865");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.6");
          _insertReal34StringLiteral("0.0773047404432999");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.7");
          _insertReal34StringLiteral("0.0555762126114832");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.8");
          _insertReal34StringLiteral("0.0391638950989871");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.9");
          _insertReal34StringLiteral("0.0270518468663504");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.0");
          _insertReal34StringLiteral("0.0183156388887342");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.1");
          _insertReal34StringLiteral("0.012155178329915");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.2");
          _insertReal34StringLiteral("0.00790705405159345");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.3");
          _insertReal34StringLiteral("0.00504176025969098");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.4");
          _insertReal34StringLiteral("0.00315111159844444");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.5");
          _insertReal34StringLiteral("0.00193045413622771");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.6");
          _insertReal34StringLiteral("0.00115922917390459");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.7");
          _insertReal34StringLiteral("0.000682328052756376");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.8");
          _insertReal34StringLiteral("0.000393669040655078");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("2.9");
          _insertReal34StringLiteral("0.000222629856918889");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.0");
          _insertReal34StringLiteral("0.000123409804086679");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.1");
          _insertReal34StringLiteral("6.70548243028109e-05");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.2");
          _insertReal34StringLiteral("3.57128496416351e-05");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.3");
          _insertReal34StringLiteral("1.86437423315168e-05");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.4");
          _insertReal34StringLiteral("9.54016287307918e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.5");
          _insertReal34StringLiteral("4.78511739212897e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.6");
          _insertReal34StringLiteral("2.35257520000976e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.7");
          _insertReal34StringLiteral("1.13372713874796e-06");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.8");
          _insertReal34StringLiteral("5.35534780279306e-07");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("3.9");
          _insertReal34StringLiteral("2.47959601804501e-07");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.0");
          _insertReal34StringLiteral("1.12535174719258e-07");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.1");
          _insertReal34StringLiteral("5.00621802076701e-08");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.2");
          _insertReal34StringLiteral("2.18295779512548e-08");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.3");
          _insertReal34StringLiteral("9.33028757450501e-09");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.4");
          _insertReal34StringLiteral("3.90893843426488e-09");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.5");
          _insertReal34StringLiteral("1.60522805518562e-09");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.6");
          _insertReal34StringLiteral("6.46143177310618e-10");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.7");
          _insertReal34StringLiteral("2.54938188039201e-10");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.8");
          _insertReal34StringLiteral("9.85950557599169e-11");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("4.9");
          _insertReal34StringLiteral("3.73757132794435e-11");
                         _insertItem(ITM_XexY);
                         _insertItem(ITM_SIGMAPLUS);

                         _insertItem(ITM_BESTF);
                  *(currentStep++) = 0;
                  *(currentStep++) = 0;

                         _insertItem(ITM_LR);
                         _insertItem(ITM_PLOT_ASSESS);
                         _insertItem(ITM_END);
}


{ // JACO EX DEMO2 is a 4 sample example which produces valid values for L.R. to be Gaussian peak, Cauchy and parabolic.
                         _insertItem(ITM_LBL);
          _insertLabelVariableString("STAT002");

                         _insertItem(ITM_CLSIGMA);

          _insertReal34StringLiteral("0.0905");
          _insertReal34StringLiteral("-0.1");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("1.0000");
          _insertReal34StringLiteral("0");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.0905");
          _insertReal34StringLiteral("+0.1");
                         _insertItem(ITM_SIGMAPLUS);

          _insertReal34StringLiteral("0.8");
          _insertReal34StringLiteral("0.01");
                         _insertItem(ITM_SIGMAPLUS);

                         _insertItem(ITM_BESTF);
                  *(currentStep++) = 0;
                  *(currentStep++) = 0;

                         _insertItem(ITM_LR);
                         _insertItem(ITM_PLOT_ASSESS);
                         _insertItem(ITM_END);
}


{ // JACO EX DEMO1 is the 100 pair 11 000 V instrumentation example.
                         _insertItem(  ITM_LBL          );
          _insertLabelVariableString(  "STAT001"        );
                         _insertItem(  ITM_CLSIGMA      );
          _insertReal34StringLiteral(  "100"            );
                         _insertItem(  ITM_STO          );
                  *(currentStep++) =   0                 ;
                         _insertItem(  ITM_LBL          );

          _insertLabelVariableString(  "LP1a"           );
          _insertReal34StringLiteral(  "11000"          );
                         _insertItem(  ITM_RAN          );
          _insertReal34StringLiteral(  "22"             );
                         _insertItem(  ITM_MULT         );
                         _insertItem(  ITM_ADD          );
                         _insertItem(  ITM_STO          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_RAN          );
          _insertReal34StringLiteral(  "4"              );
                         _insertItem(  ITM_MULT         );
                         _insertItem(  ITM_ADD          );
                         _insertItem(  ITM_RCL          );
                  *(currentStep++) =   1                 ;
                         _insertItem(  ITM_RAN          );
          _insertReal34StringLiteral(  "4"              );
                         _insertItem(  ITM_MULT         );
                         _insertItem(  ITM_ADD          );
                         _insertItem(  ITM_SIGMAPLUS    );
                         _insertItem(  ITM_DSZ          );
                  *(currentStep++) =   0                 ;
                         _insertItem(  ITM_GTO          );
          _insertLabelVariableString(  "LP1a"           );

                         _insertItem(  ITM_PLOT_SCATR   );
                         _insertItem(  ITM_PLOT_CENTRL  );
                         _insertItem(  ITM_END          );
}


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
