// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "c47.h"

void z47_registers_retained_copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister);
void oracle_setRegisterDataType(calcRegister_t regist, uint16_t dataType, const uint32_t tag);
void oracle_setRegisterDataPointer(calcRegister_t regist, const void *memPtr);
void *oracle_getRegisterDataPointer(calcRegister_t regist);
void oracle_allocateNamedVariable(const char *variableName, uint32_t dataType, uint16_t fullDataSizeInBlocks);

const reservedVariableHeader_t allReservedVariables[NUMBER_OF_RESERVED_VARIABLES] = {
  [26] = {
    .header = {
      .pointerToRegisterData = C47_NULL,
      .dataType = dtLongInteger,
      .tag = LI_POSITIVE,
      .readOnly = 1,
      .notUsed = 0,
    },
    .reservedVariableName = {3, 'A', 'D', 'M', 0, 0, 0, 0},
  },
  [31] = {
    .header = {
      .pointerToRegisterData = 1,
      .dataType = dtReal34,
      .tag = amNone,
      .readOnly = 0,
      .notUsed = 0,
    },
    .reservedVariableName = {3, 'A', 'C', 'C', 0, 0, 0, 0},
  },
  [40] = {
    .header = {
      .pointerToRegisterData = 2,
      .dataType = dtLongInteger,
      .tag = LI_POSITIVE,
      .readOnly = 0,
      .notUsed = 0,
    },
    .reservedVariableName = {6, 'G', 'R', 'A', 'M', 'O', 'D', 0},
  },
};

static inline registerHeader_t *POINTER_TO_LOCAL_REGISTER(const calcRegister_t reg) {
  return (registerHeader_t *)(currentLocalRegisters + reg);
}

enum {
  VALIDATE_NAME_MAX_GLYPHS = 7,
  VALIDATE_NAME_GLYPH_A = 0x41,
  VALIDATE_NAME_GLYPH_Z = 0x5a,
  VALIDATE_NAME_GLYPH_a = 0x61,
  VALIDATE_NAME_GLYPH_z = 0x7a,
  VALIDATE_NAME_GLYPH_A_GRAVE = 0x00c0,
  VALIDATE_NAME_GLYPH_CROSS = 0x00d7,
  VALIDATE_NAME_GLYPH_DIVIDE = 0x00f7,
  VALIDATE_NAME_GLYPH_z_CARON = 0x017e,
  VALIDATE_NAME_GLYPH_IOTA_DIALYTIKA_TONOS = 0x0390,
  VALIDATE_NAME_GLYPH_SAMPI = 0x03e1,
  VALIDATE_NAME_GLYPH_SUB_ALPHA = 0x2296,
  VALIDATE_NAME_GLYPH_SUB_MU = 0x2298,
  VALIDATE_NAME_GLYPH_SUP_a = 0x2482,
  VALIDATE_NAME_GLYPH_SUB_Z = 0x24e9,
};

static int32_t oracle_validateNameGlyphLength(const char *name) {
  int32_t glyph_length = 0;

  while(*name != 0) {
    name += (((uint8_t)*name & 0x80) != 0) ? 2 : 1;
    glyph_length++;
  }

  return glyph_length;
}

static uint16_t oracle_validateNameGlyphCode(const char *name) {
  uint8_t first = (uint8_t)name[0];

  if((first & 0x80) != 0) {
    return (uint16_t)((((uint16_t)(first & 0x7f)) << 8) | (uint8_t)name[1]);
  }

  return first;
}

bool_t oracle_validateName(const char *name) {
  int32_t glyph_length;
  uint16_t first;

  glyph_length = oracle_validateNameGlyphLength(name);
  if(glyph_length > VALIDATE_NAME_MAX_GLYPHS || glyph_length == 0) {
    return false;
  }

  first = oracle_validateNameGlyphCode(name);
  if(first < VALIDATE_NAME_GLYPH_A) {
    return false;
  }
  if(first > VALIDATE_NAME_GLYPH_Z && first < VALIDATE_NAME_GLYPH_a) {
    return false;
  }
  if(first > VALIDATE_NAME_GLYPH_z && first < VALIDATE_NAME_GLYPH_A_GRAVE) {
    return false;
  }
  if(first == VALIDATE_NAME_GLYPH_CROSS || first == VALIDATE_NAME_GLYPH_DIVIDE) {
    return false;
  }
  if(first > VALIDATE_NAME_GLYPH_z_CARON && first < VALIDATE_NAME_GLYPH_IOTA_DIALYTIKA_TONOS) {
    return false;
  }
  if(first > VALIDATE_NAME_GLYPH_SAMPI && first < VALIDATE_NAME_GLYPH_SUB_ALPHA) {
    return false;
  }
  if(first > VALIDATE_NAME_GLYPH_SUB_MU && first < VALIDATE_NAME_GLYPH_SUP_a) {
    return false;
  }
  if(first > VALIDATE_NAME_GLYPH_SUB_Z) {
    return false;
  }

  for(name += (((uint8_t)*name & 0x80) != 0) ? 2 : 1; *name != 0; name += (((uint8_t)*name & 0x80) != 0) ? 2 : 1) {
    switch(*name) {
      case '+':
      case '-':
      case ':':
      case '/':
      case '^':
      case '(':
      case ')':
      case '=':
      case ';':
      case '|':
      case '!':
      case ' ': {
        return false;
      }
      default: {
        if(oracle_validateNameGlyphCode(name) == VALIDATE_NAME_GLYPH_CROSS) {
          return false;
        }
      }
    }
  }

  return true;
}

bool_t oracle_isUniqueMenuName(const char *name) {
  for(uint32_t i = 0; i < z47_register_metadata_builtin_menu_item_count(); ++i) {
    if(z47_register_metadata_builtin_menu_item_is_menu(i) && z47_register_metadata_compare_menu_names(name, z47_register_metadata_builtin_menu_item_name(i)) == 0) {
      return false;
    }
  }

  for(uint32_t i = 0; i < z47_register_metadata_user_menu_count(); ++i) {
    if(z47_register_metadata_compare_menu_names(name, z47_register_metadata_user_menu_name(i)) == 0) {
      return false;
    }
  }

  return true;
}

static calcRegister_t oracle_findReservedVariableName(const char *variableName, uint8_t glyph_length) {
  for(calcRegister_t reg = 0; reg < NUMBER_OF_RESERVED_VARIABLES; ++reg) {
    if(allReservedVariables[reg].reservedVariableName[0] != glyph_length) {
      continue;
    }

    if(compareString(variableName, (const char *)(allReservedVariables[reg].reservedVariableName + 1), CMP_NAME) == 0) {
      return (calcRegister_t)(FIRST_RESERVED_VARIABLE + reg);
    }
  }

  return INVALID_VARIABLE;
}

void oracle_allocateNamedVariable(const char *variableName, uint32_t dataType, uint16_t fullDataSizeInBlocks) {
  int32_t glyph_length;

  (void)dataType;
  (void)fullDataSizeInBlocks;

  glyph_length = oracle_validateNameGlyphLength(variableName);
  if(glyph_length < 1 || glyph_length > VALIDATE_NAME_MAX_GLYPHS) {
    return;
  }

  if(oracle_findReservedVariableName(variableName, (uint8_t)glyph_length) != INVALID_VARIABLE) {
    displayCalcErrorMessage(ERROR_INVALID_NAME, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    return;
  }

  if(!oracle_validateName(variableName)) {
    displayCalcErrorMessage(ERROR_INVALID_NAME, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    return;
  }

  if(numberOfNamedVariables != 0) {
    if(numberOfNamedVariables == (LAST_NAMED_VARIABLE - FIRST_NAMED_VARIABLE + 1)) {
      displayCalcErrorMessage(ERROR_TOO_MANY_VARIABLES, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      return;
    }

    if(!isMemoryBlockAvailable(TO_BLOCKS(sizeof(namedVariableHeader_t) * (numberOfNamedVariables + 1)), 1, 0.0f)) {
      displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      return;
    }

    numberOfNamedVariables++;
    memset(allNamedVariables[numberOfNamedVariables - 1].variableName, 0, sizeof(allNamedVariables[numberOfNamedVariables - 1].variableName));
    allNamedVariables[numberOfNamedVariables - 1].variableName[0] = (uint8_t)strlen(variableName);
    memcpy(allNamedVariables[numberOfNamedVariables - 1].variableName + 1, variableName, (size_t)allNamedVariables[numberOfNamedVariables - 1].variableName[0]);
    oracle_setRegisterDataType((calcRegister_t)(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1), (uint16_t)dataType, amNone);
    oracle_setRegisterDataPointer((calcRegister_t)(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1), allocC47Blocks(fullDataSizeInBlocks));
    return;
  }

  if(!isMemoryBlockAvailable(TO_BLOCKS(sizeof(namedVariableHeader_t)), 1, 0.0f)) {
    displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    return;
  }

  memset(allNamedVariables[0].variableName, 0, sizeof(allNamedVariables[0].variableName));
  allNamedVariables[0].variableName[0] = (uint8_t)strlen(variableName);
  memcpy(allNamedVariables[0].variableName + 1, variableName, (size_t)allNamedVariables[0].variableName[0]);
  numberOfNamedVariables = 1;
  oracle_setRegisterDataType(FIRST_NAMED_VARIABLE, (uint16_t)dataType, amNone);
  oracle_setRegisterDataPointer(FIRST_NAMED_VARIABLE, allocC47Blocks(fullDataSizeInBlocks));
}

void oracle_fnDeleteVariable(uint16_t regist) {
  if(regist >= FIRST_NAMED_VARIABLE && regist < (FIRST_NAMED_VARIABLE + numberOfNamedVariables)) {
    uint16_t index = (uint16_t)(regist - FIRST_NAMED_VARIABLE);

    freeRegisterData((calcRegister_t)regist);
    for(uint16_t i = index; i < (numberOfNamedVariables - 1); ++i) {
      allNamedVariables[i] = allNamedVariables[i + 1];
    }
    allNamedVariables[numberOfNamedVariables - 1].header.descriptor = 0;
    memset(allNamedVariables[numberOfNamedVariables - 1].variableName, 0, sizeof(allNamedVariables[numberOfNamedVariables - 1].variableName));
    numberOfNamedVariables -= 1;
    return;
  }

  if(regist >= FIRST_NAMED_VARIABLE && regist < LAST_NAMED_VARIABLE) {
    displayCalcErrorMessage(ERROR_UNDEF_SOURCE_VAR, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
    return;
  }

  displayCalcErrorMessage(ERROR_CANNOT_DELETE_PREDEF_ITEM, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
}

static void oracle_initializeSimEqMatrix(const char *variable_name, calcRegister_t reg) {
  matrixHeader_t *matrix_header;

  oracle_allocateNamedVariable(variable_name, dtReal34Matrix, (uint16_t)(REAL34_SIZE_IN_BLOCKS + TO_BLOCKS(sizeof(matrixHeader_t))));
  if(lastErrorCode != ERROR_NONE) {
    return;
  }

  matrix_header = (matrixHeader_t *)oracle_getRegisterDataPointer(reg);
  if(matrix_header == NULL) {
    return;
  }

  matrix_header->matrixRows = 1;
  matrix_header->matrixColumns = 1;
  real34SetZero((real34_t *)((uint8_t *)matrix_header + sizeof(matrixHeader_t)));
}

static void oracle_initSimEqMatABX(void) {
  oracle_initializeSimEqMatrix("Mat_A", FIRST_NAMED_VARIABLE);
  if(lastErrorCode != ERROR_NONE) {
    return;
  }

  oracle_initializeSimEqMatrix("Mat_B", FIRST_NAMED_VARIABLE + 1);
  if(lastErrorCode != ERROR_NONE) {
    return;
  }

  oracle_initializeSimEqMatrix("Mat_X", FIRST_NAMED_VARIABLE + 2);
}

void oracle_fnDeleteAllVariables(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED && programRunStop != PGM_RUNNING) {
    z47_register_metadata_request_delete_all_variables_confirmation();
    return;
  }

  for(uint16_t var = numberOfNamedVariables; var > 0; var--) {
    oracle_fnDeleteVariable(FIRST_NAMED_VARIABLE + var - 1);
  }

  oracle_initSimEqMatABX();
  temporaryInformation = programRunStop != PGM_RUNNING ? TI_DEL_ALL_VARIABLES : TI_NO_INFO;
}

void oracle_fnClearAllVariables(uint16_t confirmation) {
  if(confirmation == NOT_CONFIRMED && programRunStop != PGM_RUNNING) {
    z47_register_metadata_request_clear_all_variables_confirmation();
    return;
  }

  displayBugScreen("oracle_fnClearAllVariables called with an unsupported confirmed case");
}

calcRegister_t oracle_findNamedVariable(const char *variableName) {
  uint8_t len = (uint8_t)oracle_validateNameGlyphLength(variableName);

  if(len < 1 || len > 7) {
    return INVALID_VARIABLE;
  }

  {
    calcRegister_t regist = oracle_findReservedVariableName(variableName, len);
    if(regist != INVALID_VARIABLE) {
      return regist;
    }
  }

  for(uint16_t i = 0; i < numberOfNamedVariables && i < MAX_FAKE_NAMED_VARIABLES; ++i) {
    if(compareString((const char *)(allNamedVariables[i].variableName + 1), variableName, CMP_NAME) == 0) {
      return (calcRegister_t)(FIRST_NAMED_VARIABLE + i);
    }
  }

  return INVALID_VARIABLE;
}

calcRegister_t oracle_findOrAllocateNamedVariable(const char *variableName) {
  uint8_t len = (uint8_t)oracle_validateNameGlyphLength(variableName);

  if(len < 1 || len > 7) {
    return INVALID_VARIABLE;
  }

  {
    calcRegister_t regist = oracle_findNamedVariable(variableName);
    if(regist != INVALID_VARIABLE) {
      return regist;
    }
  }

  if(numberOfNamedVariables > (LAST_NAMED_VARIABLE - FIRST_NAMED_VARIABLE)) {
    return INVALID_VARIABLE;
  }

  oracle_allocateNamedVariable(variableName, dtReal34, REAL34_SIZE_IN_BLOCKS);
  if(lastErrorCode != ERROR_NONE) {
    return INVALID_VARIABLE;
  }

  {
    calcRegister_t regist = (calcRegister_t)(FIRST_NAMED_VARIABLE + numberOfNamedVariables - 1);
    real34SetZero(REGISTER_REAL34_DATA(regist));
    return regist;
  }
}

uint32_t oracle_getRegisterDataType(calcRegister_t regist) {
  if(regist <= LAST_GLOBAL_REGISTER) {
    return globalRegister[regist].dataType;
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      if(regist < numberOfNamedVariables) {
        return allNamedVariables[regist].header.dataType;
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "getRegisterDataType");
      displayBugScreen(errorMessage);
    }
  }

  else if(regist <= LAST_RESERVED_VARIABLE) {
    regist -= FIRST_RESERVED_VARIABLE;
    if(regist < NUMBER_OF_LETTERED_VARIABLES) {
      return globalRegister[regist + REGISTER_X].dataType;
    }
    return allReservedVariables[regist].header.dataType;
  }

  else if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      regist -= FIRST_LOCAL_REGISTER;
      if(regist < currentNumberOfLocalRegisters) {
        return POINTER_TO_LOCAL_REGISTER(regist)->dataType;
      }
    }
  }

  else {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "getRegisterDataType", regist, LAST_RESERVED_VARIABLE + 1);
    displayBugScreen(errorMessage);
  }

  return 31u;
}

void *oracle_getRegisterDataPointer(calcRegister_t regist) {
  if(regist <= LAST_GLOBAL_REGISTER) {
    return TO_PCMEMPTR(globalRegister[regist].pointerToRegisterData);
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      if(regist < numberOfNamedVariables) {
        return TO_PCMEMPTR(allNamedVariables[regist].header.pointerToRegisterData);
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "getRegisterDataPointer");
      displayBugScreen(errorMessage);
    }
  }

  else if(regist <= LAST_RESERVED_VARIABLE) {
    regist -= FIRST_RESERVED_VARIABLE;
    return TO_PCMEMPTR(allReservedVariables[regist].header.pointerToRegisterData);
  }

  else if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      regist -= FIRST_LOCAL_REGISTER;
      if(regist < currentNumberOfLocalRegisters) {
        return TO_PCMEMPTR(POINTER_TO_LOCAL_REGISTER(regist)->pointerToRegisterData);
      }
    }
  }

  else {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "getRegisterDataPointer", regist, LAST_RESERVED_VARIABLE + 1);
    displayBugScreen(errorMessage);
  }

  return NULL;
}

uint32_t oracle_getRegisterTag(calcRegister_t regist) {
  if(regist <= LAST_GLOBAL_REGISTER) {
    return globalRegister[regist].tag;
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      if(regist < numberOfNamedVariables) {
        return allNamedVariables[regist].header.tag;
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "getRegisterTag");
      displayBugScreen(errorMessage);
    }
  }

  else if(regist <= LAST_RESERVED_VARIABLE) {
    regist -= FIRST_RESERVED_VARIABLE;
    return allReservedVariables[regist].header.tag;
  }

  else if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      regist -= FIRST_LOCAL_REGISTER;
      if(regist < currentNumberOfLocalRegisters) {
        return POINTER_TO_LOCAL_REGISTER(regist)->tag;
      }
    }
  }

  else {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "getRegisterTag", regist, LAST_RESERVED_VARIABLE + 1);
    displayBugScreen(errorMessage);
  }

  return 0;
}

void oracle_setRegisterDataType(calcRegister_t regist, uint16_t dataType, const uint32_t tag) {
  if(regist <= LAST_GLOBAL_REGISTER) {
    globalRegister[regist].dataType = dataType;
    globalRegister[regist].tag = tag;
    return;
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      if(regist < numberOfNamedVariables) {
        allNamedVariables[regist].header.dataType = dataType;
        allNamedVariables[regist].header.tag = tag;
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "setRegisterDataType");
      displayBugScreen(errorMessage);
    }
    return;
  }

  if(regist <= LAST_RESERVED_VARIABLE) {
    regist -= FIRST_RESERVED_VARIABLE;
    if(allReservedVariables[regist].header.pointerToRegisterData != C47_NULL && allReservedVariables[regist].header.readOnly == 0) {
      allNamedVariables[regist].header.dataType = dataType;
      allNamedVariables[regist].header.tag = tag;
    }
    return;
  }

  if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      regist -= FIRST_LOCAL_REGISTER;
      if(regist < currentNumberOfLocalRegisters) {
        POINTER_TO_LOCAL_REGISTER(regist)->dataType = dataType;
        POINTER_TO_LOCAL_REGISTER(regist)->tag = tag;
      }
    }
    return;
  }

  sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "setRegisterDataType", regist, LAST_RESERVED_VARIABLE + 1);
  displayBugScreen(errorMessage);
}

void oracle_setRegisterDataPointer(calcRegister_t regist, const void *memPtr) {
  uint32_t dataPointer = TO_C47MEMPTR(memPtr);

  if(regist <= LAST_GLOBAL_REGISTER) {
    globalRegister[regist].pointerToRegisterData = dataPointer;
    return;
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      if(regist < numberOfNamedVariables) {
        allNamedVariables[regist].header.pointerToRegisterData = dataPointer;
      }
    }
    return;
  }

  if(regist <= LAST_RESERVED_VARIABLE) {
    return;
  }

  if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      regist -= FIRST_LOCAL_REGISTER;
      if(regist < currentNumberOfLocalRegisters) {
        POINTER_TO_LOCAL_REGISTER(regist)->pointerToRegisterData = dataPointer;
      }
    }
    return;
  }

  sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "setRegisterDataPointer", regist, LAST_RESERVED_VARIABLE + 1);
  displayBugScreen(errorMessage);
}

void oracle_setRegisterTag(calcRegister_t regist, const uint32_t tag) {
  if(regist <= LAST_GLOBAL_REGISTER) {
    globalRegister[regist].tag = tag;
    return;
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      if(regist < numberOfNamedVariables) {
        allNamedVariables[regist].header.tag = tag;
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "setRegisterTag");
      displayBugScreen(errorMessage);
    }
    return;
  }

  if(regist <= LAST_RESERVED_VARIABLE) {
    return;
  }

  if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      regist -= FIRST_LOCAL_REGISTER;
      if(regist < currentNumberOfLocalRegisters) {
        POINTER_TO_LOCAL_REGISTER(regist)->tag = tag;
      }
    }
    return;
  }

  sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "setRegisterTag", regist, LAST_RESERVED_VARIABLE + 1);
  displayBugScreen(errorMessage);
}

void oracle_setRegisterMaxDataLengthInBlocks(calcRegister_t regist, uint16_t maxDataLen) {
  if(regist <= LAST_GLOBAL_REGISTER) {
    ((strLgIntHeader_t *)TO_PCMEMPTR(globalRegister[regist].pointerToRegisterData))->dataMaxLengthInBlocks = maxDataLen;
    return;
  }

  if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      if(regist - FIRST_NAMED_VARIABLE < numberOfNamedVariables) {
        ((strLgIntHeader_t *)oracle_getRegisterDataPointer(regist))->dataMaxLengthInBlocks = maxDataLen;
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "setRegisterMaxDataLengthInBlocks");
      displayBugScreen(errorMessage);
    }
    return;
  }

  if(regist <= LAST_RESERVED_VARIABLE) {
    regist -= FIRST_RESERVED_VARIABLE;
    ((strLgIntHeader_t *)TO_PCMEMPTR(globalRegister[regist].pointerToRegisterData))->dataMaxLengthInBlocks = maxDataLen;
    return;
  }

  if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      if(regist - FIRST_LOCAL_REGISTER < currentNumberOfLocalRegisters) {
        ((strLgIntHeader_t *)oracle_getRegisterDataPointer(regist))->dataMaxLengthInBlocks = maxDataLen;
      }
    }
    return;
  }

  sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "setRegisterMaxDataLengthInBlocks", regist, LAST_RESERVED_VARIABLE + 1);
  displayBugScreen(errorMessage);
}

uint16_t oracle_getRegisterMaxDataLengthInBlocks(calcRegister_t regist) {
  void *db = NULL;
  calcRegister_t dataTypeRegister = regist;

  if(regist <= LAST_GLOBAL_REGISTER) {
    db = TO_PCMEMPTR(globalRegister[regist].pointerToRegisterData);
  }

  else if(regist <= LAST_NAMED_VARIABLE) {
    if(numberOfNamedVariables > 0) {
      regist -= FIRST_NAMED_VARIABLE;
      dataTypeRegister = regist;
      if(regist < numberOfNamedVariables) {
        db = TO_PCMEMPTR(allNamedVariables[regist].header.pointerToRegisterData);
      }
    }
    else {
      sprintf(errorMessage, commonBugScreenMessages[bugMsgNoNamedVariables], "getRegisterMaxDataLengthInBlocks");
      displayBugScreen(errorMessage);
    }
  }

  else if(regist <= LAST_RESERVED_VARIABLE) {
    regist -= FIRST_RESERVED_VARIABLE;
    dataTypeRegister = regist;
    db = TO_PCMEMPTR(allReservedVariables[regist].header.pointerToRegisterData);
  }

  else if(regist <= LAST_LOCAL_REGISTER) {
    if(currentLocalRegisters != NULL) {
      if(regist - FIRST_LOCAL_REGISTER < currentNumberOfLocalRegisters) {
        db = TO_PCMEMPTR(POINTER_TO_LOCAL_REGISTER(regist - FIRST_LOCAL_REGISTER)->pointerToRegisterData);
      }
    }
  }

  else {
    sprintf(errorMessage, commonBugScreenMessages[bugMsgRegistMustBeLessThan], "getRegisterMaxDataLengthInBlocks", regist, LAST_RESERVED_VARIABLE + 1);
    displayBugScreen(errorMessage);
  }

  if(db != NULL) {
    uint32_t data_type = oracle_getRegisterDataType(dataTypeRegister);

    if(data_type == dtReal34Matrix) {
      return (uint16_t)(((matrixHeader_t *)db)->matrixRows * ((matrixHeader_t *)db)->matrixColumns * REAL34_SIZE_IN_BLOCKS);
    }
    if(data_type == dtComplex34Matrix) {
      return (uint16_t)(((matrixHeader_t *)db)->matrixRows * ((matrixHeader_t *)db)->matrixColumns * COMPLEX34_SIZE_IN_BLOCKS);
    }
    return ((strLgIntHeader_t *)db)->dataMaxLengthInBlocks;
  }

  return 0;
}

uint16_t oracle_getRegisterFullSizeInBlocks(calcRegister_t regist) {
  void *db = oracle_getRegisterDataPointer(regist);

  switch(oracle_getRegisterDataType(regist)) {
    case dtLongInteger:
      return ((strLgIntHeader_t *)db)->dataMaxLengthInBlocks + TO_BLOCKS(sizeof(strLgIntHeader_t));
    case dtTime:
      return REAL34_SIZE_IN_BLOCKS;
    case dtDate:
      return REAL34_SIZE_IN_BLOCKS;
    case dtString:
      return ((strLgIntHeader_t *)db)->dataMaxLengthInBlocks + TO_BLOCKS(sizeof(strLgIntHeader_t));
    case dtReal34Matrix:
      return TO_BLOCKS((((matrixHeader_t *)db)->matrixRows * ((matrixHeader_t *)db)->matrixColumns) * REAL34_SIZE_IN_BYTES + sizeof(matrixHeader_t));
    case dtComplex34Matrix:
      return TO_BLOCKS((((matrixHeader_t *)db)->matrixRows * ((matrixHeader_t *)db)->matrixColumns) * COMPLEX34_SIZE_IN_BYTES + sizeof(matrixHeader_t));
    case dtShortInteger:
      return SHORT_INTEGER_SIZE_IN_BLOCKS;
    case dtReal34:
      return REAL34_SIZE_IN_BLOCKS;
    case dtComplex34:
      return COMPLEX34_SIZE_IN_BLOCKS;
    case dtConfig:
      return CONFIG_SIZE_IN_BLOCKS;
    default:
      displayBugScreen("getRegisterFullSizeInBlocks");
      return 0;
  }
}

void oracle_reallocateRegister(calcRegister_t regist, uint32_t dataType, uint16_t dataSizeWithoutDataLenBlocks, uint32_t tag) {
  uint16_t dataSizeWithDataLenBlocks;

  switch(dataType) {
    case dtComplex34:
      dataSizeWithoutDataLenBlocks = COMPLEX34_SIZE_IN_BLOCKS;
      break;
    case dtReal34:
    case dtTime:
    case dtDate:
      dataSizeWithoutDataLenBlocks = REAL34_SIZE_IN_BLOCKS;
      break;
    case dtShortInteger:
      dataSizeWithoutDataLenBlocks = SHORT_INTEGER_SIZE_IN_BLOCKS;
      break;
    case dtConfig:
      dataSizeWithoutDataLenBlocks = CONFIG_SIZE_IN_BLOCKS;
      break;
    default:
      break;
  }

  dataSizeWithDataLenBlocks = dataSizeWithoutDataLenBlocks;
  if(dataType == dtString) {
    dataSizeWithDataLenBlocks = (uint16_t)(dataSizeWithoutDataLenBlocks + TO_BLOCKS(sizeof(strLgIntHeader_t)));
  }
  else if(dataType == dtReal34Matrix || dataType == dtComplex34Matrix) {
    dataSizeWithDataLenBlocks = (uint16_t)(dataSizeWithoutDataLenBlocks + TO_BLOCKS(sizeof(matrixHeader_t)));
  }
  else if(dataType == dtLongInteger) {
    if(TO_BYTES(dataSizeWithoutDataLenBlocks) % LIMB_SIZE != 0) {
      dataSizeWithoutDataLenBlocks = (uint16_t)(((dataSizeWithoutDataLenBlocks / TO_BLOCKS(LIMB_SIZE)) + 1) * TO_BLOCKS(LIMB_SIZE));
    }
    dataSizeWithDataLenBlocks = (uint16_t)(dataSizeWithoutDataLenBlocks + TO_BLOCKS(sizeof(strLgIntHeader_t)));
  }

  if(oracle_getRegisterDataType(regist) != dataType ||
     ((oracle_getRegisterDataType(regist) == dtString ||
       oracle_getRegisterDataType(regist) == dtLongInteger ||
       oracle_getRegisterDataType(regist) == dtReal34Matrix ||
       oracle_getRegisterDataType(regist) == dtComplex34Matrix) &&
      oracle_getRegisterMaxDataLengthInBlocks(regist) != dataSizeWithoutDataLenBlocks)) {
    if(!isMemoryBlockAvailable(dataSizeWithDataLenBlocks, 2, 0.1f)) {
      displayCalcErrorMessage(ERROR_RAM_FULL, ERR_REGISTER_LINE, NIM_REGISTER_LINE);
      return;
    }

    freeRegisterData(regist);
    oracle_setRegisterDataPointer(regist, dataSizeWithDataLenBlocks == 0 ? NULL : allocC47Blocks(dataSizeWithDataLenBlocks));
    oracle_setRegisterDataType(regist, (uint16_t)dataType, tag);

    if(dataType == dtReal34Matrix || dataType == dtComplex34Matrix) {
      matrixHeader_t *header = (matrixHeader_t *)oracle_getRegisterDataPointer(regist);
      if(header != NULL) {
        header->matrixRows = 1;
        header->matrixColumns = 1;
      }
    }
    else {
      oracle_setRegisterMaxDataLengthInBlocks(regist, dataSizeWithoutDataLenBlocks);
    }
  }

  if(dataType == dtComplex34 && getSystemFlag(FLAG_POLAR)) {
    oracle_setRegisterTag(regist, currentAngularMode | amPolar);
  }
  else {
    oracle_setRegisterTag(regist, tag);
  }
}

uint32_t z47_registers_retained_getRegisterDataType(calcRegister_t reg) {
  return oracle_getRegisterDataType(reg);
}

void *z47_registers_retained_getRegisterDataPointer(calcRegister_t reg) {
  return oracle_getRegisterDataPointer(reg);
}

uint32_t z47_registers_retained_getRegisterTag(calcRegister_t reg) {
  return oracle_getRegisterTag(reg);
}

void z47_registers_retained_setRegisterMaxDataLengthInBlocks(calcRegister_t reg, uint16_t max_data_len) {
  oracle_setRegisterMaxDataLengthInBlocks(reg, max_data_len);
}

uint16_t z47_registers_retained_getRegisterMaxDataLengthInBlocks(calcRegister_t reg) {
  return oracle_getRegisterMaxDataLengthInBlocks(reg);
}

uint16_t z47_registers_retained_getRegisterFullSizeInBlocks(calcRegister_t reg) {
  return oracle_getRegisterFullSizeInBlocks(reg);
}

void z47_registers_retained_reallocateRegister(calcRegister_t reg, uint32_t data_type, uint16_t data_size_without_data_len_blocks, uint32_t tag) {
  oracle_reallocateRegister(reg, data_type, data_size_without_data_len_blocks, tag);
}

void z47_registers_retained_copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister) {
  uint32_t dataType;
  uint16_t sizeInBlocks;

  if(FIRST_RESERVED_VARIABLE <= destRegister && destRegister < FIRST_NAMED_RESERVED_VARIABLE) {
    destRegister = destRegister - FIRST_RESERVED_VARIABLE + REGISTER_X;
  }

  if(FIRST_RESERVED_VARIABLE <= sourceRegister && sourceRegister < FIRST_NAMED_RESERVED_VARIABLE) {
    sourceRegister = sourceRegister - FIRST_RESERVED_VARIABLE + REGISTER_X;
  }
  else if(sourceRegister == RESERVED_VARIABLE_ADM ||
          sourceRegister == RESERVED_VARIABLE_DENMAX ||
          sourceRegister == RESERVED_VARIABLE_ISM ||
          sourceRegister == RESERVED_VARIABLE_REALDF ||
          sourceRegister == RESERVED_VARIABLE_NDEC) {
    return;
  }

  dataType = oracle_getRegisterDataType(sourceRegister);
  if(oracle_getRegisterDataType(destRegister) != dataType || oracle_getRegisterFullSizeInBlocks(destRegister) != oracle_getRegisterFullSizeInBlocks(sourceRegister)) {
    switch(dataType) {
      case dtLongInteger:
      case dtString:
      case dtReal34Matrix:
      case dtComplex34Matrix:
        sizeInBlocks = oracle_getRegisterMaxDataLengthInBlocks(sourceRegister);
        break;
      case dtTime:
      case dtDate:
      case dtShortInteger:
      case dtReal34:
      case dtComplex34:
      case dtConfig:
        sizeInBlocks = 0;
        break;
      default:
        return;
    }

    reallocateRegister(destRegister, dataType, sizeInBlocks, amNone);
    if(lastErrorCode == ERROR_RAM_FULL) {
      return;
    }
  }

  xcopy(oracle_getRegisterDataPointer(destRegister), oracle_getRegisterDataPointer(sourceRegister), TO_BYTES(oracle_getRegisterFullSizeInBlocks(sourceRegister)));
  oracle_setRegisterTag(destRegister, oracle_getRegisterTag(sourceRegister));
}

void oracle_copySourceRegisterToDestRegister(calcRegister_t sourceRegister, calcRegister_t destRegister) {
  z47_registers_retained_copySourceRegisterToDestRegister(sourceRegister, destRegister);
}

bool_t oracle_isFunctionAllowingNewVariable(uint16_t op) {
  switch(op) {
    case ITM_INPUT:
    case ITM_STO:
    case ITM_STOADD:
    case ITM_STOSUB:
    case ITM_STOMULT:
    case ITM_STODIV:
    case ITM_KEYQ:
    case ITM_M_DIM:
    case ITM_MVAR:
    case ITM_SOLVE:
    case ITM_STOCFG:
    case ITM_STOMAX:
    case ITM_STOMIN:
    case ITM_XtoALPHA:
    case ITM_Xex:
    case ITM_Yex:
    case ITM_Zex:
    case ITM_Tex:
    case ITM_INTEGRAL:
      return true;

    default:
      return false;
  }
}

void z47_registers_retained_setRegisterDataType(calcRegister_t reg, uint16_t data_type, uint32_t tag) {
  oracle_setRegisterDataType(reg, data_type, tag);
}

void z47_registers_retained_setRegisterDataPointer(calcRegister_t reg, const void *mem_ptr) {
  oracle_setRegisterDataPointer(reg, mem_ptr);
}

void z47_registers_retained_setRegisterTag(calcRegister_t reg, uint32_t tag) {
  oracle_setRegisterTag(reg, tag);
}