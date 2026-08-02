// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

/**
 * \file value.c
 * \brief Data type aware value type processing for T47 DSL
 */

#include "value.h"

#if defined(PC_BUILD)

#include <ctype.h>
#include <jim.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "c47.h"
#include "dateTime.h"
#include "registerValueConversions.h"

/**
 * True when the argument is not supported in scripts.
 */
static bool_t dslUnsupportedArg(Jim_Interp *interp, const char *arg, const char *kind) {
  if(arg[0] == '.' && arg[1] != '\0') {
    Jim_SetResultFormatted(interp, "local %s '.NN' not supported in scripts", kind);
    return TRUE;
  }
  if(arg[0] == '-' && arg[1] == '>') {
    Jim_SetResultFormatted(interp, "indirect %s '->...' not supported in scripts", kind);
    return TRUE;
  }
  return FALSE;
}

/**
 * Return the register number for a given letter.
 */
static int16_t dslRegisterFromLetter(char letter) {
  const char *p = strchr(registerFlagLetters, toupper((unsigned char)letter));
  if(!p) {
    return INVALID_VARIABLE;
  }
  int idx = (int)(p - registerFlagLetters);
  if(idx <= REGISTER_K - FIRST_LETTERED_REGISTER) {
    return (int16_t)(FIRST_LETTERED_REGISTER + idx);
  }
  if(idx <= REGISTER_S - FIRST_STAT_REGISTER + 12) {
    return (int16_t)(FIRST_STAT_REGISTER + (idx - 12));
  }
  return (int16_t)(FIRST_SPARE_REGISTER + (idx - 18));
}

/**
 * Parse a register argument.
 */
int dslParseRegisterArg(Jim_Interp *interp, int16_t op, const char *arg, uint16_t *outParam) {
  char internalName[64];

  if(dslUnsupportedArg(interp, arg, "register")) {
    return JIM_ERR;
  }

  if(arg[0] != '\0' && arg[strspn(arg, "0123456789")] == '\0') {
    long n = strtol(arg, NULL, 10);
    if(n < 0 || n > 99) {
      Jim_SetResultFormatted(interp, "register number out of range: '%s'", arg);
      return JIM_ERR;
    }
    calcRegister_t reg = (calcRegister_t)(FIRST_GLOBAL_REGISTER + n);
    if(!regInRange(reg)) {
      Jim_SetResultFormatted(interp, "invalid register: '%s'", arg);
      return JIM_ERR;
    }
    *outParam = (uint16_t)reg;
    return JIM_OK;
  }

  // A solver/integrator variable operand names a variable, never a lettered stack register, so a single-letter name like x must resolve as the named
  // variable below, not as register X. SOLVE and PLT f carry param TM_SOLVE; the two integrate items take the integration variable but carry TM_REGISTER,
  // so list them by index. STO/RCL-style operands keep the bare letter as a stack register.
  const bool_t solverVariableOperand = (op >= 0 && op < LAST_ITEM)
                                       && (indexOfItems[op].param == TM_SOLVE || op == ITM_INTEGRAL || op == ITM_INTEGRAL_YX);

  if(!solverVariableOperand && arg[1] == '\0' && isalpha((unsigned char)arg[0])) {
    calcRegister_t reg = dslRegisterFromLetter(arg[0]);
    if(reg == INVALID_VARIABLE || !regInRange(reg)) {
      Jim_SetResultFormatted(interp, "invalid register letter: '%s'", arg);
      return JIM_ERR;
    }
    *outParam = (uint16_t)reg;
    return JIM_OK;
  }

  if(strlen(arg) >= sizeof(internalName)/2) {
    Jim_SetResultFormatted(interp, "register name too long: '%s'", arg);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)arg, internalName);
  calcRegister_t reg;
  if(isFunctionAllowingNewVariable((uint16_t)op)) {
    reg = findOrAllocateNamedVariable(internalName);
  }
  else {
    reg = findNamedVariable(internalName);
    if(reg == INVALID_VARIABLE) {
      Jim_SetResultFormatted(interp, "undefined variable: '%s'", arg);
      return JIM_ERR;
    }
  }
  if(reg == INVALID_VARIABLE) {
    Jim_SetResultFormatted(interp, "could not allocate variable: '%s'", arg);
    return JIM_ERR;
  }
  *outParam = (uint16_t)reg;
  return JIM_OK;
}

/**
 * Parse a label argument.
 */
static int dslParseLabelArg(Jim_Interp *interp, const char *arg, uint16_t *outParam) {
  char internalName[64];

  if(arg[0] != '\0' && arg[strspn(arg, "0123456789")] == '\0') {
    long n = strtol(arg, NULL, 10);
    if(n < 0 || n > 99) {
      Jim_SetResultFormatted(interp, "label number out of range: '%s'", arg);
      return JIM_ERR;
    }
    *outParam = (uint16_t)n;
    return JIM_OK;
  }

  if(arg[1] == '\0') {
    char c = arg[0];
    // A single letter A-L / a-l names a local label, but a global label with that exact name would otherwise be unreachable, so prefer an
    // existing global label (resolved below) and map to the local-label number only when no such global label exists.
    utf8ToString((const uint8_t *)arg, internalName);
    if(findNamedLabel(internalName, STRING_LABEL_VARIABLE) == INVALID_VARIABLE) {
      if(c >= 'A' && c <= 'L') {
        *outParam = (uint16_t)(100 + (c - 'A'));
        return JIM_OK;
      }
      if(c >= 'a' && c <= 'l') {
        *outParam = (uint16_t)(FIRST_LC_LOCAL_LABEL + (c - 'a'));
        return JIM_OK;
      }
    }
  }

  if(strlen(arg) >= sizeof(internalName)/2) {
    Jim_SetResultFormatted(interp, "label name too long: '%s'", arg);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)arg, internalName);
  calcRegister_t label = findNamedLabel(internalName, STRING_LABEL_VARIABLE);
  if(label == INVALID_VARIABLE) {
    Jim_SetResultFormatted(interp, "label not found: '%s'", arg);
    return JIM_ERR;
  }
  *outParam = (uint16_t)label;
  return JIM_OK;
}

/**
 * Parse a flag argument.
 */
int dslParseFlagArg(Jim_Interp *interp, const char *arg, uint16_t *outParam) {
  char internalName[64];

  if(dslUnsupportedArg(interp, arg, "flag")) {
    return JIM_ERR;
  }

  if(arg[0] != '\0' && arg[strspn(arg, "0123456789")] == '\0') {
    long n = strtol(arg, NULL, 10);
    if(n < 0 || n > LAST_GLOBAL_FLAG) {
      Jim_SetResultFormatted(interp, "flag number out of range: '%s'", arg);
      return JIM_ERR;
    }
    *outParam = (uint16_t)n;
    return JIM_OK;
  }

  if(arg[1] == '\0' && isalpha((unsigned char)arg[0])) {
    const char *p = strchr(registerFlagLetters, toupper((unsigned char)arg[0]));
    if(!p) {
      Jim_SetResultFormatted(interp, "invalid flag letter: '%s'", arg);
      return JIM_ERR;
    }
    int idx = (int)(p - registerFlagLetters);
    if(idx <= FLAG_K - FLAG_X) {
      *outParam = (uint16_t)(FLAG_X + idx);
    }
    else {
      *outParam = (uint16_t)(FLAG_M + (idx - 12));
    }
    return JIM_OK;
  }

  if(strlen(arg) >= sizeof(internalName)/2) {
    Jim_SetResultFormatted(interp, "flag name too long: '%s'", arg);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)arg, internalName);
  for(int i = 0; i < LAST_ITEM; ++i) {
    if((indexOfItems[i].status & CAT_STATUS) == CAT_SYFL && compareString(internalName, indexOfItems[i].itemCatalogName, CMP_NAME) == 0) {
      *outParam = indexOfItems[i].param;
      return JIM_OK;
    }
  }
  Jim_SetResultFormatted(interp, "system flag not found: '%s'", arg);
  return JIM_ERR;
}

/**
 * Parse a numeric argument.
 */
static int dslParseNumericArg(Jim_Interp *interp, int16_t index, const char *arg, uint16_t *outParam) {
  item_t item = indexOfItems[index];
  int16_t minVal = item.tamMinMax >> TAM_MAX_BITS;
  int16_t maxVal = item.tamMinMax & TAM_MAX_MASK;

  if(index == ITM_PNORM) {
    if(strcasecmp(arg, "NNZ") == 0) {
      *outParam = pNorm_0_NNZ;
      return JIM_OK;
    }
    if(strcasecmp(arg, "CNORM") == 0) {
      *outParam = pNorm_1_CNORM;
      return JIM_OK;
    }
    if(strcasecmp(arg, "ENORM") == 0) {
      *outParam = pNorm_2_ENORM;
      return JIM_OK;
    }
    if(strcasecmp(arg, "RNORM") == 0 || strcasecmp(arg, "inf") == 0 || strcasecmp(arg, "INFINITY") == 0) {
      *outParam = pNorm_inf_RNORM;
      return JIM_OK;
    }
  }

  if(arg[0] == '\0' || arg[strspn(arg, "0123456789")] != '\0') {
    Jim_SetResultFormatted(interp, "expected numeric argument, got '%s'", arg);
    return JIM_ERR;
  }
  long n = strtol(arg, NULL, 10);
  if(((item.status & PTP_STATUS) == PTP_NUMBER_8_16) && n >= 250 && n <= 499) {
    *outParam = (uint16_t)n;
    return JIM_OK;
  }
  if(n < minVal || n > maxVal) {
    Jim_SetResultFormatted(interp, "value out of range [%d,%d]: '%s'", minVal, maxVal, arg);
    return JIM_ERR;
  }
  *outParam = (uint16_t)n;
  return JIM_OK;
}

/**
 * Parse a menu argument.
 */
static int dslParseMenuArg(Jim_Interp *interp, const char *arg, uint16_t *outParam) {
  char internalName[64];

  if(strlen(arg) >= sizeof(internalName)/2) {
    Jim_SetResultFormatted(interp, "menu name too long: '%s'", arg);
    return JIM_ERR;
  }
  utf8ToString((const uint8_t *)arg, internalName);
  int16_t menu = findMenu(internalName);
  if(menu == INVALID_MENU) {
    Jim_SetResultFormatted(interp, "menu not found: '%s'", arg);
    return JIM_ERR;
  }
  *outParam = (uint16_t)menu;
  return JIM_OK;
}

/**
 * Generic parameter parser for catalog functions.  Dispatches calls
 * to the above type-specific parsers.
 */
int dslParseParam(Jim_Interp *interp, int16_t index, const char *arg, uint16_t *outParam) {
  uint16_t paramMode = (indexOfItems[index].status & PTP_STATUS) >> 9;

  switch(paramMode) {
      case PARAM_REGISTER:
        return dslParseRegisterArg(interp, index, arg, outParam);
      case PARAM_LABEL:
      case PARAM_DECLARE_LABEL:
        return dslParseLabelArg(interp, arg, outParam);
      case PARAM_FLAG:
        return dslParseFlagArg(interp, arg, outParam);
      case PARAM_COMPARE:
        if(strcmp(arg, "0") == 0) {
          reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
          real34SetZero(REGISTER_REAL34_DATA(TEMP_REGISTER_1));
          *outParam = TEMP_REGISTER_1;
          return JIM_OK;
        }
        if(strcmp(arg, "1") == 0) {
          reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
          real34SetOne(REGISTER_REAL34_DATA(TEMP_REGISTER_1));
          *outParam = TEMP_REGISTER_1;
          return JIM_OK;
        }
        return dslParseRegisterArg(interp, index, arg, outParam);
      case PARAM_NUMBER_8:
      case PARAM_NUMBER_16:
      case PARAM_NUMBER_8_16:
      case PARAM_SKIP_BACK:
        return dslParseNumericArg(interp, index, arg, outParam);
      case PARAM_SHUFFLE:
        return dslParseNumericArg(interp, index, arg, outParam);
      case PARAM_MENU:
        return dslParseMenuArg(interp, arg, outParam);
      default:
        Jim_SetResultFormatted(interp, "parameter type %u not supported in scripts", paramMode);
        return JIM_ERR;
  }
}

/**
 * Convert register contents to Tcl string representation.
 * Handles: Real34, Complex34, String, ShortInteger, LongInteger
 */
int convertRegisterToString(calcRegister_t regist, char *buffer, size_t bufferSize) {
  if(bufferSize < 256) {
    return JIM_ERR;
  }

  switch(getRegisterDataType(regist)) {
    case dtReal34: {
        real34ToString(REGISTER_REAL34_DATA(regist), buffer);
        angularMode_t am = getRegisterAngularMode(regist);
        if(am != amNone) {
        size_t len = strlen(buffer);
        strncat(buffer, " ", bufferSize - len - 1);
        strncat(buffer, getAngularModeName(am), bufferSize - len - 2);
        }
        break;
    }
    case dtComplex34: {
        char realStr[512], imagStr[512];
        real34ToString(REGISTER_REAL34_DATA(regist), realStr);
        real34ToString(REGISTER_IMAG34_DATA(regist), imagStr);

        if(real34IsNegative(REGISTER_IMAG34_DATA(regist))) {
        snprintf(buffer, bufferSize, "%s - ix%s", realStr, imagStr + 1);
        }
        else {
        snprintf(buffer, bufferSize, "%s + ix%s", realStr, imagStr);
        }
        break;
    }
    case dtString: {
        stringToUtf8(REGISTER_STRING_DATA(regist), (uint8_t *)buffer);
        break;
    }
    case dtShortInteger: {
        uint64_t value = *(REGISTER_SHORT_INTEGER_DATA(regist));
        snprintf(buffer, bufferSize, "%08x-%08x (base %u)", (unsigned int)(value >> 32), (unsigned int)(value & 0xffffffff), getRegisterTag(regist));
        break;
    }
    case dtLongInteger: {
        longInteger_t lgInt;
        convertLongIntegerRegisterToLongInteger(regist, lgInt);
        longIntegerToAllocatedString(lgInt, buffer, bufferSize);
        longIntegerFree(lgInt);
        break;
    }
    case dtDate: {
        real34_t j, y, m, d;
        char sign[] = {0, 0};

        internalDateToJulianDay(REGISTER_REAL34_DATA(regist), &j);
        decomposeJulianDay(&j, &y, &m, &d);

        if(real34IsNegative(&y)) {
        sign[0] = '-';
        }
        real34CopyAbs(&y, &y);

        // Format as YYYY-MM-DD (ISO format)
        snprintf(buffer, bufferSize, "%s%04" PRIu32 "-%02" PRIu32 "-%02" PRIu32, sign, real34ToUInt32(&y), real34ToUInt32(&m), real34ToUInt32(&d));
        break;
    }
    case dtTime: {
      real34_t totalSecs;
      int32_t hour, min, sec;

      // Copy the register value (which includes 0.5 offset)
      real34Copy(REGISTER_REAL34_DATA(regist), &totalSecs);
      real34Subtract(&totalSecs, const34_1on2, &totalSecs);  // Remove 0.5 offset to get actual seconds

      // Convert total seconds to hours for extraction
      real34_t totalHours;
      real34Copy(&totalSecs, &totalHours);
      real34Divide(&totalHours, const34_3600, &totalHours);

      // Extract hours, minutes, seconds from the fractional hours
      real34_t hPart, mPart, sPart;
      real34Copy(&totalHours, &hPart);
      real34ToIntegralValue(&hPart, &hPart, DEC_ROUND_DOWN);  // integer hours

      // Get fractional part for minutes (after extracting hours)
      real34Subtract(&totalHours, &hPart, &mPart);
      real34Multiply(&mPart, const34_60, &mPart);  // convert to minutes
      real34ToIntegralValue(&mPart, &mPart, DEC_ROUND_DOWN);  // integer minutes

      // Get fractional part for seconds (after extracting hours and minutes)
      real34Subtract(&totalHours, &hPart, &sPart);
      real34Multiply(&sPart, const34_60, &sPart);  // convert to minutes first
      real34Subtract(&sPart, &mPart, &sPart);  // subtract integer minutes
      real34Multiply(&sPart, const34_60, &sPart);  // convert remaining fraction to seconds

      // Round to nearest second using DEC_ROUND_HALF_UP
      real34_t sRounded;
      real34Copy(&sPart, &sRounded);
      real34ToIntegralValue(&sRounded, &sRounded, DEC_ROUND_HALF_UP);

      hour = real34ToInt32(&hPart);
      min = real34ToInt32(&mPart);
      sec = real34ToInt32(&sRounded);

      // Handle overflow: if seconds == 60, carry to minutes
      if(sec >= 60) {
          sec -= 60;
          min += 1;
      }
      // Handle minute overflow
      if(min >= 60) {
          min -= 60;
          hour += 1;
      }
      // Handle hour overflow (shouldn't happen with valid times)
      if(hour >= 24) {
          hour -= 24;
      }

      // Display as HH:MM:SS without fractional seconds (C47 convention)
      snprintf(buffer, bufferSize, "%02d:%02d:%02d", hour, min, sec);
      break;
    }
    default: {
      strncpy(buffer, "<unsupported>", bufferSize - 1);
      buffer[bufferSize - 1] = '\0';
      break;
    }
  }
  return JIM_OK;
}

/**
 * Parse a value string and store it in a temporary register.
 * Attempts to determine the appropriate data type by trying each type in order:
 * - First tries real34 (numeric) parsing
 * - If that fails, stores as string using utf8ToString conversion
 */
static bool_t isComplexNumber(const char *str) {
  size_t len = strlen(str);
  if(len < 5) {
    return FALSE;
  }

  const char *ixPos = NULL;
  for(size_t i = 0; i < len - 2; i++) {
    if((str[i] == 'i' || str[i] == 'I') && (str[i+1] == 'x' || str[i+1] == 'X')) {
      ixPos = str + i;
      break;
    }
  }

  if(!ixPos) {
    return FALSE;
  }

  const char *plusPos = NULL;
  const char *minusPos = NULL;

  for(size_t i = 0; i < len - 2; i++) {
    if(str[i] == '+' && (str[i+1] == ' ' || str[i+1] == '\t')) {
      plusPos = str + i;
    }
    else if(str[i] == '-' && (str[i+1] == ' ' || str[i+1] == '\t')) {
      minusPos = str + i;
    }
  }

  return (plusPos && plusPos < ixPos) || (minusPos && minusPos < ixPos);
}

static int parseComplexToTempRegister(Jim_Interp *interp, const char *valueArg) {
  char buffer[1024];
  strncpy(buffer, valueArg, sizeof(buffer) - 1);
  buffer[sizeof(buffer) - 1] = '\0';

  size_t len = strlen(buffer);
  char *plusPos = NULL;
  char *minusPos = NULL;
  char *ixPos = NULL;

  for(size_t i = 0; i < len - 2; i++) {
    if((buffer[i] == 'i' || buffer[i] == 'I') && (buffer[i+1] == 'x' || buffer[i+1] == 'X')) {
      ixPos = buffer + i;
      break;
    }
  }

  if(!ixPos) {
    return JIM_ERR;
  }

  for(size_t i = 0; i < len - 2; i++) {
    if(buffer[i] == '+' && (buffer[i+1] == ' ' || buffer[i+1] == '\t')) {
      plusPos = buffer + i;
    }
    else if(buffer[i] == '-' && (buffer[i+1] == ' ' || buffer[i+1] == '\t')) {
      minusPos = buffer + i;
    }
  }

  char realPart[512], imagPart[512];

  if(plusPos && plusPos < ixPos) {
    *plusPos = '\0';
    strncpy(realPart, buffer, sizeof(realPart) - 1);
    realPart[sizeof(realPart) - 1] = '\0';

    char *startImag = plusPos + 2;
    while(*startImag == ' ' || *startImag == '\t') {
      startImag++;
    }
    strncpy(imagPart, startImag, sizeof(imagPart) - 1);
    imagPart[sizeof(imagPart) - 1] = '\0';

    size_t imagLen = strlen(imagPart);
    if(imagLen > 2 && (imagPart[imagLen-2] == 'i' || imagPart[imagLen-2] == 'I') && (imagPart[imagLen-1] == 'x' || imagPart[imagLen-1] == 'X')) {
      imagPart[imagLen-2] = '\0';
    }
  }
  else if(minusPos && minusPos < ixPos) {
    *minusPos = '\0';
    strncpy(realPart, buffer, sizeof(realPart) - 1);
    realPart[sizeof(realPart) - 1] = '\0';

    char *startImag = minusPos + 2;
    while(*startImag == ' ' || *startImag == '\t') {
      startImag++;
    }
    strncpy(imagPart, startImag, sizeof(imagPart) - 1);
    imagPart[sizeof(imagPart) - 1] = '\0';

    size_t imagLen = strlen(imagPart);
    if(imagLen > 2 && (imagPart[imagLen-2] == 'i' || imagPart[imagLen-2] == 'I') && (imagPart[imagLen-1] == 'x' || imagPart[imagLen-1] == 'X')) {
      imagPart[imagLen-2] = '\0';
    }

    if(strlen(imagPart) > 0 && imagPart[0] != '-') {
      size_t len = strlen(imagPart);
      memmove(imagPart + 1, imagPart, len + 1);
      imagPart[0] = '-';
    }
  }
  else {
    return JIM_ERR;
  }

  reallocateRegister(TEMP_REGISTER_1, dtComplex34, 0, amNone);

  real34_t realVal, imagVal;
  stringToReal34(realPart, &realVal);
  stringToReal34(imagPart, &imagVal);

  if(real34IsNaN(&realVal) || real34IsNaN(&imagVal)) {
    return JIM_ERR;
  }

  real34Copy(&realVal, REGISTER_REAL34_DATA(TEMP_REGISTER_1));
  real34Copy(&imagVal, REGISTER_IMAG34_DATA(TEMP_REGISTER_1));

   return JIM_OK;
}

/**
 * Check if a string represents a short integer in the format NNN#bb (base 2-16).
 */
static bool_t isShortInteger(const char *str) {
size_t len = strlen(str);

// Must have at least one digit, '#', and 1-2 digit base (e.g., "42#10" or "FF#16")
  if(len < 4) {
    return FALSE;
  }

  // Find the '#' separator
 const char *hashPos = strchr(str, '#');
  if(!hashPos || hashPos == str) {
    return FALSE;
  }

  // Base must be after '#'
  const char *baseStr = hashPos + 1;
  size_t baseLen = strlen(baseStr);

  // Base should be 1-2 digits (2-16)
  if(baseLen < 1 || baseLen > 2) {
    return FALSE;
  }

  // Validate base is numeric and in range 2-16
  for(size_t i = 0; i < baseLen; i++) {
    if(!isdigit((unsigned char)baseStr[i])) {
      return FALSE;
    }
  }
  int base = atoi(baseStr);
  if(base < 2 || base > 16) {
    return FALSE;
  }

  // Validate the integer part (before '#')
  const char *intPart = str;
  size_t intLen = hashPos - intPart;

  // Check for optional negative sign
  if(intPart[0] == '-') {
    intPart++;
    intLen--;
  }

  // Must have at least one digit after '-' (if present)
  if(intLen == 0) {
    return FALSE;
  }

  // Validate digits are valid for the base
  for(size_t i = 0; i < intLen; i++) {
    char c = intPart[i];
    int digitVal;

    if(c >= '0' && c <= '9') {
      digitVal = c - '0';
    }
    else if(c >= 'A' && c <= 'F') {
      digitVal = 10 + (c - 'A');
    }
    else if(c >= 'a' && c <= 'f') {
      digitVal = 10 + (c - 'a');
    }
    else {
      return FALSE;
    }

    if(digitVal >= base) {
      return FALSE;
    }
  }

  return TRUE;
}

static int parseShortIntegerToTempRegister(Jim_Interp *interp, const char *valueArg) {
  (void)interp;  // Avoid unused parameter warning

  char buffer[64];
  strncpy(buffer, valueArg, sizeof(buffer) - 1);
  buffer[sizeof(buffer) - 1] = '\0';

  // Find the '#' separator
  char *hashPos = strchr(buffer, '#');
  if(!hashPos || hashPos == buffer) {
    return JIM_ERR;
  }

  // Extract base
  int base = atoi(hashPos + 1);
  if(base < 2 || base > 16) {
    return JIM_ERR;
  }

  // Null-terminate the integer part and get it
  *hashPos = '\0';
  const char *intPart = buffer;

  // Parse using strtoull for the specified base
  char *endPtr;
  uint64_t intVal = strtoull(intPart, &endPtr, base);

  // Check if parsing was successful (not empty and fully consumed)
  if(endPtr == intPart || *endPtr != '\0') {
    return JIM_ERR;
  }

  // Convert to short integer register
  reallocateRegister(TEMP_REGISTER_1, dtShortInteger, 0, amNone);
  convertUInt64ToShortIntegerRegister(false, intVal, base, TEMP_REGISTER_1);

  return JIM_OK;
}

static bool_t isLongInteger(const char *str) {
  size_t len = strlen(str);

  // Long integers are just digit strings (optionally with negative sign)
  if(len < 1) {
    return FALSE;
  }

  const char *intPart = str;

  // Check for optional negative sign
  if(intPart[0] == '-') {
    intPart++;
  }

  // Must have at least one digit after '-' (if present)
  if(*intPart == '\0') {
    return FALSE;
  }

  // Validate all remaining characters are digits
  size_t checkLen = len - (intPart - str);
  for(size_t i = 0; i < checkLen; i++) {
    if(!isdigit((unsigned char)intPart[i])) {
      return FALSE;
    }
  }

  return TRUE;
}

static int parseLongIntegerToTempRegister(Jim_Interp *interp, const char *valueArg) {
  (void)interp;  // Avoid unused parameter warning

  longInteger_t lgInt;
  longIntegerInit(lgInt);

  // Parse using decNumber's string conversion (decimal base)
  stringToLongInteger(valueArg, 10, lgInt);

  // Convert to long integer register
  reallocateRegister(TEMP_REGISTER_1, dtLongInteger, 0, amNone);
  convertLongIntegerToLongIntegerRegister(lgInt, TEMP_REGISTER_1);

  longIntegerFree(lgInt);

  return JIM_OK;
}

static bool_t isDateString(const char *str) {
  size_t len = strlen(str);
  if(len < 10) {
      return FALSE;
  }

  // Check for YYYY-MM-DD format (ISO-like)
  // Pattern: 4 digits, dash, 2 digits, dash, 2 digits
  if(str[4] == '-' && str[7] == '-') {
    for(int i = 0; i < 10; i++) {
      if(i == 4 || i == 7) {
        continue;
      }
      if(!isdigit((unsigned char)str[i])) {
        return FALSE;
      }
    }
    return TRUE;
  }

  return FALSE;
}

static bool_t isTimeString(const char *str) {
  size_t len = strlen(str);
  if(len < 8) {
    return FALSE;
  }

  // Check for HH:MM:SS format (ISO-like)
  // Pattern: 2 digits, colon, 2 digits, colon, 2 digits (optionally .fraction)
  if(str[2] == ':' && str[5] == ':') {
    for(int i = 0; i < 8; i++) {
      if(i == 2 || i == 5) {
        continue;
      }
      if(!isdigit((unsigned char)str[i])) {
          return FALSE;
      }
    }
    // Check for fractional seconds
    if(len > 8) {
      if(str[8] != '.') {
        return FALSE;
      }
      for(size_t i = 9; i < len; i++) {
        if(!isdigit((unsigned char)str[i])) {
          return FALSE;
        }
      }
    }
    return TRUE;
  }

  return FALSE;
}

static int parseDateToTempRegister(Jim_Interp *interp, const char *valueArg) {
  char buffer[32];
  strncpy(buffer, valueArg, sizeof(buffer) - 1);
  buffer[sizeof(buffer) - 1] = '\0';

  real34_t y, m, d;

  // Parse YYYY-MM-DD format
  if(buffer[4] == '-' && buffer[7] == '-') {
    buffer[4] = '\0';
    stringToReal34(buffer, &y);

    char *monthStr = buffer + 5;
    buffer[7] = '\0';
    stringToReal34(monthStr, &m);

    stringToReal34(buffer + 8, &d);
  }
  else {
    return JIM_ERR;
  }

  // Compose Julian day
  real34_t jd;
  composeJulianDay(&y, &m, &d, &jd);

  // Convert to internal date representation (add 0.5 for noon offset)
  reallocateRegister(TEMP_REGISTER_1, dtDate, 0, amNone);
  julianDayToInternalDate(&jd, REGISTER_REAL34_DATA(TEMP_REGISTER_1));

  return JIM_OK;
}

static int parseTimeToTempRegister(Jim_Interp *interp, const char *valueArg) {
  char buffer[32];
  strncpy(buffer, valueArg, sizeof(buffer) - 1);
  buffer[sizeof(buffer) - 1] = '\0';

  real34_t h, m, s;
  int32_t hour, min, sec;
  double fracSec = 0.0;

  // Parse HH:MM:SS format
  if(buffer[2] == ':' && buffer[5] == ':') {
    char hourStr[8], minStr[8], secStr[16];

    strncpy(hourStr, buffer, 2);
    hourStr[2] = '\0';
    stringToReal34(hourStr, &h);

    strncpy(minStr, buffer + 3, 2);
    minStr[2] = '\0';
    stringToReal34(minStr, &m);

    // Seconds can have fractional part
    strcpy(secStr, buffer + 6);
    stringToReal34(secStr, &s);
  }
  else {
    return JIM_ERR;
  }

  // Handle fractional seconds if present
  size_t len = strlen(buffer);
  if(len > 8 && buffer[8] == '.') {
    char fracBuffer[16];
    strncpy(fracBuffer, buffer + 9, sizeof(fracBuffer) - 1);
    fracBuffer[sizeof(fracBuffer) - 1] = '\0';

    // Parse fractional seconds directly as double
    if(strlen(fracBuffer) > 0) {
      char *endPtr;
      double fracVal = strtod(fracBuffer, &endPtr);

      // Scale by number of digits to get proper fraction (e.g., "5" -> 0.5)
      int fracDigits = strlen(fracBuffer);
      for(int i = 0; i < fracDigits; i++) {
        fracVal /= 10.0;
      }
      fracSec = fracVal;
    }
  }

  hour = real34ToInt32(&h);
  min = real34ToInt32(&m);
  sec = real34ToInt32(&s);

  if(hour < 0 || hour > 23 || min < 0 || min > 59 || sec < 0 || sec > 59) {
    return JIM_ERR;
  }

  // Convert to seconds (internal time representation)
  double totalSeconds = (double)hour * 3600.0 + (double)min * 60.0 + (double)sec + fracSec;

  // Convert integer part to real34
  real34_t total;
  uInt32ToReal34((uint32_t)totalSeconds, &total);

  // Add fractional seconds if present
  double intPart;
  double frac = modf(totalSeconds, &intPart);
  if(frac != 0.0) {
    real34_t fracVal;
    // Parse the fractional part as a string to avoid precision issues
    char fracStr[32];
    snprintf(fracStr, sizeof(fracStr), "%.15g", frac);
    stringToReal34(fracStr, &fracVal);
    real34Add(&total, &fracVal, &total);
  }

  real34Add(&total, const34_1on2, &total);  // Add 0.5 offset

  reallocateRegister(TEMP_REGISTER_1, dtTime, 0, amNone);
  real34Copy(&total, REGISTER_REAL34_DATA(TEMP_REGISTER_1));

  return JIM_OK;
}

int parseValueToTempRegister(Jim_Interp *interp, const char *valueArg) {
  // Try parsing in documented order: date, time, short int, long int, complex, real, string

  // 1. Try date (YYYY-MM-DD format)
  if(isDateString(valueArg)) {
    if(parseDateToTempRegister(interp, valueArg) == JIM_OK) {
      return JIM_OK;
    }
  }

  // 2. Try time (HH:MM:SS format)
  if(isTimeString(valueArg)) {
    if(parseTimeToTempRegister(interp, valueArg) == JIM_OK) {
      return JIM_OK;
    }
  }

  // 3. Try short integer (NNN#bb format where NNN is the integer and bb is base 2-16)
  if(isShortInteger(valueArg)) {
    if(parseShortIntegerToTempRegister(interp, valueArg) == JIM_OK) {
      return JIM_OK;
    }
  }

  // 3. Try long integer - plain digit strings without base affix (e.g., "12345")
  if(isLongInteger(valueArg)) {
    int result = parseLongIntegerToTempRegister(interp, valueArg);
    if(result == JIM_OK) {
      return JIM_OK;
    }
  }

  // 4. Try complex number (a + ix b format)
  if(isComplexNumber(valueArg)) {
    if(parseComplexToTempRegister(interp, valueArg) == JIM_OK) {
      return JIM_OK;
    }
  }

  // 6. Try real number
  reallocateRegister(TEMP_REGISTER_1, dtReal34, 0, amNone);
  stringToReal34(valueArg, REGISTER_REAL34_DATA(TEMP_REGISTER_1));

  if(!real34IsNaN(REGISTER_REAL34_DATA(TEMP_REGISTER_1))) {
    return JIM_OK;
  }

  // 7. Fall back to string
  int stringLen = stringByteLength(valueArg) + 1;
  char *internalStr = malloc(stringLen);
  utf8ToString((const uint8_t *)valueArg, internalStr);

  reallocateRegister(TEMP_REGISTER_1, dtString, TO_BLOCKS(stringLen), amNone);
  xcopy(REGISTER_STRING_DATA(TEMP_REGISTER_1), internalStr, stringLen);

  free(internalStr);

  return JIM_OK;
}

#endif
