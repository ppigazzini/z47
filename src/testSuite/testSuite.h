// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The WP43 and C47 Authors

/********************************************//**
 * \file testSuite.h
 ***********************************************/

#define FUNC_TO_TEST  0
#define FUNC_CVT      1

#define RE_ACCURATE   0
#define RE_INACCURATE 1


typedef struct {
  char     name[25];
  void     (*func)(uint16_t);
} funcTest_t;

void strToShortInteger        (char *nimBuffer, calcRegister_t regist);
char *endOfString             (char *string);
char hexToChar                (const char *string);
void setParameter             (char *p);
void inParameters             (char *token);
void checkRegisterType        (calcRegister_t regist, char letter, uint32_t expectedDataType, uint32_t expectedTag);
void checkExpectedOutParameter(char *p);
void outParameters            (char *token);
void functionToCall           (char *functionName);
void abortTest                (void);
void standardizeLine          (void);
void processLine              (void);
void processOneFile           (void);
int  processTests             (const char *listPath);
int  relativeErrorReal34      (real34_t *expectedValue34, real34_t *value34, char *numberPart, calcRegister_t regist, char letter);
void wrongRegisterValue       (calcRegister_t regist, char letter, char *expectedValue);
void expectedAndShouldBeValue (calcRegister_t regist, char letter, char *expectedValue, char *expectedAndValue);
void updateMatrixHeightCache  (void);
void tamEnterMode             (int16_t func);
