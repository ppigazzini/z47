// SPDX-License-Identifier: GPL-3.0-only

#include <inttypes.h>
#include <stdio.h>

#include "c47.h"

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

uint32_t z47_registers_retained_getRegisterDataType(calcRegister_t reg) {
  return oracle_getRegisterDataType(reg);
}

void *z47_registers_retained_getRegisterDataPointer(calcRegister_t reg) {
  return oracle_getRegisterDataPointer(reg);
}

uint32_t z47_registers_retained_getRegisterTag(calcRegister_t reg) {
  return oracle_getRegisterTag(reg);
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